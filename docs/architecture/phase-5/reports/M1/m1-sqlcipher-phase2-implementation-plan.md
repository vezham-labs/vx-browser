# M1 SQLCipher Phase 2 implementation and qualification plan

Version 1.0 — Proposed, finalized 2026-11-09 (Asia/Kolkata); review opened 2026-11-08 UTC. **Planning only; no implementation, build or runtime authority is granted.**

[Adapter and safety design](m1-sqlcipher-provider-adapter-phase2-design.md) · [All 50 PQR routes](m1-sqlcipher-phase2-pqr-crosswalk.md) · [Evidence](../../evidence/20261108T175705Z-m1-provider-adapter-phase2-design/README.md).

## 1. Baseline, scope and sequencing

Start from reviewed Phase 1 commit `384f200f7cda567d6782df46aea322faeab54fb7` on `timeline`. Its historical 119 passing fake/supervisor assertions and static link identity remain infrastructure evidence. They are not real SQLCipher or PQR results. Preserve Phase 1 source/evidence as the baseline when a separately authorized engineering task begins. No production BrowserPersistence, Core, Keychain, WebKit, browser UI or release work belongs to this plan.

Stages A–H are bounded work packages, not permission to run their commands. The safe order is:

1. **Design review:** resolve OPEN-01 interpretation/key-aware-open feasibility; review the IPC, pre-auth write fence, resource binding and exact settings. Freeze intended runtime calls and finite oracles.
2. **Separately authorized implementation/build/fake work:** A then B, C and D contract work; E observation/confinement implementation; F fake failure/retirement/restart foundation. E and the necessary F safety controls must finish before any real database slice. C/D fake/compile completion cannot waive E.
3. **Separate runtime approval:** optionally a narrowly approved A identity/init/shutdown probe with no DB; then G bounded database slices using implemented B–F. F's real provider close/fault qualification occurs inside those specifically approved G slices.
4. **H readiness review:** assess actual per-case evidence and remaining EXP-03/04 dependencies. A PQR subset is not automatic EXP execution or an acceptance pass.

This resolves the apparent A–H order conflict: E is listed as its required workstream but is an execution prerequisite of C/D database behavior. No first database open is authorized before E and the relevant safety parts of F. No runtime authorization is inferred from code review, compilation, owner architectural direction or a planning PASS.

## 2. Common entry and execution gates

Before implementation: explicit authorization for the isolated qualification files and exact changes; reviewed v2 byte contract, ownership/failure states and bounded resource specification. No production integration or dependency changes are implied.

Before any provider-linked launch: reviewed exact executable/header/archive identities, automatic finalizer behavior, descriptors/environment, no-core/resource policy, diagnostic limits, owned process manifest and allowed call list. Separate execution authorization must cover even init/shutdown-only launch. No global host settings, installs or real secrets.

Before any database slice: resolve OPEN-01; demonstrate the pre-auth write fence and stable file identity; all required artifacts observable; review source-to-VFS/direct-I/O coverage; create/open split and cleanup state machine complete; required settings/readback frozen; synthetic-only keys and root manifest; explicit positive controls and per-case oracles. Define finite wall-clock, CPU, memory, file-count, byte and output limits, operation counts and fault ordinals before execution. Unknown limits remain BLOCKED, never default to unlimited work.

A closed-world scope grants only registered temporary resources. Public synthetic fixture keys must still use the nonlogging key channel. No user profile stores, real Keychain, WebKit stores, cloud services, external user files, uncontrolled disk fill or unregistered process termination. Failed/ambiguous ciphertext and original baselines are retained; removal is a separate quiescent registered-resource disposition.

## 3. Stage A — Provider initialization and runtime identity

**Entry:** fixed candidate source/archive/header; reviewed static ABI/link closure and automatic shutdown hooks. Review compile/link/runtime evidence separately.

**Proposed work:** explicit once-only lifecycle; identity manifest/checks; partial-init poison state; typed numeric failures; reviewed shutdown after all handles retire. Use `sqlite3_initialize`/`sqlite3_shutdown`, not manual duplicate extra-init calls. Runtime SQLite/source/compile checks are distinct from SQLCipher per-handle getters.

