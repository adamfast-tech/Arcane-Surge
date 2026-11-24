class_name UiTheme
extends RefCounted
## Palette, police et thème de l'interface (voir docs/design/08-ui-ux.md).

const BG := Color("0b111a")
const PANEL := Color("101a26")
const PANEL2 := Color("162333")
const BORDER := Color("2b4153")
const TEXT := Color("e8eef5")
const MUTED := Color("8fa3b3")
## Icônes au trait et bordures actives (concept UI).
const TEAL := Color("6fdccf")
## Fond chaud des boutons principaux (bordure or).
const WARM := Color("1e1a12")
const GOLD := Color("f2c46b")
const CYAN := Color("4fe3d2")
const MANA := Color("5aa9ff")
const DANGER := Color("ff6b6b")
const GOOD := Color("6fe39a")
const NEXUS := Color("c2456b")
const MAGENTA := Color("d93cf2")
const VIOLET := Color("b07cff")
const FIRE := Color("ff9b4a")

static var _font: FontFile
static var _font_small: FontFile
static var _title_font: FontFile


## Police de l'interface et des chiffres (Jersey 10 : chiffres nets, accents).
static func font() -> FontFile:
	if _font == null:
		_font = _load("res://assets/fonts/Jersey10-Regular.ttf")
	return _font


## Police fine pour les libellés longs dans l'arène (Jersey 15).
static func font_small() -> FontFile:
	if _font_small == null:
		_font_small = _load("res://assets/fonts/Jersey15-Regular.ttf")
	return _font_small


## Police des grands titres (Jersey 15 : en Pixelify Sans, « B » et « G » se confondaient).
static func title_font() -> FontFile:
	if _title_font == null:
		_title_font = _load("res://assets/fonts/Jersey15-Regular.ttf")
	return _title_font


static func _load(path: String) -> FontFile:
	var f: FontFile = load(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.hinting = TextServer.HINTING_LIGHT
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return f


## Cadre à coins coupés (RuneBox) : « radius » donne la taille du biseau.
static func box(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 12, border_w: int = 2, pad: int = 10, accent: Color = Color(0, 0, 0, 0)) -> StyleBox:
	var s := RuneBox.new()
	s.bg = bg
	s.border = border
	s.border_w = float(border_w) if border.a > 0.0 else 0.0
	s.cut = float(radius) * 0.75
	s.accent = accent
	s.set_content_margin_all(pad)
	return s


## Cadre rectangulaire simple (jauges).
static func flat(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 4, border_w: int = 1, pad: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w if border.a > 0.0 else 0)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	return s


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 26
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("normal", "Button", box(Color(PANEL2, 0.94), BORDER, 12, 2, 8))
	t.set_stylebox("hover", "Button", box(Color(PANEL2.lightened(0.06), 0.96), TEAL, 12, 2, 8))
	t.set_stylebox("pressed", "Button", box(Color(PANEL2.darkened(0.3), 0.96), GOLD, 12, 2, 8))
	t.set_stylebox("hover_pressed", "Button", box(Color(PANEL2.darkened(0.3), 0.96), GOLD, 12, 2, 8))
	t.set_stylebox("disabled", "Button", box(Color(PANEL2, 0.5), Color(BORDER, 0.55), 12, 2, 8))
	t.set_color("icon_normal_color", "Button", TEAL)
	t.set_color("icon_hover_color", "Button", Color("b8fff6"))
	t.set_color("icon_pressed_color", "Button", GOLD)
	t.set_color("icon_hover_pressed_color", "Button", GOLD)
	t.set_color("icon_focus_color", "Button", TEAL)
	t.set_color("icon_disabled_color", "Button", Color(MUTED, 0.45))
	t.set_constant("h_separation", "Button", 10)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_hover_pressed_color", "Button", GOLD)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color(MUTED, 0.7))
	t.set_stylebox("panel", "PanelContainer", box(Color(PANEL, 0.92), BORDER, 14, 2, 14))
	t.set_stylebox("panel", "Panel", box(Color(PANEL, 0.92), BORDER, 14, 2, 14))
	t.set_stylebox("background", "ProgressBar", flat(Color("0a1019"), BORDER, 2, 1, 0))
	t.set_stylebox("fill", "ProgressBar", flat(TEAL, Color(0, 0, 0, 0), 2, 0, 0))
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_hover_color", "CheckBox", TEXT)
	t.set_color("font_pressed_color", "CheckBox", GOLD)
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("normal", "LineEdit", box(Color("0a1019"), BORDER, 10, 2, 12))
	t.set_stylebox("focus", "LineEdit", box(Color("0a1019"), TEAL, 10, 2, 12))
	t.set_stylebox("read_only", "LineEdit", box(Color("0a1019"), BORDER, 10, 2, 12))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Color(MUTED, 0.7))
	t.set_color("caret_color", "LineEdit", CYAN)
	t.set_color("selection_color", "LineEdit", Color(CYAN, 0.35))
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 10)
	return t


