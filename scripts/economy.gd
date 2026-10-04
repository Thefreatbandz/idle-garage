class_name Economy
extends RefCounted
## Generator definitions and cost/payout math for Idle Garage.

# [name, icon, base_cost, base_payout, base_time_s, unlock_at_lifetime]
const GENERATORS := [
	{"name": "Oil Change Bay", "icon": "OIL", "cost": 25.0, "payout": 25.0, "time": 3.0, "unlock": 0.0},
	{"name": "Tire Shop", "icon": "TIRE", "cost": 150.0, "payout": 150.0, "time": 8.0, "unlock": 500.0},
	{"name": "Paint Booth", "icon": "PAINT", "cost": 1200.0, "payout": 800.0, "time": 20.0, "unlock": 5000.0},
	{"name": "Tuning Lab", "icon": "TUNE", "cost": 8000.0, "payout": 4000.0, "time": 45.0, "unlock": 40000.0},
	{"name": "Engine Build Room", "icon": "ENGINE", "cost": 60000.0, "payout": 25000.0, "time": 120.0, "unlock": 300000.0},
	{"name": "Drift Contract Board", "icon": "DRIFT", "cost": 400000.0, "payout": 150000.0, "time": 300.0, "unlock": 2000000.0},
	{"name": "Detailing Studio", "icon": "SHINE", "cost": 2500000.0, "payout": 800000.0, "time": 600.0, "unlock": 12000000.0},
	{"name": "Dyno Room", "icon": "DYNO", "cost": 15000000.0, "payout": 4000000.0, "time": 1200.0, "unlock": 80000000.0},
	{"name": "Wind Tunnel", "icon": "AERO", "cost": 80000000.0, "payout": 25000000.0, "time": 2400.0, "unlock": 500000000.0},
	{"name": "Engine Dyno Lab", "icon": "LAB", "cost": 400000000.0, "payout": 120000000.0, "time": 4800.0, "unlock": 2000000000.0},
]

# Mechanics (managers): one per generator [name, cost]
const MECHANICS := [
	{"name": "Marco", "cost": 150.0},
	{"name": "Lena", "cost": 1200.0},
	{"name": "Big D", "cost": 9000.0},
	{"name": "Yuki", "cost": 60000.0},
	{"name": "Rosa", "cost": 400000.0},
	{"name": "Ghost", "cost": 2500000.0},
	{"name": "Vex", "cost": 15000000.0},
	{"name": "Nova", "cost": 90000000.0},
	{"name": "Aero", "cost": 500000000.0},
	{"name": "Titan", "cost": 2500000000.0},
]

# Sponsors: signable contracts {name, desc, bonus_type, bonus_target, bonus_mult, unlock_type, unlock_val}
# bonus_type: "bay" (specific bay), "all" (all income), "style" (style gain)
# unlock_type: "cars" (total cars), "bay" (bay index owned), "track" (track index owned), "rarity" (min rarity owned)
const SPONSORS := [
	{"name": "Grip Tire Co.", "desc": "+25% Tire Shop", "bonus_type": "bay", "bonus_target": 1, "bonus_mult": 1.25, "unlock_type": "cars", "unlock_val": 2},
	{"name": "Octane Energy", "desc": "+15% style gain", "bonus_type": "style", "bonus_target": -1, "bonus_mult": 1.15, "unlock_type": "cars", "unlock_val": 5},
	{"name": "Apex Parts", "desc": "+20% Tuning Lab", "bonus_type": "bay", "bonus_target": 3, "bonus_mult": 1.20, "unlock_type": "bay", "unlock_val": 3},
	{"name": "Drift King Media", "desc": "+10% all income", "bonus_type": "all", "bonus_target": -1, "bonus_mult": 1.10, "unlock_type": "rarity", "unlock_val": 1},
	{"name": "Nitrous Express", "desc": "+30% Engine Room", "bonus_type": "bay", "bonus_target": 4, "bonus_mult": 1.30, "unlock_type": "bay", "unlock_val": 4},
	{"name": "Sunset Auto", "desc": "+15% Paint Booth", "bonus_type": "bay", "bonus_target": 2, "bonus_mult": 1.15, "unlock_type": "cars", "unlock_val": 3},
	{"name": "Pro Circuit", "desc": "+20% Drift Contracts", "bonus_type": "bay", "bonus_target": 5, "bonus_mult": 1.20, "unlock_type": "track", "unlock_val": 1},
	{"name": "Elite Motors", "desc": "+10% all income", "bonus_type": "all", "bonus_target": -1, "bonus_mult": 1.10, "unlock_type": "rarity", "unlock_val": 2},
	{"name": "Champion Oil", "desc": "+25% Oil Bay", "bonus_type": "bay", "bonus_target": 0, "bonus_mult": 1.25, "unlock_type": "cars", "unlock_val": 8},
	{"name": "Legend Racing", "desc": "+25% all income", "bonus_type": "all", "bonus_target": -1, "bonus_mult": 1.25, "unlock_type": "rarity", "unlock_val": 3},
]

