# M1 Consolidated Closeout Report v1.1

Date2026-11-08. **Documentation consolidated; bounded eligible validation attempted; implementation planning prepared. M1 product acceptance/completion is not claimed.** Product implementation and release remain Not Authorized. ADR statuses unchanged.

## Authority and starting state

The [owner instruction](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/owner-task-authorization.txt) authorized repository documentation, safe isolated EXP/SVC validation/fixtures/builds/evidence and implementation planning. It did not authorize product features, release/signing-notarization approval/distribution, branch changes, commits or pushes. Started clean on timeline; actual HEAD and tracked hashes are in [baseline](../../evidence/20261108T094414Z-m1-consolidated-closeout/repository-baseline.json). No production app source/configuration or Phase3 source/evidence was changed. Final audit is [here](../../evidence/20261108T094414Z-m1-consolidated-closeout/final-audit.json).

## D01–D05: canonical documentation and decisions

[Source catalog](m1-source-catalog.md) is the authority for actual paths, versions and supersession. [M1 index](README.md) links the canonical set. Exact full supplied DS/VP/SVC/CT/readiness sources were retrieved from the existing chat and archived, not reconstructed from summaries. Prior repository documents were archived before being labelled historical or reconciled.

- OD-R01–OD-R20 preserved verbatim; architecture/product direction approved, not independent implementation authority.
- OP-01 decided: full URLs including query/fragment, strip embedded credentials, no automatic query filtering, encrypted/profile-scoped/no private history; Forever default/stated alternatives; deletion-aware backup; no URL diagnostics. Sensitive path/query/fragment risk explicitly retained.
- OP-02 decided: manual metadata retention, individual/clear-all, encrypted/profile-scoped/metadata backup; metadata deletion never deletes files; payload exclusion/OD-R20 selection preserved.
- OP-03 decided: manually retained user-created snapshots, no default expiry, individual/bulk deletion, encrypted/profile-scoped/no private snapshots; internal recovery copies remain separately specified.
- OP-04 decided: normal quit/restart restore; crash prompts; recently-closed manual retention; private discard; no auto form/POST; profile/lock/deletion isolation; failed pages retain entries with explicit failure.
- Historical OD17 now selects26 capabilities. Historical OD18 remains preserved; basic Spaces/workspaces selected, advanced automation deferred. Search provider/saved-page/basic organization models remain technical gaps, not independent owner choices.
- WS01.1/historical OD01–20 meanings preserved, including OD07/08/14 and OD20 versus OD-R20 distinction.
- C01 corrected inventory categories; C02 maintained PERM-016 AC09/AC14 and corrected older SVC AC07 summary; C03 maintained RECOVERY-010 OP-04 and removed the old SVC OP-01 mention. Exact original discrepancy sources remain archived.

Canonical DS/VP/charters remain Proposed, with current owner-decided policy/authority and explicit technical gaps. No competing latest approved specification is asserted.

## D06: actual validation/evidence

Environment:arm64 macOS27.2 (26B123), Xcode SDK27.2, Swift6.4.2, compile target26.0. This is newer-host discovery, not macOS26 runtime/release qualification. [Environment](../../evidence/20261108T094414Z-m1-consolidated-closeout/environment.json), [frozen subset procedure](../../evidence/20261108T094414Z-m1-consolidated-closeout/procedure.md), [preflight](../../evidence/20261108T094414Z-m1-consolidated-closeout/results/validation-preflight.json).

