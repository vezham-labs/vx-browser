# WS-F2R-A · Persistence architecture reassessment

**Investigation complete · architecture proposal for owner review · 2026-11-09**

The review recommends **Option D**, with WebKit retaining website storage, macOS supplying native security services and Vezham protecting the browser product data it owns. SQLCipher remains the leading candidate for protected SQLite tiers if the existing-file policy and qualification gates are resolved. Ordinary SQLite does not meet full persistent-profile encryption. No D2A-01 decision was made. Start with the [recommended architecture](recommended-architecture.md) and [outstanding decisions](open-questions.md).

| Report | Scope |
|---|---|
| [Current-state assessment](current-state-assessment.md) | Source and runtime boundaries; specific integration gaps |
| [Ownership boundaries](ownership-boundaries.md) | Public WebKit API/SDK review, native security services and lifecycle |
| [Data classification](data-classification.md) | Ownership, sensitivity, storage, protection and disposition per class |
| [SQLCipher reassessment](sqlcipher-reassessment.md) | Provenance, key and write/recovery mechanics, twelve explicit questions |
| [D2A-01 impact](d2a-01-impact-analysis.md) | Pinned source order, two owner options and security objectives |
| [Architecture options](architecture-options.md) | A–D technical comparison and qualification limits |
| [Security threat model](security-threat-model.md) | Threat boundaries, 19 failure scenarios and evidence oracles |
| [Owner decision traceability](owner-decision-traceability.md) | OD-R01–20 and related OP policy coverage for A–D |
| [Backup, recovery and migration](backup-recovery-migration.md) | Portable owned format, key custody and crash-safe design requirements |
| [Engine independence](engine-independence.md) | Typed boundaries and future engine transition |
| [Performance and maintainability](performance-maintainability.md) | Expected costs and proposed workloads |
| [Recommended architecture](recommended-architecture.md) | Executive proposal, trade-offs and mandatory gates |
| [Implementation impact](implementation-impact.md) | Gated sequence under future authorization |
| [Open questions](open-questions.md) | Owner decisions, technical specifications and validation dependencies |
| [Evidence index](evidence-index.md) | Exact baseline, source and archived run references, preservation and non-execution |

Scope is investigation and documentation only. Existing ADRs, D2A-01, owner decisions and historical reports are authoritative within their recorded status. This package supplies no implementation, qualification, release or distribution authority. WKWebView remains conditional, Chromium/CEF evaluation-only, and the internal-only macOS 26+ baseline remains in place.
