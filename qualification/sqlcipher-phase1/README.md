# Isolated SQLCipher qualification tools · Phase 1

This C11 test tool implements the approved worker design's process, message, scope and key-frame boundaries. The executable supervisor runs the fake-provider suite. The linked qualification image is built and inspected as a binary. Its provider functions are never called by this task.

From the repository root, use the existing Nx target with a registered timestamped evidence directory.

```text
pnpm nx run m1-sqlcipher-phase1:verify --evidence=<absolute-new-evidence-directory>
```

The directory must be beneath docs/architecture/phase-5/evidence and contain the run's baseline.json. The stdlib Python entry point is also available when the package-manager launcher is unavailable.

```text
python3 qualification/sqlcipher-phase1/run_phase1.py --evidence=<absolute-new-evidence-directory>
```

Each invocation creates a new attempt directory and a fresh owned /private/tmp build directory. Earlier attempts are retained. The source pin, archive/header hashes, compiler and SDK must match the recorded candidate. It builds fake-worker, phase1-supervisor and sqlcipher-linked-worker. Only the first two execute. Native tests run through supervisor_tests.c and the real supervisor.c implementation.

## Files and responsibility

- protocol.h / protocol.c define and validate the single shared wire contract and deadline-bounded IPC.
- worker.c implements the fake provider's admission, held operation, cancellation and close states.
- supervisor.h / supervisor.c own child startup, request correlation, scope/lease registry, secret IPC, reaping and quarantine.
- supervisor_tests.c provides the executable native supervisor test driver.
- link_identity.c retains address references that force actual static SQLCipher code into the inspected image. It has no runtime call.
- run_phase1.py records exact build/inspection/test argv, outputs, linker map, input/binary hashes and results.
- project.json adds one cache-disabled Nx task without browser dependencies.

## Wire contract

Every control frame has a four-byte big-endian length prefix followed by exactly 113 bytes. The body is VXW1 magic (4), version uint16 (2), opcode uint16 (2), context (77), operation UUID (16), sequence uint64 (8) and argument uint32 (4). Integers are big-endian. Context contains run UUID (16), worker UUID (16), scope kind (1), scope UUID (16), store UUID (16), lease uint64 (8) and DEK version uint32 (4). All identity values and epochs must be nonzero. The header's enum fixes opcode and state values.

Requests require argument zero. Responses bind to the exact request and pack state into the upper 16 argument bits and error into the lower 16 bits. Native response validation checks kind, state/error semantics, context, operation and sequence. Commands START, BEGIN, FINISH, CANCEL and CLOSE are the complete Phase 1 allowlist. BEGIN holds a fake operation until explicit FINISH or CANCEL. Close through the supervisor cancels active work first.

The designed VXK1 key frame remains exactly 133 bytes. It carries its existing version, context, opening operation, length 32 and 32 binary bytes. The inherited secret socket requires EOF after exactly one complete frame. Extra, concatenated, short or mismatched frames reject. A partial frame can be cancelled and cleared without waiting for full reception.

## Lifecycle and limits

One native controller thread owns each supervisor object. The worker uses a bounded poll event loop while no SQLite calls exist. START moves to AwaitKey. Validated frame ownership moves to ProtocolReady after scratch clearing. BEGIN/FINISH/CANCEL move through Busy and ProtocolReady. CLOSE retires the worker. Fatal validation, timeouts, unexpected exit or failed cleanup produce Uncertain. Phase 1 ProtocolReady carries no database authentication claim.

The registry retains up to 128 scope/lease entries in one supervisor process. A live or quarantined scope/store refuses another child. A confirmed clean close permits a different worker with a higher lease. Worker identity reuse and stale leases reject. Each worker allows at most 32 admitted START/BEGIN operation IDs, has one active operation, and rejects replay and concurrent startup.

The worker bounds initial startup to 2.5s and partial control-frame receipt to 500ms. Native tests use 1s response deadlines and 100ms for the injected close timeout. The outer runner bounds its test command to 40s. Timeout retirement kills and reaps only the registered direct child, leaves cleanup uncertain and quarantines its scope. These are qualification-tool deadlines.

The phase1-supervisor program disables its own core files before generating synthetic key material. Children disable core files too. Child environment is reduced to LC_ALL=C and only explicitly duplicated channels/diagnostics survive exec. Empty stdout/stderr is enforced per child. No synthetic key bytes, encoded key strings or key hashes appear in evidence. Buffer clearing is observed over owned allocations. Provider memory, allocator copies, IPC kernel buffers, swap and controller-crash recovery remain limitations.

No database paths, SQL execution, Keychain binding, VFS, production-store resolution or browser integration exist in this slice. Database confidentiality and the 50 PQR cases remain for later authorization.

[Phase 1 report](../../docs/architecture/phase-5/reports/M1/m1-sqlcipher-worker-phase1-implementation.md) · [Approved design](../../docs/architecture/phase-5/reports/M1/m1-sqlcipher-worker-and-key-binding-design.md)
