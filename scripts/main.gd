extends Node2D
## Idle Garage — main game controller.

const SAVE_PATH := "user://idle_garage.save"

var cash := 0.0
var lifetime := 0.0  # lifetime earnings (this prestige)
var total_earned := 0.0  # all-time (for achievements)
var owned := [1, 0, 0, 0, 0, 0]  # per generator (start with 1 oil bay!)
var progress := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]  # 0..1 bar progress
var mechanics := [false, false, false, false, false, false]
var upgrades_bought := []  # indices into Economy.UPGRADES
var stars := 0  # prestige: reputation stars
var bulk := 1  # 1, 10, 100, -1 (MAX)
var start_time := 0

var _save_t := 0.0
var _ui: CanvasLayer

func _ready() -> void:
	start_time = Time.get_unix_time_from_system()
	_load()
	_calc_offline()
	_ui = preload("res://scripts/ui.gd").new()
	_ui.game = self
	add_child(_ui)
	_ui.build()
	_ui.refresh_all()
	if not _ui_pending_offline.is_empty():
		_ui.show_offline_popup(float(_ui_pending_offline[0]), float(_ui_pending_offline[1]))
		_ui_pending_offline = []

func _process(dt: float) -> void:
	# clamp dt (tab back after hours shouldn't simulate frame-by-frame)
	dt = minf(dt, 1.0)
	var gmult := global_mult()
	var pmult := prestige_mult()
	for i in range(6):
		if owned[i] <= 0:
			continue
		var g: Dictionary = Economy.GENERATORS[i]
		var t: float = g["time"]
		# bays auto-run once owned — true idle, no tapping needed
		progress[i] += dt / t
		if progress[i] >= 1.0:
			progress[i] = 0.0
			var pay := Economy.payout_per_cycle(i, owned[i], gmult, pmult) * bay_mult(i)
			earn(pay)
			_ui.float_text(i, pay)
	_ui.tick(dt)
	# autosave every 15s
	_save_t += dt
	if _save_t >= 15.0:
		_save_t = 0.0
		_save()

func earn(v: float) -> void:
	cash += v
	lifetime += v
	total_earned += v

func spend(v: float) -> bool:
	if cash < v:
		return false
	cash -= v
	return true

func global_mult() -> float:
	var m := 1.0
	for u in upgrades_bought:
		m *= float(Economy.UPGRADES[u]["mult"])
	return m

func prestige_mult() -> float:
	return 1.0 + float(stars) * 0.10

func bay_mult(i: int) -> float:
	# mechanic hired = +50% income for their bay
	return 1.5 if mechanics[i] else 1.0

func income_per_sec() -> float:
	var total := 0.0
	var gm := global_mult()
	var pm := prestige_mult()
	for i in range(6):
		total += Economy.income_per_sec(i, owned[i], gm, pm) * bay_mult(i)
	return total

func buy_generator(i: int) -> void:
	var g: Dictionary = Economy.GENERATORS[i]
	var base: float = g["cost"]
	var n := bulk if bulk > 0 else Economy.max_affordable(base, owned[i], cash)
	if n <= 0:
		return
	var cost := Economy.bulk_cost(base, owned[i], n)
	if spend(cost):
		owned[i] += n
		_ui.refresh_all()
		_save()

func buy_mechanic(i: int) -> void:
	if mechanics[i]:
		return
	var cost: float = Economy.MECHANICS[i]["cost"]
	if spend(cost):
		mechanics[i] = true
		_ui.refresh_all()
		_save()

func buy_upgrade(u: int) -> void:
	if u in upgrades_bought:
		return
	var cost: float = Economy.UPGRADES[u]["cost"]
	if spend(cost):
		upgrades_bought.append(u)
		_ui.refresh_all()
		_save()

func do_prestige() -> void:
	# franchise: reset for reputation stars
	var new_stars := int(lifetime / 10000000.0)
	if new_stars <= 0:
		return
	stars += new_stars
	cash = 0.0
	lifetime = 0.0
	owned = [1, 0, 0, 0, 0, 0]
	progress = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	mechanics = [false, false, false, false, false, false]
	upgrades_bought = []
	_ui.refresh_all()
	_save()

func _save() -> void:
	var d := {
		"cash": cash, "lifetime": lifetime, "total": total_earned,
		"owned": owned, "mechanics": mechanics, "upgrades": upgrades_bought,
		"stars": stars, "time": Time.get_unix_time_from_system(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_var(d)
		f.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var d: Dictionary = f.get_var()
	f.close()
	cash = float(d.get("cash", 0.0))
	lifetime = float(d.get("lifetime", 0.0))
	total_earned = float(d.get("total", 0.0))
	var o: Array = d.get("owned", [0, 0, 0, 0, 0, 0])
	for i in range(6):
		owned[i] = int(o[i]) if i < o.size() else 0
	var m: Array = d.get("mechanics", [false, false, false, false, false, false])
	for i in range(6):
		mechanics[i] = bool(m[i]) if i < m.size() else false
	upgrades_bought = d.get("upgrades", [])
	stars = int(d.get("stars", 0))
	_last_time = float(d.get("time", 0.0))
	# migration: old saves started with 0 bays and $0 (soft-locked)
	var total_owned := 0
	for i in range(6):
		total_owned += owned[i]
	if total_owned == 0:
		owned[0] = 1

var _last_time := 0.0

func _calc_offline() -> void:
	# welcome-back earnings: income/sec * seconds away, capped at 8h
	if _last_time <= 0.0:
		return
	var away := Time.get_unix_time_from_system() - _last_time
	if away < 60.0:
		return  # less than a minute, skip the popup
	away = minf(away, 8.0 * 3600.0)
	var gained := income_per_sec() * away
	if gained > 0.0:
		earn(gained)
		_ui_pending_offline = [gained, away]

var _ui_pending_offline := []
