import Testing
import BrowserDomain
import BrowserCore
import BrowserPersistence
import WSF0Fakes

@Suite("F0.6 recovery and restart", .serialized)
struct RecoveryTests {
    @Test("F0-REC-001 fresh coordinator reconciles established mapping without recreation")
    func availableRestart() async throws {
        let f = try Fixture(); let original = await f.active()
        let snapshot = await f.core.restartSnapshot(), raw = await f.rawCatalog(), engine = await f.engine.persistentSnapshot()
        let restarted = try Fixture(runNumber: 901, raw: raw, snapshot: snapshot, engineFixtures: engine)
        let c = await restarted.context(original.scope)
        #expect(await restarted.core.reconcile(fixtureID(1), context: c, operation: fixtureID(2000)) == .success(.reconciled))
        #expect(await restarted.calls.count(.createPersistent) == 0)
        #expect(await restarted.calls.count(.construction) == 0)
        #expect(await restarted.core.summary(c.scope)?.state == .resolved)
    }
    @Test("F0-REC-002 missing established store is quarantined and never recreated")
    func missingStore() async throws {
        let f = try Fixture(); let a = await f.prepared()
        let restarted = try Fixture(runNumber: 901, raw: await f.rawCatalog(), snapshot: await f.core.restartSnapshot())
        let c = await restarted.context(a.scope)
        #expect(await restarted.core.reconcile(fixtureID(1), context: c, operation: fixtureID(2000)) == .failure(.storeMissing))
        #expect(await restarted.core.summary(c.scope)?.state == .quarantined)
        #expect(await restarted.calls.count(.createPersistent) == 0)
    }
    @Test("F0-REC-003 unavailable conflicting and invalid provider observations fail closed")
    func observations() async throws {
        for fault in [FakeFault.unavailable, .conflicting, .invalidIdentity, .foreignIdentity(.persistent(profile: fixtureID(2), store: fixtureID(102), namespace: fixtureID(800), generation: 1))] {
            let f = try Fixture(); let a = await f.prepared()
            let restarted = try Fixture(runNumber: 901, raw: await f.rawCatalog(), snapshot: await f.core.restartSnapshot(), engineFixtures: await f.engine.persistentSnapshot())
            let c = await restarted.context(a.scope); await restarted.faults.enqueue(fault, at: .observe)
            #expect(await restarted.core.reconcile(fixtureID(1), context: c, operation: fixtureID(2000)) != .success(.reconciled))
            #expect(await restarted.core.summary(c.scope)?.state == .quarantined)
            #expect(await restarted.calls.count(.createPersistent) == 0)
        }
    }
    @Test("F0-REC-004 interrupted removal stays unknown after simulated restart")
    func interruptedRemoval() async throws {
        let f = try Fixture(); let a = await f.retired(); await f.gate.arm(.remove)
        let pending = Task { await f.core.remove(fixtureID(1), context: a, operation: fixtureID(1100)) }
        await f.gate.waitForArrival(.remove)
        let raw = await f.rawCatalog(), snapshot = await f.core.restartSnapshot(), stores = await f.engine.persistentSnapshot()
        #expect(snapshot.records.contains { if case .pending(.remove) = $0.phase { return true }; return false })
        await f.gate.release(.remove); _ = await pending.value
        let restarted = try Fixture(runNumber: 901, raw: raw, snapshot: snapshot, engineFixtures: stores)
        let c = await restarted.context(a.scope)
        #expect(await restarted.core.reconcile(fixtureID(1), context: c, operation: fixtureID(2000)) == .quarantined(.interruptedOperation))
        #expect(await restarted.calls.count(.remove) == 0)
        #expect(await restarted.calls.count(.createPersistent) == 0)
        #expect(await restarted.core.activate(c.scope, view: fixtureID(201), context: c, operation: fixtureID(2001)) == .failure(.quarantined))
    }
    @Test("F0-REC-005 unknown removal with absent provider data cannot become removed success")
    func unknownAbsent() async throws {
        let f = try Fixture(); let a = await f.retired(); await f.faults.enqueue(.unknownDeletionAfterEffect, at: .remove)
        _ = await f.core.remove(fixtureID(1), context: a, operation: fixtureID(1100))
        let restarted = try Fixture(runNumber: 901, raw: await f.rawCatalog(), snapshot: await f.core.restartSnapshot(), engineFixtures: await f.engine.persistentSnapshot())
        let c = await restarted.context(a.scope)
        #expect(await restarted.core.reconcile(fixtureID(1), context: c, operation: fixtureID(2000)) == .quarantined(.interruptedOperation))
        #expect(await restarted.core.summary(c.scope)?.state == .quarantined)
        #expect(await restarted.calls.count(.createPersistent) == 0)
    }
    @Test("F0-REC-006 corrupt metadata and mismatched store identity quarantine")
    func corruptMetadata() async throws {
        let f = try Fixture(); let a = await f.prepared(); let raw = await f.rawCatalog(), fixtures = await f.engine.persistentSnapshot()
        let original = await f.core.restartSnapshot()
        let bad = RestartSnapshot(version: 99, previousRun: f.run, records: original.records)
        let restarted = try Fixture(runNumber: 901, raw: raw, snapshot: bad, engineFixtures: fixtures)
        let c = await restarted.context(a.scope)
        #expect(await restarted.core.reconcile(fixtureID(1), context: c, operation: fixtureID(2000)) == .failure(.quarantinePersistenceFailed))
        #expect(await restarted.core.summary(c.scope)?.failure == .corruptRecovery)
        let r = RecoveryRecord(profile: fixtureID(1), store: fixtureID(199), namespace: fixtureID(800), generation: 1,
                               phase: .stable(.accessStarted), operation: fixtureID(1001))
        let conflict = try Fixture(runNumber: 902, raw: raw, snapshot: RestartSnapshot(previousRun: f.run, records: [r]), engineFixtures: fixtures)
        let cc = await conflict.context(a.scope)
        #expect(await conflict.core.reconcile(fixtureID(1), context: cc, operation: fixtureID(2000)) == .failure(.quarantinePersistenceFailed))
        #expect(await conflict.core.summary(cc.scope)?.failure == .reconciliationMismatch)
    }
    @Test("F0-REC-007 duplicate recovery identities and same-run snapshots reject")
    func duplicateMetadata() async throws {
        let f = try Fixture(); _ = await f.prepared(); let snapshot = await f.core.restartSnapshot()
        let duplicate = RestartSnapshot(previousRun: f.run, records: snapshot.records + snapshot.records)
        let j = InMemoryRecoveryJournal(namespace: f.namespace, snapshot: duplicate, newRun: fixtureID(901))
        #expect(await j.read(fixtureID(1)) == .corrupt)
        let sameRun = InMemoryRecoveryJournal(namespace: f.namespace, snapshot: snapshot, newRun: f.run)
        #expect(await sameRun.read(fixtureID(1)) == .corrupt)
    }
    @Test("F0-REC-008 quarantine write failure is explicit and restart fails closed")
    func quarantineFailure() async throws {
        let f = try Fixture(); let a = await f.prepared(); await f.journal.failQuarantineWrites()
        #expect(await f.core.quarantine(a.scope, reason: .observationUnknown, context: a, operation: fixtureID(1100)) == .failure(.quarantinePersistenceFailed))
        #expect(await f.core.summary(a.scope)?.state == .quarantined)
        #expect(await f.core.restartSnapshot().version == 0)
        let restarted = try Fixture(runNumber: 901, raw: await f.rawCatalog(), snapshot: await f.core.restartSnapshot(), engineFixtures: await f.engine.persistentSnapshot())
        let c = await restarted.context(a.scope)
        #expect(await restarted.core.reconcile(fixtureID(1), context: c, operation: fixtureID(2000)) == .failure(.quarantinePersistenceFailed))
        #expect(await restarted.core.summary(c.scope)?.failure == .corruptRecovery)
    }
    @Test("F0-REC-009 write-ahead failure denies provider operation")
    func journalAdmissionFailure() async throws {
        let f = try Fixture(); let c = await f.prepared(); await f.journal.failNextWrite()
        #expect(await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1100)) == .failure(.journalUnavailable))
        #expect(await f.calls.count(.construction) == 0)
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
    }
    @Test("F0-REC-010 missing catalog and orphan provider never auto-adopt")
    func orphan() async throws {
        let seed = try Fixture(); _ = await seed.prepared()
        let f = try Fixture(engineFixtures: await seed.engine.persistentSnapshot())
        let c = await f.context(.persistent(fixtureID(1)))
        #expect(await f.core.reconcile(fixtureID(1), context: c, operation: fixtureID(2000)) == .quarantined(.missingCatalog))
        #expect(await f.calls.snapshot().isEmpty)
        #expect(await f.catalog.enumerate().bindings.isEmpty)
    }
    @Test("F0-REC-011 recovery generation advances and never restores view authority")
    func generation() async throws {
        let f = try Fixture(); let a = await f.retired(); let before = await f.core.summary(a.scope)
        let restarted = try Fixture(runNumber: 901, raw: await f.rawCatalog(), snapshot: await f.core.restartSnapshot(), engineFixtures: await f.engine.persistentSnapshot())
        let c = await restarted.context(a.scope)
        #expect(await restarted.core.reconcile(fixtureID(1), context: c, operation: fixtureID(2000)) == .success(.reconciled))
        #expect(await restarted.core.summary(c.scope)!.generation > before!.generation)
        #expect(await restarted.core.summary(c.scope)?.viewCount == 0)
        #expect(await restarted.calls.count(.construction) == 0)
        #expect(await restarted.core.activate(c.scope, view: fixtureID(201), context: a, operation: fixtureID(2001)) == .failure(.unauthorized))
    }
    @Test("F0-REC-012 quarantine does not vanish when a stable-looking snapshot is offered")
    func stickyRuntimeQuarantine() async throws {
        let f = try Fixture(); let a = await f.prepared()
        _ = await f.core.quarantine(a.scope, reason: .observationUnknown, context: a, operation: fixtureID(1100))
        #expect(await f.core.reconcile(fixtureID(1), context: a, operation: fixtureID(1101)) == .failure(.quarantined))
        #expect(await f.calls.count(.createPersistent) == 1)
    }
    @Test("F0-REC-013 stale journal generations cannot overwrite a quarantine record")
    func journalFence() async throws {
        let f = try Fixture(); let b = f.binding()
        let q = RecoveryRecord(profile: b.profile, store: b.store, namespace: b.namespace, generation: 4,
                               phase: .quarantined(.interruptedOperation), operation: fixtureID(1000))
        #expect(await f.journal.write(q) == .committed)
        let old = RecoveryRecord(profile: b.profile, store: b.store, namespace: b.namespace, generation: 3,
                                 phase: .stable(.active), operation: fixtureID(1001))
        #expect(await f.journal.write(old) == .failed(.staleRevision))
        let same = RecoveryRecord(profile: b.profile, store: b.store, namespace: b.namespace, generation: 4,
                                  phase: .stable(.active), operation: fixtureID(1002))
        #expect(await f.journal.write(same) == .failed(.quarantined))
        #expect(await f.journal.read(b.profile) == .record(q))
    }
    @Test("F0-REC-014 terminal journal write failure cannot publish activation success")
    func terminalReceiptFailure() async throws {
        let f = try Fixture(); let c = await f.prepared(); await f.gate.arm(.activate)
        let pending = Task { await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1100)) }
        await f.gate.waitForArrival(.activate); await f.journal.failNextWrite(); await f.gate.release(.activate)
        #expect(await pending.value == .unknown(.activate))
        #expect(await f.core.summary(c.scope)?.state == .quarantined)
        #expect(await f.core.restartSnapshot().version == 0)
    }

}
