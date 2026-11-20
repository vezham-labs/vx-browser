# Installed Spaces, search and command panel qualification

November 20, 2026. The checkout and live remote matched at ac22c4bef8e76af3285bcbcde993381d7567d8f2. Earlier uncommitted chrome and evidence changes were present at the start. All work used cross-browser-research. No commit, push or branch switch occurred.

## Implementation and installed observations

1. WorkspaceLayout could reorder workspaces and groups but lacked an operation for Spaces. The new bounded move preserves the existing Space object, ID, active selection and tab membership inside the current workspace. The sidebar disables moves past either edge. The Spaces menu cycles with Option-Command-[ and Option-Command-]. In a disposable two-Space session, moving Reading earlier kept Reading selected and both shortcuts returned the expected Space. A new model regression also covers a foreign ID, unsupported offset, no-op revision and codec round trip.
2. Private search previously hard-coded DuckDuckGo. The private window now offers DuckDuckGo, Google and addresses only. Only the typed in-memory selection is retained during the mount. The URL parser encodes literal plus signs and keeps direct URL policy independent of provider. The installed command bar suppressed the web result in addresses-only mode. The Google selection exposed it. Exact provider URL generation was verified locally in Core, without submitting any test terms to either engine. Settings now precedes the web fallback for its matching query.
3. The Tabs menu exposes previous/next, duplicate and pin using the existing native commands. Shift-Command-[ and Shift-Command-] selected different loaded URLs. Duplicate produced a second independent logical tab on the same fixture. The pin action changed its sidebar section. [First installed pass](ui.json) · [Tabs acceptance](ui2.json)
4. A 640-point material panel had a weaker selected-row contrast and smaller width than the Arc reference. The design now uses a 760-point preferred content width, a solid adaptive surface, stronger selection and a dismiss control in the header. A second installed pass showed that the preferred width expanded a narrow 1442-pixel tiled capture to 1600 pixels. The final controller constrains the hosting view to the actual window width and updates the constraint on resize. After macOS tiling settled, the final closed and reopened captures both measured 1440 × 1648. [Earlier narrow palette](narrow-search.jpg) · [Final closed](last-tile-stable.jpg) · [Final reopened](last-tile-reopened.jpg)
5. On the final installed binary a genuine pointer drag moved Navigation Bravo into the first Favorite slot. The saved identities were unchanged. Clicking that slot from Navigation Charlie opened Bravo's original URL. Quit removed the installed process. Relaunch showed inactive startup and then an empty private session with the default provider. [Pointer before](last-favorites-before.jpg) · [Pointer after](last-favorites-after.jpg) · [Exit](quit3.txt) · [Final UI observations](ui3.json)

## Visual results

The reference is Arc 1.172.1 (90370) incognito and the candidate is the installed UI Preview. Both used dark appearance and the same single loopback fixture. Full-size comparisons reuse the three immutable Arc captures from the previous pass. The two narrow references were captured during this pass. Both apps used system tiling. Each scored pair has identical native pixel dimensions. The typed narrow state used the query Settings in both apps. Result sources, selection, chrome and focus indicators remain included. JPEG captures were decoded without crop, scaling or masks. For narrow frames the comparator retains the same sidebar regions and includes partial edge blocks in SSIM. Equal-dimension checks reject unmatched pairs.

| State | Native size | Exact mismatch | Any channel above 8 | Mean error / 255 | Luma SSIM |
|---|---:|---:|---:|---:|---:|
| [expanded](expanded/side-by-side.png) | 2880 × 1648 | 26.2786% | 6.4189% | 3.3225 | 0.94708 |
| [collapsed](collapsed/side-by-side.png) | 2880 × 1648 | 10.5502% | 4.0573% | 1.2707 | 0.97377 |
| [command](command/side-by-side.png) | 2880 × 1648 | 61.5370% | 11.9636% | 7.4542 | 0.89719 |
| [narrow](narrow/side-by-side.png) | 1442 × 1648 | 49.7567% | 13.0703% | 6.6663 | 0.89337 |
| [narrow-search](narrow-search/side-by-side.png) | 1440 × 1648 | 80.8147% | 24.0968% | 12.3338 | 0.82646 |

The previous full-size command result was 61.6007% exact mismatch, 29.1170% above 8, mean error 9.6519 and SSIM 0.88408. The revised panel improves the threshold and average errors more than the exact-match count. Typed narrow search has the largest remaining difference. Each state directory includes both original images, metrics by region, overlay, absolute difference and side-by-side output.

## Build and regressions

The final installed internal.vezham.browser.ui-preview is version 0.1.0 (1), ad hoc signed, with executable SHA-256 7811dcdc0b8ab99d75519c2c98d4ccf9ab5497f5d1eaee2deccc0bc2aaf343e6. Strict signature and bundle checks passed. The installer retained the previous bundle. [Install receipt](install3.json) · [Bundle audit](audit3.log) · [Build](build3.log) · [Commands](commands.json)

Core passed 103 tests in 13 suites and storage passed 27 tests in one suite. Workspace recorded 39 native and 7 contract passes. Recovery recorded 34 native and 11 contract passes. Legacy UI passed 16 and navigation passed 4. TypeScript passed. No failures were reported by those suites. The native workspace and recovery runners used the distinct Debug qualification bundle. Requested durable production cases remain outside these counts.

## Open gates

The installed path handles volatile private workspaces. SQLCipher production admission, positive signed Keychain custody and production save/restore integration remain open. Appearance continues to use the existing allowlist. Full first-run, populated collection, Split View, Mini, Light and other reference comparisons remain outstanding. This run sampled Arc menus, excludes personal entries from the labels recorded and does not qualify every menu. Tab and Space navigation, palette sizing and search choices are implemented within the bounds described above. Production signing, release OS qualification, VoiceOver speech, and complete feature parity remain unqualified.
