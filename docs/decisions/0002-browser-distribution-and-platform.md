# ADR 0002: Internal distribution and macOS platform baseline

- **Status:** Accepted
- **Date:** 2026-11-07
- **Decision owner:** Vezham Browser product owner
- **Scope:** Initial distribution and platform baseline

## Context

Vezham Browser is an independent macOS-first browser. The product owner has finalized initial deployment as internal-only, with macOS 26 Tahoe as the minimum supported OS. [ADR 0001](0001-browser-engine-strategy.md) retains its Proposed lifecycle status; the later [owner decision](../architecture/phase-3/owner-approval-decision.md) conditionally accepts WKWebView for MVP planning/implementation, not unconditional production/release acceptance. This clarification changes no accepted distribution decision or lifecycle status. The product uses React + TypeScript + HeroUI v3 for browser chrome and Swift + AppKit for the native host. `@vezham/aura` is not ready and is excluded. Local browsing must work without Vezham cloud services.

## Decisions

1. Initial distribution is internal-only. There is no Mac App Store or public distribution in scope.
2. Minimum supported OS is macOS 26 Tahoe.
3. Direct internal distribution uses Developer ID Application signing and notarized `.dmg` or `.pkg` artifacts delivered from a private internal endpoint or authenticated internal portal. MDM deployment is supported where available.
4. Development, QA, and internal production are separate update channels.
5. Release artifacts are immutable and versioned. Update metadata is signed, and clients verify metadata authenticity and artifact integrity before installation.
6. Release operations provide staged rollout, rollout halt, rollback to an approved version, minimum-version enforcement, and release revocation.
7. Signing credentials and update keys are protected, access controlled, audited, and covered by rotation and emergency revocation procedures.
8. Gatekeeper remains enabled. Employees are never asked to bypass macOS security protections.
9. Browser chrome is React + TypeScript + HeroUI v3 hosted by a Swift + AppKit native application. A typed, allowlisted command/event boundary connects UI to native code.
10. The browser core remains engine-independent. WKWebView is the proposed initial adapter subject to ADR 0001 gates. Chromium/CEF is future evaluation only.
11. `@vezham/aura` is not a dependency, placeholder, or implementation assumption.
12. Local browsing works without Vezham ID, Tamizhi, sync, or other cloud services.

## Product decisions and implementation assumptions

The decisions above establish product scope and outcomes. The exact installer format, updater, metadata format, key custody technology, rollout health signals, sandbox entitlements, and signing automation are implementation choices that remain open for design review. No particular update framework is selected here.

The internal distribution decision does not imply that every deployment will use MDM. It also does not establish that an application sandbox configuration has been validated; that remains a security acceptance gate.

## Consequences

### Positive

- A clear OS baseline reduces runtime compatibility matrix.
- Internal channels allow staged validation before employee-wide rollout.
- Signed, immutable artifacts and metadata provide auditable release provenance.
- Local browsing remains resilient to service outages and avoids making cloud identity a startup dependency.

### Costs and risks

- Vezham owns signing, notarization, updater security, release operations, and urgent revocation.
- Internal portal or MDM access must be maintained and authenticated.
- Rollback and minimum-version enforcement require careful coordination to avoid reintroducing vulnerable builds or breaking migrated local data.
- Developer ID credential compromise could affect trust in releases; key protection and response drills are required.

## Open questions

- Should internal deployment offer `.dmg`, `.pkg`, or both?
- Which updater and signed metadata protocol meet rotation, replay defense, channel separation, revocation, rollback, and offline requirements?
- What sandbox and hardened-runtime configuration is compatible with the chosen WKWebView APIs while keeping entitlements minimal?
- What are rollout health thresholds, security update SLA, minimum-version grace period, and incident owners?
- What data migrations are reversible during rollback?

## Related documents

- [Distribution architecture](../architecture/browser-distribution.md)
- [Platform architecture](../architecture/browser-platform-architecture.md)
- [Security architecture](../security/browser-security-architecture.md)
- [Security acceptance criteria](../security/browser-security-acceptance-criteria.md)
- [Engine strategy ADR](0001-browser-engine-strategy.md)
