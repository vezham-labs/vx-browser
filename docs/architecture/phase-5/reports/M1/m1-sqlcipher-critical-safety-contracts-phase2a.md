# M1 SQLCipher critical safety contracts · Phase 2A

Version 1.0 — Proposed, 2026-11-09 (Asia/Kolkata). **Design only. No implementation or execution authorization.** Starting `timeline` HEAD `fb3a71668f92deef88cc61ef454eda202fbc2587`; parent `384f200f7cda567d6782df46aea322faeab54fb7`; clean initial tree.

This is the primary Phase 2A review. It supplements the committed [Phase 2 design](m1-sqlcipher-provider-adapter-phase2-design.md), [A–H plan](m1-sqlcipher-phase2-implementation-plan.md) and [50-case crosswalk](m1-sqlcipher-phase2-pqr-crosswalk.md). It does not rewrite those historical design snapshots or treat their PASS planning status as provider qualification.

## 1. Contract package and status

| Gate | Phase 2A disposition | Remaining boundary |
|---|---|---|
| OPEN-01 | **Blocked** — supported public-API alternatives inspected; no literal key-before-physical-read solution established for existing files | Proposed decision D2A-01 requires explicit owner disposition; current requirement stays in force |
| OPEN-02 | **Resolved at proposed-contract level** — broker-enforced deny-before-auth operation matrix and failure-preservation contract specified | Implementation and negative/fault evidence absent; WAL/RAM-index compatibility and dirty-store availability remain unqualified |
| OPEN-03 | **Partially resolved** — descriptor-bound broker/VFS design, namespace rules, mappings and trace contract specified | Full VFS implementation, lock/WAL semantics, direct-I/O coverage and supported-filesystem validation pending |
| OPEN-04 | **Resolved at proposed-contract level for bounded qualification** — durable deny-admission state, no automatic stale-child adoption, restart reconciliation defined | Durability/process-exit evidence absent; production authenticated-intent bootstrap remains outside this slice |
| OPEN-05 | **Partially resolved** — single-connection IPC v2 byte layout, states, cancellation and outcome semantics specified | Second-key/copy/promotion protocol for R09–R12 remains explicitly excluded pending its own finite maintenance contract |

“Resolved at proposed-contract level” means the rule is specified for design review, not accepted implementation, runtime readiness, security validation or owner approval.

Reports:

- [OPEN-01 alternatives and exact owner decision](m1-sqlcipher-open01-resolution.md).
- [OPEN-02 write-fence specification](m1-sqlcipher-open02-write-fence-specification.md).
- [OPEN-03 VFS and filesystem confinement](m1-sqlcipher-open03-vfs-confinement-specification.md).
- [OPEN-04/05 protocol and recovery](m1-sqlcipher-open04-open05-protocol-and-recovery-specification.md).
- [Dependency graph and readiness matrix](m1-sqlcipher-phase2a-readiness-matrix.md).
- [Evidence and preservation](../../evidence/20261108T193319Z-m1-critical-safety-contracts-phase2a/README.md).

## 2. Proposed architecture and reason for the refinement

Use the existing native qualification supervisor plus a serialized **ResourceBroker service inside that supervisor**, a worker control loop and one worker DB executor. The worker's custom VFS sends bounded resource operations to the broker. It receives opaque IDs, not database/directory file descriptors or real paths. The broker alone performs descriptor-relative storage syscalls. This is a proposed refinement of Phase 2's observer/confinement VFS, replacing the earlier assumption that merely wrapping pathname-based Unix VFS opens would be enough.

The broker maintains the independent authorization phase. Every mutation request is checked before dispatch; an engine request cannot bypass authentication because it asks to recover, checkpoint, delete a journal, truncate or close. Persistent SHM mappings are not supplied to the worker. A bounded RAM-only WAL-index object is the proposed single-worker option; persistent source SHM remains untouched. Unsupported behavior fails closed. This controls trusted provider I/O through the designed interface; it is not an OS sandbox against compromised native code or hostile same-user processes.

The initial implementable milestone is deliberately smaller: an unlinked fake v2 endpoint and pure resource-policy/state models with no filesystem backend. It needs no real database, SQLCipher, VFS registration, Keychain or production target. Subsequent implementation and execution require separate explicit authority.

## 3. Frozen proposed invariants

