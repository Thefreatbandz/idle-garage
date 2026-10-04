extends CanvasLayer
## Idle Garage UI — 2D, phone-friendly.

const FONT_DISPLAY := preload("res://assets/fonts/Orbitron.ttf")
const FONT_HUD := preload("res://assets/fonts/Rajdhani.ttf")
const FONT_MONO := preload("res://assets/fonts/ShareTechMono.ttf")

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
	# top bar
	var top := ColorRect.new()
	top.color = Color(0.10, 0.08, 0.12, 0.95)
	top.position = Vector2(0, 0)
	top.size = Vector2(1280, 84)
	add_child(top)
	var accent := ColorRect.new()
	accent.color = Color(1.0, 0.62, 0.25)
	accent.position = Vector2(0, 82)
	accent.size = Vector2(1280, 3)
	add_child(accent)
	_cash_l = _label("$0", 44, Vector2(24, 8), FONT_MONO, Color(0.45, 1.0, 0.55))
	add_child(_cash_l)
	var title := _label("IDLE GARAGE", 34, Vector2(0, 16), FONT_DISPLAY, Color(1.0, 0.62, 0.25))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(1280, 50)
	add_child(title)
	_ips_l = _label("", 24, Vector2(1280 - 324, 14), FONT_MONO, Color(1.0, 0.85, 0.55))
	_ips_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ips_l.custom_minimum_size = Vector2(300, 36)
	add_child(_ips_l)
	var ips_cap := _label("PER SEC", 16, Vector2(1280 - 324, 50), FONT_HUD, Color(1, 1, 1, 0.5))
	ips_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ips_cap.custom_minimum_size = Vector2(300, 24)
	add_child(ips_cap)
	# garage scene strip (animated 2D)
	_build_garage_scene(Vector2(0, 85), Vector2(1280, 220))
	# tabs
	var tabs := ["BAYS", "CREW", "SHOP", "STATS"]
	for ti in range(4):
		var tb := _button(tabs[ti], Vector2(24 + ti * 170, 315), Vector2(160, 52), 26)
		var idx := ti
		tb.pressed.connect(func(): _set_tab(idx))
		_tab_btns.append(tb)
	# bulk toggle
	_bulk_btn = _button("x1", Vector2(1280 - 184, 315), Vector2(160, 52), 26)
	_bulk_btn.pressed.connect(_cycle_bulk)
	# panels
	for ti in range(4):
		var p := ScrollContainer.new()
		p.position = Vector2(16, 378)
		p.size = Vector2(1248, 326)
		p.visible = ti == 0
		add_child(p)
		_panels.append(p)
	_build_bays_panel()
	_build_crew_panel()
	_build_shop_panel()
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
	sb.bg_color = Color(0.14, 0.11, 0.16, 0.9)
	sb.border_color = Color(1.0, 0.62, 0.25, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	b.add_theme_stylebox_override("normal", sb)
	var sbp := sb.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(0.85, 0.45, 0.16, 0.95)
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

func _build_garage_scene(pos: Vector2, size: Vector2) -> void:
	# simple animated 2D garage: floor, lifts, cars appear as you unlock
	var scene := Control.new()
	scene.position = pos
	scene.size = size
	add_child(scene)
	var floor_c := ColorRect.new()
	floor_c.color = Color(0.13, 0.12, 0.16)
	floor_c.position = Vector2(0, 140)
	floor_c.size = Vector2(1280, 80)
	scene.add_child(floor_c)
	# neon sign
	var sign := _label("IDLE GARAGE", 40, Vector2(0, 18), FONT_DISPLAY, Color(1.0, 0.45, 0.75))
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.custom_minimum_size = Vector2(1280, 60)
	scene.add_child(sign)
	# lifts (one per generator, appear when unlocked)
	_lift_nodes.clear()
	_car_nodes.clear()
	for i in range(6):
		var lift := ColorRect.new()
		lift.name = "Lift%d" % i
		lift.color = Color(0.20, 0.18, 0.24)
		lift.position = Vector2(80 + i * 195, 110)
		lift.size = Vector2(150, 90)
		lift.visible = false
		scene.add_child(lift)
		_lift_nodes.append(lift)
		var car := ColorRect.new()
		car.name = "Car%d" % i
		var cols := [Color(0.85, 0.85, 0.88), Color(0.25, 0.55, 0.95),
			Color(0.95, 0.35, 0.55), Color(0.95, 0.75, 0.25),
			Color(0.35, 0.90, 0.45), Color(0.90, 0.30, 0.25)]
		car.color = cols[i]
		car.position = Vector2(95 + i * 195, 130)
		car.size = Vector2(120, 40)
		car.visible = false
		scene.add_child(car)
		_car_nodes.append(car)

func _build_bays_panel() -> void:
	var p: ScrollContainer = _panels[0]
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	for i in range(6):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(1220, 108)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.11, 0.10, 0.14, 0.95)
		sb.border_color = Color(1.0, 0.62, 0.25, 0.4)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", sb)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		card.add_child(hb)
		var g: Dictionary = Economy.GENERATORS[i]
		# tap area (left): icon + name + progress
		var tap := Button.new()
		tap.custom_minimum_size = Vector2(760, 92)
		tap.focus_mode = Control.FOCUS_NONE
		var tbs := StyleBoxFlat.new()
		tbs.bg_color = Color(0, 0, 0, 0)
		tap.add_theme_stylebox_override("normal", tbs)
		tap.add_theme_stylebox_override("hover", tbs)
		tap.add_theme_stylebox_override("pressed", tbs)
		tap.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var idx := i
		tap.pressed.connect(func(): game.tap_generator(idx))
		var tvb := VBoxContainer.new()
		tvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tap.add_child(tvb)
		var name_l := _label("%s %s" % [g["icon"], g["name"]], 30, Vector2(0, 0), FONT_HUD, Color(1, 1, 1))
		name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tvb.add_child(name_l)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(740, 22)
		bar.max_value = 1.0
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bbg := StyleBoxFlat.new()
		bbg.bg_color = Color(0.06, 0.06, 0.08)
		bbg.set_corner_radius_all(6)
		bar.add_theme_stylebox_override("background", bbg)
		var bfill := StyleBoxFlat.new()
		bfill.bg_color = Color(0.45, 1.0, 0.55)
		bfill.set_corner_radius_all(6)
		bar.add_theme_stylebox_override("fill", bfill)
		tvb.add_child(bar)
		var info_l := _label("", 22, Vector2(0, 0), FONT_MONO, Color(1, 1, 1, 0.7))
		info_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tvb.add_child(info_l)
		hb.add_child(tap)
		# buy button (right)
		var buy := _button("BUY", Vector2(0, 0), Vector2(400, 92), 30)
		buy.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# reparent buy into hb (was added to self by _button)
		remove_child(buy)
		hb.add_child(buy)
		buy.pressed.connect(func(): game.buy_generator(idx))
		vb.add_child(card)
		_cards.append({"tap": tap, "bar": bar, "info": info_l, "buy": buy, "card": card, "name": name_l})

