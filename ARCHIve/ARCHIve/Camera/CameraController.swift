import AVFoundation
import UIKit
import Observation

/// Aspect ratios offered in the camera, expressed as the *portrait* ratio
/// (width / height). Capture crops the full sensor frame to this.
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

    /// Set by CameraPreview (main thread) so we can convert taps to device points.
    @ObservationIgnored weak var previewLayer: AVCaptureVideoPreviewLayer?

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

    /// Call on the main thread. `completion` is delivered on the main thread.
    func capture(completion: @escaping (Data?) -> Void) {
        guard configured else { completion(nil); return }
        captureHandler = completion
        let aspect = self.aspect
        let flash = self.flashMode

        sessionQueue.async { [weak self] in
            guard let self else { return }
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
        let cropped = CameraController.crop(image, to: aspect)
        let jpeg = cropped.jpegData(compressionQuality: 0.9)
        onMain { self.deliver(jpeg) }
    }
}
