import SwiftUI

/// Fullscreen, black-background pinch-zoom viewer — the native counterpart of
/// the web "introspection" view. Pinch to zoom, drag to pan, double-tap to
/// toggle 1×/3×, single-tap (when not zoomed) to dismiss.
struct IntrospectionView: View {
    let image: UIImage?
    var onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            if let image {
                ZoomableImage(image: image, onSingleTapWhenUnzoomed: onClose)
                    .ignoresSafeArea()
            }
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.4), in: Circle())
            }
            .padding(.top, 8)
            .padding(.trailing, 16)
        }
        .statusBarHidden(true)
    }
}

/// UIScrollView-backed zoomable image: reliable pinch + pan + double-tap,
/// which SwiftUI gestures handle poorly together.
private struct ZoomableImage: UIViewRepresentable {
    let image: UIImage
    var onSingleTapWhenUnzoomed: () -> Void

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.delegate = context.coordinator
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 6
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.bouncesZoom = true
        scroll.backgroundColor = .black

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scroll.addSubview(imageView)
        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scroll

        let doubleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        scroll.addGestureRecognizer(singleTap)

        return scroll
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.layoutImage()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onSingleTap: onSingleTapWhenUnzoomed) }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?
        let onSingleTap: () -> Void
        private var didLayout = false

        init(onSingleTap: @escaping () -> Void) { self.onSingleTap = onSingleTap }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        func scrollViewDidZoom(_ scrollView: UIScrollView) { centerImage() }

        func layoutImage() {
            guard let scroll = scrollView, let iv = imageView, !didLayout,
                  scroll.bounds.width > 0 else { return }
            didLayout = true
            iv.frame = scroll.bounds
            scroll.contentSize = scroll.bounds.size
        }

        private func centerImage() {
            guard let scroll = scrollView, let iv = imageView else { return }
            let w = scroll.bounds.width, h = scroll.bounds.height
            let cw = iv.frame.width, ch = iv.frame.height
            let x = max(0, (w - cw) / 2)
            let y = max(0, (h - ch) / 2)
            iv.frame.origin = CGPoint(x: x, y: y)
        }

        @objc func handleDoubleTap(_ gr: UITapGestureRecognizer) {
            guard let scroll = scrollView else { return }
            if scroll.zoomScale > scroll.minimumZoomScale {
                scroll.setZoomScale(scroll.minimumZoomScale, animated: true)
            } else {
                let point = gr.location(in: imageView)
                let size = scroll.bounds.size
                let target = min(scroll.maximumZoomScale, 3)
                let rect = CGRect(
                    x: point.x - (size.width / target) / 2,
                    y: point.y - (size.height / target) / 2,
                    width: size.width / target,
                    height: size.height / target)
                scroll.zoom(to: rect, animated: true)
            }
        }

        @objc func handleSingleTap(_ gr: UITapGestureRecognizer) {
            guard let scroll = scrollView else { return }
            if scroll.zoomScale <= scroll.minimumZoomScale {
                onSingleTap()
            }
        }
    }
}
