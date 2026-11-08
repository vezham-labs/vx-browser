# M1 Canonical Engineering Baseline

Updated2026-11-08. Documentation consolidation, isolated validation and implementation planning Authorized; product implementation/release Not Authorized. The [primary closeout](m1-closeout-report.md) owns this task's outcomes; no M1 product completion claim.

## Canonical documents

- [Source catalog and supersession](m1-source-catalog.md).
- [Owner decision/scope register](m1-owner-decision-register.md): preserved OD-R01–20/WS01.1, owner-decided OP-01–04,26-capability OD17 scope and historical OD18 distinction.
- [Architecture](browser-core-architecture.md), [boundary contracts](core-boundary-contracts.md), [data model](browser-core-data-model.md), [persistence](local-persistence-architecture.md), [recovery](migration-and-recovery-strategy.md), [capabilities](browser-capability-architecture.md): supporting Proposed designs; current technical dispositions in the specification.
- [Developer Specification v1.1 — Proposed](m1-developer-specification.md): REQ/AC/SPEC, policy,26-capability coverage, unresolved engineering definitions and implementation traceability.
- [Validation Plan v1.1](m1-validation-plan.md) and [Supporting Charters v1.1](m1-supporting-validation-charters.md).
- [Case Matrix v1.2](m1-case-level-traceability.md):154 validation cases +11 experiment-reference rows; preserved mappings and actual outcomes.
- [Evidence and13 reports](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/), [run environment](../../evidence/20261108T094414Z-m1-consolidated-closeout/environment.json), [frozen native procedure](../../evidence/20261108T094414Z-m1-consolidated-closeout/procedure.md), [row results](../../evidence/20261108T094414Z-m1-consolidated-closeout/traceability-results.json).
- [Implementation plan v1.1](m1-implementation-plan.md):19 proposed work packages; no implementation authorization.
- [Primary consolidated closeout](m1-closeout-report.md).

## Results and limitations

EXP-01 FAIL on retained cleanup assertion; EXP-02 INCONCLUSIVE normal native subset; EXP-03–08 and SVC-01–05 BLOCKED. No complete REQ/AC passes. All154 product validation cases preflight-blocked; do not count experiment-reference observations as case passes. Native environment macOS27.2/arm64 with26.0 compile target; final macOS26 qualification remains Stage C. Cleanup-only follow-up crashed; two owned synthetic store cleanup states are unknown and retained for bounded diagnosis. No personal profiles/default stores, secrets, device permissions or irreplaceable files used.

## Historical sources

The original [owner packet](m1-owner-decision-packet.md), [decision/risk proposals](m1-decisions-and-risks.md), [launch matrix](m1-launch-feature-matrix.md), [execution proposal](m1-implementation-authorization-proposal.md) and DSH review retain historical IDs/meanings. [Exact supplied sources and prior repository documents](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/) are preserved; current canonical documents supersede old policy/authority proposals rather than silently rewriting history. Phase3 source/evidence/manifests are unchanged and never transferred as current acceptance. [Final audit](../../evidence/20261108T094414Z-m1-consolidated-closeout/final-audit.json).

ADR0001 Proposed;0002 Accepted;0003–0005 Proposed. Conditional WKWebView; CEF evaluation-only; no Aura, production Tamizhi, mandatory cloud/identity or public distribution. Local browsing must work without cloud or local-server dependency. No release authority or product implementation is granted by this index.
