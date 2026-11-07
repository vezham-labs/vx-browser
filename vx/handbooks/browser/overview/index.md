# Browser Overview

Vezham Browser is an internal macOS-first product with a macOS 26.0 minimum. Swift/AppKit owns the native host; React/TypeScript/HeroUI v3 is the future browser chrome. Product policy and browser-owned data stay engine-independent.

The Product Owner approved bounded Phase 3 closure and the architecture baseline, with WKWebView conditionally accepted for MVP planning and implementation. ADR 0001 remains Proposed; ADR 0002 is Accepted. Conditional acceptance is not complete browser or release qualification. M0 foundation has a bounded Passed assessment. Current work is M1 design only; recommendations require owner review and implementation needs a separate instruction. M2-M8 remain unstarted.

CEF/Chromium is evaluation-only, Aura is excluded, production Tamizhi is out of scope, and identity/cloud is optional. Local browsing must work without Vezham services. No public distribution is authorized.

The [M1 design packet](../../../../docs/architecture/phase-5/reports/M1/README.md) proposes Swift core and SQLite storage without selecting them as approved decisions or adding features.

## Authoritative References

- [Owner Decision](../../../../docs/architecture/phase-3/owner-approval-decision.md)
- [Scope and Milestones](../../../../docs/architecture/phase-5/phase-5-scope-and-milestones.md)

[Browser Handbook](../README.md)
