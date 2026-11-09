import Foundation
import CryptoKit
import Security
import Darwin
import BrowserDomain
import BrowserPersistence

/// Independent recovery authority held only in the native cryptographic boundary.
/// No printable kit/custody workflow is silently claimed complete by this handle.
public final class NativeBackupRecovery {
    private var secret: Data
    public init() throws { secret = try randomBytes(32) }
    deinit { secret.resetBytes(in: 0..<secret.count) }
    fileprivate func wrappingKey(salt: Data, context: Data) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(inputKeyMaterial: SymmetricKey(data: secret), salt: salt, info: context, outputByteCount: 32)
    }
}
private func randomBytes(_ count: Int) throws -> Data {
    var data = Data(count: count)
    guard data.withUnsafeMutableBytes({ SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!) }) == errSecSuccess else { throw KeyFailure.rngFailure }
    return data
}
private func uuidBytes(_ uuid: UUID) -> Data { var u = uuid.uuid;return withUnsafeBytes(of: &u) { Data($0) } }

/// Versioned provisional owned-data archive, not the production key-envelope format.
/// Outer CBOR authenticates scope/version/chunk ordering; all record metadata is encrypted.
public enum EncryptedOwnedBackup {
    private static func aad(_ header: CBOR, index: UInt64, count: UInt64, length: UInt64, kind: String) -> Data {
        CBOR.array([header,.uint(index),.uint(count),.uint(length),.text(kind)]).encoded()
    }
    public static func seal(_ snapshot: OwnedBackupSnapshot, recovery: NativeBackupRecovery) throws -> Data {
        try snapshot.validate()
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let payload = try encoder.encode(snapshot)
        guard payload.count <= 6 * 1024 * 1024 else { throw FailureCode.capacityExceeded }
        let archiveID = UUID(), salt = try randomBytes(32), prefix = try randomBytes(4)
        var contentBytes = try randomBytes(32);defer { contentBytes.resetBytes(in: 0..<contentBytes.count) }
        let key = SymmetricKey(data: contentBytes)
        let header = CBOR.map([0:.text("VXWSF2B"),1:.uint(1),2:.uint(1),3:.bytes(uuidBytes(archiveID)),
                               4:.bytes(uuidBytes(UUID(uuidString: snapshot.profile.rawValue)!)),5:.uint(snapshot.generation),6:.uint(UInt64(snapshot.schema)),7:.bytes(salt),8:.bytes(prefix)])
        let wrapInfo = CBOR.array([.text("VX-M1-ARCHIVE-WRAP-1"),header]).encoded()
        let wrapping = recovery.wrappingKey(salt: salt, context: wrapInfo)
        let wrapped = try AES.GCM.seal(contentBytes, using: wrapping, authenticating: header.encoded()).combined!
        func nonce(_ index: UInt64) throws -> AES.GCM.Nonce {
            var i = index.bigEndian
            return try AES.GCM.Nonce(data: prefix + withUnsafeBytes(of: &i) { Data($0) })
        }
        let manifest = CBOR.map([0:.uint(1),1:.uint(UInt64(payload.count)),2:.bytes(Data(SHA256.hash(data: payload))),3:.uint(snapshot.deletionEpoch),4:.array(Array(Set(snapshot.records.map { $0.category.rawValue })).sorted().map(CBOR.text))]).encoded()
        let m = try AES.GCM.seal(manifest, using: key, nonce: nonce(0), authenticating: aad(header,index:0,count:1,length:UInt64(manifest.count),kind:"manifest"))
        let chunk = try AES.GCM.seal(payload, using: key, nonce: nonce(1), authenticating: aad(header,index:1,count:1,length:UInt64(payload.count),kind:"records"))
        return CBOR.map([0:header,1:.bytes(wrapped),2:.uint(UInt64(manifest.count)),3:.bytes(m.ciphertext+m.tag),4:.uint(UInt64(payload.count)),5:.bytes(chunk.ciphertext+chunk.tag)]).encoded()
    }
    public static func open(_ archive: Data, expected: ProfileID, recovery: NativeBackupRecovery) throws -> OwnedBackupSnapshot {
        guard let outer = try CBOR.decode(archive).fields, Set(outer.keys) == Set(0...5),
              let header = outer[0], let h = header.fields, Set(h.keys) == Set(0...8),
              h[0] == .text("VXWSF2B"),h[1] == .uint(1),h[2] == .uint(1),h[3]?.data?.count == 16,
              h[4]?.data == uuidBytes(UUID(uuidString: expected.rawValue)!), let generation = h[5]?.number,generation > 0,
              h[6] == .uint(UInt64(CatalogSchema.version)),let salt = h[7]?.data,salt.count == 32,
              let prefix = h[8]?.data,prefix.count == 4,let wrapped = outer[1]?.data,wrapped.count == 60,
              let ml = outer[2]?.number,ml <= 65536,let mb = outer[3]?.data,mb.count == Int(ml)+16,
              let length = outer[4]?.number,length <= 6 * 1024 * 1024,let content = outer[5]?.data,content.count == Int(length)+16 else { throw FailureCode.corruptRecovery }
        let info = CBOR.array([.text("VX-M1-ARCHIVE-WRAP-1"),header]).encoded()
        var bytes = try AES.GCM.open(AES.GCM.SealedBox(combined: wrapped), using: recovery.wrappingKey(salt: salt, context: info), authenticating: header.encoded())
        defer { bytes.resetBytes(in: 0..<bytes.count) }
        guard bytes.count == 32 else { throw KeyFailure.invalid };let key = SymmetricKey(data: bytes)
        func decrypt(_ blob: Data, index: UInt64, length: UInt64, kind: String) throws -> Data {
            var i = index.bigEndian;let nonce = try AES.GCM.Nonce(data: prefix + withUnsafeBytes(of: &i) { Data($0) })
            let sealed = try AES.GCM.SealedBox(nonce: nonce,ciphertext:blob.dropLast(16),tag:blob.suffix(16))
            return try AES.GCM.open(sealed,using:key,authenticating:aad(header,index:index,count:1,length:length,kind:kind))
        }
        let manifest = try CBOR.decode(decrypt(mb,index:0,length:ml,kind:"manifest")).fields
        let payload = try decrypt(content,index:1,length:length,kind:"records")
        guard let manifest,Set(manifest.keys) == Set(0...4),manifest[0] == .uint(1),manifest[1] == .uint(length),manifest[2]?.data == Data(SHA256.hash(data:payload)) else { throw FailureCode.corruptRecovery }
        let snapshot = try JSONDecoder().decode(OwnedBackupSnapshot.self,from:payload);try snapshot.validate()
        guard snapshot.profile == expected,snapshot.generation == generation,manifest[3] == .uint(snapshot.deletionEpoch),
              manifest[4] == .array(Array(Set(snapshot.records.map { $0.category.rawValue })).sorted().map(CBOR.text)) else { throw FailureCode.reconciliationMismatch }
        return snapshot
    }
}

