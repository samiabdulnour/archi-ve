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

        case .portra:                                  // warm, soft, low-contrast, creamy
            var x = temperature(ci, from: 6500, to: 6150)   // warm
            x = controls(x, sat: 0.94, con: 0.95)
            x = vibrance(x, 0.08)
            return curve(x, [p(0,0.04), p(0.25,0.27), p(0.5,0.5), p(0.75,0.76), p(1,0.98)])

        case .cinestill:                               // tungsten cinema: teal shadows, cool, moody
            var x = temperature(ci, from: 6500, to: 6900)   // cooler
            x = controls(x, sat: 0.95, con: 1.07)
            x = splitTone(x)
            return curve(x, [p(0,0.03), p(0.25,0.22), p(0.5,0.5), p(0.78,0.82), p(1,0.99)])

        case .ektar:                                   // vivid, crisp, saturated
            var x = controls(ci, sat: 1.26, con: 1.10)
            x = vibrance(x, 0.18)
            return curve(x, [p(0,0.01), p(0.25,0.2), p(0.5,0.5), p(0.75,0.81), p(1,1)])

        case .trix:                                    // contrasty classic B&W
            let m = CIFilter.photoEffectMono(); m.inputImage = ci
            let base = controls(m.outputImage ?? ci, sat: 1, con: 1.12)
            return curve(base, [p(0,0.0), p(0.25,0.18), p(0.5,0.5), p(0.75,0.82), p(1,1)])
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
