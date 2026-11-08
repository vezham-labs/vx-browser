#include "sqlite3.h"
/* Link roots only. This translation unit has no startup or runtime call.
   The linked worker is inspected as a binary and never launched in Phase 1. */
__attribute__((used)) void *volatile vx_sqlcipher_link_roots[] = {
    (void *)&sqlite3_key, (void *)&sqlite3_open_v2, (void *)&sqlite3_close,
    (void *)&sqlite3_libversion, (void *)&sqlite3_sourceid,
    (void *)&sqlite3_backup_init, (void *)&sqlite3_wal_checkpoint_v2
};
