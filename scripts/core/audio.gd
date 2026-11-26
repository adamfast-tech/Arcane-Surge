extends Node
## Son du jeu (autoload « Audio » ; docs/design/43-audio.md).
## Quatre catégories : Musique (deux lecteurs en fondu enchaîné), Ambiance (couches en boucle), Effets (réserve
## de lecteurs, limite par son et anti-rafale) et Voix (babillage des personnages).
## Tout passe par le seul bus Master : sur le web, des bus créés en cours de route ne sont pas raccordés à la
## sortie (silence complet). Le volume de chaque catégorie (Options) s'applique donc à chaque lecteur : son
## niveau de base (fondus compris) plus le réglage de sa catégorie et le général.
## Les sons sont des OGG de assets/audio (sfx, music, amb, voice), générés par tools/audio. Aucun effet de bus :
## tout est « cuit » dans les fichiers.

const CATS := ["music", "sfx", "voice", "amb"]
const POOL := 28
const MAX_SAME := 3 ## un même son ne joue pas plus de 3 fois à la fois

var played: Array[String] = [] ## journal des derniers sons (tests)
var muted_reason := "" ## non vide : le son est coupé (« options »)

var _cache: Dictionary = {}
var _missing: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last: Dictionary = {} ## nom -> instant du dernier départ
var _music: Array[AudioStreamPlayer] = []
var _music_name := ""
var _music_cur := 0
var _music_db := 0.0
var _amb: Dictionary = {} ## nom -> lecteur
var _fades: Array[Dictionary] = []
var _timed: Array[Dictionary] = []
var _voice: Array[AudioStreamPlayer] = []
var _voice_next := 0
var _t := 0.0
var _duck := 0.0 ## atténuation de la musique (dB, négatif), qui revient doucement
var _off: Dictionary = {"music": 0.0, "sfx": 0.0, "voice": 0.0, "amb": 0.0} ## réglage de chaque catégorie (dB)
var _live: Array[AudioStreamPlayer] = [] ## tous les lecteurs (pour réappliquer les volumes)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL):
		_pool.append(_player("sfx"))
	for i in range(2):
		var m := _player("music")
		m.set_meta("base", -80.0)
		_music.append(m)
	for i in range(3):
		_voice.append(_player("voice"))
	apply_volumes()


