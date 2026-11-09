import Foundation
import Testing
@testable import BrowserDomain

@Suite("WS-F6 workspace layout")
struct WorkspaceLayoutTests {
    @Test func emptyAndSingleSlotRoundTrip() throws {
        var layout = WorkspaceLayout()
        let workspace = layout.activeWorkspace.id
        let space = layout.activeSpace.id
        #expect(layout.activeSpace.activeTabId == nil)
        #expect(try WorkspaceLayout.decode(layout.encoded()) == layout)
        let tab = WorkspaceTabID.fresh()
        try layout.apply(.addTab(tab))
        #expect(layout.activeSpace.activeTabId == tab)
        #expect(layout.activeWorkspace.id == workspace && layout.activeSpace.id == space)
        #expect(try WorkspaceLayout.decode(layout.encoded()) == layout)
    }

    @Test func boundedGraphRejectsOverflowWithoutChangingRevision() throws {
        var layout = WorkspaceLayout()
        for _ in 0..<24 { try layout.apply(.addTab(.fresh())) }
        for _ in 0..<32 { try layout.apply(.createGroup("Group")) }
        for _ in 1..<12 { try layout.apply(.createSpace("Space")) }
        let original = layout
        #expect(throws: WorkspaceLayout.Error.capacity) { try layout.apply(.addTab(.fresh())) }
        #expect(throws: WorkspaceLayout.Error.capacity) { try layout.apply(.createGroup("One too many")) }
        #expect(throws: WorkspaceLayout.Error.capacity) { try layout.apply(.createSpace("One too many")) }
        #expect(layout == original)
    }

    @Test func splitStateSurvivesSpaceChangeAndClosesToSurvivor() throws {
        var layout = WorkspaceLayout()
        let space = layout.activeSpace.id
        let first = WorkspaceTabID.fresh(), second = WorkspaceTabID.fresh(), third = WorkspaceTabID.fresh()
        try layout.apply(.addTab(first))
        try layout.apply(.addTab(second))
        try layout.apply(.addTab(third))
        try layout.apply(.selectTab(first))
        try layout.apply(.split(second))
        try layout.apply(.divider(6500))
        try layout.apply(.createSpace("Next"))
        #expect(layout.activeSpace.split == nil)
        try layout.apply(.selectSpace(space))
        let pair = try #require(layout.activeSpace.split)
        #expect(pair.members == [first, second] && pair.focusedTabId == second)
        #expect(pair.visibleTabs(contentWidth: 599) == [second])
        #expect(pair.visibleTabs(contentWidth: 600) == [first, second])
        #expect(pair.dividerPosition(contentWidth: 599, thickness: 1) == nil)
        #expect(pair.dividerPosition(contentWidth: 1001, thickness: 1) == 650)
        #expect(pair.dividerPosition(contentWidth: 601, thickness: 1) == 350)
        #expect(try WorkspaceLayout.decode(layout.encoded()).activeSpace.split == pair)
        try layout.apply(.selectTab(first))
        #expect(layout.activeSpace.split?.focusedTabId == first)
        try layout.apply(.closeTab(first))
        #expect(layout.activeSpace.split == nil && layout.activeSpace.activeTabId == second)
        try layout.apply(.closeTab(second))
        #expect(layout.activeSpace.activeTabId == third)
    }

    @Test func workspaceMutationKeepsIdentityAndRejectsActiveOrNonemptyDeletion() throws {
        var layout = WorkspaceLayout()
        let original = layout.activeWorkspace.id
        #expect(throws: WorkspaceLayout.Error.invalid) { try layout.apply(.deleteWorkspace(original)) }
        try layout.apply(.createWorkspace("Research"))
        let research = try #require(layout.catalog.workspaces.last?.id)
        #expect(layout.activeWorkspace.id == original)
        try layout.apply(.renameWorkspace(research, "Reading"))
        try layout.apply(.reorderWorkspace(research, -1))
        #expect(layout.catalog.workspaces.first?.id == research)
        try layout.apply(.selectWorkspace(research))
        try layout.apply(.addTab(.fresh()))
        try layout.apply(.selectWorkspace(original))
        let before = layout
        #expect(throws: WorkspaceLayout.Error.invalid) { try layout.apply(.deleteWorkspace(research)) }
        #expect(layout == before)
        try layout.apply(.selectWorkspace(research))
        try layout.apply(.deleteWorkspace(original))
        #expect(layout.catalog.workspaces.map(\.id) == [research])
    }

