class_name DialogueScreen
extends Control
## Scènes de dialogue (docs/design/07-narration.md §6, maquette docs/mockups/Dialogue.dc.html) :
## illustration, portrait et nom dans la couleur de la faction, texte en machine à écrire,
## Auto, Historique, Passer (les choix ne se passent jamais), choix « Fil du destin ».

signal finished

const CPS := 45.0
const AUTO_DELAY := 1.4

var scenes: Array[String] = []

var _scene_i := -1
var _scene_id := ""
var _queue: Array = []
var _typing := false
var _shown := 0.0
var _auto := false
var _auto_t := 0.0
var _waiting_choice := false
var _history: Array[String] = []
var _art := ""
var _subject := ""
var _t := 0.0
var _feedback_t := 0.0
var _overlay_open := false
var _done := false
var _who := ""
var _mood := "neutre"
var _talk_frame := 0
var _blink := false
var _blink_t := 3.0

var art_rect: TextureRect
var subject_rect: TextureRect
var panel: PanelContainer
var head_row: HBoxContainer
var portrait_frame: PanelContainer
var portrait_rect: TextureRect
var name_label: Label
var sub_label: Label
var text_label: Label
var next_mark: TextureRect
var feedback_label: Label
var choice_box: VBoxContainer
var title_label: Label
var auto_btn: Button
var overlay: Control
var stage: CineStage ## mise en scène : caméra, ambiance, acteurs, effets (docs/design/41-cinematiques.md)


func configure(ids: Array) -> void:
	scenes.clear()
	for id in ids:
		scenes.append(str(id))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_rect = TextureRect.new()
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art_rect)
	art_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	subject_rect = TextureRect.new()
	subject_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	subject_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	subject_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	subject_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subject_rect)
	stage = CineStage.new()
	stage.art = art_rect
	stage.subject = subject_rect
	add_child(stage)
	var flash := stage.make_flash_layer()
	add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_top_bar()
	_build_panel()
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_relayout)
	_next_scene()
	_relayout.call_deferred()


# ---------------------------------------------------------------- construction

func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	bar.position = Vector2(16, 16)
	add_child(bar)
	auto_btn = _top_button("Auto")
	auto_btn.toggle_mode = true
	auto_btn.toggled.connect(func(on: bool) -> void:
		_auto = on
		_auto_t = 0.0)
	bar.add_child(auto_btn)
	var hist := _top_button("Historique")
	hist.pressed.connect(_open_history)
	bar.add_child(hist)
	var skip := _top_button("Passer")
	skip.pressed.connect(_skip)
	bar.add_child(skip)
	title_label = UiTheme.title("", 26, UiTheme.GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.1))
	title_label.add_theme_constant_override("outline_size", 8)
	add_child(title_label)


func _top_button(text: String) -> Button:
	var b := UiTheme.button(text, 22)
	b.custom_minimum_size = Vector2(0, 56)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		var sb := UiTheme.box(Color(UiTheme.BG, 0.8), UiTheme.GOLD if st.begins_with("pressed") or st == "hover_pressed" else UiTheme.BORDER, 10, 2, 12)
		b.add_theme_stylebox_override(st, sb)
	return b


func _build_panel() -> void:
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.BG, 0.95), UiTheme.BORDER, 16, 2, 18))
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(v)
	head_row = HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 16)
	head_row.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(head_row)
	portrait_frame = PanelContainer.new()
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	head_row.add_child(portrait_frame)
	portrait_rect = TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(128, 128)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_child(portrait_rect)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 2)
	names.size_flags_vertical = Control.SIZE_SHRINK_END
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_row.add_child(names)
	name_label = UiTheme.title("", 34, UiTheme.TEXT)
	names.add_child(name_label)
	sub_label = UiTheme.label("", 20, UiTheme.MUTED)
	names.add_child(sub_label)
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL, UiTheme.BORDER, 14, 2, 18))
	bubble.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(bubble)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 0)
	bv.mouse_filter = Control.MOUSE_FILTER_PASS
	bubble.add_child(bv)
	text_label = UiTheme.wrap("", 29, UiTheme.TEXT)
	text_label.custom_minimum_size = Vector2(10, 112)
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	bv.add_child(text_label)
	next_mark = TextureRect.new()
	next_mark.texture = StoryArt.icon("next", UiTheme.CYAN)
	next_mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	next_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	next_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	next_mark.custom_minimum_size = Vector2(21, 12)
	next_mark.size_flags_horizontal = Control.SIZE_SHRINK_END
	next_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bv.add_child(next_mark)
	feedback_label = UiTheme.wrap("", 21, UiTheme.GOLD)
	feedback_label.visible = false
	v.add_child(feedback_label)
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 10)
	choice_box.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(choice_box)


