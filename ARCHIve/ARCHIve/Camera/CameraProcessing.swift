import CoreImage
import CoreImage.CIFilterBuiltins

/// Film-simulation-style colour looks, in the spirit of an X100V — our own
/// recipes, applied live and baked into the capture.
enum CameraLook: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case vivid    = "Vivid"
    case chrome   = "Chrome"
    case soft     = "Soft"
    case warm     = "Warm"
    case mono     = "Mono"
    case noir     = "Noir"
    var id: String { rawValue }
}

/// The Core Image chain shared by the live preview and the saved photo, so what
/// you see is what you get: keystone (vertical correction) then a colour look.
enum CameraProcessing {
    static func apply(to input: CIImage, keystone: Double, look: CameraLook) -> CIImage {
        var img = input
        if abs(keystone) > 0.01 { img = keystoned(img, strength: keystone) }
        img = colored(img, look: look)
        return img
    }

    /// Straighten converging verticals (strength −1…1), then zoom-crop to refill.
    static func keystoned(_ ci: CIImage, strength: Double) -> CIImage {
        let e = ci.extent
        guard e.width > 0, e.height > 0 else { return ci }
        let k = min(0.6, abs(strength) * 0.6) * e.width
        let f = CIFilter.perspectiveTransform()
        f.inputImage = ci
        if strength > 0 {            // correct upward-converging verticals
            f.topLeft = CGPoint(x: e.minX - k, y: e.maxY)
            f.topRight = CGPoint(x: e.maxX + k, y: e.maxY)
            f.bottomLeft = CGPoint(x: e.minX, y: e.minY)
            f.bottomRight = CGPoint(x: e.maxX, y: e.minY)
        } else {
            f.topLeft = CGPoint(x: e.minX, y: e.maxY)
            f.topRight = CGPoint(x: e.maxX, y: e.maxY)
            f.bottomLeft = CGPoint(x: e.minX - k, y: e.minY)
            f.bottomRight = CGPoint(x: e.maxX + k, y: e.minY)
        }
        let out = f.outputImage ?? ci
        let angle = abs(strength) * 0.7
        let s = 1.0 / cos(angle) + 0.12
        let cw = e.width / s, ch = e.height / s
        return out.cropped(to: CGRect(x: e.midX - cw / 2, y: e.midY - ch / 2, width: cw, height: ch))
    }

    static func colored(_ ci: CIImage, look: CameraLook) -> CIImage {
        switch look {
        case .standard:
            return ci
        case .vivid:
            let c = CIFilter.colorControls(); c.inputImage = ci
            c.saturation = 1.4; c.contrast = 1.08
            return c.outputImage ?? ci
        case .chrome:
            let c = CIFilter.colorControls(); c.inputImage = ci
            c.saturation = 0.8; c.contrast = 1.05
            return c.outputImage ?? ci
        case .soft:
            let c = CIFilter.colorControls(); c.inputImage = ci
            c.saturation = 0.95; c.contrast = 0.9; c.brightness = 0.02
            return c.outputImage ?? ci
        case .warm:
            let t = CIFilter.temperatureAndTint(); t.inputImage = ci
            t.neutral = CIVector(x: 5200, y: 0)
            t.targetNeutral = CIVector(x: 6500, y: 0)
            return t.outputImage ?? ci
        case .mono:
            let f = CIFilter.photoEffectMono(); f.inputImage = ci
            return f.outputImage ?? ci
        case .noir:
            let f = CIFilter.photoEffectNoir(); f.inputImage = ci
            return f.outputImage ?? ci
        }
    }
}
