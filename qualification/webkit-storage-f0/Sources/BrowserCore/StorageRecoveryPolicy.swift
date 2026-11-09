import BrowserDomain

public enum StorageRecoveryPolicy {
    public enum Catalog: Sendable { case authenticated, missing, corrupt, futureSchema, unavailable }
    public enum Key: Sendable { case available, missing, denied, mismatched, unavailable }
    public enum Engine: Sendable { case present, missing, uncertainRemoval, unknown }
    public enum Intent: Sendable { case stable, creation, publication, lock, unlock, clear, backup, restore, deletion }
    public enum Outcome: Equatable, Sendable { case eligibleForExplicitUnlock, preserveLocked, recoveryRequired }
    public static func evaluate(catalog: Catalog, key: Key, engine: Engine, intent: Intent,
                                recordedLocked: Bool, deletionKnowledgeComplete: Bool) -> Outcome {
        guard catalog == .authenticated, key == .available, engine == .present,
              intent == .stable, deletionKnowledgeComplete else { return .recoveryRequired }
        return recordedLocked ? .preserveLocked : .eligibleForExplicitUnlock
    }
}
