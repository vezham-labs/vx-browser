import Foundation
import Testing
import BrowserDomain

private func id<T>(_ n: Int) -> ID<T> { try! ID(String(format: "00000000-0000-4000-8000-%012llx", n)) }
private func descriptor() throws -> StorageDescriptor {
    try StorageDescriptor(namespace: id(1), profile: id(2), store: id(3), operation: id(4), timestamp: 1)
}
@Test("F1-MOD-001 persistent descriptor roundtrip") func roundtrip() throws {
    let d = try descriptor(); #expect(try StorageDescriptor.decodePersistent(d.persistentBytes()) == d)
}
@Test("F1-MOD-002 missing corrupt old future adapter and platform versions reject",
      arguments: ["missing", "corrupt", "old", "future", "adapter", "platform", "zero", "equal", "generation", "time"])
func invalid(_ vector: String) throws {
    var object = try JSONSerialization.jsonObject(with: descriptor().persistentBytes()) as! [String: Any]
    switch vector {
    case "missing": object.removeValue(forKey: "schemaVersion")
    case "corrupt": object["phase"] = "invented"
    case "old": object["schemaVersion"] = 0
    case "future": object["schemaVersion"] = 2
    case "adapter": object["adapterVersion"] = 2
    case "platform": object["minimumPlatformMajor"] = 27
    case "zero": object["store"] = "00000000-0000-0000-0000-000000000000"
    case "equal": object["store"] = object["profile"]
    case "generation": object["generation"] = 0
    default: object["updatedAt"] = 0
    }
    let data = try JSONSerialization.data(withJSONObject: object)
    #expect(throws: (any Error).self) { try StorageDescriptor.decodePersistent(data) }
}
@Test("F1-MOD-003 private encoding forbidden") func privateEncoding() throws {
    let d = try StorageDescriptor(namespace: id(1), session: id(8), operation: id(4), timestamp: 1)
    #expect(throws: FailureCode.privatePersistenceForbidden) { try d.persistentBytes() }
    #expect(throws: (any Error).self) { try JSONEncoder().encode(d) }
}
@Test("F1-MOD-004 all creation publication retirement transitions and replay") func transitions() throws {
    var d = try descriptor()
    for p in StorageDescriptor.Phase.allCases where p != .intent && p != .quarantined {
        try d.advance(to: p, operation: id(4), timestamp: 2)
        let before = d; try d.advance(to: p, operation: id(4), timestamp: 2); #expect(d == before)
    }
    #expect(d.phase == .removed)
    #expect(throws: FailureCode.illegalTransition) { try d.advance(to: .published, operation: id(4), timestamp: 3) }
}
@Test("F1-MOD-005 every interrupted transition quarantines without publication", arguments: Array(StorageDescriptor.Phase.allCases.dropLast()))
func cutpoints(_ stop: StorageDescriptor.Phase) throws {
    var d = try descriptor()
    for p in StorageDescriptor.Phase.allCases.dropFirst() where p != .quarantined {
        if d.phase == stop { break }; try d.advance(to: p, operation: id(4), timestamp: 2)
    }
    let plan = try StorageReconciliation(desired: .available, descriptor: d, observed: .unknown)
    #expect(plan.action == .quarantine && plan.final == .unknown)
    if stop != .removed {
        try d.advance(to: .quarantined, operation: id(4), timestamp: 3)
        #expect(throws: FailureCode.illegalTransition) { try d.advance(to: .published, operation: id(4), timestamp: 4) }
    }
}
@Test("F1-MOD-006 no premature publish navigation or foreign replay") func illegal() throws {
    var d = try descriptor()
    for phase in [StorageDescriptor.Phase.configured, .constructed, .published, .navigationAuthorized] {
        #expect(throws: FailureCode.illegalTransition) { try d.advance(to: phase, operation: id(4), timestamp: 2) }
    }
    #expect(throws: FailureCode.operationConflict) { try d.advance(to: .resolved, operation: id(7), timestamp: 2) }
}
@Test("F1-MOD-007 stable present is reusable absent conflicting and unknown fence") func reconciliation() throws {
    var d = try descriptor()
    for p in [StorageDescriptor.Phase.resolved, .registered, .configured, .constructed, .published, .navigationAuthorized] {
        try d.advance(to: p, operation: id(4), timestamp: 2)
    }
    #expect(try StorageReconciliation(desired: .available, descriptor: d, observed: .present).action == .resolveExisting)
    for obs in [StorageReconciliation.Observed.absent, .unknown, .conflicting] {
        let p = try StorageReconciliation(desired: .available, descriptor: d, observed: obs)
        #expect(p.action == .quarantine)
        #expect(try StorageReconciliation(desired: .available, descriptor: d, observed: obs) == p)
    }
}
@Test("F1-MOD-008 invalid bounds and mixed private persistent reject") func bounds() throws {
    #expect(throws: (any Error).self) { try StorageDescriptor(namespace: id(1), profile: id(2), store: id(3), session: id(5), operation: id(4), timestamp: 1) }
    #expect(throws: (any Error).self) { try StorageDescriptor.decodePersistent(Data(repeating: 0, count: 8193)) }
    #expect(throws: (any Error).self) { try StorageDescriptor.decodePersistent(Data()) }
}
