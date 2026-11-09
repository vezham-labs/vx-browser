# Source inventory

**Accessed 2026-11-10 (Asia/Kolkata)** unless a historical publication or test date is specified. **S** source/patch observation, **D** documented by project, **C** project claim or self-measurement, **I** inference, **U** unverified, **H** historical qualification or static inspection read from Vezham's repository. Source findings are bounded to these snapshots and may differ from packaged releases. This study did not execute competitor applications, inspect proprietary app source, conduct new independent benchmarks, or run Vezham tests. Source links for public Git repositories are pinned below. Vezham local links resolve in the installed repository report.

## Arc and Little Arc

- **D** Product status and sunset, workspace/features mapping, desktop export, privacy and historical changes. Little Arc is covered in its parent product's release notes, including wrong-Space/Profile fixes, archived links and shortcut behavior. [Arc](https://arc.net/) · [Sunset FAQ](https://resources.arc.net/hc/en-us/articles/44413577819159-Arc-Sunset-Frequently-Asked-Questions) · [Export](https://resources.arc.net/hc/en-us/articles/25583851606039-How-Do-I-Export-My-Data-from-Arc) · [Privacy](https://resources.arc.net/hc/en-us/articles/19434846038935-Privacy-Security) · [macOS release notes 2024–2026](https://resources.arc.net/hc/en-us/articles/20498293324823-Arc-for-macOS-2024-2026-Release-Notes) · [2023 notes](https://resources.arc.net/hc/en-us/articles/20498377604887-Arc-for-macOS-2023-Release-Notes)
- **H/I** The local Nov 7 historical Arc 1.172.1 report observed Mach-O links and Chromium-derived helper roles, with custom integration inferred. It did not resolve all WebKit usage. [Historical Arc inspection](../../../../../arc-macos-architecture-report.md)
- **U** App source is proprietary. Dedicated Little Arc process, exact website-data scope, page handoff, restart, eviction and extension behavior remain unverified. Historical standalone Little Arc help was unavailable via the tested URL. The vendor's release notes and FAQ are the usable primary sources.

## SigmaOS

