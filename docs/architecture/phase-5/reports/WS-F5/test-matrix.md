# WS-F5 test matrix

| Case family | Status | Evidence and boundary |
|---|---|---|
| URL-OS-COLD, URL-OS-WARM, URL-WRAPPER-OS | PASS_NATIVE | [Cold final batch](evidence/final-interactive-open.json), [warm delivery during edit](evidence/observations/final-external-edit.json), [Mini open](evidence/final-mini-open.json) and [Mini closure](evidence/observations/final-mini-shortcut-closed.json) |
| URL-DEFAULT-HTTP, URL-DEFAULT-HTTPS | PASS_NATIVE | [Committed destinations and exact handler restoration](evidence/final-default-routing.json) |
| URL policy positives and malformed/unsupported inputs | PASS_CONTRACT | 13 checks per final native launch, [case results](evidence/native-04/attempt-1/result.json) |
| URL redirect, back, forward and Mini transfer | PASS_NATIVE | [Actual WebKit navigation](evidence/native-04/attempt-1/result.json), [interactive Mini transfer on build 06](evidence/observations/mini-transfer.json) |
| OS delivery of hostile schemes and cross-scheme redirects | NOT_EXECUTED | Parser contract and owned normal redirect tested |
| DRAG-REORDER | BLOCKED | [Primary driver exit 78](evidence/primary-reorder-01.json). Prior gesture observations INCONCLUSIVE. |
| DRAG-GROUP, DRAG-SPACE, DRAG-PIN, DRAG-SPLIT, DRAG-CANCEL, DRAG-INVALID | NOT_EXECUTED | Primary-button path unavailable |
| LIFE windows, views, panes, Mini, cleanup, navigation recovery | PASS_NATIVE | [Final native suite](evidence/native-04/summary.json), [actual Mini shortcut](evidence/observations/final-mini-shortcut-closed.json) |
| LIFE earlier Mini ⌘W | FAIL on build 06 | [Empty Mini](evidence/observations/mini-shortcut-empty-failure.json), resolved and requalified on build 07 |
| LIFE content-process crash and prolonged leak soak | NOT_EXECUTED | Bounded object release and connection failure recovery covered |
| AX keyboard, labels, roles and modal smoke | PASS_NATIVE, scoped | [Keyboard](evidence/observations/native-keyboard.json), [final palette](evidence/interactive-closeout.json). Full native contextual menu walkthrough remains open. |
| AX-VOICEOVER | INCONCLUSIVE | Process confirmed. Observable speech/captions unavailable. |
| COMP-PUBLIC | PASS_NATIVE, public smoke | [Six final loaded tabs](evidence/observations/final-public-pages.json) |
| COMP target-blank, Mini separation and URL transfer | PASS_NATIVE, owned fixtures | [Final suite](evidence/native-04/attempt-1/result.json), [earlier actual click](evidence/observations/target-blank-pointer.json) |
| COMP synthetic auth/download denial path | INCONCLUSIVE | [Observed endpoint state](evidence/observations/unsupported-auth-download.json) |
| COMP account workflows and successful downloads | BLOCKED | Access restriction and unsupported file lifecycle |
| PLATFORM actual macOS 26 and final release | DEFERRED | [Platform boundary](platform-qualification.md) |
| TypeScript build/type checks and bundle audit | PASS_CONTRACT | [Type check](evidence/reliability-typecheck-05.json), [audit](evidence/bundle-audit-final.json) |
| Stand-in React UI | 12 PASS_FAKE_ONLY | [Serial final run](evidence/reliability-ui-06.log) |
| Existing Swift regression | 23 PASS_CONTRACT, 2 PASS_FAKE_ONLY | [Runner log](evidence/swift-regression.log). Earlier source snapshot. |
| TypeScript URL/search contract | 4 PASS_CONTRACT | [Contract log](evidence/reliability-contracts-01.log) |

Final native runner counts are **84 PASS_NATIVE and 26 PASS_CONTRACT** across two independent launches of the same final binary. The terminal suite event is excluded. Earlier revisions, interactive observations and stand-in runs are separate. [Revision ledger](evidence/revision-ledger.json)

Preserved failures include the initial Swift actor-isolation build error, a TypeScript key typing failure, editor focus escape, a disabled command in test setup, the Mini shortcut defect, and an unchanged Settings assertion that timed out during concurrent execution. The latter passed on a serial rerun. The driver compile failure was followed by successful compilation and the OS permission block. Fixture service shutdowns retain their interrupted runner records.
