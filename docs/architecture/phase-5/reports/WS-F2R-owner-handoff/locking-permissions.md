# Profile locking and permissions

2026-11-09. Owner-review package against `timeline` commit `d90ef9b029568c650588ffbead99866ee1378710`. **WS-F2 remains INCOMPLETE. WS-F2R is proposed, not authorized.**

## Successfully qualified lock subsets

The final actual host exercised two views/windows in one profile and a separate concurrent profile. Recorded final observations for manual lock and lock during navigation both end `lockState=locked`, `repeatedLockState=locked`; the navigation case also reports `lockDuringNavigationState=locked`. Tests include `F2-LOCK-MULTIWINDOW`, `F2-LOCK-REAL-RESOURCES`, `F2-LOCK-NO-VIEWS`, `F2-LOCK-NAVIGATION-DENIED`, `F2-LOCK-DURING-NAVIGATION`, `F2-LOCK-REPEATED`, `F2-LOCK-OTHER-PROFILE` and `F2-LOCK-OTHER-CLEANUP`.

These cases establish the tested owned-view/navigation boundary, not complete engine-process suspension, WebKit cryptographic locking or forensic privacy. `F2-LOCK-NO-KEY-LEASE` observed an empty cache; **no real profile key had been acquired**. It cannot qualify revoking a loaded key.

Sources: [manual lock](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-114029856396/lock-result.json), [navigation lock](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-114029856396/lock-navigation-result.json), [original lock report](../M1/m1-wsf2-profile-locking.md).

## Locking implementation and remaining gates

| Requirement | Current evidence / implementation | Remaining work |
|---|---|---|
| State and authority ordering | Core fence → invalidate permission tickets/grants → revoke key lease → retire resources; Locked only on completed retirement/no lease; epoch checks across awaited work | Hostile interleavings across real key/provider operations and destructive work |
| Native retirement/fencing | Old view unavailable; old navigation denied; ordinary allow-acquisition cannot clear independent security fence; other profile survives | Full process/transfer/resource barrier and late native callback attribution |
| Loaded-key revocation | Revocation code invalidates contexts, advances epoch and retires cache | Successful Keychain acquisition followed by actual revocation/reuse rejection is BLOCKED; best-effort buffer clearing is not proof of total memory erasure |
| Unlock | Core state machine plus real LAContext authentication source exists | Production reconciliation always receives unavailable catalog/key/unknown engine and returns false; full unlock/key reacquisition not implemented/qualified |
| OS-triggered locks | Public sleep/session-resign observers and local inactivity timer; termination awaits lockAll | Actual sleep/session/inactivity behavior NOT_EXECUTED; reliable screen-lock signal route remains missing/unqualified; no private notification workaround |
| Interrupted lock | Actual child PID 53316 killed at observed lock fence; fresh PID 53323 reports default fenced/no factory | Metadata is a synthetic captured checkpoint, not protected disk state; `F2-LOCK-DURABLE-RECEIPT` remains BLOCKED |
| Concurrent operations | Outstanding navigation and another profile exercised | Downloads absent; clear/remove/crypto/provider/subscription/queued result interleavings incomplete |

The interrupted run's streamed checkpoint is forwarded into the restart input by the existing host; this is parent-mediated synthetic metadata. Preserve the distinction from native encrypted durable receipts. [Interruption result](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-114029856396/lock-interrupted-result.json), [restart input](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-114029856396/lock-restart-input.json), [restart result](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-114029856396/lock-restart-result.json).

An earlier repeated-lock test failed because its oracle required unchanged terminal state. Source permits RecoveryRequired→Locked only after references drain and the barrier passes. That failure remains preserved; later PASS does not rewrite it. WKS-017 remains BLOCKED and WKS-018 remains PASS_FAKE_ONLY.

Implementation references: [ProfileSecurityCoordinator.swift](../../../../../qualification/webkit-storage-f0/Sources/BrowserCore/ProfileSecurityCoordinator.swift) lines 15–59; [NativeProfileBarrier.swift](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeProfileBarrier.swift) lines 14–35; [NativeSecurityLifecycle.swift](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeSecurityLifecycle.swift) lines 12–28. The inactivity timer is process-local, defaults to 900 seconds and clamps at 30 seconds; this is code inspection, not a validated product lock policy/timing guarantee.

## Permissions: actual evidence and support matrix

`F2-CON-004` and `F2-CON-005` qualify Core policy contracts for new-request Ask, session Allow, Deny, OS independence, revocation, stale prompts and private nonpersistence. Persistent grants are refused while the catalog is unavailable. Native OS authorization and browser consent are independent. Coarse scope-wide revocation is implemented; final per-origin grant UX, durable expiry and active-stream revocation are not.

| Kind | Actual mapping / current boundary | Qualification status |
|---|---|---|
| Camera | WK media delegate with Core mediator, owned-view/frame/origin checks | Positive Ask/Allow disabled; native camera-specific positive/negative matrix NOT_EXECUTED |
| Microphone | Same path; actual synthetic request attempted | `F2-PERM-NATIVE-DENIAL` FAIL: `script-error`; no recorded terminal permission trace |
| Combined camera/microphone | Native type mapping and combined OS-status evaluation source | NOT_EXECUTED; both device purposes/entitlements/consent and revocation must be verified before enabling |
| Geolocation | Public macOS27-only denial callback, availability-guarded | `F2-PERM-GEOLOCATION-DENIAL` INCONCLUSIVE: `timeout`, no geolocation trace; no positive or macOS26 callback claim |
| Website notifications | Distinct from native application notifications | Unsupported positive route; per-platform/direct-engine behavior unqualified |
| Display capture | No positively qualified selection/capture route | Unsupported; direct-engine/user-gesture/denial behavior unqualified |
| Clipboard read / clipboard write | Core unsupported requests deny; no generic native bridge | Direct-engine and user-gesture controls unqualified; policy Deny is not universal engine denial proof |
| File read / file write | Upload panel returns nil; transfer/file-token broker absent | No positive support; full native transfer matrix not run |
| MIDI | No qualified native mapping | Unsupported, no positive support |
| Unknown | Core denial-only | Policy contract passes; no invented affirmative case |

The app has no camera/microphone purpose strings or media entitlements; the mediator requires native authorization/readiness before advertising support. The existing Ask sheet lacks origin-specific presentation and is disabled/unqualified. Positive device activation must not be enabled just to make a test pass.

The latest [permission record](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-webkit-native-114029856396/permission-result.json) contains `result=script-error`, `delegateObserved=no`, `geolocationResult=timeout`, `geolocationDelegateObserved=no`. The media trace is emitted after awaiting mediation; early guard denial or an unfinished request can leave it absent. Do not equate this with proof that the OS never invoked any callback. See [native-failure-analysis.md](native-failure-analysis.md).

## Finite development qualification proposed

Preserve blocked positive routes. First add privacy-safe availability/error and callback-entry/decision diagnostics in a separately authorized task. Distinguish OS pre-denial, Core policy denial, missing API, harness error and timeout. Geolocation needs error-code attribution, not a generic error callback labeled denied. A native policy denial needs verified delegate path plus terminal denial and no active stream; a platform pre-denial is a separate result. Positive Ask/Allow and revocation need a qualified test configuration and explicit device consent. Validate public OS lock signals and loaded-key behavior only as their prerequisites become available. No tests or changes to these components occurred for this handoff.
