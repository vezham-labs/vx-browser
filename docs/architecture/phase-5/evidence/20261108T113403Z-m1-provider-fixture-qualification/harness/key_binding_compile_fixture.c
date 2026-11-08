/* VALIDATION-ONLY compile fixture: never linked into the browser or executed. */
#define __STDC_WANT_LIB_EXT1__ 1
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include "sqlite3.h"

/* Demonstrates length-explicit binary input, not a production key broker.
   Caller holds a scoped lease and keeps database/worker ownership; this code
   cannot establish key derivation, authentication, copy lifetime or zeroization
   of provider/Swift buffers. No PRAGMA interpolation, strings or logging. */
int vx_fixture_bind_only(sqlite3 *db, uint8_t *temporary_key, size_t length) {
    if (db == NULL || temporary_key == NULL || length != 32) return SQLITE_MISUSE;
    int rc = sqlite3_key(db, temporary_key, (int)length);
    int wipe_rc = memset_s(temporary_key, length, 0, length);
    if (wipe_rc != 0) return SQLITE_ERROR;
    return rc;
}
