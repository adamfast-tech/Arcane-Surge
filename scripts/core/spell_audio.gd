class_name SpellAudio
extends RefCounted
## Signature sonore de chaque sort (docs/design/43-audio.md).
## Un sort a une famille de timbre (sa discipline de classe, sinon son école, sinon son élément), un accent
## (l'élément quand il diffère de la famille : flèche de feu = flèche + feu), une hauteur propre (rang, puis
## une variation tirée de son identifiant), un volume (rang) et des couches de prestige (Archimage : montée
## orchestrale ; Interdit : chœur grave et souffle inversé). Les sons viennent de assets/audio/sfx
## (<famille>_cast, _hit, _boom, _loop, _proj), générés par tools/audio/sfx_bank.py.

const FAMILIES := ["feu", "givre", "foudre", "nature", "ombre", "lumiere", "arcane", "terre", "poison", "sang", "os", "ames",
	"malefice", "morts", "fleche", "piege", "astral", "betes", "lame", "spectre", "garde", "hache", "cri", "clan", "seisme",
	"chevalier", "forteresse", "justice", "soin", "anges", "purif", "sacre", "tempete"]
const HAS_PROJ := ["feu", "givre", "foudre", "fleche", "lame", "hache"]

## Discipline de classe -> famille (« » : l'élément du sort décide).
const DISC := {
	# Archer
	"tir": "fleche", "volees": "fleche", "traque": "fleche", "pieges": "piege", "betes": "betes", "poisons": "poison",
	"astral": "astral", "elements": "",
	# Épéiste
	"acier": "lame", "taille": "lame", "estoc": "lame", "danse": "lame", "saignee": "lame", "garde": "garde",
	"spectres": "spectre", "tempete": "tempete",
	# Chevalier
	"bouclier": "garde", "charge": "chevalier", "defi": "chevalier", "etendard": "chevalier", "ordre": "chevalier",
	"forteresse": "forteresse", "justice": "justice", "serment": "justice",
	# Berserker
	"haches": "hache", "assaut": "hache", "carnage": "hache", "cris": "cri", "fureur": "cri", "clan": "clan",
	"totems": "clan", "seisme": "seisme",
	# Clerc
	"anges": "anges", "benediction": "soin", "soins": "soin", "egide": "garde", "purification": "purif",
	"chatiment": "sacre", "rayons": "sacre", "sanctuaire": "sacre",
	# Nécromancien
	"os": "os", "morts": "morts", "necropole": "morts", "malefices": "malefice", "fleaux": "poison", "ames": "ames",
	"tenebres": "ombre", "sang": "sang",
}
const ELEM := {"feu": "feu", "givre": "givre", "foudre": "foudre", "nature": "nature", "ombre": "ombre", "lumiere": "lumiere",
	"arcane": "arcane", "physique": "terre"}
## Sans discipline, l'élément physique sonne selon la classe.
const CLASS_PHYS := {"archer": "fleche", "epeiste": "lame", "chevalier": "chevalier", "berserker": "hache",
	"necromancien": "os", "clerc": "sacre"}
## Type de sort -> famille, quand le type parle plus fort que l'élément.
const TYPE_FAM := {"barrier_heal": "soin", "barrier_shield": "garde", "purify": "purif", "frenzy": "cri", "harvest": "ames",
	"wall": "forteresse", "quake": "seisme", "mirror": "spectre"}
## Couche d'attaque de chaque sort : une touche tirée de son identifiant, parmi celles qui vont à sa famille
## (« » : aucune). Avec la hauteur, elle rend chaque sort reconnaissable.
const SWEET := {
	"clair": ["", "sw_spark", "sw_glass", "sw_ping", "sw_air"],
	"sombre": ["", "sw_sub", "sw_air", "sw_rattle", "sw_whisper"],
	"arme": ["", "sw_sub", "sw_air", "sw_ping", "sw_rattle"],
	"element": ["", "sw_sub", "sw_air", "sw_spark", "sw_rattle"],
}
const SWEET_GROUP := {"lumiere": "clair", "soin": "clair", "anges": "clair", "purif": "clair", "sacre": "clair", "justice": "clair",
	"astral": "clair", "arcane": "clair", "givre": "clair", "ombre": "sombre", "malefice": "sombre", "ames": "sombre", "morts": "sombre",
	"os": "sombre", "sang": "sombre", "poison": "sombre", "spectre": "sombre", "feu": "element", "foudre": "element", "nature": "element"}
const RANK_PITCH := {"novice": 1.08, "intermediaire": 1.04, "apprenti": 1.0, "mage": 0.97, "maitre": 0.94, "archimage": 0.91, "interdit": 0.87}
const RANK_DB := {"novice": -3.0, "intermediaire": -2.0, "apprenti": -1.0, "mage": 0.0, "maitre": 0.5, "archimage": 1.0, "interdit": 1.5}

## Invocations : genre d'unité -> son d'apparition.
const SUMMON := {"skeleton": "bones", "skeleton_archer": "bones", "ghoul": "bones", "lich": "bones", "abomination": "bones",
	"death_knight": "knight", "bone_golem": "golem", "wraith": "spirit", "beast_wolf": "wolf", "war_wolf": "wolf",
	"beast_alpha": "wolf", "beast_bear": "bear", "spirit_bear": "bear", "beast_falcon": "bird", "beast_stag": "stag",
	"beast_void": "void", "cherub": "angel", "seraph": "angel", "archangel": "angel", "holy_wisp": "crystal",
	"holy_paladin": "knight", "squire": "knight", "cavalier": "knight", "crossbowman": "knight", "fallen_king": "knight",
	"sword_guard": "knight", "ronin": "blade", "blade_dancer": "blade", "flying_sword": "blade", "blade_master_ghost": "blade",
	"raider": "warrior", "war_chief": "warrior", "war_totem": "totem", "giant": "giant", "blood_titan": "giant",
	"crystal_guardian": "crystal", "baliste": "machine"}

