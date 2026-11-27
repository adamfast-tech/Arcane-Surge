class_name LibraryScreen
extends Control
## Bibliothèque d'Ossian (docs/design/14-interface.md) : le grimoire du héros.
## - Ossian, l'archiviste, commente en bandeau ;
## - le deck : les 7 sorts emportés en combat, en barre de sorts ;
## - les écoles (Feu, Givre, Foudre, Nature, Ombre, Arcane, Terre) et les Classes en médaillons ;
## - les sorts en grille, par rang de Novice à Interdit (docs/design/18-rangs-des-sorts.md) : appris, dans
##   le deck, à apprendre (prix), verrouillés (niveau) ;
## - la fiche du sort touché, fixe en bas : stats, description, écouter, ajouter au deck ou apprendre.

signal back

var _msg := ""
var _msg_col := UiTheme.GOLD
var _school := "" ## école filtrée ; « classes » : sorts propres à chaque classe
var _class_view := "" ## classe affichée dans l'onglet Classes
var _class_part := "grimoire" ## onglet Classes : « grimoire » (techniques par rang) ou « voie » (Ultime, arbre, compagnons)
var _disc := "" ## discipline filtrée dans le grimoire de classe
var _sel := "" ## sort affiché dans la fiche
var _ctx: Dictionary = {} ## sort -> {how, info_only, known} selon l'onglet où il est montré
var _tiles: Dictionary = {} ## sort -> tuile (pour la surbrillance)
var _scroll: ScrollContainer
var _sheet: VBoxContainer

const TILE := 98
const SCHOOL_TABS := [["", "Tous", "rune", "6fdccf"], ["feu", "Feu", "boule_de_feu", "ff9b4a"], ["givre", "Givre", "pluie_de_givre", "9fe3ff"],
	["foudre", "Foudre", "eclair_chaine", "f0d23c"], ["nature", "Nature", "racines", "8fd16a"], ["ombre", "Ombre", "vortex_ombre", "8e62e0"],
	["arcane", "Arcane", "onde_arcanique", "b07cff"], ["terre", "Terre", "seisme", "c8a070"], ["classes", "Classes", "target", "f2c46b"]]
const CLASS_COL := {"mage": "b07cff", "archer": "7fd36a", "epeiste": "6fc8ff", "clerc": "ffe08a", "necromancien": "64e0b0",
	"chevalier": "c8d4e8", "berserker": "ff6b4a"}
const OSSIAN := "c8a36a"

## Ce que dit Ossian, selon l'onglet.
const LINES := {
	"": "Sept sorts tiennent dans ta main en combat. Choisis-les bien : je garde les autres au chaud, entre deux reliures.",
	"feu": "Le Feu ne pardonne pas l'hésitation. Ni la tienne, ni celle de tes ennemis.",
	"givre": "Le Givre ne tue pas vite, il tue sûrement : ce qui ralentit finit par tomber.",
	"foudre": "La Foudre saute d'un ennemi à l'autre. Plus ils sont serrés, plus elle chante.",
	"nature": "Ronces, sève, racines : la Nature soigne autant qu'elle étouffe.",
	"ombre": "L'Ombre ronge. Garde un œil sur ta Corruption quand tu tournes ces pages-là.",
	"arcane": "L'Arcane est la langue d'origine. Précise, rapide, sans élément à contrer.",
	"terre": "La Terre brise les piliers et assomme les groupes. Lente, mais rien ne lui résiste.",
	"classes": "Chaque voie a son grimoire. Ce qu'une classe apprend ici ne sert qu'en la suivant.",
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.5, 0.0, "arcane", "bibliotheque")
	_rebuild()


## Sorts du grimoire élémentaire (hors sorts des compagnons et Ultimes). Les sorts de classe, du grimoire
## ou de l'arbre de compétences, sont rangés dans l'onglet Classes.
static func catalogue() -> Array[String]:
	var out: Array[String] = []
	for id in GameData.spells().keys():
		var sp: Dictionary = GameData.spells()[id]
		if not (Profile.BASE_SPELLS.has(id) or sp.has("learn") or sp.has("source") or sp.has("rank")):
			continue
		if sp.has("grimoire"):
			continue # grimoires de classe : onglet Classes
		if Profile.spell_class(str(id)) != "":
			continue # sorts d'arbre d'une classe : onglet Classes, avec sa discipline
		out.append(str(id))
	return out


