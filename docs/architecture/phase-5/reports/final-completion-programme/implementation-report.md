# Implementation report

| Workstream | Source and checks | Disposition |
| --- | --- | --- |
| Production persistence | ProtectedCatalog, NativeStorageSession, NativeKeyBroker, pinned worker, ADR 0004 and WS-F3 owner record | Runtime lease checks tightened. Catalog admission and durable workspace mounting remain open. |
| Native browser | NativeBrowserChrome, AppKit controller, NativeWebKitStorage, native workspace and recovery runners | Tab selection and pin accessibility metadata, clearer errors and bookmark editor session teardown. See native qualification. |
| Release | Xcode Debug and Release, bundle audit, Go production-preflight | Unified native structure and signed qualification checks. Signing inventory and build evidence are separate. |
| Quality | Nx ESLint, typecheck, navigation and Playwright fixture | Fixed 30 baseline diagnostics. |
| Developer tools | Go module, checksum manifests, workspace matrix | Required case coverage, evidence integrity and explicit blocker ownership. |
| Documentation | This report and Phase 5 index | Actual results are separated from requirements and historical runs. |

The existing Keychain broker now retains the precise caller grant with each lease, checks it before sealing, rechecks the local epoch after actor suspension, and enforces the capacity limit again after the asynchronous authority check. It clears malformed retrieved byte buffers and invalidates authentication contexts when an acquisition cannot publish a lease. Negative tests exercise foreign scope, replaced grant, and forged lease rejection without positive Keychain access.

The SwiftUI tab rows expose selected and pinned state. Error messages distinguish an occupied dispatcher and a Mini handoff that did not confirm. A private session transition dismisses its temporary bookmark sheet and clears the editing draft. Existing AppKit lifecycle and WebKit boundaries remain authoritative.

Lint compared the same target before and after changes. The inherited set comprised 24 named-arrow diagnostics, four accessibility diagnostics, one comment diagnostic and one control-character regex diagnostic. The fixture now uses named arrow functions after checking initialization and callers. Escape stays attached to the shell root. Its resize affordance exposes keyboard range semantics. The two fixture modules with pre-existing formatting drift retain their local style to avoid unrelated churn. Name focus is set by the dialog. URL validation still rejects the same control characters. The legacy fixture assertions remain intact.

Go production-preflight runs the native bundle gate together with signature, entitlement, notarization and runtime-readiness checks. A missing runtime witness remains non-passing. The WS-F7 matrix validator requires IDs F7-01 to F7-20 and rejects duplicates, missing rows, unowned blockers and executed results without an artifact in the checksum manifest. It verifies artifact integrity. A valid ledger can contain blocked cases, and the validator does not establish the semantic accuracy of a case claim.

The full file inventory and source hashes are recorded in the evidence directory.

## Arc reference implementation

The current follow-up adds keyboard and Space-aware command search, bounded native sidebar resizing, state-aware AppKit menus, and a low-sensitivity welcome completion preference. It closes a direct Codable validation bypass in the logical layout. [Implemented workflow and ownership](feature-implementation.md) · [Design system](design-system.md)
