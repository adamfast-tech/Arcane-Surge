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
## Difficultés (Options) : vitesse et dégâts des ennemis, PV du Nexus (et du boss), XP et butin.
const DIFFICULTIES := [
	{"id": "facile", "name": "Facile", "mult": 0.75, "color": "8FD16A"},
	{"id": "normal", "name": "Normal", "mult": 1.0, "color": "C8D0E0"},
	{"id": "serieux", "name": "Sérieux", "mult": 1.25, "color": "F2C46B"},
	{"id": "difficile", "name": "Difficile", "mult": 1.5, "color": "FF9B4A"},
	{"id": "fou", "name": "Ça va pas non !?", "mult": 2.0, "color": "FF5A5A"},
	{"id": "impossible", "name": "Impossible", "mult": 3.0, "color": "D93CF2"},
]
## Sorts que chaque compagnon peut emporter (Cercle).
## Sorts qu'un compagnon peut emporter selon sa classe (le Cercle en choisit un).
const CLASS_SPELLS := {"chevalier": ["bouclier_leve", "charge_bastion"], "archer": ["tir_precision", "volee_fleches"],
	"berserker": ["hache_tournoyante", "bond_furieux"], "necromancien": ["linceul", "ossements"], "mage": ["boule_de_feu", "eclair_chaine"],
	"clerc": ["priere", "lance_solaire"], "epeiste": ["fente", "tranche_orage"]}
## Rôle affiché pour un compagnon qui a changé de voie.
const CLASS_ROLES := {"chevalier": "Protecteur : boucliers et charges ; renforce la Barrière (Bouclier levé)",
	"archer": "Tireur : ses archers frappent de loin, idéal contre les boss", "berserker": "Assaut : haches tournoyantes et bonds furieux",
	"necromancien": "Ombre : squelettes, Linceul et ossements", "mage": "Arcaniste : boules de feu et éclairs en chaîne",
	"clerc": "Soigneur : soigne la Barrière (Prière) et frappe de Lumière", "epeiste": "Lame : estocades et chaînes de foudre"}
## XP des compagnons (04-classes-races §5) : 80 % de celle du héros en combat, 30 % sur le banc.
const COMPANION_XP_ACTIVE := 0.8
const COMPANION_XP_BENCH := 0.3
## Rattrapage : un compagnon n'est jamais à plus de 5 niveaux sous le héros.
const COMPANION_FLOOR := 5
const CONFIG_SLOTS := 3
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
		"gold": 0, "dust": 0, "materials": {}, "inventory": [], "runes": [], "equipped": {}, "levels": {},
		"settings": {"guest": false, "auto_fire": false}, "next_uid": 1,
		"story": Story.default_state(),
		"skills": {}, "skill_resets": 0,
		"spells": {"known": BASE_SPELLS.duplicate(), "deck": BASE_SPELLS.duplicate()},
		"circle": default_circle(),
		"companions": {},
		"meditation": {"configs": [{}, {}, {}], "harmony": 0},
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
	var had_runes := data.has("runes")
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
	elif not had_runes:
		# Sauvegarde d'avant les runes : quelques runes pour découvrir la gravure.
		_give_starter_runes()


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
	_give_starter_runes()


static func _give_starter_runes() -> void:
	if not (data.get("runes") is Array):
		data["runes"] = []
	for fam in ["kaor", "ilm", "pyr"]:
		(data["runes"] as Array).append(make_rune(fam, 1, "commun"))


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
	var cat := rune_category(str(base_of(item).get("slot", "")))
	for r in item.get("runes", []):
		var e := rune_effect(r, cat)
		if e.has("stat"):
			out[str(e["stat"])] = int(out.get(str(e["stat"]), 0)) + int(e["value"])
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
	equip_to("player", uid)


static func unequip(slot: String) -> void:
	unequip_from("player", slot)


## Équipement porté par le héros (« player ») ou par un compagnon (étape 13.4).
static func equipment_of(who: String) -> Dictionary:
	if who == "player" or who == "":
		return data["equipped"]
	return _comp(who)["equipped"]


## Qui porte cet objet : « player », l'identifiant d'un compagnon, ou "" s'il est en réserve.
static func holder_of(uid: String) -> String:
	if equipped_slot(uid) != "":
		return "player"
	if data.get("companions") is Dictionary:
		for who in (data["companions"] as Dictionary).keys():
			var eq: Dictionary = (data["companions"][who] as Dictionary).get("equipped", {})
			for sl in eq.keys():
				if str(eq[sl]) == uid:
					return str(who)
	return ""


## Équipe un objet sur le héros ou un compagnon (il quitte son porteur précédent).
static func equip_to(who: String, uid: String) -> void:
	var it := find_item(uid)
	if it.is_empty():
		return
	var holder := holder_of(uid)
	if holder != "":
		var heq := equipment_of(holder)
		for sl in heq.keys():
			if str(heq[sl]) == uid:
				heq.erase(sl)
	var eq := equipment_of(who)
	var slot := str(base_of(it).get("slot", ""))
	if slot == "ring":
		slot = _ring_target(eq)
	eq[slot] = uid


## Anneau remplacé : un emplacement libre, sinon le plus faible des deux.
static func _ring_target(eq: Dictionary) -> String:
	if not eq.has("ring1"):
		return "ring1"
	if not eq.has("ring2"):
		return "ring2"
	return "ring2" if item_score(find_item(str(eq["ring2"]))) < item_score(find_item(str(eq["ring1"]))) else "ring1"


## Somme des stats d'un objet (améliorations, affixes et runes de stats compris) ; 0 pour un objet absent.
static func item_score(it: Dictionary) -> int:
	if it.is_empty():
		return 0
	var st := item_stats(it)
	var total := 0
	for k in STATS:
		total += int(st.get(k, 0))
	return total


## Comparaison d'un objet en réserve avec ce que porte `who` au même emplacement (l'anneau le plus faible
## pour les anneaux) : {better, power (écart de Puissance), diff (écart par stat), vs (uid remplacé, "" si
## l'emplacement est libre), slot}.
static func compare_to_equipped(who: String, it: Dictionary) -> Dictionary:
	var eq := equipment_of(who)
	var slot := str(base_of(it).get("slot", ""))
	if slot == "ring":
		slot = _ring_target(eq)
	var vs := str(eq.get(slot, ""))
	var cur := find_item(vs) if vs != "" else {}
	var a := item_stats(it)
	var b := item_stats(cur) if not cur.is_empty() else {}
	var diff := {}
	for k in STATS:
		var d := int(a.get(k, 0)) - int(b.get(k, 0))
		if d != 0:
			diff[k] = d
	var pw := int(round(float(item_score(it) - item_score(cur)) * 1.6))
	return {"better": pw > 0, "power": pw, "diff": diff, "vs": vs if not cur.is_empty() else "", "slot": slot}


