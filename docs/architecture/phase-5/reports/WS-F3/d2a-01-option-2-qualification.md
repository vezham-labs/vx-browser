# D2A-01 Option 2 native qualification

The exact [approved exception](approved-decisions.md) applies to existing-file opens for this pinned provider and VFS path. The old proposal and feasibility artifacts retain their historical statuses. This read-only probe has no app storage or write authority.

| Sequence on valid native probe | Actual observed operation |
|---|---|
| 1 | Connection construction requests main file offset 0, length 100, via xRead. Exactly one pre-key request is forwarded to pread. |
| 2 | Call sqlite3_key_v2 with 32 length-explicit bytes for main. No xRead occurs in binding. KeyApplied is a distinct event. |
| 3 | Read-only descriptor fingerprint after KeyApplied and before authentication reads. |
| 4 | Apply and verify the runtime cipher settings. Enter authentication. xRead requests in order are (offset, length) (0, 4096), (0, 16), (24, 16), (24, 16), (4096, 4096). |
| 5 | Check authenticated schema and expected profile, store, schema, suite and key version. Emit read_only_ready for valid fixture only. The final fence always reports write_authorized=false and matching post-bind/post-close content fingerprints for admitted cases. |

The boundary measures application/VFS requests, independent of filesystem caching and physical reads. The existing-file VFS has no xShm or mmap functions. It cannot delegate file writes, truncation, deletion, other file opens or exclusive locks. An extra pre-key or otherwise disallowed operation records a violation and stops. Denied or mismatched sources stay unavailable. Genuine short reads for truncated fixtures are supplied as short reads with the SQLite-defined zero fill. An injected existing sidecar stops before opening. No pre-key hash/copy or plaintext fallback occurs. The synthetic fresh database is generated in RAM via real SQLCipher, then emitted as ciphertext into an exclusive disposable file after identity verification.

The bounded test does not qualify a product VFS, production key custody, a write grant, all-provider diagnostic channels, concurrent I/O, WAL recovery, anti-rollback or future provider versions. Real production admission must independently validate the worker context and authority. [Final trace](evidence/provider-20261109T154014534033Z/1-valid.stdout) · [Repeated observations](evidence/provider-20261109T154014534033Z/observations.json) · [Policy enforcement](../../../../../qualification/sqlcipher-wsf3/descriptor_vfs.c)
