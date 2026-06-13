import SwiftUI
import SwiftData
import AVFoundation

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Photo.createdAt, order: .reverse) private var allPhotos: [Photo]

    @State private var camera = CameraController()
    @State private var motion = MotionLevel()

    @State private var countdown: Int?
    @State private var shutterFlash = false
    @State private var baseZoom: CGFloat = 1.0
    @State private var savedCount = 0
    @State private var tagTarget: Photo?

    @State private var tagMode: TagMode = .full
    @State private var reuseTags: HumanTags?

    // Lite-mode "Saved" toast
    @State private var savedToast: Photo?
    @State private var savedToastType = "building"
    @State private var toastHideItem: DispatchWorkItem?
    @State private var showSettings = false
    @State private var showProjectPicker = false
    @State private var tool: CameraTool = .none

    enum CameraTool { case none, looks, keystone }

    enum TagMode { case lite, full }

    private var latest: Photo? { allPhotos.first }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                if camera.authorized {
                    previewStack(in: geo)
                } else if camera.permissionDenied {
                    permissionView
                } else {
                    ProgressView().tint(.white)
                }
            }
            .overlay(alignment: .top) { savedToastView }
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
        .fullScreenCover(item: $tagTarget, onDismiss: { camera.start() }) { photo in
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
        return Set(out).union(Settings.customProjects).sorted()
    }

    // MARK: Preview + overlays

    @ViewBuilder
    private func previewStack(in geo: GeometryProxy) -> some View {
        // Native-style layout: the live feed stays full-bleed, but the *crop
        // window* sits in the region above the controls (not centred on the
        // whole screen), so its bottom edge never collides with the shutter.
        // The zoom bar rides the bottom edge of that window and moves with the
        // chosen ratio, exactly like the system Camera.
        // 16:9 is the full-bleed mode (like native): the feed fills the screen
        // edge-to-edge and the controls float over it. 4:3 / 1:1 use a framed
        // crop window with the area outside dimmed.
        let isFullBleed = camera.aspect == .sixteenNine
        let ratio = camera.aspect.portraitRatio          // width / height (<1)
        let topSafe = geo.safeAreaInsets.top
        let botSafe = geo.safeAreaInsets.bottom
        let fullW = geo.size.width
        let fullH = geo.size.height + topSafe + botSafe   // physical screen height
        let topReserve = topSafe + 50                     // top pill row
        let bottomReserve = botSafe + 172                 // shutter + mode row
        let availH = max(0, fullH - topReserve - bottomReserve)
        let frameH = min(availH, fullW / ratio)
        let frameW = min(fullW, frameH * ratio)
        let frameCx = fullW / 2
        let frameTop = topReserve + (availH - frameH) / 2
        let frameCy = frameTop + frameH / 2
        let frameBottom = frameTop + frameH

        ZStack {
            MetalCameraPreview(controller: camera)
                .ignoresSafeArea()

            if isFullBleed {
                // No crop window: full-screen grid + centred level, controls
                // float over the feed (zoom lives in the bottom inset below).
                if camera.gridOn { GridOverlay().ignoresSafeArea() }
                if camera.levelOn && !motion.isFlat {
                    LevelOverlay(angle: motion.angle, isLevel: motion.isLevel)
                }
            } else {
                // Dim everything outside the crop window, punching a clear hole.
                ZStack {
                    Color.black.opacity(0.4)
                    Rectangle()
                        .frame(width: frameW, height: frameH)
                        .position(x: frameCx, y: frameCy)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .allowsHitTesting(false)

                Rectangle().stroke(.white.opacity(0.5), lineWidth: 1)
                    .frame(width: frameW, height: frameH)
                    .position(x: frameCx, y: frameCy)
                    .allowsHitTesting(false)

                if camera.gridOn {
                    GridOverlay()
                        .frame(width: frameW, height: frameH)
                        .position(x: frameCx, y: frameCy)
                }
                if camera.levelOn && !motion.isFlat {
                    LevelOverlay(angle: motion.angle, isLevel: motion.isLevel)
                        .position(x: frameCx, y: frameCy)
                }
            }

            // Tap-to-focus + drag-to-expose, in its own full-screen space so the
            // reticle lands exactly under the finger. Hosts the pinch-zoom too.
            // Focus only registers inside the crop frame (whole screen in 16:9).
            FocusExposureView(
                camera: camera,
                baseZoom: $baseZoom,
                focusRegion: isFullBleed
                    ? CGRect(x: 0, y: 0, width: fullW, height: fullH)
                    : CGRect(x: frameCx - frameW / 2, y: frameCy - frameH / 2, width: frameW, height: frameH)
            )

            // Framed-mode zoom bar rides the crop window's bottom edge — kept
            // ABOVE the focus overlay so tapping a factor zooms (not focuses).
            if !isFullBleed && camera.maxZoom > 1.5 {
                zoomBar.position(x: frameCx, y: frameBottom - 26)
            }

            if shutterFlash { Color.black.ignoresSafeArea() }
            if let c = countdown {
                Text("\(c)").font(.system(size: 120, weight: .thin, design: .rounded))
                    .foregroundStyle(.white).shadow(radius: 8)
                    .position(x: frameCx, y: isFullBleed ? fullH / 2 : frameCy)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(alignment: .top) {
                if camera.mode == .project { projectPill } else { typeSegment }
                Spacer()
                actionPill
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 16) {
                // In full-bleed (16:9) the zoom bar floats above the shutter;
                // in framed modes it rides the crop window's bottom edge instead.
                if isFullBleed && camera.maxZoom > 1.5 { zoomBar }
                toolTray
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
            .padding(.top, 14)
            .padding(.bottom, 6)
            // Scrim so the floating controls stay legible over a bright feed.
            .background(
                LinearGradient(colors: [.clear, .black.opacity(0.5)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            )
        }
    }

    // MARK: Top — Type segment + action pill

    // Both top pills share the same height (36pt buttons + 4pt padding) and
    // icon weight so left and right read as a matched pair, native-style.
    private var typeSegment: some View {
        HStack(spacing: 8) {
            ForEach(TagVocab.types) { t in
                let active = camera.captureType == t.id
                Button { camera.captureType = t.id } label: {
                    Image(systemName: t.symbol)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(active ? .black : .white.opacity(0.85))
                        .rotatingIcon(motion.iconAngle)
                        .frame(width: 32, height: 32)
                        .background(active ? Circle().fill(.white) : Circle().fill(.clear))
                }
                .accessibilityLabel(t.label)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
    }

    private var actionPill: some View {
        HStack(spacing: 8) {
            pillButton(tagMode == .full ? "tag.fill" : "tag", active: tagMode == .full) {
                tagMode = tagMode == .full ? .lite : .full
            }
            pillButton("arrow.2.squarepath", active: reuseTags != nil) {
                reuseTags = (reuseTags == nil) ? latest?.humanTags : nil
            }
            pillButton("camera.filters", active: tool == .looks || camera.colorLook != .original) {
                tool = (tool == .looks) ? .none : .looks
            }
            pillButton("skew", active: tool == .keystone || camera.keystoneStrength != 0) {
                if tool == .keystone {
                    tool = .none
                    camera.setKeystoneStrength(0)   // tapping again cancels the tilt
                } else {
                    tool = .keystone
                }
            }
            pillButton("circle.grid.3x3.fill", active: false) { showSettings = true }
        }
        .padding(.horizontal, 10).padding(.vertical, 3)
        .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
    }

    private func pillButton(_ symbol: String, active: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(active ? Palette.coral : .white)
                .rotatingIcon(motion.iconAngle)
                .frame(width: 32, height: 32)
        }
    }

    /// Project mode replaces the Type segment with a Pick-project pill
    /// (matches the old app); tap to choose / change the project.
    private var projectPill: some View {
        Button { showProjectPicker = true } label: {
            HStack(spacing: 7) {
                Circle().fill(Palette.lemon).frame(width: 7, height: 7)
                Text(camera.currentProject ?? "Pick project")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .frame(height: 35)
            .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
        }
    }

    // MARK: Bottom — shutter, mode toggle, thumbnail, flip

    private var shutterButton: some View {
        // Native iOS Camera shutter: white ring + a gap + white centre, with a
        // springy press-shrink for tactility.
        Button(action: onShutter) {
            ZStack {
                Circle().stroke(.white, lineWidth: 2.5).frame(width: 72, height: 72)
                Circle().fill(.white).frame(width: 63, height: 63)
            }
        }
        .buttonStyle(ShutterButtonStyle())
        .disabled(countdown != nil)
    }

    private var modeToggle: some View {
        HStack(spacing: 18) {
            modeSegment("REFERENCE", on: camera.mode == .reference, tint: Palette.mint) {
                camera.mode = .reference
            }
            modeSegment("PROJECT", on: camera.mode == .project, tint: Palette.lemon) {
                camera.mode = .project
            }
        }
    }

    /// Native VIDEO/PHOTO-style label: uppercase, tracked, active highlighted.
    private func modeSegment(_ title: String, on: Bool, tint: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(on ? tint : .white.opacity(0.6))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(on ? Capsule().fill(.white.opacity(0.14)) : Capsule().fill(.clear))
        }
    }

    private var thumbnailButton: some View {
        Button { dismiss() } label: {
            Group {
                if let latest {
                    PhotoThumbnail(photo: latest).frame(width: 46, height: 46)
                } else {
                    Color.white.opacity(0.12).frame(width: 46, height: 46)
                        .overlay(Image(systemName: "photo").foregroundStyle(.white.opacity(0.7)))
                }
            }
            .rotatingIcon(motion.iconAngle)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.5), lineWidth: 1))
        }
    }

    private var flipButton: some View {
        Button { camera.flipCamera() } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .rotatingIcon(motion.iconAngle)
                .frame(width: 46, height: 46)
                .background(Circle().fill(.white.opacity(0.16)))
        }
    }

    private var zoomBar: some View {
        // Native style: the active factor is always centred with a small filled
        // circle around it; the other factors are plain numbers flanking it.
        // Everything that changes between active/inactive is animatable — the
        // circle fades (opacity), the size scales (scaleEffect), and every slot
        // is a fixed size — so switching factors is smooth, not flickery.
        let stops = zoomStops
        let activeIndex = stops.firstIndex { abs(camera.zoomFactor - $0) < 0.1 } ?? 0
        let slot: CGFloat = 48
        return ZStack {
            ForEach(Array(stops.enumerated()), id: \.element) { i, z in
                let active = i == activeIndex
                let num = z == 1 ? "1" : String(format: "%.0f", z)
                Button { camera.setZoom(z); baseZoom = z } label: {
                    ZStack {
                        Circle().fill(.black.opacity(0.5))
                            .frame(width: 40, height: 40)
                            .opacity(active ? 1 : 0)
                        // Number stays put; the "×" just fades in for the active
                        // factor (its width is always reserved), so nothing
                        // jumps mid-animation.
                        HStack(spacing: 0) {
                            Text(num)
                            Text("×").opacity(active ? 1 : 0).frame(width: 9)
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(active ? Palette.lemon : .white)
                        .shadow(color: .black.opacity(active ? 0 : 0.45), radius: 2)
                    }
                    .rotatingIcon(motion.iconAngle)
                    .frame(width: 44, height: 44)
                    .scaleEffect(active ? 1 : 0.88)
                    .contentShape(Circle())
                }
                .offset(x: CGFloat(i - activeIndex) * slot)
            }
        }
        .frame(height: 48)
        .animation(.smooth(duration: 0.3), value: activeIndex)
    }

    private var zoomStops: [CGFloat] {
        var stops: [CGFloat] = [1]
        if camera.maxZoom >= 2 { stops.append(2) }
        if camera.maxZoom >= 4 { stops.append(4) }
        return stops
    }

    /// Lite-mode confirmation toast: "Saved as <type> · Tag later in gallery"
    /// with a one-tap "Tag now". Styled in the warm/mint palette of the old app.
    @ViewBuilder private var savedToastView: some View {
        if let photo = savedToast {
            let type = TagVocab.types.first { $0.id == savedToastType }
            HStack(spacing: 12) {
                Image(systemName: type?.symbol ?? "photo")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(hex: "16140F"))
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 11).fill(.white))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Saved as \(savedToastType)")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "16140F"))
                    Text("Tag later in gallery")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "16140F").opacity(0.6))
                }
                Spacer(minLength: 8)
                Button {
                    toastHideItem?.cancel()
                    withAnimation(.easeInOut(duration: 0.2)) { savedToast = nil }
                    camera.stop()
                    tagTarget = photo
                } label: {
                    Text("Tag now")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Color(hex: "16140F")))
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 18).fill(Palette.mint))
            .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
            .padding(.horizontal, 12)
            .padding(.top, 58)   // clear the top control row
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    /// One effects panel above the shutter — looks OR keystone, never both, so
    /// the core controls (zoom, shutter) stay uncrowded.
    @ViewBuilder private var toolTray: some View {
        switch tool {
        case .looks:    LooksWheel(camera: camera)
        case .keystone: keystoneSlider
        case .none:     EmptyView()
        }
    }

    /// Strength control for the keystone correction (shown only when on).
    private var keystoneSlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "skew").font(.system(size: 14)).foregroundStyle(.white.opacity(0.85))
            Slider(value: Binding(
                get: { camera.keystoneStrength },
                set: { camera.setKeystoneStrength($0) }
            ), in: -1...1)
            .tint(Palette.coral)
        }
        .overlay(alignment: .center) {
            // a subtle centre tick (0 = no correction)
            Rectangle().fill(.white.opacity(0.3)).frame(width: 1, height: 12)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 340)
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
            } else {
                // Lite mode: no tag sheet — confirm with a toast offering a
                // one-tap "Tag now" (like the old app).
                showSavedToast(photo)
            }
        }
    }

    private func showSavedToast(_ photo: Photo) {
        savedToastType = camera.captureType
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { savedToast = photo }
        toastHideItem?.cancel()
        let item = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.3)) { savedToast = nil }
        }
        toastHideItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: item)
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
    @State private var showAppSettings = false

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(.white.opacity(0.3)).frame(width: 38, height: 5).padding(.vertical, 12)
            LazyVGrid(columns: cols, spacing: 22) {
                item("FLASH", flashIcon, active: camera.flashMode != .off) { cycleFlash() }
                item("TIMER", "timer", active: camera.timerSeconds != 0,
                     badge: camera.timerSeconds == 0 ? nil : "\(camera.timerSeconds)") { cycleTimer() }
                item("ASPECT", "aspectratio", active: camera.aspect != .fourThree, badge: camera.aspect.rawValue) { cycleAspect() }
                item("GRID", "grid", active: camera.gridOn) { camera.gridOn.toggle() }
                item("LEVEL", "level", active: camera.levelOn) { camera.levelOn.toggle() }
                item("SETTINGS", "gearshape", active: false) { showAppSettings = true }
            }
            .padding(.horizontal, 22)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.colorScheme, .dark)
        .sheet(isPresented: $showAppSettings) { SettingsView() }
        .presentationDetents([.height(246)])
        // Liquid-glass: a forced-dark frosted material so the blurred feed
        // shows through, like the native Camera control sheet.
        .presentationBackground {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Color.black.opacity(0.18)
            }
            .environment(\.colorScheme, .dark)
        }
    }

    private var timerSeconds: Int { camera.timerSeconds }
    private var flashIcon: String {
        switch camera.flashMode {
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.a.fill"
        default: return "bolt.slash.fill"
        }
    }

    private func cycleFlash() {
        switch camera.flashMode {
        case .off: camera.flashMode = .auto
        case .auto: camera.flashMode = .on
        default: camera.flashMode = .off
        }
    }
    private func cycleTimer() {
        camera.timerSeconds = camera.timerSeconds == 0 ? 3 : (camera.timerSeconds == 3 ? 10 : 0)
    }
    private func cycleAspect() {
        let all = CaptureAspect.allCases
        if let i = all.firstIndex(of: camera.aspect) { camera.aspect = all[(i + 1) % all.count] }
    }

    @ViewBuilder
    private func item(_ label: String, _ symbol: String, active: Bool,
                      badge: String? = nil, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(active ? AnyShapeStyle(Palette.lemon) : AnyShapeStyle(.ultraThinMaterial))
                        .overlay(Circle().strokeBorder(active ? .clear : .white.opacity(0.25), lineWidth: 1))
                        .frame(width: 60, height: 60)
                    if let badge {
                        Text(badge)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(active ? .black : .white)
                    } else {
                        Image(systemName: symbol)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(active ? .black : .white)
                    }
                }
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
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

