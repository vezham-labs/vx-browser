import Foundation
import Testing
import BrowserDomain
import BrowserPersistence
@testable import BrowserNativeStorage

private func id<T>() -> ID<T> { try! ID(UUID().uuidString) }
@Test("F2-CON-007 canonical CBOR rejects duplicate noncanonical indefinite and trailing input")
func cbor() throws {
    let value = CBOR.map([0:.uint(42),1:.bytes(Data([1,2])),2:.array([.text("scope"),.uint(1)])])
    #expect(try CBOR.decode(value.encoded()) == value)
    for malformed in [Data([0x18,0x01]),Data([0xa2,0,1,0,2]),Data([0x9f,0xff]),Data([1,0]),Data([0x58,0xff]),Data(repeating:0,count:8*1024*1024+1)] {
        #expect(throws: (any Error).self) { try CBOR.decode(malformed) }
    }
}
@Test("F2-CON-008 backup rejects private duplicate oversized future or conflicting records")
func backupLimits() throws {
    let p:ProfileID = id(),record = try OwnedRecord(id:id(),category:.bookmarks,payload:Data([1]))
    #expect(throws: (any Error).self) { try OwnedBackupSnapshot(scope:.privateSession(id()),generation:1,deletionEpoch:1,records:[record]) }
    #expect(throws: (any Error).self) { try OwnedBackupSnapshot(scope:.persistent(p),generation:1,deletionEpoch:1,records:[record,record]) }
    #expect(throws: (any Error).self) { try OwnedRecord(id:id(),category:.history,payload:Data(count:65537)) }
    let s = try OwnedBackupSnapshot(scope:.persistent(p),generation:1,deletionEpoch:2,records:[record])
    #expect(throws: FailureCode.destinationConflict) { try s.restoring(expectedProfile:id(),knowledge:DeletionKnowledge(epoch:2,deleted:[],complete:true),unknownLineageConfirmed:false,destinationExists:false) }
    #expect(throws: FailureCode.confirmationRequired) { try s.restoring(expectedProfile:p,knowledge:DeletionKnowledge(epoch:1,deleted:[],complete:true),unknownLineageConfirmed:false,destinationExists:false) }
}
@Test("F2-CON-009 restore omits native grants respects deletion and requires explicit unknown lineage")
func deletion() throws {
    let p:ProfileID = id(),history:ResourceID = id(),bookmark:ResourceID = id()
    let records = try [OwnedRecord(id:history,category:.history,payload:Data([1])),OwnedRecord(id:bookmark,category:.bookmarks,payload:Data([2])),OwnedRecord(id:id(),category:.permissions,payload:Data([3]))]
    let s = try OwnedBackupSnapshot(scope:.persistent(p),generation:1,deletionEpoch:1,records:records)
    let result = try s.restoring(expectedProfile:p,knowledge:DeletionKnowledge(epoch:2,deleted:[history],complete:false),unknownLineageConfirmed:true,destinationExists:false)
    #expect(result.map(\.id) == [bookmark])
}
@Test("F2-CON-010 catalog descriptor scope label and publication gates")
func catalogValidation() throws {
    let ns:NamespaceID = id(),d = try StorageDescriptor(namespace:ns,profile:id(),store:id(),operation:id(),timestamp:1)
    try CatalogSchema.validateRecord(d,label:"Synthetic",expectedNamespace:ns)
    #expect(throws: (any Error).self) { try CatalogSchema.validateRecord(d,label:"",expectedNamespace:ns) }
    #expect(throws: (any Error).self) { try CatalogSchema.validateRecord(d,label:"Synthetic",expectedNamespace:id()) }
    for values in [(false,true,true),(true,false,true),(true,true,false)] {
        #expect(!CatalogSchema.mayPublish(expectedRevision:1,actualRevision:1,journalStable:values.0,keyAuthenticated:values.1,engineReady:values.2))
    }
}
