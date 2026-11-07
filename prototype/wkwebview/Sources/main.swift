import AppKit
import AVFoundation
import WebKit
import OSLog

private let logger = Logger(subsystem: "internal.vezham.WKPrototype", category: "browser")
private let fixtureBase = URL(string: "http://127.0.0.1:18765/fixture")!

private struct ProfileKey: Hashable {
    let rawValue: UUID
}

private enum ProfileChoice {
    case persistent(ProfileKey, String)
    case privateSession(PrivateSession)

    var title: String {
        switch self {
        case .persistent(_, let name): name
        case .privateSession(let session): "Private • \(session.id.uuidString.prefix(8))"
        }
    }

    var store: WKWebsiteDataStore {
        switch self {
        case .persistent(let key, _): ProfileRegistry.shared.persistentStore(for: key)
        case .privateSession(let session): session.store
        }
    }
}

private final class PrivateSession {
    let id = UUID()
    let store = WKWebsiteDataStore.nonPersistent()
    var viewCount = 0
}

private final class ProfileRegistry {
    static let shared = ProfileRegistry()
    let profileA = ProfileKey(rawValue: UUID(uuidString: "A12A0000-0000-4000-8000-000000000001")!)
    let profileB = ProfileKey(rawValue: UUID(uuidString: "B12B0000-0000-4000-8000-000000000002")!)
    private var stores: [ProfileKey: WKWebsiteDataStore] = [:]
    private var activePrivateSession: PrivateSession?

    func persistentStore(for key: ProfileKey) -> WKWebsiteDataStore {
        if let store = stores[key] { return store }
        let store = WKWebsiteDataStore(forIdentifier: key.rawValue)
        stores[key] = store
        return store
    }

    func profileAChoice() -> ProfileChoice { .persistent(profileA, "Profile A") }
    func profileBChoice() -> ProfileChoice { .persistent(profileB, "Profile B") }

    func acquirePrivateSession() -> ProfileChoice {
        let session = activePrivateSession ?? PrivateSession()
        activePrivateSession = session
        return .privateSession(session)
    }

    func retain(_ choice: ProfileChoice) {
        if case .privateSession(let session) = choice {
            session.viewCount += 1
        }
    }

    func release(_ choice: ProfileChoice) {
        guard case .privateSession(let session) = choice else { return }
        session.viewCount = max(0, session.viewCount - 1)
        if session.viewCount == 0, activePrivateSession === session {
            activePrivateSession = nil
        }
    }
}

private enum BrowserCommand {
    case navigate(URL)
    case back
    case forward
    case reload
    case stop
    case zoom(Double)
}

private struct CommandEnvelope {
    let version: UInt8
    let requestID: UUID
    let command: BrowserCommand
}

private enum RedactedLog {
    static func host(_ url: URL?) -> String {
        guard let url else { return "none" }
        return url.host ?? "hostless"
    }

    static func navigation(_ event: String, url: URL?) {
        logger.info("\(event, privacy: .public) host=\(host(url), privacy: .public)")
    }
}

private enum TransferSupport {
    static func responseShouldDownload(_ navigationResponse: WKNavigationResponse) -> Bool {
        let disposition = (navigationResponse.response as? HTTPURLResponse)?
            .value(forHTTPHeaderField: "Content-Disposition")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return disposition?.lowercased().hasPrefix("attachment") == true || !navigationResponse.canShowMIMEType
    }

    static func safeSuggestedFilename(_ suggestedFilename: String) -> String {
        let name = URL(fileURLWithPath: suggestedFilename).lastPathComponent
        return name.isEmpty || name == "." || name == ".." ? "download" : name
    }
}

private enum OriginLabel {
    static func from(_ origin: WKSecurityOrigin) -> String {
        var components = URLComponents()
        components.scheme = origin.protocol
        components.host = origin.host
        components.port = origin.port
        return components.string ?? "unknown origin"
    }

    static func from(_ url: URL?) -> String {
        guard let url else { return "unknown origin" }
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.port = url.port
        return components.string ?? "unknown origin"
    }
}

