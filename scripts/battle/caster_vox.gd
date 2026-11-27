class_name CasterVox
extends RefCounted
## Un lanceur en combat rendu d'après son modèle en volume (HeroModel) : le héros avec son équipement et ses
## cosmétiques, les compagnons avec leur modèle. Vu de dos, il se tourne vers où il se déplace et vers le point où
## il lance un sort ; il respire, marche, tend son arme quand il tire, lance ses sorts, encaisse quand la barrière
## est touchée, se retourne vers nous pour célébrer la victoire, ou met un genou à terre.
## Les images sont rendues à la demande, une seule par image d'écran pour tous les lanceurs (le reste du temps,
## l'image précédente reste affichée), et gardées en cache.

const LIGHT := "jour"
const QUANT := TAU / float(HeroModel.STEPS) * 2.0 ## angles par pas de 15°
const TURN_DT := 0.05 ## temps pour un pas de 15°


var model: HeroModel
var tex: ImageTexture
var rest_h := 26.0 ## hauteur du personnage au repos (pixels), pour l'échelle
var tip := Vector2(6, 22) ## bout de l'arme au repos, vu de dos (pixels depuis le centre des pieds)
var yaw := 0.0
var _target_yaw := 0.0
var _turn_t := 0.0
var _anim := "idle"
var _frame := 0
var _ft := 0.0
var _forced := "" ## animation imposée (sort, coup, victoire, défaite) jusqu'à sa fin
var _hold := false ## reste sur la dernière image (fin du combat)
var _shown := ""
var _aim_x := 0.0
var _aim_t := 0.0


static func for_caster(id: String, cls: String) -> CasterVox:
	var m: HeroModel = null
	if id == "player":
		m = HeroModel.of(Profile.look(), Profile.race(), Profile.player_class(), Profile.visible_cosmetics(), Profile.gear_look())
	elif HeroModel.has_companion(id):
		m = HeroModel.of_companion(id, cls)
	if m == null:
		return null
	var cv := CasterVox.new()
	cv.model = m
	var img := m.frame_at(0.0, "idle", 0, LIGHT)
	var used := img.get_used_rect()
	cv.rest_h = float(maxi(12, HeroModel.H - 1 - used.position.y))
	cv.tip = Vector2(float(used.end.x) - float(HeroModel.W) * 0.5 - 1.0, float(HeroModel.H - 1 - used.position.y))
	cv.tex = ImageTexture.create_from_image(img)
	cv._shown = "idle|0|0"
	# Le repos, vu de dos, préparé d'avance.
	for f in range(int(HeroModel.ANIMS["idle"]["frames"])):
		m.frame_at(0.0, "idle", f, LIGHT)
	return cv


## Taille d'un pixel (mètres) pour que le personnage ait la hauteur de son sprite.
func pixel_size(height_m: float) -> float:
	return height_m / rest_h


## Décalage du sprite (pixels) : les pieds sur la position.
func offset() -> Vector2:
	return Vector2(0.0, float(HeroModel.H) * 0.5 - 1.0)


## Un sort lancé vers x (unités de l'arène) depuis x0 : il se tourne vers la cible et lance.
func cast_at(x0: float, x: float) -> void:
	if _hold:
		return
	_aim_x = x - x0
	_aim_t = 0.9
	_force("cast")


func hit() -> void:
	if _hold or _forced == "cast":
		return
	_force("hit")


## Fin du combat : victoire (il se retourne vers nous) ou défaite.
func finish(won: bool) -> void:
	if _hold:
		return
	_hold = true
	_force("victory" if won else "defeat")


func _force(anim: String) -> void:
	_forced = anim
	_anim = anim
	_frame = 0
	_ft = 0.0


## Avance l'animation ; renvoie true si l'image affichée a changé.
func step(dt: float, dx: float, firing: bool) -> bool:
	# Orientation voulue.
	if _forced == "victory":
		_target_yaw = PI
	elif _aim_t > 0.0:
		_aim_t -= dt
		_target_yaw = clampf(_aim_x * 0.22, -0.8, 0.8)
	elif absf(dx) > 0.0005:
		_target_yaw = 0.52 * signf(dx)
	elif not _hold:
		_target_yaw = 0.0
	_turn_t += dt
	if _turn_t >= TURN_DT and absf(_target_yaw - yaw) > QUANT * 0.5:
		_turn_t = 0.0
		yaw += QUANT * signf(_target_yaw - yaw)
	# Animation.
	var victory_wait := _forced == "victory" and absf(_target_yaw - yaw) > QUANT * 0.5
	if _forced != "":
		var ad: Dictionary = HeroModel.ANIMS[_forced]
		if not victory_wait:
			_ft += dt
			if _ft >= float(ad["dt"]):
				_ft = 0.0
				if _frame + 1 < int(ad["frames"]):
					_frame += 1
				elif not _hold:
					_forced = ""
	if _forced == "":
		var want := "walk" if absf(dx) > 0.0005 else ("fire" if firing else "idle")
		if want != _anim:
			_anim = want
			_frame = 0
			_ft = 0.0
		var fdt := 0.12 if _anim == "fire" else float(HeroModel.ANIMS[_anim]["dt"])
		_ft += dt
		if _ft >= fdt:
			_ft = 0.0
			_frame += 1
	var anim := _anim
	var f := _frame
	if _forced == "":
		if _anim == "fire":
			# Tir continu : l'arme tendue vers l'arène, qui palpite.
			anim = "cast"
			f = 2 + _frame % 2
		else:
			f = _frame % int(HeroModel.ANIMS[_anim]["frames"])
	elif victory_wait:
		anim = "idle"
		f = 0
	return _show(anim, f)


func _show(anim: String, f: int) -> bool:
	var key := "%s|%d|%d" % [anim, f, posmod(int(round(yaw / TAU * float(HeroModel.STEPS))), HeroModel.STEPS)]
	if key == _shown:
		return false
	var img := model.frame_budgeted(yaw, anim, f, LIGHT)
	if img == null:
		return false ## une image a déjà été rendue à cette image d'écran : on attend la suivante
	_shown = key
	tex.update(img)
	return true
