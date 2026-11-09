# Known limitations

- **Provider** · Read-only native fixture path. The no-lock simulation of the disposable single-file fixture is unsuitable for live stores. WAL/SHM, durable writer, crash consistency, app-process linking, protected migration, diagnostic/fault coverage and the full PQR matrix remain open. Scope, suite and key version checks do not establish anti-rollback.
- **Keychain** · No development signature capable of native positive custody. Real denied/missing OS results do not prove authorized operation. No weaker ACL, sandbox or signing workaround.
- **WebKit and permissions** · Bounded fixtures only. No comprehensive durable cache, error callback, engine portability, positive media or geolocation support claim. Ordinary app development does not establish release compatibility. Private cleanup does not imply forensic erasure.
- **Product persistence** · No protected catalog, profile DB writer, protected product repositories or production backup restore. The appearance allowlist is deliberately non-authoritative and plaintext. Normal startup remains fail-closed for persistent profiles.
- **Evidence** · Discovery ran on one macOS build. Per-case observations and repeated suites remain tied to exact binaries. Native synthetic keys are process-local and are not a substitute for signed custody. Interrupted/unsupported cases retain their recorded classifications.
- **Release** · macOS 26.0/latest 26.x, signing/notary, Gatekeeper, updater, performance and internal distribution release checks remain deferred or unexecuted.

[Remaining gates](next-gates.md)
