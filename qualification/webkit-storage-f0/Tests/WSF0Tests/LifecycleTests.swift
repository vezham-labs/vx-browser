import Testing
import BrowserDomain
import BrowserCore
import WSF0Fakes

@Suite("F0.4 lifecycle and races", .serialized)
struct LifecycleTests {
    @Test("F0-LIF-001 illegal activation and removal transitions are deterministic")
    func illegal() async throws {
        let f = try Fixture(); let c = await f.prepared()
        #expect(await f.core.remove(fixtureID(1), context: c, operation: fixtureID(1002)) == .failure(.illegalTransition))
        #expect(await f.core.retire(c.scope, context: c, operation: fixtureID(1003)) == .failure(.illegalTransition))
        #expect(await f.calls.count(.remove) == 0)
    }
    @Test("F0-LIF-002 references prevent quiescence and retirement")
    func references() async throws {
        let f = try Fixture(); let c = await f.active()
        #expect(await f.core.quiesce(c.scope, context: c, operation: fixtureID(1003)) == .failure(.outstandingReferences))
        #expect(await f.core.retire(c.scope, context: c, operation: fixtureID(1004)) == .failure(.illegalTransition))
        #expect(await f.calls.count(.retire) == 0)
        _ = await f.core.closeView(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1005))
        #expect(await f.core.quiesce(c.scope, context: c, operation: fixtureID(1006)) == .success(.quiesced))
        #expect(await f.core.retire(c.scope, context: c, operation: fixtureID(1007)) == .success(.retired))
    }
    @Test("F0-LIF-003 quiescence timeout is not reported as success")
    func timeout() async throws {
        let f = try Fixture(); let c = await f.prepared(); await f.faults.enqueue(.timeout, at: .quiesce)
        #expect(await f.core.quiesce(c.scope, context: c, operation: fixtureID(1002)) == .failure(.quiescenceTimeout))
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
    }
    @Test("F0-LIF-004 one pending lifecycle operation excludes concurrent requests")
    func concurrent() async throws {
        let f = try Fixture(); let c = await f.prepared(); await f.gate.arm(.construct)
        let pending = Task { await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1002)) }
        await f.gate.waitForArrival(.construct)
        #expect(await f.core.activate(c.scope, view: fixtureID(201), context: c, operation: fixtureID(1003)) == .failure(.busy))
        #expect(await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1002)) == .failure(.busy))
        await f.gate.release(.construct)
        #expect(await pending.value == .success(.activated(fixtureID(200))))
        #expect(await f.views.liveCount() == 1)
    }
    @Test("F0-LIF-005 quarantine fences a late constructor and cleans its resources")
    func lateCompletion() async throws {
        let f = try Fixture(); let c = await f.prepared(); await f.gate.arm(.construct)
        let pending = Task { await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1002)) }
        await f.gate.waitForArrival(.construct)
        #expect(await f.core.quarantine(c.scope, reason: .observationUnknown, context: c, operation: fixtureID(1003)) == .quarantined(.observationUnknown))
        await f.gate.release(.construct)
        #expect(await pending.value == .failure(.staleCompletion))
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
        #expect(await f.resources.inventory(c.scope).isEmpty)
    }
    @Test("F0-LIF-006 authority revoked during activation cannot publish success")
    func revoked() async throws {
        let f = try Fixture(); let c = await f.prepared(); await f.gate.arm(.activate)
        let pending = Task { await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1002)) }
        await f.gate.waitForArrival(.activate); await f.authority.revoke(c.caller); await f.gate.release(.activate)
        #expect(await pending.value == .failure(.staleCompletion))
        #expect(await f.resources.inventory(c.scope).isEmpty)
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
    }
    @Test("F0-LIF-007 switch requires released source and creates new destination ownership")
    func switching() async throws {
        let f = try Fixture(); let a = await f.active(); let b = await f.prepared(2, base: 1100)
        #expect(await f.core.switchScope(from: a.scope, to: b.scope, view: fixtureID(201), from: a, to: b, operation: fixtureID(1200)) == .failure(.sourceNotRetired))
        _ = await f.core.closeView(a.scope, view: fixtureID(200), context: a, operation: fixtureID(1201))
        _ = await f.core.quiesce(a.scope, context: a, operation: fixtureID(1202))
        #expect(await f.core.switchScope(from: a.scope, to: b.scope, view: fixtureID(201), from: a, to: b, operation: fixtureID(1203)) == .success(.switched(fixtureID(201))))
        #expect(await f.core.summary(a.scope)?.viewCount == 0)
        #expect(await f.core.summary(b.scope)?.viewCount == 1)
        #expect(await f.resources.inventory(a.scope).isEmpty)
    }
    @Test("F0-LIF-008 quarantine stays sticky through cleanup and never activates")
    func stickyQuarantine() async throws {
        let f = try Fixture(); let c = await f.active()
        _ = await f.core.quarantine(c.scope, reason: .reconciliationMismatch, context: c, operation: fixtureID(1100))
        _ = await f.core.closeView(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1101))
        #expect(await f.core.quiesce(c.scope, context: c, operation: fixtureID(1102)) == .success(.quiesced))
        #expect(await f.core.retire(c.scope, context: c, operation: fixtureID(1103)) == .success(.retired))
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
        #expect(await f.core.activate(c.scope, view: fixtureID(201), context: c, operation: fixtureID(1104)) == .failure(.quarantined))
    }
    @Test("F0-LIF-009 explicit fail fences access and retains failure classification")
    func explicitFailure() async throws {
        let f = try Fixture(); let c = await f.prepared()
        #expect(await f.core.fail(c.scope, reason: .providerUnavailable, context: c, operation: fixtureID(1100)) == .failure(.providerUnavailable))
        #expect(await f.core.summary(c.scope)?.state == .failed)
        #expect(await f.core.activate(c.scope, view: fixtureID(201), context: c, operation: fixtureID(1101)) == .failure(.quarantined))
    }
    @Test("F0-LIF-010 retirement provider failure does not destroy the fake persistent store")
    func retirementFailure() async throws {
        let f = try Fixture(); let c = await f.prepared(); _ = await f.core.quiesce(c.scope, context: c, operation: fixtureID(1002))
        await f.faults.enqueue(.retirementFailure, at: .retire)
        #expect(await f.core.retire(c.scope, context: c, operation: fixtureID(1003)) == .failure(.retirementFailed))
        #expect(await f.engine.assignment(for: c.scope) != nil)
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
    }
    @Test("F0-LIF-011 source reactivation during switch rejects destination success")
    func switchSourceRace() async throws {
        let f = try Fixture(); let a = await f.active(); let b = await f.prepared(2, base: 1100)
        _ = await f.core.closeView(a.scope, view: fixtureID(200), context: a, operation: fixtureID(1200))
        _ = await f.core.quiesce(a.scope, context: a, operation: fixtureID(1201))
        await f.gate.arm(.activate)
        let switching = Task { await f.core.switchScope(from: a.scope, to: b.scope, view: fixtureID(201), from: a, to: b, operation: fixtureID(1202)) }
        await f.gate.waitForArrival(.activate)
        #expect(await f.core.activate(a.scope, view: fixtureID(202), context: a, operation: fixtureID(1203)) == .success(.activated(fixtureID(202))))
        await f.gate.release(.activate)
        #expect(await switching.value == .failure(.sourceNotRetired))
        #expect(await f.resources.inventory(b.scope).isEmpty)
        #expect(await f.core.summary(a.scope)?.state == .active)
    }
    @Test("F0-LIF-012 quiescence fences subsequent fake resource acquisition")
    func admissionFence() async throws {
        let f = try Fixture(); let c = await f.prepared()
        _ = await f.core.quiesce(c.scope, context: c, operation: fixtureID(1100))
        let resource = ResourceReference(id: fixtureID(700), kind: .pendingOperation)
        #expect(await f.resources.add(resource, scope: c.scope) == false)
        #expect(await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1101)) == .success(.activated(fixtureID(200))))
        #expect(await f.resources.add(resource, scope: c.scope))
    }

}
