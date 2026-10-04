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
const BAY_W := 160.0
const BAY_H := 84.0

var _cars := []  # per generator: {mode, track_t, speed, color, bay_t, service_t, pos}
var _smokes := []
var _skids := []  # persistent skid marks: {pos, angle, life}
var _trails := []  # drift trails: {pos, life, max, col}
var _coins := []  # {pos, life}
var _floats := []  # {pos, life, max, text}
var _time := 0.0

const BAY_NAMES := ["OIL", "TIRE", "PAINT", "TUNE", "ENGINE", "DRIFT", "SHINE", "DYNO", "AERO", "LAB"]

# car modes
const M_TRACK := 0
const M_TO_BAY := 1
const M_BAY := 2
const M_TO_TRACK := 3

var _car_tex: Array = []  # preloaded car sprites, null = procedural fallback

func _ready() -> void:
	_build_track(0)  # default to Ebisu
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(20):
		var path := "res://assets/cars/car_%02d.png" % i
		if ResourceLoader.exists(path):
			_car_tex.append(load(path))
		else:
			_car_tex.append(null)
	for i in range(10):
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
	var col := i % 4
	var row := i / 4
	return Vector2(95.0 + col * 175.0, 345.0 + row * 115.0)

func _process(dt: float) -> void:
	_time += dt
	var boost := 1.0
	if game:
		boost = 1.0 + minf(game.income_per_sec() / 5000.0, 1.5)
		# rebuild track if player switched
		var want_shape: int = _track_shape_idx()
		if want_shape != _track_shape:
			_build_track(want_shape)
	for i in range(10):
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
	for sk in _skids:
		sk["life"] = float(sk["life"]) - dt
	_skids = _skids.filter(func(sk): return float(sk["life"]) > 0.0)
	for tr in _trails:
		tr["life"] = float(tr["life"]) - dt
	_trails = _trails.filter(func(tr): return float(tr["life"]) > 0.0)
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

func _spawn_skid(p: Vector2, angle: float) -> void:
	_skids.append({"pos": p, "angle": angle, "life": 8.0, "max": 8.0})
	if _skids.size() > 120:
		_skids = _skids.slice(_skids.size() - 120)

func _spawn_drift_trail(p: Vector2, col: Color) -> void:
	# colored drift trail (neon-noir style)
	_trails.append({"pos": p, "life": 1.2, "max": 1.2, "col": col})
	if _trails.size() > 80:
		_trails = _trails.slice(_trails.size() - 80)

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
		for i in range(10):
			if int(game.owned[i]) > 0:
				n += 1
	return n

var _track_pts := PackedVector2Array()  # precomputed centerline polyline
var _track_shape := 0  # 0=ebisu, 1=meihan, 2=nikko, 3=longbeach, 4=irwindale

func _build_track(shape: int) -> void:
	_track_shape = shape
	_track_pts.clear()
	match shape:
		0:  # EBISU — peanut (stadium with pinched straights)
			_build_stadium(210.0, 68.0, 36.0)
		1:  # MEIHAN — paperclip (long straight, tight hairpin, short back, wide sweeper)
			_build_paperclip()
		2:  # NIKKO — rounded triangle (3 uneven corners)
			_build_triangle()
		3:  # LONG BEACH — angular (sharp 90° corners)
			_build_angular()
		4:  # IRWINDALE — twin oval (ellipse)
			_build_ellipse(260.0, 105.0)
		5:  # FUJI — D-shape (massive straight + banked sweeper)
			_build_fuji()
		6:  # SUZUKA EAST — flowing S-complex
			_build_suzuka()
		7:  # MONZA — high-speed rectangle with chicanes
			_build_monza()
	_perimeter = 0.0
	for i in range(_track_pts.size()):
		var a: Vector2 = _track_pts[i]
		var b: Vector2 = _track_pts[(i + 1) % _track_pts.size()]
		_perimeter += a.distance_to(b)

