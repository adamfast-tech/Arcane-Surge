class_name Profile
extends RefCounted
## Progression du joueur : niveau, XP, or, poussière, matériaux, inventaire, équipement,
## niveaux terminés. Sauvegarde locale (user://save.json), synchronisée par Cloud.
## Les identifiants d'objets sont des chaînes (« i12 ») pour survivre au passage en JSON.

## Fichier de sauvegarde locale (les outils de test en utilisent un autre).
static var save_path := "user://save.json"
const VERSION := 1
const STATS := ["pou", "vig", "esp", "cel", "des"]

static var data: Dictionary = {}


static func items_db() -> Dictionary:
	return GameData.load_json("res://data/items.json")


static func prog_db() -> Dictionary:
	return GameData.load_json("res://data/progression.json")


static func default_data() -> Dictionary:
	return {
		"v": VERSION, "updated": 0.0,
		"player": {"level": 1, "xp": 0, "class": "mage", "race": "elfe", "skill_points": 0},
		"gold": 0, "dust": 0, "materials": {}, "inventory": [], "equipped": {}, "levels": {},
		"settings": {"guest": false, "auto_fire": false}, "next_uid": 1,
		"story": Story.default_state(),
	}


# ---------------------------------------------------------------- sauvegarde

static func load_local() -> void:
	data = default_data()
	if FileAccess.file_exists(save_path):
		var f := FileAccess.open(save_path, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				replace_with(parsed)
				return
	_give_starter()


## Remplace la progression (chargement local ou cloud) en complétant les clés manquantes.
static func replace_with(src: Dictionary) -> void:
	var def := default_data()
	data = src.duplicate(true)
	for k in def.keys():
		if not data.has(k):
			data[k] = def[k]
	for k in (def["player"] as Dictionary).keys():
		if not (data["player"] as Dictionary).has(k):
			data["player"][k] = def["player"][k]
	for k in (def["settings"] as Dictionary).keys():
		if not (data["settings"] as Dictionary).has(k):
			data["settings"][k] = def["settings"][k]
	if (data["inventory"] as Array).is_empty():
		_give_starter()


static func save_local() -> void:
	data["updated"] = Time.get_unix_time_from_system()
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_warning("Profile : sauvegarde locale impossible")
		return
	f.store_string(JSON.stringify(data))
	f.close()


static func updated() -> float:
	return float(data.get("updated", 0.0))


static func _give_starter() -> void:
	var rng := RandomNumberGenerator.new()
	for s in items_db()["starter"]:
		var it := make_item(str(s["base"]), str(s["rarity"]), int(s["ilvl"]), rng)
		(data["inventory"] as Array).append(it)
		equip(str(it["uid"]))


# ---------------------------------------------------------------- joueur

static func level() -> int:
	return int(data["player"]["level"])


static func xp() -> int:
	return int(data["player"]["xp"])


static func xp_to_next(lv: int = -1) -> int:
	var p := prog_db()
	var l := level() if lv < 0 else lv
	return int(float(p["xp_base"]) * pow(float(l), float(p["xp_exp"])))


## Ajoute de l'XP et retourne le nombre de niveaux gagnés.
static func add_xp(amount: int) -> int:
	var gained := 0
	var x := xp() + amount
	var lv := level()
	var max_lv := int(prog_db()["max_level"])
	while lv < max_lv and x >= xp_to_next(lv):
		x -= xp_to_next(lv)
		lv += 1
		gained += 1
	data["player"]["xp"] = x
	data["player"]["level"] = lv
	data["player"]["skill_points"] = int(data["player"]["skill_points"]) + gained
	return gained


static func gold() -> int:
	return int(data["gold"])


static func dust() -> int:
	return int(data["dust"])


## Stats du personnage : classe + progression par niveau + race + équipement.
static func stats(lv: int = -1, with_gear: bool = true) -> Dictionary:
	var party := GameData.party()
	var p: Dictionary = data["player"]
	var cls: Dictionary = party["classes"][str(p["class"])]
	var race: Dictionary = party["races"].get(str(p["race"]), {})
	var l := level() if lv < 0 else lv
	var gear := gear_stats() if with_gear else {}
	var out := {}
	for k in STATS:
		var b := float(cls["base"].get(k, 0))
		out[k] = b + b / 10.0 * float(l - 1) + float(race.get(k, 0)) + float(gear.get(k, 0))
	return out


static func power() -> int:
	var s := stats()
	var total := 0.0
	for k in STATS:
		total += float(s[k])
	return int(round(total * 1.6))


## Puissance attendue pour un niveau global (personnage du même niveau, équipement commun).
static func recommended_power(global_level: int) -> int:
	var s := stats(global_level, false)
	var total := 0.0
	for k in STATS:
		total += float(s[k])
	total += 8.0 + 1.6 * float(global_level)
	return int(round(total * 1.6))


# ---------------------------------------------------------------- objets

static func make_item(base_id: String, rarity: String, ilvl: int, rng: RandomNumberGenerator) -> Dictionary:
	var db := items_db()
	var base: Dictionary = db["bases"][base_id]
	var rar: Dictionary = db["rarities"][rarity]
	var scale := (1.0 + 0.12 * float(ilvl - 1)) * float(rar["mult"])
	var st := {}
	for k in (base["stats"] as Dictionary).keys():
		st[k] = maxi(1, int(round(float(base["stats"][k]) * scale)))
	var affixes := {}
	for i in range(int(rar["affixes"])):
		var k: String = STATS[rng.randi_range(0, STATS.size() - 1)]
		affixes[k] = int(affixes.get(k, 0)) + maxi(1, int(round(rng.randf_range(1.0, 3.0) * (1.0 + 0.1 * float(ilvl - 1)))))
	var uid := "i%d" % int(data["next_uid"])
	data["next_uid"] = int(data["next_uid"]) + 1
	return {"uid": uid, "base": base_id, "rarity": rarity, "ilvl": ilvl, "up": 0, "stats": st, "affixes": affixes}


static func find_item(uid: String) -> Dictionary:
	for it in data["inventory"]:
		if str(it["uid"]) == uid:
			return it
	return {}


static func base_of(item: Dictionary) -> Dictionary:
	return items_db()["bases"].get(str(item.get("base", "")), {})


static func rarity_of(item: Dictionary) -> Dictionary:
	return items_db()["rarities"].get(str(item.get("rarity", "commun")), {})


static func item_name(item: Dictionary) -> String:
	var n := str(base_of(item).get("name", "?"))
	var up := int(item.get("up", 0))
	return n + (" +%d" % up if up > 0 else "")


static func item_color(item: Dictionary) -> Color:
	return Color(str(rarity_of(item).get("color", "B8B8C8")))


## Stats finales d'un objet (amélioration comprise).
static func item_stats(item: Dictionary) -> Dictionary:
	var out := {}
	var mult := 1.0 + float(prog_db()["upgrade"]["per_level"]) * float(item.get("up", 0))
	for k in (item.get("stats", {}) as Dictionary).keys():
		out[k] = int(round(float(item["stats"][k]) * mult))
	for k in (item.get("affixes", {}) as Dictionary).keys():
		out[k] = int(out.get(k, 0)) + int(item["affixes"][k])
	return out


static func stats_text(st: Dictionary) -> String:
	var names: Dictionary = items_db()["stat_names"]
	var parts: Array[String] = []
	for k in STATS:
		if st.has(k):
			parts.append("+%d %s" % [int(st[k]), str(names[k])])
	return " · ".join(parts)


static func equipped_slot(uid: String) -> String:
	for s in (data["equipped"] as Dictionary).keys():
		if str(data["equipped"][s]) == uid:
			return str(s)
	return ""


static func equip(uid: String) -> void:
	var it := find_item(uid)
	if it.is_empty():
		return
	var slot := str(base_of(it).get("slot", ""))
	if slot == "ring":
		var eq: Dictionary = data["equipped"]
		if not eq.has("ring1"):
			slot = "ring1"
		elif not eq.has("ring2"):
			slot = "ring2"
		else:
			slot = "ring1"
	var current := equipped_slot(uid)
	if current != "":
		data["equipped"].erase(current)
	data["equipped"][slot] = uid


static func unequip(slot: String) -> void:
	data["equipped"].erase(slot)


static func gear_stats() -> Dictionary:
	var out := {}
	for s in (data["equipped"] as Dictionary).keys():
		var it := find_item(str(data["equipped"][s]))
		if it.is_empty():
			continue
		var st := item_stats(it)
		for k in st.keys():
			out[k] = int(out.get(k, 0)) + int(st[k])
	return out


static func weapon_element() -> String:
	var uid := str(data["equipped"].get("weapon", ""))
	if uid == "":
		return "physique"
	return str(base_of(find_item(uid)).get("element", "physique"))


static func upgrade_cost(item: Dictionary) -> int:
	var up := int(item.get("up", 0))
	var value := float(rarity_of(item).get("value", 1))
	return int(round(float(prog_db()["upgrade"]["gold_base"]) * float(up + 1) * (1.0 + value * 0.25) * (1.0 + float(item.get("ilvl", 1)) * 0.1)))


static func can_upgrade(item: Dictionary) -> bool:
	return int(item.get("up", 0)) < int(rarity_of(item).get("max_up", 5)) and gold() >= upgrade_cost(item)


static func upgrade(uid: String) -> bool:
	var it := find_item(uid)
	if it.is_empty() or not can_upgrade(it):
		return false
	data["gold"] = gold() - upgrade_cost(it)
	it["up"] = int(it.get("up", 0)) + 1
	return true


static func salvage_value(item: Dictionary) -> int:
	return int(prog_db()["salvage_dust"]) * int(rarity_of(item).get("value", 1)) * (1 + int(item.get("up", 0)))


static func salvage(uid: String) -> int:
	if equipped_slot(uid) != "":
		return 0
	var inv: Array = data["inventory"]
	for i in range(inv.size()):
		if str(inv[i]["uid"]) == uid:
			var v := salvage_value(inv[i])
			inv.remove_at(i)
			data["dust"] = dust() + v
			return v
	return 0


# ---------------------------------------------------------------- niveaux et récompenses

static func level_record(level_id: String) -> Dictionary:
	return data["levels"].get(level_id, {"stars": 0, "best": 0.0, "clears": 0})


static func is_unlocked(level_id: String) -> bool:
	var ids: Array = GameData.level_index()["levels"]
	var i := ids.find(level_id)
	if i <= 0:
		return true
	return int(level_record(str(ids[i - 1]))["clears"]) > 0


static func next_level() -> String:
	var ids: Array = GameData.level_index()["levels"]
	for id in ids:
		if int(level_record(str(id))["clears"]) == 0:
			return str(id)
	return str(ids[ids.size() - 1])


static func stars_total() -> int:
	var n := 0
	for k in (data["levels"] as Dictionary).keys():
		n += int(data["levels"][k].get("stars", 0))
	return n


## Applique le résultat d'une partie et retourne le détail des récompenses.
static func apply_battle(level_id: String, victory: bool, stars: int, time: float) -> Dictionary:
	var lv := GameData.level(level_id)
	var gl := int(lv.get("global_level", 1))
	var zone := str(int(lv.get("zone", 1)))
	var p := prog_db()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var rec := level_record(level_id).duplicate()
	var first := victory and int(rec["clears"]) == 0
	var xp_gain := float(p["reward_xp"][0]) + float(p["reward_xp"][1]) * gl
	var gold_gain := float(p["reward_gold"][0]) + float(p["reward_gold"][1]) * gl
	var items: Array = []
	var mats := {}
	if victory:
		var mult := (1.0 + float(p["star_bonus"]) * stars) * (float(p["first_clear_mult"]) if first else 1.0)
		xp_gain *= mult
		gold_gain *= mult
		var is_boss := str(lv.get("objective", "")) == "boss"
		var chests := maxi(1, stars)
		for c in range(chests):
			var table: Dictionary = p["boss_rarity"][zone] if is_boss and c == 0 else p["zone_rarity"][zone]
			var pool: Array = items_db()["loot_pool"][zone]
			var it := make_item(str(pool[rng.randi_range(0, pool.size() - 1)]), _roll(table, rng), gl, rng)
			items.append(it)
		for m in (p["materials"][zone] as Dictionary).keys():
			var r: Array = p["materials"][zone][m]
			var n := rng.randi_range(int(r[0]), int(r[1]))
			if n > 0:
				mats[m] = n
				data["materials"][m] = int(data["materials"].get(m, 0)) + n
		for it in items:
			(data["inventory"] as Array).append(it)
		rec["stars"] = maxi(int(rec["stars"]), stars)
		rec["best"] = time if float(rec["best"]) <= 0.0 else minf(float(rec["best"]), time)
		rec["clears"] = int(rec["clears"]) + 1
	else:
		xp_gain *= float(p["defeat_xp"])
		gold_gain = 0.0
	data["levels"][level_id] = rec
	var before := level()
	var gained := add_xp(int(round(xp_gain)))
	data["gold"] = gold() + int(round(gold_gain))
	save_local()
	return {"victory": victory, "first": first, "xp": int(round(xp_gain)), "gold": int(round(gold_gain)),
		"level_before": before, "level_after": level(), "levels": gained, "items": items, "materials": mats}


static func _roll(table: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for k in table.keys():
		total += float(table[k])
	var r := rng.randf() * total
	for k in table.keys():
		r -= float(table[k])
		if r <= 0.0:
			return str(k)
	return str(table.keys()[0])


## Options passées à la simulation pour refléter la progression et les fils du destin.
static func battle_opts() -> Dictionary:
	return {"player_level": level(), "gear": gear_stats(), "weapon_element": weapon_element(), "bot_level": maxi(1, level() - 1),
		"flags": Story.active_flags(), "healed": Story.has_flag("s1.sylvarche_purifiee")}
