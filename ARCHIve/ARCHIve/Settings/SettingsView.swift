import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// App settings, mirroring the old web app: Projects, Appearance, Capture flow
/// steps, Custom materials, and the How-to guide.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Photo.createdAt, order: .reverse) private var photos: [Photo]

    @AppStorage("appearance") private var appearance = "auto"
    @AppStorage("customProjects") private var customProjectsRaw = ""

    @State private var newProject = ""

    // Backup
    @State private var exportURL: URL?
    @State private var showExportShare = false
    @State private var showImporter = false
    @State private var backupMessage = ""
    @State private var showBackupResult = false

    private var derivedProjects: [String] {
        var seen = Set<String>(); var out: [String] = []
        for p in photos { if let n = p.project, !n.isEmpty, seen.insert(n).inserted { out.append(n) } }
        return out
    }
    private var allProjects: [String] {
        (Set(derivedProjects).union(Settings.list(customProjectsRaw))).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section { projectsBody } header: { header("Projects") }
                Section { appearanceBody } header: { header("Appearance") }
                Section { captureStepsBody } header: { header("Capture flow steps") }
                Section { backupBody } header: { header("Backup") } footer: {
                    Text("Saves all photos + tags to a folder you can keep in Files or iCloud Drive. Restore adds back any photos not already here.")
                }
                Section {
                    NavigationLink { HowToUseView() } label: { Text("How to use ARCHI-ve") }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.paper.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .tint(Palette.coral)
        .sheet(isPresented: $showExportShare) {
            if let exportURL { ActivityView(items: [exportURL]) }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.folder]) { result in
            handleRestore(result)
        }
        .alert("Backup", isPresented: $showBackupResult) {
            Button("OK") { }
        } message: { Text(backupMessage) }
    }

    // MARK: Backup
    @ViewBuilder private var backupBody: some View {
        Button {
            do {
                exportURL = try BackupManager.makeBackup(photos)
                showExportShare = true
            } catch {
                backupMessage = "Backup failed: \(error.localizedDescription)"
                showBackupResult = true
            }
        } label: {
            Label("Back up all photos", systemImage: "square.and.arrow.up.on.square")
        }
        .disabled(photos.isEmpty)

        Button {
            showImporter = true
        } label: {
            Label("Restore from backup", systemImage: "square.and.arrow.down.on.square")
        }
    }

    private func handleRestore(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let n = try BackupManager.restore(from: url, into: modelContext,
                                                  existingIDs: Set(photos.map(\.id)))
                backupMessage = n == 0 ? "Nothing new to restore — everything in this backup is already here."
                                       : "Restored \(n) photo\(n == 1 ? "" : "s")."
            } catch {
                backupMessage = "Restore failed. Make sure you picked an ARCHI-ve backup folder.\n\n\(error.localizedDescription)"
            }
            showBackupResult = true
        case .failure(let error):
            backupMessage = "Restore failed: \(error.localizedDescription)"
            showBackupResult = true
        }
    }

    private func header(_ t: String) -> some View {
        Text(t).font(.caption.weight(.semibold)).tracking(1.2)
            .foregroundStyle(Palette.coral).textCase(.uppercase)
    }

    // MARK: Projects
    @ViewBuilder private var projectsBody: some View {
        if allProjects.isEmpty {
            Text("No projects yet.").foregroundStyle(.secondary)
        } else {
            ForEach(allProjects, id: \.self) { Text($0) }
                .onDelete { idx in
                    var custom = Settings.list(customProjectsRaw)
                    for i in idx { let name = allProjects[i]; custom.removeAll { $0 == name } }
                    customProjectsRaw = Settings.join(custom)
                }
        }
        HStack {
            TextField("New project name", text: $newProject)
            Button("Add") {
                let n = newProject.trimmingCharacters(in: .whitespaces)
                guard !n.isEmpty else { return }
                var custom = Settings.list(customProjectsRaw); custom.append(n)
                customProjectsRaw = Settings.join(custom); newProject = ""
            }.disabled(newProject.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: Appearance
    private var appearanceBody: some View {
        Picker("Appearance", selection: $appearance) {
            Text("Light").tag("light"); Text("Dark").tag("dark"); Text("Auto").tag("auto")
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    // MARK: Capture flow steps
    private var captureStepsBody: some View {
        ForEach(TagVocab.types) { t in
            NavigationLink { FlowStepsView(flow: t.id, title: t.label) } label: { Text(t.label) }
        }
    }

}

/// Small helpers for the comma-separated @AppStorage lists, plus the resolved
/// colour scheme for the chosen appearance.
enum Settings {
    static func list(_ raw: String) -> [String] {
        raw.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
    }
    static func join(_ items: [String]) -> String { items.joined(separator: "\n") }

    static func colorScheme(for appearance: String) -> ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }
    static var customMaterials: [String] {
        list(UserDefaults.standard.string(forKey: "customMaterials") ?? "")
    }
    static var customProjects: [String] {
        list(UserDefaults.standard.string(forKey: "customProjects") ?? "")
    }

    // MARK: Capture flow steps

    /// (key, label) per Kind — the sections the user can show/hide.
    static func flowSteps(_ flow: String) -> [(String, String)] {
        switch flow {
        case "element": return [("element", "Element"), ("materiality", "Materiality"), ("colour", "Colour"),
                                ("authoryear", "Author & year"), ("note", "Note")]
        case "graphic": return [("kind", "Kind"), ("details", "Details"), ("visual", "Visual"), ("note", "Note")]
        default:        return [("typology", "Typology"), ("concept", "Concept"), ("materiality", "Materiality"),
                                ("colour", "Colour"), ("authoryear", "Author & year"), ("note", "Note")]
        }
    }
    /// Concept, Colour, Visual are off by default everywhere; Materiality is
    /// off by default for Buildings only (kept on for Elements). Rest on.
    static func flowDefault(_ flow: String, _ step: String) -> Bool {
        if step == "concept" || step == "colour" || step == "visual" { return false }
        if step == "materiality" && flow == "building" { return false }
        return true
    }

    static func flowEnabled(_ flow: String, _ step: String) -> Bool {
        flowDict()["\(flow).\(step)"] ?? flowDefault(flow, step)
    }
    static func flowDict() -> [String: Bool] {
        let raw = UserDefaults.standard.string(forKey: "flowSteps") ?? ""
        return (try? JSONDecoder().decode([String: Bool].self, from: Data(raw.utf8))) ?? [:]
    }
}

/// Toggle which tagging sections appear for a Kind (the capture flow).
private struct FlowStepsView: View {
    let flow: String
    let title: String
    @AppStorage("flowSteps") private var raw = ""

    var body: some View {
        Form {
            Section {
                ForEach(Settings.flowSteps(flow), id: \.0) { step in
                    Toggle(step.1, isOn: binding(step.0))
                }
            } footer: {
                Text("Hidden sections are skipped while tagging. Kind/Typology/Element stay available.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.paper.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .tint(Palette.coral)
    }

    private func binding(_ step: String) -> Binding<Bool> {
        Binding(
            get: { Settings.flowEnabled(flow, step) },
            set: { newVal in
                var d = Settings.flowDict()
                d["\(flow).\(step)"] = newVal
                raw = String(data: (try? JSONEncoder().encode(d)) ?? Data(), encoding: .utf8) ?? ""
            }
        )
    }
}