func _relayout() -> void:
	if size.x < 10.0:
		return
	# Paysage (ordinateur, tablette) : panneau plus large, texte et portrait plus grands.
	var land := size.x > size.y * 1.1
	var pw := minf(size.x - 32.0, 1400.0 if land else 920.0)
	text_label.add_theme_font_size_override("font_size", 36 if land else 29)
	text_label.custom_minimum_size = Vector2(pw - 80.0, 136 if land else 112)
	name_label.add_theme_font_size_override("font_size", 42 if land else 34)
	sub_label.add_theme_font_size_override("font_size", 24 if land else 20)
	portrait_rect.custom_minimum_size = Vector2(192, 192) if land else Vector2(128, 128)
	panel.custom_minimum_size = Vector2(pw, 0)
	panel.size = Vector2(pw, 0)
	panel.reset_size()
	panel.position = Vector2((size.x - pw) * 0.5, size.y - panel.size.y - 24.0)
	title_label.position = Vector2(size.x * 0.5, 22)
	title_label.size = Vector2(size.x * 0.5 - 16.0, 40)
	# Sol des acteurs : au-dessus du panneau tel qu'il est avec un portrait, pour qu'ils ne sautent pas
	# d'une réplique à l'autre.
	var ph := panel.size.y
	if not head_row.visible:
		ph += head_row.get_combined_minimum_size().y + 12.0
	stage.ground_y = size.y - 24.0 - ph - 6.0
	stage.top_y = 90.0
	_refresh_art()


func _refresh_art() -> void:
	if _art == "" or size.x < 10.0:
		return
	var px := 3.0 if size.x < size.y else 4.0
	art_rect.texture = StoryArt.plate(_art, Vector2i(int(size.x / px), int(size.y / px)))


# ---------------------------------------------------------------- déroulement

func _next_scene() -> void:
	if _scene_i >= 0 and _scene_i < scenes.size():
		Story.mark_seen(scenes[_scene_i])
	_scene_i += 1
	if _scene_i >= scenes.size():
		_finish()
		return
	_load_scene(scenes[_scene_i])
	_advance()


func _load_scene(id: String) -> void:
	_scene_id = id
	var sc := Dialogues.scene(id)
	_queue = (sc.get("lines", []) as Array).duplicate()
	stage.begin_scene(sc)
	_set_art(str(sc.get("art", "foret")))
	_set_subject(str(sc.get("subject", "")))
	subject_rect.modulate = Color(str(sc.get("subject_tint", "ffffff")))
	title_label.text = _scene_title(id, sc)


func _scene_title(id: String, sc: Dictionary) -> String:
	if sc.has("title"):
		return str(sc["title"])
	var lid := id.get_slice("_", 0) + "_" + id.get_slice("_", 1)
	var lv := GameData.level(lid) if (GameData.level_index().get("levels", []) as Array).has(lid) else {}
	return "%s %s" % [str(lv.get("number", "")), str(lv.get("name", ""))] if not lv.is_empty() else ""


func _ilvl() -> int:
	var lid := _scene_id.get_slice("_", 0) + "_" + _scene_id.get_slice("_", 1)
	if (GameData.level_index().get("levels", []) as Array).has(lid):
		return int(GameData.level(lid).get("global_level", 1))
	return Profile.level()


## Avance jusqu'à la prochaine réplique ou au prochain choix.
func _advance() -> void:
	while not _queue.is_empty():
		var l: Dictionary = _queue.pop_front()
		if not Story.check(l):
			continue
		if l.has("choice"):
			if _inline_known_choice(l):
				continue
			_show_choice(l)
			return
		_apply_visuals(l)
		if l.has("effects"):
			_show_feedback(Story.apply(l["effects"], _ilvl()))
		if l.has("text"):
			_show_line(l)
			return
	_next_scene()


