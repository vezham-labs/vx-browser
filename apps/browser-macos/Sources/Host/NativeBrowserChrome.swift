import SwiftUI
import AppKit
import BrowserDomain

enum BrowserChromeMetrics {
    static let toolbarHeight: CGFloat = 70
    static let footerHeight: CGFloat = 28
    static let separator: CGFloat = 1
    static let sidebarDefault: CGFloat = 236
    static let sidebarRange: ClosedRange<CGFloat> = 180...320
    static let sidebarHandle: CGFloat = 8
    static let dialogWidth: CGFloat = 640
    static let contentInset: CGFloat = 8
    static let compactToolbarHeight: CGFloat = 44
    static let horizontalPadding: CGFloat = 14
    static let controlRadius: CGFloat = 9
}

enum NativeBrowserMenuAction: Int {
    case newTab, commandBar, focusAddress, sidebar, back, forward, reload, stop, copyAddress, openMini, bookmarks, settings, welcome
}

/// Native presentation state only. All commands still execute under the controller's
/// serialized lifecycle and Core/WebKit authority. Nothing here is persisted.
@MainActor final class NativeChromeModel: ObservableObject {
    @Published var state: ChromeState?
    @Published var message: String?
    @Published var preview: ChromeMiniPreview?
    @Published var focusAddress = 0
    @Published var commands = false
    @Published var settings = false
    @Published var sidebarVisible = true {
        didSet { geometryChanged?() }
    }
    @Published private(set) var sidebarWidth = BrowserChromeMetrics.sidebarDefault {
        didSet { geometryChanged?() }
    }
    @Published var onboarding = false
    var geometryChanged: (() -> Void)?
    private static let onboardingKey = "VezhamWelcomeCompletedV1"

    func setSidebarWidth(_ width: CGFloat) {
        guard width.isFinite else { return }
        let bounds = BrowserChromeMetrics.sidebarRange
        let clamped = min(bounds.upperBound, max(bounds.lowerBound, width))
        if sidebarWidth != clamped { sidebarWidth = clamped }
    }

    private var usesWelcomePreference: Bool {
        if Bundle.main.bundleIdentifier == "internal.vezham.browser.foundation" { return true }
        #if DEBUG
        return Bundle.main.bundleIdentifier == "internal.vezham.browser.parity.qualification"
        #else
        return false
        #endif
    }

    func showWelcomeIfNeeded() {
        guard usesWelcomePreference,
              !UserDefaults.standard.bool(forKey: Self.onboardingKey) else { return }
        onboarding = true
    }

    func completeWelcome() {
        if usesWelcomePreference {
            UserDefaults.standard.set(true, forKey: Self.onboardingKey)
        }
        onboarding = false
    }
    @Published var showsWebContent = false
    @Published var managesBookmarks = false
    @Published var bookmarks = PrivateBookmarks()
    var execute: ((ChromeCommand) async -> ChromeResult?)?
    typealias Bookmark = PrivateBookmarks.Link
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
    func navigate(_ input: String, inNewTab: Bool = false) {
        guard let url = NativeNavigationInput.destination(input) else {
            message = "Enter a supported address or search query."; return
        }
        if inNewTab || state?.selected == nil {
            send(.navigateInNewTab, url: url.absoluteString)
        } else {
            send(.navigate, tab: state?.selected, url: url.absoluteString)
        }
    }
    func bookmarkCurrent(favorite: Bool = false) {
        guard state?.sessionID != nil, state?.recovery == nil, let tab = selectedTab, let url = tab.url else { return }
        if var link = bookmarks.links.first(where: { $0.url == url }) {
            if favorite { link.favorite = true; bookmarks.save(link) }
        } else {
            bookmarks.save(Bookmark(title: tab.title, url: url, favorite: favorite))
        }
    }

    func openBookmark(_ id: UUID) {
        guard state?.sessionID != nil, state?.recovery == nil,
              let link = bookmarks.links.first(where: { $0.id == id }),
              let url = PrivateBookmarks.destination(link.url) else { return }
        send(.navigateInNewTab, url: url.absoluteString)
    }
}

