# WS-F2 protected catalog

2026-11-09. WS-F2 implementation/qualification review. [Closeout](m1-wsf2-closeout.md) · [Actual results](m1-wsf2-qualification-results.md) · [Evidence](../../evidence/20261109T105707Z-webkit-storage-wsf2/README.md). **No release approval.**

## Status: BLOCKED at actual provider initialization

The application now composes `BrowserPersistence.ProtectedCatalog`, the existing ProfileCatalogPort and RecoveryJournalPort implementation point. Normal startup uses `NativeStorageSession.protectedFoundation()`. It does not substitute the qualification memory catalog or an unprotected file/database for production persistence. Missing keys/catalog cannot cause a new profile/store to be published. The foundation window reports protected storage unavailable; no schema/migration/provider is executed.

`ProtectedCatalog.swift` returns typed catalog/journal unavailable results, an inventory issue and invalid restart snapshot. It does not call SQLCipher, open/create a database, hash/copy existing ciphertext or introduce an initialization exception. This is an enforced integration gate, **not a functioning protected catalog**. Actual persistent creation/reopen, transactions, migration, corruption recovery, tombstones and authenticated stored lock/grant state are BLOCKED.

## Implemented independent contracts

`CatalogSchema` defines version2 and ordered0→1→2 migration plans. Version1 defines catalog identity/revision, profile/store uniqueness, protected descriptor and human label, lifecycle journal and idempotency receipts. Version2 adds independent deletion records, profile lock/key-version/epoch and profile/origin/capability permission records. Metadata timestamps/creation/publication/retirement/removal/migration state live in the validated versioned descriptor. Private session mappings are rejected. Labels are bounded, nonempty and not diagnostic data. Schema planning rejects unauthenticated, interrupted and future-version input; no downgrade/discard path exists.

Required execution contract remains: authenticated scoped provider connection and suite/schema identity first; a serialized transaction validates expected revision/receipt, writes intent/mutation, advances revision and records outcome. Each migration must run in its own authenticated transaction with schema advancement committed only on success; failed/interrupted work preserves originals and denies publication. `mayPublish` independently requires exact revision, stable journal, authenticated key and engine readiness. The migration strings and policy tests are executable planning/validation, **not tested SQLite transactions**. Provider-backed executor, binding, rollback, busy/disk-full handling and migration crash recovery are not implemented or qualified while D2A-01 is blocked.

## D2A-01 and exact operation blocked

The pinned source remains `355d4db92d3404e71faa8088d071a71d767807f4`, SQLCipher4.20.0 Community/CommonCrypto. The reviewed public open path reaches an offset-zero100-byte pager header request before returning a connection for length-explicit `sqlite3_key`. No already-approved compliant existing-file path was established. Receiving a key in RAM does not satisfy binding to that target connection. Read-only, URI keys, ATTACH, auto extensions, fabricated VFS headers and pre-key copy/hash are not loopholes.

See [the existing exact options](m1-sqlcipher-open01-resolution.md) and [WS-F2 decision handoff](m1-wsf2-security-decision-proposal.md). D2A-01 stays Proposed/Not Decided; no source pin, vendor signature, SQLCipher worker/PQR definition or owner requirement changes. New empty-file creation alone cannot qualify restart and could leave an unusable product catalog, so no partial production database is created. All actual catalog-dependent features remain visibly gated.

## WebKit consistency

Core's existing intent/journal/tombstone state machine coordinates WebKit through typed ports. Qualification uses the same existing memory adapter mirrored across actual app processes; those synthetic checkpoints are not encrypted product persistence. There is no SQLite/WebKit cross-system atomic transaction. Unknown native effects or failed metadata finalization stay fenced rather than recreating empty stores or publishing successful deletion.
