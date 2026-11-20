import SwiftUI
import AppKit
import BrowserDomain

enum BrowserChromeMetrics {
    static let toolbarHeight: CGFloat = 70
    static let footerHeight: CGFloat = 28
    static let separator: CGFloat = 1
    static let sidebarDefault: CGFloat = 288
    static let sidebarRange: ClosedRange<CGFloat> = 180...352
    static let sidebarHandle: CGFloat = 8
    static let paletteWidth: CGFloat = 760
    static let dialogWidth: CGFloat = 640
    static let contentInset: CGFloat = 8
    static let contentRadius: CGFloat = 12
    static let compactToolbarHeight: CGFloat = 44
    static let horizontalPadding: CGFloat = 14
    static let controlRadius: CGFloat = 9
    static let iconButtonSize: CGFloat = 26
    static let addressHeight: CGFloat = 32
    static let sidebarRowHeight: CGFloat = 26
    static let favoriteMinimumWidth: CGFloat = 54
    static let favoriteHeight: CGFloat = 46
    static let favoriteSpacing: CGFloat = 8
}

enum NativeBrowserMenuAction: Int {
    case newTab, commandBar, focusAddress, sidebar, back, forward, reload, stop, copyAddress, openMini, bookmarks, settings, welcome, nextSpace, previousSpace, nextTab, previousTab, duplicateTab, togglePin
}

