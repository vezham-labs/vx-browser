// Isolated encrypted snapshot writer. The original protected database is opened
// read-only behind the retained pre-key fence. Changes occur in a fresh RAM VFS
// and only ciphertext is atomically published after authentication and commit.
// Production admission remains gated separately from qualification compilation.
#ifndef VEZHAM_STORE_TESTING
#error "This worker is restricted to disposable qualification builds."
#endif
#include "descriptor_vfs.h"
#include <Security/Security.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <unistd.h>

#define MAIN "catalog.vws"
#define PRIOR "catalog.previous.vws"
#define STAGE "catalog.publish.tmp"
#define PREV_STAGE "catalog.previous.tmp"
#define LIMIT (256 * 1024)
#define DDL                                                                    \
  "CREATE TABLE identity(profile TEXT NOT NULL,store TEXT NOT "                \
  "NULL,schema_version INTEGER NOT NULL,key_version INTEGER NOT NULL)"
#define STATE                                                                  \
  "CREATE TABLE workspace(revision INTEGER PRIMARY KEY "                       \
  "CHECK(revision>=0),payload BLOB NOT NULL)"
// Status codes never include filenames, payloads, keys, titles or SQL errors.
enum {
  OK = 0,
  DENIED = 1,
  CORRUPT = 2,
  CONFLICT = 3,
  IO = 4,
  FUTURE = 5,
  UNKNOWN = 6,
  RECOVERY = 7
};
static int io_all(int fd, void *data, size_t n, int writing) {
  unsigned char *p = data;
  while (n) {
    ssize_t got = writing ? write(fd, p, n) : read(fd, p, n);
    if (got < 0 && errno == EINTR)
      continue;
    if (got <= 0)
      return 0;
    p += got;
    n -= got;
  }
  return 1;
}
static void reply(uint32_t status, uint64_t rev, const void *payload,
                  uint32_t size) {
  uint64_t header[3] = {status, rev, size};
  if (!io_all(STDOUT_FILENO, header, sizeof(header), 1))
    return;
  if (size)
    io_all(STDOUT_FILENO, (void *)payload, size, 1);
}
static int exists(int root, const char *name) {
  struct stat st;
  return fstatat(root, name, &st, AT_SYMLINK_NOFOLLOW) == 0 || errno != ENOENT;
}
static int regular(int fd, mode_t mode) {
  struct stat st;
  return fstat(fd, &st) == 0 && S_ISREG(st.st_mode) && st.st_uid == geteuid() &&
         st.st_nlink == 1 && (st.st_mode & 0777) == mode;
}
static int scalar(sqlite3 *db, const char *sql, const char *wanted) {
  sqlite3_stmt *s = NULL;
  int ok = sqlite3_prepare_v2(db, sql, -1, &s, NULL) == SQLITE_OK &&
           sqlite3_step(s) == SQLITE_ROW;
  const unsigned char *text = ok ? sqlite3_column_text(s, 0) : NULL;
  ok = ok && text && strcmp((const char *)text, wanted) == 0 &&
       sqlite3_step(s) == SQLITE_DONE;
  sqlite3_finalize(s);
  return ok;
}
static int sql(sqlite3 *db, const char *text) {
  return sqlite3_exec(db, text, NULL, NULL, NULL) == SQLITE_OK;
}
static int configure(sqlite3 *db) {
  return sql(db, "PRAGMA cipher_compatibility=4; PRAGMA "
                 "cipher_memory_security=ON;") &&
         scalar(db, "PRAGMA cipher_version", "4.20.0 community") &&
         scalar(db, "PRAGMA cipher_provider", "commoncrypto") &&
         scalar(db, "PRAGMA cipher_page_size", "4096") &&
         scalar(db, "PRAGMA kdf_iter", "256000") &&
         scalar(db, "PRAGMA cipher_use_hmac", "1") &&
         scalar(db, "PRAGMA cipher_hmac_algorithm", "HMAC_SHA512") &&
         scalar(db, "PRAGMA cipher_kdf_algorithm", "PBKDF2_HMAC_SHA512") &&
         scalar(db, "PRAGMA cipher_plaintext_header_size", "0");
}
static int open_db(struct wsf3_vfs *v, int fd, int fresh,
                   const unsigned char key[32], sqlite3 **db) {
  if (wsf3_register(v, fd, fresh) != SQLITE_OK)
    return 0;
  if (sqlite3_open_v2("/main", db,
                      fresh ? SQLITE_OPEN_READWRITE : SQLITE_OPEN_READONLY,
                      v->vfs.zName) != SQLITE_OK ||
      v->violated || v->forwarded_pre_key_reads != 1)
    return 0;
  wsf3_transition(v, WSF3_BINDING);
  if (sqlite3_key_v2(*db, "main", key, 32) != SQLITE_OK)
    return 0;
  wsf3_transition(v, WSF3_KEY_APPLIED);
  if (!configure(*db))
    return 0;
  wsf3_transition(v, fresh ? WSF3_FRESH_INITIALIZATION : WSF3_AUTHENTICATING);
  return !fresh || scalar(*db, "PRAGMA journal_mode=MEMORY", "memory");
}
static int identity(sqlite3 *db, const char *profile, const char *store) {
  if (!scalar(db, "SELECT sql FROM sqlite_schema WHERE name='identity'", DDL) ||
      !scalar(db, "SELECT sql FROM sqlite_schema WHERE name='workspace'",
              STATE))
    return CORRUPT;
  sqlite3_stmt *s = NULL;
  int result = CORRUPT;
  if (sqlite3_prepare_v2(
          db, "SELECT profile,store,schema_version,key_version FROM identity",
          -1, &s, NULL) == SQLITE_OK &&
      sqlite3_step(s) == SQLITE_ROW) {
    const char *p = (const char *)sqlite3_column_text(s, 0),
               *t = (const char *)sqlite3_column_text(s, 1);
    int schema = sqlite3_column_int(s, 2);
    if (p && t && !strcmp(p, profile) && !strcmp(t, store) &&
        sqlite3_column_int(s, 3) == 1)
      result = schema > 1 ? FUTURE : schema == 1 ? OK : CORRUPT;
    else
      result = DENIED;
    if (sqlite3_step(s) != SQLITE_DONE)
      result = CORRUPT;
  }
  sqlite3_finalize(s);
  return result;
}
static int read_state(sqlite3 *db, uint64_t *revision, unsigned char **payload,
                      uint32_t *size) {
  sqlite3_stmt *s = NULL;
  int ok = sqlite3_prepare_v2(db, "SELECT revision,payload FROM workspace", -1,
                              &s, NULL) == SQLITE_OK &&
           sqlite3_step(s) == SQLITE_ROW;
  sqlite3_int64 rev = ok ? sqlite3_column_int64(s, 0) : -1;
  int n = ok ? sqlite3_column_bytes(s, 1) : -1;
  if (ok && rev >= 0 && rev <= 9007199254740991LL && n >= 0 && n <= LIMIT) {
    const void *bytes = sqlite3_column_blob(s, 1);
    *payload = malloc(n ? n : 1);
    if (!*payload)
      ok = 0;
    else {
      if (n)
        memcpy(*payload, bytes, n);
      *size = (uint32_t)n;
      *revision = (uint64_t)rev;
      ok = sqlite3_step(s) == SQLITE_DONE;
    }
  } else
    ok = 0;
  sqlite3_finalize(s);
  return ok;
}
static int new_identity(sqlite3 *db, const char *profile, const char *store) {
  if (!sql(db, DDL ";" STATE))
    return 0;
  sqlite3_stmt *s = NULL;
  int ok = sqlite3_prepare_v2(db, "INSERT INTO identity VALUES(?1,?2,1,1)", -1,
                              &s, NULL) == SQLITE_OK;
  if (ok) {
    sqlite3_bind_text(s, 1, profile, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(s, 2, store, -1, SQLITE_TRANSIENT);
    ok = sqlite3_step(s) == SQLITE_DONE;
  }
  sqlite3_finalize(s);
  return ok;
}
static int change(sqlite3 *db, uint64_t revision, const unsigned char *payload,
                  uint32_t size) {
  if (!sql(db, "BEGIN IMMEDIATE;DELETE FROM workspace"))
    return 0;
  sqlite3_stmt *s = NULL;
  int ok = sqlite3_prepare_v2(db, "INSERT INTO workspace VALUES(?1,?2)", -1, &s,
                              NULL) == SQLITE_OK;
  if (ok) {
    sqlite3_bind_int64(s, 1, (sqlite3_int64)revision);
    sqlite3_bind_blob(s, 2, payload, (int)size, SQLITE_TRANSIENT);
    ok = sqlite3_step(s) == SQLITE_DONE;
  }
  sqlite3_finalize(s);
  if (ok)
    ok = sql(db, "COMMIT");
  if (!ok)
    sql(db, "ROLLBACK");
  return ok;
}
static int cleanup_stage(int root, const char *name) {
  int fd = openat(root, name, O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK);
  if (fd < 0)
    return errno == ENOENT;
  int ok = regular(fd, 0600) || regular(fd, 0400);
  close(fd);
  return ok && unlinkat(root, name, 0) == 0;
}
static int stage_bytes(int root, const char *name, const void *bytes,
                       size_t size) {
  int fd = openat(root, name,
                  O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
  if (fd < 0)
    return 0;
  int ok = io_all(fd, (void *)bytes, size, 1) && fchmod(fd, 0400) == 0 &&
           fsync(fd) == 0 && fcntl(fd, F_FULLFSYNC) == 0;
  if (close(fd) != 0)
    ok = 0;
  return ok;
}
static int publish(int root, int previous, struct wsf3_vfs *target,
                   const char *fail) {
  if (!cleanup_stage(root, STAGE) || !cleanup_stage(root, PREV_STAGE))
    return IO;
  if (previous >= 0) {
    struct stat st;
    if (fstat(previous, &st) || st.st_size <= 0 ||
        st.st_size > WSF3_FIXTURE_LIMIT)
      return IO;
    unsigned char *bytes = malloc((size_t)st.st_size);
    if (!bytes)
      return IO;
    ssize_t got = pread(previous, bytes, (size_t)st.st_size, 0);
    int ok = got == st.st_size &&
             stage_bytes(root, PREV_STAGE, bytes, (size_t)st.st_size);
    free(bytes);
    if (!ok || renameat(root, PREV_STAGE, root, PRIOR) || fsync(root))
      return IO;
  }
  if (!stage_bytes(root, STAGE, target->scratch, target->scratch_size))
    return IO;
#ifdef VEZHAM_STORE_TESTING
  if (!strcmp(fail, "crash-before-publish"))
    _exit(86);
  if (!strcmp(fail, "fail-before-publish"))
    return IO;
#else
  (void)fail;
#endif
  if (renameat(root, STAGE, root, MAIN))
    return IO;
#ifdef VEZHAM_STORE_TESTING
  if (!strcmp(fail, "crash-after-publish"))
    _exit(87);
  if (!strcmp(fail, "unknown-after-publish"))
    return UNKNOWN;
#endif
  return fsync(root) == 0 ? OK : UNKNOWN;
}
int main(int argc, char **argv) {
  // No provider is admitted into production by this qualification executable.
#ifndef VEZHAM_STORE_TESTING
  (void)argc;
  (void)argv;
  reply(DENIED, 0, NULL, 0);
  return 0;
#else
  if (argc != 7) {
    reply(DENIED, 0, NULL, 0);
    return 0;
  }
  const char *mode = argv[1], *profile = argv[3], *store = argv[4],
             *fail = argv[6];
  if (strlen(profile) != 36 || strlen(store) != 36 || !strcmp(profile, store)) {
    reply(DENIED, 0, NULL, 0);
    return 0;
  }
  char *end = NULL;
  errno = 0;
  unsigned long long expected = strtoull(argv[5], &end, 10);
  if (errno || !end || *end || expected >= 9007199254740991ULL) {
    reply(DENIED, 0, NULL, 0);
    return 0;
  }
  unsigned char key[32];
  uint32_t size = 0;
  unsigned char *payload = NULL, *old_payload = NULL;
  uint32_t old_size = 0;
  uint64_t rev = 0;
  int status = DENIED, root = -1, lock = -1, fd = -1;
  sqlite3 *source = NULL, *target = NULL;
  struct wsf3_vfs *from = calloc(1, sizeof(*from)),
                  *to = calloc(1, sizeof(*to));
  if (!from || !to || !io_all(0, key, 32, 0))
    goto done;
  unsigned char check = 0;
  for (int i = 0; i < 32; i++)
    check |= key[i];
  if (!check)
    goto done;
  if (!strcmp(mode, "save") || !strcmp(mode, "create")) {
    if (!io_all(0, &size, 4, 0) || size > LIMIT)
      goto done;
    payload = malloc(size ? size : 1);
    if (!payload || !io_all(0, payload, size, 0))
      goto done;
  } else if (strcmp(mode, "load") && strcmp(mode, "prior"))
    goto done;
  root = open(argv[2], O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
  struct stat st;
  if (root < 0 || fstat(root, &st) || st.st_uid != geteuid() ||
      (st.st_mode & 0777) != 0700)
    goto done;
  int creating = !strcmp(mode, "create");
  lock =
      openat(root, "writer.lock",
             O_RDWR | O_NOFOLLOW | O_CLOEXEC | (creating ? O_CREAT : 0), 0600);
  if (lock < 0 || !regular(lock, 0600) || flock(lock, LOCK_EX))
    goto done;
  if (creating) {
    if (expected != 0) {
      status = CONFLICT;
      goto done;
    }
    if (exists(root, MAIN) || exists(root, PRIOR) || exists(root, STAGE) ||
        exists(root, PREV_STAGE)) {
      status = CONFLICT;
      goto done;
    }
  } else {
    const char *name = !strcmp(mode, "prior") ? PRIOR : MAIN;
    for (int i = 0; i < 3; i++) {
      char side[64];
      snprintf(side, sizeof(side), "%s%s", name,
               i == 0   ? "-wal"
               : i == 1 ? "-shm"
                        : "-journal");
      if (exists(root, side)) {
        status = RECOVERY;
        goto done;
      }
    }
    fd = openat(root, name, O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK);
    if (fd < 0 || !regular(fd, 0400) || fstat(fd, &st) || st.st_size <= 0 ||
        st.st_size > WSF3_FIXTURE_LIMIT) {
      status = CORRUPT;
      goto done;
    }
    if (!open_db(from, fd, 0, key, &source)) {
      status = CORRUPT;
      goto done;
    }
    status = identity(source, profile, store);
    if (status != OK)
      goto done;
    if (!scalar(source, "PRAGMA integrity_check", "ok") ||
        !read_state(source, &rev, &old_payload, &old_size)) {
      status = CORRUPT;
      goto done;
    }
    if (!strcmp(mode, "load") || !strcmp(mode, "prior")) {
      status = OK;
      goto done;
    }
    if (rev != expected) {
      status = CONFLICT;
      goto done;
    }
  }
  if (!open_db(to, -1, 1, key, &target)) {
    status = IO;
    goto done;
  }
  if (creating) {
    if (!new_identity(target, profile, store)) {
      status = IO;
      goto done;
    }
  } else {
    sqlite3_backup *backup =
        sqlite3_backup_init(target, "main", source, "main");
    if (!backup) {
      status = IO;
      goto done;
    }
    int result = sqlite3_backup_step(backup, -1);
    int finish = sqlite3_backup_finish(backup);
    if (result != SQLITE_DONE || finish != SQLITE_OK ||
        identity(target, profile, store) != OK) {
      status = IO;
      goto done;
    }
  }
  if (!strcmp(fail, "future-schema") &&
      !sql(target, "UPDATE identity SET schema_version=2")) {
    status = IO;
    goto done;
  }
  if (!change(target, creating ? 0 : rev + 1, payload, size)) {
    status = IO;
    goto done;
  }
  if (sqlite3_close(target) != SQLITE_OK) {
    target = NULL;
    status = IO;
    goto done;
  }
  target = NULL;
  if (to->violated || from->violated) {
    status = DENIED;
    goto done;
  }
  status = publish(root, fd, to, fail);
  if (status == OK || status == UNKNOWN)
    rev = creating ? 0 : rev + 1;
done:
  if (source)
    sqlite3_close(source);
  if (target)
    sqlite3_close(target);
  if (from)
    sqlite3_vfs_unregister(&from->vfs);
  if (to)
    sqlite3_vfs_unregister(&to->vfs);
  if (fd >= 0)
    close(fd);
  if (lock >= 0)
    close(lock);
  if (root >= 0)
    close(root);
  if (status == OK && from && from->violated)
    status = CORRUPT;
  if (status == OK && (!strcmp(mode, "load") || !strcmp(mode, "prior")))
    reply(status, rev, old_payload, old_size);
  else
    reply(status, rev, NULL, 0);
  memset(key, 0, sizeof(key));
  if (payload) {
    memset(payload, 0, size);
    free(payload);
  }
  if (old_payload) {
    memset(old_payload, 0, old_size);
    free(old_payload);
  }
  if (from) {
    memset(from, 0, sizeof(*from));
    free(from);
  }
  if (to) {
    memset(to, 0, sizeof(*to));
    free(to);
  }
  return 0;
#endif
}
