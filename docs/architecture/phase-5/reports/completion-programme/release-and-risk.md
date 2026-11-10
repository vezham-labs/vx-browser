# Release procedure and remaining risks

The unsigned Release Nx target builds the native arm64 bundle with an explicit signing override. Go native-bundle independently checks metadata, native framework linkage, deployment target and absence of browser chrome assets. Release preflight checks signature and ticket evidence separately. The current environment has zero valid signing identities. The host is macOS 27.2.

For an authorized internal candidate, provision a Developer ID Application identity and matching team. Select the Release scheme with fresh DerivedData and set DEVELOPMENT_TEAM using local release configuration. Do not pass CODE_SIGNING_ALLOWED=NO in the signed build. Verify the sealed bundle with codesign --verify --deep --strict. Prepare a zip using ditto -c -k --keepParent. Use xcrun notarytool submit with --keychain-profile and --wait. Once accepted, staple and validate the app with xcrun stapler and assess it with spctl --assess --type execute. Store notary credentials in the approved Keychain profile. Record candidate and package hashes, entitlements and outcomes. Run installation, runtime, storage, private isolation, crash recovery, relaunch and upgrade/rollback checks on macOS 26.0 and the latest supported 26.x.

| Open item | Owner and action |
| --- | --- |
| Production protected provider | Storage engineering to integrate an authenticated descriptor broker and writer through ProtectedCatalog and lifecycle. Product/security owner to confirm production scope of the narrow pre-key exception. |
| Keychain custody | Signing owner to provision a valid authorized development identity and consistent app/team/access-group configuration. Qualify user presence, create, reopen, revoke and rotate on disposable profiles. |
| Native interactions | QA to test VoiceOver speech, keyboard traversal, drag/drop, divider dragging, resize and multiple displays. Verify focus through recovery and Mini. |
| Legacy host qualification | Browser QA to port DOM-dependent WS-F4/5 witnesses. Preserve prior evidence. |
| WebKit coverage | Browser QA to qualify attributable real process termination, external destination and download behavior and supported OS compatibility. |
| WS-F8 | Release owner to provision Developer ID and notary access, validate package and clean install, and run signed application tests on the supported OS matrix. |
