import SwiftUI
import SwiftData

@main
struct ARCHIveApp: App {
    // SwiftData container holding the photo archive. Stored on-device only.
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Photo.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
