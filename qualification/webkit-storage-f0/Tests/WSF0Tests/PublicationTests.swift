import Testing
import BrowserDomain
import BrowserCore

@Suite("F0 supporting publication policy only", .serialized)
struct PublicationTests {
    let valid = [SnapshotMember(.catalog, generation: 2, privacyEpoch: 4), SnapshotMember(.profile, generation: 2, privacyEpoch: 4), SnapshotMember(.engine, generation: 2, privacyEpoch: 4)]
    @Test("F0-PUB-001 missing or duplicate member blocks publication")
    func missing() {
        #expect(PublicationPolicy.evaluate(members: Array(valid.prefix(2)), expectedGeneration: 2, privacyEpoch: 4, destination: .freshStaging, lineage: .knownReconciled) == .blocked(.missingSnapshotMember))
        #expect(PublicationPolicy.evaluate(members: [valid[0], valid[1], valid[1]], expectedGeneration: 2, privacyEpoch: 4, destination: .freshStaging, lineage: .knownReconciled) == .blocked(.missingSnapshotMember))
    }
    @Test("F0-PUB-002 generation and privacy lineage must match")
    func generation() {
        #expect(PublicationPolicy.evaluate(members: valid, expectedGeneration: 3, privacyEpoch: 4, destination: .freshStaging, lineage: .knownReconciled) == .blocked(.inconsistentSnapshot))
        #expect(PublicationPolicy.evaluate(members: valid, expectedGeneration: 2, privacyEpoch: 5, destination: .freshStaging, lineage: .knownReconciled) == .blocked(.inconsistentSnapshot))
    }
    @Test("F0-PUB-003 active destination and unknown deletion coverage never silently restore")
    func conflicts() {
        #expect(PublicationPolicy.evaluate(members: valid, expectedGeneration: 2, privacyEpoch: 4, destination: .activeProfile, lineage: .knownReconciled) == .blocked(.destinationConflict))
        #expect(PublicationPolicy.evaluate(members: valid, expectedGeneration: 2, privacyEpoch: 4, destination: .freshStaging, lineage: .unknown) == .confirmationRequired)
        #expect(PublicationPolicy.evaluate(members: valid, expectedGeneration: 2, privacyEpoch: 4, destination: .freshStaging, lineage: .knownReconciled) == .allowed)
    }
}