## Choix déjà fait (scène rejouée après un arrêt) : on suit la branche choisie, sans en rejouer les effets.
func _inline_known_choice(l: Dictionary) -> bool:
	var made := Story.choice(str(l["choice"]))
	if made == "":
		return false
	for opt in l.get("options", []):
		if str(opt.get("key", "")) == made:
			_queue = (opt.get("then", []) as Array) + _queue
	return true


func _apply_visuals(l: Dictionary) -> void:
	if l.has("art"):
		_set_art(str(l["art"]))
	if l.has("subject"):
		_set_subject(str(l["subject"]))
	if l.has("subject_tint"):
		subject_rect.modulate = Color(str(l["subject_tint"]))


func _set_art(kind: String) -> void:
	if kind == _art:
		return
	# Changement de plan : l'ancien décor s'efface sous le nouveau, la caméra repart.
	if _art != "" and art_rect.texture != null and is_inside_tree():
		var old := TextureRect.new()
		old.texture = art_rect.texture
		old.expand_mode = art_rect.expand_mode
		old.stretch_mode = art_rect.stretch_mode
		old.texture_filter = art_rect.texture_filter
		old.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(old)
		move_child(old, art_rect.get_index() + 1)
		old.size = art_rect.size
		old.position = art_rect.position
		old.pivot_offset = art_rect.pivot_offset
		old.scale = art_rect.scale
		var tw := old.create_tween()
		tw.tween_property(old, "modulate:a", 0.0, 0.6)
		tw.tween_callback(old.queue_free)
		stage.new_shot()
	_art = kind
	stage.set_plate(kind)
	_refresh_art()


func _set_subject(name: String) -> void:
	_subject = name
	subject_rect.texture = SpriteAtlas.single(name) if name != "" else null
	subject_rect.visible = name != ""
	stage.subject_changed()


func _show_line(l: Dictionary) -> void:
	var who := Dialogues.resolve_who(str(l.get("who", "narrateur")))
	var text := Dialogues.fmt(str(l.get("text", "")))
	var narr := who == "narrateur" or not PortraitArt.has_portrait(who)
	head_row.visible = not narr
	_who = "" if narr else who
	_mood = str(l.get("mood", "neutre"))
	_talk_frame = 0
	_blink = false
	stage.speak(who, _mood)
	stage.play_cues(l)
	if not narr:
		var col := Dialogues.color(who)
		portrait_rect.texture = PortraitArt.texture(who, _mood)
		portrait_frame.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, col, 12, 3, 4))
		name_label.text = Dialogues.display_name(who).to_upper()
		name_label.add_theme_color_override("font_color", col)
		sub_label.text = Dialogues.subtitle(who)
	text_label.text = text
	text_label.add_theme_color_override("font_color", Color("cfc8ff") if narr else UiTheme.TEXT)
	text_label.visible_characters = 0
	_shown = 0.0
	_typing = true
	_auto_t = 0.0
	next_mark.modulate.a = 0.0
	_history.append(text if narr else "%s : %s" % [Dialogues.display_name(who), text])
	_relayout.call_deferred()


