# M1 Supporting Validation Charters v1.1 — Proposed

## 1. Maintained baseline and scope

Version1.1 — Proposed supporting procedures, 2026-11-08. Five SVC charters and all154 case IDs (including120 permission rows) are preserved. The11 experiment-reference rows are additional traceability rows, not validation cases. The [source catalog](m1-source-catalog.md) identifies original documents; source observations in their historical review are not current experimental results.

Safe isolated validation is Authorized by the current owner instruction; product implementation/release remain Not Authorized. Current outcomes live in [reports](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/) and [the matrix](m1-case-level-traceability.md). OP-01–04 and the26-capability historical OD17 scope are [Owner-Decided](m1-owner-decision-register.md); absent artifacts/API mappings remain blockers.

## 2. Canonical sources and historical inspection record

The [source catalog](m1-source-catalog.md) identifies maintained versus supplied/historical documents. Canonical specifications and charters now exist in this directory; earlier source-not-found statements describe historical inspection only. Current production-source inventory, SDK-header observations and missing prerequisites are recorded in the run's validation-preflight.json. Three AppKit Ready-host sources exist; no four-target Core package, bridge or product storage implementation is present. Header declarations do not prove positive permission support.

## 3. Supporting validation coverage summary

| Charter | Primary coverage | Relationship to experiments |
|---|---|---|
| SVC-01 | Package/dependency, port/adapter, concurrency and static-provider conformance | Establishes structural prerequisites; does not replace runtime experiments |
| SVC-02 | Native/chrome authority, schemas, origins, lifecycle and event delivery | Validates the privileged bridge separately from website behavior |
| SVC-03 | Source-enumerated permissions and capability truthfulness | Complements profile/private/lock/restore experiments with per-kind authorization cases |
| SVC-04 | Integrated offline product operation | Distinct from EXP-04/07 offline recovery |
| SVC-05 | Host/content-process recovery and cross-resource consistency | Integrates experiment-qualified mechanisms without replacing their evidence |

### Common conventions

- **U** means **Unspecified — requires specification**.
- Procedures remain **Proposed**; current case outcomes are recorded separately in the canonical matrix. BLOCKED preflight is not execution.
- Case IDs are proposed by this package; they are not claimed to exist in repository tests.
- Environment codes are defined in §10.
- Artifact codes are defined in §11.
- Exact schemas, thresholds and API mappings must be frozen before execution.
- A mock or negative-only result cannot qualify a native positive workflow.
- Each charter inherits the hard stop: unexpected sensitive access, cross-profile/private leakage, destructive unowned action or protection bypass.

## 4. SVC-01 — Package and dependency conformance

### Charter definition

| Field | Definition |
|---|---|
| ID/title | SVC-01 — Package and dependency conformance |
| Procedure / current outcome | Proposed / BLOCKED (preflight; see campaign report) |
| Objective | Verify that concrete targets and contracts conform to documented ownership/dependency rules |
| Scope | Four targets, ports/adapters, SQLite ownership, host/Core responsibilities, static providers and concurrency boundaries |
| Exclusions | Website compatibility, cryptographic qualification, native permission success and release qualification |
| Question | Can the implementation preserve inward dependencies without concrete platform leakage or cycles? |
| Requirements | REQ-02/04/17/18/19; supporting REQ-03 |
| Acceptance | AC02/AC14/AC15 |
| Specifications | SPEC-01/02/03/06/14/15/16 |
| Owner dispositions | OD-R01/02/03/04/05/15/16 |
| ADRs | 0001/0003/0004/0005 Proposed; 0002 Accepted |

### Source-supported graph

The textual source supports:

- BrowserPorts → BrowserDomain.
- BrowserCore → BrowserDomain + BrowserPorts.
- BrowserPersistence → BrowserDomain + BrowserPorts + SQLite/Foundation.
- Engine adapter → BrowserDomain + BrowserPorts + WebKit.
- Native Host performs composition and injection.

BrowserDomain permits Swift and a reviewed Foundation subset.

**U:** exact package manifests, final target visibility, engine-adapter target placement and concrete build wiring. The source’s call/ownership diagram must not be mistaken for a compile-time dependency graph.

### Prerequisites, environment and fixtures

- **Prerequisites:** SPEC-01/02 definitions; actual targets; selected repository subset; finite prohibited-dependency/type inventory.
- **Environment:** D0/C0; DB0 for runtime repository cases.
- **Fixtures:** valid target graph; isolated invalid cycle/import fixtures; fake providers; persistent A/B and private contexts; synthetic repository operations.
- Isolated validation fixtures may be created; no product implementation is authorized.

### Proposed procedure and cases

First freeze the graph/type rules, establish valid controls, then execute these cases in order and review emitted dependencies/results.

| Case | Proposed action and expected oracle | Environment | Artifacts |
|---|---|---|---|
| PKG-001 | Compare actual targets/dependencies with the supported graph; identify missing/extra edges explicitly | D0/C0 | CFG, GRAPH, RESULT |
| PKG-002 | Inspect exported Domain/Ports/Core types for AppKit, WebKit, SQL, Keychain objects and raw native handles | C0 | GRAPH, TRACE, RESULT |
| PKG-003 | Verify Core policy versus host execution and concrete adapter/storage ownership | D0/C0 | CFG, GRAPH, RESULT |
| PKG-004 | Exercise isolated prohibited-import/cycle fixtures; invalid dependency plans must be rejected | C0 | FX, GRAPH, RESULT |
| PKG-005 | Validate required/optional bindings, duplicate/version errors, partial initialization rollback and disposal ordering | C0 | FX, TRACE, STATE |
| PKG-006 | Suspend fake effects, retire owners and deliver late completions; verify generation/revision checks | C0 | TRACE, STATE, RESULT |
| PKG-007 | Verify repository lease/profile checks, private refusal, transaction receipts and serialized connection ownership | DB0 | TRACE, STATE, FAULT |

**Positive controls:** valid four-target graph, compatible binding, valid A mutation and matching retained receipt.

**Negative controls:** prohibited import, cycle, wrong-profile/private lease, missing dependency, duplicate binding and stale completion.

**Expected outcomes:** no concrete platform leakage, unauthorized repository access or readiness-as-permission; cancellation does not falsify committed state.

**Pass:** all mandatory selected cases match finalized contracts.

**Fail:** forbidden dependency/type leakage, cycle acceptance, authority confusion, private persistence or false commit/cleanup.

