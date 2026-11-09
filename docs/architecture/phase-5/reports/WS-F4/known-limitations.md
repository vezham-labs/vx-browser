# Known limitations

- Protected profiles, durable browsing history, downloads, profile-aware preferences, recovery and production backups are unavailable. Temporary bookmarks are explicit, scoped to the current private session and held in memory.
- Website compatibility is bounded by native fixture evidence. Public HTTPS uses standard trust evaluation; third-party sign-in, complex media and native transfers remain outside these results. Private mode does not promise OS-level forensic erasure.
- The native AppKit browser hosts one window. Tab favicon extraction, independent windows, tab groups, cross-launch restoration and real remote suggestions are future work. Navigation controls and selected state reflect the currently admitted native views.
- The development host ran macOS 27.2. macOS 26.0/latest 26.x, valid development Keychain custody, Developer ID signing, notarization, distribution and final release performance remain unqualified.
- Existing WS-F3 qualification and D2A-01 scope are unchanged. WS-F4 authorizes no release or public distribution.

[Gate status](feature-status.md) · [Testing](testing-and-evidence.md)
