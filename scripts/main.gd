extends Control
## Point d'entrée : menu des niveaux ↔ écran de combat.

var _screen: Control


func _ready() -> void:
	RenderingServer.set_default_clear_color(UiTheme.BG)
	theme = UiTheme.build()
	var direct := _level_from_url()
	if direct != "":
		_start(direct, _url_flag("solo"))
		var hp := float(str(_query().get("nexus", "0")))
		if hp > 0.0 and hp < 1.0:
			# Débogage : démarre avec le Nexus entamé (ex. « &nexus=0.67 »).
			var b := _screen as BattleScreen
			b.sim.nexus_hp = b.sim.nexus_max * hp
	else:
		_show_menu()


func _set_screen(c: Control) -> void:
	if _screen != null and is_instance_valid(_screen):
		_screen.queue_free()
	_screen = c
	add_child(c)


func _show_menu() -> void:
	var m := LevelSelect.new()
	m.start_level.connect(_start)
	_set_screen(m)


func _start(level_id: String, solo: bool) -> void:
	var b := BattleScreen.new()
	b.configure(level_id, solo)
	b.exit_requested.connect(_show_menu)
	b.restart_requested.connect(_start.bind(level_id, solo))
	_set_screen(b)


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
