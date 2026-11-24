class_name ForgeScreen
extends Control
## La Forge de Durgan (docs/design/35-equipement-runes-forge.md) :
## - GRAVURE : graver des runes sur un objet ; l'effet dépend de la catégorie (arme, armure, bijou, charme) ;
## - FUSION : 3 objets de même rareté → 1 objet de la rareté au-dessus (3 légendaires → Mythique) ;
##   un objet issu d'une fusion ne peut plus fusionner ;
## - RUNES : la réserve, la fusion de 3 runes identiques (niveau +1) et le recyclage.

signal back

var tab := "gravure"
var focus_item := "" ## objet sélectionné pour la gravure
var back_label := "Havre-Aube"
var _sel: Array[String] = [] ## sélection pour une fusion (objets ou runes)
var _msg := ""
var _msg_col := UiTheme.GOLD


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.6, 0.0, "forge")
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 12)
	var head := HBoxContainer.new()
	col.add_child(head)
	var b := UiTheme.back_button(back_label)
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	head.add_child(UiTheme.currencies())
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("LA FORGE", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title("DURGAN ENCLUME · RUNES ET FUSIONS", 20, UiTheme.TEXT))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	col.add_child(tabs)
	for t in [["gravure", "GRAVURE"], ["fusion", "FUSION"], ["runes", "RUNES · %d" % Profile.rune_inventory().size()]]:
		var id := str(t[0])
		var bt := UiTheme.button(str(t[1]), 18)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.custom_minimum_size = Vector2(0, 52)
		if id == tab:
			bt.add_theme_color_override("font_color", UiTheme.GOLD)
			bt.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), UiTheme.GOLD, 10, 2, 6))
		bt.pressed.connect(func() -> void:
			tab = id
			_sel.clear()
			_msg = ""
			_rebuild.call_deferred())
		tabs.add_child(bt)
	if _msg != "":
		col.add_child(UiTheme.wrap(_msg, 18, _msg_col))
	match tab:
		"fusion":
			_fusion(col)
		"runes":
			_runes(col)
		_:
			_gravure(col)


# ---------------------------------------------------------------- gravure

func _gravure(col: VBoxContainer) -> void:
	var it := Profile.find_item(focus_item)
	if it.is_empty():
		col.add_child(UiTheme.wrap("Choisis l'objet à graver. Une même rune a un effet différent sur une arme, une armure, un bijou ou un charme.", 17, UiTheme.MUTED))
		col.add_child(UiTheme.section("Objets équipés"))
		var reserve: Array = []
		for x in Profile.data["inventory"]:
			if Profile.holder_of(str(x["uid"])) != "":
				col.add_child(_pick_item_row(x))
			else:
				reserve.append(x)
		reserve.sort_custom(EquipmentScreen._item_order)
		col.add_child(UiTheme.section("En réserve · %d" % reserve.size()))
		for x in reserve:
			col.add_child(_pick_item_row(x))
		return
	var cat := Profile.rune_category(str(Profile.base_of(it).get("slot", "")))
	var catn := str(Profile.runes_db()["category_names"].get(cat, cat))
	var c: Array = UiTheme.card(Color(Profile.item_color(it), 0.7), 14)
	col.add_child(c[0])
	var v: VBoxContainer = c[1]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	h.add_child(item_tile(it, 52))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiTheme.label(Profile.item_name(it), 23, Profile.item_color(it)))
	info.add_child(UiTheme.label("%s · catégorie %s · %d emplacement%s" % [str(Profile.rarity_of(it).get("name", "")), catn, Profile.sockets_of(it), "s" if Profile.sockets_of(it) > 1 else ""], 16, UiTheme.MUTED))
	info.add_child(UiTheme.wrap(Profile.stats_text(Profile.item_stats(it)), 17, UiTheme.TEXT))
	var other := UiTheme.button("Changer", 17)
	other.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	other.pressed.connect(func() -> void:
		focus_item = ""
		_rebuild.call_deferred())
	h.add_child(other)
	var runes: Array = it.get("runes", [])
	for i in range(Profile.sockets_of(it)):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		v.add_child(row)
		if i < runes.size():
			var r: Dictionary = runes[i]
			row.add_child(_rune_icon(r, 40))
			var rv := VBoxContainer.new()
			rv.add_theme_constant_override("separation", 0)
			rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(rv)
			rv.add_child(UiTheme.label("%s · %s" % [Profile.rune_name(r), str(Profile.rarity_of(r).get("name", ""))], 19, Profile.rune_color(r)))
			rv.add_child(UiTheme.wrap(Profile.rune_effect_text(r, cat), 16, UiTheme.TEXT))
			var idx := i
			var rm := UiTheme.button("Retirer · %d or" % Profile.unengrave_cost(r), 16)
			rm.custom_minimum_size = Vector2(0, 46)
			rm.disabled = Profile.gold() < Profile.unengrave_cost(r)
			rm.pressed.connect(func() -> void: _act(func() -> void:
				Profile.unengrave(focus_item, idx)
				_say("Rune retirée : elle retourne dans ta réserve.")))
			row.add_child(rm)
		else:
			var empty := PanelContainer.new()
			empty.custom_minimum_size = Vector2(40, 40)
			empty.add_theme_stylebox_override("panel", UiTheme.box(Color(0, 0, 0, 0.3), Color(UiTheme.MUTED, 0.5), 20, 1, 4))
			row.add_child(empty)
			row.add_child(UiTheme.label("Emplacement libre", 17, UiTheme.MUTED))
	if bool(it.get("fused", false)):
		v.add_child(UiTheme.label("Issu d'une fusion", 15, UiTheme.FIRE))
	var inv := Profile.rune_inventory()
	col.add_child(UiTheme.section("Tes runes · effet sur %s" % catn.to_lower()))
	if inv.is_empty():
		col.add_child(UiTheme.wrap("Aucune rune en réserve. Chaque étoile gagnée donne une chance d'en obtenir une, et chaque boss en garantit une.", 17, UiTheme.MUTED))
		return
	var list := inv.duplicate()
	list.sort_custom(_rune_order)
	for r in list:
		col.add_child(_engrave_row(it, r, cat))


