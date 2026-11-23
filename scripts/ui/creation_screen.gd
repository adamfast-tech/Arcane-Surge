class_name CreationScreen
extends Control
## Création du personnage (docs/design/23-creation-personnage.md) : race, classe et apparence, avec
## aperçu du portrait et du sprite de combat. En mode Miroir (Havre-Aube), seule l'apparence change.

signal done
signal back

var mirror := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.74)
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var party := GameData.party()
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 12)
	if mirror:
		var head := HBoxContainer.new()
		col.add_child(head)
		var b := UiTheme.back_button("Havre-Aube")
		b.pressed.connect(func() -> void: back.emit())
		head.add_child(b)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("MIROIR" if mirror else "TON HÉROS", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title("APPARENCE" if mirror else "CRÉATION DU PERSONNAGE", 22, UiTheme.TEXT))
	if not mirror and Profile.level() > 1:
		col.add_child(UiTheme.wrap("Ta progression est conservée. Choisis ta race et ton apparence ; l'apparence se change ensuite au Miroir de Havre-Aube (touche ton portrait).", 18, UiTheme.MUTED))
	col.add_child(_preview(party))
	if not mirror:
		col.add_child(UiTheme.section("Race"))
		var rg := GridContainer.new()
		rg.columns = 2
		rg.add_theme_constant_override("h_separation", 8)
		rg.add_theme_constant_override("v_separation", 8)
		col.add_child(rg)
		for rid in party["races"].keys():
			rg.add_child(_race_card(str(rid), party["races"][rid]))
		col.add_child(_race_details(party["races"].get(Profile.race(), {})))
		col.add_child(UiTheme.section("Classe"))
		var cg := GridContainer.new()
		cg.columns = 2
		cg.add_theme_constant_override("h_separation", 8)
		cg.add_theme_constant_override("v_separation", 8)
		col.add_child(cg)
		for cid in party["classes"].keys():
			cg.add_child(_class_card(str(cid), party["classes"][cid]))
		col.add_child(_class_details(party["classes"].get(Profile.player_class(), {})))
	col.add_child(UiTheme.section("Apparence"))
	var lk := Profile.look()
	col.add_child(_choice_row("Silhouette", PlayerLook.SILHOUETTES, int(lk["sil"]), func(i: int) -> void: Profile.set_look("sil", i)))
	col.add_child(_choice_row("Coiffe", PlayerLook.HEADS.values(), PlayerLook.HEADS.keys().find(str(lk["head"])), func(i: int) -> void: Profile.set_look("head", str(PlayerLook.HEADS.keys()[i]))))
	col.add_child(_choice_row("Visage", PlayerLook.FACES, int(lk["face"]), func(i: int) -> void: Profile.set_look("face", i)))
	var skins: Array = (party["races"] as Dictionary).get(Profile.race(), {}).get("skins", [])
	col.add_child(_swatches("Peau", skins, int(lk["skin"]), func(i: int) -> void: Profile.set_look("skin", i)))
	col.add_child(_swatches("Cheveux", PlayerLook.HAIR.values(), PlayerLook.HAIR.keys().find(str(lk["hair"])), func(i: int) -> void: Profile.set_look("hair", str(PlayerLook.HAIR.keys()[i]))))
	col.add_child(_swatches("Yeux et magie", PlayerLook.EYES.values(), PlayerLook.EYES.keys().find(str(lk["eyes"])), func(i: int) -> void: Profile.set_look("eyes", str(PlayerLook.EYES.keys()[i]))))
	var outs: Array = []
	for k in PlayerLook.OUTFITS.keys():
		outs.append(PlayerLook.OUTFITS[k][2])
	col.add_child(_swatches("Tenue", outs, PlayerLook.OUTFITS.keys().find(str(lk["outfit"])), func(i: int) -> void: Profile.set_look("outfit", str(PlayerLook.OUTFITS.keys()[i]))))
	var go: Array = UiTheme.rich_button(84, "primary")
	var gb: Button = go[0]
	var gh: HBoxContainer = go[1]
	gh.alignment = BoxContainer.ALIGNMENT_CENTER
	gh.add_child(UiTheme.title("VALIDER" if mirror else "COMMENCER L'AVENTURE", 30, UiTheme.GOLD))
	gb.pressed.connect(func() -> void: done.emit())
	col.add_child(gb)


