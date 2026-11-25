class_name PrepScreen
extends Control
## Préparation avant le combat : rappel du niveau et choix de la façon d'emporter ses sorts —
## Deck (7 sorts choisis à la Bibliothèque) ou Tiroir (tous les sorts connus, rangés par école).

signal start
signal back

var level_id := ""
var _msg := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.5, 0.0, "campfire", "camp")
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var lv := GameData.level(level_id)
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 14)
	var head := HBoxContainer.new()
	col.add_child(head)
	var b := UiTheme.back_button("Retour")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("PRÉPARATION", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title(("%s · %s" % [str(lv.get("number", "")), str(lv.get("name", ""))]).to_upper(), 24, UiTheme.TEXT))
	col.add_child(UiTheme.wrap(str(lv.get("desc", "")), 18, UiTheme.MUTED))
	col.add_child(UiTheme.section("Sorts pour ce combat"))
	var mode := Profile.spell_mode()
	col.add_child(_mode_card("deck", mode == "deck"))
	col.add_child(_mode_card("drawer", mode == "drawer"))
	if Profile.can_replay_scenes(level_id):
		# Mission déjà réussie : revoir ou passer l'intro et la fin.
		col.add_child(UiTheme.section("Cinématiques"))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		col.add_child(row)
		row.add_child(_scene_card(false, not Profile.replay_scenes()))
		row.add_child(_scene_card(true, Profile.replay_scenes()))
	if _msg != "":
		col.add_child(UiTheme.wrap(_msg, 18, UiTheme.GOLD))
	var go: Array = UiTheme.rich_button(84, "primary")
	var gb: Button = go[0]
	var gh: HBoxContainer = go[1]
	gh.alignment = BoxContainer.ALIGNMENT_CENTER
	gh.add_child(UiTheme.icon_rect("play", 28, UiTheme.GOLD))
	gh.add_child(UiTheme.title("COMBATTRE", 34, UiTheme.GOLD))
	gb.pressed.connect(func() -> void: start.emit())
	col.add_child(gb)


func _mode_card(m: String, on: bool) -> Button:
	var rb: Array = UiTheme.rich_button(178)
	var bt: Button = rb[0]
	var h: HBoxContainer = rb[1]
	if on:
		bt.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), UiTheme.TEAL, 14, 3, 0, UiTheme.TEAL))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var known := Profile.drawer_spells()
	if m == "deck":
		top.add_child(UiTheme.title("DECK", 30, UiTheme.TEAL if on else UiTheme.TEXT))
		top.add_child(UiTheme.spacer())
		top.add_child(UiTheme.label("%d / %d sorts" % [Profile.deck().size(), Profile.DECK_MAX], 18, UiTheme.MUTED))
		v.add_child(_wrap("Tes 7 sorts choisis à la Bibliothèque, toujours visibles. Un toucher pour viser, un autre pour lancer."))
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)
		v.add_child(row)
		for id in Profile.deck():
			row.add_child(UiTheme.icon_rect(id, 30, Color(str(GameData.spells()[id].get("color", "ffffff")))))
	else:
		top.add_child(UiTheme.title("TIROIR", 30, UiTheme.TEAL if on else UiTheme.TEXT))
		top.add_child(UiTheme.spacer())
		top.add_child(UiTheme.label("%d sorts" % known.size(), 18, UiTheme.MUTED))
		v.add_child(_wrap("Tous tes sorts, rangés par école. Maintiens une école, relâche sur un sort, touche l'arène. Ou glisse le sort jusqu'à l'arène : il part aussitôt."))
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 10)
		v.add_child(row)
		for sc in BattleScreen.DRAWER:
			var n := 0
			for id in known:
				if str(GameData.spells()[id].get("school", "lumiere")) == str(sc):
					n += 1
			var info: Array = BattleScreen.DRAWER_INFO[sc]
			var chip := HBoxContainer.new()
			chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chip.add_theme_constant_override("separation", 2)
			chip.modulate = Color(1, 1, 1, 1.0 if n > 0 else 0.35)
			chip.add_child(UiTheme.icon_rect(str(info[1]), 24, Color(str(info[2]))))
			chip.add_child(UiTheme.label(str(n), 18, Color(str(info[2]))))
			row.add_child(chip)
	bt.pressed.connect(func() -> void:
		Profile.set_spell_mode(m)
		Profile.save_local()
		_msg = "Mode Deck : 7 sorts." if m == "deck" else "Mode Tiroir : %d sorts à portée de doigt." % known.size()
		_rebuild.call_deferred())
	return bt


## Carte « Passer » ou « Revoir » des cinématiques d'une mission déjà réussie.
func _scene_card(watch: bool, on: bool) -> Button:
	var rb: Array = UiTheme.rich_button(112)
	var bt: Button = rb[0]
	var h: HBoxContainer = rb[1]
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if on:
		bt.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), UiTheme.TEAL, 14, 3, 0, UiTheme.TEAL))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	top.add_child(UiTheme.icon_rect("play" if watch else "chevron", 22, UiTheme.TEAL if on else UiTheme.MUTED))
	top.add_child(UiTheme.title("REVOIR" if watch else "PASSER", 24, UiTheme.TEAL if on else UiTheme.TEXT))
	v.add_child(_wrap("L'intro et la fin de la mission, mises en scène." if watch else "Directement au combat, sans l'intro ni la fin."))
	bt.pressed.connect(func() -> void:
		Profile.set_replay_scenes(watch)
		Profile.save_local()
		_msg = "Cinématiques : revues à chaque mission déjà réussie." if watch else "Cinématiques : passées pour les missions déjà réussies."
		_rebuild.call_deferred())
	return bt


func _wrap(t: String) -> Label:
	var l := UiTheme.wrap(t, 16, UiTheme.MUTED)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
