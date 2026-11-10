import AppKit
import SwiftUI
import WebKit
import BrowserDomain
import BrowserNativeStorage

@MainActor
private final class BrowserWindow: NSWindow {
    var shortcut: ((String) -> Bool)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.intersection([.command, .control, .option, .shift]) == .command,
           let key = event.charactersIgnoringModifiers?.lowercased(), shortcut?(key) == true {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

@MainActor
private final class FocusPane: NSView {
    var focus: (() -> Void)?
    override func hitTest(_ point: NSPoint) -> NSView? {
        let target = super.hitTest(point)
        if target != nil, NSApp.currentEvent?.type == .leftMouseDown { focus?() }
        return target
    }
}

@MainActor
private final class WorkspaceSplitView: NSSplitView {
    var dividerFinished: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        let before = arrangedSubviews.first?.frame.maxX
        super.mouseDown(with: event)
        if arrangedSubviews.count == 2, arrangedSubviews.first?.frame.maxX != before { dividerFinished?() }
    }
}

@MainActor
final class MainWindowController: NSWindowController, NSWindowDelegate, NSSplitViewDelegate {
    private struct PrivateSession {
        let id: PrivateSessionID
        let storage: NativeStorageSession
        let scope: Scope
        let context: CallerContext
    }

    private let root = NSView()
    // Historical DEBUG qualification helpers retain a nil compatibility reference.
    // No browser chrome WKWebView is constructed or registered in any build.
    private var chrome: WKWebView? { nil }
    private let nativeModel = NativeChromeModel()
    private var nativeChrome: NSHostingView<NativeBrowserChrome>?
    private var nativePoll: Task<Void, Never>?
    private let page = WorkspaceSplitView()
    private let panes = [FocusPane(), FocusPane()]
    private let mini: Bool
    private var minis: [UUID: MainWindowController] = [:]
    private weak var main: MainWindowController?
    var didClose: (() -> Void)?
    private var layout = WorkspaceLayout()
    private var mountedSession: UUID?
    private var bindings: [WorkspaceTabID: ViewID] = [:]

    private struct TransferTarget: Equatable {
        let workspace: WorkspaceID
        let space: WorkspaceSpaceID
        let revision: UInt64
        let mount: UUID?
    }

    private struct TransferPreview {
        let confirmation: UUID
        let source: UUID
        let url: URL
        let target: TransferTarget
    }

    private struct TransferReceipt {
        let mount: UUID
        let space: WorkspaceSpaceID
        let tab: WorkspaceTabID
        let view: ViewID
        let navigation: UUID
    }

    private var transferPreview: TransferPreview?
    private var acceptedTransfer: (source: UUID, receipt: TransferReceipt)?
    private var transferTarget: TransferTarget {
        TransferTarget(workspace: layout.activeWorkspace.id, space: layout.activeSpace.id,
                       revision: layout.revision, mount: mountedSession)
    }
    private var transferSource: (url: URL, token: UUID)? {
        guard mini, !closing, recovery == nil, let selected, let view = bindings[selected] else { return nil }
        return browsing?.storage.adapter.committedTransferSource(in: view)
    }
    private var miniEligible: Bool {
        guard let source = transferSource, let main else { return false }
        if let acceptedTransfer, acceptedTransfer.source == source.token, main.tabs.contains(acceptedTransfer.receipt.tab) { return false }
        return !main.closing && main.recovery == nil
    }
    private var browsing: PrivateSession?
    private var focusContent = false
    private var busy = false
    private var closing = false
    private var withdrawing = false
    private var cleanupTask: Task<Void, Never>?
    private var recovery: ChromeRecovery?
    private var retirementTask: Task<Void, Never>?
    private var displayedTabs: [WorkspaceTabID] = []
    private var appliedDivider: Int?
    private var tabs: [WorkspaceTabID] { layout.activeLayout.spaces.flatMap { $0.tabs.map(\.id) } }
    private var selected: WorkspaceTabID? { layout.activeSpace.activeTabId }
    private var splitTabs: [WorkspaceTabID] { layout.activeSpace.split?.members ?? [] }
    private var activeSpace: String { layout.activeSpace.id.rawValue }
    private var spaces: [ChromeSpace] {
        layout.activeLayout.spaces.map { ChromeSpace(id: $0.id.rawValue, name: $0.name) }
    }
    private var groups: [ChromeGroup] {
        layout.activeLayout.spaces.flatMap { space in
            space.groups.map { ChromeGroup(id: $0.id.rawValue, space: space.id.rawValue, name: $0.name, collapsed: $0.collapsed) }
        }
    }

    private func membership(_ id: WorkspaceTabID) -> (space: WorkspaceSpaceID, tab: WorkspaceLayout.Tab)? {
        for space in layout.activeLayout.spaces {
            if let tab = space.tabs.first(where: { $0.id == id }) { return (space.id, tab) }
        }
        return nil
    }

    private func surface(_ id: WorkspaceTabID) -> WKWebView? {
        bindings[id].flatMap { browsing?.storage.adapter.surface($0) }
    }

    var acceptsExternalNavigation: Bool { !closing }
    var isPerformingBrowserAction: Bool { busy }
    private var lastState: ChromeState?
    private var presentation = (visible: false, left: 0.0, top: 86.0)
    private static var sharedAppearance = ChromeAppearance.system
    private var appearance: ChromeAppearance {
        get { Self.sharedAppearance }
        set { Self.sharedAppearance = newValue }
    }

