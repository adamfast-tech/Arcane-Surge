class_name EquipmentScreen
extends Control
## Équipement (docs/design/35-equipement-runes-forge.md) : l'armurerie d'un héros ou d'un compagnon.
## - le porteur se choisit en haut (son sprite, son nom) ;
## - le mannequin : le personnage au centre sur son socle, ses 10 emplacements autour (cadre à la couleur de la
##   rareté, niveau d'amélioration, runes, flèche verte s'il y a mieux en réserve), sa Puissance et ses stats ;
## - la fiche de l'emplacement ou de l'objet touché : stats, runes, comparaison avec l'objet porté, et les
##   actions (Améliorer sans retirer, Runes, Retirer ; ou Équiper, Améliorer, Recycler) ;
## - la réserve en grille, filtrable par emplacement, le meilleur d'abord.

signal back
signal changed
signal open_forge(uid: String) ## Forge de Durgan : gravure de runes (objet présélectionné) ou fusion

const LEFT := ["weapon", "head", "armor", "hands", "feet"]
const RIGHT := ["offhand", "amulet", "ring1", "ring2", "charm"]
const FILTERS := ["weapon", "offhand", "head", "armor", "hands", "feet", "amulet", "ring", "charm"]
const STAT_ABBR := GearUi.STAT_ABBR

var _col: VBoxContainer
var _filter := "" ## type d'emplacement filtré dans la réserve ("" : tout)
var who := "player" ## porteur : « player » ou l'identifiant d'un compagnon
var _sel := "" ## « slot:<emplacement> » ou « item:<uid> » : la fiche affichée
var _cmp: Dictionary = {} ## uid → comparaison avec l'équipé (Profile.compare_to_equipped)
var _better_by_slot: Dictionary = {} ## type d'emplacement → nombre d'objets meilleurs en réserve


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.55, 0.0, "forge", "armurerie")
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	_col = UiTheme.scroll_column(self, 680.0, 16.0)
	_col.add_theme_constant_override("separation", 14)
	var eqd := Profile.equipment_of(who)
	_better_by_slot.clear()
	for it in Profile.better_items(who):
		var k := _slot_key(str(Profile.base_of(it).get("slot", "")))
		_better_by_slot[k] = int(_better_by_slot.get(k, 0)) + 1
	_cmp.clear()
	for it in Profile.data["inventory"]:
		if Profile.holder_of(str(it["uid"])) == "":
			_cmp[str(it["uid"])] = Profile.compare_to_equipped(who, it)
	if _sel == "" or (_sel.begins_with("item:") and Profile.find_item(_sel.substr(5)).is_empty()):
		# Par défaut : l'arme (ou le premier objet porté).
		_sel = "slot:weapon"
		for sl in LEFT + RIGHT:
			if eqd.has(sl):
				_sel = "slot:" + sl
				break
	_header()
	var comps := Profile.companions_available()
	if not comps.is_empty():
		_col.add_child(_wearer_tabs(comps))
	_col.add_child(_doll(eqd))
	_col.add_child(_stats_card())
	_col.add_child(_detail())
	_inventory()


# ---------------------------------------------------------------- en-tête

func _header() -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	_col.add_child(head)
	var b := UiTheme.back_button("Havre-Aube")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	var fg := UiTheme.button("Forge", 18)
	fg.icon = Icons.tex("forge", 40)
	fg.custom_minimum_size = Vector2(0, 56)
	fg.add_theme_constant_override("icon_max_width", 22)
	fg.add_theme_color_override("font_color", UiTheme.FIRE)
	fg.add_theme_color_override("icon_normal_color", UiTheme.FIRE)
	fg.pressed.connect(func() -> void: open_forge.emit(""))
	head.add_child(fg)
	head.add_child(UiTheme.spacer())
	head.add_child(GearUi.purse())
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	_col.add_child(tv)
	tv.add_child(UiTheme.title("ARMURERIE", 46, UiTheme.GOLD))
	var sub := "ÉQUIPEMENT ET RUNES" if who == "player" else "ÉQUIPEMENT DE %s" % Dialogues.display_name(who).to_upper()
	tv.add_child(UiTheme.title(sub, 20, UiTheme.TEXT))


