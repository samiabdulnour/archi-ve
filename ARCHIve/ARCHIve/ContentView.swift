import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Photo.createdAt, order: .reverse) private var photos: [Photo]
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "camera.aperture")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(.secondary)
                Text("ARCHI-ve")
                    .font(.largeTitle.weight(.semibold))
                Text("\(photos.count) photo\(photos.count == 1 ? "" : "s") archived")
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showCamera = true
                } label: {
                    Label("Capture", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Photo.self, inMemory: true)
}
