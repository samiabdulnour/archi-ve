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
final class Photo {
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

    init(
        id: String = UUID().uuidString,
        imageData: Data,
        createdAt: Date = .now,
        latitude: Double? = nil,
        longitude: Double? = nil,
        humanTags: HumanTags = HumanTags(),
        project: String? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.createdAt = createdAt
        self.latitude = latitude
        self.longitude = longitude
        self.humanTagsData = (try? JSONEncoder().encode(humanTags)) ?? Data()
        self.machineTagsData = Data()
        self.project = project
    }

    /// Decoded view of the human tags.
    var humanTags: HumanTags {
        get { (try? JSONDecoder().decode(HumanTags.self, from: humanTagsData)) ?? HumanTags() }
        set { humanTagsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
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
    var element: String?           // Column, Stair, ...
    var materials: [String] = []   // Concrete, Brick, ...
    var colors: [String] = []      // white, grey, ... (when sub-element is Paint)

    // Graphic branch
    var graphicKind: String?       // artwork, book, drawing, ...
    var visual: [String] = []      // Colorful, Monochrome, ...
}
