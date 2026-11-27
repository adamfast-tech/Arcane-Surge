class_name TowerScreen
extends Control
## La Tour des Échos (docs/design/48-tour-des-echos.md) : commencer ou poursuivre l'ascension, choisir un bonus entre
## deux étages, les records, et le classement de la semaine avec le podium des trois premiers en volume.

signal back
signal climb ## monter à l'étage suivant

const COL := Color("b07cff")

var _board: Array = []
var _board_state := "idle" ## idle, loading, ok, offline
var _msg := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.5, 0.0, "arcane", "meditation")
	_rebuild()
	_sync_board()


## Envoie le record de la semaine s'il a progressé, puis charge le classement.
func _sync_board() -> void:
	if Cloud.instance == null:
		_board_state = "offline"
		_rebuild.call_deferred()
		return
	_board_state = "loading"
	var t: Dictionary = Profile._tw()
	var wb := Profile.tower_week_best()
	if Cloud.instance.is_online() and wb > 0 and (int(t.get("sent_week", -1)) != Profile.quest_week() or int(t.get("sent", 0)) < wb):
		var got: int = await Cloud.instance.tower_submit(wb, Profile.player_class(), Profile.race(), Profile.look(), Profile.visible_cosmetics(), Profile.gear_look())
		if got >= 0 and is_inside_tree():
			t["sent"] = wb
			t["sent_week"] = Profile.quest_week()
			Profile.save_local()
	var rows: Array = await Cloud.instance.tower_board()
	if not is_inside_tree():
		return
	_board = rows
	_board_state = "ok"
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 14)
	var head := HBoxContainer.new()
	col.add_child(head)
	var b := UiTheme.back_button("Havre-Aube")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	head.add_child(UiTheme.currencies())
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("TOUR DES ÉCHOS", 44, COL))
	tv.add_child(UiTheme.title("ASCENSION SANS FIN", 20, UiTheme.TEXT))
	col.add_child(UiTheme.wrap("Chaque étage est plus dur que le précédent : un mini-boss tous les 5 étages, un boss tous les 10. Entre deux étages, choisis un bonus qui dure toute l'ascension. Une défaite y met fin ; ton meilleur étage de la semaine entre au classement.", 16, UiTheme.MUTED))
	if _msg != "":
		col.add_child(UiTheme.wrap(_msg, 17, UiTheme.GOLD))
	var run := Profile.tower_run()
	if not run.is_empty() and not (run.get("choice", []) as Array).is_empty():
		_boon_choice(col, run)
	else:
		col.add_child(_run_card(run))
	col.add_child(_records())
	_board_view(col)


