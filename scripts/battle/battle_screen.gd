class_name BattleScreen
extends Control
## Écran de combat : arène pixel-art + HUD (portrait ou paysage selon la fenêtre),
## commandes tactiles / souris / clavier, fenêtres Échos, pause et fin de partie.

signal exit_requested(dest: String)
signal restart_requested

const TOP_H := 150.0
const BOTTOM_H := 350.0
const TOP_H_LAND := 92.0

var level_id := "z01_l08"
var solo := false
var sim: BattleSim
var arena: Arena3D
var backdrop: TextureRect
var flash_rect: ColorRect
var vp: SubViewport
var arena_rect: TextureRect
var hud: Control
var overlay: Control
var auto_fire := false
var paused := false
var aiming := ""

var _level: Dictionary = {}
var _landscape := false
var _built := false
var _k := 2
var _acc := 0.0
var _pointer_down := false
var _hover_in := false
var _hover := Vector2(-100.0, -100.0)
var _echo_open := false
var _end_open := false
var _toast_t := 0.0
var _side_w := 360.0
var _bottom_h := BOTTOM_H ## hauteur réelle du panneau du bas (selon son contenu)
var _bottom_panel: PanelContainer

# Références du HUD (reconstruites à chaque changement d'orientation)
var nexus_bar: ProgressBar
var nexus_info: Label
var obj_title: Label
var _opts: Dictionary = {}
var _rewards: Dictionary = {}
var barrier_bar: ProgressBar
var barrier_label: Label
var surge_bar: ProgressBar
var surge_label: Label
var mana_bar: ProgressBar
var mana_label: Label
var spell_btns: Array[Button] = []
var champ_btn: Button
var ult_btn: Button
var bot_btns: Array[Button] = []
var order_btns: Array = []
var bot_mana_bars: Array[ProgressBar] = []
var echo_label: Label
var journal_label: Label
var hint_label: Label
var toast_label: Label

# Répliques des compagnons pendant le combat (data/dialogues, « barks »).
const BARK_TIME := 3.6
const BARK_GAP := 7.0
var bark_panel: PanelContainer
var bark_portrait: TextureRect
var bark_name: Label
var bark_text: Label
var _bark_t := 0.0
var _bark_cd := 2.0
var _bark_side := "left"
var _barks_fired: Dictionary = {}
var _bark_phase := 0
var _bark_rng := RandomNumberGenerator.new()
var _present: Array[String] = []
var _pending_note := ""

# Mode « Tiroir » (docs/design/20-tiroir-de-sorts.md) : les cases affichent les écoles ; appui maintenu
# sur une école -> ses sorts dans les mêmes cases ; relâcher sur un sort le choisit (ou glisser
# jusqu'à l'arène pour le lancer aussitôt) ; après le lancer, retour aux écoles.
const DRAWER := ["feu", "givre", "foudre", "nature", "ombre", "arcane", "terre", "lumiere"]
const DRAWER_INFO := {
	"feu": ["Feu", "boule_de_feu", "FF9B4A"], "givre": ["Givre", "pluie_de_givre", "9FE3FF"],
	"foudre": ["Foudre", "eclair_chaine", "F0D23C"], "nature": ["Nature", "racines", "8FD16A"],
	"ombre": ["Ombre", "vortex_ombre", "8E62E0"], "arcane": ["Arcane", "onde_arcanique", "B07CFF"],
	"terre": ["Terre", "seisme", "C8A070"], "lumiere": ["Lumière", "purifier", "FFF6C8"],
}
const HOLD_MOVE := 12.0
var _mode := "deck"
var _by_school: Dictionary = {}
var _drawer := ""
var _hold := false
var _hold_moved := false
var _hold_start := Vector2.ZERO
var _hold_cell := -1
var _drag_spell := ""
var _hover_cell := -1
var _cell_ids: Array[String] = []


func configure(id: String, solo_mode: bool, opts: Dictionary = {}) -> void:
	_mode = str(opts.get("spell_mode", "deck"))
	_opts = opts
	level_id = id
	solo = solo_mode


func _exit_tree() -> void:
	WorldArt.zone = 1
	# Casse la référence circulaire simulation <-> terrain (sinon fuite mémoire).
	if sim != null:
		sim.terrain.sim = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level = GameData.level(level_id)
	sim = BattleSim.new()
	var o := _opts.duplicate()
	o["solo"] = solo
	sim.setup(_level, GameData.party(), int(Time.get_ticks_usec() % 1000000), o)

	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(360, 640)
	add_child(vp)
	arena = Arena3D.new()
	vp.add_child(arena)
	WorldArt.zone = int(_level.get("zone", 1))
	if _opts.has("look"):
		SpriteAtlas.set_player(_opts["look"], str(_opts.get("player_race", "elfe")))
	arena.setup(sim, UiTheme.font(), bool(_opts.get("healed", false)))
	if _mode == "drawer":
		for id in sim.player().spells:
			var sd: Dictionary = sim.spells_db[id]
			var sc := str(sd.get("school", "lumiere"))
			if not _by_school.has(sc):
				_by_school[sc] = []
			(_by_school[sc] as Array).append(id)
	for c in sim.casters:
		if c.is_bot and c.id != "":
			_present.append(c.id)
	_bark_rng.randomize()
	_pending_note = " ".join(sim.story_notes)

	backdrop = TextureRect.new()
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	arena_rect = TextureRect.new()
	arena_rect.texture = vp.get_texture()
	arena_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena_rect.stretch_mode = TextureRect.STRETCH_SCALE
	arena_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arena_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	arena_rect.gui_input.connect(_on_arena_input)
	arena_rect.mouse_exited.connect(_on_arena_exit)
	add_child(arena_rect)
	flash_rect = ColorRect.new()
	flash_rect.color = Color(1.0, 0.95, 0.85, 0.0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_rect)

	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	resized.connect(_relayout)
	_relayout.call_deferred()


# ---------------------------------------------------------------- mise en page

