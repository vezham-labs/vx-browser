# Native lifecycle

Core registers, resolves, constructs and publishes private views before navigation. UI organization references those IDs. The main host and each mini hold independent NativeStorageSession values. Website stores are assigned before WKWebView construction.

Split changes detach wrappers and mount the same views in new slots. Closure detaches strong UI references before Core retirement. The native pane focus event drives selection and the active border.

Mini creation is busy-fenced. A close during construction schedules cleanup after the pending operation. Transfer checks main-window admission, loads a new main tab and ends the mini session. Independent closure waits for cleanup before removing the child controller.

Favicons use page-provided metadata, a bounded same-origin/data image fetch and native bitmap validation. Dimensions are capped at 256 pixels and output at 32 KiB. They stay in memory; failure uses the generic icon. Engine files are never accessed.

[Host](../../../../../apps/browser-macos/Sources/Host/MainWindowController.swift) · [Adapter](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeWebKitStorage.swift)