## Aperçu : portrait, sprite de combat vu de dos, nom, race et classe.
func _preview(party: Dictionary) -> PanelContainer:
	var c: Array = UiTheme.card(Color(UiTheme.TEAL, 0.6), 14)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	(c[1] as VBoxContainer).add_child(h)
	var pf := PanelContainer.new()
	pf.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), Color(UiTheme.TEAL, 0.7), 10, 2, 4))
	pf.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(pf)
	var pic := TextureRect.new()
	pic.texture = PortraitArt.texture("porteur", "neutre")
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(128, 128)
	pf.add_child(pic)
	SpriteAtlas.set_player(Profile.look(), Profile.race(), Profile.player_class())
	var sp := TextureRect.new()
	sp.texture = SpriteAtlas.single("player")
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sp.custom_minimum_size = Vector2(80, 128)
	h.add_child(sp)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var pname := "Invité"
	if Cloud.instance != null and Cloud.instance.username != "":
		pname = Cloud.instance.username
	v.add_child(UiTheme.title(pname.to_upper(), 30, UiTheme.TEXT))
	var cname := str((party["classes"] as Dictionary).get(Profile.player_class(), {}).get("name", "Mage"))
	var rname := str((party["races"] as Dictionary).get(Profile.race(), {}).get("name", ""))
	v.add_child(UiTheme.label("%s · %s" % [rname, cname], 20, UiTheme.TEAL))
	var cl: Dictionary = (party["classes"] as Dictionary).get(Profile.player_class(), {})
	var rc: Dictionary = (party["races"] as Dictionary).get(Profile.race(), {})
	var stats: Array[String] = []
	for k in ["pou", "vig", "esp", "cel", "des"]:
		var val := int((cl.get("base", {}) as Dictionary).get(k, 0)) + int(rc.get(k, 0))
		stats.append("%s %d" % [str(k).to_upper(), val])
	v.add_child(UiTheme.label(" · ".join(stats), 16, UiTheme.MUTED))
	return c[0]


func _race_card(rid: String, r: Dictionary) -> Button:
	var on := Profile.race() == rid
	var locked := r.has("locked")
	var rb: Array = UiTheme.rich_button(98)
	var bt: Button = rb[0]
	var h: HBoxContainer = rb[1]
	if on:
		bt.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), UiTheme.TEAL, 14, 3, 0, UiTheme.TEAL))
	bt.disabled = locked
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiTheme.title(str(r.get("name", rid)).to_upper(), 24, UiTheme.TEAL if on else (UiTheme.MUTED if locked else UiTheme.TEXT)))
	var mods: Array[String] = []
	for k in ["pou", "vig", "esp", "cel", "des"]:
		var n := int(r.get(k, 0))
		if n != 0:
			mods.append("%s %+d" % [str(k).to_upper(), n])
	var l := UiTheme.label(str(r.get("locked", "")) if locked else " · ".join(mods), 15, UiTheme.MUTED)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	bt.pressed.connect(func() -> void:
		if Profile.set_race(rid):
			_rebuild.call_deferred())
	return bt


func _race_details(r: Dictionary) -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 12)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 2)
	v.add_child(UiTheme.wrap(str(r.get("desc", "")), 17, UiTheme.TEXT))
	for ps in r.get("passives", []):
		v.add_child(UiTheme.wrap("· " + str(ps), 16, UiTheme.MUTED))
	if r.has("don"):
		v.add_child(UiTheme.wrap("Don racial : " + str(r["don"]), 16, UiTheme.GOLD))
	v.add_child(UiTheme.wrap("Le Don racial se lance en combat (bouton DON). L'arbre d'héritage de la race se trouve à l'Entraînement.", 14, Color(UiTheme.MUTED, 0.8)))
	return c[0]