func _pick_item_row(it: Dictionary) -> Button:
	var parts: Array = UiTheme.rich_button(76, "row")
	var b: Button = parts[0]
	var h: HBoxContainer = parts[1]
	h.add_theme_constant_override("separation", 12)
	h.add_child(item_tile(it, 44))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var nm := UiTheme.label(Profile.item_name(it), 20, Profile.item_color(it))
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var holder := Profile.holder_of(str(it["uid"]))
	var who := "" if holder == "" else (" · porté par %s" % ("toi" if holder == "player" else Dialogues.display_name(holder)))
	var sub := UiTheme.label("%d / %d rune%s%s" % [(it.get("runes", []) as Array).size(), Profile.sockets_of(it), "s" if Profile.sockets_of(it) > 1 else "", who], 15, UiTheme.MUTED)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sub)
	h.add_child(sockets_row(it, 18))
	var uid := str(it["uid"])
	b.pressed.connect(func() -> void:
		focus_item = uid
		_msg = ""
		_rebuild.call_deferred())
	return b


func _engrave_row(it: Dictionary, r: Dictionary, cat: String) -> PanelContainer:
	var c: Array = UiTheme.card(Color(Profile.rune_color(r), 0.45), 10)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	(c[1] as VBoxContainer).add_child(h)
	h.add_child(_rune_icon(r, 40))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiTheme.label("%s · %s · %s" % [Profile.rune_name(r), str(Profile.rune_family(r).get("theme", "")), str(Profile.rarity_of(r).get("name", ""))], 18, Profile.item_color(r)))
	v.add_child(UiTheme.wrap(Profile.rune_effect_text(r, cat), 16, UiTheme.TEXT))
	var why := Profile.engrave_block(it, r)
	var g := UiTheme.button("Graver · %d or" % Profile.engrave_cost(r), 16)
	g.custom_minimum_size = Vector2(0, 46)
	g.disabled = why != ""
	g.tooltip_text = why
	var ruid := str(r["uid"])
	g.pressed.connect(func() -> void: _act(func() -> void:
		var rr := Profile.find_rune(ruid)
		var name := Profile.rune_name(rr)
		if Profile.engrave(focus_item, ruid):
			_say("%s gravée : %s." % [name, Profile.rune_effect_text(rr, cat)])))
	h.add_child(g)
	return c[0]


# ---------------------------------------------------------------- fusion d'équipement

