# Browser Engine Feasibility: WebKit and Chromium/CEF

**Project:** Vezham Browser  
**Study date:** 2026-11-07  
**Status:** Maintained comparison with historical study findings; bounded Phase 3 evidence is separately retained  
**Decision posture:** WKWebView has CONDITIONAL ACCEPTANCE for MVP planning and implementation under the [owner decision](phase-3/owner-approval-decision.md); ADR 0001 remains Proposed. CEF is evaluation-only. Current execution is M0 native foundation, not unconditional production-engine/release approval. [Staged acceptance requirements](browser-mvp-acceptance-criteria.md) remain mandatory.

## Scope and evidence labels

This study evaluates Apple WebKit through `WKWebView` and Chromium through CEF or a lower-level Chromium integration for Vezham Browser: macOS 26 Tahoe and later, Swift/AppKit host, React/TypeScript with HeroUI v3, and an engine-independent product architecture. `@vezham/aura` is not ready and is not a dependency or implementation assumption. Initial distribution is internal-only. Accepted ADR 0002 sets direct internal distribution to Developer ID Application signing and notarized `.dmg` or `.pkg` artifacts, with MDM supported where available; exact installer, updater, and sandbox configuration remain open. See [distribution architecture](browser-distribution.md) and [ADR 0002](../decisions/0002-browser-distribution-and-platform.md).

- **Documented fact** means stated in the linked Apple, Chromium, or CEF documentation.
- **Arc observation** means established by the local static inspection in [the Arc report](../../arc-macos-architecture-report.md). It is architectural reference only; it does not establish that Vezham should copy Arc’s choices.
- **Recommendation/inference** is a product or engineering judgment based on those facts.

The original API comparison did not itself run or benchmark an engine. Later [Phase 3 results](phase-3/phase-3-exit-review.md) are separate, revision-scoped evidence and do not performance-qualify M0 or a future product. API availability, platform availability, and CEF release support must be checked against the exact SDK and engine version selected for implementation.

## Executive comparison

| Area                | WebKit with `WKWebView`                                                                                                                                                         | Chromium through CEF                                                                                                          | Custom Chromium integration                                                                |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Host fit            | Direct AppKit/Swift view; Apple API                                                                                                                                             | Native macOS host is possible, but CEF is a C/C++ API and needs an Objective-C++/Swift boundary                               | Full control, but host integration is owned by Vezham                                      |
| Engine distribution | WebKit is supplied by macOS; Vezham ships its app and uses the system framework                                                                                                 | Ships CEF/Chromium framework, helper apps, resources, and libraries                                                           | Ships a custom engine build and helper/process resources                                   |
| Web data profiles   | Persistent stores by UUID and in-memory store are documented                                                                                                                    | Request contexts and cache paths support distinct storage contexts                                                            | Vezham must design and maintain all profile plumbing                                       |
| Compatibility       | Safari/WebKit behavior; can differ from Chromium sites and extensions                                                                                                           | Chromium/Blink compatibility; closer to Chrome web behavior, but not identical to Chrome                                      | Chromium compatibility is possible; patches and deltas become Vezham’s responsibility      |
| Security boundary   | WebKit manages a separate web-content process; app-level controls and recovery remain Vezham’s job                                                                              | Chromium multiprocess model and sandbox are available, but macOS helper signing, entitlements, and sandbox setup are required | Highest security engineering and maintenance burden                                        |
| Extensions          | Safari Web Extensions are designed for Safari’s app-extension model. Public `WKWebView` docs do not establish a general Safari/Chrome extension host for arbitrary browser tabs | CEF has Alloy and Chrome runtime styles. APIs and extension behavior vary; Chrome-style UI support is not full Chrome parity  | Potentially broad, but requires implementing and keeping a browser extension stack working |
| Maintenance         | Engine security and feature updates arrive with macOS; Vezham tests OS releases and supports its minimum OS                                                                     | Vezham must adopt Chromium/CEF security releases, integrate, sign, notarize, package, and ship them                           | Vezham additionally owns low-level integration and likely patch maintenance                |
| MVP complexity      | Low to medium                                                                                                                                                                   | High                                                                                                                          | Very high                                                                                  |

