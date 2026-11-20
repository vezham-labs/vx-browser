# Remaining blockers

| Requirement | State | Owner and next action |
| --- | --- | --- |
| SQLCipher admission and protected catalog | Blocked at production policy and integration boundary | Product/security to authorize the exact production read fence and scope. Storage engineering to implement the descriptor broker, native key custody handoff, atomic catalog/recovery adapters, profile lifecycle and durable UI mounting. |
| Positive Keychain lifecycle | Blocked by signing environment | Signing owner to provision an authorized app identity and matching team/profile. Verify user presence, isolated group, create/read/reacquire/revoke, negative and restart controls on disposable data. |
| Twenty production workspace cases | Blocked | Storage and QA owners to qualify the signed production path and execute the individual matrix. |
| WebKit helper exit | Not executed | QA to establish safe per-candidate process attribution on an isolated supported OS. |
| VoiceOver and physical input | Not executed | QA to use the native manual checklist on a physical or isolated supported macOS environment. |
| Signed Release and notarization | Blocked | Release owner to supply Developer ID identity and approved notary Keychain profile. Qualify package installation, signing, privacy behavior and runtime on macOS 26. |
| Legacy DOM-only host suites | Not applicable to active native shell | Browser QA to port remaining relevant DOM interactions to native witnesses. The legacy fixture suite runs independently. |

## Arc parity follow-up

Arc 1.172.1 build metadata and documented behavior are available. Exact visual parity, first-run reference comparison, full native accessibility and feature coverage remain open. Persistent profiles, bookmarks, Favorites, history and workspace restore need admitted storage. Downloads, extensions, import/export and multi-window parity require additional implementation. [Full feature matrix](arc-parity-matrix.md) · [External actions](external-authorization-checklist.md)


---

# Installation follow-up blockers — 2026-11-10

1. **Physical drag NOT VERIFIED.** Completed pointer attempts yielded no observable movement; earlier attempts returned noWindowsAvailable. Diagnose native drag source and target routing, then repeat with distinct named URLs. Cross-Space and group/collection drag are not implemented. Model assertions are insufficient.
2. **Arc matched reference unavailable.** Metadata confirms 1.172.1 / 90370; direct UI session previously stopped. All 20 visual states need matched original captures, geometry receipts, overlays and differences. No pixel parity claim is made.
3. **Relaunch NOT VERIFIED.** Installed app quit; CUA reconnection timed out and optional native launch API was unavailable. Manually launch the installed path and confirm welcome/appearance preference retention and absence of previous private tabs/bookmarks. This is not durable restore qualification.
4. **Production persistence NOT IMPLEMENTED / authorization blocked.** Keep WS-F7 boundary, ProtectedCatalog refusal and signed Keychain custody. Approved provider fixtures do not authorize a production descriptor broker, writer or restore integration. No plaintext or unsigned writer fallback was introduced.
5. **Distribution FAIL.** Zero valid local signing identities. Developer ID Application, notarization/stapling and a separate signed runtime security qualification are still required. Development install is not a release.
6. **Product gaps.** Persistent history, downloads, protected profile switching, durable bookmarks/folders and complete nested collection semantics remain unavailable. WebKit does not supply Chromium extension-host parity. Full accessibility speech, OS permissions and real termination scenarios remain manual/native qualification work.

Manual next actions: open `/Users/vigneshwaranbhoj/Applications/Vezham Browser Development.app`; verify the disclosed private-only startup; use distinct test URLs to drag pinned tabs and saved links, Escape a drag, and check each destination and URL. Capture the 20 paired states described in visual-comparison.md from Arc and Vezham at the same dimensions. Provide the approved WS-F7 owner decisions and signing credentials through the intended secure process before production work can qualify. No secret material belongs in these reports.

## Live Arc follow-up — 2026-11-10

Live Arc access is resolved. Matched visual captures, pointer reorder, signing and protected persistence remain open. [Comparison and evidence](arc-ui-alignment.md).
