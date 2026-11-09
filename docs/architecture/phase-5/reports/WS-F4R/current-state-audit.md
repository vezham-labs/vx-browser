# Baseline audit

Expected and actual starting HEAD were 7e537468a4feb4c8eb3d728375139c5a7d134bd2 on timeline. The working tree was clean. Reviewed the React shell, native host, typed bridge, WebKit adapter, Core lifecycle, previous milestone reports, ADRs and owner/security boundaries.

| Existing WS-F4 behavior | WS-F4R change |
|---|---|
| Horizontal tab strip and library sidebar | Primary vertical tab workspace, Spaces, pins and groups |
| Flat tab order | Scoped organization with stable native view identity |
| Single visible page | Two actual WKWebViews inside NSSplitView, with pane focus and narrow fallback |
| Main-window browsing only | Compact independent private mini-browser |
| Action palette | Search actions, open tabs and Spaces; enter a destination |
| Generic tab icon | Bounded page-provided favicon when available |

Historical WS-F0 through WS-F4 reports and source provenance remain at their original paths. [WS-F4](../WS-F4/README.md) · [WS-F3 gates](../WS-F3/next-gates.md)
