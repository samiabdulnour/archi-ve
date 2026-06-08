import Foundation
import SwiftData

/// Full-fidelity local backup: writes every photo (image + optional label) plus
/// a JSON manifest of all tags / date / GPS / project into a folder, which the
/// user saves to Files (or AirDrops). Restore reads that folder back, skipping
/// any photos already present so it's safe to run twice.
enum BackupManager {
    /// One photo's metadata in the manifest. The image bytes live as separate
    /// files (images/<id>.jpg, labels/<id>.jpg) so the JSON stays small.
    struct Record: Codable {
        let id: String
        let createdAt: Date
        let latitude: Double?
        let longitude: Double?
        let project: String?
        let importedAt: Date?
        let humanTags: HumanTags
        let hasLabel: Bool
    }

    static let folderName = "Archi.vé Backup"

    /// Builds the backup folder in a temp directory and returns its URL.
    static func makeBackup(_ photos: [Photo]) throws -> URL {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(folderName, isDirectory: true)
        try? fm.removeItem(at: root)
        let imagesDir = root.appendingPathComponent("images", isDirectory: true)
        let labelsDir = root.appendingPathComponent("labels", isDirectory: true)
        try fm.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: labelsDir, withIntermediateDirectories: true)

        var records: [Record] = []
        for p in photos {
            try p.imageData.write(to: imagesDir.appendingPathComponent("\(p.id).jpg"))
            var hasLabel = false
            if let label = p.labelImageData {
                try label.write(to: labelsDir.appendingPathComponent("\(p.id).jpg"))
                hasLabel = true
            }
            records.append(Record(id: p.id, createdAt: p.createdAt,
                                  latitude: p.latitude, longitude: p.longitude,
                                  project: p.project, importedAt: p.importedAt,
                                  humanTags: p.humanTags, hasLabel: hasLabel))
        }

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted]
        try enc.encode(records).write(to: root.appendingPathComponent("manifest.json"))
        return root
    }

    /// Restores from a backup folder. Returns the number of photos added (those
    /// already in the archive, matched by id, are skipped).
    @discardableResult
    static func restore(from folder: URL, into context: ModelContext, existingIDs: Set<String>) throws -> Int {
        let manifestURL = folder.appendingPathComponent("manifest.json")
        let data = try Data(contentsOf: manifestURL)
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        let records = try dec.decode([Record].self, from: data)

        var added = 0
        for r in records where !existingIDs.contains(r.id) {
            let imgURL = folder.appendingPathComponent("images/\(r.id).jpg")
            guard let img = try? Data(contentsOf: imgURL) else { continue }
            let label: Data? = r.hasLabel
                ? (try? Data(contentsOf: folder.appendingPathComponent("labels/\(r.id).jpg")))
                : nil
            let photo = Photo(id: r.id, imageData: img, createdAt: r.createdAt,
                              latitude: r.latitude, longitude: r.longitude,
                              humanTags: r.humanTags, project: r.project,
                              importedAt: r.importedAt, labelImageData: label)
            context.insert(photo)
            added += 1
        }
        if added > 0 { try context.save() }
        return added
    }
}