**Stop:** unexpected real-data paths, unresolved resource ownership or fixture escape.

**Required evidence:** actual configuration/dependency graph, type/interface inspection, fake-provider traces, repository outcomes and review.

**Risks:** absent targets cannot be called conformant; compilation alone does not prove runtime security; same-process modules are not sandboxes.

**Policy gates:** Owner-decided OP-01–OP-04 govern affected behavior; missing technical definitions block affected cases, not all synthetic structural work.

**Follow-up/ownership:** Core/storage leads own fixes; security reviews boundary failures. Missing concrete targets/contracts remain U, not Passed.

## 5. SVC-02 — Native host and browser chrome bridge

### Charter definition

| Field | Definition |
|---|---|
| ID/title | SVC-02 — Native host and browser chrome bridge |
| Procedure / current outcome | Proposed / BLOCKED (preflight; see campaign report) |
| Objective | Validate native/Core authority against untrusted or stale chrome input |
| Scope | Typed commands/events, sender/origin/schema checks, lifecycle, cancellation and coarse errors |
| Exclusions | Assuming app UI is inherently trusted; general website-native messaging; production AI/cloud access |
| Question | Can valid owned operations work while malformed, foreign or stale input produces no unauthorized effect? |
| Requirements | REQ-03/17/18/19; supporting REQ-08/10 |
| Acceptance | AC09/AC14/AC15 |
| Specifications | SPEC-02/07/09/14/15/16 |
| Owner dispositions | OD-R02/10/11/15/16/18 |
| ADRs | 0001/0003/0005 Proposed; 0002 Accepted |

### Documented versus unspecified

Documented requirements include host-created authority, immutable scope, schema checks, current ownership, delivery-time checks and no privileged website handler.

**U:** actual chrome origin/scheme, hosting, codec/schema, command inventory, version negotiation implementation, size/queue limits and CSP.

The source’s numerical limits are explicitly provisional; this package does not ratify them. [Contract proposals](/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/docs/architecture/phase-5/reports/M1/core-boundary-contracts.md:15).

### Prerequisites, environment and fixtures

- **Prerequisites:** frozen SPEC-02/14/15; actual bridge; native surface registry.
- **Environment:** I0; C0 may test models but cannot substitute for native sender validation.
- **Fixtures:** valid chrome surface; unrelated surface; website top frame/subframe; A/B/private views; forged envelopes; delayed effects/subscribers.
- Use fixed synthetic values, not real account/browser data.

### Proposed procedure and cases

Establish a valid command/control, then vary one authority/schema/lifecycle dimension at a time. Preserve the original response/effect correlation.

| Case | Proposed action and expected oracle | Environment | Artifacts |
|---|---|---|---|
| BRIDGE-001 | Valid owned command; native context is derived rather than trusted from payload | I0/C0 | CFG, TRACE, STATE |
| BRIDGE-002 | Unknown/version/type/field/size/depth/range cases; reject before effects | I0/C0 | FX, TRACE, RESULT |
| BRIDGE-003 | Website, subframe, wrong-origin and remote-navigation attempts cannot retain privileged access | I0 | TRACE, UI, RESULT |
| BRIDGE-004 | Spoof profile/window/view/AppRun/surface generation or authority fields; deny | I0/C0 | TRACE, STATE |
| BRIDGE-005 | Replay, duplicate-payload mismatch and revision conflict; distinguish accepted-pending from committed | I0/C0 | TRACE, STATE |
| BRIDGE-006 | Close/quiesce/navigate/retire owner during effects; reject stale replies and release resources | I0/C0 | TRACE, FAULT, STATE |
| BRIDGE-007 | Slow subscriber, sequence gap, overflow and revocation; scoped resnapshot without action replay | I0/C0 | TRACE, STATE |
| BRIDGE-008 | Inject storage/native failure; coarse errors and truthful outcomes without secrets/paths/SQL | I0/C0 | FAULT, TRACE, RESULT |
| BRIDGE-009 | Verify bundled hosting/CSP/navigation confinement and absence of mandatory local server | I0 | CFG, TRACE, UI |

BRIDGE-002 must instantiate the source-required adversarial categories; a count alone is not coverage. The existing MVP criterion calls for at least 100 defined hostile-message cases.

**Positive controls:** compatible valid command, authorized snapshot and correct committed receipt.

**Negative controls:** malformed input, UI-claimed authority, wrong sender/scope, stale generation and revoked queued payload.

**Expected outcomes:** native and Core checks both apply; UI compromise does not become arbitrary native authority.

**Pass:** valid controls succeed and every mandatory invalid case has zero unauthorized effect.

**Fail:** origin-only trust, page handler exposure, stale sensitive delivery or false saved/completed status.

**Stop:** unexpected native effect, sensitive disclosure or uncontrolled navigation with retained privilege.

**Evidence:** exact schemas/configuration, vector inventory, source-to-effect traces, lifecycle/resource state and redacted UI outcomes.

**Risks:** fake dispatcher success is not actual WebKit sender validation; missing hosting/schema prevents executable qualification.

**Policy gates:** OP-01/02/04 restrict real data/actions exposed through the bridge. Fixtures do not select those policies.

**Follow-up/ownership:** native/UI/Core engineering and security jointly review; required schema/hosting decisions remain U until specified.

## 6. SVC-03 — Permission-kind, origin and native authorization matrix

### Charter definition

| Field | Definition |
|---|---|
| ID/title | SVC-03 — Permission-kind, origin and native authorization matrix |
| Procedure / current outcome | Proposed / BLOCKED (preflight; see campaign report) |
| Objective | Qualify each source-enumerated kind without confusing browser grants, engine support and OS authorization |
| Scope | Permission policy, origin/profile/private scope, lifecycle and capability truthfulness |
| Exclusions | Invented permission kinds, automatic device access, production Tamizhi or dynamic extensions |
| Question | Does every promised kind have an evidenced mapping and safe complete lifecycle? |
| Requirements | REQ-03/04/09/10/17/18; supporting REQ-08/14/19 |
| Acceptance | AC03/AC04/AC09/AC14/AC15 |
| Specifications | SPEC-02/06/07/09/12/14/15/16 |
| Owner dispositions | OD-R06/09/10/11/14/15/16/18 |
| ADRs | 0001/0003/0004/0005 Proposed; 0002 Accepted |

### Source inventory and common rules

The exact proposed permission inventory is in [PermissionKind](/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/docs/architecture/browser-engine-contract.md:145).

For each known kind, the common contract requires:

