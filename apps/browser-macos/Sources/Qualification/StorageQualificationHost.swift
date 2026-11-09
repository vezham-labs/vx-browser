#if WSF1_QUALIFICATION
import AppKit
import WebKit
import Foundation
import Darwin
import BrowserNativeStorage
import BrowserDomain
import BrowserPorts
import BrowserPersistence

/// Debug-only synthetic host, entered explicitly; no normal-profile or website-file access.
@MainActor enum StorageQualificationHost {
    struct Row: Codable, Sendable {
        let profile: ProfileID
        let store: StoreID
        let revision: UInt64
        let resourceGeneration: UInt64
        let status: CatalogStatus
        let origin: BindingOrigin
        init(_ b: ProfileBinding) {
            profile = b.profile; store = b.store; revision = b.revision
            resourceGeneration = b.resourceGeneration; status = b.status; origin = b.origin
        }
        func binding(_ ns: NamespaceID) throws -> ProfileBinding {
            try ProfileBinding(profile: profile, store: store, namespace: ns, revision: revision,
                 resourceGeneration: resourceGeneration, status: status, origin: origin)
        }
    }
    struct Checkpoint: Codable, Sendable { let rows: [Row]; let snapshot: RestartSnapshot }
    struct Profile: Codable, Sendable { let name: String; let profile: ProfileID; let store: StoreID }
    struct Input: Codable, Sendable {
        let action: String
        let namespace: NamespaceID
        let profiles: [Profile]
        let checkpoint: Checkpoint?
        let origin: String?
        let cutpoint: String?
    }
    struct Case: Codable { let id: String; let status: String; let detail: String }
    struct Envelope: Codable {
        let event: String
        var cases: [Case]? = nil
        var checkpoint: Checkpoint? = nil
        var trace: [NativeWebKitStorage.Event]? = nil
        var environment: [String: String]? = nil
        var originalPresence: [String: Bool]? = nil
    }
    static func emit(_ envelope: Envelope) {
        guard let data = try? JSONEncoder().encode(envelope) else { return }
        FileHandle.standardOutput.write(data + Data([10]))
    }
    static func fresh<T>() -> ID<T> { try! ID(UUID().uuidString) }
    static func event(_ name: String, input: Input) {
        emit(Envelope(event: name))
        if input.cutpoint == name { raise(SIGSTOP) } // Exact dedicated child only; parent kills it.
    }
    actor CheckpointPorts: ProfileCatalogPort, RecoveryJournalPort {
        let catalog: InMemoryProfileCatalog
        let journal: InMemoryRecoveryJournal
        let run: RunID
        private var failPublication: Bool
        init(namespace: NamespaceID, run: RunID, checkpoint: Checkpoint?, failPublication: Bool = false) throws {
            self.run = run
            self.failPublication = failPublication
            let raw = try (checkpoint?.rows ?? []).map { row -> RawBinding in
                let b = try row.binding(namespace)
                return RawBinding(profile: b.profile.rawValue, store: b.store.rawValue, namespace: namespace.rawValue,
                     revision: b.revision, resourceGeneration: b.resourceGeneration, status: b.status, origin: b.origin)
            }
            catalog = InMemoryProfileCatalog(namespace: namespace, raw: raw)
            journal = InMemoryRecoveryJournal(namespace: namespace, snapshot: checkpoint?.snapshot, newRun: run)
        }
        func lookup(_ profile: ProfileID) async -> CatalogObservation { await catalog.lookup(profile) }
        func enumerate() async -> CatalogInventory { await catalog.enumerate() }
        func read(_ profile: ProfileID) async -> RecoveryObservation { await journal.read(profile) }
        func snapshot(run: RunID) async -> RestartSnapshot { await journal.snapshot(run: run) }
        func capture() async -> Checkpoint {
            let rows = await catalog.enumerate().bindings.map(Row.init)
            return Checkpoint(rows: rows, snapshot: await journal.snapshot(run: run))
        }
        func mirror() async { await emit(Envelope(event: "checkpoint", checkpoint: await capture())) }
        func insert(_ binding: ProfileBinding) async -> CatalogWrite {
            let r = await catalog.insert(binding); await mirror(); return r
        }
        func transition(_ profile: ProfileID, expectedRevision: UInt64, to status: CatalogStatus) async -> CatalogWrite {
            let r = await catalog.transition(profile, expectedRevision: expectedRevision, to: status); await mirror(); return r
        }
        func write(_ record: RecoveryRecord) async -> JournalWrite {
            if failPublication, case .pending(.activate) = record.phase,
               case .record(let prior) = await journal.read(record.profile),
               case .stable(.active) = prior.phase, prior.operation == record.operation {
                failPublication = false
                await emit(Envelope(event: "injected-publication-journal-failure"))
                return .failed(.journalUnavailable)
            }
            let r = await journal.write(record); await mirror(); return r
        }
    }
    static func run() async {
        var cases: [Case] = []
        func check(_ id: String, _ condition: Bool, _ detail: String) {
            cases.append(Case(id: id, status: condition ? "PASS_NATIVE" : "FAIL", detail: detail))
        }
        do {
            let bytes = FileHandle.standardInput.readDataToEndOfFile()
            guard bytes.count <= 65536 else { throw FailureCode.capacityExceeded }
            let input = try JSONDecoder().decode(Input.self, from: bytes)
            guard Bundle.main.bundleIdentifier?.contains("wsf1") == true || input.action == "enumerate-original" else { throw FailureCode.unauthorized }
            let run: RunID = fresh()
            if input.action == "enumerate-original" {
                guard Bundle.main.bundleIdentifier == "internal.vx.M1Validation.run20261108T094414Z" else { throw FailureCode.unauthorized }
                let adapter = try NativeWebKitStorage(namespace: input.namespace)
                emit(Envelope(event: "diagnostic-before-enumeration"))
                let ids = await adapter.identifiers()
                guard let ids else { throw FailureCode.observationUnknown }
                let originals = ["abb4ca2d-33dc-4d25-9c16-d135202c03e3", "9ec735a8-b9eb-416c-994b-4b299c5ee5f5"]
                emit(Envelope(event: "result", cases: [Case(id: "F1-DIAG-001", status: "PASS_NATIVE", detail: "Noncreating public enumeration only; logical prior removal remains unknown")], originalPresence: Dictionary(uniqueKeysWithValues: originals.map { ($0, ids.contains(UUID(uuidString: $0)!)) })))
                return
            }
            guard input.profiles.count == 2, Set(input.profiles.map(\.name)) == Set(["A", "B"]), Set(input.profiles.map(\.profile)).count == 2,
                  Set(input.profiles.map(\.store)).count == 2,
                  let origin = input.origin, let u = URL(string: origin), u.scheme == "http", u.host == "127.0.0.1", u.port != nil,
                  u.path.isEmpty, u.user == nil, u.password == nil, u.query == nil, u.fragment == nil else { throw FailureCode.invalidConfiguration }
            let ports = try CheckpointPorts(namespace: input.namespace, run: run, checkpoint: input.checkpoint, failPublication: input.action == "publication-failure")
            let known = try (input.checkpoint?.rows ?? []).map { try $0.binding(input.namespace) }
            let session = try NativeStorageSession(namespace: input.namespace, run: run, catalog: ports, journal: ports,
                     bindings: known, allowedOrigins: [origin])
            session.adapter.eventSink = { event in self.event(event.kind, input: input) }
            let env = ["macOS": ProcessInfo.processInfo.operatingSystemVersionString,
                       "bundle": Bundle.main.bundleIdentifier ?? "unknown",
                       "WebKit": Bundle(for: WKWebView.self).infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
                       "qualification": ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 26 ? "macOS26" : "discovery-only"]
            emit(Envelope(event: "boot", environment: env))
            if input.action == "private-only" {
                try await privateCases(session, origin: origin, cases: &cases, input: input, persistentPositiveControl: false)
                let checkpoint = await ports.capture()
                check("F1-NAT-PRIVATE-NO-PERSISTENT-METADATA", checkpoint.rows.isEmpty && checkpoint.snapshot.records.isEmpty, "Private-only run writes no catalog or journal records")
                emit(Envelope(event: "result", cases: cases, checkpoint: checkpoint, trace: session.adapter.trace(), environment: env))
                return
            }
            var contexts: [ProfileID: CallerContext] = [:]
            var opened: [ProfileID: ViewID] = [:]
            var openOrdinal = 0
            for p in input.profiles {
                let scope = Scope.persistent(p.profile)
                contexts[p.profile] = await session.authority.grant(scope, run: run)
            }
            func open(_ p: Profile) async throws -> ViewID {
                let scope = Scope.persistent(p.profile), context = contexts[p.profile]!
                let view: ViewID = fresh(), operation: OperationID = fresh()
                let r = await session.open(scope, context: context, view: view, operation: operation)
                guard r == .success(.activated(view)) else { throw FailureCode.activationFailed }
                opened[p.profile] = view
                guard await session.adapter.navigate(view, url: URL(string: origin + "/fixture")!) == .completed else { throw FailureCode.activationFailed }
                openOrdinal += 1
                let before = session.adapter.trace().count
                let replay = await session.open(scope, context: context, view: view, operation: operation)
                check("F1-NAT-ACTIVATE-REPLAY-\(openOrdinal)-\(p.name)", replay == r && session.adapter.trace().count == before, "Terminal same-operation replay after navigation performs no native effect")
                return view
            }
            func close(_ p: Profile) async throws {
                let scope = Scope.persistent(p.profile), context = contexts[p.profile]!
                if let view = opened.removeValue(forKey: p.profile) {
                    guard await session.core.closeView(scope, view: view, context: context, operation: fresh()) == .success(.viewClosed) else { throw FailureCode.outstandingReferences }
                }
                guard await session.core.quiesce(scope, context: context, operation: fresh()) == .success(.quiesced) else { throw FailureCode.quiescenceTimeout }
            }
            if input.action == "seed" {
                for p in input.profiles {
                    let binding = try ProfileBinding(profile: p.profile, store: p.store, namespace: input.namespace)
                    let context = contexts[p.profile]!, scope = Scope.persistent(p.profile)
                    let op: OperationID = fresh()
                    let r = await session.core.register(binding, context: context, operation: op)
                    check("F1-NAT-REGISTER-\(p.name)", r == .success(.registered), "Synthetic catalog only")
                    check("F1-NAT-IDEMPOTENT-\(p.name)", await session.core.register(binding, context: context, operation: op) == r, "Exact registration receipt replay")
                    event("creation-intent", input: input)
                    guard await session.core.resolve(scope, context: context, operation: fresh()) == .success(.resolved) else { throw FailureCode.storeMissing }
                    let view = try await open(p)
                    let initial = try await evaluate(session, view, "return JSON.stringify(await fixture.get())")
                    for category in ["cookie", "local", "idb", "cache"] {
                        check("F1-NAT-EMPTY-\(p.name)-\(category)", initial[category] == "", "Fresh store positive API availability checked during set")
                    }
                    let seeded = try await evaluate(session, view, "return JSON.stringify(await fixture.set('\(p.name)'))")
                    for category in ["cookie", "local", "idb", "cache", "session", "worker"] {
                        if seeded[category] == "unsupported" {
                            cases.append(Case(id: "F1-NAT-SEED-\(p.name)-\(category)", status: "INCONCLUSIVE", detail: "Native class unavailable; not isolation proof"))
                        } else { check("F1-NAT-SEED-\(p.name)-\(category)", seeded[category] == p.name, "Page-visible positive control") }
                    }
                    check("F1-NAT-SEED-\(p.name)-http", seeded["http"]?.hasPrefix("response-") == true, "HTTP cache fixture response; persistence compared by orchestrator")
                    emit(Envelope(event: "seed-values-\(p.name)", environment: seeded))
                }
                // A is re-read while B is alive; each category has an earlier positive control.
                for p in input.profiles {
                    let observed = try await evaluate(session, opened[p.profile]!, "return JSON.stringify(await fixture.get())")
                    for k in ["cookie", "local", "idb", "cache"] { check("F1-NAT-ISOLATION-\(p.name)-\(k)", observed[k] == p.name, "Concurrent same-origin profiles") }
                }
            } else {
                for p in input.profiles {
                    let r = await session.core.reconcile(p.profile, context: contexts[p.profile]!, operation: fresh())
                    if input.action == "reconcile-uncertain" {
                        let record = input.checkpoint?.snapshot.records.first { $0.profile == p.profile }
                        let stable: Bool
                        if let record, case .stable(let status) = record.phase,
                           [CatalogStatus.active, .quiescent, .retired].contains(status) { stable = true }
                        else { stable = false }
                        check("F1-NAT-RECOVERY-\(p.name)", stable ? r == .success(.reconciled) : r != .success(.reconciled), "Stable unaffected mapping resolves; interrupted/missing mapping stays fenced")
                        let repeated = await session.core.reconcile(p.profile, context: contexts[p.profile]!, operation: fresh())
                        check("F1-NAT-RECOVERY-REPEATED-\(p.name)", stable ? repeated == .success(.reconciled) : repeated != .success(.reconciled), "Repeated reconciliation grants no factory/publication")
                    } else {
                        guard r == .success(.reconciled) else { throw FailureCode.reconciliationMismatch }
                    }
                }
                if input.action == "reconcile-uncertain" {
                    check("F1-NAT-RECOVERY-NOCREATE", !session.adapter.trace().contains { $0.kind.contains("factory") }, "Noncreating reconciliation")
                } else if input.action == "publication-failure" {
                    let p = input.profiles[0], scope = Scope.persistent(p.profile), view: ViewID = fresh(), context = contexts[p.profile]!
                    let result = await session.open(scope, context: context, view: view, operation: fresh())
                    let summary = await session.core.summary(scope)
                    check("F1-NAT-PUBLICATION-FAILURE", result == .failure(.journalUnavailable), "Real construction with synthetic injected metadata-write failure")
                    check("F1-NAT-PUBLICATION-FENCED", summary?.state == .quarantined && session.adapter.surface(view) == nil, "No publication/navigation after unavailable journal")
                    _ = await session.core.closeView(scope, view: view, context: context, operation: fresh())
                } else if input.action == "remove" {
                    for p in input.profiles {
                        // No factory/view on this cleanup path. The prior process already exited.
                        let scope = Scope.persistent(p.profile), context = contexts[p.profile]!
                        guard await session.core.quiesce(scope, context: context, operation: fresh()) == .success(.quiesced),
                              await session.core.retire(scope, context: context, operation: fresh()) == .success(.retired) else { throw FailureCode.retirementFailed }
                        event("before-remove", input: input)
                        let r = await session.core.remove(p.profile, context: context, operation: fresh())
                        check("F1-NAT-REMOVE-\(p.name)", r == .success(.removed), "Public callback plus noncreating absence; no secure-erasure claim")
                    }
                } else {
                    for p in input.profiles {
                        let view = try await open(p)
                        let observed = try await evaluate(session, view, "return JSON.stringify(await fixture.get())")
                        for k in ["cookie", "local", "idb", "cache", "worker"] {
                            if observed[k] == "unsupported" { cases.append(Case(id: "F1-NAT-RESTART-\(p.name)-\(k)", status: "INCONCLUSIVE", detail: "Native class unavailable")) }
                            else { check("F1-NAT-RESTART-\(p.name)-\(k)", observed[k] == p.name, "Actual new app process / stable mapping") }
                        }
                        check("F1-NAT-RESTART-\(p.name)-session", observed["session"] == "", "New browsing context does not restore sessionStorage")
                        emit(Envelope(event: "restart-values-\(p.name)", environment: observed))
                    }
                    if input.action == "clear" {
                        let p = input.profiles[0], scope = Scope.persistent(p.profile), context = contexts[p.profile]!
                        try await close(p)
                        event("before-clear", input: input)
                        let r = await session.core.clear(scope, types: [.localStorage], context: context, operation: fresh())
                        check("F1-NAT-CLEAR-CALLBACK", r == .success(.cleared([.localStorage])), "Selected localStorage only")
                        let view = try await open(p)
                        let observed = try await evaluate(session, view, "return JSON.stringify(await fixture.get())")
                        check("F1-NAT-CLEAR-LOCAL", observed["local"] == "", "Observable selected-class absence")
                        for k in ["cookie", "idb", "cache"] { check("F1-NAT-CLEAR-RETAIN-\(k)", observed[k] == p.name, "Unselected class positive control retained") }
                    }
                    if input.action == "private" { try await privateCases(session, origin: origin, cases: &cases, input: input) }
                    if input.action == "switch" {
                        let a = input.profiles[0], b = input.profiles[1]
                        let extra: ViewID = fresh()
                        guard await session.open(.persistent(a.profile), context: contexts[a.profile]!, view: extra, operation: fresh()) == .success(.activated(extra)),
                              await session.adapter.navigate(extra, url: URL(string: origin + "/fixture")!) == .completed else { throw FailureCode.activationFailed }
                        let values = try await evaluate(session, extra, "return JSON.stringify(await fixture.get())")
                        check("F1-NAT-MULTIVIEW-SHARE", values["local"] == a.name, "Two views share only their intended profile")
                        let windows = mountTwoWindows(session, first: opened[a.profile]!, second: extra)
                        check("F1-NAT-MULTIWINDOW", windows, "Two NSWindows consume owned surfaces and release them before close")
                        _ = await session.core.closeView(.persistent(a.profile), view: extra, context: contexts[a.profile]!, operation: fresh())
                        check("F1-NAT-NONLAST-PERSISTENT", session.adapter.surface(opened[a.profile]!) != nil, "Other view remains usable")
                        try await close(a)
                        for (source, destination) in [(a, b), (b, a)] {
                            let view: ViewID = fresh()
                            let result = await session.switchProfile(from: .persistent(source.profile), to: .persistent(destination.profile), sourceContext: contexts[source.profile]!, context: contexts[destination.profile]!, view: view, operation: fresh())
                            check("F1-NAT-SWITCH-\(source.name)-\(destination.name)", result == .success(.switched(view)), "Fresh immutable view ownership")
                            guard await session.adapter.navigate(view, url: URL(string: origin + "/fixture")!) == .completed else { throw FailureCode.activationFailed }
                            let read = try await evaluate(session, view, "return JSON.stringify(await fixture.get())")
                            for k in ["cookie", "local", "idb", "cache"] { check("F1-NAT-SWITCH-\(destination.name)-\(k)", read[k] == destination.name, "Destination data remains scoped") }
                            _ = await session.core.closeView(.persistent(destination.profile), view: view, context: contexts[destination.profile]!, operation: fresh())
                            if destination.profile == b.profile { try await close(b) }
                        }
                    }
                }
            }
            for p in input.profiles where opened[p.profile] != nil { try await close(p) }
            event("clean-shutdown", input: input)
            let checkpoint = await ports.capture()
            emit(Envelope(event: "result", cases: cases, checkpoint: checkpoint, trace: session.adapter.trace(), environment: env))
        } catch {
            emit(Envelope(event: "result", cases: cases + [Case(id: "F1-HOST-ERROR", status: "FAIL", detail: (error as? FailureCode)?.rawValue ?? "invalid-input-or-framework-result")]))
        }
    }
    static func evaluate(_ session: NativeStorageSession, _ view: ViewID, _ script: String) async throws -> [String: String] {
        guard let native = session.adapter.surface(view) else { throw FailureCode.missingAssignment }
        let text: String? = await withCheckedContinuation { done in
            native.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { result in
                switch result { case .success(let value): done.resume(returning: value as? String)
                case .failure: done.resume(returning: nil) }
            }
        }
        guard let text, text.count < 16384, let bytes = text.data(using: .utf8) else { throw FailureCode.observationUnknown }
        return try JSONDecoder().decode([String: String].self, from: bytes)
    }
    static func mountTwoWindows(_ session: NativeStorageSession, first: ViewID, second: ViewID) -> Bool {
        guard let a = session.adapter.surface(first), let b = session.adapter.surface(second) else { return false }
        let one = NSWindow(contentRect: a.frame, styleMask: [.titled], backing: .buffered, defer: false)
        let two = NSWindow(contentRect: b.frame, styleMask: [.titled], backing: .buffered, defer: false)
        one.isReleasedWhenClosed = false; two.isReleasedWhenClosed = false
        one.contentView = a; two.contentView = b
        let result = one.contentView === a && two.contentView === b && one !== two
        one.contentView = nil; two.contentView = nil; one.close(); two.close()
        return result
    }
    static func privateCases(_ session: NativeStorageSession, origin: String, cases: inout [Case], input: Input, persistentPositiveControl: Bool = true) async throws {
        func check(_ id: String, _ condition: Bool) { cases.append(Case(id: id, status: condition ? "PASS_NATIVE" : "FAIL", detail: "Private in-session/fresh-session page-visible behavior; no forensic claim")) }
        func make() async throws -> (Scope, CallerContext, ViewID) {
            let id: PrivateSessionID = fresh(), view: ViewID = fresh(), scope = Scope.privateSession(id)
            let context = await session.authority.grant(scope, run: session.run)
            guard await session.core.registerPrivate(id, context: context, operation: fresh()) == .success(.registered),
                  await session.core.resolve(scope, context: context, operation: fresh()) == .success(.resolved),
                  await session.open(scope, context: context, view: view, operation: fresh()) == .success(.activated(view)),
                  await session.adapter.navigate(view, url: URL(string: origin + "/fixture")!) == .completed else { throw FailureCode.activationFailed }
            return (scope, context, view)
        }
        let a = try await make(), b = try await make()
        let initial = try await evaluate(session, a.2, "return JSON.stringify(await fixture.get())")
        for k in ["cookie", "local", "idb"] { check("F1-NAT-PRIVATE-\(persistentPositiveControl ? "PERSISTENT-SEPARATE" : "INITIAL-EMPTY")-\(k)", initial[k] == "") }
        let seeded = try await evaluate(session, a.2, "return JSON.stringify(await fixture.set('PRIVATE'))")
        for k in ["cookie", "local", "idb"] { check("F1-NAT-PRIVATE-POSITIVE-\(k)", seeded[k] == "PRIVATE") }
        event("private-active", input: input)
        let separate = try await evaluate(session, b.2, "return JSON.stringify(await fixture.get())")
        for k in ["cookie", "local", "idb"] { check("F1-NAT-PRIVATE-INDEPENDENT-\(k)", separate[k] == "") }
        let extra: ViewID = fresh()
        guard await session.open(a.0, context: a.1, view: extra, operation: fresh()) == .success(.activated(extra)),
              await session.adapter.navigate(extra, url: URL(string: origin + "/fixture")!) == .completed else { throw FailureCode.activationFailed }
        let shared = try await evaluate(session, extra, "return JSON.stringify(await fixture.get())")
        for k in ["cookie", "local", "idb"] { check("F1-NAT-PRIVATE-SHARED-\(k)", shared[k] == "PRIVATE") }
        let nonlast = await session.core.closeView(a.0, view: a.2, context: a.1, operation: fresh())
        check("F1-NAT-PRIVATE-NONLAST", nonlast == .success(.viewClosed) && session.adapter.surface(extra) != nil)
        for tuple in [(a.0, a.1, extra), b] {
            let closed = await session.core.closeView(tuple.0, view: tuple.2, context: tuple.1, operation: fresh())
            let summary = await session.core.summary(tuple.0)
            check("F1-NAT-PRIVATE-LAST-\(tuple.2 == extra ? "A" : "B")", closed == .success(.viewClosed) && summary?.state == .retired)
        }
        let c = try await make()
        let freshData = try await evaluate(session, c.2, "return JSON.stringify(await fixture.get())")
        for k in ["cookie", "local", "idb"] { check("F1-NAT-PRIVATE-FRESH-\(k)", freshData[k] == "") }
        let closed = await session.core.closeView(c.0, view: c.2, context: c.1, operation: fresh())
        let summary = await session.core.summary(c.0)
        check("F1-NAT-PRIVATE-LAST-C", closed == .success(.viewClosed) && summary?.state == .retired)
    }
}
#endif
