# M0 Foundation Decisions and Module Ownership

Date: 2026-11-07. Scope: authorized M0 native host only. These implementation
choices follow the approved boundary baseline and do not choose a core runtime,
database, production transport, release channel/tool or engine capability policy.

## Native Build Container

Choose a small checked-in Xcode macOS app project with Swift/AppKit sources,
shared scheme, explicit xcconfig files and a development bundle. Alternatives:

- A bare Swift executable plus hand-written bundle assembly would duplicate app
  packaging/build settings and make native ownership less visible in Xcode.
- A Swift package is useful for later pure modules but does not by itself define
  this native macOS application bundle/entitlement configuration.
- XcodeGen/Tuist or a third-party Swift Nx plugin would add a new prerequisite
  not needed for one native target. Existing local Vx generators create web/React
  apps; Nx discovery found no AppKit application generator in the installed set.

Use existing Nx `run-commands` integration for build/audit/launch. The standard
`@nx/workspace:run-commands` generator can add a target to an existing minimal Nx
project, so inspect its source/options and dry-run before applying it. Do not
scaffold a React application, initialize a new repository or add engine modules.

## Native Target and Dependency Direction

| Area                      | M0 implementation                                              | Later boundary, not a created placeholder                         |
| ------------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------- |
| App entry                 | Starts NSApplication and holds its delegate lifetime           | No service login or engine initialization prerequisite            |
| Host lifecycle            | Owns native menu/window and normal termination/reopen behavior | Later host authorization/platform composition stays native        |
| Window controller         | Builds a minimal native window showing Ready                   | No website/content view, privileged React chrome or script bridge |
| Browser core              | Not implemented                                                | Own engine-independent policy/state; runtime/bindings open        |
| Engine adapter            | Not implemented                                                | WK types private; no CEF code or private diagnostic ABI           |
| Browser UI                | Not implemented                                                | React/TypeScript/HeroUI v3 app-owned trust domain                 |
| Storage/platform services | No browser store, filesystem grant, Keychain or device access  | Later scoped native brokers and immutable profile ownership       |

Do not create empty core/adapter/UI packages or generic native dispatch APIs.
The native host is new focused source, not a renamed/copied Phase 3 prototype.

## Build and Protection Configuration

Minimum deployment target is macOS 26.0. Debug uses local ad-hoc signing with
App Sandbox and Hardened Runtime retained, and only the app-sandbox entitlement:
M0 needs no network client/server, media or user-selected-file grant. Release
identity/notarization and actual macOS 26 validation remain final-stage work;
no signing key, team credential or provisioning automation is configured here.

Development build products and derived data stay under ignored app `build/`.
The local driver uses system Xcode, verifies command outcomes and exposes no
website/native bridge. A successful host-only build/launch says nothing about
future browser functionality or minimum-OS runtime compatibility.

## Verification and Open Choices

Use Nx build and bundle-audit targets, inspect minimum OS/signed entitlements and
linked frameworks, then launch and quit through actual native controls. Preserve
new logs in a unique Phase 5 evidence run. No Phase 3 regression is needed.

Core runtime/local store, privileged UI origin/transport, critical account/media
scope, file/permission semantics, release tooling and incident ownership remain
open until the corresponding later milestone. M0 does not pre-approve them or
start M1-M8. Continue the current clean `timeline` branch; no branch switch,
commit, push or release is authorized.
