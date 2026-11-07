# ADR 0005: Browser capability boundaries and lifecycle

- **Status:** Proposed
- **Date:** 2026-11-07
- **Authority:** DSH-inspired architecture review instruction; detailed mechanism remains a recommendation for owner review.
- **Execution:** Design/documentation only; no implementation or plugin/runtime/dependency added.

## Problem and preserved decisions

M1 already separates core, ports, persistence and native adapters. It needs explicit rules for optional feature availability, owned subscriptions/effects, failed initialization and disposal so feature growth does not expand the core or weaken native authority. DSH offers useful composition/lifecycle examples, but Browser policy and durable state cannot become replaceable arbitrary plugins.

Preserve the approved native-first, engine-independent boundaries; conditional WKWebView direction; future React/TypeScript/HeroUI v3 chrome; local-first operation; and all private/security/release requirements. ADR0001 remains Proposed; ADR0002 Accepted. Proposed Swift runtime ADR0003 and SQLite ADR0004 are unchanged and do not become Accepted through this review.

## Alternatives

| Approach                                                                       | Benefit                                                                                           | Cost / reason for disposition                                                                                                                       |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Existing typed ports with ad-hoc per-feature lifetime handling                 | Least additional convention                                                                       | Repeated cleanup, readiness and subscription rules can diverge; too implicit as features grow                                                       |
| Explicit compiled bindings, per-feature typed ports and shared lifecycle rules | Extends current architecture without a runtime loader; ownership/readiness/failure are reviewable | Requires disciplined dependency, cleanup and event-contract review; same-process fault limitations remain                                           |
| General plugin container, DSH/Cordis runtime or everything-pluggable core      | Broad dynamic extensibility                                                                       | Adds framework/runtime/loader and policy-interception surface; conflicts with stable native authority, core-owned state and current scope; rejected |
| Process-isolated extension host                                                | Potential stronger fault/privilege separation                                                     | IPC, packaging, broker and lifecycle costs need a concrete future untrusted-code requirement; deferred, not implemented                             |

## Proposed decision

Use explicit native composition of required engine/persistence ports and selected app-bundled optional feature implementations. Keep ordinary BrowserDomain/BrowserPorts/Core/Persistence modules; do not build a new plugin framework, registry of tools, arbitrary name-based invocation or dynamic installer. Browser Core API is a logical contract surface, not another runtime.

Core owns lifecycle/ownership/navigation and authorization policy, durable-state policy and selected feature state. Native host retains OS authority. Permission enforcement is mandatory even if the grant/prompt feature is unavailable. Optional providers may use only narrow authorized ports; registration/readiness gives no operation permission. Missing product-required features remain failed/blocked acceptance, not silently optional release criteria.

Require unique instance identity, compatible contract, immutable owner scope and dependency validation before initialization. Track provisional resources and roll them back on failure. Fence requests/revoke grants before async stop, detach subscriptions and reconcile committed work, then release dependent resources in explicit safe order. Cleanup is idempotent; deadline/failure cannot falsely report disposed/deleted. Replacement is controlled build/composition change initially, not runtime hot swap.

Use typed scoped commands/results and bounded read-only event subscriptions, never event middleware that rewrites authorization or a global all-profile feed. Existing schema/repository/receipt/private rules remain unchanged; no provider owns a DB or durable browser state. Engine support, provider readiness, feature requirement and per-operation authorization are distinct facts.

## Source, trade-offs and security limits

Study is pinned to DSH `fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159`. Its [architecture](https://github.com/deepseek-ai/deepseek-harness/blob/fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159/docs/architecture.md) illustrates a broader plugin-based harness; its [lifecycle guide](https://github.com/deepseek-ai/deepseek-harness/blob/fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159/docs/cordis-tutorial/02-lifecycle-and-effects.md) motivates explicit cleanup. These are pattern references, not Vezham dependencies or security evidence. No DSH source/runtime is vendored or executed.

Recoverable feature failure should leave unrelated core operations usable through typed unavailable results and bounded resource delivery. Same-process trusted modules cannot guarantee survival of fatal traps, blocked main threads or memory/resource faults; no security sandbox is claimed. Untrusted runtime extensions are excluded. Core/native authorization, private persistence refusal and mandatory gates cannot be intercepted or waived by provider registration.

Future Tamizhi remains separately scoped, opt-in and destination-disclosed, with short-lived source/profile/view/purpose grants and no unrestricted native/model tool channel. Optional identity/cloud cannot become browsing prerequisites. No public distribution, CEF implementation or Aura is authorized.

## Compatibility, reversibility and owner decisions

This adds a lifecycle/availability convention to the existing M1 ports; no source target, store schema/data or released ABI needs migration. New proposed contract draft0.2 documents status/identity/subscription semantics without releasing wire v1. More concrete feature interfaces require their own bounded review; no generic compatibility shim is selected.

Owner review is needed for this detailed static-composition/lifecycle mechanism and the supported/launch-required feature matrix. Existing runtime/storage/encryption/retention/restore decisions remain pending where already recorded. Future extension trust/isolation, budgets and any Tamizhi feature require separate scope. Do not re-request the established engine/closure/baseline decisions or silently accept this ADR. Implementation requires a separate instruction and behavioral evidence.

[DSH assessment](../architecture/phase-5/reports/M1/dsh-architecture-assessment.md) · [Capability architecture](../architecture/phase-5/reports/M1/browser-capability-architecture.md) · [M1 contracts](../architecture/phase-5/reports/M1/core-boundary-contracts.md)
