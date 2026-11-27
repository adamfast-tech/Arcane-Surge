class_name HubScreen
extends Control
## Havre-Aube (concept UI) : profil et monnaies, « Continuer », carte et équipement, salles à
## venir, état de la sauvegarde et du compte.

signal open_map
signal open_equipment
signal open_forge
signal open_armory
signal open_quests
signal open_tower
signal open_login
signal open_save
signal open_skills
signal open_library
signal open_circle
signal open_meditation
signal play_level(level_id: String)
signal open_mirror
signal open_options

var _status_icon: TextureRect
var _status_label: Label
var _account_label: Label
var _account_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.28, 0.94, "havre")
	Profile.check_achievements()
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 16)
	col.add_child(_profile_card())
	# Options (clé à molette) : Deck ou Tiroir, écoles élémentaires, difficulté.
	var orow := HBoxContainer.new()
	col.add_child(orow)
	orow.add_child(UiTheme.spacer())
	var opt := UiTheme.button(Profile.difficulty_info()["name"], 16)
	opt.icon = Icons.tex("wrench", 48)
	opt.add_theme_constant_override("icon_max_width", 24)
	opt.add_theme_color_override("icon_normal_color", UiTheme.GOLD)
	opt.add_theme_color_override("font_color", Color(str(Profile.difficulty_info()["color"])))
	opt.tooltip_text = "Options : Deck ou Tiroir, grimoires, difficulté"
	opt.custom_minimum_size = Vector2(0, 48)
	opt.pressed.connect(func() -> void: open_options.emit())
	orow.add_child(opt)
	var title := UiTheme.title("HAVRE-AUBE", 54, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.08))
	title.add_theme_constant_override("outline_size", 8)
	col.add_child(title)
	var phase_txt := ""
	if Profile.ambience_on():
		# Havre-Aube suit l'heure réelle.
		phase_txt = str({"aube": " · à l'aube", "jour": " · en plein jour", "crepuscule": " · au crépuscule", "nuit": " · à la nuit tombée"}.get(Ambience.havre_phase(), ""))
	var sub := UiTheme.label("Refuge des Canalisateurs" + phase_txt, 22, UiTheme.TEXT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.08))
	sub.add_theme_constant_override("outline_size", 6)
	col.add_child(sub)
	# La place du village : le héros s'y promène, les marchands attendent devant leur boutique.
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.box(Color(0, 0, 0, 0.35), Color(UiTheme.GOLD, 0.45), 14, 2, 4))
	col.add_child(frame)
	var place := HavrePlace.new()
	place.open.connect(_open_room)
	frame.add_child(place)
	var hint := UiTheme.label("Touche la rue pour te promener, un lieu pour y entrer", 14, Color(UiTheme.MUTED, 0.9))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)
	col.add_child(_continue_button())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	col.add_child(grid)
	var index := GameData.level_index()
	var total := (index["levels"] as Array).size() * 3
	var zid := int(GameData.level(Profile.next_level()).get("zone", 1))
	var zname := ""
	for z in index.get("zones", []):
		if int(z["id"]) == zid:
			zname = str(z["name"])
	grid.add_child(_tile("map", "CARTE DU MONDE", zname, "Zone %d · %d / %d étoiles" % [zid, Profile.stars_total(), total], func() -> void: open_map.emit(), UiTheme.TEAL))
	grid.add_child(_tile("baton_chene", "ÉQUIPEMENT", "Équipement et runes", _gear_line(), func() -> void: open_equipment.emit(), UiTheme.FIRE))
	# Salles : Entraînement (arbre), Bibliothèque (deck), Cercle (compagnons), Méditation (voies, Harmonie).
	var rooms := GridContainer.new()
	rooms.columns = 2
	rooms.add_theme_constant_override("h_separation", 10)
	rooms.add_theme_constant_override("v_separation", 10)
	col.add_child(rooms)
	var free := Profile.skill_points_free()
	rooms.add_child(_small_tile("forge", "FORGE", "%d rune%s · fusions" % [Profile.rune_inventory().size(), "s" if Profile.rune_inventory().size() > 1 else ""], UiTheme.FIRE, func() -> void: open_forge.emit(), UiTheme.FIRE))
	# Armurerie : la vitrine si elle vaut le détour, sinon le prochain arrivage.
	var offers := Profile.shop_offers()
	var show: Dictionary = offers[0] if not offers.is_empty() else {}
	var srar := str((show.get("item", {}) as Dictionary).get("rarity", ""))
	var shop_line := "Arrivage dans %d h %02d" % [Profile.shop_seconds_left() / 3600, (Profile.shop_seconds_left() % 3600) / 60]
	var shop_col := UiTheme.MUTED
	if not bool(show.get("sold", true)) and srar in ["epique", "legendaire", "mythique"]:
		shop_line = "Vitrine : %s !" % str(Profile.items_db()["rarities"][srar]["name"])
		shop_col = Color(str(Profile.items_db()["rarities"][srar]["color"]))
	rooms.add_child(_small_tile("coin", "ARMURERIE", shop_line, shop_col, func() -> void: open_armory.emit(), Color("e0a050")))
	# Défis du jour et de la semaine, hauts faits.
	var ready := Profile.quests_claimable()
	var qs := Profile.quests()
	var dn := 0
	for e in qs["daily"]:
		if Profile.quest_done(e):
			dn += 1
	rooms.add_child(_small_tile("star", "DÉFIS", ("%d à réclamer !" % ready) if ready > 0 else "Aujourd'hui %d / %d" % [dn, (qs["daily"] as Array).size()],
		UiTheme.GOLD if ready > 0 else UiTheme.MUTED, func() -> void: open_quests.emit(), Color("8fd8ff")))
	# Tour des Échos : ascension sans fin (après l'acte 1).
	var tw_open := Profile.tower_unlocked()
	var tw := _small_tile("tower", "TOUR DES ÉCHOS", ("Record : étage %d" % Profile.tower_best()) if tw_open and Profile.tower_best() > 0 else ("Ascension sans fin" if tw_open else "Fin de l'acte 1"),
		UiTheme.TEAL if tw_open else UiTheme.MUTED, func() -> void: open_tower.emit(), Color("b07cff"))
	tw.disabled = not tw_open
	if not tw_open:
		tw.modulate = Color(1, 1, 1, 0.6)
	rooms.add_child(tw)
	rooms.add_child(_small_tile("target", "ENTRAÎNEMENT", "%d point%s" % [free, "s" if free > 1 else ""], UiTheme.GOLD if free > 0 else UiTheme.MUTED, func() -> void: open_skills.emit(), UiTheme.GOLD))
	rooms.add_child(_small_tile("book", "BIBLIOTHÈQUE", "Deck %d / %d" % [Profile.deck().size(), Profile.DECK_MAX], UiTheme.MUTED, func() -> void: open_library.emit(), UiTheme.VIOLET))
	var crew: Array[String] = []
	for who in Profile.active_companions():
		crew.append("%s niv. %d" % [Dialogues.display_name(who), Profile.companion_level(who)])
	rooms.add_child(_small_tile("circle", "LE CERCLE", " · ".join(crew), UiTheme.MUTED, func() -> void: open_circle.emit(), UiTheme.GOOD))
	var med_open := Profile.meditation_unlocked()
	var cor := Story.value("corruption")
	var med := _small_tile("moon", "MÉDITATION", ("Voies · Corruption %d" % cor if cor > 0 else "Voies · configurations") if med_open else "Fin de l'acte 1",
		Color("D93CF2") if med_open and cor > 0 else UiTheme.MUTED, func() -> void: open_meditation.emit(), Color("d8c0ff"))
	med.disabled = not med_open
	if not med_open:
		med.modulate = Color(1, 1, 1, 0.6)
	rooms.add_child(med)
	col.add_child(UiTheme.section("Prochainement"))
	var soon := GridContainer.new()
	soon.columns = 2
	soon.add_theme_constant_override("h_separation", 14)
	soon.add_theme_constant_override("v_separation", 10)
	col.add_child(soon)
	var thread := "Fils du destin"
	match Story.choice("z01_l10"):
		"A":
			thread = "Fil : Sylvarche purifiée"
		"B":
			thread = "Fil : Sylvarche abattue"
	soon.add_child(_locked("Observatoire", thread + " · Changer le futur"))
	col.add_child(UiTheme.rule())
	col.add_child(_status_row())
	var ver := UiTheme.label("v%s" % str(ProjectSettings.get_setting("application/config/version", "0.1")), 16, Color(UiTheme.MUTED, 0.6))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(ver)
	if Cloud.instance != null:
		Cloud.instance.status_changed.connect(_refresh_cloud)
	_refresh_cloud()