# Daily rewards: 7-day streak calendar {day, type, amount/car_idx, label}
# type: "cash", "car", "style"
const DAILY_REWARDS := [
	{"day": 1, "type": "cash", "amount": 1000.0, "label": "$1K"},
	{"day": 2, "type": "cash", "amount": 5000.0, "label": "$5K"},
	{"day": 3, "type": "car", "car": 3, "label": "City Coupe"},
	{"day": 4, "type": "cash", "amount": 25000.0, "label": "$25K"},
	{"day": 5, "type": "car", "car": 8, "label": "Apex S2000"},
	{"day": 6, "type": "cash", "amount": 100000.0, "label": "$100K"},
	{"day": 7, "type": "cash", "amount": 500000.0, "label": "$500K"},
]

# Daily missions: {id, label, target, reward_cash}
const MISSIONS := [
	{"id": "earn", "label": "Earn $%s", "target": 50000.0, "reward": 10000.0},
	{"id": "cars", "label": "Buy %d car", "target": 1.0, "reward": 15000.0},
	{"id": "heat", "label": "Trigger HEAT %dx", "target": 2.0, "reward": 20000.0},
	{"id": "bays", "label": "Buy %d bays", "target": 5.0, "reward": 12000.0},
]
# shapes: 0=Ebisu peanut, 1=Meihan paperclip, 2=Nikko triangle, 3=Long Beach angular, 4=Irwindale ellipse
const TRACKS := [
	{"name": "Ebisu Nights", "cost": 0.0, "bonus": 1.0, "shape": 0,
		"curb_a": Color(0.85, 0.20, 0.20), "curb_b": Color(0.92, 0.92, 0.92),
		"asphalt": Color(0.15, 0.15, 0.17), "asphalt_hi": Color(0.21, 0.21, 0.24),
		"bg": Color(0.08, 0.07, 0.10), "glow": Color(0, 0, 0, 0)},
	{"name": "Meihan Wall", "cost": 1500000.0, "bonus": 1.10, "shape": 1,
		"curb_a": Color(0.90, 0.75, 0.20), "curb_b": Color(0.20, 0.20, 0.22),
		"asphalt": Color(0.16, 0.16, 0.17), "asphalt_hi": Color(0.22, 0.22, 0.24),
		"bg": Color(0.09, 0.08, 0.09), "glow": Color(0.9, 0.75, 0.2, 0.15)},
	{"name": "Nikko Tech", "cost": 8000000.0, "bonus": 1.15, "shape": 2,
		"curb_a": Color(0.92, 0.92, 0.92), "curb_b": Color(0.85, 0.20, 0.20),
		"asphalt": Color(0.14, 0.15, 0.14), "asphalt_hi": Color(0.20, 0.21, 0.20),
		"bg": Color(0.07, 0.09, 0.07), "glow": Color(0, 0, 0, 0)},
	{"name": "Long Beach", "cost": 40000000.0, "bonus": 1.20, "shape": 3,
		"curb_a": Color(0.30, 0.55, 0.95), "curb_b": Color(0.92, 0.92, 0.92),
		"asphalt": Color(0.13, 0.13, 0.15), "asphalt_hi": Color(0.19, 0.19, 0.22),
		"bg": Color(0.07, 0.08, 0.10), "glow": Color(0.3, 0.55, 0.95, 0.18)},
	{"name": "Irwindale", "cost": 200000000.0, "bonus": 1.30, "shape": 4,
		"curb_a": Color(0.92, 0.92, 0.92), "curb_b": Color(0.85, 0.20, 0.20),
		"asphalt": Color(0.10, 0.11, 0.15), "asphalt_hi": Color(0.15, 0.16, 0.21),
		"bg": Color(0.03, 0.03, 0.07), "glow": Color(0.5, 0.7, 1.0, 0.25)},
	{"name": "Fuji Speedway", "cost": 500000000.0, "bonus": 1.40, "shape": 5,
		"curb_a": Color(0.90, 0.90, 0.90), "curb_b": Color(0.20, 0.30, 0.80),
		"asphalt": Color(0.13, 0.14, 0.16), "asphalt_hi": Color(0.19, 0.20, 0.23),
		"bg": Color(0.06, 0.08, 0.12), "glow": Color(0.2, 0.3, 0.8, 0.15)},
	{"name": "Suzuka East", "cost": 1000000000.0, "bonus": 1.50, "shape": 6,
		"curb_a": Color(0.95, 0.95, 0.95), "curb_b": Color(0.15, 0.45, 0.25),
		"asphalt": Color(0.14, 0.14, 0.15), "asphalt_hi": Color(0.20, 0.20, 0.22),
		"bg": Color(0.05, 0.08, 0.06), "glow": Color(0, 0, 0, 0)},
	{"name": "Monza", "cost": 2500000000.0, "bonus": 1.65, "shape": 7,
		"curb_a": Color(0.85, 0.20, 0.20), "curb_b": Color(0.95, 0.95, 0.95),
		"asphalt": Color(0.15, 0.13, 0.12), "asphalt_hi": Color(0.21, 0.19, 0.18),
		"bg": Color(0.08, 0.07, 0.06), "glow": Color(0.85, 0.2, 0.2, 0.12)},
]