func _show_choice(l: Dictionary) -> void:
	_waiting_choice = true
	_complete_line()
	next_mark.modulate.a = 0.0
	for ch in choice_box.get_children():
		ch.queue_free()
	var major := bool(l.get("major", false))
	var accent := UiTheme.VIOLET if major else UiTheme.CYAN
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_box.add_child(hdr)
	if major:
		var star := TextureRect.new()
		star.texture = StoryArt.icon("sparkle", accent)
		star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.custom_minimum_size = Vector2(18, 18)
		star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hdr.add_child(star)
	hdr.add_child(UiTheme.title("FIL DU DESTIN" if major else "CHOIX", 22, accent))
	var line := ColorRect.new()
	line.color = UiTheme.BORDER
	line.custom_minimum_size = Vector2(10, 2)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr.add_child(line)
	# Options réservées (race, classe, loyauté) hors de portée : montrées verrouillées, sauf si une
	# autre option de la même lettre est ouverte (ex. [Nain] ou [Brann · loyauté 60]).
	var open_keys: Array[String] = []
	for opt in l.get("options", []):
		if Story.check(opt):
			open_keys.append(str(opt.get("key", "")))
	for opt in l.get("options", []):
		if not Story.check(opt):
			var k := str(opt.get("key", ""))
			if opt.has("tag") and not open_keys.has(k):
				open_keys.append(k)
				choice_box.add_child(_locked_option(opt))
			continue
		var label := Dialogues.fmt(str(opt.get("text", "")))
		if opt.has("tag"):
			label = "[%s] %s" % [str(opt["tag"]), label]
		var b := UiTheme.button(label, 26)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 66)
		b.add_theme_stylebox_override("normal", UiTheme.box(UiTheme.PANEL2, accent, 12, 2, 14))
		b.add_theme_stylebox_override("hover", UiTheme.box(UiTheme.PANEL2.lightened(0.08), UiTheme.GOLD, 12, 2, 14))
		var o: Dictionary = opt
		b.pressed.connect(func() -> void: _on_option(l, o))
		choice_box.add_child(b)
		if Story.has_flag("s1.premonitions"):
			# Prémonitions (acte 7) : le type de conséquences de l'option, sans le détail.
			var pm := Story.premonition(opt.get("effects", {}))
			if pm != "":
				choice_box.add_child(UiTheme.wrap("Prémonition : " + pm, 17, Color(UiTheme.VIOLET, 0.9)))
	if major:
		var note := UiTheme.wrap("Ce choix changera la suite de l'histoire.", 19, UiTheme.MUTED)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choice_box.add_child(note)
	_relayout.call_deferred()


## Option verrouillée : grisée, avec un cadenas ; elle montre qu'une autre voie existait.
func _locked_option(opt: Dictionary) -> Button:
	var b := UiTheme.button("[%s] %s" % [str(opt["tag"]), Dialogues.fmt(str(opt.get("text", "")))], 24)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(0, 58)
	b.disabled = true
	b.icon = Icons.tex("lock", 26)
	b.add_theme_color_override("icon_disabled_color", Color(UiTheme.MUTED, 0.8))
	b.add_theme_constant_override("icon_max_width", 24)
	var st := UiTheme.box(Color(UiTheme.PANEL, 0.7), UiTheme.BORDER, 12, 1, 14)
	b.add_theme_stylebox_override("disabled", st)
	b.add_theme_color_override("font_disabled_color", Color(UiTheme.MUTED, 0.75))
	b.tooltip_text = "Option réservée : %s" % str(opt["tag"])
	return b


func _on_option(l: Dictionary, opt: Dictionary) -> void:
	if not _waiting_choice:
		return
	_waiting_choice = false
	for ch in choice_box.get_children():
		ch.queue_free()
	var fb := Story.choose(str(l["choice"]), opt, _ilvl())
	Profile.save_local()
	_history.append("» " + Dialogues.fmt(str(opt.get("text", ""))))
	_show_feedback(fb)
	_queue = (opt.get("then", []) as Array) + _queue
	_advance()


func _show_feedback(lines: Array[String]) -> void:
	if lines.is_empty():
		return
	feedback_label.text = "  ·  ".join(lines)
	feedback_label.visible = true
	feedback_label.modulate.a = 1.0
	_feedback_t = 5.0
	_relayout.call_deferred()


func _complete_line() -> void:
	_typing = false
	text_label.visible_characters = -1


## Portrait vivant : la bouche bouge pendant que le texte s'écrit (fermée sur les espaces et la ponctuation),
## les yeux clignent de temps en temps. Sans bouche dessinée (créatures), le portrait respire en parlant.
func _animate_portrait(delta: float) -> void:
	if _who == "":
		return
	var talk := 0
	if _typing:
		var i := clampi(int(_shown), 0, maxi(0, text_label.text.length() - 1))
		var ch := text_label.text.substr(i, 1)
		if not (ch in [" ", ",", ".", "!", "?", "…", ";", ":", "—", "«", "»"]):
			talk = [1, 2, 1, 0][int(_t / 0.08) % 4]
	_blink_t -= delta
	var blink := false
	if _blink_t <= 0.0:
		blink = true
		if _blink_t <= -0.13:
			_blink_t = randf_range(2.4, 4.6)
	if not PortraitArt.can_talk(_who):
		portrait_rect.pivot_offset = portrait_rect.size * 0.5
		portrait_rect.scale = Vector2.ONE * (1.0 + (0.035 * absf(sin(_t * 7.0)) if _typing else 0.0))
		return
	portrait_rect.scale = Vector2.ONE
	if talk != _talk_frame or blink != _blink:
		_talk_frame = talk
		_blink = blink
		portrait_rect.texture = PortraitArt.frame(_who, _mood, talk, blink)


