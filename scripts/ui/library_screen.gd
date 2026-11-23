class_name LibraryScreen
extends Control
## Bibliothèque : grimoire du héros. Choix des 7 sorts emportés en combat (le deck) et sorts à
## apprendre contre de l'or, rangés par école (Feu, Givre, Foudre, Nature, Ombre, Arcane, Terre) et par rang,
## de Novice à Interdit (docs/design/18-rangs-des-sorts.md).

signal back

var _msg := ""
var _school := "" ## école filtrée ; « classes » : sorts propres à chaque classe
var _class_view := "" ## classe affichée dans l'onglet Classes


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.68)
	_rebuild()


## Sorts du grimoire (hors sorts des compagnons et Ultimes). Les sorts d'arbre sans rang
## n'apparaissent que pour leur classe (ou une fois connus).
static func catalogue() -> Array[String]:
	var out: Array[String] = []
	var known := Profile.known_spells()
	for id in GameData.spells().keys():
		var sp: Dictionary = GameData.spells()[id]
		if not (Profile.BASE_SPELLS.has(id) or sp.has("learn") or sp.has("source") or sp.has("rank")):
			continue
		if sp.has("tree_class") and not sp.has("rank") and str(sp["tree_class"]) != Profile.player_class() and not known.has(str(id)):
			continue
		out.append(str(id))
	return out


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 12)
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
	tv.add_child(UiTheme.title("BIBLIOTHÈQUE", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title("GRIMOIRE ET DECK", 22, UiTheme.TEXT))
	var deck := Profile.deck()
	var known := Profile.known_spells()
	col.add_child(UiTheme.wrap("Deck : %d / %d sorts. Sorts connus : %d / %d. Chaque sort s'achète en or, selon sa puissance ; la magie interdite se paie aussi en Corruption et en Barrière. En mode Tiroir (choisi à la Préparation), tous les sorts connus sont emportés." % [
		deck.size(), Profile.DECK_MAX, known.size(), catalogue().size()], 18, UiTheme.MUTED))
	col.add_child(_deck_row(deck))
	if _msg != "":
		col.add_child(UiTheme.wrap(_msg, 18, UiTheme.GOLD))
	col.add_child(_school_tabs())
	if _school == "classes":
		_class_sections(col, known, deck)
		return
	var cat := catalogue()
	for rank in Profile.SPELL_RANKS:
		var ids: Array[String] = []
		for id in cat:
			var sp: Dictionary = GameData.spells()[id]
			if str(sp.get("rank", "")) == rank and (_school == "" or str(sp.get("school", "")) == _school):
				ids.append(id)
		if ids.is_empty():
			continue
		var ri: Dictionary = Profile.RANK_INFO[rank]
		var lo := 1 << 30
		var hi := 0
		for id in ids:
			lo = mini(lo, Profile.spell_price(id))
			hi = maxi(hi, Profile.spell_price(id))
		col.add_child(UiTheme.section("%s · %s" % [str(ri["name"]), ("%d or" % lo) if lo == hi else "%d à %d or" % [lo, hi]], Color(str(ri["color"]))))
		for id in ids:
			col.add_child(_spell_card(id, known.has(id), deck.has(id)))
	# Sorts hors école (Purifier).
	if _school == "":
		var other: Array[String] = []
		for id in cat:
			if not GameData.spells()[id].has("rank"):
				other.append(id)
		if not other.is_empty():
			col.add_child(UiTheme.section("Utilitaire"))
			for id in other:
				col.add_child(_spell_card(id, known.has(id), deck.has(id)))


## Sorts du deck en petites icônes (toucher une icône retire le sort du deck).
func _deck_row(deck: Array[String]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for id in deck:
		var sp: Dictionary = GameData.spells()[id]
		var scol := Color(str(sp.get("color", "6fdccf")))
		var chip := Button.new()
		chip.icon = Icons.tex(id, 48)
		chip.expand_icon = true
		chip.custom_minimum_size = Vector2(52, 52)
		chip.tooltip_text = str(sp["name"])
		chip.add_theme_color_override("icon_normal_color", scol)
		chip.add_theme_color_override("icon_hover_color", scol.lightened(0.3))
		chip.add_theme_stylebox_override("normal", UiTheme.box(Color("0a1019"), Color(scol, 0.7), 8, 2, 6))
		chip.add_theme_stylebox_override("hover", UiTheme.box(Color("0a1019"), scol, 8, 2, 6))
		var sid := id
		chip.pressed.connect(func() -> void:
			_msg = Profile.toggle_deck(sid)
			if _msg == "":
				_msg = "%s retiré du deck." % str(GameData.spells()[sid]["name"])
			_save()
			_rebuild.call_deferred())
		row.add_child(chip)
	for i in range(Profile.DECK_MAX - deck.size()):
		var empty := PanelContainer.new()
		empty.custom_minimum_size = Vector2(52, 52)
		empty.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.5), Color(UiTheme.BORDER, 0.6), 8, 1, 6))
		row.add_child(empty)
	return row


