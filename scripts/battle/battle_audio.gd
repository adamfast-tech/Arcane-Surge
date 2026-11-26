class_name BattleAudio
extends RefCounted
## Son du combat (docs/design/43-audio.md) : musique de la zone (puis du boss), ambiance du lieu (vent, pluie,
## marais, blizzard, incendie, profondeurs), sons de chaque sort (SpellAudio) aux moments de son animation,
## tirs de classe, coups, morts, Barrière, Nexus, attaques annoncées et cris des boss, fin de combat.
## Lit les évènements de la simulation avant l'arène, et compare son état d'une image à l'autre.

const STORM := ["orage", "repaire", "fort"]
const BLIZZARD := ["congeres", "col", "colosse", "aurore"]
const LAVA := ["coulee", "antre", "drake"]
## Genre de boss (ou de créature) -> cri.
const ROAR := {"stag": "stag", "sylvarche": "tree", "varg": "beast", "gharok": "orc", "croc_lich": "undead", "hydra": "hydra",
	"rune_sentinel": "golem", "rune_colossus": "golem", "sun_scarab": "insect", "glass_sphinx": "sphinx", "ancient_drake": "dragon",
	"ash_wyrm": "wyrm", "wyrm_mark": "demon", "young_kraken": "kraken", "leviathan": "sea", "wolf_rider": "wolf", "white_wolf": "wolf",
	"bear": "bear", "yeti": "bear", "ogre": "orc", "magma_golem": "golem", "ice_golem": "golem", "sandstone_golem": "golem",
	"minor_phoenix": "phoenix", "wyvernling": "dragon", "drakonid": "dragon", "ash_demon": "demon", "abyss_horror": "kraken",
	"titan_crab": "insect", "lich": "undead", "wraith": "spirit", "siren": "spirit", "hydra_head": "hydra"}
## Tir de classe -> son.
const SHOT := {"necromancien": "shot_necro", "mage": "shot_mage", "archer": "shot_archer", "epeiste": "shot_epeiste",
	"clerc": "shot_clerc", "chevalier": "shot_chevalier", "berserker": "shot_berserker"}

var sim: BattleSim
var zone := 1
var scene := ""
var _t := 0.0
var _kills := 0
var _allies := 0
var _nexus := 0.0
var _barrier := 0.0
var _phase := -1
var _tele := 0
var _whirl := 0
var _boss_alive := false
var _surge_full := false
var _champ := false
var _sid_t: Dictionary = {} ## (sort, phase) -> dernier départ
var _ended := false
var _thunder_t := 6.0 ## orage : tonnerre lointain de temps en temps


func _init(s: BattleSim, zone_n: int, scene_id: String) -> void:
	sim = s
	zone = zone_n
	scene = scene_id
	_snapshot()


func _snapshot() -> void:
	_kills = sim.kills
	_allies = sim.allies.size()
	_nexus = sim.nexus_hp
	_barrier = sim.barrier_hp
	_phase = sim.boss_phase
	_tele = sim.telegraphs.size()
	_whirl = sim.whirlpools.size()
	_boss_alive = sim.boss != null and sim.boss.alive


## Début du combat : musique, ambiance, sons courants chargés d'avance.
func start() -> void:
	var boss := sim.boss != null
	Snd.music(("boss_%d" % (1 if zone <= 3 else 2)) if boss else "battle_z%d" % clampi(zone, 1, 7), 2.0, -2.0)
	Snd.ambience(ambience_for(zone, scene, sim.is_day), 2.5)
	var pre: Array = ["hit_0", "hit_1", "hit_2", "die_0", "die_1", "die_2", "barrier_hit", "nexus_hit", "portal", "flux", "telegraph"]
	for c in sim.casters:
		pre.append(str(SHOT.get(c.class_id, "shot_mage")))
	Snd.preload_list(pre.map(func(n: Variant) -> String: return "sfx/" + str(n)))


## Couches d'ambiance d'un lieu de combat : {son: volume dB}.
static func ambience_for(z: int, sc: String, day: bool = true) -> Dictionary:
	match z:
		1:
			return {"forest_night": -6.0}
		2:
			if sc in STORM:
				return {"rain": -6.0, "wind_plains": -12.0}
			return {"wind_plains": -8.0}
		3:
			return {"swamp": -6.0}
		4:
			if sc in BLIZZARD:
				return {"blizzard": -6.0}
			return {"wind_snow": -8.0}
		5:
			return {"desert_wind": -8.0} if day else {"desert_night": -8.0}
		6:
			if sc in LAVA:
				return {"lava": -6.0, "fire_forest": -12.0}
			return {"fire_forest": -7.0}
		7:
			return {"underwater": -5.0}
	return {"forest_night": -8.0}


func on_events(events: Array[Dictionary]) -> void:
	for e in events:
		_event(e)


