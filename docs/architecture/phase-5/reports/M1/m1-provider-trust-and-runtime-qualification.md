# M1 Provider Trust and Runtime Qualification Gate — v1.0

Date: 2026-11-08. **Bounded validation-only assessment. Provider authenticity BLOCKED; runtime gate closed. No product implementation, production dependency integration, signing, notarization, distribution or release authority.**

## 1. Baseline and scope

Repository: /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser; origin https://github.com/vezham-labs/vx-browser.git; branch timeline. Starting HEAD **7fb95f769f9af0000997c2d193b3d3675d0ca6a6**, parent **f5733fabeee1b0eb559d472c6c86f317b74d8108**. The checkpoint subject is “docs(phase-5): Completed the bounded checkpoin”. The working tree was clean before this evidence directory was created. No branch/index/history operation was performed.

Authority: [exact owner instruction](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/owner-authorization.txt). [Baseline and every tracked-file hash](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/baseline.json); [canonical inputs and versions](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/canonical-inputs.json); [current host and read-only state commands](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/results/current-environment-and-state.json). This assessment supplements the [previous provider/fixture qualification](m1-provider-and-fixture-qualification.md); its evidence remains historical and unchanged.

The host is macOS 27.2/arm64; SDK 27.2. Previously retained static archives target macOS 26.0. Neither static targeting nor this source review qualifies macOS 26 runtime behavior. The Nx workspace skill required by AGENTS.md was searched previously and was unavailable; this assessment executes no Nx/product target, generator or build.

## 2. Provider identity, integrity and independent authenticity

| Field | Observation |
|---|---|
| Canonical source | Vendor release announcement links to the official sqlcipher/sqlcipher repository |
| Pinned commit — unchanged | 355d4db92d3404e71faa8088d071a71d767807f4 |
| Annotated v4.20.0 tag object | 52252487a5cada9b430e8d4b20025790c5a6ba20 |
| Commit tree | b3aa6f0a71413a40df4c968d357bbbbee61b42cb |
| Fresh tag/commit observations | Tag still resolves to the pin; commit verification unsigned; tag verification false / unknown_key |
| Release assets | API lists no separately attached binary/checksum/signature assets; release not immutable. Automatically generated source downloads are distinct from attached publisher attestations |
| Retained source archive SHA256 | fc5394c916beeabb1f43e2ac97d0827f36e8917f6675a00cca54537c32cb36a2 |
| Fresh retained-input check | Archive checksum unchanged; all 2325 archive files and all 2325 extracted source files match the retained SHA256/Git-blob manifest; zero mismatches |
| Static archives | Both retained archives still hash to ac0fed4b3c47b6259a87504b318fd4546018c880b0d60331a47e92c3f7a9856c; no rebuild or provider execution |

Fresh upstream metadata and acquisition timestamps: [tag reference](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/current-tag-ref.json), [annotated tag](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/current-tag-object.json), [commit](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/current-pinned-commit.json), [release](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/current-release.json). [Retained-input integrity recheck](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/results/retained-input-integrity.json); [archive hashes and verifier availability](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/results/local-prerequisites.json). These establish consistency with the observed upstream Git objects and retained inputs, not independent publisher authenticity.

### Exact trust blocker

The annotated tag claims Stephen Lombardo <sjlombardo@zetetic.net> as tagger. Its signature metadata claims issuer fingerprint **2646E8ECC00DAF4C2F67DBCD19A0457D05EA8350**. Claimed issuer/tagger metadata is not authenticated identity.

At inspection time the publisher's GitHub GPG endpoint said no keys were uploaded, and the GitHub user-key API returned an empty list. Zetetic's own security page publishes a support-email key, primary fingerprint **D83F5F9EB811D6E6B4A0D9C5D1FA3A2A97ED25C2**. Neither that primary key nor its three published subkeys matches the tag's claimed issuer. A support key is not automatically authorized to sign releases. The page's example lists an old expiry; this review does not infer current key validity or revocation status from that example.

No independently authenticated release-signing key binding, commit-specific vendor attestation, or vendor-authenticated archive checksum was established from the inspected sources. This is a bounded search result, not a claim that such material cannot exist. A public key obtained only by matching a keyserver fingerprint would not by itself establish publisher identity.

