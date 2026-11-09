# WS-F1 qualification plan

2026-11-09. Version1, implementation-specific. Scenarios below are implemented proposals until a matching result artifact records execution. [Results](m1-wsf1-qualification-results.md) govern outcomes. Historical WKS/EXP/PQR definitions and WS-F0 evidence are unchanged.

## Host, fixtures and execution

The actual AppKit target links the adapter; Debug's explicit qualification branch has no regular host window or user-profile fallback. The parent `apps/browser-macos/Tools/wsf1_native.py` serves hashed `storage.html` and `sw.js` on127.0.0.1 at one owned port across child restarts. Profile/store/namespace UUIDs are generated and registered before use; markers A/B/PRIVATE are public synthetic data. No external site/account, selected user file, Keychain or SQLCipher fixture participates. The historical diagnostic uses only its exact old bundle identity and filters two original IDs; it never resolves or removes those stores.

Nx targets on `browser-macos`: `storage-models`, `storage-build`, `storage-diagnostic-build`, `storage-native`. Existing `webkit-storage-wsf0:verify` remains fake-only. Every invocation requires a new registered evidence directory with baseline.json; `--evidence` points there. Native execution additionally takes exact `--build-record` and `--diagnostic-record` result paths. Records identify temporary bundles and binary SHA256; re-create them by the build targets after temporary build output expires. No cached native pass is accepted.

Use the installed workspace Nx launcher (`pnpm nx` where functioning; the recorded host required local `node node_modules/nx/dist/bin/nx.js`) with `NX_DAEMON=false NX_NO_CLOUD=true NX_ISOLATE_PLUGINS=false` and owned temporary cache/data paths. SwiftPM credential discovery is disabled for contract tests; its manifest sandbox stays enabled. Do not disable App Sandbox, Hardened Runtime or Gatekeeper. No CI job exists that silently turns a non26 host into qualification; the runner always requires separate case/platform review before an overall result.

## Scenario inventory and oracles

| IDs / route | Setup and assertions | Required evidence and failure disposition |
|---|---|---|
| F1-DIAG-001 | Cold exact original-namespace noncreating enumeration after supported public configuration initialization | Binary/source identity, before marker, callback result and filtered presence. Missing callback/crash is FAIL, not absence; no fresh fixture before gate |
| F1-MOD-001–008 | Versioned serialization, invalid vectors, private refusal, ordered transitions, every cutpoint and repeated reconciliation | Exact test names/output/hash. PASS_CONTRACT only |
| F1-GUARD-001–004 | Run/scope/revocation, unresolved construction, conflicting mappings, unpublished navigation | No store/view creation in these checks; PASS_CONTRACT only, not positive WebKit support |
| F1-FAKE-001 | Suspend fake close then request clear; suspend fake clear then request close | Both orderings return Busy without the opposing effect; PASS_FAKE_ONLY, not native concurrency proof |
| F1-NAT-REGISTER/IDEMPOTENT/EMPTY/SEED/ISOLATION | Two same-origin persistent profiles, distinct markers, cookie/localStorage/IndexedDB/CacheStorage positive controls, separate session/worker/HTTP observations | Per-class page results, mapping checkpoint, assignment/construction/publication trace. Missing positive control is INCONCLUSIVE; leakage/wrong/default store FAIL |
| F1-NAT-RESTART | Cleanly close/exit, launch a new app PID with identical persistent metadata and same origin | Stable identifier, new run/process, per-class values. sessionStorage is a new browsing context; HTTP cache response is compared separately; eviction is disclosed |
| F1-NAT-MULTIVIEW/MULTIWINDOW/SWITCH | Two views/windows, nonlast closure, A→B and B→A through Core switch | Native registry, exact owned surfaces and destination markers; no live-view rebinding or data clearing |
| F1-NAT-PRIVATE-* | Persistent/private separation, independent private stores, intentional same-session sharing, nonlast/last closure, fresh empty session | Positive controls for cookie/localStorage/IndexedDB; private decisions/state absent from persistent checkpoints. No forensic guarantee |
| private-active cutpoint | Terminate only the exact dedicated child while a private fixture is active; launch another actual app process | PID, last persistent-only checkpoint, signal, fresh-session positive/negative observations |
| F1-NAT-CLEAR-* | Verify source positive data, close/quiesce writers, clear selected localStorage, reconstruct view, verify selected absence and other classes retained | Callback plus record enumeration plus page oracle. Type/record/date variants beyond this native recipe remain separately required |
| F1-NAT-REMOVE-* | New process, noncreating resolve, quiesce/retire/no observed refs, pending intent, public remove, callback and identifier absence | Exact per-store trace, callback/error and tombstone. Error/timeout/crash is partial/unknown; no filesystem cleanup |
| cut-00–10 | creation-intent, persistent-factory, assignment, construction, publication, clear-request, clear-callback, retire, remove-request, remove-callback, enumeration during reconcile | One registered independent synthetic fixture per cutpoint. Host emits then SIGSTOPs itself; parent kills only that Popen child. Restart from last mirrored checkpoint; interrupted scopes fence, stable unaffected scopes resolve; repeat reconciliation without factories |

Service-worker qualification requires controlled-client interception of `/sw-probe` with the profile's cache marker, not registration alone. CacheStorage and HTTP cache are separate. The baseline does not qualify third-party partitions, exact origin record granularity, HTTP-only/SameSite matrices, modified-since semantics, native lock/key barriers, process-specific WebKit child killing or backup portability; keep those WKS routes blocked.

## Failure matrix, platform and stop gates

The machine-readable `failure-matrix.json` has all22 requested failure categories, initial state, injection, expected transition/fence, observable result, recovery and fake/native coverage. Public clear has no error parameter: deterministic API/partial/unknown failures are modeled, never misrepresented as injected native filesystem errors. Wrong-store/configuration failures must reject before effect. Do not edit engine files, fill disks or relax permissions to manufacture errors.

Native waits are15seconds; parent process budget120seconds, with bounded output/evidence. Crash/unexpected result stops the affected sequence, preserves resources/evidence, and prohibits unchanged automatic retry. New evidence-supported code remediation gets a separately hashed attempt. Uncertain cutpoint stores remain quarantined, not silently swept/reused. Successful removal is logical only.

Retirement also observes its weak-reference postcondition for at most15seconds;20-millisecond polling permits run-loop progress and never substitutes elapsed time for evidence. `--phase=private-only` performs a bounded nonpersistent-only run plus actual abrupt termination/relaunch, without reopening any removed persistent fixture. A fresh full run is permitted after a material correction and successful targeted validation; histories and counts remain separate.

Actual macOS26.0 and latest supported26.x require frozen app/source/runtime identities and the applicable WKS/platform matrix. A27.2 discovery host or26.0 build target never satisfies them. Developer ID, notarization, Gatekeeper, final sandbox/entitlement/updater/performance release checks remain mandatory independent Stage C gates. D2A-01/SQLCipher PQR remains unchanged and unexecuted.
