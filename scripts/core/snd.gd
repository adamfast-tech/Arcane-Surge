class_name Snd
extends RefCounted
## Accès au son depuis n'importe quel script (fonctions statiques) : relaie vers l'autoload « Audio »
## (scripts/core/audio.gd) s'il existe, ne fait rien sinon (outils en ligne de commande).


static func _a() -> Node:
	var ml := Engine.get_main_loop()
	if ml is SceneTree:
		return (ml as SceneTree).root.get_node_or_null("Audio")
	return null


static func sfx(name: String, vol_db: float = 0.0, pitch: float = 1.0, gap: float = 0.0) -> void:
	var a := _a()
	if a != null:
		a.call("sfx", name, vol_db, pitch, gap)


static func loop_for(name: String, dur: float, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	var a := _a()
	if a != null:
		a.call("loop_for", name, dur, vol_db, pitch)


static func music(name: String, fade: float = 1.6, vol_db: float = 0.0) -> void:
	var a := _a()
	if a != null:
		a.call("music", name, fade, vol_db)


static func music_name() -> String:
	var a := _a()
	return str(a.call("music_name")) if a != null else ""


static func ambience(layers: Dictionary, fade: float = 1.5) -> void:
	var a := _a()
	if a != null:
		a.call("ambience", layers, fade)


static func voice(name: String, idx: int, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	var a := _a()
	if a != null:
		a.call("voice", name, idx, vol_db, pitch)


static func duck(db: float) -> void:
	var a := _a()
	if a != null:
		a.call("duck", db)


static func preload_list(paths: Array) -> void:
	var a := _a()
	if a != null:
		a.call("preload_list", paths)


static func stop_all(fade: float = 0.6) -> void:
	var a := _a()
	if a != null:
		a.call("stop_all", fade)


static func apply_volumes() -> void:
	var a := _a()
	if a != null:
		a.call("apply_volumes")


static func has(path: String) -> bool:
	return ResourceLoader.exists("res://assets/audio/%s.ogg" % path)


## Derniers sons joués (tests).
static func played() -> Array:
	var a := _a()
	return (a.get("played") as Array) if a != null else []


## Clic d'interface, sur tous les boutons créés par UiTheme.
static func click() -> void:
	sfx("ui_click", -2.0, randf_range(0.97, 1.03), 0.04)
