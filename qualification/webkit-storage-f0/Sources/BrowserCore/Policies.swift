import BrowserDomain

public enum ConstructionPolicy {
    public static func validate(_ resolution: Resolution?, scope: Scope, binding: ProfileBinding?) -> FailureCode? {
        guard let resolution else { return .missingAssignment }
        guard case .assigned(let identity) = resolution else {
            switch resolution {
            case .defaultStore: return .defaultStoreForbidden
            case .missing: return .storeMissing
            case .unavailable: return .providerUnavailable
            case .conflicting: return .conflictingMapping
            case .unknown: return .observationUnknown
            default: return .invalidStoreIdentity
            }
        }
        guard identity.scope == scope else { return .invalidStoreIdentity }
        switch (scope, identity) {
        case (.persistent(let profile), .persistent(let p, let store, let namespace, let generation)):
            guard let binding, profile == p, binding.profile == profile, binding.store == store,
                  binding.namespace == namespace, binding.resourceGeneration == generation else { return .invalidStoreIdentity }
        case (.privateSession(let session), .ephemeral(let s, _, let generation)):
            guard session == s, binding == nil, generation > 0 else { return .privatePersistenceForbidden }
        default: return .invalidStoreIdentity
        }
        return nil
    }
}

public struct SnapshotMember: Equatable, Sendable {
    public enum Kind: String, Hashable, Sendable { case catalog, profile, engine }
    public let kind: Kind
    public let generation: UInt64
    public let privacyEpoch: UInt64
    public init(_ kind: Kind, generation: UInt64, privacyEpoch: UInt64) {
        self.kind = kind; self.generation = generation; self.privacyEpoch = privacyEpoch
    }
}
public enum PublicationDecision: Equatable, Sendable { case allowed, blocked(FailureCode), confirmationRequired }
/// A metadata-only safety gate, not an archive/export/restore implementation.
public enum PublicationPolicy {
    public static func evaluate(members: [SnapshotMember], expectedGeneration: UInt64, privacyEpoch: UInt64,
                                destination: Destination, lineage: DeletionLineage) -> PublicationDecision {
        guard members.count == 3, Set(members.map(\.kind)) == Set([.catalog, .profile, .engine]) else {
            return .blocked(.missingSnapshotMember)
        }
        guard expectedGeneration > 0, members.allSatisfy({ $0.generation == expectedGeneration && $0.privacyEpoch == privacyEpoch }) else {
            return .blocked(.inconsistentSnapshot)
        }
        guard destination == .freshStaging else { return .blocked(.destinationConflict) }
        if lineage == .unknown { return .confirmationRequired }
        return .allowed
    }
    public enum Destination: Equatable, Sendable { case freshStaging, activeProfile }
    public enum DeletionLineage: Equatable, Sendable { case knownReconciled, unknown }
}
