import BrowserDomain
import BrowserPorts

/// Only trusted native callbacks may construct requests. No page-supplied authority.
public actor PermissionCoordinator {
    private struct GrantKey: Hashable { let scope: Scope; let origin: VerifiedOrigin; let kind: PermissionKind }
    private struct Pending { let request: PermissionRequest; let epoch: UInt64 }
    private let authority: any HostAuthorityPort
    private let run: RunID
    private var grants: [GrantKey: PermissionDecision] = [:]
    private var pending: [OperationID: Pending] = [:]
    private var epochs: [Scope: UInt64] = [:]
    private var blocked: Set<Scope> = []
    public init(run: RunID, authority: any HostAuthorityPort) { self.run = run; self.authority = authority }
    public func evaluate(_ r: PermissionRequest, supported: Bool, native: NativeAuthorization) async -> PermissionEvaluation {
        guard supported, r.kind != .unknown, r.viewGeneration > 0, r.context.run == run,
              !blocked.contains(r.context.scope), pending.count < 128,
              pending[r.id] == nil, native != .denied, native != .unavailable else { return PermissionEvaluation(.deny) }
        let epoch = epochs[r.context.scope, default: 1]
        guard await authority.permits(r.context, scope: r.context.scope, run: run),
              !blocked.contains(r.context.scope), epochs[r.context.scope, default: 1] == epoch,
              pending[r.id] == nil, pending.count < 128 else { return PermissionEvaluation(.deny) }
        let key = GrantKey(scope: r.context.scope, origin: r.origin, kind: r.kind)
        if let stored = grants[key] { return PermissionEvaluation(stored == .allow && native != .authorized ? .deny : stored) }
        pending[r.id] = Pending(request: r, epoch: epoch)
        return PermissionEvaluation(.ask, ticket: PermissionTicket(id: r.id, scope: r.context.scope, epoch: epoch))
    }
    public func decide(_ ticket: PermissionTicket, choice: PermissionDecision, lifetime: GrantLifetime,
                       native: NativeAuthorization) async -> PermissionDecision {
        guard let p = pending.removeValue(forKey: ticket.id), ticket.scope == p.request.context.scope,
              ticket.epoch == p.epoch, !blocked.contains(ticket.scope), epochs[ticket.scope, default: 1] == ticket.epoch,
              lifetime != .persistent, choice != .ask,
              choice != .allow || native == .authorized else { return .deny }
        guard await authority.permits(p.request.context, scope: ticket.scope, run: run),
              !blocked.contains(ticket.scope), epochs[ticket.scope, default: 1] == ticket.epoch else { return .deny }
        if lifetime == .session, grants.count < 512 {
            grants[GrantKey(scope: ticket.scope, origin: p.request.origin, kind: p.request.kind)] = choice
        }
        return choice
    }
    public func invalidate(_ scope: Scope, lock: Bool) {
        epochs[scope, default: 1] += 1
        grants = grants.filter { $0.key.scope != scope }; pending = pending.filter { $0.value.request.context.scope != scope }
        if lock { blocked.insert(scope) }
    }
    public func restoreAdmission(_ scope: Scope) { blocked.remove(scope) }
    public func revoke(scope: Scope, origin: VerifiedOrigin, kind: PermissionKind) {
        invalidate(scope, lock: false) // All pending decisions for this scope become stale.
    }
    public func storedCount(_ scope: Scope) -> Int { grants.filter { $0.key.scope == scope }.count }
}
