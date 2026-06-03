import SwiftUI
import SwiftData

/// App settings, mirroring the old web app: Projects, Appearance, Capture flow
/// steps, Custom materials, and the How-to guide.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Photo.createdAt, order: .reverse) private var photos: [Photo]

    @AppStorage("appearance") private var appearance = "auto"
    @AppStorage("customProjects") private var customProjectsRaw = ""
    @AppStorage("customMaterials") private var customMaterialsRaw = ""

    @State private var newProject = ""
    @State private var newMaterial = ""

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
                Section { customMaterialsBody } header: { header("Custom materials") }
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
            NavigationLink { CaptureStepView(kind: t.id, title: t.label) } label: { Text(t.label) }
        }
    }

    // MARK: Custom materials
    @ViewBuilder private var customMaterialsBody: some View {
        let custom = Settings.list(customMaterialsRaw)
        if custom.isEmpty {
            Text("No custom items yet.").foregroundStyle(.secondary)
        } else {
            ForEach(custom, id: \.self) { Text($0) }
                .onDelete { idx in
                    var c = custom; c.remove(atOffsets: idx); customMaterialsRaw = Settings.join(c)
                }
        }
        HStack {
            TextField("Add new…", text: $newMaterial)
            Button("Add") {
                let n = newMaterial.trimmingCharacters(in: .whitespaces)
                guard !n.isEmpty else { return }
                var c = custom; c.append(n); customMaterialsRaw = Settings.join(c); newMaterial = ""
            }.disabled(newMaterial.trimmingCharacters(in: .whitespaces).isEmpty)
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
}

/// Read-only view of a Kind's tag options (the "capture flow" for that Kind).
private struct CaptureStepView: View {
    let kind: String
    let title: String

    var body: some View {
        Form {
            switch kind {
            case "building":
                listSection("Typology", TagVocab.typology)
                listSection("Concepts", TagVocab.concepts.map(\.label))
                listSection("Materials", TagVocab.materials + Settings.customMaterials)
            case "element":
                ForEach(TagVocab.elementGroups, id: \.group) { g in
                    listSection(g.group, g.items)
                }
                listSection("Materials", TagVocab.materials + Settings.customMaterials)
            default:
                listSection("Kinds", TagVocab.graphicKinds.map(\.label))
                listSection("Visual", TagVocab.visual)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.paper.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func listSection(_ title: String, _ items: [String]) -> some View {
        Section(title) { ForEach(items, id: \.self) { Text($0) } }
    }
}
