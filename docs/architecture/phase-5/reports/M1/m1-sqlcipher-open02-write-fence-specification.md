# M1 OPEN-02 · Pre-authentication write-fence specification

Version 1.0 — Proposed, 2026-11-09. **Resolved as a proposed contract only; not implemented or validated.** [Primary review](m1-sqlcipher-critical-safety-contracts-phase2a.md) · [VFS](m1-sqlcipher-open03-vfs-confinement-specification.md) · [Protocol/recovery](m1-sqlcipher-open04-open05-protocol-and-recovery-specification.md).

## 1. Protected objects, scope and enforcement

For an existing store, the protected bundle is the registered main database, WAL, persistent SHM, rollback/statement/super journals, registered temp/scratch artifacts and its directory-entry identities/existence. Protect bytes and lengths as well as replacement/deletion/truncation. File size, paths and operational headers can disclose metadata; this contract does not assert that every associated byte is encrypted. atime or OS access accounting may change during allowed reads; do not call that content modification or promise forensic immutability.

**Enforcement is outside the provider's own open flags:** the supervisor's ResourceBroker is the sole filesystem executor for the custom VFS. The worker receives no file/directory descriptor, writable mapping, arbitrary path or syscall callback for a protected object. A per-resource broker state machine rejects mutation requests before they reach `pwrite`, truncate, create, unlink, rename, mapping or sync-to-dirty-source paths. Reads use held read-only descriptors. Any pre-reserved write descriptor stays broker-private and unused until a separately durable grant. SQL authorizers and read-only flags are additional guards, not the enforcement boundary.

The trust scope is the existing trusted native code/OS model and an exclusively owned synthetic bundle. A malicious native worker could issue independent syscalls with the user's privileges; this design is not a sandbox against that attacker. Cross-account/root/hostile same-user namespace mutation, pre-existing dirty kernel mappings and filesystem/OS compromise are outside a broker-only guarantee. If those exclusions cannot be established for a test bundle, refuse to run. No original product/user store is used.

## 2. Broker phase machine

| State | Admission and allowed effects | Transition |
|---|---|---|
| Denied | No resource or provider authority; private/foreign/stale rejected | Valid native manifest and exclusive scope lease → Reserved |
| Reserved | Metadata-only root/object binding; no target-byte read or mutation | Current OPEN-01 rule permits only a true no-read path; owner-approved exception required for HeaderOnly |
| HeaderOnly | **Conditional, not approved:** only the exact D2A-01 header request; no other target-byte read, SQL or persistent mutation | Checked key API success event bound to the opening operation → KeyApplied |
| KeyApplied | Controller-only ciphertext baseline hashing permitted after KeyApplied; worker has configuration-only authority, no data reads; no source mutation | Frozen non-reading suite verified, baseline witness complete and explicit AUTH_READ_GRANT → Authenticating |
| Authenticating | Required schema/identity/integrity reads and bounded RAM operations; all persistent mutations still denied | Expected native identity + required pre-auth/pre-grant settings + active lease + broker checks → AuthenticatedReadOnly |
| AuthenticatedReadOnly | No persistent write authority yet; compare expected identity/settings evidence and current resources | Supervisor persists grant intent and broker atomically installs grant epoch → Writable |
| Writable | Only reviewed opening/configuration writes until full-settings DatabaseReady; then separately admitted recipe/artifact/operation-specific writes, never arbitrary SQL/path/reset | Revocation/close/failure → Fenced; new explicit maintenance grant needed for promotion/replacement |
| Fenced / Quarantined | Stop new work and sensitive delivery; after-auth transaction retirement only under explicit bounded reconciliation authority | Verified resource/outcome/cleanup witnesses permit retirement; ambiguity remains quarantined |

There is no HeaderOnly transition under the unchanged literal OPEN-01 rule. A new-store reservation has a distinct Create grant and can only affect its operation-owned, previously nonexistent branch; it cannot be used to bypass an existing-file fence. A zero-length existing path is never treated as a new reservation.

The worker's KeyApplied/Auth messages are claims by trusted native code, not cryptographic attestation. The supervisor independently checks full context, operation, effective-settings digest, trusted expected identity, complete fixture-oracle digest and resource/lease epoch. No renderer or arbitrary caller can send these messages. A compromised trusted worker is outside this boundary's threat model.