# Global upgrades: [name, desc, cost, mult] — mult applies to all income
const POWERS := [
	{"name": "Nitro Boost", "desc": "2x income for 60s", "cooldown": 300.0, "duration": 60.0},
	{"name": "Cash Injection", "desc": "Instant 10 min of income", "cooldown": 600.0, "duration": 0.0},
	{"name": "HEAT Rush", "desc": "Instantly trigger HEAT", "cooldown": 240.0, "duration": 0.0},
]

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
	{"name": "Carbon Lab", "desc": "+60% all income", "cost": 25000000.0, "mult": 1.6},
	{"name": "Telemetry Rig", "desc": "+75% all income", "cost": 120000000.0, "mult": 1.75},
	{"name": "Aero Tunnel", "desc": "+100% all income", "cost": 600000000.0, "mult": 2.0},
	{"name": "Works Team", "desc": "+125% all income", "cost": 3000000000.0, "mult": 2.25},
	{"name": "Hall of Fame", "desc": "+200% all income", "cost": 20000000000.0, "mult": 3.0},
]

const COST_GROWTH := 1.15
const MILESTONE_BONUS := 2.0  # x2 at 25/50/100/200 owned

# Showroom cars: {name, cost, income (mult), speed (mult), style (pts/sec), move, color, livery, rarity}
# rarity: "regular" (+income), "rare" (+income/speed), "exotic" (+income/style),
# Car parts: per-car upgrades (Engine/Tires/Aero, 10 levels each)
# Each level: +8% to its stat. Cost scales with car tier + part level.
const PARTS := [
	{"name": "Engine", "desc": "+8% income per level", "stat": "income", "base_cost": 5000.0},
	{"name": "Tires", "desc": "+8% speed per level", "stat": "speed", "base_cost": 3000.0},
	{"name": "Aero", "desc": "+8% style per level", "stat": "style", "base_cost": 4000.0},
]
const PART_MAX_LEVEL := 10

# Decal shop: buyable styles + custom colors
const DECALS := [
	{"name": "Racing Stripe", "cost": 10000.0, "style": "stripe"},
	{"name": "Number Roundel", "cost": 25000.0, "style": "number"},
	{"name": "Flames", "cost": 100000.0, "style": "flames"},
	{"name": "Lightning", "cost": 250000.0, "style": "lightning"},
	{"name": "Checker", "cost": 500000.0, "style": "checker"},
	{"name": "Crown", "cost": 1000000.0, "style": "crown"},
]

