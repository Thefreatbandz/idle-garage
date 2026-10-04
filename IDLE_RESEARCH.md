# IDLE GARAGE — Research File

Compiled 2026-10-03 for our Godot 4.7 drift-garage idle tycoon
(web export, iPhone 12 target, gl_compatibility renderer).
Concept: run a drift shop. Cars earn cash over time, including while away.
Buy upgrades: better cars, mechanics, shop expansions.

---

## 1. Idle Game Comparisons

### AdVenture Capitalist (Hyper Hippo, 2014) — the genre definer
- **Core loop:** Tap a business → progress bar fills → payout → buy more of that
  business → unlock bigger businesses. Lemonade stand → newspaper → car wash →
  … → oil company. Each business has its own cost, payout, and timer.
- **What makes it addictive:** The "one more buy" itch. Businesses get 2x speed
  multipliers at 25/50/100/200 owned (milestone unlocks). Bigger businesses pay
  more but take longer (oil = millions per tap, 10-hour timer). The numbers
  never stop growing — billions become trillions become quadrillions.
- **Progression:** Three worlds (Earth, Moon, Mars), each a fresh economy with
  new businesses/upgrades. Unlocks at owned-count milestones give per-business
  and global multipliers.
- **Prestige:** Angel Investors. Reset everything for Angels proportional to
  lifetime earnings; each Angel = permanent +2% profit. The central strategic
  decision: when to reset. Too early = few Angels; too late = wasted time.
