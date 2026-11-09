import AppKit
import OSLog
import BrowserNativeStorage

@MainActor
final class ApplicationDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "internal.vezham.browser.foundation", category: "lifecycle")
    private var mainWindow: MainWindowController?
    private var storageSession: NativeStorageSession?

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if WSF1_QUALIFICATION
        if ProcessInfo.processInfo.arguments.contains("--wsf1-qualification") {
            Task { @MainActor in
                await StorageQualificationHost.run()
                NSApp.terminate(nil)
            }
            return
        }
        #endif
        // Composition only: durable catalog/keys are not ready. No implicit persistent store.
        storageSession = try? NativeStorageSession.privateOnly()
        configureMenu()
        showMainWindow()
        logger.info("native-host-ready")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showMainWindow() }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        #if WSF1_QUALIFICATION
        if ProcessInfo.processInfo.arguments.contains("--wsf1-qualification") { return false }
        #endif
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("native-host-terminating")
        mainWindow = nil
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
