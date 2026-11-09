import Foundation
import BrowserDomain
import BrowserPorts
import BrowserCore

@MainActor final class NativeProfileBarrier: ProfileBarrierPort {
    let adapter: NativeWebKitStorage
    let core: LifecycleCoordinator
    let authority: NativeHostAuthority
    let catalog: any ProfileCatalogPort
    init(adapter: NativeWebKitStorage, core: LifecycleCoordinator, authority: NativeHostAuthority, catalog: any ProfileCatalogPort) {
        self.adapter = adapter; self.core = core; self.authority = authority; self.catalog = catalog
    }
    func fence(_ profile: ProfileID) async { adapter.securityFence(profile) }
    func retireResources(_ profile: ProfileID) async -> ProviderOutcome {
        let scope = Scope.persistent(profile)
        guard let context = await authority.current(scope) else {
            return await adapter.inventory(scope).isEmpty ? .completed : .unknown
        }
        for view in adapter.ownedViews(scope) {
            guard await core.closeView(scope, view: view, context: context, operation: try! OperationID(UUID().uuidString)) == .success(.viewClosed) else { return .unknown }
        }
        if await core.summary(scope) == nil { return .completed }
        guard await core.quiesce(scope, context: context, operation: try! OperationID(UUID().uuidString)) == .success(.quiesced),
              await core.retire(scope, context: context, operation: try! OperationID(UUID().uuidString)) == .success(.retired) else { return .unknown }
        await authority.revoke(scope)
        return .completed
    }
    func reconcileForUnlock(_ profile: ProfileID) async -> Bool {
        _ = await catalog.lookup(profile)
        let plan = StorageRecoveryPolicy.evaluate(catalog: .unavailable, key: .unavailable,
            engine: .unknown, intent: .unlock, recordedLocked: true, deletionKnowledgeComplete: false)
        return plan == .eligibleForExplicitUnlock // D2A-01 blocks real authenticated catalog/key reacquisition.
    }
    func restoreAdmission(_ profile: ProfileID) { adapter.restoreSecurityAdmission(profile) }
}