## 3. Exact pre-authentication operation matrix

| Artifact / operation | Permitted | Denied or required failure |
|---|---|---|
| Main DB open | Bind existing regular object without CREATE/TRUNC; use broker-private RO descriptor; reserve a matching RW descriptor only if required for later same-object writes and metadata proves identical object | New path creation/adoption, aliases, foreign object, resetting an orphan, URI/alternate VFS |
| Main DB reads | Only OPEN-01-approved pre-key range; after KeyApplied, bounded source reads and post-key baseline hashes; auth reads only after suite settings | Other pre-key bytes, decrypted publication, write/truncate/zero-fill/fallocate or recovery writes |
| Main/WAL sync | No-op only when no broker-tracked dirty data exists and no OS sync syscall is issued; log that fact | A pre-auth sync that could flush earlier dirty data; falsely claiming durable work |
| WAL existing file | Metadata bind plus post-key read-only reads of the exact frozen WAL; stable resource/identity and no other writer | Create, append, overwrite header/frame, truncate/reset, checkpoint or delete before grant |
| Persistent SHM | Inventory metadata; optional post-key forensic read by the controller only if authorized and never used as live index | Worker mapping, write, create, truncate, unlink or rebuilding source SHM |
| RAM WAL index | Bounded zero-initialized process-local memory; xShmMap/Lock/Barrier/Unmap per OPEN-03; no source mapping or backing file | Disk mapping, namespace side effects, unbounded regions, unregistered multi-process users or unsupported locking semantics |
| Rollback journal | Metadata and post-key RO reads of registered bytes | Hot-journal playback into source, delete/truncate/zero-header, automatic cleanup; return RecoveryRequired |
| Statement/super journal | Existing artifact metadata/RO observation only when permitted; unused artifacts remain retained | Disk creation/write/delete before auth; unknown cross-store super-journal participants cause refusal |
| Temp DB / sort/index | Bounded memory-only objects; synthetic identifiers, no disk path | Any pre-auth persistent temp spill, named or unnamed file, DELETEONCLOSE disk fallback |
| Provider scratch/log file | No persistent output permitted; only reviewed memory buffers and nonstorage system services | Direct file I/O or unknown scratch path; OS device logging remains separate OPEN-07 stop gate |
| Namespace operations | Metadata lookup and held-descriptor comparison; no metadata repair | File replacement, unlink/rename, chmod/chown, link creation or deleting an apparently stale sidecar |
| Close/error cleanup | Release memory and broker handle references; checked unlock, no content mutation | “Cleanup” cannot bypass fence; attempted journal/WAL deletion or checkpoint is rejected and reported incomplete |
| Cancellation/process exit | Fence commands/results; retire direct-child resources and retain source bundle | Rollback/checkpoint writes before auth, replay, key regeneration or auto-unlink because the process exited |

Opening a RO file is not a proof of no side effects: pinned `pager.c:5324–5396` can request journal deletion during hot-journal detection; `:5478–5480` returns READONLY_ROLLBACK for some hot journals. These are exactly why every VFS namespace/mutation method is broker-fenced. Source excerpts S08 preserve this evidence.

## 4. WAL, SHM, recovery and write grant

For the proposed single-worker mode, the source main/WAL are frozen against other application writers. SQLite may reconstruct a RAM wal-index through public VFS xShm methods while reading the existing WAL (S07). RAM writes are not source-file writes. This is a **candidate compatibility path**, not a demonstrated capability. If the pin requires persistent writes, unsupported locking or a source-side SHM mapping, return RecoveryRequired/UnsupportedStorageMode; do not pretend a WAL is absent or fall back to an incomplete main DB.

Hot-journal recovery into the original before authenticated identity is forbidden. A dirty bundle can remain safely unavailable. A future separately authorized coherent disposable recovery branch must name every source/sidecar, mutation allowance, key/identity oracle and original-preservation witness. Phase 2A does not grant that recovery exception, and does not count refusal as a successful recovery PQR result. T09 and any R case requiring such writes remain ineligible until its finite recovery contract is reviewed.

