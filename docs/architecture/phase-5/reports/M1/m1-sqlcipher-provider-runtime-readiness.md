# M1 SQLCipher provider runtime readiness

**NOT READY – BLOCKED** · 8 November 2026 · Baseline `670bebd4b4f7e878674e7588ddcb7e6aa4a86d32` on `timeline`.

Source authenticity passed at the preceding checkpoint. The signed SQLCipher 4.20.0 source matches the pinned commit across all 2,325 files. The team can reuse that evidence and the two matching static archives. The missing link is an isolated native worker that can authenticate a store, enforce profile ownership and expose the actual file and transaction behavior. All 50 runtime scenarios remain proposed. EXP-03 remains blocked.

## Candidate freeze

| Field | Frozen value or evidence limit |
|---|---|
| Source | sqlcipher/sqlcipher v4.20.0, annotated tag object `52252487a5cada9b430e8d4b20025790c5a6ba20`, commit `355d4db92d3404e71faa8088d071a71d767807f4` |
| Authentication | Vendor ZIP SHA-256 `a1417a5a672a2342de6ae44e08ccd68487fa3d0a43212331f4226a0d00b51b9c`. The vendor archive signature and complete source comparison establish the source binding. The separate Git tag signature remains unverified. |
| Toolchain | SQLCipher Community 4.20.0, SQLite 3.54.1, Apple clang 21.0.0 (clang-2100.4.1.1), arm64, SDK 27.2, deployment target 26.0. The observed host is macOS 27.2 build 26B123. |
| Static build | Apple CommonCrypto with Security and CoreFoundation linker flags. Both 1,651,288-byte archives have SHA-256 `ac0fed4b3c47b6259a87504b318fd4546018c880b0d60331a47e92c3f7a9856c`. A future worker must link the recorded archive and matching header and demonstrate actual symbol and library identity. |
| Compile settings | Codec enabled, CommonCrypto selected, SQLCipher extra initialization/shutdown hooks, load extensions omitted, TEMP_STORE=3 and THREADSAFE=1. The exact CFLAGS, configure arguments, paths, tool versions and reproducibility environment are in the configuration record. |
| Required suite | SQLCipher 4 compatibility, AES-256-CBC, 4,096-byte pages, HMAC-SHA512, zero plaintext header bytes and PBKDF2-HMAC-SHA512 at 256,000 iterations. Runtime settings still require measurement. |
| Connection targets | WAL, synchronous FULL, foreign keys enabled, memory temporary storage. DELETE journaling is a separate diagnostic configuration. Close and key rotation require serialization and reconciliation. |

The retained build record has an empty configure-settings summary. Its command logs and static inspection support the recorded build, and all six retained archive, header and amalgamation hashes matched on inspection. Final worker linkage, connection-setting order, memory-security activation, macOS sync settings, copy primitive and fixture schema remain open. Two identical local builds establish local repeatability. Cross-machine reproducibility and macOS 26 runtime validation remain pending.

The earlier plaintext SQLite fixtures provide detector controls. The later encryption specification governs sensitive catalog data and requires an independent catalog key. The existing engineering license review requires notice retention. Previous upstream issue records flag integrity checks with preallocation, error handling after page corruption and rekey behavior for review against this pin. These are reported risks without a local runtime reproduction. [Provider and fixture review](m1-provider-and-fixture-qualification.md) · [Publisher verification, §8](m1-sqlcipher-publisher-authenticity-evidence.md) · [Complete configuration](../../evidence/20261108T150828Z-m1-sqlcipher-runtime-readiness/provider-configuration.json)

## Key binding and ownership

| Boundary | Contract for the proposed worker |
|---|---|
| Native host and key service | Generate independent 32-byte inputs for each persistent profile and the catalog using the platform CSPRNG. Normal access unwraps the scoped DEK through the Keychain-protected KEK. Recovery uses independently held recovery material. The synthetic supervisor supplies disposable keys through a private memory channel. |
| BrowserDomain and BrowserPorts | Domain values carry scope, generation and revision. Typed ports carry bounded native leases, operations and coarse outcomes. Secret bytes and provider handles stay with their native owners. |
| BrowserCore | Validate the native caller, immutable scope and lease generation before scheduling work. Check generation and receipts again before publishing results. Refuse private persistence before resolving a path or opening a connection. |
| BrowserPersistence | A serialized worker distinguishes exclusive creation from opening an existing store. It validates the scope and key input, applies the 32-byte binary passphrase through the length-explicit C API before database reads, then authenticates the schema, scope identity, suite and key version before releasing data. Existing-file failure preserves ciphertext. |
| Failure and close | A successful key-binding call alone leaves authentication pending. Wrong keys and malformed files may yield overlapping provider errors. Return a coarse access/corruption outcome while preserving the input. Finalize cursors, reconcile commits, close connections and retire leases before reporting closure. A reopen requires fresh authority. |
| Memory and storage | The syntax fixture calls `memset_s` after binding. Its early invalid-input branch leaves cleanup ownership to be specified. Observe eligible scratch buffers before releasing them and record only a zeroization result. Provider copies, cached plaintext and OS artifacts limit erasure claims. WAL, rollback/statement journals, SHM and transient files each need their own observation. |

