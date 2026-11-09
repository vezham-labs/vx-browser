# ADR 0007: Logical tabs and WebKit admission

- **Status:** PROPOSED
- **Date:** 2026-11-10
- **Decision owner:** Vezham Browser product owner with native lifecycle and security reviewers
- **Authorization:** Documentation and review. No change to existing recovery, ports or runtime.

## Context

Current tab creation and private replacement allocate live WebKit views eagerly. The logical workspace should be available independently of those views. WKWebView construction, store assignment and Core authority must continue to protect website state. A native scope can retire on its last view even when the proposed graph still contains dormant logical slots. [Source assessment](../architecture/phase-5/reports/WS-F6/current-state-assessment.md) · [ADR 0005](0005-browser-capability-boundaries-and-lifecycle.md)

## Proposed decision

Use ADR 0006 logical identity, with one host-owned runtime binding per eligible slot and generation. Build only on visible authorized demand with explicit eligible navigation or an owned fixture intent. Blank and initially hidden slots have no website view. Serialize openings within a scope, deduplicate a slot's pending demand, verify ownership and store before construction, and recheck view, epoch, operation, mount and visibility before attach or load. An old or stale output retires through Core. Keep split intent in the layout and native view attachment in AppKit. A narrow split shows only the focused member while preserving the pair.

The existing poison, authority and retirement fences govern callbacks and close. Recoverable local failure can leave a healthy sibling usable. A poisoned scope blocks both panes in that scope. F6 introduces no automatic discard policy or change to the existing product private recovery path. [Lifecycle](../architecture/phase-5/reports/WS-F6/webkit-admission-and-lifecycle.md) · [Split](../architecture/phase-5/reports/WS-F6/split-screen-and-mini.md)

## Alternatives

| Alternative                                              | Trade-off                                                                                                                        |
| -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Eagerly rebuild all tabs                                 | Simpler immediate binding with unnecessary allocation on launch and no explicit dormant state.                                   |
| Pool or move live WebKit views across scopes             | Can preserve live page state, at the cost of ambiguous authority and storage identity.                                           |
| Build on demand and automatically evict live views       | Reduces resident work, with additional form/media state loss and recovery requirements.                                          |
| Demand-based construction with retained in-session views | Bounds initial work, preserves live navigation where possible, and requires a generation-aware registry and teardown discipline. |

## Consequences and qualification

Native performance must be measured. No process topology or memory reduction is inferred from the proposed model. Require G2 and G4 on duplicate/stale admission, denied default stores, zero hidden starts, last-view retirement, poison handling and resource release. Actual process-exit testing remains subject to safe attribution. Require G3 for focus, resize, divider and compact presentation. Conditional system WebKit and native composition remain under ADRs 0001 and 0005. [Qualification](../architecture/phase-5/reports/WS-F6/qualification-matrix.md) · [Engine ADR](0001-browser-engine-strategy.md)
