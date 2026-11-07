# Browser Development

Use the existing `vezham-labs/vx-browser` fork on the selected working branch. Inspect Git status/remotes before edits and preserve user changes. `origin` is the Browser fork; `upstream` is `vezham-labs/vx-fe-kit-starter`. Never silently change branches or rewrite history.

The root package manager/toolchain pin is authoritative. Install existing dependencies with `pnpm install --frozen-lockfile --ignore-scripts` when needed; do not regenerate the lockfile or run unrelated migration/release targets. M0 additionally needs Xcode with the macOS SDK and Swift; record the actual host/runtime when verifying. A newer host plus a 26.0 target is not macOS 26 runtime evidence.

After M0 source is present, use `pnpm nx run browser-macos:build`, then `pnpm nx run browser-macos:audit`. `pnpm nx run browser-macos:launch` opens the local development app and waits for normal quit. Development output stays under the app's ignored `build/` directory. The app is ad-hoc signed, sandboxed and hardened; do not disable Gatekeeper or configure production keys for this workflow.

## Authoritative References

- [Native Host Setup](../../../../apps/browser-macos/README.md)
- [Actual M0 Commands and Outcomes](../../../../docs/architecture/phase-5/reports/M0/README.md)
- [Existing Workspace Development Guidance](../../local-development.md)

[Browser Handbook](../README.md)
