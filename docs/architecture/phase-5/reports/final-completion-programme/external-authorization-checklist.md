# External authorization and environment checklist

## Protected production storage

Product and security owners need to approve an exact production provider admission specification before any product file is opened. Record the approved provider and hash, authorized native identities, catalog/profile boundaries, pre-key bytes and operations, descriptor ownership, sidecar allowlist and fail-closed outcomes. The existing 100-byte header allowance is scoped to the pinned qualification path. Extending it to production increases the authorized pre-authentication surface. Keeping it fixture-only preserves the current fence and delays normal profile restore. A separate key-first provider proposal would need review of its own format, migration, durability and key custody.

Approve production key provisioning, default app access-group scope, recovery/backup authority, retention and user-initiated deletion semantics, and rollback and incident response. Storage engineering must deliver and qualify the production descriptor broker, catalog writer and workspace mounting. Provision a positive signed Keychain candidate using the approved app identity and isolated disposable profiles. Record authentication, missing key, wrong group, revoke, rotation and restart controls. Keep the source ciphertext available when writes or migration fail. The current 20 product cases remain blocked.

## Signing and distribution

Release owner must provide a valid Developer ID Application identity with its private key available through the authorized signing environment, the matching team identifier, and an approved provisioning profile if required by the actual entitlements. Confirm the expected bundle identifier, effective application identifier and data-protection Keychain group on the signed artifact. Supply authorized notarization access through a local Keychain profile. Use the existing [release procedure](release-readiness.md) for signing order, packaging, submission, stapling and Gatekeeper.

## Reference and native test environment

Provide an authorized isolated Arc 1.172.1 test profile or dated reference captures. First-run account creation is restricted by the vendor. For each visual comparison match window size, OS appearance, scale and fixture content. Native qualification needs an isolated supported macOS environment for VoiceOver speech, physical pointer/trackpad and attributable WebKit process exits. Test signed runtime on macOS 26.0 and latest supported 26.x. [Arc desktop availability](https://resources.arc.net/hc/en-us/articles/19337669022103-Arc-for-Desktop-macOS-and-Windows)