private final class PrototypeApplication: NSObject, NSApplicationDelegate {
    private var windows: [BrowserWindowController] = []
    private var harness: IsolationHarness?
    private var findZoomHarness: FindZoomHarness?
    private var downloadHarness: DownloadHarness?
    private var crashRecoveryHarness: CrashRecoveryHarness?
    private var recoveryUIHarness: RecoveryUIHarness?
    private var phase3MeasurementHarness: NSObject?
    private var permissionStatusTimer: Timer?
    private var lastPermissionStatus: String?
    private var isRunningWindowLifecycleHarness = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        FileHandle.standardError.write(Data("prototype didFinishLaunching\n".utf8))
        let arguments = Set(CommandLine.arguments.dropFirst())
        if arguments.contains("--test-performance-sample") || arguments.contains("--test-ten-idle-views") || arguments.contains("--test-public-sites") {
            let index = CommandLine.arguments.firstIndex(of: "--test-run-id")
            let runID = index.flatMap { CommandLine.arguments.indices.contains($0 + 1) ? CommandLine.arguments[$0 + 1] : nil } ?? UUID().uuidString
            let done: () -> Void = { [weak self] in self?.phase3MeasurementHarness = nil; NSApp.terminate(nil) }
            if arguments.contains("--test-public-sites") {
                let harness = Phase3PublicSites(runID: runID, completion: done)
                phase3MeasurementHarness = harness; harness.start()
            } else if arguments.contains("--test-ten-idle-views") {
                let harness = Phase3IdleViews(runID: runID, completion: done)
                phase3MeasurementHarness = harness; harness.start()
            } else {
                let harness = Phase3PerformanceSample(runID: runID, completion: done)
                phase3MeasurementHarness = harness; harness.start()
            }
            return
        }
        if arguments.contains("--test-phase3-local") {
            installMenu()
            DispatchQueue.main.asyncAfter(deadline: .now() + 600) { NSApp.terminate(nil) }
            openWindow(profile: ProfileRegistry.shared.acquirePrivateSession(), initialURL: URL(string: "http://127.0.0.1:18765/phase3")!)
            return
        }
        if arguments.contains("--test-local-interactions") {
            installMenu()
            DispatchQueue.main.asyncAfter(deadline: .now() + 300) { NSApp.terminate(nil) }
            openWindow(profile: ProfileRegistry.shared.acquirePrivateSession(), initialURL: URL(string: "http://127.0.0.1:18765/interaction-fixture")!)
            return
        }
        if arguments.contains("--test-recovery-ui") {
            let index = CommandLine.arguments.firstIndex(of: "--test-run-id")
            let runID = index.flatMap { CommandLine.arguments.indices.contains($0 + 1) ? CommandLine.arguments[$0 + 1] : nil } ?? UUID().uuidString
            installMenu()
            recoveryUIHarness = RecoveryUIHarness(runID: runID) { [weak self] in self?.recoveryUIHarness = nil; NSApp.terminate(nil) }
            recoveryUIHarness?.start()
            return
        }
        if arguments.contains("--test-crash-recovery") {
            let runIDIndex = CommandLine.arguments.firstIndex(of: "--test-run-id")
            let runID = runIDIndex.flatMap { index in
                CommandLine.arguments.indices.contains(index + 1) ? CommandLine.arguments[index + 1] : nil
            } ?? UUID().uuidString
            crashRecoveryHarness = CrashRecoveryHarness(runID: runID) { [weak self] result in
                self?.crashRecoveryHarness = nil
                if let result { logger.info("crash recovery harness completed status=\(result, privacy: .public)") }
                NSApp.terminate(nil)
            }
            crashRecoveryHarness?.start()
            return
        }
        if arguments.contains("--test-download") {
            let runIDIndex = CommandLine.arguments.firstIndex(of: "--test-run-id")
            let runID = runIDIndex.flatMap { index in
                CommandLine.arguments.indices.contains(index + 1) ? CommandLine.arguments[index + 1] : nil
            } ?? UUID().uuidString
            downloadHarness = DownloadHarness(runID: runID) { [weak self] result in
                self?.downloadHarness = nil
                if let result { logger.info("download harness completed status=\(result, privacy: .public)") }
                NSApp.terminate(nil)
            }
            downloadHarness?.start()
            return
        }
        if arguments.contains("--test-upload") {
            installMenu()
            let timeoutIndex = CommandLine.arguments.firstIndex(of: "--test-upload-timeout-seconds")
            let timeout = timeoutIndex.flatMap { index in
                CommandLine.arguments.indices.contains(index + 1) ? Double(CommandLine.arguments[index + 1]) : nil
            } ?? 210
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                FileHandle.standardError.write(Data("upload test safety timeout reached; closing isolated app\n".utf8))
                NSApp.terminate(nil)
            }
            let url = URL(string: "http://127.0.0.1:18765/upload-fixture")!
            openWindow(profile: ProfileRegistry.shared.acquirePrivateSession(), initialURL: url)
            return
        }
        if arguments.contains("--test-download-panel") {
            installMenu()
            let timeoutIndex = CommandLine.arguments.firstIndex(of: "--test-download-panel-timeout-seconds")
            let timeout = timeoutIndex.flatMap { index in
                CommandLine.arguments.indices.contains(index + 1) ? Double(CommandLine.arguments[index + 1]) : nil
            } ?? 210
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                FileHandle.standardError.write(Data("download panel test safety timeout reached; closing isolated app\n".utf8))
                NSApp.terminate(nil)
            }
            let url = URL(string: "http://127.0.0.1:18765/transfer-download")!
            openWindow(profile: ProfileRegistry.shared.acquirePrivateSession(), initialURL: url)
            return
        }
        if arguments.contains("--test-permission-deny") {
            installMenu()
            recordOSPermissionStatus()
            permissionStatusTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.recordOSPermissionStatus()
            }
            let timeoutIndex = CommandLine.arguments.firstIndex(of: "--test-permission-timeout-seconds")
            let timeout = timeoutIndex.flatMap { index in
                CommandLine.arguments.indices.contains(index + 1) ? Double(CommandLine.arguments[index + 1]) : nil
            } ?? 210
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                FileHandle.standardError.write(Data("permission test safety timeout reached; closing isolated app\n".utf8))
                NSApp.terminate(nil)
            }
            let url = URL(string: "http://localhost:18765/permission-fixture")!
            openWindow(profile: ProfileRegistry.shared.acquirePrivateSession(), initialURL: url)
            return
        }
        if arguments.contains("--test-find-zoom") {
            let runIDIndex = CommandLine.arguments.firstIndex(of: "--test-run-id")
            let runID = runIDIndex.flatMap { index in
                CommandLine.arguments.indices.contains(index + 1) ? CommandLine.arguments[index + 1] : nil
            } ?? UUID().uuidString
            findZoomHarness = FindZoomHarness(runID: runID) { [weak self] result in
                self?.findZoomHarness = nil
                if let result { logger.info("find/zoom harness completed status=\(result, privacy: .public)") }
                NSApp.terminate(nil)
            }
            findZoomHarness?.start()
            return
        }
        if arguments.contains("--test-private-windows") {
            let runIDIndex = CommandLine.arguments.firstIndex(of: "--test-run-id")
            let runID = runIDIndex.flatMap { index in
                CommandLine.arguments.indices.contains(index + 1) ? CommandLine.arguments[index + 1] : nil
            } ?? UUID().uuidString
            runPrivateWindowLifecycleTest(runID: runID)
            return
        }
        if arguments.contains("--test-seed") || arguments.contains("--test-verify") {
            let mode: IsolationHarness.Mode = arguments.contains("--test-seed") ? .seed : .verify
            let runIDIndex = CommandLine.arguments.firstIndex(of: "--test-run-id")
            let runID = runIDIndex.flatMap { index in
                CommandLine.arguments.indices.contains(index + 1) ? CommandLine.arguments[index + 1] : nil
            } ?? UUID().uuidString
            harness = IsolationHarness(mode: mode, runID: runID) { [weak self] result in
                self?.harness = nil
                if let result { logger.info("isolation harness completed status=\(result, privacy: .public)") }
                NSApp.terminate(nil)
            }
            FileHandle.standardError.write(Data("starting local isolation harness\n".utf8))
            harness?.start()
            return
        }
        installMenu()
        openWindow(profile: ProfileRegistry.shared.profileAChoice(), initialURL: nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { !isRunningWindowLifecycleHarness }

    func applicationWillTerminate(_ notification: Notification) {
        permissionStatusTimer?.invalidate()
        windows.forEach { $0.cancelDownloadsForShutdown() }
    }

    func openWindow(profile: ProfileChoice, initialURL: URL?) {
        if case .privateSession = profile { ProfileRegistry.shared.retain(profile) }
        let controller = BrowserWindowController(profile: profile, initialURL: initialURL) { [weak self] closed in
            self?.windows.removeAll { $0 === closed }
        } openWindow: { [weak self] profile, url in
            self?.openWindow(profile: profile, initialURL: url)
        }
        windows.append(controller)
        if !isRunningWindowLifecycleHarness {
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func runPrivateWindowLifecycleTest(runID: String) {
        isRunningWindowLifecycleHarness = true
        let registry = ProfileRegistry.shared
        openWindow(profile: registry.acquirePrivateSession(), initialURL: nil)
        openWindow(profile: registry.acquirePrivateSession(), initialURL: nil)
        guard windows.count == 2 else {
            writeWindowLifecycleResult(runID: runID, tests: [["label": "create two private windows", "passed": false]])
            return
        }
        let first = windows[0]
        let second = windows[1]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            let sharedStore = first.profileStore === second.profileStore
            first.close()
            let retainedAfterFirstClose = registry.acquirePrivateSession().store === second.profileStore
            second.close()
            let replacedAfterLastClose = registry.acquirePrivateSession().store !== second.profileStore
            let tests: [[String: Any]] = [
                ["label": "private windows initially share the manager store", "passed": sharedStore],
                ["label": "closing one window retains the shared session", "passed": retainedAfterFirstClose],
                ["label": "closing the last window replaces the private session", "passed": replacedAfterLastClose],
            ]
            self.writeWindowLifecycleResult(runID: runID, tests: tests)
        }
    }

    private func writeWindowLifecycleResult(runID: String, tests: [[String: Any]]) {
        let failures = tests.compactMap { $0["passed"] as? Bool == true ? nil : $0["label"] as? String }
        let result: [String: Any] = ["mode": "private-windows", "status": failures.isEmpty ? "passed" : "failed", "tests": tests, "failureCount": failures.count, "failures": failures]
        do {
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("WKPrototype", isDirectory: true)
            try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            let resultURL = supportDirectory.appendingPathComponent("window-lifecycle-results-\(runID).json")
            try data.write(to: resultURL, options: .atomic)
            FileHandle.standardError.write(Data("window lifecycle results: \(resultURL.path)\n".utf8))
        } catch {
            FileHandle.standardError.write(Data("window lifecycle results write failed\n".utf8))
        }
        NSApp.terminate(nil)
    }

    private func installMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Vezham WK Prototype", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let windowItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(NSMenuItem(title: "New Profile A Window", action: #selector(newProfileA), keyEquivalent: "1"))
        windowMenu.addItem(NSMenuItem(title: "New Profile B Window", action: #selector(newProfileB), keyEquivalent: "2"))
        windowMenu.addItem(NSMenuItem(title: "New Private Window", action: #selector(newPrivate), keyEquivalent: "n"))
        windowMenu.items.forEach { $0.target = self }
        windowItem.submenu = windowMenu
        main.addItem(windowItem)
        NSApp.mainMenu = main
    }

    private func recordOSPermissionStatus() {
        func label(_ status: AVAuthorizationStatus) -> String {
            switch status {
            case .notDetermined: return "notDetermined"
            case .restricted: return "restricted"
            case .denied: return "denied"
            case .authorized: return "authorized"
            @unknown default: return "unknown"
            }
        }
        let status = "OS media status: camera=\(label(AVCaptureDevice.authorizationStatus(for: .video))); microphone=\(label(AVCaptureDevice.authorizationStatus(for: .audio)))"
        guard lastPermissionStatus != status else { return }
        lastPermissionStatus = status
        recordPermissionTestEvent(status)
    }

    func recordPermissionTestEvent(_ event: String) {
        guard CommandLine.arguments.contains("--test-permission-deny"),
              let runIDIndex = CommandLine.arguments.firstIndex(of: "--test-permission-run-id"),
              CommandLine.arguments.indices.contains(runIDIndex + 1) else { return }
        let runID = CommandLine.arguments[runIDIndex + 1]
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WKPrototype", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            let resultURL = supportDirectory.appendingPathComponent("permission-ui-events-\(runID).log")
            let prior = (try? String(contentsOf: resultURL, encoding: .utf8)) ?? ""
            try (prior + event + "\n").write(to: resultURL, atomically: true, encoding: .utf8)
        } catch {
            FileHandle.standardError.write(Data("permission test event write failed\n".utf8))
        }
    }

    @objc private func newProfileA() { openWindow(profile: ProfileRegistry.shared.profileAChoice(), initialURL: nil) }
    @objc private func newProfileB() { openWindow(profile: ProfileRegistry.shared.profileBChoice(), initialURL: nil) }
    @objc private func newPrivate() { openWindow(profile: ProfileRegistry.shared.acquirePrivateSession(), initialURL: nil) }
}

private final class BrowserWindowController: NSWindowController, NSWindowDelegate, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate, NSTextFieldDelegate {
    private let profile: ProfileChoice
    private let onClose: (BrowserWindowController) -> Void
    private let openWindow: (ProfileChoice, URL) -> Void
    private var webView: WKWebView!
    private let addressField = NSTextField()
    private let statusField = NSTextField(labelWithString: "Ready")
    private let progress = NSProgressIndicator()
    private let findField = NSSearchField()
    private var progressObservation: NSKeyValueObservation?
    private var isRecovering = false
    private var activeNavigation: WKNavigation?
    private var lastCompletedNavigation: WKNavigation?
    private var lastCommittedURL: URL?
    private var recoveryTestRetiredNavigation: WKNavigation?
    private var recoveryTestReloadCommandCount = 0
    private let retiredNavigations = NSHashTable<WKNavigation>.weakObjects()

    private struct DownloadRecord {
        let id = UUID().uuidString
        let download: WKDownload
        var destination: URL?
        var stagingDirectory: URL?
    }
    private var downloads: [ObjectIdentifier: DownloadRecord] = [:]
    var profileStore: WKWebsiteDataStore { profile.store }

    init(profile: ProfileChoice, initialURL: URL?, onClose: @escaping (BrowserWindowController) -> Void, openWindow: @escaping (ProfileChoice, URL) -> Void) {
        self.profile = profile
        self.onClose = onClose
        self.openWindow = openWindow
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 760), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "Vezham WK Prototype — \(profile.title)"
        window.center()
        super.init(window: window)
        window.delegate = self
        buildView(initialURL: initialURL)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    private func buildView(initialURL: URL?) {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = profile.store
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true

        let back = button("‹", #selector(goBack), "Back")
        let forward = button("›", #selector(goForward), "Forward")
        let reload = button("↻", #selector(reload), "Reload")
        let stop = button("■", #selector(stop), "Stop")
        let zoomOut = button("−", #selector(zoomOutAction), "Zoom out")
        let zoomIn = button("+", #selector(zoomInAction), "Zoom in")
        let find = button("Find", #selector(findAction), "Find in page")
        addressField.placeholderString = "Enter an http or https address"
        addressField.delegate = self
        findField.placeholderString = "Find in page"
        findField.target = self
        findField.action = #selector(findAction)
        statusField.lineBreakMode = .byTruncatingTail
        statusField.font = .systemFont(ofSize: 11)
        progress.isIndeterminate = false
        progress.minValue = 0
        progress.maxValue = 1
        progress.style = .bar

        let controls = NSStackView(views: [back, forward, reload, stop, addressField, zoomOut, zoomIn, findField, find])
        controls.orientation = .horizontal
        controls.alignment = .centerY
        controls.spacing = 6
        controls.translatesAutoresizingMaskIntoConstraints = false
        addressField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addressField.widthAnchor.constraint(greaterThanOrEqualToConstant: 240).isActive = true
        findField.widthAnchor.constraint(equalToConstant: 150).isActive = true

        let bottom = NSStackView(views: [progress, statusField])
        bottom.orientation = .vertical
        bottom.alignment = .leading
        bottom.spacing = 3
        bottom.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(controls)
        content.addSubview(webView)
        content.addSubview(bottom)
        NSLayoutConstraint.activate([
            controls.topAnchor.constraint(equalTo: content.topAnchor, constant: 8),
            controls.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 10),
            controls.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -10),
            webView.topAnchor.constraint(equalTo: controls.bottomAnchor, constant: 8),
            webView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottom.topAnchor, constant: -4),
            bottom.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 10),
            bottom.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -10),
            bottom.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -6),
            progress.widthAnchor.constraint(equalTo: bottom.widthAnchor),
        ])
        window?.contentView = content
        progressObservation = webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] view, _ in
            DispatchQueue.main.async { self?.progress.doubleValue = view.estimatedProgress }
        }
        if let initialURL { dispatch(.init(version: 1, requestID: UUID(), command: .navigate(initialURL))) }
    }

    // Native-only helpers for the isolated recovery test; no page message handler.
    private var recoveryTestEnabled: Bool { CommandLine.arguments.contains("--test-recovery-ui") }

    func recoveryTestSnapshot(_ completion: @escaping ([String: Any]) -> Void) {
        guard recoveryTestEnabled, let webView else { completion([:]); return }
        var result: [String: Any] = ["profile": profile.title, "status": statusField.stringValue,
            "isRecovering": isRecovering, "address": addressField.stringValue,
            "lastCommittedURL": lastCommittedURL?.absoluteString ?? "", "visible": window?.isVisible ?? false,
            "reloadCommandCount": recoveryTestReloadCommandCount]
        guard !isRecovering, webView.url?.path == "/recovery-ui" else { completion(result); return }
        webView.evaluateJavaScript("({ready:document.readyState,marker:localStorage.getItem('recovery-marker'),cookie:document.cookie,documentID:window.fixtureDocumentID,url:location.href})") { value, _ in
            result["document"] = value as? [String: Any] ?? [:]
            completion(result)
        }
    }

    func recoveryTestSeed(_ marker: String, completion: @escaping (Bool) -> Void) {
        guard recoveryTestEnabled, webView.url?.path == "/recovery-ui", !isRecovering else { completion(false); return }
        webView.callAsyncJavaScript("localStorage.setItem('recovery-marker',marker);document.cookie='fixture_recovery='+encodeURIComponent(marker)+';path=/;SameSite=Lax';return true;", arguments: ["marker": marker], in: nil, in: .page) { result in
            switch result { case .success(let value): completion((value as? Bool) == true); case .failure: completion(false) }
        }
    }

    func recoveryTestRejectStaleCallbacks() -> Bool {
        guard recoveryTestEnabled, let stale = recoveryTestRetiredNavigation, let webView else { return false }
        let before = (statusField.stringValue, addressField.stringValue, isRecovering, lastCommittedURL)
        self.webView(webView, didStartProvisionalNavigation: stale)
        self.webView(webView, didCommit: stale)
        self.webView(webView, didFinish: stale)
        self.webView(webView, didFail: stale, withError: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
        self.webView(webView, didFailProvisionalNavigation: stale, withError: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
        return before == (statusField.stringValue, addressField.stringValue, isRecovering, lastCommittedURL)
    }

    func recoveryTestRejectForeignCallbacks(from other: BrowserWindowController) -> Bool {
        guard recoveryTestEnabled, let foreign = other.webView, let navigation = other.activeNavigation else { return false }
        let before = (statusField.stringValue, addressField.stringValue, isRecovering, lastCommittedURL)
        self.webView(foreign, didStartProvisionalNavigation: navigation)
        self.webView(foreign, didCommit: navigation)
        self.webView(foreign, didFinish: navigation)
        self.webViewWebContentProcessDidTerminate(foreign)
        return before == (statusField.stringValue, addressField.stringValue, isRecovering, lastCommittedURL)
    }

    private func button(_ title: String, _ action: Selector, _ help: String) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.toolTip = help
        return button
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard control === addressField, commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
        navigateFromAddressField()
        return true
    }

    @objc private func navigateFromAddressField() {
        guard let url = NavigationPolicy.normalizedURL(addressField.stringValue) else {
            statusField.stringValue = "Only http:// and https:// URLs are allowed"
            return
        }
        dispatch(.init(version: 1, requestID: UUID(), command: .navigate(url)))
    }

    private func dispatch(_ envelope: CommandEnvelope) {
        guard envelope.version == 1 else { statusField.stringValue = "Unsupported command version"; return }
        switch envelope.command {
        case .navigate(let url):
            isRecovering = false
            activeNavigation = webView.load(URLRequest(url: url))
            RedactedLog.navigation("navigate", url: url)
        case .back: if webView.canGoBack { isRecovering = false; activeNavigation = webView.goBack() }
        case .forward: if webView.canGoForward { isRecovering = false; activeNavigation = webView.goForward() }
        case .reload:
            if recoveryTestEnabled { recoveryTestReloadCommandCount += 1 }
            if isRecovering {
                guard let url = lastCommittedURL else { return }
                isRecovering = false
                activeNavigation = webView.load(URLRequest(url: url))
            } else { activeNavigation = webView.reload() }
        case .stop: webView.stopLoading()
        case .zoom(let factor): webView.pageZoom = min(3, max(0.5, factor))
        }
    }

    @objc private func goBack() { dispatch(.init(version: 1, requestID: UUID(), command: .back)) }
    @objc private func goForward() { dispatch(.init(version: 1, requestID: UUID(), command: .forward)) }
    @objc private func reload() { dispatch(.init(version: 1, requestID: UUID(), command: .reload)) }
    @objc private func stop() { dispatch(.init(version: 1, requestID: UUID(), command: .stop)) }
    @objc private func zoomOutAction() { dispatch(.init(version: 1, requestID: UUID(), command: .zoom(webView.pageZoom - 0.1))) }
    @objc private func zoomInAction() { dispatch(.init(version: 1, requestID: UUID(), command: .zoom(webView.pageZoom + 0.1))) }

    @objc private func findAction() {
        guard !findField.stringValue.isEmpty else { return }
        let options = WKFindConfiguration()
        options.wraps = true
        webView.find(findField.stringValue, configuration: options) { [weak self] result in
            self?.statusField.stringValue = result.matchFound ? "Match found" : "No match"
        }
    }

    func windowWillClose(_ notification: Notification) {
        cancelDownloadsForShutdown()
        progressObservation = nil
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.removeFromSuperview()
        webView = nil
        ProfileRegistry.shared.release(profile)
        onClose(self)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard webView === self.webView, !isRecovering, let navigation, !retiredNavigations.contains(navigation) else { return }
        activeNavigation = navigation
        statusField.stringValue = "Loading…"
        progress.isHidden = false
        RedactedLog.navigation("navigation-start", url: webView.url)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard acceptsNavigationCallback(webView, navigation) else { return }
        lastCommittedURL = webView.url
        addressField.stringValue = webView.url?.absoluteString ?? ""
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard acceptsNavigationCallback(webView, navigation) else { return }
        lastCompletedNavigation = navigation
        isRecovering = false
        let fixtureCase = webView.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems?.first(where: { $0.name == "case" })?.value ?? ""
        LocalInteractionProbe.record("navigation-finished", details: ["path": webView.url?.path ?? "", "fixtureCase": fixtureCase, "profile": profile.title, "store": String(describing: ObjectIdentifier(profile.store))])
        statusField.stringValue = "Loaded — \(profile.title)"
        addressField.stringValue = webView.url?.absoluteString ?? ""
        RedactedLog.navigation("navigation-finish", url: webView.url)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard acceptsNavigationCallback(webView, navigation) else { return }
        showNavigationFailure(webView.url)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard acceptsNavigationCallback(webView, navigation) else { return }
        showNavigationFailure(webView.url)
    }

    private func acceptsNavigationCallback(_ view: WKWebView, _ navigation: WKNavigation?) -> Bool {
        guard view === webView, !isRecovering, let navigation else { return false }
        return navigation === activeNavigation && !retiredNavigations.contains(navigation)
    }

    private func showNavigationFailure(_ url: URL?) {
        statusField.stringValue = "Navigation failed — \(RedactedLog.host(url))"
        RedactedLog.navigation("navigation-failed", url: url)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        guard webView === self.webView else { return }
        if recoveryTestEnabled { recoveryTestRetiredNavigation = lastCompletedNavigation }
        if let activeNavigation { retiredNavigations.add(activeNavigation) }
        if let lastCompletedNavigation { retiredNavigations.add(lastCompletedNavigation) }
        activeNavigation = nil
        isRecovering = true
        progress.isHidden = true
        statusField.stringValue = "Web content stopped — use Reload to recover"
        RedactedLog.navigation("content-process-terminated", url: webView.url)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard !isRecovering else { decisionHandler(.cancel); return }
        guard let url = navigationAction.request.url, NavigationPolicy.normalizedURL(url.absoluteString) != nil else {
            LocalInteractionProbe.record("navigation-blocked", details: ["scheme": navigationAction.request.url?.scheme ?? "", "currentPath": webView.url?.path ?? "", "mainFrame": navigationAction.targetFrame?.isMainFrame ?? false])
            decisionHandler(.cancel)
            return
        }
        if navigationAction.targetFrame == nil {
            LocalInteractionProbe.record("popup-opened", details: ["profile": profile.title, "store": String(describing: ObjectIdentifier(profile.store))])
            decisionHandler(.cancel)
            openWindow(profile, url)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(TransferSupport.responseShouldDownload(navigationResponse) ? .download : .allow)
    }

    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.canChooseDirectories = parameters.allowsDirectories
        panel.canChooseFiles = true
        panel.prompt = "Choose File"
        panel.message = "Choose a file to share with \(OriginLabel.from(frame.securityOrigin))."
        if CommandLine.arguments.contains("--test-upload") || CommandLine.arguments.contains("--test-local-interactions") || CommandLine.arguments.contains("--test-phase3-local"),
           let directoryIndex = CommandLine.arguments.firstIndex(of: "--test-upload-directory"),
           CommandLine.arguments.indices.contains(directoryIndex + 1) {
            let directory = CommandLine.arguments[directoryIndex + 1]
            panel.directoryURL = URL(fileURLWithPath: directory, isDirectory: true)
        }
        if CommandLine.arguments.contains("--test-phase3-local"), parameters.allowsDirectories,
           let index = CommandLine.arguments.firstIndex(of: "--test-directory-fixture-root"),
           CommandLine.arguments.indices.contains(index + 1) {
            panel.directoryURL = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
        }
        if panel.runModal() == .OK {
            LocalInteractionProbe.record("upload-selected", details: ["fileCount": panel.urls.count, "directoriesAllowed": parameters.allowsDirectories])
            completionHandler(panel.urls)
        } else {
            LocalInteractionProbe.record("upload-cancelled", details: ["fileCount": 0])
            completionHandler(nil)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        guard let url = navigationAction.request.url, NavigationPolicy.normalizedURL(url.absoluteString) != nil else {
            LocalInteractionProbe.record("navigation-blocked", details: ["scheme": navigationAction.request.url?.scheme ?? "", "currentPath": webView.url?.path ?? "", "mainFrame": navigationAction.targetFrame?.isMainFrame ?? false])
            decisionHandler(.cancel, preferences)
            return
        }
        if navigationAction.targetFrame == nil {
            LocalInteractionProbe.record("popup-opened", details: ["profile": profile.title, "store": String(describing: ObjectIdentifier(profile.store))])
            decisionHandler(.cancel, preferences)
            openWindow(profile, url)
            return
        }
        decisionHandler(.allow, preferences)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let key = ObjectIdentifier(download)
        var record = DownloadRecord(download: download)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = TransferSupport.safeSuggestedFilename(suggestedFilename)
        panel.canCreateDirectories = true
        panel.message = "Save a download from \(OriginLabel.from(response.url))."
        if CommandLine.arguments.contains("--test-download-panel") || CommandLine.arguments.contains("--test-local-interactions") || CommandLine.arguments.contains("--test-phase3-local"),
           let directoryIndex = CommandLine.arguments.firstIndex(of: "--test-download-directory"),
           CommandLine.arguments.indices.contains(directoryIndex + 1) {
            let directory = CommandLine.arguments[directoryIndex + 1]
            panel.directoryURL = URL(fileURLWithPath: directory, isDirectory: true)
        }
        if panel.runModal() == .OK, let destination = panel.url {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("WKPrototype-Download-\(record.id)", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
                record.destination = destination
                record.stagingDirectory = directory
                downloads[key] = record
                LocalInteractionProbe.record("download-selected", details: ["downloadID": record.id, "suggestedName": suggestedFilename, "selectedBasename": destination.lastPathComponent])
                completionHandler(directory.appendingPathComponent("payload.partial"))
            } catch {
                LocalInteractionProbe.record("download-save-error", details: ["downloadID": record.id])
                statusField.stringValue = "Download could not be saved"
                completionHandler(nil)
            }
        } else {
            downloads[key] = record
            LocalInteractionProbe.record("download-cancelled", details: ["downloadID": record.id, "suggestedName": suggestedFilename])
            completionHandler(nil)
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let record = downloads.removeValue(forKey: ObjectIdentifier(download)),
              let destination = record.destination, let directory = record.stagingDirectory else { return }
        let scoped = destination.startAccessingSecurityScopedResource()
        defer {
            if scoped { destination.stopAccessingSecurityScopedResource() }
            cleanStaging(record)
        }
        do {
            let payload = directory.appendingPathComponent("payload.partial")
            if FileManager.default.fileExists(atPath: destination.path) {
                _ = try FileManager.default.replaceItemAt(destination, withItemAt: payload)
            } else {
                try FileManager.default.moveItem(at: payload, to: destination)
            }
            LocalInteractionProbe.record("download-finished", details: ["downloadID": record.id])
            statusField.stringValue = "Download finished"
        } catch {
            LocalInteractionProbe.record("download-save-error", details: ["downloadID": record.id])
            statusField.stringValue = "Download could not be saved"
        }
    }
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let record = downloads.removeValue(forKey: ObjectIdentifier(download))
        LocalInteractionProbe.record("download-error", details: ["downloadID": record?.id ?? "untracked", "domain": (error as NSError).domain, "code": (error as NSError).code])
        if let record { cleanStaging(record) }
        let nativeError = error as NSError
        statusField.stringValue = nativeError.domain == NSURLErrorDomain && nativeError.code == NSURLErrorCancelled ? "Download cancelled" : "Download failed"
    }

    private func cleanStaging(_ record: DownloadRecord) {
        guard let directory = record.stagingDirectory else { return }
        do {
            if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
            LocalInteractionProbe.record("download-cleanup", details: ["downloadID": record.id, "removed": true])
        } catch {
            LocalInteractionProbe.record("download-cleanup", details: ["downloadID": record.id, "removed": false])
        }
    }

    func cancelDownloadsForShutdown() {
        let active = Array(downloads.values)
        downloads.removeAll()
        for record in active {
            record.download.cancel(nil)
            cleanStaging(record)
        }
    }

    @available(macOS 12.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Allow media access?"
        let typeDescription = String(describing: type)
        let kind: String
        switch type {
        case .camera:
            kind = "camera"
        case .microphone:
            kind = "microphone"
        case .cameraAndMicrophone:
            kind = "camera and microphone"
        @unknown default:
            (NSApp.delegate as? PrototypeApplication)?.recordPermissionTestEvent("unknown media capture type denied: \(typeDescription)")
            decisionHandler(.deny)
            return
        }
        alert.informativeText = "\(OriginLabel.from(origin)) requests \(kind). Allow only if you intended this request."
        alert.addButton(withTitle: "Allow Once")
        alert.addButton(withTitle: "Deny")
        (NSApp.delegate as? PrototypeApplication)?.recordPermissionTestEvent("native permission prompt shown: \(kind) from \(OriginLabel.from(origin))")
        let response = alert.runModal()
        let choice = response == .alertSecondButtonReturn ? "deny" : (response == .alertFirstButtonReturn ? "allow" : "dismissed")
        (NSApp.delegate as? PrototypeApplication)?.recordPermissionTestEvent("native permission prompt choice: \(choice)")
        // A denial-only experiment must not grant page access even if its
        // default button is accidentally activated during desktop testing.
        let denialOnly = CommandLine.arguments.contains("--test-permission-deny")
        let decision: WKPermissionDecision = !denialOnly && response == .alertFirstButtonReturn ? .grant : .deny
        (NSApp.delegate as? PrototypeApplication)?.recordPermissionTestEvent("native permission prompt decision: \(decision == .deny ? "deny" : "grant")")
        decisionHandler(decision)
    }
}

private final class IsolationHarness: NSObject, WKNavigationDelegate {
    enum Mode: Equatable { case seed, verify }
    private let mode: Mode
    private let runID: String
    private let completion: (String?) -> Void
    private var views: [WKWebView] = []
    private var steps: [[String: Any]] = []
    private var failures: [String] = []
    private var finished = false

    init(mode: Mode, runID: String, completion: @escaping (String?) -> Void) {
        self.mode = mode
        self.runID = runID
        self.completion = completion
    }

    func start() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            guard let self, !self.finished else { return }
            self.fail("harness timed out")
        }
        let storeA = WKWebsiteDataStore(forIdentifier: UUID(uuidString: "A12A0000-0000-4000-8000-000000000001")!)
        let storeB = WKWebsiteDataStore(forIdentifier: UUID(uuidString: "B12B0000-0000-4000-8000-000000000002")!)
        if mode == .seed {
            load(profile: "a", store: storeA, fixtureMode: "seed") { [weak self] a in
                self?.check(a, expects: "marker-a", label: "persistent A seed")
                self?.load(profile: "a", store: storeA, fixtureMode: "verify") { [weak self] same in
                    self?.check(same, expects: "marker-a", label: "persistent A concurrent view")
                    self?.record("persistent profile A reuses its HTTP cache", passed: a["httpCacheGeneration"] as? String == same["httpCacheGeneration"] as? String)
                    self?.load(profile: "b", store: storeB, fixtureMode: "seed") { [weak self] b in
                        self?.check(b, expects: "marker-b", label: "persistent B seed")
                        self?.assertCrossIsolation(a: a, b: b)
                        self?.seedPrivateSession()
                    }
                }
            }
        } else {
            load(profile: "a", store: storeA, fixtureMode: "verify") { [weak self] a in
                self?.check(a, expects: "marker-a", label: "persistent A after relaunch")
                self?.load(profile: "b", store: storeB, fixtureMode: "verify") { [weak self] b in
                    self?.check(b, expects: "marker-b", label: "persistent B after relaunch")
                    self?.assertCrossIsolation(a: a, b: b)
                    self?.verifyFreshPrivateAndClear(storeA: storeA, storeB: storeB)
                }
            }
        }
    }

    private func seedPrivateSession() {
        let registry = ProfileRegistry.shared
        let firstChoice = registry.acquirePrivateSession()
        registry.retain(firstChoice)
        load(profile: "private", store: firstChoice.store, fixtureMode: "seed") { [weak self] first in
            self?.check(first, expects: "marker-private", label: "private session seed")
            let secondChoice = registry.acquirePrivateSession()
            registry.retain(secondChoice)
            self?.record("private windows share manager store", passed: firstChoice.store === secondChoice.store)
            self?.load(profile: "private", store: secondChoice.store, fixtureMode: "verify") { [weak self] second in
                self?.check(second, expects: "marker-private", label: "private concurrent view")
                self?.closeView(at: 3)
                registry.release(firstChoice)
                let remainingChoice = registry.acquirePrivateSession()
                registry.retain(remainingChoice)
                self?.record("private session remains while a window is retained", passed: remainingChoice.store === secondChoice.store)
                self?.load(profile: "private", store: remainingChoice.store, fixtureMode: "verify") { [weak self] remaining in
                    self?.check(remaining, expects: "marker-private", label: "private data survives one window close")
                    self?.closeViews(from: 3)
                    registry.release(secondChoice)
                    registry.release(remainingChoice)
                    let freshChoice = registry.acquirePrivateSession()
                    self?.record("private manager replaces session after last release", passed: freshChoice.store !== secondChoice.store)
                    self?.load(profile: "private", store: freshChoice.store, fixtureMode: "verify") { [weak self] fresh in
                        self?.check(fresh, expects: nil, label: "new private store starts empty")
                        registry.release(freshChoice)
                        self?.writeResultsAndFinish()
                    }
                }
            }
        }
    }

    private func verifyFreshPrivateAndClear(storeA: WKWebsiteDataStore, storeB: WKWebsiteDataStore) {
        let privateStore = WKWebsiteDataStore.nonPersistent()
        load(profile: "private", store: privateStore, fixtureMode: "verify") { [weak self] state in
            self?.check(state, expects: nil, label: "private does not survive app relaunch")
            self?.removeAllData(from: storeA) { [weak self] in
                self?.removeAllData(from: storeB) { [weak self] in
                    self?.load(profile: "a", store: storeA, fixtureMode: "verify") { [weak self] clearedA in
                        self?.check(clearedA, expects: nil, label: "profile A data deletion")
                        self?.load(profile: "b", store: storeB, fixtureMode: "verify") { [weak self] clearedB in
                            self?.check(clearedB, expects: nil, label: "profile B data deletion")
                            self?.writeResultsAndFinish()
                        }
                    }
                }
            }
        }
    }

    private func load(profile: String, store: WKWebsiteDataStore, fixtureMode: String, completion: @escaping ([String: Any]) -> Void) {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = store
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        views.append(view)
        let url = URL(string: "\(fixtureBase.absoluteString)?profile=\(profile)&mode=\(fixtureMode)")!
        pending[ObjectIdentifier(view)] = completion
        view.load(URLRequest(url: url))
    }

    private var pending: [ObjectIdentifier: ([String: Any]) -> Void] = [:]

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.callAsyncJavaScript("return await window.fixtureState();", arguments: [:], in: nil, in: .page, completionHandler: { [weak self, weak webView] result in
            guard let self, let webView else { return }
            let key = ObjectIdentifier(webView)
            guard let callback = self.pending.removeValue(forKey: key) else { return }
            switch result {
            case .success(let value):
                if let state = value as? [String: Any] { callback(state) }
                else { self.failures.append("fixture returned unexpected value"); callback([:]) }
            case .failure:
                self.failures.append("fixture state evaluation failed")
                callback([:])
            }
        })
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        fail("fixture navigation failed")
    }

    private func check(_ state: [String: Any], expects marker: String?, label: String) {
        let fields = ["local", "indexedDB", "cache", "httpCache", "auth"]
        var passed = (state["bridgeAbsent"] as? Bool) == true
        if let marker {
            passed = passed && fields.allSatisfy { state[$0] as? String == marker }
            passed = passed && (state["serviceWorker"] as? Bool) == true
        } else {
            passed = passed && fields.allSatisfy { state[$0] == nil || state[$0] is NSNull || state[$0] as? String == "missing" }
            passed = passed && (state["serviceWorker"] as? Bool) == false
        }
        let sanitized: [String: Any] = [
            "label": label,
            "expectedMarker": marker ?? "absent",
            "observedFieldsMatch": passed,
            "bridgeAbsent": state["bridgeAbsent"] as? Bool ?? false,
            "serviceWorkerPresent": state["serviceWorker"] as? Bool ?? false,
        ]
        steps.append(sanitized)
        if !passed { failures.append(label) }
    }

    private func record(_ label: String, passed: Bool) {
        steps.append(["label": label, "passed": passed])
        if !passed { failures.append(label) }
    }

    private func assertCrossIsolation(a: [String: Any], b: [String: Any]) {
        let passed = (a["local"] as? String == "marker-a") && (b["local"] as? String == "marker-b") && (a["auth"] as? String == "marker-a") && (b["auth"] as? String == "marker-b") && (a["httpCache"] as? String == "marker-a") && (b["httpCache"] as? String == "marker-b")
        record("persistent profiles A/B cross-isolation including HTTP cache", passed: passed)
    }

    private func removeAllData(from store: WKWebsiteDataStore, completion: @escaping () -> Void) {
        store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast, completionHandler: completion)
    }

    private func closeView(at index: Int) {
        guard views.indices.contains(index) else { return }
        let view = views.remove(at: index)
        view.stopLoading()
        view.navigationDelegate = nil
        view.removeFromSuperview()
    }

    private func closeViews(from index: Int) {
        guard index < views.count else { return }
        for view in views[index...] {
            view.stopLoading()
            view.navigationDelegate = nil
            view.removeFromSuperview()
        }
        views.removeSubrange(index...)
    }

    private func writeResultsAndFinish() {
        guard !finished else { return }
        finished = true
        let result: [String: Any] = [
            "mode": mode == .seed ? "seed" : "verify",
            "status": failures.isEmpty ? "passed" : "failed",
            "tests": steps,
            "failureCount": failures.count,
            "failures": failures,
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("WKPrototype", isDirectory: true)
            try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            let resultURL = supportDirectory.appendingPathComponent("isolation-results-\(runID)-\(mode == .seed ? "seed" : "verify").json")
            try data.write(to: resultURL, options: .atomic)
            FileHandle.standardError.write(Data("isolation results: \(resultURL.path)\n".utf8))
            completion(failures.isEmpty ? "passed" : "failed")
        } catch {
            completion("failed-results-write")
        }
    }

    private func fail(_ description: String) {
        failures.append(description)
        writeResultsAndFinish()
    }
}

