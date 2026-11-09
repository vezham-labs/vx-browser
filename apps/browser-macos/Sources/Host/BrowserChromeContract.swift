import Foundation

struct ChromeCommand: Decodable {
    enum Kind: String, Decodable {
        case snapshot, startPrivate, endPrivate, newTab, activate, close, duplicate, move
        case navigate, back, forward, reload, stop, copy, paste, appearance, presentation
        case spaceCreate, spaceRename, spaceSwitch, spaceDelete, tabSpace, pin
        case groupCreate, groupRename, groupToggle, groupMove, groupDelete, tabGroup
        case split, unsplit, miniOpen, miniTransfer
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

struct ChromeState: Encodable, Equatable {
    let revision: Int
    let session: String
    let sessionID: String?
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
}

struct ChromeResult: Encodable {
    let id: String
    let state: ChromeState
    let error: Failure?
    let text: String?

    enum Failure: String, Encodable, Error {
        case busy, unavailable, invalid, failed
    }
}
