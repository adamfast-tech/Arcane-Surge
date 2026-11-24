class_name EquipmentScreen
extends Control
## Équipement et Forge (concept UI) : puissance et stats, objets équipés avec leur icône,
## emplacements vides (un toucher filtre l'inventaire), inventaire avec Équiper, Améliorer, Recycler.
## Étape 13.4 : le porteur se choisit en haut (toi ou un compagnon recruté).

signal back
signal changed
signal open_forge(uid: String) ## Forge de Durgan : gravure de runes (objet présélectionné) ou fusion

var _col: VBoxContainer
var _filter := "" ## emplacement filtré dans l'inventaire ("" : tout)
var who := "player" ## porteur : « player » ou l'identifiant d'un compagnon
const STAT_ABBR := {"pou": "POU", "vig": "VIG", "esp": "ESP", "cel": "CÉL", "des": "DES"}
var _cmp: Dictionary = {} ## uid → comparaison avec l'équipé (Profile.compare_to_equipped)
var _better_by_slot: Dictionary = {} ## type d'emplacement → nombre d'objets meilleurs en réserve


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.5, 0.0, "forge", "armurerie")
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
	var fg := UiTheme.button("Forge", 18)
	fg.icon = Icons.tex("forge", 40)
	fg.add_theme_constant_override("icon_max_width", 22)
	fg.add_theme_color_override("font_color", UiTheme.FIRE)
	fg.pressed.connect(func() -> void: open_forge.emit(""))
	head.add_child(fg)
	head.add_child(UiTheme.spacer())
	head.add_child(UiTheme.currencies())
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	_col.add_child(tv)
	tv.add_child(UiTheme.title("ÉQUIPEMENT", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title("& RUNES" if who == "player" else "& RUNES · %s" % Dialogues.display_name(who).to_upper(), 22, UiTheme.TEXT))
	var comps := Profile.companions_available()
	if not comps.is_empty():
		_col.add_child(_wearer_tabs(comps))
	_col.add_child(_stats_card())
	var db := Profile.items_db()
	var empty: Array[String] = []
	var equipped: Array = []
	var eqd := Profile.equipment_of(who)
	# Nombre d'objets en réserve meilleurs que l'équipé, par type d'emplacement (anneaux ensemble).
	_better_by_slot.clear()
	for it in Profile.better_items(who):
		var k := _slot_key(str(Profile.base_of(it).get("slot", "")))
		_better_by_slot[k] = int(_better_by_slot.get(k, 0)) + 1
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
	var n_up := 0
	for n in _better_by_slot.values():
		n_up += int(n)
	if n_up > 0:
		inv_head.add_child(_up_label("%d meilleur%s que l'équipé" % [n_up, "s" if n_up > 1 else ""], 16))
	if _filter != "":
		var fb := UiTheme.button("%s  ×" % _slot_name(_filter), 17)
		fb.flat = true
		fb.add_theme_color_override("font_color", UiTheme.TEAL)
		fb.pressed.connect(func() -> void:
			_filter = ""
			_rebuild.call_deferred())
		inv_head.add_child(fb)
	var items: Array = []
	_cmp.clear()
	for it in Profile.data["inventory"]:
		if Profile.holder_of(str(it["uid"])) != "":
			continue
		if _filter != "" and _slot_key(str(Profile.base_of(it).get("slot", ""))) != _slot_key(_filter):
			continue
		items.append(it)
		_cmp[str(it["uid"])] = Profile.compare_to_equipped(who, it)
	# Les objets meilleurs que l'équipement porté d'abord (le plus gros gain en tête), puis le reste.
	items.sort_custom(func(a: Dictionary, c: Dictionary) -> bool:
		var pa := int(_cmp[str(a["uid"])]["power"]) if bool(_cmp[str(a["uid"])]["better"]) else 0
		var pc := int(_cmp[str(c["uid"])]["power"]) if bool(_cmp[str(c["uid"])]["better"]) else 0
		if pa != pc:
			return pa > pc
		return _item_order(a, c))
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
	r.modulate = Color.WHITE if Icons.item_colored(base_id) else col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.add_child(r)
	return f


## Runes gravées : emplacements, effets, et bouton vers la Forge.
func _runes_line(it: Dictionary, v: VBoxContainer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	row.add_child(ForgeScreen.sockets_row(it, 20))
	var cat := Profile.rune_category(str(Profile.base_of(it).get("slot", "")))
	var fx: Array[String] = []
	for r in it.get("runes", []):
		fx.append(Profile.rune_effect_text(r, cat))
	var t := UiTheme.wrap(" · ".join(fx) if not fx.is_empty() else "Aucune rune gravée", 15, UiTheme.TEAL if not fx.is_empty() else UiTheme.MUTED)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	var uid := str(it["uid"])
	var gb := UiTheme.button("Runes", 16)
	gb.custom_minimum_size = Vector2(84, 40)
	gb.add_theme_color_override("font_color", UiTheme.FIRE)
	gb.pressed.connect(func() -> void: open_forge.emit(uid))
	row.add_child(gb)
	return row


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
	_runes_line(it, v)
	var bt := VBoxContainer.new()
	bt.add_theme_constant_override("separation", 6)
	bt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(bt)
	var rm := UiTheme.button("Retirer", 18)
	rm.custom_minimum_size = Vector2(110, 52)
	rm.pressed.connect(func() -> void: _act(func() -> void: Profile.unequip_from(who, slot)))
	bt.add_child(rm)
	var n := int(_better_by_slot.get(_slot_key(slot), 0))
	if n > 0:
		bt.add_child(_better_button(slot, n))
	return c[0]


## « 2 mieux » : n'affiche dans l'inventaire que les objets de cet emplacement (re-toucher : tout).
func _better_button(slot: String, n: int) -> Button:
	var b := UiTheme.button("%d mieux" % n, 16)
	b.icon = Icons.tex("up", 36)
	b.add_theme_constant_override("icon_max_width", 16)
	b.add_theme_color_override("icon_normal_color", UiTheme.GOOD)
	b.custom_minimum_size = Vector2(110, 40)
	b.add_theme_color_override("font_color", UiTheme.GOOD)
	b.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.GOOD, 0.12), Color(UiTheme.GOOD, 0.7), 10, 1, 6))
	b.tooltip_text = "Voir les objets de réserve meilleurs que celui-ci"
	b.pressed.connect(func() -> void:
		_filter = "" if _slot_key(_filter) == _slot_key(slot) else slot
		_rebuild.call_deferred())
	return b


