# ARCHI-ve — App Icon Design Brief (handoff)

A handoff for designing a **new iOS app icon** for ARCHI-ve. Everything a
designer (or a design agent) needs: identity, palette, concept directions,
constraints, and exact delivery specs.

---

## 1. What the app is

**ARCHI-ve** — a fast, private **photo-journal for an architect**. The owner
snaps architecture they notice in everyday life (buildings, details, materials,
exhibition pieces, book pages), tags each shot with a small structured
vocabulary (two taps), and browses the archive later by time, reference,
project, or place. Single user, on their own iPhone. No social, no cloud-share
feel — it's a personal, considered tool.

**Personality:** editorial, calm, architectural, precise. Warm paper-and-ink,
not techy/neon. Think a well-made notebook or a museum wall label, rendered with
Apple-native restraint. Minimal, confident, a little crafted.

**Name styling:** the wordmark is written **ARCHI-ve** — "ARCHI" in ink, "-ve"
in the coral accent. (For reference only; the icon should **not** contain text.)

---

## 2. Current icon (what we're replacing)

A white woven-aperture / interlaced-circle glyph on a **blue→purple gradient**
(`AppIcon.png`, 1024². See `ARCHIve/ARCHIve/Assets.xcassets/AppIcon.appiconset/`).

**Why replace it:** the blue/purple gradient is generic and **off-brand** — it
doesn't relate to the app's warm paper/ink/coral palette or its architectural,
editorial character. We want an icon that feels like it belongs to *this* app.

---

## 3. Brand palette (use these — exact values)

| Token | Hex | Use |
|-------|-----|-----|
| Paper | `#F0EFE9` | warm limestone background |
| Paper (elevated) | `#FFFFFF` | |
| Ink | `#16140F` | near-black, primary marks |
| Ink 2 | `#3A352B` | warm dark brown |
| **Coral** | `#F44E48` | **the signature accent** |
| Mint | `#7CE3A0` | secondary (Reference) |
| Lemon | `#E8E373` | secondary (Project) |

**Direction:** lead with **paper + ink + coral**. Coral is the brand's
signature — a small, deliberate coral element is the strongest tie to the app.
Mint/lemon are optional accents, use sparingly if at all. Avoid blue/purple.

---

## 4. Concept directions (pick/combine — not prescriptive)

The mark should read instantly at small sizes as **one** clear idea. Strong
candidates, roughly best-first:

1. **Aperture / lens** — ties to "capture", architectural and geometric. Could
   be refined, thinner, ink-on-paper with a coral element (e.g. one coral blade,
   or a coral focus dot at centre). Evolves the current idea rather than tossing
   it.
2. **Lettermark "A"** — an architectural capital A (could double as a roof /
   pediment / measuring triangle). Ink A on paper with a coral detail.
3. **Archive + architecture fusion** — a stacked/indexed motif (cards, spreads,
   layers) implying an archive of images, kept geometric and minimal.
4. **Aperture + structure** — the lens blades formed from architectural lines
   (a plan grid, a column, a threshold), merging "camera" and "building".
5. **Tag** — a single clean tag/label shape (nods to the two-tap tagging core),
   ink with a coral edge.

**Avoid:** literal cameras, generic photo-stack clichés, skeuomorphic gradients,
heavy detail, anything that needs text to be legible.

---

## 5. Visual constraints (so it works as an iOS icon)

- **One focal shape**, centred, generous margins. Must be crisp at **40–60px**
  (Home Screen / Settings / Spotlight).
- **Full-bleed background** (a flat or very subtly graded fill — keep it tasteful,
  warm). The shape sits on top with good contrast.
- **No text**, no photographs, no tiny details that vanish when scaled.
- **Don't round the corners** — iOS applies the superellipse mask. Deliver a
  full square; keep important content away from the extreme corners.
- **No transparency** — fully opaque background, edge to edge.
- Should feel at home next to native iOS icons (flat, modern, confident).

---

## 6. Deliverables & technical specs

**Primary:** a single **1024 × 1024 px PNG**, **sRGB**, **no alpha/transparency**,
no pre-applied corner rounding.
- Filename: **`AppIcon.png`**
- Drop-in location: `ARCHIve/ARCHIve/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
  (overwrites the current file; `Contents.json` already points at this single
  universal 1024 asset — no other sizes needed, Xcode generates them).

**Nice-to-have (iOS 18 appearance modes):** if easy, also provide
- a **Dark** variant (same mark, dark warm-ink background), and
- a **Tinted** (monochrome) version (single-colour mark on transparent/!), so the
  system can tint it.
  (If provided, say so and I'll switch the asset catalog to the 3-slot
  single-size layout. Otherwise the one light icon is fine for launch.)

**Process artifacts welcome:** a few 1024² explorations to choose from, shown on
both light and dark home-screen mock backgrounds, and at a small size
(~60px) to prove legibility.

---

## 7. Acceptance checklist

- [ ] Reads clearly at ~60px and in greyscale.
- [ ] Uses the warm palette; coral present and intentional; no blue/purple.
- [ ] One focal idea, centred, safe margins, full-bleed opaque background.
- [ ] No text, no transparency, square (un-rounded) 1024² sRGB PNG.
- [ ] Feels architectural / editorial / Apple-native — not generic or techy.

---

## 8. Drop-in / install (once art is chosen)

1. Replace `ARCHIve/ARCHIve/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
   with the new 1024² PNG (same filename).
2. Build & run — the new icon appears on the Home Screen.
3. (If dark/tinted variants are added, I'll update `Contents.json` to the
   three-appearance single-size format and wire the extra files.)

App identity: **ARCHI-ve** · bundle `com.samiabdulnour.archive`.
