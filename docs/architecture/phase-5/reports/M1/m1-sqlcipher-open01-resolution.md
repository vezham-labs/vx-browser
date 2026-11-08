# M1 OPEN-01 · Key-before-read resolution analysis

Version 1.0 — Proposed, 2026-11-09. **Design only. OPEN-01 remains Blocked; no security requirement is changed.** [Primary review](m1-sqlcipher-critical-safety-contracts-phase2a.md).

## 1. Meaning and source-derived result

The literal requirement is: **no bytes of the target database are read before its scoped key is applied through the length-explicit SQLCipher binding to the connection that will access that target.** Receiving a key in worker RAM, applying it to an unrelated in-memory connection or merely declaring a key lease is not application to the target. Metadata-only path/descriptor validation is not a database-byte read; pre-key hashing, copying, prefetch and memory mapping are reads and cannot be used as a loophole.

For existing files in pin `355d4db92d3404e71faa8088d071a71d767807f4`, the ordinary public API sequence cannot satisfy this literal rule. `sqlite3_open_v2` reaches B-tree/pager header reading before it returns a handle on which the caller can call `sqlite3_key`. Exact source:

| Source reference | Observation |
|---|---|
| S01 `main.c:3682`, `:3721–3738` | B-tree opened before automatic extensions |
| S02 `btree.c:2575,2712–2716` | Header buffer is 100 bytes; pager open followed by header read |
| S03 `pager.c:4063–4081` | Header read invokes `sqlite3OsRead` at offset zero |
| S04 `main.c:3387–3417,3784–3793` | SQLCipher URI key helper exists, but is called after B-tree open |
| S05 `attach.c:219,253–306` | ATTACH opens B-tree before its codec/key handling |
| S06 `sqlcipher.c:3810–3826` | Public key API needs the DB connection and attaches its codec; successful binding is not authentication |

