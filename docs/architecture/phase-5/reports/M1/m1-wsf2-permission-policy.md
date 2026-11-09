# WS-F2 permission policy

2026-11-09. WS-F2 implementation/qualification review. [Closeout](m1-wsf2-closeout.md) · [Actual results](m1-wsf2-qualification-results.md) · [Evidence](../../evidence/20261109T105707Z-webkit-storage-wsf2/README.md). **No release approval.**

## Core and native path

`PermissionCoordinator` owns verified-origin/capability/profile policy, bounded pending tickets and session grants. Requests require a current native host context/run/view generation. Supported, safely mediated new requests return Ask; unsupported, ambiguous, denied/unavailable OS authorization or stale/locked scope returns Deny. Tickets bind scope/epoch and are consumed once. OS authorization never substitutes for browser consent, nor browser Allow for OS access.

The native media delegate verifies owned published WKWebView, current generation/fence, main frame, top-level scheme/host/port and requesting WKSecurityOrigin before constructing a Core request. Ask has a native Allow Once/Don’t Allow sheet on the owned window; it rechecks current state afterward. No media entitlement/purpose string is introduced, so this positive path is not enabled or claimed qualified. Implemented popup, file-picker and authentication delegates remain fail closed; unmediated engine capability families require their explicit support/denial matrix before product browsing is enabled. Logs contain coarse outcome only, no origin/URL/token/content.

## Actual support matrix

| Permission kind | Public mapping / OS dependency | Current product/native status |
|---|---|---|
| Camera, microphone, combined | WKUIDelegate media callback; separate AVCapture/TCC status | Denial path integrated; positive Ask/Allow BLOCKED pending purpose/entitlement/OS and active-stream revocation qualification |
| Geolocation | Public WKUIDelegate denial callback is macOS27-only, availability-guarded |27.2 denial fixture; no affirmative support or26 callback availability claim |
| Website notifications | Distinct from native notifications | Unsupported; no automatic notification grant |
| Display capture | Requires separately validated API/user selection | No supported positive route; complete direct-engine denial/user-gesture behavior remains unqualified |
| Clipboard read/write | Separate origin/user-action contracts | Core denies unsupported requests; direct-engine/user-gesture matrix unqualified; no generic native bridge |
| File read/write | Existing chooser/transfer brokers not implemented | Upload panel refused; no native file token/grant |
| MIDI | No positively qualified public native mapping | Unsupported/fail closed |
| Unknown | No safe mapping | Deny-only |

Native qualification requests synthetic loopback microphone access with no media entitlement; any unexpected stream is immediately stopped and fails the case. The result distinguishes actual delegate observation from platform pre-denial; a page-level rejection alone does not qualify browser prompt mediation. Positive allow, native Ask UI and active stream revocation are NOT_EXECUTED/BLOCKED. Contract tests exercise Ask/Allow/Deny, native-status independence, one-time/session decisions, revocation, stale prompts, private sessions and unsupported kinds without claiming native positive support.

## Persistence and revocation

Persistent grants are refused while the protected catalog is blocked; private decisions never write a persistent adapter. Intended protected fields are profile, verified origin, kind, decision/lifetime, creation/update and revocation/expiry metadata; no OS secrets. Session grants are memory-only and vanish on process restart. Lock/session end/profile deletion must invalidate them before new admission. Revocation currently conservatively invalidates the scope's pending decisions and session grants; final per-grant inspection/revocation UX and durable expiry require specification/integration.

This preserves the owner's eventual Ask policy without advertising unverified kinds. Gate E is partial: real delegate denial is integrated, while durable grants, native positive routes, stream/device revocation and full supported-kind matrix remain mandatory gaps.

The current Ask sheet is disabled by the platform-readiness gate and remains unqualified; origin-specific prompt presentation, OS-consent flow and cancellation/active-stream lifecycle must be completed and tested before enabling positive support. The latest native probe failed its media denial oracle (`script-error`, no delegate observed) and geolocation was INCONCLUSIVE (`timeout`, no delegate observed); do not call those outcomes verified denial.
