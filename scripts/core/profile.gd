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

## Sorts connus au départ (et deck de départ) ; 7 sorts au plus en combat.
const BASE_SPELLS := ["boule_de_feu", "pluie_de_givre", "racines", "eclair_chaine", "vortex_ombre", "onde_arcanique", "purifier"]
## Rangs des sorts élémentaires, par ordre croissant (docs/design/18-rangs-des-sorts.md). Tout sort
## s'achète à la Bibliothèque, à un prix proportionnel à sa puissance ; la magie interdite donne de la Corruption.
const SPELL_RANKS := ["novice", "intermediaire", "apprenti", "mage", "maitre", "archimage", "interdit"]
const RANK_INFO := {
	"novice": {"name": "Novice", "color": "C8D0E0"},
	"intermediaire": {"name": "Intermédiaire", "color": "8FD16A"},
	"apprenti": {"name": "Apprenti", "color": "6FDCCF"},
	"mage": {"name": "Mage", "color": "6FA8E8"},
	"maitre": {"name": "Maître", "color": "B07CFF"},
	"archimage": {"name": "Archimage", "color": "F2C46B"},
	"interdit": {"name": "Interdit", "color": "D93CF2", "corruption": 10},
}
## Or par point de puissance, prix minimum.
const SPELL_PRICE_PER_POWER := 1.5
const SPELL_PRICE_MIN := 40
const SCHOOLS := {"feu": "Feu", "givre": "Givre", "foudre": "Foudre", "nature": "Nature", "ombre": "Ombre", "arcane": "Arcane", "terre": "Terre"}
const DECK_MAX := 7
## Sorts que chaque compagnon peut emporter (Cercle).
const COMPANION_SPELLS := {"brann": ["bouclier_leve", "charge_bastion"], "sylwen": ["tir_precision", "volee_fleches"], "krag": ["hache_tournoyante", "bond_furieux"], "nyx": ["linceul", "ossements"]}
## Compagnons emmenés en combat : 2 au plus.
const ACTIVE_MAX := 2


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
		"skills": {}, "skill_resets": 0,
		"spells": {"known": BASE_SPELLS.duplicate(), "deck": BASE_SPELLS.duplicate()},
		"circle": default_circle(),
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


## Progression totale d'une sauvegarde (XP cumulée, qui ne fait que croître) : sert à départager
## la sauvegarde de l'appareil et celle du compte sans jamais écraser la plus avancée.
static func progress_of(d: Dictionary) -> float:
	var p: Variant = d.get("player", {})
	if not (p is Dictionary):
		return 0.0
	var total := float((p as Dictionary).get("xp", 0))
	for l in range(1, int((p as Dictionary).get("level", 1))):
		total += float(xp_to_next(l))
	return total


## Résumé lisible d'une sauvegarde (écran Sauvegarde).
static func summary(d: Dictionary) -> String:
	var p: Dictionary = d.get("player", {}) if d.get("player") is Dictionary else {}
	var stars := 0
	for k in (d.get("levels", {}) as Dictionary).keys():
		stars += int(d["levels"][k].get("stars", 0))
	return "Niveau %d · %d étoile%s · %d objets · %d or" % [int(p.get("level", 1)), stars, "s" if stars > 1 else "",
		(d.get("inventory", []) as Array).size(), int(d.get("gold", 0))]


## Date de la dernière sauvegarde, à l'heure de l'appareil (« 22/11 à 10:42 »).
static func save_date(d: Dictionary) -> String:
	var u := float(d.get("updated", 0.0))
	if u <= 0.0:
		return "jamais sauvegardée"
	var local := int(u) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var t := Time.get_datetime_dict_from_unix_time(local)
	return "%02d/%02d à %02d:%02d" % [int(t["day"]), int(t["month"]), int(t["hour"]), int(t["minute"])]