## Objets en réserve (portés par personne) meilleurs que l'équipement actuel de `who`.
static func better_items(who: String) -> Array:
	var out: Array = []
	for it in data["inventory"]:
		if holder_of(str(it["uid"])) == "" and bool(compare_to_equipped(who, it)["better"]):
			out.append(it)
	return out


static func unequip_from(who: String, slot: String) -> void:
	equipment_of(who).erase(slot)


static func gear_stats() -> Dictionary:
	return gear_stats_of("player")


static func gear_stats_of(who: String) -> Dictionary:
	var out := {}
	var eq := equipment_of(who)
	for s in eq.keys():
		var it := find_item(str(eq[s]))
		if it.is_empty():
			continue
		var st := item_stats(it)
		for k in st.keys():
			out[k] = int(out.get(k, 0)) + int(st[k])
	return out


static func weapon_element() -> String:
	return weapon_element_of("player")


static func weapon_element_of(who: String) -> String:
	var uid := str(equipment_of(who).get("weapon", ""))
	if uid == "":
		return "physique"
	return str(base_of(find_item(uid)).get("element", "physique"))


static func upgrade_cost(item: Dictionary) -> int:
	var up := int(item.get("up", 0))
	var value := float(rarity_of(item).get("value", 1))
	var rm := race_mods()
	var disc := clampf(float(rm.get("price_discount", 0.0)) + float(rm.get("forge_discount", 0.0)), 0.0, 0.5)
	return int(round(float(prog_db()["upgrade"]["gold_base"]) * float(up + 1) * (1.0 + value * 0.25) * (1.0 + float(item.get("ilvl", 1)) * 0.1) * (1.0 - disc)))


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
	if holder_of(uid) != "":
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
	# Niveau bonus (6-R) : ouvert par un fil de l'histoire.
	var req := str(GameData.level(level_id).get("requires", ""))
	if req != "":
		return Story.has_flag(req) or int(level_record(level_id)["clears"]) > 0
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
## « unique » : base d'un objet unique gagné en combat (ex. Couronne de l'Énigme : les deux énigmes du
## Sphinx résolues), donné une seule fois, en légendaire.
static func apply_battle(level_id: String, victory: bool, stars: int, time: float, present: Array = [], unique: String = "", story_flags: Array = []) -> Dictionary:
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
	var runes_won: Array = []
	var mats := {}
	if victory:
		var mult := (1.0 + float(p["star_bonus"]) * stars) * (float(p["first_clear_mult"]) if first else 1.0)
		xp_gain *= mult
		gold_gain *= mult
		var is_boss := str(lv.get("objective", "")) == "boss"
		# Difficulté : plus (ou moins) de coffres, et des objets plus rares au-delà de Normal.
		var loot := difficulty_mult()
		var exp_chests := float(maxi(1, stars)) * loot
		var chests := maxi(1, int(floor(exp_chests)) + (1 if rng.randf() < exp_chests - floor(exp_chests) else 0))
		var better := clampf((loot - 1.0) * 0.25 + float(rune_mods_of("player").get("luck", 0.0)), 0.0, 0.75)
		for c in range(chests):
			var table: Dictionary = p["boss_rarity"][zone] if is_boss and c == 0 else p["zone_rarity"][zone]
			var pool: Array = items_db()["loot_pool"][zone]
			var rar := _roll(table, rng)
			if rng.randf() < better:
				rar = _better_rarity(rar, _roll(table, rng))
			var it := make_item(str(pool[rng.randi_range(0, pool.size() - 1)]), rar, gl, rng)
			items.append(it)
		for m in (p["materials"][zone] as Dictionary).keys():
			var r: Array = p["materials"][zone][m]
			var n := int(round(float(rng.randi_range(int(r[0]), int(r[1]))) * loot))
			if n > 0:
				mats[m] = n
				data["materials"][m] = int(data["materials"].get(m, 0)) + n
		# Légendaire de boss (Hache du Serment Brisé, Fiole des Trois Venins) : une chance sur huit, une seule fois.
		var bu: Dictionary = p.get("boss_unique", {})
		var ubase := str((bu.get("levels", {}) as Dictionary).get(level_id, ""))
		if unique == "" and ubase != "" and rng.randf() < float(bu.get("chance", 0.125)) * loot:
			unique = ubase
		if unique != "" and (items_db()["bases"] as Dictionary).has(unique):
			var owned := false
			for it in data["inventory"]:
				owned = owned or str(it.get("base", "")) == unique
			if not owned:
				items.append(make_item(unique, "legendaire", gl, rng))
		for it in items:
			(data["inventory"] as Array).append(it)
		# Runes : une chance par étoile, une rune garantie sur un boss (niveau selon la zone).
		var rdrop: Dictionary = p.get("rune_drops", {})
		if not rdrop.is_empty():
			var luck := float(rune_mods_of("player").get("luck", 0.0))
			var nr := 1 if is_boss else 0
			for st_i in range(maxi(1, stars)):
				if rng.randf() < float(rdrop.get("per_star", 0.4)) * loot:
					nr += 1
			var lv_range: Array = (rdrop.get("level_by_zone", {}) as Dictionary).get(zone, [1, 1])
			var fams: Array = (runes_db()["families"] as Dictionary).keys()
			for k in range(nr):
				var rar_r := _roll(p["zone_rarity"][zone], rng)
				if rng.randf() < clampf(better + luck, 0.0, 0.75):
					rar_r = _better_rarity(rar_r, _roll(p["zone_rarity"][zone], rng))
				var rn := make_rune(str(fams[rng.randi_range(0, fams.size() - 1)]), rng.randi_range(int(lv_range[0]), int(lv_range[1])), rar_r)
				(data["runes"] as Array).append(rn)
				runes_won.append(rn)
		rec["stars"] = maxi(int(rec["stars"]), stars)
		rec["best"] = time if float(rec["best"]) <= 0.0 else minf(float(rec["best"]), time)
		rec["clears"] = int(rec["clears"]) + 1
	else:
		xp_gain *= float(p["defeat_xp"])
		gold_gain = 0.0
	# Fils de l'histoire écrits par le combat (acte 6 : compagnon épargné ou achevé) et effets de victoire du niveau.
	var story_lines: Array[String] = []
	if victory:
		for f in story_flags:
			Story.set_flag(str(f))
		if lv.has("on_win"):
			story_lines = Story.apply(lv["on_win"], gl)
	data["levels"][level_id] = rec
	var before := level()
	# Difficulté : de -25 % (Facile) à +200 % (Impossible) d'XP, compagnons compris.
	xp_gain *= difficulty_mult()
	# Compagnons : 80 % de l'XP du héros s'ils ont combattu, 30 % s'ils sont restés à Havre-Aube.
	var comps := {}
	for who in companions_available():
		var active := present.has(who)
		var amount := int(round(xp_gain * (COMPANION_XP_ACTIVE if active else COMPANION_XP_BENCH)))
		var up := add_companion_xp(who, amount)
		comps[who] = {"xp": amount, "levels": up, "level": companion_level(who), "active": active}
	xp_gain *= 1.0 + float(race_mods().get("xp_bonus", 0.0))
	var gained := add_xp(int(round(xp_gain)))
	data["gold"] = gold() + int(round(gold_gain))
	save_local()
	return {"victory": victory, "first": first, "xp": int(round(xp_gain)), "gold": int(round(gold_gain)),
		"level_before": before, "level_after": level(), "levels": gained, "items": items, "runes": runes_won, "materials": mats, "companions": comps,
		"story": story_lines}