func _relayout() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	var landscape := size.x > size.y * 1.1
	if landscape != _landscape or not _built:
		_landscape = landscape
		_built = true
		_build_hud()
		# Mesure du panneau du bas une fois ses enfants dimensionnés.
		_relayout.call_deferred()
	var avail: Rect2
	if _landscape:
		_side_w = clampf(size.x * 0.2, 320.0, 440.0)
		avail = Rect2(_side_w, TOP_H_LAND, size.x - 2.0 * _side_w, size.y - TOP_H_LAND)
	else:
		# Le panneau du bas grandit si son contenu ne tient pas dans BOTTOM_H (petits écrans).
		if _bottom_panel != null and is_instance_valid(_bottom_panel):
			var need := maxf(BOTTOM_H, _bottom_panel.get_combined_minimum_size().y + 2.0)
			if absf(need - _bottom_h) > 1.0:
				_bottom_h = need
				_bottom_panel.offset_top = -_bottom_h
				_relayout.call_deferred()
		avail = Rect2(0.0, TOP_H, size.x, size.y - TOP_H - _bottom_h)
	_place_arena(avail)
	_update_hud()


func _place_arena(avail: Rect2) -> void:
	var fit_w := minf(avail.size.x, avail.size.y * 9.0 / 16.6)
	_k = maxi(1, int(floor(fit_w / 270.0)))
	var vs := Vector2i(maxi(64, int(avail.size.x / _k)), maxi(64, int(avail.size.y / _k)))
	vp.size = vs
	arena.fit_camera(vs)
	var shown := Vector2(vs * _k)
	arena_rect.position = (avail.position + (avail.size - shown) * 0.5).floor()
	arena_rect.size = shown
	backdrop.texture = WorldArt.backdrop(vs)
	backdrop.position = arena_rect.position
	backdrop.size = shown
	flash_rect.position = arena_rect.position
	flash_rect.size = shown


func _build_hud() -> void:
	for ch in hud.get_children():
		ch.queue_free()
	spell_btns.clear()
	bot_btns.clear()
	order_btns.clear()
	bot_mana_bars.clear()
	echo_label = null
	journal_label = null
	if _landscape:
		_build_landscape()
	else:
		_build_portrait()
	hint_label = UiTheme.label("", 22, UiTheme.GOLD)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.1))
	hint_label.add_theme_constant_override("outline_size", 8)
	_anchor(hint_label, 0.0, 0.0, 1.0, 0.0, 0.0, (TOP_H_LAND if _landscape else TOP_H) + 8.0, 0.0, (TOP_H_LAND if _landscape else TOP_H) + 40.0)
	hud.add_child(hint_label)
	toast_label = UiTheme.label("", 24, UiTheme.TEXT)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.1))
	toast_label.add_theme_constant_override("outline_size", 8)
	_anchor(toast_label, 0.0, 0.5, 1.0, 0.5, 40.0, -20.0, -40.0, 20.0)
	hud.add_child(toast_label)
	_build_bark()


func _build_portrait() -> void:
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.94), UiTheme.BORDER, 0, 0, 12))
	_anchor(top, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, TOP_H)
	hud.add_child(top)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	top.add_child(v)
	var row := HBoxContainer.new()
	v.add_child(row)
	row.add_child(_pause_button())
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	obj_title = UiTheme.label("NEXUS", 24)
	head.add_child(obj_title)
	head.add_child(UiTheme.spacer())
	head.add_child(UiTheme.label("%s %s" % [str(_level.get("number", "")), str(_level.get("name", ""))], 20, UiTheme.MUTED))
	nexus_bar = UiTheme.bar(UiTheme.NEXUS, 18)
	col.add_child(nexus_bar)
	nexus_info = UiTheme.label("", 18, UiTheme.MUTED)
	col.add_child(nexus_info)
	v.add_child(_surge_row())

	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.96), UiTheme.BORDER, 0, 0, 12))
	_anchor(bottom, 0.0, 1.0, 1.0, 1.0, 0.0, -BOTTOM_H, 0.0, 0.0)
	hud.add_child(bottom)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 8)
	bottom.add_child(bv)
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 8)
	bv.add_child(r1)
	for c in sim.casters:
		if c.is_bot and c.side == "left":
			r1.add_child(_bot_cycle_button(c))
	champ_btn = _action_button("CHAMPION", UiTheme.GOLD)
	champ_btn.pressed.connect(_on_champion)
	r1.add_child(champ_btn)
	if _mode == "drawer":
		# Tiroir : l'Ultime passe sur la rangée du Champion, les 8 cases servent aux écoles.
		ult_btn = _ult_button()
		ult_btn.custom_minimum_size = Vector2(0, 76)
		r1.add_child(ult_btn)
	for c in sim.casters:
		if c.is_bot and c.side == "right":
			r1.add_child(_bot_cycle_button(c))
	bv.add_child(_barrier_row())
	bv.add_child(_mana_row())
	# Sorts sur deux rangées de quatre (7 sorts + Ultime, ou 8 écoles du tiroir).
	var r3 := GridContainer.new()
	r3.columns = 4
	r3.add_theme_constant_override("h_separation", 6)
	r3.add_theme_constant_override("v_separation", 6)
	r3.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bv.add_child(r3)
	if _mode == "drawer":
		for i in range(DRAWER.size()):
			r3.add_child(_cell_button(i))
	else:
		for i in range(sim.player().spells.size()):
			var b := _spell_button(i)
			r3.add_child(b)
		ult_btn = _ult_button()
		ult_btn.custom_minimum_size = Vector2(0, 78)
		r3.add_child(ult_btn)
	_bottom_panel = bottom
	_bottom_h = BOTTOM_H