func _build_crew_panel() -> void:
	var p: ScrollContainer = _panels[1]
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	var hint := _label("Hire a mechanic to automate a bay forever.", 26, Vector2(0, 0), FONT_HUD, Color(1, 1, 1, 0.7))
	vb.add_child(hint)
	for i in range(6):
		var g: Dictionary = Economy.GENERATORS[i]
		var m: Dictionary = Economy.MECHANICS[i]
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		var nl := _label("👨‍🔧 %s\n%s" % [m["name"], g["name"]], 26, Vector2(0, 0), FONT_HUD, Color(1, 1, 1))
		nl.custom_minimum_size = Vector2(760, 70)
		hb.add_child(nl)
		var btn := _button("HIRE", Vector2(0, 0), Vector2(400, 70), 28)
		remove_child(btn)
		hb.add_child(btn)
		var idx := i
		btn.pressed.connect(func(): game.buy_mechanic(idx))
		vb.add_child(hb)
		_mech_btns.append({"label": nl, "btn": btn})

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
		nl.custom_minimum_size = Vector2(760, 70)
		hb.add_child(nl)
		var btn := _button("BUY", Vector2(0, 0), Vector2(400, 70), 28)
		remove_child(btn)
		hb.add_child(btn)
		var idx := u
		btn.pressed.connect(func(): game.buy_upgrade(idx))
		vb.add_child(hb)
		_shop_btns.append({"label": nl, "btn": btn, "idx": u})

var _shop_btns := []
var _lift_nodes := []
var _car_nodes := []

