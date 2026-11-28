class_name VoiceBabble
extends RefCounted
## Babillage des personnages (docs/design/43-audio.md), à la « Animal Crossing », dans le style de l'Ancien Tobin :
## pendant qu'une réplique s'écrit, chaque lettre déclenche une courte syllabe de la voix du personnage
## (assets/audio/voice/<voix>.ogg, tools/audio/voices.py) choisie d'après la lettre (« b » -> « ba », « i » -> « i »…),
## si bien qu'un même mot sonne toujours pareil. Débit vif pour les gens, lent et grave pour les grandes créatures ;
## plus aiguë quand le personnage est joyeux ou surpris, plus grave quand il est triste ; la fin d'une question monte,
## la fin d'une phrase descend, une exclamation sonne plus fort. Le narrateur n'a pas de voix : on entend sa plume.

const N_SYL := 22
## Lettre -> syllabe de la bande (même ordre que SYLS dans tools/audio/voices.py).
const LETTER := {"a": 0, "à": 0, "â": 0, "e": 1, "é": 1, "è": 1, "ê": 1, "ë": 1, "i": 2, "î": 2, "ï": 2, "y": 2, "o": 3, "ô": 3,
	"u": 4, "ù": 4, "û": 4, "b": 5, "p": 6, "d": 7, "t": 8, "c": 9, "k": 9, "q": 9, "g": 10, "m": 11, "n": 12, "l": 13, "r": 14,
	"s": 15, "ç": 15, "f": 16, "j": 17, "h": 18, "w": 19, "z": 20, "x": 20, "v": 21}
## Voix propres ; les autres personnages empruntent une voix proche (ou celle du héros).
const VOICES := ["porteur", "brann", "sylwen", "nyx", "krag", "ignara", "ssareth", "ysolde", "thalren", "orrin", "prevote",
	"aurele", "ancien", "voix", "vesper", "sphinx", "durgan", "fee", "varg", "sylvarche", "gharok", "mere_dragon", "cerf",
	"corvin", "leviathan", "wyrm", "ourdisseur", "morvaen", "narrateur"]
## Débit (secondes entre deux syllabes) : vif pour les gens, lent pour les grandes créatures.
const GAP := {"sylvarche": 0.2, "cerf": 0.2, "leviathan": 0.22, "wyrm": 0.19, "mere_dragon": 0.17, "ourdisseur": 0.15,
	"gharok": 0.12, "sphinx": 0.11, "voix": 0.1, "orrin": 0.1, "varg": 0.09, "fee": 0.05, "narrateur": 0.16}
const DEFAULT_GAP := 0.068
const MOOD_PITCH := {"joie": 1.07, "surpris": 1.12, "triste": 0.93, "colere": 1.02}
## Le héros : sa voix suit sa race (hauteur).
const RACE_PITCH := {"humain": 1.0, "elfe": 1.08, "nain": 0.86, "orc": 0.8, "fee": 1.45, "draconique": 0.9, "reptilien": 0.95, "revenant": 0.92}

var _voice := ""
var _pitch := 1.0
var _db := -4.0
var _gap := DEFAULT_GAP
var _acc := 0.0
var _last := -1
var _text := ""
var _beat := 9.0 ## temps depuis la dernière syllabe (bouche du portrait)


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
	_db = -16.0 if _voice == "narrateur" else (-2.0 if mood == "colere" else -4.0)
	_gap = float(GAP.get(_voice, DEFAULT_GAP))
	_acc = _gap
	_last = -1
	_beat = 9.0


static func voice_of(who: String) -> String:
	if who in VOICES:
		return who
	if who in ["", "narrateur"]:
		return "narrateur"
	return "porteur"


## Syllabe d'une lettre (-1 : pas de syllabe, la voix respire).
static func syllable_of(ch: String) -> int:
	return int(LETTER.get(ch.to_lower(), -1))


## Appelé à chaque image pendant que le texte s'écrit : « shown » lettres sont visibles.
func tick(delta: float, shown: int) -> void:
	_beat += delta
	if _voice == "" or _text.is_empty():
		return
	_acc += delta
	if _acc < _gap:
		return
	var i := clampi(shown - 1, 0, _text.length() - 1)
	var k := syllable_of(_text[i])
	if k < 0:
		return
	_acc = 0.0
	_beat = 0.0
	# Deux fois la même syllabe de suite : la voisine, pour garder le rebond du babillage.
	if k == _last:
		k = (k + 1) % N_SYL
	_last = k
	var p := _pitch * randf_range(0.97, 1.04)
	var db := _db
	# Intonation : la fin d'une phrase descend, une question monte, une exclamation sonne plus fort.
	var end := _sentence_end(i)
	if end == "?":
		p *= 1.0 + 0.12 * _closeness(i)
	elif end == ".":
		p *= 1.0 - 0.07 * _closeness(i)
	elif end == "!":
		db += 2.0
		p *= 1.03
	Snd.voice(_voice, k, db, p)


## Ponctuation qui termine la phrase en cours (« », « . », « ? », « ! »).
func _sentence_end(i: int) -> String:
	for j in range(i, mini(_text.length(), i + 40)):
		var c := _text[j]
		if c in [".", "?", "!", "…"]:
			return "." if c == "…" else c
	return ""


## 1 sur les dernières lettres avant la ponctuation, 0 plus loin.
func _closeness(i: int) -> float:
	for j in range(i, mini(_text.length(), i + 8)):
		if _text[j] in [".", "?", "!", "…"]:
			return 1.0 - float(j - i) / 8.0
	return 0.0


## Bouche du portrait, au rythme des syllabes : grande ouverte sur la syllabe, entrouverte, puis fermée.
func mouth() -> int:
	if _voice == "narrateur" or _voice == "":
		return 0
	var open := minf(0.05, _gap * 0.45)
	if _beat < open:
		return 2
	if _beat < _gap * 0.85:
		return 1
	return 0
