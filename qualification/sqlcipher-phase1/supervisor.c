#include "supervisor.h"
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <spawn.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <unistd.h>

/* Process-local native authority. Entries retain lease history without keys. */
struct registration {
    struct vx_context identity;
    bool active, quarantined;
};
static struct registration registry[128];
static size_t registry_count;
static int register_child(struct vx_child *c, const struct vx_context *identity) {
    if (registry_count == 128) return VX_STATE_ERROR;
    for (size_t i = 0; i < registry_count; ++i) {
        struct registration *entry = &registry[i];
        if (!memcmp(entry->identity.worker, identity->worker, 16)) return VX_STALE;
        bool same_store = !memcmp(entry->identity.store, identity->store, 16);
        bool same_scope = entry->identity.scope_kind == identity->scope_kind &&
                          !memcmp(entry->identity.scope, identity->scope, 16);
        if (same_store || same_scope) {
            if (entry->active || entry->quarantined) return VX_SCOPE_ERROR;
            if (identity->lease <= entry->identity.lease) return VX_STALE;
        }
    }
    c->registry_slot = (int)registry_count++;
    registry[c->registry_slot] = (struct registration){.identity = *identity, .active = true};
    return VX_OK;
}
static void record_retirement(struct vx_child *c, bool confirmed) {
    if (c->registry_slot < 0) return;
    registry[c->registry_slot].active = false;
    registry[c->registry_slot].quarantined = !confirmed;
}

void vx_child_init(struct vx_child *c) {
    memset(c, 0, sizeof(*c)); c->pid = -1;
    c->control_fd = c->key_fd = c->diagnostic_fd = -1;
    c->registry_slot = -1;
}
int vx_child_spawn(struct vx_child *c, const char *worker,
                   const struct vx_context *identity, const char *fault) {
    if (!c || c->used) return VX_STATE_ERROR;
    if (!vx_context_valid(identity)) return VX_SCOPE_ERROR;
    if (identity->scope_kind == 2) return VX_PRIVATE;
    int admission = register_child(c, identity);
    if (admission) return admission;
    c->used = true; c->identity = *identity; c->state = VX_STARTING;
    int control[2] = {-1, -1}, keys[2] = {-1, -1}, diagnostic[2] = {-1, -1};
    if (socketpair(AF_UNIX, SOCK_STREAM, 0, control) ||
        socketpair(AF_UNIX, SOCK_STREAM, 0, keys) || pipe(diagnostic)) goto failure;
    /* Keep action sources distinct from both fixed child channel descriptors. */
    int *descriptors[] = {&control[0], &control[1], &keys[0], &keys[1],
                          &diagnostic[0], &diagnostic[1]};
    for (size_t i = 0; i < sizeof(descriptors) / sizeof(descriptors[0]); ++i) {
        int moved = fcntl(*descriptors[i], F_DUPFD_CLOEXEC, VX_KEY_FD + 1);
        if (moved < 0) goto failure;
        close(*descriptors[i]); *descriptors[i] = moved;
    }
    posix_spawn_file_actions_t actions;
    posix_spawnattr_t attributes;
    if (posix_spawn_file_actions_init(&actions)) goto failure;
    if (posix_spawnattr_init(&attributes)) {
        posix_spawn_file_actions_destroy(&actions); goto failure;
    }
    int error = posix_spawnattr_setflags(&attributes, POSIX_SPAWN_CLOEXEC_DEFAULT);
    error |= posix_spawn_file_actions_adddup2(&actions, control[1], VX_CONTROL_FD);
    error |= posix_spawn_file_actions_adddup2(&actions, keys[1], VX_KEY_FD);
    error |= posix_spawn_file_actions_adddup2(&actions, diagnostic[1], STDOUT_FILENO);
    error |= posix_spawn_file_actions_adddup2(&actions, diagnostic[1], STDERR_FILENO);
    error |= posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0);
    char identity_hex[VX_CONTEXT_SIZE * 2 + 1]; vx_context_hex(identity_hex, identity);
    char *args[] = {(char *)worker, identity_hex, (char *)fault, NULL};
    char *environment[] = {"LC_ALL=C", NULL};
    if (!error) error = posix_spawn(&c->pid, worker, &actions, &attributes, args, environment);
    posix_spawn_file_actions_destroy(&actions); posix_spawnattr_destroy(&attributes);
    close(control[1]); close(keys[1]); close(diagnostic[1]);
    control[1] = keys[1] = diagnostic[1] = -1;
    if (error) goto failure;
    c->control_fd = control[0]; c->key_fd = keys[0]; c->diagnostic_fd = diagnostic[0];
    return VX_OK;
