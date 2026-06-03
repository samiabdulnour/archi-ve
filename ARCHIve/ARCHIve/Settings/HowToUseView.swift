import SwiftUI

/// Annotated guide to the camera layout — the native counterpart of the old
/// web app's numbered explainer.
struct HowToUseView: View {
    private struct Step: Identifiable {
        let id = UUID()
        let n: Int
        let title: String
        let tint: Color
        let body: String
    }

    private let steps: [Step] = [
        .init(n: 1, title: "Type", tint: Palette.coral,
              body: "Top-left: Building · Element · Graphic. Tap to set what you're capturing — it pre-fills the photo's tag."),
        .init(n: 2, title: "Tag · Reuse · More", tint: Palette.mint,
              body: "Top-right. The tag icon toggles Lite ↔ Full — Full opens the tagger right after the shutter, Lite saves instantly to tag later. Reuse applies your last photo's tags. The dots open camera settings."),
        .init(n: 3, title: "Shutter", tint: Palette.lemon,
              body: "Tap to capture. In Full you tag immediately; in Lite it's saved to the archive to tag whenever you like."),
        .init(n: 4, title: "Gallery", tint: Palette.coral,
              body: "Bottom-left shows your latest photo. Tap it to jump back into the archive."),
        .init(n: 5, title: "Reference vs Project", tint: Palette.mint,
              body: "Reference for things found out in the world. Project for a site-specific shoot — pick the project once, then shoot a whole sequence into it."),
        .init(n: 6, title: "Flip camera", tint: Palette.lemon,
              body: "Bottom-right — switch between the rear and front cameras."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(steps) { step in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(step.n)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(width: 30, height: 30)
                            .background(RoundedRectangle(cornerRadius: 7).fill(step.tint))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title).font(.headline)
                            Text(step.body).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.tile))
                }
            }
            .padding(16)
        }
        .background(Palette.paper.ignoresSafeArea())
        .navigationTitle("How to use")
        .navigationBarTitleDisplayMode(.inline)
    }
}
