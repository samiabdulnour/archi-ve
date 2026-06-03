import SwiftUI
import SwiftData
import AVFoundation

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Photo.createdAt, order: .reverse) private var allPhotos: [Photo]

    @State private var camera = CameraController()
    @State private var motion = MotionLevel()

    @State private var focusPoint: CGPoint?
    @State private var focusRingVisible = false
    @State private var countdown: Int?
    @State private var shutterFlash = false
    @State private var baseZoom: CGFloat = 1.0
    @State private var savedCount = 0
    @State private var tagTarget: Photo?

    @State private var tagMode: TagMode = .full
    @State private var reuseTags: HumanTags?
    @State private var showSettings = false
    @State private var showProjectPicker = false

    enum TagMode { case lite, full }

    private var latest: Photo? { allPhotos.first }

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
        .sheet(isPresented: $showSettings) {
            CameraSettingsSheet(camera: camera)
        }
        .sheet(isPresented: $showProjectPicker) {
            ProjectPickerSheet(projects: existingProjects, current: camera.currentProject) { name in
                camera.currentProject = name
                camera.mode = .project
            }
        }
    }

    private var existingProjects: [String] {
        var seen = Set<String>(); var out: [String] = []
        for p in allPhotos { if let n = p.project, !n.isEmpty, seen.insert(n).inserted { out.append(n) } }
        return out.sorted()
    }

    // MARK: Preview + overlays

    @ViewBuilder
    private func previewStack(in size: CGSize) -> some View {
        let ratio = camera.aspect.portraitRatio
        let frameW = size.width
        let frameH = min(size.height, frameW / ratio)

        ZStack {
            ZStack {
                CameraPreview(controller: camera) { point in handleFocusTap(point) }
                if camera.gridOn { GridOverlay() }
                if camera.levelOn && !motion.isFlat {
                    LevelOverlay(angle: motion.angle, isLevel: motion.isLevel)
                }
                if let p = focusPoint, focusRingVisible { FocusRing().position(p) }
            }
            .frame(width: frameW, height: frameH)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                MagnifyGesture()
                    .onChanged { value in camera.setZoom(baseZoom * value.magnification) }
                    .onEnded { _ in baseZoom = camera.zoomFactor }
            )

            if shutterFlash { Color.white.ignoresSafeArea() }

            if let c = countdown {
                Text("\(c)")
                    .font(.system(size: 120, weight: .thin, design: .rounded))
                    .foregroundStyle(.white).shadow(radius: 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(alignment: .top) {
                typeSegment
                Spacer()
                actionPill
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 16) {
                if camera.maxZoom > 1.5 { zoomBar }
                shutterButton
                ZStack {
                    HStack {
                        thumbnailButton
                        Spacer()
                        flipButton
                    }
                    modeToggle
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 6)
        }
    }

    // MARK: Top — Type segment + action pill

    private var typeSegment: some View {
        HStack(spacing: 2) {
            ForEach(TagVocab.types) { t in
                let active = camera.captureType == t.id
                Button { camera.captureType = t.id } label: {
                    KindGlyph(id: t.id, color: active ? .black : .white.opacity(0.75))
                        .frame(width: 26, height: 26)
                        .padding(5)
                        .background(active ? Circle().fill(.white) : Circle().fill(.clear))
                }
            }
        }
        .padding(5)
        .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
    }

    private var actionPill: some View {
        HStack(spacing: 6) {
            pillButton(tagMode == .full ? "tag.fill" : "tag", active: tagMode == .full) {
                tagMode = tagMode == .full ? .lite : .full
            }
            pillButton("arrow.2.squarepath", active: reuseTags != nil) {
                reuseTags = (reuseTags == nil) ? latest?.humanTags : nil
            }
            pillButton("ellipsis", active: false) { showSettings = true }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
    }

    private func pillButton(_ symbol: String, active: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(active ? Palette.coral : .white)
                .frame(width: 26, height: 26)
        }
    }

    // MARK: Bottom — shutter, mode toggle, thumbnail, flip

    private var shutterButton: some View {
        Button(action: onShutter) {
            ZStack {
                Circle().stroke(.white, lineWidth: 4).frame(width: 74, height: 74)
                Circle().fill(camera.mode == .project ? Palette.lemon : Palette.mint)
                    .frame(width: 60, height: 60)
            }
        }
        .disabled(countdown != nil)
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeSegment("Reference", on: camera.mode == .reference, tint: Palette.mint) {
                camera.mode = .reference
            }
            modeSegment("Project", on: camera.mode == .project, tint: Palette.lemon) {
                if camera.currentProject == nil { showProjectPicker = true } else { camera.mode = .project }
            }
        }
        .padding(3)
        .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
    }

    private func modeSegment(_ title: String, on: Bool, tint: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(on ? .black : .white)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(on ? Capsule().fill(tint) : Capsule().fill(.clear))
        }
    }

    private var thumbnailButton: some View {
        Button { dismiss() } label: {
            Group {
                if let latest {
                    PhotoThumbnail(photo: latest)
                        .frame(width: 42, height: 42)
                        .clipShape(Circle())
                } else {
                    Circle().fill(.black.opacity(0.3)).frame(width: 42, height: 42)
                        .overlay(Image(systemName: "photo").foregroundStyle(.white.opacity(0.7)))
                }
            }
            .overlay(Circle().stroke(.white, lineWidth: 2))
        }
    }

    private var flipButton: some View {
        Button { camera.flipCamera() } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Circle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
        }
    }

    private var zoomBar: some View {
        HStack(spacing: 10) {
            ForEach(zoomStops, id: \.self) { z in
                Button { camera.setZoom(z); baseZoom = z } label: {
                    Text(z == 1 ? "1×" : String(format: "%.0f×", z))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(abs(camera.zoomFactor - z) < 0.1 ? Palette.lemon : .white)
                        .frame(width: 40, height: 30)
                        .background(.black.opacity(0.35), in: Capsule())
                }
            }
        }
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
            .buttonStyle(.borderedProminent).tint(Palette.coral)
        }
    }

    // MARK: Actions

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
        // A quick shutter blink, decoupled from how long the capture takes —
        // previously the white overlay stayed up for the whole (~1s) capture.
        withAnimation(.easeIn(duration: 0.04)) { shutterFlash = true }
        Task {
            try? await Task.sleep(nanoseconds: 90_000_000)
            withAnimation(.easeOut(duration: 0.18)) { shutterFlash = false }
        }
        camera.capture { data in
            guard let data else { return }
            let coord = LocationProvider.shared.last
            let photo = Photo(imageData: data,
                              latitude: coord?.latitude,
                              longitude: coord?.longitude,
                              humanTags: prefilledTags(),
                              project: camera.mode == .project ? camera.currentProject : nil)
            modelContext.insert(photo)
            try? modelContext.save()
            savedCount += 1
            if tagMode == .full {
                camera.stop()
                tagTarget = photo
            }
        }
    }

    /// Seed the new photo's tags: the Type chosen on the camera, plus any tags
    /// being reused from the last shot.
    private func prefilledTags() -> HumanTags {
        var t = reuseTags ?? HumanTags()
        t.type = camera.captureType
        return t
    }
}

