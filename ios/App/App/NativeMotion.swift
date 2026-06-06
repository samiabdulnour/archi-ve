import Foundation
import Capacitor
import CoreMotion

// Streams the device GRAVITY vector to JS at ~30 Hz via CoreMotion.
//
// Why this exists (and why it is the one piece of hand-written native Swift in
// this project): the web DeviceMotion/DeviceOrientation APIs inside Capacitor's
// WKWebView only start delivering AFTER a user gesture (iOS gates
// requestPermission() behind a tap). That made the camera level + icon-spin sit
// frozen until the screen was tapped. CoreMotion's device-motion gravity needs
// NO permission prompt and NO gesture, so the level goes live the instant the
// camera opens. The owner explicitly relaxed the "no native Swift" rule for
// this on 2026-06-01. See memory: ios-device-motion.
//
// gravity is a unit vector in the device frame (≈ (0, -1, 0) held upright in
// portrait). JS reads it exactly like accelerationIncludingGravity — the angle
// math (atan2) is scale-independent, so the web fallback stays identical.
@objc(NativeMotionPlugin)
public class NativeMotionPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativeMotionPlugin"
    public let jsName = "NativeMotion"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise)
    ]

    private let manager = CMMotionManager()

    @objc func start(_ call: CAPPluginCall) {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else {
            call.resolve()
            return
        }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let g = motion?.gravity else { return }
            self.notifyListeners("gravity", data: ["x": g.x, "y": g.y, "z": g.z])
        }
        call.resolve()
    }

    @objc func stop(_ call: CAPPluginCall) {
        manager.stopDeviceMotionUpdates()
        call.resolve()
    }
}

// Capacitor 8 only auto-registers plugins shipped as npm packages (read from
// capacitor.config.json). An app-local plugin must be registered by hand, which
// is what this CAPBridgeViewController subclass does in capacitorDidLoad().
// Main.storyboard points its single view controller at this class. Subclassing
// keeps the Info.plist portrait lock intact (supportedInterfaceOrientations is
// inherited from CAPBridgeViewController).
public class MotionBridgeViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(NativeMotionPlugin())
    }
}
