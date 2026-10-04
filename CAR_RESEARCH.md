# CAR RESEARCH — 2D Car Sprites for Idle Garage (v6)

Compiled 2026-10-03. Goal: top-down (or 3/4-view) 2D car sprites with a
drift/street-racing vibe for our 12-car collection
(Regular / Rare / Exotic / Legendary tiers).
Requirements: free for commercial use, Godot-friendly (PNG + transparency).

---

## Verified finds (license checked on the exact page)

### 1. Kenney Racing Pack — TOP PICK
- URL: https://kenney.nl/assets/racing-pack
- License: **CC0** (verified on page) — free commercial use, no attribution.
- Contents: 420 files, 2D top-down. Cars, tracks, barriers, decals.
- View: top-down. Style: clean vector-ish, matches our current UI aesthetic.
- Fit: **Excellent.** This is the drift-garage look. Multiple distinct car
  designs in one consistent style = perfect for 4 tiers.

### 2. Kenney Pixel Vehicle Pack — fallback
- URL: https://kenney.nl/assets/pixel-vehicle-pack
- License: **CC0** (verified on page).
- Contents: 50 files, 2D pixel-art top-down vehicles.
- View: top-down. Style: pixel art (chunkier than our current vector look).
- Fit: Good if we want a pixel direction, but clashes slightly with our
  clean vector track/UI. Keep as backup.

### 3. 2D Race Cars by looneybits (OpenGameArt)
- URL: https://opengameart.org/content/racecars-2d
- License: **CC0** (verified on page).
- Contents: 10+ cars, PNG + **layered SVG** (we can recolor/edit!),
  explicitly "mobile friendly."
- View: top-down racing.
- Fit: **Excellent for Exotic/Legendary.** SVG source means we can make
  custom liveries per tier (recolor in code or pre-bake variants).

### 4. Top Down Cars by The Wolf (OpenGameArt)
- URL: https://opengameart.org/content/top-down-cars
- License: **CC0** (verified on page).
- Contents: 6 cars (car1–car6.png), ~7 KB each.
- View: top-down.
- Fit: Good filler for Regular tier. Tiny files.

### 5. Top Down Cars Sprite Pack 1.0 by tokka (itch.io)
- URL: https://tokka.itch.io/top-down-car
- License: **Commercial use explicitly allowed** on the page
  ("You can use these assets both in free and in commercial projects").
  Not formal CC0, but a clear written grant. Name-your-own-price (free).
- Contents: 30 cars (limos, police, taxi, ambulance, everyday cars...).
- View: top-down, GTA-style.
- Fit: Great variety for Regular/Rare filler. Style is GTA1-ish, slightly
  different from Kenney — fine for "street" tier cars.

### 6. Free Top Down Car Sprites by Unlucky Studio
- URL: https://lpc.opengameart.org/content/free-top-down-car-sprites-by-unlucky-studio
  (also mirrored on opengameart.org)
- License: **Royalty-free for personal + commercial** (stated on page,
  credit appreciated but not required).
- Contents: 9 vehicles — Audi-style, Viper-style, police (animated),
  taxi, ambulance (animated), truck, van. High-res PNG.
- View: top-down.
- Fit: Good for Rare/Exotic — the "Viper" and "Audi" reads as sporty.

## Unverified (check license on page before use)

### 7. 2D Top Down Pixel Art Car Pack by marcusvh (itch.io)
- 4 unique cars + truck + trailer, 4 colors each. License not confirmed —
  check the page before importing.

### 8. Sports Car Set by Sundae Buoy (itch.io)
- 6 unique 16-bit top-down racing cars, 64x64 PNG. License not confirmed.

## Wrong view angle (do NOT use on track)

### 9. Pay 'n' Sprite packs (itch.io)
- URL: https://patricio449.itch.io/free-pixel-cars-pack-1-22-cars
- License: commercial OK ("don't resell as assets").
- Contents: 22 cars, 128x128 PNG — but **front/rear view only**
  (OutRun-style), NOT top-down.
- Fit: unusable on the track, BUT genuinely useful as **showroom
  portraits** in the CARS tab (car cards showing front view = car-collector
  vibe). Optional.

---

## Tier mapping proposal (12 cars)

| Tier | Count | Source |
|------|-------|--------|
| Regular | 4 | Kenney Racing Pack basics + The Wolf cars |
| Rare | 3 | tokka pack picks + Unlucky Studio |
| Exotic | 3 | looneybits SVG (custom liveries) |
| Legendary | 2 | Best Kenney racing cars + looneybits hero car |

All from CC0 / commercially-cleared sources above. No attribution required
(credit Kenney anyway — it's good karma and one line).

---

## Recommendation: SWITCH TO SPRITE PNGs

**Switch from procedural rectangles to sprite PNGs. One clear call:**

1. **Tbandz explicitly asked for livery designs on the cars.**
   Procedural polygons can't do liveries, decals, headlights, or real car
   silhouettes without a lot of custom drawing code per car. Sprites give
   it for free.
2. **Download size is trivial.** ~12 cars at 5–15 KB each = under 200 KB
   total. Our wasm is 39 MB. Nobody will notice.
3. **iPhone perf is equal or better.** One textured Sprite2D rotated per
   car is cheaper than per-frame `_draw` polygon calls. We already rotate
   nodes for drift yaw — sprites drop straight into the existing
   `_draw_car` rotation logic (replace polygon with texture draw).
4. **12 distinct cars is the whole point of v6.** Drawing 12 recognizably
   different cars in code is weeks of fiddly polygon work. Curating 12
   from Kenney + looneybits is an afternoon.
5. **Signature moves still work.** 360 spins, reverse entries, wall taps
   are all just rotation — sprites rotate the same as polygons.

**Plan:** Kenney Racing Pack as the primary set (style match), looneybits
SVG for Exotic/Legendary (bake 2–3 custom liveries), tokka/The Wolf as
Regular-tier filler. Optional: Pay 'n' Sprite front-view PNGs as showroom
card portraits in the CARS tab.

**Keep procedural as fallback:** if a sprite fails to load, fall back to
the current colored-rectangle draw so the game never shows a blank car.

---

*License discipline: re-verify the badge on the exact asset page at import
time. Prefer CC0 sources (Kenney, looneybits, The Wolf). tokka and Unlucky
Studio have clear written commercial grants — fine, but screenshot the
grant into the repo for the record.*
