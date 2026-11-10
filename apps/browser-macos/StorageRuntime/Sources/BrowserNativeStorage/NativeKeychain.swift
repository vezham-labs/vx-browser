import Foundation
import Security
import LocalAuthentication
import CryptoKit
import BrowserDomain
import BrowserPorts

/// Native-only reference; no secret bytes can be obtained through a Core/UI port.
public struct NativeKeyReference: Hashable, Codable, Sendable {
    public let profile: ProfileID
    public let keyID: UUID
    public let version: UInt32
    public init(profile: ProfileID, keyID: UUID, version: UInt32 = 1) throws {
        guard version > 0, keyID != UUID(uuidString: "00000000-0000-0000-0000-000000000000") else { throw KeyFailure.invalid }
        self.profile = profile; self.keyID = keyID; self.version = version
    }
}
private final class SecretBuffer {
    private let bytes: UnsafeMutableRawPointer
    let count: Int
    init(_ data: Data) { count = data.count; bytes = .allocate(byteCount: count, alignment: 16); data.copyBytes(to: bytes.assumingMemoryBound(to: UInt8.self), count: count) }
    deinit { bytes.initializeMemory(as: UInt8.self, repeating: 0, count: count); bytes.deallocate() }
    func symmetricKey() -> SymmetricKey { SymmetricKey(data: UnsafeRawBufferPointer(start: bytes, count: count)) }
}

