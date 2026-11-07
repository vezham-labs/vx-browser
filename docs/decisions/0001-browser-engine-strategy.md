# ADR 0001: Browser engine strategy for Vezham Browser

- **Status:** Proposed; conditional owner decision recorded on 2026-11-07; no Accepted transition
- **Date:** 2026-11-07
- **Decision owner:** Vezham Browser product owner
- **Scope:** Internal macOS 26.0+ MVP engine; conditional planning/implementation direction and mandatory staged gates
- **Authorization:** Documentation and consistency review only; conditional MVP implementation direction recorded, execution requires a separate scoped task

## Context

Vezham Browser is an independent macOS 26 Tahoe+ browser with an engine-independent architecture, React/TypeScript + HeroUI v3 UI, Swift/AppKit native host, an engine-independent core, future optional Tamizhi, and optional Vezham ID/cloud capabilities. `@vezham/aura` is not ready and is excluded from dependencies, imports, placeholders, and assumptions. Distribution is internal-only. Accepted [ADR 0002](0002-browser-distribution-and-platform.md) requires Developer ID Application signing and notarized internal direct-distribution artifacts; installer/updater details and exact sandbox configuration remain open. The product prioritizes balanced performance, security, and web compatibility.

Static inspection of Arc 1.172.1 found a native macOS host linked to a proprietary Chromium-derived `ArcCore` framework with Blink/V8 and browser, renderer, and GPU helpers. This is only an architectural reference. Vezham will not use Arc source, binaries, assets, or branding. See [the Arc report](../../arc-macos-architecture-report.md).

The evaluated candidates were Apple WebKit via `WKWebView` and Chromium through a maintained embedder such as CEF. The Product Owner has now conditionally accepted WKWebView for MVP planning and implementation; CEF remains evaluation-only. This is not unconditional production-engine or release approval.

## Decision drivers

1. Keep the first release aligned with a native Swift/AppKit host.
2. Establish a security boundary between browser UI and remote page content.
3. Support multiple user profiles, private browsing, downloads/uploads, permissions, recovery, and durable browser history.
4. Avoid taking on more update/signing/sandbox work than needed to test the product.
5. Preserve an engine adapter boundary and report nonportable engine capabilities honestly.
6. Validate compatibility against named target sites before making broad claims.

## Options considered

### A. Apple WebKit through WKWebView

**Pros:** Native AppKit view; Apple documents persistent data stores by identifier and in-memory stores; public APIs cover navigation policy/events, find, zoom, cookies/website data, downloads/uploads, selected permission decisions, and content-process termination. macOS supplies the engine, so Vezham does not package a Chromium runtime or helper suite.

**Cons:** Engine release cadence follows macOS; API surface and security controls are less configurable than a browser-owned Chromium runtime. Safari/WebKit compatibility can differ from Chromium. Full Chrome-extension hosting and a general browser-level request-interception API are not documented for arbitrary WKWebView tabs.

### B. Chromium through CEF

**Pros:** Chromium/Blink compatibility; CEF provides a C/C++ embedder API and binary distributions; separate request contexts, browser/renderer/GPU helpers, download/permission/context-menu/find/zoom APIs, and sandbox support are documented.

**Cons:** CEF/Chromium packaging, helper apps, native bridging, sandbox configuration, nested signing, entitlements, notarization, licensing notices, security updates, and upgrade validation become Vezham responsibilities. CEF release availability can lag Chromium. Chrome and Alloy runtime feature sets differ; extension compatibility must be tested against a concrete API list.

### C. Direct custom Chromium integration

**Pros:** Maximum engine-level control.

**Cons:** Vezham would own substantially more of the engine integration, update, patch, process, and packaging surface. This is not justified for a macOS MVP when a maintained embedder is available for evaluation.


## Owner decision and evidence basis — conditional acceptance

On **2026-11-07**, the **Product Owner** explicitly approved: **Phase 3 closure — APPROVED; WKWebView engine — CONDITIONAL ACCEPTANCE for MVP planning and implementation; architecture baseline — APPROVED.** See the canonical [owner approval decision](../architecture/phase-3/owner-approval-decision.md) for scope and conditions.