## Plus rare des deux raretés (ordre de items.json).
static func _better_rarity(a: String, b: String) -> String:
	var order: Array = (items_db().get("rarities", {}) as Dictionary).keys()
	return b if order.find(b) > order.find(a) else a


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
# ---------------------------------------------------------------- runes et Forge (docs/design/35-equipement-runes-forge.md)

const ROMAN := ["I", "II", "III", "IV", "V"]


static func runes_db() -> Dictionary:
	return items_db()["runes"]


static func rune_inventory() -> Array:
	if not (data.get("runes") is Array):
		data["runes"] = []
	return data["runes"]


static func make_rune(family: String, level: int, rarity: String) -> Dictionary:
	var uid := "r%d" % int(data["next_uid"])
	data["next_uid"] = int(data["next_uid"]) + 1
	return {"uid": uid, "rune": family, "level": clampi(level, 1, 5), "rarity": rarity}


static func rune_family(r: Dictionary) -> Dictionary:
	return (runes_db()["families"] as Dictionary).get(str(r.get("rune", "")), {})


## Nom court d'une rune : « Pyr III ».
static func rune_name(r: Dictionary) -> String:
	return "%s %s" % [str(rune_family(r).get("name", "?")), ROMAN[clampi(int(r.get("level", 1)), 1, 5) - 1]]


static func rune_color(r: Dictionary) -> Color:
	return Color(str(rune_family(r).get("color", "4fe3d2")))


## Puissance d'une rune : niveau (I à V) × rareté.
static func rune_power(r: Dictionary) -> float:
	var pw: Array = runes_db()["level_pow"]
	var rar: Dictionary = (items_db()["rarities"] as Dictionary).get(str(r.get("rarity", "commun")), {})
	return float(pw[clampi(int(r.get("level", 1)), 1, 5) - 1]) * float(rar.get("mult", 1.0))


## Catégorie d'un emplacement pour les runes : arme, armure, bijou ou charme.
static func rune_category(slot: String) -> String:
	var key := "ring" if slot.begins_with("ring") else slot
	return str((runes_db()["categories"] as Dictionary).get(key, "armure"))


## Effet d'une rune selon la catégorie de l'objet : {stat, value} ou {mod, value, label, fmt}.
static func rune_effect(r: Dictionary, category: String) -> Dictionary:
	var e: Dictionary = rune_family(r).get(category, {})
	if e.is_empty():
		return {}
	var p := rune_power(r)
	if e.has("stat"):
		return {"stat": str(e["stat"]), "value": maxi(1, int(round(float(e["per"]) * p)))}
	return {"mod": str(e["mod"]), "value": float(e["per"]) * p, "label": str(e.get("label", "")), "fmt": str(e.get("fmt", "pct"))}


static func rune_effect_text(r: Dictionary, category: String) -> String:
	var e := rune_effect(r, category)
	if e.is_empty():
		return ""
	if e.has("stat"):
		return "+%d %s" % [int(e["value"]), str(items_db()["stat_names"][str(e["stat"])])]
	var v := float(e["value"])
	match str(e["fmt"]):
		"flat":
			return "%s +%s" % [str(e["label"]), _num(v)]
		"sec":
			return "%s +%s s" % [str(e["label"]), _num(v)]
		"regen":
			return "%s +%s PV/s" % [str(e["label"]), _num(v)]
		"neg":
			return "%s −%s %%" % [str(e["label"]), _num(v * 100.0)]
	return "%s +%s %%" % [str(e["label"]), _num(v * 100.0)]


static func _num(v: float) -> String:
	if absf(v - roundf(v)) < 0.05 or absf(v) >= 10.0:
		return "%d" % int(round(v))
	return ("%.1f" % v).replace(".", ",")


## Emplacements de runes d'un objet (selon sa rareté).
static func sockets_of(item: Dictionary) -> int:
	return int(rarity_of(item).get("sockets", 1))


## Effets spéciaux des runes gravées sur l'équipement porté (les stats passent par item_stats).
static func rune_mods_of(who: String) -> Dictionary:
	var out := {}
	var eq := equipment_of(who)
	for sl in eq.keys():
		var it := find_item(str(eq[sl]))
		if it.is_empty():
			continue
		var cat := rune_category(str(base_of(it).get("slot", "")))
		for r in it.get("runes", []):
			var e := rune_effect(r, cat)
			if e.has("mod"):
				out[str(e["mod"])] = float(out.get(str(e["mod"]), 0.0)) + float(e["value"])
	return out


static func find_rune(uid: String) -> Dictionary:
	for r in rune_inventory():
		if str(r["uid"]) == uid:
			return r
	return {}


static func engrave_cost(r: Dictionary) -> int:
	var rar: Dictionary = (items_db()["rarities"] as Dictionary).get(str(r.get("rarity", "commun")), {})
	return int(runes_db()["engrave_gold"]) * int(r.get("level", 1)) * int(rar.get("value", 1))


static func unengrave_cost(r: Dictionary) -> int:
	return int(runes_db()["remove_gold"]) * int(r.get("level", 1))


## "" si la rune peut être gravée sur l'objet, sinon la raison.
static func engrave_block(item: Dictionary, r: Dictionary) -> String:
	if item.is_empty() or r.is_empty():
		return "Choisis un objet et une rune"
	if (item.get("runes", []) as Array).size() >= sockets_of(item):
		return "Aucun emplacement libre"
	if gold() < engrave_cost(r):
		return "Or insuffisant"
	return ""


static func engrave(item_uid: String, rune_uid: String) -> bool:
	var it := find_item(item_uid)
	var r := find_rune(rune_uid)
	if engrave_block(it, r) != "":
		return false
	data["gold"] = gold() - engrave_cost(r)
	rune_inventory().erase(r)
	if not (it.get("runes") is Array):
		it["runes"] = []
	(it["runes"] as Array).append(r)
	return true


