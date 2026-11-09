# WS-F2 qualification plan

2026-11-09. WS-F2 implementation/qualification review. [Closeout](m1-wsf2-closeout.md) · [Actual results](m1-wsf2-qualification-results.md) · [Evidence](../../evidence/20261109T105707Z-webkit-storage-wsf2/README.md). **No release approval.**

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
| F2-PERM-* | Actual loopback getUserMedia and27-only geolocation rejection; record delegate versus pre-denial. Any unexpected stream stops immediately and fails. Positive grant/Ask/TCC behavior remains separately blocked |
| Original native WSF1 recipes | Persistent/private class behavior, isolation/switch, clear/remove, publication failure and11 exact lifecycle cutpoints with actual child restarts |

PASS_NATIVE is always bounded by exact class/fixture/platform/oracle; policy/admission/fake cases retain PASS_CONTRACT/PASS_FAKE_ONLY. BLOCKED, NOT_EXECUTED, FAIL and INCONCLUSIVE are distinct. Do not aggregate different revisions or fake/native totals. A runner can exit0 while reporting blocked dependent cases; that is not a milestone PASS.

## Failure and fixture safety

Each child is Popen-owned with exact input/PID/binary; only that child can be killed. Parent budget100seconds for F2, inherited120seconds for F1. Selected self-stop cutpoints use SIGSTOP followed by parent SIGKILL and actual relaunch. Native callbacks keep their existing15-second budgets. Unexpected failures stop that dependent sequence and preserve evidence/resources; a material correction receives a new hashed attempt. No broad process kill, OS permission reset, security relaxation, user data, engine database/path manipulation or real disk-fill corruption is used.

Follow the gate/failure ledger for blocked actual catalog transactions, key creation/recovery, native positive grants, durable lock receipts, archive process recovery and true native error/drop-callback tests. macOS26.0/latest26.x are deliberately not executed for this milestone; see the dedicated release backlog. No public distribution is authorized by that scheduling change.
