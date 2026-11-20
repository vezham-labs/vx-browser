# Native drag qualification — 2026-11-10

**PARTIAL implementation; physical acceptance NOT VERIFIED.**

Native SwiftUI row drag payloads carry current private-session ID, item kind and UUID. Drops reject foreign sessions, recovery state, malformed or missing IDs and invalid destinations. Tab moves require the same Space, pinned membership and group. Saved-link moves preserve ID, title and exact associated destination, and adopt the live target's favorite/folder membership. Folder labels accept link drops. Targeted rows show an accent insertion line. No callbacks write protected or unprotected durable storage.

| Operation | Implementation | Actual qualification | Remaining action |
|---|---|---|---|
| Pinned/tab reorder within section | Native row drag/drop | NOT VERIFIED physically; workspace order domain/native cases pass | Drag two distinctly named pinned tabs, confirm URL and order |
| Favorite/bookmark reorder | Native saved row drag/drop | PARTIAL: model cases pass; pointer attempts had no observable result | Inspect drag initiation/destination routing with native instrumentation |
| Link into folder | Folder drop target | NOT VERIFIED: first attempts noWindowsAvailable, renewed attempt unchanged | Confirm live folder target receives payload and insertion feedback |
| Link out of folder / cross favorite-bookmark sections | Drop beside target adopts membership; context menu also available | Model preserves ID/URL; no successful physical movement observed | Test with nonempty targets and verify before/after order |
| Invalid/self/missing target | Model and session/live-target guards | PASS for tested model rejection | Add native foreign-session and cancellation observation |
| Cancellation | No mutation until accepted drop | NOT VERIFIED physically | Drag, Escape, assert unchanged array and URL |
| Tab between Spaces/sections | Context actions exist; row drop rejects cross membership | NOT IMPLEMENTED as drag | Define reference destination behavior then implement explicit targets |
| Groups/collections reorder | Move earlier/later context actions | NOT IMPLEMENTED as drag | Observe Arc reference, implement native collection destinations |
| Ordering after restart | Protected persistence unavailable | NOT IMPLEMENTED in product | Authorized signed WS-F7 writer and restore integration |

The pointer tests are actual CUA `drag` calls. They are not counted as passes: noWindowsAvailable occurred initially; later calls completed but the accessibility tree remained unchanged. One half-scale coordinate retry opened the workspace menu and was dismissed; it provides no drop evidence. Root cause is not established from these results. These observations do not prove a successful native drag or justify claiming a tested ordering guarantee.

[UI observations](evidence/installation-01/installed-ui-observations.json) · [99 Swift cases](evidence/installation-01/core-fixed.stdout.txt). PrivateBookmarkTests includes exact URL association, rename/update identity, invalid website refusal, reorder, self/missing-target rejection and folder movement. These are model cases only.

Additional model evidence: [core-membership](evidence/installation-01/core-membership.stdout.txt) passes favorite cross-section membership, payload preservation, invalid-folder refusal and explicit private-session cleanup (100 total Core cases). Physical status is unchanged.

## Live Arc follow-up — 2026-11-10

A fresh pointer drag in the isolated preview left Favorite tile order unchanged. Physical reorder remains unqualified. [Comparison and evidence](arc-ui-alignment.md).


[Favorite reorder and equal-size Arc captures](arc-drag-follow-up.md) records the updated preview, regression results and remaining interaction and comparison limits.
