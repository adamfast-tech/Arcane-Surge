class_name GearUi
extends RefCounted
## Briques visuelles de l'Équipement et de la Forge (docs/design/35-equipement-runes-forge.md) : cases d'objet
## (cadre et lueur à la couleur de la rareté, niveau d'amélioration, runes, flèche « meilleur »), cases de rune,
## pastilles de stats, jauge d'amélioration, socle lumineux, bandeau d'un personnage qui parle.

## Couleur de chaque stat.
const STAT_COL := {"pou": Color("ff9b4a"), "vig": Color("6fe39a"), "esp": Color("b07cff"), "cel": Color("6fdccf"), "des": Color("f2c46b")}
const STAT_ABBR := {"pou": "POU", "vig": "VIG", "esp": "ESP", "cel": "CÉL", "des": "DES"}
const ROMAN := ["", "I", "II", "III", "IV", "V", "VI"]


## Case d'objet cliquable : vide (silhouette de l'emplacement) ou objet (icône, « +N », runes, flèche verte s'il
## existe mieux en réserve). « tag » : petite mention en bas (« porté »…).
static func item_button(it: Dictionary, slot: String, px: int, selected: bool = false, better: int = 0, tag: String = "",
		dim: bool = false) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(px, px)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var empty := it.is_empty()
	var col := Color(UiTheme.MUTED, 0.35) if empty else Profile.item_color(it)
	var bg := Color("0a1019") if empty else Color(col.darkened(0.82), 0.96)
	var bd := UiTheme.GOLD if selected else (Color(col, 0.9) if not empty else Color(UiTheme.BORDER, 0.8))
	var acc := UiTheme.GOLD if selected else Color(0, 0, 0, 0)
	var w := 3 if selected else 2
	b.add_theme_stylebox_override("normal", UiTheme.box(bg, bd, 12, w, 0, acc))
	b.add_theme_stylebox_override("hover", UiTheme.box(bg.lightened(0.06), UiTheme.GOLD if selected else UiTheme.TEAL, 12, w, 0, acc))
	b.add_theme_stylebox_override("pressed", UiTheme.box(bg.darkened(0.3), UiTheme.GOLD, 12, w, 0, acc))
	b.add_theme_stylebox_override("hover_pressed", UiTheme.box(bg.darkened(0.3), UiTheme.GOLD, 12, w, 0, acc))
	b.add_theme_stylebox_override("disabled", UiTheme.box(Color(bg, 0.6), Color(bd, 0.4), 12, w, 0))
	b.pressed.connect(Snd.click)
	if not empty:
		# Lueur de la rareté au fond de la case.
		b.add_child(_glow(col, 0.35 if not dim else 0.12))
	var base := str(it.get("base", "")) if not empty else str(Icons.SLOT_ICON.get(slot, "rune"))
	var ic := TextureRect.new()
	ic.texture = Icons.item(base, slot, px * 2) if not empty else Icons.tex(base, px * 2)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := float(px) * 0.16
	ic.offset_left = m
	ic.offset_top = m
	ic.offset_right = -m
	ic.offset_bottom = -m - (float(px) * 0.08 if not empty and Profile.sockets_of(it) > 0 else 0.0)
	if empty:
		ic.modulate = Color(UiTheme.MUTED, 0.28)
	else:
		ic.modulate = (Color.WHITE if Icons.item_colored(base) else col) * (Color(0.5, 0.5, 0.55, 0.7) if dim else Color.WHITE)
	b.add_child(ic)
	if not empty:
		var up := int(it.get("up", 0))
		if up > 0:
			var pl := pill("+%d" % up, UiTheme.GOLD, maxi(13, px / 6))
			b.add_child(pl)
			pl.position = Vector2(float(px) - pl.get_combined_minimum_size().x - 4.0, 4.0)
		if Profile.sockets_of(it) > 0:
			var so := ForgeScreen.sockets_row(it, maxi(8, px / 9))
			b.add_child(so)
			var sw := so.get_combined_minimum_size()
			so.size = sw
			so.position = Vector2((float(px) - sw.x) * 0.5, float(px) - sw.y - 6.0)
	if better > 0:
		var ar := UiTheme.icon_rect("up", maxi(14, px / 4), UiTheme.GOOD)
		ar.position = Vector2(4.0, 4.0)
		b.add_child(ar)
	if tag != "":
		var tl := UiTheme.label(tag, maxi(12, px / 7), UiTheme.TEAL)
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tl.position = Vector2(6.0, 4.0)
		b.add_child(tl)
	return b


