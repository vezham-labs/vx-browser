# Runtime environment

| Item | Observed value |
|---|---|
| Host | macOS 27.2 build 26B123, Apple Silicon arm64 |
| Toolchain | Xcode 27.2 build 27B52, Swift 6.4.2, macOS SDK 27.2 |
| WebKit | 22625.2.8.11.9 |
| Final native app executable SHA-256 | 1d2578587f90cc1d73ac1febf0072b7db279a971128f0350ffb7b2782caddf6b |
| Previous native app executable SHA-256 | 7ae409473cdc7d4e5db579f4ea16d5ead3aaa25d7515c7cc095cf15ddbb044f1 |
| Signing | Ad-hoc with Hardened Runtime and no TeamIdentifier. Zero valid identities. |
| App entitlements | App Sandbox and outgoing network client. No media or custom Keychain group entitlements. |
| Provider | SQLCipher 4.20.0 Community / CommonCrypto, embedded SQLite 3.54.1, separately linked standalone qualification executable |
| Product low tier | macOS system SQLite, ordinary plaintext database. Separate from SQLCipher. |

The SDK WebKit header SHA-256 is `416940fc49e703de57c6da8ef372f98493503fb9d6cffe9d2b3479c6c62f4b9a`. The build target remains 26.0. Neither SDK availability nor 27.2 discovery qualifies actual macOS 26 runtime. CLI signature/entitlement data belongs to its own run, distinct from the AppKit signature.

[Environment commands](evidence/environment-commands.txt) · [Raw environment](evidence/environment.stdout) · [Final signing](evidence/final-signing.stderr) · [Provider binary and environment](evidence/provider-20261109T154014534033Z/environment.json) · [Settings binary and environment](evidence/settings-20261109T154359495015Z/environment.json)
