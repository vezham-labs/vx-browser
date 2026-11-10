# Verification

macOS 27.2 (26B123), arm64. Xcode 27.2 (27B52). The candidate minimum target is macOS 26.0. No macOS 26 runtime check ran. The read-only remote query used `git ls-remote origin refs/heads/cross-browser-research refs/heads/timeline`. Exact source and candidate hashes are preserved.

The combined preflight retains the signed-runtime result as unexecuted. Automatic review rejected a proposed change to omit that result because it could weaken the release gate. The resulting code retains the check.

The first read-only remote query failed under the restricted network. The authorized repeat matched the local branch. The first final-candidate injected recovery attempt was rejected by its source identity check because a legacy fixture formatting change landed while it ran. The repeated workspace and recovery runs used stable source hashes. Earlier run output remains in this evidence directory.

## baseline-lint

Thirty inherited errors confirmed. Exit 1.

```sh
npm exec --offline -- nx run browser-macos:lint --output-style=static
```

[Invocation and working directory](evidence/baseline-lint.command.json) · [Output](evidence/baseline-lint.stdout.txt)

## quality-final

Four navigation cases and 16 legacy shell cases passed. Lint and typecheck passed. Exit 0.

```sh
npm exec --offline -- nx run-many -t reliability-contracts reliability-typecheck reliability-ui lint --projects browser-macos --parallel=2 --output-style=static
```

[Invocation and working directory](evidence/quality-final.command.json) · [Output](evidence/quality-final.stdout.txt)

## core

96 Swift Core tests passed. Exit 0.

```sh
swift test --package-path qualification/webkit-storage-f0 --scratch-path /private/tmp/vezham-final-core --disable-keychain --disable-netrc --jobs 2 --disable-xctest --enable-swift-testing --no-parallel
```

[Invocation and working directory](evidence/core.command.json) · [Output](evidence/core.stdout.txt)

## storage

27 Swift storage tests passed. Exit 0.

```sh
swift test --package-path apps/browser-macos/StorageRuntime --scratch-path /private/tmp/vezham-final-storage --disable-keychain --disable-netrc --jobs 2 --disable-xctest --enable-swift-testing --no-parallel
```

[Invocation and working directory](evidence/storage.command.json) · [Output](evidence/storage.stdout.txt)

## provider

14 pinned SQLCipher disposable worker cases passed. Exit 0.

```sh
env VEZHAM_SQLCIPHER_PROVIDER=/private/tmp/vx-m1-provider-fixtures-20261108T113403Z/provider-build-1 go test -tags protectedstore -run TestProtectedStore -count=1 -v ./...
```

[Invocation and working directory](evidence/provider.command.json) · [Output](evidence/provider.stdout.txt)

## provider-vet

Tagged Go vet passed. Exit 0.

```sh
go vet -tags protectedstore ./...
```

[Invocation and working directory](evidence/provider-vet.command.json) · [Output](evidence/provider-vet.stdout.txt)

## go-final

11 Go tests and Go vet passed. Exit 0.

```sh
npm exec --offline -- nx run-many -t qualification-tool-tests qualification-tool-vet --projects browser-macos --parallel=2 --output-style=static
```

[Invocation and working directory](evidence/go-final.command.json) · [Output](evidence/go-final.stdout.txt)

## go-build-final

Go qualification executable built. Exit 0.

```sh
go build -o /Users/vigneshwaranbhoj/Documents/Codex/2026-11-10/files-pasted-by-the-user-vezham/work/final-programme/vezham-qualify .
```

[Invocation and working directory](evidence/go-build-final.command.json) · [Output](evidence/go-build-final.stdout.txt)

## debug-final

Final arm64 Debug built successfully. Exit 0.

```sh
env VEZHAM_DERIVED_DATA=/private/tmp/vezham-final-debug npm exec --offline -- nx run browser-macos:build --output-style=static
```

[Invocation and working directory](evidence/debug-final.command.json) · [Output](evidence/debug-final.stdout.txt)

## qualification-final

Final native qualification bundle built successfully. Exit 0.

```sh
env VEZHAM_DERIVED_DATA=/private/tmp/vezham-final-qual npm exec --offline -- nx run browser-macos:build-workspace-qualification --output-style=static
```

[Invocation and working directory](evidence/qualification-final.command.json) · [Output](evidence/qualification-final.stdout.txt)

## unsigned-final

Final unsigned arm64 Release built successfully. Exit 0.

