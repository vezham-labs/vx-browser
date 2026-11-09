import Foundation

public enum FailureCode: String, Codable, Error, Sendable, CaseIterable {
    case invalidIdentity, invalidConfiguration, invalidRevision, duplicateIdentity, conflictingMapping
    case missingCatalog, corruptCatalog, catalogUnavailable, catalogWriteFailed, staleRevision
    case unauthorized, staleAuthority, staleCompletion, illegalTransition, busy, operationConflict
    case capacityExceeded, diagnosticsOverflow, missingAssignment, defaultStoreForbidden
    case providerUnavailable, storeMissing, invalidStoreIdentity, observationUnknown, namespaceMismatch
    case constructionFailed, activationFailed, quiescenceTimeout, outstandingReferences, retirementFailed
    case clearFailed, removalFailed, partialDeletion, unknownDeletion, interruptedOperation
    case corruptRecovery, quarantinePersistenceFailed, journalUnavailable, reconciliationMismatch
    case quarantined, privatePersistenceForbidden, duplicateView, unsupported, sourceNotRetired
    case missingSnapshotMember, inconsistentSnapshot, destinationConflict, confirmationRequired
}

public enum ProfileTag: Sendable {}
public enum StoreTag: Sendable {}
public enum SessionTag: Sendable {}
public enum EphemeralTag: Sendable {}
public enum NamespaceTag: Sendable {}
public enum RunTag: Sendable {}
public enum CallerTag: Sendable {}
public enum OperationTag: Sendable {}
public enum ViewTag: Sendable {}
public enum ResourceTag: Sendable {}

public struct ID<Tag: Sendable>: Hashable, Sendable, Comparable {
    public let rawValue: String
    public init(_ string: String) throws(FailureCode) {
        guard let uuid = UUID(uuidString: string), uuid.uuidString.lowercased() == string.lowercased(),
              uuid.uuidString != "00000000-0000-0000-0000-000000000000" else { throw FailureCode.invalidIdentity }
        rawValue = uuid.uuidString.lowercased()
    }
    public static func fresh() -> Self { try! Self(UUID().uuidString) }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}
public typealias ProfileID = ID<ProfileTag>
public typealias StoreID = ID<StoreTag>
public typealias PrivateSessionID = ID<SessionTag>
public typealias EphemeralStoreID = ID<EphemeralTag>
public typealias NamespaceID = ID<NamespaceTag>
public typealias RunID = ID<RunTag>
public typealias CallerID = ID<CallerTag>
public typealias OperationID = ID<OperationTag>
public typealias ViewID = ID<ViewTag>
public typealias ResourceID = ID<ResourceTag>

extension ID: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(container.decode(String.self))
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public enum Scope: Hashable, Sendable {
    case persistent(ProfileID)
    case privateSession(PrivateSessionID)
    public var kind: ScopeKind { if case .persistent = self { return .persistent }; return .privateSession }
    public var profile: ProfileID? { if case .persistent(let p) = self { return p }; return nil }
}
public enum ScopeKind: String, Sendable { case persistent, privateSession }
public struct CallerContext: Equatable, Sendable {
    public let caller: CallerID
    public let scope: Scope
    public let run: RunID
    public let authorityEpoch: UInt64
    // This value is a claim checked against the injected host registry, not a bearer token.
    public init(caller: CallerID, scope: Scope, run: RunID, authorityEpoch: UInt64) {
        self.caller = caller; self.scope = scope; self.run = run; self.authorityEpoch = authorityEpoch
    }
}
