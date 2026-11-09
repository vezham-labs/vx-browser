# WS-F2 security decision handoff

2026-11-09. WS-F2 implementation/qualification review. [Closeout](m1-wsf2-closeout.md) · [Actual results](m1-wsf2-qualification-results.md) · [Evidence](../../evidence/20261109T105707Z-webkit-storage-wsf2/README.md). **No release approval.**

## No owner decision is recorded by this proposal

D2A-01 remains Proposed/Not Decided. Existing exact options in [OPEN-01](m1-sqlcipher-open01-resolution.md) remain canonical: retain the literal key-before-target-byte-read rule and keep existing-file open blocked, or explicitly approve the narrowly bounded offset0/length100 encrypted-header VFS request exception with all its key-in-RAM/no-SQL/no-write/no-additional-read/no-pre-key-hash-copy conditions. OS read-ahead is not bounded physical-device I/O. This task does not select either option, change the source pin or add an exception.

Without that decision, a usable protected catalog and dependent unlock/persistent-grant/source-backup integration cannot be completed. Even an approved exception would still require real worker/VFS/binding/authentication/artifact qualification; it is not automatic production approval. A maintained vendor key-aware-open API is a separately reviewed alternative, not an invented available solution.

Keychain's concrete environment action is to provide an authorized stable signing identity/default access-group environment and re-run only the exact synthetic userPresence cases. No request is made to weaken ACLs, use shared groups, bypass Gatekeeper or substitute file/env keys. This is an access prerequisite, not a new product-policy choice.

Archive/normal-recovery custody work must continue under existing OD-R08/19 and key-envelope contracts: verified printable kit/encrypted recovery file, independent key recovery, key-ring/retained-backup dependencies and authenticated migration. The provisional archive helper cannot silently settle final interoperability/custody or bypass a blocked source catalog. Remaining public WebKit protection/backup class limitations remain existing owner/security review topics, not newly approved guarantees.

The smallest next milestone is finite: owner disposition of D2A-01 plus a working signed Keychain qualification environment, followed by the already-defined catalog/key/lock/backup gates. Independent WebKit observations can be retained without restarting Phase3 or repeating unchanged provider/permission loops.
