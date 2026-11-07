# Browser Decisions and Authority

ADRs have a single canonical location under `docs/decisions/`; this handbook links them instead of copying them. ADR 0001 remains Proposed while recording the owner's conditional WKWebView decision. ADR 0002 remains Accepted. The owner approval record is the dated authority for bounded Phase 3 closure, conditional engine acceptance and approved architecture boundaries.

Do not infer unconditional engine approval, grant new access or waive security/release gates from a status label. Keep historical Phase 3 reports/ledger unchanged; later approval records and implementation reports provide subsequent state. Current authorization covers M1 design only; implementation and M2-M8 require separate instructions.

Material M0 choices and alternatives are recorded separately. Core runtime, storage, UI transport, capability policy, approved critical workflows and release tooling require future decisions before dependent implementation, not invented placeholders now.

[ADR0003 — Proposed](../../../../docs/decisions/0003-browser-core-runtime-and-language.md) recommends Swift core; [ADR0004 — Proposed](../../../../docs/decisions/0004-browser-local-persistence.md) recommends SQLite with explicit protection/privacy conditions. The [M1 decision register](../../../../docs/architecture/phase-5/reports/M1/m1-decisions-and-risks.md) distinguishes owner decisions, recommendations and deferred scope. No approval or ADR status transition is inferred.

## Authoritative References

- [ADR 0001 — Proposed](../../../../docs/decisions/0001-browser-engine-strategy.md)
- [ADR 0002 — Accepted](../../../../docs/decisions/0002-browser-distribution-and-platform.md)
- [Product Owner Approval](../../../../docs/architecture/phase-3/owner-approval-decision.md)
- [M0 Decisions](../../../../docs/architecture/phase-5/reports/M0/m0-foundation-decisions.md)

[Browser Handbook](../README.md)
