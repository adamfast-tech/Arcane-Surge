class_name HubTile
extends Button
## Tuile « diorama » de Havre-Aube : le décor en pixel art de la salle (RoomArt), son gardien en volume qui respire
## (Durgan à la Forge, Aldric à l'Armurerie, Ossian à la Bibliothèque…), des particules d'ambiance (braises,
## poussière dorée, lucioles, éclats…), un badge quand quelque chose attend, et un geste du gardien au toucher
## avant d'ouvrir la salle.

signal chosen

const STAGGER := 3 ## images d'écran entre l'apparition de deux gardiens (le premier rendu coûte)

static var _order := 0

var art_kind := "forge" ## décor (RoomArt.scene)
var art_tint := Color.WHITE
var title_text := ""
var line_text := ""
var line_col := UiTheme.MUTED
var icon_name := "star"
var accent := UiTheme.TEAL
var big := false
var badge := "" ## pastille en haut à droite ("" : aucune)
var locked := false
var keepers: Array = [] ## [HeroModel, yaw, x (part de la largeur), lumière]
var particles := "" ## embers, dust, fireflies, sparks, echoes, motes, beam, ""
var pedestal := false ## socle lumineux sous le gardien (Équipement)
var gesture := "cast" ## geste du gardien au toucher

var _figs: Array = []
var _wait := 0
var _frame: Panel
var _fx: Control
var _t := 0.0
var _parts: Array = []
var _rng := RandomNumberGenerator.new()
var _pressing := false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	clip_contents = true
	custom_minimum_size = Vector2(0, 210 if big else 172)
	for s in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
		add_theme_stylebox_override(s, UiTheme.box(Color(0.03, 0.04, 0.07), Color(0, 0, 0, 0), 14, 0, 0))
	_rng.seed = hash(title_text)
	# Le décor de la salle.
	var art := TextureRect.new()
	art.texture = RoomArt.scene(art_kind, Vector2i(170, 108 if big else 92))
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = art_tint if not locked else Color(0.42, 0.42, 0.5)
	add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Particules et socle (dessinés).
	_fx = Control.new()
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Ombre en bas pour le texte.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(0.02, 0.03, 0.06, 0.0), Color(0.02, 0.03, 0.06, 0.35), Color(0.02, 0.03, 0.06, 0.92)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	var shade := TextureRect.new()
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Texte : icône et nom, puis la ligne d'état.
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	v.offset_left = 14
	v.offset_right = -10
	v.offset_top = -64 if big else -58
	v.offset_bottom = -10
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	h.add_child(UiTheme.icon_rect("lock" if locked else icon_name, 26 if big else 22, accent if not locked else UiTheme.MUTED))
	var tl := UiTheme.title(title_text, 24 if big else 19, UiTheme.TEXT if not locked else UiTheme.MUTED)
	tl.add_theme_constant_override("outline_size", 6)
	tl.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.95))
	h.add_child(tl)
	var ll := UiTheme.label(line_text, 16 if big else 14, line_col if not locked else UiTheme.MUTED)
	ll.add_theme_constant_override("outline_size", 5)
	ll.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.95))
	ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ll.custom_minimum_size = Vector2(10, 0)
	v.add_child(ll)
	# Pastille.
	if badge != "" and not locked:
		var bp := PanelContainer.new()
		bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bp.add_theme_stylebox_override("panel", UiTheme.box(Color(accent.darkened(0.7), 0.95), accent, 12, 2, 6))
		var bl := UiTheme.label(badge, 14, accent.lightened(0.2))
		bp.add_child(bl)
		add_child(bp)
		bp.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		bp.offset_left = -float(14 + badge.length() * 9)
		bp.offset_right = -8
		bp.offset_top = 8
		bp.offset_bottom = 36
		bp.set_meta("pulse", true)
	# Cadre, par-dessus tout : il s'éclaire au survol et à l'appui.
	_frame = Panel.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_frame(0)
	mouse_entered.connect(func() -> void: _set_frame(1))
	mouse_exited.connect(func() -> void: _set_frame(0))
	disabled = locked
	pressed.connect(_on_pressed)
	_wait = _order * STAGGER
	_order += 1
	set_process(true)


func _set_frame(state: int) -> void:
	if _frame == null:
		return
	var col := accent if not locked else UiTheme.MUTED
	var a: float = [0.55, 0.95, 1.0][state]
	var w: int = [2, 3, 3][state]
	_frame.add_theme_stylebox_override("panel", UiTheme.box(Color(0, 0, 0, 0), Color(UiTheme.GOLD if state == 2 else col, a), 14, w, 0))


static func reset_order() -> void:
	_order = 0


func _process(delta: float) -> void:
	_t += delta
	# Les gardiens apparaissent l'un après l'autre (chaque premier rendu coûte).
	if _figs.size() < keepers.size():
		_wait -= 1
		if _wait <= 0:
			_add_keeper(keepers[_figs.size()])
			_wait = STAGGER
	_place_keepers()
	_tick_particles(delta)
	_fx.queue_redraw()
	for ch in get_children():
		if ch is PanelContainer and ch.has_meta("pulse"):
			(ch as Control).modulate.a = 0.75 + 0.25 * sin(_t * 4.0)


