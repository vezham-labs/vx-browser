import Foundation

/// Local parsing only; no network suggestions, credential retention or automatic restore.
public enum NativeNavigationInput {
    public enum SearchProvider: String, CaseIterable, Sendable {
        case duckDuckGo = "DuckDuckGo"
        case google = "Google"
        case addressesOnly = "Addresses only"
    }

    public static func destination(_ value: String, provider: SearchProvider = .duckDuckGo) -> URL? {
        let input = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, input.utf8.count <= 2048,
              !input.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return nil }
        let hasWhitespace = input.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
        let hostPart = input.split(whereSeparator: { "/?#".contains($0) }).first.map(String.init) ?? input
        // An authority with user information must never become a remote search query.
        // Check before search classification, including scheme-relative references.
        let authority = input.hasPrefix("//") ? String(input.dropFirst(2).prefix { !"/?#".contains($0) }) : hostPart
        if let separator = authority.lastIndex(of: "@"), separator != authority.startIndex,
           authority.rangeOfCharacter(from: .whitespacesAndNewlines) == nil {
            return nil
        }
        let hostLike = hostPart.contains(".") || hostPart.lowercased().hasPrefix("localhost") || hostPart.hasPrefix("[")
        let schemePattern = "^[a-zA-Z][a-zA-Z0-9+.-]*:"
        let explicitScheme = input.range(of: schemePattern, options: .regularExpression) != nil && !hostLike
        if !explicitScheme && (!hostLike || hasWhitespace) {
            var search = URLComponents()
            search.scheme = "https"
            switch provider {
            case .duckDuckGo:
                search.host = "duckduckgo.com"
                search.path = "/"
            case .google:
                search.host = "www.google.com"
                search.path = "/search"
            case .addressesOnly:
                return nil
            }
            search.queryItems = [URLQueryItem(name: "q", value: input)]
            // Search engines decode a literal plus as a form-space.
            search.percentEncodedQuery = search.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
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
