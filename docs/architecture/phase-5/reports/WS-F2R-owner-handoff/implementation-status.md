# WS-F2 implementation status

2026-11-09. Owner-review package against `timeline` commit `d90ef9b029568c650588ffbead99866ee1378710`. **WS-F2 remains INCOMPLETE. WS-F2R is proposed, not authorized.**

## Status definitions

**Implemented** means source exists and is connected for its stated bounded purpose. **Partially implemented** means only part of the required feature exists. **Not implemented** means the required execution/workflow is absent. **External prerequisite** identifies owner/environment access rather than completed implementation. **Implemented but not qualified** means source is present without sufficient native evidence. Multiple labels can apply to one area. A passing refusal check does not establish a working positive feature.

## Component inventory

| Area | Actual status | Implemented / demonstrated | Missing or blocked |
|---|---|---|---|
| WebKit runtime | Implemented bounded adapter; partially qualified | Explicit named/nonpersistent store assignment before construction; immutable ownership, fences, clear/remove and original lifecycle regression; manual lock retirement | Full class/origin/partition/error/timing matrix, engine-process-specific faults and complete OS/key barrier |
| HTTP cache | Investigation implemented; disk persistence inconclusive | Same live store and reconstructed view reuse; A/B distinct responses; fresh retrieval after clean/abrupt process restart and selected/full clearing | Durable disk behavior and conditional revalidation not qualified |
| Protected catalog / SQLCipher | Refusal gate implemented; database execution not implemented; owner-blocked | `ProtectedCatalog` returns typed unavailable outcomes; schema v2/migration planning and publication guards | Actual open/create/reopen, transactions, migrations, corruption/rollback, durable receipts/tombstones; D2A-01 plus provider qualification prerequisites |
| Keychain lifecycle | Real adapter partially implemented; environment-blocked | Exact item identity, CSPRNG, userPresence ACL, real missing/create/acquire/delete attempts, opaque leases/cache retirement | Successful create/read/restart/duplicate, loaded-key revocation, KEK/DEK envelope, rotation, independent recovery/custody |
| Lock/unlock | Partially implemented; bounded native lock qualification | Core epoch/state policy; native view/navigation fencing; multiwindow and unaffected other profile; lock-fence process death/restart | Actual loaded-key barrier, production unlock, protected receipts, full OS triggers and concurrent operations |
| Permissions | Core policy implemented; native positive path unqualified | Typed Ask/Allow/Deny, OS independence, bounded session grants/tickets, stale/private/revoke contracts; native guards | Latest denial oracle FAIL, geolocation INCONCLUSIVE; usable origin-specific prompt/OS flow, active streams, per-kind matrix, persistent grants |
| Backup/restore | Synthetic native slice implemented and qualified; product integration absent | Bounded owned records, strict CBOR, AES-GCM/HKDF, no-overwrite stage/publication, authentication/deletion controls | Protected source snapshot/import, category repositories, durable recovery custody, migrations, independent-process/Mac restore and optional external-file selection |
| Unified recovery | Pure policy and existing engine reconciliation implemented; integrated persistent recovery blocked | Missing/corrupt/denied/mismatched/uncertain inputs deny admission; actual engine process restarts with synthetic metadata | Real catalog/key/backup state reconciliation and durable lock/grant/delete outcomes |
| Qualification infrastructure | Implemented | Retained 82 fake cases; typed contract suite; exact-binary native hosts, unique fixtures, bounded owned children, structured evidence | Permission diagnostics lose cause; some summaries say PASS_NATIVE despite embedded BLOCKED items; no whole-engine acceptance follows |

## Major source paths

All paths below are repository-relative. The shared target placement remains under the existing qualification package; this is not a completed, independently released Browser Core product package.

