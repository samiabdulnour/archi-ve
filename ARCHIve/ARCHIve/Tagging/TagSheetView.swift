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
        return Set(out).union(Settings.customProjects).sorted()
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
            .background(Palette.paper.ignoresSafeArea())
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
        typologySection
        if let typ = tags.typology, typ != "Landscape" {
            let rooms = TagVocab.roomsFor(typ)
            if !rooms.isEmpty {
                singleChipSection("Room", options: rooms.map { ($0.id, $0.label, $0.symbol) },
                                  selectionID: $tags.room)
            }
        }
        conceptSection
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
                ForEach(TagVocab.materials + Settings.customMaterials, id: \.self) { m in
                    IllustratedTile(label: m, selected: tags.materials.contains(m)) {
                        MaterialityPattern(id: m, ink: Palette.ink)
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
        graphicKindSection
        graphicDetailSection
        visualSection
    }

    /// Per-kind detail fields, matching the web app's GRAPHIC_FIELDS.
    @ViewBuilder private var graphicDetailSection: some View {
        let fields = TagVocab.graphicFields(for: tags.graphicKind)
        if !fields.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Details")
                ForEach(fields, id: \.0) { field in
                    TextField(field.1, text: binding(for: field.0))
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    /// Maps a graphic field key to the matching HumanTags property.
    private func binding(for key: String) -> Binding<String> {
        switch key {
        case "title":   return strBinding(\.title)
        case "creator": return strBinding(\.creator)
        case "year":    return strBinding(\.year)
        case "source":  return strBinding(\.source)
        case "name":    return strBinding(\.contactName)
        case "company": return strBinding(\.contactCompany)
        default:        return strBinding(\.title)
        }
    }
    private func strBinding(_ kp: WritableKeyPath<HumanTags, String?>) -> Binding<String> {
        Binding(get: { tags[keyPath: kp] ?? "" },
                set: { tags[keyPath: kp] = $0.isEmpty ? nil : $0 })
    }

    // MARK: Illustrated sections (Typology / Graphic kinds / Visual)

    private var conceptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Concept")
            LazyVGrid(columns: tileColumns, spacing: 8) {
                ForEach(TagVocab.concepts) { c in
                    IllustratedTile(label: c.label, selected: tags.concepts.contains(c.id)) {
                        LineArtGlyph(group: .concept, id: c.id, color: Palette.ink)
                    } action: {
                        if let i = tags.concepts.firstIndex(of: c.id) { tags.concepts.remove(at: i) }
                        else { tags.concepts.append(c.id) }
                    }
                }
            }
        }
    }

    private var typologySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Typology")
            LazyVGrid(columns: tileColumns, spacing: 8) {
                ForEach(TagVocab.typology, id: \.self) { ty in
                    IllustratedTile(label: ty, selected: tags.typology == ty) {
                        LineArtGlyph(group: .typology, id: ty, color: Palette.ink)
                    } action: {
                        tags.typology = (tags.typology == ty) ? nil : ty
                    }
                }
            }
        }
    }

    private var graphicKindSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Kind")
            LazyVGrid(columns: tileColumns, spacing: 8) {
                ForEach(TagVocab.graphicKinds) { k in
                    IllustratedTile(label: k.label, selected: tags.graphicKind == k.id) {
                        LineArtGlyph(group: .graphic, id: k.label, color: Palette.ink)
                    } action: {
                        tags.graphicKind = (tags.graphicKind == k.id) ? nil : k.id
                    }
                }
            }
        }
    }

    private var visualSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Visual")
            LazyVGrid(columns: tileColumns, spacing: 8) {
                ForEach(TagVocab.visual, id: \.self) { v in
                    IllustratedTile(label: v, selected: tags.visual.contains(v)) {
                        LineArtGlyph(group: .visual, id: v, color: Palette.ink)
                    } action: {
                        if let i = tags.visual.firstIndex(of: v) { tags.visual.remove(at: i) }
                        else { tags.visual.append(v) }
                    }
                }
            }
        }
    }

    // MARK: Extras

    private var extrasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            // Graphic has its own per-kind Title/Creator/Year fields, so the
            // generic Author & year is only shown for Building / Element.
            if tags.type != "graphic" {
                sectionLabel("Author & year")
                TextField("e.g. Aalto, 1939", text: Binding(
                    get: { tags.authorYear ?? "" },
                    set: { tags.authorYear = $0.isEmpty ? nil : $0 }))
                    .textFieldStyle(.roundedBorder)
            }
            sectionLabel("Note")
            TextField("Personal note", text: Binding(
                get: { tags.note ?? "" },
                set: { tags.note = $0.isEmpty ? nil : $0 }), axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
            sectionLabel("Keywords")
            TextField("comma, separated", text: Binding(
                get: { tags.keywords.joined(separator: ", ") },
                set: { tags.keywords = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }))
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
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
            .background(selected ? Palette.coral.opacity(0.16) : Palette.tile)
            .foregroundStyle(selected ? Palette.coral : Palette.ink)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? Palette.coral : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
