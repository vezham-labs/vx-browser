import BrowserDomain
import BrowserPorts

public enum FaultPoint: String, Hashable, Sendable, CaseIterable {
    case observe, createPersistent, createPrivate, construct, activate, quiesce, retire, clear, remove, close
}
public enum FakeFault: Equatable, Sendable {
    case unavailable, missing, invalidIdentity, duplicateIdentity, defaultFallback, conflicting
    case constructionFailure, activationFailure, timeout, partialDeletion, unknownDeletion, unknownDeletionAfterEffect
    case removalFailure, retirementFailure, foreignIdentity(StoreIdentity)
}
public actor FaultScript {
    private var values: [FaultPoint: [FakeFault]] = [:]
    public init() {}
    @discardableResult public func enqueue(_ fault: FakeFault, at point: FaultPoint) -> Bool {
        guard (values[point]?.count ?? 0) < 32 else { return false }
        values[point, default: []].append(fault); return true
    }
    public func consume(_ point: FaultPoint) -> FakeFault? {
        guard var queue = values[point], !queue.isEmpty else { return nil }
        let fault = queue.removeFirst(); values[point] = queue; return fault
    }
}
public enum FakeCall: String, Sendable { case observe, createPersistent, createPrivate, assignment, construction, activation, quiesce, retire, clear, remove, close }
public actor CallRecorder {
    private var calls: [FakeCall] = []
    private let limit: Int
    public private(set) var overflowed = false
    public init(limit: Int = 4096) { self.limit = max(1, min(limit, 4096)) }
    @discardableResult public func record(_ call: FakeCall) -> Bool {
        guard calls.count < limit else { overflowed = true; return false }
        calls.append(call); return true
    }
    public func snapshot() -> [FakeCall] { calls }
    public func count(_ call: FakeCall) -> Int { calls.filter { $0 == call }.count }
}
/// Deterministic single-shot rendezvous. Tests control arrival and release, without sleeps or polling.
public actor ControlledGate {
    private var armed: Set<FaultPoint> = []
    private var arrivals: Set<FaultPoint> = []
    private var waiters: [FaultPoint: CheckedContinuation<Void, Never>] = [:]
    private var observers: [FaultPoint: [CheckedContinuation<Void, Never>]] = [:]
    public init() {}
    public func arm(_ point: FaultPoint) { armed.insert(point); arrivals.remove(point) }
    public func pause(_ point: FaultPoint) async {
        guard armed.remove(point) != nil else { return }
        arrivals.insert(point)
        for observer in observers.removeValue(forKey: point) ?? [] { observer.resume() }
        await withCheckedContinuation { continuation in waiters[point] = continuation }
    }
    public func waitForArrival(_ point: FaultPoint) async {
        if arrivals.contains(point) { return }
        await withCheckedContinuation { continuation in observers[point, default: []].append(continuation) }
    }
    public func release(_ point: FaultPoint) { waiters.removeValue(forKey: point)?.resume() }
}
public actor FakeHostAuthority: HostAuthorityPort {
    private var grants: [CallerID: CallerContext] = [:]
    private var epochs: [CallerID: UInt64] = [:]
    public init() {}
    public func grant(_ caller: CallerID, scope: Scope, run: RunID) -> CallerContext {
        let epoch = (epochs[caller] ?? 0) + 1; epochs[caller] = epoch
        let context = CallerContext(caller: caller, scope: scope, run: run, authorityEpoch: epoch)
        grants[caller] = context; return context
    }
    public func revoke(_ caller: CallerID) { grants[caller] = nil }
    public func permits(_ context: CallerContext, scope: Scope, run: RunID) -> Bool {
        grants[context.caller] == context && context.scope == scope && context.run == run
    }
}
public actor FakeResources: ResourcePort {
    private var values: [Scope: Set<ResourceReference>] = [:]
    private var fenced: Set<Scope> = []
    public init() {}
    @discardableResult public func add(_ reference: ResourceReference, scope: Scope) -> Bool {
        guard !fenced.contains(scope), (values[scope]?.count ?? 0) < 128 else { return false }
        return values[scope, default: []].insert(reference).inserted
    }
    // Deliberate adversarial fixture hook, never used by construction/provider admission.
    public func injectUncoordinatedReference(_ reference: ResourceReference, scope: Scope) { values[scope, default: []].insert(reference) }
    public func preventAcquisition(in scope: Scope) { fenced.insert(scope) }
    public func allowAcquisition(in scope: Scope) { fenced.remove(scope) }
    public func release(_ reference: ResourceReference, scope: Scope) { values[scope]?.remove(reference) }
    public func inventory(_ scope: Scope) -> Set<ResourceReference> { values[scope] ?? [] }
}
