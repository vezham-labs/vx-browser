# Frozen bounded native procedure — revision 1

Parent sources: canonical Validation Plan EXP-01 steps1–5/7 and EXP-02 steps1–2/4/6; ISO-001/PRIV-001 are experiment-reference rows, not new validation cases. This is an isolated public-WebKit capability probe, not a product adapter.

Prerequisites: actual Xcode/SDK; interactive macOS discovery host; disposable signed sandboxed app; two newly generated UUID store identifiers recorded before use; two controlled loopback origins. Never use the default persistent website store. No personal data, accounts, devices, Keychain items, file panels or external websites.

Seed invocation: clear only the two newly registered stores via public APIs; write synthetic A/B cookies, LocalStorage, IndexedDB, CacheStorage and service-worker registrations where available. Read same-A second view and B; verify intended sharing and isolation with positive controls. Probe a separate origin for origin-keyed classes (cookies intentionally not treated as port-isolated). Create two private stores, verify intended within-group sharing and cross-group isolation, release private views, then create a fresh private store and check absence.

Verify invocation: reuse only this run's A/B identifiers; verify process-relaunch persistence, clear A through removeData(all types), create a fresh A view, verify A absence and B preservation; finally remove only this run's two persistent stores through public identifier removal. Preserve any cleanup error; no raw file deletion of WebKit data.

Observation oracles: each supported written class must be visible in intended control and absent in foreign store. Missing API/support is recorded, not silently passed. Positive contamination, wrong-profile deletion or unexpected real data immediately stops the run. Per-class booleans and synthetic marker observations are evidence, not a whole EXP/AC PASS.

Uncovered requirements: actual Core/host ownership/generation/initialization-failure injection, engine metadata/protection/backup, all product repositories/private history/grants/staging, abrupt private interruption, actual last-owner disposal proof. These prevent complete EXP-01/02 qualification even if native subset observations succeed. No product implementation or release qualification.

Maximum app runtime50s; each runner invocation60s. Native launch failure is BLOCKED; ambiguous class observations are INCONCLUSIVE; observed failed defined checks are FAIL. No retry without a distinct environment/configuration explanation. macOS27.2 discovery is not macOS26 qualification.

