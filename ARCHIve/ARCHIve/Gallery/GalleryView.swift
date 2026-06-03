import SwiftUI
import SwiftData
import MapKit

enum GalleryLens: String, CaseIterable, Identifiable {
    case time = "Time", reference = "Reference", project = "Project", map = "Map"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .time: return "clock"
        case .reference: return "square.grid.2x2"
        case .project: return "folder"
        case .map: return "map"
        }
    }
}

struct GalleryView: View {
    @Query(sort: \Photo.createdAt, order: .reverse) private var photos: [Photo]
    @State private var lens: GalleryLens = .time
    @State private var refType = "all"

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            lensPicker
            if photos.isEmpty {
                emptyState
            } else {
                switch lens {
                case .time:      timeLens
                case .reference: referenceLens
                case .project:   projectLens
                case .map:       MapLens(photos: photos.filter { $0.latitude != nil })
                }
            }
        }
    }

    // MARK: Lenses

    private var timeLens: some View {
        grid(photos)
    }

    private var referenceLens: some View {
        VStack(spacing: 0) {
            Picker("Type", selection: $refType) {
                Text("All").tag("all")
                ForEach(TagVocab.types) { Text($0.label).tag($0.id) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            grid(refType == "all" ? photos : photos.filter { $0.humanTags.type == refType })
        }
    }

    private var projectLens: some View {
        let groups = Dictionary(grouping: photos) { $0.project ?? "Unfiled" }
        let keys = groups.keys.sorted { a, b in
            if a == "Unfiled" { return false }
            if b == "Unfiled" { return true }
            return a < b
        }
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 18, pinnedViews: [.sectionHeaders]) {
                ForEach(keys, id: \.self) { key in
                    Section {
                        LazyVGrid(columns: cols, spacing: 2) {
                            ForEach(groups[key] ?? []) { cell($0) }
                        }
                    } header: {
                        Text(key)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.bar)
                    }
                }
            }
        }
    }

    // MARK: Pieces

    private func grid(_ items: [Photo]) -> some View {
        ScrollView {
            LazyVGrid(columns: cols, spacing: 2) {
                ForEach(items) { cell($0) }
            }
        }
    }

    private func cell(_ photo: Photo) -> some View {
        NavigationLink(value: photo) {
            PhotoThumbnail(photo: photo)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
        }
        .buttonStyle(.plain)
    }

    private var lensPicker: some View {
        Picker("Lens", selection: $lens) {
            ForEach(GalleryLens.allCases) { l in
                Label(l.rawValue, systemImage: l.symbol).tag(l)
            }
        }
        .pickerStyle(.segmented)
        .padding(12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "camera.aperture")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(.secondary)
            Text("ARCHI-ve").font(.largeTitle.weight(.semibold))
            Text("No photos yet").foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Thumbnail that decodes a downsampled image off the main thread.
struct PhotoThumbnail: View {
    let photo: Photo
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.secondarySystemBackground)
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .task(id: photo.id) {
                if image == nil {
                    image = await Self.thumbnail(from: photo.imageData, maxPixel: 400)
                }
            }
        }
    }

    static func thumbnail(from data: Data, maxPixel: CGFloat) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
            let opts: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            ]
            guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
            return UIImage(cgImage: cg)
        }.value
    }
}

/// Map lens — drops a pin for every located photo.
private struct MapLens: View {
    let photos: [Photo]

    var body: some View {
        if photos.isEmpty {
            ContentUnavailableView("No located photos", systemImage: "mappin.slash",
                                   description: Text("Photos you take with location on will appear here."))
        } else {
            Map {
                ForEach(photos) { photo in
                    if let lat = photo.latitude, let lon = photo.longitude {
                        Annotation("", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            NavigationLink(value: photo) {
                                PhotoThumbnail(photo: photo)
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white, lineWidth: 2))
                                    .shadow(radius: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
