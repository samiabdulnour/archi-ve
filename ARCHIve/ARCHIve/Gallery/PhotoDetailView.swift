import SwiftUI
import SwiftData

/// Shows one photo, the categories it was tagged with, and opens the
/// fullscreen pinch-zoom introspection when the image is tapped.
struct PhotoDetailView: View {
    @Bindable var photo: Photo
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var introspecting = false
    @State private var editing = false
    @State private var confirmDelete = false

    private var image: UIImage? { UIImage(data: photo.imageData) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let image {
                    Button { introspecting = true } label: {
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
                .padding(.bottom, 24)
            }
        }
        .background(Palette.paper.ignoresSafeArea())
        .navigationTitle(photo.createdAt.formatted(date: .abbreviated, time: .shortened))
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
            }
        }
        .fullScreenCover(isPresented: $introspecting) {
            IntrospectionView(image: image) { introspecting = false }
        }
        .sheet(isPresented: $editing) {
            TagSheetView(photo: photo) { editing = false }
        }
        .alert("Delete this photo?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                modelContext.delete(photo)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes the photo from your archive.")
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
        add("Element", t.element)
        addList("Materiality", t.materials)
        addList("Colour", t.colors.map { $0.capitalized })
        add("Graphic kind", t.graphicKind?.capitalized)
        addList("Visual", t.visual)
        add("Author & year", t.authorYear)
        add("Note", t.note)
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
