import SwiftUI
import SwiftData
import MapKit
import PhotosUI
import ImageIO

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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Photo.createdAt, order: .reverse) private var photos: [Photo]

    @State private var lens: GalleryLens = .time
    @State private var search = ""

    // Filters
    @State private var showFilter = false
    @State private var filterType: String?     // nil | "untagged" | building | element | graphic
    @State private var filterProject: String?

    // Selection
    @State private var selecting = false
    @State private var selected: Set<String> = []
    @State private var confirmDelete = false
    @State private var shareItems: [UIImage] = []
    @State private var showShare = false

    // Import
    @State private var importItems: [PhotosPickerItem] = []
    @State private var showImporter = false

    // Settings
    @State private var showSettings = false

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    // Time-grid zoom: pinch to change how many photos per row (1...5).
    @State private var gridCols = 3
    @State private var pinchBaseCols: Int?

    // MARK: Derived

    private var filtersActive: Bool { filterType != nil || filterProject != nil }

    private var filtered: [Photo] {
        let words = search.lowercased().split(separator: " ").map(String.init)
        return photos.filter { p in
            if !words.isEmpty {
                let txt = p.searchText
                if !words.allSatisfy({ txt.contains($0) }) { return false }
            }
            if let ft = filterType {
                if ft == "untagged" { if !p.isUntagged { return false } }
                else if p.humanTags.type != ft { return false }
            }
            if let fp = filterProject, p.project != fp { return false }
            return true
        }
    }

    private var projectNames: [String] {
        var seen = Set<String>(); var out: [String] = []
        for p in photos { if let n = p.project, !n.isEmpty, seen.insert(n).inserted { out.append(n) } }
        return Set(out).union(Settings.customProjects).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            lensPicker
            if photos.isEmpty {
                emptyState
            } else {
                if filtersActive || !search.isEmpty { resultBar }
                switch lens {
                case .time:      grid(filtered)
                case .reference: referenceLens
                case .project:   projectLens
                case .map:       MapLens(photos: filtered.filter { $0.latitude != nil }, selecting: false)
                }
            }
        }
        .background(Palette.paper.ignoresSafeArea())
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search")
        .toolbar { galleryToolbar }
        .safeAreaInset(edge: .bottom) { if selecting { selectionBar } }
        .sheet(isPresented: $showFilter) {
            FilterSheet(type: $filterType, project: $filterProject, projects: projectNames)
        }
        .confirmationDialog("Delete \(selected.count) photo\(selected.count == 1 ? "" : "s")?",
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This can't be undone.") }
        .sheet(isPresented: $showShare) { ActivityView(items: shareItems) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .photosPicker(isPresented: $showImporter, selection: $importItems, matching: .images)
        .onChange(of: importItems) { _, items in Task { await importPhotos(items) } }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var galleryToolbar: some ToolbarContent {
        if selecting {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") { selecting = false; selected.removeAll() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(allSelected ? "Deselect All" : "Select All") { toggleSelectAll() }
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showFilter = true } label: { Label("Filter", systemImage: "line.3.horizontal.decrease.circle") }
                    Button { showImporter = true } label: { Label("Import", systemImage: "square.and.arrow.down") }
                    Button { selecting = true } label: { Label("Select", systemImage: "checkmark.circle") }
                    Divider()
                    Button { showSettings = true } label: { Label("Settings", systemImage: "gearshape") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
    }

    private var allSelected: Bool { !filtered.isEmpty && selected.count == filtered.count }
    private func toggleSelectAll() {
        if allSelected { selected.removeAll() } else { selected = Set(filtered.map(\.id)) }
    }

    // MARK: Lenses

    private var referenceLens: some View {
        ReferenceLens(photos: filtered)
    }

    private var projectLens: some View {
        let groups = Dictionary(grouping: filtered) { $0.project ?? "Unfiled" }
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
                        Text(key).font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Palette.paper)
                    }
                }
            }
        }
    }

    private func grid(_ items: [Photo]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: gridCols)
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(items) { cell($0) }
            }
            .animation(.easeInOut(duration: 0.2), value: gridCols)
        }
        // Pinch to change photos-per-row: spread = bigger/fewer, pinch = smaller/more.
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { value in
                    if pinchBaseCols == nil { pinchBaseCols = gridCols }
                    let base = pinchBaseCols ?? gridCols
                    let steps = Int((value.magnification - 1) * 5)
                    gridCols = min(8, max(1, base - steps))
                }
                .onEnded { _ in pinchBaseCols = nil }
        )
    }

    // MARK: Cell + badges

    @ViewBuilder
    private func cell(_ photo: Photo) -> some View {
        if selecting {
            Button { toggleSelect(photo) } label: {
                tile(photo, selected: selected.contains(photo.id))
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: photo) { tile(photo, selected: false) }
                .buttonStyle(.plain)
        }
    }

    private func tile(_ photo: Photo, selected sel: Bool) -> some View {
        PhotoThumbnail(photo: photo)
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .overlay(alignment: .topLeading) { TileBadges(photo: photo).padding(4) }
            .overlay { if selecting {
                ZStack(alignment: .topTrailing) {
                    Color.black.opacity(sel ? 0.35 : 0)
                    Image(systemName: sel ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(sel ? Palette.coral : .white)
                        .font(.system(size: 20)).padding(5)
                        .shadow(radius: 1)
                }
            } }
    }

    private func toggleSelect(_ p: Photo) {
        if selected.contains(p.id) { selected.remove(p.id) } else { selected.insert(p.id) }
    }

    // MARK: Result bar / pills

    private var resultBar: some View {
        HStack(spacing: 8) {
            if let ft = filterType { filterPill(label: ft.capitalized) { filterType = nil } }
            if let fp = filterProject { filterPill(label: fp) { filterProject = nil } }
            Spacer()
            Text("\(filtered.count) of \(photos.count)")
                .font(.caption).foregroundStyle(Palette.ink3)
        }
        .padding(.horizontal, 12).padding(.bottom, 6)
    }

    private func filterPill(label: String, clear: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption.weight(.medium))
            Button(action: clear) { Image(systemName: "xmark.circle.fill") }.foregroundStyle(Palette.ink3)
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(Capsule().fill(Palette.tile))
        .foregroundStyle(Palette.ink)
    }

    // MARK: Selection action bar

    private var selectionBar: some View {
        HStack {
            Button { shareSelected() } label: { Label("Share", systemImage: "square.and.arrow.up") }
                .disabled(selected.isEmpty)
            Spacer()
            Text("\(selected.count) selected").font(.subheadline).foregroundStyle(Palette.ink2)
            Spacer()
            Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: "trash") }
                .disabled(selected.isEmpty)
        }
        .padding(.horizontal, 24).padding(.vertical, 12)
        .background(.bar)
    }

    private func deleteSelected() {
        for p in photos where selected.contains(p.id) { modelContext.delete(p) }
        try? modelContext.save()
        selected.removeAll(); selecting = false
    }

    private func shareSelected() {
        let imgs = photos.filter { selected.contains($0.id) }.compactMap { UIImage(data: $0.imageData) }
        guard !imgs.isEmpty else { return }
        shareItems = imgs; showShare = true
    }

    // MARK: Import

    private func importPhotos(_ items: [PhotosPickerItem]) async {
        var count = 0
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data), let jpeg = ui.jpegData(compressionQuality: 0.9) {
                // Carry over the original capture date + GPS from the photo's
                // metadata so imported shots sort by Time and show on the Map.
                let meta = Self.imageMetadata(from: data)
                let photo = Photo(imageData: jpeg,
                                  createdAt: meta.date ?? .now,
                                  latitude: meta.latitude,
                                  longitude: meta.longitude,
                                  importedAt: .now)
                modelContext.insert(photo); count += 1
            }
        }
        if count > 0 { try? modelContext.save() }
        importItems = []
    }

    /// Reads the original capture date and GPS from an image's EXIF/GPS
    /// metadata (no Photos-library permission needed — it's in the file data).
    private static func imageMetadata(from data: Data) -> (date: Date?, latitude: Double?, longitude: Double?) {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
        else { return (nil, nil, nil) }

        var date: Date?
        if let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let s = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
            date = exifDateFormatter.date(from: s)
        }
        if date == nil, let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
           let s = tiff[kCGImagePropertyTIFFDateTime] as? String {
            date = exifDateFormatter.date(from: s)
        }

        var lat: Double?, lon: Double?
        if let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any],
           let latVal = gps[kCGImagePropertyGPSLatitude] as? Double,
           let lonVal = gps[kCGImagePropertyGPSLongitude] as? Double {
            let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String ?? "N"
            let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String ?? "E"
            lat = latRef == "S" ? -latVal : latVal
            lon = lonRef == "W" ? -lonVal : lonVal
        }
        return (date, lat, lon)
    }

    private static let exifDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy:MM:dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: Chrome

    private var lensPicker: some View {
        Picker("Lens", selection: $lens) {
            ForEach(GalleryLens.allCases) { l in Label(l.rawValue, systemImage: l.symbol).tag(l) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 8)
        .disabled(selecting)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "camera.aperture").font(.system(size: 56, weight: .thin)).foregroundStyle(Palette.ink3)
            Text("ARCHI-ve").font(.largeTitle.weight(.semibold)).foregroundStyle(Palette.ink)
            Text("No photos yet").foregroundStyle(Palette.ink3)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tile badges

/// Untagged red dot (top-left), project lemon pill, reference mint pill.
struct TileBadges: View {
    let photo: Photo
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if photo.isUntagged {
                Circle().fill(Palette.coral).frame(width: 9, height: 9)
                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
            }
            if let proj = photo.project, !proj.isEmpty {
                pill(proj, Palette.lemon)
            } else if let ref = referenceLabel {
                pill(ref, Palette.mint)
            }
        }
    }
    private var referenceLabel: String? {
        let t = photo.humanTags
        switch t.type {
        case "building": return t.typology
        case "element": return t.element
        case "graphic": return t.graphicKind?.capitalized
        default: return nil
        }
    }
    private func pill(_ text: String, _ color: Color) -> some View {
        Text(text).font(.system(size: 9, weight: .semibold)).lineLimit(1)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(Capsule().fill(color))
            .foregroundStyle(.black)
    }
}