- Verified requesting origin and required top-level/frame context.
- Current profile/private/view/request/access generations.
- Explicit temporary/persistent semantics where supported.
- Private decisions remaining memory-only.
- Denial/revocation/expiry without cross-profile effects.
- No stale request rebinding after navigation/profile change.
- Independent native authorization.
- Unsupported/ambiguous behavior failing closed.

**U:** canonicalization, exact per-kind grant lifetime, consumption/expiry, reset procedure and complete API mappings.

### Per-kind matrix

The common rules above are incorporated into every row. `U` retains the full meaning **Unspecified — requires specification**.

| Case/kind | Browser/engine evidence | Native macOS requirement/API evidence | Grant/private/lifecycle qualification |
|---|---|---|---|
| PERM-001 `camera` | Enumerated; historical prototype media delegate path | Historical camera status/TCC path; no current M1 broker | Temporary/profile options are illustrative; exact lifetime/reset U; private memory-only; apply all lifecycle variants |
| PERM-002 `microphone` | Enumerated; historical prototype media delegate path | Historical microphone status/TCC path; no current M1 broker | Same common requirements; separate-device behavior must be qualified |
| PERM-003 `camera-and-microphone` | Enumerated; historical combined delegate branch | Both native authorizations must be independently accounted for; current integration U | Combined result must not imply separate device coverage |
| PERM-004 `geolocation` | Enumerated only | U | Positive native grant blocked until mapping; policy negatives remain specified |
| PERM-005 `notifications` | Enumerated only | U | Persistence, native registration/reset and private behavior U beyond common policy |
| PERM-006 `clipboard-read` | Enumerated only | U | No assumed clipboard access; approved synthetic fixture only |
| PERM-007 `clipboard-write` | Enumerated only | U | No assumed native authorization model; no real clipboard data |
| PERM-008 `bluetooth` | Enumerated only | U | Device/API/chooser/grant behavior U |
| PERM-009 `usb` | Enumerated only | U | Device/API/chooser/grant behavior U |
| PERM-010 `midi` | Enumerated only | U | Device/API/grant/reset behavior U |
| PERM-011 `screen-capture` | Enumerated only | U | Capture API, selection, OS authorization and revocation U |
| PERM-012 `unknown` | Explicit enum and fail-closed requirement | No native access should be attempted | Deny before effect; no persistent/private allow record |

The historical [media handler](/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/prototype/wkwebview/Sources/main.swift:853) is evidence of a prototype API path, not current M1 grant/revocation qualification.

### Required per-kind variants

For PERM-001–PERM-011, reserve suffixes consistently:

| Variant | Proposed validation |
|---|---|
| `.A` | Valid supported affirmative control |
| `.B` | Explicit browser denial/cancellation |
| `.C` | Wrong/opaque/changed origin, frame or navigation |
| `.D` | Foreign profile/private scope |
| `.E` | Temporary consumption/expiry under finalized semantics |
| `.F` | Supported profile grant; no private persistence |
| `.G` | Revoke and request again; no cached authority |
| `.H` | Lock/unlock, navigation or profile-switch generation fencing |
| `.I` | Native denial/unavailability despite browser allow |
| `.J` | Scoped reset/deletion/cancellation without unrelated OS changes |

A variant lacking a concrete native mapping is **blocked/U**, not Passed. PERM-012 uses denial/unsupported controls only; it has no affirmative grant variant.

### Additional cross-cutting cases

| Case | Proposed action/oracle | Environment | Artifacts |
|---|---|---|---|
| PERM-013 | Canonical origin/frame/redirect/user-action attribution; UI claims cannot supply authority | I0/C0 | FX, TRACE, STATE |
| PERM-014 | Temporary/profile lifetime, expiry, revoke and scoped browser reset | I0/AU | TRACE, STATE, AUTH |
| PERM-015 | Private decisions leave persistent grants and metadata untouched | I0 | TRACE, STATE |
| PERM-016 | Lock/navigation/profile switch and pending responses reject old generations | I0/L0 | TRACE, STATE, AUTH |
| PERM-017 | Browser allow/deny and actual OS allow/deny remain independent | AM/AU | AUTH, TRACE, RESULT |
| PERM-018 | Missing provider/unknown capability denies without readiness-as-permission | C0/I0 | CFG, TRACE |
| PERM-019 | Restored policy records do not import OS grants or stale authority | I0 | FX, TRACE, STATE |
| PERM-020 | Engine capability inventory matches actual supported/partial/unsupported behavior | D0/I0 | CFG, TRACE, RESULT |
| PERM-021 | Native file-selection/destination tokens stay origin/profile/request-bound; cancellation exposes nothing | I0 | AUTH, TRACE, STATE |

PERM-021 validates file authorization. It does not replace complete upload compatibility testing or EXP-06 download lifecycle evidence.

### Other contemplated capability fields

The [EngineCapabilities source](/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/docs/architecture/browser-engine-contract.md:92) also lists the following. They are not automatically website permission kinds.

| Fields | Required treatment under PERM-020 |
|---|---|
| `viewEmbedding` | Match declared embedding behavior; native mapping U |
| `persistentProfiles`, `privateProfiles` | Bind to EXP-01/02 evidence, not identifiers alone |
| `cookieReadWrite`, `websiteDataClear` | Privileged scoped operations; no raw cookie/native access through chrome |
| `navigationPolicy` | Current owned navigation and scheme policy |
| `downloadManagement`, `uploadPanel` | Native file authority; PERM-021 and related transfer evidence |
| `permissionKinds` | Per-kind inventory above; absent entry does not imply support |
| `findInPage`, `pageZoom` | View-scoped capability; not a native grant |
| `sessionHistory`, `durableHistory` | Per-view navigation versus Core-owned durable history; legacy facade still requires refinement |
| `contextMenu` | Native adaptation and scoped actions; exact behavior U |
| `processCrashEvents` | Actual event correlation; SVC-05 |
| `pageJavaScript`, `isolatedJavaScriptWorld` | No arbitrary native authority; page-scoped separately authorized behavior only |
| `extensionRuntime`, `extensionApiCoverage` | No M1 dynamic loading; absence/exclusion is not permission to install |
| `processModel`, `sandboxConfiguration` | Runtime facts, not grant decisions or sandbox guarantees |
| `engineName`, `engineVersion`, `platform` | Metadata to pin; not authorization |

Website-data kinds additionally include `media-keys`, `http-auth` and `other` alongside cookies/storage/cache/service workers. Their presence does not define new permission kinds or portable backup support.