/// Rotates a control glyph to stay upright as the phone turns (native Camera
/// behaviour) while the UI itself stays locked in portrait.
private struct RotatingIcon: ViewModifier {
    let angle: Double
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .animation(.easeInOut(duration: 0.28), value: angle)
    }
}

private extension View {
    func rotatingIcon(_ angle: Double) -> some View { modifier(RotatingIcon(angle: angle)) }
}

/// Springy press-shrink for the shutter, like the native Camera.
private struct ShutterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

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

/// Tap-to-focus + drag-to-expose, native-Camera style. Lives in its own
/// full-screen GeometryReader so the tap location and the reticle's `.position`
/// share one coordinate space (the reticle lands exactly under the finger), and
/// that space matches the full-bleed preview layer (so focus is accurate too).
/// Also hosts the pinch-to-zoom so all camera-feed gestures live together.
private struct FocusExposureView: View {
    let camera: CameraController
    @Binding var baseZoom: CGFloat
    /// Taps that start outside this rect don't focus (the dimmed area in 4:3 /
    /// 1:1). Pinch-to-zoom still works anywhere.
    var focusRegion: CGRect

    @State private var point: CGPoint?
    @State private var bias: Float = 0
    @State private var visible = false
    @State private var gestureStarted = false
    @State private var ignoring = false
    @State private var hideItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            Color.clear.contentShape(Rectangle())
            if visible, let point {
                FocusReticle(bias: bias)
                    .position(point)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .gesture(focusDrag)
        .simultaneousGesture(zoomMagnify)
    }