func _school_tabs() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 6)
	var tabs := [["", "Tous", "rune", "6fdccf"], ["feu", "Feu", "boule_de_feu", "FF9B4A"], ["givre", "Givre", "pluie_de_givre", "9FE3FF"],
		["foudre", "Foudre", "eclair_chaine", "F0D23C"], ["nature", "Nature", "racines", "8FD16A"], ["ombre", "Ombre", "vortex_ombre", "8E62E0"],
		["arcane", "Arcane", "onde_arcanique", "B07CFF"], ["terre", "Terre", "seisme", "C8A070"], ["classes", "Classes", "target", "F2C46B"]]
	for t in tabs:
		var id := str(t[0])
		var tc := Color(str(t[3]))
		var on := id == _school
		var bt := UiTheme.button(str(t[1]), 15)
		bt.icon = Icons.tex(str(t[2]), 40)
		bt.add_theme_constant_override("icon_max_width", 18)
		bt.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bt.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		bt.add_theme_color_override("icon_normal_color", tc if on else Color(tc, 0.7))
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.custom_minimum_size = Vector2(0, 58)
		if on:
			bt.add_theme_color_override("font_color", tc)
			bt.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), tc, 10, 2, 4))
		bt.pressed.connect(func() -> void:
			_school = id
			_rebuild.call_deferred())
		g.add_child(bt)
	return g


## Sorts propres à une classe : son Ultime, les sorts débloqués par son arbre (branche, palier, verrou)
## et ceux qu'un compagnon de cette voie peut emporter.
static func class_spells(cls: String) -> Dictionary:
	var classes: Dictionary = GameData.party()["classes"]
	var cd: Dictionary = classes.get(cls, {})
	var tree: Array = []
	var td: Dictionary = GameData.load_json("res://data/skill_trees/%s.json" % cls)
	for br in td.get("branches", []):
		for tier in br.get("tiers", []):
			for node in tier["nodes"]:
				if node.has("unlock") and GameData.spells().has(str(node["unlock"])):
					tree.append({"id": str(node["unlock"]), "branch": str(br.get("name", "")), "req": int(tier.get("req", 0)),
						"surge": br.has("unlock_flag"), "locked": Profile.branch_locked(br) if cls == Profile.player_class() else ""})
	var comp: Array[String] = []
	for sid in Profile.CLASS_SPELLS.get(cls, []):
		comp.append(str(sid))
	return {"ultimate": str(cd.get("ultimate", "")), "tree": tree, "companion": comp}


func _class_name(cls: String) -> String:
	return str((GameData.party()["classes"] as Dictionary).get(cls, {}).get("name", cls))


## Onglet Classes : choix de la classe, puis son Ultime, ses sorts d'arbre et ses sorts de compagnon.
func _class_sections(col: VBoxContainer, known: Array[String], deck: Array[String]) -> void:
	if _class_view == "":
		_class_view = Profile.player_class()
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	col.add_child(g)
	var classes: Dictionary = GameData.party()["classes"]
	for cid in classes.keys():
		if not bool((classes[cid] as Dictionary).get("playable", false)):
			continue
		var on := str(cid) == _class_view
		var mine := str(cid) == Profile.player_class()
		var bt := UiTheme.button(_class_name(str(cid)), 15)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.custom_minimum_size = Vector2(0, 50)
		if mine:
			bt.add_theme_color_override("font_color", UiTheme.TEAL)
		if on:
			if not mine:
				bt.add_theme_color_override("font_color", UiTheme.GOLD)
			bt.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), UiTheme.GOLD, 10, 2, 4))
		var target := str(cid)
		bt.pressed.connect(func() -> void:
			_class_view = target
			_rebuild.call_deferred())
		g.add_child(bt)
	var cls := _class_view
	var mine_cls := cls == Profile.player_class()
	var info := class_spells(cls)
	var intro := "En turquoise : ta voie actuelle. Les sorts d'arbre se débloquent en investissant des points dans l'arbre de la classe (Entraînement)."
	if not mine_cls:
		intro = "Tu suis la voie : %s. Pour obtenir ces sorts, change de voie à la Salle de méditation (dès l'acte 2), puis investis dans l'arbre de cette classe." % _class_name(Profile.player_class())
	col.add_child(UiTheme.wrap(intro, 17, UiTheme.MUTED))
	# Ultime.
	col.add_child(UiTheme.section("Ultime"))
	var ult := str(info["ultimate"])
	if ult != "":
		col.add_child(_spell_card(ult, mine_cls, false, "Se lance quand la jauge Surge est pleine (bouton ULTIME).", true))
	# Sorts de l'arbre.
	col.add_child(UiTheme.section("Sorts de l'arbre"))
	for t in info["tree"]:
		var sid := str(t["id"])
		var how := "Arbre : %s · branche %s · %d points dans la branche" % [_class_name(cls), str(t["branch"]), int(t["req"])]
		if bool(t["surge"]):
			how += " · Voie du Surge (fin de l'acte 3)"
		if GameData.spells()[sid].has("rank"):
			how += " · aussi en vente dans son école"
		var is_known := mine_cls and known.has(sid)
		col.add_child(_spell_card(sid, is_known, is_known and deck.has(sid), how, not is_known))
	# Sorts de compagnon.
	if not (info["companion"] as Array).is_empty():
		col.add_child(UiTheme.section("Sorts d'un compagnon de cette voie"))
		col.add_child(UiTheme.wrap("Un compagnon qui suit cette voie emporte l'un de ces sorts (au choix, au Cercle).", 16, UiTheme.MUTED))
		for sid in info["companion"]:
			col.add_child(_spell_card(str(sid), false, false, "Choisi au Cercle pour un compagnon %s." % _class_name(cls), true))