// MARK: - Settings sheet (the "More" / ⋯ action)

private struct CameraSettingsSheet: View {
    @Bindable var camera: CameraController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Overlays") {
                    Toggle("Grid", isOn: $camera.gridOn)
                    Toggle("Level", isOn: $camera.levelOn)
                }
                Section("Capture") {
                    Picker("Flash", selection: $camera.flashMode) {
                        Text("Off").tag(AVCaptureDevice.FlashMode.off)
                        Text("Auto").tag(AVCaptureDevice.FlashMode.auto)
                        Text("On").tag(AVCaptureDevice.FlashMode.on)
                    }
                    Picker("Aspect", selection: $camera.aspect) {
                        ForEach(CaptureAspect.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Timer", selection: $camera.timerSeconds) {
                        Text("Off").tag(0); Text("3s").tag(3); Text("10s").tag(10)
                    }
                }
            }
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium])
        .tint(Palette.coral)
    }
}

// MARK: - Project picker (Project mode)

private struct ProjectPickerSheet: View {
    let projects: [String]
    let current: String?
    var onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                if !projects.isEmpty {
                    Section("Projects") {
                        ForEach(projects, id: \.self) { p in
                            Button { onPick(p); dismiss() } label: {
                                HStack {
                                    Text(p).foregroundStyle(Palette.ink)
                                    Spacer()
                                    if p == current { Image(systemName: "checkmark").foregroundStyle(Palette.coral) }
                                }
                            }
                        }
                    }
                }
                Section("New project") {
                    HStack {
                        TextField("Name", text: $newName)
                        Button("Add") {
                            let n = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !n.isEmpty { onPick(n); dismiss() }
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Shoot into…")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .presentationDetents([.medium])
        .tint(Palette.coral)
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

/// Artificial-horizon line through center that rotates with the phone, green
/// when level. Matches the web behaviour.
private struct LevelOverlay: View {
    let angle: Double
    let isLevel: Bool
    var body: some View {
        Rectangle()
            .fill(isLevel ? Palette.mint : Color.white.opacity(0.9))
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
            .stroke(Palette.lemon, lineWidth: 1.5)
            .frame(width: 78, height: 78)
            .allowsHitTesting(false)
    }
}
