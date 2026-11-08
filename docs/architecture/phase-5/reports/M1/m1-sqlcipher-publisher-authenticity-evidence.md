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

## 8. Vendor archive cryptographic verification — 2026-11-08 (current checkpoint)

**Current bounded source-authenticity outcome: PASS through the signed vendor archive and complete pinned-source correspondence.** Sections 1–7 and the original header describe the preceding BLOCKED acquisition checkpoint and remain historical. This addendum supersedes that source-authenticity blocker only. It does not claim a verified Git tag signature, qualified runtime encryption, EXP-03 acceptance or production/release approval.

### 8.1 Baseline, authority and actual execution

Repository vezham-labs/vx-browser; branch timeline. Starting and ending HEAD **0139c80a519f1b90c2d06bacea9d2af2620b16cc**, parent **9118f89930a738c5e9d4711c7718a1e373e49761**. Working tree clean before this evidence directory was created. All 948 baseline tracked-file hashes and the previous acquisition manifest's 73 entries were recorded/checked.

[Current task](../../evidence/20261108T142421Z-m1-vendor-archive-verification/sources/owner-authorization.txt), [baseline](../../evidence/20261108T142421Z-m1-vendor-archive-verification/baseline.json), [preflight and previous-manifest checks](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/preflight.json), [explicit owner approval to install Homebrew GnuPG and required tool dependencies](../../evidence/20261108T142421Z-m1-vendor-archive-verification/sources/tool-install-approval.txt).

Installed approved Homebrew GnuPG 2.5.24 (formula 2.5.24_1, arm64_golden_gate bottle), using libgcrypt 1.12.4. Exact resolved executable: /opt/homebrew/Cellar/gnupg/2.5.24_1/bin/gpg; SHA-256 **21cb9adcad96b7be404014ff6e9fb837160a2135455c217dec9efe196cf0661a**. Recorded version output, installed receipt/formula and actual command arguments. Homebrew installed ten required tool dependencies and upgraded seven existing required tool dependencies; those host changes were covered by the explicit approval. Browser package manifests, lockfiles and dependencies were not changed. Homebrew's pre-release-macOS warning and ignored unrelated untrusted tap were retained; no tap-trust exception or macOS-security change was made.

[Installation record and dependency changes](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/tool-installation-record.json), [verifier version/environment/binary provenance](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/verifier-environment.json), [installed receipt](../../evidence/20261108T142421Z-m1-vendor-archive-verification/sources/gnupg-INSTALL_RECEIPT.json), [installed formula](../../evidence/20261108T142421Z-m1-vendor-archive-verification/sources/gnupg-installed-formula.rb).

All key operations used a fresh mode 0700 task-specific GNUPGHOME under /private/tmp/vx-m1-vendor-auth-t5_e63ng, --no-options, batch mode, disabled automatic key retrieval/autostart and no personal keyring. No ownertrust override or signing/private-key operation occurred. After verification the disposable keyring was removed; the authenticated extracted source remains in its owned temporary directory for review. GnuPG remains installed.

### 8.2 Exact official acquisition