## Retire la rune n° idx d'un objet (payant) : elle retourne dans la réserve.
static func unengrave(item_uid: String, idx: int) -> bool:
	var it := find_item(item_uid)
	var list: Array = it.get("runes", [])
	if idx < 0 or idx >= list.size():
		return false
	var r: Dictionary = list[idx]
	if gold() < unengrave_cost(r):
		return false
	data["gold"] = gold() - unengrave_cost(r)
	list.remove_at(idx)
	rune_inventory().append(r)
	return true


static func rune_fuse_cost(r: Dictionary) -> int:
	return int(runes_db()["fuse_gold"]) * int(r.get("level", 1))


## "" si ces 3 runes peuvent fusionner (même famille, même niveau, même rareté, niveau < V).
static func rune_fuse_block(uids: Array) -> String:
	if uids.size() != 3:
		return "Choisis 3 runes identiques"
	var first := find_rune(str(uids[0]))
	for u in uids:
		var r := find_rune(str(u))
		if r.is_empty() or str(r["rune"]) != str(first["rune"]) or int(r["level"]) != int(first["level"]) or str(r["rarity"]) != str(first["rarity"]):
			return "Les 3 runes doivent être identiques (famille, niveau, rareté)"
	if int(first["level"]) >= 5:
		return "Niveau V : niveau maximum"
	if gold() < rune_fuse_cost(first):
		return "Or insuffisant"
	return ""


## Fusionne 3 runes identiques en une rune du niveau au-dessus.
static func fuse_runes(uids: Array) -> Dictionary:
	if rune_fuse_block(uids) != "":
		return {}
	var first := find_rune(str(uids[0]))
	data["gold"] = gold() - rune_fuse_cost(first)
	var out := make_rune(str(first["rune"]), int(first["level"]) + 1, str(first["rarity"]))
	for u in uids:
		rune_inventory().erase(find_rune(str(u)))
	rune_inventory().append(out)
	return out


static func rune_salvage_value(r: Dictionary) -> int:
	var rar: Dictionary = (items_db()["rarities"] as Dictionary).get(str(r.get("rarity", "commun")), {})
	return int(runes_db()["salvage_dust"]) * int(r.get("level", 1)) * int(rar.get("value", 1))


static func salvage_rune(uid: String) -> int:
	var r := find_rune(uid)
	if r.is_empty():
		return 0
	var v := rune_salvage_value(r)
	rune_inventory().erase(r)
	data["dust"] = dust() + v
	return v


## Fusion d'équipement (Forge) : 3 objets de même rareté → 1 objet de la rareté au-dessus.
static func fusion_next(rarity: String) -> String:
	return str((items_db()["fusion"]["next"] as Dictionary).get(rarity, ""))


static func fusion_cost(items: Array) -> int:
	if items.is_empty():
		return 0
	var rar := str((items[0] as Dictionary).get("rarity", "commun"))
	var ilvl := 1
	for it in items:
		ilvl = maxi(ilvl, int((it as Dictionary).get("ilvl", 1)))
	return int(round(float((items_db()["fusion"]["gold"] as Dictionary).get(rar, 100)) * (1.0 + 0.03 * float(ilvl))))


## "" si l'objet peut entrer dans une fusion, sinon la raison.
static func fusion_item_block(it: Dictionary) -> String:
	if it.is_empty():
		return "Objet introuvable"
	if bool(it.get("fused", false)):
		return "Issu d'une fusion : il ne peut plus fusionner"
	if bool(base_of(it).get("unique", false)):
		return "Objet unique"
	if holder_of(str(it["uid"])) != "":
		return "Équipé"
	if fusion_next(str(it.get("rarity", ""))) == "":
		return "Rareté maximale"
	return ""


## "" si ces 3 objets peuvent fusionner, sinon la raison.
static func fusion_block(uids: Array) -> String:
	if uids.size() != int(items_db()["fusion"]["count"]):
		return "Choisis 3 objets de même rareté"
	var items: Array = []
	var rar := ""
	for u in uids:
		var it := find_item(str(u))
		var why := fusion_item_block(it)
		if why != "":
			return why
		if rar == "":
			rar = str(it["rarity"])
		elif str(it["rarity"]) != rar:
			return "Les 3 objets doivent être de même rareté"
		items.append(it)
	if gold() < fusion_cost(items):
		return "Or insuffisant"
	return ""


## Fusionne 3 objets : le premier donne son modèle, le niveau d'objet est le plus haut des trois ;
## le résultat est marqué « fusion » et ne pourra plus fusionner. Les runes gravées reviennent en réserve.
static func fuse_items(uids: Array) -> Dictionary:
	if fusion_block(uids) != "":
		return {}
	var items: Array = []
	for u in uids:
		items.append(find_item(str(u)))
	var first: Dictionary = items[0]
	var ilvl := 1
	for it in items:
		ilvl = maxi(ilvl, int(it.get("ilvl", 1)))
	data["gold"] = gold() - fusion_cost(items)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var out := make_item(str(first["base"]), fusion_next(str(first["rarity"])), ilvl, rng)
	out["fused"] = true
	for it in items:
		for r in it.get("runes", []):
			rune_inventory().append(r)
		(data["inventory"] as Array).erase(it)
	(data["inventory"] as Array).append(out)
	return out


static func battle_opts() -> Dictionary:
	return {"player_level": level(), "gear": gear_stats(), "weapon_element": weapon_element(), "bot_level": maxi(1, level() - 1),
		"flags": Story.active_flags(), "healed": Story.has_flag("s1.sylvarche_purifiee"),
		"mods": all_mods(), "don": don_info(), "deck": deck() if spell_mode() == "deck" else drawer_spells(), "spell_mode": spell_mode(), "circle": circle(),
		"player_race": race(), "look": look(), "player_class": player_class(),
		"loyalty": {"brann": Story.loyalty("brann"), "sylwen": Story.loyalty("sylwen"), "krag": Story.loyalty("krag"), "nyx": Story.loyalty("nyx"), "ignara": Story.loyalty("ignara"), "ssareth": Story.loyalty("ssareth")},
		"active": active_companions(), "bots": bots_opts(), "difficulty": difficulty_mult()}


## Niveau, classe et équipement de chaque compagnon recruté, pour la simulation.
static func bots_opts() -> Dictionary:
	var out := {}
	for who in companions_available():
		out[who] = {"level": companion_level(who), "class": companion_class(who), "gear": gear_stats_of(who), "weapon_element": weapon_element_of(who)}
	return out


# ---------------------------------------------------------------- arbre de compétences (Entraînement)

static func tree_db() -> Dictionary:
	return GameData.load_json("res://data/skill_trees/%s.json" % str(data["player"]["class"]))


