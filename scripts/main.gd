extends Control
## Point d'entrée et navigation : connexion → Havre-Aube → carte / équipement → combat → récompenses.

var _screen: Control
var cloud: Cloud


func _ready() -> void:
	RenderingServer.set_default_clear_color(UiTheme.BG)
	theme = UiTheme.build()
	cloud = Cloud.new()
	add_child(cloud)
	Profile.load_local()
	var direct := _level_from_url()
	if direct != "":
		_start(direct, _url_flag("solo"))
		var hp := float(str(_query().get("nexus", "0")))
		if hp > 0.0 and hp < 1.0:
			# Débogage : démarre avec l'objectif entamé (ex. « &nexus=0.67 »).
			(_screen as BattleScreen).sim.debug_set_ratio(hp)
		return
	_boot()


func _boot() -> void:
	_show_loading()
	var resumed: bool = await cloud.resume()
	if resumed:
		await cloud.sync_pull()
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
	UiTheme.backdrop(c, 0.6)
	var l := UiTheme.title("ARCANE SURGE", 56, UiTheme.GOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_screen(c)


func _show_login(from_hub: bool) -> void:
	var s := LoginScreen.new()
	s.from_hub = from_hub
	s.done.connect(_show_hub)
	_set_screen(s)


func _show_hub() -> void:
	var h := HubScreen.new()
	h.open_map.connect(_show_map)
	h.open_equipment.connect(_show_equipment)
	h.open_login.connect(_show_login.bind(true))
	h.play_level.connect(func(id: String) -> void: _start(id, false))
	_set_screen(h)


func _show_map() -> void:
	var m := MapScreen.new()
	m.back.connect(_show_hub)
	m.play.connect(_start)
	_set_screen(m)


func _show_equipment() -> void:
	var e := EquipmentScreen.new()
	e.back.connect(_show_hub)
	_set_screen(e)


func _start(level_id: String, solo: bool) -> void:
	var b := BattleScreen.new()
	b.configure(level_id, solo, Profile.battle_opts())
	b.exit_requested.connect(_on_battle_exit)
	b.restart_requested.connect(_start.bind(level_id, solo))
	_set_screen(b)


func _on_battle_exit(dest: String) -> void:
	if dest == "hub":
		_show_hub()
	else:
		_show_map()


## Web : « ?level=z01_l08 » ouvre directement un niveau (« &solo=1 » pour le mode solo).
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
