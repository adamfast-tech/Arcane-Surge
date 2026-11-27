class_name ForgeScreen
extends Control
## La Forge de Durgan (docs/design/35-equipement-runes-forge.md). Durgan, en bandeau, commente ce qu'on fait.
## - GRAVURE : choisir l'objet (grille), le poser sur l'enclume (ses emplacements de runes en grand), choisir
##   une rune (grille) : son effet sur ce type d'objet s'affiche, puis Graver ; une rune gravée se retire ;
## - FUSION : 3 objets de même rareté posés dans le cercle rituel → 1 objet de la rareté au-dessus
##   (3 légendaires → Mythique) ; un objet issu d'une fusion peut refusionner ;
## - RUNES : la réserve en grille, la fusion de 3 runes identiques (niveau +1) et le recyclage.

signal back

var tab := "gravure"
var focus_item := "" ## objet posé sur l'enclume (gravure)
var back_label := "Havre-Aube"
var _sel: Array[String] = [] ## sélection pour une fusion (objets ou runes)
var _rune_pick := "" ## rune choisie pour la gravure
var _socket := -1 ## emplacement gravé touché (gravure)
var _msg := ""
var _msg_col := UiTheme.GOLD

const TABS := [["gravure", "GRAVURE", "rune", "Runes sur un objet"], ["fusion", "FUSION", "forge", "3 objets en 1 meilleur"],
	["runes", "RUNES", "sparkle", "Réserve, fusion, recyclage"]]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.5, 0.0, "forge", "forge")
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 14)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	var b := UiTheme.back_button(back_label)
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	head.add_child(GearUi.purse())
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("LA FORGE", 46, UiTheme.FIRE))
	tv.add_child(UiTheme.title("DE DURGAN ENCLUME", 20, UiTheme.TEXT))
	col.add_child(GearUi.speaker_banner("durgan", "Durgan", "Maître de la Forge", _msg if _msg != "" else _flavor(), _msg_col if _msg != "" else UiTheme.TEXT))
	col.add_child(_tabs())
	match tab:
		"fusion":
			_fusion(col)
		"runes":
			_runes(col)
		_:
			_gravure(col)


## Ce que dit Durgan, selon l'atelier et ce qui est choisi.
func _flavor() -> String:
	match tab:
		"fusion":
			return "Trois pièces de même lignée, et j'en tire une meilleure. La première que tu poses donne sa forme."
		"runes":
			return "Trois runes jumelles se fondent en une plus forte. Les autres, je les réduis en poussière d'arcane."
	if Profile.find_item(focus_item).is_empty():
		return "Montre-moi ce que tu portes. Une même rune ne chante pas pareil sur une lame et sur une cuirasse."
	if _rune_pick != "":
		return "Bon choix. Pose-la sur un emplacement libre, je m'occupe du reste."
	return "Choisis une rune dans ta besace : je te dis ce qu'elle fera sur ce métal-là."


func _tabs() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for t in TABS:
		var id := str(t[0])
		var on := id == tab
		var parts: Array = UiTheme.rich_button(74, "primary" if on else "tile")
		var bt: Button = parts[0]
		var h: HBoxContainer = parts[1]
		h.add_theme_constant_override("separation", 8)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(UiTheme.icon_rect(str(t[2]), 26, UiTheme.FIRE if on else UiTheme.MUTED))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(v)
		var name := str(t[1]) + (" · %d" % Profile.rune_inventory().size() if id == "runes" else "")
		var l1 := UiTheme.label(name, 19, UiTheme.GOLD if on else UiTheme.TEXT)
		l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l1)
		var l2 := UiTheme.label(str(t[3]), 13, UiTheme.MUTED)
		l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l2)
		bt.pressed.connect(func() -> void:
			Snd.click()
			tab = id
			_sel.clear()
			_rune_pick = ""
			_socket = -1
			_msg = ""
			_rebuild.call_deferred())
		row.add_child(bt)
	return row


# ---------------------------------------------------------------- gravure