func _build_landscape() -> void:
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.96), UiTheme.BORDER, 0, 0, 16))
	_anchor(left, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, _side_w_for(size.x), 0.0)
	hud.add_child(left)
	var lv := VBoxContainer.new()
	left.add_child(lv)
	lv.add_child(UiTheme.label("LE CERCLE", 26, UiTheme.MUTED))
	if sim.casters.size() == 1:
		lv.add_child(_wrap_label("Mode solo : pas de bots. +25 % d'XP.", 20, UiTheme.MUTED))
	for c in sim.casters:
		if c.idx == 0:
			continue
		lv.add_child(_bot_card(c))
	lv.add_child(UiTheme.label("ÉCHOS ACTIFS", 26, UiTheme.MUTED))
	echo_label = _wrap_label("Aucun", 20, UiTheme.CYAN)
	lv.add_child(echo_label)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(sp)
	lv.add_child(_wrap_label("Clic maintenu : Flux · 1-7 : sorts au curseur · E : Champion · Espace : Ultime · Q/R : ordres · F : tir auto · Échap : pause", 18, UiTheme.MUTED))

	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.96), UiTheme.BORDER, 0, 0, 16))
	_anchor(right, 1.0, 0.0, 1.0, 1.0, -_side_w_for(size.x), 0.0, 0.0, 0.0)
	hud.add_child(right)
	var rv := VBoxContainer.new()
	right.add_child(rv)
	rv.add_child(UiTheme.label("SORTS", 26, UiTheme.MUTED))
	rv.add_child(_mana_row())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	rv.add_child(grid)
	if _mode == "drawer":
		for i in range(DRAWER.size()):
			var cb := _cell_button(i)
			cb.custom_minimum_size = Vector2(0, 76)
			grid.add_child(cb)
	else:
		for i in range(sim.player().spells.size()):
			var b := _spell_button(i)
			b.custom_minimum_size = Vector2(0, 82)
			grid.add_child(b)
	champ_btn = _action_button("CHAMPION", UiTheme.GOLD)
	champ_btn.pressed.connect(_on_champion)
	champ_btn.custom_minimum_size = Vector2(0, 80)
	grid.add_child(champ_btn)
	ult_btn = _ult_button()
	ult_btn.custom_minimum_size = Vector2(0, 80)
	grid.add_child(ult_btn)
	rv.add_child(_barrier_row())
	rv.add_child(UiTheme.label("JOURNAL", 26, UiTheme.MUTED))
	journal_label = _wrap_label("", 19, UiTheme.MUTED)
	journal_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_label.clip_text = true
	rv.add_child(journal_label)

	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.9), UiTheme.BORDER, 0, 0, 10))
	_anchor(top, 0.0, 0.0, 1.0, 0.0, _side_w_for(size.x), 0.0, -_side_w_for(size.x), TOP_H_LAND)
	hud.add_child(top)
	var th := HBoxContainer.new()
	top.add_child(th)
	th.add_child(_pause_button())
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	obj_title = UiTheme.label("NEXUS", 22)
	head.add_child(obj_title)
	nexus_info = UiTheme.label("", 18, UiTheme.MUTED)
	head.add_child(nexus_info)
	head.add_child(UiTheme.spacer())
	head.add_child(UiTheme.label("%s %s" % [str(_level.get("number", "")), str(_level.get("name", ""))], 18, UiTheme.MUTED))
	nexus_bar = UiTheme.bar(UiTheme.NEXUS, 16)
	col.add_child(nexus_bar)
	var s := _surge_row()
	s.custom_minimum_size = Vector2(260, 0)
	th.add_child(s)


func _side_w_for(w: float) -> float:
	return clampf(w * 0.2, 320.0, 440.0)


func _anchor(c: Control, al: float, at: float, ar: float, ab: float, ol: float, ot: float, or_: float, ob: float) -> void:
	c.anchor_left = al
	c.anchor_top = at
	c.anchor_right = ar
	c.anchor_bottom = ab
	c.offset_left = ol
	c.offset_top = ot
	c.offset_right = or_
	c.offset_bottom = ob


func _wrap_label(text: String, fs: int, color: Color) -> Label:
	var l := UiTheme.label(text, fs, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	return l


func _pause_button() -> Button:
	var b := UiTheme.button("", 28)
	b.icon = Icons.tex("pause", 56)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 28)
	b.custom_minimum_size = Vector2(68, 68)
	b.pressed.connect(_open_pause)
	return b


func _surge_row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_child(UiTheme.label("SURGE", 22, UiTheme.CYAN))
	surge_bar = UiTheme.bar(UiTheme.CYAN, 14)
	surge_bar.max_value = 100.0
	h.add_child(surge_bar)
	surge_label = UiTheme.label("0%", 22, UiTheme.CYAN)
	surge_label.custom_minimum_size = Vector2(64, 0)
	surge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(surge_label)
	return h


func _mana_row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_child(UiTheme.label("MANA", 20, UiTheme.MANA))
	mana_bar = UiTheme.bar(UiTheme.MANA, 12)
	h.add_child(mana_bar)
	mana_label = UiTheme.label("", 20, UiTheme.MANA)
	mana_label.custom_minimum_size = Vector2(96, 0)
	mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(mana_label)
	return h


func _barrier_row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_child(UiTheme.label("BARRIÈRE", 20, UiTheme.GOLD))
	barrier_bar = UiTheme.bar(UiTheme.GOLD, 12)
	h.add_child(barrier_bar)
	barrier_label = UiTheme.label("", 20, UiTheme.GOLD)
	barrier_label.custom_minimum_size = Vector2(96, 0)
	barrier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(barrier_label)
	return h


func _action_button(text: String, accent: Color) -> Button:
	var b := UiTheme.button(text, 20)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 76)
	b.add_theme_color_override("font_color", accent)
	return b


func _spell_button(i: int) -> Button:
	var b := UiTheme.button("", 18)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 78)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.clip_text = true
	# Bordure à la couleur du sort, pour le reconnaître d'un coup d'œil.
	var sid: String = sim.player().spells[i]
	var col := Color(str(sim.spells_db[sid].get("color", "4A3D7A")))
	# Icône au trait du sort, au-dessus du nom, à sa couleur.
	b.icon = Icons.tex(sid, 56)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", 24)
	b.add_theme_constant_override("h_separation", 2)
	b.add_theme_color_override("icon_normal_color", col)
	b.add_theme_color_override("icon_hover_color", col.lightened(0.3))
	b.add_theme_color_override("icon_disabled_color", Color(col, 0.35))
	b.add_theme_stylebox_override("normal", UiTheme.box(UiTheme.PANEL2, Color(col, 0.85), 12, 2, 6))
	b.add_theme_stylebox_override("hover", UiTheme.box(UiTheme.PANEL2.lightened(0.08), col, 12, 2, 6))
	b.add_theme_stylebox_override("disabled", UiTheme.box(Color(UiTheme.PANEL2, 0.55), Color(col, 0.3), 12, 2, 6))
	b.pressed.connect(_on_spell_pressed.bind(i))
	spell_btns.append(b)
	return b


## Case du tiroir : une école (fermé) ou un de ses sorts (ouvert). Réagit dès l'appui.
func _cell_button(i: int) -> Button:
	var b := UiTheme.button("", 17)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 78)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.clip_text = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", 24)
	b.add_theme_constant_override("h_separation", 2)
	b.button_down.connect(_on_cell_down.bind(i))
	spell_btns.append(b)
	_cell_ids.append("?")
	return b


