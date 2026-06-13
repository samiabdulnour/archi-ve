import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics

/// Cinematic colour looks. White-balance-led grades (the lever that matters most
/// for a filmic result), plus genuine *per-hue* control via a colour cube (LUT)
/// so greens can go muted-teal and the iPhone's over-saturated reds can be
/// reined in — the way Fuji film sims and Ricoh GR recipes actually behave.
enum CameraLook: String, CaseIterable, Identifiable {
    case original  = "Original"
    case chrome    = "Chrome"        // Classic-Chrome-style: muted, Kodak-ish
    case cinema    = "Cinema"        // Ricoh-GR-style cinematic green, warm WB
    case nostalgic = "Nostalgic"     // Classic-Neg-style: warm highlights, cool shadows
    case studio    = "Studio"        // our own architectural teal-orange
    case mono      = "Mono"          // rich black & white
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
        case .original:
            return ci

        case .chrome:                                  // muted, full-bodied, Kodak-ish
            var x = temperature(ci, from: 6500, to: 6540)      // ~neutral, a hair cool
            x = applyCube(x, data: chromeCube)                 // subdue reds+greens, blues→cyan
            x = controls(x, sat: 0.88, con: 1.06)
            // soft highlights, deeper shadows
            return curve(x, [p(0,0.03), p(0.25,0.235), p(0.5,0.5), p(0.75,0.78), p(1,0.955)])

        case .cinema:                                  // Ricoh-GR cinematic green
            var x = temperature(ci, from: 6500, to: 6300)      // warm WB
            x = applyCube(x, data: cinemaCube)                 // greens → muted teal, reds down
            x = controls(x, sat: 0.93, con: 1.0)
            x = vibrance(x, 0.05)
            // lifted blacks + gentle rolloff = matte, faded cinema
            return curve(x, [p(0,0.055), p(0.25,0.27), p(0.5,0.5), p(0.75,0.74), p(1,0.95)])

        case .nostalgic:                               // Classic-Neg-style
            var x = temperature(ci, from: 6500, to: 6360)      // warm
            x = controls(x, sat: 1.06, con: 1.07)
            x = splitTone(x, strength: 1.0)                    // warm highlights, cool shadows
            return curve(x, [p(0,0.025), p(0.25,0.22), p(0.5,0.5), p(0.78,0.8), p(1,0.985)])

        case .studio:                                  // our own architectural teal-orange
            var x = controls(ci, sat: 0.96, con: 1.05)
            x = applyCube(x, data: studioCube)                 // tame iPhone reds
            x = splitTone(x, strength: 1.9)                    // shadows teal, highlights warm
            x = vibrance(x, 0.08)
            return curve(x, [p(0,0.03), p(0.25,0.23), p(0.5,0.5), p(0.76,0.79), p(1,0.985)])

        case .mono:                                    // rich black & white
            let m = CIFilter.photoEffectMono(); m.inputImage = ci
            let base = controls(m.outputImage ?? ci, sat: 1, con: 1.08)
            return curve(base, [p(0,0.02), p(0.25,0.2), p(0.5,0.5), p(0.75,0.8), p(1,0.99)])
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

    /// Teal in the shadows, warmth in the highlights — the cinematic balance,
    /// scaled by `strength` (≈1 gentle, ≈2 pronounced).
    private static func splitTone(_ ci: CIImage, strength s: Float) -> CIImage {
        let f = CIFilter.colorPolynomial(); f.inputImage = ci
        f.redCoefficients   = CIVector(x: CGFloat(-0.008 * s), y: CGFloat(1 + 0.028 * s), z: 0, w: 0)
        f.greenCoefficients = CIVector(x: 0, y: 1, z: 0, w: 0)
        f.blueCoefficients  = CIVector(x: CGFloat(0.022 * s), y: CGFloat(1 - 0.01 * s), z: CGFloat(-0.018 * s), w: 0)
        return f.outputImage ?? ci
    }

    // MARK: Per-hue colour cubes (LUTs)

    private static let cubeSize = 24

