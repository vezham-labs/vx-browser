import AppKit
import Foundation
import WebKit

enum Phase3MeasurementClock {
    static var processEntry: Double = 0
    static var now: Double { ProcessInfo.processInfo.systemUptime }
}

enum Phase3Evidence {
    static func write(_ result: [String: Any], name: String) {
        do {
            let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("WKPrototype", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: directory.appendingPathComponent(name), options: .atomic)
        } catch {
            FileHandle.standardError.write(Data("phase3 evidence write failed\n".utf8))
        }
    }
}

final class Phase3PerformanceSample: NSObject, WKNavigationDelegate {
    private let runID: String
    private let completion: () -> Void
    private var views: [WKWebView] = []
    private var window: NSWindow?
    private var phase = 0
    private var started = 0.0
    private var pageStarted = 0.0
    private var metrics: [String: Any] = [:]
    private var finished = false

    init(runID: String, completion: @escaping () -> Void) { self.runID = runID; self.completion = completion }

    func start() {
        started = Phase3MeasurementClock.now
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 600), configuration: configuration)
        view.navigationDelegate = self
        views.append(view)
        let host = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
        host.contentView = view
        window = host
        view.loadHTMLString("<!doctype html><title>Engine ready fixture</title><p>ready</p>", baseURL: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) { [weak self] in self?.finish(error: "sample timeout") }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !finished else { return }
        if phase == 0 {
            metrics["engineFirstViewReadyMs"] = (Phase3MeasurementClock.now - started) * 1000
            metrics["processEntryToReadyMs"] = (Phase3MeasurementClock.now - Phase3MeasurementClock.processEntry) * 1000
            phase = 1
            let begin = Phase3MeasurementClock.now
            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = .nonPersistent()
            let page = WKWebView(frame: webView.frame, configuration: configuration)
            metrics["warmEmptyViewConstructorMs"] = (Phase3MeasurementClock.now - begin) * 1000
            page.navigationDelegate = self
            views.append(page)
            window?.contentView = page
            pageStarted = Phase3MeasurementClock.now
            page.load(URLRequest(url: URL(string: "http://127.0.0.1:18765/benchmark-page")!, cachePolicy: .reloadIgnoringLocalCacheData))
        } else {
            metrics["localPageNativeLoadMs"] = (Phase3MeasurementClock.now - pageStarted) * 1000
            webView.evaluateJavaScript("(()=>{const n=performance.getEntriesByType('navigation')[0];return {domMs:n.domContentLoadedEventEnd-n.startTime,encodedBodyBytes:n.encodedBodySize}})()") { [weak self] value, error in
                guard let self, !self.finished else { return }
                if let value = value as? [String: Any], error == nil {
                    self.metrics["localPageDOMReadyMs"] = value["domMs"]
                    self.metrics["encodedBodyBytes"] = value["encodedBodyBytes"]
                    self.finish(error: nil)
                } else { self.finish(error: "navigation timing unavailable") }
            }
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { finish(error: "fixture navigation failed: \((error as NSError).code)") }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { finish(error: "fixture navigation failed: \((error as NSError).code)") }

    private func finish(error: String?) {
        guard !finished else { return }; finished = true
        Phase3Evidence.write(["mode": "performance-sample", "runID": runID, "status": error == nil ? "observed" : "failed", "error": error as Any? ?? NSNull(), "metrics": metrics, "hostOSVersion": ProcessInfo.processInfo.operatingSystemVersionString, "method": "Fresh app process, hidden AppKit host window; WebKit plus first view to ready; warm view constructor; same-origin Navigation Timing for exact 1 MB HTTP fixture. OS caches are not flushed."], name: "performance-sample-\(runID).json")
        views.forEach { $0.stopLoading(); $0.navigationDelegate = nil }
        completion()
    }
}

final class Phase3IdleViews: NSObject, WKNavigationDelegate {
    private let runID: String
    private let completion: () -> Void
    private var views: [WKWebView] = []
    private var windows: [NSWindow] = []
    private var loaded = Set<ObjectIdentifier>()
    private var ready = false
    private var finished = false
    private var idleStarted = 0.0
    // Test-only collection grace; default behavior is unchanged for existing runners.
    private var reportingGraceSeconds: Double {
        guard let index = CommandLine.arguments.firstIndex(of: "--test-idle-report-grace-seconds"),
              CommandLine.arguments.indices.contains(index + 1),
              let seconds = Double(CommandLine.arguments[index + 1]), seconds.isFinite else { return 3 }
        return min(60, max(3, seconds))
    }
    init(runID: String, completion: @escaping () -> Void) { self.runID = runID; self.completion = completion }

