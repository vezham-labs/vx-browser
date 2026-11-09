# ADR 0006: Workspace identity and versioned layout

- **Status:** PROPOSED
- **Date:** 2026-11-10
- **Decision owner:** Vezham Browser product owner with Core and persistence reviewers
- **Authorization:** Documentation and review. Implementation requires a separate scoped instruction.

## Context

The current AppKit controller keys tab membership and split state by `ViewID`. An explicit private recovery replaces those IDs. Workspace metadata needs a longer lifetime than an engine object and a coherent boundary for restore, migration, validation and atomic publication. ADR 0004 and Option D already govern data custody. This decision defines logical identity and snapshot semantics within those boundaries. [Source assessment](../architecture/phase-5/reports/WS-F6/current-state-assessment.md) · [ADR 0004](0004-browser-local-persistence.md) · [Option D](../architecture/phase-5/reports/WS-F3/approved-decisions.md)

## Proposed decision

Use typed stable workspace, Space, group and tab IDs. Preserve identities across presentation and view lifecycle. The single library writer publishes one versioned catalog/session revision with explicit order and validated membership. One main mount owns a workspace's presentation in the first slice. A Space organizes tabs and conveys no separate website-data authority. A split is layout intent with two same-Space members, focus and divider preference. The native host owns attachment and actual geometry.

V1 starts as a synthetic layout contract with explicit validation, bounded normalization of missing optional references, known-version migration and compare-and-replace publication. Structural rejection and unknown versions preserve source bytes. Keep private state volatile. F7 provides protected authority for real records. [Data model](../architecture/phase-5/reports/WS-F6/workspace-data-model.md) · [Persistence](../architecture/phase-5/reports/WS-F6/persistence-and-recovery.md)

## Alternatives

| Alternative                                            | Trade-off                                                                                                                     |
| ------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| Persist current view IDs and controller dictionaries   | Small initial change with fragile references after retirement, recovery and restart.                                          |
| Derive identity from names, URLs or positions          | Renaming, reordering and duplicate URLs can collide. URL-derived identities also expose browsing information.                 |
| Independent mutable files per workspace and per window | Simpler local edits, with greater partial-publication and cross-reference risk.                                               |
| Stable logical graph with one revision                 | More explicit validation and mutation logic. Supports migrations and deterministic recovery without retaining engine handles. |

## Consequences and qualification

Close/retry and saved layout now have separate outcomes. Existing Core/native lifecycle remains authoritative for resources. Scope is local and bounded, with one writer and no cloud merge. Require G1 and G4 validation for ordering, deletion, optional repair, structural rejection, corruption, concurrent writes, migration, rollback and private exclusion. Require G5 and approved retention before real metadata writes. [Qualification matrix](../architecture/phase-5/reports/WS-F6/qualification-matrix.md)
