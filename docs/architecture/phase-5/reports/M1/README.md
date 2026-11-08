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

## SQLCipher provider runtime readiness — 2026-11-08

The static candidate and its source evidence are recorded. The 50 proposed scenarios await an isolated worker, key-binding adapter, encrypted fixtures and controlled faults. EXP-03 remains BLOCKED. [Provider runtime readiness](m1-sqlcipher-provider-runtime-readiness.md)

## SQLCipher worker and key-binding design — 2026-11-08

The proposed design supplies the scoped native qualification worker, exact static link plan, key lifecycle, settings sequence, synthetic fixture contracts and controlled fault barriers. All 50 PQR scenarios remain unexecuted. The design is ready for owner review, while implementation and runtime prerequisites remain pending. The private-refusal mapping correction is recorded for the future executable procedure. [Worker and key-binding design](m1-sqlcipher-worker-and-key-binding-design.md)

## Isolated SQLCipher worker implementation · Phase 1 — 2026-11-08

The native qualification supervisor and fake-provider worker pass 119 conformance assertions. The separately built image has verified static linkage to the pinned SQLCipher archive through its linker map, symbols and binary identity. Phase 1 preserves the zero database/runtime and zero PQR execution boundary. The new control layout, lifecycle coverage, scope quarantine and Nx launcher limitation are recorded in the [Phase 1 implementation report](m1-sqlcipher-worker-phase1-implementation.md).

## SQLCipher provider adapter · Phase 2 design — 2026-11-08

[Adapter and runtime safety design](m1-sqlcipher-provider-adapter-phase2-design.md), [staged implementation plan](m1-sqlcipher-phase2-implementation-plan.md) and [all 50 PQR routes](m1-sqlcipher-phase2-pqr-crosswalk.md) extend the committed Phase 1 infrastructure baseline with design-only ownership, authentication, filesystem fencing and restart requirements. Literal pre-key database-read ordering and pre-auth write/SHM preservation remain blocking gates; no requirement is silently relaxed. All PQR cases remain unexecuted. No provider-linked image, database, fixture, EXP-03/04 or product implementation was executed by this review. [Review evidence and preservation audit](../../evidence/20261108T175705Z-m1-provider-adapter-phase2-design/README.md).

## SQLCipher critical safety contracts · Phase 2A — 2026-11-09

[Primary safety review](m1-sqlcipher-critical-safety-contracts-phase2a.md) links the [OPEN-01 alternatives/owner decision](m1-sqlcipher-open01-resolution.md), [OPEN-02 write fence](m1-sqlcipher-open02-write-fence-specification.md), [OPEN-03 brokered VFS](m1-sqlcipher-open03-vfs-confinement-specification.md), [OPEN-04/05 protocol/recovery](m1-sqlcipher-open04-open05-protocol-and-recovery-specification.md) and [readiness/dependency matrix](m1-sqlcipher-phase2a-readiness-matrix.md). OPEN-01 remains blocked; no requirement interpretation or owner approval is inferred. OPEN-02/04 have explicit proposed contracts; OPEN-03/05 retain validation/maintenance boundaries. The smallest proposed next milestone is separately authorized fake-only v2 work. No implementation/provider/runtime/PQR/EXP execution occurred. [Evidence and preservation audit](../../evidence/20261108T193319Z-m1-critical-safety-contracts-phase2a/README.md).

## WebKit-managed website storage design — 2026-11-09

[Website-storage architecture](m1-webkit-website-storage-architecture.md), [40-case proposed qualification plan](m1-webkit-website-storage-qualification-plan.md) and [requirement/case/PQR traceability](m1-webkit-website-storage-traceability.md) supplement SPEC-08 and planned M2/M5/M6/M8 boundaries. WebKit owns website files; Vezham owns protected mapping/policy/lifecycle metadata. macOS26 export/restore APIs are reviewed per class, with no qualified backup/protection guarantee. SQLCipher remains scoped to Vezham-owned persistence; its gates and all historical outcomes are unchanged. No runtime/implementation/test activity occurred. [Evidence, non-execution and preservation](../../evidence/20261108T202200Z-webkit-website-storage-design/README.md).