func _gravure(col: VBoxContainer) -> void:
	var it := Profile.find_item(focus_item)
	if it.is_empty():
		var worn: Array = []
		var reserve: Array = []
		for x in Profile.data["inventory"]:
			if Profile.sockets_of(x) <= 0:
				continue
			if Profile.holder_of(str(x["uid"])) != "":
				worn.append(x)
			else:
				reserve.append(x)
		reserve.sort_custom(EquipmentScreen._item_order)
		col.add_child(UiTheme.section("Objets portés · %d" % worn.size()))
		col.add_child(_pick_grid(worn))
		col.add_child(UiTheme.section("En réserve · %d" % reserve.size()))
		col.add_child(_pick_grid(reserve))
		return
	col.add_child(_anvil(it))
	var cat := Profile.rune_category(str(Profile.base_of(it).get("slot", "")))
	var catn := str(Profile.runes_db()["category_names"].get(cat, cat))
	if _socket >= 0 and _socket < (it.get("runes", []) as Array).size():
		col.add_child(_engraved_card(it, cat))
	var inv := Profile.rune_inventory()
	col.add_child(UiTheme.section("Ta besace de runes · effet sur %s" % catn.to_lower()))
	if inv.is_empty():
		col.add_child(UiTheme.wrap("Aucune rune en réserve. Chaque étoile gagnée donne une chance d'en obtenir une, et chaque boss en garantit une.", 17, UiTheme.MUTED))
		return
	if _rune_pick != "" and not Profile.find_rune(_rune_pick).is_empty():
		col.add_child(_engrave_card(it, Profile.find_rune(_rune_pick), cat))
	var list := inv.duplicate()
	list.sort_custom(_rune_order)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	col.add_child(grid)
	for r in list:
		var ruid := str(r["uid"])
		var rb := GearUi.rune_button(r, 100, ruid == _rune_pick, Profile.engrave_block(it, r) != "")
		rb.tooltip_text = "%s · %s" % [Profile.rune_name(r), Profile.rune_effect_text(r, cat)]
		rb.pressed.connect(func() -> void:
			_rune_pick = "" if _rune_pick == ruid else ruid
			_socket = -1
			_msg = ""
			_rebuild.call_deferred())
		grid.add_child(rb)


func _pick_grid(items: Array) -> Control:
	if items.is_empty():
		return UiTheme.wrap("Aucun objet à graver ici.", 16, UiTheme.MUTED)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for x in items:
		var uid := str(x["uid"])
		var holder := Profile.holder_of(uid)
		var tag := "" if holder == "" else ("toi" if holder == "player" else Dialogues.display_name(holder))
		var b := GearUi.item_button(x, str(Profile.base_of(x).get("slot", "")), 100, false, 0, tag)
		b.tooltip_text = Profile.item_name(x)
		b.pressed.connect(func() -> void:
			focus_item = uid
			_rune_pick = ""
			_socket = -1
			_msg = ""
			_rebuild.call_deferred())
		grid.add_child(b)
	return grid


