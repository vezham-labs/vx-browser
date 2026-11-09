public enum CatalogStatus: String, Codable, Sendable { case registered, accessStarted, active, quiescent, retired, deleting, deleted, quarantined }
public enum BindingOrigin: String, Codable, Sendable { case fresh, established }
public struct ProfileBinding: Equatable, Sendable {
    public let profile: ProfileID
    public let store: StoreID
    public let namespace: NamespaceID
    public let revision: UInt64
    public let resourceGeneration: UInt64
    public let status: CatalogStatus
    public let origin: BindingOrigin
    public init(profile: ProfileID, store: StoreID, namespace: NamespaceID, revision: UInt64 = 1,
                resourceGeneration: UInt64 = 1, status: CatalogStatus = .registered, origin: BindingOrigin = .fresh) throws(FailureCode) {
        guard profile.rawValue != store.rawValue else { throw FailureCode.invalidIdentity }
        guard revision > 0, revision < UInt64.max, resourceGeneration > 0 else { throw FailureCode.invalidRevision }
        self.profile = profile; self.store = store; self.namespace = namespace; self.revision = revision
        self.resourceGeneration = resourceGeneration; self.status = status; self.origin = origin
    }
    public func advancing(to status: CatalogStatus) throws(FailureCode) -> Self {
        try Self(profile: profile, store: store, namespace: namespace, revision: revision + 1,
                 resourceGeneration: resourceGeneration, status: status, origin: origin)
    }
}
public struct RawBinding: Sendable {
    public let profile: String
    public let store: String
    public let namespace: String
    public let revision: UInt64
    public let resourceGeneration: UInt64
    public let status: CatalogStatus
    public let origin: BindingOrigin
    public init(profile: String, store: String, namespace: String, revision: UInt64 = 1,
                resourceGeneration: UInt64 = 1, status: CatalogStatus = .registered, origin: BindingOrigin = .established) {
        self.profile = profile; self.store = store; self.namespace = namespace; self.revision = revision
        self.resourceGeneration = resourceGeneration; self.status = status; self.origin = origin
    }
}
public enum CatalogObservation: Equatable, Sendable {
    case available(ProfileBinding), missing, corrupt, conflicting, unavailable
}
public struct CatalogIssue: Equatable, Sendable {
    public let index: Int
    public let failure: FailureCode
    public init(index: Int, failure: FailureCode) { self.index = index; self.failure = failure }
}
public struct CatalogInventory: Equatable, Sendable {
    public let bindings: [ProfileBinding]
    public let issues: [CatalogIssue]
    public init(bindings: [ProfileBinding], issues: [CatalogIssue] = []) { self.bindings = bindings; self.issues = issues }
}
public enum CatalogWrite: Equatable, Sendable { case committed(ProfileBinding), failed(FailureCode) }

public enum StoreIdentity: Hashable, Sendable {
    case persistent(profile: ProfileID, store: StoreID, namespace: NamespaceID, generation: UInt64)
    case ephemeral(session: PrivateSessionID, store: EphemeralStoreID, generation: UInt64)
    public var scope: Scope {
        switch self { case .persistent(let p, _, _, _): return .persistent(p)
        case .ephemeral(let s, _, _): return .privateSession(s) }
    }
}
public enum Resolution: Equatable, Sendable {
    case assigned(StoreIdentity), missing, unknown, conflicting, unavailable, invalid, defaultStore
}
public enum WebsiteDataKind: String, CaseIterable, Hashable, Sendable {
    case cookies, localStorage, indexedDB, sessionStorage, cacheStorage, httpCache, serviceWorkers
}
public enum ProviderOutcome: Equatable, Sendable { case completed, partial, failed(FailureCode), unknown }
public enum ConstructionOutcome: Equatable, Sendable { case constructed, failed(FailureCode) }
public enum ResourceKind: String, Hashable, Sendable { case view, participant, pendingOperation }
public struct ResourceReference: Hashable, Sendable {
    public let id: ResourceID
    public let kind: ResourceKind
    public init(id: ResourceID, kind: ResourceKind) { self.id = id; self.kind = kind }
}
public enum LifecycleState: String, Hashable, Sendable {
    case registered, resolving, resolved, activating, active, quiescing, quiescent, retiring, retired
    case clearing, removing, removed, reconciling, failed, quarantined
}
public enum Action: String, Codable, Hashable, Sendable, CaseIterable {
    case register, resolve, activate, closeView, quiesce, retire, switchScope, clear, remove, reconcile, fail, quarantine
}
public enum Success: Equatable, Sendable {
    case registered, resolved, activated(ViewID), viewClosed, quiesced, retired, switched(ViewID)
    case cleared(Set<WebsiteDataKind>), removed, reconciled
}
public enum OperationResult: Equatable, Sendable {
    case success(Success), failure(FailureCode), partial(Action), unknown(Action), quarantined(FailureCode)
}
public struct ScopeSummary: Equatable, Sendable {
    public let state: LifecycleState
    public let generation: UInt64
    public let viewCount: Int
    public let pending: OperationID?
    public let failure: FailureCode?
    public init(state: LifecycleState, generation: UInt64, viewCount: Int, pending: OperationID?, failure: FailureCode?) {
        self.state = state; self.generation = generation; self.viewCount = viewCount; self.pending = pending; self.failure = failure
    }
}
public enum RecoveryPhase: Codable, Equatable, Sendable { case stable(CatalogStatus), pending(Action), quarantined(FailureCode), removed }
public struct RecoveryRecord: Codable, Equatable, Sendable {
    public let profile: ProfileID
    public let store: StoreID
    public let namespace: NamespaceID
    public let generation: UInt64
    public let phase: RecoveryPhase
    public let operation: OperationID
    public let interruptedAction: Action?
    public init(profile: ProfileID, store: StoreID, namespace: NamespaceID, generation: UInt64,
                phase: RecoveryPhase, operation: OperationID, interruptedAction: Action? = nil) {
        self.profile = profile; self.store = store; self.namespace = namespace; self.generation = generation
        self.phase = phase; self.operation = operation; self.interruptedAction = interruptedAction
    }
}
public struct RestartSnapshot: Codable, Equatable, Sendable {
    public let version: UInt16
    public let previousRun: RunID
    public let records: [RecoveryRecord]
    public init(version: UInt16 = 1, previousRun: RunID, records: [RecoveryRecord]) {
        self.version = version; self.previousRun = previousRun; self.records = records
    }
}
public enum RecoveryObservation: Equatable, Sendable { case record(RecoveryRecord), missing, corrupt, unavailable }
public enum JournalWrite: Equatable, Sendable { case committed, failed(FailureCode) }
public struct DiagnosticEvent: Equatable, Sendable {
    public let sequence: UInt64
    public let operation: OperationID
    public let action: Action
    public let scopeKind: ScopeKind
    public let classification: DiagnosticClass
    public let failure: FailureCode?
    public init(sequence: UInt64, operation: OperationID, action: Action, scopeKind: ScopeKind,
                classification: DiagnosticClass, failure: FailureCode?) {
        self.sequence = sequence; self.operation = operation; self.action = action; self.scopeKind = scopeKind
        self.classification = classification; self.failure = failure
    }
}
public enum DiagnosticClass: String, Sendable { case started, succeeded, failed, partial, unknown, quarantined, rejected, stale }
public struct DiagnosticSnapshot: Equatable, Sendable {
    public let events: [DiagnosticEvent]
    public let overflowed: Bool
    public init(events: [DiagnosticEvent], overflowed: Bool) { self.events = events; self.overflowed = overflowed }
}
