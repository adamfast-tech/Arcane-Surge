class_name CineAudio
extends RefCounted
## Son des cinématiques (docs/design/43-audio.md) : musique selon l'humeur de la scène, un son pour chaque effet mis en scène
## (éclair, pluie, ombre d'ailes, cloche, chaînes brisées…), pour les gestes (coup, chute, sort) et les cris
## des créatures, et le babillage de chaque personnage pendant que sa réplique s'écrit (VoiceBabble).

## Humeur du décor -> musique de fond.
const MOOD_MUSIC := {"mist": "cine_calm", "moon": "cine_calm", "dawn": "cine_calm", "arcane": "cine_mystery", "steppe": "cine_calm",
	"campfire": "cine_calm", "swamp": "cine_mystery", "snow": "cine_calm", "forge": "cine_tension", "desert": "cine_calm",
	"cinder": "cine_tension", "abyss": "cine_mystery"}
## Étalonnage d'une réplique -> musique (les changements forts seulement).
const GRADE_MUSIC := {"red": "cine_tension", "dark": "cine_tension", "violet": "cine_mystery", "gold": "cine_heroic",
	"dawn": "cine_calm"}
## Effet mis en scène -> [son, volume dB].
const FX := {
	"white": ["lumiere_hit", -4.0], "flash": ["sw_spark", -6.0], "bloom": ["sw_spark", -10.0], "lightning": ["thunder", -2.0],
	"bolt": ["foudre_hit", -3.0], "crack": ["ombre_hit", -4.0], "rays": ["lumiere_cast", -8.0], "beam": ["beam", -5.0],
	"ring": ["sw_air", -10.0], "shock": ["terre_hit", -5.0], "seal": ["sacre_cast", -5.0], "spiral": ["arcane_cast", -5.0],
	"flux": ["arcane_cast", -7.0], "gate": ["forteresse_cast", -6.0], "arrow": ["fleche_cast", -4.0], "swarm": ["sw_air", -8.0],
	"clang": ["garde_hit", -4.0], "thorns": ["nature_hit", -5.0], "glitter": ["sw_spark", -8.0], "drip": ["sw_glass", -10.0],
	"hooves": ["chevalier_boom", -6.0], "timestop": ["sw_glass", -4.0], "wind": ["wave_swoosh", -7.0], "veins": ["malefice_cast", -7.0],
	"fountain": ["wave_crash", -6.0], "heartbeat": ["barrier_low", -4.0], "willo": ["sw_spark", -9.0], "cage": ["nature_cast", -6.0],
	"shatter": ["givre_boom", -3.0], "roots": ["nature_boom", -5.0], "splinters": ["rubble", -6.0], "renewal": ["nature_cast", -7.0],
	"slash": ["lame_hit", -4.0], "wisps": ["ames_hit", -8.0], "charge": ["arcane_cast", -8.0], "burst": ["arcane_hit", -6.0],
	"dust": ["rubble", -10.0],
	"arcs": ["foudre_cast", -6.0], "shieldwall": ["garde_cast", -4.0], "howl": ["roar_wolf", -4.0], "drums": ["clan_cast", -3.0],
	"banners": ["chevalier_cast", -10.0], "pact": ["soin_cast", -5.0], "shadow": ["ombre_cast", -7.0], "coins": ["ui_coin", -4.0],
	"chant": ["anges_cast", -6.0], "sigils": ["malefice_cast", -6.0], "cheer": ["rally_horn", -6.0], "bars": ["piege_hit", -5.0],
	"bubbles": ["poison_cast", -9.0], "fogbank": ["wave_swoosh", -10.0], "ripples": ["sw_glass", -10.0], "bonerise": ["summon_bones", -4.0],
	"chains": ["piege_cast", -6.0], "jaws": ["hache_hit", -3.0], "ashring": ["feu_cast", -6.0], "heads": ["roar_hydra", -3.0],
	"moths": ["sw_air", -10.0], "whispers": ["sw_whisper", -5.0],
	"blizzard": ["givre_cast", -6.0], "avalanche": ["avalanche", -3.0], "icecrack": ["givre_hit", -4.0], "runes": ["arcane_cast", -6.0],
	"anvil": ["ui_anvil", -2.0], "aurora": ["astral_cast", -8.0], "breath": ["sw_air", -12.0], "doors": ["forteresse_hit", -4.0],
	"spectral": ["ames_cast", -6.0],
	"sandstorm": ["wave_swoosh", -5.0], "mirage": ["arcane_cast", -8.0], "glint": ["sw_spark", -9.0], "sundisk": ["lumiere_boom", -5.0],
	"hourglass": ["sw_glass", -6.0], "riddle": ["astral_cast", -6.0], "pages": ["ui_page", -4.0],
	"firewall": ["wildfire", -3.0], "wingshadow": ["dragon_pass", -2.0], "lavaflow": ["terre_cast", -5.0], "eggglow": ["barrier_low", -5.0],
	"phoenix": ["roar_phoenix", -4.0], "wyrmmark": ["malefice_cast", -5.0], "dragonfire": ["feu_boom", -2.0], "ashswirl": ["purif_cast", -6.0],
	"current": ["wave_swoosh", -6.0], "tide": ["whirlpool", -5.0], "tentacles": ["tentacle", -2.0], "ink": ["ombre_cast", -6.0],
	"song": ["ames_cast", -5.0], "threads": ["astral_cast", -6.0], "bellring": ["gong_day", -2.0], "nacre": ["shield_up", -5.0],
	"blacktide": ["malefice_hit", -5.0],
}
## Gestes des personnages (bustes) -> son.
const ACT := {"attack": ["lame_hit", -6.0], "hurt": ["hit_1", -4.0], "fall": ["die_0", -4.0], "cast": ["arcane_cast", -9.0],
	"glow": ["sw_spark", -9.0], "echo": ["sw_glass", -7.0], "kneel": ["sw_air", -14.0], "enter": ["sw_air", -12.0]}