/// Native host selects a directory; no website/chrome path input. No overwrite or symlink traversal.
public final class NativeBackupFiles {
    private let directory: Int32
    public init(directory url: URL) throws {
        directory = Darwin.open(url.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
        guard directory >= 0 else { throw FailureCode.invalidConfiguration }
    }
    deinit { Darwin.close(directory) }
    public func publish(_ data: Data, id: UUID, interruptBeforePublish: Bool = false) throws {
        guard data.count <= 8 * 1024 * 1024 else { throw FailureCode.capacityExceeded }
        let name = id.uuidString.lowercased(), staged = name+".incomplete"
        let fd = openat(directory, staged, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, mode_t(0o600))
        guard fd >= 0 else { throw FailureCode.destinationConflict }
        defer { Darwin.close(fd) }
        try data.withUnsafeBytes { buffer in
            var offset = 0
            while offset < buffer.count {
                let n = Darwin.write(fd,buffer.baseAddress!.advanced(by:offset),buffer.count-offset)
                guard n > 0 else { throw FailureCode.providerUnavailable };offset += n
            }
        }
        guard fsync(fd) == 0 else { throw FailureCode.providerUnavailable }
        if interruptBeforePublish { throw FailureCode.interruptedOperation }
        guard linkat(directory,staged,directory,name+".vxbackup",0) == 0 else { throw FailureCode.destinationConflict }
        guard unlinkat(directory,staged,0) == 0,fsync(directory) == 0 else { throw FailureCode.observationUnknown }
    }
    public func read(_ id: UUID) throws -> Data {
        let fd = openat(directory,id.uuidString.lowercased()+".vxbackup",O_RDONLY | O_NOFOLLOW)
        guard fd >= 0 else { throw FailureCode.storeMissing };defer { Darwin.close(fd) }
        var stat = stat();guard fstat(fd,&stat) == 0,stat.st_mode & S_IFMT == S_IFREG,stat.st_size >= 0,stat.st_size <= 8*1024*1024 else { throw FailureCode.invalidConfiguration }
        var d = Data(count:Int(stat.st_size));let count = d.withUnsafeMutableBytes { Darwin.read(fd,$0.baseAddress, $0.count) }
        guard count == d.count else { throw FailureCode.corruptRecovery };return d
    }
}
