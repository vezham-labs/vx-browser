# WS-F3 qualification matrix

## Canonical dispositions

These counts describe observations, not distinct production requirements or an aggregate pass rate. Earlier runs and the one historical-binary diagnostic are separate. Exact counted cases and explicit unexecuted scenarios are indexed in the [disposition ledger](evidence/dispositions.json).

| Final run | PASS_NATIVE | PASS_CONTRACT | PASS_FAKE_ONLY | FAIL | INCONCLUSIVE | BLOCKED | NOT_EXECUTED |
|---|---:|---:|---:|---:|---:|---:|---:|
| Pinned SQLCipher, 12 cases × 2 | 24 | 0 | 0 | 0 | 0 | 0 | 0 |
| System SQLite appearance, 4 cases × 2 | 8 | 0 | 0 | 0 | 0 | 0 | 0 |
| WebKit, native views/lock/permissions, 16 app processes | 38 | 0 | 0 | 0 | 2 | 4 | 0 |
| Keychain/backup, 3 app processes | 16 | 2 | 0 | 0 | 0 | 6 | 0 |
| Current private-only subset, 3 app processes including one observed forced termination | 40 | 0 | 0 | 0 | 0 | 0 | 0 |
| Final Swift contract suite | 0 | 23 | 2 | 0 | 0 | 0 | 0 |
| Retained WS-F0 regression | 0 | 0 | 82 | 0 | 0 | 0 | 0 |
| Explicitly enumerated unexecuted product/release scenarios | 0 | 0 | 0 | 0 | 0 | 0 | 18 |
| **Counted** | **126** | **25** | **84** | **0** | **2** | **10** | **18** |

The private suite additionally recorded **1 PASS_NATIVE** for noncreating enumeration with the archived diagnostic binary. This is outside the 40 current-candidate observations. The outer private qualification remains blocked for supported release OS testing. The prior full WS-F2 and WS-F1 runs remain historical.

Repeatability: final provider 12/12 cases on both fresh passes, 100% reproduction for the scoped expectations. The previous successful provider revision separately recorded 24/24 observations. Final settings 4/4 twice, with the initial revision's 6/8 preserved. WebKit and security app suites each ran on two builds, with the same per-suite count and the same permission/Keychain limitations. The second app build includes the missing-settings fix. Private behavior was exercised before and after deliberate process death in one current suite. Compile and runner failures remain in [failure analysis](failure-analysis.md), outside final case counts.

## Acceptance gates

| Gate | Status | Evidence and limit |
|---|---|---|
| A · Architecture | BLOCKED | Option D record and one-value allowlist, public WebKit ownership and fail-closed protected startup delivered. Full tiered protected backend missing. |
| B · D2A-01 | BLOCKED | Exact fixture reopen boundary and authentication passed natively. Product broker/concurrency, writes and recovery not qualified. |
| C · Keychain | BLOCKED | -34018 create/delete, -25300 lookup, negative controls only; valid development identity and positive custody required. |
| D · Profiles/WebKit | BLOCKED | Actual fixture isolation/lifecycle and private cleanup observed. App persistent profile metadata, key association and durable lifecycle not delivered. |
| E · Browser metadata | BLOCKED | Protected history/bookmarks, sessions, downloads and snapshots unimplemented. |
| F · Locking and permissions | BLOCKED | Actual native view fencing and isolated scoped results. No real loaded-key revocation/unlock. Both permission denials inconclusive; positives blocked. |
| G · Backup/recovery | BLOCKED | 14 native synthetic archive observations and existing model checks. Production source, durable import, migration, deletion reconciliation and cross-Mac restoration unavailable. |
| H · Native qualification | BLOCKED | Actual native discovery, repetitions and evidence indexed. Required production and failure matrix remains incomplete. |

## Failure coverage

- **Executed on synthetic fixtures** · wrong key, corrupted page, truncated file, mismatched profile/store/schema/suite/version, missing file/key, WAL sidecar rejection. No mutation on the existing-file path.
- **Executed against AppKit/WebKit** · Keychain entitlement/missing-item results, scoped native view lock including outstanding navigation, lock cutpoint and restart, cache reload/termination/clearing, private termination/relaunch and synthetic archive tamper/no-overwrite controls.
- **Unexecuted production scenarios** · consult the 18 named rows in the ledger for DB write crash, create/delete interruption, Keychain unavailability variants and custody failures, full disk, actual WAL recovery, migration, session recovery, permissions and release cases. Simulated or unavailable paths are excluded from positive evidence.
