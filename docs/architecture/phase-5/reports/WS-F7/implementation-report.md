# WS-F7 implementation assessment

**Exit: BLOCKED.** Protected workspace persistence, relaunch restore and its integration are unimplemented. No durability, encryption, atomic publication or crash-recovery claim follows from existing layout tests.

Date: 2026-11-10. Branch: `cross-browser-research`. Initial HEAD: `9472b17`; initial checkout clean (0 staged, 0 unstaged, 0 untracked). No commit, push, merge or PR. Host: macOS 27.2 (26B123), arm64; Xcode 27.2 (27B52); Go 1.19.6. Application minimum remains macOS 26.0.

## Actual architecture and blocking dependency

The production [ProtectedCatalog](../../../../../qualification/webkit-storage-f0/Sources/BrowserPersistence/ProtectedCatalog.swift) rejects lookup, catalog writes and recovery journal access. [NativeStorageSession](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeStorageSession.swift) composes that authority at normal startup. Foreground browsing instead creates explicitly private scopes with in-memory catalog/journal adapters. The current `WorkspaceLayout` includes the private logical tab graph; it carries neither a proven persistent-profile binding nor a durable write grant. Serializing that graph would retain private tab state despite the explicit exclusions.

[WS-F3 approved decisions](../WS-F3/approved-decisions.md), [protected persistence](../WS-F3/protected-persistence.md), [remaining gates](../WS-F3/next-gates.md) and [WS-F6 persistence boundary](../WS-F6/persistence-and-recovery.md) govern this dependency. The SQLCipher fixture producer writes a bounded encrypted image in RAM; existing-file admission opens read-only, rejects sidecars, and forbids persistent mutation. In `qualification/sqlcipher-wsf3/descriptor_vfs.c`, `can_initialize` permits writes only to the fresh in-memory fixture. This is not an existing production transactional store to extend with a workspace row.

The existing native Keychain broker requires scoped native authority and data-protection Keychain user-presence items. This run's `security find-identity -v -p codesigning` returned **0 valid identities**. Prior positive Keychain custody gates remain unresolved; historical -34018 observations were not rerun or relabeled as fresh evidence. There is no qualified persisted-key reopen to support a real protected relaunch test on this host.

## Stop boundary and work required

This is a security/architecture dependency under the brief's stop rule, rather than an ordinary schema choice requiring renewed permission. No plaintext JSON, UserDefaults, appearance-settings SQLite, process-local test key, or second profile authority was introduced. Production persistence integration and its dependent native-UI migration were stopped; independent tooling, build repair, regression checks and release preparation continued.

Continuation requires an authorized usable development signing identity with consistent team/app/Keychain configuration for the existing broker. Developer ID distribution identity and notarization access are separate release prerequisites. Then implement and qualify the existing authority's encrypted writer: descriptor/sidecar ownership, authenticated identity, key leases, durable transaction outcomes, migration, conflict handling, interruption recovery, profile admission and lifecycle coordination. This remains engineering work, not a claim that supplying a certificate completes WS-F7.

The brief authorizes WS-F7 implementation. No additional owner approval for ordinary implementation choices is being requested. Any change to the approved pre-key read bound or other privacy boundaries would still require an explicit decision. Once production authority is proven, add an explicitly persistent eligible-metadata boundary that cannot accept private or Mini session graphs and run all 20 required real-storage cases.

[Exact commands and outcomes](../developer-tooling/commands-and-results.md) · [Evidence](../developer-tooling/evidence/safe-foundation-01/) · [Combined report](../developer-tooling/implementation-report.md)