static func label(text: String, size: int = 26, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, size: int = 24) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	return b


static func bar(color: Color, height: int = 16) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, height)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("fill", flat(color, Color(0, 0, 0, 0), 2, 0, 0))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static var _shine: ShaderMaterial


static func title(text: String, size: int = 40, color: Color = GOLD) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", title_font())
	if Profile.ambience_on() and size >= 26:
		# Titres dorés : halo, ombre portée et reflet qui passe (shader).
		if _shine == null:
			_shine = ShaderMaterial.new()
			_shine.shader = load("res://shaders/ui_title_shine.gdshader")
		l.material = _shine
		l.add_theme_color_override("font_shadow_color", Color(color, 0.22))
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 0)
		l.add_theme_constant_override("shadow_outline_size", 9)
		l.add_theme_color_override("font_outline_color", Color(color.darkened(0.8), 0.95))
		l.add_theme_constant_override("outline_size", 5)
	return l


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Fond commun des écrans hors combat : illustration assombrie (title.jpg, ou la scène de la salle générée
## par RoomArt quand scene est donné), voile, dégradé, ambiance.
## fade > 0 : le bas de l'écran s'assombrit en dégradé (lisibilité des textes sur l'illustration).
static func backdrop(parent: Control, dim: float = 0.62, fade: float = 0.0, mood: String = "dawn", scene: String = "") -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	art.name = "BackdropArt"
	if scene != "":
		art.texture = RoomArt.scene(scene, RoomArt.size_for(parent.get_viewport_rect().size))
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		art.texture = load("res://assets/art/title.jpg")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(BG, dim)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if fade > 0.0:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.5, 0.78, 1.0])
		g.colors = PackedColorArray([Color(BG, 0.0), Color(BG, 0.0), Color(BG, fade * 0.85), Color(BG, fade)])
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(0, 1)
		gt.width = 4
		gt.height = 256
		var fr := TextureRect.new()
		fr.texture = gt
		fr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fr.stretch_mode = TextureRect.STRETCH_SCALE
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(fr)
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if Profile.ambience_on():
		# Ambiance enrichie : l'illustration respire, rayons, brume, particules de la salle, vignette.
		var amb := Ambience.new()
		amb.mood = mood
		amb.art = art
		parent.add_child(amb)


## Change la scène de fond d'un écran déjà construit (carte : un décor par zone).
static func set_scene(parent: Control, scene: String) -> void:
	var art := parent.get_node_or_null("BackdropArt") as TextureRect
	if art != null:
		art.texture = RoomArt.scene(scene, RoomArt.size_for(parent.get_viewport_rect().size))


## Change l'ambiance d'un écran déjà construit (carte : une ambiance par zone).
static func set_mood(parent: Control, mood: String) -> void:
	for ch in parent.get_children():
		if ch is Ambience and (ch as Ambience).mood != mood:
			var amb := Ambience.new()
			amb.mood = mood
			amb.art = (ch as Ambience).art
			var at := ch.get_index()
			ch.queue_free()
			parent.add_child(amb)
			parent.move_child(amb, at)
			return


## Colonne centrée et défilante (largeur max 680 px) ; retourne le conteneur où ajouter le contenu.
static func scroll_column(parent: Control, max_w: float = 680.0, top: float = 24.0, center_v: bool = false) -> VBoxContainer:
	# Écran reconstruit (ex. après un clic) : on garde la position de défilement de l'ancienne liste.
	var keep := 0
	for ch in parent.get_children():
		if ch is ScrollContainer and ch.is_queued_for_deletion():
			keep = (ch as ScrollContainer).scroll_vertical
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if keep > 0:
		var bar := scroll.get_v_scroll_bar()
		var apply := func() -> void:
			if is_instance_valid(scroll):
				scroll.scroll_vertical = keep
		bar.changed.connect(apply)
		scroll.get_tree().create_timer(0.6).timeout.connect(func() -> void:
			if is_instance_valid(bar) and bar.changed.is_connected(apply):
				bar.changed.disconnect(apply))
	# Colonne centrée horizontalement, en haut de l'écran (ou au milieu si center_v).
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", int(top))
	margin.add_theme_constant_override("margin_bottom", 32)
	margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER if center_v else Control.SIZE_SHRINK_BEGIN
	center.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(minf(max_w, parent.get_viewport_rect().size.x - 36.0), 0)
	margin.add_child(v)
	return v