func _rebuild() -> void:
	var keep := _scroll.scroll_vertical if is_instance_valid(_scroll) else 0
	var old := get_node_or_null("LibRoot")
	if old != null:
		old.name = "LibRootOld"
		old.queue_free()
	_ctx.clear()
	_tiles.clear()
	var deck := Profile.deck()
	var known := Profile.known_spells()
	if _sel == "" or not GameData.spells().has(_sel):
		_sel = deck[0] if not deck.is_empty() else ""
	var margin := MarginContainer.new()
	margin.name = "LibRoot"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in [["margin_left", 18], ["margin_right", 18], ["margin_top", 14], ["margin_bottom", 12]]:
		margin.add_theme_constant_override(str(k[0]), int(k[1]))
	add_child(margin)
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(center)
	var frame := VBoxContainer.new()
	frame.add_theme_constant_override("separation", 10)
	frame.custom_minimum_size = Vector2(minf(680.0, get_viewport_rect().size.x - 36.0), 0)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(frame)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	frame.add_child(head)
	var b := UiTheme.back_button("Havre-Aube")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	head.add_child(GearUi.purse())
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(_scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(col)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("BIBLIOTHÈQUE", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title("LE GRIMOIRE D'OSSIAN", 20, UiTheme.TEXT))
	col.add_child(GearUi.speaker_banner("ossian", "Ossian", "Archiviste", str(LINES.get(_school, LINES[""])), UiTheme.TEXT, Color(OSSIAN)))
	col.add_child(_deck_panel(deck))
	col.add_child(_school_row(known))
	if _school != "classes" and not Profile.elem_for_all() and Profile.player_class() != "mage":
		col.add_child(UiTheme.wrap("Option « Chaque voie son grimoire » : les écoles élémentaires sont réservées au Mage. Tes sorts élémentaires appris restent ici et reviendront si tu changes d'option ou de voie (clé à molette de Havre-Aube).", 15, Color("d9a0f2")))
	if _school == "classes":
		_class_sections(col, known, deck)
	else:
		_school_sections(col, known, deck)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 12)
	col.add_child(pad)
	var c: Array = UiTheme.card(Color(UiTheme.GOLD, 0.45), 12)
	frame.add_child(c[0])
	_sheet = c[1]
	_sheet.add_theme_constant_override("separation", 8)
	_fill_sheet()
	if keep > 0:
		_restore.call_deferred(keep)


func _restore(v: int) -> void:
	await get_tree().process_frame
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = v


# ---------------------------------------------------------------- deck

