import Testing
import BrowserDomain

@Suite("WS-F0 identity contracts", .serialized)
struct IdentityTests {
    @Test("F0-ID-001 malformed and zero identifiers are rejected")
    func invalidIdentifiers() {
        #expect(throws: FailureCode.invalidIdentity) { try ProfileID("not-an-id") }
        #expect(throws: FailureCode.invalidIdentity) { try StoreID("00000000-0000-0000-0000-000000000000") }
    }
}
