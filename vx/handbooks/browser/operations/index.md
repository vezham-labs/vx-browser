# Browser Operations

M0 is a local native host with no browsing state, service integration, telemetry pipeline or release updater. There is no production support/deployment runbook to claim complete. Diagnose only the current build/task and preserve command logs, source/configuration hashes and observed error codes without collecting page data or credentials.

Use the M0 report and run-specific evidence to distinguish a build/configuration failure from a host runtime or protection failure. Do not repeatedly relaunch unchanged prototypes, weaken OS protections or terminate unrelated WebKit processes. Later engine diagnostics require explicit disposable-process attribution.

Before internal deployment, name owners for OS-driven WebKit regressions, security response, release health/halt, revocation/minimum versions and credential/key rotation. Logs/crash reports must redact tokens, sensitive URLs/content, file paths and private identifiers; OS/engine diagnostics need review rather than assumed safety.

The [M1 migration/recovery proposal](../../../../docs/architecture/phase-5/reports/M1/migration-and-recovery-strategy.md) defines future store/version/key/corruption and privacy-clear behavior. It is not an implemented recovery runbook. Assign storage/security/incident owners and validate the corresponding implementation before operating real browsing data.

## Authoritative References

- [Security and Incident Requirements](../../../../docs/security/browser-security-architecture.md)
- [Release Operations Requirements](../../../../docs/architecture/browser-distribution.md)
- [Current M0 Outcome and Blockers](../../../../docs/architecture/phase-5/reports/M0/README.md)

[Browser Handbook](../README.md)
