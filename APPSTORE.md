# App Store submission — step-by-step

This is the practical walkthrough for getting archi-ve into the iOS App
Store. It assumes you are publishing under your own name as an
**Individual** developer (the simpler path; pick this unless you have a
business reason to publish as an LLC/company).

The whole process splits into three phases:

1. **One-time setup** — Apple Developer account + Bundle ID + privacy URL.
2. **App record** — create the listing in App Store Connect.
3. **Build + submit** — wrap the web app, upload, and submit for review.

Phase 1 you do once. Phase 2 you do once per app. Phase 3 you do every
time you ship a new version.

This guide only covers phases 1 and 2 in detail. Phase 3 needs the
Capacitor wrapping work, which lives in a separate PR.

---

## Prerequisites checklist

Before you start, have these ready:

- [ ] An **Apple ID** (your usual one is fine).
- [ ] A **credit / debit card** for the $99 USD annual developer fee.
- [ ] A **physical address** that matches government ID — Apple will verify
      your identity by sending a code to a phone tied to it.
- [ ] An **iPhone** with that Apple ID signed in, for the 2FA prompt.
- [ ] **GitHub Pages enabled** for `samiabdulnour/archi-ve` so the privacy
      policy URL resolves (see Step 0 below to confirm).
- [ ] About **30 minutes** of uninterrupted time for the signup, plus
      **24–48 hours** waiting for Apple to verify your identity.

---

## Step 0 — Confirm the privacy policy URL works

Once this PR is merged, the file `privacy.html` in the repo root will be
served by GitHub Pages at:

> **`https://samiabdulnour.github.io/archi-ve/privacy.html`**

After merging, open that URL in any browser. You should see the privacy
policy page. **This is the URL you give Apple in Phase 2.**

If you get a 404:

1. Open <https://github.com/samiabdulnour/archi-ve/settings/pages>.
2. Under "Build and deployment", confirm Source = **Deploy from a branch**.
3. Branch = `main`, folder = `/ (root)`.
4. Click Save and wait ~1 minute for the rebuild.

---

## Step 1 — Enrol in the Apple Developer Program

1. Go to <https://developer.apple.com/programs/enroll/> on your Mac (you
   can do this on Windows/Linux too, but later steps need a Mac for
   Xcode — borrow or rent one then).
2. Click **Start Your Enrollment**. Sign in with your Apple ID.
3. Choose **Individual / Sole Proprietor** when asked about entity type.
4. Fill in your legal name and address exactly as they appear on your
   government ID. Apple does verify this.
