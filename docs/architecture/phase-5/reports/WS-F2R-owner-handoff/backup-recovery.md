# Backup, restore and unified recovery

2026-11-09. Owner-review package against `timeline` commit `d90ef9b029568c650588ffbead99866ee1378710`. **WS-F2 remains INCOMPLETE. WS-F2R is proposed, not authorized.**

## Implemented synthetic archive slice

`OwnedBackupSnapshot` accepts only persistent scope, current schema, positive generation/deletion epoch, unique bounded records (1,024 maximum, 64 KiB per payload, 4 MiB total). `EncryptedOwnedBackup` uses actual CryptoKit AES-256-GCM, HKDF-SHA256, fresh archive/content-key material and authenticated framing. Strict CBOR rejects unsupported/noncanonical/trailing encodings. The encrypted manifest covers payload digest/length, selected categories and deletion epoch; header/AAD binds profile/version/generation and chunk identity/length/purpose.

`NativeBackupFiles` performs native-selected directory-relative no-follow, exclusive 0600 staging, fsync and no-overwrite publication. `.incomplete` data is not auto-promoted. Its synthetic interruption check is a controlled pre-publication branch, not proof of sudden-power-loss recovery. The current format `VXWSF2B` schema 1 is provisional and distinct from the existing `VXKE` profile-key envelope.

Sources: [OwnedBackupPolicy.swift](../../../../../qualification/webkit-storage-f0/Sources/BrowserPersistence/OwnedBackupPolicy.swift), [EncryptedOwnedBackup.swift](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/EncryptedOwnedBackup.swift), [CanonicalCBOR.swift](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/CanonicalCBOR.swift), [original backup report](../M1/m1-wsf2-backup-and-restore.md).

## Actual results versus missing integration

The native security/backup suite's **14 backup observations** passed: authenticated roundtrip, fresh archive output, tamper, truncation, trailing bytes, wrong recovery authority, wrong profile, deletion filtering, unknown-lineage refusal, destination conflict, private exclusion, actual file roundtrip, no overwrite and interrupted-stage nonpublication. Two other PASS_NATIVE observations in that suite are Keychain missing-item controls; the 16 native passes must not all be described as Keychain lifecycle successes. [Exact backup result](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-security-native-113238831637/backup-result.json).

| Layer | Status | Exact remaining limitation |
|---|---|---|
| Synthetic crypto and temporary files | PASS_NATIVE within stated slice | Not production feature readiness, independent review or power-loss proof |
| Schema/bounds/deletion contracts | PASS_CONTRACT | Not database acquisition or transactional import |
| Protected catalog/profile acquisition | BLOCKED / not implemented | No authenticated coherent database snapshot or real repository source; D2A/provider/key dependencies |
| Production restore/import | BLOCKED / not implemented | Helper returns validated records only; no actual catalog transaction, migration or destination promotion workflow |
| Recovery-material custody | Not implemented / unqualified | Memory-only independent archive-purpose authority has no completed printable kit, encrypted recovery-file export/import or saved-copy verification |
| Cross-process / cross-Mac restore | NOT_EXECUTED | Same-process synthetic handle/roundtrip cannot prove portability or source-Keychain independence |
| Optional downloaded-file selection | Not implemented | OD-R20 all/individual selection, size estimate, original locations/conflicts, moved/missing file and failure handling still required |
| WebKit website-data backup | Excluded / unqualified | No complete portable export/import, coherent snapshot or browser-key protection guarantee |

## Profile, deletion and external-file policy

Restore validates expected profile/generation/schema and a fresh destination, rejects mismatches/conflicts, filters known deleted IDs and omits permission records rather than reviving native grants. Private backup scope is rejected. Deletion knowledge older than the archive epoch is refused; incomplete knowledge needs explicit confirmation. Such confirmation cannot make an old offline archive know later deletions. Tests cover synthetic record filtering and refusal, not durable cross-device ledger propagation or all profile-deletion operations.

Encrypted download metadata and actual downloaded files remain separate. Metadata/profile deletion must not silently delete external user files, and restoration must not silently overwrite them. No real download payload or user destination was touched. The current slice does not implement the actual profile-delete/external-file preservation workflow or optional payload restore; it therefore cannot qualify those product guarantees by absence of file I/O alone. OD-R17/20 remain unchanged.

Current owner-decided OP-01–OP-04 govern history, manual download metadata/user-snapshot retention and situation-specific session recovery. The engineering work is to implement those policies, not reopen them as undecided. Sources: [owner register](../M1/m1-owner-decision-register.md) and [developer specification §25](../M1/m1-developer-specification.md).

## Engine-managed data remains a separate protection domain

WebKit owns website data. Vezham owns profile identity, policy and lifecycle coordination. Per-profile SQLite encryption does not encrypt WebKit files with Vezham keys. The synthetic archive does not satisfy WKS-031–034/040, prove localStorage export to be a complete browser backup or provide a coherent SQLite/WebKit transaction. No internal engine database is copied/opened/modified here. Secure erasure, universal private forensic cleanup and complete portable website backup remain unsupported claims.

## Unified recovery

`StorageRecoveryPolicy` requires authenticated catalog, available key, present engine, stable intent and complete deletion knowledge before eligibility for explicit unlock; recorded lock remains locked. Native unlock intentionally supplies unavailable/unknown inputs and refuses admission. Existing engine reconciliation uses parent-captured synthetic catalog/journal checkpoints across real app processes. Actual encrypted durable catalog/key/grant/tombstone/backup state is not qualified by those checkpoints. [Recovery policy](../../../../../qualification/webkit-storage-f0/Sources/BrowserCore/StorageRecoveryPolicy.swift), [original recovery report](../M1/m1-wsf2-recovery-and-reconciliation.md).

Safe independent WS-F2R work can improve archive validation, authorized temporary-file conflict/deletion tests and recovery-format/custody specifications. Actual source/import/reopen/key recovery must wait for their prerequisites; no plaintext or memory-catalog product fallback may fill the gap. Final independent second-Mac and official signed-build qualification remain recorded obligations. This handoff executed no archive, crypto, database, Keychain or WebKit runtime experiment.