static var _cache: Dictionary = {}


## Profil sonore d'un sort : {fam, accent, pitch, db, grand, forbidden, type, kind}.
static func profile(id: String) -> Dictionary:
	if _cache.is_empty():
		_build_all()
	if _cache.has(id):
		return _cache[id]
	return _make(id, 0)


## Profils de tous les sorts, dans l'ordre de leurs identifiants : si deux sorts sonneraient pareil (même
## famille, accent, hauteur, touche et couches), le second monte d'un cran jusqu'à être unique.
static func _build_all() -> void:
	var ids: Array = GameData.spells().keys()
	ids.sort()
	var used: Dictionary = {}
	for id in ids:
		var bump := 0
		var p := _make(str(id), 0)
		while used.has(_sig(p)) and bump < 40:
			bump += 1
			p = _make(str(id), bump)
		used[_sig(p)] = true
		_cache[str(id)] = p


static func _sig(p: Dictionary) -> String:
	return "%s|%s|%d|%s|%s|%s|%s" % [p["fam"], p["accent"], roundi(float(p["pitch"]) * 1000.0), p["sweet"], p["grand"], p["forbidden"], p["kind"]]


static func _make(id: String, bump: int) -> Dictionary:
	var sp: Dictionary = GameData.spells().get(id, {})
	var fam := family_of(sp)
	var elem := str(sp.get("element", ""))
	var accent := ""
	var ef := str(ELEM.get(elem, ""))
	if ef != "" and ef != fam and elem != "physique" and not (fam in ["sacre", "soin", "anges", "purif", "justice"] and elem == "lumiere") \
			and not (fam in ["malefice", "ames", "morts", "sang", "os", "spectre"] and elem == "ombre") and not (fam == "tempete" and elem == "foudre") \
			and not (fam == "poison" and elem == "nature"):
		accent = ef
	var rank := str(sp.get("rank", "apprenti"))
	var h := absi(hash(id)) + bump * 7
	# Variation propre au sort : 13 crans de 1,5 % autour de la hauteur du rang, et une couche d'attaque.
	var pitch := float(RANK_PITCH.get(rank, 1.0)) * (1.0 + float(h % 13 - 6) * 0.015)
	var sw: Array = SWEET[str(SWEET_GROUP.get(fam, "arme"))]
	return {"fam": fam, "accent": accent, "pitch": pitch, "db": float(RANK_DB.get(rank, 0.0)), "type": str(sp.get("type", "")),
		"sweet": str(sw[(absi(hash(id)) / 13 + bump / 13) % sw.size()]),
		"grand": rank == "archimage", "forbidden": rank == "interdit", "kind": str(sp.get("kind", "")),
		"r": float(sp.get("radius", 1.0)), "big": rank in ["maitre", "archimage", "interdit"]}


static func family_of(sp: Dictionary) -> String:
	var t := str(sp.get("type", ""))
	var disc := str(sp.get("disc", ""))
	if DISC.has(disc) and str(DISC[disc]) != "":
		return str(DISC[disc])
	if TYPE_FAM.has(t) and disc == "":
		return str(TYPE_FAM[t])
	var school := str(sp.get("school", ""))
	if school != "" and ELEM.has(school):
		return str(ELEM[school])
	if school == "terre":
		return "terre"
	var elem := str(sp.get("element", ""))
	var cls := str(sp.get("grimoire", sp.get("tree_class", "")))
	if elem == "physique" or elem == "":
		if TYPE_FAM.has(t):
			return str(TYPE_FAM[t])
		return str(CLASS_PHYS.get(cls, "terre"))
	return str(ELEM.get(elem, "arcane"))


## Sons qu'un sort peut jouer (préchargement en début de combat, contrôles).
static func sounds_of(id: String) -> Array[String]:
	var p := profile(id)
	var fam := str(p["fam"])
	var out: Array[String] = [fam + "_cast", fam + "_hit", fam + "_boom", fam + "_loop"]
	if fam in HAS_PROJ:
		out.append(fam + "_proj")
	if str(p["accent"]) != "":
		out.append(str(p["accent"]) + "_hit")
	if str(p["sweet"]) != "":
		out.append(str(p["sweet"]))
	if bool(p["grand"]):
		out.append("grand_cast")
	if bool(p["forbidden"]):
		out.append("forbidden")
	if str(p["type"]) == "army":
		out.append("summon_" + str(SUMMON.get(str(p["kind"]), "bones")))
	return out


## Son de projectile d'un sort (boule de feu, flèche, hache…).
static func proj_of(p: Dictionary) -> String:
	var fam := str(p["fam"])
	if fam in HAS_PROJ:
		return fam + "_proj"
	var acc := str(p["accent"])
	if acc in HAS_PROJ:
		return acc + "_proj"
	match fam:
		"astral", "betes", "piege", "poison":
			return "fleche_proj"
		"spectre", "tempete", "garde", "chevalier", "justice":
			return "lame_proj"
		"cri", "clan", "seisme":
			return "hache_proj"
	return "feu_proj" if fam == "feu" else "lame_proj"


## Prévisualisation (Bibliothèque) : le lancement puis l'impact du sort.
static func preview(id: String) -> void:
	var p := profile(id)
	Snd.sfx(str(p["fam"]) + "_cast", -2.0 + float(p["db"]), float(p["pitch"]))
