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
    @State private var showFullscreen = false
    @State private var headerImage: UIImage?
    @State private var labelImage: UIImage?
    @State private var showLabelCamera = false
    @State private var showFullscreenLabel = false
    @AppStorage("flowSteps") private var flowRaw = ""

    private var flow: String { tags.type ?? "building" }
    private func enabled(_ step: String) -> Bool { Settings.flowEnabled(flow, step) }

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
                VStack(alignment: .leading, spacing: 12) {
                    thumbnail
                    typePicker
                    switch tags.type {
                    case "building": buildingSections
                    case "element":  elementSections
                    case "graphic":  graphicSections
                    default:
                        Text("Pick a category above.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.top, 8)
                    }
                    if tags.type != nil { extrasSection }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
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
            .onAppear {
                tags = photo.humanTags; project = photo.project ?? ""
                if let d = photo.labelImageData { labelImage = UIImage(data: d) }
            }
            .task(id: photo.id) { headerImage = await PhotoImage.full(for: photo) }
        }
        .interactiveDismissDisabled(false)
        .fullScreenCover(isPresented: $showFullscreen) {
            IntrospectionView(image: headerImage) { showFullscreen = false }
        }
        .fullScreenCover(isPresented: $showLabelCamera) {
            ImagePicker { data in labelImage = UIImage(data: data) }
                .ignoresSafeArea()
        }
    }

    // MARK: Header

    /// Tap the thumbnail to inspect the shot fullscreen (pinch-zoom) before
    /// committing tags.
    private var thumbnail: some View {
        Button { showFullscreen = true } label: {
            Group {
                if let img = headerImage {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(Circle().fill(.black.opacity(0.45)))
                                .padding(6)
                        }
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// Building / Element / Graphic as a single segmented toggle.
    private var typePicker: some View {
        Picker("Category", selection: Binding(
            get: { tags.type ?? "" },
            set: { tags.type = $0.isEmpty ? nil : $0 })) {
            ForEach(TagVocab.types) { Text($0.label).tag($0.id) }
        }
        .pickerStyle(.segmented)
    }

    // MARK: Building

    @ViewBuilder private var buildingSections: some View {
        if enabled("typology") {
            typologySection
            if let typ = tags.typology, typ != "Landscape" {
                let rooms = TagVocab.roomsFor(typ)
                if !rooms.isEmpty { roomSection(rooms) }
            }
        }
        if enabled("concept") { conceptSection }
        if enabled("materiality") { materialitySection }
        if enabled("colour") { colorSection }
    }

    // MARK: Element

    @ViewBuilder private var elementSections: some View {
        if enabled("element") {
            tileSection("Element") {
                ForEach(TagVocab.elementCategories, id: \.category) { cat in
                    CompactTile(label: cat.category, selected: tags.elementCategory == cat.category) {
                        symbolArt("elementcat", cat.category)
                    } action: {
                        if tags.elementCategory == cat.category { tags.elementCategory = nil; tags.element = nil }
                        else { tags.elementCategory = cat.category; tags.element = nil }
                    }
                }
            }
            if let cat = tags.elementCategory {
                tileSection(cat) {
                    ForEach(TagVocab.elementItems(for: cat), id: \.self) { sub in
                        CompactTile(label: sub, selected: tags.element == sub) {
                            symbolArt("elementsub", sub)
                        } action: { tags.element = (tags.element == sub) ? nil : sub }
                    }
                }
            }
        }
        // Finish → Paint swaps Materiality for Colour (web behaviour).
        if tags.element == "Paint" {
            colorSection
        } else {
            if enabled("materiality") { materialitySection }
            if enabled("colour") { colorSection }
        }
    }

    // MARK: Materiality (hatch-pattern tiles, shared by Building + Element)

    private var materialitySection: some View {
        tileSection("Materiality") {
            ForEach(TagVocab.materials + Settings.customMaterials, id: \.self) { m in
                CompactTile(label: m, selected: tags.materials.contains(m)) {
                    symbolArt("material", m)
                } action: {
                    if let i = tags.materials.firstIndex(of: m) { tags.materials.remove(at: i) }
                    else { tags.materials.append(m) }
                }
            }
        }
    }

    // MARK: Colour (small swatch + label, shared by Building + Element)

    private var colorSection: some View {
        tileSection("Colour") {
            ForEach(TagVocab.colors, id: \.id) { c in
                CompactTile(label: c.label, selected: tags.colors.contains(c.id)) {
                    RoundedRectangle(cornerRadius: 5).fill(Color(hex: c.hex))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Palette.hairline, lineWidth: 0.5))
                } action: {
                    if let i = tags.colors.firstIndex(of: c.id) { tags.colors.remove(at: i) }
                    else { tags.colors.append(c.id) }
                }
            }
        }
    }

    private var tileColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)
    }

    // MARK: Graphic

    @ViewBuilder private var graphicSections: some View {
        if enabled("kind") { graphicKindSection }
        if enabled("details") { graphicDetailSection }
        if enabled("visual") { visualSection }
    }

    /// Per-kind detail fields, matching the web app's GRAPHIC_FIELDS. Plus a
    /// "Capture label" shortcut: at a gallery/exhibition you can snap the wall
    /// placard instead of typing the title/artist by hand.
    @ViewBuilder private var graphicDetailSection: some View {
        let fields = TagVocab.graphicFields(for: tags.graphicKind)
        if !fields.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Details")
                labelCaptureRow
                ForEach(fields, id: \.0) { field in
                    TextField(field.1, text: binding(for: field.0))
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    /// Snap-the-placard control: a button when empty, a tappable thumbnail
    /// (with retake / remove) once a label photo has been captured.
    @ViewBuilder private var labelCaptureRow: some View {
        if let img = labelImage {
            HStack(spacing: 12) {
                Button { showFullscreenLabel = true } label: {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.hairline, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Label captured").font(.subheadline.weight(.medium)).foregroundStyle(Palette.ink)
                    Text("Tap to view").font(.caption).foregroundStyle(Palette.ink3)
                }
                Spacer()
                Button { showLabelCamera = true } label: {
                    Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 16))
                }
                Button(role: .destructive) { labelImage = nil } label: {
                    Image(systemName: "trash").font(.system(size: 16))
                }
            }
            .fullScreenCover(isPresented: $showFullscreenLabel) {
                IntrospectionView(image: labelImage) { showFullscreenLabel = false }
            }
        } else {
            Button { showLabelCamera = true } label: {
                Label("Capture label", systemImage: "text.viewfinder")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Palette.tile))
                    .foregroundStyle(Palette.ink)
            }
            .buttonStyle(.plain)
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

    /// SF Symbol artwork for a tile (colour inherited from the tile state).
    private func symbolArt(_ group: String, _ id: String) -> some View {
        Image(systemName: TagVocab.symbol(group, id))
            .font(.system(size: 20, weight: .regular))
    }

    private func tileSection<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel(title)
            LazyVGrid(columns: tileColumns, spacing: 6, content: content)
        }
    }

    private func roomSection(_ rooms: [TagOption]) -> some View {
        tileSection("Room") {
            ForEach(rooms) { r in
                CompactTile(label: r.label, selected: tags.room == r.id) {
                    symbolArt("room", r.id)
                } action: { tags.room = (tags.room == r.id) ? nil : r.id }
            }
        }
    }

    private var conceptSection: some View {
        tileSection("Concept") {
            ForEach(TagVocab.concepts) { c in
                CompactTile(label: c.label, selected: tags.concepts.contains(c.id)) {
                    symbolArt("concept", c.id)
                } action: {
                    if let i = tags.concepts.firstIndex(of: c.id) { tags.concepts.remove(at: i) }
                    else { tags.concepts.append(c.id) }
                }
            }
        }
    }

    private var typologySection: some View {
        tileSection("Typology") {
            ForEach(TagVocab.typology, id: \.self) { ty in
                CompactTile(label: ty, selected: tags.typology == ty) {
                    symbolArt("typology", ty)
                } action: { tags.typology = (tags.typology == ty) ? nil : ty }
            }
        }
    }

    private var graphicKindSection: some View {
        tileSection("Kind") {
            ForEach(TagVocab.graphicKinds) { k in
                CompactTile(label: k.label, selected: tags.graphicKind == k.id) {
                    symbolArt("graphic", k.id)
                } action: { tags.graphicKind = (tags.graphicKind == k.id) ? nil : k.id }
            }
        }
    }

    private var visualSection: some View {
        tileSection("Visual") {
            ForEach(TagVocab.visual, id: \.self) { v in
                CompactTile(label: v, selected: tags.visual.contains(v)) {
                    symbolArt("visual", v)
                } action: {
                    if let i = tags.visual.firstIndex(of: v) { tags.visual.remove(at: i) }
                    else { tags.visual.append(v) }
                }
            }
        }
    }

    // MARK: Extras

    private var extrasSection: some View {
        // Compact, label-light layout (placeholders act as labels) so the whole
        // tag form ideally fits without scrolling.
        VStack(alignment: .leading, spacing: 8) {
            Divider().padding(.vertical, 2)
            if enabled("rating") { ratingRow }
            // Graphic has its own per-kind Title/Creator/Year fields, so Author
            // & year is only shown for Building / Element — as two separate
            // fields with the year on the right.
            if tags.type != "graphic" && enabled("authoryear") {
                HStack(spacing: 8) {
                    TextField("Author", text: strBinding(\.creator))
                        .textFieldStyle(.roundedBorder)
                    TextField("Year", text: strBinding(\.year))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 78)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numbersAndPunctuation)
                }
            }
            if enabled("note") {
                TextField("Note", text: Binding(
                    get: { tags.note ?? "" },
                    set: { tags.note = $0.isEmpty ? nil : $0 }), axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.roundedBorder)
            }
            TextField("Keywords (comma separated)", text: Binding(
                get: { tags.keywords.joined(separator: ", ") },
                set: { tags.keywords = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }))
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            projectSection
        }
    }

    /// Five-star rating, styled as a labelled field to match the text inputs:
    /// "Rating" on the left, stars right-aligned. Tap a star to set 1…5; tap the
    /// current rating to clear it.
    private var ratingRow: some View {
        HStack {
            Text("Rating").foregroundStyle(Palette.ink3)
            Spacer()
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { i in
                    let filled = (tags.rating ?? 0) >= i
                    Button {
                        tags.rating = (tags.rating == i) ? nil : i
                    } label: {
                        Image(systemName: filled ? "star.fill" : "star")
                            .font(.system(size: 17))
                            .foregroundStyle(filled ? Palette.coral : Palette.ink3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 8).fill(Palette.paperElev))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Palette.hairline, lineWidth: 0.5))
    }

    /// Project association lives on the Photo (not in HumanTags). Tap an existing
    /// project to reuse it, or type a new one. Tapping the active chip clears it.
    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Project", text: $project)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            if !existingProjects.isEmpty {
                chipGrid(existingProjects.map { ($0, $0, nil as String?) }) { id in
                    project == id
                } toggle: { id in
                    project = (project == id) ? "" : id
                }
            }
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
        photo.labelImageData = labelImage?.jpegData(compressionQuality: 0.85)
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
