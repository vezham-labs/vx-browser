import Foundation
import SQLite3

/// The ordinary SQLite allowlist contains exactly one non-authoritative global value.
/// This store has no profile, URL, origin, file capability or arbitrary-value API.
public enum GlobalAppearance: Int32, Sendable {
    case system = 0
    case light = 1
    case dark = 2
}

public struct GlobalAppearanceSettings: Sendable {
    public struct StorageError: Error, Equatable {
        public let operation: String
        public let code: Int32
    }

    private let file: URL

    public init(applicationSupport: URL) {
        file = applicationSupport.appendingPathComponent("global-appearance.sqlite", isDirectory: false)
    }

    public func read() throws -> GlobalAppearance {
        do {
            _ = try FileManager.default.attributesOfItem(atPath: file.path)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain &&
            (error.code == NSFileNoSuchFileError || error.code == NSFileReadNoSuchFileError) {
            return .system
        }
        return try withDatabase(flags: SQLITE_OPEN_READONLY) { db in
            try withStatement(db, "SELECT appearance FROM global_appearance WHERE slot=1") { statement in
                let rc = sqlite3_step(statement)
                if rc == SQLITE_DONE { return .system }
                guard rc == SQLITE_ROW, sqlite3_column_type(statement, 0) == SQLITE_INTEGER,
                      let value = GlobalAppearance(rawValue: sqlite3_column_int(statement, 0)),
                      sqlite3_column_int64(statement, 0) == Int64(value.rawValue) else {
                    throw StorageError(operation: "read", code: rc == SQLITE_ROW ? SQLITE_MISMATCH : rc)
                }
                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw StorageError(operation: "unique-row", code: SQLITE_MISMATCH)
                }
                return value
            }
        }
    }

    /// Explicit write entry point. A read or a storage error never creates or resets this file.
    public func set(_ appearance: GlobalAppearance) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        try withDatabase(flags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE) { db in
            try execute(db, "BEGIN IMMEDIATE")
            // Closing the unshared connection rolls back an uncommitted transaction.
            try execute(db, """
                CREATE TABLE IF NOT EXISTS global_appearance (
                    slot INTEGER PRIMARY KEY CHECK(slot = 1),
                    appearance INTEGER NOT NULL CHECK(appearance IN (0, 1, 2))
                ) STRICT
                """)
            try withStatement(db, """
                INSERT INTO global_appearance(slot, appearance) VALUES(1, ?)
                ON CONFLICT(slot) DO UPDATE SET appearance=excluded.appearance
                """) { statement in
                let bind = sqlite3_bind_int(statement, 1, appearance.rawValue)
                guard bind == SQLITE_OK else { throw StorageError(operation: "bind", code: bind) }
                let rc = sqlite3_step(statement)
                guard rc == SQLITE_DONE else { throw StorageError(operation: "write", code: rc) }
            }
            try execute(db, "COMMIT")
        }
    }

    private func withDatabase<T>(flags: Int32, _ body: (OpaquePointer) throws -> T) throws -> T {
        var handle: OpaquePointer?
        let rc = sqlite3_open_v2(file.path, &handle, flags | SQLITE_OPEN_NOFOLLOW, nil)
        defer { if let handle { sqlite3_close(handle) } }
        guard rc == SQLITE_OK, let handle else { throw StorageError(operation: "open", code: rc) }
        try execute(handle, "PRAGMA trusted_schema=OFF")
        return try body(handle)
    }

    private func execute(_ db: OpaquePointer, _ sql: String) throws {
        let rc = sqlite3_exec(db, sql, nil, nil, nil)
        guard rc == SQLITE_OK else { throw StorageError(operation: "statement", code: rc) }
    }

    private func withStatement<T>(_ db: OpaquePointer, _ sql: String, _ body: (OpaquePointer) throws -> T) throws -> T {
        var statement: OpaquePointer?
        let rc = sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        defer { if let statement { sqlite3_finalize(statement) } }
        guard rc == SQLITE_OK, let statement else { throw StorageError(operation: "prepare", code: rc) }
        return try body(statement)
    }
}
