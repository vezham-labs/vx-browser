# WKWebView Feasibility Prototype

This is an isolated native AppKit experiment, not the Vezham Browser application. It contains no production UI, React bundle, Aura dependency, account integration, cloud client, or Arc material. The visible chrome is native AppKit; remote sites are rendered in a separate `WKWebView` with no script message handlers.

## Build

Run `./build.sh` from this directory. It uses the installed macOS Command Line Tools SDK and Swift compiler, builds `build/VezhamWKPrototype.app`, signs it ad hoc with the prototype entitlements, and enables the hardened runtime. Xcode is not required by the script. The build output is local and disposable.

The prototype uses `com.apple.security.app-sandbox`, outbound networking for browsing, and user-selected read/write access for native file panels. It does not disable Gatekeeper or weaken WebKit's process sandbox. These entitlements are experimental and are not a production release profile.

## Run

`open build/VezhamWKPrototype.app` starts a native window on Profile A. The Window menu opens Profile A, Profile B, or a shared Private Session in additional windows. Close all private windows to end the in-memory session. The app uses only native controls; its only page view displays remote/local website content.

## Local isolation harness

`./run-local-isolation.sh` builds under a temporary directory and unique app identity, then starts a loopback-only fixture server and runs seed, fresh-process verification, and a headless AppKit private-window lifecycle process. The storage harness writes synthetic markers to cookies, localStorage, IndexedDB, Cache Storage/service-worker scope, and a cacheable HTTP response; it tests persistent-profile separation and private-session registry retain/release behavior. The window harness exercises actual window close callbacks, verifying that closing one private window retains the session and closing the last replaces it. Results go to that test identity's sandboxed Application Support container, and the runner checks all three JSON reports for a passed status. It clears only the isolated test profiles' website data after verification.

## Find and zoom API harness

Run `bash ./run-find-zoom.sh` to check case-sensitive and insensitive find, forward/backward search, wrapping, zero-result reporting, and per-view zoom set/read/reset. The runner builds into a temporary directory under a unique bundle identifier, preserving the regular prototype app bundle and its data container. Results remain in that test identity's sandboxed Application Support container.

Run `bash ./run-url-policy.sh` for 13 Foundation-level URL normalization checks shared with the app. It tests HTTP/HTTPS acceptance and rejects unsupported schemes, embedded credentials, and malformed input. It does not test WebKit's redirect, popup, or subresource behavior. The JSON report is written to `Evidence/url-policy-results.json`.

## Local download harness

Run `bash ./run-local-download.sh` for a loopback-only synthetic download. The isolated harness checks WebKit's download callback, path-like suggested-name reduction, the test destination boundary, and exact payload bytes. It chooses a test-only destination instead of opening `NSSavePanel`, so it does not verify the visible save prompt, cancellation, duplicate-name handling, or user-selected paths. The temporary test file and build are removed after the run; its JSON report remains in the test identity's sandboxed Application Support container.

Run `bash ./run-local-download-panel.sh` to exercise the visible native save panel. Select Save in the panel; the isolated fixture folder is preselected as the destination. The runner checks that the file stayed inside that folder, retained a safe basename, and matches the synthetic payload. It holds the app open for desktop inspection and closes it automatically after 3.5 minutes if needed.

Run `bash ./run-local-permission-deny.sh` for the loopback media-denial fixture. The request begins only after the **Request camera and microphone** button is clicked. This test build alone receives temporary media entitlements and purpose strings. Choosing **Don't Allow** in macOS verifies OS denial; reaching Vezham's own **Deny** choice requires the separately authorized temporary OS-access workflow described below. Both OS-denial and app-owned native-denial evidence are retained. The latter final request passed 4/4 checks; the full grant/revocation lifecycle remains untested. See the [test results](../../docs/architecture/prototype/wkwebview-test-results.md).

Run `bash ./run-local-upload.sh` to open an isolated prototype window with a **Choose test file** button through LaunchServices. Click it, then select the single synthetic file in the native picker; the loopback fixture checks the selected name and exact uploaded bytes. The runner waits up to three minutes for that interactive selection and the app closes automatically after three and a half minutes. The app uses a unique test bundle ID and the temporary picker folder supplied on its test-only command line.

## App-owned permission follow-up

The app-owned permission test is a separate, explicitly approved workflow: allow the disposable app at both macOS privacy prompts, then choose **Deny** in Vezham's own prompt. Test mode always returns Deny to the page and records the actual button choice separately. The latest final request passed 4/4 checks: both OS authorizations were observed, the origin-labelled app prompt appeared, explicit Deny was selected, and the page received NotAllowedError/no stream. The earlier guarded request remains a separate 3/4 report because Allow was clicked in the app prompt. Targeted Camera/Microphone resets succeeded after app closure and the build was removed. Actual website grants, persistence/revocation and independent device cases remain untested. See the final review for retained results and cleanup evidence.