    init(mini: Bool = false) {
        self.mini = mini
        let window = BrowserWindow(
            contentRect: NSRect(x: 0, y: 0, width: mini ? 620 : 1180, height: mini ? 520 : 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = mini ? "Vezham Mini · Private" : "Vezham Browser"
        window.minSize = NSSize(width: mini ? 430 : 680, height: mini ? 340 : 470)
        window.center()
        super.init(window: window)
        window.delegate = self
        configureContent(window)
        window.shortcut = { [weak self] key in
            guard let self, !self.closing else { return false }
            if self.recovery != nil {
                guard key == "w" else { return false }
                self.window?.performClose(nil)
                return true
            }
            switch key {
            case "l": self.nativeModel.focusAddress += 1
            case "k": self.nativeModel.commands = true
            case ",": self.nativeModel.settings = true
            case "t":
                if self.mini { self.nativeModel.focusAddress += 1 }
                else { self.nativeModel.send(self.mountedSession == nil ? .startPrivate : .newTab) }
            case "w":
                if let selected = self.selected { self.nativeModel.send(.close, tab: selected.rawValue) }
                else { self.window?.performClose(nil) }
            case "r": self.nativeModel.send(.reload, tab: self.selected?.rawValue)
            case "[": self.nativeModel.send(.back, tab: self.selected?.rawValue)
            case "]": self.nativeModel.send(.forward, tab: self.selected?.rawValue)
            default: return false
            }
            return true
        }
    }

    required init?(coder: NSCoder) { fatalError("Storyboard initialization is not supported") }

    private func configureContent(_ window: NSWindow) {
        window.contentView = root
        let host = NSHostingView(rootView: NativeBrowserChrome(model: nativeModel))
        host.frame = root.bounds
        host.autoresizingMask = [.width, .height]
        root.addSubview(host)
        nativeChrome = host
        page.delegate = self
        page.isVertical = true
        page.dividerStyle = .thin
        page.dividerFinished = { [weak self] in self?.rememberDivider() }
        root.addSubview(page)
        page.isHidden = true
        presentation = (true, mini ? 0 : 236, 71)
        nativeModel.execute = { [weak self] command in
            guard let self else { return nil }
            let response = await self.run(command)
            self.refreshNative()
            return response
        }
        refreshNative()
        nativePoll = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.refreshNative()
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
        if let value = try? Self.settings().read() {
            switch value {
            case .system: appearance = .system
            case .light: appearance = .light
            case .dark: appearance = .dark
            }
        }
    }

    static func settings() throws -> GlobalAppearanceSettings {
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                   appropriateFor: nil, create: false)
        return GlobalAppearanceSettings(applicationSupport: support.appendingPathComponent("VezhamBrowser"))
    }

    private func refreshNative() {
        guard !closing else { return }
        let command = ChromeCommand(version: 1, id: "native-snapshot", type: .snapshot, tab: nil, url: nil,
            value: nil, offset: nil, target: nil, name: nil, visible: nil, left: nil, top: nil)
        let state = result(command).state
        if nativeModel.state != state {
            if state.sessionID != nativeModel.state?.sessionID || state.recovery != nil { nativeModel.bookmarks.removeAll() }
            nativeModel.state = state
        }
        if !busy { updateSurface() }
    }

    private func result(_ command: ChromeCommand, error: ChromeResult.Failure? = nil, text: String? = nil) -> ChromeResult {
        let revision = lastState?.revision ?? 0
        let session = mountedSession == nil ? "inactive" : "private"
        let sessionID = mountedSession?.uuidString.lowercased()
        let active = selected?.rawValue.lowercased()
        let items = tabs.map(tabState)
        let observed = ChromeState(revision: revision, session: session, sessionID: sessionID, recovery: recovery,
                                   tabs: items, selected: active, appearance: appearance, spaces: spaces, activeSpace: activeSpace,
                                   groups: groups, split: splitTabs.map { $0.rawValue.lowercased() },
                                   splitCompact: page.bounds.width < 600, mini: mini, workspaces: workspaceList, activeWorkspace: layout.activeWorkspace.id.rawValue, miniEligible: miniEligible)
        let state = observed == lastState ? observed : ChromeState(revision: revision + 1,
            session: session, sessionID: sessionID, recovery: recovery, tabs: items, selected: active, appearance: appearance, spaces: spaces, activeSpace: activeSpace,
                                   groups: groups, split: splitTabs.map { $0.rawValue.lowercased() },
                                   splitCompact: page.bounds.width < 600, mini: mini, workspaces: workspaceList, activeWorkspace: layout.activeWorkspace.id.rawValue, miniEligible: miniEligible)
        lastState = state
        return ChromeResult(id: command.id, state: state, error: error, text: text)
    }

    private var workspaceList: [ChromeWorkspace] {
        layout.catalog.workspaces.map { workspace in
            let empty = layout.session.layouts.first { $0.workspaceId == workspace.id }?.spaces.allSatisfy { $0.tabs.isEmpty } == true
            return ChromeWorkspace(id: workspace.id.rawValue, name: workspace.name, empty: empty)
        }
    }

    private func tabState(_ id: WorkspaceTabID) -> ChromeTab {
        let adapter = browsing?.storage.adapter
        let web = surface(id)
        let requested = bindings[id].flatMap { adapter?.requestedURL(in: $0) }
        let loadFailed = bindings[id].map { adapter?.navigationFailed(in: $0) == true } ?? false
        let effectiveURL = loadFailed ? requested ?? web?.url : web?.url ?? requested
        let url = effectiveURL.flatMap { value -> String? in
            guard let parts = URLComponents(url: value, resolvingAgainstBaseURL: false),
                  parts.user == nil, parts.password == nil else { return nil }
            return String(value.absoluteString.prefix(2048))
        }
        let failure: String? = recovery == .failed ? "content-unavailable" : loadFailed ? "load-failed" : nil
        let placement = membership(id)
        let connection: String
        if failure != nil || web?.isLoading != false { connection = "unknown" }
        else if web?.url?.scheme == "https", web?.hasOnlySecureContent == true { connection = "encrypted" }
        else if web?.url?.scheme == "http" { connection = "unencrypted" }
        else { connection = "unknown" }
        let title = web?.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return ChromeTab(id: id.rawValue.lowercased(), title: String((title.isEmpty ? (web?.url?.host ?? "New tab") : title).prefix(120)),
                         url: url, loading: web?.isLoading ?? false, progress: web?.estimatedProgress ?? 0,
                         back: web?.canGoBack ?? false, forward: web?.canGoForward ?? false, connection: connection, favicon: bindings[id].flatMap { adapter?.favicon(in: $0) }, failure: failure,
                         space: placement?.space.rawValue ?? activeSpace, pinned: placement?.tab.pinned ?? false,
                         group: placement?.tab.groupId?.rawValue)
    }

    private func run(_ command: ChromeCommand) async -> ChromeResult {
        if command.type == .snapshot { return result(command) }
        guard !closing else { return result(command, error: .unavailable) }
        if command.type == .presentation {
            guard let left = command.left, let top = command.top, let visible = command.visible,
                  left.isFinite, top.isFinite, (0...340).contains(left), (40...128).contains(top) else {
                return result(command, error: .invalid)
            }
            presentation = (visible, left, top)
            updateSurface()
            return result(command)
        }
        guard !busy else { return result(command, error: .busy) }
        guard recovery == nil || command.type == .recoverPrivate else {
            return result(command, error: .unavailable)
        }
        busy = true
        defer { browserActionFinished() }
        do {
            switch command.type {
            case .recoverPrivate:
                try await recoverPrivate()
            case .spaceCreate, .spaceRename, .spaceSwitch, .spaceDelete, .groupCreate,
                 .groupRename, .groupToggle, .groupMove, .groupDelete:
                try organize(command)
            case .workspaceCreate, .workspaceRename, .workspaceMove, .workspaceDelete:
                try organize(command)
            case .workspaceSwitch:
                guard !mini, mountedSession != nil, let id = try command.target.map({ try WorkspaceID($0.uuidString) }) else {
                    throw ChromeResult.Failure.invalid
                }
                try await switchWorkspace(id)
            case .unsplit: try layout.apply(.unsplit)
            case .miniOpen:
                guard !mini else { throw ChromeResult.Failure.unavailable }
                let url = command.url.flatMap(URL.init(string:)) ??
                    tabs.first(where: { UUID(uuidString: $0.rawValue) == command.tab }).flatMap { surface($0)?.url }
                guard let url else { throw ChromeResult.Failure.invalid }
                try await openMini(url)
            case .miniTransferPreview:
                var response = result(command)
                response.miniPreview = try previewHandoff()
                return response
            case .miniTransfer:
                try await transferMini(confirmation: command.target)
            case .startPrivate:
                try startPrivate()
            case .endPrivate:
                try await endPrivate()
            case .newTab:
                _ = try addTab()
            case .appearance:
                guard let value = command.value else { throw ChromeResult.Failure.invalid }
                try Self.settings().set(value == .system ? .system : value == .light ? .light : .dark)
                appearance = value
                NSApp.appearance = value == .system ? nil : NSAppearance(named: value == .light ? .aqua : .darkAqua)
            default:
                guard let raw = command.tab, let id = try? WorkspaceTabID(raw.uuidString), tabs.contains(id),
                      mountedSession != nil else { throw ChromeResult.Failure.unavailable }
                if let text = try await tabCommand(command, id: id) { return result(command, text: text) }
            }
            return result(command)
        } catch let failure as ChromeResult.Failure {
            return result(command, error: failure)
        } catch {
            return result(command, error: .failed)
        }
    }

    private func makePrivateSession() async throws -> PrivateSession {
        let storage = try NativeStorageSession.privateOnly(interactiveBrowsing: true)
        let id = try PrivateSessionID(UUID().uuidString)
        let scope = Scope.privateSession(id)
        let context = await storage.authority.grant(scope, run: storage.run)
        return PrivateSession(id: id, storage: storage, scope: scope, context: context)
    }

    private func preparePrivateSession(_ session: PrivateSession) async throws {
        let core = session.storage.core
        guard case .success(.registered) = await core.registerPrivate(session.id, context: session.context, operation: try operation()),
              case .success(.resolved) = await core.resolve(session.scope, context: session.context, operation: try operation()) else {
            throw ChromeResult.Failure.failed
        }
    }

    private func observe(_ session: PrivateSession) {
        let id = session.id
        session.storage.adapter.privateContentProcessDidTerminate = { [weak self] failedID in
            self?.privateContentTerminated(failedID)
        }
        session.storage.adapter.openExternalLink = { [weak self] url in
            Task { @MainActor [weak self] in
                guard let self, self.browsing?.id == id, self.recovery == nil else { return }
                do { try await self.openMini(url) }
                catch { NSSound.beep() }
            }
        }
    }

    private func startPrivate() throws {
        guard mountedSession == nil, !closing else { throw ChromeResult.Failure.invalid }
        mountedSession = UUID()
        _ = try addTab()
    }

    private func readySession() async throws -> PrivateSession {
        if let browsing { return browsing }
        let session = try await makePrivateSession()
        browsing = session
        observe(session)
        do {
            try await preparePrivateSession(session)
            guard !closing, recovery == nil else { throw ChromeResult.Failure.unavailable }
            return session
        } catch {
            if await retirePrivateSession(session) { browsing = nil }
            else { recovery = .failed }
            throw error
        }
    }

    private func admit(_ tab: WorkspaceTabID, demand: (() -> Bool)? = nil) async throws -> ViewID {
        func requested() -> Bool { demand?() ?? (selected == tab) }
        guard mountedSession != nil, !closing, recovery == nil, requested() else {
            throw ChromeResult.Failure.unavailable
        }
        if let view = bindings[tab], let session = browsing {
            guard await session.storage.authority.permits(session.context, scope: session.scope, run: session.storage.run),
                  !closing, recovery == nil, requested(), browsing?.id == session.id,
                  bindings[tab] == view, surface(tab) != nil else { throw ChromeResult.Failure.unavailable }
            return view
        }
        let mount = mountedSession
        let session = try await readySession()
        guard mountedSession == mount, !closing, recovery == nil, requested() else { throw ChromeResult.Failure.unavailable }
        let view = ViewID.fresh()
        let result = await session.storage.open(session.scope, context: session.context, view: view, operation: .fresh())
        guard result == .success(.activated(view)) else {
            if recovery == nil {
                let state = await session.storage.core.summary(session.scope)
                if recovery == nil, state?.state == .quarantined || state?.state == .failed
                    || state?.pending != nil || session.storage.adapter.ownedViews(session.scope).contains(view) {
                    await session.storage.adapter.preventAcquisition(in: session.scope)
                    await session.storage.authority.revoke(session.scope)
                    detachContent()
                    recovery = .failed
                }
            }
            throw ChromeResult.Failure.unavailable
        }
        guard !closing, recovery == nil, mountedSession == mount, browsing?.id == session.id,
              requested(), session.storage.adapter.surface(view) != nil else {
            if recovery == nil { try await closeBinding(view, in: session) }
            throw ChromeResult.Failure.unavailable
        }
        bindings[tab] = view
        return view
    }

    private func load(_ url: URL, in tab: WorkspaceTabID) async throws {
        guard validWebURL(url) else { throw ChromeResult.Failure.invalid }
        let view = try await admit(tab)
        guard !closing, recovery == nil, selected == tab, browsing?.storage.adapter.perform(.load(url), in: view) == true else { throw ChromeResult.Failure.failed }
    }

    private func browserActionFinished() {
        busy = false
        startRecoveryRetirement()
        if closing { scheduleCleanup() }
        else { presentation.visible = recovery == nil; refreshNative() }
    }

    private func privateContentTerminated(_ id: PrivateSessionID) {
        // If close already owns teardown, the adapter's fence still applies.
        // A callback must not start another Core retirement from this window.
        guard !closing, browsing?.id == id, recovery == nil else { return }
        recovery = .retiring
        presentation.visible = false
        focusContent = false
        window?.makeFirstResponder(nil)
        detachContent()
        page.isHidden = true
        startRecoveryRetirement()
    }

    private func startRecoveryRetirement() {
        guard !busy, recovery == .retiring, retirementTask == nil, let session = browsing else { return }
        retirementTask = Task { @MainActor in
            let confirmed = await retirePrivateSession(session)
            retirementTask = nil
            guard browsing?.id == session.id else { return }
            if confirmed {
                browsing = nil
                bindings.removeAll()
                recovery = .ready
            } else {
                recovery = .failed
            }
        }
    }

    /// Core owns the close/retire receipts. The adapter inventory includes weak
    /// references and pending resources, so an empty pane never suffices.
    private func retirePrivateSession(_ session: PrivateSession) async -> Bool {
        let storage = session.storage
        let scope = session.scope
        let adapter = storage.adapter
        adapter.openExternalLink = nil
        adapter.privateContentProcessDidTerminate = nil
        await adapter.preventAcquisition(in: scope)
        let confirmed = await confirmRetirement(session)
        await storage.authority.revoke(scope)
        let authorityRevoked = await storage.authority.current(scope) == nil
        return confirmed && authorityRevoked
    }

    private func confirmRetirement(_ session: PrivateSession) async -> Bool {
        let storage = session.storage, scope = session.scope
        let core = storage.core, context = session.context
        let ids = storage.adapter.ownedViews(scope)
        guard let initial = await core.summary(scope), initial.pending == nil, initial.viewCount == ids.count else { return false }
        do {
            for id in ids {
                guard await core.closeView(scope, view: id, context: context, operation: try operation()) == .success(.viewClosed) else { return false }
            }
            if ids.isEmpty, initial.state != .retired {
                guard await core.quiesce(scope, context: context, operation: try operation()) == .success(.quiesced),
                      await core.retire(scope, context: context, operation: try operation()) == .success(.retired) else { return false }
            }
        } catch { return false }
        guard let final = await core.summary(scope), final.state == .retired, final.viewCount == 0, final.pending == nil else { return false }
        return await storage.adapter.inventory(scope).isEmpty
    }

    private func recoverPrivate() async throws {
        guard recovery == .ready, browsing == nil, !closing else { throw ChromeResult.Failure.unavailable }
        recovery = .rebuilding
        guard !tabs.isEmpty else {
            recovery = .failed
            throw ChromeResult.Failure.unavailable
        }
        // Retirement already removed every old binding. Reopening only the layout
        // keeps each logical identity and leaves all pages blank until a fresh action.
        mountedSession = UUID()
        recovery = nil
    }

    private func addTab() throws -> WorkspaceTabID {
        guard mountedSession != nil else { throw ChromeResult.Failure.unavailable }
        let id = WorkspaceTabID.fresh()
        try layout.apply(.addTab(id))
        return id
    }

    private func closeBinding(_ view: ViewID, in session: PrivateSession) async throws {
        let storage = session.storage, scope = session.scope
        guard await storage.core.closeView(scope, view: view, context: session.context, operation: .fresh()) == .success(.viewClosed) else {
            await storage.adapter.preventAcquisition(in: scope)
            await storage.authority.revoke(scope)
            detachContent()
            recovery = .failed
            throw ChromeResult.Failure.failed
        }
        if await storage.core.summary(scope)?.state == .retired {
            await storage.authority.revoke(scope)
            browsing = nil
            if !closing { mountedSession = UUID() }
        }
    }

    private func endPrivate() async throws {
        guard mountedSession != nil || browsing != nil else { return }
        withdrawing = true
        defer { withdrawing = false }
        detachContent()
        if let browsing, !(await retirePrivateSession(browsing)) {
            recovery = .failed
            throw ChromeResult.Failure.failed
        }
        browsing = nil
        bindings.removeAll()
        mountedSession = nil
        layout = WorkspaceLayout()
    }

    private func closeTab(_ id: WorkspaceTabID) async throws {
        withdrawing = true
        defer { withdrawing = false }
        var next = layout
        try next.apply(.closeTab(id))
        if let view = bindings[id], let browsing {
            detachContent()
            try await closeBinding(view, in: browsing)
            bindings.removeValue(forKey: id)
        }
        if next.session.layouts.allSatisfy({ $0.spaces.allSatisfy { $0.tabs.isEmpty } }) {
            try await endPrivate()
        } else {
            layout = next
        }
    }

    private func switchWorkspace(_ id: WorkspaceID) async throws {
        guard id != layout.activeWorkspace.id else { return }
        var next = layout
        try next.apply(.selectWorkspace(id))
        withdrawing = true
        defer { withdrawing = false }
        detachContent()
        if let browsing, !(await retirePrivateSession(browsing)) {
            recovery = .failed
            throw ChromeResult.Failure.failed
        }
        browsing = nil
        bindings.removeAll()
        guard !closing else { throw ChromeResult.Failure.unavailable }
        mountedSession = UUID()
        layout = next
    }

    private func tabCommand(_ command: ChromeCommand, id: WorkspaceTabID) async throws -> String? {
        switch command.type {
        case .activate, .activateKeepingChromeFocus:
            try layout.apply(.selectTab(id))
            focusContent = command.type == .activate
        case .pin: try layout.apply(.pin(id))
        case .tabSpace:
            guard let target = command.target else { throw ChromeResult.Failure.invalid }
            try layout.apply(.moveTab(id, WorkspaceSpaceID(target.uuidString)))
        case .tabGroup:
            try layout.apply(.group(id, command.target.map { try WorkspaceGroupID($0.uuidString) }))
        case .split:
            guard !mini else { throw ChromeResult.Failure.invalid }
            try layout.apply(.split(id))
            focusContent = true
        case .close:
            try await closeTab(id)
            if mini && tabs.isEmpty { window?.close() }
        case .duplicate:
            let url = surface(id)?.url
            let new = try addTab()
            if let url { try await load(url, in: new) }
        case .move:
            guard let offset = command.offset else { throw ChromeResult.Failure.invalid }
            try layout.apply(.reorderTab(id, offset))
        case .copy:
            guard let value = tabState(id).url else { throw ChromeResult.Failure.unavailable }
            NSPasteboard.general.clearContents()
            guard NSPasteboard.general.setString(value, forType: .string) else { throw ChromeResult.Failure.failed }
        case .paste:
            guard let value = NSPasteboard.general.string(forType: .string), value.utf8.count <= 8192 else {
                throw ChromeResult.Failure.unavailable
            }
            return value
        case .navigate:
            guard let value = command.url, value.utf8.count <= 8192, let url = URL(string: value) else {
                throw ChromeResult.Failure.invalid
            }
            try await load(url, in: id)
            focusContent = true
        case .back: try await pageAction(.back, in: id)
        case .forward: try await pageAction(.forward, in: id)
        case .reload: try await pageAction(.reload, in: id)
        case .stop: try await pageAction(.stop, in: id)
        default: throw ChromeResult.Failure.invalid
        }
        return nil
    }

    private func pageAction(_ action: NativeWebKitStorage.InteractiveNavigation, in id: WorkspaceTabID) async throws {
        guard selected == id, let view = bindings[id], let session = browsing,
              await session.storage.authority.permits(session.context, scope: session.scope, run: session.storage.run),
              !closing, recovery == nil, selected == id, browsing?.id == session.id, bindings[id] == view,
              session.storage.adapter.perform(action, in: view) else { throw ChromeResult.Failure.unavailable }
    }

    private func operation() throws -> OperationID { try OperationID(UUID().uuidString) }

    private func detachContent() {
        // AppKit's responder can retain an otherwise detached website surface.
        // Move focus before asking Core to observe native reference retirement.
        if closing || (window?.firstResponder as? NSView).map({ $0 === page || $0.isDescendant(of: page) }) == true {
            window?.makeFirstResponder(nil)
        }
        for pane in panes {
            pane.focus = nil
            pane.subviews.forEach { $0.removeFromSuperview() }
            pane.removeFromSuperview()
        }
        displayedTabs = []
        appliedDivider = nil
    }

    private func updateSurface() {
        if presentation.top == 71 { presentation.left = mini || !nativeModel.sidebarVisible ? 0 : 236 }
        defer {
            let showing = !page.isHidden
            if nativeModel.showsWebContent != showing { nativeModel.showsWebContent = showing }
        }
        let bounds = root.bounds
        let left = CGFloat(presentation.left), top = CGFloat(presentation.top)
        let width = max(0, bounds.width - left)
        let resized = page.frame.width != width
        page.frame = NSRect(x: left, y: 29, width: width, height: max(0, bounds.height - top - 29))
        guard !closing, !withdrawing, recovery == nil, presentation.visible, let selected else {
            page.isHidden = true
            return
        }
        let pair = layout.activeSpace.split
        let visible = pair?.visibleTabs(contentWidth: width) ?? [selected]
        let surfaces = visible.map(surface)
        guard surfaces.contains(where: { $0 != nil }) else {
            detachContent()
            page.isHidden = true
            return
        }
        let changed = displayedTabs != visible || surfaces.enumerated().contains { index, web in
            if let web { return web.superview !== panes[index] }
            return panes[index].subviews.first is WKWebView
        }
        if changed {
            detachContent()
            for (index, id) in visible.enumerated() {
                let pane = panes[index]
                pane.focus = { [weak self] in
                    guard let self, !self.busy, self.recovery == nil, self.displayedTabs.contains(id) else { return }
                    try? self.layout.apply(.selectTab(id))
                    self.updateBorders()
                }
                pane.frame = NSRect(x: 0, y: 0, width: width / CGFloat(visible.count), height: page.bounds.height)
                let content = surfaces[index].map { $0 as NSView } ?? NSTextField(labelWithString: "Enter an address to browse in this pane.")
                content.frame = pane.bounds.insetBy(dx: 2, dy: 2)
                content.autoresizingMask = [.width, .height]
                pane.addSubview(content)
                page.addArrangedSubview(pane)
            }
            displayedTabs = visible
            page.adjustSubviews()
        }
        if let pair, visible.count == 2, resized || appliedDivider != pair.dividerBasisPoints,
           let position = pair.dividerPosition(contentWidth: width, thickness: page.dividerThickness) {
            page.setPosition(position, ofDividerAt: 0)
            appliedDivider = pair.dividerBasisPoints
        }
        updateBorders()
        page.isHidden = false
        if focusContent {
            _ = window?.makeFirstResponder(surface(selected) ?? nativeChrome)
            focusContent = false
        }
    }

    private func updateBorders() {
        for (index, pane) in panes.enumerated() {
            pane.wantsLayer = true
            pane.layer?.borderWidth = displayedTabs.count == 2 ? 2 : 0
            pane.layer?.borderColor = (displayedTabs.indices.contains(index) && displayedTabs[index] == selected
                ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
        }
    }

    private func rememberDivider() {
        guard !busy, !closing, recovery == nil, displayedTabs.count == 2,
              let leading = page.arrangedSubviews.first else { return }
        let available = page.bounds.width - page.dividerThickness
        guard available >= 500 else { return }
        let preference = Int((leading.frame.width / available * 10_000).rounded())
        try? layout.apply(.divider(preference))
        appliedDivider = layout.activeSpace.split?.dividerBasisPoints
    }

    private func organize(_ command: ChromeCommand) throws {
        guard !mini, mountedSession != nil else { throw ChromeResult.Failure.unavailable }
        let action: WorkspaceLayout.Action
        switch command.type {
        case .workspaceCreate: action = .createWorkspace(command.name ?? "")
        case .workspaceRename, .workspaceMove, .workspaceDelete:
            guard let target = command.target else { throw ChromeResult.Failure.invalid }
            let id = try WorkspaceID(target.uuidString)
            switch command.type {
            case .workspaceRename: action = .renameWorkspace(id, command.name ?? "")
            case .workspaceMove:
                guard let offset = command.offset else { throw ChromeResult.Failure.invalid }
                action = .reorderWorkspace(id, offset)
            default: action = .deleteWorkspace(id)
            }
        case .spaceCreate: action = .createSpace(command.name ?? "")
        case .spaceRename, .spaceSwitch, .spaceDelete:
            guard let target = command.target else { throw ChromeResult.Failure.invalid }
            let id = try WorkspaceSpaceID(target.uuidString)
            switch command.type {
            case .spaceRename: action = .renameSpace(id, command.name ?? "")
            case .spaceSwitch: action = .selectSpace(id)
            default: action = .deleteSpace(id)
            }
        case .groupCreate: action = .createGroup(command.name ?? "")
        case .groupRename, .groupToggle, .groupMove, .groupDelete:
            guard let target = command.target else { throw ChromeResult.Failure.invalid }
            let id = try WorkspaceGroupID(target.uuidString)
            switch command.type {
            case .groupRename: action = .renameGroup(id, command.name ?? "")
            case .groupToggle: action = .toggleGroup(id)
            case .groupMove:
                guard let offset = command.offset, [-1, 1].contains(offset) else { throw ChromeResult.Failure.invalid }
                action = .reorderGroup(id, offset)
            default: action = .deleteGroup(id)
            }
        default: throw ChromeResult.Failure.invalid
        }
        try layout.apply(action)
    }

    func openMini(_ url: URL) async throws {
        guard !closing, recovery == nil, validWebURL(url), minis.count < 6 else { throw ChromeResult.Failure.unavailable }
        let id = UUID()
        let child = MainWindowController(mini: true)
        child.busy = true
        defer { child.browserActionFinished() }
        minis[id] = child
        child.main = self
        child.didClose = { [weak self] in self?.minis.removeValue(forKey: id) }
        child.showWindow(nil)
        child.window?.makeKeyAndOrderFront(nil)
        do {
            try child.startPrivate()
            guard let selected = child.selected else { throw ChromeResult.Failure.failed }
            try await child.load(url, in: selected)
        } catch {
            child.window?.close()
            throw error
        }
    }

    private func validWebURL(_ url: URL) -> Bool {
        NativeWebKitStorage.permitsInteractiveURL(url)
    }

    func openExternal(_ url: URL) async throws {
        guard !busy else { throw ChromeResult.Failure.busy }
        guard await receive(url) else { throw ChromeResult.Failure.unavailable }
    }

    private func receive(_ url: URL) async -> Bool {
        guard !closing, !busy, recovery == nil, validWebURL(url) else { return false }
        busy = true
        defer { browserActionFinished() }
        do {
            let wasInactive = mountedSession == nil
            if wasInactive { try startPrivate() }
            if !wasInactive { _ = try addTab() }
            guard let selected else { return false }
            try await load(url, in: selected)
            window?.makeKeyAndOrderFront(nil)
            return true
        } catch { return false }
    }

    private func previewHandoff() throws -> ChromeMiniPreview {
        guard miniEligible, let source = transferSource, let main else {
            throw ChromeResult.Failure.unavailable
        }
        let preview = TransferPreview(confirmation: UUID(), source: source.token, url: source.url, target: main.transferTarget)
        transferPreview = preview
        return ChromeMiniPreview(token: preview.confirmation, url: source.url.absoluteString,
                                 workspace: main.layout.activeWorkspace.name, space: main.layout.activeSpace.name)
    }

    private func transferMini(confirmation: UUID?) async throws {
        guard miniEligible, let preview = transferPreview, preview.confirmation == confirmation,
              let main, transferSource?.token == preview.source else { throw ChromeResult.Failure.unavailable }
        transferPreview = nil
        let receipt = try await main.acceptHandoff(preview) { [weak self] in
            self?.transferSource?.token == preview.source
        }
        acceptedTransfer = (preview.source, receipt)
        let deadline = ContinuousClock.now.advanced(by: .seconds(8))
        while !closing, transferSource?.token == preview.source, ContinuousClock.now < deadline {
            switch main.handoffState(receipt) {
            case .pending:
                try await Task.sleep(for: .milliseconds(20))
            case .failed:
                throw ChromeResult.Failure.transferUnconfirmed
            case .committed:
                try await endPrivate()
                main.window?.makeKeyAndOrderFront(nil)
                window?.close()
                return
            }
        }
        throw ChromeResult.Failure.transferUnconfirmed
    }

    private func acceptHandoff(_ preview: TransferPreview, sourceValid: @escaping () -> Bool) async throws -> TransferReceipt {
        guard !mini, !busy, !closing, recovery == nil, transferTarget == preview.target, sourceValid(),
              NativeWebKitStorage.permitsMiniTransferURL(preview.url) else { throw ChromeResult.Failure.unavailable }
        let tab = WorkspaceTabID.fresh()
        var next = layout
        try next.apply(.addTab(tab))
        busy = true
        defer { browserActionFinished() }
        let hadMount = mountedSession != nil
        let mount = mountedSession ?? UUID()
        mountedSession = mount
        do {
            let view = try await admit(tab, demand: sourceValid)
            guard let navigation = browsing?.storage.adapter.beginDirectLoad(preview.url, in: view) else {
                throw ChromeResult.Failure.failed
            }
            layout = next
            return TransferReceipt(mount: mount, space: layout.activeSpace.id, tab: tab, view: view, navigation: navigation)
        } catch {
            if recovery == nil {
                if let view = bindings[tab], let browsing { try await closeBinding(view, in: browsing) }
                bindings.removeValue(forKey: tab)
                if !hadMount {
                    if let browsing, !(await retirePrivateSession(browsing)) {
                        recovery = .failed
                        throw ChromeResult.Failure.failed
                    }
                    browsing = nil
                    mountedSession = nil
                }
            }
            throw error
        }
    }

    private func handoffState(_ receipt: TransferReceipt) -> NativeWebKitStorage.DirectLoadState {
        guard !closing, recovery == nil, mountedSession == receipt.mount, layout.activeSpace.id == receipt.space,
              selected == receipt.tab, bindings[receipt.tab] == receipt.view else { return .failed }
        return browsing?.storage.adapter.directLoadState(receipt.navigation, in: receipt.view) ?? .failed
    }

    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        max(250, proposedMinimumPosition)
    }
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        min(splitView.bounds.width - 250, proposedMaximumPosition)
    }

