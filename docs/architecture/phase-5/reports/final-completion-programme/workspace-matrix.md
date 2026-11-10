# WS-F7 workspace and persistence matrix

All rows describe product qualification. Linked Core and worker outputs are supporting evidence at their respective boundaries. Every blocked case requires an admitted production provider and positive signed Keychain custody.

| ID | Product outcome | Status | Individual blocker | Available evidence |
| --- | --- | --- | --- | --- |
| F7-01 | Relaunch restore | Blocked | The app has no production reader or normal-profile workspace mount. | [Supporting output](evidence/provider.stdout.txt) |
| F7-02 | Multiple workspaces and order | Blocked | The product catalog cannot store an ordered workspace library. | [Supporting output](evidence/core.stdout.txt) |
| F7-03 | Stable identities | Blocked | There is no protected durable record to compare across app runs. | [Supporting output](evidence/core.stdout.txt) |
| F7-04 | Lazy restored views | Blocked | Startup cannot mount a signed persistent layout, so post-restore admission cannot be measured. | No product result |
| F7-05 | Split, focus and divider | Blocked | The persistent layout cannot be restored into the active split controller. | [Supporting output](evidence/core.stdout.txt) |
| F7-06 | Durable mutation | Blocked | The production mutation dispatcher has no protected publication path. | [Supporting output](evidence/provider.stdout.txt) |
| F7-07 | Private exclusion | Blocked | A positive normal-profile write control is unavailable for a durable negative test. | No product result |
| F7-08 | Mini exclusion | Blocked | A positive durable receiver control is unavailable to compare against Mini. | No product result |
| F7-09 | Persistent profile isolation | Blocked | The product cannot provision two authenticated normal profiles. | [Supporting output](evidence/provider.stdout.txt) |
| F7-10 | Unauthorized access | Blocked | The admitted product provider has no runnable positive control. | [Supporting output](evidence/storage.stdout.txt) |
| F7-11 | Interrupted real writes | Blocked | The browser has no production commit boundary for safe fault injection. | [Supporting output](evidence/provider.stdout.txt) |
| F7-12 | Failed publication | Blocked | No previous committed production workspace revision exists to preserve. | [Supporting output](evidence/provider.stdout.txt) |
| F7-13 | Malformed and truncated data | Blocked | The product cannot reopen authenticated disposable ciphertext through the catalog. | [Supporting output](evidence/provider.stdout.txt) |
| F7-14 | Schema migration | Blocked | There is no production schema admission or migration path. | [Supporting output](evidence/core.stdout.txt) |
| F7-15 | Future schema rejection | Blocked | The normal application cannot open the protected schema fixture. | [Supporting output](evidence/provider.stdout.txt) |
| F7-16 | Stale revisions | Blocked | There is no integrated durable revision writer to exercise from two app instances. | [Supporting output](evidence/provider.stdout.txt) |
| F7-17 | Repeatable migration | Blocked | The app cannot create and reopen an authenticated prior durable schema. | [Supporting output](evidence/core.stdout.txt) |
| F7-18 | Private diagnostics | Blocked | The durable application recovery branch cannot run with a verified signed key. | [Supporting output](evidence/provider.stdout.txt) |
| F7-19 | Startup race | Blocked | There is no durable restore operation to race against a user edit. | No product result |
| F7-20 | Explicit durable outcomes | Blocked | The app cannot publish and reconcile an uncertain protected commit. | [Supporting output](evidence/provider.stdout.txt) |

[Security and recovery](security-and-recovery.md) · [Exact commands](verification.md)

## Arc parity programme follow-up

The existing 20-case ledger was validated again against its evidence manifest. All 20 cases remain blocked for product execution. The Core suite now also covers direct Codable decoding of unsupported versions and invalid empty catalogs. No provider file, authenticated production workspace or Keychain item was created.

For every case below, use the same approved signed app with a known disposable production profile and record a baseline ciphertext hash and committed revision. Test owned loopback content only. After an expected failure, reopen through the same authenticated identity and compare the last committed revision. Preserve failed or ambiguous records for review.

| ID | Additional precondition and operation | Expected result and failure control |
| --- | --- | --- |
| F7-01 | Create an ordered workspace, commit, quit and relaunch | Same graph restored. An interrupted restart retains last commit. |
| F7-02 | Create three workspaces and reorder them | Reopen preserves all three and their order. Failed reorder leaves prior ordering. |
| F7-03 | Capture opaque stable IDs before reopening | Identities match. Unknown IDs never bind by display name. |
| F7-04 | Restore a multi-tab layout with no foreground load | No eager website view admission. Explicit navigation admits only the intended view. |
| F7-05 | Commit two-pane focus and divider state | Restore valid layout and focus. Missing member safely normalizes to one tab. |
| F7-06 | Mutate pin, group and Space membership in one revision | Changes publish atomically. Interrupted publication leaves the previous valid graph. |
| F7-07 | Run private and normal scopes side by side | Private markers never appear in durable records. Normal control persists. |
| F7-08 | Seed Mini website state, transfer an eligible link | Destination receives the link only. No Mini records appear in durable data. |
| F7-09 | Provision two normal profiles and swap descriptors | Each sees only its own graph. Wrong profile or store is denied. |
| F7-10 | Attempt access with wrong scope, revoked grant and missing key | Access is fenced before publication. Source bytes remain available. |
| F7-11 | Interrupt before and after commit | Reopen yields exactly the previously durable or newly durable revision. |
| F7-12 | Inject failure during staging or publish | Previous committed revision remains readable and receipt reports failure or uncertainty. |
| F7-13 | Corrupt and truncate disposable ciphertext | Open fails safely. Explicit authenticated recovery can read a valid prior revision. |
| F7-14 | Open a supported old schema and migrate | Valid graph migrates once. Interrupted migration preserves original recovery data. |
| F7-15 | Open an authenticated future schema | Reject before mutation and preserve ciphertext. |
| F7-16 | Submit two writers against one expected revision | Exactly one commits. Stale writer reconciles without overwriting. |
| F7-17 | Repeat reopen and migration after interruption | No duplicated records or revision effects. |
| F7-18 | Inject authorization, corruption and recovery errors | Logs contain scoped outcome categories and exclude URLs, names and keys. |
| F7-19 | Race a user edit with application restore | Mutation is sequenced after validated mount or denied explicitly. |
| F7-20 | Lose the commit reply and reopen | Caller reconciles by authoritative revision and operation outcome. |

The existing worker and Core suite are supporting tests for selected mechanics. The signed application test runner for these product cases still depends on the unimplemented production path. See the [authorization checklist](external-authorization-checklist.md).
