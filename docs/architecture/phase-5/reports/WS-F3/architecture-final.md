# Approved architecture and delivered boundaries

The [owner record](approved-decisions.md) selects Option D. These are the target boundaries and the delivered portion of each.

| Owner | Authority | WS-F3 state |
|---|---|---|
| WebKit | Cookies, origin storage, LocalStorage, IndexedDB, HTTP cache, service workers and website-data lifecycle | Existing public-API adapter retained. Permission callback gating and the qualification oracle were tightened. |
| Vezham | Product records, profile identity, storage mapping, retention, backup selection and browser policy | New low-sensitivity appearance setting is wired into AppKit. Protected native provider qualification is isolated from the application. No protected product metadata is routed through the low tier. |
| macOS | Sandbox, entitlements, OS authorization, native file capabilities, cryptographic randomness and Keychain | System services remain independent. The host lacks a signed Keychain development identity. |

BrowserDomain and BrowserPorts remain engine-neutral. The pinned SQLCipher archive is linked only into a standalone qualification executable. Normal application startup cannot publish a persistent profile until a protected catalog and lease path exist. Native WebKit uses named, nonzero stores for persistent fixture profiles and nonpersistent stores for private scopes. No website payload is copied into Vezham persistence. No engine-internal file access or portability/erasure claim is introduced.

[Baseline and classification](../WS-F2R-A/data-classification.md) · [Source status](implementation-status.md)
