import Foundation

public enum WorkspaceTag: Sendable {}
public enum WorkspaceSpaceTag: Sendable {}
public enum WorkspaceGroupTag: Sendable {}
public enum WorkspaceTabTag: Sendable {}
public typealias WorkspaceID = ID<WorkspaceTag>
public typealias WorkspaceSpaceID = ID<WorkspaceSpaceTag>
public typealias WorkspaceGroupID = ID<WorkspaceGroupTag>
public typealias WorkspaceTabID = ID<WorkspaceTabTag>

public struct WorkspaceLayout: Codable, Equatable, Sendable {
    public struct Catalog: Codable, Equatable, Sendable {
        public var workspaces: [Workspace]
    }

    public struct Workspace: Codable, Equatable, Sendable {
        public let id: WorkspaceID
        public var name: String
    }

    public struct Session: Codable, Equatable, Sendable {
        public var lastWorkspaceId: WorkspaceID?
        public var layouts: [Layout]
    }

    public struct Layout: Codable, Equatable, Sendable {
        public let workspaceId: WorkspaceID
        public var activeSpaceId: WorkspaceSpaceID?
        public var spaces: [Space]
        public var windowFrame: Frame?
    }

    public struct Space: Codable, Equatable, Sendable {
        public let id: WorkspaceSpaceID
        public var name: String
        public var groups: [Group]
        public var tabs: [Tab]
        public var activeTabId: WorkspaceTabID?
        public var split: Split?
    }

    public struct Group: Codable, Equatable, Sendable {
        public let id: WorkspaceGroupID
        public var name: String
        public var collapsed: Bool
    }

    public struct Tab: Codable, Equatable, Sendable {
        public let id: WorkspaceTabID
        public var pinned: Bool
        public var groupId: WorkspaceGroupID?
    }

    public struct Split: Codable, Equatable, Sendable {
        public let leadingTabId: WorkspaceTabID
        public let trailingTabId: WorkspaceTabID
        public var focusedTabId: WorkspaceTabID?
        public var dividerBasisPoints: Int

        public var members: [WorkspaceTabID] { [leadingTabId, trailingTabId] }

        public func visibleTabs(contentWidth: Double) -> [WorkspaceTabID] {
            contentWidth >= 600 ? members : [focusedTabId ?? leadingTabId]
        }

        public func dividerPosition(contentWidth: Double, thickness: Double) -> Double? {
            let available = contentWidth - thickness
            guard contentWidth >= 600, available >= 500 else { return nil }
            return min(available - 250, max(250, available * Double(dividerBasisPoints) / 10_000))
        }
    }

    public struct Frame: Codable, Equatable, Sendable {
        public let x: Double
        public let y: Double
        public let width: Double
        public let height: Double

        fileprivate var isValid: Bool {
            [x, y, width, height].allSatisfy { $0.isFinite && abs($0) <= 100_000 } && width > 0 && height > 0
        }
    }

    public enum Error: Swift.Error, Equatable {
        case invalid, capacity, unsupportedVersion, staleRevision
    }

    public static let maxRevision: UInt64 = 9_007_199_254_740_991
    public static let maxBytes = 256 * 1024
    public private(set) var schemaVersion = 1
    public private(set) var revision: UInt64 = 0
    public private(set) var catalog: Catalog
    public private(set) var session: Session

    public init() {
        let id = WorkspaceID.fresh()
        catalog = Catalog(workspaces: [Workspace(id: id, name: "Personal")])
        session = Session(lastWorkspaceId: id, layouts: [Self.emptyLayout(id)])
    }

    fileprivate static func emptySpace(_ name: String) -> Space {
        Space(id: .fresh(), name: name, groups: [], tabs: [])
    }

    private static func emptyLayout(_ id: WorkspaceID) -> Layout {
        let space = emptySpace("Personal")
        return Layout(workspaceId: id, activeSpaceId: space.id, spaces: [space])
    }

