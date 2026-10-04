# TRACK RESEARCH — 5 Real Drift Track Layouts (v8)

Compiled 2026-10-03. Goal: 5 geometrically DISTINCT 2D top-down track shapes
for Idle Garage, each inspired by a famous real drift circuit. These replace
color-only themes with real layout variety — each shape must read clearly
different in a ~720x300 phone preview.

Current in-game track is a symmetric stadium oval (2 straights + 2 semicircles).
Keep it as a 6th bonus "Clubman" track or retire it; the 5 below are the new set.

Implementation note for parent: each recipe is a segment list
(straight L / arc angle,radius) that can be turned into a parametric
`_track_pos(t)` the same way the current stadium is built. Proportions are
given for a ~640x260 drawing area.

---

## 1. EBISU MINAMI — "Drift Stadium" (Japan)

Real layout: Part of the Ebisu complex (Fukushima). Minami is the touge-style
drift stadium — narrow, wall-lined, with elevation changes and the famous jump
entry. Flowing S-curves rather than hairpins; rewards linking one long drift
through rhythm sections. Tight enough that walls are always close.

Key features: S-curve rhythm section, narrow width, jump, walls both sides.

**2D simplification: KIDNEY / PEANUT with S-curves.**
Take a stadium oval and bow both straights inward so the track pinches in the
middle like a peanut. One straight bows left, the other bows right → creates
a natural S-curve flowing section on each side.

Recipe: straight(180) → arc(200°, r=55) → S-curve(160, bow 30) →
arc(200°, r=55) → S-curve(160, bow -30) → close.
Width: narrow (28px vs current 32). Infield: dark (night vibe), minimal grass.

In-game name: "Ebisu Nights". Theme: dark asphalt, red/white curbs, faint
crowd dots on the outside of the S-curves. Bonus idea: +style gain (it's a
drift stadium — style meter fills 15% faster here).

Distinctive read: the only track that pinches in the middle.

---

## 2. MEIHAN C COURSE — "The Wall Ride" (Japan)

Real layout: Meihan Sportsland, Nara. C Course is famous for ONE thing: a long
wall-lined straight that lets drivers build huge speed, ending in a wall that
"eats cars" — ultra-fast entries into a tight section. The rest of the course
is a short technical return. Asymmetric: one very long straight, one very
tight end.

Key features: long wall straight (speed entry), tight 180° hairpin, short
technical return leg.

**2D simplification: PAPERCLIP.**
One straight ~2.5x longer than the other. Long straight → tight 180° hairpin
(small radius) → short straight back → wide 180° sweeper (large radius).

Recipe: straight(300) → arc(180°, r=35) → straight(120) → arc(180°, r=80)
→ close. The radius mismatch (35 vs 80) is what sells the paperclip.

In-game name: "Meihan Wall". Theme: concrete-gray walls drawn thick on the
long straight (wall-ride visual), yellow/black curb on the hairpin. Bonus
idea: +10% income (fast entries = big energy).

Distinctive read: the only strongly asymmetric track — one end pointy-tight,
one end fat-round.

---

## 3. NIKKO CIRCUIT — "The Technical 12" (Japan)

Real layout: Tochigi, Japan. Compact 12-turn course, home of D1 GP and
grassroots soukoukai. Quick entries (famous Turn 1), technical linked turns,
slight elevation. No single signature corner — the challenge is linking all
12 turns without straightening.

Key features: compact, 12 turns, no long straights, rhythm/linked corners.

**2D simplification: ROUNDED TRIANGLE with uneven corners.**
Three straights of different lengths (140 / 100 / 180) joined by three
different corner radii (tight hairpin r=30, medium r=55, sweeper r=75).
Every corner a different speed = reads "technical" instantly.

Recipe: straight(140) → arc(120°, r=30) → straight(100) → arc(120°, r=55) →
straight(180) → arc(120°, r=75) → close. (Interior angles sum correctly for
a closed triangle: 3 × 120° of turning.)

In-game name: "Nikko Tech". Theme: green infield (it's a countryside
circuit), white/red curbs. Bonus idea: +5% style AND +5% income (balanced).

Distinctive read: the only triangular track — three visibly different
corners.

---

## 4. LONG BEACH (Formula Drift) — "The Street Course" (USA)

Real layout: FD uses turns 9-10-11 of the Long Beach GP street circuit.
~80mph entry into a 90° right-hander (T9), wall clipping zones under the
bridge between 9-10, sweeping left past the grandstands (T10), then a full
direction change into the tight T11 hairpin, finishing sideways across the
line. Concrete walls everywhere, zero runoff — the most unforgiving course.

Key features: 90° corners (not sweepers), wall-lined, hairpin finale,
street-circuit angularity.

