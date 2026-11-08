# M1 isolated worker implementation · Phase 1

**Phase 1 completion — PASS**  
8 November 2026. Branch `timeline`. Starting and ending HEAD `43f57789a32fed9fa3e3c6a2926e5aceadb9c029`, parent `85bdcf55a0e671424ecd284bb26a8263c9316845`. Working tree was clean at baseline.

The qualification worker and native supervisor build successfully. The final source revision passed **119 fake-provider assertions, zero failures**. The separately built qualification image's linker map and binary inspection verify that all nine selected SQLite/SQLCipher symbols resolve to the retained pinned archive. No database or SQLCipher function was invoked. EXP-03 and the 50 PQR runtime cases remain unexecuted.

## 1. Existing architecture and implementation location

Inspected the approved worker design, runtime-readiness report, encryption/key-management contracts, Core-to-Persistence boundary, owner register, ADRs and AppKit foundation host/native configuration. The design inspection and source inventory from the preceding checkpoint provide exact canonical input references. Current baseline hashes preserve those files.

The installed Nx generator catalogs cover JS/React/workspace artifacts and have no native C11 qualification-tool generator. Added a scoped `qualification/sqlcipher-phase1` directory with an explicit cache-disabled run-commands target, following the native host's Python-runner convention. Root package manifests, lockfiles, the four-target architecture and production app code are unchanged.

The implementation reuses the design's 133-byte key frame and supplies the previously unspecified typed control wire layout in one shared protocol header/source. Both worker and supervisor compile that definition. [Tool source and commands](../../../../../qualification/sqlcipher-phase1/README.md) · [Worker design](m1-sqlcipher-worker-and-key-binding-design.md)

## 2. Implemented files and behavior

| File | Implemented responsibility |
|---|---|
| protocol.h, protocol.c | Fixed-width big-endian codecs, complete scope/lease binding, strict version/size/opcode validation, bounded stream reads/writes and owned buffer clearing |
| worker.c | Native process with Starting, AwaitKey, ProtocolReady, Busy, Closing, Retired and Uncertain states. Fake active operations, cancellation, close and selected cleanup faults |
| supervisor.h, supervisor.c | Child launch with inherited channels, minimal environment, scope registry, request/reply correlation, synthetic key transfer, close barrier, direct-child reaping and quarantine |
| supervisor_tests.c | Executable native supervisor driver with protocol, IPC, lifecycle, private-refusal, key ownership, forged-reply and failure tests |
| link_identity.c | Address references to public SQLite/codec symbols, forcing the retained static object into the inspected worker image |
| run_phase1.py | Pinned-input/toolchain checks, three builds, linker/binary inspection, fake-only test execution and retained exact argv/stdout/stderr |
| project.json | m1-sqlcipher-phase1:verify Nx target, cache disabled |
| README.md | Exact wire layout, command entry points, lifecycle, test limits and remaining coverage |

The worker has no database filename/path interface, SQL execution or Keychain call. The fake provider consists of its state and held-operation model. ProtocolReady reports successful message/key-frame admission and buffer retirement. It does not claim an authenticated database.

## 3. Protocol, identity and process ownership

Control frames have a four-byte length prefix followed by exactly 113 bytes. The body carries VXW1, version 1, typed opcode, the 77-byte identity context, operation UUID, sequence and bounded argument. Identity context binds run, worker, persistent/catalog scope kind, profile UUID, store UUID, lease and DEK version. The shared codec prevents serialization of C struct padding.

Bootstrap identity arrives as public metadata in argv. Secret material travels only through a separate inherited socket. It follows the approved VXK1 133-byte frame and requires a single complete frame followed by EOF. Context and opening-operation values must match the immutable bootstrap/admission registry. Oversized, concatenated, truncated, incompatible and foreign/stale frames reject. Both normal and partial/error key buffers are cleared under their actual allocation bounds.

The native parent refuses private scope before allocating a child or channels. The worker also returns explicit private refusal for a private control request before key admission. There is no persistent-store fallback. Tests observe the refusal result, missing child identity and missing channel allocation in the parent path, and rejection in the worker path.

The supervisor uses posix_spawn with CLOEXEC-default descriptor inheritance. All action-source descriptors are relocated above the fixed child channels before dup2 to avoid descriptor collisions. Child environment contains only LC_ALL=C. stdin is /dev/null, and stdout/stderr are captured through a private diagnostic pipe. The worker contains no logging path. Native tests require empty diagnostic output after reaping every child.

A process-local registry tracks up to 128 admitted scope/lease identities. Live or quarantined profile/store entries reject new workers. Clean closure permits a fresh worker identity with a strictly higher lease. Stale generations, reused worker identities and attempts to reuse an already-used supervisor object reject. Registry quarantine survives for that supervisor process lifetime.

Each worker admits at most 32 START/BEGIN identities and one active operation. Requests require the next sequence, a nonzero operation and argument 0. Response validation checks context, operation, sequence, expected response kind and the allowed state/error combination. A forged Ready carrying an error or illegal state is rejected by the parent.

## 4. Lifecycle and failure evidence

