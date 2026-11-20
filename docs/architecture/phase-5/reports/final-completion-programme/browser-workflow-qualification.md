# Installed browser workflow qualification — 2026-11-10

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

The reference column for every new product comparison is **NOT VERIFIED by direct Arc UI observation**. The expectation is associated-item navigation and validated native state changes while preserving the existing private/protected boundary. Procedure and observations are recorded in [installed-ui-observations.json](evidence/installation-01/installed-ui-observations.json); regression results are in [verification](verification.md). No reference parity PASS follows from a bounded Vezham behavior PASS.

## Live Arc follow-up — 2026-11-10

The installed preview verified command entry, sidebar collapse and the corrected keyboard address focus. Relaunch started with an empty private session. [Comparison and evidence](arc-ui-alignment.md).
