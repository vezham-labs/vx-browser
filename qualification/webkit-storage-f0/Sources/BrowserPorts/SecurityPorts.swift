import BrowserDomain

public protocol ProfileKeyPort: Sendable {
    func revoke(_ profile: ProfileID) async
    func hasActiveLease(_ profile: ProfileID) async -> Bool
}
public protocol ProfileBarrierPort: Sendable {
    func fence(_ profile: ProfileID) async
    func retireResources(_ profile: ProfileID) async -> ProviderOutcome
    func reconcileForUnlock(_ profile: ProfileID) async -> Bool
    func restoreAdmission(_ profile: ProfileID) async
}
public protocol ProfileAuthenticationPort: Sendable {
    func authenticate(_ profile: ProfileID) async -> Bool
}
