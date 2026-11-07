# Phase 3 evidence and Phase 4 decision review

This folder is the review packet that concludes the bounded Phase 3 WKWebView feasibility investigation and prepares Phase 4 engine selection/architecture freeze. It contains documentation and the [2026-11-07 Product Owner decision](owner-approval-decision.md): Phase 3 closure APPROVED, WKWebView CONDITIONAL ACCEPTANCE for MVP planning and implementation, and architecture baseline APPROVED. It contains no implementation, test runner, unconditional production-engine acceptance or release authorization.

## Owner decision and Phase 5 handoff

Read the canonical [owner approval decision](owner-approval-decision.md) for the exact three approvals, remaining conditions and verification of the completed, reviewed Phase 4.1 ADR correction. The valid ADR is preserved without another correction in this Phase 4.2 completion. ADR 0001 stays Proposed; CEF is evaluation-only; Aura is excluded; no public distribution is authorized. The [Phase 5 index](../phase-5/README.md), [scope/milestones](../phase-5/phase-5-scope-and-milestones.md) and [implementation plan](../phase-5/phase-5-implementation-plan.md) prepare a later separately scoped kickoff. No implementation or build/test runs in Phase 4.2.

## Reading order and primary exit review

1. **[Phase 3 exit review](phase-3-exit-review.md)** — the primary review: approved bounded closure, primary revision, earlier evidence, known failures, blocked/deferred tests and remaining obligations. Start here.
2. [Browser acceptance-gate ledger](browser-acceptance-gate-ledger.md) — A/B/C/D classification, explicit statuses, evidence/limitations/owners, previous 13-gate and source-requirement crosswalks. Requirement counts are not test pass rates.
3. [Browser engine decision assessment](browser-engine-decision-assessment.md) — balanced capability/risk assessment and all four decision paths; conditional recommendation and approval conditions.
4. [Browser MVP architecture baseline](browser-mvp-architecture-baseline.md) — approved ownership/trust boundaries with explicit unresolved implementation choices; no production code.

## Historical evidence versus maintained decisions

The exit review and evidence register are point-in-time records. The latest recovery revision supplies separate **49/49 actual-window recovery** and **48/48 regression** results. Earlier performance/compatibility/permission/transfer results retain their own revisions and limits; no combined aggregate pass rate or latest-revision performance qualification is implied.

Original [prototype reports](../prototype/phase3-final-review.md), [evidence](../../../prototype/wkwebview/Evidence), source manifests/hashes and prior review archives remain preserved. Older failed/incomplete or superseded observations remain readable and are not rewritten as Passed. The gate ledger remains the unchanged Phase 4 review snapshot, including its A/B/C/D classifications and old B12 approval-blocked row. The dated owner decision supplies the subsequent approval state without rewriting that snapshot or its counts, mutating original JSON statuses or converting deferred criteria into evidence.

Maintained architecture remains in [platform architecture](../browser-platform-architecture.md), [engine contract](../browser-engine-contract.md), [MVP acceptance criteria](../browser-mvp-acceptance-criteria.md), [distribution architecture](../browser-distribution.md) and [security criteria](../../security/browser-security-acceptance-criteria.md). They define continuing implementation/release obligations; they are not archived test results. The baseline in this folder is now approved for its stated boundaries and exceptions under the owner decision. This does not implement it or settle its unresolved technology choices. Further alignment of other maintained documents is separately scoped; the explicit dated owner decision governs current approval scope.

[ADR 0001](../../decisions/0001-browser-engine-strategy.md) has its sole canonical home under `docs/decisions/` and remains **Proposed**. There is no ADR copy in this folder. [ADR 0002](../../decisions/0002-browser-distribution-and-platform.md) remains **Accepted**. The recorded owner approvals govern their conditional scope; they do not make ADR 0001 Accepted or remove remaining gates. No approval beyond the three stated decisions is inferred.

Some older proposed implementation sequences still place macOS 26 validation first or require the whole MVP checklist before selection. The newer explicit user scheduling instruction governs macOS 26/signing at final release validation. The reviewed ADR defines Stage A before engine selection, Stage B during implementation and Stage C before final release. These validation stages differ from ledger categories A/B/C/D; their mapping preserves every required outcome and all historical classifications. The Phase 5 plan maps M0-M7 to implementation and M8 to final release. Other maintained files are intentionally unchanged in this milestone.

## Scope and stop point

Keep macOS 26.0+ minimum, internal-only distribution, Swift/AppKit host, React/TypeScript/HeroUI v3 future chrome and engine-independent core. WKWebView has CONDITIONAL ACCEPTANCE for MVP planning and implementation; Chromium/CEF remains evaluation-only; `@vezham/aura` is excluded; no production Tamizhi/cloud dependency is introduced. Public-pages-only testing restrictions remain in force. macOS 26 runtime and signing/notarization stay final-release validation, without a pass claim.

Bounded Phase 3 closure and the architecture baseline are APPROVED; WKWebView has CONDITIONAL ACCEPTANCE for MVP planning and implementation. The conditional direction is not unconditional production-engine approval. It does not close all product/release gates. No prototype source, build or existing evidence is changed. No rebuild, completed-suite rerun, prototype restart, expanded test scope or production work is authorized by reading or generating these documents. Stop after preparation; starting implementation requires a separate scoped execution instruction, not a repeated request for the three owner decisions.