## Porteur de l'équipement : toi ou un compagnon (son sprite, son nom).
func _wearer_tabs(comps: Array[String]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var list: Array[String] = ["player"]
	list.append_array(comps)
	for w in list:
		var on := w == who
		var tc := UiTheme.TEAL if w == "player" else Dialogues.color(w)
		var parts: Array = UiTheme.rich_button(64, "primary" if on else "tile")
		var bt: Button = parts[0]
		var h: HBoxContainer = parts[1]
		h.add_theme_constant_override("separation", 6)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		if w == "player":
			SpriteAtlas.set_player(Profile.look(), Profile.race(), Profile.player_class())
		h.add_child(GearUi.figure(w, 40))
		var nl := UiTheme.label("Toi" if w == "player" else Dialogues.display_name(w), 18, tc if on else UiTheme.TEXT)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(nl)
		var target := w
		bt.pressed.connect(func() -> void:
			Snd.click()
			who = target
			_filter = ""
			_sel = ""
			_rebuild.call_deferred())
		row.add_child(bt)
	return row


# ---------------------------------------------------------------- mannequin

func _doll(eqd: Dictionary) -> PanelContainer:
	var c: Array = UiTheme.card(Color(UiTheme.GOLD, 0.35), 14)
	var v: VBoxContainer = c[1]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(_slot_column(LEFT, eqd))
	# Le personnage, sur son socle, et sa Puissance.
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 0)
	h.add_child(mid)
	var el := Profile.weapon_element_of(who)
	var ecol := Color(str(SpriteAtlas.ELEM[el][2])) if SpriteAtlas.ELEM.has(el) else UiTheme.TEAL
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 300)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(stage)
	var ped := GearUi.pedestal(ecol, 230, 70)
	ped.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ped.position = Vector2(-115, -96)
	ped.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	ped.offset_left = -115
	ped.offset_right = 115
	ped.offset_top = -100
	ped.offset_bottom = -30
	stage.add_child(ped)
	if who == "player":
		# Le héros en volume : on le fait tourner en le glissant vers la gauche ou la droite.
		var tt := HeroTurntable.new()
		tt.setup(Profile.look(), Profile.race(), Profile.player_class())
		tt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		var hw := float(HeroModel.W * HeroTurntable.SCALE) * 0.5
		tt.offset_left = -hw
		tt.offset_right = hw
		tt.offset_top = -40.0 - float(HeroModel.H * HeroTurntable.SCALE)
		tt.offset_bottom = -40.0
		stage.add_child(tt)
		var hint := HBoxContainer.new()
		hint.alignment = BoxContainer.ALIGNMENT_CENTER
		hint.add_theme_constant_override("separation", 6)
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		hint.offset_left = -120
		hint.offset_right = 120
		hint.offset_top = -26
		hint.offset_bottom = -4
		hint.add_child(UiTheme.icon_rect("back", 14, Color(UiTheme.MUTED, 0.8)))
		hint.add_child(UiTheme.label("Glisse pour le faire tourner", 13, Color(UiTheme.MUTED, 0.8)))
		hint.add_child(UiTheme.icon_rect("chevron", 14, Color(UiTheme.MUTED, 0.8)))
		stage.add_child(hint)
	else:
		var fig := GearUi.figure(who, 230)
		fig.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		fig.offset_left = -95
		fig.offset_right = 95
		fig.offset_top = -270
		fig.offset_bottom = -52
		stage.add_child(fig)
	var pw := UiTheme.label("PUISSANCE %d" % (Profile.power() if who == "player" else Profile.companion_power(who)), 26, UiTheme.GOLD)
	pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(pw)
	var info := HBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 0)
	mid.add_child(info)
	info.add_child(UiTheme.label("Niveau %d · " % (Profile.level() if who == "player" else Profile.companion_level(who)), 17, UiTheme.MUTED))
	info.add_child(UiTheme.label(str(BattleSim.ELEM_NAMES.get(el, "Physique")), 17, ecol))
	h.add_child(_slot_column(RIGHT, eqd))
	var n_up := 0
	for n in _better_by_slot.values():
		n_up += int(n)
	if n_up > 0:
		var hint := HBoxContainer.new()
		hint.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(hint)
		hint.add_child(_up_label("%d objet%s de la réserve meilleur%s que l'équipé (flèches vertes)" % [n_up, "s" if n_up > 1 else "", "s" if n_up > 1 else ""], 15))
	return c[0]


