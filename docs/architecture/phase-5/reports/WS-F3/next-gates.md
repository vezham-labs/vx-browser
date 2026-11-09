# Remaining implementation, qualification and release gates

1. Finish the protected provider broker and product integration. Establish a supported isolated write path, scoped descriptors and sidecars, mutation/diagnostic coverage, safe transaction and migration behavior, and authenticated catalog/profile startup without fallback. Complete applicable OPEN-02–08 evidence and PQR cases.
2. Provision an authorized development signing identity, team, provisioning and access group for the sandboxed application. Qualify positive Keychain create, lookup, user presence, restart, rotation, deletion, and interruption/recovery on disposable accounts/items.
3. Couple real protected catalog/profile transactions, engine mapping, grants, view fencing and loaded key leases. Qualify concurrent profiles, creation/deletion interruptions, disk full, wrong/missing keys, identity mismatch, migration and OS lifecycle behavior. Finish permission capability and outcome coverage under OS consent.
4. Deliver protected history/bookmarks, session/recently closed state, downloads/snapshots and permissions. Qualify archive selection, durable protected import, interruption, corruption, deleted data, external conflicts and offline cross-Mac restore.
5. Qualify the final release separately on macOS 26.0 and latest supported 26.x with Developer ID, notarization, Gatekeeper, sandbox/Hardened Runtime, entitlement, updater, compatibility, distribution and performance evidence. Public distribution is unauthorized.

[Implementation status](implementation-status.md) · [Qualification matrix](qualification-matrix.md)
