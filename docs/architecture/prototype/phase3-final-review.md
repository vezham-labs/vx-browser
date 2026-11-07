# Vezham Browser Phase 3 final review — 7 November 2026

**Local/public investigation:** completed for the executed scope below.  
**Full Phase 3 acceptance:** open for remaining Phase 3 criteria; final release checks are separately deferred.  
**Engine:** no selection; ADR 0001 remains **Proposed**. No production engine implementation was started.

The requested work was taken through local security/transfer checks, public-page smoke tests, measurements, regression and evidence review. Public-account workflows remain blocked. The user has scheduled developer code signing/notarization and macOS 26 runtime validation for the final release-validation stage. These checks are unverified release conditions and are not current Phase 3 blockers.

## What was verified

- The current recovery-state revision passed **48** existing regression checks: storage seed **12**, fresh-process verify **6**, private-window lifecycle **3**, find/zoom **14**, URL policy **13**. The earlier storage/lifecycle regression also passed **12+6+3** checks. The earlier bounded post-exit scan of **52** WebKit-store files found no synthetic private marker; it excludes OS-managed data outside that directory.
- Previous URL policy **13**, find/zoom **14**, isolated download **5**, upload picker **3**, save panel **3**, and cancellation/navigation **13** checks have retained evidence.
- Expanded two-origin tests exercised a hostile frame, **100 forged/oversized native-channel attempts**, cross-origin redirect/popup behavior, privileged-shaped schemes, multiple selected files, selected folder contents and duplicate cancellation. The page had no native transport to invoke; this is not a future IPC-validator pass.
- Testing exposed a **29-byte incomplete final download**. The prototype now stages payloads in app-owned temporary storage and moves a completed payload to the selected destination. The changed path passed **9/9 executed regression checks**, including error cleanup and exact completed bytes.
- **21/21 public landing-page visits loaded**: three fresh-store repetitions across seven destinations. No login, payment transaction, editor/save workflow, conference room or media grant was used.
- **30 fresh-process AC timing samples** were collected after external power was confirmed. An earlier 30-sample battery run was retained separately. **Ten idle views** remained loaded for **621.18 seconds**.

The latest native permission denial passed **4/4 final-request checks**. OS camera and microphone were temporarily authorized; the origin-labelled Vezham prompt appeared, the assistant explicitly selected Deny, and the page returned NotAllowedError/no stream. On an earlier request the user selected Allow in Vezham's prompt; the denial-only guard returned Deny and the original 3/4 result is retained. After page reload, the separate final request explicitly chose Deny. Both targeted OS resets succeeded after app closure and its build was removed. This verifies native denial, not actual website grants, grant persistence/revocation or separate device cases. [Successful final request](../../../prototype/wkwebview/Evidence/native-permission-20261107T130211Z-native-deny/native-permission-retry-results.json); [initial guarded request](../../../prototype/wkwebview/Evidence/native-permission-20261107T130211Z-native-deny/native-permission-results.json); [cleanup](../../../prototype/wkwebview/Evidence/native-permission-20261107T130211Z-native-deny/permission-cleanup.json).

The raw expanded run remains **24/26**. One failed assertion incorrectly assumed the callback URL stayed at the previous page during a cancelled redirect; the native cancel event was present. The other exposed the real incomplete-file issue. A focused retry retained as **13/30** contains the 9 executed download-regression checks; its 17 unrelated steps were not repeated after a long desktop-control attachment. These raw reports were not rewritten as passed suites. The final recovery-state revision passed the separate 48-check storage/lifecycle/find-zoom/URL-policy regression. Earlier run IDs retain their own source scope.

## Measurements

The 30-sample timing and ten-view RSS observations predate this recovery-state fix and remain historical feasibility evidence. They were not rerun to qualify the changed revision. The final revision has 49 recovery UI checks and 48 existing regression checks, with matching native source hashes.

Host: **MacBookAir10,1, arm64, 8 GiB RAM**, macOS **27.2 (26B123)**. Toolchain: Xcode 27.2, Swift 6.4.2; system WebKit **22625.2.8.11.9**. The app deployment target remains **macOS 26.0**.

| Measured proxy | Samples | Median | p95 | Approved numeric target | Observation |
|---|---:|---:|---:|---:|---|
| WebKit plus first view to ready | 30 | 216.32 ms | 678.70 ms | 2000 ms | Met numerically |
| Warm empty-view constructor | 30 | 4.90 ms | 11.26 ms | 500 ms | Met numerically |
| 1 MB local page DOM-ready | 30 | 18.00 ms | 43.00 ms | 1500 ms | Met numerically |

The 1 MB response size and AC power at both ends were confirmed. The first proxy includes WebKit plus its first view; the second is constructor time and excludes asynchronous renderer readiness. Windows were hidden, other user apps remained active, and OS caches were not flushed. These are bounded numeric observations, not a full product-performance pass.

