import BrowserDomain
import BrowserPorts

public actor FakeConstruction: ViewConstructionPort {
    private let engine: any EngineStoragePort
    private let resources: FakeResources
    private let calls: CallRecorder
    private let faults: FaultScript
    private let gate: ControlledGate
    private var views: [ViewID: (Scope, ResourceReference)] = [:]
    private var closed: Set<ViewID> = []
    public init(engine: any EngineStoragePort, resources: FakeResources, calls: CallRecorder,
                faults: FaultScript, gate: ControlledGate) {
        self.engine = engine; self.resources = resources; self.calls = calls; self.faults = faults; self.gate = gate
    }
    public func construct(_ identity: StoreIdentity, view: ViewID, generation: UInt64, operation: OperationID) async -> ConstructionOutcome {
        guard generation > 0, await engine.validates(identity), await calls.record(.assignment) else { return .failed(.invalidStoreIdentity) }
        await gate.pause(.construct)
        guard !closed.contains(view), views[view] == nil else { return .failed(.staleCompletion) }
        if await faults.consume(.construct) != nil { return .failed(.constructionFailed) }
        guard await calls.record(.construction), let id = try? ResourceID(view.rawValue) else { return .failed(.diagnosticsOverflow) }
        let reference = ResourceReference(id: id, kind: .view)
        guard await resources.add(reference, scope: identity.scope) else { return .failed(.outstandingReferences) }
        views[view] = (identity.scope, reference); return .constructed
    }
    public func close(_ view: ViewID, scope: Scope) async -> ProviderOutcome {
        guard await calls.record(.close) else { return .failed(.diagnosticsOverflow) }
        await gate.pause(.close)
        if await faults.consume(.close) != nil { return .failed(.outstandingReferences) }
        if let entry = views[view] {
            guard entry.0 == scope else { return .failed(.invalidStoreIdentity) }
            views[view] = nil; await resources.release(entry.1, scope: scope)
        }
        closed.insert(view)
        return .completed
    }
    public func liveCount() -> Int { views.count }
}