func _class_card(cid: String, cl: Dictionary) -> Button:
	var on := Profile.player_class() == cid
	var playable := bool(cl.get("playable", false))
	var rb: Array = UiTheme.rich_button(112)
	var bt: Button = rb[0]
	var h: HBoxContainer = rb[1]
	if on:
		bt.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), UiTheme.GOLD, 14, 3, 0, UiTheme.GOLD))
	bt.disabled = not playable
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiTheme.title(str(cl.get("name", cid)).to_upper(), 24, UiTheme.GOLD if on else (UiTheme.TEXT if playable else UiTheme.MUTED)))
	var d := UiTheme.wrap(str(cl.get("desc", "")) if playable else "Bientôt jouable (étape « Classes »).", 14, UiTheme.MUTED)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(d)
	bt.pressed.connect(func() -> void:
		if Profile.set_class(cid):
			_rebuild.call_deferred())
	return bt


## Fiche de la classe choisie : invocation, Champion, Ultime et branches de l'arbre.
func _class_details(cl: Dictionary) -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 12)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 2)
	var units := GameData.units()
	var spells := GameData.spells()
	var fam := str(cl.get("player_familiar", cl.get("familiar", "")))
	v.add_child(UiTheme.wrap("Invocation : %s" % str((units.get(fam, {}) as Dictionary).get("name", fam)), 16, UiTheme.TEXT))
	v.add_child(UiTheme.wrap("Champion : %s" % str((units.get(str(cl.get("champion", "")), {}) as Dictionary).get("name", "")), 16, UiTheme.TEXT))
	var ult: Dictionary = spells.get(str(cl.get("ultimate", "")), {})
	v.add_child(UiTheme.wrap("Ultime : %s" % str(ult.get("name", "")), 16, UiTheme.GOLD))
	var tree: Dictionary = GameData.load_json("res://data/skill_trees/%s.json" % Profile.player_class())
	var names: Array[String] = []
	for br in tree.get("branches", []):
		names.append("%s (%s)" % [str(br.get("name", "")), str(br.get("theme", ""))])
	if not names.is_empty():
		v.add_child(UiTheme.wrap("Arbre : " + " · ".join(names), 15, UiTheme.MUTED))
	v.add_child(UiTheme.wrap("Le grimoire (Bibliothèque) est commun à toutes les classes ; chaque classe a son propre arbre.", 14, Color(UiTheme.MUTED, 0.8)))
	return c[0]


func _choice_row(title: String, labels: Array, current: int, apply: Callable) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.add_child(UiTheme.label(title, 17, UiTheme.MUTED))
	var g := GridContainer.new()
	g.columns = mini(4, labels.size())
	g.add_theme_constant_override("h_separation", 6)
	v.add_child(g)
	for i in range(labels.size()):
		var b := UiTheme.button(str(labels[i]), 17)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 50)
		if i == current:
			b.add_theme_color_override("font_color", UiTheme.TEAL)
			b.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), UiTheme.TEAL, 10, 2, 6))
		var idx := i
		b.pressed.connect(func() -> void:
			apply.call(idx)
			_rebuild.call_deferred())
		g.add_child(b)
	return v


func _swatches(title: String, colors: Array, current: int, apply: Callable) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.add_child(UiTheme.label(title, 17, UiTheme.MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	for i in range(colors.size()):
		var col := Color(str(colors[i]))
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(46, 46)
		var bd := UiTheme.GOLD if i == current else Color(UiTheme.BORDER, 0.9)
		b.add_theme_stylebox_override("normal", UiTheme.box(col, bd, 8, 3 if i == current else 2, 0))
		b.add_theme_stylebox_override("hover", UiTheme.box(col.lightened(0.1), UiTheme.TEAL, 8, 2, 0))
		b.add_theme_stylebox_override("pressed", UiTheme.box(col, UiTheme.GOLD, 8, 3, 0))
		var idx := i
		b.pressed.connect(func() -> void:
			apply.call(idx)
			_rebuild.call_deferred())
		row.add_child(b)
	return v
