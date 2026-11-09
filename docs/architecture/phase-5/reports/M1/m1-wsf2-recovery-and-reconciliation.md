# WS-F2 recovery and reconciliation

2026-11-09. WS-F2 implementation/qualification review. [Closeout](m1-wsf2-closeout.md) · [Actual results](m1-wsf2-qualification-results.md) · [Evidence](../../evidence/20261109T105707Z-webkit-storage-wsf2/README.md). **No release approval.**

## Implemented layers

Existing Core lifecycle/journal/receipts and native WSF1 reconciliation remain authoritative for engine operations. `StorageRecoveryPolicy` adds a pure cross-component eligibility gate: authenticated catalog, available matching key, present engine, stable intent and complete deletion knowledge are all required before even proposing explicit unlock. Recorded lock remains locked. Missing/corrupt/future/unavailable catalog, missing/denied/mismatched key, missing/unknown/uncertain-removal engine and creation/publication/lock/unlock/clear/backup/restore/delete intents require recovery. Eligibility is not authorization or publication.

Native unlock invokes that gate with truthful unavailable catalog/key state and refuses admission. Startup has no plaintext fallback, orphan adoption, random replacement profile or default store. Key loss never regenerates over ciphertext. Pending tombstones/unknown engine results remain preserved; absence alone cannot manufacture a callback-confirmed removal. Permission epochs invalidate late grants. Backup restore authenticates full content, applies known deletion IDs and refuses unknown lineage without explicit confirmation; no stale grant/native token restores as authority.

## Actual process behavior and evidence limits

The current WSF1 native regression actually terminates/relaunches the dedicated host across clean restart, interrupted creation/publication/clear/removal/reconciliation and private death. Its synthetic catalog/journal metadata is mirrored through parent evidence; this is not actual protected disk state. WSF2 additionally performs Keychain attempts in separate processes, actual cache abrupt termination/relaunch, and lock-fence interruption/fresh-process conservative lock admission. Distinguish PID restart, object reconstruction, engine resolution, website class persistence and browser-owned checkpoint handling.

Keychain creation cannot qualify key restart because -34018 prevented item creation. The first harness expectation was wrong and remains a preserved FAIL; corrected handling records BLOCKED plus a real missing-item control. Lock navigation can cause RecoveryRequired until references drain; later lock convergence is not retroactive success. No uncertain native/staged fixture is silently swept or recycled.

## Not qualified

Actual encrypted catalog reopen/migration/transaction failure, protected journal/tombstone persistence, key/cipher identity reconciliation, durable lock/unlock/permission receipts, encrypted backup/restore process recovery and user recovery custody remain BLOCKED. Faults modeled by policy/fakes are not native I/O/cipher/TCC behavior. Real provider opening is not attempted to satisfy a recovery test. Existing SQLCipher PQR/EXP outcomes remain unchanged.

No cross-system atomicity, auto repair, secure erasure, universal private forensic cleanup or unconditional browser readiness is claimed. Safe recovery may require explicit user action after the concrete signing/provider gates are resolved.
