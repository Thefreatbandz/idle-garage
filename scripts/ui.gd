extends CanvasLayer
## Idle Garage UI — 2D, phone-friendly.

const FONT_DISPLAY := preload("res://assets/fonts/Orbitron.ttf")
const FONT_HUD := preload("res://assets/fonts/Rajdhani.ttf")
const FONT_MONO := preload("res://assets/fonts/ShareTechMono.ttf")

# clean text badges (emoji renders as tofu on some phones)
const BADGES := ["OIL", "TIRE", "PAINT", "TUNE", "ENGINE", "DRIFT", "SHINE", "DYNO"]
const BADGE_COLORS := [
	Color(0.95, 0.62, 0.25), Color(0.45, 0.55, 0.65), Color(0.95, 0.35, 0.55),
	Color(0.35, 0.75, 0.95), Color(0.95, 0.75, 0.25), Color(0.90, 0.30, 0.25),
	Color(0.55, 0.85, 0.95), Color(0.75, 0.45, 0.95),
]

var game  # main.gd
var _cash_l: Label
var _ips_l: Label
var _cards := []  # per-generator card controls
var _bars := []
var _buy_btns := []
var _mech_btns := []
var _tab := 0
var _tab_btns := []
var _panels := []
var _bulk_btn: Button
var _float_layer: Control
var _time := 0.0

func build() -> void:
	layer = 10
	# background
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# top bar (portrait: taller, bigger cash)
	var top := ColorRect.new()
	top.color = Color(0.10, 0.08, 0.12, 0.95)
	top.position = Vector2(0, 0)
	top.size = Vector2(720, 110)
	add_child(top)
	var accent := ColorRect.new()
	accent.color = Color(1.0, 0.62, 0.25)
	accent.position = Vector2(0, 107)
	accent.size = Vector2(720, 3)
	add_child(accent)
	_cash_l = _label("$0", 52, Vector2(20, 8), FONT_MONO, Color(0.45, 1.0, 0.55))
	add_child(_cash_l)
	var title := _label("IDLE GARAGE", 30, Vector2(0, 62), FONT_DISPLAY, Color(1.0, 0.62, 0.25))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(720, 40)
	add_child(title)
	_ips_l = _label("", 30, Vector2(720 - 220, 8), FONT_MONO, Color(1.0, 0.85, 0.55))
	_ips_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ips_l.custom_minimum_size = Vector2(200, 40)
	add_child(_ips_l)
	var ips_cap := _label("PER SEC", 18, Vector2(720 - 220, 48), FONT_HUD, Color(1, 1, 1, 0.5))
	ips_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ips_cap.custom_minimum_size = Vector2(200, 26)
	add_child(ips_cap)
	# live drift preview — HERO, much bigger (portrait)
	var preview := preload("res://scripts/race_preview.gd").new()
	preview.game = game
	preview.position = Vector2(0, 110)
	preview.size = Vector2(720, 520)
	add_child(preview)
	_preview = preview
	# tabs (6 tabs + bulk in one row)
	var tabs := ["BAYS", "CREW", "SHOP", "CARS", "AWARDS", "STATS"]
	for ti in range(6):
		var tb := _button(tabs[ti], Vector2(12 + ti * 100, 642), Vector2(96, 54), 20)
		var idx := ti
		tb.pressed.connect(func(): _set_tab(idx))
		_tab_btns.append(tb)
	# bulk toggle (right side of tab row)
	_bulk_btn = _button("x1", Vector2(720 - 100, 642), Vector2(88, 54), 20)
	_bulk_btn.pressed.connect(_cycle_bulk)
	# panels (scrollable card area)
	for ti in range(6):
		var p := ScrollContainer.new()
		p.position = Vector2(12, 708)
		p.size = Vector2(696, 560)
		p.visible = ti == 0
		add_child(p)
		_panels.append(p)
	_build_bays_panel()
	_build_crew_panel()
	_build_shop_panel()
	_build_cars_panel()
	_build_awards_panel()
	_build_stats_panel()
	# floating text layer
	_float_layer = Control.new()
	_float_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_float_layer)
	_set_tab(0)

