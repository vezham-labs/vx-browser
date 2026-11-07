# Phase 3 exit review

**Date:** 2026-11-07. **Primary exit review for the Phase 4 decision packet.**

**Owner decision, 2026-11-07:** **Phase 3 closure — APPROVED**, as a bounded feasibility investigation with its recorded limitations. **WKWebView — CONDITIONAL ACCEPTANCE for MVP planning and implementation. Architecture baseline — APPROVED.** See [owner-approval-decision.md](owner-approval-decision.md) for the exact authority, conditions and Phase 4.2 consistency record.

Closure does not establish complete browser/security/compatibility/performance/release readiness. The conditional engine decision is not unconditional production-engine approval. ADR 0001 remains **Proposed**; Chromium/CEF remains evaluation-only; Aura is excluded; no public distribution is authorized. This update records approvals and prepares Phase 5 only: no prototype launch, rebuild, test rerun or production implementation.

## Scope, authority and preserved state

The investigation was an isolated Swift/AppKit + WKWebView prototype, synthetic loopback fixtures, public-page smoke visits, diagnostics and documentation. Authoritative decisions remain macOS **26.0 minimum**, internal-only distribution, Swift/AppKit host, future React + TypeScript + HeroUI v3 chrome and an engine-independent browser core. `@vezham/aura` is excluded including placeholders. Tamizhi and optional Vezham identity/cloud are not production browsing dependencies. Accepted [ADR 0002](../../decisions/0002-browser-distribution-and-platform.md) remains unchanged.

The user limited external testing to public pages and scheduled macOS 26 runtime and Developer ID signing/notarization at final release validation. These restrictions are not test passes or security exceptions. No later approval of targets, temporary OS media access, or a test retry is engine approval.

This milestone preserves the entire prototype/evidence tree, existing source manifests, historical reports and review archives. The original Phase 4 preparation created five review documents and updated ADR 0001; Phase 4.2 adds the owner decision and Phase 5 planning documents and updates current approval/status pointers only. Historical evidence and acceptance-gate classifications remain unchanged. A preservation hash comparison is a documentation integrity check, not a rerun of prototype tests. The preserved manifest SHA-256 is `df99e29f5c51f453a8a4c31cc20485d1860edb095f317717682e645adf99da4a` ([E12](../../../prototype/wkwebview/Evidence/phase3-source-manifest.json)).

## Primary recovery revision: keep the two suites separate

| Suite | Original run | Outcome | Provenance and practical limit |
|---|---|---|---|
| Actual-window recovery | `20261107T135156Z-15341` | **49/49 checks; zero recorded failures** | [E01](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/recovery-ui-results.json), [E03](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/source-hashes.json), [E05](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/computer-use-observation.json). Three content-process terminations across A/B/Private, real toolbar Reload, last committed URL and new DOM identity; unaffected windows retained synthetic markers/documents. Five stale navigation callback forms were injected before/after reload, plus foreign-view callbacks. Not 49 independent crashes or every real callback ordering. |
| Existing regression | `20261107T135604Z-15653` | **48/48 checks; zero recorded failures** | [E02](../../../prototype/wkwebview/Evidence/recovery-regression-20261107T135604Z-15653/regression-summary.json), [E04](../../../prototype/wkwebview/Evidence/recovery-regression-20261107T135604Z-15653/source-hashes.json). Storage seed 12, fresh-process verify 6, private-window lifecycle 3, find/zoom 14, URL policy 13. Same four Swift hashes as recovery, not another OS/runtime matrix. |

Do not publish “97/97 browser acceptance,” a combined percentage with older runs, or a full product gate pass. These suites answer different bounded questions on one source revision. Functional regression success does not qualify the latest revision against performance targets.

