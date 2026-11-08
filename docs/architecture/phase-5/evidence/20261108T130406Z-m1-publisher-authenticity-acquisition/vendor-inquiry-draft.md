# Zetetic SQLCipher publisher-authenticity inquiry — UNSENT DRAFT

Status: Draft only. No external communication authorized or sent. Do not send without separate owner authorization.

To: Zetetic SQLCipher team <support@zetetic.net>
Routing note: Zetetic's Community Edition page directs community support questions to https://discuss.zetetic.net/c/sqlcipher. Confirm the appropriate recipient/channel before sending.
Subject: SQLCipher 4.20.0 — authenticated release-signing key and source-commit binding

Hello Zetetic SQLCipher team,

We are evaluating SQLCipher Community Edition 4.20.0 for an internal Vezham Browser feasibility/validation effort. We need to authenticate the exact retained source before any runtime qualification.

Our pinned source commit is 355d4db92d3404e71faa8088d071a71d767807f4. The v4.20.0 annotated tag object is 52252487a5cada9b430e8d4b20025790c5a6ba20. GitHub reports unknown_key for its signature. Its signature metadata claims fingerprint 2646E8ECC00DAF4C2F67DBCD19A0457D05EA8350.

Your official verification page https://www.zetetic.net/sqlcipher/verify/ publishes package-signing key fingerprint D83F5F9EB811D6E6B4A0D9C5D1FA3A2A97ED25C2 and links to the SQLCipher 4.20.0 source ZIP and detached signature. We understand that this is a separate package-signing route and do not assume that the support/package key is the Git tag signer.

Could you please provide or point us to an authenticated publisher-controlled publication confirming:

1. The authorized Git tag/release-signing key for SQLCipher 4.20.0, including whether fingerprint 2646E8ECC00DAF4C2F67DBCD19A0457D05EA8350 is authorized.
2. The publication location for the complete signing public key, its primary/subkey relationship, validity and revocation information.
3. That the authorized signature binds the exact pinned commit above, with the signed tag/object identity or a commit-specific signed attestation.
4. Whether the source ZIP at https://www.zetetic.net/downloads/sqlcipher/verify/4.20.0/sqlcipher-4.20.0.zip is equivalent to that pinned commit, and any intentional packaging differences or a reproducible comparison manifest.
5. An independently verifiable signed checksum or release attestation for that ZIP/pinned source, if available, and the authorized signing key for its detached signature.

For clarity, the previously retained GitHub codeload tarball has SHA-256 fc5394c916beeabb1f43e2ac97d0827f36e8917f6675a00cca54537c32cb36a2. This is not the vendor ZIP's checksum, and we are not asking you to endorse an unverified equivalence between those archive formats.

A public statement on your authenticated official domain, with full key material and a signed artifact/commit binding, would let us verify the evidence independently. A newly supplied key or unsigned private reply alone would not resolve the full verification requirement.

Thank you.

[Sender name and role to be supplied only if sending is separately authorized]

