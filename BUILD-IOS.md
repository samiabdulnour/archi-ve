# Building ARCHI-ve for iOS (App Store)

This is a step-by-step you run **once your Apple Developer Program enrolment is approved** and you're sitting at a Mac with Xcode installed. Until then, everything in this file is "later" — the repo prep (manifest, icons, Capacitor config) is already done.

Why this exists: the app is plain HTML/CSS/JS. To put it on the App Store, we wrap that web app in a thin native iOS shell. **Capacitor** is the tool of choice — it's the smallest possible wrapper, doesn't change `index.html`, and lets us add native iOS APIs later (proper camera plugin, Photos write, etc.).

---

## 0. What you need before you start

- A Mac (Capacitor's iOS toolchain only runs on macOS).
- **Xcode 15+** from the Mac App Store. ~15GB download. Open it once after install so it accepts the licence.
- **Node.js 20+** from <https://nodejs.org> (pick the LTS installer). Capacitor's CLI is a Node package.
- **Cocoapods**: `sudo gem install cocoapods` in Terminal. iOS dependencies are installed via Pods.
- Apple Developer Program membership (approved).
- This repo cloned locally.

---

## 1. Add Capacitor to the repo (one-time)

From the repo root in Terminal:

```bash
# Initialise a tiny package.json so npm has somewhere to record Capacitor.
# This does NOT introduce a bundler or build step. The app is still served
# from index.html as-is.
npm init -y

# Install Capacitor core + CLI + iOS platform.
npm install --save @capacitor/core @capacitor/ios
npm install --save-dev @capacitor/cli

# Capacitor reads capacitor.config.json (already in this repo) for appId,
# appName, and webDir. So `init` is a no-op when the config exists — but
# run it once to register the package with the CLI:
npx cap init "ARCHI-ve" "com.archi-ve.app" --web-dir=.

# Add the iOS platform. This creates an /ios folder with an Xcode project.
npx cap add ios

# Copy web assets + native config into the iOS project.
npx cap sync ios
```

The `/ios` folder is committed-friendly. The `/node_modules` folder is not — make sure `.gitignore` excludes it (see Step 6).

---

## 2. App icon: drop the 1024 into the Xcode project

The repo already contains generated icons in `/ios/icon-*.png`. For the iOS app bundle we need them placed into Xcode's Asset Catalog.

```bash
npx cap open ios
```

That opens Xcode on the generated project. In Xcode's left sidebar:

1. Open **App → App → Assets.xcassets → AppIcon**.
2. Drag `ios/icon-1024.png` from Finder onto the **App Store iOS 1024pt** slot.
3. Xcode auto-generates the smaller sizes from the 1024.

If Xcode doesn't auto-generate (older versions), drag each size into its matching slot using the file naming convention in `/ios/icon-*.png`.

---

## 3. Signing & capabilities

In Xcode, with the **App** target selected:

1. **Signing & Capabilities** tab.
2. Tick **Automatically manage signing**.
3. **Team**: pick your Apple Developer team from the dropdown.
4. **Bundle Identifier**: should read `com.archi-ve.app`. If Xcode complains it's taken, change to `com.<yourname>.archive` and update `capacitor.config.json` too.
5. Click **+ Capability** and add:
   - **Camera** — for live capture via getUserMedia in the WebView.
   - Add an **Info.plist key** `NSCameraUsageDescription` = `"ARCHI-ve uses the camera to capture photos for your archive."`
   - `NSPhotoLibraryAddUsageDescription` = `"ARCHI-ve saves photos to your Photos library on request."` (only if you wire up the share-to-Photos feature later).
   - `NSLocationWhenInUseUsageDescription` = `"ARCHI-ve tags each photo with the place it was taken so you can browse the archive on a map."`

---

## 4. First build to the simulator

In Xcode, top toolbar:

1. Pick **iPhone 15 Pro** (or any) from the device dropdown.
2. Press **▶ Run** (Cmd+R).
3. Wait. First build is slow (Xcode compiles Capacitor's Swift glue).
4. The simulator boots and launches ARCHI-ve.

If the app shows a white screen: `npx cap sync ios` and rebuild. The web assets didn't copy over.

---

## 5. Run on your physical iPhone

1. Plug the iPhone into the Mac with a USB cable.
2. On the iPhone: **Settings → Privacy & Security → Developer Mode → On** (requires restart).
3. In Xcode, pick the iPhone from the device dropdown.
4. Press ▶ Run.
5. First time only: on the iPhone, **Settings → General → VPN & Device Management → Apple Development: <your-email>** → trust.

Now the app is on your phone, running as a real installed app — not a web page.

---

## 6. .gitignore

Add to `.gitignore`:

```
node_modules/
ios/App/Pods/
ios/App/Podfile.lock
ios/App/build/
ios/DerivedData/
*.xcuserstate
```

Commit `ios/App/App.xcodeproj`, `ios/App/Podfile`, `capacitor.config.json`, `package.json`, `package-lock.json` — those are the build inputs.

---

## 7. TestFlight (private beta with you + invited testers)

1. In Xcode: **Product → Archive**. Wait for build.
2. The Organizer window opens. Click **Distribute App → App Store Connect → Upload**.
3. Go to <https://appstoreconnect.apple.com>, your app → **TestFlight** tab.
4. The build appears after Apple processes it (~10–30 min).
5. Fill in **Test Information** (what to test, contact email).
6. Add yourself as an internal tester. Install **TestFlight** from the App Store on your iPhone, accept the invite, install ARCHI-ve.

This is the path you should use for at least a week before submitting to the public App Store — to shake out crashes and iOS-specific bugs.

---

## 8. App Store submission

In App Store Connect:

1. **App Information**: name, subtitle, category. See `APPSTORE.md` for the draft copy.
2. **Pricing**: Free.
3. **Privacy**: declare what data the app collects (none — everything is local). Link to a privacy policy URL.
4. **Screenshots**: 6.7" (iPhone 15 Pro Max) and 6.5" required. Take with the iOS Simulator → File → New Screenshot.
5. **Description / Keywords / Support URL**: from `APPSTORE.md`.
6. **Build**: pick the TestFlight build.
7. **Submit for Review**.

Review takes 1–7 days. Common rejection reasons for this app:
- Camera/photo permission strings missing → fixed in Step 3.
- Crashes on launch on older iOS → test on iOS 16+ simulators.
- Missing privacy policy URL → host the existing `PRIVACY.md` somewhere public.

---

## 9. Updating the app after launch

For web-only changes (CSS, HTML, JS):

```bash
# Edit index.html as normal, push to main, the website updates automatically.
# For the iOS app, copy the new web assets in and re-archive:
npx cap sync ios
# Then in Xcode: Product → Archive → upload → submit new build.
```

Bumping the version: in Xcode, **General** tab, bump **Version** (e.g. 1.0.0 → 1.0.1) and **Build** (incremental, e.g. 1 → 2). Apple requires the build number to increase with every upload.

---

## Notes

- **The Leaflet CDN dependency** (`unpkg.com/leaflet@1.9.4`) currently requires internet at launch. The native app may want to bundle Leaflet locally — TODO before App Store submission, since Apple discourages mandatory network calls on launch.
- **The `getUserMedia` camera** works inside the Capacitor WebView with the camera permission set in step 3. If we hit any iOS quirks (focus, orientation), we'll swap to the `@capacitor/camera` plugin which uses native AVFoundation.
- **IndexedDB persists across app updates** by default in Capacitor's WKWebView. Photos survive.