- `qualification/webkit-storage-f0/Sources/BrowserDomain/SecurityModels.swift`: lock, key-lease, validated origin/permission, record and deletion values.
- `qualification/webkit-storage-f0/Sources/BrowserPorts/SecurityPorts.swift`: key revocation, resource barrier and authentication contracts.
- `qualification/webkit-storage-f0/Sources/BrowserCore/{ProfileSecurityCoordinator,PermissionCoordinator,StorageRecoveryPolicy}.swift`: policy/state/epoch coordination; no AppKit/WebKit/SQLCipher types in these new boundaries.
- `qualification/webkit-storage-f0/Sources/BrowserPersistence/{ProtectedCatalog,OwnedBackupPolicy}.swift`: unavailable catalog integration gate, schema plans, publication and restore policies.
- `apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/{NativeStorageSession,NativeWebKitStorage}.swift`: real native composition, view/store ownership and security fences.
- The same native directory's `NativeKeychain.swift`, `NativeProfileBarrier.swift`, `NativeSecurityLifecycle.swift`, `NativePermissionMediator.swift`: Security/LAContext and host-side policy execution.
- The same directory's `CanonicalCBOR.swift`, `EncryptedOwnedBackup.swift`: provisional owned-data archive/crypto/native file slice.
- `apps/browser-macos/Sources/Host/{ApplicationDelegate,MainWindowController}.swift`: protected bootstrap, awaited shutdown and truthful unavailable UI. Normal bootstrap creates no implicit profile/store/key.
- `apps/browser-macos/Sources/Qualification/SecurityQualificationHost.swift`: Debug qualification on synthetic metadata and real native APIs. Existing `StorageQualificationHost.swift` remains preserved.
- `apps/browser-macos/StorageRuntime/Tests/StorageModelTests/{SecurityContractTests,BackupContractTests}.swift`: new checks, alongside preserved original model/fake tests.
- `apps/browser-macos/Tools/{wsf2,wsf2_native}.py`, existing `wsf1.py`, `project.json`, and `VezhamBrowser.xcodeproj/project.pbxproj`: bounded orchestration and four uncached F2 targets. This report ran none of them.

The exact 46 authored paths/hashes are in [changed-files.json](../../evidence/20261109T105707Z-webkit-storage-wsf2/changed-files.json); complete current implementation hashes are in [implementation-manifest.json](../../evidence/20261109T105707Z-webkit-storage-wsf2/sources/implementation-manifest.json). Fourteen WS-F2 reports and minimal app/runtime/M1-index/security-document updates accompany the implementation. Dependencies, entitlement files, deployment target, provider pin and historical evidence were not changed by WS-F2.

## Cache result detail

The controlled loopback path used a unique fixture ID, cacheable responses and ETags. The final observations include A `cache-1/cache-1`, B `cache-2/cache-2`, clean restart `cache-3`, reconstruction `cache-4/cache-4`, abrupt-run/restart `cache-5` then `cache-6`, selected clear `cache-7`→`cache-8`, full clear `cache-9`→`cache-10`. No conditional ETag revalidation was observed. Callback-confirmed normal removal plus noncreating identifier absence establishes logical removal only. [Cache analysis and server requests](../../evidence/20261109T105707Z-webkit-storage-wsf2/results/cache-analysis.json).

## Dependencies that remain open

D2A-01 is the owner prerequisite for the affected catalog path; it is not the only provider-safety prerequisite. Real VFS/worker/authentication/artifact contracts still need implementation and qualification. A development-signed, correctly provisioned Keychain host can address successful key cases independently of Developer ID release signing. Native permission diagnosis, supported OS lock signals and synthetic backup improvements are development work. Protected catalog transactions, durable grants/keys and coherent production backup require their actual dependencies; source skeletons or memory checkpoints cannot substitute.

Current policy remains the [owner register](../M1/m1-owner-decision-register.md) and [developer specification v1.2](../M1/m1-developer-specification.md). OP-01–OP-04 are owner-decided; exact engineering schemas/lifecycles remain unfinished. No full browser UX, downloads engine, production chrome, cloud or Tamizhi capability was added. See the [original closeout](../M1/m1-wsf2-closeout.md) and [gate ledger](../../evidence/20261109T105707Z-webkit-storage-wsf2/acceptance-gates.json).
