class_name HubScreen
extends Control
## Havre-Aube : profil, progression, accès à la carte, à l'équipement et aux salles.

signal open_map
signal open_equipment
signal open_login
signal play_level(level_id: String)

var _cloud_label: Label
var _account_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.5)
	var col := UiTheme.scroll_column(self, 680.0, 20.0)
	col.add_child(_profile_card())
	var title := UiTheme.title("HAVRE-AUBE", 52, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := UiTheme.label("Refuge des Canalisateurs", 22, UiTheme.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var next_id := Profile.next_level()
	var nl := GameData.level(next_id)
	var go := UiTheme.button("CONTINUER\n%s · %s" % [str(nl.get("number", "")), str(nl.get("name", ""))], 28)
	go.custom_minimum_size = Vector2(0, 104)
	go.add_theme_color_override("font_color", UiTheme.GOLD)
	go.add_theme_stylebox_override("normal", UiTheme.box(Color("3a2c18"), UiTheme.GOLD, 16, 3, 10))
	go.add_theme_stylebox_override("hover", UiTheme.box(Color("4a381e"), UiTheme.GOLD, 16, 3, 10))
	go.pressed.connect(func() -> void: play_level.emit(next_id))
	col.add_child(go)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	col.add_child(grid)
	var index := GameData.level_index()
	var total := (index["levels"] as Array).size() * 3
	grid.add_child(_tile("CARTE DU MONDE", "Zone 1 · %s\n%d / %d étoiles" % [str(index["zone"]), Profile.stars_total(), total], true, func() -> void: open_map.emit()))
	grid.add_child(_tile("ÉQUIPEMENT & FORGE", "Puissance %d\n%d objets" % [Profile.power(), (Profile.data["inventory"] as Array).size()], true, func() -> void: open_equipment.emit()))
	grid.add_child(_tile("BIBLIOTHÈQUE", "Sorts et Grimoire\nBientôt (étape 10.3)", false, Callable()))
	grid.add_child(_tile("ENTRAÎNEMENT", "Arbre de compétences\nBientôt (étape 10.3)", false, Callable()))
	grid.add_child(_tile("LE CERCLE", "Brann · Sylwen\nBientôt (étape 10.3)", false, Callable()))
	grid.add_child(_tile("OBSERVATOIRE", "Fils du destin\nActe 2", false, Callable()))
	var ver := UiTheme.label("v%s" % str(ProjectSettings.get_setting("application/config/version", "0.1")), 16, UiTheme.MUTED)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(ver)
	if Cloud.instance != null:
		Cloud.instance.status_changed.connect(_refresh_cloud)
	_refresh_cloud()


func _profile_card() -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 14)
	var v: VBoxContainer = c[1]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var pname := "Invité"
	if Cloud.instance != null and Cloud.instance.username != "":
		pname = Cloud.instance.username
	var avatar := Label.new()
	avatar.text = pname.substr(0, 1).to_upper()
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.custom_minimum_size = Vector2(64, 64)
	avatar.add_theme_font_size_override("font_size", 34)
	avatar.add_theme_color_override("font_color", UiTheme.CYAN)
	avatar.add_theme_stylebox_override("normal", UiTheme.box(UiTheme.PANEL2, UiTheme.CYAN, 12, 2, 0))
	row.add_child(avatar)
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", 2)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(who)
	who.add_child(UiTheme.label(pname, 28))
	who.add_child(UiTheme.label("Mage elfe · niveau %d" % Profile.level(), 20, UiTheme.MUTED))
	var money := VBoxContainer.new()
	money.add_theme_constant_override("separation", 2)
	row.add_child(money)
	var g := UiTheme.label("%d or" % Profile.gold(), 22, UiTheme.GOLD)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money.add_child(g)
	var d := UiTheme.label("%d poussière" % Profile.dust(), 18, UiTheme.VIOLET)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money.add_child(d)
	var xp_row := HBoxContainer.new()
	v.add_child(xp_row)
	xp_row.add_child(UiTheme.label("XP", 20, UiTheme.CYAN))
	var bar := UiTheme.bar(UiTheme.CYAN, 12)
	bar.max_value = Profile.xp_to_next()
	bar.value = Profile.xp()
	xp_row.add_child(bar)
	xp_row.add_child(UiTheme.label("%d / %d" % [Profile.xp(), Profile.xp_to_next()], 18, UiTheme.MUTED))
	var acc := HBoxContainer.new()
	v.add_child(acc)
	_cloud_label = UiTheme.wrap("", 18, UiTheme.MUTED)
	_cloud_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acc.add_child(_cloud_label)
	_account_btn = UiTheme.button("", 18)
	_account_btn.custom_minimum_size = Vector2(190, 48)
	_account_btn.pressed.connect(_on_account)
	acc.add_child(_account_btn)
	return c[0]


func _tile(title: String, body: String, enabled: bool, cb: Callable) -> Button:
	var b := UiTheme.button("%s\n%s" % [title, body], 20)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 118)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.disabled = not enabled
	if enabled:
		b.add_theme_color_override("font_color", UiTheme.TEXT)
		b.pressed.connect(cb)
	return b


func _refresh_cloud() -> void:
	if _cloud_label == null or not is_instance_valid(_cloud_label):
		return
	var c := Cloud.instance
	if c != null and c.is_online():
		_cloud_label.text = "Compte Académie : %s · %s" % [c.username, c.message if c.message != "" else "connecté"]
		_account_btn.text = "Se déconnecter"
	elif c != null and c.status == "connecting":
		_cloud_label.text = "Connexion au compte…"
		_account_btn.text = "…"
	else:
		_cloud_label.text = "Hors ligne : progression sauvegardée sur cet appareil" + ("" if c == null or c.message == "" else " (%s)" % c.message)
		_account_btn.text = "Se connecter"


func _on_account() -> void:
	var c := Cloud.instance
	if c != null and c.is_online():
		c.logout()
		_refresh_cloud()
	else:
		open_login.emit()