## Copie de secours de l'appareil (« appareil », « compte ») : {} si absente.
static func read_backup(tag: String) -> Dictionary:
	var path := "user://save_backup_%s.json" % tag
	if not FileAccess.file_exists(path):
		return {}
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return v if v is Dictionary else {}


## Copie de secours sur l'appareil (user://save_backup_<tag>.json) avant tout remplacement.
static func backup(d: Dictionary, tag: String) -> void:
	var f := FileAccess.open("user://save_backup_%s.json" % tag, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))
		f.close()


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
	# XP proportionnelle à l'XP du niveau du lieu : une 1re victoire vaut environ 0,8 niveau
	# (le joueur suit ainsi le niveau des zones sans devoir trop rejouer).
	var xp_gain := float(xp_to_next(gl)) * float(p.get("reward_xp_ratio", 0.33))
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
		"flags": Story.active_flags(), "healed": Story.has_flag("s1.sylvarche_purifiee"),
		"mods": skill_mods(), "deck": deck() if spell_mode() == "deck" else drawer_spells(), "spell_mode": spell_mode(), "circle": circle(),
		"loyalty": {"brann": Story.loyalty("brann"), "sylwen": Story.loyalty("sylwen"), "krag": Story.loyalty("krag"), "nyx": Story.loyalty("nyx")},
		"active": active_companions()}


# ---------------------------------------------------------------- arbre de compétences (Entraînement)

static func tree_db() -> Dictionary:
	return GameData.load_json("res://data/skill_trees/%s.json" % str(data["player"]["class"]))


## 1 point par niveau à partir du niveau 2, plus 1 tous les 10 niveaux (04-classes-races §3.1).
static func skill_points_total() -> int:
	var l := level()
	return maxi(0, l - 1) + int(l / 10.0)


static func skill_ranks() -> Dictionary:
	var cls := str(data["player"]["class"])
	if not (data.get("skills") is Dictionary):
		data["skills"] = {}
	if not (data["skills"].get(cls) is Dictionary):
		data["skills"][cls] = {}
	return data["skills"][cls]


static func skill_rank(id: String) -> int:
	return int(skill_ranks().get(id, 0))


static func skill_points_spent() -> int:
	var n := 0
	for k in skill_ranks().keys():
		n += int(skill_ranks()[k])
	return n


static func skill_points_free() -> int:
	return skill_points_total() - skill_points_spent()


static func branch_spent(branch: Dictionary) -> int:
	var n := 0
	for tier in branch.get("tiers", []):
		for node in tier["nodes"]:
			n += skill_rank(str(node["id"]))
	return n


## [branche, palier, nœud] d'un nœud de l'arbre, ou [] s'il n'existe pas.
static func find_node(id: String) -> Array:
	for br in tree_db().get("branches", []):
		for tier in br.get("tiers", []):
			for node in tier["nodes"]:
				if str(node["id"]) == id:
					return [br, tier, node]
	return []


## "" si la branche est ouverte, sinon la raison (ex. Voie du Surge : ouverte par l'histoire de l'acte 3).
static func branch_locked(br: Dictionary) -> String:
	if br.has("unlock_flag"):
		return "" if Story.has_flag(str(br["unlock_flag"])) else str(br.get("locked", "Verrouillée"))
	if br.has("locked"):
		return str(br["locked"])
	return ""


static func keystones_taken() -> int:
	var n := 0
	for br in tree_db().get("branches", []):
		for tier in br.get("tiers", []):
			for node in tier["nodes"]:
				if str(node.get("kind", "")) == "keystone" and skill_rank(str(node["id"])) > 0:
					n += 1
	return n


