# Qualification plan

Ordered increments: 1) routing and reproducible candidate; 2) pointer-driven drag; 3) lifecycle and recovery; 4) accessibility; 5) public compatibility and platform boundaries; 6) preservation and disposition.

Use an isolated development identity, existing sandbox/Hardened Runtime and no entitlement expansion. Preserve HTTP policy (public HTTPS, loopback HTTP). No accounts, real credentials, user profiles, protected persistence or Keychain qualification. No security warning bypass.

Every case records input, setup, actual assertion, candidate/source identity, platform, raw evidence and outcome. A command exit alone is insufficient for navigation pass. Native pointer/VoiceOver cases require actual OS interaction; JS drag dispatch and stand-in bridge tests cannot substitute. Default routing requires observed handler selection and actual URL delivery, plus restoration verification. Screenshot/AX trees alone do not prove VoiceOver usability. Resource evidence uses bounded repeated operation and weak-reference/native inventories; RSS is diagnostic, not proof of zero leaks.

PASS_NATIVE means observed assertions in actual AppKit/WebKit; PASS_CONTRACT is static or pure contract; PASS_FAKE_ONLY is a stand-in; FAIL means observed contrary behavior; INCONCLUSIVE means attempted but evidence insufficient; NOT_EXECUTED means not attempted; BLOCKED records the dependency. Never aggregate different revisions into a pass rate. Keep failed runs, exact commands, source/binary hashes and final evidence checksums.

Required families: URL cold/warm/macOS Open/default HTTP/default HTTPS/wrapper/malformed/unsupported/main-Mini; DRAG reorder/group/Space/pin/split/cancel/invalid; LIFE windows/views/panes/Mini/focus/failure/recovery/repeated cleanup; AX labels/roles/keyboard/dialog/menu/VoiceOver; COMP public pages/redirects/synthetic auth/target-blank/download denial/isolation; PLATFORM actual host/minimum/latest supported 26.x and release gates.

## Reproduce the scoped development run

From the repository root with its pinned dependencies and selected Xcode, use a new output and evidence run name. The campaign used the local Nx executable directly after the package manager wrapper stalled. Set `VEZHAM_DERIVED_DATA` to the isolated path before build and audit.

```sh
export VEZHAM_DERIVED_DATA="$PWD/apps/browser-macos/build/WSF5/DerivedData"
NX_DAEMON=false node_modules/.bin/nx run browser-macos:build --wsf5-qualification --output-style=static
NX_DAEMON=false node_modules/.bin/nx run browser-macos:audit --output-style=static
python3 apps/browser-macos/Tools/wsf5.py \
  --app "$VEZHAM_DERIVED_DATA/Build/Products/Debug/VezhamBrowser.app" \
  --evidence docs/architecture/phase-5/reports/WS-F5/evidence \
  --run-name REVIEWER-UNIQUE-NAME --attempts 2
```

The native runner uses loopback fixtures and records source, binary and bundle resource hashes before and after. Use its `--serve-only` mode and the isolated bundle's `--wsf5-observe` mode for interactive checks. Use synthetic or public destinations with the observer because it records native navigation state. The final [cold launch command](evidence/final-interactive-open.json) shows output redirection and argument ordering.

For an authorized default-handler test, snapshot both handlers and verify their original bundles are available. Select the isolated app using the compiled probe, confirm actual scheme ownership, deliver fixture HTTP and public HTTPS with plain `open`, and verify rendered native state. Restore both handlers in cleanup and query them again. macOS changed both scheme handlers together in this campaign. Preserve a before/selected/after record. [Probe source](../../../../../apps/browser-macos/Tools/wsf5_handlers.swift) · [Recorded run](evidence/final-default-routing.json)

For drag, use a primary pointer with the three fixture tabs. Verify the exact isolated window, record native order before and after each gesture, and inspect group, Space, pinned, split and selection state. Cancellation and invalid targets must leave relevant state intact. The optional qualification driver requires existing OS input authorization. VoiceOver qualification requires directly observed speech or captions. Review those cases in the [test matrix](test-matrix.md).