    func windowDidResize(_ notification: Notification) { updateSurface() }

    func windowWillClose(_ notification: Notification) {
        closing = true
        page.isHidden = true
        nativePoll?.cancel(); nativePoll = nil; nativeModel.execute = nil
        detachContent()
        for child in Array(minis.values) { child.window?.close() }
        if !busy { scheduleCleanup() }
    }

    private func scheduleCleanup() {
        guard cleanupTask == nil else { return }
        let children = Array(minis.values)
        cleanupTask = Task { @MainActor in
            for child in children { await child.shutdown() }
            await retirementTask?.value
            if recovery == nil {
                do { try await endPrivate() }
                catch { page.isHidden = true }
            }
            nativeChrome?.removeFromSuperview()
            nativeChrome = nil
            didClose?()
        }
    }

    func shutdown() async {
        let children = Array(minis.values)
        window?.close()
        for child in children { await child.shutdown() }
        while busy { try? await Task.sleep(for: .milliseconds(20)) }
        scheduleCleanup()
        await cleanupTask?.value
    }
}

#if DEBUG
extension MainWindowController {
    func qualifyLoopback(_ origin: URL) async {
        guard origin.scheme == "http", origin.host == "127.0.0.1", origin.port != nil,
              origin.path.isEmpty || origin.path == "/", origin.user == nil, origin.password == nil,
              let chrome, let window else {
            Self.emit("fixture", status: "BLOCKED")
            NSApp.terminate(nil)
            return
        }
        defer { NSApp.terminate(nil) }
        func require(_ id: String, _ condition: Bool) throws {
            Self.emit(id, status: condition ? "PASS_NATIVE" : "FAIL")
            if !condition { throw ChromeResult.Failure.failed }
        }
        func eventually(_ condition: () async -> Bool) async -> Bool {
            for _ in 0..<80 {
                if await condition() { return true }
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return false }
            }
            return false
        }
        func readChrome(_ code: String, arguments: [String: Any] = [:]) async -> Bool {
            ((try? await chrome.callAsyncJavaScript(code, arguments: arguments, in: nil, contentWorld: .page)) as? Bool) == true
        }
        func command(_ type: String, tab: WorkspaceTabID? = nil, url: URL? = nil, offset: Int? = nil) async -> Bool {
            var value: [String: Any] = ["id": UUID().uuidString, "version": 1, "type": type]
            if let tab { value["tab"] = tab.rawValue }
            if let url { value["url"] = url.absoluteString }
            if let offset { value["offset"] = offset }
            return await readChrome("const result = await window.webkit.messageHandlers.browserChrome.postMessage(command); return !result.error;",
                                    arguments: ["command": value])
        }
        func screenshot(_ name: String) async {
            let marker = "{\"screenshot\":\"\(name)\",\"window\":\(window.windowNumber)}\n"
            FileHandle.standardOutput.write(Data(marker.utf8))
            try? await Task.sleep(for: .seconds(2))
        }
        do {
            try require("F4-SHELL", await eventually {
                await readChrome("return !!document.querySelector('.welcome .primary') && !document.querySelector('.welcome .primary').disabled;")
            })
            await screenshot("start")
            try require("F4-START-BUTTON", await readChrome("document.querySelector('.welcome .primary').click(); return true;"))
            try require("F4-PRIVATE-ASSIGNMENT", await eventually {
                guard let selected, let web = surface(selected) else { return false }
                let store = web.configuration.websiteDataStore
                return !store.isPersistent && store.identifier == nil
            })
            try require("F4-PRIVATE-UI", await eventually {
                await readChrome("return document.querySelector('.welcome h1')?.textContent === 'Where to?';")
            })
            await screenshot("private")
            guard let first = selected else { throw ChromeResult.Failure.failed }
            try require("F4-NAVIGATE-ACCEPTED", await command("navigate", tab: first, url: origin.appendingPathComponent("guide")))
            try require("F4-WEBKIT-RENDER", await eventually {
                guard let web = surface(first) else { return false }
                return web.title == "Coastal Field Guide" && !web.isLoading && !page.isHidden && web.superview === page
            })
            try require("F4-NAVIGATION-UI", await eventually {
                await readChrome("return document.querySelector('.tab-wrap.current .tab')?.textContent.trim() === 'Coastal Field Guide';")
            })
            await screenshot("browsing")
            do {
                guard let firstSurface = surface(first) else { throw ChromeResult.Failure.failed }
                let cookieWasSet = (try? await firstSurface.callAsyncJavaScript(
                    "return document.cookie.includes('fixture=');",
                    arguments: [:], in: nil, contentWorld: .page)) as? Bool
                try require("F4-COOKIE-SEED", cookieWasSet == true)
                let noHandler = (try? await firstSurface.callAsyncJavaScript(
                    "return typeof window.webkit?.messageHandlers?.browserChrome === 'undefined';",
                    arguments: [:], in: nil, contentWorld: .page)) as? Bool
                try require("F4-CHROME-ISOLATION", noHandler == true)
                try require("F4-INVALID-SCHEME", !(await command("navigate", tab: first, url: URL(string: "file:///tmp/chrome-guard"))))
                _ = try await firstSurface.callAsyncJavaScript("document.querySelector('#next').click();", arguments: [:], in: nil, contentWorld: .page)
                try require("F4-PAGE-LINK", await eventually { firstSurface.title == "Trail Notes" && firstSurface.canGoBack })
                try require("F4-BACK", await command("back", tab: first))
                try require("F4-BACK-RECONCILED", await eventually { firstSurface.title == "Coastal Field Guide" })
            }
            try require("F4-DUPLICATE", await command("duplicate", tab: first))
            guard let second = selected, second != first else { throw ChromeResult.Failure.failed }
            try require("F4-TAB-IDENTITIES", tabs.count == 2 && second != first)
            try require("F4-MOVE", await command("move", tab: second, offset: -1))
            try require("F4-MOVE-RECONCILED", tabs.first == second)
            try require("F4-CLOSE-DUPLICATE", await command("close", tab: second))
            try require("F4-END-PRIVATE", await command("endPrivate") && browsing == nil && tabs.isEmpty && selected == nil)
            try require("F4-SESSION-UI-CLEARED", await eventually {
                await readChrome("return document.querySelector('.welcome h1')?.textContent.includes('little room') === true;")
            })
            try require("F4-FRESH-SESSION", await command("startPrivate"))
            guard let fresh = selected else { throw ChromeResult.Failure.failed }
            try require("F4-FRESH-NAVIGATION", await command("navigate", tab: fresh, url: origin.appendingPathComponent("state")))
            try require("F4-COOKIE-NONREUSE", await eventually {
                surface(fresh)?.title == "Fresh Session"
            })
            try require("F4-BROKEN-NAVIGATION-START", await command("navigate", tab: fresh, url: origin.appendingPathComponent("broken")))
            try require("F4-NATIVE-FAILURE-UI", await eventually {
                await readChrome("return Array.from(document.querySelectorAll('main h2')).some((heading) => heading.textContent === 'This page couldn’t load');")
            })
            try require("F4-FINAL-END", await command("endPrivate"))
            try require("F4-SETTINGS-UI", await readChrome("Array.from(document.querySelectorAll('aside button')).find((button) => button.textContent.trim() === 'Settings')?.click(); return true;"))
            try require("F4-LIGHT-APPEARANCE", await eventually {
                await readChrome("const light = Array.from(document.querySelectorAll('.theme-options button')).find((button) => button.textContent.trim() === 'light'); if (light && light.getAttribute('aria-pressed') !== 'true') light.click(); return document.documentElement.dataset.theme === 'light';")
            })
            await screenshot("settings-light")
            _ = await readChrome("Array.from(document.querySelectorAll('.theme-options button')).find((button) => button.textContent.trim() === 'system')?.click(); return true;")
            Self.emit("qualification", status: "PASS_NATIVE")
        } catch {
            Self.emit("qualification", status: "FAIL")
        }
    }

