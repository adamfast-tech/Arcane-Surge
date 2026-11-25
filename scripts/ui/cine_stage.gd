class_name CineStage
extends Control
## Mise en scène des dialogues (docs/design/41-cinematiques.md) : une petite « cinématique » par réplique.
## - Caméra sur le décor : lent travelling (zoom et dérive), zooms, panoramiques, secousses.
## - Ambiance animée selon le décor (lumière, brume, lucioles, braises, neige, bulles), éclairs et flashs.
## - Acteurs : les personnages qui parlent apparaissent sur scène (ils entrent, respirent, s'animent en parlant,
##   sautent de surprise, tremblent de colère, s'affaissent de tristesse), et agissent sur indication.
## Indications facultatives d'une réplique : « cam », « fx », « act » (voir play_cues).

## Décor -> ambiance (Ambience.MOODS).
const PLATE_MOOD := {
	"fracture": "arcane", "surge": "arcane", "nexus": "arcane", "college": "arcane", "sphinx": "arcane", "tour": "moon",
	"lysbourg": "dawn", "foret": "mist", "foret_gueri": "dawn", "source": "mist", "pont": "mist", "sylvarche": "arcane", "collines": "dawn",
	"steppe": "steppe", "moulins": "steppe", "campement": "campfire", "orage": "steppe", "traite": "steppe", "fort": "steppe",
	"marais": "swamp", "cercle": "swamp", "hydre": "swamp", "refuge": "campfire",
	"pics": "snow", "porte": "snow", "lac": "snow", "forteresse": "snow", "colosse": "forge", "forge": "forge",
	"dunes": "desert", "oasis": "desert", "miroirs": "desert", "desert_nuit": "moon",
	"cendres": "cinder", "coulee": "cinder", "braisemont": "cinder", "nid": "cinder", "autels": "arcane", "citadelle": "cinder",
	"caldeira": "forge", "antre": "cinder",
	"cite": "abyss", "quais": "abyss", "canal": "abyss", "statues": "abyss", "archives": "arcane", "palais": "abyss", "abysse": "abyss",
}
## Personnages qui ont un sprite d'acteur (le héros : son sprite généré, « player »).
const ACTOR_SPRITE := {"porteur": "player", "brann": "brann", "sylwen": "sylwen", "krag": "krag", "nyx": "nyx", "ignara": "ignara", "ssareth": "ssareth"}
const MAX_ACTORS := 4
## Vocabulaire des indications (vérifié par tools/ui_smoke.gd).
const CAMS := ["zoom", "zoom_out", "reset", "punch", "shake", "tremble", "pan_left", "pan_right", "pan_up"]
const FXS := ["flash", "white", "fade", "lightning", "sparkles", "embers"]
const ACTS := ["jump", "hop", "shake", "hurt", "attack", "droop", "kneel", "glow", "fall", "exit", "enter", "rise"]
const SUBJECT_ACTS := ["roar", "hit", "fall", "glow", "rise"]

var art: TextureRect ## le décor, cadré par la caméra
var subject: TextureRect ## le sujet de la scène (créature, boss)
var ground_y := 600.0 ## ligne du sol des acteurs (pixels de l'écran)
var top_y := 90.0 ## haut de la zone de scène

var _t := 0.0
var _zoom := 1.0
var _zoom_to := 1.0
var _drift_dir := 1.0
var _pan := Vector2.ZERO
var _pan_to := Vector2.ZERO
var _shake := 0.0
var _shake_amp := 10.0
var _punch := 0.0
var _ambient: Ambience
var _mood := ""
var _flash: ColorRect
var _flash_t := 0.0
var _flash_dur := 0.3
var _flash2_t := -1.0 ## second éclair (foudre)
var _actors: Dictionary = {} ## id -> état de l'acteur
var _order: Array[String] = []
var _speaker := ""
var _subject_t := 0.0 ## entrée du sujet
var _subject_act := ""
var _subject_act_t := 0.0
var _burst: CPUParticles2D
var _burst_at := Vector2(-1, -1) ## d'où partent les étincelles (l'acteur qui agit)
var cast_fixed := false ## distribution imposée par la scène (« cast »)
var talking := false ## l'orateur parle (le texte s'écrit)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SpriteAtlas.set_player(Profile.look(), Profile.race(), Profile.player_class())
	_burst = CPUParticles2D.new()
	_burst.emitting = false
	_burst.one_shot = true
	_burst.amount = 40
	_burst.lifetime = 0.9
	_burst.explosiveness = 0.95
	_burst.direction = Vector2(0, -1)
	_burst.spread = 180.0
	_burst.initial_velocity_min = 80.0
	_burst.initial_velocity_max = 260.0
	_burst.gravity = Vector2(0, 180)
	_burst.scale_amount_min = 4.0
	_burst.scale_amount_max = 9.0
	add_child(_burst)


