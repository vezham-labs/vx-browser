import AppKit
import OSLog

@MainActor
final class ApplicationDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "internal.vezham.browser.foundation", category: "lifecycle")
    private var mainWindow: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenu()
        showMainWindow()
        logger.info("native-host-ready")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showMainWindow() }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

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