    private static func emit(_ id: String, status: String) {
        let marker = "{\"testID\":\"\(id)\",\"status\":\"\(status)\"}\n"
        FileHandle.standardOutput.write(Data(marker.utf8))
    }
}
#endif

#if DEBUG
extension MainWindowController {
    func qualifyRefinement(_ origin: URL) async {
        guard origin.scheme == "http", origin.host == "127.0.0.1", origin.port != nil,
              let chrome, let window else { Self.emit("R-INPUT", status: "BLOCKED"); NSApp.terminate(nil); return }
        defer { NSApp.terminate(nil) }
        func require(_ id: String, _ value: Bool) throws {
            Self.emit(id, status: value ? "PASS_NATIVE" : "FAIL")
            if !value { throw ChromeResult.Failure.failed }
        }
        func wait(_ predicate: () async -> Bool) async -> Bool {
            for _ in 0..<160 {
                if await predicate() { return true }
                try? await Task.sleep(for: .milliseconds(100))
            }
            return false
        }
        func js(_ code: String, on controller: MainWindowController? = nil, arguments: [String: Any] = [:]) async -> Bool {
            let surface = controller?.chrome ?? chrome
            return ((try? await surface.callAsyncJavaScript(code, arguments: arguments, in: nil, contentWorld: .page)) as? Bool) == true
        }
        func command(_ type: String, fields: [String: Any] = [:], on controller: MainWindowController? = nil) async -> Bool {
            let payload = fields.merging(["type": type, "version": 1, "id": UUID().uuidString]) { _, value in value }
            return await js("const r = await window.webkit.messageHandlers.browserChrome.postMessage(payload); return !r.error;",
                            on: controller, arguments: ["payload": payload])
        }
        func capture(_ name: String, controller: MainWindowController? = nil) async {
            try? await Task.sleep(for: .milliseconds(400))
            let number = controller?.window?.windowNumber ?? window.windowNumber
            let marker = "{\"screenshot\":\"\(name)\",\"window\":\(number)}\n"
            FileHandle.standardOutput.write(Data(marker.utf8))
            try? await Task.sleep(for: .milliseconds(600))
        }
        func loaded(_ id: WorkspaceTabID, _ title: String, on controller: MainWindowController? = nil) -> Bool {
            let source = controller ?? self
            return source.surface(id)?.title == title &&
                source.surface(id)?.isLoading == false
        }
        do {
            try require("R-SHELL", await wait { await js("return !!document.querySelector('.welcome .primary') && !document.querySelector('.welcome .primary').disabled;") })
            await capture("01-main-default")
            try require("R-PRIVATE-START", await js("document.querySelector('.welcome .primary').click(); return true;"))
            try require("R-PRIVATE-STORE", await wait {
                guard let selected, let view = surface(selected) else { return false }
                return !view.configuration.websiteDataStore.isPersistent && view.configuration.websiteDataStore.identifier == nil
            })
            await capture("07-new-tab-private")
            guard let first = selected else { throw ChromeResult.Failure.failed }
            try require("R-URL", await command("navigate", fields: ["tab": first.rawValue, "url": origin.appendingPathComponent("guide").absoluteString]))
            try require("R-RENDER", await wait { loaded(first, "Coastal Field Guide") && !page.isHidden })
            try require("R-FAVICON", await wait { tabState(first).favicon?.hasPrefix("data:image/png;base64,") == true })
            try require("R-PIN", await command("pin", fields: ["tab": first.rawValue]) && membership(first)?.tab.pinned == true)
            try require("R-NEW-TAB", await command("newTab"))
            guard let second = selected else { throw ChromeResult.Failure.failed }
            try require("R-SECOND-PAGE", await command("navigate", fields: ["tab": second.rawValue, "url": origin.appendingPathComponent("notes").absoluteString]))
            try require("R-SECOND-RENDER", await wait { loaded(second, "Trail Notes") })
            try require("R-GROUP-CREATE", await command("groupCreate", fields: ["name": "Field notes"]))
            guard let group = groups.first else { throw ChromeResult.Failure.failed }
            try require("R-GROUP-ASSIGN", await command("tabGroup", fields: ["tab": second.rawValue, "target": group.id]) && membership(second)?.tab.groupId?.rawValue == group.id)
            await capture("02-vertical-tabs")
            await capture("05-pinned-tabs")
            await capture("06-group-expanded")
            try require("R-GROUP-COLLAPSE", await command("groupToggle", fields: ["target": group.id]) && groups.first?.collapsed == true)
            await capture("06-group-collapsed")
            try require("R-GROUP-EXPAND", await command("groupToggle", fields: ["target": group.id]))
            try require("R-GROUP-RENAME", await command("groupRename", fields: ["target": group.id, "name": "Coast research"]) && groups.first?.name == "Coast research")
            try require("R-GROUP-ORDER", await command("groupCreate", fields: ["name": "Reading"]))
            try require("R-GROUP-MOVE", await command("groupMove", fields: ["target": group.id, "offset": 1]) && groups.last?.id == group.id)
            let personal = activeSpace
            try require("R-SPACE-CREATE", await command("spaceCreate", fields: ["name": "Research"]) && selected == nil)
            let research = activeSpace
            try require("R-SPACE-RENAME", await command("spaceRename", fields: ["target": research, "name": "Explore"]))
            await capture("04-spaces")
            try require("R-SPACE-SWITCH", await command("spaceSwitch", fields: ["target": personal]) && selected != nil)
            try require("R-NONEMPTY-SPACE-GUARD", !(await command("spaceDelete", fields: ["target": personal])))
            try require("R-COLLAPSE-SIDEBAR", await js("document.querySelector('[aria-label=\"Hide sidebar\"]').click(); return true;"))
            try require("R-COLLAPSED-LAYOUT", await wait { await js("return !document.querySelector('aside');") })
            await capture("03-sidebar-collapsed")
            try require("R-EXPAND-SIDEBAR", await js("document.querySelector('[aria-label=\"Show sidebar\"]').click(); return true;"))
            try require("R-COMMAND-BAR", await js("document.querySelector('[aria-label=\"Open command palette\"]').click(); return true;"))
            try require("R-COMMAND-FOCUS", await wait { await js("return document.activeElement?.getAttribute('aria-label') === 'Find a command';") })
            await capture("08-command-bar")
            _ = await js("document.querySelector('[aria-label=\"Close commands\"]').click(); return true;")
            try require("R-TAB-CONTEXT", await js("document.querySelector('.vertical-tab .tool').click(); return true;"))
            try require("R-TAB-CONTEXT-VISIBLE", await wait { await js("return !!document.querySelector('.workspace-context .popover');") })
            await capture("09-tab-context")
            try require("R-CONTEXT-ACTION", await js("const action = Array.from(document.querySelectorAll('.workspace-context button')).find(button => button.textContent.trim() === 'Copy address'); if (!action) return false; action.click(); return true;"))
            try require("R-CONTEXT-DISMISSED", await wait { await js("return !document.querySelector('.context-shade') && !document.querySelector('dialog');") })
            try require("R-SPLIT-SELECT", await command("activate", fields: ["tab": first.rawValue]))
            try require("R-SPLIT-CREATE", await command("split", fields: ["tab": second.rawValue]))
            try require("R-SPLIT-NATIVE-VIEWS", await wait {
                page.arrangedSubviews.count == 2 &&
                    surface(first)?.superview === panes[0] &&
                    surface(second)?.superview === panes[1]
            })
            try require("R-SPLIT-DISTINCT-IDENTITY", surface(first) !== surface(second))
            await capture("10-split-screen")
            try require("R-SPLIT-FOCUS-SECOND", selected == second)
            await capture("11-split-second-focused")
            try require("R-SPLIT-FOCUS-FIRST", await command("activate", fields: ["tab": first.rawValue]) && selected == first && splitTabs.count == 2)
            try require("R-SPLIT-INDEPENDENT-NAVIGATION", await command("navigate", fields: ["tab": first.rawValue, "url": origin.appendingPathComponent("notes").absoluteString]))
            try require("R-SPLIT-STATE", await wait { loaded(first, "Trail Notes") && loaded(second, "Trail Notes") })
            try require("R-SPLIT-OTHER-NAVIGATION", await command("navigate", fields: ["tab": second.rawValue, "url": origin.appendingPathComponent("guide").absoluteString]))
            try require("R-SPLIT-OTHER-STATE", await wait { loaded(first, "Trail Notes") && loaded(second, "Coastal Field Guide") })
            try require("R-CONTENT-BRIDGE-ISOLATION", ((try? await surface(first)?.callAsyncJavaScript(
                "return typeof window.webkit?.messageHandlers?.browserChrome === 'undefined';", arguments: [:], in: nil, contentWorld: .page)) as? Bool) == true)
            window.setContentSize(NSSize(width: 680, height: 510))
            try require("R-NARROW-FALLBACK", await wait { page.arrangedSubviews.count == 1 && splitTabs.count == 2 })
            await capture("18-narrow-window")
            window.setContentSize(NSSize(width: 1180, height: 760))
            try require("R-SPLIT-RESTORED", await wait { page.arrangedSubviews.count == 2 })
            try require("R-SPLIT-EXIT", await command("unsplit") && splitTabs.isEmpty)
            try require("R-DUPLICATE", await command("duplicate", fields: ["tab":first.rawValue]))
            guard let duplicate = selected, duplicate != first else { throw ChromeResult.Failure.failed }
            try require("R-REORDER", await command("move", fields:["tab":duplicate.rawValue,"offset":-2]) && tabs.first == duplicate)
            try require("R-SPLIT-CLOSE-SELECT", await command("activate", fields:["tab":first.rawValue]))
            try require("R-SPLIT-CLOSE-SETUP", await command("split",fields:["tab":duplicate.rawValue]))
            try require("R-SPLIT-CLOSE-READY", await wait { page.arrangedSubviews.count == 2 })
            page.setPosition(page.bounds.width * 0.6, ofDividerAt: 0)
            try require("R-SPLIT-DIVIDER", panes[0].frame.width >= 250 && panes[1].frame.width >= 250)
            try require("R-SPLIT-CLOSE-PANE", await command("close", fields:["tab":duplicate.rawValue]) && splitTabs.isEmpty && !tabs.contains(duplicate))
            do {
                guard let surface = surface(second) else { throw ChromeResult.Failure.failed }
                let seeded = (try? await surface.callAsyncJavaScript("localStorage.setItem('workspace-only','synthetic'); return localStorage.getItem('workspace-only') === 'synthetic';", arguments:[:],in:nil,contentWorld:.page)) as? Bool
                try require("R-MINI-ISOLATION-CONTROL", seeded == true)
            }
            try require("R-MINI-OPEN", await command("miniOpen", fields: ["tab": second.rawValue]))
            guard let child = minis.values.first else { throw ChromeResult.Failure.failed }
            try require("R-MINI-RENDER", await wait {
                guard let id = child.selected else { return false }
                return loaded(id, "Coastal Field Guide", on: child) && !child.page.isHidden
            })
            try require("R-MINI-STRUCTURE", await js("return !!document.querySelector('.mini-browser') && !document.querySelector('aside');", on: child))
            guard let miniTab = child.selected else { throw ChromeResult.Failure.failed }
            try require("R-MINI-SEPARATE-STORE", child.surface(miniTab)?.configuration.websiteDataStore !== surface(second)?.configuration.websiteDataStore)
            do {
                guard let surface = child.surface(miniTab) else { throw ChromeResult.Failure.failed }
                let isolated = (try? await surface.callAsyncJavaScript("localStorage.setItem('mini-only','synthetic'); return localStorage.getItem('workspace-only') === null;", arguments:[:],in:nil,contentWorld:.page)) as? Bool
                try require("R-MINI-STORAGE-ISOLATION", isolated == true)
            }
            try require("R-APPEARANCE-ALL-WINDOWS", await command("appearance",fields:["value":"light"]))
            try require("R-MINI-APPEARANCE-RECONCILED", await wait {
                await js("return document.documentElement.dataset.theme === 'light';",on:child)
            })
            _ = await command("appearance",fields:["value":"system"])
            await capture("12-mini-browser", controller: child)
            try require("R-MINI-NAVIGATE", await command("navigate", fields: ["tab": miniTab.rawValue, "url": origin.appendingPathComponent("notes").absoluteString], on: child))
            try require("R-MINI-NAVIGATED", await wait { loaded(miniTab, "Trail Notes", on: child) })
            try require("R-MINI-BACK", await command("back", fields: ["tab": miniTab.rawValue], on: child))
            try require("R-MINI-BACK-STATE", await wait { loaded(miniTab, "Coastal Field Guide", on: child) })
            try require("R-MINI-FORWARD", await command("forward", fields: ["tab": miniTab.rawValue], on: child))
            try require("R-MINI-FORWARD-STATE", await wait { loaded(miniTab, "Trail Notes", on: child) })
            try require("R-MINI-RELOAD", await command("reload", fields: ["tab": miniTab.rawValue], on: child))
            try require("R-MINI-RELOADED", await wait { loaded(miniTab, "Trail Notes", on: child) })
            await capture("13-mini-navigation", controller: child)
            await capture("14-mini-transfer-action", controller: child)
            let preview = try child.previewHandoff()
            try require("R-MINI-TRANSFER", await command("miniTransfer", fields: ["target": preview.token.uuidString], on: child))
            try require("R-MINI-TRANSFER-URL", await wait {
                guard let id = selected else { return false }
                return loaded(id, "Trail Notes") && child.browsing == nil && minis.isEmpty
            })
            do {
                guard let selected, let surface = surface(selected) else { throw ChromeResult.Failure.failed }
                let noCopy = (try? await surface.callAsyncJavaScript("return localStorage.getItem('mini-only') === null && localStorage.getItem('workspace-only') === 'synthetic';", arguments:[:],in:nil,contentWorld:.page)) as? Bool
                try require("R-MINI-TRANSFER-URL-ONLY", noCopy == true)
            }
            try require("R-MINI-CLOSE-SECOND", await command("miniOpen", fields: ["tab": first.rawValue]))
            guard let closeChild = minis.values.first else { throw ChromeResult.Failure.failed }
            try require("R-MINI-SECOND-LOADED", await wait { closeChild.selected != nil })
            closeChild.window?.close()
            try require("R-MINI-CLOSE-CLEANUP", await wait { closeChild.browsing == nil && closeChild.tabs.isEmpty && minis.isEmpty })
            do {
            guard let sourceView = surface(first) else { throw ChromeResult.Failure.failed }
            _ = try await sourceView.callAsyncJavaScript("document.querySelector('#mini-link')?.click();", arguments: [:], in: nil, contentWorld: .page)
            try require("R-MINI-LINK-ENTRY", await wait { minis.count == 1 })
            for mini in Array(minis.values) { mini.window?.close() }
            try require("R-MINI-LINK-CLEANUP", await wait { minis.isEmpty })
            }
            var components = URLComponents()
            components.scheme = "vezham"; components.host = "open"
            components.queryItems = [URLQueryItem(name:"url",value:origin.appendingPathComponent("notes").absoluteString)]
            guard let delivery = components.url, let delegate = NSApp.delegate as? ApplicationDelegate else { throw ChromeResult.Failure.failed }
            delegate.application(NSApp, open:[delivery])
            try require("R-NATIVE-URL-ENTRY", await wait { minis.count == 1 })
            for mini in Array(minis.values) { mini.window?.close() }
            try require("R-NATIVE-URL-CLEANUP", await wait { minis.isEmpty })
            let externalMarker = try JSONSerialization.data(withJSONObject: ["externalURL": delivery.absoluteString])
            FileHandle.standardOutput.write(externalMarker + Data([10]))
            try require("R-EXTERNAL-URL-DELIVERY", await wait { minis.count == 1 })
            for mini in Array(minis.values) { mini.window?.close() }
            try require("R-EXTERNAL-URL-CLEANUP", await wait { minis.isEmpty })
            try require("R-DARK", await command("appearance", fields: ["value":"dark"]))
            await capture("16-dark")
            try require("R-LIGHT", await command("appearance", fields: ["value":"light"]))
            await capture("15-light")
            try require("R-UNPIN", await command("pin", fields: ["tab": first.rawValue]) && membership(first)?.tab.pinned == false)
            try require("R-UNGROUP", await command("tabGroup", fields: ["tab": second.rawValue]) && membership(second)?.tab.groupId?.rawValue == nil)
            try require("R-TAB-MOVE-SPACE", await command("tabSpace", fields: ["tab": second.rawValue, "target": research]) && membership(second)?.space.rawValue == research)
            try require("R-SPACE-DELETE-EMPTY", await command("spaceCreate", fields: ["name":"Disposable"]))
            let disposable = activeSpace
            try require("R-SPACE-DELETED", await command("spaceDelete", fields: ["target":disposable]) && !spaces.contains(where: {$0.id == disposable}))
            _ = await command("spaceSwitch", fields: ["target":personal])
            await capture("17-private-session")
            try require("R-END", await command("endPrivate") && browsing == nil && tabs.isEmpty && groups.isEmpty)
            _ = await command("appearance", fields: ["value":"system"])
            Self.emit("qualification", status:"PASS_NATIVE")
        } catch { Self.emit("qualification", status:"FAIL") }
    }
}