func _player(cat: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.set_meta("cat", cat)
	p.set_meta("base", 0.0)
	add_child(p)
	_live.append(p)
	return p


## Volumes du profil (0 à 1) : général × catégorie, « son coupé » = silence ; appliqués tout de suite.
func apply_volumes() -> void:
	var master := Profile.audio_vol("master") if Profile.sound_on() else 0.0
	for c in CATS:
		var v := master * Profile.audio_vol(str(c))
		_off[c] = linear_to_db(v) if v > 0.001 else -80.0
	for p in _live:
		if is_instance_valid(p):
			_apply(p)


## Volume réel d'un lecteur : son niveau de base + le réglage de sa catégorie (+ l'atténuation de la musique).
func _apply(p: AudioStreamPlayer) -> void:
	var cat := str(p.get_meta("cat", "sfx"))
	var db := float(p.get_meta("base", 0.0)) + float(_off.get(cat, 0.0))
	if cat == "music":
		db += _duck
	p.volume_db = maxf(-80.0, db)


func _set_base(p: AudioStreamPlayer, db: float) -> void:
	p.set_meta("base", db)
	_apply(p)


# ---------------------------------------------------------------- flux

## Flux d'un son (« sfx/feu_cast », « music/zone1 »…), chargé une fois. Nul s'il n'existe pas.
func stream(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var full := "res://assets/audio/%s.ogg" % path
	var s: AudioStream = null
	if ResourceLoader.exists(full):
		s = load(full)
	elif not _missing.has(path):
		_missing[path] = true
		push_warning("Audio : son absent " + full)
	_cache[path] = s
	return s


func has(path: String) -> bool:
	return stream(path) != null


## Charge d'avance une liste de sons (début de combat, de scène) : pas d'à-coup au premier coup.
func preload_list(paths: Array) -> void:
	for p in paths:
		stream(str(p))


# ---------------------------------------------------------------- effets

## Joue un effet. « gap » : intervalle minimal entre deux départs de ce son (anti-rafale).
func sfx(name: String, vol_db: float = 0.0, pitch: float = 1.0, gap: float = 0.0) -> AudioStreamPlayer:
	if name == "":
		return null
	if gap > 0.0 and _t - float(_last.get(name, -99.0)) < gap:
		return null
	var s := stream("sfx/" + name)
	if s == null:
		return null
	var same := 0
	for p in _pool:
		if p.playing and p.get_meta("snd", "") == name:
			same += 1
	if same >= MAX_SAME:
		return null
	var pl := _free_player()
	pl.stream = s
	_set_base(pl, vol_db)
	pl.pitch_scale = clampf(pitch, 0.25, 4.0)
	pl.set_meta("snd", name)
	pl.play()
	_last[name] = _t
	_log(name)
	return pl


## Son en boucle pendant « dur » secondes, puis fondu (zones de sorts, tempêtes).
func loop_for(name: String, dur: float, vol_db: float = 0.0, pitch: float = 1.0, fade_in: float = 0.25) -> void:
	var s := stream("sfx/" + name)
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	var pl := _free_player()
	pl.stream = s
	pl.pitch_scale = pitch
	pl.set_meta("snd", name)
	_set_base(pl, -40.0)
	pl.play()
	_fade(pl, -40.0, vol_db, fade_in, false)
	_timed.append({"p": pl, "t": maxf(0.2, dur), "fade": 0.7, "db": vol_db})
	_log(name)


func _free_player() -> AudioStreamPlayer:
	for k in range(POOL):
		var p := _pool[(_next + k) % POOL]
		if not p.playing:
			_next = (_next + k + 1) % POOL
			return p
	# Tous occupés : on reprend le plus ancien.
	var p2 := _pool[_next]
	_next = (_next + 1) % POOL
	p2.stop()
	return p2


# ---------------------------------------------------------------- voix

## Une syllabe de voix (babillage des cinématiques) : tranche « idx » de la bande « voice/<voix> »
## (une syllabe toutes les VOICE_SLOT secondes ; tools/audio/voices.py).
const VOICE_SLOT := 0.6


func voice(name: String, idx: int, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	var s := stream("voice/" + name)
	if s == null:
		return
	var pl := _voice[_voice_next]
	_voice_next = (_voice_next + 1) % _voice.size()
	for tm in _timed.duplicate():
		if tm["p"] == pl:
			_timed.erase(tm)
	for f in _fades.duplicate():
		if f["p"] == pl:
			_fades.erase(f)
	pl.stream = s
	_set_base(pl, vol_db)
	pl.pitch_scale = clampf(pitch, 0.5, 2.0)
	pl.play(float(idx) * VOICE_SLOT)
	_timed.append({"p": pl, "t": (VOICE_SLOT - 0.04) / pl.pitch_scale, "fade": 0.02, "db": vol_db})
	_log("voice/%s_%d" % [name, idx])


# ---------------------------------------------------------------- musique

## Change de musique en fondu enchaîné (même morceau : rien ne change). « » : silence.
func music(name: String, fade: float = 1.6, vol_db: float = 0.0) -> void:
	if name == _music_name:
		_music_db = vol_db
		return
	var old := _music[_music_cur]
	if old.playing:
		_fade(old, float(old.get_meta("base", 0.0)), -60.0, fade, true)
	_music_name = name
	_music_db = vol_db
	if name == "":
		return
	var s := stream("music/" + name)
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	_music_cur = 1 - _music_cur
	var m := _music[_music_cur]
	m.stream = s
	_set_base(m, -50.0)
	m.play()
	_fade(m, -50.0, vol_db, fade, false)
	_log("music/" + name)


func music_name() -> String:
	return _music_name


## Atténue la musique un moment (fanfare de victoire, grand sort, réplique importante).
func duck(db: float) -> void:
	_duck = minf(_duck, db)


# ---------------------------------------------------------------- ambiances

## Couches d'ambiance en boucle : {nom: volume dB}. Les couches absentes s'éteignent en fondu.
func ambience(layers: Dictionary, fade: float = 1.5) -> void:
	for n in _amb.keys():
		if not layers.has(n):
			var p: AudioStreamPlayer = _amb[n]
			_fade(p, float(p.get_meta("base", 0.0)), -60.0, fade, true)
			_amb.erase(n)
	for n in layers.keys():
		var db := float(layers[n])
		if _amb.has(n):
			var p2: AudioStreamPlayer = _amb[n]
			_fade(p2, float(p2.get_meta("base", 0.0)), db, fade, false)
			continue
		var s := stream("amb/" + str(n))
		if s == null:
			continue
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		var pl := _player("amb")
		pl.stream = s
		_set_base(pl, -50.0)
		pl.play(randf() * maxf(0.0, s.get_length() - 0.5))
		_fade(pl, -50.0, db, fade, false)
		_amb[n] = pl
		_log("amb/" + str(n))


func stop_all(fade: float = 0.6) -> void:
	music("", fade)
	ambience({}, fade)


# ---------------------------------------------------------------- temps

func _fade(p: AudioStreamPlayer, from_db: float, to_db: float, dur: float, stop_after: bool) -> void:
	for f in _fades:
		if f["p"] == p:
			_fades.erase(f)
			break
	_fades.append({"p": p, "a": from_db, "b": to_db, "t": 0.0, "d": maxf(0.01, dur), "stop": stop_after})


func _process(delta: float) -> void:
	_t += delta
	for f in _fades.duplicate():
		var p: AudioStreamPlayer = f["p"]
		if not is_instance_valid(p):
			_fades.erase(f)
			continue
		f["t"] = float(f["t"]) + delta
		var u := clampf(float(f["t"]) / float(f["d"]), 0.0, 1.0)
		# Fondu en puissance (dB interpolés) : naturel à l'oreille.
		_set_base(p, lerpf(float(f["a"]), float(f["b"]), u))
		if u >= 1.0:
			_fades.erase(f)
			if bool(f["stop"]):
				p.stop()
				if str(p.get_meta("cat", "")) == "amb" and not _amb.values().has(p):
					_live.erase(p)
					p.queue_free()
	for tm in _timed.duplicate():
		tm["t"] = float(tm["t"]) - delta
		if float(tm["t"]) <= 0.0:
			_timed.erase(tm)
			var p3: AudioStreamPlayer = tm["p"]
			if is_instance_valid(p3) and p3.playing:
				_fade(p3, float(p3.get_meta("base", 0.0)), -50.0, float(tm["fade"]), true)
	# Atténuation de la musique : revient en 1,5 s environ.
	if _duck < 0.0:
		_duck = minf(0.0, _duck + delta * 6.0)
	var m := _music[_music_cur]
	if m.playing and not _is_fading(m):
		_set_base(m, _music_db)
	for mm in _music:
		if mm.playing:
			_apply(mm)


func _is_fading(p: AudioStreamPlayer) -> bool:
	for f in _fades:
		if f["p"] == p:
			return true
	return false


func _log(name: String) -> void:
	played.append(name)
	if played.size() > 400:
		played = played.slice(200)
