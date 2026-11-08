# M1 Provider and Fixture Qualification — v1.0

Date: 2026-11-08. **Bounded qualification infrastructure and evidence only. No product implementation, production dependency change, signing, notarization, distribution or release authority.**

## 1. Baseline, authority and source inventory

Starting repository: vezham-labs/vx-browser; origin https://github.com/vezham-labs/vx-browser.git; branch timeline; HEAD f5733fabeee1b0eb559d472c6c86f317b74d8108; working tree clean. Expected HEAD matched before any work. [Owner instruction](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/sources/owner-authorization.txt), [all tracked hashes/start state](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/baseline.json). No branch switch/stage/commit/push/reset/rebase/clean.

Governing sources inspected and hash-matched against the preceding remediation artifacts:
- [Remediation report v1.0](m1-validation-remediation-report.md).
- [Readiness/downstream assessment v1.0](m1-validation-readiness-remediation.md).
- [Encryption specification v1.0](m1-persistent-profile-encryption-specification.md).
- [Keychain/recovery specification v1.0](m1-keychain-and-independent-recovery-specification.md).
- [EXP-01 diagnosis v1.0](m1-exp-01-cleanup-diagnosis.md).
- Developer Specification1.2, Validation Plan1.2, Supporting Charters1.2 and case matrix1.3; exact versions/paths/hashes in [source inventory](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/sources/canonical-input-inventory.json).
- Original EXP-01/03/04 reports, fixtures and native probe code, including original seed/verify/cleanup-only modes. All historical evidence is unchanged.

Current host: arm64, macOS27.2/build26B123; Xcode SDK27.2, Swift6.4.2, Apple clang21.0.0; Python3.13.1; Apple Tcl8.5.9. [Toolchain/target records](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/toolchain-and-target.json). Compile target26.0 is not macOS26 runtime qualification. Supported product architecture set is not expanded; only arm64 was built. The required nx-workspace skill was searched in installed skill roots during prerequisite inspection and is unavailable; no product Nx task or generator was modified. Isolated evidence scripts have no existing Nx target.

## 2. Workstream A — candidate provenance/build/license

### Exact candidate record

