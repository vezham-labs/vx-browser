import Testing
import BrowserDomain
import BrowserCore
import WSF0Fakes

@Suite("F0.7 failure injection and diagnostics", .serialized)
struct DiagnosticsTests {
    @Test("F0-DIA-001 diagnostic events are bounded with reserved terminal capacity")
    func bound() async throws {
        let f = try Fixture(diagnostics: 4)
        let c = await f.context(.persistent(fixtureID(1)))
        _ = await f.core.register(f.binding(), context: c, operation: fixtureID(1000))
        _ = await f.core.resolve(c.scope, context: c, operation: fixtureID(1001))
        #expect(await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1002)) == .failure(.diagnosticsOverflow))
        let d = await f.core.diagnostics()
        #expect(d.events.count == 4); #expect(d.overflowed)
        #expect(d.events.map(\.sequence) == [1, 2, 3, 4])
        #expect(await f.calls.count(.construction) == 0)
    }
    @Test("F0-DIA-002 diagnostics have only typed classifications and opaque operations")
    func sanitized() async throws {
        let f = try Fixture(); let c = await f.prepared(); let identity = try #require(await f.engine.assignment(for: c.scope))
        _ = await f.engine.seed(identity, kind: .localStorage, text: "https://sensitive.invalid/?token=SECRET /Users/private KEY_MATERIAL")
        _ = await f.core.quarantine(c.scope, reason: .removalFailed, context: c, operation: fixtureID(1100))
        let d = await f.core.diagnostics(), text = String(describing: await f.core.diagnostics())
        for forbidden in ["https://", "SECRET", "/Users/private", "KEY_MATERIAL", identity.scope.profile!.rawValue] {
            #expect(!text.contains(forbidden))
        }
        #expect(d.events.contains { $0.failure == .removalFailed })
        #expect(d.events.last?.classification == .quarantined)
    }
    @Test("F0-DIA-003 failure scripts are FIFO deterministic and exhaust once")
    func deterministicFaults() async throws {
        let faults = FaultScript()
        #expect(await faults.enqueue(.missing, at: .observe))
        #expect(await faults.enqueue(.unavailable, at: .observe))
        #expect(await faults.consume(.observe) == .missing)
        #expect(await faults.consume(.observe) == .unavailable)
        #expect(await faults.consume(.observe) == nil)
        for _ in 0..<32 { #expect(await faults.enqueue(.timeout, at: .quiesce)) }
        #expect(await faults.enqueue(.timeout, at: .quiesce) == false)
    }
    @Test("F0-DIA-004 held close references cannot produce successful cleanup")
    func closeFailure() async throws {
        let f = try Fixture(); let c = await f.active(); await f.faults.enqueue(.unavailable, at: .close)
        #expect(await f.core.closeView(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1100)) == .failure(.outstandingReferences))
        #expect(await f.resources.inventory(c.scope).count == 1)
        #expect(await f.core.summary(c.scope)?.viewCount == 1)
    }
    @Test("F0-DIA-005 limits reject invalid coordinator configurations")
    func invalidLimits() {
        #expect(throws: FailureCode.invalidConfiguration) { try Fixture(diagnostics: 1) }
        #expect(throws: FailureCode.invalidConfiguration) { try Fixture(diagnostics: 4097) }
    }
    @Test("F0-DIA-006 in-flight events reserve space under diagnostic pressure")
    func reserveFinal() async throws {
        let f = try Fixture(diagnostics: 6); let c = await f.prepared(); await f.gate.arm(.construct)
        let pending = Task { await f.core.activate(c.scope, view: fixtureID(200), context: c, operation: fixtureID(1002)) }
        await f.gate.waitForArrival(.construct)
        #expect(await f.core.activate(c.scope, view: fixtureID(201), context: c, operation: fixtureID(1003)) == .failure(.busy))
        await f.gate.release(.construct); _ = await pending.value
        let d = await f.core.diagnostics()
        #expect(d.events.count == 6); #expect(d.overflowed)
        #expect(d.events.last?.operation == fixtureID(1002))
    }
}
