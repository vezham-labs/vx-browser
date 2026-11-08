import Testing
import BrowserDomain
import BrowserCore
import WSF0Fakes

@Suite("F0.2 private scopes", .serialized)
struct PrivateTests {
    @Test("F0-PRI-001 private scope never enters persistent catalog or restart journal")
    func nonPersistence() async throws {
        let f = try Fixture(); let scope = Scope.privateSession(fixtureID(10)), c = await f.context(.privateSession(fixtureID(10)))
        #expect(await f.core.registerPrivate(fixtureID(10), context: c, operation: fixtureID(1000)) == .success(.registered))
        #expect(await f.core.resolve(scope, context: c, operation: fixtureID(1001)) == .success(.resolved))
        #expect(await f.core.activate(scope, view: fixtureID(200), context: c, operation: fixtureID(1002)) == .success(.activated(fixtureID(200))))
        #expect(await f.catalog.enumerate().bindings.isEmpty)
        #expect(await f.core.restartSnapshot().records.isEmpty)
        #expect(await f.calls.count(.createPersistent) == 0)
    }
    @Test("F0-PRI-002 same private group shares one fake ephemeral identity")
    func sameGroup() async throws {
        let f = try Fixture(); let scope = Scope.privateSession(fixtureID(10)), c = await f.context(.privateSession(fixtureID(10)))
        _ = await f.core.registerPrivate(fixtureID(10), context: c, operation: fixtureID(1000))
        _ = await f.core.resolve(scope, context: c, operation: fixtureID(1001))
        let original = try #require(await f.engine.assignment(for: scope))
        #expect(await f.engine.seed(original, kind: .localStorage, text: "PUBLIC-PRIVATE-P1"))
        _ = await f.core.activate(scope, view: fixtureID(200), context: c, operation: fixtureID(1002))
        _ = await f.core.activate(scope, view: fixtureID(201), context: c, operation: fixtureID(1003))
        #expect(await f.engine.assignment(for: scope) == original)
        #expect(await f.engine.value(original, kind: .localStorage) == "PUBLIC-PRIVATE-P1")
        #expect(await f.core.summary(scope)?.viewCount == 2)
    }
    @Test("F0-PRI-003 independent private groups and persistent scopes do not share fake data")
    func independent() async throws {
        let f = try Fixture(); _ = await f.prepared()
        for n in [10, 11] {
            let scope = Scope.privateSession(fixtureID(n)), c = await f.context(scope, caller: n + 500)
            _ = await f.core.registerPrivate(fixtureID(n), context: c, operation: fixtureID(10000 + n * 100))
            _ = await f.core.resolve(scope, context: c, operation: fixtureID(10000 + n * 100 + 1))
        }
        let p1 = try #require(await f.engine.assignment(for: .privateSession(fixtureID(10))))
        let p2 = try #require(await f.engine.assignment(for: .privateSession(fixtureID(11))))
        let a = try #require(await f.engine.assignment(for: .persistent(fixtureID(1))))
        _ = await f.engine.seed(p1, kind: .cookies, text: "P1")
        #expect(p1 != p2); #expect(await f.engine.value(p2, kind: .cookies) == nil)
        #expect(await f.engine.value(a, kind: .cookies) == nil)
    }
    @Test("F0-PRI-004 non-last private owner closure preserves its sibling")
    func sibling() async throws {
        let f = try Fixture(); let scope = Scope.privateSession(fixtureID(10)), c = await f.context(.privateSession(fixtureID(10)))
        _ = await f.core.registerPrivate(fixtureID(10), context: c, operation: fixtureID(1000))
        _ = await f.core.resolve(scope, context: c, operation: fixtureID(1001))
        _ = await f.core.activate(scope, view: fixtureID(200), context: c, operation: fixtureID(1002))
        _ = await f.core.activate(scope, view: fixtureID(201), context: c, operation: fixtureID(1003))
        #expect(await f.core.closeView(scope, view: fixtureID(200), context: c, operation: fixtureID(1004)) == .success(.viewClosed))
        #expect(await f.core.summary(scope)?.state == .active)
        #expect(await f.engine.privateCount() == 1); #expect(await f.calls.count(.retire) == 0)
    }
    @Test("F0-PRI-005 last private owner triggers quiescence and retirement")
    func lastOwner() async throws {
        let f = try Fixture(); let scope = Scope.privateSession(fixtureID(10)), c = await f.context(.privateSession(fixtureID(10)))
        _ = await f.core.registerPrivate(fixtureID(10), context: c, operation: fixtureID(1000))
        _ = await f.core.resolve(scope, context: c, operation: fixtureID(1001))
        _ = await f.core.activate(scope, view: fixtureID(200), context: c, operation: fixtureID(1002))
        #expect(await f.core.closeView(scope, view: fixtureID(200), context: c, operation: fixtureID(1003)) == .success(.viewClosed))
        #expect(await f.core.summary(scope)?.state == .retired)
        #expect(await f.engine.privateCount() == 0); #expect(await f.resources.inventory(scope).isEmpty)
        #expect(await f.core.restartSnapshot().records.isEmpty)
    }
    @Test("F0-PRI-006 pending private participant blocks successful last-owner cleanup")
    func heldParticipant() async throws {
        let f = try Fixture(); let scope = Scope.privateSession(fixtureID(10)), c = await f.context(.privateSession(fixtureID(10)))
        _ = await f.core.registerPrivate(fixtureID(10), context: c, operation: fixtureID(1000))
        _ = await f.core.resolve(scope, context: c, operation: fixtureID(1001))
        _ = await f.core.activate(scope, view: fixtureID(200), context: c, operation: fixtureID(1002))
        let ref = ResourceReference(id: fixtureID(700), kind: .participant)
        _ = await f.resources.add(ref, scope: scope)
        #expect(await f.core.closeView(scope, view: fixtureID(200), context: c, operation: fixtureID(1003)) == .failure(.outstandingReferences))
        #expect(await f.core.summary(scope)?.state == .quiescing)
        #expect(await f.engine.privateCount() == 1)
        await f.resources.release(ref, scope: scope)
        #expect(await f.core.quiesce(scope, context: c, operation: fixtureID(1004)) == .success(.quiesced))
        #expect(await f.core.retire(scope, context: c, operation: fixtureID(1005)) == .success(.retired))
        #expect(await f.engine.privateCount() == 0)
    }
    @Test("F0-PRI-007 private context cannot request persistent removal or receive persistent assignment")
    func refusePersistent() async throws {
        let f = try Fixture(); let scope = Scope.privateSession(fixtureID(10)), c = await f.context(.privateSession(fixtureID(10)))
        _ = await f.core.registerPrivate(fixtureID(10), context: c, operation: fixtureID(1000))
        #expect(await f.core.remove(fixtureID(10), context: c, operation: fixtureID(1001)) == .failure(.unauthorized))
        await f.faults.enqueue(.foreignIdentity(.persistent(profile: fixtureID(1), store: fixtureID(101), namespace: f.namespace, generation: 1)), at: .createPrivate)
        #expect(await f.core.resolve(scope, context: c, operation: fixtureID(1002)) == .failure(.invalidStoreIdentity))
        #expect(await f.catalog.enumerate().bindings.isEmpty)
    }
    @Test("F0-PRI-008 new process snapshots contain no private data or sessions")
    func restartExclusion() async throws {
        let f = try Fixture(); let scope = Scope.privateSession(fixtureID(10)), c = await f.context(.privateSession(fixtureID(10)))
        _ = await f.core.registerPrivate(fixtureID(10), context: c, operation: fixtureID(1000))
        _ = await f.core.resolve(scope, context: c, operation: fixtureID(1001))
        let p = try #require(await f.engine.assignment(for: scope)); _ = await f.engine.seed(p, kind: .cookies, text: "PRIVATE-MARKER")
        let snapshot = await f.core.restartSnapshot(), engineSnapshot = await f.engine.persistentSnapshot()
        #expect(snapshot.records.isEmpty); #expect(engineSnapshot.isEmpty)
        let restarted = try Fixture(runNumber: 901, snapshot: snapshot, engineFixtures: engineSnapshot)
        #expect(await restarted.engine.privateCount() == 0)
        #expect(await restarted.core.summary(scope) == nil)
    }
}
