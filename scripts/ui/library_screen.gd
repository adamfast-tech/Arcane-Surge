class_name LibraryScreen
extends Control
## Bibliothèque : grimoire du Mage. Choix des 7 sorts emportés en combat (le deck), sorts à
## apprendre contre de l'or, sorts débloqués par l'arbre de compétences.

signal back

var _msg := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.68)
	_rebuild()


## Sorts du Mage (hors sorts des compagnons et Ultime).
static func catalogue() -> Array[String]:
	var out: Array[String] = []
	for id in GameData.spells().keys():
		var sp: Dictionary = GameData.spells()[id]
		if Profile.BASE_SPELLS.has(id) or sp.has("learn") or sp.has("source"):
			out.append(str(id))
	return out


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 12)
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
	tv.add_child(UiTheme.title("BIBLIOTHÈQUE", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title("GRIMOIRE ET DECK", 22, UiTheme.TEXT))
	var deck := Profile.deck()
	col.add_child(UiTheme.wrap("Deck : %d / %d sorts. Les sorts du deck apparaissent en combat, dans l'ordre du grimoire." % [deck.size(), Profile.DECK_MAX], 18, UiTheme.MUTED))
	if _msg != "":
		col.add_child(UiTheme.wrap(_msg, 18, UiTheme.GOLD))
	var known := Profile.known_spells()
	var cat := catalogue()
	col.add_child(UiTheme.section("Sorts connus · %d" % known.size()))
	for id in cat:
		if known.has(id):
			col.add_child(_spell_card(id, "known", deck.has(id)))
	var learnable: Array[String] = []
	var locked: Array[String] = []
	for id in cat:
		if known.has(id):
			continue
		if GameData.spells()[id].has("learn"):
			learnable.append(id)
		else:
			locked.append(id)
	if not learnable.is_empty():
		col.add_child(UiTheme.section("À apprendre"))
		for id in learnable:
			col.add_child(_spell_card(id, "learn", false))
	if not locked.is_empty():
		col.add_child(UiTheme.section("Débloqués par l'arbre de compétences"))
		for id in locked:
			col.add_child(_spell_card(id, "locked", false))


func _spell_card(id: String, mode: String, in_deck: bool) -> PanelContainer:
	var sp: Dictionary = GameData.spells()[id]
	var scol := Color(str(sp.get("color", "6fdccf")))
	var c: Array = UiTheme.card(Color(scol, 0.75) if in_deck else UiTheme.BORDER, 12)
	var pc: PanelContainer = c[0]
	if mode == "locked":
		pc.modulate = Color(1, 1, 1, 0.6)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	(c[1] as VBoxContainer).add_child(h)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.box(Color("0a1019"), Color(scol, 0.7), 8, 2, 8))
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(frame)
	frame.add_child(UiTheme.icon_rect(id, 36, scol))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiTheme.label(str(sp["name"]), 22, scol))
	v.add_child(UiTheme.label("%d mana · recharge %d s" % [int(sp.get("mana", 0)), int(sp.get("cd", 0))], 16, UiTheme.MUTED))
	v.add_child(UiTheme.wrap(str(sp.get("desc", "")), 17, UiTheme.TEXT))
	match mode:
		"known":
			var t := UiTheme.button("Dans le deck" if in_deck else "Ajouter", 18)
			t.custom_minimum_size = Vector2(130, 54)
			t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if in_deck:
				t.add_theme_color_override("font_color", UiTheme.TEAL)
				t.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.94), UiTheme.TEAL, 10, 2, 6))
			t.pressed.connect(func() -> void:
				_msg = Profile.toggle_deck(id)
				_save()
				_rebuild.call_deferred())
			h.add_child(t)
		"learn":
			var l: Dictionary = sp["learn"]
			var block := Profile.learn_block(id)
			var lb := UiTheme.button("Apprendre\n%d or" % int(l.get("gold", 0)), 17)
			lb.custom_minimum_size = Vector2(130, 60)
			lb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			lb.disabled = block != ""
			if block == "":
				lb.add_theme_color_override("font_color", UiTheme.GOLD)
				lb.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.85), 10, 2, 6))
			lb.pressed.connect(func() -> void:
				if Profile.learn(id):
					_msg = "%s appris." % str(sp["name"])
					_save()
				_rebuild.call_deferred())
			h.add_child(lb)
			var req := "Niveau %d requis" % int(l.get("level", 1))
			if block != "" and not block.begins_with("Niveau"):
				req += " · " + block
			v.add_child(UiTheme.label(req, 15, UiTheme.MUTED if block != "" else UiTheme.GOOD))
		"locked":
			h.add_child(UiTheme.icon_rect("lock", 22, UiTheme.MUTED))
			v.add_child(UiTheme.label(str(sp.get("source", "")), 15, UiTheme.MUTED))
	return pc


func _save() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
