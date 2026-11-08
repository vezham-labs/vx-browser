# M1 Browser Core and Local State — Design Review

**Date:** 2026-11-07. **Status:** M1 design prepared for owner review; implementation Not Started.

## 1. Repository baseline and Git state

Used the existing `/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser` checkout on `timeline`, starting clean at **`fd60d5dda8144b8fedaaaf4f73e439907d8360c1`** (`chore(browser-macos): init browser poc`). `origin` remains `https://github.com/vezham-labs/vx-browser.git`; `upstream` remains `https://github.com/vezham-labs/vx-fe-kit-starter.git`. This is the now-committed M0 baseline, not the earlier M0 report's pre-work commit. Preserve that historical report unchanged.

Captured 601 tracked-file hashes before editing. No reset/stash, source overwrite, branch switch, commit or push. Final task changes are documentation/review records only, unstaged; see [baseline](../../evidence/20261107T161137Z-m1-design/repository-baseline.json), [preservation/change report](../../evidence/20261107T161137Z-m1-design/preservation-and-change-review.json) and [documentation verification](../../evidence/20261107T161137Z-m1-design/documentation-review.json).

## 2. Existing M0 implementation review

Read all three Swift sources, configuration/entitlements, native build/audit/launch driver, resolved Nx target configuration, the [M0 exit report](../M0/README.md) and [foundation decisions](../M0/m0-foundation-decisions.md). Entry point/delegate retain application lifetime; the delegate owns the native menu/window and normal close/reopen policy; the window presents Ready. The host contains no core, web view, script channel, persistent browser store or optional service.

The target minimum remains26.0; Debug uses ad-hoc signing with sandbox/Hardened Runtime configuration and Release identity remains unconfigured. Compared the 14 current native source/configuration files with the historical M0 source manifest: identical. Historical M0 build/corrected audit/native launch/Quit results are references, not rerun here; close-last-window/reopen remain separately unqualified as stated in M0. No build, app launch, product test or Phase3 regression runs in this task.

Read the ten Browser handbook pages, approved baseline, engine contract, both existing ADRs, security architecture/threat model/acceptance criteria and Phase5 plan/milestones before drafting. New proposed ADRs do not change ADR0001 Proposed or ADR0002 Accepted.

## 3. Core architecture proposal

[Module architecture](browser-core-architecture.md) defines a Swift value-domain/ports/runtime/persistence split, with native composition/authority and separate future engine/UI/platform adapters. It covers application/window/tab/navigation/session ownership, profiles/private lifecycle policy, history/bookmarks/preferences, transfer/permission metadata and explicit recovery. Spaces/workspaces are deferred because no approved behavior justifies a new module. Responsibilities and later sequencing do not imply all features are implemented in M1.

## 4. Runtime and language recommendation

[ADR0003 — Proposed](../../../../decisions/0003-browser-core-runtime-and-language.md): recommend Swift6 core in the existing native host process, Foundation-only models/ports, actor-coordinated state and off-main serialized database I/O. Compare Swift, JSCore/TypeScript, separate Node, Rust/C++ and React-owned authority. Keep React/TypeScript/HeroUI v3 presentation, WK objects in the future adapter, and native authorization in the host. No production runtime or repository dependency was added. Shared host/core process is not a separate security boundary.

## 5. Local persistence recommendation

[ADR0004 — Proposed](../../../../decisions/0004-browser-local-persistence.md) and [local persistence architecture](local-persistence-architecture.md): recommend typed repositories over SQLite with a small catalog and separate persistent-profile DBs; private core state uses memory only. Evaluate CoreData, SwiftData, plain files, web/cloud and encrypted providers explicitly. Engine cookies/cache/site storage are separate; local state has no identity/cloud requirement. Encryption for real data remains an approval condition, not an implicit plaintext decision.

## 6. Data model, migration and recovery

[Initial data model](browser-core-data-model.md) distinguishes runtime epochs/capabilities from durable profile, preferences, future history/bookmarks/restore/permission/download entities. Bootstrap only the schema needed for an authorized slice. [Migration/recovery strategy](migration-and-recovery-strategy.md) defines checksummed transactional migrations, minimum reader/writer version, controlled snapshot/backup eligibility, privacy epochs, no automatic reset/downgrade, catalog/native reconciliation and explicit crash restoration. No database, SQL migration, fixture store or product metadata was created.

## 7. Interface and contract design