## "" si l'on peut investir un point dans ce nœud, sinon la raison.
static func invest_block(id: String) -> String:
	var f := find_node(id)
	if f.is_empty():
		return "Nœud inconnu"
	var br: Dictionary = f[0]
	var tier: Dictionary = f[1]
	var node: Dictionary = f[2]
	if branch_locked(br) != "":
		return branch_locked(br)
	if node.has("flag") and not Story.has_flag(str(node["flag"])):
		return "Réservé : %s" % str(node.get("flag_text", node["flag"]))
	if skill_rank(id) >= int(node.get("max", 1)):
		return "Rang maximum"
	if branch_spent(br) < int(tier.get("req", 0)):
		return "Palier verrouillé : %d points dans la branche" % int(tier["req"])
	if str(node.get("kind", "")) == "keystone" and keystones_taken() >= int(tree_db().get("keystone_limit", 2)):
		return "2 Clés de voûte au maximum"
	if skill_points_free() <= 0:
		return "Aucun point disponible"
	return ""


static func invest(id: String) -> bool:
	if invest_block(id) != "":
		return false
	skill_ranks()[id] = skill_rank(id) + 1
	return true


## Réinitialisation : gratuite la 1re fois, puis 100 or de plus à chaque fois.
static func reset_cost() -> int:
	return 100 * int(data.get("skill_resets", 0))


static func reset_skills() -> bool:
	var cost := reset_cost()
	if gold() < cost or skill_points_spent() == 0:
		return false
	data["gold"] = gold() - cost
	skill_ranks().clear()
	data["skill_resets"] = int(data.get("skill_resets", 0)) + 1
	return true


## Effets cumulés de l'arbre : {clé: valeur × rang}.
static func skill_mods() -> Dictionary:
	var out := {}
	for br in tree_db().get("branches", []):
		for tier in br.get("tiers", []):
			for node in tier["nodes"]:
				var r := skill_rank(str(node["id"]))
				if r <= 0:
					continue
				var m: Dictionary = node.get("mods", {})
				for k in m.keys():
					out[k] = float(out.get(k, 0.0)) + float(m[k]) * float(r)
	return out


# ---------------------------------------------------------------- sorts (Bibliothèque)

static func _spells_state() -> Dictionary:
	if not (data.get("spells") is Dictionary):
		data["spells"] = {"known": BASE_SPELLS.duplicate(), "deck": BASE_SPELLS.duplicate()}
	return data["spells"]


## Sorts connus : appris (base, Bibliothèque) et débloqués par l'arbre.
static func known_spells() -> Array[String]:
	var out: Array[String] = []
	for id in _spells_state().get("known", []):
		if GameData.spells().has(str(id)) and not out.has(str(id)):
			out.append(str(id))
	for br in tree_db().get("branches", []):
		for tier in br.get("tiers", []):
			for node in tier["nodes"]:
				if node.has("unlock") and skill_rank(str(node["id"])) > 0 and not out.has(str(node["unlock"])):
					out.append(str(node["unlock"]))
	return out


## Deck emporté en combat (dans l'ordre du grimoire), parmi les sorts connus.
static func deck() -> Array[String]:
	var known := known_spells()
	var chosen: Array = _spells_state().get("deck", [])
	var out: Array[String] = []
	for id in GameData.spells().keys():
		if chosen.has(id) and known.has(str(id)) and out.size() < DECK_MAX:
			out.append(str(id))
	if out.is_empty() and not known.is_empty():
		out.append(known[0])
	return out


## Mode des sorts en combat : « deck » (7 sorts choisis) ou « drawer » (tiroir : tous les sorts connus,
## rangés par école). Choisi à l'écran de préparation.
static func spell_mode() -> String:
	return "drawer" if str(data.get("spell_mode", "deck")) == "drawer" else "deck"


static func set_spell_mode(m: String) -> void:
	data["spell_mode"] = "drawer" if m == "drawer" else "deck"


## Sorts du tiroir : tous les sorts connus du Mage, dans l'ordre du grimoire.
static func drawer_spells() -> Array[String]:
	var known := known_spells()
	var out: Array[String] = []
	for id in GameData.spells().keys():
		if known.has(str(id)):
			out.append(str(id))
	return out


