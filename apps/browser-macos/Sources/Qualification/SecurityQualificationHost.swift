#if WSF1_QUALIFICATION
import AppKit
import WebKit
import Foundation
import Darwin
import BrowserDomain
import BrowserPorts
import BrowserCore
import BrowserPersistence
import BrowserNativeStorage

@MainActor enum SecurityQualificationHost {
    struct Input: Codable {
        let action: String
        let namespace: UUID
        let profile: ProfileID
        let store: StoreID
        let keyID: UUID
        let origin: String?
        let cacheID: String?
        let checkpoint: StorageQualificationHost.Checkpoint?
        let cutpoint: String?
        let expectKey: Bool?
    }
    struct Case: Codable { let id: String; let status: String; let detail: String }
    struct Output: Codable { let cases: [Case]; let environment: [String:String]; let observations: [String:String]; var checkpoint: StorageQualificationHost.Checkpoint? = nil }
    static func id<T>() -> ID<T> { try! ID(UUID().uuidString) }
    static func emit(_ value: Output) { if let d = try? JSONEncoder().encode(value) { FileHandle.standardOutput.write(d+Data([10])) } }
    static func run() async {
        var cases: [Case] = [], observations: [String:String] = [:]
        var finalCheckpoint: StorageQualificationHost.Checkpoint?
        func add(_ id: String, _ ok: Bool, _ detail: String = "Bounded synthetic native observation") { cases.append(Case(id:id,status:ok ? "PASS_NATIVE":"FAIL",detail:detail)) }
        func blocked(_ id: String,_ detail: String) { cases.append(Case(id:id,status:"BLOCKED",detail:detail)) }
        do {
            let bytes = FileHandle.standardInput.readDataToEndOfFile();guard bytes.count < 65536,
                  Bundle.main.bundleIdentifier == "internal.vezham.browser.wsf1.qualification" else { throw FailureCode.unauthorized }
            let input = try JSONDecoder().decode(Input.self,from:bytes),run:RunID = id()
            if input.action.hasPrefix("keychain") {
                let authority = NativeHostAuthority(),scope = Scope.persistent(input.profile)
                let context = await authority.grant(scope,run:run)
                let broker = NativeKeyBroker(authority:authority,run:run,qualificationNamespace:input.namespace)
                let ref = try NativeKeyReference(profile:input.profile,keyID:input.keyID)
                let foreign = await authority.grant(.persistent(id()),run:run)
                do { _ = try await broker.exists(ref,context:foreign);add("F2-KEY-WRONG-SCOPE",false) }
                catch { cases.append(Case(id:"F2-KEY-WRONG-SCOPE",status:"PASS_CONTRACT",detail:"Adapter denied foreign profile before OS call")) }
                if input.action == "keychain-create" {
                    do { add("F2-KEY-MISSING",try await !broker.exists(ref,context:context)) }
                    catch { blocked("F2-KEY-MISSING",(error as? KeyFailure)?.rawValue ?? "unavailable") }
                    do {
                        try await broker.create(ref,context:context);add("F2-KEY-CREATE",true)
                        do { try await broker.create(ref,context:context);add("F2-KEY-DUPLICATE",false) }
                        catch { add("F2-KEY-DUPLICATE",error as? KeyFailure == .duplicate) }
                    } catch { blocked("F2-KEY-CREATE",(error as? KeyFailure)?.rawValue ?? "unavailable") }
                    observations["createOSStatus"] = broker.lastOSStatus.map(String.init) ?? "not-called"
                }
                if input.action == "keychain-restart" {
                    do {
                        let exists = try await broker.exists(ref,context:context)
                        if input.expectKey == true { add("F2-KEY-RESTART-EXISTS",exists) }
                        else { add("F2-KEY-RESTART-MISSING-CONTROL",!exists);blocked("F2-KEY-RESTART-EXISTS","Creation prerequisite did not succeed; no persisted-key pass") }
                    }
                    catch { blocked("F2-KEY-RESTART-EXISTS",(error as? KeyFailure)?.rawValue ?? "unavailable") }
                }
                do {
                    let lease = try await broker.acquire(ref,context:context,interactive:false)
                    add("F2-KEY-ACQUIRE",await broker.hasActiveLease(input.profile))
                    await broker.revoke(input.profile)
                    add("F2-KEY-REVOKE",!(await broker.hasActiveLease(input.profile)))
                    _ = lease
                } catch { blocked("F2-KEY-ACQUIRE",(error as? KeyFailure)?.rawValue ?? "unavailable") }
                observations["acquireOSStatus"] = broker.lastOSStatus.map(String.init) ?? "not-called"
                if input.action == "keychain-restart" {
                    do { try await broker.remove(ref,context:context);add("F2-KEY-DELETE",true)
                        add("F2-KEY-DELETED-ABSENT",try await !broker.exists(ref,context:context))
                    } catch { blocked("F2-KEY-DELETE",(error as? KeyFailure)?.rawValue ?? "unavailable") }
                    observations["deleteOSStatus"] = broker.lastOSStatus.map(String.init) ?? "not-called"
                }
            } else if input.action == "backup" {
                let recovery = try NativeBackupRecovery(),wrong = try NativeBackupRecovery()
                let history:ResourceID = id(),download:ResourceID = id()
                let records = try [OwnedRecord(id:history,category:.history,payload:Data("SYNTHETIC_HISTORY".utf8)),OwnedRecord(id:download,category:.downloads,payload:Data("EXTERNAL_FILE_METADATA_ONLY".utf8))]
                let snapshot = try OwnedBackupSnapshot(scope:.persistent(input.profile),generation:1,deletionEpoch:1,records:records)
                let archive = try EncryptedOwnedBackup.seal(snapshot,recovery:recovery)
                let reopened = try EncryptedOwnedBackup.open(archive,expected:input.profile,recovery:recovery)
                add("F2-BACKUP-AEAD-ROUNDTRIP",reopened == snapshot)
                add("F2-BACKUP-NONCE-FRESH",try EncryptedOwnedBackup.seal(snapshot,recovery:recovery) != archive)
                for (name,data) in [("TAMPER",Data(archive.dropLast())+Data([archive.last! ^ 1])),("TRUNCATE",Data(archive.dropLast())),("TRAILING",archive+Data([0]))] {
                    do { _ = try EncryptedOwnedBackup.open(data,expected:input.profile,recovery:recovery);add("F2-BACKUP-\(name)",false) }
                    catch { add("F2-BACKUP-\(name)",true) }
                }
                do { _ = try EncryptedOwnedBackup.open(archive,expected:input.profile,recovery:wrong);add("F2-BACKUP-WRONG-RECOVERY",false) }
                catch { add("F2-BACKUP-WRONG-RECOVERY",true) }
                do { _ = try EncryptedOwnedBackup.open(archive,expected:id(),recovery:recovery);add("F2-BACKUP-WRONG-PROFILE",false) }
                catch { add("F2-BACKUP-WRONG-PROFILE",true) }
                let filtered = try reopened.restoring(expectedProfile:input.profile,knowledge:DeletionKnowledge(epoch:2,deleted:[history],complete:true),unknownLineageConfirmed:false,destinationExists:false)
                add("F2-BACKUP-DELETION-FILTER",filtered.map(\.id) == [download])
                do { _ = try reopened.restoring(expectedProfile:input.profile,knowledge:DeletionKnowledge(epoch:1,deleted:[],complete:false),unknownLineageConfirmed:false,destinationExists:false);add("F2-BACKUP-UNKNOWN-LINEAGE",false) }
                catch { add("F2-BACKUP-UNKNOWN-LINEAGE",true) }
                do { _ = try reopened.restoring(expectedProfile:input.profile,knowledge:DeletionKnowledge(epoch:1,deleted:[],complete:true),unknownLineageConfirmed:false,destinationExists:true);add("F2-BACKUP-NO-OVERWRITE",false) }
                catch { add("F2-BACKUP-NO-OVERWRITE",true) }
                do { _ = try OwnedBackupSnapshot(scope:.privateSession(id()),generation:1,deletionEpoch:1,records:records);add("F2-BACKUP-NO-PRIVATE",false) }
                catch { add("F2-BACKUP-NO-PRIVATE",true) }
                let dir = FileManager.default.temporaryDirectory.appendingPathComponent("wsf2-"+UUID().uuidString)
                try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700])
                defer { try? FileManager.default.removeItem(at:dir) } // Exact owned synthetic backup dir only.
                let files = try NativeBackupFiles(directory:dir),archiveID = UUID(),interrupted = UUID()
                try files.publish(archive,id:archiveID)
                add("F2-BACKUP-FILE-ROUNDTRIP",try files.read(archiveID) == archive)
                do { try files.publish(archive,id:archiveID);add("F2-BACKUP-FILE-NO-OVERWRITE",false) }
                catch { add("F2-BACKUP-FILE-NO-OVERWRITE",try files.read(archiveID) == archive) }
                do { try files.publish(archive,id:interrupted,interruptBeforePublish:true);add("F2-BACKUP-INTERRUPTED",false) }
                catch { add("F2-BACKUP-INTERRUPTED",!FileManager.default.fileExists(atPath:dir.appendingPathComponent(interrupted.uuidString.lowercased()+".vxbackup").path)) }
                blocked("F2-BACKUP-PRODUCTION-CATALOG","Actual source snapshot/import and independent recovery custody blocked by protected catalog/key prerequisites; synthetic records only")
            } else {
                guard let origin = input.origin,let url = URL(string:origin),url.scheme == "http",url.host == "127.0.0.1",url.port != nil,
                      let cacheID = input.cacheID,UUID(uuidString:cacheID) != nil else { throw FailureCode.invalidConfiguration }
                let ns = try NamespaceID(input.namespace.uuidString)
                let ports = try StorageQualificationHost.CheckpointPorts(namespace:ns,run:run,checkpoint:input.checkpoint)
                let known = try (input.checkpoint?.rows ?? []).map { try $0.binding(ns) }
                let session = try NativeStorageSession(namespace:ns,run:run,catalog:ports,journal:ports,bindings:known,allowedOrigins:[origin])
                let binding = try ProfileBinding(profile:input.profile,store:input.store,namespace:ns),scope = Scope.persistent(input.profile)
                let context = await session.authority.grant(scope,run:run)
                if input.checkpoint == nil && (input.action == "cache-seed" || input.action.hasPrefix("lock") || input.action == "permission") {
                    guard await session.core.register(binding,context:context,operation:id()) == .success(.registered),await session.core.resolve(scope,context:context,operation:id()) == .success(.resolved) else { throw FailureCode.storeMissing }
                } else {
                    guard await session.core.reconcile(input.profile,context:context,operation:id()) == .success(.reconciled) else { throw FailureCode.reconciliationMismatch }
                }
                if input.action == "lock-restart" {
                    await session.security.register(input.profile,initiallyLocked:true)
                    add("F2-LOCK-RESTART-DEFAULT-FENCED",await session.security.state(input.profile) == .locked)
                    add("F2-LOCK-RESTART-NO-FACTORY",!session.adapter.trace().contains { $0.kind.contains("factory") })
                    blocked("F2-LOCK-DURABLE-RECEIPT","Synthetic checkpoint plus conservative default lock, not persisted protected lock-state qualification")
                    finalCheckpoint = await ports.capture()
                    emit(Output(cases:cases,environment:["macOS":ProcessInfo.processInfo.operatingSystemVersionString],observations:observations,checkpoint:finalCheckpoint))
                    return
                }
                let view:ViewID = id()
                guard await session.open(scope,context:context,view:view,operation:id()) == .success(.activated(view)),await session.adapter.navigate(view,url:URL(string:origin+"/fixture")!) == .completed else { throw FailureCode.activationFailed }
                if input.action.hasPrefix("cache-") {
                    let script = "return JSON.stringify({first:await (await fetch('/cache-probe/\(cacheID)',{cache:'force-cache'})).text(),second:await (await fetch('/cache-probe/\(cacheID)',{cache:'force-cache'})).text()})"
                    if input.action == "cache-selected-clear" || input.action == "cache-full-clear" {
                        let before = try await evaluate(session,view,script)
                        _ = await session.core.closeView(scope,view:view,context:context,operation:id())
                        _ = await session.core.quiesce(scope,context:context,operation:id())
                        let types: Set<WebsiteDataKind> = input.action == "cache-selected-clear" ? [.httpCache] : Set(WebsiteDataKind.allCases)
                        let cleared = await session.core.clear(scope,types:types,context:context,operation:id())
                        add("F2-CACHE-CLEAR-CALLBACK",cleared == .success(.cleared(types)))
                        let replacement:ViewID = id()
                        guard await session.open(scope,context:context,view:replacement,operation:id()) == .success(.activated(replacement)),await session.adapter.navigate(replacement,url:URL(string:origin+"/fixture")!) == .completed else { throw FailureCode.activationFailed }
                        observations = try await evaluate(session,replacement,script)
                        observations["beforeClear"] = before["first"]
                        add("F2-CACHE-CLEAR-POSITIVE-CONTROL",before["first"] != observations["first"])
                        _ = await session.core.closeView(scope,view:replacement,context:context,operation:id())
                    } else {
                        observations = try await evaluate(session,view,script)
                        if input.action == "cache-reconstruct" {
                            let before = observations["first"]
                            _ = await session.core.closeView(scope,view:view,context:context,operation:id())
                            let replacement:ViewID = id()
                            guard await session.open(scope,context:context,view:replacement,operation:id()) == .success(.activated(replacement)),await session.adapter.navigate(replacement,url:URL(string:origin+"/fixture")!) == .completed else { throw FailureCode.activationFailed }
                            observations = try await evaluate(session,replacement,script);observations["beforeReconstruction"] = before
                            add("F2-CACHE-RECONSTRUCTION-POSITIVE",before?.hasPrefix("cache-") == true && observations["first"]?.hasPrefix("cache-") == true)
                            _ = await session.core.closeView(scope,view:replacement,context:context,operation:id())
                        }
                    }
                    add("F2-CACHE-POPULATED",observations["first"]?.hasPrefix("cache-") == true)
                    if input.cutpoint == "cache-active" {
                        let checkpoint = await ports.capture()
                        emit(Output(cases:cases,environment:[:],observations:observations,checkpoint:checkpoint))
                        raise(SIGSTOP)
                    }
                } else if input.action.hasPrefix("lock") {
                    let second:ViewID = id()
                    guard await session.open(scope,context:context,view:second,operation:id()) == .success(.activated(second)) else { throw FailureCode.activationFailed }
                    add("F2-LOCK-MULTIWINDOW",StorageQualificationHost.mountTwoWindows(session,first:view,second:second))
                    let other = try ProfileBinding(profile:id(),store:id(),namespace:ns),otherScope = Scope.persistent(other.profile),otherView:ViewID = id()
                    let otherContext = await session.authority.grant(otherScope,run:run)
                    guard await session.core.register(other,context:otherContext,operation:id()) == .success(.registered),await session.core.resolve(otherScope,context:otherContext,operation:id()) == .success(.resolved),
                          await session.open(otherScope,context:otherContext,view:otherView,operation:id()) == .success(.activated(otherView)),await session.adapter.navigate(otherView,url:URL(string:origin+"/fixture")!) == .completed else { throw FailureCode.activationFailed }
                    await session.security.register(input.profile,initiallyLocked:false)
                    if input.cutpoint == "lock-fence" {
                        session.adapter.eventSink = { event in
                            if event.kind == "security-fence" {
                                self.emit(Output(cases:[],environment:[:],observations:["cutpoint":"lock-fence"]))
                                raise(SIGSTOP)
                            }
                        }
                    }
                    if input.action == "lock-navigation" {
                        let began = NativeQualificationSignal()
                        session.adapter.eventSink = { event in if event.kind == "navigation-request" { began.fire() } }
                        let navigation = Task { await session.adapter.navigate(view,url:URL(string:origin+"/slow")!) }
                        await began.wait()
                        let locked = await session.security.lock(input.profile,cause:.manual)
                        let navigationResult = await navigation.value
                        add("F2-LOCK-DURING-NAVIGATION",navigationResult != .completed && session.adapter.surface(view) == nil)
                        observations["lockDuringNavigationState"] = locked.rawValue
                    }
                    let state = await session.security.lock(input.profile,cause:.manual)
                    add("F2-LOCK-REAL-RESOURCES",state == .locked || (input.action == "lock-navigation" && state == .recoveryRequired))
                    observations["lockState"] = state.rawValue
                    add("F2-LOCK-NO-VIEWS",session.adapter.ownedViews(scope).isEmpty && session.adapter.surface(view) == nil)
                    add("F2-LOCK-NAVIGATION-DENIED",await session.adapter.navigate(view,url:URL(string:origin+"/fixture")!) == .failed(.unauthorized))
                    add("F2-LOCK-NO-KEY-LEASE",!(await session.keys.hasActiveLease(input.profile)))
                    let repeated = await session.security.lock(input.profile,cause:.manual)
                    observations["repeatedLockState"] = repeated.rawValue
                    let noResources = await session.adapter.inventory(scope).isEmpty
                    let noLease = !(await session.keys.hasActiveLease(input.profile))
                    add("F2-LOCK-REPEATED",repeated == state || (repeated == .locked && noResources && noLease))
                    let otherSummary = await session.core.summary(otherScope)
                    add("F2-LOCK-OTHER-PROFILE",session.adapter.surface(otherView) != nil && otherSummary?.state == .active)
                    _ = await session.core.closeView(otherScope,view:otherView,context:otherContext,operation:id())
                    _ = await session.core.quiesce(otherScope,context:otherContext,operation:id());_ = await session.core.retire(otherScope,context:otherContext,operation:id())
                    add("F2-LOCK-OTHER-CLEANUP",await session.core.remove(other.profile,context:otherContext,operation:id()) == .success(.removed))
                    observations["otherProfile"] = other.profile.rawValue;observations["otherStore"] = other.store.rawValue
                    blocked("F2-UNLOCK-PRODUCTION","Real key reacquisition/protected catalog reopen blocked; no automatic OS authentication prompt in qualification")
                } else if input.action == "permission" {
                    emit(Output(cases:[],environment:[:],observations:["phase":"before-media-request"]))
                    observations = try await evaluate(session,view,"const attempt=navigator.mediaDevices.getUserMedia({audio:true}).then(s=>{s.getTracks().forEach(t=>t.stop());return 'unexpected-stream'},e=>e.name);return JSON.stringify({result:await Promise.race([attempt,new Promise(r=>setTimeout(()=>r('timeout'),3000))])})")
                    if observations["result"] == "timeout" { cases.append(Case(id:"F2-PERM-NATIVE-DENIAL",status:"INCONCLUSIVE",detail:"No native/page completion within bounded script deadline")) }
                    else { add("F2-PERM-NATIVE-DENIAL",observations["result"] == "NotAllowedError" || observations["result"] == "SecurityError") }
                    observations["delegateObserved"] = session.adapter.trace().contains { $0.kind == "permission" } ? "yes" : "no"
                    emit(Output(cases:[],environment:[:],observations:["phase":"before-geolocation-request"]))
                    let geo = try await evaluate(session,view,"return JSON.stringify(await new Promise(resolve=>{if(!navigator.geolocation){resolve({result:'unavailable'});return}navigator.geolocation.getCurrentPosition(()=>resolve({result:'unexpected-location'}),()=>resolve({result:'denied'}),{timeout:1000})}))")
                    if geo["result"] == "timeout" || geo["result"] == "unavailable" { cases.append(Case(id:"F2-PERM-GEOLOCATION-DENIAL",status:"INCONCLUSIVE",detail:"No qualified page denial result")) }
                    else { add("F2-PERM-GEOLOCATION-DENIAL",geo["result"] == "denied") }
                    observations["geolocationResult"] = geo["result"]
                    observations["geolocationDelegateObserved"] = session.adapter.trace().contains { $0.kind == "geolocation-permission" } ? "yes" : "no"
                    blocked("F2-PERM-POSITIVE-ASK-ALLOW","Positive native media/Ask path lacks purpose strings/entitlements; policy-only allow tests do not qualify native support")
                }
                if !input.action.hasPrefix("lock") {
                    if session.adapter.surface(view) != nil { _ = await session.core.closeView(scope,view:view,context:context,operation:id()) }
                    _ = await session.core.quiesce(scope,context:context,operation:id())
                    _ = await session.core.retire(scope,context:context,operation:id())
                }
                if input.action == "cache-remove" {
                    add("F2-CACHE-REMOVE",await session.core.remove(input.profile,context:context,operation:id()) == .success(.removed))
                }
                finalCheckpoint = await ports.capture()
            }
        } catch { cases.append(Case(id:"F2-HOST-ERROR",status:"FAIL",detail:(error as? FailureCode)?.rawValue ?? (error as? KeyFailure)?.rawValue ?? "native-operation-failed")) }
        emit(Output(cases:cases,environment:["macOS":ProcessInfo.processInfo.operatingSystemVersionString,"WebKit":Bundle(for:WKWebView.self).infoDictionary?["CFBundleVersion"] as? String ?? "unknown"],observations:observations,checkpoint:finalCheckpoint))
    }
    static func evaluate(_ session:NativeStorageSession,_ view:ViewID,_ script:String) async throws -> [String:String] {
        guard let surface = session.adapter.surface(view) else { throw FailureCode.missingAssignment }
        let reply = BoundedQualificationScript()
        let d:Data? = await withCheckedContinuation { continuation in
            reply.continuation = continuation
            reply.timer = Task { @MainActor in do { try await Task.sleep(for:.seconds(5));reply.finish(nil) } catch {} }
            surface.callAsyncJavaScript(script,arguments:[:],in:nil,in:.page) { result in
                switch result {
                case .success(let value):reply.finish((value as? String)?.data(using:.utf8))
                case .failure:reply.finish(Data("{\"result\":\"script-error\"}".utf8))
                }
            }
        }
        guard let d else { return ["result":"timeout"] }
        guard d.count < 16384 else { throw FailureCode.observationUnknown }
        return try JSONDecoder().decode([String:String].self,from:d)
    }
}
@MainActor private final class NativeQualificationSignal {
    private var fired = false
    private var continuation: CheckedContinuation<Void,Never>?
    func fire() { fired = true;continuation?.resume();continuation = nil }
    func wait() async { if fired { return };await withCheckedContinuation { continuation = $0 } }
}
@MainActor private final class BoundedQualificationScript {
    var continuation: CheckedContinuation<Data?,Never>?
    var timer: Task<Void,Never>?
    func finish(_ data: Data?) { guard let c = continuation else { return };continuation = nil;timer?.cancel();timer = nil;c.resume(returning:data) }
}
#endif
