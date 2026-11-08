# EXP-02 — Evidence report

Execution date:2026-11-08. Reviewer:Codex automated engineering agent; independent engineering/security sign-off not established. **Outcome:INCONCLUSIVE.** This is not a release or product acceptance.

- Procedure/version:[Validation Plan v1.1](../../../reports/M1/m1-validation-plan.md), EXP-02; [frozen native subset](../procedure.md) where applicable.
- Existing experiment reference(s):PRIV-001 (not additional validation cases).
- Environment:[environment.json](../environment.json), arm64 macOS27.2/SDK27.2/Swift6.4.2; target26.0. No macOS26 runtime qualification.
- Fixtures:[fixtures.json](../fixtures.json); synthetic owned resources only. No personal browsing profiles, production secrets or irreplaceable files.
- Actual execution/results:Native private store nonpersistence flag, same-group sharing, independent-group isolation and fresh-private-store absence were observed for cookies/LocalStorage/IndexedDB/cache/service-workers. No failed private check flag.
- Evidence:[native-seed-observations.json](../results/native-seed-observations.json). Exact commands/stdout/stderr/times are retained in results records for executed actions.
- Limitations/blockers:No actual browser-owned private repositories/history/grants/download metadata/staging; no abrupt interruption or proven final-owner disposal. Fresh empty store does not prove forensic erasure or all cleanup.
- Cleanup:[cleanup-only result](../results/cleanup-only-result.json) and [native log](../results/cleanup-only-native.json). After initial live-handle refusal, cleanup-only follow-up crashed. Completion is unknown; registered generated IDs are retained for a future bounded cleanup investigation, not manually deleted. Loopback fixture servers were shut down by runner finally blocks; no TCC/Keychain/native device permission changed.
- Follow-up:see [implementation plan](../../../reports/M1/m1-implementation-plan.md), relevant packages. Product fixes are proposed work only; no implementation authorized. Never convert a blocked/inconclusive subset to PASS.


## Observation precision

Cache markers exercise the CacheStorage API, not all HTTP/disk-cache behavior. Service-worker checks observe registration counts/readiness, not complete worker execution or every associated resource. Views are loaded in a bounded sequence; no scheduling-race qualification. Reading an empty IndexedDB fixture can create an empty database; marker absence is not forensic erasure. These limitations prevent broader protection/cleanup/compatibility claims.
