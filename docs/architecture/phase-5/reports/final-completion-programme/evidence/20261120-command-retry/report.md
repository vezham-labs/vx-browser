# Installed command bar and sidebar qualification

20 November 2026. Development Preview 0.1.0 (1), internal.vezham.browser.ui-preview, macOS 27.2 arm64. Base and remote branch head ac22c4b. [Installation and executable SHA-256](accepted-install.json).

The previous command implementation opened a sheet and enumerated tabs, Spaces and actions. Saved destinations now use the existing session-owned Bookmark lookup and navigation path. A centered native view sits above both the chrome and the WebKit surface. Testing the first floating build exposed that WebKit retained keyboard focus. The installed revision transfers focus to the AppKit search field when it enters the window and uses the field editor for selection, submission and dismissal.

| Installed check | Observation |
|---|---|
| ⌘K over a loaded fixture | The search field received keyboard focus and accepted typing without a click. |
| Arrow keys and Return | Down selected Settings, Up returned to the search action, Down and Return opened the Settings sheet. |
| Dismissal | Escape dismissed the reopened palette. A click outside also dismissed it. |
| Private collections | Favorite title, Bookmark URL and folder name matched. Opening results loaded the correct loopback URLs. Reading returned both children. |
| Native pointer movement | Bravo exchanged Favorite slots with Visual fixture and opened its original URL. Unpinned Bravo moved to the front. Visual fixture moved ahead of Bravo in Pinned. Charlie moved into collapsed Reading and appeared under it on expansion. |
| Restart | After quitting the populated preview, the app showed inactive startup and a fresh session contained one blank tab and zero Favorites or Bookmarks. Independent process-absence sampling on the final iteration was inconclusive. No durable restoration pass. |

[Installed AX observations](accepted-ui.json) · [Favorite before](accepted-drag-before.jpg) · [Favorite after](accepted-drag-after.jpg)

## Visual measurements

Arc 1.172.1 (90370) incognito and Vezham private Main displayed the same loopback fixture with dark appearance on the same Retina display. Captures are 2880 × 1648. The reference and candidate each had one loaded tab and empty collections. The command comparison used the native command entry in each app, including the differing suggestions, materials and page backdrop. No resize, crop or masks. Earlier captures with a different sidebar state or a detached sheet were excluded from paired measurements.

| State | RGB mismatch | Any channel above 8 | Mean absolute channel error / 255 | Luma SSIM |
|---|---:|---:|---:|---:|
| [Expanded](accepted-expanded/side-by-side.png) | 26.457% | 6.382% | 3.3302 | 0.94695 |
| [Collapsed](accepted-collapsed/side-by-side.png) | 10.550% | 4.057% | 1.2707 | 0.97377 |
| [Command](accepted-command/side-by-side.png) | 61.601% | 29.117% | 9.6519 | 0.88408 |

Each state directory includes original-resolution overlay, difference image, fixed-region metrics and side-by-side output. Command result ranking, colors, palette width, reference defaults and sidebar structure differ. Arc's search-provider and account-backed data were outside the disposable session.

## Regression results

[Exact command arguments and exit statuses](commands.json) · [Logs](accepted-tests/) · [Preview build](focus-build.log)

Core passed 101 tests in 13 suites. Storage passed 27 tests in one suite. Workspace passed 39 native and 7 contract observations. Recovery passed 34 native and 11 contract observations. Legacy UI passed 16 tests. Navigation passed four contracts. All exit codes were zero, including the TypeScript check and bundle audit. The Preview build emitted weak-variable warnings in qualification routines and an App Intents metadata notice. Strict verification of the installed ad hoc signature passed.

## Open qualification

Production restore requires approved production provider admission, positive signed Keychain custody and a production catalog and restore integration. Release signing, notarization, real helper-exit recovery and macOS 26 runtime qualification remain open. The remaining item-level comparisons, including onboarding, populated Arc collections, Mini and Split View visuals and VoiceOver speech, do not have equivalent final-build matched evidence. The three visual measurements cannot support an overall parity score. No complete product or distribution verdict.
