import BrowserDomain
import BrowserPorts

public struct PersistentFixture: Equatable, Sendable {
    public let binding: ProfileBinding
    public var data: [WebsiteDataKind: String]
    public init(binding: ProfileBinding, data: [WebsiteDataKind: String] = [:]) { self.binding = binding; self.data = data }
}
public actor FakeEngine: EngineStoragePort {
    private var persistent: [StoreID: PersistentFixture] = [:]
    private var ephemeral: [PrivateSessionID: (StoreIdentity, [WebsiteDataKind: String])] = [:]
    private let faults: FaultScript
    private let calls: CallRecorder
    private let gate: ControlledGate
    private var privateOrdinal: UInt64 = 1
    public init(faults: FaultScript, calls: CallRecorder, gate: ControlledGate, fixtures: [PersistentFixture] = []) {
        self.faults = faults; self.calls = calls; self.gate = gate
        for fixture in fixtures { persistent[fixture.binding.store] = fixture }
    }
    public func observe(_ store: StoreID) async -> Resolution {
        guard await calls.record(.observe) else { return .unavailable }
        await gate.pause(.observe)
        if let fault = await faults.consume(.observe) { return resolution(fault) }
        guard let fixture = persistent[store] else { return .missing }
        return .assigned(identity(fixture.binding))
    }
    public func createPersistent(_ binding: ProfileBinding) async -> Resolution {
        guard await calls.record(.createPersistent) else { return .unavailable }
        await gate.pause(.createPersistent)
        if let fault = await faults.consume(.createPersistent) { return resolution(fault) }
        guard persistent[binding.store] == nil, persistent.count < 128,
              !persistent.values.contains(where: { $0.binding.profile == binding.profile }) else { return .conflicting }
        persistent[binding.store] = PersistentFixture(binding: binding)
        return .assigned(identity(binding))
    }
    public func createPrivate(_ session: PrivateSessionID) async -> Resolution {
        guard await calls.record(.createPrivate) else { return .unavailable }
        await gate.pause(.createPrivate)
        if let fault = await faults.consume(.createPrivate) { return resolution(fault) }
        if let known = ephemeral[session] { return .assigned(known.0) }
        guard ephemeral.count < 128, privateOrdinal < 65536 else { return .unavailable }
        let suffix = String(privateOrdinal, radix: 16); privateOrdinal += 1
        guard let id = try? EphemeralStoreID("eeeeeeee-eeee-4eee-8eee-" + String(repeating: "0", count: 12 - suffix.count) + suffix) else { return .invalid }
        let value = StoreIdentity.ephemeral(session: session, store: id, generation: 1)
        ephemeral[session] = (value, [:]); return .assigned(value)
    }
    public func validates(_ value: StoreIdentity) -> Bool {
        switch value {
        case .persistent(_, let store, _, _): return persistent[store].map { identity($0.binding) == value } ?? false
        case .ephemeral(let session, _, _): return ephemeral[session]?.0 == value
        }
    }
    public func activate(_ value: StoreIdentity) async -> ProviderOutcome {
        guard await calls.record(.activation) else { return .failed(.diagnosticsOverflow) }
        await gate.pause(.activate)
        if let f = await faults.consume(.activate) { return outcome(f, fallback: .activationFailed) }
        return validates(value) ? .completed : .failed(.invalidStoreIdentity)
    }
    public func quiesce(_ scope: Scope) async -> ProviderOutcome {
        guard await calls.record(.quiesce) else { return .failed(.diagnosticsOverflow) }
        await gate.pause(.quiesce)
        if let f = await faults.consume(.quiesce) { return outcome(f, fallback: .quiescenceTimeout) }
        return .completed
    }
    public func retire(_ scope: Scope) async -> ProviderOutcome {
        guard await calls.record(.retire) else { return .failed(.diagnosticsOverflow) }
        await gate.pause(.retire)
        if let f = await faults.consume(.retire) { return outcome(f, fallback: .retirementFailed) }
        if case .privateSession(let session) = scope { ephemeral[session] = nil }
        return .completed
    }
    public func clear(_ value: StoreIdentity, types: Set<WebsiteDataKind>) async -> ProviderOutcome {
        guard await calls.record(.clear) else { return .failed(.diagnosticsOverflow) }
        await gate.pause(.clear)
        guard validates(value) else { return .failed(.invalidStoreIdentity) }
        let fault = await faults.consume(.clear)
        if let fault {
            if fault == .partialDeletion {
                if let first = types.sorted(by: { $0.rawValue < $1.rawValue }).first { erase(value, types: [first]) }
                return .partial
            }
            if fault == .unknownDeletionAfterEffect { erase(value, types: types); return .unknown }
            return outcome(fault, fallback: .clearFailed)
        }
        erase(value, types: types); return .completed
    }
    public func remove(_ value: StoreIdentity) async -> ProviderOutcome {
        guard await calls.record(.remove) else { return .failed(.diagnosticsOverflow) }
        await gate.pause(.remove)
        guard case .persistent(_, let store, _, _) = value, validates(value) else { return .failed(.invalidStoreIdentity) }
        if let f = await faults.consume(.remove) {
            if f == .partialDeletion { erase(value, types: [.cookies]); return .partial }
            if f == .unknownDeletionAfterEffect { persistent[store] = nil; return .unknown }
            return outcome(f, fallback: .removalFailed)
        }
        persistent[store] = nil; return .completed
    }
    @discardableResult public func seed(_ value: StoreIdentity, kind: WebsiteDataKind, text: String) -> Bool {
        guard validates(value), text.utf8.count <= 4096 else { return false }
        switch value {
        case .persistent(_, let store, _, _): persistent[store]?.data[kind] = text
        case .ephemeral(let session, _, _): ephemeral[session]?.1[kind] = text
        }
        return true
    }
    public func value(_ identity: StoreIdentity, kind: WebsiteDataKind) -> String? {
        guard validates(identity) else { return nil }
        switch identity {
        case .persistent(_, let store, _, _): return persistent[store]?.data[kind]
        case .ephemeral(let session, _, _): return ephemeral[session]?.1[kind]
        }
    }
    public func assignment(for scope: Scope) -> StoreIdentity? {
        switch scope {
        case .persistent(let profile): return persistent.values.first(where: { $0.binding.profile == profile }).map { identity($0.binding) }
        case .privateSession(let session): return ephemeral[session]?.0
        }
    }
    public func persistentSnapshot() -> [PersistentFixture] { persistent.values.sorted { $0.binding.store < $1.binding.store } }
    public func privateCount() -> Int { ephemeral.count }
    private func identity(_ b: ProfileBinding) -> StoreIdentity {
        .persistent(profile: b.profile, store: b.store, namespace: b.namespace, generation: b.resourceGeneration)
    }
    private func erase(_ value: StoreIdentity, types: Set<WebsiteDataKind>) {
        switch value {
        case .persistent(_, let store, _, _): for t in types { persistent[store]?.data[t] = nil }
        case .ephemeral(let session, _, _): for t in types { ephemeral[session]?.1[t] = nil }
        }
    }
    private func resolution(_ f: FakeFault) -> Resolution {
        switch f {
        case .unavailable: return .unavailable
        case .missing: return .missing
        case .invalidIdentity: return .invalid
        case .duplicateIdentity, .conflicting: return .conflicting
        case .defaultFallback: return .defaultStore
        case .foreignIdentity(let value): return .assigned(value)
        default: return .unknown
        }
    }
    private func outcome(_ f: FakeFault, fallback: FailureCode) -> ProviderOutcome {
        switch f {
        case .partialDeletion: return .partial
        case .unknownDeletion, .unknownDeletionAfterEffect: return .unknown
        case .unavailable: return .failed(.providerUnavailable)
        case .timeout: return .failed(.quiescenceTimeout)
        default: return .failed(fallback)
        }
    }
}