func _style_cell(b: Button, icon_id: String, col: Color, open: bool) -> void:
	b.icon = Icons.tex(icon_id, 56) if icon_id != "" else null
	b.add_theme_color_override("icon_normal_color", col)
	b.add_theme_color_override("icon_hover_color", col.lightened(0.3))
	b.add_theme_color_override("icon_pressed_color", col.lightened(0.3))
	b.add_theme_color_override("icon_disabled_color", Color(col, 0.3))
	var fill := UiTheme.PANEL2 if not open else Color("1a1430")
	b.add_theme_stylebox_override("normal", UiTheme.box(fill, Color(col, 0.85), 12, 2, 6))
	b.add_theme_stylebox_override("hover", UiTheme.box(fill.lightened(0.08), col, 12, 2, 6))
	b.add_theme_stylebox_override("pressed", UiTheme.box(fill.lightened(0.12), col.lightened(0.3), 12, 3, 6))
	b.add_theme_stylebox_override("disabled", UiTheme.box(Color(fill, 0.5), Color(col, 0.25), 12, 2, 6))


## Contenu des cases du tiroir (écoles, ou sorts de l'école ouverte), restylées seulement si elles changent.
func _update_drawer() -> void:
	var c := sim.player()
	for i in range(spell_btns.size()):
		var b := spell_btns[i]
		var shown := ""
		if _drawer == "":
			shown = "@" + str(DRAWER[i])
		else:
			var list: Array = _by_school.get(_drawer, [])
			shown = str(list[i]) if i < list.size() else ""
		if shown != _cell_ids[i]:
			_cell_ids[i] = shown
			if shown.begins_with("@"):
				var info: Array = DRAWER_INFO[shown.substr(1)]
				_style_cell(b, str(info[1]), Color(str(info[2])), false)
			elif shown != "":
				_style_cell(b, shown, Color(str(sim.spells_db[shown].get("color", "FFFFFF"))), true)
			else:
				_style_cell(b, "", Color(UiTheme.MUTED, 0.4), true)
		var txt := ""
		if shown.begins_with("@"):
			var sc := shown.substr(1)
			var list: Array = _by_school.get(sc, [])
			var ready := 0
			for id in list:
				if sim.spell_ready(c, str(id)):
					ready += 1
			txt = "%s\n%s" % [str(DRAWER_INFO[sc][0]).to_upper(), ("%d/%d prêts" % [ready, list.size()]) if not list.is_empty() else "—"]
			b.disabled = list.is_empty()
			b.modulate = Color.WHITE if ready > 0 else Color(1, 1, 1, 0.7)
		elif shown != "":
			var sp: Dictionary = sim.spells_db[shown]
			var cd := float(c.spell_cd.get(shown, 0.0))
			txt = "%s\n%ds" % [str(sp["name"]), int(ceil(cd))] if cd > 0.0 else "%s\n%d mana" % [str(sp["name"]), int(sim.spell_cost(c, shown))]
			b.disabled = not sim.spell_ready(c, shown)
			b.modulate = Color(1.0, 0.92, 0.6) if aiming == shown or (_hold and _hover_cell == i) else Color.WHITE
		else:
			b.disabled = true
			b.modulate = Color.WHITE
		_set_text(b, txt)


func _open_drawer(school: String) -> void:
	_drawer = school
	_update_drawer()


func _close_drawer() -> void:
	_drawer = ""
	_hold = false
	_drag_spell = ""
	_hover_cell = -1
	if _mode == "drawer" and not spell_btns.is_empty():
		_update_drawer()


func _on_cell_down(i: int) -> void:
	if paused or sim.state != "running":
		return
	_hold = true
	_hold_moved = false
	_hold_start = get_global_mouse_position()
	_hold_cell = i
	_hover_cell = i
	_drag_spell = ""
	if _drawer == "":
		var sc := str(DRAWER[i])
		if (_by_school.get(sc, []) as Array).is_empty():
			_hold = false
			_toast("Aucun sort de %s : apprends-en à la Bibliothèque" % str(DRAWER_INFO[sc][0]))
			return
		if aiming != "" and aiming != "ultimate":
			aiming = ""
		_open_drawer(sc)
		return
	# Tiroir ouvert : un appui sur un sort le prend en main (relâcher pour choisir, glisser vers l'arène pour lancer).
	var list: Array = _by_school.get(_drawer, [])
	if i < list.size():
		_drag_spell = str(list[i])


## Pendant l'appui maintenu sur le tiroir : survol des cases, glisser vers l'arène, relâcher.
func _input(ev: InputEvent) -> void:
	if not _hold or _mode != "drawer":
		return
	if ev is InputEventMouseMotion:
		var pos := (ev as InputEventMouseMotion).position
		if pos.distance_to(_hold_start) > HOLD_MOVE:
			_hold_moved = true
		_hover_cell = _cell_at(pos)
		var list: Array = _by_school.get(_drawer, [])
		if _hover_cell >= 0 and _drawer != "" and _hover_cell < list.size():
			_drag_spell = str(list[_hover_cell])
		if _drag_spell != "" and arena_rect.get_global_rect().has_point(pos):
			# Glisser le sort jusqu'à l'arène : la zone d'effet suit le doigt.
			_aim_with(_drag_spell)
			_hover = _to_logic(pos - arena_rect.global_position)
			_hover_in = true
	elif ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and not ev.is_pressed():
		var pos := (ev as InputEventMouseButton).position
		_hold = false
		var cell := _cell_at(pos)
		var list: Array = _by_school.get(_drawer, [])
		if _drag_spell != "" and arena_rect.get_global_rect().has_point(pos):
			_aim_with(_drag_spell)
			_cast_aimed(_to_logic(pos - arena_rect.global_position))
		elif cell >= 0 and _drawer != "" and cell < list.size():
			var id := str(list[cell])
			if sim.spell_ready(sim.player(), id):
				_aim_with(id)
			else:
				var c := sim.player()
				_toast("Pas assez de mana" if c.mana < sim.spell_cost(c, id) else "Sort en recharge")
		elif cell == _hold_cell and not _hold_moved:
			pass # simple toucher sur l'école : le tiroir reste ouvert, toucher ensuite un sort
		elif aiming == "":
			_close_drawer()
		_drag_spell = ""
		_hover_cell = -1


func _cell_at(pos: Vector2) -> int:
	for i in range(spell_btns.size()):
		if spell_btns[i].get_global_rect().has_point(pos):
			return i
	return -1


