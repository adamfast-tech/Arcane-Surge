class_name BattleScreen
extends Control
## Écran de combat : arène pixel-art + HUD (portrait ou paysage selon la fenêtre),
## commandes tactiles / souris / clavier, fenêtres Échos, pause et fin de partie.

signal exit_requested
signal restart_requested

const TOP_H := 150.0
const BOTTOM_H := 330.0
const TOP_H_LAND := 92.0

var level_id := "z01_l08"
var solo := false
var sim: BattleSim
var view: ArenaView
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

# Références du HUD (reconstruites à chaque changement d'orientation)
var nexus_bar: ProgressBar
var nexus_info: Label
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


func configure(id: String, solo_mode: bool) -> void:
	level_id = id
	solo = solo_mode


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level = GameData.level(level_id)
	sim = BattleSim.new()
	sim.setup(_level, GameData.party(), int(Time.get_ticks_usec() % 1000000), {"solo": solo})

	vp = SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(360, 640)
	add_child(vp)
	view = ArenaView.new()
	vp.add_child(view)
	view.setup(sim, vp.size, UiTheme.font())

	arena_rect = TextureRect.new()
	arena_rect.texture = vp.get_texture()
	arena_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena_rect.stretch_mode = TextureRect.STRETCH_SCALE
	arena_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arena_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	arena_rect.gui_input.connect(_on_arena_input)
	arena_rect.mouse_exited.connect(_on_arena_exit)
	add_child(arena_rect)

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
	var avail: Rect2
	if _landscape:
		_side_w = clampf(size.x * 0.2, 320.0, 440.0)
		avail = Rect2(_side_w, TOP_H_LAND, size.x - 2.0 * _side_w, size.y - TOP_H_LAND)
	else:
		avail = Rect2(0.0, TOP_H, size.x, size.y - TOP_H - BOTTOM_H)
	_place_arena(avail)
	_update_hud()


func _place_arena(avail: Rect2) -> void:
	var fit_w := minf(avail.size.x, avail.size.y * 9.0 / 16.6)
	_k = maxi(1, int(floor(fit_w / 270.0)))
	var vs := Vector2i(maxi(64, int(avail.size.x / _k)), maxi(64, int(avail.size.y / _k)))
	vp.size = vs
	view.resize(vs)
	var shown := Vector2(vs * _k)
	arena_rect.position = (avail.position + (avail.size - shown) * 0.5).floor()
	arena_rect.size = shown


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
	toast_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.1))
	toast_label.add_theme_constant_override("outline_size", 8)
	_anchor(toast_label, 0.0, 0.5, 1.0, 0.5, 0.0, -20.0, 0.0, 20.0)
	hud.add_child(toast_label)


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
	head.add_child(UiTheme.label("NEXUS", 24))
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
		if c.idx == 1:
			r1.add_child(_bot_cycle_button(c))
	champ_btn = _action_button("CHAMPION", UiTheme.GOLD)
	champ_btn.pressed.connect(_on_champion)
	r1.add_child(champ_btn)
	for c in sim.casters:
		if c.idx == 2:
			r1.add_child(_bot_cycle_button(c))
	bv.add_child(_barrier_row())
	bv.add_child(_mana_row())
	var r3 := HBoxContainer.new()
	r3.add_theme_constant_override("separation", 6)
	r3.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bv.add_child(r3)
	for i in range(sim.player().spells.size()):
		var b := _spell_button(i)
		r3.add_child(b)
	ult_btn = _ult_button()
	r3.add_child(ult_btn)


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
	lv.add_child(_wrap_label("Clic maintenu : Flux · 1-4 : sorts au curseur · E : Champion · Espace : Ultime · Q/R : ordres · F : tir auto · Échap : pause", 18, UiTheme.MUTED))

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
	for i in range(sim.player().spells.size()):
		var b := _spell_button(i)
		b.custom_minimum_size = Vector2(0, 96)
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
	head.add_child(UiTheme.label("NEXUS", 22))
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
	var b := UiTheme.button("II", 28)
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
	b.custom_minimum_size = Vector2(0, 100)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.clip_text = true
	b.pressed.connect(_on_spell_pressed.bind(i))
	spell_btns.append(b)
	return b


