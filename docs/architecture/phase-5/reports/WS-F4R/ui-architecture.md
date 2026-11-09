# UI architecture

React owns presentation, input drafts, menus, filtering, sidebar width and provisional bookmarks. AppKit owns ordered tabs, active view, Space membership, pins, named groups, pane membership and mini-browser controllers. Existing Core and Ports coordinate the private scope and view publication. Native snapshots reconcile the UI by revision.

~~~mermaid
flowchart TD
 Chrome[React chrome] --> Bridge[Existing typed bridge]
 Bridge --> Host[AppKit window coordinator]
 Host --> Organization[Session Spaces pins and groups]
 Host --> Split[NSSplitView]
 Split --> A[Published WebKit view A]
 Split --> B[Published WebKit view B]
 Host --> Mini[Independent mini window and private scope]
 Mini --> Transfer[Explicit URL transfer to main]
~~~

Vezham Mini uses the same trusted local bundle and bridge with a minimal render branch. Website content remains in native views. WS-F6 can connect authenticated profile capabilities behind this boundary.

[Host](../../../../../apps/browser-macos/Sources/Host/MainWindowController.swift) · [React](../../../../../apps/browser-macos/Chrome/src/Browser.tsx)
