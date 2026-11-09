import Foundation

/// Engine-independent metadata. No native handles, paths, URLs, grants or website contents.
public struct StorageDescriptor: Codable, Equatable, Sendable {
    public enum Mode: String, Codable, Sendable { case persistent, privateSession }
    public enum Phase: String, Codable, Sendable, CaseIterable {
        case intent, resolved, registered, configured, constructed, published, navigationAuthorized
        case retiring, retired, removalPending, removed, quarantined
    }
    public enum RestoreState: String, Codable, Sendable { case none, pending, reconciled, unknown }
    public let schemaVersion: UInt16
    public let adapterVersion: UInt16
    public let namespace: NamespaceID
    public let profile: ProfileID?
    public let store: StoreID?
    public let session: PrivateSessionID?
    public let generation: UInt64
    public let operation: OperationID
    public let createdAt: UInt64
    public private(set) var updatedAt: UInt64
    public private(set) var phase: Phase
    public private(set) var restore: RestoreState
    public let minimumPlatformMajor: UInt16

    public var mode: Mode { profile == nil ? .privateSession : .persistent }
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, adapterVersion, namespace, profile, store, session, generation, operation
        case createdAt, updatedAt, phase, restore, minimumPlatformMajor
    }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(UInt16.self, forKey: .schemaVersion)
        adapterVersion = try c.decode(UInt16.self, forKey: .adapterVersion)
        namespace = try c.decode(NamespaceID.self, forKey: .namespace)
        profile = try c.decodeIfPresent(ProfileID.self, forKey: .profile)
        store = try c.decodeIfPresent(StoreID.self, forKey: .store)
        session = try c.decodeIfPresent(PrivateSessionID.self, forKey: .session)
        generation = try c.decode(UInt64.self, forKey: .generation)
        operation = try c.decode(OperationID.self, forKey: .operation)
        createdAt = try c.decode(UInt64.self, forKey: .createdAt)
        updatedAt = try c.decode(UInt64.self, forKey: .updatedAt)
        phase = try c.decode(Phase.self, forKey: .phase)
        restore = try c.decode(RestoreState.self, forKey: .restore)
        minimumPlatformMajor = try c.decode(UInt16.self, forKey: .minimumPlatformMajor)
        try validate()
        guard mode == .persistent else { throw FailureCode.privatePersistenceForbidden }
    }
    public func encode(to encoder: any Encoder) throws {
        try validate()
        guard mode == .persistent else { throw FailureCode.privatePersistenceForbidden }
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(schemaVersion, forKey: .schemaVersion); try c.encode(adapterVersion, forKey: .adapterVersion)
        try c.encode(namespace, forKey: .namespace); try c.encodeIfPresent(profile, forKey: .profile)
        try c.encodeIfPresent(store, forKey: .store); try c.encodeIfPresent(session, forKey: .session)
        try c.encode(generation, forKey: .generation); try c.encode(operation, forKey: .operation)
        try c.encode(createdAt, forKey: .createdAt); try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(phase, forKey: .phase); try c.encode(restore, forKey: .restore)
        try c.encode(minimumPlatformMajor, forKey: .minimumPlatformMajor)
    }
    public init(namespace: NamespaceID, profile: ProfileID? = nil, store: StoreID? = nil,
                session: PrivateSessionID? = nil, generation: UInt64 = 1, operation: OperationID,
                timestamp: UInt64) throws {
        schemaVersion = 1; adapterVersion = 1; self.namespace = namespace
        self.profile = profile; self.store = store; self.session = session; self.generation = generation
        self.operation = operation; createdAt = timestamp; updatedAt = timestamp
        phase = .intent; restore = .none; minimumPlatformMajor = 26
        try validate()
    }
    public func validate() throws {
        guard schemaVersion == 1, adapterVersion == 1, minimumPlatformMajor == 26,
              generation > 0, generation < UInt64.max, createdAt > 0, updatedAt >= createdAt else {
            throw FailureCode.invalidConfiguration
        }
        if let profile {
            guard let store, profile.rawValue != store.rawValue, session == nil else { throw FailureCode.invalidIdentity }
        } else {
            guard session != nil, store == nil else { throw FailureCode.privatePersistenceForbidden }
        }
        if restore == .unknown, phase != .quarantined { throw FailureCode.corruptRecovery }
    }
    public mutating func advance(to next: Phase, operation: OperationID, timestamp: UInt64) throws {
        try validate()
        guard self.operation == operation, timestamp >= updatedAt else { throw FailureCode.operationConflict }
        if next == phase { return } // Exact transition replay has no effect.
        let expected: Phase?
        switch phase {
        case .intent: expected = .resolved
        case .resolved: expected = .registered
        case .registered: expected = .configured
        case .configured: expected = .constructed
        case .constructed: expected = .published
        case .published: expected = .navigationAuthorized
        case .navigationAuthorized: expected = .retiring
        case .retiring: expected = .retired
        case .retired: expected = .removalPending
        case .removalPending: expected = .removed
        case .removed, .quarantined: expected = nil
        }
        guard next == expected || (next == .quarantined && phase != .removed) else { throw FailureCode.illegalTransition }
        phase = next; updatedAt = timestamp
        if next == .quarantined { restore = .unknown }
    }
    public func persistentBytes() throws -> Data {
        try validate()
        guard mode == .persistent else { throw FailureCode.privatePersistenceForbidden }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }
    public static func decodePersistent(_ bytes: Data) throws -> Self {
        guard !bytes.isEmpty, bytes.count <= 8192 else { throw FailureCode.corruptRecovery }
        let value = try JSONDecoder().decode(Self.self, from: bytes)
        try value.validate()
        guard value.mode == .persistent else { throw FailureCode.privatePersistenceForbidden }
        return value
    }
}

/// A restart reconciliation plan is a value, not permission to execute a native factory.
public struct StorageReconciliation: Equatable, Sendable {
    public enum Desired: Sendable { case available, retired, removed }
    public enum Observed: Sendable { case present, absent, unknown, conflicting }
    public enum Step: Equatable, Sendable { case resolveExisting, remainRetired, preserveTombstone, quarantine }
    public let desired: Desired
    public let recorded: StorageDescriptor.Phase
    public let observed: Observed
    public let action: Step
    public let final: StorageDescriptor.RestoreState
    public init(desired: Desired, descriptor: StorageDescriptor, observed: Observed) throws {
        try descriptor.validate()
        guard descriptor.mode == .persistent else { throw FailureCode.privatePersistenceForbidden }
        self.desired = desired; recorded = descriptor.phase; self.observed = observed
        switch (desired, descriptor.phase, observed) {
        case (.available, .navigationAuthorized, .present), (.available, .published, .present):
            action = .resolveExisting; final = .reconciled
        case (.retired, .retired, .present): action = .remainRetired; final = .reconciled
        case (.removed, .removed, .absent): action = .preserveTombstone; final = .reconciled
        default: action = .quarantine; final = .unknown
        }
    }
}