func _build_stadium(straight: float, radius: float, pinch: float) -> void:
	# stadium oval with optional middle pinch (Ebisu peanut)
	var n := 24
	# top straight (left to right), bowed inward by pinch
	for i in range(n + 1):
		var t := float(i) / n
		var x := _cx - straight + t * 2.0 * straight
		var bow := sin(t * PI) * pinch
		_track_pts.append(Vector2(x, _cy - radius + bow))
	# right arc
	for i in range(1, n / 2 + 1):
		var a := float(i) / (n / 2) * PI
		_track_pts.append(Vector2(_cx + straight + radius * sin(a), _cy - radius * cos(a)))
	# bottom straight (right to left), bowed inward
	for i in range(1, n + 1):
		var t := float(i) / n
		var x := _cx + straight - t * 2.0 * straight
		var bow := sin(t * PI) * pinch
		_track_pts.append(Vector2(x, _cy + radius - bow))
	# left arc
	for i in range(1, n / 2 + 1):
		var a := float(i) / (n / 2) * PI
		_track_pts.append(Vector2(_cx - straight - radius * sin(a), _cy + radius * cos(a)))

func _build_paperclip() -> void:
	# Meihan: long straight → tight hairpin → short straight → wide sweeper
	var pts := PackedVector2Array()
	var n := 20
	# long top straight (left to right)
	for i in range(n + 1):
		var t := float(i) / n
		pts.append(Vector2(_cx - 280 + t * 560, _cy - 70))
	# tight hairpin right (r=35)
	for i in range(1, 12):
		var a := float(i) / 12 * PI
		pts.append(Vector2(_cx + 280 + 35 * sin(a), _cy - 70 + 35 * (1 - cos(a))))
	# short bottom straight (right to left)
	for i in range(1, n / 2 + 1):
		var t := float(i) / (n / 2)
		pts.append(Vector2(_cx + 280 - t * 280, _cy))
	# wide sweeper left (r=80)
	for i in range(1, 16):
		var a := float(i) / 16 * PI
		pts.append(Vector2(_cx - 70 - 80 * sin(a), _cy + 80 * (1 - cos(a)) * 0.5))
	_track_pts = pts

func _build_triangle() -> void:
	# Nikko: 3 straights, 3 different corner radii
	var pts := PackedVector2Array()
	var corners := [
		{"x": _cx + 180, "y": _cy - 40, "r": 30.0},
		{"x": _cx - 60, "y": _cy + 90, "r": 55.0},
		{"x": _cx - 180, "y": _cy - 60, "r": 75.0},
	]
	# simplified: triangle vertices with rounded corners
	var verts := [Vector2(_cx + 200, _cy - 50), Vector2(_cx - 40, _cy + 100), Vector2(_cx - 200, _cy - 70)]
	var n := 16
	for vi in range(3):
		var a: Vector2 = verts[vi]
		var b: Vector2 = verts[(vi + 1) % 3]
		var r: float = corners[vi]["r"]
		# straight to corner entry
		var dir := (b - a).normalized()
		var entry := b - dir * r
		for i in range(n):
			var t := float(i) / n
			pts.append(a.lerp(entry, t))
		# arc around corner
		var c: Vector2 = corners[vi]["x"]
		# simplified: just add the corner point
		pts.append(b)
	_track_pts = pts

func _build_angular() -> void:
	# Long Beach: sharp 90° corners (chamfered slightly)
	var w := 240.0
	var h := 90.0
	var ch := 25.0  # chamfer
	var pts := PackedVector2Array([
		Vector2(_cx - w + ch, _cy - h),
		Vector2(_cx + w - ch, _cy - h),
		Vector2(_cx + w, _cy - h + ch),
		Vector2(_cx + w, _cy + h - ch),
		Vector2(_cx + w - ch, _cy + h),
		Vector2(_cx - w + ch, _cy + h),
		Vector2(_cx - w, _cy + h - ch),
		Vector2(_cx - w, _cy - h + ch),
	])
	# subdivide for smooth car movement
	var dense := PackedVector2Array()
	var n := 12
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		for j in range(n):
			dense.append(a.lerp(b, float(j) / n))
	_track_pts = dense

func _build_ellipse(rx: float, ry: float) -> void:
	# Irwindale: clean ellipse
	var n := 72
	for i in range(n):
		var a := float(i) / n * TAU
		_track_pts.append(Vector2(_cx + rx * cos(a), _cy + ry * sin(a)))