func _label(t: String, size: int, pos: Vector2, font: Font, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_font_override("font", font)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.position = pos
	return l

func _button(t: String, pos: Vector2, size: Vector2, font := 28) -> Button:
	var b := Button.new()
	b.text = t
	b.position = pos
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font)
	b.add_theme_font_override("font", FONT_HUD)
	b.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.12, 0.18, 0.95)
	sb.border_color = Color(1.0, 0.65, 0.28, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	b.add_theme_stylebox_override("normal", sb)
	var sbp := sb.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(0.90, 0.48, 0.18, 0.98)
	sbp.border_color = Color(1.0, 0.80, 0.40, 1.0)
	b.add_theme_stylebox_override("pressed", sbp)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# disabled style
	var sbd := sb.duplicate() as StyleBoxFlat
	sbd.bg_color = Color(0.08, 0.07, 0.10, 0.9)
	sbd.border_color = Color(0.35, 0.32, 0.38, 0.6)
	b.add_theme_stylebox_override("disabled", sbd)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	add_child(b)
	return b

func _build_bays_panel() -> void:
	var p: ScrollContainer = _panels[0]
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	# tutorial hint
	_hint_label = _label("", 24, Vector2(0, 0), FONT_HUD, Color(1.0, 0.85, 0.45))
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.custom_minimum_size = Vector2(680, 36)
	vb.add_child(_hint_label)
	for i in range(8):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(680, 150)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.13, 0.11, 0.16, 0.97)
		sb.border_color = Color(1.0, 0.62, 0.25, 0.55)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(14)
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 3)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", sb)
		var tvb := VBoxContainer.new()
		tvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tvb.add_theme_constant_override("separation", 6)
		card.add_child(tvb)
		var g: Dictionary = Economy.GENERATORS[i]
		# row 1: badge + name + $/s
		var name_hb := HBoxContainer.new()
		name_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_hb.add_theme_constant_override("separation", 10)
		tvb.add_child(name_hb)
		var badge := Label.new()
		badge.text = BADGES[i]
		badge.add_theme_font_size_override("font_size", 20)
		badge.add_theme_font_override("font", FONT_HUD)
		badge.add_theme_color_override("font_color", Color(0.08, 0.07, 0.10))
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = BADGE_COLORS[i]
		bsb.set_corner_radius_all(6)
		bsb.content_margin_left = 10
		bsb.content_margin_right = 10
		bsb.content_margin_top = 4
		bsb.content_margin_bottom = 4
		badge.add_theme_stylebox_override("normal", bsb)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_hb.add_child(badge)
		var name_l := _label("%s" % g["name"], 28, Vector2(0, 0), FONT_HUD, Color(1, 1, 1))
		name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_hb.add_child(name_l)
		var ips_l := _label("", 24, Vector2(0, 0), FONT_MONO, Color(0.45, 1.0, 0.55))
		ips_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_hb.add_child(ips_l)
		# row 2: progress bar (full width)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(650, 26)
		bar.max_value = 1.0
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bbg := StyleBoxFlat.new()
		bbg.bg_color = Color(0.06, 0.06, 0.08)
		bbg.set_corner_radius_all(8)
		bar.add_theme_stylebox_override("background", bbg)
		var bfill := StyleBoxFlat.new()
		bfill.bg_color = Color(0.45, 1.0, 0.55)
		bfill.set_corner_radius_all(8)
		bar.add_theme_stylebox_override("fill", bfill)
		tvb.add_child(bar)
		# row 3: payout info + buy button
		var bot_hb := HBoxContainer.new()
		bot_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bot_hb.add_theme_constant_override("separation", 10)
		tvb.add_child(bot_hb)
		var info_l := _label("", 22, Vector2(0, 0), FONT_MONO, Color(1, 1, 1, 0.7))
		info_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bot_hb.add_child(info_l)
		var buy := _button("BUY", Vector2(0, 0), Vector2(220, 56), 26)
		remove_child(buy)
		bot_hb.add_child(buy)
		var idx := i
		buy.pressed.connect(func(): game.buy_generator(idx))
		vb.add_child(card)
		_cards.append({"bar": bar, "info": info_l, "buy": buy, "card": card, "name": name_l, "ips": ips_l})

