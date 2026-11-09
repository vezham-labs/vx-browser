# Current-state audit

The audit began with a clean `timeline` checkout at the approved checkpoint. WS-F5 recorded 84 native assertions and 26 contract assertions across two launches, 12 stand-in UI passes, six public page loads, and verified restoration of both default handlers. The WS-F5 and WS-F4R manifests recorded 223 and 423 verified entries respectively. These counts are historical and excluded from WS-F5R totals.

The host is Apple Silicon on macOS 27.2 (26B123). The existing deployment target is 26.0. The [WS-F5 platform record](../WS-F5/platform-qualification.md) distinguishes those facts from actual macOS 26 qualification.

The current browser uses independent private sessions for the main window and each Mini. Tabs and split panes in the same window can share a session and its nonpersistent store. A content-process callback fences and poisons the corresponding scope. The current UI offers session exit when that scope loses its surfaces. See the [recovery investigation](process-recovery-report.md) for the storage and controller paths.

Owner boundaries for this increment are documented in the [case matrix](test-matrix.md). The prior [WS-F5 drag](../WS-F5/drag-drop-report.md), [accessibility](../WS-F5/accessibility-report.md) and [compatibility](../WS-F5/compatibility-report.md) reports retain their observed outcomes and limitations.
