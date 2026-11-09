# WS-F2 public-release qualification backlog

2026-11-09. WS-F2 implementation/qualification review. [Closeout](m1-wsf2-closeout.md) · [Actual results](m1-wsf2-qualification-results.md) · [Evidence](../../evidence/20261109T105707Z-webkit-storage-wsf2/README.md). **No release approval.**

The WS-F2 owner instruction deliberately schedules actual macOS26.0/latest supported26.x qualification for the public-release stage. It does not authorize a public release, change the26.0 minimum target, claim26 compatibility or waive security gates. Existing ADR statuses/distribution decisions remain unchanged. Do not deploy an unqualified26-target candidate merely because the current development host is27.2.

| Backlog | Required final-candidate evidence |
|---|---|
| PRQ-01 | Actual26.0 and latest supported26.x, exact app/OS/WebKit/build identities and relevant40 WKS cases; deployment target/27.2 results cannot substitute |
| PRQ-02 | Authorized stable signing identity/default Keychain access group, userPresence item create/read/deny/restart/upgrade/reinstall/loss behavior |
| PRQ-03 | Qualified pinned SQLCipher initialization after explicit D2A-01 decision, complete VFS/worker/authentication/artifact/PQR evidence |
| PRQ-04 | Actual encrypted catalog/profile DB transactions, migration/recovery, tombstones, wrong/missing key, tamper and no plaintext artifacts |
| PRQ-05 | Lock/unlock under OS lock/sleep/session/inactivity, multiple windows, key/engine barrier, transfers and concurrent destructive work |
| PRQ-06 | Per-kind native permission positive/negative Ask/Allow/Deny, OS independence, origin/frame/profile/lifetime and active-stream revocation |
| PRQ-07 | Real authenticated backups/import, independent recovery kit/file verification, source-independent second-Mac/version migration and deletion lineage |
| PRQ-08 | Exact browser-owned category schemas/retention, no private persistence, external-download selection/no overwrite and incomplete-stage recovery |
| PRQ-09 | Developer ID signing/notarization, Gatekeeper, Hardened Runtime/App Sandbox/entitlements, dependency/license inventory and incident/update ownership |
| PRQ-10 | Updater signature/rollback/confinement, critical authorized website/account workflows, reliability/accessibility and final-candidate performance |

All entries are NOT_EXECUTED or BLOCKED until their precise evidence and owner gates pass. Internal-only remains authoritative; any future public distribution requires a separate explicit owner decision. No backlog item is marked passed here.
