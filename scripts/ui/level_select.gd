class_name LevelSelect
extends Control
## Menu du prototype : choix du niveau de la zone 1 et du mode solo.

signal start_level(level_id: String, solo: bool)

var _solo: CheckBox


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	center.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.custom_minimum_size = Vector2(minf(660.0, get_viewport_rect().size.x - 48.0), 0)
	margin.add_child(v)

	var title := UiTheme.label("ARCANE SURGE", 64, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UiTheme.label("Prototype jouable · combat", 26, UiTheme.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var index := GameData.level_index()
	v.add_child(UiTheme.label("Zone 1 · %s" % str(index.get("zone", "")), 28, UiTheme.CYAN))
	for id in index.get("levels", []):
		v.add_child(_level_card(str(id)))

	_solo = CheckBox.new()
	_solo.text = "Mode solo (sans bots) · +25 % d'XP"
	_solo.focus_mode = Control.FOCUS_NONE
	_solo.add_theme_font_size_override("font_size", 24)
	v.add_child(_solo)

	var help := PanelContainer.new()
	v.add_child(help)
	var hv := VBoxContainer.new()
	help.add_child(hv)
	hv.add_child(UiTheme.label("COMMANDES", 24, UiTheme.MUTED))
	hv.add_child(_wrap(
		"Tactile : maintiens sur l'arène pour lancer le Flux d'invocations, glisse pour viser. "
		+ "Touche un sort puis l'arène pour le lancer. Touche un bot pour changer son ordre.\n"
		+ "PC : clic gauche maintenu = Flux, souris = viser, 1-4 = sorts au curseur, E = Champion, "
		+ "Espace = Ultime, Q / R = ordres des bots, F = tir automatique, Échap = pause.", 20, UiTheme.TEXT))
	var ver := UiTheme.label("v%s · Godot %s" % [str(ProjectSettings.get_setting("application/config/version", "0.1")), Engine.get_version_info()["string"]], 18, UiTheme.MUTED)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ver)


func _level_card(id: String) -> PanelContainer:
	var lv := GameData.level(id)
	var card := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var b := UiTheme.button("%s · %s" % [str(lv.get("number", "")), str(lv.get("name", ""))], 30)
	b.custom_minimum_size = Vector2(0, 76)
	b.add_theme_color_override("font_color", UiTheme.GOLD)
	b.pressed.connect(func() -> void: start_level.emit(id, _solo.button_pressed))
	v.add_child(b)
	var meta := "%s · niveau %d" % [str(lv.get("type", "")), int(lv.get("global_level", 1))]
	if bool(lv.get("solo", false)):
		meta += " · solo"
	v.add_child(UiTheme.label(meta, 20, UiTheme.CYAN))
	v.add_child(_wrap(str(lv.get("desc", "")), 20, UiTheme.MUTED))
	return card


func _wrap(text: String, fs: int, color: Color) -> Label:
	var l := UiTheme.label(text, fs, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	return l
