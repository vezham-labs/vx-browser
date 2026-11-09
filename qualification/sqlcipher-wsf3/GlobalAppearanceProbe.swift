import Foundation
import SQLite3

private struct ProbeFailure: Error {}
private func require(_ condition: Bool) throws {
    guard condition else { throw ProbeFailure() }
}

@main
enum GlobalAppearanceProbe {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let file = root.appendingPathComponent("global-appearance.sqlite")
        let store = GlobalAppearanceSettings(applicationSupport: root)
        func observation(_ id: String, _ expected: String, _ body: () throws -> Void) {
            var result = "PASS_NATIVE"
            do { try body() } catch { result = "FAIL" }
            let record = ["testID": id, "expected": expected, "status": result]
            if let data = try? JSONSerialization.data(withJSONObject: record, options: [.sortedKeys]) {
                print(String(decoding: data, as: UTF8.self))
            }
        }
        observation("LOW-MISSING", "System appearance without creating a database") {
            try require(try store.read() == .system)
            try require(!FileManager.default.fileExists(atPath: file.path))
        }
        observation("LOW-ROUNDTRIP", "Typed global appearance round-trips through native SQLite") {
            for choice in [GlobalAppearance.dark, .light, .system] {
                try store.set(choice)
                try require(try GlobalAppearanceSettings(applicationSupport: root).read() == choice)
            }
        }
        observation("LOW-ALLOWLIST", "SQLite rejects values and slots outside the allowlist") {
            var handle: OpaquePointer?
            let result = sqlite3_open_v2(file.path, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_NOFOLLOW, nil)
            defer { if let handle { sqlite3_close(handle) } }
            try require(result == SQLITE_OK && handle != nil)
            try require(sqlite3_exec(handle, "UPDATE global_appearance SET appearance=99", nil, nil, nil) == SQLITE_CONSTRAINT)
            try require(sqlite3_exec(handle, "INSERT INTO global_appearance VALUES(2,1)", nil, nil, nil) == SQLITE_CONSTRAINT)
        }
        observation("LOW-SYMLINK", "Read refuses a symlink instead of following it or replacing it") {
            let backup = root.appendingPathComponent("original")
            try FileManager.default.moveItem(at: file, to: backup)
            try FileManager.default.createSymbolicLink(at: file, withDestinationURL: backup)
            do {
                _ = try store.read()
            } catch is GlobalAppearanceSettings.StorageError {
                return
            }
            throw ProbeFailure()
        }
    }
}
