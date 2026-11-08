// VALIDATION-ONLY: transient synthetic keys; no Keychain, database, app identity or secret output.
import Foundation
import CryptoKit

enum Invalid: Error { case format, limit, identity, version, missingKey }
indirect enum CB: Equatable {
    case uint(UInt64), bytes(Data), text(String), array([CB]), map([UInt64:CB])
}
func head(_ major:UInt8,_ v:UInt64)->Data {
    if v<24{return Data([major<<5|UInt8(v)])}
    let n=v<=255 ? 1 : v<=65535 ? 2 : v<=UInt64(UInt32.max) ? 4 : 8
    let ai:UInt8=n==1 ? 24:n==2 ? 25:n==4 ? 26:27
    return Data([major<<5|ai]+(0..<n).reversed().map{UInt8(truncatingIfNeeded:v>>($0*8))})
}
func enc(_ x:CB)->Data {
    switch x {
    case .uint(let v):return head(0,v)
    case .bytes(let d):return head(2,UInt64(d.count))+d
    case .text(let s):let d=Data(s.utf8);return head(3,UInt64(d.count))+d
    case .array(let a):return head(4,UInt64(a.count))+a.reduce(Data()){$0+enc($1)}
    case .map(let d):return head(5,UInt64(d.count))+d.keys.sorted().reduce(Data()){$0+enc(.uint($1))+enc(d[$1]!)}
    }
}
struct Decoder {
    let d:[UInt8];var p=0
    mutating func byte() throws->UInt8 {guard p<d.count else{throw Invalid.format};defer{p+=1};return d[p]}
    mutating func node(_ depth:Int=0) throws->CB {
        guard depth<=8 else{throw Invalid.limit}
        let b=try byte(),major=b>>5,ai=b&31
        let v:UInt64
        if ai<24{v=UInt64(ai)}else{
            guard [24,25,26,27].contains(ai) else{throw Invalid.format}
            let n=1<<Int(ai-24);var t:UInt64=0
            for _ in 0..<n{t=(t<<8)|UInt64(try byte())}
            guard (n==1 && t>=24)||(n==2 && t>255)||(n==4 && t>65535)||(n==8 && t>UInt64(UInt32.max)) else{throw Invalid.format};v=t
        }
        if major==0{return .uint(v)}
        guard v<=1_048_576 else{throw Invalid.limit}
        let n=Int(v)
        if major==2 || major==3 {
            guard n<=d.count-p else{throw Invalid.format};let bytes=Data(d[p..<p+n]);p+=n
            if major==2{return .bytes(bytes)}
            guard let s=String(data:bytes,encoding:.utf8) else{throw Invalid.format};return .text(s)
        }
        guard n<=64 else{throw Invalid.limit}
        if major==4 {var a:[CB]=[];for _ in 0..<n{a.append(try node(depth+1))};return .array(a)}
        if major==5 {
            var m:[UInt64:CB]=[:];var last:UInt64?
            for _ in 0..<n{guard case .uint(let key)=try node(depth+1),last==nil || key>last! else{throw Invalid.format};m[key]=try node(depth+1);last=key}
            return .map(m)
        }
        throw Invalid.format
    }
}
func decode(_ d:Data)throws->CB{guard d.count<=1_048_576 else{throw Invalid.limit};var p=Decoder(d:Array(d));let x=try p.node();guard p.p==d.count,enc(x)==d else{throw Invalid.format};return x}
func random(_ count:Int)->Data{SymmetricKey(size:SymmetricKeySize(bitCount:count*8)).withUnsafeBytes{Data($0)}}
func base32(_ d:Data)->String {
    let a=Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".utf8);var acc:UInt64=0,bits=0;var out:[UInt8]=[]
    for b in d{acc=(acc<<8)|UInt64(b);bits+=8;while bits>=5{bits-=5;out.append(a[Int((acc>>bits)&31)])};acc &= bits==0 ? 0:((1<<bits)-1)}
    if bits>0{out.append(a[Int((acc<<(5-bits))&31)])};return String(bytes:out,encoding:.ascii)!
}
func unbase32(_ s:String)throws->Data{
    let alphabet=Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".utf8);let normalized=s.uppercased().filter{!$0.isWhitespace && $0 != "-"}
    var acc:UInt64=0,bits=0;var out:[UInt8]=[]
    for b in normalized.utf8{guard let v=alphabet.firstIndex(of:b) else{throw Invalid.format};acc=(acc<<5)|UInt64(v);bits+=5;if bits>=8{bits-=8;out.append(UInt8(truncatingIfNeeded:acc>>bits))};acc &= bits==0 ? 0:((1<<bits)-1)}
    guard acc==0,base32(Data(out))==normalized else{throw Invalid.format};return Data(out)
}
func checksum(_ scope:Data,_ generation:UInt64,_ r:Data)->String {base32(Data(SHA256.hash(data:enc(.array([.uint(1),.uint(0),.bytes(scope),.uint(generation),.bytes(r)]))).prefix(5)))}
func bytes(_ m:[UInt64:CB],_ k:UInt64,_ count:Int?=nil)throws->Data{guard case .bytes(let d)=m[k],count==nil || d.count==count else{throw Invalid.format};return d}
func num(_ m:[UInt64:CB],_ k:UInt64)throws->UInt64{guard case .uint(let n)=m[k] else{throw Invalid.format};return n}
func derive(_ root:Data,_ m:[UInt64:CB])throws->SymmetricKey {
    let info=enc(.array([.text("VX-M1-WRAP-1"),.map(m.filter{$0.key<=6})]))
    return HKDF<SHA256>.deriveKey(inputKeyMaterial:SymmetricKey(data:root),salt:try bytes(m,7,32),info:info,outputByteCount:32)
}
func makeSlot(_ secret:Data,_ scope:Data,_ payload:CB,_ kind:UInt64=1)throws->[UInt64:CB]{
    let plain=enc(payload),nonce=AES.GCM.Nonce();let nd=nonce.withUnsafeBytes{Data($0)}
    var m:[UInt64:CB]=[0:.uint(kind),1:.uint(1),2:.bytes(scope),3:.uint(1),4:.uint(1),5:.uint(1),6:.bytes(random(16)),7:.bytes(random(32)),8:.bytes(nd),9:.uint(UInt64(plain.count))]
    let box=try AES.GCM.seal(plain,using:derive(secret,m),nonce:nonce,authenticating:enc(.array([.uint(1),.uint(0),.uint(1),.map(m)])))
    m[10] = .bytes(box.ciphertext);m[11] = .bytes(box.tag);return m
}
func openSlot(_ secret:Data,_ m:[UInt64:CB],_ scope:Data,_ expectedKind:UInt64=1)throws->CB{
    guard Set(m.keys)==Set(0...11),try num(m,0)==expectedKind,try num(m,1)<=1,try bytes(m,2,16)==scope else{throw Invalid.identity}
    for k:UInt64 in [3,4,5]{guard try num(m,k)>0 else{throw Invalid.version}}
    _=try bytes(m,6,16);let c=try bytes(m,10),n=try num(m,9);guard n<=1_048_576,UInt64(c.count)==n else{throw Invalid.limit}
    let key=try derive(secret,m),nonce=try AES.GCM.Nonce(data:bytes(m,8,12)),tag=try bytes(m,11,16)
    let plain=try AES.GCM.open(AES.GCM.SealedBox(nonce:nonce,ciphertext:c,tag:tag),using:key,authenticating:enc(.array([.uint(1),.uint(0),.uint(1),.map(m.filter{$0.key<=9})])))
    let p=try decode(plain);guard case .map(let pm)=p,try bytes(pm,0,16)==scope,try num(pm,1)==num(m,3),try num(pm,2)==num(m,4),case .array(let entries)=pm[3],!entries.isEmpty else{throw Invalid.identity}
    var versions=Set<UInt64>()
    for item in entries{guard case .map(let x)=item,Set(x.keys)==Set(0...3),try num(x,0)>0,try num(x,2)==1,try num(x,3)>0 else{throw Invalid.format};_=try bytes(x,1,32);guard versions.insert(try num(x,0)).inserted else{throw Invalid.format}}
    guard versions.contains(try num(pm,2)) else{throw Invalid.missingKey};return p
}
func recoveryFile(_ slot:[UInt64:CB])->CB{.map([0:.bytes(Data("VXRF".utf8)),1:.uint(1),2:.uint(0),3:.map(slot)])}
func readRecovery(_ d:Data,_ secret:Data,_ scope:Data)throws->CB{
    guard case .map(let m)=try decode(d),Set(m.keys)==Set(0...3),try bytes(m,0)==Data("VXRF".utf8),try num(m,1)==1,try num(m,2)==0,case .map(let s)=m[3] else{throw Invalid.version}
    return try openSlot(secret,s,scope)
}
var checks:[[String:Any]]=[]
@MainActor func record(_ label:String,_ ok:Bool){checks.append(["observation":label,"satisfied":ok]);print("VX_OBSERVATION "+label+" "+String(ok));fflush(stdout)}
@MainActor func rejects(_ label:String,_ f:()throws->Void){do{try f();record(label,false)}catch{record(label,true)}}

