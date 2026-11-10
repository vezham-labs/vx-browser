# Arc reference implementation slice

The application now offers a native keyboard command palette with local results for tabs, Spaces and enabled actions. Command-T opens the palette on Main. Selecting a destination admits a fresh tab through the existing serialized Swift command dispatcher and WebKit policy. Opening an existing tab or Space uses its stable layout identity. Mini keeps the address-field shortcut rather than opening a Main-only command palette.

The native sidebar exposes a bounded drag target and accessibility increment/decrement actions. Its width updates AppKit's WebKit content boundary, so the same two-pane fallback applies when a wide sidebar reduces content width. The app adds first-run and revisitable welcome, state-aware AppKit menus, and shared geometry tokens.

Workspace decode now validates the version and graph in Codable's initializer, in addition to the bounded serialized entry point. Direct JSON decoding can no longer bypass validation and expose an invalid graph to active-workspace accessors. A test exercises unsupported version and empty catalog. This does not admit the product catalog, provide a durable writer or restore product data.

Implemented work and remaining differences are listed in the [feature matrix](arc-parity-matrix.md) and [screen comparison](ui-ux-qualification.md).
