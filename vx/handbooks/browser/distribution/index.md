# Browser Internal Distribution

The initial product is internal-only. No public distribution or publishing is authorized. Developer ID Application signing, Apple notarization and Gatekeeper stay mandatory for an internal release. A local ad-hoc M0 app is a development artifact, not a distributable release.

Plan implementation of release controls before final qualification. The actual macOS 26.0/latest supported 26.x matrix, signed/notarized candidate, clean install, sandbox/Hardened Runtime/entitlements, release compatibility/performance and updater security remain Stage C checks. None is pre-passed by the owner decision or M0.

ADR 0002 governs immutable artifacts, signed metadata/digests, channel eligibility, rollout/halt, safe rollback/minimum version, revocation and key custody/rotation. Installer/updater technology and operational ownership remain open; M0 configures no production signing keys or release infrastructure.

## Authoritative References

- [Accepted Distribution ADR](../../../../docs/decisions/0002-browser-distribution-and-platform.md)
- [Distribution Architecture](../../../../docs/architecture/browser-distribution.md)
- [Implementation versus Final Release](../../../../docs/architecture/phase-5/phase-5-scope-and-milestones.md)

[Browser Handbook](../README.md)
