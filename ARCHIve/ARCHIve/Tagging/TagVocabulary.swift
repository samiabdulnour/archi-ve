import SwiftUI

/// The v3 tag vocabulary, ported verbatim from the web app. IDs stay lowercase
/// to match the existing data shape. SF Symbols stand in for the web glyphs.

struct TagOption: Identifiable, Hashable {
    let id: String
    let label: String
    let hint: String
    var symbol: String = "circle"
    init(_ id: String, _ label: String, _ hint: String = "", symbol: String = "circle") {
        self.id = id; self.label = label; self.hint = hint; self.symbol = symbol
    }
}

enum TagVocab {
    // Tap 1 — Kind
    static let types: [TagOption] = [
        TagOption("building", "Building", "A whole building or space", symbol: "building.2"),
        TagOption("element",  "Element",  "A part or detail", symbol: "square.split.bottomrightquarter"),
        TagOption("graphic",  "Graphic",  "Flat: artwork, book, drawing…", symbol: "doc.richtext"),
    ]

    // Building → Typology (8)
    static let typology: [String] = [
        "Residential", "Office", "Public", "Commercial",
        "Hospitality", "Heritage", "Landscape", "Other",
    ]

    // Building → Concept (8, multi)
    static let concepts: [TagOption] = [
        TagOption("form",        "Form",        "massing, geometry", symbol: "cube"),
        TagOption("space",       "Space",       "enclosure, sequence", symbol: "square.dashed"),
        TagOption("light",       "Light",       "daylight, shadow", symbol: "sun.max"),
        TagOption("materiality", "Materiality", "surface, texture", symbol: "square.grid.3x3"),
        TagOption("structure",   "Structure",   "tectonics, load", symbol: "square.stack.3d.up"),
        TagOption("context",     "Context",     "site, urban", symbol: "map"),
        TagOption("circulation", "Circulation", "movement, route", symbol: "arrow.triangle.turn.up.right.diamond"),
        TagOption("other",       "Other",       "something else", symbol: "ellipsis.circle"),
    ]

    // Rooms — single-select, filtered by typology
    static let rooms: [TagOption] = [
        TagOption("outdoor", "Outdoor"), TagOption("lobby", "Lobby"),
        TagOption("hall", "Hall"), TagOption("living", "Living"),
        TagOption("bedroom", "Bedroom"), TagOption("workspace", "Workspace"),
        TagOption("kitchen", "Kitchen"), TagOption("bathroom", "Bathroom"),
        TagOption("dining", "Dining"), TagOption("meeting", "Meeting"),
        TagOption("auditorium", "Auditorium"), TagOption("library", "Library"),
        TagOption("shop", "Shop"), TagOption("showroom", "Showroom"),
        TagOption("bar", "Bar"), TagOption("spa", "Spa"),
        TagOption("lab", "Lab"), TagOption("mechanical", "Mechanical"),
        TagOption("chapel", "Chapel"), TagOption("storage", "Storage"),
        TagOption("service", "Service"), TagOption("stairs", "Stairs"),
        TagOption("atrium", "Atrium"), TagOption("lounge", "Lounge"),
        TagOption("window", "Window"), TagOption("counter", "Counter"),
        TagOption("other", "Other"),
    ]
    static let roomsByTypology: [String: [String]] = [
        "Residential": ["outdoor", "living", "bedroom", "kitchen", "bathroom", "hall", "stairs", "other"],
        "Office":      ["outdoor", "lobby", "workspace", "meeting", "atrium", "lounge", "stairs", "other"],
        "Public":      ["outdoor", "lobby", "hall", "atrium", "auditorium", "library", "stairs", "other"],
        "Commercial":  ["outdoor", "lobby", "shop", "showroom", "workspace", "window", "counter", "other"],
        "Hospitality": ["outdoor", "lobby", "bedroom", "dining", "kitchen", "spa", "bathroom", "other"],
        "Other":       ["outdoor", "lobby", "hall", "workspace", "kitchen", "bathroom", "service", "other"],
        "Heritage":    ["outdoor", "hall", "living", "bedroom", "library", "chapel", "kitchen", "other"],
        // Landscape intentionally omitted — outdoor by definition.
    ]
    static func roomsFor(_ typology: String) -> [TagOption] {
        (roomsByTypology[typology] ?? []).compactMap { id in rooms.first { $0.id == id } }
    }

    // Element → grouped sub-elements (single select)
    static let elementGroups: [(group: String, items: [String])] = [
        ("Structural",  ["Column", "Beam", "Wall", "Arch", "Vault", "Dome", "Truss"]),
        ("Circulation", ["Door", "Window", "Stair", "Ramp", "Corridor", "Threshold", "Balcony"]),
        ("Enclosure",   ["Roof", "Ceiling", "Floor", "Facade"]),
        ("Ornament",    ["Cornice", "Railing", "Joint", "Pavement"]),
    ]

    // Materials (8, multi)
    static let materials: [String] = [
        "Concrete", "Brick", "Stone", "Timber",
        "Metal", "Glass", "Plaster", "Other",
    ]

    // Colors (8) — shown for Paint elements; hex for swatches
    static let colors: [(id: String, label: String, hex: String)] = [
        ("white",  "White",  "F0EFEA"), ("grey",   "Grey",   "9A9A95"),
        ("black",  "Black",  "1A1A18"), ("red",    "Red",    "C44536"),
        ("yellow", "Yellow", "D9B566"), ("green",  "Green",  "5C8060"),
        ("blue",   "Blue",   "4B6F9E"), ("earth",  "Earth",  "A87454"),
    ]

    // Graphic → Kind (8)
    static let graphicKinds: [TagOption] = [
        TagOption("artwork", "Artwork", "painting, sculpture", symbol: "paintpalette"),
        TagOption("book",    "Book",    "page, article", symbol: "book"),
        TagOption("drawing", "Drawing", "sketch, hand drawing", symbol: "pencil.and.outline"),
        TagOption("plan",    "Plan",    "floor plan, layout", symbol: "ruler"),
        TagOption("render",  "Render",  "visualisation, 3D", symbol: "cube.transparent"),
        TagOption("diagram", "Diagram", "schema, section", symbol: "chart.bar.doc.horizontal"),
        TagOption("contact", "Contact", "business card", symbol: "person.crop.rectangle"),
        TagOption("other",   "Other",   "note, sign, receipt", symbol: "ellipsis.rectangle"),
    ]

    // Graphic → Visual (multi)
    static let visual: [String] = [
        "Colorful", "Monochrome", "Textured", "Minimal", "Patterned",
        "Ornate", "Dark", "Light",
    ]

    /// Per-graphic-kind detail fields (key, placeholder) — matches the web
    /// app's GRAPHIC_FIELDS. Empty for kinds with no details (plan/render/…).
    static func graphicFields(for kind: String?) -> [(String, String)] {
        switch kind {
        case "artwork": return [("title", "Title"), ("creator", "Artist"), ("year", "Year"), ("source", "Source / where")]
        case "book":    return [("title", "Title"), ("creator", "Author"), ("source", "Publisher / library")]
        case "drawing": return [("title", "Title"), ("creator", "Creator"), ("year", "Year")]
        case "contact": return [("name", "Name"), ("company", "Company")]
        default:        return []
        }
    }
}

extension Color {
    /// Build a Color from a 6-digit hex string (no leading #).
    init(hex: String) {
        let v = UInt64(hex, radix: 16) ?? 0
        self.init(
            .sRGB,
            red:   Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue:  Double(v & 0xFF) / 255,
            opacity: 1
        )
    }
}