Printing, fullscreen, IME, accessibility and drag/drop are contemplated native UX areas, but a complete per-feature contract is **U**. No extra permission enum is invented.

### Remaining charter fields

- **Prerequisites:** SPEC-09 mappings, actual broker, supported-kind scope and separate native-access authorization.
- **Environment:** AM for media; AU for unmapped native kinds; I0/C0 for policy; L0 for lock interaction.
- **Fixtures:** synthetic origins A/B, persistent/private scopes, controlled clocks, request generations, approved test devices/files only.
- **Procedure:** freeze per-kind contracts → establish supported controls → run variants → run cross-cutting cases → inspect persistence/native separation → review.
- **Positive controls:** genuine supported kind with valid origin/scope and required native authorization.
- **Negative controls:** denial, OS denial, opaque/foreign origin, expired grant, private persistence and stale request.
- **Expected outcomes:** unsupported denies; supported grants obey both browser and OS policy.
- **Pass:** complete promised lifecycle passes per kind; denial-only results do not pass affirmative grant workflows.
- **Fail:** browser override of OS denial, spoofed origin, cross-profile/private grant leakage or stale reuse.
- **Stop:** unapproved device activation, ambient device scanning or access to real clipboard/files/media.
- **Evidence:** per-kind configuration, trusted context, authorization outcomes and persistent-state differences; no media recordings/secrets.
- **Risks:** enum presence is not platform support; native mapping gaps remain.
- **Policy gates:** OP-01/02 constrain related real metadata; OP-04 constrains restored-session activation. Historical OD17 launch scope is owner-selected; each permission kind still needs evidence-backed positive API mapping. Ask for supported new requests; unsupported/ambiguous deny.
- **Follow-up/owners:** native/security/Core leads define mappings; Product Owner resolves actual scope changes, not routine API details.

## 7. SVC-04 — Integrated offline product operation

### Charter definition

| Field | Definition |
|---|---|
| ID/title | SVC-04 — Integrated offline product operation |
| Procedure / current outcome | Proposed / BLOCKED (preflight; see campaign report) |
| Objective | Validate usable local product workflows with external network and local-server dependencies unavailable |
| Scope | Launch/relaunch, profiles, approved local data/settings/permissions and local export |
| Exclusions | Offline availability of arbitrary remote websites; treating EXP-04/07 as product proof |
| Question | Does the integrated browser remain usable locally without Vezham/cloud/server dependence? |
| Requirements | REQ-01/06/09/11/12/16/19/20 |
| Acceptance | AC01/AC04/AC10/AC11/AC12/AC15 |
| Specifications | SPEC-01/03/05/06/09/10/11/12/15/16 |
| Owner dispositions | OD-R04/05/06/08/09/11/12/13/14/19/20 |
| ADRs | 0001/0003/0004/0005 Proposed; 0002 Accepted |

### Prerequisites, environment and fixtures

- **Prerequisites:** integrated product paths and local resource-hosting contract; qualified storage/key mechanisms.
- **Environment:** O0. All fixture servers stopped for the no-local-server assertion.
- **Fixtures:** synthetic local profiles, bookmarks, approved test history/download records, preferences/grants, encrypted exports and unavailable remote targets.
- Exact production data policies remain gated.

### Proposed procedure and cases

Prepare local data with recorded provenance, establish an online control where appropriate, then isolate connectivity and execute:

| Case | Proposed action/oracle | Environment | Artifacts |
|---|---|---|---|
| OFFLINE-001 | Cold launch with no network and no fixture/local server; local shell/resources remain usable | O0 | CFG, TRACE, UI |
| OFFLINE-002 | Relaunch and access intended persisted local state | O0, relaunch | TRACE, STATE, UI |
| OFFLINE-003 | Local profile access/create/delete and required local authentication without cloud | O0, auth where needed | AUTH, STATE, TRACE |
| OFFLINE-004 | Inspect/change local settings; inspect/revoke supported browser grants | O0 | TRACE, STATE, UI |
| OFFLINE-005 | Query/delete synthetic history and download metadata under explicit fixture policy | O0 | STATE, TRACE |
| OFFLINE-006 | Perform intended local backup/export workflow using qualified formats and authorized files | O0 | AUTH, HASH, STATE |
| OFFLINE-007 | Request network-dependent operations; show truthful failure without blocking local functions | O0 | TRACE, UI, RESULT |
| OFFLINE-008 | Private local workflow and closure leave no durable private state | O0, P/N stores | TRACE, STATE |

**Positive controls:** known local record, valid local key access, available bundled resource and successful declared local export.

**Negative controls:** unavailable remote site/service, missing local resource, locked/unavailable key, stale grant and stopped fixture server.

**Expected outcomes:** local operation works; remote dependency failure is explicit; no mandatory service request or local server.

**Pass:** complete declared local workflows succeed and request-attempt evidence supports the dependency claim.

**Fail:** blank remote-hosted chrome, account requirement, hidden local server dependency, false saved/exported state or durable private data.

**Stop:** unexpected real data, unapproved network destination or filesystem escape.

**Evidence:** isolation configuration, request-attempt inventory, UI state, local store/export integrity and failure outcomes. A firewall dropping traffic is not proof of zero request attempts.

**Risks:** a Ready window is not product validation; cached website success is not general offline-engine support.

**Policy gates:** OP-01/02 for real records; OP-03 for automatic snapshot lifecycle; OP-04 for durable reopening. Synthetic controls do not choose defaults.

**Follow-up/owners:** product/native/Core/storage teams define the supported local operation inventory; security reviews network/authority evidence.

### Source-supported network distinction

Current source requires local operation with optional services unavailable, but its existing outage scenario assumes public internet remains available. [Existing criterion](/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/docs/architecture/browser-mvp-acceptance-criteria.md:90).

This charter therefore adds the planned **integrated disconnected** validation route without claiming it already works. Remote website content and optional remote-service functions cannot be assumed available offline; cached behavior requires its own explicit scope.

## 8. SVC-05 — Durable host/content-process recovery

### Charter definition

