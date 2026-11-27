class_name MeditationScreen
extends Control
## Salle de méditation (Sœur Aelis, Ordre de l'Aube ; docs/design/27-meditation-compagnons.md et
## docs/design/14-interface.md). Ouverte à la fin de l'acte 1. Trois onglets :
## - VOIES : un mandala, le héros au centre et les 7 voies en cercle ; toucher une voie montre sa fiche
##   (Ultime, disciplines, points placés dans son arbre), puis « Emprunter cette voie » ; plus bas, la voie
##   de chaque compagnon ;
## - CONFIGURATIONS : 3 sceaux (voie, arbre, deck) à enregistrer et recharger sans frais ;
## - HARMONIE : la Corruption sur une jauge circulaire, méditer pour l'apaiser, et réinitialiser l'arbre.

signal back

const AELIS := Color("f2e2b8")
const CORRUPT := Color("d93cf2")
const TABS := [["voies", "VOIES", "target", "Héros et compagnons"], ["configs", "CONFIGURATIONS", "book", "3 sceaux"],
	["harmonie", "HARMONIE", "moon", "Corruption, arbre"]]
const ROMAN := ["I", "II", "III", "IV", "V"]
const SHORT := {"mage": "Mage", "archer": "Archer", "epeiste": "Épéiste", "clerc": "Clerc", "necromancien": "Nécro",
	"chevalier": "Chevalier", "berserker": "Berserker"}

var _msg := ""
var _reset_armed := false
var _tab := "voies"
var _pick := "" ## voie montrée dans la fiche (par défaut : la voie actuelle)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.5, 0.0, "moon", "meditation")
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	if _pick == "":
		_pick = Profile.player_class()
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 14)
	var head := HBoxContainer.new()
	col.add_child(head)
	var b := UiTheme.back_button("Havre-Aube")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	head.add_child(GearUi.purse())
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("SALLE DE MÉDITATION", 42, UiTheme.GOLD))
	tv.add_child(UiTheme.title("LE SANCTUAIRE DE SŒUR AELIS", 20, UiTheme.TEXT))
	col.add_child(GearUi.speaker_banner("aelis", "Sœur Aelis", "Ordre de l'Aube", _msg if _msg != "" else _line(), UiTheme.GOLD if _msg != "" else UiTheme.TEXT, AELIS))
	col.add_child(_tabs())
	match _tab:
		"configs":
			_configs(col)
		"harmonie":
			_harmony(col)
		_:
			_paths(col)


## Ce que dit Sœur Aelis, selon l'onglet.
func _line() -> String:
	match _tab:
		"configs":
			return "Grave dans la mémoire du Sceau les voies qui te réussissent. Tu les retrouveras d'un souffle."
		"harmonie":
			if Story.value("corruption") >= 30:
				return "Je sens la Cendre sur toi. Assieds-toi ; nous allons la laisser retomber."
			return "Le silence aussi est un sort. Il défait ce que la magie interdite a noué."
	return "Respire, Porteur. Le Sceau d'Écho ne t'enchaîne à aucune voie : il te laisse les emprunter toutes."


func _tabs() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for t in TABS:
		var id := str(t[0])
		var on := id == _tab
		var rb: Array = UiTheme.rich_button(70, "primary" if on else "tile")
		var bt: Button = rb[0]
		var h: HBoxContainer = rb[1]
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 8)
		h.add_child(UiTheme.icon_rect(str(t[2]), 24, AELIS if on else UiTheme.MUTED))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(v)
		v.add_child(UiTheme.label(str(t[1]), 17, UiTheme.GOLD if on else UiTheme.TEXT))
		v.add_child(UiTheme.label(str(t[3]), 13, UiTheme.MUTED))
		bt.pressed.connect(func() -> void:
			Snd.click()
			_tab = id
			_msg = ""
			_reset_armed = false
			_rebuild.call_deferred())
		row.add_child(bt)
	return row


func _class_name(cid: String) -> String:
	return str((GameData.party()["classes"] as Dictionary).get(cid, {}).get("name", cid))


func _class_col(cid: String) -> Color:
	return Color(str(LibraryScreen.CLASS_COL.get(cid, "f2c46b")))