    private static func applyCube(_ ci: CIImage, data: Data) -> CIImage {
        let f = CIFilter.colorCubeWithColorSpace()
        f.cubeDimension = Float(cubeSize)
        f.cubeData = data
        f.colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        f.inputImage = ci
        return f.outputImage ?? ci
    }

    /// Builds CIColorCube data by mapping every grid colour through `map`
    /// (applied in sRGB). Built once per look and reused every frame.
    private static func makeCube(_ map: (SIMD3<Float>) -> SIMD3<Float>) -> Data {
        let n = cubeSize
        var cube = [Float](repeating: 0, count: n * n * n * 4)
        var i = 0
        for b in 0..<n {
            for g in 0..<n {
                for r in 0..<n {
                    let rgb = SIMD3<Float>(Float(r) / Float(n - 1),
                                           Float(g) / Float(n - 1),
                                           Float(b) / Float(n - 1))
                    let out = map(rgb)
                    cube[i + 0] = min(max(out.x, 0), 1)
                    cube[i + 1] = min(max(out.y, 0), 1)
                    cube[i + 2] = min(max(out.z, 0), 1)
                    cube[i + 3] = 1
                    i += 4
                }
            }
        }
        return cube.withUnsafeBufferPointer { Data(buffer: $0) }
    }

    // Classic-Chrome-ish: subdue reds & greens, nudge blues toward cyan.
    private static let chromeCube = makeCube { rgb in
        var hsv = rgb2hsv(rgb)
        let h = hsv.x
        if h < 40 || h > 330 { hsv.y *= 0.70 }              // reds/oranges
        else if h > 70 && h < 170 { hsv.y *= 0.80 }         // greens
        else if h > 185 && h < 265 { hsv.x = h - 12 }       // blues → cyan
        return hsv2rgb(hsv)
    }

    // Ricoh-GR cinematic green: rotate greens toward teal and mute them; reds down.
    private static let cinemaCube = makeCube { rgb in
        var hsv = rgb2hsv(rgb)
        let h = hsv.x
        if h > 70 && h < 165 {                               // greens
            hsv.x = min(h + 22, 176)                         // toward cyan/teal
            hsv.y *= 0.70
        } else if h < 35 || h > 335 {                        // reds
            hsv.y *= 0.85
        }
        return hsv2rgb(hsv)
    }

    // Our own: just rein in the iPhone's over-saturated reds; tones do the rest.
    private static let studioCube = makeCube { rgb in
        var hsv = rgb2hsv(rgb)
        let h = hsv.x
        if h < 35 || h > 335 { hsv.y *= 0.80 }
        return hsv2rgb(hsv)
    }

    private static func rgb2hsv(_ c: SIMD3<Float>) -> SIMD3<Float> {
        let r = c.x, g = c.y, b = c.z
        let mx = max(r, max(g, b)), mn = min(r, min(g, b))
        let d = mx - mn
        var h: Float = 0
        if d > 1e-6 {
            if mx == r { h = (g - b) / d }
            else if mx == g { h = 2 + (b - r) / d }
            else { h = 4 + (r - g) / d }
            h *= 60; if h < 0 { h += 360 }
        }
        let s = mx <= 1e-6 ? 0 : d / mx
        return SIMD3(h, s, mx)
    }

    private static func hsv2rgb(_ c: SIMD3<Float>) -> SIMD3<Float> {
        let h = c.x, s = c.y, v = c.z
        if s <= 1e-6 { return SIMD3(v, v, v) }
        let hh = h.truncatingRemainder(dividingBy: 360) / 60
        let idx = Int(floor(hh))
        let f = hh - Float(idx)
        let pp = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f))
        switch idx % 6 {
        case 0: return SIMD3(v, t, pp)
        case 1: return SIMD3(q, v, pp)
        case 2: return SIMD3(pp, v, t)
        case 3: return SIMD3(pp, q, v)
        case 4: return SIMD3(t, pp, v)
        default: return SIMD3(v, pp, q)
        }
    }

    // MARK: Keystone

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
        // no transparent edges, so no zoom-in is needed — nothing leaves the frame.
        let cw = e.width * 0.99, ch = e.height * 0.99
        return out.cropped(to: CGRect(x: e.midX - cw / 2, y: e.midY - ch / 2, width: cw, height: ch))
    }
}
