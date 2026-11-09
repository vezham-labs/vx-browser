# Architecture recommendations

## Direction and sequence

Keep the native AppKit composition, system WebKit, Core/Ports and guarded browser-chrome boundary. Use a stable workspace identity above the ephemeral view lifecycle. Keep a Space organizational until an explicitly authorized profile mapping says otherwise. Search's lazy realization, Little Arc's destination affordance and SigmaOS's command discoverability can fit this model. Engine plugins, Chromium/Gecko/Electron embedding, private APIs, broad agent control, cookie/password migration, private disk restoration, launch-dependent extension parity and mandatory sync are outside the recommended scope. [Opportunity matrix](feature-opportunity-matrix.md) · [ADR 0001](../../../../decisions/0001-browser-engine-strategy.md) · [ADR 0005](../../../../decisions/0005-browser-capability-boundaries-and-lifecycle.md)

| Workstream | Refinement | Exit evidence |
|---|---|---|
| WS-F5R · Browser Reliability & Interaction Qualification | Finish the current matrix before starting major work. Establish helper attribution before real termination tests. Preserve baseline, execution-01 evidence and actual/contract/stand-in classifications. Close or explicitly disposition native drag, VoiceOver, downloads feasibility, external auth and supported-OS cases in their existing scope | Exact candidate and case IDs, scoped termination signal and callback, old-scope denial and release, new store isolation, repeated native results, and recorded remaining blockers. No research result substitutes for these cases |
| WS-F6 · Persistent Workspace | Model stable logical identities, graph/version integrity, tab/pin/group/Space/window restore and split intent. Qualify lazy admission and restoration with synthetic state. Refine command and handoff behavior against the same model. Integrate real writes only if the protected-store prerequisites qualify | Migration/rollback, corrupt and partial writes, multi-window revisions, selection and compact split, no unintended background loads, private exclusion, replay safety. Record blocked product persistence if WS-F7 gates remain open |
| WS-F7 · Secure Browser Profiles | Complete production protected catalog and worker qualification within Option D and exact D2A-01 authority. Obtain an authorized signed Keychain environment, prove positive custody and lock/unlock. Validate verified profile/store binding, same-origin isolation, retention/clear/delete, permission policy and owned backup/import | Native data isolation and cache matrix, wrong/missing key, concurrent clear/lock/save, authenticated migration, backup tamper/interruption and fresh-destination publication. No plaintext or default-store fallback |
| WS-F8 · Release Qualification | Qualify the signed/notarized internal candidate, Gatekeeper, clean install and upgrades/rollback, updater integrity, release sandbox and actual supported macOS runtimes. Repeat native workflows and performance checks on that candidate | Separate evidence for 26.0 and latest supported 26.x, exact signing/release artifact, approved auth/download workflows, AX/VoiceOver, launch/teardown, content recovery and owner release decision |

These are refinements to the brief's WS sequence. They do not replace Phase 5's M0–M8 milestones or change ADR stages, existing evidence or authority. Dependency ordering means an F6 fixture can be finished while a real-data rollout remains gated. Current WS-F5R environment gaps must remain visible even where final candidate coverage is scheduled in WS-F8. [Phase 5 scope](../../phase-5-scope-and-milestones.md) · [WS-F5R matrix](../WS-F5R/evidence/execution-01/test-matrix.md) · [WS-F3 gates](../WS-F3/next-gates.md)

## Recommendation cards

### 1. ADOPT stable workspace identities · Large

- **Problem and reference.** A private session reset changes every view ID and a restart loses organization. Search's saved rows and Zen's session integration show stable records with reconstructed surfaces.
- **Current and proposed behavior.** Current organization is window memory keyed by native `ViewID`. Give window, Space, group, tab slot and split references versioned logical IDs. Restore ordering, pinning, group collapse, selection and validated window geometry before admitting views.
- **Impact and dependencies.** Workspace model and transaction owner above Core view lifecycle. Start after WS-F5R with fixture records. Require approved product persistence and Keychain gates for real browsing metadata.
- **Security.** Exclude private graphs from disk. Validate size, ownership and references before publication, and fence old generations.
- **Qualification.** Round-trip snapshots, concurrent close/save and migrations, older-reader refusal, corrupted input, missing displays, stale references, locked or missing profile, and no disk trace of private test markers. [Persistence](persistence-and-session-architecture.md)

