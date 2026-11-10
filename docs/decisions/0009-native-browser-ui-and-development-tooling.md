# ADR 0009: Native browser UI and development tooling

- **Status:** Accepted target technology direction. Native shell active, qualification partial.
- **Date:** 2026-11-10
- **Authority:** Current WS-F7/native-alignment/WS-F8 implementation brief explicitly establishes this policy.

## Context

ADR 0002 selected native host plus React chrome for the initial slice. The functioning product has AppKit windows and split surfaces around bundled React/HeroUI controls. The owner now directs primary macOS chrome to SwiftUI/AppKit and standalone reusable developer qualification tooling to Go. Existing workspace/private lifecycle behavior must survive migration. The protected production persistence authority remains unavailable.

## Decision

Swift owns application/domain state, persistence, navigation, recovery and profile authority. SwiftUI is the target primary application presentation; AppKit owns window, responder, accessibility and advanced native integration where needed. WebKit owns website rendering, stores and content process lifecycle. This supersedes ADR 0002's React-shell direction for future primary chrome, while recording that the current runtime still uses that earlier implementation.

Go is development-only qualification/evidence tooling, preferably standard library. Existing useful Python tools remain development-only. No Go/Python application runtime dependency is introduced. HeroUI may serve deliberate web interfaces, but the current browser shell is a legacy migration surface and cannot be relabeled an internal tool to satisfy the target direction.

## Alternatives

Retaining React indefinitely conflicts with the new owner direction. A wholesale replacement risks breaking workspace, focus, recovery and Mini semantics. Incremental native presentation on existing Swift/AppKit authority preserves tested behavior while allowing staged qualification. Rewriting working Python runners merely for uniformity adds migration risk without demonstrated benefit.

## Consequences and migration

Inventory all browser surfaces and preserve behavior before removing dependencies. Replace each shell surface with native presentation and verify accessibility/focus plus integration. Retire bridge/resources and HeroUI only after no live browser usage remains; other repository web products remain independently scoped. Persistence may not bypass Option D or the existing protected profile authority. Credential and signed-custody blockers do not grant a plaintext fallback.

This record accepts the user-directed target policy. It does not assert that native migration, protected persistence or signed release is implemented or qualified. [Actual work](../architecture/phase-5/reports/developer-tooling/implementation-report.md) · [UI inventory](../architecture/phase-5/reports/native-ui-alignment/implementation-report.md)

## Implementation update

The browser hosts its Main and Mini chrome in SwiftUI within AppKit. Website rendering remains in separately managed WebKit views. Xcode excludes the legacy web shell resources. The legacy source and Playwright fixture remain available for historical comparison. Native interaction and release qualification remain partial. [Implementation and evidence](../architecture/phase-5/reports/completion-programme/README.md).