The current official [verification page](https://www.zetetic.net/sqlcipher/verify/) was fetched with default HTTPS certificate validation. Every exact artifact URL below was confirmed in that captured page. No GitHub-generated archive or mirror was substituted, and the original downloaded bytes remain unchanged.

| Artifact | Official URL | Bytes | SHA-256 |
|---|---|---:|---|
| SQLCipher 4.20.0 source ZIP | https://www.zetetic.net/downloads/sqlcipher/verify/4.20.0/sqlcipher-4.20.0.zip | 21,014,800 | a1417a5a672a2342de6ae44e08ccd68487fa3d0a43212331f4226a0d00b51b9c |
| Corresponding detached signature | https://www.zetetic.net/downloads/sqlcipher/verify/4.20.0/sqlcipher-4.20.0.zip.sig | 459 | c5d13b33ff0bd57baa7cb92c2e835d8620add0f95940024dc72fdccbdd68854b |
| Vendor-published key | https://www.zetetic.net/security/support_zetetic_net_public_key.gpg | 29,175 | b5fa10e62b50478db1236f3a8c7157074d71450a1f6a245eb77a71802202eefd |

All three returned HTTP 200 without redirects or content encoding. Acquisition times, headers, filenames, sizes and hashes are in [vendor-acquisition.json](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/vendor-acquisition.json), with individual provenance records and original bytes under sources/. The ZIP was not inspected/extracted until signature verification and key-structure review passed.

### 8.3 Key structure, validity and signature verification

| Role | Full fingerprint | GnuPG inspection |
|---|---|---|
| Primary RSA4096 certification key | D83F5F9EB811D6E6B4A0D9C5D1FA3A2A97ED25C2 | Matches owner baseline and explicit vendor package-key publication; current self-certification verified; expires 2027-08-02T21:57:52Z |
| Actual RSA3072 signing subkey | A4EA79E649E745B92117A56F0CB99EE267FD0322 | Binding signature verified under primary; signing capability; expires 2027-08-02T21:58:05Z |
| RSA3072 encryption subkey | 466459A718EC371CDD171FC03A7D809DD4DFEDA7 | Primary binding verified; expires 2027-08-02T21:58:33Z |
| RSA3072 authentication subkey | 5AE773802F16DD3AE688050462AE2C1CB1C49DF6 | Primary binding verified; expires 2027-08-02T21:58:49Z |

GnuPG inspected the full public certificate/packets and checked UID self-signatures and all three subkey bindings. The latest self-certification and binding signatures verified; no revoked/expired/invalid key flags or revocation packets were found in the freshly published certificate at inspection time. Three third-party UID certifications remained unverified because their keys were absent; they were not used as identity evidence or fetched automatically.

**Detached ZIP signature: PASS.** GnuPG exited 0 and emitted GOODSIG and VALIDSIG identifying the complete signing-subkey fingerprint and its vendor primary fingerprint. Verification required cross-certification. The signature uses RSA/SHA-512. The actual signing subkey is therefore bound to the expected vendor-published primary, rather than merely sharing a short key ID.

GnuPG retained TRUST_UNDEFINED and the warning that the UID is not certified by a trusted signature. That is not hidden or overridden: the disposable keyring has no Web-of-Trust ownertrust. External publisher identity rests on the separately recorded official HTTPS publication of the complete primary fingerprint/key, which matches the owner-supplied baseline. Successful cryptography alone would not establish that identity.

[Exact GnuPG commands and exit codes](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/gpg-commands.json); complete [signature status output](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/gpg-05-verify-vendor-archive.stdout.txt) and [signature stderr/warning](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/gpg-05-verify-vendor-archive.stderr.txt); [machine-readable signature result](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/signature-verification.json); [key structure/revocation review](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/key-structure-review.json). The full show-key, packet, import and check-sigs stdout/stderr files are retained beside them.

Revocation/identity limits: checks cover the vendor certificate obtained at this acquisition time, not a guarantee against unpublished revocations or future key compromise. No independent out-of-band vendor identity ceremony or global keyserver refresh occurred. The official HTTPS publication is the documented publisher-controlled trust channel; it does not provide immunity to compromise of that channel. No custom cryptographic signature verifier was written.

### 8.4 Complete archive-to-pinned-commit correspondence

Only after the preceding PASS results, extracted the authenticated ZIP into /private/tmp/vx-m1-vendor-auth-t5_e63ng/authenticated-source. Checked paths, duplicate/case collisions, entry types and size bounds; extracted files are nonexecutable mode 0600 and no archive content was executed. The ZIP's recorded Git-relevant executable bits were compared separately from extraction permissions.

Fresh official Git metadata identifies pinned commit **355d4db92d3404e71faa8088d071a71d767807f4**, tree **b3aa6f0a71413a40df4c968d357bbbbee61b42cb**. The recursive tree was complete, not truncated. Reconstructed all 60 Git tree objects from their full paths, modes and child identities and matched the pinned root. Every signed-archive file's Git blob identity and SHA-256 was calculated and compared with the full pinned-tree inventory.

| Comparison category | Actual result |
|---|---:|
| Archive files / pinned Git files | 2,325 / 2,325 |
| Exact byte matches | **2,325** |
| Archive-only files | **0** |
| Git-only files | **0** |
| Content differences | **0** |
| Git executable-bit differences | **0** |
| Packaging-generated/extra source files | **0** |
| Version/source-layout differences | **0** |

**Correspondence: PASS — exact source-file bytes and Git-tracked executable modes.** The outer ZIP folder sqlcipher-4.20.0 was normalized; ZIP container metadata/directory entries are not Git source files. No packaging exclusion or content exception was needed. VERSION contains 3.54.1, the SQLite baseline; the SQLCipher 4.20.0 release identity comes from the publisher release/verification documentation and full source correspondence, not a version-only assertion. Total uncompressed file bytes: 119,699,518.

[Complete comparison and every exact match](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/archive-to-commit-comparison.json), [sorted archive SHA-256/blob manifest](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/archive-file-manifest.json), [60 reconstructed Git tree objects](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/pinned-tree-object-verification.json), [deterministic comparison without run time/temporary path](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/archive-to-commit-deterministic.json). Deterministic comparison SHA-256: **7cde345937ded908c50d392eb3c72413ae6f08bf3fc0e52d7bde9461adc88c4d**. Original Git metadata, acquisition URLs and source/comparison scripts are retained; no pinned-source record was changed.

A supplemental [direct byte comparison](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/retained-pinned-source-byte-comparison.json) compares every authenticated extracted file with the retained pinned source and checks the latter against its original SHA-256 manifest. All 2,325 byte comparisons and 2,325 retained-manifest checks passed. The retained source was read only; this supplements the fresh Git-object comparison and does not replace its exact commit/tree binding.

### 8.5 Decision and remaining boundaries

| Gate | Current outcome | Meaning |
|---|---|---|
| Maintained verification environment | PASS | Explicitly approved host tool; recorded version, binary and package provenance; disposable keyring |
| Official ZIP/signature/key acquisition | PASS | Exact official artifacts acquired and preserved |
| Certificate self-signatures/subkey bindings/current published validity | PASS | Bounded to the freshly acquired vendor certificate and stated revocation limits |
| Exact archive cryptographic signature | PASS | GnuPG valid signature by the expected vendor-primary-bound signing subkey |
| Complete signed-source-to-pin correspondence | PASS | Every pinned source file/byte and executable bit matches; no missing/extra/content exceptions |
| **Bounded source-authenticity prerequisite** | **PASS** | Official publisher-key publication + valid vendor-archive signature + exact pinned-source identity |
| Separate Git tag signature | BLOCKED / not verified here | Earlier unknown_key route is not reclassified as verified; claimed 2646…8350 publisher binding remains unresolved |
| Runtime provider/security qualification and EXP-03 | BLOCKED / not executed | This source-only task grants no runtime/database/encryption campaign or acceptance pass |

**The source-authenticity prerequisite can advance through this vendor-archive route.** Authenticating the separate tag signature is no longer needed to establish this exact signed-source correspondence, but its historical limitation remains recorded. This does not independently qualify earlier static binaries, provider configuration, security advisories, encrypted storage surfaces, recovery, production dependency integration or release.

Next work requires a separately scoped provider-runtime qualification decision with frozen build/configuration, synthetic data, key-binding/artifact/failure oracles and the remaining readiness prerequisites. No runtime action follows automatically from this PASS.

### 8.6 Evidence, preservation and completion

[Final evidence index](../../evidence/20261108T142421Z-m1-vendor-archive-verification/artifact-index-final.json), [final SHA-256 manifest](../../evidence/20261108T142421Z-m1-vendor-archive-verification/SHA256SUMS-final), [final file-by-file change inventory](../../evidence/20261108T142421Z-m1-vendor-archive-verification/changed-files-final.json), [final preservation audit](../../evidence/20261108T142421Z-m1-vendor-archive-verification/preservation-audit-final.json), [disposable-keyring cleanup](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/disposable-keyring-cleanup.json), [qualification decision](../../evidence/20261108T142421Z-m1-vendor-archive-verification/results/qualification-decision.json).

The [initial preservation audit](../../evidence/20261108T142421Z-m1-vendor-archive-verification/preservation-audit.json) recorded 21 successful checks and one formatting failure: a new blank line at EOF in this addendum. That line was removed. The initial audit/index/inventory/manifest remain immutable; final-named records supersede only their documentation-finalization status. No signature or source comparison was rerun to correct formatting, and no cryptographic failure occurred.

Updated only append-only canonical references/addenda: this dedicated report, M1 README, source catalog, trust/runtime report and readiness report; all other tracked files and earlier evidence/manifests remain unchanged. Host changes are the explicitly approved GnuPG/tool-dependency installation. Personal keyrings and original browser stores were not accessed. No SQLCipher build, provider/database runtime, EXP-01/03/04, Keychain/WebKit qualification, vendor message, signing/notarization/distribution, stage/commit/push or branch switch occurred.

Historical experiment/acceptance outcomes and all 165 matrix rows remain unchanged. No M1 REQ/AC is marked passed by this source check. Owner decisions/WS01.1 and ADR statuses remain unchanged: 0001 Proposed, 0002 Accepted, 0003–0005 Proposed; conditional WKWebView, CEF evaluation-only, Aura excluded, no production Tamizhi/mandatory cloud/public distribution. Mandatory macOS 26/runtime/security/release gates remain.

**Current checkpoint complete: vendor archive signature PASS; exact pinned-source correspondence PASS; bounded source-authenticity prerequisite PASS. Runtime qualification remains unexecuted.**