    @Test func pinGroupingMoveAndSplitReferencesStayLocal() throws {
        var layout = WorkspaceLayout()
        let space = layout.activeSpace.id, tab = WorkspaceTabID.fresh(), sibling = WorkspaceTabID.fresh()
        try layout.apply(.addTab(tab))
        try layout.apply(.createGroup("Drafts"))
        let group = try #require(layout.activeSpace.groups.first?.id)
        try layout.apply(.group(tab, group))
        try layout.apply(.pin(tab))
        #expect(layout.activeSpace.tabs.first?.pinned == true && layout.activeSpace.tabs.first?.groupId == nil)
        try layout.apply(.group(tab, group))
        #expect(layout.activeSpace.tabs.first?.pinned == false)
        try layout.apply(.addTab(sibling))
        try layout.apply(.reorderTab(sibling, -1))
        try layout.apply(.split(tab))
        try layout.apply(.createSpace("Target"))
        let target = layout.activeSpace.id
        try layout.apply(.moveTab(tab, target))
        #expect(layout.activeSpace.tabs.first?.id == tab && layout.activeSpace.tabs.first?.groupId == nil)
        #expect(throws: WorkspaceLayout.Error.invalid) { try layout.apply(.group(tab, group)) }
        try layout.apply(.selectSpace(space))
        #expect(layout.activeSpace.split == nil && layout.activeSpace.activeTabId == sibling)
        try layout.apply(.deleteGroup(group))
        #expect(layout.activeSpace.groups.isEmpty)
    }