func _build_fuji() -> void:
	# D-shape: very long straight + huge banked sweeper
	var pts := PackedVector2Array()
	var n := 24
	# long top straight
	for i in range(n + 1):
		var t := float(i) / n
		pts.append(Vector2(_cx - 290 + t * 580, _cy - 85))
	# big right sweeper (r=85, 180°)
	for i in range(1, 20):
		var a := float(i) / 20 * PI
		pts.append(Vector2(_cx + 290 + 85 * sin(a), _cy - 85 + 85 * (1 - cos(a))))
	# bottom straight back
	for i in range(1, n + 1):
		var t := float(i) / n
		pts.append(Vector2(_cx + 290 - t * 580, _cy + 85))
	# tight left hairpin (r=40)
	for i in range(1, 14):
		var a := float(i) / 14 * PI
		pts.append(Vector2(_cx - 290 - 40 * sin(a), _cy + 85 - 40 * (1 - cos(a))))
	_track_pts = pts

func _build_suzuka() -> void:
	# flowing S-complex: alternating curves
	var pts := PackedVector2Array()
	var n := 60
	for i in range(n + 1):
		var t := float(i) / n * TAU
		# S-curve modulation on an ellipse base
		var rx := 240.0
		var ry := 95.0
		var wobble := 28.0 * sin(t * 3.0)
		var x := _cx + (rx + wobble) * cos(t)
		var y := _cy + ry * sin(t)
		pts.append(Vector2(x, y))
	_track_pts = pts

func _build_monza() -> void:
	# high-speed rectangle with 2 chicanes
	var pts := PackedVector2Array([
		Vector2(_cx - 250, _cy - 80),
		Vector2(_cx + 250, _cy - 80),
		Vector2(_cx + 270, _cy - 40),
		Vector2(_cx + 270, _cy + 40),
		Vector2(_cx + 250, _cy + 80),
		# chicane 1 (right-left kink)
		Vector2(_cx + 100, _cy + 80),
		Vector2(_cx + 80, _cy + 60),
		Vector2(_cx + 60, _cy + 80),
		Vector2(_cx - 60, _cy + 80),
		# chicane 2
		Vector2(_cx - 80, _cy + 60),
		Vector2(_cx - 100, _cy + 80),
		Vector2(_cx - 250, _cy + 80),
		Vector2(_cx - 270, _cy + 40),
		Vector2(_cx - 270, _cy - 40),
	])
	var dense := PackedVector2Array()
	var m := 10
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		for j in range(m):
			dense.append(a.lerp(b, float(j) / m))
	_track_pts = dense

func _track_pos(t: float) -> Vector2:
	if _track_pts.is_empty():
		return Vector2(_cx, _cy)
	var n := _track_pts.size()
	var ft := fposmod(t, 1.0) * n
	var i0 := int(ft) % n
	var i1 := (i0 + 1) % n
	var frac: float = ft - floor(ft)
	return _track_pts[i0].lerp(_track_pts[i1], frac)

func _track_angle(t: float) -> float:
	var p0 := _track_pos(t)
	var p1 := _track_pos(t + 0.01)
	return (p1 - p0).angle()

func _in_drift_zone(t: float) -> bool:
	# drift where the track curves (angle changing rapidly)
	var a0 := _track_angle(t)
	var a1 := _track_angle(t + 0.02)
	var turn := absf(wrapf(a1 - a0, -PI, PI))
	return turn > 0.08

func _track_theme() -> Dictionary:
	# use the player's selected track
	if game:
		var ti: int = game.track_selected
		if ti >= 0 and ti < Economy.TRACKS.size():
			return Economy.TRACKS[ti]
	return Economy.TRACKS[0]

func _track_shape_idx() -> int:
	var theme := _track_theme()
	return int(theme.get("shape", 0))

