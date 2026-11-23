class_name MapScreen
extends Control
## Carte de la zone : niveaux, étoiles, déblocage, puissance recommandée.

signal back
signal play(level_id: String, solo: bool)

var _solo: CheckBox
## Zone affichée (onglets) : par défaut celle du prochain niveau.
var zone := 0

const ZONE_BLURB := {
	1: "Niveaux 1 à 10 · le Surge frappe le village de Lysbourg.",
	2: "Niveaux 11 à 20 · acte 2, les Alliances : pillards, clans orcs possédés et vent des steppes.",
	3: "Niveaux 21 à 30 · acte 3, les Cendres : morts du marais, brume qui cache les ennemis, mares de poison.",
	4: "Niveaux 31 à 40 · acte 4, les Runes : bêtes des montagnes et élémentaires de givre, glace qui fait glisser, avalanches, Portes naines « Forge ».",
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.72)
	if zone <= 0:
		zone = int(GameData.level(Profile.next_level()).get("zone", 1))
	_build()


func _build() -> void:
	var solo_on := _solo != null and _solo.button_pressed
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var col := UiTheme.scroll_column(self, 680.0, 20.0)
	var head := HBoxContainer.new()
	col.add_child(head)
	var b := UiTheme.back_button("Havre-Aube")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	var index := GameData.level_index()
	var zd: Dictionary = {}
	for z in index.get("zones", []):
		if int(z["id"]) == zone:
			zd = z
	var ids: Array = zd.get("levels", [])
	var stars := 0
	for id in ids:
		stars += int(Profile.level_record(str(id))["stars"])
	head.add_child(UiTheme.icon_rect("star", 26, UiTheme.GOLD))
	head.add_child(UiTheme.label("%d / %d" % [stars, ids.size() * 3], 24, UiTheme.GOLD))
	# Onglets des zones.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	col.add_child(tabs)
	for z in index.get("zones", []):
		var zid := int(z["id"])
		var first := str((z["levels"] as Array)[0])
		var open := Profile.is_unlocked(first)
		var t := UiTheme.button("Zone %d\n%s" % [zid, str(z["name"])], 18)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.custom_minimum_size = Vector2(0, 66)
		t.disabled = not open
		if not open:
			t.icon = Icons.tex("lock", 36)
			t.add_theme_constant_override("icon_max_width", 18)
		if zid == zone:
			t.add_theme_color_override("font_color", UiTheme.GOLD)
			t.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.85), 12, 2, 8, UiTheme.GOLD))
		t.pressed.connect(func() -> void:
			zone = zid
			_build.call_deferred())
		tabs.add_child(t)
	var title := UiTheme.title("ZONE %d · %s" % [zone, str(zd.get("name", "")).to_upper()], 40, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	col.add_child(UiTheme.wrap("%s Ta puissance : %d" % [str(ZONE_BLURB.get(zone, "")), Profile.power()], 20, UiTheme.MUTED))
	_solo = CheckBox.new()
	_solo.button_pressed = solo_on
	_solo.text = "Mode solo (sans bots) · +25 % d'XP"
	_solo.focus_mode = Control.FOCUS_NONE
	_solo.add_theme_font_size_override("font_size", 22)
	col.add_child(_solo)
	for id in ids:
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
		b.icon = Icons.tex("play", 40)
		b.add_theme_constant_override("icon_max_width", 18)
		b.custom_minimum_size = Vector2(170, 58)
		b.add_theme_color_override("font_color", UiTheme.GOLD)
		b.add_theme_color_override("icon_normal_color", UiTheme.GOLD)
		b.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.8), 12, 2, 8))
		b.pressed.connect(func() -> void: play.emit(id, _solo.button_pressed))
		foot.add_child(b)
	else:
		foot.add_child(UiTheme.icon_rect("lock", 20, UiTheme.MUTED))
		foot.add_child(UiTheme.label("Verrouillé", 20, UiTheme.MUTED))
	return pc
