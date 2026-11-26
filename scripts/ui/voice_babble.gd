class_name VoiceBabble
extends RefCounted
## Babillage des personnages (docs/design/43-audio.md) : pendant qu'une réplique s'écrit, une syllabe de la voix
## du personnage (assets/audio/voice/<voix>.ogg, tools/audio/voices.py) part à chaque groupe de lettres.
## Plus aiguë quand il est joyeux ou surpris, plus grave quand il est triste ; la dernière syllabe d'une
## question monte. Le narrateur n'a pas de voix : on entend sa plume.

const N_SYL := 6
## Voix propres ; les autres personnages empruntent une voix proche (ou celle du héros).
const VOICES := ["porteur", "brann", "sylwen", "nyx", "krag", "ignara", "ssareth", "ysolde", "thalren", "orrin", "prevote",
	"aurele", "ancien", "voix", "vesper", "sphinx", "durgan", "fee", "varg", "sylvarche", "gharok", "mere_dragon", "cerf",
	"corvin", "leviathan", "wyrm", "ourdisseur", "morvaen", "narrateur"]
## Débit (secondes entre deux syllabes) : les grandes créatures parlent lentement.
const GAP := {"sylvarche": 0.17, "cerf": 0.17, "leviathan": 0.18, "wyrm": 0.16, "mere_dragon": 0.15, "ourdisseur": 0.15,
	"fee": 0.07, "narrateur": 0.16}
const MOOD_PITCH := {"joie": 1.07, "surpris": 1.12, "triste": 0.93, "colere": 1.02}
## Le héros : sa voix suit sa race (hauteur).
const RACE_PITCH := {"humain": 1.0, "elfe": 1.08, "nain": 0.86, "orc": 0.8, "fee": 1.45, "draconique": 0.9, "reptilien": 0.95, "revenant": 0.92}

var _voice := ""
var _pitch := 1.0
var _db := -6.0
var _gap := 0.1
var _acc := 0.0
var _last := -1
var _question := false
var _text := ""


## Nouvelle réplique.
func start(who: String, mood: String, text: String) -> void:
	_text = text
	_voice = voice_of(who)
	_pitch = float(MOOD_PITCH.get(mood, 1.0))
	if not (who in VOICES) and who not in ["", "narrateur"]:
		# Personnage sans voix propre : celle du héros, à une hauteur qui lui est propre.
		_pitch *= 0.85 + float(absi(hash(who)) % 7) * 0.05
	elif _voice == "porteur":
		_pitch *= float(RACE_PITCH.get(Profile.race(), 1.0))
	_db = -16.0 if _voice == "narrateur" else (-4.0 if mood == "colere" else -6.0)
	_gap = float(GAP.get(_voice, 0.095))
	_acc = _gap
	_question = text.strip_edges().ends_with("?")


static func voice_of(who: String) -> String:
	if who in VOICES:
		return who
	if who in ["", "narrateur"]:
		return "narrateur"
	return "porteur"


## Appelé à chaque image pendant que le texte s'écrit : « shown » lettres sont visibles.
func tick(delta: float, shown: int) -> void:
	if _voice == "":
		return
	_acc += delta
	if _acc < _gap:
		return
	var i := clampi(shown - 1, 0, maxi(0, _text.length() - 1))
	if _text.is_empty():
		return
	var ch := _text[i]
	# Pas de syllabe sur les espaces ni la ponctuation : la voix respire.
	if ch in [" ", ",", ".", "…", "!", "?", ";", ":", "«", "»", "\n", "—", "-"]:
		return
	_acc = 0.0
	var k := randi() % N_SYL
	if k == _last:
		k = (k + 1) % N_SYL
	_last = k
	var p := _pitch * randf_range(0.96, 1.05)
	if _question and shown >= _text.length() - 3:
		p *= 1.12
	Snd.voice(_voice, k, _db, p)