func _empty_slot(slot: String) -> Button:
	var n := int(_better_by_slot.get(_slot_key(slot), 0))
	var b := UiTheme.button(_slot_name(slot) + (" · %d mieux" % n if n > 0 else ""), 17)
	b.flat = _filter != slot
	b.icon = Icons.tex(str(Icons.SLOT_ICON.get(slot, "rune")), 40)
	b.add_theme_constant_override("icon_max_width", 20)
	b.add_theme_color_override("icon_normal_color", Color(UiTheme.MUTED, 0.6))
	b.add_theme_color_override("font_color", UiTheme.GOOD if n > 0 else UiTheme.MUTED)
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
	var cmp: Dictionary = _cmp.get(str(it["uid"]), Profile.compare_to_equipped(who, it))
	var better := bool(cmp["better"])
	var c: Array = UiTheme.card(UiTheme.GOOD if better else Color(col, 0.6), 14)
	var v: VBoxContainer = c[1]
	var base := Profile.base_of(it)
	var rar := Profile.rarity_of(it)
	var slot := str(base.get("slot", ""))
	if better:
		v.add_child(_compare_badge(cmp))
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
	var dl := _diff_line(cmp)
	if dl != null:
		info.add_child(dl)
	if base.has("element") and str(base["element"]) != "physique":
		info.add_child(UiTheme.label("Élément : %s" % str(BattleSim.ELEM_NAMES.get(str(base["element"]), "")), 16, UiTheme.TEAL))
	if bool(it.get("fused", false)):
		info.add_child(UiTheme.label("Issu d'une fusion", 15, UiTheme.FIRE))
	if base.has("lore"):
		v.add_child(UiTheme.wrap(str(base["lore"]), 16, UiTheme.MUTED))
	_runes_line(it, v)
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


## Bandeau vert en tête d'un objet meilleur que l'équipé : gain de Puissance.
func _compare_badge(cmp: Dictionary) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.GOOD, 0.14), Color(UiTheme.GOOD, 0.5), 8, 1, 6))
	var t := "MIEUX QUE L'ÉQUIPÉ" if str(cmp["vs"]) != "" else "EMPLACEMENT LIBRE"
	pc.add_child(_up_label("%s · Puissance +%d" % [t, int(cmp["power"])], 16))
	return pc


## Flèche verte et texte (gain).
func _up_label(text: String, fs: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(UiTheme.icon_rect("up", fs + 2, UiTheme.GOOD))
	h.add_child(UiTheme.label(text, fs, UiTheme.GOOD))
	return h


## Écart avec l'objet porté au même emplacement, stat par stat (vert : gain, rouge : perte).
func _diff_line(cmp: Dictionary) -> RichTextLabel:
	var vs := str(cmp["vs"])
	var diff: Dictionary = cmp["diff"]
	if vs == "" or diff.is_empty():
		return null
	var parts: Array[String] = []
	for k in Profile.STATS:
		if diff.has(k):
			var d := int(diff[k])
			parts.append("[color=#%s]%s%d %s[/color]" % [(UiTheme.GOOD if d > 0 else UiTheme.DANGER).to_html(false), "+" if d > 0 else "−", absi(d), STAT_ABBR[k]])
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_theme_font_size_override("normal_font_size", 15)
	rt.add_theme_color_override("default_color", UiTheme.MUTED)
	rt.text = "vs %s : %s" % [Profile.item_name(Profile.find_item(vs)), " · ".join(parts)]
	return rt


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
