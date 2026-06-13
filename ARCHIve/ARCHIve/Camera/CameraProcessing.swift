import CoreImage
import CoreImage.CIFilterBuiltins

/// Film-simulation-style colour looks — our own recipes in the spirit of Fuji
/// film sims and Ricoh GR effects: crisp, with cinematic colour balance (gentle
/// S-curves, split toning, controlled saturation). Applied live + baked in.
enum CameraLook: String, CaseIterable, Identifiable {
    case original  = "Original"
    case portra    = "Portra 400"
    case cinestill = "CineStill 800T"
    case ektar     = "Ektar 100"
    case trix      = "Tri-X 400"
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
        case .original:                                // untouched
            return ci

        case .portra:                                  // Portra 400: barely-warm, soft, creamy
            var x = temperature(ci, from: 6500, to: 6380)   // a touch warm
            x = controls(x, sat: 0.97, con: 0.99)
            x = vibrance(x, 0.05)
            // faintly lifted blacks, gentle highlight rolloff — the faded-film look
            return curve(x, [p(0,0.022), p(0.25,0.255), p(0.5,0.5), p(0.75,0.745), p(1,0.985)])

        case .cinestill:                               // CineStill 800T: cool tungsten, subtle teal shadows
            var x = temperature(ci, from: 6500, to: 6640)   // slightly cool
            x = controls(x, sat: 0.99, con: 1.02)
            x = splitTone(x)
            return curve(x, [p(0,0.03), p(0.25,0.238), p(0.5,0.5), p(0.78,0.788), p(1,0.985)])

        case .ektar:                                   // Ektar 100: clean, crisp, a little vivid
            var x = controls(ci, sat: 1.10, con: 1.03)
            x = vibrance(x, 0.10)
            return curve(x, [p(0,0.015), p(0.25,0.242), p(0.5,0.5), p(0.75,0.765), p(1,0.997)])

        case .trix:                                    // Tri-X 400: classic B&W, moderate contrast
            let m = CIFilter.photoEffectMono(); m.inputImage = ci
            let base = controls(m.outputImage ?? ci, sat: 1, con: 1.05)
            return curve(base, [p(0,0.02), p(0.25,0.222), p(0.5,0.5), p(0.75,0.78), p(1,0.99)])
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
        // out = c0 + c1·in + c2·in² + c3·in³  (per channel). Kept gentle — a hint
        // of teal in the shadows, a hint of warmth in the highlights.
        f.redCoefficients   = CIVector(x: -0.01, y: 1.03, z:  0.00, w: 0)  // softly warmer highlights
        f.greenCoefficients = CIVector(x:  0.00, y: 1.00, z:  0.00, w: 0)
        f.blueCoefficients  = CIVector(x:  0.025, y: 0.99, z: -0.02, w: 0) // faint teal shadows
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
        var out = f.outputImage ?? ci

        // Straightening verticals widens one end, which leaves the subject looking
        // short and squashed. Counter it with a vertical stretch (about the centre)
        // that grows with the tilt — keeps the object's proportions natural.
        let v = 1.0 + abs(strength) * 0.5
        let stretch = CGAffineTransform(translationX: 0, y: e.midY)
            .scaledBy(x: 1, y: v)
            .translatedBy(x: 0, y: -e.midY)
        out = out.transformed(by: stretch)

        // Crop back to the original frame, centred. The full sensor width fits with
        // no transparent edges (the widened end only adds width, never removes it),
        // so no zoom-in is needed — nothing leaves the frame. A 1% inset guards
        // against a sub-pixel hairline at the corners.
        let cw = e.width * 0.99, ch = e.height * 0.99
        return out.cropped(to: CGRect(x: e.midX - cw / 2, y: e.midY - ch / 2, width: cw, height: ch))
    }
}
