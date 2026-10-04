extends Control
## Live garage preview: drift track up top, service bays below.
## Each owned generator gets a car that cycles: TRACK -> PULL IN -> SERVICE -> PULL OUT.

var game  # main.gd

# track geometry (portrait hero: 720x520 canvas)
var _cx := 360.0
var _cy := 150.0
var _straight := 210.0
var _radius := 68.0
var _perimeter := 0.0

# bays: 3 cols x 2 rows
const BAY_W := 200.0
const BAY_H := 84.0

var _cars := []  # per generator: {mode, track_t, speed, color, bay_t, service_t, pos}
var _smokes := []
var _coins := []  # {pos, life}
var _floats := []  # {pos, life, max, text}
var _time := 0.0

const BAY_NAMES := ["OIL", "TIRE", "PAINT", "TUNE", "ENGINE", "DRIFT"]

# car modes
const M_TRACK := 0
const M_TO_BAY := 1
const M_BAY := 2
const M_TO_TRACK := 3

var _car_tex: Array = []  # preloaded car sprites, null = procedural fallback

func _ready() -> void:
	_perimeter = 4.0 * _straight + 2.0 * PI * _radius
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(20):
		var path := "res://assets/cars/car_%02d.png" % i
		if ResourceLoader.exists(path):
			_car_tex.append(load(path))
		else:
			_car_tex.append(null)
	for i in range(6):
		_cars.append({
			"mode": M_TRACK, "track_t": randf(),
			"speed": 0.10 + randf() * 0.04,
			"bay_t": 0.0, "service_t": 0.0,
			"track_time": randf_range(0.0, 8.0),
			"spin_t": 0.0,  # for 360 move
			"pos": Vector2.ZERO, "angle": 0.0,
		})

func _car_color(i: int) -> Color:
	if game:
		var car: Dictionary = Economy.CARS[int(game.cars_equipped[i])]
		return car["color"]
	return Color(0.8, 0.8, 0.8)

func _car_speed_mult(i: int) -> float:
	if game:
		var car: Dictionary = Economy.CARS[int(game.cars_equipped[i])]
		return float(car["speed"])
	return 1.0

func _car_move(i: int) -> String:
	if game:
		var car: Dictionary = Economy.CARS[int(game.cars_equipped[i])]
		return String(car["move"])
	return "drift"

func _car_livery(i: int) -> String:
	if game:
		var car: Dictionary = Economy.CARS[int(game.cars_equipped[i])]
		return String(car["livery"])
	return "plain"

func _car_rarity(i: int) -> String:
	if game:
		var car: Dictionary = Economy.CARS[int(game.cars_equipped[i])]
		return String(car["rarity"])
	return "regular"

func _bay_pos(i: int) -> Vector2:
	var col := i % 3
	var row := i / 3
	return Vector2(130.0 + col * 230.0, 345.0 + row * 115.0)

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
				var old_t := float(c["track_t"])
				var spd: float = float(c["speed"]) * _car_speed_mult(i) * boost
				c["track_t"] = fmod(old_t + spd * dt, 1.0)
				var new_t := float(c["track_t"])
				c["pos"] = _track_pos(new_t)
				c["angle"] = _track_angle(new_t)
				c["track_time"] = float(c["track_time"]) + dt
				# crossed the finish line -> money float!
				if new_t < old_t and game:
					var share: float = game.income_per_sec() / maxf(1.0, float(_owned_count()))
					_spawn_float(_track_pos(0.0) + Vector2(0, -30), "+$%s" % BigNum.fmt(share))
					_spawn_coins(_track_pos(0.0))
				# pull in for service only after 12s+ on track (no instant bounce)
				if float(c["track_time"]) > 12.0 and randf() < dt * 0.25:
					c["mode"] = M_TO_BAY
					c["bay_t"] = 0.0
					c["track_time"] = 0.0
				# signature move in drift zone
				var mv := _car_move(i)
				if _in_drift_zone(new_t):
					match mv:
						"spin":
							# 360 spin: rotate extra
							c["spin_t"] = float(c["spin_t"]) + dt * 6.0
						"reverse":
							# reverse entry handled in draw (flipped yaw)
							pass
						"wall":
							# wall tap: sparks
							if randf() < dt * 10.0:
								_spawn_spark(c["pos"])
					if randf() < 0.4:
						_spawn_smoke(c["pos"])
					if randf() < dt * 2.0 and game:
						_spawn_float(c["pos"] + Vector2(0, -24), "+$%s" % BigNum.fmt(game.income_per_sec() * 0.1))
				else:
					c["spin_t"] = 0.0
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
	for fl in _floats:
		fl["life"] = float(fl["life"]) - dt
		fl["pos"] = (fl["pos"] as Vector2) + Vector2(0, -30) * dt
	_floats = _floats.filter(func(fl): return float(fl["life"]) > 0.0)
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