do {
    print("VX_PHASE synthetic-key-generation");fflush(stdout)
    let scope=random(16),r=random(32),dek=random(32)
    let payload:CB = .map([0:.bytes(scope),1:.uint(1),2:.uint(1),3:.array([.map([0:.uint(1),1:.bytes(dek),2:.uint(1),3:.uint(1)])])])
    print("VX_PHASE envelope-construction");fflush(stdout)
    let slot=try makeSlot(r,scope,payload),file=enc(recoveryFile(slot))
    print("VX_PHASE authentication-and-parser-controls");fflush(stdout)
    record("platform AEAD roundtrip and scope validation",try readRecovery(file,r,scope)==payload)
    record("canonical codec roundtrip",try decode(file)==recoveryFile(slot))
    rejects("wrong recovery secret rejected"){_=try readRecovery(file,random(32),scope)}
    rejects("wrong profile identity rejected"){_=try readRecovery(file,r,random(16))}
    rejects("catalog/profile kind mismatch rejected"){_=try openSlot(r,slot,scope,0)}
    var changed=slot;var tag=try bytes(slot,11);tag[tag.startIndex]^=1;changed[11] = .bytes(tag)
    rejects("modified tag rejected"){_=try readRecovery(enc(recoveryFile(changed)),r,scope)}
    changed=slot;var cipher=try bytes(slot,10);cipher[cipher.startIndex]^=1;changed[10] = .bytes(cipher)
    rejects("modified ciphertext rejected"){_=try readRecovery(enc(recoveryFile(changed)),r,scope)}
    changed=slot;changed[5] = .uint(2)
    rejects("AAD generation modification rejected"){_=try readRecovery(enc(recoveryFile(changed)),r,scope)}
    changed=slot;changed[6] = .bytes(random(16))
    rejects("HKDF purpose/key identifier modification rejected"){_=try readRecovery(enc(recoveryFile(changed)),r,scope)}
    rejects("truncated capsule rejected"){_=try readRecovery(file.dropLast(),r,scope)}
    let unsupported:CB = .map([0:.bytes(Data("VXRF".utf8)),1:.uint(2),2:.uint(0),3:.map(slot)])
    rejects("unsupported format rejected"){_=try readRecovery(enc(unsupported),r,scope)}
    changed=slot;changed[12] = .uint(2)
    rejects("unknown algorithm/critical slot field rejected"){_=try readRecovery(enc(recoveryFile(changed)),r,scope)}
    let missing:CB = .map([0:.bytes(scope),1:.uint(1),2:.uint(1),3:.array([.map([0:.uint(2),1:.bytes(dek),2:.uint(1),3:.uint(1)])])])
    let missingSlot=try makeSlot(r,scope,missing)
    rejects("missing current key version rejected"){_=try readRecovery(enc(recoveryFile(missingSlot)),r,scope)}
    rejects("noncanonical integer rejected"){_=try decode(Data([0x18,0x01]))}
    rejects("duplicate CBOR map key rejected"){_=try decode(Data([0xa2,0x00,0x01,0x00,0x02]))}
    rejects("indefinite CBOR container rejected"){_=try decode(Data([0x9f,0xff]))}
    rejects("oversized input rejected"){_=try decode(Data(repeating:0,count:1_048_577))}
    rejects("excessive nesting rejected"){_=try decode(Data(repeating:0x81,count:10)+Data([0]))}
    rejects("trailing bytes rejected"){_=try decode(file+Data([0]))}
    let keyString=base32(r),paperCapsule=base32(file),paperChecksum=checksum(scope,1,r)
    let readKey=try unbase32(keyString),readCapsule=try unbase32(paperCapsule)
    record("printable 256-bit encoding length",keyString.count==52 && paperChecksum.count==8)
    let paperPayload=try readRecovery(readCapsule,readKey,scope)
    record("printable/file in-memory interoperability",readKey==r && readCapsule==file && paperPayload==payload)
    record("printable checksum verifies locally",checksum(scope,1,readKey)==paperChecksum)
    rejects("printable invalid alphabet rejected"){_=try unbase32("0"+keyString)}
    rejects("printable nonzero padding bits rejected"){_=try unbase32(String(keyString.dropLast())+"B")}
    // Real file readback contains only encrypted capsule. R/key never leaves memory.
    let tmp=URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("vx-recovery-capsule-"+UUID().uuidString)
    defer {try? FileManager.default.removeItem(at:tmp)}
    try file.write(to:tmp,options:.atomic);try FileManager.default.setAttributes([.posixPermissions:0o600],ofItemAtPath:tmp.path)
    let back=try Data(contentsOf:tmp)
    record("encrypted recovery-file readback authentication",try readRecovery(back,r,scope)==payload)
    let transient=try FileManager.default.attributesOfItem(atPath:tmp.path)[.posixPermissions] as? Int
    record("transient encrypted file mode0600",transient==0o600)
    // Public non-secret CBOR structure can be cross-decoded independently; no key/envelope bytes exposed.
    let publicStructure:CB = .map([0:.text("VX-M1-STRUCTURE-ONLY"),1:.uint(1),2:.bytes(Data([1,2,3])),3:.array([.uint(23),.uint(24),.uint(256)])])
    let result:[String:Any]=["scope":"isolated format/AEAD synthetic observations only","checks":checks,"all_observations_satisfied":checks.allSatisfy{$0["satisfied"] as? Bool == true},"public_structure_cbor_hex":enc(publicStructure).map{String(format:"%02x",$0)}.joined(),"secret_or_key_hash_output":false,"native_keychain_test":false,"database_restore_test":false,"cross_mac_recovery":false,"EXP04_qualified":false]
    print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
} catch {
    // Coarse error only; never dump the exception's underlying crypto/key payload.
    print("{\"fixture_runner_error\":true,\"secret_or_key_hash_output\":false,\"EXP04_qualified\":false}")
    exit(1)
}