## Case de rune cliquable : la gemme, son niveau en chiffres romains, cadre à la couleur de sa rareté.
static func rune_button(r: Dictionary, px: int, selected: bool = false, dim: bool = false) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(px, px)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var col := Profile.item_color(r)
	var bg := Color(Profile.rune_color(r).darkened(0.85), 0.96)
	var bd := UiTheme.GOLD if selected else Color(col, 0.85)
	var acc := UiTheme.GOLD if selected else Color(0, 0, 0, 0)
	var w := 3 if selected else 2
	b.add_theme_stylebox_override("normal", UiTheme.box(bg, bd, 12, w, 0, acc))
	b.add_theme_stylebox_override("hover", UiTheme.box(bg.lightened(0.06), UiTheme.GOLD if selected else UiTheme.TEAL, 12, w, 0, acc))
	b.add_theme_stylebox_override("pressed", UiTheme.box(bg.darkened(0.3), UiTheme.GOLD, 12, w, 0, acc))
	b.add_theme_stylebox_override("disabled", UiTheme.box(Color(bg, 0.5), Color(bd, 0.35), 12, w, 0))
	b.pressed.connect(Snd.click)
	b.add_child(_glow(Profile.rune_color(r), 0.4 if not dim else 0.1))
	var ic := TextureRect.new()
	ic.texture = ItemArt.rune(str(r["rune"]), int(r["level"]), px * 2)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := float(px) * 0.14
	ic.offset_left = m
	ic.offset_top = m
	ic.offset_right = -m
	ic.offset_bottom = -m
	if dim:
		ic.modulate = Color(0.5, 0.5, 0.55, 0.6)
	b.add_child(ic)
	b.add_child(corner(pill(str(ROMAN[clampi(int(r["level"]), 0, 6)]), Profile.rune_color(r), maxi(12, px / 6)), 7))
	return b


## Place un contrôle dans le coin bas-droit de son parent (des conteneurs : la taille réelle est prise en compte).
static func corner(c: Control, margin: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		m.add_theme_constant_override(k, margin)
	c.size_flags_horizontal = Control.SIZE_SHRINK_END
	c.size_flags_vertical = Control.SIZE_SHRINK_END
	m.add_child(c)
	return m


## Bourse : or et poussière, chacun avec son icône.
static func purse() -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.WARM, 0.9), Color(UiTheme.GOLD, 0.45), 10, 1, 8))
	pc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	pc.add_child(v)
	for row in [["coin", "%d" % Profile.gold(), UiTheme.GOLD], ["dust", "%d" % Profile.dust(), UiTheme.VIOLET]]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		h.alignment = BoxContainer.ALIGNMENT_END
		v.add_child(h)
		h.add_child(UiTheme.label(str(row[1]), 20, row[2]))
		h.add_child(UiTheme.icon_rect(str(row[0]), 20, row[2]))
	return pc


## Lueur ronde (dégradé radial) qui remplit son parent.
static func _glow(col: Color, a: float) -> TextureRect:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(col, a), Color(col, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.55)
	gt.fill_to = Vector2(0.5, 0.0)
	gt.width = 64
	gt.height = 64
	var t := TextureRect.new()
	t.texture = gt
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.offset_left = 4
	t.offset_top = 4
	t.offset_right = -4
	t.offset_bottom = -4
	return t