func _build_crew_panel() -> void:
	var p: ScrollContainer = _panels[1]
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	var hint := _label("Mechanics boost their bay's income by +50%.", 26, Vector2(0, 0), FONT_HUD, Color(1, 1, 1, 0.7))
	vb.add_child(hint)
	for i in range(8):
		var g: Dictionary = Economy.GENERATORS[i]
		var m: Dictionary = Economy.MECHANICS[i]
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		var nl := _label("%s\n%s" % [m["name"], g["name"]], 26, Vector2(0, 0), FONT_HUD, Color(1, 1, 1))
		nl.custom_minimum_size = Vector2(420, 70)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(nl)
		var btn := _button("HIRE", Vector2(0, 0), Vector2(220, 70), 26)
		remove_child(btn)
		hb.add_child(btn)
		var idx := i
		btn.pressed.connect(func(): game.buy_mechanic(idx))
		vb.add_child(hb)
		_mech_btns.append({"label": nl, "btn": btn, "idx": i})

func _build_shop_panel() -> void:
	var p: ScrollContainer = _panels[2]
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	var hint := _label("Global upgrades boost ALL income.", 26, Vector2(0, 0), FONT_HUD, Color(1, 1, 1, 0.7))
	vb.add_child(hint)
	for u in range(Economy.UPGRADES.size()):
		var up: Dictionary = Economy.UPGRADES[u]
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		var nl := _label("%s\n%s" % [up["name"], up["desc"]], 26, Vector2(0, 0), FONT_HUD, Color(1, 1, 1))
		nl.custom_minimum_size = Vector2(420, 70)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(nl)
		var btn := _button("BUY", Vector2(0, 0), Vector2(220, 70), 26)
		remove_child(btn)
		hb.add_child(btn)
		var idx := u
		btn.pressed.connect(func(): game.buy_upgrade(idx))
		vb.add_child(hb)
		_shop_btns.append({"label": nl, "btn": btn, "idx": u})

var _shop_btns := []
var _preview: Control
var _hint_label: Label

func _build_cars_panel() -> void:
	var p: ScrollContainer = _panels[3]
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	_cars_vb = vb
	_refresh_cars()

var _cars_vb: VBoxContainer
var _car_buy_btns := []  # {btn, cost} for live disabled updates

