# M1 Validation Readiness and Downstream Remediation

Version 1.0,2026-11-08. D04/D05. Normative specifications are refined; execution readiness is separately assessed. Sources: [encryption](m1-persistent-profile-encryption-specification.md), [key/recovery](m1-keychain-and-independent-recovery-specification.md), [SDK/provider inventory](../../evidence/20261108T103813Z-m1-validation-remediation/results/candidate-availability.json), [EXP-01 diagnosis](m1-exp-01-cleanup-diagnosis.md).

## 1. EXP-03 prerequisite checklist

**Overall: Blocked. No EXP-03 execution authorized by readiness alone or performed here.**

| Prerequisite | Current position | Required evidence before execution |
|---|---|---|
| Qualified encryption provider | Blocked: SQLCipher 4.20.0/CommonCrypto is a documented candidate, not installed/digest-pinned/license-reviewed/qualified | Exact artifact/source/build/toolchain/SQLite/crypto-provider versions, checksums, license/provenance review and real settings |
| Key-management interface | Contract specified:32-byte per-scope input, protected normal/recovery slots, no String/log exposure | Reviewed isolated binding/key ownership and failure/zeroization limitations; no production implementation |
| Disposable databases | Not created | Owned isolated paths/IDs and fixture manifest; no personal data or old WebKit stores |
| Main/WAL/journal/SHM/temp | Required matrix/configuration specified | Each actual artifact produced/observed; memory-temp compile/runtime proof; header leakage assessed; no plaintext staging |
| Authentication/corruption | Oracles specified, fixtures absent | Correct/missing/wrong profile key; ciphertext/tag/page/truncation controls, functioning plaintext detector control |
| Rotation/recovery | Copy-and-promote/key-ring contract specified, fixtures absent | Interrupted before/after each retained-generation/promotion boundary; no sole source/key deletion |
| Pass/fail/review | Existing CRYPTO-001/AC05/14/15 routes retained | Case-specific complete artifact/expected-result inventory and engineering/security disposition |
| Platform/resources | SDK declarations present; no macOS 26 qualification | Named authorized environment and bounded storage/memory faults; no filling user disk |

EXP-03 PASS requires all mandatory declared configurations/artifacts to meet protected-data/integrity/failure outcomes. FAIL includes accepted wrong key/tamper, plaintext spill, destructive fallback or false commit. Missing provider/artifact visibility is BLOCKED/INCONCLUSIVE, not PASS. Successful database open alone never qualifies encryption.

## 2. EXP-04 prerequisite checklist

**Overall: Blocked.** Key/format specification closure does not create a tested recovery stack.

| Prerequisite | Current position | Required evidence before execution |
|---|---|---|
| Keychain API availability | Installed SDK declares selected access-control/data-protection APIs | Actual isolated app identity/access-group/ACL/userPresence tests; fresh context, deny/cancel/unavailable handling |
| Independent recovery format | Proposed VXKE/VXRF/print-kit contract specified | Independent implementation/parser/encoding/AAD/AEAD vectors and interoperability review; no secrets in artifacts |
| Fixture generation | Not executed; no keys/kits created | Disposable per-scope key rings/capsules and encrypted profile fixture from qualified EXP-03 configuration |
| Offline recovery | Sequence defined | Network-isolated restoration without source Keychain/cloud and with explicit destination preservation |
| Wrong/corrupt material | Failure behavior specified | Wrong R/profile/version/slot; malformed/truncated/tag-changed capsule; missing files; no guessed/reset key |
| Data verification | Expected authenticated reopen required | Known synthetic records/key versions, integrity/identity and exact restored content |
| Key isolation | Separate DEK/KEK/R per profile/catalog defined | Profile A/B wrong-key and scope-binding controls; no normal-access bypass while locked |
| Independent destination | Not provisioned or identified | Second Mac for KEY-002/cross-Mac claim; source Keychain demonstrably absent |
| Custody verification | Full readback/decrypt/kit reconstruction required | Native export/print/input procedure and verified receipt, with OS spool limits disclosed |

Provider-independent Keychain subset preparation is **Conditionally ready as a design only**, once exact identity/ACL fixtures/native access are provisioned. It is not a Ready verdict for EXP-04, does not execute now and cannot qualify independent encrypted-profile recovery.

No permission/signing or fixture-generation action is inferred from documentation. EXP-04 cannot PASS without correct recovered data/key isolation and failure preservation; no-device/source-Keychain fallback cannot replace independent destination evidence.

## 3. Downstream dependencies