private final class CrashRecoveryHarness: NSObject, WKNavigationDelegate {
    private enum State: Equatable { case initialLoad, awaitingTermination, reloading }
    private let runID: String
    private let completion: (String?) -> Void
    private var webView: WKWebView!
    private var window: NSWindow?
    private var state = State.initialLoad
    private var initialURL: URL?
    private var terminationSystemUptime: Double?
    private var callbackToDOMReadyMs: Double?
    private var observedNativeTitles: [String] = []
    private var readyURL: URL?
    private var steps: [[String: Any]] = []
    private var failures: [String] = []
    private var finished = false

    init(runID: String, completion: @escaping (String?) -> Void) {
        self.runID = runID
        self.completion = completion
    }

    func start() {
        Timer.scheduledTimer(withTimeInterval: 45, repeats: false) { [weak self] _ in
            guard let self, !self.finished else { return }
            self.record("content-process recovery completed before timeout", passed: false)
            self.finish()
        }

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 600), configuration: configuration)
        webView.navigationDelegate = self
        let frame = NSRect(x: 0, y: 0, width: 900, height: 600)
        let testWindow = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        testWindow.contentView = webView
        window = testWindow
        let url = URL(string: "http://127.0.0.1:18765/crash-fixture")!
        webView.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        switch state {
        case .initialLoad:
            state = .awaitingTermination
            initialURL = webView.url
            observedNativeTitles.append(webView.title ?? "<nil>")
            webView.evaluateJavaScript("document.title === 'WK Recovery Fixture' && document.querySelector('h1')?.textContent === 'Local recovery page'") { [weak self] value, error in
                guard let self, !self.finished else { return }
                let valid = error == nil && (value as? Bool) == true && self.initialURL?.absoluteString == "http://127.0.0.1:18765/crash-fixture"
                self.record("local recovery fixture loaded", passed: valid)
                if valid { self.writeReadyMarker() } else { self.finish() }
            }
        case .awaitingTermination:
            break
        case .reloading:
            record("host remains alive after content termination", passed: NSApp.isRunning)
            observedNativeTitles.append(webView.title ?? "<nil>")
            record("last committed URL reloads successfully", passed: webView.url == initialURL)
            webView.evaluateJavaScript("document.readyState === 'complete' && document.title === 'WK Recovery Fixture' && document.querySelector('h1')?.textContent === 'Local recovery page'") { [weak self] value, error in
                guard let self, !self.finished else { return }
                self.record("reloaded fixture responds to a DOM readiness query", passed: error == nil && (value as? Bool) == true)
                if let started = self.terminationSystemUptime {
                    self.callbackToDOMReadyMs = (ProcessInfo.processInfo.systemUptime - started) * 1000
                }
                self.finish()
            }
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        terminationSystemUptime = ProcessInfo.processInfo.systemUptime
        guard state == .awaitingTermination else {
            record("content termination callback arrived in expected state", passed: false)
            finish()
            return
        }
        record("WebKit reports content-process termination", passed: true)
        record("host process remains alive for recovery", passed: NSApp.isRunning)
        record("last committed URL remains available", passed: webView.url == initialURL)
        state = .reloading
        webView.reload()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        record("local recovery fixture navigation succeeds", passed: false)
        finish()
    }

    private func writeReadyMarker() {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WKPrototype", isDirectory: true)
        readyURL = supportDirectory.appendingPathComponent("crash-ready-\(runID).json")
        let ready: [String: Any] = [
            "status": "ready",
            "hostProcessIdentifier": ProcessInfo.processInfo.processIdentifier,
            "fixtureURL": webView.url?.absoluteString ?? "",
        ]
        do {
            try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: ready, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: readyURL!, options: .atomic)
            FileHandle.standardError.write(Data("crash recovery harness ready\n".utf8))
        } catch {
            record("write crash test ready marker", passed: false)
            finish()
        }
    }

    private func record(_ label: String, passed: Bool) {
        steps.append(["label": label, "passed": passed])
        if !passed { failures.append(label) }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        if let readyURL { try? FileManager.default.removeItem(at: readyURL) }
        let result: [String: Any] = [
            "mode": "crash-recovery",
            "runID": runID,
            "callbackToDOMReadyMs": callbackToDOMReadyMs as Any? ?? NSNull(),
            "nativeTitlesAtDidFinish": observedNativeTitles,
            "timingScope": "Native termination callback through last-URL reload and a successful DOM readiness query; excludes signal-to-callback delay. External runner separately bounds signal-to-result time.",
            "hostOSVersion": ProcessInfo.processInfo.operatingSystemVersionString,
            "status": failures.isEmpty ? "passed" : "failed",
            "tests": steps,
            "failureCount": failures.count,
            "failures": failures,
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("WKPrototype", isDirectory: true)
            try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            let resultURL = supportDirectory.appendingPathComponent("crash-recovery-results-\(runID).json")
            try data.write(to: resultURL, options: .atomic)
            FileHandle.standardError.write(Data("crash recovery results: \(resultURL.path)\n".utf8))
            completion(failures.isEmpty ? "passed" : "failed")
        } catch {
            completion("failed-results-write")
        }
    }
}