    private enum CodingKeys: String, CodingKey { case schemaVersion, revision, catalog, session }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        guard version == 0 || version == 1 else { throw Error.unsupportedVersion }
        revision = try container.decode(UInt64.self, forKey: .revision)
        catalog = try container.decode(Catalog.self, forKey: .catalog)
        session = try container.decode(Session.self, forKey: .session)
        if version == 0 {
            guard session.layouts.allSatisfy({ $0.windowFrame == nil && $0.spaces.allSatisfy { $0.split == nil } }),
                  revision < Self.maxRevision else { throw Error.invalid }
            revision += 1
        }
        try validateAndNormalize()
    }

    public static func decode(_ data: Data) throws -> Self {
        guard data.count <= maxBytes else { throw Error.capacity }
        return try JSONDecoder().decode(Self.self, from: data)
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(self)
        guard data.count <= Self.maxBytes else { throw Error.capacity }
        return data
    }

    public var activeWorkspace: Workspace { catalog.workspaces.first { $0.id == session.lastWorkspaceId }! }
    public var activeLayout: Layout { session.layouts.first { $0.workspaceId == session.lastWorkspaceId }! }
    public var activeSpace: Space { activeLayout.spaces.first { $0.id == activeLayout.activeSpaceId }! }

    /// All edits are staged in a value copy and published only after graph validation.
    public mutating func replace(expectedRevision: UInt64, _ edit: (inout Catalog, inout Session) throws -> Void) throws {
        guard revision == expectedRevision else { throw Error.staleRevision }
        var next = self
        try edit(&next.catalog, &next.session)
        try next.validateAndNormalize()
        guard next != self else { return }
        guard revision < Self.maxRevision else { throw Error.capacity }
        next.revision += 1
        self = next
    }

    public enum Action {
        case createWorkspace(String), renameWorkspace(WorkspaceID, String), reorderWorkspace(WorkspaceID, Int)
        case selectWorkspace(WorkspaceID), deleteWorkspace(WorkspaceID)
        case createSpace(String), renameSpace(WorkspaceSpaceID, String), selectSpace(WorkspaceSpaceID), deleteSpace(WorkspaceSpaceID)
        case createGroup(String), renameGroup(WorkspaceGroupID, String), toggleGroup(WorkspaceGroupID)
        case reorderGroup(WorkspaceGroupID, Int), deleteGroup(WorkspaceGroupID)
        case addTab(WorkspaceTabID), selectTab(WorkspaceTabID), closeTab(WorkspaceTabID), reorderTab(WorkspaceTabID, Int)
        case moveTab(WorkspaceTabID, WorkspaceSpaceID), pin(WorkspaceTabID), group(WorkspaceTabID, WorkspaceGroupID?)
        case split(WorkspaceTabID), unsplit, divider(Int)
    }

    public mutating func apply(_ action: Action) throws {
        let workspace = activeWorkspace.id
        try replace(expectedRevision: revision) { catalog, session in
            guard let index = session.layouts.firstIndex(where: { $0.workspaceId == workspace }) else { throw Error.invalid }
            switch action {
            case .createWorkspace(let name):
                let id = WorkspaceID.fresh()
                catalog.workspaces.append(Workspace(id: id, name: name))
                session.layouts.append(Self.emptyLayout(id))
            case .renameWorkspace(let id, let name):
                guard let i = catalog.workspaces.firstIndex(where: { $0.id == id }) else { throw Error.invalid }
                catalog.workspaces[i].name = name
            case .reorderWorkspace(let id, let offset):
                guard let i = catalog.workspaces.firstIndex(where: { $0.id == id }) else { throw Error.invalid }
                try Self.move(&catalog.workspaces, from: i, offset: offset)
            case .selectWorkspace(let id):
                guard catalog.workspaces.contains(where: { $0.id == id }) else { throw Error.invalid }
                session.lastWorkspaceId = id
            case .deleteWorkspace(let id):
                guard id != workspace, let i = session.layouts.firstIndex(where: { $0.workspaceId == id }),
                      session.layouts[i].spaces.allSatisfy({ $0.tabs.isEmpty }) else { throw Error.invalid }
                session.layouts.remove(at: i)
                catalog.workspaces.removeAll { $0.id == id }
            default:
                try session.layouts[index].apply(action)
            }
        }
    }

    fileprivate static func move<T>(_ array: inout [T], from index: Int, offset: Int) throws {
        guard (-24...24).contains(offset) else { throw Error.invalid }
        let destination = min(array.count - 1, max(0, index + offset))
        let value = array.remove(at: index)
        array.insert(value, at: destination)
    }

    fileprivate static func checkedName(_ name: String) throws -> String {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...40).contains(name.count),
              !name.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else { throw Error.invalid }
        return name
    }

    private mutating func validateAndNormalize() throws {
        guard revision <= Self.maxRevision, !catalog.workspaces.isEmpty else { throw Error.invalid }
        guard catalog.workspaces.count <= 12 else { throw Error.capacity }
        let workspaceIDs = Set(catalog.workspaces.map(\.id))
        guard workspaceIDs.count == catalog.workspaces.count, session.layouts.count == workspaceIDs.count,
              Set(session.layouts.map(\.workspaceId)) == workspaceIDs else { throw Error.invalid }
        for i in catalog.workspaces.indices { catalog.workspaces[i].name = try Self.checkedName(catalog.workspaces[i].name) }
        if session.lastWorkspaceId.map(workspaceIDs.contains) != true {
            session.lastWorkspaceId = catalog.workspaces.first?.id
        }

        let spaces = session.layouts.flatMap(\.spaces)
        let allSpaces = Set(spaces.map(\.id))
        let groups = spaces.flatMap(\.groups), tabs = spaces.flatMap(\.tabs)
        let allGroups = Set(groups.map(\.id)), allTabs = Set(tabs.map(\.id))
        guard allSpaces.count == spaces.count, allGroups.count == groups.count, allTabs.count == tabs.count else { throw Error.invalid }
        for li in session.layouts.indices {
            var layout = session.layouts[li]
            guard let first = layout.spaces.first else { throw Error.invalid }
            guard layout.spaces.count <= 12, layout.spaces.reduce(0, { $0 + $1.tabs.count }) <= 24,
                  layout.spaces.reduce(0, { $0 + $1.groups.count }) <= 32 else { throw Error.capacity }
            let local = Set(layout.spaces.map(\.id))
            if let active = layout.activeSpaceId, !local.contains(active), allSpaces.contains(active) { throw Error.invalid }
            if layout.activeSpaceId.map(local.contains) != true { layout.activeSpaceId = first.id }
            if layout.windowFrame?.isValid == false { layout.windowFrame = nil }
            for si in layout.spaces.indices {
                try layout.spaces[si].normalize(allGroups: allGroups, allTabs: allTabs)
            }
            session.layouts[li] = layout
        }
    }
}

