# M1 Owner Decision and Scope Register

Version: 1.1. Decision provenance: Product Owner's consolidated closeout instruction, 2026-11-08, plus the previously supplied complete OD-R register. Product implementation and release remain Not Authorized.

The current instruction authorizes documentation, isolated EXP/SVC validation within prerequisites, evidence retention and implementation planning. It supersedes earlier no-repository-change/no-validation-execution restrictions for this task only. OD-R01–OD-R20 remain approved product/architecture direction; their approval does not independently authorize product implementation. ADR statuses are unchanged.

## Source provenance

- [Current owner instruction](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/owner-task-authorization.txt), §§1, 3 and final authorization.
- [Preserved Developer Specification v1.0](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/developer-specification-v1.0-proposed.md), §27 contains the verbatim supplied owner entries.
- [Historical owner packet](m1-owner-decision-packet.md), OD01–OD20 retain their original meanings.
- [Canonical source catalog](m1-source-catalog.md).

## Current policy and capability dispositions — verbatim from current instruction

## 3.2 OP-01 — Browsing history

Owner decision:

- Retain full URLs: scheme, hostname, path, query parameters and fragments.
- Strip embedded username and password credentials.
- Never persist private browsing history.
- Encrypt and scope history to its profile.
- Default retention: Forever.
- Configurable retention: 30 days, 90 days, one year or Forever.
- Support individual, date-range and all-history deletion.
- Backup and restore must respect deletion decisions.
- Deleted entries must not silently reappear.
- Full URLs must not leak into diagnostic logs.
- Do not automatically filter query parameters under this policy.

Record the privacy risk of sensitive information embedded in URL paths, query parameters or fragments. Preserve encryption and diagnostic protections.

## 3.3 OP-02 — Download metadata

Owner decision:

- Manual retention.
- Retain metadata until the user removes it.
- Encrypted and profile-scoped.
- Individual deletion and clear-all supported.
- Metadata deletion must not delete the actual downloaded file.
- Download files remain separate from browser metadata.
- Backup metadata.
- Exclude download files by default.
- Optional download-file backup follows OD-R20.

Exact metadata fields and incomplete-download retention remain engineering specification details.

## 3.4 OP-03 — App-owned snapshots

Owner decision:

- Manual retention for user-created snapshots.
- No automatic expiry by default.
- Individual and bulk deletion.
- Encrypted and profile-scoped.
- No persistent private-browsing snapshots.
- Backup and restore must respect deliberate deletion.

Keep user-created snapshots distinct from internal recovery snapshots, website cache, WebKit website data and download files.

Define separate lifecycle policies for user-created and internal recovery snapshots in the engineering specification.

## 3.5 OP-04 — Session restoration and recovery

Owner decision:

| Situation | Required behaviour |
|---|---|
| Normal quit | Restore previous session |
| Crash recovery | Prompt user |
| macOS restart | Restore previous session |
| Recently closed tabs/windows | Manual retention |
| Private session recovery | Discard |
| Form/POST replay | Never automatically replay |
| Profile handling | Isolated per profile |

Additional requirements:
- Restore tab/window entries even when a page is unavailable; show an explicit failure state.
- Keep session state, browsing history, recently closed entries and internal recovery snapshots separate.
- Respect profile locks and deletion decisions.
- Never expose private session state through persistent recovery.

Session checkpoint timing, consistency, recently closed storage and lock/recovery interactions remain specification items.

## 3.6 Historical OD17 — M1 launch capability scope

Preserve the historical OD17 record and incorporate the following 26 selected capabilities.

### Core browsing and navigation

1. Address bar, URL entry, search, redirects, back, forward and reload.
2. Multiple tabs, creation, closing, reordering and duplication.
3. Multiple browser windows and window management.
4. Recently closed tabs and windows.
5. Download manager with progress, cancellation and supported resume.
6. Bookmarks, favorites and saved pages.
7. Searchable browsing history and history management.

### Browser organization

8. Multiple isolated browser profiles.
9. Private browsing with nonpersistent website data.
10. Session restoration and crash recovery.
11. Tab grouping and contextual organization.
12. Basic Arc-style Spaces and workspace organization.

