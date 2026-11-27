class_name HeroTurntable
extends Control
## Le héros (ou un compagnon) qu'on fait tourner (Équipement) : glisser vers la gauche ou la droite le tourne sur lui-même,
## librement, sur 360° ; lâché en mouvement, il continue sur sa lancée puis ralentit. Un glissé vertical reste
## un défilement de la page. Il respire au repos ; le toucher lui fait faire un geste (sort, victoire) ; play()
## joue une animation (marche, coup reçu, défaite…). Rendu : HeroModel (voxels -> pixel art), images gardées en
## cache, préparées en arrière-plan à raison d'une par image d'écran.

signal tapped

const SCALE := 7 ## taille d'un pixel du héros à l'écran
const TURN_PX := 320.0 ## glissé (px) pour un tour complet
const DEADZONE := 8.0
const FLOURISH := ["cast", "victory"] ## gestes joués au toucher, à tour de rôle

var yaw := PI + 0.45 ## de trois quarts face
var light := "jour" ## éclairage de la scène (HeroModel.LIGHTS)
var idle := "idle" ## animation de repos ("" : immobile)
var react := true ## le toucher fait faire un geste
var _model: HeroModel
var _tex: ImageTexture
var _shown := ""
var _vel := 0.0 ## vitesse de rotation (radians/s) après un lâcher
var _press := false
var _axis := 0 ## 0 : indécis, 1 : horizontal (rotation), 2 : vertical (défilement de la page)
var _start := Vector2.ZERO
var _last_t := 0
var _warm := 0 ## prochain angle à préparer en arrière-plan
var _anim := ""
var _frame := 0
var _ft := 0.0 ## temps passé sur l'image en cours
var _hold := 0.0 ## une animation finie reste sur sa dernière image ce temps-là
var _tap_n := 0


func setup(look: Dictionary, race: String, cls: String, cos: Dictionary = {}, gear: Dictionary = {}) -> void:
	setup_model(HeroModel.of(look, race, cls, cos, gear))


## Un modèle déjà construit (compagnon).
func setup_model(m: HeroModel) -> void:
	_model = m
	_anim = idle
	_frame = 0
	custom_minimum_size = Vector2(HeroModel.FOOT_W * SCALE, HeroModel.FOOT_H * SCALE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tooltip_text = "Glisse vers la gauche ou la droite pour le faire tourner ; touche-le pour un geste"
	_shown = ""
	_refresh()


## Joue une animation (HeroModel.ANIMS) ; celles qui ne bouclent pas reviennent ensuite au repos.
func play(anim: String) -> void:
	if not HeroModel.ANIMS.has(anim):
		return
	_anim = anim
	_frame = 0
	_ft = 0.0
	_hold = 0.0
	_refresh()


func current_anim() -> String:
	return _anim


func set_light(id: String) -> void:
	light = id
	_shown = ""
	_warm = 0
	_refresh()


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if _model == null:
		return
	if not _press and absf(_vel) > 0.05:
		yaw += _vel * delta
		_vel *= pow(0.04, delta) ## freinage : la lancée s'éteint en une seconde environ
	elif not _press:
		_vel = 0.0
	# Animation : pendant qu'on le fait tourner, il garde son image (moins de rendus).
	if _anim != "" and not (_press and _axis == 1):
		var ad: Dictionary = HeroModel.ANIMS[_anim]
		if _hold > 0.0:
			_hold -= delta
			if _hold <= 0.0:
				_anim = idle
				_frame = 0
				_ft = 0.0
		else:
			_ft += delta
			if _ft >= float(ad["dt"]):
				_ft = 0.0
				if _frame + 1 < int(ad["frames"]):
					_frame += 1
				elif bool(ad["loop"]):
					_frame = 0
				elif _anim != idle:
					_hold = 1.6 if _anim == "defeat" else 0.7
	_refresh()
	# Préparer d'avance : les images du repos sous cet angle, puis les autres angles.
	if _warm < HeroModel.STEPS:
		_model.frame_at(float(_warm) / float(HeroModel.STEPS) * TAU, idle, 0, light)
		_warm += 1
	elif idle != "" and _warm < HeroModel.STEPS + int(HeroModel.ANIMS[idle]["frames"]):
		_model.frame_at(yaw, idle, _warm - HeroModel.STEPS, light)
		_warm += 1


func _refresh() -> void:
	if _model == null:
		return
	var step := posmod(int(round(yaw / TAU * float(HeroModel.STEPS))), HeroModel.STEPS)
	var key := "%d|%s|%d|%s" % [step, _anim, _frame, light]
	if key == _shown:
		return
	_shown = key
	var img := _model.frame_at(yaw, _anim, _frame, light)
	if _tex == null or _tex.get_size() != Vector2(img.get_size()):
		_tex = ImageTexture.create_from_image(img)
	else:
		_tex.update(img)
	queue_redraw()


func _draw() -> void:
	if _tex == null:
		return
	# Toute l'image, pieds en bas au centre : un bras levé ou un saut débordent au-dessus.
	var sz := Vector2(HeroModel.W * SCALE, HeroModel.H * SCALE)
	draw_texture_rect(_tex, Rect2(Vector2((size.x - sz.x) * 0.5, size.y - sz.y), sz), false)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := e as InputEventMouseButton
		if mb.pressed:
			_press = true
			_axis = 0
			_start = mb.position
			_vel = 0.0
			_last_t = Time.get_ticks_msec()
		else:
			_press = false
			if _axis == 1:
				# Lâché après une pause : pas de lancée.
				if Time.get_ticks_msec() - _last_t > 90:
					_vel = 0.0
				accept_event()
			elif _axis == 0:
				# Un toucher sans glisser : un geste.
				tapped.emit()
				if react and (_anim == idle or _anim == ""):
					play(str(FLOURISH[_tap_n % FLOURISH.size()]))
					_tap_n += 1
			_axis = 0
		return
	if e is InputEventMouseMotion and _press:
		var mm := e as InputEventMouseMotion
		if _axis == 0:
			var d := mm.position - _start
			if absf(d.x) > DEADZONE and absf(d.x) > absf(d.y):
				_axis = 1
			elif absf(d.y) > DEADZONE:
				_axis = 2
		if _axis == 1:
			var now := Time.get_ticks_msec()
			var dt := maxf(0.001, float(now - _last_t) / 1000.0)
			_last_t = now
			var dy := -mm.relative.x / TURN_PX * TAU
			yaw += dy
			_vel = lerpf(_vel, dy / dt, 0.5)
			_refresh()
			accept_event()
