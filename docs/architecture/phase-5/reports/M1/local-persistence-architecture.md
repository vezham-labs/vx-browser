# Local Persistence Architecture

**Current baseline (2026-11-08):** supporting Proposed design; [owner register](m1-owner-decision-register.md) and [Developer Specification](m1-developer-specification.md) govern current policies/scope. Documentation/isolated validation/planning Authorized; no product implementation or release. Original draft is preserved in the evidence source archive.
**Date:** 2026-11-07. **Status:** Proposed M1 design for owner review; not approved or implemented.

## Recommendation and alternatives

[ADR 0004](../../../../decisions/0004-browser-local-persistence.md) compares SQLite, Core Data, SwiftData, files, web/cloud storage and encrypted providers. Recommend a narrow SQLite adapter behind core-owned repositories, a small application catalog, and one database per persistent profile. SQLite is selected for explicit local transaction and lifecycle control, not another product's choice or a measured speed advantage. All recommendations await review.

## Data domains and access

| Domain                          | Location / owner                                             | Access and privacy boundary                                                                                                                                                                              |
| ------------------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Application catalog             | Sandbox Application Support, native storage service          | Persistent profile identity/label/lifecycle and app preferences only; no private sessions, browsing URLs, titles, credentials or page content                                                            |
| Persistent profile DB           | Host-created opaque profile directory in Application Support | Browser-owned state only; every repository operation binds a native-verified profile lease and checks the store header. Separate DBs reduce accidental cross-profile queries, not trusted-host privilege |
| Engine website stores           | Adapter/native private mapping to engine-managed stores      | Cookies, HTTP auth, website cache/localStorage/IndexedDB/service workers stay engine-owned; never copied into the core DB                                                                                |
| Private core state              | Memory-only session values                                   | No catalog row, SQLite file/connection, backup, restore snapshot, persistent preferences, grant history or sync journal                                                                                  |
| Native secrets/authorizations   | Future Keychain/file-service brokers                         | Core stores opaque references only where needed; no secret bytes or security-scoped bookmark blobs in UI/domain snapshots                                                                                |
| User-approved exports/downloads | Explicit future native destination                           | Deliberate external output must be disclosed; never confuse it with automatic private-state persistence                                                                                                  |

Resolve paths natively from the app container, never an input URL/path from chrome. Profile UUIDs map to host-generated directory names after catalog/header checks; deny symlink substitution and unexpected owner/type before opening. Restrict file/directory permissions and preserve sandbox constraints. Do not place browser data on a network/shared/cloud-synchronized database directory. No App Group sharing is proposed.

## Connections, transactions and durability

A persistence service owns a bounded serial database worker and connection registry. SQLite calls run off the main actor on that worker; connection/cursor objects never escape. Begin with one writer per store and bounded/paginated reads, rather than a new thread/pool per tab. Set/verify foreign keys on each connection before a transaction. Bind statement parameters and keep SQL private; no arbitrary SQL or generic predicate arrives from UI.

