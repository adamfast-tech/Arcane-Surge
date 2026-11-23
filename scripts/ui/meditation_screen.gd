class_name MeditationScreen
extends Control
## Salle de méditation (Sœur Aelis, Ordre de l'Aube ; docs/design/27-meditation-compagnons.md) :
## changer de voie (le héros et ses compagnons), 3 configurations enregistrées, réinitialisation
## de l'arbre et Harmonie (fait baisser la Corruption). Ouverte à la fin de l'acte 1.

signal back

const SHORT := {"mage": "Mage", "archer": "Archer", "epeiste": "Épéiste", "clerc": "Clerc", "necromancien": "Nécro",
	"chevalier": "Chevalier", "berserker": "Berserker"}
const AELIS := Color("f2e2b8")

var _msg := ""
var _reset_armed := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.66)
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
	head.add_child(UiTheme.spacer())
	head.add_child(UiTheme.currencies())
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("SALLE DE MÉDITATION", 42, UiTheme.GOLD))
	tv.add_child(UiTheme.title("SŒUR AELIS · ORDRE DE L'AUBE", 20, UiTheme.TEXT))
	col.add_child(_aelis_card())
	if _msg != "":
		col.add_child(UiTheme.wrap(_msg, 18, UiTheme.GOLD))
	# Voie du héros.
	col.add_child(UiTheme.section("Ta voie"))
	col.add_child(UiTheme.wrap("Le Sceau d'Écho te laisse emprunter d'autres voies. Chaque classe garde son propre arbre, et tes points dépendent de ton niveau : changer ne coûte rien. Le grimoire reste le même.", 17, UiTheme.MUTED))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	col.add_child(g)
	var classes: Dictionary = GameData.party()["classes"]
	for cid in classes.keys():
		if bool((classes[cid] as Dictionary).get("playable", false)):
			g.add_child(_class_button(str(cid), classes[cid]))
	# Voies des compagnons.
	var comps := Profile.companions_available()
	if not comps.is_empty():
		col.add_child(UiTheme.section("Voies des compagnons"))
		col.add_child(UiTheme.wrap("Un compagnon garde sa race mais peut changer de classe : son invocation, ses stats et les sorts proposés au Cercle suivent sa nouvelle voie.", 17, UiTheme.MUTED))
		for who in comps:
			col.add_child(_companion_paths(who))
	# Configurations.
	col.add_child(UiTheme.section("Configurations"))
	col.add_child(UiTheme.wrap("Enregistre ta voie, ton arbre et ton deck, puis recharge-les à tout moment, sans frais.", 17, UiTheme.MUTED))
	for i in range(Profile.CONFIG_SLOTS):
		col.add_child(_config_card(i))
	# Réinitialisation.
	col.add_child(UiTheme.section("Réinitialisation"))
	var cost := Profile.reset_cost()
	var rs := UiTheme.button(("Confirmer : réinitialiser l'arbre" if _reset_armed else "Réinitialiser l'arbre de %s" % _class_name(Profile.player_class())) + (" · gratuit" if cost == 0 else " · %d or" % cost), 19)
	rs.custom_minimum_size = Vector2(0, 56)
	rs.disabled = Profile.gold() < cost or Profile.skill_points_spent() == 0
	if _reset_armed:
		rs.add_theme_color_override("font_color", UiTheme.DANGER)
	rs.pressed.connect(func() -> void:
		if not _reset_armed:
			_reset_armed = true
		elif Profile.reset_skills():
			_reset_armed = false
			_msg = "Ton arbre est vierge : %d points à replacer." % Profile.skill_points_free()
			_save()
		_rebuild.call_deferred())
	col.add_child(rs)
	# Harmonie.
	col.add_child(UiTheme.section("Harmonie"))
	var cor := Story.value("corruption")
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", 10)
	col.add_child(hr)
	hr.add_child(UiTheme.label("Corruption %d / 100" % cor, 19, Color("D93CF2") if cor > 0 else UiTheme.MUTED))
	var bar := UiTheme.bar(Color("D93CF2"), 8)
	bar.max_value = 100
	bar.value = cor
	hr.add_child(bar)
	col.add_child(UiTheme.wrap("La magie interdite nourrit la Corruption, qui pousse ton histoire vers la voie des Cendres. Méditer avec Sœur Aelis l'apaise.", 17, UiTheme.MUTED))
	var hcost := Profile.harmony_cost()
	var hb := UiTheme.button("Méditer · %d or (Corruption −5)" % hcost, 19)
	hb.custom_minimum_size = Vector2(0, 56)
	hb.disabled = cor <= 0 or Profile.gold() < hcost
	hb.add_theme_color_override("font_color", AELIS)
	hb.pressed.connect(func() -> void:
		var n := Profile.harmony()
		if n > 0:
			_msg = "Le souffle s'apaise. Corruption −%d." % n
			_save()
		_rebuild.call_deferred())
	col.add_child(hb)