| Contract | Normative proposed rule | Detailed owner |
|---|---|---|
| C01 | Private/foreign/stale scope denied before paths, provider launch/init or key delivery | OPEN-02 §§2–3; protocol §§2–5 |
| C02 | Existing-store physical-read prohibition remains unchanged unless D2A-01 is explicitly approved | OPEN-01 §§1–4 |
| C03 | No existing protected content or namespace mutation before authenticated identity and broker grant | OPEN-02 §§2–5 |
| C04 | Read permission, key acceptance, key application, authenticated identity and write authority are distinct states | OPEN-02 §3; protocol §5 |
| C05 | Resource identity binds held descriptors and exact root/sidecar IDs, not a caller pathname | OPEN-03 §§2–3 |
| C06 | No persistent SHM mapping; RAM index requires single-worker exclusivity and validation | OPEN-03 §4 |
| C07 | Unknown temp/scratch path, alternate VFS or trace gap blocks admission; no unobserved fallback | OPEN-03 §§5–6 |
| C08 | Only checked full UUIDs/epochs authorize operations; version 1 remains fake-only | Protocol §§2–4 |
| C09 | SQLite connection/statement/transaction ownership is serialized; interrupt lifetime is pinned | Protocol §§5,7 |
| C10 | Cancellation is an intent, not proof of rollback or noncommit | Protocol §§6–7 |
| C11 | Mutation, revision and retained receipt commit together; Unknown is never silently replayed | Protocol §6 |
| C12 | Persistent intent/quarantine precedes launch, grant and destructive effects; restart defaults to deny | Protocol §8 |
| C13 | Stale PID alone never grants kill/adoption authority; direct-child reap is checked | Protocol §§8–9 |
| C14 | Cleanup has independent provider, process, broker and artifact witnesses | OPEN-02 §5; protocol §9 |
| C15 | No raw key, SQL, paths, arbitrary diagnostics or FS buffers in public records | OPEN-03 §6; protocol §§4,9 |
| C16 | Mandatory security/release gates and current engine/product boundaries stay unchanged | §6; readiness §6 |

These C identifiers are local contract references, not new REQ, AC, PQR, SPEC, OD or experiment IDs.

## 4. Exact owner decision still required

**D2A-01 — Proposed / Not Decided:** retain the literal prohibition and keep existing-file provider opens blocked, or explicitly approve the narrowly bounded pre-key encrypted-header exception in OPEN-01 §4. The recommended narrower interpretation is not applied by this package. It cannot be inferred from approval of the SQLCipher candidate, OD-R decisions, documentation work or the words “continue”/“try now.” No approved security requirement is changed.

No new disposition of OP-01–OP-04 or OD-R01–OD-R20 is required for the proposed fake-only milestone. Compatibility and error-oracle choices are engineering work, not unapproved owner policy. Product expansion into hostile same-user/native-code isolation would require a separate threat-model review; it is not claimed here.

## 5. Explicit assumptions and evidence gaps

| Assumption | Role and failure behavior |
|---|---|
| A01 Trusted native broker/worker/provider and supported OS | Matches existing offline-at-rest threat model. Compromise invalidates API-level confinement; no sandbox claim |
| A02 Exclusive application ownership of the registered synthetic bundle | No other DB user/writer or untrusted namespace mutator. External mutation stops the run; advisory locks alone cannot exclude a malicious same-user process |
| A03 Local supported filesystem and stable held-object identities | Device/inode/type/owner/link identity plus retained descriptors; no assumed network/cloud/removable-volume semantics |
| A04 Custom VFS semantics accurately implement SQLite contracts | Especially xRead short-read, locks, SHM and sync. Source suggests feasibility; no runtime proof exists |
| A05 RAM WAL-index construction works for the pinned single-worker mode | Persistent source SHM is never reused or overwritten; unsupported or incompatible WAL stops as RecoveryRequired |
| A06 Durable log and filesystem sync primitives provide their documented scope | No claim of hardware power-loss proof; failed/unsupported durability prevents launch or grant |
| A07 Independent synthetic key custody is available for a requested restart check | No key bytes in durable journal. Missing key means quarantine, not regeneration or Keychain/cloud fallback |
| A08 Diagnostics and trace budgets can be enforced | Default OS-device logging/direct I/O require independent review; output/coverage failure stops qualification |

All assumptions are declared, not established facts. The readiness report names validation needed to discharge each. The retained source authenticity/static builds/119 Phase 1 assertions retain their original limited meanings. None is a Phase 2A provider test.

## 6. Preservation and authorization

Swift 6 engine-independent Core, Swift/AppKit host, future React/TypeScript/HeroUI v3 chrome, offline local browsing, optional identity/cloud and separate WebKit protection remain unchanged. ADR 0001 stays Proposed with conditional WKWebView strategy; ADR 0002 stays Accepted; 0003–0005 stay Proposed. CEF is evaluation-only. Aura, production Tamizhi, public distribution and production implementation are excluded. macOS 26 and signing/notarization remain mandatory final-release gates.

Only these six new reports, timestamped evidence and append-only references in the M1 README/source catalog are authorized changes. Phase 1/prototype/product source, historical reports/evidence/manifests, PQR definitions, owner records and ADRs remain preserved. No validation case is marked passed or run. Existing OPEN-06 genuine bind-failure observation, OPEN-07 device/crash diagnostics and OPEN-08 case budgets/oracles remain pending technical prerequisites.

**No real SQLCipher provider operations, database opens, encryption tests, fixtures or PQR runtime cases were executed. EXP-03 and EXP-04 remain unexecuted.**
