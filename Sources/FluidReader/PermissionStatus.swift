import ApplicationServices
import CoreGraphics

enum PermissionStatus {
    static func screenRecordingAllowed() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        }
        return true
    }

    static func requestScreenRecordingAccess() {
        if #available(macOS 10.15, *) {
            CGRequestScreenCaptureAccess()
        }
    }

    static func accessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }
}