@MainActor struct NativeBrowserChrome: View {
    @ObservedObject var model: NativeChromeModel
    @State private var address = ""
    @State private var sidebarDragOrigin: CGFloat?
    @State private var showWelcomeAfterSettings = false
    @State private var showSettingsAfterCommands = false
    @State private var bookmarkFilter = ""
    @State private var bookmarkDraft: NativeChromeModel.Bookmark?
    @State private var editor: EditRequest?
    @State private var deletion: DeleteRequest?
    @State private var dropTarget: String?
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
                    if state.mini || !model.sidebarVisible {
                        toolbar(state).frame(height: BrowserChromeMetrics.compactToolbarHeight)
                    }
                    HStack(spacing: 0) {
                        if !state.mini && model.sidebarVisible {
                            sidebar(state)
                                .frame(width: model.sidebarWidth)
                                .overlay(alignment: .trailing) { sidebarResizeHandle }
                        }
                        content(state)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.background, in: RoundedRectangle(cornerRadius: BrowserChromeMetrics.controlRadius))
                            .padding(BrowserChromeMetrics.contentInset)
                    }
                    if state.mini {
                        Text("Private · memory only")
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(height: BrowserChromeMetrics.footerHeight)
                    }
                }
                .background(.background)
                .sheet(isPresented: $model.commands, onDismiss: {
                    if showSettingsAfterCommands {
                        showSettingsAfterCommands = false
                        model.settings = true
                    }
                }) {
                    NativeCommandPalette(model: model, openSettings: { showSettingsAfterCommands = true })
                }
                .sheet(isPresented: $model.onboarding) { welcomeSheet(state) }
                .sheet(isPresented: $model.settings, onDismiss: {
                    if showWelcomeAfterSettings {
                        showWelcomeAfterSettings = false
                        model.onboarding = true
                    }
                }) { settingsSheet(state) }
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
        .ignoresSafeArea()
        .onChange(of: model.state?.sessionID) { _, _ in
            model.managesBookmarks = false
            bookmarkDraft = nil
            bookmarkFilter = ""
        }
        .onChange(of: model.focusAddress) { _, _ in
            address = model.selectedTab?.url ?? ""
            addressFocused = false
            Task { @MainActor in
                // The address field may have just moved from the collapsed toolbar
                // into the sidebar. Give SwiftUI a turn to mount its new focus target.
                await Task.yield()
                addressFocused = true
            }
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
            Spacer().frame(width: 64)
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
            }.padding(9).background(.quaternary, in: RoundedRectangle(cornerRadius: BrowserChromeMetrics.controlRadius))
            .disabled(state.session == "inactive" || state.recovery != nil)
            if state.mini {
                tool("Preview destination in main workspace", "arrow.up.forward.app", enabled: state.miniEligible) { model.send(.miniTransferPreview) }
            } else {
                tool("New tab", "plus", enabled: state.session != "inactive") { model.send(.newTab) }
                tool("Command bar", "command") { model.commands = true }
                Menu {
                    Button("Add temporary bookmark") { model.bookmarkCurrent() }.disabled(model.selectedTab?.url == nil)
                    Button("Add temporary favorite") { model.bookmarkCurrent(favorite: true) }.disabled(model.selectedTab?.url == nil)
                    ForEach(model.bookmarks.links) { bookmark in Button(bookmark.title) { model.openBookmark(bookmark.id) } }
                    Divider()
                    Button("Manage temporary bookmarks…") { model.managesBookmarks = true }.disabled(state.session == "inactive")
                } label: { Image(systemName: "bookmark") }.menuStyle(.borderlessButton).fixedSize().help("Temporary bookmarks")
                tool("Settings", "gearshape") { model.settings = true }
            }
        }.padding(.horizontal, BrowserChromeMetrics.horizontalPadding).frame(height: BrowserChromeMetrics.compactToolbarHeight)
    }
    private func sidebar(_ state: ChromeState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                Spacer(minLength: 64)
                tool("Hide sidebar", "sidebar.left") { model.sidebarVisible = false }
                Spacer(minLength: 0)
                tool("Back", "chevron.left", enabled: model.selectedTab?.back == true) { model.send(.back, tab: state.selected) }
                tool("Forward", "chevron.right", enabled: model.selectedTab?.forward == true) { model.send(.forward, tab: state.selected) }
                tool(model.selectedTab?.loading == true ? "Stop loading" : "Reload", model.selectedTab?.loading == true ? "xmark" : "arrow.clockwise", enabled: model.selectedTab?.url != nil) {
                    model.send(model.selectedTab?.loading == true ? .stop : .reload, tab: state.selected)
                }
            }.frame(height: 34)
            HStack(spacing: 6) {
                Image(systemName: model.selectedTab?.connection == "encrypted" ? "lock" : "magnifyingglass")
                    .font(.caption).foregroundStyle(.secondary)
                    .accessibilityLabel("Connection: \(model.selectedTab?.connection ?? "unknown")")
                TextField("Search or enter an address", text: $address)
                    .textFieldStyle(.plain).font(.system(size: 12))
                    .focused($addressFocused)
                    .onSubmit { model.navigate(address); addressFocused = false }
                    .accessibilityIdentifier("native-address").accessibilityLabel("Address and search")
                if model.selectedTab?.loading == true { ProgressView().controlSize(.mini) }
            }
            .padding(.horizontal, 10).frame(height: 34)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: BrowserChromeMetrics.controlRadius))
            .disabled(state.session == "inactive" || state.recovery != nil)
            if !model.bookmarks.links.filter(\.favorite).isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 6)], spacing: 6) {
                    ForEach(model.bookmarks.links.filter(\.favorite)) { savedRow($0, state) }
                }.padding(.vertical, 4)
                .accessibilityLabel("Favorites")
            }

            HStack {
                Picker("Space", selection: Binding(get: { state.activeSpace }, set: { model.send(.spaceSwitch, target: $0) })) {
                    ForEach(state.spaces, id: \.id) { Text($0.name).tag($0.id) }
                }.labelsHidden().accessibilityLabel("Space")
                Menu {
                    Menu("Workspace") {
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
                    }
                    Divider()
                    Button("New Space…") { edit("New Space", .spaceCreate) }
                    Button("Rename Space…") { edit("Rename Space", .spaceRename, state.activeSpace, state.spaces.first { $0.id == state.activeSpace }?.name ?? "") }
                    Button("Delete empty Space…", role: .destructive) { deletion = DeleteRequest(title: "Delete this empty Space?", kind: .spaceDelete, target: state.activeSpace) }
                        .disabled(state.spaces.count < 2 || state.tabs.contains { $0.space == state.activeSpace })
                    Divider(); Button("New group…") { edit("New group", .groupCreate) }
                    Divider()
                    Button("Add temporary bookmark") { model.bookmarkCurrent() }.disabled(model.selectedTab?.url == nil)
                    Button("Add temporary favorite") { model.bookmarkCurrent(favorite: true) }.disabled(model.selectedTab?.url == nil)
                    Button("Manage temporary bookmarks…") { model.managesBookmarks = true }
                } label: { Image(systemName: "ellipsis.circle") }.menuStyle(.borderlessButton).fixedSize()
            }.disabled(state.session == "inactive")
            Button { model.send(state.session == "inactive" ? .startPrivate : .newTab) } label: { Label(state.session == "inactive" ? "Start private session" : "New tab", systemImage: "plus") }.buttonStyle(.plain)
            List(selection: Binding(get: { state.selected }, set: { if let id = $0 { model.send(.activateKeepingChromeFocus, tab: id) } })) {
                let current = state.tabs.filter { $0.space == state.activeSpace }
                savedLinks(state)
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
            if !state.split.isEmpty {
                HStack { ForEach(state.split, id: \.self) { id in Button(state.tabs.first { $0.id == id }?.title ?? "Pane") { model.send(.activate, tab: id) }.lineLimit(1) } }
                Button("Close Split Screen") { model.send(.unsplit) }
            }
            Spacer(minLength: 0)
            Button("End private session", role: .destructive) {
                deletion = DeleteRequest(title: "End this private session and clear its workspace?", kind: .endPrivate, target: "")
            }.disabled(state.session == "inactive")
            HStack(spacing: 12) {
                tool("Command bar", "command") { model.commands = true }
                tool("Bookmarks", "bookmark") { model.managesBookmarks = true }
                    .disabled(state.session == "inactive")
                Spacer()
                tool("Settings", "gearshape") { model.settings = true }
            }
            Text(state.session == "inactive" ? "Private browsing is inactive" : "Private · memory only")
                .font(.caption2).foregroundStyle(.secondary)
            Text("Protected profiles unavailable").font(.caption2).foregroundStyle(.tertiary)
        }.padding(.horizontal, 8).padding(.bottom, 10).background(.regularMaterial)
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
        .draggable(dragPayload("tab", tab.id, state))
        .dropDestination(for: String.self) { items, _ in
            guard let source = dragID(items, "tab", state),
                  let from = state.tabs.firstIndex(where: { $0.id == source }),
                  let to = state.tabs.firstIndex(where: { $0.id == tab.id }), from != to,
                  state.tabs[from].space == tab.space, state.tabs[from].pinned == tab.pinned,
                  state.tabs[from].group == tab.group else { return false }
            model.send(.move, tab: source, offset: to - from)
            return true
        } isTargeted: { highlight(tab.id, $0) }
        .overlay(alignment: .top) { dropIndicator(tab.id) }
    }

    private func dragPayload(_ kind: String, _ id: String, _ state: ChromeState) -> String {
        "\(state.sessionID ?? "")/\(kind)/\(id)"
    }

    private func dragID(_ items: [String], _ kind: String, _ state: ChromeState) -> String? {
        guard items.count == 1, let value = items.first, let session = state.sessionID,
              model.state?.sessionID == session, model.state?.recovery == nil else { return nil }
        let pieces = value.split(separator: "/", omittingEmptySubsequences: false)
        guard pieces.count == 3, pieces[0] == session, pieces[1] == kind,
              UUID(uuidString: String(pieces[2])) != nil else { return nil }
        return String(pieces[2])
    }

    private func highlight(_ id: String, _ targeted: Bool) {
        if targeted { dropTarget = id }
        else if dropTarget == id { dropTarget = nil }
    }

    @ViewBuilder private func dropIndicator(_ id: String) -> some View {
        if dropTarget == id { Rectangle().fill(Color.accentColor).frame(height: 2).allowsHitTesting(false) }
    }

    @ViewBuilder private func savedLinks(_ state: ChromeState) -> some View {
        let links = model.bookmarks.links
        let ordinary = links.filter { !$0.favorite }
        if !ordinary.isEmpty {
            Section("Bookmarks") {
                ForEach(ordinary.filter { $0.folder.isEmpty }) { savedRow($0, state) }
                ForEach(Array(Set(ordinary.map(\.folder).filter { !$0.isEmpty })).sorted(), id: \.self) { folder in
                    DisclosureGroup {
                        ForEach(ordinary.filter { $0.folder == folder }) { savedRow($0, state) }
                    } label: {
                        Label(folder, systemImage: "folder")
                            .dropDestination(for: String.self) { items, _ in
                                guard let raw = dragID(items, "link", state), let id = UUID(uuidString: raw) else { return false }
                                return model.bookmarks.move(id, toFolder: folder)
                            } isTargeted: { highlight("folder-" + folder, $0) }
                            .overlay(alignment: .top) { dropIndicator("folder-" + folder) }
                    }
                }
            }
        }
    }

    private func savedRow(_ link: NativeChromeModel.Bookmark, _ state: ChromeState) -> some View {
        let id = link.id.uuidString
        return Button { model.openBookmark(link.id) } label: {
            Group {
                if link.favorite {
                    Image(systemName: "globe")
                        .font(.system(size: 18, weight: .medium))
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: BrowserChromeMetrics.controlRadius))
                } else {
                    Label(link.title, systemImage: "bookmark")
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
            .help(link.title + "\n" + link.url)
            .accessibilityLabel((link.favorite ? "Favorite " : "Bookmark ") + link.title)
            .accessibilityIdentifier("saved-link-" + id)
            .contextMenu {
                Button("Open in new tab") { model.openBookmark(link.id) }
                Button("Edit…") { bookmarkDraft = link; model.managesBookmarks = true }
                Button(link.favorite ? "Move to Bookmarks" : "Move to Favorites") {
                    var updated = link
                    updated.favorite.toggle()
                    model.bookmarks.save(updated)
                }
                if !link.folder.isEmpty {
                    Button("Move out of folder") { model.bookmarks.move(link.id, toFolder: "") }
                }
                Button("Copy address") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(link.url, forType: .string)
                }
                Button("Remove", role: .destructive) { model.bookmarks.remove(link.id) }
            }
            .draggable(dragPayload("link", id, state))
            .dropDestination(for: String.self) { items, point in
                guard let raw = dragID(items, "link", state), let source = UUID(uuidString: raw) else { return false }
                if link.favorite, model.bookmarks.links.contains(where: { $0.id == source && $0.favorite }) {
                    return model.bookmarks.reorderFavorite(source, onto: link.id)
                }
                return model.bookmarks.move(source, beside: link.id, after: link.favorite || point.y >= 10)
            } isTargeted: { highlight(id, $0) }
            .overlay(alignment: .top) {
                if link.favorite {
                    RoundedRectangle(cornerRadius: BrowserChromeMetrics.controlRadius)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .opacity(dropTarget == id ? 1 : 0)
                        .allowsHitTesting(false)
                } else {
                    dropIndicator(id)
                }
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
                Text(state.session == "inactive" ? "A fresh private workspace. Nothing to restore." : "Search or enter an address to start browsing.").foregroundStyle(.secondary)
                if !state.mini {
                    Button("Search or open a website") { model.commands = true }
                        .keyboardShortcut("k", modifiers: .command)
                }
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
    private var sidebarResizeHandle: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: BrowserChromeMetrics.sidebarHandle)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if sidebarDragOrigin == nil { sidebarDragOrigin = model.sidebarWidth }
                    model.setSidebarWidth((sidebarDragOrigin ?? model.sidebarWidth) + value.translation.width)
                }
                .onEnded { _ in sidebarDragOrigin = nil })
            .accessibilityLabel("Sidebar width")
            .accessibilityValue("\(Int(model.sidebarWidth)) points")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: model.setSidebarWidth(model.sidebarWidth + 12)
                case .decrement: model.setSidebarWidth(model.sidebarWidth - 12)
                @unknown default: break
                }
            }
            .help("Drag to resize the sidebar")
    }

    private func welcomeSheet(_ state: ChromeState) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Welcome to Vezham", systemImage: "sparkles").font(.largeTitle.bold())
            Text("A native browser with Spaces for organizing your tabs.").foregroundStyle(.secondary)
            Label("Use the sidebar to pin, group and move tabs between Spaces.", systemImage: "sidebar.left")
            Label("Press ⌘T to search tabs, Spaces and actions, or open a new address.", systemImage: "command")
            Label("Private tabs and bookmarks clear when you end the session.", systemImage: "hand.raised")
            Text("Searches use DuckDuckGo. Protected profiles and workspace restoration are unavailable.")
                .foregroundStyle(.secondary)
            appearancePicker(state)
            HStack {
                Button("Skip setup") { model.completeWelcome() }
                Spacer()
                Button("Done") { model.completeWelcome() }.keyboardShortcut(.defaultAction)
            }
        }.padding(28).frame(width: BrowserChromeMetrics.dialogWidth)
    }

    private func appearancePicker(_ state: ChromeState) -> some View {
        Picker("Appearance", selection: Binding(get: { state.appearance }, set: { model.send(.appearance, appearance: $0) })) {
            Text("System").tag(ChromeAppearance.system)
            Text("Light").tag(ChromeAppearance.light)
            Text("Dark").tag(ChromeAppearance.dark)
        }.pickerStyle(.segmented)
    }
    private func bookmarkSheet(_ state: ChromeState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Temporary bookmarks").font(.title2.bold())
            Text("Bookmarks clear when this private session ends.").foregroundStyle(.secondary)
            if let draft = bookmarkDraft {
                NativeBookmarkEditor(bookmark: draft) { updated in
                    guard model.state?.sessionID == state.sessionID else { bookmarkDraft = nil; return }
                    guard model.bookmarks.save(updated) else {
                        model.message = "Enter a valid website address, name and folder."
                        return
                    }
                    bookmarkDraft = nil
                } cancel: { bookmarkDraft = nil }
                .id(draft.id)
            } else {
                TextField("Filter bookmarks", text: $bookmarkFilter)
                List(model.bookmarks.links.filter {
                    bookmarkFilter.isEmpty || "\($0.title) \($0.url) \($0.folder)".localizedCaseInsensitiveContains(bookmarkFilter)
                }) { bookmark in
                    HStack {
                        Button(bookmark.title) { model.openBookmark(bookmark.id); model.managesBookmarks = false }
                        Text(bookmark.folder).foregroundStyle(.secondary)
                        Spacer()
                        Menu("Actions") {
                            Button("Edit") { bookmarkDraft = bookmark }
                            Button("Move earlier") { moveBookmark(bookmark.id, offset: -1) }
                            Button("Move later") { moveBookmark(bookmark.id, offset: 1) }
                            Button("Remove", role: .destructive) { model.bookmarks.remove(bookmark.id) }
                        }.fixedSize()
                    }
                }.frame(height: 200)
                Button("Add bookmark…") {
                    bookmarkDraft = NativeChromeModel.Bookmark(title: model.selectedTab?.title ?? "", url: model.selectedTab?.url ?? "")
                }.disabled(model.bookmarks.links.count >= 100)
            }
            Button("Done", role: .cancel) { model.managesBookmarks = false }
        }.padding(24).frame(width: 480)
        .onDisappear { bookmarkDraft = nil; bookmarkFilter = "" }
    }

    private func moveBookmark(_ id: UUID, offset: Int) {
        let links = model.bookmarks.links
        guard let link = links.first(where: { $0.id == id }) else { return }
        let siblings = links.filter { $0.folder == link.folder && $0.favorite == link.favorite }
        guard let index = siblings.firstIndex(where: { $0.id == id }), siblings.indices.contains(index + offset) else { return }
        model.bookmarks.move(id, beside: siblings[index + offset].id, after: offset > 0)
    }

    private func settingsSheet(_ state: ChromeState) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Settings").font(.title2.bold())
            appearancePicker(state)
            Text("Search provider: DuckDuckGo").foregroundStyle(.secondary)
            Button("Show welcome") { showWelcomeAfterSettings = true; model.settings = false }
            Text("Private workspaces and temporary bookmarks clear when the session ends. Protected persistent profiles, history and downloads remain unavailable.").foregroundStyle(.secondary)
            Button("Done", role: .cancel) { model.settings = false }
        }.padding(24).frame(width: 470)
    }
}

