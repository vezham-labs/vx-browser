# Workspace data model

**Classification: PROPOSED.** The JSON below is a contract illustration for synthetic fixtures. It does not select a product file or database format.

## Entities and ordering

| Entity            | Required fields and relationships                                                                                                                                                                                |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Snapshot          | `schemaVersion` and `revision` plus `catalog` and `session`. Both sections belong to one library and are published in one revision.                                                                              |
| Workspace catalog | Ordered `workspaces` array of `id` and `name`. Workspace ownership is the authenticated profile-keyed library boundary, supplied out of band. F6 fixtures use a synthetic library authority.                     |
| Session layout    | `lastWorkspaceId` and `layouts`, exactly one per catalog workspace. Layout has `workspaceId`, `activeSpaceId`, ordered `spaces` and optional `windowFrame`. The F6 fixture mounts one main workspace at a time.  |
| Space             | `id`, `name`, ordered `groups`, ordered `tabs`, optional `activeTabId` and optional `split`. At least one Space per workspace.                                                                                   |
| Group             | `id`, `name`, `collapsed`. A flat group owns presentation, with tab membership via `groupId` within the same Space.                                                                                              |
| Tab               | `id`, `pinned`, optional `groupId`. A pin is ungrouped. The tab array owns ordering. The sidebar derives the pinned section and each group from it.                                                              |
| Split             | `leadingTabId`, `trailingTabId`, `focusedTabId`, `dividerBasisPoints`. Members are distinct same-Space tabs. Focus equals that Space's active tab and identifies the single visible pane under compact layout.   |
| Window frame      | Optional per workspace. Finite AppKit point values `x`, `y`, `width`, `height`, measured from the saved desktop coordinate space. Placement clamps to a visible current screen or falls back to a default frame. |
| Runtime binding   | `WorkspaceID`, `TabID`, mount generation, scope identity/epoch, operation, optional `ViewID` and status. No runtime binding is serialized.                                                                       |

Typed UUIDs are assigned once, represented as lowercase canonical UUID strings and checked for uniqueness within each ID type across a library. A rename, order change, scope transition or view retirement does not change an ID. A duplicate-tab command creates a new ID. Deleted IDs are never deliberately reissued, including after migration; concurrent writes use revision checks and runtime completion uses generation checks. A normal layout's IDs do not cross into private records. A profile/store identifier, engine handle or grant is never inferred from a layout ID.

## Validation and normalization

- **Bounds.** Start F6 with 12 workspaces per library and the existing limits of 12 Spaces, 24 tab slots and 32 groups per workspace. Names trim whitespace, contain 1–40 grapheme clusters and no control characters. The V1 fixture envelope is capped at 256 KiB before decode. Revisions are nonnegative and bounded by the JSON safe integer range, with no wrapping. Divider preference is an integer from 0 through 10,000; displayed bounds are native. Product limits and names are reviewable proposals.
- **Structural rejection.** Reject unsupported versions, malformed required values, duplicate identities, duplicate membership, missing/extra workspace layouts, explicit cross-owner references, impossible counts and values beyond caps. No partial write or engine demand follows. New commands also reject invalid targets, pin-plus-group membership, repeated split members and cross-Space pairs.
- **Optional repair for decoded known-version records.** A dangling group on a tab clears the group. A pinned-and-grouped tab keeps its pin and clears its group. A missing/stale active Space falls back to the first Space. A missing/stale active tab uses the first tab in stored order, or null if empty. A split with one surviving member falls back to that member as a single tab. Drop a pair with no surviving members or a repeated member and use the active-tab fallback. For a valid pair with missing/stale focus, choose the active member if eligible, otherwise the leading pane. Drop invalid geometry and use the native default. Keep repairs in memory and expose a diagnostic category. An optional reference proven to target a different workspace or authority fails closed. An ordinary dangling ID is never substituted with an object from another Space or workspace.
- **Empty state.** The default is one workspace with one Space and no tabs. No active tab, split, live view or load is implied. Closing or deleting a selected tab chooses the next tab at its previous index or the previous last tab. When one split member survives, that member takes precedence.
- **Selection.** An inactive Space retains valid split intent and its selection, with zero admitted demand from the inactive Space. Selecting a third tab in the active Space clears that Space's pair. Selecting a split member changes focus within the pair. Closing Split keeps both tabs and the focused tab selected.

[Mutation ownership](workspace-architecture.md) · [Recovery and migration](persistence-and-recovery.md)

## Serialized empty workspace

```json
{
  "schemaVersion": 1,
  "revision": 0,
  "catalog": {
    "workspaces": [
      { "id": "10000000-0000-4000-8000-000000000001", "name": "Personal" }
    ]
  },
  "session": {
    "lastWorkspaceId": "10000000-0000-4000-8000-000000000001",
    "layouts": [
      {
        "workspaceId": "10000000-0000-4000-8000-000000000001",
        "activeSpaceId": "20000000-0000-4000-8000-000000000001",
        "spaces": [
          {
            "id": "20000000-0000-4000-8000-000000000001",
            "name": "Start",
            "groups": [],
            "tabs": [],
            "activeTabId": null,
            "split": null
          }
        ],
        "windowFrame": null
      }
    ]
  }
}
```

## Serialized workspace with a split

```json
{
  "schemaVersion": 1,
  "revision": 7,
  "catalog": {
    "workspaces": [
      { "id": "10000000-0000-4000-8000-000000000002", "name": "Projects" }
    ]
  },
  "session": {
    "lastWorkspaceId": "10000000-0000-4000-8000-000000000002",
    "layouts": [
      {
        "workspaceId": "10000000-0000-4000-8000-000000000002",
        "activeSpaceId": "20000000-0000-4000-8000-000000000002",
        "spaces": [
          {
            "id": "20000000-0000-4000-8000-000000000002",
            "name": "Research",
            "groups": [
              {
                "id": "30000000-0000-4000-8000-000000000001",
                "name": "Drafts",
                "collapsed": false
              }
            ],
            "tabs": [
              {
                "id": "40000000-0000-4000-8000-000000000001",
                "pinned": true,
                "groupId": null
              },
              {
                "id": "40000000-0000-4000-8000-000000000002",
                "pinned": false,
                "groupId": "30000000-0000-4000-8000-000000000001"
              }
            ],
            "activeTabId": "40000000-0000-4000-8000-000000000002",
            "split": {
              "leadingTabId": "40000000-0000-4000-8000-000000000001",
              "trailingTabId": "40000000-0000-4000-8000-000000000002",
              "focusedTabId": "40000000-0000-4000-8000-000000000002",
              "dividerBasisPoints": 5500
            }
          }
        ],
        "windowFrame": { "x": 120, "y": 80, "width": 1180, "height": 760 }
      }
    ]
  }
}
```
