import Foundation

// Evidence sink for the isolated interactive runner. Never registered with a page.
enum LocalInteractionProbe {
    static func record(_ event: String, details: [String: Any] = [:]) {
        guard CommandLine.arguments.contains("--test-local-interactions") || CommandLine.arguments.contains("--test-phase3-local"),
              let index = CommandLine.arguments.firstIndex(of: "--test-run-id"),
              CommandLine.arguments.indices.contains(index + 1) else { return }
        let runID = CommandLine.arguments[index + 1]
        guard runID.range(of: "^[A-Za-z0-9-]+$", options: .regularExpression) != nil else { return }
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WKPrototype", isDirectory: true)
        let file = directory.appendingPathComponent("interaction-events-\(runID).json")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let previous = (try? Data(contentsOf: file)).flatMap {
                try? JSONSerialization.jsonObject(with: $0) as? [[String: Any]]
            } ?? []
            var entry = details
            entry["event"] = event
            let data = try JSONSerialization.data(withJSONObject: previous + [entry], options: [.prettyPrinted, .sortedKeys])
            try data.write(to: file, options: .atomic)
        } catch {
            FileHandle.standardError.write(Data("interaction evidence write failed\n".utf8))
        }
    }
}
