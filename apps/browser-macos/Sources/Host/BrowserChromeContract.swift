import Foundation
import BrowserNativeStorage

/// External deliveries share the adapter's existing HTTPS/loopback-HTTP policy.
enum ExternalBrowserRoute {
    case workspace(URL), mini(URL)

    static func parse(_ input: URL) -> Self? {
        guard input.absoluteString.utf8.count <= 12_288 else { return nil }
        if NativeWebKitStorage.permitsInteractiveURL(input) { return .workspace(input) }
        guard input.scheme?.lowercased() == "vezham", input.host?.lowercased() == "open",
              input.user == nil, input.password == nil, input.port == nil,
              input.path.isEmpty, input.fragment == nil,
              let parts = URLComponents(url: input, resolvingAgainstBaseURL: false),
              parts.queryItems?.count == 1, let query = parts.queryItems?.first,
              query.name == "url", let value = query.value,
              value.utf8.count <= 8192,
              !value.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              let destination = URL(string: value),
              NativeWebKitStorage.permitsInteractiveURL(destination) else { return nil }
        return .mini(destination)
    }
}

struct ChromeCommand: Decodable {
    enum Kind: String, Decodable {
        case snapshot, recoverPrivate, startPrivate, endPrivate, newTab, activate, close, duplicate, move
        case navigate, back, forward, reload, stop, copy, paste, appearance, presentation
        case spaceCreate, spaceRename, spaceSwitch, spaceDelete, tabSpace, pin
        case groupCreate, groupRename, groupToggle, groupMove, groupDelete, tabGroup
        case split, unsplit, miniOpen, miniTransferPreview, miniTransfer
        case workspaceCreate, workspaceRename, workspaceMove, workspaceDelete, workspaceSwitch
    }

    let version: Int
    let id: String
    let type: Kind
    let tab: UUID?
    let url: String?
    let value: ChromeAppearance?
    let offset: Int?
    let target: UUID?
    let name: String?
    let visible: Bool?
    let left: Double?
    let top: Double?
}

enum ChromeAppearance: String, Codable {
    case system, light, dark
}

struct ChromeTab: Encodable, Equatable {
    let id: String
    let title: String
    let url: String?
    let loading: Bool
    let progress: Double
    let back: Bool
    let forward: Bool
    let connection: String
    let favicon: String?
    let failure: String?
    let space: String
    let pinned: Bool
    let group: String?
}

struct ChromeWorkspace: Encodable, Equatable {
    let id: String
    let name: String
    let empty: Bool
}

struct ChromeMiniPreview: Encodable {
    let token: UUID
    let url: String
    let workspace: String
    let space: String
}

struct ChromeSpace: Encodable, Equatable {
    let id: String
    var name: String
}
struct ChromeGroup: Encodable, Equatable {
    let id: String
    let space: String
    var name: String
    var collapsed = false
}

enum ChromeRecovery: String, Encodable {
    case retiring, ready, rebuilding, failed
}

struct ChromeState: Encodable, Equatable {
    let revision: Int
    let session: String
    let sessionID: String?
    let recovery: ChromeRecovery?
    let profile = "unavailable"
    let tabs: [ChromeTab]
    let selected: String?
    let appearance: ChromeAppearance
    let spaces: [ChromeSpace]
    let activeSpace: String
    let groups: [ChromeGroup]
    let split: [String]
    let splitCompact: Bool
    let mini: Bool
    let workspaces: [ChromeWorkspace]
    let activeWorkspace: String
    let miniEligible: Bool
}

struct ChromeResult: Encodable {
    let id: String
    let state: ChromeState
    let error: Failure?
    let text: String?
    var miniPreview: ChromeMiniPreview? = nil

    enum Failure: String, Encodable, Error {
        case busy, unavailable, invalid, failed, transferUnconfirmed
    }
}