## Le deck en barre de sorts : toucher un sort l'affiche dans la fiche (d'où on peut le retirer).
func _deck_panel(deck: Array[String]) -> PanelContainer:
	var c: Array = UiTheme.card(Color(UiTheme.TEAL, 0.5), 12)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	top.add_child(UiTheme.label("TON DECK", 20, UiTheme.TEAL))
	top.add_child(UiTheme.label("%d / %d" % [deck.size(), Profile.DECK_MAX], 20, UiTheme.GOLD))
	top.add_child(UiTheme.spacer())
	var mana := 0
	var schools: Dictionary = {}
	for id in deck:
		var sp: Dictionary = GameData.spells()[id]
		mana += int(sp.get("mana", 0))
		var sc := str(sp.get("school", sp.get("element", "")))
		schools[sc] = int(schools.get(sc, 0)) + 1
	for t in SCHOOL_TABS:
		var n := int(schools.get(str(t[0]), 0))
		if str(t[0]) == "" or n == 0:
			continue
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 2)
		chip.add_child(UiTheme.icon_rect(str(t[2]), 16, Color(str(t[3]))))
		chip.add_child(UiTheme.label("%d" % n, 15, Color(str(t[3]))))
		top.add_child(chip)
	top.add_child(UiTheme.label("· %d mana moy." % int(round(float(mana) / float(maxi(deck.size(), 1)))), 15, UiTheme.MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for id in deck:
		var t := _spell_button(id, 82, true, false, true)
		row.add_child(t)
		_tiles[id + "#deck"] = t
	for i in range(Profile.DECK_MAX - deck.size()):
		var e := PanelContainer.new()
		e.custom_minimum_size = Vector2(82, 82)
		e.add_theme_stylebox_override("panel", UiTheme.box(Color(0, 0, 0, 0.3), Color(UiTheme.MUTED, 0.4), 12, 1, 0))
		var plus := UiTheme.label("+", 30, Color(UiTheme.MUTED, 0.5))
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		e.add_child(plus)
		row.add_child(e)
	v.add_child(UiTheme.label("Touche un sort pour sa fiche. Mode Tiroir (Préparation) : tous les sorts connus partent au combat.", 14, UiTheme.MUTED))
	return c[0]


# ---------------------------------------------------------------- écoles

func _school_row(known: Array[String]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	var cat := catalogue()
	for t in SCHOOL_TABS:
		var id := str(t[0])
		var total := 0
		var got := 0
		if id != "classes":
			for sid in cat:
				if id == "" or str((GameData.spells()[sid] as Dictionary).get("school", "")) == id:
					total += 1
					if known.has(sid):
						got += 1
		var s := Sigil.new()
		s.glyph = Icons.tex(str(t[2]), 96, 1.6)
		s.col = Color(str(t[3]))
		s.on = id == _school
		s.text_under = str(t[1])
		s.frac = float(got) / float(total) if total > 0 else -1.0
		s.setup(70.0)
		s.pressed.connect(func() -> void:
			if _school == id:
				return
			_school = id
			_msg = ""
			_scroll.scroll_vertical = 0
			_rebuild.call_deferred())
		row.add_child(s)
	return row


func _school_sections(col: VBoxContainer, known: Array[String], deck: Array[String]) -> void:
	var cat := catalogue()
	for rank in Profile.SPELL_RANKS:
		var ids: Array[String] = []
		for id in cat:
			var sp: Dictionary = GameData.spells()[id]
			if str(sp.get("rank", "")) == rank and (_school == "" or str(sp.get("school", "")) == _school):
				ids.append(id)
		if ids.is_empty():
			continue
		col.add_child(_rank_header(rank, ids, known))
		var g := _grid()
		col.add_child(g)
		for id in ids:
			_ctx[id] = {"known": known.has(id), "info_only": false, "how": ""}
			g.add_child(_tile(id, known.has(id), deck.has(id), false))
	if _school == "":
		var other: Array[String] = []
		for id in cat:
			if not (GameData.spells()[id] as Dictionary).has("rank"):
				other.append(id)
		if not other.is_empty():
			col.add_child(UiTheme.section("Utilitaire"))
			var g2 := _grid()
			col.add_child(g2)
			for id in other:
				_ctx[id] = {"known": known.has(id), "info_only": false, "how": ""}
				g2.add_child(_tile(id, known.has(id), deck.has(id), false))


func _rank_header(rank: String, ids: Array[String], known: Array[String]) -> HBoxContainer:
	var ri: Dictionary = Profile.RANK_INFO[rank]
	var rc := Color(str(ri["color"]))
	var lo := 1 << 30
	var hi := 0
	var got := 0
	for id in ids:
		lo = mini(lo, Profile.spell_price(id))
		hi = maxi(hi, Profile.spell_price(id))
		if known.has(id) or Profile.learned(id):
			got += 1
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var gem := UiTheme.icon_rect("rune", 22, rc)
	h.add_child(gem)
	h.add_child(UiTheme.label(str(ri["name"]).to_upper(), 20, rc))
	var line := ColorRect.new()
	line.color = Color(rc, 0.35)
	line.custom_minimum_size = Vector2(0, 2)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(line)
	h.add_child(UiTheme.label("%d / %d" % [got, ids.size()], 16, UiTheme.TEXT))
	h.add_child(UiTheme.label(("%d or" % lo) if lo == hi else "%d à %d or" % [lo, hi], 16, UiTheme.MUTED))
	return h


func _grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return g


# ---------------------------------------------------------------- classes

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


## Onglet Classes : les classes en médaillons (emblème : leur Ultime), puis grimoire ou voie.
func _class_sections(col: VBoxContainer, known: Array[String], deck: Array[String]) -> void:
	if _class_view == "":
		_class_view = Profile.player_class()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	col.add_child(row)
	var classes: Dictionary = GameData.party()["classes"]
	for cid in classes.keys():
		var cd: Dictionary = classes[cid]
		if not bool(cd.get("playable", false)):
			continue
		var target := str(cid)
		var s := Sigil.new()
		s.glyph = Icons.tex(str(cd.get("ultimate", "target")), 96, 1.6)
		s.col = Color(str(CLASS_COL.get(target, "f2c46b")))
		s.on = target == _class_view
		s.mine = target == Profile.player_class()
		s.text_under = _class_name(target)
		var g := Profile.class_grimoire(target)
		var got := 0
		for sid in g:
			if Profile.learned(sid) or (target == Profile.player_class() and known.has(sid)):
				got += 1
		s.frac = float(got) / float(g.size()) if not g.is_empty() else -1.0
		s.setup(80.0)
		s.pressed.connect(func() -> void:
			_class_view = target
			_disc = ""
			_rebuild.call_deferred())
		row.add_child(s)
	var cls := _class_view
	var mine_cls := cls == Profile.player_class()
	var parts := HBoxContainer.new()
	parts.add_theme_constant_override("separation", 8)
	col.add_child(parts)
	for pt in [["grimoire", "GRIMOIRE · %d" % Profile.class_grimoire(cls).size(), "book", "Techniques par rang"], ["voie", "LA VOIE", "target", "Ultime, arbre, compagnons"]]:
		var pid := str(pt[0])
		var on := pid == _class_part
		var rb: Array = UiTheme.rich_button(64, "primary" if on else "tile")
		var bt: Button = rb[0]
		var h: HBoxContainer = rb[1]
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 8)
		h.add_child(UiTheme.icon_rect(str(pt[2]), 22, UiTheme.GOLD if on else UiTheme.MUTED))
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(tv)
		tv.add_child(UiTheme.label(str(pt[1]), 18, UiTheme.GOLD if on else UiTheme.TEXT))
		tv.add_child(UiTheme.label(str(pt[3]), 13, UiTheme.MUTED))
		bt.pressed.connect(func() -> void:
			Snd.click()
			_class_part = pid
			_rebuild.call_deferred())
		parts.add_child(bt)
	if not mine_cls:
		col.add_child(UiTheme.wrap("Tu suis la voie : %s. Pour te servir de ces sorts, change de voie à la Salle de méditation (dès l'acte 2)." % _class_name(Profile.player_class()), 15, UiTheme.MUTED))
	if _class_part == "grimoire":
		_grimoire_sections(col, cls, known, deck)
		return
	var info := class_spells(cls)
	var ult := str(info["ultimate"])
	if ult != "":
		col.add_child(UiTheme.section("Ultime", UiTheme.GOLD))
		var ur := HBoxContainer.new()
		ur.add_theme_constant_override("separation", 12)
		col.add_child(ur)
		_ctx[ult] = {"known": mine_cls, "info_only": true, "how": "Se lance quand la jauge Surge est pleine (bouton ULTIME)."}
		ur.add_child(_tile(ult, mine_cls, false, true))
		var uv := VBoxContainer.new()
		uv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		uv.add_child(UiTheme.label(str((GameData.spells()[ult] as Dictionary).get("name", "")), 20, Color(str((GameData.spells()[ult] as Dictionary).get("color", "f2c46b")))))
		uv.add_child(UiTheme.wrap(str((GameData.spells()[ult] as Dictionary).get("desc", "")), 15, UiTheme.MUTED))
		ur.add_child(uv)
	col.add_child(UiTheme.section("Sorts de l'arbre (Entraînement)"))
	var g2 := _grid()
	col.add_child(g2)
	for t in info["tree"]:
		var sid := str(t["id"])
		var how := "Arbre : %s · branche %s · %d points dans la branche" % [_class_name(cls), str(t["branch"]), int(t["req"])]
		if bool(t["surge"]):
			how += " · Voie du Surge (fin de l'acte 3)"
		if (GameData.spells()[sid] as Dictionary).has("rank"):
			how += " · aussi en vente dans son école"
		var is_known := mine_cls and known.has(sid)
		_ctx[sid] = {"known": is_known, "info_only": not is_known, "how": how}
		g2.add_child(_tile(sid, is_known, is_known and deck.has(sid), not is_known))
	if not (info["companion"] as Array).is_empty():
		col.add_child(UiTheme.section("Sorts d'un compagnon de cette voie (Cercle)"))
		var g3 := _grid()
		col.add_child(g3)
		for sid in info["companion"]:
			var s2 := str(sid)
			if not _ctx.has(s2):
				_ctx[s2] = {"known": false, "info_only": true, "how": "Un compagnon %s emporte l'un de ces sorts, au choix, au Cercle." % _class_name(cls)}
			g3.add_child(_tile(s2, false, false, true))


## Grimoire d'une classe : ses techniques par rang (Novice à Interdit), filtrables par discipline.
func _grimoire_sections(col: VBoxContainer, cls: String, known: Array[String], deck: Array[String]) -> void:
	var ids := Profile.class_grimoire(cls)
	var mine := cls == Profile.player_class()
	if ids.is_empty():
		if cls == "mage":
			col.add_child(UiTheme.wrap("Le grimoire du Mage, ce sont les sept écoles élémentaires (médaillons Feu à Terre) : 56 sorts, de Novice à Interdit, ouverts à toutes les voies.", 16, UiTheme.MUTED))
		else:
			col.add_child(UiTheme.wrap("Le grimoire de cette voie s'écrit encore : ses techniques arrivent bientôt.", 16, UiTheme.MUTED))
		return
	# Disciplines : des pastilles à icône, avec le nombre de techniques apprises.
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	col.add_child(flow)
	var tabs: Array = [{"id": "", "name": "Toutes", "icon": "book", "color": "6fdccf"}]
	tabs.append_array(Profile.disciplines(cls))
	for t in tabs:
		var did := str(t["id"])
		var tc := Color(str(t["color"]))
		var on := did == _disc
		var n := 0
		var got := 0
		for id in ids:
			if did == "" or str((GameData.spells()[id] as Dictionary).get("disc", "")) == did:
				n += 1
				if Profile.learned(id) or (mine and known.has(id)):
					got += 1
		var bt := Button.new()
		bt.focus_mode = Control.FOCUS_NONE
		bt.text = "%s %d/%d" % [str(t["name"]), got, n]
		bt.icon = Icons.tex(str(t["icon"]), 40)
		bt.add_theme_constant_override("icon_max_width", 18)
		bt.add_theme_font_size_override("font_size", 15)
		bt.custom_minimum_size = Vector2(0, 42)
		bt.add_theme_color_override("font_color", tc if on else UiTheme.TEXT)
		bt.add_theme_color_override("icon_normal_color", tc if on else Color(tc, 0.75))
		bt.add_theme_stylebox_override("normal", UiTheme.box(Color(tc.darkened(0.8), 0.95) if on else Color(UiTheme.BG, 0.85), Color(tc, 0.9) if on else Color(tc, 0.35), 20, 2 if on else 1, 8))
		bt.add_theme_stylebox_override("hover", UiTheme.box(Color(tc.darkened(0.75), 0.95), tc, 20, 2, 8))
		bt.add_theme_stylebox_override("pressed", UiTheme.box(Color(tc.darkened(0.7), 0.95), tc, 20, 2, 8))
		bt.pressed.connect(func() -> void:
			Snd.click()
			_disc = "" if _disc == did else did
			_rebuild.call_deferred())
		flow.add_child(bt)
	if _disc != "":
		var di := Profile.discipline_info(cls, _disc)
		if not di.is_empty():
			col.add_child(UiTheme.wrap(str(di.get("desc", "")), 15, Color(str(di["color"]))))
	for rank in Profile.SPELL_RANKS:
		var rids: Array[String] = []
		for id in ids:
			var sp: Dictionary = GameData.spells()[id]
			if str(sp.get("rank", "")) == rank and (_disc == "" or str(sp.get("disc", "")) == _disc):
				rids.append(id)
		if rids.is_empty():
			continue
		col.add_child(_rank_header(rank, rids, known))
		var g := _grid()
		col.add_child(g)
		for id in rids:
			if mine:
				_ctx[id] = {"known": known.has(id), "info_only": false, "how": ""}
				g.add_child(_tile(id, known.has(id), deck.has(id), false))
			else:
				var how := "Apprise : sert en suivant la voie %s." % _class_name(cls) if Profile.learned(id) else "Prix : %d or · voie %s requise" % [Profile.spell_price(id), _class_name(cls)]
				_ctx[id] = {"known": Profile.learned(id), "info_only": true, "how": how}
				g.add_child(_tile(id, Profile.learned(id), false, true))


# ---------------------------------------------------------------- tuiles

## Tuile d'un sort et son nom dessous.
func _tile(id: String, known: bool, in_deck: bool, info_only: bool) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(TILE, 0)
	var b := _spell_button(id, TILE, known, in_deck, false, info_only)
	v.add_child(b)
	_tiles[id] = b
	var sp: Dictionary = GameData.spells()[id]
	var nm := UiTheme.label(str(sp.get("name", id)), 14, Color(str(sp.get("color", "e8eef5"))) if known else UiTheme.MUTED)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(TILE, 0)
	nm.max_lines_visible = 2
	v.add_child(nm)
	return v


## Bouton-sort : cadre au rang, lueur à la couleur du sort, icône, et ses marques
## (dans le deck, prix à payer, niveau requis, mana).
func _spell_button(id: String, px: int, known: bool, in_deck: bool, deck_slot: bool, info_only: bool = false) -> Button:
	var sp: Dictionary = GameData.spells()[id]
	var scol := Color(str(sp.get("color", "6fdccf")))
	var rank := str(sp.get("rank", ""))
	var rc := Color(str((Profile.RANK_INFO.get(rank, {}) as Dictionary).get("color", "8a9bb0")))
	var block := "" if known or info_only else Profile.learn_block(id)
	var lvl_lock := block.begins_with("Niveau")
	var sel := id == _sel
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(px, px)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bg := Color(scol.darkened(0.86), 0.96)
	var bd := UiTheme.GOLD if sel else (UiTheme.TEAL if in_deck else Color(rc, 0.85 if known else 0.45))
	var acc := UiTheme.GOLD if sel else Color(0, 0, 0, 0)
	var w := 3 if sel or in_deck else 2
	b.add_theme_stylebox_override("normal", UiTheme.box(bg, bd, 12, w, 0, acc))
	b.add_theme_stylebox_override("hover", UiTheme.box(bg.lightened(0.05), UiTheme.GOLD if sel else scol, 12, w, 0, acc))
	b.add_theme_stylebox_override("pressed", UiTheme.box(bg.darkened(0.3), UiTheme.GOLD, 12, w, 0, acc))
	b.set_meta("sid", id)
	b.add_child(GearUi._glow(scol, 0.45 if known else 0.14))
	var ic := TextureRect.new()
	ic.texture = Icons.tex("lock" if lvl_lock else id, px * 2, 1.6)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := float(px) * 0.2
	ic.offset_left = m
	ic.offset_top = m
	ic.offset_right = -m
	ic.offset_bottom = -m
	ic.modulate = scol if known else (Color(UiTheme.MUTED, 0.7) if lvl_lock else Color(scol, 0.5))
	b.add_child(ic)
	if rank == "interdit":
		var fx := UiTheme.icon_rect("sparkle", 16, Color("d93cf2"))
		fx.position = Vector2(px - 21, 5)
		b.add_child(fx)
	if in_deck and not deck_slot:
		var ck := PanelContainer.new()
		ck.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ck.add_theme_stylebox_override("panel", UiTheme.box(Color("0a2a28"), UiTheme.TEAL, 10, 1, 2))
		ck.add_child(UiTheme.icon_rect("check", 14, UiTheme.TEAL))
		ck.position = Vector2(5, 5)
		b.add_child(ck)
	# Marque du bas : mana (sort connu), prix (à apprendre), niveau (verrouillé).
	var mark := ""
	var mc := UiTheme.CYAN
	if known:
		mark = "%d" % int(sp.get("mana", 0)) if int(sp.get("mana", 0)) > 0 else "ULT"
	elif not info_only:
		var l := Profile.learn_info(id)
		if lvl_lock:
			mark = "Niv. %d" % int(l.get("level", 0))
			mc = UiTheme.MUTED
		elif not l.is_empty():
			mark = "%d or" % int(l.get("gold", 0))
			mc = UiTheme.GOLD if block == "" else UiTheme.FIRE
	if mark != "":
		b.add_child(GearUi.corner(GearUi.pill(mark, mc, 13 if px < 90 else 14), 6))
	b.pressed.connect(func() -> void:
		Snd.click()
		_pick(id))
	return b


## Toucher un sort : il passe dans la fiche (sans reconstruire l'écran).
func _pick(id: String) -> void:
	if id == _sel:
		return
	var prev := _sel
	_sel = id
	for k in [prev, prev + "#deck", id, id + "#deck"]:
		if _tiles.has(k) and is_instance_valid(_tiles[k]):
			var old := _tiles[k] as Button
			var sid := str(k).trim_suffix("#deck")
			var slot := str(k).ends_with("#deck")
			var cx: Dictionary = _ctx.get(sid, {"known": true})
			var known := slot or bool(cx.get("known", true))
			var in_deck := not slot and Profile.deck().has(sid)
			var nb := _spell_button(sid, int(old.custom_minimum_size.x), known, in_deck, slot, not slot and bool(cx.get("info_only", false)))
			var parent := old.get_parent()
			var at := old.get_index()
			parent.remove_child(old)
			old.queue_free()
			parent.add_child(nb)
			parent.move_child(nb, at)
			_tiles[k] = nb
	_fill_sheet()


# ---------------------------------------------------------------- fiche du sort

func _fill_sheet() -> void:
	for ch in _sheet.get_children():
		ch.queue_free()
	if _sel == "" or not GameData.spells().has(_sel):
		return
	var id := _sel
	var sp: Dictionary = GameData.spells()[id]
	var known_all := Profile.known_spells()
	var deck := Profile.deck()
	var ctx: Dictionary = _ctx.get(id, {"known": known_all.has(id), "info_only": false, "how": ""})
	var known := bool(ctx.get("known", false)) or (deck.has(id))
	var info_only := bool(ctx.get("info_only", false)) and not deck.has(id)
	var scol := Color(str(sp.get("color", "6fdccf")))
	var rank := str(sp.get("rank", ""))
	var ri: Dictionary = Profile.RANK_INFO.get(rank, {})
	if _msg != "":
		_sheet.add_child(UiTheme.wrap(_msg, 15, _msg_col))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	_sheet.add_child(top)
	var big := _spell_button(id, 78, known, false, true, info_only)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(big)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	var nm := UiTheme.label(str(sp.get("name", id)), 24, scol)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(nm)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 4)
	info.add_child(chips)
	if not ri.is_empty():
		chips.add_child(GearUi.pill(str(ri["name"]), Color(str(ri["color"])), 14))
	if sp.has("school"):
		chips.add_child(GearUi.pill(str(Profile.SCHOOLS.get(str(sp["school"]), "")), scol, 14))
	elif sp.has("disc") and Profile.spell_class(id) != "":
		var di := Profile.discipline_info(Profile.spell_class(id), str(sp["disc"]))
		if not di.is_empty():
			chips.add_child(GearUi.pill(str(di.get("name", "")), Color(str(di.get("color", "f2c46b"))), 14))
	if int(sp.get("mana", 0)) == 0 and int(sp.get("cd", 0)) == 0:
		chips.add_child(GearUi.pill("Ultime", UiTheme.GOLD, 14))
	if deck.has(id):
		chips.add_child(GearUi.pill("Dans le deck", UiTheme.TEAL, 14))
	var hear := Button.new()
	hear.focus_mode = Control.FOCUS_NONE
	hear.icon = Icons.tex("sound", 40)
	hear.tooltip_text = "Écouter le sort"
	hear.add_theme_constant_override("icon_max_width", 22)
	hear.custom_minimum_size = Vector2(52, 52)
	hear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hear.add_theme_color_override("icon_normal_color", UiTheme.TEAL)
	hear.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.BG, 0.9), Color(UiTheme.TEAL, 0.5), 12, 1, 6))
	hear.add_theme_stylebox_override("hover", UiTheme.box(Color(UiTheme.BG, 0.9), UiTheme.TEAL, 12, 2, 6))
	hear.pressed.connect(func() -> void: SpellAudio.preview(id))
	top.add_child(hear)
	_sheet.add_child(_stats(id, sp))
	var desc := UiTheme.wrap(str(sp.get("desc", "")), 16, UiTheme.TEXT)
	desc.max_lines_visible = 3
	_sheet.add_child(desc)
	var how := str(ctx.get("how", ""))
	if how != "":
		_sheet.add_child(UiTheme.wrap(how, 14, UiTheme.TEAL))
	_sheet.add_child(_action(id, sp, known, info_only, deck))


