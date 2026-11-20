# Vezham native visual remediation

20 November 2026 · macOS 27.2 arm64 · `cross-browser-research`

The third installed iteration reduced exact pixel mismatch from **26.5687% to 26.3378%**, or 10,958 fewer differing pixels. Mean RGB channel error fell **41.27%** and structural similarity rose from **0.91048 to 0.94718**. The native pointer replay verified that Favorites still reorder visibly and open their original destination. The comparison still shows differences in sidebar controls, selection, labels and native materials. [Final side by side](final/side-by-side.png) · [Pointer qualification](pointer-qualification.md)

## Repository and build

Started from a clean `cross-browser-research` checkout at `35a8553b7bdeff8f5b98e296a14fe531fd24c487`. A read-only `git ls-remote origin refs/heads/cross-browser-research` returned the same full commit. The attached workspace was an empty, unborn `timeline` repository, so all implementation used the existing Vezham checkout. The ending HEAD remains at the starting commit, with native source, report and evidence changes in the worktree. No branch switch, commit or push occurred. `timeline` was untouched.

Installed and launched `~/Applications/Vezham Browser UI Preview.app`, version **0.1.0 (1)**, identifier `internal.vezham.browser.ui-preview`. Executable SHA-256 is `0af08b5954436636a05166a18ee6c1018321807eb2423d15ec0318216f99e43c`. The static audit and strict ad hoc signature verification passed. The install retained the preceding bundle for rollback. [Install receipt](test/pass-three-installation.json) · [Running executable and signature](test/installed-identity.txt)

## Comparison conditions

Arc **1.172.1 (90370)** and the Vezham preview displayed one unpinned tab with the same static loopback fixture, in dark appearance, at **2880 × 1648** on the same Retina display. Both sidebars were expanded, both windows used their default isolated Space, and both started with empty pin, Favorite and Bookmark collections. Vezham displays Personal and private status, while Arc displays its incognito status. macOS Window → Centre/Center → Fill supplied the matched frame. Arc’s update badge, the system pointer and traffic-light focus differences are included in the full-window numbers.

Every quantitative run uses the same **byte-identical captured Arc reference**. A fresh Arc recapture returned 2880 × 1644 and is preserved outside the score. All scored captures are full size, aligned at the top left, with a fixed set of regional rectangles and zero masked pixels. In particular, the older **33.25%** public Example Domain comparison used a different page. The new fixed-fixture baseline is **26.5687%**. [Baseline Arc](baseline/arc.jpg) · [Baseline Vezham](baseline/vezham.jpg) · [Final Arc reference](final/arc-fixed-reference.jpg) · [Final Vezham](final/vezham.jpg) · [Supplementary Arc recapture](final/arc-recapture-1644.jpg) · [Fixture](fixture.html)

The comparator decodes the input screenshots in sRGB and uses the absolute RGB channel difference. Exact mismatch counts a pixel if any channel differs. The second threshold counts a pixel if any channel differs by more than 8 levels out of 255. The structural score averages non-overlapping 8 × 8 luminance SSIM blocks. JPEG compression and rasterization contribute small channel differences, so the exact count and absolute error capture different aspects of the result. [Comparator source](compare.swift)

## Visual results

| Metric | Baseline | Final | Change |
| --- | ---: | ---: | ---: |
| Exact RGB mismatch | 26.5687% | 26.3378% | −0.2309 pp |
| Pixels differing in any channel | 1,261,015 | 1,250,057 | −10,958 |
| Any channel difference greater than 8 | 24.8063% | 6.4830% | −18.3233 pp |
| Mean absolute channel error out of 255 | 5.6002 | 3.2887 | −2.3115 |
| Luminance structural similarity | 0.91048 | 0.94718 | +0.03670 |

| Fixed region | Exact mismatch before → after | Mean channel error before → after |
| --- | ---: | ---: |
| Sidebar | 99.708% → 99.707% | 21.780 → 12.778 |
| Navigation and address | 99.669% → 99.665% | 25.657 → 18.660 |
| Workspace and tabs | 99.719% → 99.719% | 20.499 → 10.714 |
| Sidebar footer | 99.686% → 99.685% | 24.551 → 17.461 |
| Main browser area | 4.995% → 4.697% | 0.828 → 0.490 |

[Baseline side by side](baseline/side-by-side.png) · [Baseline overlay](baseline/overlay.png) · [Baseline diff](baseline/pixel-difference.png) · [Baseline metrics](baseline/metrics.json)

[Final side by side](final/side-by-side.png) · [Final overlay](final/overlay.png) · [Final diff](final/pixel-difference.png) · [Final metrics](final/metrics.json)

## Diagnosis and changes