### Native macOS integration

13. Native file selection and upload.
14. Native download destinations and file opening.
15. macOS Keychain and authentication integration.
16. Native macOS notifications where authorized.
17. External links and registered URL handling.

### Browser security and privacy

18. Certificate/TLS error handling with no silent bypass.
19. Origin-scoped and profile-isolated permission controls.
20. Private-session isolation and cleanup.
21. Independent clearing of history, cookies, website data and cache.
22. Profile locking on macOS lock, sleep and user switching.

### Recovery and reliability

23. Browser host crash recovery.
24. WebKit content-process termination recovery.
25. Encrypted profile backup and restore.
26. Core browser operation without mandatory cloud account or local server.

### Permission policy

- Positive support only for permission kinds verified against actual supported APIs.
- Default behaviour for a new permission request: Ask.
- Unsupported or ambiguous permissions: Deny/fail closed.
- Native macOS authorization is independent of browser permission grants.
- Do not assume all twelve inventoried permission kinds are positively supported.
- Produce an evidence-backed support matrix for each permission kind.
- Keep website notifications separate from native macOS notifications.

### M1 launch philosophy

Balanced browser: polished essential browsing workflows, profiles, privacy, downloads, recovery and verified permissions.

### Explicitly deferred capabilities

- Cloud account and cross-device synchronization.
- Third-party extensions and dynamic plugins.
- Tamizhi browser intelligence and autonomous web actions.
- iOS, iPadOS and Android browser applications.
- Advanced Arc-style Spaces and workspace automation.

### OD17 / historical OD18 clarification

Historical OD18 broadly deferred Spaces.

OD17 now explicitly selects basic Arc-style Spaces and workspace organization for M1 while deferring advanced Spaces and workspace automation.

Preserve OD18 historically. Record this as a scoped distinction/refinement. Do not silently rewrite OD18 or claim its original meaning was different.

## 3.7 Historical decision namespace

Preserve:
- Historical OD01–OD20.
- Current review OD-R01–OD-R20.
- WS01.1 crosswalk.

Never equate matching numeric suffixes.

Historical OD20 implementation authorization is not the same as current OD-R20 download/backup policy.

Preserve the historical OD07, OD08 and OD14 mappings and their documented relationships.

---



## Engineering qualifications

OP-01–OP-04 are Owner-Decided; dependencies remain technical validation dependencies. The selected history presets are 30/90 days, one year and Forever. OD-R12's original custom-retention statement is preserved below; the precise custom UI/schema integration is not silently deleted or implemented. User-created snapshots' manual retention does not choose an internal recovery-snapshot TTL. Internal recovery lifecycle, checkpoint consistency and field formats remain engineering specification work. Known signed-in compatibility workflows remain public-pages-only/access-blocked until authorized test environments exist.

## Preserved OD-R01–OD-R20

### Verbatim normative owner entries

### OD-R01 — Swift 6 Browser Core Runtime

**Disposition: Approved**

Use Swift 6 as the Browser Core runtime.

Approved direction:

- Foundation-based, engine-independent domain values.
- Actor-coordinated core state.
- Native host retains macOS platform authority.
- Swift-native architecture for the initial M1 core.

This approves the runtime direction, not every implementation detail or the final package implementation.

### OD-R02 — Same-Process Native Host and Browser Core Boundary

**Disposition: Approved**

Use a same-process Native Host and Browser Core boundary for the initial MVP.

Approved direction:

- Native Host and Browser Core execute within the application process.
- Web-content processes remain engine-managed.
- Browser Core owns browser policy and authoritative state.
- Native Host owns platform-specific execution and application lifecycle.

A same-process module boundary is not a security sandbox or crash-isolation boundary.

### OD-R03 — Four-Target Package Structure

**Disposition: Approved**

Use the proposed four-target logical package structure:

1. `BrowserDomain`
2. `BrowserPorts`
3. `BrowserCore`
4. `BrowserPersistence`

Approved direction:

- Domain models and rules remain engine-independent.
- Ports define contracts.
- Core orchestrates browser behaviour.
- Persistence implements browser-owned storage.

