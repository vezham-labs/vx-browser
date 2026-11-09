# Vezham cross-browser architecture and product research

**Access date:** 10 November 2026 (Asia/Kolkata). **Vezham baseline:** `timeline` at `f55619dfef819365dc0073166f430b22e70d8a02`, initially clean and aligned with the locally cached `origin/timeline`. This is a research snapshot and recommendation, with no new browser execution or qualification results.

## Executive summary

Vezham already combines a native AppKit window and split-view host, system WebKit, a productive sidebar, a command bar, and independent Mini sessions. Its strongest differentiation in this study is the combination of a lightweight temporary-window workflow and explicit authority, isolation and retirement rules. The underlying code is more advanced than the original WS-F5R investigation describes. A replacement private session is implemented and exercised with injected termination callbacks. Real OS termination, attributed helpers, and other native qualification gaps still determine readiness. [Vezham audit](current-vezham-architecture.md)

Search provides the closest lifecycle comparison. Its saved tab model can exist without a WebKit view, and only the visible selection or split wakes on restore. Arc and Little Arc show how to make a browsing destination explicit, SigmaOS shows how to make commands discoverable, and Zen shows why workspace organization and account isolation deserve distinct labels. Cra, Stedding, Flecha, Refrax and Vela show which ideas survive an engine change and where the packaging, migration, or trust costs rise. [Feature comparison](browser-feature-comparison.md) · [Lifecycle comparison](webkit-lifecycle-comparison.md)

## Scope and inventory

| Role | Browser | Why it is here |
|---|---|---|
| Primary | Arc | Workspace hierarchy, pin semantics, command bar, split, migration and archival UX |
| Primary | Little Arc | Separate window, quick triage, explicit handoff and wrong-destination failure modes |
| Primary | Search by Office Commun | Native SwiftUI/AppKit plus WebKit, source-level view lifecycle, storage, blocking and automation |
| Secondary | SigmaOS | Task-oriented Workspaces and keyboard-led flows in a self-described native WebKit browser |
| Secondary | Zen | Workspace/Firefox container separation, compact chrome, Glance and session storage |
| Secondary | Cra | AppKit/SwiftUI with CEF plus a narrow WebKit media path, Little Windows and importer |
| Secondary | Stedding | Chromium patch stack, sidebar migration, separate Space cookies and sync pitfalls |
| Secondary | Flecha | Patched Chromium with a component-extension shell, developer commands and local MCP |
| Secondary | Refrax | Native WebKit plus optional external engines, profile contracts and authenticated local control |
| Secondary | Vela by JoSanson | Electron composition, Peek and split, migration preview opportunity and benchmark design |

Arc and Little Arc are two research subjects within one closed-source product. The vendor announced a December 22, 2026 sunset. Use its current export documentation and historical release notes when studying migration and interaction. SigmaOS is also proprietary. All seven public repositories were inspected at pinned revisions, with product docs, source/patches, and available release or issue evidence distinguished. [Arc announcement](https://arc.net/) · [Source inventory](source-inventory.md)

## Highest-priority opportunities after WS-F5R

1. **ADOPT** a versioned workspace model with stable logical IDs for Spaces, tabs, groups, windows and split membership. Use synthetic or memory-only fixtures until protected storage is qualified.
2. **ADAPT** Search's lazy restore model. Restore organization first, materialize the authorized visible tab or split, and admit background views on demand.
3. **ADOPT** scoped, discoverable command results and keyboard equivalents for existing sidebar actions. Make the active Space and split target obvious.
4. **ADAPT** Little Arc's explicit handoff. Show a Mini's destination and open an eligible link through the receiving window's own authority and store.
5. **ADAPT** restoration of two-pane layout and focus intent within a workspace, including the narrow-window fallback.

WS-F6 should prove the workspace format and lazy admission. WS-F7 should close the protected catalog, signed Keychain, profile isolation, permissions and owned backup gates before enabling real-user persistence. WS-F8 should qualify the signed internal candidate, supported macOS versions, upgrade and rollback, native workflows and performance. These refinements use the workstream names in the brief and preserve the repository's Phase 5 gates. [Recommendations and gates](architecture-recommendations.md) · [Opportunity matrix](feature-opportunity-matrix.md)

Keep the native host and system WebKit. Exclude alternate engine bundles, production remote debugging or unrestricted agent control, secret migration, private-session disk restore, and Chrome Web Store parity as a launch dependency. Design any later filtering or extension capability against public WebKit APIs and the existing admission model. [Security](privacy-security-comparison.md) · [Extensions and automation](extensions-and-automation.md)

## Report index

- [Current Vezham architecture](current-vezham-architecture.md)
- [Browser feature comparison](browser-feature-comparison.md)
- [WebKit lifecycle comparison](webkit-lifecycle-comparison.md)
- [Workspace and tab UX](workspace-and-tab-ux.md)
- [Persistence and session architecture](persistence-and-session-architecture.md)
- [Privacy and security comparison](privacy-security-comparison.md)
- [Extensions and automation](extensions-and-automation.md)
- [Performance and reliability](performance-and-reliability.md)
- [Feature opportunity matrix](feature-opportunity-matrix.md)
- [Architecture recommendations](architecture-recommendations.md)
- [Source inventory](source-inventory.md)