**Recommendation:** Keep WebKit through `WKWebView` as the proposed initial engine candidate, subject to the acceptance gates in [the MVP criteria](browser-mvp-acceptance-criteria.md) and product-owner approval. This is not an accepted engine selection or implementation authorization. CEF remains a future alternative, not an active implementation. WebKit compatibility and browser-extension gaps may be unacceptable for Vezham’s target users.

## A. WebKit through WKWebView

### Lifecycle and native integration

**Documented facts:** `WKWebView` is a native view for AppKit and UIKit. A caller creates it with a `WKWebViewConfiguration`, installs navigation/UI delegates, and adds the view to the native hierarchy. The configuration captures behavior, user-content, and website-data settings at creation; Apple says configuration values are incorporated when the web view is created, rather than changed dynamically afterward. WebKit reports navigation start, commit, finish, failure, estimated progress, and content-process termination through its APIs. [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview/), [WKWebViewConfiguration](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration), [WKNavigationDelegate](https://developer.apple.com/documentation/webkit/wknavigationdelegate)

**Recommendation:** Let Swift own `WKWebView` creation, delegates, lifecycle, profile selection, and view attachment. TypeScript should issue typed commands to the native host and observe normalized events; it should not own a raw WebKit object or a privileged JavaScript bridge.

### Profiles, cookies, local storage, and sessions

**Documented facts:** `WKWebsiteDataStore.default()` is persistent; `nonPersistent()` creates an in-memory store that does not write website data to disk; and `init(forIdentifier:)` creates or returns a persistent store for an identifier. The store manages cookies, caches, and other website data. It exposes a cookie store, website data type enumeration, record fetch, and data removal. Configure the store on `WKWebViewConfiguration` before creating the view. [WKWebsiteDataStore](https://developer.apple.com/documentation/webkit/wkwebsitedatastore), [WKWebViewConfiguration.websiteDataStore](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/websitedatastore), [WKHTTPCookieStore](https://developer.apple.com/documentation/webkit/wkhttpcookiestore)

**Engineering limits:** Multiple data stores provide a public website-data isolation mechanism, but do not promise an independent process, OS account, or complete privacy boundary per Vezham profile. Keep app-owned history, bookmarks, settings, downloads, permission decisions, and sync data keyed by Vezham profile. Do not equate WebKit’s back-forward list with durable browser history. Establish whether cookie export/import, session-cookie behavior, and store removal meet migration and account-switching requirements with an SDK prototype before promising them.

### Downloads and uploads

**Documented facts:** Navigation actions/responses that become downloads are surfaced as `WKDownload`; `WKDownloadDelegate` supplies a destination and reports completion/failure. WebKit’s file-upload control invokes the UI delegate’s open-panel callback. Apple documents file upload as disabled by default on macOS if the app does not implement that callback. [WKDownload](https://developer.apple.com/documentation/webkit/wkdownload), [WKDownloadDelegate](https://developer.apple.com/documentation/webkit/wkdownloaddelegate), [WKOpenPanelParameters](https://developer.apple.com/documentation/webkit/wkopenpanelparameters), [open-panel delegate method](https://developer.apple.com/documentation/webkit/wkuidelegate/webview%28_%3Arunopenpanelwith%3Ainitiatedbyframe%3Acompletionhandler%3A)

**Recommendation:** Make save destination and file selection decisions in Swift, use system panels and sandbox-scoped URLs, and never let page-provided names or paths select arbitrary local destinations. Model download failure, cancellation, resume support, and destination selection in Vezham’s download service rather than relying on a page view’s lifetime.

### Permissions

**Documented facts:** `WKUIDelegate` includes permission callbacks for camera/microphone capture and device orientation/motion. The current Apple documentation also lists a geolocation request callback, but marks it **Beta**. These callbacks include the requesting security origin and a frame. If the media-capture callback is not implemented, WebKit’s documented default is to prompt. macOS privacy permissions and App Sandbox entitlements are additional platform controls; entitlements express app capability but do not replace user consent. [WKUIDelegate](https://developer.apple.com/documentation/webkit/wkuidelegate), [media-capture permission callback](https://developer.apple.com/documentation/webkit/wkuidelegate/webview%28_%3Arequestmediacapturepermissionfor%3Ainitiatedbyframe%3Atype%3Adecisionhandler%3A), [Beta geolocation callback](https://developer.apple.com/documentation/webkit/wkuidelegate/webview%28_%3Arequestgeolocationpermissionfor%3Ainitiatedbyframe%3Adecisionhandler%3A), [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox)

**Engineering limit:** These callbacks should not be treated as a complete browser permission-management system. Vezham needs its own per-origin/profile permission records, prompt UI, revocation, OS-level TCC interaction, and explicit behavior for capability types without a documented `WKWebView` decision callback. Do not make geolocation support a launch promise until the Beta API is stable on the supported macOS release. Verify each desired permission on the supported macOS range.

### Context menus, navigation interception, find, and zoom

**Documented facts:** `WKNavigationDelegate` allows or denies navigation actions and responses, tracks load stages, and receives failure/process-termination callbacks. `WKUIDelegate` supplies native UI integration points, including new windows, JavaScript dialogs, upload panels, and contextual UI. `WKWebView.find(_:configuration:)` searches page content and supports direction, case sensitivity, and wrapping. On macOS, `pageZoom` and magnification APIs can scale content. [WKNavigationDelegate](https://developer.apple.com/documentation/webkit/wknavigationdelegate), [WKUIDelegate](https://developer.apple.com/documentation/webkit/wkuidelegate), [find configuration](https://developer.apple.com/documentation/webkit/wkfindconfiguration), [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview/)

**Engineering limit:** WebKit exposes selected control points, not a complete omnibox/network interception layer. A policy callback is not a general request firewall for every subresource. Native context-menu customization details vary by platform/API; prototype macOS behavior instead of assuming that UIKit context-menu examples port unchanged. Use app-owned history and navigation events as the durable source of browser history.

### Web-content process crashes and security

**Documented facts:** WebKit reports when a web-content process terminates. Apple describes the web view as using a separate process for rendering and managing web content. The host receives notification, but is responsible for presenting an error/reload experience and restoring its own UI state. [Process termination callback](https://developer.apple.com/documentation/webkit/wknavigationdelegate/webviewwebcontentprocessdidterminate%28_%3A%29)

**Engineering limit:** The public API does not expose a browser-vendor-style process topology or per-renderer sandbox policy for Vezham to tune. The web-content process separation is a meaningful platform boundary, not a guarantee that the host is safe from a WebKit compromise or from unsafe native bridge design. The accepted internal direct-distribution path requires Developer ID signing and notarization. Exact hardened-runtime flags, App Sandbox configuration, and entitlements still require validation; the distribution decision has not settled those details. [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox), [Mac distribution preparation](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution)

### Distribution, updates, and modern-browser limits

Vezham does not package a separate WebKit runtime; it links the system framework. Apple controls WebKit delivery through OS updates, reducing Vezham’s engine packaging and security-release pipeline. Vezham still owns Developer ID signing, notarization, app-level security, minimum-OS compatibility, regression testing on new macOS releases, and customer support across the supported OS matrix for the accepted internal direct-distribution path. Installer and updater details remain open. [Packaging Mac software](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution), [distribution architecture](browser-distribution.md)

Relevant browser-product risks include Safari/WebKit compatibility differences, limited control over the engine’s release cadence and process model, public-API gaps for full browser networking/permission control, and lack of documented general-purpose Chrome-extension hosting in `WKWebView`. Apple’s Safari Web Extensions are packaged as app extensions for Safari (and specified Mac web-app cases), which is different from a general extension host for arbitrary `WKWebView` tabs. [Safari Web Extensions](https://developer.apple.com/documentation/safariservices/safari-web-extensions)

## B. Chromium through CEF or a lower-level integration

### CEF as the practical embedder candidate

**Documented facts:** CEF is a C/C++ framework for embedding Chromium. Its project publishes binary distributions with the framework, headers, libraries, resources, samples, and a BSD license. CEF release branches track Chromium milestones and the project documents that CEF availability can lag Chromium releases. [CEF general usage](https://chromiumembedded.github.io/cef/general_usage.html), [CEF branches and building](https://chromiumembedded.github.io/cef/branches_and_building.html)

CEF is the practical candidate for a native Swift/React product that wants Chromium without owning a complete Chromium fork. The host still needs a C/C++ boundary (typically Objective-C++ for AppKit/Swift interop), a macOS helper app bundle, browser process lifecycle, UI integration, and version-specific glue. CEF supports native platform UI and off-screen rendering modes; choose the native child-view path for MVP feasibility unless a specific composition requirement justifies off-screen rendering. [CEF tutorial](https://chromiumembedded.github.io/cef/tutorial)

A direct Chromium Content API integration offers more control, but it moves engine API churn, process wiring, packaging, and security patch integration onto Vezham. This is not a lower-cost alternative to CEF for Phase 2. The Arc inspection confirms that a Chromium browser can be packaged as a custom framework with browser/renderer/GPU helpers, but Arc’s proprietary bundle is not a template or implementation source for Vezham. [Arc architecture report](../../arc-macos-architecture-report.md)

### Browser, renderer, GPU processes and macOS integration

Chromium’s architecture uses a browser process plus renderer processes and separate GPU/network/storage/utility processes as needed; the browser controls renderer creation and communication. Renderer separation and OS sandboxing are security mechanisms, but the actual assurance depends on process launch configuration and platform setup. [Chromium multi-process architecture](https://www.chromium.org/developers/design-documents/multi-process-architecture/), [Chromium sandbox overview](https://chromium.googlesource.com/chromium/src/+/main/docs/design/sandbox.md)

CEF inherits this model. Its macOS docs require a separate helper executable/app bundle for subprocesses. CEF sandboxing on macOS must be explicitly enabled with the matching CEF sandbox library and initialization in the helper before loading CEF; a helper bundle existing on disk does not itself prove sandboxing is active. [CEF tutorial](https://chromiumembedded.github.io/cef/tutorial), [CEF sandbox setup](https://chromiumembedded.github.io/cef/sandbox_setup)

### Profiles, cookies, and sessions

CEF’s `CefRequestContext` associates browsers and requests with cache paths, cookie managers, request handlers, and settings. A context with an empty cache path is in-memory; a non-empty profile path persists data. CEF documents that browsers with different request contexts are not hosted in the same renderer process, while process sharing rules still depend on the process model. [CEF request context settings](https://cef-builds.spotifycdn.com/docs/156.0/structcef__request__context__settings__t.html), [CEF request context](https://cef-builds.spotifycdn.com/docs/156.0/classCefRequestContext.html)

This is a stronger engine-level profile mechanism than a simple app-owned namespace, but Vezham must still define isolated profile paths, prevent path collisions, handle concurrent writes, control session-cookie persistence, and make profile deletion/export behavior reliable. Different renderer processes do not by themselves prove full OS account separation; sandbox and filesystem policy remain essential.

### Downloads, uploads, permissions, context menus, find, and zoom

CEF exposes handlers for downloads, file dialogs, permissions, context menus, and find; browser APIs also expose zoom, back/forward navigation entries, and lifecycle events. These capabilities are documented as CEF APIs, but the host must implement UI, permissions persistence, destination handling, and platform-specific file access. [CefBrowserHost API](https://cef-builds.spotifycdn.com/docs/156.0/classCefBrowserHost.html), [CefDownloadHandler](https://cef-builds.spotifycdn.com/docs/118.0/classCefDownloadHandler.html), [CefPermissionHandler](https://cef-builds.spotifycdn.com/docs/156.0/classCefPermissionHandler.html), [CefContextMenuHandler](https://cef-builds.spotifycdn.com/docs/152.0/classCefContextMenuHandler.html)

CEF permission defaults depend on runtime style. For example, the CEF 156 docs state that Chrome-style default handling displays permission UI, while Alloy-style default handling ignores a general permission prompt and denies media access. Vezham must implement its own policy/UI and test each request type; the default behavior must not become accidental product policy. [CefPermissionHandler](https://cef-builds.spotifycdn.com/docs/156.0/classCefPermissionHandler.html)

### Extensions: do not promise Chrome parity

CEF currently has two runtime styles: Alloy and Chrome. The CEF architecture docs describe Chrome runtime as offering a larger set of Chrome features, including extension support, while Alloy is the smaller embedding-oriented runtime. The Chrome runtime’s Views/UI requirements and behavior differ from an AppKit-owned browser shell; CEF docs state that runtime-style feature support is not identical. Separately, CEF’s legacy V8 `CefRegisterExtension` mechanism is documented as deprecated starting in M154; that mechanism is not the same thing as full Chrome WebExtensions support. [CEF architecture](https://github.com/chromiumembedded/cef/blob/master/docs/architecture.md), [CEF JavaScript integration](https://github.com/chromiumembedded/cef/blob/master/docs/javascript_integration.md)

**Conclusion:** Treat third-party Chrome extension compatibility as unsupported for MVP until a pinned CEF release and the specific Vezham extension API requirements are audited and tested. A request for Chrome extensions is a decision gate, not a checkbox implied by “Chromium.”

### Updates, packaging, signing, and size

CEF bundles include engine code and resources. On macOS, Vezham would ship CEF frameworks, helper apps, libraries, resource packs, and the native app. The outer app and all nested code must be signed in the correct order with process-appropriate entitlements and notarized for the accepted internal direct-distribution path. CEF documentation warns that helper entitlements are per process and its macOS sandbox requirements are version-sensitive. [CEF code signing](https://chromiumembedded.github.io/cef/code_signing.html), [Apple notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

Vezham becomes responsible for selecting supported CEF releases, integrating Chromium security fixes, testing upgrades, signing every helper/library, notarizing, validating clean installs, and handling crashes/regressions. CEF release branches track Chromium milestones, but CEF docs note that binary builds may lag Chromium updates. [CEF branches and building](https://chromiumembedded.github.io/cef/branches_and_building.html), [CEF README/security updates](https://github.com/chromiumembedded/cef/blob/master/README.md)

The runtime payload will be substantially larger than using a system-provided engine. No exact CEF size is asserted here because it depends on the release, architecture slices, build flags, resources, and compression. As an illustration only, the locally inspected Arc 1.172.1 bundle’s proprietary `ArcCore` binary was about 508 MB; this is not a CEF size prediction.

### Licensing and redistribution

CEF’s binary distribution includes a BSD license and its docs instruct redistributors to include the license text in the product distribution. Chromium’s main license permits redistribution subject to its stated notice and disclaimer terms, but a shipped browser also contains many third-party components with their own notices and terms. Vezham must produce a license/attribution inventory from the exact pinned engine distribution, preserve required notices, review codec/patent and trademark implications for any selected build, and obtain legal review before release. This is an engineering checklist, not legal advice. [CEF redistribution/license guidance](https://chromiumembedded.github.io/cef/general_usage.html), [Chromium LICENSE](https://chromium.googlesource.com/chromium/src/+/main/LICENSE)

## Recommendation and decision gates

### Conditional MVP direction: WebKit, with unresolved validation

The recorded owner choice conditionally accepts `WKWebView` behind the engine contract for the macOS MVP. The original rationale remains:

1. It is the most direct fit for the required Swift/AppKit host and avoids a second browser runtime inside the app.
2. Persistent profile data stores, private in-memory stores, navigation policy/events, download/upload callbacks, find, zoom, and process-termination notification are publicly documented.
3. The OS supplies the engine, avoiding Vezham’s initial multi-process runtime packaging, helper signing, and Chromium security-release integration pipeline.
4. It supports staged product/profile/security validation before any separately scoped CEF evaluation introduces additional operational ownership.

The engine direction is conditionally accepted for MVP planning and implementation, not unconditionally qualified for production. It does not establish Chromium equivalence, universal site compatibility or a full extension host. ADR 0001 Stage A/B/C sequences the remaining tests without waiving them. The current task implements M0 only; no full WK adapter or CEF implementation is authorized here.

### Risks and complexity

| Risk                 | WebKit MVP                                                                                                          | CEF/Chromium                                                                                                           |
| -------------------- | ------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Site compatibility   | Safari/WebKit divergence may break target sites or auth flows                                                       | Better Chromium compatibility, but still not Google Chrome’s exact product/codec/API configuration                     |
| Security ownership   | Must harden UI/bridge, profile handling, permissions, downloads, sync; engine sandbox details are mostly OS-managed | Same host risks plus helper sandbox configuration, process-specific entitlements, Chromium update/patch responsibility |
| Browser feature gaps | Extension host and network interception limitations; permission coverage varies                                     | Extension APIs/runtime styles are not uniform; native Chrome UI requirements can conflict with custom Swift UI         |
| Update cadence       | Engine follows macOS release/security updates                                                                       | Vezham selects, integrates, ships, and validates CEF updates; a build can lag Chromium                                 |
| Packaging            | Native app signing/notarization                                                                                     | Large engine and helper payload; nested signing/entitlements/notarization and architecture slices                      |
| Phase 2 development  | Low-medium                                                                                                          | High                                                                                                                   |

### Conditions for adding CEF later

Revisit CEF only when one or more measurable product requirements cannot be met acceptably by WebKit:

- Reproducible WebKit incompatibilities block named, high-priority target sites or workflows after reasonable app-level remediation.
- Users require a defined list of Chrome extension APIs that a pinned, supported CEF Chrome runtime demonstrably supports.
- Cross-platform engine consistency becomes a funded requirement, rather than a speculative future possibility.
- A measured compatibility or security requirement justifies Vezham owning the engine release, helper, signing, and update burden.

Before deciding to add CEF, prototype one native child browser view with one isolated persistent context; test helper launch and sandbox; test permission/download/upload flows; audit the exact extension API list; produce a signed/notarized test bundle; measure unpacked and downloaded size; and exercise one Chromium upgrade. Keep Chromium/CEF evaluation-only. No implementation or second-engine milestone is authorized by this comparison or the current M0 task.

## Source register

Sources are primary project/vendor documentation reviewed on 2026-11-07. API details and CEF branch availability change; recheck exact versions before implementation.

- Apple: [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview/), [configuration](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration), [navigation delegate](https://developer.apple.com/documentation/webkit/wknavigationdelegate), [website data stores](https://developer.apple.com/documentation/webkit/wkwebsitedatastore), [cookie store](https://developer.apple.com/documentation/webkit/wkhttpcookiestore), [downloads](https://developer.apple.com/documentation/webkit/wkdownload), [UI delegate](https://developer.apple.com/documentation/webkit/wkuidelegate), [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox), [Safari Web Extensions](https://developer.apple.com/documentation/safariservices/safari-web-extensions), [distribution](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution).
- Chromium: [multi-process architecture](https://www.chromium.org/developers/design-documents/multi-process-architecture/), [sandbox overview](https://chromium.googlesource.com/chromium/src/+/main/docs/design/sandbox.md), [project license](https://chromium.googlesource.com/chromium/src/+/main/LICENSE).
- CEF: [general usage](https://chromiumembedded.github.io/cef/general_usage.html), [tutorial](https://chromiumembedded.github.io/cef/tutorial), [architecture](https://github.com/chromiumembedded/cef/blob/master/docs/architecture.md), [sandbox setup](https://chromiumembedded.github.io/cef/sandbox_setup), [code signing](https://chromiumembedded.github.io/cef/code_signing.html), [branch/building policy](https://chromiumembedded.github.io/cef/branches_and_building.html), [CEF 156 request contexts](https://cef-builds.spotifycdn.com/docs/156.0/classCefRequestContext.html), [browser host API](https://cef-builds.spotifycdn.com/docs/156.0/classCefBrowserHost.html), [permissions](https://cef-builds.spotifycdn.com/docs/156.0/classCefPermissionHandler.html).