| Field | Definition |
|---|---|
| ID/title | SVC-05 — Durable host/content-process recovery |
| Procedure / current outcome | Proposed / BLOCKED (preflight; see campaign report) |
| Objective | Validate recovery boundaries and discard/re-establishment rules across interruption |
| Scope | Host/content termination, state consistency, pending operations, locks, downloads and restore promotion |
| Exclusions | Treating content restart as host restart; automatic action replay; copying historical Phase 3 passes |
| Question | Can recovery preserve qualified durable data while rejecting stale/private/unauthorized runtime state? |
| Requirements | REQ-08/09/13/14/15/18/19/20/22 |
| Acceptance | AC04/AC07/AC08/AC11/AC12/AC13/AC14/AC15 |
| Specifications | SPEC-02/03/05/06/07/08/11/12/13/14/15/16 |
| Owner dispositions | OD-R05/06/07/08/09/10/13/14/16/17/18/19/20 |
| ADRs | 0001/0003/0004/0005 Proposed; 0002 Accepted |

### Recoverable versus discarded state

| State | Proposed treatment grounded in source |
|---|---|
| Committed browser-owned rows/receipts | Reopen and validate under normal ownership/version/key rules |
| Last committed content descriptor in live host memory | Only scoped safe recovery under defined policy |
| Durable restore descriptors | Owner-decided OP-04; checkpoint/lock/recovery engineering details required |
| AppRun/window/tab/view generations | Recreate/revalidate; do not import live authority |
| Pending prompts, grants, native tokens or effects | Discard/reconcile; no automatic authority replay |
| Private browsing state | Never restore durably |
| POST/form/upload bodies | No automatic replay |
| Interrupted files/sagas | Reconcile owned phase, not blind re-execution |

Source: [recovery strategy](/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser/docs/architecture/phase-5/reports/M1/migration-and-recovery-strategy.md:46).

### Prerequisites, environment and fixtures

- **Prerequisites:** defined identity/receipt/saga contracts; qualified relevant storage/key/transfer/archive mechanisms.
- **Environment:** R0; L0 for native lock-trigger variants.
- **Fixtures:** A/B/private views, known committed revisions, pending effects, controlled download/restore staging, corrupt/newer-version copies.
- **U:** safe process-attribution/termination method and exact interruption checkpoints. No broad process kill is permitted.

### Proposed procedure and cases

Record pre-state, interrupt only the identified harness/component, restart through ordinary access rules and compare durable versus discarded state.

| Case | Proposed action/oracle | Environment | Artifacts |
|---|---|---|---|
| RECOVERY-001 | Content-process termination: retire generation, preserve unaffected scope, require defined safe recovery | R0 | FAULT, TRACE, STATE |
| RECOVERY-002 | Host termination before/after commit: rows, revision and receipt agree after reopen | R0/DB0 | FAULT, STATE, HASH |
| RECOVERY-003 | New AppRun/owner identities; no private/pending grant/token restoration | R0 | TRACE, STATE |
| RECOVERY-004 | In-flight navigation/POST/form operation: no automatic replay or fabricated history | R0 | TRACE, FAULT, STATE |
| RECOVERY-005 | Download interruption/finalization: reconcile staging; preserve external completed files | R0 | FAULT, HASH, STATE |
| RECOVERY-006 | Locked host restart/key unavailability: no bypass, replacement key or stale access | R0/L0 | AUTH, TRACE, STATE |
| RECOVERY-007 | Corrupt/newer/migration-failed store: preserve original and refuse unsafe open/reset | R0/DB0 | FAULT, STATE, HASH |
| RECOVERY-008 | Interrupted backup/restore promotion: retain source/original and reconcile exact phase | R0 | FAULT, HASH, STATE |
| RECOVERY-009 | Create/delete resource interruption: no usable orphan, forced deletion or unrelated file loss | R0 | FAULT, TRACE, STATE |
| RECOVERY-010 | User-visible error/recovery choices match actual state and owner-decided OP-04 and specified recovery transitions | R0 | UI, TRACE, RESULT |

**Positive controls:** clean relaunch, known committed transaction and supported explicit recovery.

**Negative controls:** stale callbacks, unavailable key, wrong owner, incomplete staging, corrupt input and discarded private/pending state.

**Expected outcomes:** truthful scoped recovery; no reset, unauthorized replay or cross-profile merge.

**Pass:** mandatory supported interruption cases meet finalized contracts; OP-04-dependent positive cases require actual checkpoint/restore/lock implementation and specified transitions.

**Fail:** restored live authority/private state, false rollback/success, silent reset or destructive replay.

**Stop:** uncertain process identity, unowned file/store access, raw diagnostic secrets or unexpected data loss.

**Evidence:** pre/post revisions, receipts, lineage, resource phases, process-generation correlation and redacted recovery UI.

**Risks:** injected errors are not hardware-durability proof; historical helper diagnostics are not a stable product API.

**Policy gates:** OP-01 recovery-history fields, OP-02 metadata retention, OP-03 snapshots and OP-04 capture/reopening/history cause.

**Follow-up/owners:** native/adapter/storage/security review failures; Product Owner resolves only the deferred policy or necessary scope change.

Historical 49/49 recovery and 48/48 regression results remain separate and do not pass these cases.

## 9. Case-level traceability matrix

### Proposed experiment case references

These stable references identify already-planned work inside existing experiments. They are not new experiments or repository test claims. Exact configurations/data-class parameters remain U until SPEC-16 is completed.

| Proposed case | Existing experiment / purpose | Environment | Expected artifacts |
|---|---|---|---|
| ISO-001 | EXP-01: required website-data-class sharing/isolation/deletion | I0 | CFG, TRACE, STATE |
| PRIV-001 | EXP-02: private website-data teardown/restart | I0/R0 | TRACE, STATE, FAULT |
| CRYPTO-001 | EXP-03: declared DB/WAL/journal/temp protection and invalid-access controls | DB0 | CFG, HASH, STATE, FAULT |
| KEY-001 | EXP-04: normal key access and denied/cancelled authentication | AMK | AUTH, TRACE |
| KEY-002 | EXP-04: independent recovery-material verification/cross-Mac recovery | X0 | AUTH, HASH, RESULT |
| LOCK-001 | EXP-05: each approved lock trigger and access barrier | L0 | AUTH, TRACE, STATE |
| XFER-001 | EXP-06: bytes, interruption/resume and staging finalization | I0/R0 | AUTH, HASH, STATE |
| BACKUP-001 | EXP-07: coherent selected profile/catalog archive and cross-Mac restore | X0 | CFG, HASH, STATE |
| BACKUP-002 | EXP-07: selected external files and conflict-safe restore | X0 | AUTH, HASH, STATE |
| BACKUP-003 | EXP-07: explicitly covered WebKit backup/restore/migration classes | X0/I0 | CFG, HASH, STATE |
| DELETE-001 | EXP-08: known deletion, unknown coverage and confirmation/lineage | I0/R0 | TRACE, STATE, FAULT |

