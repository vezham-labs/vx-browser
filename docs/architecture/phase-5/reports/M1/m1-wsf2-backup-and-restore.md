# WS-F2 backup, restore and deletion

2026-11-09. WS-F2 implementation/qualification review. [Closeout](m1-wsf2-closeout.md) · [Actual results](m1-wsf2-qualification-results.md) · [Evidence](../../evidence/20261109T105707Z-webkit-storage-wsf2/README.md). **No release approval.**

## Implemented native slice; production integration BLOCKED

`OwnedBackupSnapshot` validates an explicitly persistent scope, schema/generation/deletion epoch, unique IDs and bounded typed records. `EncryptedOwnedBackup` performs actual CryptoKit AES-256-GCM and HKDF-SHA256, with a fresh archive key/UUID,32-byte salt,96-bit nonces,128-bit tags and deterministic CBOR AAD. A strict bounded CBOR subset rejects duplicates, indefinite/noncanonical encodings, unknown critical fields and trailing input. The provisional `VXWSF2B` schema1 is an owned-data archive framing refinement, **not the existing VXKE key-envelope format or a final production/archive interoperability approval**.

Index0 authenticates an encrypted manifest; index1 encrypts the bounded record payload under the fresh content key. Nonces use a fresh32-bit prefix and64-bit chunk index. AAD binds header/scope/version/generation, index/count, exact length and purpose. The encrypted manifest authenticates selected category names, ordered payload digest/length and deletion epoch. Recovery-purpose wrapping uses its independent random authority and fresh salt/nonce; no key bytes occur in the outer manifest. All authentication and schema/scope checks complete before exposing records. Authentication failure never publishes partial plaintext or overwrites a destination.

`NativeBackupFiles` opens a native-selected directory, stages with O_EXCL/O_NOFOLLOW and0600 permissions, fsyncs, hard-links to a no-overwrite final name and fsyncs the directory. Read rejects nonregular, oversized or incomplete final files. Failed/interrupted stages remain distinguishable `.incomplete` and are never automatically promoted. This is logical same-filesystem publication, not a proven sudden-power-loss/full-storage durability guarantee. No actual user destination panel or source snapshot acquisition is implemented.

## Category policy

| Category | Inclusion/protection/profile/retention | Restore/deletion/portability boundary |
|---|---|---|
| Profile metadata/catalog selection | Intended encrypted, persistent scoped records | Authenticated identity/mapping and migration required; actual catalog snapshot/import BLOCKED |
| History | Encrypted per profile; full URLs strip credentials; Forever default,30/90/year/Forever/custom remains existing policy | Individual/range/all deletion records; filter known deleted IDs; no private history; actual repository integration BLOCKED |
| Bookmarks/preferences | Encrypted selected profile records | Validated schema, fresh destination; actual repositories not added |
| Session descriptors | Encrypted persistent metadata; OP-04 policy | No automatic forms/POST/action replay; private discarded; source checkpoint integration BLOCKED |
| Permission metadata | Encrypted selected records if implemented | Not restored as active native/OS grants; current restore omits these records; user reauthorization required |
| Download metadata | Encrypted; manual retention | Metadata deletion never deletes external payload; actual download engine not implemented |
| User snapshots/archives | Encrypted selected records; manual/no default expiry | Separate from internal recovery; current source schema/acquisition BLOCKED |
| WebKit website data | Excluded | No internal-file copy, SQLite access, portable website-data claim or localStorage-only full-backup inference |
| Actual downloaded files | Excluded by default | Optional OD-R20 all/individual selection, size estimate, original locations/no overwrite remain unimplemented/BLOCKED; never silently delete files |
| Private data | Excluded/rejected | No history/session/store mapping/snapshot/backup restoration |
| Internal recovery journal | Not a user snapshot; future authenticated checkpoint only | Never restore runtime leases/prompts/native handles or replace authoritative deletion knowledge |

## Actual qualification and remaining gates

Native synthetic-record tests exercise encrypted roundtrip, fresh archive output, tamper/truncation/trailing bytes, wrong recovery authority/profile, deletion filtering, unknown lineage refusal, destination conflict, private rejection, actual file publication/no overwrite and interrupted-stage nonpublication. Contract tests add canonical framing/bounds/schema/selection checks. No test secret, secret hash or plaintext key enters evidence.

Restore filters independent known deletion records and rejects stale knowledge. Unknown coverage requires explicit native confirmation; that does not guarantee an offline archive knows later deletions. Current helper returns validated records for a fresh staging destination only; it does not import into a real protected catalog. No coherent catalog/profile/WebKit snapshot transaction, full-browser selection, actual cross-Mac recovery, printable kit/encrypted recovery-file custody verification, archive-key persistence, real process/power-loss backup recovery or migration is qualified. The memory-only recovery handle has no default durable/export path; loss makes its synthetic archive unrecoverable. Do not use this slice as a user-facing backup product until those gates pass.

Gate F remains BLOCKED for production source/import/recovery integration. No approved retention, deletion, independent recovery or external-download policy is weakened.
