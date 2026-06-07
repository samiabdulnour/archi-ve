import SwiftUI
import SwiftData

/// Swipeable detail: pages horizontally through the archive (newest first),
/// starting at the tapped photo. Each page shows the image (tap to pinch-zoom
/// fullscreen) and the tags it was captured with.
struct PhotoDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Photo.createdAt, order: .reverse) private var photos: [Photo]

    @State private var selection: String
    @State private var introspecting = false
    @State private var editing = false
    @State private var confirmDelete = false

    init(photoID: String) { _selection = State(initialValue: photoID) }

    private var current: Photo? { photos.first { $0.id == selection } }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(photos) { photo in
                PhotoPage(photo: photo) { introspecting = true }
                    .tag(photo.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Palette.paper.ignoresSafeArea())
        .navigationTitle(current.map { $0.createdAt.formatted(date: .abbreviated, time: .shortened) } ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { editing = true } label: { Label("Edit tags", systemImage: "tag") }
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(current == nil)
            }
        }
        .fullScreenCover(isPresented: $introspecting) {
            IntrospectionView(image: current.flatMap { UIImage(data: $0.imageData) }) { introspecting = false }
        }
        .fullScreenCover(isPresented: $editing) {
            if let current {
                TagSheetView(photo: current) { editing = false }
            }
        }
        .alert("Delete this photo?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { deleteCurrent() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes the photo from your archive.")
        }
    }

    /// Delete the current page, then move to a neighbour or leave if it was the
    /// last one.
    private func deleteCurrent() {
        guard let current, let idx = photos.firstIndex(where: { $0.id == current.id }) else { return }
        let neighbour = photos[safe: idx + 1] ?? photos[safe: idx - 1]
        modelContext.delete(current)
        try? modelContext.save()
        if let neighbour { selection = neighbour.id } else { dismiss() }
    }
}

/// A single detail page: tappable image + its tag rows.
private struct PhotoPage: View {
    @Bindable var photo: Photo
    var onZoom: () -> Void

    @State private var showLabel = false

    private var image: UIImage? { UIImage(data: photo.imageData) }
    private var labelImage: UIImage? { photo.labelImageData.flatMap { UIImage(data: $0) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let image {
                    Button(action: onZoom) {
                        Image(uiImage: image)
                            .resizable().scaledToFit()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(tagRows, id: \.label) { row in
                        DetailRow(label: row.label, value: row.value)
                    }
                }
                .padding(.horizontal, 16)

                if let labelImage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Label").font(.subheadline).foregroundStyle(.secondary)
                        Button { showLabel = true } label: {
                            Image(uiImage: labelImage)
                                .resizable().scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.hairline, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 24)
        }
        .fullScreenCover(isPresented: $showLabel) {
            IntrospectionView(image: labelImage) { showLabel = false }
        }
    }

    // MARK: Tag rows

    private struct Row { let label: String; let value: String }

    private var tagRows: [Row] {
        let t = photo.humanTags
        var rows: [Row] = []
        func add(_ label: String, _ value: String?) {
            if let v = value, !v.isEmpty { rows.append(Row(label: label, value: v)) }
        }
        func addList(_ label: String, _ values: [String]) {
            if !values.isEmpty { rows.append(Row(label: label, value: values.joined(separator: ", "))) }
        }
        add("Kind", t.type?.capitalized)
        add("Typology", t.typology)
        add("Room", t.room?.capitalized)
        addList("Concept", t.concepts.map { $0.capitalized })
        add("Category", t.elementCategory)
        add("Element", t.element)
        addList("Materiality", t.materials)
        addList("Colour", t.colors.map { $0.capitalized })
        add("Graphic kind", t.graphicKind?.capitalized)
        add("Title", t.title)
        add("Creator", t.creator)
        add("Year", t.year)
        add("Source", t.source)
        add("Contact", [t.contactName, t.contactCompany].compactMap { $0 }.joined(separator: " · "))
        addList("Visual", t.visual)
        add("Author & year", t.authorYear)
        add("Note", t.note)
        addList("Keywords", t.keywords)
        add("Project", photo.project)
        if photo.latitude != nil { rows.append(Row(label: "Location", value: "Tagged")) }
        if rows.isEmpty { rows.append(Row(label: "Untagged", value: "Tap ⋯ to add tags")) }
        return rows
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value).font(.subheadline)
            Spacer()
        }
    }
}

private extension Array {
    /// Safe index lookup — returns nil instead of trapping out of bounds.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
