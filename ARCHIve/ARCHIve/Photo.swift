import Foundation
import SwiftData

/// One archived photo plus its human tags and (reserved) machine tags.
///
/// Mirrors the web app's record shape: a JPEG blob, a capture timestamp,
/// optional GPS, and two strictly-separate tag bags — `tagsHuman` (the
/// owner's Kind + Context answers) and `tagsMachine` (reserved for future
/// image-recognition suggestions; empty for now, never merged with human
/// tags so intent and guesses stay distinguishable forever).
@Model
final class Photo: Identifiable {
    /// Stable id (UUID string) — matches the web app's record id style.
    @Attribute(.unique) var id: String

    /// The captured JPEG. Stored outside the main store file for size.
    @Attribute(.externalStorage) var imageData: Data

    /// When the photo was taken (capture time, not import time).
    var createdAt: Date

    // GPS comes free from the phone; nil when unavailable / denied.
    var latitude: Double?
    var longitude: Double?

    /// The owner's structured tags. Encoded JSON so the shape can evolve
    /// without a SwiftData migration for every taxonomy tweak.
    var humanTagsData: Data

    /// Reserved for machine-suggested tags. Empty for now.
    var machineTagsData: Data

    /// Project association (editable later); nil = unfiled.
    var project: String?

    /// Set when the photo was brought in via Import rather than the camera.
    var importedAt: Date?

    /// An optional second photo of an info placard / wall label (e.g. the
    /// painting's caption at an exhibition) — captured instead of typing the
    /// title/artist. Stored outside the main store file like the main image.
    @Attribute(.externalStorage) var labelImageData: Data?

    init(
        id: String = UUID().uuidString,
        imageData: Data,
        createdAt: Date = .now,
        latitude: Double? = nil,
        longitude: Double? = nil,
        humanTags: HumanTags = HumanTags(),
        project: String? = nil,
        importedAt: Date? = nil,
        labelImageData: Data? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.createdAt = createdAt
        self.latitude = latitude
        self.longitude = longitude
        self.humanTagsData = (try? JSONEncoder().encode(humanTags)) ?? Data()
        self.machineTagsData = Data()
        self.project = project
        self.importedAt = importedAt
        self.labelImageData = labelImageData
    }

    /// Decoded view of the human tags.
    var humanTags: HumanTags {
        get { (try? JSONDecoder().decode(HumanTags.self, from: humanTagsData)) ?? HumanTags() }
        set { humanTagsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    /// True when the photo has no Kind and no project — shows the red dot.
    var isUntagged: Bool { humanTags.type == nil && (project ?? "").isEmpty }

    /// Denormalised lower-cased text of every tag value, for search (AND
    /// word-match), mirroring the web app's `search_text`.
    var searchText: String {
        let t = humanTags
        var parts: [String?] = [t.type, t.typology, t.room, t.elementCategory, t.element, t.graphicKind,
                                t.authorYear, t.note, t.title, t.creator, t.year,
                                t.source, t.brand, t.model, t.contactName, t.contactCompany,
                                project]
        parts += t.concepts + t.materials + t.colors + t.visual + t.keywords
        return parts.compactMap { $0 }.joined(separator: " ").lowercased()
    }
}

/// The owner's structured Kind + Context answers. All optional/array so a
/// partially-tagged draft is representable. IDs are lowercase to match the
/// existing web vocabulary (so future data import lines up).
struct HumanTags: Codable, Equatable {
    /// "building" | "element" | "graphic"
    var type: String?

    // Building branch
    var typology: String?          // Residential, Office, ...
    var room: String?              // outdoor, lobby, ...
    var concepts: [String] = []    // form, space, light, ...

    // Element branch
    var elementCategory: String?   // Structure, Vertical, Opening, ...
    var element: String?           // Wall, Column, Stair, ...
    var materials: [String] = []   // Concrete, Brick, ...
    var colors: [String] = []      // white, grey, ... (when sub-element is Paint)

    // Graphic branch
    var graphicKind: String?       // artwork, book, drawing, ...
    var visual: [String] = []      // Colorful, Monochrome, ...
    // Per-graphic-kind detail fields (match the web app)
    var title: String?
    var creator: String?
    var year: String?
    var source: String?
    var brand: String?
    var model: String?
    var contactName: String?
    var contactCompany: String?

    // Free-text extras (optional)
    var authorYear: String?        // "Aalto, 1939" etc.
    var note: String?              // personal note
    var keywords: [String] = []    // free user keywords

    /// A draft is "tagged" once a type is chosen.
    var isEmpty: Bool {
        type == nil && typology == nil && room == nil && concepts.isEmpty
            && element == nil && materials.isEmpty && colors.isEmpty
            && graphicKind == nil && visual.isEmpty
            && (authorYear?.isEmpty ?? true) && (note?.isEmpty ?? true)
    }
}
