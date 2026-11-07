# Browser Overview

Vezham Browser is an internal macOS-first product with a macOS 26.0 minimum. Swift/AppKit owns the native host; React/TypeScript/HeroUI v3 is the future browser chrome. Product policy and browser-owned data stay engine-independent.

The Product Owner approved bounded Phase 3 closure and the architecture baseline, with WKWebView conditionally accepted for MVP planning and implementation. ADR 0001 remains Proposed; ADR 0002 is Accepted. Conditional acceptance is not complete browser or release qualification. Current execution is M0 foundation only; M1-M8 are not authorized by the M0 task.

CEF/Chromium is evaluation-only, Aura is excluded, production Tamizhi is out of scope, and identity/cloud is optional. Local browsing must work without Vezham services. No public distribution is authorized.

## Authoritative References

- [Owner Decision](../../../../docs/architecture/phase-3/owner-approval-decision.md)
- [Scope and Milestones](../../../../docs/architecture/phase-5/phase-5-scope-and-milestones.md)

[Browser Handbook](../README.md)
