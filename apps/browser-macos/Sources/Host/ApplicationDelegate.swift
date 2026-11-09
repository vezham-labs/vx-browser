import AppKit
import OSLog
import BrowserNativeStorage

@MainActor
final class ApplicationDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "internal.vezham.browser.foundation", category: "lifecycle")
    private var mainWindow: MainWindowController?
    private var storageSession: NativeStorageSession?
    private var securityLifecycle: NativeSecurityLifecycle?

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
        logger.info("native-host-ready")
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
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
        showMainWindow()
        for wrapper in urls.prefix(6) {
            guard wrapper.scheme == "vezham", wrapper.host == "open",
                  let parts = URLComponents(url: wrapper, resolvingAgainstBaseURL: false),
                  parts.queryItems?.count == 1,
                  let query = parts.queryItems?.first, query.name == "url",
                  let value = query.value, value.utf8.count <= 8192, let url = URL(string: value),
                  let mainWindow else { continue }
            Task { @MainActor in
                do { try await mainWindow.openMini(url) }
                catch { NSSound.beep() }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showMainWindow() }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        #if WSF1_QUALIFICATION
        if ProcessInfo.processInfo.arguments.contains(where: { ["--wsf1-qualification", "--wsf2-qualification", "--wsf4-qualification"].contains($0) }) { return false }
        #endif
        return true
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        #if WSF1_QUALIFICATION
        if ProcessInfo.processInfo.arguments.contains(where: { ["--wsf1-qualification", "--wsf2-qualification", "--wsf4-qualification"].contains($0) }) { return .terminateNow }
        #endif
        guard let storageSession else { return .terminateNow }
        Task { @MainActor in
            await storageSession.security.lockAll(cause: .shutdown)
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
        if mainWindow == nil { mainWindow = MainWindowController() }
        mainWindow?.showWindow(nil)
        mainWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureMenu() {
        let menu = NSMenu()
        let applicationItem = NSMenuItem()
        let applicationMenu = NSMenu(title: "Vezham Browser")
        applicationMenu.addItem(withTitle: "Quit Vezham Browser", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        applicationItem.submenu = applicationMenu
        menu.addItem(applicationItem)
        NSApp.mainMenu = menu
    }
}
