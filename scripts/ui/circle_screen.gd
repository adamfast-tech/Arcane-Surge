class_name CircleScreen
extends Control
## Le Cercle : réglages des compagnons pour les prochaines parties (les 2 emmenés en combat,
## ordre par défaut, sort emporté, côtés), loyauté et bonus d'amitié (+5 % de stats à partir de 75).

signal back


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.68)
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 14)
	var head := HBoxContainer.new()
	col.add_child(head)
	var b := UiTheme.back_button("Havre-Aube")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("LE CERCLE", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title("TES COMPAGNONS", 22, UiTheme.TEXT))
	var avail := Profile.companions_available()
	var active := Profile.active_companions()
	var intro := "Réglages des prochaines parties. Les compagnons ont ton niveau − 1. En combat, toucher un compagnon change encore son ordre."
	if avail.size() > Profile.ACTIVE_MAX:
		intro = "Tu emmènes %d compagnons en combat ; les autres restent à Havre-Aube. " % Profile.ACTIVE_MAX + intro
	col.add_child(UiTheme.wrap(intro, 18, UiTheme.MUTED))
	var party := GameData.party()
	var circ := Profile.circle()
	for bd in party["bots"]:
		if avail.has(str(bd["id"])) and active.has(str(bd["id"])):
			col.add_child(_companion_card(bd, circ, true))
	for bd in party["bots"]:
		if avail.has(str(bd["id"])) and not active.has(str(bd["id"])):
			col.add_child(_companion_card(bd, circ, false))
	var sw := UiTheme.button("Échanger les côtés", 20)
	sw.icon = Icons.tex("onde_arcanique", 40)
	sw.add_theme_constant_override("icon_max_width", 20)
	sw.custom_minimum_size = Vector2(0, 60)
	sw.pressed.connect(func() -> void:
		Profile.set_circle("", "swap", not bool(circ.get("swap", false)))
		_save()
		_rebuild.call_deferred())
	col.add_child(sw)


## Côté du compagnon en combat : à deux, le premier (ordre du groupe) à gauche, le second à droite.
func _side_of(who: String, bd: Dictionary, circ: Dictionary) -> String:
	var side := str(bd.get("side", "left"))
	var act := Profile.active_companions()
	if act.size() == 2:
		var order: Array[String] = []
		for b in GameData.party()["bots"]:
			if act.has(str(b["id"])):
				order.append(str(b["id"]))
		side = "left" if order.find(who) == 0 else "right"
	if bool(circ.get("swap", false)):
		side = "right" if side == "left" else "left"
	return side


func _companion_card(bd: Dictionary, circ: Dictionary, is_active: bool = true) -> PanelContainer:
	var who := str(bd.get("id", ""))
	var mine: Dictionary = circ.get(who, {})
	var col := Dialogues.color(who)
	var party := GameData.party()
	var c: Array = UiTheme.card(Color(col, 0.6) if is_active else UiTheme.BORDER, 16)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 10)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), Color(col, 0.8), 10, 2, 4))
	h.add_child(frame)
	var pic := TextureRect.new()
	pic.texture = PortraitArt.texture(who, "joie" if Story.loyalty(who) >= 75 else "neutre")
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.custom_minimum_size = Vector2(64, 64)
	frame.add_child(pic)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiTheme.title(str(bd.get("name", who)).to_upper(), 28, col))
	var side := _side_of(who, bd, circ)
	info.add_child(UiTheme.label("%s · %s · niveau %d · %s" % [str(party["races"].get(str(bd["race"]), {}).get("name", "")), str(party["classes"].get(str(bd["class"]), {}).get("name", "")),
		maxi(1, Profile.level() - 1), ("à gauche" if side == "left" else "à droite") if is_active else "reste à Havre-Aube"], 18, UiTheme.MUTED))
	if bd.has("role"):
		info.add_child(UiTheme.wrap(str(bd["role"]), 16, UiTheme.TEXT))
	var loy := Story.loyalty(who)
	var lr := HBoxContainer.new()
	lr.add_theme_constant_override("separation", 10)
	info.add_child(lr)
	lr.add_child(UiTheme.label("Loyauté %d" % loy, 17, UiTheme.TEXT))
	var bar := UiTheme.bar(col, 8)
	bar.max_value = 100
	bar.value = loy
	lr.add_child(bar)
	info.add_child(UiTheme.label("Amitié active : +5 % de stats" if loy >= 75 else "Amitié à 75 de loyauté : +5 % de stats", 16, UiTheme.GOOD if loy >= 75 else UiTheme.MUTED))
	if not is_active:
		# Remplacer un des compagnons emmenés.
		var rg := HBoxContainer.new()
		rg.add_theme_constant_override("separation", 8)
		v.add_child(rg)
		for other in Profile.active_companions():
			var rb := UiTheme.button("Remplacer %s" % Dialogues.display_name(other), 18)
			rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rb.custom_minimum_size = Vector2(0, 54)
			rb.add_theme_color_override("font_color", col)
			var replaced := other
			rb.pressed.connect(func() -> void:
				Profile.swap_active(who, replaced)
				_save()
				_rebuild.call_deferred())
			rg.add_child(rb)
	# Ordre par défaut.
	v.add_child(UiTheme.section("Ordre par défaut"))
	var og := GridContainer.new()
	og.columns = 4
	og.add_theme_constant_override("h_separation", 6)
	v.add_child(og)
	for o in BattleSim.ORDERS:
		var on: bool = str(mine.get("order", bd.get("order", "libre"))) == str(o)
		var ob := UiTheme.button(str(BattleSim.ORDER_LABELS[o]), 17)
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ob.custom_minimum_size = Vector2(0, 52)
		if on:
			ob.add_theme_color_override("font_color", col)
			ob.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), col, 10, 2, 6))
		var order := str(o)
		ob.pressed.connect(func() -> void:
			Profile.set_circle(who, "order", order)
			_save()
			_rebuild.call_deferred())
		og.add_child(ob)
	# Sort emporté.
	v.add_child(UiTheme.section("Sort"))
	var sg := HBoxContainer.new()
	sg.add_theme_constant_override("separation", 8)
	v.add_child(sg)
	for sid in Profile.COMPANION_SPELLS.get(who, []):
		var sp: Dictionary = GameData.spells().get(str(sid), {})
		var on := str(mine.get("spell", "")) == str(sid)
		var scol := Color(str(sp.get("color", "6fdccf")))
		var sb := UiTheme.button(str(sp.get("name", sid)), 18)
		sb.icon = Icons.tex(str(sid), 40)
		sb.add_theme_constant_override("icon_max_width", 22)
		sb.add_theme_color_override("icon_normal_color", scol)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.custom_minimum_size = Vector2(0, 56)
		if on:
			sb.add_theme_color_override("font_color", scol)
			sb.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), scol, 10, 2, 6))
		var spell := str(sid)
		sb.pressed.connect(func() -> void:
			Profile.set_circle(who, "spell", spell)
			_save()
			_rebuild.call_deferred())
		sg.add_child(sb)
	return c[0]


func _save() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
