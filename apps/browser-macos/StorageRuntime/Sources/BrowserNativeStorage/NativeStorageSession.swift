import Foundation
import BrowserDomain
import BrowserPorts
import BrowserCore
import BrowserPersistence

/// Host registry; opaque IDs supplied by a page cannot mint a grant.
public actor NativeHostAuthority: HostAuthorityPort {
    private var grants: [Scope: CallerContext] = [:]
    public init() {}
    public func grant(_ scope: Scope, run: RunID) -> CallerContext {
        let context = CallerContext(caller: try! CallerID(UUID().uuidString), scope: scope, run: run, authorityEpoch: 1)
        grants[scope] = context; return context
    }
    public func revoke(_ scope: Scope) { grants.removeValue(forKey: scope) }
    public func permits(_ context: CallerContext, scope: Scope, run: RunID) -> Bool { grants[scope] == context && context.run == run }
}

/// Application composition shared by normal host and isolated qualification mode.
/// Persistent catalog/journal are injected ports. The normal host has no approved durable
/// catalog yet and therefore exposes no persistent-profile create/open path.
@MainActor public final class NativeStorageSession {
    public let core: LifecycleCoordinator
    public let adapter: NativeWebKitStorage
    public let authority: NativeHostAuthority
    public let run: RunID
    private let journal: any RecoveryJournalPort
    public init(namespace: NamespaceID, run: RunID, catalog: any ProfileCatalogPort,
                journal: any RecoveryJournalPort, bindings: [ProfileBinding] = [], allowedOrigins: Set<String> = []) throws {
        self.run = run; self.journal = journal
        authority = NativeHostAuthority()
        adapter = try NativeWebKitStorage(namespace: namespace, knownBindings: bindings, allowedOrigins: allowedOrigins)
        core = try LifecycleCoordinator(run: run, namespace: namespace, authority: authority, catalog: catalog,
                                        journal: journal, engine: adapter, constructor: adapter, resources: adapter)
    }
    public static func privateOnly() throws -> NativeStorageSession {
        let ns = try NamespaceID(UUID().uuidString)
        return try NativeStorageSession(namespace: ns, run: RunID(UUID().uuidString),
             catalog: InMemoryProfileCatalog(namespace: ns), journal: InMemoryRecoveryJournal(namespace: ns))
    }
    public func open(_ scope: Scope, context: CallerContext, view: ViewID, operation: OperationID) async -> OperationResult {
        let result = await core.activate(scope, view: view, context: context, operation: operation)
        return await publishResult(result, expected: .activated(view), scope: scope, context: context, view: view, operation: operation)
    }
    public func switchProfile(from source: Scope, to destination: Scope, sourceContext: CallerContext,
                              context: CallerContext, view: ViewID, operation: OperationID) async -> OperationResult {
        let result = await core.switchScope(from: source, to: destination, view: view, from: sourceContext, to: context, operation: operation)
        return await publishResult(result, expected: .switched(view), scope: destination, context: context, view: view, operation: operation)
    }
    private func publishResult(_ result: OperationResult, expected: Success, scope: Scope, context: CallerContext,
                               view: ViewID, operation: OperationID) async -> OperationResult {
        guard result == .success(expected) else { return result }
        guard let summary = await core.summary(scope), summary.state == .active,
              await authority.permits(context, scope: scope, run: run) else {
            return await publicationFailure(scope, context: context, reason: .staleCompletion)
        }
        if adapter.publicationMatches(view, scope: scope, generation: summary.generation, operation: operation) { return result }
        var publicationRecord: RecoveryRecord?
        if let p = scope.profile {
            guard case .record(let r) = await journal.read(p) else {
                return await publicationFailure(scope, context: context, reason: .corruptRecovery)
            }
            publicationRecord = r
            let pending = RecoveryRecord(profile: r.profile, store: r.store, namespace: r.namespace,
                generation: r.generation, phase: .pending(.activate), operation: operation)
            guard await journal.write(pending) == .committed else {
                return await publicationFailure(scope, context: context, reason: .journalUnavailable)
            }
        }
        do {
            try adapter.publish(view, scope: scope, generation: summary.generation, operation: operation)
            if let r = publicationRecord, await journal.write(r) != .committed { throw FailureCode.journalUnavailable }
        }
        catch {
            return await publicationFailure(scope, context: context, reason: error as? FailureCode ?? .staleCompletion)
        }
        return result
    }
    private func publicationFailure(_ scope: Scope, context: CallerContext, reason: FailureCode) async -> OperationResult {
        await adapter.preventAcquisition(in: scope)
        _ = await core.quarantine(scope, reason: reason, context: context, operation: try! OperationID(UUID().uuidString))
        return .failure(reason)
    }
}
