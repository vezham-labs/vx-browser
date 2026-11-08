import Testing
import BrowserDomain
import BrowserCore
import WSF0Fakes

@Suite("F0.5 deletion state machines", .serialized)
struct DeletionTests {
    @Test("F0-DEL-001 clear selected types preserves store and unselected data")
    func selectiveClear() async throws {
        let f = try Fixture(); let c = await f.prepared()
        let identity = try #require(await f.engine.assignment(for: c.scope))
        _ = await f.engine.seed(identity, kind: .cookies, text: "COOKIE")
        _ = await f.engine.seed(identity, kind: .localStorage, text: "LOCAL")
        _ = await f.core.quiesce(c.scope, context: c, operation: fixtureID(1100))
        #expect(await f.core.clear(c.scope, types: [.cookies], context: c, operation: fixtureID(1101)) == .success(.cleared([.cookies])))
        #expect(await f.engine.value(identity, kind: .cookies) == nil)
        #expect(await f.engine.value(identity, kind: .localStorage) == "LOCAL")
        #expect(await f.engine.assignment(for: c.scope) == identity)
        #expect(await f.calls.count(.remove) == 0)
        #expect(await f.catalog.enumerate().bindings.count == 1)
    }
    @Test("F0-DEL-002 clear has same-operation idempotency and payload mismatch rejection")
    func clearReplay() async throws {
        let f = try Fixture(); let c = await f.prepared(); _ = await f.core.quiesce(c.scope, context: c, operation: fixtureID(1100))
        _ = await f.core.clear(c.scope, types: [.cookies], context: c, operation: fixtureID(1101))
        #expect(await f.core.clear(c.scope, types: [.cookies], context: c, operation: fixtureID(1101)) == .success(.cleared([.cookies])))
        #expect(await f.core.clear(c.scope, types: [.localStorage], context: c, operation: fixtureID(1101)) == .failure(.operationConflict))
        #expect(await f.calls.count(.clear) == 1)
    }
    @Test("F0-DEL-003 explicit retirement required before whole-store removal")
    func retirementRequired() async throws {
        let f = try Fixture(); let c = await f.active()
        #expect(await f.core.remove(fixtureID(1), context: c, operation: fixtureID(1100)) == .failure(.illegalTransition))
        #expect(await f.calls.count(.remove) == 0)
        #expect(await f.core.summary(c.scope)?.state == .active)
    }
    @Test("F0-DEL-004 retired store removal retains a deleted catalog tombstone")
    func successfulRemoval() async throws {
        let f = try Fixture(); let c = await f.retired()
        #expect(await f.core.remove(fixtureID(1), context: c, operation: fixtureID(1100)) == .success(.removed))
        #expect(await f.engine.assignment(for: c.scope) == nil)
        #expect(await f.core.summary(c.scope)?.state == .removed)
        if case .available(let b) = await f.catalog.lookup(fixtureID(1)) { #expect(b.status == .deleted) }
        else { Issue.record("Missing deletion tombstone") }
        #expect(await f.core.remove(fixtureID(1), context: c, operation: fixtureID(1100)) == .success(.removed))
        #expect(await f.calls.count(.remove) == 1)
    }
    @Test("F0-DEL-005 resources reappearing after retirement block removal")
    func lateResource() async throws {
        let f = try Fixture(); let c = await f.retired()
        let ref = ResourceReference(id: fixtureID(700), kind: .participant)
        await f.resources.injectUncoordinatedReference(ref, scope: c.scope)
        #expect(await f.core.remove(fixtureID(1), context: c, operation: fixtureID(1100)) == .failure(.outstandingReferences))
        #expect(await f.calls.count(.remove) == 0)
        #expect(await f.engine.assignment(for: c.scope) != nil)
    }
    @Test("F0-DEL-006 partial removal remains partial and quarantined")
    func partialRemoval() async throws {
        let f = try Fixture(); let c = await f.retired(); await f.faults.enqueue(.partialDeletion, at: .remove)
        #expect(await f.core.remove(fixtureID(1), context: c, operation: fixtureID(1100)) == .partial(.remove))
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
        #expect(await f.engine.assignment(for: c.scope) != nil)
        #expect(await f.core.remove(fixtureID(1), context: c, operation: fixtureID(1101)) == .failure(.quarantined))
        #expect(await f.core.remove(fixtureID(1), context: c, operation: fixtureID(1100)) == .partial(.remove))
        #expect(await f.calls.count(.remove) == 1)
    }
    @Test("F0-DEL-007 unknown removal after effects never becomes success")
    func unknownAfterEffect() async throws {
        let f = try Fixture(); let c = await f.retired(); await f.faults.enqueue(.unknownDeletionAfterEffect, at: .remove)
        #expect(await f.core.remove(fixtureID(1), context: c, operation: fixtureID(1100)) == .unknown(.remove))
        #expect(await f.engine.assignment(for: c.scope) == nil)
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
        let snapshot = await f.core.restartSnapshot()
        #expect(snapshot.records.contains { $0.interruptedAction == .remove })
    }
    @Test("F0-DEL-008 failed removal never rolls mapping back to active")
    func failedRemoval() async throws {
        let f = try Fixture(); let c = await f.retired(); await f.faults.enqueue(.removalFailure, at: .remove)
        #expect(await f.core.remove(fixtureID(1), context: c, operation: fixtureID(1100)) == .failure(.removalFailed))
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
        if case .available(let b) = await f.catalog.lookup(fixtureID(1)) { #expect(b.status == .deleting) }
        else { Issue.record("Deleted mapping was lost") }
        #expect(await f.engine.assignment(for: c.scope) != nil)
    }
    @Test("F0-DEL-009 clear failure and partial outcomes are not successful clears")
    func clearFailures() async throws {
        for fault in [FakeFault.partialDeletion, .unknownDeletion, .unavailable] {
            let f = try Fixture(); let c = await f.prepared(); _ = await f.core.quiesce(c.scope, context: c, operation: fixtureID(1100))
            await f.faults.enqueue(fault, at: .clear)
            let result = await f.core.clear(c.scope, types: [.cookies, .localStorage], context: c, operation: fixtureID(1101))
            #expect(result != .success(.cleared([.cookies, .localStorage])))
            #expect(await f.core.summary(c.scope)?.state == .quarantined)
            #expect(await f.calls.count(.remove) == 0)
        }
    }
    @Test("F0-DEL-010 catalog commit failure after provider effect remains unknown")
    func lostCatalogCommit() async throws {
        let f = try Fixture(); let c = await f.retired(); await f.gate.arm(.remove)
        let pending = Task { await f.core.remove(fixtureID(1), context: c, operation: fixtureID(1100)) }
        await f.gate.waitForArrival(.remove); await f.catalog.failNextWrite(); await f.gate.release(.remove)
        #expect(await pending.value == .unknown(.remove))
        #expect(await f.engine.assignment(for: c.scope) == nil)
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
        #expect(await f.core.restartSnapshot().records.first?.interruptedAction == .remove)
    }
    @Test("F0-DEL-011 zero selected data types is refused without a provider call")
    func emptySelection() async throws {
        let f = try Fixture(); let c = await f.prepared()
        #expect(await f.core.clear(c.scope, types: [], context: c, operation: fixtureID(1100)) == .failure(.unsupported))
        #expect(await f.calls.count(.clear) == 0)
    }
    @Test("F0-DEL-012 successful clear of one profile leaves another profile unchanged")
    func unrelatedPreserved() async throws {
        let f = try Fixture(); let a = await f.prepared(); let b = await f.prepared(2, base: 1100)
        let ai = try #require(await f.engine.assignment(for: a.scope)); let bi = try #require(await f.engine.assignment(for: b.scope))
        _ = await f.engine.seed(ai, kind: .cookies, text: "A")
        _ = await f.engine.seed(bi, kind: .cookies, text: "B")
        _ = await f.core.quiesce(a.scope, context: a, operation: fixtureID(1200))
        _ = await f.core.clear(a.scope, types: [.cookies], context: a, operation: fixtureID(1201))
        #expect(await f.engine.value(ai, kind: .cookies) == nil)
        #expect(await f.engine.value(bi, kind: .cookies) == "B")
    }
}
