#include "descriptor_vfs.h"

#include <CommonCrypto/CommonDigest.h>
#include <Security/Security.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define FIXTURE_SCHEMA "CREATE TABLE identity(scope TEXT,store TEXT,schema_id TEXT,suite TEXT,key_version INTEGER)"
#define FIXTURE_SCOPE "132959cb-d52c-4346-8f3d-b6ecf4668ea7"
#define FIXTURE_STORE "3485ee37-fd82-4870-aa21-25f8ccf4d341"
#define FIXTURE_SUITE "sqlcipher-4.20.0-v4"
#define FIXTURE_FILE "fixture.db"

static bool execute(sqlite3 *db, const char *sql) {
    return sqlite3_exec(db, sql, NULL, NULL, NULL) == SQLITE_OK;
}

static bool check_values(sqlite3 *db, const char *sql, const char *const *expected, int columns) {
    sqlite3_stmt *query = NULL;
    int rc = sqlite3_prepare_v2(db, sql, -1, &query, NULL);
    bool matches = rc == SQLITE_OK && sqlite3_column_count(query) == columns &&
        sqlite3_step(query) == SQLITE_ROW;
    for (int i = 0; matches && i < columns; i++) {
        const unsigned char *value = sqlite3_column_text(query, i);
        size_t bytes = strlen(expected[i]);
        matches = value && sqlite3_column_bytes(query, i) == (int)bytes &&
            memcmp(value, expected[i], bytes) == 0;
    }
    if (matches) matches = sqlite3_step(query) == SQLITE_DONE;
    return sqlite3_finalize(query) == SQLITE_OK && matches;
}

static bool check_value(sqlite3 *db, const char *sql, const char *expected) {
    return check_values(db, sql, &expected, 1);
}

static bool configure(sqlite3 *db) {
    return execute(db, "PRAGMA cipher_compatibility=4; PRAGMA cipher_memory_security=ON;"
                       "PRAGMA temp_store=MEMORY; PRAGMA trusted_schema=OFF") &&
        check_value(db, "PRAGMA cipher_version", "4.20.0 community") &&
        check_value(db, "PRAGMA cipher_provider", "commoncrypto") &&
        check_value(db, "PRAGMA cipher_page_size", "4096") &&
        check_value(db, "PRAGMA kdf_iter", "256000") &&
        check_value(db, "PRAGMA cipher_use_hmac", "1") &&
        check_value(db, "PRAGMA cipher_hmac_algorithm", "HMAC_SHA512") &&
        check_value(db, "PRAGMA cipher_kdf_algorithm", "PBKDF2_HMAC_SHA512") &&
        check_value(db, "PRAGMA cipher_plaintext_header_size", "0") &&
        check_value(db, "PRAGMA cipher_memory_security", "1");
}

static bool bind_key(struct wsf3_vfs *scope, sqlite3 *db, const unsigned char key[32]) {
    if (scope->violated || scope->forwarded_pre_key_reads != 1) return false;
    wsf3_transition(scope, WSF3_BINDING);
    if (sqlite3_key_v2(db, "main", key, 32) != SQLITE_OK || scope->violated) return false;
    wsf3_transition(scope, WSF3_KEY_APPLIED);
    return true;
}

static bool authenticate(sqlite3 *db, const char *profile, const char *store, const char *schema,
                         const char *suite, const char *key_version) {
    const char *expected[] = {profile, store, schema, suite, key_version};
    return check_value(db, "SELECT sql FROM main.sqlite_schema WHERE type='table' AND name='identity'",
                       FIXTURE_SCHEMA) &&
        check_values(db, "SELECT scope,store,schema_id,suite,key_version FROM main.identity",
                     expected, 5);
}

static bool persist_fixture(int root, struct wsf3_vfs *scope, const char *test) {
    size_t size = scope->scratch_size;
    if (size < 8192 || !memcmp(scope->scratch, "SQLite format 3", 15)) return false;
    if (!strcmp(test, "corrupt")) scope->scratch[4096] ^= 0x40;
    if (!strcmp(test, "invalid-header")) size = 16;
    int fd = openat(root, FIXTURE_FILE, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
    if (fd < 0) return false;
    size_t offset = 0;
    while (offset < size) {
        ssize_t count = write(fd, scope->scratch + offset, size - offset);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) break;
        offset += (size_t)count;
    }
    bool ok = offset == size && fchmod(fd, 0400) == 0 && fsync(fd) == 0;
    return close(fd) == 0 && ok;
}