- **D** Workspace management, nested pages, task actions, keyboard mode, Lazy Search, two-page Split Screen, and extension setup. [Product](https://sigmaos.com/) · [Workspaces](https://docs.sigmaos.com/tutorial/workspaces) · [Lazy Search](https://docs.sigmaos.com/tutorial/pages) · [Split](https://docs.sigmaos.com/tutorial/split-screen) · [Cheat sheet](https://docs.sigmaos.com/cheat-sheet) · [Extensions](https://docs.sigmaos.com/tutorial/extensions) · [Common questions](https://docs.sigmaos.com/common-questions) · [1.0 release notes](https://sigmaos.com/updates/1-0)
- **C/U** Vendor describes SwiftUI/WebKit, native Keychain and tracking prevention, unload, sync, and energy advantages. Source is proprietary. Store allocation, retention/backup and suspension details, installed extension compatibility and timing are unverified.

## Search

**Source revision:** `e198e77b6e57519d6ceb0d13a816757dffa586ad`. [Repository](https://github.com/driceroland/Search) · [Product and performance claims](https://searchbrowser.app/) · [Releases](https://github.com/driceroland/Search/releases) · [Close-time state loss issue](https://github.com/driceroland/Search/issues/750)

- **D/C** product, UI and privacy claims. [README.md](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/README.md)
- **D** restore, focus and private logging fixes. [CHANGELOG.md](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/CHANGELOG.md)
- **S** Swift packaging. [Package.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Package.swift)
- **S** restore, visible wake, navigation and WKDownload delegate. [Sources/Search/Browser.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Sources/Search/Browser.swift)
- **S** lazy PageView and store configuration. [Sources/Search/Tab.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Sources/Search/Tab.swift)
- **S** serialized rows and layout. [Sources/Search/Session.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Sources/Search/Session.swift)
- **S** persistent store assignment and deletion. [Sources/Search/Spaces.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Sources/Search/Spaces.swift)
- **S** additional window management and restore. [Sources/Search/Windows.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Sources/Search/Windows.swift)
- **S** idle sleep exclusions. [Sources/Search/Sleep.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Sources/Search/Sleep.swift)
- **S** public and private termination callbacks, recovery UX. [Sources/Search/Dialogs.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Sources/Search/Dialogs.swift)
- **S** split UI. [Sources/Search/SplitView.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Sources/Search/SplitView.swift)
- **S** compiled rule lists. [Sources/Search/Shield.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Sources/Search/Shield.swift)
- **S** Keychain operations. [Sources/Search/Vault.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Sources/Search/Vault.swift)
- **S** controller and adapters. [Sources/Search/Extensions.swift](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Sources/Search/Extensions.swift)
- **S** AppleScript read vocabulary and privacy exclusions. [Search.sdef](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Search.sdef)
- **S** isolated test process and MCP. [bench-mcp](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/bench-mcp)
- **S** harness test. [Tests/bench_mcp.py](https://github.com/driceroland/Search/blob/e198e77b6e57519d6ceb0d13a816757dffa586ad/Tests/bench_mcp.py)

**U.** Release equivalence, performance, privacy guarantees, extension compatibility and full per-window lifecycle were not reproduced. The README's one-window positioning is narrower than the inspected window management source.

## Zen

**Source revision:** `498360074520dcbc9aaa491f498a171a0fa6df07`. [Repository](https://github.com/zen-browser/desktop) · [Product and Mods](https://zen-browser.app/) · [Release notes](https://zen-browser.app/release-notes/latest/) · [Workspaces](https://docs.zen-browser.app/user-manual/workspaces) · [Compact Mode](https://docs.zen-browser.app/user-manual/compact-mode) · [Glance](https://docs.zen-browser.app/user-manual/glance) · [Split](https://docs.zen-browser.app/user-manual/split-view) · [Shortcuts](https://docs.zen-browser.app/user-manual/shortcuts)

- **D** Firefox base and build streams. [README.md](https://github.com/zen-browser/desktop/blob/498360074520dcbc9aaa491f498a171a0fa6df07/README.md)
- **S** workspace state and interaction. [src/zen/spaces/ZenSpaceManager.mjs](https://github.com/zen-browser/desktop/blob/498360074520dcbc9aaa491f498a171a0fa6df07/src/zen/spaces/ZenSpaceManager.mjs)
- **S** Glance workflow. [src/zen/glance/ZenGlanceManager.mjs](https://github.com/zen-browser/desktop/blob/498360074520dcbc9aaa491f498a171a0fa6df07/src/zen/glance/ZenGlanceManager.mjs)
- **S** split. [src/zen/split-view/ZenViewSplitter.mjs](https://github.com/zen-browser/desktop/blob/498360074520dcbc9aaa491f498a171a0fa6df07/src/zen/split-view/ZenViewSplitter.mjs)
- **S** sidebar restoration, migration and fallback. [src/zen/sessionstore/ZenSessionManager.sys.mjs](https://github.com/zen-browser/desktop/blob/498360074520dcbc9aaa491f498a171a0fa6df07/src/zen/sessionstore/ZenSessionManager.sys.mjs)
- **S** upstream integration. [src/browser/components/sessionstore/SessionStore-sys-mjs.patch](https://github.com/zen-browser/desktop/blob/498360074520dcbc9aaa491f498a171a0fa6df07/src/browser/components/sessionstore/SessionStore-sys-mjs.patch)
- **S** extension tab integration. [src/browser/components/extensions/parent/ext-tabs-js.patch](https://github.com/zen-browser/desktop/blob/498360074520dcbc9aaa491f498a171a0fa6df07/src/browser/components/extensions/parent/ext-tabs-js.patch)
- **S** browser customization. [src/zen/mods/ZenMods.mjs](https://github.com/zen-browser/desktop/blob/498360074520dcbc9aaa491f498a171a0fa6df07/src/zen/mods/ZenMods.mjs)

**U.** Current build process scheduling, DRM/auth coverage, key custody and launch/resource benchmarks were not reproduced.

## Cra

**Source revision:** `992760043e1c629337822d13bf09fc410fc732a8`. [Repository](https://github.com/VictorKildahl/cra) · [Help and onboarding](https://crabrowser.app/help) · [Release notes](https://crabrowser.app/release-notes)

- **D/C** CEF, features, imports and claims. [README.md](https://github.com/VictorKildahl/cra/blob/992760043e1c629337822d13bf09fc410fc732a8/README.md)
- **S** package and CEF boundary. [Package.swift](https://github.com/VictorKildahl/cra/blob/992760043e1c629337822d13bf09fc410fc732a8/Package.swift)
- **S** CEF request contexts and renderer termination. [Sources/CraCEF/CraCEF.mm](https://github.com/VictorKildahl/cra/blob/992760043e1c629337822d13bf09fc410fc732a8/Sources/CraCEF/CraCEF.mm)
- **S** engine dispatch and media exception. [Sources/Cra/Services/WebKit/PageEngines.swift](https://github.com/VictorKildahl/cra/blob/992760043e1c629337822d13bf09fc410fc732a8/Sources/Cra/Services/WebKit/PageEngines.swift)
- **S** native layout and routing integration. [Sources/Cra/UI/Windows/MainWindowController.swift](https://github.com/VictorKildahl/cra/blob/992760043e1c629337822d13bf09fc410fc732a8/Sources/Cra/UI/Windows/MainWindowController.swift)
- **S** Little Window owner. [Sources/Cra/UI/Windows/LittleWindowController.swift](https://github.com/VictorKildahl/cra/blob/992760043e1c629337822d13bf09fc410fc732a8/Sources/Cra/UI/Windows/LittleWindowController.swift)
- **S** native Keychain access. [Sources/Cra/Services/SafeStorage.swift](https://github.com/VictorKildahl/cra/blob/992760043e1c629337822d13bf09fc410fc732a8/Sources/Cra/Services/SafeStorage.swift)
- **D** engine-specific media policy. [docs/protected-media.md](https://github.com/VictorKildahl/cra/blob/992760043e1c629337822d13bf09fc410fc732a8/docs/protected-media.md)
- **D** local measurement design. [docs/performance.md](https://github.com/VictorKildahl/cra/blob/992760043e1c629337822d13bf09fc410fc732a8/docs/performance.md)

**U.** DRM success, release signing claims, complete restoration fidelity, and feature parity across CEF and WebKit were not verified.

## Stedding

**Source revision:** `a93a12d0bdcd321ef218dae65a3569d184f259be`. [Repository](https://github.com/ysalitrynskyi/stedding-browser) · [Product](https://stedding.dev/) · [Releases](https://github.com/ysalitrynskyi/stedding-browser/releases) · [Sync issue 89](https://github.com/ysalitrynskyi/stedding-browser/issues/89)

- **D/C** product, platform, settings and feature gaps. [README.md](https://github.com/ysalitrynskyi/stedding-browser/blob/a93a12d0bdcd321ef218dae65a3569d184f259be/README.md)
- **D** import scope and constraints. [docs/features/import.md](https://github.com/ysalitrynskyi/stedding-browser/blob/a93a12d0bdcd321ef218dae65a3569d184f259be/docs/features/import.md)
- **D** isolation, routes and limitations. [docs/features/sessions.md](https://github.com/ysalitrynskyi/stedding-browser/blob/a93a12d0bdcd321ef218dae65a3569d184f259be/docs/features/sessions.md)
- **D** partition rationale. [docs/decisions/0019-space-sessions-are-storage-partitions.md](https://github.com/ysalitrynskyi/stedding-browser/blob/a93a12d0bdcd321ef218dae65a3569d184f259be/docs/decisions/0019-space-sessions-are-storage-partitions.md)
- **S** first-run flow. [patches/0015-welcome-a-first-run-flow-in-place-of-the-bare-search.patch](https://github.com/ysalitrynskyi/stedding-browser/blob/a93a12d0bdcd321ef218dae65a3569d184f259be/patches/0015-welcome-a-first-run-flow-in-place-of-the-bare-search.patch)
- **S** Chromium partition implementation. [patches/0046-spaces-isolate-cookies-per-space-in-a-storage-partit.patch](https://github.com/ysalitrynskyi/stedding-browser/blob/a93a12d0bdcd321ef218dae65a3569d184f259be/patches/0046-spaces-isolate-cookies-per-space-in-a-storage-partit.patch)
- **S** Peek implementation. [patches/0088-feat-peek-rebuilt-on-the-little-window.patch](https://github.com/ysalitrynskyi/stedding-browser/blob/a93a12d0bdcd321ef218dae65a3569d184f259be/patches/0088-feat-peek-rebuilt-on-the-little-window.patch)
- **S** Space sleep policy. [patches/0021-spaces-switcher-overflow-and-reorder-the-space-sleep.patch](https://github.com/ysalitrynskyi/stedding-browser/blob/a93a12d0bdcd321ef218dae65a3569d184f259be/patches/0021-spaces-switcher-overflow-and-reorder-the-space-sleep.patch)
- **C** historical project benchmark, method and limits. [docs/perf/README.md](https://github.com/ysalitrynskyi/stedding-browser/blob/a93a12d0bdcd321ef218dae65a3569d184f259be/docs/perf/README.md)

**U.** Published release parity, latest runtime footprint, import reliability and all partition edge cases remain unverified.

## Flecha

**Source revision:** `e54caa21edcb21b8936d6424dae3887078e2a805`. [Repository](https://github.com/lucianodiisouza/flecha-browser) · [Releases](https://github.com/lucianodiisouza/flecha-browser/releases)

- **D/C** current engine, product flows and project claims. [README.md](https://github.com/lucianodiisouza/flecha-browser/blob/e54caa21edcb21b8936d6424dae3887078e2a805/README.md)
- **S** engine pin. [chromium/CHROMIUM_VERSION](https://github.com/lucianodiisouza/flecha-browser/blob/e54caa21edcb21b8936d6424dae3887078e2a805/chromium/CHROMIUM_VERSION)
- **S** component extension and permissions. [chromium/shell/manifest.json](https://github.com/lucianodiisouza/flecha-browser/blob/e54caa21edcb21b8936d6424dae3887078e2a805/chromium/shell/manifest.json)
- **S** developer commands. [chromium/shell/ui/devCommands.ts](https://github.com/lucianodiisouza/flecha-browser/blob/e54caa21edcb21b8936d6424dae3887078e2a805/chromium/shell/ui/devCommands.ts)
- **S** split-incognito shell state. [chromium/shell/incognito.ts](https://github.com/lucianodiisouza/flecha-browser/blob/e54caa21edcb21b8936d6424dae3887078e2a805/chromium/shell/incognito.ts)
- **S** Space partitioning. [chromium/patches/0034-spaces-with-separate-cookies.patch](https://github.com/lucianodiisouza/flecha-browser/blob/e54caa21edcb21b8936d6424dae3887078e2a805/chromium/patches/0034-spaces-with-separate-cookies.patch)
- **S** loopback, Host and token checks. [chromium/native-host/agentServer.ts](https://github.com/lucianodiisouza/flecha-browser/blob/e54caa21edcb21b8936d6424dae3887078e2a805/chromium/native-host/agentServer.ts)
- **S** agent action schemas. [chromium/shared/agentTools.ts](https://github.com/lucianodiisouza/flecha-browser/blob/e54caa21edcb21b8936d6424dae3887078e2a805/chromium/shared/agentTools.ts)
- **S** browser import. [chromium/native-host/browserImport.ts](https://github.com/lucianodiisouza/flecha-browser/blob/e54caa21edcb21b8936d6424dae3887078e2a805/chromium/native-host/browserImport.ts)

**U.** Standalone flecha.dev and its /docs path were unavailable via web retrieval. Repository docs and source were accessible. MCP adversarial behavior, signing and website/extension parity claims were not reproduced.

## Refrax

**Source revision:** `a34ec67fe2ce384e09037f92227de224d3631c98`. [Repository](https://github.com/kageroumado/refrax-browser) · [Product](https://kagerou.glass/refrax/) · [Releases](https://github.com/kageroumado/refrax-browser/releases)

- **D** UX, engine installation and CLI. [README.md](https://github.com/kageroumado/refrax-browser/blob/a34ec67fe2ce384e09037f92227de224d3631c98/README.md)
- **D** engine and profile contracts. [Engines/CONTRACT.md](https://github.com/kageroumado/refrax-browser/blob/a34ec67fe2ce384e09037f92227de224d3631c98/Engines/CONTRACT.md)
- **S** IPC contracts. [Engines/Chromium/refrax/common/mojom/engine.mojom](https://github.com/kageroumado/refrax-browser/blob/a34ec67fe2ce384e09037f92227de224d3631c98/Engines/Chromium/refrax/common/mojom/engine.mojom)
- **S** WebKit profile/store selection. [Refrax/Core/Managers/Tabs/SpaceDataStoreManager.swift](https://github.com/kageroumado/refrax-browser/blob/a34ec67fe2ce384e09037f92227de224d3631c98/Refrax/Core/Managers/Tabs/SpaceDataStoreManager.swift)
- **S** host tab persistence. [Refrax/Core/Managers/Tabs/TabManager+Persistence.swift](https://github.com/kageroumado/refrax-browser/blob/a34ec67fe2ce384e09037f92227de224d3631c98/Refrax/Core/Managers/Tabs/TabManager+Persistence.swift)
- **S** Space lock path. [Refrax/Core/Managers/Tabs/SpaceLockManager.swift](https://github.com/kageroumado/refrax-browser/blob/a34ec67fe2ce384e09037f92227de224d3631c98/Refrax/Core/Managers/Tabs/SpaceLockManager.swift)
- **S** Keychain credential path. [Refrax/Core/Managers/PasswordsManager.swift](https://github.com/kageroumado/refrax-browser/blob/a34ec67fe2ce384e09037f92227de224d3631c98/Refrax/Core/Managers/PasswordsManager.swift)
- **S** socket and caller checks. [Refrax/Core/Control/RefraxControlHost.swift](https://github.com/kageroumado/refrax-browser/blob/a34ec67fe2ce384e09037f92227de224d3631c98/Refrax/Core/Control/RefraxControlHost.swift)
- **S** client access records. [Refrax/Core/Control/ControlAccessStore.swift](https://github.com/kageroumado/refrax-browser/blob/a34ec67fe2ce384e09037f92227de224d3631c98/Refrax/Core/Control/ControlAccessStore.swift)
- **S** extension mediation. [Refrax/Core/Managers/Extensions/ExtensionManager.swift](https://github.com/kageroumado/refrax-browser/blob/a34ec67fe2ce384e09037f92227de224d3631c98/Refrax/Core/Managers/Extensions/ExtensionManager.swift)

**U.** Engine-switch website-data equivalence, cryptographic meaning of Space lock, release helper isolation and comparative performance were not reproduced.

## Vela

**Source revision:** `55b18a3ad70dbf8838c4acf512230e57368ac2d2`. [Repository](https://github.com/JoSanson/vela) · [Repository-linked releases](https://github.com/JoSanson/vela/releases)

- **D/C** features, extension sample, migration and claims. [README.md](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/README.md)
- **D** project-owned landing page template linked to JoSanson/vela. [site/src/index.html](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/site/src/index.html)
- **D** release change history. [CHANGELOG.md](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/CHANGELOG.md)
- **D** state and process design. [ARCHITECTURE.md](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/ARCHITECTURE.md)
- **S** Electron runtime pin. [apps/desktop/package.json](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/apps/desktop/package.json)
- **S** WebContentsView, lazy creation, sleep and renderer failure. [apps/desktop/src/main/tabs/tabManager.ts](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/apps/desktop/src/main/tabs/tabManager.ts)
- **S** profile partitions. [apps/desktop/src/main/sessions.ts](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/apps/desktop/src/main/sessions.ts)
- **S** native-process prompt coordination. [apps/desktop/src/main/permissions.ts](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/apps/desktop/src/main/permissions.ts)
- **S** download integration. [apps/desktop/src/main/downloads.ts](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/apps/desktop/src/main/downloads.ts)
- **S** importer composition. [apps/desktop/src/main/importer.ts](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/apps/desktop/src/main/importer.ts)
- **D** import and migration workflow. [docs/MIGRATING-FROM-ARC.md](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/docs/MIGRATING-FROM-ARC.md)
- **D/C** extension test coverage and limits. [docs/EXTENSIONS.md](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/docs/EXTENSIONS.md)
- **C** project measurements and method. [docs/BENCHMARK.md](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/docs/BENCHMARK.md)

**U.** The repository-owned site source is attributable. A separate live domain could not be tied to this repository, so the similarly named velabrowser.com was excluded. Full incognito isolation, extension parity and benchmark reproduction remain unverified.

## Vezham local audit

**S.** Repository `vezham-labs/vx-browser`, branch `timeline`, commit `f55619dfef819365dc0073166f430b22e70d8a02`. `origin/timeline` refers to the local tracking ref observed during the audit. The native host, chrome, storage modules, Swift and Playwright suites, and runners were read. [Application delegate](../../../../../apps/browser-macos/Sources/Host/ApplicationDelegate.swift) · [Window controller](../../../../../apps/browser-macos/Sources/Host/MainWindowController.swift) · [Chrome contract](../../../../../apps/browser-macos/Sources/Host/BrowserChromeContract.swift) · [Chrome UI](../../../../../apps/browser-macos/Chrome/src/Browser.tsx) · [Storage runtime](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage) · [Core package](../../../../../qualification/webkit-storage-f0) · [Storage tests](../../../../../apps/browser-macos/StorageRuntime/Tests/StorageModelTests) · [Chrome tests](../../../../../apps/browser-macos/Chrome/tests/shell.spec.ts) · [WS-F5R runner](../../../../../apps/browser-macos/Tools/wsf5r.py)

**D/H.** ADRs and owner authority, implementation plans and chronological reports were used. Evidence from different candidates was kept separate. [ADRs](../../../../decisions) · [Phase 5 plan](../../phase-5-implementation-plan.md) · [WS-F4R](../WS-F4R/README.md) · [WS-F5](../WS-F5/README.md) · [WS-F5R baseline](../WS-F5R/README.md) · [WS-F5R recovery design](../WS-F5R/recovery-design/decision-record.md) · [WS-F5R execution](../WS-F5R/evidence/execution-01/README.md) · [Execution matrix](../WS-F5R/evidence/execution-01/test-matrix.md) · [WS-F2 closeout](../M1/m1-wsf2-closeout.md) · [WS-F3 approval](../WS-F3/approved-decisions.md) · [WS-F3 qualification matrix](../WS-F3/qualification-matrix.md)

## Platform and protocol references

- **D** WebKit website data lifecycle, preconstruction store assignment, content-process callback, user content, inspection and extension configuration. [Website stores](https://developer.apple.com/documentation/webkit/wkwebsitedatastore) · [Nonpersistent store](https://developer.apple.com/documentation/webkit/wkwebsitedatastore/nonpersistent()) · [Termination callback](https://developer.apple.com/documentation/webkit/wknavigationdelegate/webviewwebcontentprocessdidterminate(_:)) · [WKDownload](https://developer.apple.com/documentation/webkit/wkdownload) · [Content blockers](https://webkit.org/blog/3476/content-blockers-first-look/) · [Tracking prevention](https://webkit.org/tracking-prevention/) · [App-bound domains](https://webkit.org/blog/10882/app-bound-domains/) · [Extension configuration](https://developer.apple.com/documentation/webkit/wkwebextensioncontroller/configuration-swift.class) · [Web Inspector opt-in](https://developer.apple.com/documentation/safari-developer-tools/enabling-inspecting-content-in-your-apps)
- **D** Engine-level process, session and site isolation behavior, with product differences retained. [Chromium multiprocess](https://www.chromium.org/developers/design-documents/multi-process-architecture/) · [Chromium site isolation](https://www.chromium.org/developers/design-documents/site-isolation/) · [Firefox process model](https://firefox-source-docs.mozilla.org/dom/ipc/process_model.html) · [Firefox SessionStore utilities](https://firefox-source-docs.mozilla.org/toolkit/components/sessionstore/utils.html)
- **D** Threat classes for authenticated local/remote agent integrations. [MCP security guidance](https://modelcontextprotocol.io/specification/2025-11-25/basic/security_best_practices)

**I.** Workstream sequencing, recommendation categories, complexity/risk ratings and benchmark proposals are this report's design judgments. They do not represent independently verified product outcomes.
