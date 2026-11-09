# Keychain and signing

The development qualification bundle is internal.vezham.browser.wsf1.qualification. It is ad-hoc signed with App Sandbox, outgoing network client and Hardened Runtime. There is no valid development signing identity on the Mac, no TeamIdentifier or selected provisioning configuration for this bundle, and no declared custom Keychain access group. The current app has no camera/microphone entitlements or purpose strings. No changes to signing, TCC, Keychain ACLs or project entitlements were made.

The production adapter uses the data-protection Keychain with userPresence and WhenUnlockedThisDeviceOnly, non-synchronizing items and scoped leases. Both app runs reproduced create/delete OSStatus -34018 and lookup -25300 after failed creation. Missing-item controls are native negative evidence. Wrong-scope contract controls do not hit the OS. No item creation, retrieval, deletion, persisted-key reopen or rotation qualified. No loaded key existed to validate cryptographic revocation.

The exact external prerequisite is an authorized valid development signing identity and consistent team/app entitlement and access-group configuration that can create and reacquire the intended Keychain items. Developer ID distribution and notarization are separate deferred release steps.

[Current environment](runtime-environment.md) · [Create witness](evidence/f2-security-native-154509919813/keychain-create-result.json) · [Restart witness](evidence/f2-security-native-154509919813/keychain-restart-result.json)