static bool seed_fixture(int root, const unsigned char key[32], const char *test) {
    struct wsf3_vfs scope;
    if (wsf3_register(&scope, -1, true) != SQLITE_OK) return false;
    sqlite3 *db = NULL;
    bool ok = sqlite3_open_v2("/main", &db, SQLITE_OPEN_READWRITE, scope.vfs.zName) == SQLITE_OK &&
        bind_key(&scope, db, key) && configure(db);
    if (ok) {
        wsf3_transition(&scope, WSF3_FRESH_INITIALIZATION);
        ok = check_value(db, "PRAGMA journal_mode=MEMORY", "memory") &&
            execute(db, FIXTURE_SCHEMA "; INSERT INTO identity VALUES('" FIXTURE_SCOPE
                        "','" FIXTURE_STORE "','1','" FIXTURE_SUITE "',1)") &&
            authenticate(db, FIXTURE_SCOPE, FIXTURE_STORE, "1", FIXTURE_SUITE, "1");
    }
    bool closed = sqlite3_close(db) == SQLITE_OK;
    sqlite3_vfs_unregister(&scope.vfs);
    printf("{\"event\":\"fixture_generation\",\"result\":\"%s\",\"policy_violation\":%s}\n",
           ok && closed ? "ready" : "failure", scope.violated ? "true" : "false");
    return ok && closed && !scope.violated && persist_fixture(root, &scope, test);
}

static bool no_sidecars(int root) {
    const char *paths[] = {FIXTURE_FILE "-journal", FIXTURE_FILE "-wal", FIXTURE_FILE "-shm"};
    struct stat info;
    for (size_t i = 0; i < sizeof(paths) / sizeof(paths[0]); i++) {
        if (fstatat(root, paths[i], &info, AT_SYMLINK_NOFOLLOW) == 0 || errno != ENOENT) return false;
    }
    return true;
}

static bool fingerprint(int fd, unsigned char digest[CC_SHA256_DIGEST_LENGTH]) {
    unsigned char bytes[WSF3_FIXTURE_LIMIT + 1];
    size_t size = 0;
    while (size < sizeof(bytes)) {
        ssize_t count = pread(fd, bytes + size, sizeof(bytes) - size, (off_t)size);
        if (count < 0 && errno == EINTR) continue;
        if (count < 0) return false;
        if (count == 0) break;
        size += (size_t)count;
    }
    return size < sizeof(bytes) && CC_SHA256(bytes, (CC_LONG)size, digest) != NULL;
}

