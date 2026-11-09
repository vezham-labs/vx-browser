# Browser macOS Host

The Swift/AppKit foundation consumes the native storage runtime through the existing
Domain/Ports/Core boundaries. WS-F2 connects the protected-catalog gate, native
Keychain adapter, permission policy and lifecycle security without automatically
creating a website store/view/key. The foundation window reports protected storage
unavailable while D2A-01/signing/key gates are unresolved. No React chrome, privileged
website bridge, CEF or optional service is wired.

## Local Commands

Use the repository-pinned Node/pnpm dependencies and a selected Xcode with the
macOS SDK. From the workspace root:

```sh
pnpm nx run browser-macos:build
pnpm nx run browser-macos:audit
pnpm nx run browser-macos:launch
```

The launch target waits until normal quit. Build/audit do not open the app.
A restricted command sandbox may prevent LaunchServices access (`-10827`); use an
authorized normal local terminal rather than changing app/OS protections. See the
M0 report for the failed sandboxed attempt and successful authorized retry.
Development output is ignored under `build/DerivedData`; audit writes
`build/wsf1-bundle-audit.json`; the historical M0 audit is not overwritten.
Capture run-specific review evidence separately.
Debug is ad-hoc signed with App Sandbox/Hardened Runtime and outbound network-client
entitlement. No media or user-selected-file entitlement is added. Release
signing is deliberately unconfigured; no keys/provisioning or release artifact
are prepared. A newer host build with minimum target 26.0 is not runtime evidence
for macOS 26 or notarization/distribution qualification.

## Ownership and Evidence

- [M0 Decisions and Alternatives](../../docs/architecture/phase-5/reports/M0/m0-foundation-decisions.md)
- [M0 Report](../../docs/architecture/phase-5/reports/M0/README.md)
- [Browser Handbook](../../vx/handbooks/browser/README.md)

## WS-F1 integration and qualification

[Runtime package](StorageRuntime/README.md) and [WS-F1 closeout](../../docs/architecture/phase-5/reports/M1/m1-wsf1-closeout.md)
describe implemented code and remaining gates. `storage-models`, `storage-build`,
`storage-diagnostic-build` and `storage-native` Nx targets take `--evidence` pointing
to a registered run. Native execution also requires exact build/diagnostic result
records; qualification mode is explicit and Debug-only. `--phase=persistent-lifecycle`
records a separate independent subset without waiving private failures;
`--phase=private-only` uses only nonpersistent stores. See the plan for resume rules.

Native discovery on27.2 is not mandatory26.0/latest26.x qualification or release
approval. Preserve the Phase3 prototype and all historical evidence; do not use a
normal user profile as a fixture. No further product milestone starts implicitly.

## WS-F2 storage and security

[WS-F2 closeout](../../docs/architecture/phase-5/reports/M1/m1-wsf2-closeout.md)
links the current architecture, gate ledger, qualification evidence and remaining
decisions. Use `storage-f2-build`, `storage-f2-contracts`, `storage-f2-native` and
`storage-f2-webkit` with a new registered `--evidence` directory. Native F2 targets
require the exact `--build-record` from that build. The Debug-only
`--wsf2-qualification` host uses synthetic data, actual WebKit/Security/CryptoKit,
bounded child processes and a controlled loopback origin. No SQLCipher open or
runtime provider test is permitted through these targets while D2A-01 is unresolved.

Primary WS-F2 qualification is27.2/arm64. The requested release backlog retains
actual26.0/latest26.x and all signing/notarization/security requirements; public
distribution remains unauthorized. A successful bounded test process does not
override blocked Keychain, catalog, unlock, native grants or production-backup gates.