## Un lieu de la place : il ouvre sa salle.
func _open_room(room: String) -> void:
	match room:
		"map":
			open_map.emit()
		"equipment":
			open_equipment.emit()
		"forge":
			open_forge.emit()
		"armory":
			open_armory.emit()
		"library":
			open_library.emit()
		"skills":
			open_skills.emit()
		"circle":
			open_circle.emit()
		"meditation":
			open_meditation.emit()
		"tower":
			open_tower.emit()
		"quests":
			open_quests.emit()


func _profile_card() -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 16)
	var v: VBoxContainer = c[1]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	# Portrait : le toucher ouvre le Miroir (apparence du héros).
	var frame := Button.new()
	frame.focus_mode = Control.FOCUS_NONE
	frame.tooltip_text = "Miroir : apparence du héros"
	frame.add_theme_stylebox_override("normal", UiTheme.box(Color("0a1019"), Color(UiTheme.TEAL, 0.7), 10, 2, 4))
	frame.add_theme_stylebox_override("hover", UiTheme.box(Color("0a1019"), UiTheme.TEAL, 10, 2, 4))
	frame.add_theme_stylebox_override("pressed", UiTheme.box(Color("0a1019"), UiTheme.GOLD, 10, 2, 4))
	frame.custom_minimum_size = Vector2(72, 72)
	frame.pressed.connect(func() -> void: open_mirror.emit())
	row.add_child(frame)
	var pic := TextureRect.new()
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.position = Vector2(4, 4)
	pic.size = Vector2(64, 64)
	pic.texture = PortraitArt.texture("porteur")
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(64, 64)
	frame.add_child(pic)
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", 2)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(who)
	var pname := "Invité"
	if Cloud.instance != null and Cloud.instance.username != "":
		pname = Cloud.instance.username
	who.add_child(UiTheme.label(pname, 28))
	if Profile.title() != "":
		# Le titre gagné par un haut fait, sous le nom.
		who.add_child(UiTheme.label("« %s »" % Profile.title(), 16, UiTheme.GOLD))
	var party := GameData.party()
	var cname := str((party["classes"] as Dictionary).get(Profile.player_class(), {}).get("name", "Mage"))
	var rname := str((party["races"] as Dictionary).get(Profile.race(), {}).get("name", "")).to_lower()
	who.add_child(UiTheme.label("%s %s · niveau %d" % [cname, rname, Profile.level()], 19, UiTheme.MUTED))
	row.add_child(UiTheme.currencies())
	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 12)
	v.add_child(xp_row)
	xp_row.add_child(UiTheme.label("XP", 17, UiTheme.MUTED))
	var bar := UiTheme.bar(UiTheme.TEAL, 10)
	bar.max_value = Profile.xp_to_next()
	bar.value = Profile.xp()
	xp_row.add_child(bar)
	xp_row.add_child(UiTheme.label("%d / %d" % [Profile.xp(), Profile.xp_to_next()], 17, UiTheme.MUTED))
	return c[0]