| Condition | Actual tested outcome |
|---|---|
| Normal startup / synthetic binary key frame | AwaitKey then ProtocolReady. Embedded-NUL synthetic material is carried without String conversion |
| Missing executable | Spawn failure produces Uncertain and prevents object reuse |
| Version/malformed/oversized/truncated control | Rejection or bounded failure with uncertain retirement |
| Worker/run/profile/store/lease/DEK mismatch | Explicit rejection, no Ready or data operation |
| Duplicate sequence or completed operation replay | Rejected. Fatal stale input retires the worker scope |
| Concurrent START or overlapping scope registration | Rejected while the original admission remains owned |
| Private scope | Parent refusal before spawn and explicit worker refusal |
| Cancellation during startup | Retired without Ready, including a partially received secret frame |
| Cancellation of active fake operation | Cancelled terminal response, state returns to ProtocolReady |
| Close with active fake operation | Parent first cancels active work, awaits its terminal response, then requests close |
| Graceful close | Closed/Retired acknowledgement plus observed exit 0/reaping confirms the Phase 1 barrier |
| Close timeout / explicit cleanup fault | Uncertain, cleanup unconfirmed, owned child retired and scope quarantined |
| Unexpected worker exit / exit during startup | Child status is recorded as failure, cleanup stays uncertain |
| Restart of a clean scope | Different worker with higher lease accepted. A stale lease rejects |
| New worker for quarantined scope | Rejected even with a newer lease |
| Forged reply | Parent rejects incorrect context, sequence, operation, response type, state/error or protocol version |
| Secret ownership and diagnostics | Allocated test/frame buffers are observed zero after clearing, and every child emits empty diagnostics |

119 is the final assertion count. It comprises 83 individually named assertions and 36 per-child diagnostic assertions, covering 84 unique assertion names. These are Phase 1 conformance assertions, not PQR runtime cases or acceptance-gate passes.

The worker event loop polls control and key channels and supports deadline-bounded partial input. No SQLite thread/cursor/interrupt implementation is needed for this fake-only slice. Close/reap uses the registered direct child. An unreaped direct child retains its PID identity, which avoids killing an unrelated recycled PID. Forced termination never supplies a successful cleanup acknowledgement.

## 5. Build and linkage verification

The existing source pin remains `355d4db92d3404e71faa8088d071a71d767807f4`. The retained vendor archive's source-authenticity PASS is reused. The separate Git tag signature's historical unknown_key limitation remains visible.

| Input/check | Actual result |
|---|---|
| Compiler | Apple clang 21.0.0, clang-2100.4.1.1 |
| Target / SDK | arm64-apple-macosx26.0, SDK 27.2 |
| C configuration | C11, -O2, -g0, -Wall -Wextra -Werror, owned source include path |
| Static archive | /private/tmp/vx-m1-provider-fixtures-20261108T113403Z/provider-build-1/libsqlite3.a |
| Archive SHA-256 | ac0fed4b3c47b6259a87504b318fd4546018c880b0d60331a47e92c3f7a9856c |
| Generated sqlite3.h SHA-256 | e36eb6ed4de77e56a633866a8f84ed339785662d0cf79cf099f420b638bf28ec |
| Linked qualification image | Same worker/protocol source plus link_identity.c and exact archive, SQLITE_HAS_CODEC, Security and CoreFoundation |
| Binary strings | SQLCipher 4.20.0, SQLite 3.54.1 and exact generated-header SQLITE_SOURCE_ID present |
| Linker map | All nine checked symbols resolve to the pinned libsqlite3.a object member |
| Dynamic dependencies | No direct dynamic SQLite dependency |
| Execution | Only fake-worker and native supervisor executed. The SQLCipher-linked image was never launched |

Verified map/symbol roots are sqlite3_key, sqlite3_open_v2, sqlite3_close, sqlite3_libversion, sqlite3_sourceid, sqlcipher_cc_setup, sqlcipher_extra_init, sqlite3_backup_init and sqlite3_wal_checkpoint_v2. nm confirms their defined text symbols in the output image. otool/lipo records and full compiler/linker commands are retained. Address references create link roots without invoking any provider function. The linked image may include provider initialization/finalization code, which is another reason Phase 1 inspects it without execution.

This proves actual static linkage and binary identity under the stated inputs. Runtime cipher/provider getter checks, loaded-image behavior and any data-protection behavior still require the later provider task.

## 6. Commands, revisions and actual results

The preferred command was attempted first.

```text
NX_NO_CLOUD=true NX_DAEMON=false NX_PLUGIN_ISOLATION=false pnpm nx run m1-sqlcipher-phase1:verify --evidence=/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/docs/architecture/phase-5/evidence/20261108T165809Z-m1-worker-phase1
```

The pnpm launcher produced no target output or attempt files for more than a minute. Read-only process inspection identified the owned launcher. It was terminated with SIGTERM and exited 143. Execution of the Nx wrapper remains unverified. No software was installed or environment configuration changed.

The same target entry point then ran directly.

