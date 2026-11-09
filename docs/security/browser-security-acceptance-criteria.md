# Browser Security Acceptance Criteria

**Status:** Required staged implementation and release gates; checklist boxes remain unpassed  
**Platform:** macOS 26 Tahoe and later  
**Test rule:** Record build, OS version, steps, expected/actual results, evidence, and defects for each case. A design statement is not test evidence.

## Decision authority and sequencing

The [owner record](../architecture/phase-3/owner-approval-decision.md) approves bounded Phase 3 closure and architecture, with WKWebView conditionally accepted for MVP planning/implementation. ADR 0001 remains Proposed and ADR 0002 Accepted. [Stage A/B/C](../decisions/0001-browser-engine-strategy.md) sequences these unchanged criteria: bounded evidence/risk decisions before selection, production validation during implementation, candidate qualification before final release. The separately authorized [WS-F2 storage/security milestone](../architecture/phase-5/reports/M1/m1-wsf2-closeout.md) implements bounded native components and records remaining catalog/key/permission/backup failures and blocks; no whole checklist or engine security certification follows from these tests. Account/media restrictions persist. No hard leak/unauthorized-action criterion is waived.

## Platform and release

- [ ] Install and operate on a clean macOS 26 system; unsupported earlier macOS versions are rejected clearly.
- [ ] Verify Developer ID Application signature for the app and all nested code; verify hardened runtime and minimal documented entitlements.
- [ ] Verify notarization status and a clean install/open path with Gatekeeper enabled. No test asks users to bypass macOS security.
- [ ] Tamper with signed update metadata and artifact bytes; updater rejects both before installation.
- [ ] Verify channel separation, staged rollout halt, revoked release rejection, minimum-version enforcement, and safe rollback to an approved version.

## UI and website isolation

- [ ] A website loaded in a content view cannot invoke any browser UI command, enumerate native objects, read browser chrome state, or access app credentials.
- [ ] Bridge rejects arbitrary and unknown commands, malformed/oversized payloads, wrong origins, website top-level frames, subframes, stale IDs, and mismatched profile/view ownership.
- [ ] Browser UI origin cannot navigate to arbitrary remote content while retaining privileged bridge access.
- [ ] Renderer/content-process crash does not expose data to another profile or restore private state into persistent storage.

## Profiles and private browsing

- [ ] With two persistent profiles, cookies, local storage, IndexedDB, service workers, and caches written in one are absent from the other.
- [ ] Test concurrent views sharing and not sharing a profile as specified; validate persistence across relaunch and data deletion.
- [ ] Private browsing uses a non-persistent data store; cookies and storage do not survive session teardown/relaunch and are never included in sync.
- [ ] Private history, page-derived Tamizhi inputs, permission records, and crash recovery state do not enter persistent stores or cloud payloads.
- [ ] Confirm these results for WKWebsiteDataStore on the supported macOS build; do not infer isolation solely from API names or IDs.

## Credentials and permissions

- [ ] Vezham ID credentials are stored in Keychain, inaccessible to page JS and browser UI state inspection, and scoped as intended.
- [ ] Supported new website permission requests default to Ask; unknown/unsupported/ambiguous requests deny/fail closed; prompts show the verified origin and profile. Browser grants do not replace independent native OS authorization.
- [ ] Test grant, one-time grant, denial, expiry, revocation, and OS TCC denial/revocation for each implemented permission type.
- [ ] Verify permission decisions do not leak across profiles or private sessions.

## Downloads and uploads

- [ ] Download destination requires the intended user/native authorization; hostile filenames, path traversal, duplicate names, cancellation, and interrupted transfer remain safe.
- [ ] Downloaded content is not automatically opened; origin/type/status are visible; quarantine behavior is preserved where applicable.
- [ ] Upload uses native selection; cancellation sends no file; only explicitly selected files are exposed to the requesting origin.
- [ ] Validate multi-file and directory behavior, symlink handling, and security-scoped URL lifetime.

## Tamizhi and cloud

- [ ] Tamizhi does not receive page content before explicit consent; consent identifies scope and destination.
- [ ] Prompt-injection pages in visible/hidden text, OCR, metadata, and frames cannot cause unauthorized native actions, disclosure, navigation, or data sharing.
- [ ] Passwords, hidden inputs, cookies, browser chrome, unrelated tabs, and private data are excluded from default extraction.
- [ ] Offline browsing, local history/bookmarks, and local engine operation work while Vezham services are unreachable.
- [ ] Cloud sync is opt-in and excludes cookies, passwords, auth sessions, private data, and Tamizhi extracts by default; revocation and deletion are verified.

## Crash, logs, and compatibility workflows

- [ ] Crash/recovery tests cover renderer termination during navigation, download, profile switch, and private session; no private or cross-profile data leakage occurs.
- [ ] Logs and crash reports redact tokens, cookies, sensitive URL parameters, page text, form values, local file paths, and private profile identifiers.
- [ ] Run workflow compatibility checks on macOS 26 and record results for Google Workspace, Microsoft 365, GitHub, Figma, Notion, banking/payment portals, video conferencing, and Vezham applications.
- [ ] Workflows include sign-in/MFA, navigation, file upload/download, media permissions where relevant, logout, and profile separation. Record site-specific limitations without claiming blanket compatibility.

## Evidence record

For each criterion attach test run ID, app/build hash, OS build, engine version, test data setup, result, artifacts (redacted screenshots/logs where useful), and issue links. Acceptance requires review by engineering and security owners. No criteria are considered passed until evidence is entered and reviewed.

## WS-F2 qualification scope — 2026-11-09

Primary WS-F2 execution is macOS27.2/arm64. The owner deliberately defers actual26.0/latest26.x qualification to the [release backlog](../architecture/phase-5/reports/M1/m1-wsf2-public-release-qualification-backlog.md). This does not pass or waive any checklist, authorize public distribution or change ADR/owner/security status. See [actual results and limits](../architecture/phase-5/reports/M1/m1-wsf2-qualification-results.md); native media denial failed its oracle, geolocation is inconclusive, Keychain creation is entitlement-blocked and D2A-01 remains unresolved.
