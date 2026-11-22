class_name Story
extends RefCounted
## Fils du destin (docs/design/07-narration.md) : drapeaux, choix, loyauté des compagnons,
## réputation, corruption, scènes vues. Rangé dans Profile.data["story"] : sauvegardé et
## synchronisé avec le reste de la progression.
##
## Clés de valeur : « loy.<compagnon> » (0 à 100), « rep.<faction> » (−100 à 100), « corruption » (0 à 100).
## Drapeaux rangés par saison : « s1.fees_liberees », « s1.sylvarche_purifiee »…

const COMPANIONS := {"brann": "Brann", "sylwen": "Sylwen", "krag": "Krag", "nyx": "Nyx"}
const FACTIONS := {
	"elfes": "Elfes", "orcs": "Clans orcs", "humains": "Royaumes humains", "nains": "Nains",
	"cendres": "Cercle des Cendres", "aube": "Ordre de l'Aube", "dragons": "Dragons", "archivistes": "Archivistes",
}
## Jouer une partie avec un compagnon : +1 de loyauté, au plus +5 par jour (07-narration §5.1).
const PLAY_BONUS_DAILY := 5


static func default_state() -> Dictionary:
	return {"flags": {}, "choices": {}, "seen": {}, "loyalty": {"brann": 50, "sylwen": 50},
		"rep": {}, "corruption": 0, "echo_debt": 0, "play_bonus": {}}


## État de l'histoire, complété si la sauvegarde est ancienne.
static func st() -> Dictionary:
	if not (Profile.data.get("story") is Dictionary):
		Profile.data["story"] = default_state()
	var s: Dictionary = Profile.data["story"]
	var def := default_state()
	for k in def.keys():
		if not s.has(k):
			s[k] = def[k]
	return s


static func player_name() -> String:
	if Cloud.instance != null and Cloud.instance.username != "":
		return Cloud.instance.username
	return "Porteur"


# ---------------------------------------------------------------- drapeaux, choix, scènes

static func has_flag(f: String) -> bool:
	return bool((st()["flags"] as Dictionary).get(f, false))


static func set_flag(f: String, on: bool = true) -> void:
	if on:
		st()["flags"][f] = true
	else:
		(st()["flags"] as Dictionary).erase(f)


## Flags actifs, pour la simulation (modificateurs d'histoire des niveaux).
static func active_flags() -> Array[String]:
	var out: Array[String] = []
	for k in (st()["flags"] as Dictionary).keys():
		if bool(st()["flags"][k]):
			out.append(str(k))
	return out


static func choice(id: String) -> String:
	var c: Variant = (st()["choices"] as Dictionary).get(id, {})
	return str((c as Dictionary).get("opt", "")) if c is Dictionary else ""


static func seen(scene_id: String) -> bool:
	return (st()["seen"] as Dictionary).has(scene_id)


static func mark_seen(scene_id: String) -> void:
	st()["seen"][scene_id] = true


# ---------------------------------------------------------------- valeurs

static func value(key: String) -> int:
	var s := st()
	var parts := key.split(".", true, 1)
	match parts[0]:
		"loy":
			return int((s["loyalty"] as Dictionary).get(parts[1], 50))
		"rep":
			return int((s["rep"] as Dictionary).get(parts[1], 0))
		"corruption":
			return int(s["corruption"])
	return 0


static func loyalty(who: String) -> int:
	return value("loy." + who)


## Ajoute delta à une valeur (bornée) et retourne la variation réelle.
static func add_value(key: String, delta: int) -> int:
	var s := st()
	var parts := key.split(".", true, 1)
	var before := value(key)
	var after := before
	match parts[0]:
		"loy":
			after = clampi(before + delta, 0, 100)
			s["loyalty"][parts[1]] = after
		"rep":
			after = clampi(before + delta, -100, 100)
			s["rep"][parts[1]] = after
		"corruption":
			after = clampi(before + delta, 0, 100)
			s["corruption"] = after
	return after - before


static func value_label(key: String) -> String:
	var parts := key.split(".", true, 1)
	match parts[0]:
		"loy":
			return "%s : loyauté" % str(COMPANIONS.get(parts[1], parts[1].capitalize()))
		"rep":
			return "%s : réputation" % str(FACTIONS.get(parts[1], parts[1].capitalize()))
		"corruption":
			return "Corruption"
	return key


# ---------------------------------------------------------------- conditions et effets