| Swift source | SHA-256 |
|---|---|
| LocalInteractionProbe.swift | `8a2fae9505b0105dba696cc3d366ee75f243046086ff22ef8a6127bdc00620a0` |
| NavigationPolicy.swift | `f0eda048dc9b305210a3a28bf3e10ad8c90e1fa2f3d91b70ba1762b267666149` |
| Phase3Measurements.swift | `0adf7a80fe2a744bd45af1b00301b83988356995b72d9986e7c60bd43c8c6e7f` |
| main.swift | `775561a9b25d7277f60417a41daec12096af0b3f2e8e2a602fb1b4136dfba896` |


Recorded runtime: macOS 27.2 (26B123), Apple Silicon MacBookAir10,1, 8 GiB RAM; Xcode/SDK 27.2 and Swift 6.4.2, system WebKit 22625.2.8.11.9. The deployment target remains 26.0. This is historical environment evidence, not macOS 26 execution or a fresh inventory ([E30](../../../prototype/wkwebview/Evidence/phase3-final-environment.json)).

The latest recovery fix retains committed URL and navigation/view identity, retires terminated navigation tokens and waits for an explicit Reload action. It prevents the tested stale/foreign navigation callbacks from replacing the recovery message. It does not prove rejection of stale process-termination notifications, every disposal race, in-flight crash behavior or durable product-state restoration.

The normal recovery build retained App Sandbox, Hardened Runtime, outbound networking and user-selected file access ([E07](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/signed-entitlements.plist), [E32](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/build.log), [E33](../../../prototype/wkwebview/Evidence/recovery-regression-20261107T135604Z-15653/build.log)). Test-only media permissions were confined to an earlier disposable denial workflow. The latest private-marker scan found persistent A/B positive controls and no private marker in 40 files under one isolated WebsiteDataStore; excluded directories and OS-managed data remain outside the claim ([E06](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/post-exit-private-marker-scan.json)). Cleanup is recorded in [E08](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/cleanup.json) and the regression cleanup alongside [E02](../../../prototype/wkwebview/Evidence/recovery-regression-20261107T135604Z-15653/regression-summary.json).

## Earlier results: evidence, not qualification of the latest revision

- Earlier integrated storage/lifecycle runs passed 12+6+3 and a separate 52-file scan was clear. They are distinct from the latest 48-check suite and 40-file scan; neither scan proves complete private-data erasure ([E23](../../../prototype/wkwebview/Evidence/private-cleanup-scan-20261107T095741Z-23704.json)).
- Earlier single-file upload 3/3, isolated download 5/5, native save panel 3/3 and local cancellation/navigation 13/13 are retained in the [historical test report](../prototype/wkwebview-test-results.md). Multi-file/tree, duplicate cancellation and two-origin hostile-frame/popup observations have bounded evidence in [E16](../../../prototype/wkwebview/Evidence/phase3-local-results-20261107T091800Z-16628.json), [E18](../../../prototype/wkwebview/Evidence/phase3-local-review.json), [E19](../../../prototype/wkwebview/Evidence/local-interactions-20261107T090509Z-15825.json). No universal arbitrary-file/path guarantee follows.
- An interrupted download left a 29-byte final artifact. App-owned staging fixed that defect, with 9/9 selected executed checks in [E15](../../../prototype/wkwebview/Evidence/download-staging-regression-20261107T092722Z-18980.json). The parent retry still reports 13/30; the 17 unrelated unexecuted steps are not promoted.
- The final combined camera/microphone Deny request passed 4/4 after temporary OS authorization ([E13](../../../prototype/wkwebview/Evidence/native-permission-20261107T130211Z-native-deny/native-permission-retry-results.json)); targeted resets/cleanup were recorded ([E14](../../../prototype/wkwebview/Evidence/native-permission-20261107T130211Z-native-deny/permission-cleanup.json)). It did not grant website media or verify separate-device, persistence, expiry, revoke or cross-profile decisions.
- Public visits loaded 21/21 across seven landing destinations and three fresh stores per destination ([E20](../../../prototype/wkwebview/Evidence/measurements-20261107T094114Z-22381/public-sites-results-20261107T094114Z-22381-sites.json)). No authenticated Google/Microsoft/GitHub/Figma/Notion/payment/conference workflow passed. Synthetic cookie persistence is not authentication/MFA/SSO/passkey evidence.
- The 100 forged/oversized message attempts exercised an absent page-native channel. They did not exercise a production React transport or prove its schema/origin/frame/replay validator.

