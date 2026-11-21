class_name GameData
extends RefCounted
## Accès aux données du jeu (fichiers JSON dans res://data), mis en cache.

static var _cache: Dictionary = {}


static func load_json(path: String) -> Variant:
	if _cache.has(path):
		return _cache[path]
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("GameData : impossible d'ouvrir %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed == null:
		push_error("GameData : JSON invalide dans %s" % path)
		return {}
	_cache[path] = parsed
	return parsed


static func units() -> Dictionary:
	return load_json("res://data/units.json")


static func spells() -> Dictionary:
	return load_json("res://data/spells.json")


static func echoes() -> Array:
	return load_json("res://data/echoes.json")


static func party() -> Dictionary:
	return load_json("res://data/party.json")


static func level_index() -> Dictionary:
	return load_json("res://data/levels/index.json")


static func level(id: String) -> Dictionary:
	return load_json("res://data/levels/%s.json" % id)