## Ajoute ou retire un sort du deck ; retourne "" ou la raison du refus.
static func toggle_deck(id: String) -> String:
	var st := _spells_state()
	var d: Array = st.get("deck", [])
	var current := deck()
	if current.has(id):
		if current.size() <= 1:
			return "Il faut au moins un sort"
		d.erase(id)
	else:
		if not known_spells().has(id):
			return "Sort inconnu"
		if current.size() >= DECK_MAX:
			return "Deck complet (%d sorts) : retire d'abord un sort" % DECK_MAX
		# On repart du deck effectif pour ne pas garder de sorts devenus inconnus.
		d.clear()
		d.append_array(current)
		d.append(id)
	st["deck"] = d
	return ""


## Puissance d'un sort par lancer : dégâts × surface touchée, durée, rebonds, gel, ralentissement,
## soin ou bouclier de la Barrière, part de dégâts au Nexus, Surge. Sert à fixer son prix.
static func spell_power(id: String) -> int:
	var sp: Dictionary = GameData.spells().get(id, {})
	var area := func(r: float) -> float: return 0.5 + 0.5 * r * r
	var dmg := float(sp.get("damage", 0))
	var p := 0.0
	match str(sp.get("type", "")):
		"aoe":
			var a: float = area.call(float(sp.get("radius", 1.0)))
			p = dmg * a + float(sp.get("freeze", 0.0)) * 25.0 * a
		"zone":
			var a: float = area.call(float(sp.get("radius", 1.5)))
			var d := float(sp.get("dur", 3.0))
			p = float(sp.get("dps", 0)) * d * a + float(sp.get("slow", 0.0)) * d * 12.0 * a + float(sp.get("pull", 0.0)) * d * 8.0
		"chain":
			var f := float(sp.get("falloff", 0.8))
			for k in range(int(sp.get("bounces", 5))):
				p += float(sp.get("damage", 40)) * pow(f, k)
		"column":
			p = float(sp.get("damage", 30)) * float(sp.get("width", 0.8)) * 4.0
		"barrage":
			p = float(sp.get("count", 5)) * dmg * float(area.call(float(sp.get("radius", 1.0))))
		"wave":
			p = float(sp.get("damage", 20)) * float(area.call(float(sp.get("radius", 2.0)))) + float(sp.get("push", 2.0)) * 20.0
		"barrier_heal", "barrier_shield":
			p = float(sp.get("amount", 15)) * 12.0
		"purify":
			p = 100.0
		"wall":
			p = float(sp.get("amount", 300)) * 0.8 + float(sp.get("dur", 10.0)) * 10.0
		"quake":
			var band := minf(float(sp.get("band", 2.0)), 8.0)
			p = dmg * band * 2.2 + float(sp.get("stun", 1.0)) * band * 10.0 + float(sp.get("cracks", 0)) * 10.0 + float(sp.get("craters", 0)) * 50.0
		"ground":
			var a: float = area.call(float(sp.get("radius", 2.0)))
			var d := float(sp.get("dur", 6.0))
			match str(sp.get("ground_kind", "")):
				"braises":
					p = float(sp.get("dps", 0)) * d * a
				"verglas":
					p = 0.35 * d * 12.0 * a + dmg * a
				"eau":
					p = 0.25 * d * 12.0 * a
				"statique":
					p = float(sp.get("zap", 30)) * 3.0 * (d / 0.8) * 0.5
				"miasme":
					p = d * a * 12.0
				"rune":
					p = float(sp.get("blast", 120)) * float(area.call(float(sp.get("blast_r", 2.0))))
	p += dmg * float(sp.get("nexus_ratio", 0.0)) * 2.0 + float(sp.get("surge_gain", 0.0)) * 20.0
	var g: Variant = sp.get("ground", null)
	if g is Dictionary:
		# Sol laissé par le sort (gravats, faille…).
		p += dmg * float((g as Dictionary).get("dps", 0.0)) * float((g as Dictionary).get("dur", 0.0)) * 2.0 + float((g as Dictionary).get("dur", 0.0)) * 5.0
	return int(round(p))