failure:
    for (size_t i = 0; i < 2; ++i) {
        if (control[i] >= 0) close(control[i]);
        if (keys[i] >= 0) close(keys[i]);
        if (diagnostic[i] >= 0) close(diagnostic[i]);
    }
    c->state = VX_UNCERTAIN;
    record_retirement(c, false);
    return VX_IO_ERROR;
}
int vx_child_request(struct vx_child *c, uint16_t opcode, uint8_t op,
                     struct vx_message *request) {
    if (!c || c->pid <= 0 || c->reaped || c->state == VX_UNCERTAIN ||
        c->state == VX_RETIRED || c->sequence == UINT64_MAX) return VX_STATE_ERROR;
    memset(request, 0, sizeof(*request));
    request->opcode = opcode; request->context = c->identity;
    request->operation[15] = op; request->sequence = ++c->sequence;
    int rc = vx_send(c->control_fd, request, 1000);
    if (rc) c->state = VX_UNCERTAIN;
    return rc;
}
int vx_child_response(struct vx_child *c, const struct vx_message *request,
                      uint16_t expected, int timeout_ms, struct vx_message *response) {
    int rc = vx_receive(c->control_fd, response, timeout_ms);
    if (rc || !vx_context_equal(&response->context, &c->identity) ||
        memcmp(response->operation, request->operation, 16) ||
        response->sequence != request->sequence || response->opcode != expected ||
        (response->argument >> 16) < VX_STARTING || (response->argument >> 16) > VX_UNCERTAIN ||
        (response->argument & 0xffff) > VX_CLEANUP_ERROR) {
        c->state = VX_UNCERTAIN; return rc ? rc : VX_INVALID;
    }
    enum vx_state state = (enum vx_state)(response->argument >> 16);
    unsigned error = response->argument & 0xffff;
    bool legal = false;
    switch (expected) {
        case VX_WAITING: legal = state == VX_AWAIT_KEY && error == VX_OK; break;
        case VX_PROTOCOL_READY: case VX_DONE:
            legal = state == VX_READY && error == VX_OK; break;
        case VX_ACCEPTED: legal = state == VX_BUSY && error == VX_OK; break;
        case VX_CANCELLED:
            legal = (state == VX_READY || state == VX_RETIRED) && error == VX_OK; break;
        case VX_CLOSED: legal = state == VX_RETIRED && error == VX_OK; break;
        case VX_REJECTED: case VX_CLEANUP_REQUIRED: legal = error != VX_OK; break;
        default: break;
    }
    if (!legal) { c->state = VX_UNCERTAIN; return VX_INVALID; }
    c->state = state;
    if (expected == VX_ACCEPTED && request->opcode == VX_BEGIN)
        c->active_operation = request->operation[15];
    return VX_OK;
}
int vx_child_key(struct vx_child *c, const struct vx_message *opening,
                 const uint8_t key[32]) {
    if (c->key_fd < 0 || c->state != VX_AWAIT_KEY || !key) return VX_STATE_ERROR;
    uint8_t wire[VX_KEY_SIZE]; vx_key_encode(wire, &c->identity, opening->operation, key);
    int rc = vx_write_all(c->key_fd, wire, sizeof(wire), vx_now_ms() + 1000);
    vx_wipe(wire, sizeof(wire));
    if (!vx_zero(wire, sizeof(wire))) rc = VX_CLEANUP_ERROR;
    if (shutdown(c->key_fd, SHUT_WR) && !rc) rc = VX_IO_ERROR;
    close(c->key_fd); c->key_fd = -1;
    return rc;
}
int vx_child_reap(struct vx_child *c, int timeout_ms) {
    if (c->reaped || c->pid <= 0 || !c->used) return VX_STATE_ERROR;
    int64_t deadline = vx_now_ms() + timeout_ms;
    do {
        int status;
        pid_t result = waitpid(c->pid, &status, WNOHANG);
        if (result == c->pid) {
            c->reaped = true;
            bool clean = c->state == VX_RETIRED && WIFEXITED(status) && WEXITSTATUS(status) == 0;
            c->cleanup_confirmed = clean;
            record_retirement(c, clean);
            if (!clean) c->state = VX_UNCERTAIN;
            return clean ? VX_OK : VX_CHILD_EXIT;
        }
        if (result < 0 && errno != EINTR) { c->state = VX_UNCERTAIN; return VX_CHILD_EXIT; }
        /* Bounded process observation. Exit status, not elapsed delay, proves reaping. */
        (void)poll(NULL, 0, 2);
    } while (vx_now_ms() < deadline);
    c->state = VX_UNCERTAIN; return VX_TIMEOUT;
}
int vx_child_close(struct vx_child *c, int timeout_ms) {
    struct vx_message request, response;
    if (c->state == VX_BUSY) {
        int cancel = vx_child_request(c, VX_CANCEL, c->active_operation, &request);
        if (!cancel) cancel = vx_child_response(c, &request, VX_CANCELLED, timeout_ms, &response);
        if (cancel) { c->state = VX_UNCERTAIN; return cancel; }
    }
    int rc = vx_child_request(c, VX_CLOSE, 240, &request);
    if (!rc) rc = vx_child_response(c, &request, VX_CLOSED, timeout_ms, &response);
    if (!rc && (response.argument & 0xffff)) rc = VX_CLEANUP_ERROR;
    if (!rc) rc = vx_child_reap(c, timeout_ms);
    if (rc) c->state = VX_UNCERTAIN;
    return rc;
}
void vx_child_retire(struct vx_child *c) {
    if (c->pid > 0 && !c->reaped) {
        /* This direct child cannot have its PID reused before waitpid reaps it. */
        int status;
        pid_t ended = waitpid(c->pid, &status, WNOHANG);
        if (ended == c->pid) c->reaped = true;
        else if (ended == 0) {
            (void)kill(c->pid, SIGKILL);
            while (waitpid(c->pid, &status, 0) < 0 && errno == EINTR) {}
            c->reaped = true;
        }
        if (!c->cleanup_confirmed) c->state = VX_UNCERTAIN;
    }
    if (c->control_fd >= 0) close(c->control_fd);
    if (c->key_fd >= 0) close(c->key_fd);
    c->control_fd = c->key_fd = -1;
    if (c->used) record_retirement(c, c->cleanup_confirmed);
}
bool vx_child_diagnostics_clean(struct vx_child *c, const uint8_t key[32]) {
    if (!c->reaped || c->diagnostic_fd < 0) return false;
    uint8_t output[4096]; size_t total = 0;
    ssize_t n;
    while (total < sizeof(output) &&
           (n = read(c->diagnostic_fd, output + total, sizeof(output) - total)) > 0)
        total += (size_t)n;
    bool leaked = false;
    for (size_t i = 0; i + 32 <= total; ++i)
        if (!memcmp(output + i, key, 32)) leaked = true;
    /* The worker's public diagnostics contract is empty, including encoded secrets. */
    bool clean = !leaked && total == 0;
    vx_wipe(output, sizeof(output)); close(c->diagnostic_fd); c->diagnostic_fd = -1;
    return clean;
}