## Sort choisi : la zone d'effet suit le pointeur, toucher l'arène pour le lancer.
func _aim_with(id: String) -> void:
	if not sim.spell_ready(sim.player(), id):
		return
	aiming = id
	var sp: Dictionary = sim.spells_db[id]
	match str(sp["type"]):
		"purify":
			arena.aim_radius = 0.9
		"chain":
			arena.aim_radius = 2.5
		"quake":
			arena.aim_radius = minf(float(sp.get("band", 2.0)), 4.0)
		"barrage":
			arena.aim_radius = float(sp.get("spread", 2.0))
		_:
			arena.aim_radius = float(sp.get("radius", 1.0))
	arena.aim_color = Color(str(sp.get("color", "FFFFFF")))


func _ult_button() -> Button:
	var b := UiTheme.button("ULTIME", 18)
	b.icon = Icons.tex("meteore", 56)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", 24)
	b.add_theme_color_override("icon_normal_color", UiTheme.CYAN)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 100)
	b.add_theme_color_override("font_color", UiTheme.CYAN)
	b.add_theme_stylebox_override("normal", UiTheme.box(Color("1d4a52"), UiTheme.CYAN, 12, 2, 8))
	b.add_theme_stylebox_override("hover", UiTheme.box(Color("24606a"), UiTheme.CYAN, 12, 2, 8))
	b.pressed.connect(_on_ultimate_pressed)
	return b


func _bot_cycle_button(c: BattleSim.Caster) -> Button:
	var b := UiTheme.button("", 20)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 76)
	b.pressed.connect(func() -> void: sim.cycle_order(c.idx))
	b.set_meta("idx", c.idx)
	bot_btns.append(b)
	return b


func _bot_card(c: BattleSim.Caster) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.BORDER, 12, 2, 12))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	var party: Dictionary = GameData.party()
	var cls_name := str(party["classes"][c.class_id].get("name", c.class_id))
	var race_name := str(party["races"].get(c.race_id, {}).get("name", c.race_id))
	var h := HBoxContainer.new()
	v.add_child(h)
	h.add_child(UiTheme.label(c.name, 24))
	h.add_child(UiTheme.spacer())
	h.add_child(UiTheme.label("Gauche" if c.side == "left" else "Droite", 18, UiTheme.MUTED))
	v.add_child(UiTheme.label("%s · %s · niv. %d" % [race_name, cls_name, c.level], 18, UiTheme.MUTED))
	var mb := UiTheme.bar(UiTheme.MANA, 8)
	v.add_child(mb)
	bot_mana_bars.append(mb)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	v.add_child(g)
	var row: Array[Button] = []
	for o in BattleSim.ORDERS:
		var b := UiTheme.button(str(BattleSim.ORDER_LABELS[o]), 17)
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 52)
		var order := str(o)
		b.pressed.connect(func() -> void: sim.set_order(c.idx, order))
		b.set_meta("order", order)
		g.add_child(b)
		row.append(b)
	order_btns.append({"idx": c.idx, "buttons": row})
	return card


# ---------------------------------------------------------------- boucle

func _process(delta: float) -> void:
	if sim == null:
		return
	if not paused and sim.state == "running":
		_acc += minf(delta, 0.1)
		var steps := 0
		while _acc >= BattleSim.TICK and steps < 4:
			sim.step()
			_acc -= BattleSim.TICK
			steps += 1
			if sim.state != "running":
				break
		if steps >= 4:
			_acc = 0.0
		_keyboard_move(delta)
	arena.alpha = clampf(_acc / BattleSim.TICK, 0.0, 1.0)
	if not sim.events.is_empty():
		arena.consume_events(sim.events)
		sim.events.clear()
	arena.aim_active = aiming != "" and _hover_in
	arena.aim_pos = _hover
	flash_rect.color.a = clampf(arena.flash * 1.2, 0.0, 0.8)
	_toast_t = maxf(0.0, _toast_t - delta)
	if _pending_note != "" and toast_label != null:
		_toast(_pending_note, 5.0)
		_pending_note = ""
	_update_barks(delta)
	_update_hud()
	if sim.state == "echo" and not _echo_open:
		_open_echo()
	if (sim.state == "victory" or sim.state == "defeat") and not _end_open:
		_open_end()


func _keyboard_move(delta: float) -> void:
	var dir := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir += 1.0
	if dir != 0.0:
		var c := sim.player()
		sim.set_player_aim(c.target_x + dir * 6.0 * delta)


