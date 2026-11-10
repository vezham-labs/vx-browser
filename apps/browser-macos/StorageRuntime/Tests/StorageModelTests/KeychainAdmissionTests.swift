import Foundation
import Testing
import BrowserDomain
@testable import BrowserNativeStorage

@MainActor
struct KeychainAdmissionTests {
    @Test func wrongScopeAndReplacedGrantFailBeforeKeychainAccess() async throws {
        let authority = NativeHostAuthority()
        let run = RunID.fresh()
        let profile = ProfileID.fresh()
        let scope = Scope.persistent(profile)
        let broker = NativeKeyBroker(authority: authority, run: run, qualificationNamespace: UUID())
        let reference = try NativeKeyReference(profile: profile, keyID: UUID())
        let foreign = await authority.grant(.persistent(.fresh()), run: run)
        let stale = await authority.grant(scope, run: run)
        _ = await authority.grant(scope, run: run)
        for context in [foreign, stale] {
            do {
                _ = try await broker.acquire(reference, context: context, interactive: false)
                Issue.record("Unauthorized acquire succeeded")
            } catch let failure as KeyFailure {
                #expect(failure == .denied)
            }
        }
        #expect(broker.lastOSStatus == nil)
        #expect(!broker.hasActiveLease(profile))
    }

    @Test func forgedLeaseCannotSeal() async throws {
        let run = RunID.fresh()
        let broker = NativeKeyBroker(authority: NativeHostAuthority(), run: run, qualificationNamespace: UUID())
        let forged = KeyLease(id: .fresh(), profile: .fresh(), run: run, epoch: 1)
        do {
            _ = try await broker.seal(Data([1]), lease: forged, aad: Data())
            Issue.record("A forged lease sealed data")
        } catch let failure as KeyFailure {
            #expect(failure == .stale)
        }
        #expect(broker.lastOSStatus == nil)
    }
}
