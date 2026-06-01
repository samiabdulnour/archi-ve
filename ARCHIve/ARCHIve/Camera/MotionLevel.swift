import CoreMotion
import Observation
import QuartzCore

/// Feeds a smoothed device-roll angle for the camera level, using CoreMotion
/// gravity (no permission prompt, no user gesture — unlike the web
/// DeviceMotion API). Angle math matches the old web app: `atan2(gx, -gy)`,
/// where 0° = upright & level.
@MainActor
@Observable
final class MotionLevel {
    /// Smoothed roll angle in degrees. 0 = level, ±90 = on its side.
    var angle: Double = 0
    /// True when within ~1° of a cardinal (0/90/180/270) — the green state.
    var isLevel: Bool = false
    /// True when the phone is lying flat (gravity mostly on Z) — level hidden.
    var isFlat: Bool = false

    private let manager = CMMotionManager()
    private var smoothed: Double = 0
    private let ema = 0.18   // smoothing factor, matches web

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let g = motion?.gravity else { return }
            self.update(gx: g.x, gy: g.y, gz: g.z)
        }
    }

    func stop() {
        if manager.isDeviceMotionActive { manager.stopDeviceMotionUpdates() }
    }

    private func update(gx: Double, gy: Double, gz: Double) {
        // Flat-on-table dead zone: most of gravity is on Z.
        let planar = (gx * gx + gy * gy).squareRoot()
        let total = (gx * gx + gy * gy + gz * gz).squareRoot()
        isFlat = total > 0 && planar / total < 0.17

        // atan2(gx, -gy): 0° upright, rotates with the phone's roll.
        let raw = atan2(gx, -gy) * 180 / .pi   // degrees, -180...180

        // EMA smoothing with wrap handling.
        var delta = raw - smoothed
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        smoothed += delta * ema
        if smoothed > 180 { smoothed -= 360 }
        if smoothed < -180 { smoothed += 360 }

        angle = smoothed

        // Nearest cardinal (0/90/180/-90).
        let bucket = (smoothed / 90).rounded() * 90
        isLevel = !isFlat && abs(smoothed - bucket) < 1.0
    }
}