## Passer : saute les répliques jusqu'au prochain choix (jamais passé) ou jusqu'à la fin.
## Les effets rencontrés (drapeaux) sont appliqués.
func _skip() -> void:
	if _waiting_choice or _overlay_open or _done:
		return
	var last: Dictionary = {}
	while true:
		if _queue.is_empty():
			Story.mark_seen(scenes[_scene_i])
			_scene_i += 1
			if _scene_i >= scenes.size():
				_scene_i = scenes.size() - 1
				_finish()
				return
			_load_scene(scenes[_scene_i])
			continue
		var l: Dictionary = _queue.pop_front()
		if not Story.check(l):
			continue
		if l.has("choice"):
			if _inline_known_choice(l):
				continue
			if not last.is_empty():
				_show_line(last)
			_show_choice(l)
			return
		_apply_visuals(l)
		if l.has("effects"):
			Story.apply(l["effects"], _ilvl())
		if l.has("text"):
			last = l
			var who := Dialogues.resolve_who(str(l.get("who", "narrateur")))
			_history.append(Dialogues.fmt(str(l["text"])) if who == "narrateur" else "%s : %s" % [Dialogues.display_name(who), Dialogues.fmt(str(l["text"]))])


func _finish() -> void:
	if _done:
		return
	_done = true
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
	finished.emit()


# ---------------------------------------------------------------- entrées et animation

func _on_gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.is_pressed() and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_tap()
	elif ev is InputEventScreenTouch and ev.is_pressed():
		_tap()


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.is_pressed() or ev.is_echo():
		return
	match (ev as InputEventKey).keycode:
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			_tap()
		KEY_ESCAPE:
			if _overlay_open:
				_close_history()
			else:
				_skip()
		KEY_H:
			_open_history()
		_:
			return
	get_viewport().set_input_as_handled()


func _tap() -> void:
	if _overlay_open or _waiting_choice or _done:
		return
	if _typing:
		_complete_line()
	else:
		_advance()


func _process(delta: float) -> void:
	_t += delta
	if _typing:
		_shown += delta * CPS
		var n := text_label.get_total_character_count()
		text_label.visible_characters = int(_shown)
		if int(_shown) >= n:
			_complete_line()
	_animate_portrait(delta)
	stage.talking = _typing
	if not _typing and not _waiting_choice and not _done:
		next_mark.modulate.a = 0.5 + 0.5 * sin(_t * 5.0)
		if _auto and not _overlay_open:
			_auto_t += delta
			if _auto_t >= AUTO_DELAY + 0.02 * float(text_label.text.length()):
				_auto_t = 0.0
				_advance()
	if _feedback_t > 0.0:
		_feedback_t -= delta
		feedback_label.modulate.a = clampf(_feedback_t, 0.0, 1.0)
		if _feedback_t <= 0.0:
			feedback_label.visible = false
			_relayout.call_deferred()


# ---------------------------------------------------------------- historique

func _open_history() -> void:
	if _overlay_open:
		return
	_overlay_open = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.09, 0.8)
	overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL, UiTheme.BORDER, 16, 2, 18))
	var w := minf(size.x - 32.0, 760.0)
	pc.position = Vector2((size.x - w) * 0.5, 40.0)
	pc.size = Vector2(w, size.y - 80.0)
	overlay.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	v.add_child(UiTheme.title("HISTORIQUE", 32, UiTheme.GOLD))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	sc.add_child(list)
	for h in _history:
		list.add_child(UiTheme.wrap(h, 22, UiTheme.TEXT if not h.begins_with("» ") else UiTheme.CYAN))
	var close := UiTheme.button("Fermer", 24)
	close.custom_minimum_size = Vector2(0, 60)
	close.pressed.connect(_close_history)
	v.add_child(close)
	sc.scroll_vertical = 1000000
	(func() -> void: sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value)).call_deferred()


func _close_history() -> void:
	for ch in overlay.get_children():
		ch.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_open = false