## Historical performance: cannot qualify the recovery revision

| Observation | Historical result | Method limit / approved target |
|---|---|---|
| WebKit plus first-view ready, 30 AC samples | median 216.32 ms; p95 678.70 ms | Proxy ≤2,000 ms numerically; not OS cold launch. |
| Warm empty-view constructor, 30 AC samples | median 4.90 ms; p95 11.26 ms | Constructor only; excludes async renderer readiness; target ≤500 ms. |
| 1 MiB fixture DOM ready, 30 AC samples | median 18.00 ms; p95 43.00 ms | Local deterministic page; target ≤1,500 ms. |
| Earlier single-view automatic recovery, 30 samples | signal-to-result median 247.03 ms; p95 upper bound 600.71 ms | Includes JSON write/polling; not timed visible error/manual recovery; threshold ≤2,000 ms cannot be claimed as full product acceptance. |
| Ten-view RSS observation | 630.01 s idle, then 30 sequential one-second samples; peak 23.77 MiB | Host + 12 helpers; numeric ≤1.5 GB. One idle run, not 30 independent runs; resident pages exclude compressed memory/physical footprint and shared RSS can be counted more than once. |

Sources: [E09](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T133031Z-14262/attributed-checks-summary.json), [E10](../../../prototype/wkwebview/Evidence/measurements-20261107T095303Z-23093-AC/AC-measurement-summary.json), [E31](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T133031Z-14262/derived-statistics-and-review.json). An earlier battery run remains separate ([E11](../../../prototype/wkwebview/Evidence/measurements-20261107T094114Z-22381/measurement-summary.json)); the initial host-only 90.16 MiB peak cannot meet a host-plus-engine criterion by itself. Windows were hidden, desktop apps active, caches unflushed. Published variance exists in E10/E31. No clean-state current-revision performance, true cold-launch, full energy or conference qualification is established.

The historical attributed recovery/RSS source has `main.swift` SHA-256 `170dfe1e122923a245441c488996295d49e04450bd918245aea828396607a043`; primary recovery uses the different hash above. AC timing artifacts are separately identified and must not be assigned the later revision hash by inference. No performance rerun is proposed automatically.

The 30 completed crash samples copied from an interrupted collection into E09 remain the same 30 samples. Host attribution used a private Darwin diagnostic ABI validated on two isolated app groups ([E29](../../../prototype/wkwebview/Evidence/process-attribution-20261107T131200Z-10810/two-host-attribution-validation.json)); it stays outside app source and is not an approved public production process-control API.

## Failure and incomplete-run disposition

| Original observation | Retained interpretation |
|---|---|
| LaunchServices -10827 and direct abort before diagnostics | Launch later worked after Xcode installation; root cause unproven. No security protections were removed. See [initial feasibility narrative](../prototype/wkwebview-feasibility-report.md). |
| Interaction 12/13 | One action not reached; later 13/13 is separate ([E27](../../../prototype/wkwebview/Evidence/local-interactions-incomplete-20261107T090022Z-15063.json), [E19](../../../prototype/wkwebview/Evidence/local-interactions-20261107T090509Z-15825.json)). |
| Expanded 24/26 | Real incomplete-file defect plus a transient-URL assertion error; both dispositions recorded, raw failure preserved ([E16](../../../prototype/wkwebview/Evidence/phase3-local-results-20261107T091800Z-16628.json), [E18](../../../prototype/wkwebview/Evidence/phase3-local-review.json)). |
| Focused parent retry 13/30 | Seventeen unrelated steps not repeated; 9/9 selected executed staging checks are only a scoped extraction ([E17](../../../prototype/wkwebview/Evidence/phase3-local-results-20261107T092722Z-18980.json), [E15](../../../prototype/wkwebview/Evidence/download-staging-regression-20261107T092722Z-18980.json)). |
| OS-denial/prepared retries 2/4; guarded native Allow request 3/4 | App prompt not reached or explicit Deny not chosen. Final separate Deny request 4/4; never a grant pass ([E28](../../../prototype/wkwebview/Evidence/permission-deny-20261107T084857Z-14398/result.json), [E26](../../../prototype/wkwebview/Evidence/native-permission-20261107T130211Z-native-deny/native-permission-results.json), [E13](../../../prototype/wkwebview/Evidence/native-permission-20261107T130211Z-native-deny/native-permission-retry-results.json)). |
| First attributed crash assertions failed | Native title at didFinish was not a reliable readiness assertion; later tests query DOM title/content and retain native observations ([E24](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T132333Z-12795/crash-result-1.json)). |
| First idle collection interrupted | No memory completion claim for that run. Later fresh-host idle observation completed; earlier 30 crash samples reused ([E25](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T132441Z-13174/attributed-checks-summary.json), [E09](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T133031Z-14262/attributed-checks-summary.json)). |