**Acceptance / exit:** exact static identity, no stock SQLite fallback; fake duplicate/partial/stalled-init and shutdown transitions behave within limits; finalizer/atexit behavior and permitted launch effects documented. Under a separately approved init-only run, capture actual init/identity/shutdown without a DB. Cipher version/provider/settings remain unverified until keyed-handle G checks. A missing runtime observation cannot be replaced by binary strings.

**Tests/evidence proposed:** compile/link map and symbols; fake init/shutdown state probes; CFG/HASH/STATE/TRACE. Real init-only probes only if separately authorized; they are a partial contribution to E01, never its full result.

**Dependencies / risks:** source/build inputs; initialization default logs and module finalizers (OPEN-07). No DB, key API or fixture is eligible in the init-only slice.

## 4. Stage B — Key binding and connection ownership

**Entry:** A contract; v2 request/response sizes and limits frozen; private refusal and scoped resource tokens specified; full operation UUID API.

**Proposed work:** one DB executor plus bounded control loop; lifetime-pinned cancellation; single opening key frame; ownership through key-call return; wipe every terminal buffer path; separate `KeyApplied`/`DatabaseReady`; resource/lease/result-generation checks; statement/transaction registry. Maintain the existing 32-byte binary passphrase semantics.

**Acceptance / exit:** fake counters prove missing/null/wrong-length/private/foreign/retired requests never invoke provider/path access; duplicate/replay/mixed-version frames fail closed; complete UUID preserved; scratch ownership checked on success/failure/timeout; no concurrent close/interrupt; one declared owner for each resource. Real provider-copy behavior remains pending.

**Tests/evidence proposed:** fake control and owned-buffer probes, malformed frames, deadlines, late delivery, close cancellation and same-scope exclusivity; CFG/FX/STATE/TRACE/HASH. K05–K09 and K14 have admission-only routes; a successful fake result cannot qualify K01/K15/K16 provider behavior.

**Dependencies / risks:** OPEN-05 protocol details; OPEN-06 actual provider bind-failure feasibility; later two-key maintenance channel. A real bind requires a handle and therefore C/D/E/F safety prerequisites plus G authorization.

## 5. Stage C — Exclusive creation and existing-store authentication

**Entry:** B ownership; OPEN-01 resolved explicitly; E enforced object binding and pre-auth fence specified; exact test identity/receipt schema and expected records reviewed.

**Proposed work:** exclusive native reservation for a new store; never adopt an orphan; no-CREATE existing path; key/configure then authenticate schema/identity and lease; distinguish wrong/corrupt from authenticated wrong-scope; refuse recovery requiring writes before trusted identity. A read-only/immutable flag is not a universal safety proof.

**Acceptance / exit:** fake/file-model paths prove no reset/adoption/fallback; existing path blocks create; no published partial or foreign rows; wrong-key/corrupt source bytes and sidecars must be preserved in the eventual real slice; new identity/initial receipt committed and independently reopened before publication. Dirty-source recovery runs only on an explicitly authorized coherent branch.

**Tests/evidence proposed:** fake lifecycle and filesystem adversary models first; actual exclusive create/reopen/wrong-key/identity and malformed cases only under G; before/after resource identities and hashes, CFG/FX/STATE/TRACE, plus frozen expected records.

**Dependencies / risks:** OPEN-01/02/03; provider construction reads encrypted headers; hot-journal/WAL recovery and writable SHM can invalidate preservation. No real open is permitted merely because C code compiles.

## 6. Stage D — Connection settings and readback

**Entry:** design §7 table reviewed; A/B/C contract; E ready before actual getters or mode transitions on DBs.

**Proposed work:** ordered exact suite, memory/logging, temp, foreign-key, durability, journal, busy/mmap/checkpoint settings; distinguish init APIs, pre-read getters, post-auth mode changes and before-first-write settings. Verify row counts/types/values and exact pin-specific output labels; reject silently ignored PRAGMAs.