Write grant is an atomic policy transition in the broker, not a new pathname open by the worker. For a normal existing-file connection, the VFS may advertise its requested logical READWRITE capability while all early writes are denied by the broker. This is not a claim of OS read-only mode. When a later grant will require an RW descriptor, the broker must already have bound a matching no-CREATE/no-TRUNC RW descriptor to the same object before granting. It remains unused pre-auth; reads use the RO descriptor. Opening the descriptor may fail access checks, in which case no writable-ready result is possible. The worker never gets that descriptor.

If a provider reports actual READONLY and would need a new connection to write, close it with the fence intact and reauthenticate the new fenced connection against the same held object/key/version before a grant. Do not upgrade a previously authenticated path by name or transfer an auth witness across connections. New sidecars may be created only after grant in the lease-owned directory with an exclusive broker reservation; existing sidecars retain their own object bindings.

## 5. Failure-preservation proof obligations

| Scenario | Enforced behavior | Required future independent witnesses |
|---|---|---|
| Wrong-key auth | No broker mutation authority ever installed; typed UnauthenticatedOrCorrupt; retain source and close under fence | Post-KeyApplied/pre-auth baseline versus post-retirement file bytes/lengths/existence/identities, complete denied-mutation trace, zero grant count; correct-key control on a fresh fenced lease |
| Corrupt input | Same fence; no reset/create/migrate; incomplete schema never becomes Ready | Exact mutation manifest on disposable copy; original baseline retained; auth/structural result correctly classified |
| Valid crypto, wrong identity | Deny grant even though decryption succeeds; no rows published or relabeling | Expected versus actual opaque identity/version, grant log absent and source equality |
| Interrupted open / key-call failure | No mutation authority; retain handles/source and quarantine if cleanup cannot be confirmed | Broker phase/ordinal and policy decisions, owned PID status and object inventory. If no KeyApplied occurred, OPEN-01 may prohibit full hashing; explicitly mark that witness unavailable, not passed |
| Worker termination | Broker revokes request admission and closes its RO references without source cleanup writes | Checked wait status, broker pending-RPC outcomes, before/after artifact inventory/hash when legally readable; process exit is not provider-close proof |
| Supervisor/broker termination | No further broker-mediated writes after broker death; in-flight syscall outcome is unknown where applicable | Durable intent and restart quarantine; no new lease until resources/outcome reconciled. Before grant, no mutating syscall was admissible |
| WAL index/recovery needed | RAM-only rebuild if supported; otherwise fail closed and preserve WAL/SHM | Actual source read/write trace, RAM-region lifecycle and source SHM unchanged; no claim from absence of a file |
| Hot-journal/checkpoint write needed | Return RecoveryRequired before any mutation; preserve originals | Denied exact syscall/VFS intent and unchanged bundle; recovery remains blocked rather than passed |

**Proof is layered:** policy model checks plus syscall-dispatch inspection show prevention; future independent filesystem/system tracing corroborates actual behavior; content hashes/inventory compare results. None alone substitutes for the others. Hashing itself obeys OPEN-01. Missing pre-key baselines or missing system coverage produce a narrower/INCONCLUSIVE result; this package grants no additional pre-key copy/hash exception.

After post-auth writes have begun, cancellation/failure may need separately bounded transaction reconciliation. The pre-auth “unchanged source” claim cannot be extended to those writes. A revocation stops new work and delivery; a reconciliation grant, if explicitly allowed by the run manifest, may finish rollback/close for the admitted transaction without granting new operations. Unknown commit remains Unknown. No permanently retained key is justified by a cleanup deadline failure.

## 6. Freeze and validation boundary

The deny/allow matrix, state separation and no-source-mapping rule are proposed normative contracts. The broker, custom VFS, RAM WAL compatibility, locks, sync/error behavior and all preservation observations remain unimplemented/unvalidated. Required future controls include every forbidden operation, false Ready/grant messages, stale epochs, read-range violation, source replacement, pipe/trace pressure, interrupted open and hot-journal/WAL modes. They are not tests executed here and do not change original PQR definitions.

**No provider operations, database opens, fixtures, builds or runtime tests occurred.**
