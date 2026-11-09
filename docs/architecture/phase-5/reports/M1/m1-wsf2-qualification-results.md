# WS-F2 actual qualification results

2026-11-09. **WS-F2 INCOMPLETE — Required implementation or safety gates remain unmet.** Primary actual environment: macOS27.2/26B123 arm64, Swift6.4.2/SDK27.2, WebKit22625.2.8.11.9. macOS26.0/latest26.x are deliberately deferred under this task, not passed and not themselves a WS-F2 implementation failure.

| Canonical suite | Actual result | Identity/scope |
|---|---|---|
| Retained full WS-F1 native regression |475 PASS_NATIVE observations,2 HTTP-cache INCONCLUSIVE,0 failures;39 app processes/12 deliberate terminations | `native-113327653483`, production build `f2-build-113022470426` |
| New WebKit/cache/lock/permission |36 PASS_NATIVE observations,4 BLOCKED,1 INCONCLUSIVE,1 FAIL;15 processes | `f2-webkit-native-114029856396`, final test-host build `f2-build-113900589907` |
| Native Keychain/owned backup |16 PASS_NATIVE observations,2 PASS_CONTRACT admission checks,6 BLOCKED,0 failures;3 processes | `f2-security-native-113238831637`, production build `f2-build-113022470426` |
| Contract/model/fake suite |23 PASS_CONTRACT,2 PASS_FAKE_ONLY,0 failures;25 named tests | `f2-contracts-113307401411` |
| Original fake suite |82 PASS_FAKE_ONLY,0 failures/skips/uncompleted | `attempt-112058889226`; original providers/tests preserved |

Counts remain separate. Do not add historical runs, convert observations to unique WKS cases, combine fake/native totals or claim one binary passed every suite. Only qualification-host instrumentation changed after the production regression build; shared product-source hashes are reconciled in the implementation-identity record. The final host executable SHA256 is `d933ae466707edcdd39936cdcdddeceddfc5b17ae2fd746296d6b64ded938c9a`; the production regression build is `17897e1450048796e69b4225ffeda47b2fd6e997dba2bb58ea3948034bf64d47`.

## What the native evidence demonstrates

The retained regression covers explicit persistent/private assignment, tested storage-class isolation/sharing/relaunch, switching, private retirement, localStorage clear, normal remove and11 exact lifecycle cutpoints plus private death. Original HTTP-cache persistence observations remain inconclusive; they are not retroactively upgraded.

New controlled HTTP evidence shows live-profile response reuse, distinct A/B responses, view reconstruction behavior, new network retrieval after clean/abrupt process restart, in-process pre-clear positive controls and fresh response after selected/full clearing. Public callbacks/identifier absence confirm normal removal. These are response/server observations, not disk-file persistence or erasure guarantees.

Actual lock checks cover two views/windows, another profile, blocked old-view navigation, key-cache absence, outstanding navigation, repeated safe convergence, actual lock-fence child death and fresh-process conservative locking without a creating factory. No real key had been acquired; no durable protected lock/unlock receipt or all-OS-trigger guarantee follows.

Keychain missing-item calls reach the OS. Creation/delete return-34018; acquisition returns-25300 after creation failed. Host has0 valid code-signing identities. The required data-protection/userPresence ACL is unchanged. Successful key creation/read/duplicate/rotation/recovery is BLOCKED, not a native pass.

The backup tests perform real AES-GCM/HKDF and synthetic owned-file operations: authenticated roundtrip, fresh encryption, tamper/truncation/trailing/wrong-key/wrong-profile refusal, deletion filtering, unknown-lineage/private/destination controls, no overwrite and incomplete-stage nonpublication. Real catalog source/import and recovery custody remain BLOCKED.

## Actual permission failure and incomplete runs

The final media fixture returned `script-error` before its native delegate was observed, so it failed the expected-denial oracle. Geolocation returned `timeout`, no delegate observed, and remains INCONCLUSIVE. Positive Ask/Allow is BLOCKED. The native host exited normally and retained its retired synthetic checkpoint; the sequence stopped and did not claim successful permission cleanup. No positive device support or verified denial is inferred from script failure.

Earlier permission probing hit the100-second parent timeout and its exact owned process was killed; that FAIL remains. New5-second script completion and phase markers provided a bounded result rather than relabeling the timeout Passed. No unchanged retry loop continues.

Earlier compile failure from unhandled ID construction and a source-changed-during-test runner failure are retained. The first Keychain restart oracle incorrectly required existence after blocked creation; it failed and was corrected to BLOCKED plus missing-item control. An earlier repeated-lock oracle required identical terminal state despite references draining; the corrected postcondition permits RecoveryRequired→Locked only after empty resources/no lease, with the original failure preserved. All attempted builds/runs have separate outputs/hashes.

## Not executed / remaining mandatory qualification

Actual protected SQLCipher catalog create/open/transaction/migration/corruption recovery, successful userPresence Keychain lifecycle, loaded-key lock revocation/authenticated unlock/OS-trigger/transfer matrix, positive native permission/grant revocation, coherent production backups/import/custody/cross-Mac recovery, native in-flight/partial/dropped-callback error routes, website export/backup and release gates remain blocked or unexecuted. No provider/PQR runtime operation or database open/create occurred. Actual26.0/latest26.x remains a deferred release backlog, with public distribution still unauthorized.

[Canonical records](../../evidence/20261109T105707Z-webkit-storage-wsf2/results/canonical-attempts.json) · [per-case inventory](../../evidence/20261109T105707Z-webkit-storage-wsf2/case-inventory.json) · [all attempts](../../evidence/20261109T105707Z-webkit-storage-wsf2/results/attempt-history.json) · [cache analysis](../../evidence/20261109T105707Z-webkit-storage-wsf2/results/cache-analysis.json) · [gates](../../evidence/20261109T105707Z-webkit-storage-wsf2/acceptance-gates.json).
