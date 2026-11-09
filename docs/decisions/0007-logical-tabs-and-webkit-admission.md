# ADR 0007: Logical tabs and WebKit admission

- **Status:** Accepted for the scoped WS-F6 in-memory implementation
- **Date:** 2026-11-10
- **Decision owner:** Vezham Browser product owner with native lifecycle and security reviewers
- **Authorization:** The WS-F6 implementation brief authorizes logical private recovery and lifecycle integration while preserving the existing poison and retirement guarantees.

## Context

Current tab creation and private replacement allocate live WebKit views eagerly. The logical workspace should be available independently of those views. WKWebView construction, store assignment and Core authority must continue to protect website state. A native scope can retire on its last view even when the proposed graph still contains dormant logical slots. [Source assessment](../architecture/phase-5/reports/WS-F6/current-state-assessment.md) · [ADR 0005](0005-browser-capability-boundaries-and-lifecycle.md)

## Decision

Use ADR 0006 logical identity, with one host-owned runtime binding per eligible slot and generation. Build only on visible authorized demand with explicit eligible navigation or an owned fixture intent. Blank and initially hidden slots have no website view. Serialize openings within a scope, deduplicate a slot's pending demand, verify ownership and store before construction, and recheck view, epoch, operation, mount and visibility before attach or load. An old or stale output retires through Core. Keep split intent in the layout and native view attachment in AppKit. A narrow split shows only the focused member while preserving the pair.

The existing poison, authority and retirement fences govern callbacks and close. Recoverable local failure can leave a healthy sibling usable. A poisoned scope blocks both panes in that scope. F6 retains live views until explicit lifecycle teardown and migrates private recovery to stable logical IDs with blank demand-based replacement. [Lifecycle](../architecture/phase-5/reports/WS-F6/webkit-admission-and-lifecycle.md) · [Split](../architecture/phase-5/reports/WS-F6/split-screen-and-mini.md)

## Alternatives

| Alternative                                              | Trade-off                                                                                                                        |
| -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Eagerly rebuild all tabs                                 | Simpler immediate binding with unnecessary allocation on launch and no explicit dormant state.                                   |
| Pool or move live WebKit views across scopes             | Can preserve live page state, at the cost of ambiguous authority and storage identity.                                           |
| Build on demand and automatically evict live views       | Reduces resident work, with additional form/media state loss and recovery requirements.                                          |
| Demand-based construction with retained in-session views | Bounds initial work, preserves live navigation where possible, and requires a generation-aware registry and teardown discipline. |

## Consequences and qualification

Native performance must be measured. No process topology or memory reduction is inferred from the proposed model. Require G2 and G4 on duplicate/stale admission, denied default stores, zero hidden starts, last-view retirement, poison handling and resource release. Actual process-exit testing remains subject to safe attribution. Require G3 for focus, resize, divider and compact presentation. Conditional system WebKit and native composition remain under ADRs 0001 and 0005. [Qualification](../architecture/phase-5/reports/WS-F6/qualification-matrix.md) · [Engine ADR](0001-browser-engine-strategy.md)

## Implementation disposition · 2026-11-10

The user authorized implementation of the existing product direction and resolution of ordinary design details. The current volatile private browser now consumes the workspace model and native binding path. Normal URL retention/replay remains unavailable, Mini accepts only proven direct GETs without queries or fragments, and private recovery preserves logical IDs with blank replacement pages. Existing Core quarantine and uncertain-retirement fences remain authoritative. Native tests observed the scoped behavior after an injected recovery callback. Real WebKit helper termination and release acceptance retain their separate gates. [Implementation report](../architecture/phase-5/reports/WS-F6/implementation-report.md) · [Actual qualification](../architecture/phase-5/reports/WS-F6/implementation-qualification.md)
