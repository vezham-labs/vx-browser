# WebKit storage

The public API boundary remains as documented against macOS SDK 27.2. Named store construction, enumeration and removal are declared from macOS 14.0. Nonpersistent/default store APIs and record and type/date clearing are declared from macOS 10.11. Construct and assign the intended store before creating a WKWebView. No unset getter is used to establish policy, and existing named-store lookup remains fenced by the existing mapping/existence checks. Clear and full store removal are separate operations.

Use current fixture observations for scoped behavior and keep prior evidence separate. The named-store enumerate/lookup race, all callback failures, cache persistence, full portable website backup, forensic erasure and actual macOS 26 compatibility remain unqualified.

[SDK and ownership review](../WS-F2R-A/ownership-boundaries.md) · [Current runtime evidence](evidence-index.md)