func _update_hud() -> void:
	if nexus_bar == null or not is_instance_valid(nexus_bar):
		return
	var obar := sim.objective_bar()
	nexus_bar.max_value = obar.y
	nexus_bar.value = obar.x
	_set_text(obj_title, sim.objective_title())
	_set_text(nexus_info, sim.objective_info())
	surge_bar.value = sim.surge
	_set_text(surge_label, "%d%%" % int(sim.surge))
	var c := sim.player()
	mana_bar.max_value = c.mana_max
	mana_bar.value = c.mana
	_set_text(mana_label, "%d/%d" % [int(c.mana), int(c.mana_max)])
	barrier_bar.max_value = sim.barrier_max
	barrier_bar.value = sim.barrier_hp
	var bl := "%d/%d" % [int(ceil(sim.barrier_hp)), int(sim.barrier_max)]
	if sim.barrier_shield > 0.0:
		bl += " +%d" % int(sim.barrier_shield)
	_set_text(barrier_label, bl)
	if _mode == "drawer":
		_update_drawer()
	for i in range(spell_btns.size() if _mode != "drawer" else 0):
		var id: String = c.spells[i]
		var sp: Dictionary = sim.spells_db[id]
		var cd := float(c.spell_cd.get(id, 0.0))
		var b := spell_btns[i]
		var txt := "%s\n%ds" % [str(sp["name"]), int(ceil(cd))] if cd > 0.0 else "%s\n%d mana" % [str(sp["name"]), int(sim.spell_cost(c, id))]
		_set_text(b, txt)
		b.disabled = not sim.spell_ready(c, id)
		b.modulate = Color(1.0, 0.92, 0.6) if aiming == id else Color.WHITE
	_set_text(champ_btn, "CHAMPION\n%d/%d" % [sim.champion_charge, sim.champion_need])
	champ_btn.disabled = sim.champion_charge < sim.champion_need or sim.state != "running"
	_set_text(ult_btn, "ULTIME\n%d%%" % int(sim.surge))
	ult_btn.disabled = not sim.ultimate_ready()
	ult_btn.modulate = Color(1.0, 0.92, 0.6) if aiming == "ultimate" else Color.WHITE
	for b in bot_btns:
		var bc := sim.casters[int(b.get_meta("idx"))]
		_set_text(b, "%s\n%s" % [bc.name, str(BattleSim.ORDER_LABELS.get(bc.order, bc.order))])
	for entry in order_btns:
		var oc := sim.casters[int(entry["idx"])]
		for ob in entry["buttons"]:
			ob.set_pressed_no_signal(str(ob.get_meta("order")) == oc.order)
	var bi := 0
	for cc in sim.casters:
		if cc.idx == 0 or bi >= bot_mana_bars.size():
			continue
		bot_mana_bars[bi].max_value = cc.mana_max
		bot_mana_bars[bi].value = cc.mana
		bi += 1
	if echo_label != null:
		var names: Array[String] = []
		for id in sim.echoes_taken:
			names.append(str(sim.echo_def(id)["name"]))
		_set_text(echo_label, "Aucun" if names.is_empty() else "\n".join(names))
	if journal_label != null:
		var n := sim.log_lines.size()
		var lines: Array[String] = []
		for i in range(maxi(0, n - 9), n):
			lines.append(sim.log_lines[i])
		_set_text(journal_label, "\n".join(lines))
	if aiming != "":
		_set_text(hint_label, "Touche l'arène pour lancer — Échap / clic droit : annuler")
	elif sim.wind_state != "calm":
		_set_text(hint_label, "%s vers la %s !" % ["Rafale imminente" if sim.wind_state == "warn" else "Le vent pousse les troupes", "droite" if sim.wind_dir > 0.0 else "gauche"])
	elif not auto_fire and sim.time < 6.0 and not sim.player().firing:
		_set_text(hint_label, "Maintiens sur l'arène pour lancer le Flux, glisse pour viser")
	else:
		_set_text(hint_label, "")
	toast_label.modulate.a = clampf(_toast_t, 0.0, 1.0)
	_place_bark()


func _set_text(n: Variant, s: String) -> void:
	if n != null and n.text != s:
		n.text = s


func _toast(s: String, dur: float = 1.8) -> void:
	toast_label.text = s
	_toast_t = dur


# ---------------------------------------------------------------- répliques des compagnons

func _build_bark() -> void:
	bark_panel = PanelContainer.new()
	bark_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bark_panel.visible = false
	hud.add_child(bark_panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bark_panel.add_child(h)
	bark_portrait = TextureRect.new()
	bark_portrait.custom_minimum_size = Vector2(64, 64)
	bark_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bark_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bark_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bark_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bark_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(bark_portrait)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	bark_name = UiTheme.title("", 20, UiTheme.TEXT)
	v.add_child(bark_name)
	bark_text = UiTheme.wrap("", 22, UiTheme.TEXT)
	v.add_child(bark_text)


## Déclenche une réplique (une fois par partie et par déclencheur, espacées de BARK_GAP s).
func _bark(trigger: String, force: bool = false) -> void:
	if _barks_fired.has(trigger) or _present.is_empty() or bark_panel == null:
		return
	if _bark_cd > 0.0 and not force:
		return
	var key := trigger.rstrip("0123456789")
	var list := Dialogues.barks(level_id, key, _present)
	_barks_fired[trigger] = true
	if list.is_empty():
		return
	var b: Dictionary = list[_bark_rng.randi_range(0, list.size() - 1)]
	var who := str(b["who"])
	var col := Dialogues.color(who)
	bark_portrait.texture = PortraitArt.texture(who, str(b.get("mood", "neutre")))
	bark_name.text = Dialogues.display_name(who).to_upper()
	bark_name.add_theme_color_override("font_color", col)
	bark_text.text = Dialogues.fmt(str(b["text"]))
	bark_panel.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.BG, 0.9), col, 12, 2, 10))
	_bark_side = "left"
	for c in sim.casters:
		if c.id == who:
			_bark_side = c.side
	_bark_t = BARK_TIME
	_bark_cd = BARK_GAP
	bark_panel.visible = true
	_place_bark()


func _place_bark() -> void:
	if bark_panel == null or not bark_panel.visible:
		return
	var w := minf(size.x - 24.0, 520.0)
	var x0 := 12.0
	var x1 := size.x - 12.0
	var bottom := size.y - _bottom_h - 12.0
	if _landscape:
		x0 = arena_rect.position.x + 12.0
		x1 = arena_rect.position.x + arena_rect.size.x - 12.0
		w = minf(w, x1 - x0)
		bottom = size.y - 16.0
	# Largeur du texte fixée : sinon le retour à la ligne est calculé sur 10 px et le cadre s'étire.
	bark_text.custom_minimum_size = Vector2(w - 64.0 - 10.0 - 22.0, 0)
	bark_text.size = Vector2(w - 64.0 - 10.0 - 22.0, bark_text.size.y)
	bark_panel.custom_minimum_size = Vector2(w, 0)
	bark_panel.size = Vector2(w, 0)
	bark_panel.reset_size()
	# Hauteur calculée d'après le texte : jamais plus haute que nécessaire (le cadre s'étirait parfois).
	var pad := bark_panel.get_theme_stylebox("panel").get_minimum_size().y if bark_panel.has_theme_stylebox("panel") else 24.0
	var want := maxf(64.0, bark_name.get_minimum_size().y + bark_text.get_minimum_size().y) + pad
	if bark_panel.size.y > want + 4.0:
		bark_panel.size = Vector2(w, want)
	bark_panel.position = Vector2(x0 if _bark_side != "right" else x1 - w, bottom - bark_panel.size.y)


func _update_barks(delta: float) -> void:
	_bark_cd = maxf(0.0, _bark_cd - delta)
	if bark_panel != null and _bark_t > 0.0:
		_bark_t -= delta
		# Fondu d'entrée (le temps que le cadre prenne sa taille) et de sortie.
		bark_panel.modulate.a = clampf(minf(_bark_t / 0.4, (BARK_TIME - _bark_t - 0.05) / 0.2), 0.0, 1.0)
		if _bark_t <= 0.0:
			bark_panel.visible = false
	if sim.state != "running" or paused:
		return
	if sim.boss != null and sim.boss_phase > _bark_phase:
		_bark_phase = sim.boss_phase
		_bark("boss_phase%d" % _bark_phase, true)
	if sim.time >= 2.0:
		_bark("start")
	if sim.barrier_hp < sim.barrier_max * 0.4:
		_bark("barrier_low", true)
	if sim.escort != null and sim.escort.alive and sim.escort.hp < sim.escort.max_hp * 0.5:
		_bark("escort_low", true)
	if sim.objective_ratio() <= 0.5:
		_bark("half")
	if not sim.echoes_taken.is_empty():
		_bark("echo")
	if sim.allies.size() >= 120:
		_bark("crowd")


