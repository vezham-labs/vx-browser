# Outstanding owner and technical decisions

## Owner review

| Decision | Proposed direction | Consequence or dependency |
|---|---|---|
| Architecture and protection tiers | Approve D and keep encrypted full profiles and sensitive catalog. Require an explicit low-global allowlist before any plaintext storage. | No automatic provider selection. Classify any catalog/bootstrap disclosure and decide exceptions explicitly. |
| D2A-01 for retained SQLCipher existing-file reads | Decide literal rule or canonical exact bounded exception. | Literal keeps the current open blocked. Exception requires signed implementation/runtime scope and evidence; no implied selection. |
| Protected backend branch | Evaluate A if D2A-01 admits a supported open; authorize a finite C investigation if A remains unavailable or unsuitable. | Accepting visible structural metadata as part of “full encryption” requires reviewed disclosure limits. Replacing primary SQLite or topology requires separate OD-R04/05 policy review. |
| Portable website data scope | Approve proposed owned-only default with clear user-facing exclusions. | Any supported optional WebKit export needs types, build/OS behavior, failure cases, user intent and compatibility. Unsupported format copies stay excluded. |
| Execution and internal release scope | Separately authorize next native work and authorized signing environment, then release qualification and distribution independently. | No provider execution, production work or distribution follows from review. macOS 26.x and signing/notary deferral remain. |

## Technical resolution and qualification

- Determine catalog grant/security table placement, bootstrap identity and authenticated freshness source. Determine generation/receipt ordering, lock state on cold restart and interrupted recovery, and safe downgrade refusal. [Core contracts](../M1/core-boundary-contracts.md)
- Freeze key hierarchy/envelope versions, canonical binding, rotation and old backup compatibility, recovery material custody and independent deletion record propagation. Define lock handling of queued outputs, active downloads and partial failures. [Key specification](../M1/m1-keychain-and-independent-recovery-specification.md), [backup design](backup-recovery-migration.md)
- Resolve legitimate signed Data Protection Keychain provisioning and complete custody/lease validation. Determine how required screen-lock, logout/switch/sleep and wake are observed with supported APIs. [Signing blockers](../WS-F2R-owner-handoff/signing-keychain-blockers.md), [locking](../WS-F2R-owner-handoff/locking-permissions.md)
- Freeze permission per-capability support and native origin/document recheck; demonstrate terminal and cancellation semantics, cache/clear/removal postconditions, mapping loss and all-stage failure controls. [WS-F2 results](../M1/m1-wsf2-qualification-results.md)
- Reconcile the narrower OP-01 duration list with OD-R12's custom option without changing either record. Set workload sizes and performance limits with owner input before qualifying comparisons. [Owner register](../M1/m1-owner-decision-register.md), [owner matrix](owner-decision-traceability.md)

The next review can decide the architecture boundary and qualification branch without waiting for final-release testing. It cannot approve any unqualified runtime behavior. [Proposed sequence](implementation-impact.md)
