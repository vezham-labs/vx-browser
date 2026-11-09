import Foundation
import Testing
import BrowserDomain
import BrowserCore
import BrowserPersistence
import WSF0Fakes

@Test("F1-FAKE-001 concurrent close and clear exclude one another without effects")
func closeClearRace() async throws {
    func id<T>() -> ID<T> { try! ID(UUID().uuidString) }
    let namespace: NamespaceID = id(), run: RunID = id(), profile: ProfileID = id(), view: ViewID = id()
    let authority = FakeHostAuthority(), resources = FakeResources(), calls = CallRecorder()
    let faults = FaultScript(), gate = ControlledGate()
    let engine = FakeEngine(faults: faults, calls: calls, gate: gate)
    let constructor = FakeConstruction(engine: engine, resources: resources, calls: calls, faults: faults, gate: gate)
    let core = try LifecycleCoordinator(run: run, namespace: namespace, authority: authority,
        catalog: InMemoryProfileCatalog(namespace: namespace), journal: InMemoryRecoveryJournal(namespace: namespace),
        engine: engine, constructor: constructor, resources: resources)
    let scope = Scope.persistent(profile), context = await authority.grant(id(), scope: scope, run: run)
    let binding = try ProfileBinding(profile: profile, store: id(), namespace: namespace)
    #expect(await core.register(binding, context: context, operation: id()) == .success(.registered))
    #expect(await core.resolve(scope, context: context, operation: id()) == .success(.resolved))
    #expect(await core.activate(scope, view: view, context: context, operation: id()) == .success(.activated(view)))
    await gate.arm(.close)
    let closeOperation: OperationID = id()
    let closing = Task { await core.closeView(scope, view: view, context: context, operation: closeOperation) }
    await gate.waitForArrival(.close)
    #expect(await core.clear(scope, types: [.localStorage], context: context, operation: id()) == .failure(.busy))
    #expect(await calls.count(.clear) == 0)
    await gate.release(.close)
    #expect(await closing.value == .success(.viewClosed))
    #expect(await core.quiesce(scope, context: context, operation: id()) == .success(.quiesced))
    await gate.arm(.clear)
    let clearOperation: OperationID = id()
    let clearing = Task { await core.clear(scope, types: [.localStorage], context: context, operation: clearOperation) }
    await gate.waitForArrival(.clear)
    let closesBefore = await calls.count(.close)
    #expect(await core.closeView(scope, view: view, context: context, operation: id()) == .failure(.busy))
    #expect(await calls.count(.close) == closesBefore)
    await gate.release(.clear)
    #expect(await clearing.value == .success(.cleared([.localStorage])))
    #expect(await resources.inventory(scope).isEmpty)
}
