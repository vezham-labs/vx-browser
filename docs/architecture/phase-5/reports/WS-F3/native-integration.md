# Native integration

The AppKit qualification binary links the normal WebKit storage module and system SQLite. It was built with the existing sandbox and Hardened Runtime, and run on macOS 27.2 against disposable profiles, loopback origin fixtures and scoped test Keychain requests. Native WebKit case output includes cache and store lifecycle, process cutpoints, lock effects and a private termination/relaunch subset. Fixtures use injected metadata and cannot stand in for the persistent protected catalog.

The independent native provider probe links the authenticated retained SQLCipher archive. It exercises real ciphertext and POSIX I/O, with process-local keys. It has no app bundle identity or Keychain evidence. The Swift settings probe exercises the same low-tier source the app compiles and invokes during normal startup. Its CLI results do not assert normal app startup or app-container write qualification.

[Exact case counts](qualification-matrix.md) · [App binary and environment](runtime-environment.md) · [Provider evidence](d2a-01-option-2-qualification.md)
