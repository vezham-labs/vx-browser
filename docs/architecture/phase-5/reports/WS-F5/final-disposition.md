# Final disposition

**WS-F5 incomplete.** Scoped URL routing, lifecycle, keyboard and public-page checks passed on the macOS 27.2 arm64 development host. Primary-button drag is blocked. VoiceOver output and the exact synthetic auth/download denial path remain inconclusive. See the matrix for cases left unexecuted and release gates deferred by the owner.

The final candidate is build 07, SHA-256 `6af85394d6e5883a689adc0542d40547c2dbccde6f1fb883afbfe244bc0fe342`. Its two native launches each passed 42 native assertions and 13 contract assertions. The serial UI suite passed 12 stand-in cases. All results retain their original revision and classification. HTTP/HTTPS handlers were restored and verified as Arc. The isolated app was quit and the fixture stopped. [Final runs](evidence/native-04/summary.json) · [Restoration](evidence/final-default-routing.json) · [Preservation](evidence/preservation.json) · [Checksums](evidence/SHA256SUMS)

The next qualification increment is a primary-button drag session with observed native state for each target and cancellation case, followed by a VoiceOver walkthrough with recorded speech or captions. The required content-process recovery, authorized compatibility and platform cases stay open. ADR 0001 remains Proposed with conditional WKWebView acceptance. Changes are local and uncommitted on timeline.
