# Native Host, Core, Engine, UI and Storage Contracts

**Date:** 2026-11-07. **Status:** Proposed design only; no schema, migration, service or bridge implemented.

## Status, version and compatibility

This is a **proposed contract version 0.2** with a planned v1 command/event protocol. It is documentation, not Swift/TypeScript implementation, an installed bridge or an approved ABI. The [existing engine contract](../../../browser-engine-contract.md) remains an illustrative proposed API. Its TypeScript syntax does not select the trusted core runtime; its global-history facade must be split into a core-owned history repository before a future adapter implements it. Cookie/website-data/page-script methods are privileged adapter/native capabilities, never automatically chrome commands. No extraction feature is authorized.

Internal native interfaces use typed Swift values and async results; the future chrome boundary uses language-neutral versioned data. Propose an exact v1.0 schema and paired conformance fixtures, with explicit negotiation for later additive changes. Unsupported major/minor or unknown command fields/types return unsupported/invalid before effects. Do not rely on JavaScript structural typing, reflection or generated bindings as runtime validation. Schema/binding generation tooling is not selected or installed.

## Ownership context and common envelope

Every native intent is paired with a **host-created AuthorityContext** derived from the registered surface or service, not decoded from message claims. It contains issuer surface class, current surface epoch, AppRun, permitted immutable DataScope, relevant object generations, allowed operation classes and native authorization references. IDs are identifiers, not bearer authorization. A valid ProfileId in a JSON body cannot select a different profile or database.

Proposed chrome request data:

| Field                         | Meaning / validation                                                                                                                            |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| protocolMajor / protocolMinor | Exactly negotiated version, initially 1/0; unknown version fails closed                                                                         |
| requestId                     | Bounded canonical opaque identifier, unique for that surface epoch; duplicate payload mismatch rejected                                         |
| type                          | Explicit small command enum; no dynamic selector or arbitrary method string                                                                     |
| target                        | Registered WindowId/TabId/ViewId as required; must match native surface ownership and current generation                                        |
| expectedRevision              | Decimal-string state revision for mutations that require current-state preconditions                                                            |
| payload                       | Exact per-command schema, bounded depth/size/string lengths; no arbitrary paths, SQL, JavaScript source, cookies, credentials or engine handles |

AuthorityContext, native grants, store lease and effect identity are not frontend-provided authority fields. Recommend provisional limits of 64 KiB/request, 16 KiB navigation URL, 256 characters per ID, 100 rows/page and 256 pending requests/surface; owner/security implementation review must ratify or adjust these before transport work. These are proposals, not measured or existing limits.

## Boundary A — Host to Browser Core

| Operation family                  | Input / result                                                                  | Rules                                                                                                                       |
| --------------------------------- | ------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Start / quiesce / stop            | Host lifecycle context, explicit reason/deadline; ready/stopped/degraded result | Idempotent; reject new work after quiesce; native host decides OS lifetime                                                  |
| Create/close/select window or tab | Owned scope + bounded intent; stable runtime IDs/revision/effect                | Core decides model transition; host creates/destroys actual windows/views. Cross-profile move must create new ownership     |
| Navigate / stop / recover         | Owned view generation + validated navigation/recovery intent                    | Core returns bounded engine effect; no direct native object. Unknown URL schemes, stale owner and forbidden recovery reject |
| Repository request                | Persistent lease + typed mutation/query                                         | Explicit private refusal, revision preconditions and committed acknowledgement                                              |
| Snapshot / subscription           | Native caller scope + last state revision                                       | Minimized immutable projections; bounded buffering and explicit resnapshot on gap                                           |

Core pure policy and native authorization both run. Host must recheck authorization at the actual native side effect, not assume a prior core check stays valid across an await. Core errors carry coarse code/correlation, not raw SQL, internal paths or sensitive URLs.

## Boundary B — Core to Engine Adapter

Core issues typed create/dispose/navigate/stop/find/zoom/recovery intents against opaque view identities. The host/adapter owns the public engine objects, store binding and main-actor execution. No protocol argument is WKWebView/WKNavigation/NSView or a raw pointer. Capabilities are runtime facts with supported/partial/unsupported and limitations, not unconditional promises.

Every callback carries trusted adapter registration plus AppRun, DataScope, ViewId, view generation, NavigationId where relevant and sequence. The host/adapter binds these to its native registry; it must not accept page-supplied ownership labels as source authority. Reject retired generation, foreign scope, unknown request and duplicate/out-of-order state changes. Retiring a view clears its pending callbacks/prompts; a replacement view receives a new generation.

