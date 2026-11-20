# Vezham Favorite drag acceptance

20 November 2026 · macOS 27.2 arm64 · `cross-browser-research` at `5c41c18eb043c02183ab016484ea4f8628ff48f9`

**Installed Favorite reorder passed.** A pointer drag moved IANA ahead of Example Domain. The two tile labels visibly exchanged slots, their IDs and URLs followed the tiles, and clicking the new first slot opened IANA. Reversing the drag restored the original order. Private relaunch cleared the fixtures. The equal-dimension visual comparison found material differences.

[Before capture](favorites-before.jpg) · [After capture](favorites-after.jpg) · [Pointer steps and observed UI states](pointer-witness.json)

## Root cause and fix

The earlier logical-point drag landed in the address area because the Computer Use surface takes screenshot pixels. The correctly scaled drag went from screenshot pixels (179, 220) to (65, 220), equivalent to approximately (90, 650) to (32, 650) in AppKit’s bottom-left window coordinates. The baseline trace shows pointer-down, motion, creation of a session-scoped link payload and pointer-up. SwiftUI reported target entry after pointer-up, and the saved-link drop callback never fired. The existing domain reorder function was downstream of that failure. [Baseline pointer trace](baseline-pointer.txt)

The first window-tracking candidate exposed a separate hit-testing problem. Its diagnostic trace shows the source anchor was 50.5 × 44 points, while its SwiftUI-provided visible rectangle covered 1180 × 760 points. At the destination, the source-local point was (-32, 22). The oversized clipping rectangle still accepted it, so the destination resolved to the source and the drop was rejected. The corrected hit test intersects each anchor’s own bounds with its clipping rectangle. [Native geometry trace](native-pointer.txt)

The installed fix tracks a real left-button drag in AppKit’s window event path. Pointer-down records the typed item identity with the active session and Space. Motion past four points resolves a live target and updates the target outline or before/after insertion line. Pointer-up revalidates the destination, clears the indicator and calls the existing move operation. Bookmark moves update the published private bookmark state and SwiftUI renders the stable link IDs in the new order. Tab moves use the existing native bridge `.move` action and workspace layout, then render the returned native state. Favorite tiles display the first two characters of their titles so the normal UI exposes the order visually. The pointer gesture stays in the current window and session, with no URL transfer or pasteboard payload. The mid-drag indicator was inspected in code. The pointer tool captures the UI after release, so the evidence contains no held-pointer indicator frame.

## Installed pointer results

All 19 drag gestures below and in the witness used Computer Use’s native coordinate drag against the installed preview. The harness used accessibility readings as observations and ordinary app controls to create disposable fixtures. [Pointer steps and observed UI states](pointer-witness.json)

| Interaction | Observation |
| --- | --- |
| Favorites | Second to first and first to second both changed the visible order. Clicking the moved tile opened its original URL. A final drag restored the changed order before quit. |
| Pinned, unpinned and grouped tabs | Changed the visible row order in each of the three supported sections. |
| Bookmark rows and folders | Reordered ordinary rows and children of Reading. Dropped a bookmark onto the collapsed folder label, checked it inside after expansion, then moved it back to the root beside another bookmark. |
| Bookmark and Favorite conversion | Promoted a root bookmark and a folder child onto Favorite tiles. Dropped a Favorite onto an ordinary bookmark and onto a folder label. |
| Rejected destinations | Web content, unpinned-to-pinned and grouped-to-pinned drops left their observed orders intact. |
| Other native drag controls | Sidebar divider moved from 236 to 262 points and was restored to 236. Split divider moved from 450.5 to 500.5 points. |
| Quit and relaunch | Quit with IANA first and confirmed the process exited. Relaunch showed inactive private browsing and no restore state. A new private session contained zero Favorites. |

The preview’s **private reset passed**, and **order persistence remains blocked**. Favorites are held in volatile `PrivateBookmarks`, and the product reports that protected profiles are unavailable. Durable acceptance requires an admitted signed protected profile, production writer and restore integration. The preview continues to use its existing private storage, authorization and development signing boundaries.

## Build and regression evidence

Installed application. `~/Applications/Vezham Browser UI Preview.app`, version `0.1.0 (1)`, bundle ID `internal.vezham.browser.ui-preview`. Executable SHA-256 `531a6565f60e7c25322a167141cd7256720c12a150937bcab3166b32137e7b19`. The rebuilt app passed the repository’s static preview audit before reinstall. The installed executable matched the audited artifact and passed strict code-signature verification. [Installation receipt](accepted-installation.json) · [Runtime path and signature](running-builds.txt) · [Audit](accepted-audit.stdout.txt)

| Suite or check | Exact result |
| --- | --- |
| Swift Core | Exit 0. 101 tests in 13 suites passed. |
| WS-F6 Workspace | Exit 0. `PASS_NATIVE`, 39 native and 7 contract event observations in one attempt. |
| WS-F6 Recovery | Exit 0. `PASS_NATIVE`, 34 native and 11 contract event observations in one attempt. |
| Preview and qualification builds | Both succeeded, exit 0. |
| Static preview audit | Passed, exit 0. |

[Core log](core.stdout.txt) · [Workspace summary](accepted-workspace.stdout.txt) · [Recovery summary](accepted-recovery.stdout.txt) · [Preview build](accepted-build.command.json) · [Qualification build](accepted-qualification-build.command.json)

## Visual comparison

Arc **1.172.1 (90370)** and the installed Vezham preview were captured in their incognito or private windows with dark appearance, sidebar expanded and one tab on `https://example.com/`. The same macOS Window → Fill command produced **2880 × 1648** native screenshots on the same Retina display. Each browser retained its native sidebar width. The whole-window measurements include page rendering, cursors and JPEG capture effects. [Arc capture](arc-1.172.1.jpg) · [Vezham capture](vezham.jpg)

**Pixel parity failed for this state.** Of 4,746,240 pixels, 1,577,895 (33.25%) differed in at least one RGB channel, and 1,338,342 (28.20%) had a channel difference greater than 8 out of 255. Mean absolute channel difference was 9.247 levels out of 255. Inputs were decoded into sRGB at their original size. The overlay uses an equal channel blend and the difference image uses absolute per-channel differences. Sidebar proportions, chrome placement, controls and rendered content alignment differ. [Overlay](overlay.png) · [Pixel difference](pixel-difference.png) · [Metrics](pixel-metrics.json) · [Comparison source](compare.swift)

Protected-profile persistence and full Arc parity remain open. Developer ID release signing and notarization remain outside this development preview’s qualification.
