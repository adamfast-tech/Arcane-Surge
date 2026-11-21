class_name UiTheme
extends RefCounted
## Palette, police et thème de l'interface (voir docs/design/08-ui-ux.md).

const BG := Color("120e22")
const PANEL := Color("1e1838")
const PANEL2 := Color("2a2150")
const BORDER := Color("4a3d7a")
const TEXT := Color("ece8ff")
const MUTED := Color("a99fd0")
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


## Police des grands titres (Pixelify Sans).
static func title_font() -> FontFile:
	if _title_font == null:
		_title_font = _load("res://assets/fonts/PixelifySans.ttf")
	return _title_font


static func _load(path: String) -> FontFile:
	var f: FontFile = load(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.hinting = TextServer.HINTING_LIGHT
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return f


static func box(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 12, border_w: int = 2, pad: int = 10) -> StyleBoxFlat:
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
	t.set_stylebox("normal", "Button", box(PANEL2, BORDER, 12, 2, 8))
	t.set_stylebox("hover", "Button", box(PANEL2.lightened(0.08), CYAN, 12, 2, 8))
	t.set_stylebox("pressed", "Button", box(PANEL2.darkened(0.25), GOLD, 12, 2, 8))
	t.set_stylebox("hover_pressed", "Button", box(PANEL2.darkened(0.25), GOLD, 12, 2, 8))
	t.set_stylebox("disabled", "Button", box(Color(PANEL2, 0.55), Color(BORDER, 0.6), 12, 2, 8))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_hover_pressed_color", "Button", GOLD)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color(MUTED, 0.7))
	t.set_stylebox("panel", "PanelContainer", box(Color(PANEL, 0.95), BORDER, 14, 2, 14))
	t.set_stylebox("panel", "Panel", box(Color(PANEL, 0.95), BORDER, 14, 2, 14))
	t.set_stylebox("background", "ProgressBar", box(PANEL2, BORDER, 6, 1, 0))
	t.set_stylebox("fill", "ProgressBar", box(CYAN, Color(0, 0, 0, 0), 6, 0, 0))
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_hover_color", "CheckBox", TEXT)
	t.set_color("font_pressed_color", "CheckBox", GOLD)
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("normal", "LineEdit", box(Color("16122a"), BORDER, 10, 2, 12))
	t.set_stylebox("focus", "LineEdit", box(Color("16122a"), CYAN, 10, 2, 12))
	t.set_stylebox("read_only", "LineEdit", box(Color("16122a"), BORDER, 10, 2, 12))
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
	p.add_theme_stylebox_override("fill", box(color, Color(0, 0, 0, 0), 6, 0, 0))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func title(text: String, size: int = 40, color: Color = GOLD) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", title_font())
	return l


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Fond commun des écrans hors combat : illustration de la direction artistique, assombrie.
static func backdrop(parent: Control, dim: float = 0.62) -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	art.texture = load("res://assets/art/title.jpg")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.04, 0.12, dim)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Colonne centrée et défilante (largeur max 680 px) ; retourne le conteneur où ajouter le contenu.
static func scroll_column(parent: Control, max_w: float = 680.0, top: float = 24.0) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", int(top))
	margin.add_theme_constant_override("margin_bottom", 32)
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
		var tr := TextureRect.new()
		tr.texture = SpriteAtlas.single("star" if i < n else "star_off")
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(size, size)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(tr)
	return h
