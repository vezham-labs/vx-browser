# ADR 0004: Browser-owned local persistence

- **Status:** Proposed
- **Date:** 2026-11-07
- **Authority:** M1 design recommendation; storage, privacy defaults and encryption disposition await owner review.
- **Implementation:** No database, schema migration, profile or storage code created.

## Problem

Browser-owned history, bookmarks, preferences, restore descriptors and later permission/download records need local transactions and clear profile/private ownership. Engine cookies/cache/storage are separate assets. Local operation must require neither a cloud account nor network access. Reuse in another Vezham product is not a selection criterion.

## Alternatives and trade-offs

| Option                                            | Suitability and benefits                                                                                                           | Costs / privacy / performance considerations                                                                                                                                                                     |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SQLite through a small native persistence adapter | Explicit transactions, relationships, indexes, versioning and local file ownership; direct inspection of failure/recovery behavior | SQL, connection lifetime, C bindings and migration/backup discipline are our responsibility. Plain SQLite must not be represented as application-level encryption                                                |
| Core Data                                         | Native object persistence, relationship and change management                                                                      | Adds managed-object/context semantics to keep outside core; requires store/migration/backup policy, not automatically weaker isolation. A reasonable fallback if custom SQL maintenance proves excessive         |
| SwiftData                                         | Swift-native model/migration API; no need to add a cloud dependency                                                                | Adds model/container lifecycle and platform API coupling behind a port; offers no automatic proof of private cleanup. Explicit schema migration is supported, so absence of migrations is not a rejection reason |
| JSON/property-list files                          | Simple settings and small interchange                                                                                              | Cross-entity atomicity, partial writes, indexing and growth become custom work; unsuitable as the primary history/state store                                                                                    |
| Embedded web storage or remote database           | Convenient to frontend/service code                                                                                                | Reject as primary: browser data must not depend on chrome origin lifetime or a remote service; violates local-first/authority requirements                                                                       |
| Encrypted SQLite provider                         | Could provide database-file encryption with a separate key lifecycle                                                               | New provider/dependency/licensing/update and recovery obligations; required evaluation if owner policy demands application-level database encryption                                                             |

[Apple Core Data](https://developer.apple.com/documentation/coredata) and [SwiftData SchemaMigrationPlan](https://developer.apple.com/documentation/swiftdata/schemamigrationplan) document legitimate native alternatives. The preference for SQLite is a design judgment about explicit ownership and transactions, not a benchmark or claim that alternatives require cloud services.

## Proposed decision and conditions

Recommend SQLite for persistent browser-owned state, accessed only through typed repository operations. Use a small persistent application catalog plus a separate database per persistent profile. Private sessions use Swift in-memory values without a SQLite connection or persistent profile row. This is logical/storage separation, not separate OS accounts or a guarantee against host compromise.

Use the public SDK SQLite interface initially; verify the actual minimum-OS runtime library, compile options and required API subset during implementation/release validation. Do not pin an invented system SQLite version or add an ORM/provider now. Use parameter-bound statements, enabled/verified foreign keys, one serialized writer, bounded reads and WAL with a conservative durability policy. [SQLite foreign keys](https://sqlite.org/foreignkeys.html) and [WAL documentation](https://sqlite.org/wal.html) inform these requirements; they are not Vezham test results.

**Encryption is a condition, not an inferred approval.** Recommend a fixture-only first implementation slice. Before storing real browsing data, the owner/security reviewer must approve either a managed-device/FileVault plus sandbox/file-protection threat model without application-level DB encryption, or require an evaluated encrypted provider. No sensitive-data fallback to plaintext if a required key/provider is unavailable. Keys, when required, are brokered by native Keychain services and never stored in frontend state or the database beside ciphertext. [Apple Keychain services](https://developer.apple.com/documentation/security/keychain-services) provides native secret storage; [FileVault](https://support.apple.com/guide/security/sec4c6dc1b6e/web) addresses volume protection, not all unlocked-host threats.

## Maintenance, reversibility and approval

SQLite needs transaction, migration, corruption, retention and backup expertise. Profile files simplify scoped ownership/deletion but create catalog/profile coordination and connection-management work; a single shared DB would simplify transactions but make every query depend on perfect namespace filtering. Neither is an engine isolation guarantee.

Repository ports and versioned logical export reduce future storage replacement cost; live file-format conversion, encrypted-provider changes and backup compatibility still require explicit migration. There is no production data to convert now. Backup/export and future sync formats must exclude engine secrets and private data; no cloud implementation follows from stable entity IDs.

Owner approval is needed for the storage/file-layout direction, encryption disposition before real data, and proposed retention/session-restore defaults. See [persistence architecture](../architecture/phase-5/reports/M1/local-persistence-architecture.md), [data model](../architecture/phase-5/reports/M1/browser-core-data-model.md), [migration/recovery](../architecture/phase-5/reports/M1/migration-and-recovery-strategy.md) and [decision register](../architecture/phase-5/reports/M1/m1-decisions-and-risks.md). Approval of this record would still require a separate implementation scope.
