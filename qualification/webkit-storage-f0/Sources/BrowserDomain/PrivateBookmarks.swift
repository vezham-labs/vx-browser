import Foundation

/// Volatile sidebar links. No serialization or cross-session ownership.
public struct PrivateBookmarks: Sendable {
    public struct Link: Identifiable, Equatable, Sendable {
        public let id: UUID
        public var title: String
        public var url: String
        public var folder: String
        public var favorite: Bool

        public init(id: UUID = UUID(), title: String, url: String, folder: String = "", favorite: Bool = false) {
            self.id = id
            self.title = title
            self.url = url
            self.folder = folder
            self.favorite = favorite
        }
    }

    public private(set) var links: [Link] = []
    public init() {}

    public static func destination(_ input: String) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.utf8.count <= 2048, !text.contains("\\"), !text.unicodeScalars.contains(where: {
            CharacterSet.controlCharacters.contains($0) || CharacterSet.whitespacesAndNewlines.contains($0)
        }), let parts = URLComponents(string: text),
              let scheme = parts.scheme?.lowercased(), let host = parts.host?.lowercased(), !host.isEmpty,
              parts.user == nil, parts.password == nil,
              scheme == "https" || (scheme == "http" && ["127.0.0.1", "localhost", "[::1]", "::1"].contains(host))
        else { return nil }
        return parts.url
    }

    @discardableResult public mutating func save(_ link: Link) -> Bool {
        var clean = link
        clean.title = clean.title.trimmingCharacters(in: .whitespacesAndNewlines)
        clean.folder = clean.folder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.title.isEmpty, clean.title.count <= 120, clean.folder.count <= 40,
              !(clean.title + clean.folder).unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              let url = Self.destination(clean.url) else { return false }
        clean.url = url.absoluteString
        if let index = links.firstIndex(where: { $0.id == clean.id }) {
            links[index] = clean
        } else {
            guard links.count < 100 else { return false }
            links.append(clean)
        }
        return true
    }

    public mutating func remove(_ id: UUID) { links.removeAll { $0.id == id } }
    public mutating func removeAll() { links.removeAll() }

    /// Reorder relative to a live target. A cross-folder drop adopts the target's
    /// membership and leaves identity, title and URL unchanged.
    @discardableResult public mutating func move(_ id: UUID, beside target: UUID, after: Bool) -> Bool {
        guard id != target, let from = links.firstIndex(where: { $0.id == id }),
              let to = links.firstIndex(where: { $0.id == target }) else { return false }
        let destination = links[to]
        var link = links.remove(at: from)
        link.folder = destination.folder
        link.favorite = destination.favorite
        links.insert(link, at: to - (from < to ? 1 : 0) + (after ? 1 : 0))
        return true
    }

    /// Dropping onto another tile places the dragged Favorite in that tile's slot.
    @discardableResult public mutating func reorderFavorite(_ id: UUID, onto target: UUID) -> Bool {
        let favorites = links.filter(\.favorite)
        guard let sourceIndex = favorites.firstIndex(where: { $0.id == id }),
              let targetIndex = favorites.firstIndex(where: { $0.id == target }),
              sourceIndex != targetIndex else { return false }
        return move(id, beside: target, after: sourceIndex < targetIndex)
    }

    @discardableResult public mutating func move(_ id: UUID, toFolder folder: String) -> Bool {
        guard var link = links.first(where: { $0.id == id }) else { return false }
        link.folder = folder
        link.favorite = false
        return save(link)
    }
}