/// Native presentation state only. All commands still execute under the controller's
/// serialized lifecycle and Core/WebKit authority. Nothing here is persisted.
@MainActor final class NativeChromeModel: ObservableObject {
    @Published var state: ChromeState?
    @Published var message: String?
    @Published var preview: ChromeMiniPreview?
    @Published var focusAddress = 0
    @Published var commands = false {
        didSet { if commands != oldValue { commandVisibilityChanged?(commands) } }
    }
    var commandVisibilityChanged: ((Bool) -> Void)?
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
    @Published var searchProvider = NativeNavigationInput.SearchProvider.duckDuckGo
    @Published var managesBookmarks = false
    @Published var bookmarks = PrivateBookmarks()
    @Published var sidebarDrop: SidebarDrop?
    lazy var sidebarDrag = NativeSidebarDrag(model: self)
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
        guard let url = NativeNavigationInput.destination(input, provider: searchProvider) else {
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

enum SidebarDragItem: Equatable {
    case tab(String)
    case link(UUID)
    case folder(String)
}

struct SidebarDrop: Equatable {
    enum Placement: Equatable { case before, after, onto }
    let item: SidebarDragItem
    let placement: Placement
}

@MainActor
final class SidebarDragAnchor: NSView {
    var item: SidebarDragItem?
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

@MainActor
private struct SidebarDragRegion: NSViewRepresentable {
    let interaction: NativeSidebarDrag
    let item: SidebarDragItem

    func makeNSView(context: Context) -> SidebarDragAnchor {
        let anchor = SidebarDragAnchor()
        interaction.register(anchor)
        return anchor
    }

    func updateNSView(_ view: SidebarDragAnchor, context: Context) {
        view.item = item
    }
}

/// Tracks an in-window pointer drag using live row geometry and a session-scoped
/// identity. No website address or sidebar item is published to the pasteboard.
@MainActor
final class NativeSidebarDrag {
    private struct Source {
        let item: SidebarDragItem
        let sessionID: String
        let spaceID: String
        let origin: NSPoint
    }

    private weak var model: NativeChromeModel?
    private let anchors = NSHashTable<SidebarDragAnchor>.weakObjects()
    private var source: Source?
    private var dragging = false

    init(model: NativeChromeModel) {
        self.model = model
    }

    fileprivate func register(_ anchor: SidebarDragAnchor) {
        anchors.add(anchor)
    }

    func cancel() {
        source = nil
        dragging = false
        if model?.sidebarDrop != nil { model?.sidebarDrop = nil }
    }

    func handle(_ event: NSEvent) -> Bool {
        if event.type == .leftMouseDown {
            cancel()
            let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
            guard modifiers.isEmpty, let model, model.sidebarVisible,
                  let state = model.state, state.recovery == nil, let session = state.sessionID,
                  let hit = hit(at: event.locationInWindow, in: event.window) else { return false }
            if case .folder = hit.item { return false }
            source = Source(item: hit.item, sessionID: session, spaceID: state.activeSpace,
                            origin: event.locationInWindow)
            return true
        }

        guard let source else { return false }
        if event.type == .keyDown, event.keyCode == 53 {
            cancel()
            return true
        }
        guard event.type == .leftMouseDragged || event.type == .leftMouseUp else { return false }
        guard let model, model.sidebarVisible, let state = model.state,
              state.sessionID == source.sessionID, state.activeSpace == source.spaceID,
              state.recovery == nil else {
            cancel()
            return true
        }

        let point = event.locationInWindow
        if hypot(point.x - source.origin.x, point.y - source.origin.y) >= 4 { dragging = true }
        let hit = hit(at: point, in: event.window)
        if dragging {
            let drop = hit.flatMap { proposedDrop(from: source.item, to: $0.item, after: $0.after, in: state) }
            if event.type == .leftMouseUp {
                cancel()
                if let drop { perform(drop, from: source.item, in: state) }
            } else if model.sidebarDrop != drop {
                model.sidebarDrop = drop
            }
        } else if event.type == .leftMouseUp {
            cancel()
            if hit?.item == source.item {
                switch source.item {
                case .tab(let id): model.send(.activateKeepingChromeFocus, tab: id)
                case .link(let id): model.openBookmark(id)
                case .folder: break
                }
            }
        }
        return true
    }

    private func hit(at point: NSPoint, in window: NSWindow?) -> (item: SidebarDragItem, after: Bool)? {
        guard let window else { return nil }
        for anchor in anchors.allObjects where anchor.window === window && !anchor.isHiddenOrHasHiddenAncestor {
            let local = anchor.convert(point, from: nil)
            // SwiftUI can give a representable a clipping rectangle larger than
            // its own layout. A point must be inside both rectangles.
            let visibleBounds = anchor.bounds.intersection(anchor.visibleRect)
            if let item = anchor.item, visibleBounds.contains(local) {
                return (item, anchor.isFlipped ? local.y >= anchor.bounds.midY : local.y < anchor.bounds.midY)
            }
        }
        return nil
    }

    private func tabOffset(from source: String, to target: String, in state: ChromeState) -> Int? {
        guard let from = state.tabs.firstIndex(where: { $0.id == source }),
              let to = state.tabs.firstIndex(where: { $0.id == target }), from != to else { return nil }
        let a = state.tabs[from], b = state.tabs[to]
        guard a.space == state.activeSpace, b.space == a.space,
              a.pinned == b.pinned, a.group == b.group else { return nil }
        return to - from
    }

    private func proposedDrop(from source: SidebarDragItem, to target: SidebarDragItem,
                              after: Bool, in state: ChromeState) -> SidebarDrop? {
        guard source != target, let model else { return nil }
        let links = model.bookmarks.links
        switch (source, target) {
        case (.tab(let from), .tab(let to)):
            guard let offset = tabOffset(from: from, to: to, in: state) else { return nil }
            return SidebarDrop(item: target, placement: offset > 0 ? .after : .before)
        case (.link(let from), .link(let to)):
            guard links.contains(where: { $0.id == from }),
                  let link = links.first(where: { $0.id == to }) else { return nil }
            return SidebarDrop(item: target, placement: link.favorite ? .onto : (after ? .after : .before))
        case (.link(let from), .folder(let folder)):
            guard links.contains(where: { $0.id == from }),
                  links.contains(where: { !$0.favorite && $0.folder == folder }) else { return nil }
            return SidebarDrop(item: target, placement: .onto)
        default:
            return nil
        }
    }

    private func perform(_ drop: SidebarDrop, from source: SidebarDragItem, in state: ChromeState) {
        guard let model else { return }
        switch (source, drop.item) {
        case (.tab(let from), .tab(let to)):
            if let offset = tabOffset(from: from, to: to, in: state) {
                model.send(.move, tab: from, offset: offset)
            }
        case (.link(let from), .link(let to)):
            if drop.placement == .onto, model.bookmarks.links.contains(where: { $0.id == from && $0.favorite }) {
                model.bookmarks.reorderFavorite(from, onto: to)
            } else {
                model.bookmarks.move(from, beside: to, after: drop.placement != .before)
            }
        case (.link(let from), .folder(let folder)):
            model.bookmarks.move(from, toFolder: folder)
        default:
            break
        }
    }
}

private struct ChromeIconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ChromeIconButton(configuration: configuration, isEnabled: isEnabled)
    }

    private struct ChromeIconButton: View {
        let configuration: Configuration
        let isEnabled: Bool
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.system(size: 13, weight: .medium))
                .frame(width: BrowserChromeMetrics.iconButtonSize, height: BrowserChromeMetrics.iconButtonSize)
                .contentShape(Rectangle())
                .background {
                    if isEnabled && (hovering || configuration.isPressed) {
                        RoundedRectangle(cornerRadius: BrowserChromeMetrics.controlRadius)
                            .fill(.primary.opacity(configuration.isPressed ? 0.16 : 0.08))
                    }
                }
                .onHover { hovering = $0 }
                .opacity(isEnabled ? 1 : 0.42)
        }
    }
}

