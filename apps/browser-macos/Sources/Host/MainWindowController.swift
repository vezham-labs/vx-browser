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
final class MainWindowController: NSWindowController, WKNavigationDelegate, NSWindowDelegate, WKScriptMessageHandlerWithReply {
    private struct PrivateSession {
        let id: PrivateSessionID
        let storage: NativeStorageSession
        let scope: Scope
        let context: CallerContext
    }

    private let root = NSView()
    private var chrome: WKWebView?
    private let page = NSView()
    private var chromeURL: URL?
    private var browsing: PrivateSession?
    private var tabs: [ViewID] = []
    private var selected: ViewID?
    private var busy = false
    private var closing = false
    private var lastState: ChromeState?
    private var presentation = (visible: false, left: 0.0, top: 86.0)
    private var appearance = ChromeAppearance.system

    init() {
        let window = BrowserWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1080, height: 712),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = "Vezham Browser"
        window.minSize = NSSize(width: 660, height: 470)
        window.center()
        super.init(window: window)
        window.delegate = self
        configureContent(window)
        window.shortcut = { [weak self] key in
            guard let self, ["l", "t", "w", "r", "k", ",", "[", "]"].contains(key),
                  let chrome = self.chrome, chrome.url == self.chromeURL,
                  key != "w" || !self.tabs.isEmpty else { return false }
            self.window?.makeFirstResponder(chrome)
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
                                   tabs: items, selected: active, appearance: appearance)
        let state = observed == lastState ? observed : ChromeState(revision: revision + 1,
            session: session, sessionID: sessionID, tabs: items, selected: active, appearance: appearance)
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
                         back: web?.canGoBack ?? false, forward: web?.canGoForward ?? false, connection: connection, failure: failure)
    }

    private func run(_ command: ChromeCommand) async -> ChromeResult {
        if command.type == .snapshot { return result(command) }
        if command.type == .presentation {
            guard let left = command.left, let top = command.top, let visible = command.visible,
                  left.isFinite, top.isFinite, (0...310).contains(left), (72...128).contains(top) else {
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
        selected = id
        return id
    }

    private func endPrivate() async throws {
        while let id = tabs.last { try await closeTab(id) }
        if browsing != nil { await discard() }
    }

    private func closeTab(_ id: ViewID) async throws {
        guard let browsing, let index = tabs.firstIndex(of: id) else { throw ChromeResult.Failure.unavailable }
        if selected == id { page.subviews.forEach { $0.removeFromSuperview() } }
        let closed = await browsing.storage.core.closeView(browsing.scope, view: id, context: browsing.context, operation: try operation())
        guard case .success(.viewClosed) = closed else {
            await discard()
            throw ChromeResult.Failure.failed
        }
        tabs.remove(at: index)
        if selected == id { selected = tabs.isEmpty ? nil : tabs[min(index, tabs.count - 1)] }
        if tabs.isEmpty { await discard() }
    }

    private func discard() async {
        page.subviews.forEach { $0.removeFromSuperview() }
        if let browsing {
            await browsing.storage.adapter.preventAcquisition(in: browsing.scope)
            await browsing.storage.authority.revoke(browsing.scope)
        }
        browsing = nil
        tabs = []
        selected = nil
    }

    private func tabCommand(_ command: ChromeCommand, id: ViewID, browsing: PrivateSession) async throws -> String? {
        let adapter = browsing.storage.adapter
        let navigation: NativeWebKitStorage.InteractiveNavigation
        switch command.type {
        case .activate: selected = id; return nil
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

    private func updateSurface() {
        let bounds = root.bounds
        let left = CGFloat(presentation.left), top = CGFloat(presentation.top)
        page.frame = NSRect(x: left, y: 29, width: max(0, bounds.width - left), height: max(0, bounds.height - top - 29))
        guard presentation.visible, let selected, let web = browsing?.storage.adapter.surface(selected) else {
            page.isHidden = true
            return
        }
        if web.superview !== page {
            page.subviews.forEach { $0.removeFromSuperview() }
            web.frame = page.bounds
            web.autoresizingMask = [.width, .height]
            page.addSubview(web)
        }
        page.isHidden = false
    }

    func windowDidResize(_ notification: Notification) { updateSurface() }

    func windowWillClose(_ notification: Notification) {
        closing = true
        chrome?.configuration.userContentController.removeScriptMessageHandler(forName: "browserChrome", contentWorld: .page)
        page.subviews.forEach { $0.removeFromSuperview() }
        if !busy { scheduleCleanup() }
    }

    private func scheduleCleanup() {
        Task { @MainActor in
            do { try await endPrivate() }
            catch { await discard() }
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
