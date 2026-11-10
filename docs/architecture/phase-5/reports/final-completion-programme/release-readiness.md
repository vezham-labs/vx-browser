# Release readiness

The unsigned arm64 configuration uses the normal Release target and its explicit structural override. Debug remains sandboxed and ad hoc signed. The unified Go gate checks native framework linkage, architecture, minimum OS, metadata, legacy resource absence, signature integrity, Developer ID identity, runtime flags, sandbox entitlements and notarization ticket. The signed runtime gate remains visible as unexecuted. An unsigned build must fail this production gate.

From the repository root, run the build and local artifact checks:

    npm exec --offline -- nx run browser-macos:build-unsigned-release
    cd tools/vezham-qualify
    go build -o /tmp/vezham-qualify .
    /tmp/vezham-qualify native-bundle --bundle "$VEZHAM_RELEASE_APP"
    /tmp/vezham-qualify production-preflight --bundle "$VEZHAM_RELEASE_APP"

The local codesigning identity inventory reports zero valid identities. Developer ID signing needs an authorized Developer ID Application identity and private key, the associated team configuration, and approved entitlements or provisioning profile where applicable. Positive Keychain testing also needs an exact signed test bundle with the authorized default app identity and a disposable namespace. Keep the existing application sandbox and hardened runtime requirements.

For an authorized release, build the Release scheme without the unsigned override. Verify nested signatures and inspect the signed entitlements. Package the sealed app with ditto -c -k --keepParent. Submit the package with xcrun notarytool submit using the team's Keychain profile and --wait. After acceptance, staple and validate the application, repackage the stapled bundle, and assess it with spctl --assess --type execute. Record the signature, entitlements, exact app and package hashes, notary acceptance, and clean-install results. Run signed browser and Keychain behavior on macOS 26.0 and the latest supported 26.x. [Apple Developer ID signing](https://developer.apple.com/developer-id/) · [Apple notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)

No Developer ID signing, notarization submission, installation or distribution ran in this programme.