Propose WAL with `synchronous=FULL` for durable stores, explicit checkpoint policy, and reviewed macOS full-sync settings before real data. Do not relax durability to improve a benchmark. SQLite documents WAL and the additional commit sync under FULL; actual OS/library/filesystem behavior still needs qualification. [WAL](https://sqlite.org/wal.html), [synchronous and fullfsync settings](https://sqlite.org/pragma.html#pragma_synchronous).

Use short transactions with compare-and-swap store revision, bounded operation receipts and domain validation. No engine/Keychain/file-panel/network call occurs in a DB transaction. An acknowledgement means the defined transaction committed, not that a subsequent native side effect completed. Busy/disk-full/I/O/corrupt/newer-schema/key-unavailable results are explicit errors; retries are bounded and never silently drop history/bookmarks or recreate a failed DB.

Catalog, profile DB, engine stores, Keychain and final files are different transactional resources. Use explicit creating/ready/deleting/cleanup-required states and reconciliation; do not claim an atomic transaction spans them. Independent profiles have independent failure handling. Multi-profile operations are outside the initial slice.

## Private sessions and profile separation

A private session uses Swift memory structures and cannot obtain a persistent-store lease. Storage rejects tagged private context before queueing any operation, including receipts, migrations, backup, telemetry and app preference writes. Private mode does not reuse a persistent SQLite DB with a boolean filter. Persistent preference defaults may be copied into memory at creation; private overrides never write back to the parent.

Closing the last private window cancels/revokes private service requests, releases views and transient state, and cleans only app-owned opaque staging resources. Do not persist private URLs or IDs as recovery/cleanup logs. Future transfer staging may require temporary bytes; M5 must specify minimal crash-cleanup markers without browsing metadata and prove cleanup. Engine data-store release is adapter work; neither memory-only core nor a DB design proves engine private browsing. OS swap, crash artifacts, user-selected files and OS snapshots have separate limits; do not promise forensic erasure.

Physical profile DB separation is combined with immutable scope, per-store header checks, repository ownership and bounded native capabilities. Never `ATTACH` another profile DB for normal feature queries. Global search/suggestions cannot scan other profiles or normal history in private mode by convenience.

## Protection, encryption and credentials

History URLs/titles, bookmarks, profile labels and restore state are sensitive even without passwords. Proposed threat model protects against website/chrome-native boundary abuse, accidental cross-profile access and offline device exposure, while acknowledging a compromised trusted host or unlocked OS account can read active data. FileVault is volume protection; it does not make all same-user threats disappear. [Apple FileVault](https://support.apple.com/guide/security/sec4c6dc1b6e/web).

Recommend no application DB encryption dependency for the **fixture-only** first slice. Before real browsing data is persisted, obtain an explicit owner/security disposition for managed-device encryption/file protection or an evaluated encrypted SQLite provider. Provider/key availability is a storage precondition if encryption is required; never generate a replacement key over an inaccessible existing database. Key rotation, loss/recovery, backup encryption and search/index leakage need design before encrypted storage is enabled. Native Keychain integration remains a future broker; this task stores no keys or accounts.

Current OP-01/02/04: Forever history default; manual download metadata retention; normal-quit/restart session restoration and crash prompt. Retain full history URLs after stripping embedded credentials; do not automatically filter queries/fragments. Encrypt/profile-scope; never private persistence or raw URL diagnostics. Paths/query/fragments may contain secrets; encryption and redaction do not remove that privacy risk. Exact schema/title/checkpoint/retention integration remains specification work.

## Backup, export, deletion and future synchronization

Use a verified SQLite snapshot API for controlled pre-migration backups; never copy only a live main DB and assume WAL state is included. [SQLite Backup API](https://sqlite.org/backup.html). User-created snapshots have manual retention/no default expiry under OP-03. Internal pre-migration/recovery snapshot lifecycle is distinct and remains engineering specification; do not import the historical24-hour proposal as a current default. Backups share the profile's protection level and include a manifest, schema and privacy epoch. No private backup or automatic upload.

Backup recovery and logical user export are separate. Future user-selected logical export uses a versioned sanitized format, limits record counts and excludes cookies, passwords, grants, native bookmarks, private data and operational receipts by default. Import allocates/revalidates ownership and does not overwrite an existing profile implicitly. No importer/exporter is implemented.

Privacy clear invalidates app-owned older snapshots before success is reported; recovery refuses a snapshot behind the catalog privacy epoch. Remove all known app-owned profile copies on deletion and report incomplete cleanup. OS snapshots/user backups and SSD behavior are outside a secure-erasure guarantee. [Migration/recovery](migration-and-recovery-strategy.md) defines failure points.

Stable entity IDs, revisions and explicit deletion semantics support a future export/sync boundary without selecting a protocol, cloud account, CRDT or automatic data transmission. Do not create a sync outbox, device identity, remote ID or mandatory cloud dependency in M1. Future sync must re-evaluate conflict resolution, tombstones, encryption, consent and private exclusions separately.
