# Performance and reliability

## Available evidence

| Reference | Evidence and interpretation |
|---|---|
| Vezham | Historical WS-F4R and WS-F5 runs cover scoped interactions and lifecycle, with distinct native/contract/stand-in labels. WS-F5R execution-01 exercises actual WebKit/AppKit after an injected trigger. Historical Phase 3 recovery evidence used a different prototype. No comparative Vezham timings or memory measurements were collected for this report. |
| Search | Product site claims a window opens in about a third of a second. Source confirms lazy view realization, protected sleep exclusions and visible/hidden termination handling. Mechanisms alone cannot establish speed, power draw or one renderer per tab. |
| Arc and Little Arc | Vendor reports performance work on large sidebars and background tabs. Little Arc has no separately verified benchmark in this study. |
| SigmaOS | Vendor claims memory and battery benefits and idle page suspension. Exact policies, test cohorts and comparable measurements remain unverified. |
| Zen | Source shows session backups, split/session integration and Gecko process foundations. No matching benchmark located. |
| Cra | Its documented local performance recorder distinguishes main-loop stalls, startup, and per-process memory. It is a measurement design reference. No matched performance comparison used here. |
| Stedding | Its own 2026-09-02 matched-pin local run measured about 0.66 s vs 0.65 s cold first paint and 823 MB in both browser trees for ten idle local pages. Its live footprint run varied materially. It explicitly reports no current measurement. |
| Flecha and Refrax | Source provides implementation and operational mechanisms. No matched quantitative benchmark located. |
| Vela | Its project benchmark on M5/macOS 26.5 reported median window appearance of 271 ms (Vela) and 2058 ms (Arc), with 1967 MB and 3149 MB respectively after loading 11 tabs, blocker off. Different Chromium versions and project-controlled setup limit inference. With a blocker, content workload changes. Results apply to those exact builds and metrics. |

[Vezham execution-01](../WS-F5R/evidence/execution-01/README.md) · [Search publisher site](https://searchbrowser.app/) · [Arc release notes](https://resources.arc.net/hc/en-us/articles/20498293324823-Arc-for-macOS-2024-2026-Release-Notes) · [SigmaOS](https://sigmaos.com/) · [Cra recorder](https://github.com/VictorKildahl/cra/blob/992760043e1c629337822d13bf09fc410fc732a8/docs/performance.md) · [Stedding method](https://github.com/ysalitrynskyi/stedding-browser/blob/a93a12d0bdcd321ef218dae65a3569d184f259be/docs/perf/README.md) · [Vela method and raw results](https://github.com/JoSanson/vela/blob/55b18a3ad70dbf8838c4acf512230e57368ac2d2/docs/BENCHMARK.md)

## Candidate baseline and oracles

| Scenario | Record and compare |
|---|---|
| Cold/warm launch | Time separately to window present, first accepted chrome action and first fixture page paint. Compare empty, 1, 12 and 24 logical tabs with same candidate settings. A first visible frame can precede usable controls. |
| Lazy restore and switching | Record number of view builds, store assignments, navigation requests and admitted scopes before first selection. Count unexpected background network requests. Compare first activation to already-live activation, command result to focus, and split open/resize. |
| Background and window lifecycle | Sample attributable physical footprint, main-thread stalls, CPU and live view inventory for main, split and Minis during foreground/background, idle, media, and repeated create/close. Use deterministic loopback fixtures and explicit cache/blocker state. Compare before and after teardown after a fixed settle interval. |
| Recovery | Measure callback-to-fence, confirmed retirement, user-initiated rebuild and first fresh commit independently. Preserve assertion evidence for original and fresh store, old references, stale callback rejection and unaffected scopes. Real content-helper fault injection needs positive two-host attribution and signal-time revalidation with abort on ambiguity. |
| Native regression | Script keyboard and deterministic navigation. Record physical pointer drag, actual VoiceOver speech/captions, default-handler restore, downloads and permissions separately. Keep owned authentication distinct from external providers and run the actual supported OS matrix. |

Record source/build hash, OS and WebKit build, signing mode, hardware, fixture version, battery state, window geometry, foreground state and process-attribution method. Alternate comparable runs and retain all samples and failures. Report median and tail values with sample count and spread, plus hard correctness oracles and error rates. Record per-role helper measurements when attribution is reliable. Shared WebKit services and ambiguous process ownership should be marked unknown. Avoid summing RSS as a proxy for physical footprint. Establish baseline variance before choosing regression budgets. Keep the WS-F5R qualification ledger and these later performance experiments independent. [Current test matrix](../WS-F5R/evidence/execution-01/test-matrix.md) · [Architecture recommendations](architecture-recommendations.md)
