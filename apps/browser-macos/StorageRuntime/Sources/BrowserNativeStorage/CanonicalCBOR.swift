import Foundation
import BrowserDomain

/// Small closed CBOR subset for authenticated archive framing, not a generic decoder.
indirect enum CBOR: Equatable {
    case uint(UInt64), bytes(Data), text(String), array([CBOR]), map([UInt64: CBOR])
    private static func head(_ major: UInt8, _ n: UInt64) -> Data {
        if n < 24 { return Data([major << 5 | UInt8(n)]) }
        let count = n <= 255 ? 1 : n <= 65535 ? 2 : n <= UInt32.max ? 4 : 8
        var d = Data([major << 5 | (count == 1 ? 24 : count == 2 ? 25 : count == 4 ? 26 : 27)])
        for i in (0..<count).reversed() { d.append(UInt8(truncatingIfNeeded: n >> (i * 8))) }; return d
    }
    func encoded() -> Data {
        switch self {
        case .uint(let n): return Self.head(0,n)
        case .bytes(let d): return Self.head(2,UInt64(d.count)) + d
        case .text(let s): let d = Data(s.utf8); return Self.head(3,UInt64(d.count)) + d
        case .array(let a): return Self.head(4,UInt64(a.count)) + a.reduce(Data()) { $0 + $1.encoded() }
        case .map(let m): return Self.head(5,UInt64(m.count)) + m.keys.sorted().reduce(Data()) { $0 + CBOR.uint($1).encoded() + m[$1]!.encoded() }
        }
    }
    static func decode(_ data: Data) throws -> CBOR {
        guard data.count <= 8 * 1024 * 1024 else { throw FailureCode.capacityExceeded }
        var offset = 0
        func read(_ count: Int) throws -> Data {
            guard count >= 0, count <= data.count - offset else { throw FailureCode.corruptRecovery }
            let d = data.subdata(in: offset..<(offset+count));offset += count;return d
        }
        func value(_ depth: Int) throws -> CBOR {
            guard depth <= 8 else { throw FailureCode.corruptRecovery }
            let b = try read(1).first!, major = b >> 5, small = b & 31
            let n: UInt64
            if small < 24 { n = UInt64(small) }
            else {
                guard (24...27).contains(small) else { throw FailureCode.corruptRecovery }
                n = try read(1 << Int(small - 24)).reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
            }
            guard n <= 8 * 1024 * 1024 || major == 0 else { throw FailureCode.capacityExceeded }
            switch major {
            case 0: return .uint(n)
            case 2: return .bytes(try read(Int(n)))
            case 3: guard let s = String(data: try read(Int(n)), encoding: .utf8) else { throw FailureCode.corruptRecovery };return .text(s)
            case 4: guard n <= 4096 else { throw FailureCode.capacityExceeded };return .array(try (0..<Int(n)).map { _ in try value(depth+1) })
            case 5:
                guard n <= 64 else { throw FailureCode.capacityExceeded };var m: [UInt64: CBOR] = [:]
                for _ in 0..<Int(n) {
                    guard case .uint(let k) = try value(depth+1), m[k] == nil else { throw FailureCode.corruptRecovery }
                    m[k] = try value(depth+1)
                };return .map(m)
            default: throw FailureCode.corruptRecovery
            }
        }
        let result = try value(0)
        guard offset == data.count, result.encoded() == data else { throw FailureCode.corruptRecovery }
        return result
    }
    var number: UInt64? { if case .uint(let n) = self { n } else { nil } }
    var data: Data? { if case .bytes(let d) = self { d } else { nil } }
    var list: [CBOR]? { if case .array(let a) = self { a } else { nil } }
    var fields: [UInt64: CBOR]? { if case .map(let m) = self { m } else { nil } }
}
