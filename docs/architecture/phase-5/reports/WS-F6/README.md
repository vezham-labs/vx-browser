# WS-F6 · Workspace Foundation

**Status: PROPOSED design package, 2026-11-10.** The checked-out branch `cross-browser-research` started clean at `19337b01c62a7527d4288b149dd742853ad92b5f`. A fresh fetch of its upstream showed zero commits ahead and zero behind. The package uses that exact source and evidence baseline.

## Executive summary

Vezham should make it easy to resume a project, work with two sites together, and triage a link in a temporary Mini. WS-F6 proposes stable workspace and tab identities, a versioned layout, demand-driven WebKit admission, two-pane restoration, and a destination-aware Mini handoff. It uses synthetic fixtures to qualify these contracts while WS-F7 owns the prerequisites for real-user writes and protected profiles. The product remains a native macOS AppKit host with system WebKit and the existing bundled React/TypeScript/HeroUI chrome.

## Proposed decisions and scope

| ID  | Decision                                                                                                                                                                                  |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D1  | Use a single writer for workspace structure and session layout, with typed stable IDs, ordered membership and explicit transaction revisions.                                             |
| D2  | Keep the logical tab independent of `ViewID`. Admit and attach only eligible visible content through Core and native authority, and keep ordinary failure distinct from a poisoned scope. |
| D3  | Own the pair, focused member and divider preference in the workspace layout. Render the split through AppKit, with a one-pane presentation at narrow widths.                              |
| D4  | Keep Mini in a distinct nonpersistent session. Require an explicit URL-only destination and a correlated main-frame commit before automatic closure.                                      |
| D5  | Qualify versioning and crash recovery on synthetic records. Gate product persistence, profile binding, custody and backup on WS-F7 and the existing Option D requirements.                |

Workspace organization, two-pane workflows, private Quick Browse and session-specific command actions define the proposed launch experience. Alternate engines, extension parity, generalized automation, per-Space cookie isolation, credential migration, cloud sync, live tab discard, and durable private recovery are outside WS-F6. A baseline comparison and decision-to-test mapping are in the [traceability matrix](traceability-matrix.md).

## Acceptance gates

| Gate                  | Evidence required                                                                                                                                                                                          |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| G0 · Entry            | Separate implementation authorization and a recorded WS-F5R exit or owner disposition for affected cases. Retain all existing unresolved cases and evidence classes.                                       |
| G1 · Model            | Deterministic graph validation, revision conflict handling, stable IDs, and fixture migration and failure preservation.                                                                                    |
| G2 · Admission        | Current authority checked before allocation, publication, attachment and fresh load. No hidden initial work, duplicate view or stale attachment. Native cleanup and failure tests are separate from fakes. |
| G3 · Interaction      | Native pair/focus/resize and Mini handoff/cleanup tested with owned fixtures. Physical drag and VoiceOver require their own operator evidence.                                                             |
| G4 · Fixture closeout | Repeated tests and scoped native observations on a pinned candidate, no private metadata persistence, release of observed resources and an explicit backlog for blocked cases.                             |
| G5 · Product rollout  | WS-F7 protected catalog and signed custody gates plus WS-F8 final signed internal release evidence. F6 synthetic success cannot satisfy these gates.                                                       |

The existing WS-F5R callback evidence remains bounded to an injected trigger. Real helper attribution and termination/recovery, physical drag, observable VoiceOver speech/captions, successful downloads, external authentication and real macOS 26 coverage retain their documented dispositions. [Current-state assessment](current-state-assessment.md) · [WS-F5R case matrix](../WS-F5R/evidence/execution-01/test-matrix.md)

## Review package

- [Product direction](product-direction.md)
- [Current-state assessment](current-state-assessment.md)
- [Workspace architecture](workspace-architecture.md)
- [Workspace data model](workspace-data-model.md)
- [WebKit admission and lifecycle](webkit-admission-and-lifecycle.md)
- [Split Screen and Vezham Mini](split-screen-and-mini.md)
- [Persistence and recovery](persistence-and-recovery.md)
- [Implementation plan](implementation-plan.md)
- [Qualification matrix](qualification-matrix.md)
- [Risk register](risk-register.md)
- [Traceability matrix](traceability-matrix.md)
- [Main-chat handoff](main-chat-handoff.md)

Proposed decisions are recorded in [ADR 0006](../../../../decisions/0006-workspace-identity-and-versioned-layout.md), [ADR 0007](../../../../decisions/0007-logical-tabs-and-webkit-admission.md) and [ADR 0008](../../../../decisions/0008-mini-isolation-and-url-handoff.md). [ADR 0004](../../../../decisions/0004-browser-local-persistence.md) and the [WS-F3 owner decision](../WS-F3/approved-decisions.md) continue to govern persistence.