func _slot_column(slots: Array, eqd: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	for sl in slots:
		var slot := str(sl)
		var uid := str(eqd.get(slot, ""))
		var it := Profile.find_item(uid) if uid != "" else {}
		var b := GearUi.item_button(it, slot, 78, _sel == "slot:" + slot, int(_better_by_slot.get(_slot_key(slot), 0)))
		b.tooltip_text = _slot_name(slot)
		b.pressed.connect(func() -> void:
			_sel = "slot:" + slot
			_rebuild.call_deferred())
		col.add_child(b)
	return col


func _stats_card() -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 12)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	(c[1] as VBoxContainer).add_child(grid)
	var st := Profile.stats() if who == "player" else Profile.companion_stats(who)
	var names: Dictionary = Profile.items_db()["stat_names"]
	for k in Profile.STATS:
		var col: Color = GearUi.STAT_COL[k]
		var pc := PanelContainer.new()
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pc.add_theme_stylebox_override("panel", UiTheme.box(Color(col, 0.08), Color(col, 0.45), 8, 1, 6))
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		pc.add_child(cell)
		var a := UiTheme.label(str(STAT_ABBR[k]), 16, col)
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(a)
		var n := UiTheme.label("%d" % int(round(float(st[k]))), 28)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(n)
		pc.tooltip_text = str(names[k])
		grid.add_child(pc)
	return c[0]


# ---------------------------------------------------------------- fiche

func _detail() -> PanelContainer:
	if _sel.begins_with("item:"):
		return _item_detail(Profile.find_item(_sel.substr(5)))
	var slot := _sel.substr(5)
	var uid := str(Profile.equipment_of(who).get(slot, ""))
	var it := Profile.find_item(uid) if uid != "" else {}
	if it.is_empty():
		return _empty_detail(slot)
	return _equipped_detail(slot, it)


## En-tête d'une fiche : grande case, nom, rareté, emplacement, niveau d'objet, jauge d'amélioration.
func _detail_head(it: Dictionary, slot: String, v: VBoxContainer, tag: String) -> void:
	var col := Profile.item_color(it)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var tile := GearUi.item_button(it, slot, 96)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tile)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	if tag != "":
		info.add_child(UiTheme.label(tag, 15, UiTheme.TEAL))
	info.add_child(UiTheme.label(Profile.item_name(it), 25, col))
	var base := Profile.base_of(it)
	var line := "%s · %s · iLvl %d" % [str(Profile.rarity_of(it).get("name", "")), _slot_name(str(base.get("slot", slot))), int(it.get("ilvl", 1))]
	if base.has("element") and str(base["element"]) != "physique":
		line += " · %s" % str(BattleSim.ELEM_NAMES.get(str(base["element"]), ""))
	info.add_child(UiTheme.label(line, 16, UiTheme.MUTED))
	var pr := HBoxContainer.new()
	pr.add_theme_constant_override("separation", 8)
	info.add_child(pr)
	var max_up := int(Profile.rarity_of(it).get("max_up", 5))
	pr.add_child(GearUi.pips(int(it.get("up", 0)), max_up, 12))
	pr.add_child(UiTheme.label("Amélioration %d/%d" % [int(it.get("up", 0)), max_up], 15, UiTheme.MUTED))
	if bool(it.get("fused", false)):
		info.add_child(UiTheme.label("Issu d'une fusion", 15, UiTheme.FIRE))


