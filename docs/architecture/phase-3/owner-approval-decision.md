# Owner approval decision — Phase 4.2

**Decision date:** 2026-11-07  
**Decision authority:** Product Owner  
**Source of authority:** explicit Product Owner decisions supplied in the Phase 4.2 instruction. No personal signatory identity or approval beyond that instruction is inferred.  
**Task scope:** final owner approval recording, verification of the completed Phase 4.1 ADR correction and Phase 5 kickoff preparation only. The valid existing owner/plan drafts are retained and finalized; no duplicate record is created.

## Decisions as approved

| Decision | Approved wording | Meaning and boundary |
|---|---|---|
| 1. Phase 3 closure | **APPROVED** | Close the bounded feasibility investigation with its recorded limitations, failures, blocked tests and deferrals. Not a complete browser/security/performance/release acceptance. |
| 2. WKWebView engine | **CONDITIONAL ACCEPTANCE for MVP planning and implementation** | WKWebView is the conditionally accepted MVP direction behind an engine-independent adapter. This is not unconditional production-engine approval or permission to release a product. |
| 3. Architecture baseline | **APPROVED** | Approve the boundaries and invariants in the [architecture baseline](browser-mvp-architecture-baseline.md), including its explicit unresolved implementation details. Approval does not invent choices for the core runtime, transport, database, permissions or release tooling. |

The second decision includes **implementation**, not merely planning. It must not be rewritten as either “WKWebView unapproved” or “WKWebView unconditionally approved for production.” The three decisions above do not need to be requested again merely because ADR 0001 retains a Proposed lifecycle status.

This documentation task performs no implementation. A separate scoped Phase 5 execution instruction is required to begin work; the [Phase 5 plan](../phase-5/phase-5-implementation-plan.md) is prepared, not started. This record authorizes no internal release or deployment, and **no public distribution is authorized**.

## Phase 3 closure and evidence limits

The [primary exit review](phase-3-exit-review.md) records **49/49 actual-window recovery checks** and the separate **48/48 regression checks** on the matching latest recovery revision. Neither result is a combined browser acceptance rate. Earlier permission/transfer/public-page and performance observations retain their own source revisions, method limits and failed/incomplete parents. Historical performance does not qualify the latest recovery revision or a future Phase 5 product revision.

All prototype source, original evidence, source manifests/hashes, historical reports and existing review archives remain preserved. No failed, blocked, deferred or untested criterion becomes Passed through owner approval. The [67-item gate ledger](browser-acceptance-gate-ledger.md), its A/B/C/D classifications, row statuses and historical failure register remain an unchanged Phase 4 review snapshot.

The ledger's B12 entry describes owner approval as blocked **at that snapshot**. This dated record supplies the three owner decisions now; it does not rewrite B12, change historical counts, clear B01-B11 access restrictions, settle ADR lifecycle status or grant technical acceptance. Phase 5 uses this record for present approval authority and the unchanged ledger for remaining requirements.

## Remaining conditions and mandatory gates

1. **Platform and separation:** macOS **26.0 minimum**, internal-only, Swift/AppKit native host, React + TypeScript + HeroUI v3 chrome, engine-independent core and private engine-adapter implementation details remain fixed. Architecture approval preserves the listed freeze exceptions until resolved before their relevant milestone.
2. **Security:** no cross-profile/private-data leak or unauthorized action is acceptable. Such a defect blocks the affected milestone and release until remediated and evidenced; it is never waived into Passed. Production chrome origin/CSP, typed allowlist, frame/origin/ownership/replay/size validation and credential boundaries must be implemented and verified.
3. **Profiles, privacy and native services:** product-owned history/state, private-session exclusions/cleanup, permission grant/expiry/revocation, file destination/scope/metadata/quarantine and wider recovery/cancellation scenarios still require implementation and evidence. Prototype slices do not establish whole-product behavior.
4. **Compatibility and access:** public-pages-only restrictions remain. Account/MFA/SSO/passkey, editing/payment sandbox, conferencing and any actual website media grants require separately approved scope and environments. Conditional engine acceptance does not approve those tests or assert compatibility. Product launch-critical subflows and supported capabilities remain to be named.
5. **Performance and reliability:** qualify the applicable Phase 5/release revision against the already approved targets with explicit source/OS/engine/method provenance. Do not reuse historical proxy measurements as new-revision passes. Report timing/resource method limitations and remaining blockers.
6. **Final-release conditions:** macOS 26.0 and the latest supported 26.x runtime matrix, Developer ID signing and Apple notarization remain at final release validation. Also retain clean install/Gatekeeper, actual release entitlements/sandbox, signed update metadata/artifact integrity, channels/rollback/revocation, dependency review and release-owner sign-off under accepted [ADR 0002](../../decisions/0002-browser-distribution-and-platform.md). None is waived or pre-passed.
7. **Optional services:** local browsing must work without Vezham identity, cloud or Tamizhi. Identity/cloud integration remains optional and outside the required foundation. **No production Tamizhi integration** is in Phase 5 scope; future integration requires a separate feature/data-flow approval.
8. **Excluded work:** **Chromium/CEF remains evaluation-only; no Chromium/CEF implementation. Aura remains excluded, including `@vezham/aura` dependencies, imports, placeholders and API assumptions. No public distribution is authorized.**

