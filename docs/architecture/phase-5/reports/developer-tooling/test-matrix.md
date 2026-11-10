# Delivered tool test matrix

| Area                                                     | Cases                                                                                                                        | Result                       |
| -------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ---------------------------- |
| SHA256                                                   | Valid file with spaces, changed, missing, traversal, absolute path, external symlink, duplicate, malformed, empty, directory | Passed 10 named subcases     |
| Manifest boundary                                        | Escaped manifest root and invalid hexadecimal digest                                                                         | Passed                       |
| Aggregation                                              | Pass, fail, block, unexecuted, skipped, N/A, unknown status, duplicate/missing ID, extra field, trailing JSON, empty         | Passed 12 named subcases     |
| CLI                                                      | Usage failures, deterministic JSON, exit 3 for blocked rows                                                                  | Passed                       |
| Executable integration                                   | Built CLI accepts evidence, rejects later tamper with exit 1                                                                 | Passed                       |
| Release negative controls                                | Missing bundle, platform plist dotted keys, real ad-hoc signed disposable bundle                                             | Passed on current macOS host |
| Static Go checks                                         | `go vet ./...`                                                                                                               | Passed                       |
| Automatic architecture and report validation subcommands | Not implemented                                                                                                              | Not executed                 |

This is 8 top-level tests plus 22 named table subcases; other assertions remain within their parent tests. Do not count these as 30 independent release gates.