| Field | Evidence-backed result |
|---|---|
| Upstream | Official sqlcipher/sqlcipher repository, [release v4.20.0](https://github.com/sqlcipher/sqlcipher/releases/tag/v4.20.0) |
| Annotated tag object | 52252487a5cada9b430e8d4b20025790c5a6ba20 |
| Immutable source commit | **355d4db92d3404e71faa8088d071a71d767807f4** |
| Tree | b3aa6f0a71413a40df4c968d357bbbbee61b42cb |
| Release record | Not marked immutable; no attached binary/checksum assets in this repository release |
| Source archive SHA256 | fc5394c916beeabb1f43e2ac97d0827f36e8917f6675a00cca54537c32cb36a2 |
| Integrity verification | All2325 archive file Git-blob identifiers matched the immutable upstream recursive tree; path/special-file bounds checked before extraction |
| Publisher authenticity limitation | Commit unsigned; annotated tag has signature but GitHub reports unknown_key. No independently trusted publisher-key verification or vendor archive checksum established |
| SQLite version | Source VERSION3.54.1 and compiled object string3.54.1 |
| SQLCipher compatibility | Candidate4.20.0; production format remains4.x contract, not5.x beta |
| Provider | Build defines SQLCIPHER_CRYPTO_CC; archive symbols reference CommonCrypto and SecRandom; no OpenSSL provider selected |
| Exact input record | [provider-source-record.json](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/provider-source-record.json), [tag/commit/tree/release metadata](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/sources/) |
| Qualification status | **Verified source-tree integrity + prepared static builds; full provider qualification remains Blocked** |

Only source was downloaded from official GitHub/codeload over HTTPS; no prebuilt binary was downloaded/executed. Matching Git objects establishes integrity relative to that upstream repository, not independent proof that a compromised upstream could not publish malicious source. The immutable commit and locally retained SHA256, not a moving tag/release URL, are the reproduction input.

### License and security assessment

SQLCipher LICENSE.md is a three-condition BSD-style license requiring notice/disclaimer retention and prohibiting endorsement without permission. SQLite source is public domain; bundled autosetup has a separate permissive license. Exact license/README/changelog files and hashes are retained under [sources](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/sources/). This is an engineering provenance assessment, not organizational legal approval or release permission. Production dependency approval/license notices still require review.

Official GitHub security-advisory API returned no published advisories; this is not a clean security bill. [API capture](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/sources/security-advisories.json). Vendor [4.19 advisory](https://www.zetetic.net/blog/2026/09/08/sqlcipher-4.19.0-release/) describes fixes to export alias handling and malformed URI hexkey behavior; the pinned4.20 source includes the later history, but application regression tests are still required. This fixture interface forbids arbitrary SQL/URI keys and uses the length-explicit key API. [Open issues](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/sources/upstream-open-issues.json) include rollback/integrity-check/preallocation and macOS x86_64 build concerns. They are reported issues, not proven reproduced defects in this arm64 build.

SQLite3.54.1 release notes report a32-bit heap-overflow fix; arm64 build does not establish other-architecture safety. [Upstream release notes](https://www.sqlite.org/releaselog/3_54_1.html). A complete CVE/SBOM/operational dependency review, publisher trust decision and supported-target qualification remain open.

### Isolated source build and reproducibility

Prepared two out-of-tree **static archives only**, outside production targets, under /private/tmp/vx-m1-provider-fixtures-20261108T113403Z/provider-build-1 and provider-build-2. No package manifest/lockfile/product target changed; no install target or codesign/notarization command executed. Compiler-generated configure/build helpers were used by the ordinary source build; no app identity/entitlement was introduced or changed.

Configuration:
- Official autosetup configure; --disable-shared --disable-tcl --disable-readline --disable-load-extension --with-tempstore=always.
- CFLAGS: -O2, target arm64-apple-macosx26.0, SDK27.2, SQLITE_HAS_CODEC, SQLCIPHER_CRYPTO_CC, SQLITE_EXTRA_INIT=sqlcipher_extra_init, SQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown, SQLITE_OMIT_LOAD_EXTENSION; path remapping; configure emits SQLITE_TEMP_STORE=3 and SQLITE_THREADSAFE=1.
- make -j2 libsqlite3.a. This upstream version's artifact name is libsqlite3.a even though it contains SQLCipher; do not confuse it with stock system SQLite.
- ZERO_AR_DATE=1, fixed SOURCE_DATE_EPOCH1793028838, explicit Tcl path and owned temporary directory. Actual full compiler/SDK/environment/commands/stdout/stderr in [build runner](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/harness/build_provider_static.py) and [build record](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/provider-build-record.json).

Both archives are1,651,288 bytes and SHA256 **ac0fed4b3c47b6259a87504b318fd4546018c880b0d60331a47e92c3f7a9856c**. Generated amalgamation/header hashes also agree. [Static inspection](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/provider-static-inspection.json) confirms CommonCrypto/SecRandom references and compiled TEMP_STORE=3. Object LC_BUILD_VERSION records minos26.0/sdk27.2.

**Narrow conclusion:** repeatability of these two local builds is verified. Independent-machine/SDK/architecture reproducibility, runtime provider settings, DB authentication, encrypted artifact protection and runtime absence of temp spill are not qualified. No static archive was loaded to execute an encryption campaign.

Initial configure attempts failed in the execution sandbox with Tcl error-file creation restrictions, including an owned TMPDIR attempt. Those records were retained. A distinct outside-execution-sandbox build completed; no sandbox/Gatekeeper protection of an application was disabled. No unchanged retry loop.

### Database fixture inventory and expected observations

[Preparation script](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/harness/prepare_database_controls.py) created disposable **unencrypted synthetic controls only** using Python's stock SQLite3.53.4, not the candidate. Paths/hashes/modes and classifications in [database-control-fixtures.json](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/database-control-fixtures.json). Catalog/profile-A/profile-B controls, captured main/WAL/SHM and rollback-journal bytes, and mutated/truncated plaintext copies were prepared. Public synthetic marker detection worked in main and WAL controls. These prove detector controls, not encryption or coherent backup/recovery.

No keys are in those files. Copies of live WAL/SHM are explicitly artifact detectors, not claimed portable consistent snapshots. Statement journals/temp spill, encrypted/corrupt-tag fixtures, interruption/rekey/promotion and protected snapshots remain **Prepared plan / Not Executed**.

| Required condition | Prepared artifact/plan | Expected observation before any qualification claim |
|---|---|---|
| Correct key |32-byte binary key-input contract; encrypted fixture not built | Declared authenticated records/identity/settings readable with exact scope |
| Missing key | Planned existing encrypted-copy fixture | Fail access without CREATE/reset/plaintext fallback |
| Wrong key | Planned independent transient key | Fail authenticated read, preserve ciphertext |
| Wrong profile/scope key | Separate public control namespaces prepared; crypto fixture not built | Wrong profile key/lease fails; correct other profile unaffected |
| Ciphertext/page/tag modification | Byte-mutation constructor prepared on plaintext copy only | Qualified encrypted copy rejects tamper; no claim from plaintext mutation |
| Truncated DB | Constructor prepared on plaintext copy only | Fail/explicit corruption; no destructive repair |
| Missing/corrupt WAL/journal/SHM | Artifact inventory prepared; fault test not run | Exact committed/uncommitted boundary preserved or truthful failure; do not delete live journals to manufacture pass |
| Interrupted write | Planned disposable worker/checkpoint fixture | Commit/receipt outcomes match the frozen interruption boundary |
| Rotation/interrupted promotion | Contract/fixture plan only | Preserve source/old key generation until verified destination promotion |
| Plaintext detector | Main/WAL synthetic positive controls built and observed | Detector finds known public marker; absence in encrypted bytes is supporting evidence only |
| Temp/statement journal | Compile setting3 verified; runtime fixture missing | Runtime/file observation plus provider evidence demonstrates declared no-spill policy; headers/operational metadata assessed |
| Catalog/profile independence | Public namespaces prepared; actual encrypted key scopes not executed | Distinct keys, no cross-scope access or catalog bootstrap bypass |

No full EXP-03 or existing case outcome is changed.

### Key-binding interface review

[Compile-only fixture](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/harness/key_binding_compile_fixture.c) type-checks against this candidate's generated sqlite3.h with SQLITE_HAS_CODEC enabled. Final [syntax record](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/key-binding-syntax-check.json) has returncode0; it was not linked or executed.

Interface: db pointer and mutable temporary32-byte buffer owned by the isolated native worker; reject null/wrong length; invoke sqlite3_key(db,buffer,32) directly; no string/hex/SQL/URI interpolation; clear the caller temporary buffer with the SDK-declared memset_s contract and check its return. Initial explicit_bzero use was undeclared on this SDK; its compile failure is preserved and the fixture was corrected to the actual header surface.

Pinned src/sqlcipher.c:1856–1992 uses PBKDF2 for ordinary32-byte input; raw-key handling requires distinct hex-blob lengths/syntax. Source3810 onward copies/binds key material; derivation may occur on first access, so sqlite3_key success is **not authentication success**. Future qualification must read authenticated schema/identity and verify actual settings. No production raw-key reinterpretation is approved.

Wiping one caller buffer does not prove provider/Swift/Data/allocator/CPU/swap/crash-copy erasure. Provider retains its own context until derivation/close; review exact copy/close/error lifetimes and no secret String conversion. No volatile DIY crypto or hand-written primitive was introduced. Domain/Ports receive opaque lease/outcome values; only native/Persistence internals may see key bytes; Core policy validates scope/generation, UI and WebKit never receive the SQLite key. No generic SQL path is exposed.

## 3. Workstream B — Keychain and recovery fixtures

### Native Keychain feasibility

Inspected native configuration: bundle internal.vezham.browser.foundation; Swift6/minimum26; manual ad-hoc Debug setup, Release identity unconfigured; App Sandbox/Hardened Runtime enabled; entitlement is app-sandbox only. Three production AppKit Ready-host sources have no Keychain integration. [Native identity/config inventory](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/native-identity-and-registry-feasibility.json).

**Actual Keychain tests: none. Blocked.** Do not launch a command-line script under a different identity and credit it as the browser's device-bound Keychain test. The task forbids new signing/entitlement/access-group/provisioning changes and required native user-action improvisation.

Prerequisites: an explicitly authorized stable signed isolated identity with correct default access group/data-protection Keychain behavior, exact SecAccessControl/WhenUnlockedThisDeviceOnly+userPresence settings, fresh LAContext and native interaction scope, disposable item ownership/cleanup contract. Missing/denied/cancelled/unavailable and normal/profile/catalog/generation separation must then be actually observed. No personal Keychain item was read, created, reset or deleted.

The supported design remains device-bound normal KEK plus independent recovery; no unprotected normal-access shortcut. SDK declarations are not runtime ACL evidence. Lock/unlock key invalidation and key-version binding remain unqualified.

### Independent recovery fixtures actually executed

[Swift validation script](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/harness/RecoveryVectors.swift) uses existing Apple CryptoKit AES-GCM/HKDF; it implements only a bounded format/codec fixture and invokes platform primitives. It runs in the existing Swift interpreter, creates no signed app and never calls Keychain/WebKit. Random synthetic R/DEK/normal-wrap inputs remain transient memory. No keys, key hashes, printable secret/capsule or recoverable key-ring bytes are retained in evidence.

Current [runner](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/recovery-fixture-run.json) and [29 observation records](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/recovery-fixture-observations.json) show:
- Platform AEAD roundtrip; canonical codec roundtrip; VXKE structural serialization; normal/recovery encrypted payload agreement and normal-secret mismatch rejection.
- Wrong recovery secret, wrong profile, catalog/profile scope-kind, modified tag/ciphertext/AAD/key identifier, truncated capsule, unsupported format and unknown critical slot-field rejection.
- Missing current DEK version; noncanonical integers, duplicate keys, indefinite encoding, excessive depth/length and trailing bytes rejection.
- Printable Base32 length/checksum/encoding checks and in-memory kit/file capsule interoperability.
- An encrypted capsule was written to an owned temporary file, read back and authenticated with identity/key-ring validation; mode0600 checked. Secret R/DEK never written. The file was removed by the runner; subsequent [cleanup inspection](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/recovery-fixture-cleanup-check.json) found no matching fixture filename.

All29 final scoped observations were satisfied, **not a PASS of EXP-04 or an acceptance criterion**. They are not new case IDs. No database records were restored, no independent Mac/Keychain environment was involved, and no printed/export custody workflow was exercised. VXKE validation is structural plus slot controls, not a fully qualified production envelope container/parser. Suite1 is fixed; rejecting an unknown critical field is not comprehensive future-algorithm negotiation evidence.

The test codec is not a newly approved production CBOR dependency. [Independent Python structural check](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/public-cbor-interop.json) decodes only a public non-secret CBOR structure from Swift and compares canonical bytes; it does not establish full recovery-format interoperability across independent crypto implementations. Checksum byte framing used by the fixture is explicitly encoded in its source; the final public kit framing still needs independent specification/vector review.

Initial compile errors and an interpreter trap are retained. Phase checkpoints localized the trap to zero-based mutation of a Data value whose collection indices need not start at zero; the fixture now mutates startIndex. A later fixture review separated slot kind from profile/catalog scope kind and added normal/VXKE controls. Those are fixture corrections, not product/crypto primitive fixes or erased failures. Existing original EXP-01/02/03/04 outcomes are untouched.

### Offline recovery minimum reproducible setup — prepared only

Required: pinned qualified provider+binding; encrypted synthetic profile/catalog with known scope/key versions and records; authenticated matching VXKE/VXRF/kit inputs; independent destination Mac whose Keychain lacks source items; demonstrable network isolation; scoped native destination authorization; preserved source/archive/existing destination; explicit conflict handling; readback/decrypt/database identity/integrity/record verification for all retained versions; native destination KEK provisioning separately authorized. Existing source Mac cannot substitute for cross-Mac qualification. **This setup is not yet provisioned; EXP-04 remains Blocked.**

## 4. Workstream C — original stores and observability

Original A abb4ca2d-33dc-4d25-9c16-d135202c03e3 and B9ec735a8-b9eb-416c-994b-4b299c5ee5f5 remain logically **Unknown**. Exact-path [before](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/original-store-before.json)/[after](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/results/original-store-after.json) hashes retain A absence and B38-file presence. Absence is not completed removal; presence is not intact logical contents. No store was opened/initialized/recreated/deleted/moved/renamed/repaired, and protected container boundaries were not bypassed.

### Noncreating registry feasibility

Supported API: WKWebsiteDataStore.fetchAllDataStoreIdentifiers / asynchronous allDataStoreIdentifiers. It can enumerate without init(forIdentifier:), which may create a store. Existing retained signed harness exposes seed/verify/cleanup, not enumeration-only. Same valid application identity/container is required; invoking Swift under a different identity cannot prove the original namespace.

**Registry inspection actually performed: none. Blocked.** The task's signing prohibition prevents modifying/re-signing the existing harness; its current cleanup mode is not a safe inspection tool. Exact prerequisite: authorized same-identity read-only enumeration mode with verified signature/container and a procedure restricted to the two known UUIDs, no init/remove calls. No new UUIDs were created to bypass original-state readiness.

### Future per-store lifecycle observability design — not executed

Use existing ISO-001/EXP-01 route; no new case IDs. Future diagnostic needs a separate explicit readiness decision, NEW UUIDs and no operations against originals. Structured event envelope: run UUID, monotonic event sequence/time, process PID/start token, store UUID, operation UUID, view/owner generation, phase, coarse outcome/error and public-API context. No page URLs/keys or user content.

| Checkpoint | Required evidence / completion rule |
|---|---|
| Fixture identity/creation | Predeclared NEW UUID/native identity and noncreating registry-before; create only registered fixture scope; record actual API completion |
| Store/view ownership | Registry of all strong store/config/view/window/delegate/service owners, with weak lifetime sentinels |
| Navigation/service cancellation | Exact navigation/service IDs, stop/cancel requests and completed/inflight outcomes; cancellation is not rollback |
| Delegate/handler/continuation/task retirement | Remove exact delegate/script handler/timer/subscription references; resolve continuations once; reconcile pending tasks |
| Reference release | Exit owner scopes, clear strong containers/locals, record weak/deinit evidence; no arbitrary sleep as proof |
| Removal invocation | Per-store before-call event flushed before public remove API; verify no unrelated/unknown UUID |
| Callback entry | Distinct per-store callback-enter event, correlated process/operation |
| Callback completion/error | Record success/coarse failure and operation completion exactly once before any next store call |
| Registry after completion | Noncreating enumeration in same identity; compare only registered new IDs; error/absence distinguished |
| Scoped physical state | Read-only exact fixture path/hash observation, secondary to API completion; never direct engine-file deletion |
| Final per-store result | Aggregate only its own checkpoints; missing/crash/timeout remains inconclusive/incomplete, never inferred pass |

A watchdog deadline may stop a run but cannot prove quiescence. A crash terminates it; preserve last flushed events, source/binary/OS/framework identity and errors; no automatic retry, manual deletion or new same-UUID recreation. Unknown ownership/state stops cleanup. No such design was launched here.

## 5. Consolidated status and existing traceability

| Item | Current classification | Exact remaining decision/prerequisite |
|---|---|---|
| Candidate source/tree integrity | **Verified** relative to immutable official Git objects | Publisher signature trust/legal/security qualification still incomplete |
| Two arm64 target26 static archives | **Prepared; local repeatability verified** | Runtime provider/crypto/artifact tests and supported-platform qualification separate |
| Catalog/profile/main/WAL/SHM/journal controls | **Prepared, synthetic plaintext only** | Encrypted fixtures/native binding/configuration not exercised |
| Key binding | **Compile-checked; not executed** | Actual open/auth/settings/lifetime/zeroization review |
| Recovery-format/CryptoKit fixtures | **29 bounded observations satisfied** | Independent full format/custody/database/cross-Mac qualification missing |
| Native Keychain | **Blocked; not executed** | Identity/signing/ACL/native user-action prerequisites |
| Original-store registry inspection | **Blocked; not performed** | Same-identity noncreating tool without forbidden signing/actions |
| New-UUID lifecycle diagnostic | **Designed; not executed** | Separate explicit readiness decision after original-state/environment prerequisites |
| Historical EXP-01 | **FAIL unchanged** | Original cleanup and framework-crash findings retained |
| Cleanup-only follow-up | **INCONCLUSIVE/crashed unchanged** | No new cleanup inference |
| EXP-02 | **INCONCLUSIVE unchanged** | Full private-product lifecycle absent |
| EXP-03/04 | **BLOCKED unchanged** | No separately authorized full campaign; not all prerequisites met |
| EXP-05/06/07/08, SVC-01–05 | **BLOCKED unchanged** | Existing integration/platform/recovery prerequisites remain |
| AC01–15 / REQ-21 | **No new pass; StageC separate** | No AC16 or release authorization |

Existing154 validation cases+11 experiment-reference rows=165 traceability rows; all individual mappings/outcomes preserved. Fixture observations are subordinate preparation evidence, not new IDs or acceptance passes. REQ-05/06→SPEC-04→CRYPTO-001/EXP-03; REQ-07→SPEC-05→KEY-001/002/EXP-04; REQ-08/22→SPEC-07/08→LOCK/ISO/BACKUP routes retain their exact matrix assignments. PERM-016 remains AC09/AC14; RECOVERY-010 remains OP-04. Owner decisions/WS01.1/ADRs/F01–17 unchanged.

## 6. Commands, artifacts and limits

Actual command classes:
- Read-only Git baseline/status, canonical/source/config/header inspection; official metadata/API/source retrieval and complete archive-to-tree blob verification.
- configure --help; isolated configure/make static build twice; nm/lipo/otool/strings inspection. Exact toolchain/environment/output records retained.
- Python synthetic plaintext detector preparation; clang -fsyntax-only key-binding check.
- Swift interpreter synthetic recovery vectors; independent Python public CBOR check; transient-file cleanup check.
- Exact original-store read-only before/after hash inspection and final documentation/preservation audit.

No database/provider runtime campaign, native Keychain/auth prompt, WebKit registry API call, signed app creation/codesign command, original-store mutation or production dependency operation occurred. Generated static archives/fixtures remain in the task-specific /private/tmp area with source/build hashes; no secret-bearing capsule/secret/key hash is in evidence. Source archives/manifests/license/metadata and all scripts/results are [here](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/). [Commands/evidence index](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/commands-and-artifacts.json), [final audit](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/qualification-audit.json), [file inventory](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/changed-files.json).

## 7. Next bounded task and authorization checkpoint

Recommended: review the pinned static candidate provenance/trust/license/security and fixture gaps, then prepare an explicitly scoped provider-runtime/key-binding/artifact qualification procedure under existing EXP-03 before any full execution authorization. Require native identity/ACL permission and independent destination provisioning for EXP-04. Separately authorize a same-identity enumeration-only observability tool if desired; do not modify/sign the old harness or remove originals under this task.

Do not count these source builds or fixture observations as completed M1 validation. Product implementation, release, signing/notarization/distribution, original-store cleanup and full/downstream campaigns remain outside scope. Ending branch/HEAD and exact changed paths are verified by the final audit; no commit or push.


## 8. Checkpoint completion and remaining boundaries

Starting and ending HEAD are f5733fabeee1b0eb559d472c6c86f317b74d8108 on timeline. Working tree now contains this new report/evidence and link-only edits to README.md, m1-source-catalog.md and m1-validation-readiness-remediation.md. Nothing is staged/committed/pushed. The final audit records all35 satisfied documentation/preservation checks; these are not35 product/security tests.

Exact [created/modified path/hash inventory](../../evidence/20261108T113403Z-m1-provider-fixture-qualification/changed-files.json) distinguishes source/harness/results from the three maintained documentation changes. Source archive/static binaries and public database control fixtures are in the run-specific temporary workspace with retained hashes; they are not added to production dependency resolution. Historical outcomes and original store/evidence bytes are unchanged.

Per-experiment blockers: EXP-01 needs same-identity noncreating registry and per-store lifecycle observability with a separate readiness decision before any new-UUID run; EXP-03 needs publisher/provenance/security acceptance, executed key binding/settings and actual protected artifact/fault fixtures, followed by separate full-campaign authority; EXP-04 needs native signed identity/ACL/user-action permission, independent destination and authenticated encrypted-record restoration—not only format observations. No acceptance, implementation or release approval is inferred.

## 9. Subsequent provider trust/runtime gate — 2026-11-08

[Trust and runtime gate assessment](m1-provider-trust-and-runtime-qualification.md) starts from the committed checkpoint 7fb95f769f9af0000997c2d193b3d3675d0ca6a6 (parent f5733fabeee1b0eb559d472c6c86f317b74d8108). Fresh source/archive checks agree with all2325 retained file records and both static archive hashes. Independent publisher authenticity remains BLOCKED; the published support key does not match the tag's claimed issuer, and signature verification was not established. The gate therefore stopped before any runtime encryption, storage-surface or interruption test. This subsequent evidence does not rewrite this report's historical results, qualify EXP-03, or authorize production integration/release.