[Boundary contracts](core-boundary-contracts.md) cover host/core, core/engine, core/chrome, core/persistence and future permission/transfer brokers: host-created authority, immutable profile/private scope, opaque IDs, epochs/generations, expected revisions, bounded requests/events, commit receipts, cancellation and explicit failures. Actual chrome transport remains M3 work; websites never receive a privileged handler. The old TypeScript facade's durable-history ownership and generation/cancellation details need later approved refinement, not a silent runtime selection or an adapter implementation now.

## 8. Security and privacy analysis

Core/store private refusal is distinct from real WKWebsiteDataStore isolation. Private URLs/titles/history/permissions/recovery/receipts cannot enter durable stores, normal suggestions, logs, backup or future sync. Credentials/cookies belong to separate native/engine boundaries; no secret reaches frontend storage. Native tokens stay one-shot and owner/origin/epoch-bound. Crash recovery never replays old authorization, forms/POST, transfers or private sessions. Typed code and actors are not a security certification; all future implementation criteria remain Not Tested.

Propose 30-day history/download metadata retention, restore opt-in/off, bookmarks/preferences until deletion and at most24h pre-migration backup. These are unapproved options with URL/query sensitivity, encryption, deletion/snapshot and OS-artifact limits explicitly recorded. Cross-profile/private leaks and unauthorized native access remain hard failures. No mandatory security/release gate is waived.

## 9. Proposed M1 implementation sequence

[Implementation breakdown](m1-implementation-plan.md) contains I0 design disposition, I1 domain/ports, I2 actor/runtime, I3 fixture persistence proof, I4 history/bookmark metadata, I5 restore model, I6 service policy contracts and I7 separately scoped host integration/exit. Recommend a small first implementation authorization for I1-I2 and synthetic I3, after runtime/store direction approval. No M2 or later milestone starts. Full engine, real profiles/private browsing, permissions/files, React UI and releases stay in their later milestones.

## 10. Owner decisions required

Review the [decision register D01-D08](m1-decisions-and-risks.md): Swift runtime/package boundary; SQLite/catalog/per-profile layout; protection/encryption before real data; retention/retained URL/query/title scope and restore defaults; safe restoration/history policy; and the exact finite implementation slice. Spaces and actual transport/capability/release choices remain deferred. Existing conditional engine acceptance is not requested again; new recommendations are not silently Approved/Accepted.

## 11. Risks, verification and evidence limits

The [risk register R01-R12](m1-decisions-and-risks.md) covers reentrancy, wrong-store/private leakage, data protection, migration/key loss, backup resurrection, partial native effects, SQLite latency/durability, old contract ambiguity, restricted compatibility, trusted-host/OS limits and unassigned operational owners. No runtime/storage benchmark or proof-of-concept runs here. Account/media workflows remain access-blocked; macOS26 and DeveloperID/notarization remain deferred final-stage gates.

Actual work is read-only Git/source/hash/Nx inspection, primary-document research, documentation authoring, scoped Markdown formatting/link review and protected-file comparison. Initial pinned-pnpm registry/cache restrictions and the authorized retry are recorded separately in this run; identity verification was not disabled. [Review evidence](../../evidence/20261107T161137Z-m1-design/documentation-review.json) records exact command outcomes and limitations. No product tests or measured performance results are invented.

## 12. M1 design completion assessment and stop

| Area                                                                                       | Assessment                                           | Limit                                                             |
| ------------------------------------------------------------------------------------------ | ---------------------------------------------------- | ----------------------------------------------------------------- |
| Requested architecture/runtime/persistence/model/recovery/contracts/sequence/risk coverage | Prepared for owner review                            | Recommendations remain Proposed, not owner-approved               |
| Documentation navigation/format/link and protected-file review                             | See recorded documentation verification              | Documentation checks only; not product/engine/security acceptance |
| M0 source/build configuration and historical Phase3/M0 evidence                            | Preserved                                            | Historical results not reinterpreted or rerun                     |
| M1 implementation and feature/security tests                                               | Not Started / Not Tested                             | No source/package/schema/bridge or database added                 |
| M2+ and release qualification                                                              | Not Started; existing access/deferred gates retained | No new authorization, no public distribution                      |

**Design preparation complete for owner review; approval pending. M1 implementation is not complete or authorized.** ADR0001 remains Proposed; ADR0002 Accepted; ADR0003/0004 Proposed. No Aura, CEF implementation, production Tamizhi, Vezham identity/cloud dependency or public distribution.

Stop after this packet and consistency review. Next action is owner review/disposition, then a separate scoped implementation instruction; do not implement merely because a design was prepared.
