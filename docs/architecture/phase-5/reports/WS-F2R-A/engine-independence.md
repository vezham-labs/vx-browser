# Engine independence

**Source:** Foundation domain IDs are separate from engine objects. The current storage descriptor still carries adapter version and a 26 platform minimum. The native adapter resolves resources, then binds a named/nonpersistent store before view construction. Reuse the typed ports and move adapter-specific version/minimum information into versioned opaque adapter bindings if/when their contract is revised. The adapter can validate them without importing WebKit into product models. [Domain descriptor](../../../../../qualification/webkit-storage-f0/Sources/BrowserDomain/StorageDescriptor.swift), [ports](../../../../../qualification/webkit-storage-f0/Sources/BrowserPorts/StoragePorts.swift), [adapter](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeWebKitStorage.swift)

| Boundary | Proposed stable contract |
|---|---|
| BrowserDomain | ProfileID, SessionID, typed data/policy and safe navigation values; no WK types, paths or engine schemas |
| BrowserPorts | Logical repositories, authenticated lifecycle operations, scoped binding and capabilities, typed failure/cancellation/terminal outcomes |
| BrowserCore | Authority over profiles, permissions, tabs/session policies, grants, lifecycle, epochs, restore and cross-resource orchestration |
| BrowserPersistence | SQLite-backed protected logical repositories where required, catalog, receipts, deletion knowledge, portable archive schemas; no origin data |
| Native Host | Swift/AppKit application lifecycle, native security, user presence, Keychain, files/OS consent and engine view execution |
| Engine adapter | Namespaced binding `engine kind + adapter format/version + opaque store identifier + profile scope/generation`; capabilities and lifecycle assertions, public engine API only |
| Browser chrome | Future React + TypeScript + HeroUI v3 UI issues scoped typed intents; cannot choose stores, obtain keys or bypass policy. Website content is a separate untrusted surface. |

A future engine can use its own namespace, formats and equivalent scoped lifecycle ports. During an authorized change, authenticate the logical profile, quiesce old resources and grants, create a fresh namespace, reconcile the replacement mapping, validate capability parity and admit new views only after success. Migrate product records via a versioned logical representation. Do not replay opaque store bindings, site session cookies, grants or native file authorities across engine/device changes. Keep old engine stores under explicit preservation/deletion policy until verified migration and authorized retirement. Portability of any website data is an independently evaluated public-engine-API feature.

WKWebView remains conditional for MVP. Chromium/CEF remains evaluation-only. Swift/AppKit and engine-independent core remain the baseline. No Aura, production Tamizhi integration, mandatory Vezham identity/cloud, or public distribution. [ADR 0001](../../../../decisions/0001-browser-engine-strategy.md), [ADR 0002](../../../../decisions/0002-browser-distribution-and-platform.md), [ADR 0003](../../../../decisions/0003-browser-core-runtime-and-language.md), [ADR 0005](../../../../decisions/0005-browser-capability-boundaries-and-lifecycle.md), [platform architecture](../../../browser-platform-architecture.md)