func _ult_button() -> Button:
	var b := UiTheme.button("ULTIME", 18)
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
	view.alpha = clampf(_acc / BattleSim.TICK, 0.0, 1.0)
	if not sim.events.is_empty():
		view.consume_events(sim.events)
		sim.events.clear()
	view.aim_active = aiming != "" and _hover_in
	view.aim_pos = _hover
	_toast_t = maxf(0.0, _toast_t - delta)
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
	nexus_bar.max_value = sim.nexus_max
	nexus_bar.value = sim.nexus_hp
	var info := "%d / %d" % [int(ceil(sim.nexus_hp)), int(sim.nexus_max)]
	if sim.nexus_shielded():
		info += " · SCELLÉ (sceaux %d/%d)" % [sim.seals_purified(), sim.seals_total]
	elif sim.healers_alive() > 0:
		info += " · soin ennemi"
	_set_text(nexus_info, info)
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
	for i in range(spell_btns.size()):
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
	elif not auto_fire and sim.time < 6.0 and not sim.player().firing:
		_set_text(hint_label, "Maintiens sur l'arène pour lancer le Flux, glisse pour viser")
	else:
		_set_text(hint_label, "")
	toast_label.modulate.a = clampf(_toast_t, 0.0, 1.0)


func _set_text(n: Variant, s: String) -> void:
	if n != null and n.text != s:
		n.text = s


func _toast(s: String) -> void:
	toast_label.text = s
	_toast_t = 1.8


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
	return view.to_logic(local / float(_k))


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
		KEY_1, KEY_2, KEY_3, KEY_4:
			var i := int(k - KEY_1)
			if i < spell_btns.size():
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
			sim.cycle_order(1)
		KEY_R:
			sim.cycle_order(2)
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
	view.aim_radius = float(sp.get("radius", 1.0)) if str(sp["type"]) != "purify" else 0.9
	view.aim_color = Color(str(sp.get("color", "FFFFFF")))
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
	view.aim_radius = float(sp.get("radius", 3.0))
	view.aim_color = Color(str(sp.get("color", "B07CFF")))


func _cast_aimed(at: Vector2) -> void:
	if aiming == "ultimate":
		if sim.cast_ultimate(at):
			aiming = ""
		return
	var c := sim.player()
	if sim.cast_spell(c, aiming, at):
		aiming = ""
	elif str(sim.spells_db[aiming]["type"]) == "purify":
		_toast("Aucun portail négatif ici")
	else:
		aiming = ""


func _cancel_aim() -> void:
	aiming = ""


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
	var t := UiTheme.label(title, 40, title_color)
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
	quit.pressed.connect(func() -> void: exit_requested.emit())
	v.add_child(quit)


func _open_end() -> void:
	_end_open = true
	aiming = ""
	var win := sim.state == "victory"
	var v := _modal("VICTOIRE" if win else "DÉFAITE", "Le Nexus est détruit !" if win else "La Barrière est tombée…", UiTheme.GOLD if win else UiTheme.DANGER)
	if win:
		var stars := HBoxContainer.new()
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		stars.add_theme_constant_override("separation", 16)
		for i in range(3):
			var tr := TextureRect.new()
			tr.texture = PixelSprites.star(i < sim.stars)
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(63, 63)
			stars.add_child(tr)
		v.add_child(stars)
		var crit := _wrap_label("1 étoile : victoire · 2 : Barrière > 50 %% · 3 : et en moins de %s" % _fmt_time(sim.par_time), 18, UiTheme.MUTED)
		crit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(crit)
	var stats := _wrap_label("Durée : %s\nEnnemis vaincus : %d\nBarrière : %d / %d\nInvocations : %d (fusions : %d)\nSoins ennemis sur le Nexus : +%d" % [
		_fmt_time(sim.time), sim.kills, int(ceil(sim.barrier_hp)), int(sim.barrier_max), sim.summoned, sim.fusions, int(sim.healed_total)], 22, UiTheme.TEXT)
	v.add_child(stats)
	var again := UiTheme.button("Rejouer", 26)
	again.custom_minimum_size = Vector2(0, 72)
	again.pressed.connect(func() -> void: restart_requested.emit())
	v.add_child(again)
	var menu := UiTheme.button("Menu", 24)
	menu.custom_minimum_size = Vector2(0, 64)
	menu.pressed.connect(func() -> void: exit_requested.emit())
	v.add_child(menu)


func _fmt_time(s: float) -> String:
	var t := int(s)
	return "%d:%02d" % [int(t / 60.0), t % 60]
