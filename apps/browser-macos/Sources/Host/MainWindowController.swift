import AppKit

@MainActor
final class MainWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Vezham Browser"
        window.minSize = NSSize(width: 640, height: 420)
        window.center()
        super.init(window: window)
        configureContent(window)
    }

    required init?(coder: NSCoder) { fatalError("Storyboard initialization is not supported") }

    private func configureContent(_ window: NSWindow) {
        let title = NSTextField(labelWithString: "Vezham Browser")
        title.font = .systemFont(ofSize: 28, weight: .semibold)
        let status = NSTextField(labelWithString: "Protected profile storage unavailable")
        status.textColor = .secondaryLabelColor
        status.setAccessibilityIdentifier("browser-host-status")

        let stack = NSStackView(views: [title, status])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -24)
        ])
        window.contentView = content
    }
}