@MainActor
private final class ReliabilityReferences {
    weak var controller: MainWindowController?
    weak var surface: WKWebView?
    weak var mini: MainWindowController?
    weak var miniSurface: WKWebView?
}

extension MainWindowController {
    func reliabilityDOMObservation() async -> Any {
        guard let chrome else { return NSNull() }
        let code = """
        if (!window.__wsf5DragEvents) {
          window.__wsf5DragEvents = [];
          for (const type of ['mousedown','mousemove','dragstart','dragenter','dragover','drop','dragend']) {
            document.addEventListener(type, e => {
              if (type === 'mousemove' && !e.buttons) return;
              const log = window.__wsf5DragEvents;
              log.push({type, x:e.clientX, y:e.clientY, buttons:e.buttons, target:e.target.className, dropEffect:e.dataTransfer?.dropEffect});
              if (log.length > 100) log.shift();
            }, true);
          }
        }
        return {events:window.__wsf5DragEvents, focused:document.activeElement?.getAttribute('aria-label') || document.activeElement?.textContent?.slice(0,80)};
        """
        return (try? await chrome.callAsyncJavaScript(code, arguments: [:], in: nil, contentWorld: .page)) ?? NSNull()
    }

    func reliabilityObservation() -> [String: Any] {
        let command = try! JSONDecoder().decode(ChromeCommand.self, from: Data("{\"version\":1,\"id\":\"observation\",\"type\":\"snapshot\"}".utf8))
        let encoded = try! JSONEncoder().encode(result(command).state)
        return ["window": window?.windowNumber ?? -1, "visible": window?.isVisible ?? false,
                "closing": closing, "busy": busy, "nativeChromeReady": nativeChrome != nil,
                "state": try! JSONSerialization.jsonObject(with: encoded),
                "minis": minis.values.map { $0.reliabilityObservation() }]
    }

