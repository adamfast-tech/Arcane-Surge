extends Control
## Point d'entrée et navigation : connexion, Havre-Aube, carte et équipement, dialogue d'intro,
## combat, récompenses, dialogue de fin.

var _screen: Control
var cloud: Cloud
## Scènes de choix en suspens déjà proposées pendant cette session (évite de les reproposer en boucle).
var _offered: Dictionary = {}


func _ready() -> void:
	RenderingServer.set_default_clear_color(UiTheme.BG)
	theme = UiTheme.build()
	TouchScroll.install(get_tree())
	cloud = Cloud.new()
	add_child(cloud)
	Profile.load_local()
	var scene := str(_query().get("scene", ""))
	if Dialogues.has_scene(scene):
		# Aperçu d'une scène de dialogue (« ?scene=z01_l10_outro »).
		_show_dialogue([scene], _boot)
		return
	var direct := _level_from_url()
	if direct != "":
		var extra := {"healed": true} if _url_flag("healed") else {}
		if _url_flag("krag"):
			# Aperçu : Krag dans l'équipe (« &krag=1 »).
			var fl := Story.active_flags()
			fl.append("s1.krag_allie")
			extra["flags"] = fl
			extra["active"] = ["sylwen", "krag"]
		var dq := str(_query().get("deck", ""))
		if dq != "":
			# Aperçu : sorts imposés (« &deck=orage,comete »).
			var dk: Array[String] = []
			for sid in dq.split(",", false):
				if GameData.spells().has(sid):
					dk.append(sid)
			extra["deck"] = dk
		if str(_query().get("mode", "")) == "drawer":
			# Aperçu : mode Tiroir (« &mode=drawer »), avec les sorts de « &deck= » ou tous les sorts connus.
			extra["spell_mode"] = "drawer"
			if not extra.has("deck"):
				extra["deck"] = Profile.drawer_spells()
		var slow := float(str(_query().get("slow", "1")))
		if slow > 0.0 and slow < 1.0:
			# Aperçu au ralenti (« &slow=0.3 ») : vérifier les animations image par image.
			Engine.time_scale = slow
		var qd := str(_query().get("demo", ""))
		if qd != "":
			# Aperçu des animations : « &demo=eclipse,linceul&every=3 » (sorts lancés tour à tour).
			extra["demo"] = Array(qd.split(",", false))
			extra["demo_every"] = float(str(_query().get("every", "3")))
		var qc := str(_query().get("class", ""))
		if qc != "":
			# Aperçu : classe du héros (« &class=chevalier »).
			extra["player_class"] = qc
		if _url_flag("mana"):
			# Aperçu : mana qui se recharge 20 fois plus vite (« &mana=1 »).
			extra["debug_mana"] = true
		_start(direct, _url_flag("solo"), extra)
		var hp := float(str(_query().get("nexus", "0")))
		if hp > 0.0 and hp < 1.0:
			# Débogage : démarre avec l'objectif entamé (ex. « &nexus=0.67 »).
			(_screen as BattleScreen).sim.debug_set_ratio(hp)
		return
	_boot()


func _boot() -> void:
	_show_loading()
	var t0 := Time.get_ticks_msec()
	var resumed: bool = await cloud.resume()
	if resumed:
		await cloud.sync_pull()
	# L'écran de chargement reste au moins 1,2 s (évite un simple éclair).
	var wait := 1.2 - float(Time.get_ticks_msec() - t0) / 1000.0
	if wait > 0.0:
		await get_tree().create_timer(wait).timeout
	if resumed:
		_show_hub()
	elif bool(Profile.data["settings"].get("guest", false)) or Profile.updated() > 0.0:
		_show_hub()
	else:
		_show_login(false)


func _set_screen(c: Control) -> void:
	if _screen != null and is_instance_valid(_screen):
		_screen.queue_free()
	_screen = c
	add_child(c)