func _fusion(col: VBoxContainer) -> void:
	col.add_child(UiTheme.wrap("Fusionne 3 objets de même rareté pour obtenir un objet de la rareté au-dessus. Le premier choisi donne son modèle, et le niveau d'objet est le plus haut des trois. Trois légendaires donnent un objet MYTHIQUE. Un objet issu d'une fusion ne peut plus fusionner. Les runes gravées reviennent dans ta réserve.", 17, UiTheme.MUTED))
	var chosen: Array = []
	for u in _sel:
		var x := Profile.find_item(u)
		if not x.is_empty():
			chosen.append(x)
	var c: Array = UiTheme.card(UiTheme.FIRE, 14)
	col.add_child(c[0])
	var v: VBoxContainer = c[1]
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 10)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(slots)
	for i in range(3):
		if i < chosen.size():
			slots.add_child(item_tile(chosen[i], 56))
		else:
			var e := PanelContainer.new()
			e.custom_minimum_size = Vector2(64, 64)
			e.add_theme_stylebox_override("panel", UiTheme.box(Color(0, 0, 0, 0.3), Color(UiTheme.MUTED, 0.5), 8, 1, 4))
			slots.add_child(e)
	slots.add_child(UiTheme.icon_rect("chevron", 26, UiTheme.GOLD))
	var next := Profile.fusion_next(str((chosen[0] as Dictionary).get("rarity", ""))) if not chosen.is_empty() else ""
	var res := PanelContainer.new()
	res.custom_minimum_size = Vector2(64, 64)
	var ncol := Color(str((Profile.items_db()["rarities"] as Dictionary).get(next, {}).get("color", "5e5e6a")))
	res.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), ncol, 8, 2, 4))
	if not chosen.is_empty():
		var ic := TextureRect.new()
		ic.texture = Icons.item(str((chosen[0] as Dictionary)["base"]), "", 112)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(56, 56)
		res.add_child(ic)
	slots.add_child(res)
	if chosen.is_empty():
		v.add_child(UiTheme.label("Touche 3 objets ci-dessous.", 18, UiTheme.MUTED))
	else:
		var first: Dictionary = chosen[0]
		var ilvl := 1
		for x in chosen:
			ilvl = maxi(ilvl, int((x as Dictionary).get("ilvl", 1)))
		var nr: Dictionary = (Profile.items_db()["rarities"] as Dictionary).get(next, {})
		v.add_child(UiTheme.label("→ %s · %s · iLvl %d · %d emplacement%s de runes" % [str(Profile.base_of(first).get("name", "")), str(nr.get("name", "")), ilvl, int(nr.get("sockets", 1)), "s" if int(nr.get("sockets", 1)) > 1 else ""], 18, ncol))
	var why := Profile.fusion_block(_sel)
	var go := UiTheme.button("FUSIONNER · %d or" % Profile.fusion_cost(chosen) if not chosen.is_empty() else "FUSIONNER", 20)
	go.custom_minimum_size = Vector2(0, 58)
	go.disabled = why != ""
	go.add_theme_color_override("font_color", UiTheme.GOLD)
	go.pressed.connect(func() -> void: _act(func() -> void:
		var out := Profile.fuse_items(_sel)
		_sel.clear()
		if not out.is_empty():
			_say("Fusion réussie : %s (%s) !" % [Profile.item_name(out), str(Profile.rarity_of(out).get("name", ""))])))
	v.add_child(go)
	if why != "" and not chosen.is_empty():
		v.add_child(UiTheme.label(why, 16, UiTheme.MUTED))
	col.add_child(UiTheme.section("Objets en réserve"))
	var list: Array = []
	for x in Profile.data["inventory"]:
		if Profile.holder_of(str(x["uid"])) == "":
			list.append(x)
	list.sort_custom(EquipmentScreen._item_order)
	if list.is_empty():
		col.add_child(UiTheme.wrap("Rien en réserve : les objets équipés ne fusionnent pas.", 17, UiTheme.MUTED))
	for x in list:
		col.add_child(_fusion_row(x, chosen))


