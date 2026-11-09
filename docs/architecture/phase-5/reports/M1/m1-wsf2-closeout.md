# WS-F2 storage/security closeout

2026-11-09. **WS-F2 INCOMPLETE — Required implementation or safety gates remain unmet.** Independent runtime/security components were implemented and tested, but the protected catalog, successful Keychain lifecycle, full unlock/permission and production backup/recovery gates are not complete. No overall security, engine or release PASS is issued.

Starting branch `timeline`, clean HEAD `21ad0b0ca91ed0777e873fd8233290e4f12f2e96`, matching the owner baseline. Final implementation commit is the commit containing this report; exact SHA and postcommit working-tree state are supplied in the handoff (`git log -1 --format=%H -- docs/architecture/phase-5/reports/M1/m1-wsf2-closeout.md` avoids a self-referential embedded hash). Local commit only; no push/branch switch/destructive reset.

[WebKit hardening](m1-wsf2-webkit-runtime-hardening.md) · [Protected catalog](m1-wsf2-protected-catalog.md) · [Keychain](m1-wsf2-keychain-integration.md) · [Locking](m1-wsf2-profile-locking.md) · [Permissions](m1-wsf2-permission-policy.md) · [Backup/restore](m1-wsf2-backup-and-restore.md) · [Recovery](m1-wsf2-recovery-and-reconciliation.md) · [Plan](m1-wsf2-qualification-plan.md) · [Actual results](m1-wsf2-qualification-results.md) · [WKS](m1-wsf2-wks-traceability.md) · [Risks](m1-wsf2-risks-and-limitations.md) · [Decision handoff](m1-wsf2-security-decision-proposal.md) · [Release backlog](m1-wsf2-public-release-qualification-backlog.md).

## Implemented components and actual boundaries

The existing AppKit app consumes the same native storage module/Core/Ports. Normal startup now wires the explicit protected-catalog gate, real Keychain broker, Core lock/permission/recovery policy and public AppKit lifecycle hooks; it automatically creates no profile, website store/view or key. Production persistent access stays unavailable. Debug qualification uses synthetic memory metadata and actual WebKit/Security/CryptoKit/files, never user data or a replacement plaintext product database.

| Path | Actual change |
|---|---|
| `qualification/webkit-storage-f0/Sources/BrowserDomain/SecurityModels.swift` | Opaque lease, validated origin/request/ticket, lock/grant/category/deletion values |
| `.../BrowserPorts/SecurityPorts.swift` | Typed engine-independent key/barrier/auth contracts; no native secret/object/connection |
| `.../BrowserCore/PermissionCoordinator.swift` | Ask/Allow/Deny, bounded session grants/tickets, authority/epoch/revocation/private checks; persistent grants refused |
| `.../BrowserCore/ProfileSecurityCoordinator.swift` | Lock/unlock policy/epochs, key retirement, resource barrier, safe initial/repeated/concurrent outcomes |
| `.../BrowserCore/StorageRecoveryPolicy.swift` | Cross-component fail-closed eligibility; no automatic unlock/publication |
| `.../BrowserPersistence/ProtectedCatalog.swift` | Actual catalog-port integration gate plus schema/migration/transaction-publication planning; no DB executor/open under D2A-01 |
| `.../BrowserPersistence/OwnedBackupPolicy.swift` | Bounded persistent snapshot/selection and deletion-aware fresh-destination validation |
| `apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeKeychain.swift` | Real Security/LAContext/CSPRNG, exact ACL/item identity, opaque cache/revocation and coarse statuses; successful item access blocked |
| `.../NativeProfileBarrier.swift`, `NativeSecurityLifecycle.swift` | Actual Core/native retirement, public sleep/session/inactivity hooks, awaited app termination; full OS/loaded-key matrix unqualified |
| `.../NativePermissionMediator.swift` | Owned native media request→Core policy→bounded-origin/frame/current-state checks; positive routes disabled pending platform qualification |
| `.../CanonicalCBOR.swift`, `EncryptedOwnedBackup.swift` | Actual strict framing, AES-GCM/HKDF and native no-overwrite/incomplete-stage file slice; synthetic records only |
| `.../NativeStorageSession.swift`, `NativeWebKitStorage.swift` | Connect services, protected bootstrap, security fences/publication rechecks, public27-only geolocation denial guarded for26.0 target |
| `apps/browser-macos/Sources/Host/ApplicationDelegate.swift`, `MainWindowController.swift` | Compose gates/lifecycle, Debug-only F2 host and truthful protected-storage-unavailable window |
| `apps/browser-macos/Sources/Qualification/SecurityQualificationHost.swift` | Real app synthetic Keychain/backup/cache/lock/permission cases, bounded scripts and owned termination |
| `apps/browser-macos/StorageRuntime/Tests/StorageModelTests/SecurityContractTests.swift`, `BackupContractTests.swift` | New Core/catalog/recovery/framing/backup/fake tests; original cases preserved |
| `apps/browser-macos/Tools/wsf2.py`, `wsf2_native.py` | Reproducible bounded build/test/native orchestration/evidence; no provider path |
| `apps/browser-macos/Tools/wsf1.py` | Preserve old target while recognizing new F2 contract/fake labels separately |
| `apps/browser-macos/project.json`, `VezhamBrowser.xcodeproj/project.pbxproj` | Four uncached F2 targets and Debug source integration; no external dependency or entitlement change |
| App/runtime READMEs; M1 indexes | Current scoped usage and report links, historical narratives preserved |