extension WorkspaceLayout.Layout {
    fileprivate mutating func apply(_ action: WorkspaceLayout.Action) throws {
        typealias Failure = WorkspaceLayout.Error
        guard let active = spaces.firstIndex(where: { $0.id == activeSpaceId }) else { throw Failure.invalid }
        switch action {
        case .createSpace(let name):
            let space = WorkspaceLayout.emptySpace(name)
            spaces.append(space)
            activeSpaceId = space.id
        case .renameSpace(let id, let name):
            guard let i = spaces.firstIndex(where: { $0.id == id }) else { throw Failure.invalid }
            spaces[i].name = name
        case .selectSpace(let id):
            guard spaces.contains(where: { $0.id == id }) else { throw Failure.invalid }
            activeSpaceId = id
        case .deleteSpace(let id):
            guard spaces.count > 1, let i = spaces.firstIndex(where: { $0.id == id }), spaces[i].tabs.isEmpty else { throw Failure.invalid }
            spaces.remove(at: i)
            if activeSpaceId == id { activeSpaceId = spaces[min(i, spaces.count - 1)].id }
        case .selectTab(let id):
            guard let i = spaces.firstIndex(where: { $0.tabs.contains { $0.id == id } }) else { throw Failure.invalid }
            activeSpaceId = spaces[i].id
            spaces[i].select(id)
        case .moveTab(let id, let target):
            guard let from = spaces.firstIndex(where: { $0.tabs.contains { $0.id == id } }),
                  let to = spaces.firstIndex(where: { $0.id == target }) else { throw Failure.invalid }
            guard from != to else { return }
            var tab = try spaces[from].remove(id)
            tab.groupId = nil
            spaces[to].tabs.append(tab)
        case .closeTab(let id), .pin(let id), .group(let id, _), .reorderTab(let id, _):
            guard let i = spaces.firstIndex(where: { $0.tabs.contains { $0.id == id } }) else { throw Failure.invalid }
            try spaces[i].apply(action)
        default:
            try spaces[active].apply(action)
        }
    }
}

extension WorkspaceLayout.Space {
    fileprivate mutating func select(_ id: WorkspaceTabID) {
        activeTabId = id
        if split?.members.contains(id) == true { split?.focusedTabId = id }
        else { split = nil }
    }

    fileprivate mutating func remove(_ id: WorkspaceTabID) throws -> WorkspaceLayout.Tab {
        guard let i = tabs.firstIndex(where: { $0.id == id }) else { throw WorkspaceLayout.Error.invalid }
        let tab = tabs.remove(at: i)
        if let pair = split, pair.members.contains(id) {
            split = nil
            activeTabId = pair.members.first { $0 != id }
        } else if activeTabId == id {
            activeTabId = tabs.isEmpty ? nil : tabs[min(i, tabs.count - 1)].id
        }
        return tab
    }

