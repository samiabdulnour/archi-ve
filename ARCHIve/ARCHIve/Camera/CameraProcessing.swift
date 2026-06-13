import CoreImage
import CoreImage.CIFilterBuiltins

/// Film-simulation-style colour looks — our own recipes in the spirit of Fuji
/// film sims and Ricoh GR effects: crisp, with cinematic colour balance (gentle
/// S-curves, split toning, controlled saturation). Applied live + baked in.
enum CameraLook: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case vivid    = "Vivid"
    case chrome   = "Chrome"
    case cinema   = "Cinema"
    case bleach   = "Bleach"
    case mono     = "Mono"
    case noir     = "Noir"
    var id: String { rawValue }
}

enum CameraProcessing {
    static func apply(to input: CIImage, keystone: Double, look: CameraLook) -> CIImage {
        var img = input
        if abs(keystone) > 0.01 { img = keystoned(img, strength: keystone) }
        img = colored(img, look: look)
        return img
    }

    // MARK: Colour looks

    static func colored(_ ci: CIImage, look: CameraLook) -> CIImage {
        switch look {
        case .standard:
            return vibrance(controls(ci, sat: 1.04, con: 1.03), 0.1)

        case .vivid:                                   // Velvia-ish: punchy but controlled
            var x = controls(ci, sat: 1.22, con: 1.10)
            x = vibrance(x, 0.25)
            return curve(x, [p(0,0), p(0.25,0.21), p(0.5,0.5), p(0.75,0.80), p(1,1)])

        case .chrome:                                  // Classic Chrome / GR positive film: muted, matte
            var x = controls(ci, sat: 0.78, con: 1.05)
            x = temperature(x, from: 6500, to: 6250)   // a touch warm
            // lifted blacks + rolled highlights = soft, documentary feel
            return curve(x, [p(0,0.06), p(0.25,0.28), p(0.5,0.5), p(0.75,0.73), p(1,0.96)])

        case .cinema:                                  // teal shadows, warm highlights
            var x = controls(ci, sat: 0.96, con: 1.06)
            x = splitTone(x)
            return curve(x, [p(0,0.03), p(0.25,0.22), p(0.5,0.5), p(0.78,0.82), p(1,0.99)])

        case .bleach:                                  // bleach bypass: silvery, high-contrast
            var x = controls(ci, sat: 0.42, con: 1.28)
            x = highlightShadow(x, highlight: 0.25, shadow: -0.25)
            return curve(x, [p(0,0.02), p(0.25,0.18), p(0.5,0.52), p(0.75,0.86), p(1,1)])

        case .mono:                                    // Acros-ish: rich, crisp B&W
            let m = CIFilter.photoEffectMono(); m.inputImage = ci
            let base = m.outputImage ?? ci
            return curve(controls(base, sat: 1, con: 1.04), [p(0,0.02), p(0.25,0.2), p(0.5,0.5), p(0.75,0.8), p(1,0.99)])

        case .noir:                                    // dramatic high-contrast B&W
            let f = CIFilter.photoEffectNoir(); f.inputImage = ci
            return f.outputImage ?? ci
        }
    }

    // MARK: Building blocks

    private static func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    private static func controls(_ ci: CIImage, sat: Float, con: Float, bri: Float = 0) -> CIImage {
        let f = CIFilter.colorControls(); f.inputImage = ci
        f.saturation = sat; f.contrast = con; f.brightness = bri
        return f.outputImage ?? ci
    }

    private static func vibrance(_ ci: CIImage, _ amount: Float) -> CIImage {
        let f = CIFilter.vibrance(); f.inputImage = ci; f.amount = amount
        return f.outputImage ?? ci
    }

    private static func curve(_ ci: CIImage, _ pts: [CGPoint]) -> CIImage {
        let f = CIFilter.toneCurve(); f.inputImage = ci
        f.point0 = pts[0]; f.point1 = pts[1]; f.point2 = pts[2]; f.point3 = pts[3]; f.point4 = pts[4]
        return f.outputImage ?? ci
    }

    private static func temperature(_ ci: CIImage, from: CGFloat, to: CGFloat) -> CIImage {
        let f = CIFilter.temperatureAndTint(); f.inputImage = ci
        f.neutral = CIVector(x: from, y: 0); f.targetNeutral = CIVector(x: to, y: 0)
        return f.outputImage ?? ci
    }

    private static func highlightShadow(_ ci: CIImage, highlight: Float, shadow: Float) -> CIImage {
        let f = CIFilter.highlightShadowAdjust(); f.inputImage = ci
        f.highlightAmount = highlight; f.shadowAmount = shadow; f.radius = 8
        return f.outputImage ?? ci
    }

    /// Teal in the shadows, warmth in the highlights — the cinematic balance,
    /// via gentle per-channel polynomials.
    private static func splitTone(_ ci: CIImage) -> CIImage {
        let f = CIFilter.colorPolynomial(); f.inputImage = ci
        // out = c0 + c1·in + c2·in² + c3·in³  (per channel)
        f.redCoefficients   = CIVector(x: -0.02, y: 1.06, z: 0.00, w: 0)   // warmer highlights
        f.greenCoefficients = CIVector(x:  0.00, y: 1.00, z: 0.00, w: 0)
        f.blueCoefficients  = CIVector(x:  0.05, y: 0.98, z: -0.04, w: 0)  // teal shadows, cooler-down highs
        return f.outputImage ?? ci
    }

    // MARK: Keystone (unchanged)

    static func keystoned(_ ci: CIImage, strength: Double) -> CIImage {
        let e = ci.extent
        guard e.width > 0, e.height > 0 else { return ci }
        let k = min(0.6, abs(strength) * 0.6) * e.width
        let f = CIFilter.perspectiveTransform()
        f.inputImage = ci
        if strength > 0 {
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
}
