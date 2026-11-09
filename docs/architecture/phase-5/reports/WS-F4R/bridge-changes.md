# Typed bridge changes

The existing version-1 command/result envelope remains the single bridge.

| Commands | Native authority |
|---|---|
| spaceCreate/Rename/Switch/Delete | Bound names, known identity, empty deletion, selection and split reconciliation |
| tabSpace, pin | Known published tab and destination; reset group on Space move |
| groupCreate/Rename/Toggle/Move/Delete, tabGroup | Bound group identity, same-Space membership, stable tab IDs |
| split, unsplit | Distinct published views in one session and Space |
| miniOpen, miniTransfer | Validated URL, capped windows, explicit URL-only transfer |
| Existing navigation/presentation | Active native view and bounded content geometry |

State adds Spaces, groups, memberships, pins, split IDs, narrow fallback and mini mode. Favicons are bounded PNG data. Admission still requires the exact bundled main-frame document and WKWebView, envelope size/version and known command values. Content views have no chrome handler. Errors are explicit.

[TypeScript](../../../../../apps/browser-macos/Chrome/src/bridge.ts) · [Swift](../../../../../apps/browser-macos/Sources/Host/BrowserChromeContract.swift)