func _refresh_cars() -> void:
	if not _cars_vb:
		return
	for c in _cars_vb.get_children():
		c.queue_free()
	_car_buy_btns.clear()
	# collection counter
	var owned_n := 0
	for c in game.cars_owned:
		if c:
			owned_n += 1
	var coll := _label("COLLECTION %d/%d" % [owned_n, game.cars_owned.size()], 24, Vector2(0, 0), FONT_HUD, Color(1.0, 0.75, 0.30))
	_cars_vb.add_child(coll)
	# TRACK SELECTOR
	var tkh := _label("— TRACK —", 24, Vector2(0, 0), FONT_HUD, Color(0.5, 0.8, 1.0))
	_cars_vb.add_child(tkh)
	for ti in range(Economy.TRACKS.size()):
		var tr: Dictionary = Economy.TRACKS[ti]
		var thb := HBoxContainer.new()
		thb.add_theme_constant_override("separation", 10)
		_cars_vb.add_child(thb)
		var tn := _label("%s\n+%d%% income" % [tr["name"], int((float(tr["bonus"]) - 1.0) * 100)], 24, Vector2(0, 0), FONT_HUD, Color(1, 1, 1))
		tn.custom_minimum_size = Vector2(400, 60)
		tn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		thb.add_child(tn)
		var tbtn := _button("RACE" if ti == game.track_selected else ("BUY $%s" % BigNum.fmt(tr["cost"]) if not game.tracks_owned[ti] else "SELECT"), Vector2(0, 0), Vector2(220, 60), 24)
		remove_child(tbtn)
		thb.add_child(tbtn)
		var tii := ti
		if not game.tracks_owned[ti]:
			tbtn.pressed.connect(func(): game.buy_track(tii))
			tbtn.disabled = game.cash < float(tr["cost"])
		elif ti == game.track_selected:
			tbtn.disabled = true
		else:
			tbtn.pressed.connect(func(): game.select_track(tii))
	_cars_vb.add_child(_label("— CARS —", 24, Vector2(0, 0), FONT_HUD, Color(1.0, 0.75, 0.30)))
	# style meter header
	var heat_txt := "HEAT ACTIVE! 2x income (%ds)" % int(game.heat_timer) if game.heat_timer > 0 else "Style %d/100 — full meter = 30s 2x HEAT" % int(game.style_meter)
	var hm := _label(heat_txt, 24, Vector2(0, 0), FONT_HUD, Color(1.0, 0.5, 0.2) if game.heat_timer > 0 else Color(1, 1, 1, 0.7))
	hm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cars_vb.add_child(hm)
	var sbar := ProgressBar.new()
	sbar.custom_minimum_size = Vector2(660, 18)
	sbar.max_value = 100.0
	sbar.value = game.style_meter
	sbar.show_percentage = false
	var sbg := StyleBoxFlat.new()
	sbg.bg_color = Color(0.06, 0.06, 0.08)
	sbg.set_corner_radius_all(6)
	sbar.add_theme_stylebox_override("background", sbg)
	var sfill := StyleBoxFlat.new()
	sfill.bg_color = Color(1.0, 0.5, 0.2)
	sfill.set_corner_radius_all(6)
	sbar.add_theme_stylebox_override("fill", sfill)
	_cars_vb.add_child(sbar)
	# car cards
	for ci in range(Economy.CARS.size()):
		var car: Dictionary = Economy.CARS[ci]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(680, 170)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.13, 0.11, 0.16, 0.97)
		sb.border_color = Color(1.0, 0.62, 0.25, 0.55)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(14)
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 3)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", sb)
		var cvb := VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 6)
		card.add_child(cvb)
		# name + sprite + rarity
		var nhb := HBoxContainer.new()
		nhb.add_theme_constant_override("separation", 10)
		cvb.add_child(nhb)
		var spath := "res://assets/cars/car_%02d.png" % ci
		if ResourceLoader.exists(spath):
			var tr := TextureRect.new()
			tr.texture = load(spath)
			tr.custom_minimum_size = Vector2(48, 64)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			nhb.add_child(tr)
		else:
			var dot := ColorRect.new()
			dot.color = car["color"]
			dot.custom_minimum_size = Vector2(28, 28)
			nhb.add_child(dot)
		var nl := _label(String(car["name"]), 28, Vector2(0, 0), FONT_HUD, Color(1, 1, 1))
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nhb.add_child(nl)
		var rr: String = car["rarity"]
		var rl := _label(rr.to_upper(), 20, Vector2(0, 0), FONT_HUD, Economy.RARITY_COLORS[rr])
		nhb.add_child(rl)
		# stats
		var move_names := {"drift": "Drift", "spin": "360 Spin", "reverse": "Reverse Entry", "wall": "Wall Tap"}
		var sl := _label("Income x%.1f  ·  Speed x%.2f  ·  Move: %s" % [float(car["income"]), float(car["speed"]), move_names.get(String(car["move"]), "?")],
			22, Vector2(0, 0), FONT_MONO, Color(1, 1, 1, 0.7))
		cvb.add_child(sl)
		# buy or equip
		var owned: bool = game.cars_owned[ci]
		if not owned:
			var bhb := HBoxContainer.new()
			cvb.add_child(bhb)
			var cost_l := _label("$%s" % BigNum.fmt(float(car["cost"])), 26, Vector2(0, 0), FONT_MONO, Color(1.0, 0.85, 0.30))
			cost_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bhb.add_child(cost_l)
			var buy := _button("BUY", Vector2(0, 0), Vector2(200, 56), 26)
			remove_child(buy)
			bhb.add_child(buy)
			var cidx := ci
			buy.pressed.connect(func(): game.buy_car(cidx))
			buy.disabled = game.cash < float(car["cost"])
			_car_buy_btns.append({"btn": buy, "cost": float(car["cost"]), "ci": ci})
		else:
			var ehb := HBoxContainer.new()
			ehb.add_theme_constant_override("separation", 6)
			cvb.add_child(ehb)
			var el := _label("Equip to bay:", 22, Vector2(0, 0), FONT_HUD, Color(1, 1, 1, 0.7))
			ehb.add_child(el)
			for b in range(6):
				var bb := _button(str(b + 1), Vector2(0, 0), Vector2(56, 48), 22)
				remove_child(bb)
				ehb.add_child(bb)
				var bidx := b
				var cidx2 := ci
				bb.pressed.connect(func(): game.equip_car(bidx, cidx2))
				# highlight if equipped here
				if game.cars_equipped[b] == ci:
					bb.modulate = Color(0.45, 1.0, 0.55)
		_cars_vb.add_child(card)