func _aelis_card() -> PanelContainer:
	var c: Array = UiTheme.card(Color(AELIS, 0.5), 14)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	(c[1] as VBoxContainer).add_child(h)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), Color(AELIS, 0.8), 10, 2, 4))
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(frame)
	var pic := TextureRect.new()
	pic.texture = PortraitArt.texture("aelis", "neutre")
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.custom_minimum_size = Vector2(88, 88)
	frame.add_child(pic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	h.add_child(v)
	v.add_child(UiTheme.title("SŒUR AELIS", 24, AELIS))
	var line := "« Respire, Porteur. Le Sceau d'Écho ne t'enchaîne à aucune voie : il te laisse les emprunter toutes. »"
	if Story.value("corruption") >= 30:
		line = "« Je sens la Cendre sur toi. Assieds-toi ; nous allons la laisser retomber. »"
	v.add_child(UiTheme.wrap(line, 18, UiTheme.TEXT))
	return c[0]


func _class_name(cid: String) -> String:
	return str((GameData.party()["classes"] as Dictionary).get(cid, {}).get("name", cid))


func _class_button(cid: String, cl: Dictionary) -> Button:
	var on := Profile.player_class() == cid
	var rb: Array = UiTheme.rich_button(84)
	var bt: Button = rb[0]
	var h: HBoxContainer = rb[1]
	if on:
		bt.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), UiTheme.GOLD, 14, 3, 0, UiTheme.GOLD))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiTheme.title(str(cl.get("name", cid)).to_upper(), 22, UiTheme.GOLD if on else UiTheme.TEXT))
	var ult: Dictionary = GameData.spells().get(str(cl.get("ultimate", "")), {})
	var l := UiTheme.label(("Ta voie actuelle" if on else "Ultime : %s" % str(ult.get("name", ""))), 15, UiTheme.MUTED)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	bt.pressed.connect(func() -> void:
		if on:
			return
		var before := _class_name(Profile.player_class())
		if Profile.change_class(cid):
			_msg = "Tu suis désormais la voie : %s. Ton arbre de %s est conservé." % [_class_name(cid), before]
			_save()
		_rebuild.call_deferred())
	return bt


func _companion_paths(who: String) -> PanelContainer:
	var col := Dialogues.color(who)
	var c: Array = UiTheme.card(Color(col, 0.5), 12)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 8)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	var pic := TextureRect.new()
	pic.texture = PortraitArt.texture(who, "neutre")
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.custom_minimum_size = Vector2(44, 44)
	h.add_child(pic)
	var t := UiTheme.title("%s · %s" % [Dialogues.display_name(who).to_upper(), _class_name(Profile.companion_class(who))], 22, col)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	v.add_child(g)
	for cid in SHORT.keys():
		var on: bool = Profile.companion_class(who) == str(cid)
		var bt := UiTheme.button(str(SHORT[cid]), 16)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.custom_minimum_size = Vector2(0, 48)
		if on:
			bt.add_theme_color_override("font_color", col)
			bt.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), col, 10, 2, 6))
		var target := str(cid)
		bt.pressed.connect(func() -> void:
			if on:
				return
			if Profile.set_companion_class(who, target):
				_msg = "%s suit désormais la voie : %s." % [Dialogues.display_name(who), _class_name(target)]
				_save()
			_rebuild.call_deferred())
		g.add_child(bt)
	return c[0]


func _config_card(i: int) -> PanelContainer:
	var cfg: Dictionary = Profile.configs()[i]
	var c: Array = UiTheme.card(UiTheme.BORDER, 12)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 6)
	v.add_child(UiTheme.title("CONFIGURATION %d" % (i + 1), 20, UiTheme.TEXT))
	if cfg.is_empty():
		v.add_child(UiTheme.label("Vide", 17, UiTheme.MUTED))
	else:
		var keys: Array = cfg.get("keys", [])
		var deck: Array = cfg.get("deck", [])
		var parts: Array[String] = [_class_name(str(cfg.get("class", ""))), "%d points" % int(cfg.get("points", 0)),
			"Deck %d sorts" % deck.size() if str(cfg.get("mode", "deck")) == "deck" else "Tiroir"]
		v.add_child(UiTheme.label(" · ".join(parts), 17, UiTheme.GOLD))
		v.add_child(UiTheme.wrap("Clés de voûte : %s" % (", ".join(keys) if not keys.is_empty() else "aucune"), 16, UiTheme.MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var sv := UiTheme.button("Enregistrer ici" if cfg.is_empty() else "Remplacer", 18)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.custom_minimum_size = Vector2(0, 52)
	sv.pressed.connect(func() -> void:
		Profile.save_config(i)
		_msg = "Configuration %d enregistrée." % (i + 1)
		_save()
		_rebuild.call_deferred())
	row.add_child(sv)
	var ld := UiTheme.button("Charger", 18)
	ld.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ld.custom_minimum_size = Vector2(0, 52)
	ld.disabled = cfg.is_empty()
	if not cfg.is_empty():
		ld.add_theme_color_override("font_color", UiTheme.GOLD)
	ld.pressed.connect(func() -> void:
		var err := Profile.load_config(i)
		_msg = err if err != "" else "Configuration %d chargée : %s." % [i + 1, _class_name(Profile.player_class())]
		if err == "":
			_save()
		_rebuild.call_deferred())
	row.add_child(ld)
	return c[0]


func _save() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
