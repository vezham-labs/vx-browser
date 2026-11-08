# M1 Canonical Source Catalog and Supersession Record

Version1.1,2026-11-08. Authority: [current owner instruction](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/owner-task-authorization.txt). Documentation and isolated validation/planning Authorized; no product implementation/release authority.

## Canonical maintained set

| Purpose | Actual path in this directory | Version/status | Relationship |
|---|---|---|---|
| Architecture/design | [browser-core-architecture.md](browser-core-architecture.md), [core-boundary-contracts.md](core-boundary-contracts.md), [data model](browser-core-data-model.md), [persistence](local-persistence-architecture.md), [recovery](migration-and-recovery-strategy.md), [capabilities](browser-capability-architecture.md) | Proposed supporting designs plus current scope notices | DS§32 owns current engineering dispositions; historic proposals do not override current owner policy |
| Owner decisions/scope | [m1-owner-decision-register.md](m1-owner-decision-register.md) | v1.1; owner-approved direction | Exact OD-R entries, current OP decisions,26 capabilities and historical crosswalk |
| Developer specification | [m1-developer-specification.md](m1-developer-specification.md) | v1.2 Proposed | Current requirements/policy/coverage/engineering gaps; not validated implementation |
| Validation plan | [m1-validation-plan.md](m1-validation-plan.md) | v1.2 Proposed procedures | Current authorization with original EXP procedures and run reports |
| Supporting charters | [m1-supporting-validation-charters.md](m1-supporting-validation-charters.md) | v1.2 Proposed | All five charters preserved; C02/C03 corrected explicitly |
| Case traceability | [m1-case-level-traceability.md](m1-case-level-traceability.md) | v1.3 Proposed |154 cases +11 references; preserved mappings and separate actual outcomes |
| Experiment evidence | [this run](../../evidence/20261108T094414Z-m1-consolidated-closeout/), [activity reports](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/) | Actual diagnostic records/blocked assessments | Not release or production acceptance; per-row JSON is audit input |
| Implementation plan | [m1-implementation-plan.md](m1-implementation-plan.md) | v1.1 Proposed,19 work packages | Backlog only; not implementation authorization |
| Final closeout | [m1-closeout-report.md](m1-closeout-report.md) | v1.1 qualified closeout | Consolidates this bounded task, remaining blockers and handoff |

## Supplied sources preserved verbatim

The four review deliverables were not found as canonical repository files before this task. They were retrieved from the complete supplied chat documents, not reconstructed from summaries. [Archived Developer Specification](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/developer-specification-v1.0-proposed.md), [Validation Plan](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/validation-plan-v1.0-proposed.md), [Supporting Charters](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/supporting-validation-charters-v1.0-proposed.md), [Case Matrix](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/case-level-traceability-v1.1-proposed.md), [Owner Readiness Review v1.1](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/owner-readiness-review-v1.1-proposed.md) retain exact text. Their original no-execution/unresolved-policy language is historical and superseded only by the current instruction and maintained documents. They are not competing latest specifications.

The previous repository M1 README/implementation plan are [archived](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/) before replacement. [Historical owner packet](m1-owner-decision-packet.md), [decision/risk proposals](m1-decisions-and-risks.md), [old execution proposal](m1-implementation-authorization-proposal.md), DSH assessment and historical evidence retain their IDs/meanings. Current owner decisions do not retroactively approve the historical OD20 implementation proposal.

## ADR/platform/source controls

ADR0001 Proposed,0002 Accepted,0003–0005 Proposed; no status transition. Conditional WKWebView, CEF evaluation-only, Aura excluded, no production Tamizhi/cloud dependency, no public distribution. macOS26 minimum remains;27.2 native results are discovery. Phase3 source/evidence/manifests are preserved; historical49/49 and48/48 results are not combined with current observations.

Original tracked-file hashes/HEAD/branch/clean state: [baseline](../../evidence/20261108T094414Z-m1-consolidated-closeout/repository-baseline.json). Current source/probe hashes, commands and environment: [results](../../evidence/20261108T094414Z-m1-consolidated-closeout/results/), [environment](../../evidence/20261108T094414Z-m1-consolidated-closeout/environment.json). Final preservation audit records actual changed paths; no commit/push/branch change.

