# App Store listing — ARCHI-ve

Draft copy and metadata for the App Store Connect submission. Edit before submitting.

---

## Identity

| Field | Value |
| --- | --- |
| **App name** | ARCHI-ve |
| **Subtitle** | Architect's photo archive |
| **Bundle ID** | com.samiabdulnour.archive |
| **SKU** | archive-ios-001 |
| **Primary category** | Photo & Video |
| **Secondary category** | Productivity |
| **Age rating** | 4+ (no objectionable content) |
| **Price** | Free |

---

## Description (4000 char limit)

> ARCHI-ve is a private photo archive for architects.
>
> Take a photo on a site visit, at an exhibition, or of a book page. Two taps to tag it — what typology, what room, what element, what concept, what material — and it's filed. Browse later by any of those tags, by time, or by place on a map.
>
> Built for the way architects actually shoot: site walks, references in the wild, exhibitions, your own work in progress. No accounts, no cloud, no sharing — your photos live on your phone and never leave.
>
> **Capture in seconds**
> One screen. Tap the shutter. Two tag prompts. Done. The whole flow takes under ten seconds so it's usable while walking.
>
> **Browse by what you actually look for**
> Filter the archive by typology (residential / office / hospitality / public / commercial / heritage / landscape), by room (lobby, atrium, workspace, kitchen…), by architectural element (column, vault, façade, joint…), by concept (form, light, structure, materiality…), or by material (stone, wood, concrete, metal, glass…).
>
> **Reference vs Project modes**
> Reference for photos you encounter in the wild. Project for site-specific shoots — pick the project once, then shoot a whole sequence into it.
>
> **Yours, on your phone**
> All photos and tags are stored locally on your device. There is no server, no account, no cloud sync. The app works offline.
>
> Designed for working architects, by an architect.

---

## Promotional text (170 char limit, can be updated without a new build)

> The fastest way to file an architecture photo. Two taps, tagged. No accounts, no cloud — your archive stays on your phone.

---

## Keywords (100 char limit, comma-separated, no spaces)

```
architecture,photo,archive,reference,journal,visit,exhibition,site,project,typology,tag,catalog
```

---

## Support URL

`https://github.com/samiabdulnour/archi-ve`  *(or a dedicated page later)*

## Marketing URL (optional)

`https://samiabdulnour.github.io/archi-ve/`

## Privacy policy URL (required)

`https://samiabdulnour.github.io/archi-ve/PRIVACY.html`  *(create from PRIVACY.md before submission — Apple will reject without a working URL)*

---

## Privacy — App Privacy section in App Store Connect

| Data type | Collected? | Linked to user? | Used for tracking? |
| --- | --- | --- | --- |
| Photos | **Stored on device only** | No | No |
| Location (coarse, per-photo) | **Stored on device only** | No | No |
| Camera | Accessed for capture | No | No |
| Identifiers / contacts / browsing history / etc. | Not collected | — | — |

The app does not transmit any data off the device. Mark all App Privacy categories as "Data Not Collected" except where the in-device storage is disclosed.

---

## Screenshots — required sizes

Apple requires screenshots for the largest iPhone size you support. Take from the iOS Simulator (**File → New Screenshot** at 6.7" device).

Recommended set (6 screenshots, each 1290 × 2796 px):

1. **Welcome / How-to-use** — the welcome diagram with the call-outs.
2. **Camera viewfinder** — paper bands, mint Reference highlighted, mode pill at the bottom.
3. **Tag flow** — the Type / Room / Concept tiles mid-tag.
4. **Gallery time lens** — photo grid grouped by month, with the typology row.
5. **Gallery map lens** — the world map dotted with photo pins.
6. **Photo detail** — single photo with all metadata + tags visible.

Captions (one short line each, ≤ 30 chars per ARCHI-ve design):

1. "Two taps. Archive complete."
2. "Capture in ten seconds."
3. "Pre-defined tags. No typing."
4. "Browse by month, place, project."
5. "Every photo on the map."
6. "Yours, on your phone."

---

## App Review Information (private)

| Field | Value |
| --- | --- |
| Contact first name | Sami |
| Contact last name | Abdulnour |
| Contact email | sami.abdulnour@gmail.com |
| Contact phone | *(your phone)* |
| Sign-in required? | No |
| Demo account | n/a |

**Notes to reviewer:**

> ARCHI-ve is a single-user, on-device photo archive. It does not connect to any server or service. All capture, tagging, browsing, and storage happen locally via the device's camera and IndexedDB. The Leaflet map tiles loaded from openstreetmap.org are the only external resource (read-only, no data sent out).
>
> The app's two camera permissions are for taking photos (camera) and tagging each photo with the location it was taken (location). Both are accessed only when the user is actively capturing.

---

## Version 1.0 — what's new

```
First release. The fast capture loop, the tag taxonomy, gallery filters across
typology, room, element, concept, material, project, and place. Light + dark
themes. Built for the way architects actually shoot.
```

---

## Open TODOs before submission

- [ ] Host `PRIVACY.html` at a public URL (GitHub Pages can serve a markdown file rendered to HTML).
- [ ] Take and edit the six screenshots in the Simulator.
- [ ] Decide whether to bundle Leaflet locally instead of via CDN (Apple sometimes flags mandatory network calls on launch).
- [ ] Confirm bundle ID `com.samiabdulnour.archive` is available in App Store Connect. (Capacitor doesn't allow dashes, so `com.archi-ve.app` couldn't be used.)
- [ ] Increment the version in Xcode each build (1.0.0 / build 1 for first submission).