The proposed four targets define ownership. The inspected app contains the foundation host. Its source inventory and the syntax-only helper provide no implementation evidence for a linked persistence worker, failure supervisor or protected close barrier. A scoped adapter test can establish private-request refusal. Integrated private browsing, Keychain custody and WebKit data protection have separate validation routes. [Core contracts](core-boundary-contracts.md) · [Encryption specification](m1-persistent-profile-encryption-specification.md) · [Key lifecycle](m1-keychain-and-independent-recovery-specification.md)

## Synthetic matrix and evidence

The matrix defines **50 scenarios** under the existing EXP-03 / CRYPTO-001 route. There are 12 encryption and confidentiality cases, 16 key-binding cases, 10 tamper/corruption cases and 12 interruption/recovery cases. Each row gives its local identifier, grounded requirement and AC mapping, prerequisites, fixture, operation, expected result, failure oracle, requested artifacts and cleanup. The principal mappings are REQ-05/06/19 and AC05/14/15. Each case supports only its declared portion. The matrix proposes experimental resource caps and workload sizes for review before execution. [Case matrix](../../evidence/20261108T150828Z-m1-sqlcipher-runtime-readiness/synthetic-test-matrix.md) · [Machine-readable cases](../../evidence/20261108T150828Z-m1-sqlcipher-runtime-readiness/synthetic-test-matrix.json) · [Canonical case traceability](m1-case-level-traceability.md)

| Claim | Evidence needed for a future disposition |
|---|---|
| Encryption at rest | Bind the exact native image and effective settings to each run. Reopen with the correct key in a fresh worker and compare all expected records and identity fields. Exercise wrong-key and occupied-page tamper controls. A changed header alone supplies insufficient evidence. |
| Sidecars and temporary data | Exercise actual WAL, SHM, rollback journal, statement journal, TEMP/sort/index and vacuum paths. Capture bounded file-open/write observations including transient and unlinked files. Classify structural metadata separately from payload. Prove the marker detector works on known plaintext controls. Missing visibility leaves the surface inconclusive. |
| Profile isolation and private refusal | Apply A/B/catalog keys and native leases independently. Record rejection points and provider call counts. A private request must produce zero persistent opens, receipts and records. |
| Integrity | Use untouched controls, disposable mutated copies and fresh readers. Record page authentication results alongside structural checks and full logical data. Distinguish a poisoned connection from independent corruption. |
| Interruption and rotation | Freeze the last committed revision and receipt. Inject faults at named pre-commit, post-commit/pre-acknowledgement, checkpoint and promotion boundaries. Reopen with the correct key and reconcile the ledger. Preserve old ciphertext and required key generations until destination verification and durable promotion succeed. |
| Key retirement and cleanup | Record handle/cursor ownership, actual close results, generation fences and scope retirement. Capture only safe identifiers, booleans, sizes and artifact hashes. Unknown commit state, incomplete cleanup or missing artifacts must be reported explicitly. |

