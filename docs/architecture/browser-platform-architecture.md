# Browser Platform Architecture

**Status:** Maintained architecture aligned to the approved Phase 4 baseline; implementation remains staged  
**Platform baseline:** macOS 26 Tahoe and later  
**Distribution:** Internal-only; see [distribution architecture](browser-distribution.md)

## Product decisions

- Browser chrome uses React + TypeScript + HeroUI v3.
- The native host uses Swift + AppKit.
- The browser core and product-facing data models remain engine-independent.
- WKWebView has CONDITIONAL ACCEPTANCE for MVP planning and implementation under the [owner decision](phase-3/owner-approval-decision.md). ADR 0001 remains Proposed; this is not unconditional production-engine or release approval. Chromium/CEF remains evaluation-only, with no implementation in scope.
- `@vezham/aura` is not ready. Do not add it, import it, create a placeholder, or assume its APIs.
- Local browsing must remain usable when Vezham ID, Tamizhi, sync, or other Vezham cloud services are unavailable.

## Process and trust separation

The native AppKit host owns app lifecycle, windows, profile orchestration, local persistence, permission policy, Keychain access, file panels, downloads coordination, update policy, and engine-view lifecycle. The browser core defines engine-independent operations and policy. React renders browser chrome inside a dedicated, app-owned UI web view or equivalent isolated UI surface.

Remote websites render only in engine-managed content views. Do not load arbitrary websites in the privileged browser UI view. Do not expose the browser UI's native bridge, account state, file access, or privileged commands to website content. UI resources should be bundled and served from a fixed app-controlled origin/scheme; navigation away from that origin is denied or opened as website content in a separate view after native policy checks.

The React-to-native boundary consists of versioned typed commands and events. Swift validates message shape, size, enum values, identifiers, current profile/view ownership, caller origin, and authorization for every command. The bridge is allowlisted; unknown commands fail closed. Avoid generic method dispatch and arbitrary native object exposure. Website content has no direct bridge. Any page script execution remains explicit, narrowly scoped, page-world functionality, and distinct from browser UI commands.

## Engine adapter boundary

The browser core owns opaque `ProfileId`, `ViewId`, navigation IDs, history and permission records, and capability declarations. It does not expose WKWebView or CEF objects to React. A native adapter maps product operations onto an engine and reports `supported`, `partial`, or `unsupported` capabilities with version context.

WKWebView is conditionally accepted as the MVP adapter direction behind the engine-independent boundary. Bounded feasibility evidence supports that direction; production data-store behavior, critical workflows and release readiness still require the staged validation in ADR 0001. Do not claim that `WKWebsiteDataStore` automatically provides complete profile or security isolation: validate persistent stores by identifier, non-persistent stores, cookies, local storage, IndexedDB, service workers, caches, concurrent views, deletion behavior, and crash recovery on the supported OS. CEF is not in the active implementation plan; a later evaluation must separately address runtime size, helper apps, sandbox, signing, extension needs, security updates, and licensing.

## Storage and optional services

Use distinct persistent engine data stores for persistent browser profiles and an in-memory, non-persistent store for private browsing. Keep browser-owned state (history, bookmarks, permissions, downloads metadata, settings) in a profile-keyed local store. Credentials and Vezham ID tokens belong in Keychain, not web content, React state persistence, logs, or sync payloads. Private browsing does not write to persistent browser history or sync and must clean up its in-memory store when its private session ends.

Tamizhi is future/phased; no production integration is authorized in the current M0 or required Phase 5 foundation. A later separately approved feature must remain disabled until its scoped consent/data-flow policy is validated. Any page-derived data transfer requires explicit, understandable consent and least-data selection. Vezham ID and cloud sync are optional capabilities. Local browsing, bookmarks/history stored locally, and the engine itself must not depend on cloud reachability.

## App security and release

Use Developer ID Application signing and notarization for internal direct distribution, with minimal App Sandbox entitlements and a documented justification for every exception. Exact sandbox and hardened-runtime configuration remains an implementation gate. Distribution channels, signed update metadata, artifact integrity, rollout, rollback, minimum version, and revocation are defined in [browser distribution](browser-distribution.md).

## Implementation sequence

1. Stage A: preserve the approved bounded Phase 3 closure and conditional engine/baseline decisions; identify remaining critical-workflow and unresolved-risk dispositions before affected implementation choices.
2. Stage B: execute only scoped implementation milestones. Current authorization is [M0 native foundation](phase-5/reports/M0/README.md); M1-M8 remain unstarted. Validate production bridge, profile/private, permissions/files and lifecycle security before relying on those features; remote content has no privileged native bridge.
3. Stage C: qualify the release candidate on macOS 26.0/latest supported 26.x, Developer ID/notarization, Gatekeeper/sandbox/Hardened Runtime and release compatibility/performance/update security. Final-stage scheduling does not waive requirements.

The [approved boundary baseline](phase-3/browser-mvp-architecture-baseline.md) and [ADR 0001](../decisions/0001-browser-engine-strategy.md) govern. Current M0 execution does not authorize the full adapter, product chrome, production Tamizhi/cloud or release.
