import Foundation
import Testing
import BrowserDomain
import BrowserPorts
import BrowserCore
import BrowserPersistence
import WSF0Fakes

func fixtureID<T>(_ value: Int) -> ID<T> {
    // Public deterministic fixture identifiers only; no random/native service.
    try! ID<T>(String(format: "00000000-0000-4000-8000-%012llx", UInt64(value)))
}
struct Fixture: Sendable {
    let namespace: NamespaceID = fixtureID(800)
    let run: RunID
    let faults = FaultScript()
    let calls = CallRecorder()
    let gate = ControlledGate()
    let authority = FakeHostAuthority()
    let resources = FakeResources()
    let catalog: InMemoryProfileCatalog
    let journal: InMemoryRecoveryJournal
    let engine: FakeEngine
    let views: FakeConstruction
    let core: LifecycleCoordinator
    init(runNumber: Int = 900, raw: [RawBinding] = [], snapshot: RestartSnapshot? = nil,
         engineFixtures: [PersistentFixture] = [], diagnostics: Int = 1024) throws {
        run = fixtureID(runNumber)
        catalog = InMemoryProfileCatalog(namespace: namespace, raw: raw)
        journal = InMemoryRecoveryJournal(namespace: namespace, snapshot: snapshot, newRun: run)
        engine = FakeEngine(faults: faults, calls: calls, gate: gate, fixtures: engineFixtures)
        views = FakeConstruction(engine: engine, resources: resources, calls: calls, faults: faults, gate: gate)
        core = try LifecycleCoordinator(run: run, namespace: namespace, authority: authority, catalog: catalog,
                                        journal: journal, engine: engine, constructor: views, resources: resources,
                                        diagnosticLimit: diagnostics)
    }
    func binding(_ number: Int = 1, store: Int? = nil, origin: BindingOrigin = .fresh) -> ProfileBinding {
        try! ProfileBinding(profile: fixtureID(number), store: fixtureID(store ?? (100 + number)), namespace: namespace, origin: origin)
    }
    func context(_ scope: Scope, caller: Int = 500) async -> CallerContext {
        await authority.grant(fixtureID(caller), scope: scope, run: run)
    }
    func prepared(_ number: Int = 1, base: Int = 1000) async -> CallerContext {
        let b = binding(number), scope = Scope.persistent(b.profile)
        let c = await context(scope, caller: 500 + number)
        #expect(await core.register(b, context: c, operation: fixtureID(base)) == .success(.registered))
        #expect(await core.resolve(scope, context: c, operation: fixtureID(base + 1)) == .success(.resolved))
        return c
    }
    func active(_ number: Int = 1, base: Int = 1000, view: Int = 200) async -> CallerContext {
        let c = await prepared(number, base: base)
        #expect(await core.activate(c.scope, view: fixtureID(view), context: c, operation: fixtureID(base + 2)) == .success(.activated(fixtureID(view))))
        return c
    }
    func retired(_ number: Int = 1, base: Int = 1000, view: Int = 200) async -> CallerContext {
        let c = await active(number, base: base, view: view)
        #expect(await core.closeView(c.scope, view: fixtureID(view), context: c, operation: fixtureID(base + 3)) == .success(.viewClosed))
        #expect(await core.quiesce(c.scope, context: c, operation: fixtureID(base + 4)) == .success(.quiesced))
        #expect(await core.retire(c.scope, context: c, operation: fixtureID(base + 5)) == .success(.retired))
        return c
    }
    func rawCatalog() async -> [RawBinding] {
        let inv = await catalog.enumerate()
        return inv.bindings.map { RawBinding(profile: $0.profile.rawValue, store: $0.store.rawValue,
                                             namespace: $0.namespace.rawValue, revision: $0.revision, resourceGeneration: $0.resourceGeneration, status: $0.status, origin: $0.origin) }
    }
}
