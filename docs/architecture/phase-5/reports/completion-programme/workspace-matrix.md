# WS-F7 product qualification matrix

All 20 product cases require signed Keychain and protected normal-profile admission. Core tests are unit and contract evidence. The tagged Go tests run real SQLCipher against disposable files.

| Case | Required outcome | Product status | Available evidence |
| --- | --- | --- | --- |
| F7-01 | Create, terminate and relaunch | Blocked | Worker reopens encrypted opaque payload. |
| F7-02 | Multiple workspaces and order | Blocked | Core layout checks. |
| F7-03 | Stable identities across relaunch | Blocked | Core layout round trip. |
| F7-04 | Lazy admission after durable restore | Blocked | Private workspace native fixture covers lazy admission. |
| F7-05 | Split, focus and divider restore | Blocked | Core and private native observations. |
| F7-06 | Durable mutation | Blocked | Worker payload compare-and-swap. |
| F7-07 | Private exclusion | Blocked | Current application has no durable workspace route. |
| F7-08 | Mini exclusion | Blocked | Private native isolation observations. |
| F7-09 | Persistent profile isolation | Blocked | Worker verifies separate roots and foreign scope rejection. |
| F7-10 | Unauthorized durable access | Blocked | Worker denies missing key and foreign scope. |
| F7-11 | Interrupted real writes | Blocked | Worker exits before and after rename. |
| F7-12 | Failed publication preserves previous state | Blocked | Worker preserves source hash on failed staging. |
| F7-13 | Malformed and truncated data | Blocked | Worker refuses corruption and reads explicit prior revision. |
| F7-14 | Durable schema migration | Blocked | Core synthetic V0 only. |
| F7-15 | Unknown durable schema | Blocked | Worker refuses authenticated future schema. |
| F7-16 | Stale revision | Blocked | Worker stale and concurrent compare-and-swap. |
| F7-17 | Repeatable durable migration | Blocked | Core synthetic V0 only. |
| F7-18 | Private diagnostics | Blocked | Fixture checks absence of synthetic marker. |
| F7-19 | Restore race | Blocked | Concurrent worker CAS only. |
| F7-20 | Explicit failure outcomes | Blocked | Worker reports typed outcomes and uncertain publication. |

Run each product case against the same signed browser build using two disposable normal profiles, one private session and one Mini. Use owned loopback fixtures. Record opaque revisions and typed outcomes. Preserve encrypted artifacts on failure. See the release and risk report for the responsible owners and prerequisites.
