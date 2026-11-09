# Test matrix and evidence

## Development environment

Actual macOS 27.2 (26B123), arm64, Xcode 27.2/SDK 27.2 and Swift 6.4.2. Native tests use the isolated internal.vezham.browser.wsf4.qualification app with the existing ad-hoc signature, App Sandbox, network client and Hardened Runtime. Exact app and asset hashes are in [confirmed build](evidence/confirmed-build.json).

## Results by suite

| Suite | Result | Scope |
|---|---|---|
| Confirmed native refinement | 174 PASS_NATIVE · 87 per launch · 0 FAIL | Two independent launches. Sidebar, Spaces, groups, pins, titles/favicon, command/context UI, two actual WebKit panes, focus and narrow fallback, native divider and pane close, mini navigation/transfer/cleanup, explicit native URL method and macOS Open delivery, website bridge exclusion, independent mini LocalStorage, URL-only transfer and live cross-window appearance synchronization. |
| Existing storage regression | 474 current-candidate PASS_NATIVE, 2 INCONCLUSIVE | 39 app processes including 12 deliberate cutpoints. The archived namespace diagnostic adds one separate native observation. Cache response identity on relaunch remains inconclusive. |
| Swift regression | 23 PASS_CONTRACT, 2 PASS_FAKE_ONLY | Existing contracts and isolated model coverage. |
| TypeScript URL/search | 3 PASS_CONTRACT | Normalization, rejected schemes/credentials and local provider interface. |
| Packaged React UI | 7 PASS_FAKE_ONLY | Stand-in bridge only. Tabs, sidebar, palette focus, settings, provisional bookmarks, groups, Spaces and split control rendering. |
| TypeScript/build/signature audit | Static PASS_CONTRACT | Compilation, bundle resources, script boundary and existing entitlements. Not included in runtime totals. |

The storage regression used the earlier [final build](evidence/build.json) before the palette-key correction, cross-window appearance synchronization and additional debug assertions. Its Core and native storage adapter sources match the confirmed build. Counts stay separate and do not create a combined pass rate. Its legacy supported-OS outer gate remains BLOCKED for actual macOS 26. Both main development implementations continue to use nonpersistent private scopes; protected profile/custody and release gates remain deferred.

## Interaction evidence

- [Confirmed launch 1](evidence/complete/native-1/result.json) and [launch 2](evidence/complete/native-2/result.json)
- [macOS Open launch 1](evidence/complete/external-1.json) and [launch 2](evidence/complete/external-2.json)
- [Packaged UI](evidence/frontend-verified.log), [type checking](evidence/typecheck-verified.log) and [URL/search tests](evidence/navigation-final.log)
- [Native storage regression](evidence/storage-regression.log), [environment](evidence/environment.txt), [source inventory](evidence/sources.json) and [checksums](evidence/SHA256SUMS)

## Commands

~~~sh
python3 apps/browser-macos/Tools/native_host.py build --qualification
python3 apps/browser-macos/Tools/native_host.py audit
python3 apps/browser-macos/Tools/wsf4_native.py --evidence docs/architecture/phase-5/reports/WS-F4R/evidence --run-name confirmed --refinement
~~~

Frontend runs use the checked-in Playwright config in Chrome and the existing local tools. Swift and storage runs use the original registered runner with the new report directory admitted. Exact build logs and per-run command records are preserved. No account data or user browsing data enters the fixtures.

## Earlier failures and incomplete work

- Attempts 01 and 02 stopped at split visibility. The context menu had been mounted in the mini render branch. Moving it into the main branch and asserting actual menu dismissal corrected the underlying UI path. Both runs and their failed assertions remain.
- Build 04 failed on an async call inside a short-circuit autoclosure in the debug test. The test now uses separate awaited assertions.
- Frontend 01 had five passes and two failures. One selector matched both Space and Workspace actions. The New tab selector also required its accessible shortcut text.
- The next frontend run had six passes and exposed a product defect: duplicate-title tabs shared React keys and produced stale command entries. Entries now use stable tab IDs. All seven final tests passed.
- The first external-URL campaign was interrupted by a runner variable collision after successful URL delivery. The incomplete record and exception remain under candidate. Correcting the runner produced two complete, clean-exit campaigns on the same binary.
- Ordinary website-context link menus, default HTTP/HTTPS routing, VoiceOver and public-site compatibility are NOT_EXECUTED. Pointer drag is implemented, while the native qualification verifies its typed reorder/assignment endpoints and split target path. Direct drag gesture automation is NOT_EXECUTED.
- Protected persistent profile/custody, authenticated unlock, durable backup and macOS 26/release qualification remain BLOCKED or deferred. They are outside WS-F4R's implementation authority.
