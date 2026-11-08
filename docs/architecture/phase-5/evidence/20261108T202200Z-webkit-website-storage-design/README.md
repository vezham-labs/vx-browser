# WebKit website-storage design evidence

Documentation/static review, 2026-11-09 (Asia/Kolkata); UTC run20261108T202200Z. Starting `timeline` HEAD `a99da90d4d2ec7fbcb6308689709558641cf2b73`, parent `fb3a71668f92deef88cc61ef454eda202fbc2587`, clean tree.

Reports: [architecture](../../reports/M1/m1-webkit-website-storage-architecture.md), [40-case qualification plan](../../reports/M1/m1-webkit-website-storage-qualification-plan.md), [traceability and SQLCipher scope](../../reports/M1/m1-webkit-website-storage-traceability.md).

- [Owner task](sources/owner-task.txt), [baseline and tracked hashes](baseline.json).
- [Repository input inventory/line references](sources/repository-input-inventory.json); no completed M2 report exists in baseline.
- [SDK API declarations/excerpts/hashes](sources/sdk-api-inventory.json). Header snapshots are static evidence, not availability/runtime tests.
- [Official references](sources/official-references.json), [Apple overview snapshot](sources/apple-wkwebsitedatastore.md).
- [Pinned upstream source manifest](sources/webkit-upstream-source-pin.json), [exact excerpts](sources/upstream-source-excerpts.json). Five inert .mm/.cpp snapshots retain original licenses; no source is compiled/imported. Commit75dff6dba87fafb94367ddb5bb155a110963ba80 is not established as shipping macOS source.
- [Claims ledger](claims-ledger.json): documented API / upstream source / proposed assumptions / historical runtime evidence.
- [All40 proposed WKS cases and individual setup/assertion/fault/evidence/mappings](qualification-cases.json).
- [All50 original SQLCipher PQR definitions and independent applicability](sqlcipher-pqr-applicability.json).
- [Non-execution](results/non-execution.json), [static consistency review](results/static-consistency-review.json), [preservation audit](results/preservation-audit.json).
- [Exact changed-file inventory](changed-files.json), [artifact index](artifact-index.json), [SHA256 manifest](SHA256SUMS).

No current fixture, encrypted archive, WebKit/Keychain/provider call, database open/create, build or runtime test occurred. WKS40, PQR50 and all existing canonical/historical outcomes remain unexecuted/unchanged as applicable. EXP-01 FAIL and cleanup crash, EXP-02 INCONCLUSIVE, EXP-05/07 BLOCKED, separate49/49 and48/48 and unresolved SQLCipher gates remain preserved. SQLCipher is scoped to browser-owned data, not engine-managed storage. No app-key website encryption, secure erasure, isolation, crash safety or private nonpersistence is claimed from this review.

Manifest hashes provide integrity comparison only. The artifact index excludes itself/SHA256SUMS; SHA256SUMS excludes itself only. The audit permits only append-only changes to the existing M1 README/source catalog. All other baseline files must hash-match.
