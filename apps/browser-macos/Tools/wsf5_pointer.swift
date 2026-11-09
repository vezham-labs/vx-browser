// Owner-authorized, disposable WS-F5 primary-button input. Never prompts for access.
import AppKit
import ApplicationServices

@main
struct PrimaryPointer {
    @MainActor static func main() {
        let a = Array(CommandLine.arguments.dropFirst())
        guard a.count == 6, let pid = Int32(a[0]), let id = UInt32(a[1]),
              let x1 = Double(a[2]), let y1 = Double(a[3]), let x2 = Double(a[4]), let y2 = Double(a[5]),
              let app = NSRunningApplication(processIdentifier: pid),
              app.bundleIdentifier == "internal.vezham.browser.wsf5.qualification",
              let windows = CGWindowListCopyWindowInfo(.optionIncludingWindow, id) as? [[String: Any]],
              let info = windows.first, info[kCGWindowOwnerPID as String] as? Int32 == pid,
              let raw = info[kCGWindowBounds as String] as? [String: Any],
              let bounds = CGRect(dictionaryRepresentation: raw as CFDictionary),
              [x1,y1,x2,y2].allSatisfy({ $0.isFinite }),
              x1 > 5, x2 > 5, y1 > 38, y2 > 38,
              x1 < bounds.width-5, x2 < bounds.width-5, y1 < bounds.height-5, y2 < bounds.height-5 else {
            print("BLOCKED: exact isolated app/window and contained finite points required"); exit(2)
        }
        guard AXIsProcessTrusted(), CGPreflightPostEventAccess() else {
            print("BLOCKED: existing OS input permission unavailable; no prompt or security-setting change requested"); exit(78)
        }
        guard app.activate(options: []) else {
            print("BLOCKED: target could not be activated"); exit(3)
        }
        Thread.sleep(forTimeInterval: 0.2)
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else {
            print("BLOCKED: isolated target is not frontmost"); exit(4)
        }
        let source = CGEventSource(stateID: .hidSystemState)
        func post(_ type: CGEventType, _ x: Double, _ y: Double) {
            let event = CGEvent(mouseEventSource: source, mouseType: type,
                                mouseCursorPosition: CGPoint(x: bounds.minX+x, y: bounds.minY+y), mouseButton: .left)!
            event.flags = []
            event.post(tap: .cghidEventTap)
        }
        post(.mouseMoved,x1,y1); Thread.sleep(forTimeInterval: 0.1)
        post(.leftMouseDown,x1,y1); Thread.sleep(forTimeInterval: 0.25)
        for step in 1...40 {
            let t = Double(step)/40
            post(.leftMouseDragged,x1+(x2-x1)*t,y1+(y2-y1)*t)
            Thread.sleep(forTimeInterval: 0.025)
        }
        Thread.sleep(forTimeInterval: 0.2); post(.leftMouseUp,x2,y2)
        print("PRIMARY_DRAG_POSTED pid=\(pid) window=\(id) from=\(x1),\(y1) to=\(x2),\(y2). Requires observed native outcome; posting alone is not a pass.")
    }
}
