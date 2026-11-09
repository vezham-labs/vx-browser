# Native integration

The AppKit host uses the existing NativeStorageSession, HostAuthority and Core registration, resolve, open and retirement paths. Private product browsing selects a new nonpersistent store and the existing adapter binds it before creating a WKWebView. Only a resolved and published view can load. HTTPS uses system trust evaluation. The only HTTP exception is loopback for local content and synthetic qualification. Unsupported schemes, embedded URL credentials and absent authority fail closed. Existing named-store qualification origins remain bounded by their original allowlist.

The chrome WKWebView is independently configured before construction, uses its own nonpersistent store, and accepts only the signed bundled main document. Website WKWebViews retain the original UI and navigation delegates and permission mediator. No default-store fallback, engine file access, data replication, alternate engine or security requirement change is introduced. Normal protected startup remains fenced, with no attempt to enable Keychain or the protected databases.

The isolated development app is signed ad-hoc with existing App Sandbox, outgoing network and Hardened Runtime. Debug qualification drives its real shell and website views using a synthetic loopback origin. The historical diagnostic bundle, when used, is reported separately. macOS 26 runtime and final signing/notarization remain deferred.

[Run evidence](testing-and-evidence.md) · [Native adapter](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeWebKitStorage.swift)