```sh
env VEZHAM_DERIVED_DATA=/private/tmp/vezham-final-release npm exec --offline -- nx run browser-macos:build-unsigned-release --output-style=static
```

[Invocation and working directory](evidence/unsigned-final.command.json) · [Output](evidence/unsigned-final.stdout.txt)

## debug-audit-final

Debug bundle audit passed. Exit 0.

```sh
env VEZHAM_DERIVED_DATA=/private/tmp/vezham-final-debug npm exec --offline -- nx run browser-macos:audit --output-style=static
```

[Invocation and working directory](evidence/debug-audit-final.command.json) · [Output](evidence/debug-audit-final.stdout.txt)

## native-recovery-final

Initial final-candidate recovery run rejected source identity drift from a concurrent legacy fixture edit. Exit 1.

```sh
python3 apps/browser-macos/Tools/wsf6.py --suite recovery --app /private/tmp/vezham-final-qual/Build/Products/Debug/VezhamBrowser.app --evidence /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/build/wsf6-evidence --run-name final-programme-recovery-02
```

[Invocation and working directory](evidence/native-recovery-final.command.json) · [Output](evidence/native-recovery-final.stdout.txt)

## workspace-verified

36 native and seven contract observations passed. Exit 0.

```sh
python3 apps/browser-macos/Tools/wsf6.py --suite workspace --app /private/tmp/vezham-final-qual/Build/Products/Debug/VezhamBrowser.app --evidence /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/build/wsf6-evidence --run-name final-programme-workspace-03
```

[Invocation and working directory](evidence/workspace-verified.command.json) · [Output](evidence/workspace-verified.stdout.txt)

## recovery-verified

34 native and 11 contract observations passed using an injected callback. Exit 0.

```sh
python3 apps/browser-macos/Tools/wsf6.py --suite recovery --app /private/tmp/vezham-final-qual/Build/Products/Debug/VezhamBrowser.app --evidence /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/apps/browser-macos/build/wsf6-evidence --run-name final-programme-recovery-03
```

[Invocation and working directory](evidence/recovery-verified.command.json) · [Output](evidence/recovery-verified.stdout.txt)

## release-structure

Unsigned Release architecture, app identity and native runtime boundaries passed. Exit 0.

```sh
/Users/vigneshwaranbhoj/Documents/Codex/2026-11-10/files-pasted-by-the-user-vezham/work/final-programme/vezham-qualify native-bundle --bundle /private/tmp/vezham-final-release/Build/Products/Release/VezhamBrowser.app
```

[Invocation and working directory](evidence/release-structure.command.json) · [Output](evidence/release-structure.stdout.txt)

## release-preflight

Production preflight correctly rejected the unsigned artifact. Exit 1.

```sh
/Users/vigneshwaranbhoj/Documents/Codex/2026-11-10/files-pasted-by-the-user-vezham/work/final-programme/vezham-qualify production-preflight --bundle /private/tmp/vezham-final-release/Build/Products/Release/VezhamBrowser.app
```

[Invocation and working directory](evidence/release-preflight.command.json) · [Output](evidence/release-preflight.stdout.txt)

## release-settings

Allowlisted resolved release settings recorded. Exit 0.

```sh
xcodebuild -project apps/browser-macos/VezhamBrowser.xcodeproj -scheme VezhamBrowser -configuration Release -destination platform=macOS,arch=arm64 -showBuildSettings
```

[Invocation and working directory](evidence/release-settings.command.json) · [Output](evidence/release-settings.stdout.txt)

## diff-final

Tracked diff passed whitespace validation. Exit 0.

```sh
git diff --check
```

[Invocation and working directory](evidence/diff-final.command.json) · [Output](evidence/diff-final.stdout.txt)

## Evidence boundaries

Verified 1013 historical checksums across seven retained manifests. The workspace matrix validator passed coverage and integrity for 20 blocked records. This is report validation. All 20 product cases remain blocked.

Six live native UI cases passed on the rebuilt Debug candidate. VoiceOver speech and the physical-input matrix remain unexecuted. The fixture preserves all prior assertions and is separate from active app chrome. An earlier Prettier check passed before unrelated formatting churn was removed from two modules. Final verification relies on the unchanged lint rules, typecheck, tests, and the whitespace check for the minimal diff.

[Historical verification](evidence/historical-verification.json) · [Environment](evidence/environment.json) · [Manual UI observations](evidence/manual-ui.json) · [Candidate hashes](evidence/candidate-hashes.json) · [Matrix validator output](evidence/workspace-matrix-validation.json)