    private var focusDrag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !gestureStarted {
                    gestureStarted = true
                    // Ignore the whole gesture if it began outside the frame.
                    ignoring = !focusRegion.contains(value.startLocation)
                    guard !ignoring else { return }
                    // First touch inside the frame = tap-to-focus at that point.
                    point = value.startLocation
                    bias = 0
                    camera.focusAndExpose(atLayerPoint: value.startLocation)
                    camera.setExposureBias(0)
                    reveal()
                }
                guard !ignoring else { return }
                // Drag up = brighter, down = darker (≈90pt per EV).
                let dy = value.location.y - value.startLocation.y
                bias = Float(max(-2, min(2, Double(-dy) / 90)))
                camera.setExposureBias(bias)
                reveal()
            }
            .onEnded { _ in
                gestureStarted = false
                ignoring = false
                scheduleHide()
            }
    }

    private var zoomMagnify: some Gesture {
        MagnifyGesture()
            .onChanged { value in camera.setZoom(baseZoom * value.magnification) }
            .onEnded { _ in baseZoom = camera.zoomFactor }
    }

    private func reveal() {
        hideItem?.cancel()
        if !visible { withAnimation(.easeOut(duration: 0.15)) { visible = true } }
    }

    private func scheduleHide() {
        hideItem?.cancel()
        let item = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.4)) { visible = false }
        }
        hideItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: item)
    }
}

/// The yellow focus square with a sun that slides up/down as exposure changes —
/// the native tap-to-focus reticle.
private struct FocusReticle: View {
    let bias: Float
    private let box: CGFloat = 76

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Palette.lemon, lineWidth: 1)
                .frame(width: box, height: box)
            // Exposure sun on the right edge, sliding with the bias.
            Image(systemName: "sun.max.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.lemon)
                .shadow(color: .black.opacity(0.4), radius: 1)
                .offset(x: box / 2 + 16, y: CGFloat(-bias) * 22)
        }
        .allowsHitTesting(false)
    }
}