## Conditions : « if » / « if_not » (drapeau ou liste), « loy_min » / « loy_max » ({compagnon: seuil}),
## « chose » ({id: option ou liste d'options}), « only » ({race: [...], class: [...]} : option réservée
## à une race OU à une classe du joueur, ex. [Humain/Clerc]).
static func check(cond: Dictionary) -> bool:
	for f in _as_list(cond.get("if", [])):
		if not has_flag(f):
			return false
	for f in _as_list(cond.get("if_not", [])):
		if has_flag(f):
			return false
	var lmin: Dictionary = cond.get("loy_min", {})
	for who in lmin.keys():
		if loyalty(str(who)) < int(lmin[who]):
			return false
	var lmax: Dictionary = cond.get("loy_max", {})
	for who in lmax.keys():
		if loyalty(str(who)) > int(lmax[who]):
			return false
	var ch: Dictionary = cond.get("chose", {})
	for id in ch.keys():
		if not _as_list(ch[id]).has(choice(str(id))):
			return false
	var only: Dictionary = cond.get("only", {})
	if not only.is_empty():
		var pl: Dictionary = Profile.data.get("player", {})
		if not (_as_list(only.get("race", [])).has(str(pl.get("race", ""))) or _as_list(only.get("class", [])).has(str(pl.get("class", "")))):
			return false
	return true


static func _as_list(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if v is Array:
		for x in v:
			out.append(str(x))
	elif str(v) != "":
		out.append(str(v))
	return out


## Applique des effets et retourne les lignes de bilan à afficher :
## « set » / « clear » (drapeaux), « add » ({clé: delta}), « grant » ({base, rarity}),
## « also » (liste d'effets conditionnels, mêmes conditions que check()).
static func apply(eff: Dictionary, ilvl: int = 0) -> Array[String]:
	var out: Array[String] = []
	for f in _as_list(eff.get("set", [])):
		set_flag(f)
	for f in _as_list(eff.get("clear", [])):
		set_flag(f, false)
	var add: Dictionary = eff.get("add", {})
	for k in add.keys():
		var d := add_value(str(k), int(add[k]))
		if d != 0:
			out.append("%s %+d" % [value_label(str(k)), d])
	var g: Dictionary = eff.get("grant", {})
	if not g.is_empty():
		out.append(_grant(str(g["base"]), str(g.get("rarity", "commun")), ilvl if ilvl > 0 else Profile.level()))
	for sub in eff.get("also", []):
		if check(sub):
			out.append_array(apply(sub, ilvl))
	return _merge(out)


## Fusionne les variations successives d'une même valeur (ex. « Sylwen : loyauté −30 » puis « +15 »).
static func _merge(lines: Array[String]) -> Array[String]:
	var totals := {}
	var order: Array[String] = []
	var out: Array[String] = []
	for l in lines:
		var i := l.rfind(" ")
		var head := l.substr(0, i)
		var num := l.substr(i + 1)
		if i > 0 and num.is_valid_int() and (num.begins_with("+") or num.begins_with("-")):
			if not totals.has(head):
				order.append(head)
				totals[head] = 0
			totals[head] = int(totals[head]) + int(num)
		else:
			out.append(l)
	var merged: Array[String] = []
	for h in order:
		if int(totals[h]) != 0:
			merged.append("%s %+d" % [h, int(totals[h])])
	merged.append_array(out)
	return merged


static func _grant(base_id: String, rarity: String, ilvl: int) -> String:
	var base: Dictionary = Profile.items_db()["bases"].get(base_id, {})
	if bool(base.get("unique", false)):
		for it in Profile.data["inventory"]:
			if str(it.get("base", "")) == base_id:
				return "Déjà en ta possession : %s" % str(base.get("name", base_id))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var it := Profile.make_item(base_id, rarity, ilvl, rng)
	(Profile.data["inventory"] as Array).append(it)
	return "Objet obtenu : %s (%s)" % [Profile.item_name(it), str(Profile.rarity_of(it).get("name", rarity))]


## Enregistre un choix (avec sa date, pour la future Carte des fils du destin) et applique ses effets.
static func choose(choice_id: String, opt: Dictionary, ilvl: int = 0) -> Array[String]:
	st()["choices"][choice_id] = {"opt": str(opt.get("key", "")), "t": int(Time.get_unix_time_from_system())}
	return apply(opt.get("effects", {}), ilvl)


## Fin de partie : +1 de loyauté par compagnon présent, au plus PLAY_BONUS_DAILY par jour.
static func on_battle(present: Array[String]) -> void:
	var pb: Dictionary = st()["play_bonus"]
	var today := Time.get_date_string_from_system()
	if str(pb.get("date", "")) != today:
		pb.clear()
		pb["date"] = today
	for who in present:
		if not COMPANIONS.has(who):
			continue
		var n := int(pb.get(who, 0))
		if n < PLAY_BONUS_DAILY:
			pb[who] = n + 1
			add_value("loy." + who, 1)