private final class DownloadHarness: NSObject, WKNavigationDelegate, WKDownloadDelegate {
    private let runID: String
    private let completion: (String?) -> Void
    private let payload = Data("Vezham synthetic download fixture\n".utf8)
    private var webView: WKWebView!
    private var window: NSWindow?
    private var activeDownload: WKDownload?
    private var transferDirectory: URL!
    private var destinationURL: URL?
    private var steps: [[String: Any]] = []
    private var failures: [String] = []
    private var finished = false

    init(runID: String, completion: @escaping (String?) -> Void) {
        self.runID = runID
        self.completion = completion
    }

    func start() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            guard let self, !self.finished else { return }
            self.record("download completed before timeout", passed: false)
            self.finish()
        }

        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WKPrototype", isDirectory: true)
        transferDirectory = supportDirectory.appendingPathComponent("transfers-\(runID)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: transferDirectory, withIntermediateDirectories: true)
        } catch {
            record("create isolated transfer directory", passed: false)
            finish()
            return
        }

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 600), configuration: configuration)
        webView.navigationDelegate = self
        let frame = NSRect(x: 0, y: 0, width: 900, height: 600)
        let testWindow = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        testWindow.contentView = webView
        window = testWindow
        let url = URL(string: "http://127.0.0.1:18765/transfer-download")!
        webView.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        begin(download)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let shouldDownload = TransferSupport.responseShouldDownload(navigationResponse)
        record("attachment response requests WebKit download policy", passed: shouldDownload)
        decisionHandler(shouldDownload ? .download : .allow)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        begin(download)
    }

    private func begin(_ download: WKDownload) {
        activeDownload = download
        download.delegate = self
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let safeName = TransferSupport.safeSuggestedFilename(suggestedFilename)
        let isSafeBasename = !safeName.isEmpty
            && safeName == URL(fileURLWithPath: safeName).lastPathComponent
            && !safeName.contains("/")
            && safeName != "."
            && safeName != ".."
        record("path-like suggested filename reduced to a safe basename", passed: isSafeBasename)
        steps[steps.count - 1]["observedSuggestedFilename"] = suggestedFilename
        steps[steps.count - 1]["destinationName"] = safeName
        let destination = transferDirectory.appendingPathComponent(safeName).standardizedFileURL
        let staysInsideTestDirectory = destination.deletingLastPathComponent().path == transferDirectory.standardizedFileURL.path
        record("download destination remains inside isolated directory", passed: staysInsideTestDirectory)
        destinationURL = destination
        completionHandler(destination)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let destinationURL, let actual = try? Data(contentsOf: destinationURL) else {
            record("synthetic download file exists", passed: false)
            finish()
            return
        }
        record("downloaded bytes match loopback fixture", passed: actual == payload)
        finish()
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        record("download completed without error", passed: false)
        finish()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if activeDownload != nil {
            record("navigation handed off to WKDownload", passed: true)
            return
        }
        record("loopback download response received", passed: false)
        finish()
    }

    private func record(_ label: String, passed: Bool) {
        steps.append(["label": label, "passed": passed])
        if !passed { failures.append(label) }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        activeDownload = nil
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        let result: [String: Any] = [
            "mode": "download",
            "hostOSVersion": ProcessInfo.processInfo.operatingSystemVersionString,
            "status": failures.isEmpty ? "passed" : "failed",
            "tests": steps,
            "failureCount": failures.count,
            "failures": failures,
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("WKPrototype", isDirectory: true)
            try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            let resultURL = supportDirectory.appendingPathComponent("download-results-\(runID).json")
            try data.write(to: resultURL, options: .atomic)
            if let transferDirectory { try? FileManager.default.removeItem(at: transferDirectory) }
            FileHandle.standardError.write(Data("download results: \(resultURL.path)\n".utf8))
            completion(failures.isEmpty ? "passed" : "failed")
        } catch {
            completion("failed-results-write")
        }
    }
}