**2D simplification: ANGULAR BOOT / "L".**
Mostly 90° corners with short chamfers instead of arcs. One tight hairpin
(180° but small radius) as the finale corner. Draw with squared-off corners
— the ONLY track with sharp corners reads instantly as "street course".

Recipe: straight(200) → corner(90°, chamfer 25) → straight(140) →
corner(90°, chamfer 25) → straight(90) → hairpin(180°, r=30) →
straight(160) → corner(90°, chamfer 25) → close.
Add concrete-wall visuals: thick gray border on the outside of every
corner, grandstand rectangles on one straight.

In-game name: "Long Beach". Theme: gray concrete walls, blue/white curbs,
palm-dot decorations on the infield (two or three green dots = palms).
Bonus idea: +15% income (unforgiving = prestigious).

Distinctive read: the only track with sharp 90° corners — everything else
flows, this one bites.

---

## 5. IRWINDALE SPEEDWAY — "House of Drift" (USA)

Real layout: Irwindale, California. Banked 1/2-mile outer oval (progressive
banking 6°/9°/12°) + 1/3-mile infield oval. FD's course uses BOTH: Outside
Zone 1 on the big bank wall, Outside Zone 2 on the inner bank wall. Two long
high-speed wall zones — the fastest, most spectacular course in FD. Closed
Dec 2024, so it's a tribute pick.

Key features: banked oval, TWO concentric ovals, long wall zones, pure speed.

**2D simplification: TWIN OVAL.**
A clean wide ellipse (no pinched straights — true oval, wider corner radii
than the stadium) with the 1/3-mile infield oval drawn as a second,
thinner track line inside it. Banking suggested visually: darker shading on
the outside of corners + "BANKED" chevron marks on the turns.

Recipe: ellipse(rx=260, ry=110) for the outer; inner ellipse(rx=170, ry=70)
drawn at 40% width as the infield oval. Cars run the outer; the inner oval
is decoration (or a future second route).

In-game name: "Irwindale". Theme: night — dark blue bg, white/red curbs,
spotlight cones (4 translucent white triangles from outside the track),
stadium crowd dots ringing the outside. Bonus idea: +20% income (the
"House of Drift" premium — most expensive track).

Distinctive read: the only track with two visible ovals + night stadium
atmosphere.

---

## Shape cheat-sheet (must look different at a glance)

| # | Track        | Silhouette in preview              |
|---|--------------|------------------------------------|
| 1 | Ebisu Minami | Peanut — pinched middle, S-curves  |
| 2 | Meihan C     | Paperclip — one long straight, one tight end |
| 3 | Nikko        | Rounded triangle — 3 uneven corners |
| 4 | Long Beach   | Angular boot — sharp 90° corners   |
| 5 | Irwindale    | Twin oval — outer + inner ellipse, night |

No two share a silhouette. Ebisu is the only pinched one, Meihan the only
asymmetric one, Nikko the only triangle, Long Beach the only angular one,
Irwindale the only double-oval.

## Suggested buy/switch structure (for parent)

- TRACKS tab: 5 cards, each shows a mini silhouette (draw the same polyline
  scaled to ~120x50 in the card — instant readability).
- Costs: Ebisu $25K → Meihan $150K → Nikko $600K → Long Beach $3M →
  Irwindale $12M (escalating with bonuses).
- Bonuses: Ebisu +15% style rate / Meihan +10% income / Nikko +5%/+5% /
  Long Beach +15% income / Irwindale +20% income.
- Selected track changes the preview shape AND applies its bonus.
- Cars "go along with the tracks": the existing car-follow logic
  (`_track_pos(t)` + drift zones) works on any closed polyline — just
  re-derive drift zones per track (put them on the curviest segments of
  each shape: S-curves for Ebisu, hairpin for Meihan, T1 for Nikko,
  T9/T11 for Long Beach, banked turns for Irwindale).

## Sources consulted

- Ebisu Minami: SLRspeed/SIMHQ Assetto Corsa listings (touge-style, narrow
  flowing turns, wall riding), CarX Ebisu Complex overview.
- Meihan C: motortrend.com Super D Japan 2017 (long wall-lined straight into
  a wall), sandalsracing.net (wall ride section, fast entries), thedrive.com
  Keep Drifting Fun short film.
- Nikko: fatlace.com (tight corners, fast transitions), motortrend.com King
  of Nations 2017 (12-turn course), thenaritadogfight.com (short technical
  course).
- Long Beach: drivingline.com FD 2018 recap (T9 90° entry at ~80mph, wall
  zones, T11 hairpin), news.turn14.com 2015 (course outline), Wikipedia
  (hairpin + Shoreline Drive straight).
- Irwindale: Wikipedia (banked 1/2-mile + 1/3-mile ovals, progressive
  banking 6°/9°/12°), motortrend.com FD 2019 (two long zones: big bank wall
  OZ1, inner bank wall OZ2), pasmag.com (House of Drift finale).