func _run_card(run: Dictionary) -> PanelContainer:
	var c: Array = UiTheme.card(Color(COL, 0.55), 14)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 10)
	if run.is_empty():
		v.add_child(UiTheme.title("LA TOUR T'ATTEND", 26, COL))
		v.add_child(UiTheme.wrap("Tes compagnons du Cercle montent avec toi. Ton équipement, tes runes et tes cosmétiques comptent.", 16, UiTheme.TEXT))
		var go := UiTheme.button("COMMENCER L'ASCENSION", 22)
		go.custom_minimum_size = Vector2(0, 64)
		go.add_theme_color_override("font_color", UiTheme.GOLD)
		go.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.95), Color(UiTheme.GOLD, 0.9), 12, 2, 8, UiTheme.GOLD))
		go.pressed.connect(func() -> void:
			Snd.click()
			Profile.tower_start()
			Profile.save_local()
			climb.emit())
		v.add_child(go)
		return c[0]
	var floor := int(run["floor"])
	var lv := Profile.tower_level(floor, int(run["seed"]))
	var tw: Dictionary = lv.get("tower", {})
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var badge := VBoxContainer.new()
	badge.add_theme_constant_override("separation", 0)
	h.add_child(badge)
	badge.add_child(UiTheme.label("ÉTAGE", 14, UiTheme.MUTED))
	badge.add_child(UiTheme.title(str(floor), 54, UiTheme.GOLD))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	h.add_child(info)
	var kind := "BOSS" if bool(tw.get("boss", false)) else ("MINI-BOSS" if bool(tw.get("mini", false)) else str(lv.get("type", "")).to_upper())
	info.add_child(UiTheme.label(kind, 16, UiTheme.DANGER if kind.contains("BOSS") else COL))
	info.add_child(UiTheme.label(str(lv.get("name", "")), 22, UiTheme.TEXT))
	var zn := ""
	for zd in GameData.level_index()["zones"]:
		if int(zd["id"]) == int(tw.get("zone", 1)):
			zn = str(zd["name"])
	info.add_child(UiTheme.label("%s · ennemis renforcés ×%.2f" % [zn, 1.0 + 0.03 * float(floor - 1)], 15, UiTheme.MUTED))
	var boons: Array = run.get("boons", [])
	if not boons.is_empty():
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		v.add_child(flow)
		var counts := {}
		for id in boons:
			counts[id] = int(counts.get(id, 0)) + 1
		for id in counts.keys():
			var bd := Profile.tower_boon(str(id))
			flow.add_child(GearUi.pill("%s%s" % [str(bd.get("name", id)), (" ×%d" % int(counts[id])) if int(counts[id]) > 1 else ""], COL, 14))
	v.add_child(UiTheme.label("Gains de l'ascension : %d or · %d poussière" % [int(run.get("gold", 0)), int(run.get("dust", 0))], 15, UiTheme.GOLD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var go2 := UiTheme.button("MONTER À L'ÉTAGE %d" % floor, 21)
	go2.custom_minimum_size = Vector2(0, 62)
	go2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go2.add_theme_color_override("font_color", UiTheme.GOLD)
	go2.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.95), Color(UiTheme.GOLD, 0.9), 12, 2, 8, UiTheme.GOLD))
	go2.pressed.connect(func() -> void:
		Snd.click()
		climb.emit())
	row.add_child(go2)
	var stop := UiTheme.button("Abandonner", 17)
	stop.custom_minimum_size = Vector2(0, 62)
	stop.pressed.connect(func() -> void:
		Profile.tower_abandon()
		Profile.save_local()
		_msg = "Ascension terminée à l'étage %d." % (floor - 1)
		_rebuild.call_deferred())
	row.add_child(stop)
	return c[0]


func _boon_choice(col: VBoxContainer, run: Dictionary) -> void:
	col.add_child(UiTheme.section("Étage %d franchi : choisis un bonus" % (int(run["floor"]) - 1), UiTheme.GOLD))
	for id in run["choice"]:
		var bd := Profile.tower_boon(str(id))
		var rb: Array = UiTheme.rich_button(88, "tile")
		var bt: Button = rb[0]
		var bh: HBoxContainer = rb[1]
		bt.add_theme_stylebox_override("normal", UiTheme.box(Color(COL.darkened(0.82), 0.95), Color(COL, 0.6), 14, 2, 10, COL))
		var ic := TextureRect.new()
		ic.texture = Icons.tex(str(bd.get("icon", "star")), 96)
		ic.custom_minimum_size = Vector2(52, 52)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bh.add_child(ic)
		var tvv := VBoxContainer.new()
		tvv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tvv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bh.add_child(tvv)
		tvv.add_child(UiTheme.label(str(bd.get("name", id)), 21, UiTheme.GOLD))
		tvv.add_child(UiTheme.label(str(bd.get("desc", "")), 16, UiTheme.TEXT))
		var id2 := str(id)
		bt.pressed.connect(func() -> void:
			Snd.sfx("rune_glow", -6.0)
			Profile.tower_pick_boon(id2)
			Profile.save_local()
			_msg = "Bonus : %s." % str(bd.get("name", id2))
			_rebuild.call_deferred())
		col.add_child(bt)


