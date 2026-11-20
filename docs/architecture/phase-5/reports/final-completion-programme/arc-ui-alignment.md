# Vezham Arc UI comparison

Live inspection succeeded with `/Applications/Arc 2.app`, Arc **1.172.1 build 90370**. The original Arc path timed out and lookup by bundle ID was ambiguous because three copies share the identifier. The earlier session-stopped message did not identify what triggered the stop.

The installed preview is `/Users/vigneshwaranbhoj/Applications/Vezham Browser UI Preview.app`. The running process matched the installed executable and its SHA-256 matched the audited Debug build. The preview uses its own bundle identifier to avoid targeting another Vezham instance. Earlier app bundles were retained, including the prior preview build.

| Area | Observed in Arc | Implemented and verified in Vezham | Remaining gap |
|---|---|---|---|
| Expanded layout | Navigation and compact address field in left sidebar, rounded page inset | Moved controls into the sidebar and inset the native WebKit view. The installed preview loaded Example Domain in the new layout. | Exact spacing, color, typography and appearance comparison |
| Favorites | Icon-only tiles above the Space and tabs | Added accessible icon tiles and verified creation with distinct URLs. Clicking a Favorite loaded its associated URL. | Real favicon artwork and physical reorder |
| Space and tab hierarchy | New Tab above the selected tab row | Moved New tab above the list and consolidated workspace controls in More. | Arc Space dock and nested collections |
| Command entry | Floating search panel with selectable results | Simplified the native sheet. Verified ⌘T, URL entry and Return opened the expected page. | Floating placement, animation and suggestion parity |
| Sidebar and address keyboard flow | ⌘S toggles the sidebar | Verified collapse and ⌘L reveal. Fixed a focus regression and verified keyboard-only navigation to the exact typed URL after the fix. | Complete keyboard and accessibility matrix |
| Collapsed layout | Page fills the available window with the sidebar hidden | Page gains width and a compact toolbar keeps controls available. Native checks verify bounds and restoration after expansion. | Arc’s collapsed presentation differs |
| Pointer drag | Native input required for acceptance | Dragged between two Favorite tiles in the isolated preview. The accessible order did not change. | Successful pointer reorder, cancellation and cross-section moves |
| Private restart | Compared in a clean Arc incognito window | Quit and relaunched the installed preview. It opened inactive with no previous private tabs or Favorites. | Durable protected restore remains unavailable |

Arc and Vezham screenshots were displayed in the chat. Arc was captured at 1920 × 1050 and Vezham at 1180 × 760 and 2360 × 1520. A pointer resize attempt left Arc’s window unchanged. The captures do not form a matched pair, so pixel differences and overlays remain pending. The comparison used a disposable Arc window and the public Example Domain page.

Final preview and qualification builds, unsigned Release build, bundle audit and Release structure checks passed. The final workspace run passed **39 native and 7 contract checks**, including three geometry checks. The recovery run passed **34 native and 11 contract checks** using injected termination callbacks. The unsigned artifact was rejected by production preflight as expected. Developer ID signing, notarization and WS-F7 production persistence are separate outstanding gates.

Changes remain uncommitted on `cross-browser-research` at `ce2a9fa6a013b2f70f990c50468f27ed22517914`. See the [installation receipt](evidence/arc-ui-02/focus-installation.json), [launch identity](evidence/arc-ui-02/launch-identity.json), [workspace result](evidence/arc-ui-02/workspace-focus.stdout.txt), [recovery result](evidence/arc-ui-02/recovery-focus.stdout.txt) and [production preflight](evidence/arc-ui-02/release-focus-preflight.stdout.txt).
