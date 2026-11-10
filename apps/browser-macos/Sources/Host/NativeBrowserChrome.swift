import SwiftUI
import AppKit
import BrowserDomain

/// Native presentation state only. All commands still execute under the controller's
/// serialized lifecycle and Core/WebKit authority. Nothing here is persisted.
@MainActor final class NativeChromeModel: ObservableObject {
    @Published var state: ChromeState?
    @Published var message: String?
    @Published var preview: ChromeMiniPreview?
    @Published var focusAddress = 0
    @Published var commands = false
    @Published var settings = false
    @Published var sidebarVisible = true
    @Published var showsWebContent = false
    @Published var managesBookmarks = false
    @Published var bookmarks: [Bookmark] = []
    var execute: ((ChromeCommand) async -> ChromeResult?)?
    struct Bookmark: Identifiable {
        var id = UUID()
        var title: String
        var url: String
        var folder = "Favorites"
    }
    var selectedTab: ChromeTab? { state?.tabs.first { $0.id == state?.selected } }
    func send(_ type: ChromeCommand.Kind, tab: String? = nil, target: String? = nil,
              name: String? = nil, url: String? = nil, offset: Int? = nil, appearance: ChromeAppearance? = nil) {
        let command = ChromeCommand(version: 1, id: UUID().uuidString, type: type,
            tab: tab.flatMap(UUID.init(uuidString:)), url: url, value: appearance, offset: offset,
            target: target.flatMap(UUID.init(uuidString:)), name: name, visible: nil, left: nil, top: nil)
        Task { @MainActor [weak self] in
            guard let self, let execute else { return }
            guard let result = await execute(command) else { return }
            if result.error == nil, (type == .startPrivate || type == .newTab) { focusAddress += 1 }
            if result.state.session == "inactive" { bookmarks.removeAll() }
            if let error = result.error {
                switch error {
                case .transferUnconfirmed:
                    message = "The destination did not confirm this handoff. Mini remains available."
                case .busy:
                    message = "The browser is finishing another action. Try again in a moment."
                default:
                    message = "The browser could not finish this action."
                }
            }
            if let preview = result.miniPreview { self.preview = preview }
        }
    }
    func navigate(_ input: String) {
        guard let url = NativeNavigationInput.destination(input), let selected = state?.selected else {
            message = "Enter a supported address or search query."; return
        }
        send(.navigate, tab: selected, url: url.absoluteString)
    }
    func bookmarkCurrent() {
        guard let tab = selectedTab, let url = tab.url, bookmarks.count < 100,
              !bookmarks.contains(where: { $0.url == url }) else { return }
        bookmarks.append(Bookmark(title: tab.title, url: url))
    }
}