static func wrap(text: String, size: int = 20, color: Color = MUTED) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	return l


static func card(border: Color = BORDER, pad: int = 14) -> Array:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", box(Color(PANEL, 0.93), border, 14, 2, pad))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	return [pc, v]


static func star_row(n: int, size: int = 26) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	for i in range(3):
		h.add_child(icon_rect("star", size, GOLD if i < n else Color(MUTED, 0.35)))
	return h


# ---------------------------------------------------------------- briques du concept UI

## Icône au trait, teintée.
static func icon_rect(name: String, px: int, color: Color = TEAL) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Icons.tex(name, px * 2)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.modulate = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Bouton à contenu libre : retourne [Button, HBoxContainer] (mettre le contenu dans la boîte).
## style : « primary » (fond chaud, bordure or), « tile » (bordure sarcelle au survol), « plain ».
static func rich_button(min_h: float, style: String = "tile") -> Array:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, min_h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := Color(PANEL, 0.9)
	var bd := BORDER
	var hov := TEAL
	var acc := Color(0, 0, 0, 0)
	if style == "primary":
		bg = Color(WARM, 0.94)
		bd = Color(GOLD, 0.85)
		hov = GOLD
		acc = GOLD
	b.add_theme_stylebox_override("normal", box(bg, bd, 14, 2, 0, acc))
	b.add_theme_stylebox_override("hover", box(bg.lightened(0.05), hov, 14, 2, 0, acc))
	b.add_theme_stylebox_override("pressed", box(bg.darkened(0.3), GOLD, 14, 2, 0, acc))
	b.add_theme_stylebox_override("hover_pressed", box(bg.darkened(0.3), GOLD, 14, 2, 0, acc))
	b.add_theme_stylebox_override("disabled", box(Color(bg, 0.5), Color(bd, 0.5), 14, 2, 0))
	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 20)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 12)
	b.add_child(m)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 14)
	m.add_child(h)
	return [b, h]


## Bouton « ‹ Havre-Aube » (retour).
static func back_button(text: String) -> Button:
	var b := button(text, 22)
	b.icon = Icons.tex("back", 40)
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", 20)
	b.custom_minimum_size = Vector2(0, 56)
	return b


## Titre de section discret (« PROCHAINEMENT », « ÉQUIPÉ · 3 OBJETS »).
static func section(text: String, color: Color = MUTED) -> Label:
	if not Profile.ambience_on():
		return label(text.to_upper(), 18, color)
	# Ambiance enrichie : un losange devant, un filet qui s'efface derrière.
	var l := label("     " + text.to_upper(), 18, color)
	var h := l.get_minimum_size().y
	var tw := font().get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var dia := ColorRect.new()
	dia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dia.color = color.lightened(0.2)
	dia.size = Vector2(8, 8)
	dia.pivot_offset = Vector2(4, 4)
	dia.rotation = PI * 0.25
	dia.position = Vector2(4, h * 0.5 - 4.0)
	l.add_child(dia)
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(color, 0.7), Color(color, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 128
	gt.height = 2
	var line := TextureRect.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.texture = gt
	line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	line.stretch_mode = TextureRect.STRETCH_SCALE
	line.anchor_right = 1.0
	line.offset_left = tw + 14.0
	line.offset_top = h * 0.5 - 1.0
	line.offset_bottom = h * 0.5 + 1.0
	l.add_child(line)
	return l


## Or et poussière, alignés à droite.
static func currencies() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := label("%d or" % Profile.gold(), 22, GOLD)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(g)
	var d := label("%d poussière" % Profile.dust(), 18, MUTED)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(d)
	return v


## Fine ligne horizontale.
static func rule(color: Color = BORDER) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(10, 2)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
