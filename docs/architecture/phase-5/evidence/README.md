# Phase 5 Evidence

Store raw logs, snapshots, machine-generated results and screenshots in a unique
run directory. Do not overwrite a prior run or move Phase 3 evidence here.

Historical M0 run: [20261107T151625Z-m0](20261107T151625Z-m0/repository-baseline.json), linked from the
[M0 report](../reports/M0/README.md). Record actual command, exit code, UTC date,
working tree/base SHA, source hashes, toolchain/OS/SDK and scope with each result.
Redact credentials and browsing content; this native M0 fixture has no websites.

M1 design review run: [20261107T161137Z-m1-design](20261107T161137Z-m1-design/repository-baseline.json), linked from the
[M1 design report](../reports/M1/README.md). It contains repository/source inspection,
documentation review and preservation records only; no build, app launch, product
test, database or performance result. Keep M0 evidence unchanged.

Development signing/build/launch is not Developer ID/notarization, macOS 26 runtime,
engine or product security qualification. Preserve failed prerequisite commands
and corrected attempts with their distinct reasons, rather than hiding failures
or running unchanged retries. Build outputs/caches remain ignored under the app;
only bounded review evidence belongs here.

## 2026-11-08 M1 consolidated closeout

[Run records](20261108T094414Z-m1-consolidated-closeout/) preserve exact supplied sources, original tracked hashes, disposable harness revisions, failed/inconclusive native observations, blocked campaign reports and final preservation audit. No Phase3 evidence is overwritten; no production/release qualification.