func _add_keeper(k: Array) -> void:
	var tt := HeroTurntable.new()
	tt.interactive = false
	tt.px_scale = 4 if big else 3
	tt.light = str(k[3]) if k.size() > 3 else "jour"
	tt.yaw = float(k[1])
	tt.setup_model(k[0])
	if locked:
		tt.modulate = Color(0.4, 0.4, 0.48)
	add_child(tt)
	# Sous le texte et le cadre.
	move_child(tt, 3)
	tt.set_meta("x", float(k[2]))
	_figs.append(tt)


func _place_keepers() -> void:
	for tt in _figs:
		var t: HeroTurntable = tt
		t.size = t.custom_minimum_size
		var x := size.x * float(t.get_meta("x"))
		t.position = Vector2(x - t.size.x * 0.5, size.y - 18.0 - t.size.y)


func _on_pressed() -> void:
	if _pressing:
		return
	_pressing = true
	_set_frame(2)
	Snd.click()
	for tt in _figs:
		(tt as HeroTurntable).play(gesture)
	_burst()
	# Le geste, puis la salle.
	get_tree().create_timer(0.32).timeout.connect(_emit_chosen)


func _emit_chosen() -> void:
	_pressing = false
	_set_frame(0)
	chosen.emit()


# ---------------------------------------------------------------- particules

func _spawn() -> Dictionary:
	var w := maxf(size.x, 10.0)
	var h := maxf(size.y, 10.0)
	match particles:
		"embers":
			return {"p": Vector2(_rng.randf_range(w * 0.15, w * 0.6), h - 20.0), "v": Vector2(_rng.randf_range(-8, 8), _rng.randf_range(-50, -25)), "life": 0.0, "max": _rng.randf_range(1.2, 2.4), "c": Color("ffb050"), "s": 2.0}
		"dust", "motes":
			return {"p": Vector2(_rng.randf() * w, _rng.randf() * h * 0.8), "v": Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-6, 4)), "life": 0.0, "max": _rng.randf_range(2.0, 4.0), "c": Color("ffe8a0") if particles == "dust" else Color("fff6d8"), "s": 2.0}
		"fireflies":
			return {"p": Vector2(_rng.randf() * w, _rng.randf_range(h * 0.3, h * 0.85)), "v": Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-6, 6)), "life": 0.0, "max": _rng.randf_range(2.0, 3.5), "c": Color("d8ff7a"), "s": 2.0}
		"sparks", "echoes":
			return {"p": Vector2(_rng.randf_range(w * 0.2, w * 0.8), h - 10.0), "v": Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-40, -20)), "life": 0.0, "max": _rng.randf_range(1.5, 3.0), "c": Color("8ff0ff") if particles == "sparks" else Color("c8a0ff"), "s": 2.0}
		"beam":
			return {"p": Vector2(w * 0.68 + _rng.randf_range(-24, 24), h - 24.0), "v": Vector2(0, _rng.randf_range(-36, -18)), "life": 0.0, "max": _rng.randf_range(1.2, 2.2), "c": accent.lightened(0.3), "s": 2.0}
	return {}


func _tick_particles(delta: float) -> void:
	if particles == "" or locked:
		return
	var want := 14
	while _parts.size() < want and _rng.randf() < 0.3:
		var p := _spawn()
		if p.is_empty():
			break
		_parts.append(p)
	for p in _parts.duplicate():
		p["life"] = float(p["life"]) + delta
		if float(p["life"]) > float(p["max"]):
			_parts.erase(p)
			continue
		p["p"] = (p["p"] as Vector2) + (p["v"] as Vector2) * delta
		if particles == "fireflies" or particles == "dust" or particles == "motes":
			p["v"] = (p["v"] as Vector2).rotated(delta * 1.5)


func _burst() -> void:
	for i in range(14):
		var c := size * Vector2(0.65, 0.75)
		_parts.append({"p": c, "v": Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(40, 140), "life": 0.0, "max": 0.6, "c": UiTheme.GOLD, "s": 3.0})


func _draw_fx() -> void:
	if pedestal and not locked:
		var c := Vector2(size.x * 0.68, size.y - 20.0)
		var pulse := 0.8 + 0.2 * sin(_t * 2.5)
		for k in range(5):
			var r := (70.0 - float(k) * 12.0) * pulse
			_ellipse(c, r, r * 0.26, Color(accent, 0.07 + 0.04 * float(k)))
		_fx.draw_rect(Rect2(c.x - 16.0, 0, 32.0, c.y), Color(accent, 0.05 + 0.03 * pulse))
	for p in _parts:
		var k2 := float(p["life"]) / float(p["max"])
		var a := sin(k2 * PI)
		if particles == "fireflies":
			a *= 0.5 + 0.5 * sin(_t * 9.0 + float(p["max"]) * 10.0)
		var s := float(p["s"])
		_fx.draw_rect(Rect2((p["p"] as Vector2) - Vector2(s, s) * 0.5, Vector2(s, s)), Color(p["c"], a))


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(28):
		var a := float(i) / 28.0 * TAU
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	_fx.draw_colored_polygon(pts, col)
