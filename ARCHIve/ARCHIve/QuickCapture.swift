import Foundation

/// App-side of the "jump to camera" plumbing. The Lock Screen control + widgets
/// (in the widget extension) set a flag in the shared App Group; the app reads
/// it on becoming active and opens the camera. The matching writer lives in the
/// widget target (it can't share this file under Xcode's synchronized folders).
enum QuickCapture {
    static let appGroup = "group.com.samiabdulnour.archive"
    private static let pendingKey = "pendingOpenCamera"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    /// Returns true once if the camera was requested, then clears the flag.
    static func consumeCameraRequest() -> Bool {
        guard let d = defaults, d.bool(forKey: pendingKey) else { return false }
        d.set(false, forKey: pendingKey)
        return true
    }
}
