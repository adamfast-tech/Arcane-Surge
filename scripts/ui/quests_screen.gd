class_name QuestsScreen
extends Control
## Défis et hauts faits (docs/design/47-defis-hauts-faits.md) : trois défis du jour, deux de la semaine, à réclamer ;
## les hauts faits, chacun avec son titre, et le choix du titre affiché sous le nom du héros.

signal back

const COL := Color("8fd8ff")

var tab := "defis"
var _msg := ""
var _msg_col := UiTheme.GOLD
var _tick: Timer
var _clocks: Array = [] ## [Label, hebdo]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.55, 0.0, "arcane", "archives")
	_tick = Timer.new()
	_tick.wait_time = 1.0
	_tick.autostart = true
	_tick.timeout.connect(_on_tick)
	add_child(_tick)
	# Les hauts faits atteints autrement qu'en combat (étoiles, zones, collection…) se débloquent ici aussi.
	if not Profile.check_achievements().is_empty():
		_save()
	_rebuild()


func _on_tick() -> void:
	for c in _clocks:
		(c[0] as Label).text = _clock(Profile.quest_reset_in(bool(c[1])))
	# Nouveau jour : nouveaux défis.
	if int(Profile._q().get("day", -1)) != Profile.quest_day():
		_rebuild()


static func _clock(sec: int) -> String:
	var d := sec / 86400
	var h := (sec % 86400) / 3600
	var m := (sec % 3600) / 60
	if d > 0:
		return "%d j %d h" % [d, h]
	return "%d h %02d" % [h, m] if h > 0 else "%d min %02d s" % [m, sec % 60]


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	_clocks.clear()
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
	tv.add_child(UiTheme.title("DÉFIS", 46, COL))
	tv.add_child(UiTheme.title("ET HAUTS FAITS", 20, UiTheme.TEXT))
	if _msg != "":
		col.add_child(UiTheme.wrap(_msg, 17, _msg_col))
	col.add_child(_tabs())
	if tab == "hauts":
		_achievements(col)
	else:
		_quests(col)


func _tabs() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var n := Profile.quests_claimable()
	var got := (Profile._q()["ach"] as Dictionary).size()
	for t in [["defis", "DÉFIS", "target", "%d à réclamer" % n if n > 0 else "Du jour et de la semaine"],
			["hauts", "HAUTS FAITS", "star", "%d / %d · titres" % [got, (Profile.quests_db()["achievements"] as Array).size()]]]:
		var on: bool = str(t[0]) == tab
		var rb: Array = UiTheme.rich_button(76, "primary" if on else "tile")
		var bt: Button = rb[0]
		var bh: HBoxContainer = rb[1]
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bh.add_child(UiTheme.icon_rect(str(t[2]), 26, COL if on else UiTheme.MUTED))
		var tvv := VBoxContainer.new()
		tvv.add_theme_constant_override("separation", 0)
		tvv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bh.add_child(tvv)
		tvv.add_child(UiTheme.label(str(t[1]), 18, COL if on else UiTheme.TEXT))
		tvv.add_child(UiTheme.label(str(t[3]), 13, UiTheme.GOLD if str(t[0]) == "defis" and n > 0 else UiTheme.MUTED))
		var id := str(t[0])
		bt.pressed.connect(func() -> void:
			Snd.click()
			tab = id
			_msg = ""
			_rebuild.call_deferred())
		h.add_child(bt)
	return h


# ---------------------------------------------------------------- défis

func _quests(col: VBoxContainer) -> void:
	var qs := Profile.quests()
	for weekly in [false, true]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		col.add_child(row)
		row.add_child(UiTheme.section("Cette semaine" if weekly else "Aujourd'hui", COL))
		row.add_child(UiTheme.spacer())
		row.add_child(UiTheme.icon_rect("moon", 18, UiTheme.MUTED))
		var cl := UiTheme.label(_clock(Profile.quest_reset_in(weekly)), 15, UiTheme.MUTED)
		row.add_child(cl)
		_clocks.append([cl, weekly])
		var list: Array = qs["weekly" if weekly else "daily"]
		for i in range(list.size()):
			col.add_child(_quest_card(list[i], weekly, i))
	col.add_child(UiTheme.wrap("Les défis du jour changent chaque jour, ceux de la semaine chaque semaine. Combats, Forge, Armurerie et Tour des Échos les font avancer.", 15, UiTheme.MUTED))