The final dependency graph, target boundaries and engine-adapter placement still require technical specification.

### OD-R04 — SQLite Persistence Adapter and Offline-First Operation

**Disposition: Approved**

Use SQLite as the primary Browser-owned persistence adapter.

Approved direction:

- Browser-owned persistence works without a local server.
- Core local functionality works offline.
- No mandatory Vezham cloud account or service dependency.
- Repository contracts remain independent of SQLite implementation.
- Cloud sync and Tamizhi remain optional future capabilities.

PocketBase is not selected as the primary local persistence adapter.

### OD-R05 — Database Topology

**Disposition: Approved**

Use:

- One browser catalog database.
- Separate SQLite databases for persistent profiles.
- Memory-only browser-owned state for private browsing.

Conceptual topology:

- Browser catalog database for global profile registry and browser-level metadata.
- Profile database for profile-specific browser-owned data.
- Private session state excluded from persistent browser-owned storage.

The exact directory layout, schema and cross-resource transaction strategy remain technical specification work.

### OD-R06 — Private Browsing Storage

**Disposition: Approved**

Use memory-only browser-owned private-session state and nonpersistent WebKit website-data storage.

Approved direction:

- Private browsing does not write persistent browser-owned history or session metadata.
- Private WebKit views use nonpersistent website-data storage.
- Private session state is not restored after application restart.
- Private permission decisions do not modify persistent profile grants.
- Explicitly saved downloads may remain as user files, but private download history must not persist.

Validate cleanup, lifecycle and OS-level privacy limitations.

### OD-R07 — Persistent Profile Encryption

**Disposition: Approved**

Use full persistent-profile encryption.

Approved direction:

- Unique encryption key per persistent profile.
- Protect persistent profile data.
- Include SQLite database-associated files such as WAL, journals and temporary files in the protection assessment.
- Define authenticated integrity, key rotation and format versioning.
- Assess browser catalog protection separately.

WebKit-managed website data is a separate protection domain and is not automatically covered by SQLite encryption.

### OD-R08 — Keychain and Independent Recovery

**Disposition: Approved**

Use macOS Keychain protection together with independent recovery material.

Approved direction:

- Generate cryptographically secure unique profile key material.
- Protect normal-access key material using macOS Keychain.
- Provide independent user-controlled recovery material.
- Support offline recovery without a mandatory Vezham account or cloud service.
- Define key hierarchy, recovery, rotation and loss handling.

Recovery material must provide an independent recovery path for the profile encryption key.

### OD-R09 — Profile Unlock and Authentication Policy

**Disposition: Approved**

Use OS-native unlock with optional profile locking.

Approved direction:

- Normal access uses macOS Keychain.
- Do not require a separate browser password at every launch by default.
- Users can manually lock individual profiles.
- Unlock requires macOS authentication when a profile is locked.
- Define inactivity locking and secure key lifecycle behaviour.

A UI-only lock is insufficient if the encryption key remains available to unrestricted operations in memory.

### OD-R10 — WebKit Website-Data Store Architecture

**Disposition: Approved**

Use dedicated WebKit website-data stores per persistent profile.

Approved direction:

- Each persistent profile has its own persistent WebKit data store.
- Private browsing uses a nonpersistent WebKit data store.
- Cookies, LocalStorage, IndexedDB, service-worker data and caches are isolated by profile.
- Browser Core controls profile-to-store assignment.
- Website-data deletion and cleanup are explicit operations.

Validate actual WebKit storage protection, backup behaviour and deletion semantics independently.

### OD-R11 — Website Permissions and Authorization

**Disposition: Approved**

Browser Core owns the central website-permission and authorization policy.

Approved direction:

- Grants are scoped to verified origin and capability.
- Grants are isolated between profiles.
- Temporary and persistent grants are supported.
- Users can inspect and revoke grants.
- Private-session decisions do not modify persistent profile records.
- OS authorization remains an independent enforcement layer.
- Unsupported or ambiguous requests fail closed.

WebKit capabilities and callbacks must be validated individually.

### OD-R12 — History Retention and Deletion

**Disposition: Approved**

Use profile-specific browsing history with **Forever as the default retention period**.

Approved direction:

