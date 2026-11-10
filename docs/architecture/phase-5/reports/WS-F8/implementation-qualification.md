# WS-F8 actual qualification

| Check                                                   | Result                                                        |
| ------------------------------------------------------- | ------------------------------------------------------------- |
| Debug build and development bundle audit                | Passed; ad-hoc development scope only                         |
| Release configuration identity requirement              | Implemented and resolved settings inspected                   |
| Explicitly unsigned Release build                       | Passed structural build, including final corrected shell      |
| Go preflight on development bundle                      | Blocked, exit 3; Developer ID/ticket absent                   |
| Go preflight on unsigned Release bundle                 | Failed as expected, exit 1; not an acceptable signed artifact |
| Developer ID identity inventory                         | 0 valid identities; signing blocked                           |
| Real signed app, nested signatures and entitlements     | Blocked                                                       |
| Positive signed Keychain lifecycle                      | Blocked; historical negative evidence not rerun               |
| Packaging, notarization, Gatekeeper, clean installation | Not executed / signing-dependent blocked                      |
| macOS 26.0 and latest supported 26.x runtime            | Blocked; host is 27.2                                         |
| Public/internal distribution                            | Not executed; no authorization inferred                       |

[Exact commands](../developer-tooling/commands-and-results.md) · [Runbook](implementation-report.md)