- **Monetization (note only — we're not doing this yet):** Gold (IAP) for
  instant Angels, day-of-idle-earnings skips; MegaBucks from events/milestones
  for ×7.77 golden tickets per business; ads to double offline earnings.
- **Session design:** 5-minute check-ins. Earns offline; you return, collect,
  spend, leave. Designed to NOT demand attention — that's the point.
- Source: https://en.wikipedia.org/wiki/AdVenture_Capitalist

### Idle Miner Tycoon (Kolibri, 2016)
- **Core loop:** Tap miners → ore flows up shaft → elevator → warehouse → cash.
  Three linked stages (mine/elevator/warehouse) create a bottleneck-balancing
  puzzle: upgrade the slowest link.
- **What makes it addictive:** The bottleneck puzzle is genuinely strategic —
  you're always asking "which upgrade gives the best $/sec per $?". 20+ mines,
  8 continents with separate currencies (fresh economies, like AdCap's planets).
- **Managers:** Hire a manager per stage and the mine runs itself. This is the
  moment it becomes a true idle game. Managers also have unique bonus effects.
- **Prestige:** Super Cash. Reset a mine at $1M lifetime for Super Cash =
  permanent multipliers. Managers are KEPT through resets (smart — removes the
  sting).
- **Monetization:** Ads to double offline earnings, barrier skips, Super Cash
  IAP.
- **Session design:** Welcome-back screen showing offline earnings is the #1
  retention driver. Daily rewards with 7-day streaks. Limited-time event mines.
- Sources: https://github.com/philroy/idlemining (open-source clone — useful
  reference implementation)

### Realm Grinder (DivineGames, 2015)
- **Core loop:** Click for coins → buy buildings → buildings auto-produce →
  buy upgrades → pick a faction (alignment) with unique bonuses.
- **What makes it addictive:** Faction choice = build identity. 12+ factions
  with wildly different playstyles; players theorycraft "which faction for
  this run." Deep players, deep retention.
- **Prestige:** Reincarnation — layered and complex. Resets buildings/coins but
  KEEPS trophies, artifacts, faction upgrades. Reincarnation points unlock new
  tiers: offline bonuses, higher factions, new spells. Multiple prestige layers
  (reincarnation → ascension) keep decade-long players engaged.
- **Lesson for us:** Prestige should feel like unlocking a NEW GAME, not
  punishment. Keep some things through the reset (Idle Miner keeps managers;
  Realm Grinder keeps trophies/artifacts).
- **Monetization:** Mostly Steam premium + light IAP. Proves idle games can
  work without aggressive ads.

### NGU Idle (4G, 2019 — solo dev!)
- **Core loop:** Fight boss → get EXP/PP → spend on energy/magic → numbers go
  up → rebirth (prestige) → adventure zones for gear → merge gear → push
  further. Enormous feature sprawl built over years by ONE developer.
- **What makes it addictive:** Absurd depth. Dozens of interlocking systems
  (NGUs, perks, wishes, quirks, evil/sadistic difficulties). Every system feeds
  another. The solo-dev proof that content depth > graphics.
- **Prestige:** Rebirth (short loop, ~30 min) → evil/sadistic difficulty
  unlocks (long loop). Challenges (self-imposed handicaps for permanent
  bonuses). Multiple nested reset layers.
- **Lesson for us:** A solo/small team CAN build a deep idle game. Start with
  ONE tight loop, add systems in waves. NGU's first version was tiny.
- Source: https://ngu-idle.fandom.com/wiki/New_Player_Guide_(Truth)

### Idle Heroes (DH Games, 2016)
- **Core loop:** Summon heroes → auto-battle campaign → collect idle rewards
  (EXP/gold scale with campaign progress) → upgrade/evolve heroes → push
  further.
- **What makes it addictive:** Collection + gacha + team building. 400+ heroes
  across factions. Idle rewards scale with your max campaign stage, so pushing
  further = more idle income = the core incentive loop.
- **Progression:** Campaign stages, Tower, Arena, Guild raids, daily quests,
  events. Multiple progression tracks at different speeds (fast: campaign;
  slow: hero evolution).
- **Lesson for us:** The "idle income scales with furthest progress" trick is
  gold. In our garage: your $/sec should scale with the best car/job you've
  unlocked, so there's always a reason to push one step further.
- **Monetization:** Heavy gacha/IAP. We're skipping this, but note: collection
  mechanics (cars as collectibles) drive spending AND engagement.

### Car-themed idle games (direct competitors)
- **Chrome Garage: Idle Cars** — restore rusty cars → sell for profit → expand
  garage. Offline earnings. Car restoration fantasy = proven hook.
- **Idle Car Shop** — start with one bay → hire staff → expand across the
  city. Staff = managers (automation). Offline earnings.
- **Car Mechanic: Idle Tycoon** — repair cars, unlock workstations, hire
  workers. Satisfying repair animations.
- **Idle Car Factory Tycoon** — conveyor-belt factory, build/sell cars.
- **Pattern:** They all use: garage bays = generators, staff = managers,
  car restoration/sale = payout event, offline earnings. Our drift-shop angle
  (tuning cars for drift races) is a fresh wrapper on a proven formula.

---

## 2. Mechanics to Steal (prioritized)

### P0 — ship with v1
1. **Generators with exponential cost.** The genre's bedrock formula:
   `cost = base × 1.15^owned`. Every car bay / service station uses this.
   Industry standard, players' brains are tuned to it.
2. **Offline earnings + welcome-back screen.** `earned = $/sec × seconds_away`
   (cap at 8–12 hours). The return screen is THE dopamine beat — design it
   deliberately: big number, "while you were away," collect button.
3. **Milestone multipliers.** At 10/25/50/100 owned, a generator gets ×2.
   Gives every purchase tier a mini-goal. AdCap proved this.
4. **Managers/automation.** First purchases are manual (tap to collect); hiring
   a mechanic automates a station. The "it plays itself now" moment is when
   players emotionally commit.
5. **Big number formatting.** K/M/B/T then aa/ab/ac… or scientific. Non-
   negotiable — without it the game feels broken past 1M.

### P1 — add within first month
6. **Prestige (one layer, done right).** "Franchise": reset the garage for
   Reputation Stars = permanent +10% income each. Keep mechanics hired
   (reduces sting, per Idle Miner). Post-prestige runs must feel 2–5x faster
   or players revolt.
7. **Achievements with income bonuses.** CasinoIdle does +1% income per
   achievement (29 of them). Gives completionists a reason to do everything.
8. **Visual progression.** The shop MUST look better as you earn (Taps to
   Riches proved this). New floor tiles at $10K, neon sign at $1M, second
   floor at $100M. Every major unlock changes the scene.
9. **Floating +$ text.** Tap/click feedback: "+$1.2K" floats up. Cheap, juicy,
   essential game feel.

### P2 — later
10. **Daily rewards + streaks.** 7-day calendar, doubling rewards. Cheapest
    retention mechanic in the genre.
11. **Time-limited events.** Weekend "Drift Championship": special currency,
    exclusive mechanic skins. FOMO done ethically (no paid advantage).
12. **Multiple locations.** Second garage across town = fresh economy
    (AdCap's Moon, Idle Miner's continents). Big content lever.

---

## 3. Graphics & Art Direction

### What top idle games look like
- **AdVenture Capitalist:** 2D cartoon caricatures. Flat colors, thick
  outlines, satirical business tycoon vibe. The UI IS the game — rows of
  businesses with progress bars.
- **Idle Miner Tycoon:** 2D side-view mine with tiny animated miners. Clean
  vector look, bright colors, chunky buttons.
- **Egg, Inc.:** Gorgeous 2D farm, soft gradients, satisfying animations.
- **Pattern:** The genre is 2D, clean, cartoon/vector. The screen is 80% UI
  (numbers, bars, buttons) and 20% scene. Nobody plays idle games for the 3D.

### RECOMMENDATION: 2D clean cartoon UI, top-down/side-view garage scene
**Go 2D. One clear reason:** in idle games the UI is the game — players stare
at numbers, progress bars, and buy buttons, not a 3D world. A 3D garage would
burn our iPhone/WebGL budget on a backdrop players ignore, while 2D gives us
crisp text, 60fps, tiny download size, and the exact visual language the
genre's players expect (AdCap, Idle Miner, Egg Inc. are all 2D). We can still
use our PS1/sunset *palette* (amber, neon, dusk) so it feels like OUR game,
and add one animated 2D garage scene (cars on lifts, mechanics walking,
sparks) for life. 3D is a backdrop risk — the camera fights the spreadsheet.
(Singularity Inc's GDD says exactly this.)

### UI patterns to use
- **Big numbers first.** Cash balance huge at top, $/sec under it. Tabular
  figures (Share Tech Mono — we already have it).
- **Progress bars everywhere.** Every generator shows fill → payout. Glowing
  when full (Idle Miner's "collect me" signal).
- **Floating +$ text.** Pooled labels, float up and fade. Never instantiate
  per tap without pooling.
- **Buttons pulse when affordable.** Scale animation on buy buttons the moment
  the player can afford them — the "shiny button" pull.
- **x1 / x10 / x100 / MAX bulk buy toggle.** CasinoIdle has this; players
  expect it. MAX = "buy as many as I can afford."
- **Card-per-generator layout.** Each car bay = a card: icon, name, owned
  count, $/sec, progress bar, buy button. This is the genre's native UI.
- **Dark theme with amber/neon accents.** Our sunset palette differentiates us
  from every pastel idle game. True-black backgrounds also save OLED battery.

---

## 4. Performance

### The idle game performance contract
- **Math is trivial; UI is the cost.** Income = sum of generator outputs.
  Compute in a `_process(delta)` accumulator (NEVER Timer nodes — they drift).
  Update labels at 10 FPS max, or via signals only when values change.
- **BigNumber from day 1.** Floats die at ~1.8e308. Use mantissa+exponent
  (e.g. `1.5e300`). Format: K/M/B/T → aa/ab/ac… → scientific past ~1e303.
  (CasinoIdle's `fmt.gd` and the gd-agentic-skills `scientific_notation_
  formatter.gd` are reference implementations.)
- **Cost formula:** `base_price × 1.15^owned` (industry standard). Bulk-buy
  cost = geometric series sum — precompute, don't loop 10,000 times.
- **Save system:** Autosave every 20s + on focus-out/app-pause/exit (browser
  tabs never deliver close events — CasinoIdle learned this). Keep a `.bak`
  backup copy. Version your saves; migrate old versions. Store a unix
  timestamp → offline earnings = rate × elapsed (capped).
- **Battery:** `OS.low_processor_usage_mode = true` on mobile. Throttle to
  30fps when idle-tabbed. Dark/OLED-friendly palette. No per-frame
  allocations in the income loop.
- **Web specifics (we know these):** gl_compatibility renderer, threads OFF,
  no system fonts in browser (bundle our own — we already do), user://
  persists via IndexedDB.

---

## 5. Free Assets (verified free for commercial use)

### UI kits & icons (all CC0 — public domain, no attribution required)
| Asset | What | License | URL |
|---|---|---|---|
| Kenney UI Pack | 430 UI elements: buttons, panels, sliders, 9-slice windows | CC0 | https://kenney.nl/assets/ui-pack |
| Kenney Game Icons | Hundreds of game icons (coin, tools, wrench, car) | CC0 | https://kenney.nl/assets/game-icons |
| Kenney 1-Bit Pack | Minimal B/W icons, trivially recolorable to our palette | CC0 | https://kenney.nl/assets/1-bit-pack |
| Kenney Car Kit | 2D/3D cars for scene dressing or icons | CC0 | https://kenney.nl/assets/car-kit |

### Fonts (all OFL — free for commercial, we already ship 3 of these)
- **Orbitron** — big cash display (we have it)
- **Rajdhani** — buttons/headings (we have it)
- **Share Tech Mono** — $/sec, timers, tabular numbers (we have it)
- Kenney Future (bundled in Kenney UI packs) — backup display font

### Godot-specific idle references (open source)
| Repo | What | URL |
|---|---|---|
| impulserfl/CasinoIdle | Complete Godot 4 idle game: economy, prestige, offline progress, autosave, achievements, bulk buy. The single best reference. | https://github.com/impulserfl/casinoidle |
| philroy/idlemining | Open-source Idle Miner clone | https://github.com/philroy/idlemining |
| gd-agentic-skills (idle-clicker) | Godot 4.7 idle blueprint: BigNumber, 1.15x costs, offline calc, prestige, formatter script | https://github.com/thedivergentai/gd-agentic-skills/blob/HEAD/skills/godot-genre-idle-clicker/SKILL.md |

### Audio (CC0)
- Kenney Interface Sounds — clicks, buy chimes, achievement dings:
  https://kenney.nl/assets/interface-sounds
- Our existing synth SFX pipeline from TOUGE works too.

---

## 6. Our Game Blueprint — IDLE GARAGE v1

### 30-second pitch
You inherit a beat-up drift garage. Tap the service bay to finish jobs and
earn cash. Hire mechanics to automate bays. Buy better bays (tuning, paint,
engine shop) that earn more. Tune customer drift cars and send them out —
they earn while you're away. Franchise (prestige) for permanent boosts and
watch your garage go from grease pit to neon empire.

### First 5 minutes (onboarding)
1. **0:00** — Empty garage, one lift, one rusty car. "TAP THE LIFT to finish
   the job." Tap → progress bar → +$25. Floating "+$25" text.
2. **0:45** — "Buy another job slot" ($50). Now two bars filling. Player
   learns the buy loop.
3. **1:30** — "Hire Marco the Mechanic" ($150). The bay now runs itself.
   THE moment — the game plays itself, player is hooked.
4. **2:30** — "Unlock Paint Booth" ($500). Second generator, new card, new
   visuals (paint booth appears in the garage scene).
5. **4:00** — "Your crew earned $X while you read this" — first offline-
   style beat (simulate 30s). Welcome-back screen tutorial.
6. **5:00** — Drift contract offered: tune a car for Saturday's race, bigger
   payout, longer timer. Sets up the mid-game.

### Upgrade tiers (v1: 6 generators)
1. **Oil Change Bay** — $25 base, 3s timer. The lemonade stand.
2. **Tire Shop** — $150 base, 8s. Unlocks at $500 lifetime.
3. **Paint Booth** — $800 base, 20s. Unlocks at $5K. Visual: booth appears.
4. **Tuning Lab** — $4K base, 45s. Unlocks at $40K. ECU maps, turbo kits.
5. **Engine Build Room** — $25K base, 2min. Unlocks at $300K.
6. **Drift Contract Board** — $150K base, 5min. Unlocks at $2M. Customer
   drift cars; each completion parks a tuned car in your showroom (visual
   progression + collection hook).
- Each: 1.15^owned cost growth, ×2 at 25/50/100 owned.
- Mechanics (managers): one per generator, escalating cost, automates it.

### Prestige: FRANCHISE
- Unlock: $100M lifetime earnings.
- Reset all cash/generators/mechanics. Keep: achievement bonuses.
- Gain **Reputation Stars**: 1 per $10M lifetime, each = permanent +10%
  income. New franchise location skin per star tier (visual prestige flex).
- Post-prestige pace target: reach previous peak in ~1/3 the time.

### Screen layout (portrait-first? No — landscape 1280×720 like TOUGE)
```
┌──────────────────────────────────────────────────┐
│ $1.24M            IDLE GARAGE          $8.2K/sec │
│ (Orbitron 44)                                  │
├──────────────────────────────────────────────────┤
│  [2D garage scene: lifts, cars, mechanics,      │
│   sparks, neon sign — animated, ~40% height]     │
├──────────────────────────────────────────────────┤
│ ┌ card ─────────────────────────────┐ ┌ tabs ─┐ │
│ │ 🛠 Oil Change Bay    x37  $/s 1.2K │ │ BAYS  │ │
│ │ [████████████░░░░░░]  BUY $4.2K   │ │ MECH  │ │
│ └───────────────────────────────────┘ │UPGRADE│ │
│ ┌ card ─────────────────────────────┐ │STATS  │ │
│ │ 🎨 Paint Booth       x12  $/s 3.8K │ └───────┘ │
│ │ [███████░░░░░░░░░░░]  BUY $9.1K   │           │
└──────────────────────────────────────────────────┘
```
- Tabs: Bays (generators) / Mechanics (managers) / Upgrades (global
  multipliers) / Stats (achievements, prestige).
- Bulk toggle: x1 / x10 / x100 / MAX (top-right of Bays tab).
- Settings gear: save indicator, reset save, low-power toggle.

### v1 scope discipline
- 6 generators, 6 mechanics, ~20 global upgrades, 15 achievements, 1
  prestige layer, offline earnings, autosave. NOT in v1: events, second
  location, gacha, multiplayer, ads. Add in waves like NGU Idle did.
- All 2D UI + one animated 2D garage scene. Zero 3D. Tiny PCK, 60fps,
  sips battery.

---

*License discipline: verify the badge on the exact asset page before
shipping. All items above are CC0 or OFL (both allow commercial use,
no attribution required).*
