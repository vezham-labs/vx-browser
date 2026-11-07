# Arc for macOS: static architecture inspection

**Target:** Arc 1.172.1, build 90370, from `/Users/vigneshwaranbhoj/Downloads/Arc-1.172.1-90370.dmg` (bundle visible at `/Volumes/Arc/Arc.app`).  
**Inspection date:** 2026-11-07.  
**Method:** Read-only bundle, plist, Mach-O dependency, signature-metadata, and string-table inspection. No Arc executable or helper was launched; no bundle files were changed or copied.

## Executive summary

Arc is a native macOS application whose host executable is a universal x86_64/arm64 Mach-O named `Arc`. The host dynamically links to the bundled `ArcCore.framework`. That framework is the browser engine integration: its bundle version is `157.0.8103.39`, its binary contains Chromium Blink and V8 symbols, and it packages Chromium-style Browser, Renderer, and GPU helper apps plus Vulkan/SwiftShader libraries. This is strong evidence that Arc 1.172.1 embeds a Chromium-derived browser engine, customized/packaged by The Browser Company.

The host also links Apple’s system WebKit and imports `WKWebView`, `WKWebViewConfiguration`, and `WKWebsiteDataStore` classes. This confirms WebKit code is used somewhere in the app, but static inspection does not establish whether it is used for the primary page view or for auxiliary/internal web content. The Chromium evidence for the browser core is substantially stronger: `ArcCore` is the large, directly linked framework and owns renderer/GPU helpers.

No CEF or Electron framework, executable, or conventional packaging layout was found. This does not prove Arc has no CEF-derived code or Electron-like techniques internally; the evidence supports a native Arc host with a proprietary Chromium integration, rather than a stock Electron or CEF application.

## Bundle layout and metadata

The top-level application layout is the conventional macOS bundle shape:

```text
Arc.app/Contents/
  Info.plist
  MacOS/Arc
  Frameworks/
    ArcCore.framework/
      Versions/A/ArcCore
      Versions/A/Helpers/Browser Helper*.app
      Versions/A/Libraries/{libaperitif,libvulkan,libvk_swiftshader}.dylib
      Versions/A/Resources/ (locale packs, DevTools, other Chromium resources)
    FirebaseFirestoreInternal.framework
    Lottie.framework
    Sentry.framework
    Sparkle.framework
    absl.framework
    grpc.framework
    grpcpp.framework
    openssl_grpc.framework
    libswiftCompatibilitySpan.dylib
  PlugIns/DockTilePlugIn.plugin
  Resources/ (Arc feature bundles, assets, locales, SDK bundles)
  _CodeSignature/CodeResources
  embedded.provisionprofile
```

`Info.plist` reports:

- `CFBundleIdentifier`: `company.thebrowser.Browser`
- `CFBundleExecutable`: `Arc`
- `NSPrincipalClass`: `Arc.BrowserApp`
- `CFBundleShortVersionString` / `CFBundleVersion`: `1.172.1` / `90370`
- `BCNYBuildDate`: `5 Nov 2026, 19:13`; `BCNYCommitInfo`: `Release-90370-cc0f0476d6246731128ba65d3e4c5fa46b4aacbf`
- Minimum macOS version: `13.0.0`
- Document and URL registrations include HTML/XHTML/PDF, `http`, `https`, `mailto`, and `arcBrowser`.

The main executable and `ArcCore` are both universal binaries (x86_64 and arm64). Their observed sizes are about 167.6 MB and 507.5 MB respectively. The app’s resources include a large family of `ARC_*` feature bundles, localized `.lproj` resources, `Assets.car`, and third-party SDK resource bundles. `ArcCore` has Chromium-oriented resource directories including locale packs and `DevTools`.

The installed `/Applications/Arc.app` is a different, older build: 1.171.0 / 89666, with `ArcCore` 156.0.8078.74. Findings in this report refer to the supplied 1.172.1 DMG bundle unless explicitly identified otherwise.

## Main executable and linked frameworks

`Contents/MacOS/Arc` is a signed universal Mach-O executable. Its load commands show a direct dependency on:

- `@executable_path/../Frameworks/ArcCore.framework/Versions/A/ArcCore`
- bundled `Lottie.framework` and `Sparkle.framework`
- Apple system frameworks including AppKit, Foundation, SwiftUI, WebKit, AVKit/AVFoundation, CloudKit, Core Data, Core Graphics, Metal, Core Location, and others
- the system Swift runtime and Objective-C runtime

`ArcCore.framework` is itself a universal dynamically linked shared library, identified as `company.thebrowser.browser.framework`, version `157.0.8103.39`. Its linkage includes Apple graphics, media, networking, security, and operating-system frameworks. The app bundle also contains Firebase, gRPC, OpenSSL gRPC, Abseil, Sentry, and related frameworks/bundles. These indicate supporting SDKs and services; their presence alone does not establish which features are active at runtime.

The app and framework carry code-signing metadata with Team ID `S6N382Y83G` and the hardened-runtime flag. `codesign -dv` reported the signing authority as unavailable in this inspection environment, so this report does not claim an independent signature trust/validity result.

## Browser-engine evidence

### Chromium: confirmed with high confidence

Evidence from the supplied bundle:

1. `Arc` directly links `ArcCore.framework`; the framework metadata reports Chromium-shaped version `157.0.8103.39`.
2. `ArcCore` string tables contain extensive `blink::` and `v8::` symbols, matching Chromium’s Blink rendering engine and V8 JavaScript engine.
3. `ArcCore` packages `Browser Helper`, `Browser Helper (Renderer)`, `Browser Helper (GPU)`, and alert/Aperitif helper variants. The helper bundle IDs and names explicitly identify browser, renderer, and GPU roles. This is consistent with Chromium’s multi-process architecture.
4. The framework contains `libvulkan.dylib` and `libvk_swiftshader.dylib`, alongside Chromium resource directories and DevTools resources.
5. There is no separate top-level Chromium framework because the engine is packaged inside `ArcCore.framework`.

Together, these facts support an embedded Chromium-derived engine rather than WebKit as Arc’s primary browser engine. They do not reveal how far Arc diverges from upstream Chromium, its exact build flags, update cadence, or enabled/disabled features.

### WebKit: confirmed use, role unresolved

`Arc` links `/System/Library/Frameworks/WebKit.framework`, and its undefined-symbol table includes Objective-C class references to `WKWebView`, `WKWebViewConfiguration`, and `WKWebsiteDataStore`. This confirms the host uses WebKit APIs. It does not establish what content they render. Potential roles such as sign-in, internal pages, previews, or other embedded content remain hypotheses; runtime observation or deeper call-site analysis would be needed to identify the actual role.

### CEF: not evidenced

No `Chromium Embedded Framework.framework`, `libcef`, or `cefclient` was found in the inspected bundle paths. Arc’s private `ArcCore.framework` and branded helper apps point to a custom integration. Absence of the conventional CEF artifacts is evidence against stock CEF packaging, not proof about internal code ancestry.

### Electron: not evidenced

No `Electron Framework`, `Electron Helper`, `app.asar`, or bundled Node runtime was found. The `Arc.BrowserApp` principal class, AppKit/SwiftUI/Swift runtime linkage, and native app bundle structure support a native macOS host rather than a stock Electron shell.

### Custom integration: strongly supported

The proprietary-named `ArcCore.framework`, The Browser Company bundle identifiers, direct host-to-framework linkage, branded helper processes, and Chromium engine symbols together support a custom native integration of Chromium. The specific internal APIs, patch set, process-launch controls, IPC protocol, and code boundaries are not recoverable from these metadata observations alone.

## Evidence versus inference

| Finding | Status | Basis |
|---|---|---|
| Native macOS host executable named `Arc`, x86_64 + arm64 | Confirmed | Bundle `Info.plist`; `file` output |
| ArcCore version `157.0.8103.39` is bundled and directly linked | Confirmed | Framework `Info.plist`; `otool -L` |
| Chromium Blink/V8 components are in ArcCore | Confirmed | Static string/symbol inspection |
| Separate renderer/GPU/browser helpers are packaged | Confirmed | Helper app paths and helper `Info.plist` metadata |
| ArcCore provides the primary page-rendering engine | High-confidence inference | Engine markers plus direct host linkage and packaged renderer/GPU process roles |
| WebKit APIs are used somewhere by the host | Confirmed | WebKit load command and imported WKWebView class symbols |
| WebKit’s specific product role | Unknown | Static linkage does not identify call sites or actual views |
| Stock CEF or Electron packaging | Not evidenced | Expected conventional bundle artifacts were not found |
| Arc’s Chromium patches and build configuration | Unknown | Not recoverable from bundle names and metadata alone |

## Scope limits and handling

This was a static inspection. Arc and its helpers were not run. No network activity was initiated, no user profile or browser data was inspected, and no secrets/config values were extracted. In particular, the presence of `GoogleService-Info.plist` was noted as a resource path only; its contents were not read. No Arc proprietary source code or assets were copied into Vezham Browser.

Static dependency lists do not prove that every linked framework is exercised in normal browsing, and string-table matches can include dormant or shared upstream code. Conversely, the absence of a named framework does not rule out statically linked or renamed components.

## Recommended next investigative steps

1. **Map WebKit call sites and purpose.** Continue static analysis of class/symbol references and app feature bundles to identify which flows instantiate `WKWebView`. If runtime validation is later authorized, observe view/process creation on a clean test profile and harmless local test pages.
2. **Inspect helper entitlements and sandbox profiles.** Read the app/helper entitlements and relevant plist metadata to understand privilege separation, renderer restrictions, GPU access, and network permissions. Keep this static and avoid changing signing or system policy.
3. **Map Chromium process orchestration.** Record helper executable metadata, command-line configuration only from authorized static artifacts, and process/IPC behavior in a controlled runtime study. This will clarify whether Arc uses Chromium’s standard multiprocess model or a heavily customized arrangement.
4. **Establish engine maintenance costs for Vezham.** Compare a native `WKWebView` design with a Chromium embed in terms of browser-feature coverage, update ownership, helper packaging, sandboxing, crash isolation, and cross-platform needs. Arc demonstrates that shipping Chromium as a custom framework entails substantial bundled engine/runtime material and multiple helper executables.
5. **Keep Vezham implementation independent.** Use these observations as architectural facts only. Build against Apple WebKit or a separately licensed/maintained Chromium distribution; do not reuse Arc binaries, assets, branding, or proprietary implementation details.

## Reproducibility notes

Read-only tools used included `find`, `file`, `stat`, `PlistBuddy`, `otool -L`, `nm -u`, `strings -a` with focused filtering, and `codesign -dv`. The inspected paths were under `/Volumes/Arc/Arc.app`; the separately installed `/Applications/Arc.app` was only checked to establish its older version. No Arc binaries were executed.
