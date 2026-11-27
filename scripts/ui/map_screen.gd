class_name MapScreen
extends Control
## Carte du monde (docs/design/14-interface.md) :
## - en haut : retour, Puissance, étoiles de la zone, et la frise des 7 zones (emblème, acte, progression) ;
## - au centre : la carte illustrée de la zone (MapBoard), défilante, centrée sur le niveau choisi ;
## - en bas : la fiche du niveau touché (type, étoiles, record, description, puissance conseillée,
##   mode solo, JOUER).

signal back
signal play(level_id: String, solo: bool)

## Zone affichée : par défaut celle du prochain niveau.
var zone := 0
## Niveau choisi : par défaut le prochain niveau de la zone.
var selected := ""
var _solo: Button
var _board: MapBoard
var _scroll: ScrollContainer
var _sheet: VBoxContainer
var _ids: Array = []

const ZONE_BLURB := {
	1: "Le Surge frappe le village de Lysbourg.",
	2: "Pillards, clans orcs possédés et vent des steppes.",
	3: "Morts du marais, brume qui cache les ennemis, mares de poison.",
	4: "Bêtes des montagnes, élémentaires de givre, glace et avalanches, Portes naines.",
	5: "Soleil et lune, mirages, miroirs qui renvoient les tirs, et le Sphinx.",
	6: "Dragons et démons de feu, incendies que le Givre éteint, et le Wyrm de cendre.",
	7: "Créatures abyssales, marées qui noient les portails, courants, et le Léviathan.",
}
const ZONE_ACT := {1: "Acte I · Le Surge", 2: "Acte II · Les Alliances", 3: "Acte III · Les Cendres", 4: "Acte IV · Les Runes",
	5: "Acte V · Le Désert de Verre", 6: "Acte VI · Le Sang", 7: "Acte VII · Les Archives"}
const ROMAN := ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

## Ambiance de chaque zone sur la carte (option « Enrichie »).
const ZONE_MOOD := {1: "mist", 2: "steppe", 3: "swamp", 4: "snow", 5: "desert", 6: "cinder", 7: "abyss"}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if zone <= 0:
		zone = int(GameData.level(Profile.next_level()).get("zone", 1))
	UiTheme.backdrop(self, 0.55, 0.0, str(ZONE_MOOD.get(zone, "mist")), "zone%d" % zone)
	_build()


func _build() -> void:
	var solo_on := _solo != null and _solo.button_pressed
	var old := get_node_or_null("MapRoot")
	if old != null:
		old.name = "MapRootOld"
		old.queue_free()
	var index := GameData.level_index()
	var zd: Dictionary = {}
	for z in index.get("zones", []):
		if int(z["id"]) == zone:
			zd = z
	_ids = []
	for lid in zd.get("levels", []):
		# Niveau bonus (6-R) : visible seulement quand l'histoire l'ouvre.
		if str(GameData.level(str(lid)).get("requires", "")) == "" or Profile.is_unlocked(str(lid)):
			_ids.append(lid)
	if selected == "" or not _ids.has(selected):
		selected = _default_pick()
	# Colonne : en-tête et frise fixes, carte défilante, fiche fixe en bas.
	var margin := MarginContainer.new()
	margin.name = "MapRoot"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in [["margin_left", 18], ["margin_right", 18], ["margin_top", 14], ["margin_bottom", 12]]:
		margin.add_theme_constant_override(str(k[0]), int(k[1]))
	add_child(margin)
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	var w := minf(680.0, get_viewport_rect().size.x - 36.0)
	col.custom_minimum_size = Vector2(w, 0)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(col)
	col.add_child(_header())
	col.add_child(_zone_strip(index))
	col.add_child(_zone_title(zd))
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_scroll)
	_board = MapBoard.new()
	_board.selected = selected
	_scroll.add_child(_board)
	_board.setup(zone, _ids, w)
	_board.picked.connect(_select)
	var c: Array = UiTheme.card(Color(UiTheme.GOLD, 0.45), 14)
	col.add_child(c[0])
	_sheet = c[1]
	_sheet.add_theme_constant_override("separation", 8)
	_solo = null
	_fill_sheet(solo_on)
	_center_on.call_deferred(selected)


