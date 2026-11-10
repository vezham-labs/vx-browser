# Visual and behavioral qualification

The reference version was verified statically. The release notes support behavior comparisons. Matched screen geometry, typography, color, shadows, radii, exact positions and motion remain unmeasured. Older Vezham screenshots under WS-F4R predate the active SwiftUI shell and cannot substitute for the current candidate. Current native smoke observations are linked from verification.

| Screen | Reference evidence | Vezham surface | Exact visual parity |
| --- | --- | --- | --- |
| First launch | Missing matching Arc account setup | Native welcome and skip | Unverified |
| Main window | Optional Arc toolbar documented | SwiftUI toolbar over AppKit website surface | Unverified |
| Sidebar expanded | Arc vertical sidebar documented | Resizable native list | Unverified |
| Sidebar collapsed | Arc concealment documented | Native toggle | Unverified |
| Tab selected | Exact reference styling unavailable | Native selected row | Unverified |
| Tab hover | Motion and styling unavailable | System hover behavior | Unverified |
| Pinned tab | Pinned label and favorites distinction documented | Pinned native section | Unverified |
| Group | Nested reference folders documented | Flat native group | Unverified |
| Space switcher | Named Spaces documented | Picker and command results | Unverified |
| Address/search | Arc toolbar and command bar documented | Native field and private navigation | Unverified |
| Command bar | Command-T flow documented | Native sheet with keyboard results | Unverified |
| Split View | Split and drag actions documented | Two native website panes | Unverified |
| Mini | Little Arc quick flow documented | Native isolated Mini | Unverified |
| Context menu | Several actions documented | Native tab/group actions | Unverified |
| Application menu | Exact arrangement unavailable | Native state-aware menu | Unverified |
| Settings | Arc categories documented | Appearance and welcome | Unverified |
| Onboarding | Current matched walkthrough absent | Native first-run welcome | Unverified |
| Downloads | Downloads history documented | Product manager unavailable | Unverified |
| History | Chromium history documented | Persistent browser history unavailable | Unverified |
| Privacy settings | Clear browsing data documented | Private mode and protected-profile status | Unverified |
| Empty state | Matched capture unavailable | Start private or open address | Unverified |
| Error state | Matched capture unavailable | Native failure and recovery feedback | Unverified |
| Dark appearance | Matched capture unavailable | System dark or explicit Dark | Unverified |
| Light appearance | Matched capture unavailable | System light or explicit Light | Unverified |


For a paired visual run, launch both candidates with separate disposable profiles on the same macOS appearance, resolution and display scale. Set each window to 1180 × 760 content points and load the same owned local page. Capture expanded and collapsed sidebar, selected and hovered rows, pin and group sections, Space selector, command bar, Split View, Mini, menus, Settings and both appearance modes. Record point dimensions, control baselines, font samples, semantic colors and motion. Capture the first-run state on clean isolated profiles. If the Arc account is unavailable, use dated authorized screenshots and record the exact state that could not be replayed.

Use the [native qualification report](native-qualification.md) for VoiceOver and physical input procedures and the [design system](design-system.md) for Vezham values.
