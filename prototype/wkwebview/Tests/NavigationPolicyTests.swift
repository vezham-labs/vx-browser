import Foundation

private struct NavigationPolicyCase {
    let label: String
    let input: String
    let expectedURL: String?
}

@main
private enum NavigationPolicyTests {
    static func main() throws {
        let cases = [
            NavigationPolicyCase(label: "trim surrounding whitespace", input: "  https://example.com/path  ", expectedURL: "https://example.com/path"),
            NavigationPolicyCase(label: "add HTTPS to a bare hostname", input: "example.com", expectedURL: "https://example.com"),
            NavigationPolicyCase(label: "allow HTTP loopback with an explicit port", input: "http://127.0.0.1:18765", expectedURL: "http://127.0.0.1:18765"),
            NavigationPolicyCase(label: "preserve HTTPS path and query", input: "https://example.com/path?q=fixture", expectedURL: "https://example.com/path?q=fixture"),
            NavigationPolicyCase(label: "reject file URLs", input: "file:///etc/passwd", expectedURL: nil),
            NavigationPolicyCase(label: "reject JavaScript URLs", input: "javascript:alert(1)", expectedURL: nil),
            NavigationPolicyCase(label: "reject data URLs", input: "data:text/html,fixture", expectedURL: nil),
            NavigationPolicyCase(label: "reject mail URLs", input: "mailto:fixture@example.com", expectedURL: nil),
            NavigationPolicyCase(label: "reject FTP URLs", input: "ftp://example.com/file", expectedURL: nil),
            NavigationPolicyCase(label: "reject embedded credentials", input: "https://user:pass@example.com/", expectedURL: nil),
            NavigationPolicyCase(label: "reject missing host", input: "https:///path", expectedURL: nil),
            NavigationPolicyCase(label: "reject empty input", input: "", expectedURL: nil),
            NavigationPolicyCase(label: "reject whitespace-only input", input: "   \n\t", expectedURL: nil),
        ]
        let tests: [[String: Any]] = cases.map { item in
            let url = NavigationPolicy.normalizedURL(item.input)
            let passed = url?.absoluteString == item.expectedURL
            return ["label": item.label, "passed": passed]
        }
        let failures = tests.compactMap { $0["passed"] as? Bool == true ? nil : $0["label"] as? String }
        let result: [String: Any] = [
            "mode": "url-policy",
            "hostOSVersion": ProcessInfo.processInfo.operatingSystemVersionString,
            "deploymentTarget": "macOS 26.0",
            "status": failures.isEmpty ? "passed" : "failed",
            "tests": tests,
            "failureCount": failures.count,
            "failures": failures,
        ]
        let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
        if !failures.isEmpty { exit(EXIT_FAILURE) }
    }
}
