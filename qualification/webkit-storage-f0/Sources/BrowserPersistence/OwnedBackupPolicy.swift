import Foundation
import BrowserDomain

/// Browser-owned records only; actual catalog snapshot acquisition remains gated.
public struct OwnedBackupSnapshot: Codable, Equatable, Sendable {
    public let schema: UInt32
    public let profile: ProfileID
    public let generation: UInt64
    public let deletionEpoch: UInt64
    public let records: [OwnedRecord]
    public init(scope: Scope, generation: UInt64, deletionEpoch: UInt64, records: [OwnedRecord]) throws {
        guard case .persistent(let profile) = scope, generation > 0, deletionEpoch > 0,
              records.count <= 1024, Set(records.map(\.id)).count == records.count,
              records.allSatisfy({ $0.payload.count <= 65536 }), records.reduce(0, { $0 + $1.payload.count }) <= 4 * 1024 * 1024 else { throw FailureCode.invalidConfiguration }
        schema = CatalogSchema.version; self.profile = profile;self.generation = generation;self.deletionEpoch = deletionEpoch;self.records = records
    }
    public func validate() throws {
        guard schema == CatalogSchema.version else { throw FailureCode.unsupported }
        _ = try Self(scope: .persistent(profile), generation: generation, deletionEpoch: deletionEpoch, records: records)
    }
    public func restoring(expectedProfile: ProfileID, knowledge: DeletionKnowledge,
                          unknownLineageConfirmed: Bool, destinationExists: Bool) throws -> [OwnedRecord] {
        try validate()
        guard expectedProfile == profile, !destinationExists else { throw FailureCode.destinationConflict }
        guard knowledge.epoch >= deletionEpoch, knowledge.complete || unknownLineageConfirmed else { throw FailureCode.confirmationRequired }
        // Runtime native file tokens and OS permission grants are never restored.
        return records.filter { !knowledge.deleted.contains($0.id) && $0.category != .permissions }
    }
}