@MainActor struct NativeBrowserChrome: View {
    @ObservedObject var model: NativeChromeModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var address = ""
    @State private var sidebarDragOrigin: CGFloat?
    @State private var showWelcomeAfterSettings = false
    @State private var bookmarkFilter = ""
    @State private var bookmarkDraft: NativeChromeModel.Bookmark?
    @State private var editor: EditRequest?
    @State private var deletion: DeleteRequest?
    @FocusState private var addressFocused: Bool
    private struct EditRequest: Identifiable {
        let id = UUID(); let title: String; let kind: ChromeCommand.Kind; let target: String?; var value: String
    }
    private struct DeleteRequest: Identifiable {
        let id = UUID(); let title: String; let kind: ChromeCommand.Kind; let target: String
    }
    private var shellBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.075, green: 0.086, blue: 0.110)
            : Color(red: 0.940, green: 0.950, blue: 0.975)
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
                            .background(.background, in: RoundedRectangle(cornerRadius: BrowserChromeMetrics.contentRadius))
                            .padding(BrowserChromeMetrics.contentInset)
                    }
                    if state.mini {
                        Text("Private · memory only")
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(height: BrowserChromeMetrics.footerHeight)
                    }
                }
                .background(shellBackground)
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
            model.sidebarDrag.cancel()
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
        Button(action: action) { Image(systemName: icon) }
            .buttonStyle(ChromeIconButtonStyle()).help(label).accessibilityLabel(label).disabled(!enabled)
    }

    private func navigationControls(_ state: ChromeState) -> some View {
        HStack(spacing: 2) {
            tool("Back", "chevron.left", enabled: model.selectedTab?.back == true) { model.send(.back, tab: state.selected) }
            tool("Forward", "chevron.right", enabled: model.selectedTab?.forward == true) { model.send(.forward, tab: state.selected) }
            let loading = model.selectedTab?.loading == true
            tool(loading ? "Stop loading" : "Reload", loading ? "xmark" : "arrow.clockwise", enabled: model.selectedTab?.url != nil) {
                model.send(loading ? .stop : .reload, tab: state.selected)
            }
        }
    }

    private func addressField(_ state: ChromeState) -> some View {
        HStack(spacing: 8) {
            Image(systemName: model.selectedTab?.connection == "encrypted" ? "lock" : "magnifyingglass")
                .frame(width: 14)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Connection: \(model.selectedTab?.connection ?? "unknown")")
            TextField("Search or enter an address", text: $address)
                .textFieldStyle(.plain)
                .focused($addressFocused)
                .onSubmit { model.navigate(address); addressFocused = false }
                .accessibilityIdentifier("native-address")
                .accessibilityLabel("Address and search")
            if model.selectedTab?.loading == true { ProgressView().controlSize(.mini) }
        }
        .font(.system(size: 12))
        .padding(.horizontal, 10)
        .frame(height: BrowserChromeMetrics.addressHeight)
        .background(.primary.opacity(colorScheme == .dark ? 0.09 : 0.06),
                    in: RoundedRectangle(cornerRadius: BrowserChromeMetrics.controlRadius))
        .overlay {
            RoundedRectangle(cornerRadius: BrowserChromeMetrics.controlRadius)
                .strokeBorder(addressFocused ? Color.accentColor : .primary.opacity(0.07), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .disabled(state.session == "inactive" || state.recovery != nil)
    }

    private func toolbar(_ state: ChromeState) -> some View {
        HStack(spacing: 8) {
            Spacer().frame(width: 64)
            if !state.mini {
                tool(model.sidebarVisible ? "Hide sidebar" : "Show sidebar", "sidebar.left") { model.sidebarVisible.toggle() }
            }
            navigationControls(state)
            addressField(state)
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
                navigationControls(state)
            }.frame(height: 34)
            addressField(state)
            if !model.bookmarks.links.filter(\.favorite).isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: BrowserChromeMetrics.favoriteMinimumWidth),
                                             spacing: BrowserChromeMetrics.favoriteSpacing)],
                          spacing: BrowserChromeMetrics.favoriteSpacing) {
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
                        .disabled(state.workspaces.first?.id == state.activeWorkspace)
                    Button("Move workspace later") { model.send(.workspaceMove, target: state.activeWorkspace, offset: 1) }
                        .disabled(state.workspaces.last?.id == state.activeWorkspace)
                    Button("Delete empty workspace…", role: .destructive) { deletion = DeleteRequest(title: "Delete this empty workspace?", kind: .workspaceDelete, target: state.activeWorkspace) }
                        .disabled(state.workspaces.count < 2 || state.workspaces.first { $0.id == state.activeWorkspace }?.empty != true)
                    }
                    Divider()
                    Button("New Space…") { edit("New Space", .spaceCreate) }
                    Button("Rename Space…") { edit("Rename Space", .spaceRename, state.activeSpace, state.spaces.first { $0.id == state.activeSpace }?.name ?? "") }
                    Button("Move Space earlier") { model.send(.spaceMove, target: state.activeSpace, offset: -1) }
                        .disabled(state.spaces.first?.id == state.activeSpace)
                    Button("Move Space later") { model.send(.spaceMove, target: state.activeSpace, offset: 1) }
                        .disabled(state.spaces.last?.id == state.activeSpace)
                    Button("Delete empty Space…", role: .destructive) { deletion = DeleteRequest(title: "Delete this empty Space?", kind: .spaceDelete, target: state.activeSpace) }
                        .disabled(state.spaces.count < 2 || state.tabs.contains { $0.space == state.activeSpace })
                    Divider(); Button("New group…") { edit("New group", .groupCreate) }
                    Divider()
                    Button("Add temporary bookmark") { model.bookmarkCurrent() }.disabled(model.selectedTab?.url == nil)
                    Button("Add temporary favorite") { model.bookmarkCurrent(favorite: true) }.disabled(model.selectedTab?.url == nil)
                    Button("Manage temporary bookmarks…") { model.managesBookmarks = true }
                } label: { Image(systemName: "ellipsis.circle") }.menuStyle(.borderlessButton).fixedSize()
            }.disabled(state.session == "inactive")
            Button { model.send(state.session == "inactive" ? .startPrivate : .newTab) } label: {
                Label(state.session == "inactive" ? "Start private session" : "New tab", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 6)
                    .frame(minHeight: BrowserChromeMetrics.sidebarRowHeight, alignment: .leading)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
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
            VStack(alignment: .leading, spacing: 4) {
                Label(state.session == "inactive" ? "Private browsing is inactive" : "Private · memory only",
                      systemImage: "shield")
                    .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                Text("Protected profiles unavailable").font(.caption2).foregroundStyle(.secondary)
            }
        }.padding(.horizontal, 10).padding(.bottom, 12)
    }
    private func tabRow(_ tab: ChromeTab, _ state: ChromeState) -> some View {
        HStack {
            HStack(spacing: 8) {
                tabIcon(tab, split: state.split.contains(tab.id))
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
                Text(tab.title)
                    .font(.system(size: 13, weight: tab.id == state.selected ? .semibold : .regular))
                    .lineLimit(1).accessibilityValue(tab.pinned ? "Pinned" : "")
                Spacer(minLength: 0)
                if tab.loading { ProgressView().controlSize(.mini) }
            }
            .frame(minHeight: BrowserChromeMetrics.sidebarRowHeight)
            .background { dragRegion(.tab(tab.id)) }
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
        .overlay { dropIndicator(.tab(tab.id)) }
    }

    @ViewBuilder private func tabIcon(_ tab: ChromeTab, split: Bool) -> some View {
        let prefix = "data:image/png;base64,"
        if !tab.pinned, !split, let favicon = tab.favicon, favicon.hasPrefix(prefix),
           let data = Data(base64Encoded: String(favicon.dropFirst(prefix.count))),
           let image = NSImage(data: data) {
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: tab.pinned ? "pin.fill" : split ? "rectangle.split.2x1" : "globe")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
        }
    }

    private func dragRegion(_ item: SidebarDragItem) -> some View {
        SidebarDragRegion(interaction: model.sidebarDrag, item: item)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    @ViewBuilder private func dropIndicator(_ item: SidebarDragItem) -> some View {
        if let drop = model.sidebarDrop, drop.item == item {
            switch drop.placement {
            case .before, .after:
                Rectangle().fill(Color.accentColor).frame(height: 2)
                    .frame(maxHeight: .infinity, alignment: drop.placement == .after ? .bottom : .top)
                    .allowsHitTesting(false)
            case .onto:
                RoundedRectangle(cornerRadius: BrowserChromeMetrics.controlRadius)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .allowsHitTesting(false)
            }
        }
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
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, minHeight: BrowserChromeMetrics.sidebarRowHeight, alignment: .leading)
                            .background { dragRegion(.folder(folder)) }
                            .overlay { dropIndicator(.folder(folder)) }
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
                    Text(link.title.prefix(2).uppercased())
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity).frame(height: BrowserChromeMetrics.favoriteHeight)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: BrowserChromeMetrics.controlRadius))
                } else {
                    Label(link.title, systemImage: "bookmark")
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: BrowserChromeMetrics.sidebarRowHeight, alignment: .leading)
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
            .background { dragRegion(.link(link.id)) }
            .overlay { dropIndicator(.link(link.id)) }
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
                Text("V").font(.system(size: 52, weight: .heavy, design: .rounded)).foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text(state.session == "inactive" ? "Your next idea." : "Where to?")
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                Text(state.session == "inactive" ? "A fresh private workspace. Nothing to restore." : "Search or enter an address to start browsing.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
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
            Text("New private sessions use DuckDuckGo. Protected profiles and workspace restoration are unavailable.")
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
            Picker("Private session search", selection: $model.searchProvider) {
                ForEach(NativeNavigationInput.SearchProvider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }.disabled(state.session == "inactive" || state.recovery != nil)
            Text("The search choice resets to DuckDuckGo when this private session ends.").foregroundStyle(.secondary)
            Button("Show welcome") { showWelcomeAfterSettings = true; model.settings = false }
            Text("Private workspaces and temporary bookmarks clear when the session ends. Protected persistent profiles, history and downloads remain unavailable.").foregroundStyle(.secondary)
            Button("Done", role: .cancel) { model.settings = false }
        }.padding(24).frame(width: 470)
    }
}

