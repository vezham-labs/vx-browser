# Browser Security

Website content and privileged browser chrome are separate trust domains. Websites must never receive a filesystem, Keychain, shell or general native bridge. Native communication must eventually be typed, versioned, allowlisted and checked for caller origin/frame, ownership, size, freshness and authorization. Credentials/tokens never belong in frontend storage or logs.

M0 has no web view, script handler, URL-opening API or native transport. Its native app uses App Sandbox and Hardened Runtime with no network/device/file-selection entitlements. Development ad-hoc signing is not Developer ID/notarization qualification. Add permissions only in a later scoped implementation with a demonstrated need.

Cross-profile/private leakage and unauthorized native access are hard failures, never accepted exceptions. Unsupported permissions fail closed. Production Tamizhi integration is excluded; any future extraction needs separately approved opt-in scope/destination and prompt-injection defenses.

The [M1 persistence proposal](../../../../docs/architecture/phase-5/reports/M1/local-persistence-architecture.md) separates durable profiles, memory-only private core state, engine website data and native secrets. [Privacy/encryption decisions and risks](../../../../docs/architecture/phase-5/reports/M1/m1-decisions-and-risks.md) remain open before real-data persistence; documentation does not pass private isolation or cleanup tests.

## Authoritative References

- [Threat Model](../../../../docs/security/browser-threat-model.md)
- [Security Architecture](../../../../docs/security/browser-security-architecture.md)
- [Mandatory Security Criteria](../../../../docs/security/browser-security-acceptance-criteria.md)

[Browser Handbook](../README.md)
