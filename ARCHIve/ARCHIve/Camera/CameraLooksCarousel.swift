import SwiftUI
import CoreImage

/// Film-look picker: a horizontal strip of **live thumbnails** — each tile shows
/// the current scene with that look applied (like Ricoh/Fuji). Tap to select.
struct LooksCarousel: View {
    @Bindable var camera: CameraController
    @State private var thumbs: [String: UIImage] = [:]

    private let timer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()
    private static let ctx = CIContext(options: [.useSoftwareRenderer: false])

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CameraLook.allCases) { look in
                    let on = camera.colorLook == look
                    VStack(spacing: 4) {
                        ZStack {
                            Color.white.opacity(0.12)
                            if let img = thumbs[look.rawValue] {
                                Image(uiImage: img).resizable().scaledToFill()
                            }
                        }
                        .frame(width: 50, height: 66)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(on ? Palette.lemon : .white.opacity(0.3),
                                          lineWidth: on ? 2 : 0.5))
                        Text(look.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(on ? Palette.lemon : .white.opacity(0.85))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { camera.setColorLook(look) }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 92)
        .onAppear(perform: refresh)
        .onReceive(timer) { _ in refresh() }
    }

    private func refresh() {
        guard let frame = camera.latestFrame else { return }
        let e = frame.extent
        guard e.width > 1 else { return }
        let scale = 150 / e.width
        let base = frame.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let rect = base.extent
        Task.detached(priority: .userInitiated) {
            var out: [String: UIImage] = [:]
            for look in CameraLook.allCases {
                let ci = CameraProcessing.colored(base, look: look)
                if let cg = LooksCarousel.ctx.createCGImage(ci, from: rect) {
                    out[look.rawValue] = UIImage(cgImage: cg)
                }
            }
            let result = out
            await MainActor.run { thumbs = result }
        }
    }
}