```text
python3 qualification/sqlcipher-phase1/run_phase1.py --evidence=/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/docs/architecture/phase-5/evidence/20261108T165809Z-m1-worker-phase1
```

Four developmental invocations all built and passed their respective fake suites. Counts were 89, 107, 117 and 119 assertions as scope/reply validation and lifecycle coverage were added. The canonical final evidence is **attempt-171322765352**, tied to its exact final C source hashes. Earlier attempts are preserved as different revisions and are never combined into an aggregate pass rate.

The final invocation built fake-worker, phase1-supervisor and sqlcipher-linked-worker with no compiler diagnostics, verified linkage, and ran the native test command with 119 PASS / 0 FAIL. Every compiler, linker, nm, otool, lipo, strings and supervisor command has its exact argv, exit status and full relevant output in that attempt's commands.json and companion files.

[Final result](../../evidence/20261108T165809Z-m1-worker-phase1/attempt-171322765352/result.json) · [Build/test commands](../../evidence/20261108T165809Z-m1-worker-phase1/attempt-171322765352/commands.json) · [Linker map](../../evidence/20261108T165809Z-m1-worker-phase1/attempt-171322765352/worker-link.map) · [Verified identity](../../evidence/20261108T165809Z-m1-worker-phase1/attempt-171322765352/library-identity.json) · [Test results](../../evidence/20261108T165809Z-m1-worker-phase1/attempt-171322765352/test-results.json) · [Nx launcher record](../../evidence/20261108T165809Z-m1-worker-phase1/results/nx-launcher.json)

## 7. Deviations and security limits

- The design's four prospective C translation units were replaced by phase-appropriate protocol, worker, supervisor, test driver and address-only identity units. The VFS and database store units are deferred under this task's explicit boundary.
- A single poll event loop implements fake work and cancellation. The design's separate DB execution/control threads, live-handle pinning and sqlite3_close barrier belong to the later actual provider adapter.
- The control layout fills a design detail using the same shared identity context and fixed-width encoding. The 133-byte key frame remains as designed.
- Concurrent identical START requests currently receive a deterministic rejection instead of joining a pending result. This preserves one owner and is recorded as the Phase 1 behavior.
- Held synthetic key bytes are used only to exercise message ownership and transport. The suite does not demonstrate cryptographic key independence between real profile databases.
- Supervisor scope quarantine and lease history are memory-only. Supervisor-crash recovery and persistent cleanup reconciliation remain future work. Process termination closes OS resources, while successful safe cleanup still requires its own acknowledgement and evidence.
- Core files are disabled in both native test supervisor and worker before synthetic material is processed. Buffer zero checks cover owned allocations only. IPC kernel copies, registers/allocator copies, swap and OS diagnostic behavior limit erasure claims.
- The qualification tools run as native account processes, without an OS sandbox or VFS confinement claim. Phase 1 implements no database path or file-write interface. Later filesystem/VFS isolation must be reviewed before any database workload.
- The pnpm/Nx launcher stall remains a tooling limitation. Direct build/test execution succeeded using existing tools and dependencies.

## 8. Completion criteria and next phase

| Owner completion criterion | Status | Evidence |
|---|---|---|
| 1. Worker and supervisor build | PASS | Final compiler/link records for fake worker, supervisor and linked image |
| 2. Protocol tests pass | PASS | Encoding, decoding, version, malformed/partial input and request/reply validation assertions |
| 3. Fake-provider lifecycle/failure tests pass | PASS | Startup/cancellation/close/timeout/termination/quarantine assertions |
| 4. Private refusal demonstrated | PASS | Parent no-spawn refusal and explicit worker rejection |
| 5. Key-frame ownership tested safely | PASS | Bound fixed frame, foreign/stale/malformed/duplicate/partial cases, clearing observations and empty diagnostics |
| 6. Actual pinned archive linkage verified | PASS | Exact archive/header hashes, archive-member map resolution, defined symbols and binary version/source-ID evidence |
| 7. Production source/dependencies preserved | PASS | Baseline hash and scoped-change audit |
| 8. Accurate documentation/limitations | PASS | This report, source README, launcher limitation and phase-specific boundaries |

Recommend Phase 2 as a separately authorized provider-adapter slice. It should implement the approved initialization/key-binding/identity sequence, real connection ownership and observation/fault prerequisites, then undergo a new readiness review before the 50 PQR campaign. Runtime authorization must explicitly state which limited provider calls or fixture operations are allowed. This Phase 1 result supplies the process/protocol/linkage foundation only.

EXP-03, EXP-04, native Keychain/WebKit, encrypted fixtures, actual DB open/key operations and all 50 PQR runtime cases were NOT EXECUTED. ADR/owner decisions, source pin, historical outcomes and existing 165-row acceptance matrix are preserved. No production integration, signing/release, commit or push occurred.

[Created/modified files](../../evidence/20261108T165809Z-m1-worker-phase1/changed-files.json) · [Preservation audit](../../evidence/20261108T165809Z-m1-worker-phase1/preservation-audit.json) · [Evidence index](../../evidence/20261108T165809Z-m1-worker-phase1/artifact-index.json)
