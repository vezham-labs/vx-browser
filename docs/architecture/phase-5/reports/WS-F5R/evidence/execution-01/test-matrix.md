# WS-F5R execution case matrix

This matrix updates the 49 baseline cases without modifying the original manifest. PASS_NATIVE rows describe the verified scope in the observation column. An injected callback exercises real AppKit/WebKit retirement and reconstruction, while the trigger itself remains contract evidence. Actual crash-dependent cases stay open. Assertion totals and raw events are in the [native results](callback-run-01/attempt-1/result.json). The [14 stand-in UI checks](playwright.log) are PASS_FAKE_ONLY.

| ID | Case | Status | Observed scope or blocker |
|---|---|---|---|
| PR-01 | Source and lifecycle fence trace | REVIEWED (static finding) | Fence path, closure race and separate teardown owner reviewed. |
| PR-02 | Attribute a disposable WebKit content helper | BLOCKED | Current WebKit helper attribution remains unestablished. |
| PR-03 | Main WebKit content-process termination | NOT_EXECUTED | Actual OS termination was not triggered. R-INJECTED-FENCE is PASS_CONTRACT. |
| PR-04 | Explicit main recovery | NOT_EXECUTED | Injected-trigger subcases PASS_NATIVE for retirement, fresh identity, workspace layout and committed fresh navigation. Real process-exit case open. |
| PR-05 | Explicit Mini recovery | NOT_EXECUTED | Injected-trigger subcases PASS_NATIVE for independent Mini rebuild and fresh navigation. Real process-exit case open. |
| PR-06 | Simultaneous failures | NOT_EXECUTED | Injected simultaneous callbacks PASS_CONTRACT. Two separately retired scopes PASS_NATIVE. Real simultaneous failures open. |
| PR-07 | Old view release and repeated teardown | PASS_NATIVE | R-OLD-RETIREMENT confirms Core state, inventory, authority and weak-reference release after injection. |
| PR-08 | Failed or interrupted reconstruction | PASS_NATIVE | R-RETIREMENT-UNCONFIRMED and R-FAILED-STAGED-PUBLICATION cover a retained view and an invalid reconstruction. Actual mid-construction crash remains open. |
| PR-09 | Fence, session isolation and safe replay | PASS_NATIVE | Fresh nonpersistent stores and absent old cookie and LocalStorage observed. Old reload and navigation denial is PASS_CONTRACT. |
| PR-10 | Workspace and late callback invariants | PASS_CONTRACT | Stale and repeated recovery requests rejected. Workspace layout and split reattachment additionally observed with PASS_NATIVE. |
| DG-01 | Accessibility trust diagnostic | NOT_EXECUTED | Physical primary-button path pending. The prior temporary Swift diagnostic returned false for both checks in its own caller context. |
| DG-02 | Core Graphics event-posting diagnostic | NOT_EXECUTED | Physical primary-button path pending. The prior temporary Swift diagnostic returned false for both checks in its own caller context. |
| DG-03 | Tab reorder | BLOCKED | Physical primary-button path pending. The prior temporary Swift diagnostic returned false for both checks in its own caller context. |
| DG-04 | Group move | NOT_EXECUTED | Physical primary-button path pending. The prior temporary Swift diagnostic returned false for both checks in its own caller context. |
| DG-05 | Space move | NOT_EXECUTED | Physical primary-button path pending. The prior temporary Swift diagnostic returned false for both checks in its own caller context. |
| DG-06 | Pinned-tab behavior | NOT_EXECUTED | Physical primary-button path pending. The prior temporary Swift diagnostic returned false for both checks in its own caller context. |
| DG-07 | Split target | NOT_EXECUTED | Physical primary-button path pending. The prior temporary Swift diagnostic returned false for both checks in its own caller context. |
| DG-08 | Cancellation | NOT_EXECUTED | Physical primary-button path pending. The prior temporary Swift diagnostic returned false for both checks in its own caller context. |
| DG-09 | Invalid drop | NOT_EXECUTED | Physical primary-button path pending. The prior temporary Swift diagnostic returned false for both checks in its own caller context. |
| AX-01 | Native keyboard and AX tree | NOT_EXECUTED | No new native AX audit in this increment. |
| VO-01 | Sidebar navigation | NOT_EXECUTED | Requires observable VoiceOver speech or captions. |
| VO-02 | Tab identification and selection | NOT_EXECUTED | Requires observable VoiceOver speech or captions. |
| VO-03 | Tab context menu | NOT_EXECUTED | Requires observable VoiceOver speech or captions. |
| VO-04 | Spaces and groups | NOT_EXECUTED | Requires observable VoiceOver speech or captions. |
| VO-05 | Split controls | NOT_EXECUTED | Requires observable VoiceOver speech or captions. |
| VO-06 | Mini window | NOT_EXECUTED | Requires observable VoiceOver speech or captions. |
| VO-07 | Command bar | NOT_EXECUTED | Requires observable VoiceOver speech or captions. |
| VO-08 | Focus transitions and announcements | NOT_EXECUTED | Historical VoiceOver attempt was INCONCLUSIVE. No new speech or captions. |
| DL-01 | Existing sandbox destination feasibility | NOT_EXECUTED | Product download lifecycle and destination feasibility remain pending under current entitlements. |
| DL-02 | Successful deterministic attachment | BLOCKED | Product download lifecycle and destination feasibility remain pending under current entitlements. |
| DL-03 | Destination selection | BLOCKED | Product download lifecycle and destination feasibility remain pending under current entitlements. |
| DL-04 | Cancellation | BLOCKED | Product download lifecycle and destination feasibility remain pending under current entitlements. |
| DL-05 | Duplicate names | BLOCKED | Product download lifecycle and destination feasibility remain pending under current entitlements. |
| DL-06 | Failed and interrupted transfer | BLOCKED | Product download lifecycle and destination feasibility remain pending under current entitlements. |
| DL-07 | Hostile suggested filename | BLOCKED | Product download lifecycle and destination feasibility remain pending under current entitlements. |
| DL-08 | Lifecycle cleanup | BLOCKED | Product download lifecycle and destination feasibility remain pending under current entitlements. |
| AU-01 | Synthetic sign-in | PASS_NATIVE | Owned synthetic account signed in through the fixture form. |
| AU-02 | Authenticated redirect | PASS_NATIVE | Expected account URL and authenticated title observed after redirect. |
| AU-03 | Session continuity | PASS_NATIVE | Distinct probe URL committed with the authenticated session. |
| AU-04 | Logout | PASS_NATIVE | Owned fixture logout reached the signed-out state. |
| AU-05 | Main and Mini isolation | PASS_NATIVE | Mini reached signed-out state while main was signed in. Separate LocalStorage and cookie probes also passed. |
| AU-06 | Fresh private session | NOT_EXECUTED | Generic fresh-session marker isolation passed. Authenticated recovery remains untested. |
| AU-07 | External test account workflow | BLOCKED | External environment requires separate owner approval. |
| OS-01 | macOS 26.0 build and launch | NOT_EXECUTED | No real macOS 26 runtime available. |
| OS-02 | Latest supported 26.x build and launch | NOT_EXECUTED | No real macOS 26 runtime available. |
| OS-03 | Native windows and focus | NOT_EXECUTED | No real macOS 26 runtime available. |
| OS-04 | WebKit compatibility | NOT_EXECUTED | No real macOS 26 runtime available. |
| OS-05 | Permission behavior | NOT_EXECUTED | No real macOS 26 runtime available. |
| OS-06 | Regression matrix | NOT_EXECUTED | No real macOS 26 runtime available. |
