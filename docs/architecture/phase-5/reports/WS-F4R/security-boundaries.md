# Security and persistence boundaries

Protected profiles remain unavailable. Every live main or mini page uses an explicit private scope and a real nonpersistent store. Spaces organize tabs within one scope and do not promise profile or website-storage isolation.

The mini owns a separate store. Transfer moves a validated URL and no cookies, LocalStorage, keys or engine handles. Website WKWebViews retain the permission mediator and have no privileged chrome handler. Split panes remain distinct published views. Target-blank routing checks the source and destination.

D2A-01 Option 2, SQLCipher, owner decisions and ADR statuses are untouched. The appearance-only ordinary SQLite allowlist remains. Private history, snapshots, restoration and backups stay excluded. There is no Aura, CEF, cloud or production Tamizhi integration.

Claims are limited to the native evidence. Signed Keychain, full lock/unlock, permission persistence, backup/restore and release qualification remain open. [Security gates](../WS-F3/next-gates.md)
