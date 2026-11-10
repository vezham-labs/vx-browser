# Phase 5 — MVP foundation and implementation preparation

**Prepared and reviewed:** 2026-11-07, Phase 4.2. **Execution status:** M0 foundation Passed within its bounded scope; M1 design prepared for owner review; M1 implementation and M2-M8 Not Started. This folder holds the plan and linked M0 execution records; the plan itself is not build/test evidence or deployment authorization.

## Authority and starting state

The [Product Owner decision](../phase-3/owner-approval-decision.md) records exactly: **Phase 3 closure — APPROVED; WKWebView engine — CONDITIONAL ACCEPTANCE for MVP planning and implementation; architecture baseline — APPROVED.** Conditional acceptance is not unconditional production-engine or release approval. [ADR 0001](../../decisions/0001-browser-engine-strategy.md) remains **Proposed**, with its completed, reviewed Phase 4.1 correction and Stage A/B/C gates verified unchanged; no Accepted transition is inferred. Its lifecycle label does not require the three decisions to be requested again.

The completed scoped workspace/handbook/M0 instruction supplied execution authorization for M0 only. The current instruction authorizes M1 architecture/design documentation, with owner review and a separate instruction required before implementation. The earlier Phase 4.2 preparation did not authorize execution by itself. See the [M0 report](reports/M0/README.md), [report index](reports/README.md) and [run-specific evidence](evidence/README.md) for actual work and exit status. Preparing or importing documentation is not a milestone pass.

## Read in order

1. [Scope and milestones](phase-5-scope-and-milestones.md) — allowed work, M0-M8 sequence, dependencies, acceptance criteria, risks and implementation/final-release separation.
2. [Implementation plan](phase-5-implementation-plan.md) — concrete work packages, prerequisite design choices, gate/evidence discipline, bounded future verification and exit conditions.
3. [Approved architecture baseline](../phase-3/browser-mvp-architecture-baseline.md) — approved boundaries and deliberately unresolved implementation details.
4. [M1 design packet](reports/M1/README.md), [runtime ADR 0003 — Proposed](../../decisions/0003-browser-core-runtime-and-language.md) and [persistence ADR 0004 — Proposed](../../decisions/0004-browser-local-persistence.md) — recommendations for owner review, not implementation approval.
5. [Primary Phase 3 exit review](../phase-3/phase-3-exit-review.md) and [unchanged gate snapshot](../phase-3/browser-acceptance-gate-ledger.md) — existing evidence and continuing requirements. The historical B12 approval-blocked row is superseded only for the three owner decisions by the dated approval record; technical classifications/results are unchanged.

## Non-negotiable constraints

- macOS **26.0+** minimum; Swift/AppKit native host; React + TypeScript + HeroUI v3 chrome; engine-independent core and opaque adapter boundaries.
- **No `@vezham/aura`**, including dependencies, imports, placeholders or API assumptions.
- **No Chromium/CEF implementation.** CEF stays evaluation-only; no runtime/helper/package or CEF-specific placeholder adapter is added by this plan.
- **No public distribution.** Internal release remains a separate, gated release decision under accepted [ADR 0002](../../decisions/0002-browser-distribution-and-platform.md).
- **No production Tamizhi integration.** Vezham identity/cloud remains optional, outside the required local-browsing path; it is not an implementation prerequisite or an implicitly authorized feature.
- No mandatory security/release gate is removed. No unknown, blocked, deferred or untested criterion is Passed through planning or owner approval.
- Do not edit/restart the Phase 3 prototype, rewrite historical evidence or reuse older performance as new-revision qualification. The separate 49/49 recovery and 48/48 regression outcomes remain historical inputs, not Phase 5 acceptance.

## Stage separation and stop point

Outstanding ADR **Stage A** critical-workflow and risk-disposition questions remain explicit before the affected implementation choices. M0-M7 cover future implementation/integration and preparation of an internal release candidate under **Stage B**. M8 is **Stage C final-release validation**, including the user-deferred macOS 26.0/latest supported 26.x runtime matrix and Developer ID signing/notarization. Plan release infrastructure earlier; do not use the final-stage timing to waive or pre-pass it. Account/media workflows remain access-blocked until separately approved, and release cannot treat those blockers as compatibility proof.

M0 native foundation is complete within its bounded scope. Current scope is [M1 Browser Core and Local State design](reports/M1/README.md): runtime/storage alternatives, module/model/contracts, migration/privacy and an implementation breakdown; recommendations remain Proposed. The [canonical Browser handbook](../../../vx/handbooks/browser/README.md) is the developer entry point. No M1 implementation, M2-M8 work, credentials, release infrastructure or optional-service feature is included. Stop after the M1 design review; implementation needs owner review and a separate scoped instruction.

## Current M1 consolidation — 2026-11-08

The maintained [M1 baseline](reports/M1/README.md) supersedes historical pending-policy and blanket Spaces-deferral statements for current owner scope. OP-01–04 are decided; current OD17 selects26 capabilities including basic Spaces, while advanced automation remains deferred and historical OD18 is preserved. Documentation/isolated validation/planning are authorized; product implementation/release remain unauthorized. Actual outcomes and blockers are in the M1 closeout; no milestone/product qualification follows from this documentation update.

## 2026-11-10 coordinated WS-F7/native/tooling/WS-F8 execution

[Actual partial implementation](reports/developer-tooling/implementation-report.md) delivers Go qualification tooling, a shell build fix and safe release preparation. [WS-F7](reports/WS-F7/README.md) remains blocked on protected production writer/positive signed key custody; [native-primary UI](reports/native-ui-alignment/README.md) is not implemented; [WS-F8](reports/WS-F8/README.md) has unsigned structural evidence only. Existing historical approvals and release gates remain in force. No whole-milestone completion or distribution acceptance is claimed.

## Native browser completion programme

The current branch builds SwiftUI/AppKit browser chrome and qualifies a disposable encrypted transaction worker. Production storage and signed release remain incomplete. [Programme record](reports/completion-programme/README.md).
