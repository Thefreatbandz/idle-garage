extends Control
## Live garage preview: drift track up top, service bays below.
## Each owned generator gets a car that cycles: TRACK -> PULL IN -> SERVICE -> PULL OUT.

var game  # main.gd

# track geometry (top area)
var _cx := 640.0
var _cy := 72.0
var _straight := 380.0
var _radius := 42.0
var _perimeter := 0.0

# bays (bottom area)
const BAY_Y := 158.0
const BAY_W := 170.0
const BAY_H := 52.0

var _cars := []  # per generator: {mode, track_t, speed, color, bay_t, service_t, pos}
var _smokes := []
var _coins := []  # {pos, life}
var _time := 0.0

const CAR_COLORS := [
	Color(0.95, 0.30, 0.25), Color(0.25, 0.55, 0.95), Color(0.95, 0.75, 0.25),
	Color(0.35, 0.90, 0.45), Color(0.90, 0.40, 0.80), Color(0.85, 0.85, 0.88),
]
const BAY_NAMES := ["OIL", "TIRE", "PAINT", "TUNE", "ENGINE", "DRIFT"]

# car modes
const M_TRACK := 0
const M_TO_BAY := 1
const M_BAY := 2
const M_TO_TRACK := 3

func _ready() -> void:
	_perimeter = 4.0 * _straight + 2.0 * PI * _radius
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(6):
		_cars.append({
			"mode": M_TRACK, "track_t": randf(),
			"speed": 0.10 + randf() * 0.04,
			"color": CAR_COLORS[i],
			"bay_t": 0.0, "service_t": 0.0,
			"pos": Vector2.ZERO, "angle": 0.0,
		})

func _bay_pos(i: int) -> Vector2:
	return Vector2(110.0 + i * 195.0, BAY_Y)

func _process(dt: float) -> void:
	_time += dt
	var boost := 1.0
	if game:
		boost = 1.0 + minf(game.income_per_sec() / 5000.0, 1.5)
	for i in range(6):
		var c: Dictionary = _cars[i]
		var owned := int(game.owned[i]) if game else 0
		if owned <= 0:
			continue
		match int(c["mode"]):
			M_TRACK:
				c["track_t"] = fmod(float(c["track_t"]) + float(c["speed"]) * boost * dt, 1.0)
				c["pos"] = _track_pos(float(c["track_t"]))
				c["angle"] = _track_angle(float(c["track_t"]))
				# randomly decide to pull in for service
				if randf() < dt * 0.15:
					c["mode"] = M_TO_BAY
					c["bay_t"] = 0.0
				# drift smoke
				if _in_drift_zone(float(c["track_t"])) and randf() < 0.4:
					_spawn_smoke(c["pos"])
			M_TO_BAY:
				c["bay_t"] = float(c["bay_t"]) + dt * 1.5
				var bp := _bay_pos(i)
				var tp: Vector2 = c["pos"]
				c["pos"] = tp.lerp(bp, minf(float(c["bay_t"]), 1.0))
				if float(c["bay_t"]) >= 1.0:
					c["mode"] = M_BAY
					c["service_t"] = 0.0
			M_BAY:
				c["service_t"] = float(c["service_t"]) + dt
				c["pos"] = _bay_pos(i) + Vector2(0, sin(_time * 10.0 + i) * 2.0)
				c["angle"] = lerpf(float(c["angle"]), 0.0, dt * 5.0)
				# service sparks
				if randf() < dt * 8.0:
					_spawn_spark(c["pos"])
				if float(c["service_t"]) > 2.5:
					c["mode"] = M_TO_TRACK
					c["bay_t"] = 0.0
					# coin burst when service done = payout visual
					_spawn_coins(_bay_pos(i))
			M_TO_TRACK:
				c["bay_t"] = float(c["bay_t"]) + dt * 1.5
				var bp2 := _bay_pos(i)
				# rejoin at nearest track point (just use t=0 area)
				var target := _track_pos(float(c["track_t"]))
				c["pos"] = (bp2 as Vector2).lerp(target, minf(float(c["bay_t"]), 1.0))
				if float(c["bay_t"]) >= 1.0:
					c["mode"] = M_TRACK
	# particles
	for s in _smokes:
		s["life"] = float(s["life"]) - dt
		s["pos"] = (s["pos"] as Vector2) + Vector2(0, -14) * dt
	_smokes = _smokes.filter(func(s): return float(s["life"]) > 0.0)
	for cn in _coins:
		cn["life"] = float(cn["life"]) - dt
		cn["pos"] = (cn["pos"] as Vector2) + Vector2(randf_range(-20, 20), -40) * dt
	_coins = _coins.filter(func(cn): return float(cn["life"]) > 0.0)
	if _smokes.size() > 60:
		_smokes = _smokes.slice(_smokes.size() - 60)
	queue_redraw()

func _spawn_smoke(p: Vector2) -> void:
	_smokes.append({"pos": p + Vector2(randf_range(-8, 8), 0), "life": 0.9, "max": 0.9, "size": randf_range(6, 12)})

func _spawn_spark(p: Vector2) -> void:
	_smokes.append({"pos": p + Vector2(randf_range(-14, 14), randf_range(-8, 8)), "life": 0.4, "max": 0.4, "size": randf_range(3, 5)})

func _spawn_coins(p: Vector2) -> void:
	for k in range(5):
		_coins.append({"pos": p + Vector2(randf_range(-20, 20), 0), "life": 1.0, "max": 1.0})

