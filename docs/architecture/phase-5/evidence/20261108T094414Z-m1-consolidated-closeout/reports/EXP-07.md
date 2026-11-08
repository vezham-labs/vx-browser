# EXP-07 — Evidence report

Execution date:2026-11-08. Reviewer:Codex automated engineering agent; independent engineering/security sign-off not established. **Outcome:BLOCKED.** This is not a release or product acceptance.

- Procedure/version:[Validation Plan v1.1](../../../reports/M1/m1-validation-plan.md), EXP-07; [frozen native subset](../procedure.md) where applicable.
- Existing experiment reference(s):BACKUP-001, BACKUP-002, BACKUP-003 (not additional validation cases).
- Environment:[environment.json](../environment.json), arm64 macOS27.2/SDK27.2/Swift6.4.2; target26.0. No macOS26 runtime qualification.
- Fixtures:[fixtures.json](../fixtures.json); synthetic owned resources only. No personal browsing profiles, production secrets or irreplaceable files.
- Actual execution/results:Preflight only. Encrypted provider, independent recovery, coherent archive/promotion and WebKit backup contracts absent; independent Mac not provisioned.
- Evidence:[validation-preflight.json](../results/validation-preflight.json). Exact commands/stdout/stderr/times are retained in results records for executed actions.
- Limitations/blockers:No actual archives/restores or personal files. No silent overwrite. Browser-owned and WebKit coverage remain distinct; payload exclusion/optional selection is owner-decided.
- Cleanup:[cleanup-only result](../results/cleanup-only-result.json) and [native log](../results/cleanup-only-native.json). After initial live-handle refusal, cleanup-only follow-up crashed. Completion is unknown; registered generated IDs are retained for a future bounded cleanup investigation, not manually deleted. Loopback fixture servers were shut down by runner finally blocks; no TCC/Keychain/native device permission changed.
- Follow-up:see [implementation plan](../../../reports/M1/m1-implementation-plan.md), relevant packages. Product fixes are proposed work only; no implementation authorized. Never convert a blocked/inconclusive subset to PASS.

