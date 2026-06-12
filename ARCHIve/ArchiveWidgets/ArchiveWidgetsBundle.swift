import WidgetKit
import SwiftUI

@main
struct ArchiveWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ArchiveLaunchWidget()
        if #available(iOS 18.0, *) {
            ArchiveWidgetsControl()
        }
    }
}