private final class FindZoomHarness: NSObject, WKNavigationDelegate {
    private let runID: String
    private let completion: (String?) -> Void
    private var caseView: WKWebView!
    private var movementView: WKWebView!
    private var windows: [NSWindow] = []
    private var steps: [[String: Any]] = []
    private var failures: [String] = []
    private var caseDone = false
    private var movementDone = false
    private var finished = false

    init(runID: String, completion: @escaping (String?) -> Void) {
        self.runID = runID
        self.completion = completion
    }

    func start() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            guard let self, !self.finished else { return }
            self.record("harness completed before timeout", passed: false)
            self.finishIfReady(force: true)
        }

        let zoomA = makeView()
        let zoomB = makeView()
        attachToHiddenWindow(zoomA)
        attachToHiddenWindow(zoomB)
        let zoomBInitial = zoomB.pageZoom
        zoomA.pageZoom = 1.5
        record("zoom set and read back", passed: abs(zoomA.pageZoom - 1.5) < 0.001)
        record("zoom change stays scoped to its view", passed: abs(zoomB.pageZoom - zoomBInitial) < 0.001)
        zoomA.pageZoom = 1.0
        record("zoom resets to 1.0", passed: abs(zoomA.pageZoom - 1.0) < 0.001)
        zoomB.pageZoom = 1.25
        record("second view zoom set and read back", passed: abs(zoomB.pageZoom - 1.25) < 0.001)
        record("second view zoom does not change first view", passed: abs(zoomA.pageZoom - 1.0) < 0.001)

        caseView = makeView()
        movementView = makeView()
        caseView.navigationDelegate = self
        movementView.navigationDelegate = self
        attachToHiddenWindow(caseView)
        attachToHiddenWindow(movementView)
        caseView.loadHTMLString("<!doctype html><meta charset='utf-8'><main>Alpha alpha</main>", baseURL: nil)
        movementView.loadHTMLString("<!doctype html><meta charset='utf-8'><main>alpha alpha alpha</main>", baseURL: nil)
    }

    private func makeView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        return WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 600), configuration: configuration)
    }

    private func attachToHiddenWindow(_ view: WKWebView) {
        let frame = NSRect(x: 0, y: 0, width: 900, height: 600)
        let container = NSView(frame: frame)
        view.frame = container.bounds
        container.addSubview(view)
        let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = container
        windows.append(window)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView === caseView, !caseDone {
            runCaseSensitivityChecks()
        } else if webView === movementView, !movementDone {
            runMovementChecks()
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        record("local find fixture loaded", passed: false)
        if webView === caseView { caseDone = true }
        if webView === movementView { movementDone = true }
        finishIfReady()
    }

    private func runCaseSensitivityChecks() {
        find("ALPHA", in: caseView, caseSensitive: false, wraps: true, backwards: false, expected: true, label: "case-insensitive find") {
            self.find("ALPHA", in: self.caseView, caseSensitive: true, wraps: false, backwards: false, expected: false, label: "case-sensitive find rejects different case") {
                self.find("alpha", in: self.caseView, caseSensitive: true, wraps: true, backwards: false, expected: true, label: "case-sensitive find matches exact case") {
                    self.find("not-present", in: self.caseView, caseSensitive: false, wraps: true, backwards: false, expected: false, label: "find reports zero results") {
                        self.caseDone = true
                        self.finishIfReady()
                    }
                }
            }
        }
    }

    private func runMovementChecks() {
        find("alpha", in: movementView, caseSensitive: false, wraps: false, backwards: false, expected: true, label: "find next first match") {
            self.find("alpha", in: self.movementView, caseSensitive: false, wraps: false, backwards: false, expected: true, label: "find next advances to another match") {
                self.find("alpha", in: self.movementView, caseSensitive: false, wraps: false, backwards: true, expected: true, label: "find previous moves backward") {
                    self.find("alpha", in: self.movementView, caseSensitive: false, wraps: false, backwards: true, expected: false, label: "find previous stops at document start") {
                        self.find("alpha", in: self.movementView, caseSensitive: false, wraps: true, backwards: true, expected: true, label: "find wraps when enabled") {
                            self.movementDone = true
                            self.finishIfReady()
                        }
                    }
                }
            }
        }
    }

    private func find(_ text: String, in view: WKWebView, caseSensitive: Bool, wraps: Bool, backwards: Bool, expected: Bool, label: String, completion: @escaping () -> Void) {
        let configuration = WKFindConfiguration()
        configuration.caseSensitive = caseSensitive
        configuration.wraps = wraps
        configuration.backwards = backwards
        view.find(text, configuration: configuration) { [weak self] result in
            guard let self else { return }
            self.record(label, passed: result.matchFound == expected)
            completion()
        }
    }

    private func record(_ label: String, passed: Bool) {
        steps.append(["label": label, "passed": passed])
        if !passed { failures.append(label) }
    }

    private func finishIfReady(force: Bool = false) {
        guard !finished, force || (caseDone && movementDone) else { return }
        finished = true
        let result: [String: Any] = [
            "mode": "find-zoom",
            "hostOSVersion": ProcessInfo.processInfo.operatingSystemVersionString,
            "status": failures.isEmpty ? "passed" : "failed",
            "tests": steps,
            "failureCount": failures.count,
            "failures": failures,
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("WKPrototype", isDirectory: true)
            try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            let resultURL = supportDirectory.appendingPathComponent("find-zoom-results-\(runID).json")
            try data.write(to: resultURL, options: .atomic)
            FileHandle.standardError.write(Data("find/zoom results: \(resultURL.path)\n".utf8))
            completion(failures.isEmpty ? "passed" : "failed")
        } catch {
            completion("failed-results-write")
        }
    }
}

