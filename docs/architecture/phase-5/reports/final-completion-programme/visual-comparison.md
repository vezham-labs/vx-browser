# Visual comparison — 2026-11-10

**NOT VERIFIED: pixel parity for all 20 requested states.**

Arc metadata confirms 1.172.1 build 90370. Reference UI access previously returned an explicitly stopped session; matched reference captures are absent. Installed Vezham screenshots were displayed by CUA in chat at 2360 × 1584, including loaded Example Domain, Favorites, expanded Reading folder, pinned and ordinary tabs. The API did not return a local image export. No PNG path, overlay or difference file is invented.

| Requested state | Matched Arc/Vezham pair | Status |
|---|---|---|
| First launch/welcome | Absent | NOT VERIFIED |
| Main browser window | Absent | NOT VERIFIED |
| Expanded sidebar | Absent | NOT VERIFIED |
| Collapsed sidebar | Absent | NOT VERIFIED |
| Pinned tabs | Absent | NOT VERIFIED |
| Favorites | Absent | NOT VERIFIED |
| Bookmarks | Absent | NOT VERIFIED |
| Bookmark folders | Absent | NOT VERIFIED |
| Spaces | Absent | NOT VERIFIED |
| Tab groups | Absent | NOT VERIFIED |
| Active tab | Absent | NOT VERIFIED |
| New-tab/enter page | Absent | NOT VERIFIED |
| Command bar | Absent | NOT VERIFIED |
| Split View | Absent | NOT VERIFIED |
| Mini browser | Absent | NOT VERIFIED |
| Settings | Absent | NOT VERIFIED |
| Contextual menus | Absent | NOT VERIFIED |
| Application menus | Absent | NOT VERIFIED |
| Navigation controls | Absent | NOT VERIFIED |
| Empty/error states | Absent | NOT VERIFIED |

No matching display scale, window dimensions, appearance, theme, sidebar width and content-state pair has been established. The current native token values are toolbar 70 pt, footer 28 pt, sidebar 236 pt (180–320), horizontal padding 14 pt and controls radius 9 pt. These describe Vezham, not measurements from Arc.

Remaining procedure: obtain both app captures for each row on the same display and window geometry; save original PNGs and geometry metadata; compare equal dimensions only; create alpha overlays and absolute-pixel differences with a conventional image tool; record typography, spacing, colors, icons, hover/selected states and animations separately. Do not infer pixel-perfect parity from a visual impression or documented Arc behavior.

## Live Arc follow-up — 2026-11-10

Live captures are available in the chat. Their dimensions differ, so the pixel overlay and difference checks remain pending. [Comparison and evidence](arc-ui-alignment.md).


[Favorite reorder and equal-size Arc captures](arc-drag-follow-up.md) records the updated preview, regression results and remaining interaction and comparison limits.
