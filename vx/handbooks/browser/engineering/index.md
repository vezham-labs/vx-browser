# Browser Engineering

Use repository coding standards and the focused Nx skills. Native application code is Swift/AppKit; use platform APIs and avoid new dependencies for lifecycle/window functionality. Keep entry point, lifecycle coordination and native window construction focused and separate.

The Nx project is `browser-macos`. Native build/audit/launch targets call the checked-in local driver; JavaScript workspace tooling must not acquire authority over websites or inject a convenience bridge. No React/core/engine implementation is hidden in M0 scaffolding.

Record material choices before implementing them, including alternatives and scope. Open choices stay open. Preserve view/profile ownership, cancellation and capability semantics when later milestones are separately authorized. Do not publish, commit or push from an agent task without explicit authorization.

The [M1 runtime ADR](../../../../docs/decisions/0003-browser-core-runtime-and-language.md) proposes Swift value models and actor coordination; the [implementation breakdown](../../../../docs/architecture/phase-5/reports/M1/m1-implementation-plan.md) separates later domain/store proofs from actual engine/UI work. No package, target, dependency or source change is authorized by the design-only task.

## Authoritative References

- [Repository Coding Standards](../../coding-standards/index.md)
- [Brand and Naming](../../brand.md)
- [M0 Decisions and Module Ownership](../../../../docs/architecture/phase-5/reports/M0/m0-foundation-decisions.md)

[Browser Handbook](../README.md)
