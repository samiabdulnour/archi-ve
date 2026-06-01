import SwiftUI
import SwiftData
import AVFoundation

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var camera = CameraController()
    @State private var motion = MotionLevel()

    @State private var focusPoint: CGPoint?
    @State private var focusRingVisible = false
    @State private var countdown: Int?
    @State private var shutterFlash = false
    @State private var baseZoom: CGFloat = 1.0
    @State private var savedCount = 0
    @State private var tagTarget: Photo?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if camera.authorized {
                    previewStack(in: geo.size)
                } else if camera.permissionDenied {
                    permissionView
                } else {
                    ProgressView().tint(.white)
                }
            }
        }
        .statusBarHidden(true)
        .onAppear {
            camera.requestAccessAndConfigure()
            motion.start()
            LocationProvider.shared.start()
        }
        .onDisappear {
            camera.stop()
            motion.stop()
            LocationProvider.shared.stop()
        }
        .sheet(item: $tagTarget, onDismiss: { camera.start() }) { photo in
            TagSheetView(photo: photo) { tagTarget = nil }
        }
    }

    // MARK: Preview + overlays

    @ViewBuilder
    private func previewStack(in size: CGSize) -> some View {
        ZStack {
            CameraPreview(controller: camera) { point in
                handleFocusTap(point)
            }
            .ignoresSafeArea()

            // Aspect-ratio letterbox mask
            aspectMask(in: size)

            if camera.gridOn { GridOverlay() }
            if camera.levelOn && !motion.isFlat { LevelOverlay(angle: motion.angle, isLevel: motion.isLevel) }

            if let p = focusPoint, focusRingVisible { FocusRing().position(p) }

            if shutterFlash { Color.white.ignoresSafeArea().transition(.opacity) }

            if let c = countdown {
                Text("\(c)")
                    .font(.system(size: 120, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
            }

            VStack {
                topBar
                Spacer()
                if camera.maxZoom > 1.5 { zoomBar }
                bottomBar
            }
            .padding(.vertical, 8)
        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in camera.setZoom(baseZoom * value) }
                .onEnded { _ in baseZoom = camera.zoomFactor }
        )
    }

    /// Letterbox bars that preview the chosen aspect-ratio crop. The preview
    /// itself fills the screen (resizeAspectFill); these dim the parts that
    /// will be cropped away on capture.
    @ViewBuilder
    private func aspectMask(in size: CGSize) -> some View {
        if let ratio = camera.aspect.portraitRatio {
            let targetH = min(size.height, size.width / ratio)
            let bar = max(0, (size.height - targetH) / 2)
            VStack(spacing: 0) {
                Color.black.opacity(0.55).frame(height: bar)
                Spacer(minLength: 0)
                Color.black.opacity(0.55).frame(height: bar)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }

    // MARK: Top controls

    private var topBar: some View {
        HStack(spacing: 28) {
            iconButton(flashIcon, active: camera.flashMode != .off) { cycleFlash() }
            iconButton(timerIcon, active: camera.timerSeconds != 0) { cycleTimer() }
            Menu {
                ForEach(CaptureAspect.allCases) { a in
                    Button(a.rawValue) { camera.aspect = a }
                }
            } label: {
                labelChip(camera.aspect.rawValue, active: camera.aspect != .full)
            }
            iconButton(camera.gridOn ? "grid" : "grid", active: camera.gridOn) { camera.gridOn.toggle() }
            iconButton("level", active: camera.levelOn, system: false) { camera.levelOn.toggle() }
            Spacer()
            iconButton("xmark", active: false) { dismiss() }
        }
        .padding(.horizontal, 20)
    }

    private var flashIcon: String {
        switch camera.flashMode {
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.a.fill"
        default: return "bolt.slash.fill"
        }
    }
    private var timerIcon: String {
        camera.timerSeconds == 0 ? "timer" : "timer"
    }

    // MARK: Bottom controls

    private var bottomBar: some View {
        HStack {
            Text("\(savedCount)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 60)
            Spacer()
            shutterButton
            Spacer()
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var shutterButton: some View {
        Button(action: onShutter) {
            ZStack {
                Circle().stroke(.white, lineWidth: 4).frame(width: 74, height: 74)
                Circle().fill(.white).frame(width: 60, height: 60)
            }
        }
        .disabled(countdown != nil)
    }

    private var zoomBar: some View {
        HStack(spacing: 10) {
            ForEach(zoomStops, id: \.self) { z in
                Button {
                    camera.setZoom(z); baseZoom = z
                } label: {
                    Text(z == 1 ? "1×" : String(format: "%.0f×", z))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(abs(camera.zoomFactor - z) < 0.1 ? .yellow : .white)
                        .frame(width: 40, height: 30)
                        .background(.black.opacity(0.35), in: Capsule())
                }
            }
        }
        .padding(.bottom, 14)
    }

    private var zoomStops: [CGFloat] {
        var stops: [CGFloat] = [1]
        if camera.maxZoom >= 2 { stops.append(2) }
        if camera.maxZoom >= 4 { stops.append(4) }
        return stops
    }

    private var permissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill").font(.system(size: 44)).foregroundStyle(.white)
            Text("Camera access needed").foregroundStyle(.white)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: Control widgets

    private func iconButton(_ name: String, active: Bool, system: Bool = true, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if system {
                    Image(systemName: name)
                } else {
                    // custom "level" glyph
                    Image(systemName: "ruler")
                }
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(active ? .yellow : .white)
            .frame(width: 34, height: 34)
        }
    }

    private func labelChip(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(active ? .yellow : .white)
            .frame(minWidth: 34, minHeight: 34)
    }

    // MARK: Actions

    private func cycleFlash() {
        switch camera.flashMode {
        case .off: camera.flashMode = .auto
        case .auto: camera.flashMode = .on
        default: camera.flashMode = .off
        }
    }

    private func cycleTimer() {
        switch camera.timerSeconds {
        case 0: camera.timerSeconds = 3
        case 3: camera.timerSeconds = 10
        default: camera.timerSeconds = 0
        }
    }

    private func handleFocusTap(_ point: CGPoint) {
        camera.focusAndExpose(atLayerPoint: point)
        focusPoint = point
        withAnimation(.easeOut(duration: 0.15)) { focusRingVisible = true }
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation(.easeOut(duration: 0.3)) { focusRingVisible = false }
        }
    }

    private func onShutter() {
        let secs = camera.timerSeconds
        if secs > 0 {
            Task { await runCountdown(from: secs); performCapture() }
        } else {
            performCapture()
        }
    }

    private func runCountdown(from seconds: Int) async {
        for s in stride(from: seconds, through: 1, by: -1) {
            countdown = s
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        countdown = nil
    }

    private func performCapture() {
        withAnimation(.easeIn(duration: 0.05)) { shutterFlash = true }
        camera.capture { data in
            withAnimation(.easeOut(duration: 0.2)) { shutterFlash = false }
            guard let data else { return }
            let coord = LocationProvider.shared.last
            let photo = Photo(imageData: data,
                              latitude: coord?.latitude,
                              longitude: coord?.longitude)
            modelContext.insert(photo)
            try? modelContext.save()
            savedCount += 1
            // Pause the session and open the tag sheet for this shot.
            camera.stop()
            tagTarget = photo
        }
    }
}

// MARK: - Overlays

private struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { p in
                let w = geo.size.width, h = geo.size.height
                for i in 1...2 {
                    let x = w * CGFloat(i) / 3
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: h))
                    let y = h * CGFloat(i) / 3
                    p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y))
                }
            }
            .stroke(.white.opacity(0.35), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}

/// Artificial-horizon line: a bar through center that rotates with the phone
/// (full angle, not deviation), green when level. Matches the web behaviour.
private struct LevelOverlay: View {
    let angle: Double
    let isLevel: Bool
    var body: some View {
        Rectangle()
            .fill(isLevel ? Color.green : Color.white.opacity(0.9))
            .frame(width: 120, height: 2)
            .rotationEffect(.degrees(-angle))
            .shadow(color: .black.opacity(0.4), radius: 1)
            .animation(.linear(duration: 0.05), value: angle)
            .allowsHitTesting(false)
    }
}

private struct FocusRing: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(Color.yellow, lineWidth: 1.5)
            .frame(width: 78, height: 78)
            .allowsHitTesting(false)
    }
}
