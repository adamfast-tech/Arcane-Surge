class_name MapScreen
extends Control
## Carte de la zone : niveaux, étoiles, déblocage, puissance recommandée.

signal back
signal play(level_id: String, solo: bool)

var _solo: CheckBox


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.72)
	var col := UiTheme.scroll_column(self, 680.0, 20.0)
	var head := HBoxContainer.new()
	col.add_child(head)
	var b := UiTheme.button("‹ Havre-Aube", 22)
	b.custom_minimum_size = Vector2(0, 56)
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	var index := GameData.level_index()
	var total := (index["levels"] as Array).size() * 3
	head.add_child(UiTheme.star_row(1, 26))
	head.add_child(UiTheme.label("%d / %d" % [Profile.stars_total(), total], 24, UiTheme.GOLD))
	var title := UiTheme.title("ZONE 1 · %s" % str(index["zone"]).to_upper(), 40, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	col.add_child(UiTheme.wrap("Niveaux 1 à 10 · le Surge frappe le village de Lysbourg. Ta puissance : %d" % Profile.power(), 20, UiTheme.MUTED))
	_solo = CheckBox.new()
	_solo.text = "Mode solo (sans bots) · +25 % d'XP"
	_solo.focus_mode = Control.FOCUS_NONE
	_solo.add_theme_font_size_override("font_size", 22)
	col.add_child(_solo)
	for id in index["levels"]:
		col.add_child(_level_card(str(id)))


func _level_card(id: String) -> PanelContainer:
	var lv := GameData.level(id)
	var unlocked := Profile.is_unlocked(id)
	var rec := Profile.level_record(id)
	var special := str(lv.get("objective", "")) == "boss"
	var c: Array = UiTheme.card(UiTheme.GOLD if special and unlocked else (UiTheme.BORDER if unlocked else Color(UiTheme.BORDER, 0.5)), 14)
	var pc: PanelContainer = c[0]
	var v: VBoxContainer = c[1]
	if not unlocked:
		pc.modulate = Color(1, 1, 1, 0.55)
	var row := HBoxContainer.new()
	v.add_child(row)
	var nm := UiTheme.label("%s · %s" % [str(lv.get("number", "")), str(lv.get("name", ""))], 28, UiTheme.GOLD if unlocked else UiTheme.MUTED)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(nm)
	row.add_child(UiTheme.star_row(int(rec["stars"]), 24))
	var gl := int(lv.get("global_level", 1))
	var rp := Profile.recommended_power(gl)
	var meta := "%s · niveau %d" % [str(lv.get("type", "")), gl]
	if int(rec["clears"]) > 0 and float(rec["best"]) > 0.0:
		meta += " · record %d:%02d" % [int(float(rec["best"]) / 60.0), int(float(rec["best"])) % 60]
	v.add_child(UiTheme.label(meta, 20, UiTheme.CYAN))
	v.add_child(UiTheme.wrap(str(lv.get("desc", "")), 19, UiTheme.MUTED))
	var foot := HBoxContainer.new()
	v.add_child(foot)
	var pw := UiTheme.label("Puissance recommandée %d" % rp, 19, UiTheme.GOOD if Profile.power() >= rp else UiTheme.FIRE)
	pw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(pw)
	if unlocked:
		var b := UiTheme.button("JOUER" if int(rec["clears"]) == 0 else "REJOUER", 24)
		b.custom_minimum_size = Vector2(170, 58)
		b.add_theme_color_override("font_color", UiTheme.GOLD)
		b.pressed.connect(func() -> void: play.emit(id, _solo.button_pressed))
		foot.add_child(b)
	else:
		foot.add_child(UiTheme.label("Verrouillé", 20, UiTheme.MUTED))
	return pc