func _event(e: Dictionary) -> void:
	var t := str(e["t"])
	if e.has("sid") and str(e["sid"]) != "":
		_spell(str(e["sid"]), t, e)
		return
	match t:
		"barrier":
			Snd.sfx("barrier_hit", -1.0, randf_range(0.95, 1.05), 0.25)
		"dragon":
			Snd.sfx("dragon_pass", 0.0, randf_range(0.95, 1.05), 0.6)
		"avalanche":
			Snd.sfx("avalanche", 0.0, 1.0, 1.0)
		"shot_fire", "rise", "fireflies":
			var ci := int(e.get("c", 0))
			var cls := sim.casters[ci].class_id if ci >= 0 and ci < sim.casters.size() else "mage"
			Snd.sfx(str(SHOT.get(cls, "shot_mage")), -2.0 if ci == 0 else -7.0, randf_range(0.94, 1.06), 0.05)
		"shot_hit":
			Snd.sfx("shot_light_hit" if str(e.get("shot", "")) == "lumiere" else "shot_hit", -6.0, randf_range(0.9, 1.1), 0.07)
		"shot_shock":
			Snd.sfx("shot_shock", -3.0, randf_range(0.95, 1.05), 0.1)
		"prop_hit":
			Snd.sfx("rubble", -8.0, randf_range(1.1, 1.3), 0.15)
		"prop_fall":
			Snd.sfx("tree_fall", -2.0, 1.0, 0.5)
		"prop_crash", "wall_break":
			Snd.sfx("rubble", -2.0, randf_range(0.9, 1.05), 0.3)
		"wall":
			Snd.sfx("wall_rise", -2.0, 1.0, 0.3)
		"trap":
			Snd.sfx("trap_snap", -3.0, randf_range(0.95, 1.05), 0.1)
		"daynight":
			Snd.sfx("gong_day", -4.0)
			Snd.ambience(ambience_for(zone, scene, bool(e.get("day", true))), 3.0)
		"wave":
			Snd.sfx("wave_crash", -1.0, 1.0, 0.5)
		"strike":
			match str(e.get("kind", "")):
				"tentacle":
					Snd.sfx("tentacle", 0.0, randf_range(0.9, 1.1), 0.2)
				"fire", "dragon":
					Snd.sfx("feu_boom", -2.0, 0.9, 0.2)
				"venom":
					Snd.sfx("poison_boom", -2.0, 1.0, 0.2)
				"wave", "avalanche":
					pass
				_:
					Snd.sfx("terre_hit", -2.0, 0.85, 0.2)
		"summon":
			Snd.sfx("summon_rise", -4.0, 0.9, 0.3)
		"steam":
			Snd.sfx("givre_hit", -6.0, 0.8, 0.3)
		"wind":
			if str(e.get("phase", "")) == "blow":
				Snd.sfx("wave_swoosh", -4.0, 0.6, 1.0)


## Évènement d'un sort : chaque phase de son animation a son son.
func _spell(sid: String, phase: String, e: Dictionary) -> void:
	var p := SpellAudio.profile(sid)
	var fam := str(p["fam"])
	var pit := float(p["pitch"])
	var db := float(p["db"])
	var key := sid + "|" + phase
	if _t - float(_sid_t.get(key, -9.0)) < (0.9 if phase == "puff" else 0.08):
		return
	_sid_t[key] = _t
	var big := bool(e.get("big", false)) or float(e.get("r", p["r"])) >= 2.0 or bool(p["big"])
	match phase:
		"spell":
			Snd.sfx(fam + "_cast", db - 1.0, pit)
			if str(p["sweet"]) != "":
				Snd.sfx(str(p["sweet"]), db - 7.0, pit)
			if bool(p["grand"]):
				Snd.sfx("grand_cast", db - 4.0, pit)
			if bool(p["forbidden"]):
				Snd.sfx("forbidden", db - 2.0, pit)
				Snd.duck(-8.0)
			if bool(e.get("ult", false)):
				Snd.sfx("ultimate", 0.0)
				Snd.duck(-10.0)
			if str(p["type"]) == "rally":
				Snd.sfx("rally_horn", db - 5.0, pit)
		"explosion":
			Snd.sfx(fam + ("_boom" if big else "_hit"), db, pit * randf_range(0.97, 1.03))
			if str(p["accent"]) != "":
				Snd.sfx(str(p["accent"]) + "_hit", db - 7.0, pit)
		"lightning", "bolt":
			Snd.sfx("foudre_hit" if not big else "thunder", db - 1.0, pit)
		"beam":
			Snd.sfx("beam", db - 4.0, pit)
			Snd.sfx(fam + "_hit", db - 5.0, pit)
		"column", "pillar":
			Snd.sfx("wave_swoosh", db - 6.0, pit * 1.2)
			Snd.sfx(fam + ("_boom" if big else "_hit"), db - 1.0, pit)
		"wave", "wind":
			Snd.sfx("wave_swoosh", db - 2.0, pit)
			Snd.sfx(fam + "_hit", db - 5.0, pit)
		"shield":
			Snd.sfx("shield_up", db - 2.0, pit)
		"ring":
			if str(p["type"]) in ["rally", "frenzy", "mirror", "harvest"]:
				Snd.sfx(fam + "_hit", db - 4.0, pit)
		"puff":
			if str(p["type"]) == "army":
				Snd.sfx("summon_" + str(SpellAudio.SUMMON.get(str(p["kind"]), "bones")), db - 1.0, pit)
		"summon":
			Snd.sfx("summon_rise", db - 3.0, pit)
		"quake":
			Snd.sfx("quake", db, pit)
		"ground", "trap":
			Snd.sfx(fam + "_hit", db - 2.0, pit)
		"steam":
			Snd.sfx("givre_hit", db - 4.0, pit)
		_:
			# Projectile (boule de feu, météore, flèche…) ou zone qui dure (pluie, racines, vortex…).
			var dur := float(e.get("dur", 0.0))
			if e.has("from") and e.has("to") and dur <= 2.0:
				Snd.sfx(SpellAudio.proj_of(p), db - 3.0, pit * randf_range(0.96, 1.04), 0.05)
			elif dur > 1.0:
				Snd.sfx(fam + "_hit", db - 2.0, pit)
				Snd.loop_for(fam + "_loop", minf(dur, 12.0), db - 3.0, pit)
			else:
				Snd.sfx(fam + "_hit", db - 3.0, pit)