## L'enclume : l'objet en grand, puis ses emplacements de runes en grand (gravés ou libres).
func _anvil(it: Dictionary) -> PanelContainer:
	var c: Array = UiTheme.card(Color(UiTheme.FIRE, 0.55), 16)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(124, 124)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(stage)
	var glow := GearUi.pedestal(UiTheme.FIRE, 124, 124)
	stage.add_child(glow)
	var tile := GearUi.item_button(it, str(Profile.base_of(it).get("slot", "")), 108)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.position = Vector2(8, 8)
	stage.add_child(tile)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var cat := Profile.rune_category(str(Profile.base_of(it).get("slot", "")))
	var catn := str(Profile.runes_db()["category_names"].get(cat, cat))
	info.add_child(UiTheme.label("SUR L'ENCLUME", 15, UiTheme.FIRE))
	info.add_child(UiTheme.label(Profile.item_name(it), 24, Profile.item_color(it)))
	var n := Profile.sockets_of(it)
	info.add_child(UiTheme.label("%s · catégorie %s · %d emplacement%s" % [str(Profile.rarity_of(it).get("name", "")), catn, n, "s" if n > 1 else ""], 15, UiTheme.MUTED))
	info.add_child(GearUi.stat_chips(Profile.item_stats(it), 15))
	var other := UiTheme.button("Changer d'objet", 16)
	other.custom_minimum_size = Vector2(0, 42)
	other.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	other.pressed.connect(func() -> void:
		focus_item = ""
		_rune_pick = ""
		_socket = -1
		_msg = ""
		_rebuild.call_deferred())
	info.add_child(other)
	# Emplacements de runes.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var runes: Array = it.get("runes", [])
	for i in range(n):
		var sv := VBoxContainer.new()
		sv.add_theme_constant_override("separation", 4)
		row.add_child(sv)
		var idx := i
		if i < runes.size():
			var r: Dictionary = runes[i]
			var rb := GearUi.rune_button(r, 84, _socket == i)
			rb.pressed.connect(func() -> void:
				_socket = -1 if _socket == idx else idx
				_rune_pick = ""
				_msg = ""
				_rebuild.call_deferred())
			sv.add_child(rb)
			var l := UiTheme.label(Profile.rune_name(r), 14, Profile.rune_color(r))
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv.add_child(l)
		else:
			var e := Button.new()
			e.focus_mode = Control.FOCUS_NONE
			e.custom_minimum_size = Vector2(84, 84)
			var ready := _rune_pick != ""
			var bd := UiTheme.GOLD if ready else Color(UiTheme.MUTED, 0.5)
			e.add_theme_stylebox_override("normal", UiTheme.box(Color(0, 0, 0, 0.35), bd, 30, 2, 0, UiTheme.GOLD if ready else Color(0, 0, 0, 0)))
			e.add_theme_stylebox_override("hover", UiTheme.box(Color(0, 0, 0, 0.25), UiTheme.GOLD, 30, 2, 0))
			e.add_theme_stylebox_override("pressed", UiTheme.box(Color(0, 0, 0, 0.5), UiTheme.GOLD, 30, 2, 0))
			e.text = "+" if ready else ""
			e.add_theme_font_size_override("font_size", 34)
			e.add_theme_color_override("font_color", UiTheme.GOLD)
			e.disabled = not ready or Profile.engrave_block(it, Profile.find_rune(_rune_pick)) != ""
			e.pressed.connect(func() -> void: _engrave(it, cat))
			sv.add_child(e)
			var l2 := UiTheme.label("libre", 14, UiTheme.MUTED)
			l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv.add_child(l2)
	if bool(it.get("fused", false)):
		v.add_child(UiTheme.label("Issu d'une fusion", 15, UiTheme.FIRE))
	return c[0]


## Rune gravée touchée : son effet, et la retirer (elle revient dans la besace).
func _engraved_card(it: Dictionary, cat: String) -> PanelContainer:
	var r: Dictionary = (it.get("runes", []) as Array)[_socket]
	var c: Array = UiTheme.card(Color(Profile.rune_color(r), 0.6), 14)
	var v: VBoxContainer = c[1]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiTheme.label("%s · %s" % [Profile.rune_name(r), str(Profile.rarity_of(r).get("name", ""))], 21, Profile.rune_color(r)))
	info.add_child(UiTheme.wrap(Profile.rune_effect_text(r, cat), 18, UiTheme.TEAL))
	var idx := _socket
	var rm := UiTheme.button("Retirer · %d or" % Profile.unengrave_cost(r), 17)
	rm.custom_minimum_size = Vector2(170, 52)
	rm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rm.disabled = Profile.gold() < Profile.unengrave_cost(r)
	rm.pressed.connect(func() -> void: _act(func() -> void:
		if Profile.unengrave(focus_item, idx):
			Snd.sfx("piege_hit", -8.0, 1.2)
			_say("Rune retirée : elle retourne dans ta besace.")
		_socket = -1))
	h.add_child(rm)
	return c[0]


