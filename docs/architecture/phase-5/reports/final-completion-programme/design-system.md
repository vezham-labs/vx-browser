# Native browser design system

The implementation uses native semantic colors and AppKit/SwiftUI appearance. The reference audit has observable workflows, but it has no calibrated Arc 1.172.1 design tokens. The values here are Vezham tokens. Exact Arc spacing, colors and radii remain unverified.

| Role | Token or source | Use |
| --- | --- | --- |
| Surface | SwiftUI background | Main and Mini chrome respects the current appearance. |
| Sidebar | Regular material and native list selection | Sidebar navigation is distinct from website content. |
| Text | Semantic primary and secondary styles | Native dynamic text contrasts in system, light and dark modes. |
| Focus and palette selection | System focus and accent at 16 percent opacity | The selected command also exposes accessibility selection. |
| Brand | Existing orange Vezham wordmark | Main and Mini identity. |
| Typography | System body, caption, title2 and largeTitle | Tabs, footer, dialogs and welcome. |
| Chrome geometry | Toolbar 70 pt, footer 28 pt, separator 1 pt | Native and WebKit layout share the same bounds. |
| Sidebar geometry | 236 pt initial, 180–320 pt bounded, 8 pt resize hit target | Layout changes with the actual sidebar width and existing split threshold. |
| Spacing | 8 pt command row padding, 12 pt command stack, 14 pt toolbar inset, 22/28 pt sheet padding | Standard spacing for these surfaces. |
| Corners | 9 pt address and selected command radius | Shared native control outline. |
| Symbols | SF Symbols with native labels and help | Toolbar, command matches and onboarding. |
| Borders and shadows | System divider, native window and sheet shadow | No custom shadow or border color matching asserted. |
| Motion | System sheet transitions, direct manipulation during resize | Exact Arc timing and easing require a reference capture. |

Main keeps a 680 × 470 pt minimum content size and Mini 430 × 340 pt. The two-pane layout retains its 600 pt content-width threshold, after sidebar width and divider are applied. Current tab geometry, hover treatments and material rendering need visual review on matching OS and display settings.