## Le prochain niveau de la zone, sinon le dernier ouvert.
func _default_pick() -> String:
	var last := ""
	for id in _ids:
		if Profile.is_unlocked(str(id)):
			last = str(id)
			if int(Profile.level_record(last)["clears"]) == 0:
				return last
	return last if last != "" else (str(_ids[0]) if not _ids.is_empty() else "")


func _center_on(id: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(_scroll) or not is_instance_valid(_board):
		return
	var y := _board.point_of(id).y
	_scroll.scroll_vertical = int(clampf(y - _scroll.size.y * 0.5, 0.0, maxf(_board.size.y - _scroll.size.y, 0.0)))


func _header() -> HBoxContainer:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var b := UiTheme.back_button("Havre-Aube")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	head.add_child(_chip("champion", "%d" % Profile.power(), UiTheme.TEAL, "Puissance"))
	var stars := 0
	for id in _ids:
		stars += int(Profile.level_record(str(id))["stars"])
	head.add_child(_chip("star_fill", "%d / %d" % [stars, _ids.size() * 3], UiTheme.GOLD, ""))
	return head


func _chip(icon: String, text: String, c: Color, caption: String) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.WARM, 0.9), Color(c, 0.45), 10, 1, 8))
	pc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	pc.add_child(h)
	h.add_child(UiTheme.icon_rect(icon, 22, c))
	if caption != "":
		h.add_child(UiTheme.label(caption, 15, UiTheme.MUTED))
	h.add_child(UiTheme.label(text, 22, c))
	return pc