func _draw_scenery(shape: int) -> void:
	match shape:
		0:  # Ebisu Nights — bouncing crowd + waving banners
			for i in range(24):
				var a := float(i) / 24 * TAU
				var bounce := sin(_time * 8.0 + float(i) * 0.8) * 3.0
				var p := Vector2(_cx + 300 * cos(a), _cy + 140 * sin(a) + bounce)
				draw_circle(p, 3.0, Color(0.9, 0.85, 0.7, 0.5))
			# waving banners
			for i in range(4):
				var bx := 120.0 + i * 160.0
				var wave := sin(_time * 5.0 + float(i) * 1.2) * 4.0
				draw_rect(Rect2(bx, 268 + wave, 100, 18), Color(0.85, 0.2, 0.25, 0.8))
		1:  # Meihan Wall — concrete barriers (static, solid)
			for i in range(10):
				var x := 100.0 + i * 65.0
				draw_rect(Rect2(x, 52, 55, 14), Color(0.55, 0.55, 0.58))
				draw_rect(Rect2(x, 52, 55, 4), Color(0.9, 0.75, 0.2))
		2:  # Nikko Tech — swaying trees
			for i in range(16):
				var tx := 40.0 + fposmod(i * 137.0, 640.0)
				var ty := 30.0 + fposmod(i * 89.0, 240.0)
				if Vector2(tx - _cx, ty - _cy).length() < 120.0:
					continue
				var sway := sin(_time * 2.5 + float(i)) * 3.0
				draw_circle(Vector2(tx + sway, ty), 10.0, Color(0.15, 0.35, 0.18))
				draw_circle(Vector2(tx - 3 + sway, ty - 3), 5.0, Color(0.20, 0.45, 0.22))
		3:  # Long Beach — buildings with twinkling windows + swaying palms
			for i in range(5):
				var bx := 60.0 + i * 130.0
				draw_rect(Rect2(bx, 20, 80, 50), Color(0.22, 0.24, 0.30))
				var twinkle := 0.4 + 0.3 * sin(_time * 3.0 + float(i) * 2.0)
				draw_rect(Rect2(bx + 10, 30, 60, 8), Color(0.95, 0.85, 0.4, twinkle))
			for i in range(6):
				var px := 80.0 + i * 110.0
				var sway := sin(_time * 2.0 + float(i) * 1.5) * 4.0
				draw_line(Vector2(px, 250), Vector2(px + sway, 230), Color(0.4, 0.3, 0.2), 4.0)
				draw_circle(Vector2(px + sway, 225), 12.0, Color(0.18, 0.45, 0.20))
		4:  # Irwindale — sweeping spotlights + bouncing crowd
			for i in range(4):
				var sx := 100.0 + i * 170.0
				var sweep := sin(_time * 1.5 + float(i) * 1.8) * 50.0
				var cone := PackedVector2Array([
					Vector2(sx, 10), Vector2(sx - 40 + sweep, 120), Vector2(sx + 40 + sweep, 120)
				])
				draw_colored_polygon(cone, Color(1, 1, 0.9, 0.08))
				draw_circle(Vector2(sx, 10), 6.0, Color(1, 1, 0.9, 0.9))
			draw_rect(Rect2(80, 270, 560, 24), Color(0.18, 0.18, 0.22))
			for i in range(28):
				var gx := 90.0 + i * 20.0
				var bounce := sin(_time * 7.0 + float(i) * 0.9) * 2.5
				draw_circle(Vector2(gx, 282 + bounce), 3.0, Color(0.9, 0.85, 0.7, 0.6))
		5:  # Fuji — Mt. Fuji + animated speed lines
			var mtn := PackedVector2Array([
				Vector2(480, 60), Vector2(580, 10), Vector2(680, 60)
			])
			draw_colored_polygon(mtn, Color(0.25, 0.28, 0.35))
			draw_circle(Vector2(580, 18), 12.0, Color(0.9, 0.9, 0.95, 0.8))
			for i in range(6):
				var lx := 120.0 + i * 90.0 + fposmod(_time * 120.0, 90.0)
				draw_line(Vector2(lx, 40), Vector2(lx + 40, 40), Color(1, 1, 1, 0.15), 2.0)
		6:  # Suzuka East — swaying hills + spinning Ferris wheel
			for i in range(10):
				var hx := 60.0 + i * 65.0
				var hy := 25.0 + 10.0 * sin(i * 1.3)
				draw_circle(Vector2(hx, hy), 18.0, Color(0.16, 0.32, 0.18))
			var spin := _time * 0.8
			draw_arc(Vector2(620, 60), 28.0, 0, TAU, 24, Color(0.9, 0.5, 0.6, 0.5), 3.0)
			for i in range(10):
				var a := float(i) / 8 * TAU + spin
				draw_circle(Vector2(620, 60) + Vector2(cos(a), sin(a)) * 28.0, 4.0, Color(0.9, 0.5, 0.6, 0.6))
		7:  # Monza — waving Italian flags
			for i in range(3):
				var fx := 150.0 + i * 200.0
				var wave := sin(_time * 6.0 + float(i) * 2.0) * 3.0
				draw_rect(Rect2(fx, 15 + wave, 14, 30), Color(0.2, 0.6, 0.3))
				draw_rect(Rect2(fx + 14, 15 + wave, 14, 30), Color(0.95, 0.95, 0.95))
				draw_rect(Rect2(fx + 28, 15 + wave, 14, 30), Color(0.8, 0.2, 0.2))
			draw_arc(Vector2(_cx, _cy), 150.0, 0, TAU, 48, Color(0.6, 0.55, 0.5, 0.25), 8.0)

