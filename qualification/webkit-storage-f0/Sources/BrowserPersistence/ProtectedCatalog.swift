import Foundation
import BrowserDomain
import BrowserPorts

/// The one production catalog port. No provider call or plaintext fallback until
/// an approved key-before-read initialization path exists for the pinned provider.
public actor ProtectedCatalog: ProfileCatalogPort, RecoveryJournalPort {
    public enum Blocker: String, Sendable { case D2A01KeyBeforeRead }
    public let blocker: Blocker = .D2A01KeyBeforeRead
    public init() {}
    public func lookup(_ profile: ProfileID) -> CatalogObservation { .unavailable }
    public func enumerate() -> CatalogInventory { CatalogInventory(bindings: [], issues: [CatalogIssue(index: 0, failure: .catalogUnavailable)]) }
    public func insert(_ binding: ProfileBinding) -> CatalogWrite { .failed(.catalogUnavailable) }
    public func transition(_ profile: ProfileID, expectedRevision: UInt64, to status: CatalogStatus) -> CatalogWrite { .failed(.catalogUnavailable) }
    public func read(_ profile: ProfileID) -> RecoveryObservation { .unavailable }
    public func write(_ record: RecoveryRecord) -> JournalWrite { .failed(.journalUnavailable) }
    public func snapshot(run: RunID) -> RestartSnapshot { RestartSnapshot(version: 0, previousRun: run, records: []) }
}

/// Executable schema/migration planning, never executed against a provider here.
public enum CatalogSchema {
    public static let version: UInt32 = 2
    public struct Migration: Sendable { public let from: UInt32; public let to: UInt32; public let statements: [String] }
    public static let migrations: [Migration] = [
        Migration(from: 0, to: 1, statements: [
            "CREATE TABLE catalog_identity(id TEXT PRIMARY KEY, schema_version INTEGER NOT NULL, revision INTEGER NOT NULL CHECK(revision>0));",
            "CREATE TABLE profiles(profile_id TEXT PRIMARY KEY, store_id TEXT UNIQUE NOT NULL, descriptor BLOB NOT NULL, label TEXT NOT NULL, state TEXT NOT NULL, revision INTEGER NOT NULL CHECK(revision>0), CHECK(profile_id<>store_id));",
            "CREATE TABLE lifecycle(profile_id TEXT PRIMARY KEY REFERENCES profiles(profile_id), operation_id TEXT NOT NULL, generation INTEGER NOT NULL, phase TEXT NOT NULL, payload BLOB NOT NULL);",
            "CREATE TABLE receipts(operation_id TEXT PRIMARY KEY, request_digest BLOB NOT NULL, expected_revision INTEGER NOT NULL, outcome BLOB NOT NULL);"
        ]),
        Migration(from: 1, to: 2, statements: [
            "CREATE TABLE deletion_records(record_id TEXT PRIMARY KEY, profile_id TEXT NOT NULL, deletion_epoch INTEGER NOT NULL CHECK(deletion_epoch>0));",
            "CREATE TABLE profile_security(profile_id TEXT PRIMARY KEY REFERENCES profiles(profile_id), lock_state TEXT NOT NULL, key_version INTEGER NOT NULL, epoch INTEGER NOT NULL CHECK(epoch>0));",
            "CREATE TABLE permission_grants(profile_id TEXT NOT NULL REFERENCES profiles(profile_id), origin BLOB NOT NULL, capability TEXT NOT NULL, decision TEXT NOT NULL, lifetime TEXT NOT NULL, created_ms INTEGER NOT NULL, updated_ms INTEGER NOT NULL, revoked_ms INTEGER, PRIMARY KEY(profile_id,origin,capability));"
        ])
    ]
    public static func plan(from current: UInt32, authenticated: Bool, interrupted: Bool) throws -> [Migration] {
        guard authenticated, !interrupted else { throw FailureCode.quarantined }
        guard current <= version else { throw FailureCode.unsupported }
        return migrations.filter { $0.from >= current }
    }
    public static func validateRecord(_ descriptor: StorageDescriptor, label: String, expectedNamespace: NamespaceID) throws {
        try descriptor.validate()
        guard descriptor.mode == .persistent, descriptor.namespace == expectedNamespace,
              !label.isEmpty, label.utf8.count <= 256, !label.contains(where: { $0.isNewline || $0 == "\0" }) else {
            throw FailureCode.invalidConfiguration
        }
    }
    public static func mayPublish(expectedRevision: UInt64, actualRevision: UInt64,
                                  journalStable: Bool, keyAuthenticated: Bool, engineReady: Bool) -> Bool {
        expectedRevision > 0 && expectedRevision == actualRevision && journalStable && keyAuthenticated && engineReady
    }
}