## Points placés dans l'arbre d'une classe (chaque classe garde le sien).
static func _spent_in(cid: String) -> int:
	var sk: Dictionary = Profile.data.get("skills", {}) if Profile.data.get("skills") is Dictionary else {}
	var ranks: Dictionary = sk.get(cid, {}) if sk.get(cid) is Dictionary else {}
	var n := 0
	for k in ranks.keys():
		n += int(ranks[k])
	return n


func _playable() -> Array[String]:
	var out: Array[String] = []
	var classes: Dictionary = GameData.party()["classes"]
	for cid in classes.keys():
		if bool((classes[cid] as Dictionary).get("playable", false)):
			out.append(str(cid))
	return out


# ---------------------------------------------------------------- voies

func _paths(col: VBoxContainer) -> void:
	var w := minf(680.0, get_viewport_rect().size.x - 36.0)
	var m := Mandala.new()
	m.custom_minimum_size = Vector2(w, 530)
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	m.anim = Profile.ambience_on()
	col.add_child(m)
	var ids := _playable()
	var center := Vector2(w * 0.5, 262.0)
	m.center = center
	m.radius = 200.0
	m.count = ids.size()
	# Le héros au centre, dans sa voie actuelle.
	SpriteAtlas.set_player(Profile.look(), Profile.race(), Profile.player_class())
	var hero := GearUi.figure("player", 150)
	m.add_child(hero)
	hero.size = hero.custom_minimum_size
	hero.position = center - Vector2(hero.size.x * 0.5, hero.size.y * 0.62)
	for i in range(ids.size()):
		var cid := ids[i]
		var cd: Dictionary = GameData.party()["classes"][cid]
		var s := LibraryScreen.Sigil.new()
		s.glyph = Icons.tex(str(cd.get("ultimate", "target")), 96, 1.6)
		s.col = _class_col(cid)
		s.on = cid == _pick
		s.mine = cid == Profile.player_class()
		s.text_under = _class_name(cid)
		s.setup(78.0)
		s.size = s.custom_minimum_size
		var a := -PI * 0.5 + float(i) * TAU / float(ids.size())
		var p := center + Vector2.from_angle(a) * m.radius
		s.position = p - Vector2(39, 39)
		if cid == _pick:
			m.picked = i
		s.pressed.connect(func() -> void:
			if _pick == cid:
				return
			_pick = cid
			_msg = ""
			_rebuild.call_deferred())
		m.add_child(s)
	col.add_child(_class_card(_pick))
	var comps := Profile.companions_available()
	if not comps.is_empty():
		col.add_child(UiTheme.section("Voies des compagnons", AELIS))
		col.add_child(UiTheme.wrap("Un compagnon garde sa race mais peut changer de classe : son invocation, ses stats et les sorts proposés au Cercle suivent sa nouvelle voie.", 15, UiTheme.MUTED))
		for who in comps:
			col.add_child(_companion_card(who))


