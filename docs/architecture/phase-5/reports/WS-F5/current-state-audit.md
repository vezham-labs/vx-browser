# Current state audit

Read-only audit before implementation: clean timeline at the owner-supplied WS-F4R commit. Historical SHA256SUMS: 423 matched, no missing/mismatched artifacts. Source inventory: 42 matched. Existing normal development binary differs from the historical qualification binary; no results transfer between them.

WS-F4R: 174 PASS_NATIVE (87 each on two launches); historical earlier-build storage observations remain separate. Actual drag gestures, VoiceOver, default routing and public compatibility were NOT_EXECUTED. Previous failures/incomplete attempts remain preserved.

- ApplicationDelegate.swift:51–65 accepts only vezham wrappers; Info.plist declares only that scheme.
- Chrome/src/navigation.ts:14–29 accepts HTTP while NativeWebKitStorage.swift:264–271 restricts it to loopback for interactive private browsing.
- MainWindowController.swift:543–546 duplicates URL policy with an IPv6 spelling discrepancy.
- Website adapter cancels unsupported MIME responses, upload panels, dialogs and non-server-trust authentication. Successful downloads/authentication are not implemented capabilities.
- Pointer gestures, focus/menus and controller release require native evidence, beyond DOM/typed bridge calls.
- Actual host 27.2 arm64; target 26.0 is not 26 runtime qualification.

References: [WS-F4R matrix](../WS-F4R/test-matrix.md), [baseline record](evidence/baseline.json), [tracked preservation inventory](evidence/baseline-tracked.json).
