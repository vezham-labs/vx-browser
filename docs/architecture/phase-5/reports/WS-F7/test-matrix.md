# WS-F7 required persistence matrix

All rows require the protected production writer/profile authority and signed positive key custody. Existing in-memory or private regression checks are insufficient substitutes.

| ID    | Required observation                            | Actual result         |
| ----- | ----------------------------------------------- | --------------------- |
| F7-01 | Create workspace, terminate, relaunch, restore  | Blocked; not executed |
| F7-02 | Multiple workspaces and ordering                | Blocked; not executed |
| F7-03 | Stable identities across relaunch               | Blocked; not executed |
| F7-04 | Lazy WebKit admission after restoration         | Blocked; not executed |
| F7-05 | Split membership, focus and divider restoration | Blocked; not executed |
| F7-06 | Durable workspace mutations                     | Blocked; not executed |
| F7-07 | Private browsing exclusion at durable boundary  | Blocked; not executed |
| F7-08 | Mini session and website-storage exclusion      | Blocked; not executed |
| F7-09 | Persistent profile isolation                    | Blocked; not executed |
| F7-10 | Unauthorized durable access rejection           | Blocked; not executed |
| F7-11 | Interrupted real writes                         | Blocked; not executed |
| F7-12 | Failed publication preserves committed state    | Blocked; not executed |
| F7-13 | Malformed and truncated durable data            | Blocked; not executed |
| F7-14 | Supported durable schema migration              | Blocked; not executed |
| F7-15 | Unsupported future durable schema               | Blocked; not executed |
| F7-16 | Stale durable revision conflict                 | Blocked; not executed |
| F7-17 | Repeatable durable migration                    | Blocked; not executed |
| F7-18 | Privacy-safe durable recovery diagnostics       | Blocked; not executed |
| F7-19 | Restore races with user mutations               | Blocked; not executed |
| F7-20 | Explicit durable failure outcomes               | Blocked; not executed |

No process crash, filesystem failure injection, durable publication, encrypted workspace restore, migration-on-disk or persistent conflict test was executed.
