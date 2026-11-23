class_name EquipmentScreen
extends Control
## Équipement et Forge (concept UI) : puissance et stats, objets équipés avec leur icône,
## emplacements vides (un toucher filtre l'inventaire), inventaire avec Équiper, Améliorer, Recycler.
## Étape 13.4 : le porteur se choisit en haut (toi ou un compagnon recruté).

signal back
signal changed

var _col: VBoxContainer
var _filter := "" ## emplacement filtré dans l'inventaire ("" : tout)
var who := "player" ## porteur : « player » ou l'identifiant d'un compagnon


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.6, 0.0, "forge")
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	_col = UiTheme.scroll_column(self, 680.0, 16.0)
	_col.add_theme_constant_override("separation", 14)
	var head := HBoxContainer.new()
	_col.add_child(head)
	var b := UiTheme.back_button("Havre-Aube")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	head.add_child(UiTheme.currencies())
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	_col.add_child(tv)
	tv.add_child(UiTheme.title("ÉQUIPEMENT", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title("& FORGE" if who == "player" else "& FORGE · %s" % Dialogues.display_name(who).to_upper(), 22, UiTheme.TEXT))
	var comps := Profile.companions_available()
	if not comps.is_empty():
		_col.add_child(_wearer_tabs(comps))
	_col.add_child(_stats_card())
	var db := Profile.items_db()
	var empty: Array[String] = []
	var equipped: Array = []
	var eqd := Profile.equipment_of(who)
	for slot in db["slot_order"]:
		var uid := str(eqd.get(slot, ""))
		var it := Profile.find_item(uid) if uid != "" else {}
		if it.is_empty():
			empty.append(str(slot))
		else:
			equipped.append([str(slot), it])
	_col.add_child(UiTheme.section("Équipé · %d objet%s" % [equipped.size(), "s" if equipped.size() > 1 else ""]))
	for e in equipped:
		_col.add_child(_equipped_row(str(e[0]), e[1]))
	if not empty.is_empty():
		_col.add_child(UiTheme.section("Emplacements vides · %d" % empty.size()))
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		_col.add_child(grid)
		for slot in empty:
			grid.add_child(_empty_slot(slot))
	var inv_head := HBoxContainer.new()
	_col.add_child(inv_head)
	var st := UiTheme.section("Inventaire et Forge")
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_head.add_child(st)
	if _filter != "":
		var fb := UiTheme.button("%s  ×" % _slot_name(_filter), 17)
		fb.flat = true
		fb.add_theme_color_override("font_color", UiTheme.TEAL)
		fb.pressed.connect(func() -> void:
			_filter = ""
			_rebuild.call_deferred())
		inv_head.add_child(fb)
	var items: Array = []
	for it in Profile.data["inventory"]:
		if Profile.holder_of(str(it["uid"])) != "":
			continue
		if _filter != "" and _slot_key(str(Profile.base_of(it).get("slot", ""))) != _slot_key(_filter):
			continue
		items.append(it)
	items.sort_custom(_item_order)
	if items.is_empty():
		_col.add_child(_empty_inventory())
	for it in items:
		_col.add_child(_item_card(it))


## Porteur de l'équipement : toi ou un compagnon.
func _wearer_tabs(comps: Array[String]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var list: Array[String] = ["player"]
	list.append_array(comps)
	for w in list:
		var on := w == who
		var tc := UiTheme.TEAL if w == "player" else Dialogues.color(w)
		var bt := UiTheme.button("Toi" if w == "player" else Dialogues.display_name(w), 18)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.custom_minimum_size = Vector2(0, 52)
		if on:
			bt.add_theme_color_override("font_color", tc)
			bt.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), tc, 10, 2, 6))
		var target := w
		bt.pressed.connect(func() -> void:
			who = target
			_filter = ""
			_rebuild.call_deferred())
		row.add_child(bt)
	return row


func _stats_card() -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 16)
	var v: VBoxContainer = c[1]
	var row := HBoxContainer.new()
	v.add_child(row)
	var p := UiTheme.label("Puissance %d" % (Profile.power() if who == "player" else Profile.companion_power(who)), 26, UiTheme.GOLD)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(p)
	var el := Profile.weapon_element_of(who)
	var ecol := Color(str(SpriteAtlas.ELEM[el][2])) if SpriteAtlas.ELEM.has(el) else UiTheme.MUTED
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)
	info.add_child(UiTheme.label("Niveau %d · " % (Profile.level() if who == "player" else Profile.companion_level(who)), 19, UiTheme.MUTED))
	info.add_child(UiTheme.label(str(BattleSim.ELEM_NAMES.get(el, "Physique")), 19, ecol))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	v.add_child(grid)
	var st := Profile.stats() if who == "player" else Profile.companion_stats(who)
	var names: Dictionary = Profile.items_db()["stat_names"]
	for k in Profile.STATS:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 0)
		var a := UiTheme.label(str(names[k]).substr(0, 3).to_upper(), 17, UiTheme.MUTED)
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(a)
		var n := UiTheme.label("%d" % int(round(float(st[k]))), 30)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(n)
		grid.add_child(cell)
	return c[0]


## Vignette d'objet : icône au trait dans un cadre à la couleur de la rareté.
func _icon_tile(base_id: String, slot: String, col: Color, px: int = 44) -> PanelContainer:
	var f := PanelContainer.new()
	f.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), Color(col, 0.75), 8, 2, 8))
	f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := TextureRect.new()
	r.texture = Icons.item(base_id, slot, px * 2)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.modulate = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.add_child(r)
	return f


