import Foundation
import Testing
import BrowserDomain
import BrowserNativeStorage

private func fresh<T>() -> ID<T> { try! ID(UUID().uuidString) }
@Test("F1-GUARD-001 host grants are scoped current and revocable")
func authority() async {
    let a = NativeHostAuthority(), run: RunID = fresh(), scope = Scope.persistent(fresh())
    let c = await a.grant(scope, run: run)
    #expect(await a.permits(c, scope: scope, run: run))
    #expect(await a.permits(c, scope: .persistent(fresh()), run: run) == false)
    await a.revoke(scope)
    #expect(await a.permits(c, scope: scope, run: run) == false)
}
@Test("F1-GUARD-002 unresolved and wrong scope construction have no native effect")
@MainActor func unresolved() async throws {
    let ns: NamespaceID = fresh(), p: ProfileID = fresh()
    let a = try NativeWebKitStorage(namespace: ns)
    let identity = StoreIdentity.persistent(profile: p, store: fresh(), namespace: ns, generation: 1)
    #expect(await a.construct(identity, view: fresh(), generation: 1, operation: fresh()) == .failed(.missingAssignment))
    #expect(await a.clear(identity, types: [.localStorage]) == .failed(.clearFailed))
    #expect(await a.remove(identity) == .failed(.outstandingReferences))
    #expect(a.trace().isEmpty)
    #expect(throws: FailureCode.staleCompletion) { try a.publish(fresh(), scope: .persistent(p), generation: 1, operation: fresh()) }
}
@Test("F1-GUARD-003 catalog namespace duplicate profile and store rejected before WebKit")
@MainActor func mappings() throws {
    let ns: NamespaceID = fresh(), p: ProfileID = fresh(), st: StoreID = fresh()
    let b = try ProfileBinding(profile: p, store: st, namespace: ns)
    #expect(throws: FailureCode.conflictingMapping) { try NativeWebKitStorage(namespace: ns, knownBindings: [b,b]) }
    #expect(throws: FailureCode.conflictingMapping) { try NativeWebKitStorage(namespace: fresh(), knownBindings: [b]) }
    let duplicateProfile = try ProfileBinding(profile: p, store: fresh(), namespace: ns)
    #expect(throws: FailureCode.conflictingMapping) { try NativeWebKitStorage(namespace: ns, knownBindings: [b,duplicateProfile]) }
}
@Test("F1-GUARD-004 normal composition cannot publish or navigate unresolved views")
@MainActor func normal() async throws {
    let s = try NativeStorageSession.privateOnly(), view: ViewID = fresh()
    #expect(s.adapter.surface(view) == nil)
    #expect(await s.adapter.navigate(view, url: URL(string: "http://127.0.0.1:1/fixture")!) == .failed(.unauthorized))
    #expect(s.adapter.trace().isEmpty)
}
