import Foundation
import AppIntents

/// Shared plumbing for the Lock Screen control + widgets that jump straight into
/// the camera. The control/widget run in a separate process, so they signal the
/// main app through a flag in the shared App Group; the app consumes it on
/// becoming active and opens the camera.
///
/// NB: add this file to BOTH the app target and the widget-extension target.
enum QuickCapture {
    static let appGroup = "group.com.samiabdulnour.archive"
    private static let pendingKey = "pendingOpenCamera"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    /// Called from the control/widget intent — asks the app to open the camera.
    static func requestCamera() { defaults?.set(true, forKey: pendingKey) }

    /// Called by the app on activation — returns true once, then clears.
    static func consumeCameraRequest() -> Bool {
        guard let d = defaults, d.bool(forKey: pendingKey) else { return false }
        d.set(false, forKey: pendingKey)
        return true
    }
}

/// Opens Archi.vé and starts capturing. Used by the Lock Screen control and the
/// Home/Lock Screen widgets.
struct OpenCameraIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Camera"
    static var description = IntentDescription("Open Archi.vé and start capturing.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickCapture.requestCamera()
        return .result()
    }
}
