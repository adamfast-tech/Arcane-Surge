class_name HeroTurntable
extends Control
## Le héros (ou un compagnon) qu'on fait tourner (Équipement) : glisser vers la gauche ou la droite le tourne sur lui-même,
## librement, sur 360° ; lâché en mouvement, il continue sur sa lancée puis ralentit. Un glissé vertical reste
## un défilement de la page. Rendu : HeroModel (voxels -> pixel art), 48 angles gardés en cache, préparés
## en arrière-plan à raison d'un par image.

const SCALE := 7 ## taille d'un pixel du héros à l'écran
const TURN_PX := 320.0 ## glissé (px) pour un tour complet
const DEADZONE := 8.0

var yaw := PI + 0.45 ## de trois quarts face
var _model: HeroModel
var _tex: ImageTexture
var _step := -1
var _vel := 0.0 ## vitesse de rotation (radians/s) après un lâcher
var _press := false
var _axis := 0 ## 0 : indécis, 1 : horizontal (rotation), 2 : vertical (défilement de la page)
var _start := Vector2.ZERO
var _last_t := 0
var _warm := 0 ## prochain angle à préparer en arrière-plan


func setup(look: Dictionary, race: String, cls: String, cos: Dictionary = {}) -> void:
	setup_model(HeroModel.of(look, race, cls, cos))


## Un modèle déjà construit (compagnon).
func setup_model(m: HeroModel) -> void:
	_model = m
	custom_minimum_size = Vector2(HeroModel.W * SCALE, HeroModel.H * SCALE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tooltip_text = "Glisse vers la gauche ou la droite pour le faire tourner"
	_refresh()


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if _model == null:
		return
	if not _press and absf(_vel) > 0.05:
		yaw += _vel * delta
		_vel *= pow(0.04, delta) ## freinage : la lancée s'éteint en une seconde environ
		_refresh()
	elif not _press:
		_vel = 0.0
	# Préparer les autres angles, un par image, pour que la rotation reste fluide dès le premier tour.
	if _warm < HeroModel.STEPS:
		_model.image_at(float(_warm) / float(HeroModel.STEPS) * TAU)
		_warm += 1


func _refresh() -> void:
	var step := posmod(int(round(yaw / TAU * float(HeroModel.STEPS))), HeroModel.STEPS)
	if step == _step:
		return
	_step = step
	var img := _model.image_at(yaw)
	if _tex == null:
		_tex = ImageTexture.create_from_image(img)
	else:
		_tex.update(img)
	queue_redraw()


func _draw() -> void:
	if _tex == null:
		return
	var sz := Vector2(HeroModel.W * SCALE, HeroModel.H * SCALE)
	draw_texture_rect(_tex, Rect2((size - sz) * 0.5 * Vector2(1, 0) + Vector2(0, size.y - sz.y), sz), false)


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