## Fiche d'une voie : son champion, sa description, son Ultime, ses disciplines et l'arbre déjà investi.
func _class_card(cid: String) -> PanelContainer:
	var cd: Dictionary = GameData.party()["classes"].get(cid, {})
	var cc := _class_col(cid)
	var mine := cid == Profile.player_class()
	var c: Array = UiTheme.card(Color(cc, 0.6), 14)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 10)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(120, 132)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(stage)
	stage.add_child(GearUi.pedestal(cc, 120, 132))
	# Le héros tel qu'il serait dans cette voie (tenue et arme de la classe).
	SpriteAtlas.set_player(Profile.look(), Profile.race(), cid)
	var fig := GearUi.figure("player", 118)
	SpriteAtlas.set_player(Profile.look(), Profile.race(), Profile.player_class())
	stage.add_child(fig)
	fig.size = fig.custom_minimum_size
	fig.position = Vector2((120.0 - fig.size.x) * 0.5, 6.0)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiTheme.label("TA VOIE ACTUELLE" if mine else "VOIE", 14, UiTheme.TEAL if mine else UiTheme.MUTED))
	info.add_child(UiTheme.title(_class_name(cid).to_upper(), 30, cc))
	info.add_child(UiTheme.wrap(str(cd.get("desc", "")), 16, UiTheme.TEXT))
	var spent := _spent_in(cid)
	info.add_child(UiTheme.label("%d point%s placé%s dans son arbre" % [spent, "s" if spent > 1 else "", "s" if spent > 1 else ""] if spent > 0 else "Arbre encore vierge", 15, UiTheme.GOLD if spent > 0 else UiTheme.MUTED))
	# Ultime.
	var ult := str(cd.get("ultimate", ""))
	var usp: Dictionary = GameData.spells().get(ult, {})
	if not usp.is_empty():
		var ur := HBoxContainer.new()
		ur.add_theme_constant_override("separation", 10)
		v.add_child(ur)
		var ub := PanelContainer.new()
		ub.custom_minimum_size = Vector2(54, 54)
		ub.add_theme_stylebox_override("panel", UiTheme.box(Color(Color(str(usp.get("color", "f2c46b"))).darkened(0.82), 0.95), Color(UiTheme.GOLD, 0.8), 27, 2, 6))
		ub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ub.add_child(UiTheme.icon_rect(ult, 30, Color(str(usp.get("color", "f2c46b")))))
		ur.add_child(ub)
		var uv := VBoxContainer.new()
		uv.add_theme_constant_override("separation", 0)
		uv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ur.add_child(uv)
		uv.add_child(UiTheme.label("ULTIME · %s" % str(usp.get("name", "")), 17, UiTheme.GOLD))
		var ud := UiTheme.wrap(str(usp.get("desc", "")), 14, UiTheme.MUTED)
		ud.max_lines_visible = 2
		uv.add_child(ud)
	# Disciplines du grimoire.
	var discs: Array = cd.get("disciplines", [])
	if not discs.is_empty():
		var f := HFlowContainer.new()
		f.add_theme_constant_override("h_separation", 6)
		f.add_theme_constant_override("v_separation", 6)
		v.add_child(f)
		for d in discs:
			var dc := Color(str((d as Dictionary).get("color", "f2c46b")))
			var pc := PanelContainer.new()
			pc.add_theme_stylebox_override("panel", UiTheme.box(Color(dc.darkened(0.82), 0.9), Color(dc, 0.5), 14, 1, 6))
			var dh := HBoxContainer.new()
			dh.add_theme_constant_override("separation", 4)
			pc.add_child(dh)
			dh.add_child(UiTheme.icon_rect(str((d as Dictionary).get("icon", "book")), 16, dc))
			dh.add_child(UiTheme.label(str((d as Dictionary).get("name", "")), 14, dc))
			f.add_child(pc)
	if mine:
		var l := UiTheme.label("Chaque voie garde son propre arbre : changer ne coûte rien.", 15, UiTheme.MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		return c[0]
	var go := UiTheme.button("EMPRUNTER CETTE VOIE", 21)
	go.icon = Icons.tex("target", 40)
	go.add_theme_constant_override("icon_max_width", 22)
	go.custom_minimum_size = Vector2(0, 58)
	go.add_theme_color_override("font_color", UiTheme.GOLD)
	go.add_theme_color_override("icon_normal_color", UiTheme.GOLD)
	go.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.95), Color(UiTheme.GOLD, 0.9), 12, 2, 8, UiTheme.GOLD))
	go.disabled = not Profile.meditation_unlocked()
	go.pressed.connect(func() -> void:
		var before := _class_name(Profile.player_class())
		if Profile.change_class(cid):
			Snd.sfx("level_up", -6.0)
			_msg = "Tu suis désormais la voie : %s. Ton arbre de %s est conservé." % [_class_name(cid), before]
			_save()
		_rebuild.call_deferred())
	v.add_child(go)
	return c[0]


## Voie d'un compagnon : son portrait, sa voie, et les 7 voies en petits médaillons.
func _companion_card(who: String) -> PanelContainer:
	var col := Dialogues.color(who)
	var cur := Profile.companion_class(who)
	var c: Array = UiTheme.card(Color(col, 0.5), 12)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 8)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var fr := PanelContainer.new()
	fr.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), Color(col, 0.8), 10, 2, 3))
	fr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(fr)
	var pic := TextureRect.new()
	pic.texture = PortraitArt.texture(who, "neutre")
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.custom_minimum_size = Vector2(60, 60)
	fr.add_child(pic)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	tv.add_child(UiTheme.title(Dialogues.display_name(who).to_upper(), 24, col))
	tv.add_child(UiTheme.label("Voie : %s" % _class_name(cur), 16, _class_col(cur)))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	for cid in _playable():
		var cd: Dictionary = GameData.party()["classes"][cid]
		var s := LibraryScreen.Sigil.new()
		s.glyph = Icons.tex(str(cd.get("ultimate", "target")), 96, 1.6)
		s.col = _class_col(cid)
		s.on = cid == cur
		s.text_under = str(SHORT.get(cid, _class_name(cid)))
		s.setup(62.0)
		s.custom_minimum_size.x = 82.0
		s.pressed.connect(func() -> void:
			if cid == Profile.companion_class(who):
				return
			if Profile.set_companion_class(who, cid):
				_msg = "%s suit désormais la voie : %s." % [Dialogues.display_name(who), _class_name(cid)]
				_save()
			_rebuild.call_deferred())
		row.add_child(s)
	return c[0]