### Requirement coverage

Every requirement is represented. **REQ-21 remains an explicit mapping gap rather than being silently assigned AC15.**

| Requirement | AC mapping | Proposed case IDs | EXP/SVC route | SPEC | Gaps/status |
|---|---|---|---|---|---|
| REQ-01 | AC01 | OFFLINE-001–008 | SVC-04 | 01/03/16 | Integrated app absent; Not Run |
| REQ-02 | AC02 | PKG-001–004/006 | SVC-01 | 01/02 | Concrete package/placement U |
| REQ-03 | AC09/14 | BRIDGE-001–006/009; PERM-013 | SVC-02/03 | 02/09/14 | Actual hosting/schema U |
| REQ-04 | AC03/14 | PKG-007; ISO-001; PERM-013/015; RECOVERY-009 | SVC-01/03/05; EXP-01 | 03/06/08 | Store identifiers insufficient |
| REQ-05 | AC05 | CRYPTO-001 | EXP-03 | 04 | No SVC substitutes for crypto qualification |
| REQ-06 | AC12/14/15 | CRYPTO-001; BACKUP-001; OFFLINE-003 | EXP-03/07; SVC-04 | 03/04/12 | Catalog protection U |
| REQ-07 | AC06 | KEY-001/002 | EXP-04/07 | 04/05 | Independent Mac required for cross-device claim |
| REQ-08 | AC07/14/15 | LOCK-001; PERM-016; BRIDGE-006/007; RECOVERY-006 | EXP-05; SVC-02/03/05 | 05/07 | Actual barrier U |
| REQ-09 | AC04/14 | PRIV-001; PERM-015; OFFLINE-008; RECOVERY-003/005 | EXP-02; SVC-03/04/05 | 06/08 | No forensic guarantee |
| REQ-10 | AC09/14 | PERM-001–021; BRIDGE-003/004 | SVC-03/02 | 09/14/15 | Native per-kind mappings incomplete |
| REQ-11 | AC10/13 | OFFLINE-005; DELETE-001; RECOVERY-004 | SVC-04/05; EXP-08 | 10/13 | OP-01/04 |
| REQ-12 | AC11 | XFER-001; OFFLINE-005; RECOVERY-005 | EXP-06; SVC-04/05 | 11 | OP-02 |
| REQ-13 | AC11 | XFER-001; PERM-021; RECOVERY-005 | EXP-06; SVC-03/05 | 11 | Native file/finalization details U |
| REQ-14 | AC12/15 | BACKUP-001; KEY-002; RECOVERY-008 | EXP-04/07; SVC-05 | 05/12 | Format/promotion U |
| REQ-15 | AC13 | DELETE-001; RECOVERY-008 | EXP-08; SVC-05 | 13 | Ledger coverage/protocol U |
| REQ-16 | AC11/12 | BACKUP-002; OFFLINE-006 | EXP-07; SVC-04 | 11/12 | Selection/conflict contract U |
| REQ-17 | AC02/15 | PKG-005; PERM-018/020; BRIDGE-006 | SVC-01/02/03 | 01/06/14 | Required-feature scope not waived |
| REQ-18 | AC14/15 | PKG-006; BRIDGE-005–008; PERM-016; RECOVERY-003 | SVC-01/02/03/05 | 14/15 | Envelopes/bounds U |
| REQ-19 | AC15 | PKG-007; RECOVERY-002/007–009; CRYPTO-001; BACKUP-001; DELETE-001 | SVC-01/05; EXP-03/07/08 | 03/06/15 | Cross-resource checkpoints U |
| REQ-20 | AC15 | RECOVERY-001–004/006/010 | SVC-05 | 06/10/15 | OP-04; host/content distinction preserved |
| **REQ-21** | **No explicit AC01–AC15 identifier in supplied baseline** | **U** | Separate mandatory Stage C gates; not covered by five SVCs or eight feasibility experiments | Release specifications/checklists outside this numbered set | **Explicit gap: acceptance/case mapping needs correction; no new AC/EXP invented** |
| **REQ-22** | **AC08** | **ISO-001; PRIV-001; LOCK-001; BACKUP-003; supporting RECOVERY-001/009** | **EXP-01/02/05/07; supporting SVC-05** | **08** | Per-data-class protection/deletion/backup criteria U |

### Acceptance coverage check

| AC | Planned route |
|---|---|
| AC01 | OFFLINE cases |
| AC02 | PKG cases |
| AC03 | ISO-001, PKG-007 |
| AC04 | PRIV-001, PERM-015, OFFLINE-008, recovery exclusions |
| AC05 | CRYPTO-001 |
| AC06 | KEY-001/002 |
| AC07 | LOCK-001, RECOVERY-006 |
| AC08 | ISO-001, PRIV-001, LOCK-001, BACKUP-003 |
| AC09 | PERM and bridge authority cases |
| AC10 | OFFLINE-005, deletion/history cases; policy-gated |
| AC11 | XFER-001, file-token, offline metadata and recovery cases |
| AC12 | BACKUP cases, KEY-002, RECOVERY-008 |
| AC13 | DELETE-001, related recovery |
| AC14 | Bridge, permission, profile/private and stale-delivery cases |
| AC15 | Lifecycle/fault/receipt/recovery cases |

All 15 have planned routes. None has a new validation result.

## 10. Platform and environment matrix

### Environment profiles

Each case’s environment code incorporates the following requirements. Mandatory runtime qualification remains macOS 26.0/latest supported 26.x at the approved stage; authorized newer-host discovery must be labelled separately.