func _records() -> PanelContainer:
	var c: Array = UiTheme.card(Color(UiTheme.GOLD, 0.35), 12)
	var v: VBoxContainer = c[1]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	for pair in [["RECORD", Profile.tower_best()], ["CETTE SEMAINE", Profile.tower_week_best()]]:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 0)
		h.add_child(box)
		var l := UiTheme.label(str(pair[0]), 14, UiTheme.MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
		var n := UiTheme.title("Étage %d" % int(pair[1]), 28, UiTheme.GOLD)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(n)
	var last: Dictionary = Profile._tw().get("last", {})
	if not last.is_empty():
		v.add_child(UiTheme.label("Dernière ascension : étage %d · %d or · %d poussière" % [int(last.get("floor", 0)), int(last.get("gold", 0)), int(last.get("dust", 0))], 15, UiTheme.MUTED))
	return c[0]


# ---------------------------------------------------------------- classement

func _board_view(col: VBoxContainer) -> void:
	var sec := HBoxContainer.new()
	col.add_child(sec)
	sec.add_child(UiTheme.section("Classement de la semaine", COL))
	if _board_state == "loading":
		col.add_child(UiTheme.wrap("Chargement du classement…", 16, UiTheme.MUTED))
		return
	if _board_state == "offline" or (_board.is_empty() and (Cloud.instance == null or not Cloud.instance.is_online())):
		col.add_child(UiTheme.wrap("Connecte-toi à ton compte (Sauvegarde) pour figurer au classement et le consulter.", 16, UiTheme.MUTED))
		return
	if _board.is_empty():
		col.add_child(UiTheme.wrap("Personne n'a encore grimpé cette semaine : sois le premier !", 16, UiTheme.MUTED))
		return
	col.add_child(_podium())
	var me := Cloud.instance.username if Cloud.instance != null else ""
	for i in range(3, _board.size()):
		var row: Dictionary = _board[i]
		var mine := str(row.get("username", "")) == me and me != ""
		var c: Array = UiTheme.card(Color(UiTheme.GOLD if mine else UiTheme.BORDER, 0.5 if mine else 0.3), 8)
		var hv: VBoxContainer = c[1]
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		hv.add_child(h)
		h.add_child(UiTheme.label("%d." % int(row.get("rank", i + 1)), 17, UiTheme.MUTED))
		var nl := UiTheme.label(str(row.get("username", "?")), 17, UiTheme.GOLD if mine else UiTheme.TEXT)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nl)
		h.add_child(UiTheme.label("%s · étage %d" % [_class_name(str(row.get("cls", ""))), int(row.get("floor", 0))], 16, COL))
		col.add_child(c[0])


static func _class_name(cls: String) -> String:
	return str((GameData.party()["classes"] as Dictionary).get(cls, {}).get("name", cls))


## Les trois premiers en volume, sur des marches (2e, 1er, 3e), avec leur allure de la semaine.
func _podium() -> Control:
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 360)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var order := [1, 0, 2]
	var steps := [124.0, 88.0, 66.0] ## hauteur de la marche, par rang
	var cols := [UiTheme.GOLD, Color("d8dce8"), Color("d08a4a")]
	for k in range(3):
		var idx: int = order[k]
		if idx >= _board.size():
			continue
		var row: Dictionary = _board[idx]
		var x := 0.2 + 0.3 * float(k)
		var step := Panel.new()
		step.add_theme_stylebox_override("panel", UiTheme.box(Color((cols[idx] as Color).darkened(0.75), 0.95), Color(cols[idx], 0.8), 8, 2, 0))
		step.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		stage.add_child(step)
		step.set_meta("x", x)
		step.set_meta("h", steps[idx])
		var tt := HeroTurntable.new()
		tt.interactive = false
		tt.px_scale = 4
		tt.yaw = PI + (0.35 if k == 0 else (-0.35 if k == 2 else 0.0))
		var m := HeroModel.of(row.get("look", {}) if row.get("look") is Dictionary else {}, str(row.get("race", "humain")), str(row.get("cls", "mage")),
			row.get("cos", {}) if row.get("cos") is Dictionary else {}, row.get("gear", {}) if row.get("gear") is Dictionary else {})
		tt.setup_model(m)
		stage.add_child(tt)
		if idx == 0:
			tt.play_for("victory", 3.0)
		var nm := UiTheme.label("%d. %s" % [idx + 1, str(row.get("username", "?"))], 16, cols[idx])
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stage.add_child(nm)
		var fl := UiTheme.label("Étage %d" % int(row.get("floor", 0)), 15, UiTheme.TEXT)
		fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stage.add_child(fl)
		stage.resized.connect(func() -> void:
			var w := stage.size.x
			var sh := float(steps[idx])
			step.position = Vector2(w * x - 80.0, stage.size.y - sh)
			step.size = Vector2(160.0, sh)
			tt.size = tt.custom_minimum_size
			tt.position = Vector2(w * x - tt.size.x * 0.5, stage.size.y - sh - tt.size.y + 6.0)
			nm.position = Vector2(w * x - 80.0, stage.size.y - sh + 8.0)
			nm.size = Vector2(160.0, 24.0)
			fl.position = Vector2(w * x - 80.0, stage.size.y - sh + 32.0)
			fl.size = Vector2(160.0, 24.0))
	return stage
