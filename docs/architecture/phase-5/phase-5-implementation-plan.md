# Phase 5 implementation plan — M0 reviewed, M1 design prepared

**Date:** 2026-11-07. **Status:** M0 native foundation Passed within its bounded scope; M1 design is prepared for owner review; M1 implementation and M2-M8 remain unstarted. Phase 4.2 was documentation-only preparation. The current M0 report records actual changes/verification separately; remaining work packages below are plans, not authority to implement them.

## Inputs and authority

- [Owner approval](../phase-3/owner-approval-decision.md): closure APPROVED; WKWebView CONDITIONAL ACCEPTANCE for MVP planning and implementation; architecture baseline APPROVED. No unconditional production-engine or release approval.
- [ADR 0001](../../decisions/0001-browser-engine-strategy.md): Proposed retained; completed/reviewed Phase 4.1 Stage A/B/C policy verified unchanged, with no duplicate correction. [ADR 0002](../../decisions/0002-browser-distribution-and-platform.md): accepted internal distribution/security outcomes.
- [Approved architecture baseline](../phase-3/browser-mvp-architecture-baseline.md), [engine contract](../browser-engine-contract.md), [MVP criteria](../browser-mvp-acceptance-criteria.md), [security criteria](../../security/browser-security-acceptance-criteria.md) and [gate snapshot](../phase-3/browser-acceptance-gate-ledger.md).
- [Phase 3 exit evidence](../phase-3/phase-3-exit-review.md): separate 49/49 recovery and 48/48 regression suites, earlier limited/failed/incomplete results and historical performance. Inputs only, not Phase 5 qualification.

Where older proposed documents still say “engine unapproved” or “all gates before implementation,” the dated owner decision governs the new conditional direction and the corrected ADR distinguishes implementation from release. This does not weaken any required outcome. The unchanged gate snapshot records its earlier review state; new milestone records must not overwrite it.

## Validation-stage alignment

The completed ADR's **Stage A** concerns the bounded engine decision and explicit unresolved-risk/launch-critical workflow disposition. The three owner approvals are recorded; unanswered product/access questions are not automatically solved. Record those questions before the affected M0/M1/M2 capability or architecture choice. Where a condition cannot be accepted, define finite authorized validation or hold that scope instead of claiming it passed.

**Stage B** applies during M0-M7 implementation and integration: architecture/engine, bridge/trust boundaries, profile/private isolation, native permissions/files/lifecycles and authorized critical website workflows. **Stage C** is M8 final release: required macOS 26 runtimes, actual signing/notarization, OS protections, release performance/compatibility, internal distribution and updater integrity. The ledger A/B/C/D categories remain unchanged and identify requirements; they are not an alternative stage sequence. No hard security failure can be waived or deferred beyond reliance on the affected behavior.

## Preparation before the first execution task

1. M0 execution is complete within its bounded scope. The current instruction authorizes [M1 design only](reports/M1/README.md), not implementation. Do not request the three recorded engine/closure/baseline decisions again or infer permission to execute the remaining plan or publish.
2. The implementation repository is the existing `vezham-labs/vx-browser` checkout on `timeline`, verified in the [M0 baseline](reports/M0/README.md). Prior Codex documents/prototype are imported with provenance; historical copies remain unchanged and the original source location is preserved. The native host is new M0 source, not a transformed Phase 3 prototype.
3. Assign accountable role owners (native/platform, core/storage, adapter, UI, security, QA, release); this plan invents no individual assignees or deadlines.
4. Record immediate design choices in the appropriate maintained design/ADR: trusted core runtime/binding, storage interface, module dependency rules and native service ownership. The approved baseline's open choices are real prerequisites, not newly rejected architecture.
5. Record launch-critical workflow/capability questions and unresolved authentication/performance risk dispositions before the implementation decisions that depend on them; conditional engine acceptance is not a complete critical-subflow specification. Define a bounded work package, acceptance scope, expected evidence, target source/SDK/runtime and stop conditions before implementation. Credentials/account/media/signing access are separate prerequisites only for the work that needs them; do not block unrelated foundation work on final-release signing.

## Work packages and dependencies

