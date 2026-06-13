import SwiftUI

/// Film-simulation picker as a horizontal **name wheel** above the shutter —
/// like a camera mode dial. Swipe to rotate; the centred name is selected.
/// Names only, no thumbnails. Less is more.
struct LooksWheel: View {
    @Bindable var camera: CameraController
    @State private var centered: CameraLook?

    private let itemWidth: CGFloat = 120

    var body: some View {
        GeometryReader { geo in
            let side = max(0, (geo.size.width - itemWidth) / 2)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(CameraLook.allCases) { look in
                        let on = centered == look
                        Text(look.rawValue.uppercased())
                            .font(.system(size: 11, weight: on ? .semibold : .regular))
                            .tracking(1.4)
                            .foregroundStyle(on ? Palette.lemon : .white.opacity(0.5))
                            .frame(width: itemWidth)
                            .id(look)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $centered, anchor: .center)
            .contentMargins(.horizontal, side, for: .scrollContent)
            .onAppear { centered = camera.colorLook }
            .onChange(of: centered) { _, v in
                guard let v, v != camera.colorLook else { return }
                camera.setColorLook(v)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .frame(height: 22)
    }
}
