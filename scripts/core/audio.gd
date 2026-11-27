extends Node
## Son du jeu (autoload « Audio » ; docs/design/43-audio.md).
## Trois catégories : Musique (deux lecteurs en fondu enchaîné), Effets (réserve de lecteurs, limite par son et
## anti-rafale) et Voix (babillage des personnages).
## Sur le web, la sortie reste coupée jusqu'à ce que la sauvegarde soit chargée (volumes du joueur en place)
## et que le navigateur laisse jouer le son ; elle s'ouvre alors en fondu. Le navigateur peut exiger un premier
## geste du joueur (règle des navigateurs mobiles) : une bulle discrète le dit, et n'importe quel toucher suffit.
## Tout passe par le seul bus Master : sur le web, des bus créés en cours de route ne sont pas raccordés à la
## sortie (silence complet). Le volume de chaque catégorie (Options) s'applique donc à chaque lecteur : son
## niveau de base (fondus compris) plus le réglage de sa catégorie et le général.
## Les sons sont des OGG de assets/audio (sfx, music, voice), générés par tools/audio. Aucun effet de bus :
## tout est « cuit » dans les fichiers.

const CATS := ["music", "sfx", "voice"]
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
var _fades: Array[Dictionary] = []
var _timed: Array[Dictionary] = []
var _voice: Array[AudioStreamPlayer] = []
var _voice_next := 0
var _t := 0.0
var _duck := 0.0 ## atténuation de la musique (dB, négatif), qui revient doucement
var _off: Dictionary = {"music": 0.0, "sfx": 0.0, "voice": 0.0} ## réglage de chaque catégorie (dB)
var _live: Array[AudioStreamPlayer] = [] ## tous les lecteurs (pour réappliquer les volumes)
var _applied := "" ## réglages de son appliqués (empreinte)
var _sync_t := 0.0
var _locked := false ## web : sortie coupée (sauvegarde pas encore chargée, ou son bloqué par le navigateur)
var _profile_ok := false ## la sauvegarde est chargée : les volumes du joueur sont en place
var _gesture := false ## un geste du joueur a été vu
var _poll_t := 0.0
var _resume_tries := 0
var _ready_t := -1.0 ## petit délai avant l'ouverture, le temps que le navigateur relance le son
var _blocked_t := 0.0 ## temps passé bloqué par le navigateur, sauvegarde chargée
var _open_t := -1.0 ## fondu d'ouverture de la sortie (s écoulées), -1 : aucun
var _hint: CanvasLayer

const OPEN_FADE := 0.8


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
	if OS.has_feature("web"):
		_locked = true
		AudioServer.set_bus_volume_db(0, -80.0)


## La sauvegarde est chargée (main) : ses volumes s'appliquent, et le son peut s'ouvrir.
func profile_loaded() -> void:
	_profile_ok = true
	apply_volumes()


## Premier geste du joueur (toucher, clic, touche) : on demande au navigateur de relancer le son.
func _input(e: InputEvent) -> void:
	if not _locked or _gesture:
		return
	if (e is InputEventMouseButton and (e as InputEventMouseButton).pressed) or (e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed) \
			or (e is InputEventKey and (e as InputEventKey).pressed):
		_gesture = true
		_ctx_state(true)
		_poll_t = 0.0


## État du son du navigateur : « running », « suspended »… ou « none » si on ne le connaît pas (la page
## l'expose par html/head_include, voir export_presets.cfg).
func _ctx_state(try_resume: bool) -> String:
	if not OS.has_feature("web"):
		return "running"
	var js := "(function(){var a=window.__actxs||[];if(!a.length)return 'none';var c=a[a.length-1];%sreturn c.state;})()" \
		% ("if(c.state!=='running'){try{c.resume();}catch(e){}}" if try_resume else "")
	return str(JavaScriptBridge.eval(js, true))


## Le navigateur a-t-il déjà vu un geste du joueur ?
func _activated() -> bool:
	return bool(JavaScriptBridge.eval("(navigator.userActivation ? navigator.userActivation.hasBeenActive : false)", true))


