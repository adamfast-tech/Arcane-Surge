class_name CircleScreen
extends Control
## Le Cercle (docs/design/15-competences-bibliotheque-cercle.md et 14-interface.md) : les compagnons autour du feu.
## - la formation de combat : le héros au centre, les 2 compagnons emmenés à gauche et à droite (échanger les
##   côtés), ceux restés à Havre-Aube en retrait ;
## - un onglet par compagnon : niveau, XP, loyauté (amitié à 75 : +5 % de stats), puissance et équipement,
##   ordre par défaut, tir normal (troupes ou tir de classe) et sort emporté.

signal back
signal open_equipment(who: String)

var _who := "" ## compagnon affiché

## Ordre par défaut -> [icône, ce qu'il fait].
const ORDER_INFO := {"focus_nexus": ["target", "Attaque le Nexus ennemi"], "defends": ["champion", "Protège la Barrière"],
	"suis_moi": ["chevron", "Vise là où tu vises"], "libre": ["sparkle", "Décide seul"]}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.5, 0.0, "campfire", "cercle")
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var avail := Profile.companions_available()
	var active := Profile.active_companions()
	if _who == "" or not avail.has(_who):
		_who = active[0] if not active.is_empty() else (avail[0] if not avail.is_empty() else "")
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
	tv.add_child(UiTheme.title("TES COMPAGNONS AUTOUR DU FEU", 20, UiTheme.TEXT))
	if avail.is_empty():
		col.add_child(UiTheme.wrap("Personne n'a encore rejoint le Cercle.", 18, UiTheme.MUTED))
		return
	col.add_child(_formation(avail, active))
	col.add_child(UiTheme.wrap("En combat, un compagnon gagne 80 %% de ton XP ; resté à Havre-Aube, 30 %% (jamais plus de %d niveaux sous toi). En combat, toucher son médaillon change son ordre." % Profile.COMPANION_FLOOR, 15, UiTheme.MUTED))
	if avail.size() > 1:
		col.add_child(_tabs(avail, active))
	col.add_child(_sheet(_who, active.has(_who)))


# ---------------------------------------------------------------- formation

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


func _bot(who: String) -> Dictionary:
	for bd in GameData.party()["bots"]:
		if str(bd["id"]) == who:
			return bd
	return {}


