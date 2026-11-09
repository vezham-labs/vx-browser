#include "descriptor_vfs.h"

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

struct descriptor_file {
    sqlite3_file base;
    struct wsf3_vfs *scope;
};

static struct wsf3_vfs *context(sqlite3_file *file) {
    return ((struct descriptor_file *)file)->scope;
}

static const char *phase_name(enum wsf3_phase phase) {
    switch (phase) {
        case WSF3_CONSTRUCTION: return "construction";
        case WSF3_BINDING: return "binding";
        case WSF3_KEY_APPLIED: return "key_applied";
        case WSF3_AUTHENTICATING: return "authenticating";
        case WSF3_READY: return "read_only_ready";
        case WSF3_FRESH_INITIALIZATION: return "fresh_initialization";
    }
    return "invalid";
}

void wsf3_transition(struct wsf3_vfs *scope, enum wsf3_phase next) {
    scope->phase = next;
    if (!scope->fresh) {
        printf("{\"event\":\"phase\",\"database\":\"main\",\"phase\":\"%s\"}\n", phase_name(next));
    }
}

static int deny(struct wsf3_vfs *scope, const char *operation, int error) {
    scope->violated = true;
    if (!scope->fresh) {
        printf("{\"event\":\"denied\",\"operation\":\"%s\",\"phase\":\"%s\"}\n",
               operation, phase_name(scope->phase));
    }
    return error;
}

static int read_bytes(sqlite3_file *file, void *out, int size, sqlite3_int64 offset) {
    struct wsf3_vfs *scope = context(file);
    bool before_key = scope->phase < WSF3_KEY_APPLIED;
    bool allowed = !scope->violated && size > 0 && offset >= 0 && offset <= INT64_MAX - size &&
        (!before_key || (scope->phase == WSF3_CONSTRUCTION && scope->requests == 0 &&
                         offset == 0 && size == 100));
    scope->requests++;
    if (!scope->fresh) {
        printf("{\"event\":\"xRead\",\"database\":\"main\",\"sequence\":%u,"
               "\"phase\":\"%s\",\"offset\":%lld,\"length\":%d,\"forwarded\":%s}\n",
               scope->requests, phase_name(scope->phase), (long long)offset, size, allowed ? "true" : "false");
    }
    if (!allowed) return deny(scope, "xRead", SQLITE_IOERR_READ);
    if (before_key) scope->forwarded_pre_key_reads++;
    ssize_t got;
    if (scope->fresh) {
        size_t available = (uint64_t)offset >= scope->scratch_size ? 0 : scope->scratch_size - (size_t)offset;
        got = (size_t)size < available ? size : (ssize_t)available;
        if (got) memcpy(out, scope->scratch + (size_t)offset, (size_t)got);
    } else {
        do {
            got = pread(scope->descriptor, out, (size_t)size, offset);
        } while (got < 0 && errno == EINTR);
    }
    if (got < 0) return SQLITE_IOERR_READ;
    if (got == size) return SQLITE_OK;
    memset((unsigned char *)out + got, 0, (size_t)(size - got));
    return SQLITE_IOERR_SHORT_READ;
}

static bool can_initialize(const struct wsf3_vfs *scope) {
    return scope->fresh && scope->phase == WSF3_FRESH_INITIALIZATION && !scope->violated;
}

static int write_bytes(sqlite3_file *file, const void *in, int size, sqlite3_int64 offset) {
    struct wsf3_vfs *scope = context(file);
    if (!can_initialize(scope)) return deny(scope, "xWrite", SQLITE_IOERR_WRITE);
    if (size < 0 || offset < 0 || size > WSF3_FIXTURE_LIMIT || offset > WSF3_FIXTURE_LIMIT - size)
        return SQLITE_IOERR_WRITE;
    memcpy(scope->scratch + offset, in, (size_t)size);
    size_t end = (size_t)offset + (size_t)size;
    if (end > scope->scratch_size) scope->scratch_size = end;
    return SQLITE_OK;
}

static int truncate_file(sqlite3_file *file, sqlite3_int64 size) {
    struct wsf3_vfs *scope = context(file);
    if (!can_initialize(scope)) return deny(scope, "xTruncate", SQLITE_IOERR_TRUNCATE);
    if (size < 0 || size > WSF3_FIXTURE_LIMIT) return SQLITE_IOERR_TRUNCATE;
    if ((size_t)size < scope->scratch_size)
        memset(scope->scratch + size, 0, scope->scratch_size - (size_t)size);
    scope->scratch_size = (size_t)size;
    return SQLITE_OK;
}

static int sync_file(sqlite3_file *file, int flags) {
    (void)flags;
    struct wsf3_vfs *scope = context(file);
    return can_initialize(scope) ? SQLITE_OK : deny(scope, "xSync", SQLITE_IOERR_FSYNC);
}