Host-only idle RSS peaked at **90.16 MiB**; the last available host sample was **20.77 MiB**. The 1.5 GB criterion requires host plus attributable engine processes. 30/30 uniquely attributed single-view content-process terminations recovered; 7 checks per run. Signal-to-result observed p95 upper bound 600.71 ms; callback-to-DOM p95 502.09 ms. Those timings used a hidden automatic-reload fixture before the recovery-state fix. The final revision passed 49/49 checks in actual AppKit windows across Profile A, Profile B and Private: recovery status, no automatic reload, real toolbar Reload, last committed URL, new document identity and unchanged synthetic storage/documents in unaffected windows. Five injected stale navigation callbacks were rejected before and after reload; foreign-view callbacks were also rejected. This tests native callback injection, not arbitrary event scheduling or stale process notifications. A stale-callback defect was fixed with retired-navigation/active-navigation identity checks, view ownership checks, retained committed URL and explicit user reload. Remaining gaps include durable product state, termination during navigation/download/profile switching and broader crash scheduling. A separate AC-powered ten-view run idled 630.01 s, then collected 30 one-second host+12-helper RSS samples. Peak 23.77 MiB against the 1.5 GB target; numeric threshold met. RSS excludes compressed-memory/physical-footprint accounting. This is one idle run with sequential samples, hidden windows and an active desktop. Helper attribution used read-only private Darwin coalition/unique-ID diagnostics, validated against two simultaneous isolated apps with disjoint helper groups. Exact executable paths, process owner and both coalition IDs were checked; unique IDs were rechecked immediately before each targeted signal. The diagnostic stays outside browser source and is not a stable public product API. The initial idle run began on battery and external power was connected during it. Full energy, true OS cold launch, 30-minute account workflows and conferencing metrics remain unverified.

Sample variance (n−1) from the raw records: signal-to-result 18274.25 ms²; callback-to-DOM 11343.51 ms²; aggregate RSS 0.9365 MiB².

The latest bounded crash and memory measurements, guards and cleanup are retained in the [attributed diagnostic summary](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T133031Z-14262/attributed-checks-summary.json) and [30 memory samples](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T133031Z-14262/memory-samples.json). The earlier failed crash report is retained separately: title-based assertions at didFinish failed while the reloaded fixture DOM content was available, so the repeat checks fixture title/content together through the DOM. No failed report was rewritten. The first idle observation was interrupted before acceptance to extend the collector's native-timer wait; its 30 completed crash samples were reused with matching native-source hashes. The final memory observation is a separate fresh-host run.

The final revision passed 49/49 checks in actual AppKit windows across Profile A, Profile B and Private: recovery status, no automatic reload, real toolbar Reload, last committed URL, new document identity and unchanged synthetic storage/documents in unaffected windows. Five injected stale navigation callbacks were rejected before and after reload; foreign-view callbacks were also rejected. This tests native callback injection, not arbitrary event scheduling or stale process notifications. A stale-callback defect was fixed with retired-navigation/active-navigation identity checks, view ownership checks, retained committed URL and explicit user reload. The 30-sample timing and ten-view RSS observations predate this recovery-state fix and remain historical feasibility evidence. They were not rerun to qualify the changed revision. The final revision has 49 recovery UI checks and 48 existing regression checks, with matching native source hashes. [49-check actual-window recovery](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/recovery-ui-results.json); [48-check regression](../../../prototype/wkwebview/Evidence/recovery-regression-20261107T135604Z-15653/regression-summary.json); [bounded post-exit private-marker scan](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/post-exit-private-marker-scan.json).

## Acceptance gates and remaining owners

