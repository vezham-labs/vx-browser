import Testing
import BrowserDomain
import BrowserCore
import WSF0Fakes

@Suite("F0.3 construction", .serialized)
struct ConstructionTests {
    @Test("F0-CON-001 resolution and assignment precede construction and activation")
    func order() async throws {
        let f = try Fixture(); _ = await f.active()
        let calls = await f.calls.snapshot()
        #expect(calls.firstIndex(of: .observe)! < calls.firstIndex(of: .assignment)!)
        #expect(calls.firstIndex(of: .createPersistent)! < calls.firstIndex(of: .construction)!)
        #expect(calls.firstIndex(of: .assignment)! < calls.firstIndex(of: .construction)!)
        #expect(calls.firstIndex(of: .construction)! < calls.firstIndex(of: .activation)!)
    }
    @Test("F0-CON-002 missing assignment and default resolution fail closed")
    func noDefault() async throws {
        let f = try Fixture(); let b = f.binding(), c = await f.context(.persistent(b.profile))
        #expect(ConstructionPolicy.validate(nil, scope: c.scope, binding: b) == .missingAssignment)
        #expect(ConstructionPolicy.validate(.defaultStore, scope: c.scope, binding: b) == .defaultStoreForbidden)
        _ = await f.core.register(b, context: c, operation: fixtureID(1000))
        #expect(await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1001)) == .failure(.illegalTransition))
        await f.faults.enqueue(.defaultFallback, at: .createPersistent)
        #expect(await f.core.resolve(c.scope, context: c, operation: fixtureID(1002)) == .failure(.defaultStoreForbidden))
        #expect(await f.calls.count(.construction) == 0)
    }
    @Test("F0-CON-003 failed provider resolution cannot construct")
    func providerUnavailable() async throws {
        let f = try Fixture(); let c = await f.context(.persistent(fixtureID(1)))
        _ = await f.core.register(f.binding(), context: c, operation: fixtureID(1000))
        await f.faults.enqueue(.unavailable, at: .observe)
        #expect(await f.core.resolve(c.scope, context: c, operation: fixtureID(1001)) == .failure(.providerUnavailable))
        #expect(await f.calls.count(.construction) == 0)
    }
    @Test("F0-CON-004 wrong identity and conflict are rejected before constructor")
    func wrongIdentity() async throws {
        for fault in [FakeFault.invalidIdentity, .duplicateIdentity, .foreignIdentity(.persistent(profile: fixtureID(2), store: fixtureID(102), namespace: fixtureID(800), generation: 1))] {
            let f = try Fixture(); let c = await f.context(.persistent(fixtureID(1)))
            _ = await f.core.register(f.binding(), context: c, operation: fixtureID(1000))
            await f.faults.enqueue(fault, at: .createPersistent)
            let result = await f.core.resolve(c.scope, context: c, operation: fixtureID(1001))
            #expect(result != .success(.resolved)); #expect(await f.calls.count(.construction) == 0)
        }
    }
    @Test("F0-CON-005 construction failure is explicit and has no ghost view")
    func constructFailure() async throws {
        let f = try Fixture(); let c = await f.prepared(); await f.faults.enqueue(.constructionFailure, at: .construct)
        #expect(await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1002)) == .failure(.constructionFailed))
        #expect(await f.resources.inventory(c.scope).isEmpty)
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
    }
    @Test("F0-CON-006 activation failure retires the constructed fake view")
    func activationFailure() async throws {
        let f = try Fixture(); let c = await f.prepared(); await f.faults.enqueue(.activationFailure, at: .activate)
        #expect(await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1002)) == .failure(.activationFailed))
        #expect(await f.resources.inventory(c.scope).isEmpty); #expect(await f.views.liveCount() == 0)
    }
    @Test("F0-CON-007 operation replay does not construct twice; payload mismatch fails")
    func replay() async throws {
        let f = try Fixture(); let c = await f.active()
        #expect(await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1002)) == .success(.activated(fixtureID(200))))
        #expect(await f.core.activate(c.scope, view: fixtureID(201), context: c, operation: fixtureID(1002)) == .failure(.operationConflict))
        #expect(await f.calls.count(.construction) == 1)
    }
    @Test("F0-CON-008 private-to-persistent and persistent-to-private assignments are invalid")
    func scopeTypes() throws {
        let b = try Fixture().binding()
        let p = Scope.privateSession(fixtureID(10))
        #expect(ConstructionPolicy.validate(.assigned(.persistent(profile: b.profile, store: b.store, namespace: b.namespace, generation: 1)), scope: p, binding: nil) == .invalidStoreIdentity)
        #expect(ConstructionPolicy.validate(.assigned(.ephemeral(session: fixtureID(10), store: fixtureID(20), generation: 1)), scope: .persistent(b.profile), binding: b) == .invalidStoreIdentity)
    }
    @Test("F0-CON-009 duplicate view identity cannot cross profiles")
    func duplicateView() async throws {
        let f = try Fixture(); _ = await f.active(); let b = await f.prepared(2, base: 1100)
        #expect(await f.core.activate(b.scope, view: fixtureID(200), context: b, operation: fixtureID(1102)) == .failure(.duplicateView))
        #expect(await f.views.liveCount() == 1)
    }
}