## Frise des zones : emblème, numéro d'acte, étoiles gagnées ; cadenas tant que la zone est fermée.
func _zone_strip(index: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	for z in index.get("zones", []):
		var zid := int(z["id"])
		var lv: Array = z["levels"]
		var got := 0
		var n := 0
		var done := true
		for lid in lv:
			if str(GameData.level(str(lid)).get("requires", "")) != "" and not Profile.is_unlocked(str(lid)):
				continue
			n += 1
			got += int(Profile.level_record(str(lid))["stars"])
			done = done and int(Profile.level_record(str(lid))["clears"]) > 0
		var m := ZoneMedal.new()
		m.zid = zid
		m.open = Profile.is_unlocked(str(lv[0]))
		m.on = zid == zone
		m.frac = float(got) / float(maxi(n * 3, 1))
		m.done = done
		m.col = Color(str(MapBoard.ZONE_COL.get(zid, "ffffff")))
		var em := MapBoard.emblem(zid)
		m.art = em[0]
		m.region = em[1]
		m.label_text = str(ROMAN[clampi(zid, 0, 10)])
		m.tooltip_text = "Zone %d · %s" % [zid, str(z["name"])]
		m.setup()
		m.disabled = not m.open
		m.pressed.connect(func() -> void:
			if zid == zone:
				return
			zone = zid
			selected = ""
			UiTheme.set_mood(self, str(ZONE_MOOD.get(zid, "mist")))
			UiTheme.set_scene(self, "zone%d" % zid)
			_build.call_deferred())
		row.add_child(m)
	return row


func _zone_title(zd: Dictionary) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var act := UiTheme.label(str(ZONE_ACT.get(zone, "")).to_upper(), 16, Color(str(MapBoard.ZONE_COL.get(zone, "ffffff"))))
	act.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(act)
	var title := UiTheme.title(str(zd.get("name", "")).to_upper(), 36, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var first := GameData.level(str(_ids[0])) if not _ids.is_empty() else {}
	var lo := int(first.get("global_level", 1))
	var cleared := 0
	for id in _ids:
		if int(Profile.level_record(str(id))["clears"]) > 0:
			cleared += 1
	var blurb := UiTheme.wrap("Niveaux %d à %d · %d / %d terminés · %s" % [lo, lo + 9, cleared, _ids.size(), str(ZONE_BLURB.get(zone, ""))], 16, UiTheme.MUTED)
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(blurb)
	return v


func _select(id: String) -> void:
	if id == selected:
		return
	selected = id
	_board.select(id)
	_fill_sheet(_solo != null and _solo.button_pressed)


# ---------------------------------------------------------------- fiche du niveau choisi

func _fill_sheet(solo_on: bool) -> void:
	for ch in _sheet.get_children():
		ch.queue_free()
	if selected == "":
		return
	var lv := GameData.level(selected)
	var rec := Profile.level_record(selected)
	var open := Profile.is_unlocked(selected)
	var kind := str(lv.get("type", "Assaut"))
	var k: Array = MapBoard.KIND.get(kind, MapBoard.KIND["Assaut"])
	var kc := Color(str(k[1]))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	_sheet.add_child(top)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(62, 62)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel", UiTheme.box(Color(kc.darkened(0.82), 0.95), Color(kc, 0.8), 31, 2, 6))
	badge.add_child(UiTheme.icon_rect(str(k[0]) if open else "lock", 34, kc if open else UiTheme.MUTED))
	top.add_child(badge)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	var nm := UiTheme.label("%s · %s" % [str(lv.get("number", "")), str(lv.get("name", ""))], 24, UiTheme.GOLD if open else UiTheme.MUTED)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(nm)
	var meta := "%s · niveau %d" % [kind, int(lv.get("global_level", 1))]
	if int(rec["clears"]) > 0 and float(rec["best"]) > 0.0:
		meta += " · record %d:%02d" % [int(float(rec["best"]) / 60.0), int(float(rec["best"])) % 60]
	info.add_child(UiTheme.label(meta, 16, kc if open else UiTheme.MUTED))
	var st := HBoxContainer.new()
	st.add_theme_constant_override("separation", 2)
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in range(3):
		st.add_child(UiTheme.icon_rect("star_fill" if i < int(rec["stars"]) else "star", 26, UiTheme.GOLD if i < int(rec["stars"]) else Color(UiTheme.MUTED, 0.45)))
	top.add_child(st)
	var desc := UiTheme.wrap(str(lv.get("desc", "")), 16, UiTheme.TEXT)
	desc.max_lines_visible = 3
	_sheet.add_child(desc)
	_sheet.add_child(_power_row(int(lv.get("global_level", 1))))
	var act := HBoxContainer.new()
	act.add_theme_constant_override("separation", 10)
	_sheet.add_child(act)
	_solo = Button.new()
	_solo.toggle_mode = true
	_solo.button_pressed = solo_on
	_solo.focus_mode = Control.FOCUS_NONE
	_solo.custom_minimum_size = Vector2(190, 60)
	_solo.icon = Icons.tex("target", 40)
	_solo.add_theme_constant_override("icon_max_width", 20)
	_solo.add_theme_font_size_override("font_size", 16)
	_solo.text = "Solo · +25 % XP"
	_solo.tooltip_text = "Sans bots : +25 % d'expérience"
	_solo.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.BG, 0.9), Color(UiTheme.MUTED, 0.5), 12, 2, 8))
	_solo.add_theme_stylebox_override("hover", UiTheme.box(Color(UiTheme.BG, 0.9), UiTheme.TEAL, 12, 2, 8))
	_solo.add_theme_stylebox_override("pressed", UiTheme.box(Color(UiTheme.TEAL.darkened(0.8), 0.95), UiTheme.TEAL, 12, 2, 8, UiTheme.TEAL))
	_solo.add_theme_stylebox_override("hover_pressed", UiTheme.box(Color(UiTheme.TEAL.darkened(0.8), 0.95), UiTheme.TEAL, 12, 2, 8, UiTheme.TEAL))
	_solo.add_theme_color_override("font_color", UiTheme.MUTED)
	_solo.add_theme_color_override("font_pressed_color", UiTheme.TEAL)
	_solo.add_theme_color_override("font_hover_pressed_color", UiTheme.TEAL)
	_solo.add_theme_color_override("icon_normal_color", UiTheme.MUTED)
	_solo.add_theme_color_override("icon_pressed_color", UiTheme.TEAL)
	_solo.toggled.connect(func(_on: bool) -> void: Snd.click())
	act.add_child(_solo)
	var id := selected
	var go := UiTheme.button(("JOUER" if int(rec["clears"]) == 0 else "REJOUER") if open else "VERROUILLÉ", 26)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.custom_minimum_size = Vector2(0, 60)
	go.icon = Icons.tex("play" if open else "lock", 40)
	go.add_theme_constant_override("icon_max_width", 22)
	go.disabled = not open
	if open:
		go.add_theme_color_override("font_color", UiTheme.GOLD)
		go.add_theme_color_override("icon_normal_color", UiTheme.GOLD)
		go.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.95), Color(UiTheme.GOLD, 0.9), 12, 2, 8, UiTheme.GOLD))
	go.pressed.connect(func() -> void: play.emit(id, _solo.button_pressed))
	act.add_child(go)
	if not open:
		var i := _ids.find(selected)
		var prev := str(GameData.level(str(_ids[i - 1])).get("number", "")) if i > 0 else ""
		var hint := UiTheme.label("Termine d'abord le niveau %s." % prev if prev != "" else "Termine la zone précédente.", 15, UiTheme.MUTED)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_sheet.add_child(hint)


