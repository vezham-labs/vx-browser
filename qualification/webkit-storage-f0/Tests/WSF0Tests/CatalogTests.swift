import Testing
import BrowserDomain
import BrowserCore
import BrowserPersistence
import WSF0Fakes

@Suite("F0.1 catalog and identity", .serialized)
struct CatalogTests {
    @Test("F0-CAT-001 validated identities are canonical and type-separated")
    func canonical() throws {
        let lower = try ProfileID("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
        let upper = try ProfileID("AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA")
        #expect(lower == upper)
        #expect(throws: FailureCode.invalidIdentity) {
            try ProfileBinding(profile: lower, store: StoreID(lower.rawValue), namespace: fixtureID(800))
        }
    }
    @Test("F0-CAT-002 stable mapping and noncreating deterministic enumeration")
    func stableEnumeration() async throws {
        let f = try Fixture(); _ = await f.prepared(2, base: 1100); _ = await f.prepared(1)
        let before = await f.calls.snapshot()
        let a = await f.catalog.enumerate(), b = await f.catalog.enumerate()
        #expect(a == b); #expect(a.bindings.map(\.profile) == [fixtureID(1), fixtureID(2)])
        #expect(await f.calls.snapshot() == before)
        #expect(a.bindings.first?.store == fixtureID(101))
    }
    @Test("F0-CAT-003 duplicate store insertion preserves original mapping")
    func duplicateStore() async throws {
        let f = try Fixture(); let c1 = await f.prepared()
        let c2 = await f.context(.persistent(fixtureID(2)), caller: 502)
        #expect(await f.core.register(f.binding(2, store: 101), context: c2, operation: fixtureID(1100)) == .failure(.duplicateIdentity))
        #expect(await f.core.summary(c1.scope)?.state == .resolved)
        #expect(await f.catalog.enumerate().bindings.count == 1)
        #expect(await f.calls.count(.createPersistent) == 1)
    }
    @Test("F0-CAT-004 malformed catalog record is explicit corruption")
    func corruptCatalog() async throws {
        let f = try Fixture(raw: [RawBinding(profile: (fixtureID(1) as ProfileID).rawValue, store: "broken", namespace: (fixtureID(800) as NamespaceID).rawValue)])
        #expect(await f.catalog.lookup(fixtureID(1)) == .corrupt)
        #expect(await f.catalog.enumerate().issues.first?.failure == .corruptCatalog)
        let c = await f.context(.persistent(fixtureID(1)))
        #expect(await f.core.reconcile(fixtureID(1), context: c, operation: fixtureID(1000)) == .quarantined(.corruptCatalog))
        #expect(await f.calls.snapshot().isEmpty)
    }
    @Test("F0-CAT-005 duplicate raw profile/store records cannot be adopted")
    func duplicateRaw() async throws {
        let raw = [RawBinding(profile: (fixtureID(1) as ProfileID).rawValue, store: (fixtureID(101) as StoreID).rawValue, namespace: (fixtureID(800) as NamespaceID).rawValue),
                   RawBinding(profile: (fixtureID(2) as ProfileID).rawValue, store: (fixtureID(101) as StoreID).rawValue, namespace: (fixtureID(800) as NamespaceID).rawValue)]
        let f = try Fixture(raw: raw)
        #expect(await f.catalog.lookup(fixtureID(1)) == .conflicting)
        #expect(await f.catalog.lookup(fixtureID(2)) == .conflicting)
        #expect(await f.catalog.enumerate().bindings.isEmpty)
    }
    @Test("F0-CAT-006 missing lookup never creates or replaces a store")
    func missingLookup() async throws {
        let f = try Fixture(); #expect(await f.catalog.lookup(fixtureID(99)) == .missing)
        #expect(await f.engine.observe(fixtureID(199)) == .missing)
        #expect(await f.calls.count(.createPersistent) == 0)
    }
    @Test("F0-CAT-007 namespace mismatch and corrupt catalog block fresh insertion")
    func namespaceConflict() async throws {
        let f = try Fixture(raw: [RawBinding(profile: (fixtureID(1) as ProfileID).rawValue, store: (fixtureID(101) as StoreID).rawValue, namespace: (fixtureID(899) as NamespaceID).rawValue)])
        #expect(await f.catalog.lookup(fixtureID(1)) == .corrupt)
        #expect(await f.catalog.insert(f.binding(2)) == .failed(.corruptCatalog))
        let bad = try ProfileBinding(profile: fixtureID(2), store: fixtureID(102), namespace: fixtureID(899))
        let clean = try Fixture(); let c = await clean.context(.persistent(bad.profile))
        #expect(await clean.core.register(bad, context: c, operation: fixtureID(1000)) == .failure(.namespaceMismatch))
    }
    @Test("F0-CAT-008 revision and capacity are enforced without overwrite")
    func revisionAndCapacity() async throws {
        let f = try Fixture(); #expect(await f.catalog.insert(f.binding()) == .committed(f.binding()))
        #expect(await f.catalog.transition(fixtureID(1), expectedRevision: 99, to: .active) == .failed(.staleRevision))
        for n in 2...128 { _ = await f.catalog.insert(f.binding(n)) }
        #expect(await f.catalog.insert(f.binding(129)) == .failed(.capacityExceeded))
        #expect(await f.catalog.enumerate().bindings.count == 128)
    }
    @Test("F0-CAT-009 catalog unavailable and failed write do not invoke engine")
    func unavailable() async throws {
        let f = try Fixture(); await f.catalog.setUnavailable(true)
        let c = await f.context(.persistent(fixtureID(1)))
        #expect(await f.core.register(f.binding(), context: c, operation: fixtureID(1000)) == .failure(.catalogUnavailable))
        #expect(await f.calls.snapshot().isEmpty)
        await f.catalog.setUnavailable(false); await f.catalog.failNextWrite()
        #expect(await f.core.register(f.binding(), context: c, operation: fixtureID(1001)) == .failure(.catalogWriteFailed))
        #expect(await f.calls.snapshot().isEmpty)
    }
    @Test("F0-CAT-010 store identity alone never authorizes cross-profile actions")
    func identifiersAreNotCapabilities() async throws {
        let f = try Fixture(); let a = await f.prepared(); let b = await f.prepared(2, base: 1100)
        #expect(await f.core.activate(b.scope, view: fixtureID(200), context: a, operation: fixtureID(1200)) == .failure(.unauthorized))
        #expect(await f.calls.count(.construction) == 0)
        #expect(await f.core.summary(b.scope)?.state == .resolved)
    }
    @Test("F0-CAT-011 malformed identity shapes never become valid IDs")
    func malformedShapes() {
        for value in ["", "../profile", "00000000000040008000000000000001", "https://secret.example/token", "00000000-0000-0000-0000-000000000000"] {
            #expect(throws: FailureCode.invalidIdentity) { try StoreID(value) }
        }
    }
    @Test("F0-CAT-012 fresh binding does not silently adopt an orphaned existing store")
    func freshOrphanCollision() async throws {
        let seed = try Fixture(); _ = await seed.prepared()
        let f = try Fixture(engineFixtures: await seed.engine.persistentSnapshot())
        let c = await f.context(.persistent(fixtureID(1)))
        #expect(await f.core.register(f.binding(), context: c, operation: fixtureID(1000)) == .success(.registered))
        #expect(await f.core.resolve(c.scope, context: c, operation: fixtureID(1001)) == .failure(.conflictingMapping))
        #expect(await f.calls.count(.createPersistent) == 0)
        #expect(await f.calls.count(.construction) == 0)
    }

}