## Rune choisie : son effet sur cet objet, ce qui l'empêche, le prix, et Graver.
func _engrave_card(it: Dictionary, r: Dictionary, cat: String) -> PanelContainer:
	var why := Profile.engrave_block(it, r)
	var c: Array = UiTheme.card(UiTheme.GOLD if why == "" else Color(UiTheme.MUTED, 0.6), 14)
	var v: VBoxContainer = c[1]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var rb := GearUi.rune_button(r, 72)
	rb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(rb)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiTheme.label("%s · %s · %s" % [Profile.rune_name(r), str(Profile.rune_family(r).get("theme", "")), str(Profile.rarity_of(r).get("name", ""))], 19, Profile.rune_color(r)))
	info.add_child(UiTheme.wrap(Profile.rune_effect_text(r, cat), 19, UiTheme.TEAL))
	if why != "":
		info.add_child(UiTheme.label(why, 15, UiTheme.DANGER))
	var g := UiTheme.button("GRAVER · %d or" % Profile.engrave_cost(r), 19)
	g.icon = Icons.tex("forge", 40)
	g.add_theme_constant_override("icon_max_width", 20)
	g.custom_minimum_size = Vector2(0, 56)
	g.disabled = why != ""
	if why == "":
		g.add_theme_color_override("font_color", UiTheme.GOLD)
		g.add_theme_color_override("icon_normal_color", UiTheme.GOLD)
		g.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.85), 12, 2, 8, UiTheme.GOLD))
	g.pressed.connect(func() -> void: _engrave(it, cat))
	v.add_child(g)
	return c[0]


func _engrave(it: Dictionary, cat: String) -> void:
	var ruid := _rune_pick
	if ruid == "":
		return
	_act(func() -> void:
		var rr := Profile.find_rune(ruid)
		var name := Profile.rune_name(rr)
		var before := Profile.find_item(focus_item).duplicate(true)
		var rune_copy := rr.duplicate(true)
		var effect := Profile.rune_effect_text(rr, cat)
		if Profile.engrave(focus_item, ruid):
			_say("%s gravée : %s." % [name, effect])
			# Durgan grave la rune, de face, sous nos yeux.
			add_child(ForgeScene.engraving(before, rune_copy, Profile.find_item(focus_item).duplicate(true), effect))
		_rune_pick = "")


# ---------------------------------------------------------------- fusion d'équipement

## Cercle rituel dessiné derrière les emplacements de la fusion.
class Ritual extends Control:
	var col := Color("ff9b4a")

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.46
		for k in range(3):
			draw_arc(c, r * (1.0 - 0.14 * float(k)), 0.0, TAU, 96, Color(col, 0.28 - 0.07 * float(k)), 2.0, true)
		for i in range(24):
			var a := float(i) / 24.0 * TAU
			var p := c + Vector2.from_angle(a) * r * 0.93
			draw_line(p, c + Vector2.from_angle(a) * r * (0.86 if i % 2 == 0 else 0.9), Color(col, 0.35), 2.0)
		var tri := PackedVector2Array()
		for i in range(4):
			tri.append(c + Vector2.from_angle(-PI * 0.5 + float(i % 3) * TAU / 3.0) * r * 0.72)
		draw_polyline(tri, Color(col, 0.18), 2.0, true)