func _fusion_row(it: Dictionary, chosen: Array) -> Button:
	var parts: Array = UiTheme.rich_button(72, "row")
	var b: Button = parts[0]
	var h: HBoxContainer = parts[1]
	h.add_theme_constant_override("separation", 12)
	h.add_child(item_tile(it, 42))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var uid := str(it["uid"])
	var picked := _sel.has(uid)
	var why := Profile.fusion_item_block(it)
	if why == "" and not chosen.is_empty() and not picked and str((chosen[0] as Dictionary)["rarity"]) != str(it["rarity"]):
		why = "Autre rareté que la sélection"
	var nm := UiTheme.label(Profile.item_name(it), 19, Profile.item_color(it) if why == "" or picked else Color(UiTheme.MUTED, 0.7))
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var sub := UiTheme.label("%s · iLvl %d%s" % [str(Profile.rarity_of(it).get("name", "")), int(it["ilvl"]), (" · " + why) if why != "" and not picked else ""], 15, UiTheme.MUTED)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sub)
	if picked:
		h.add_child(UiTheme.icon_rect("check", 26, UiTheme.GOLD))
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
	col.add_child(UiTheme.wrap("Fusionne 3 runes identiques (même famille, même niveau, même rareté) pour obtenir le niveau au-dessus, jusqu'au niveau V. Une rune recyclée donne de la Poussière d'arcane.", 17, UiTheme.MUTED))
	if _sel.size() > 0:
		var why := Profile.rune_fuse_block(_sel)
		var first := Profile.find_rune(_sel[0])
		var go := UiTheme.button("FUSIONNER %d/3 · %d or" % [_sel.size(), Profile.rune_fuse_cost(first)], 20)
		go.custom_minimum_size = Vector2(0, 56)
		go.disabled = why != ""
		go.add_theme_color_override("font_color", UiTheme.GOLD)
		go.pressed.connect(func() -> void: _act(func() -> void:
			var out := Profile.fuse_runes(_sel)
			_sel.clear()
			if not out.is_empty():
				_say("Fusion : %s (%s) !" % [Profile.rune_name(out), str(Profile.rarity_of(out).get("name", ""))])))
		col.add_child(go)
		if why != "" and _sel.size() == 3:
			col.add_child(UiTheme.label(why, 16, UiTheme.MUTED))
	var inv := Profile.rune_inventory().duplicate()
	if inv.is_empty():
		col.add_child(UiTheme.wrap("Aucune rune en réserve. Chaque étoile gagnée donne une chance d'en obtenir une, et chaque boss en garantit une.", 17, UiTheme.MUTED))
		return
	inv.sort_custom(_rune_order)
	for r in inv:
		col.add_child(_rune_card(r))


func _rune_card(r: Dictionary) -> PanelContainer:
	var uid := str(r["uid"])
	var picked := _sel.has(uid)
	var c: Array = UiTheme.card(UiTheme.GOLD if picked else Color(Profile.rune_color(r), 0.45), 10)
	var v: VBoxContainer = c[1]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(_rune_icon(r, 44))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiTheme.label("%s · %s" % [Profile.rune_name(r), str(Profile.rune_family(r).get("theme", ""))], 20, Profile.rune_color(r)))
	info.add_child(UiTheme.label(str(Profile.rarity_of(r).get("name", "")), 15, Profile.item_color(r)))
	var sel := UiTheme.button("Retirer" if picked else "Choisir", 16)
	sel.custom_minimum_size = Vector2(96, 44)
	sel.pressed.connect(func() -> void:
		if _sel.has(uid):
			_sel.erase(uid)
		elif _sel.size() < 3:
			_sel.append(uid)
		_msg = ""
		_rebuild.call_deferred())
	h.add_child(sel)
	var sv := UiTheme.button("Recycler · +%d" % Profile.rune_salvage_value(r), 16)
	sv.custom_minimum_size = Vector2(0, 44)
	sv.pressed.connect(func() -> void: _act(func() -> void:
		_sel.erase(uid)
		_say("Rune recyclée : +%d Poussière d'arcane." % Profile.salvage_rune(uid))))
	h.add_child(sv)
	var cats: Dictionary = Profile.runes_db()["category_names"]
	for k in ["arme", "armure", "bijou", "charme"]:
		v.add_child(UiTheme.label("%s : %s" % [str(cats[k]), Profile.rune_effect_text(r, k)], 15, UiTheme.MUTED))
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


func _rune_icon(r: Dictionary, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = ItemArt.rune(str(r["rune"]), int(r["level"]), px * 2)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.custom_minimum_size = Vector2(px, px)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func _rune_order(a: Dictionary, b: Dictionary) -> bool:
	if str(a["rune"]) != str(b["rune"]):
		var keys: Array = (Profile.runes_db()["families"] as Dictionary).keys()
		return keys.find(str(a["rune"])) < keys.find(str(b["rune"]))
	if int(a["level"]) != int(b["level"]):
		return int(a["level"]) > int(b["level"])
	return float(Profile.rarity_of(a).get("value", 1)) > float(Profile.rarity_of(b).get("value", 1))


func _say(text: String, c: Color = UiTheme.GOLD) -> void:
	_msg = text
	_msg_col = c


func _act(f: Callable) -> void:
	f.call()
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
	_rebuild.call_deferred()
