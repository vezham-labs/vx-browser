#include "protocol.h"
#include <errno.h>
#include <poll.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <unistd.h>

/* Fake provider only. No SQLite initialization, handles, paths or key calls. */
struct worker {
    struct vx_context identity;
    enum vx_state state;
    struct vx_message opening;
    uint8_t active_operation[16];
    uint64_t sequence;
    uint8_t key_frame[VX_KEY_SIZE + 1];
    size_t key_bytes;
    bool key_closed;
    int close_mode;
    uint8_t admitted_operations[32][16];
    size_t admitted_count;
};
static int reply(struct worker *w, const struct vx_message *request,
                 uint16_t opcode, enum vx_error error) {
    struct vx_message result = *request;
    result.context = w->identity; result.opcode = opcode;
    result.argument = ((uint32_t)w->state << 16) | (uint32_t)error;
    return vx_send(VX_CONTROL_FD, &result, 1000);
}
static int reject(struct worker *w, const struct vx_message *request, enum vx_error error) {
    w->state = VX_UNCERTAIN;
    vx_wipe(w->key_frame, sizeof(w->key_frame));
    (void)reply(w, request, VX_REJECTED, error);
    return 2;
}
static int handle_control(struct worker *w) {
    struct vx_message request = {0};
    int rc = vx_receive(VX_CONTROL_FD, &request, 500);
    if (rc) return reject(w, &w->opening, (enum vx_error)rc);
    if (request.context.scope_kind == 2) return reject(w, &request, VX_PRIVATE);
    if (request.opcode > VX_CLOSE) return reject(w, &request, VX_INVALID);
    if (!vx_context_equal(&request.context, &w->identity))
        return reject(w, &request, VX_SCOPE_ERROR);
    if (request.sequence != w->sequence + 1) return reject(w, &request, VX_STALE);
    w->sequence = request.sequence;
    if (request.argument != 0) return reject(w, &request, VX_INVALID);
    if (request.opcode == VX_START) {
        if (w->state != VX_STARTING)
            return reply(w, &request, VX_REJECTED, VX_STATE_ERROR) ? 2 : 0;
        w->opening = request;
        if (w->identity.scope_kind == 2) return reject(w, &request, VX_PRIVATE);
        memcpy(w->admitted_operations[w->admitted_count++], request.operation, 16);
        w->state = VX_AWAIT_KEY;
        return reply(w, &request, VX_WAITING, VX_OK) ? 2 : 0;
    }
    if (request.opcode == VX_CLOSE) {
        if (w->state == VX_BUSY)
            return reply(w, &request, VX_REJECTED, VX_STATE_ERROR) ? 2 : 0;
        w->state = VX_CLOSING; vx_wipe(w->key_frame, sizeof(w->key_frame));
        if (w->close_mode == 1) return 0;
        if (w->close_mode == 2) {
            w->state = VX_UNCERTAIN;
            (void)reply(w, &request, VX_CLEANUP_REQUIRED, VX_CLEANUP_ERROR);
            return 2;
        }
        w->state = VX_RETIRED;
        return reply(w, &request, VX_CLOSED, VX_OK) ? 2 : 1;
    }
    if (request.opcode == VX_CANCEL) {
        if (w->state != VX_AWAIT_KEY && w->state != VX_BUSY)
            return reply(w, &request, VX_REJECTED, VX_STATE_ERROR) ? 2 : 0;
        const uint8_t *op = w->state == VX_BUSY ? w->active_operation : w->opening.operation;
        if (memcmp(request.operation, op, 16)) return reject(w, &request, VX_SCOPE_ERROR);
        vx_wipe(w->key_frame, sizeof(w->key_frame));
        if (w->state == VX_AWAIT_KEY) {
            w->state = VX_RETIRED;
            (void)reply(w, &request, VX_CANCELLED, VX_OK);
            return 1;
        }
        w->state = VX_READY;
        return reply(w, &request, VX_CANCELLED, VX_OK) ? 2 : 0;
    }
    if (request.opcode == VX_BEGIN && w->state == VX_READY) {
        for (size_t i = 0; i < w->admitted_count; ++i)
            if (!memcmp(w->admitted_operations[i], request.operation, 16))
                return reject(w, &request, VX_STALE);
        if (w->admitted_count == 32) return reject(w, &request, VX_STATE_ERROR);
        memcpy(w->admitted_operations[w->admitted_count++], request.operation, 16);
        memcpy(w->active_operation, request.operation, 16); w->state = VX_BUSY;
        return reply(w, &request, VX_ACCEPTED, VX_OK) ? 2 : 0;
    }
    if (request.opcode == VX_FINISH && w->state == VX_BUSY) {
        if (memcmp(request.operation, w->active_operation, 16))
            return reject(w, &request, VX_SCOPE_ERROR);
        w->state = VX_READY;
        return reply(w, &request, VX_DONE, VX_OK) ? 2 : 0;
    }
    return reply(w, &request, VX_REJECTED, VX_STATE_ERROR) ? 2 : 0;
}
static int handle_key(struct worker *w) {
    ssize_t n = recv(VX_KEY_FD, w->key_frame + w->key_bytes,
                     sizeof(w->key_frame) - w->key_bytes, MSG_DONTWAIT);
    if (n < 0) return (errno == EINTR || errno == EAGAIN) ? 0 : 2;
    if (n > 0) {
        w->key_bytes += (size_t)n;
        if (w->key_bytes > VX_KEY_SIZE) return reject(w, &w->opening, VX_KEY_ERROR);
        return 0;
    }
    w->key_closed = true;
    if (w->state != VX_AWAIT_KEY) return reject(w, &w->opening, VX_STATE_ERROR);
    enum vx_error rc = vx_key_validate(w->key_frame, w->key_bytes,
                                      &w->identity, w->opening.operation);
    vx_wipe(w->key_frame, sizeof(w->key_frame));
    if (!vx_zero(w->key_frame, sizeof(w->key_frame))) rc = VX_CLEANUP_ERROR;
    if (rc) return reject(w, &w->opening, rc);
    w->state = VX_READY;
    return reply(w, &w->opening, VX_PROTOCOL_READY, VX_OK) ? 2 : 0;
}
int main(int argc, char **argv) {
    struct rlimit limit = {0, 0};
    if (setrlimit(RLIMIT_CORE, &limit)) return 3;
    signal(SIGPIPE, SIG_IGN);
    struct worker w = {0}; w.state = VX_STARTING;
    if (argc != 3 || !vx_context_unhex(&w.identity, argv[1])) return 3;
    w.opening.context = w.identity;
    w.opening.sequence = 1;
    w.opening.operation[15] = 1;
    if (!strcmp(argv[2], "close-timeout")) w.close_mode = 1;
    else if (!strcmp(argv[2], "close-failure")) w.close_mode = 2;
    else if (strcmp(argv[2], "normal")) return 3;
    int outcome = 0;
    int64_t startup_deadline = vx_now_ms() + 2500;
    while (!outcome) {
        struct pollfd fds[2] = {
            {VX_CONTROL_FD, POLLIN, 0},
            {w.key_closed ? -1 : VX_KEY_FD, POLLIN, 0}
        };
        int ready = poll(fds, 2, 100);
        if (ready < 0 && errno != EINTR) { outcome = 2; break; }
        if (fds[0].revents & (POLLIN | POLLHUP | POLLERR)) outcome = handle_control(&w);
        if (!outcome && fds[1].revents & (POLLIN | POLLHUP | POLLERR)) outcome = handle_key(&w);
        if (!outcome && (w.state == VX_STARTING || w.state == VX_AWAIT_KEY) &&
            vx_now_ms() >= startup_deadline) outcome = reject(&w, &w.opening, VX_TIMEOUT);
    }
    vx_wipe(w.key_frame, sizeof(w.key_frame));
    close(VX_CONTROL_FD); close(VX_KEY_FD);
    return outcome == 1 ? 0 : 2;
}