- **Geometry and materials.** The 236-point default sidebar shifted the web viewport and its centered fixture left. At y=500, the Arc viewport reached stable page color at x=654, versus x=495 in the baseline. The resizable 288-point Vezham sidebar moved that edge to x=599. The gap fell from 159 to 55 pixels. A dark slate appearance replaced the material-backed gray sidebar and light mode has a separate surface. A common content-corner token keeps the SwiftUI surface and the AppKit WebKit host aligned. [Measured pixel runs](geometry-pixel-runs.txt)
- **Toolbar and typography.** The sidebar, collapsed toolbar and Mini share the same native back, forward, reload/stop and address views. Symbol buttons gain consistent hit areas and hover/press feedback. Address focus has a visible accent border. The compact address field retains its existing connection indicator and URL. Tabs use explicit 13-point system text, a stronger selected weight and fixed icon alignment. Normal tabs can show the already-provided WebKit favicon, while pinned and split states retain their SF Symbols. [Narrow toolbar](feature-captures/vezham-compact.jpg) · [Vezham Mini](feature-captures/vezham-mini.jpg)
- **Collections and entry.** Link rows and folder labels use consistent minimum heights and truncation. The adaptive Favorite grid has larger tile targets and readable monograms. Native list selection, folder disclosure, context menus and the existing pointer actions still handle interactions. The entry view uses a smaller Vezham mark and centered multiline copy. [Collections](feature-captures/vezham-collections.jpg) · [Entry](feature-captures/vezham-entry.jpg)
- **Iterative correction.** Iteration one improved structural similarity to 0.93617 and mean error to 4.1796, while exact mismatch rose to 27.2051%. Iteration two added the common controls and row treatments, with structural similarity 0.93405 and mean error 4.3004. The third iteration restored the original page gutter after the edge measurements and reduced the luminance of the slate surface. It produced the strongest measured result on all three whole-window metrics. [First iteration](pass-one/metrics.json) · [Second iteration](pass-two/metrics.json)

## Qualification

| Check | Observed result |
| --- | --- |
| Installed pointer replay | Passed the observed Favorite, pin, regular tab, group, Bookmark, folder, cross-section and divider cases. Favorite click loaded the correct fixture. |
| Installed responsive UI | A 1446 × 1648 tiled window retained the active page and readable address controls when the sidebar was hidden. Sidebar expansion restored its width. |
| Installed native workflows | Space creation and switching, command bar, Split View, Split View divider, Mini and Back/Forward all produced the expected UI states. |
| Installed private relaunch | Quit removed the process. The relaunched preview had zero Favorites after starting a fresh private session. |
| Swift Core | Exit 0. **101 tests in 13 suites passed.** |
| Native storage/security | Exit 0. **27 tests in one suite passed.** |
| Workspace qualification | Exit 0. **39 native and 7 contract** passes in one attempt. |
| Recovery qualification | Exit 0. **34 native and 11 contract** passes in one attempt. |
| Browser integration and navigation | Exit 0. **16** legacy integration tests and **4** routing contracts passed. TypeScript check passed. |
| Native build and development audit | Preview and qualification builds succeeded. Static audit and strict installed signature verification passed. |

[Pointer replay](pointer-qualification.md) · [Core](test/core.stdout.txt) · [Storage](test/storage.stdout.txt) · [Workspace](test/native/workspace-summary.json) · [Recovery](test/native/recovery-summary.json) · [Legacy integration](test/legacy-ui.stdout.txt) · [Navigation](test/nav-contracts.stdout.txt) · [Audit](test/pass-three-audit.stdout.txt)

## Remaining gaps and next phase

- **Partially verified visual states.** This quantitative case covers a single loaded tab. Empty, collection, Split View, command and compact states have installed functional or visual witnesses. A compatible Arc isolated fixture for pinned tabs, Favorites and bookmark folders remains unavailable. Hover, pressed, animation and the held-pointer drag indicator were not measured side by side.
- **Differences by priority.** The largest remaining color error is in the navigation/address region. Arc displays a compact host label and a floating command entry, and Vezham exposes a full editable address and a native sheet. Selection, footer, account and collection affordances also differ. [Arc command entry](feature-captures/arc-command.jpg) · [Vezham command entry](feature-captures/vezham-command.jpg)
- **Blocked production features.** The installed private preview uses volatile storage. Durable WS-F7 workspace and Favorite restoration still require admitted protected-profile storage, production integration and signed runtime qualification. Developer ID signing and notarization remain open.
- **Recommended next phase.** Measure toolbar and command entry in loaded, focused, narrow and hidden-sidebar states. Once an isolated reference collection can be prepared, add matched Favorites and pin-heavy layouts to the benchmark. Use the current pointer and recovery checks as regression gates.
