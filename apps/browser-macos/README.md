# Browser macOS Host — M0

This is a new Swift/AppKit application foundation in the existing Browser fork.
It owns only application lifetime, a native window and normal quit/reopen policy.
It contains no WKWebView, browser core/store, React UI, bridge, profiles,
permissions, transfers, optional services or CEF implementation.

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
`build/bundle-audit.json`. Capture run-specific review evidence separately.
Debug is ad-hoc signed with App Sandbox/Hardened Runtime and only the sandbox
entitlement. No network, media or user-selected-file grant is needed. Release
signing is deliberately unconfigured; no keys/provisioning or release artifact
are prepared. A newer host build with minimum target 26.0 is not runtime evidence
for macOS 26 or notarization/distribution qualification.

## Ownership and Evidence

- [M0 Decisions and Alternatives](../../docs/architecture/phase-5/reports/M0/m0-foundation-decisions.md)
- [M0 Report](../../docs/architecture/phase-5/reports/M0/README.md)
- [Browser Handbook](../../vx/handbooks/browser/README.md)

Stop after M0. Core/engine/React integration belongs to later separately scoped
milestones; do not turn the preserved Phase 3 prototype into this application.
