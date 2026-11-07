# Browser MVP Engine Feasibility and Security Acceptance Criteria

**Status:** Maintained staged acceptance requirements. WKWebView is conditionally accepted for MVP planning and implementation; bounded Phase 3 is closed with limitations. No unverified criterion is Passed. Developer signing/notarization and macOS 26 runtime remain mandatory final-release validation.  
**Target:** Internal macOS distribution, minimum macOS 26 Tahoe.  
**Conditional MVP engine:** WKWebView. ADR 0001 remains Proposed; Chromium/CEF stays evaluation-only with no implementation.

This document preserves mandatory implementation/release outcomes under the [owner approval](phase-3/owner-approval-decision.md) and [ADR 0001 Stage A/B/C policy](../decisions/0001-browser-engine-strategy.md). Conditional engine acceptance permits separately scoped implementation, not unconditional production approval. Performance targets were approved on 2026-11-07; other unresolved capabilities/critical subflows require explicit disposition before affected work. Only M0 is currently authorized.

## Architecture boundaries required for every test

| Component                                     | Responsibility and trust level                                                                                                                                       |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| React + TypeScript + HeroUI v3 browser chrome | Trusted app UI for tabs, address bar, prompts, and browser controls. Hosted in an app-owned surface and limited to typed, allowlisted commands/events.               |
| Swift + AppKit native host                    | Owns native windows/views, OS panels, lifecycle, command authorization, and native permission integration. It validates every command and owns native paths/tokens.  |
| Browser core                                  | Engine-independent policy and app-owned state: profiles, durable history, permission policy, download policy, and orchestration.                                     |
| Engine adapter                                | Translates core operations to engine APIs and reports actual engine capabilities. It does not define product policy.                                                 |
| Remote website content                        | Untrusted. Has no privileged native bridge, browser UI access, account token access, or filesystem access beyond explicit user-mediated selection.                   |
| Tamizhi                                       | Separate intelligence layer. Receives page content only through explicit, scoped, disclosed user action; phased and disabled until the data-flow policy is approved. |
| Optional Vezham ID and cloud services         | Opt-in account/sync services. Local browsing and local browser data must remain usable when these services are unavailable or disabled.                              |

The browser UI surface must not navigate to remote websites. The remote page surface must not host the app command handler. The UI-to-native protocol rejects unknown commands, invalid schemas, stale view/profile ownership, oversized input, and requests from the wrong surface.

## Test environment and evidence rules

- Test on Apple Silicon hardware using macOS 26.0 Tahoe and the latest generally available macOS 26.x update at execution time. Record model, memory, OS build, app build, SDK, and engine version.
- Continue feasibility work on macOS 27.2 while compiling for macOS 26.0. Run the macOS 26.0 and latest supported 26.x runtime baseline, plus Developer ID code signing/notarization, at the final release-validation stage. These scheduling deferrals do not establish compatibility or release readiness.
- Use dedicated synthetic/test accounts, test tenants, and banking/payment sandbox accounts. Do not use live payment transactions or include user credentials in reports, logs, screenshots, or traces.
- For each workflow, execute three clean-profile repetitions on each OS build. Mark each expected step pass/fail and attach sanitized evidence, error codes, and reproducible steps. A workflow passes only when all critical steps pass in all repetitions or an accepted, documented limitation is approved.
- Record test date and exact site/service version where observable. Recheck provider changes before using a result as a release claim.
- For WebKit profile, private-mode, bridge, permission, upload/download, and crash gates, any cross-boundary leak or unauthorized action is a hard failure. There is no tolerated leak budget.
- CEF is not required to pass WebKit MVP gates. If WebKit fails a high-priority workflow, document whether it is an app-level fix, an engine limitation, or a product requirement requiring reconsideration.

## Target-site workflow matrix

Each workflow uses an approved test account and covers sign-in, MFA where available, navigation, reload, back/forward, session persistence, and sign-out. Record unsupported browser APIs, failed third-party redirects, pop-up behavior, and any required workarounds.

