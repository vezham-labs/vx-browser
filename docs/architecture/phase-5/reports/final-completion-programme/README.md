# Final engineering completion programme

**Readiness verdict: partial. Production and distribution acceptance remain open.**

The programme started from the clean cross-browser-research checkout at 3866390170ed8730fb60342292e5786088f402e3. A read-only remote query confirmed the same branch tip and timeline at f55619dfef819365dc0073166f430b22e70d8a02. The timeline reference was used for comparison only.

SwiftUI and AppKit remain the active Main and Mini interface. This run improves tab accessibility and action feedback, tightens native Keychain lease checks, resolves 30 inherited fixture lint diagnostics, and adds a machine-readable WS-F7 matrix validator and production preflight.

Production workspace persistence remains unavailable. The pinned provider is qualified for a bounded disposable path. The production descriptor broker, writer and lifecycle adapters remain unimplemented, and positive signed Keychain evidence is unavailable. The existing application keeps browsing workspaces private and volatile.

- [Implementation](implementation-report.md)
- [Verification and commands](verification.md)
- [Workspace matrix](workspace-matrix.md)
- [Security and recovery](security-and-recovery.md)
- [Native qualification](native-qualification.md)
- [Release readiness](release-readiness.md)
- [Remaining blockers](remaining-blockers.md)

## Arc alternative programme follow-up

**Partially complete.** Started and ended on cross-browser-research at beb1a6fab0b378aaf83875e6294ca82b1bb58446. The new native command palette, sidebar resizing, menu actions and welcome flow are implemented. The workspace graph decoder now enforces validation for all Codable entry points. The confirmed reference is Arc 1.172.1 build 90370. Exact visual parity is unverified. The browser remains private-only and production persistence is blocked by authorization and unfinished integration. Signed release is blocked by credentials.

- [Arc feature matrix](arc-parity-matrix.md)
- [Native design tokens](design-system.md)
- [Screen comparison and qualification](ui-ux-qualification.md)
- [Implemented scope and gaps](feature-implementation.md)
- [Welcome, menus and settings](onboarding-and-settings.md)
- [External authorization checklist](external-authorization-checklist.md)

Current results are in the follow-up section of [verification](verification.md). Earlier sections remain evidence from their own revision.


---

# Installed-app qualification follow-up — 2026-11-10

**Overall PARTIAL. Development installation and bounded installed workflows verified. Full Arc parity and production release acceptance remain open.**

Starting HEAD `ce2a9fa6a013b2f70f990c50468f27ed22517914` on `cross-browser-research`. Native sidebar favorites/bookmarks/folders now use a validated volatile domain model with stable item IDs and strict website destinations. Associated-item opening, folder management, session-scoped drag payloads and an explicit enter-page action were implemented. The new bookmark tests compile and pass after correcting Swift Testing macro usage.

- [Installation and launch](installation-and-launch.md)
- [Installed browser workflows](browser-workflow-qualification.md)
- [Drag qualification](drag-and-drop-qualification.md)
- [Visual comparison](visual-comparison.md)
- [Updated Arc matrix](arc-parity-matrix.md)
- [Verification](verification.md)
- [Remaining blockers and manual actions](remaining-blockers.md)
- [Raw candidate evidence](evidence/installation-01/)

The app is installed in the user's Applications directory as `Vezham Browser Development.app`. It launched from that location and loaded the correct saved-item URL. Native private browsing, tabs, Space switching, Split View, Mini and Settings were observed. Physical drag, relaunch and matched Arc visual qualification remain unresolved. The production persistence and release fences remain in place.

## Live Arc follow-up — 2026-11-10

The live Arc reference is now accessible through Arc 2.app. The installed Vezham UI Preview includes the sidebar layout and keyboard focus correction. [Comparison and evidence](arc-ui-alignment.md).


[Favorite reorder and equal-size Arc captures](arc-drag-follow-up.md) records the updated preview, regression results and remaining interaction and comparison limits.
