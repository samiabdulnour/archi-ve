import SwiftUI
import AVFoundation

/// Hosts the AVCaptureVideoPreviewLayer. Reports tap locations (in layer
/// space) back to the controller for tap-to-focus.
struct CameraPreview: UIViewRepresentable {
    let controller: CameraController
    /// Called with the tap location in the preview's coordinate space.
    var onTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = controller.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        controller.previewLayer = view.videoPreviewLayer

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        context.coordinator.onTap = onTap
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        context.coordinator.onTap = onTap
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        var onTap: ((CGPoint) -> Void)?
        @objc func handleTap(_ gr: UITapGestureRecognizer) {
            guard let view = gr.view else { return }
            onTap?(gr.location(in: view))
        }
    }

    /// A UIView whose backing layer is the preview layer (auto-resizes).
    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