private final class RecoveryUIHarness: NSObject {
    private let runID: String
    private let completion: () -> Void
    private var controllers: [String: BrowserWindowController] = [:]
    private let roles = ["A", "B", "Private"]
    private var phase = "loading"
    private var round = 1
    private var affected = ""
    private var seen = Set<String>()
    private var baseline: [String: [String: Any]] = [:]
    private var latest: [String: [String: Any]] = [:]
    private var tests: [[String: Any]] = []
    private var failures: [String] = []
    private var pending = false
    private var finished = false
    private var quietStarted = 0.0
    private var timer: Timer?

    init(runID: String, completion: @escaping () -> Void) { self.runID = runID; self.completion = completion }
    func start() {
        let registry = ProfileRegistry.shared
        let choices: [ProfileChoice] = [registry.profileAChoice(), registry.profileBChoice(), registry.acquirePrivateSession()]
        for (index, role) in roles.enumerated() {
            let choice = choices[index]
            if case .privateSession = choice { registry.retain(choice) }
            let url = URL(string: "http://127.0.0.1:18765/recovery-ui?role=\(role)")!
            let controller = BrowserWindowController(profile: choice, initialURL: url, onClose: { [weak self] _ in
                guard let self, !self.finished else { return }; self.record("test window stayed open", false); self.finish()
            }, openWindow: { _, _ in })
            controller.window?.title = "Vezham Recovery Test — \(role)"
            controller.window?.setFrameOrigin(NSPoint(x: 80 + index * 45, y: 80 + index * 45))
            controllers[role] = controller
            controller.showWindow(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in self?.poll() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { [weak self] in
            guard let self, !self.finished else { return }; self.record("recovery UI test completed before timeout", false); self.finish()
        }
    }
    private func snapshots(_ index: Int = 0, _ values: [String: [String: Any]] = [:], completion: @escaping ([String: [String: Any]]) -> Void) {
        guard index < roles.count else { completion(values); return }
        let role = roles[index]
        controllers[role]?.recoveryTestSnapshot { [weak self] value in
            guard let self else { return }; var next = values; next[role] = value
            self.snapshots(index + 1, next, completion: completion)
        }
    }
    private func loaded(_ value: [String: Any]) -> Bool {
        let document = value["document"] as? [String: Any] ?? [:]
        return (value["isRecovering"] as? Bool) == false && (value["status"] as? String ?? "").hasPrefix("Loaded") && document["ready"] as? String == "complete"
    }
    private func markerOK(_ value: [String: Any], role: String) -> Bool {
        let document = value["document"] as? [String: Any] ?? [:]
        let marker = runID + "-" + role
        return document["marker"] as? String == marker && (document["cookie"] as? String ?? "").contains("fixture_recovery=" + marker)
    }
    private func documentID(_ value: [String: Any]) -> String { (value["document"] as? [String: Any])?["documentID"] as? String ?? "" }
    private func seed(_ index: Int = 0) {
        guard index < roles.count else {
            snapshots { [weak self] rows in
                guard let self, !self.finished else { return }
                for role in self.roles { self.record("\(role): initial synthetic storage is profile-scoped", self.markerOK(rows[role] ?? [:], role: role)) }
                self.baseline = rows; self.latest = rows; self.phase = "readyForCrash"; self.pending = false; self.writeState()
            }; return
        }
        let role = roles[index]
        controllers[role]?.recoveryTestSeed(runID + "-" + role) { [weak self] ok in
            guard let self, !self.finished else { return }; self.record("\(role): test marker seeded", ok); self.seed(index + 1)
        }
    }
    private func poll() {
        guard !finished, !pending else { return }; pending = true
        snapshots { [weak self] rows in
            guard let self, !self.finished else { return }; self.latest = rows
            switch self.phase {
            case "loading":
                if self.roles.allSatisfy({ self.loaded(rows[$0] ?? [:]) }) { self.phase = "seeding"; self.seed(); return }
            case "readyForCrash":
                let stopped = self.roles.filter { rows[$0]?["isRecovering"] as? Bool == true }
                if !stopped.isEmpty {
                    guard stopped.count == 1, let role = stopped.first, !self.seen.contains(role) else { self.record("one new profile view stopped per targeted signal", false); self.finish(); return }
                    self.affected = role
                    self.record("\(role): host alive and actual window visible", NSApp.isRunning && rows[role]?["visible"] as? Bool == true)
                    self.record("\(role): native recovery message appears", rows[role]?["status"] as? String == "Web content stopped — use Reload to recover")
                    self.record("\(role): stale start/commit/finish/failure callbacks cannot clear recovery", self.controllers[role]?.recoveryTestRejectStaleCallbacks() == true)
                    self.checkOthers(rows, label: "after crash")
                    self.quietStarted = ProcessInfo.processInfo.systemUptime
                    self.phase = "quiescence"
                }
            case "quiescence":
                if ProcessInfo.processInfo.systemUptime - self.quietStarted >= 1 {
                    self.record("\(self.affected): no automatic reload before toolbar action", rows[self.affected]?["isRecovering"] as? Bool == true && rows[self.affected]?["reloadCommandCount"] as? Int == self.baseline[self.affected]?["reloadCommandCount"] as? Int)
                    self.phase = "awaitingUserReload"
                    self.controllers[self.affected]?.window?.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                    self.writeState()
                }
            case "awaitingUserReload":
                let value = rows[self.affected] ?? [:]
                if self.loaded(value) {
                    let old = self.baseline[self.affected] ?? [:]
                    self.record("\(self.affected): toolbar Reload command observed", (value["reloadCommandCount"] as? Int ?? 0) == (old["reloadCommandCount"] as? Int ?? 0) + 1)
                    self.record("\(self.affected): last committed URL restored", value["address"] as? String == old["lastCommittedURL"] as? String && value["lastCommittedURL"] as? String == old["lastCommittedURL"] as? String)
                    self.record("\(self.affected): reloaded document has a new identity", !self.documentID(value).isEmpty && self.documentID(value) != self.documentID(old))
                    self.record("\(self.affected): own storage survives, other profile markers absent", self.markerOK(value, role: self.affected))
                    self.record("\(self.affected): retired callbacks stay rejected after reload", self.controllers[self.affected]?.recoveryTestRejectStaleCallbacks() == true)
                    self.checkOthers(rows, label: "after reload")
                    if let other = self.roles.first(where: { $0 != self.affected }), let otherController = self.controllers[other] {
                        self.record("\(self.affected): foreign view callbacks cannot mutate this window", self.controllers[self.affected]?.recoveryTestRejectForeignCallbacks(from: otherController) == true)
                    }
                    self.seen.insert(self.affected); self.baseline = rows; self.round += 1
                    if self.seen.count == 3 { self.finish(); return }
                    self.phase = "readyForCrash"; self.writeState()
                }
            default: break
            }
            self.pending = false
        }
    }
    private func checkOthers(_ rows: [String: [String: Any]], label: String) {
        for role in roles where role != affected {
            let value = rows[role] ?? [:]
            record("\(role): unaffected \(label), own marker and document unchanged", loaded(value) && markerOK(value, role: role) && documentID(value) == documentID(baseline[role] ?? [:]))
        }
    }
    private func record(_ label: String, _ passed: Bool) { tests.append(["label": label, "passed": passed]); if !passed { failures.append(label) } }
    private func writeState() {
        Phase3Evidence.write(["runID": runID, "phase": phase, "round": round, "affectedRole": affected, "windowTitle": "Vezham Recovery Test — \(affected)", "hostPID": ProcessInfo.processInfo.processIdentifier, "snapshots": latest, "seenRoles": Array(seen).sorted()], name: "recovery-ui-state-\(runID).json")
    }
    private func finish() {
        guard !finished else { return }; finished = true; timer?.invalidate()
        record("all three profile kinds recovered", seen.count == 3)
        phase = "complete"; writeState()
        Phase3Evidence.write(["runID": runID, "status": failures.isEmpty ? "passed" : "failed", "tests": tests, "failureCount": failures.count, "failures": failures, "recoveredRoles": Array(seen).sorted(), "hostOSVersion": ProcessInfo.processInfo.operatingSystemVersionString, "scope": "Actual prototype windows/toolbar; three targeted content terminations; native test-only callback injection. Synthetic storage only; no durable product history or host-crash restoration claim."], name: "recovery-ui-results-\(runID).json")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in controllers.values.forEach { $0.close() }; completion() }
    }
}

@main
private enum PrototypeMain {
    static func main() {
        Phase3MeasurementClock.processEntry = Phase3MeasurementClock.now
        FileHandle.standardError.write(Data("prototype main entered\n".utf8))
        let app = NSApplication.shared
        FileHandle.standardError.write(Data("NSApplication initialized\n".utf8))
        let delegate = PrototypeApplication()
        app.setActivationPolicy(.regular)
        app.delegate = delegate
        FileHandle.standardError.write(Data("entering AppKit run loop\n".utf8))
        app.run()
    }
}