| Code | macOS 26 requirement | Second Mac | Native authorization / interactive session | Multiple OS sessions | Network | Stores/files/Keychain | Termination/relaunch |
|---|---|---|---|---|---|---|---|
| D0 | Not required for document inspection | No | No / No | No | None required | Source only | No |
| C0 | Declared target/SDK conformance; runtime claims require supported OS | No | No / not inherently | No | No dependency | Controlled fixtures only | Only if case says |
| DB0 | Required for supported runtime qualification | No | No for synthetic key injection | No | None | Owned DB/files; native Keychain only if explicitly added | Controlled reopen/fault case |
| I0 | Required for supported native/WebKit runtime claim | No | Native file action where specified / Yes | No | Controlled origins; no external service dependency | P/N stores and owned files as applicable; profile-key preconditions | Only stated cases |
| AM | Required for native media claim | No | Yes / Yes | No | Controlled valid origin | Approved camera/mic fixture; no recordings; profile resources | Only stated cases |
| AU | Required for native runtime claim | No | **U per kind** / Yes if native | No | Controlled context | API/device/OS conditions **U** | Per finalized contract |
| AMK | Required for native key-access claim | No | Yes / Yes | No | No cloud requirement | Isolated test Keychain/profile material | Per case |
| O0 | Required for supported product-offline claim | No | Local auth/file action where needed / Yes | No | Isolation mandatory; no local server | Owned local data; P/N where stated; local Keychain | OFFLINE-002 |
| R0 | Required for supported recovery claim | No | Required where locked/native action / Yes | No unless explicit variant | Controlled/isolation as stated | P/N, DB/files/keys required by case | Yes, safely attributed |
| L0 | Required for actual trigger/barrier claim | No | Unlock authentication / Yes | **Only session-switch variant** | Controlled | Owned profile/key/view resources | Restart variant only |
| X0 | Required on platforms claimed by cross-Mac result | **Yes** | Recovery/file authorization / Yes | No | Offline restore | Independent destination Keychain/files; website classes only if claimed | Relevant restore/relaunch cases |

P/N means persistent/nonpersistent WebKit stores.

### Per-case application

- Every PKG, BRIDGE, cross-cutting PERM, OFFLINE and RECOVERY case has an environment assignment in its charter table.
- PERM-001–003 use **AM**.
- PERM-004–011 use **AU** until native mappings exist.
- PERM-012 uses **C0/I0**, with no native grant attempted.
- PERM variants inherit their parent environment; `.I` requires the actual native condition when defined.
- LOCK-001 requires multiple macOS sessions only for its session-switch subcase.
- A browser profile switch does not itself require multiple macOS user sessions.
- No SVC requires a second Mac merely for local validation. Cross-Mac claims stay with KEY-002/BACKUP cases.
- An actual device-dependent positive case is blocked if its approved device/API/environment is unavailable.

Exact hardware models, supported architectures, test identities and methods remain **U** until the finite execution plan is approved.

## 11. Evidence artifact and reporting standard

Artifacts are required where the corresponding action actually executes; never fabricate an artifact or result for an unrun case.

| Code | Expected artifact |
|---|---|
| CFG | Source/build/OS/SDK/provider/contract configuration and case scope |
| GRAPH | Actual dependency/import/type graph and reviewed exceptions |
| FX | Synthetic fixture inventory, expected state and vector parameters |
| TRACE | Correlated request/effect/generation/sequence observations |
| STATE | Redacted database/filesystem/resource-state differences |
| AUTH | Browser versus native authorization outcome, using opaque test references |
| HASH | Fixture/archive/file integrity verification |
| FAULT | Exact injected/actual interruption point and recovery outcome |
| UI | Redacted status/error screenshot or recording where useful |
| RESULT | Expected/actual case result, limitations and defect reference |
| REVIEW | Engineering/security disposition and scope-qualified sign-off |

For every case ID, evidence must associate:

- Parent SVC/EXP and variant.
- REQ, AC, SPEC, OD-R and relevant OP references.
- Current source/configuration.
- Expected versus actual outcome.
- Environment and authorized scope.
- Result: Passed, Failed, Blocked, Inconclusive or Not Run.
- Cleanup status and remaining limitations.

### Redaction and integrity

- No raw keys, recovery secrets, credentials or private browsing content.
- No private-page screenshots or unredacted dumps by convenience.
- Prefer synthetic identifiers, booleans, counts and integrity summaries.
- Keychain evidence records outcomes, not secret bytes.
- Raw heap dumps are not required to prove bounded key-handle behavior.
- Preserve failures and revisions separately.
- Do not merge historical runs into a new pass rate.
- UI screenshots supplement, not replace, state/authorization evidence.

A case cannot be Passed without functioning controls and required artifacts. Missing artifacts are a gap, not assumed success.

## 12. Dependencies and critical path

1. **Establish canonical baseline references.** Repository locations for the current Developer Specification, Validation Plan and current register remain unresolved.
2. **Complete executable contracts.** Target placement, bridge hosting/schema, permission-kind mappings and recovery checkpoints.
3. **Prepare supporting conformance fixtures.** PKG and model-level authority/lifecycle cases.
4. **Qualify existing experiment mechanisms.** Encryption/key recovery, profile stores, locks, downloads and archives.
5. **Run integrated supporting cases only after authorization.** Native bridge, offline product and recovery.
6. **Review remaining policy gates and capability failures.**
7. **Conduct scoped readiness review.**
8. **Retain separate implementation and final-release authorization.**

Possible parallel work:

- Package contract review and bridge schema design.
- Permission inventory/specification and offline workflow inventory.
- Model-level recovery/failure design and experiment fixture design.

Not safely parallel on the same session:

- Lock/sleep/session-switch testing.
- Native permission resets.
- Key replacement/recovery mutation.
- Process termination and profile cleanup.

No missing required capability becomes optional merely because another component works.

## 13. Unresolved specification gaps

| Gap | Required resolution | Related findings |
|---|---|---|
| Canonical source locations | Canonical sources now established; preserve versions/provenance and distinguish archived supplied sources | F01/F16 |
| Concrete target/adapter placement | Final package graph, manifests, visibility and adapter target | F02/F04/F14 |
| Native/chrome contract | Origin, hosting, codec, exact schema/version/limits and CSP | F02/F14/F15 |
| Native permission mapping | Per-kind public API, native authorization, lifetime/reset and supported launch scope | F08/F14 |
| Protection/key formats | Provider, catalog coverage, Keychain/recovery/rotation contracts | F05/F06 |
| Lock mechanism | Reliable OS signals, actual WebKit barrier and key/access lifecycle | F07 |
| Lifecycle checkpoints | Cross-resource creation/deletion/restore consistency and process attribution | F10/F12 |
| Private staging/metadata wording | Concrete no-persistence cleanup protocol | F09 |
| Download/file authority | Native token persistence, resume, staging and restore conflicts | F13 |
| Events/errors | Bounds, sequences, snapshots and commit/cancellation outcomes | F15 |
| Evidence/case parameters | Actual fixture/configuration values and variant inventory | F16 |
| REQ-21 acceptance/case route | Explicit mapping to mandatory release criteria; do not invent an AC assignment | F01/F16 continuity |
| OP engineering integration | Integrate owner-decided OP-01–OP-04 without inventing internal snapshot or checkpoint semantics | F11 |