## Chaque image : coups, morts, Nexus, attaques annoncées, phases et chute du boss, Surge, Champion.
func update(delta: float) -> void:
	_t += delta
	if zone == 2 and scene in STORM:
		_thunder_t -= delta
		if _thunder_t <= 0.0:
			_thunder_t = randf_range(9.0, 22.0)
			Snd.sfx("thunder_far", randf_range(-8.0, -3.0), randf_range(0.85, 1.1))
	if sim.kills > _kills:
		var n := sim.kills - _kills
		Snd.sfx("die_%d" % (randi() % 3), -8.0 + minf(4.0, float(n)), randf_range(0.85, 1.15), 0.09)
		if n > 0:
			Snd.sfx("hit_%d" % (randi() % 3), -10.0, randf_range(0.85, 1.2), 0.06)
	_kills = sim.kills
	if sim.nexus_hp < _nexus - 0.5:
		Snd.sfx("nexus_hit", -6.0, randf_range(0.95, 1.08), 0.18)
	_nexus = sim.nexus_hp
	if sim.barrier_hp < _barrier - 0.5 and sim.barrier_hp < sim.barrier_max * 0.3:
		Snd.sfx("barrier_low", -6.0, 1.0, 1.4)
	_barrier = sim.barrier_hp
	if sim.telegraphs.size() > _tele:
		Snd.sfx("telegraph", -6.0, 1.0, 0.4)
	_tele = sim.telegraphs.size()
	if sim.whirlpools.size() > _whirl:
		Snd.sfx("whirlpool", -2.0, 1.0, 1.0)
	_whirl = sim.whirlpools.size()
	if sim.boss != null:
		var kind := str(sim.boss.kind)
		if sim.boss_phase != _phase and _phase >= 0:
			Snd.sfx("roar_" + str(ROAR.get(kind, "beast")), 0.0, 1.0, 1.0)
			Snd.duck(-6.0)
		if _boss_alive and not sim.boss.alive:
			Snd.sfx("roar_" + str(ROAR.get(kind, "beast")), 0.0, 0.85)
			Snd.sfx("nexus_break", -2.0, 0.9)
		_boss_alive = sim.boss.alive
	_phase = sim.boss_phase
	var surge_full := sim.surge >= 100.0
	if surge_full and not _surge_full:
		Snd.sfx("surge_full", -4.0)
	_surge_full = surge_full


## Fin du combat : fanfare ou complainte, musique coupée.
func end(victory: bool) -> void:
	if _ended:
		return
	_ended = true
	Snd.music("", 0.8)
	Snd.ambience({}, 2.0)
	if victory:
		Snd.sfx("nexus_break", -3.0)
		Snd.sfx("victory", 0.0)
	else:
		Snd.sfx("barrier_break", -2.0)
		Snd.sfx("defeat", -1.0)


## Le premier boss d'une zone fait entendre son cri à son arrivée.
func boss_intro() -> void:
	if sim.boss != null:
		Snd.sfx("roar_" + str(ROAR.get(str(sim.boss.kind), "beast")), -1.0)
