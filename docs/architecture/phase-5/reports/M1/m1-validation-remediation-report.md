# M1 Validation Remediation Report v1.0

Date: 2026-11-08. Documentation and bounded read-only remediation are Authorized; product implementation, signing, notarization, distribution and release are Not Authorized. This task did not execute fresh native/crypto/downstream experiments.

## Deliverables and actual paths

| Deliverable | Maintained document / evidence |
|---|---|
| D01 Cleanup diagnosis | [EXP-01 diagnosis](m1-exp-01-cleanup-diagnosis.md), [matched crash/binary and store snapshots](../../evidence/20261108T103813Z-m1-validation-remediation/results/) |
| D02 Protection specification | [Persistent-profile encryption](m1-persistent-profile-encryption-specification.md) — Proposed v1.0 |
| D03 Key/recovery specification | [Keychain/independent recovery](m1-keychain-and-independent-recovery-specification.md) — Proposed v1.0 |
| D04 EXP-03/04 readiness | [Readiness assessment](m1-validation-readiness-remediation.md#1-exp-03-prerequisite-checklist) |
| D05 Downstream update | [Dependency assessment](m1-validation-readiness-remediation.md#3-downstream-dependencies) |
| D06 Traceability | [Existing matrix](m1-case-level-traceability.md), dated remediation section and [existing-route table](m1-validation-readiness-remediation.md#4-existing-traceability-retained) |
| D07 Consolidated remediation | This report, [baseline](../../evidence/20261108T103813Z-m1-validation-remediation/baseline.json), [audit](../../evidence/20261108T103813Z-m1-validation-remediation/remediation-audit.json) and [change inventory](../../evidence/20261108T103813Z-m1-validation-remediation/changed-files.json) |

## 1. Baseline verification and sources

Started clean on timeline at7545fcec1ef8cd5e939ebc67990d8b6acdc10a7e. HEAD equals the locally recorded origin/timeline tip, with expected canonical-baseline commit subject. No fetch/live remote-server check is claimed. [Canonical source versions/paths/hashes before edits](../../evidence/20261108T103813Z-m1-validation-remediation/sources/canonical-source-inventory.json) and [primary reference inventory](../../evidence/20261108T103813Z-m1-validation-remediation/sources/primary-sources.json) distinguish published repository evidence, external API/design documentation and current read-only observations.

The prior canonical baseline was updated in place only where necessary; it was not recreated. One pre-existing metadata mismatch was corrected: Developer Specification's title said1.0 while its body/index/catalog said1.1. Current focused version is1.2; Validation Plan/charters1.2 and case matrix1.3 add supporting references, with original IDs/mappings/outcomes preserved.

Original Phase3/prototype artifacts, previous consolidation evidence including EXP-01 FAIL and cleanup crash, owner register, ADRs and production sources are unchanged. No commit/push/stage/branch switch/reset/rebase/clean.

## 2. Cleanup diagnosis and store states

Original in-use rejection is confirmed. Source inspection identifies insufficiently proven view/store/configuration/async reference retirement; exact sole retaining object was not instrumented. Apple requires releasing the relevant WKWebViews before identifier removal. This is a diagnosed harness-precondition/lifecycle issue, not a new production implementation.

A now-available matching crash report identifies EXC_BAD_ACCESS/SIGSEGV in os_unfair_lock_lock → WTF::RunLoop::dispatch → WebKit::WebsiteDataStore::removeDataStoreWithIdentifierImpl. App image UUID and retained cleanup binary hash match the original revision. Crash occurred during framework asynchronous removal, not merely before app diagnostics. A bounded unified-log query additionally confirms removal-start for A at15:26:14.278133+0530, with no captured completion/B-start record. Logs do not prove absence of other side effects. There are no app-level per-store before/after checkpoints: whether A completed before B's call or which UUID was active at fault remains unknown. Run-loop/framework initialization/lifetime is a plausible hypothesis, not a confirmed crash root cause.

| Original store | Current evidence | Classification |
|---|---|---|
| A,abb4ca2d-33dc-4d25-9c16-d135202c03e3 | Expected directory absent; original physical location/registry and API completion were not captured | **State unknown**; no inference of successful removal |
| B,9ec735a8-b9eb-416c-994b-4b299c5ee5f5 | Exact disposable-container UUID directory exists with38 recorded files/hashes | **State unknown** at logical integrity/completion level; presence is confirmed |

Read-only process/open-handle snapshots did not report a matching reference at capture time; this is not global proof or reconstruction of the earlier crash. No store initialization, enumeration-through-creation, removal, manual file deletion, process termination or new fixture run occurred. No TCC/Keychain or OS lock/session action.

Fresh verification is **Blocked / Not Executed** because original-state prerequisites remain unresolved. Only new disposable UUIDs may be used after that prerequisite is met. Original EXP-01 remains **FAIL**; cleanup-only follow-up remains **INCONCLUSIVE/crashed**; no historical result is converted to PASS. Artifacts are retained as evidence, not discarded.

## 3. Specification closure achieved

The Proposed specifications now define:
- Threat model: offline profile/backup theft and authenticated data acceptance, with explicit unlocked-process/OS compromise, recovery-secret and memory/OS artifact limits.
- Protection inventory for catalog, profile databases, WAL/journals/SHM/temp files, history/download/profile metadata, user/internal snapshots, sessions/recently-closed, permissions/bookmarks/saved pages, archives/key/recovery metadata, WebKit and external files.
- Independently encrypted catalog and profile key scopes; SQLCipher 4.20.0/CommonCrypto qualification candidate, not an installed/qualified dependency.
- Database suite/settings/key-input contract, memory-temp requirement and exact artifact/failure evidence demanded by EXP-03.
- AES-256-GCM/HKDF-SHA256 envelope construction, nonce/purpose/scope rules, strict deterministic format, authenticated identity and bounded parsing; no hand-written crypto/provider implementation.
- Per-profile DEK/normal KEK/independent random recovery R, protected Keychain path, explicit normal native authentication and no separate default browser password.
- Printable kit and encrypted recovery file with independent custody, encoding/checksum versus authentication distinction, readback/decrypt verification and offline restore sequence.
- Key-version/KEK/DEK/recovery rotation, preserved old backup dependencies, loss/corruption/conflict behavior and no automatic destructive reset.
- Real lock/key/view-access barrier, late-event fencing, protected inflight reconciliation, other-profile isolation and no UI-only lock success.
- WebKit remains a separate protection/export/delete domain; SQLite keys do not encrypt its website data or external downloaded files. Conditional WKWebView strategy remains.

These are normative engineering definitions, not evidence of cryptographic correctness, secure-memory enforcement, a qualified provider or implementation readiness. Full SPEC-03 schema, SPEC-08 WebKit protection, SPEC-12 coherent snapshot/promotion and SPEC-13 deletion propagation still need their own qualifications.

## 4. Readiness and downstream outcomes

| Activity | Readiness / execution disposition |
|---|---|
| EXP-03 | **Blocked**: exact candidate source/binary/build/license/provider/settings and key binding not qualified; artifact/corruption/rotation fixtures not built |
| EXP-04 | **Blocked**: exact app Keychain/ACL runtime and independent recovery/parser/crypto fixtures absent; qualified encrypted profile and independent Mac not provisioned |
| Provider-independent Keychain subset | **Conditionally ready as a design only** after identity/access/fixtures are provisioned; not executed |
| EXP-05 | **Blocked**: actual OS-trigger/key/DB/view barrier remains unimplemented/unqualified |
| EXP-07 | **Blocked**: encrypted stack/coherent archive/promotion/selection/deletion and independent destination missing |
| EXP-08 | **Blocked**: actual ledger/lineage/coverage propagation and archive restore absent |
| SVC-04 | **Blocked**: integrated local product absent; offline recovery is not offline-product proof |
| SVC-05 | **Blocked**: integrated durable host/content/profile/SQL/key/file recovery absent |

No EXP-03/04/05/07/08 or downstream SVC execution occurred. Specifications do not themselves authorize a case whose prerequisites are missing. Supported macOS 26 runtime/architecture and final StageC gates remain mandatory.

## 5. Traceability and preservation

OD01–20, OD-R01–20, WS01.1, OP01–04, SPEC01–16, REQ01–22, AC01–15, EXP01–08, SVC01–05 and all existing case IDs retain their meanings/mappings. No new acceptance/case IDs. PERM-016 remains AC09/AC14; RECOVERY-010 remains OP-04; REQ-21 is separate final StageC with no AC assignment; REQ-22 remains SPEC-08/AC08/EXP-01/02/05/07.

Inventory/outcomes are unchanged:154 validation cases all Blocked;11 experiment references with1 FAIL,1 INCONCLUSIVE and9 Blocked;165 total rows. Current diagnosis adds evidence to ISO-001, not a passing new validation case. F01–F17 are not closed/downgraded by the specifications.

The [final audit](../../evidence/20261108T103813Z-m1-validation-remediation/remediation-audit.json) verifies tracked baseline preservation, original evidence and owner/ADR/source immutability, unchanged individual matrix mappings/outcomes, requirement/acceptance/spec coverage, link validity and branch/HEAD/index state. It is a documentation/preservation audit, not a runtime/security qualification. Read-only original-store file hashes are rechecked; no destructive operation is authorized or recorded.

## 6. Recommended next engineering task

Prepare a finite provider/binding/fixture qualification task for the documented SQLCipher candidate and platform envelope/Keychain contracts, with exact build/provenance and isolated access prerequisites before EXP-03/04. In parallel, establish noncreating same-identity registry and per-store lifecycle observability for the original synthetic stores; do not create missing A with init(forIdentifier:) or delete by guessed path. Only after original state is sufficiently understood should a new-UUID teardown/completion diagnostic be considered.

Resolve actual key/view lock feasibility and archive/deletion integration through their existing experiments later. No production fix, signing, release or broad native/UI work begins automatically. This remediation closes the specified technical ambiguities as Proposed contracts while explicitly retaining executable blockers and the unresolved framework crash cause.