# ---------------------------------------------------------------- configurations

func _configs(col: VBoxContainer) -> void:
	col.add_child(UiTheme.wrap("Un sceau garde ta voie, ton arbre et ton deck ; le recharger est gratuit et immédiat.", 16, UiTheme.MUTED))
	for i in range(Profile.CONFIG_SLOTS):
		col.add_child(_seal(i))


func _seal(i: int) -> PanelContainer:
	var cfg: Dictionary = Profile.configs()[i]
	var empty := cfg.is_empty()
	var cid := str(cfg.get("class", ""))
	var cc := _class_col(cid) if not empty else Color(UiTheme.MUTED, 0.6)
	var c: Array = UiTheme.card(Color(cc, 0.55) if not empty else Color(UiTheme.BORDER, 0.7), 14)
	var v: VBoxContainer = c[1]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	# Le sceau : un médaillon à l'emblème de la voie enregistrée.
	var s := LibraryScreen.Sigil.new()
	var cd: Dictionary = GameData.party()["classes"].get(cid, {})
	s.glyph = Icons.tex(str(cd.get("ultimate", "lock")) if not empty else "rune", 96, 1.6)
	s.col = cc if not empty else UiTheme.MUTED
	s.on = not empty
	s.text_under = "SCEAU %s" % ROMAN[i]
	s.setup(76.0)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(s)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	if empty:
		info.add_child(UiTheme.title("EMPLACEMENT LIBRE", 22, UiTheme.MUTED))
		info.add_child(UiTheme.wrap("Grave ici ta voie actuelle (%s), ton arbre et ton deck." % _class_name(Profile.player_class()), 15, UiTheme.MUTED))
	else:
		info.add_child(UiTheme.title(_class_name(cid).to_upper(), 24, cc))
		var deck: Array = cfg.get("deck", [])
		var mode := str(cfg.get("mode", "deck"))
		info.add_child(UiTheme.label("%d points dans l'arbre · %s" % [int(cfg.get("points", 0)), "Deck de %d sorts" % deck.size() if mode == "deck" else "Mode Tiroir"], 15, UiTheme.TEXT))
		if mode == "deck" and not deck.is_empty():
			var dr := HBoxContainer.new()
			dr.add_theme_constant_override("separation", 4)
			info.add_child(dr)
			for sid in deck:
				var sp: Dictionary = GameData.spells().get(str(sid), {})
				var chip := PanelContainer.new()
				chip.add_theme_stylebox_override("panel", UiTheme.box(Color(Color(str(sp.get("color", "6fdccf"))).darkened(0.85), 0.95), Color(str(sp.get("color", "6fdccf")), 0.6), 8, 1, 3))
				chip.add_child(UiTheme.icon_rect(str(sid), 22, Color(str(sp.get("color", "6fdccf")))))
				dr.add_child(chip)
		var keys: Array = cfg.get("keys", [])
		if not keys.is_empty():
			var kf := HFlowContainer.new()
			kf.add_theme_constant_override("h_separation", 4)
			kf.add_theme_constant_override("v_separation", 4)
			info.add_child(kf)
			for k in keys:
				kf.add_child(GearUi.pill(str(k), UiTheme.GOLD, 13))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	if not empty:
		var ld := UiTheme.button("CHARGER", 19)
		ld.icon = Icons.tex("up", 40)
		ld.add_theme_constant_override("icon_max_width", 20)
		ld.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ld.custom_minimum_size = Vector2(0, 54)
		ld.add_theme_color_override("font_color", UiTheme.GOLD)
		ld.add_theme_color_override("icon_normal_color", UiTheme.GOLD)
		ld.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.95), Color(UiTheme.GOLD, 0.9), 12, 2, 8, UiTheme.GOLD))
		ld.pressed.connect(func() -> void:
			var err := Profile.load_config(i)
			_msg = err if err != "" else "Sceau %s rechargé : voie %s." % [ROMAN[i], _class_name(Profile.player_class())]
			if err == "":
				Snd.sfx("level_up", -8.0)
				_pick = Profile.player_class()
				_save()
			_rebuild.call_deferred())
		row.add_child(ld)
	var sv := UiTheme.button("ENREGISTRER ICI" if empty else "REMPLACER", 17)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.custom_minimum_size = Vector2(0, 54)
	sv.pressed.connect(func() -> void:
		Profile.save_config(i)
		Snd.sfx("ui_confirm", -6.0)
		_msg = "Sceau %s gravé : %s." % [ROMAN[i], _class_name(Profile.player_class())]
		_save()
		_rebuild.call_deferred())
	row.add_child(sv)
	return c[0]