[Publisher key endpoint capture](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/github-publisher-public-keys.asc), [empty key API response](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/github-publisher-key-api.json), [vendor security page](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/vendor-security-page.txt), [vendor support key](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/vendor-security-support-key.asc), [metadata comparison](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/results/public-key-metadata.json).

The local environment has no gpg, gpgv or sq on PATH or at the checked common GnuPG locations. OpenSSL availability is not an OpenPGP verification result. No verification software was installed. The evidence parser only decodes bounded public OpenPGP metadata; it does not verify signatures, self-signatures, key binding, revocation or validity. No homemade cryptographic verifier was used.

**Workstream A overall: BLOCKED. Stop before runtime qualification.** The observed evidence neither proves tampering nor justifies a FAIL of the provider; it does not satisfy the required authenticity gate.

## 3. Workstream A criterion ledger

PASS below means only the stated bounded observation is satisfied. It is not a security approval or an EXP-03 result.

| Criterion | Status | Evidence and limitation |
|---|---|---|
| Canonical upstream identity | PASS | Vendor announcement identifies the official repository; HTTPS source observations do not independently authenticate a signed artifact |
| Exact release/tag/commit relationship | PASS | Fresh tag object/ref and commit/tree metadata agree with unchanged pin; moving tag/release is not the reproduction input |
| Retained source-tree/archive integrity | PASS | Fresh 2325-file/archive/source checks agree with the previously verified immutable-tree manifest; publisher compromise is outside this proof |
| Publisher-to-signing-key binding | BLOCKED | No independently authenticated release-key binding established; support key does not match claimed tag issuer |
| Cryptographic tag verification | BLOCKED | GitHub unknown_key; no matching authenticated key or installed OpenPGP verifier; metadata parsing is not verification |
| Independent source authenticity | BLOCKED | No verified publisher signature/attestation binds this exact pin or archive; same-channel tree/archive agreement is insufficient |
| License obligations / internal-use compatibility assessment | PASS | Retained source licenses permit use/redistribution subject to notices/disclaimer and no endorsement; scoped engineering review only, not organizational legal approval or distribution authorization |
| Current upstream security-source inventory/review | PASS | Vendor advisory/disclosure process, empty published GitHub advisory response and relevant issue/PR reports reviewed; no exhaustive CVE/SBOM review or vulnerability-free claim |
| Build/dependency provenance and repeatability assessment | PASS | Prior exact build/config/toolchain records retained; two current archive hashes still agree. Independent-machine, other architecture/SDK and runtime qualification remain absent |

Criterion counts: **9 reviewed: 6 PASS, 0 FAIL, 3 BLOCKED.** There are zero runtime test executions. These trust-review criteria are not new M1 case IDs and are not added to the 165-row acceptance matrix.

## 4. License, security posture and dependency considerations

SQLCipher's retained LICENSE.md permits internal use and source/binary redistribution while requiring copyright/license/disclaimer retention; binary notices must accompany distribution, and publisher/contributor endorsement requires permission. SQLite's primary source is public domain; autosetup/build utilities have separate permissive attribution terms. Required notices and an organizational dependency/legal review remain prerequisites to any future product integration/distribution. No public distribution is authorized.

License evidence remains in the previous run's sources/upstream-LICENSE.md, upstream-SQLITE_LICENSE.md and upstream-autosetup-LICENSE; baseline hashes and the final preservation audit prove those records were not rewritten.

Zetetic documents a security contact and responsible disclosure process. Its official 4.19 announcement describes fixes involving export alias input handling and malformed URI hex keys. The 4.20 pin follows that release, but this is not runtime regression evidence. The fresh published-advisory API returned an empty list; absence of listed advisories is not evidence of no vulnerabilities.

Fresh upstream records include issues #635 (savepoint/trigger rollback), #634 (integrity checks on preallocated pages), #617 (error state after a corrupt page), #601 (macOS x86_64 cross-build), and open PRs #636 (cached-page rekey authentication), #633 (salt/preallocation), #631/#630 (migration read-only/URI behavior). PR proposals and user reports are not vendor-confirmed or locally reproduced defects in this pin. Applicability and dispositions must be reviewed before qualification; especially do not treat a successful rekey/integrity check as a complete tamper oracle.