## Stats, runes et histoire de l'objet.
func _detail_body(it: Dictionary, v: VBoxContainer) -> void:
	v.add_child(GearUi.stat_chips(Profile.item_stats(it), 18))
	_runes_line(it, v)
	var base := Profile.base_of(it)
	if base.has("lore"):
		v.add_child(UiTheme.wrap(str(base["lore"]), 16, Color(UiTheme.MUTED, 0.9)))


func _equipped_detail(slot: String, it: Dictionary) -> PanelContainer:
	var c: Array = UiTheme.card(Color(Profile.item_color(it), 0.65), 16)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 10)
	_detail_head(it, slot, v, "PORTÉ · %s" % _slot_name(slot).to_upper())
	_detail_body(it, v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	# Améliorer sans retirer : l'objet reste porté, ses stats montent tout de suite.
	row.add_child(_upgrade_button(it, 18))
	var uid := str(it["uid"])
	var rn := UiTheme.button("Runes", 18)
	rn.icon = Icons.tex("rune", 40)
	rn.add_theme_constant_override("icon_max_width", 20)
	rn.custom_minimum_size = Vector2(120, 52)
	rn.add_theme_color_override("font_color", UiTheme.FIRE)
	rn.add_theme_color_override("icon_normal_color", UiTheme.FIRE)
	rn.pressed.connect(func() -> void: open_forge.emit(uid))
	row.add_child(rn)
	var rm := UiTheme.button("Retirer", 18)
	rm.custom_minimum_size = Vector2(110, 52)
	rm.pressed.connect(func() -> void: _act(func() -> void:
		Profile.unequip_from(who, slot)
		Snd.sfx("ui_equip", -4.0, 0.9)))
	row.add_child(rm)
	var n := int(_better_by_slot.get(_slot_key(slot), 0))
	if n > 0:
		v.add_child(_better_button(slot, n))
	return c[0]


func _empty_detail(slot: String) -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 16)
	var v: VBoxContainer = c[1]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var tile := GearUi.item_button({}, slot, 80)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tile)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiTheme.label(_slot_name(slot).to_upper(), 23, UiTheme.TEXT))
	var have := 0
	for it in Profile.data["inventory"]:
		if Profile.holder_of(str(it["uid"])) == "" and _slot_key(str(Profile.base_of(it).get("slot", ""))) == _slot_key(slot):
			have += 1
	info.add_child(UiTheme.wrap("Emplacement libre. %s" % ("%d objet%s de la réserve peu%s s'y porter." % [have, "s" if have > 1 else "", "vent" if have > 1 else "t"] if have > 0 else "Rien dans la réserve pour cet emplacement : les coffres de fin de partie en contiennent."), 16, UiTheme.MUTED))
	if have > 0:
		var f := UiTheme.button("Voir ces objets", 18)
		f.custom_minimum_size = Vector2(0, 50)
		f.add_theme_color_override("font_color", UiTheme.TEAL)
		f.pressed.connect(func() -> void:
			_filter = _slot_key(slot)
			_rebuild.call_deferred())
		v.add_child(f)
	return c[0]