| Activity | Newly specified dependencies | Remaining blockers/prerequisite change | Existing procedure/revision |
|---|---|---|---|
| EXP-05 | Single protected KEK path, real lock states/generations, key lease/reacquisition and inflight outcomes | Actual OS trigger and key/view/DB barrier; native identity/Keychain and release proof; EXP-01 crash unresolved | Broad procedure valid; bind exact new state/AAD/key tests before execution; **Blocked** |
| EXP-07 | Archive key wrapping, independent recovery authority, catalog encryption, no plaintext staging and rotation preservation | Qualified provider/key stack; coherent archive/promotion/migration/selection/ledger implementation; independent Mac; WebKit categories still unqualified | Broad procedure valid; update exact format/fixture/checkpoints; **Blocked** |
| EXP-08 | Protected key/data scopes and explicit unknown-deletion handling; old-key/backup limits | Actual independent deletion ledger/lineage/propagation/confirmation and qualified archive | Existing known/unknown hypothesis valid; refine versions/confirmation binding; **Blocked** |
| SVC-04 | Catalog/profile normal and recovery key paths do not require cloud/server | Integrated product/Core/repositories/UI and real offline operation absent | Existing offline charter valid; key-unavailable/normal-prompt outcomes need fixture details; **Blocked** |
| SVC-05 | Restart/rotation/locked state and per-store cleanup failures specified | Actual durable host/content/profile/DB/file recovery, scope release, crash checkpoints; EXP-01 unresolved | Broad charter valid; add precise checkpoints without new IDs; **Blocked** |

No downstream experiment/campaign ran. New crypto framing does not finish SPEC-12 coherent backup or SPEC-13 deletion propagation. Private-session/website-data/TLS/permission and full functional coverage remain open. macOS 26 runtime and Stage C remain separately scheduled, not waived.

## 4. Existing traceability retained

| Existing route | New supporting specification/evidence | Status impact |
|---|---|---|
| REQ-05/06 → SPEC-04 → AC05/14/15 → EXP-03/CRYPTO-001 | Encryption§§2–6, provider/API inventory | BLOCKED unchanged |
| REQ-07 → SPEC-05 → AC06 → EXP-04/KEY-001/002 | Key/recovery§§1–4/6–7 | BLOCKED unchanged |
| REQ-08/18 → SPEC-07/14/15 → AC07/14/15 → EXP-05/LOCK-001; RECOVERY-006 | Key/recovery§5 and diagnosis reference-release findings | BLOCKED unchanged |
| REQ-14/16/19 → SPEC-05/12/13 → AC12/13/15 → EXP-07/08/BACKUP/DELETE routes | Key/recovery, encryption backup/delete boundaries | BLOCKED unchanged; no complete archive/ledger claim |
| REQ-22 → SPEC-08 → AC08 → EXP-01/02/05/07 | Diagnosis and encryption§7 | Original ISO-001 FAIL/PRIV-001 INCONCLUSIVE and other blockers unchanged |
| REQ-21 | Separate mandatory final Stage C; no AC01–15 assignment | Deferred, not run; no release authorization |

PERM-016 remains AC09/AC14; RECOVERY-010 remains OP-04. No new REQ/AC/EXP/SVC/case IDs. Existing154 validation cases plus11 experiment references remain165 rows, with unchanged outcomes. Additional diagnostic checkpoint granularity or format vectors are proposed refinements, not silently numbered new cases.

## 5. Next bounded engineering checkpoint

First provision a pinned/provider-reviewed isolated SQLCipher candidate and audited crypto/CBOR/key interface fixtures, then review the finite EXP-03/04 prerequisites. Obtain safe noncreating registry/lifecycle observability for the original stores; do not delete them based on absence/no-handle snapshots. Once original states and safe prerequisites are understood, newly minted store IDs may be used for a distinct release-order/completion diagnostic. Do not sign/launch/retry or run downstream campaigns as an automatic consequence of this document. Production implementation and release remain Not Authorized.

## Subsequent provider/fixture checkpoint — 2026-11-08

[Qualification report](m1-provider-and-fixture-qualification.md) supplies pinned source/tree verification, two identical arm64 static archives, compile-setting evidence, plaintext detector controls, syntax-only binary-key binding and bounded synthetic CryptoKit/format observations. No full EXP-03/04 campaign ran; runtime artifact protection/binding, provider trust/security qualification, native Keychain identity/ACL and independent destination remain Blocked. WebKit enumeration remains designed/blocked under the signing boundary. This update adds evidence links without changing existing mappings/outcomes or treating the source Mac as cross-Mac recovery.
