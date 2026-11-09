# Feature status

| Feature | Delivered state | Limit |
|---|---|---|
| AppKit shell | Implemented · bundled chrome, title bar, toolbar, native page area, sidebar | AppKit development candidate only |
| Tab interaction | Implemented · native create/select/close/duplicate/move, title, loading, overflow, keyboard and context actions | Generic icon; no restored protected session |
| Navigation | Implemented · real page views, address/search, history controls for each live view, failure state, clipboard and connection indicator | Local suggestions only; public HTTP unavailable |
| New tab and command palette | Implemented · search, manual favorites, keyboard and empty states | No recent-visit list from private sessions |
| Bookmarks | Provisional · explicit session-memory records, folders, filter, edit, reorder, remove and toolbar | Cleared on a new native session identity or termination |
| History | Availability UI · clear action disabled | Protected listing/filter/delete path blocked; private browsing records no product history |
| Downloads | Availability UI | No native transfer, Finder/open, cancel, retry or metadata deletion |
| Profiles | Availability UI · protected create and switch disabled | No unprotected default profile |
| Private | Implemented · actual nonpersistent WebKit and ephemeral Vezham state | No forensic erasure claim |
| Appearance | Implemented · native allowlisted global setting | Other durable preferences blocked |
| Website permissions | Availability UI; existing delegate policy preserved | Signed positive and persistent permission behavior still unqualified |

## Changed areas

- `apps/browser-macos/Chrome` · local HTML, Vite/TypeScript config, React and HeroUI chrome, bridge client, icons, navigation and tests.
- `apps/browser-macos/Sources/Host` · application qualification dispatch, window coordinator and Swift bridge contracts.
- `apps/browser-macos/StorageRuntime` · private-only interactive policy and tab navigation/error observation; existing assignment and security guards retained.
- `apps/browser-macos/Tools` and Xcode project · local asset build and bundle, qualification and regression entrypoints.
- `docs/architecture/phase-5/reports/WS-F4` · milestone reports and new evidence.

[Remaining dependencies](next-milestones.md)
