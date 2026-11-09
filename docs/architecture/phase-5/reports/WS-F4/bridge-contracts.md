# Browser chrome bridge v1

Commands are discriminated TypeScript values mirrored by Swift Decodable commands. Every request carries a correlation ID and a version. Native results echo the ID and provide a revisioned state, optional typed error and optional clipboard response for an explicit paste action. There is no arbitrary script, raw database, renderer authority or generic privileged method command.

| Family | Behavior |
|---|---|
| Snapshot | Native session state, opaque identity, ordered tabs, active tab, bounded titles, current URLs, loading/progress, native connection observation and typed failure |
| Lifecycle | Explicit start/end private session and create/select/close/duplicate/move tab. Mutations serialize on the host. Requests during a conflicting mutation receive busy. |
| Navigation | Typed back/forward/reload/stop/navigate, rejected for unowned views and unsupported addresses. AppKit clipboard commands use the trusted chrome. |
| Presentation | Bounded geometry of the native page, without altering site scope, permission or backend state |
| Appearance | Three typed values: system, light and dark |

Admission requires the expected WKWebView instance, main frame, exact bundled file document, JSON size and version checks. Content rendering receives no native message handler. Native snapshot reads are paced by the client, which applies monotonic revisions and keeps presentation state local. The displayed HTTPS indicator depends on completed WebKit navigation and its secure-content observation. Loopback HTTP has a separate unencrypted indication. No keys, passwords or full browsing URLs are written to browser diagnostic logs.

[TypeScript contract](../../../../../apps/browser-macos/Chrome/src/bridge.ts) · [Swift contract](../../../../../apps/browser-macos/Sources/Host/BrowserChromeContract.swift)