func _fusion(col: VBoxContainer) -> void:
	var chosen: Array = []
	for u in _sel:
		var x := Profile.find_item(u)
		if not x.is_empty():
			chosen.append(x)
	var c: Array = UiTheme.card(Color(UiTheme.FIRE, 0.7), 14)
	col.add_child(c[0])
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 10)
	var stack := PanelContainer.new()
	stack.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	stack.custom_minimum_size = Vector2(0, 190)
	v.add_child(stack)
	var ring := Ritual.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(ring)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(center)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 10)
	center.add_child(slots)
	for i in range(3):
		if i < chosen.size():
			var uid := str((chosen[i] as Dictionary)["uid"])
			var t := GearUi.item_button(chosen[i], "", 92, true)
			t.tooltip_text = "Retirer de la fusion"
			t.pressed.connect(func() -> void:
				_sel.erase(uid)
				_rebuild.call_deferred())
			slots.add_child(t)
		else:
			var e := GearUi.item_button({}, "", 92)
			e.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slots.add_child(e)
	slots.add_child(UiTheme.icon_rect("chevron", 30, UiTheme.GOLD))
	var next := Profile.fusion_next(str((chosen[0] as Dictionary).get("rarity", ""))) if not chosen.is_empty() else ""
	var nr: Dictionary = (Profile.items_db()["rarities"] as Dictionary).get(next, {})
	var ncol := Color(str(nr.get("color", "5e5e6a")))
	if not chosen.is_empty():
		var preview := {"uid": "?", "base": str((chosen[0] as Dictionary)["base"]), "rarity": next, "ilvl": 1, "up": 0, "stats": {}, "affixes": {}}
		var res := GearUi.item_button(preview, "", 104, false)
		res.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slots.add_child(res)
	else:
		var res2 := GearUi.item_button({}, "", 104)
		res2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slots.add_child(res2)
	if chosen.is_empty():
		var l := UiTheme.label("Touche 3 objets de même rareté dans ta réserve.", 18, UiTheme.MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	else:
		var first: Dictionary = chosen[0]
		var ilvl := 1
		for x in chosen:
			ilvl = maxi(ilvl, int((x as Dictionary).get("ilvl", 1)))
		var l2 := UiTheme.label("%s · %s · iLvl %d · %d emplacement%s de runes" % [str(Profile.base_of(first).get("name", "")), str(nr.get("name", "")), ilvl, int(nr.get("sockets", 1)), "s" if int(nr.get("sockets", 1)) > 1 else ""], 18, ncol)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l2)
	var why := Profile.fusion_block(_sel)
	var go := UiTheme.button("FUSIONNER · %d or" % Profile.fusion_cost(chosen) if not chosen.is_empty() else "FUSIONNER", 21)
	go.custom_minimum_size = Vector2(0, 60)
	go.disabled = why != ""
	if why == "":
		go.add_theme_color_override("font_color", UiTheme.GOLD)
		go.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.85), 12, 2, 8, UiTheme.GOLD))
	go.pressed.connect(func() -> void: _act(func() -> void:
		var objs: Array = []
		for uid in _sel:
			var x := Profile.find_item(str(uid))
			if not x.is_empty():
				objs.append(x.duplicate(true))
		var out := Profile.fuse_items(_sel)
		_sel.clear()
		if not out.is_empty():
			_say("Fusion réussie : %s (%s) !" % [Profile.item_name(out), str(Profile.rarity_of(out).get("name", ""))])
			# Durgan rabat ses lunettes et forge la fusion sous nos yeux.
			add_child(ForgeScene.fusion(objs, out.duplicate(true)))))
	v.add_child(go)
	if why != "" and not chosen.is_empty():
		var wl := UiTheme.label(why, 16, UiTheme.MUTED)
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(wl)
	var list: Array = []
	for x in Profile.data["inventory"]:
		if Profile.holder_of(str(x["uid"])) == "":
			list.append(x)
	list.sort_custom(EquipmentScreen._item_order)
	col.add_child(UiTheme.section("Ta réserve · %d objet%s" % [list.size(), "s" if list.size() > 1 else ""]))
	if list.is_empty():
		col.add_child(UiTheme.wrap("Rien en réserve : les objets équipés ne fusionnent pas.", 17, UiTheme.MUTED))
		return
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	col.add_child(grid)
	for x in list:
		grid.add_child(_fusion_tile(x, chosen))


func _fusion_tile(it: Dictionary, chosen: Array) -> Button:
	var uid := str(it["uid"])
	var picked := _sel.has(uid)
	var why := Profile.fusion_item_block(it)
	if why == "" and not chosen.is_empty() and not picked and str((chosen[0] as Dictionary)["rarity"]) != str(it["rarity"]):
		why = "Autre rareté que la sélection"
	var b := GearUi.item_button(it, str(Profile.base_of(it).get("slot", "")), 100, picked, 0, "", why != "" and not picked)
	b.tooltip_text = Profile.item_name(it) + ((" · " + why) if why != "" and not picked else "")
	if picked:
		var ck := UiTheme.icon_rect("check", 26, UiTheme.GOLD)
		ck.position = Vector2(6, 6)
		b.add_child(ck)
	b.disabled = why != "" and not picked
	b.pressed.connect(func() -> void:
		if _sel.has(uid):
			_sel.erase(uid)
		elif _sel.size() < 3:
			_sel.append(uid)
		_msg = ""
		_rebuild.call_deferred())
	return b


