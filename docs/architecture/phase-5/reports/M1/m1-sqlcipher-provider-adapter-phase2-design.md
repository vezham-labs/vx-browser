# M1 SQLCipher provider adapter · Phase 2 design and runtime safety review

Version 1.0 — Proposed, finalized 2026-11-09 (Asia/Kolkata); review opened 2026-11-08 UTC. **Design-only; implementation and runtime execution are not authorized by this review.** Baseline `timeline` at `384f200f7cda567d6782df46aea322faeab54fb7`, parent `43f57789a32fed9fa3e3c6a2926e5aceadb9c029`.

[Implementation stages](m1-sqlcipher-phase2-implementation-plan.md) · [50-case PQR crosswalk](m1-sqlcipher-phase2-pqr-crosswalk.md) · [Evidence and preservation audit](../../evidence/20261108T175705Z-m1-provider-adapter-phase2-design/README.md).

## 1. Review boundary and evidence hierarchy

This is the proposed native qualification adapter, not production BrowserPersistence. No provider-linked image was launched, no provider function called and no database opened during this task. Source inspection can establish control flow and intended checks; it cannot establish runtime encryption, effective settings, successful cleanup or recovery.

The inspected Phase 1 worker is infrastructure evidence. Its final attempt `attempt-171322765352` records 119 passing assertions, zero failing assertions, fake-provider execution only, and static inspection of a separately linked image. Earlier development attempts are different revisions and are not aggregated. Its Nx launcher stalled before task execution; the documented direct Python entry point succeeded historically. Neither route was rerun here.