# ---------------------------------------------------------------- harmonie

func _harmony(col: VBoxContainer) -> void:
	var cor := Story.value("corruption")
	var c: Array = UiTheme.card(Color(CORRUPT, 0.5) if cor > 0 else Color(AELIS, 0.4), 14)
	col.add_child(c[0])
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 10)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	v.add_child(h)
	var g := Gauge.new()
	g.value = float(cor) / 100.0
	g.number = cor
	g.custom_minimum_size = Vector2(170, 170)
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(g)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiTheme.title("CORRUPTION", 26, CORRUPT if cor > 0 else AELIS))
	var state := "Ton âme est en paix." if cor <= 0 else ("La Cendre te gagne." if cor >= 60 else ("Une ombre te suit." if cor >= 30 else "Un voile léger."))
	info.add_child(UiTheme.label(state, 17, UiTheme.TEXT))
	info.add_child(UiTheme.wrap("La magie interdite nourrit la Corruption, qui pousse ton histoire vers la voie des Cendres. Méditer l'apaise de 5.", 15, UiTheme.MUTED))
	var hcost := Profile.harmony_cost()
	var hb := UiTheme.button("MÉDITER · %d or · Corruption −5" % hcost if cor > 0 else "RIEN À APAISER", 19)
	hb.icon = Icons.tex("moon", 40)
	hb.add_theme_constant_override("icon_max_width", 20)
	hb.custom_minimum_size = Vector2(0, 58)
	hb.disabled = cor <= 0 or Profile.gold() < hcost
	if not hb.disabled:
		hb.add_theme_color_override("font_color", AELIS)
		hb.add_theme_color_override("icon_normal_color", AELIS)
		hb.add_theme_stylebox_override("normal", UiTheme.box(Color(CORRUPT.darkened(0.85), 0.95), Color(AELIS, 0.8), 12, 2, 8, AELIS))
	hb.pressed.connect(func() -> void:
		var n := Profile.harmony()
		if n > 0:
			Snd.sfx("ui_confirm", -4.0, 0.8)
			_msg = "Le souffle s'apaise. Corruption −%d." % n
			_save()
		_rebuild.call_deferred())
	v.add_child(hb)
	if cor > 0 and Profile.gold() < hcost:
		var poor := UiTheme.label("Il te manque %d or." % (hcost - Profile.gold()), 15, UiTheme.FIRE)
		poor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(poor)
	# Réinitialisation de l'arbre.
	var cost := Profile.reset_cost()
	var spent := Profile.skill_points_spent()
	var rc: Array = UiTheme.card(Color(UiTheme.DANGER, 0.45) if _reset_armed else UiTheme.BORDER, 14)
	col.add_child(rc[0])
	var rv: VBoxContainer = rc[1]
	rv.add_theme_constant_override("separation", 8)
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 12)
	rv.add_child(rh)
	rh.add_child(UiTheme.icon_rect("wrench", 30, UiTheme.DANGER if _reset_armed else UiTheme.MUTED))
	var ri := VBoxContainer.new()
	ri.add_theme_constant_override("separation", 0)
	ri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rh.add_child(ri)
	ri.add_child(UiTheme.label("RÉINITIALISER L'ARBRE", 19, UiTheme.TEXT))
	ri.add_child(UiTheme.label("%s · %d / %d points placés · %s" % [_class_name(Profile.player_class()), spent, Profile.skill_points_total(), "gratuit" if cost == 0 else "%d or" % cost], 15, UiTheme.MUTED))
	var rs := UiTheme.button("CONFIRMER : TOUT EFFACER" if _reset_armed else "RÉINITIALISER", 18)
	rs.custom_minimum_size = Vector2(0, 52)
	rs.disabled = Profile.gold() < cost or spent == 0
	if _reset_armed:
		rs.add_theme_color_override("font_color", UiTheme.DANGER)
		rs.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.DANGER.darkened(0.85), 0.95), UiTheme.DANGER, 12, 2, 8))
	rs.pressed.connect(func() -> void:
		if not _reset_armed:
			_reset_armed = true
		elif Profile.reset_skills():
			_reset_armed = false
			_msg = "Ton arbre est vierge : %d points à replacer." % Profile.skill_points_free()
			_save()
		_rebuild.call_deferred())
	rv.add_child(rs)
	if _reset_armed:
		var warn := UiTheme.label("Touche encore pour confirmer. Les autres voies gardent leur arbre.", 14, UiTheme.DANGER)
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rv.add_child(warn)


