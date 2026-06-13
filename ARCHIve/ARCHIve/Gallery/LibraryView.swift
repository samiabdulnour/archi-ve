import SwiftUI
import SwiftData
import Photos

/// Browse the system Photos library and tag photos *in place* — the app stores a
/// reference (the asset's id) plus your tags, with **no copy**. Already-tagged
/// photos show a check; tapping one re-opens its tags.
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allPhotos: [Photo]

    @State private var status: PHAuthorizationStatus = PhotosLibrary.status
    @State private var assets: [PHAsset] = []
    @State private var tagTarget: Photo?

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    private var referenced: [String: Photo] {
        var m: [String: Photo] = [:]
        for p in allPhotos { if let id = p.assetLocalID, !id.isEmpty { m[id] = p } }
        return m
    }

    var body: some View {
        NavigationStack {
            Group {
                switch status {
                case .authorized, .limited: grid
                case .denied, .restricted:  deniedView
                default: ProgressView()
                }
            }
            .navigationTitle("Tag from Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .background(Palette.paper.ignoresSafeArea())
        }
        .task { await loadAssets() }
        .fullScreenCover(item: $tagTarget, onDismiss: cleanupIfSkipped) { photo in
            TagSheetView(photo: photo) { tagTarget = nil }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: cols, spacing: 2) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    let existing = referenced[asset.localIdentifier]
                    Button { tap(asset, existing: existing) } label: {
                        LibraryCell(asset: asset, tagged: existing != nil)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
        }
    }

    private var deniedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.largeTitle).foregroundStyle(Palette.ink3)
            Text("Photos access is off").font(.headline)
            Text("Allow photo access to tag your existing library.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Open Settings") {
                if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) }
            }
            .buttonStyle(.borderedProminent).tint(Palette.coral)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadAssets() async {
        if status == .notDetermined { status = await PhotosLibrary.requestAuthorization() }
        guard status == .authorized || status == .limited else { return }
        let result = PhotosLibrary.fetchImages()
        var arr: [PHAsset] = []
        arr.reserveCapacity(result.count)
        result.enumerateObjects { a, _, _ in arr.append(a) }
        assets = arr
    }

    private func tap(_ asset: PHAsset, existing: Photo?) {
        if let existing { tagTarget = existing; return }
        let photo = Photo(imageData: Data(),
                          createdAt: asset.creationDate ?? .now,
                          latitude: asset.location?.coordinate.latitude,
                          longitude: asset.location?.coordinate.longitude,
                          assetLocalID: asset.localIdentifier)
        modelContext.insert(photo)
        tagTarget = photo
    }

    /// A reference left untagged means the user skipped — drop it.
    private func cleanupIfSkipped() {
        for p in allPhotos where p.isReference && p.isUntagged {
            modelContext.delete(p)
        }
        try? modelContext.save()
    }
}

private struct LibraryCell: View {
    let asset: PHAsset
    let tagged: Bool
    @State private var image: UIImage?

    var body: some View {
        // Color.clear forces a square sized to the cell width; the image fills it
        // and is clipped — a definite frame, so thumbnails never overflow.
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    Palette.tile
                    if let image { Image(uiImage: image).resizable().scaledToFill() }
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .overlay(alignment: .topTrailing) {
                if tagged {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, Palette.coral)
                        .padding(4).shadow(radius: 1)
                }
            }
            .task(id: asset.localIdentifier) {
                if image == nil { image = await PhotosLibrary.image(asset: asset, maxPixel: 400) }
            }
    }
}