func _continue_button() -> Button:
	var next_id := Profile.next_level()
	var nl := GameData.level(next_id)
	var parts: Array = UiTheme.rich_button(108, "primary")
	var b: Button = parts[0]
	var h: HBoxContainer = parts[1]
	h.add_child(UiTheme.icon_rect("rune", 36, UiTheme.GOLD))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(UiTheme.title("CONTINUER", 30, UiTheme.GOLD))
	v.add_child(UiTheme.label("%s · %s" % [str(nl.get("number", "")), str(nl.get("name", ""))], 21, UiTheme.TEXT))
	h.add_child(UiTheme.icon_rect("chevron", 26, UiTheme.GOLD))
	b.pressed.connect(func() -> void: play_level.emit(next_id))
	return b


## Icône d'une tuile ; avec l'ambiance enrichie, à la couleur de la salle, sur un halo qui palpite.
func _glow_icon(icon: String, px: int, col: Color) -> Control:
	if not Profile.ambience_on():
		var plain := UiTheme.icon_rect(icon, px)
		plain.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return plain
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.custom_minimum_size = Vector2(px, px)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var halo := TextureRect.new()
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.texture = _halo_tex()
	halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	halo.stretch_mode = TextureRect.STRETCH_SCALE
	var hs := float(px) * 2.6
	halo.size = Vector2(hs, hs)
	halo.position = Vector2(px, px) * 0.5 - halo.size * 0.5
	halo.modulate = Color(col, 0.55)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = mat
	box.add_child(halo)
	var tw := halo.create_tween().set_loops()
	tw.tween_property(halo, "modulate:a", 0.3, 1.6 + randf() * 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(halo, "modulate:a", 0.6, 1.6 + randf() * 0.6).set_trans(Tween.TRANS_SINE)
	var ic := UiTheme.icon_rect(icon, px, col.lightened(0.15))
	ic.position = Vector2.ZERO
	ic.size = Vector2(px, px)
	box.add_child(ic)
	return box


static var _halo: Texture2D


static func _halo_tex() -> Texture2D:
	if _halo == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_halo = t
	return _halo


func _tile(icon: String, title: String, line1: String, line2: String, cb: Callable, glow: Color = UiTheme.TEAL) -> Button:
	var parts: Array = UiTheme.rich_button(168, "tile")
	var b: Button = parts[0]
	var h: HBoxContainer = parts[1]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(_glow_icon(icon, 44, glow))
	for t in [[title, 22, UiTheme.TEXT, true], [line1, 18, UiTheme.MUTED, false], [line2, 18, UiTheme.TEAL, false]]:
		var l := UiTheme.title(str(t[0]), int(t[1]), t[2]) if bool(t[3]) else UiTheme.label(str(t[0]), int(t[1]), t[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(10, 0)
		v.add_child(l)
	b.pressed.connect(cb)
	return b


func _small_tile(icon: String, title: String, line: String, line_col: Color, cb: Callable, glow: Color = UiTheme.TEAL) -> Button:
	var parts: Array = UiTheme.rich_button(128, "tile")
	var b: Button = parts[0]
	var h: HBoxContainer = parts[1]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(_glow_icon(icon, 32, glow))
	for t in [[title, 18, UiTheme.TEXT, true], [line, 16, line_col, false]]:
		var l := UiTheme.title(str(t[0]), int(t[1]), t[2]) if bool(t[3]) else UiTheme.label(str(t[0]), int(t[1]), t[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(10, 0)
		v.add_child(l)
	b.pressed.connect(cb)
	return b


func _locked(name: String, detail: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(UiTheme.icon_rect("lock", 20, UiTheme.MUTED))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	v.add_child(UiTheme.label(name, 21, UiTheme.MUTED))
	v.add_child(UiTheme.label(detail, 16, Color(UiTheme.MUTED, 0.7)))
	return h


func _status_row() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var s := HBoxContainer.new()
	s.add_theme_constant_override("separation", 10)
	v.add_child(s)
	_status_icon = UiTheme.icon_rect("cloud", 20, UiTheme.MUTED)
	s.add_child(_status_icon)
	_status_label = UiTheme.wrap("", 18, UiTheme.MUTED)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(_status_label)
	var a := HBoxContainer.new()
	v.add_child(a)
	_account_label = UiTheme.label("", 17, UiTheme.MUTED)
	_account_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.add_child(_account_label)
	# Écran Sauvegarde : choisir manuellement la progression à garder.
	var sv := UiTheme.button("Sauvegarde", 18)
	sv.icon = Icons.tex("cloud", 40)
	sv.add_theme_constant_override("icon_max_width", 20)
	sv.custom_minimum_size = Vector2(0, 44)
	sv.pressed.connect(func() -> void: open_save.emit())
	a.add_child(sv)
	_account_btn = UiTheme.button("", 18)
	_account_btn.flat = true
	_account_btn.custom_minimum_size = Vector2(0, 44)
	_account_btn.add_theme_color_override("font_color", UiTheme.TEAL)
	_account_btn.pressed.connect(_on_account)
	a.add_child(_account_btn)
	return v


func _refresh_cloud() -> void:
	if _status_label == null or not is_instance_valid(_status_label):
		return
	var c := Cloud.instance
	var col := UiTheme.MUTED
	if c != null and c.is_online():
		var msg := c.message if c.message != "" else "Synchronisé"
		col = UiTheme.GOLD if msg.contains("indisponible") or msg.begins_with("Échec") else UiTheme.TEAL
		_status_label.text = msg
		_account_label.text = "Compte Académie · %s" % c.username
		_account_btn.text = "Se déconnecter"
	elif c != null and c.status == "connecting":
		_status_label.text = "Connexion au compte…"
		_account_label.text = "Compte Académie"
		_account_btn.text = "…"
	else:
		_status_label.text = "Hors ligne : progression sauvegardée sur cet appareil" + ("" if c == null or c.message == "" else " (%s)" % c.message)
		_account_label.text = "Sans compte"
		_account_btn.text = "Se connecter"
	_status_label.add_theme_color_override("font_color", col)
	_status_icon.modulate = col


func _on_account() -> void:
	var c := Cloud.instance
	if c != null and c.is_online():
		c.logout()
		_refresh_cloud()
	else:
		open_login.emit()


## Tuile Équipement : la Puissance, et les objets de réserve meilleurs que l'équipé s'il y en a.
static func _gear_line() -> String:
	var n := Profile.better_items("player").size()
	if n > 0:
		return "Puissance %d · %d objet%s mieux en réserve" % [Profile.power(), n, "s" if n > 1 else ""]
	return "Puissance %d · %d objets" % [Profile.power(), (Profile.data["inventory"] as Array).size()]