- Configurable retention: 30 days, 90 days, one year and custom.
- Delete individual entries.
- Delete by date range.
- Delete all history.
- Private browsing is excluded.
- Retention and deletion work offline.
- Deleted history must not silently reappear after backup restoration.

Clear Browsing Data must provide independent controls for history, cookies, website data, cache, download history and permissions.

Deleting download history does not delete downloaded files.

### OD-R13 — Downloads Storage and Lifecycle Management

**Disposition: Approved**

Use the macOS Downloads directory as the default destination, with configurable locations.

Approved direction:

- Download metadata is encrypted and profile-specific.
- Actual downloaded files are separate from browser-owned metadata.
- No silent overwrites.
- Safe duplicate-name handling.
- Resume interrupted downloads where supported.
- Clean abandoned temporary files.
- Private-session downloads may be explicitly saved.
- Private download history is not persisted.
- Deleting profile metadata does not automatically delete externally saved files.

Validate WebKit resume support and download lifecycle behaviour.

### OD-R14 — Encrypted Portable Backup, Restore and Migration

**Disposition: Approved**

Use encrypted, portable and offline-first backups.

Approved direction:

- Independent profile backups.
- Full-browser backups covering catalog and selected persistent profiles.
- Independent recovery capability.
- Offline export and restore.
- Cross-Mac migration and restoration without Vezham account dependency.
- Private-session data excluded.
- Downloaded files excluded by default, with optional user selection.
- Versioned backup manifests.
- Validated migrations.
- Preserve existing backups until restoration succeeds.
- Restore must not silently resurrect deliberately deleted data.

WebKit-managed website data should be included only where reliable backup and restoration are validated.

### OD-R15 — Static Capability Composition

**Disposition: Approved**

Use static capability composition for M1.

Approved direction:

- Trusted capabilities are wired during application startup.
- No dynamic plugin or arbitrary runtime loading in M1.
- Browser Core owns capability lifecycle and authorization policy.
- Native Host performs platform-specific execution.
- Optional capabilities may be unavailable.
- Capability registration or readiness does not grant permissions.
- Required capability failures must be handled explicitly.

Future dynamic extensibility requires separate review.

### OD-R16 — Typed Capability Contracts and Events

**Disposition: Approved**

Use explicit typed Swift capability protocols and profile-scoped typed events.

Approved direction:

- Structured typed inputs and results.
- Explicit subscription lifecycle.
- Owned cancellation and cleanup.
- Browser Core retains authorization authority.
- No unrestricted cross-profile event feed.
- No authorization-rewriting middleware.

Event ordering, sequence gaps, lock/unlock fencing, overflow and terminal operation outcomes still require normative contracts.

### OD-R17 — Deleted-Data Reconciliation Across Backups

**Disposition: Approved — Option D**

Use independent deletion records where available.

Approved direction:

- Maintain deletion records where feasible.
- If deletion status is unknown, require explicit user confirmation before restoring potentially affected data.
- Preserve offline backup and recovery capability.
- Do not claim that user confirmation guarantees deleted information cannot reappear.

Important limitation:
An old offline backup cannot automatically know about deletions performed after it was created. The specification must define how updated deletion records are propagated to other devices and backup media.

### OD-R18 — Profile Lock Policy

**Disposition: Approved — Option A**

Approved lock triggers:

- macOS locks.
- Mac goes to sleep.
- User switches macOS sessions.
- Configurable inactivity timeout.
- Manual locking at any time.

While locked:

- Block profile data access.
- Suspend associated WebKit views.
- Invalidate active access to its encryption key.
- Keep other unlocked profiles unaffected.

Define lock-state transitions, key reacquisition, in-flight operations, downloads, queued results, subscriptions and partial-failure recovery.

### OD-R19 — Recovery-Material Custody and Loss

**Disposition: Approved — Option D**

Approved direction:

- Provide a printable recovery kit.
- Provide an exportable encrypted recovery file.
- Generate recovery material locally.
- Store recovery material separately from the Mac and profile backups.
- Verify successful saving/export.
- Never transmit or retain an unprotected copy on Vezham servers.
- Warn that loss of both Keychain key material and recovery material may make the profile permanently unrecoverable.