## Prix d'un sort à la Bibliothèque : proportionnel à sa puissance (arrondi à 10 or, à 50 or au-delà de 1 000).
static func spell_price(id: String) -> int:
	var g := maxf(float(SPELL_PRICE_MIN), float(spell_power(id)) * SPELL_PRICE_PER_POWER)
	var step := 50.0 if g >= 1000.0 else 10.0
	return int(round(g / step) * step)


## Conditions d'apprentissage d'un sort : {gold, corruption} (ou {level, gold} pour un sort qui
## l'impose) ; vide s'il ne s'achète pas.
static func learn_info(id: String) -> Dictionary:
	var sp: Dictionary = GameData.spells().get(id, {})
	if sp.has("learn"):
		return sp["learn"]
	if not sp.has("rank"):
		return {}
	var out := {"gold": spell_price(id)}
	var ri: Dictionary = RANK_INFO.get(str(sp["rank"]), {})
	if ri.has("corruption"):
		out["corruption"] = int(ri["corruption"])
	return out


static func learn_block(id: String) -> String:
	var l := learn_info(id)
	if l.is_empty():
		return "Ne s'apprend pas à la Bibliothèque"
	if known_spells().has(id):
		return "Déjà appris"
	if level() < int(l.get("level", 1)):
		return "Niveau %d requis" % int(l["level"])
	if gold() < int(l.get("gold", 0)):
		return "Or insuffisant"
	return ""


static func learn(id: String) -> bool:
	if learn_block(id) != "":
		return false
	var l := learn_info(id)
	data["gold"] = gold() - int(l.get("gold", 0))
	(_spells_state()["known"] as Array).append(id)
	# Magie interdite : la Corruption grandit (07-narration.md §1).
	if int(l.get("corruption", 0)) > 0:
		Story.add_value("corruption", int(l["corruption"]))
	return true


# ---------------------------------------------------------------- Cercle (compagnons)

static func default_circle() -> Dictionary:
	return {"swap": false, "active": ["brann", "sylwen"], "brann": {"order": "defends", "spell": "bouclier_leve"},
		"sylwen": {"order": "focus_nexus", "spell": "tir_precision"}, "krag": {"order": "defends", "spell": "hache_tournoyante"},
		"nyx": {"order": "focus_nexus", "spell": "linceul"}}


## Compagnons qui ont rejoint le groupe (Krag : selon les choix de l'acte 2).
static func companions_available() -> Array[String]:
	var out: Array[String] = []
	for bd in GameData.party()["bots"]:
		var req := str(bd.get("requires", ""))
		if req == "" or Story.has_flag(req):
			out.append(str(bd["id"]))
	return out


## Compagnons emmenés en combat (choisis au Cercle), complétés si besoin jusqu'à 2.
static func active_companions() -> Array[String]:
	var avail := companions_available()
	var out: Array[String] = []
	for id in circle().get("active", []):
		if avail.has(str(id)) and not out.has(str(id)) and out.size() < ACTIVE_MAX:
			out.append(str(id))
	for id in avail:
		if out.size() >= ACTIVE_MAX:
			break
		if not out.has(id):
			out.append(id)
	return out


## Emmène « who » à la place de « replaced ».
static func swap_active(who: String, replaced: String) -> void:
	var act := active_companions()
	var i := act.find(replaced)
	if i < 0 or act.has(who) or not companions_available().has(who):
		return
	act[i] = who
	circle()["active"] = act


static func circle() -> Dictionary:
	if not (data.get("circle") is Dictionary):
		data["circle"] = default_circle()
	var c: Dictionary = data["circle"]
	var def := default_circle()
	for k in def.keys():
		if not c.has(k):
			c[k] = def[k]
	return c


static func set_circle(who: String, key: String, value: Variant) -> void:
	var c := circle()
	if who == "":
		c[key] = value
	else:
		(c[who] as Dictionary)[key] = value