## Le voile de flash vit au-dessus du décor et des acteurs, sous le panneau de texte.
func make_flash_layer() -> ColorRect:
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return _flash


# ---------------------------------------------------------------- scène

## Nouvelle scène : distribution vide (ou imposée), caméra au repos, travelling dans l'autre sens.
func begin_scene(sc: Dictionary) -> void:
	for id in _actors.keys():
		(_actors[id]["rect"] as TextureRect).queue_free()
	_actors.clear()
	_order.clear()
	_speaker = ""
	_zoom = 1.0
	_zoom_to = 1.0
	_pan = Vector2.ZERO
	_pan_to = Vector2.ZERO
	_drift_dir = -_drift_dir
	_t = 0.0
	cast_fixed = sc.has("cast")
	for c in sc.get("cast", []):
		var cd: Dictionary = c if c is Dictionary else {"id": str(c)}
		_add_actor(str(cd["id"]), float(cd.get("x", -1.0)), bool(cd.get("hidden", false)))
	if sc.has("cam"):
		_camera(str(sc["cam"]))


## Décor : son ambiance animée (une seule à la fois).
func set_plate(kind: String) -> void:
	var mood := str(PLATE_MOOD.get(kind, "mist"))
	if mood == _mood and _ambient != null:
		return
	_mood = mood
	if _ambient != null:
		_ambient.queue_free()
		_ambient = null
	if not Profile.ambience_on():
		return
	_ambient = Ambience.new()
	_ambient.mood = mood
	add_child(_ambient)
	move_child(_ambient, 0)


## Nouveau plan (changement de décor) : le travelling repart dans l'autre sens.
func new_shot() -> void:
	_t = 0.0
	_drift_dir = -_drift_dir
	_pan_to = Vector2.ZERO
	_zoom_to = 1.0


## Nouveau sujet : il apparaît en grandissant.
func subject_changed() -> void:
	_subject_t = 0.0
	_subject_act = ""
	_reflow()


# ---------------------------------------------------------------- répliques

## Une réplique commence : l'orateur (s'il a un sprite) entre en scène et joue selon son humeur.
func speak(who: String, mood: String) -> void:
	_speaker = who
	if not ACTOR_SPRITE.has(who):
		return
	if not _actors.has(who):
		if cast_fixed:
			return
		_add_actor(who, -1.0, false)
	var a: Dictionary = _actors[who]
	if bool(a["hidden"]):
		a["hidden"] = false
		a["enter_t"] = 0.0
	match mood:
		"surpris":
			_act(who, "jump")
		"colere":
			_act(who, "shake")
		"joie":
			_act(who, "hop")
		"triste":
			_act(who, "droop")


## Indications de mise en scène d'une réplique :
## « cam » : zoom, zoom_out, punch, shake, tremble, pan_left, pan_right, reset ;
## « fx » : flash, flash:RRGGBB, lightning, fade, sparkles[:RRGGBB], embers, white (ou une liste) ;
## « act » : {qui: action} — jump, hop, shake, attack, hurt, kneel, rise, droop, exit, enter, fall, glow ;
##   « subject » désigne la créature : roar, hit, fall, rise, glow.
func play_cues(l: Dictionary) -> void:
	if l.has("cam"):
		for c in _list(l["cam"]):
			_camera(c)
	_burst_at = Vector2(-1, -1)
	if l.has("act"):
		var acts: Dictionary = l["act"]
		for who in acts.keys():
			var w := Dialogues.resolve_who(str(who))
			if w == "subject":
				_subject_act = str(acts[who])
				_subject_act_t = 0.0
				if subject != null and subject.visible:
					_burst_at = subject.position + subject.size * Vector2(0.5, 0.45)
				if _subject_act == "roar":
					_camera("shake")
			else:
				if not _actors.has(w) and ACTOR_SPRITE.has(w):
					_add_actor(w, -1.0, false)
				_act(w, str(acts[who]))
				if _actors.has(w):
					var r: TextureRect = _actors[w]["rect"]
					_burst_at = Vector2(float(_actors[w]["x"]) * size.x, ground_y - r.size.y * 0.6)
	if l.has("fx"):
		for f in _list(l["fx"]):
			_effect(f)


