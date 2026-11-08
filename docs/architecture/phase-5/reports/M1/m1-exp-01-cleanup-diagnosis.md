# EXP-01 Cleanup Diagnosis — Remediation 2026-11-08

Version 1.0. D01 of M1 Validation Remediation. Read-only diagnosis; no store creation, cleanup, deletion, harness launch, signing or retry performed. Original [EXP-01 FAIL](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/EXP-01.md) and cleanup crash evidence remain unchanged.

## 1. Verified baseline and source identity

Repository branch timeline; HEAD7545fcec1ef8cd5e939ebc67990d8b6acdc10a7e, clean at start. HEAD matches locally recorded origin/timeline and commit subject docs(phase-5): prepare M1 Canonical Engineering Baseline. This is local tracking-ref verification, not a new fetch or live remote-server attestation. [Baseline and tracked hashes](../../evidence/20261108T103813Z-m1-validation-remediation/baseline.json).

Sources: retained NativeProbe.swift and revisions/NativeProbe-v1.swift; original fixture UUID registry, seed/verify results, cleanup-only native log/result and signature/binary provenance under the previous run. [Read-only evidence](../../evidence/20261108T103813Z-m1-validation-remediation/results/) records actual current paths/commands/hashes. Current arm64 macOS 27.2/build26B123 discovery does not qualify macOS 26.

The retained cleanup binary SHA256 matches original cleanup provenance; Mach-O UUID9B391BAD-3851-386E-A6CB-0B8C83691B1B matches the crash report image. Thus the crash is tied to this exact cleanup-only revision, not inferred from a similarly named process/report.

## 2. First failure: retained-reference analysis

Original verify branch:
- Local variables a/b hold persistent WKWebsiteDataStore objects.
- Local a1/a2/b1/cleanA WKWebView values and their configurations can retain those stores across the async frame.
- Probe.retainedViews and window.contentView subviews are explicitly cleared, but that does not establish all local/configuration/native references were released.
- Navigation delegates, pending continuation dictionary, Task/self, timeout/self and the extended application delegate lifetime require explicit retirement/instrumentation. Pending navigation continuations are removed by completion callbacks in the code, but no final live-object/operation counters were retained.
- stopLoading/removeFromSuperview/window.close do not prove WKWebView deallocation or auxiliary process quiescence.

Both removal callbacks reported Data store is in use. **Confirmed:** WebKit rejected removal as in-use. **Evidence-supported contributing factor:** teardown did not establish the required release boundary before invoking removal. The exact final retaining object/process cannot be uniquely attributed without lifetime instrumentation; do not promote every possible reference to a confirmed root cause.