## Stats du sort en pastilles : puissance, mana, recharge, zone, dégâts, durée.
func _stats(id: String, sp: Dictionary) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 6)
	f.add_theme_constant_override("v_separation", 4)
	var items: Array = []
	if sp.has("rank"):
		items.append(["Puissance", "%d" % Profile.spell_power(id), UiTheme.GOLD])
	if int(sp.get("mana", 0)) > 0:
		items.append(["Mana", "%d" % int(sp["mana"]), UiTheme.CYAN])
	if int(sp.get("cd", 0)) > 0:
		items.append(["Recharge", "%d s" % int(sp["cd"]), UiTheme.TEXT])
	if float(sp.get("radius", 0.0)) > 0.0:
		items.append(["Zone", "%s m" % _num(float(sp["radius"])), UiTheme.TEAL])
	if float(sp.get("damage", 0.0)) > 0.0:
		items.append(["Dégâts", "%d" % int(sp["damage"]), UiTheme.FIRE])
	if float(sp.get("dur", 0.0)) > 0.0:
		items.append(["Durée", "%s s" % _num(float(sp["dur"])), UiTheme.VIOLET])
	for it in items:
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", UiTheme.box(Color(0.03, 0.05, 0.08, 0.85), Color(it[2], 0.35), 8, 1, 6))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 5)
		pc.add_child(h)
		h.add_child(UiTheme.label(str(it[0]), 13, UiTheme.MUTED))
		h.add_child(UiTheme.label(str(it[1]), 16, it[2]))
		f.add_child(pc)
	return f


