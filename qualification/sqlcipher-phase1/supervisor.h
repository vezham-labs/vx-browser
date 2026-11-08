#ifndef VX_PHASE1_SUPERVISOR_H
#define VX_PHASE1_SUPERVISOR_H
#include "protocol.h"
#include <sys/types.h>
struct vx_child {
    pid_t pid;
    int control_fd, key_fd, diagnostic_fd;
    struct vx_context identity;
    enum vx_state state;
    uint64_t sequence;
    bool used, reaped, cleanup_confirmed;
    int registry_slot;
    uint8_t active_operation;
};
/* One controller thread owns each child. The worker has no DB handles in Phase 1. */
void vx_child_init(struct vx_child *child);
int vx_child_spawn(struct vx_child *child, const char *worker,
                   const struct vx_context *identity, const char *fault);
int vx_child_request(struct vx_child *child, uint16_t opcode, uint8_t operation_id,
                     struct vx_message *request);
int vx_child_response(struct vx_child *child, const struct vx_message *request,
                      uint16_t expected, int timeout_ms, struct vx_message *response);
int vx_child_key(struct vx_child *child, const struct vx_message *opening,
                 const uint8_t key[32]);
int vx_child_reap(struct vx_child *child, int timeout_ms);
int vx_child_close(struct vx_child *child, int timeout_ms);
void vx_child_retire(struct vx_child *child);
bool vx_child_diagnostics_clean(struct vx_child *child, const uint8_t key[32]);
#endif