func _build_awards_panel() -> void:
	var p: ScrollContainer = _panels[4]
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	_awards_vb = vb
	_refresh_awards()

var _awards_vb: VBoxContainer

func _refresh_awards() -> void:
	if not _awards_vb:
		return
	for c in _awards_vb.get_children():
		c.queue_free()
	var done := 0
	for ai in range(Economy.ACHIEVEMENTS.size()):
		var a: Dictionary = Economy.ACHIEVEMENTS[ai]
		var unlocked: bool = ai in game.achievements
		if unlocked:
			done += 1
		var pct := int(round((float(a["bonus"]) - 1.0) * 100.0))
		var txt := "[X] %s — %s (+%d%%)" % [a["name"], a["desc"], pct] if unlocked else "[ ] %s — %s (+%d%%)" % [a["name"], a["desc"], pct]
		var col := Color(1.0, 0.85, 0.30) if unlocked else Color(1, 1, 1, 0.45)
		var l := _label(txt, 24, Vector2(0, 0), FONT_HUD, col)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_awards_vb.add_child(l)
	var head := _label("AWARDS  %d/%d" % [done, Economy.ACHIEVEMENTS.size()], 28, Vector2(0, 0), FONT_DISPLAY, Color(1.0, 0.85, 0.30))
	_awards_vb.add_child(head)
	_awards_vb.move_child(head, 0)

func _build_stats_panel() -> void:
	var p: ScrollContainer = _panels[5]
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)
	_stats_vb = vb
	_refresh_stats()

var _stats_vb: VBoxContainer

func _refresh_stats() -> void:
	if not _stats_vb:
		return
	for c in _stats_vb.get_children():
		c.queue_free()
	var add := func(t: String):
		var l := _label(t, 26, Vector2(0, 0), FONT_MONO, Color(1, 1, 1, 0.85))
		_stats_vb.add_child(l)
	add.call("Cash: $%s" % BigNum.fmt(game.cash))
	add.call("Lifetime: $%s" % BigNum.fmt(game.lifetime))
	add.call("All-time: $%s" % BigNum.fmt(game.total_earned))
	add.call("Income/sec: $%s" % BigNum.fmt(game.income_per_sec()))
	add.call("Reputation stars: %d (+%d%% income)" % [game.stars, game.stars * 10])
	add.call("")
	add.call("FRANCHISE (prestige): reset for stars")
	add.call("Earn $10M lifetime = 1 star (+10% forever)")
	var pb := _button("FRANCHISE NOW", Vector2(0, 0), Vector2(420, 70), 26)
	remove_child(pb)
	_stats_vb.add_child(pb)
	pb.pressed.connect(func(): game.do_prestige())

func _set_tab(t: int) -> void:
	_tab = t
	for i in range(6):
		_panels[i].visible = i == t
		# highlight active tab
		var tb: Button = _tab_btns[i]
		tb.modulate = Color(1, 1, 1) if i == t else Color(1, 1, 1, 0.55)
	if t == 3:
		_refresh_cars()
	if t == 4:
		_refresh_awards()

func _cycle_bulk() -> void:
	if game.bulk == 1:
		game.bulk = 10
	elif game.bulk == 10:
		game.bulk = 100
	elif game.bulk == 100:
		game.bulk = -1
	else:
		game.bulk = 1
	_bulk_btn.text = "MAX" if game.bulk < 0 else "x%d" % game.bulk
	refresh_generators()

func tick(dt: float) -> void:
	_time += dt
	_cash_l.text = "$%s" % BigNum.fmt(game.cash)
	_ips_l.text = "$%s" % BigNum.fmt(game.income_per_sec())
	# update generator bars (every frame)
	for i in range(8):
		var c: Dictionary = _cards[i]
		(c["bar"] as ProgressBar).value = game.progress[i]
	# refresh button affordability 2x/sec (fixes stale disabled states)
	_btn_t += dt
	if _btn_t >= 0.5:
		_btn_t = 0.0
		_refresh_button_states()
	# floating texts
	for ft in _float_layer.get_children():
		ft.position.y -= 60.0 * dt
		ft.modulate.a -= dt * 0.8
		if ft.modulate.a <= 0.0:
			ft.queue_free()

