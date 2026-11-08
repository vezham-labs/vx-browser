import BrowserDomain
import BrowserPorts

public actor LifecycleCoordinator {
    private enum Cleanup: Equatable { case live, quiesced, retired }
    private struct Entry {
        var binding: ProfileBinding?
        var state: LifecycleState = .registered
        var epoch: UInt64 = 1
        var resolution: Resolution?
        var views: Set<ViewID> = []
        var pending: OperationID?
        var failure: FailureCode?
        var quarantine: FailureCode?
        var cleanup: Cleanup = .live
        var recoveryBarrier: Action?
    }
    private struct Request: Equatable {
        let action: Action
        let scope: Scope
        var binding: ProfileBinding? = nil
        var view: ViewID? = nil
        var types: Set<WebsiteDataKind> = []
        var source: Scope? = nil
        var failure: FailureCode? = nil
    }
    private struct Receipt { let request: Request; var result: OperationResult? }
    private struct Ticket { let request: Request; let operation: OperationID; let epoch: UInt64; let prior: LifecycleState }
    private enum Admission { case ticket(Ticket), result(OperationResult) }
    private let run: RunID
    private let namespace: NamespaceID
    private let authority: any HostAuthorityPort
    private let catalog: any ProfileCatalogPort
    private let journal: any RecoveryJournalPort
    private let engine: any EngineStoragePort
    private let constructor: any ViewConstructionPort
    private let resources: any ResourcePort
    private let diagnosticLimit: Int
    private var entries: [Scope: Entry] = [:]
    private var receipts: [OperationID: Receipt] = [:]
    private var events: [DiagnosticEvent] = []
    private var terminalReservations = 0
    private var overflowed = false

    public init(run: RunID, namespace: NamespaceID, authority: any HostAuthorityPort, catalog: any ProfileCatalogPort,
                journal: any RecoveryJournalPort, engine: any EngineStoragePort, constructor: any ViewConstructionPort,
                resources: any ResourcePort, diagnosticLimit: Int = 1024) throws(FailureCode) {
        guard (2...4096).contains(diagnosticLimit) else { throw .invalidConfiguration }
        self.run = run; self.namespace = namespace; self.authority = authority; self.catalog = catalog
        self.journal = journal; self.engine = engine; self.constructor = constructor; self.resources = resources
        self.diagnosticLimit = diagnosticLimit
    }
    public func summary(_ scope: Scope) -> ScopeSummary? {
        entries[scope].map { ScopeSummary(state: $0.state, generation: $0.epoch, viewCount: $0.views.count,
                                         pending: $0.pending, failure: $0.failure) }
    }
    public func diagnostics() -> DiagnosticSnapshot { DiagnosticSnapshot(events: events, overflowed: overflowed) }
    public func catalogInventory() async -> CatalogInventory { await catalog.enumerate() }
    public func restartSnapshot() async -> RestartSnapshot { await journal.snapshot(run: run) }

    public func register(_ binding: ProfileBinding, context: CallerContext, operation: OperationID) async -> OperationResult {
        let scope = Scope.persistent(binding.profile)
        let request = Request(action: .register, scope: scope, binding: binding)
        guard await authorized(context, scope) else { return reject(request, operation, .unauthorized) }
        if let replay = replay(request, operation) { return replay }
        guard binding.namespace == namespace else { return reject(request, operation, .namespaceMismatch) }
        guard binding.origin == .fresh, binding.status == .registered, binding.revision == 1 else {
            return reject(request, operation, .invalidConfiguration)
        }
        guard entries[scope] == nil else { return reject(request, operation, .illegalTransition) }
        let observation = await catalog.lookup(binding.profile)
        guard case .missing = observation else { return reject(request, operation, catalogFailure(observation)) }
        let inventory = await catalog.enumerate()
        guard !inventory.bindings.contains(where: { $0.store == binding.store }),
              !entries.values.contains(where: { $0.binding?.store == binding.store }), entries[scope] == nil else {
            return reject(request, operation, .duplicateIdentity)
        }
        guard entries.count < 128 else { return reject(request, operation, .capacityExceeded) }
        entries[scope] = Entry(binding: binding)
        switch await begin(request, context, operation, allowed: [.registered], next: .registered) {
        case .result(let result): return result
        case .ticket(let t):
            let write = await catalog.insert(binding)
            guard await current(t, context) else { return await stale(t) }
            switch write {
            case .committed(let stored): entries[scope]?.binding = stored
            case .failed(let f): return await failTicket(t, f)
            }
            return await complete(t, context, .registered, .registered)
        }
    }
    public func registerPrivate(_ session: PrivateSessionID, context: CallerContext, operation: OperationID) async -> OperationResult {
        let scope = Scope.privateSession(session), request = Request(action: .register, scope: .privateSession(session))
        guard await authorized(context, scope) else { return reject(request, operation, .unauthorized) }
        if let r = replay(request, operation) { return r }
        guard entries[scope] == nil, entries.count < 128 else { return reject(request, operation, .illegalTransition) }
        entries[scope] = Entry(binding: nil)
        switch await begin(request, context, operation, allowed: [.registered], next: .registered) {
        case .result(let r): return r
        case .ticket(let t): return await complete(t, context, .registered, .registered)
        }
    }
    public func resolve(_ scope: Scope, context: CallerContext, operation: OperationID) async -> OperationResult {
        let request = Request(action: .resolve, scope: scope)
        switch await begin(request, context, operation, allowed: [.registered, .resolved, .quiescent], next: .resolving) {
        case .result(let r): return r
        case .ticket(let t):
            var resolution: Resolution
            if let known = entries[scope]?.resolution { resolution = known }
            else if let profile = scope.profile {
                let observed = await catalog.lookup(profile)
                guard await current(t, context) else { return await stale(t) }
                guard case .available(let binding) = observed, binding.namespace == namespace,
                      binding.store == entries[scope]?.binding?.store, binding.status != .deleted else {
                    return await failTicket(t, catalogFailure(observed))
                }
                entries[scope]?.binding = binding
                resolution = await engine.observe(binding.store)
                guard await current(t, context) else { return await stale(t) }
                if binding.origin == .fresh, binding.status == .registered, case .assigned = resolution {
                    return await failTicket(t, .conflictingMapping)
                }
                if resolution == .missing, binding.origin == .fresh, binding.status == .registered {
                    if let failure = await catalogState(t, context, .accessStarted) { return failure }
                    guard await current(t, context) else { return await stale(t) }
                    resolution = await engine.createPersistent(binding)
                }
            } else if case .privateSession(let session) = scope { resolution = await engine.createPrivate(session) }
            else { return await failTicket(t, .invalidIdentity) }
            guard await current(t, context) else { return await stale(t) }
            if let failure = ConstructionPolicy.validate(resolution, scope: scope, binding: entries[scope]?.binding) {
                return await failTicket(t, failure)
            }
            entries[scope]?.resolution = resolution
            return await complete(t, context, .resolved, .resolved)
        }
    }
    public func activate(_ scope: Scope, view: ViewID, context: CallerContext, operation: OperationID) async -> OperationResult {
        await construct(Request(action: .activate, scope: scope, view: view), context, operation)
    }
    public func switchScope(from source: Scope, to destination: Scope, view: ViewID, from: CallerContext,
                            to context: CallerContext, operation: OperationID) async -> OperationResult {
        let request = Request(action: .switchScope, scope: destination, view: view, source: source)
        guard source != destination, await authorized(from, source) else { return reject(request, operation, .unauthorized) }
        guard let entry = entries[source], entry.quarantine == nil, [.quiescent, .retired].contains(entry.state),
              await resources.inventory(source).isEmpty else { return reject(request, operation, .sourceNotRetired) }
        return await construct(request, context, operation, sourceContext: from, sourceEpoch: entry.epoch)
    }
    private func construct(_ request: Request, _ context: CallerContext, _ operation: OperationID,
                           sourceContext: CallerContext? = nil, sourceEpoch: UInt64? = nil) async -> OperationResult {
        let scope = request.scope
        switch await begin(request, context, operation, allowed: [.resolved, .active, .quiescent], next: .activating) {
        case .result(let r): return r
        case .ticket(let t):
            guard let view = request.view, !entries.values.contains(where: { $0.views.contains(view) }) else {
                return await failTicket(t, .duplicateView)
            }
            guard let resolution = entries[scope]?.resolution,
                  ConstructionPolicy.validate(resolution, scope: scope, binding: entries[scope]?.binding) == nil,
                  case .assigned(let identity) = resolution else { return await failTicket(t, .missingAssignment) }
            await resources.allowAcquisition(in: scope)
            guard await current(t, context) else { return await stale(t) }
            entries[scope]?.views.insert(view)
            let constructed = await constructor.construct(identity, view: view, generation: t.epoch, operation: operation)
            guard await current(t, context) else {
                let closed = await constructor.close(view, scope: scope)
                if closed == .completed { entries[scope]?.views.remove(view) }
                return await stale(t)
            }
            if let source = request.source {
                guard let sourceContext, let sourceEpoch, entries[source]?.epoch == sourceEpoch,
                      entries[source]?.pending == nil,
                      entries[source].map({ [.quiescent, .retired].contains($0.state) }) == true,
                      entries[source]?.quarantine == nil, await resources.inventory(source).isEmpty,
                      await authorized(sourceContext, source) else {
                    let closed = await constructor.close(view, scope: scope)
                    if closed == .completed { entries[scope]?.views.remove(view) }
                    return await failTicket(t, .staleCompletion)
                }
            }
            switch constructed {
            case .failed(let f): entries[scope]?.views.remove(view); return await failTicket(t, f)
            case .constructed: break
            }
            let activated = await engine.activate(identity)
            guard await current(t, context) else {
                let closed = await constructor.close(view, scope: scope)
                if closed == .completed { entries[scope]?.views.remove(view) }
                return await stale(t)
            }
            guard activated == .completed else {
                let closed = await constructor.close(view, scope: scope)
                if closed == .completed { entries[scope]?.views.remove(view) }
                return await failTicket(t, closed == .completed ? .activationFailed : .outstandingReferences)
            }
            if let source = request.source {
                guard let sourceContext, let sourceEpoch, entries[source]?.epoch == sourceEpoch,
                      entries[source]?.pending == nil,
                      entries[source].map({ [.quiescent, .retired].contains($0.state) }) == true,
                      entries[source]?.quarantine == nil, await resources.inventory(source).isEmpty,
                      await authorized(sourceContext, source) else {
                    let closed = await constructor.close(view, scope: scope)
                    if closed == .completed { entries[scope]?.views.remove(view) }
                    return await failTicket(t, .sourceNotRetired)
                }
            }
            entries[scope]?.cleanup = .live
            if let failure = await catalogState(t, context, .active) {
                let closed = await constructor.close(view, scope: scope)
                if closed == .completed { entries[scope]?.views.remove(view) }
                return failure
            }
            let success: Success = request.action == .switchScope ? .switched(view) : .activated(view)
            return await complete(t, context, success, .active)
        }
    }
    public func closeView(_ scope: Scope, view: ViewID, context: CallerContext, operation: OperationID) async -> OperationResult {
        let request = Request(action: .closeView, scope: scope, view: view)
        guard await authorized(context, scope) else { return reject(request, operation, .unauthorized) }
        guard let state = entries[scope]?.state else { return reject(request, operation, .illegalTransition) }
        switch await begin(request, context, operation, allowed: [state], next: state, cleanup: true) {
        case .result(let r): return r
        case .ticket(let t):
            guard entries[scope]?.views.contains(view) == true else { return await failTicket(t, .duplicateView) }
            let outcome = await constructor.close(view, scope: scope)
            guard await current(t, context) else { return await stale(t) }
            guard outcome == .completed else { return await failTicket(t, .outstandingReferences) }
            entries[scope]?.views.remove(view)
            if case .privateSession = scope, entries[scope]?.views.isEmpty == true {
                await resources.preventAcquisition(in: scope)
                guard await current(t, context) else { return await stale(t) }
                let quiet = await engine.quiesce(scope)
                guard await current(t, context) else { return await stale(t) }
                guard quiet == .completed else { return await failTicket(t, .quiescenceTimeout) }
                guard await resources.inventory(scope).isEmpty else {
                    return await finishUnsuccessful(t, context, .failure(.outstandingReferences), .quiescing, .outstandingReferences)
                }
                guard await current(t, context) else { return await stale(t) }
                let retired = await engine.retire(scope)
                guard await current(t, context) else { return await stale(t) }
                guard retired == .completed, await resources.inventory(scope).isEmpty else {
                    return await failTicket(t, .retirementFailed)
                }
                entries[scope]?.cleanup = .retired
                return await complete(t, context, .viewClosed, .retired)
            }
            return await complete(t, context, .viewClosed, t.prior)
        }
    }
    public func quiesce(_ scope: Scope, context: CallerContext, operation: OperationID) async -> OperationResult {
        let request = Request(action: .quiesce, scope: scope)
        switch await begin(request, context, operation, allowed: [.resolved, .active, .quiescing, .quiescent, .failed, .quarantined], next: .quiescing, fence: true, cleanup: true) {
        case .result(let r): return r
        case .ticket(let t):
            let outcome = await engine.quiesce(scope)
            guard await current(t, context) else { return await stale(t) }
            guard outcome == .completed else { return await failTicket(t, .quiescenceTimeout) }
            guard await resources.inventory(scope).isEmpty, entries[scope]?.views.isEmpty == true else {
                return await finishUnsuccessful(t, context, .failure(.outstandingReferences), .quiescing, .outstandingReferences)
            }
            guard await current(t, context) else { return await stale(t) }
            entries[scope]?.cleanup = .quiesced
            entries[scope]?.recoveryBarrier = nil
            entries[scope]?.failure = nil
            if let failure = await catalogState(t, context, .quiescent) { return failure }
            return await complete(t, context, .quiesced, .quiescent)
        }
    }
    public func retire(_ scope: Scope, context: CallerContext, operation: OperationID) async -> OperationResult {
        let request = Request(action: .retire, scope: scope)
        guard await authorized(context, scope) else { return reject(request, operation, .unauthorized) }
        if let r = replay(request, operation) { return r }
        guard entries[scope]?.cleanup == .quiesced else { return reject(request, operation, .illegalTransition) }
        switch await begin(request, context, operation, allowed: [.quiescent, .quarantined], next: .retiring, fence: true, cleanup: true) {
        case .result(let r): return r
        case .ticket(let t):
            guard await resources.inventory(scope).isEmpty, entries[scope]?.views.isEmpty == true else { return await failTicket(t, .outstandingReferences) }
            let outcome = await engine.retire(scope)
            guard await current(t, context) else { return await stale(t) }
            guard outcome == .completed, await resources.inventory(scope).isEmpty else { return await failTicket(t, .retirementFailed) }
            guard await current(t, context) else { return await stale(t) }
            entries[scope]?.cleanup = .retired
            if let f = await catalogState(t, context, .retired) { return f }
            return await complete(t, context, .retired, .retired)
        }
    }
    public func clear(_ scope: Scope, types: Set<WebsiteDataKind>, context: CallerContext, operation: OperationID) async -> OperationResult {
        let request = Request(action: .clear, scope: scope, types: types)
        guard !types.isEmpty else { return reject(request, operation, .unsupported) }
        return await deletion(request, context, operation)
    }
    public func remove(_ profile: ProfileID, context: CallerContext, operation: OperationID) async -> OperationResult {
        await deletion(Request(action: .remove, scope: .persistent(profile)), context, operation)
    }
    private func deletion(_ request: Request, _ context: CallerContext, _ operation: OperationID) async -> OperationResult {
        let removing = request.action == .remove, scope = request.scope
        switch await begin(request, context, operation, allowed: removing ? [.retired] : [.quiescent], next: removing ? .removing : .clearing, fence: true) {
        case .result(let r): return r
        case .ticket(let t):
            guard await resources.inventory(scope).isEmpty, entries[scope]?.views.isEmpty == true else { return await failTicket(t, .outstandingReferences) }
            guard await current(t, context), let resolution = entries[scope]?.resolution,
                  case .assigned(let identity) = resolution else { return await failTicket(t, .missingAssignment) }
            if removing, let f = await catalogState(t, context, .deleting) { return f }
            let result = removing ? await engine.remove(identity) : await engine.clear(identity, types: request.types)
            guard await current(t, context) else { return await stale(t) }
            switch result {
            case .partial: return await uncertain(t, .partial(request.action), .partialDeletion)
            case .unknown: return await uncertain(t, .unknown(request.action), .unknownDeletion)
            case .failed(let f): return await failTicket(t, f)
            case .completed:
                if removing {
                    if let failure = await catalogState(t, context, .deleted) { return failure }
                    return await complete(t, context, .removed, .removed)
                }
                return await complete(t, context, .cleared(request.types), .quiescent)
            }
        }
    }
    public func quarantine(_ scope: Scope, reason: FailureCode, context: CallerContext, operation: OperationID) async -> OperationResult {
        await forceFence(scope, reason, .quarantine, context, operation)
    }
    public func fail(_ scope: Scope, reason: FailureCode, context: CallerContext, operation: OperationID) async -> OperationResult {
        await forceFence(scope, reason, .fail, context, operation)
    }
    private func forceFence(_ scope: Scope, _ reason: FailureCode, _ action: Action, _ context: CallerContext, _ operation: OperationID) async -> OperationResult {
        let request = Request(action: action, scope: scope, failure: reason)
        guard await authorized(context, scope) else { return reject(request, operation, .unauthorized) }
        if let r = replay(request, operation) { return r }
        guard var entry = entries[scope] else { return reject(request, operation, .illegalTransition) }
        guard entry.epoch < UInt64.max else { return reject(request, operation, .capacityExceeded) }
        entry.epoch += 1; entry.pending = nil; entry.quarantine = reason; entry.failure = reason
        entry.state = action == .fail ? .failed : .quarantined; entries[scope] = entry
        await resources.preventAcquisition(in: scope)
        guard reserveDiagnostic(request, operation) else {
            if let b = entry.binding { _ = await journal.write(checkpoint(b, entry.epoch, .quarantined(.diagnosticsOverflow), operation)) }
            return .failure(.diagnosticsOverflow)
        }
        let t = Ticket(request: request, operation: operation, epoch: entry.epoch, prior: entry.state)
        var result: OperationResult = action == .fail ? .failure(reason) : .quarantined(reason)
        if let b = entry.binding {
            let prior = await journal.read(b.profile)
            var causeOperation = operation
            var interrupted: Action? = action
            if case .record(let priorRecord) = prior {
                if case .pending(let priorAction) = priorRecord.phase {
                    causeOperation = priorRecord.operation; interrupted = priorAction
                } else if let priorAction = priorRecord.interruptedAction {
                    causeOperation = priorRecord.operation; interrupted = priorAction
                }
            }
            let pending = checkpoint(b, entry.epoch, .pending(action), causeOperation, interrupted: interrupted)
            let prepared = await journal.write(pending)
            let record = checkpoint(b, entry.epoch, .quarantined(reason), causeOperation, interrupted: interrupted)
            let committed = await journal.write(record)
            if prepared != .committed || committed != .committed { result = .failure(.quarantinePersistenceFailed) }
        }
        return finishReceipt(t, result)
    }
    public func reconcile(_ profile: ProfileID, context: CallerContext, operation: OperationID) async -> OperationResult {
        let scope = Scope.persistent(profile), request = Request(action: .reconcile, scope: .persistent(profile))
        guard await authorized(context, scope) else { return reject(request, operation, .unauthorized) }
        if let r = replay(request, operation) { return r }
        let lookup = await catalog.lookup(profile)
        guard case .available(let binding) = lookup, binding.namespace == namespace else {
            if entries[scope] == nil { entries[scope] = Entry(binding: nil) }
            return await forceFence(scope, catalogFailure(lookup), .quarantine, context, operation)
        }
        if entries[scope] == nil { entries[scope] = Entry(binding: binding) }
        if entries[scope]?.quarantine != nil { return reject(request, operation, .quarantined) }
        let journalState = await journal.read(profile)
        guard case .record(let record) = journalState, record.profile == profile, record.store == binding.store,
              record.namespace == namespace, record.generation > 0 else {
            return await forceFence(scope, journalState == .corrupt ? .corruptRecovery : .reconciliationMismatch, .quarantine, context, operation)
        }
        guard record.generation < UInt64.max else {
            return await forceFence(scope, .capacityExceeded, .quarantine, context, operation)
        }
        let recoveredEpoch = max(entries[scope]?.epoch ?? 1, record.generation)
        entries[scope]?.epoch = recoveredEpoch
        guard case .stable(let stableStatus) = record.phase, stableStatus == binding.status, ![.deleting, .deleted, .quarantined].contains(binding.status) else {
            return await forceFence(scope, .interruptedOperation, .quarantine, context, operation)
        }
        guard record.generation < UInt64.max, (entries[scope]?.epoch ?? 0) < UInt64.max else {
            return await forceFence(scope, .capacityExceeded, .quarantine, context, operation)
        }
        let nextEpoch = max(entries[scope]?.epoch ?? 1, record.generation) + 1
        entries[scope]?.epoch = nextEpoch
        switch await begin(request, context, operation, allowed: [.registered, .failed, .retired, .resolved], next: .reconciling) {
        case .result(let r): return r
        case .ticket(let t):
            guard await resources.inventory(scope).isEmpty else { return await failTicket(t, .outstandingReferences) }
            guard await current(t, context) else { return await stale(t) }
            let observed = await engine.observe(binding.store)
            guard await current(t, context) else { return await stale(t) }
            if let f = ConstructionPolicy.validate(observed, scope: scope, binding: binding) { return await failTicket(t, f) }
            entries[scope]?.binding = binding; entries[scope]?.resolution = observed
            return await complete(t, context, .reconciled, .resolved)
        }
    }

    private func authorized(_ context: CallerContext, _ scope: Scope) async -> Bool {
        guard context.run == run, context.scope == scope else { return false }
        return await authority.permits(context, scope: scope, run: run)
    }
    private func replay(_ request: Request, _ operation: OperationID) -> OperationResult? {
        guard let receipt = receipts[operation] else { return nil }
        guard receipt.request == request else { return .failure(.operationConflict) }
        return receipt.result ?? .failure(.busy)
    }
    private func reserveDiagnostic(_ request: Request, _ operation: OperationID) -> Bool {
        guard !overflowed, receipts.count < 128, events.count + terminalReservations + 2 <= diagnosticLimit else {
            overflowed = true; return false
        }
        receipts[operation] = Receipt(request: request, result: nil)
        events.append(DiagnosticEvent(sequence: UInt64(events.count + 1), operation: operation, action: request.action,
                                      scopeKind: request.scope.kind, classification: .started, failure: nil))
        terminalReservations += 1
        return true
    }
    private func reject(_ request: Request, _ operation: OperationID, _ failure: FailureCode) -> OperationResult {
        if events.count + terminalReservations < diagnosticLimit {
            events.append(DiagnosticEvent(sequence: UInt64(events.count + 1), operation: operation, action: request.action,
                                          scopeKind: request.scope.kind, classification: .rejected, failure: failure))
        } else { overflowed = true }
        return .failure(failure)
    }
    private func begin(_ request: Request, _ context: CallerContext, _ operation: OperationID,
                       allowed: Set<LifecycleState>, next: LifecycleState, fence: Bool = false, cleanup: Bool = false) async -> Admission {
        guard await authorized(context, request.scope) else { return .result(reject(request, operation, .unauthorized)) }
        if let r = replay(request, operation) { return .result(r) }
        guard var entry = entries[request.scope] else { return .result(reject(request, operation, .illegalTransition)) }
        guard entry.pending == nil else { return .result(reject(request, operation, .busy)) }
        guard cleanup || entry.quarantine == nil else { return .result(reject(request, operation, .quarantined)) }
        guard allowed.contains(entry.state) else { return .result(reject(request, operation, .illegalTransition)) }
        guard !fence || entry.epoch < UInt64.max else { return .result(reject(request, operation, .capacityExceeded)) }
        guard reserveDiagnostic(request, operation) else { return .result(.failure(.diagnosticsOverflow)) }
        let prior = entry.state
        if fence { entry.epoch += 1 }
        entry.state = next; entry.pending = operation; entries[request.scope] = entry
        let t = Ticket(request: request, operation: operation, epoch: entry.epoch, prior: prior)
        if fence {
            await resources.preventAcquisition(in: request.scope)
            guard await current(t, context) else { return .result(await stale(t)) }
        }
        if let b = entry.binding {
            let phase: RecoveryPhase = entry.quarantine.map(RecoveryPhase.quarantined) ?? .pending(request.action)
            let write = await journal.write(checkpoint(b, entry.epoch, phase, operation, interrupted: entry.quarantine == nil ? nil : request.action))
            guard await current(t, context) else { return .result(await stale(t)) }
            if case .failed(let f) = write { return .result(await failTicket(t, f)) }
        }
        return .ticket(t)
    }
    private func current(_ t: Ticket, _ context: CallerContext) async -> Bool {
        guard entries[t.request.scope]?.epoch == t.epoch, entries[t.request.scope]?.pending == t.operation else { return false }
        let allowed = await authorized(context, t.request.scope)
        return allowed && entries[t.request.scope]?.epoch == t.epoch && entries[t.request.scope]?.pending == t.operation
    }
    private func checkpoint(_ b: ProfileBinding, _ generation: UInt64, _ phase: RecoveryPhase, _ operation: OperationID, interrupted: Action? = nil) -> RecoveryRecord {
        RecoveryRecord(profile: b.profile, store: b.store, namespace: b.namespace, generation: generation, phase: phase, operation: operation, interruptedAction: interrupted)
    }
    private func catalogState(_ t: Ticket, _ context: CallerContext, _ state: CatalogStatus) async -> OperationResult? {
        guard await current(t, context) else { return await stale(t) }
        guard let binding = entries[t.request.scope]?.binding else { return nil }
        let desired = entries[t.request.scope]?.quarantine == nil ? state : .quarantined
        let result = await catalog.transition(binding.profile, expectedRevision: binding.revision, to: desired)
        guard await current(t, context) else { return await stale(t) }
        switch result {
        case .committed(let next): entries[t.request.scope]?.binding = next; return nil
        case .failed(let f): return await uncertain(t, .unknown(t.request.action), f)
        }
    }
    private func complete(_ t: Ticket, _ context: CallerContext, _ success: Success, _ state: LifecycleState) async -> OperationResult {
        guard await current(t, context), let entry = entries[t.request.scope] else { return await stale(t) }
        if let b = entry.binding {
            let phase: RecoveryPhase = entry.quarantine.map(RecoveryPhase.quarantined) ?? entry.recoveryBarrier.map(RecoveryPhase.pending) ?? (state == .removed ? .removed : .stable(b.status))
            let write = await journal.write(checkpoint(b, entry.epoch, phase, t.operation))
            guard await current(t, context) else { return await stale(t) }
            if case .failed(let f) = write { return await uncertain(t, .unknown(t.request.action), f) }
        }
        entries[t.request.scope]?.state = entry.quarantine == nil ? state : .quarantined
        entries[t.request.scope]?.pending = nil
        return finishReceipt(t, .success(success))
    }
    private func finishUnsuccessful(_ t: Ticket, _ context: CallerContext, _ result: OperationResult,
                                    _ state: LifecycleState, _ failure: FailureCode) async -> OperationResult {
        guard await current(t, context) else { return await stale(t) }
        if var entry = entries[t.request.scope] {
            entry.state = entry.quarantine == nil ? state : .quarantined
            entry.pending = nil; entry.failure = failure; entry.recoveryBarrier = t.request.action
            entries[t.request.scope] = entry
        }
        // The unresolved write-ahead record remains pending, so restart cannot treat it as clean.
        return finishReceipt(t, result)
    }
    private func failTicket(_ t: Ticket, _ failure: FailureCode) async -> OperationResult {
        await uncertain(t, .failure(failure), failure)
    }
    private func uncertain(_ t: Ticket, _ result: OperationResult, _ failure: FailureCode) async -> OperationResult {
        if var entry = entries[t.request.scope], entry.epoch == t.epoch, entry.pending == t.operation {
            if entry.epoch < UInt64.max { entry.epoch += 1 }
            entry.state = .quarantined; entry.pending = nil; entry.failure = failure; entry.quarantine = failure
            entries[t.request.scope] = entry
            await resources.preventAcquisition(in: t.request.scope)
            if let b = entry.binding { _ = await journal.write(checkpoint(b, entry.epoch, .quarantined(failure), t.operation, interrupted: t.request.action)) }
        }
        return finishReceipt(t, result)
    }
    private func stale(_ t: Ticket) async -> OperationResult {
        // Revocation may leave an otherwise unchanged pending state. Always fence it locally.
        if entries[t.request.scope]?.pending == t.operation {
            entries[t.request.scope]?.state = .quarantined; entries[t.request.scope]?.quarantine = .staleCompletion
            entries[t.request.scope]?.failure = .staleCompletion; entries[t.request.scope]?.pending = nil
            await resources.preventAcquisition(in: t.request.scope)
            if let entry = entries[t.request.scope], let b = entry.binding {
                _ = await journal.write(checkpoint(b, entry.epoch, .quarantined(.staleCompletion), t.operation, interrupted: t.request.action))
            }
        }
        return finishReceipt(t, .failure(.staleCompletion))
    }
    private func finishReceipt(_ t: Ticket, _ result: OperationResult) -> OperationResult {
        guard var receipt = receipts[t.operation], receipt.result == nil else { return receipts[t.operation]?.result ?? result }
        receipt.result = result; receipts[t.operation] = receipt; terminalReservations -= 1
        let classification: DiagnosticClass
        let failure: FailureCode?
        switch result {
        case .success: classification = .succeeded; failure = nil
        case .failure(let f): classification = f == .staleCompletion ? .stale : .failed; failure = f
        case .partial: classification = .partial; failure = .partialDeletion
        case .unknown: classification = .unknown; failure = .unknownDeletion
        case .quarantined(let f): classification = .quarantined; failure = f
        }
        events.append(DiagnosticEvent(sequence: UInt64(events.count + 1), operation: t.operation, action: t.request.action,
                                      scopeKind: t.request.scope.kind, classification: classification, failure: failure))
        return result
    }
    private func catalogFailure(_ observed: CatalogObservation) -> FailureCode {
        switch observed { case .missing: return .missingCatalog; case .corrupt: return .corruptCatalog
        case .conflicting: return .conflictingMapping; case .unavailable: return .catalogUnavailable
        case .available: return .reconciliationMismatch }
    }
}
