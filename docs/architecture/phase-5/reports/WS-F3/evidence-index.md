# Evidence index

| Evidence | Canonical artifacts |
|---|---|
| Starting state and exact decisions | [Baseline](evidence/baseline.json), [approval](approved-decisions.md) |
| Provider | [Final result](evidence/provider-20261109T154014534033Z/result.json), [inputs](evidence/provider-20261109T154014534033Z/inputs.json), [observations](evidence/provider-20261109T154014534033Z/observations.json), [prior success](evidence/provider-20261109T153650183751Z/result.json), [first compile failure](evidence/provider-20261109T153538203758Z/build.stderr) |
| Settings | [Final result](evidence/settings-20261109T154359495015Z/result.json), [observations](evidence/settings-20261109T154359495015Z/observations.json), [initial failure](evidence/settings-20261109T154121729855Z/observations.json) |
| App builds | [Final](evidence/f3-final-app-build-154430288065/result.json), [exact sources](evidence/f3-final-app-build-154430288065/sources.json), [prior build](evidence/f3-app-build-154142960775/result.json), [prior binary preservation](evidence/f3-final-app-build-154430288065/prior-build-preserved.json), [sandbox failure](evidence/f2-build-153618072330/result.json), [compile failure](evidence/f2-build-153757983100/result.json) |
| WebKit and lock | [Final cases](evidence/f2-webkit-native-154509919762/case-results.json), [permission observations](evidence/f2-webkit-native-154509919762/permission-result.json), [previous run](evidence/f2-webkit-native-154248866718/result.json) |
| Keychain and backup | [Final cases](evidence/f2-security-native-154509919813/case-results.json), [archive probes](evidence/f2-security-native-154509919813/backup-result.json), [previous run](evidence/f2-security-native-154248866641/result.json) |
| Private subset | [Cases](evidence/native-154509919727/case-results.json), [cutpoint](evidence/native-154509919727/private-only-interrupted-result.json), [restart](evidence/native-154509919727/private-only-restart-result.json) |
| Swift regressions | [Final contracts](evidence/f2-contracts-154430421543/result.json), [fake baseline](evidence/attempt-153921486637/result.json), [source-stability guard failure](evidence/f2-contracts-153921357819/result.json), [manifest sandbox failure](evidence/f2-contracts-153737419971/swift-test.stderr) |
| Consolidation | [Disposition ledger](evidence/dispositions.json), [native app observation cross-index](evidence/native-app-observations.json), [preservation check](evidence/preservation.json), [checksums](evidence/SHA256SUMS) |

Raw stdout/stderr and commands are retained beside their runs. CLI case timestamps were recorded at launch. The reused app harness does not timestamp individual operations; its cross-index records each result artifact's UTC persistence time as such. Provider fixture IDs and loopback inputs are synthetic. No keys, credentials, user browsing data or plaintext rows are captured. App binary copies remain local outside Git; the SHA-256 values identify the binaries used. Earlier outcomes are retained without merging different revisions.

The Nx wrapper stalled before emitting target output and was interrupted. The corresponding checked-in entrypoints were executed directly. Scoped execution allowed Xcode/SwiftPM to use their normal local caches and manifest sandbox. App security configuration was unchanged.
