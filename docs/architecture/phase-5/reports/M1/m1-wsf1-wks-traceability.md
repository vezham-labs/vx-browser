# WS-F1 WKS traceability

2026-11-09. Overlay only: all40 original definitions, mappings and historical outcomes are preserved verbatim in [machine-readable dispositions](../../evidence/20261108T234332Z-webkit-storage-wsf1/wks-dispositions.json). Original source is the committed WS-F0 overlay; no PQR/AC/EXP is closed.

Whole-case overlay: **4 PASS_FAKE_ONLY,1 PASS_CONTRACT,35 BLOCKED**. All required macOS26 runtime qualification remains BLOCKED. Native27.2 observations are useful contributions, not supported-platform passes. WKS-036 is static API/minimum auditing only. Historical fake dispositions remain separately visible.

[Full native per-case results](../../evidence/20261108T234332Z-webkit-storage-wsf1/native-063248009165/case-results.json) retain475 passing observations,2 HTTP-cache inconclusive and0 failures; repeated setup observations are not independent WKS cases. [Failure matrix](../../evidence/20261108T234332Z-webkit-storage-wsf1/failure-matrix.json) distinguishes22 required categories by actual fake/contract/native coverage.

| WKS / original title | WS-F1 whole-case status | Historical WS-F0 | Remaining qualification / limits |
|---|---|---|---|
| WKS-001 Explicit store assignment precedes view construction | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-002 Default-store and coder/initializer prevention | PASS_FAKE_ONLY | PASS_FAKE_ONLY | Bounded model branch only, never native qualification. |
| WKS-003 Invalid/missing identifier rejected before native effect | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-004 Duplicate or foreign profile mapping | PASS_FAKE_ONLY | PASS_FAKE_ONLY | Bounded model branch only, never native qualification. |
| WKS-005 Same-profile sharing with browsing-context controls | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Same-profile localStorage sharing observed; full browsing-context/sessionStorage controls remain. |
| WKS-006 Cross-profile and origin/partition isolation | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Single controlled first-party origin and selected classes; partitions/HTTP-only/SameSite incomplete. |
| WKS-007 Persistent relaunch with stable mapping | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-008 Concurrent persistent profiles | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-009 Profile switch recreates immutable view ownership | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-010 Popup/configuration ownership gate | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Popups refused; positive inherited-configuration route unqualified. |
| WKS-011 Intentional private-group sharing | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-012 Independent private groups and persistent separation | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-013 Private non-last-owner closure | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-014 Last-private-owner teardown and late-result fencing | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-015 Private graceful shutdown and fresh session | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-016 Private abrupt-host termination | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-017 Profile lock engine access barrier | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Complete engine/OS/key lock barrier unqualified. |
| WKS-018 Incomplete lock/cleanup remains blocked | PASS_FAKE_ONLY | PASS_FAKE_ONLY | Bounded model branch only, never native qualification. |
| WKS-019 Content-process termination and replacement view | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. No independently attributed content-process termination. |
| WKS-020 Network-process/lifecycle interruption | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. No independently attributed network-process fault. |
| WKS-021 Graceful application shutdown and recovery policy | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-022 Selected class/record data deletion | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. LocalStorage clear only; record/date/all-class matrix incomplete. |
| WKS-023 Modified-since deletion semantics | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Modified-since/record-selected deletion not executed. |
| WKS-024 Clear-data completion is not store removal | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-025 In-use whole-store removal failure | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. No forced real in-use removal error; fake rejection only. |
| WKS-026 Whole-store removal after release boundary | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-027 Removal error without false rollback/success | PASS_FAKE_ONLY | PASS_FAKE_ONLY | Bounded model branch only, never native qualification. |
| WKS-028 Interrupted removal and lost completion | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Before-call and after-callback deaths tested; issued-before-callback/platform callback-drop timeout not qualified. |
| WKS-029 Missing established store mapping | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Missing established resource remains fake; no unsafe recreation probe. |
| WKS-030 Orphan/inconsistent namespace reconciliation | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-031 macOS26 localStorage export/restore candidate | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. No website-data export/restore execution. |
| WKS-032 Unsupported export types and capability inventory | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. No per-class export capability qualification. |
| WKS-033 Invalid blob/format and partial restore | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. No opaque malformed-blob/partial-restore execution. |
| WKS-034 Cross-Mac/version migration and deletion lineage | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. No independent-Mac/version migration. |
| WKS-035 Permissions and privacy/logging boundary | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Own logs/fail-closed delegates only; full permission/TCC/restore-grant matrix unqualified. |
| WKS-036 Minimum-OS public API surface audit | PASS_CONTRACT | BLOCKED | Static selected-public-API/compiled-minimum audit only; no runtime qualification. |
| WKS-037 Required macOS26 runtime matrix | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Discovery contributes only its exact fixture/class/lifecycle subset. |
| WKS-038 At-rest protection inventory and limits | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. No complete runtime at-rest/protection inventory. |
| WKS-039 Catalog failure after engine lifecycle effect | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Native publication-journal failure tested; full opaque restore saga incomplete. |
| WKS-040 Interrupted multi-resource backup publication | BLOCKED | BLOCKED | Actual26.0/latest26.x absent. Metadata-only publication policy; no complete archive implementation. |

Native contribution routes: WKS-001/005–009 use seed/restart/switch/assignment traces;011–016 private sharing/cleanup/actual restart;021 shutdown;022/024 clear;026 normal remove;028/030 interrupted lifecycle/reconcile;039 publication-journal failure. These are bounded subsets, not full-case upgrades. WKS-019/020 process-specific failures,017 lock/key barriers,023 date/record deletion,025 forced in-use error,031–034/040 archive/migration and038 at-rest protection remain unqualified. WKS-035 own diagnostic minimization and conservative delegates do not prove positive permissions. All50 SQLCipher PQR definitions, historical namespaces, ADR statuses, owner policies and OP-01–04 remain unchanged.