# ---------------------------------------------------------------- réserve de runes

func _runes(col: VBoxContainer) -> void:
	var inv := Profile.rune_inventory().duplicate()
	if inv.is_empty():
		col.add_child(UiTheme.wrap("Aucune rune en réserve. Chaque étoile gagnée donne une chance d'en obtenir une, et chaque boss en garantit une.", 17, UiTheme.MUTED))
		return
	# Sélection : la fusion de 3 runes jumelles.
	var bar: Array = UiTheme.card(Color(UiTheme.GOLD, 0.5) if _sel.size() == 3 else UiTheme.BORDER, 12)
	col.add_child(bar[0])
	var bv: VBoxContainer = bar[1]
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 10)
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	bv.add_child(srow)
	for i in range(3):
		if i < _sel.size():
			var rb := GearUi.rune_button(Profile.find_rune(_sel[i]), 72, true)
			rb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			srow.add_child(rb)
		else:
			var e := PanelContainer.new()
			e.custom_minimum_size = Vector2(72, 72)
			e.add_theme_stylebox_override("panel", UiTheme.box(Color(0, 0, 0, 0.3), Color(UiTheme.MUTED, 0.45), 26, 1, 4))
			srow.add_child(e)
	srow.add_child(UiTheme.icon_rect("chevron", 26, UiTheme.GOLD))
	var why := Profile.rune_fuse_block(_sel) if not _sel.is_empty() else "Choisis 3 runes identiques"
	var first := Profile.find_rune(_sel[0]) if not _sel.is_empty() else {}
	var go := UiTheme.button("FUSIONNER %d/3%s" % [_sel.size(), (" · %d or" % Profile.rune_fuse_cost(first)) if not first.is_empty() else ""], 19)
	go.custom_minimum_size = Vector2(0, 56)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.disabled = why != ""
	if why == "":
		go.add_theme_color_override("font_color", UiTheme.GOLD)
		go.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.85), 12, 2, 8, UiTheme.GOLD))
	go.pressed.connect(func() -> void: _act(func() -> void:
		var out := Profile.fuse_runes(_sel)
		_sel.clear()
		if not out.is_empty():
			Snd.sfx("sw_glass", -3.0)
			Snd.sfx("loot", -4.0)
			_say("Fusion : %s (%s) !" % [Profile.rune_name(out), str(Profile.rarity_of(out).get("name", ""))])))
	srow.add_child(go)
	var hint := UiTheme.label(why if why != "" else "Même famille, même niveau, même rareté : le niveau monte de 1 (jusqu'à V).", 15, UiTheme.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(hint)
	# Fiche de la dernière rune touchée.
	if not _sel.is_empty():
		col.add_child(_rune_card(Profile.find_rune(_sel.back())))
	inv.sort_custom(_rune_order)
	col.add_child(UiTheme.section("Ta besace · %d rune%s" % [inv.size(), "s" if inv.size() > 1 else ""]))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	col.add_child(grid)
	for r in inv:
		var uid := str(r["uid"])
		var rb2 := GearUi.rune_button(r, 100, _sel.has(uid))
		rb2.tooltip_text = Profile.rune_name(r)
		rb2.pressed.connect(func() -> void:
			if _sel.has(uid):
				_sel.erase(uid)
			elif _sel.size() < 3:
				_sel.append(uid)
			_msg = ""
			_rebuild.call_deferred())
		grid.add_child(rb2)


## Fiche d'une rune : ses effets sur chaque type d'objet, et son recyclage.
func _rune_card(r: Dictionary) -> PanelContainer:
	var uid := str(r["uid"])
	var c: Array = UiTheme.card(Color(Profile.rune_color(r), 0.6), 14)
	var v: VBoxContainer = c[1]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiTheme.label("%s · %s" % [Profile.rune_name(r), str(Profile.rune_family(r).get("theme", ""))], 21, Profile.rune_color(r)))
	info.add_child(UiTheme.label(str(Profile.rarity_of(r).get("name", "")), 15, Profile.item_color(r)))
	var sv := UiTheme.button("Recycler · +%d" % Profile.rune_salvage_value(r), 16)
	sv.icon = Icons.tex("dust", 40)
	sv.add_theme_constant_override("icon_max_width", 18)
	sv.add_theme_color_override("icon_normal_color", UiTheme.VIOLET)
	sv.custom_minimum_size = Vector2(0, 46)
	sv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sv.pressed.connect(func() -> void: _act(func() -> void:
		_sel.erase(uid)
		Snd.sfx("sw_spark", -3.0, 0.9)
		_say("Rune recyclée : +%d Poussière d'arcane." % Profile.salvage_rune(uid))))
	h.add_child(sv)
	var cats: Dictionary = Profile.runes_db()["category_names"]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	v.add_child(grid)
	for k in ["arme", "armure", "bijou", "charme"]:
		grid.add_child(UiTheme.label(str(cats[k]), 15, UiTheme.MUTED))
		var e := UiTheme.wrap(Profile.rune_effect_text(r, k), 15, UiTheme.TEXT)
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(e)
	return c[0]