func _equipped_row(slot: String, it: Dictionary) -> PanelContainer:
	var col := Profile.item_color(it)
	var c: Array = UiTheme.card(UiTheme.BORDER, 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	(c[1] as VBoxContainer).add_child(h)
	h.add_child(_icon_tile(str(it.get("base", "")), slot, col))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiTheme.label(_slot_name(slot), 16, UiTheme.MUTED))
	v.add_child(UiTheme.label(Profile.item_name(it), 23, col))
	v.add_child(UiTheme.wrap(Profile.stats_text(Profile.item_stats(it)), 17, UiTheme.MUTED))
	var rm := UiTheme.button("Retirer", 18)
	rm.custom_minimum_size = Vector2(110, 52)
	rm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rm.pressed.connect(func() -> void: _act(func() -> void: Profile.unequip_from(who, slot)))
	h.add_child(rm)
	return c[0]


func _empty_slot(slot: String) -> Button:
	var b := UiTheme.button(_slot_name(slot), 17)
	b.flat = _filter != slot
	b.icon = Icons.tex(str(Icons.SLOT_ICON.get(slot, "rune")), 40)
	b.add_theme_constant_override("icon_max_width", 20)
	b.add_theme_color_override("icon_normal_color", Color(UiTheme.MUTED, 0.6))
	b.add_theme_color_override("font_color", UiTheme.MUTED)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 46)
	b.pressed.connect(func() -> void:
		_filter = "" if _filter == slot else slot
		_rebuild.call_deferred())
	return b


func _empty_inventory() -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 16)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	(c[1] as VBoxContainer).add_child(h)
	h.add_child(UiTheme.icon_rect("rune", 30, UiTheme.MUTED))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiTheme.label("Aucun objet en réserve" if _filter == "" else "Aucun objet de ce type", 22))
	v.add_child(UiTheme.wrap("Les coffres de fin de partie en contiennent : 1 coffre par étoile obtenue.", 17, UiTheme.MUTED))
	return c[0]


func _item_card(it: Dictionary) -> PanelContainer:
	var col := Profile.item_color(it)
	var c: Array = UiTheme.card(Color(col, 0.6), 14)
	var v: VBoxContainer = c[1]
	var base := Profile.base_of(it)
	var rar := Profile.rarity_of(it)
	var slot := str(base.get("slot", ""))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	h.add_child(_icon_tile(str(it.get("base", "")), slot, col))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiTheme.label(Profile.item_name(it), 23, col))
	info.add_child(UiTheme.label("%s · %s · iLvl %d" % [str(rar.get("name", "")), _slot_name(slot), int(it["ilvl"])], 16, UiTheme.MUTED))
	info.add_child(UiTheme.wrap(Profile.stats_text(Profile.item_stats(it)), 18, UiTheme.TEXT))
	if base.has("element") and str(base["element"]) != "physique":
		info.add_child(UiTheme.label("Élément : %s" % str(BattleSim.ELEM_NAMES.get(str(base["element"]), "")), 16, UiTheme.TEAL))
	if base.has("lore"):
		v.add_child(UiTheme.wrap(str(base["lore"]), 16, UiTheme.MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var uid := str(it["uid"])
	var eq := UiTheme.button("Équiper" if who == "player" else "Équiper sur %s" % Dialogues.display_name(who), 19)
	eq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq.custom_minimum_size = Vector2(0, 52)
	eq.add_theme_color_override("font_color", UiTheme.GOLD)
	eq.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.8), 12, 2, 8))
	eq.pressed.connect(func() -> void: _act(func() -> void: Profile.equip_to(who, uid)))
	row.add_child(eq)
	var max_up := int(rar.get("max_up", 5))
	var up := UiTheme.button("Améliorer · %d or" % Profile.upgrade_cost(it) if int(it.get("up", 0)) < max_up else "Niveau max", 18)
	up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up.custom_minimum_size = Vector2(0, 52)
	up.disabled = not Profile.can_upgrade(it)
	up.pressed.connect(func() -> void: _act(func() -> void: Profile.upgrade(uid)))
	row.add_child(up)
	var sv := UiTheme.button("Recycler · +%d" % Profile.salvage_value(it), 18)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.custom_minimum_size = Vector2(0, 52)
	sv.pressed.connect(func() -> void: _act(func() -> void: Profile.salvage(uid)))
	row.add_child(sv)
	return c[0]


func _slot_name(slot: String) -> String:
	var db := Profile.items_db()
	return str(db["slots"].get(slot, db["slots"].get(slot + "1", "Anneau")))


## « ring1 », « ring2 » et « ring » désignent le même type d'emplacement.
static func _slot_key(slot: String) -> String:
	return "ring" if slot.begins_with("ring") else slot


func _act(f: Callable) -> void:
	f.call()
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
	changed.emit()
	_rebuild.call_deferred()


static func _item_order(a: Dictionary, c: Dictionary) -> bool:
	var ka := float(Profile.rarity_of(a).get("value", 1)) * 100.0 + float(a["ilvl"])
	var kc := float(Profile.rarity_of(c).get("value", 1)) * 100.0 + float(c["ilvl"])
	return ka > kc