    // Tests the production delegate path with a deliberate callback injection.
    // This harness cannot establish an actual WebKit content-process exit.
    func qualifyWorkspace(_ origin: URL) async {
        func check(_ id: String, _ value: Bool, contract: Bool = false) throws {
            Self.emit(id, status: value ? (contract ? "PASS_CONTRACT" : "PASS_NATIVE") : "FAIL")
            guard value else { throw ChromeResult.Failure.failed }
        }
        func wait(_ condition: () -> Bool) async -> Bool {
            let deadline = ContinuousClock.now.advanced(by: .seconds(10))
            while ContinuousClock.now < deadline {
                if condition() { return true }
                try? await Task.sleep(for: .milliseconds(20))
            }
            return false
        }
        func loaded(_ controller: MainWindowController, _ path: String) -> Bool {
            guard let id = controller.selected, let view = controller.surface(id) else { return false }
            return view.url?.path == path && !view.isLoading
        }
        func js(_ controller: MainWindowController, _ script: String) async -> Bool {
            guard let id = controller.selected, let view = controller.surface(id) else { return false }
            return (try? await view.callAsyncJavaScript(script, arguments: [:], in: nil, contentWorld: .page)) as? Bool == true
        }
        func newMini(_ path: String) async throws -> MainWindowController {
            let previous = Set(minis.keys)
            try await openMini(origin.appendingPathComponent(path))
            guard let child = minis.first(where: { !previous.contains($0.key) })?.value else { throw ChromeResult.Failure.failed }
            guard await wait({ loaded(child, "/" + path) }) else { throw ChromeResult.Failure.failed }
            return child
        }
        func deniedTransfer(_ path: String, _ id: String) async throws {
            let child = try await newMini(path)
            let preview = try child.previewHandoff()
            let before = tabs.count
            do {
                try await child.transferMini(confirmation: preview.token)
                throw ChromeResult.Failure.invalid
            } catch ChromeResult.Failure.transferUnconfirmed {
                try check(id, !child.closing && child.surface(child.selected!) != nil && tabs.count == before + 1)
            }
            await child.shutdown()
        }
        do {
            try check("F6-EMPTY-NATIVE", browsing == nil && bindings.isEmpty && mountedSession == nil)
            try startPrivate()
            let first = selected!
            for _ in 1..<24 { _ = try addTab() }
            try layout.apply(.selectTab(first))
            try check("F6-LAZY-24-SLOTS", tabs.count == 24 && browsing == nil && bindings.isEmpty && tabState(first).failure == nil)
            try await load(origin.appendingPathComponent("alpha"), in: first)
            try check("F6-FIRST-LOAD", await wait { loaded(self, "/alpha") })
            guard let session = browsing else { throw ChromeResult.Failure.failed }
            let view = bindings[first]!
            try check("F6-ONE-ADMISSION", session.storage.adapter.ownedViews(session.scope) == [view])
            let same = try await admit(first)
            try check("F6-DUPLICATE-ADMISSION", same == view && bindings.count == 1)
            try check("F6-MAIN-MARKERS", await js(self, "localStorage.setItem('f6-main','1'); document.cookie='f6_main=1; Path=/'; return true;"))
            let second = tabs[1]
            try layout.apply(.selectTab(second))
            try check("F6-BACKGROUND-IS-BLANK", surface(second) == nil && bindings.count == 1)
            try await load(origin.appendingPathComponent("beta"), in: second)
            try check("F6-SECOND-LOAD", await wait { loaded(self, "/beta") })
            try layout.apply(.selectTab(first))
            try layout.apply(.split(second))
            try layout.apply(.divider(6500))
            presentation = (true, 0, 86)
            window?.setContentSize(NSSize(width: 1001, height: 760))
            updateSurface()
            try check("F6-SPLIT-VIEWS", page.arrangedSubviews.count == 2 && surface(first) !== surface(second))
            try check("F6-DIVIDER-PREFERENCE", abs((page.arrangedSubviews.first?.frame.width ?? 0) - 650) < 3)
            try layout.apply(.selectTab(first))
            focusContent = true
            updateSurface()
            do {
                let focusTarget = surface(first)!
                let responder = window?.firstResponder as? NSView
                try check("F6-PANE-FOCUS", responder === focusTarget || responder?.isDescendant(of: focusTarget) == true)
            }
            window?.setContentSize(NSSize(width: 680, height: 470))
            presentation = (true, 166, 86)
            updateSurface()
            try check("F6-COMPACT", displayedTabs == [first] && splitTabs.count == 2 && layout.activeSpace.split?.dividerBasisPoints == 6500)
            window?.setContentSize(NSSize(width: 1001, height: 760))
            presentation = (true, 0, 86)
            updateSurface()
            try check("F6-WIDE-RESTORED", displayedTabs == [first, second] && layout.activeSpace.split?.dividerBasisPoints == 6500)
            let home = layout.activeSpace.id
            try layout.apply(.createSpace("Other"))
            try layout.apply(.selectSpace(home))
            try check("F6-SPACE-PAIR-RESTORED", splitTabs == [first, second] && selected == first, contract: true)
            try await closeTab(second)
            try check("F6-SPLIT-SURVIVOR", splitTabs.isEmpty && selected == first && bindings.count == 1)

            let child = try await newMini("alpha")
            let other = try await newMini("beta")
            try check("F6-MINI-ISOLATION", await js(child, "localStorage.setItem('f6-mini','1'); return localStorage.getItem('f6-main') === null && !document.cookie.includes('f6_main=');"))
            try check("F6-TWO-MINI-ISOLATION", await js(other, "return localStorage.getItem('f6-mini') === null && localStorage.getItem('f6-main') === null;"))
            try check("F6-NONPERSISTENT-STORES", [surface(first), child.surface(child.selected!), other.surface(other.selected!)].allSatisfy { $0?.configuration.websiteDataStore.isPersistent == false })
            await other.shutdown()
            try await closeTab(tabs.last!)
            let target = transferTarget
            let preview = try child.previewHandoff()
            try check("F6-MINI-DESTINATION-PREVIEW", preview.workspace == layout.activeWorkspace.name && preview.space == layout.activeSpace.name && transferTarget == target, contract: true)
            try await child.transferMini(confirmation: preview.token)
            try check("F6-MINI-COMMIT-CLEANUP", await wait {
                child.closing && child.browsing == nil && child.nativeChrome == nil && minis.isEmpty && selected != first
            })
            try check("F6-HANDOFF-RECEIVER-ISOLATION", await wait { loaded(self, "/alpha") })
            try check("F6-HANDOFF-NO-SOURCE-DATA", await js(self, "return localStorage.getItem('f6-mini') === null && localStorage.getItem('f6-main') === '1';"))
            try await closeTab(selected!)

            let cancelled = try await newMini("alpha")
            let stale = try cancelled.previewHandoff()
            try layout.apply(.renameWorkspace(layout.activeWorkspace.id, "Changed"))
            let before = tabs.count
            do {
                try await cancelled.transferMini(confirmation: stale.token)
                throw ChromeResult.Failure.invalid
            } catch ChromeResult.Failure.unavailable {
                try check("F6-STALE-PREVIEW-DENIED", tabs.count == before && !cancelled.closing, contract: true)
            }
            await cancelled.shutdown()
            try await deniedTransfer("f6-redirect/" + UUID().uuidString, "F6-REDIRECT-KEEPS-MINI")
            try await closeTab(selected!)
            try await deniedTransfer("f6-failure/" + UUID().uuidString, "F6-FAILURE-KEEPS-MINI")
            try await closeTab(selected!)
            try await deniedTransfer("f6-http-error/" + UUID().uuidString, "F6-HTTP-ERROR-KEEPS-MINI")
            try await closeTab(selected!)

            let delayed = try await newMini("f6-delay/" + UUID().uuidString)
            let delayedPreview = try delayed.previewHandoff()
            let transfer = Task { @MainActor in try await delayed.transferMini(confirmation: delayedPreview.token) }
            try check("F6-ACCEPTED-MINI-STAYS", await wait { delayed.acceptedTransfer != nil && !delayed.closing })
            let acceptedCount = tabs.count
            do {
                try await delayed.transferMini(confirmation: delayedPreview.token)
                throw ChromeResult.Failure.invalid
            } catch ChromeResult.Failure.unavailable {
                try check("F6-DUPLICATE-TRANSFER-DENIED", tabs.count == acceptedCount, contract: true)
            }
            await delayed.shutdown()
            _ = try? await transfer.value
            try check("F6-CLOSE-AFTER-ACCEPTANCE", delayed.browsing == nil && tabs.count == acceptedCount && delayed.nativeChrome == nil)
            try await closeTab(selected!)

            try check("F6-URL-QUERY-REJECTED", !NativeWebKitStorage.permitsMiniTransferURL(origin.appendingPathComponent("alpha").appending(queryItems: [URLQueryItem(name: "secret", value: "synthetic")])), contract: true)
            try check("F6-URL-FRAGMENT-REJECTED", !NativeWebKitStorage.permitsMiniTransferURL(URL(string: origin.absoluteString + "/alpha#fragment")!), contract: true)
            let newWorkspace: WorkspaceID
            try layout.apply(.createWorkspace("Another"))
            newWorkspace = layout.catalog.workspaces.last!.id
            let previousIDs = tabs
            let previousWorkspace = layout.activeWorkspace.id
            try await switchWorkspace(newWorkspace)
            try check("F6-SWITCH-RETIREMENT", browsing == nil && bindings.isEmpty && tabs.isEmpty && layout.activeWorkspace.id == newWorkspace)
            try await switchWorkspace(previousWorkspace)
            try check("F6-SWITCH-RESTORE-BLANK", tabs == previousIDs && bindings.isEmpty && browsing == nil && tabs.allSatisfy { tabState($0).url == nil })
            try await endPrivate()
            for i in 0..<4 {
                let cycle = MainWindowController()
                try await cycle.openExternal(origin.appendingPathComponent("alpha"))
                try check("F6-CYCLE-LOAD-\(i)", await wait { loaded(cycle, "/alpha") })
                weak var held = cycle.surface(cycle.selected!)
                await cycle.shutdown()
                let released = cycle.browsing == nil && held == nil && cycle.nativeChrome == nil
                if !released, let active = cycle.browsing {
                    let detail = ["recovery": cycle.recovery?.rawValue ?? "none",
                                  "core": String(describing: await active.storage.core.summary(active.scope)),
                                  "inventory": String((await active.storage.adapter.inventory(active.scope)).count)]
                    if let data = try? JSONSerialization.data(withJSONObject: detail) {
                        FileHandle.standardOutput.write(data + Data([10]))
                    }
                }
                try check("F6-CYCLE-RELEASE-\(i)", released)
            }
            let denied = MainWindowController()
            try await denied.openExternal(origin.appendingPathComponent("alpha"))
            guard let deniedSession = denied.browsing, let deniedTab = denied.selected else { throw ChromeResult.Failure.failed }
            await deniedSession.storage.authority.revoke(deniedSession.scope)
            do {
                try await denied.load(origin.appendingPathComponent("beta"), in: deniedTab)
                throw ChromeResult.Failure.invalid
            } catch ChromeResult.Failure.unavailable {
                try check("F6-EXISTING-BINDING-REVOKED", denied.surface(deniedTab)?.url?.path != "/beta", contract: true)
            }
            // Reconcile the original test grant solely to exercise normal teardown.
            // Production code has no reauthorization shortcut.
            let cleanupGrant = await deniedSession.storage.authority.grant(deniedSession.scope, run: deniedSession.storage.run)
            denied.browsing = PrivateSession(id: deniedSession.id, storage: deniedSession.storage, scope: deniedSession.scope, context: cleanupGrant)
            await denied.shutdown()
            await shutdown()
            try check("F6-SHUTDOWN", browsing == nil && bindings.isEmpty && nativeChrome == nil)
            Self.emit("qualification", status: "PASS_NATIVE")
        } catch {
            await shutdown()
            Self.emit("qualification", status: "FAIL")
        }
    }

