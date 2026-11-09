# Signing and Keychain blockers

2026-11-09. Owner-review package against `timeline` commit `d90ef9b029568c650588ffbead99866ee1378710`. **WS-F2 remains INCOMPLETE. WS-F2R is proposed, not authorized.**

## Exact failed operations and context

Primary native attempt: [f2-security-native-113238831637](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-security-native-113238831637/result.json), using build `f2-build-113022470426`, executable SHA256 `17897e1450048796e69b4225ffeda47b2fd6e997dba2bb58ea3948034bf64d47`, bundle ID `internal.vezham.browser.wsf1.qualification`, macOS 27.2 build 26B123 / arm64. Synthetic namespace/profile/key identifiers are retained in exact input records; no real profile or user's existing key was selected.

| Case / operation | Recorded outcome | Meaning and limit |
|---|---|---|
| `F2-KEY-MISSING` / `SecItemCopyMatching` attribute lookup | PASS_NATIVE; absent item | Working negative control, not proof of authorized item creation/read |
| `F2-KEY-CREATE` / `SecItemAdd` | BLOCKED; `-34018`, adapter `unavailable` | Required entitlement missing; no successful item exists from this call |
| `F2-KEY-ACQUIRE` / `SecItemCopyMatching` for value | BLOCKED; `-25300`, adapter `missing`, in both processes | Item not found after failed creation; not a successful userPresence check or wrong-password test |
| `F2-KEY-RESTART-EXISTS` | BLOCKED | Creation prerequisite failed; separate missing-item control passed |
| `F2-KEY-DELETE` / `SecItemDelete` | BLOCKED; `-34018` | No successful deletion/absence qualification |
| `F2-KEY-WRONG-SCOPE` in both processes | PASS_CONTRACT | Adapter rejects before OS call; not OS-enforced cross-app isolation evidence |

Sources: [creation result](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-security-native-113238831637/keychain-create-result.json), [restart result](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-security-native-113238831637/keychain-restart-result.json), [NativeKeychain.swift](../../../../../apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeKeychain.swift) lines 39–50, 59–103. The captured [public SDK error definitions](../../evidence/20261109T105707Z-webkit-storage-wsf2/results/public-api-review.json) identify `-34018` as `errSecMissingEntitlement` and `-25300` as `errSecItemNotFound`.

## Signature and entitlements actually used

Both retained bundles were statically re-inspected during this handoff, without launching them. Each displayed `Signature=adhoc`, `TeamIdentifier=not set`, code-directory flags `0x10002(adhoc,runtime)`, no certificate `Authority=` chain, and no `Contents/embedded.provisionprofile`. Their executable hashes matched the historical records; `codesign --verify --strict` exited 0 for both. The final-host signature is also captured in [final-signature.json](../../evidence/20261109T105707Z-webkit-storage-wsf2/results/final-signature.json).

The signature entitlements contain exactly:

- `com.apple.security.app-sandbox = true`
- `com.apple.security.network.client = true`

There is no signed `keychain-access-groups`, application-identifier or team-identifier entitlement. The query itself omits `kSecAttrAccessGroup`, requesting the default authorized group; this is an intent, not evidence that such a group was provisioned. [Recorded entitlements](../../evidence/20261109T105707Z-webkit-storage-wsf2/f2-build-113022470426/entitlements.stdout) match the unchanged repository entitlement file. Debug config uses `CODE_SIGN_IDENTITY = -`; base config uses manual signing and disables base-entitlement injection. This is neither Apple Development nor Developer ID signing. The macOS ad-hoc signature must not be confused with Apple's separately named Ad Hoc distribution provisioning method.

The historical [identity discovery](../../evidence/20261109T105707Z-webkit-storage-wsf2/results/signing-identities.json) returned `0 valid identities found`. This review did not query the current Keychain/certificates or Apple account, so current credential availability is not independently established.

## Diagnosis and supported interpretation

Apple documents `errSecMissingEntitlement` as a missing required entitlement and recommends checking built entitlements/access-group membership. Omitting an explicit access-group key avoids requesting an unrelated group but cannot establish a missing application identity. [Apple error reference](https://developer.apple.com/documentation/security/errsecmissingentitlement).

Apple's macOS Keychain note explains that data-protection Keychain access groups derive from signing entitlements authorized by provisioning, and library access follows the host executable. The observed ad-hoc/no-team/no-profile app is therefore consistent with a signing/provisioning prerequisite for this required Keychain path. The exact OS internal entitlement evaluation was not traced, so this is a source-supported diagnosis, not proof that a particular new certificate alone will fix it. [Apple TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains).

The adapter deliberately retains GenericPassword, unique 32-byte normal-KEK candidate, data-protection Keychain, `WhenUnlockedThisDeviceOnly` + `userPresence`, `synchronizable=false`, exact profile/key/version identity and opaque native lease. No legacy file-Keychain substitution, weak accessibility, shared group, environment/file secret or ACL removal is proposed. [Original Keychain report](../M1/m1-wsf2-keychain-integration.md).

## Development and release are separate qualification boundaries

| Work | Current / development requirement | Official Vezham release boundary |
|---|---|---|
| Static entitlements/signature audit, Core negative policy, native view fences, synthetic CryptoKit/files | Can proceed with existing tools and scoped authority | Does not qualify final app identity or distribution |
| Successful data-protection Keychain create/duplicate/authenticated read/deny/restart/delete and loaded-key revocation | Needs a suitable authorized **development** signing/provisioning identity and isolated test bundle/default group; availability is unverified | A dev PASS does not qualify Vezham's official production identity/group |
| Development media/geolocation denial diagnosis and lock signals | Finite diagnostic work can proceed independently of Developer ID; positive device tests need supported APIs, test configuration and explicit device consent | Requalify actual final entitlement/purpose/consent and revocation behavior |
| Profile KEK/DEK envelope, rotation/recovery and source catalog integration | Missing implementation/provider/custody prerequisites remain even after signing works | Official identity upgrade/reinstall/recovery coverage remains mandatory |
| Developer ID, production access groups/entitlements, notarization and packaged candidate | **Deferred to release hardening** | Requires Vezham-authorized signing/provisioning credentials and exact final artifacts |

Apple distinguishes development/debugging builds from Developer ID direct distribution and notarization. An authorized development setup is a valid separate qualification target; it is not a promise that the current ad-hoc environment or any personal/free team can provision the required capability. [Apple distribution methods](https://help.apple.com/xcode/mac/current/en.lproj/dev31de635e5.html), [Apple notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

WS-F2R must not wait for production signing to investigate independent work. If development credentials are unavailable, keep successful Keychain/loaded-key cases explicitly BLOCKED and continue safe independent work; do not downgrade protection. Official Vezham identity/group continuity, signed upgrade/reinstall, final native key lifecycle, Developer ID, notarization, Gatekeeper and distribution remain mandatory release-hardening gates. None was executed or authorized here.