#         "legendary" (+income/speed/style, unique moves)
# livery: "plain", "stripe", "number", "twotone"
const CARS := [
	# REGULAR — honest income
	{"name": "Rust Bucket", "cost": 0.0, "income": 1.0, "speed": 1.0, "style": 1.0, "move": "drift", "color": Color(0.55, 0.55, 0.58), "livery": "plain", "sprite": "res://assets/cars/car_00.png", "rarity": "regular"},
	{"name": "Daily Beater", "cost": 2000.0, "income": 1.15, "speed": 1.05, "style": 1.1, "move": "drift", "color": Color(0.45, 0.60, 0.70), "livery": "plain", "sprite": "res://assets/cars/car_01.png", "rarity": "regular"},
	{"name": "Street S13", "cost": 5000.0, "income": 1.3, "speed": 1.12, "style": 1.4, "move": "spin", "color": Color(0.25, 0.55, 0.95), "livery": "stripe", "sprite": "res://assets/cars/car_02.png", "rarity": "regular"},
	{"name": "City Coupe", "cost": 12000.0, "income": 1.22, "speed": 1.08, "style": 1.2, "move": "drift", "color": Color(0.35, 0.70, 0.40), "livery": "plain", "sprite": "res://assets/cars/car_12.png", "rarity": "regular"},
	{"name": "Night Runner", "cost": 25000.0, "income": 1.25, "speed": 1.10, "style": 1.3, "move": "drift", "color": Color(0.85, 0.75, 0.25), "livery": "plain", "sprite": "res://assets/cars/car_13.png", "rarity": "regular"},
	# RARE — income + speed
	{"name": "Drift AE86", "cost": 75000.0, "income": 1.7, "speed": 1.25, "style": 2.0, "move": "reverse", "color": Color(0.95, 0.95, 0.92), "livery": "twotone", "sprite": "res://assets/cars/car_03.png", "rarity": "rare"},
	{"name": "Turbo FC", "cost": 200000.0, "income": 1.9, "speed": 1.32, "style": 2.2, "move": "spin", "color": Color(0.90, 0.55, 0.20), "livery": "stripe", "sprite": "res://assets/cars/car_04.png", "rarity": "rare"},
	{"name": "Grip R32", "cost": 400000.0, "income": 2.0, "speed": 1.38, "style": 2.4, "move": "reverse", "color": Color(0.30, 0.35, 0.45), "livery": "number", "sprite": "res://assets/cars/car_05.png", "rarity": "rare"},
	{"name": "Apex S2000", "cost": 150000.0, "income": 1.8, "speed": 1.30, "style": 2.1, "move": "spin", "color": Color(0.30, 0.50, 0.90), "livery": "stripe", "sprite": "res://assets/cars/car_14.png", "rarity": "rare"},
	{"name": "Boosted 240", "cost": 300000.0, "income": 1.95, "speed": 1.35, "style": 2.3, "move": "drift", "color": Color(0.90, 0.35, 0.30), "livery": "stripe", "sprite": "res://assets/cars/car_15.png", "rarity": "rare"},
	# EXOTIC — income + style (faster HEAT)
	{"name": "Pro FD3S", "cost": 5000000.0, "income": 2.2, "speed": 1.4, "style": 2.8, "move": "wall", "color": Color(0.95, 0.30, 0.25), "livery": "number", "sprite": "res://assets/cars/car_06.png", "rarity": "exotic"},
	{"name": "Carbon Supra", "cost": 15000000.0, "income": 2.5, "speed": 1.45, "style": 3.2, "move": "spin", "color": Color(0.20, 0.20, 0.22), "livery": "stripe", "sprite": "res://assets/cars/car_07.png", "rarity": "exotic"},
	{"name": "Widebody NSX", "cost": 30000000.0, "income": 2.7, "speed": 1.5, "style": 3.5, "move": "reverse", "color": Color(0.95, 0.75, 0.20), "livery": "twotone", "sprite": "res://assets/cars/car_08.png", "rarity": "exotic"},
	{"name": "Phantom GT", "cost": 10000000.0, "income": 2.4, "speed": 1.42, "style": 3.0, "move": "spin", "color": Color(0.35, 0.65, 0.40), "livery": "number", "sprite": "res://assets/cars/car_16.png", "rarity": "exotic"},
	{"name": "Velocity Z", "cost": 25000000.0, "income": 2.6, "speed": 1.48, "style": 3.3, "move": "reverse", "color": Color(0.35, 0.50, 0.90), "livery": "twotone", "sprite": "res://assets/cars/car_17.png", "rarity": "exotic"},
	# LEGENDARY — everything, unique moves
	{"name": "Legend R34", "cost": 50000000.0, "income": 3.0, "speed": 1.6, "style": 4.0, "move": "spin", "color": Color(0.35, 0.45, 0.95), "livery": "number", "sprite": "res://assets/cars/car_09.png", "rarity": "legendary"},
	{"name": "Midnight S15", "cost": 120000000.0, "income": 3.5, "speed": 1.7, "style": 4.5, "move": "wall", "color": Color(0.15, 0.10, 0.35), "livery": "stripe", "sprite": "res://assets/cars/car_10.png", "rarity": "legendary"},
	{"name": "Godzilla R35", "cost": 300000000.0, "income": 4.0, "speed": 1.8, "style": 5.0, "move": "spin", "color": Color(0.90, 0.90, 0.92), "livery": "number", "sprite": "res://assets/cars/car_11.png", "rarity": "legendary"},
	{"name": "Emperor EVO", "cost": 80000000.0, "income": 3.3, "speed": 1.65, "style": 4.3, "move": "wall", "color": Color(0.85, 0.75, 0.25), "livery": "stripe", "sprite": "res://assets/cars/car_18.png", "rarity": "legendary"},
	{"name": "Titan GTR", "cost": 200000000.0, "income": 3.8, "speed": 1.75, "style": 4.8, "move": "spin", "color": Color(0.90, 0.35, 0.30), "livery": "number", "sprite": "res://assets/cars/car_19.png", "rarity": "legendary"},
	# MYTHIC — endgame, massive bonuses
	{"name": "Neon Phantom", "cost": 500000000.0, "income": 4.5, "speed": 1.9, "style": 6.0, "move": "spin", "color": Color(0.70, 0.20, 0.90), "livery": "number", "sprite": "res://assets/cars/car_12.png", "rarity": "mythic"},
	{"name": "Solar Apex", "cost": 800000000.0, "income": 5.0, "speed": 2.0, "style": 6.5, "move": "wall", "color": Color(1.0, 0.60, 0.10), "livery": "stripe", "sprite": "res://assets/cars/car_13.png", "rarity": "mythic"},
	{"name": "Void Runner", "cost": 1200000000.0, "income": 5.5, "speed": 2.1, "style": 7.0, "move": "spin", "color": Color(0.10, 0.10, 0.15), "livery": "number", "sprite": "res://assets/cars/car_14.png", "rarity": "mythic"},
	{"name": "Chrome Storm", "cost": 1800000000.0, "income": 6.0, "speed": 2.2, "style": 7.5, "move": "wall", "color": Color(0.85, 0.90, 0.95), "livery": "stripe", "sprite": "res://assets/cars/car_15.png", "rarity": "mythic"},
	{"name": "Eternal Drift", "cost": 2500000000.0, "income": 7.0, "speed": 2.3, "style": 8.0, "move": "spin", "color": Color(0.95, 0.30, 0.50), "livery": "number", "sprite": "res://assets/cars/car_16.png", "rarity": "mythic"},
]