    func qualifyPrivateRecovery(_ origin: URL) async {
        func check(_ id: String, _ condition: Bool, contract: Bool = false) throws {
            Self.emit(id, status: condition ? (contract ? "PASS_CONTRACT" : "PASS_NATIVE") : "FAIL")
            guard condition else { throw ChromeResult.Failure.failed }
        }
        func command(_ type: String, tab: WorkspaceTabID? = nil) throws -> ChromeCommand {
            var body = ["type": type, "id": UUID().uuidString]
            if let tab { body["tab"] = tab.rawValue }
            var payload: [String: Any] = body
            payload["version"] = 1
            return try JSONDecoder().decode(ChromeCommand.self, from: JSONSerialization.data(withJSONObject: payload))
        }
        func inject(_ session: PrivateSession, _ id: ViewID) -> Bool {
            guard let view = session.storage.adapter.surface(id) else { return false }
            session.storage.adapter.webViewWebContentProcessDidTerminate(view)
            session.storage.adapter.webViewWebContentProcessDidTerminate(view)
            return true
        }
        func loaded(_ controller: MainWindowController, _ title: String, url: URL? = nil) async -> Bool {
            let deadline = ContinuousClock.now.advanced(by: .seconds(8))
            while ContinuousClock.now < deadline {
                if let id = controller.selected,
                   let view = controller.surface(id),
                   view.title == title, !view.isLoading, url == nil || view.url == url { return true }
                try? await Task.sleep(for: .milliseconds(30))
            }
            return false
        }
        func js(_ controller: MainWindowController, _ source: String) async -> Bool {
            guard let id = controller.selected, let surface = controller.surface(id) else { return false }
            return (try? await surface.callAsyncJavaScript(source, arguments: [:], in: nil, contentWorld: .page)) as? Bool == true
        }
        do {
            try startPrivate()
            let first = tabs[0]
            let address = origin.appendingPathComponent("alpha")
            try await load(address, in: first)
            let second = try addTab()
            _ = try await admit(second)
            let old = browsing!
            let firstView = bindings[first]!, secondView = bindings[second]!
            try layout.apply(.pin(first))
            try layout.apply(.createGroup("Fixture group"))
            let group = groups[0]
            try layout.apply(.group(second, WorkspaceGroupID(group.id)))
            let space = layout.activeSpace.id
            try layout.apply(.createSpace("Fixture Space"))
            try layout.apply(.selectSpace(space))
            try layout.apply(.selectTab(first))
            try layout.apply(.split(second))
            try layout.apply(.selectTab(first))
            try check("R-SETUP-MAIN-LOAD", old.storage.adapter.surface(firstView) != nil)
            try check("R-SETUP-MAIN-COMMIT", await loaded(self, "Alpha"))
            try check("R-SETUP-MAIN-MARKERS", await js(self, "localStorage.setItem('old-main','1'); document.cookie='old_main=1; Path=/'; return document.cookie.includes('old_main=1');"))
            try await openMini(address)
            guard let child = minis.values.first, let oldMini = child.browsing, let miniTab = child.selected, let miniID = child.bindings[miniTab] else {
                throw ChromeResult.Failure.failed
            }
            try check("R-SETUP-MINI-COMMIT", await loaded(child, "Alpha"))
            try check("R-SETUP-MINI-MARKERS", await js(child, "localStorage.setItem('old-mini','1'); return localStorage.getItem('old-main') === null && !document.cookie.includes('old_main=');"))
            let oldIDs = tabs
            let oldViewIDs = Set(bindings.values)
            weak var oldView = old.storage.adapter.surface(firstView)
            weak var oldStore = oldView?.configuration.websiteDataStore
            try check("R-INJECTED-FENCE", inject(old, firstView) && recovery == .retiring, contract: true)
            try check("R-OLD-SCOPE-REJECTS", old.storage.adapter.surface(firstView) == nil
                && old.storage.adapter.surface(secondView) == nil
                && !old.storage.adapter.perform(.reload, in: firstView)
                && !old.storage.adapter.perform(.load(address), in: firstView), contract: true)
            let early = await run(try command("recoverPrivate"))
            try check("R-RETIRING-REJECTS-RECOVER", early.error != nil, contract: true)
            await retirementTask?.value
            let oldSummary = await old.storage.core.summary(old.scope)
            let oldInventory = await old.storage.adapter.inventory(old.scope)
            let oldAuthority = await old.storage.authority.current(old.scope)
            try check("R-OLD-RETIREMENT", recovery == .ready && oldSummary?.state == .retired
                && oldInventory.isEmpty && oldAuthority == nil && oldView == nil && oldStore == nil)
            try check("R-MINI-UNAFFECTED", child.browsing?.id == oldMini.id && child.recovery == nil)
            try check("R-MINI-MARKER-RETAINED", await js(child, "return localStorage.getItem('old-mini') === '1';"))
            let restored = await run(try command("recoverPrivate"))
            try check("R-WORKSPACE-STRUCTURE", restored.error == nil && tabs == oldIDs && spaces.count == 2 && groups == [group]
                && membership(first)?.tab.pinned == true && membership(second)?.tab.groupId?.rawValue == group.id
                && selected == first && splitTabs == tabs)
            try check("F6-RECOVERY-LAZY", bindings.isEmpty && browsing == nil && tabs.allSatisfy { tabState($0).url == nil }, contract: true)
            let retry = await run(try command("recoverPrivate"))
            try check("R-REPEAT-RECOVER-REJECTED", retry.error == .unavailable && browsing == nil, contract: true)
            privateContentTerminated(old.id)
            try check("R-STALE-SESSION-CALLBACK", recovery == nil && browsing == nil, contract: true)
            try layout.apply(.selectTab(second))
            let freshSecond = try await admit(second)
            try layout.apply(.selectTab(first))
            let freshFirst = try await admit(first)
            guard let fresh = browsing else { throw ChromeResult.Failure.failed }
            try check("R-FRESH-IDENTITIES", fresh.id != old.id && fresh.storage.run != old.storage.run
                && Set(bindings.values).isDisjoint(with: oldViewIDs) && recovery == nil)
            try check("R-FRESH-BLANK-STORES", [freshFirst, freshSecond].allSatisfy { id in
                guard let view = fresh.storage.adapter.surface(id) else { return false }
                return view.url == nil && !view.configuration.websiteDataStore.isPersistent
                    && view.configuration.websiteDataStore.identifier == nil
            })
            try check("R-FRESH-NAVIGATION", fresh.storage.adapter.perform(.load(address), in: freshFirst))
            try check("R-FRESH-COMMIT", await loaded(self, "Alpha"))
            try check("R-NO-TRANSFERRED-WEB-DATA", await js(self, "return localStorage.getItem('old-main') === null && localStorage.getItem('old-mini') === null && !document.cookie.includes('old_main=');"))
            presentation = (true, 236, 126)
            updateSurface()
            try check("R-SPLIT-REATTACHED", page.arrangedSubviews.count == 2)

            let signin = origin.appendingPathComponent("fixture-signin")
            let account = origin.appendingPathComponent("fixture-account")
            try check("R-AUTH-OPEN", fresh.storage.adapter.perform(.load(signin), in: freshFirst))
            try check("R-AUTH-FORM", await loaded(self, "Fixture sign in"))
            try check("R-AUTH-POST", await js(self, "const form = document.forms[0]; form.elements.account.value = 'fixture'; form.elements.password.value = 'disposable'; setTimeout(() => form.requestSubmit(), 0); return true;"))
            try check("R-AUTH-REDIRECT", await loaded(self, "Fixture signed in", url: account))
            var continuity = URLComponents(url: account, resolvingAgainstBaseURL: false)!
            continuity.queryItems = [URLQueryItem(name: "probe", value: "continuity")]
            guard let continuityURL = continuity.url else { throw ChromeResult.Failure.failed }
            try check("R-AUTH-CONTINUITY-LOAD", fresh.storage.adapter.perform(.load(continuityURL), in: freshFirst))
            try check("R-AUTH-CONTINUITY", await loaded(self, "Fixture signed in", url: continuityURL))
            try check("R-AUTH-MINI-LOAD", oldMini.storage.adapter.perform(.load(account), in: miniID))
            try check("R-AUTH-MINI-ISOLATION", await loaded(child, "Fixture signed out"))
            try check("R-AUTH-LOGOUT-POST", await js(self, "const form = document.forms[0]; setTimeout(() => form.requestSubmit(), 0); return true;"))
            try check("R-AUTH-LOGOUT", await loaded(self, "Fixture signed out"))

            try check("R-INJECTED-SIMULTANEOUS", inject(fresh, freshFirst) && inject(oldMini, miniID)
                && recovery == .retiring && child.recovery == .retiring, contract: true)
            await retirementTask?.value
            await child.retirementTask?.value
            try check("R-TWO-RETIRED-SCOPES", recovery == .ready && child.recovery == .ready
                && browsing == nil && child.browsing == nil)
            let miniRestored = await child.run(try command("recoverPrivate"))
            guard let selectedMini = child.selected else { throw ChromeResult.Failure.failed }
            try check("R-MINI-INDEPENDENT-REBUILD", miniRestored.error == nil && selectedMini == miniTab
                && child.browsing == nil && browsing == nil, contract: true)
            try await child.load(address, in: selectedMini)
            if let newMini = child.browsing {
                try check("R-MINI-FRESH-NAVIGATION", newMini.id != oldMini.id && newMini.id != fresh.id)
                try check("R-MINI-FRESH-COMMIT", await loaded(child, "Alpha"))
                try check("R-MINI-NO-TRANSFERRED-WEB-DATA", await js(child, "return localStorage.getItem('old-mini') === null && !document.cookie.includes('old_main=');"))
            } else { throw ChromeResult.Failure.failed }

            let held = MainWindowController()
            try await held.openExternal(address)
            guard let heldSession = held.browsing, let heldTab = held.selected, let heldID = held.bindings[heldTab],
                  let retainedView = heldSession.storage.adapter.surface(heldID) else { throw ChromeResult.Failure.failed }
            try check("R-INJECTED-RETAINED-VIEW", inject(heldSession, heldID), contract: true)
            await held.retirementTask?.value
            let failure = await held.run(try command("recoverPrivate"))
            try check("R-RETIREMENT-UNCONFIRMED", recovery == .ready && held.recovery == .failed
                && held.browsing?.id == heldSession.id && failure.error == .unavailable
                && retainedView.superview == nil && heldSession.storage.adapter.surface(heldID) == nil)
            await held.shutdown()

            let invalid = MainWindowController()
            invalid.recovery = .ready
            let invalidResult = await invalid.run(try command("recoverPrivate"))
            try check("R-FAILED-STAGED-PUBLICATION", invalidResult.error != nil && invalid.recovery == .failed
                && invalid.browsing == nil && invalid.tabs.isEmpty)
            await invalid.shutdown()

            if let newMini = child.browsing, let tab = child.selected, let view = child.bindings[tab] {
                try check("R-INJECTED-CLOSE-BOUNDARY", inject(newMini, view), contract: true)
                await child.shutdown()
                try check("R-CLOSE-JOINS-RETIREMENT", child.closing && child.retirementTask == nil
                    && child.browsing == nil && minis.isEmpty)
            } else { throw ChromeResult.Failure.failed }
            let closingWindow = MainWindowController()
            try await closingWindow.openExternal(address)
            guard let closingSession = closingWindow.browsing, let closingTab = closingWindow.selected, let closingView = closingWindow.bindings[closingTab] else {
                throw ChromeResult.Failure.failed
            }
            // Model a callback after close has started but before Core teardown finishes.
            closingWindow.closing = true
            try check("R-CLOSING-CALLBACK-DOES-NOT-START-RECOVERY",
                inject(closingSession, closingView) && closingWindow.retirementTask == nil
                    && closingWindow.recovery == nil && closingSession.storage.adapter.surface(closingView) == nil,
                contract: true)
            await closingWindow.shutdown()
            try check("R-CLOSING-SINGLE-TEARDOWN", closingWindow.browsing == nil && closingWindow.nativeChrome == nil)

            await shutdown()
            try check("R-SHUTDOWN-JOINS", closing && retirementTask == nil && nativeChrome == nil)
            Self.emit("qualification", status: "PASS_NATIVE")
        } catch {
            Self.emit("qualification", status: "FAIL")
        }
    }