| # | Gate | Status | Owner | Required next dependency |
|---:|---|---|---|---|
| 1 | Local browsing without cloud connectivity | **Partially Verified** | Product/core engineering | Implement and validate app-owned local state after engine approval. |
| 2 | Persistent profile isolation | **Partially Verified** | QA / platform engineering | Run the macOS 26.0/latest supported 26.x matrix at final release validation; continue current work on macOS 27.2 with a 26.0 build target. |
| 3 | Private-session isolation and cleanup | **Partially Verified** | Core/security engineering | Validate the remaining cleanup scope and future app-owned private state. |
| 4 | Authentication and MFA compatibility | **Blocked** | Product owner / test-account owners | Provide approved test tenants and critical workflows if this restriction is changed. |
| 5 | Browser UI/native bridge isolation | **Partially Verified** | Native/UI security engineering | Validate legitimate and adversarial transport commands when the production bridge exists; absence is not validator acceptance. |
| 6 | Native permissions and revocation | **Partially Verified** | Product/security owner | Native denial is verified. Complete actual website grants, persistence/revocation and independent device cases only within separately authorized scope. |
| 7 | File upload/download security | **Partially Verified** | Native/core security engineering | Validate remaining destination/metadata/lifetime cases before production transfer acceptance. |
| 8 | Find and zoom behavior | **Partially Verified** | Native/UI and core engineering | Validate the complete product UI/history behavior after engine approval. |
| 9 | Crash and content-process recovery | **Partially Verified** | Platform QA / diagnostics owner | Validate in-flight navigation/download/profile-switch crashes, durable state and broader process-callback scheduling; retain host-specific diagnostic limits. |
| 10 | Sandbox and Hardened Runtime compatibility | **Partially Verified** | Platform/security engineering | Complete signing/notarization and minimum-OS validation in the final release-validation stage. |
| 11 | Representative website compatibility | **Partially Verified** | Product owner / compatibility QA | Run approved critical account workflows if the public-only scope changes. |
| 12 | Performance targets | **Partially Verified** | Performance / platform QA | Complete the remaining method-controlled cold-launch, energy, conferencing and product-performance measurements. |
| 13 | Internal distribution feasibility | **Deferred — final release validation** | Release/security engineering | At final release validation, configure Developer ID signing/notarization and validate ADR 0002 distribution requirements. |

The local feature slices have evidence; no whole product gate was promoted to Passed merely because the prototype compiled or a smaller test passed. User-directed deferral/restriction is not compatibility proof or an accepted security exception.

## Boundaries preserved

- Swift + AppKit native host; React + TypeScript + HeroUI v3 remains the future browser chrome; engine-independent core remains the product architecture.
- WKWebView remains Proposed. Chromium/CEF stays evaluation-only. No Aura or production Tamizhi/cloud dependency was added.
- Normal signed entitlements remain App Sandbox, network client and user-selected file access. The audited normal bundle has no media entitlement/purpose string; media entitlements were confined to the separately approved denial test.
- Hardened Runtime stayed enabled. No Gatekeeper, certificate, account or OS protection was weakened. Only the disposable app's attributed WebContent process was terminated in each of the 30 successful recovery samples; the user's other browsers were untouched.
- Internal-only distribution and macOS 26+ remain authoritative. Developer ID code signing/notarization and macOS 26 runtime validation are scheduled for the final release-validation stage. The last inventory reported **0 valid signing identities**; signing setup is a future release dependency rather than a current Phase 3 blocker.

## Evidence

- [Machine-readable gate/owner record](../../../prototype/wkwebview/Evidence/phase3-final-status.json)
- [Expanded local raw run](../../../prototype/wkwebview/Evidence/phase3-local-results-20261107T091800Z-16628.json); [reviewed dispositions](../../../prototype/wkwebview/Evidence/phase3-local-review.json)
- [Focused 9-check regression](../../../prototype/wkwebview/Evidence/download-staging-regression-20261107T092722Z-18980.json); [full incomplete retry](../../../prototype/wkwebview/Evidence/phase3-local-results-20261107T092722Z-18980.json)
- [Final storage seed](../../../prototype/wkwebview/Evidence/isolation-results-20261107T095741Z-23704-seed.json); [verify](../../../prototype/wkwebview/Evidence/isolation-results-20261107T095741Z-23704-verify.json); [lifecycle](../../../prototype/wkwebview/Evidence/window-lifecycle-results-20261107T095741Z-23704.json); [post-exit scan](../../../prototype/wkwebview/Evidence/private-cleanup-scan-20261107T095741Z-23704.json)
- [Public-page observations](../../../prototype/wkwebview/Evidence/measurements-20261107T094114Z-22381/public-sites-results-20261107T094114Z-22381-sites.json)
- [AC timing summary](../../../prototype/wkwebview/Evidence/measurements-20261107T095303Z-23093-AC/AC-measurement-summary.json); [initial timing/idle summary](../../../prototype/wkwebview/Evidence/measurements-20261107T094114Z-22381/measurement-summary.json); [resource samples](../../../prototype/wkwebview/Evidence/measurements-20261107T094114Z-22381/idle-resource-observations.json)
- [Signed normal-bundle audit](../../../prototype/wkwebview/Evidence/measurements-20261107T094114Z-22381/bundle-audit.json); [environment](../../../prototype/wkwebview/Evidence/measurements-20261107T094114Z-22381/environment.json); [system WebKit/toolchain record](../../../prototype/wkwebview/Evidence/phase3-final-environment.json)

**Recommendation:** continue the remaining non-deferred Phase 3 validation in authorized environments. Perform developer code signing/notarization and macOS 26 validation at the final release-validation stage. The evidence package is ready for Phase 4 review, but engine approval still requires the user's explicit decision before Phase 5 production engine work.