| Activity | Outcome | Actual work and limitation |
|---|---|---|
| [EXP-01](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/EXP-01.md) | FAIL | Native sharing/isolation/relaunch/scoped-clear observations succeeded; live-handle store removal failed. Full generation/initialization-fault/product coverage absent. |
| [EXP-02](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/EXP-02.md) | INCONCLUSIVE | Normal native private sharing/isolation/fresh-store absence observed; no product durable/private-grant/staging/abrupt/true last-owner proof. |
| [EXP-03](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/EXP-03.md) | BLOCKED | No selected authenticated encrypted-SQLite provider/configuration/provenance; stock SQLite not credited. |
| [EXP-04](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/EXP-04.md) | BLOCKED | Keychain/recovery formats/access configuration/encrypted fixture missing; independent Mac not provisioned. |
| [EXP-05](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/EXP-05.md) | BLOCKED | Actual key/view/profile barrier and OS-trigger contracts absent. |
| [EXP-06](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/EXP-06.md) | BLOCKED | Native destination/token/resume/finalization/metadata integration incomplete. |
| [EXP-07](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/EXP-07.md) | BLOCKED | Provider/key/archive/coherent promotion/WebKit coverage and independent Mac missing. |
| [EXP-08](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/EXP-08.md) | BLOCKED | Protected ledger/lineage/confirmation and qualified archive implementation absent. |
| [SVC-01](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/SVC-01.md) | BLOCKED | Actual four-target package absent; source preflight only. |
| [SVC-02](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/SVC-02.md) | BLOCKED | Actual production chrome/bridge/origin/codec absent. |
| [SVC-03](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/SVC-03.md) | BLOCKED | No M1 broker/grants/native tokens/per-kind positive mapping; no fake-negative substitute. |
| [SVC-04](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/SVC-04.md) | BLOCKED | Integrated local browser/storage/UI/key functionality absent. |
| [SVC-05](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/SVC-05.md) | BLOCKED | Integrated durable host/content/profile/SQL/key/transfer recovery absent. |

No complete EXP, SVC, REQ or AC is passed. Native checks are observations within experiment-reference rows, not passing validation cases. Seed recorded30 successful check flags; verify recorded13 successful and1 failed cleanup flag. These are not an M1 acceptance pass rate and are not combined with Phase3 results.

### Commands, failures and cleanup

Only the disposable Swift6 native harness was compiled/ad-hoc-debug-signed; static signature verification passed with App Sandbox/Hardened Runtime enabled and network-client entitlement. No release signature/notarization or security weakening. Initial Swift SDK overload compile error was corrected only in harness source; retained subsequent build records show success.

Loopback initially failed under automation network restriction, then authorized loopback access was granted. Initial app launch aborted in the automation sandbox; one distinct outside-execution-sandbox attempt reached the logged-in native environment with app protections intact. Original attempts are retained, not erased.

The native verify failure was **Data store is in use** while the experimental procedure retained store/view references. No cross-profile leak was observed. A separate cleanup-only harness revision, after the prior process exited, compiled/signed successfully but crashed after VX_BOOT with returncode-11. [Cleanup result](../../evidence/20261108T094414Z-m1-consolidated-closeout/results/cleanup-only-result.json) is INCONCLUSIVE; [native log](../../evidence/20261108T094414Z-m1-consolidated-closeout/results/cleanup-only-native.json) retains the actual command/output. It does not convert the failed experiment to PASS. Exact prior source revision and source/binary hashes remain retained.

**Cleanup completion is unknown for this run's two newly generated WebKit store IDs.** Their registry is [fixtures.json](../../evidence/20261108T094414Z-m1-consolidated-closeout/fixtures.json); all data is synthetic under the unique disposable app identity. No personal/default store was used. No direct WebKit-file deletion or repeated unchanged loop was attempted. Loopback fixture servers shut down in runner finally blocks; no camera/microphone/Keychain/OS lock/sleep/user-session actions. Temporary debug artifacts remain under the run-specific /private/tmp directory for diagnosis; experimental source is retained in evidence.

## D05: recalculated traceability

| Inventory | Validation cases | Experiment references | Combined rows |
|---|---:|---:|---:|
| Count |154|11|165|
| Historical B |36|0|36|
| Historical U |48|9|57|
| Historical PN |70|2|72|
| Current PASS |0|0|0|
| Current FAIL |0|1|1|
| Current BLOCKED |154|9|163|
| Current INCONCLUSIVE |0|1|1|
| Current NOT RUN |0|0|0|

All154 cases were accounted for by preflight and are BLOCKED, not154 executed tests. ISO-001/PRIV-001 are the two partially exercised experiment references. [Canonical matrix](m1-case-level-traceability.md) and [row JSON](../../evidence/20261108T094414Z-m1-consolidated-closeout/traceability-results.json) preserve all original mappings and reasons. No status is altered merely to fit totals.

## Requirements/functional coverage and remaining gaps

All REQ-01–22, AC01–15, SPEC-01–16, EXP-01–08, SVC-01–05, OD-R01–20 and all existing row IDs are accounted for by the final documentation audit. REQ-21 remains separately deferred Stage C with no AC assignment; REQ-22 remains SPEC-08→AC08→EXP-01/02/05/07. There is no whole-criterion pass.