The recovery-file format, protection, verification and recovery workflow require technical specification.

### OD-R20 — Download and Backup Policy

**Disposition: Approved — Option D**

Approved direction:

- Downloaded files are excluded from backups by default.
- Users can optionally include downloaded files.
- Users can select all or individual files.
- Show estimated backup size before starting.
- Preserve original file locations.
- Avoid silent overwrites on restore.
- Keep encrypted download metadata separate from actual downloaded files.
- Deleting a profile must not silently delete externally saved files.

Define selection manifests, integrity verification, duplicate handling, missing/moved files and failure recovery.



## WS01.1 historical crosswalk (historical meanings preserved)

## 26. Historical decision crosswalk

This crosswalk is preserved from the preceding audit, using its historical references. It was not reconstructed from numeric suffixes or freshly reverified here.

Historical source: [owner packet matrix](/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/docs/architecture/phase-5/reports/M1/m1-owner-decision-packet.md:30). Line references below refer to that previously inspected version.

| Historical ID / line | Historical meaning | Current correspondence |
|---|---|---|
| OD01 / 32 | Swift 6 trusted core | OD-R01 matches |
| OD02 / 33 | Host/core same native process | OD-R02 matches/refines limitations |
| OD03 / 34 | Domain/Ports/Core/Persistence package | OD-R03 matches; concrete graph technical |
| OD04 / 35 | SQLite repository adapter | OD-R04 refines offline/no-server requirement |
| OD05 / 36 | Catalog plus per-profile databases | OD-R05 matches |
| OD06 / 37 | Memory-only private core; no persistent lease | OD-R06 adds explicit engine/download conditions |
| OD07 / 38 | Fixture-first; real-data protection choice open | Refined across OD-R07/08/09/18/19; optional encryption alternative superseded |
| OD08 / 39 | History 30 days; bookmarks/preferences until deletion; recovery-history cause open | OD-R12 supersedes history default; OP-04 now owner-decided; checkpoint/cause engineering remains |
| OD09 / 40 | Download metadata 30 days; separate file lifetime | OD-R13/20 refine file policy; TTL remains OP-02 |
| OD10 / 41 | URL/title/query/fragment inventory | Related OD-R07/12; OP-01 owner-decided; exact schema remains engineering |
| OD11 / 42 | One pre-migration snapshot, at most 24h | OD-R14/17/20 expand backup scope; OP-03 user-created retention decided; internal lifecycle remains engineering |
| OD12 / 43 | Opt-in capture/default-off reopening; explicit recovery | No direct current replacement; related OD-R14/16; OP-04 owner-decided; exact transitions remain engineering |
| OD13 / 44 | Privacy epochs/deletion intents/snapshot invalidation | OD-R12/17 refine records and unknown coverage |
| OD14 / 45 | Checksummed migrations, minimum writer, transactions, bounded receipts | Supports OD-R04/05/14; not equivalent to current OD-R14 |
| OD15 / 46 | Static bindings and owned lifecycle | OD-R15 matches/refines authority |
| OD16 / 47 | Typed ports/events and bounded subscriptions | OD-R16 refines exact contracts |
| OD17 / 48 | Launch-required built-ins/workflows/permission scope | Related OD-R10/11/13/15/16; launch scope still open |
| OD18 / 49 | Extensions/spaces/advanced search deferred | OD-R15 retains dynamic-loading exclusion; current OD17 selects basic Spaces while advanced automation remains deferred |
| OD19 / 50 | Future Tamizhi/optional services | OD-R04 matches optional scope |
| OD20 / 51 | I1/I2/synthetic-I3 execution proposal, not granted | Current authorization remains not granted; OD-R20 is a different subject |

Historical proposals are not retroactively marked approved. WS01.1 preserves both namespaces.



Current overlay: OP-01–OP-04 are now owner-decided by the current instruction; the current-correspondence column reflects the latest policy overlay while original historical subjects remain unchanged. Historical OD18 remains a broad Spaces deferral; current historical-OD17 scope selects basic Spaces/workspaces and defers advanced automation. No numeric namespace is equated with another.

