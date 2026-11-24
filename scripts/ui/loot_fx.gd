class_name LootFx
extends RefCounted
## Fin de combat (ambiance enrichie) : chaque objet gagné apparaît l'un après l'autre, sur un faisceau de
## lumière à la couleur de sa rareté. Plus l'objet est rare, plus le faisceau est haut, et les objets
## épiques et légendaires jaillissent dans une gerbe d'étincelles.

## Hauteur du faisceau et nombre d'étincelles selon la rareté.
const POWER := {"commun": [36.0, 0], "rare": [70.0, 10], "epique": [105.0, 22], "legendaire": [150.0, 40]}

static var _beam_tex: Texture2D
static var _dot: Texture2D


## Ligne d'un objet gagné : icône sur son faisceau, nom et caractéristiques ; « idx » règle l'ordre d'apparition.
static func card(it: Dictionary, idx: int) -> Control:
	var col := Profile.item_color(it)
	var rar := str(it.get("rarity", "commun"))
	var pw: Array = POWER.get(rar, POWER["commun"])
	var delay := 0.35 + 0.45 * float(idx)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 58)
	# Socle de l'icône : le faisceau part de là.
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(54, 54)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(holder)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var beam := TextureRect.new()
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.texture = _beam()
	beam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	beam.stretch_mode = TextureRect.STRETCH_SCALE
	beam.material = add
	beam.modulate = Color(col, 0.0)
	beam.size = Vector2(40, float(pw[0]) + 40.0)
	beam.position = Vector2(7, 50.0 - beam.size.y)
	beam.pivot_offset = Vector2(20, beam.size.y)
	beam.scale = Vector2(1, 0)
	holder.add_child(beam)
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), col, 8, 2, 6))
	frame.position = Vector2(2, 2)
	frame.size = Vector2(50, 50)
	holder.add_child(frame)
	var base := Profile.base_of(it)
	var is_rune := it.has("rune")
	var ic := TextureRect.new()
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.texture = ItemArt.rune(str(it["rune"]), int(it.get("level", 1)), 40) if is_rune else Icons.item(str(it.get("base", "")), str(base.get("slot", "")), 40)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(36, 36)
	ic.modulate = Color.WHITE if is_rune or Icons.item_colored(str(it.get("base", ""))) else col
	frame.add_child(ic)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(v)
	var nm := UiTheme.label("Rune %s · %s" % [Profile.rune_name(it), str(Profile.rune_family(it).get("theme", ""))] if is_rune else Profile.item_name(it), 20, col)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(10, 0)
	v.add_child(nm)
	var detail := "sur une arme : %s" % Profile.rune_effect_text(it, "arme") if is_rune else Profile.stats_text(Profile.item_stats(it))
	var st := UiTheme.label("%s · %s" % [str(Profile.rarity_of(it).get("name", rar)), detail], 16, UiTheme.MUTED)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.custom_minimum_size = Vector2(10, 0)
	v.add_child(st)
	# Apparition : la ligne se dévoile, le faisceau jaillit, puis palpite.
	row.modulate = Color(1, 1, 1, 0)
	var tw := row.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(row, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(beam, "scale:y", 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(beam, "modulate:a", 0.95, 0.25)
	tw.tween_property(beam, "modulate:a", 0.55, 0.6)
	var pulse := beam.create_tween().set_loops()
	pulse.tween_interval(delay + 1.2)
	pulse.tween_property(beam, "modulate:a", 0.8, 1.1).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(beam, "modulate:a", 0.45, 1.1).set_trans(Tween.TRANS_SINE)
	if int(pw[1]) > 0:
		# Gerbe d'étincelles pour les objets rares et au-delà.
		var sp := CPUParticles2D.new()
		sp.texture = _soft()
		sp.material = add
		sp.position = Vector2(27, 27)
		sp.amount = int(pw[1])
		sp.one_shot = true
		sp.explosiveness = 0.9
		sp.lifetime = 0.9
		sp.direction = Vector2(0, -1)
		sp.spread = 70.0
		sp.initial_velocity_min = 60.0
		sp.initial_velocity_max = 150.0
		sp.gravity = Vector2(0, 160)
		sp.scale_amount_min = 0.12
		sp.scale_amount_max = 0.3
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(col, 0.9), Color(col, 0.0)])
		g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
		sp.color_ramp = g
		sp.emitting = false
		holder.add_child(sp)
		var go := sp.create_tween()
		go.tween_interval(delay + 0.1)
		go.tween_callback(func() -> void: sp.emitting = true)
	return row


static func _beam() -> Texture2D:
	if _beam_tex == null:
		# Faisceau : vertical, plus intense au pied, effacé sur les bords et en haut.
		var img := Image.create_empty(32, 64, false, Image.FORMAT_RGBA8)
		for y in range(64):
			var fy := float(y) / 63.0
			var va := pow(fy, 1.6)
			for x in range(32):
				var fx := absf(float(x) - 15.5) / 15.5
				var ha := pow(maxf(0.0, 1.0 - fx), 1.8)
				img.set_pixel(x, y, Color(1, 1, 1, clampf(va * ha, 0.0, 1.0)))
		_beam_tex = ImageTexture.create_from_image(img)
	return _beam_tex


static func _soft() -> Texture2D:
	if _dot == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 32
		t.height = 32
		_dot = t
	return _dot