## 1 point par niveau à partir du niveau 2, plus 1 tous les 10 niveaux (04-classes-races §3.1).
static func skill_points_total() -> int:
	var l := level()
	var extra := int(l / 20.0) if float(race_mods().get("extra_points", 0.0)) > 0.0 else 0
	return maxi(0, l - 1) + int(l / 10.0) + extra


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
	var parents: Array = node.get("parents", [])
	if not parents.is_empty():
		# Arbre : il faut au moins un rang dans une compétence reliée au palier précédent.
		var linked := false
		var names: Array[String] = []
		for pid in parents:
			linked = linked or skill_rank(str(pid)) > 0
			var pf := find_node(str(pid))
			if not pf.is_empty():
				names.append(str((pf[2] as Dictionary).get("name", pid)))
		if not linked:
			return "Prérequis : %s" % " ou ".join(names)
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


# ---------------------------------------------------------------- options (clé à molette de Havre-Aube)

static func _options() -> Dictionary:
	if not (data.get("options") is Dictionary):
		data["options"] = {}
	return data["options"]


## Vrai : les écoles élémentaires (grimoire du Mage) servent à toutes les voies. Faux : chaque voie
## n'emporte que son grimoire de classe (et les sorts sans école, comme Purifier).
static func elem_for_all() -> bool:
	return bool(_options().get("elem_all", true))


static func set_elem_for_all(v: bool) -> void:
	_options()["elem_all"] = v


## Tir automatique du Flux en combat : le choix du joueur est gardé d'une partie à l'autre.
static func auto_fire_on() -> bool:
	return bool(_options().get("auto_fire", false))


static func set_auto_fire(v: bool) -> void:
	if auto_fire_on() == v:
		return
	_options()["auto_fire"] = v
	save_local()


## Ambiance enrichie des menus (rayons, brume, particules, panneaux en relief, titres dorés).
static func ambience_on() -> bool:
	return bool(_options().get("ambience", true))


static func set_ambience(v: bool) -> void:
	_options()["ambience"] = v
	RuneBox.rich = v


## Éclat au toucher (étincelles là où l'on touche, hors combat).
static func sparkle_on() -> bool:
	return bool(_options().get("sparkle", false))


static func set_sparkle(v: bool) -> void:
	_options()["sparkle"] = v


static func difficulty() -> String:
	var d := str(_options().get("difficulty", "normal"))
	for x in DIFFICULTIES:
		if str(x["id"]) == d:
			return d
	return "normal"


static func set_difficulty(id: String) -> void:
	_options()["difficulty"] = id


static func difficulty_info(id: String = "") -> Dictionary:
	var d := difficulty() if id == "" else id
	for x in DIFFICULTIES:
		if str(x["id"]) == d:
			return x
	return DIFFICULTIES[1]


## Multiplicateur de la difficulté : vitesse et dégâts ennemis, PV du Nexus, XP et butin.
static func difficulty_mult() -> float:
	return float(difficulty_info()["mult"])


## Sort des écoles élémentaires (Feu à Terre, ou de rang sans grimoire de classe).
static func is_elemental(id: String) -> bool:
	var sp: Dictionary = GameData.spells().get(id, {})
	return sp.has("school") and not sp.has("grimoire")


## Sort que la voie actuelle peut emporter, selon l'option des écoles élémentaires.
static func elem_allowed(id: String) -> bool:
	return elem_for_all() or player_class() == "mage" or not is_elemental(id)


## Techniques de départ d'une classe : apprises d'office.
static func starter_spells(cls: String) -> Array:
	return ((GameData.party()["classes"] as Dictionary).get(cls, {}) as Dictionary).get("starter_spells", [])


## Classe propriétaire d'un sort du grimoire de classe (« » pour le grimoire élémentaire, commun).
static func grimoire_of(id: String) -> String:
	return str((GameData.spells().get(id, {}) as Dictionary).get("grimoire", ""))


## Classe d'un sort de classe : son grimoire, ou l'arbre de compétences qui le débloque (Entraînement) ;
## « » pour les sorts des écoles élémentaires (le Mage, et ses sorts d'arbre, y compris).
static func spell_class(id: String) -> String:
	var sp: Dictionary = GameData.spells().get(id, {})
	if sp.has("grimoire"):
		return str(sp["grimoire"])
	if sp.has("tree_class") and not sp.has("school") and str(sp["tree_class"]) != "mage":
		return str(sp["tree_class"])
	return ""


## Case du Tiroir d'un sort : la discipline de sa classe (« d:os »…) pour un sort de classe (grimoire ou
## arbre), sinon son école (Purifier, sans école, va avec la Lumière).
static func drawer_group(id: String) -> String:
	var sp: Dictionary = GameData.spells().get(id, {})
	if spell_class(id) != "" and sp.has("disc"):
		return "d:" + str(sp["disc"])
	return str(sp.get("school", "lumiere"))


## Grimoire d'une classe (docs/design/29-grimoires-de-classe.md) : ses techniques, du rang Novice à Interdit.
## Le Mage a pour grimoire les écoles élémentaires, communes à toutes les voies.
static func class_grimoire(cls: String) -> Array[String]:
	var out: Array[String] = []
	for rank in SPELL_RANKS:
		for id in GameData.spells().keys():
			var sp: Dictionary = GameData.spells()[id]
			if str(sp.get("grimoire", "")) == cls and str(sp.get("rank", "")) == rank:
				out.append(str(id))
	return out


## Disciplines du grimoire d'une classe (8 au plus : une case du Tiroir chacune).
static func disciplines(cls: String) -> Array:
	return ((GameData.party()["classes"] as Dictionary).get(cls, {}) as Dictionary).get("disciplines", [])


static func discipline_info(cls: String, disc: String) -> Dictionary:
	for d in disciplines(cls):
		if str((d as Dictionary)["id"]) == disc:
			return d
	return {}


## Sorts connus et utilisables : appris (base, Bibliothèque) et débloqués par l'arbre. Les techniques
## du grimoire d'une autre classe restent apprises mais ne servent qu'en suivant cette voie.
static func known_spells() -> Array[String]:
	var out: Array[String] = []
	var cls := player_class()
	for id in starter_spells(cls):
		if GameData.spells().has(str(id)):
			out.append(str(id))
	for id in _spells_state().get("known", []):
		var g := grimoire_of(str(id))
		if GameData.spells().has(str(id)) and not out.has(str(id)) and (g == "" or g == cls) and elem_allowed(str(id)):
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
	if out.size() < mini(3, known.size()):
		# Deck presque vide (option des écoles changée, nouvelle voie) : complété par les sorts connus.
		for id in known:
			if out.size() < DECK_MAX and not out.has(id):
				out.append(id)
	return out


# ---------------------------------------------------------------- héros (création de personnage, Miroir)

static func race() -> String:
	return str(data["player"].get("race", "elfe"))


static func player_class() -> String:
	return str(data["player"].get("class", "mage"))


