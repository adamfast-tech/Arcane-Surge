class_name EquipmentScreen
extends Control
## Équipement et Forge : stats, objets équipés, inventaire, amélioration et recyclage.

signal back
signal changed

var _col: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.78)
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	_col = UiTheme.scroll_column(self, 680.0, 20.0)
	var head := HBoxContainer.new()
	_col.add_child(head)
	var b := UiTheme.button("‹ Havre-Aube", 22)
	b.custom_minimum_size = Vector2(0, 56)
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	head.add_child(UiTheme.label("%d or · %d poussière" % [Profile.gold(), Profile.dust()], 22, UiTheme.GOLD))
	var title := UiTheme.title("ÉQUIPEMENT & FORGE", 40, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(title)
	_col.add_child(_stats_card())
	_col.add_child(UiTheme.label("ÉQUIPÉ", 24, UiTheme.CYAN))
	var db := Profile.items_db()
	var eq_card: Array = UiTheme.card()
	_col.add_child(eq_card[0])
	for slot in db["slot_order"]:
		var uid := str(Profile.data["equipped"].get(slot, ""))
		var it := Profile.find_item(uid) if uid != "" else {}
		var row := HBoxContainer.new()
		(eq_card[1] as VBoxContainer).add_child(row)
		var sl := UiTheme.label(str(db["slots"][slot]), 19, UiTheme.MUTED)
		sl.custom_minimum_size = Vector2(150, 0)
		row.add_child(sl)
		if it.is_empty():
			var e := UiTheme.label("—", 19, Color(UiTheme.MUTED, 0.6))
			e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(e)
			continue
		var n := UiTheme.wrap("%s  %s" % [Profile.item_name(it), Profile.stats_text(Profile.item_stats(it))], 19, Profile.item_color(it))
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(n)
		var rm := UiTheme.button("Retirer", 17)
		rm.custom_minimum_size = Vector2(96, 44)
		var s := str(slot)
		rm.pressed.connect(func() -> void: _act(func() -> void: Profile.unequip(s)))
		row.add_child(rm)
	_col.add_child(UiTheme.label("INVENTAIRE ET FORGE", 24, UiTheme.CYAN))
	var items: Array = []
	for it in Profile.data["inventory"]:
		if Profile.equipped_slot(str(it["uid"])) == "":
			items.append(it)
	items.sort_custom(_item_order)
	if items.is_empty():
		_col.add_child(UiTheme.wrap("Aucun objet en réserve. Les coffres de fin de partie (1 par étoile) en contiennent.", 19))
	for it in items:
		_col.add_child(_item_card(it))


func _stats_card() -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 14)
	var v: VBoxContainer = c[1]
	var st := Profile.stats()
	var names: Dictionary = Profile.items_db()["stat_names"]
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	v.add_child(grid)
	for k in Profile.STATS:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 0)
		var a := UiTheme.label(str(names[k]).substr(0, 3).to_upper(), 17, UiTheme.MUTED)
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(a)
		var b := UiTheme.label("%d" % int(round(float(st[k]))), 26)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(b)
		grid.add_child(cell)
	var el := str(SpriteAtlas.ELEM.get(Profile.weapon_element(), [])[2] if SpriteAtlas.ELEM.has(Profile.weapon_element()) else "ffffff")
	var row := HBoxContainer.new()
	v.add_child(row)
	var p := UiTheme.label("Puissance %d · niveau %d" % [Profile.power(), Profile.level()], 22, UiTheme.GOLD)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(p)
	row.add_child(UiTheme.label("Élément des familiers : %s" % str(BattleSim.ELEM_NAMES.get(Profile.weapon_element(), "Physique")), 19, Color(el)))
	return c[0]


func _item_card(it: Dictionary) -> PanelContainer:
	var col := Profile.item_color(it)
	var c: Array = UiTheme.card(col, 12)
	var v: VBoxContainer = c[1]
	var base := Profile.base_of(it)
	var rar := Profile.rarity_of(it)
	var head := HBoxContainer.new()
	v.add_child(head)
	var n := UiTheme.label(Profile.item_name(it), 24, col)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(n)
	head.add_child(UiTheme.label("%s · %s · iLvl %d" % [str(rar.get("letter", "?")), str(Profile.items_db()["slots"].get(str(base.get("slot", "")), "Anneau")), int(it["ilvl"])], 18, UiTheme.MUTED))
	v.add_child(UiTheme.label(Profile.stats_text(Profile.item_stats(it)), 19, UiTheme.TEXT))
	if base.has("element") and str(base["element"]) != "physique":
		v.add_child(UiTheme.label("Élément natif : %s" % str(BattleSim.ELEM_NAMES.get(str(base["element"]), "")), 18, UiTheme.CYAN))
	if base.has("lore"):
		v.add_child(UiTheme.wrap(str(base["lore"]), 17, UiTheme.MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var uid := str(it["uid"])
	var eq := UiTheme.button("Équiper", 19)
	eq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq.custom_minimum_size = Vector2(0, 50)
	eq.add_theme_color_override("font_color", UiTheme.GOLD)
	eq.pressed.connect(func() -> void: _act(func() -> void: Profile.equip(uid)))
	row.add_child(eq)
	var max_up := int(rar.get("max_up", 5))
	var up := UiTheme.button("Améliorer · %d or" % Profile.upgrade_cost(it) if int(it.get("up", 0)) < max_up else "Niveau max", 19)
	up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up.custom_minimum_size = Vector2(0, 50)
	up.disabled = not Profile.can_upgrade(it)
	up.pressed.connect(func() -> void: _act(func() -> void: Profile.upgrade(uid)))
	row.add_child(up)
	var sv := UiTheme.button("Recycler · +%d" % Profile.salvage_value(it), 19)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.custom_minimum_size = Vector2(0, 50)
	sv.pressed.connect(func() -> void: _act(func() -> void: Profile.salvage(uid)))
	row.add_child(sv)
	return c[0]


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
