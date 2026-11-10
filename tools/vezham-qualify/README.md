# Vezham qualification tooling

Development-only Go CLI; standard library only, Go 1.19 or newer. This module is
not a Swift package dependency, Xcode build input, embedded helper, or app resource.
No existing Python runner is replaced. It consolidates checksum checks and
strict result classification while preserving original evidence bytes.

From the repository root:

```sh
npm exec --offline -- nx run browser-macos:qualification-tool-tests
npm exec --offline -- nx run browser-macos:qualification-tool-vet
```

From this module:

```sh
go build -o /tmp/vezham-qualify .
/tmp/vezham-qualify verify-evidence --root ../.. --manifest ../../docs/architecture/phase-5/reports/WS-F6/evidence/implementation-01/SHA256SUMS
/tmp/vezham-qualify aggregate-tests --ledger cases.json
/tmp/vezham-qualify release-preflight --bundle /absolute/path/VezhamBrowser.app
```

Each parsed qualification command emits stable, sorted JSON without timestamps. Exit codes: 0 checks
passed, 1 failed/invalid evidence, 2 usage error, 3 blocked or incomplete checks.
`go run` wraps nonzero child exits; build the binary when testing precise codes.
Flag parsing uses Go's standard flags; flags follow the command. JSON is the sole
report format. Diagnostics omit artifact contents, entitlements and signing IDs.

## Evidence

SHA256SUMS paths are relative to the manifest's directory. The explicit root
bounds allowed references, including symlinks. GNU text/binary SHA256 entries
with spaces in filenames are supported. Escaped GNU filenames, absolute paths,
empty manifests, malformed digests, duplicate normalized paths, directories,
and files outside the root fail closed. Historical manifests are never rewritten.
Verification assumes the local evidence tree is not concurrently mutated by an
adversary; it does not establish provenance, authorship, or runtime correctness.

## Aggregation

Input is a nonempty JSON array containing exactly `id` and `status` per case:

```json
[
  { "id": "example-implemented", "status": "passed" },
  { "id": "example-not-run", "status": "not_executed" }
]
```

Accepted classifications are `passed`, `failed`, `blocked`, `skipped`,
`not_executed`, `not_applicable`. Unknown fields/statuses and duplicate/empty IDs
fail. Blocked, skipped and unexecuted rows prevent an all-passed aggregate.
A not-applicable row is retained as not applicable. Source-suite result mapping
must be explicit and reviewed; this command does not infer results from prose,
exit codes or historical PASS_NATIVE labels. This is an interchange format,
not an automatic parser for every historical suite.

## Release preflight

macOS is required. The tool reads the built Info.plist through platform `plutil`,
checks resolved metadata and an executable, verifies the code seal (including
nested code) with `codesign`, distinguishes Developer ID from ad-hoc signatures,
checks Hardened Runtime, requires sandbox/network-client entitlements, rejects
three dangerous debug/code-loading entitlements, and validates a stapled ticket.
An absent ticket or Developer ID signature is blocked. Invalid bundle/signature
structure is failed. Entitlements are not an exhaustive capability audit.

Signed runtime qualification remains explicitly unexecuted, so preflight alone
can never mark WS-F8 complete. Ticket validation does not replace Gatekeeper,
clean installation, supported-OS execution, positive Keychain tests, packaging,
upgrade/rollback, or distribution authorization. This command never signs,
submits, staples, launches or modifies the supplied application. No signing
credentials are read. Code-sign metadata is inspected using public tools.

Architecture checks and Markdown/ADR validation are deliberately not implemented
as speculative source-string tests. The current runtime architecture inventory
is in `docs/architecture/phase-5/reports/native-ui-alignment/`. Full native UI
migration and production protected storage remain outstanding.

## Native product bundle and storage fixture

Run `vezham-qualify native-bundle --bundle PATH` against the current arm64 Debug or unsigned Release product. Use `release-preflight` to check signature and notarization separately.

From this Go module, set `VEZHAM_SQLCIPHER_PROVIDER` to the retained arm64 provider directory and run `go test -tags protectedstore -run TestProtectedStore -count=1 -v ./...`. The suite verifies both artifact hashes and creates disposable files with synthetic keys. [Programme record](../../docs/architecture/phase-5/reports/completion-programme/README.md).