## ADR 0001 / Phase 4.1 consistency review

**Phase 4.1 is complete and reviewed**, as confirmed by the Product Owner. Canonical [ADR 0001](../../decisions/0001-browser-engine-strategy.md) already contains the corrected three-stage validation policy and the conditional owner decisions. It was inspected during Phase 4.2 and **retained without modification**; this task does not duplicate or reapply the completed correction. The verified ADR SHA-256 is `e51917928b8e4321830b0b276c10dcb3758414c65a5c036f6b833618ad770ef5`.

The consistency review confirms the three approvals above; separate primary 49/49 recovery and 48/48 regression results; the limits of historical performance; Stage A/B/C sequencing; preservation of mandatory security/release criteria; evaluation-only CEF; Aura exclusion; and no public distribution or implementation execution in this task. Existing valid ADR findings and references remain intact.

**ADR lifecycle status remains Proposed.** The status is not silently changed to Accepted. The owner's conditional planning/implementation decision and architecture/closure approvals are real; the Proposed label neither erases them nor requires them to be requested again. No unconditional production-engine acceptance or technical gate pass follows. Any later formal ADR status transition requires its own explicit disposition.

## Validation stages and gate-category mapping

The completed Phase 4.1 **validation stages A/B/C describe timing**. The preserved gate ledger's **categories A/B/C/D describe requirement types**. They are different classifications; neither is renamed or rewritten by this approval record.

| Completed ADR validation policy | Effect after the owner decisions | Remaining obligation / Phase 5 placement |
|---|---|---|
| **Stage A — Before engine selection** | Bounded evidence and limitations underpin the owner's conditional choice; closure and baseline are approved. | Critical subflows/capabilities and explicit unresolved-risk dispositions remain to be documented before affected implementation decisions. If a named risk cannot be accepted, use finite authorized validation or hold that affected scope; do not repeat the three approvals. |
| **Stage B — During implementation** | Conditional WKWebView planning/implementation and approved architecture guide separately scoped Phase 5 tasks. | M0-M7 implement and validate architecture, engine/bridge trust boundaries, profiles/private sessions, permissions/files/lifecycles and authorized critical workflows. Cross-profile/private leakage and unauthorized native access are hard failures. |
| **Stage C — Before final release** | Final-release obligations stay mandatory and unpassed. | M8 validates macOS 26.0/latest supported 26.x runtime, Developer ID/notarization, Gatekeeper/sandbox/Hardened Runtime/entitlements, current release performance/compatibility, internal distribution and updater security before any separate internal release decision. |

Category A feasibility results remain bounded; category B account/media/scope blockers remain unresolved except for the three administrative owner decisions recorded here; category D product work moves into relevant Stage B implementation milestones; category C release requirements remain Stage C. The unchanged ledger's B12/status counts are a historical snapshot, not a demand to repeat approvals. No requirement, result or status is relabelled Passed through this mapping.

The [Phase 5 scope and milestones](../phase-5/phase-5-scope-and-milestones.md) and [implementation plan](../phase-5/phase-5-implementation-plan.md) carry these obligations forward. This mapping changes no mandatory criterion and supplies no additional account/media authorization, security exception or release permission.

## Related records

- [Phase 3/4 closeout index](README.md) and [primary exit review](phase-3-exit-review.md)
- [Historical engine assessment](browser-engine-decision-assessment.md), [approved architecture baseline](browser-mvp-architecture-baseline.md), [unchanged gate snapshot](browser-acceptance-gate-ledger.md)
- [Canonical ADR 0001](../../decisions/0001-browser-engine-strategy.md)
- [Phase 5 index](../phase-5/README.md), [scope/milestones](../phase-5/phase-5-scope-and-milestones.md), [implementation plan](../phase-5/phase-5-implementation-plan.md)