var _btn_t := 0.0

func _refresh_button_states() -> void:
	# generator buys
	for i in range(8):
		var c: Dictionary = _cards[i]
		var g: Dictionary = Economy.GENERATORS[i]
		var owned: int = game.owned[i]
		var n: int = game.bulk if game.bulk > 0 else Economy.max_affordable(float(g["cost"]), owned, game.cash)
		if n <= 0:
			n = 1
		var cost := Economy.bulk_cost(float(g["cost"]), owned, n)
		(c["buy"] as Button).disabled = game.cash < cost
	# crew
	for e in _mech_btns:
		var btn: Button = e["btn"]
		var mi: int = e["idx"]
		if not game.mechanics[mi]:
			btn.disabled = game.cash < float(Economy.MECHANICS[mi]["cost"])
	# shop
	for e in _shop_btns:
		var u: int = e["idx"]
		var btn2: Button = e["btn"]
		if u not in game.upgrades_bought:
			btn2.disabled = game.cash < float(Economy.UPGRADES[u]["cost"])
	# car buys
	for e in _car_buy_btns:
		var cb: Button = e["btn"]
		var ci: int = e["ci"]
		if not game.cars_owned[ci]:
			cb.disabled = game.cash < float(e["cost"])

func float_text(gen_idx: int, amount: float) -> void:
	var l := _label("+$%s" % BigNum.fmt(amount), 28, Vector2(0, 0), FONT_MONO, Color(0.45, 1.0, 0.55))
	# position near the generator card (portrait: cards start at y=708)
	l.position = Vector2(300, 760 + gen_idx * 40)
	_float_layer.add_child(l)

func refresh_all() -> void:
	refresh_generators()
	refresh_crew()
	refresh_shop()
	_refresh_awards()
	_refresh_stats()
	_update_hint()

func refresh_generators() -> void:
	var gm: float = game.global_mult()
	var pm: float = game.prestige_mult()
	for i in range(8):
		var g: Dictionary = Economy.GENERATORS[i]
		var c: Dictionary = _cards[i]
		var owned: int = game.owned[i]
		var unlocked: bool = game.lifetime >= float(g["unlock"]) or owned > 0
		(c["card"] as Control).visible = unlocked
		if not unlocked:
			var nxt: float = g["unlock"]
			(c["name"] as Label).text = "LOCKED — $%s lifetime" % BigNum.fmt(nxt)
			(c["ips"] as Label).text = ""
			(c["info"] as Label).text = ""
			(c["buy"] as Button).disabled = true
			(c["buy"] as Button).text = "LOCKED"
			continue
		(c["name"] as Label).text = "%s  x%d" % [g["name"], owned]
		var bm: float = game.bay_mult(i)
		var ips: float = Economy.income_per_sec(i, owned, gm, pm) * bm
		var pay: float = Economy.payout_per_cycle(i, owned, gm, pm) * bm
		(c["ips"] as Label).text = "$%s/s" % BigNum.fmt(ips)
		(c["info"] as Label).text = "$%s / %s" % [BigNum.fmt(pay), BigNum.fmt_time(float(g["time"]))]
		var buy: Button = c["buy"]
		var n: int = game.bulk if game.bulk > 0 else Economy.max_affordable(float(g["cost"]), owned, game.cash)
		if n <= 0:
			n = 1
		var cost := Economy.bulk_cost(float(g["cost"]), owned, n)
		var blabel := "BUY x%d\n$%s" % [n, BigNum.fmt(cost)] if game.bulk > 0 else "BUY MAX (%d)\n$%s" % [n, BigNum.fmt(cost)]
		buy.text = blabel
		buy.disabled = game.cash < cost

func refresh_crew() -> void:
	for i in range(8):
		var e: Dictionary = _mech_btns[i]
		var btn: Button = e["btn"]
		if game.mechanics[i]:
			btn.text = "HIRED ✓"
			btn.disabled = true
		else:
			var cost: float = Economy.MECHANICS[i]["cost"]
			btn.text = "HIRE $%s" % BigNum.fmt(cost)
			btn.disabled = game.cash < cost

