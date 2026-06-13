import AVFoundation
import UIKit
import Observation

/// Aspect ratios offered in the camera, expressed as the *portrait* ratio
/// (width / height). Capture crops the full sensor frame to this.
/// Reference = photos found out in the world; Project = a site-specific shoot
/// where a project is chosen once and a sequence is shot into it.
enum CaptureMode { case reference, project }

enum CaptureAspect: String, CaseIterable, Identifiable {
    case fourThree = "4:3"      // the full sensor
    case square = "1:1"
    case sixteenNine = "16:9"

    var id: String { rawValue }

    /// width / height in portrait. The preview is letterboxed to this and the
    /// capture is cropped to the same ratio, so what you frame is what you get.
    var portraitRatio: CGFloat {
        switch self {
        case .square: return 1
        case .fourThree: return 3.0 / 4.0
        case .sixteenNine: return 9.0 / 16.0
        }
    }
}

/// Owns the AVCaptureSession. All session mutation happens on `sessionQueue`;
/// observable UI state is always written back on the main thread so SwiftUI
/// stays consistent. Public methods are intended to be called from the main
/// thread (SwiftUI), and they hop to the session queue internally.
@Observable
final class CameraController: NSObject {
    let session = AVCaptureSession()

    // Observable UI state (written on main).
    var authorized = false
    var permissionDenied = false
    var isRunning = false
    var flashMode: AVCaptureDevice.FlashMode = .off
    var aspect: CaptureAspect = .fourThree
    var gridOn = true
    var levelOn = true
    var timerSeconds = 0           // 0 | 3 | 10
    var zoomFactor: CGFloat = 1.0
    var maxZoom: CGFloat = 1.0
    /// Architectural keystone: when on, the live preview is warped (and the
    /// saved photo corrected) to keep verticals straight as the phone tilts.
    var keystoneOn = false

    // Capture context (mirrors the web app's camera modes).
    var mode: CaptureMode = .reference
    var currentProject: String?            // the project shots land in (Project mode)
    var captureType: String = "building"   // Type segment: building | element | graphic
    var position: AVCaptureDevice.Position = .back

    /// Set by CameraPreview (main thread) so we can convert taps to device points.
    @ObservationIgnored weak var previewLayer: AVCaptureVideoPreviewLayer?

    @ObservationIgnored private var keystonePitch: Double = 0   // latest pitch (deg)
    @ObservationIgnored private var pendingKeystone: Double?    // pitch to correct at capture

