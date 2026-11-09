# ADR 0008: Mini isolation and URL handoff

- **Status:** Accepted for the scoped WS-F6 in-memory implementation
- **Date:** 2026-11-10
- **Decision owner:** Vezham Browser product owner with native routing and privacy reviewers
- **Authorization:** The WS-F6 implementation brief authorizes the preview and committed-GET handoff. Normal profiles and broad URL control remain gated.

## Context

Mini currently owns an independent private store. Its URL-only transfer closes Mini after the receiver accepts a fresh navigation and source teardown completes. That admission does not prove the page committed or that a changing destination still matches the user's intent. [Source assessment](../architecture/phase-5/reports/WS-F6/current-state-assessment.md) · [Workspace UX research](../architecture/phase-5/reports/cross-browser-research/workspace-and-tab-ux.md)

## Decision

Keep each Mini in its own nonpersistent session, with separate grants, view identity and teardown. Preview the eligible link and exact mounted workspace/active Space plus privacy context. Require explicit confirmation and validate current source and destination. Pass only an eligible committed GET URL and a bounded transfer correlation identity. The receiving context authorizes a fresh GET. Distinguish rejection, acceptance, matching main-frame commit and cleanup. Close automatically only after the matching commit and confirmed source cleanup. A stale destination, denial, nonmatching commit or failure leaves the source available or fenced according to the lifecycle.

Transfer no source cookies, logins, form state, credentials, history, permissions, referrer or native view. Keep source layout and metadata out of durable storage. F6 qualifies owned fixtures with conservative URL eligibility. Product URL policy and real normal destinations require separate review. [Split and Mini contract](../architecture/phase-5/reports/WS-F6/split-screen-and-mini.md)

## Alternatives

| Alternative                                  | Trade-off                                                                                               |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Share a profile/store or move the Mini view  | Maximizes continuity and violates the intended private boundary.                                        |
| Close at request acceptance                  | Shorter interaction, with no proof of receiver commit and greater risk of losing the source on failure. |
| Always keep Mini open                        | Simpler lifecycle, with additional manual cleanup even after a successful handoff.                      |
| Explicit URL handoff with commit-aware close | Preserves intent and source visibility, with a correlation and teardown contract to qualify.            |

## Consequences and qualification

Handoff cannot preserve authentication from Mini; the receiver can use only its own session state. Provenance restrictions may exclude useful URLs and must be evaluated with representative workflows. Require G3/G4 for Main and multiple Mini isolation, stale or denied targets, exact committed request correlation, no duplicate destination tab, independent closure, navigation failures and callback races. Normal protected destination metadata depends on F7 policy and authority. [Qualification](../architecture/phase-5/reports/WS-F6/qualification-matrix.md) · [Existing capability ADR](0005-browser-capability-boundaries-and-lifecycle.md)

## Implementation disposition · 2026-11-10

The user authorized implementation of the existing product direction and resolution of ordinary design details. The current volatile private browser now consumes the workspace model and native binding path. Normal URL retention/replay remains unavailable, Mini accepts only proven direct GETs without queries or fragments, and private recovery preserves logical IDs with blank replacement pages. Existing Core quarantine and uncertain-retirement fences remain authoritative. Native tests observed the scoped behavior after an injected recovery callback. Real WebKit helper termination and release acceptance retain their separate gates. [Implementation report](../architecture/phase-5/reports/WS-F6/implementation-report.md) · [Actual qualification](../architecture/phase-5/reports/WS-F6/implementation-qualification.md)