    func start() {
        let store = WKWebsiteDataStore.nonPersistent()
        for _ in 0..<10 {
            let config = WKWebViewConfiguration(); config.websiteDataStore = store
            let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 600), configuration: config)
            view.navigationDelegate = self
            let host = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
            host.contentView = view
            views.append(view); windows.append(host)
            view.load(URLRequest(url: URL(string: "http://127.0.0.1:18765/benchmark-page")!, cachePolicy: .reloadIgnoringLocalCacheData))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 690) { [weak self] in self?.finish(error: "idle harness timeout") }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !finished else { return }
        loaded.insert(ObjectIdentifier(webView))
        if loaded.count == 10 && !ready {
            ready = true; idleStarted = Phase3MeasurementClock.now
            Phase3Evidence.write(["mode": "idle-ready", "viewCount": loaded.count, "hostPID": ProcessInfo.processInfo.processIdentifier, "idleStartedSystemUptime": idleStarted, "reportingGraceSeconds": reportingGraceSeconds], name: "idle-ready-\(runID).json")
            DispatchQueue.main.asyncAfter(deadline: .now() + 600) { [weak self] in self?.finish(error: nil) }
        }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { finish(error: "idle fixture load failed") }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { finish(error: "idle content process terminated") }
    private func finish(error: String?) {
        guard !finished else { return }; finished = true
        Phase3Evidence.write(["mode": "ten-idle-views", "runID": runID, "status": error == nil ? "observed" : "failed", "error": error as Any? ?? NSNull(), "loadedViewCount": loaded.count, "idleSeconds": ready ? Phase3MeasurementClock.now - idleStarted : 0, "hostPID": ProcessInfo.processInfo.processIdentifier, "reportingGraceSeconds": reportingGraceSeconds, "engineProcessAttribution": "External runner required; the app does not query WebKit helper PIDs."], name: "performance-idle-\(runID).json")
        DispatchQueue.main.asyncAfter(deadline: .now() + reportingGraceSeconds) { [weak self] in self?.completion() }
    }
}

final class Phase3PublicSites: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let runID: String
    private let completion: () -> Void
    private let sites = [("Google Workspace", "https://workspace.google.com/"), ("Microsoft 365", "https://www.microsoft365.com/"), ("GitHub", "https://github.com/"), ("Figma", "https://www.figma.com/"), ("Notion", "https://www.notion.com/"), ("Payment documentation", "https://docs.stripe.com/testing"), ("Conferencing landing", "https://meet.jit.si/")]
    private var index = 0
    private var view: WKWebView?
    private var window: NSWindow?
    private var observations: [[String: Any]] = []
    private var generation = 0
    private var httpStatus = 0
    private var finished = false
    private var responseRecorded = false
    init(runID: String, completion: @escaping () -> Void) { self.runID = runID; self.completion = completion }
    func start() { next() }

    private func next() {
        view?.stopLoading(); view?.navigationDelegate = nil; view?.uiDelegate = nil
        if index == sites.count * 3 {
            finished = true
            Phase3Evidence.write(["mode": "public-site-smoke", "runID": runID, "status": observations.allSatisfy { $0["status"] as? String == "loaded" } ? "observed" : "partially_verified", "observations": observations, "scope": "Three fresh nonpersistent stores per public landing page; no sign-in, test tenant, payment, conference room, or account workflow. Not full compatibility acceptance."], name: "public-sites-results-\(runID).json")
            completion(); return
        }
        generation += 1; let token = generation; httpStatus = 0; responseRecorded = false
        let config = WKWebViewConfiguration(); config.websiteDataStore = .nonPersistent()
        let page = WKWebView(frame: NSRect(x: 0, y: 0, width: 1000, height: 700), configuration: config)
        page.navigationDelegate = self; page.uiDelegate = self; view = page
        if window == nil { window = NSWindow(contentRect: page.frame, styleMask: .borderless, backing: .buffered, defer: false) }
        window?.contentView = page
        page.load(URLRequest(url: URL(string: sites[index % sites.count].1)!))
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            guard let self, !self.finished, self.generation == token else { return }
            self.record(status: "blocked", errorCode: "timeout", bridgeAbsent: nil)
        }
    }
    private func record(status: String, errorCode: String?, bridgeAbsent: Bool?) {
        guard !finished, !responseRecorded else { return }; responseRecorded = true
        let item = sites[index % sites.count]
        observations.append(["site": item.0, "requestedURL": item.1, "repetition": index / sites.count + 1, "status": status, "httpStatus": httpStatus, "finalHost": view?.url?.host ?? "", "title": view?.title ?? "", "error": errorCode as Any? ?? NSNull(), "bridgeAbsent": bridgeAbsent as Any? ?? NSNull()])
        FileHandle.standardError.write(Data("public site \(observations.count)/\(sites.count * 3): \(item.0) \(status)\n".utf8))
        generation += 1; index += 1
        DispatchQueue.main.async { [weak self] in self?.next() }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView === view else { return }
        let token = generation
        let title = (webView.title ?? "").lowercased()
        let loaded = (200..<400).contains(httpStatus) && !title.isEmpty && !["access denied", "just a moment", "captcha", "forbidden"].contains(where: title.contains)
        webView.evaluateJavaScript("!window.webkit || !window.webkit.messageHandlers || !window.webkit.messageHandlers.vezham") { [weak self] value, _ in
            guard let self, self.generation == token else { return }
            self.record(status: loaded ? "loaded" : "blocked", errorCode: loaded ? nil : "HTTP or challenge page", bridgeAbsent: value as? Bool)
        }
    }
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if response.isForMainFrame { httpStatus = (response.response as? HTTPURLResponse)?.statusCode ?? 0 }
        decisionHandler(response.canShowMIMEType ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(action.targetFrame != nil && action.request.url?.scheme == "https" ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard webView === view else { return }; record(status: "blocked", errorCode: String((error as NSError).code), bridgeAbsent: nil)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard webView === view else { return }; record(status: "blocked", errorCode: String((error as NSError).code), bridgeAbsent: nil)
    }
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) { decisionHandler(.deny) }
}
