extends Control
## Live drift preview: animated stadium track with cars drifting the corners.
## Car count/speed scales with the player's income.

var game  # main.gd

# stadium track geometry
var _cx := 640.0
var _cy := 118.0
var _straight := 380.0  # half-length of straight
var _radius := 62.0
var _perimeter := 0.0

var _cars := []  # {t, speed, color, drift}
var _smokes := []  # {pos, life, max_life, size}
var _time := 0.0

const CAR_COLORS := [
	Color(0.95, 0.30, 0.25), Color(0.25, 0.55, 0.95), Color(0.95, 0.75, 0.25),
	Color(0.35, 0.90, 0.45), Color(0.90, 0.40, 0.80), Color(0.85, 0.85, 0.88),
]
const STATUS := ["WARMING UP", "DRIFTING", "TANDEM DRIFT", "FULL SEND"]

func _ready() -> void:
	_perimeter = 4.0 * _straight + 2.0 * PI * _radius
	# spawn cars over time as generators unlock
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(dt: float) -> void:
	_time += dt
	# desired car count = number of unlocked generators (min 1)
	var want := 1
	if game:
		for i in range(6):
			var g: Dictionary = Economy.GENERATORS[i]
			if game.lifetime >= float(g["unlock"]) or game.owned[i] > 0:
				want = i + 1
	want = mini(want, 6)
	while _cars.size() < want:
		_cars.append({
			"t": randf(),
			"speed": 0.10 + randf() * 0.04,
			"color": CAR_COLORS[_cars.size() % CAR_COLORS.size()],
			"drift": 0.0,
		})
	# speed scales slightly with income (more money = faster)
	var boost := 1.0
	if game:
		boost = 1.0 + minf(game.income_per_sec() / 5000.0, 1.5)
	for c in _cars:
		c["t"] = fmod(float(c["t"]) + float(c["speed"]) * boost * dt, 1.0)
	# smoke particles
	for s in _smokes:
		s["life"] = float(s["life"]) - dt
		s["pos"] = (s["pos"] as Vector2) + Vector2(0, -18) * dt
	_smokes = _smokes.filter(func(s): return float(s["life"]) > 0.0)
	# spawn smoke in drift zones
	if _cars.size() > 0 and randf() < 0.5:
		for c in _cars:
			if _in_drift_zone(float(c["t"])):
				var p := _track_pos(float(c["t"]))
				_smokes.append({
					"pos": p + Vector2(randf_range(-8, 8), randf_range(-4, 4)),
					"life": 0.9, "max_life": 0.9, "size": randf_range(6, 12),
				})
				if _smokes.size() > 60:
					_smokes.pop_front()
	queue_redraw()

func _in_drift_zone(t: float) -> bool:
	# drift zones = the two semicircles
	var d := t * _perimeter
	var s1_end := 2.0 * _straight
	var curve_end := s1_end + PI * _radius
	var s2_end := curve_end + 2.0 * _straight
	return (d > s1_end and d < curve_end) or (d > s2_end)

func _track_pos(t: float) -> Vector2:
	var d := t * _perimeter
	var s := 2.0 * _straight  # each straight is 2*half
	var c := PI * _radius
	# top straight: left -> right
	if d < s:
		return Vector2(_cx - _straight + d, _cy - _radius)
	d -= s
	# right curve
	if d < c:
		var a := d / _radius  # 0..PI
		return Vector2(_cx + _straight + _radius * sin(a), _cy - _radius * cos(a))
	d -= c
	# bottom straight: right -> left
	if d < s:
		return Vector2(_cx + _straight - d, _cy + _radius)
	d -= s
	# left curve
	var a := d / _radius
	return Vector2(_cx - _straight - _radius * sin(a), _cy + _radius * cos(a))

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
	# backdrop gradient feel: two rects
	draw_rect(Rect2(0, 0, w, size.y), Color(0.08, 0.07, 0.10))
	draw_rect(Rect2(0, size.y - 46, w, 46), Color(0.06, 0.05, 0.08))
	# track: wide dark ring (draw thick polyline loop)
	var pts := PackedVector2Array()
	var n := 64
	for i in range(n + 1):
		pts.append(_track_pos(float(i) / float(n)))
	draw_polyline(pts, Color(0.16, 0.16, 0.18), 34.0, true)
	draw_polyline(pts, Color(0.22, 0.22, 0.25), 28.0, true)
	# center line dashes
	var dash := PackedVector2Array()
	for i in range(0, n, 4):
		dash.append(_track_pos(float(i) / float(n)))
		dash.append(_track_pos(float(i + 1) / float(n)))
	if dash.size() > 1:
		draw_multiline(dash, Color(1, 1, 1, 0.25), 2.0)
	# start/finish line
	var sf := _track_pos(0.0)
	draw_line(sf + Vector2(-4, -14), sf + Vector2(-4, 14), Color(1, 1, 1, 0.8), 4.0)
	# smoke (behind cars)
	for s in _smokes:
		var a: float = float(s["life"]) / float(s["max_life"])
		draw_circle(s["pos"], float(s["size"]) * (1.2 - a * 0.4), Color(0.8, 0.8, 0.85, a * 0.35))
	# cars
	for c in _cars:
		_draw_car(_track_pos(float(c["t"])), _track_angle(float(c["t"])),
			_in_drift_zone(float(c["t"])), c["color"])
	# status text
	var laps := int(_time / 8.0)
	var st: String = STATUS[mini(_cars.size() - 1, 3)] if _cars.size() > 0 else STATUS[0]
	var ips := "$0/s"
	if game:
		ips = "$%s/s" % BigNum.fmt(game.income_per_sec())
	draw_string(ThemeDB.fallback_font, Vector2(24, 34), "LIVE  •  %s" % st,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.45, 0.45))
	draw_string(ThemeDB.fallback_font, Vector2(w - 24, 34), ips,
		HORIZONTAL_ALIGNMENT_RIGHT, -1, 26, Color(0.45, 1.0, 0.55))

func _draw_car(p: Vector2, angle: float, drifting: bool, col: Color) -> void:
	# car as rotated rect with windshield; extra yaw when drifting
	var yaw := angle + (0.45 if drifting else 0.0)
	var dir := Vector2(cos(yaw), sin(yaw))
	var perp := Vector2(-dir.y, dir.x)
	var l := 22.0
	var wd := 11.0
	var body := PackedVector2Array([
		p + dir * l - perp * wd, p + dir * l + perp * wd,
		p - dir * l + perp * wd, p - dir * l - perp * wd,
	])
	draw_colored_polygon(body, col)
	# windshield
	var ws := PackedVector2Array([
		p + dir * l * 0.45 - perp * wd * 0.7, p + dir * l * 0.45 + perp * wd * 0.7,
		p + dir * l * 0.05 + perp * wd * 0.7, p + dir * l * 0.05 - perp * wd * 0.7,
	])
	draw_colored_polygon(ws, Color(0.1, 0.12, 0.16))
	# drift glow
	if drifting:
		draw_arc(p, 30.0, 0, TAU, 16, Color(1.0, 0.6, 0.2, 0.25), 3.0)
