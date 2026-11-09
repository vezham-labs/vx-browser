# D2A-01 owner decision handoff

2026-11-09. Owner-review package against `timeline` commit `d90ef9b029568c650588ffbead99866ee1378710`. **WS-F2 remains INCOMPLETE. WS-F2R is proposed, not authorized.**

## Canonical record and unchanged status

**D2A-01 remains Proposed / Not Decided.** The authoritative alternatives are [OPEN-01 §4](../M1/m1-sqlcipher-open01-resolution.md) (lines 64–75), supported by [Phase 2A critical safety contracts](../M1/m1-sqlcipher-critical-safety-contracts-phase2a.md) (line 61), [readiness matrix](../M1/m1-sqlcipher-phase2a-readiness-matrix.md) and [pinned source excerpts S01–S06](../../evidence/20261108T193319Z-m1-critical-safety-contracts-phase2a/sources/pinned-source-excerpts.json). Pin: `355d4db92d3404e71faa8088d071a71d767807f4`, SQLCipher 4.20.0 Community/CommonCrypto. These are inspected-source conclusions, not executed provider I/O traces.

The literal rule requires applying the scoped key through the length-explicit SQLCipher binding to the **target connection before reading target database bytes**. Possessing the key in worker RAM or keying another in-memory database is insufficient. In the inspected ordinary existing-file path, `sqlite3_open_v2` enters B-tree/pager header reading before returning the connection needed for `sqlite3_key`; S02/S03 identify offset 0, length 100. No approved supported public-API literal solution was established for this pin.

## The two options

| Dimension | Option 1 — retain literal rule | Option 2 — exact bounded exception |
|---|---|---|
| Security interpretation | Zero target-byte reads before the target's KeyApplied event | Only the specified truthful encrypted-header application/VFS request before KeyApplied; OS transfers/read-ahead may exceed it |
| Immediate implementation consequence | Existing-file opens remain blocked; current unavailable gate stays | May make ordinary open then length-explicit bind a candidate for bounded qualification; no automatic Ready/write approval |
| Compatibility | Current inspected public existing-file path cannot qualify; no supported key-aware alternative identified | Applies only to frozen provider/VFS path; not arbitrary versions/VFSs; format/recovery/upgrade behavior still needs qualification |
| Maintenance | A supported vendor key-aware API or reconsidered provider strategy needs separate review | Recheck read bound and ordering on every provider/VFS upgrade; unexpected reads stop the run |
| Remaining prohibitions | No fake header, pager patch, plaintext fallback, URI/SQL secret or pre-key hash/copy workaround | All original restrictions except precisely permitted request remain; no broader hash/copy, SQL, publication, mutation, recovery/checkpoint write or extra pre-key read |
| Required evidence | Truthful all-resource read/write/mapping trace proves zero target-byte reads before target KeyApplied, then scope/suite/schema authentication | Same trace proves only approved pre-key header request, key already validated in worker memory, no mutations/additional reads, then correct binding/settings/identity before grant |
| Main unresolved consequence | Working authenticated reopen remains unavailable | Owner explicitly accepts ciphertext request before key application and relinquishes a zero-physical-device-read guarantee; actual runtime conformance is unproven |

## Exact Option 2 wording, preserved for decision review

The following is reproduced from the canonical repository decision record; it is **not** an approval:

> For the pinned qualification path, permit the truthful encrypted-header request at main-database offset 0, length 100, during connection construction before the length-explicit key call. This 100-byte bound is the application/VFS read-request bound, not a bound on block-device transfers: OS caching, sector reads and read-ahead may fetch more ciphertext before key application. No zero-physical-device-read guarantee is retained by this exception. The scoped 32-byte key must already have been validated in worker-owned memory. This exception permits no schema/row SQL, decrypted content publication, key in a URI/SQL string, persistent mutation, recovery/checkpoint write, additional application/VFS pre-key data-read request, or DatabaseReady/write grant. Apply the approved suite before authentication; all original protected files remain fenced until authenticated native scope/store/schema/suite/key-version identity is verified. An unexpected pre-key read range or any persistent mutation stops and preserves the run. Re-review the bound on provider/VFS upgrades.

Metadata queries and genuine short reads remain separately logged. Whole-file baseline hashing must occur only **after KeyApplied**, before authentication reads capable of recovery, with the broker fence already active. Pre-key ciphertext hashing/copying is a distinct broader exception and is not included. If open or key binding needs another disallowed request or any persistent mutation, stop and preserve rather than expanding the allowance. A key-binding return code does not prove key correctness or authenticate the database.

## Required qualification after a decision and separate execution authority

1. Preserve the exact pin/VFS/suite and distinguish KeyReceived, OpenEnter, Read, KeyApplied, Authenticated and write-grant markers. Trace main file, sidecars, mapping and mutation classes without secret bytes.
2. Apply the branch-specific oracle: zero pre-key target reads for Option 1; only the frozen header request for Option 2. Never combine these into one PASS.
3. Qualify key length/lifetime/scope, correct and wrong/missing keys, wrong store/schema/suite/version, denial/cancellation and no Ready/write before complete authentication.
4. Prove write fencing on failed/partial initialization, recovery/checkpoint/close paths and unexpected reads. Hash witnesses support enforcement; they do not replace it.
5. Qualify exclusive new-file creation **and** fresh-process reopen, migrations and failure preservation. New empty-file creation alone cannot qualify an operational persistent catalog.

The original 50 PQR cases and EXP mappings remain unchanged; their prerequisites and complete execution criteria still apply. D2A-01 approval alone does not complete the provider contracts, authorize all PQR runtime, waive release gates or grant WS-F2R implementation authority.

## Recommendation for owner consideration

Consider **Option 2 only if its exact application/VFS ciphertext-read trade-off fits the threat model**; it is the narrowly documented route worth qualifying for this pin. If the zero-pre-key-target-read requirement is mandatory, choose Option 1 and accept that existing-file catalog operation stays blocked pending a separately reviewed supported strategy. This is a recommendation, not a disposition. Record the selected option and exact scope explicitly; a general “continue,” approval of SQLCipher as a candidate or development signing does not resolve it.