# ---------------------------------------------------------------- commandes

func _on_arena_input(ev: InputEvent) -> void:
	if paused or sim.state != "running":
		return
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		var lp := _to_logic(mb.position)
		_hover = lp
		_hover_in = true
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if aiming != "":
					_cast_aimed(lp)
					return
				if _mode == "drawer" and _drawer != "":
					# Toucher l'arène sans sort choisi : le tiroir se referme.
					_close_drawer()
				_pointer_down = true
				sim.set_player_aim(lp.x)
				sim.set_player_firing(true)
			else:
				_pointer_down = false
				if not auto_fire:
					sim.set_player_firing(false)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_cancel_aim()
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		var lp := _to_logic(mm.position)
		_hover = lp
		_hover_in = true
		if _pointer_down:
			sim.set_player_aim(lp.x)


func _to_logic(local: Vector2) -> Vector2:
	return arena.pick(local / float(_k))


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.is_pressed() or ev.is_echo():
		return
	var k := (ev as InputEventKey).keycode
	if k == KEY_ESCAPE:
		if aiming != "":
			_cancel_aim()
		elif _end_open or _echo_open:
			return
		elif paused:
			_close_overlay()
			paused = false
		else:
			_open_pause()
		return
	if paused or sim.state != "running":
		return
	match k:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
			var i := int(k - KEY_1)
			if _mode == "drawer":
				# Tiroir au clavier : 1-8 ouvre une école, puis 1-8 lance son sort au curseur.
				if _drawer == "":
					var sc := str(DRAWER[i])
					if not (_by_school.get(sc, []) as Array).is_empty():
						_open_drawer(sc)
				else:
					var list: Array = _by_school.get(_drawer, [])
					if i < list.size():
						_aim_with(str(list[i]))
						if aiming != "" and _hover_in:
							_cast_aimed(_hover)
			elif i < spell_btns.size():
				_on_spell_pressed(i, _hover_in)
		KEY_E:
			_on_champion()
		KEY_SPACE:
			if _hover_in:
				aiming = "ultimate"
				_cast_aimed(_hover)
			else:
				_on_ultimate_pressed()
		KEY_Q:
			sim.cycle_order(_bot_idx("left"))
		KEY_R:
			sim.cycle_order(_bot_idx("right"))
		KEY_F:
			auto_fire = not auto_fire
			sim.set_player_firing(auto_fire or _pointer_down)
			_toast("Tir automatique : %s" % ("OUI" if auto_fire else "NON"))


func _on_spell_pressed(i: int, quick: bool = false) -> void:
	var c := sim.player()
	var id: String = c.spells[i]
	if not sim.spell_ready(c, id):
		_toast("Pas assez de mana" if c.mana < sim.spell_cost(c, id) else "Sort en recharge")
		return
	if aiming == id:
		_cancel_aim()
		return
	aiming = id
	var sp: Dictionary = sim.spells_db[id]
	match str(sp["type"]):
		"purify":
			arena.aim_radius = 0.9
		"chain":
			arena.aim_radius = 2.5
		_:
			arena.aim_radius = float(sp.get("radius", 1.0))
	arena.aim_color = Color(str(sp.get("color", "FFFFFF")))
	if quick:
		_cast_aimed(_hover)


func _on_ultimate_pressed() -> void:
	if not sim.ultimate_ready():
		_toast("Jauge Surge incomplète")
		return
	if aiming == "ultimate":
		_cancel_aim()
		return
	aiming = "ultimate"
	var sp: Dictionary = sim.spells_db[sim.ultimate_id]
	arena.aim_radius = float(sp.get("radius", 3.0))
	arena.aim_color = Color(str(sp.get("color", "B07CFF")))


func _cast_aimed(at: Vector2) -> void:
	if aiming == "ultimate":
		if sim.cast_ultimate(at):
			aiming = ""
			_bark("ultimate", true)
		return
	var c := sim.player()
	if sim.cast_spell(c, aiming, at):
		aiming = ""
		if _mode == "drawer":
			_close_drawer()
	elif str(sim.spells_db[aiming]["type"]) == "purify":
		_toast("Aucun portail négatif ici")
	elif str(sim.spells_db[aiming]["type"]) == "chain":
		_toast("Aucun ennemi à portée")
	else:
		aiming = ""


func _cancel_aim() -> void:
	aiming = ""
	if _mode == "drawer":
		_close_drawer()


func _on_champion() -> void:
	if not sim.summon_champion():
		_toast("Champion : %d/%d invocations" % [sim.champion_charge, sim.champion_need])


# ---------------------------------------------------------------- fenêtres

func _modal(title: String, subtitle: String, title_color: Color = UiTheme.GOLD) -> VBoxContainer:
	_close_overlay()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.09, 0.72)
	overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL, title_color, 18, 3, 24))
	panel.custom_minimum_size = Vector2(minf(620.0, size.x - 40.0), 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var t := UiTheme.title(title, 40, title_color)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	if subtitle != "":
		var s := _wrap_label(subtitle, 22, UiTheme.MUTED)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(s)
	return v


func _close_overlay() -> void:
	for ch in overlay.get_children():
		ch.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _open_echo() -> void:
	_echo_open = true
	_pointer_down = false
	if not auto_fire:
		sim.set_player_firing(false)
	aiming = ""
	var v := _modal("ÉCHO DU DESTIN", "Le temps se fige… Un fragment d'une autre ligne temporelle s'offre à toi.", UiTheme.CYAN)
	for id in sim.pending_echoes:
		var e := sim.echo_def(id)
		var b := UiTheme.button("%s\n%s" % [str(e["name"]), str(e.get("desc", ""))], 22)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 104)
		var echo_id := str(id)
		b.pressed.connect(func() -> void: _choose_echo(echo_id))
		v.add_child(b)


