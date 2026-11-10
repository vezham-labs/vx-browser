# Native browser qualification

Main and Mini are SwiftUI hosted by AppKit, with WebKit reserved for website content. The workspace and recovery runners use a disposable qualification bundle and owned loopback pages. These runners cover lazy tab admission, split configuration and compact fallback, independent WebKit views, Mini isolation and commit-aware handoff, private retirement, and injected recovery. Per-observation results and exact commands are under verification.

The final Debug candidate passed six live accessibility-tree and pointer/keyboard cases for relaunch, private activation and focus, native address entry, Back and Forward, pinning and Command-T. The initial accessibility update duplicated the tab name. The rebuilt candidate showed a single page title, a separate close label and a pinned value. Reload was invoked without an independent request-count witness. The sidebar toggle was checked on the first build. The previous programme's Mini handoff and workspace sheet observations remain prior-candidate evidence. [Live observation record](evidence/manual-ui.json)

Actual WebKit content process termination remains unexecuted. The runner injects the delegate callback while exercising the real view lifecycle. This environment has no established exclusive attribution of a helper PID to a selected test tab, so killing a WebKit helper would risk affecting another browser. Qualify actual exit on an isolated test account or disposable supported macOS VM after establishing process attribution. Use separate synthetic origins for affected and unaffected tabs and compare old/new bindings, tab identities, website storage and recovery UI across repeated exits.

## Manual interaction checklist

1. Start the exact Debug candidate with the owned loopback fixture. Turn on VoiceOver using the operator's test account. Traverse toolbar, address, workspace menu, tab list and recovery status with keyboard. Record labels, selected and pinned announcements and focus restoration.
2. Create three tabs, move one between groups and Spaces and drag to reorder. Reorder via keyboard/context menu too. Check order, pin state and selection after each action.
3. Split two different loopback pages. Change focus by keyboard and pointer, navigate each pane, drag the divider and resize below the compact threshold. Enlarge again and check the remembered divider and focus. Close one member.
4. Open Mini from a tab. Navigate and independently close a Mini. Repeat using the preview sheet, first cancel and then confirm. Verify the destination tab commits before Mini closes and that website storage stays isolated.
5. Exercise Back, Forward, Reload, Stop, tab closure and Command-T on the signed and Debug candidates. Confirm app activation and reopening behavior. Record source revision, macOS build, display scale, exact action and observed result for every case.

Physical drag/drop, display transitions, and VoiceOver speech remain unqualified unless observed and recorded for the candidate.

## Arc parity follow-up

The disposable UI candidate was exercised through the native accessibility tree and keyboard/pointer interaction. Initial findings and final retests are recorded separately. Native workspace and injected recovery used the stable source candidate. Physical drag and divider gestures, VoiceOver speech, exact Arc comparisons and actual WebKit helper exits remain unqualified. [Native observations](evidence/arc-parity-01/manual-ui.json) · [Screen comparison](ui-ux-qualification.md)