**Acceptance / exit:** fake missing/duplicate/wrong-type/mismatching result controls reject; normal-WAL and rollback-diagnostic configurations are separate; no automatic downgrade. Real effective values and behavior must match the reviewed table before data operations. Provider version `unknown` has only the documented metadata exception; no missing cipher/provider-name exception.

**Tests/evidence proposed:** compile/fake ordered-call trace and false-success PRAGMA controls; real CFG records, actual artifact traces and E01/config-dependent cases only in G.

**Dependencies / risks:** settings source audit and runtime getter feasibility; process-global memory behavior, default logging before NONE, macOS sync interpretation. These technical proposals remain evidence-dependent and are not new owner approvals.

## 7. Stage E — Filesystem observation and VFS

**Entry:** complete registered-root/artifact inventory; source-audited SQLite VFS entry points plus provider direct-I/O review; path-race and SHM threat model.

**Proposed work:** observer/confinement VFS with stable descriptor-relative identity, sidecar binding, pre-auth content-write fence, mapping policy, trace gap/overflow detection and deterministic write/sync/error barriers. Observe named/unnamed/delete-on-close temp artifacts, backup intermediates and direct-I/O corroboration. Disable content mmap while handling SHM separately.

**Acceptance / exit:** controlled fake/VFS tests detect deliberate paths, replacements, symlinks/hard links and trace loss; deny all unregistered storage and pre-auth content modification; no delegated pathname TOCTOU gap masked by a precheck; no writable SHM bypass. Positive controls prove marker detection below codec and on every covered artifact class. Unsupported mapping/path semantics block corresponding DB cases. A file not observed after exit is insufficient evidence it never existed.

**Tests/evidence proposed:** model/fake filesystem and I/O contract checks after implementation authorization; no SQLCipher needed for those preliminary controls. Provider-backed artifact behavior and real marker controls require G. CFG/FX/HASH/STATE/TRACE and FAULT for injected cases, with exact write offsets/ordinals but no secret buffers.

**Dependencies / risks:** OPEN-02/03; a logging shim alone cannot satisfy confinement. Stage E is a hard prerequisite to the first G database open and all artifact claims. No VFS was implemented in this design task.

## 8. Stage F — Failure, close and recovery qualification

**Entry:** B ownership + C/D/E contracts; durable intent/quarantine format and exact terminal-state oracles frozen. Fake safety foundation must precede G.

**Proposed work:** statement/blob/backup/transaction retirement, real-close barrier and checkpoint results; bounded kill/reap and concurrent bounded diagnostic drain; persistent restart intent/quarantine; commit receipt reconciliation and no automatic replay; deterministic failure cutpoints. Fix the inspected Phase 1 reap and post-reap diagnostic assumptions before introducing real provider blocking behavior.

**Acceptance / exit:** fake BUSY/close failure/hung init/pipe saturation/EOF/restart/late completion exercise all terminal states; cleanup cannot be confirmed from exit alone. Real close proves resources retired; checkpoint failures retain sidecars; interruption matches the frozen durable ledger or remains quarantined. Supervisor restart cannot silently clear uncertain ownership; old PIDs cannot grant kill authority. Unknown commit is preserved until authenticated receipt/state reconciliation.

**Tests/evidence proposed:** fake model and process lifecycle controls first; actual provider BUSY/IOERR/FULL/cursor/checkpoint/commit/promotion fault cases only within G's finite manifest. No repeated campaign until a new revision or new evidence warrants it. Use FAULT plus all original case evidence codes.

**Dependencies / risks:** OPEN-04/06/07/08; persistent metadata authentication for product recovery remains outside this synthetic worker. Hardware power loss and forensic key erasure are unqualified. Real F completion is assessed per approved case after G, not falsely declared before the first runtime slice.

## 9. Stage G — Encrypted fixtures and bounded runtime cases

**Entry:** separate explicit execution authorization names the reviewed executable hash, registered roots, synthetic keys, chosen PQR IDs, case counts, cutpoints, finite budgets, detector controls, cleanup/preservation and stop rules. A–F prerequisite evidence reviewed; OPEN-01/02 cannot be waived by this stage. No blanket PQR/EXP authority.

