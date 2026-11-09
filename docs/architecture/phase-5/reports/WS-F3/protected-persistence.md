# Protected persistence

The native C probe statically links the retained pinned SQLCipher 4.20.0 Community/CommonCrypto archive. It verifies archive and header hashes before build and requires SQLite 3.54.1, TEMP_STORE=3 and exact returned cipher suite settings. The length-explicit sqlite3_key_v2 call takes 32 in-process random bytes. Authentication verifies the actual identity table DDL and a unique row matching profile, store, schema, suite and key version. Successful fixture admission is read-only.

The VFS is descriptor-scoped and provides no delegate path for xOpen, byte reads, writes, deletion or mappings. The fixture producer first initializes an encrypted image with the actual provider in bounded RAM, validates its identity and only then publishes ciphertext to a newly reserved path. Reopen uses O_RDONLY | O_NOFOLLOW and an existing 0400 single-link file. WAL/SHM/journal presence fails admission. Existing-file reads have no persistent mutation path. These choices deliberately avoid pretending a single-file fixture implementation can coordinate production WAL, other writers, crash recovery or a cross-resource saga.

The protected catalog and profile repositories remain unavailable in the normal app. The probe uses synthetic expected identities and process-local test keys. It establishes a bounded native read boundary and identity gate. Durable write grants, migration, restore, authenticated catalog admission and signed Keychain leases remain separate work.

[Native boundary](d2a-01-option-2-qualification.md) · [Original OPEN-02 write fence](../M1/m1-sqlcipher-open02-write-fence-specification.md) · [Probe source](../../../../../qualification/sqlcipher-wsf3/native_probe.c)
