import BrowserDomain

public protocol HostAuthorityPort: Sendable {
    func permits(_ context: CallerContext, scope: Scope, run: RunID) async -> Bool
}
public protocol ProfileCatalogPort: Sendable {
    func lookup(_ profile: ProfileID) async -> CatalogObservation
    func enumerate() async -> CatalogInventory
    func insert(_ binding: ProfileBinding) async -> CatalogWrite
    func transition(_ profile: ProfileID, expectedRevision: UInt64, to status: CatalogStatus) async -> CatalogWrite
}
public protocol RecoveryJournalPort: Sendable {
    func read(_ profile: ProfileID) async -> RecoveryObservation
    func write(_ record: RecoveryRecord) async -> JournalWrite
    func snapshot(run: RunID) async -> RestartSnapshot
}
public protocol EngineStoragePort: Sendable {
    func observe(_ store: StoreID) async -> Resolution
    func createPersistent(_ binding: ProfileBinding) async -> Resolution
    func createPrivate(_ session: PrivateSessionID) async -> Resolution
    func validates(_ identity: StoreIdentity) async -> Bool
    func activate(_ identity: StoreIdentity) async -> ProviderOutcome
    func quiesce(_ scope: Scope) async -> ProviderOutcome
    func retire(_ scope: Scope) async -> ProviderOutcome
    func clear(_ identity: StoreIdentity, types: Set<WebsiteDataKind>) async -> ProviderOutcome
    func remove(_ identity: StoreIdentity) async -> ProviderOutcome
}
public protocol ResourcePort: Sendable {
    func inventory(_ scope: Scope) async -> Set<ResourceReference>
    func preventAcquisition(in scope: Scope) async
    func allowAcquisition(in scope: Scope) async
}
public protocol ViewConstructionPort: Sendable {
    func construct(_ identity: StoreIdentity, view: ViewID, generation: UInt64, operation: OperationID) async -> ConstructionOutcome
    func close(_ view: ViewID, scope: Scope) async -> ProviderOutcome
}
