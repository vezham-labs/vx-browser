# M1 SQLCipher Publisher Authenticity Evidence — v1.0

Date: 2026-11-08. **Final trust-gate status: BLOCKED. Source-authenticity evidence acquisition only. No provider build/execution, runtime qualification, production dependency integration, signing, notarization, release or distribution authorized by this task.**

## 1. Exact baseline and authority

Repository: /Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser; origin https://github.com/vezham-labs/vx-browser.git. Branch **timeline**. Starting HEAD **9118f89930a738c5e9d4711c7718a1e373e49761**, parent **7fb95f769f9af0000997c2d193b3d3675d0ca6a6**. Checkpoint subject: “docs(phase-5): gate provider runtime checks”. Working tree clean before this new evidence directory was created. The previous gate checkpoint is committed in the immediate parent and its report/evidence are present in HEAD.

[Owner task](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/sources/owner-authorization.txt), [baseline and all 873 tracked-file hashes](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/baseline.json), [prior evidence and verifier inventory](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/results/prior-evidence-and-tools.json). All 32 artifacts indexed by the previous gate still matched their recorded hashes before acquisition. The [complete preceding trust report](m1-provider-trust-and-runtime-qualification.md), its source captures, findings and manifest were reviewed; no historical result was rewritten.

The repository's nx-workspace skill was found and read this time. No Nx project/task, generator, package manager, provider build or environment installation was invoked. No branch/index/history change was made.

## 2. Sources investigated and new evidence

| Investigated source | Fresh observation / limitation |
|---|---|
| Official Zetetic 4.20.0 announcement | Identifies release, official GitHub source and Apple provider context; does not itself authenticate the tag's claimed signing fingerprint or exact archive/commit equivalence |
| Official security page | Publishes support-email key; its older example expiry is not a current cryptographic validity decision |
| **Official SQLCipher verification instructions** | Newly located explicit authorization of the published key for SQLCipher package verification; current direct response links **4.20.0** core source ZIP and detached signature |
| Community and documentation pages | Official repository identity and digital-signature documentation route; Community Edition support routing is the community forum |
| Vendor key publication | Official verification page links /security/support_zetetic_net_public_key.gpg; 29,175 public key bytes retained; identical to the earlier support-key capture |
| Vendor 4.20.0 detached source signature | Published link fetched successfully; 459 bytes retained. Bytes have not been cryptographically verified |
| GitHub tag reference and annotated tag | Fresh reference → tag object → exact pin relationship agrees with prior record; signature remains unknown_key |
| Pinned commit and release metadata | Fresh successful follow-up reads confirm commit/tree and v4.20.0 release; commit unsigned, release not immutable, attached assets empty |
| Publisher GitHub public-key endpoint/API | No uploaded public GPG key / empty user-key array at inspection time; same-channel evidence would still need authenticated publisher binding |
| GitHub attestation lookup | Unauthenticated lookup for the previously retained codeload archive SHA-256 returned HTTP404 Not Found. This supplies no positive attestation and does not prove global absence, cover the unknown vendor-ZIP digest, or verify any provenance signature |
| Exact fingerprint / official signing-key searches | No authoritative statement binding the claimed tag fingerprint to this release was established from the bounded inspected search results and pages; not a claim that none exists anywhere |

Raw responses, request URLs/timestamps, SHA-256 values and HTTP statuses: [first acquisition](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/results/acquisition-summary.json), [published-artifact and bounded metadata follow-up](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/results/followup-acquisitions.json), [decoded response provenance](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/results/decoded-body-records.json), [source/key comparison](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/results/source-and-key-provenance.json). [Evidence index](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/artifact-index.json); [SHA-256 manifest](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/SHA256SUMS).

First commit/release API reads returned HTTP504; both responses were retained. One bounded follow-up per affected endpoint returned HTTP200; successful data is separately named and did not replace the failures. Direct raw HTTP pages were gzip-compressed; an initial UTF-8 inspection failed. Raw bodies were preserved, then bounded gzip-decoded copies were created. No authenticity failure is inferred from either transport/inspection issue. Initial link extraction did not identify the key link; the full official page and browser link inspection established its exact published URL. No arbitrary guessed signature/key URL or keyserver match was used.

