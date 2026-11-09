# Implementation status

| Area | Delivered implementation | Qualification scope |
|---|---|---|
| Option D decision and D2A-01 | Owner approval recorded append-only | Policy recorded, no change to earlier decisions |
| Plain SQLite allowlist | Typed appearance enum, single fixed table and schema constraints, read-only startup, explicit transactional setter | Repeated standalone native settings probe |
| Protected VFS | Real pinned provider binary, descriptor-backed bounded reopen, exact header exception, authenticated fixture identity and closed write fence | Repeated standalone native fixture tests |
| Protected application backend | Existing fail-closed normal startup retained | Blocked by missing product broker/repositories, custody and admission; no write, migration or recovery support |
| Keychain | Existing actual Security.framework adapter retained; no weaker ACL or configuration | App fixture negative controls only, positive signed custody blocked |
| Engine/profile | Existing guarded WebKit lifecycle retained, scoped permission navigation token introduced | Native discovery with injected metadata, independent of protected provider |
| Product browser data | No protected repositories for history, bookmarks, sessions, downloads, snapshots, preferences or grants | Not executed |
| Private | Existing memory and nonpersistent store integration retained | Discovery only; no production private UI or durable normal scope integration |
| Permission | Entry and terminal observation separated; pending tickets cancelled on stale/no-window; media grant rechecks navigation, origin, view and scope | Native script and API outcomes remain incomplete; positive paths blocked |
| Lock | Existing native view barriers retained | Native volatile-scope observations only; no active protected key/DB barrier |
| Backup | Existing synthetic encrypted owned-file adapter retained | Bounded fixtures only; production import and cross-Mac restore unexecuted |

See [qualification](qualification-matrix.md) for counts and [next gates](next-gates.md) for dependencies.