## Sujet (sprite d'unité ou portrait) -> cri.
const CREATURE := {"cerf": "stag", "stag": "stag", "sylvarche": "tree", "mere_dragon": "dragon", "wyrm": "wyrm", "ash_wyrm": "wyrm",
	"leviathan": "sea", "sphinx": "sphinx", "glass_sphinx": "sphinx", "gharok": "orc", "varg": "beast", "fee": "small", "pixie": "small"}

var _music := ""
var _music_t := -99.0
var _t := 0.0


## Début de scène : musique de son humeur.
func scene(plate_mood: String, _art: String) -> void:
	_set_music(str(MOOD_MUSIC.get(plate_mood, "cine_calm")), true)


## Changement de décor au milieu d'une scène (la musique suit l'étalonnage des répliques).
func plate(_plate_mood: String) -> void:
	pass


func _set_music(name: String, force: bool = false) -> void:
	if name == _music:
		return
	if not force and _t - _music_t < 10.0:
		return
	_music = name
	_music_t = _t
	Snd.music(name, 2.5, -5.0)


## Indications d'une réplique : effets, gestes, cris, étalonnage, carton-titre.
func cues(l: Dictionary, stage: CineStage) -> void:
	for f in _list(l.get("fx", [])):
		var kind := str(f).get_slice(":", 0).get_slice("@", 0)
		if FX.has(kind):
			var fx: Array = FX[kind]
			Snd.sfx(str(fx[0]), float(fx[1]), randf_range(0.96, 1.04), 0.15)
	var acts: Dictionary = l.get("act", {}) if l.get("act") is Dictionary else {}
	for who in acts.keys():
		var what := str(acts[who])
		if str(who) == "subject":
			_subject_act(what, stage)
		elif ACT.has(what):
			var ac: Array = ACT[what]
			Snd.sfx(str(ac[0]), float(ac[1]), randf_range(0.95, 1.05), 0.2)
	var em: Dictionary = l.get("emote", {}) if l.get("emote") is Dictionary else {}
	for who2 in em.keys():
		if str(em[who2]) == "!":
			Snd.sfx("sw_ping", -14.0, 1.4, 0.3)
		elif str(em[who2]) == "note":
			Snd.sfx("ui_confirm", -12.0, 1.1, 0.3)
	if l.has("grade") and GRADE_MUSIC.has(str(l["grade"])):
		_set_music(str(GRADE_MUSIC[str(l["grade"])]))
	if l.has("title"):
		_set_music("cine_heroic", true)
		Snd.sfx("level_up", -6.0)


func _subject_act(what: String, stage: CineStage) -> void:
	var pres: Dictionary = stage.get("_pres")
	var name := str(pres.get("pid", "")) if str(pres.get("pid", "")) != "" else str(pres.get("name", ""))
	var cr := str(CREATURE.get(name, BattleAudio.ROAR.get(name, "beast")))
	match what:
		"roar":
			Snd.sfx("roar_" + cr, -3.0, randf_range(0.95, 1.05), 0.8)
		"hit":
			Snd.sfx("hit_%d" % (randi() % 3), -3.0, 0.8, 0.2)
		"fall":
			Snd.sfx("roar_" + cr, -6.0, 0.82, 0.8)
			Snd.sfx("rubble", -6.0, 0.8, 0.5)
		"appear", "rise":
			Snd.sfx("summon_rise", -6.0, 0.9, 0.5)
		"fade":
			Snd.sfx("ames_hit", -8.0, 1.0, 0.5)
		"glow":
			Snd.sfx("sw_spark", -8.0, 1.0, 0.4)


func tick(delta: float) -> void:
	_t += delta


## Fin des cinématiques : on laisse la place à l'écran suivant.
func finish() -> void:
	pass


static func _list(v: Variant) -> Array:
	if v is Array:
		return v
	if v is String and str(v) != "":
		return [v]
	return []