| Category                | Representative workflow                                                                                                                                               | Pass criteria                                                                                                                                                                                             |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Google Workspace        | Sign in with MFA; open Gmail and Drive; preview and edit a test Doc; upload and download a test file; sign out.                                                       | All listed actions complete without repeated reload loops, broken authentication redirects, or loss of saved test content. The persistent profile retains its intended session; another profile does not. |
| Microsoft 365           | Sign in with MFA; open Outlook and a test Office document; edit/save; exercise a Teams web meeting if that is the chosen supported workflow.                          | Authentication and core document/mail actions complete. Media workflow is separately scored against the conferencing criteria.                                                                            |
| GitHub                  | Sign in with MFA or passkey where the test account supports it; browse a repository; open a pull request; upload/download a test artifact; sign out.                  | Repository and PR workflows function; auth challenge completes; files use the browser’s explicit transfer flow.                                                                                           |
| Figma                   | Sign in; open a test design file; inspect and edit a test object; save; verify media/rendering and keyboard interaction.                                              | Test file loads and saves, key interaction remains usable, and no crash occurs during a 30-minute session.                                                                                                |
| Notion                  | Sign in; open, search, edit, and save a test page; verify reload persistence.                                                                                         | Search and page edits complete and survive reload in the same persistent profile.                                                                                                                         |
| Banking/payment portals | Use at least one approved sandbox portal; complete authentication/MFA and review a test account/payment flow up to the provider sandbox’s safe confirmation boundary. | Sign-in, MFA, navigation, and expected confirmation UI work. No real funds movement. Record biometric/passkey and anti-automation incompatibilities; never bypass portal controls.                        |
| Video conferencing      | Join a test meeting; allow and deny camera/microphone; mute/unmute; leave; test screen sharing only if in MVP scope.                                                  | User-mediated permission prompts and revocation behave as documented; media starts/stops correctly; denial is respected; meeting can be left without a hung view.                                         |
| Vezham applications     | Exercise representative local-first Vezham web apps in a test environment; test signed-out and signed-in paths separately.                                            | Local browsing features work with Vezham ID/cloud endpoints blocked. Optional account-backed features clearly report unavailable state and recover after service restoration.                             |

Minimum compatibility result: all critical workflows above are scored; zero unresolved blocker in the MVP’s approved target set. Product owner must identify which subflows are launch-critical before running the matrix. “Website loaded” alone is not a workflow pass.

## Profile and private-browsing gates

Use a controlled HTTPS fixture that writes unique markers to cookies (including session cookies), localStorage, IndexedDB, and a service worker/cache. Record only synthetic marker values.

1. Create persistent profiles A and B. Sign into the fixture separately and write distinct markers. Verify that neither profile can read the other profile’s cookies, session, local storage, IndexedDB, or service-worker state: **zero cross-profile markers in all reads**.
2. Close and relaunch the app. Each persistent profile retains only its own intended session and storage. The same test is repeated with two simultaneous views per profile.
3. Create a private session backed by non-persistent website data. Confirm cookies and storage are absent after closing all private views and after app quit/relaunch. Private session data is never copied into a persistent store.
4. Verify private visits do not enter normal history, suggestions derived from normal history, Vezham ID, or cloud sync. Required result: **zero private URL or page-data records** in those stores and outbound payloads.
5. Close a private session, then inspect app-owned temporary storage: **zero private session artifacts** remain, excluding documented OS-managed transient data outside app control. Record exact cleanup scope and platform limitations.
6. Open multiple windows assigned to A, B, and private mode. New tabs, popups, downloads, permission decisions, and history events remain bound to the originating or explicitly selected profile. Cross-profile window creation requires an explicit browser UI action.
7. Attempt profile deletion while views/downloads are active. The core refuses deletion until owners close/cancel; it does not silently orphan or delete active data.

If an API or WebKit behavior does not guarantee a cleanup property, report that limitation rather than infer success from UI state. Keep WebKit website stores and Vezham-owned profile state distinct in the report.

## Security and browser-feature gates

### Typed UI/native boundary and remote pages

- Maintain a versioned allowlist of UI commands and event schemas. No generic method invocation, arbitrary JavaScript source, filesystem paths, account tokens, WebKit objects, or CEF objects cross the React/native boundary.
- Exercise each allowed command from the legitimate app-owned UI and verify only the intended operation occurs.
- In an adversarial fixture, try at least 100 malformed, unknown, stale-view, wrong-profile, oversized, wrong-origin, replayed, and page-originated messages. Required: **100% rejected**, no privileged side effect, crash, or sensitive data disclosure.
- Verify remote pages have no message handler or direct native channel. Attempt navigation from the chrome surface to remote origins and from the remote surface to app-owned privileged routes; both are denied.
- Validate production UI CSP, app-origin navigation allowlist, and that web content cannot read browser chrome DOM, address bar text, tabs, or Vezham account state.

### Permissions, uploads, and downloads

- Camera/microphone: test first request, allow once, deny, revoke, reload, and OS TCC denial. An OS-level denial is not overridden by the browser grant.
- Geolocation and other permission kinds: support only when the target macOS SDK exposes a stable, documented decision callback and the workflow passes. Beta or unavailable API is recorded as unsupported/partial; unknown permissions fail closed.
- Uploads: test one file, multiple files, cancellation, directory selection where applicable, and a hostile filename. Only user-selected files are disclosed; cancellation yields no file data; remote-provided strings never select a path.
- Downloads: test save prompt, cancellation, duplicate names, interrupted transfer, and path-traversal-like suggested names. Destination remains within user-selected location; no automatic open/execute occurs; profile and source origin are visible in browser state.

### Find, zoom, history, and crash recovery

