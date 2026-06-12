import AppIntents
import SwiftUI
import WidgetKit

/// Lock Screen / Control Center / Action Button control that opens Archi.vé
/// straight into the camera. (iOS 18+.)
@available(iOS 18.0, *)
struct ArchiveWidgetsControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.samiabdulnour.archive.OpenCamera") {
            ControlWidgetButton(action: OpenCameraIntent()) {
                Label("Capture", systemImage: "camera.aperture")
            }
        }
        .displayName("Archi.vé Camera")
        .description("Open Archi.vé and start capturing.")
    }
}