## Erreurs d'indications d'une réplique ou d'une scène (mots inconnus, acteur sans sprite).
static func check_cues(l: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	for c in _list(l.get("cam", [])):
		if not CAMS.has(c):
			errs.append("cam " + c)
	for f in _list(l.get("fx", [])):
		if not FXS.has(f.get_slice(":", 0)):
			errs.append("fx " + f)
	var acts: Dictionary = l.get("act", {})
	for who in acts.keys():
		var w := str(who)
		var what := str(acts[who])
		if w == "subject":
			if not SUBJECT_ACTS.has(what):
				errs.append("act subject " + what)
		elif not (ACTOR_SPRITE.has(w) or w == "traitre") or not ACTS.has(what):
			errs.append("act %s %s" % [w, what])
	for c in l.get("cast", []):
		var id := str((c as Dictionary).get("id", "")) if c is Dictionary else str(c)
		if not ACTOR_SPRITE.has(id):
			errs.append("cast " + id)
	return errs


static func _list(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if v is Array:
		for x in v:
			out.append(str(x))
	else:
		out.append(str(v))
	return out


func _camera(c: String) -> void:
	match c:
		"zoom":
			_zoom_to = 1.22
		"zoom_out":
			_zoom_to = 0.98
		"reset":
			_zoom_to = 1.0
			_pan_to = Vector2.ZERO
		"punch":
			_punch = 1.0
		"shake":
			_shake = 0.5
			_shake_amp = 12.0
		"tremble":
			_shake = 1.6
			_shake_amp = 4.0
		"pan_left":
			_pan_to = Vector2(size.x * 0.06, 0.0)
		"pan_right":
			_pan_to = Vector2(-size.x * 0.06, 0.0)
		"pan_up":
			_pan_to = Vector2(0.0, size.y * 0.05)


func _effect(f: String) -> void:
	var parts := f.split(":")
	var kind := parts[0]
	var col := Color(parts[1]) if parts.size() > 1 else Color.WHITE
	match kind:
		"flash":
			_flash_on(col, 0.35, 0.8)
		"white":
			_flash_on(Color.WHITE, 0.9, 1.0)
		"fade":
			_flash_on(Color.BLACK, 1.2, 1.0)
		"lightning":
			_flash_on(Color("e8f0ff"), 0.18, 0.9)
			_flash2_t = 0.25
			_camera("shake")
		"sparkles", "embers":
			var c2 := col if parts.size() > 1 else (Color("ffb050") if kind == "embers" else Color("fff3b0"))
			_burst.position = _burst_at if _burst_at.x >= 0.0 else Vector2(size.x * 0.5, top_y + (ground_y - top_y) * 0.45)
			_burst.color = c2
			_burst.gravity = Vector2(0, -60) if kind == "embers" else Vector2(0, 180)
			_burst.restart()
			_burst.emitting = true


func _flash_on(col: Color, dur: float, peak: float) -> void:
	if _flash == null:
		return
	_flash.color = Color(col, peak)
	_flash_dur = dur
	_flash_t = dur


# ---------------------------------------------------------------- acteurs

func _add_actor(id: String, x: float, hidden: bool) -> void:
	if not ACTOR_SPRITE.has(id) or _actors.has(id):
		return
	if _order.size() >= MAX_ACTORS:
		# Plus de place : le plus ancien acteur qui ne parle pas quitte la scène.
		for old in _order:
			if old != _speaker:
				_remove_actor(old)
				break
	var r := TextureRect.new()
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	_order.append(id)
	var slot := x if x >= 0.0 else -1.0
	_actors[id] = {"rect": r, "sprite": str(ACTOR_SPRITE[id]), "x": slot, "cx": -1.0, "hidden": hidden, "enter_t": 0.0,
		"act": "", "act_t": 0.0, "side": -1.0 if _order.size() % 2 == 1 else 1.0}
	_reflow()


func _remove_actor(id: String) -> void:
	if not _actors.has(id):
		return
	(_actors[id]["rect"] as TextureRect).queue_free()
	_actors.erase(id)
	_order.erase(id)
	_reflow()


## Places des acteurs sans position imposée : réparties de gauche à droite dans l'ordre d'arrivée.
func _reflow() -> void:
	var free: Array[String] = []
	for id in _order:
		if float(_actors[id]["x"]) < 0.0 or bool(_actors[id].get("auto", false)):
			_actors[id]["auto"] = true
			free.append(id)
	# Avec une créature au centre, les acteurs se rangent sur les côtés.
	var sides: Array[float] = [0.16, 0.84, 0.3, 0.7]
	var subj := subject != null and subject.visible and subject.texture != null
	for i in range(free.size()):
		_actors[free[i]]["x"] = sides[i] if subj else (float(i) + 1.0) / float(free.size() + 1)


func _act(id: String, what: String) -> void:
	if not _actors.has(id):
		return
	var a: Dictionary = _actors[id]
	match what:
		"exit":
			a["act"] = "exit"
		"enter":
			a["hidden"] = false
			a["enter_t"] = 0.0
		_:
			a["act"] = what
	a["act_t"] = 0.0


# ---------------------------------------------------------------- image par image

func _process(delta: float) -> void:
	_t += delta
	_update_camera(delta)
	_update_actors(delta)
	_update_subject(delta)
	if _flash != null and _flash_t > 0.0:
		_flash_t -= delta
		var k := clampf(_flash_t / maxf(0.01, _flash_dur), 0.0, 1.0)
		_flash.color.a = k * k * (0.9 if _flash.color.v > 0.5 else 1.0)
	if _flash2_t > 0.0:
		_flash2_t -= delta
		if _flash2_t <= 0.0:
			_flash_on(Color("e8f0ff"), 0.22, 0.85)


func _update_camera(delta: float) -> void:
	if art == null:
		return
	_zoom = lerpf(_zoom, _zoom_to, clampf(delta * 1.4, 0.0, 1.0))
	_pan = _pan.lerp(_pan_to, clampf(delta * 1.2, 0.0, 1.0))
	_punch = maxf(0.0, _punch - delta * 3.0)
	var shake_off := Vector2.ZERO
	if _shake > 0.0:
		_shake -= delta
		shake_off = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amp * clampf(_shake * 2.0, 0.0, 1.0)
	# Lent travelling : le décor s'approche doucement et dérive pendant la scène.
	var breath := 1.05 + 0.05 * clampf(_t / 24.0, 0.0, 1.0) + 0.006 * sin(_t * 0.6)
	var s := breath * _zoom * (1.0 + 0.06 * sin(_punch * PI))
	art.pivot_offset = art.size * 0.5
	art.scale = Vector2.ONE * s
	art.position = Vector2(_drift_dir * clampf(_t / 24.0, 0.0, 1.0) * size.x * 0.025, sin(_t * 0.25) * 3.0) + _pan + shake_off


## Taille des acteurs à l'écran : un même multiple entier pour tous (les tailles relatives restent justes).
func _actor_scale() -> float:
	var area := maxf(120.0, ground_y - top_y)
	return clampf(floorf(area * 0.26 / 22.0), 3.0, 9.0)


func _update_actors(delta: float) -> void:
	for id in _order:
		var a: Dictionary = _actors[id]
		var r: TextureRect = a["rect"]
		var speaking := id == _speaker
		var mouth := speaking and talking
		var frame := 0
		if mouth and int(_t * 6.0) % 2 == 1:
			frame = 1
		r.texture = SpriteAtlas.single(str(a["sprite"]), frame)
		if r.texture == null:
			continue
		var tw := float(r.texture.get_width())
		var th := float(r.texture.get_height())
		var k := _actor_scale()
		r.size = Vector2(tw * k, th * k)
		var tx := float(a["x"]) * size.x
		if float(a["cx"]) < 0.0:
			# Entrée : il arrive du bord de son côté.
			a["cx"] = -r.size.x if float(a["side"]) < 0.0 else size.x + r.size.x
		a["cx"] = lerpf(float(a["cx"]), tx, clampf(delta * 4.0, 0.0, 1.0))
		var dx := 0.0
		var dy := 0.0
		var sy := 1.0
		var rot := 0.0
		var alpha := 1.0
		var tint := Color.WHITE
		a["act_t"] = float(a["act_t"]) + delta
		var at := float(a["act_t"])
		match str(a["act"]):
			"jump":
				dy = -absf(sin(clampf(at / 0.4, 0.0, 1.0) * PI)) * k * 5.0
			"hop":
				dy = -absf(sin(clampf(at / 0.6, 0.0, 1.0) * TAU)) * k * 2.5
			"shake":
				dx = sin(at * 60.0) * k * 0.8 * clampf(1.0 - at / 0.5, 0.0, 1.0)
			"hurt":
				dx = sin(at * 50.0) * k * 1.2 * clampf(1.0 - at / 0.4, 0.0, 1.0)
				tint = Color(1.0, 0.5, 0.5).lerp(Color.WHITE, clampf(at / 0.5, 0.0, 1.0))
			"attack":
				var dir := 1.0 if tx < size.x * 0.5 else -1.0
				dx = dir * sin(clampf(at / 0.45, 0.0, 1.0) * PI) * k * 6.0
			"droop", "kneel":
				sy = 0.86 if str(a["act"]) == "kneel" else 0.95
			"glow":
				tint = Color(1.6, 1.6, 1.3).lerp(Color.WHITE, clampf(at / 1.2, 0.0, 1.0))
			"fall":
				rot = clampf(at / 0.5, 0.0, 1.0) * PI * 0.5
				alpha = clampf(1.4 - at, 0.25, 1.0)
			"exit":
				dx = (1.0 if tx > size.x * 0.5 else -1.0) * at * size.x * 0.9
				alpha = clampf(1.0 - at * 1.5, 0.0, 1.0)
		if mouth and str(a["act"]) == "":
			dy -= absf(sin(_t * 9.0)) * k * 0.6
		elif not speaking:
			dy -= sin(_t * 1.8 + float(_order.find(id))) * k * 0.25
		r.visible = not bool(a["hidden"])
		r.pivot_offset = Vector2(r.size.x * 0.5, r.size.y)
		r.rotation = rot
		r.scale = Vector2(1.0, sy)
		r.position = Vector2(float(a["cx"]) - r.size.x * 0.5 + dx, ground_y - r.size.y + dy)
		# Ceux qui se taisent restent un peu dans l'ombre.
		var dim := 1.0 if speaking or _speaker == "" or not ACTOR_SPRITE.has(_speaker) else 0.72
		r.modulate = Color(tint.r * dim, tint.g * dim, tint.b * dim, alpha)
		if str(a["act"]) == "exit" and at > 0.8:
			_remove_actor.call_deferred(id)


func _update_subject(delta: float) -> void:
	if subject == null or not subject.visible or subject.texture == null:
		return
	_subject_t += delta
	var grow := clampf(_subject_t / 0.6, 0.0, 1.0)
	var sc := lerpf(0.7, 1.0, 1.0 - pow(1.0 - grow, 3.0))
	var dx := 0.0
	var extra := 1.0
	var rot := 0.0
	var tint := Color.WHITE
	if _subject_act != "":
		_subject_act_t += delta
		var at := _subject_act_t
		match _subject_act:
			"roar":
				extra = 1.0 + 0.12 * sin(clampf(at / 0.5, 0.0, 1.0) * PI)
				tint = Color(1.4, 0.8, 0.8).lerp(Color.WHITE, clampf(at / 0.8, 0.0, 1.0))
			"hit":
				dx = sin(at * 50.0) * 10.0 * clampf(1.0 - at / 0.4, 0.0, 1.0)
				tint = Color(1.0, 0.4, 0.4).lerp(Color.WHITE, clampf(at / 0.4, 0.0, 1.0))
			"fall":
				rot = clampf(at / 0.8, 0.0, 1.0) * 0.35
				tint = Color.WHITE.lerp(Color(0.5, 0.5, 0.55), clampf(at / 0.8, 0.0, 1.0))
			"glow":
				tint = Color(1.6, 1.6, 1.4).lerp(Color.WHITE, clampf(at / 1.2, 0.0, 1.0))
			"rise":
				extra = lerpf(0.8, 1.0, clampf(at / 0.8, 0.0, 1.0))
	# La créature se tient au fond de la scène, derrière les acteurs : grande, posée, elle respire.
	var tw := float(subject.texture.get_width())
	var th := float(subject.texture.get_height())
	var area := maxf(120.0, ground_y - top_y)
	var k := clampf(floorf(area * 0.6 / th), 2.0, 12.0)
	subject.size = Vector2(tw * k, th * k)
	var foot := ground_y - area * 0.07
	subject.pivot_offset = Vector2(subject.size.x * 0.5, subject.size.y)
	subject.scale = Vector2(1.0, 1.0 + 0.015 * sin(_t * 1.6)) * sc * extra
	subject.rotation = rot
	subject.position = Vector2((size.x - subject.size.x) * 0.5 + dx, foot - subject.size.y)
	subject.self_modulate = Color(tint, grow)