The [DS§31 capability table](m1-developer-specification.md#31-current-owner-selected-launch-capability-coverage) assesses every selected capability. Dedicated navigation/search, tabs/windows/recently-closed, bookmark/favorite/saved-page, group/basic Spaces, TLS/external URLs/native notification and file-open/upload functional acceptance is incomplete. A proposed extension is explicitly unnumbered and requires owner review before new approved matrix rows; related security ACs are not forced to substitute.

The [DS§32 specification register](m1-developer-specification.md#32-engineering-disposition-register--spec-01spec-16) retains provider/protection, key/recovery, lock/view barrier, schema/checkpoints/internal snapshots, permission APIs, external-file authority, archive/ledger/migration and functional-oracle gaps. [DS§33](m1-developer-specification.md#33-owner--capability--specification--requirement--validation--evidence--implementation) connects owner→capability→SPEC→REQ→AC→validation→evidence→work package with explicit Unspecified/partial links. F01–F17 remain open; none closed/downgraded by documentation.

## D07: implementation plan and readiness

[Implementation plan](m1-implementation-plan.md) contains19 work packages with objective/scope, existing IDs, dependencies, actual evidence, deliverables/acceptance/definition of done, complexity and risks. WP01/WP04 Conditional; other17 Blocked. All are Not Authorized for implementation.

Critical path: contracts/provider → encrypted storage qualification → independent key recovery → profile/key/view/resource lifecycle → coherent archive/deletion reconciliation → session/file recovery → integrated functional/offline acceptance → separately authorized Stage C. Package/domain specification can proceed independently of provider investigation. UI privilege waits for the verified bridge; basic Spaces/group UX needs functional specification and acceptance extension review.

**Recommended next engineering action:** a finite isolated diagnosis of the retained WebKit cleanup failure/crash and closure of selected encrypted-SQLite/key/recovery/archive prerequisites. In parallel, review the proposed functional acceptance extension and concrete package/bridge contracts. No automatic product fix or implementation start. No repeated unchanged validation loop.

## Stage C and authorization checkpoint

REQ-21 remains mandatory before actual internal release: macOS26.0/latest supported26.x and supported architectures; Developer ID/nested code/notarization/Gatekeeper; App Sandbox/Hardened Runtime/entitlements; candidate reliability/performance/compatibility; updater/artifact integrity/replay/expiry/channel/minimum-version/revocation/rollback; dependency/provenance/license/security review; separate owner internal-release decision. No actual candidate or release qualification exists here.

| Area | Status |
|---|---|
| Documentation baseline | Consolidated, Proposed technical specification with explicit gaps |
| Owner OP-01–04 and OD17 scope | Owner-Decided; engineering integration not validated |
| Validation execution | Authorized within prerequisites; actual FAIL/INCONCLUSIVE/BLOCKED outcomes above |
| Implementation planning | Authorized;19-package backlog prepared |
| Product implementation | Not Started / Not Authorized |
| Release/signing-notarization approval/distribution | Not Authorized |
| ADRs |0001 Proposed;0002 Accepted;0003–0005 Proposed |
| Git | timeline retained; no staging/commit/push/reset/rebase/clean/branch switch; exact change audit linked above |

This task closes the documentation consolidation and bounded available validation attempt with explicit blockers. It does not close M1 product acceptance, waive gates or authorize implementation/release.


## File-by-file change report

[Changed documents and artifact categories](../../evidence/20261108T094414Z-m1-consolidated-closeout/change-report.md) and [exact path/hash inventory](../../evidence/20261108T094414Z-m1-consolidated-closeout/changed-files.json) record created/modified files. Original supplied sources and prior repository versions remain archived; the final preservation audit independently checks tracked hashes, branch/HEAD and an unstaged index. Documentation audits are not product validation passes.

## Native observation bounds and permission inventory

Native cache observations cover CacheStorage markers, not all HTTP/disk caches; service-worker observations cover registration/readiness, not every execution/resource behavior; no scheduling-race or forensic-erasure guarantee. The maintained specification §34 explicitly lists all12 existing website permission kinds, actual SDK-declaration evidence, missing M1 positive/native qualification and unchanged PERM families. Native macOS notifications remain separate.