Apple explicitly requires releasing WKWebViews using the store before removal. That supports correcting the experimental teardown contract, not modifying production code or asserting an engine defect. [Apple API](https://developer.apple.com/documentation/webkit/wkwebsitedatastore/remove%28foridentifier%3Acompletionhandler%3A%29).

## 3. Separate cleanup-only crash

The cleanup revision branches before creating persistent stores/views and invokes remove(A), then remove(B), awaiting each. It prints only VX_BOOT and a final aggregate VX_RESULT; there are no before/after markers for each store.

[Crash extract](../../evidence/20261108T103813Z-m1-validation-remediation/results/cleanup-crash-extract.json):
- Launch2026-11-08 15:26:10.0183 +0530; crash15:26:16.0952 +0530.
- EXC_BAD_ACCESS/SIGSEGV, invalid address0x48, faulting thread3.
- Frames include os_unfair_lock_lock, WTF::RunLoop::dispatch, then WebKit::WebsiteDataStore::removeDataStoreWithIdentifierImpl on a background work item.
- Native process returncode−11; no aggregate VX_RESULT.
- The crash report was written later; its filename time is not the operation's actual crash time.

**Confirmed fault phase:** during framework asynchronous removal work/dispatch, before aggregate completion reporting. It was not merely an app launch failure or runner timeout.

**Unknown:** exact active call/callback completion at the crash (the unified log below confirms A start but not completion); whether A's completion ran before B; whether filesystem changes completed before completion delivery; exact run-loop/object-lifetime cause. The source's combined sequential awaits plus absent per-store markers cannot answer those questions. Run-loop initialization/lifetime or OS/WebKit behavior is a plausible hypothesis, not a confirmed root cause. No binary-matched upstream source-level diagnosis is established.


### Bounded unified-log corroboration

A read-only query restricted to PID60924 and15:26:09–15:26:18 returned138 records. The [filtered removal summary](../../evidence/20261108T103813Z-m1-validation-remediation/results/unified-log-removal-summary.json) records Removal started for identifier abb4ca2d-33dc-4d25-9c16-d135202c03e3 at15:26:14.278133+0530. No removal-completed or store-B-start record appears in that captured window. **Confirmed:** A's removal was entered before the crash. This narrows the sequence beyond the app's aggregate stdout. It does not prove which callbacks fired or that a missing completion log means no filesystem side effect; partial/lost logging remains possible. A's logical removal is still not confirmed from directory absence. The exact framework root cause remains unresolved.

Current installed WebKit/JavaScriptCore metadata reports22625.2.8.11.9; this is recorded separately from the binary-matched app UUID and is not a claim that upstream source or another OS build was qualified.

## 4. Store-by-store current classification

Only the exact recorded UUIDs and exact disposable app namespace were inspected. No broad similarly named directory search/deletion occurred. See [state snapshot](../../evidence/20261108T103813Z-m1-validation-remediation/results/original-store-state.json).

| Store | Recorded UUID | Current physical evidence | Classification |
|---|---|---|---|
| A | abb4ca2d-33dc-4d25-9c16-d135202c03e3 | Expected UUID directory absent beneath the exact app's WebsiteDataStore root. Original physical path/registry state was not captured at creation; UUID identity is known but original filesystem identity/location is not conclusively established. | **State unknown** — absence alone does not prove completed removal |
| B | 9ec735a8-b9eb-416c-994b-4b299c5ee5f5 | Matching directory present;38 file names/sizes/modes/owners/timestamps/hashes retained. No pre-removal filesystem manifest or current native registry/content-integrity proof. | **State unknown** — physical presence confirmed; whole-store intactness/partial modification not established |

The current app identity is tied to original fixture/bundle provenance and current exact namespace. Protected container-manager metadata may be inaccessible; any such error is retained, not bypassed. No hidden default/personal profile is treated as a fixture.

[Process snapshot](../../evidence/20261108T103813Z-m1-validation-remediation/results/process-snapshot.json) and [lsof](../../evidence/20261108T103813Z-m1-validation-remediation/results/owned-open-handles.json) reported no matching app/engine process or open store handle at the observation time, subject to command return/error fields. This does not establish the absence of future/background references or reconstruct the prior failure. No process was killed.

Missing A plus present B is compatible with partial side effects or A completion followed by B failure; it is not sufficient to choose between them. Test artifacts remain necessary evidence. No file was removed or reconstructed.

## 5. Bounded follow-up disposition

**Fresh diagnostic verification: BLOCKED / NOT EXECUTED.** Original logical state/registry and the cleanup crash's per-store completion are not understood sufficiently to satisfy this instruction's prerequisite. No original store is removed. No new disposable store/harness is created merely to bypass the prerequisite. No signing is performed.

Proposed next diagnostic, not run: obtain noncreating identifier enumeration in the same valid app identity and instrument exact before-call/after-callback/store-ID checkpoints and deallocation/operation counters. Apple documents enumeration as the existence check; init(forIdentifier:) may create a missing store and must not be used to inspect A. [WebKit profile guide](https://webkit.org/blog/14423/building-profiles-with-new-webkit-api/).

Once original state is sufficiently established, a future finite probe must use NEW UUIDs, explicit reference ownership/release scopes, cancelled navigation/services, nil delegates/handlers, awaited operations and completion/error results; capture public identifier enumeration before/after and final scoped resource state. Release a WebKit reference by proof/counters, not arbitrary sleeps. A crash stops that run; no direct filesystem cleanup or unchanged loop.

Additional granularity is a proposed procedure refinement under existing ISO-001/EXP-01, not a new case ID or silent acceptance extension. Exact safe runtime/harness/signing prerequisites must be established before execution.

## 6. Conclusion and proposed engineering tasks

- Original EXP-01 remains **FAIL**.
- Initial in-use precondition failure is confirmed; incomplete reference-release proof contributes.
- Cleanup-only framework fault location/phase is confirmed; underlying crash root cause remains unresolved.
- Both original logical cleanup states remain explicitly unknown, with A absence/B presence distinguished.
- Read-only diagnosis improves specificity but creates no remediation PASS, AC08 pass or production guarantee.
- Proposed work: native-owned resource inventory/reference-release boundary; per-store async completion checkpoints; noncreating registry inspection; safe cleanup reconciliation state; explicit failure/no false cleanup; framework initialization hypothesis investigation using fresh fixtures only after prerequisites.
- All production fixes remain proposed. WKWebView conditional direction and ADR statuses unchanged.