func _draw() -> void:
	var w := size.x
	var theme := _track_theme()
	draw_rect(Rect2(0, 0, w, size.y), theme["bg"])
	# scenery behind track (per-track decorations)
	_draw_scenery(_track_shape_idx())
	# use precomputed track polyline
	var pts := _track_pts
	var n := pts.size()
	if n < 3:
		return
	# grass infield (fill inside track, shrunk toward center)
	var inner := PackedVector2Array()
	for i in range(n):
		inner.append(pts[i] * 0.80 + Vector2(_cx * 0.20, _cy * 0.20))
	draw_colored_polygon(inner, Color(0.12, 0.28, 0.14))
	# track: layered halo (outer glow for depth), curb, then asphalt
	var step := maxi(1, n / 36)
	var loop := pts + PackedVector2Array([pts[0]])
	# outer halo — soft glow under everything
	draw_polyline(loop, Color(0, 0, 0, 0.5), 58.0, true)
	# curb with rounded alternating segments
	for i in range(0, n, step * 2):
		var seg := PackedVector2Array([pts[i], pts[(i + step) % n], pts[(i + step * 2) % n]])
		var curb_col: Color = theme["curb_a"] if (i / (step * 2)) % 2 == 0 else theme["curb_b"]
		draw_polyline(seg, curb_col, 48.0, true)
	# asphalt
	draw_polyline(loop, theme["asphalt"], 42.0, true)
	draw_polyline(loop, theme["asphalt_hi"], 34.0, true)
	# neon edge line (thin bright line on track edge)
	var edge_col: Color = theme["curb_a"]
	draw_polyline(loop, Color(edge_col.r, edge_col.g, edge_col.b, 0.35), 44.0, true)
	# theme glow under track
	if (theme["glow"] as Color).a > 0:
		draw_polyline(pts, theme["glow"], 54.0, true)
	# checkered start/finish line (animated pulse)
	var sf := _track_pos(0.0)
	var sf_pulse := 0.85 + 0.15 * sin(_time * 4.0)
	for k in range(4):
		var ck := Color(1, 1, 1, sf_pulse) if k % 2 == 0 else Color(0.1, 0.1, 0.1, sf_pulse)
		draw_rect(Rect2(sf + Vector2(-4, -20 + k * 10), Vector2(8, 10)), ck)
	# theme label
	draw_string(ThemeDB.fallback_font, Vector2(16, 30), theme["name"],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.5))
	# HEAT glow overlay
	if game and float(game.heat_timer) > 0.0:
		var pulse := 0.10 + 0.05 * sin(Time.get_ticks_msec() / 180.0)
		draw_rect(Rect2(0, 0, w, size.y), Color(1.0, 0.45, 0.10, pulse))
	# bays
	if game:
		for i in range(10):
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
	# skid marks (under cars, over track)
	for sk in _skids:
		var sa: float = float(sk["life"]) / float(sk["max"])
		var dir := Vector2(cos(float(sk["angle"])), sin(float(sk["angle"])))
		var pp: Vector2 = sk["pos"]
		draw_line(pp - dir * 14.0, pp + dir * 14.0, Color(0.05, 0.05, 0.06, sa * 0.55), 7.0, true)
	# drift trails (neon glow, over skids)
	for tr in _trails:
		var ta: float = float(tr["life"]) / float(tr["max"])
		var tc: Color = tr["col"]
		var tp: Vector2 = tr["pos"]
		draw_circle(tp, 10.0 * ta + 4.0, Color(tc.r, tc.g, tc.b, ta * 0.30))
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
		for i in range(10):
			if int(game.owned[i]) <= 0:
				continue
			var c: Dictionary = _cars[i]
			var drifting := int(c["mode"]) == M_TRACK and _in_drift_zone(float(c["track_t"]))
			if drifting:
				_spawn_skid(c["pos"], float(c["angle"]))
				_spawn_drift_trail(c["pos"], _car_color(i))
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
			_draw_car(c["pos"], float(c["angle"]) + extra_yaw, drifting, _car_color(i), _car_livery(i), _car_rarity(i), int(game.cars_equipped[i]), int(game.car_decals[int(game.cars_equipped[i])]), game.car_decal_colors[int(game.cars_equipped[i])])
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

