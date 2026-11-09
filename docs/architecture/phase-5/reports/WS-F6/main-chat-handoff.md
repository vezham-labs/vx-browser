# Main-chat handoff

## Baseline and deliverables

`vezham-labs/vx-browser`, `cross-browser-research`, baseline `19337b01c62a7527d4288b149dd742853ad92b5f`. The branch was clean and matched its fetched upstream. The documentation package is under `docs/architecture/phase-5/reports/WS-F6/`, with ADRs 0006–0008 proposed under `docs/decisions/`. [Package index](README.md) · [Source assessment](current-state-assessment.md) · [Traceability](traceability-matrix.md)

The package proposes typed workspace/Space/group/tab IDs and one versioned layout revision; one mounted main workspace; lazy, authorized view binding; layout-owned two-pane focus and divider; and independent Mini with a previewed, commit-aware URL-only handoff. F6 qualification uses synthetic data and an isolated native fixture. F7 owns production protected writes, signed custody, isolation and backup. F8 owns signed release and platform/upgrade validation. No design proposal constitutes product implementation or acceptance.

## Review decisions still open

- Confirm the V1 layout shape, fixture caps, one-mounted-workspace rule, split thresholds and initial command discoverability scope.
- Confirm the launch layout-only restore policy, future navigation provenance/retention requirements, and whether the conservative Mini URL eligibility rules fit the intended workflows.
- Decide if and when to migrate the existing product private path to logical IDs. Require separate recovery and teardown regression evidence.
- Establish production catalog and signed Keychain authority and access to the release OS matrix. Preserve real helper attribution/termination, physical drag, VoiceOver speech/captions, successful downloads and external auth as open WS-F5R cases where applicable. [Risk register](risk-register.md) · [Existing WS-F5R matrix](../WS-F5R/evidence/execution-01/test-matrix.md)

## Next steps

1. Review the package and its three proposed ADRs, settle the fixture contract and confirm the affected WS-F5R prerequisites. If a gate is open, record its disposition in the owning workstream.
2. Once separately authorized, implement W1 in the isolated fixture lane. Begin with typed IDs, normalization, revisioned compare-and-replace, fixture migration and negative cases. Require G1 before connecting any host.
3. Review W2 ownership and final-view retirement, then add W3 Split/command/focus and W4 Mini using the qualified fixture binding. Use a new output directory and preserve historical evidence.
4. Close out F6 with the matrix and a pinned candidate. Keep real-user persistence and release dependent on WS-F7 and WS-F8. [Implementation plan](implementation-plan.md) · [Qualification matrix](qualification-matrix.md)

## Copy-ready handoff

> WS-F6 design is ready for review on `cross-browser-research` at baseline `19337b0`. Start with the WS-F6 report index, ADRs 0006–0008, and the qualification matrix. Review stable layout IDs, lazy WebKit admission, remembered two-pane intent and Mini's explicit URL-only handoff. Preserve the WS-F5R real-termination, attribution, drag, VoiceOver, download, external auth and macOS 26 dispositions. After separate implementation authorization and G0 review, start W1 with synthetic model/revision/migration tests. Keep real workspace writes behind WS-F7 and signed release behind WS-F8. This branch contains planning documentation only.