@MainActor struct NativeBrowserChrome: View {
    @ObservedObject var model: NativeChromeModel
    @State private var address = ""
    @State private var query = ""
    @State private var bookmarkFilter = ""
    @State private var bookmarkDraft: NativeChromeModel.Bookmark?
    @State private var editor: EditRequest?
    @State private var deletion: DeleteRequest?
    @State private var dragToken = UUID()
    @FocusState private var addressFocused: Bool
    private struct EditRequest: Identifiable {
        let id = UUID(); let title: String; let kind: ChromeCommand.Kind; let target: String?; var value: String
    }
    private struct DeleteRequest: Identifiable {
        let id = UUID(); let title: String; let kind: ChromeCommand.Kind; let target: String
    }
    var body: some View {
        Group {
            if let state = model.state {
                VStack(spacing: 0) {
                    toolbar(state)
                    Divider()
                    HStack(spacing: 0) {
                        if !state.mini && model.sidebarVisible { sidebar(state).frame(width: 236); Divider() }
                        content(state).frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    Divider()
                    HStack {
                        Label(state.session == "inactive" ? "Private browsing is inactive" : "Private · memory only", systemImage: "hand.raised")
                        Spacer()
                        if state.splitCompact && !state.split.isEmpty { Text("Split · focused pane") }
                        Text("Protected profiles unavailable").foregroundStyle(.secondary)
                    }.font(.caption).padding(.horizontal, 12).frame(height: 28)
                }
                .background(.background)
                .sheet(isPresented: $model.commands) { commandSheet(state) }
                .sheet(isPresented: $model.settings) { settingsSheet(state) }
                .sheet(isPresented: $model.managesBookmarks) { bookmarkSheet(state) }
                .sheet(item: $editor) { request in nameEditor(request) }
                .sheet(item: $deletion) { request in deleteEditor(request) }
                .sheet(item: Binding(get: { model.preview.map(PreviewItem.init) }, set: { if $0 == nil { model.preview = nil } })) { item in
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Open in main workspace?").font(.title2.bold())
                        Text(item.preview.url).textSelection(.enabled).lineLimit(4)
                        Text("\(item.preview.workspace) › \(item.preview.space) · independent private destination")
                        Text("Only this eligible link is sent. Mini's cookies, sign-in and page state stay in Mini.").foregroundStyle(.secondary)
                        HStack { Button("Cancel", role: .cancel) { model.preview = nil }; Spacer(); Button("Open link") {
                            model.send(.miniTransfer, target: item.preview.token.uuidString); model.preview = nil
                        }.keyboardShortcut(.defaultAction) }
                    }.padding(24).frame(width: 470)
                }
            } else { ProgressView("Preparing browser…") }
        }
        .onChange(of: model.state?.sessionID) { _, _ in
            model.managesBookmarks = false
            bookmarkDraft = nil
            bookmarkFilter = ""
        }
        .onChange(of: model.focusAddress) { _, _ in
            address = model.selectedTab?.url ?? ""; addressFocused = true
        }
        .onChange(of: model.state?.selected) { _, _ in address = model.selectedTab?.url ?? "" }
        .onChange(of: model.selectedTab?.url) { _, value in if !addressFocused { address = value ?? "" } }
        .alert("Browser action unavailable", isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })) {
            Button("OK") { model.message = nil }
        } message: { Text(model.message ?? "") }
    }
    private struct PreviewItem: Identifiable { let preview: ChromeMiniPreview; var id: UUID { preview.token }; init(_ preview: ChromeMiniPreview) { self.preview = preview } }
    private func tool(_ label: String, _ icon: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).frame(width: 22, height: 22) }
            .buttonStyle(.borderless).help(label).accessibilityLabel(label).disabled(!enabled)
    }
    private func toolbar(_ state: ChromeState) -> some View {
        HStack(spacing: 10) {
            Text(state.mini ? "V" : "VEZHAM").font(.system(size: state.mini ? 24 : 15, weight: .heavy, design: .rounded)).foregroundStyle(.orange)
            if !state.mini {
                tool(model.sidebarVisible ? "Hide sidebar" : "Show sidebar", "sidebar.left") { model.sidebarVisible.toggle() }
            }
            tool("Back", "chevron.left", enabled: model.selectedTab?.back == true) { model.send(.back, tab: state.selected) }
            tool("Forward", "chevron.right", enabled: model.selectedTab?.forward == true) { model.send(.forward, tab: state.selected) }
            tool(model.selectedTab?.loading == true ? "Stop loading" : "Reload", model.selectedTab?.loading == true ? "xmark" : "arrow.clockwise", enabled: model.selectedTab?.url != nil) {
                model.send(model.selectedTab?.loading == true ? .stop : .reload, tab: state.selected)
            }
            HStack(spacing: 8) {
                Image(systemName: model.selectedTab?.connection == "encrypted" ? "lock" : "globe").foregroundStyle(.secondary).accessibilityLabel("Connection: \(model.selectedTab?.connection ?? "unknown")")
                TextField("Search or enter an address", text: $address).textFieldStyle(.plain)
                    .focused($addressFocused).onSubmit { model.navigate(address); addressFocused = false }
                    .accessibilityIdentifier("native-address").accessibilityLabel("Address and search")
                if model.selectedTab?.loading == true { ProgressView().controlSize(.small) }
            }.padding(9).background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
            .disabled(state.session == "inactive" || state.recovery != nil)
            if state.mini {
                tool("Preview destination in main workspace", "arrow.up.forward.app", enabled: state.miniEligible) { model.send(.miniTransferPreview) }
            } else {
                tool("New tab", "plus", enabled: state.session != "inactive") { model.send(.newTab) }
                tool("Command bar", "command") { model.commands = true }
                Menu {
                    Button("Add temporary bookmark") { model.bookmarkCurrent() }.disabled(model.selectedTab?.url == nil)
                    ForEach(model.bookmarks) { bookmark in Button(bookmark.title) { model.navigate(bookmark.url) } }
                    Divider()
                    Button("Manage temporary bookmarks…") { model.managesBookmarks = true }.disabled(state.session == "inactive")
                } label: { Image(systemName: "bookmark") }.menuStyle(.borderlessButton).fixedSize().help("Temporary bookmarks")
                tool("Settings", "gearshape") { model.settings = true }
            }
        }.padding(.horizontal, 14).frame(height: 70)
    }
    private func sidebar(_ state: ChromeState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Menu {
                    ForEach(state.workspaces, id: \.id) { workspace in
                        Button(workspace.name) { model.send(.workspaceSwitch, target: workspace.id) }
                    }
                    Divider()
                    Button("New workspace…") { edit("New workspace", .workspaceCreate) }
                    Button("Rename workspace…") { edit("Rename workspace", .workspaceRename, state.activeWorkspace, state.workspaces.first { $0.id == state.activeWorkspace }?.name ?? "") }
                    Button("Move workspace earlier") { model.send(.workspaceMove, target: state.activeWorkspace, offset: -1) }
                    Button("Move workspace later") { model.send(.workspaceMove, target: state.activeWorkspace, offset: 1) }
                    Button("Delete empty workspace…", role: .destructive) { deletion = DeleteRequest(title: "Delete this empty workspace?", kind: .workspaceDelete, target: state.activeWorkspace) }
                        .disabled(state.workspaces.count < 2 || state.workspaces.first { $0.id == state.activeWorkspace }?.empty != true)
                } label: { Label(state.workspaces.first { $0.id == state.activeWorkspace }?.name ?? "Workspace", systemImage: "square.stack") }
                .disabled(state.session == "inactive")
                Spacer()
            }
            HStack {
                Picker("Space", selection: Binding(get: { state.activeSpace }, set: { model.send(.spaceSwitch, target: $0) })) {
                    ForEach(state.spaces, id: \.id) { Text($0.name).tag($0.id) }
                }.labelsHidden().accessibilityLabel("Space")
                Menu {
                    Button("New Space…") { edit("New Space", .spaceCreate) }
                    Button("Rename Space…") { edit("Rename Space", .spaceRename, state.activeSpace, state.spaces.first { $0.id == state.activeSpace }?.name ?? "") }
                    Button("Delete empty Space…", role: .destructive) { deletion = DeleteRequest(title: "Delete this empty Space?", kind: .spaceDelete, target: state.activeSpace) }
                        .disabled(state.spaces.count < 2 || state.tabs.contains { $0.space == state.activeSpace })
                    Divider(); Button("New group…") { edit("New group", .groupCreate) }
                } label: { Image(systemName: "ellipsis.circle") }.menuStyle(.borderlessButton).fixedSize()
            }.disabled(state.session == "inactive")
            List(selection: Binding(get: { state.selected }, set: { if let id = $0 { model.send(.activateKeepingChromeFocus, tab: id) } })) {
                let current = state.tabs.filter { $0.space == state.activeSpace }
                if current.contains(where: \.pinned) {
                    Section("Pinned") { ForEach(current.filter(\.pinned), id: \.id) { tabRow($0, state) } }
                }
                Section("Tabs") { ForEach(current.filter { !$0.pinned && $0.group == nil }, id: \.id) { tabRow($0, state) } }
                ForEach(state.groups.filter { $0.space == state.activeSpace }, id: \.id) { group in
                    Section {
                        if !group.collapsed { ForEach(current.filter { $0.group == group.id }, id: \.id) { tabRow($0, state) } }
                    } header: {
                        Button { model.send(.groupToggle, target: group.id) } label: { Label(group.name, systemImage: group.collapsed ? "chevron.right" : "chevron.down") }
                        .buttonStyle(.plain).accessibilityLabel("\(group.collapsed ? "Expand" : "Collapse") group \(group.name)")
                        .contextMenu {
                            Button("Rename…") { edit("Rename group", .groupRename, group.id, group.name) }
                            Button("Move earlier") { model.send(.groupMove, target: group.id, offset: -1) }
                            Button("Move later") { model.send(.groupMove, target: group.id, offset: 1) }
                            Button("Ungroup tabs") { model.send(.groupDelete, target: group.id) }
                        }
                    }
                }
            }.listStyle(.sidebar).scrollContentBackground(.hidden).accessibilityIdentifier("native-tabs")
            Button { model.send(state.session == "inactive" ? .startPrivate : .newTab) } label: { Label(state.session == "inactive" ? "Start private session" : "New tab", systemImage: "plus") }.buttonStyle(.plain)
            if !state.split.isEmpty {
                HStack { ForEach(state.split, id: \.self) { id in Button(state.tabs.first { $0.id == id }?.title ?? "Pane") { model.send(.activate, tab: id) }.lineLimit(1) } }
                Button("Close Split Screen") { model.send(.unsplit) }
            }
            Spacer(minLength: 0)
            Button("End private session", role: .destructive) {
                deletion = DeleteRequest(title: "End this private session and clear its workspace?", kind: .endPrivate, target: "")
            }.disabled(state.session == "inactive")
        }.padding(14).background(.regularMaterial)
    }
    private func tabRow(_ tab: ChromeTab, _ state: ChromeState) -> some View {
        HStack {
            Image(systemName: tab.pinned ? "pin.fill" : state.split.contains(tab.id) ? "rectangle.split.2x1" : "globe")
                .accessibilityHidden(true)
            Text(tab.title).lineLimit(1).accessibilityValue(tab.pinned ? "Pinned" : "")
            Spacer(minLength: 0)
            if tab.loading { ProgressView().controlSize(.mini) }
            Button { model.send(.close, tab: tab.id) } label: { Image(systemName: "xmark").font(.caption) }.buttonStyle(.borderless).accessibilityLabel("Close \(tab.title)")
        }.tag(tab.id)
        .accessibilityIdentifier("native-tab-\(tab.id)")
        .contextMenu {
            Button("Select") { model.send(.activate, tab: tab.id) }
            Button(tab.pinned ? "Unpin" : "Pin") { model.send(.pin, tab: tab.id) }
            Button("Duplicate") { model.send(.duplicate, tab: tab.id) }
            Button("Move earlier") { model.send(.move, tab: tab.id, offset: -1) }
            Button("Move later") { model.send(.move, tab: tab.id, offset: 1) }
            Menu("Move to Space") { ForEach(state.spaces, id: \.id) { space in Button(space.name) { model.send(.tabSpace, tab: tab.id, target: space.id) } } }
            Menu("Group") {
                Button("None") { model.send(.tabGroup, tab: tab.id) }
                ForEach(state.groups.filter { $0.space == tab.space }, id: \.id) { group in Button(group.name) { model.send(.tabGroup, tab: tab.id, target: group.id) } }
            }
            Button("Split with selected tab") { model.send(.split, tab: tab.id) }.disabled(state.selected == tab.id)
            Button("Open in Mini") { model.send(.miniOpen, tab: tab.id) }.disabled(tab.url == nil)
            Button("Copy address") { model.send(.copy, tab: tab.id) }.disabled(tab.url == nil)
            Divider(); Button("Close", role: .destructive) { model.send(.close, tab: tab.id) }
        }
        .draggable("\(dragToken.uuidString)/\(tab.id)")
        .dropDestination(for: String.self) { items, _ in
            guard items.count == 1, let value = items.first else { return false }
            let pieces = value.split(separator: "/", omittingEmptySubsequences: false)
            guard pieces.count == 2, pieces[0] == dragToken.uuidString,
                  let from = state.tabs.firstIndex(where: { $0.id == pieces[1] }),
                  let to = state.tabs.firstIndex(where: { $0.id == tab.id }),
                  state.tabs[from].space == tab.space, from != to else { return false }
            model.send(.move, tab: state.tabs[from].id, offset: to - from)
            return true
        }
    }
    private func content(_ state: ChromeState) -> some View {
        VStack(spacing: 18) {
            if let recovery = state.recovery {
                Image(systemName: "arrow.clockwise.circle").font(.system(size: 44)).foregroundStyle(.orange)
                Text(recovery == .ready ? "Ready for a fresh private session" : recovery == .failed ? "Browser content is unavailable" : "Closing interrupted content…").font(.title2)
                Text("Private page data will not be restored. Logical tabs stay available after confirmed cleanup.").foregroundStyle(.secondary).multilineTextAlignment(.center)
                if recovery == .ready { Button("Recover private session") { model.send(.recoverPrivate) }.buttonStyle(.borderedProminent) }
            } else if model.showsWebContent {
                Color.clear.accessibilityHidden(true)
            } else {
                Text("V").font(.system(size: 64, weight: .heavy, design: .rounded)).foregroundStyle(.orange)
                Text(state.session == "inactive" ? "Your next idea." : "Where to?").font(.largeTitle.bold())
                Text(state.session == "inactive" ? "A fresh private workspace. Nothing to restore." : "Enter an address or search from the toolbar.").foregroundStyle(.secondary)
                if state.session == "inactive" { Button("Start private session") { model.send(.startPrivate) }.buttonStyle(.borderedProminent) }
                else if model.selectedTab?.failure != nil { Label("This page could not load. Edit the address or try Reload.", systemImage: "exclamationmark.triangle") }
            }
        }.padding(30).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private func edit(_ title: String, _ kind: ChromeCommand.Kind, _ target: String? = nil, _ value: String = "") { editor = EditRequest(title: title, kind: kind, target: target, value: value) }
    private func nameEditor(_ request: EditRequest) -> some View {
        NativeNameEditor(title: request.title, initial: request.value) { value in model.send(request.kind, target: request.target, name: value); editor = nil } cancel: { editor = nil }
    }
    private func deleteEditor(_ request: DeleteRequest) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(request.title).font(.title2)
            Text("This action cannot be undone within this session.").foregroundStyle(.secondary)
            HStack { Button("Cancel", role: .cancel) { deletion = nil }; Spacer(); Button("Confirm", role: .destructive) { model.send(request.kind, target: request.target); deletion = nil } }
        }.padding(24).frame(width: 430)
    }
    private func commandSheet(_ state: ChromeState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Command bar").font(.title2.bold())
            TextField("Search tabs or enter an address", text: $query).textFieldStyle(.roundedBorder).onSubmit { model.navigate(query); model.commands = false }
            List {
                ForEach(state.tabs.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || ($0.url?.localizedCaseInsensitiveContains(query) == true) }, id: \.id) { tab in
                    Button(tab.title) { model.send(.activate, tab: tab.id); model.commands = false }
                }
                if !query.isEmpty { Button("Go or search: \(query)") { model.navigate(query); model.commands = false } }
                Button("New tab") { model.send(.newTab); model.commands = false }.disabled(state.session == "inactive")
                Button("Settings") { model.commands = false; model.settings = true }
            }.frame(height: 260)
            Button("Done", role: .cancel) { model.commands = false }
        }.padding(22).frame(width: 500)
    }
    private func bookmarkSheet(_ state: ChromeState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Temporary bookmarks").font(.title2.bold())
            Text("Bookmarks clear when this private session ends.").foregroundStyle(.secondary)
            if let draft = bookmarkDraft {
                NativeBookmarkEditor(bookmark: draft) { updated in
                    guard model.state?.sessionID == state.sessionID else { bookmarkDraft = nil; return }
                    if let index = model.bookmarks.firstIndex(where: { $0.id == updated.id }) {
                        model.bookmarks[index] = updated
                    } else if model.bookmarks.count < 100 {
                        model.bookmarks.append(updated)
                    }
                    bookmarkDraft = nil
                } cancel: { bookmarkDraft = nil }
                .id(draft.id)
            } else {
                TextField("Filter bookmarks", text: $bookmarkFilter)
                List(model.bookmarks.filter {
                    bookmarkFilter.isEmpty || "\($0.title) \($0.url) \($0.folder)".localizedCaseInsensitiveContains(bookmarkFilter)
                }) { bookmark in
                    HStack {
                        Button(bookmark.title) { model.navigate(bookmark.url); model.managesBookmarks = false }
                        Text(bookmark.folder).foregroundStyle(.secondary)
                        Spacer()
                        Menu("Actions") {
                            Button("Edit") { bookmarkDraft = bookmark }
                            Button("Move earlier") { moveBookmark(bookmark.id, offset: -1) }
                            Button("Move later") { moveBookmark(bookmark.id, offset: 1) }
                            Button("Remove", role: .destructive) { model.bookmarks.removeAll { $0.id == bookmark.id } }
                        }.fixedSize()
                    }
                }.frame(height: 200)
                Button("Add bookmark…") {
                    bookmarkDraft = NativeChromeModel.Bookmark(title: model.selectedTab?.title ?? "", url: model.selectedTab?.url ?? "")
                }.disabled(model.bookmarks.count >= 100)
            }
            Button("Done", role: .cancel) { model.managesBookmarks = false }
        }.padding(24).frame(width: 480)
        .onDisappear { bookmarkDraft = nil; bookmarkFilter = "" }
    }

    private func moveBookmark(_ id: UUID, offset: Int) {
        guard let index = model.bookmarks.firstIndex(where: { $0.id == id }),
              model.bookmarks.indices.contains(index + offset) else { return }
        model.bookmarks.swapAt(index, index + offset)
    }

    private func settingsSheet(_ state: ChromeState) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Settings").font(.title2.bold())
            Picker("Appearance", selection: Binding(get: { state.appearance }, set: { model.send(.appearance, appearance: $0) })) {
                Text("System").tag(ChromeAppearance.system); Text("Light").tag(ChromeAppearance.light); Text("Dark").tag(ChromeAppearance.dark)
            }.pickerStyle(.segmented)
            Text("Private workspaces and temporary bookmarks clear when the session ends. Protected persistent profiles, history and downloads remain unavailable.").foregroundStyle(.secondary)
            Button("Done", role: .cancel) { model.settings = false }
        }.padding(24).frame(width: 470)
    }
}