**Ordered proposed slices:** (1) applicable A init-only identity if not already separately reviewed; (2) E01 effective settings and E12 detector controls with the minimal owned encrypted fixture; (3) E02/E11 and K01–K10/K14 admission/authentication controls; (4) artifact E03–E09 and lifecycle E10/K11–K16; (5) T01–T10; (6) R01–R08; (7) R09–R12 only after the two-key maintenance/copy/promotion contract is complete. These slices may depend on each other's minimal fixtures; the approved manifest must describe that setup, never treat setup as an unapproved side effect or a case pass. K11 keeps the original ten-cycle bound. Preserve original definitions and failure oracles.

**Acceptance / exit:** each selected case has a recorded exact revision, source/build/setting identities, complete expected-state comparison, actual artifact coverage, cleanup disposition and original evidence codes. Mark PASS only for the exact executed case and scope. Missing instrumentation/oracles → BLOCKED/INCONCLUSIVE; incorrect security/data result → FAIL and stop. Do not sum Phase 1 assertions, source checks and PQR cases into an encryption pass rate. Unselected cases remain Proposed / Not Executed.

**Tests/evidence proposed:** only selected real-provider operations and fixtures, no Keychain/WebKit/product changes; CFG/FX/HASH/STATE/TRACE/FAULT as specified by the original PQR case. Keep original and mutation copies separate; never mutate user/browser stores. Fault cases use the injected ordinal, not host disk exhaustion or unregistered process kills.

**Stop rules:** wrong provider/setting, secret output, unexpected path, cross-profile/private persistence, unbounded resource use, trace gaps, source modification on rejected authentication or unexplained receipt/state immediately fences admission and preserves originals. No automatic rerun or reset to obtain a PASS.

## 10. Stage H — EXP-03 / EXP-04 readiness review

**Entry:** actual per-case G evidence and limitations; unresolved cases visible; no assumption that all 50 have run.

**Proposed work:** reconcile PQR prerequisites to EXP-03/CRYPTO-001 and relevant REQ/AC/SPEC routes; review residual artifact/provenance/license/security issues and operating-system coverage. Record exact missing coverage. Prepare an EXP-04 dependency handoff covering synthetic provider readiness without claiming Keychain/recovery custody, OS-native authentication, source-independent second-Mac recovery or envelope qualification.

**Acceptance / exit:** evidence-backed ready/blocked/inconclusive decision for the next separately authorized campaign. State the finite additional work, platforms and resources. Full EXP-03 and EXP-04 require their own scope/authority and evidence; H does not execute either. macOS 26 runtime, Developer ID/notarization, Gatekeeper/sandbox/Hardened Runtime, distribution/updater and final-candidate performance remain mandatory Stage C release qualification, outside this plan.

## 11. Test evidence and decision accounting

The [PQR crosswalk](m1-sqlcipher-phase2-pqr-crosswalk.md) preserves all 50 original descriptions, evidence codes and prerequisite references and states where fake probes can contribute. Six cases have pure admission-only routes: K05/K06/K07/K08/K09/K14. K13 has fake delivery-fencing coverage but requires real evidence for committed-outcome reconciliation. The other 43 cases require real SQLCipher for their complete original provider claim. K15 remains dependent on genuine bind-failure instrumentation; an adapter-injected pre-call error is not equivalent.

Use existing DB0 environment/evidence definitions from the readiness matrix. No new canonical validation case, experiment, owner policy or AC pass is created by these local routes. Carry the explicit earlier K14 mapping correction with historical source unchanged. Per-run artifact files are future outputs, not evidence generated by planning.

## 12. Current status and next authorization request

**Design planning PASS; runtime readiness BLOCKED; provider behavior INCONCLUSIVE; no newly observed runtime FAIL.** Implementation of A–F, builds/fake checks and any provider-linked launch each need the scope authorized by a future explicit instruction. The smallest meaningful next step is review/resolve OPEN-01 and approve the detailed protocol/VFS contracts, followed by a bounded isolated implementation task. Database testing is not the next safe automatic action.

**No real SQLCipher provider operations, database opens, encryption tests, fixtures or PQR runtime cases were executed. EXP-03 and EXP-04 remain unexecuted.**