5. Pay the **$99 USD** annual fee. Renews automatically.
6. Wait. Apple sends a confirmation email within a few hours; full
   approval (you'll see "Welcome" in your Apple Developer dashboard) takes
   **24 to 48 hours**. Sometimes faster.

Once approved, you have access to:

- **<https://developer.apple.com/account/>** — certificates, identifiers,
  provisioning profiles.
- **<https://appstoreconnect.apple.com/>** — the App Store listing,
  build uploads, TestFlight, sales.

---

## Step 2 — Reserve the Bundle ID

The Bundle ID is the unique reverse-DNS identifier for your app. Once
you ship a version under a Bundle ID, you can never change it for that
app on the store. Pick once, pick well.

Suggested: **`com.abdulnour.archive`** (short, your surname, the app's
purpose). Confirm or change before proceeding.

1. Go to <https://developer.apple.com/account/resources/identifiers/list>.
2. Click the **+** button next to "Identifiers".
3. Choose **App IDs** &rsaquo; **App**.
4. Description: `archi-ve`.
5. Bundle ID: **Explicit**, enter `com.abdulnour.archive`.
6. Capabilities: tick **Access WiFi Information** only if needed (it is
   not, for this app). Leave others alone for now — they can be added
   later.
7. Click **Continue** &rsaquo; **Register**.

You now have a reserved identifier. No code yet.

---

## Step 3 — Create the app record in App Store Connect

1. Go to <https://appstoreconnect.apple.com/apps>.
2. Click **+** &rsaquo; **New App**.
3. Fill in:
   - **Platform:** iOS.
   - **Name:** `archi-ve` (what shows on the store and home screen).
     Names must be unique across the store — if taken, try
     `archi-ve journal` or `archi-ve archive`.
   - **Primary language:** English (U.S.).
   - **Bundle ID:** select the `com.abdulnour.archive` you just made.
   - **SKU:** `archive-001` (private internal ID, never shown).
   - **User Access:** Full Access.
4. Click **Create**.

The empty app shell now exists. The rest is filling in metadata.

---

## Step 4 — Fill the App Privacy questionnaire

This is the section that uses the privacy policy URL.

1. From the app record, sidebar &rsaquo; **App Privacy**.
2. Paste the privacy URL into **Privacy Policy URL**:
   `https://samiabdulnour.github.io/archi-ve/privacy.html`
3. Click **Get Started** for the data collection survey.

Honest answers, mapped to what `privacy.html` says:

| Apple question                              | Answer                          |
| ------------------------------------------- | ------------------------------- |
| Do you or your third-party partners collect data from this app? | **No**            |

That's the headline answer, because archi-ve stores everything on-device
and the developer (you) has no server collecting anything. The third-party
services the app contacts (Google Fonts, unpkg, OpenStreetMap, Nominatim)
are network requests that may be logged by those services as part of
normal web traffic, but they don't collect identifiable data **on your
behalf**, so Apple's questionnaire treats this as **No**.

If you ever add analytics, crash reporting, or a sync backend, this
answer changes — come back and update it.

---

## Step 5 — Fill the rest of the listing

You'll need these assets ready. None are written yet — flag this so we
can do it in a follow-up:

- [ ] **App icon** — 1024×1024 PNG, no transparency, no rounded corners
      (Apple rounds them).
- [ ] **Screenshots** — minimum one set: 6.7" iPhone (1290×2796) or
      6.9". You need 3–10 screenshots. Capture them from a real iPhone
      using the wrapped build.
- [ ] **App description** — short marketing paragraph (4000 chars max).
- [ ] **Keywords** — 100 chars, comma-separated, no spaces.
- [ ] **Support URL** — can point to the GitHub repo for now:
      `https://github.com/samiabdulnour/archi-ve`.
- [ ] **Marketing URL** — optional, can be blank.
- [ ] **Category** — Primary: **Photo & Video**, Secondary:
      **Productivity**.
- [ ] **Age rating** — answer the questionnaire; for a personal photo
      journal with no UGC, ratings come out 4+.
- [ ] **Pricing** — Free.
- [ ] **Availability** — All territories, unless you want to restrict.

---

## Step 6 — Wrap, sign, upload, submit

This is Phase 3 and depends on the Capacitor wrapping work (separate PR).
Outline only:

1. Install Capacitor in the project, init iOS platform.
2. Configure `Info.plist` with the camera + location usage descriptions
   (Apple requires a human sentence per permission, e.g.
   `NSCameraUsageDescription` = "archi-ve needs the camera to take the
   photos you save to your archive.").
3. Open the generated `ios/App` Xcode project.
4. Set the Team to your individual developer account.
5. Bundle ID must match `com.abdulnour.archive`.
6. Build a release archive: **Product** &rsaquo; **Archive**.
7. Distribute &rsaquo; **App Store Connect** &rsaquo; Upload.
8. Back in App Store Connect &rsaquo; your app &rsaquo; Version 1.0, attach
   that build, fill in "What's New", and click **Submit for Review**.

Apple review takes **1 to 3 days** for the first submission. They will
often reject a first submission for small things; common ones:

- Permission usage strings are too vague.
- Privacy policy URL doesn't actually load (test it from a network with
  no GitHub cache).
- Screenshots show non-final UI or contain Apple trademarks.

Fix and resubmit; subsequent reviews are usually faster.

---

## What to do right now

Order of operations from this PR:

1. **Merge this PR** so `privacy.html` is live.
2. **Verify** the privacy URL loads (Step 0).
3. **Start Phase 1** — enrol in the Apple Developer Program (Step 1).
   The 24–48h wait is the long pole.
4. While waiting, decide on the **Bundle ID** and **App name** (Step 2,
   Step 3).
5. Once approved, run through Steps 2–5 in one sitting (~1 hour).

Phase 3 (Capacitor wrap + first build) is the next PR after this one.