func _spell_card(id: String, known: bool, in_deck: bool, how: String = "", info_only: bool = false) -> PanelContainer:
	var sp: Dictionary = GameData.spells()[id]
	var scol := Color(str(sp.get("color", "6fdccf")))
	var rank := str(sp.get("rank", ""))
	var ri: Dictionary = Profile.RANK_INFO.get(rank, {})
	var forbidden := rank == "interdit"
	var block := "" if known else Profile.learn_block(id)
	var level_locked := block.begins_with("Niveau")
	var poor := block == "Or insuffisant"
	var c: Array = UiTheme.card(Color(scol, 0.75) if in_deck else (Color("D93CF2", 0.6) if forbidden else UiTheme.BORDER), 12)
	var pc: PanelContainer = c[0]
	if level_locked or poor:
		pc.modulate = Color(1, 1, 1, 0.72 if poor else 0.55)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	(c[1] as VBoxContainer).add_child(h)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), Color(scol, 0.7), 8, 2, 8))
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(frame)
	frame.add_child(UiTheme.icon_rect("lock" if level_locked else id, 36, UiTheme.MUTED if level_locked else scol))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiTheme.label(str(sp["name"]), 22, scol))
	var tags: Array[String] = []
	if not ri.is_empty():
		tags.append(str(ri["name"]))
	if sp.has("school"):
		tags.append(str(Profile.SCHOOLS.get(str(sp["school"]), "")))
	if sp.has("rank"):
		tags.append("puissance %d" % Profile.spell_power(id))
	if int(sp.get("mana", 0)) > 0 or int(sp.get("cd", 0)) > 0:
		tags.append("%d mana" % int(sp.get("mana", 0)))
		tags.append("recharge %d s" % int(sp.get("cd", 0)))
	else:
		tags.append("Ultime")
	v.add_child(UiTheme.label(" · ".join(tags), 16, Color(str(ri.get("color", "8a9bb0"))) if not ri.is_empty() else UiTheme.MUTED))
	v.add_child(UiTheme.wrap(str(sp.get("desc", "")), 17, UiTheme.TEXT))
	if how != "":
		v.add_child(UiTheme.wrap(how, 15, UiTheme.TEAL))
	if info_only:
		if not known:
			h.add_child(UiTheme.icon_rect("lock" if not sp.has("rank") else "book", 22, UiTheme.MUTED))
		return pc
	if known:
		var t := UiTheme.button("Dans le deck" if in_deck else "Ajouter", 18)
		t.custom_minimum_size = Vector2(130, 54)
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if in_deck:
			t.add_theme_color_override("font_color", UiTheme.TEAL)
			t.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.94), UiTheme.TEAL, 10, 2, 6))
		t.pressed.connect(func() -> void:
			_msg = Profile.toggle_deck(id)
			_save()
			_rebuild.call_deferred())
		h.add_child(t)
		return pc
	var l := Profile.learn_info(id)
	if l.is_empty():
		h.add_child(UiTheme.icon_rect("lock", 22, UiTheme.MUTED))
		v.add_child(UiTheme.label(str(sp.get("source", "")), 15, UiTheme.MUTED))
		return pc
	var lb := UiTheme.button("Apprendre\n%d or" % int(l.get("gold", 0)), 17)
	lb.custom_minimum_size = Vector2(130, 60)
	lb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lb.disabled = block != ""
	if block == "":
		var bc := Color("D93CF2") if forbidden else UiTheme.GOLD
		lb.add_theme_color_override("font_color", bc)
		lb.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(bc, 0.85), 10, 2, 6))
	lb.pressed.connect(func() -> void:
		if Profile.learn(id):
			_msg = "%s appris." % str(sp["name"])
			if int(l.get("corruption", 0)) > 0:
				_msg += " La Corruption grandit (+%d)." % int(l["corruption"])
			_save()
		_rebuild.call_deferred())
	h.add_child(lb)
	var req := "Prix : %d or" % int(l.get("gold", 0))
	if l.has("level"):
		req = "Niveau %d requis · " % int(l["level"]) + req
	if poor:
		req += " · il te manque %d or" % (int(l.get("gold", 0)) - Profile.gold())
	if int(l.get("corruption", 0)) > 0:
		req += " · Corruption +%d" % int(l["corruption"])
	v.add_child(UiTheme.label(req, 15, UiTheme.MUTED if block != "" else UiTheme.GOOD))
	if sp.has("source"):
		v.add_child(UiTheme.label("Aussi offert par l'arbre de compétences", 15, UiTheme.MUTED))
	return pc


func _save() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
