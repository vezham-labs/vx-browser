# Browser Distribution Architecture

**Status:** Accepted product and release decisions; implementation details remain to be validated  
**Platform:** macOS 26 Tahoe and later  
**Channel:** Internal-only

## Decisions

- Distribute Vezham Browser only to internal users in the initial scope.
- Support macOS 26 Tahoe and later. Installer and runtime checks must reject unsupported macOS versions with a clear explanation.
- Sign the app with a Developer ID Application identity and notarize every release distributed outside the Mac App Store.
- Deliver a signed `.dmg` or `.pkg` through a private internal release endpoint or authenticated internal portal. Use MDM deployment where available.
- Maintain separate development, QA, and internal production channels with distinct update metadata and eligibility controls.
- Publish immutable, versioned release artifacts. Replacing an artifact in place is prohibited; corrections receive a new version/build and release record.
- Verify signed update metadata and artifact integrity before installation. Bind channel, version, platform, minimum OS, artifact digest, signing identity, and rollout policy into the authenticated release metadata.
- Support staged rollout, rollback to an approved safe version, minimum-version enforcement, and release revocation. Rollback policy must account for data migrations and security fixes; a revoked vulnerable build must not be reinstalled by ordinary rollback.
- Protect Developer ID credentials and update-signing keys in access-controlled signing infrastructure. Separate routine build access from signing authority, audit use, rotate credentials, and document emergency revocation.
- Do not distribute through the Mac App Store or publicly in the initial scope.
- Never disable Gatekeeper or ask employees to bypass macOS security protections.

## Current execution and validation stage

The [owner decision](phase-3/owner-approval-decision.md) conditionally accepts WKWebView and approves the architecture baseline; it does not authorize release. ADR 0001 remains Proposed and ADR 0002 Accepted. M0 establishes a local native foundation only, with no production signing keys, updater infrastructure or internal/public deployment. Developer ID signing/notarization, macOS 26.0/latest supported 26.x and actual release Gatekeeper/sandbox/Hardened Runtime/entitlement verification remain Stage C final-release gates. Planning/implementation of release services later in Stage B must not be mistaken for those passes.

## Release flow

1. CI produces a versioned app artifact from a reviewed source revision and locked dependency set.
2. Release automation inventories nested code, verifies bundle identifiers and entitlements, signs nested code before the containing app, and applies the selected hardened-runtime and sandbox configuration.
3. CI verifies signatures, notarizes the candidate, staples or otherwise delivers notarization status as appropriate, and runs clean-install and launch checks on supported macOS.
4. Release metadata is signed independently of the artifact. Clients validate metadata signature, channel eligibility, OS requirement, artifact digest, and version policy before accepting an update.
5. QA validates a candidate on the QA channel. Internal production rollout begins with a small cohort and expands by measured health thresholds.
6. Operators can halt a rollout, revoke a release, and direct clients to a known-good signed version. A rollback cannot silently downgrade security policy or bypass minimum-version rules.

## Update trust and failure behavior

The updater must fail closed on invalid signatures, digest mismatch, expired/invalid metadata, wrong channel, unsupported OS, or revoked release. It must preserve the installed app if staging fails and report a concise, privacy-safe error. Update payloads and metadata are fetched over authenticated TLS, but TLS alone is not the trust root; cryptographic metadata and artifact verification are required. Define key rotation, recovery, replay protection, metadata expiry, and offline behavior before implementation.

Internal services must authenticate users/devices and authorize channel access. Do not put update secrets in the client. An offline app remains usable for local browsing; optional cloud services and update checks may be unavailable without disabling local browser functions.

## Open implementation decisions

- Select `.dmg`, `.pkg`, or both based on MDM and employee installation workflows.
- Select update framework/protocol only after its metadata-signing, rollback, channel, and revocation behavior has been reviewed.
- Define rollout health signals, cohort sizes, release retention, rollback triggers, and minimum-version grace periods.
- Define signing-key custody, notarization credentials, emergency rotation, and incident roles.
- Validate exact hardened-runtime flags, App Sandbox configuration, and entitlements against WKWebView and the minimum OS.

## Related documents

- [Platform architecture](browser-platform-architecture.md)
- [Security architecture](../security/browser-security-architecture.md)
- [Security acceptance criteria](../security/browser-security-acceptance-criteria.md)
- [ADR 0002](../decisions/0002-browser-distribution-and-platform.md)