func _spawn_float(p: Vector2, text: String) -> void:
	_floats.append({"pos": p, "life": 1.4, "max": 1.4, "text": text})
	if _floats.size() > 20:
		_floats.pop_front()

func _owned_count() -> int:
	var n := 0
	if game:
		for i in range(6):
			if int(game.owned[i]) > 0:
				n += 1
	return n

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

func _track_theme() -> Dictionary:
	# 0=street, 1=neon (6+ cars), 2=championship (1+ star)
	var tier := 0
	if game:
		var owned_cars := 0
		for c in game.cars_owned:
			if c:
				owned_cars += 1
		if int(game.stars) >= 1:
			tier = 2
		elif owned_cars >= 6:
			tier = 1
	match tier:
		1:
			return {"name": "NEON NIGHTS", "curb_a": Color(0.2, 0.9, 1.0), "curb_b": Color(0.9, 0.2, 0.9),
				"asphalt": Color(0.10, 0.10, 0.14), "asphalt_hi": Color(0.16, 0.16, 0.20),
				"bg": Color(0.05, 0.05, 0.10), "glow": Color(0.2, 0.8, 1.0, 0.3)}
		2:
			return {"name": "CHAMPIONSHIP", "curb_a": Color(1.0, 0.8, 0.2), "curb_b": Color(0.95, 0.95, 0.95),
				"asphalt": Color(0.14, 0.13, 0.12), "asphalt_hi": Color(0.20, 0.19, 0.18),
				"bg": Color(0.08, 0.07, 0.06), "glow": Color(1.0, 0.8, 0.2, 0.25)}
	return {"name": "STREET CIRCUIT", "curb_a": Color(0.85, 0.20, 0.20), "curb_b": Color(0.92, 0.92, 0.92),
		"asphalt": Color(0.15, 0.15, 0.17), "asphalt_hi": Color(0.21, 0.21, 0.24),
		"bg": Color(0.08, 0.07, 0.10), "glow": Color(0, 0, 0, 0)}