WKWebView is the conditionally accepted MVP direction behind an engine-independent adapter. This is not unconditional production-engine approval, acceptance of unverified criteria or release authorization. The current task records decisions and prepares Phase 5 only; no production implementation, prototype restart, build or test is performed. A separate scoped Phase 5 execution instruction is still needed. **No public distribution is authorized.**

The ADR lifecycle status remains **Proposed** by instruction. Do not use that label to erase or request again the three owner decisions; do not silently change it to Accepted. The decision record and staged gates below now consistently represent conditional planning/implementation permission and continuing mandatory conditions.

Primary evidence is the latest recovery revision: [49/49 actual-window recovery checks](../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/recovery-ui-results.json) and the separate [48/48 regression checks](../../prototype/wkwebview/Evidence/recovery-regression-20261107T135604Z-15653/regression-summary.json). Their [recovery hashes](../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/source-hashes.json) and [regression hashes](../../prototype/wkwebview/Evidence/recovery-regression-20261107T135604Z-15653/source-hashes.json) match. `main.swift` SHA-256 is `775561a9b25d7277f60417a41daec12096af0b3f2e8e2a602fb1b4136dfba896`. Do not aggregate these suites with other revisions or infer complete browser readiness.

Current evidence shows three prototype content-process recoveries across A/B/Private with actual native Reload, last committed URL restoration, unchanged unaffected synthetic profile state and injected stale/foreign navigation callback rejection. Existing storage/lifecycle/find/zoom/URL suites passed on the same source. These are bounded macOS 27.2 observations with a 26.0 deployment target, not minimum-OS runtime qualification, all crash scenarios or a production UI/core.

Earlier evidence remains historical: public landing visits 21/21; combined native Deny 4/4; a fixed interrupted-download defect with 9/9 selected executed regression checks. Raw failed/incomplete runs remain unchanged. The prior 30-sample recovery timing and ten-view RSS observations, and separate earlier AC timing proxies, do **not** performance-qualify the latest recovery revision. See the [primary exit review](../architecture/phase-3/phase-3-exit-review.md) for provenance, failures and every limitation.

## Four decision paths reviewed

| Path | Evaluation |
|---|---|
| 1. Accept WKWebView as MVP engine | **Owner selected CONDITIONAL ACCEPTANCE for MVP planning and implementation.** Conditions and unverified requirements remain; not unconditional production-engine or release approval. |
| 2. Continue targeted WKWebView validation | Choose if critical missing workflow evidence is required before selection. Define a finite requirement/access/revision/exit condition first. This ADR starts no test or loop. |
| 3. Investigate Chromium/CEF further | Evaluation-only fallback for a demonstrated must-have WebKit limitation or funded requirement. No Vezham CEF runtime, benchmark or workflow validation exists. |
| 4. Reconsider engine strategy | Appropriate if neither candidate satisfies approved essentials, or the product owner changes platform/feature scope. Current evidence does not establish that conclusion. |

The [decision assessment](../architecture/phase-3/browser-engine-decision-assessment.md) contains rationale, trade-offs, assumptions, risk owners and approval conditions for all four paths. No claim is made that CEF is faster, fully Chrome-compatible or already suitable for this deployment.

## Rationale and remaining risk

The prototype demonstrates native host/view, data-store, find/zoom, selected file/permission and recovery primitives. That supports a focused macOS engine plan. It does not establish the whole browser. Authentication/MFA/SSO/passkeys and critical editing/payment/conference flows remain blocked by public-pages-only restrictions; cookies and landing pages are insufficient substitutes. Private cleanup, file metadata/lifetimes, wider crash/event ordering and latest-revision performance remain incomplete.

