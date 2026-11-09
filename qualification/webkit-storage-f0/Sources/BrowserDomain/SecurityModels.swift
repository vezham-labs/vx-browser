import Foundation

public enum ProfileLockState: String, Codable, Sendable {
    case unlocked, lockRequested, quiescing, locked, unlockRequested, unlocking, recoveryRequired
}
public enum LockCause: String, Sendable { case manual, sleep, sessionResigned, inactivity, screenLock, shutdown }
public struct KeyLease: Hashable, Sendable {
    public let id: ResourceID
    public let profile: ProfileID
    public let run: RunID
    public let epoch: UInt64
    public init(id: ResourceID, profile: ProfileID, run: RunID, epoch: UInt64) {
        self.id = id; self.profile = profile; self.run = run; self.epoch = epoch
    }
}
public enum KeyFailure: String, Error, Sendable {
    case missing, duplicate, denied, interactionRequired, unavailable, invalid, stale, unsupported, rngFailure
}
public enum PermissionKind: String, Codable, CaseIterable, Sendable {
    case camera, microphone, cameraAndMicrophone, geolocation, notifications, displayCapture
    case clipboardRead, clipboardWrite, fileRead, fileWrite, midi, unknown
}
public struct VerifiedOrigin: Hashable, Codable, Sendable {
    public let scheme: String
    public let host: String
    public let port: UInt16
    public init(scheme: String, host: String, port: Int) throws {
        guard ["https", "http"].contains(scheme), !host.isEmpty, host.count <= 253,
              !host.contains(where: { $0.isWhitespace || "/\\@:#?%".contains($0) }), (1...65535).contains(port) else {
            throw FailureCode.invalidConfiguration
        }
        self.scheme = scheme; self.host = host.lowercased(); self.port = UInt16(port)
    }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(scheme: c.decode(String.self, forKey: .scheme), host: c.decode(String.self, forKey: .host), port: c.decode(Int.self, forKey: .port))
    }
}
public enum PermissionDecision: String, Codable, Sendable { case ask, allow, deny }
public enum GrantLifetime: String, Codable, Sendable { case once, session, persistent }
public enum NativeAuthorization: Sendable { case authorized, denied, notDetermined, unavailable }
public struct PermissionRequest: Sendable {
    public let id: OperationID
    public let context: CallerContext
    public let view: ViewID
    public let viewGeneration: UInt64
    public let origin: VerifiedOrigin
    public let kind: PermissionKind
    public init(id: OperationID, context: CallerContext, view: ViewID, viewGeneration: UInt64,
                origin: VerifiedOrigin, kind: PermissionKind) {
        self.id = id; self.context = context; self.view = view; self.viewGeneration = viewGeneration
        self.origin = origin; self.kind = kind
    }
}
public struct PermissionTicket: Hashable, Sendable {
    public let id: OperationID
    public let scope: Scope
    public let epoch: UInt64
    public init(id: OperationID, scope: Scope, epoch: UInt64) { self.id = id; self.scope = scope; self.epoch = epoch }
}
public struct PermissionEvaluation: Sendable {
    public let decision: PermissionDecision
    public let ticket: PermissionTicket?
    public init(_ decision: PermissionDecision, ticket: PermissionTicket? = nil) { self.decision = decision; self.ticket = ticket }
}
public enum OwnedDataCategory: String, Codable, CaseIterable, Sendable {
    case profileMetadata, history, bookmarks, preferences, sessions, permissions, downloads, snapshots
}
public struct OwnedRecord: Codable, Equatable, Sendable {
    public let id: ResourceID
    public let category: OwnedDataCategory
    public let payload: Data
    public init(id: ResourceID, category: OwnedDataCategory, payload: Data) throws {
        guard payload.count <= 65536 else { throw FailureCode.capacityExceeded }
        self.id = id; self.category = category; self.payload = payload
    }
}
public struct DeletionKnowledge: Codable, Sendable {
    public let epoch: UInt64
    public let deleted: Set<ResourceID>
    public let complete: Bool
    public init(epoch: UInt64, deleted: Set<ResourceID>, complete: Bool) { self.epoch = epoch; self.deleted = deleted; self.complete = complete }
}
