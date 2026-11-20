# Installation and launch — 2026-11-10

**PASS: local development build, installation and initial installed-app launch. PARTIAL: relaunch qualification.**

Branch `cross-browser-research`, starting HEAD `ce2a9fa6a013b2f70f990c50468f27ed22517914`. Work remains uncommitted. No branch switch, commit, push or history change was performed.

The supported Nx `browser-macos:build` produced an arm64 Debug bundle. `browser-macos:audit` passed all 12 static boundary checks: SwiftUI/WebKit linked, sandbox and network-client entitlements, hardened runtime, ad hoc development signature, no legacy web chrome, engine-independent Core and bounded minimum OS 26.0. Host execution is macOS 27.2; this does not qualify a macOS 26 runtime.

Installed app: `/Users/vigneshwaranbhoj/Applications/Vezham Browser Development.app`.

Bundle identifier `internal.vezham.browser.foundation`, version `0.1.0`, build `1`. Executable SHA-256 `fb3f7e308fb1c28d2674268298fb9c1120e8762ce967456da243b55e3e01e12a` matches the built executable. Strict/deep signature verification succeeded. This is an ad hoc Debug app, not a Developer ID release.

The repository provides build/audit/launch targets but no installer or update mechanism. Installation therefore used staged `ditto`, signature/hash validation, and a non-overwriting `mv -n` into the user's Applications directory. The destination was required to be absent; no other installed app was replaced.

CUA launched the exact installed path. Process inspection observed PID 38006 executing that path. Welcome, private browsing, website navigation and sidebar smoke steps succeeded. Other older development instances had separate paths; they were not used as evidence for installed-app launch.

Quit was sent through the installed app. The subsequent process check found the installed executable absent. Reconnection timed out; optional native launch API was unavailable. Therefore restart behavior and preserved preferences after restart remain **NOT VERIFIED**. Private workspace/bookmark restoration is intentionally unavailable; no durable pass is claimed.

[Install receipt](evidence/installation-01/installation.json) · [Bundle inspection](evidence/installation-01/bundle-inspection.json) · [Audit](evidence/installation-01/bundle-audit.json) · [UI witness](evidence/installation-01/installed-ui-observations.json)

## Live Arc follow-up — 2026-11-10

The final UI Preview uses its own Debug bundle identifier. Its installed path, running process, executable hash and clean private restart were verified. [Comparison and evidence](arc-ui-alignment.md).
