# Verification and command record

The final build and test results are listed below. The build and fixture tools ran on macOS 27.2 arm64. The first native runner and audit attempts started before Xcode finished and could not find a complete bundle. Both suites and the audit passed after sequencing build completion first. The first sandboxed build settings query could not access the local Swift cache. A subsequent query captured the allowlisted settings.

## core

96 Swift Core tests passed Exit 0.

```sh
swift test --package-path qualification/webkit-storage-f0 --scratch-path /private/tmp/vezham-programme-core --disable-keychain --disable-netrc --jobs 2 --disable-xctest --enable-swift-testing --no-parallel
```

[Command metadata](evidence/core.command.json)

## storage

25 Swift storage tests passed Exit 0.

```sh
swift test --package-path apps/browser-macos/StorageRuntime --scratch-path /private/tmp/vezham-programme-storage --disable-keychain --disable-netrc --jobs 2 --disable-xctest --enable-swift-testing --no-parallel
```

[Command metadata](evidence/storage.command.json)

## provider-verified

14 encrypted SQLCipher fixture cases passed Exit 0.

```sh
env VEZHAM_SQLCIPHER_PROVIDER=/private/tmp/vx-m1-provider-fixtures-20261108T113403Z/provider-build-1 go test -tags protectedstore -run TestProtectedStore -count=1 -v ./...
```

[Command metadata](evidence/provider-verified.command.json)

## go-final

10 Go tests and vet passed Exit 0.

```sh
npm exec --offline -- nx run-many -t qualification-tool-tests qualification-tool-vet --projects browser-macos --parallel=2 --output-style=static
```

[Command metadata](evidence/go-final.command.json)

## nx-quality

4 navigation and 16 retained Playwright fixture tests passed. Typecheck passed. Lint reports 30 inherited source errors. Exit 1.

```sh
npm exec --offline -- nx run-many -t qualification-tool-tests qualification-tool-vet reliability-contracts reliability-typecheck reliability-ui lint --projects browser-macos --parallel=2 --output-style=static
```

[Command metadata](evidence/nx-quality.command.json)

## dev-final

Debug build passed Exit 0.

```sh
env VEZHAM_DERIVED_DATA=/private/tmp/vezham-programme-dev npm exec --offline -- nx run browser-macos:build --output-style=static
```

[Command metadata](evidence/dev-final.command.json)

## qual-final

Workspace qualification build passed Exit 0.

```sh
env VEZHAM_DERIVED_DATA=/private/tmp/vezham-programme-qual npm exec --offline -- nx run browser-macos:build-workspace-qualification --output-style=static
```

[Command metadata](evidence/qual-final.command.json)

## release-final

Unsigned Release build passed Exit 0.

```sh
env VEZHAM_DERIVED_DATA=/private/tmp/vezham-programme-release npm exec --offline -- nx run browser-macos:build-unsigned-release --output-style=static
```

[Command metadata](evidence/release-final.command.json)

## audit-final

Development bundle audit passed Exit 0.

```sh
env VEZHAM_DERIVED_DATA=/private/tmp/vezham-programme-dev npm exec --offline -- nx run browser-macos:audit --output-style=static
```

[Command metadata](evidence/audit-final.command.json)

## workspace-final

36 native and 7 contract observations passed Exit 0.

```sh
python3 apps/browser-macos/Tools/wsf6.py --suite workspace --app /private/tmp/vezham-programme-qual/Build/Products/Debug/VezhamBrowser.app --evidence /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/build/wsf6-evidence --run-name completion-native-workspace-02
```

[Command metadata](evidence/workspace-final.command.json)

## recovery-final

34 native and 11 contract observations passed with injected termination callback Exit 0.

```sh
python3 apps/browser-macos/Tools/wsf6.py --suite recovery --app /private/tmp/vezham-programme-qual/Build/Products/Debug/VezhamBrowser.app --evidence /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/build/wsf6-evidence --run-name completion-native-recovery-02
```

[Command metadata](evidence/recovery-final.command.json)

## structure-debug

Native bundle gate passed Exit 0.

```sh
/Users/vigneshwaranbhoj/Documents/Codex/2026-11-10/files-pasted-by-the-user-vezham/work/completion/vezham-qualify native-bundle --bundle /private/tmp/vezham-programme-dev/Build/Products/Debug/VezhamBrowser.app
```

[Command metadata](evidence/structure-debug.command.json)

## structure-release

Unsigned native bundle gate passed Exit 0.

```sh
/Users/vigneshwaranbhoj/Documents/Codex/2026-11-10/files-pasted-by-the-user-vezham/work/completion/vezham-qualify native-bundle --bundle /private/tmp/vezham-programme-release/Build/Products/Release/VezhamBrowser.app
```

[Command metadata](evidence/structure-release.command.json)

## preflight-release

Expected signature preflight rejection of unsigned artifact Exit 1.

```sh
/Users/vigneshwaranbhoj/Documents/Codex/2026-11-10/files-pasted-by-the-user-vezham/work/completion/vezham-qualify release-preflight --bundle /private/tmp/vezham-programme-release/Build/Products/Release/VezhamBrowser.app
```

[Command metadata](evidence/preflight-release.command.json)

## identities

Zero valid signing identities Exit 0.

```sh
security find-identity -v -p codesigning
```

[Command metadata](evidence/identities.command.json)

## release-settings-final

Resolved Release signing and sandbox settings recorded Exit 0.

```sh
xcodebuild -project apps/browser-macos/VezhamBrowser.xcodeproj -scheme VezhamBrowser -configuration Release -destination platform=macOS,arch=arm64 -showBuildSettings
```

[Command metadata](evidence/release-settings-final.command.json)

## formatting

Configuration formatting check passed Exit 0.

```sh
node_modules/.bin/prettier --check apps/browser-macos/project.json
```

[Command metadata](evidence/formatting.command.json)


## Evidence boundaries

The legacy Playwright suite exercises the retained web fixture. The native workspace and recovery suites exercise the private-session lifecycle and real WebKit fixtures. Recovery uses an injected termination callback. The manual accessibility record refers to isolated build 02. VoiceOver speech, physical drag/drop, actual WebKit helper termination, supported OS release testing and durable product relaunch remain outstanding.

The Go checksum tool verified 896 historical entries across six manifests. The release bundle gate independently inspected the final unsigned artifact. Production signing, notarization and signed runtime remain blocked or unexecuted. The expected unsigned preflight rejection is recorded separately.

[Historical checks](evidence/historical-checks.json) · [Manual UI observations](evidence/manual-ui.json) · [Candidate hashes](evidence/candidate-hashes.json)
