# Vezham Browser Handbook

The canonical developer-facing entry point for Browser knowledge is
`vx/handbooks/browser/`. Follow the existing Vx plain-Markdown, relative-link and
heading conventions; no separate docs framework or frontmatter is introduced.
Detailed architecture, ADRs and milestone records stay in `docs/` as linked
sources of truth. This handbook organizes and summarizes them, not a second copy.

## Current Decision and Execution State

Phase 3 bounded closure and the architecture baseline are APPROVED. WKWebView has
CONDITIONAL ACCEPTANCE for MVP planning and implementation. ADR 0001 remains
Proposed; ADR 0002 is Accepted. M0 native-host foundation has a bounded Passed exit assessment; M1 design is prepared for owner review; M1 implementation and M2-M8 remain Not Started.
Conditional acceptance does not establish browser/release readiness. No Aura,
CEF/Chromium implementation, production Tamizhi or public distribution is in scope.
Identity/cloud stays optional; local browsing must not depend on Vezham services.

## Handbook Navigation

- [Overview](./overview/index.md)
- [Architecture](./architecture/index.md)
- [Engineering](./engineering/index.md)
- [Security](./security/index.md)
- [Development](./development/index.md)
- [Testing and Evidence](./testing/index.md)
- [Internal Distribution](./distribution/index.md)
- [Operations](./operations/index.md)
- [Decisions](./decisions/index.md)

## Authority and Historical Evidence

- [Owner Approval](../../../docs/architecture/phase-3/owner-approval-decision.md)
- [Approved Architecture Baseline](../../../docs/architecture/phase-3/browser-mvp-architecture-baseline.md)
- [ADR 0001 — Proposed](../../../docs/decisions/0001-browser-engine-strategy.md)
- [ADR 0002 — Accepted](../../../docs/decisions/0002-browser-distribution-and-platform.md)
- [Phase 3 Exit Review](../../../docs/architecture/phase-3/phase-3-exit-review.md)
- [Phase 5 Plan](../../../docs/architecture/phase-5/README.md)
- [M0 Report](../../../docs/architecture/phase-5/reports/M0/README.md)
- [M1 Core and Local State Design](../../../docs/architecture/phase-5/reports/M1/README.md)
- [ADR 0003 — Core Runtime, Proposed](../../../docs/decisions/0003-browser-core-runtime-and-language.md)
- [ADR 0004 — Local Persistence, Proposed](../../../docs/decisions/0004-browser-local-persistence.md)
- [Documentation Mapping and Cleanup](../../../docs/architecture/phase-5/reports/M0/documentation-mapping-and-cleanup.md)

The original Codex records were imported once into this existing repository with
hash provenance; their original source location remains preserved as a historical
snapshot. Maintained documents in this checkout are now the current sources.
Phase 3 source/evidence/reports/manifests/archives stay unchanged and separate from
new milestone evidence. Historical 49/49 recovery and 48/48 regression are distinct suites;
older performance is not current-revision qualification. Unresolved choices and
blocked/deferred gates are neither silently implemented nor relabelled Passed.
