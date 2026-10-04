extends Node2D
## Idle Garage — main game controller.

const SAVE_PATH := "user://idle_garage.save"

var cash := 0.0
var lifetime := 0.0  # lifetime earnings (this prestige)
var total_earned := 0.0  # all-time (for achievements)
var owned := [1, 0, 0, 0, 0, 0, 0, 0]  # per generator (start with 1 oil bay!)
var progress := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]  # 0..1 bar progress
var mechanics := [false, false, false, false, false, false, false, false]
var upgrades_bought := []  # indices into Economy.UPGRADES
var stars := 0  # prestige: reputation stars
var prestige_count := 0
var achievements := []  # unlocked indices into Economy.ACHIEVEMENTS
var cars_owned := [true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
var cars_equipped := [0, 0, 0, 0, 0, 0, 0, 0]  # car index per generator bay
var tracks_owned := [true, false, false, false, false]
var track_selected := 0  # index into Economy.TRACKS
var style_meter := 0.0  # 0..100, fills from drifting
var heat_timer := 0.0  # >0 = 2x HEAT bonus active
var bulk := 1  # 1, 10, 100, -1 (MAX)
var start_time := 0
# daily rewards
var last_daily := ""  # YYYY-MM-DD of last claim
var daily_streak := 0  # 1..7
# missions (daily)
var mission_date := ""  # YYYY-MM-DD
var missions_done := [false, false, false, false]
var mission_prog := [0.0, 0.0, 0.0, 0.0]
# sponsors (v10): up to 3 active
var sponsors_active := [-1, -1, -1]

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
	# show any achievement popups earned while offline
	for ai in _pending_ach_popups:
		var a: Dictionary = Economy.ACHIEVEMENTS[ai]
		_ui.achievement_popup(String(a["name"]), float(a["bonus"]))
	_pending_ach_popups = []
	# daily rewards + missions check
	_check_daily()

func _today_str() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]

func _check_daily() -> void:
	var today := _today_str()
	# missions reset
	if mission_date != today:
		mission_date = today
		missions_done = [false, false, false, false]
		mission_prog = [0.0, 0.0, 0.0, 0.0]
		_save()
	# daily reward
	if last_daily == today:
		return  # already claimed
	var yesterday := _today_str_offset(-1)
	if last_daily == yesterday:
		daily_streak = mini(daily_streak + 1, 7)
	else:
		daily_streak = 1  # streak broken or first time
	_ui.show_daily_popup(daily_streak)

func _today_str_offset(days: int) -> String:
	var t := Time.get_unix_time_from_system() + days * 86400
	var d := Time.get_date_dict_from_unix_time(t)
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]

func claim_daily() -> void:
	var r: Dictionary = Economy.DAILY_REWARDS[daily_streak - 1]
	match String(r["type"]):
		"cash":
			cash += float(r["amount"])
			total_earned += float(r["amount"])
		"car":
			var ci := int(r["car"])
			cars_owned[ci] = true
		"style":
			style_meter = minf(style_meter + float(r["amount"]), 100.0)
	last_daily = _today_str()
	_ui.refresh_all()
	_save()

# sponsors
func sponsor_unlocked(si: int) -> bool:
	var s: Dictionary = Economy.SPONSORS[si]
	match String(s["unlock_type"]):
		"cars":
			var n := 0
			for c in cars_owned:
				if c:
					n += 1
			return n >= int(s["unlock_val"])
		"bay":
			return owned[int(s["unlock_val"])] > 0
		"track":
			return tracks_owned[int(s["unlock_val"])]
		"rarity":
			# rarity index: 0=regular, 1=rare, 2=exotic, 3=legendary
			var need := int(s["unlock_val"])
			for ci in range(Economy.CARS.size()):
				if cars_owned[ci]:
					var r: String = Economy.CARS[ci]["rarity"]
					var ri := 0
					match r:
						"rare": ri = 1
						"exotic": ri = 2
						"legendary": ri = 3
					if ri >= need:
						return true
			return false
	return false

func toggle_sponsor(si: int) -> void:
	if not sponsor_unlocked(si):
		return
	if si in sponsors_active:
		sponsors_active[sponsors_active.find(si)] = -1
	else:
		# fill first empty slot
		for i in range(3):
			if sponsors_active[i] == -1:
				sponsors_active[i] = si
				break
	_ui.refresh_all()
	_save()

func sponsor_bay_mult(bay: int) -> float:
	var m := 1.0
	for si in sponsors_active:
		if si < 0:
			continue
		var s: Dictionary = Economy.SPONSORS[si]
		if String(s["bonus_type"]) == "bay" and int(s["bonus_target"]) == bay:
			m *= float(s["bonus_mult"])
	return m

func sponsor_all_mult() -> float:
	var m := 1.0
	for si in sponsors_active:
		if si < 0:
			continue
		var s: Dictionary = Economy.SPONSORS[si]
		if String(s["bonus_type"]) == "all":
			m *= float(s["bonus_mult"])
	return m

