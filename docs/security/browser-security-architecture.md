# Browser Security Architecture

**Status:** Proposed security design; requires implementation review and test evidence  
**Scope:** Internal macOS 26 Tahoe+ browser; React/TypeScript + HeroUI v3; Swift/AppKit; conditionally accepted WKWebView direction; no production Tamizhi integration now; optional Vezham ID/cloud with no local-browsing dependency.

The [owner decision](../architecture/phase-3/owner-approval-decision.md) and [ADR 0001 Stage A/B/C policy](../decisions/0001-browser-engine-strategy.md) permit staged implementation, currently M0 only. ADR 0001 remains Proposed; ADR 0002 remains Accepted. Architecture approval and conditional engine acceptance are not security certification or release passes.

## Trust boundaries

| Boundary                                 | Trust assumption                                                        | Required control                                                                                                  |
| ---------------------------------------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Native host ↔ browser core               | Product code, but each input may be malformed or stale                  | Typed APIs, ownership checks, bounded inputs, least privilege                                                     |
| Browser UI web view ↔ Swift host         | UI bundle is trusted only while its fixed app origin and integrity hold | Dedicated UI surface, fixed origin, allowlisted commands, origin validation, CSP, no arbitrary navigation         |
| Website content ↔ native host/browser UI | Fully untrusted, including frames, redirects, and compromised renderers | No privileged bridge; engine-managed content process; native policy gates                                         |
| Persistent profile ↔ other profiles      | Separate logical browser data domains, not separate OS accounts         | Unique engine store IDs and app data namespaces; test all storage classes and concurrency                         |
| Private session ↔ persistent state       | Ephemeral session with no persistence or sync                           | Non-persistent store; separate app state; cleanup and non-sync tests                                              |
| Browser ↔ Tamizhi                        | Page content is untrusted data and may contain adversarial instructions | Explicit consent, scoped extraction, prompt-injection-resistant instruction hierarchy, no direct privileged tools |
| Device ↔ Vezham cloud                    | Optional authenticated external service                                 | TLS, scoped short-lived tokens, Keychain, authorization, revocation, explicit sync controls                       |
| Build/release ↔ installed app            | Release pipeline and signing keys are high-value                        | Controlled CI, dependency pinning, signing separation, notarization, signed update metadata, revocation           |

The renderer must be assumed compromisable. A WebKit content process boundary is not a guarantee against engine compromise. App-managed WKWebsiteDataStore separation is a storage mechanism requiring validation, not a claim of complete profile isolation or separate OS identities.

## Native bridge policy

The React UI may send only versioned, allowlisted commands. Swift verifies fixed UI origin, schema, payload size, enum/range constraints, active window/profile/view ownership, user gesture where required, and policy authorization. Events are minimized and typed. Reject unknown commands, stale IDs, messages from website origins, top-level website frames, and subframes. Never expose arbitrary selectors, generic RPC, native object references, secrets, filesystem paths, or engine handles. Treat UI XSS as privileged compromise: use a restrictive CSP, bundle dependencies, avoid unsafe HTML, and review UI dependencies.

Website JavaScript has no browser-native bridge. If page JavaScript evaluation is required by a user-facing feature, it is page-scoped and disabled by default, cannot access native credentials or browser chrome, accepts structured input without source interpolation, and is gated by a short-lived purpose-bound permission. Prefer APIs that do not require page script injection.

## Profiles, private browsing, and credentials

Assign immutable profile IDs. Bind engine storage, history, bookmarks, permissions, downloads metadata, and sync records to the selected profile. Validate WKWebsiteDataStore persistent stores by identifier and in-memory stores on macOS 26 across cookies, local storage, IndexedDB, service workers, caches, concurrent web views, deletion, and process termination. Do not infer complete isolation from distinct identifiers alone. Deny implicit cross-profile window creation.

Private browsing uses non-persistent website storage and ephemeral app state. Do not persist or sync private history, cookies, downloads metadata beyond operational completion state, Tamizhi page content, or permission grants. On session end, dispose views, clear transient app state, and validate the non-persistent store is released. Document unavoidable OS/engine crash artifacts if any arise during testing.

