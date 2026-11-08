import BrowserDomain
import BrowserPorts

/// Qualification-only memory adapter. No filesystem, database or key service.
public actor InMemoryProfileCatalog: ProfileCatalogPort {
    private let namespace: NamespaceID
    private var values: [ProfileID: ProfileBinding] = [:]
    private var rejected: [ProfileID: FailureCode] = [:]
    private var issues: [CatalogIssue] = []
    private var nextWriteFailure: FailureCode?
    private var unavailable = false
    public init(namespace: NamespaceID, raw: [RawBinding] = []) {
        self.namespace = namespace
        var candidates: [(Int, ProfileBinding)] = []
        for (index, row) in raw.enumerated() {
            do {
                let p = try ProfileID(row.profile)
                let b = try ProfileBinding(profile: p, store: StoreID(row.store), namespace: NamespaceID(row.namespace),
                                           revision: row.revision, resourceGeneration: row.resourceGeneration, status: row.status, origin: row.origin)
                guard b.namespace == namespace else {
                    rejected[p] = .namespaceMismatch; issues.append(CatalogIssue(index: index, failure: .namespaceMismatch)); continue
                }
                candidates.append((index, b))
            } catch {
                if let p = try? ProfileID(row.profile) { rejected[p] = .corruptCatalog }
                issues.append(CatalogIssue(index: index, failure: .corruptCatalog))
            }
        }
        for (index, b) in candidates {
            let duplicate = candidates.filter { $0.1.profile == b.profile || $0.1.store == b.store }.count > 1
            if duplicate {
                rejected[b.profile] = .conflictingMapping; issues.append(CatalogIssue(index: index, failure: .conflictingMapping))
            } else if rejected[b.profile] == nil { values[b.profile] = b }
        }
    }
    public func setUnavailable(_ value: Bool) { unavailable = value }
    public func failNextWrite(_ failure: FailureCode = .catalogWriteFailed) { nextWriteFailure = failure }
    public func lookup(_ profile: ProfileID) -> CatalogObservation {
        if unavailable { return .unavailable }
        if issues.contains(where: { $0.failure == .corruptCatalog || $0.failure == .namespaceMismatch }) { return .corrupt }
        if let issue = rejected[profile] { return issue == .conflictingMapping ? .conflicting : .corrupt }
        return values[profile].map(CatalogObservation.available) ?? .missing
    }
    public func enumerate() -> CatalogInventory {
        CatalogInventory(bindings: values.values.sorted { $0.profile < $1.profile }, issues: issues.sorted { $0.index < $1.index })
    }
    public func insert(_ binding: ProfileBinding) -> CatalogWrite {
        if unavailable { return .failed(.catalogUnavailable) }
        if let failure = consumeFailure() { return .failed(failure) }
        guard issues.isEmpty else { return .failed(.corruptCatalog) }
        guard binding.namespace == namespace else { return .failed(.namespaceMismatch) }
        guard rejected[binding.profile] == nil, values[binding.profile] == nil else { return .failed(.conflictingMapping) }
        guard !values.values.contains(where: { $0.store == binding.store }) else { return .failed(.duplicateIdentity) }
        guard values.count < 128 else { return .failed(.capacityExceeded) }
        values[binding.profile] = binding
        return .committed(binding)
    }
    public func transition(_ profile: ProfileID, expectedRevision: UInt64, to status: CatalogStatus) -> CatalogWrite {
        if unavailable { return .failed(.catalogUnavailable) }
        if let failure = consumeFailure() { return .failed(failure) }
        guard let b = values[profile], rejected[profile] == nil else { return .failed(.missingCatalog) }
        guard b.revision == expectedRevision else { return .failed(.staleRevision) }
        do {
            let next = try b.advancing(to: status); values[profile] = next
            return .committed(next)
        } catch { return .failed(error) }
    }
    private func consumeFailure() -> FailureCode? { defer { nextWriteFailure = nil }; return nextWriteFailure }
}

/// A simulated write-ahead journal surviving coordinator replacement in memory only.
public actor InMemoryRecoveryJournal: RecoveryJournalPort {
    private let namespace: NamespaceID
    private var records: [ProfileID: RecoveryRecord] = [:]
    private var corrupt = false
    private var nextFailure: FailureCode?
    private var quarantineFailure = false
    private var uncertainSnapshot = false
    public init(namespace: NamespaceID, snapshot: RestartSnapshot? = nil, newRun: RunID? = nil) {
        self.namespace = namespace
        if let snapshot {
            guard let newRun, snapshot.version == 1, snapshot.previousRun != newRun, snapshot.records.count <= 128 else { corrupt = true; return }
            var stores: Set<StoreID> = []
            for record in snapshot.records {
                guard record.namespace == namespace, record.generation > 0, records[record.profile] == nil,
                      stores.insert(record.store).inserted else { corrupt = true; records = [:]; return }
                records[record.profile] = record
            }
        }
    }
    public func failNextWrite(_ failure: FailureCode = .journalUnavailable) { nextFailure = failure }
    public func failQuarantineWrites() { quarantineFailure = true }
    public func corruptMetadata() { corrupt = true }
    public func read(_ profile: ProfileID) -> RecoveryObservation {
        if corrupt { return .corrupt }
        return records[profile].map(RecoveryObservation.record) ?? .missing
    }
    public func write(_ record: RecoveryRecord) -> JournalWrite {
        if corrupt { return .failed(.corruptRecovery) }
        if let f = nextFailure { nextFailure = nil; uncertainSnapshot = true; return .failed(f) }
        if case .quarantined = record.phase, quarantineFailure { uncertainSnapshot = true; return .failed(.quarantinePersistenceFailed) }
        guard record.namespace == namespace, record.generation > 0 else { return .failed(.reconciliationMismatch) }
        if let current = records[record.profile] {
            guard current.store == record.store else { return .failed(.reconciliationMismatch) }
            guard record.generation >= current.generation else { return .failed(.staleRevision) }
            if record.generation == current.generation, case .quarantined = current.phase {
                guard case .quarantined = record.phase else { return .failed(.quarantined) }
            }
        }
        guard !records.values.contains(where: { $0.profile != record.profile && $0.store == record.store }) else {
            return .failed(.reconciliationMismatch)
        }
        guard records.count < 128 || records[record.profile] != nil else { return .failed(.capacityExceeded) }
        records[record.profile] = record
        return .committed
    }
    public func snapshot(run: RunID) -> RestartSnapshot {
        RestartSnapshot(version: (corrupt || uncertainSnapshot) ? 0 : 1, previousRun: run, records: records.values.sorted { $0.profile < $1.profile })
    }
}
