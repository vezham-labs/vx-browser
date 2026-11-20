# Installed pointer qualification

The tests used the installed UI Preview and Computer Use coordinate drags. UI accessibility snapshots supplied item identities and order after release. Setup used the browser’s own address field, tab menus and bookmark editor. The principal test window returned a 2880 × 1648 capture. The last two link conversions and the grouped-to-pinned drop also ran at 2360 × 1520. [Retained before and after observations](installed-ui-witness.json)

| Genuine drag coordinates | Result observed in the sidebar |
| --- | --- |
| (220, 218) to (82, 218) | Navigation Bravo moved from second to first. Clicking (82, 218) switched the loaded page from Navigation Charlie to Navigation Bravo. |
| (82, 218) to (220, 218) | Navigation Bravo returned to second. |
| (220, 218) to (840, 218) | Web-content target rejected. Original Favorite order remained. |
| (165, 580) to (165, 512) | Pinned Navigation Bravo moved ahead of pinned Navigation Charlie. |
| (165, 712) to (165, 512) | Unpinned Visual fixture remained in Tabs and pin order remained unchanged. |
| (165, 780) to (165, 712) | Unpinned Visual fixture moved ahead of unpinned Navigation Bravo. |
| (167, 846) to (167, 777) | Visual fixture moved ahead of Navigation Bravo within Visual study. |
| (165, 580) to (165, 504) | Bravo bookmark moved ahead of Alpha bookmark in the root. |
| (165, 580) to (165, 647) | Alpha bookmark moved onto collapsed Reading. Expanding Reading exposed it as a child. |
| (175, 716) to (175, 640) | Folder child moved ahead of Alpha bookmark within Reading. |
| (175, 716) to (175, 518) | Alpha bookmark moved beside the root Bravo bookmark. |
| (165, 580) to (220, 218) | Alpha bookmark became the third Favorite with its original URL. |
| (358, 218) to (165, 579) | The promoted Favorite returned to Reading as a bookmark. |
| (574, 305) to (626, 305) | Sidebar width advanced from 288 to 314 points. The reverse gesture restored 288 points. |
| (1727, 745) to (1827, 745) | The native split divider moved from 567.5 to 617.5 points. |
| (220, 218) to (82, 218) | Reordered Favorites before an ordinary quit. The process exited and a new private session contained zero Favorites. |
| (180, 647) to (220, 218) | In the 2360 × 1520 window, the Reading child became a Favorite at its original URL. |
| (358, 218) to (170, 514) | The Favorite moved beside the root bookmark. |
| (168, 584) to (168, 387) | The grouped Bravo tab stayed in Drag boundary and the pinned Visual fixture row stayed pinned. |

The listed replay contains 19 outcomes plus a sidebar restore gesture. The unpinned reorder case uses the successful replay after both tabs had loaded. The pointer harness records post-release frames.

[Favorite before](feature-captures/favorite-final-before.jpg) · [Favorite after](feature-captures/favorite-final-after.jpg) · [Expanded bookmark and tab groups](feature-captures/vezham-collections.jpg) · [Split View](feature-captures/vezham-split.jpg)