The vendor signed archive and complete 2,325-file correspondence supplied the prior source-authenticity PASS. The separate Git tag signature still has an unknown key. Local matching static builds and Phase 1 link inspection do not establish runtime identity or provider qualification. See [publisher evidence §8](m1-sqlcipher-publisher-authenticity-evidence.md#8-vendor-archive-cryptographic-verification--2026-11-08-current-checkpoint), [provider readiness](m1-sqlcipher-provider-runtime-readiness.md), [Phase 1 report](m1-sqlcipher-worker-phase1-implementation.md), [existing worker design](m1-sqlcipher-worker-and-key-binding-design.md), [encryption contract](m1-persistent-profile-encryption-specification.md) and [key/recovery contract](m1-keychain-and-independent-recovery-specification.md).

Current OD-R01–OD-R20, WS01.1, historical decision meanings and owner-decided OP-01–OP-04 remain unchanged. ADR 0001 remains Proposed with conditional WKWebView acceptance; 0002 remains Accepted; 0003–0005 remain Proposed. macOS 26 minimum and final-release gates remain mandatory. Host 27.2 results would be discovery only. CEF remains evaluation-only; Aura, production Tamizhi, mandatory cloud and public distribution remain excluded.

## 2. Architecture and component ownership

| Component | Proposed responsibility | Must not own or imply |
|---|---|---|
| BrowserDomain / BrowserPorts / BrowserCore | Domain policy, opaque scope/lease/operation identity, typed results and authorization | Raw keys, SQLite handles, SQL, file paths or provider error text |
| Native qualification supervisor | Registered owned root/resources; process and lease admission; key-frame transfer; deadlines; durable intent/quarantine; result fencing | Authority from a UI path, stale generation or worker readiness alone |
| Worker control loop | Parse bounded versioned frames; scope/sequence checks; cancellation/deadline delivery; protocol replies | Concurrent connection use or publishing provisional data |
| Worker provider executor | Sole connection/statement/transaction owner; configuration; bind/authenticate; typed fixture operations; close | Generic SQL service, arbitrary ATTACH, key SQL, implicit retry/reset |
| Observer/confinement VFS | Identity-bound file access, phase write fence, complete artifact tracing and deterministic injected faults | Encryption implementation or proof of OS-wide confinement |
| Evidence controller | Public synthetic manifests/oracles, redacted traces, artifact hashes and final disposition | Secret material, unbounded diagnostics, production backup or custody authority |

Use one worker per catalog or persistent-profile scope and one ordinary connection per worker. The catalog has its own key and cannot share a profile connection. Private contexts are rejected before path resolution, resource acquisition or provider initialization. A connection is never reassigned to another profile. The qualification subprocess does not change the approved same-process Host/Core product direction.

Use one serialized DB executor and a small control loop because a synchronous SQL call would otherwise prevent Phase 1's polling loop from receiving cancellation. The control loop may request interruption only through a lifetime-pinned handle under a defined synchronization barrier; close cannot race interrupt. Progress callbacks read an atomic cancellation/deadline flag and cannot re-enter SQL or perform protocol/file I/O. No connection pool or parallel transaction executor is proposed.

A later quiesced snapshot/rotation operation may need a second connection for a new same-profile destination. This is an explicit maintenance exception, not general concurrency: same scope, separate resource/key-version identities, one serialized executor, both handles tracked, no concurrent normal work. The second key channel and promotion contract must be reviewed before R10–R12 are eligible. Their absence cannot be hidden by reusing the Phase 1 opening frame.

## 3. Pinned provider, ABI and runtime lifecycle

### 3.1 Fixed inputs and distinct kinds of identity

- Official source pin `355d4db92d3404e71faa8088d071a71d767807f4`; SQLCipher Community 4.20.0; SQLite 3.54.1.
- Retained archive `/private/tmp/vx-m1-provider-fixtures-20261108T113403Z/provider-build-1/libsqlite3.a`, SHA256 `ac0fed4b3c47b6259a87504b318fd4546018c880b0d60331a47e92c3f7a9856c`.
- Matching generated header `provider-build-1/sqlite3.h`, SHA256 `e36eb6ed4de77e56a633866a8f84ed339785662d0cf79cf099f420b638bf28ec` under the same retained root.
- Expected generated SQLite source ID: `2026-10-16 14:45:20 555e07ef33f69a0957d24d8e555b702464a131d6f1607f4c3c1e4551e8e6alt1`.

Compile evidence must identify this header, arm64/macOS deployment target 26.0, C ABI/int length, include precedence, build flags and compiler/SDK. Link evidence must attribute provider symbols to this exact static archive and rule out direct or transitively selected stock SQLite for these calls. The CommonCrypto/Security and CoreFoundation system dependencies must be recorded. No platform SQLite header or library fallback is permitted. Relevant pinned flags are `SQLITE_HAS_CODEC`, `SQLCIPHER_CRYPTO_CC`, `SQLITE_EXTRA_INIT=sqlcipher_extra_init`, `SQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown`, `SQLITE_OMIT_LOAD_EXTENSION`, `SQLITE_TEMP_STORE=3`, `SQLITE_THREADSAFE=1`.

Pinned `src/sqlcipher.c:99–103,1172–1178` formats the expected full `cipher_version` value as `4.20.0 community`; the Phase 1 binary substring `4.20.0` does not establish that getter result. Runtime evidence, only after separate authorization, must compare `sqlite3_libversion`, `sqlite3_sourceid`, `sqlite3_threadsafe` and required compile options against the retained header/build manifest. Provider-name and effective cipher-setting getters require a keyed codec context. The version getter itself does not require that context (`sqlcipher.c:2940–2954`), but still uses a SQL handle; this plan deliberately defers all per-handle PRAGMAs to G. Do not describe a per-handle probe as the approved Stage A no-handle/no-DB slice. Required crypto provider name is `commoncrypto`. The pin's `crypto_cc.c:50–82` can return provider version `unknown` when bundle version lookup fails; retain this limitation plus the OS build and linked system identity. A missing/wrong provider name is a failure. A documented `unknown` provider-version string alone is not evidence of a different provider or a precise crypto module version. No FIPS certification is inferred.

### 3.2 Lifecycle

Process lifecycle: `Cold → Initializing → Initialized → Stopping → Stopped`; failure or an uncertain transition enters `Poisoned → Retire/Quarantine`. Admit only one initialization sequence and no retry after partial failure in the same process. Explicit `sqlite3_initialize` invokes the compiled SQLCipher extra-init hook; do not also call that hook directly. Verify success before registering/using the reviewed VFS. Duplicate requests return the already established state only when identity and sequence match; they cannot rerun global initialization.

Pinned `src/sqlcipher.c:482–661` contains provider setup/partial-failure cleanup; `:661` onward contains extra shutdown. More importantly, `:412–450` registers Apple `__mod_term_func` cleanup and `atexit` cleanup. Merely launching and exiting a provider-linked image may execute provider finalization even when main calls no SQL API. Future Stage A authorization must explicitly cover linked-image launch, initialization, identity calls and shutdown/finalizers. The Phase 1 image remains unlaunched here.

A failed init never admits a database/key operation. Record only numeric/typed stage failures, stop admission, perform only source-reviewed safe partial cleanup, retire the worker, and preserve ambiguity. If init stalls, the registered child may be terminated under the finite future fault plan; no claim of successful library shutdown follows. Normal shutdown requires all handles/resources retired before `sqlite3_shutdown`; check its return and worker exit separately. Global hooks being idempotent in source is not a runtime cleanup proof.

## 4. Phase 1 IPC changes required before real operations

Phase 1 version 1 has a length-prefixed 113-byte control body and a separate 133-byte key frame. Identity includes run, worker, scope kind/UUID, store UUID, lease generation and DEK version; operation UUID and sequence protect messages. The worker validates then wipes the key frame before `ProtocolReady` (`worker.c:113–119`). That is correct for a fake endpoint and insufficient for actual binding. `ProtocolReady` must never be relabeled as authenticated database readiness.

The proposed real endpoint uses a separately negotiated version 2, retaining the scoped fixed-width key fields and 32-byte key semantics but rejecting v1 real-operation requests. Phase 1 remains a separate fake conformance baseline. Version-2 control serialization still needs a frozen byte-level contract before implementation: typed Create/OpenExisting, registered resource ID, full 128-bit operation ID, deadline, expected revision, requested key version, state transition and durable outcome/receipt. A resource token is not a caller-provided path. Define exact frame sizes, limits, canonical encoding, unknown-field rejection and response states in Stage B; no permissive extension of the existing argument word.

Keep separate `ProviderInitialized`, `KeyApplied`, `DatabaseReady`, cancellation acknowledgement, transaction outcome and `CleanupConfirmed`. Only `DatabaseReady` admits normal operations; `CleanupConfirmed` is a separate terminal cleanup result. `supervisor.h:13–20` and `supervisor.c:136` currently reduce request operation IDs to one byte; the real API must retain the whole UUID. Cancellation acknowledgment cannot mean rolled back, and `DONE` cannot stand for a durable receipt without a committed DB record.

Opening key delivery remains a single exact frame plus EOF on a dedicated inherited descriptor; no argv/env/log/SQL key transport. A v2 frame may retain the 133-byte field layout with its version changed to 2; this is a framing proposal, not a new key format. Additional rotation keys require separately scoped one-shot channels and an explicit reviewed maintenance protocol. Unexpected extra bytes, replay, timeout, wrong channel/context, stale lease or mixed versions fail closed and retire owned key buffers.

## 5. Key binding, authentication and the pre-read gate

### 5.1 Required sequence

1. Reject private/foreign/retired scope before paths or provider initialization. Verify the native manifest, active lease, requested resource identity, operation and key version. Only then run or confirm Stage A initialization/process-identity checks under the reviewed diagnostic controls. Do not deliver a key until that initialization phase is complete.
2. Receive and validate the complete scoped key frame and exactly 32 bytes; embedded zeros must survive. Missing/null/31-/33-byte input is rejected without path access or any database/key API call. Keep the key in one owned mutable worker buffer until the length-explicit `sqlite3_key(db, bytes, 32)` returns. Never interpret it as a C string, raw/hex SQL key or a new cipher suite. Normal/recovery unwrapping remains outside this worker design; only synthetic keys are proposed for future qualification.
3. Acquire/create the registered resource under the fences below; Stage A initialization has already completed. Track a non-null handle even on open failure; no other owner may use it. Install default-deny operation/authorizer rules before any startup SQL. Runtime feature getters on the handle use a strict allowlist.
4. Bind once, then clear received frame/scratch on success or failure with the reviewed non-elidable wipe primitive. Pinned `sqlcipher.c:1372–1385` copies input into provider-owned memory. A successful return establishes **KeyApplied**, not successful KDF/read/authentication. Provider-owned copies remain a separate lifetime until codec/connection teardown.
5. Apply the exact suite settings before schema/row SQL or derivation-triggering reads. Verify the supported getter set without treating empty results as success. Authenticate on the write-fenced existing handle by real schema access, encrypted identity row and complete bounded fixture oracle. Validate scope kind/UUID, store UUID, schema and minimum reader/writer versions, suite ID and DEK version against trusted native expectations.
6. Check every current lease/generation again before admitting work or delivering results. Only authenticated identity plus effective settings and authorized positive controls can produce `DatabaseReady`. Any mismatch retires results/keys/handles and retains existing ciphertext.

### 5.2 OPEN-01: literal no database reads before key application

The current task requires key application before **any** database read. The earlier worker design §5 allowed encrypted-header reads during handle construction; that is a material interpretation difference, not a resolved guarantee. Pinned `src/main.c:3682` calls `sqlite3BtreeOpen`; `src/btree.c:2712–2716` opens the pager and calls `sqlite3PagerReadFileheader`; `src/pager.c:4063–4081` calls `sqlite3OsRead` at offset zero. The public key API requires an existing connection. Therefore the stock call sequence does not meet a literal zero-physical-read-before-key condition.

**BLOCKED for this literal requirement.** Before affected real database execution, specify and review either a supported key-aware open path with proof of its I/O ordering, or obtain explicit acceptance of the narrower rule: no decrypted schema/row access, initialization write or readiness before binding and configuration, while explicitly allowing audited encrypted-header reads. This document does not approve that interpretation or silently waive the current requirement. Do not fabricate successful header reads, substitute a fake empty database header or patch pager/crypto internals to hide the conflict. An observer recording pre-key reads is evidence of the limitation, not compliance with the literal rule.

### 5.3 Existing-file authentication must preserve ciphertext

Omitting CREATE and later comparing hashes detects damage but does not prevent it. Read-only mode alone does not settle WAL/SHM/hot-journal behavior. Before existing-store authentication, the proposed VFS must prohibit persistent content writes, truncate, delete, replacement and writable shared-memory effects across the registered main/sidecars. Permit only reviewed non-content locking needed for a safe read. No automatic recovery writes or RW fallback are allowed before authenticated identity. A hot journal or WAL requiring a prohibited write returns `RecoveryRequired`; normal opening stops and retains all files.

After authenticated identity, a phase write-enable token must bind the same resource objects and live lease. A path swap, RO-to-RW reopen, unknown SHM behavior or unproven fence invalidates authentication and blocks admission. Any necessary reopen repeats the full gated authentication against stable identity. **OPEN-02: this enforcement and SHM design are not implemented or proven; existing-store failure preservation remains BLOCKED pending Stage E.** Preserve before/after identities, lengths and hashes of all quiescent source artifacts. Metadata changes such as locks must be classified separately from protected bytes.

Recovery, if needed, operates only on a separately authorized coherent disposable branch with original baseline preserved. Copying a live main file without its transaction state is not a coherent branch. No wrong-key/corrupt result creates replacement keys, truncates a source, deletes sidecars or adopts another database. Coarse `UnauthenticatedOrCorrupt` avoids promising a reliable distinction between wrong key and damaged input. Authenticated wrong-scope data yields `IdentityMismatch` with no published rows or write enable.

## 6. Open modes, resource ownership and creation

| Path | Proposed behavior and completion |
|---|---|
| New exclusive create | Native supervisor reserves a new regular file using exclusive creation beneath its owned root, permissions 0600/directory 0700, and records device/inode plus operation. Only that operation's reservation may be opened as new. Configure keyed suite, DELETE journaling, FULL durability and temp policy before first transaction. Atomically write test identity and initial state; durable intent and fresh-process correct-key validation precede fixture publication. |
| Existing encrypted store | Must exist; no CREATE, URI or plaintext fallback. Validate identity-bound resource; authenticate under the content-write fence; only then enable reviewed operational writes. Check actual read/write mode, not flags alone. |
| Existing path during create | Refuse before provider access, including existing zero-length files, directories, symlinks, aliases and hard links. Never interpret existence as permission to reset. |
| Incomplete creation | Operation-owned reserved/staged files remain unpublished; record all sidecars and quarantine. Restart cannot adopt an unrecorded zero-length/orphan file. Recover only through reviewed intent/identity inspection; never delete another resource. |
| Existing unauthenticated store | No normal reads or writes, no destructive fallback, coarse typed error, retire key/connection and retain artifacts. |
| Authenticated identity mismatch | Reject even if decryption works; do not migrate or relabel a foreign store automatically. |

The supervisor owns root descriptors and resource grants; the VFS must enforce descriptor-relative no-follow traversal and stable object binding, including all sidecars and root-parent identity. A native precheck followed by stock path open is a TOCTOU gap. A VFS shim that merely logs delegated pathname opens cannot claim to fix it. Reject unexpected link count/type/owner/mode, cross-root names, URI paths, replacements and undecidable identity. Exact macOS descriptor delegation/WAL mapping semantics are **OPEN-03** until Stage E design and controlled validation. Path hashes alone are not authorization.

The provider executor owns handles, statements, cursors, blobs, backup handles, transactions and cancellation pins. Every statement is registered to its operation; no borrowed handle escapes. A transaction carries a single mutation UUID, expected revision and bounded payload digest. The Core boundary's revision and receipt update belong in the same DB transaction as the mutation. Neither supervisor RAM nor a sent `DONE` message establishes commit durability. Duplicate same-ID/different-payload requests are rejected; retained same-ID/same-payload requests reconcile known receipts. No unlimited exactly-once claim after receipt eviction.

## 7. Configuration and effective-value contract

Existing encryption §4 fixes 4096-byte pages, AES-256-CBC, per-page HMAC-SHA512, SQLCipher compatibility 4, PBKDF2-HMAC-SHA512/256000 and plaintext-header size zero. This design retains the 32-byte random binary passphrase input. The following timing/readback is proposed for this exact candidate; missing getter rows, unknown options, type/value mismatches or unsupported required behavior stop readiness. Setters returning OK are insufficient because SQLite may ignore unknown PRAGMAs.

Phases: **I** process initialization; **K** keyed/configuration-only before first schema/row read; **A** authenticated existing/new identity; **W** before any write transaction; **X** checkpoint/close. For new creation, W settings apply before its first identity transaction; existing authentication keeps the write fence active. No current phase was executed.

| Setting | Apply / authority | Required effective evidence and response |
|---|---|---|
| Required build options | I; fixed candidate flags in §3 | Header/build hash and runtime compile-option APIs agree; TEMP_STORE=3, codec/CommonCrypto/hooks/extension omission verified through appropriate static/runtime sources; no undocumented option-name assumptions |
| Provider identity | I APIs, K cipher getters | SQLite/source exact match; cipher_version exactly `4.20.0 community`, provider commoncrypto, provider version recorded with §3 limitation; unsupported required getter blocks |
| Binary key | K, before startup SQL; encryption §4 | `sqlite3_key(...,32)` returns checked code; later authenticated records required; no strlen/raw-key conversion |
| cipher_memory_security ON | First K PRAGMA; technical proposal inherited from prior design | Getter 1 after provider allocator use and again after authentication; an early 0 is recorded but cannot satisfy final readiness. Global enable-only behavior and best-effort allocation handling need evidence |
| cipher_log_level NONE | K startup; technical proposal | Getter NONE, plus bounded output monitoring. Init/default device logging precedes this setting and remains a disclosure limitation requiring review before secrets |
| cipher_compatibility 4 | K before individual suite settings | No assumed compatibility getter; verify all individual effective suite fields |
| cipher_page_size 4096 | K; normative suite | Getter 4096; initialized page_size 4096; do not set logical page_size in a way that silently rewrites an existing file |
| kdf_iter 256000 | K before derivation; normative suite | One integer 256000 plus matching cipher_settings row |
| cipher_use_hmac ON | K; normative suite | Getter 1, effective setting row and eventual mutation-negative behavior |
| cipher_hmac_algorithm HMAC_SHA512 | K; normative suite | Exact named getter and settings label |
| cipher_kdf_algorithm PBKDF2_HMAC_SHA512 | K; normative suite | Exact named getter and settings label |
| cipher_plaintext_header_size 0 | K; normative suite | Getter 0 plus future artifact assessment; salt/header metadata not described as encrypted content automatically |
| cipher_settings | K and final A | Exactly six recognized distinct suite-setting rows in this pin; values agree with individual getters; record returned text with no secrets |
| foreign_keys ON | W outside transactions; existing contract | Getter 1 and bounded invalid-child negative fixture; no silent disabled constraints |
| temp_store MEMORY | Before any applicable SQL workload; existing contract | Getter 2 and build TEMP_STORE=3 plus observed transient coverage; spill/unknown path blocks |
| journal_mode DELETE then WAL | W; proposed new-create path / existing normal WAL contract | New reservation begins DELETE, then authenticated mode transition; operational WAL returns wal. Separate rollback diagnostics return delete. Never OFF/MEMORY fallback. Existing auth may inspect mode but cannot change it under the write fence |
| synchronous FULL | W; existing proposed qualification contract | Getter 2 per participating connection; unknown/lower value stops |
| fullfsync ON | W; technical proposal | Getter 1 and delegated sync trace; does not establish physical-power-loss durability |
| checkpoint_fullfsync ON | Before checkpoints; technical proposal | Getter 1 and actual checkpoint sync trace |
| wal_autocheckpoint 0 | W; deterministic harness proposal | Getter 0; explicit parent-scheduled bounded checkpoints; unexpected automatic checkpoint invalidates fault placement |
| busy timeout 0 | After handle setup; deterministic harness proposal | C API result, busy_timeout getter 0 and BUSY fault route; caller may issue a separately identified bounded retry, never an unbounded worker retry |
| mmap_size 0 | Before reads/mappings; technical proposal | Getter 0 plus no content xFetch mapping; SHM is a separate path, not disabled by this setting |
| No dynamic extensions, ATTACH, DETACH, key/rekey SQL, arbitrary SQL/file PRAGMAs | Static and default-deny executor/authorizer | Forbidden-operation controls; startup whitelist limited to the reviewed setting names; public backup C API is a separately reviewed maintenance operation |
| Integrity checks | After authenticated fixture creation, and disposable corruption branches | Record cipher_integrity_check and integrity_check independently, exact complete expected records and negative controls; empty cipher error rows alone cannot prove valid/authentic input |
| Close/checkpoint | X; real lifecycle contract | Normal quiesced WAL TRUNCATE; checkpoint-fault FULL; rc and log/checkpoint counts retained. BUSY/incomplete checkpoint never becomes a clean success |

Memory-security, sync, mmap, timeout and checkpoint choices remain proposed engineering settings requiring review and runtime evidence. This task does not promote them to owner decisions or waive any mandatory requirement.

## 8. Filesystem observation, confinement and plaintext detection

**Proposed decision: a reviewed observer/confinement VFS is required for the first database slice.** A polling directory scan, system file trace or final hash alone cannot reliably observe short-lived/unnamed writes, shared mappings, block writes before authentication or inject exact failure ordinals. A wrapper over the platform VFS is a starting design, not sufficient proof of race-free open or SHM fencing. No VFS is implemented here.

Observe `xOpen/xClose`, reads/writes, truncate/sync/delete/access/fullpath, locking, file-control, fetch/unfetch, SHM map/lock/barrier/unmap and return codes. Record artifact ID, stable resource identity, public operation/scope/lease, phase, monotonic ordinal, offset/count/flags and normalized error. Preserve gap/overflow detection and bounded output. Instrument creation and writes even for delete-on-close and unnamed temp files. Deny alternate VFS selection and unrestricted attach. Audit provider/system direct I/O outside SQLite VFS; platform tracing and a complete owned-root inventory corroborate rather than replace VFS coverage. Unknown bypass or trace gap yields BLOCKED/INCONCLUSIVE.

| Artifact | Creation and leakage observation | Cleanup, interruption and retained evidence |
|---|---|---|
| Main DB | Registered xOpen identity; encrypted-page/header byte classification; scan synthetic markers below codec on writes and quiescent file | Before/after size/hash, key-positive/wrong-key/tamper results; preserve source on failure; no reset |
| WAL | Observe creation, every frame/header write and checkpoint | Capture while live at a reviewed barrier; no live-sidecar deletion; retain interrupted WAL with main identity |
| SHM / WAL index | Track mapping sizes/permissions, locks and write visibility; classify metadata separately; do not call it encrypted | Snapshot only at safe barriers; writable mapping before auth forbidden unless proven safe; unchanged protected bytes/final inventory; unknown mapping behavior blocks |
| Rollback journal | xOpen/write/sync/delete; page-payload marker coverage plus header classification | Capture hot-journal barrier on disposable branch, retain after interruption, recovery cannot mutate untouched baseline |
| Statement journal | Include named/unnamed and in-memory paths under bounded rollback workload | Record spill/no-spill path and delete-on-close lifecycle; absence without exercised trigger is inconclusive |
| Temp DB/sort/index | Enforce memory policy and detect any disk open/write even when path is NULL | No spill success by missing scan alone; bounded memory pressure returns typed failure; inventory after retirement |
| Provider scratch | Source audit plus actual system/VFS trace for direct/temp/log paths | Unknown path stops run; no assertion that VFS sees non-VFS I/O; retained public classification only |
| Backup/copy intermediate | Explicit exclusive destination and auxiliary artifacts; same observation layer for both handles | Staging remains encrypted and unpublished; hashes/integrity/fresh reopen before promotion; failed copies retained/quarantined |

Markers are public synthetic UTF-8/UTF-16/binary patterns with boundary-spanning and deliberately unencrypted positive controls. Detect in write buffers below codec and declared quiescent artifact bytes; never capture keys or raw arbitrary buffers in traces. A missing marker is supporting evidence only, not proof of encryption. Source/codec analysis, effective settings, correct-key round trip, independent wrong-key/tamper controls and complete I/O coverage are also required. A path with no triggered workload or incomplete observability remains unverified. Retaining raw failure artifacts is allowed only for registered synthetic data and must be bounded.

## 9. Close, failures, quarantine and restart

| Condition | Required response and remaining evidence |
|---|---|
| Normal close | Fence admission/delivery; settle transaction outcome; finish backups, blobs, statements/cursors and interrupt pins; selected checkpoint; actual `sqlite3_close` OK; clear owned buffers, close VFS resources, shutdown and reap. Report provider close, process exit and artifact disposition separately |
| Active statement/cursor | Close returns BUSY or ownership tracker refuses; retire owned resource explicitly then retry once under bounded close plan. No false cleanup while a handle survives |
| Active transaction | Decide rollback if not committed; record rollback/commit result and autocommit/receipt state; transaction destruction alone cannot imply a known acknowledged outcome |
| Busy/checkpoint failure | Stop new work, record BUSY/error and counts, retain recoverable sidecars. A closed connection can still leave recovery artifacts; report incomplete disposition, not clean checkpoint |
| Failed close | Do not erase handle ownership or reuse lease. Bounded cleanup attempt; if uncertain, retire registered child and quarantine scope/resources |
| Init/partial-init failure | No DB admission; source-reviewed cleanup, poison process, no in-process reinitialization retry |
| Authentication failure | Revoke write enable, publish no data, close/retire buffers and preserve all original protected bytes; unknown cleanup enters quarantine |
| Unexpected child exit | Fence results; record wait status and last observed phase, preserve artifacts and durable intent. Exit is not a successful close or filesystem-cleanup receipt |
| Supervisor exit | Worker detects control EOF where possible and enters quiescence. A blocked SQL call needs its cancellation/watchdog path; inherited pipes/process lifetime do not guarantee immediate exit |
| Uncertain commit | Record Unknown, never automatic replay. Fresh authenticated recovery checks mutation receipt/revision and complete expected state; retained same-ID/digest can reconcile, absent/evicted receipt may remain unknown/conflict |
| Quarantine | Persistent deny-admission state until independently verified close, resource identity and operation outcome allow explicit reviewed recovery. Never reuse a path because an old process exited |

Normalize errors at the worker boundary using the current phase and durable-outcome state, not the message text. Retain primary/extended numeric SQLite codes only in scoped synthetic diagnostics; never relay raw `sqlite3_errmsg`, SQL, paths, rows or pointers to Core/UI. A later cleanup error cannot overwrite an already known committed receipt or turn Unknown into RolledBack.

| Provider / native condition | Proposed public result and handling |
|---|---|
| Invalid frame/key length/scope/version or stale lease | `InvalidInput`, `InvalidOwner` or `StaleLease` before provider access; no path or plaintext publication |
| NOTADB/CORRUPT/AUTH or authentication/integrity failure during existing open | `UnauthenticatedOrCorrupt`; preserve source and avoid claiming wrong-key versus corruption distinction |
| Authenticated scope/schema/suite/version mismatch | `IdentityMismatch` / `UnsupportedFormat`; no write-enable or automatic migration |
| BUSY / LOCKED | `Busy`; no implicit retry or false receipt; close/checkpoint phases additionally report incomplete cleanup |
| READONLY / CANTOPEN / denied native resource | `AccessUnavailable` with a coarse scoped reason; never retry with CREATE, another path or relaxed flags |
| IOERR / FULL | `StorageIOFailure` / `StorageFull`; fence work, inspect transaction state, preserve artifacts and mark outcome Unknown if commit durability cannot be established |
| NOMEM or bounded allocation failure | `ResourceLimit` / `ProviderUnavailable`; retire affected context, keep the pre-operation source and uncertainty |
| INTERRUPT / ABORT / deadline | `Cancelled` only for a confirmed not-committed operation; otherwise separately report Committed or Unknown and fence late delivery |
| MISUSE, unexpected INTERNAL/error code, poisoned init or unproven close | `ProviderFailure` plus quarantine; no in-process retry or clean-retirement claim |

Use `sqlite3_close`, not `close_v2` success as a destruction barrier: close_v2 can leave a zombie connection with outstanding resources ([SQLite close contract](https://sqlite.org/c3ref/close.html)). No process-exit result demonstrates forensic memory erasure, hardware durability or absence of historical OS copies.

Phase 1's registry (`supervisor.c:15–40`) is process memory only. Real restart safety needs a durable supervisor intent/quarantine log before launch and before each destructive/promotion boundary, binding run/worker, child ownership token, scope/store, lease, operation/digest, resource identities, key versions, last durable phase and disposition. No secret bytes or sensitive product paths in public evidence. Atomic replacement, directory durability, bounded parsing, sequence/integrity checks and unknown-state rejection are required. A synthetic controller log may be public test metadata; its hash is not malicious-tamper authentication. Production intent authentication and secure bootstrap remain governed by the existing key/catalog contracts and are outside this worker task.

Restart must load registered intents before admitting another worker for that scope; incrementing a RAM counter is insufficient. Authenticate store/receipt state under a newly authorized key acquisition. Synthetic supervisor RAM key loss is not independent offline recovery. Old PID values alone cannot authorize killing or adopting a process after restart; validate process start/ownership or quarantine pending review. Coherent branch selection and old-key availability must survive rotation cuts. Exact durable log/reattachment format is **OPEN-04**, required before restart-dependent runtime cases.

Inspection also found Phase 1 retirement sets `reaped=true` after a wait loop without proving a successful reap on every non-EINTR error (`supervisor.c:184–199`), and diagnostic checking does a post-reap blocking read (`:202` onward). Stage F must require checked kill/wait results and bounded reap, plus concurrent bounded diagnostic draining. A provider filling a pipe or a surviving inherited writer must not deadlock cleanup. No Phase 1 source was corrected in this design task.

## 10. Snapshot, copy, rotation and recovery scope

Proposed primitive: public `sqlite3_backup_init/step/finish` between a quiesced authenticated source and an exclusive, keyed, same-profile destination. Pinned `src/backup.c:145–178` checks encrypted/plaintext mismatch; `:270–315` constrains page/reserve compatibility. This supports investigating encrypted-to-encrypted copies; it does not demonstrate correct re-encryption, encrypted intermediates, safe DEK rotation or a portable browser backup. Both handles need effective settings, full artifact observation and key/identity oracles.

Require bounded steps/cancellation, finish result, complete record/receipt/revision match, destination fresh-process validation, main/sidecar inventory and old/new key separation. Promotion needs durable intent before copy and before atomic same-volume rename, directory durability, exact old/new object identities and interrupted-state recovery. Retain old encrypted branch/key until verified outcome and declared backup/recovery dependencies permit retirement. No active in-place rekey, loose copying of live WAL/main, cross-profile ATTACH or plaintext export fallback.

R09 is one encrypted database snapshot; R10–R12 cover only the finite synthetic copy/promotion scenario once the second-key protocol and oracles are reviewed. Multi-resource catalog/profile consistency, recovery capsules/custody, external download selections, deletion reconciliation and independent second-Mac restore remain EXP-04/07 and other approved contracts. No snapshot TTL, new owner policy or deletion authorization is invented here.

## 11. Security assessment and unresolved gates

| Gate | Classification / state | Required next resolution |
|---|---|---|
| OPEN-01 pre-key physical read | BLOCKED; technical incompatibility / explicit requirement interpretation | Supported no-read key-aware open evidence or explicit approval of the narrower encrypted-header rule; do not waive implicitly |
| OPEN-02 failure preservation | BLOCKED; technical specification + experimental validation | Enforced pre-auth content/SHM write fence; dirty-store rejection/recovery rules; source unchanged under wrong/corrupt keys |
| OPEN-03 path and VFS coverage | OPEN; technical specification + experimental validation | Descriptor-bound all-artifact access, sidecar race/WAL/SHM behavior, direct-I/O audit and working detector/fault controls |
| OPEN-04 restart durability | OPEN; technical specification + experimental validation | Durable intent/quarantine, authenticated production counterpart, process ownership/reconciliation and receipt eviction behavior |
| OPEN-05 protocol and executor | OPEN; technical specification | Version-2 byte contract, full operation IDs, separate readiness/outcomes, interrupt/close fencing and second-key maintenance transport |
| OPEN-06 native bind-failure observation | OPEN; experimental feasibility | Non-secret proof of actual provider failure and buffer retirement. Fake errors cannot stand for internal allocator/codec failures |
| OPEN-07 initialization diagnostics | OPEN; technical specification + validation | Review default device logging before per-handle NONE, bounded child output, crash diagnostics and safe numeric error capture; stop on disclosure |
| OPEN-08 resource and test oracles | OPEN; technical specification before execution | Freeze per-case schema/records, ordinals, finite time/memory/storage/output limits and acceptable terminal states; no unbounded retries or disk fill |

Process separation, descriptor inheritance control and 0700/0600 modes reduce accidental access; they are not an App Sandbox or an adversarial same-user isolation proof. The current child inherits user privileges and system-library trust. A VFS cannot stop compromised worker code from issuing arbitrary syscalls. Hostile native code, debugger/root/kernel access, swap/core/crash diagnostic copies, source/build supply-chain compromise and hardware power loss are not solved by this design. No host security configuration is changed. Future launch must record and verify no-core/resource limits, permitted descriptors/environment and exact owned roots before key delivery; inability to bound diagnostics or paths stops authorization readiness.

Cross-profile prevention requires native context admission, dedicated key/handle/resource identities, authenticated DB identity and delivery fencing together. Encryption alone cannot detect relabeling when identity is not checked. Private refusal here proves only the persistence boundary, never WebKit private cleanup. Local offline operation remains required; no identity/cloud service is introduced.

Technical choices can be refined under a separately authorized engineering task. Any actual relaxation of the pre-read requirement, residual product risk acceptance or release policy change requires the appropriate explicit authority. This document does not choose one or reopen approved owner policy.

## 12. Requirement traceability, status and handoff

| Existing contract | Design sections / future route | Claim boundary |
|---|---|---|
| REQ-05, SPEC-03/04, AC05, OD-R04/07 | §§3,5–8; E/K/T cases | Candidate configuration and confidentiality design only |
| REQ-06, catalog separation | §§2,5–6; K03 | Independent catalog key/handle, not product bootstrap qualification |
| REQ-07/08, SPEC-05/06, AC06/07, OD-R08/09/18/19 | §§4–5,9–10 | Key lease/lock prerequisites; no Keychain, OS auth or independent recovery execution |
| REQ-09, SPEC-03/06, AC04/14, OD-R05/06 | §§2,4–6; corrected K14 route | Persistence refusal only; private engine/storage lifecycle remains separate |
| REQ-14/19, SPEC-12/16, AC12/14/15 | §§6,8–10; R cases | Single-store receipts/recovery/copy prerequisites; no complete portable backup or release qualification |
| REQ-21 and REQ-22 | §1,§10; separate Stage C / SPEC-08 routes | No release, WebKit protection/deletion/backup or AC08 result from PQR |

**PASS — design deliverables and 50-case planning coverage. FAIL — no new runtime failure asserted. BLOCKED — real database qualification (including OPEN-01/02 and unimplemented observation/adapter). INCONCLUSIVE — effective provider settings, confidentiality, failure preservation, real close and recovery until separately authorized evidence exists.** No PQR or canonical AC result changes.

**No real SQLCipher provider operations, database opens, encryption tests, fixtures or PQR runtime cases were executed. EXP-03 and EXP-04 remain unexecuted.**

## Primary API references

Checked 2026-11-08. Live documentation explains public contracts; the pinned source excerpts in this review's evidence control candidate-specific assertions: [SQLite open](https://sqlite.org/c3ref/open.html), [SQLite close](https://sqlite.org/c3ref/close.html), [SQLite VFS](https://sqlite.org/vfs.html), [SQLCipher API](https://www.zetetic.net/sqlcipher/sqlcipher-api/). No third-party provider behavior is presumed.