func _draw_decal(bp: Vector2, yaw: float, decal_idx: int, col: Color) -> void:
	var dir := Vector2(cos(yaw), sin(yaw))
	var perp := Vector2(-dir.y, dir.x)
	var style: String = Economy.DECALS[decal_idx]["style"]
	match style:
		"stripe":
			# racing stripe down the center
			draw_line(bp - dir * 28.0, bp + dir * 28.0, col, 10.0, true)
			draw_line(bp - dir * 28.0, bp + dir * 28.0, Color(1, 1, 1, 0.9), 4.0, true)
		"number":
			# big number on roof
			draw_circle(bp, 14.0, Color(1, 1, 1, 0.95))
			draw_arc(bp, 14.0, 0, TAU, 16, col, 3.0)
			draw_string(ThemeDB.fallback_font, bp + Vector2(-8, 7), str(decal_idx + 7),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)
		"flames":
			# flame licks on hood
			for i in range(5):
				var fx := bp + dir * (8.0 + float(i) * 5.0) + perp * sin(float(i) * 2.0) * 8.0
				draw_circle(fx, 6.0 - float(i), Color(col.r, col.g * 0.5, 0.1, 0.9))
		"lightning":
			# lightning bolt
			var pts := PackedVector2Array([
				bp + Vector2(-6, -18), bp + Vector2(4, -4), bp + Vector2(-2, -2),
				bp + Vector2(6, 18), bp + Vector2(-4, 2), bp + Vector2(2, 0),
			])
			# rotate to car yaw
			var rp := PackedVector2Array()
			for pt in pts:
				var rel := pt - bp
				rp.append(bp + rel.rotated(yaw + PI * 0.5))
			draw_colored_polygon(rp, col)
		"checker":
			# checkered band
			for i in range(6):
				var cx := bp - perp * 15.0 + perp * float(i) * 6.0
				var ck := Color(1, 1, 1, 0.9) if i % 2 == 0 else Color(0.1, 0.1, 0.1, 0.9)
				draw_line(cx - dir * 20.0, cx + dir * 20.0, ck, 5.0, true)
		"crown":
			# crown on roof
			var crown := PackedVector2Array([
				bp + Vector2(-12, 6), bp + Vector2(-12, -6), bp + Vector2(-6, 0),
				bp + Vector2(0, -10), bp + Vector2(6, 0), bp + Vector2(12, -6),
				bp + Vector2(12, 6),
			])
			var rp2 := PackedVector2Array()
			for pt in crown:
				var rel := pt - bp
				rp2.append(bp + rel.rotated(yaw + PI * 0.5))
			draw_colored_polygon(rp2, col)