static func look() -> Dictionary:
	return PlayerLook.of(data["player"].get("look", {}))


static func set_look(k: String, v: Variant) -> void:
	var lk: Dictionary = data["player"].get("look", {})
	lk[k] = v
	data["player"]["look"] = lk


## Choix de la race (création) : la teinte de peau revient à la 2e de la race.
static func set_race(r: String) -> bool:
	var ri: Dictionary = (GameData.party()["races"] as Dictionary).get(r, {})
	if ri.is_empty() or ri.has("locked"):
		return false
	data["player"]["race"] = r
	set_look("skin", 1)
	return true


static func set_class(c: String) -> bool:
	var ci: Dictionary = (GameData.party()["classes"] as Dictionary).get(c, {})
	if ci.is_empty() or not bool(ci.get("playable", false)):
		return false
	data["player"]["class"] = c
	return true


## Personnage créé (sinon l'écran de création s'affiche à l'arrivée à Havre-Aube).
# ---------------------------------------------------------------- héritage racial (étape 13.2)

static func race_tree() -> Array:
	return (GameData.load_json("res://data/race_trees.json")["races"] as Dictionary).get(race(), [])


static func _heritage() -> Dictionary:
	if not (data["player"].get("heritage") is Dictionary):
		data["player"]["heritage"] = {}
	return data["player"]["heritage"]


static func race_rank(id: String) -> int:
	return int(_heritage().get(id, 0))


## Points d'héritage : 1 tous les 10 niveaux, plus 1 par acte terminé (boss de fin de zone vaincu).
static func heritage_total() -> int:
	var n := int(level() / 10.0)
	for z in GameData.level_index().get("zones", []):
		var ids: Array = z.get("levels", [])
		if not ids.is_empty() and int(level_record(str(ids.back()))["clears"]) > 0:
			n += 1
	return n


static func heritage_spent() -> int:
	var n := 0
	for node in race_tree():
		n += race_rank(str(node["id"]))
	return n


static func race_invest_block(id: String) -> String:
	for node in race_tree():
		if str(node["id"]) == id:
			if race_rank(id) >= int(node.get("max", 3)):
				return "Rang maximum"
			if heritage_spent() >= heritage_total():
				return "Aucun point d'héritage"
			return ""
	return "Nœud inconnu"


static func race_invest(id: String) -> bool:
	if race_invest_block(id) != "":
		return false
	_heritage()[id] = race_rank(id) + 1
	return true


## Passifs de la race et rangs de l'arbre d'héritage.
static func race_mods() -> Dictionary:
	var out: Dictionary = ((GameData.party()["races"] as Dictionary).get(race(), {}) as Dictionary).get("passive_mods", {}).duplicate()
	for node in race_tree():
		var r := race_rank(str(node["id"]))
		if r <= 0:
			continue
		var m: Dictionary = node.get("mods", {})
		for k in m.keys():
			out[k] = float(out.get(k, 0.0)) + float(m[k]) * float(r)
	return out


## Modificateurs de combat : arbre de compétences + race.
static func all_mods() -> Dictionary:
	var out := skill_mods()
	var rm := race_mods()
	for k in rm.keys():
		out[k] = float(out.get(k, 0.0)) + float(rm[k])
	var ru := rune_mods_of("player")
	for k in ru.keys():
		out[k] = float(out.get(k, 0.0)) + float(ru[k])
	return out


## Don racial : {id, name, cd} (recharge réduite par l'arbre d'héritage).
static func don_info() -> Dictionary:
	var ri: Dictionary = (GameData.party()["races"] as Dictionary).get(race(), {})
	if not ri.has("don_id"):
		return {}
	var cd := float(ri.get("don_cd", 60)) * (1.0 - clampf(float(race_mods().get("don_cd", 0.0)), 0.0, 0.6))
	return {"id": str(ri["don_id"]), "name": str(ri.get("don_name", "Don")), "cd": cd, "color": str(ri.get("color", "F2C46B")),
		"power": float(race_mods().get("don_power", 0.0))}


static func created() -> bool:
	return bool(data["player"].get("created", false))


static func set_created() -> void:
	data["player"]["created"] = true


## Mode des sorts en combat : « deck » (7 sorts choisis) ou « drawer » (tiroir : tous les sorts connus,
## rangés par école). Choisi à l'écran de préparation.
static func spell_mode() -> String:
	return "drawer" if str(data.get("spell_mode", "deck")) == "drawer" else "deck"


static func set_spell_mode(m: String) -> void:
	data["spell_mode"] = "drawer" if m == "drawer" else "deck"


## Missions déjà réussies : revoir leurs cinématiques (intro et fin) ou les passer (par défaut).
## Le choix se fait à la préparation et reste mémorisé.
static func replay_scenes() -> bool:
	return bool(data.get("replay_scenes", false))


static func set_replay_scenes(on: bool) -> void:
	data["replay_scenes"] = on


