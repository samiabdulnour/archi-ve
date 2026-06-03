import SwiftUI
import SwiftData

/// Post-capture tagging. Binds to a freshly-saved Photo so the image is never
/// lost — Save commits the chosen tags, Skip leaves it untagged (only `type`
/// kept, exactly like the web back-arrow behaviour). Fast path: pick a type,
/// pick one option, Save.
struct TagSheetView: View {
    @Bindable var photo: Photo
    var onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allPhotos: [Photo]
    @State private var tags = HumanTags()
    @State private var project = ""

    /// Distinct project names already in use, for one-tap reuse.
    private var existingProjects: [String] {
        var seen = Set<String>(); var out: [String] = []
        for p in allPhotos {
            guard let name = p.project, !name.isEmpty, !seen.contains(name) else { continue }
            seen.insert(name); out.append(name)
        }
        return out.sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    thumbnail
                    typePicker
                    Divider()
                    switch tags.type {
                    case "building": buildingSections
                    case "element":  elementSections
                    case "graphic":  graphicSections
                    default:
                        Text("Choose what this photo is of.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 12)
                    }
                    if tags.type != nil { extrasSection }
                }
                .padding(20)
            }
            .navigationTitle("Tag photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") { finish() }      // keeps type only
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { commit() }
                        .fontWeight(.semibold)
                        .disabled(tags.type == nil)
                }
            }
            .onAppear { tags = photo.humanTags; project = photo.project ?? "" }
        }
        .interactiveDismissDisabled(false)
    }

    // MARK: Header

    private var thumbnail: some View {
        Group {
            if let img = UIImage(data: photo.imageData) {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("What is this?")
            HStack(spacing: 10) {
                ForEach(TagVocab.types) { t in
                    TagChip(label: t.label, symbol: t.symbol, selected: tags.type == t.id) {
                        if tags.type != t.id { tags.type = t.id }
                    }
                }
            }
        }
    }

    // MARK: Building

    @ViewBuilder private var buildingSections: some View {
        pickerSection("Typology", options: TagVocab.typology, selection: $tags.typology)
        if let typ = tags.typology, typ != "Landscape" {
            let rooms = TagVocab.roomsFor(typ)
            if !rooms.isEmpty {
                singleChipSection("Room", options: rooms.map { ($0.id, $0.label, $0.symbol) },
                                  selectionID: $tags.room)
            }
        }
        multiChipSection("Concept", options: TagVocab.concepts.map { ($0.id, $0.label, $0.symbol) },
                         selection: $tags.concepts)
        materialitySection
        colorSection
    }

    // MARK: Element

    @ViewBuilder private var elementSections: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Element")
            ForEach(TagVocab.elementGroups, id: \.group) { grp in
                Text(grp.group.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                chipGrid(grp.items.map { ($0, $0, nil as String?) }) { id in
                    tags.element == id
                } toggle: { id in
                    tags.element = (tags.element == id) ? nil : id
                }
            }
        }
        materialitySection
        colorSection
    }

    // MARK: Materiality (hatch-pattern tiles, shared by Building + Element)

    private var materialitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Materiality")
            LazyVGrid(columns: tileColumns, spacing: 8) {
                ForEach(TagVocab.materials, id: \.self) { m in
                    IllustratedTile(label: m, selected: tags.materials.contains(m)) {
                        MaterialityPattern(id: m, ink: .primary)
                    } action: {
                        if let i = tags.materials.firstIndex(of: m) { tags.materials.remove(at: i) }
                        else { tags.materials.append(m) }
                    }
                }
            }
        }
    }

    // MARK: Colour (square swatch tiles, shared by Building + Element)

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Colour")
            LazyVGrid(columns: tileColumns, spacing: 8) {
                ForEach(TagVocab.colors, id: \.id) { c in
                    IllustratedTile(label: c.label, selected: tags.colors.contains(c.id)) {
                        Rectangle().fill(Color(hex: c.hex))
                    } action: {
                        if let i = tags.colors.firstIndex(of: c.id) { tags.colors.remove(at: i) }
                        else { tags.colors.append(c.id) }
                    }
                }
            }
        }
    }

    private var tileColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    }

    // MARK: Graphic

    @ViewBuilder private var graphicSections: some View {
        singleChipSection("Kind", options: TagVocab.graphicKinds.map { ($0.id, $0.label, $0.symbol) },
                          selectionID: $tags.graphicKind)
        multiTextSection("Visual", options: TagVocab.visual, selection: $tags.visual)
    }

    // MARK: Extras

    private var extrasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            sectionLabel("Author & year")
            TextField("e.g. Aalto, 1939", text: Binding(
                get: { tags.authorYear ?? "" },
                set: { tags.authorYear = $0.isEmpty ? nil : $0 }))
                .textFieldStyle(.roundedBorder)
            sectionLabel("Note")
            TextField("Personal note", text: Binding(
                get: { tags.note ?? "" },
                set: { tags.note = $0.isEmpty ? nil : $0 }), axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
            projectSection
        }
    }

    /// Project association lives on the Photo (not in HumanTags). Tap an existing
    /// project to reuse it, or type a new one. Tapping the active chip clears it.
    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Project")
            if !existingProjects.isEmpty {
                chipGrid(existingProjects.map { ($0, $0, nil as String?) }) { id in
                    project == id
                } toggle: { id in
                    project = (project == id) ? "" : id
                }
            }
            TextField("New project name", text: $project)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
        }
    }

    // MARK: Reusable section builders

    private func sectionLabel(_ t: String) -> some View {
        Text(t).font(.headline)
    }

    /// Single-select from plain strings (id == label).
    private func pickerSection(_ title: String, options: [String], selection: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(title)
            chipGrid(options.map { ($0, $0, nil as String?) }) { id in
                selection.wrappedValue == id
            } toggle: { id in
                selection.wrappedValue = (selection.wrappedValue == id) ? nil : id
            }
        }
    }

    /// Single-select with symbols, storing the option id.
    private func singleChipSection(_ title: String, options: [(String, String, String?)],
                                   selectionID: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(title)
            chipGrid(options) { id in selectionID.wrappedValue == id }
                toggle: { id in selectionID.wrappedValue = (selectionID.wrappedValue == id) ? nil : id }
        }
    }

    /// Multi-select with symbols, storing ids in an array.
    private func multiChipSection(_ title: String, options: [(String, String, String?)],
                                  selection: Binding<[String]>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(title)
            chipGrid(options) { id in selection.wrappedValue.contains(id) }
                toggle: { id in toggleMulti(id, in: selection) }
        }
    }

    /// Multi-select from plain strings.
    private func multiTextSection(_ title: String, options: [String], selection: Binding<[String]>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(title)
            chipGrid(options.map { ($0, $0, nil as String?) }) { id in
                selection.wrappedValue.contains(id)
            } toggle: { id in toggleMulti(id, in: selection) }
        }
    }

    private func toggleMulti(_ id: String, in selection: Binding<[String]>) {
        if let i = selection.wrappedValue.firstIndex(of: id) {
            selection.wrappedValue.remove(at: i)
        } else {
            selection.wrappedValue.append(id)
        }
    }

    /// A 4-column grid of chips. `options` is (id, label, symbol?).
    private func chipGrid(_ options: [(String, String, String?)],
                          isSelected: @escaping (String) -> Bool,
                          toggle: @escaping (String) -> Void) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            ForEach(options, id: \.0) { opt in
                TagChip(label: opt.1, symbol: opt.2, selected: isSelected(opt.0)) { toggle(opt.0) }
            }
        }
    }

    // MARK: Persist

    private func commit() {
        photo.humanTags = tags
        let trimmed = project.trimmingCharacters(in: .whitespacesAndNewlines)
        photo.project = trimmed.isEmpty ? nil : trimmed
        try? modelContext.save()
        finish()
    }

    private func finish() {
        // If nothing was chosen beyond type, the record simply stays sparse —
        // it's already persisted, so the photo is never lost.
        onDone()
        dismiss()
    }
}

/// A single selectable tag button.
struct TagChip: View {
    let label: String
    let symbol: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 17))
                }
                Text(label)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: symbol == nil ? 44 : 60)
            .background(selected ? Color.accentColor.opacity(0.16) : Color(.secondarySystemBackground))
            .foregroundStyle(selected ? Color.accentColor : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
