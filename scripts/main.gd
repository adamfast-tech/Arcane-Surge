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
	if _url_flag("fx"):
		# Aperçu de l'ambiance enrichie (« &fx=1 »), sans changer la sauvegarde.
		Profile._options()["ambience"] = true
	RuneBox.rich = Profile.ambience_on()
	if str(_query().get("hour", "")) != "":
		# Aperçu de Havre-Aube à une autre heure (« &hour=22 »).
		Ambience.hour_override = int(str(_query().get("hour", "")))
	var scene := str(_query().get("scene", ""))
	if Dialogues.has_scene(scene):
		# Aperçu d'une scène de dialogue (« ?scene=z01_l10_outro »).
		_show_dialogue([scene], _boot)
		return
	var room := str(_query().get("room", ""))
	if _url_flag("gear"):
		# Aperçu : un assortiment d'objets et de runes (« &gear=1 »), pour la Forge et l'Équipement.
		_preview_gear()
	if str(_query().get("prog", "")) != "":
		# Aperçu : les N premiers niveaux gagnés (« &prog=14 »), avec des étoiles variées.
		_preview_progress(int(str(_query().get("prog", "0"))))
	if str(_query().get("lvl", "")) != "":
		# Aperçu : héros à un niveau donné (« &lvl=40 »), et quelques points investis dans l'arbre (« &build=1 »).
		Profile.data["player"]["level"] = int(str(_query().get("lvl", "1")))
		if str(_query().get("class", "")) != "":
			Profile.data["player"]["class"] = str(_query().get("class", ""))
		if _url_flag("build"):
			_preview_build()
	if room in ["meditation", "circle", "skills", "library", "options"]:
		# Aperçu d'une salle (« ?room=meditation », « ?room=library&tab=classes&class=archer »), sans écran de chargement.
		if str(_query().get("class", "")) != "":
			Profile.data["player"]["class"] = str(_query().get("class", ""))
		_show_room(room)
		if room == "library" and str(_query().get("tab", "")) != "":
			_screen.set("_school", str(_query().get("tab", "")))
			_screen.call("_rebuild")
		return
	if room == "map":
		# Aperçu de la carte (« ?room=map », « &zone=3 »).
		_show_map(int(str(_query().get("zone", "0"))))
		return
	if room == "hub":
		# Aperçu de Havre-Aube (« ?room=hub ») : héros déjà créé, sans écran de connexion.
		Profile.data["player"]["created"] = true
		_show_hub()
		return
	if room == "equipment":
		_show_equipment(str(_query().get("who", "player")))
		return
	if room == "forge":
		# Aperçu de la Forge (« ?room=forge&tab=fusion »).
		_show_forge()
		if str(_query().get("tab", "")) != "":
			_screen.set("tab", str(_query().get("tab", "")))
			_screen.call("_rebuild")
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
		if _url_flag("win"):
			# Aperçu : victoire immédiate (écran de fin, butin).
			extra["debug_win"] = true
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


## Éclat au toucher (option) : une gerbe d'étincelles là où l'on touche, hors combat.
var _spark_layer: CanvasLayer


func _input(ev: InputEvent) -> void:
	if not Profile.sparkle_on() or _screen is BattleScreen:
		return
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_sparkle((ev as InputEventMouseButton).position)


