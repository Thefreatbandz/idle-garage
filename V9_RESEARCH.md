# V9 RESEARCH — What to add to Idle Garage

Compiled 2026-10-04. Goal: the next wave of features that make the game more
FUN and keep people coming back — not just bigger numbers.

Current state (v8): 8 auto bays, 20 cars (4 rarities), 5 buyable real drift
tracks (Ebisu/Meihan/Nikko/Long Beach/Irwindale), mechanics, 15 upgrades,
15 achievements, style meter → 2x HEAT, offline earnings, 1 prestige layer
(Franchise stars). Godot 4.7, portrait, web export, iPhone 12 target.

Already covered (do NOT re-propose): offline earnings + welcome-back screen,
achievements, milestone multipliers, bulk buy, big-number formatting,
prestige layer 1.

Sources: IDLE_RESEARCH.md (in-repo), pocketgamer.biz (Gold & Goblins live-ops
deconstruction, Rockbite daily-missions case study), gamigion 2025 mobile
market reports, genre design audits (multi-layer prestige: Anti-Idle /
Realm Grinder / Revolution Idle), drift-game feature surveys (CarX, OverDrift
Festival, JDM: Japanese Drift Master).

---

## TOP 8 — ranked by impact vs. effort for a solo dev shipping fast

### 1. Daily Rewards (login calendar)
- **What:** 7-day streak calendar. Open the game → claim escalating rewards
  (cash → style points → free Regular car → free Rare car → big cash).
  Missing a day resets to day 1 (reward-for-presence, never punishment).
- **Why it fits:** The single cheapest retention mechanic in the genre
  (IDLE_RESEARCH P2). Our game is already built around "come back and
  collect" (offline earnings) — a daily calendar turns that into a habit.
  Korean market data treats daily attendance as the baseline generosity
  signal players expect.
- **Scope:** SMALL. New popup + date tracking in save + reward table.
  No new art needed (reuse car/cash icons).

### 2. Drift Missions (daily/weekly quests)
- **What:** A short checklist that refreshes daily: "Earn $50K", "Buy 2 cars",
  "Trigger HEAT 3 times", "Own 5 Rare cars". Completing all = bonus chest.
  Shown on the main screen like Rockbite's home-base daily tab.
- **Why it fits:** Right now a session is "spend cash, leave." Missions give
  every 2-minute session a purpose. Rockbite's case study: daily missions on
  the home screen lifted R1–R3 ~3% and later-day retention more. Gold &
  Goblins' lesson: "every time the core loop slows down, a quest kicks in —
  you always have a nearby goal."
- **Scope:** SMALL-MEDIUM. Mission definitions + progress counters (most
  events already tracked: earnings, buys, HEAT triggers) + a list UI.

### 3. Sponsors
- **What:** Car-culture contracts you sign: "Falken-style Tire Co: +20% Tire
  Shop income, requires 3 Rare+ cars." "Energy Drink Brand: +10% style gain,
  requires Irwindale owned." 8–10 sponsors, each with an unlock condition and
  a themed bonus. Pick 3 active at a time → light loadout strategy.
- **Why it fits:** The most on-brand income-depth mechanic available. Real
  drift runs on sponsors; it turns our 20-car collection and 5-track roster
  into *requirements* instead of just purchases. Adds strategy ("which 3?") to
  a game that currently has none — without touching the core loop.
- **Scope:** SMALL-MEDIUM. Data table + unlock checks + active-3 picker UI.
  Bonus math plugs into existing `income_per_sec()`.

### 4. Weekend Drift Championship (timed event)
- **What:** Every Fri–Sun: a special 6th track ("Ebisu Finals") appears.
  Earn event points from style gain + HEAT triggers during the window.
  End-of-weekend payout tiers: cash, exclusive event-only car (rotating),
  trophy in AWARDS tab. Rivals are seeded bots with beatable scores
  (no server needed).
- **Why it fits:** Gold & Goblins' $100M lesson: player activity *spikes*
  when events start — events are the #1 live-ops lever, and they're
  completable-without-paying by design. Real drifting IS weekend
  competitions (Formula Drift, Ebisu events). Gives veterans a reason to
  return weekly and new players something to aspire to.
- **Scope:** MEDIUM. Weekend window logic (local clock) + event currency +
  bot leaderboard + 1 exclusive car per rotation. No backend required.