Search previews initially referenced 4.18.0; the current direct vendor page and its captured HTML identify 4.20.0. The direct capture governs this report.

Primary publisher references: [verification instructions](https://www.zetetic.net/sqlcipher/verify/), [published key](https://www.zetetic.net/security/support_zetetic_net_public_key.gpg), [4.20.0 source ZIP](https://www.zetetic.net/downloads/sqlcipher/verify/4.20.0/sqlcipher-4.20.0.zip), [detached signature](https://www.zetetic.net/downloads/sqlcipher/verify/4.20.0/sqlcipher-4.20.0.zip.sig), [release announcement](https://www.zetetic.net/blog/2026/10/27/sqlcipher-4.20.0-release/), [security documentation](https://www.zetetic.net/security/), [Community Edition routing](https://www.zetetic.net/sqlcipher/community/). GitHub's [attestation API documentation](https://docs.github.com/en/rest/repos/attestations) distinguishes retrieval from cryptographic provenance verification.

## 3. Publisher identity and fingerprint findings

**New supported finding:** Zetetic's authenticated HTTPS verification page explicitly identifies **D83F5F9EB811D6E6B4A0D9C5D1FA3A2A97ED25C2** as its software/package-signing key. It is therefore more than an assumed support-key role. This improves the documented package-signing provenance; it does not authorize substituting that key for the different Git tag signer.

The tag's unchanged signature metadata claims **2646E8ECC00DAF4C2F67DBCD19A0457D05EA8350**; it is the same signature bytes as the preceding gate. The prior public-metadata record identifies the published key's primary fingerprint and three subkeys, none matching that claimed issuer. The newly downloaded key bytes exactly match the earlier capture (SHA-256 **b5fa10e62b50478db1236f3a8c7157074d71450a1f6a245eb77a71802202eefd**). This byte comparison and the vendor's fingerprint statement are not fresh cryptographic key validation. No custom signature verifier or replacement metadata-based validity claim was used.

The verification page's displayed 2027-08-02 expiry differs from the security page's older example. Neither example proves current key/subkey validity, self-signatures or revocation status. No official statement authenticating the tag's claimed 2646…8350 fingerprint was established in the inspected sources.

## 4. Exact source binding and cryptographic verification

| Source object | Observed exact relationship |
|---|---|
| v4.20.0 reference | Annotated tag object 52252487a5cada9b430e8d4b20025790c5a6ba20 |
| Annotated tag target | Commit **355d4db92d3404e71faa8088d071a71d767807f4** |
| Fresh pinned commit tree | b3aa6f0a71413a40df4c968d357bbbbee61b42cb |
| Release metadata | tag_name v4.20.0; target_commitish master is a branch label, not an independently signed commit binding |
| Previously retained codeload tarball | Prior checksum fc5394c916beeabb1f43e2ac97d0827f36e8917f6675a00cca54537c32cb36a2; historical integrity evidence preserved, no new archive campaign |
| Vendor source ZIP and detached signature | Different artifact/format from that codeload tarball; ZIP not downloaded or compared, checksum not measured, signature not verified; equality to the pin remains unverified |

**Cryptographic verification: NOT EXECUTED, prerequisite BLOCKED.** Fresh checks found no gpg, gpgv or sq on PATH, nor GnuPG at the checked common paths. No verifier was installed, no keyring imported/modified, and no gpg/version/signature command was run. Verifier name/version/provenance and signature stdout/stderr are therefore unavailable, not invented. Public-key validity, self-signatures, subkey binding, revocation, actual detached-signature issuer and exact tag/release signature validity remain unverified.

[Explicit verification non-execution record](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/results/signature-verification-status.json). In accordance with the owner's stop rule, acquisition did not proceed into cryptographic execution or provider qualification. The detached signature's presence/HTTP200 response does not satisfy the gate.

## 5. Qualification ledger

| Criterion | Status | Scope / missing prerequisite |
|---|---|---|
| Official publisher source/documentation identity | PASS | Authenticated HTTPS vendor pages identify SQLCipher repository and package-verification route |
| Explicit vendor package-key publication/role | PASS | Full fingerprint published and key bytes acquired from vendor-controlled URL; validity not cryptographically checked |
| Release-specific signature acquisition | PASS | Vendor-published 4.20.0 detached signature retained; acquisition only |
| Exact Git ref/tag/commit relationship | PASS | Fresh API identities agree with unchanged pin; not independent publisher authentication |
| Authorization/publication of claimed Git tag signer | BLOCKED | No independently authenticated matching release-key binding established for 2646…8350 |
| Key validity/self-signatures/subkey binding/revocation | BLOCKED | Maintained verifier unavailable; not executed |
| Exact tag or detached signature verification | BLOCKED | Maintained verifier unavailable; appropriate authenticated key and signed artifact still required |
| Vendor signed-archive equivalence to pin | BLOCKED | ZIP/signature verification and reviewed source-file equivalence/attestation not performed |
| Positive GitHub attestation evidence | INCONCLUSIVE | Scoped digest lookup returned404; no attestation verification attempted |
| **Overall pinned-provider authenticity** | **BLOCKED** | No complete authenticated-publisher + valid-signature + exact-pin binding chain |

These are source-review classifications, not M1 test-case or acceptance passes. No FAIL/malicious-source conclusion is inferred from missing evidence. Source availability, successful prior builds, same-channel checksums, fingerprint similarity and metadata parsing do not satisfy cryptographic authenticity.

## 6. Precise blockers, next action and unsent inquiry

Two potentially sufficient routes remain:

1. Authenticate the complete authorized tag-signing key for 2646…8350 through the publisher, validate its key/signature context with a maintained verifier, and verify the annotated tag binding to the unchanged pin.
2. Use the explicitly vendor-published package key to validate the 4.20.0 detached source signature with a maintained verifier, then establish a reviewed complete source correspondence or authenticated vendor attestation binding that signed ZIP to the exact pin. Equal version labels are insufficient; a ZIP digest must not be confused with the retained codeload tarball digest.

**Immediate execution prerequisite:** separately authorize/provision a maintained OpenPGP verifier with recorded version and provenance, without changing production dependencies. No software installation is authorized or performed here. Once available, a separately scoped verification task must still check validity/revocation, signatures and source binding; installing the verifier alone does not pass the gate. No runtime advance is authorized by this acquisition task, even if later authenticity succeeds.

An [unsent vendor inquiry draft](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/vendor-inquiry-draft.md) requests the authorized 4.20 key, full claimed fingerprint confirmation, authenticated full-key publication, exact commit binding, and signed checksum/attestation/archive correspondence. It includes the newly discovered official package-verification route and the Community Edition forum-routing caveat. No message was sent or account accessed; sending requires separate explicit authorization.

## 7. Changes, artifacts and preservation

Created this report, public evidence/provenance/status records, acquisition/decoding scripts, unsent draft, evidence index, SHA-256 manifest, change inventory and preservation audit. Appended references only to the canonical M1 README, trust/runtime report, source catalog and readiness report. Existing report bodies and prior evidence remain unchanged.

[File-by-file inventory](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/changed-files.json), [preservation audit](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/preservation-audit.json), [commands/artifact index](../../evidence/20261108T130406Z-m1-publisher-authenticity-acquisition/artifact-index.json). Every baseline tracked file is checked; only the four declared canonical append-only reference updates are allowed tracked changes. No commit, push, stage, branch switch, source-pin change, product dependency/code change, original-store access or environment install occurred.

EXP-01/03/04, native Keychain/WebKit work, provider builds/execution and all runtime/storage/interruption tests were NOT EXECUTED. Historical EXP-01 FAIL/cleanup crash, EXP-02 INCONCLUSIVE, EXP-03–08 and SVC-01–05 BLOCKED, all165 matrix rows and existing REQ/AC/SPEC/owner mappings are preserved. ADR0001 Proposed;0002 Accepted;0003–0005 Proposed unchanged. Conditional WKWebView, evaluation-only CEF, Aura excluded, no production Tamizhi/mandatory cloud/public distribution; mandatory macOS26/signing/release gates remain.

**Stop disposition: evidence acquisition complete; authenticity remains BLOCKED. No runtime qualification in this task.**