### M0 — Foundation and native host

Prepare the production workspace/module graph in the selected checkout only after execution is authorized. Establish macOS 26.0 deployment configuration, Swift/AppKit application/window lifecycle, composition/service ownership, safe shutdown and an engine-neutral public model/contract boundary. Pin toolchain/dependency manifests as relevant. Do not copy the monolithic prototype/test harness or private diagnostic ABI into production.

Future verification: a recorded development build/launch and lifecycle/shutdown check on the named development host, reviewed module dependencies and declared minimum target. This does not run the macOS 26 release matrix or require final Developer ID/notarization early. If launch fails, capture the cause and stop the affected task; never bypass Gatekeeper/sandbox/Hardened Runtime protections.

### M1 — Core and local state

The [M1 design packet](reports/M1/README.md) and [bounded implementation breakdown](reports/M1/m1-implementation-plan.md) now propose runtime/store/model/contracts. ADR0003/0004 remain Proposed; approve the needed choices and separately authorize an implementation slice before the future work below.

Depends on M0. Implement opaque profile/view/navigation/request/transfer identities, cancellation/generation/sequence semantics and core product policy independent of WK objects. Select the local store and migration model before persistence code; separate engine website data from browser-owned history/bookmarks/settings/permission/download state. Commit-only history, private exclusions and active-owner profile deletion refusal are required. Native authorization remains authoritative regardless of core language/binding.

Future verification: engine-free domain/store tests that meaningfully exercise invalid ownership, transaction/migration failure, private persistence refusal, deletion while owned, disposal and event ordering. No renderer handles, arbitrary paths, credentials or general-purpose script enter the chrome/core protocol. Store technology, encryption/migration and durability policy are documented decisions, not assumptions from Phase 3 cookies.

### M2 — WKWebView adapter

Depends on M0/M1. Build one adapter for the conditionally accepted engine using documented SDK APIs; choose data store before view creation; expose capability-correct navigation, load state, view bounds, zoom/find and relevant native callbacks. Correlate events to current view/profile/navigation/generation and retain committed URL outside the content process. Recovery preserves stopped/error state until an allowed explicit recovery action; disposed/retired/foreign events cannot mutate replacement state.

Future verification: deterministic adapter fixtures with current revision/source/OS/engine provenance, normal and cancelled navigation, redirects/popups under policy, unsupported scheme/capability failure, lifecycle and stable/in-flight recovery. Crash tooling must safely identify only disposable test-owned helpers; no production private process ABI or unrelated process termination. No CEF adapter/runtime/helper or CEF-specific placeholder is implemented. Native engine objects never cross the shared boundary.

### M3 — Trust boundary and privileged transport

Depends on the M0-M2 ownership/contract slice; precedes privileged UI command exposure. Resolve the dedicated app-owned chrome origin/resource scheme and transport design. Implement native validation of registered caller surface, origin/frame metadata, schema/version/size, current profile/view ownership, replay/request state and authorization. Bundle trusted UI resources with restrictive CSP; deny privileged-surface remote navigation. Website views have no app handler; no generic reflection or arbitrary JavaScript/file-path dispatch.

Future verification: legitimate allowlisted commands plus at least 100 defined malformed/oversized/unknown/replayed/stale/wrong-profile/wrong-origin/subframe/page-originated cases rejected without privileged side effects, crash or disclosure. Test the actual production transport; Phase 3's absent-channel attempts cannot satisfy it. Review UI dependency/resource provenance and cancellation-safe event responses. A leak or unauthorized action blocks the milestone/release, with no waiver into Passed.

### M4 — React/TypeScript/HeroUI v3 interface

Depends on M2/M3 and the M1 model. Build browser chrome against sanitized core state and typed intent: address/navigation, tab/window/profile presentation, loading/error/recovery, find/zoom and service prompts. Keep sensitive paths/tokens/native objects out of UI state. Integrate required keyboard/accessibility, origin/profile labels and clear cancel/unsupported flows. Layout exploration can be isolated, but no privileged UI operation bypasses M3.