func sponsor_style_mult() -> float:
	var m := 1.0
	for si in sponsors_active:
		if si < 0:
			continue
		var s: Dictionary = Economy.SPONSORS[si]
		if String(s["bonus_type"]) == "style":
			m *= float(s["bonus_mult"])
	return m

# missions
func mission_progress(id: String, amount: float) -> void:
	var mi := -1
	for i in range(Economy.MISSIONS.size()):
		if String(Economy.MISSIONS[i]["id"]) == id:
			mi = i
			break
	if mi < 0 or missions_done[mi]:
		return
	mission_prog[mi] += amount
	var target: float = Economy.MISSIONS[mi]["target"]
	if mission_prog[mi] >= target:
		missions_done[mi] = true
		cash += float(Economy.MISSIONS[mi]["reward"])
		total_earned += float(Economy.MISSIONS[mi]["reward"])
		if _ui:
			_ui.mission_popup(String(Economy.MISSIONS[mi]["label"]))
		_save()

func _process(dt: float) -> void:
	# clamp dt (tab back after hours shouldn't simulate frame-by-frame)
	dt = minf(dt, 1.0)
	var gmult := global_mult()
	var pmult := prestige_mult()
	for i in range(8):
		if owned[i] <= 0:
			continue
		var g: Dictionary = Economy.GENERATORS[i]
		var t: float = g["time"]
		# bays auto-run once owned — true idle, no tapping needed
		progress[i] += dt / t
		if progress[i] >= 1.0:
			progress[i] = 0.0
			var pay: float = Economy.payout_per_cycle(i, owned[i], gmult, pmult) * bay_mult(i) * heat_mult()
			earn(pay)
			_ui.float_text(i, pay)
	# style meter fills from equipped cars drifting; full = 30s 2x HEAT
	var style_rate := 0.0
	for i in range(8):
		if owned[i] > 0:
			var car: Dictionary = Economy.CARS[cars_equipped[i]]
			style_rate += float(car["style"])
	style_meter += style_rate * dt * 0.5 * sponsor_style_mult()
	if style_meter >= 100.0:
		style_meter = 0.0
		heat_timer = 30.0
		_ui.heat_popup()
		_ui.show_heat_tap()
		mission_progress("heat", 1.0)
	if heat_timer > 0.0:
		heat_timer -= dt
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
	mission_progress("earn", v)
	check_achievements()

func spend(v: float) -> bool:
	if cash < v:
		return false
	cash -= v
	return true

func global_mult() -> float:
	var m := 1.0
	for u in upgrades_bought:
		m *= float(Economy.UPGRADES[u]["mult"])
	m *= achievement_mult()
	return m

func achievement_mult() -> float:
	var m := 1.0
	for a in achievements:
		m *= float(Economy.ACHIEVEMENTS[a]["bonus"])
	return m

func check_achievements() -> void:
	var mech_count := 0
	for hired in mechanics:
		if hired:
			mech_count += 1
	for ai in range(Economy.ACHIEVEMENTS.size()):
		if ai in achievements:
			continue
		var a: Dictionary = Economy.ACHIEVEMENTS[ai]
		var done := false
		match String(a["kind"]):
			"lifetime":
				done = lifetime >= float(a["target"])
			"owned":
				done = owned[int(a["gen"])] >= int(a["target"])
			"mechanics":
				done = mech_count >= int(a["target"])
			"upgrades":
				done = upgrades_bought.size() >= int(a["target"])
			"prestige":
				done = prestige_count >= int(a["target"])
		if done:
			achievements.append(ai)
			if _ui:
				_ui.achievement_popup(String(a["name"]), float(a["bonus"]))
			else:
				_pending_ach_popups.append(ai)
	_save()

var _pending_ach_popups := []

func prestige_mult() -> float:
	return 1.0 + float(stars) * 0.10

func bay_mult(i: int) -> float:
	# mechanic hired = +50% income for their bay
	var m := 1.5 if mechanics[i] else 1.0
	# equipped car income mult
	var car: Dictionary = Economy.CARS[cars_equipped[i]]
	m *= float(car["income"])
	return m

func heat_mult() -> float:
	return 2.0 if heat_timer > 0.0 else 1.0

func income_per_sec() -> float:
	var total := 0.0
	var gm := global_mult()
	var pm := prestige_mult()
	var hm := heat_mult()
	var tm: float = Economy.TRACKS[track_selected]["bonus"]
	var sm := sponsor_all_mult()
	for i in range(8):
		total += Economy.income_per_sec(i, owned[i], gm, pm) * bay_mult(i) * hm * tm * sm * sponsor_bay_mult(i)
	return total

func buy_car(ci: int) -> void:
	if cars_owned[ci]:
		return
	var cost: float = Economy.CARS[ci]["cost"]
	if spend(cost):
		cars_owned[ci] = true
		mission_progress("cars", 1.0)
		_ui.refresh_all()
		_save()

