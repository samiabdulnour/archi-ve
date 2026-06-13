import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics

/// Cinematic colour looks. White-balance-led grades (the lever that matters most
/// for a filmic result), plus genuine *per-hue* control via a colour cube (LUT)
/// so greens can go muted-teal and the iPhone's over-saturated reds can be
/// reined in — the way Fuji film sims and Ricoh GR recipes actually behave.
enum CameraLook: String, CaseIterable, Identifiable {
    case original  = "Original"
    case portra    = "Portra 400"      // warm, soft, lifted shadows, muted greens
    case gold      = "Gold 200"        // golden, nostalgic, warm yellows
    case ektar     = "Ektar 100"       // vivid, punchy, clean
    case cinestill = "CineStill 800T"  // tungsten: cool, teal shadows, halation glow
    case trix      = "Tri-X 400"       // contrasty black & white
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

        case .portra:                                  // Kodak Portra 400
            var x = temperature(ci, from: 6500, to: 6250)     // warm
            x = applyCube(x, data: portraCube)                // muted greens (→yellow), blues→cyan
            x = controls(x, sat: 0.96, con: 0.94)             // soft, low contrast
            x = vibrance(x, 0.06)
            // lifted shadows (the signature trait) + soft highlight rolloff
            return curve(x, [p(0,0.06), p(0.25,0.275), p(0.5,0.5), p(0.75,0.74), p(1,0.95)])

        case .gold:                                    // Kodak Gold 200
            var x = temperature(ci, from: 6500, to: 6120)     // golden warm
            x = applyCube(x, data: goldCube)                  // greens → gold, punchy yellows
            x = controls(x, sat: 1.05, con: 1.04)
            return curve(x, [p(0,0.045), p(0.25,0.26), p(0.5,0.5), p(0.75,0.76), p(1,0.97)])

        case .ektar:                                   // Kodak Ektar 100
            var x = temperature(ci, from: 6500, to: 6600)     // a touch cool/clean
            x = applyCube(x, data: ektarCube)                 // punchy reds + blues
            x = controls(x, sat: 1.18, con: 1.10)
            x = vibrance(x, 0.12)
            return curve(x, [p(0,0.02), p(0.25,0.225), p(0.5,0.5), p(0.75,0.785), p(1,0.998)])

        case .cinestill:                               // CineStill 800T (tungsten)
            var x = temperature(ci, from: 6500, to: 6950)     // tungsten → cool/blue
            x = applyCube(x, data: cinestillCube)             // greens → teal
            x = controls(x, sat: 0.98, con: 1.06)
            x = splitTone(x, strength: 1.6)                   // teal shadows, warm highlights
            x = bloom(x)                                      // signature red-highlight halation glow
            return curve(x, [p(0,0.04), p(0.25,0.235), p(0.5,0.5), p(0.78,0.8), p(1,0.97)])

        case .trix:                                    // Kodak Tri-X 400
            let m = CIFilter.photoEffectMono(); m.inputImage = ci
            let base = controls(m.outputImage ?? ci, sat: 1, con: 1.10)
            return curve(base, [p(0,0.03), p(0.25,0.2), p(0.5,0.5), p(0.75,0.8), p(1,0.99)])
        }
    }

    /// Soft highlight glow — CineStill's halation. Bloom enlarges the extent, so
    /// crop back to the input's frame.
    private static func bloom(_ ci: CIImage) -> CIImage {
        let f = CIFilter.bloom(); f.inputImage = ci; f.radius = 9; f.intensity = 0.35
        return (f.outputImage ?? ci).cropped(to: ci.extent)
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

    // Portra: greens lean yellow-green and mute; blues muted toward cyan.
    private static let portraCube = makeCube { rgb in
        var hsv = rgb2hsv(rgb)
        let h = hsv.x
        if h > 70 && h < 175 { hsv.x = h - 12; hsv.y *= 0.78 }        // greens → yellow-green, muted
        else if h > 185 && h < 265 { hsv.x = h - 10; hsv.y *= 0.82 } // blues → cyan, muted
        return hsv2rgb(hsv)
    }

    // Gold: greens drift to gold; yellows get punchier (the golden cast).
    private static let goldCube = makeCube { rgb in
        var hsv = rgb2hsv(rgb)
        let h = hsv.x
        if h > 70 && h < 160 { hsv.x = h - 18; hsv.y *= 0.82 }        // greens → golden
        else if h >= 40 && h <= 70 { hsv.y = min(hsv.y * 1.12, 1) }  // yellows punchier
        return hsv2rgb(hsv)
    }

    // Ektar: punch up the primaries (reds + blues) — vivid, clean.
    private static let ektarCube = makeCube { rgb in
        var hsv = rgb2hsv(rgb)
        let h = hsv.x
        if h < 35 || h > 330 { hsv.y = min(hsv.y * 1.15, 1) }        // reds
        else if h > 185 && h < 265 { hsv.y = min(hsv.y * 1.12, 1) }  // blues
        return hsv2rgb(hsv)
    }

    // CineStill: greens drift to teal and mute (with the cool tungsten WB + split-tone).
    private static let cinestillCube = makeCube { rgb in
        var hsv = rgb2hsv(rgb)
        let h = hsv.x
        if h > 80 && h < 175 { hsv.x = min(h + 18, 178); hsv.y *= 0.80 }
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
