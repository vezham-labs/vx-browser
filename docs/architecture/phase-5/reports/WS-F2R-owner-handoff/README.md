# WS-F2 Evidence Handoff Report

2026-11-09. Owner-review package against `timeline` commit `d90ef9b029568c650588ffbead99866ee1378710`. **WS-F2 remains INCOMPLETE. WS-F2R is proposed, not authorized.**

This package consolidates the implemented storage/security foundation, its actual evidence and the finite decisions needed before WS-F2R. It adds reporting only. It does not reopen Phase 3, implement WS-F2R, rerun qualification or change historical results.

## Repository verification

| Item | Independently inspected result |
|---|---|
| Checkout | `/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser` |
| Branch | `timeline` |
| Expected and actual HEAD | `d90ef9b029568c650588ffbead99866ee1378710` — matches |
| Parent / WS-F2 starting commit | `21ad0b0ca91ed0777e873fd8233290e4f12f2e96` |
| Commit subject | `feat(browser-macos): integrate guarded storage security foundation` |
| Initial working tree | Clean; no uncommitted changes |
| Committed WS-F2 change set | 942 paths: 46 authored files (14 existing modified, 32 new including 14 reports), plus 896 new evidence files |
| Handoff changes | Only the nine new, untracked Markdown files in this directory; no tracked file changed, nothing staged or committed |

The current task's snapshot covers all 2,970 tracked files. They are required to remain byte-identical through report completion. The existing WS-F2 preservation record additionally covers the preceding baseline: 2,028 unchanged of 2,042 tracked files, with 14 explicitly scoped modifications. These are different preservation boundaries.

## Findings for the owner

The native host connects real WebKit operations, actual Security/Keychain attempts and a real CryptoKit/synthetic-file backup slice to typed Core policies. **The protected catalog is an enforced unavailable gate, not a usable encrypted database.** Keychain item creation failed; no acquired profile key was available to qualify revocation. Native view retirement passed bounded tests, while full authenticated unlock, OS-trigger coverage, persistent grants and production backup/recovery remain incomplete.

The latest WebKit suite contains `F2-PERM-NATIVE-DENIAL` **FAIL** (`script-error`) and geolocation **INCONCLUSIVE** (`timeout`). Neither recorded its expected permission trace. The underlying JavaScript/native error was discarded, and the media trace is recorded only after mediation, so the exact failure cause and delegate entry are unresolved. Positive Ask/Allow remains disabled/unqualified.

D2A-01 needs an explicit owner choice between retaining the literal pre-key target-byte-read prohibition and the existing precisely bounded encrypted-header request exception. No option has been selected by this report. Development signing/provisioning can enable a separate Keychain development qualification; **Vezham Developer ID, production entitlements, notarization and official signed-build qualification remain release-hardening work**, not prerequisites for every development activity.

## Report navigation

| Deliverable | Purpose |
|---|---|
| [README.md](README.md) | Executive summary, repository state and review boundary |
| [implementation-status.md](implementation-status.md) | Actual inventory, component paths and incomplete work |
| [d2a-01-owner-decision.md](d2a-01-owner-decision.md) | Exact owner alternatives, consequences and proposed decision criteria |
| [signing-keychain-blockers.md](signing-keychain-blockers.md) | Operations, signature/entitlements, development versus release prerequisites |
| [locking-permissions.md](locking-permissions.md) | Native lock evidence, loaded-key/unlock limits and permission support matrix |
| [backup-recovery.md](backup-recovery.md) | Synthetic crypto/files, production integration and website-data exclusions |
| [native-failure-analysis.md](native-failure-analysis.md) | Exact failure, diagnostic limitations and finite investigation proposal |
| [qualification-matrix.md](qualification-matrix.md) | Separate suite counts, all 40 WKS cases, failed runs and hash verification |
| [ws-f2r-proposal.md](ws-f2r-proposal.md) | Proposed finite work, dependencies, acceptance and release exclusions |

## Integrity and independent-verification limits

This handoff rehashed all **895** entries in the existing `SHA256SUMS`, **940** artifact-index entries and **74** implementation-manifest entries: **zero mismatches or missing files**. Both retained app executables also match their recorded hashes; static `codesign --verify --strict` succeeded for both. These checks verify consistency with stored records, not the correctness of every earlier runtime assertion or publisher authenticity of an ad-hoc signature. The hash values, commands and limitations are recorded in [qualification-matrix.md](qualification-matrix.md).

No historical runtime result was reproduced. Media failure root cause/reproducibility, geolocation cause, successful Keychain userPresence behavior, current account/certificate availability and final Vezham provisioning remain unverified. The historic identity inventory reported zero valid identities; it was not rerun against Keychain for this report. No Apple account, Keychain item, website store or database was accessed at runtime. Existing source, reports, owner decisions, ADRs and evidence remain untouched.

ADR 0001 remains Proposed; WKWebView remains conditional, CEF evaluation-only, Aura excluded. No production Tamizhi, mandatory cloud/account service or public distribution is authorized. OP-01–OP-04 are already owner-decided in the current M1 register; their engineering details remain incomplete. This package does not reopen them or change OD-R01–OD-R20/WS01.1/historical meanings.