Future verification: actual UI-to-native actions and current-state events, stale/disposed response rejection, per-view/profile ownership and required native UX/accessibility flows. Full find clear/stop/reset and zoom restoration follow explicit product policy; do not promise exact match counts unsupported by the engine. No `@vezham/aura` dependency/import/placeholder. This plan neither selects undocumented HeroUI APIs nor generates UI code now.

### M5 — Profiles/private sessions, permissions and transfers

Depends on M1-M4 integration. Implement immutable view/profile ownership, distinct persistent website stores plus profile-keyed product state, shared intended private sessions and last-owner teardown. Refuse active-owner deletion. Ensure private visits/history/suggestions/permission/recovery data cannot enter normal persistent stores or optional sync. Define app-owned temporary data and exact cleanup scope; distinguish OS-managed limits.

Implement origin/profile-bound permissions with default-deny unknown/unsupported types, documented one-time/persisted/private/revoke semantics and OS-denial precedence. Map supported kinds to public APIs. Actual media Allow/expiry/revoke testing remains blocked until separately authorized; earlier temporary OS access for a denial fixture is not new website-grant permission. Keychain-backed service boundaries are native and future identity integration is not required here.

Implement file selection/destination tokens, only selected-data exposure, cancellation/no upload, staged downloads, exact completion, overwrite policy, symlink/cross-volume handling, security-scope lifetime, quarantine/metadata and shutdown/host-death cleanup. No automatic opening/execution. Future verification uses synthetic files and scoped fixtures: persistent A/B and shared/unshared views, relaunch/delete, private cleanup/exclusion with positive controls, permission separation, hostile file names, cancel/interrupt/duplicate and defined destination/lifetime cases. Do not label a picker-only test as whole file-service acceptance.

### M6 — Compatibility, reliability, performance and local-first behavior

Depends on integrated M1-M5 slices. Confirm launch-critical workflows/capabilities with the product owner, then apply the public-only restriction until approved environments and access scope exist. Record separate blocked cases for Google Workspace, Microsoft 365, GitHub, Figma, Notion, payment sandboxes, conferencing and named Vezham apps; public landing pages and synthetic cookies are not authenticated/MFA/SSO/passkey/edit/save evidence. No real funds movement or new account/media scope is authorized by this plan.

Exercise local browsing/history/bookmarks/profiles with Vezham services disabled and verify zero requests to those services. Identity/cloud stays optional; no production Tamizhi integration. Verify in-flight navigation/download/profile-switch crashes, unaffected views, late callbacks/disposal, private exclusions and current-state recovery. Failures belong to the new implementation revision, not a reopened Phase 3 loop.