func _show_loading() -> void:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(c, 0.22)
	# Titre « ARCANE / SURGE » et séparateur runique, en haut.
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 0)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = get_viewport_rect().size.y * 0.1
	for part in [["ARCANE", UiTheme.GOLD], ["SURGE", UiTheme.TEXT]]:
		var l := UiTheme.title(str(part[0]), 92, part[1])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.08))
		l.add_theme_constant_override("outline_size", 10)
		top.add_child(l)
	var div := HBoxContainer.new()
	div.alignment = BoxContainer.ALIGNMENT_CENTER
	div.add_theme_constant_override("separation", 14)
	top.add_child(div)
	for i in range(3):
		if i == 1:
			div.add_child(UiTheme.icon_rect("rune", 30, UiTheme.TEAL))
		else:
			var r := UiTheme.rule(Color(UiTheme.GOLD, 0.7))
			r.custom_minimum_size = Vector2(150, 2)
			r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			div.add_child(r)
	# « Éveil des runes » et barre de chargement, en bas.
	var bot := VBoxContainer.new()
	bot.add_theme_constant_override("separation", 8)
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(bot)
	bot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_top = -170.0
	bot.offset_bottom = -60.0
	var cap := UiTheme.title("ÉVEIL DES RUNES", 20, UiTheme.GOLD)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot.add_child(cap)
	var bar := UiTheme.bar(UiTheme.TEAL, 6)
	bar.custom_minimum_size = Vector2(320, 6)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bot.add_child(bar)
	var sub := UiTheme.label("Chargement…", 18, UiTheme.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot.add_child(sub)
	_set_screen(c)
	var tw := c.create_tween()
	tw.tween_property(bar, "value", 100.0, 1.2)


func _show_login(from_hub: bool) -> void:
	var s := LoginScreen.new()
	s.from_hub = from_hub
	s.done.connect(_show_hub)
	_set_screen(s)


func _show_hub() -> void:
	# Sauvegarde antérieure à la narration : un choix de l'histoire n'a jamais été fait.
	var pend := Dialogues.pending_choice_scene()
	if pend != "" and not _offered.has(pend):
		_offered[pend] = true
		_show_dialogue([pend], _show_hub)
		return
	if not Profile.created():
		# Création du personnage (une fois, y compris pour une partie déjà avancée).
		_show_creation(false)
		return
	var h := HubScreen.new()
	h.open_mirror.connect(_show_creation.bind(true))
	h.open_map.connect(_show_map)
	h.open_equipment.connect(_show_equipment)
	h.open_login.connect(_show_login.bind(true))
	h.open_save.connect(_show_save)
	h.open_skills.connect(_show_room.bind("skills"))
	h.open_library.connect(_show_room.bind("library"))
	h.open_circle.connect(_show_room.bind("circle"))
	h.play_level.connect(func(id: String) -> void: _play(id, false, true))
	_set_screen(h)


## Création du personnage (première fois) ou Miroir (apparence seule).
func _show_creation(mirror: bool) -> void:
	var c := CreationScreen.new()
	c.mirror = mirror
	c.done.connect(func() -> void:
		Profile.set_created()
		Profile.save_local()
		if cloud != null:
			cloud.push()
		_show_hub())
	c.back.connect(func() -> void:
		Profile.save_local()
		_show_hub())
	_set_screen(c)


func _show_map() -> void:
	var m := MapScreen.new()
	m.back.connect(_show_hub)
	m.play.connect(_play)
	_set_screen(m)


## Salles de Havre-Aube : Entraînement (arbre), Bibliothèque (deck), Cercle (compagnons).
func _show_room(which: String) -> void:
	var s: Control
	match which:
		"skills":
			s = SkillTreeScreen.new()
		"library":
			s = LibraryScreen.new()
		_:
			s = CircleScreen.new()
	s.connect("back", _show_hub)
	_set_screen(s)


func _show_save() -> void:
	var s := SaveScreen.new()
	s.back.connect(_show_hub)
	s.open_login.connect(_show_login.bind(true))
	_set_screen(s)


func _show_equipment() -> void:
	var e := EquipmentScreen.new()
	e.back.connect(_show_hub)
	_set_screen(e)


func _show_dialogue(ids: Array, then: Callable) -> void:
	var d := DialogueScreen.new()
	d.configure(ids)
	d.finished.connect(then)
	_set_screen(d)


## Avant un niveau : le prologue (toute première partie), puis l'intro du niveau si elle n'a jamais été vue.
## Avant un combat : écran de préparation (Deck ou Tiroir), puis dialogues d'introduction et combat.
func _play(level_id: String, solo: bool, from_hub: bool = false) -> void:
	var p := PrepScreen.new()
	p.level_id = level_id
	p.back.connect(_show_hub if from_hub else _show_map)
	p.start.connect(_launch.bind(level_id, solo))
	_set_screen(p)


func _launch(level_id: String, solo: bool) -> void:
	var ids: Array[String] = []
	if level_id == "z01_l01" and not Story.seen("prologue") and int(Profile.level_record("z01_l01")["clears"]) == 0:
		ids.append("prologue")
	var intro := level_id + "_intro"
	if Dialogues.has_scene(intro) and not Story.seen(intro):
		ids.append(intro)
	if ids.is_empty():
		_start(level_id, solo)
	else:
		_show_dialogue(ids, _start.bind(level_id, solo))


func _start(level_id: String, solo: bool, extra: Dictionary = {}) -> void:
	var b := BattleScreen.new()
	b.configure(level_id, solo, Profile.battle_opts().merged(extra, true))
	b.exit_requested.connect(func(dest: String) -> void: _after_battle(dest, b, level_id, solo))
	b.restart_requested.connect(func() -> void: _after_battle("restart", b, level_id, solo))
	_set_screen(b)


## Après une 1re victoire, le dialogue de fin (et ses choix) se joue avant de quitter l'écran de combat.
func _after_battle(dest: String, b: BattleScreen, level_id: String, solo: bool) -> void:
	var outro := level_id + "_outro"
	var won := b.sim != null and b.sim.state == "victory"
	if won and Dialogues.has_scene(outro) and not Story.seen(outro):
		_show_dialogue([outro], _go.bind(dest, level_id, solo))
	else:
		_go(dest, level_id, solo)


func _go(dest: String, level_id: String, solo: bool) -> void:
	match dest:
		"restart":
			_start(level_id, solo)
		"hub":
			_show_hub()
		_:
			_show_map()


## Web : « ?level=z01_l08 » ouvre directement un niveau (« &solo=1 » pour le mode solo, « &krag=1 »
## pour emmener Krag, « &deck=orage,comete » pour imposer des sorts, « &mana=1 » pour un mana rapide,
## « &mode=drawer » pour le tiroir de sorts).
func _level_from_url() -> String:
	var q := _query()
	var id := str(q.get("level", ""))
	if id != "" and (GameData.level_index().get("levels", []) as Array).has(id):
		return id
	return ""


func _url_flag(key: String) -> bool:
	return str(_query().get(key, "")) in ["1", "true", "oui"]


func _query() -> Dictionary:
	var out := {}
	if not OS.has_feature("web"):
		return out
	var search := str(JavaScriptBridge.eval("window.location.search", true))
	for part in search.trim_prefix("?").split("&", false):
		var kv := part.split("=", true, 1)
		out[kv[0]] = kv[1] if kv.size() > 1 else "1"
	return out
