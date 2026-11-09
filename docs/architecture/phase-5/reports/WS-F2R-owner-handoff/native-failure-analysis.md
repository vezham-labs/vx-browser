# Native failure analysis

2026-11-09. Owner-review package against `timeline` commit `d90ef9b029568c650588ffbead99866ee1378710`. **WS-F2 remains INCOMPLETE. WS-F2R is proposed, not authorized.**

## Exact latest failure

| Field | Recorded value |
|---|---|
| Case | `F2-PERM-NATIVE-DENIAL` |
| Attempt / stage | `f2-webkit-native-114029856396` / `permission` |
| App PID / exit | 53324 / 0; no parent timeout or intentional kill |
| Binary | `d933ae466707edcdd39936cdcdddeceddfc5b17ae2fd746296d6b64ded938c9a` |
| Platform | macOS 27.2 build 26B123, WebKit 22625.2.8.11.9 |
| Output | `status=FAIL`, `result=script-error`, `delegateObserved=no` |
| Adjacent case | `F2-PERM-GEOLOCATION-DENIAL`: INCONCLUSIVE, `geolocationResult=timeout`, `geolocationDelegateObserved=no` |
| Positive case | `F2-PERM-POSITIVE-ASK-ALLOW`: BLOCKED |
| Cleanup | View/store retired in emitted synthetic checkpoint; subsequent `permission-cleanup` stage was not executed |

Source: [exact result](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-114029856396/permission-result.json), [input](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-114029856396/permission-input.json), [stdout](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-114029856396/permission.stdout), [stderr](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-114029856396/permission.stderr), [stopped-run blocker](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-114029856396/blocker.json). Stderr is empty. A normal process exit does not turn a failed case into a pass.

## What the code establishes

[SecurityQualificationHost.swift](../../../../../apps/browser-macos/Sources/Qualification/SecurityQualificationHost.swift) lines 217–229 requests loopback microphone access. The script expects `NotAllowedError` or `SecurityError`, times out its promise after three seconds and stops any unexpected stream. Lines 244–259 wrap `callAsyncJavaScript` in a five-second completion deadline. **Every native JavaScript completion error is replaced by the same literal `{"result":"script-error"}`**; error domain/code and safe exception classification are not retained.

Consequently the actual error could not be recovered from this record. API absence, secure-context/readiness, gesture/presentation restrictions, script failure, frame/lifecycle issues or native execution problems are hypotheses, not established causes. Missing purpose strings and media entitlements are verified configuration facts, but they do not establish which condition caused this script error.

The media `permission` trace is emitted only after awaiting the mediator, at [NativeWebKitStorage.swift](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeWebKitStorage.swift) lines 374–389. Early guard denial emits no such trace. Thus `delegateObserved=no` means **no matching completed mediation trace was recorded**, not proof that no native callback entered. The geolocation callback records its own trace at lines 391–393; that trace was absent too.

Two oracle limitations also require correction before a new native denial claim: the current media test can accept a page-level rejection without correlated Core/native denial; geolocation's generic error callback maps all errors to `denied`, without error-code attribution. These are source-established harness limitations. The underlying native request failure remains **unresolved between harness, platform/configuration and implementation**. No exploit, unauthorized capture or security bypass is demonstrated by the available failure record, and no complete fail-closed guarantee follows from it.

## Historical attempts and reproducibility

An earlier `permission` process in [f2-webkit-native-113245864607](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-113245864607/permission-result.json) hit the 100-second parent deadline and was killed (PID 51692, exit -9). It emitted no final cases. That run remains FAIL. It used production regression binary `17897e…`, while the latest instrumented host used `d933ae…`; it is not a second identical reproduction of the latest script error.

The exact final binary still exists and was hash-verified during this review. Inputs, host argv, native output and fixture source are retained. The original loopback origin was temporary; replaying its now-stopped URL is not a valid reproduction. **Deterministic repeatability and root cause have not been established.** No native run was executed for this report, and earlier FAIL/INCONCLUSIVE records remain unchanged.

## Smallest proposed next action, after WS-F2R authorization

1. Add a bounded, permission-only diagnostic route instead of rerunning cache/lock suites. Retain exact binary/source/platform identities and fresh registered synthetic fixture IDs.
2. Record only privacy-safe booleans/classifications for API presence, secure context, document/frame readiness, owned-view/generation/fence, callback entry, terminal decision and safe error domain/code. Do not log URLs, origins, exception messages containing content or device data.
3. Perform **one** instrumented noninteractive reproduction with finite script/parent deadlines. Distinguish platform pre-denial, Core denial, unavailable API, timeout and harness error. A timeout/error is never affirmative denial evidence.
4. Diagnose from the new evidence; make only an attributable scoped fix. Run **one** targeted verification after that fix. If cause remains unknown or the environment cannot reach the callback, stop with INCONCLUSIVE/BLOCKED and a concrete diagnostic handoff; no unchanged retry loop.
5. Require recorded native path plus terminal denial/no stream for the browser-policy denial case. A separate OS pre-denial result cannot satisfy that case. Attribute geolocation errors and correlate its native callback. Positive device/Ask/Allow/stream-revocation testing needs a separate qualified test configuration and explicit consent within the future authorized milestone.
6. Give exact owned-fixture cleanup its own outcome even when a test fails; preserve uncertain stores/receipts and never use a creating existence probe, broad sweep or forced deletion to manufacture cleanup success.

These are proposed changes and executions only. This reporting task authorizes none of them.