- Find: case-sensitive/insensitive, next/previous, wrap, zero results, and stop/clear behavior are exercised on a deterministic fixture. Report match counts only if exact semantics are stable.
- Zoom: set, read, reset, and restore per view/profile as decided; no OS display scaling side effect.
- History: committed top-level navigations enter profile-scoped durable history; failed provisional navigations do not appear as committed visits; private mode writes none. Back/forward session history remains per view.
- Crash: in a test-only harness, terminate a web-content process and verify the host stays alive, surfaces recovery state, rejects stale callbacks, and restores the last committed URL only after user/product policy. No unrelated view/profile state is lost or merged.

### Local browsing and optional services

With public internet available but Vezham ID, cloud, and Tamizhi endpoints blocked or disabled, start the app, visit a public site, create local history/bookmark/profile state, and reopen it. Required: these local browsing actions succeed and **zero requests** are made to Vezham account/cloud/Tamizhi endpoints. When enabled later, each optional service must have explicit consent and a documented data inventory; private-mode records remain excluded.

## Performance and resource gates (targets approved 2026-11-07)

The product owner approved these targets on 2026-11-07. Approval of thresholds is separate from passing them. Run on the same named Apple Silicon test machine, plugged into power, with a documented clean state. Collect 30 samples per measurement and report median, p95, and variance. Initial battery samples are retained separately from the subsequent AC-powered repeat. Hidden-window/active-session timing proxies and host-only resources do not establish the complete performance gate; retain the method and limitations explicitly.

| Measurement                                        |                                      Approved pass target |
| -------------------------------------------------- | --------------------------------------------------------: |
| Browser engine initialization to ready state       |                                               p95 ≤ 2.0 s |
| Empty browser view creation after engine ready     |                                              p95 ≤ 500 ms |
| Local deterministic 1 MB page fixture to DOM-ready |                                               p95 ≤ 1.5 s |
| Ten idle views after 10 minutes on the fixture set | Browser host + attributable engine processes ≤ 1.5 GB RSS |
| Crash recovery to visible error/reload state       |                                               p95 ≤ 2.0 s |

Also record cold app launch, memory during a 30-minute representative site workflow, CPU while idle, energy impact if available, and peak memory during conferencing. Any target miss must include traces and an agreed disposition; do not weaken a target silently.

## Distribution, update, and licensing gates

- Follow accepted ADR 0002: Developer ID Application signing and notarization for internal direct-distribution artifacts, with Gatekeeper enabled. Before a distributable build, decide `.dmg`/`.pkg`, MDM use, updater and signed-metadata design, and validate hardened-runtime flags, App Sandbox, and entitlements. See [distribution architecture](browser-distribution.md) and [security acceptance criteria](../security/browser-security-acceptance-criteria.md).
- For WebKit, record supported macOS 26.x coverage and OS-driven WebKit update regression responsibilities.
- For a future CEF evaluation, pin an exact CEF/Chromium build; measure compressed and installed size; demonstrate helper startup, renderer/GPU process roles, sandbox operation, signing/notarization for the chosen internal channel, clean update/rollback, and security patch cadence.
- Produce an exact third-party license/notice inventory for any packaged Chromium/CEF distribution and review codec/patent and trademark questions before redistribution. WebKit use does not eliminate app dependency licensing obligations.

The broader release, update, and platform security checks are tracked in [browser security acceptance criteria](../security/browser-security-acceptance-criteria.md); this document adds engine-specific feasibility gates and does not supersede them.

## Exit decision record

Developer ID code signing/notarization and macOS 26 runtime checks are scheduled for final release validation, separately from current Phase 3 blockers. Their evidence remains open and mandatory before internal release. This scheduling decision does not approve an engine.

The test report must include each criterion, evidence link/path, pass/fail/blocked status, known limitations, and owner for each remediation. ADR 0001 remains **Proposed**, while its conditional owner decisions are already recorded. The following obligations remain and are sequenced, not waived:

1. The target-site critical set is approved. Performance targets were approved on 2026-11-07; controlled runtime evidence is still required. Authenticated site workflows remain blocked by the product owner's public-pages-only direction.
2. All current-stage hard security/profile gates pass with no cross-profile or private-data leak. The two user-deferred final-stage validations remain mandatory release conditions and are not marked passed in advance.
3. Compatibility and performance outcomes are reviewed against product priorities.
4. Remaining risks, distribution policy, and unsupported capabilities are accepted by the product owner.
5. Preserve the recorded conditional owner decision and a separate formal ADR lifecycle disposition; do not silently mark ADR 0001 Accepted or demand the same three approvals again.

Stage A reviews evidence/risks and critical-workflow scope before affected selection decisions. Stage B validates production implementation and security as features are built. Stage C validates macOS 26.0/latest supported 26.x, signing/notarization, OS protections and the actual candidate before internal release. The current scoped task authorizes M0 foundation only; future milestones and any internal release need separate scope. Account/media restrictions remain. No public distribution is authorized.