func _build_stats_panel() -> void:
	var p: ScrollContainer = _panels[3]
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
	add.call("💰 Cash: $%s" % BigNum.fmt(game.cash))
	add.call("📈 Lifetime: $%s" % BigNum.fmt(game.lifetime))
	add.call("🏆 All-time: $%s" % BigNum.fmt(game.total_earned))
	add.call("⚡ Income/sec: $%s" % BigNum.fmt(game.income_per_sec()))
	add.call("⭐ Reputation stars: %d (+%d%% income)" % [game.stars, game.stars * 10])
	add.call("")
	add.call("FRANCHISE (prestige): reset for stars")
	add.call("Earn $10M lifetime = 1 star (+10% forever)")
	var pb := _button("FRANCHISE NOW", Vector2(0, 0), Vector2(400, 70), 28)
	remove_child(pb)
	_stats_vb.add_child(pb)
	pb.pressed.connect(func(): game.do_prestige())

func _set_tab(t: int) -> void:
	_tab = t
	for i in range(4):
		_panels[i].visible = i == t
		# highlight active tab
		var tb: Button = _tab_btns[i]
		tb.modulate = Color(1, 1, 1) if i == t else Color(1, 1, 1, 0.55)

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
	# update generator bars + buy buttons (cheap enough every frame)
	for i in range(6):
		var c: Dictionary = _cards[i]
		(c["bar"] as ProgressBar).value = game.progress[i]
	# floating texts
	for ft in _float_layer.get_children():
		ft.position.y -= 60.0 * dt
		ft.modulate.a -= dt * 0.8
		if ft.modulate.a <= 0.0:
			ft.queue_free()

func float_text(gen_idx: int, amount: float) -> void:
	var l := _label("+$%s" % BigNum.fmt(amount), 28, Vector2(0, 0), FONT_MONO, Color(0.45, 1.0, 0.55))
	# position near the generator card
	l.position = Vector2(400 + gen_idx * 40, 480)
	_float_layer.add_child(l)

func refresh_all() -> void:
	refresh_generators()
	refresh_crew()
	refresh_shop()
	_refresh_stats()
	_update_garage_scene()

func refresh_generators() -> void:
	var gm: float = game.global_mult()
	var pm: float = game.prestige_mult()
	for i in range(6):
		var g: Dictionary = Economy.GENERATORS[i]
		var c: Dictionary = _cards[i]
		var owned: int = game.owned[i]
		var unlocked: bool = game.lifetime >= float(g["unlock"]) or owned > 0
		(c["card"] as Control).visible = unlocked
		if not unlocked:
			var nxt: float = g["unlock"]
			(c["name"] as Label).text = "🔒 Unlock at $%s lifetime" % BigNum.fmt(nxt)
			continue
		(c["name"] as Label).text = "%s %s  x%d" % [g["icon"], g["name"], owned]
		var ips := Economy.income_per_sec(i, owned, gm, pm)
		var pay := Economy.payout_per_cycle(i, owned, gm, pm)
		(c["info"] as Label).text = "$%s/s  ·  $%s / %s" % [BigNum.fmt(ips), BigNum.fmt(pay), BigNum.fmt_time(float(g["time"]))]
		var buy: Button = c["buy"]
		var n: int = game.bulk if game.bulk > 0 else Economy.max_affordable(float(g["cost"]), owned, game.cash)
		if n <= 0:
			n = 1
		var cost := Economy.bulk_cost(float(g["cost"]), owned, n)
		var blabel := "BUY x%d\n$%s" % [n, BigNum.fmt(cost)] if game.bulk > 0 else "BUY MAX (%d)\n$%s" % [n, BigNum.fmt(cost)]
		buy.text = blabel
		buy.disabled = game.cash < cost

func refresh_crew() -> void:
	for i in range(6):
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

func show_offline_popup(gained: float, away_sec: float) -> void:
	# dim background
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	# popup panel
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 320)
	panel.position = Vector2(360, 200)
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
	var t := _label("WELCOME BACK! 🎉", 36, Vector2(0, 0), FONT_DISPLAY, Color(1.0, 0.62, 0.25))
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

func _update_garage_scene() -> void:
	# show lifts/cars for unlocked generators
	for i in range(6):
		var g: Dictionary = Economy.GENERATORS[i]
		var unlocked: bool = game.lifetime >= float(g["unlock"]) or game.owned[i] > 0
		if i < _lift_nodes.size():
			(_lift_nodes[i] as Control).visible = unlocked
			(_car_nodes[i] as Control).visible = unlocked
