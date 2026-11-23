class_name OptionsScreen
extends Control
## Options (clé à molette de Havre-Aube ; docs/design/30-options.md) : sorts en combat (Deck ou
## Tiroir), écoles élémentaires communes ou réservées au Mage, et difficulté (de Facile à Impossible).

signal back

var _msg := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.7)
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 14)
	var head := HBoxContainer.new()
	col.add_child(head)
	var b := UiTheme.back_button("Havre-Aube")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("OPTIONS", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title("COMBAT, GRIMOIRES ET DIFFICULTÉ", 20, UiTheme.TEXT))
	if _msg != "":
		col.add_child(UiTheme.wrap(_msg, 18, UiTheme.GOLD))

	# Sorts en combat : Deck ou Tiroir.
	col.add_child(UiTheme.section("Sorts en combat"))
	var mode := Profile.spell_mode()
	col.add_child(_choice("DECK", "Les 7 sorts choisis à la Bibliothèque : toucher un sort, puis l'arène.", "book", mode == "deck", func() -> void:
		Profile.set_spell_mode("deck")
		_changed("Mode Deck : tes 7 sorts choisis à la Bibliothèque.")))
	col.add_child(_choice("TIROIR", "Tous tes sorts connus, rangés par école et par discipline : maintenir une école, glisser jusqu'au sort.", "rune", mode == "drawer", func() -> void:
		Profile.set_spell_mode("drawer")
		_changed("Mode Tiroir : tous tes sorts connus, rangés par école et par discipline.")))
	col.add_child(UiTheme.wrap("L'écran de Préparation, avant chaque combat, permet aussi de changer ce choix.", 15, UiTheme.MUTED))

	# Ambiance des menus : sobre, ou enrichie (rayons, brume, particules, panneaux en relief, titres dorés).
	col.add_child(UiTheme.section("Ambiance des menus"))
	var fx := Profile.ambience_on()
	col.add_child(_choice("ENRICHIE", "Havre-Aube et ses salles s'animent : lumière et brume qui dérivent, lucioles, poussière arcanique ou braises selon la salle, panneaux en relief, titres dorés. Le combat ne change pas.", "sparkle", fx, func() -> void:
		Profile.set_ambience(true)
		_changed("Ambiance enrichie : Havre-Aube s'anime.")))
	col.add_child(_choice("SOBRE", "Les menus d'origine, sans animation de fond (plus économe sur les vieux téléphones).", "moon", not fx, func() -> void:
		Profile.set_ambience(false)
		_changed("Ambiance sobre.")))

	var sp := Profile.sparkle_on()
	col.add_child(_choice("ÉCLAT AU TOUCHER : %s" % ("OUI" if sp else "NON"), "Une gerbe d'étincelles là où tu touches l'écran, dans les menus (jamais en combat).", "dust", sp, func() -> void:
		Profile.set_sparkle(not Profile.sparkle_on())
		_changed("Éclat au toucher : %s." % ("activé" if Profile.sparkle_on() else "désactivé"))))

	# Grimoires : écoles élémentaires communes, ou chaque voie son grimoire.
	col.add_child(UiTheme.section("Grimoires"))
	var all := Profile.elem_for_all()
	col.add_child(_choice("ÉCOLES POUR TOUTES LES VOIES", "Les sorts élémentaires (Feu, Givre, Foudre, Nature, Ombre, Arcane, Terre : le grimoire du Mage) servent à toutes les voies, en plus du grimoire de chaque classe.", "sparkle", all, func() -> void:
		Profile.set_elem_for_all(true)
		_changed("Toutes les voies emportent aussi les sorts élémentaires.")))
	col.add_child(_choice("CHAQUE VOIE SON GRIMOIRE", "Seul le Mage emporte les sorts élémentaires. Les autres voies n'emportent que leur grimoire de classe, les sorts de leur arbre et les sorts sans école (Purifier).", "target", not all, func() -> void:
		Profile.set_elem_for_all(false)
		_changed("Chaque voie n'emporte plus que son propre grimoire.")))
	var cls := Profile.player_class()
	var cname := str(((GameData.party()["classes"] as Dictionary).get(cls, {}) as Dictionary).get("name", cls))
	var note := "Ta voie : %s. " % cname
	if cls == "mage":
		note += "Le Mage garde toujours les écoles élémentaires : c'est son grimoire."
	else:
		note += "Les sorts déjà appris ne sont jamais perdus : ils reviennent si tu changes d'option ou de voie. Chaque voie connaît d'office trois techniques de départ."
	col.add_child(UiTheme.wrap(note, 15, UiTheme.MUTED))

	# Difficulté.
	col.add_child(UiTheme.section("Difficulté"))
	col.add_child(UiTheme.wrap("Elle s'applique aux prochains combats : vitesse et dégâts des ennemis, PV du Nexus (et du boss), XP gagnée et butin.", 15, UiTheme.MUTED))
	var cur := Profile.difficulty()
	for d in Profile.DIFFICULTIES:
		var did := str(d["id"])
		col.add_child(_difficulty_card(d, did == cur, func() -> void:
			Profile.set_difficulty(did)
			_changed("Difficulté : %s." % str(d["name"]))))


