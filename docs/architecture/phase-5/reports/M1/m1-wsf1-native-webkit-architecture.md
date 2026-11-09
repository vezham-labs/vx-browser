# WS-F1 native WebKit storage architecture

2026-11-09. Implementation review; qualification is reported separately in [results](m1-wsf1-qualification-results.md). WKWebView remains conditional and ADR0001 Proposed. This is neither release readiness nor a new owner policy.

## Composition and ownership

The existing `apps/browser-macos/VezhamBrowser.xcodeproj` consumes the local `StorageRuntime` Swift package's `BrowserNativeStorage` product. `ApplicationDelegate` retains `NativeStorageSession`; the Debug-only explicit `--wsf1-qualification` branch uses the same session/adapter/Core implementation. There is no separate substitute engine implementation. Normal startup constructs only a memory-backed composition; it does not create a website store/view or offer persistent-profile operation without an approved durable catalog. The normal window remains the M0 foundation surface.

`qualification/webkit-storage-f0` remains the physical location of the established Domain, Ports, Core and in-memory Persistence targets. Additional individual library products expose those exact targets; no contracts are copied. Native application linkage does not include `WSF0Fakes`. This location is transitional, not a fifth engine-dependent Core target or a decision to put product policy in a test harness.

| Component | Implemented authority / boundary |
|---|---|
| BrowserDomain | Validated tagged IDs, engine-independent descriptor and reconciliation values; no WK/AppKit types |
| BrowserPorts | Existing catalog, journal, engine, construction, resource and host-authority protocols; unchanged |
| BrowserCore | Existing actor lifecycle coordinator and safety policy; unchanged source |
| BrowserPersistence | Existing in-memory catalog/journal for qualification/private-only composition; no new durable backend |
| NativeHostAuthority | Host-minted, run/scope-bound grants with explicit revocation; IDs alone grant nothing |
| NativeStorageSession | Connects all ports; confirms Core activation/switch before native publication; persistent publication has its own pending journal fence |
| NativeWebKitStorage | Main-actor native stores/configurations/views, assignment, navigation, weak-reference observations and API callbacks |
| WebKit | Website storage formats, paths, subprocesses, retention and implementation; never SQLCipher-wrapped |

Same-process modules are not security sandboxes. Future React/TypeScript/HeroUI v3 chrome receives no native object, script evaluator or store selector. Website content gets no privileged message handler. Qualification-only script execution is compiled behind `WSF1_QUALIFICATION` in the Debug app source, restricted to registered loopback fixtures; it is not a chrome bridge.

## Resolution, construction and publication

Persistent provisioning follows Core's recorded fresh binding/pending access intent, noncreating identifier observation, explicit named public factory, native registration, fresh configuration, explicit store assignment, copied-view-configuration verification and unpublished construction. Established mappings use identifier enumeration before the creating factory; absence fails closed. Enumeration and factory resolution are not an atomic transaction against external processes. No `.default()` factory/getter warmup or coder initialization is used.

Each independent private session receives `WKWebsiteDataStore.nonPersistent()`; views within its intended session reuse that object. Independent sessions use distinct objects. The catalog/journal never receives a private scope. Private descriptor encoding is rejected even through generic `Codable`.

Construction returns an unpublished resource. Core completes activation; `NativeStorageSession` records pending publication, publishes the matching scope/generation, then finalizes its journal checkpoint. A publication failure fences Core. Navigation requires published ownership, current native fence and an explicitly allowed origin; the qualification allowlist contains one loopback origin. Default normal-host allowlist is empty. Popups, upload panels, unsupported downloads/responses, authentication challenges, media grants and script dialogs fail closed pending their separately scoped brokers. This is not a supported-permissions or file-transfer implementation.

## Lifecycle and callbacks

One main-actor registry owns strong store/configuration/view references, pending storage operations, navigation continuations and weak observations of released objects. Core sees opaque resource references. Closing a view cancels its navigation, detaches delegates and superview, then drops owned references. Quiescence refuses observed resources; retirement drops the store and checks weak observations. Observed deallocation is stronger than assigning nil, but does not prove all internal engine processes/background work have stopped. Held external native owners remain a release blocker.

Fencing rejects construction/navigation/publication. Content-process termination installs a sticky native poison fence; admission cannot clear it automatically. No automatic reload or action replay is introduced. Complete lock/key revocation and whole engine barrier remain unqualified.

Public API waits have15-second terminal budgets. Timeout is Unknown, never completion. A clear-operation reference spans callback and record verification; incomplete callbacks retain conservative ownership. Core's generation and pending-operation checks reject stale results. Scope receipts remain bounded128 and diagnostics4096; there is no unlimited exactly-once claim.

Retirement has a15-second observed-release budget, with20-millisecond observation cadence to permit main-run-loop work. Time alone never establishes release. Private last-owner retirement explicitly clears the supported categories, observes the callback/record postcondition, then drops owned references and waits for weak observations. Earlier immediate/2-second failures remain historical. This budget is an engineering choice, not a release performance pass. Full hostile native grant/publication/callback interleavings and the production lock barrier still require qualification; no cross-actor transaction guarantee is claimed.

Clearing and removal are separate ports. Clear uses an explicit type map, public callback and public selected-record re-enumeration; residual records are Partial, timeout Unknown. Per-category page-visible postconditions still require native qualification. Whole-store removal requires retired/no-owned-resource state, callback without error and noncreating absence observation. Error is Partial because side effects may already exist; missing callback/absence alone is not success. Catalog tombstones are Core-owned. No engine filesystem manipulation or secure-erasure claim exists.

## API and security evidence classes

**Documented:** [Apple WebKit storage API](https://developer.apple.com/documentation/webkit/wkwebsitedatastore) and [WebKit profile guide](https://webkit.org/blog/14423/building-profiles-with-new-webkit-api/). Named stores/enumeration/removal are declared from macOS14; all selected runtime APIs are available by deployment26.0. Installed SDK27.2 headers and Mach-O minimums are static evidence only.

**Source-verified, not shipping-binary correspondence:** pinned upstream `75dff6dba87fafb94367ddb5bb155a110963ba80` shows lazy default-store getters and `API::Object` initialization. The cold-enumeration remediation initializes a public `WKWebViewConfiguration` without reading its store or constructing a view; no private initialization function is called. The initial crash and subsequent outcome are separately retained in the results, rather than asserted fixed from source alone.

**Design/implementation intent:** scope isolation, safe retirement, publication sequencing and truthful cleanup. **Runtime qualification required:** actual website class behavior, process release, callback/error/timeout effects, minimum OS, lock barriers and crash persistence.

App Sandbox and Hardened Runtime remain enabled. The app gains only outbound `network.client` entitlement for controlled native browsing; no server, camera, microphone, file-access or sandbox bypass entitlement is added. Ad-hoc static verification is not Developer ID, notarization or Gatekeeper/release validation. SQLCipher/D2A-01 remains unchanged and applies only to Vezham-owned persistence. No production Keychain operation or replacement key scheme is introduced.
