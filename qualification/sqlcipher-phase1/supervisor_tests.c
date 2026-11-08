#include "supervisor.h"
#include <Security/SecRandom.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/resource.h>
#include <unistd.h>

static unsigned passed, failed;
static void check(const char *name, bool ok) {
    printf("{\"test\":\"%s\",\"status\":\"%s\"}\n", name, ok ? "PASS" : "FAIL");
    if (ok) ++passed; else ++failed;
}
static struct vx_context context(void) {
    struct vx_context c = {0};
    if (SecRandomCopyBytes(kSecRandomDefault, 16, c.run) ||
        SecRandomCopyBytes(kSecRandomDefault, 16, c.worker) ||
        SecRandomCopyBytes(kSecRandomDefault, 16, c.scope) ||
        SecRandomCopyBytes(kSecRandomDefault, 16, c.store)) exit(4);
    c.scope_kind = 1; c.lease = 7; c.dek_version = 1;
    return c;
}
static void key_material(uint8_t key[32]) {
    if (SecRandomCopyBytes(kSecRandomDefault, 32, key)) exit(4);
    key[0] = 0; /* Binary input and embedded-NUL handling are intentional. */
}
static bool waiting(struct vx_child *child, const char *path, const char *fault,
                    struct vx_message *opening) {
    struct vx_context c = context(); struct vx_message response;
    vx_child_init(child);
    return vx_child_spawn(child, path, &c, fault) == VX_OK &&
           vx_child_request(child, VX_START, 1, opening) == VX_OK &&
           vx_child_response(child, opening, VX_WAITING, 1000, &response) == VX_OK;
}
static bool ready(struct vx_child *child, const char *path, const char *fault,
                  const uint8_t key[32]) {
    struct vx_message opening, response;
    return waiting(child, path, fault, &opening) &&
           vx_child_key(child, &opening, key) == VX_OK &&
           vx_child_response(child, &opening, VX_PROTOCOL_READY, 1000, &response) == VX_OK &&
           child->state == VX_READY;
}
static bool exchange(struct vx_child *child, uint16_t opcode, uint8_t op, uint16_t expected) {
    struct vx_message request, response;
    return vx_child_request(child, opcode, op, &request) == VX_OK &&
           vx_child_response(child, &request, expected, 1000, &response) == VX_OK;
}
static void finish_child(struct vx_child *child, const uint8_t key[32]) {
    vx_child_retire(child);
    check("child-diagnostics-empty", vx_child_diagnostics_clean(child, key));
}
static void protocol_tests(void) {
    struct vx_context c = context(), decoded;
    char hex[VX_CONTEXT_SIZE * 2 + 1]; vx_context_hex(hex, &c);
    check("context-roundtrip", vx_context_unhex(&decoded, hex) && vx_context_equal(&c, &decoded));
    hex[0] = 'z'; check("context-bad-hex", !vx_context_unhex(&decoded, hex));
    struct vx_message request = {.opcode = VX_START, .context = c, .sequence = 1};
    request.operation[15] = 1;
    uint8_t wire[VX_CONTROL_SIZE]; struct vx_message output;
    vx_control_encode(wire, &request);
    check("control-roundtrip", vx_control_decode(&output, wire, sizeof(wire)) == VX_OK &&
          output.sequence == 1 && output.opcode == VX_START && vx_context_equal(&c, &output.context));
    check("control-truncated", vx_control_decode(&output, wire, sizeof(wire)-1) == VX_INVALID);
    wire[0] = 0; check("control-magic", vx_control_decode(&output, wire, sizeof(wire)) == VX_INVALID);
    vx_control_encode(wire, &request); wire[5] = 2;
    check("control-version", vx_control_decode(&output, wire, sizeof(wire)) == VX_VERSION_ERROR);
    vx_control_encode(wire, &request); wire[7] = 99;
    check("control-unknown-opcode", vx_control_decode(&output, wire, sizeof(wire)) == VX_INVALID);
    request.sequence = 0; vx_control_encode(wire, &request);
    check("control-zero-sequence", vx_control_decode(&output, wire, sizeof(wire)) == VX_INVALID);
    uint8_t key[32], keywire[VX_KEY_SIZE]; key_material(key);
    vx_key_encode(keywire, &c, request.operation, key);
    check("key-exact-frame", vx_key_validate(keywire, sizeof(keywire), &c, request.operation) == VX_OK);
    check("key-short-frame", vx_key_validate(keywire, sizeof(keywire)-1, &c, request.operation) == VX_KEY_ERROR);
    check("key-null", vx_key_validate(NULL, sizeof(keywire), &c, request.operation) == VX_KEY_ERROR);
    size_t offsets[] = {6,22,38,39,55,71,79,83,99};
    const char *names[] = {"key-run","key-worker","key-kind","key-profile","key-store","key-lease","key-dek","key-operation","key-length"};
    for (size_t i = 0; i < sizeof(offsets)/sizeof(offsets[0]); ++i) {
        vx_key_encode(keywire, &c, request.operation, key); keywire[offsets[i]] ^= 1;
        check(names[i], vx_key_validate(keywire, sizeof(keywire), &c, request.operation) != VX_OK);
    }
    vx_key_encode(keywire, &c, request.operation, key); keywire[5] = 2;
    check("key-version", vx_key_validate(keywire, sizeof(keywire), &c, request.operation) == VX_VERSION_ERROR);
    vx_key_encode(keywire, &c, request.operation, key); keywire[0] = 0;
    check("key-magic", vx_key_validate(keywire, sizeof(keywire), &c, request.operation) == VX_KEY_ERROR);
    c.scope_kind = 2; vx_key_encode(keywire, &c, request.operation, key);
    check("key-private", vx_key_validate(keywire, sizeof(keywire), &c, request.operation) == VX_PRIVATE);
    vx_wipe(keywire, sizeof(keywire)); vx_wipe(key, sizeof(key));
    check("owned-key-buffers-cleared", vx_zero(keywire, sizeof(keywire)) && vx_zero(key, sizeof(key)));
}
static void invalid_control_case(const char *path, unsigned kind, const uint8_t key[32]) {
    struct vx_child child; struct vx_message request, response;
    bool ok = ready(&child, path, "normal", key);
    if (ok) {
        memset(&request, 0, sizeof(request)); request.opcode = VX_BEGIN;
        request.context = child.identity; request.sequence = ++child.sequence; request.operation[15] = 2;
        if (kind == 0) request.context.worker[0] ^= 1;
        if (kind == 1) request.context.scope[0] ^= 1;
        if (kind == 2) request.context.store[0] ^= 1;
        if (kind == 3) ++request.context.lease;
        if (kind == 4) request.sequence = 1;
        if (kind == 5) request.context.run[0] ^= 1;
        if (kind == 6) ++request.context.dek_version;
        ok = vx_send(child.control_fd, &request, 1000) == VX_OK &&
             vx_receive(child.control_fd, &response, 1000) == VX_OK &&
             response.opcode == VX_REJECTED && (response.argument >> 16) == VX_UNCERTAIN;
    }
    const char *names[] = {"worker-identity-mismatch","profile-mismatch","store-mismatch",
                           "stale-lease","duplicate-sequence","run-mismatch","key-version-mismatch"};
    check(names[kind], ok); finish_child(&child, key);
}
static void invalid_key_case(const char *path, unsigned kind, const uint8_t key[32]) {
    struct vx_child child; struct vx_message opening, response;
    bool ok = waiting(&child, path, "normal", &opening);
    if (ok) {
        uint8_t wire[VX_KEY_SIZE*2]; vx_key_encode(wire, &child.identity, opening.operation, key);
        size_t size = VX_KEY_SIZE;
        if (kind == 0) wire[22] ^= 1;
        if (kind == 1) wire[39] ^= 1;
        if (kind == 2) wire[55] ^= 1;
        if (kind == 3) wire[71] ^= 1;
        if (kind == 4) wire[83] ^= 1;
        if (kind == 5) wire[100] = 31;
        if (kind == 6) --size;
        if (kind == 7) { memcpy(wire + VX_KEY_SIZE, wire, VX_KEY_SIZE); size *= 2; }
        if (kind == 8) wire[5] = 2;
        ok = vx_write_all(child.key_fd, wire, size, vx_now_ms()+1000) == VX_OK;
        vx_wipe(wire, sizeof(wire)); shutdown(child.key_fd, SHUT_WR);
        ok = ok && vx_receive(child.control_fd, &response, 1000) == VX_OK &&
             response.opcode == VX_REJECTED && child.state == VX_AWAIT_KEY;
    }
    const char *names[] = {"ipc-key-worker","ipc-key-profile","ipc-key-store","ipc-key-lease",
                           "ipc-key-operation","ipc-key-malformed-length","ipc-key-truncated",
                           "ipc-key-duplicate","ipc-key-version"};
    check(names[kind], ok); finish_child(&child, key);
}
static void forged_reply_tests(void) {
    const char *names[] = {"reply-foreign-worker","reply-stale-sequence","reply-wrong-operation",
        "reply-illegal-state","reply-error-as-ready","reply-wrong-kind","reply-version"};
    for (unsigned kind=0;kind<7;++kind) {
        int sockets[2]; if (socketpair(AF_UNIX,SOCK_STREAM,0,sockets)) exit(4);
        struct vx_child c; vx_child_init(&c); c.identity=context(); c.control_fd=sockets[0];
        struct vx_message request={.context=c.identity,.sequence=1,.opcode=VX_START};
        request.operation[15]=1;
        struct vx_message response=request, output;
        response.opcode=VX_PROTOCOL_READY; response.argument=(uint32_t)VX_READY<<16;
        if(kind==0)response.context.worker[0]^=1;
        if(kind==1)response.sequence=2;
        if(kind==2)response.operation[15]=2;
        if(kind==3)response.argument=(uint32_t)VX_BUSY<<16;
        if(kind==4)response.argument|=VX_KEY_ERROR;
        if(kind==5)response.opcode=VX_DONE;
        bool sent;
        if(kind==6) {
            uint8_t wire[VX_CONTROL_SIZE+4]={0,0,0,VX_CONTROL_SIZE};
            vx_control_encode(wire+4,&response);wire[9]=2;
            sent=vx_write_all(sockets[1],wire,sizeof(wire),vx_now_ms()+1000)==VX_OK;
        } else sent=vx_send(sockets[1],&response,1000)==VX_OK;
        check(names[kind],sent && vx_child_response(&c,&request,VX_PROTOCOL_READY,1000,&output)!=VX_OK &&
              c.state==VX_UNCERTAIN && !c.cleanup_confirmed);
        close(sockets[0]);close(sockets[1]);
    }
}
static void transport_tests(const char *worker,const uint8_t key[32]) {
    struct vx_child child;struct vx_message opening,response,request;
    bool ok=waiting(&child,worker,"normal",&opening);
    if(ok) {
        uint8_t wire[VX_KEY_SIZE];vx_key_encode(wire,&child.identity,opening.operation,key);
        ok=vx_write_all(child.key_fd,wire,120,vx_now_ms()+1000)==VX_OK;
        vx_wipe(wire,sizeof(wire));
    }
    check("cancel-with-partial-secret-frame",ok && exchange(&child,VX_CANCEL,1,VX_CANCELLED) &&
          vx_child_reap(&child,1000)==VX_OK);
    finish_child(&child,key);

    ok=ready(&child,worker,"normal",key);
    if(ok) {
        request=(struct vx_message){.context=child.identity,.sequence=++child.sequence,.opcode=VX_BEGIN};
        request.operation[15]=2;
        uint8_t wire[VX_CONTROL_SIZE+4]={0,0,0,VX_CONTROL_SIZE};vx_control_encode(wire+4,&request);
        for(size_t i=0;i<sizeof(wire)&&ok;++i)
            ok=vx_write_all(child.control_fd,wire+i,1,vx_now_ms()+1000)==VX_OK;
        ok=ok && vx_child_response(&child,&request,VX_ACCEPTED,1000,&response)==VX_OK;
    }
    check("fragmented-control-stream",ok && exchange(&child,VX_FINISH,2,VX_DONE));
    check("fragmented-control-close",vx_child_close(&child,1000)==VX_OK);finish_child(&child,key);

    for(unsigned kind=0;kind<2;++kind) {
        ok=ready(&child,worker,"normal",key);
        if(ok) {
            request=(struct vx_message){.context=child.identity,.sequence=++child.sequence,.opcode=VX_BEGIN};
            request.operation[15]=2;
            uint8_t wire[VX_CONTROL_SIZE+4]={0,0,0,VX_CONTROL_SIZE};vx_control_encode(wire+4,&request);
            size_t count=sizeof(wire);
            if(kind==0){count=24;}else{wire[9]=2;}
            ok=vx_write_all(child.control_fd,wire,count,vx_now_ms()+1000)==VX_OK;
            if(kind==0)shutdown(child.control_fd,SHUT_WR);
            ok=ok && vx_receive(child.control_fd,&response,1000)==VX_OK &&
               response.opcode==VX_REJECTED && (response.argument>>16)==VX_UNCERTAIN;
        }
        check(kind==0?"truncated-control-stream":"incompatible-worker-protocol",ok);
        finish_child(&child,key);
    }

    ok=waiting(&child,worker,"normal",&opening);
    check("missing-key-bounded-startup",ok && vx_receive(child.control_fd,&response,3500)==VX_OK &&
          response.opcode==VX_REJECTED && (response.argument&0xffff)==VX_TIMEOUT);
    finish_child(&child,key);
}
static void registry_tests(const char *worker,const uint8_t key[32]) {
    struct vx_child first,second;struct vx_message opening,response;
    bool ok=waiting(&first,worker,"normal",&opening);
    struct vx_context identity=first.identity;
    identity.worker[0]^=0x80;
    vx_child_init(&second);
    check("registry-refuses-concurrent-scope",ok &&
          vx_child_spawn(&second,worker,&identity,"normal")==VX_SCOPE_ERROR && second.pid==-1);
    check("registry-clean-close",vx_child_close(&first,1000)==VX_OK);
    finish_child(&first,key);
    check("registry-refuses-stale-open",vx_child_spawn(&second,worker,&identity,"normal")==VX_STALE);
    ++identity.lease;
    ok=vx_child_spawn(&second,worker,&identity,"normal")==VX_OK &&
       vx_child_request(&second,VX_START,1,&opening)==VX_OK &&
       vx_child_response(&second,&opening,VX_WAITING,1000,&response)==VX_OK;
    check("registry-allows-fresh-generation-after-clean-close",ok);
    check("registry-reopened-close",vx_child_close(&second,1000)==VX_OK);
    finish_child(&second,key);

    ok=ready(&first,worker,"close-timeout",key);
    identity=first.identity;identity.worker[0]^=0x80;++identity.lease;
    check("registry-timeout-quarantines-scope",ok && vx_child_close(&first,100)==VX_TIMEOUT);
    finish_child(&first,key);
    vx_child_init(&second);
    check("registry-refuses-new-worker-after-uncertain-cleanup",
          vx_child_spawn(&second,worker,&identity,"normal")==VX_SCOPE_ERROR && second.pid==-1);
}
int main(int argc, char **argv) {
    struct rlimit core_limit = {0, 0};
    if (setrlimit(RLIMIT_CORE, &core_limit)) return 4;
    signal(SIGPIPE, SIG_IGN);
    if (argc != 2) return 4;
    const char *worker = argv[1]; protocol_tests();
    uint8_t key[32]; key_material(key);
    forged_reply_tests();
    transport_tests(worker,key);
    registry_tests(worker,key);
    struct vx_child child; struct vx_message request, response, opening;
    bool ok = ready(&child, worker, "normal", key);
    check("startup-and-key-ownership", ok);
    check("active-operation", ok && exchange(&child,VX_BEGIN,2,VX_ACCEPTED) &&
          exchange(&child,VX_FINISH,2,VX_DONE));
    check("graceful-close", vx_child_close(&child,1000)==VX_OK && child.cleanup_confirmed && child.reaped);
    struct vx_context c = context();
    check("closed-instance-never-reused", vx_child_spawn(&child,worker,&c,"normal")==VX_STATE_ERROR);
    finish_child(&child,key);

    vx_child_init(&child); c=context();
    check("startup-exec-failure", vx_child_spawn(&child,"/nonexistent-vx-worker",&c,"normal")==VX_IO_ERROR &&
          child.state==VX_UNCERTAIN && child.used);
    check("failed-start-never-reused",vx_child_spawn(&child,worker,&c,"normal")==VX_STATE_ERROR);
    vx_child_retire(&child);
    vx_child_init(&child); c=context(); c.scope_kind=2;
    check("private-refused-before-spawn",vx_child_spawn(&child,worker,&c,"normal")==VX_PRIVATE &&
          child.pid==-1 && !child.used && child.control_fd==-1 && child.key_fd==-1);

    /* Bypass parent policy only in this negative test to prove child enforcement. */
    c=context(); vx_child_init(&child);
    ok=vx_child_spawn(&child,worker,&c,"normal")==VX_OK;
    if(ok) {
        /* Child bootstrap identity is persistent, so a private request is foreign. */
        request=(struct vx_message){.opcode=VX_START,.context=c,.sequence=1};
        request.operation[15]=1; request.context.scope_kind=2;
        ok=vx_send(child.control_fd,&request,1000)==VX_OK &&
           vx_receive(child.control_fd,&response,1000)==VX_OK && response.opcode==VX_REJECTED &&
           (response.argument & 0xffff)==VX_PRIVATE;
    }
    check("worker-refuses-private-message",ok);finish_child(&child,key);

    ok=waiting(&child,worker,"normal",&opening);
    check("startup-cancel",ok && exchange(&child,VX_CANCEL,1,VX_CANCELLED) &&
          vx_child_reap(&child,1000)==VX_OK);
    finish_child(&child,key);
    ok=ready(&child,worker,"normal",key);
    check("active-cancel",ok && exchange(&child,VX_BEGIN,2,VX_ACCEPTED) &&
          exchange(&child,VX_CANCEL,2,VX_CANCELLED) && child.state==VX_READY);
    check("cancelled-operation-cannot-finish",exchange(&child,VX_FINISH,2,VX_REJECTED));
    check("close-after-cancel",vx_child_close(&child,1000)==VX_OK);finish_child(&child,key);

    ok=ready(&child,worker,"normal",key);
    check("close-cancels-active-operation-first",ok && exchange(&child,VX_BEGIN,2,VX_ACCEPTED) &&
          vx_child_close(&child,1000)==VX_OK && child.cleanup_confirmed);
    finish_child(&child,key);

    ok=waiting(&child,worker,"normal",&opening);
    check("concurrent-start-refused",ok && exchange(&child,VX_START,2,VX_REJECTED));
    check("pending-start-can-close",vx_child_close(&child,1000)==VX_OK);finish_child(&child,key);

    ok=ready(&child,worker,"normal",key);
    check("duplicate-operation",ok && exchange(&child,VX_BEGIN,2,VX_ACCEPTED) &&
          exchange(&child,VX_FINISH,2,VX_DONE) && exchange(&child,VX_BEGIN,2,VX_REJECTED) &&
          child.state==VX_UNCERTAIN);
    finish_child(&child,key);

    ok=ready(&child,worker,"close-timeout",key);
    check("close-timeout",ok && vx_child_close(&child,100)==VX_TIMEOUT &&
          child.state==VX_UNCERTAIN && !child.cleanup_confirmed);
    check("uncertain-instance-refused",vx_child_spawn(&child,worker,&c,"normal")==VX_STATE_ERROR);
    finish_child(&child,key);
    ok=ready(&child,worker,"close-failure",key);
    check("close-failure",ok && vx_child_close(&child,1000)!=VX_OK &&
          child.state==VX_UNCERTAIN && !child.cleanup_confirmed);
    finish_child(&child,key);

    ok=ready(&child,worker,"normal",key);
    if(ok) ok=kill(child.pid,SIGKILL)==0;
    check("unexpected-exit",ok && vx_child_reap(&child,1000)==VX_CHILD_EXIT &&
          child.state==VX_UNCERTAIN && !child.cleanup_confirmed);
    finish_child(&child,key);

    ok=waiting(&child,worker,"normal",&opening);
    if(ok) ok=kill(child.pid,SIGKILL)==0;
    check("termination-during-startup",ok && vx_child_reap(&child,1000)==VX_CHILD_EXIT &&
          child.state==VX_UNCERTAIN);
    finish_child(&child,key);

    for(unsigned i=0;i<7;++i) invalid_control_case(worker,i,key);
    for(unsigned i=0;i<9;++i) invalid_key_case(worker,i,key);

    ok=ready(&child,worker,"normal",key);
    if(ok) {
        uint8_t oversized[4]={0,0,255,255};
        ok=vx_write_all(child.control_fd,oversized,4,vx_now_ms()+1000)==VX_OK &&
           vx_receive(child.control_fd,&response,1000)==VX_OK && response.opcode==VX_REJECTED;
    }
    check("oversized-control-frame",ok);finish_child(&child,key);

    vx_wipe(key,sizeof(key));check("supervisor-key-retired",vx_zero(key,sizeof(key)));
    printf("{\"summary\":true,\"passed\":%u,\"failed\":%u}\n",passed,failed);
    return failed ? 1 : 0;
}