func _draw() -> void:
	var w := size.x
	var theme := _track_theme()
	draw_rect(Rect2(0, 0, w, size.y), theme["bg"])
	# infield grass with subtle texture
	var pts := PackedVector2Array()
	var n := 72
	for i in range(n + 1):
		pts.append(_track_pos(float(i) / float(n)))
	# grass infield (fill inside track)
	var inner := PackedVector2Array()
	for i in range(n + 1):
		inner.append(_track_pos(float(i) / float(n)) * 0.82 + Vector2(_cx * 0.18, _cy * 0.18))
	draw_colored_polygon(inner, Color(0.12, 0.28, 0.14))
	# track: curb, then asphalt with theme colors
	for i in range(0, n, 2):
		var seg := PackedVector2Array([pts[i], pts[i + 1], pts[i + 2] if i + 2 <= n else pts[n]])
		var curb_col: Color = theme["curb_a"] if (i / 2) % 2 == 0 else theme["curb_b"]
		if seg.size() >= 2:
			draw_polyline(seg, curb_col, 46.0, true)
	draw_polyline(pts, theme["asphalt"], 40.0, true)
	draw_polyline(pts, theme["asphalt_hi"], 32.0, true)
	# theme glow under track
	if (theme["glow"] as Color).a > 0:
		draw_polyline(pts, theme["glow"], 52.0, true)
	# checkered start/finish line
	var sf := _track_pos(0.0)
	for k in range(4):
		var ck := Color(1, 1, 1) if k % 2 == 0 else Color(0.1, 0.1, 0.1)
		draw_rect(Rect2(sf + Vector2(-3, -16 + k * 8), Vector2(6, 8)), ck)
	# theme label
	draw_string(ThemeDB.fallback_font, Vector2(16, 30), theme["name"],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.5))
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
	# floating money text
	for fl in _floats:
		var fa: float = float(fl["life"]) / float(fl["max"])
		draw_string(ThemeDB.fallback_font, fl["pos"], String(fl["text"]),
			HORIZONTAL_ALIGNMENT_CENTER, 120, 20, Color(0.45, 1.0, 0.55, fa))
	# cars
	if game:
		for i in range(6):
			if int(game.owned[i]) <= 0:
				continue
			var c: Dictionary = _cars[i]
			var drifting := int(c["mode"]) == M_TRACK and _in_drift_zone(float(c["track_t"]))
			var mv := _car_move(i)
			var extra_yaw := 0.0
			if drifting:
				match mv:
					"spin":
						extra_yaw = float(c["spin_t"])  # 360 spin
					"reverse":
						extra_yaw = PI * 0.75  # reverse entry (backwards)
					"wall":
						extra_yaw = 0.6
					_:
						extra_yaw = 0.45
			_draw_car(c["pos"], float(c["angle"]) + extra_yaw, drifting, _car_color(i), _car_livery(i), _car_rarity(i), int(game.cars_equipped[i]))
	# status
	var st := "WARMING UP"
	var nowned := _owned_count()
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

func _draw_car(p: Vector2, angle: float, drifting: bool, col: Color, livery: String, rarity: String, car_idx: int) -> void:
	var yaw := angle
	# sprite (Kenney, faces up) — rotate so its nose follows travel dir
	var tex: Texture2D = _car_tex[car_idx] if car_idx < _car_tex.size() else null
	if tex != null:
		# drop shadow for depth
		draw_set_transform(p + Vector2(4, 6), yaw + PI * 0.5, Vector2(0.55, 0.55))
		draw_texture(tex, -tex.get_size() * 0.5, Color(0, 0, 0, 0.35))
		# car body (bigger so spoilers/details read)
		draw_set_transform(p, yaw + PI * 0.5, Vector2(0.55, 0.55))
		draw_texture(tex, -tex.get_size() * 0.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		# procedural fallback
		var dir := Vector2(cos(yaw), sin(yaw))
		var perp := Vector2(-dir.y, dir.x)
		var l := 26.0
		var wd := 13.0
		var body := PackedVector2Array([
			p + dir * l - perp * wd, p + dir * l + perp * wd,
			p - dir * l + perp * wd, p - dir * l - perp * wd,
		])
		draw_colored_polygon(body, col)
	# rarity glow ring
	var rcol: Color = Economy.RARITY_COLORS.get(rarity, Color(1, 1, 1, 0.3))
	if rarity == "legendary":
		draw_arc(p, 34.0, 0, TAU, 20, Color(rcol.r, rcol.g, rcol.b, 0.6), 3.0)
	elif rarity == "exotic":
		draw_arc(p, 32.0, 0, TAU, 20, Color(rcol.r, rcol.g, rcol.b, 0.4), 2.0)
	if drifting:
		draw_arc(p, 26.0, 0, TAU, 16, Color(1.0, 0.6, 0.2, 0.25), 3.0)