func equip_car(bay: int, ci: int) -> void:
	if not cars_owned[ci]:
		return
	cars_equipped[bay] = ci
	_ui.refresh_all()
	_save()

func buy_track(ti: int) -> void:
	if tracks_owned[ti]:
		return
	var cost: float = Economy.TRACKS[ti]["cost"]
	if spend(cost):
		tracks_owned[ti] = true
		track_selected = ti
		_ui.refresh_all()
		_save()

func select_track(ti: int) -> void:
	if not tracks_owned[ti]:
		return
	track_selected = ti
	_ui.refresh_all()
	_save()

func buy_generator(i: int) -> void:
	var g: Dictionary = Economy.GENERATORS[i]
	var base: float = g["cost"]
	var n := bulk if bulk > 0 else Economy.max_affordable(base, owned[i], cash)
	if n <= 0:
		return
	var cost := Economy.bulk_cost(base, owned[i], n)
	if spend(cost):
		owned[i] += n
		mission_progress("bays", float(n))
		_ui.refresh_all()
		check_achievements()
		_save()

func buy_mechanic(i: int) -> void:
	if mechanics[i]:
		return
	var cost: float = Economy.MECHANICS[i]["cost"]
	if spend(cost):
		mechanics[i] = true
		_ui.refresh_all()
		check_achievements()
		_save()

func buy_upgrade(u: int) -> void:
	if u in upgrades_bought:
		return
	var cost: float = Economy.UPGRADES[u]["cost"]
	if spend(cost):
		upgrades_bought.append(u)
		_ui.refresh_all()
		check_achievements()
		_save()

func do_prestige() -> void:
	# franchise: reset for reputation stars
	var new_stars := int(lifetime / 10000000.0)
	if new_stars <= 0:
		return
	stars += new_stars
	prestige_count += 1
	cash = 0.0
	lifetime = 0.0
	owned = [1, 0, 0, 0, 0, 0]
	progress = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	mechanics = [false, false, false, false, false, false]
	upgrades_bought = []
	# achievements persist through prestige (they're the keeper)
	_ui.refresh_all()
	check_achievements()
	_save()

func _save() -> void:
	var d := {
		"cash": cash, "lifetime": lifetime, "total": total_earned,
		"owned": owned, "mechanics": mechanics, "upgrades": upgrades_bought,
		"stars": stars, "prestige_count": prestige_count,
		"achievements": achievements,
		"cars_owned": cars_owned, "cars_equipped": cars_equipped,
		"tracks_owned": tracks_owned, "track_selected": track_selected,
		"last_daily": last_daily, "daily_streak": daily_streak,
		"mission_date": mission_date, "missions_done": missions_done, "mission_prog": mission_prog,
		"sponsors_active": sponsors_active,
		"time": Time.get_unix_time_from_system(),
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
	for i in range(8):
		owned[i] = int(o[i]) if i < o.size() else 0
	var m: Array = d.get("mechanics", [false, false, false, false, false, false])
	for i in range(8):
		mechanics[i] = bool(m[i]) if i < m.size() else false
	upgrades_bought = d.get("upgrades", [])
	stars = int(d.get("stars", 0))
	prestige_count = int(d.get("prestige_count", 0))
	achievements = d.get("achievements", [])
	var co: Array = d.get("cars_owned", [true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false])
	for i in range(20):
		cars_owned[i] = bool(co[i]) if i < co.size() else (i == 0)
	var ce: Array = d.get("cars_equipped", [0, 0, 0, 0, 0, 0, 0, 0])
	for i in range(8):
		cars_equipped[i] = int(ce[i]) if i < ce.size() else 0
	var to: Array = d.get("tracks_owned", [true, false, false, false, false])
	for i in range(5):
		tracks_owned[i] = bool(to[i]) if i < to.size() else (i == 0)
	track_selected = int(d.get("track_selected", 0))
	if track_selected < 0 or track_selected >= 5:
		track_selected = 0
	last_daily = String(d.get("last_daily", ""))
	daily_streak = int(d.get("daily_streak", 0))
	mission_date = String(d.get("mission_date", ""))
	var md: Array = d.get("missions_done", [false, false, false, false])
	for i in range(4):
		missions_done[i] = bool(md[i]) if i < md.size() else false
	var mp: Array = d.get("mission_prog", [0.0, 0.0, 0.0, 0.0])
	for i in range(4):
		mission_prog[i] = float(mp[i]) if i < mp.size() else 0.0
	var sa: Array = d.get("sponsors_active", [-1, -1, -1])
	for i in range(3):
		sponsors_active[i] = int(sa[i]) if i < sa.size() else -1
	_last_time = float(d.get("time", 0.0))
	# migration: old saves started with 0 bays and $0 (soft-locked)
	var total_owned := 0
	for i in range(8):
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