### 2. ADAPT lazy WebKit admission · Large

- **Problem and reference.** Eager allocation binds every restored tab to WebKit, even when hidden. Search wakes only visible records, and Vela illustrates a separate record and live view on Chromium.
- **Current and proposed behavior.** Current creation and private rebuild are eager. WS-F6 restore should publish metadata, then materialize the focused authorized tab and the second member only when visible. Build others on activation. Retain the existing private recovery policy during WS-F5R.
- **Impact and dependencies.** Stable logical identities, generation-aware registry and existing Core admission; a dormant record has no store/view handle. Deduplicate construction and keep failure visible.
- **Security.** Resolve current authority at activation, never use a default-store fallback, and invalidate late results on scope changes. Require reviewed normal-navigation provenance.
- **Qualification.** Zero hidden navigation or view construction on initial restore, split and compact cases, concurrent activation, failed publication, retirement during activation, stale callbacks and measured startup/activation costs. [Lifecycle](webkit-lifecycle-comparison.md)

### 3. ADOPT scoped command discovery · Small

- **Problem and reference.** Users can miss sidebar actions or switch the wrong target. Arc and SigmaOS make contextual commands and keyboard navigation visible.
- **Current and proposed behavior.** Existing search covers tabs, Spaces and actions. Label active vs. other Space, indicate action vs. destination, expose keyboard alternatives for existing move/group/pin commands, and show the focused split pane.
- **Impact and dependencies.** Bundled chrome presentation and existing typed native actions. Use qualified focus and AX baselines, with native target checks retained.
- **Security.** Limit results to the current authorized window/session. Keep drafts and private queries in memory, and validate that tab or pane still exists when submitting.
- **Qualification.** VoiceOver announcements, keyboard-only moves, no accidental navigation from an action, no interception of page typing, and stale-result and hidden-Space cases. [Workspace UX](workspace-and-tab-ux.md)

### 4. ADAPT explicit Mini handoff · Medium

- **Problem and reference.** Users need a quick link to land in an intended durable project. Arc recorded wrong-Space/Profile bugs in Little Arc. Cra documents its own Little Window.
- **Current and proposed behavior.** Mini already passes a URL to the owning main controller. Show the receiving workspace and Space, then open an eligible URL through existing receiver admission. Distinguish request accepted from page committed. Define whether Mini stays open after a failed or cancelled handoff.
- **Impact and dependencies.** A small routing/presentation contract with stable destination IDs, source lifetime and existing WS-F5R routing constraints. Main and Mini continue to own separate stores.
- **Security.** Validate the destination at execution, transfer only an eligible URL, and avoid redirect/request replay or implicit login transfer. Disclose destination and relevant retention before handoff to a future durable workspace.
- **Qualification.** Busy, deleted, locked, closing and recovering receivers, two Minis, cold/warm launch, valid/invalid external URL, different auth markers and first responder on success or failure. [Workspace UX](workspace-and-tab-ux.md)

### 5. ADAPT two-pane layout restoration · Medium

- **Problem and reference.** A research pair and keyboard focus are easy to lose. Search persists split pairs and widths. SigmaOS gives split actions explicit pane targeting.
- **Current and proposed behavior.** Native two-pane display and compact single-pane fallback already exist. Save member IDs, orientation as supported by the existing layout, divider preference and focused member for a normal workspace. If one member is stale, restore the remaining eligible member as a single tab.
- **Impact and dependencies.** Reuse native `NSSplitView`, the WS-F6 workspace model and lazy admission. Do not create a second view for the same logical slot.
- **Security.** Require both members to belong to the same eligible scope/Space and guard focus-target actions against stale bindings.
- **Qualification.** Restore both then shrink/expand, switch Space, delete/close one member, revoke profile mid-restore, keyboard/VoiceOver focus and drag qualification, and inspect both view/store identities. [Lifecycle](webkit-lifecycle-comparison.md)

## Open decisions

What constitutes a safely committed, eligible normal restore URL? Should a user choose between layout-only and URL restore? Which product data categories and permission types are essential for the internal release? Can release OS coverage, positive Keychain custody and a defensible native WebKit helper-attribution method be provided for the pinned candidate? Each answer changes a gate or model decision. Document it in the owning workstream after review. [Qualification matrix](../WS-F5R/evidence/execution-01/test-matrix.md) · [WS-F3 gate ledger](../WS-F3/qualification-matrix.md)
