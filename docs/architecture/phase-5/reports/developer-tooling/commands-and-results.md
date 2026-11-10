# Exact commands and outcomes

Run-specific cwd, environment-relevant command arguments, exit codes and unabridged stdout/stderr are preserved below. The initial Nx run grouped Go tests/vet, navigation, typecheck, UI and lint: 4 targets succeeded and UI/lint failed. Captured terminal logs retain each original target output. Final changed checks were rerun after the recorded fixes.

Core/storage use the existing Swift invocation with isolated scratch/cache paths directly because the historical Nx wrappers require a registered historical evidence destination; no historical destination was reused. Build, UI, navigation, typecheck, lint, audit and Go checks use Nx. Standalone Go evidence and release checks exercise the new CLI itself.

## aggregate-real-ledger

Exit code: `1`. [Command record](evidence/safe-foundation-01/aggregate-real-ledger.command.json).

```sh
/Users/vigneshwaranbhoj/Documents/Codex/2026-11-10/files-pasted-by-the-user-vezham/work/vezham-qualify aggregate-tests --ledger /Users/vigneshwaranbhoj/Documents/Codex/2026-11-10/files-pasted-by-the-user-vezham/work/wsf7-evidence/qualification-ledger.json
```

## bundle-audit-final

Exit code: `0`. [Command record](evidence/safe-foundation-01/bundle-audit-final.command.json).

```sh
npm exec --offline -- nx run browser-macos:audit --output-style=static
```

[Raw stdout](evidence/safe-foundation-01/bundle-audit-final.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/bundle-audit-final.stderr.txt)

## bundle-audit

Exit code: `0`. [Command record](evidence/safe-foundation-01/bundle-audit.command.json).

```sh
npm exec --offline -- nx run browser-macos:audit --output-style=static
```

[Raw stdout](evidence/safe-foundation-01/bundle-audit.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/bundle-audit.stderr.txt)

## core-tests

Exit code: `0`. [Command record](evidence/safe-foundation-01/core-tests.command.json).

```sh
swift test --package-path /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/qualification/webkit-storage-f0 --scratch-path /private/tmp/vezham-f7-core/build --cache-path /private/tmp/vezham-f7-core/cache --config-path /private/tmp/vezham-f7-core/config --security-path /private/tmp/vezham-f7-core/security --disable-keychain --disable-netrc --manifest-cache local --jobs 2 --disable-xctest --enable-swift-testing --no-parallel
```

[Raw stdout](evidence/safe-foundation-01/core-tests.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/core-tests.stderr.txt)

## debug-build-fixed

Exit code: `0`. [Command record](evidence/safe-foundation-01/debug-build-fixed.command.json).

```sh
npm exec --offline -- nx run browser-macos:build --output-style=static
```

[Raw stdout](evidence/safe-foundation-01/debug-build-fixed.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/debug-build-fixed.stderr.txt)

## debug-build

Exit code: `0`. [Command record](evidence/safe-foundation-01/debug-build.command.json).

```sh
npm exec --offline -- nx run browser-macos:build
```

[Raw stdout](evidence/safe-foundation-01/debug-build.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/debug-build.stderr.txt)

## development-preflight

Exit code: `3`. [Command record](evidence/safe-foundation-01/development-preflight.command.json).

```sh
/Users/vigneshwaranbhoj/Documents/Codex/2026-11-10/files-pasted-by-the-user-vezham/work/vezham-qualify release-preflight --bundle /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/build/DerivedData/Build/Products/Debug/VezhamBrowser.app
```

[Raw stdout](evidence/safe-foundation-01/development-preflight.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/development-preflight.stderr.txt)

## final-format

Exit code: `1`. [Command record](evidence/safe-foundation-01/final-format.command.json).

```sh
node_modules/.bin/prettier --check apps/browser-macos/project.json apps/browser-macos/Chrome/vite.config.ts
```

[Raw stdout](evidence/safe-foundation-01/final-format.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/final-format.stderr.txt)

## format-final

Exit code: `0`. [Command record](evidence/safe-foundation-01/format-final.command.json).

```sh
node_modules/.bin/prettier --check apps/browser-macos/project.json apps/browser-macos/Chrome/vite.config.ts eslint.config.mjs
```

[Raw stdout](evidence/safe-foundation-01/format-final.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/format-final.stderr.txt)

## lint-final

Exit code: `1`. [Command record](evidence/safe-foundation-01/lint-final.command.json).

```sh
npm exec --offline -- nx run browser-macos:lint --output-style=static
```

[Raw stdout](evidence/safe-foundation-01/lint-final.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/lint-final.stderr.txt)

## native-recovery

Exit code: `0`. [Command record](evidence/safe-foundation-01/native-recovery.command.json).

```sh
python3 /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/Tools/wsf6.py --suite recovery --app /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/build/wsf7-qualification/VezhamBrowser.app --evidence /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/build/wsf6-evidence --run-name f7-regression-recovery-01
```

[Raw stdout](evidence/safe-foundation-01/native-recovery.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/native-recovery.stderr.txt)

## native-workspace

Exit code: `0`. [Command record](evidence/safe-foundation-01/native-workspace.command.json).

```sh
python3 /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/Tools/wsf6.py --suite workspace --app /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/build/wsf7-qualification/VezhamBrowser.app --evidence /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/build/wsf6-evidence --run-name f7-regression-workspace-01
```

