class_name Economy
extends RefCounted
## Generator definitions and cost/payout math for Idle Garage.

# [name, icon, base_cost, base_payout, base_time_s, unlock_at_lifetime]
const GENERATORS := [
	{"name": "Oil Change Bay", "icon": "🛢", "cost": 25.0, "payout": 25.0, "time": 3.0, "unlock": 0.0},
	{"name": "Tire Shop", "icon": "🛞", "cost": 150.0, "payout": 150.0, "time": 8.0, "unlock": 500.0},
	{"name": "Paint Booth", "icon": "🎨", "cost": 1200.0, "payout": 800.0, "time": 20.0, "unlock": 5000.0},
	{"name": "Tuning Lab", "icon": "⚙", "cost": 8000.0, "payout": 4000.0, "time": 45.0, "unlock": 40000.0},
	{"name": "Engine Build Room", "icon": "🔧", "cost": 60000.0, "payout": 25000.0, "time": 120.0, "unlock": 300000.0},
	{"name": "Drift Contract Board", "icon": "🏁", "cost": 400000.0, "payout": 150000.0, "time": 300.0, "unlock": 2000000.0},
]

# Mechanics (managers): one per generator [name, cost]
const MECHANICS := [
	{"name": "Marco", "cost": 150.0},
	{"name": "Lena", "cost": 1200.0},
	{"name": "Big D", "cost": 9000.0},
	{"name": "Yuki", "cost": 60000.0},
	{"name": "Rosa", "cost": 400000.0},
	{"name": "Ghost", "cost": 2500000.0},
]

# Global upgrades: [name, desc, cost, mult] — mult applies to all income
const UPGRADES := [
	{"name": "Better Wrenches", "desc": "+25% all income", "cost": 1000.0, "mult": 1.25},
	{"name": "LED Shop Lights", "desc": "+25% all income", "cost": 8000.0, "mult": 1.25},
	{"name": "Coffee Machine", "desc": "+30% all income", "cost": 50000.0, "mult": 1.30},
	{"name": "Neon Sign", "desc": "+35% all income", "cost": 250000.0, "mult": 1.35},
	{"name": "Dyno Machine", "desc": "+40% all income", "cost": 1200000.0, "mult": 1.40},
	{"name": "Showroom Floor", "desc": "+50% all income", "cost": 6000000.0, "mult": 1.50},
	{"name": "Pro Pit Crew", "desc": "+60% all income", "cost": 30000000.0, "mult": 1.60},
	{"name": "Wind Tunnel", "desc": "+75% all income", "cost": 150000000.0, "mult": 1.75},
	{"name": "Factory Team", "desc": "+100% all income", "cost": 800000000.0, "mult": 2.0},
	{"name": "Legend Status", "desc": "+150% all income", "cost": 5000000000.0, "mult": 2.5},
]

const COST_GROWTH := 1.15
const MILESTONE_BONUS := 2.0  # x2 at 25/50/100/200 owned

# Showroom cars: {name, cost, income (mult), speed (mult), style (pts/sec), move, color, livery, rarity}
# rarity: "regular" (+income), "rare" (+income/speed), "exotic" (+income/style),
#         "legendary" (+income/speed/style, unique moves)
# livery: "plain", "stripe", "number", "twotone"
const CARS := [
	# REGULAR — honest income
	{"name": "Rust Bucket", "cost": 0.0, "income": 1.0, "speed": 1.0, "style": 1.0, "move": "drift", "color": Color(0.55, 0.55, 0.58), "livery": "plain", "rarity": "regular"},
	{"name": "Daily Beater", "cost": 2000.0, "income": 1.15, "speed": 1.05, "style": 1.1, "move": "drift", "color": Color(0.45, 0.60, 0.70), "livery": "plain", "rarity": "regular"},
	{"name": "Street S13", "cost": 5000.0, "income": 1.3, "speed": 1.12, "style": 1.4, "move": "spin", "color": Color(0.25, 0.55, 0.95), "livery": "stripe", "rarity": "regular"},
	# RARE — income + speed
	{"name": "Drift AE86", "cost": 75000.0, "income": 1.7, "speed": 1.25, "style": 2.0, "move": "reverse", "color": Color(0.95, 0.95, 0.92), "livery": "twotone", "rarity": "rare"},
	{"name": "Turbo FC", "cost": 200000.0, "income": 1.9, "speed": 1.32, "style": 2.2, "move": "spin", "color": Color(0.90, 0.55, 0.20), "livery": "stripe", "rarity": "rare"},
	{"name": "Grip R32", "cost": 400000.0, "income": 2.0, "speed": 1.38, "style": 2.4, "move": "reverse", "color": Color(0.30, 0.35, 0.45), "livery": "number", "rarity": "rare"},
	# EXOTIC — income + style (faster HEAT)
	{"name": "Pro FD3S", "cost": 800000.0, "income": 2.2, "speed": 1.4, "style": 2.8, "move": "wall", "color": Color(0.95, 0.30, 0.25), "livery": "number", "rarity": "exotic"},
	{"name": "Carbon Supra", "cost": 2000000.0, "income": 2.5, "speed": 1.45, "style": 3.2, "move": "spin", "color": Color(0.20, 0.20, 0.22), "livery": "stripe", "rarity": "exotic"},
	{"name": "Widebody NSX", "cost": 4000000.0, "income": 2.7, "speed": 1.5, "style": 3.5, "move": "reverse", "color": Color(0.95, 0.75, 0.20), "livery": "twotone", "rarity": "exotic"},
	# LEGENDARY — everything, unique moves
	{"name": "Legend R34", "cost": 8000000.0, "income": 3.0, "speed": 1.6, "style": 4.0, "move": "spin", "color": Color(0.35, 0.45, 0.95), "livery": "number", "rarity": "legendary"},
	{"name": "Midnight S15", "cost": 15000000.0, "income": 3.5, "speed": 1.7, "style": 4.5, "move": "wall", "color": Color(0.15, 0.10, 0.35), "livery": "stripe", "rarity": "legendary"},
	{"name": "Godzilla R35", "cost": 30000000.0, "income": 4.0, "speed": 1.8, "style": 5.0, "move": "spin", "color": Color(0.90, 0.90, 0.92), "livery": "number", "rarity": "legendary"},
]

