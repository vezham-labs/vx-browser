import AppKit
import WebKit
import AVFoundation
import BrowserDomain
import BrowserCore

@MainActor public final class NativePermissionMediator {
    private let policy: PermissionCoordinator
    private let authority: NativeHostAuthority
    private let run: RunID
    init(policy: PermissionCoordinator, authority: NativeHostAuthority, run: RunID) { self.policy = policy; self.authority = authority; self.run = run }
    public static func nativeStatus(_ kind: PermissionKind) -> NativeAuthorization {
        func status(_ media: AVMediaType) -> NativeAuthorization {
            switch AVCaptureDevice.authorizationStatus(for: media) {
            case .authorized: return .authorized
            case .notDetermined: return .notDetermined
            case .denied, .restricted: return .denied
            @unknown default: return .unavailable
            }
        }
        switch kind {
        case .camera: return status(.video)
        case .microphone: return status(.audio)
        case .cameraAndMicrophone:
            let a = status(.video), b = status(.audio)
            return a == .authorized && b == .authorized ? .authorized : a == .denied || b == .denied ? .denied : .notDetermined
        default: return .unavailable
        }
    }
    func request(scope: Scope, view: ViewID, generation: UInt64, origin: VerifiedOrigin,
                 kind: PermissionKind, surface: WKWebView, stillCurrent: @escaping @MainActor () -> Bool) async -> WKPermissionDecision {
        guard stillCurrent(), let context = await authority.current(scope) else { return .deny }
        let status = Self.nativeStatus(kind)
        let purposes: [String] = switch kind {
        case .camera: ["NSCameraUsageDescription"]
        case .microphone: ["NSMicrophoneUsageDescription"]
        case .cameraAndMicrophone: ["NSCameraUsageDescription", "NSMicrophoneUsageDescription"]
        default: []
        }
        let supported = !purposes.isEmpty && purposes.allSatisfy {
            Bundle.main.object(forInfoDictionaryKey: $0) != nil
        } && status == .authorized
        guard let id = try? OperationID(UUID().uuidString) else { return .deny }
        let request = PermissionRequest(id: id, context: context, view: view,
                                        viewGeneration: generation, origin: origin, kind: kind)
        let evaluation = await policy.evaluate(request, supported: supported, native: status)
        if evaluation.decision != .ask {
            return stillCurrent() && evaluation.decision == .allow ? .grant : .deny
        }
        guard let ticket = evaluation.ticket else { return .deny }
        guard stillCurrent(), let window = surface.window else {
            await policy.cancel(ticket)
            return .deny
        }
        let alert = NSAlert(); alert.messageText = "Allow this site to use \(kind.rawValue)?"
        alert.informativeText = "This decision applies only to this browser session."
        alert.addButton(withTitle: "Don’t Allow"); alert.addButton(withTitle: "Allow Once")
        let choice = await withCheckedContinuation { c in alert.beginSheetModal(for: window) { c.resume(returning: $0 == .alertSecondButtonReturn) } }
        guard stillCurrent() else {
            await policy.cancel(ticket)
            return .deny
        }
        let decision = await policy.decide(ticket, choice: choice ? .allow : .deny, lifetime: .once, native: Self.nativeStatus(kind))
        return stillCurrent() && decision == .allow ? .grant : .deny
    }
}