S identifiers refer to [exact captured source excerpts and hashes](../../evidence/20261108T193319Z-m1-critical-safety-contracts-phase2a/sources/pinned-source-excerpts.json). These are source-inspection conclusions, not an executed I/O trace. Public contracts: [SQLCipher key API](https://www.zetetic.net/sqlcipher/sqlcipher-api/), [SQLite open](https://sqlite.org/c3ref/open.html).

## 2. Alternatives evaluated

### A. Ordinary open, then explicit binary binding

**Sequence:** scoped key validated in RAM → metadata/resource admission → `sqlite3_open_v2` on named VFS → `sqlite3_key(db,key,32)` → suite settings → schema/identity authentication under write fence.

**Pre-key physical read:** yes, offset-zero header request occurs in S01–S03. **API/pin compatibility:** supported ordinary API, exact existing binary-passphrase contract. **Maintenance:** public API plus reviewed custom VFS; upstream open ordering must be rechecked on upgrade. **Security:** no key in SQL/URI; encrypted-header access does not itself authenticate data; strict write fence still required. **Proof:** future broker/VFS ordinal trace must distinguish KeyReceived, OpenEnter, Read, KeyApplied, Authenticated and Grant. **Failure:** any Ready/write before auth fails; literal pre-read criterion fails even if all reads are ciphertext. **Disposition:** viable only if D2A-01 explicitly approves the bounded exception.

### B. Read-only, immutable or nolock variants

**Sequence:** open with read-only/URI immutable flags → bind key → authenticate. **Pre-key read:** yes; S03 still runs. **API/pin:** flags supported, but immutable/nolock assert external conditions and are not an authentication fence. **Maintenance:** public flags are stable; recovery/WAL semantics vary and require review. **Security:** an incorrect immutable claim can suppress locking/change detection; read-only alone does not prohibit every VFS side effect. **Proof:** trace all main/sidecar/mapping effects, not flags alone. **Failure:** stale/missing WAL state, ignored recovery or altered sidecars; no literal compliance. **Disposition:** not a solution; no immutable/nolock shortcut selected.

### C. SQLCipher URI key / hexkey / textkey

**Sequence:** open URI containing key parameter → B-tree header read → `sqlite3CodecQueryParameters` invokes key API (S04). **Pre-key read:** yes. **API/pin:** URI key processing exists in this pin; it is not an early key-aware open. **Maintenance:** URI parsing/version-specific behavior needs review. **Security:** key material enters filename parsing/logging and key/textkey use string semantics; hexkey decoding does not remove URI secret exposure. **Proof:** source ordering plus future trace if separately needed; no secret URI experiment is required to reject it here. **Failure:** key leakage, binary truncation/reinterpretation, wrong ordering. **Disposition:** rejected under existing nonlogging binary-channel contract; no change to that requirement.

### D. Automatic extension or initialization hook

**Sequence:** register callback → open target → B-tree header read → extension callback can receive DB handle and bind. **Pre-key read:** yes, extensions run after B-tree open (S01). `SQLITE_EXTRA_INIT` has no per-target connection/key argument and is not a supported pre-open binding API. **API/pin:** automatic extensions exist but do not move the header read. **Maintenance:** relying on internal callback ordering/hooks increases coupling. **Security:** global key state risks cross-profile confusion and expands trusted initialization. **Proof:** compare exact call order; no live callback is executed. **Failure:** late binding, duplicate initialization, global key leakage. **Disposition:** not a supported literal solution.

### E. Key an in-memory connection, then ATTACH target with a bound BLOB key

**Sequence:** memory open → memory key → ATTACH target → target B-tree/header read → target codec attach/key → schema access. **Pre-key target read:** yes (S05). **API/pin:** ATTACH KEY supports BLOB semantics, but timing is still too late; approved adapter forbids arbitrary ATTACH. **Maintenance:** two schemas and extra authorization surface. **Security:** a key on the memory DB is not a key on the target; plaintext/empty-key attach paths add hazards. **Proof:** target-resource trace, not “some key applied earlier.” **Failure:** target read before its own key, scope confusion, plaintext attach. **Disposition:** rejected; no ATTACH exception introduced.

### F. Stage bytes in memory or use deserialize/backup/file substitution

**Sequence:** copy/read existing target → construct memory DB or deserialize → bind/replace/export. **Pre-key target read:** yes during acquisition. Keying an empty memory DB first does not establish a documented encrypted-file deserialize/key-before-read path. **API/pin:** no supported public operation found to atomically transplant an unopened file into an already keyed target connection while preserving this suite and recovery semantics. **Maintenance:** substantial format and buffer-lifetime coupling. **Security:** extra whole-store copies/plaintext exposure and inconsistent sidecar acquisition. **Proof:** include controller/broker reads, not only provider calls. **Failure:** hidden read, invalid codec/format, lost WAL/recovery state. **Disposition:** not a supported solution; no whole-file memory workaround selected.

### G. Defer/block VFS xRead until binding, or fabricate a short/empty header

**Sequence:** open waits in xRead for key binding → caller cannot bind until open returns; alternatively VFS pretends an existing header is absent. **Pre-key read:** blocking avoids the read only by preventing completion; fabricated data hides it rather than implements truthful I/O. **API/pin:** no supported public safe reentrant key binding on the half-constructed connection established. **Maintenance:** callback/reentrancy and pager-invariant coupling. **Security:** deadlock, wrong page layout, accidental new-store initialization or source modification. **Proof:** fake liveness/ordering model may demonstrate the cycle; never manufacture an apparently passing trace. **Failure:** timeout or false empty database. **Disposition:** rejected; no fabricated reads or codec/pager patch authorized.

### H. Vendor-supported new key-aware open API or different provider strategy

**Sequence:** would require documented target key attachment before any physical open/read, with this exact binary/suite contract and truthful I/O. **Pre-key read:** unknown until such an API and source are supplied. **API/pin:** not found in the inspected pin/public API; not an available solution. **Maintenance:** a maintained upstream API could be evaluated after provenance, source/build and migration review. **Security/proof:** requalify all relevant open, failure, scope and artifact controls; a vendor assertion alone is insufficient. **Failure:** unsupported fork, partial binding or lost format/recovery guarantees. **Disposition:** future investigation only; no patch, dependency replacement or vendor contact authorized here.

## 3. New-store scope and negative conclusion

A genuinely new zero-length exclusive reservation has no existing content to read, but `xRead` can still be invoked and return a truthful short read. That observation cannot qualify the existing-file requirement. Refusing every existing-file open satisfies a fail-closed policy while providing no authenticated reopen functionality. This package does not label refusal a functioning literal key-aware open.

**No supported, maintainable public-API approach meeting the literal requirement was established for the pinned existing-file path.** This is a bounded conclusion about the inspected pin and public interfaces, not proof that no future vendor API can ever exist.

## 4. D2A-01 — exact proposed owner disposition

**Status: Proposed / Not Decided.** The owner must explicitly choose one of these directions before affected implementation behavior is accepted:

1. **Retain the literal rule.** Existing-file SQLCipher opens remain blocked; investigate a maintained supported key-aware API or reconsider the provider path under separate scope. No fake header, internal patch or weaker interpretation is authorized.
2. **Approve this exact bounded exception:** “For the pinned qualification path, permit the truthful encrypted-header request at main-database offset 0, length 100, during connection construction before the length-explicit key call. This 100-byte bound is the application/VFS read-request bound, not a bound on block-device transfers: OS caching, sector reads and read-ahead may fetch more ciphertext before key application. No zero-physical-device-read guarantee is retained by this exception. The scoped 32-byte key must already have been validated in worker-owned memory. This exception permits no schema/row SQL, decrypted content publication, key in a URI/SQL string, persistent mutation, recovery/checkpoint write, additional application/VFS pre-key data-read request, or DatabaseReady/write grant. Apply the approved suite before authentication; all original protected files remain fenced until authenticated native scope/store/schema/suite/key-version identity is verified. An unexpected pre-key read range or any persistent mutation stops and preserves the run. Re-review the bound on provider/VFS upgrades.”

The 100-byte allowance is derived from S02/S03 for the proposed broker VFS, not assumed sufficient for an arbitrary platform VFS or provider upgrade. If the reviewed implementation legitimately needs another pre-key read, the exception does not silently expand; remain blocked and seek a revised explicit disposition. Metadata queries and genuine short reads are separately logged. Allowing encrypted baseline hashing or coherent ciphertext-copy acquisition **before the provider key call** is a distinct broader exception and is **not included** in option 2.

Consequently baseline whole-file hashes must be captured only after KeyApplied but before starting auth reads capable of recovery; the broker fence is already active. If the key call itself needs additional file reads or writes beyond the frozen pre-key rule, stop. After failure, hashes are an independent witness of the enforced fence, not the enforcement itself. No pre-key hash/copy loophole is introduced.

Approval of option 2 would be a scoped requirement interpretation/change that must be explicitly recorded by the authorized owner in a separate task. This report neither records approval nor changes existing owner/security documents. Product/release use, other providers/versions, runtime testing, implementation and broader threat acceptance remain separately unauthorized.

## 5. Required later evidence

Only after design approval and execution authority: trace every broker read/write/mapping and marker phase; establish exactly which reads occur inside open and inside key binding; demonstrate no SQL/data access before binding; verify wrong/missing-key controls and complete post-bind settings/identity. The no-read literal branch must show zero target-byte reads before its own KeyApplied event. Under an approved exception, the separate bounded oracle must show only the approved pre-key header request. These are different criteria and must never be combined into one PASS.

**No provider function, database open, experiment, fixture or runtime test was executed by this analysis.**
