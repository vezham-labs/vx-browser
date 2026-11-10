import Foundation

/// Local parsing only; no network suggestions, credential retention or automatic restore.
public enum NativeNavigationInput {
    public static func destination(_ value: String) -> URL? {
        let input = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, input.utf8.count <= 2048,
              !input.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return nil }
        let hasWhitespace = input.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
        let hostPart = input.split(whereSeparator: { "/?#".contains($0) }).first.map(String.init) ?? input
        let hostLike = !hostPart.contains("@") && (hostPart.contains(".") || hostPart.lowercased().hasPrefix("localhost") || hostPart.hasPrefix("["))
        let schemePattern = "^[a-zA-Z][a-zA-Z0-9+.-]*:"
        let explicitScheme = input.range(of: schemePattern, options: .regularExpression) != nil && !hostLike
        if !explicitScheme && (!hostLike || hasWhitespace) {
            var search = URLComponents(); search.scheme = "https"; search.host = "duckduckgo.com"; search.path = "/"
            search.queryItems = [URLQueryItem(name: "q", value: input)]
            return search.url
        }
        guard !hasWhitespace, !input.contains("\\"),
              let parts = URLComponents(string: explicitScheme ? input : "https://" + input),
              let scheme = parts.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host = parts.host, !host.isEmpty, parts.user == nil, parts.password == nil,
              scheme != "http" || ["localhost", "127.0.0.1", "::1", "[::1]"].contains(host.lowercased()) else { return nil }
        return parts.url
    }
}