# ---------------------------------------------------------------- outils

## Vignette d'objet : icône dans un cadre à la couleur de la rareté.
static func item_tile(it: Dictionary, px: int = 44) -> PanelContainer:
	var col := Profile.item_color(it)
	var f := PanelContainer.new()
	f.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), Color(col, 0.85), 8, 2, 4))
	f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base := str(it.get("base", ""))
	var r := TextureRect.new()
	r.texture = Icons.item(base, str(Profile.base_of(it).get("slot", "")), px * 2)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.modulate = Color.WHITE if Icons.item_colored(base) else col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.add_child(r)
	return f


## Rangée d'emplacements de runes : rune gravée (icône) ou emplacement vide (losange).
static func sockets_row(it: Dictionary, px: int = 18) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 2)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var runes: Array = it.get("runes", [])
	for i in range(Profile.sockets_of(it)):
		if i < runes.size():
			var r: Dictionary = runes[i]
			var t := TextureRect.new()
			t.texture = ItemArt.rune(str(r["rune"]), int(r["level"]), px * 2)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.custom_minimum_size = Vector2(px, px)
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(t)
		else:
			var e := PanelContainer.new()
			e.custom_minimum_size = Vector2(px, px)
			e.add_theme_stylebox_override("panel", UiTheme.box(Color(0, 0, 0, 0.35), Color(UiTheme.MUTED, 0.55), int(px / 2), 1, 0))
			e.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(e)
	return h


static func _rune_order(a: Dictionary, b: Dictionary) -> bool:
	if str(a["rune"]) != str(b["rune"]):
		var keys: Array = (Profile.runes_db()["families"] as Dictionary).keys()
		return keys.find(str(a["rune"])) < keys.find(str(b["rune"]))
	if int(a["level"]) != int(b["level"]):
		return int(a["level"]) > int(b["level"])
	return float(Profile.rarity_of(a).get("value", 1)) > float(Profile.rarity_of(b).get("value", 1))


## Aperçu des gestes de Durgan (« ?room=forge&fx=fusion » ou « &fx=gravure »), sans rien changer à la sauvegarde.
func demo_scene(kind: String) -> ForgeScene:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var sc: ForgeScene
	if kind == "gravure":
		var it := Profile.make_item("sceptre_solaire", "legendaire", 30, rng)
		var r := Profile.make_rune("pyr", 3, "epique")
		var after := it.duplicate(true)
		after["runes"] = [r]
		sc = ForgeScene.engraving(it, r, after, Profile.rune_effect_text(r, Profile.rune_category("weapon")))
	else:
		var objs: Array = []
		for b in ["epee_ecuyer", "lame_verre", "rapiere_aube"]:
			objs.append(Profile.make_item(str(b), "epique", 30, rng))
		sc = ForgeScene.fusion(objs, Profile.make_item("lame_verre", "legendaire", 31, rng))
	add_child(sc)
	return sc


func _say(text: String, c: Color = UiTheme.GOLD) -> void:
	_msg = text
	_msg_col = c


func _act(f: Callable) -> void:
	f.call()
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
	_rebuild.call_deferred()