func _draw_car(p: Vector2, angle: float, drifting: bool, col: Color, livery: String, rarity: String, car_idx: int, decal_idx: int = -1, decal_col: Color = Color(1, 1, 1)) -> void:
	var yaw := angle
	# suspension bounce (subtle)
	var bounce := sin(_time * 18.0 + float(car_idx) * 1.7) * 1.5
	var bp := p + Vector2(0, bounce)
	# drift tilt — car slides sideways when drifting
	var drift_angle := 0.0
	if drifting:
		drift_angle = sin(_time * 6.0 + float(car_idx)) * 0.25
	yaw += drift_angle
	# sprite (Kenney, faces up) — rotate so its nose follows travel dir
	var tex: Texture2D = _car_tex[car_idx] if car_idx < _car_tex.size() else null
	if tex != null:
		# drop shadow for depth
		draw_set_transform(bp + Vector2(4, 6), yaw + PI * 0.5, Vector2(0.65, 0.65))
		draw_texture(tex, -tex.get_size() * 0.5, Color(0, 0, 0, 0.35))
		# car body (bigger so spoilers/details read)
		draw_set_transform(bp, yaw + PI * 0.5, Vector2(0.65, 0.65))
		draw_texture(tex, -tex.get_size() * 0.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# SPOILER overlay — dark wing at the rear (makes it pop)
		var dir := Vector2(cos(yaw), sin(yaw))
		var perp := Vector2(-dir.y, dir.x)
		var rear := bp - dir * 30.0
		draw_line(rear - perp * 20.0, rear + perp * 20.0, Color(0.08, 0.08, 0.10, 0.95), 8.0, true)
		draw_line(rear - perp * 20.0, rear + perp * 20.0, Color(0.25, 0.25, 0.30, 0.9), 3.0, true)
		# CUSTOM DECAL from decal shop
		if decal_idx >= 0:
			_draw_decal(bp, yaw, decal_idx, decal_col)
		# DECAL — racing number roundel on the hood (default livery)
		var hood := bp + dir * 12.0
		draw_circle(hood, 11.0, Color(1, 1, 1, 0.92))
		draw_arc(hood, 11.0, 0, TAU, 16, Color(0.15, 0.15, 0.18, 0.9), 2.0)
		draw_string(ThemeDB.fallback_font, hood + Vector2(-7, 6), str((car_idx % 9) + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.12, 0.12, 0.15))
		# EXHAUST — smoke puffs when drifting, flames on boost
		var exhaust := bp - dir * 34.0
		if drifting:
			for i in range(3):
				var off := Vector2(randf_range(-8, 8), randf_range(-8, 8))
				var age := fposmod(_time * 2.0 + float(i) * 0.33 + float(car_idx), 1.0)
				var sp := exhaust - dir * age * 24.0 + off * age
				draw_circle(sp, 4.0 + age * 6.0, Color(0.7, 0.7, 0.72, 0.35 * (1.0 - age)))
		# SPEED LINES — when moving fast
		if not drifting:
			for i in range(2):
				var lp := bp - dir * (44.0 + float(i) * 14.0) + perp * (float(i) * 16.0 - 8.0)
				draw_line(lp, lp + dir * 18.0, Color(1, 1, 1, 0.18), 2.0)
	else:
		# procedural fallback
		var dir := Vector2(cos(yaw), sin(yaw))
		var perp := Vector2(-dir.y, dir.x)
		var l := 26.0
		var wd := 13.0
		var body := PackedVector2Array([
			bp + dir * l - perp * wd, bp + dir * l + perp * wd,
			bp - dir * l + perp * wd, bp - dir * l - perp * wd,
		])
		draw_colored_polygon(body, col)
	# rarity glow ring (pulsing for mythic)
	var rcol: Color = Economy.RARITY_COLORS.get(rarity, Color(1, 1, 1, 0.3))
	if rarity == "mythic":
		var pulse := 0.5 + 0.3 * sin(_time * 4.0)
		draw_arc(bp, 36.0, 0, TAU, 24, Color(rcol.r, rcol.g, rcol.b, pulse), 3.0)
	elif rarity == "legendary":
		draw_arc(bp, 34.0, 0, TAU, 20, Color(rcol.r, rcol.g, rcol.b, 0.6), 3.0)
	elif rarity == "exotic":
		draw_arc(bp, 32.0, 0, TAU, 20, Color(rcol.r, rcol.g, rcol.b, 0.4), 2.0)
	if drifting:
		draw_arc(bp, 26.0, 0, TAU, 16, Color(1.0, 0.6, 0.2, 0.25), 3.0)