const RARITY_COLORS := {
	"regular": Color(0.60, 0.62, 0.65),
	"rare": Color(0.65, 0.40, 0.95),
	"exotic": Color(1.0, 0.75, 0.25),
	"legendary": Color(1.0, 0.35, 0.45),
}

# Achievements: {name, desc, kind, target, bonus}
# kind: "lifetime" (earn X lifetime), "owned" (own X of generator idx),
#       "mechanics" (hire X), "upgrades" (buy X), "prestige" (prestige X times)
const ACHIEVEMENTS := [
	{"name": "First Dollar", "desc": "Earn $100 lifetime", "kind": "lifetime", "target": 100.0, "gen": -1, "bonus": 1.02},
	{"name": "Grease Monkey", "desc": "Own 5 Oil Change Bays", "kind": "owned", "target": 5.0, "gen": 0, "bonus": 1.02},
	{"name": "Getting Serious", "desc": "Earn $10K lifetime", "kind": "lifetime", "target": 10000.0, "gen": -1, "bonus": 1.03},
	{"name": "Crew Up", "desc": "Hire 1 mechanic", "kind": "mechanics", "target": 1.0, "gen": -1, "bonus": 1.03},
	{"name": "Tire Empire", "desc": "Own 5 Tire Shops", "kind": "owned", "target": 5.0, "gen": 1, "bonus": 1.03},
	{"name": "Hundred Grand", "desc": "Earn $100K lifetime", "kind": "lifetime", "target": 100000.0, "gen": -1, "bonus": 1.05},
	{"name": "Full Crew", "desc": "Hire 3 mechanics", "kind": "mechanics", "target": 3.0, "gen": -1, "bonus": 1.05},
	{"name": "Paint It Up", "desc": "Own 5 Paint Booths", "kind": "owned", "target": 5.0, "gen": 2, "bonus": 1.05},
	{"name": "Millionaire", "desc": "Earn $1M lifetime", "kind": "lifetime", "target": 1000000.0, "gen": -1, "bonus": 1.08},
	{"name": "Upgrade Happy", "desc": "Buy 5 global upgrades", "kind": "upgrades", "target": 5.0, "gen": -1, "bonus": 1.08},
	{"name": "Tuning Fork", "desc": "Own 5 Tuning Labs", "kind": "owned", "target": 5.0, "gen": 3, "bonus": 1.08},
	{"name": "Ten Million", "desc": "Earn $10M lifetime", "kind": "lifetime", "target": 10000000.0, "gen": -1, "bonus": 1.10},
	{"name": "Engine Room", "desc": "Own 3 Engine Build Rooms", "kind": "owned", "target": 3.0, "gen": 4, "bonus": 1.10},
	{"name": "Drift Legend", "desc": "Own 2 Drift Contract Boards", "kind": "owned", "target": 2.0, "gen": 5, "bonus": 1.15},
	{"name": "Franchised", "desc": "Franchise (prestige) once", "kind": "prestige", "target": 1.0, "gen": -1, "bonus": 1.15},
]

static func bulk_cost(base: float, owned: int, n: int) -> float:
	# total cost to buy n more when you own `owned`
	var total := 0.0
	for i in range(n):
		total += base * pow(COST_GROWTH, owned + i)
	return total

static func max_affordable(base: float, owned: int, cash: float) -> int:
	# how many can you buy with cash (cap at 1000 per click for sanity)
	var n := 0
	var c := cash
	while n < 1000:
		var price := base * pow(COST_GROWTH, owned + n)
		if price > c:
			break
		c -= price
		n += 1
	return n

static func milestone_mult(owned: int) -> float:
	var m := 1.0
	for ms in [25, 50, 100, 200, 400]:
		if owned >= ms:
			m *= MILESTONE_BONUS
	return m

static func payout_per_cycle(gen_idx: int, owned: int, global_mult: float, prestige_mult: float) -> float:
	if owned <= 0:
		return 0.0
	var g: Dictionary = GENERATORS[gen_idx]
	var base: float = g["payout"]
	return base * owned * milestone_mult(owned) * global_mult * prestige_mult

static func income_per_sec(gen_idx: int, owned: int, global_mult: float, prestige_mult: float) -> float:
	var g: Dictionary = GENERATORS[gen_idx]
	var t: float = g["time"]
	if t <= 0.0:
		return 0.0
	return payout_per_cycle(gen_idx, owned, global_mult, prestige_mult) / t
