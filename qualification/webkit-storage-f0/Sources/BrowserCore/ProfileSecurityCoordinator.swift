import BrowserDomain
import BrowserPorts

public actor ProfileSecurityCoordinator {
    private let barrier: any ProfileBarrierPort
    private let keys: any ProfileKeyPort
    private let authentication: any ProfileAuthenticationPort
    private let permissions: PermissionCoordinator
    private var states: [ProfileID: ProfileLockState] = [:]
    private var epochs: [ProfileID: UInt64] = [:]
    public init(barrier: any ProfileBarrierPort, keys: any ProfileKeyPort,
                authentication: any ProfileAuthenticationPort, permissions: PermissionCoordinator) {
        self.barrier = barrier; self.keys = keys; self.authentication = authentication; self.permissions = permissions
    }
    public func register(_ profile: ProfileID, initiallyLocked: Bool = true) async {
        guard states[profile] == nil else { return }
        states[profile] = .recoveryRequired; epochs[profile] = 1
        if initiallyLocked { _ = await lock(profile, cause: .manual) }
        else { states[profile] = .unlocked }
    }
    public func state(_ profile: ProfileID) -> ProfileLockState { states[profile] ?? .recoveryRequired }
    public func lock(_ profile: ProfileID, cause: LockCause) async -> ProfileLockState {
        guard let state = states[profile] else { return .recoveryRequired }
        if state == .locked { return .locked }
        if state == .lockRequested || state == .quiescing { return state }
        let epoch = epochs[profile, default: 0] + 1; epochs[profile] = epoch
        states[profile] = .lockRequested
        await barrier.fence(profile)
        await permissions.invalidate(.persistent(profile), lock: true)
        await keys.revoke(profile)
        guard epochs[profile] == epoch else { return states[profile] ?? .recoveryRequired }
        states[profile] = .quiescing
        let outcome = await barrier.retireResources(profile)
        guard epochs[profile] == epoch else { return states[profile] ?? .recoveryRequired }
        let noKeys = !(await keys.hasActiveLease(profile))
        states[profile] = outcome == .completed && noKeys ? .locked : .recoveryRequired
        return states[profile]!
    }
    public func unlock(_ profile: ProfileID) async -> ProfileLockState {
        guard states[profile] == .locked else { return states[profile] ?? .recoveryRequired }
        let epoch = epochs[profile, default: 0] + 1; epochs[profile] = epoch; states[profile] = .unlockRequested
        let authenticated = await authentication.authenticate(profile)
        guard epochs[profile] == epoch else { return states[profile] ?? .recoveryRequired }
        guard authenticated else { states[profile] = .locked; return .locked }
        states[profile] = .unlocking
        let reconciled = await barrier.reconcileForUnlock(profile)
        guard epochs[profile] == epoch else { return states[profile] ?? .recoveryRequired }
        guard reconciled else { states[profile] = .recoveryRequired; return .recoveryRequired }
        await barrier.restoreAdmission(profile)
        guard epochs[profile] == epoch else { await barrier.fence(profile); return states[profile] ?? .recoveryRequired }
        await permissions.restoreAdmission(.persistent(profile))
        guard epochs[profile] == epoch else {
            await permissions.invalidate(.persistent(profile), lock: true);await barrier.fence(profile)
            return states[profile] ?? .recoveryRequired
        }
        states[profile] = .unlocked
        return .unlocked
    }
    public func lockAll(cause: LockCause) async { for p in Array(states.keys) { _ = await lock(p, cause: cause) } }
}
