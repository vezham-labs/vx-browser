#ifndef VX_PHASE1_PROTOCOL_H
#define VX_PHASE1_PROTOCOL_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define VX_VERSION 1
#define VX_CONTEXT_SIZE 77
#define VX_CONTROL_SIZE 113
#define VX_KEY_SIZE 133
#define VX_CONTROL_FD 198
#define VX_KEY_FD 199

enum vx_opcode {
    VX_START = 1, VX_BEGIN, VX_FINISH, VX_CANCEL, VX_CLOSE,
    VX_WAITING = 101, VX_PROTOCOL_READY, VX_ACCEPTED, VX_DONE,
    VX_CANCELLED, VX_CLOSED, VX_REJECTED, VX_CLEANUP_REQUIRED
};
enum vx_state {
    VX_STARTING = 1, VX_AWAIT_KEY, VX_READY, VX_BUSY, VX_CLOSING,
    VX_RETIRED, VX_UNCERTAIN
};
enum vx_error {
    VX_OK = 0, VX_INVALID, VX_VERSION_ERROR, VX_SCOPE_ERROR,
    VX_STALE, VX_PRIVATE, VX_STATE_ERROR, VX_KEY_ERROR, VX_TIMEOUT,
    VX_IO_ERROR, VX_CHILD_EXIT, VX_CLEANUP_ERROR
};
struct vx_context {
    uint8_t run[16], worker[16], scope_kind, scope[16], store[16];
    uint64_t lease;
    uint32_t dek_version;
};
struct vx_message {
    uint16_t opcode;
    struct vx_context context;
    uint8_t operation[16];
    uint64_t sequence;
    uint32_t argument;
};
void vx_wipe(void *buffer, size_t size);
bool vx_zero(const void *buffer, size_t size);
bool vx_context_valid(const struct vx_context *context);
bool vx_context_equal(const struct vx_context *a, const struct vx_context *b);
void vx_context_encode(uint8_t out[VX_CONTEXT_SIZE], const struct vx_context *context);
bool vx_context_decode(struct vx_context *context, const uint8_t *input, size_t size);
void vx_context_hex(char output[VX_CONTEXT_SIZE * 2 + 1], const struct vx_context *context);
bool vx_context_unhex(struct vx_context *context, const char *input);
void vx_control_encode(uint8_t out[VX_CONTROL_SIZE], const struct vx_message *message);
enum vx_error vx_control_decode(struct vx_message *message, const uint8_t *input, size_t size);
void vx_key_encode(uint8_t out[VX_KEY_SIZE], const struct vx_context *context,
                   const uint8_t operation[16], const uint8_t key[32]);
enum vx_error vx_key_validate(const uint8_t *input, size_t size,
                              const struct vx_context *expected,
                              const uint8_t operation[16]);
int64_t vx_now_ms(void);
int vx_wait(int fd, short events, int64_t deadline);
int vx_write_all(int fd, const void *data, size_t size, int64_t deadline);
int vx_send(int fd, const struct vx_message *message, int timeout_ms);
int vx_receive(int fd, struct vx_message *message, int timeout_ms);
#endif