Store Vezham ID refresh/access credentials and sync cryptographic material in Keychain with appropriate access controls and access group. Keep website passwords under engine/browser-managed secure storage only if explicitly designed and audited; never read them into browser UI or Tamizhi. Do not log tokens, cookies, authorization headers, page bodies, or file contents.

## Permissions and file transfer

Permission decisions are keyed by profile, requesting origin, top-level origin where available, type, and expiry. Unknown/unmapped permission requests default-deny. Present origin-specific prompts, distinguish one-time and persistent choices, and provide revocation. App policy and macOS TCC authorization are both required for protected hardware. Revoke grants at the browser layer immediately and test OS-level behavior.

Downloads require explicit destination policy, normalized filenames, collision handling, cancellation, origin display, and profile association. Use native save panels and user-authorized URLs; do not auto-open files. Uploads use native open panels and disclose files only after user selection, honoring site request and cancellation. Test malicious names, archive traversal, multiple selection, symlinks, type mismatches, and interrupted operations. Preserve platform quarantine behavior where applicable.

## Tamizhi

Tamizhi is future/phased and optional; production integration is outside the current Phase 5 foundation. The following requirements apply before any separately approved future feature is enabled. Each feature that sends page-derived information requires a clear user action and disclosure of the selected source (selection, visible page, or explicitly approved page scope), destination, and whether processing is on-device or remote. Minimize collection; exclude browser chrome, cookies, credentials, password fields, hidden form values, unrelated tabs, and private-session data by default.

Treat page content as untrusted quoted data, never as system instructions. The model receives no native bridge, file access, credential retrieval, profile switching, or cloud-sync tools. Tool authorization remains in the host and is evaluated independently of model output. Confirm actions that navigate, download, upload, or share data. Test prompt injection in visible text, hidden text, image OCR, metadata, and cross-origin frames. Record only the minimum consent/audit event and avoid storing raw page content unless the feature explicitly requires it and retention is disclosed.

## Cloud identity and sync

Vezham ID and sync are optional; local browsing works offline. Use TLS, short-lived scoped tokens, server-side object authorization, device/session revocation, replay protection, and rate limits. Keep tokens in Keychain and out of website contexts, logs, URLs, and analytics. Sync only explicitly selected product data; cookies, passwords, auth sessions, private data, and Tamizhi extracts are excluded by default. Define encryption, key recovery, export/deletion, retention, and account takeover response before enabling sync.

## App, dependencies, telemetry, and incident response

Sign with Developer ID Application and notarize each internal release. Use minimal App Sandbox entitlements and hardened-runtime exceptions; review each against the selected adapter. Test actual sandbox behavior rather than treating entitlements as proof of renderer safety. If CEF is evaluated later, separately prove helper roles, sandbox activation, per-process entitlements, nested signatures, and patch cadence.

Pin dependencies, maintain an inventory/SBOM and license notices, scan for known vulnerabilities, review update provenance, and define a security update SLA. Protect signing and update keys; require controlled approvals, audit use, and documented rotation/revocation. Update metadata and payload digest verification are mandatory; see [distribution architecture](../architecture/browser-distribution.md).

Logs and crash reports must redact tokens, cookies, URLs with sensitive query parameters, page text, form values, file paths, and private profile identifiers. Prefer coarse error codes and opt-in diagnostics with reviewable payload preview. Crash recovery restores only the affected view/profile and must not copy transient private state into persistent recovery storage.

Incident response must support halting rollout, revoking signed release metadata/artifacts, minimum-version enforcement, publishing a fixed build, rotating compromised credentials, and notifying internal users through an authenticated channel. Preserve evidence without collecting browsing content unnecessarily.

## Remaining risks

Engine zero-days, same-user malware, browser UI XSS, WebKit storage edge cases, OS-level process behavior, permission API coverage, prompt injection, cloud account compromise, and signing-key compromise remain residual risks. Acceptance criteria in [security acceptance criteria](browser-security-acceptance-criteria.md) require behavior-specific implementation and final-release evidence at their applicable stage; historical prototype evidence is not a current product pass. This document is not a security certification.