@MainActor private struct NativeCommandPalette: View {
    @ObservedObject var model: NativeChromeModel
    let openSettings: () -> Void
    @State private var query = ""
    @State private var commandSelection = 0
    @FocusState private var commandFocused: Bool

    private struct PaletteItem: Identifiable {
        let id: String
        let label: String
        let symbol: String
        let perform: () -> Void
    }

    private func paletteItems(_ state: ChromeState) -> [PaletteItem] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        func matches(_ label: String) -> Bool { needle.isEmpty || label.localizedCaseInsensitiveContains(needle) }
        var items: [PaletteItem] = []
        if state.recovery == nil && !state.mini {
            for tab in state.tabs where matches(tab.title) || tab.url.map(matches) == true {
                items.append(PaletteItem(id: "tab-" + tab.id, label: "Switch to \(tab.title)", symbol: "rectangle.on.rectangle") {
                    model.send(.activate, tab: tab.id)
                })
            }
            if state.session != "inactive" {
                for space in state.spaces where space.id != state.activeSpace && matches(space.name) {
                    items.append(PaletteItem(id: "space-" + space.id, label: "Switch to Space \(space.name)", symbol: "square.stack") {
                        model.send(.spaceSwitch, target: space.id)
                    })
                }
            }
        }
        let actions = [
            PaletteItem(id: "new-tab", label: state.session == "inactive" ? "Start private session" : "New blank tab", symbol: "plus") {
                model.send(state.session == "inactive" ? .startPrivate : .newTab)
            },
            PaletteItem(id: "sidebar", label: model.sidebarVisible ? "Hide sidebar" : "Show sidebar", symbol: "sidebar.left") {
                model.sidebarVisible.toggle()
            }
        ]
        if state.recovery == nil && !state.mini {
            items += actions.filter { matches($0.label) }
            if let tab = model.selectedTab, tab.url != nil {
                let actions = [
                    PaletteItem(id: "copy", label: "Copy address", symbol: "doc.on.doc") { model.send(.copy, tab: tab.id) },
                    PaletteItem(id: "mini", label: "Open in Mini", symbol: "macwindow") { model.send(.miniOpen, tab: tab.id) }
                ]
                items += actions.filter { matches($0.label) }
            }
            if !needle.isEmpty, NativeNavigationInput.destination(needle) != nil {
                items.append(PaletteItem(id: "navigate", label: "Open or search in new tab", symbol: "magnifyingglass") {
                    model.navigate(needle, inNewTab: true)
                })
            }
        }
        if !state.mini && matches("Settings") {
            items.append(PaletteItem(id: "settings", label: "Settings", symbol: "gearshape", perform: openSettings))
        }
        return items
    }

    var body: some View {
        let items = model.state.map(paletteItems) ?? []
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search or enter an address", text: $query)
                .accessibilityLabel("Search tabs, Spaces, actions or the web")
                .textFieldStyle(.plain).font(.system(size: 16, weight: .medium))
                .focused($commandFocused)
                .onKeyPress(.upArrow) {
                    commandSelection = max(0, commandSelection - 1)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    commandSelection = min(max(0, items.count - 1), commandSelection + 1)
                    return .handled
                }
                .onSubmit {
                    if items.indices.contains(commandSelection) { runPaletteItem(items[commandSelection]) }
                }
            }.padding(.horizontal, 10).frame(height: 44)
            Divider()
            ScrollViewReader { scroll in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            Button { runPaletteItem(item) } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: item.symbol).frame(width: 22)
                                    Text(item.label).lineLimit(1)
                                    Spacer(minLength: 8)
                                    if index == commandSelection {
                                        Image(systemName: "arrow.turn.down.left").foregroundStyle(.secondary)
                                    }
                                }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10).frame(height: 40)
                                    .background(index == commandSelection ? Color.accentColor.opacity(0.16) : .clear,
                                                in: RoundedRectangle(cornerRadius: BrowserChromeMetrics.controlRadius))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(index == commandSelection ? [.isSelected] : [])
                            .id(item.id)
                        }
                    }
                }
                .onChange(of: commandSelection) { _, index in
                    if items.indices.contains(index) { scroll.scrollTo(items[index].id) }
                }
            }.frame(height: 240)
            if items.isEmpty { Text("No matching commands").foregroundStyle(.secondary) }
            Button("Cancel", role: .cancel) { model.commands = false }
        }.padding(10)
            .frame(width: BrowserChromeMetrics.dialogWidth)
            .onExitCommand { model.commands = false }
            .onAppear { query = ""; commandSelection = 0; commandFocused = true }
            .onChange(of: query) { _, _ in commandSelection = 0 }
            .onChange(of: items.count) { _, count in commandSelection = min(commandSelection, max(0, count - 1)) }
    }

    private func runPaletteItem(_ item: PaletteItem) {
        model.commands = false
        query = ""
        item.perform()
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
        PrivateBookmarks.destination(bookmark.url)
    }
}