[Raw stdout](evidence/safe-foundation-01/native-workspace.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/native-workspace.stderr.txt)

## nx-checks

Exit code: `1`. [Command record](evidence/safe-foundation-01/nx-checks.command.json).

```sh
npm exec --offline -- nx run-many -t qualification-tool-tests qualification-tool-vet reliability-contracts reliability-typecheck reliability-ui lint --projects browser-macos --parallel=2
```

[Raw stdout](evidence/safe-foundation-01/nx-checks.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/nx-checks.stderr.txt)

## release-settings

Exit code: `0`. [Command record](evidence/safe-foundation-01/release-settings.command.json).

```sh
xcodebuild -project /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/VezhamBrowser.xcodeproj -scheme VezhamBrowser -configuration Release -showBuildSettings
```

[Raw stdout](evidence/safe-foundation-01/release-settings.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/release-settings.stderr.txt)

## release-unsigned-build

Exit code: `0`. [Command record](evidence/safe-foundation-01/release-unsigned-build.command.json).

```sh
xcodebuild -project /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/VezhamBrowser.xcodeproj -scheme VezhamBrowser -configuration Release -destination platform=macOS,arch=arm64 -derivedDataPath /private/tmp/vezham-f7-release build ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO
```

[Raw stdout](evidence/safe-foundation-01/release-unsigned-build.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/release-unsigned-build.stderr.txt)

## release-unsigned-fixed

Exit code: `0`. [Command record](evidence/safe-foundation-01/release-unsigned-fixed.command.json).

```sh
xcodebuild -project /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/VezhamBrowser.xcodeproj -scheme VezhamBrowser -configuration Release -destination platform=macOS,arch=arm64 -derivedDataPath /private/tmp/vezham-f7-release build ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO
```

[Raw stdout](evidence/safe-foundation-01/release-unsigned-fixed.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/release-unsigned-fixed.stderr.txt)

## storage-tests

Exit code: `0`. [Command record](evidence/safe-foundation-01/storage-tests.command.json).

```sh
swift test --package-path /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/StorageRuntime --scratch-path /private/tmp/vezham-f7-storage/build --cache-path /private/tmp/vezham-f7-storage/cache --config-path /private/tmp/vezham-f7-storage/config --security-path /private/tmp/vezham-f7-storage/security --disable-keychain --disable-netrc --manifest-cache local --jobs 2 --disable-xctest --enable-swift-testing --no-parallel
```

[Raw stdout](evidence/safe-foundation-01/storage-tests.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/storage-tests.stderr.txt)

## tooling-final

Exit code: `0`. [Command record](evidence/safe-foundation-01/tooling-final.command.json).

```sh
npm exec --offline -- nx run-many -t qualification-tool-tests qualification-tool-vet --projects browser-macos --parallel=1 --output-style=static
```

[Raw stdout](evidence/safe-foundation-01/tooling-final.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/tooling-final.stderr.txt)

## ui-fixed

Exit code: `0`. [Command record](evidence/safe-foundation-01/ui-fixed.command.json).

```sh
npm exec --offline -- nx run browser-macos:reliability-ui --output-style=static
```

[Raw stdout](evidence/safe-foundation-01/ui-fixed.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/ui-fixed.stderr.txt)

## unsigned-preflight

Exit code: `1`. [Command record](evidence/safe-foundation-01/unsigned-preflight.command.json).

```sh
/Users/vigneshwaranbhoj/Documents/Codex/2026-11-10/files-pasted-by-the-user-vezham/work/vezham-qualify release-preflight --bundle /private/tmp/vezham-f7-release/Build/Products/Release/VezhamBrowser.app
```

[Raw stdout](evidence/safe-foundation-01/unsigned-preflight.stdout.txt) · [Raw stderr](evidence/safe-foundation-01/unsigned-preflight.stderr.txt)

## Result interpretation

- Core 93 and storage 25 tests passed; navigation 4 and typecheck passed in the first grouped Nx run.
- Final Go Nx run passed 8 top-level tests (22 named table subcases plus parent assertions) and vet.
- Initial shell suite failed all 16 cases with the JSX/runtime mismatch; after the Vite fix all 16 passed.
- Initial lint included generated libraries (9,626 errors); final source-only lint retains the original 30 source errors. This remains failed.
- Native workspace: 36 native / 7 contract observations. Injected private recovery: 34 / 11. No actual helper kill or durable relaunch test.
- Debug build/audit, unsigned Release build and final configuration formatting passed.
- Development release preflight blocked (exit 3). Unsigned Release preflight failed (exit 1) as expected; no signed release acceptance.
- The real aggregate ledger fails because retained source lint fails. Its blocked/unexecuted rows remain visible.
- Five historical checksum manifests verify 791 entries. [Full argv and counts](evidence/safe-foundation-01/historical-summary.json).

The first scratch setup attempted a relative path from the wrong working directory; no tests were installed in that attempt and `go test` reported no test files. That setup was corrected before any test pass was claimed. A first checksum invocation was issued before the CLI build completed and did not execute; it was rerun after the binary existed. These setup errors are not test passes. A configuration formatting check initially failed on the added project targets, then passed after formatting.

Initial grouped target commands are available in `nx-terminal-*.txt`, including the full failing UI/lint logs. Native evidence copies retain bytes; `.log` copies have an appended `.txt` suffix to remain trackable, with a filename map. Test logs containing synthetic fixture names do not establish product private-state retention permission.