## Web : la sortie s'ouvre dès que la sauvegarde est chargée et que le navigateur laisse jouer le son.
func _gate(delta: float) -> void:
	if _ready_t >= 0.0:
		_ready_t -= delta
		if _ready_t <= 0.0:
			_unlock()
		return
	if not _profile_ok:
		return
	_poll_t -= delta
	if _poll_t > 0.0:
		return
	_poll_t = 0.2
	var st := _ctx_state(_resume_tries < 2)
	_resume_tries += 1
	if st == "running" or (st == "none" and (_gesture or _activated())):
		_ready_t = 0.12
		return
	_blocked_t += 0.2
	if _blocked_t >= 0.8 and _hint == null:
		_show_hint()


## Ouvre la sortie en fondu ; une musique lancée pendant l'attente repart de son début.
func _unlock() -> void:
	_locked = false
	_open_t = 0.0
	var m := _music[_music_cur]
	if m.playing:
		m.play(0.0)
		_set_base(m, -50.0)
		_fade(m, -50.0, _music_db, 1.4, false)
	for p in _pool:
		p.stop()
	for v in _voice:
		v.stop()
	if _hint != null:
		var h := _hint
		_hint = null
		var tw := create_tween()
		tw.tween_property(h.get_child(0), "modulate:a", 0.0, 0.4)
		tw.tween_callback(h.queue_free)


## Bulle discrète en haut de l'écran : le navigateur attend un toucher pour laisser jouer le son.
func _show_hint() -> void:
	_hint = CanvasLayer.new()
	_hint.layer = 120
	add_child(_hint)
	var root := Control.new()
	root.theme = UiTheme.build()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.modulate.a = 0.0
	_hint.add_child(root)
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	box.offset_top = 158.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_theme_stylebox_override("panel", UiTheme.box(Color(0.03, 0.05, 0.09, 0.92), Color(UiTheme.TEAL, 0.7), 18, 1, 10))
	box.add_child(pc)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(h)
	h.add_child(UiTheme.icon_rect("sound", 20, UiTheme.TEAL))
	h.add_child(UiTheme.label("Touche l'écran pour activer le son", 16, UiTheme.TEXT))
	create_tween().tween_property(root, "modulate:a", 1.0, 0.4)


func _player(cat: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.set_meta("cat", cat)
	p.set_meta("base", 0.0)
	add_child(p)
	_live.append(p)
	return p


## Volumes du profil (0 à 1) : général × catégorie, « son coupé » = silence ; appliqués tout de suite.
func apply_volumes() -> void:
	_applied = _vol_key()
	var master := Profile.audio_vol("master") if Profile.sound_on() else 0.0
	for c in CATS:
		var v := master * Profile.audio_vol(str(c))
		_off[c] = linear_to_db(v) if v > 0.001 else -80.0
	for p in _live:
		if is_instance_valid(p):
			_apply(p)


## Empreinte des réglages de son du profil (pour savoir s'ils ont changé).
func _vol_key() -> String:
	var k := "1" if Profile.sound_on() else "0"
	for c in ["master"] + CATS:
		k += "|%.2f" % Profile.audio_vol(str(c))
	return k


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


func stop_all(fade: float = 0.6) -> void:
	music("", fade)


# ---------------------------------------------------------------- temps

func _fade(p: AudioStreamPlayer, from_db: float, to_db: float, dur: float, stop_after: bool) -> void:
	for f in _fades:
		if f["p"] == p:
			_fades.erase(f)
			break
	_fades.append({"p": p, "a": from_db, "b": to_db, "t": 0.0, "d": maxf(0.01, dur), "stop": stop_after})


func _process(delta: float) -> void:
	_t += delta
	if _locked:
		_gate(delta)
	elif _open_t >= 0.0:
		_open_t += delta
		var u := clampf(_open_t / OPEN_FADE, 0.0, 1.0)
		AudioServer.set_bus_volume_db(0, lerpf(-50.0, 0.0, u))
		if u >= 1.0:
			_open_t = -1.0
	# Le profil peut être chargé (sauvegarde locale, cloud, configuration) après le démarrage de l'audio :
	# ses volumes sont réappliqués dès qu'ils diffèrent de ceux en place.
	_sync_t -= delta
	if _sync_t <= 0.0:
		_sync_t = 0.5
		var key := _vol_key()
		if key != _applied:
			apply_volumes()
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
