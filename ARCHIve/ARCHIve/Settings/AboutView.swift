import SwiftUI

/// About ARCHI-ve — identity, author, a short explanation, version and an
/// authorship / copyright line.
struct AboutView: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(v) (\(b))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    (Text("ARCHI").foregroundStyle(Palette.ink)
                     + Text("-ve.").foregroundStyle(Palette.coral))
                        .font(.system(size: 40, weight: .bold))
                    Text("by Sami Abdulnour").font(.subheadline).foregroundStyle(Palette.ink3)
                }

                Text("A fast, private journal for the architecture you notice — capture in a tap, tag in two, and find it again later by time, reference, project, or place.")
                    .font(.callout).foregroundStyle(Palette.ink2)

                VStack(alignment: .leading, spacing: 8) {
                    Text("THE IDEA").font(.caption.weight(.semibold)).tracking(1.2)
                        .foregroundStyle(Palette.coral)
                    Text("Architects collect references constantly — a façade, a joint, a book spread, a model. ARCHI-ve turns that habit into a structured, searchable archive: photograph it, answer two quick questions, and your library organises itself by what things are and where you found them. Everything stays on your device and syncs privately through your iCloud.")
                        .font(.callout).foregroundStyle(Palette.ink2)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text(version).font(.footnote).foregroundStyle(Palette.ink3)
                    Text("© 2026 Sami Abdulnour. All rights reserved.")
                        .font(.footnote).foregroundStyle(Palette.ink3)
                }
            }
            .padding(24)
        }
        .background(Palette.paper.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