func _sparkle(at: Vector2) -> void:
	if _spark_layer == null:
		_spark_layer = CanvasLayer.new()
		_spark_layer.layer = 100
		add_child(_spark_layer)
	var p := CPUParticles2D.new()
	p.texture = LootFx._soft()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = add
	p.position = at
	p.amount = 16
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.55
	p.spread = 180.0
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 140.0
	p.gravity = Vector2(0, 120)
	p.damping_min = 40.0
	p.damping_max = 80.0
	p.scale_amount_min = 0.1
	p.scale_amount_max = 0.28
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(UiTheme.GOLD, 0.9), Color(UiTheme.TEAL, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	p.color_ramp = g
	p.emitting = true
	_spark_layer.add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _set_screen(c: Control) -> void:
	if _screen != null and is_instance_valid(_screen):
		_screen.queue_free()
	_screen = c
	add_child(c)
	_screen_sound(c)
	if Profile.ambience_on():
		# Ambiance enrichie : chaque écran apparaît en fondu.
		c.modulate.a = 0.0
		c.create_tween().tween_property(c, "modulate:a", 1.0, 0.25)


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
	h.open_forge.connect(func() -> void: _show_forge())
	h.open_skills.connect(_show_room.bind("skills"))
	h.open_library.connect(_show_room.bind("library"))
	h.open_circle.connect(_show_room.bind("circle"))
	h.open_meditation.connect(_show_room.bind("meditation"))
	h.open_options.connect(_show_room.bind("options"))
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


func _show_map(z: int = 0) -> void:
	var m := MapScreen.new()
	m.zone = z
	m.back.connect(_show_hub)
	m.play.connect(_play)
	_set_screen(m)


## Salles de Havre-Aube : Entraînement (arbre), Bibliothèque (deck), Cercle (compagnons), Méditation.
func _show_room(which: String) -> void:
	var s: Control
	match which:
		"skills":
			s = SkillTreeScreen.new()
		"library":
			s = LibraryScreen.new()
		"meditation":
			s = MeditationScreen.new()
		"options":
			s = OptionsScreen.new()
		_:
			var cs := CircleScreen.new()
			cs.open_equipment.connect(func(who: String) -> void: _show_equipment(who, true))
			s = cs
	s.connect("back", _show_hub)
	_set_screen(s)


func _show_save() -> void:
	var s := SaveScreen.new()
	s.back.connect(_show_hub)
	s.open_login.connect(_show_login.bind(true))
	_set_screen(s)


## Équipement : du héros (depuis Havre-Aube) ou d'un compagnon (depuis le Cercle, qui reprend au retour).
func _show_equipment(who: String = "player", from_circle: bool = false) -> void:
	var e := EquipmentScreen.new()
	e.who = who
	if from_circle:
		e.back.connect(_show_room.bind("circle"))
	else:
		e.back.connect(_show_hub)
	e.open_forge.connect(func(uid: String) -> void: _show_forge(uid, "equipment", who))
	_set_screen(e)


func _preview_build() -> void:
	var br: Dictionary = (Profile.tree_db().get("branches", []) as Array)[0]
	for pass_i in range(6):
		for tier in br.get("tiers", []):
			for node in tier["nodes"]:
				var id := str(node["id"])
				if Profile.skill_points_spent() < 26 and Profile.invest_block(id) == "" and (Profile.skill_rank(id) < 2 or str(node.get("kind", "")) != "passive"):
					Profile.invest(id)


func _preview_progress(n: int) -> void:
	var ids: Array = GameData.level_index()["levels"]
	for i in range(mini(n, ids.size())):
		Profile.data["levels"][str(ids[i])] = {"stars": 3 - (i * 7) % 3 if i % 4 != 3 else 1, "best": 140.0 + float(i * 13 % 90), "clears": 1}


func _preview_gear() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	Profile.data["gold"] = 50000
	var picks := [["sceptre_solaire", "legendaire"], ["cuirasse_naine", "epique"], ["heaume_cornu", "rare"], ["amulette_scarabee", "epique"],
		["faux_cendres", "rare"], ["lame_verre", "epique"], ["gants_cuir", "commun"], ["bottes_marche", "commun"], ["capuche_toile", "commun"],
		["arc_dunes", "rare"], ["coiffe_sables", "legendaire"], ["sablier_fige", "rare"], ["tome_college", "epique"], ["hache_givre", "commun"]]
	for pk in picks:
		var it := Profile.make_item(str(pk[0]), str(pk[1]), 40, rng)
		(Profile.data["inventory"] as Array).append(it)
		if pk[0] in ["sceptre_solaire", "cuirasse_naine", "heaume_cornu", "amulette_scarabee"]:
			Profile.equip(str(it["uid"]))
	var w := Profile.find_item(str(Profile.equipment_of("player").get("weapon", "")))
	w["runes"] = [Profile.make_rune("pyr", 4, "epique"), Profile.make_rune("kaor", 3, "rare")]
	for rr in [["isa", 3, "rare"], ["isa", 3, "rare"], ["isa", 3, "rare"], ["lux", 2, "epique"], ["wyrd", 4, "legendaire"], ["mult", 1, "commun"], ["gard", 2, "rare"]]:
		Profile.rune_inventory().append(Profile.make_rune(str(rr[0]), int(rr[1]), str(rr[2])))


## La Forge (gravure, fusion, runes) : depuis Havre-Aube, ou depuis l'Équipement (avec l'objet choisi).
func _show_forge(uid: String = "", origin: String = "hub", who: String = "player") -> void:
	var f := ForgeScreen.new()
	f.focus_item = uid
	if origin == "equipment":
		f.back_label = "Équipement"
		f.back.connect(func() -> void: _show_equipment(who))
	else:
		f.back.connect(_show_hub)
	_set_screen(f)


func _show_dialogue(ids: Array, then: Callable, replay: bool = false) -> void:
	var d := DialogueScreen.new()
	d.configure(ids)
	d.replay = replay
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
	var replay := _replaying(level_id)
	if Dialogues.has_scene(intro) and (not Story.seen(intro) or replay):
		ids.append(intro)
	if ids.is_empty():
		_start(level_id, solo)
	else:
		_show_dialogue(ids, _start.bind(level_id, solo), replay and Story.seen(intro))


## Mission déjà réussie, avec « Revoir les cinématiques » choisi à la préparation.
func _replaying(level_id: String) -> bool:
	return Profile.replay_scenes() and Profile.can_replay_scenes(level_id)


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
	elif won and Dialogues.has_scene(outro) and _replaying(level_id):
		_show_dialogue([outro], _go.bind(dest, level_id, solo), true)
	else:
		_go(dest, level_id, solo)


func _go(dest: String, level_id: String, solo: bool) -> void:
	match dest:
		"restart":
			_start(level_id, solo)
		"hub":
			_show_hub()
		"equipment":
			_show_equipment()
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



## Musique et ambiance de chaque écran (docs/design/43-audio.md). Le combat et les cinématiques ont les leurs
## (BattleAudio, CineAudio).
func _screen_sound(c: Control) -> void:
	if c is BattleScreen or c is DialogueScreen:
		return
	var music := "havre"
	var amb: Dictionary = {"havre": -12.0}
	if c is MapScreen:
		music = "map"
		amb = {"wind_plains": -16.0}
	elif c is LibraryScreen or c is SaveScreen or c is OptionsScreen:
		amb = {"library": -10.0}
	elif c is MeditationScreen:
		amb = {"meditation": -8.0}
	elif c is CircleScreen or c is PrepScreen:
		amb = {"campfire": -10.0}
	elif c is ForgeScreen or c is EquipmentScreen:
		amb = {"forge": -10.0}
	elif c is SkillTreeScreen:
		amb = {"forest_day": -12.0}
	elif c is LoginScreen or c is CreationScreen:
		amb = {"forest_night": -12.0}
	Snd.music(music, 1.8, -4.0)
	Snd.ambience(amb, 1.5)