### 5. Livery Studio (player car customization)
- **What:** Pick per car: paint color (palette), stripe style, racing number,
  decal slot. Renders live on the track via the existing overlay system
  (we already draw spoiler bars + number roundels in `_draw_car` — this
  just makes them player-chosen).
- **Why it fits:** Tbandz asked for visible car designs/decals TWICE and was
  unsatisfied with both attempts. OverDrift Festival and CarX both treat
  livery creation as a headline feature — car culture is self-expression.
  Turns the 20-car collection from "stat sticks" into "MY cars."
- **Scope:** MEDIUM. Picker UI (color swatches, 4–5 stripe patterns, number
  entry) + save per-car livery + extend overlay drawing. No new sprites.

### 6. Car Meets (collection showcase)
- **What:** Weekly Friday-night meet: enter up to 5 cars, scored on rarity
  mix + liveries + total style. Ranked against seeded bot crews. Rewards:
  cash, style points, exclusive "Best in Show" trophy. Your entered cars
  visibly park together in the preview during the meet.
- **Why it fits:** Gives the 20-car collection a *purpose* beyond income
  multipliers — currently there's no reason to own more than 6 (one per
  bay). Real car culture runs on meets; it's the social fantasy without
  needing real multiplayer. Pairs naturally with #5 (liveries get judged).
- **Scope:** MEDIUM. Entry picker + scoring formula + bot crews + reward
  tiers. Reuses track preview for the meet scene.

### 7. HEAT Tap minigame (active skill moment)
- **What:** When HEAT triggers, a 5-second " clipping zone" bar appears:
  a marker sweeps and you tap when it's in the green zone. Perfect taps
  extend HEAT (+5s each, up to +15s). Misses do nothing (no punishment).
- **Why it fits:** Our signature mechanic (HEAT) is currently 100% passive.
  One tiny skill moment per HEAT gives active players something to *do*
  during the most exciting 30 seconds of the game, and it's pure juice —
  green-zone timing is the cheapest fun-per-line-of-code in games.
  "Less pressure plus more depth equals better long-term retention"
  (Gold & Goblins) — this is depth without pressure.
- **Scope:** SMALL. One overlay UI + sweep timer + HEAT extension hook.
  No economy changes.

### 8. Second prestige layer ("Motorsport Empire")
- **What:** Above Franchise stars: reset stars/tracks/cars for Empire Points.
  Each point unlocks a permanent *new mechanic*, not just a multiplier —
  e.g. "keep equipped cars through Franchise," "auto-trigger HEAT at full
  meter," "9th bay slot." 5–8 empire upgrades total.
- **Why it fits:** The genre's proven endgame extender (Realm Grinder:
  Reincarnation → Ascension; Anti-Idle: 3 layers; Revolution Idle:
  Prestige → Infinity → Eternity). Design rule from research: each layer
  must feel like "a new game," not a bigger number — mechanic unlocks do
  that. Our vets will hit the Franchise wall; this is their next mountain.
- **Scope:** LARGE. Second reset path + empire upgrade tree + save
  migration. Biggest build here — schedule it as its own version, not
  bundled with 1–7.

---

## PARKED (good ideas, wrong time)

- **Battle/season pass:** needs a live-ops content cadence a solo dev can't
  sustain yet. Revisit when events (#4) prove the audience.
- **Guilds/clans & real PvP:** needs a backend. Our web export has none.
  Seeded bots (#4, #6) deliver 80% of the feeling for 5% of the cost.
- **Push notifications:** unreliable on web export; parked with ads.
- **Second garage location (AdCap's "Moon"):** great v10+ lever — a fresh
  economy doubles content. Too big for v9 alongside 1–8.
- **Photo mode / share:** small and fun, but strictly lower retention impact
  than anything in the top 8. Easy filler for a polish pass.

## Suggested v9 packaging

- **v9a (fast):** #1 Daily Rewards + #2 Missions + #7 HEAT Tap. Three
  small-scope features, one version, all about "reasons to open the game
  today."
- **v9b (culture):** #3 Sponsors + #5 Livery Studio + #6 Car Meets. The
  car-culture wave — collection, expression, and showing off.
- **v9c (event):** #4 Weekend Championship. Its own version so the
  weekend cadence can be tuned alone.
- **v10:** #8 Second prestige. Its own mountain.

---

*License discipline: no new assets required for any top-8 item. All art
reuses existing Kenney CC0 sprites + procedural overlays.*
