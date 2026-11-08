# WS-F0 fake website-storage qualification

This isolated Swift6 package implements the authorized fake-only milestone. It is not linked to the native browser host and does not implement a WebKit or database adapter.

## Targets

- BrowserDomain: tagged immutable IDs, persistent/private scopes, bindings, lifecycle/outcome/recovery/diagnostic values.
- BrowserPorts: typed host-authority, catalog, recovery-journal, engine-storage, resource and construction protocols.
- BrowserCore: actor coordinator, explicit construction policy and metadata-only publication gate.
- BrowserPersistence: in-memory qualification catalog and simulated restart journal only. No production storage integration.
- WSF0Fakes: in-memory engine data, deterministic fault queue, controlled continuation gates, view/resource recorder and fake host authority.
- WSF0Tests: deterministic Swift Testing catalog/scope/construction/lifecycle/deletion/restart/diagnostic/integration tests.

No package dependencies or product project references are added. Foundation is used only for UUID value validation and public deterministic fixture formatting. No WebKit/AppKit/Security/SQLite/provider imports, network, filesystem website storage or native-service port implementation is present.

## Verification

Preferred workspace entry point (registered evidence directory required):

```sh
NX_DAEMON=false NX_NO_CLOUD=true pnpm nx run webkit-storage-wsf0:verify --evidence=/absolute/registered/evidence/directory
```

The verified installed-CLI entry point, when the package-manager shim stalls:

```sh
NX_DAEMON=false NX_NO_CLOUD=true NX_ISOLATE_PLUGINS=false node node_modules/nx/dist/bin/nx.js run webkit-storage-wsf0:verify --evidence=/absolute/registered/evidence/directory
```

The identical safe runner entry point, if the Nx launcher is unavailable:

```sh
python3 qualification/webkit-storage-f0/run_wsf0.py --evidence=/absolute/registered/evidence/directory
```

The runner inspects imports/surfaces before building, invokes only this package's Swift tests, disables SwiftPM Keychain/netrc credential discovery, retains SwiftPM's own manifest sandbox and writes build/cache/test outputs into a unique owned temporary directory. Evidence/log files are ordinary qualification artifacts, not filesystem-backed website storage. It never invokes the SQLCipherPhase1 verify target because that builds a provider-linked image outside this milestone's authority. No broad workspace tasks, dependency installation or browser app launch.

## Behavioral scope

A host authority registry must validate caller/run/scope/epoch; an identifier is not a capability. Persistent mapping uniqueness is enforced in the catalog. Private scopes have only ephemeral engine identities and cannot be represented in catalog/restart records. Enumeration and established-store reconciliation do not create stores. Only a recorded fresh provisioning path can request a new fake store; orphan/collision/missing/ambiguous states quarantine.

The coordinator reserves operation identity and a pending checkpoint before awaited effects. It checks current ownership/generation after completions, serializes per-scope work, fences resource acquisition during quiescence/retirement and keeps quarantine sticky. Clear-selected and remove-store have separate results and preconditions; removal retains a deletion tombstone. Partial/unknown/failure outcomes never become success, including after simulated restart. Same-operation/same-payload retries return a retained typed result; changed payload rejects; pending replay returns Busy. A finite128-operation receipt bound stops admission rather than promises unlimited exactly-once behavior.

Last private-view closure initiates fake quiescence/retirement; independent participants can block cleanup. Explicit cleanup may succeed while the scope remains quarantined; it is not permission to activate. Recovery records preserve the interrupted action. A failed memory-journal/quarantine write poisons the exported simulated snapshot so restart cannot mistake an older stable record for successful persistence. This deliberately conservative fake behavior is not real durable crash safety.

Diagnostics are bounded typed events with reserved terminal capacity. They include operation IDs and scope kind, never profile/session IDs, raw errors, URLs, website content, keys, paths or capabilities. Harness inspection APIs for catalog snapshots/fake data/resources are trusted qualification utilities, not proposed UI/native permission endpoints. Fake recorders/fault injection hooks intentionally model adversarial conditions; they provide no production logging/privacy guarantee.

The publication gate checks only immutable metadata membership/generation/privacy epoch, destination conflicts and unknown deletion lineage. It creates no archive, blob, backup, restore or encryption result.

## Limits

Passing fake tests cannot qualify WebKit's copied configuration, origin/cookie semantics, persistent/private data behavior, reference release, process crashes, OS locks, deletion side effects, file protection, opaque backup format, cross-Mac recovery, signing or macOS26 runtime. All40 original WKS definitions and50 SQLCipher PQR definitions remain historical inputs. The separate WS-F0 disposition report labels only bounded fake contributions; no native case is promoted to fully qualified.
