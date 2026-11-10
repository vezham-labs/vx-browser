# Release preparation and remaining gates

**WS-F8 is incomplete. No real Developer ID signed candidate, notarization, distribution or signed runtime acceptance was produced.**

Date: 2026-11-10. Branch: `cross-browser-research`. Initial HEAD: `9472b17`; initial checkout clean (0 staged, 0 unstaged, 0 untracked). No commit, push, merge or PR. Host: macOS 27.2 (26B123), arm64; Xcode 27.2 (27B52); Go 1.19.6. Application minimum remains macOS 26.0.

## Implemented and observed

`Config/Release.xcconfig` now explicitly requires `Developer ID Application` and `CODE_SIGNING_REQUIRED = YES`. It inherits macOS 26.0, manual signing, App Sandbox, Hardened Runtime and the existing bounded entitlement file from Base. Team/identity material must be supplied externally. Debug remains ad-hoc. Resolved Release settings were recorded; development team is empty and identity inventory has zero valid entries.

The actual Release scheme built successfully with the explicit structural-only override `CODE_SIGNING_ALLOWED=NO`. After the shell repair it was rebuilt successfully. This is an unsigned structural candidate, not a release candidate. Development build and existing bundle audit passed; the audit verifies a development signature and must not be interpreted as release acceptance. Go preflight reports the ad-hoc development candidate Blocked, and rejects the unsigned Release artifact (exit 1, failed signature/entitlement checks). These expected non-acceptance outcomes are preserved, not softened into signing passes.

The new Go preflight inspects resolved Info.plist values, executable presence, strict/deep code seal, Developer ID signature metadata, Hardened Runtime, selected signed entitlement requirements and a stapled ticket. It explicitly leaves signed runtime qualification unexecuted. It has no signing, notarization, upload or launch mutation. Existing `native_host.py` remains the build/audit entry; no Python runtime was added to the app. Existing `.github/workflows/release.yml` is npm release automation on Ubuntu, not macOS browser distribution automation; it was not repurposed or triggered.

## Reproducible preparation and completion runbook

From repository root, build chrome using the existing target:

```sh
npm exec --offline -- nx run browser-macos:build
```

The recorded structural Release build command is in [commands](../developer-tooling/commands-and-results.md). It selects the existing Xcode project/scheme, Release, arm64, an isolated DerivedData directory and `CODE_SIGNING_ALLOWED=NO`. That override must not be used for signing qualification.

For a real candidate, supply an authorized Developer ID identity and matching `DEVELOPMENT_TEAM` through local release configuration, use the Release scheme without the unsigned override, inspect nested code and signed entitlements, then run the Go preflight against that exact bundle. Qualify positive data-protection Keychain creation/reacquisition/user presence/revocation/restart using disposable items before relying on protected state. Never copy a test key or alter Keychain policy to obtain a pass.

Packaging must preserve the signed bundle; record its complete resource/binary hashes, build settings and code identity. Use the authorized Apple notarization account/profile and the organization's approved internal distribution packaging. Verify submission outcome and staple/validate the exact package/app. No credentials or credential values belong in commands, reports or evidence. Validate Gatekeeper and clean install on macOS 26.0 and latest supported 26.x, then qualify startup, workspace relaunch, private/Mini exclusions, nested code, permissions, upgrade/rollback and tamper rejection. The current macOS 27.2 host does not satisfy that OS matrix.

No package/installer, updater, Apple submission, signed runtime test or distribution occurred. Provisioning/access-group needs must be resolved for the actual selected team/app capability set; this report invents none. The missing signing prerequisites do not resolve the still-unimplemented protected provider writer or native shell migration.

[Exact commands and outcomes](../developer-tooling/commands-and-results.md) · [Evidence](../developer-tooling/evidence/safe-foundation-01/) · [Combined report](../developer-tooling/implementation-report.md)
