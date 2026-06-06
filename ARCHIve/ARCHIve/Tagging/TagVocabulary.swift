import SwiftUI
import UIKit

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

    // Building → Typology (10)
    static let typology: [String] = [
        "Residential", "Office", "Public", "Commercial", "Civic",
        "Hospitality", "Heritage", "Industrial", "Landscape", "Other",
    ]

    // Building → Concept (10, multi)
    static let concepts: [TagOption] = [
        TagOption("form",        "Form",        "massing, geometry"),
        TagOption("space",       "Space",       "enclosure, sequence"),
        TagOption("light",       "Light",       "daylight, shadow"),
        TagOption("materiality", "Materiality", "surface, texture"),
        TagOption("structure",   "Structure",   "tectonics, load"),
        TagOption("context",     "Context",     "site, urban"),
        TagOption("circulation", "Circulation", "movement, route"),
        TagOption("scale",       "Scale",       "proportion, size"),
        TagOption("threshold",   "Threshold",   "edge, entry"),
        TagOption("other",       "Other",       "something else"),
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
    // Exactly 10 rooms per typology (9 + Other) so they fill two rows of five.
    static let roomsByTypology: [String: [String]] = [
        "Residential": ["outdoor", "living", "bedroom", "kitchen", "bathroom", "dining", "hall", "stairs", "storage", "other"],
        "Office":      ["outdoor", "lobby", "workspace", "meeting", "atrium", "lounge", "kitchen", "bathroom", "stairs", "other"],
        "Public":      ["outdoor", "lobby", "hall", "atrium", "auditorium", "library", "showroom", "bathroom", "stairs", "other"],
        "Commercial":  ["outdoor", "lobby", "shop", "showroom", "workspace", "counter", "window", "storage", "stairs", "other"],
        "Civic":       ["outdoor", "lobby", "hall", "meeting", "auditorium", "library", "workspace", "bathroom", "stairs", "other"],
        "Hospitality": ["outdoor", "lobby", "bedroom", "dining", "kitchen", "bar", "spa", "bathroom", "stairs", "other"],
        "Heritage":    ["outdoor", "hall", "living", "bedroom", "library", "chapel", "kitchen", "atrium", "stairs", "other"],
        "Industrial":  ["outdoor", "workspace", "service", "storage", "mechanical", "lab", "counter", "bathroom", "stairs", "other"],
        "Other":       ["outdoor", "lobby", "hall", "workspace", "kitchen", "bathroom", "service", "storage", "stairs", "other"],
        // Landscape intentionally omitted — outdoor by definition.
    ]
    static func roomsFor(_ typology: String) -> [TagOption] {
        (roomsByTypology[typology] ?? []).compactMap { id in rooms.first { $0.id == id } }
    }

    // Element → Category → sub-element (single-select each), like the web app.
    static let elementCategories: [(category: String, items: [String])] = [
        ("Structure", ["Wall", "Column", "Beam", "Slab"]),
        ("Vertical",  ["Stair", "Ramp", "Railing", "Elevator"]),
        ("Opening",   ["Door", "Window", "Curtain wall", "Skylight"]),
        ("Envelope",  ["Roof", "Facade", "Ceiling", "Floor"]),
        ("Finish",    ["Tile", "Cladding", "Paint", "Render"]),
        ("Detail",    ["Joint", "Section", "Profile", "Pattern"]),
        ("Service",   ["HVAC", "Plumbing", "Electrical", "Fire"]),
        ("Product",   ["Furniture", "Lighting", "Appliance", "Decor"]),
    ]
    static func elementItems(for category: String) -> [String] {
        elementCategories.first { $0.category == category }?.items ?? []
    }

    // Materials (10, multi)
    static let materials: [String] = [
        "Concrete", "Brick", "Stone", "Timber", "Metal",
        "Glass", "Plaster", "Tile", "Earth", "Other",
    ]

    // Colors (10) — optional; hex for swatches
    static let colors: [(id: String, label: String, hex: String)] = [
        ("white",  "White",  "F0EFEA"), ("grey",   "Grey",   "9A9A95"),
        ("black",  "Black",  "1A1A18"), ("red",    "Red",    "C44536"),
        ("orange", "Orange", "D9803A"), ("yellow", "Yellow", "D9B566"),
        ("green",  "Green",  "5C8060"), ("blue",   "Blue",   "4B6F9E"),
        ("brown",  "Brown",  "6B4F3A"), ("earth",  "Earth",  "A87454"),
    ]

    // Graphic → Kind (10)
    static let graphicKinds: [TagOption] = [
        TagOption("artwork", "Artwork", "painting, sculpture"),
        TagOption("book",    "Book",    "page, article"),
        TagOption("drawing", "Drawing", "sketch, hand drawing"),
        TagOption("plan",    "Plan",    "floor plan, layout"),
        TagOption("render",  "Render",  "visualisation, 3D"),
        TagOption("diagram", "Diagram", "schema, section"),
        TagOption("photo",   "Photo",   "photograph"),
        TagOption("sign",    "Sign",    "signage, lettering"),
        TagOption("contact", "Contact", "business card"),
        TagOption("other",   "Other",   "note, receipt"),
    ]

    // Graphic → Visual (10, multi)
    static let visual: [String] = [
        "Colorful", "Monochrome", "Textured", "Minimal", "Patterned",
        "Ornate", "Geometric", "Organic", "Dark", "Light",
    ]

    /// SF Symbol for a tag option, replacing the old line-art glyphs.
    /// Guarded by `safe()` so an unavailable symbol never renders blank.
    static func symbol(_ group: String, _ id: String) -> String {
        let raw: String
        switch group {
        case "typology":
            raw = ["Residential": "house", "Office": "building", "Public": "building.columns",
                   "Commercial": "storefront", "Civic": "flag", "Hospitality": "bed.double",
                   "Heritage": "building.columns.fill", "Industrial": "gearshape.2",
                   "Landscape": "tree", "Other": "ellipsis"][id] ?? "building.2"
        case "concept":
            raw = ["form": "cube", "space": "square.dashed", "light": "sun.max", "materiality": "square.grid.3x3",
                   "structure": "square.stack.3d.up", "context": "map", "circulation": "figure.walk",
                   "scale": "ruler", "threshold": "door.left.hand.open", "other": "ellipsis"][id] ?? "circle"
        case "elementcat":
            raw = ["Structure": "square.stack.3d.up", "Vertical": "stairs", "Opening": "door.left.hand.closed",
                   "Envelope": "house", "Finish": "paintbrush", "Detail": "ruler",
                   "Service": "wrench.and.screwdriver", "Product": "sofa"][id] ?? "square"
        case "elementsub":
            raw = elementSubSymbols[id] ?? "square"
        case "graphic":
            raw = ["artwork": "photo.artframe", "book": "book", "drawing": "pencil.and.outline", "plan": "ruler",
                   "render": "cube.transparent", "diagram": "chart.bar", "photo": "photo", "sign": "signpost.right",
                   "contact": "person.crop.rectangle", "other": "ellipsis"][id] ?? "doc"
        case "visual":
            raw = ["Colorful": "paintpalette", "Monochrome": "circle.lefthalf.filled", "Textured": "square.grid.3x3",
                   "Minimal": "square", "Patterned": "circle.grid.2x2", "Ornate": "seal", "Geometric": "triangle",
                   "Organic": "leaf", "Dark": "moon", "Light": "sun.max"][id] ?? "square"
        case "room":
            raw = roomSymbols[id] ?? "square.dashed"
        default:
            raw = "square"
        }
        return safe(raw)
    }

    static let roomSymbols: [String: String] = [
        "outdoor": "leaf", "lobby": "door.left.hand.open", "hall": "rectangle.portrait", "living": "sofa",
        "bedroom": "bed.double", "workspace": "laptopcomputer", "kitchen": "fork.knife", "bathroom": "shower",
        "dining": "fork.knife", "meeting": "person.3", "auditorium": "theatermasks", "library": "books.vertical",
        "shop": "cart", "showroom": "bag", "bar": "wineglass", "spa": "drop", "lab": "testtube.2",
        "mechanical": "gearshape.2", "chapel": "cross", "storage": "archivebox", "service": "wrench.and.screwdriver",
        "stairs": "stairs", "atrium": "building.columns", "lounge": "sofa", "window": "rectangle.split.2x2",
        "counter": "rectangle.split.3x1", "other": "ellipsis",
    ]

    static let elementSubSymbols: [String: String] = [
        "Wall": "rectangle.portrait", "Column": "building.columns", "Beam": "rectangle", "Slab": "square",
        "Stair": "stairs", "Ramp": "line.diagonal", "Railing": "rectangle.split.3x1", "Elevator": "arrow.up.arrow.down",
        "Door": "door.left.hand.closed", "Window": "rectangle.split.2x2", "Curtain wall": "rectangle.split.3x3",
        "Skylight": "sun.max", "Roof": "triangle", "Facade": "rectangle.grid.3x2",
        "Ceiling": "rectangle.tophalf.inset.filled", "Floor": "rectangle.bottomhalf.inset.filled",
        "Tile": "square.grid.3x3", "Cladding": "square.grid.2x2", "Paint": "paintbrush.pointed", "Render": "cube.transparent",
        "Joint": "link", "Section": "square.dashed.inset.filled", "Profile": "squareshape", "Pattern": "circle.grid.2x2",
        "HVAC": "wind", "Plumbing": "drop", "Electrical": "bolt", "Fire": "flame",
        "Furniture": "sofa", "Lighting": "lightbulb", "Appliance": "refrigerator", "Decor": "leaf",
    ]

    /// Returns `name` if the SF Symbol exists, else a neutral fallback.
    static func safe(_ name: String) -> String {
        UIImage(systemName: name) != nil ? name : "square.dashed"
    }

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
