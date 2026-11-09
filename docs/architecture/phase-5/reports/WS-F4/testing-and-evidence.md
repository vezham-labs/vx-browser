# Testing and evidence

## Actual application captures

These captures come from the AppKit window of the isolated development build. The coastal guide is an owned loopback fixture rendered in its native website view.

- [Start screen](evidence/verified-native/native-1/start.png)
- [Private new tab](evidence/verified-native/native-1/private.png)
- [Website rendered in WebKit](evidence/verified-native/native-1/browsing.png)
- [Light appearance settings](evidence/verified-native/native-1/settings-light.png)

## Final observations

| Suite | Classification | Outcome |
|---|---|---|
| Actual browser smoke | PASS_NATIVE | Two launches, 28 assertions per launch, both terminated cleanly. Covers native shell, actual nonpersistent assignment, navigation and a page link, back, duplication and reorder, chrome isolation, rejected file navigation, native load failure UI, cookie seeding and subsequent nonreuse, session retirement and native appearance change. |
| WebKit storage regression | PASS_NATIVE / INCONCLUSIVE | 474 current-binary observations passed, 2 HTTP-cache relaunch observations inconclusive. One archived diagnostic observation is separate. The 39 processes include 12 deliberate terminations. |
| TypeScript navigation | PASS_CONTRACT | 3 checks for URL normalization, unsupported/credentialed input and local search provider behavior. |
| Existing Swift regression | PASS_CONTRACT / PASS_FAKE_ONLY | 23 contract and 2 fake tests. |
| Packaged React chrome | PASS_FAKE_ONLY | 4 Playwright checks with a stand-in or disconnected bridge. Includes tab and form interactions, sidebar, context actions, focus, settings, session bookmark reset and 660 × 470 layout. |
| Build, type checking and bundle audit | Static PASS_CONTRACT | React bundle, Swift build and unchanged sandbox/Hardened Runtime verified. These checks are reported separately from runtime case totals. |

The development host ran macOS 27.2 (26B123), arm64, Swift 6.4.2 and SDK 27.2. Release performance, real public-site workflows, accessibility assistive technology coverage and physical-device/OS privacy guarantees were outside this run. Protected profile workflows, native transfers and release signing stay blocked or deferred. Bundled assets and local native snapshots eliminate remote chrome startup dependencies; no release latency thresholds were qualified.

## Preserved prior outcomes

- [Initial build](evidence/build-01.log) failed Swift actor isolation around NSEvent. The host now handles shortcuts at the window's key-equivalent boundary.
- [Initial frontend run](evidence/frontend-01.log) failed because the library bundle retained a Node environment reference. The build now defines production mode and the packaged shell runs in the browser.
- [Initial native run](evidence/native-runner-01.log) passed functional assertions but timed out before debug process exit. The explicit debug termination path passed in the later builds. Ordinary interactive quit was not independently qualified.
- [Initial storage runner](evidence/storage-regression-runner.log) stopped at the debug bundle identity guard. The corrected guard accepts only the two explicit isolated development IDs for synthetic fixture work. [Final storage regression](evidence/native-162832669345/case-results.json)

## Evidence index

[Build](evidence/build-04.log) · [Bundle and resource hashes](evidence/verified-bundle.json) · [Audit](evidence/bundle-audit-verified.log) · [Host](evidence/environment.txt) · [Native run 1](evidence/verified-native/native-1/result.json) · [Native run 2](evidence/verified-native/native-2/result.json) · [Packaged chrome](evidence/frontend-verified.log) · [Navigation](evidence/navigation-tests-final.log) · [Final matrix](evidence/qualification.json) · [Preservation](evidence/preservation.json) · [Checksums](evidence/SHA256SUMS)
