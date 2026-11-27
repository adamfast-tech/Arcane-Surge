class_name HeroCard
extends Control
## Carte du héros à partager (Équipement) : le héros en volume en pose (victoire, sort, repos), avec son équipement,
## ses cosmétiques et l'éclairage de la zone choisie en fond, son nom, sa race, sa classe, son niveau, sa Puissance
## et ses objets portés. La carte est rendue dans un SubViewport (1080 × 1350) puis enregistrée en PNG
## (téléchargée sur le web).

signal closed

const CARD := Vector2i(1080, 1350)
## Éclairage du héros selon le décor de la zone.
const ZONE_LIGHT := {1: "nuit", 2: "crepuscule", 3: "nuit", 4: "aube", 5: "jour", 6: "lave", 7: "abysses"}
const POSES := [["victory", "Victoire"], ["cast", "Sort"], ["idle", "Repos"]]

var zone := 1
var pose_id := "victory"
var _vp: SubViewport
var _card: Control
var _preview: TextureRect
var _row_zone: HFlowContainer
var _row_pose: HFlowContainer
var _status: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	zone = clampi(_current_zone(), 1, 7)
	var dim := ColorRect.new()
	dim.color = Color(UiTheme.BG, 0.98)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_vp = SubViewport.new()
	_vp.size = CARD
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 12)
	var head := HBoxContainer.new()
	col.add_child(head)
	var b := UiTheme.back_button("Équipement")
	b.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	head.add_child(b)
	col.add_child(UiTheme.title("CARTE DU HÉROS", 40, UiTheme.GOLD))
	_preview = TextureRect.new()
	_preview.texture = _vp.get_texture()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.custom_minimum_size = Vector2(0, 640)
	col.add_child(_preview)
	col.add_child(UiTheme.label("DÉCOR", 14, UiTheme.MUTED))
	_row_zone = HFlowContainer.new()
	_row_zone.add_theme_constant_override("h_separation", 6)
	_row_zone.add_theme_constant_override("v_separation", 6)
	col.add_child(_row_zone)
	col.add_child(UiTheme.label("POSE", 14, UiTheme.MUTED))
	_row_pose = HFlowContainer.new()
	_row_pose.add_theme_constant_override("h_separation", 6)
	_row_pose.add_theme_constant_override("v_separation", 6)
	col.add_child(_row_pose)
	var save: Array = UiTheme.rich_button(72, "primary")
	var sb: Button = save[0]
	var sh: HBoxContainer = save[1]
	sh.alignment = BoxContainer.ALIGNMENT_CENTER
	sh.add_child(UiTheme.icon_rect("star", 26, UiTheme.GOLD))
	sh.add_child(UiTheme.title("ENREGISTRER L'IMAGE", 26, UiTheme.GOLD))
	sb.pressed.connect(_save)
	col.add_child(sb)
	_status = UiTheme.label("", 15, UiTheme.MUTED)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_status)
	_refresh()


static func _current_zone() -> int:
	return maxi(1, int(GameData.level(Profile.next_level()).get("zone", 1)))


func _refresh() -> void:
	for ch in _row_zone.get_children():
		ch.queue_free()
	for ch in _row_pose.get_children():
		ch.queue_free()
	var zones: Array = GameData.level_index()["zones"]
	for zd in zones:
		var zid := int(zd["id"])
		if zid > _current_zone():
			continue
		var zb := _chip(str(zd["name"]), zid == zone)
		zb.pressed.connect(func() -> void:
			Snd.click()
			zone = zid
			_refresh())
		_row_zone.add_child(zb)
	for pz in POSES:
		var pid := str(pz[0])
		var pb := _chip(str(pz[1]), pid == pose_id)
		pb.pressed.connect(func() -> void:
			Snd.click()
			pose_id = pid
			_refresh())
		_row_pose.add_child(pb)
	if is_instance_valid(_card):
		_card.queue_free()
	_card = build_card(zone, pose_id)
	_vp.add_child(_card)


