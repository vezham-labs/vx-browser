# Split Screen

The coordinator holds two distinct published view IDs from the current private session and active Space. Each retains its own URL, navigation list, loading state and WebKit identity. The toolbar targets the selected pane.

NSSplitView mounts each WKWebView in its own wrapper. Clicking a page or choosing its heading selects that pane. The native divider keeps a 250-point minimum. Below 600 points of available website width, the host shows the selected view and preserves split membership. Widening restores both.

Exit Split keeps both tabs. Closing a pane invokes Core closure and returns the survivor to normal layout. Switching Spaces exits split without closing its tabs. Group/pin changes do not recreate views. Cross-Space and repeated-ID split requests are rejected.

[Lifecycle](native-lifecycle.md) · [Evidence](test-matrix.md)
