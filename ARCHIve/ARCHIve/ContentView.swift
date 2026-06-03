import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var photos: [Photo]
    @State private var showCamera = false
    @AppStorage("appearance") private var appearance = "auto"
    @AppStorage("welcomed") private var welcomed = false

    var body: some View {
        NavigationStack {
            GalleryView()
                .navigationTitle("ARCHI-ve")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Photo.self) { photo in
                    PhotoDetailView(photo: photo)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showCamera = true } label: {
                            Image(systemName: "camera.fill")
                        }
                    }
                    #if targetEnvironment(simulator)
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Seed") { seedSample() }
                    }
                    #endif
                }
                .safeAreaInset(edge: .bottom) {
                    Button { showCamera = true } label: {
                        Label("Capture", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
        .fullScreenCover(isPresented: Binding(get: { !welcomed }, set: { welcomed = !$0 })) {
            WelcomeView { welcomed = true }
        }
        .preferredColorScheme(Settings.colorScheme(for: appearance))
    }

    #if targetEnvironment(simulator)
    /// Inserts a few synthetic photos so the gallery / tagging / detail flows
    /// can be exercised on the simulator, which has no camera. Never compiled
    /// into a device build.
    private func seedSample() {
        let palette: [(UIColor, HumanTags, String?)] = [
            (.systemTeal,   buildingTags(),  "Aalto House"),
            (.systemBrown,  elementTags(),   nil),
            (.systemIndigo, graphicTags(),   "Aalto House"),
            (.systemGreen,  buildingTags(),  nil),
        ]
        for (i, item) in palette.enumerated() {
            guard let data = swatch(item.0) else { continue }
            let p = Photo(imageData: data,
                          createdAt: Date().addingTimeInterval(Double(-i) * 3600),
                          latitude: 60.20 + Double(i) * 0.01,
                          longitude: 24.86 + Double(i) * 0.01,
                          humanTags: item.1,
                          project: item.2)
            modelContext.insert(p)
        }
        try? modelContext.save()
    }

    private func buildingTags() -> HumanTags {
        var t = HumanTags(); t.type = "building"; t.typology = "Residential"
        t.room = "living"; t.concepts = ["light", "space"]; t.materials = ["Timber", "Glass"]
        t.authorYear = "Aalto, 1939"; return t
    }
    private func elementTags() -> HumanTags {
        var t = HumanTags(); t.type = "element"; t.element = "Stair"; t.materials = ["Concrete"]; return t
    }
    private func graphicTags() -> HumanTags {
        var t = HumanTags(); t.type = "graphic"; t.graphicKind = "drawing"; t.visual = ["Monochrome", "Minimal"]; return t
    }

    private func swatch(_ color: UIColor) -> Data? {
        let size = CGSize(width: 800, height: 1000)
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            color.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
        }.jpegData(compressionQuality: 0.8)
    }
    #endif
}

#Preview {
    ContentView()
        .modelContainer(for: Photo.self, inMemory: true)
}