Qualify the applicable pinned revision against the [unchanged target/method table](phase-5-scope-and-milestones.md#approved-performance-targets-to-retain). Record 30 samples where required, median/p95/variance, AC power, state, payload/readiness definitions, helper attribution and RSS/compression limits. Also record true cold launch, idle CPU/energy when available and approved representative/conference workload resources. The latest Phase 3 recovery revision was not performance-qualified; historical proxy numbers never transfer as new passes.

Future exit: all scoped critical local/security/reliability checks have evidence; external account/media blocks are explicit. M6 remains partial if critical workflows remain blocked, while independent M7 work may continue. Final release cannot inherit that partial status as complete compatibility.

### M7 — Internal release engineering and readiness

Can be designed after M0 and implemented against stable M1-M5 dependencies alongside M6. Select `.dmg`/`.pkg`/MDM delivery and updater/metadata protocols; define internal development/QA/production channels, artifact identities/digests, signed metadata, staging, replay/expiry/wrong-channel protection, minimum version, revocation and rollback safe for migrations/security. Define rollout health/halt, key custody/rotation/emergency response, dependency notices and reproducible build/provenance/runbooks.

Future verification: review exact dependencies, isolated verifier rejection/failure paths and non-production operational procedures. This is preparation for actual release qualification, not a claim of Developer ID/notarization, Gatekeeper or clean-install success. No credentials, keys or CI/deployment settings are fetched/changed in Phase 4.2. Any future privileged external configuration needs its own authorized task. No public release channel or endpoint is introduced.

### M8 — Final-release qualification

Depends on implemented M0-M7 and a pinned candidate with resolved launch-critical access/scope prerequisites. At this user-directed final stage, run the actual macOS 26.0 and latest supported 26.x runtime matrix, Developer ID signing and Apple notarization, Gatekeeper/clean install, actual release entitlements/nested code, unsupported-OS rejection and the selected internal delivery path. Test signed update metadata/artifact tamper/replay/wrong-channel/revocation/rollback/minimum-version behavior and operational halt/key response. Do not relax OS protections to manufacture success.

Reconcile exact-candidate compatibility/security/privacy/reliability/performance evidence, third-party notices and supported-version regression/security ownership. Any cross-boundary leak/unauthorized action, unresolved mandatory defect or untested launch-critical workflow blocks release. A product owner may explicitly change feature scope, but cannot silently turn a skipped test or security defect into Passed. A separate release-owner decision is required for any internal distribution. **No public distribution is authorized.**

## Evidence, change control and finite verification

For each later task, record work-package ID, source/build hash, dependency lock, SDK/OS/engine, setup, expected/actual outcome, pass/fail/blocked/deferred/not-tested status, limitations, artifacts, owner and exit disposition. Record authorization/access separately from the technical result. Keep new evidence outside the preserved Phase 3 source/evidence/archives; choose the Phase 5 evidence location in M0. Do not overwrite old runs or combine revisions into one aggregate pass rate.

Use the unchanged A/B/C/D [gate classifications](../phase-3/browser-acceptance-gate-ledger.md) to map implementation outputs and release prerequisites. The dated owner record resolves the three approvals, not technical blockers. Partial/out-of-scope capability declarations must be reflected in product behavior and cannot masquerade as support.

Future checks should be scoped to changed behavior and mandatory integration concerns. After a failure, record the defect/method/environment hypothesis before retrying; unchanged retries without new information are not progress. After required checks pass, broaden only for new code changes, failures or a concrete unresolved concern. No recurring test automation or endless loop is created by this plan. Respect user pauses and preserve existing work.

## Outstanding design decisions and risk ownership

| Decision/risk                                                                                             | Role owner                        | Needed before                                                                                                       |
| --------------------------------------------------------------------------------------------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Implementation repository/checkout, core runtime/bindings and module ownership                            | Architecture/native/core          | M0/M1 relevant packages                                                                                             |
| Local store/schema, migrations/encryption and private ephemeral data boundaries                           | Core/storage/security             | M1 and M5 persistence                                                                                               |
| Chrome origin/resource hosting, transport schema/CSP and lifecycle/replay policy                          | Native/UI/security                | M3 privileged transport                                                                                             |
| Permission kinds/grant/revoke/private semantics; file tokens/overwrite/quarantine/scopes                  | Platform/security/product         | M5 feature implementation/verification                                                                              |
| Critical sites/subflows, supported capability/UX matrix, screen-sharing scope and approved accounts/media | Product/compatibility QA          | Relevant M5/M6 tests; all release-critical items before M8 exit                                                     |
| Broader process recovery/order, product performance and OS-driven WebKit changes                          | Adapter/performance/platform QA   | M6 and exact-candidate M8 qualification                                                                             |
| Installer/updater/metadata, release key custody, health/rollback/revocation, incident ownership           | Release/security                  | M7 design and M8 final release                                                                                      |
| Formal ADR lifecycle disposition                                                                          | Product Owner/documentation owner | Separate explicit status decision; no implicit Accepted transition or repeated approval of the same three decisions |

## Overall exit and current stop

The approved architecture boundaries and conditional WKWebView direction govern future execution; they are not proof of the code that must be built. Phase 5 is complete only when scoped implementation criteria and applicable final-release gates are evidenced and an internal release candidate receives its separate authorization. No unconditional production-engine acceptance, new service integration, public distribution or security waiver follows from this plan.

**Current stop:** M0 foundation is complete; finish only [M1 design and consistency review](reports/M1/README.md). M1 implementation, M2-M8, full adapter/chrome, service integrations, production signing/release infrastructure and distribution remain out of scope. Do not restart Phase 3 or treat its historical results as M0 qualification.