    fileprivate mutating func apply(_ action: WorkspaceLayout.Action) throws {
        typealias Failure = WorkspaceLayout.Error
        switch action {
        case .addTab(let id):
            tabs.append(WorkspaceLayout.Tab(id: id, pinned: false))
            select(id)
        case .closeTab(let id):
            _ = try remove(id)
        case .reorderTab(let id, let offset):
            guard let i = tabs.firstIndex(where: { $0.id == id }) else { throw Failure.invalid }
            try WorkspaceLayout.move(&tabs, from: i, offset: offset)
        case .pin(let id):
            guard let i = tabs.firstIndex(where: { $0.id == id }) else { throw Failure.invalid }
            tabs[i].pinned.toggle()
            if tabs[i].pinned { tabs[i].groupId = nil }
        case .group(let id, let group):
            guard let i = tabs.firstIndex(where: { $0.id == id }),
                  group.map({ g in groups.contains { $0.id == g } }) ?? true else { throw Failure.invalid }
            tabs[i].groupId = group
            if group != nil { tabs[i].pinned = false }
        case .createGroup(let name):
            groups.append(WorkspaceLayout.Group(id: .fresh(), name: name, collapsed: false))
        case .renameGroup(let id, let name):
            guard let i = groups.firstIndex(where: { $0.id == id }) else { throw Failure.invalid }
            groups[i].name = name
        case .toggleGroup(let id):
            guard let i = groups.firstIndex(where: { $0.id == id }) else { throw Failure.invalid }
            groups[i].collapsed.toggle()
        case .reorderGroup(let id, let offset):
            guard let i = groups.firstIndex(where: { $0.id == id }) else { throw Failure.invalid }
            try WorkspaceLayout.move(&groups, from: i, offset: offset)
        case .deleteGroup(let id):
            guard groups.contains(where: { $0.id == id }) else { throw Failure.invalid }
            groups.removeAll { $0.id == id }
            for i in tabs.indices where tabs[i].groupId == id { tabs[i].groupId = nil }
        case .split(let second):
            guard let first = activeTabId, first != second, tabs.contains(where: { $0.id == second }) else { throw Failure.invalid }
            split = WorkspaceLayout.Split(leadingTabId: first, trailingTabId: second, focusedTabId: second, dividerBasisPoints: 5000)
            activeTabId = second
        case .unsplit:
            split = nil
        case .divider(let basisPoints):
            guard split != nil, (0...10_000).contains(basisPoints) else { throw Failure.invalid }
            split?.dividerBasisPoints = basisPoints
        default:
            throw Failure.invalid
        }
    }

    fileprivate mutating func normalize(allGroups: Set<WorkspaceGroupID>, allTabs: Set<WorkspaceTabID>) throws {
        typealias Failure = WorkspaceLayout.Error
        name = try WorkspaceLayout.checkedName(name)
        let localGroups = Set(groups.map(\.id)), localTabs = Set(tabs.map(\.id))
        for i in groups.indices { groups[i].name = try WorkspaceLayout.checkedName(groups[i].name) }
        for i in tabs.indices {
            if let id = tabs[i].groupId, !localGroups.contains(id) {
                guard !allGroups.contains(id) else { throw Failure.invalid }
                tabs[i].groupId = nil
            }
            if tabs[i].pinned { tabs[i].groupId = nil }
        }
        if let id = activeTabId, !localTabs.contains(id), allTabs.contains(id) { throw Failure.invalid }
        if activeTabId.map(localTabs.contains) != true { activeTabId = tabs.first?.id }
        guard var pair = split else { return }
        guard (0...10_000).contains(pair.dividerBasisPoints) else { throw Failure.invalid }
        if let focus = pair.focusedTabId, !localTabs.contains(focus), allTabs.contains(focus) { throw Failure.invalid }
        let missing = pair.members.filter { !localTabs.contains($0) }
        guard missing.allSatisfy({ !allTabs.contains($0) }) else { throw Failure.invalid }
        if pair.leadingTabId == pair.trailingTabId || !missing.isEmpty {
            split = nil
            if missing.count == 1 { activeTabId = pair.members.first(where: localTabs.contains) }
            return
        }
        if pair.focusedTabId.map(pair.members.contains) != true {
            pair.focusedTabId = activeTabId.flatMap { pair.members.contains($0) ? $0 : nil } ?? pair.leadingTabId
        }
        split = pair
        activeTabId = pair.focusedTabId
    }
}