@MainActor private struct NativeNameEditor: View {
    let title: String
    @State var value: String
    let save: (String) -> Void
    let cancel: () -> Void
    @FocusState private var focused: Bool
    init(title: String, initial: String, save: @escaping (String) -> Void, cancel: @escaping () -> Void) {
        self.title = title; _value = State(initialValue: initial); self.save = save; self.cancel = cancel
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title).font(.title2)
            TextField("Name", text: $value).textFieldStyle(.roundedBorder).focused($focused).onSubmit { if valid { save(value) } }
            HStack { Button("Cancel", role: .cancel, action: cancel); Spacer(); Button("Save") { save(value) }.disabled(!valid).keyboardShortcut(.defaultAction) }
        }.padding(24).frame(width: 400).onAppear { focused = true }
    }
    private var valid: Bool { !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && value.count <= 40 && !value.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) } }
}


@MainActor private struct NativeBookmarkEditor: View {
    @State var bookmark: NativeChromeModel.Bookmark
    let save: (NativeChromeModel.Bookmark) -> Void
    let cancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Name", text: $bookmark.title)
            TextField("Address", text: $bookmark.url)
            TextField("Folder", text: $bookmark.folder)
            HStack {
                Button("Cancel", action: cancel)
                Spacer()
                Button("Save") {
                    guard let url = destination else { return }
                    var updated = bookmark
                    updated.url = url.absoluteString
                    save(updated)
                }.disabled(destination == nil || bookmark.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var destination: URL? {
        NativeNavigationInput.destination(bookmark.url)
    }
}
