import Foundation
import Testing
import BrowserDomain
import BrowserPorts
import BrowserCore
import BrowserPersistence
import BrowserNativeStorage
import WSF0Fakes

private func id<T>() -> ID<T> { try! ID(UUID().uuidString) }
@Test("F2-CON-001 protected catalog refuses every operation without provider IO")
func catalogBlocked() async throws {
    let c = ProtectedCatalog(), p: ProfileID = id(), b = try ProfileBinding(profile: p, store: id(), namespace: id())
    #expect(await c.lookup(p) == .unavailable)
    #expect(await c.enumerate().issues.count == 1)
    #expect(await c.insert(b) == .failed(.catalogUnavailable))
    #expect(await c.transition(p, expectedRevision: 1, to: .active) == .failed(.catalogUnavailable))
    #expect(await c.snapshot(run: id()).version == 0)
}
@Test("F2-CON-002 catalog migration plans reject unauthenticated interrupted and future schema")
func migrations() throws {
    #expect(try CatalogSchema.plan(from: 0, authenticated: true, interrupted: false).count == 2)
    #expect(try CatalogSchema.plan(from: 1, authenticated: true, interrupted: false).count == 1)
    #expect(try CatalogSchema.plan(from: 2, authenticated: true, interrupted: false).isEmpty)
    #expect(throws: (any Error).self) { try CatalogSchema.plan(from: 3, authenticated: true, interrupted: false) }
    #expect(throws: (any Error).self) { try CatalogSchema.plan(from: 0, authenticated: false, interrupted: false) }
    #expect(throws: (any Error).self) { try CatalogSchema.plan(from: 1, authenticated: true, interrupted: true) }
    #expect(!CatalogSchema.mayPublish(expectedRevision: 1, actualRevision: 2, journalStable: true, keyAuthenticated: true, engineReady: true))
}
@Test("F2-CON-003 verified origins reject ambiguous identity") func origins() throws {
    for host in ["", "a/b", "a@b", "a b", "a%2fb"] { #expect(throws: (any Error).self) { try VerifiedOrigin(scheme: "https", host: host, port: 443) } }
    #expect(throws: (any Error).self) { try VerifiedOrigin(scheme: "file", host: "localhost", port: 1) }
}
@Test("F2-CON-004 permission Ask allow deny revoke and OS independence")
func permissions() async throws {
    let a = FakeHostAuthority(), run: RunID = id(), scope = Scope.persistent(id())
    let context = await a.grant(id(), scope: scope, run: run), policy = PermissionCoordinator(run: run, authority: a)
    let origin = try VerifiedOrigin(scheme: "https", host: "example.test", port: 443)
    func request(_ kind: PermissionKind = .camera) -> PermissionRequest { PermissionRequest(id: id(), context: context, view: id(), viewGeneration: 1, origin: origin, kind: kind) }
    let e = await policy.evaluate(request(), supported: true, native: .authorized)
    #expect(e.decision == .ask)
    #expect(await policy.decide(e.ticket!, choice: .allow, lifetime: .session, native: .authorized) == .allow)
    #expect(await policy.evaluate(request(), supported: true, native: .authorized).decision == .allow)
    #expect(await policy.evaluate(request(), supported: true, native: .denied).decision == .deny)
    await policy.revoke(scope: scope, origin: origin, kind: .camera)
    let denied = await policy.evaluate(request(), supported: true, native: .authorized)
    #expect(denied.decision == .ask)
    #expect(await policy.decide(denied.ticket!, choice: .deny, lifetime: .once, native: .authorized) == .deny)
    #expect(await policy.evaluate(request(.unknown), supported: true, native: .authorized).decision == .deny)
}
@Test("F2-CON-005 private permission no persistence and lock fences stale prompt")
func privatePermissions() async throws {
    let a = FakeHostAuthority(), run: RunID = id(), scope = Scope.privateSession(id())
    let c = await a.grant(id(), scope: scope, run: run), policy = PermissionCoordinator(run: run, authority: a)
    let origin = try VerifiedOrigin(scheme: "https", host: "example.test", port: 443)
    func req() -> PermissionRequest { PermissionRequest(id: id(), context: c, view: id(), viewGeneration: 1, origin: origin, kind: .microphone) }
    let e = await policy.evaluate(req(), supported: true, native: .authorized)
    #expect(await policy.decide(e.ticket!, choice: .allow, lifetime: .persistent, native: .authorized) == .deny)
    let p = await policy.evaluate(req(), supported: true, native: .authorized)
    await policy.invalidate(scope, lock: true)
    #expect(await policy.decide(p.ticket!, choice: .allow, lifetime: .once, native: .authorized) == .deny)
    #expect(await policy.storedCount(scope) == 0)
    #expect(await policy.evaluate(req(), supported: true, native: .authorized).decision == .deny)
}
private actor SecurityFake: ProfileBarrierPort, ProfileKeyPort, ProfileAuthenticationPort {
    var retired = true; var authenticated = false; var recoverable = false
    var calls: [String] = []; var lease = true
    func configure(retired: Bool, authenticated: Bool, recoverable: Bool) { self.retired = retired; self.authenticated = authenticated; self.recoverable = recoverable }
    func fence(_ profile: ProfileID) { calls.append("fence") }
    func retireResources(_ profile: ProfileID) -> ProviderOutcome { calls.append("retire"); return retired ? .completed : .unknown }
    func reconcileForUnlock(_ profile: ProfileID) -> Bool { recoverable }
    func restoreAdmission(_ profile: ProfileID) { calls.append("admit") }
    func authenticate(_ profile: ProfileID) -> Bool { authenticated }
    func revoke(_ profile: ProfileID) { calls.append("revoke"); lease = false }
    func hasActiveLease(_ profile: ProfileID) -> Bool { lease }
    func trace() -> [String] { calls }
}
@Test("F2-FAKE-001 lock retires keys and resources before Locked; unlock needs auth and recovery")
func lockPolicy() async throws {
    let fake = SecurityFake(), a = FakeHostAuthority(), p: ProfileID = id()
    let permission = PermissionCoordinator(run: id(), authority: a)
    let core = ProfileSecurityCoordinator(barrier: fake, keys: fake, authentication: fake, permissions: permission)
    await core.register(p, initiallyLocked: false)
    #expect(await core.lock(p, cause: .manual) == .locked)
    #expect(await fake.trace() == ["fence", "revoke", "retire"])
    #expect(await core.unlock(p) == .locked)
    await fake.configure(retired: true, authenticated: true, recoverable: false)
    #expect(await core.unlock(p) == .recoveryRequired)
    #expect(await core.lock(p, cause: .manual) == .locked)
    await fake.configure(retired: true, authenticated: true, recoverable: true)
    #expect(await core.unlock(p) == .unlocked)
    await fake.configure(retired: false, authenticated: true, recoverable: true)
    #expect(await core.lock(p, cause: .sleep) == .recoveryRequired)
}
@Test("F2-CON-006 key errors remain distinct and contain no native secret objects")
@MainActor func keyErrors() {
    #expect(NativeKeyBroker.classify(-25300) == .missing)
    #expect(NativeKeyBroker.classify(-25299) == .duplicate)
    #expect(NativeKeyBroker.classify(-25308) == .interactionRequired)
    #expect(NativeKeyBroker.classify(-25293) == .denied)
    #expect(NativeKeyBroker.classify(-34018) == .unavailable)
}
@Test("F2-CON-011 cross-component missing corrupt denied mismatch and interrupted recovery fence")
func recovery() {
    for c in [StorageRecoveryPolicy.Catalog.missing,.corrupt,.futureSchema,.unavailable] {
        #expect(StorageRecoveryPolicy.evaluate(catalog:c,key:.available,engine:.present,intent:.stable,recordedLocked:false,deletionKnowledgeComplete:true) == .recoveryRequired)
    }
    for k in [StorageRecoveryPolicy.Key.missing,.denied,.mismatched,.unavailable] {
        #expect(StorageRecoveryPolicy.evaluate(catalog:.authenticated,key:k,engine:.present,intent:.stable,recordedLocked:false,deletionKnowledgeComplete:true) == .recoveryRequired)
    }
    for i in [StorageRecoveryPolicy.Intent.creation,.publication,.lock,.unlock,.clear,.backup,.restore,.deletion] {
        #expect(StorageRecoveryPolicy.evaluate(catalog:.authenticated,key:.available,engine:.present,intent:i,recordedLocked:false,deletionKnowledgeComplete:true) == .recoveryRequired)
    }
    #expect(StorageRecoveryPolicy.evaluate(catalog:.authenticated,key:.available,engine:.uncertainRemoval,intent:.stable,recordedLocked:false,deletionKnowledgeComplete:true) == .recoveryRequired)
    #expect(StorageRecoveryPolicy.evaluate(catalog:.authenticated,key:.available,engine:.present,intent:.stable,recordedLocked:true,deletionKnowledgeComplete:true) == .preserveLocked)
}