static int file_size(sqlite3_file *file, sqlite3_int64 *size) {
    struct wsf3_vfs *scope = context(file);
    if (scope->fresh) {
        *size = (sqlite3_int64)scope->scratch_size;
        return SQLITE_OK;
    }
    struct stat stat;
    if (fstat(scope->descriptor, &stat)) return SQLITE_IOERR_FSTAT;
    *size = stat.st_size;
    return SQLITE_OK;
}

static int close_file(sqlite3_file *file) { file->pMethods = NULL; return SQLITE_OK; }
static int lock_file(sqlite3_file *file, int level) {
    struct wsf3_vfs *scope = context(file);
    if (level > SQLITE_LOCK_SHARED && !can_initialize(scope))
        return deny(scope, "xLock", SQLITE_IOERR_LOCK);
    return SQLITE_OK;
}
static int unlock_file(sqlite3_file *file, int level) { (void)file; (void)level; return SQLITE_OK; }
static int reserved(sqlite3_file *file, int *result) { (void)file; *result = 0; return SQLITE_OK; }
static int control(sqlite3_file *file, int op, void *arg) {
    (void)file; (void)op; (void)arg;
    return SQLITE_NOTFOUND;
}
static int sector(sqlite3_file *file) { (void)file; return 4096; }
static int characteristics(sqlite3_file *file) { (void)file; return 0; }

static const sqlite3_io_methods methods = {
    .iVersion = 1,
    .xClose = close_file, .xRead = read_bytes, .xWrite = write_bytes,
    .xTruncate = truncate_file, .xSync = sync_file, .xFileSize = file_size,
    .xLock = lock_file, .xUnlock = unlock_file, .xCheckReservedLock = reserved,
    .xFileControl = control, .xSectorSize = sector, .xDeviceCharacteristics = characteristics
};

static int open_main(sqlite3_vfs *vfs, sqlite3_filename name, sqlite3_file *file, int flags, int *out_flags) {
    struct wsf3_vfs *scope = vfs->pAppData;
    file->pMethods = NULL;
    int expected = SQLITE_OPEN_MAIN_DB | (scope->fresh ? SQLITE_OPEN_READWRITE : SQLITE_OPEN_READONLY);
    if (!name || strcmp(name, "/main") || flags != expected)
        return deny(scope, "xOpen", SQLITE_CANTOPEN);
    ((struct descriptor_file *)file)->scope = scope;
    if (out_flags) *out_flags = flags;
    file->pMethods = &methods;
    return SQLITE_OK;
}

static int delete_file(sqlite3_vfs *vfs, const char *name, int sync_dir) {
    (void)name; (void)sync_dir;
    return deny(vfs->pAppData, "xDelete", SQLITE_IOERR_DELETE);
}

// The harness supplies a single exclusive fixture descriptor. No other path exists in
// this virtual namespace. The caller must reject physical sidecars before admission.
static int access_file(sqlite3_vfs *vfs, const char *name, int flags, int *result) {
    (void)vfs; (void)flags;
    *result = strcmp(name, "/main") == 0;
    return SQLITE_OK;
}

static int full_path(sqlite3_vfs *vfs, const char *name, int size, char *out) {
    (void)vfs;
    if (size < (int)sizeof("/main") || strcmp(name, "/main")) return SQLITE_CANTOPEN;
    memcpy(out, "/main", sizeof("/main"));
    return SQLITE_OK;
}

static int random_bytes(sqlite3_vfs *vfs, int size, char *out) {
    struct wsf3_vfs *scope = vfs->pAppData;
    return scope->system->xRandomness(scope->system, size, out);
}
static int sleep_us(sqlite3_vfs *vfs, int microseconds) {
    struct wsf3_vfs *scope = vfs->pAppData;
    return scope->system->xSleep(scope->system, microseconds);
}
static int current_time(sqlite3_vfs *vfs, double *out) {
    struct wsf3_vfs *scope = vfs->pAppData;
    return scope->system->xCurrentTime(scope->system, out);
}

int wsf3_register(struct wsf3_vfs *scope, int descriptor, bool fresh) {
    memset(scope, 0, sizeof(*scope));
    scope->descriptor = descriptor;
    scope->fresh = fresh;
    scope->system = sqlite3_vfs_find(NULL);
    if (!scope->system) return SQLITE_ERROR;
    scope->vfs = (sqlite3_vfs){
        .iVersion = 1, .szOsFile = sizeof(struct descriptor_file), .mxPathname = 32,
        .zName = "wsf3-fixture-descriptor", .pAppData = scope,
        .xOpen = open_main, .xDelete = delete_file, .xAccess = access_file, .xFullPathname = full_path,
        .xRandomness = random_bytes, .xSleep = sleep_us, .xCurrentTime = current_time
    };
    wsf3_transition(scope, WSF3_CONSTRUCTION);
    return sqlite3_vfs_register(&scope->vfs, 0);
}
