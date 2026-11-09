import Foundation
import AppKit
import WebKit
import BrowserDomain
import BrowserPorts

@MainActor private final class WeakObject {
    weak var value: AnyObject?
    let resource: ResourceReference
    init(_ value: AnyObject, kind: ResourceKind = .participant) {
        self.value = value
        resource = ResourceReference(id: try! ResourceID(UUID().uuidString), kind: kind)
    }
}
private enum Reply<T: Sendable>: Sendable { case value(T), timedOut }
@MainActor private final class Once<T: Sendable> {
    var continuation: CheckedContinuation<Reply<T>, Never>?
    var timeout: Task<Void, Never>?
    func finish(_ value: Reply<T>) {
        guard let c = continuation else { return }
        continuation = nil; timeout?.cancel(); timeout = nil; c.resume(returning: value)
    }
}

/// Public WebKit implementation of the existing ports. No database/file/Keychain access.
/// Native objects never cross BrowserPorts. This same module is linked by the AppKit app.
@MainActor public final class NativeWebKitStorage: NSObject, EngineStoragePort, ViewConstructionPort, ResourcePort, WKNavigationDelegate, WKUIDelegate {
    private struct Store {
        let identity: StoreIdentity
        var object: WKWebsiteDataStore?
        var retired = false
    }
    private struct View {
        let identity: StoreIdentity
        let generation: UInt64
        let operation: OperationID
        let object: WKWebView
        let configuration: WKWebViewConfiguration
        var descriptor: StorageDescriptor
        var published = false
        var permissionDocument = UUID()
        var navigationFailed = false
        var requestedURL: URL?
    }
    public struct Event: Codable, Sendable {
        public let sequence: Int
        public let kind: String
        public let outcome: String
    }
    private let namespace: NamespaceID
    private let allowedOrigins: Set<String>
    private let interactivePrivateBrowsing: Bool
    private var bindings: [StoreID: ProfileBinding] = [:]
    private var stores: [Scope: Store] = [:]
    private var views: [ViewID: View] = [:]
    private var fenced: Set<Scope> = []
    private var poisoned: Set<Scope> = []
    private var securityLocked: Set<Scope> = []
    public var permissionMediator: NativePermissionMediator?
    public func ownedViews(_ scope: Scope) -> [ViewID] { views.filter { $0.value.identity.scope == scope }.map(\.key) }
    public func securityFence(_ profile: ProfileID) {
        let scope = Scope.persistent(profile); securityLocked.insert(scope); fenced.insert(scope)
        for v in views.values where v.identity.scope == scope {
            v.object.stopLoading(); navigations.removeValue(forKey: ObjectIdentifier(v.object))?(false)
        }
        record("security-fence", "installed")
    }
    func restoreSecurityAdmission(_ profile: ProfileID) { securityLocked.remove(.persistent(profile)) }
    private var pending: [Scope: Set<ResourceReference>] = [:]
    private var released: [Scope: [WeakObject]] = [:]
    private var navigations: [ObjectIdentifier: (@MainActor @Sendable (Bool) -> Void)] = [:]
    private var events: [Event] = []
    private var overflowed = false
    private var frameworkReady = false
    public var eventSink: (@MainActor @Sendable (Event) -> Void)?
    public init(namespace: NamespaceID, knownBindings: [ProfileBinding] = [], allowedOrigins: Set<String> = [], interactivePrivateBrowsing: Bool = false) throws {
        self.namespace = namespace; self.allowedOrigins = allowedOrigins
        self.interactivePrivateBrowsing = interactivePrivateBrowsing
        for b in knownBindings {
            guard b.namespace == namespace, bindings[b.store] == nil,
                  !bindings.values.contains(where: { $0.profile == b.profile }) else { throw FailureCode.conflictingMapping }
            bindings[b.store] = b
        }
        super.init()
    }
    public func trace() -> [Event] { events }
    private func record(_ kind: String, _ outcome: String) {
        guard events.count < 4096 else { overflowed = true; return }
        let event = Event(sequence: events.count + 1, kind: kind, outcome: outcome)
        events.append(event); eventSink?(event)
    }
    private func wait<T: Sendable>(timeout: Duration = .seconds(15), _ invoke: (@escaping @MainActor @Sendable (T) -> Void) -> Void) async -> Reply<T> {
        let once = Once<T>()
        return await withCheckedContinuation { continuation in
            once.continuation = continuation
            once.timeout = Task { @MainActor in
                do { try await Task.sleep(for: timeout); once.finish(.timedOut) } catch {}
            }
            invoke { value in once.finish(.value(value)) }
        }
    }
    public func identifiers() async -> Set<UUID>? {
        if !frameworkReady {
            // Public object initialization before a cold class-only enumeration. The
            // upstream API::Object constructor initializes WebKit. Never inspect this
            // configuration's unset store, construct a view, or instantiate a default store.
            let configuration = WKWebViewConfiguration()
            withExtendedLifetime(configuration) {}
            frameworkReady = true
            record("framework-configuration", "public-init-no-store-getter")
        }
        let result: Reply<[UUID]> = await wait { completion in
            WKWebsiteDataStore.fetchAllDataStoreIdentifiers { completion($0) }
        }
        switch result {
        case .value(let ids): record("enumeration", "observed"); return Set(ids)
        case .timedOut: record("enumeration", "unknown"); return nil
        }
    }
    public func observe(_ store: StoreID) async -> Resolution {
        guard !overflowed, let ids = await identifiers() else { return .unknown }
        guard ids.contains(UUID(uuidString: store.rawValue)!) else { return .missing }
        guard let b = bindings[store], b.namespace == namespace,
              ![.deleting, .deleted, .quarantined].contains(b.status) else { return .conflicting }
        let identity = StoreIdentity.persistent(profile: b.profile, store: store, namespace: namespace, generation: b.resourceGeneration)
        // Noncreating observation only. Reopening happens later under construction admission.
        if stores[identity.scope] == nil { stores[identity.scope] = Store(identity: identity, object: nil) }
        return .assigned(identity)
    }
    public func createPersistent(_ binding: ProfileBinding) async -> Resolution {
        guard !overflowed, stores.count < 128, binding.namespace == namespace,
              binding.origin == .fresh, binding.status == .registered,
              stores[.persistent(binding.profile)] == nil,
              bindings[binding.store] == nil,
              !bindings.values.contains(where: { $0.profile == binding.profile }),
              let ids = await identifiers() else { return .invalid }
        guard !ids.contains(UUID(uuidString: binding.store.rawValue)!) else { return .conflicting }
        let identity = StoreIdentity.persistent(profile: binding.profile, store: binding.store, namespace: namespace, generation: binding.resourceGeneration)
        let object = WKWebsiteDataStore(forIdentifier: UUID(uuidString: binding.store.rawValue)!)
        guard object.isPersistent, object.identifier == UUID(uuidString: binding.store.rawValue) else { return .invalid }
        bindings[binding.store] = binding; stores[identity.scope] = Store(identity: identity, object: object)
        record("persistent-factory", "explicit"); return .assigned(identity)
    }
    public func createPrivate(_ session: PrivateSessionID) async -> Resolution {
        let scope = Scope.privateSession(session)
        guard !overflowed, stores.count < 128, stores[scope] == nil else { return .invalid }
        let object = WKWebsiteDataStore.nonPersistent()
        guard !object.isPersistent, object.identifier == nil else { return .invalid }
        let identity = StoreIdentity.ephemeral(session: session, store: try! EphemeralStoreID(UUID().uuidString), generation: 1)
        stores[scope] = Store(identity: identity, object: object)
        record("private-factory", "nonpersistent"); return .assigned(identity)
    }
    public func validates(_ identity: StoreIdentity) async -> Bool {
        guard let s = stores[identity.scope], s.identity == identity, !s.retired else { return false }
        if let object = s.object { return matches(object, identity) }
        guard case .persistent(_, let store, _, _) = identity, let ids = await identifiers() else { return false }
        return ids.contains(UUID(uuidString: store.rawValue)!)
    }
    private func now() -> UInt64 { UInt64(max(1, Date().timeIntervalSince1970 * 1000)) }
    private func matches(_ store: WKWebsiteDataStore, _ identity: StoreIdentity) -> Bool {
        switch identity {
        case .persistent(_, let id, let ns, _): return ns == namespace && store.isPersistent && store.identifier == UUID(uuidString: id.rawValue)
        case .ephemeral: return !store.isPersistent && store.identifier == nil && stores[identity.scope]?.object === store
        }
    }
    public func construct(_ identity: StoreIdentity, view: ViewID, generation: UInt64, operation: OperationID) async -> ConstructionOutcome {
        guard !overflowed, !fenced.contains(identity.scope), views.count < 128, views[view] == nil,
              await validates(identity), !fenced.contains(identity.scope), var s = stores[identity.scope] else { return .failed(.missingAssignment) }
        if s.object == nil {
            guard case .persistent(_, let id, _, _) = identity, let ids = await identifiers(),
                  !fenced.contains(identity.scope), ids.contains(UUID(uuidString: id.rawValue)!) else { return .failed(.storeMissing) }
            s.object = WKWebsiteDataStore(forIdentifier: UUID(uuidString: id.rawValue)!)
            stores[identity.scope] = s; record("existing-factory", "observed-first")
        }
        guard let object = s.object, matches(object, identity) else { return .failed(.invalidStoreIdentity) }
        do {
            var d: StorageDescriptor
            switch identity {
            case .persistent(let p, let st, _, _): d = try StorageDescriptor(namespace: namespace, profile: p, store: st, generation: generation, operation: operation, timestamp: now())
            case .ephemeral(let session, _, _): d = try StorageDescriptor(namespace: namespace, session: session, generation: generation, operation: operation, timestamp: now())
            }
            try d.advance(to: .resolved, operation: operation, timestamp: now())
            try d.advance(to: .registered, operation: operation, timestamp: now())
            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = object
            guard matches(configuration.websiteDataStore, identity) else { return .failed(.invalidStoreIdentity) }
            try d.advance(to: .configured, operation: operation, timestamp: now())
            record("assignment", "verified-before-construction")
            let native = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), configuration: configuration)
            guard matches(native.configuration.websiteDataStore, identity) else { return .failed(.constructionFailed) }
            native.navigationDelegate = self; native.uiDelegate = self
            try d.advance(to: .constructed, operation: operation, timestamp: now())
            views[view] = View(identity: identity, generation: generation, operation: operation, object: native, configuration: configuration, descriptor: d)
            record("construction", "unpublished"); return .constructed
        } catch { return .failed(.constructionFailed) }
    }
    public func activate(_ identity: StoreIdentity) async -> ProviderOutcome {
        guard !fenced.contains(identity.scope), await validates(identity) else { return .failed(.activationFailed) }
        return .completed // Does not publish or navigate; host must confirm Core's terminal result first.
    }
    public func publicationMatches(_ view: ViewID, scope: Scope, generation: UInt64, operation: OperationID) -> Bool {
        guard let v = views[view] else { return false }
        return v.published && v.identity.scope == scope && v.generation == generation && v.operation == operation && !fenced.contains(scope)
    }
    public func publish(_ view: ViewID, scope: Scope, generation: UInt64, operation: OperationID) throws {
        guard !overflowed, !fenced.contains(scope), var v = views[view], v.identity.scope == scope,
              v.generation == generation, v.operation == operation else { throw FailureCode.staleCompletion }
        if v.published { return }
        try v.descriptor.advance(to: .published, operation: v.operation, timestamp: now())
        v.published = true; views[view] = v; record("publication", "host-confirmed")
    }
    public func surface(_ view: ViewID) -> WKWebView? {
        guard let v = views[view], v.published, !fenced.contains(v.identity.scope) else { return nil }
        return v.object
    }
    public func navigate(_ view: ViewID, url: URL) async -> ProviderOutcome {
        guard var v = views[view], v.published, !fenced.contains(v.identity.scope), permitted(url),
              navigations[ObjectIdentifier(v.object)] == nil else { return .failed(.unauthorized) }
        do { try v.descriptor.advance(to: .navigationAuthorized, operation: v.operation, timestamp: now()) }
        catch { return .failed(.illegalTransition) }
        views[view] = v
        let key = ObjectIdentifier(v.object)
        let r: Reply<Bool> = await wait { done in
            navigations[key] = done
            v.object.load(URLRequest(url: url))
            record("navigation-request", "issued")
        }
        guard !fenced.contains(v.identity.scope), views[view]?.generation == v.generation else { return .unknown }
        if case .value(true) = r { record("navigation", "finished"); return .completed }
        record("navigation", "unknown-or-failed"); return .unknown
    }
    public enum InteractiveNavigation {
        case load(URL), back, forward, reload, stop
    }
    public func perform(_ command: InteractiveNavigation, in view: ViewID) -> Bool {
        guard interactivePrivateBrowsing, var entry = views[view], entry.identity.scope.profile == nil,
              entry.published, !fenced.contains(entry.identity.scope) else { return false }
        let surface = entry.object
        switch command {
        case .load(let url):
            guard permitted(url, scope: entry.identity.scope) else { return false }
            if entry.descriptor.phase == .published {
                do { try entry.descriptor.advance(to: .navigationAuthorized, operation: entry.operation, timestamp: now()) }
                catch { return false }
            }
            guard entry.descriptor.phase == .navigationAuthorized else { return false }
            entry.navigationFailed = false
            entry.requestedURL = url
            views[view] = entry
            return surface.load(URLRequest(url: url)) != nil
        case .back: return surface.canGoBack && surface.goBack() != nil
        case .forward: return surface.canGoForward && surface.goForward() != nil
        case .reload:
            if entry.navigationFailed, let url = entry.requestedURL { return perform(.load(url), in: view) }
            return surface.reload() != nil
        case .stop: surface.stopLoading(); return true
        }
    }
    public func requestedURL(in view: ViewID) -> URL? { views[view]?.requestedURL }
    public func navigationFailed(in view: ViewID) -> Bool { views[view]?.navigationFailed ?? false }
    private func permitted(_ url: URL, scope: Scope? = nil) -> Bool {
        guard let scheme = url.scheme, ["http", "https"].contains(scheme), let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil else { return false }
        if interactivePrivateBrowsing, let scope, case .privateSession = scope {
            return scheme == "https" || ["localhost", "127.0.0.1", "[::1]", "::1"].contains(host)
        }
        let port = url.port.map { ":\($0)" } ?? ""
        return allowedOrigins.contains("\(scheme)://\(host)\(port)")
    }
    public func inventory(_ scope: Scope) async -> Set<ResourceReference> {
        released[scope] = (released[scope] ?? []).filter { $0.value != nil }
        var refs = Set((released[scope] ?? []).map(\.resource))
        refs.formUnion(pending[scope] ?? [])
        for (id, v) in views where v.identity.scope == scope {
            refs.insert(ResourceReference(id: try! ResourceID(id.rawValue), kind: .view))
        }
        return refs
    }
    public func preventAcquisition(in scope: Scope) async { fenced.insert(scope); record("fence", "installed") }
    public func allowAcquisition(in scope: Scope) async {
        if !overflowed && !poisoned.contains(scope) && !securityLocked.contains(scope) { fenced.remove(scope) }
    }
    private func dispose(_ view: ViewID, scope: Scope) -> Bool {
        guard let v = views[view], v.identity.scope == scope else { return false }
        released[scope, default: []].append(WeakObject(v.object, kind: .view))
        released[scope, default: []].append(WeakObject(v.configuration))
        let key = ObjectIdentifier(v.object)
        navigations.removeValue(forKey: key)?(false)
        v.object.stopLoading(); v.object.navigationDelegate = nil; v.object.uiDelegate = nil
        v.object.removeFromSuperview(); views.removeValue(forKey: view)
        return true
    }
    public func close(_ view: ViewID, scope: Scope) async -> ProviderOutcome {
        guard dispose(view, scope: scope) else { return .failed(.invalidIdentity) }
        record("close", "released-owned-references"); return .completed
    }
    public func quiesce(_ scope: Scope) async -> ProviderOutcome {
        fenced.insert(scope)
        guard await inventory(scope).isEmpty else { return .failed(.outstandingReferences) }
        record("quiesce", "no-observed-owned-resources"); return .completed
    }
    private func dropStore(_ scope: Scope) {
        if let object = stores[scope]?.object { released[scope, default: []].append(WeakObject(object)) }
        stores[scope]?.object = nil; stores[scope]?.retired = true
    }
    public func retire(_ scope: Scope) async -> ProviderOutcome {
        fenced.insert(scope)
        guard stores[scope] != nil else { return .failed(.invalidStoreIdentity) }
        guard await inventory(scope).isEmpty else { return .failed(.outstandingReferences) }
        if case .privateSession = scope {
            // Closing a private lifecycle means discarding its website state as well as
            // owned views. Clear the explicit supported categories (including workers)
            // before observing wrapper retirement; never purge another scope.
            guard let identity = stores[scope]?.identity else { return .failed(.invalidStoreIdentity) }
            let purged = await clear(identity, types: Set(WebsiteDataKind.allCases))
            guard purged == .completed else { record("private-retirement-purge", "incomplete"); return purged }
            record("private-retirement-purge", "callback-and-records-empty")
        }
        dropStore(scope)
        // WebKit may release its wrapper on a later main-run-loop turn. Wait for an
        // observable weak-reference postcondition, never assume a fixed sleep proves it.
        let deadline = ContinuousClock.now.advanced(by: .seconds(15))
        if !(await inventory(scope)).isEmpty { record("retire-wait", "observed-reference-present") }
        while !(await inventory(scope)).isEmpty {
            guard ContinuousClock.now < deadline, !Task.isCancelled else {
                record("retire", "reference-deadline-blocked"); return .failed(.outstandingReferences)
            }
            do { try await Task.sleep(for: .milliseconds(20)) }
            catch { return .unknown }
        }
        record("retire", "weak-observation-clear"); return .completed
    }
    private func nativeTypes(_ types: Set<WebsiteDataKind>) -> Set<String> {
        Set(types.flatMap { kind -> [String] in
            switch kind {
            case .cookies: return [WKWebsiteDataTypeCookies]
            case .localStorage: return [WKWebsiteDataTypeLocalStorage]
            case .indexedDB: return [WKWebsiteDataTypeIndexedDBDatabases]
            case .sessionStorage: return [WKWebsiteDataTypeSessionStorage]
            case .cacheStorage: return [WKWebsiteDataTypeFetchCache]
            case .httpCache: return [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]
            case .serviceWorkers: return [WKWebsiteDataTypeServiceWorkerRegistrations]
            }
        })
    }
    public func clear(_ identity: StoreIdentity, types: Set<WebsiteDataKind>) async -> ProviderOutcome {
        let scope = identity.scope
        guard !types.isEmpty, fenced.contains(scope), await inventory(scope).isEmpty,
              let object = stores[scope]?.object, matches(object, identity) else { return .failed(.clearFailed) }
        let reference = ResourceReference(id: try! ResourceID(UUID().uuidString), kind: .pendingOperation)
        pending[scope, default: []].insert(reference)
        let kinds = nativeTypes(types)
        record("clear-request", "before-call")
        let reply: Reply<Bool> = await wait { done in
            object.removeData(ofTypes: kinds, modifiedSince: .distantPast) { [self] in
                record("clear-callback", "received-no-error-channel"); done(true)
            }
        }
        guard case .value = reply else { record("clear", "unknown"); return .unknown }
        let verification: Reply<Bool> = await wait { done in
            object.fetchDataRecords(ofTypes: kinds) { [self] records in
                pending[scope]?.remove(reference); done(records.isEmpty)
            }
        }
        switch verification {
        case .value(true): record("clear", "callback-and-records-empty"); return .completed
        case .value(false): record("clear", "residual-records"); return .partial
        case .timedOut: return .unknown
        }
    }
    public func remove(_ identity: StoreIdentity) async -> ProviderOutcome {
        let scope = identity.scope
        guard case .persistent(_, let id, _, _) = identity, fenced.contains(scope),
              stores[scope]?.identity == identity, stores[scope]?.retired == true,
              stores[scope]?.object == nil, await inventory(scope).isEmpty else { return .failed(.outstandingReferences) }
        let reference = ResourceReference(id: try! ResourceID(UUID().uuidString), kind: .pendingOperation)
        pending[scope, default: []].insert(reference); record("remove-request", "before-call")
        let result: Reply<Bool> = await wait { done in
            WKWebsiteDataStore.remove(forIdentifier: UUID(uuidString: id.rawValue)!) { [self] error in
                pending[scope]?.remove(reference); record("remove-callback", error == nil ? "no-error" : "error-partial-possible"); done(error == nil)
            }
        }
        guard case .value(let success) = result else { return .unknown }
        guard success else { return .partial }
        guard let ids = await identifiers() else { return .unknown }
        guard !ids.contains(UUID(uuidString: id.rawValue)!) else { return .partial }
        record("remove", "callback-and-absence"); return .completed
    }
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let id = views.first(where: { $0.value.object === webView })?.key { views[id]?.navigationFailed = false }
    }
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { navigations.removeValue(forKey: ObjectIdentifier(webView))?(true) }
    private func navigationFailure(_ webView: WKWebView, error: any Error) {
        if (error as? URLError)?.code != .cancelled,
           let id = views.first(where: { $0.value.object === webView })?.key {
            views[id]?.navigationFailed = true
        }
        navigations.removeValue(forKey: ObjectIdentifier(webView))?(false)
    }
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) { navigationFailure(webView, error: error) }
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) { navigationFailure(webView, error: error) }
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if let v = views.values.first(where: { $0.object === webView }) {
            fenced.insert(v.identity.scope); poisoned.insert(v.identity.scope)
        }
        navigations.removeValue(forKey: ObjectIdentifier(webView))?(false); record("content-process", "terminated-fenced")
    }
    public func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        guard let pair = views.first(where: { $0.value.object === webView }), pair.value.published,
              !fenced.contains(pair.value.identity.scope), action.request.url.map({ permitted($0, scope: pair.value.identity.scope) }) == true else {
            decisionHandler(.cancel)
            return
        }
        if action.targetFrame?.isMainFrame == true {
            views[pair.key]?.permissionDocument = UUID()
            if interactivePrivateBrowsing, pair.value.identity.scope.profile == nil {
                views[pair.key]?.requestedURL = action.request.httpMethod == "GET" ? action.request.url : nil
            }
        }
        decisionHandler(.allow)
    }
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? { nil }
    public func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse, decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void) {
        let owned = views.values.contains { $0.object === webView && $0.published && !fenced.contains($0.identity.scope) }
        decisionHandler(owned && response.canShowMIMEType ? .allow : .cancel)
    }
    public func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor @Sendable ([URL]?) -> Void) { completionHandler(nil) }
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor @Sendable () -> Void) { completionHandler() }
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor @Sendable (Bool) -> Void) { completionHandler(false) }
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor @Sendable (String?) -> Void) { completionHandler(nil) }
    public func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping @MainActor @Sendable (WKPermissionDecision) -> Void) {
        record("permission", "delegate-entered")
        guard let pair = views.first(where: { $0.value.object === webView }), pair.value.published,
              !fenced.contains(pair.value.identity.scope), frame.isMainFrame,
              let url = webView.url, url.host == origin.host, url.scheme == origin.protocol,
              let verified = try? VerifiedOrigin(scheme: origin.protocol, host: origin.host, port: origin.port == 0 ? (origin.protocol == "https" ? 443 : 80) : origin.port),
              let port = UInt16(exactly: url.port ?? (url.scheme == "https" ? 443 : 80)),
              verified.port == port, let mediator = permissionMediator else {
            record("permission", "denied-unverified-context")
            decisionHandler(.deny)
            return
        }
        let kind: PermissionKind
        switch type {
        case .camera: kind = .camera
        case .microphone: kind = .microphone
        case .cameraAndMicrophone: kind = .cameraAndMicrophone
        @unknown default:
            record("permission", "denied-unsupported")
            decisionHandler(.deny)
            return
        }
        let id = pair.key, generation = pair.value.generation, scope = pair.value.identity.scope
        let document = pair.value.permissionDocument
        Task { @MainActor [weak self, weak webView] in
            guard let self, let webView else { decisionHandler(.deny); return }
            let decision = await mediator.request(scope: scope, view: id, generation: generation, origin: verified, kind: kind, surface: webView) { [weak self, weak webView] in
                self?.views[id]?.generation == generation && self?.views[id]?.published == true &&
                    self?.views[id]?.permissionDocument == document && self?.fenced.contains(scope) == false &&
                    webView?.url == url
            }
            self.record("permission", decision == .grant ? "granted-scoped" : "denied-closed")
            decisionHandler(decision)
        }
    }
    @available(macOS 27.0, *)
    public func webView(_ webView: WKWebView, requestGeolocationPermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping @MainActor @Sendable (WKPermissionDecision) -> Void) {
        record("geolocation-permission", "denied-unsupported");decisionHandler(.deny)
    }
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping @MainActor @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let livePrivate = interactivePrivateBrowsing && views.values.contains {
            $0.object === webView && $0.identity.scope.profile == nil && $0.published && !fenced.contains($0.identity.scope)
        }
        let normalTrust = livePrivate && challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
        completionHandler(normalTrust ? .performDefaultHandling : .cancelAuthenticationChallenge, nil)
    }
}