func _chip(text: String, on: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.text = text
	b.add_theme_font_size_override("font_size", 14)
	b.custom_minimum_size = Vector2(0, 40)
	var col := UiTheme.GOLD
	b.add_theme_color_override("font_color", col if on else UiTheme.TEXT)
	b.add_theme_stylebox_override("normal", UiTheme.box(Color(col.darkened(0.82), 0.95) if on else Color(UiTheme.BG, 0.85), Color(col, 0.9) if on else Color(col, 0.3), 18, 2 if on else 1, 10))
	b.add_theme_stylebox_override("hover", UiTheme.box(Color(col.darkened(0.78), 0.95), col, 18, 2, 10))
	return b


## Image du héros dans la pose choisie (dernière image de l'animation), sous l'éclairage de la zone.
static func hero_image(z: int, pose: String) -> Image:
	var m := HeroModel.of(Profile.look(), Profile.race(), Profile.player_class(), Profile.visible_cosmetics(), Profile.gear_look())
	var f := 0
	match pose:
		"victory":
			f = int(HeroModel.ANIMS["victory"]["frames"]) - 1
		"cast":
			f = 3
	return m.frame_at(PI + 0.5, pose, f, str(ZONE_LIGHT.get(z, "jour")))


## La carte elle-même (1080 × 1350).
static func build_card(z: int, pose: String) -> Control:
	var root := Control.new()
	root.size = Vector2(CARD)
	var party := GameData.party()
	# Décor de la zone, assombri vers le bas pour le texte.
	var art := TextureRect.new()
	art.texture = RoomArt.scene("zone%d" % z, Vector2i(270, 338))
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.size = Vector2(CARD)
	root.add_child(art)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.18, 0.55, 0.78, 1.0])
	g.colors = PackedColorArray([Color(UiTheme.BG, 0.75), Color(UiTheme.BG, 0.1), Color(UiTheme.BG, 0.05), Color(UiTheme.BG, 0.82), Color(UiTheme.BG, 0.96)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 256
	var shade := TextureRect.new()
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.size = Vector2(CARD)
	root.add_child(shade)
	# Cadre doré.
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", UiTheme.box(Color(0, 0, 0, 0), Color(UiTheme.GOLD, 0.85), 26, 5, 0))
	frame.position = Vector2(22, 22)
	frame.size = Vector2(CARD) - Vector2(44, 44)
	root.add_child(frame)
	var inner := Panel.new()
	inner.add_theme_stylebox_override("panel", UiTheme.box(Color(0, 0, 0, 0), Color(UiTheme.GOLD, 0.3), 20, 2, 0))
	inner.position = Vector2(36, 36)
	inner.size = Vector2(CARD) - Vector2(72, 72)
	root.add_child(inner)
	# En-tête : le jeu et le décor.
	var zones: Array = GameData.level_index()["zones"]
	var zname := ""
	for zd in zones:
		if int(zd["id"]) == z:
			zname = str(zd["name"])
	var t1 := _text("ARCANE SURGE", 54, UiTheme.GOLD, true)
	t1.position = Vector2(0, 66)
	t1.size = Vector2(CARD.x, 70)
	root.add_child(t1)
	var t2 := _text(zname.to_upper(), 30, Color(UiTheme.TEXT, 0.8), false)
	t2.position = Vector2(0, 130)
	t2.size = Vector2(CARD.x, 40)
	root.add_child(t2)
	# Le héros sur son socle de lumière.
	var light_col: Color = (HeroModel.LIGHTS[str(ZONE_LIGHT.get(z, "jour"))] as Dictionary)["key"]
	var ped := GearUi.pedestal(light_col, 620, 150)
	ped.position = Vector2((CARD.x - 620) * 0.5, 838)
	ped.size = Vector2(620, 150)
	root.add_child(ped)
	var img := hero_image(z, pose)
	var hero := TextureRect.new()
	hero.texture = ImageTexture.create_from_image(img)
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_SCALE
	var sc := 17.0
	hero.size = Vector2(HeroModel.W, HeroModel.H) * sc
	hero.position = Vector2((float(CARD.x) - hero.size.x) * 0.5, 930.0 - hero.size.y + 2.0 * sc)
	root.add_child(hero)
	# Nom, race, classe, niveau, Puissance.
	var pname := "Invité"
	if Cloud.instance != null and Cloud.instance.username != "":
		pname = Cloud.instance.username
	var n := _text(pname.to_upper(), 86, UiTheme.TEXT, true)
	n.position = Vector2(0, 968)
	n.size = Vector2(CARD.x, 96)
	root.add_child(n)
	var cname := str((party["classes"] as Dictionary).get(Profile.player_class(), {}).get("name", ""))
	var rname := str((party["races"] as Dictionary).get(Profile.race(), {}).get("name", ""))
	var sub := _text("%s · %s · Niveau %d" % [rname, cname, Profile.level()], 34, UiTheme.TEAL, false)
	sub.position = Vector2(0, 1062)
	sub.size = Vector2(CARD.x, 44)
	root.add_child(sub)
	var pw := _text("PUISSANCE %d" % Profile.power(), 52, UiTheme.GOLD, true)
	pw.position = Vector2(0, 1108)
	pw.size = Vector2(CARD.x, 64)
	root.add_child(pw)
	# Objets portés.
	var eq := Profile.equipment_of("player")
	var slots := ["weapon", "offhand", "head", "armor", "hands", "feet", "amulet", "charm"]
	var shown: Array = []
	for slot in slots:
		var it := Profile.find_item(str(eq.get(slot, "")))
		if not it.is_empty():
			shown.append(it)
	var px := 92.0
	var gap := 14.0
	var x0 := (float(CARD.x) - (px * float(shown.size()) + gap * float(maxi(0, shown.size() - 1)))) * 0.5
	for i in range(shown.size()):
		var it: Dictionary = shown[i]
		var rc := Profile.item_color(it)
		var box := Panel.new()
		box.add_theme_stylebox_override("panel", UiTheme.box(Color(rc.darkened(0.8), 0.9), Color(rc, 0.95), 14, 3, 0))
		box.position = Vector2(x0 + float(i) * (px + gap), 1190)
		box.size = Vector2(px, px)
		root.add_child(box)
		var ic := TextureRect.new()
		ic.texture = Icons.item(str(it.get("base", "")), str(Profile.items_db()["bases"].get(str(it.get("base", "")), {}).get("slot", "")), 96)
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.position = box.position + Vector2(8, 8)
		ic.size = Vector2(px - 16, px - 16)
		root.add_child(ic)
	# Kit de curiosités complet.
	var counts := Profile.cosmetic_kit_counts()
	for kit in counts.keys():
		if int(counts[kit]) >= 4:
			var kd: Dictionary = (Profile.cosmetics_db()["kits"] as Dictionary).get(kit, {})
			var kl := _text("Kit complet : %s" % str(kd.get("name", "")), 28, Color(str(kd.get("color", "e0a050"))), false)
			kl.position = Vector2(0, 186)
			kl.size = Vector2(CARD.x, 36)
			root.add_child(kl)
	return root


static func _text(s: String, sz: int, col: Color, title: bool) -> Label:
	var l := UiTheme.title(s, sz, col) if title else UiTheme.label(s, sz, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("outline_size", maxi(6, sz / 6))
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.9))
	return l


func _save() -> void:
	_status.text = "Préparation de l'image…"
	await RenderingServer.frame_post_draw
	var img := _vp.get_texture().get_image()
	if img == null or img.is_empty():
		_status.text = "Image indisponible sur cet appareil."
		return
	var png := img.save_png_to_buffer()
	var fname := "arcane-surge-%s.png" % Profile.player_class()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(png, fname, "image/png")
		_status.text = "Image téléchargée : %s" % fname
	else:
		var path := "user://" + fname
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			_status.text = "Impossible d'enregistrer l'image."
			return
		f.store_buffer(png)
		f.close()
		_status.text = "Image enregistrée : %s" % ProjectSettings.globalize_path(path)