func _in_drift_zone(t: float) -> bool:
	var d := t * _perimeter
	var s1 := 2.0 * _straight
	var ce := s1 + PI * _radius
	var s2 := ce + 2.0 * _straight
	return (d > s1 and d < ce) or (d > s2)

func _track_pos(t: float) -> Vector2:
	var d := t * _perimeter
	var s := 2.0 * _straight
	var c := PI * _radius
	if d < s:
		return Vector2(_cx - _straight + d, _cy - _radius)
	d -= s
	if d < c:
		var a := d / _radius
		return Vector2(_cx + _straight + _radius * sin(a), _cy - _radius * cos(a))
	d -= c
	if d < s:
		return Vector2(_cx + _straight - d, _cy + _radius)
	d -= s
	var a2 := d / _radius
	return Vector2(_cx - _straight - _radius * sin(a2), _cy + _radius * cos(a2))

func _track_angle(t: float) -> float:
	var d := t * _perimeter
	var s := 2.0 * _straight
	var c := PI * _radius
	if d < s:
		return 0.0
	d -= s
	if d < c:
		return d / _radius
	d -= c
	if d < s:
		return PI
	d -= c
	return PI + d / _radius

func _draw() -> void:
	var w := size.x
	draw_rect(Rect2(0, 0, w, size.y), Color(0.08, 0.07, 0.10))
	# track
	var pts := PackedVector2Array()
	var n := 64
	for i in range(n + 1):
		pts.append(_track_pos(float(i) / float(n)))
	draw_polyline(pts, Color(0.16, 0.16, 0.18), 26.0, true)
	draw_polyline(pts, Color(0.22, 0.22, 0.25), 20.0, true)
	# bays
	if game:
		for i in range(6):
			var bp := _bay_pos(i)
			var owned := int(game.owned[i])
			var g: Dictionary = Economy.GENERATORS[i]
			# stall
			var rect := Rect2(bp - Vector2(BAY_W / 2, BAY_H / 2), Vector2(BAY_W, BAY_H))
			var col := Color(0.13, 0.12, 0.16) if owned > 0 else Color(0.08, 0.08, 0.10)
			draw_rect(rect, col)
			draw_rect(rect, Color(1.0, 0.62, 0.25, 0.5 if owned > 0 else 0.15), false, 2.0)
			# label
			var lbl: String = BAY_NAMES[i]
			if owned > 0:
				lbl += " x%d" % owned
			else:
				var unl: float = g["unlock"]
				if unl > 0:
					lbl = "LOCK $%s" % BigNum.fmt(unl)
			draw_string(ThemeDB.fallback_font, bp + Vector2(-BAY_W / 2 + 8, -BAY_H / 2 - 6),
				lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.75 if owned > 0 else 0.35))
			# working glow (progress)
			if owned > 0:
				var pr: float = game.progress[i]
				draw_rect(Rect2(bp - Vector2(BAY_W / 2, BAY_H / 2 + 4), Vector2(BAY_W * pr, 3)),
					Color(0.45, 1.0, 0.55))
	# smoke/sparks
	for s in _smokes:
		var a: float = float(s["life"]) / float(s["max"])
		draw_circle(s["pos"], float(s["size"]), Color(0.8, 0.8, 0.85, a * 0.35))
	# coins
	for cn in _coins:
		var ca: float = float(cn["life"]) / float(cn["max"])
		draw_circle(cn["pos"], 5.0, Color(1.0, 0.85, 0.30, ca))
	# cars
	if game:
		for i in range(6):
			if int(game.owned[i]) <= 0:
				continue
			var c: Dictionary = _cars[i]
			var drifting := int(c["mode"]) == M_TRACK and _in_drift_zone(float(c["track_t"]))
			_draw_car(c["pos"], float(c["angle"]), drifting, c["color"])
	# status
	var st := "WARMING UP"
	var nowned := 0
	if game:
		for i in range(6):
			if int(game.owned[i]) > 0:
				nowned += 1
	if nowned >= 6:
		st = "FULL SEND"
	elif nowned >= 3:
		st = "TANDEM DRIFT"
	elif nowned >= 2:
		st = "DRIFTING"
	var ips := "$0/s"
	if game:
		ips = "$%s/s" % BigNum.fmt(game.income_per_sec())
	draw_string(ThemeDB.fallback_font, Vector2(24, 28), "LIVE  •  %s" % st,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.45, 0.45))
	draw_string(ThemeDB.fallback_font, Vector2(w - 24, 28), ips,
		HORIZONTAL_ALIGNMENT_RIGHT, -1, 24, Color(0.45, 1.0, 0.55))

func _draw_car(p: Vector2, angle: float, drifting: bool, col: Color) -> void:
	var yaw := angle + (0.45 if drifting else 0.0)
	var dir := Vector2(cos(yaw), sin(yaw))
	var perp := Vector2(-dir.y, dir.x)
	var l := 18.0
	var wd := 9.0
	var body := PackedVector2Array([
		p + dir * l - perp * wd, p + dir * l + perp * wd,
		p - dir * l + perp * wd, p - dir * l - perp * wd,
	])
	draw_colored_polygon(body, col)
	var ws := PackedVector2Array([
		p + dir * l * 0.45 - perp * wd * 0.7, p + dir * l * 0.45 + perp * wd * 0.7,
		p + dir * l * 0.05 + perp * wd * 0.7, p + dir * l * 0.05 - perp * wd * 0.7,
	])
	draw_colored_polygon(ws, Color(0.1, 0.12, 0.16))
	if drifting:
		draw_arc(p, 26.0, 0, TAU, 16, Color(1.0, 0.6, 0.2, 0.25), 3.0)
