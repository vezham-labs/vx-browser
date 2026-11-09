# WS-F2 Keychain integration

2026-11-09. WS-F2 implementation/qualification review. [Closeout](m1-wsf2-closeout.md) · [Actual results](m1-wsf2-qualification-results.md) · [Evidence](../../evidence/20261109T105707Z-webkit-storage-wsf2/README.md). **No release approval.**

## Actual adapter and policy

`BrowserNativeStorage/NativeKeychain.swift` implements SecRandomCopyBytes, SecAccessControlCreateWithFlags, SecItemAdd/CopyMatching/Delete and LAContext. `NativeStorageSession.keys` connects it to the Core security lifecycle through the opaque ProfileKeyPort. Profile/run/epoch-bound KeyLease values contain no key bytes. IDs alone do not grant access: exact current host context, profile, run and reference version are checked before OS work and after async authority checks. Revocation advances epoch, invalidates contexts, retires the native cache and best-effort clears its owned buffer. CryptoKit/provider/Data copies and OS memory artifacts are not claimed erased.

| Configuration | Implemented value |
|---|---|
| Item | GenericPassword,32-byte normal KEK candidate |
| Service | `internal.vx.browser.keys.v1`; synthetic tests append `.qualification.UUID` |
| Account | scope kind/profile UUID/key UUID/version; no labels/URLs |
| Keychain | `kSecUseDataProtectionKeychain=true` |
| Accessibility/ACL | `WhenUnlockedThisDeviceOnly` with `userPresence`; no conflicting accessible attribute |
| Sync/groups | synchronizable=false; default app access group only; no shared/unrelated entitlement |
| Interactive unlock | fresh OS context with deviceOwnerAuthentication; denied/unavailable leaves locked |
| Noninteractive qualification | context interactionNotAllowed; cannot bypass userPresence |

## Actual native result and blocker

The ad-hoc sandboxed qualification app reached the real Keychain. Missing-item lookup succeeded; create and delete returned `-34018` (errSecMissingEntitlement), and lookup after failed creation returned `-25300` (item not found). Host discovery found0 valid code-signing identities. This is a signing/access-group environment blocker, not proof that the32-byte value or ACL is valid under a proper signing identity. No keychain access-group entitlement, weaker ACL, synchronizable item, file/env secret or conventional-Keychain fallback is added to make a test pass.

The first restart oracle incorrectly required existence after blocked creation and failed; that outcome is retained. The corrected run records the existence test BLOCKED and separately tests the missing-item control in another actual process. Foreign-scope rejection is PASS_CONTRACT, not native OS denial. Successful item creation, duplicate-item runtime, authenticated read/restart, rotation and full key recovery remain BLOCKED or NOT_EXECUTED. Coarse OS status numbers are retained without key bytes, key hashes or raw error contents. Qualification namespace/reference fixtures permit exact later inspection; no user's existing keys are queried or deleted.

## Upgrade, replacement and recovery limits

Stable signed app/default access-group identity and service/account continuity are prerequisites; actual signed upgrade/reinstall behavior is NOT_EXECUTED. ThisDeviceOnly material is not a cross-Mac recovery credential. Missing/wrong/denied items never regenerate a key over an existing profile. KEK rewrap/DEK rotation and independently authenticated normal/recovery slot publication retain the existing key specification; they are not silently replaced by direct bulk-key storage.

The native backup recovery handle is a purpose-separated, memory-only authority for synthetic archive qualification. It is not the profile DEK/normal KEK or a completed printable recovery kit. Normal/recovery envelope v1, custody verification, key-ring rotation, old-backup dependencies and independent second-Mac recovery remain unimplemented/unqualified. The existing OD-R08/19 requirements are preserved. Production key publication remains blocked until its required durable state and custody gates exist.