## Le choix de revoir les cinématiques s'offre-t-il pour ce niveau (réussi, avec une intro ou une fin) ?
static func can_replay_scenes(level_id: String) -> bool:
	return int(level_record(level_id)["clears"]) > 0 \
		and (Dialogues.has_scene(level_id + "_intro") or Dialogues.has_scene(level_id + "_outro"))


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
			var a: float = 0.9 if bool(sp.get("single", false)) else area.call(float(sp.get("radius", 1.0)))
			p = dmg * a + float(sp.get("freeze", 0.0)) * 25.0 * a + float(sp.get("root", 0.0)) * 12.0 * a
		"zone":
			var a: float = area.call(float(sp.get("radius", 1.5)))
			var d := float(sp.get("dur", 3.0))
			p = float(sp.get("dps", 0)) * d * a + float(sp.get("slow", 0.0)) * d * 12.0 * a + float(sp.get("pull", 0.0)) * d * 8.0 + dmg * a
			p += float(sp.get("ally_heal", 0.0)) * d * 150.0 * a + float(sp.get("ally_shield", 0.0)) * a * 1.5
			if str(sp.get("spawn", "")) != "":
				# Cimetière : une invocation toutes les « spawn_every » s.
				var su: Dictionary = GameData.units().get(str(sp["spawn"]), {})
				var uv := float(su.get("hp", 10)) * 0.4 + float(su.get("atk", 10)) / maxf(0.3, float(su.get("atk_interval", 0.5))) * 1.5
				p += d / maxf(0.3, float(sp.get("spawn_every", 2.0))) * uv * (2.0 if str(su.get("role", "")) == "elite" else 1.0)
			if bool(sp.get("raise", false)):
				p += d * 4.0 * a
			p += (float(sp.get("ally_atk", 0.0)) + float(sp.get("ally_aspd", 0.0)) * 0.9) * d * 30.0 * minf(a, 2.5)
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
		"rally":
			p = _rally_power(sp)
		"harvest":
			# Sacrifice : chaque invocation sacrifiée explose (Ombre, 0,9 m).
			p = float(sp.get("count", 20)) * (float(sp.get("damage", 25)) + 20.0) * 0.6
		"mirror":
			p = float(sp.get("count", 10)) * 15.0
		"frenzy":
			# Frénésie de toutes les invocations : +40 % de dégâts, vol de vie.
			p = float(sp.get("dur", 6.0)) * 40.0 + dmg * float(area.call(float(sp.get("radius", 1.5))))
		"army":
			# Invocations : PV, dégâts par seconde, aura de soin ; une élite compte double ; durée de vie limitée.
			var kinds: Array = sp.get("kinds", [])
			var life := float(sp.get("life", 0.0))
			for k in range(int(sp.get("count", 6))):
				var ud: Dictionary = GameData.units().get(str(kinds[k % kinds.size()]) if not kinds.is_empty() else str(sp.get("kind", "skeleton")), {})
				var u := float(ud.get("hp", 10)) * 0.4 + float(ud.get("atk", 10)) / maxf(0.3, float(ud.get("atk_interval", 0.5))) * 1.5 + float(ud.get("heal_aura", 0.0)) * 20.0
				p += u * (2.0 if str(ud.get("role", "")) == "elite" else 1.0) * (minf(1.0, life / 30.0) if life > 0.0 else 1.0)
			p += dmg * float(area.call(float(sp.get("radius", 2.0))))
		"purify":
			p = 100.0 + dmg * float(area.call(float(sp.get("radius", 2.5))))
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
				"piege":
					p = float(sp.get("count", 1)) * (float(sp.get("blast", 60)) * float(area.call(float(sp.get("blast_r", 1.4)))) + float(sp.get("root", 0.0)) * 15.0)
	p += dmg * float(sp.get("nexus_ratio", 0.0)) * 2.0 + float(sp.get("surge_gain", 0.0)) * 20.0
	# Effets du grimoire de classe : marque, givre, recul, exécution, gros gibier, critique, renfort.
	p += float(sp.get("weak", 0.0)) * 6.0 + float(sp.get("stun", 0.0)) * 12.0 + float(sp.get("heal_per", 0.0)) * float(sp.get("count", 0)) * 6.0
	p += float(sp.get("mark", 0.0)) * 5.0 + float(sp.get("chill", 0)) * 15.0 + float(sp.get("knock", 0.0)) * 20.0 + float(sp.get("bleed", 0.0)) * 8.0
	if bool(sp.get("chain_bolt", false)):
		p += dmg * 0.4 * 2.0
	p += dmg * (float(sp.get("execute", 0.0)) * 0.3 + float(sp.get("big_game", 0.0)) * 0.3 + float(sp.get("crit_add", 0.0)) + float(sp.get("marked_bonus", 0.0)) * 0.3)
	if sp.get("rally", null) is Dictionary:
		p += _rally_power(sp["rally"])
	var g: Variant = sp.get("ground", null)
	if g is Dictionary:
		# Sol laissé par le sort (gravats, faille…).
		p += dmg * float((g as Dictionary).get("dps", 0.0)) * float((g as Dictionary).get("dur", 0.0)) * 2.0 + float((g as Dictionary).get("dur", 0.0)) * 5.0
	return int(round(p))


## Valeur d'un renfort : dégâts, cadence, critique, bouclier et soin des invocations, selon la durée.
static func _rally_power(r: Dictionary) -> float:
	var reach := 1.0 if float(r.get("radius", 0.0)) <= 0.0 else minf(1.0, float(r["radius"]) / 3.0)
	return (float(r.get("atk", 0.0)) + float(r.get("aspd", 0.0)) * 0.9 + float(r.get("crit", 0.0)) * 1.2 + float(r.get("shield", 0.0)) * 0.8
		+ float(r.get("heal", 0.0)) * 0.6 + float(r.get("steal", 0.0)) * 1.0 + float(r.get("thorns", 0.0)) * 0.5) * float(r.get("dur", 6.0)) * 90.0 * reach


## Prix d'un sort à la Bibliothèque : proportionnel à sa puissance (arrondi à 10 or, à 50 or au-delà de 1 000).
static func spell_price(id: String) -> int:
	var g := maxf(float(SPELL_PRICE_MIN), float(spell_power(id)) * SPELL_PRICE_PER_POWER)
	g *= 1.0 - clampf(float(race_mods().get("price_discount", 0.0)), 0.0, 0.5)
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


## Techniques apprises, quelle que soit la voie suivie.
static func learned(id: String) -> bool:
	return (_spells_state().get("known", []) as Array).has(id)


static func learn_block(id: String) -> String:
	var l := learn_info(id)
	if l.is_empty():
		return "Ne s'apprend pas à la Bibliothèque"
	if not elem_allowed(id):
		return "Réservé au Mage (Options)"
	if known_spells().has(id) or learned(id):
		return "Déjà appris"
	var g := grimoire_of(id)
	if g != "" and g != player_class():
		return "Voie %s requise" % str(((GameData.party()["classes"] as Dictionary).get(g, {}) as Dictionary).get("name", g))
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
		"nyx": {"order": "focus_nexus", "spell": "linceul"}, "ignara": {"order": "focus_nexus", "spell": "souffle_draconique"}, "ssareth": {"order": "defends", "spell": "chant_archives"}}


## Compagnons qui ont rejoint le groupe (Krag : selon les choix de l'acte 2).
static func companions_available() -> Array[String]:
	var out: Array[String] = []
	for bd in GameData.party()["bots"]:
		var req := str(bd.get("requires", ""))
		if (req == "" or Story.has_flag(req)) and not Story.companion_lost(str(bd["id"])):
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


# ---------------------------------------------------------------- compagnons : niveaux, voies, équipement (étape 13.4)

static func _bot_def(who: String) -> Dictionary:
	for bd in GameData.party()["bots"]:
		if str(bd.get("id", "")) == who:
			return bd
	return {}


## État d'un compagnon (créé au besoin : niveau du héros − 1, classe d'origine, rien d'équipé).
static func _comp(who: String) -> Dictionary:
	if not (data.get("companions") is Dictionary):
		data["companions"] = {}
	var all: Dictionary = data["companions"]
	if not (all.get(who) is Dictionary):
		all[who] = {}
	var c: Dictionary = all[who]
	if not c.has("level"):
		c["level"] = maxi(1, level() - 1)
	if not c.has("xp"):
		c["xp"] = 0
	if not c.has("class"):
		c["class"] = str(_bot_def(who).get("class", "chevalier"))
	if not (c.get("equipped") is Dictionary):
		c["equipped"] = {}
	return c


