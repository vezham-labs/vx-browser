import AppKit
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
final class MainWindowController: NSWindowController, WKNavigationDelegate, NSWindowDelegate, NSSplitViewDelegate, WKScriptMessageHandlerWithReply {
    private struct PrivateSession {
        let id: PrivateSessionID
        let storage: NativeStorageSession
        let scope: Scope
        let context: CallerContext
    }

    private let root = NSView()
    private var chrome: WKWebView?
    private let page = NSSplitView()
    private let panes = [FocusPane(), FocusPane()]
    private var splitTabs: [ViewID] = []
    private let mini: Bool
    private var minis: [UUID: MainWindowController] = [:]
    private var spaces = [ChromeSpace(id: UUID().uuidString.lowercased(), name: "Personal")]
    private var spaceIndex = 0
    private struct Organization {
        var space: String
        var pinned = false
        var group: String?
    }
    private var organization: [ViewID: Organization] = [:]
    private var groups: [ChromeGroup] = []
    var transferToMain: ((URL) async -> Bool)?
    var didClose: (() -> Void)?
    private var activeSpace: String { spaces[spaceIndex].id }
    private var chromeURL: URL?
    private var browsing: PrivateSession?
    private var tabs: [ViewID] = []
    private var selected: ViewID?
    private var busy = false
    private var closing = false
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
            guard let self, ["l", "t", "w", "r", "k", ",", "[", "]"].contains(key),
                  let chrome = self.chrome, chrome.url == self.chromeURL,
                  key != "w" || !self.tabs.isEmpty else { return false }
            self.window?.makeFirstResponder(chrome)
            if self.mini, ["l", "t", "k"].contains(key) {
                chrome.evaluateJavaScript("document.querySelector('.mini-address input')?.focus();")
                return true
            }
            chrome.callAsyncJavaScript("window.dispatchEvent(new CustomEvent('vezham-shortcut', {detail:key}));",
                arguments: ["key": key], in: nil, in: .page, completionHandler: nil)
            return true
        }
    }

    required init?(coder: NSCoder) { fatalError("Storyboard initialization is not supported") }

    private func configureContent(_ window: NSWindow) {
        window.contentView = root
        guard let entry = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "chrome") else {
            let message = NSTextField(labelWithString: "Browser chrome is unavailable. Build with the native host build target.")
            message.frame = NSRect(x: 28, y: 40, width: 580, height: 28)
            root.addSubview(message)
            return
        }
        chromeURL = entry.standardizedFileURL
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController.addScriptMessageHandler(self, contentWorld: .page, name: "browserChrome")
        let web = WKWebView(frame: root.bounds, configuration: configuration)
        web.navigationDelegate = self
        web.autoresizingMask = [.width, .height]
        root.addSubview(web)
        page.delegate = self
        page.isVertical = true
        page.dividerStyle = .thin
        root.addSubview(page)
        page.isHidden = true
        chrome = web
        web.loadFileURL(entry, allowingReadAccessTo: entry.deletingLastPathComponent())
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

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        let allowed = webView === chrome && action.targetFrame?.isMainFrame == true &&
            action.request.url?.standardizedFileURL == chromeURL
        decisionHandler(allowed ? .allow : .cancel)
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) async -> (Any?, String?) {
        guard let chrome, message.webView === chrome, message.frameInfo.isMainFrame,
              message.frameInfo.request.url?.standardizedFileURL == chromeURL,
              chrome.url?.standardizedFileURL == chromeURL,
              let body = message.body as? [String: Any],
              JSONSerialization.isValidJSONObject(body),
              let bytes = try? JSONSerialization.data(withJSONObject: body), bytes.count <= 12_288,
              let command = try? JSONDecoder().decode(ChromeCommand.self, from: bytes),
              command.version == 1, command.id.count <= 100, !command.id.isEmpty else {
            return (nil, "Invalid browser chrome request")
        }
        let result = await run(command)
        guard let encoded = try? JSONEncoder().encode(result),
              let response = try? JSONSerialization.jsonObject(with: encoded) else {
            return (nil, "Could not encode browser state")
        }
        return (response, nil)
    }

    private func result(_ command: ChromeCommand, error: ChromeResult.Failure? = nil, text: String? = nil) -> ChromeResult {
        let revision = lastState?.revision ?? 0
        let session = browsing == nil ? "inactive" : "private"
        let sessionID = browsing?.id.rawValue
        let active = selected?.rawValue.lowercased()
        let items = tabs.map(tabState)
        let observed = ChromeState(revision: revision, session: session, sessionID: sessionID,
                                   tabs: items, selected: active, appearance: appearance, spaces: spaces, activeSpace: activeSpace,
                                   groups: groups, split: splitTabs.map { $0.rawValue.lowercased() },
                                   splitCompact: page.bounds.width < 600, mini: mini)
        let state = observed == lastState ? observed : ChromeState(revision: revision + 1,
            session: session, sessionID: sessionID, tabs: items, selected: active, appearance: appearance, spaces: spaces, activeSpace: activeSpace,
                                   groups: groups, split: splitTabs.map { $0.rawValue.lowercased() },
                                   splitCompact: page.bounds.width < 600, mini: mini)
        lastState = state
        return ChromeResult(id: command.id, state: state, error: error, text: text)
    }

    private func tabState(_ id: ViewID) -> ChromeTab {
        let adapter = browsing?.storage.adapter
        let web = adapter?.surface(id)
        let requested = adapter?.requestedURL(in: id)
        let effectiveURL = adapter?.navigationFailed(in: id) == true ? requested ?? web?.url : web?.url ?? requested
        let url = effectiveURL.flatMap { value -> String? in
            guard let parts = URLComponents(url: value, resolvingAgainstBaseURL: false),
                  parts.user == nil, parts.password == nil else { return nil }
            return String(value.absoluteString.prefix(2048))
        }
        let failure: String? = web == nil ? "content-unavailable" : adapter?.navigationFailed(in: id) == true ? "load-failed" : nil
        let connection: String
        if failure != nil || web?.isLoading != false { connection = "unknown" }
        else if web?.url?.scheme == "https", web?.hasOnlySecureContent == true { connection = "encrypted" }
        else if web?.url?.scheme == "http" { connection = "unencrypted" }
        else { connection = "unknown" }
        let title = web?.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return ChromeTab(id: id.rawValue.lowercased(), title: String((title.isEmpty ? (web?.url?.host ?? "New tab") : title).prefix(120)),
                         url: url, loading: web?.isLoading ?? false, progress: web?.estimatedProgress ?? 0,
                         back: web?.canGoBack ?? false, forward: web?.canGoForward ?? false, connection: connection, favicon: adapter?.favicon(in: id), failure: failure,
                         space: organization[id]?.space ?? activeSpace, pinned: organization[id]?.pinned ?? false,
                         group: organization[id]?.group)
    }

    private func run(_ command: ChromeCommand) async -> ChromeResult {
        if command.type == .snapshot { return result(command) }
        if command.type == .presentation {
            guard let left = command.left, let top = command.top, let visible = command.visible,
                  left.isFinite, top.isFinite, (0...340).contains(left), (40...128).contains(top) else {
                return result(command, error: .invalid)
            }
            presentation = (visible, left, top)
            updateSurface()
            return result(command)
        }
        guard !busy, !closing else { return result(command, error: .busy) }
        busy = true
        defer {
            busy = false
            if closing { scheduleCleanup() }
            else { updateSurface() }
        }
        do {
            switch command.type {
            case .spaceCreate, .spaceRename, .spaceSwitch, .spaceDelete, .groupCreate,
                 .groupRename, .groupToggle, .groupMove, .groupDelete:
                try organize(command)
            case .unsplit: splitTabs = []
            case .miniOpen:
                guard !mini else { throw ChromeResult.Failure.unavailable }
                let url = command.url.flatMap(URL.init(string:)) ??
                    tabs.first(where: { UUID(uuidString: $0.rawValue) == command.tab }).flatMap { browsing?.storage.adapter.surface($0)?.url }
                guard let url else { throw ChromeResult.Failure.invalid }
                try await openMini(url)
            case .miniTransfer:
                guard mini, let selected, let url = browsing?.storage.adapter.surface(selected)?.url,
                      let transferToMain, await transferToMain(url) else { throw ChromeResult.Failure.failed }
                try await endPrivate()
                window?.close()
            case .startPrivate:
                guard browsing == nil else { throw ChromeResult.Failure.invalid }
                try await startPrivate()
            case .endPrivate:
                try await endPrivate()
            case .newTab:
                _ = try await addTab()
            case .appearance:
                guard let value = command.value else { throw ChromeResult.Failure.invalid }
                try Self.settings().set(value == .system ? .system : value == .light ? .light : .dark)
                appearance = value
                NSApp.appearance = value == .system ? nil : NSAppearance(named: value == .light ? .aqua : .darkAqua)
            default:
                guard let raw = command.tab, let id = tabs.first(where: { UUID(uuidString: $0.rawValue) == raw }),
                      let browsing else { throw ChromeResult.Failure.unavailable }
                if let text = try await tabCommand(command, id: id, browsing: browsing) { return result(command, text: text) }
            }
            return result(command)
        } catch let failure as ChromeResult.Failure {
            return result(command, error: failure)
        } catch {
            return result(command, error: .failed)
        }
    }

    private func startPrivate() async throws {
        let storage = try NativeStorageSession.privateOnly(interactiveBrowsing: true)
        let id = try PrivateSessionID(UUID().uuidString)
        let scope = Scope.privateSession(id)
        let context = await storage.authority.grant(scope, run: storage.run)
        guard case .success = await storage.core.registerPrivate(id, context: context, operation: try operation()),
              case .success = await storage.core.resolve(scope, context: context, operation: try operation()) else {
            await storage.authority.revoke(scope)
            throw ChromeResult.Failure.failed
        }
        browsing = PrivateSession(id: id, storage: storage, scope: scope, context: context)
        storage.adapter.openExternalLink = { [weak self] url in
            guard let self else { return }
            Task { @MainActor in
                do { try await self.openMini(url) }
                catch { NSSound.beep() }
            }
        }
        do { _ = try await addTab() }
        catch {
            await discard()
            throw error
        }
    }

    private func addTab() async throws -> ViewID {
        guard let browsing, tabs.count < 24 else { throw ChromeResult.Failure.unavailable }
        let id = try ViewID(UUID().uuidString)
        let opened = await browsing.storage.open(browsing.scope, context: browsing.context, view: id, operation: try operation())
        guard case .success(.activated(id)) = opened else { throw ChromeResult.Failure.failed }
        tabs.append(id)
        organization[id] = Organization(space: activeSpace)
        selected = id
        return id
    }

    private func endPrivate() async throws {
        while let id = tabs.last { try await closeTab(id) }
        if browsing != nil { await discard() }
    }

    private func closeTab(_ id: ViewID) async throws {
        guard let browsing, let index = tabs.firstIndex(of: id) else { throw ChromeResult.Failure.unavailable }
        if selected == id || splitTabs.contains(id) { detachContent() }
        let closed = await browsing.storage.core.closeView(browsing.scope, view: id, context: browsing.context, operation: try operation())
        guard case .success(.viewClosed) = closed else {
            await discard()
            throw ChromeResult.Failure.failed
        }
        tabs.remove(at: index)
        organization.removeValue(forKey: id)
        if splitTabs.contains(id) { splitTabs = [] }
        if selected == id { selected = tabs.last(where: { organization[$0]?.space == activeSpace }) }
        if tabs.isEmpty { await discard() }
    }

    private func discard() async {
        detachContent()
        if let browsing {
            await browsing.storage.adapter.preventAcquisition(in: browsing.scope)
            await browsing.storage.authority.revoke(browsing.scope)
        }
        browsing = nil
        tabs = []
        selected = nil
        organization = [:]
        groups = []
        splitTabs = []
        spaces = [ChromeSpace(id: UUID().uuidString.lowercased(), name: "Personal")]
        spaceIndex = 0
    }

    private func tabCommand(_ command: ChromeCommand, id: ViewID, browsing: PrivateSession) async throws -> String? {
        let adapter = browsing.storage.adapter
        let navigation: NativeWebKitStorage.InteractiveNavigation
        switch command.type {
        case .activate:
            guard let space = organization[id]?.space, let index = spaces.firstIndex(where: { $0.id == space }) else {
                throw ChromeResult.Failure.invalid
            }
            if index != spaceIndex { spaceIndex = index; splitTabs = [] }
            if !splitTabs.contains(id) { splitTabs = [] }
            selected = id
            return nil
        case .pin:
            organization[id]?.pinned.toggle()
            return nil
        case .tabSpace:
            guard let target = command.target?.uuidString.lowercased(), spaces.contains(where: { $0.id == target }) else {
                throw ChromeResult.Failure.invalid
            }
            organization[id]?.space = target
            organization[id]?.group = nil
            splitTabs = []
            if selected == id { selected = tabs.last(where: { organization[$0]?.space == activeSpace }) }
            return nil
        case .tabGroup:
            let target = command.target?.uuidString.lowercased()
            if let target {
                guard let group = groups.first(where: { $0.id == target }), group.space == organization[id]?.space else {
                    throw ChromeResult.Failure.invalid
                }
            }
            organization[id]?.group = target
            organization[id]?.pinned = false
            return nil
        case .split:
            guard !mini, let first = selected, first != id, organization[first]?.space == organization[id]?.space else {
                throw ChromeResult.Failure.invalid
            }
            splitTabs = [first, id]
            selected = id
            return nil
        case .close: try await closeTab(id); return nil
        case .duplicate:
            let source = adapter.surface(id)?.url
            let new = try await addTab()
            if let source, !adapter.perform(.load(source), in: new) { throw ChromeResult.Failure.failed }
            return nil
        case .move:
            guard let from = tabs.firstIndex(of: id), let offset = command.offset, (-24...24).contains(offset) else {
                throw ChromeResult.Failure.invalid
            }
            let to = max(0, min(tabs.count - 1, from + offset))
            tabs.remove(at: from)
            tabs.insert(id, at: to)
            return nil
        case .copy:
            guard let value = tabState(id).url else { throw ChromeResult.Failure.unavailable }
            NSPasteboard.general.clearContents()
            guard NSPasteboard.general.setString(value, forType: .string) else { throw ChromeResult.Failure.failed }
            return nil
        case .paste:
            guard let value = NSPasteboard.general.string(forType: .string), value.utf8.count <= 8192 else {
                throw ChromeResult.Failure.unavailable
            }
            return value
        case .navigate:
            guard let value = command.url, value.utf8.count <= 8192, let url = URL(string: value) else {
                throw ChromeResult.Failure.invalid
            }
            navigation = .load(url)
        case .back: navigation = .back
        case .forward: navigation = .forward
        case .reload: navigation = .reload
        case .stop: navigation = .stop
        default: throw ChromeResult.Failure.invalid
        }
        guard adapter.perform(navigation, in: id) else { throw ChromeResult.Failure.unavailable }
        return nil
    }

    private func operation() throws -> OperationID { try OperationID(UUID().uuidString) }

    private func detachContent() {
        for pane in panes { pane.subviews.forEach { $0.removeFromSuperview() }; pane.removeFromSuperview() }
    }

    private func updateSurface() {
        let bounds = root.bounds
        let left = CGFloat(presentation.left), top = CGFloat(presentation.top)
        page.frame = NSRect(x: left, y: 29, width: max(0, bounds.width - left), height: max(0, bounds.height - top - 29))
        guard presentation.visible, let selected else { page.isHidden = true; return }
        let visible = splitTabs.count == 2 && page.bounds.width >= 600 ? splitTabs : [selected]
        let surfaces = visible.compactMap { browsing?.storage.adapter.surface($0) }
        guard surfaces.count == visible.count else { page.isHidden = true; return }
        let changed = page.arrangedSubviews.count != visible.count ||
            visible.enumerated().contains { index, _ in surfaces[index].superview !== panes[index] }
        if changed {
            detachContent()
            for (index, id) in visible.enumerated() {
                let pane = panes[index], surface = surfaces[index]
                pane.focus = { [weak self] in self?.selected = id; self?.updateBorders() }
                pane.frame = NSRect(x: 0, y: 0, width: page.bounds.width / CGFloat(visible.count), height: page.bounds.height)
                surface.frame = pane.bounds.insetBy(dx: 2, dy: 2)
                surface.autoresizingMask = [.width, .height]
                pane.addSubview(surface)
                page.addArrangedSubview(pane)
            }
            page.adjustSubviews()
        }
        updateBorders()
        page.isHidden = false
    }

    private func updateBorders() {
        let visible = splitTabs.count == 2 && page.bounds.width >= 600 ? splitTabs : selected.map { [$0] } ?? []
        for (index, pane) in panes.enumerated() {
            pane.wantsLayer = true
            pane.layer?.borderWidth = visible.count == 2 ? 2 : 0
            pane.layer?.borderColor = (visible.indices.contains(index) && visible[index] == selected
                ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
        }
    }

    private func organize(_ command: ChromeCommand) throws {
        guard !mini, browsing != nil else { throw ChromeResult.Failure.unavailable }
        func name() throws -> String {
            guard let value = command.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty, value.count <= 40, !value.unicodeScalars.contains(where: { $0.value < 32 }) else {
                throw ChromeResult.Failure.invalid
            }
            return value
        }
        let target = command.target?.uuidString.lowercased()
        switch command.type {
        case .spaceCreate:
            guard spaces.count < 12 else { throw ChromeResult.Failure.unavailable }
            spaces.append(ChromeSpace(id: UUID().uuidString.lowercased(), name: try name()))
            spaceIndex = spaces.count - 1; selected = nil; splitTabs = []
        case .spaceRename, .spaceSwitch, .spaceDelete:
            guard let index = spaces.firstIndex(where: { $0.id == target }) else { throw ChromeResult.Failure.invalid }
            if command.type == .spaceRename { spaces[index].name = try name() }
            else if command.type == .spaceSwitch {
                spaceIndex = index; selected = tabs.last(where: { organization[$0]?.space == activeSpace }); splitTabs = []
            } else {
                guard spaces.count > 1, !tabs.contains(where: { organization[$0]?.space == target }) else {
                    throw ChromeResult.Failure.unavailable
                }
                let previous = activeSpace
                spaces.remove(at: index)
                spaceIndex = spaces.firstIndex(where: { $0.id == previous }) ?? 0
                groups.removeAll { $0.space == target }
                selected = tabs.last(where: { organization[$0]?.space == activeSpace }); splitTabs = []
            }
        case .groupCreate:
            guard groups.count < 32 else { throw ChromeResult.Failure.unavailable }
            groups.append(ChromeGroup(id: UUID().uuidString.lowercased(), space: activeSpace, name: try name()))
        case .groupRename, .groupToggle, .groupMove, .groupDelete:
            guard let index = groups.firstIndex(where: { $0.id == target && $0.space == activeSpace }) else {
                throw ChromeResult.Failure.invalid
            }
            switch command.type {
            case .groupRename: groups[index].name = try name()
            case .groupToggle: groups[index].collapsed.toggle()
            case .groupMove:
                guard let offset = command.offset, [-1, 1].contains(offset) else { throw ChromeResult.Failure.invalid }
                let next = index + offset
                if groups.indices.contains(next), groups[next].space == activeSpace { groups.swapAt(index, next) }
            default:
                for id in tabs where organization[id]?.group == target { organization[id]?.group = nil }
                groups.remove(at: index)
            }
        default: throw ChromeResult.Failure.invalid
        }
    }

    func openMini(_ url: URL) async throws {
        guard validWebURL(url), minis.count < 6 else { throw ChromeResult.Failure.unavailable }
        let id = UUID()
        let child = MainWindowController(mini: true)
        child.busy = true
        defer {
            child.busy = false
            if child.closing { child.scheduleCleanup() }
        }
        minis[id] = child
        child.transferToMain = { [weak self] url in
            guard let self else { return false }
            return await self.receive(url)
        }
        child.didClose = { [weak self] in self?.minis.removeValue(forKey: id) }
        child.showWindow(nil)
        child.window?.makeKeyAndOrderFront(nil)
        do { try await child.startPrivate()
            guard !child.closing, let selected = child.selected,
                  child.browsing?.storage.adapter.perform(.load(url), in: selected) == true else {
                throw ChromeResult.Failure.failed
            }
        } catch {
            child.window?.close()
            throw error
        }
    }

    private func validWebURL(_ url: URL) -> Bool {
        guard let host = url.host, url.user == nil, url.password == nil else { return false }
        return url.scheme == "https" || (url.scheme == "http" && ["127.0.0.1", "localhost", "::1"].contains(host))
    }

    private func receive(_ url: URL) async -> Bool {
        guard !closing, !busy, validWebURL(url) else { return false }
        busy = true
        defer { busy = false; updateSurface() }
        do {
            if browsing == nil { try await startPrivate() }
            else { _ = try await addTab() }
            guard let selected, browsing?.storage.adapter.perform(.load(url), in: selected) == true else { return false }
            window?.makeKeyAndOrderFront(nil)
            return true
        } catch { return false }
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
        chrome?.configuration.userContentController.removeScriptMessageHandler(forName: "browserChrome", contentWorld: .page)
        detachContent()
        for child in Array(minis.values) { child.window?.close() }
        if !busy { scheduleCleanup() }
    }

    private func scheduleCleanup() {
        Task { @MainActor in
            do { try await endPrivate() }
            catch { await discard() }
            didClose?()
        }
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
        func command(_ type: String, tab: ViewID? = nil, url: URL? = nil, offset: Int? = nil) async -> Bool {
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
                guard let selected, let web = browsing?.storage.adapter.surface(selected) else { return false }
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
                guard let web = browsing?.storage.adapter.surface(first) else { return false }
                return web.title == "Coastal Field Guide" && !web.isLoading && !page.isHidden && web.superview === page
            })
            try require("F4-NAVIGATION-UI", await eventually {
                await readChrome("return document.querySelector('.tab-wrap.current .tab')?.textContent.trim() === 'Coastal Field Guide';")
            })
            await screenshot("browsing")
            do {
                guard let firstSurface = browsing?.storage.adapter.surface(first) else { throw ChromeResult.Failure.failed }
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
                browsing?.storage.adapter.surface(fresh)?.title == "Fresh Session"
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
        func loaded(_ id: ViewID, _ title: String, on controller: MainWindowController? = nil) -> Bool {
            let source = controller ?? self
            return source.browsing?.storage.adapter.surface(id)?.title == title &&
                source.browsing?.storage.adapter.surface(id)?.isLoading == false
        }
        do {
            try require("R-SHELL", await wait { await js("return !!document.querySelector('.welcome .primary') && !document.querySelector('.welcome .primary').disabled;") })
            await capture("01-main-default")
            try require("R-PRIVATE-START", await js("document.querySelector('.welcome .primary').click(); return true;"))
            try require("R-PRIVATE-STORE", await wait {
                guard let selected, let view = browsing?.storage.adapter.surface(selected) else { return false }
                return !view.configuration.websiteDataStore.isPersistent && view.configuration.websiteDataStore.identifier == nil
            })
            await capture("07-new-tab-private")
            guard let first = selected else { throw ChromeResult.Failure.failed }
            try require("R-URL", await command("navigate", fields: ["tab": first.rawValue, "url": origin.appendingPathComponent("guide").absoluteString]))
            try require("R-RENDER", await wait { loaded(first, "Coastal Field Guide") && !page.isHidden })
            try require("R-FAVICON", await wait { browsing?.storage.adapter.favicon(in: first)?.hasPrefix("data:image/png;base64,") == true })
            try require("R-PIN", await command("pin", fields: ["tab": first.rawValue]) && organization[first]?.pinned == true)
            try require("R-NEW-TAB", await command("newTab"))
            guard let second = selected else { throw ChromeResult.Failure.failed }
            try require("R-SECOND-PAGE", await command("navigate", fields: ["tab": second.rawValue, "url": origin.appendingPathComponent("notes").absoluteString]))
            try require("R-SECOND-RENDER", await wait { loaded(second, "Trail Notes") })
            try require("R-GROUP-CREATE", await command("groupCreate", fields: ["name": "Field notes"]))
            guard let group = groups.first else { throw ChromeResult.Failure.failed }
            try require("R-GROUP-ASSIGN", await command("tabGroup", fields: ["tab": second.rawValue, "target": group.id]) && organization[second]?.group == group.id)
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
                    browsing?.storage.adapter.surface(first)?.superview === panes[0] &&
                    browsing?.storage.adapter.surface(second)?.superview === panes[1]
            })
            try require("R-SPLIT-DISTINCT-IDENTITY", browsing?.storage.adapter.surface(first) !== browsing?.storage.adapter.surface(second))
            await capture("10-split-screen")
            try require("R-SPLIT-FOCUS-SECOND", selected == second)
            await capture("11-split-second-focused")
            try require("R-SPLIT-FOCUS-FIRST", await command("activate", fields: ["tab": first.rawValue]) && selected == first && splitTabs.count == 2)
            try require("R-SPLIT-INDEPENDENT-NAVIGATION", await command("navigate", fields: ["tab": first.rawValue, "url": origin.appendingPathComponent("notes").absoluteString]))
            try require("R-SPLIT-STATE", await wait { loaded(first, "Trail Notes") && loaded(second, "Trail Notes") })
            try require("R-SPLIT-OTHER-NAVIGATION", await command("navigate", fields: ["tab": second.rawValue, "url": origin.appendingPathComponent("guide").absoluteString]))
            try require("R-SPLIT-OTHER-STATE", await wait { loaded(first, "Trail Notes") && loaded(second, "Coastal Field Guide") })
            try require("R-CONTENT-BRIDGE-ISOLATION", ((try? await browsing?.storage.adapter.surface(first)?.callAsyncJavaScript(
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
                guard let surface = browsing?.storage.adapter.surface(second) else { throw ChromeResult.Failure.failed }
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
            try require("R-MINI-SEPARATE-STORE", child.browsing?.storage.adapter.surface(miniTab)?.configuration.websiteDataStore !== browsing?.storage.adapter.surface(second)?.configuration.websiteDataStore)
            do {
                guard let surface = child.browsing?.storage.adapter.surface(miniTab) else { throw ChromeResult.Failure.failed }
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
            try require("R-MINI-TRANSFER", await command("miniTransfer", on: child))
            try require("R-MINI-TRANSFER-URL", await wait {
                guard let id = selected else { return false }
                return loaded(id, "Trail Notes") && child.browsing == nil && minis.isEmpty
            })
            do {
                guard let selected, let surface = browsing?.storage.adapter.surface(selected) else { throw ChromeResult.Failure.failed }
                let noCopy = (try? await surface.callAsyncJavaScript("return localStorage.getItem('mini-only') === null && localStorage.getItem('workspace-only') === 'synthetic';", arguments:[:],in:nil,contentWorld:.page)) as? Bool
                try require("R-MINI-TRANSFER-URL-ONLY", noCopy == true)
            }
            try require("R-MINI-CLOSE-SECOND", await command("miniOpen", fields: ["tab": first.rawValue]))
            guard let closeChild = minis.values.first else { throw ChromeResult.Failure.failed }
            try require("R-MINI-SECOND-LOADED", await wait { closeChild.selected != nil })
            closeChild.window?.close()
            try require("R-MINI-CLOSE-CLEANUP", await wait { closeChild.browsing == nil && closeChild.tabs.isEmpty && minis.isEmpty })
            do {
            guard let sourceView = browsing?.storage.adapter.surface(first) else { throw ChromeResult.Failure.failed }
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
            try require("R-UNPIN", await command("pin", fields: ["tab": first.rawValue]) && organization[first]?.pinned == false)
            try require("R-UNGROUP", await command("tabGroup", fields: ["tab": second.rawValue]) && organization[second]?.group == nil)
            try require("R-TAB-MOVE-SPACE", await command("tabSpace", fields: ["tab": second.rawValue, "target": research]) && organization[second]?.space == research)
            try require("R-SPACE-DELETE-EMPTY", await command("spaceCreate", fields: ["name":"Disposable"]))
            let disposable = activeSpace
            try require("R-SPACE-DELETED", await command("spaceDelete", fields: ["target":disposable]) && !spaces.contains(where: {$0.id == disposable}))
            _ = await command("spaceSwitch", fields: ["target":personal])
            await capture("17-private-session")
            try require("R-END", await command("endPrivate") && browsing == nil && organization.isEmpty && groups.isEmpty)
            _ = await command("appearance", fields: ["value":"system"])
            Self.emit("qualification", status:"PASS_NATIVE")
        } catch { Self.emit("qualification", status:"FAIL") }
    }
}
#endif