/// The palette lives in its own hosting view above WebKit. AppKit owns the
/// field editor so activation from a web page transfers keyboard focus directly.
@MainActor private struct CommandSearchField: NSViewRepresentable {
    @Binding var query: String
    var move: (Int) -> Void
    var submit: () -> Void
    var cancel: () -> Void

    final class Field: NSTextField {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil else { return }
            Task { @MainActor [weak self] in
                guard let self, let window = self.window else { return }
                window.makeFirstResponder(self)
            }
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CommandSearchField
        init(_ parent: CommandSearchField) { self.parent = parent }

        func controlTextDidChange(_ notification: Notification) {
            if let field = notification.object as? NSTextField { parent.query = field.stringValue }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            guard !textView.hasMarkedText() else { return false }
            switch selector {
            case #selector(NSResponder.moveUp(_:)): parent.move(-1)
            case #selector(NSResponder.moveDown(_:)): parent.move(1)
            case #selector(NSResponder.insertNewline(_:)): parent.submit()
            case #selector(NSResponder.cancelOperation(_:)): parent.cancel()
            default: return false
            }
            return true
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> Field {
        let field = Field()
        field.placeholderString = "Search or enter an address"
        field.setAccessibilityLabel("Search tabs, Spaces, Favorites, Bookmarks, actions or the web")
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 16, weight: .medium)
        field.usesSingleLineMode = true
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ field: Field, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != query { field.stringValue = query }
    }
}

@MainActor struct NativeCommandPalette: View {
    @ObservedObject var model: NativeChromeModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var query = ""
    @State private var commandSelection = 0

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
                for bookmark in model.bookmarks.links where
                    matches(bookmark.title) || matches(bookmark.url) || matches(bookmark.folder) {
                    let action = bookmark.favorite ? "Open Favorite" : "Open Bookmark"
                    let label = bookmark.folder.isEmpty
                        ? "\(action) \(bookmark.title)"
                        : "\(action) \(bookmark.title) · \(bookmark.folder)"
                    items.append(PaletteItem(id: "saved-link-\(bookmark.id.uuidString)", label: label,
                                             symbol: bookmark.favorite ? "star.fill" : "bookmark.fill") {
                        model.openBookmark(bookmark.id)
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
        }
        if !state.mini && matches("Settings") {
            items.append(PaletteItem(id: "settings", label: "Settings", symbol: "gearshape", perform: { model.settings = true }))
        }
        if state.recovery == nil && !state.mini && !needle.isEmpty, NativeNavigationInput.destination(needle, provider: model.searchProvider) != nil {
            items.append(PaletteItem(id: "navigate", label: "Open or search in new tab", symbol: "magnifyingglass") {
                model.navigate(needle, inNewTab: true)
            })
        }
        return items
    }

    var body: some View {
        let items = model.state.map(paletteItems) ?? []
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                CommandSearchField(query: $query, move: { step in
                    commandSelection = min(max(0, items.count - 1), max(0, commandSelection + step))
                }, submit: {
                    if items.indices.contains(commandSelection) { runPaletteItem(items[commandSelection]) }
                }, cancel: { model.commands = false })
                Button { model.commands = false } label: { Image(systemName: "xmark.circle") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Dismiss command bar")
                    .help("Dismiss (Escape)")
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
                                    .padding(.horizontal, 10).frame(height: 44)
                                    .foregroundStyle(index == commandSelection ? Color.white : Color.primary)
                                    .background(index == commandSelection ? Color.indigo : .clear,
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
        }.padding(10)
            .frame(maxWidth: BrowserChromeMetrics.paletteWidth)
            .background(colorScheme == .dark ? Color(red: 0.096, green: 0.097, blue: 0.11) : Color(nsColor: .windowBackgroundColor),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.14)) }
            .shadow(color: .black.opacity(0.36), radius: 20, y: 6)
            .padding(20)
            .onExitCommand { model.commands = false }
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
