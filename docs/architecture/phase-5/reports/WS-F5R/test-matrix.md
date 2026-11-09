# WS-F5R qualification case matrix

Sequence: establish the record, investigate recovery and review the architecture boundary, run bounded recovery qualification, conduct physical drag and VoiceOver, investigate sandbox downloads, exercise owned synthetic auth, and run the platform matrix when a compatible environment is available.

PASS_NATIVE requires observed AppKit, WebKit or actual OS behavior on the identified candidate. PASS_CONTRACT covers contract assertions and PASS_FAKE_ONLY covers substitutes. A source finding carries no runtime pass. Record observed contrary behavior as FAIL, missing attribution or evidence as INCONCLUSIVE, unmet prerequisites as BLOCKED, and unrun cases as NOT_EXECUTED. A candidate-level claim requires all applicable case assertions on that candidate.

| ID | Case | Execution mode | Required evidence | Status |
|---|---|---|---|---|
| PR-01 | Source and lifecycle fence trace | Static | Trace callback, poison, grants, Core close and retirement, host states | REVIEWED (static finding) |
| PR-02 | Attribute a disposable WebKit content helper | Automated | Exact candidate and helper executable, process identity and ownership rechecked at signal time | BLOCKED |
| PR-03 | Main WebKit content-process termination | Automated | Real OS termination, live host, callback, denied navigation and hidden fenced surfaces | NOT_EXECUTED |
| PR-04 | Explicit main recovery | Automated + native action | Fresh private scope and view, admitted GET commit, retained permitted workspace structure, old scope still fenced | NOT_EXECUTED |
| PR-05 | Explicit Mini recovery | Automated + native action | Fresh Mini scope, committed page, no cross-window storage or focus mutation | NOT_EXECUTED |
| PR-06 | Simultaneous failures | Automated | Individually attributed helpers or documented shared-process effect, bounded recovery, no duplicates | NOT_EXECUTED |
| PR-07 | Old view release and repeated teardown | Automated | Zero adapter-owned old views, detached hierarchy, old references released, outstanding actions settled | NOT_EXECUTED |
| PR-08 | Failed or interrupted reconstruction | Automated | Abort new admission, retire partial replacement, old scope remains fenced, bounded terminal result | NOT_EXECUTED |
| PR-09 | Fence, session isolation and safe replay | Automated | No old grants/data or unsafe request replay, no default or persistent store, unrelated scope untouched | NOT_EXECUTED |
| PR-10 | Workspace and late callback invariants | Automated + native action | Stable logical order, pins, groups, Spaces, selection/split mapping, stale callback rejection | NOT_EXECUTED |
| DG-01 | Accessibility trust diagnostic | Read-only preflight | Independent result and caller context | NOT_EXECUTED |
| DG-02 | Core Graphics event-posting diagnostic | Read-only preflight | Independent result and caller context | NOT_EXECUTED |
| DG-03 | Tab reorder | Physical pointer | Exact native ID order before and after | BLOCKED |
| DG-04 | Group move | Physical pointer | Source and destination membership and row placement | NOT_EXECUTED |
| DG-05 | Space move | Physical pointer | Source/destination Space membership and valid selection | NOT_EXECUTED |
| DG-06 | Pinned-tab behavior | Physical pointer | Expected pin state and order | NOT_EXECUTED |
| DG-07 | Split target | Physical pointer | Correct logical tab and two active native views | NOT_EXECUTED |
| DG-08 | Cancellation | Physical pointer | Tab organization and selection consistent, drag state cleared | NOT_EXECUTED |
| DG-09 | Invalid drop | Physical pointer | Rejected target, unchanged relevant state, next gesture works | NOT_EXECUTED |
| AX-01 | Native keyboard and AX tree | Native keyboard + AX | Named and focused controls, no screen-reader claim | NOT_EXECUTED |
| VO-01 | Sidebar navigation | Human-assisted VoiceOver | Speech/caption and reachable landmarks or controls | NOT_EXECUTED |
| VO-02 | Tab identification and selection | Human-assisted VoiceOver | Speech/caption for name and selection state, actual selection | NOT_EXECUTED |
| VO-03 | Tab context menu | Human-assisted VoiceOver | Speech/caption for actions, dismissal and returned focus | NOT_EXECUTED |
| VO-04 | Spaces and groups | Human-assisted VoiceOver | Speech/caption for switch and expand/collapse states | NOT_EXECUTED |
| VO-05 | Split controls | Human-assisted VoiceOver | Speech/caption for pane actions and focus handoff | NOT_EXECUTED |
| VO-06 | Mini window | Human-assisted VoiceOver | Speech/caption for window context, controls and focus return | NOT_EXECUTED |
| VO-07 | Command bar | Human-assisted VoiceOver | Speech/caption for search, results, actions and dismissal | NOT_EXECUTED |
| VO-08 | Focus transitions and announcements | Human-assisted VoiceOver | Speech/caption with expected active control after each transition | NOT_EXECUTED |
| DL-01 | Existing sandbox destination feasibility | Native + static audit | Same entitlements, panel scope, observed authorized and denied destinations | NOT_EXECUTED |
| DL-02 | Successful deterministic attachment | Native + automated | Transfer callbacks and exact expected byte count and SHA-256 | BLOCKED |
| DL-03 | Destination selection | Native save panel | Explicit selection and validated destination, no automatic open | BLOCKED |
| DL-04 | Cancellation | Native save panel + automated | Terminal cancel, no file or partial artifact | BLOCKED |
| DL-05 | Duplicate names | Native save panel + automated | Sentinel remains byte-identical, no silent overwrite | BLOCKED |
| DL-06 | Failed and interrupted transfer | Native + automated | Bounded failure and cleanup of partial files | BLOCKED |
| DL-07 | Hostile suggested filename | Native + automated | No path escape or unintended destination | BLOCKED |
| DL-08 | Lifecycle cleanup | Native + automated | Exactly one terminal event, no orphaned file, operation or grant | BLOCKED |
| AU-01 | Synthetic sign-in | Owned loopback fixture | Dedicated fixture account accepted, protected marker visible | NOT_EXECUTED |
| AU-02 | Authenticated redirect | Owned loopback fixture | Expected origin and authenticated destination | NOT_EXECUTED |
| AU-03 | Session continuity | Owned loopback fixture | Reload and same-scope navigation retain valid session | NOT_EXECUTED |
| AU-04 | Logout | Owned loopback fixture | Session invalidated, protected resource denied | NOT_EXECUTED |
| AU-05 | Main and Mini isolation | Owned loopback fixture | Independent cookie and website-data observations before and after transfer | NOT_EXECUTED |
| AU-06 | Fresh private session | Owned loopback fixture | No previous cookies, storage or auth state | NOT_EXECUTED |
| AU-07 | External test account workflow | Approved external environment | Dedicated account and named allowed workflow | BLOCKED |
| OS-01 | macOS 26.0 build and launch | Actual 26.0 environment | Candidate and toolchain identity, actual process launch | NOT_EXECUTED |
| OS-02 | Latest supported 26.x build and launch | Actual 26.x environment | Candidate and toolchain identity, actual process launch | NOT_EXECUTED |
| OS-03 | Native windows and focus | Actual 26 environments | Main, Mini and Split Screen observations per OS | NOT_EXECUTED |
| OS-04 | WebKit compatibility | Actual 26 environments | Exact WebKit version and committed fixtures per OS | NOT_EXECUTED |
| OS-05 | Permission behavior | Actual 26 environments | Observe applicable native prompts and fail-closed policies per OS | NOT_EXECUTED |
| OS-06 | Regression matrix | Actual 26 environments | Revision-specific native, contract and stand-in results per OS | NOT_EXECUTED |

Every run records date, host, OS and architecture, candidate identity, source and resource hashes, method, fixtures, raw logs, assertions, outcome and cleanup. Preserve failures and separate candidate revisions. Scope ambiguous WebKit helper attribution to an observation and stop before signalling. Preserve historical manifests and verify WS-F5R artifacts with the local manifest.