Ellipses retain the preceding package source prefix. Complete exact paths/hashes are in changed-files/implementation manifests. Source pins, vendor verification, ADR/owner/OP policies, original Core lifecycle/fake providers/tests, Phase3 and all historical evidence remain preserved.

## Actual verification and acceptance gates

Primary platform: macOS27.2/26B123 arm64, Swift6.4.2/SDK27.2, WebKit22625.2.8.11.9. The final qualification host compiles at26.0 minimum with App Sandbox/Hardened Runtime retained; ad-hoc signature is not release or Keychain qualification.

Separate outcomes: retained full native regression475 PASS_NATIVE/2 HTTP-cache INCONCLUSIVE; new WebKit/cache/lock36 PASS_NATIVE/4 BLOCKED/1 INCONCLUSIVE/1 FAIL; native Keychain/backup16 PASS_NATIVE/2 PASS_CONTRACT/6 BLOCKED; contract suite23 PASS_CONTRACT+2 PASS_FAKE_ONLY; original fake suite82 PASS_FAKE_ONLY. Each suite has its own binary/source identity; the result report explains test-host-only changes and reconciles shared implementation hashes. No totals are combined across categories/revisions.

| Gate | Disposition and exact remaining work |
|---|---|
| A WebKit runtime | BLOCKED — Cache behavior, original full regression, selected/full clear, normal removal and bounded lock resources tested. Full native origin-record/date/in-flight/error matrix incomplete. |
| B Protected persistence | BLOCKED — D2A-01 blocks actual protected catalog open/transactions/migrations/recovery; schema/gates tested only. |
| C Keychain | BLOCKED — Real adapter attempts return-34018;0 valid signing identities. No successful item/ACL read/restart/rotation/recovery qualification. |
| D Profile security | BLOCKED — Native views fenced/retired; protected key/unlock/durable receipts and full OS trigger/transfer/concurrency guarantees incomplete. |
| E Permissions | BLOCKED — Core policy tests pass; native media denial oracle FAIL/script-error, geolocation INCONCLUSIVE/timeout; positives and persistent grants blocked. |
| F Backup/restore | BLOCKED — Actual CryptoKit/synthetic-file slice passes; real protected source/import, full categories/custody/migrations/process recovery incomplete. |
| G Regression/unified recovery | BLOCKED — 82 retained fake tests and full WSF1 native regression pass their scopes; cross-component actual persisted/key/backup recovery remains blocked. |
| H Closeout | PASS_CONTRACT — Required reports, evidence, traceability and preservation prepared; final commit/worktree receipt supplied by handoff after local commit. Not a runtime/security PASS. |

## Remaining decisions and next milestone

1. Obtain an explicit D2A-01 owner disposition using the existing exact alternatives. No header/read/hash/copy/VFS exception or provider replacement is implied. Then qualify the pinned worker/VFS/authentication path before enabling catalog execution.
2. Provide a valid authorized signing/default-Keychain-group environment; rerun finite synthetic userPresence item cases. Do not weaken ACLs or introduce another key store.
3. Complete protected key/custody/catalog migrations, durable lock/grants and actual backup snapshot/import/recovery. The synthetic archive slice is not a user-ready backup feature.
4. Resolve the native media pre-delegate script failure and geolocation timeout with a finite API-availability/origin/frame probe before claiming support. Keep positive permission capability disabled; do not repeat unchanged prompts.
5. Follow the dedicated release backlog for actual26.0/latest26.x and all final signing/notarization/Gatekeeper/sandbox/updater/performance gates. Their deliberate deferral is not a WS-F2 implementation failure or public-distribution approval.

The missing catalog/provider, Keychain entitlement and full security/product workflows are why WS-F2 is INCOMPLETE. Core/native module boundaries are not security sandboxes. No complete browser readiness, secure erasure, per-profile WebKit encryption/cryptographic lock, full portable website backup, OS-wide private forensic cleanup or unconditional engine acceptance is claimed.

ADR0001 remains Proposed; WKWebView conditional; CEF evaluation-only. Aura, production Tamizhi, mandatory identity/cloud/local service and public distribution remain excluded. No keys/test secrets, provider runtime, browser database or personal data enter evidence. Product-owner review remains required before further implementation/release scope.