static func _num(x: float) -> String:
	return ("%d" % int(x)) if is_equal_approx(x, roundf(x)) else ("%.1f" % x).replace(".", ",")


## Bouton d'action de la fiche : ajouter / retirer du deck, ou apprendre ; sinon la raison.
func _action(id: String, sp: Dictionary, known: bool, info_only: bool, deck: Array[String]) -> Control:
	var forbidden := str(sp.get("rank", "")) == "interdit"
	if info_only:
		var l0 := UiTheme.wrap("Consultation seulement." if known else "Ce sort ne s'apprend pas ici.", 15, UiTheme.MUTED)
		return l0
	if known:
		var in_deck := deck.has(id)
		var t := UiTheme.button("RETIRER DU DECK" if in_deck else "AJOUTER AU DECK", 20)
		t.custom_minimum_size = Vector2(0, 56)
		t.icon = Icons.tex("back" if in_deck else "up", 40)
		t.add_theme_constant_override("icon_max_width", 20)
		var full := not in_deck and deck.size() >= Profile.DECK_MAX
		if not in_deck and not full:
			t.add_theme_color_override("font_color", UiTheme.GOLD)
			t.add_theme_color_override("icon_normal_color", UiTheme.GOLD)
			t.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.95), Color(UiTheme.GOLD, 0.9), 12, 2, 8, UiTheme.GOLD))
		if full:
			t.text = "DECK COMPLET · RETIRE D'ABORD UN SORT"
			t.add_theme_font_size_override("font_size", 16)
			t.disabled = true
		t.pressed.connect(func() -> void:
			var err := Profile.toggle_deck(id)
			if err != "":
				_say(err, UiTheme.FIRE)
			elif in_deck:
				_say("%s quitte le deck." % str(sp["name"]), UiTheme.MUTED)
			else:
				SpellAudio.preview(id)
				_say("%s rejoint le deck." % str(sp["name"]), UiTheme.TEAL)
			_save()
			_rebuild.call_deferred())
		return t
	var l := Profile.learn_info(id)
	if l.is_empty():
		return UiTheme.wrap(str(sp.get("source", "Ne s'apprend pas à la Bibliothèque.")), 15, UiTheme.MUTED)
	var block := Profile.learn_block(id)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var lb := UiTheme.button("APPRENDRE · %d or" % int(l.get("gold", 0)), 20)
	lb.custom_minimum_size = Vector2(0, 56)
	lb.icon = Icons.tex("book", 40)
	lb.add_theme_constant_override("icon_max_width", 20)
	lb.disabled = block != ""
	if block == "":
		var bc := Color("d93cf2") if forbidden else UiTheme.GOLD
		lb.add_theme_color_override("font_color", bc)
		lb.add_theme_color_override("icon_normal_color", bc)
		lb.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.95), Color(bc, 0.9), 12, 2, 8, bc))
	lb.pressed.connect(func() -> void:
		if Profile.learn(id):
			Snd.sfx("loot_rare", -6.0)
			SpellAudio.preview(id)
			var msg := "%s appris." % str(sp["name"])
			if int(l.get("corruption", 0)) > 0:
				msg += " La Corruption grandit (+%d)." % int(l["corruption"])
			_say(msg, UiTheme.GOLD)
			_save()
		_rebuild.call_deferred())
	v.add_child(lb)
	var req: Array[String] = []
	if block != "" and block != "Or insuffisant":
		req.append(block)
	if l.has("level") and not block.begins_with("Niveau"):
		req.append("Niveau %d requis" % int(l["level"]))
	if block == "Or insuffisant":
		req.append("Il te manque %d or" % (int(l.get("gold", 0)) - Profile.gold()))
	if int(l.get("corruption", 0)) > 0:
		req.append("Corruption +%d" % int(l["corruption"]))
	if sp.has("source"):
		req.append("Aussi offert par l'arbre de compétences")
	if not req.is_empty():
		var rl := UiTheme.label(" · ".join(req), 14, UiTheme.MUTED if block != "" else UiTheme.GOOD)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(rl)
	return v