## Puissance du héros face à la puissance conseillée : une jauge et un verdict.
func _power_row(gl: int) -> HBoxContainer:
	var rp := Profile.recommended_power(gl)
	var pw := Profile.power()
	var ratio := float(pw) / float(maxi(rp, 1))
	var c := UiTheme.GOOD if ratio >= 1.0 else (UiTheme.GOLD if ratio >= 0.85 else UiTheme.FIRE)
	var verdict := "Prêt" if ratio >= 1.0 else ("Ardu" if ratio >= 0.85 else "Périlleux")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UiTheme.icon_rect("champion", 20, c))
	row.add_child(UiTheme.label("Puissance %d / %d conseillée" % [pw, rp], 16, UiTheme.MUTED))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = clampf(ratio, 0.0, 1.0)
	bar.custom_minimum_size = Vector2(0, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.45)
	bg.set_corner_radius_all(6)
	var fg := StyleBoxFlat.new()
	fg.bg_color = c
	fg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	row.add_child(bar)
	row.add_child(UiTheme.label(verdict, 17, c))
	return row


# ---------------------------------------------------------------- emblème de zone

class ZoneMedal extends Button:
	var zid := 1
	var open := false
	var on := false
	var done := false
	var frac := 0.0
	var col := Color.WHITE
	var art: Texture2D
	var region := Rect2()
	var label_text := ""

	func setup() -> void:
		custom_minimum_size = Vector2(86, 98)
		focus_mode = Control.FOCUS_NONE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		for s in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(s, StyleBoxEmpty.new())
		pressed.connect(Snd.click)

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, 41.0)
		var r := 36.0
		draw_circle(c + Vector2(0, 5), r, Color(0, 0, 0, 0.4))
		if on:
			draw_circle(c, r + 8.0, Color(UiTheme.GOLD, 0.16))
		draw_circle(c, r, Color(col.darkened(0.78), 0.97) if open else Color("10151c"))
		draw_circle(c + Vector2(0, -8), r * 0.7, Color(col, 0.10) if open else Color(1, 1, 1, 0.02))
		if art != null:
			var sz := region.size if region.size != Vector2.ZERO else art.get_size()
			var sc := minf(50.0 / sz.y, 58.0 / sz.x)
			var dst := Rect2(c + Vector2(-sz.x * sc * 0.5, r - 12.0 - sz.y * sc), sz * sc)
			var tint := Color.WHITE if open else Color(0.25, 0.28, 0.33, 0.9)
			if region.size != Vector2.ZERO:
				draw_texture_rect_region(art, dst, region, tint)
			else:
				draw_texture_rect(art, dst, false, tint)
		var ring := UiTheme.GOLD if on else (Color(col, 0.75) if open else Color("3a4652"))
		draw_arc(c, r, 0.0, TAU, 64, ring, 3.0 if on else 2.0, true)
		# Progression : un arc d'or proportionnel aux étoiles gagnées.
		if open and frac > 0.0:
			draw_arc(c, r + 4.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 64, UiTheme.GOLD, 3.0, true)
		if not open:
			var lk := Icons.tex("lock", 64, 1.8)
			draw_texture_rect(lk, Rect2(c - Vector2(14, 14), Vector2(28, 28)), false, Color("8fa3b3"))
		elif done:
			var ck := Icons.tex("check", 48, 2.2)
			draw_circle(c + Vector2(r * 0.72, -r * 0.72), 11.0, Color("0f2a1a"))
			draw_arc(c + Vector2(r * 0.72, -r * 0.72), 11.0, 0.0, TAU, 24, UiTheme.GOOD, 2.0, true)
			draw_texture_rect(ck, Rect2(c + Vector2(r * 0.72 - 8.0, -r * 0.72 - 8.0), Vector2(16, 16)), false, UiTheme.GOOD)
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, 94), label_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, UiTheme.GOLD if on else (UiTheme.TEXT if open else UiTheme.MUTED))