| Event                                 | Core transition / persistence                                                                             |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Top-level started / redirected        | Provisional state only; redirects keep current NavigationId                                               |
| Matching main-frame committed         | Update last committed descriptor; mint one CommitId if history policy permits and scope is persistent     |
| Progress / title / URL hint           | Advisory bounded projection; cannot fabricate a committed visit                                           |
| Finished / failed / stopped-cancelled | Close only the matching current navigation; stale terminals cannot close a newer one                      |
| Content process terminated            | Retire current generation, show crash/stopped state, invalidate pending services; no implicit auto-reload |

Per-view sequence does not order all profiles or all service channels. Navigation changes and permission/download operations have distinct request identities; no stale permission response is accepted merely because a view still exists. Missing origin/frame metadata limits supported permission behavior; unknown cannot become allow.

The old contract's navigation terminal set needs an explicit cancellation mapping and generation/authority fields before M2. Durable history queries/recording belong to the repository port, not a WK adapter. Record these as pending refinements; do not silently treat a documentation proposal as a completed engine implementation.

## Boundary C — Core and Future React Chrome

The future M3 host dispatcher maps a minimal operation allowlist to core intents; React renders sanitized projections. Initial candidate command families are select/create/close tab, navigate/back/forward/reload/stop, find/zoom and explicit recovery. Profile creation/deletion, grants and transfer actions require their later scoped schemas/authorization; listing them here exposes nothing today.

A reply reports rejected, accepted-pending, committed or failed with request correlation and a current revision. Accepted-pending is not a saved/finished result. Event streams include scope/surface epoch and snapshot revision; gaps/overflow trigger a fresh authorized snapshot, not silent loss of terminal/security events. Coalesce advisory progress; bound queues. A disposed surface receives no late sensitive reply. On resubscription, state replaces old projection rather than replaying user actions.

UI receives only data needed by its currently authorized window/profile. Address/title data is sensitive even when display is necessary; never store it in frontend localStorage/IndexedDB or logs by convenience. No cookie read/set, arbitrary script, SQL, Keychain, shell, filesystem path, raw native dispatch or implicit cross-profile search belongs in the chrome allowlist.

Actual chrome resource origin/scheme, hosting and transport remain an M3 decision. The host verifies fixed bundled top-level origin/frame and surface identity; privileged chrome cannot navigate remotely and retain authority. Remote websites get no such handler. No temporary permissive bridge is proposed to make M1 development easier.

## Boundary D — Core to Persistence

A `PersistentStoreLease` binds ProfileId, store identity and lease generation. Private DataScope is a different type and is rejected even if incorrectly passed at runtime. Propose typed repository methods for validated preferences, later bookmark/history CRUD, and explicit restore/permission/download metadata operations only when those feature slices are authorized. No generic execute-SQL, arbitrary file path, database handle or unbounded predicate is exposed.

Mutation input includes native MutationId, expected store revision and bounded domain operations. In one DB transaction the adapter validates header/lease, revision and receipt, applies the operation, increments revision and records the receipt. Return a typed commit receipt; same ID/different payload is rejected, same retained ID/same payload returns its known outcome. A retained receipt window is bounded; after eviction, an old expected revision must conflict rather than claim unlimited exactly-once execution. Private operations write neither data nor receipts.

On an async result, core checks ownership/generation and receipt before publishing. A caller that disappears cannot authorize another operation; an already committed write still exists and must be reconciled through snapshot/receipt. Cancellation is best effort before commit, not rollback magic. Database work has no native panel/network call inside its transaction. Busy, disk-full, corrupt, locked/key-unavailable, unsupported-schema, stale-revision, invalid-owner and private-persistence-denied are distinct coarse errors.

## Boundary E — Future Permission and Transfer Brokers

Request envelopes bind AppRun, DataScope, ViewId/generation, trusted requesting/top-level/frame origins where available, kind, user-action context, request/effect ID, revocation epoch and deadline. Host brokers enforce OS/TCC and current authorization immediately before work; policy cannot override OS denial. Unknown/unmapped kinds and missing required origin data deny. One-time/private grants are memory-only; supported persisted grants require explicit later product policy and revocation tests.