static bool reopen(int root, const unsigned char key[32], const char *test) {
    bool sidecars_absent = no_sidecars(root);
    if (!sidecars_absent || !strcmp(test, "missing-key")) {
        printf("{\"event\":\"admission_refused\",\"reason\":\"%s\"}\n",
               sidecars_absent ? "key_absent" : "sidecar_present_or_unknown");
        return (sidecars_absent && !strcmp(test, "missing-key")) ||
            (!sidecars_absent && !strcmp(test, "sidecar"));
    }
    int fd = openat(root, FIXTURE_FILE, O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK);
    if (fd < 0) {
        bool missing = errno == ENOENT;
        puts("{\"event\":\"admission_refused\",\"reason\":\"file_open_failed\"}");
        return !strcmp(test, "missing") && missing;
    }
    struct stat info;
    struct wsf3_vfs scope;
    if (fstat(fd, &info) || !S_ISREG(info.st_mode) || info.st_nlink != 1 || info.st_uid != geteuid() ||
        (info.st_mode & 0777) != 0400 || info.st_size <= 0 || info.st_size > WSF3_FIXTURE_LIMIT ||
        wsf3_register(&scope, fd, false) != SQLITE_OK) {
        close(fd);
        return false;
    }
    sqlite3 *db = NULL;
    unsigned char before[CC_SHA256_DIGEST_LENGTH], after[CC_SHA256_DIGEST_LENGTH];
    bool bound = sqlite3_open_v2("/main", &db, SQLITE_OPEN_READONLY, scope.vfs.zName) == SQLITE_OK &&
        bind_key(&scope, db, key);
    bool baseline = bound && fingerprint(fd, before);
    if (baseline) puts("{\"event\":\"fingerprint\",\"phase\":\"key_applied\",\"database\":\"main\"}");
    bool configured = baseline && configure(db);
    bool ready = false;
    if (configured) {
        wsf3_transition(&scope, WSF3_AUTHENTICATING);
        ready = authenticate(db, !strcmp(test, "foreign") ? "foreign" : FIXTURE_SCOPE,
                             !strcmp(test, "wrong-store") ? "foreign" : FIXTURE_STORE,
                             !strcmp(test, "wrong-schema") ? "2" : "1",
                             !strcmp(test, "wrong-suite") ? "other" : FIXTURE_SUITE,
                             !strcmp(test, "wrong-version") ? "2" : "1") && !scope.violated;
        if (ready) wsf3_transition(&scope, WSF3_READY);
    }
    bool closed = sqlite3_close(db) == SQLITE_OK;
    sqlite3_vfs_unregister(&scope.vfs);
    bool preserved = baseline && !scope.violated && fingerprint(fd, after) && memcmp(before, after, sizeof(before)) == 0;
    bool fd_closed = close(fd) == 0;
    bool ok = configured && closed && fd_closed && preserved && no_sidecars(root) &&
        !scope.violated && scope.forwarded_pre_key_reads == 1 &&
        ready == (!strcmp(test, "valid"));
    printf("{\"event\":\"fence\",\"bound\":%s,\"configured\":%s,\"ready\":%s,"
           "\"write_authorized\":false,\"content_preserved\":%s,\"policy_violation\":%s}\n",
           bound ? "true" : "false", configured ? "true" : "false", ready ? "true" : "false",
           preserved ? "true" : "false", scope.violated ? "true" : "false");
    return ok;
}

static bool allowed_test(const char *test) {
    const char *cases[] = {"valid", "wrong-key", "foreign", "wrong-store", "wrong-schema",
        "wrong-suite", "wrong-version", "corrupt", "invalid-header", "missing", "missing-key", "sidecar"};
    for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); i++) {
        if (!strcmp(test, cases[i])) return true;
    }
    return false;
}

int main(int argc, char **argv) {
    if (argc != 3 || !allowed_test(argv[2])) return 2;
    if (strcmp(sqlite3_libversion(), "3.54.1") || !sqlite3_compileoption_used("TEMP_STORE=3")) return 3;
    int root = open(argv[1], O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    struct stat info;
    if (root < 0 || fstat(root, &info) || info.st_uid != geteuid() || (info.st_mode & 0777) != 0700)
        return 4;
    if (fstatat(root, FIXTURE_FILE, &info, AT_SYMLINK_NOFOLLOW) == 0 || errno != ENOENT) {
        close(root);
        return 4;
    }
    unsigned char key[32];
    bool ok = SecRandomCopyBytes(kSecRandomDefault, sizeof(key), key) == errSecSuccess;
    if (ok && strcmp(argv[2], "missing")) ok = seed_fixture(root, key, argv[2]);
    if (ok && !strcmp(argv[2], "sidecar")) {
        int sidecar = openat(root, FIXTURE_FILE "-wal", O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600);
        ok = sidecar >= 0 && close(sidecar) == 0;
    }
    if (!strcmp(argv[2], "wrong-key")) key[0] ^= 1;
    if (ok) ok = reopen(root, key, argv[2]);
    for (volatile unsigned char *byte = key; byte != key + sizeof(key); byte++) *byte = 0;
    if (close(root)) ok = false;
    printf("{\"event\":\"result\",\"case\":\"%s\",\"pass\":%s}\n", argv[2], ok ? "true" : "false");
    return ok ? 0 : 1;
}
