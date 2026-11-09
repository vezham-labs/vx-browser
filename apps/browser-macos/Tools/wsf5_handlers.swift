// WS-F5-only native default-handler probe. No browser/runtime storage access.
import AppKit

@main
struct HandlerProbe {
    @MainActor static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        let workspace = NSWorkspace.shared
        if args == ["snapshot"] {
            var result: [String: String] = [:]
            for scheme in ["http", "https"] {
                if let app = workspace.urlForApplication(toOpen: URL(string: "\(scheme)://example.com/")!) {
                    result[scheme] = app.path
                }
            }
            let data = try! JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
            print(String(decoding: data, as: UTF8.self))
            return
        }
        guard args.count == 3, args[0] == "set", ["http", "https"].contains(args[1]),
              args[2].hasSuffix(".app"), FileManager.default.fileExists(atPath: args[2]) else {
            print("Invalid handler probe arguments"); exit(2)
        }
        let error: String? = await withCheckedContinuation { continuation in
            workspace.setDefaultApplication(at: URL(fileURLWithPath: args[2]), toOpenURLsWithScheme: args[1]) { error in
                continuation.resume(returning: error.map { String(describing: $0) })
            }
        }
        let data = try! JSONSerialization.data(withJSONObject: ["scheme": args[1], "result": error ?? "completed"], options: [.sortedKeys])
        print(String(decoding: data, as: UTF8.self))
        if error != nil { exit(1) }
    }
}