// MARK: - Filter sheet

private struct FilterSheet: View {
    @Binding var type: String?
    @Binding var project: String?
    let projects: [String]
    @Environment(\.dismiss) private var dismiss

    private let types: [(String, String)] = [("untagged", "Untagged"), ("building", "Building"),
                                              ("element", "Element"), ("graphic", "Graphic")]

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: Binding(get: { type ?? "all" },
                                                      set: { type = $0 == "all" ? nil : $0 })) {
                        Text("All").tag("all")
                        ForEach(types, id: \.0) { Text($0.1).tag($0.0) }
                    }.pickerStyle(.inline).labelsHidden()
                }
                if !projects.isEmpty {
                    Section("Project") {
                        Picker("Project", selection: Binding(get: { project ?? "" },
                                                             set: { project = $0.isEmpty ? nil : $0 })) {
                            Text("Any").tag("")
                            ForEach(projects, id: \.self) { Text($0).tag($0) }
                        }.pickerStyle(.inline).labelsHidden()
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Clear") { type = nil; project = nil } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
        .tint(Palette.coral)
    }
}

// MARK: - Share sheet

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Thumbnail

/// Thumbnail that decodes a downsampled image off the main thread.
struct PhotoThumbnail: View {
    let photo: Photo
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Palette.tile
                if let image { Image(uiImage: image).resizable().scaledToFill() }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .task(id: photo.id) {
                if image == nil { image = await Self.thumbnail(from: photo.imageData, maxPixel: 400) }
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

// MARK: - Map lens

private struct MapLens: View {
    let photos: [Photo]
    var selecting: Bool

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
