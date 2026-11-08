# Migration, Integrity and Recovery Strategy

**Date:** 2026-11-07. **Status:** Proposed design only; no schema, migration, service or bridge implemented.

## Decision and alternatives

Recommend explicit ordered, checksummed migrations and controlled snapshots through the persistence port. Automatic destructive recreation is rejected because corruption/version mismatch must not erase browsing data. Ad-hoc startup DDL is rejected because partial upgrades and downgrade behavior become invisible. Framework-managed migrations remain possible if the storage recommendation changes; no migration is installed in this task.

Transactional profile schema changes, catalog lifecycle intent and post-crash native reconciliation solve different problems. Database atomicity does not include engine stores, Keychain, native files or UI effects. [Storage design](local-persistence-architecture.md) and [logical model](browser-core-data-model.md) define those resources.

## Open and migration protocol

1. Resolve a host-owned persistent profile lease and approved location. Reject private scope before file access. Check owner/type/symlink policy, catalog lifecycle/privacy epoch and stored profile identity; never repair identity by editing a mismatched header.
2. Open the expected store on its serialized worker. Verify actual runtime API/compile support, enabled foreign keys and configured journal/durability settings. If a required encryption key is unavailable, return locked/unavailable; do not create a new store at the same path.
3. Inspect schema version, migration checksums and minimum reader/writer versions. Newer/unknown versions return unsupported without mutation. Do not downgrade automatically or allow a previous app release to write an incompatible store.
4. Quiesce the affected store and invalidate/cancel conflicting effects. Before a risky upgrade, create a verified snapshot using the [SQLite Backup API](https://sqlite.org/backup.html). Include profile ID, schema, privacy epoch and digest in an app-owned protected manifest; verify snapshot completeness and storage space. Do not assume copying the live main file captures WAL state.
5. Run each supported transactional migration, invariant checks and version/receipt updates in a single store transaction. No await, engine call, file panel or remote call inside it. On error, roll back and leave the old logical schema usable where SQLite permits; record only a coarse failure category.
6. Run bounded integrity/foreign-key checks appropriate to the upgrade, reopen through normal header checks and publish readiness. Do not clear the original or promote an unverified backup. Large rebuild migrations require an explicit staged design, not an implicit exception to this transaction policy.

Fresh-schema bootstrap is an initialization case, not migration of Phase3 prototype stores. No prototype profile/evidence is imported into product data. Transaction guarantees depend on the actual SQLite/OS/filesystem and need implementation fault tests; design text is not proof.

## Catalog and native resource reconciliation

| Operation                 | Durable intent and work                                                                                                                                                                          | Safe restart / incomplete outcome                                                                                                                                                          |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Create persistent profile | Catalog records creating with native-generated storage identity; initialize DB/header; later M5 provision engine binding; publish ready only after required resources exist                      | Resume only the known intent and owned resources. Never activate an arbitrary orphan directory or bind another profile's engine store                                                      |
| Delete persistent profile | Refuse while actual host/core/broker owners exist. Quiesce, retire generation, record deleting; later remove app-owned DB/snapshots, engine binding/store and relevant broker resources          | Keep cleanup-required and deny reopening if a step fails. Retry only the owned cleanup phase; report partial deletion, not success. User-chosen output files are not automatically deleted |
| Clear browsing data       | Record a higher privacy epoch/clear intent before invalidating snapshots, then clear selected app data and dependent indexes, reconcile required engine data separately, acknowledge exact scope | Block older restore/backup use immediately. If interrupted, finish the declared clear or show incomplete scope; never restore a backup that resurrects deleted data                        |

These are sagas with explicit phases, not one cross-store SQL transaction. Initial M1 foundation can later verify pure state transitions with fake resources. Actual profile/engine/file cleanup is M5 work and not authorized here. Catalog intents contain no private sessions or browsing URLs. If privacy-epoch metadata is missing/corrupt, do not guess that an older backup is eligible; require a deliberate recovery decision.

## Failure handling and acknowledgment

| Failure                                  | Required behavior                                                                                                        | Future meaningful verification                                                                 |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| Busy/lock contention                     | Bounded wait/retry budget; cancel safely; report storage-busy without blocking main actor                                | Two writers/held transaction and timeout; no partial mutation                                  |
| Disk full or I/O error                   | Roll back when possible; preserve original files; mark durable feature degraded; do not report saved                     | Inject failure before/at commit; reopen and inspect transaction/receipt                        |
| Caller cancelled while commit may finish | Resolve by MutationId receipt and revision; cancellation cannot undo a completed transaction                             | Race cancellation/owner disposal against commit and late reply                                 |
| Process death during WAL transaction     | Let SQLite perform its documented recovery on next authorized open; do not manually delete WAL/SHM to manufacture a pass | Kill disposable future fixture at defined boundaries, compare committed revisions/data         |
| Corrupt store / identity mismatch        | Stop writes, isolate that store, retain owned evidence without browsing content, offer reviewed recovery path            | Corrupt copy/wrong-profile header; verify no automatic reset or cross-profile read             |
| Migration interruption/newer schema      | Transaction rollback or explicit staged failure; refuse unsupported writer version                                       | Death before/after version commit, repeated open, older app rejection                          |
| Required key lost/locked                 | Return inaccessible, preserve ciphertext and explain recovery limits                                                     | Fake key unavailable/incorrect/rotation interruption; no plaintext fallback or regenerated key |

No such fault test runs during this documentation task. Store receipts provide bounded retry reconciliation, not an unlimited exactly-once guarantee. Expired receipt plus stale expected revision must reject the mutation rather than replaying it blindly.

## Content-process, host and session recovery

Content-process recovery uses core memory for the affected view's last committed descriptor and owner generation. Reject late/disposed/foreign callbacks. Do not reload automatically, repeat an upload/form/POST, regrant permissions or resume a transfer from a stale intent. If safe restoration semantics cannot be established through public APIs, show a stopped/error state and require a new explicit action. Earlier Phase3 recovery suites do not validate this new architecture.

Host restart uses only opt-in persistent restore descriptors, never arbitrary serialized core memory. Assign new AppRun/Window/Tab/View/capability IDs and revalidate URLs/profile ownership. Show the proposed restore choice before navigation; do not resurrect live network operations, old IPC requests, prompt grants or credential data. Private windows and their URLs/titles/permissions/restore records are never restored.

M5 must clean app-owned private staging after abrupt death using minimal opaque resource markers and a fixed owned directory policy, without persisting private browsing metadata. Memory-only core cannot promise no OS/engine artifacts. User-approved private download/export files intentionally remain outside automatic session cleanup unless separately requested.

## Backup, rollback and privacy deletion

Propose at most one app-owned pre-migration snapshot for no more than 24h, invalidated sooner by a clear/delete. Owner review must approve TTL/protection policy. Backup manifest/schema/profile/privacy-epoch checks and integrity verification precede any restore. Recovery never overwrites the sole original automatically; preserve it and require an explicit user decision before losing newer valid records. Do not merge corrupted rows by best effort or send them to cloud diagnostics.

A signed app rollback is not a database downgrade. Release engineering must select a candidate compatible with the current store or an explicitly approved recovery/export path; obsolete snapshots cannot bypass privacy epochs or reintroduce vulnerable policy. Device/Time Machine snapshots and user exports have separate retention/deletion limits. Logical deletion, checkpoint/vacuum and encrypted-key destruction must not be advertised as guaranteed SSD/backup forensic erasure.

## Reversibility and open review

Before any production data exists, changing the logical schema or provider is cheap. Once data exists, preserve versioned logical export, migration fixtures, backup eligibility and minimum writer policy. Final encryption/provider choice, retention, restore UX, privacy-clear scope and operational recovery ownership await approval. No release gate, security defect or private/cross-profile leak can be waived by accepting this strategy.
