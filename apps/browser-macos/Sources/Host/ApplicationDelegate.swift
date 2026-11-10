import AppKit
import OSLog
import BrowserNativeStorage

@MainActor
final class ApplicationDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    private let logger = Logger(subsystem: "internal.vezham.browser.foundation", category: "lifecycle")
    private var mainWindow: MainWindowController?
    private var storageSession: NativeStorageSession?
    private var securityLifecycle: NativeSecurityLifecycle?
    private var terminating = false
    private var routingReady = false
    private var routing = false
    private var pendingRoutes: [ExternalBrowserRoute] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if WSF1_QUALIFICATION
        if ProcessInfo.processInfo.arguments.contains("--wsf2-qualification") {
            Task { @MainActor in await SecurityQualificationHost.run();NSApp.terminate(nil) }
            return
        }
        if ProcessInfo.processInfo.arguments.contains("--wsf1-qualification") {
            Task { @MainActor in
                await StorageQualificationHost.run()
                NSApp.terminate(nil)
            }
            return
        }
        #endif
        // Composition only: durable catalog/keys are not ready. No implicit persistent store.
        do {
            storageSession = try NativeStorageSession.protectedFoundation()
        } catch {
            logger.error("protected-foundation-unavailable")
        }
        applyGlobalAppearance()
        if let storageSession { securityLifecycle = NativeSecurityLifecycle(session: storageSession) }
        configureMenu()
        showMainWindow()
        mainWindow?.showWelcomeIfNeeded()
        routingReady = true
        drainRoutes()
        logger.info("native-host-ready")
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if Bundle.main.bundleIdentifier == "internal.vezham.browser.wsf5.qualification", arguments.contains("--wsf5-observe") {
            Task { @MainActor in
                for _ in 0..<1800 {
                    if let current = self.mainWindow {
                        let dom = await current.reliabilityDOMObservation()
                        let event: [String: Any] = ["observation": current.reliabilityObservation(), "chromeDiagnostic": dom, "uptime": ProcessInfo.processInfo.systemUptime]
                        if let data = try? JSONSerialization.data(withJSONObject: event, options: [.sortedKeys]) {
                            FileHandle.standardOutput.write(data + Data([10]))
                        }
                    }
                    try? await Task.sleep(for: .seconds(1))
                }
            }
        }
        if Bundle.main.bundleIdentifier == "internal.vezham.browser.wsf5.qualification",
           let flag = arguments.firstIndex(of: "--wsf5-qualification"),
           arguments.indices.contains(flag + 1), let origin = URL(string: arguments[flag + 1]),
           origin.scheme == "http", origin.host == "127.0.0.1", let mainWindow {
            Task { @MainActor in
                await mainWindow.qualifyReliability(origin)
                NSApp.terminate(nil)
            }
        }
        if ["internal.vezham.browser.wsf5.qualification", "internal.vezham.browser.wsf6.qualification"]
            .contains(Bundle.main.bundleIdentifier ?? ""),
           let flag = arguments.firstIndex(of: "--wsf5r-qualification"),
           arguments.indices.contains(flag + 1), let origin = URL(string: arguments[flag + 1]),
           origin.scheme == "http", origin.host == "127.0.0.1", origin.port != nil,
           origin.user == nil, origin.password == nil, origin.query == nil, origin.fragment == nil,
           origin.path.isEmpty, let mainWindow {
            Task { @MainActor in
                await mainWindow.qualifyPrivateRecovery(origin)
                NSApp.terminate(nil)
            }
        }
        if Bundle.main.bundleIdentifier == "internal.vezham.browser.wsf6.qualification",
           let flag = arguments.firstIndex(of: "--wsf6-qualification"),
           arguments.indices.contains(flag + 1), let origin = URL(string: arguments[flag + 1]),
           origin.scheme == "http", origin.host == "127.0.0.1", origin.port != nil,
           origin.user == nil, origin.password == nil, origin.query == nil, origin.fragment == nil,
           origin.path.isEmpty, let mainWindow {
            Task { @MainActor in
                await mainWindow.qualifyWorkspace(origin)
                NSApp.terminate(nil)
            }
        }
        if Bundle.main.bundleIdentifier == "internal.vezham.browser.wsf4.qualification",
           let flag = arguments.firstIndex(of: "--wsf4-qualification"),
           arguments.indices.contains(flag + 1), let origin = URL(string: arguments[flag + 1]),
           let mainWindow {
            Task { @MainActor in
                if arguments.contains("--wsf4r-qualification") { await mainWindow.qualifyRefinement(origin) }
                else { await mainWindow.qualifyLoopback(origin) }
            }
        }
        #endif
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard !terminating else { return }
        for input in urls.prefix(6) {
            guard pendingRoutes.count < 12, let route = ExternalBrowserRoute.parse(input) else {
                logger.notice("external-url-rejected")
                continue
            }
            pendingRoutes.append(route)
        }
        drainRoutes()
    }

    private func drainRoutes() {
        guard routingReady, !routing, !pendingRoutes.isEmpty else { return }
        routing = true
        Task { @MainActor in
            defer { routing = false }
            while !pendingRoutes.isEmpty && !terminating {
                showMainWindow()
                guard let mainWindow else { break }
                var waits = 0
                while mainWindow.isPerformingBrowserAction && !terminating && waits < 400 {
                    waits += 1
                    try? await Task.sleep(for: .milliseconds(50))
                }
                guard !terminating else { break }
                let route = pendingRoutes.removeFirst()
                guard !mainWindow.isPerformingBrowserAction else {
                    logger.notice("external-url-admission-timeout")
                    continue
                }
                do {
                    switch route {
                    case .workspace(let url): try await mainWindow.openExternal(url)
                    case .mini(let url): try await mainWindow.openMini(url)
                    }
                } catch { logger.notice("external-url-unavailable") }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !terminating else { return false }
        if !flag { showMainWindow() }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        #if WSF1_QUALIFICATION
        if ProcessInfo.processInfo.arguments.contains(where: { ["--wsf1-qualification", "--wsf2-qualification", "--wsf4-qualification", "--wsf6-qualification", "--wsf5r-qualification"].contains($0) }) { return false }
        #endif
        return true
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        #if DEBUG
        // The isolated suites await shutdown and record its postconditions before
        // requesting termination. Avoid a second asynchronous teardown with no window.
        let arguments = ProcessInfo.processInfo.arguments
        if Bundle.main.bundleIdentifier == "internal.vezham.browser.wsf6.qualification",
           arguments.contains("--wsf6-qualification") || arguments.contains("--wsf5r-qualification") {
            return .terminateNow
        }
        #endif
        #if WSF1_QUALIFICATION
        if ProcessInfo.processInfo.arguments.contains(where: { ["--wsf1-qualification", "--wsf2-qualification", "--wsf4-qualification"].contains($0) }) { return .terminateNow }
        #endif
        terminating = true
        routingReady = false
        pendingRoutes.removeAll()
        let closingWindow = mainWindow
        Task { @MainActor in
            await closingWindow?.shutdown()
            if let storageSession { await storageSession.security.lockAll(cause: .shutdown) }
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("native-host-terminating")
        mainWindow = nil
        securityLifecycle?.stop();securityLifecycle = nil
    }

    private func applyGlobalAppearance() {
        do {
            let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                       appropriateFor: nil, create: false)
            let settings = GlobalAppearanceSettings(applicationSupport: support.appendingPathComponent("VezhamBrowser"))
            switch try settings.read() {
            case .system: NSApp.appearance = nil
            case .light: NSApp.appearance = NSAppearance(named: .aqua)
            case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
            }
        } catch {
            logger.error("global-appearance-unavailable")
        }
    }

    private func showMainWindow() {
        guard !terminating else { return }
        if mainWindow?.acceptsExternalNavigation != true {
            let controller = MainWindowController()
            controller.didClose = { [weak self, weak controller] in
                if self?.mainWindow === controller { self?.mainWindow = nil }
            }
            mainWindow = controller
        }
        mainWindow?.showWindow(nil)
        mainWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var menuController: MainWindowController? {
        NSApp.keyWindow?.windowController as? MainWindowController
    }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        guard let action = NativeBrowserMenuAction(rawValue: item.tag) else { return false }
        return menuController?.allowsMenuAction(action) == true
    }

    @objc private func browserMenuCommand(_ sender: NSMenuItem) {
        if let action = NativeBrowserMenuAction(rawValue: sender.tag) {
            menuController?.performMenuAction(action)
        }
    }

    private func configureMenu() {
        let menu = NSMenu()
        func browserItem(_ title: String, _ action: NativeBrowserMenuAction, key: String = "") -> NSMenuItem {
            let item = NSMenuItem(title: title, action: #selector(browserMenuCommand(_:)), keyEquivalent: key)
            item.target = self
            item.tag = action.rawValue
            return item
        }
        func submenu(_ name: String, _ entries: [NSMenuItem]) -> NSMenu {
            let item = NSMenuItem()
            let group = NSMenu(title: name)
            for entry in entries { group.addItem(entry) }
            item.submenu = group
            menu.addItem(item)
            return group
        }
        let applicationItem = NSMenuItem()
        let applicationMenu = NSMenu(title: "Vezham Browser")
        applicationMenu.addItem(browserItem("Settings…", .settings, key: ","))
        applicationMenu.addItem(.separator())
        applicationMenu.addItem(withTitle: "Quit Vezham Browser", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        applicationItem.submenu = applicationMenu
        menu.addItem(applicationItem)
        _ = submenu("File", [
            browserItem("New Tab…", .commandBar, key: "t"),
            browserItem("New Blank Tab", .newTab),
            browserItem("Open Current Page in Mini", .openMini)
        ])
        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        menu.addItem(editItem)
        _ = submenu("View", [
            browserItem("Toggle Sidebar", .sidebar),
            browserItem("Focus Address", .focusAddress, key: "l"),
            browserItem("Command Bar…", .commandBar, key: "k")
        ])
        _ = submenu("Navigation", [
            browserItem("Back", .back, key: "["),
            browserItem("Forward", .forward, key: "]"),
            browserItem("Reload", .reload, key: "r"),
            browserItem("Stop", .stop),
            browserItem("Copy Address", .copyAddress)
        ])
        _ = submenu("Bookmarks", [browserItem("Temporary Bookmarks…", .bookmarks)])
        let windows = submenu("Window", [
            NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"),
            NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "")
        ])
        _ = submenu("Help", [browserItem("Welcome to Vezham", .welcome)])
        NSApp.mainMenu = menu
        NSApp.windowsMenu = windows
    }
}