## Local cancellation and navigation checks

Run `bash ./run-local-interactions.sh` for an isolated interactive run using the normal prototype entitlements. Cancel the upload picker, press **Check upload selection**, cancel the download save panel, follow the local redirect, return to the checks, open the popup, return again, then try the unsupported address. The runner records native callbacks and fixture observations, checking for zero selected/uploaded files, an empty test download destination, retained synthetic private-session markers/cookies, the originating popup data store, rejection of the unsupported scheme, and absence of the `vezham` page bridge.

The evidence sink is enabled only by the test command line and is not exposed to website scripts. The app uses a unique identity, temporary picker/save folders, and a five-minute safety timeout. These checks cover one local HTTP redirect and one same-origin popup; they do not establish hostile-frame or cross-origin redirect safety, arbitrary destination cleanup, or complete profile isolation. Results remain under the isolated app identity's Application Support directory.

## Final Phase 3 local suite

`bash ./run-phase3-local.sh` runs the two-origin frame/redirect/popup and expanded transfer fixture in a separate app identity. Choose only the generated two-file set and synthetic folder; cancel duplicate replacement and the save panel, then save the interrupted and completed synthetic transfers. Follow the cross-origin redirect, try the privileged-scheme redirect, return, and open the cross-origin popup. Runtime failures remain in the JSON report. The 100 forged-message attempts exercise an absent page-native channel; they do not validate a future React/native transport.

`WK_PHASE3_DOWNLOAD_ONLY=1 bash ./run-phase3-local.sh` scopes the report to the interrupted/completed download regression. The prototype stages selected downloads under its own temporary directory, removes failed/cancelled staging, and moves a completed payload to the selected final URL. An abruptly killed host, cross-volume save, metadata/quarantine behavior, and replacement of an existing destination still need dedicated validation. No broad filesystem entitlement is added.

## Public-page and measurement runner

`bash ./run-phase3-measurements.sh` collects 30 fresh-process timing samples, three clean-store public landing-page visits for seven services, and a ten-minute observation of ten idle views. It records environment/power metadata, host RSS/CPU, and an all-WebKit RSS upper bound. It never signs in, joins a room, pays, or grants media access. The original runner does not attribute helper ownership. A separate host-only diagnostic follow-up now provides bounded aggregate RSS and crash timing; see the Phase 3 final review for its private-ABI method and limits. The hidden-window timing proxies and any battery-powered run are reported separately from controlled release acceptance. Reports are retained under `Evidence/measurements-<run>`.

## Local content-process recovery harness

`bash ./run-local-crash-recovery.sh` is the original conservative runner. It attempts parent/bundle attribution and refuses to signal a reparented process when that ownership is unavailable. Its original blocked attempts remain historical evidence.

A separate host-only follow-up validated resource/jetsam coalition and unique-process IDs against two simultaneously running isolated AppKit apps. After checking the disposable host and helper paths/owners/identities, it terminated only that host's single WebContent process and rechecked identities immediately before each signal. Thirty fresh-host recovery samples passed seven checks each; signal-to-result observed p95 was 600.71 ms. The app uses its public termination callback, reloads its last fixture URL, then verifies DOM readiness. The first report's title-at-didFinish assertions failed; the repeat reads fixture title/content together from the DOM, retaining native title observations and the failed report.

The follow-up uses private Darwin diagnostic metadata outside browser source. The exact executed runner and metadata helper are retained with its evidence, alongside two-host validation, per-signal guards and raw results. It is validated only on this recorded Mac and is not a supported product process-control API. The browser imports no private diagnostic API. The final revision separately passed 49 actual-window recovery checks across A/B/Private, with real Reload actions and injected stale/foreign navigation callbacks; durable product state and broader in-flight crash cases remain unverified.

For the separate ten-view idle observation, `--test-idle-report-grace-seconds 60` keeps the test views alive briefly after the native ten-minute report, allowing 30 one-second RSS samples. The default grace remains three seconds; the native timer may coalesce while hidden. Helper membership/identity is checked throughout sampling. The RSS result is distinct from physical footprint/compressed memory and from full performance acceptance.

Harness JavaScript evaluation is a test-only private helper, not part of `BrowserCommand` and not reachable from page content or the app's shared UI boundary. Test fixtures bind only to loopback. No external service workflows are automated.
