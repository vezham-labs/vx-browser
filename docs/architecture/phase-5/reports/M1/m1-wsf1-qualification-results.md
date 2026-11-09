# WS-F1 actual qualification results

2026-11-09. **Native supported-platform qualification: BLOCKED.** Available host: macOS27.2/build26B123, arm64, Swift6.4.2, SDK27.2, installed WebKit22625.2.8.11.9. No actual26.0/latest26.x execution, release signing or notarization occurred.

The canonical [full native run](../../evidence/20261108T234332Z-webkit-storage-wsf1/native-063248009165/result.json) used the [final build](../../evidence/20261108T234332Z-webkit-storage-wsf1/build-062812696387/result.json), executable SHA256 `28ad7f6042186d502cdd242008491927418188547ae67421f5711e40bb56c23f`. The separate original-namespace diagnostic is pinned to `diagnostic-build-001154431303`; it is an enumeration-only diagnostic revision, not this candidate's functional qualification. Every build/test attempt remains in [history](../../evidence/20261108T234332Z-webkit-storage-wsf1/results/attempt-history.json).

## Counts and evidence scope

| Executed suite | Actual outcome | Meaning |
|---|---|---|
| Final native full run |475 PASS_NATIVE observations,0 FAIL,2 INCONCLUSIVE;39 app launches including12 deliberate child terminations | macOS27.2 discovery only;477 observations,98 distinct case labels, repeated setup assertions distinguished by attempt label |
| Final descriptor/admission suite `models-063737711735` |12 PASS_CONTRACT plus1 PASS_FAKE_ONLY,0 failures |13 named tests; parameterized descriptor vectors included. Guard tests instantiate the adapter but create no native store/view |
| Retained WS-F0 `attempt-001707035860` |82 PASS_FAKE_ONLY,0 failures/skips/uncompleted | Original82 tests and fake providers retained; shared Domain source hashes match the current implementation |

These are separate counts. Do not sum fake/contract/native totals, add earlier attempts, or call475 observations475 independent WKS cases. Latest native full run is the canonical acceptance contribution; previous partial/failed runs never become a cumulative pass rate. [Per-observation cases](../../evidence/20261108T234332Z-webkit-storage-wsf1/native-063248009165/case-results.json) and [per-process outcomes/checkpoints](../../evidence/20261108T234332Z-webkit-storage-wsf1/native-063248009165/attempts.json) retain actual scopes, labels and build identity.

## Demonstrated on the discovery host

- Persistent A/B: explicit distinct named-store assignment, positive cookie/localStorage/IndexedDB/CacheStorage/sessionStorage and controlled service-worker observations. Same-origin A/B markers remain separate. Actual process exit/relaunch preserves the tested persistent classes; new browsing contexts do not restore sessionStorage.
- Service-worker observation includes controlled fetch interception, not registration alone. HTTP-cache response identity across relaunch is **INCONCLUSIVE for both profiles**; it is not converted into persistence/isolation PASS.
- Profile switching: A→B/B→A uses newly owned views; same-profile extra view and two actual NSWindows consume intended surfaces. Nonlast closure leaves the other view usable. Terminal activation replay after navigation causes no native effect.
- Private: persistent/private and independent-session separation for cookie/localStorage/IndexedDB; intended-group sharing; nonlast/last closure; fresh session; actual abrupt host death/relaunch. Final15-second release-observation budget and explicit supported-category purge precede successful observed wrapper retirement. No forensic or all-engine-process disappearance guarantee follows.
- Clear: real localStorage deletion callback, selected public-record absence, page-visible absence and retained cookie/IndexedDB/CacheStorage positive controls. Clear retains mapping; it is not store removal.
- Removal: both main-run stores removed in a distinct process after noncreating reconciliation and ownership barriers; callback plus public identifier absence confirmed. No creating probe after removal, manual filesystem cleanup or secure-erasure claim.
- Recovery:11 independent controlled cutpoints at creation intent, factory, assignment, construction, publication, clear request/callback, retirement, remove request/callback and reconciliation enumeration. Each actually terminates/relaunches the owned process, preserves pending metadata and repeats noncreating reconciliation. `clear-request`/`remove-request` are explicitly **before-call** checkpoints; issued-before-callback timing and real dropped-callback timeouts are not claimed tested.
- Publication-journal failure after real construction is injected in the synthetic metadata adapter; Core/native publication stays fenced. Native effect plus a simulated journal failure is not SQLCipher failure qualification.

## Earlier outcomes and corrections

Initial model runner missed two parameterized summaries despite all8 tests passing; its parser was corrected and the failed runner result preserved. Development builds exposed enum raw-type ordering, app/package architecture mismatch and public Swift callback/async expression errors; all failed build outputs remain.

`native-000624305959` failed before enumeration completion with SIGSEGV/EXC_BAD_ACCESS at0x48. The binary-matched crash identifies WebKit identifier-enumeration background callback dispatch. Pinned upstream `API::Object` initialization supports a public configuration-initialization hypothesis; the implementation now initializes `WKWebViewConfiguration` without reading its store, constructing a view or warming a default store. Subsequent original-namespace observations completed. This is a successful bounded remediation observation, not a general shipping-engine root-cause proof.

Immediate private retirement failed in `native-001659018868` (100 passing observations,2 failures). A2-second observed-release window in `native-002020654867` left the seeded private A wrapper observable (67 passes,1 failure); explicit private purge plus publication fixes in `native-002553871987` still missed that deadline (73 passes,1 failure). Their two HTTP-cache observations per run remained inconclusive. No failure was rewritten.

The independent persistent subset `native-002844387365` completed with346 passing observations and2 inconclusive HTTP-cache observations while explicitly preserving the private failure. At the owner's subsequent “try now,” the release postcondition was retained and the engineering observation budget increased to15seconds. Targeted `native-063003266421` passed41 observations including private abrupt death/relaunch; then the complete frozen-build run above passed its finite discovery scope. This is a new implementation revision and budget, not a retroactive2-second pass or performance claim.

Original historical namespace: A remains absent from enumeration and B present. Prior removal completion/intactness remains unknown; neither original was resolved, repaired or removed. Original EXP-01 FAIL, EXP-02 INCONCLUSIVE, EXP-05/07 BLOCKED, Phase3 recovery49/49 and regression48/48, and all SQLCipher PQR outcomes remain unchanged.

## Not executed / remaining limits

Actual26.0/latest26.x, Intel/independent-Mac qualification, protected durable catalog/Keychain integration, lock barriers, forced native in-use/I/O errors, all deletion categories/records/date semantics, third-party/HTTP-only/SameSite coverage, independently targeted content/network process failures, positive permission/account workflows, website export/import/backup/migration and release gates remain blocked or unexecuted. Fake partial/error/unknown vectors do not prove native positive support. The [22-category failure matrix](../../evidence/20261108T234332Z-webkit-storage-wsf1/failure-matrix.json) records the precise supporting mode and outstanding native routes.

Uncertain interruption/publication fixtures remain recorded and quarantined; they are not silently swept or reused. Successful primary removals and retained uncertain fixtures are distinct in [resource dispositions](../../evidence/20261108T234332Z-webkit-storage-wsf1/results/resource-dispositions.json).
