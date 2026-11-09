# Profile locking

The existing native profile barrier retires WebKit views and denies stale navigation. NativeKeyBroker retains scoped lease controls, and Core fences permissions and keys through ports. Existing volatile-fixture lock observations and any new native rerun cannot establish loaded-key retirement, all-OS trigger coverage or protected unlock. The production path must atomically fence access admission, handle pending operations and leases, and reauthenticate scope/store/version at unlock. Loaded keys, interrupted unlock, sleep/wake and restart with durable state remain blocked or unexecuted.

[Current evidence](qualification-matrix.md) · [Historical handoff](../WS-F2R-owner-handoff/locking-permissions.md)
