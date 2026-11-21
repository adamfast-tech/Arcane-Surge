class_name Dialogues
extends RefCounted
## Accès aux scènes de dialogue et aux répliques de combat (data/dialogues/<langue>/zNN.json).
## Une scène « zNN_lMM_intro » se joue avant le niveau, « zNN_lMM_outro » après la 1re victoire.

const LANG := "fr"


static func db(zone: int = 1) -> Dictionary:
	return GameData.load_json("res://data/dialogues/%s/z%02d.json" % [LANG, zone])


static func zone_of(scene_or_level: String) -> int:
	if scene_or_level.begins_with("z") and scene_or_level.length() >= 3 and scene_or_level.substr(1, 2).is_valid_int():
		return int(scene_or_level.substr(1, 2))
	return 1


static func scene(id: String) -> Dictionary:
	return (db(zone_of(id)).get("scenes", {}) as Dictionary).get(id, {})


static func has_scene(id: String) -> bool:
	return not scene(id).is_empty()


static func character(who: String, zone: int = 1) -> Dictionary:
	return (db(zone).get("characters", {}) as Dictionary).get(who, {"name": who.capitalize(), "color": "ECE8FF"})


static func fmt(text: String) -> String:
	return text.replace("{pseudo}", Story.player_name())


## Nom affiché, titre (faction, loyauté) et couleur d'un personnage.
static func display_name(who: String) -> String:
	return fmt(str(character(who).get("name", who)))


static func subtitle(who: String) -> String:
	var c := character(who)
	var t := str(c.get("title", ""))
	var tf: Dictionary = c.get("title_flag", {})
	for f in tf.keys():
		if Story.has_flag(str(f)):
			t = str(tf[f])
	if bool(c.get("loyalty", false)):
		t += (" · " if t != "" else "") + "loyauté %d" % Story.loyalty(who)
	return t


static func color(who: String) -> Color:
	return Color(str(character(who).get("color", "ECE8FF")))


## Identifiant du choix contenu dans une scène ("" s'il n'y en a pas).
static func choice_of(scene_id: String) -> String:
	for l in scene(scene_id).get("lines", []):
		if (l as Dictionary).has("choice"):
			return str(l["choice"])
	return ""


## Scène de fin d'un niveau déjà gagné dont le choix n'a jamais été fait (sauvegardes antérieures
## à la narration) : elle est proposée à l'arrivée à Havre-Aube.
static func pending_choice_scene() -> String:
	for id in GameData.level_index().get("levels", []):
		var sid := "%s_outro" % str(id)
		var cid := choice_of(sid)
		if cid == "" or Story.choice(cid) != "":
			continue
		if int(Profile.level_record(str(id))["clears"]) > 0:
			return sid
	return ""


## Répliques de combat possibles pour un déclencheur, parmi les compagnons présents.
## Celles propres au niveau passent en priorité.
static func barks(level_id: String, trigger: String, present: Array[String]) -> Array[Dictionary]:
	var d := db(zone_of(level_id))
	var lists: Array = []
	var per: Dictionary = (d.get("barks_level", {}) as Dictionary).get(level_id, {})
	if per.has(trigger):
		lists.append(per[trigger])
	lists.append((d.get("barks", {}) as Dictionary).get(trigger, []))
	for list in lists:
		var out: Array[Dictionary] = []
		for b in list:
			if present.has(str(b.get("who", ""))) and Story.check(b):
				out.append(b)
		if not out.is_empty():
			return out
	return []
