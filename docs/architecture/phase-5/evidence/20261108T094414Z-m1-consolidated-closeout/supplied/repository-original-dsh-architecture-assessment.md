# DSH-Inspired M1 Architecture Review

**Date:** 2026-11-07. **Status:** Proposed M1 architecture refinement; design only, no implementation or new feature authorization.

## Assessment and source boundary

Recommend a bounded refinement of M1's existing ports: explicit feature-provider availability, typed scoped events and owned initialization/disposal. Preserve the small native core's authorization, lifecycle and durable-state responsibilities. A generic plugin framework is unnecessary for the first native browser.

Reviewed DSH at commit **`fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159`**, dated2026-11-04; nine primary files were read and their blob identities verified. DSH's [architecture](https://github.com/deepseek-ai/deepseek-harness/blob/fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159/docs/architecture.md) describes a Cordis plugin composition, including persistence and policy. Its [primer](https://github.com/deepseek-ai/deepseek-harness/blob/fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159/docs/cordis-primer.md), [service reference](https://github.com/deepseek-ai/deepseek-harness/blob/fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159/docs/cordis-api/service.md) and [typed-event reference](https://github.com/deepseek-ai/deepseek-harness/blob/fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159/docs/cordis-api/events.md) provide concrete extension seams. This is useful inspiration, not proof of a small stable browser kernel or a reason to copy its Node/Cordis execution model. DSH itself documents experimental/security limitations in its [safety notice](https://github.com/deepseek-ai/deepseek-harness/blob/fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159/SAFETY.md).

## Principles applied and deliberately rejected

| Principle / source observation                                   | Browser disposition                                                                                                                                                     |
| ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Narrow contracts and replaceable implementations                 | Retain Domain/Ports and host-injected concrete adapters. Browser Core API is the logical typed surface, not a new runtime/package facade                                |
| Typed events with explicit dispatch semantics                    | Add scoped result/availability events, ownership, ordering, backpressure and cancellation. Notifications cannot rewrite policy or dispatch arbitrary privileged methods |
| Registration/resource ownership                                  | Specify unique native bindings and owned subscriptions/tasks/resources; registration is never permission                                                                |
| Explicit initialization/disposal                                 | Validate dependencies, publish readiness after success, roll back failed setup and fence late work before cleanup; retain required services until dependents reconcile  |
| Everything as plugins, including policy/persistence              | Reject. Core/native authorization, profile/private invariants and durable data ownership remain mandatory ordinary modules                                              |
| Global context/interception, config overlays and dynamic loading | Reject as Browser architecture. No ambient service locator, waterfall policy override, runtime code installation/HMR, Cordis or Node import                             |
| Agent turn/tool/session-log model                                | Reject. No agent loop, tool registry, replay-all-events persistence or automatic model/native actions                                                                   |

The [DSH lifecycle tutorial](https://github.com/deepseek-ai/deepseek-harness/blob/fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159/docs/cordis-tutorial/02-lifecycle-and-effects.md) notes concurrent async disposers, so safe Browser teardown must specify dependency order explicitly. [Scoped registry code](https://github.com/deepseek-ai/deepseek-harness/blob/fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159/packages/core/scope/src/store.ts) associates registration with context and supports composition shadowing; that is not Browser profile isolation or authority. Vezham rejects duplicate providers and implicit parent-scope grant inheritance. These Browser dispositions are engineering judgments under its own security requirements.

## Resulting design and compatibility

[Capability architecture](browser-capability-architecture.md) distinguishes core responsibilities, built-in optional providers, future trusted extensions and future AI-assisted features. Permission enforcement remains mandatory; optional permission-grant UX cannot default to allow when absent. Optional implementation structure never waives a required MVP feature gate.

| Existing M1 area                                             | Refinement / migration consequence                                                                                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Domain/Ports/Core/Persistence and native composition         | Preserve targets/proposed language, add explicit per-feature lifetime/availability rules; no new plugin target/framework                               |
| Engine and storage backend seams                             | Preserve replaceable required ports; optional modules use portable typed ports, not WK downcasts or SQL handles                                        |
| Schema, core-owned history/receipts and private memory state | Unchanged. No event log/schema/data migration or provider-owned stores                                                                                 |
| Authority context, epochs and contracts                      | Add provider instance/generation and owned subscription semantics; proposed contract draft0.1 advances to0.2; wire v1 remains unimplemented/unapproved |
| M1 sequencing                                                | Add finite fake-provider lifecycle cases within existing later I1/I2/I6/I7 scope; no execution or new milestone starts                                 |

Recoverable optional failures return bounded unavailable states without blocking unrelated core work. A required dependency failure still blocks its operation. Same-process modules cannot guarantee crash/memory/main-thread fault containment; actual untrusted extensions would need a separate isolation design. Tamizhi stays future and separately consented, with no unrestricted native or data channel.

## Files reviewed and changed

Reviewed all eight original M1 documents, ADRs0001-0004 and approved architecture/security boundaries, together with the nine pinned DSH files in [source provenance](../../evidence/20261107T171758Z-dsh-architecture-review/dsh-sources.json). Existing M1 document hashes match the preceding review manifest at the baseline. No DSH/Cordis code was executed or vendored.

Created this assessment, [capability architecture](browser-capability-architecture.md) and [ADR0005 — Proposed](../../../../decisions/0005-browser-capability-boundaries-and-lifecycle.md). Updated only the relevant existing M1 proposals: [module architecture](browser-core-architecture.md), [contracts](core-boundary-contracts.md), [implementation plan](m1-implementation-plan.md) and [decisions/risks](m1-decisions-and-risks.md). Original M1 completion report, M0 implementation, all earlier ADRs, historical reports and evidence remain unchanged. No global handbook/Phase5 plan rewrite or source/dependency change.

## Repository, validation and remaining decisions

Started clean on `timeline` at **`0057d5a0362b02712dd24343a605725f710568f4`** (`docs(browser-macos): prepare M1 core design`), with expected origin/upstream unchanged. Captured629 tracked-file hashes. No branch switch, stash/reset, commit or push; final task changes are unstaged documentation/review records only.

[Documentation checks](../../evidence/20261107T171758Z-dsh-architecture-review/documentation-review.json), [preservation/change review](../../evidence/20261107T171758Z-dsh-architecture-review/preservation-and-change-review.json) and [review hashes](../../evidence/20261107T171758Z-dsh-architecture-review/review-file-manifest.json) record actual outcomes. Verification is scoped Nx Markdown formatting, local link/heading and consistency review, Git whitespace and protected-file hashes; no build, product test, app launch or historical regression. Behavioral lifecycle/security/failure-isolation remains Not Tested.

Owner review is needed for the detailed ADR0005 mechanism and which built-in features are launch-required; existing ADR0003/0004 and protection/retention/restore decisions remain Proposed/pending. Future trusted-extension isolation, concrete transport/budgets and any Tamizhi access require separate review. The requested native-first/engine-independent direction is preserved, not presented as a new engine approval question.

**Review prepared; implementation not started.** No accepted ADR changes, new dependencies, AI harness/plugin system, dynamic code installation, production Tamizhi, Aura, CEF implementation or public distribution. All mandatory security and final-release gates remain unpassed where previously unverified. Stop after documentation and owner review preparation.
