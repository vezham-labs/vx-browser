# Arc-to-Vezham product parity matrix

[Latest installed visual benchmark and drag qualification](evidence/20261120T114710Z-visual-remediation/report.md)

Reference. Installed Arc 1.172.1 build 90370 inspected through bundle metadata on 2026-11-10. The repository static Arc report uses the same version and explicitly lacks runtime observations. The functional comparison uses dated vendor documentation and existing Vezham research. Vendor release notes describe historical behavior and do not establish every detail on the installed build. No private Arc profile or account was opened. Exact visual states remain unverified without an isolated reference session or matched captures.

Sources. [Arc macOS release notes](https://resources.arc.net/hc/en-us/articles/20498293324823-Arc-for-macOS-2024-2026-Release-Notes) · [Arc historical interactions](https://resources.arc.net/hc/en-us/articles/20498377604887-Arc-for-macOS-2023-Release-Notes) · [Arc product feature inventory](https://resources.arc.net/hc/en-us/articles/44413577819159-Arc-Sunset-Frequently-Asked-Questions) · [Arc data export](https://resources.arc.net/hc/en-us/articles/25583851606039-How-Do-I-Export-My-Data-from-Arc) · [Repository workspace research](../cross-browser-research/workspace-and-tab-ux.md)

Rows describe current scope and required verification. No row claims exact parity, and no aggregate percentage is supported. Test references identify the closest available witness and retain its scope.

| # | Feature | Reference behavior | Reference visual evidence | Vezham behavior | Remaining implementation or gap | Native ownership | Automated witness | Manual qualification | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Window and layout | Optional toolbar and collapsible sidebar | Vertical sidebar beside content | Native Main and Mini windows | Match proportions, visibility and restoration | AppKit controller | Bundle and workspace suites | Measure matching screens | Partial |
| 2 | Sidebar | Organizes favorites, pinned and unpinned tabs | Sidebar hierarchy documented | Native resize, hide/show, tabs and Spaces | Qualify width, material and hover states | NativeBrowserChrome | Native workspace suite | Drag and compare at fixed dimensions | Partial |
| 3 | Tabs | Create, close, switch, rename and reorder | Pinned and unpinned rows | Create, close, reorder, group and move | Rename parity, tab switcher and archived tab recovery | WorkspaceLayout and native controller | Core layout and native workspace | Keyboard and drag trajectories | Partial |
| 4 | Spaces | Named, switchable Space tab collections | Sidebar Space presentation documented | Named Spaces and palette lookup | Swipes, themes and durable Space state | WorkspaceLayout and palette | Core and native workspace | Space search, switching and gesture comparison | Partial |
| 5 | Favourites and pins | Favorites and named pinned tabs | Favorites are icon-oriented, pins retain labels | Private pins and temporary bookmarks | Favorites grid, original URL reset and retention | Native sidebar and workspace model | Core pin contracts | Compare pinned and favorite states | Partial |
| 6 | Folders and groups | Pinned folders can nest | Nested sidebar hierarchy | Flat groups with contextual controls | Folder hierarchy and reopen behavior | WorkspaceLayout and native sidebar | Core grouping and move | Compare nesting and menus | Partial |
| 7 | Navigation | Browser history controls and reload | Toolbar can be shown | Back, Forward, Reload, Stop | Navigation error and policy edge coverage | WebKit adapter | Navigation contract and native workspace | Back, Forward, Reload and Stop on fixture | Partial |
| 8 | Address and search | Command bar accepts URL and queries | Exact field geometry unverified | Native address and DuckDuckGo query routing | Provider setup, suggestions and reference geometry | NativeNavigationInput | Swift and legacy navigation tests | Inspect editing and search states | Partial |
| 9 | Command bar | Command-T opens new destinations and searches actions | Reference bar is documented; exact dimensions unverified | Local tab, Space and action search; new-tab navigation | Nonmodal reference interaction, ranking and broader command coverage | Native palette and dispatcher | Native local smoke | Keyboard navigation and visual comparison | Partial |
| 10 | Split View | Independent split tabs with pane focus and drag flows | Split divider and paired tabs documented | Two AppKit panes and compact focus fallback | Drag-to-split, additional layouts and durable URLs | WorkspaceSplitView and layout | Native split and Core tests | Physical divider and focus transitions | Partial |
| 11 | Mini | Little Arc opens quick browsing and sends pages to Main | Compact independent window documented | Isolated Mini with preview and commit-aware URL handoff | Reference placement, multi-tab behavior and activation parity | AppKit controller and WebKit policy | Native Mini cases | Compare independent open, close and handoff | Partial |
| 12 | Onboarding | Import-based suggestions documented in older release notes | Matching first-run captures unavailable | Native welcome, appearance, skip and completion flag | Reference flow, imports and optional search choice | NativeBrowserChrome and preferences | Manual disposable relaunch | Isolated Arc first-run account and Vezham controls | Blocked by missing reference evidence |
| 13 | Menus | App, Spaces and navigation actions documented | Exact menu hierarchy unverified | AppKit App, File, Edit, View, Navigation, Bookmarks, Window, Help | Remaining Spaces and history actions | ApplicationDelegate | Manual AppKit menus | State-aware actions and submenu comparison | Partial |
| 14 | Context menus | Move to Space, folders and tab actions | Grouping and order unverified | Tab and group actions; native website menus | Folder commands, media and download actions | Native sidebar and WebKit delegate | Workspace native cases | Compare menu item order and availability | Partial |
| 15 | Keyboard shortcuts | Command-T and configurable shortcuts | Discoverable menu equivalents | Command-T and Command-K palette, address and navigation shortcuts | Full tab switcher, Space cycling and shortcut settings | AppKit responder path | Manual palette and native focus | Test keyboard-only traversals | Partial |
| 16 | Settings | General, profile, advanced and Chromium settings | Exact settings screens unverified | Native appearance, search disclosure and welcome link | Full capabilities and settings surface | SwiftUI settings and appearance adapter | Native settings smoke | Compare dark, light and system flows | Partial |
| 17 | Downloads | Downloads history and completion controls documented | Downloads view geometry unverified | No download manager | Secure destination selection, permissions and history | WebKit download policy and native UI | No product test | Synthetic download and cancel/resume | Not implemented |
| 18 | History | Chromium browsing history and clearance controls | History screen unverified | Private WebKit navigation history only | Protected browser history and archive | Protected catalog and WebKit | Native navigation only | Signed persistent history test | Not implemented |
| 19 | Bookmarks | Arc uses sidebar pins and Favorites; data export available | Sidebar and export link hierarchy | Session-only bookmarks with folder labels | Durable bookmark and import/export behavior | Private bookmark UI and future protected provider | Manual bookmark actions | Create, search and restart with approved profile | Partial |
| 20 | Profiles and identities | Arc Profiles associate browser data with Spaces | Profile preferences documented | Private scopes only; persistent profile port unavailable | Protected provisioning, switching and access controls | NativeStorageSession and ProtectedCatalog | Keychain negative and isolation tests | Signed profile lifecycle | Partial |
| 21 | Privacy and permissions | Site controls and Chromium clear-data settings | Site settings screen unverified | Native policy gates and private boundary | User-facing per-site management and persistent grants | Native permission coordinator | Storage contracts | Permission prompt and reset on disposable origin | Partial |
| 22 | Extensions and integrations | Chromium extensions and Arc integrations | Pinned extensions on optional toolbar | No extension host | Document WebKit alternatives and capability limits | Engine policy and native chrome | Bundle policy only | Approved extension integration test | Not implemented |
| 23 | Website data | Profile data and clear browsing data controls | Chromium settings surface documented | Nonpersistent WKWebsiteDataStore per private scope | Persistent ownership, browsing data UI and deletion tests | WebKit storage adapter | Private native isolation | Signed cross-profile and clear-data controls | Partial |
| 24 | Session persistence | Sync/export preserves selected sidebar structures | Restored sidebar geometry unverified | Volatile layouts and bounded graph codec | Protected durable storage and app reopen | WorkspaceLayout and protected catalog | Core codec, SQLCipher fixture | Run all 20 product cases under signed authority | Blocked by authorization |
| 25 | Recovery | Detailed current crash-restore behavior unverified | Recovery UI reference missing | Fail-closed private recovery; injected callback qualification | Actual process attribution and durable restoration | Native recovery and journal ports | Native injected recovery | Real exit on isolated VM | Partial |
| 26 | Accessibility | Exact current VoiceOver behavior unverified | Reference AX tree absent | Native AX roles, labels, selection and resize adjustments | Speech, full focus order and reference parity | SwiftUI and AppKit | Manual native AX smoke | VoiceOver with no mouse | Blocked by environment |
| 27 | Animations and feedback | Detailed timings unverified | Reference motion captures absent | System sheet motion and loading indicators | Measure transitions and hover behavior | SwiftUI presentation | Manual inspection | Compare durations and Reduced Motion | Blocked by missing reference evidence |
| 28 | Window management | Multi-window and mini workflows documented | Exact sizes unverified | One Main with independent Mini windows | Multiple normal windows and restoration | ApplicationDelegate and controller | Native Mini lifecycle | Compare activation, multiple displays and restore | Partial |
| 29 | Responsive behavior | Sidebar hide and fullscreen behavior documented | Reference collapse breakpoints unverified | Minimum size, resize handle and compact Split View | Compare breakpoints and fullscreen | Native geometry and AppKit | Native compact fallback | Physical resize and display qualification | Partial |
| 30 | Empty, loading and failure states | Current reference details vary by workflow | Matched captures absent | Welcome, blank private tab, loading and recovery states | Full error and recovery design comparisons | Native browser chrome | Native fixture error cases | Match blank/loading/error fixture screens | Partial |


---

# Installation follow-up — 2026-11-10

Evidence for this follow-up is under [installation-01](evidence/installation-01/). Prior reports and artifacts remain historical. Statuses below describe this candidate, not a production authorization.

| Feature | Status | Actual result / evidence | Remaining gap / next action |
|---|---|---|---|
| Tabs / pinned tabs | PARTIAL | Installed favorite created new tab; Pin context action produced Pinned row; native workspace suite covers ordering. | Arc naming/selection and all keyboard/hover details need reference capture. |
| Favorites | PARTIAL | Saved associated HTTPS destination and opened Example Domain in new tab; stable UUID model. | Current labeled star row differs from documented Arc icon favorites; no direct reference observation. |
| Bookmarks / folders | PARTIAL | Created named Reading folder and Folder example; expanded and opened correct URL. | One level of folders; session-only; no complete Arc collection parity. |
| Space switching | PARTIAL | Created Qualification Space, observed empty enter page, returned to Personal tabs. | Restart and full reference comparison absent. |
| Tab groups / collections | PARTIAL | Existing group context/model support retained. | No new physical group drag or installed group scenario qualified. |
| Command bar / keyboard | PARTIAL | Command-T displayed matching tabs, Space and actions. | Full arrow/Return/VoiceOver and Arc ranking comparison not rerun. |
| Website navigation | PASS | Installed https://example.com/ HTML and address agree for direct, favorite and folder link selection. | PASS is bounded to these observed navigations; complete browser equivalence unclaimed. |
| Back / forward / stop / failures | PARTIAL | Existing navigation suite and native recovery checks passed. | Installed live history chain, loading cancellation and permission prompts not comprehensively exercised. |
| Enter page | PASS | Empty active Space showed Where to? and Search or open a website; inactive welcome showed private-session entry. | No matched Arc visual claim. |
| Split View | PASS | Two loaded website panes appeared; Close Split Screen returned to single pane. | Full resizing/focus matrix remains. |
| Mini browser | PARTIAL | Open in Mini loaded associated URL; native close returned to Main. | Transfer preview/confirm not exercised in this installed smoke run. |
| Onboarding / Settings | PARTIAL | Done closed welcome; Dark selected and System restored in Settings. | Relaunch preference persistence not verified. |
| Context / application menus | PARTIAL | Observed native tab actions and bookmark manager; Pin, Split and Mini actions worked. | Complete menu and site-specific action comparison absent. |
| Drag / section / Space movements | PARTIAL | Validated model moves, current-session native payloads and indicators implemented. | No successful pointer drop; cross-Space/group drag absent. See drag report. |
| Appearance / sidebar geometry | PARTIAL | Native settings and 236-point resizable sidebar exist. | Matched geometry, hover and animation measurement absent. |
| Profiles / isolation | PARTIAL | Private WebKit and recovery qualification passed; normal protected path remains unavailable. | Signed persistent profile isolation cases blocked. |
| History / downloads | NOT IMPLEMENTED | Settings explicitly discloses unavailable persistent history and downloads. | Needs approved durable implementation and lifecycle integration. |
| Website permissions | PARTIAL | Existing permission model guards retained and storage suites passed. | Real camera/microphone/OS grant matrix unqualified; no permission expansion performed. |
| Workspace/bookmark restart restoration | NOT IMPLEMENTED | Private data remains volatile. | WS-F7 authorization, signed custody, production writer and restore integration required. |
| Chromium extension host | NOT IMPLEMENTED | No Chromium extension-host implementation exists in WebKit architecture. | Cannot claim Arc extension compatibility. |
| Pixel-level visual parity | NOT VERIFIED | No equal-dimension reference pair. | Capture matched states and compute overlays/diffs. |
| Distribution readiness | FAIL | Unsigned Release correctly fails production preflight. | Developer ID, notarization, signed runtime qualification and production security integration. |

For every row, direct Arc reference behavior remains NOT VERIFIED; existing vendor documentation is background, not a measured observation of this installation. Evidence and procedures: [installed workflow](browser-workflow-qualification.md), [drag](drag-and-drop-qualification.md), [visual](visual-comparison.md). Expected behavior is correct item/URL identity, native state transitions and preserved security fences.

## Live Arc follow-up — 2026-11-10

Live Arc inspection now informs the sidebar, Favorites, tab and command entry changes. Full workflow parity remains partial. [Comparison and evidence](arc-ui-alignment.md).

## Installed Favorite drag and matched Arc captures — 2026-11-20

The `0.1.0 (1)` UI Preview was rebuilt and audited from working changes on `cross-browser-research` at `5c41c18`. The live reference was Arc `1.172.1 (90370)` in an isolated incognito window. These results apply to the observed states and the installed preview build. [Acceptance report and evidence](evidence/favorite-drag-04/report.md)

| Feature | Current result | Observed evidence and remaining gap |
| --- | --- | --- |
| Favorites | PASS for private-session pointer reorder | IANA moved ahead of Example Domain, the tiles visibly exchanged slots, and a click on the new first tile opened IANA. Reverse reorder and an invalid web-content drop behaved as expected. Arc’s full Favorites workflow remains partial. [Before](evidence/favorite-drag-04/favorites-before.jpg) · [After](evidence/favorite-drag-04/favorites-after.jpg) |
| Tabs and pins | PASS for supported reorder | Installed native pointer gestures reordered pinned, unpinned and same-group tabs. Drops from unpinned and grouped sections onto a pin were rejected. Cross-Space and cross-group gestures remain outside the supported reorder scope. [Pointer witness](evidence/favorite-drag-04/pointer-witness.json) |
| Bookmarks and folders | PASS for supported drops | Pointer reorder at the root and inside Reading, drop onto a collapsed folder, move to root and transfers between bookmarks and Favorites all produced the expected sidebar state. Nested and durable collections remain partial. [Pointer witness](evidence/favorite-drag-04/pointer-witness.json) |
| Sidebar and Split View | PASS for divider drags | Sidebar moved from 236 to 262 points and was restored. Split divider moved from 450.5 to 500.5 points. Appearance and drag-to-split parity remain partial. [Pointer witness](evidence/favorite-drag-04/pointer-witness.json) |
| Relaunch persistence | BLOCKED | Completed a verified quit with reordered Favorites. An ordinary relaunch and fresh private session had zero Favorites. The expected private reset passed. Durable persistence requires an admitted signed protected profile, a production writer and restore integration. [Pointer witness](evidence/favorite-drag-04/pointer-witness.json) |
| Pixel-level visual parity | FAIL for captured state | Both captures are 2880 × 1648 at native size, dark appearance, expanded sidebar, one Example Domain tab. 1,577,895 of 4,746,240 pixels differed (33.25%). The native sidebar sizes, chrome and page alignment differ. [Arc](evidence/favorite-drag-04/arc-1.172.1.jpg) · [Vezham](evidence/favorite-drag-04/vezham.jpg) · [Overlay](evidence/favorite-drag-04/overlay.png) · [Pixel difference](evidence/favorite-drag-04/pixel-difference.png) · [Metrics](evidence/favorite-drag-04/pixel-metrics.json) |
| Qualification and distribution | PASS for development checks | Core passed 101 tests in 13 suites. WS-F6 Workspace recorded 39 native and 7 contract passes. WS-F6 Recovery recorded 34 native and 11 contract passes. The static audit and installed signature verification passed. Production signing, notarization and protected-profile runtime qualification remain open. [Build receipt](evidence/favorite-drag-04/accepted-installation.json) · [Full regressions](evidence/favorite-drag-04/report.md#build-and-regression-evidence) |


## Native visual remediation — 2026-11-20

Audited UI Preview 0.1.0 (1) at base `35a8553` was installed and exercised against the established Arc 1.172.1 (90370) reference. [Full report](evidence/20261120T114710Z-visual-remediation/report.md)

| Feature | Current result | Evidence and remaining gap |
| --- | --- | --- |
| Loaded window and sidebar | IMPROVED | Sidebar default moved from 236 to 288 points. The fixed scanline gap to the Arc web viewport fell from 159 to 55 pixels. Resize and 1446 × 1648 compact layout passed. Arc’s native chrome and Vezham’s slate controls remain visually distinct. [Geometry](evidence/20261120T114710Z-visual-remediation/geometry-pixel-runs.txt) · [Compact capture](evidence/20261120T114710Z-visual-remediation/feature-captures/vezham-compact.jpg) |
| Navigation and tabs | PASS for tested functionality | Native shared controls, Back/Forward, pinned and unpinned reorder and within-group reorder passed. Arc shows a host label, while Vezham retains the full native address. [Installed witnesses](evidence/20261120T114710Z-visual-remediation/installed-ui-witness.json) |
| Favorites, Bookmarks and folders | PASS for tested pointer gestures | Reorder and opening of a moved Favorite passed. Bookmark and folder reorder, root movement and Favorite conversion passed. Matched populated Arc collections remain open. [Pointer results](evidence/20261120T114710Z-visual-remediation/pointer-qualification.md) |
| Entry, command bar and split | PARTIALLY VERIFIED | Installed entry, command, Mini and split captures plus functional resize and Space switching. Arc used a floating command entry and Vezham used a native sheet. [Feature captures](evidence/20261120T114710Z-visual-remediation/feature-captures/) · [Installed witnesses](evidence/20261120T114710Z-visual-remediation/installed-ui-witness.json) |
| Pixel parity | FAIL for exact match, measurable improvement | Same reference, no masking, exact RGB mismatch 26.57% → 26.34%, mean error 5.60 → 3.29, SSIM 0.91048 → 0.94718. [Overlay](evidence/20261120T114710Z-visual-remediation/final/overlay.png) · [Difference](evidence/20261120T114710Z-visual-remediation/final/pixel-difference.png) · [Metrics](evidence/20261120T114710Z-visual-remediation/final/metrics.json) |
| Protected persistence and signing | BLOCKED for production | Ordinary preview relaunch cleared Favorites. Core, storage and both native suites passed in their development scope. WS-F7 durable qualification, Developer ID and notarization remain open. [Regression results](evidence/20261120T114710Z-visual-remediation/report.md#qualification) |

## Installed floating command bar and pointer replay — 20 November 2026

[Installed qualification and matched visual results](evidence/20261120-command-retry/report.md) · [Item-level coverage](observable-coverage.md)

Private saved-link search, native keyboard focus, arrows, Return, Escape, outside dismissal and tested sidebar gestures passed on the installed Preview. Expanded sidebar, collapsed sidebar and floating command states now have matched Arc captures, overlays and differences. Durable workspace restoration and release signing remain blocked.

## Spaces, session search and responsive command panel — 20 November 2026

Space ordering and cycling, private search choices, tab menu actions, visible Favorite reorder and private reset have installed evidence. Five matched states now include the narrow window and typed narrow command bar. Full product parity remains incomplete. [Results and evidence](evidence/20261120-spaces-search/report.md)

## Arc 2 installed drag and navigation retry

Four matched visual states, pointer acceptance, private reset, address-routing validation and the latest build identity are recorded in the [installed qualification](evidence/20261120-address-routing/report.md). Durable restoration and pixel parity remain open.