const RARITY_COLORS := {
	"regular": Color(0.60, 0.62, 0.65),
	"rare": Color(0.65, 0.40, 0.95),
	"exotic": Color(1.0, 0.75, 0.25),
	"legendary": Color(1.0, 0.35, 0.45),
	"mythic": Color(0.70, 0.20, 1.0),
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
	{"name": "Mythic Hunter", "desc": "Own a Mythic car", "kind": "mycar", "target": 1.0, "gen": -1, "bonus": 1.20},
	{"name": "Track Master", "desc": "Own 5 tracks", "kind": "tracks", "target": 5.0, "gen": -1, "bonus": 1.20},
	{"name": "Wind Tunnel Vision", "desc": "Own a Wind Tunnel", "kind": "owned", "target": 1.0, "gen": 8, "bonus": 1.15},
	{"name": "Full Garage", "desc": "Own 10 bays of every type", "kind": "bays10", "target": 1.0, "gen": -1, "bonus": 1.25},
	{"name": "Sponsor Magnet", "desc": "Have 3 sponsors active", "kind": "sponsors", "target": 3.0, "gen": -1, "bonus": 1.15},
	{"name": "HEAT Wave", "desc": "Trigger HEAT 25 times", "kind": "heat", "target": 25.0, "gen": -1, "bonus": 1.15},
	{"name": "Billionaire", "desc": "Earn $1B lifetime", "kind": "lifetime", "target": 1000000000.0, "gen": -1, "bonus": 1.30},
	{"name": "Car Collector", "desc": "Own 20 cars", "kind": "cars", "target": 20.0, "gen": -1, "bonus": 1.25},
	{"name": "Empire Builder", "desc": "Reach Motorsport Empire", "kind": "empire", "target": 1.0, "gen": -1, "bonus": 1.30},
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
