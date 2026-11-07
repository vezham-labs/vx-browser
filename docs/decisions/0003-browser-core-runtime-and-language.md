# ADR 0003: Browser Core runtime and language

- **Status:** Proposed
- **Date:** 2026-11-07
- **Authority:** Recommendation prepared under the M1 design-only instruction; Product Owner approval pending.
- **Implementation:** Not authorized by this record. ADR 0001 remains Proposed; ADR 0002 remains Accepted.

## Problem and established boundaries

The approved architecture separates native authority, engine-independent policy, engine objects and React presentation, but deliberately leaves the core runtime open. The older [engine contract](../architecture/browser-engine-contract.md) uses illustrative TypeScript declarations. They do not select a JavaScript runtime or put policy inside React. M0 already supplies a Swift/AppKit executable, not a core or script host.

## Alternatives

| Approach                                                                 | Advantages                                                                                                     | Costs and security/privacy implications                                                                                                          | Performance and maintenance implications                                                                                                                    |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Swift value models and actor-coordinated core in the native host process | Reuses the native toolchain; typed calls to platform adapters; no additional production runtime or IPC service | Actor/reentrancy mistakes still matter; shared host compromise reaches trusted core state; no claim of a security boundary between Swift modules | Avoids a second runtime/FFI; serialization still needed for future chrome. Swift API ownership and portability discipline require review, not a speed claim |
| TypeScript core in an isolated JavaScriptCore context                    | Language sharing with chrome models; possible independent policy context                                       | Requires explicit host bindings, context lifecycle and exception/cancellation mapping; never run authority in the chrome or page world           | Adds a JS runtime/context to manage and cross-runtime conversion; sharing types does not eliminate runtime validation                                       |
| TypeScript core in a separate Node process                               | Mature JavaScript tooling and process lifecycle independent of UI                                              | Adds a production runtime, process/IPC and packaging/update/permission surface; can expose broad native capabilities if misconfigured            | More startup, distribution and failure coordination work; no measured benefit for this macOS-only MVP                                                       |
| Rust/C++ shared core with Swift bindings                                 | Future native portability and explicit low-level control                                                       | New language/toolchain/FFI and ownership review; not required by approved scope                                                                  | Higher integration and maintenance burden now; revisit for a concrete portability or measured performance need                                              |
| Core policy inside React                                                 | Easy initial state sharing                                                                                     | Privileged policy would follow chrome script lifetime and UI compromise; violates the approved authority boundary                                | Rejected; convenience does not justify coupling                                                                                                             |

These cost comparisons are engineering judgments, not benchmarks. No alternative runtime was installed or tested.

## Proposed decision

Use **Swift 6**, with Foundation-only domain values and ports, in the existing native application process. Propose a local Swift package `apps/browser-macos/Packages/BrowserCoreKit/` with `BrowserDomain`, `BrowserPorts`, `BrowserCore` and `BrowserPersistence` targets; create none in this task. Keep AppKit/WebKit/Security and SQLite connection objects outside the domain/core targets. The host is the composition root and independently enforces native authorization.

Use a core actor for mutable ownership/state, with short synchronous state transitions and explicit effects. AppKit and future WK objects remain on the main actor. Database I/O uses a bounded serial worker behind a persistence service; do not perform blocking SQLite work on the main actor or assume an actor implies a dedicated I/O thread. [Swift Sendable](https://docs.swift.org/latest/documentation/swift/sendable/) describes values crossing isolation domains; [SE-0306 actors](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-actors.md#actor-reentrancy) explains why state can change across suspension.

An `await` is a revalidation point: reserve an effect ID and owner generation first, then compare generation/revision on completion. No actor-held state assumption, native handle or live database cursor crosses an asynchronous boundary unchecked. Avoid blanket `@unchecked Sendable` as an integration shortcut.

React/TypeScript/HeroUI v3 remains the future presentation layer. A language-neutral versioned contract maps to Swift and TypeScript value bindings later. No JavaScriptCore/Node authority runtime, generic bridge or code-generation dependency is selected now. See [contracts](../architecture/phase-5/reports/M1/core-boundary-contracts.md).

## Consequences and reversibility

This keeps the first implementation close to the approved native host and reduces runtime/packaging obligations. The team must maintain Swift domain expertise, protocol compatibility and asynchronous ownership tests. It does not prove better performance or cross-platform readiness.

Engine independence means no WK types in core interfaces; it does not mean every engine capability is portable. Pure models, versioned DTOs and repository ports make a later runtime replacement reviewable, but replacement would still require behavioral requalification and migration review. Swift binary ABI is not the UI protocol. No existing browser data or core package needs migration because neither exists yet.

## Approval and revisit conditions

Owner approval is requested for the Swift core/runtime and proposed package boundary, followed by a separately scoped implementation instruction. Chrome hosting/transport, account workflows and release tooling remain later decisions. Revisit for a funded second-platform requirement, demonstrated runtime constraint or measured problem that this approach cannot resolve; do not introduce a new runtime speculatively.

[Core architecture](../architecture/phase-5/reports/M1/browser-core-architecture.md) · [M1 review](../architecture/phase-5/reports/M1/README.md) · [Open decisions](../architecture/phase-5/reports/M1/m1-decisions-and-risks.md)