F03’s authorization separation and F17’s reference-product limitations remain unchanged.

The following source discrepancies also remain visible:

- Legacy TypeScript facade versus future Swift contracts.
- Historical optional-encryption/30-day/default-off proposals versus current owner dispositions and deferred policies.
- Browser-owned offline operation requirements versus the existing internet-available outage scenario.
- Historical prototype results versus unimplemented M1 behavior.

These are not silently corrected in the repository.

## 14. OP-01–OP-04 policy gate status

| Policy | Status | Supporting cases affected | Permitted planning boundary |
|---|---|---|---|
| OP-01 History fields/query/fragment | Owner-Decided | OFFLINE-005; RECOVERY-004; related archive/history fixtures | Full URL policy; exact schema/deletion/checkpoint engineering required |
| OP-02 Download metadata retention | Owner-Decided | OFFLINE-005; RECOVERY-005; metadata cases | Manual retention; incomplete-transfer lifecycle still technical |
| OP-03 App-owned snapshot retention/deletion | Owner-Decided | OFFLINE-006; RECOVERY-007/008/009 | Manual user-created snapshots; internal recovery lifecycle still technical |
| OP-04 Restore/reopening/recovery history | Owner-Decided | OFFLINE-002; RECOVERY-003/004/010; PERM-019 where activation involved | Implement specified normal/restart restore and crash prompt only after checkpoint/lock contracts |

Resolving a policy does not authorize implementation or execution.

### Historical crosswalk preservation

| Historical decision | Preserved subject/current relationship |
|---|---|
| OD01–OD06 | Runtime, process, targets, SQLite, topology, private representation → corresponding OD-R01–06 with refinements |
| OD07 | Protection choice → OD-R07/08/09/18/19; optional-encryption alternative superseded |
| OD08 | History retention and related data lifetime → OD-R12; Forever supersedes 30-day history |
| OD09 | Download-metadata retention → related OD-R13/20; OP-02 remains |
| OD10 | Retained URL/title/query/fragment inventory → OP-01 |
| OD11 | Pre-migration snapshot count/TTL → expanded backup scope; OP-03 remains |
| OD12 | Restore capture/reopening proposal → OP-04; no direct current replacement |
| OD13 | Privacy epochs/deletion intents → OD-R12/17 |
| OD14 | Migration/receipt mechanics → supports OD-R04/05/14; not current OD-R14’s subject |
| OD15 | Static bindings/lifecycle → OD-R15 |
| OD16 | Typed contracts/events → OD-R16 |
| OD17 | Launch-critical scope/permissions → still-open scope details |
| OD18 | Historical broad deferral preserved; current OD17 selects basic Spaces and defers advanced automation/extensions |
| OD19 | Future optional services → OD-R04 optionality |
| OD20 | Execution proposal, not granted → not current OD-R20’s download/backup policy |

WS01.1 and all current OD-R conditions remain unchanged. Safari and Arc remain design references, not proprietary implementation specifications.

## 15. Consolidated M1 validation readiness assessment

| Area | Classification | Assessment |
|---|---|---|
| All 22 requirements represented | **Ready with limitations** | Every requirement has a row; representation is not complete executable traceability |
| Complete requirement-to-acceptance/case chain | **Not Ready** | REQ-21 has no explicit AC01–AC15/case mapping; other case parameters remain unresolved |
| All 15 acceptance criteria have planned routes | **Ready with limitations** | Routes exist; product/native-positive coverage blocked; bounded storage reference outcomes are partial |
| SVC-01 sufficiently specified | **Ready with limitations** | Source dependency rules are clear; concrete package/adapter placement absent |
| SVC-02 sufficiently specified | **Not Ready** | Hosting/schema/limits and actual bridge absent |
| SVC-03 sufficiently specified | **Not Ready** | Inventory is source-backed; complete native mappings/lifecycles are not |
| SVC-04 sufficiently specified | **Not Ready** | Integrated product and concrete policy/schema/lifecycle engineering absent; owner policies decided |
| SVC-05 sufficiently specified | **Not Ready** | Recovery mechanics/checkpoints/process targeting and OP-04 engineering integration incomplete |
| Eight experiments coherent with supporting charters | **Ready with limitations** | Identities/scopes preserved; supporting cases do not replace experiment proof |
| Platform prerequisites clear | **Ready with limitations** | Required categories assigned; actual hardware/API identities remain unspecified |
| Evidence standard actionable | **Ready with limitations** | Artifact requirements are defined; actual schemas/fixtures and outputs absent |
| Specification gaps resolved | **Not Ready** | §13 remains open |
| Owner policies | **Owner-Decided** | OP-01–OP-04 recorded; remaining engineering and evidence are not waived |
| Ready for review of proposed cases/gaps | **Ready with limitations** | Useful review package; current scoped execution authority is separate; no implementation approval implied |
| Ready for final validation-readiness go decision | **Not Ready** | Contracts, mappings, policy engineering and environment inventory remain incomplete; scoped execution authority already granted |

No supporting validation case executed: all154 are preflight BLOCKED. EXP-01/02 native reference subsets ran with retained FAIL/INCONCLUSIVE outcomes; no package becomes implementation-ready because documents exist.

## 16. Current authorization and correction record

Documentation/isolated SVC validation/evidence/planning are Authorized. Product implementation, release/signing-notarization approval/distribution, branch changes/commits/pushes are Not Authorized.

C02: maintained §9 AC07 route is LOCK-001/RECOVERY-006; PERM-016 remains AC09/AC14. C03: maintained §14 omits the older OP-01 mention for RECOVERY-010; that case remains OP-04. [Exact old v1.0](../../evidence/20261108T094414Z-m1-consolidated-closeout/supplied/supporting-validation-charters-v1.0-proposed.md) is preserved, so corrections are explicit rather than silent history rewrites.

RECOVERY-009 explicitly preserves external files across metadata/profile deletion, distinguishes metadata from payload deletion, prohibits silent restore overwrite and requires a defined authorized affirmative file-delete operation. No product operation is implemented here.

Current [matrix](m1-case-level-traceability.md) retains all individual permission mappings and current outcomes; [reports](../../evidence/20261108T094414Z-m1-consolidated-closeout/reports/) retain evidence. Positive native support is never inferred from denial-only policy fixtures. Website notifications are separate from native macOS notifications.