## Focused remediation sources — 2026-11-08

New maintained supporting specifications: [Persistent-profile encryption v1.0](m1-persistent-profile-encryption-specification.md), [Keychain/independent recovery v1.0](m1-keychain-and-independent-recovery-specification.md), [Readiness/downstream update v1.0](m1-validation-readiness-remediation.md), [EXP-01 diagnosis v1.0](m1-exp-01-cleanup-diagnosis.md), [Remediation report v1.0](m1-validation-remediation-report.md). These own detailed existing SPEC contracts, not competing product/owner decisions. Original canonical Developer Specification1.1 header said1.0 while its body/catalog said1.1; maintained header now correctly identifies1.2 focused remediation. Validation Plan/charters1.2 and matrix1.3 carry only focused references/authority metadata; IDs/mappings/outcomes unchanged. Source paths/versions/hashes before edits are in ../../evidence/20261108T103813Z-m1-validation-remediation/sources/canonical-source-inventory.json; baseline HEAD and every tracked hash are retained.

## Provider and fixture qualification checkpoint — 2026-11-08

[Canonical qualification-readiness report v1.0](m1-provider-and-fixture-qualification.md) is the focused checkpoint for static source/build and synthetic fixture evidence. It supplements existing specs without replacing owner decisions or altering historical EXP/case outcomes. Evidence: ../../evidence/20261108T113403Z-m1-provider-fixture-qualification/. Original inputs/version hashes and archive/build records are retained; no production dependency selected/installed and no signing/release.

## Provider trust/runtime gate — 2026-11-08

[Canonical trust/runtime assessment v1.0](m1-provider-trust-and-runtime-qualification.md) owns the subsequent authenticity stop decision at baseline 7fb95f769f9af0000997c2d193b3d3675d0ca6a6. Evidence: ../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/. Prior source/build hashes still agree; independent publisher authenticity remains BLOCKED, so runtime/storage/interruption qualification was NOT EXECUTED. Prior source versions, outcomes, owner decisions and ADR statuses are preserved.

## Publisher authenticity evidence acquisition — 2026-11-08

[Canonical publisher evidence report v1.0](m1-sqlcipher-publisher-authenticity-evidence.md) records fresh official signing instructions, published key and 4.20.0 detached signature at baseline 9118f89930a738c5e9d4711c7718a1e373e49761. Evidence: ../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/. Exact Git tag→pin relationship still agrees; independent authenticity remains BLOCKED pending maintained verification and complete publisher/artifact/pin binding. An inquiry draft is unsent. Prior evidence/report bodies, ADR/owner decisions and all acceptance outcomes remain unchanged.

## Vendor archive verification — 2026-11-08 (latest source checkpoint)

[Publisher evidence §8, current verification](m1-sqlcipher-publisher-authenticity-evidence.md#8-vendor-archive-cryptographic-verification--2026-11-08-current-checkpoint) at baseline 0139c80a519f1b90c2d06bacea9d2af2620b16cc supplies the maintained-verifier signature and complete signed-archive-to-pin comparison. Source authenticity PASS via the vendor archive; the previous BLOCKED acquisition snapshot is preserved, not rewritten. Evidence: ../../evidence/20261108T142421Z-m1-vendor-archive-verification/. No pinned-source change, source execution/build, runtime qualification, owner/ADR change or release. GnuPG and required host-tool dependencies were installed only after explicit owner approval; browser dependencies are unchanged.

## SQLCipher worker and key-binding design — 2026-11-08

The proposed design supplies the scoped native qualification worker, exact static link plan, key lifecycle, settings sequence, synthetic fixture contracts and controlled fault barriers. All 50 PQR scenarios remain unexecuted. The design is ready for owner review, while implementation and runtime prerequisites remain pending. The private-refusal mapping correction is recorded for the future executable procedure. [Worker and key-binding design](m1-sqlcipher-worker-and-key-binding-design.md)