SQLCipher supplies configuration and integrity interfaces. SQLite can silently ignore unknown PRAGMAs, so the worker must assert the expected returned rows and values. TEMP_STORE=3 alone cannot qualify journals or every transient write path. [SQLCipher API](https://www.zetetic.net/sqlcipher/sqlcipher-api/) · [SQLite PRAGMAs](https://sqlite.org/pragma.html) · [SQLite temporary files](https://sqlite.org/tempfiles.html)

## Prerequisite assessment

| Prerequisite | Status | Basis and remaining limit |
|---|---|---|
| Authenticated source | PASS | Existing signed vendor ZIP and complete 2,325-file correspondence; all 56 prior manifest entries match now. No signature/source comparison repeated; separate Git tag signature remains unverified. |
| Frozen build configuration | INCONCLUSIVE | Static recipe/source/header/archive identities frozen and current toolchain matches. Final native link/connection ordering and explicit memory/macOS sync/copy settings remain G01/G03/G07. |
| Reproducible build | PASS | Existing two identical local arm64 static builds; six current archive/amalgamation/header hash checks match. Narrow local repeatability only; no rebuild or independent-machine/platform reproducibility claim. |
| Provider runtime availability | BLOCKED | Retained libsqlite3.a exists; source expected version is 4.20.0 community/SQLite3.54.1. No linked/executed isolated worker or actual runtime settings/version observation; G01. |
| Key-binding implementation/test adapter | BLOCKED | Existing helper syntax-checked historically; exact 32-byte binary-passphrase contract already specified. Bare-pointer helper is not the full scope/authentication/close/key-lifetime adapter; G02. |
| Synthetic fixtures | BLOCKED | Historical plaintext detector controls/descriptors exist; current 50 scenario definitions prepared. No encrypted profile/catalog, corruption, journal/fault or copy/promotion fixtures; G05. |
| Test harness | BLOCKED | Native serialized-worker/supervisor design requirements are documented. No runtime executable/orchestrator or reviewed lifecycle/control implementation; G01/G02/G08. |
| File inspection tools | INCONCLUSIVE | Python/file/xxd/hash/lsof/xcrun tools found; previous static artifact proof retained. No complete native transient/unlinked I/O and safe memory observations; G04. |
| Failure injection | BLOCKED | 50-case matrix defines required finite fault families and preservation rules. No implemented deterministic barrier/VFS/supervisor or fixed terminal-state oracles; G06/G07. |
| Cleanup and preservation | INCONCLUSIVE | All previous repository/evidence inputs hash-matched; owned cleanup rules proposed. Future worker/cursor/key/sidecar quiescence and fault cleanup remain untested; G02/G08. |
| Test environment isolation | INCONCLUSIVE | macOS27.2 arm64 host/SDK27.2 inspected; future minos26 candidate and owned-only policy fixed. No reviewed/exercised runtime path/process/resource/secrets manifest; G08. macOS26 and release remain separate. |
| Acceptance mapping | PASS | 50 local PQR checks explicitly decompose existing EXP-03/CRYPTO-001 routes to REQ05/06/19 and AC05/14/15. Mapping readiness only; no AC pass, new canonical case or full Keychain/lock/private-engine/backup/release claim. |

There are **3 PASS, 0 FAIL, 5 BLOCKED and 4 INCONCLUSIVE** prerequisites. The PASS entries cover authenticated source, local static repeatability and acceptance mapping. Runtime executions total zero.

## Work before runtime authorization

- **G01 · Exact native worker and link identity** — Specify exact retained archive/header, entry point, initialization hooks and link closure; review image/symbol/version probes before separately authorized adapter construction.
- **G02 · Owned key/scope/handle lifecycle and failure contract** — Define exact native ownership/lease protocol, open-existing/create split, key-before-access sequence, authenticated identity gate, typed coarse error mapping, real close barrier and scratch/provider cleanup semantics. No raw key in Domain/Ports/Core/UI.
- **G03 · Connection settings and readback oracles** — Record a reviewed setting/order/readback table per normal-WAL and rollback-diagnostic worker. Recommend memory security ON in a fresh worker; do not silently promote this recommendation to the existing contract. Reject missing required getter results, not just nonzero setter errors.
- **G04 · Complete artifact/temp observation and controls** — Review a bounded native I/O/VFS observation design covering named and unnamed files, operation phases and encryption boundaries, with functioning public-marker controls and cleanup traces. Do not capture key bytes or raw sensitive buffers.
- **G05 · Synthetic database identity and expected-state ledger** — Freeze test-only schema/version, full expected records, scope mismatch controls, source-audited mutation offsets and typed result/error oracles; preserve canonical product schema decisions.
- **G06 · Failure injection, cancellation and terminal outcomes** — Specify exact before/after commit/checkpoint/write/promotion hooks, PID/start-token ownership, emitted durable/acknowledged ledger states, bounded fault ordinals and per-cutpoint acceptable outcomes. Ambiguity prevents a PASS.
- **G07 · Encrypted snapshot/copy-and-promote primitive** — Specify and review a public provider-supported copy mechanism and its encrypted output, identity/key-generation checks, retained old branch and promotion checkpoints. Multi-resource backups, custody and second-Mac recovery remain EXP-04/07 work.
- **G08 · Owned environment, secrets channel and safe cleanup** — Review per-case owned paths/processes, exclusive scope, finite resource guards, no core dumps/key logs, failure retention and quiescent cleanup. No personal stores, real Keychain, WebKit/native prompts or host-disk exhaustion.

First freeze the build-to-worker link, open sequence, settings readback and the synthetic identity/receipt schema. Next prepare the isolated adapter, observable file operations, process barriers, fault injection and cleanup under a separately scoped engineering task. Review the resulting executable, fixtures and stop conditions before requesting bounded runtime execution. After authorization, begin with identity and detector controls, then key and scope controls, storage surfaces, tamper cases and finally interruption and rotation. An unexpected path, secret disclosure, incorrect library or destructive recovery stops the run and preserves the evidence.

This assessment used document inspection, retained-file hashes and toolchain metadata. Source authentication and static builds are prior evidence. The proposed matrix, configuration reconciliation and prerequisite assessment are the new readiness deliverables. EXP-03 remains BLOCKED. Runtime execution, product integration and final release validation require their respective authorizations. [Evidence directory](../../evidence/20261108T150828Z-m1-sqlcipher-runtime-readiness/) · [Detailed gaps](../../evidence/20261108T150828Z-m1-sqlcipher-runtime-readiness/readiness-gaps.json) · [Prerequisite records](../../evidence/20261108T150828Z-m1-sqlcipher-runtime-readiness/prerequisite-assessment.json)

**NOT READY – BLOCKED**

## SQLCipher worker and key-binding design — 2026-11-08

The proposed design supplies the scoped native qualification worker, exact static link plan, key lifecycle, settings sequence, synthetic fixture contracts and controlled fault barriers. All 50 PQR scenarios remain unexecuted. The design is ready for owner review, while implementation and runtime prerequisites remain pending. The private-refusal mapping correction is recorded for the future executable procedure. [Worker and key-binding design](m1-sqlcipher-worker-and-key-binding-design.md)