Earlier snapshots may call attribution blocked or the native prompt unverified. Preserve them as time-scoped reports; later artifacts establish only their own narrower superseding observations. The full historical directory inventory was reviewed, including 279 JSON artifacts (many repeated per-sample files/copies); none was modified. Original raw labels remain unchanged.

## Reconciled closure and open requirements

The [consolidated ledger](browser-acceptance-gate-ledger.md) splits the former 13 mixed gates into 67 explicit requirements across A/B/C/D. Preserved review-snapshot inventory: **Passed: 9, Partially Verified: 12, Failed: 0, Blocked: 12, Deferred: 7, Not Tested: 22, Out of Scope: 5**. These are requirement counts, not a combined test rate. Historical failed/incomplete runs have a separate register. No whole browser/security/release gate is claimed Passed.

The concrete access blocker is the public-pages-only instruction and undefined approved critical account subflows; no current compile/launch blocker is recorded. Full media grants need separate authorized scope. macOS 26 runtime and signing/notarization remain mandatory final-stage conditions. Durable history, production bridge, app-state and service integrations require future implementation, so repeatedly testing the current prototype cannot satisfy them.

**Closure/stop condition:** Phase 3 closure is APPROVED as a bounded investigation with limitations under the [owner decision](owner-approval-decision.md). Do not continue automatic edge-case loops, rerun unchanged suites or require unimplemented MVP features as perpetual Phase 3 tasks. Any later validation must have a separately approved requirement, version/scope and exit criterion. Any real cross-boundary leak or unauthorized action remains a hard blocker requiring remediation.

## Owner approvals recorded and Phase 5 preparation

The Product Owner explicitly approved the three decisions on 2026-11-07: **Phase 3 closure — APPROVED; WKWebView engine — CONDITIONAL ACCEPTANCE for MVP planning and implementation; architecture baseline — APPROVED.** The [owner approval decision](owner-approval-decision.md) is the current dated authority. The [assessment](browser-engine-decision-assessment.md) retains the earlier alternatives/risk analysis, and the [approved baseline](browser-mvp-architecture-baseline.md) retains its unresolved implementation details.

The three approvals do not need to be requested again. Phase 4.1 is complete and reviewed; its Stage A/B/C validation policy is verified, and ADR 0001 is unchanged in this Phase 4.2 completion and remains Proposed; conditional acceptance does not establish a release-ready or unconditionally accepted production engine. No incomplete, access-blocked, deferred or future implementation gate becomes Passed. The ledger's B12 and 67-item totals remain an unchanged pre-approval snapshot; the owner record adds the later administrative disposition without rewriting test evidence or classifications.