func _quest_card(e: Dictionary, weekly: bool, i: int) -> PanelContainer:
	var done := Profile.quest_done(e)
	var claimed := bool(e.get("claimed", false))
	var acc := UiTheme.GOLD if done and not claimed else (UiTheme.GOOD if claimed else COL)
	var c: Array = UiTheme.card(Color(acc, 0.6 if done else 0.35), 12)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 8)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(UiTheme.icon_rect("check" if claimed else ("star" if weekly else "target"), 26, acc))
	var t := UiTheme.wrap(Profile.quest_text(e), 18, UiTheme.TEXT if not claimed else UiTheme.MUTED)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var goal := Profile.quest_goal(e)
	var p := mini(int(e.get("p", 0)), goal)
	h.add_child(UiTheme.label("%d / %d" % [p, goal], 16, acc))
	var bar := UiTheme.bar(acc, 8)
	bar.max_value = goal
	bar.value = p
	v.add_child(bar)
	var rr := HBoxContainer.new()
	rr.add_theme_constant_override("separation", 8)
	v.add_child(rr)
	var rw := Profile.quest_reward(e, weekly)
	rr.add_child(GearUi.pill("+%d or" % int(rw["gold"]), UiTheme.GOLD, 14))
	rr.add_child(GearUi.pill("+%d poussière" % int(rw["dust"]), UiTheme.VIOLET, 14))
	if int(rw.get("rune", 0)) > 0:
		rr.add_child(GearUi.pill("Rune niv. %d" % int(rw["rune"]), UiTheme.TEAL, 14))
	if bool(rw.get("cosmetic", false)):
		rr.add_child(GearUi.pill("Curiosité", Color("e0a050"), 14))
	rr.add_child(UiTheme.spacer())
	if claimed:
		rr.add_child(UiTheme.label("Réclamé", 15, UiTheme.GOOD))
	elif done:
		var cb := UiTheme.button("RÉCLAMER", 16)
		cb.custom_minimum_size = Vector2(150, 44)
		cb.add_theme_color_override("font_color", UiTheme.GOLD)
		cb.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.95), Color(UiTheme.GOLD, 0.9), 12, 2, 8, UiTheme.GOLD))
		cb.pressed.connect(func() -> void: _claim(weekly, i))
		rr.add_child(cb)
	return c[0]


func _claim(weekly: bool, i: int) -> void:
	var got := Profile.claim_quest(weekly, i)
	if got.is_empty():
		return
	Snd.sfx("loot_rare" if weekly else "ui_coin", -3.0)
	var parts: Array[String] = ["+%d or" % int(got["gold"]), "+%d poussière" % int(got["dust"])]
	if got.has("rune"):
		parts.append(Profile.rune_name(got["rune"]))
	if got.has("cosmetic"):
		parts.append("curiosité : %s" % str(Profile.cosmetic_info(str(got["cosmetic"])).get("name", "")))
	_msg = "Récompense : " + " · ".join(parts)
	_msg_col = UiTheme.GOLD
	_save()
	_rebuild.call_deferred()


# ---------------------------------------------------------------- hauts faits

func _achievements(col: VBoxContainer) -> void:
	# Titre affiché sous le nom du héros (Havre-Aube, carte du héros, Tour des Échos).
	var c: Array = UiTheme.card(Color(UiTheme.GOLD, 0.45), 12)
	col.add_child(c[0])
	var v: VBoxContainer = c[1]
	v.add_child(UiTheme.label("TITRE AFFICHÉ", 14, UiTheme.MUTED))
	var cur := Profile.title()
	v.add_child(UiTheme.title(cur if cur != "" else "Aucun", 26, UiTheme.GOLD if cur != "" else UiTheme.MUTED))
	v.add_child(UiTheme.wrap("Touche un haut fait débloqué pour porter son titre.", 14, UiTheme.MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	col.add_child(grid)
	var cur_id := str(Profile._q().get("title", ""))
	for a in Profile.quests_db()["achievements"]:
		grid.add_child(_ach_tile(a, str(a["id"]) == cur_id))


func _ach_tile(a: Dictionary, worn: bool) -> Button:
	var on := Profile.achievement_unlocked(str(a["id"]))
	var st := Profile.ach_state(a)
	var acc := UiTheme.GOLD if on else UiTheme.MUTED
	var rb: Array = UiTheme.rich_button(104, "primary" if worn else "tile")
	var bt: Button = rb[0]
	var bh: HBoxContainer = rb[1]
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bt.disabled = not on
	if not on:
		bt.modulate = Color(1, 1, 1, 0.72)
	bh.add_child(UiTheme.icon_rect("star_fill" if on else "lock", 26, acc))
	var tvv := VBoxContainer.new()
	tvv.add_theme_constant_override("separation", 1)
	tvv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tvv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(tvv)
	tvv.add_child(UiTheme.label(str(a["name"]), 17, UiTheme.TEXT if on else UiTheme.MUTED))
	var tl := UiTheme.label("« %s »" % str(a["title"]), 14, acc)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tvv.add_child(tl)
	if not on:
		var pb := UiTheme.bar(COL, 6)
		pb.max_value = int(st[1])
		pb.value = int(st[0])
		tvv.add_child(pb)
		tvv.add_child(UiTheme.label("%d / %d" % [int(st[0]), int(st[1])], 12, UiTheme.MUTED))
	elif worn:
		tvv.add_child(UiTheme.label("Titre porté", 12, UiTheme.GOOD))
	var id := str(a["id"])
	bt.pressed.connect(func() -> void:
		Snd.click()
		Profile.set_title("" if worn else id)
		_save()
		_rebuild.call_deferred())
	return bt


func _save() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
