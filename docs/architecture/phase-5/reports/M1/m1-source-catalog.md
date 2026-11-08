# M1 Canonical Source Catalog and Supersession Record

Version1.1,2026-11-08. Authority: [current owner instruction](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/owner-task-authorization.txt). Documentation and isolated validation/planning Authorized; no product implementation/release authority.

## Canonical maintained set

| Purpose | Actual path in this directory | Version/status | Relationship |
|---|---|---|---|
| Architecture/design | [browser-core-architecture.md](browser-core-architecture.md), [core-boundary-contracts.md](core-boundary-contracts.md), [data model](browser-core-data-model.md), [persistence](local-persistence-architecture.md), [recovery](migration-and-recovery-strategy.md), [capabilities](browser-capability-architecture.md) | Proposed supporting designs plus current scope notices | DS§32 owns current engineering dispositions; historic proposals do not override current owner policy |
| Owner decisions/scope | [m1-owner-decision-register.md](m1-owner-decision-register.md) | v1.1; owner-approved direction | Exact OD-R entries, current OP decisions,26 capabilities and historical crosswalk |
| Developer specification | [m1-developer-specification.md](m1-developer-specification.md) | v1.1 Proposed | Current requirements/policy/coverage/engineering gaps; not validated implementation |
| Validation plan | [m1-validation-plan.md](m1-validation-plan.md) | v1.1 Proposed procedures | Current authorization with original EXP procedures and run reports |
| Supporting charters | [m1-supporting-validation-charters.md](m1-supporting-validation-charters.md) | v1.1 Proposed | All five charters preserved; C02/C03 corrected explicitly |
| Case traceability | [m1-case-level-traceability.md](m1-case-level-traceability.md) | v1.2 Proposed |154 cases +11 references; preserved mappings and separate actual outcomes |
| Experiment evidence | [this run](../../evidence/20261108T094414Z-m1-consolidated-closeout/), [activity reports](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/) | Actual diagnostic records/blocked assessments | Not release or production acceptance; per-row JSON is audit input |
| Implementation plan | [m1-implementation-plan.md](m1-implementation-plan.md) | v1.1 Proposed,19 work packages | Backlog only; not implementation authorization |
| Final closeout | [m1-closeout-report.md](m1-closeout-report.md) | v1.1 qualified closeout | Consolidates this bounded task, remaining blockers and handoff |

## Supplied sources preserved verbatim

The four review deliverables were not found as canonical repository files before this task. They were retrieved from the complete supplied chat documents, not reconstructed from summaries. [Archived Developer Specification](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/developer-specification-v1.0-proposed.md), [Validation Plan](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/validation-plan-v1.0-proposed.md), [Supporting Charters](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/supporting-validation-charters-v1.0-proposed.md), [Case Matrix](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/case-level-traceability-v1.1-proposed.md), [Owner Readiness Review v1.1](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/owner-readiness-review-v1.1-proposed.md) retain exact text. Their original no-execution/unresolved-policy language is historical and superseded only by the current instruction and maintained documents. They are not competing latest specifications.

The previous repository M1 README/implementation plan are [archived](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/) before replacement. [Historical owner packet](m1-owner-decision-packet.md), [decision/risk proposals](m1-decisions-and-risks.md), [old execution proposal](m1-implementation-authorization-proposal.md), DSH assessment and historical evidence retain their IDs/meanings. Current owner decisions do not retroactively approve the historical OD20 implementation proposal.

## ADR/platform/source controls

ADR0001 Proposed,0002 Accepted,0003–0005 Proposed; no status transition. Conditional WKWebView, CEF evaluation-only, Aura excluded, no production Tamizhi/cloud dependency, no public distribution. macOS26 minimum remains;27.2 native results are discovery. Phase3 source/evidence/manifests are preserved; historical49/49 and48/48 results are not combined with current observations.

Original tracked-file hashes/HEAD/branch/clean state: [baseline](../../evidence/20261108T094414Z-m1-consolidated-closeout/repository-baseline.json). Current source/probe hashes, commands and environment: [results](../../evidence/20261108T094414Z-m1-consolidated-closeout/results/), [environment](../../evidence/20261108T094414Z-m1-consolidated-closeout/environment.json). Final preservation audit records actual changed paths; no commit/push/branch change.

