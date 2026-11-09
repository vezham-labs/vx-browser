# Native website-storage runtime

Swift6/macOS26.0 local package consumed by the existing AppKit app. `BrowserNativeStorage` implements the existing BrowserPorts using public WebKit APIs; it imports the exact Domain/Core/Persistence targets from the WS-F0 package without copying them or linking fake providers into the app.

Normal startup wires a private-only, memory-backed composition without creating WebKit objects or offering persistent profile access. Protected durable catalog integration remains gated; qualification uses explicit synthetic in-memory catalog/journal ports mirrored between actual app processes. No replacement plaintext product database is introduced.

See [architecture](../../../docs/architecture/phase-5/reports/M1/m1-wsf1-native-webkit-architecture.md), [qualification plan](../../../docs/architecture/phase-5/reports/M1/m1-wsf1-qualification-plan.md) and [actual results](../../../docs/architecture/phase-5/reports/M1/m1-wsf1-qualification-results.md). Native results are never inferred from contract/fake tests or a26.0 deployment target. Run the existing app's `storage-*` Nx targets with a registered evidence directory; do not launch against personal profiles.