[Fresh advisory capture](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/upstream-published-advisories.json), [current issues and PRs](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/upstream-current-issues.json), [vendor advisory](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/sources/vendor-prior-security-advisory.txt). The issue endpoint includes PRs; the distinction is preserved. No runtime reproduction was attempted after the authenticity stop.

The previous configuration is SQLCipher 4.20.0 / SQLite 3.54.1, Apple CommonCrypto, arm64, min macOS 26.0 / SDK 27.2, SQLITE_HAS_CODEC, SQLITE_TEMP_STORE=3, THREADSAFE=1 and omitted load extensions. Exact configuration/build outputs remain in the previous run. These are compile/static observations, not observed runtime settings or proof that auxiliary files cannot contain plaintext. The binary-key API fixture was previously syntax-checked only. No production dependency, package manifest, lockfile or pin changed; no prebuilt third-party binary was executed.

Primary external references: [vendor 4.20 announcement](https://www.zetetic.net/blog/2026/10/27/sqlcipher-4.20.0-release/), [official release](https://github.com/sqlcipher/sqlcipher/releases/tag/v4.20.0), [vendor security policy](https://www.zetetic.net/security/), [publisher public key endpoint](https://github.com/sjlombardo.gpg), [vendor 4.19 advisory](https://www.zetetic.net/blog/2026/09/08/sqlcipher-4.19.0-release/), [pinned license](https://github.com/sqlcipher/sqlcipher/blob/355d4db92d3404e71faa8088d071a71d767807f4/LICENSE.md). Local captures retain the inspected observations.

## 5. Runtime, storage and interruption outcomes

| Workstream | Required conditions from owner checklist | Qualification status | Execution / evidence |
|---|---|---|---|
| B — Runtime (8 conditions) | Encryption enabled; encrypted database at rest; correct-key authenticated reads; wrong-key failure; cross-profile isolation; tamper detection; integrity-check semantics; no unintended plaintext temp/auxiliary writes | BLOCKED | NOT EXECUTED — A did not pass. No linked/loaded provider, runtime settings/key-binding result, encrypted database, runtime harness or runtime logs created |
| C — Storage surfaces (6 conditions) | Main; WAL; SHM; rollback journal; temporary database files; temporary operation storage | BLOCKED | NOT EXECUTED — no new synthetic encrypted artifact inventory, signatures, plaintext scans or cleanup observations. Prior plaintext detector controls remain preparation only |
| D — Interruption/key boundaries (7 conditions) | Interrupted writes; process termination during writes; reopen; wrong-key recovery; rotation boundaries; profile-key separation; preservation without silent loss | BLOCKED | NOT EXECUTED — no interruption/rekey/fault worker or synthetic recovery campaign launched |

Counts are deliberately separated: 9 source-review criteria above; **0 runtime tests executed, 0 runtime passes, 0 observed runtime failures**. The 21 owner checklist conditions are blocked prerequisites/coverage obligations, overlap across workstreams and are not 21 executed or newly registered test cases. The requested runnable runtime harness/report deliverable is blocked by the explicit stop condition, not silently considered prepared.

No native Keychain qualification, WebKit registry/cleanup campaign, EXP-04, original-store inspection/mutation, signing, notarization, release or product implementation occurred. No secrets or encryption keys were generated for this task.

## 6. Traceability and unchanged historical results

[Encryption specification](m1-persistent-profile-encryption-specification.md), [key/recovery specification](m1-keychain-and-independent-recovery-specification.md), [readiness assessment](m1-validation-readiness-remediation.md), [case matrix](m1-case-level-traceability.md). Existing REQ-05/06 → SPEC-04 → AC05/14/15 → EXP-03 / CRYPTO-001 remains BLOCKED. No EXP-03 acceptance, protected-artifact guarantee, key-lifecycle guarantee or recovery qualification is inferred.

Historical EXP-01 FAIL, cleanup-only INCONCLUSIVE/crash, EXP-02 INCONCLUSIVE, EXP-03–08 BLOCKED and SVC-01–05 BLOCKED are unchanged. All 154 validation-case rows and 11 experiment-reference rows remain unchanged; no aggregate pass rate mixes source checks, synthetic prior observations and acceptance cases. REQ-21 remains separate Stage C with no AC16; REQ-22/SPEC-08/AC08 retains existing EXP-01/02/05/07 routes.

Owner decisions/WS01.1 and ADR statuses remain unchanged: 0001 Proposed, 0002 Accepted, 0003–0005 Proposed. WKWebView conditional, CEF evaluation-only, Aura excluded, no production Tamizhi or mandatory cloud/identity; internal-only, local operation without cloud. Final macOS 26 runtime, signing/notarization and release gates remain mandatory and unexecuted here.

## 7. Commands, evidence and preservation

Executed source-only acquisition: python3 docs/architecture/phase-5/evidence/20261108T123527Z-m1-provider-trust-runtime-gate/inspect_provider_authenticity.py (see exact script under evidence); HTTPS GET metadata and public keys with default TLS validation, bounded responses and timestamps. Executed retained-input hash comparison: verify_retained_provider_inputs.py. Other actions: read-only Git/environment/tool availability/document/license inspection; documentation and preservation checks. [Machine-readable gate ledger](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/results/gate-results.json), [commands and artifact index](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/artifact-index.json), [final preservation audit](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/preservation-audit.json), [created/modified paths](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/changed-files.json).

The public metadata parser is an inspection aid, not a signature verifier. Hashing/tar reads do not execute provider code. No configure/make/build/test/benchmark/experiment or install ran in this gate; the only Python checks validate public source metadata and documentation/preservation, not product behavior. A read-only rg attempt referenced a nonexistent prior script name and exited 2; corrected inventory inspection located acquire_provider_source.py. It did not execute any provider or alter evidence.

Preservation includes every pre-existing tracked-file hash, all earlier evidence, Phase 3 source/manifests, owner/ADR records, source pin and product/dependency files. Only this new evidence/report and four append-only canonical references are allowed changes. The audit separately checks branch/HEAD/parent/index, tracked deletions/renames and local document links. Original browser stores are not touched or inspected by this audit; their state is not inferred from repository preservation.

The initial documentation audit checked links before its three generated index/audit/inventory files existed and reported one failed link check. That exact result is preserved in [the initial audit](../../evidence/20261108T123527Z-m1-provider-trust-runtime-gate/results/preservation-audit-initial.json). Output finalization was corrected and the metadata-only preservation/link check repeated after those files were generated. This is a document-finalization correction, not a provider/runtime test failure or retry; no source retrieval, build or runtime campaign was repeated.

## 8. Smallest next action and authority

Obtain, without sending credentials or keys, an independently authenticated publisher release-signing key and binding for the claimed tag issuer, or an equivalent vendor attestation binding the exact pinned commit/archive. Verify the complete signature/key validity/revocation context with a maintained OpenPGP verifier in an isolated trust context; preserve key/attestation provenance and verification output. A vendor-authenticated alternative must explicitly bind the artifact, not merely repeat its version. Do not substitute the support key, self-asserted tag fields, arbitrary keyserver match or another same-repository checksum.

No vendor contact was sent, software installed, pin changed or trust exception requested. Authenticity evidence is the immediate prerequisite; repeating builds or encryption tests cannot resolve it. Existing task authority permits bounded B–D only after A genuinely passes and sufficient licensing confidence remains. No additional owner decision is needed to review supplied authenticity evidence or continue those expressly scoped tests once their prerequisites are satisfied. A maintained verifier must also be provisioned with provenance and the applicable filesystem permissions. External messaging, a pin/strategy change or expansion into full EXP-03/04, production implementation or release requires separate scope/authorization. No owner waiver can be recorded as a successful cryptographic verification.

**Disposition: assessment complete with Workstream A BLOCKED; B–D BLOCKED / NOT EXECUTED. EXP-03 remains BLOCKED. Stop here.**

