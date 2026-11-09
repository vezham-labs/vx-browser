# Failure analysis and preservation

- Initial native provider build failed on missing INT64_MAX declaration and unavailable explicit_bzero declaration. Corrected the header and used an explicit volatile overwrite for the probe's stack key. No general memory-erasure guarantee. Both successful provider attempts retain exact source and binary hashes separately.
- Initial app build was blocked by SwiftPM cache writes outside the sandbox. Initial contract attempt could not apply SwiftPM's nested manifest sandbox. Scoped build execution with the normal tools preserved application sandbox/signing configuration.
- First unrestricted app build failed Swift type checking for the purpose-key list. Added its explicit String array type and rebuilt.
- An intermediate contract run executed 25 tests but its source-stability guard failed after source changed during the run. It is not used as final regression evidence.
- The first settings run produced two failures in the missing-file check. Native Foundation may report NSFileReadNoSuchFileError for that lookup. The corrected path handles both recognized missing-file codes and preserves other errors. Prior 6 pass/2 fail remain separate.
- Earlier WS-F2 native media script errors and geolocation timeouts are preserved. Current terminal evidence is still required; no absent callback is a pass.
- Signed positive Keychain remains blocked. Protected write, interrupted migration/restore, disk full, WAL recovery and end-to-end session crash recovery cannot be meaningfully exercised against an absent durable product backend.

[Raw attempt history](evidence-index.md) · [Canonical dispositions](qualification-matrix.md)