func _item_detail(it: Dictionary) -> PanelContainer:
	var cmp: Dictionary = _cmp.get(str(it["uid"]), Profile.compare_to_equipped(who, it))
	var better := bool(cmp["better"])
	var c: Array = UiTheme.card(UiTheme.GOOD if better else Color(Profile.item_color(it), 0.65), 16)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 10)
	if better:
		v.add_child(_compare_badge(cmp))
	var slot := str(Profile.base_of(it).get("slot", ""))
	_detail_head(it, slot, v, "EN RÉSERVE")
	_detail_body(it, v)
	var vs := str(cmp["vs"])
	if vs != "" and not (cmp["diff"] as Dictionary).is_empty():
		var cr := HBoxContainer.new()
		cr.add_theme_constant_override("separation", 8)
		v.add_child(cr)
		var lb := UiTheme.label("vs %s :" % Profile.item_name(Profile.find_item(vs)), 15, UiTheme.MUTED)
		lb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cr.add_child(lb)
		var chips := GearUi.stat_chips(cmp["diff"], 16, true)
		chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cr.add_child(chips)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var uid := str(it["uid"])
	var eq := UiTheme.button("Équiper" if who == "player" else "Équiper sur %s" % Dialogues.display_name(who), 20)
	eq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq.custom_minimum_size = Vector2(0, 56)
	eq.add_theme_color_override("font_color", UiTheme.GOLD)
	eq.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.85), 12, 2, 8, UiTheme.GOLD))
	eq.pressed.connect(func() -> void: _act(func() -> void:
		Profile.equip_to(who, uid)
		Snd.sfx("ui_equip", -3.0)
		var s2 := str(Profile.base_of(it).get("slot", ""))
		var eqd := Profile.equipment_of(who)
		for k in eqd.keys():
			if str(eqd[k]) == uid:
				s2 = str(k)
		_sel = "slot:" + s2))
	row.add_child(eq)
	row.add_child(_upgrade_button(it, 17))
	var sv := UiTheme.button("Recycler · +%d" % Profile.salvage_value(it), 17)
	sv.custom_minimum_size = Vector2(150, 56)
	sv.icon = Icons.tex("dust", 40)
	sv.add_theme_constant_override("icon_max_width", 18)
	sv.add_theme_color_override("icon_normal_color", UiTheme.VIOLET)
	sv.pressed.connect(func() -> void: _act(func() -> void:
		Profile.salvage(uid)
		Snd.sfx("sw_spark", -2.0, 0.9)
		_sel = ""))
	row.add_child(sv)
	return c[0]


## Bouton « Améliorer en +N · prix » d'un objet (porté ou en réserve) : niveau atteint, prix, or manquant.
func _upgrade_button(it: Dictionary, fs: int) -> Button:
	var uid := str(it["uid"])
	var max_up := int(Profile.rarity_of(it).get("max_up", 5))
	var lvl := int(it.get("up", 0))
	var cost := Profile.upgrade_cost(it)
	var txt := "Niveau max (+%d)" % max_up
	if lvl < max_up:
		txt = "Améliorer en +%d · %d or" % [lvl + 1, cost]
		if Profile.gold() < cost:
			txt += " (il manque %d)" % (cost - Profile.gold())
	var up := UiTheme.button(txt, fs)
	up.set_meta("uid", uid)
	up.icon = Icons.tex("up", 40)
	up.add_theme_constant_override("icon_max_width", 18)
	up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up.custom_minimum_size = Vector2(0, 52)
	up.disabled = not Profile.can_upgrade(it)
	if not up.disabled:
		up.add_theme_color_override("font_color", UiTheme.GOLD)
		up.add_theme_color_override("icon_normal_color", UiTheme.GOLD)
		up.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.8), 12, 2, 8))
	up.pressed.connect(func() -> void: _act(func() -> void:
		if Profile.upgrade(uid):
			Snd.sfx("ui_anvil", -4.0, randf_range(0.97, 1.03))))
	return up


## « 2 meilleurs en réserve » : n'affiche dans la réserve que les objets de cet emplacement.
func _better_button(slot: String, n: int) -> Button:
	var b := UiTheme.button("%d meilleur%s en réserve : voir" % [n, "s" if n > 1 else ""], 17)
	b.icon = Icons.tex("up", 36)
	b.add_theme_constant_override("icon_max_width", 16)
	b.add_theme_color_override("icon_normal_color", UiTheme.GOOD)
	b.custom_minimum_size = Vector2(0, 46)
	b.add_theme_color_override("font_color", UiTheme.GOOD)
	b.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.GOOD, 0.12), Color(UiTheme.GOOD, 0.7), 10, 1, 6))
	b.pressed.connect(func() -> void:
		_filter = "" if _filter == _slot_key(slot) else _slot_key(slot)
		_rebuild.call_deferred())
	return b


