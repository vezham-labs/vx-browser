import AppKit

@main
@MainActor
struct VezhamBrowserMain {
    static func main() {
        let application = NSApplication.shared
        let delegate = ApplicationDelegate()
        application.setActivationPolicy(.regular)
        application.delegate = delegate
        application.run()
        withExtendedLifetime(delegate) {}
    }
}
