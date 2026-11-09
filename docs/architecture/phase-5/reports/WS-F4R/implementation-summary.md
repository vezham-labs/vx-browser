# Implementation summary

| Area | Changed source |
|---|---|
| React | Browser.tsx, styles.css, bridge.ts and icons.tsx render the sidebar workspace, organization, switcher, split headings and mini mode |
| Frontend tests | shell.spec.ts covers vertical organization, Spaces and split controls as stand-in tests |
| Contract | BrowserChromeContract.swift adds typed native commands and state |
| AppKit | MainWindowController.swift owns organization, split panes, focus, mini windows, transfer and cleanup |
| Adapter | NativeWebKitStorage.swift adds scoped target-blank routing and bounded favicon observation |
| URL entry | ApplicationDelegate.swift and Info.plist declare and handle the custom scheme |
| Qualification | wsf4_native.py executes the native flow and captures owned windows; wsf1.py and wsf1_native.py admit the new evidence directory |

No dependency, schema, SQLCipher, entitlement or ADR changes. [Evidence](test-matrix.md) · [Disposition](final-disposition.md)