func _save() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()


# ---------------------------------------------------------------- dessins

## Mandala des voies : cercles de runes, rayons vers chaque voie (plus vif vers la voie choisie), et une
## couronne de traits qui tourne lentement (ambiance enrichie).
class Mandala extends Control:
	var center := Vector2.ZERO
	var radius := 200.0
	var count := 7
	var picked := -1
	var anim := true
	var _t := 0.0

	func _ready() -> void:
		set_process(anim)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := center
		var gold := Color("f2e2b8")
		for k in range(5):
			draw_circle(c, 120.0 - float(k) * 18.0, Color(0.95, 0.88, 0.7, 0.025 + 0.012 * float(k)))
		draw_arc(c, radius + 46.0, 0.0, TAU, 128, Color(gold, 0.18), 2.0, true)
		draw_arc(c, radius, 0.0, TAU, 128, Color(gold, 0.12), 1.5, true)
		draw_arc(c, 92.0, 0.0, TAU, 96, Color(gold, 0.22), 2.0, true)
		var rot := _t * 0.08
		for i in range(48):
			var a := rot + float(i) / 48.0 * TAU
			var r0 := radius + 38.0
			var r1 := radius + (46.0 if i % 4 == 0 else 42.0)
			draw_line(c + Vector2.from_angle(a) * r0, c + Vector2.from_angle(a) * r1, Color(gold, 0.3), 1.5)
		for i in range(count):
			var a2 := -PI * 0.5 + float(i) * TAU / float(maxi(count, 1))
			var on := i == picked
			draw_line(c + Vector2.from_angle(a2) * 96.0, c + Vector2.from_angle(a2) * (radius - 42.0), Color(gold, 0.55 if on else 0.12), 3.0 if on else 1.5, true)
		# Étoile à 7 branches qui relie les voies.
		var pts := PackedVector2Array()
		for i in range(count + 1):
			var k2 := (i * 3) % maxi(count, 1)
			pts.append(c + Vector2.from_angle(-PI * 0.5 + float(k2) * TAU / float(maxi(count, 1))) * (radius - 44.0))
		draw_polyline(pts, Color(gold, 0.07), 1.5, true)


## Jauge circulaire de la Corruption.
class Gauge extends Control:
	var value := 0.0
	var number := 0

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 10.0
		var col := Color("d93cf2")
		draw_circle(c, r + 6.0, Color(0, 0, 0, 0.35))
		draw_arc(c, r, 0.0, TAU, 96, Color(1, 1, 1, 0.08), 12.0, true)
		if value > 0.0:
			draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * clampf(value, 0.0, 1.0), 96, col, 12.0, true)
			draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * clampf(value, 0.0, 1.0), 96, Color(col, 0.25), 22.0, true)
		for k in [0.3, 0.6]:
			var a := -PI * 0.5 + TAU * float(k)
			draw_line(c + Vector2.from_angle(a) * (r - 9.0), c + Vector2.from_angle(a) * (r + 9.0), Color(1, 1, 1, 0.35), 2.0)
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, c.y + 14.0), "%d" % number, HORIZONTAL_ALIGNMENT_CENTER, size.x, 44, col if number > 0 else Color("f2e2b8"))
		draw_string(font, Vector2(0, c.y + 40.0), "/ 100", HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color("8fa3b3"))