File selection/destination results use one-shot native opaque resource tokens, bound to request/scope/view/origin and current epoch. A string from UI cannot fabricate or reuse a valid token. The native broker owns security-scoped access and closes it on cancellation/disposal/expiry. Transfer metadata does not prove byte completion: the broker validates staging/finalization/quarantine before completion is accepted. Native tokens, selected file URLs, file contents and bookmark blobs never enter general UI state or persistent core tables.

Persistent transfer finalization needs later M5 crash reconciliation across files and DB; do not replay a write/overwrite because an operation receipt exists. Private payload output needs explicit user selection/disclosure, with no persistent private history or download metadata. No actual grant, chooser, download, device or Keychain operation is implemented here.

## Boundary F — Selected feature providers and lifecycle events

This draft0.2 refinement follows [Proposed ADR0005](../../../../decisions/0005-browser-capability-boundaries-and-lifecycle.md) and the [capability architecture](browser-capability-architecture.md). It adds semantic requirements to proposed M1 ports, not an installed bridge, new framework or generic plugin interface.

Use per-feature typed interfaces. This **uncompiled illustrative signature** shows the intended boundary, not source added to the repository:

```swift
protocol FindInPagePort: Sendable {
    func start(_ intent: FindIntent, context: AuthorizedViewContext) async -> FindOutcome
    func cancel(_ request: OwnedRequestID, context: AuthorizedViewContext) async -> CancelOutcome
}
```

`FindIntent`, outcomes and context are bounded domain values. Context is minted/validated natively, never trusted from UI fields; each side effect still rechecks ownership/generation. Find has explicit success/unsupported/cancelled/unavailable outcomes, not arbitrary operation names. Other services retain their own narrow interfaces. Shared lifetime conventions do not imply a common `invoke(name, payload)` or universal provider base class.

| Proposed contract family    | Required semantics                                                                                                                                                                                                |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Native binding descriptor   | Known feature kind/version, unique provider identity, declared dependencies/lifetime and data/effect inventory. Metadata gives no native permission; duplicates/unknown versions fail before activation           |
| Provider activation         | Host supplies only reviewed typed inputs; provisional resources/subscriptions are owned; ready is published only after successful setup. Missing optional dependency disables the affected feature                |
| Provider availability event | Exact typed family, contract version, native provider instance/generation, AppRun, owner scope, per-instance sequence and relevant snapshot revision. No arbitrary name/payload event bus                         |
| Request/result              | Existing authority context, target/generation and request correlation; no new grant from provider readiness. Error/unavailability cannot silently become allow/saved/completed                                    |
| Subscription lifetime       | Specific authorized projection, bounded queue, recheck at delivery/revocation, dispose with owner. Slow/failing consumer cannot block core policy/revocation; gaps require resnapshot                             |
| Stop/cleanup result         | Fence ingress/revoke capabilities first; cancel and reconcile already committed work; stop subscriptions/resources before dependencies. Idempotent exact-instance disposal; report cleanup-required if incomplete |

Events are read-only facts. Optional subscribers cannot rewrite/veto authorization, mutate core-owned state directly, create a durable event log or subscribe across profiles/private sessions. A feature needing an action sends a separately validated typed intent. No global-listener bypass or inherited permission appears in the contract. Core repositories alone persist selected approved facts under existing private/receipt/transaction rules.

Initialization rollback and teardown must specify async dependency order; do not assume an automatic disposer stack serializes all async work. Quiescing keeps required core/storage finalization endpoints alive until dependents reconcile, without allowing new reads/actions. Generation fencing rejects old replies after replacement/stop; a disposed presentation does not erase an already committed store result.

Registration is native composition of reviewed code, not a security sandbox. Future trusted extensions/AI use no ambient core/store/Keychain object or unrestricted command feed. Tamizhi content/intent access requires separate source/profile/view/purpose/destination/lifetime consent; model output has no native authority. No production Tamizhi or runtime plugin installation is authorized.

## Error, lifecycle and verification policy

Unknown input fails before side effects; authorization is rechecked after async boundaries and at native execution. Store/state revision conflicts return resnapshot/retry guidance, never automatic replay of a destructive command. Late results may be ignored for presentation but committed storage must be reconciled. No unsafe success fallback exists for unsupported engine capability or missing native metadata.

[M1 plan](m1-implementation-plan.md) defines later fake-port/repository tests; real transport hostile-message checks remain M3, real engine mapping M2, and profile/permission/transfer integration M5/M6. All implementation/security criteria are Not Tested now. Cross-profile/private leakage and unauthorized native access remain hard failures under [ADR 0001](../../../../decisions/0001-browser-engine-strategy.md).
