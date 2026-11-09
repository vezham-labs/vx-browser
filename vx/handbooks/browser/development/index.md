# Browser Development

Use the existing `vezham-labs/vx-browser` fork on the selected working branch. Inspect Git status/remotes before edits and preserve user changes. `origin` is the Browser fork; `upstream` is `vezham-labs/vx-fe-kit-starter`. Never silently change branches or rewrite history.

The root package manager/toolchain pin is authoritative. Install existing dependencies with `pnpm install --frozen-lockfile --ignore-scripts` when needed; do not regenerate the lockfile or run unrelated migration/release targets. M0 additionally needs Xcode with the macOS SDK and Swift; record the actual host/runtime when verifying. A newer host plus a 26.0 target is not macOS 26 runtime evidence.

## Run the Browser Locally

With the repository-pinned dependencies installed and Xcode selected, build and launch from the repository root:

```sh
cd /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser
pnpm nx run browser-macos:build
pnpm nx run browser-macos:launch
```

The build target bundles the React/TypeScript browser chrome and builds the Swift/AppKit macOS app. The launch target opens the existing development app and waits until you quit it normally; it does not rebuild. On subsequent launches, run only `pnpm nx run browser-macos:launch` unless source has changed.

In the app, choose **Start private session** to browse. Protected profiles are currently unavailable. Session bookmarks, Spaces, groups and pins are temporary.

Optionally inspect the built bundle's static signing, sandbox and resource checks:

```sh
pnpm nx run browser-macos:audit
```

Build and audit do not open the app. The static audit does not qualify runtime behavior or release readiness. Development output stays under `apps/browser-macos/build/`, including the app at `DerivedData/Build/Products/Debug/VezhamBrowser.app`. The development app is ad-hoc signed, sandboxed and hardened; do not disable Gatekeeper or configure production keys for this workflow. If a restricted command sandbox blocks LaunchServices, run the launch command in an authorized local terminal.

## Milestone Scope

The original [M1 design milestone](../../../../docs/architecture/phase-5/reports/M1/README.md) restricted its tasks to documentation review. Those historical restrictions remain part of that milestone's record. Later implementation and qualification work has separate scope and prerequisites; preserve its source and evidence. The local commands above describe the current development app and do not authorize additional milestone or release activities.

## Authoritative References

- [Native Host Setup](../../../../apps/browser-macos/README.md)
- [Actual M0 Commands and Outcomes](../../../../docs/architecture/phase-5/reports/M0/README.md)
- [Existing Workspace Development Guidance](../../local-development.md)

[Browser Handbook](../README.md)