## Socle lumineux (ellipse qui s'estompe) sous un personnage.
static func pedestal(col: Color, w: float, h: float) -> TextureRect:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(col, 0.55), Color(col, 0.18), Color(col, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	gt.width = 128
	gt.height = 64
	var t := TextureRect.new()
	t.texture = gt
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.custom_minimum_size = Vector2(w, h)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Petite étiquette arrondie (« +3 », « III », « porté »).
static func pill(text: String, col: Color, fs: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiTheme.box(Color(0.03, 0.05, 0.08, 0.92), Color(col, 0.9), 6, 1, 2)
	sb.content_margin_left = 7.0
	sb.content_margin_right = 7.0
	p.add_theme_stylebox_override("panel", sb)
	var l := UiTheme.label(text, fs, col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


## Jauge d'amélioration : un losange par niveau, plein jusqu'au niveau atteint (au-delà de 10 niveaux : une
## barre dorée).
static func pips(up: int, max_up: int, px: int = 12) -> Control:
	if max_up > 10:
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = float(max_up)
		bar.value = float(up)
		bar.custom_minimum_size = Vector2(140, px - 2)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background", UiTheme.flat(Color(0, 0, 0, 0.45), Color(UiTheme.GOLD, 0.35), 3, 1))
		bar.add_theme_stylebox_override("fill", UiTheme.flat(UiTheme.GOLD, Color(0, 0, 0, 0), 3, 0))
		return bar
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(max_up):
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(px, px)
		d.color = UiTheme.GOLD if i < up else Color(UiTheme.MUTED, 0.25)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(px + 2, px + 2)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.position = Vector2(1, 1)
		d.pivot_offset = Vector2(px * 0.5, px * 0.5)
		d.rotation = PI * 0.25
		d.scale = Vector2(0.72, 0.72)
		holder.add_child(d)
		h.add_child(holder)
	return h


## Pastilles de stats (« +54 POU ») à la couleur de chaque stat ; « diff » : écarts colorés (+ vert, − rouge).
static func stat_chips(st: Dictionary, fs: int = 17, diff: bool = false) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 6)
	f.add_theme_constant_override("v_separation", 6)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in Profile.STATS:
		if not st.has(k):
			continue
		var v := int(st[k])
		var col: Color = STAT_COL[k] if not diff else (UiTheme.GOOD if v > 0 else UiTheme.DANGER)
		var p := PanelContainer.new()
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_theme_stylebox_override("panel", UiTheme.box(Color(col, 0.1), Color(col, 0.55), 8, 1, 5))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 5)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(h)
		var a := UiTheme.label(("+" if v > 0 else "−") + str(absi(v)), fs, col if diff else UiTheme.TEXT)
		a.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(a)
		var n := UiTheme.label(str(STAT_ABBR[k]), fs - 3, col)
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(n)
		f.add_child(p)
	return f


## Sprite pixel d'un personnage, agrandi au plus proche voisin.
static func figure(name: String, h: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = SpriteAtlas.single(name)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(h * 0.8, h)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Bandeau d'un personnage qui parle : portrait encadré, nom et titre, bulle de texte.
static func speaker_banner(who: String, name: String, title: String, line: String, line_col: Color = UiTheme.TEXT,
		accent: Color = Color(0, 0, 0, 0)) -> PanelContainer:
	var tint := accent if accent.a > 0.0 else Dialogues.color(who)
	var c: Array = UiTheme.card(Color(tint, 0.55), 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	(c[1] as VBoxContainer).add_child(h)
	var fr := PanelContainer.new()
	fr.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), Color(tint, 0.8), 10, 2, 4))
	fr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pt := TextureRect.new()
	pt.texture = PortraitArt.texture(who, "joie" if line_col == UiTheme.GOLD else "neutre")
	pt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pt.custom_minimum_size = Vector2(92, 92)
	fr.add_child(pt)
	h.add_child(fr)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var nr := HBoxContainer.new()
	nr.add_theme_constant_override("separation", 8)
	v.add_child(nr)
	nr.add_child(UiTheme.label(name.to_upper(), 21, tint))
	nr.add_child(UiTheme.label(title, 15, UiTheme.MUTED))
	var bub := PanelContainer.new()
	bub.add_theme_stylebox_override("panel", UiTheme.box(Color(0.04, 0.06, 0.1, 0.85), Color(UiTheme.BORDER, 0.9), 10, 1, 10))
	v.add_child(bub)
	bub.add_child(UiTheme.wrap("« %s »" % line, 17, line_col))
	return c[0]