    @Test func rejectsDuplicateMissingAndForeignRecords() throws {
        var layout = WorkspaceLayout()
        let tab = WorkspaceTabID.fresh()
        try layout.apply(.addTab(tab))
        let original = layout
        #expect(throws: WorkspaceLayout.Error.invalid) { try layout.apply(.addTab(tab)) }
        #expect(throws: WorkspaceLayout.Error.invalid) {
            try layout.replace(expectedRevision: original.revision) { _, session in session.layouts.removeAll() }
        }
        #expect(layout == original)
        try layout.apply(.createWorkspace("Foreign"))
        let foreign = try #require(layout.catalog.workspaces.last?.id)
        try layout.apply(.selectWorkspace(foreign))
        let foreignSpace = layout.activeSpace.id
        #expect(throws: WorkspaceLayout.Error.invalid) {
            let revision = layout.revision
            try layout.replace(expectedRevision: revision) { _, session in session.layouts[0].activeSpaceId = foreignSpace }
        }
    }

    @Test func normalizesMissingOptionalRecordsInMemory() throws {
        var layout = WorkspaceLayout()
        let first = WorkspaceTabID.fresh(), second = WorkspaceTabID.fresh()
        try layout.apply(.addTab(first))
        try layout.apply(.addTab(second))
        try layout.apply(.split(first))
        let revision = layout.revision
        try layout.replace(expectedRevision: revision) { _, session in
            session.lastWorkspaceId = .fresh()
            session.layouts[0].activeSpaceId = .fresh()
            session.layouts[0].windowFrame = .init(x: 0, y: 0, width: -1, height: 800)
            session.layouts[0].spaces[0].tabs.removeFirst()
            session.layouts[0].spaces[0].tabs[0].groupId = .fresh()
            session.layouts[0].spaces[0].activeTabId = .fresh()
        }
        #expect(layout.activeSpace.activeTabId == second && layout.activeSpace.split == nil)
        #expect(layout.activeSpace.tabs.first?.groupId == nil && layout.activeLayout.windowFrame == nil)
        #expect(layout.revision == revision + 1)
    }

    @Test func migrationKeepsIDsAndRejectsUnknownOrCorruptVersions() throws {
        var layout = WorkspaceLayout()
        try layout.apply(.addTab(.fresh()))
        let data = try layout.encoded()
        var wire = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        wire["schemaVersion"] = 0
        let old = try JSONSerialization.data(withJSONObject: wire)
        let first = try WorkspaceLayout.decode(old)
        #expect(first.schemaVersion == 1 && first.revision == layout.revision + 1)
        #expect(first.catalog == layout.catalog && first.session == layout.session)
        #expect(try WorkspaceLayout.decode(old) == first)
        #expect(try WorkspaceLayout.decode(first.encoded()) == first)
        wire["schemaVersion"] = 2
        let future = try JSONSerialization.data(withJSONObject: wire)
        #expect(throws: WorkspaceLayout.Error.unsupportedVersion) { try WorkspaceLayout.decode(future) }
        #expect(throws: WorkspaceLayout.Error.capacity) { try WorkspaceLayout.decode(Data(repeating: 32, count: WorkspaceLayout.maxBytes + 1)) }
        #expect(throws: DecodingError.self) { try WorkspaceLayout.decode(Data("{".utf8)) }
    }

    @Test func staleWriterAndInterruptedEditKeepPreviousSnapshot() throws {
        var layout = WorkspaceLayout()
        let revision = layout.revision
        try layout.apply(.createWorkspace("Committed"))
        let before = layout
        #expect(throws: WorkspaceLayout.Error.staleRevision) {
            try layout.replace(expectedRevision: revision) { _, _ in Issue.record("A stale writer ran") }
        }
        let current = layout.revision
        #expect(throws: CancellationError.self) {
            try layout.replace(expectedRevision: current) { catalog, _ in
                catalog.workspaces.removeAll()
                throw CancellationError()
            }
        }
        #expect(layout == before)
        let serialized = String(decoding: try layout.encoded(), as: UTF8.self)
        for key in ["url", "title", "viewId", "storeId", "privateSessionId", "cookies", "credentials"] {
            #expect(!serialized.contains("\"\(key)\""))
        }
    }
    @Test func selectionFallbackAtEveryPosition() throws {
        for selectedIndex in 0..<3 {
            var layout = WorkspaceLayout()
            let ids = (0..<3).map { _ in WorkspaceTabID.fresh() }
            for id in ids { try layout.apply(.addTab(id)) }
            try layout.apply(.selectTab(ids[selectedIndex]))
            try layout.apply(.closeTab(ids[selectedIndex]))
            let survivors = ids.filter { $0 != ids[selectedIndex] }
            #expect(layout.activeSpace.activeTabId == survivors[min(selectedIndex, 1)])
            for id in survivors { try layout.apply(.closeTab(id)) }
            #expect(layout.activeSpace.activeTabId == nil && layout.activeSpace.tabs.isEmpty)
        }
    }

    @Test func optionalFocusRepairAndForeignTabRefusal() throws {
        var layout = WorkspaceLayout()
        let first = WorkspaceTabID.fresh(), second = WorkspaceTabID.fresh()
        try layout.apply(.addTab(first))
        try layout.apply(.addTab(second))
        try layout.apply(.split(first))
        try layout.replace(expectedRevision: layout.revision) { _, session in
            session.layouts[0].spaces[0].split?.focusedTabId = .fresh()
        }
        #expect(layout.activeSpace.split?.focusedTabId == first)
        try layout.apply(.createSpace("Foreign"))
        let foreign = WorkspaceTabID.fresh()
        try layout.apply(.addTab(foreign))
        let original = layout
        #expect(throws: WorkspaceLayout.Error.invalid) {
            try layout.replace(expectedRevision: original.revision) { _, session in
                session.layouts[0].spaces[0].split?.focusedTabId = foreign
            }
        }
        #expect(layout == original)
        let missing = WorkspaceSpaceID.fresh()
        #expect(throws: WorkspaceLayout.Error.invalid) { try layout.apply(.moveTab(first, missing)) }
    }

}