WebKit publishes data-store and navigation callback surfaces; those API facts are distinct from measured Vezham behavior. [Website-store public header](https://raw.githubusercontent.com/WebKit/WebKit/main/Source/WebKit/UIProcess/API/Cocoa/WKWebsiteDataStore.h), [navigation-delegate public header](https://raw.githubusercontent.com/WebKit/WebKit/main/Source/WebKit/UIProcess/API/Cocoa/WKNavigationDelegate.h). Profile store identifiers are not a promise of separate OS users/renderers or protection from host compromise.

CEF remains a plausible Chromium-based alternative, but its documented macOS framework/helper layout and application-owned update responsibilities imply additional integration/release work. This is an engineering inference, not a Vezham benchmark or validated adoption plan. [CEF application layout](https://chromiumembedded.github.io/cef/general_usage.html#macos), [CEF security-update guidance](https://github.com/chromiumembedded/cef/blob/master/README.md#security-updates).

A system engine does not replace Vezham's responsibility for chrome origin/CSP/bridge, policy, credentials, browser-owned data, permissions, file access and release integrity. Private process-attribution diagnostics used by test tools are not approved product APIs. No universal extensions, network interception or engine-to-engine profile migration is promised.

## Staged validation policy and approved bounded closure

The validation stages below replace the earlier all-product-gates-before-engine sequencing. **Only sequencing changes: no mandatory criterion is waived, deleted, weakened or marked Passed.** The [MVP acceptance criteria](../architecture/browser-mvp-acceptance-criteria.md) and [security acceptance criteria](../security/browser-security-acceptance-criteria.md) retain their required outcomes. A conditional engine decision permits scoped implementation while the relevant implementation and final-release gates remain open.

### Stage A — Before engine selection

1. Review bounded native integration evidence, using the separate 49/49 actual-window recovery and 48/48 regression suites for the latest recovery revision. Do not combine revisions or infer complete browser readiness from these results.
2. Review documented limitations, failed/incomplete runs and unresolved risks, including authentication/MFA, private-data/transfer lifetimes, broader recovery behavior and historical performance that does not qualify the latest revision.
3. Identify and document launch-critical workflows and required engine capabilities. The representative site list is not an approved complete critical-subflow matrix; the outstanding scope decision remains visible in the ledger.
4. Obtain owner acceptance of unresolved authentication and performance risks for the conditional path, **or require finite targeted validation before proceeding** if those risks cannot be accepted. Any targeted work needs a named uncertainty, authorized environment, pinned revision, expected outcome and stop criterion; no automatic testing loop follows.

The Product Owner's recorded choice is **CONDITIONAL ACCEPTANCE for MVP planning and implementation**, with Phase 3 closure and the architecture baseline approved. Preserve that decision; do not request the same three approvals again or reinterpret them as unconditional acceptance. It does not settle the outstanding critical-workflow scope, authorize restricted account/media tests or make incomplete Stage A information Passed. If a decision-critical condition cannot be met, hold the affected implementation scope and return for a specific disposition rather than silently accepting the risk.

### Stage B — During implementation

1. Validate the production architecture and WKWebView engine integration against the approved ownership boundaries, engine-independent core/adapter contract and actual supported public SDK capabilities. Prototype design statements are not production acceptance.
2. Validate the native bridge and trust boundaries: app-owned chrome origin/CSP/navigation confinement; typed versioned allowlist; schema, size, origin/frame, ownership, replay and lifecycle checks; legitimate operations and adversarial cases. Remote website content has no privileged native channel.
3. Validate persistent-profile and private-session isolation, concurrent views, persistence/deletion, private teardown and app-owned cleanup. Durable history/bookmarks/settings/permission/recovery state remain profile-scoped; private data must not enter normal persistent stores or optional sync. Do not infer a per-profile OS renderer/sandbox guarantee.
4. Validate permissions, file transfers and lifecycle security: supported-kind/default-deny policy, OS-denial precedence, scoped grant/expiry/revocation; native selection and opaque destination tokens; staged completion, interruption/cancellation, overwrite, symlink, metadata/quarantine and scope lifetime; stale/disposed/foreign callbacks and in-flight crash/recovery behavior. Verify find/zoom and the applicable native UX semantics on the implementation revision.
5. Validate critical website workflows using **authorized test environments**, including authentication/MFA/SSO/passkey and editing/payment/conference subflows where approved and applicable. Public-pages-only restrictions and separate account/media authorizations remain in force. Keep unavailable workflows Blocked rather than replacing them with landing-page or synthetic-cookie passes.
6. Validate local browsing and browser-owned history/bookmarks/profile operation with optional Vezham services unavailable and zero requests to those endpoints. No production Tamizhi or Chromium/CEF implementation is introduced; identity/cloud remains optional. Record implementation-revision reliability/performance evidence without transferring historical proxy results.
7. Treat **cross-profile/private-data leakage and unauthorized native access as hard failures**. Stop the affected milestone and release until remediated and evidenced. Conditional acceptance or owner risk acceptance cannot waive such a defect into Passed. Complete security checks before relying on the affected implementation; they are not all postponed to release.

Stage B execution requires a separate scoped implementation instruction. This correction starts no implementation, prototype restart, build or test and does not reopen Phase 3.

### Stage C — Before final release

1. Validate the candidate on **macOS 26.0 and the latest supported macOS 26.x release**. Record exact build/SDK/OS/engine provenance; compiling for 26.0 on a newer host does not satisfy this matrix.
2. Validate **Developer ID Application signing and Apple notarization**, including the actual app and nested code. These and the macOS 26 runtime checks remain at the user-directed final-release stage, never optional or pre-passed.
3. Validate **Gatekeeper, App Sandbox, Hardened Runtime and minimal documented entitlements**, clean install/open behavior and unsupported-OS rejection on the actual packaged candidate. Do not weaken protections or inherit temporary media-test entitlements.
4. Validate **release performance and compatibility** on the applicable candidate against the approved measurement methods/targets and supported critical-workflow matrix. Include true cold launch, relevant resource/energy/workload observations and known limitations; do not use older hidden-window timing, constructor-only or RSS proxies as complete release qualification.
5. Validate **internal distribution and updater security** under accepted ADR 0002: selected installer/internal delivery or MDM path, immutable artifacts/provenance, dependency/license inventory, signed metadata and artifact integrity, replay/expiry/channel checks, rollout/halt, safe rollback/minimum version, revocation, key custody/rotation and incident ownership.
6. Reconcile all applicable Stage B security/privacy/reliability and critical-workflow requirements before internal release. A blocked launch-critical workflow or unresolved hard security failure is not a release pass. A separate internal release decision is required; **no public distribution is authorized**.

### Relationship to the preserved gate ledger

Stage **A/B/C** above names **when validation occurs**. The unchanged ledger's categories **A/B/C/D** name **what kind of requirement it is**; they are not competing sequences.

| Validation stage | Relevant ledger categories and treatment |
|---|---|
| Stage A — before engine selection | Category A bounded feasibility evidence and limitations; category B critical-workflow/risk/owner decisions. The dated owner record supplies the three approvals; historic B12 remains a snapshot rather than a renewed approval request. |
| Stage B — during implementation | Category D product requirements and remaining category A behavior/security gaps; category B workflow/device tests only when their scope/access is authorized. No category or status is changed by this mapping. |
| Stage C — before final release | Category C final-release requirements and final-candidate qualification of all applicable implementation/security/compatibility conditions. Remaining blocked requirements stay blocked, never silently Passed. |

The [consolidated ledger](../architecture/phase-3/browser-acceptance-gate-ledger.md) retains the former 13-gate and source-requirement crosswalks, original classifications/statuses, evidence limitations and historical failure register. The [owner decision](../architecture/phase-3/owner-approval-decision.md) supplies later approval authority without rewriting test results. Older pre-approval wording in the assessment and ledger is explicitly historical; no mandatory gate is removed by the stage mapping.

Phase 3 closure is **APPROVED as a bounded investigation with limitations**, not a fully accepted browser/release. Repetitive Phase 3 testing stays paused. Phase 5 verification concerns separately authorized implementation milestones and their pinned revisions; it does not reopen old prototype loops or reuse their results as new passes. WKWebView remains conditionally accepted, Chromium/CEF evaluation-only, and the excluded Aura dependency remains absent from implementation scope.

## Recorded approvals, remaining conditions and execution boundary

- **Decision date / authority:** 2026-11-07 / Product Owner; source is the explicit Phase 4.2 instruction.
- **Phase 3 closure:** APPROVED, bounded by preserved evidence and limitations.
- **WKWebView engine:** CONDITIONAL ACCEPTANCE for MVP planning and implementation; not unconditional production-engine acceptance.
- **Architecture baseline:** APPROVED, with its explicit unresolved implementation choices retained.

The three decisions are recorded in [owner-approval-decision.md](../architecture/phase-3/owner-approval-decision.md). They are not pending merely because ADR 0001 remains Proposed. The earlier “planning only / owner approval pending” inconsistency has been corrected in place; no completed alternative correction was found in the inspected checkout, and no duplicate ADR is created.

Mandatory remaining conditions: preserve zero-leak/unauthorized-action hard failure rules; implement/validate production trust boundaries and native data/file/permission lifetimes; resolve launch-critical compatibility scope and approved environments; qualify relevant new revisions for performance/reliability; complete macOS 26.0/latest supported 26.x and Developer ID/notarization at final release validation; satisfy accepted ADR 0002 for internal release integrity and operations. Public-pages-only and media/account restrictions persist. None is waived by the conditional decision.

**Lifecycle record:** Proposed retained; corrected owner decision and staged-gate consistency represented. No Accepted transition is performed. Any later formal lifecycle disposition requires an explicit status decision, not reapproval of the already recorded three decisions. This task starts no implementation, build, test, deployment or release. [Phase 5 preparation](../architecture/phase-5/README.md) is documentation only.

## Consequences of the conditional owner decision

Use the conditionally accepted WKWebView page-engine direction for MVP planning and separately authorized implementation. Keep native engine/platform objects private; core product state and policy remain engine-independent; React uses a separate typed allowlisted protocol. Future Tamizhi and optional Vezham identity/cloud remain outside rendering/startup dependencies and require separate consent/data-flow review. `@vezham/aura` is excluded as a dependency, placeholder and assumption. No CEF helper/runtime, direct custom Chromium or production browser code is introduced by this decision packet.

OS-driven WebKit changes require a supported-runtime regression/incident owner. Unverified account compatibility, permission grants, private-data cleanup, transfer metadata/lifetimes, crash scenarios, product bridge/state and latest performance remain tracked obligations. The freeze is of reviewed boundaries, not invented APIs or complete release readiness.

## Revisit triggers

Revisit the recommendation for a reproducible high-priority workflow failure attributable to WebKit after reasonable app remediation; a committed capability such as a specific extension/interception API that public WKWebView cannot provide; an approved second-platform requirement; a failed isolation/security requirement; or qualified measurements that change the trade-off. First distinguish product bugs, test assumptions, access restrictions and engine limitations.

Any CEF adoption requires a separately approved scope with a pinned build, actual workflow/capability/extension matrix, helper/sandbox design, payload/dependency inventory, release/update/signing plan and security-response ownership. No automatic fallback or CEF production implementation is authorized.

## Related records

- [Owner approval decision](../architecture/phase-3/owner-approval-decision.md) and [Phase 5 preparation](../architecture/phase-5/README.md)

- [Phase 4 review index](../architecture/phase-3/README.md) and [primary exit review](../architecture/phase-3/phase-3-exit-review.md)
- [Engine decision assessment](../architecture/phase-3/browser-engine-decision-assessment.md)
- [Approved architecture baseline and open implementation choices](../architecture/phase-3/browser-mvp-architecture-baseline.md)
- [Consolidated acceptance ledger](../architecture/phase-3/browser-acceptance-gate-ledger.md)
- [Maintained engine comparison](../architecture/browser-engine-comparison.md), [engine contract](../architecture/browser-engine-contract.md), [platform architecture](../architecture/browser-platform-architecture.md)
- [Security criteria](../security/browser-security-acceptance-criteria.md) and [accepted ADR 0002](0002-browser-distribution-and-platform.md)