## Runes gravées : emplacements et effets.
func _runes_line(it: Dictionary, v: VBoxContainer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	if Profile.sockets_of(it) <= 0:
		return row
	row.add_child(ForgeScreen.sockets_row(it, 24))
	var cat := Profile.rune_category(str(Profile.base_of(it).get("slot", "")))
	var fx: Array[String] = []
	for r in it.get("runes", []):
		fx.append(Profile.rune_effect_text(r, cat))
	var t := UiTheme.wrap(" · ".join(fx) if not fx.is_empty() else "Aucune rune gravée (Forge de Durgan)", 15, UiTheme.TEAL if not fx.is_empty() else UiTheme.MUTED)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	return row


# ---------------------------------------------------------------- réserve

func _inventory() -> void:
	var items: Array = []
	var counts: Dictionary = {}
	for it in Profile.data["inventory"]:
		if Profile.holder_of(str(it["uid"])) != "":
			continue
		var k := _slot_key(str(Profile.base_of(it).get("slot", "")))
		counts[k] = int(counts.get(k, 0)) + 1
		if _filter != "" and k != _filter:
			continue
		items.append(it)
	var total := 0
	for n in counts.values():
		total += int(n)
	_col.add_child(UiTheme.section("Réserve · %d objet%s" % [total, "s" if total > 1 else ""]))
	if total == 0:
		_col.add_child(_empty_inventory())
		return
	# Filtres par emplacement.
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	_col.add_child(flow)
	flow.add_child(_filter_chip("", "Tout · %d" % total))
	for f in FILTERS:
		if int(counts.get(f, 0)) > 0:
			flow.add_child(_filter_chip(str(f), "%s · %d" % [_slot_name(str(f)), int(counts[f])]))
	# Les objets meilleurs que l'équipement porté d'abord (le plus gros gain en tête), puis le reste.
	items.sort_custom(func(a: Dictionary, c: Dictionary) -> bool:
		var pa := int(_cmp[str(a["uid"])]["power"]) if bool(_cmp[str(a["uid"])]["better"]) else 0
		var pc := int(_cmp[str(c["uid"])]["power"]) if bool(_cmp[str(c["uid"])]["better"]) else 0
		if pa != pc:
			return pa > pc
		return _item_order(a, c))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_col.add_child(grid)
	for it in items:
		var uid := str(it["uid"])
		var slot := str(Profile.base_of(it).get("slot", ""))
		var b := GearUi.item_button(it, slot, 100, _sel == "item:" + uid, 1 if bool(_cmp[uid]["better"]) else 0)
		b.tooltip_text = Profile.item_name(it)
		b.pressed.connect(func() -> void:
			_sel = "item:" + uid
			_rebuild.call_deferred())
		grid.add_child(b)


func _filter_chip(key: String, text: String) -> Button:
	var on := _filter == key
	var b := UiTheme.button(text, 16)
	b.custom_minimum_size = Vector2(0, 42)
	if key != "":
		b.icon = Icons.tex(str(Icons.SLOT_ICON.get(key, "rune")), 36)
		b.add_theme_constant_override("icon_max_width", 18)
	b.add_theme_color_override("font_color", UiTheme.GOLD if on else UiTheme.MUTED)
	b.add_theme_color_override("icon_normal_color", UiTheme.GOLD if on else UiTheme.MUTED)
	b.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94) if on else Color(UiTheme.PANEL, 0.85), Color(UiTheme.GOLD, 0.8) if on else UiTheme.BORDER, 8, 1, 6))
	b.pressed.connect(func() -> void:
		_filter = key
		_rebuild.call_deferred())
	return b


func _empty_inventory() -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 14)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	(c[1] as VBoxContainer).add_child(h)
	h.add_child(UiTheme.icon_rect("rune", 34, UiTheme.MUTED))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	v.add_child(UiTheme.label("Aucun objet en réserve", 20))
	v.add_child(UiTheme.wrap("Les coffres de fin de partie en contiennent : 1 coffre par étoile obtenue.", 16, UiTheme.MUTED))
	return c[0]


# ---------------------------------------------------------------- outils

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
