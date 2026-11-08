# M1 Canonical Engineering Baseline

Updated2026-11-08. Documentation consolidation, isolated validation and implementation planning Authorized; product implementation/release Not Authorized. The [primary closeout](m1-closeout-report.md) owns this task's outcomes; no M1 product completion claim.

## Canonical documents

- [Source catalog and supersession](m1-source-catalog.md).
- [Owner decision/scope register](m1-owner-decision-register.md): preserved OD-R01–20/WS01.1, owner-decided OP-01–04,26-capability OD17 scope and historical OD18 distinction.
- [Architecture](browser-core-architecture.md), [boundary contracts](core-boundary-contracts.md), [data model](browser-core-data-model.md), [persistence](local-persistence-architecture.md), [recovery](migration-and-recovery-strategy.md), [capabilities](browser-capability-architecture.md): supporting Proposed designs; current technical dispositions in the specification.
- [Developer Specification v1.2 — Proposed](m1-developer-specification.md): REQ/AC/SPEC, policy,26-capability coverage, unresolved engineering definitions and implementation traceability.
- [Validation Plan v1.2](m1-validation-plan.md) and [Supporting Charters v1.2](m1-supporting-validation-charters.md).
- [Case Matrix v1.3](m1-case-level-traceability.md):154 validation cases +11 experiment-reference rows; preserved mappings and actual outcomes.
- [Evidence and13 reports](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/), [run environment](../../evidence/20261108T094414Z-m1-consolidated-closeout/environment.json), [frozen native procedure](../../evidence/20261108T094414Z-m1-consolidated-closeout/procedure.md), [row results](../../evidence/20261108T094414Z-m1-consolidated-closeout/traceability-results.json).
- [Implementation plan v1.1](m1-implementation-plan.md):19 proposed work packages; no implementation authorization.
- [Primary consolidated closeout](m1-closeout-report.md).

## Results and limitations

EXP-01 FAIL on retained cleanup assertion; EXP-02 INCONCLUSIVE normal native subset; EXP-03–08 and SVC-01–05 BLOCKED. No complete REQ/AC passes. All154 product validation cases preflight-blocked; do not count experiment-reference observations as case passes. Native environment macOS27.2/arm64 with26.0 compile target; final macOS26 qualification remains Stage C. Cleanup-only follow-up crashed; two owned synthetic store cleanup states are unknown and retained for bounded diagnosis. No personal profiles/default stores, secrets, device permissions or irreplaceable files used.

## Historical sources

The original [owner packet](m1-owner-decision-packet.md), [decision/risk proposals](m1-decisions-and-risks.md), [launch matrix](m1-launch-feature-matrix.md), [execution proposal](m1-implementation-authorization-proposal.md) and DSH review retain historical IDs/meanings. [Exact supplied sources and prior repository documents](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/) are preserved; current canonical documents supersede old policy/authority proposals rather than silently rewriting history. Phase3 source/evidence/manifests are unchanged and never transferred as current acceptance. [Final audit](../../evidence/20261108T094414Z-m1-consolidated-closeout/final-audit.json).

ADR0001 Proposed;0002 Accepted;0003–0005 Proposed. Conditional WKWebView; CEF evaluation-only; no Aura, production Tamizhi, mandatory cloud/identity or public distribution. Local browsing must work without cloud or local-server dependency. No release authority or product implementation is granted by this index.

## M1 validation remediation — 2026-11-08

[Current remediation report](m1-validation-remediation-report.md), [EXP-01 cleanup diagnosis](m1-exp-01-cleanup-diagnosis.md), [encryption specification](m1-persistent-profile-encryption-specification.md), [Keychain/independent recovery specification](m1-keychain-and-independent-recovery-specification.md), and [readiness/downstream dependencies](m1-validation-readiness-remediation.md) refine the existing baseline. Original EXP-01 FAIL/crash evidence and165-row outcomes are preserved; fresh cleanup diagnostics and EXP-03/04 remain Blocked. No product implementation, signing or release authorized.

## Provider and fixture qualification — 2026-11-08

[Current qualification-readiness report](m1-provider-and-fixture-qualification.md) records immutable SQLCipher source provenance, two repeatable isolated static builds, synthetic fixture preparation/observations and blocked native Keychain/same-identity WebKit registry work. Source/build/fixture evidence is not EXP-03/04 acceptance. Original165-row outcomes, owner/ADR decisions and original-store state remain unchanged; no signing/product integration or release.

## Provider trust and runtime gate — 2026-11-08

[Current trust/runtime gate assessment](m1-provider-trust-and-runtime-qualification.md) rechecks the unchanged pin and retained source/build integrity. Independent publisher authenticity remains BLOCKED: GitHub reports unknown_key and no authenticated matching release key/attestation was established. Runtime, storage-surface and interruption qualification stopped before execution as required. No EXP-03, case or acceptance outcome changed.

## Publisher authenticity acquisition — 2026-11-08

[Current publisher-evidence report](m1-sqlcipher-publisher-authenticity-evidence.md) locates official Zetetic package-signing instructions and the 4.20.0 source ZIP/detached signature, retaining the published key and signature. The package key differs from the Git tag's claimed signer; no maintained verifier was found and signed-archive-to-pin correspondence is unverified. Authenticity remains BLOCKED. No build/runtime qualification, installation or external communication occurred; an unsent inquiry is preserved.

## Vendor archive cryptographic verification — 2026-11-08 (latest source checkpoint)

[Current verification addendum](m1-sqlcipher-publisher-authenticity-evidence.md#8-vendor-archive-cryptographic-verification--2026-11-08-current-checkpoint) records approved GnuPG provisioning, a valid vendor-primary-bound archive signature and all 2,325 pinned files matching with zero missing/extra/content/executable-bit differences. The bounded source-authenticity prerequisite is now PASS via the vendor archive; earlier BLOCKED entries/header remain historical. The separate Git tag signature is unverified. Runtime/provider qualification and EXP-03 remain BLOCKED; no build, encryption/runtime/native campaign or product/release authorization is inferred.
