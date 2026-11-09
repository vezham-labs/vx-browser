# Implementation files and validation receipt

The baseline branch is `cross-browser-research` at `fef74f0b451e084bd33e13b4867c91694bf5bc90`. No commits, pushes, merges, branch changes or PR creation are part of this execution.

## Application and test files

- [apps/browser-macos/Chrome/src/Browser.tsx](../../../../../apps/browser-macos/Chrome/src/Browser.tsx)
- [apps/browser-macos/Chrome/src/bridge.ts](../../../../../apps/browser-macos/Chrome/src/bridge.ts)
- [apps/browser-macos/Chrome/tests/shell.spec.ts](../../../../../apps/browser-macos/Chrome/tests/shell.spec.ts)
- [apps/browser-macos/Sources/Host/ApplicationDelegate.swift](../../../../../apps/browser-macos/Sources/Host/ApplicationDelegate.swift)
- [apps/browser-macos/Sources/Host/BrowserChromeContract.swift](../../../../../apps/browser-macos/Sources/Host/BrowserChromeContract.swift)
- [apps/browser-macos/Sources/Host/MainWindowController.swift](../../../../../apps/browser-macos/Sources/Host/MainWindowController.swift)
- [apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeWebKitStorage.swift](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeWebKitStorage.swift)
- [apps/browser-macos/Tools/wsf6.py](../../../../../apps/browser-macos/Tools/wsf6.py)
- [qualification/webkit-storage-f0/Sources/BrowserDomain/Identity.swift](../../../../../qualification/webkit-storage-f0/Sources/BrowserDomain/Identity.swift)
- [qualification/webkit-storage-f0/Sources/BrowserDomain/WorkspaceLayout.swift](../../../../../qualification/webkit-storage-f0/Sources/BrowserDomain/WorkspaceLayout.swift)
- [qualification/webkit-storage-f0/Tests/WSF0Tests/WorkspaceLayoutTests.swift](../../../../../qualification/webkit-storage-f0/Tests/WSF0Tests/WorkspaceLayoutTests.swift)

## Architecture and implementation records

All thirteen original WS-F6 reports carry a dated implementation update and retain the original design scope for traceability. ADRs 0006–0008 record scoped acceptance and the resolved retention, handoff and recovery choices. ADRs 0001–0005 retain their original bytes.

- [README.md](README.md)
- [current-state-assessment.md](current-state-assessment.md)
- [implementation-files.md](implementation-files.md)
- [implementation-plan.md](implementation-plan.md)
- [implementation-qualification.md](implementation-qualification.md)
- [implementation-report.md](implementation-report.md)
- [main-chat-handoff.md](main-chat-handoff.md)
- [persistence-and-recovery.md](persistence-and-recovery.md)
- [product-direction.md](product-direction.md)
- [qualification-matrix.md](qualification-matrix.md)
- [risk-register.md](risk-register.md)
- [split-screen-and-mini.md](split-screen-and-mini.md)
- [traceability-matrix.md](traceability-matrix.md)
- [webkit-admission-and-lifecycle.md](webkit-admission-and-lifecycle.md)
- [workspace-architecture.md](workspace-architecture.md)
- [workspace-data-model.md](workspace-data-model.md)
- [0006-workspace-identity-and-versioned-layout.md](../../../../decisions/0006-workspace-identity-and-versioned-layout.md)
- [0007-logical-tabs-and-webkit-admission.md](../../../../decisions/0007-logical-tabs-and-webkit-admission.md)
- [0008-mini-isolation-and-url-handoff.md](../../../../decisions/0008-mini-isolation-and-url-handoff.md)

## Evidence and preservation

The [integration receipt](evidence/implementation-01/integration-verification.json) records branch, HEAD, unstaged file counts, installed source identity and historical evidence verification.

Fresh records live under `evidence/implementation-01/`. The [artifact inventory](evidence/implementation-01/artifact-inventory.json) lists every evidence file and hash. Its [checksum manifest](evidence/implementation-01/SHA256SUMS) verifies the records. Native runs identify candidate/source hashes before and after execution. The final native suites use identical candidate and source manifests and exit normally.

Before and after integration, verify the original WS-F4R, WS-F5, WS-F5R baseline and execution-01 manifests with 423, 223, 12 and 36 entries respectively, totaling 694 original checksums. Their manifests and artifacts are outside this change.

Validation comprises the 93-test Core suite, 25-test storage suite, 4 navigation tests, 16 chrome stand-ins, final native workspace/recovery runs, native bundle audit, formatting and Python syntax checks. Configured ESLint retains 27 baseline errors; this is explicitly an outstanding repository check. `git diff --check`, new-file whitespace, internal links, source hashes and protected-path diffs are checked during the integration receipt. [Actual results](implementation-report.md) · [40-case ledger](implementation-qualification.md)