func _say(text: String, c: Color) -> void:
	_msg = text
	_msg_col = c


func _save() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()


# ---------------------------------------------------------------- médaillon d'école ou de classe

class Sigil extends Button:
	var glyph: Texture2D
	var col := Color.WHITE
	var on := false
	var mine := false
	var frac := -1.0 ## part des sorts appris (-1 : pas de jauge)
	var text_under := ""
	var d := 72.0

	func setup(diam: float) -> void:
		d = diam
		custom_minimum_size = Vector2(diam, diam + 24.0)
		focus_mode = Control.FOCUS_NONE
		for s in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(s, StyleBoxEmpty.new())
		pressed.connect(Snd.click)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, d * 0.5)
		var r := d * 0.5 - 4.0
		var hov := is_hovered()
		draw_circle(c + Vector2(0, 4), r, Color(0, 0, 0, 0.4))
		if on:
			draw_circle(c, r + 5.0, Color(col, 0.18))
		draw_circle(c, r, Color(col.darkened(0.82), 0.97) if on else Color(0.05, 0.07, 0.1, 0.92))
		draw_circle(c + Vector2(0, -r * 0.25), r * 0.7, Color(col, 0.10 if on else 0.04))
		draw_arc(c, r, 0.0, TAU, 64, col if on else Color(col, 0.55 if hov else 0.35), 3.0 if on else 2.0, true)
		if frac >= 0.0 and frac > 0.0:
			draw_arc(c, r + 3.5, -PI * 0.5, -PI * 0.5 + TAU * minf(frac, 1.0), 48, Color(UiTheme.GOLD, 0.9), 2.5, true)
		if glyph != null:
			var ic := r * 1.05
			draw_texture_rect(glyph, Rect2(c - Vector2(ic, ic) * 0.5, Vector2(ic, ic)), false, col if on or hov else Color(col, 0.7))
		if mine:
			draw_circle(c + Vector2(r * 0.72, -r * 0.72), 6.0, UiTheme.TEAL)
			draw_arc(c + Vector2(r * 0.72, -r * 0.72), 6.0, 0.0, TAU, 16, Color(0, 0, 0, 0.6), 1.5, true)
		var font := get_theme_default_font()
		var fs := 14 if text_under.length() < 9 else 12
		draw_string(font, Vector2(0, d + 18.0), text_under, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, col if on else UiTheme.TEXT)
