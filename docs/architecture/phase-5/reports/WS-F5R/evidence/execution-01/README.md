# WS-F5R resumed execution

**Recovery implemented and qualified with injected termination callbacks. WS-F5R remains incomplete.** Actual OS content-process termination and helper attribution remain open. This execution report and [updated case matrix](test-matrix.md) are append-only successors to the [committed WS-F5R baseline](../../README.md).

## Review and integration

The interrupted temporary copy existed and the original checkout was clean at `a359ebc5f3ef3656568daa02b51ba0b116ea8538` on `timeline`. The [inventory](interrupted-copy-inventory.json) covers every entry examined without following the dependency symlink. It records 92 unchanged files, eight modified tracked files and 90 additions, including 76 generated files. See the [interrupted diff](interrupted-copy.patch) and the [integrated diff](reviewed.patch). Build output, probe caches and the dependency symlink stayed outside the checkout.

Review found that an owned termination callback could start a second Core retirement while window closure was already awaiting teardown. The reviewed patch keeps the adapter fence but refuses a second retirement after window closure begins. It also rejects late presentation commands during close, preserves a normal close shortcut for an unavailable workspace, and strengthens the fixture continuity assertion to require a distinct committed URL. See the [concurrency review](../../recovery-design/concurrency-and-failure-analysis.md).

## Recovery behavior

The adapter fences and poisons the owning private scope before asking the host to retire it. Scope checks deny old navigation and view lookup. The host detaches surfaces and waits for Core retirement, zero Core views, empty native inventory and revoked authority. An unavailable or uncertain retirement keeps the workspace blocked. A user action consumes the ready state once and creates a new private session via Core registration, resolve, activation and publication.

The layout restores tab order, Spaces, groups, pins, selection and split intent in memory. Each tab uses a new view ID and starts blank. Old URLs and titles are omitted because the existing navigation metadata does not prove a committed request safe to replay. Existing website data, authentication, grants and native WebKit references have no transfer path. The Mini uses its own session and store. [State machine](../../recovery-design/recovery-state-machine.md) · [Isolation analysis](../../recovery-design/storage-isolation-analysis.md)

## Build and tests

The [interrupted build](interrupted-build-01.log) compiled chrome, then Xcode exited 74 while resolving packages. Even with DerivedData in the temporary tree, Clang could not write `~/.cache/clang/ModuleCache` and SwiftPM could not emit `~/Library/Caches/org.swift.swiftpm/manifests/ManifestLoading/storageruntime.dia`. The CoreSimulator log also reported a denied write. Automatic approval review had rejected the prior modified-candidate build on the interpretation that work stopped at the investigation boundary. The resumed, explicitly reviewed [single build command](qualify-build.sh) succeeded with scoped DerivedData, package and module cache paths. [Build log](build-success.log)

- Host macOS 27.2 (26B123), arm64, Xcode 27.2 (27B52), deployment target 26.0. Candidate SHA-256 `c0a80adda8d209d487fe2cab0154466ecb30c3e4c182360a9220ab2eca4849a3`.
- Static Swift syntax, TypeScript type-checking and Python syntax checks passed. Bundle signature and the existing sandbox and network-client entitlements verified. The successful Xcode build and these static checks are separate from the assertion totals. [Signature](candidate-signature.log) · [Entitlements](candidate-entitlements.plist) · [Deployment metadata](candidate-build-version.txt)
- The [callback suite](callback-run-01/summary.json) exited 0 with **35 PASS_NATIVE** observations of actual AppKit/WebKit behavior and **9 PASS_CONTRACT** assertions about injected callbacks and guarded transitions. It covered confirmed retirement, retained-view failure, staged session cleanup when no replacement tabs can be published, fresh stores, cookies and LocalStorage, Main/Mini separation, split reattachment, duplicate recovery, stale identity and close/teardown. The synthetic login redirect, same-scope continuity, Mini isolation and logout passed. The terminal suite marker is excluded from counts.
- The [stand-in browser chrome suite](playwright.log) exited 0 with **14 PASS_FAKE_ONLY**, including two recovery UI regressions.

## Outstanding qualification

A real WebKit termination requires positive helper attribution for the isolated candidate before any signal. Physical primary-button dragging, VoiceOver speech or captions, successful downloads, external accounts, and actual macOS 26 remain open. The owned login fixture exercises synthetic sessions only. Authenticated state across a real recovery and exact provider behavior were outside this run.

The baseline manifests verified all 658 entries after integration. The [preservation record](preservation.json) lists exact files and verifies the 63 native runner inputs against the integrated checkout. Changes remain local and uncommitted on `timeline`. [New artifact checksums](SHA256SUMS)