The [Phase 5 index](../phase-5/README.md), [scope/milestones](../phase-5/phase-5-scope-and-milestones.md) and [implementation plan](../phase-5/phase-5-implementation-plan.md) prepare later scoped execution under the conditional direction: M0-M7 implement/validate under ADR Stage B; M8 performs mandatory final-release validation under Stage C. Outstanding Stage A critical-workflow/risk decisions stay explicit before affected implementation choices. This task starts no production implementation, builds/tests or prototype loop. CEF stays evaluation-only, Aura excluded, production Tamizhi excluded and identity/cloud optional; no public distribution is authorized.

## Evidence register

| Evidence | Original artifact | Interpretation |
|---|---|---|
| E01 | [E01](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/recovery-ui-results.json) | Primary recovery revision: 49/49 assertions, three real content-process crashes; A, B and Private. |
| E02 | [E02](../../../prototype/wkwebview/Evidence/recovery-regression-20261107T135604Z-15653/regression-summary.json) | Same native-source revision: 48/48 across seed 12, verify 6, window lifecycle 3, find/zoom 14 and URL policy 13. |
| E03 | [E03](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/source-hashes.json) | Four Swift file hashes for the primary recovery revision. |
| E04 | [E04](../../../prototype/wkwebview/Evidence/recovery-regression-20261107T135604Z-15653/source-hashes.json) | Matching hashes for the regression build. |
| E05 | [E05](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/computer-use-observation.json) | Actual native recovery message observed; real toolbar Reload clicked separately for A/B/Private. Immediate AX updates were stale; restored-document verification comes from the native harness. |
| E06 | [E06](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/post-exit-private-marker-scan.json) | 40 files under the isolated app WebsiteDataStore; A/B positive controls found, private synthetic marker absent. Other directories and OS transient data excluded. |
| E07 | [E07](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/signed-entitlements.plist) | Normal sandbox, network client and user-selected read/write access; no media/debug entitlement in this build. |
| E08 | [E08](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/cleanup.json) | Three attributed content signals; disposable build removed and fixture server closed. |
| E09 | [E09](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T133031Z-14262/attributed-checks-summary.json) | Historical recovery/RSS revision: 30 crash samples, p95 signal-to-result upper bound 600.71 ms; one ten-view idle run, 30 sequential RSS samples, peak 23.77 MiB. |
| E10 | [E10](../../../prototype/wkwebview/Evidence/measurements-20261107T095303Z-23093-AC/AC-measurement-summary.json) | Earlier 30-sample AC timing proxies: p95 first-view 678.70 ms, warm constructor 11.26 ms, local DOM 43.00 ms. Not latest-revision qualification. |
| E11 | [E11](../../../prototype/wkwebview/Evidence/measurements-20261107T094114Z-22381/measurement-summary.json) | Earlier 30-sample battery timing run, public pages 21/21, ten-view idle 621.18 s; host-only resources and unresolved attribution at that time. |
| E12 | [E12](../../../prototype/wkwebview/Evidence/phase3-source-manifest.json) | Preserved final Phase 3 source manifest; individual run hashes still govern run provenance. |
| E13 | [E13](../../../prototype/wkwebview/Evidence/native-permission-20261107T130211Z-native-deny/native-permission-retry-results.json) | Final combined camera/microphone Deny request: 4/4. OS access temporary; no website grant. |
| E14 | [E14](../../../prototype/wkwebview/Evidence/native-permission-20261107T130211Z-native-deny/permission-cleanup.json) | Targeted OS permission resets and temporary-build cleanup recorded. |
| E15 | [E15](../../../prototype/wkwebview/Evidence/download-staging-regression-20261107T092722Z-18980.json) | Nine selected executed download checks passed; not a passing full 30-check retry. |
| E16 | [E16](../../../prototype/wkwebview/Evidence/phase3-local-results-20261107T091800Z-16628.json) | Earlier expanded run remains 24/26; includes the real incomplete-final-download defect and redirect assertion failure. |
| E17 | [E17](../../../prototype/wkwebview/Evidence/phase3-local-results-20261107T092722Z-18980.json) | Raw retry remains 13/30, including 17 unrelated interactive checks not repeated. |
| E18 | [E18](../../../prototype/wkwebview/Evidence/phase3-local-review.json) | Disposition of redirect assertion and 29-byte incomplete-download defect; focused remediation evidence. |
| E19 | [E19](../../../prototype/wkwebview/Evidence/local-interactions-20261107T090509Z-15825.json) | Earlier 13/13 native cancellation/navigation/private-popup checks. |
| E20 | [E20](../../../prototype/wkwebview/Evidence/measurements-20261107T094114Z-22381/public-sites-results-20261107T094114Z-22381-sites.json) | Seven public landing pages, three fresh-store repetitions each. No authenticated workflow. |
| E21 | [E21](../../../prototype/wkwebview/Evidence/phase3-final-status.json) | Historical 13-gate record and user-directed scope/deferrals. This review splits mixed gates without changing the record. |
| E22 | [E22](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T133031Z-14262/build-audit.json) | Historical build audit: minimum 26.0, SDK 27.2, ad-hoc signature, Hardened Runtime and normal entitlements; not Developer ID/notarization proof. |
| E23 | [E23](../../../prototype/wkwebview/Evidence/private-cleanup-scan-20261107T095741Z-23704.json) | Earlier bounded 52-file store scan; distinct from E06. |
| E24 | [E24](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T132333Z-12795/crash-result-1.json) | Historical first recovery run failed two native-title-at-didFinish assertions. |
| E25 | [E25](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T132441Z-13174/attributed-checks-summary.json) | Run interrupted during idle collection; its 30 completed crash samples were reused, not repeated or counted twice. |
| E26 | [E26](../../../prototype/wkwebview/Evidence/native-permission-20261107T130211Z-native-deny/native-permission-results.json) | Earlier same-session guarded Allow choice: 3/4; denial-only guard returned Deny. Separate final request E13 explicitly chose Deny. |
| E27 | [E27](../../../prototype/wkwebview/Evidence/local-interactions-incomplete-20261107T090022Z-15063.json) | Earlier incomplete interaction run: 12/13; unsupported-address action not reached. |
| E28 | [E28](../../../prototype/wkwebview/Evidence/permission-deny-20261107T084857Z-14398/result.json) | OS denial observation 2/4; app-owned prompt was not reached. |
| E29 | [E29](../../../prototype/wkwebview/Evidence/process-attribution-20261107T131200Z-10810/two-host-attribution-validation.json) | Host-only private Darwin diagnostic ABI validated against two simultaneous isolated app groups; not a supported product API. |
| E30 | [E30](../../../prototype/wkwebview/Evidence/phase3-final-environment.json) | Recorded host/SDK/WebKit environment; not a live inventory or macOS 26 runtime result. |
| E31 | [E31](../../../prototype/wkwebview/Evidence/attributed-checks-20261107T133031Z-14262/derived-statistics-and-review.json) | Historical raw samples and variance reviewed; currentSourceMatchesMeasuredRevision=false. |
| E32 | [E32](../../../prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/build.log) | Primary UI build compiled and passed strict ad-hoc signature verification. |
| E33 | [E33](../../../prototype/wkwebview/Evidence/recovery-regression-20261107T135604Z-15653/build.log) | Regression build compiled and passed strict ad-hoc signature verification. |


## Preserved reports and authority

[Feasibility report](../prototype/wkwebview-feasibility-report.md), [test report](../prototype/wkwebview-test-results.md), [limitations](../prototype/wkwebview-limitations.md), [prior final review](../prototype/phase3-final-review.md), [dependency inventory](../prototype/phase3-dependency-inventory.md) and original evidence are historical records. This review reconciles their scope without rewriting them. Maintained [platform architecture](../browser-platform-architecture.md), [engine contract](../browser-engine-contract.md), [acceptance criteria](../browser-mvp-acceptance-criteria.md) and ADRs remain in their existing locations. The dated owner record and corrected ADR distinguish the approved conditional implementation direction from unpassed implementation/release gates and earlier all-product-gates-before-selection wording. ADR 0001 stays Proposed; no wider unconditional acceptance or waiver is inferred.