## La formation autour du feu : le héros au centre, à gauche et à droite les compagnons emmenés.
func _formation(avail: Array[String], active: Array[String]) -> PanelContainer:
	var c: Array = UiTheme.card(Color(UiTheme.FIRE, 0.45), 10)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 6)
	var top := HBoxContainer.new()
	v.add_child(top)
	top.add_child(UiTheme.label("FORMATION DE COMBAT", 17, UiTheme.FIRE))
	top.add_child(UiTheme.spacer())
	var w := minf(680.0, get_viewport_rect().size.x - 36.0) - 24.0
	var camp := Camp.new()
	camp.custom_minimum_size = Vector2(w, 280)
	camp.anim = Profile.ambience_on()
	v.add_child(camp)
	var circ := Profile.circle()
	SpriteAtlas.set_player(Profile.look(), Profile.race(), Profile.player_class())
	var hero := GearUi.figure("player", 128)
	camp.add_child(hero)
	hero.size = hero.custom_minimum_size
	hero.position = Vector2(w * 0.5 - hero.size.x * 0.5, 40.0)
	var hl := _tag("TOI", UiTheme.TEAL)
	camp.add_child(hl)
	hl.position = Vector2(w * 0.5 - 22.0, 172.0)
	for who in active:
		var bd := _bot(who)
		var side := _side_of(who, bd, circ)
		var x := w * (0.2 if side == "left" else 0.8)
		var fb := _figure_button(who, 112.0)
		camp.add_child(fb)
		fb.position = Vector2(x - fb.custom_minimum_size.x * 0.5, 60.0)
		var tg := _tag("%s · %s" % ["GAUCHE" if side == "left" else "DROITE", Dialogues.display_name(who).to_upper()], Dialogues.color(who))
		camp.add_child(tg)
		tg.position = Vector2(x - 70.0, 196.0)
	camp.fire_at = Vector2(w * 0.5, 236.0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var sw := UiTheme.button("ÉCHANGER LES CÔTÉS", 17)
	sw.icon = Icons.tex("onde_arcanique", 40)
	sw.add_theme_constant_override("icon_max_width", 20)
	sw.custom_minimum_size = Vector2(0, 50)
	sw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sw.disabled = active.size() < 1
	sw.pressed.connect(func() -> void:
		Profile.set_circle("", "swap", not bool(circ.get("swap", false)))
		_save()
		_rebuild.call_deferred())
	row.add_child(sw)
	# Ceux qui restent à Havre-Aube.
	var home: Array[String] = []
	for who2 in avail:
		if not active.has(who2):
			home.append(who2)
	if not home.is_empty():
		var hr := HBoxContainer.new()
		hr.add_theme_constant_override("separation", 8)
		v.add_child(hr)
		hr.add_child(UiTheme.label("RESTENT À HAVRE-AUBE", 14, UiTheme.MUTED))
		for who3 in home:
			var pb := _portrait_button(who3, 44)
			hr.add_child(pb)
	return c[0]


func _tag(text: String, col: Color) -> PanelContainer:
	var p := GearUi.pill(text, col, 14)
	return p


## Figure d'un compagnon (son sprite) qu'on touche pour ouvrir sa fiche.
func _figure_button(who: String, h: float) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	for s in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	b.custom_minimum_size = Vector2(h * 0.9, h)
	b.size = b.custom_minimum_size
	var on := who == _who
	if on:
		b.add_child(GearUi._glow(Dialogues.color(who), 0.45))
	var fig := GearUi.figure(who, h)
	fig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(fig)
	b.pressed.connect(func() -> void:
		Snd.click()
		_who = who
		_rebuild.call_deferred())
	return b


func _portrait_button(who: String, px: int) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(px + 8, px + 8)
	var col := Dialogues.color(who)
	var on := who == _who
	b.add_theme_stylebox_override("normal", UiTheme.box(Color("0a1019"), Color(col, 0.9 if on else 0.45), 10, 2, 3, UiTheme.GOLD if on else Color(0, 0, 0, 0)))
	b.add_theme_stylebox_override("hover", UiTheme.box(Color("0a1019"), col, 10, 2, 3))
	b.add_theme_stylebox_override("pressed", UiTheme.box(Color("0a1019"), UiTheme.GOLD, 10, 2, 3))
	var pic := TextureRect.new()
	pic.texture = PortraitArt.texture(who, "neutre")
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pic.offset_left = 4
	pic.offset_top = 4
	pic.offset_right = -4
	pic.offset_bottom = -4
	b.add_child(pic)
	b.tooltip_text = Dialogues.display_name(who)
	b.pressed.connect(func() -> void:
		Snd.click()
		_who = who
		_rebuild.call_deferred())
	return b


## Un onglet par compagnon : portrait, nom, niveau.
func _tabs(avail: Array[String], active: Array[String]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var ordered: Array[String] = []
	for who in active:
		ordered.append(who)
	for who in avail:
		if not ordered.has(who):
			ordered.append(who)
	for who in ordered:
		var on := who == _who
		var col := Dialogues.color(who)
		var rb: Array = UiTheme.rich_button(64, "primary" if on else "tile")
		var bt: Button = rb[0]
		var h: HBoxContainer = rb[1]
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 8)
		var pic := TextureRect.new()
		pic.texture = PortraitArt.texture(who, "neutre")
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.custom_minimum_size = Vector2(40, 40)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(pic)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(v)
		v.add_child(UiTheme.label(Dialogues.display_name(who), 18, col if on else UiTheme.TEXT))
		v.add_child(UiTheme.label("niv. %d%s" % [Profile.companion_level(who), "" if active.has(who) else " · Havre-Aube"], 13, UiTheme.MUTED))
		bt.pressed.connect(func() -> void:
			Snd.click()
			_who = who
			_rebuild.call_deferred())
		row.add_child(bt)
	return row


# ---------------------------------------------------------------- fiche d'un compagnon

func _sheet(who: String, is_active: bool) -> PanelContainer:
	var bd := _bot(who)
	var circ := Profile.circle()
	var mine: Dictionary = circ.get(who, {})
	var col := Dialogues.color(who)
	var party := GameData.party()
	var cls := Profile.companion_class(who)
	var c: Array = UiTheme.card(Color(col, 0.6), 14)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 12)
	# En-tête : portrait, nom, race, voie, niveau, côté.
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), Color(col, 0.85), 12, 2, 4))
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(frame)
	var pic := TextureRect.new()
	pic.texture = PortraitArt.texture(who, "joie" if Story.loyalty(who) >= 75 else "neutre")
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(104, 104)
	frame.add_child(pic)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var nr := HBoxContainer.new()
	nr.add_theme_constant_override("separation", 10)
	info.add_child(nr)
	nr.add_child(UiTheme.title(str(bd.get("name", who)).to_upper(), 30, col))
	var side := _side_of(who, bd, circ)
	nr.add_child(GearUi.pill(("À GAUCHE" if side == "left" else "À DROITE") if is_active else "À HAVRE-AUBE", UiTheme.TEAL if is_active else UiTheme.MUTED, 13))
	var lv := Profile.companion_level(who)
	info.add_child(UiTheme.label("%s · %s · niveau %d" % [str(party["races"].get(str(bd.get("race", "")), {}).get("name", "")),
		str(party["classes"].get(cls, {}).get("name", "")), lv], 17, UiTheme.MUTED))
	if Profile.companion_role(who) != "":
		info.add_child(UiTheme.wrap(Profile.companion_role(who), 15, UiTheme.TEXT))
	# Jauges : XP et loyauté (repère d'amitié à 75).
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 6)
	v.add_child(g)
	g.add_child(UiTheme.label("XP", 15, UiTheme.CYAN))
	var xb := UiTheme.bar(UiTheme.CYAN, 8)
	xb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xb.max_value = Profile.xp_to_next(lv)
	xb.value = Profile.companion_xp(who)
	g.add_child(xb)
	g.add_child(UiTheme.label("%d / %d" % [Profile.companion_xp(who), Profile.xp_to_next(lv)], 14, UiTheme.MUTED))
	var loy := Story.loyalty(who)
	g.add_child(UiTheme.label("Loyauté", 15, col))
	var lb := Loyalty.new()
	lb.value = float(loy) / 100.0
	lb.col = col
	lb.custom_minimum_size = Vector2(0, 16)
	lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	g.add_child(lb)
	g.add_child(UiTheme.label("%d / 100" % loy, 14, UiTheme.MUTED))
	v.add_child(UiTheme.label("Amitié active : +5 % de stats" if loy >= 75 else "Amitié à 75 de loyauté : +5 % de stats (repère doré)", 15, UiTheme.GOOD if loy >= 75 else UiTheme.MUTED))
	# Puissance et équipement.
	var er := HBoxContainer.new()
	er.add_theme_constant_override("separation", 10)
	v.add_child(er)
	var pw := PanelContainer.new()
	pw.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.WARM, 0.9), Color(UiTheme.GOLD, 0.45), 10, 1, 8))
	pw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pwh := HBoxContainer.new()
	pwh.add_theme_constant_override("separation", 6)
	pw.add_child(pwh)
	pwh.add_child(UiTheme.icon_rect("champion", 20, UiTheme.GOLD))
	pwh.add_child(UiTheme.label("Puissance %d" % Profile.companion_power(who), 18, UiTheme.GOLD))
	er.add_child(pw)
	var n_eq := Profile.equipment_of(who).size()
	var el := UiTheme.label("%d objet%s équipé%s" % [n_eq, "s" if n_eq > 1 else "", "s" if n_eq > 1 else ""], 15, UiTheme.MUTED)
	el.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	er.add_child(el)
	var eb := UiTheme.button("ÉQUIPEMENT", 17)
	eb.icon = Icons.tex("forge", 40)
	eb.add_theme_constant_override("icon_max_width", 20)
	eb.custom_minimum_size = Vector2(170, 50)
	eb.add_theme_color_override("font_color", col)
	eb.add_theme_color_override("icon_normal_color", col)
	eb.pressed.connect(func() -> void: open_equipment.emit(who))
	er.add_child(eb)
	if not Profile.meditation_unlocked():
		v.add_child(UiTheme.label("Voie fixe jusqu'à la Salle de méditation (fin de l'acte 1).", 14, UiTheme.MUTED))
	# Emmener au combat (à la place d'un compagnon emmené).
	if not is_active:
		v.add_child(UiTheme.section("Emmener au combat", col))
		var rg := HBoxContainer.new()
		rg.add_theme_constant_override("separation", 8)
		v.add_child(rg)
		for other in Profile.active_companions():
			var rb := UiTheme.button("À la place de %s" % Dialogues.display_name(other), 17)
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
	v.add_child(UiTheme.section("Ordre par défaut", col))
	var og := GridContainer.new()
	og.columns = 2
	og.add_theme_constant_override("h_separation", 8)
	og.add_theme_constant_override("v_separation", 8)
	v.add_child(og)
	for o in BattleSim.ORDERS:
		var oid := str(o)
		var info2: Array = ORDER_INFO.get(oid, ["sparkle", ""])
		var on: bool = str(mine.get("order", bd.get("order", "libre"))) == oid
		og.add_child(_option(str(info2[0]), str(BattleSim.ORDER_LABELS[o]), str(info2[1]), on, col, func() -> void:
			Profile.set_circle(who, "order", oid)
			_save()
			_rebuild.call_deferred()))
	# Tir normal (docs/design/42-tirs-de-classe.md) : ses troupes, ou le tir de sa classe.
	v.add_child(UiTheme.section("Tir normal", col))
	var fg := GridContainer.new()
	fg.columns = 2
	fg.add_theme_constant_override("h_separation", 8)
	v.add_child(fg)
	var fam := str((party["classes"].get(cls, {}) as Dictionary).get("familiar", ""))
	var fam_name := str((GameData.units().get(fam, {}) as Dictionary).get("name", "ses troupes"))
	var fire_now := str(mine.get("fire", "troupes"))
	var ult := str((party["classes"].get(cls, {}) as Dictionary).get("ultimate", "target"))
	fg.add_child(_option("circle", "Troupes", "%s : elles tiennent le terrain" % fam_name, fire_now == "troupes", col, func() -> void:
		Profile.set_circle(who, "fire", "troupes")
		_save()
		_rebuild.call_deferred()))
	fg.add_child(_option(ult, "Tir de classe", "%s : plus fort, plus loin" % _cap(str(ClassFire.LABEL.get(cls, ""))), fire_now == "classe", col, func() -> void:
		Profile.set_circle(who, "fire", "classe")
		_save()
		_rebuild.call_deferred()))
	# Sort emporté.
	v.add_child(UiTheme.section("Sort emporté", col))
	var sg := GridContainer.new()
	sg.columns = 2
	sg.add_theme_constant_override("h_separation", 8)
	sg.add_theme_constant_override("v_separation", 8)
	v.add_child(sg)
	for sid in Profile.companion_spells(who):
		var sp: Dictionary = GameData.spells().get(str(sid), {})
		var spell := str(sid)
		var sub := "%d mana · recharge %d s" % [int(sp.get("mana", 0)), int(sp.get("cd", 0))]
		var tile := _option(spell, str(sp.get("name", sid)), sub, str(mine.get("spell", "")) == spell, Color(str(sp.get("color", "6fdccf"))), func() -> void:
			Profile.set_circle(who, "spell", spell)
			SpellAudio.preview(spell)
			_save()
			_rebuild.call_deferred())
		tile.tooltip_text = str(sp.get("desc", ""))
		sg.add_child(tile)
	return c[0]