@MainActor public final class NativeKeyBroker: ProfileKeyPort {
    private struct Entry {
        let lease: KeyLease
        let reference: NativeKeyReference
        let caller: CallerContext
        let secret: SecretBuffer
        let authentication: LAContext
    }
    private let service: String
    private let authority: NativeHostAuthority
    private let run: RunID
    private var entries: [ResourceID: Entry] = [:]
    private var epochs: [ProfileID: UInt64] = [:]
    public private(set) var lastOSStatus: Int32?
    public init(authority: NativeHostAuthority, run: RunID, qualificationNamespace: UUID? = nil) {
        self.authority = authority; self.run = run
        service = qualificationNamespace.map { "internal.vx.browser.keys.v1.qualification." + $0.uuidString.lowercased() } ?? "internal.vx.browser.keys.v1"
    }
    private func query(_ ref: NativeKeyReference) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
         kSecAttrAccount as String: "profile/\(ref.profile.rawValue)/\(ref.keyID.uuidString.lowercased())/\(ref.version)",
         kSecUseDataProtectionKeychain as String: true, kSecAttrSynchronizable as String: false]
    }
    public static func classify(_ status: OSStatus) -> KeyFailure {
        switch status {
        case errSecItemNotFound: return .missing
        case errSecDuplicateItem: return .duplicate
        case errSecAuthFailed, errSecUserCanceled: return .denied
        case errSecInteractionNotAllowed: return .interactionRequired
        case errSecDecode, errSecParam: return .invalid
        default: return .unavailable
        }
    }
    private func permitted(_ ref: NativeKeyReference, _ context: CallerContext) async -> Bool {
        guard ref.version > 0, ref.keyID != UUID(uuidString: "00000000-0000-0000-0000-000000000000"),
              context.scope == .persistent(ref.profile), context.run == run else { return false }
        return await authority.permits(context, scope: context.scope, run: run)
    }
    public func create(_ ref: NativeKeyReference, context: CallerContext) async throws {
        guard await permitted(ref, context) else { throw KeyFailure.denied }
        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .userPresence, &error) else { throw KeyFailure.unavailable }
        var bytes = Data(count: 32)
        let status = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
        guard status == errSecSuccess else { throw KeyFailure.rngFailure }
        defer { bytes.resetBytes(in: 0..<bytes.count) }
        var q = query(ref); q[kSecAttrAccessControl as String] = access; q[kSecValueData as String] = bytes
        let result = SecItemAdd(q as CFDictionary, nil)
        lastOSStatus = result
        guard result == errSecSuccess else { throw Self.classify(result) }
    }
    public func acquire(_ ref: NativeKeyReference, context: CallerContext, interactive: Bool) async throws -> KeyLease {
        guard await permitted(ref, context), entries.count < 128 else { throw KeyFailure.denied }
        let epoch = epochs[ref.profile, default: 1]
        let authentication = LAContext(); authentication.interactionNotAllowed = !interactive
        authentication.localizedReason = "Unlock this Vezham profile"
        var q = query(ref); q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        q[kSecUseAuthenticationContext as String] = authentication
        var value: CFTypeRef?
        let result = SecItemCopyMatching(q as CFDictionary, &value)
        lastOSStatus = result
        guard result == errSecSuccess else { authentication.invalidate(); throw Self.classify(result) }
        guard var bytes = value as? Data else { authentication.invalidate(); throw KeyFailure.invalid }
        defer { bytes.resetBytes(in: 0..<bytes.count) }
        guard bytes.count == 32 else { authentication.invalidate(); throw KeyFailure.invalid }
        guard await permitted(ref, context), epochs[ref.profile, default: 1] == epoch,
              entries.count < 128 else {
            authentication.invalidate()
            throw KeyFailure.stale
        }
        let lease = KeyLease(id: try ResourceID(UUID().uuidString), profile: ref.profile, run: run, epoch: epoch)
        entries[lease.id] = Entry(lease: lease, reference: ref, caller: context,
                                  secret: SecretBuffer(bytes), authentication: authentication)
        return lease
    }
    public func revoke(_ profile: ProfileID) {
        epochs[profile, default: 1] += 1
        for key in Array(entries.keys) where entries[key]?.reference.profile == profile { entries[key]?.authentication.invalidate(); entries.removeValue(forKey: key) }
    }
    public func hasActiveLease(_ profile: ProfileID) -> Bool { entries.values.contains { $0.reference.profile == profile } }
    public func remove(_ ref: NativeKeyReference, context: CallerContext) async throws {
        guard await permitted(ref, context) else { throw KeyFailure.denied }
        revoke(ref.profile)
        let status = SecItemDelete(query(ref) as CFDictionary)
        lastOSStatus = status
        guard status == errSecSuccess || status == errSecItemNotFound else { throw Self.classify(status) }
    }
    public func exists(_ ref: NativeKeyReference, context: CallerContext) async throws -> Bool {
        guard await permitted(ref, context) else { throw KeyFailure.denied }
        var q = query(ref);q[kSecReturnAttributes as String] = true;q[kSecMatchLimit as String] = kSecMatchLimitOne
        let c = LAContext(); c.interactionNotAllowed = true;q[kSecUseAuthenticationContext as String] = c
        var v: CFTypeRef?; let result = SecItemCopyMatching(q as CFDictionary, &v);c.invalidate()
        lastOSStatus = result
        if result == errSecItemNotFound { return false }
        guard result == errSecSuccess else { throw Self.classify(result) };return true
    }
    // Crypto remains inside the native broker. Check the exact caller grant
    // before using a lease and recheck the local epoch after actor suspension.
    func seal(_ plaintext: Data, lease: KeyLease, aad: Data) async throws -> Data {
        guard let candidate = entries[lease.id], candidate.lease == lease else { throw KeyFailure.stale }
        guard await permitted(candidate.reference, candidate.caller),
              let current = entries[lease.id], current.lease == lease,
              epochs[lease.profile, default: 1] == lease.epoch else {
            entries.removeValue(forKey: lease.id)?.authentication.invalidate()
            throw KeyFailure.stale
        }
        guard let bytes = try AES.GCM.seal(plaintext, using: current.secret.symmetricKey(),
                                           authenticating: aad).combined else { throw KeyFailure.invalid }
        return bytes
    }
}

@MainActor public final class NativeProfileAuthentication: ProfileAuthenticationPort {
    public init() {}
    public func authenticate(_ profile: ProfileID) async -> Bool {
        let context = LAContext(); defer { context.invalidate() }
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        do { return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock this Vezham profile") }
        catch { return false }
    }
}