## Ligne de choix exclusive (titre, explication, icône), surlignée quand elle est active.
## Un panneau qui suit la hauteur de son texte ; toucher (sans faire défiler) le choisit.
func _choice(title: String, text: String, icon: String, on: bool, pick: Callable, accent: Color = UiTheme.TEAL) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_PASS
	pc.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL2, 0.96) if on else Color(UiTheme.PANEL, 0.9), accent if on else UiTheme.BORDER, 12, 2 if on else 1, 12))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	pc.add_child(h)
	var ic := UiTheme.icon_rect(icon, 30, accent if on else UiTheme.MUTED)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	v.add_child(UiTheme.label(title, 19, accent if on else UiTheme.TEXT))
	v.add_child(UiTheme.wrap(text, 15, UiTheme.MUTED))
	if on:
		var ok := UiTheme.icon_rect("check", 26, accent)
		ok.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ok)
	for c in [h, ic, v]:
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in v.get_children():
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var down := [Vector2.ZERO]
	pc.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if ev.is_pressed():
				down[0] = (ev as InputEventMouseButton).global_position
			elif (ev as InputEventMouseButton).global_position.distance_to(down[0]) < 14.0:
				pick.call())
	return pc


## Explication d'une difficulté : multiplicateurs lisibles (« 25 % plus rapides »…).
static func difficulty_text(d: Dictionary) -> String:
	var m := float(d["mult"])
	if is_equal_approx(m, 1.0):
		return "Le jeu tel qu'il est équilibré : rien ne change."
	var pct := int(round(absf(m - 1.0) * 100.0))
	if m < 1.0:
		return "Ennemis %d %% plus lents, %d %% de dégâts en moins · Nexus et boss : %d %% de PV en moins · XP et butin : -%d %%." % [pct, pct, pct, pct]
	return "Ennemis %d %% plus rapides, %d %% de dégâts en plus · Nexus et boss : +%d %% de PV · XP et butin : +%d %% (objets plus rares)." % [pct, pct, pct, pct]


func _difficulty_card(d: Dictionary, on: bool, pick: Callable) -> PanelContainer:
	var dc := Color(str(d["color"]))
	var pc := _choice(str(d["name"]).to_upper(), difficulty_text(d), "star" if float(d["mult"]) >= 1.0 else "moon", on, pick, dc)
	if not on:
		# Couleur de la difficulté sur son nom, même quand elle n'est pas choisie.
		var v: VBoxContainer = (pc.get_child(0) as HBoxContainer).get_child(1)
		(v.get_child(0) as Label).add_theme_color_override("font_color", Color(dc, 0.85))
	return pc


func _changed(msg: String) -> void:
	_msg = msg
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
	_rebuild.call_deferred()
