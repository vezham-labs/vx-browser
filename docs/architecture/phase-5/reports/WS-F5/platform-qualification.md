# Platform qualification

| Platform or gate | Outcome | Evidence |
|---|---|---|
| macOS 27.2 (26B123), arm64 | Scoped native development cases passed. See open case families. | [Final native suite](evidence/native-04/summary.json) |
| macOS deployment target 26.0 | PASS_CONTRACT for binary and bundle minimum. | [Final audit](evidence/bundle-audit-final.json) |
| Actual macOS 26.0 | DEFERRED under owner sequencing. Runtime unavailable in this campaign. | [Baseline](evidence/baseline.json) |
| Latest supported macOS 26.x | DEFERRED under owner sequencing. Runtime unavailable in this campaign. | [Stage C](../../../../decisions/0001-browser-engine-strategy.md) |
| Other platforms and architectures | NOT_EXECUTED. The candidate was built and observed on arm64. | [Build](evidence/build-07.json) |
| Developer ID, notarization, Gatekeeper release validation, distribution and updater | DEFERRED mandatory release qualification. | [Remaining gates](../WS-F3/next-gates.md) |

The static bundle audit passed for the final binary with ad-hoc signing, App Sandbox, network client and Hardened Runtime. Minimum deployment and actual runtime support are recorded separately.