    @ObservationIgnored private let photoOutput = AVCapturePhotoOutput()
    @ObservationIgnored private var videoDevice: AVCaptureDevice?
    @ObservationIgnored private let sessionQueue = DispatchQueue(label: "archive.camera.session")
    @ObservationIgnored private var configured = false
    @ObservationIgnored private var captureHandler: ((Data?) -> Void)?
    @ObservationIgnored private var pendingAspect: CaptureAspect = .fourThree

    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }

    // MARK: Permission + setup

    func requestAccessAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authorized = true
            configureIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                self?.onMain {
                    guard let self else { return }
                    self.authorized = granted
                    self.permissionDenied = !granted
                    if granted { self.configureIfNeeded() }
                }
            }
        default:
            permissionDenied = true
        }
    }

    private func configureIfNeeded() {
        guard !configured else { start(); return }
        configured = true
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)
            self.videoDevice = device

            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.maxPhotoQualityPrioritization = .quality
            }

            if let conn = self.photoOutput.connection(with: .video),
               conn.isVideoRotationAngleSupported(90) {
                conn.videoRotationAngle = 90
            }

            self.session.commitConfiguration()

            let maxZ = min(device.activeFormat.videoMaxZoomFactor, 8.0)
            self.session.startRunning()
            self.onMain {
                self.maxZoom = maxZ
                self.isRunning = true
            }
        }
    }

    func start() {
        guard configured else { return }
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            self.onMain { self.isRunning = true }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            self.onMain { self.isRunning = false }
        }
    }

    // MARK: Flip front/back

    func flipCamera() {
        let newPos: AVCaptureDevice.Position = (position == .back) ? .front : .back
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            for input in self.session.inputs {
                if let di = input as? AVCaptureDeviceInput, di.device.hasMediaType(.video) {
                    self.session.removeInput(di)
                }
            }
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
               let input = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoDevice = device
            }
            if let conn = self.photoOutput.connection(with: .video),
               conn.isVideoRotationAngleSupported(90) {
                conn.videoRotationAngle = 90
            }
            self.session.commitConfiguration()
            let maxZ = min(self.videoDevice?.activeFormat.videoMaxZoomFactor ?? 1, 8.0)
            self.onMain {
                self.position = newPos
                self.maxZoom = maxZ
                self.zoomFactor = 1
            }
        }
    }

    // MARK: Tap to focus + exposure

    /// `layerPoint` is a point in the preview layer's coordinate space.
    /// Call on the main thread (uses the preview layer).
    func focusAndExpose(atLayerPoint layerPoint: CGPoint) {
        guard let devicePoint = previewLayer?.captureDevicePointConverted(fromLayerPoint: layerPoint) else { return }
        sessionQueue.async { [weak self] in
            guard let self, let device = self.videoDevice else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = device.isFocusModeSupported(.autoFocus) ? .autoFocus : .continuousAutoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = device.isExposureModeSupported(.autoExpose) ? .autoExpose : .continuousAutoExposure
                }
                device.unlockForConfiguration()
            } catch { }
        }
    }

    /// Manual exposure compensation in EV (e.g. dragging the sun up/down after a
    /// tap-to-focus), clamped to the device's supported range.
    func setExposureBias(_ ev: Float) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.videoDevice else { return }
            do {
                try device.lockForConfiguration()
                let v = max(device.minExposureTargetBias, min(device.maxExposureTargetBias, ev))
                device.setExposureTargetBias(v, completionHandler: nil)
                device.unlockForConfiguration()
            } catch { }
        }
    }

    // MARK: Zoom

    func setZoom(_ factor: CGFloat) {
        let clamped = max(1.0, min(factor, maxZoom))
        zoomFactor = clamped
        sessionQueue.async { [weak self] in
            guard let self, let device = self.videoDevice else { return }
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clamped
                device.unlockForConfiguration()
            } catch { }
        }
    }

    // MARK: Capture

    // MARK: Keystone (architectural vertical correction)

    /// Toggle the live keystone preview.
    func setKeystoneEnabled(_ on: Bool) { keystoneOn = on; applyPreviewKeystone() }

    /// Feed the latest device pitch (degrees); warps the preview when enabled.
    func setKeystonePitch(_ deg: Double) {
        keystonePitch = deg
        if keystoneOn { applyPreviewKeystone() }
    }

    private func applyPreviewKeystone() {
        guard let layer = previewLayer else { return }
        CATransaction.begin(); CATransaction.setDisableActions(true)
        if keystoneOn {
            let clamped = max(-22, min(22, keystonePitch))
            let angle = clamped * .pi / 180 * 0.7          // counter-rotate the preview plane
            var t = CATransform3DIdentity
            t.m34 = -1.0 / 1500                            // perspective
            t = CATransform3DRotate(t, CGFloat(angle), 1, 0, 0)
            let s = 1.0 / cos(angle) + 0.12                // scale up to refill the frame
            t = CATransform3DScale(t, CGFloat(s), CGFloat(s), 1)
            layer.transform = t
        } else {
            layer.transform = CATransform3DIdentity
        }
        CATransaction.commit()
    }

    /// Redraw to `.up` orientation so Core Image works in display space.
    private static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let r = UIGraphicsImageRenderer(size: image.size)
        return r.image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
    }

    /// Straighten converging verticals by widening the compressed edge, then
    /// crop back to the original frame. Approximate (pitch-driven), tunable.
    static func correctKeystone(_ image: UIImage, pitchDegrees: Double) -> UIImage {
        guard abs(pitchDegrees) > 1 else { return image }
        let upright = normalized(image)
        guard let cg = upright.cgImage else { return image }
        let ci = CIImage(cgImage: cg)
        let W = ci.extent.width, H = ci.extent.height
        let k = min(0.32, abs(tan(pitchDegrees * .pi / 180)) * 0.5) * W
        let widenTop = pitchDegrees < 0   // tilted up → verticals converge upward
        let f = CIFilter(name: "CIPerspectiveTransform")!
        f.setValue(ci, forKey: kCIInputImageKey)
        if widenTop {
            f.setValue(CIVector(x: -k, y: H), forKey: "inputTopLeft")
            f.setValue(CIVector(x: W + k, y: H), forKey: "inputTopRight")
            f.setValue(CIVector(x: 0, y: 0), forKey: "inputBottomLeft")
            f.setValue(CIVector(x: W, y: 0), forKey: "inputBottomRight")
        } else {
            f.setValue(CIVector(x: 0, y: H), forKey: "inputTopLeft")
            f.setValue(CIVector(x: W, y: H), forKey: "inputTopRight")
            f.setValue(CIVector(x: -k, y: 0), forKey: "inputBottomLeft")
            f.setValue(CIVector(x: W + k, y: 0), forKey: "inputBottomRight")
        }
        guard let out = f.outputImage else { return image }
        let ctx = CIContext()
        guard let cgOut = ctx.createCGImage(out, from: CGRect(x: 0, y: 0, width: W, height: H)) else { return image }
        return UIImage(cgImage: cgOut, scale: upright.scale, orientation: .up)
    }

    /// Call on the main thread. `completion` is delivered on the main thread.
    func capture(completion: @escaping (Data?) -> Void) {
        guard configured else { completion(nil); return }
        captureHandler = completion
        let aspect = self.aspect
        let flash = self.flashMode
        let keystone = keystoneOn ? keystonePitch : nil

        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.pendingKeystone = keystone
            // No camera (e.g. the Simulator) → safe no-op instead of throwing.
            guard self.session.isRunning, self.photoOutput.connection(with: .video) != nil else {
                self.onMain { self.deliver(nil) }
                return
            }
            let settings: AVCapturePhotoSettings
            if self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            } else {
                settings = AVCapturePhotoSettings()
            }
            if self.photoOutput.supportedFlashModes.contains(flash) {
                settings.flashMode = flash
            }
            settings.photoQualityPrioritization = .quality
            self.pendingAspect = aspect
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func deliver(_ data: Data?) {
        let handler = captureHandler
        captureHandler = nil
        handler?(data)
    }

    /// Center-crop a UIImage to the given portrait aspect ratio.
    static func crop(_ image: UIImage, to aspect: CaptureAspect) -> UIImage {
        let ratio = aspect.portraitRatio
        guard let cg = image.cgImage else { return image }
        let w = CGFloat(cg.width), h = CGFloat(cg.height)
        // Match orientation: if the pixel buffer is landscape, invert ratio.
        let targetRatio = (w > h) ? (1.0 / ratio) : ratio
        var cw = w, ch = w / targetRatio
        if ch > h { ch = h; cw = h * targetRatio }
        cw = min(w, cw); ch = min(h, ch)
        let rect = CGRect(x: (w - cw) / 2, y: (h - ch) / 2, width: cw, height: ch).integral
        guard let cropped = cg.cropping(to: rect) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        let aspect = pendingAspect   // set on session queue before capture; safe here
        guard error == nil, let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            onMain { self.deliver(nil) }
            return
        }
        let corrected = pendingKeystone.map { CameraController.correctKeystone(image, pitchDegrees: $0) } ?? image
        let cropped = CameraController.crop(corrected, to: aspect)
        let jpeg = cropped.jpegData(compressionQuality: 0.9)
        onMain { self.deliver(jpeg) }
    }
}