## Option à toucher : icône dans un médaillon, titre et ligne d'explication ; cadre à la couleur quand choisie.
func _option(icon: String, title: String, sub: String, on: bool, col: Color, act: Callable) -> Button:
	var rb: Array = UiTheme.rich_button(68, "tile")
	var bt: Button = rb[0]
	var h: HBoxContainer = rb[1]
	h.add_theme_constant_override("separation", 10)
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if on:
		bt.add_theme_stylebox_override("normal", UiTheme.box(Color(col.darkened(0.82), 0.96), col, 12, 2, 8, col))
		bt.add_theme_stylebox_override("hover", UiTheme.box(Color(col.darkened(0.78), 0.96), col, 12, 2, 8, col))
	var md := PanelContainer.new()
	md.mouse_filter = Control.MOUSE_FILTER_IGNORE
	md.custom_minimum_size = Vector2(44, 44)
	md.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	md.add_theme_stylebox_override("panel", UiTheme.box(Color(0.03, 0.05, 0.08, 0.9), Color(col, 0.8 if on else 0.35), 22, 2, 6))
	md.add_child(UiTheme.icon_rect(icon, 24, col if on else Color(col, 0.7)))
	h.add_child(md)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := UiTheme.label(title, 17, col if on else UiTheme.TEXT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	var s := UiTheme.label(sub, 13, UiTheme.MUTED)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.custom_minimum_size = Vector2(10, 0)
	v.add_child(s)
	if on:
		h.add_child(UiTheme.icon_rect("check", 20, col))
	bt.pressed.connect(func() -> void:
		Snd.click()
		act.call())
	return bt


static func _cap(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)


func _save() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()


# ---------------------------------------------------------------- dessins

## Le feu de camp au centre de la formation : lueur au sol, bûches, flammes et étincelles.
class Camp extends Control:
	var fire_at := Vector2.ZERO
	var anim := true
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		set_process(anim)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var f := fire_at
		var fl := 1.0 + 0.06 * sin(_t * 9.0) + 0.04 * sin(_t * 23.0)
		# Lueur au sol.
		for k in range(6):
			var r := (240.0 - float(k) * 34.0) * fl
			_ellipse(f + Vector2(0, 6), r, r * 0.28, Color(1.0, 0.55, 0.2, 0.05 + 0.025 * float(k)))
		# Ombres des personnages.
		for x in [0.2, 0.5, 0.8]:
			_ellipse(Vector2(size.x * float(x), 170.0), 46.0, 10.0, Color(0, 0, 0, 0.35))
		# Bûches.
		draw_line(f + Vector2(-30, 8), f + Vector2(30, -2), Color("4a2e1a"), 9.0)
		draw_line(f + Vector2(-30, -2), f + Vector2(30, 8), Color("5a3820"), 9.0)
		# Flammes : trois langues qui ondulent.
		for k in range(3):
			var sx := float(k - 1) * 11.0
			var hgt := (34.0 - absf(sx)) * fl + 6.0 * sin(_t * 7.0 + float(k) * 2.0)
			var col: Color = [Color("ff6a2a"), Color("ffb44a"), Color("ff8a3a")][k]
			var pts := PackedVector2Array([f + Vector2(sx - 11, 2), f + Vector2(sx + sin(_t * 6.0 + float(k)) * 4.0, -hgt), f + Vector2(sx + 11, 2)])
			draw_colored_polygon(pts, Color(col, 0.9))
		draw_colored_polygon(PackedVector2Array([f + Vector2(-6, 2), f + Vector2(sin(_t * 8.0) * 2.0, -18.0 * fl), f + Vector2(6, 2)]), Color("fff0b0"))
		# Étincelles.
		for i in range(10):
			var ph := float(i) * 1.7
			var life := fposmod(_t * 0.6 + ph * 0.37, 1.0)
			var p := f + Vector2(sin(ph * 3.1 + _t) * 18.0 * life, -20.0 - life * 120.0)
			draw_circle(p, 1.8, Color(1.0, 0.7, 0.3, 1.0 - life))

	func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in range(32):
			var a := float(i) / 32.0 * TAU
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, col)


## Jauge de loyauté avec le repère d'amitié (75).
class Loyalty extends Control:
	var value := 0.0
	var col := Color.WHITE

	func _draw() -> void:
		var r := Rect2(Vector2(0, size.y * 0.5 - 5.0), Vector2(size.x, 10.0))
		draw_rect(r, Color(0, 0, 0, 0.45))
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(value, 0.0, 1.0), r.size.y)), col)
		var mx := size.x * 0.75
		draw_line(Vector2(mx, 0), Vector2(mx, size.y), Color("f2c46b"), 2.0)
		draw_circle(Vector2(mx, 2), 3.0, Color("f2c46b"))
