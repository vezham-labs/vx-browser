from pathlib import Path
R=Path('/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser')
M=R/'docs/architecture/phase-5/reports/M1'
E='../../evidence/20261109T105707Z-webkit-storage-wsf2/'
def report(name,title,body):
 (M/name).write_text('# '+title+'\n\n2026-11-09. WS-F2 implementation/qualification review. '+
 '[Closeout](m1-wsf2-closeout.md) · [Actual results](m1-wsf2-qualification-results.md) · '+
 '[Evidence]('+E+'README.md). **No release approval.**\n\n'+body.strip()+'\n')
report('m1-wsf2-webkit-runtime-hardening.md','WS-F2 WebKit runtime hardening','''
## Implemented integration

The existing NativeWebKitStorage is extended rather than replaced. Its explicit store/configuration/view ownership, noncreating identifier observation, default-store prohibition, construction-before-publication ordering, generation checks, separate clear/remove callbacks and15-second observed private-retirement budget remain. Earlier2-second private failures and all WS-F1 evidence stay unchanged. No private API, filesystem manipulation of engine data, SQLCipher wrapping or default-store warmup is added.

The security fence is independent of ordinary lifecycle acquisition fences. Core's allow-acquisition request cannot clear a security lock or content-process poison fence. Lock cancels owned navigation continuations, stops loading, retires views/configurations through Core, and observes resources before returning Locked. The host rechecks authority/native publication after its awaited journal finalization. Navigation request issuance is an additional coarse structured trace event; no URL/content is logged.

## HTTP cache investigation

The new controlled origin uses a unique `/cache-probe/UUID`, fresh per-test server counters, explicit `Cache-Control: public, max-age=86400, immutable`, ETag and actual server request observations. The page awaits two `force-cache` fetches and returns only registered public synthetic response markers. A and B use the same origin/path, distinct store mappings and distinct response markers. Within a live profile the second fetch reuses the response without another server request. Actual process exit/relaunch and abrupt termination/relaunch cause new network retrieval in the recorded fixture. No conditional ETag request was observed in those runs. This establishes bounded response/network behavior, not WebKit disk contents or a universal persistence guarantee.

Selected HTTP-cache and full selected-category clearing now have in-process positive population before clearing, callback/record verification and a new page-visible response afterward. Reconstructing a view after that clear is distinct from app restart. Normal store removal records callback and noncreating absence; no creating check reopens removed identifiers. Exact per-process marker and server observations are in the current `f2-webkit-native-*` evidence and cache-analysis record. WS-F1's original HTTP-cache INCONCLUSIVE results remain historical; disk persistence remains INCONCLUSIVE where public observability is insufficient.

## Expanded lifecycle and limitations

Qualification includes same-profile two-view/two-window composition, a separate simultaneously open profile, manual lock, other-profile survival, navigation outstanding during lock, repeated lock convergence, actual lock-fence child termination and conservative fresh-process locking. Resources may initially need RecoveryRequired while an awaited navigation's local references drain; a later lock may reach Locked only after empty-resource/no-key observations. This is not a false earlier Locked result or an assertion that all WebKit internal processes stopped.

The original full WS-F1 suite is also executed against WS-F2 implementation inputs. It retains persistent/private/isolation/switch/selected clear/normal remove and11 lifecycle cutpoints plus private termination. No different-revision pass aggregation. In-use/error/timeout tests not actually forced at the native API remain unqualified; fake errors are supporting policy evidence only. Selected domain-record/modified-since semantics, issued-before-callback timing, independently attributed engine-process faults and complete native lock/key barriers remain open.
''')
report('m1-wsf2-protected-catalog.md','WS-F2 protected catalog','''
## Status: BLOCKED at actual provider initialization

The application now composes `BrowserPersistence.ProtectedCatalog`, the existing ProfileCatalogPort and RecoveryJournalPort implementation point. Normal startup uses `NativeStorageSession.protectedFoundation()`. It does not substitute the qualification memory catalog or an unprotected file/database for production persistence. Missing keys/catalog cannot cause a new profile/store to be published. The foundation window reports protected storage unavailable; no schema/migration/provider is executed.

`ProtectedCatalog.swift` returns typed catalog/journal unavailable results, an inventory issue and invalid restart snapshot. It does not call SQLCipher, open/create a database, hash/copy existing ciphertext or introduce an initialization exception. This is an enforced integration gate, **not a functioning protected catalog**. Actual persistent creation/reopen, transactions, migration, corruption recovery, tombstones and authenticated stored lock/grant state are BLOCKED.

## Implemented independent contracts

`CatalogSchema` defines version2 and ordered0→1→2 migration plans. Version1 defines catalog identity/revision, profile/store uniqueness, protected descriptor and human label, lifecycle journal and idempotency receipts. Version2 adds independent deletion records, profile lock/key-version/epoch and profile/origin/capability permission records. Metadata timestamps/creation/publication/retirement/removal/migration state live in the validated versioned descriptor. Private session mappings are rejected. Labels are bounded, nonempty and not diagnostic data. Schema planning rejects unauthenticated, interrupted and future-version input; no downgrade/discard path exists.

Required execution contract remains: authenticated scoped provider connection and suite/schema identity first; a serialized transaction validates expected revision/receipt, writes intent/mutation, advances revision and records outcome. Each migration must run in its own authenticated transaction with schema advancement committed only on success; failed/interrupted work preserves originals and denies publication. `mayPublish` independently requires exact revision, stable journal, authenticated key and engine readiness. The migration strings and policy tests are executable planning/validation, **not tested SQLite transactions**. Provider-backed executor, binding, rollback, busy/disk-full handling and migration crash recovery are not implemented or qualified while D2A-01 is blocked.

## D2A-01 and exact operation blocked

The pinned source remains `355d4db92d3404e71faa8088d071a71d767807f4`, SQLCipher4.20.0 Community/CommonCrypto. The reviewed public open path reaches an offset-zero100-byte pager header request before returning a connection for length-explicit `sqlite3_key`. No already-approved compliant existing-file path was established. Receiving a key in RAM does not satisfy binding to that target connection. Read-only, URI keys, ATTACH, auto extensions, fabricated VFS headers and pre-key copy/hash are not loopholes.

See [the existing exact options](m1-sqlcipher-open01-resolution.md) and [WS-F2 decision handoff](m1-wsf2-security-decision-proposal.md). D2A-01 stays Proposed/Not Decided; no source pin, vendor signature, SQLCipher worker/PQR definition or owner requirement changes. New empty-file creation alone cannot qualify restart and could leave an unusable product catalog, so no partial production database is created. All actual catalog-dependent features remain visibly gated.

## WebKit consistency

Core's existing intent/journal/tombstone state machine coordinates WebKit through typed ports. Qualification uses the same existing memory adapter mirrored across actual app processes; those synthetic checkpoints are not encrypted product persistence. There is no SQLite/WebKit cross-system atomic transaction. Unknown native effects or failed metadata finalization stay fenced rather than recreating empty stores or publishing successful deletion.
''')
report('m1-wsf2-keychain-integration.md','WS-F2 Keychain integration','''
## Actual adapter and policy

`BrowserNativeStorage/NativeKeychain.swift` implements SecRandomCopyBytes, SecAccessControlCreateWithFlags, SecItemAdd/CopyMatching/Delete and LAContext. `NativeStorageSession.keys` connects it to the Core security lifecycle through the opaque ProfileKeyPort. Profile/run/epoch-bound KeyLease values contain no key bytes. IDs alone do not grant access: exact current host context, profile, run and reference version are checked before OS work and after async authority checks. Revocation advances epoch, invalidates contexts, retires the native cache and best-effort clears its owned buffer. CryptoKit/provider/Data copies and OS memory artifacts are not claimed erased.

| Configuration | Implemented value |
|---|---|
| Item | GenericPassword,32-byte normal KEK candidate |
| Service | `internal.vx.browser.keys.v1`; synthetic tests append `.qualification.UUID` |
| Account | scope kind/profile UUID/key UUID/version; no labels/URLs |
| Keychain | `kSecUseDataProtectionKeychain=true` |
| Accessibility/ACL | `WhenUnlockedThisDeviceOnly` with `userPresence`; no conflicting accessible attribute |
| Sync/groups | synchronizable=false; default app access group only; no shared/unrelated entitlement |
| Interactive unlock | fresh OS context with deviceOwnerAuthentication; denied/unavailable leaves locked |
| Noninteractive qualification | context interactionNotAllowed; cannot bypass userPresence |

## Actual native result and blocker

The ad-hoc sandboxed qualification app reached the real Keychain. Missing-item lookup succeeded; create and delete returned `-34018` (errSecMissingEntitlement), and lookup after failed creation returned `-25300` (item not found). Host discovery found0 valid code-signing identities. This is a signing/access-group environment blocker, not proof that the32-byte value or ACL is valid under a proper signing identity. No keychain access-group entitlement, weaker ACL, synchronizable item, file/env secret or conventional-Keychain fallback is added to make a test pass.

The first restart oracle incorrectly required existence after blocked creation and failed; that outcome is retained. The corrected run records the existence test BLOCKED and separately tests the missing-item control in another actual process. Foreign-scope rejection is PASS_CONTRACT, not native OS denial. Successful item creation, duplicate-item runtime, authenticated read/restart, rotation and full key recovery remain BLOCKED or NOT_EXECUTED. Coarse OS status numbers are retained without key bytes, key hashes or raw error contents. Qualification namespace/reference fixtures permit exact later inspection; no user's existing keys are queried or deleted.

## Upgrade, replacement and recovery limits

Stable signed app/default access-group identity and service/account continuity are prerequisites; actual signed upgrade/reinstall behavior is NOT_EXECUTED. ThisDeviceOnly material is not a cross-Mac recovery credential. Missing/wrong/denied items never regenerate a key over an existing profile. KEK rewrap/DEK rotation and independently authenticated normal/recovery slot publication retain the existing key specification; they are not silently replaced by direct bulk-key storage.

The native backup recovery handle is a purpose-separated, memory-only authority for synthetic archive qualification. It is not the profile DEK/normal KEK or a completed printable recovery kit. Normal/recovery envelope v1, custody verification, key-ring rotation, old-backup dependencies and independent second-Mac recovery remain unimplemented/unqualified. The existing OD-R08/19 requirements are preserved. Production key publication remains blocked until its required durable state and custody gates exist.
''')
report('m1-wsf2-profile-locking.md','WS-F2 profile locking','''
## Policy and native enforcement

`BrowserCore/ProfileSecurityCoordinator.swift` implements Unlocked → LockRequested → Quiescing → Locked, and UnlockRequested → Unlocking → Unlocked or RecoveryRequired. Unknown profiles fail closed. Initial locked registration performs retirement checks; it cannot set Locked merely from a UI flag. Monotonic epochs reject stale async work, including an unlock reply arriving after a newer lock. Duplicate in-progress locks do not start parallel retirement. A later explicit lock may safely converge from RecoveryRequired after outstanding references drain; exact terminal-state equality is not required in that situation.

Lock installs the native security fence first, invalidates permission grants/prompts, revokes key leases, closes owned Core views, quiesces and retires the native store. Locked requires completed owned-resource retirement and no active key lease. Retained external/configuration/pending references produce RecoveryRequired. Core's ordinary acquisition API cannot remove this fence. Other profiles retain separate authority and native resources.

`NativeProfileBarrier` integrates existing Core/view/resource ports, not a second lifecycle coordinator. `NativeProfileAuthentication` implements real OS authentication for explicit unlock. Even successful OS authentication cannot unlock without authenticated key/catalog reconciliation; the D2A-01 gate returns RecoveryRequired rather than admitting an unprotected profile. Unlock performs no automatic navigation/form/POST replay.

## Native observations and limits

Qualification exercises two views/windows, a simultaneous independent profile, lock during outstanding controlled navigation, repeated requests, blocked old-view navigation, key-lease absence, other-profile survival and actual lock-fence process death/relaunch. These use synthetic catalogs; no real loaded profile key existed because Keychain creation was blocked. No-key-cache observation is therefore not qualification of revoking a successfully acquired protected key.

Navigation can leave a locally retained async object briefly alive. The first lock may truthfully return RecoveryRequired; a later retry may reach Locked only when resource/key observations pass. The earlier too-strict equality assertion and its failure remain preserved. Actual restart uses a recorded synthetic checkpoint and conservative initial locking with no creating factory. It is not a durable protected lock receipt or complete crash-safe lock/unlock transaction.

## OS lifecycle and outstanding requirements

`NativeSecurityLifecycle` observes public sleep/session-resign signals, local activity and a configurable inactivity timer (default900seconds, minimum30). App termination awaits Core lockAll before replying to AppKit. No global input monitor, undocumented screen-lock notification or private API is used. Actual macOS lock-screen trigger coverage, sleep/session-switch integration, inactivity timing and signed restart behavior remain NOT_EXECUTED; the missing screen-lock signal route is an explicit mandatory gap, not a waiver of OD-R18.

Downloads are not implemented; no live transfer is silently ignored or claimed suspended. In-flight clear/remove, key-provider operations and multiwindow hostile interleavings still need complete integrated qualification. WebKit files are not cryptographically revoked by a profile lock, and weak object observations do not prove every internal process stopped. Gate D remains partial/BLOCKED for full native unlock/key/persistence/OS-trigger guarantees.
''')
report('m1-wsf2-permission-policy.md','WS-F2 permission policy','''
## Core and native path

`PermissionCoordinator` owns verified-origin/capability/profile policy, bounded pending tickets and session grants. Requests require a current native host context/run/view generation. Supported, safely mediated new requests return Ask; unsupported, ambiguous, denied/unavailable OS authorization or stale/locked scope returns Deny. Tickets bind scope/epoch and are consumed once. OS authorization never substitutes for browser consent, nor browser Allow for OS access.

The native media delegate verifies owned published WKWebView, current generation/fence, main frame, top-level scheme/host/port and requesting WKSecurityOrigin before constructing a Core request. Ask has a native Allow Once/Don’t Allow sheet on the owned window; it rechecks current state afterward. No media entitlement/purpose string is introduced, so this positive path is not enabled or claimed qualified. Other delegate families remain fail closed. Logs contain coarse outcome only, no origin/URL/token/content.

## Actual support matrix

| Permission kind | Public mapping / OS dependency | Current product/native status |
|---|---|---|
| Camera, microphone, combined | WKUIDelegate media callback; separate AVCapture/TCC status | Denial path integrated; positive Ask/Allow BLOCKED pending purpose/entitlement/OS and active-stream revocation qualification |
| Geolocation | Separate platform/geolocation mediation needed | Unsupported, fail closed; no affirmative support claimed |
| Website notifications | Distinct from native notifications | Unsupported; no automatic notification grant |
| Display capture | Requires separately validated API/user selection | Unsupported; no screen capture |
| Clipboard read/write | Separate origin/user-action contracts | Unsupported; no generic native clipboard bridge |
| File read/write | Existing chooser/transfer brokers not implemented | Upload panel refused; no native file token/grant |
| MIDI | No positively qualified public native mapping | Unsupported/fail closed |
| Unknown | No safe mapping | Deny-only |

Native qualification requests synthetic loopback microphone access with no media entitlement; any unexpected stream is immediately stopped and fails the case. The result distinguishes actual delegate observation from platform pre-denial; a page-level rejection alone does not qualify browser prompt mediation. Positive allow, native Ask UI and active stream revocation are NOT_EXECUTED/BLOCKED. Contract tests exercise Ask/Allow/Deny, native-status independence, one-time/session decisions, revocation, stale prompts, private sessions and unsupported kinds without claiming native positive support.

## Persistence and revocation

Persistent grants are refused while the protected catalog is blocked; private decisions never write a persistent adapter. Intended protected fields are profile, verified origin, kind, decision/lifetime, creation/update and revocation/expiry metadata; no OS secrets. Session grants are memory-only and vanish on process restart. Lock/session end/profile deletion must invalidate them before new admission. Revocation currently conservatively invalidates the scope's pending decisions and session grants; final per-grant inspection/revocation UX and durable expiry require specification/integration.

This preserves the owner's eventual Ask policy without advertising unverified kinds. Gate E is partial: real delegate denial is integrated, while durable grants, native positive routes, stream/device revocation and full supported-kind matrix remain mandatory gaps.
''')
report('m1-wsf2-backup-and-restore.md','WS-F2 backup, restore and deletion','''
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
''')
report('m1-wsf2-recovery-and-reconciliation.md','WS-F2 recovery and reconciliation','''
## Implemented layers

Existing Core lifecycle/journal/receipts and native WSF1 reconciliation remain authoritative for engine operations. `StorageRecoveryPolicy` adds a pure cross-component eligibility gate: authenticated catalog, available matching key, present engine, stable intent and complete deletion knowledge are all required before even proposing explicit unlock. Recorded lock remains locked. Missing/corrupt/future/unavailable catalog, missing/denied/mismatched key, missing/unknown/uncertain-removal engine and creation/publication/lock/unlock/clear/backup/restore/delete intents require recovery. Eligibility is not authorization or publication.

Native unlock invokes that gate with truthful unavailable catalog/key state and refuses admission. Startup has no plaintext fallback, orphan adoption, random replacement profile or default store. Key loss never regenerates over ciphertext. Pending tombstones/unknown engine results remain preserved; absence alone cannot manufacture a callback-confirmed removal. Permission epochs invalidate late grants. Backup restore authenticates full content, applies known deletion IDs and refuses unknown lineage without explicit confirmation; no stale grant/native token restores as authority.

## Actual process behavior and evidence limits

The current WSF1 native regression actually terminates/relaunches the dedicated host across clean restart, interrupted creation/publication/clear/removal/reconciliation and private death. Its synthetic catalog/journal metadata is mirrored through parent evidence; this is not actual protected disk state. WSF2 additionally performs Keychain attempts in separate processes, actual cache abrupt termination/relaunch, and lock-fence interruption/fresh-process conservative lock admission. Distinguish PID restart, object reconstruction, engine resolution, website class persistence and browser-owned checkpoint handling.

Keychain creation cannot qualify key restart because -34018 prevented item creation. The first harness expectation was wrong and remains a preserved FAIL; corrected handling records BLOCKED plus a real missing-item control. Lock navigation can cause RecoveryRequired until references drain; later lock convergence is not retroactive success. No uncertain native/staged fixture is silently swept or recycled.

## Not qualified

Actual encrypted catalog reopen/migration/transaction failure, protected journal/tombstone persistence, key/cipher identity reconciliation, durable lock/unlock/permission receipts, encrypted backup/restore process recovery and user recovery custody remain BLOCKED. Faults modeled by policy/fakes are not native I/O/cipher/TCC behavior. Real provider opening is not attempted to satisfy a recovery test. Existing SQLCipher PQR/EXP outcomes remain unchanged.

No cross-system atomicity, auto repair, secure erasure, universal private forensic cleanup or unconditional browser readiness is claimed. Safe recovery may require explicit user action after the concrete signing/provider gates are resolved.
''')
report('m1-wsf2-qualification-plan.md','WS-F2 qualification plan','''
## Frozen platform, host and commands

Primary WS-F2 platform is actual macOS27.2/26B123 arm64, Swift6.4.2/SDK27.2. The existing AppKit target links the actual native module; Debug-only `--wsf2-qualification` selects synthetic cases, and `--wsf1-qualification` retains the original regression host. Normal application startup composes the guarded production catalog, keys, permissions/security coordinator and public AppKit lifecycle integration. No alternate standalone product implementation is used.

Uncached Nx targets: `browser-macos:storage-f2-build`, `storage-f2-contracts`, `storage-f2-native`, `storage-f2-webkit`; retained `webkit-storage-wsf0:verify` and `browser-macos:storage-native` supply regressions. Supply `--evidence=<new registered run directory>`; native F2 targets require `--build-record=<exact build result.json>`. The WSF1 regression also takes its pinned enumeration-only `--diagnostic-record`. Use repository-pinned pnpm/Nx; the recorded environment uses local `node node_modules/nx/dist/bin/nx.js` with daemon/cloud/plugin isolation disabled and owned temporary cache/data directories. No dependencies or host security settings are changed.

Each attempt records commands/stdout/stderr, source hashes and binary identity; do not reuse cached native pass results. SwiftPM manifest sandbox remains enabled; build credential discovery is disabled. Actual Keychain qualification deliberately calls the adapter, uses only exact random service/account fixtures and noninteractive contexts, and never exports test secrets. SecItem failures preserve ACL/sandbox/signing controls.

## Test groups and disposition rules

| IDs / group | Actual method and oracle |
|---|---|
| Original F0-* |82 retained deterministic fake cases; same source IDs/providers preserved |
| F1-MOD/GUARD, F1-FAKE |12 original contract checks plus close/clear fake race; no native store/key operation |
| F2-CON-001–011 | Protected-catalog refusal; authenticated migration planning; origin validation; Ask/Allow/Deny/revoke/OS/private policy; error classification; canonical CBOR/backup bounds; deletion; catalog publication and cross-component recovery |
| F2-FAKE-001 | Injected barrier/key/auth states: fence→revoke→retire ordering, auth denial, blocked reconciliation, unlock and incomplete retirement; fake only |
| F2-KEY-* | Actual SecItem/ACL/random generation on dedicated namespace; create then separate-process lookup/delete. Creation failure blocks dependent existence/acquisition/rotation; never assume a key exists |
| F2-BACKUP-* | Actual CryptoKit/owned synthetic file operations, authenticated corruption/scope tests, deletion filtering, incomplete output and conflict/private controls. No actual product DB source/import |
| F2-CACHE-* | Unique cache endpoint, explicit headers/ETag, same-profile repeated fetch, A/B positive isolation, actual restart/kill/relaunch, in-process pre-clear controls, selected/full clear and normal removal |
| F2-LOCK-* | Two views/windows and another live profile, native resource fence/retirement, navigation interruption, repeated convergence, actual lock-fence death/restart; cannot pass protected unlock/key revocation without their prerequisites |
| F2-PERM-* | Actual loopback getUserMedia rejection; record delegate versus pre-denial. Any unexpected stream stops immediately and fails. Positive grant/Ask/TCC behavior remains separately blocked |
| Original native WSF1 recipes | Persistent/private class behavior, isolation/switch, clear/remove, publication failure and11 exact lifecycle cutpoints with actual child restarts |

PASS_NATIVE is always bounded by exact class/fixture/platform/oracle; policy/admission/fake cases retain PASS_CONTRACT/PASS_FAKE_ONLY. BLOCKED, NOT_EXECUTED, FAIL and INCONCLUSIVE are distinct. Do not aggregate different revisions or fake/native totals. A runner can exit0 while reporting blocked dependent cases; that is not a milestone PASS.

## Failure and fixture safety

Each child is Popen-owned with exact input/PID/binary; only that child can be killed. Parent budget100seconds for F2, inherited120seconds for F1. Selected self-stop cutpoints use SIGSTOP followed by parent SIGKILL and actual relaunch. Native callbacks keep their existing15-second budgets. Unexpected failures stop that dependent sequence and preserve evidence/resources; a material correction receives a new hashed attempt. No broad process kill, OS permission reset, security relaxation, user data, engine database/path manipulation or real disk-fill corruption is used.

Follow the gate/failure ledger for blocked actual catalog transactions, key creation/recovery, native positive grants, durable lock receipts, archive process recovery and true native error/drop-callback tests. macOS26.0/latest26.x are deliberately not executed for this milestone; see the dedicated release backlog. No public distribution is authorized by that scheduling change.
''')
report('m1-wsf2-risks-and-limitations.md','WS-F2 risks and limitations','''
1. **Protected persistence is not implemented as a usable runtime.** D2A-01 still prevents compliant existing-file SQLCipher open. A gate/schema planner is not a functioning encrypted catalog, transaction/migration executor or durable recovery journal. No provider/PQR runtime pass is inferred.
2. **Keychain creation/access is environment-blocked.** Required data-protection/userPresence items returned-34018 under ad-hoc identity;0 valid signing identities exist. No weaker ACL/access group/alternate key store is selected. Successful key creation, duplicate/rotation/authenticated reopen and actual loaded-key revocation remain unqualified.
3. **Full lock guarantees remain incomplete.** Native view fencing/retirement is tested; cryptographic revocation of WebKit-managed files is unavailable. Actual screen-lock signal, sleep/session/inactivity/upgrade behavior, in-flight transfers/storage errors and protected unlock receipts remain gaps. RecoveryRequired is not Locked.
4. **Positive native permissions are unqualified.** Core Ask/Allow/Deny is tested by contracts; runtime denial is distinct from a qualified native Ask/Allow route. Persistent grants are blocked by the catalog; no device-support claim follows from negative tests. Active streams need explicit revocation qualification before enabling positive support.
5. **Backups are a bounded synthetic-record native slice.** Authenticated encryption/framing and file publication work; production snapshot/import, full-browser/category schemas, independent recovery kit/file custody, key-ring rotation and second-Mac/process recovery are not complete. The provisional archive framing is not a portable final product format or a replacement for the specified key envelope.
6. **Deletion knowledge is bounded.** Known IDs are filtered; an old offline backup cannot know later deletions. Explicit confirmation of unknown lineage is not a non-resurrection guarantee. Download files are independent and never silently deleted; optional payload selection remains unimplemented.
7. **HTTP cache public observations do not prove disk storage.** The tested path reuses within a process and fetches anew after restart; retain the precise origin/header/cache-mode scope. No WebKit internal file inspection, universal persistence or physical erasure claim.
8. **Qualification catalogs are synthetic.** Parent-mirrored metadata permits actual process tests but is not product encryption, real SQLite commits or a cross-system transaction. Unknown/staged fixtures remain recorded rather than swept/reused.
9. **Platform/release tests are deferred, not waived.** macOS26.0/latest26.x and release signing/notarization/Gatekeeper/updater/performance qualification remain in the dedicated backlog. No macOS26 compatibility, release readiness or public distribution is claimed.
10. **Module/native trust is limited.** Host/Core are same-process boundaries, not sandboxes against compromised trusted code. Native handles/keys never enter Domain/Core/UI; no privileged website message handler, CEF, Aura, production Tamizhi, cloud sync/account prerequisite or dynamic plugin is added.

Owner/security actions are narrowly scoped in the decision handoff. All historical ADR/owner/OP policies, source pins/vendor evidence, WS-F0/WS-F1 failures/checksums and Phase3 results remain unchanged. The milestone must remain INCOMPLETE while essential implementation/security gates are unmet.
''')
report('m1-wsf2-public-release-qualification-backlog.md','WS-F2 public-release qualification backlog','''
The WS-F2 owner instruction deliberately schedules actual macOS26.0/latest supported26.x qualification for the public-release stage. It does not authorize a public release, change the26.0 minimum target, claim26 compatibility or waive security gates. Existing ADR statuses/distribution decisions remain unchanged. Do not deploy an unqualified26-target candidate merely because the current development host is27.2.

| Backlog | Required final-candidate evidence |
|---|---|
| PRQ-01 | Actual26.0 and latest supported26.x, exact app/OS/WebKit/build identities and relevant40 WKS cases; deployment target/27.2 results cannot substitute |
| PRQ-02 | Authorized stable signing identity/default Keychain access group, userPresence item create/read/deny/restart/upgrade/reinstall/loss behavior |
| PRQ-03 | Qualified pinned SQLCipher initialization after explicit D2A-01 decision, complete VFS/worker/authentication/artifact/PQR evidence |
| PRQ-04 | Actual encrypted catalog/profile DB transactions, migration/recovery, tombstones, wrong/missing key, tamper and no plaintext artifacts |
| PRQ-05 | Lock/unlock under OS lock/sleep/session/inactivity, multiple windows, key/engine barrier, transfers and concurrent destructive work |
| PRQ-06 | Per-kind native permission positive/negative Ask/Allow/Deny, OS independence, origin/frame/profile/lifetime and active-stream revocation |
| PRQ-07 | Real authenticated backups/import, independent recovery kit/file verification, source-independent second-Mac/version migration and deletion lineage |
| PRQ-08 | Exact browser-owned category schemas/retention, no private persistence, external-download selection/no overwrite and incomplete-stage recovery |
| PRQ-09 | Developer ID signing/notarization, Gatekeeper, Hardened Runtime/App Sandbox/entitlements, dependency/license inventory and incident/update ownership |
| PRQ-10 | Updater signature/rollback/confinement, critical authorized website/account workflows, reliability/accessibility and final-candidate performance |

All entries are NOT_EXECUTED or BLOCKED until their precise evidence and owner gates pass. Internal-only remains authoritative; any future public distribution requires a separate explicit owner decision. No backlog item is marked passed here.
''')
report('m1-wsf2-security-decision-proposal.md','WS-F2 security decision handoff','''
## No owner decision is recorded by this proposal

D2A-01 remains Proposed/Not Decided. Existing exact options in [OPEN-01](m1-sqlcipher-open01-resolution.md) remain canonical: retain the literal key-before-target-byte-read rule and keep existing-file open blocked, or explicitly approve the narrowly bounded offset0/length100 encrypted-header VFS request exception with all its key-in-RAM/no-SQL/no-write/no-additional-read/no-pre-key-hash-copy conditions. OS read-ahead is not bounded physical-device I/O. This task does not select either option, change the source pin or add an exception.

Without that decision, a usable protected catalog and dependent unlock/persistent-grant/source-backup integration cannot be completed. Even an approved exception would still require real worker/VFS/binding/authentication/artifact qualification; it is not automatic production approval. A maintained vendor key-aware-open API is a separately reviewed alternative, not an invented available solution.

Keychain's concrete environment action is to provide an authorized stable signing identity/default access-group environment and re-run only the exact synthetic userPresence cases. No request is made to weaken ACLs, use shared groups, bypass Gatekeeper or substitute file/env keys. This is an access prerequisite, not a new product-policy choice.

Archive/normal-recovery custody work must continue under existing OD-R08/19 and key-envelope contracts: verified printable kit/encrypted recovery file, independent key recovery, key-ring/retained-backup dependencies and authenticated migration. The provisional archive helper cannot silently settle final interoperability/custody or bypass a blocked source catalog. Remaining public WebKit protection/backup class limitations remain existing owner/security review topics, not newly approved guarantees.

The smallest next milestone is finite: owner disposition of D2A-01 plus a working signed Keychain qualification environment, followed by the already-defined catalog/key/lock/backup gates. Independent WebKit observations can be retained without restarting Phase3 or repeating unchanged provider/permission loops.
''')
print('Prepared ten supporting WS-F2 reports plus release backlog/decision handoff; closeout/results/traceability generated from final evidence separately')