static func companion_level(who: String) -> int:
	return clampi(maxi(int(_comp(who)["level"]), level() - COMPANION_FLOOR), 1, int(prog_db()["max_level"]))


static func companion_xp(who: String) -> int:
	var c := _comp(who)
	return int(c["xp"]) if int(c["level"]) >= companion_level(who) else 0


## Ajoute de l'XP à un compagnon et retourne le nombre de niveaux gagnés.
static func add_companion_xp(who: String, amount: int) -> int:
	var c := _comp(who)
	var lv := companion_level(who)
	if int(c["level"]) < lv:
		c["level"] = lv
		c["xp"] = 0
	var x := int(c["xp"]) + maxi(0, amount)
	var max_lv := int(prog_db()["max_level"])
	var gained := 0
	while lv < max_lv and x >= xp_to_next(lv):
		x -= xp_to_next(lv)
		lv += 1
		gained += 1
	c["xp"] = x
	c["level"] = lv
	return gained


static func companion_class(who: String) -> String:
	return str(_comp(who)["class"])


## Change la voie d'un compagnon (Salle de méditation). Son sort passe au premier de sa nouvelle classe.
static func set_companion_class(who: String, cls: String) -> bool:
	var ci: Dictionary = (GameData.party()["classes"] as Dictionary).get(cls, {})
	if ci.is_empty() or not bool(ci.get("playable", false)) or not meditation_unlocked() or _bot_def(who).is_empty():
		return false
	_comp(who)["class"] = cls
	var circ := circle()
	if circ.get(who) is Dictionary and not companion_spells(who).has(str((circ[who] as Dictionary).get("spell", ""))):
		(circ[who] as Dictionary)["spell"] = companion_spells(who)[0]
	return true


static func companion_spells(who: String) -> Array[String]:
	var out: Array[String] = []
	var bd := _bot_def(who)
	if companion_class(who) == str(bd.get("class", "")):
		# Sort propre au compagnon (Souffle draconique d'Ignara).
		for sid in bd.get("spells", []):
			if not out.has(str(sid)):
				out.append(str(sid))
	for sid in CLASS_SPELLS.get(companion_class(who), []):
		if not out.has(str(sid)):
			out.append(str(sid))
	if Story.has_flag("s1.heritage_" + who):
		out.append("souffle_de_cendre")
	return out


static func companion_role(who: String) -> String:
	var bd := _bot_def(who)
	if companion_class(who) == str(bd.get("class", "")):
		return str(bd.get("role", ""))
	return str(CLASS_ROLES.get(companion_class(who), ""))


## Stats d'un compagnon : classe + progression par niveau + race + équipement (mêmes règles que le héros).
static func companion_stats(who: String) -> Dictionary:
	var party := GameData.party()
	var cls: Dictionary = party["classes"].get(companion_class(who), {})
	var race: Dictionary = party["races"].get(str(_bot_def(who).get("race", "")), {})
	var l := companion_level(who)
	var gear := gear_stats_of(who)
	var out := {}
	for k in STATS:
		var b := float((cls.get("base", {}) as Dictionary).get(k, 0))
		out[k] = b + b / 10.0 * float(l - 1) + float(race.get(k, 0)) + float(gear.get(k, 0))
	return out


static func companion_power(who: String) -> int:
	var st := companion_stats(who)
	var total := 0.0
	for k in STATS:
		total += float(st[k])
	return int(round(total * 1.6))


# ---------------------------------------------------------------- Salle de méditation (étape 13.4)

## Ouverte à la fin de l'acte 1 (Sylvarche vaincue) : c'est aussi le début des changements de voie (acte 2).
static func meditation_unlocked() -> bool:
	return int(level_record("z01_l10")["clears"]) > 0


## Changer de voie (classe du héros) à la Salle de méditation. Chaque classe garde son propre arbre.
static func change_class(c: String) -> bool:
	if not meditation_unlocked():
		return false
	return set_class(c)


static func _med() -> Dictionary:
	if not (data.get("meditation") is Dictionary):
		data["meditation"] = {}
	var m: Dictionary = data["meditation"]
	if not (m.get("configs") is Array):
		m["configs"] = []
	while (m["configs"] as Array).size() < CONFIG_SLOTS:
		(m["configs"] as Array).append({})
	if not m.has("harmony"):
		m["harmony"] = 0
	return m


static func configs() -> Array:
	return _med()["configs"]


## Noms des Clés de voûte prises dans l'arbre de la classe actuelle.
static func keystone_names() -> Array[String]:
	var out: Array[String] = []
	for br in tree_db().get("branches", []):
		for tier in br.get("tiers", []):
			for node in tier["nodes"]:
				if str(node.get("kind", "")) == "keystone" and skill_rank(str(node["id"])) > 0:
					out.append(str(node["name"]))
	return out


## Enregistre la configuration actuelle : classe, arbre, deck et mode de sorts.
static func save_config(i: int) -> void:
	if i < 0 or i >= CONFIG_SLOTS:
		return
	configs()[i] = {"class": player_class(), "ranks": skill_ranks().duplicate(), "deck": deck().duplicate(), "mode": spell_mode(),
		"keys": keystone_names(), "points": skill_points_spent()}


## Recharge une configuration ; "" si tout va bien, sinon la raison.
static func load_config(i: int) -> String:
	if i < 0 or i >= CONFIG_SLOTS:
		return "Emplacement inconnu"
	var cfg: Dictionary = configs()[i]
	if cfg.is_empty():
		return "Emplacement vide"
	if str(cfg.get("class", "")) != player_class() and not change_class(str(cfg.get("class", ""))):
		return "Voie indisponible"
	var ranks := skill_ranks()
	ranks.clear()
	var saved: Dictionary = cfg.get("ranks", {})
	for id in saved.keys():
		if not find_node(str(id)).is_empty():
			ranks[str(id)] = int(saved[id])
	if skill_points_spent() > skill_points_total():
		ranks.clear()
		return "Points de compétence insuffisants"
	var known := known_spells()
	var dk: Array = []
	for sid in cfg.get("deck", []):
		if known.has(str(sid)) and dk.size() < DECK_MAX:
			dk.append(str(sid))
	if not dk.is_empty():
		_spells_state()["deck"] = dk
	set_spell_mode(str(cfg.get("mode", spell_mode())))
	return ""


## Harmonie (Sœur Aelis) : méditer fait baisser la Corruption de 5. Coût : 100 or, +50 à chaque séance.
static func harmony_cost() -> int:
	return 100 + 50 * int(_med()["harmony"])


static func harmony() -> int:
	var cost := harmony_cost()
	if Story.value("corruption") <= 0 or gold() < cost:
		return 0
	data["gold"] = gold() - cost
	_med()["harmony"] = int(_med()["harmony"]) + 1
	return -Story.add_value("corruption", -5)