    func qualifyReliability(_ origin: URL) async {
        func emit(_ id: String, _ status: String, _ detail: String = "") {
            let data = try! JSONSerialization.data(withJSONObject: ["testID": id, "status": status, "detail": detail], options: [.sortedKeys])
            FileHandle.standardOutput.write(data + Data([10]))
        }
        func check(_ id: String, _ value: Bool, status: String = "PASS_NATIVE") throws {
            emit(id, value ? status : "FAIL")
            if !value { throw ChromeResult.Failure.failed }
        }
        func wait(_ condition: () async -> Bool) async -> Bool {
            for _ in 0..<100 {
                if await condition() { return true }
                try? await Task.sleep(for: .milliseconds(100))
            }
            return false
        }
        func title(_ expected: String, on controller: MainWindowController? = nil) -> Bool {
            let c = controller ?? self
            guard let id = c.selected, let surface = c.surface(id) else { return false }
            return !surface.isLoading && surface.title == expected
        }
        func js(_ code: String, on controller: MainWindowController? = nil) async -> Bool {
            let c = controller ?? self
            guard let id = c.selected, let surface = c.surface(id) else { return false }
            return ((try? await surface.callAsyncJavaScript(code, arguments: [:], in: nil, contentWorld: .page)) as? Bool) == true
        }
        func closedCycle() async throws -> ReliabilityReferences {
            let references = ReliabilityReferences()
            let c = MainWindowController()
            references.controller = c
            c.showWindow(nil)
            try await c.openExternal(origin.appendingPathComponent("alpha"))
            guard let id = c.selected else { throw ChromeResult.Failure.failed }
            references.surface = c.surface(id)
            try await c.openMini(origin.appendingPathComponent("beta"))
            if let mini = c.minis.values.first, let selected = mini.selected {
                references.mini = mini
                references.miniSurface = mini.surface(selected)
            }
            await c.shutdown()
            return references
        }
        do {
            try check("URL-POLICY-HTTPS", ExternalBrowserRoute.parse(URL(string: "https://example.com/")!) != nil, status: "PASS_CONTRACT")
            try check("URL-POLICY-LOOPBACK", ExternalBrowserRoute.parse(origin) != nil, status: "PASS_CONTRACT")
            for (index, input) in ["http://example.com/", "javascript:alert(1)", "file:///tmp/private", "data:text/html,test", "https://u:p@example.com/", "vezham://open?url=javascript%3Aalert(1)", "vezham://open?url=https%3A%2F%2Fexample.com&url=https%3A%2F%2Fexample.org", "vezham://u@open?url=https%3A%2F%2Fexample.com", "vezham://open/extra?url=https%3A%2F%2Fexample.com", "vezham://open?url=https%3A%2F%2Fexample.com#ignored"].enumerated() {
                try check("URL-REJECT-\(index + 1)", ExternalBrowserRoute.parse(URL(string: input)!) == nil, status: "PASS_CONTRACT")
            }
            try check("URL-IPV6-LOOPBACK", NativeWebKitStorage.permitsInteractiveURL(URL(string: "http://[::1]:1234/")!), status: "PASS_CONTRACT")
            try check("LIFE-CHROME-READY", await wait { self.chrome?.isLoading == false })
            try await openExternal(origin.appendingPathComponent("alpha"))
            try check("URL-MAIN-LOAD", await wait { title("Alpha") })
            let first = selected!
            guard let browsing, let firstView = bindings[first] else { throw ChromeResult.Failure.failed }
            let a = browsing.storage.adapter
            try check("LIFE-NATIVE-VIEW", a.surface(firstView) != nil && a.ownedViews(browsing.scope).count == 1)
            try check("COMP-MAIN-STORAGE-SET", await js("localStorage.setItem('main-only','synthetic');document.cookie='mainOnly=synthetic;path=/';return true;"))
            try check("URL-REDIRECT-ISSUED", a.perform(.load(origin.appendingPathComponent("redirect")), in: firstView))
            try check("URL-REDIRECT-COMMITTED", await wait { title("Beta") })
            try check("URL-BACK-ISSUED", a.perform(.back, in: firstView))
            try check("URL-BACK-COMMITTED", await wait { title("Alpha") })
            try check("URL-FORWARD-ISSUED", a.perform(.forward, in: firstView))
            try check("URL-FORWARD-COMMITTED", await wait { title("Beta") })
            try check("LIFE-FAILURE-ISSUED", a.perform(.load(origin.appendingPathComponent("failure")), in: firstView))
            try check("LIFE-FAILURE-OBSERVED", await wait { a.navigationFailed(in: firstView) })
            try check("LIFE-RECOVERY-ISSUED", a.perform(.load(origin.appendingPathComponent("alpha")), in: firstView))
            try check("LIFE-RECOVERY-COMMITTED", await wait { title("Alpha") && !a.navigationFailed(in: firstView) })
            try await openMini(origin.appendingPathComponent("alpha"))
            var miniController: MainWindowController? = minis.values.first
            guard let child = miniController else { throw ChromeResult.Failure.failed }
            try check("LIFE-MINI-LOADED", await wait { title("Alpha", on: child) })
            try check("COMP-MINI-STORAGE-ISOLATION", await js("return localStorage.getItem('main-only')===null && !document.cookie.includes('mainOnly=');", on: child))
            try check("COMP-MINI-STORAGE-SET", await js("localStorage.setItem('mini-only','synthetic');return true;", on: child))
            try check("COMP-MAIN-STORAGE-ISOLATION", await js("return localStorage.getItem('mini-only')===null && localStorage.getItem('main-only')==='synthetic';"))
            let preview = try child.previewHandoff()
            try await child.transferMini(confirmation: preview.token)
            try check("URL-MINI-TRANSFER-DESTINATION", selected != first)
            await child.shutdown()
            miniController = nil
            try check("LIFE-MINI-CLEANUP", await wait { minis.isEmpty && child.browsing == nil && child.nativeChrome == nil })
            try check("COMP-TRANSFER-URL-ONLY", await wait { title("Alpha") })
            try check("COMP-TRANSFER-STORAGE-UNCHANGED", await js("return localStorage.getItem('mini-only')===null && localStorage.getItem('main-only')==='synthetic';"))
            // Real WebKit target-blank delegate path; DOM click is not a pointer qualification.
            let current = bindings[selected!]!
            try check("COMP-TARGET-LOAD", a.perform(.load(origin.appendingPathComponent("target")), in: current))
            try check("COMP-TARGET-READY", await wait { a.surface(current)?.isLoading == false && a.surface(current)?.url?.path == "/target" })
            try check("COMP-TARGET-CLICK", await js("document.querySelector('#popup').click(); return true;"))
            try check("COMP-TARGET-MINI", await wait { minis.values.first.map { title("Beta", on: $0) } == true })
            for child in Array(minis.values) { await child.shutdown() }
            try check("LIFE-POPUP-CLEANUP", minis.isEmpty)
            try await openMini(origin.appendingPathComponent("beta"))
            guard let lastTabMini = minis.values.first, let lastTab = lastTabMini.selected else { throw ChromeResult.Failure.failed }
            let closePayload: [String: Any] = ["version": 1, "id": "last-mini-tab", "type": "close", "tab": lastTab.rawValue]
            let closeCommand = try JSONDecoder().decode(ChromeCommand.self, from: JSONSerialization.data(withJSONObject: closePayload))
            let closedLast = await lastTabMini.run(closeCommand)
            try check("LIFE-MINI-LAST-TAB-COMMAND", closedLast.error == nil)
            try check("LIFE-MINI-LAST-TAB-WINDOW", await wait { minis.isEmpty && lastTabMini.window?.isVisible == false && lastTabMini.chrome == nil })

            try await openExternal(origin.appendingPathComponent("gamma"))
            let second = selected!
            try check("LIFE-SECOND-VIEW", await wait { title("Gamma") })
            guard let secondView = bindings[second] else { throw ChromeResult.Failure.failed }
            try layout.apply(.selectTab(first))
            try layout.apply(.split(second))
            presentation = (true, 236, 126)
            updateSurface()
            try check("LIFE-SPLIT-TWO-NATIVE-VIEWS", page.arrangedSubviews.count == 2 && a.surface(firstView) !== a.surface(secondView))
            try await closeTab(second)
            updateSurface()
            try check("LIFE-SPLIT-CLOSE", splitTabs.isEmpty && a.surface(secondView) == nil && tabs.contains(first))
            for index in 1...4 {
                let refs = try await closedCycle()
                try check("LIFE-RELEASE-\(index)", await wait { refs.controller == nil && refs.surface == nil && refs.mini == nil && refs.miniSurface == nil })
            }
            // Close races a suspended external-navigation admission; cleanup must eventually win.
            let racer = MainWindowController()
            racer.showWindow(nil)
            let receiveTask = Task { @MainActor in await racer.receive(origin.appendingPathComponent("alpha")) }
            await Task.yield()
            await racer.shutdown()
            _ = await receiveTask.value
            try check("LIFE-CLOSE-DURING-RECEIVE", racer.browsing == nil && racer.tabs.isEmpty && racer.nativeChrome == nil && racer.closing)
            try await endPrivate()
            try check("LIFE-END-SESSION", self.browsing == nil && tabs.isEmpty && minis.isEmpty && page.arrangedSubviews.isEmpty)
            try startPrivate()
            try await load(origin.appendingPathComponent("alpha"), in: selected!)
            try check("COMP-NEW-PRIVATE-LOAD", self.browsing != nil)
            try check("COMP-NEW-PRIVATE-READY", await wait { title("Alpha") })
            try check("COMP-NEW-PRIVATE-CLEAN", await js("return localStorage.getItem('main-only')===null && localStorage.getItem('mini-only')===null && !document.cookie.includes('mainOnly=');"))
            await shutdown()
            try check("LIFE-MAIN-SHUTDOWN", self.browsing == nil && nativeChrome == nil && tabs.isEmpty)
            emit("qualification", "PASS_NATIVE")
        } catch { emit("qualification", "FAIL", "See preceding case and preserved native stderr") }
    }
}
#endif
