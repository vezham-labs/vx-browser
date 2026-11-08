import Testing
import BrowserDomain
import BrowserCore
import WSF0Fakes

@Suite("F0.8 full fake integration scenarios", .serialized)
struct IntegrationTests {
    @Test("F0-INT-001 persistent create activate switch clear retire remove lifecycle")
    func lifecycle() async throws {
        let f = try Fixture(); let a = await f.active(); let b = await f.prepared(2, base: 1100)
        let ai = try #require(await f.engine.assignment(for: a.scope)), bi = try #require(await f.engine.assignment(for: b.scope))
        _ = await f.engine.seed(ai, kind: .localStorage, text: "PROFILE-A")
        _ = await f.engine.seed(bi, kind: .localStorage, text: "PROFILE-B")
        _ = await f.core.closeView(a.scope, view: fixtureID(200), context: a, operation: fixtureID(1200))
        _ = await f.core.quiesce(a.scope, context: a, operation: fixtureID(1201))
        #expect(await f.core.switchScope(from: a.scope, to: b.scope, view: fixtureID(201), from: a, to: b, operation: fixtureID(1202)) == .success(.switched(fixtureID(201))))
        #expect(await f.engine.value(ai, kind: .localStorage) == "PROFILE-A")
        #expect(await f.engine.value(bi, kind: .localStorage) == "PROFILE-B")
        #expect(await f.core.clear(a.scope, types: [.localStorage], context: a, operation: fixtureID(1203)) == .success(.cleared([.localStorage])))
        #expect(await f.engine.value(bi, kind: .localStorage) == "PROFILE-B")
        _ = await f.core.retire(a.scope, context: a, operation: fixtureID(1204))
        #expect(await f.core.remove(fixtureID(1), context: a, operation: fixtureID(1205)) == .success(.removed))
        #expect(await f.core.summary(b.scope)?.state == .active)
    }
    @Test("F0-INT-002 independent private session opens closes and never enters restart state")
    func privateScenario() async throws {
        let f = try Fixture(); _ = await f.active()
        let p = Scope.privateSession(fixtureID(10)), c = await f.context(.privateSession(fixtureID(10)), caller: 510)
        _ = await f.core.registerPrivate(fixtureID(10), context: c, operation: fixtureID(2000))
        _ = await f.core.resolve(p, context: c, operation: fixtureID(2001))
        _ = await f.core.activate(p, view: fixtureID(210), context: c, operation: fixtureID(2002))
        #expect(await f.core.closeView(p, view: fixtureID(210), context: c, operation: fixtureID(2003)) == .success(.viewClosed))
        #expect(await f.engine.privateCount() == 0)
        #expect(await f.catalog.enumerate().bindings.count == 1)
        #expect(await f.core.restartSnapshot().records.count == 1)
        #expect(await f.core.summary(.persistent(fixtureID(1)))?.state == .active)
    }
    @Test("F0-INT-003 interrupted activation restart cannot replay views or requests")
    func interruptedActivation() async throws {
        let f = try Fixture(); let a = await f.prepared(); await f.gate.arm(.activate)
        let pending = Task { await f.core.activate(a.scope, view: fixtureID(200), context: a, operation: fixtureID(1100)) }
        await f.gate.waitForArrival(.activate)
        let raw = await f.rawCatalog(), snapshot = await f.core.restartSnapshot(), fixtures = await f.engine.persistentSnapshot()
        await f.gate.release(.activate); _ = await pending.value
        let restarted = try Fixture(runNumber: 901, raw: raw, snapshot: snapshot, engineFixtures: fixtures)
        let c = await restarted.context(a.scope)
        #expect(await restarted.core.reconcile(fixtureID(1), context: c, operation: fixtureID(2000)) == .quarantined(.interruptedOperation))
        #expect(await restarted.calls.snapshot().isEmpty)
        #expect(await restarted.views.liveCount() == 0)
    }
    @Test("F0-INT-004 ambiguity in one profile preserves another active profile")
    func unaffectedProfile() async throws {
        let f = try Fixture(); let a = await f.retired(); let b = await f.active(2, base: 1100, view: 201)
        await f.faults.enqueue(.unknownDeletion, at: .remove)
        #expect(await f.core.remove(fixtureID(1), context: a, operation: fixtureID(1200)) == .unknown(.remove))
        #expect(await f.core.activate(a.scope, view: fixtureID(202), context: a, operation: fixtureID(1201)) == .failure(.quarantined))
        #expect(await f.core.summary(b.scope)?.state == .active)
        #expect(await f.core.summary(b.scope)?.viewCount == 1)
    }
    @Test("F0-INT-005 cross-profile and default fallback adversarial attempts have no construction effect")
    func adversarial() async throws {
        let f = try Fixture(); let a = await f.prepared(); let b = await f.prepared(2, base: 1100)
        #expect(await f.core.activate(b.scope, view: fixtureID(201), context: a, operation: fixtureID(1200)) == .failure(.unauthorized))
        #expect(await f.calls.count(.construction) == 0)
        #expect(ConstructionPolicy.validate(.defaultStore, scope: b.scope, binding: f.binding(2)) == .defaultStoreForbidden)
        #expect(await f.calls.count(.construction) == 0)
    }
}
