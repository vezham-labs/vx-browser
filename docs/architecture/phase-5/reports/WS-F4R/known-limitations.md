# Known limitations

- Spaces, pins and groups are session-scoped. Protected profiles and signed Keychain remain deferred.
- The custom scheme was verified through macOS Open and the native URL handler. Default HTTP/HTTPS browser routing is unqualified.
- Split Screen is two panes. Narrow layout shows the focused pane and retains membership. Tabs are capped at 24.
- Favicons fall back when page policy, origin, size or supported formats prevent retrieval.
- Tests use owned loopback pages. Public-site workflows, VoiceOver, release performance and macOS 26 remain separate qualification.
- No physical erasure, forensic privacy, loaded-key revocation or full website portability claim follows.
