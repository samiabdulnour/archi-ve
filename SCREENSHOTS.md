# Podklady pro App Store screenshoty (brief pro ChatGPT)

Tenhle soubor vlož (celý nebo po částech) do ChatGPT. Slouží ke dvěma věcem:
**A)** vygenerovat realistické *architektonické fotky*, kterými appku naplníš
před focením screenshotů; **B)** složit *marketingové* App Store screenshoty
(nadpis + pozadí + rámeček telefonu) z tvých reálných snímků.

> ⚠️ Apple chce, aby screenshoty věrně ukazovaly skutečnou appku. Nevymýšlej
> falešné UI. UI = tvoje reálné screenshoty; AI použij na obsahové fotky a na
> marketingový layout (nadpisy, pozadí, rámeček).

---

## 1) Co je appka (kontext pro GPT)

**Archi.vé** je soukromý fotojournal pro architekty. Vyfotíš architekturu,
které si všimneš (fasáda, detail, materiál, výstavní exponát, stránka z knihy,
model), dvěma ťuknutími ji otaguješ pevně daným slovníkem a později ji najdeš
podle času, reference (co je na fotce), projektu nebo místa na mapě. Vše je
lokálně na zařízení a synchronizuje se přes vlastní iCloud uživatele. Nativní
iPhone app (SwiftUI), míří do App Store.

**Tón:** editorial, klidný, architektonický, "teplý papír a inkoust", ne
technicky/neonově. Jako dobře udělaný zápisník nebo muzejní popiska.

## 2) Vizuální identita (drž se přesně)

- **Název / wordmark:** „Archi.vé" — serifové písmo, „Archi" inkoustově,
  „.vé" korálově.
- **Ikona:** korálová clona (aperture) s černými lamelami a světlým
  hexagonem uprostřed.
- **Paleta (HEX):** papír `#F0EFE9`, inkoust `#16140F`, **korál `#F44E48`**
  (akcent), mint `#7CE3A0` (Reference), citron `#E8E373` (Project),
  dlaždice `#E5E3DA`.
- **Ikonky v UI:** Apple SF Symbols (čisté, tenké).
- **Režimy:** světlý (teplý papír) i tmavý (skoro černá). Kamera je vždy tmavá.
- **Zařízení:** iPhone, **na výšku**.

## 3) Rozměry a formát (App Store)

- Povinné: **6.9" iPhone = 1320 × 2868 px**, portrait, PNG/JPG, bez průhlednosti.
- (Volitelně 6.5" = 1242 × 2688 px.)
- Doporučeno 6 screenshotů.

## 4) Realistický obsah, kterým appku naplnit (prompty na fotky)

Vygeneruj v ChatGPT 12–20 **realistických architektonických fotek** (na výšku i
šířku), které pak naimportuješ do appky a vyfotíš s nimi UI. Náměty:

- Betonová fasáda s výrazným rastrem; brutalistický detail.
- Cihlová zeď, vazba cihel zblízka.
- Kamenná zeď / mramorový detail.
- Dřevěný obklad, spár a textura.
- Kovová fasáda / ocelový spoj.
- Skleněná fasáda s odrazem.
- Schodiště (vřetenové i přímé) — beton, kov.
- Interiér: lobby, atrium, světlík.
- Výstava / galerie: exponát na bílé stěně, popiska u obrazu.
- Stránka z knihy / půdorys / skica.
- Fyzický architektonický model.
- Krajina / dlažba / veřejný prostor.

Styl fotek: přirozené světlo, dokumentární, bez lidí v hlavní roli, čisté.

## 5) Šest screenshotů (obsah + nadpis)

U každého: nahoře krátký **nadpis** (headline), pod ním rámeček telefonu s
**reálným** screenshotem dané obrazovky. Pozadí jemné (papírové `#F0EFE9` nebo
tmavé `#16140F`), akcent korál. Nadpisy uváděj **anglicky** (App Store je EN);
v závorce CZ pro tebe.

1. **Kamera / hledáček** — screenshot kamery (mřížka, vodováha, REFERENCE/PROJECT).
   Headline: **"Capture in seconds."** _(Zachyť to za pár vteřin.)_
2. **Tagování** — screenshot „Tag photo" s dlaždicemi (Building → Element, výběr).
   Headline: **"Two taps. Filed."** _(Dvě ťuknutí. Uloženo.)_
3. **Galerie – Time** — mřížka fotek (3 ve řádku), nahoře Time/Reference/Project/Map.
   Headline: **"Your whole archive, by time."** _(Celý archiv podle času.)_
4. **Reference** — řádky podle typologie/elementu s počty a náhledy.
   Headline: **"Browse by what it is."** _(Hledej podle toho, co to je.)_
5. **Mapa** — špendlíky fotek na mapě.
   Headline: **"Find it by place."** _(Najdi podle místa.)_
6. **Detail fotky** — fotka + řádky tagů (Kind, Typology, Material, Rating…).
   Headline: **"Private. Synced. Yours."** _(Soukromé. Synced. Tvoje.)_

Typografie nadpisů: **serif**, inkoust, jedno slovo/věta korálově pro akcent.

## 6) Příklady tagů (ať obsah vypadá opravdově)

- Building · Typology: Residential / Public / Heritage; Room: Lobby, Atrium.
- Element: Stair (Vertical), Facade (Envelope), Joint (Detail); Material: Concrete,
  Stone, Timber, Glass, Metal.
- Graphic: Drawing / Book / Model / Artwork.
- Concept: light, structure, materiality. Rating: ★★★★☆. Project: „Aalto House".

## 7) Hotový prompt pro ChatGPT (zkopíruj)

> Jsi grafik. Navrhni 6 App Store screenshotů na výšku (1320×2868 px) pro
> iPhone aplikaci „Archi.vé" — soukromý fotojournal pro architekty. Drž se
> palety: papír #F0EFE9, inkoust #16140F, korál #F44E48 (akcent), mint #7CE3A0,
> citron #E8E373. Wordmark „Archi.vé" serifem (Archi inkoust, .vé korál).
> Každý screenshot = nahoře serifový nadpis (akcentové slovo korálově), dole
> rámeček iPhonu s mým reálným screenshotem dané obrazovky (vložím ho). Nadpisy
> a obrazovky podle seznamu: [vlož sekci 5]. Styl editorial, klidný, teplý
> papír a inkoust. Nevymýšlej UI — UI dodám jako reálné snímky; ty řeš nadpis,
> pozadí a rámeček. Nejdřív mi ale vygeneruj 16 realistických
> architektonických fotek podle těchto námětů: [vlož sekci 4].

---

### Postup v kostce
1. GPT → 16 architektonických fotek → ulož do Fotek.
2. V Archi.vé: Import (⋯ → Import) → naťaguj je (různé typy/materiály, pár
   oblíbených ★, jeden projekt).
3. Vyfoť 6 obrazovek (Simulator iPhone 16 Pro Max = 6.9", ⌘S; nebo z telefonu).
4. GPT (nebo Figma/Canva) → slož marketingové rámečky s nadpisy z tvých snímků.
5. Nahraj do App Store Connectu (1320×2868).
