import AppKit
import BrowserDomain

/// Public AppKit lifecycle signals. Screen-lock signal remains unqualified separately;
/// no undocumented distributed notification is treated as a guaranteed lock primitive.
@MainActor public final class NativeSecurityLifecycle: NSObject {
    private let session: NativeStorageSession
    private var timer: Timer?
    private var activityMonitor: Any?
    private let inactivity: TimeInterval
    private var lastActivity = Date()
    public init(session: NativeStorageSession, inactivity: TimeInterval = 900) {
        self.session = session; self.inactivity = max(30, inactivity)
        super.init()
        let c = NSWorkspace.shared.notificationCenter
        c.addObserver(self, selector: #selector(sleeping), name: NSWorkspace.willSleepNotification, object: nil)
        c.addObserver(self, selector: #selector(resigned), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopping), name: NSApplication.willTerminateNotification, object: nil)
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in Task { @MainActor in self?.tick() } }
        activityMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown,.leftMouseDown,.rightMouseDown,.scrollWheel]) { [weak self] event in self?.activity(); return event }
    }
    public func activity() { lastActivity = Date() }
    private func tick() { if Date().timeIntervalSince(lastActivity) >= inactivity { request(.inactivity) } }
    private func request(_ cause: LockCause) { Task { await session.security.lockAll(cause: cause) } }
    @objc private func sleeping() { request(.sleep) }
    @objc private func resigned() { request(.sessionResigned) }
    @objc private func stopping() { request(.shutdown) }
    public func stop() { timer?.invalidate();timer = nil;if let activityMonitor { NSEvent.removeMonitor(activityMonitor) };activityMonitor = nil;NSWorkspace.shared.notificationCenter.removeObserver(self);NotificationCenter.default.removeObserver(self) }
}