func refresh_shop() -> void:
	for e in _shop_btns:
		var u: int = e["idx"]
		var btn: Button = e["btn"]
		if u in game.upgrades_bought:
			btn.text = "OWNED ✓"
			btn.disabled = true
		else:
			var cost: float = Economy.UPGRADES[u]["cost"]
			btn.text = "BUY $%s" % BigNum.fmt(cost)
			btn.disabled = game.cash < cost

func _update_hint() -> void:
	if not _hint_label:
		return
	# contextual tutorial: guide the first 5 minutes
	if game.owned[0] <= 1 and game.cash < 50.0 and not game.mechanics[0]:
		_hint_label.text = "Your Oil Bay works on its own. Save up, then buy more bays!"
	elif not game.mechanics[0] and game.cash >= 150.0:
		_hint_label.text = "Hire MARCO in the CREW tab — +50% Oil Bay income."
	elif game.owned[1] == 0 and game.lifetime >= 500.0:
		_hint_label.text = "Tire Shop unlocked! Buy it for bigger payouts."
	elif game.income_per_sec() > 0 and game.upgrades_bought.is_empty() and game.cash >= 1000.0:
		_hint_label.text = "Check the SHOP tab — global upgrades boost ALL income."
	else:
		_hint_label.text = ""

func achievement_popup(ach_name: String, bonus: float) -> void:
	# toast at top of screen
	var toast := PanelContainer.new()
	toast.custom_minimum_size = Vector2(600, 90)
	toast.position = Vector2(60, 200)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.08, 0.97)
	sb.border_color = Color(1.0, 0.85, 0.30, 0.95)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	toast.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	toast.add_child(vb)
	var t := _label("ACHIEVEMENT UNLOCKED", 20, Vector2(0, 0), FONT_HUD, Color(1.0, 0.85, 0.30))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.custom_minimum_size = Vector2(560, 28)
	vb.add_child(t)
	var pct := int(round((bonus - 1.0) * 100.0))
	var n := _label("%s  (+%d%% income)" % [ach_name, pct], 26, Vector2(0, 0), FONT_HUD, Color(1, 1, 1))
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.custom_minimum_size = Vector2(560, 36)
	vb.add_child(n)
	add_child(toast)
	# auto-dismiss after 3s
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(toast.queue_free)

func heat_popup() -> void:
	var toast := PanelContainer.new()
	toast.custom_minimum_size = Vector2(600, 80)
	toast.position = Vector2(60, 300)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.08, 0.05, 0.97)
	sb.border_color = Color(1.0, 0.4, 0.1, 0.95)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	toast.add_theme_stylebox_override("panel", sb)
	var t := _label("HEAT! 2x INCOME FOR 30s", 30, Vector2(0, 0), FONT_DISPLAY, Color(1.0, 0.5, 0.15))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.custom_minimum_size = Vector2(560, 50)
	toast.add_child(t)
	add_child(toast)
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(toast.queue_free)

func show_offline_popup(gained: float, away_sec: float) -> void:
	# dim background
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	# popup panel
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 320)
	panel.position = Vector2(80, 400)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.15, 0.98)
	sb.border_color = Color(1.0, 0.62, 0.25, 0.9)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	var t := _label("WELCOME BACK!", 36, Vector2(0, 0), FONT_DISPLAY, Color(1.0, 0.62, 0.25))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.custom_minimum_size = Vector2(500, 50)
	vb.add_child(t)
	var away_str := BigNum.fmt_time(away_sec)
	var msg := _label("Your crew earned while you were away:\n%s  (%s)" % [BigNum.fmt(gained), away_str], 28, Vector2(0, 0), FONT_MONO, Color(0.45, 1.0, 0.55))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.custom_minimum_size = Vector2(500, 90)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(msg)
	var btn := _button("COLLECT", Vector2(0, 0), Vector2(500, 64), 30)
	remove_child(btn)
	vb.add_child(btn)
	btn.pressed.connect(func():
		dim.queue_free()
		panel.queue_free())
	add_child(panel)
