# Browser Architecture

The native host owns application/window lifecycle and native authorization. The core will own engine-independent product policy and local state. An adapter will translate that policy to WKWebView while keeping engine objects private. Chrome presents sanitized state and typed intent in a dedicated app-owned surface; remote website content is a separate, untrusted trust domain.

M0 creates only the AppKit host target. It does not implement a core runtime, store, WK adapter, React surface or bridge. Future modules are boundary responsibilities, not empty placeholder packages. [M1 design](../../../../docs/architecture/phase-5/reports/M1/browser-core-architecture.md) now proposes a Swift core with domain/ports/runtime/persistence targets and SQLite behind repositories; owner approval is pending. Chrome resource origin/transport and actual engine/native integration remain later decisions.

Only supported public native APIs belong in product code. Host-only private diagnostic tools preserved with Phase 3 evidence must never become a production dependency. Engine independence does not promise identical engine capabilities, a renderer per profile or lossless engine-store migration.

See the [data model](../../../../docs/architecture/phase-5/reports/M1/browser-core-data-model.md) and [boundary contracts](../../../../docs/architecture/phase-5/reports/M1/core-boundary-contracts.md) for planned ownership, epochs/revisions and cancellation. These are proposals, not implemented APIs.

## Authoritative References

- [Platform Architecture](../../../../docs/architecture/browser-platform-architecture.md)
- [Engine Contract](../../../../docs/architecture/browser-engine-contract.md)
- [Approved Boundary Baseline](../../../../docs/architecture/phase-3/browser-mvp-architecture-baseline.md)
- [M0 Implementation Decisions](../../../../docs/architecture/phase-5/reports/M0/m0-foundation-decisions.md)

[Browser Handbook](../README.md)
