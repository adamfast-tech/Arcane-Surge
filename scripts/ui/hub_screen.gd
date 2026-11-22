class_name HubScreen
extends Control
## Havre-Aube (concept UI) : profil et monnaies, « Continuer », carte et équipement, salles à
## venir, état de la sauvegarde et du compte.

signal open_map
signal open_equipment
signal open_login
signal open_save
signal play_level(level_id: String)

var _status_icon: TextureRect
var _status_label: Label
var _account_label: Label
var _account_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.28, 0.94)
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 16)
	col.add_child(_profile_card())
	var title := UiTheme.title("HAVRE-AUBE", 54, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.08))
	title.add_theme_constant_override("outline_size", 8)
	col.add_child(title)
	var sub := UiTheme.label("Refuge des Canalisateurs", 22, UiTheme.TEXT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.08))
	sub.add_theme_constant_override("outline_size", 6)
	col.add_child(sub)
	# Espace qui laisse voir l'illustration (plus grand sur les écrans hauts).
	var gap := Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y - 1000.0, 24.0, 420.0))
	col.add_child(gap)
	col.add_child(_continue_button())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	col.add_child(grid)
	var index := GameData.level_index()
	var total := (index["levels"] as Array).size() * 3
	grid.add_child(_tile("map", "CARTE DU MONDE", str(index["zone"]), "Zone 1 · %d / %d étoiles" % [Profile.stars_total(), total], func() -> void: open_map.emit()))
	grid.add_child(_tile("baton_chene", "ÉQUIPEMENT", "Équipement & Forge", "Puissance %d · %d objets" % [Profile.power(), (Profile.data["inventory"] as Array).size()], func() -> void: open_equipment.emit()))
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
	soon.add_child(_locked("Bibliothèque", "Sorts et grimoires"))
	soon.add_child(_locked("Entraînement", "Arbres de compétences"))
	soon.add_child(_locked("Le Cercle", "Brann %d · Sylwen %d" % [Story.loyalty("brann"), Story.loyalty("sylwen")]))
	soon.add_child(_locked("Observatoire", thread))
	col.add_child(UiTheme.rule())
	col.add_child(_status_row())
	var ver := UiTheme.label("v%s" % str(ProjectSettings.get_setting("application/config/version", "0.1")), 16, Color(UiTheme.MUTED, 0.6))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(ver)
	if Cloud.instance != null:
		Cloud.instance.status_changed.connect(_refresh_cloud)
	_refresh_cloud()


func _profile_card() -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 16)
	var v: VBoxContainer = c[1]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), Color(UiTheme.TEAL, 0.7), 10, 2, 4))
	row.add_child(frame)
	var pic := TextureRect.new()
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
	who.add_child(UiTheme.label("Mage elfe · niveau %d" % Profile.level(), 19, UiTheme.MUTED))
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


func _tile(icon: String, title: String, line1: String, line2: String, cb: Callable) -> Button:
	var parts: Array = UiTheme.rich_button(168, "tile")
	var b: Button = parts[0]
	var h: HBoxContainer = parts[1]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var ic := UiTheme.icon_rect(icon, 44)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	for t in [[title, 22, UiTheme.TEXT, true], [line1, 18, UiTheme.MUTED, false], [line2, 18, UiTheme.TEAL, false]]:
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