func _on_arena_exit() -> void:
	_hover_in = false


func _on_resume() -> void:
	_close_overlay()
	paused = false


func _on_toggle_autofire(b: Button) -> void:
	auto_fire = not auto_fire
	sim.set_player_firing(auto_fire)
	b.text = "Tir automatique : %s" % ("OUI" if auto_fire else "NON")


func _choose_echo(id: String) -> void:
	sim.choose_echo(id)
	_close_overlay()
	_echo_open = false


func _open_pause() -> void:
	if _end_open or _echo_open:
		return
	paused = true
	_pointer_down = false
	if not auto_fire:
		sim.set_player_firing(false)
	var v := _modal("PAUSE", "%s %s · %s" % [str(_level.get("number", "")), str(_level.get("name", "")), str(_level.get("type", ""))])
	var desc := _wrap_label(str(_level.get("desc", "")), 20, UiTheme.TEXT)
	v.add_child(desc)
	# Rappel des sorts (nom à la couleur du sort, effet).
	var sp_box := VBoxContainer.new()
	sp_box.add_theme_constant_override("separation", 2)
	v.add_child(sp_box)
	if _mode == "drawer":
		v.add_child(_wrap_label("Tiroir : %d sorts connus. Maintiens une école, relâche sur un sort, puis touche l'arène (ou glisse le sort jusqu'à l'arène pour le lancer aussitôt)." % sim.player().spells.size(), 18, UiTheme.MUTED))
	for id in (sim.player().spells if _mode != "drawer" else []):
		var sd: Dictionary = sim.spells_db[id]
		if not sd.has("desc"):
			continue
		var l := RichTextLabel.new()
		l.bbcode_enabled = true
		l.fit_content = true
		l.scroll_active = false
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override("normal_font_size", 17)
		l.text = "[color=#%s]%s[/color] [color=#a99fd0]%s[/color]" % [str(sd.get("color", "ECE8FF")), str(sd["name"]), str(sd["desc"])]
		sp_box.add_child(l)
	var resume := UiTheme.button("Reprendre", 26)
	resume.custom_minimum_size = Vector2(0, 72)
	resume.pressed.connect(_on_resume)
	v.add_child(resume)
	var af := UiTheme.button("Tir automatique : %s" % ("OUI" if auto_fire else "NON"), 24)
	af.custom_minimum_size = Vector2(0, 64)
	af.pressed.connect(_on_toggle_autofire.bind(af))
	v.add_child(af)
	var restart := UiTheme.button("Recommencer", 24)
	restart.custom_minimum_size = Vector2(0, 64)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	v.add_child(restart)
	var quit := UiTheme.button("Quitter vers le menu", 24)
	quit.custom_minimum_size = Vector2(0, 64)
	quit.pressed.connect(func() -> void: exit_requested.emit("map"))
	v.add_child(quit)


func _bot_idx(side: String) -> int:
	for c in sim.casters:
		if c.is_bot and c.side == side:
			return c.idx
	return -1


func _open_end() -> void:
	_end_open = true
	aiming = ""
	var win := sim.state == "victory"
	if _rewards.is_empty():
		Story.on_battle(_present)
		_rewards = Profile.apply_battle(level_id, win, sim.stars, sim.time)
		if Cloud.instance != null:
			Cloud.instance.push()
	var v := _modal("VICTOIRE" if win else "DÉFAITE", sim.end_reason, UiTheme.GOLD if win else UiTheme.DANGER)
	if win:
		var stars := HBoxContainer.new()
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		stars.add_theme_constant_override("separation", 16)
		for i in range(3):
			stars.add_child(UiTheme.icon_rect("star", 54, UiTheme.GOLD if i < sim.stars else Color(UiTheme.MUTED, 0.35)))
		v.add_child(stars)
		var crit := _wrap_label("1 étoile : victoire · 2 : Barrière > 50 %% · 3 : et en moins de %s" % _fmt_time(sim.par_time), 17, UiTheme.MUTED)
		crit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(crit)
	var stats := _wrap_label("Durée %s · %d ennemis vaincus · Barrière %d/%d" % [_fmt_time(sim.time), sim.kills, int(ceil(sim.barrier_hp)), int(sim.barrier_max)], 19, UiTheme.MUTED)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(stats)
	# Récompenses
	var rw := PanelContainer.new()
	rw.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.BORDER, 12, 2, 12))
	v.add_child(rw)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	rw.add_child(rv)
	var line := "+%d XP · +%d or" % [int(_rewards.get("xp", 0)), int(_rewards.get("gold", 0))]
	if bool(_rewards.get("first", false)):
		line += " · 1re victoire ×2"
	rv.add_child(UiTheme.label(line, 22, UiTheme.GOLD))
	if int(_rewards.get("levels", 0)) > 0:
		rv.add_child(UiTheme.label("NIVEAU %d ATTEINT ! (+%d point de compétence)" % [int(_rewards["level_after"]), int(_rewards["levels"])], 22, UiTheme.CYAN))
	var mats: Dictionary = _rewards.get("materials", {})
	if not mats.is_empty():
		var names: Array[String] = []
		var mdb: Dictionary = Profile.items_db()["materials"]
		for m in mats.keys():
			names.append("%s ×%d" % [str(mdb.get(m, {}).get("name", m)), int(mats[m])])
		rv.add_child(UiTheme.label(" · ".join(names), 19, UiTheme.MUTED))
	for it in _rewards.get("items", []):
		var l := _wrap_label("%s  —  %s" % [Profile.item_name(it), Profile.stats_text(Profile.item_stats(it))], 19, Profile.item_color(it))
		rv.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var again := UiTheme.button("Rejouer", 22)
	again.custom_minimum_size = Vector2(0, 64)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(func() -> void: restart_requested.emit())
	row.add_child(again)
	var map := UiTheme.button("Carte", 22)
	map.custom_minimum_size = Vector2(0, 64)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.add_theme_color_override("font_color", UiTheme.GOLD)
	map.pressed.connect(func() -> void: exit_requested.emit("map"))
	row.add_child(map)
	var hub := UiTheme.button("Havre-Aube", 22)
	hub.custom_minimum_size = Vector2(0, 64)
	hub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hub.pressed.connect(func() -> void: exit_requested.emit("hub"))
	row.add_child(hub)


func _fmt_time(s: float) -> String:
	var t := int(s)
	return "%d:%02d" % [int(t / 60.0), t % 60]
