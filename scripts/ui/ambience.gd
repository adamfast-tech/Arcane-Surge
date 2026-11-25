class_name Ambience
extends Control
## Ambiance des menus (option « Ambiance enrichie » ; docs/design/31-ambiance.md) : l'illustration de fond
## respire, des rayons et une brume lumineuse dérivent (shader), des particules propres à chaque salle
## flottent (lucioles, poussière arcanique, braises, éclats de lune). Rien ne change dans la mise en page.

## Ambiances : couleurs des rayons et de la brume, type et couleurs des particules.
const MOODS := {
	"dawn": {"glow": "4fe3d2", "glow2": "f2c46b", "rays": 0.6, "fog": 0.45, "kind": "fireflies", "motes": ["fff3b0", "c8f5a0"], "amount": 44},
	"arcane": {"glow": "b07cff", "glow2": "ffb86a", "rays": 0.45, "fog": 0.35, "kind": "dust", "motes": ["e0c8ff", "9ff0ff"], "amount": 46},
	"moon": {"glow": "a8b8ff", "glow2": "e8e0ff", "rays": 0.6, "fog": 0.25, "kind": "dust", "motes": ["ffffff", "c8b0ff"], "amount": 30},
	"forge": {"glow": "ff6a2a", "glow2": "ffb050", "rays": 0.3, "fog": 0.4, "kind": "embers", "motes": ["ffe08a", "ff6a2a"], "amount": 48},
	"campfire": {"glow": "ff9b4a", "glow2": "ffd070", "rays": 0.3, "fog": 0.3, "kind": "embers", "motes": ["ffe8a0", "ff8a3a"], "amount": 30},
	"mist": {"glow": "6fdccf", "glow2": "9fe3ff", "rays": 0.35, "fog": 0.55, "kind": "fireflies", "motes": ["c8f5a0", "9ff0ff"], "amount": 26},
	"gold": {"glow": "f2c46b", "glow2": "6fdccf", "rays": 0.5, "fog": 0.25, "kind": "dust", "motes": ["fff1c4", "f2c46b"], "amount": 40},
	# Havre-Aube suit l'heure réelle : aube, jour, crépuscule, nuit (teinte de l'illustration, lumière, particules).
	"havre_aube": {"glow": "ff9bb0", "glow2": "ffc870", "rays": 0.7, "fog": 0.5, "kind": "fireflies", "motes": ["fff3b0", "ffc8d8"], "amount": 30, "tint": [1.05, 0.86, 0.86]},
	"havre_jour": {"glow": "8fe3d2", "glow2": "fff0b0", "rays": 0.9, "fog": 0.25, "kind": "dust", "motes": ["fffbe0", "f2e28b"], "amount": 34, "tint": [1.2, 1.16, 1.06]},
	"havre_crepuscule": {"glow": "ff7a5a", "glow2": "ffa84a", "rays": 0.65, "fog": 0.45, "kind": "dust", "motes": ["ffd8a0", "ff8a5a"], "amount": 36, "tint": [1.08, 0.78, 0.62]},
	"havre_nuit": {"glow": "6a8aff", "glow2": "c8d8ff", "rays": 0.4, "fog": 0.4, "kind": "fireflies", "motes": ["fff3b0", "9ff0ff"], "amount": 46, "tint": "9aa8e8"},
	# Carte : une ambiance par zone.
	"steppe": {"glow": "e8b060", "glow2": "ffd8a0", "rays": 0.55, "fog": 0.35, "kind": "dust", "motes": ["ffe8c0", "d8a060"], "amount": 40},
	"swamp": {"glow": "8fd16a", "glow2": "c8f5a0", "rays": 0.25, "fog": 0.8, "kind": "fireflies", "motes": ["d8ff8a", "8fd16a"], "amount": 30, "tint": "d8e8d0"},
	"snow": {"glow": "9fe3ff", "glow2": "e8f6ff", "rays": 0.45, "fog": 0.45, "kind": "snow", "motes": ["ffffff", "cfefff"], "amount": 60, "tint": "e0ecff"},
	"desert": {"glow": "f2c46b", "glow2": "3fc1c9", "rays": 0.85, "fog": 0.3, "kind": "dust", "motes": ["fff1c4", "e6c15a"], "amount": 44, "tint": [1.12, 1.02, 0.86]},
	"abyss": {"glow": "4fe3d2", "glow2": "8fe0ff", "rays": 0.8, "fog": 0.5, "kind": "dust", "motes": ["e0f8ff", "8fe0ff"], "amount": 40, "tint": [0.82, 0.98, 1.12]},
	"cinder": {"glow": "ff6a2a", "glow2": "ffb050", "rays": 0.35, "fog": 0.55, "kind": "embers", "motes": ["ffd070", "ff6a2a"], "amount": 50, "tint": [1.08, 0.86, 0.8]},
}

## Phases de la journée à Havre-Aube, selon l'heure de l'appareil (« &hour=22 » pour un aperçu).
static var hour_override := -1


static func havre_phase() -> String:
	var h := hour_override if hour_override >= 0 else int(Time.get_datetime_dict_from_system(false)["hour"])
	if h >= 5 and h < 8:
		return "aube"
	if h >= 8 and h < 17:
		return "jour"
	if h >= 17 and h < 21:
		return "crepuscule"
	return "nuit"

var mood := "dawn"
var art: Control ## illustration de fond qui « respire » (zoom et dérive très lents)
var _t := 0.0
var _parts: CPUParticles2D
var _glow: ColorRect

static var _dot: Texture2D
static var _glow_shader: Shader
static var _vignette_shader: Shader


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if mood == "havre":
		mood = "havre_" + havre_phase()
	var m: Dictionary = MOODS.get(mood, MOODS["dawn"])
	if art != null:
		# Teinte de l'illustration (nuit bleutée, crépuscule orangé…), neutre sinon.
		art.modulate = Color.WHITE
		if m.has("tint"):
			var tn: Variant = m["tint"]
			art.modulate = Color(float(tn[0]), float(tn[1]), float(tn[2])) if tn is Array else Color(str(tn))
	_t = randf() * 30.0
	# Rayons et brume (additif).
	if _glow_shader == null:
		_glow_shader = load("res://shaders/ui_ambience.gdshader")
		_vignette_shader = load("res://shaders/ui_vignette.gdshader")
	_glow = ColorRect.new()
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gm := ShaderMaterial.new()
	gm.shader = _glow_shader
	gm.set_shader_parameter("glow", Color(str(m["glow"])))
	gm.set_shader_parameter("glow2", Color(str(m["glow2"])))
	gm.set_shader_parameter("rays", float(m["rays"]))
	gm.set_shader_parameter("fog", float(m["fog"]))
	_glow.material = gm
	add_child(_glow)
	_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Particules.
	_parts = _make_particles(m)
	add_child(_parts)
	# Vignette.
	var vig := ColorRect.new()
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = _vignette_shader
	vig.material = vm
	add_child(vig)
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_fit)
	_fit()


func _fit() -> void:
	if _glow != null and _glow.material != null:
		(_glow.material as ShaderMaterial).set_shader_parameter("aspect", Vector2(1.0, size.y / maxf(1.0, size.x)))
	if _parts == null:
		return
	var m: Dictionary = MOODS.get(mood, MOODS["dawn"])
	if str(m["kind"]) == "embers":
		# Braises : elles montent depuis le bas de l'écran.
		_parts.position = Vector2(size.x * 0.5, size.y + 10.0)
		_parts.emission_rect_extents = Vector2(size.x * 0.5, 20.0)
	elif str(m["kind"]) == "snow":
		# Neige : elle tombe depuis le haut de l'écran.
		_parts.position = Vector2(size.x * 0.5, -10.0)
		_parts.emission_rect_extents = Vector2(size.x * 0.55, 10.0)
	else:
		# Lucioles et poussière : surtout dans l'illustration (les deux tiers du haut).
		_parts.position = Vector2(size.x * 0.5, size.y * 0.36)
		_parts.emission_rect_extents = Vector2(size.x * 0.5, size.y * 0.34)
	# Densité selon la surface (téléphone ou écran large).
	_parts.amount = clampi(int(float(m["amount"]) * clampf(size.x * size.y / (430.0 * 900.0), 0.7, 2.2)), 12, 90)


func _process(delta: float) -> void:
	_t += delta
	if art != null and is_instance_valid(art):
		# L'illustration respire : zoom de 4 à 7 %, dérive de quelques pixels.
		art.pivot_offset = art.size * 0.5
		art.scale = Vector2.ONE * (1.055 + 0.015 * sin(_t * 0.11))
		art.position = Vector2(sin(_t * 0.05) * 10.0, cos(_t * 0.04) * 6.0)


static func _soft_dot() -> Texture2D:
	if _dot == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 32
		t.height = 32
		_dot = t
	return _dot


func _make_particles(m: Dictionary) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _soft_dot()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.local_coords = false
	var c1 := Color(str(m["motes"][0]))
	var c2 := Color(str(m["motes"][1]))
	var ramp := Gradient.new()
	match str(m["kind"]):
		"embers":
			p.lifetime = 6.0
			p.direction = Vector2(0, -1)
			p.spread = 18.0
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 75.0
			p.gravity = Vector2(4, -6)
			p.scale_amount_min = 0.18
			p.scale_amount_max = 0.45
			ramp.offsets = PackedFloat32Array([0.0, 0.1, 0.6, 1.0])
			ramp.colors = PackedColorArray([Color(c1, 0.0), Color(c1, 1.0), Color(c2, 0.7), Color(c2, 0.0)])
		"fireflies":
			# Lucioles : elles errent lentement et clignotent.
			p.lifetime = 8.0
			p.direction = Vector2(0, -1)
			p.spread = 180.0
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 16.0
			p.gravity = Vector2(0, -2)
			p.damping_min = 0.5
			p.damping_max = 2.0
			p.scale_amount_min = 0.35
			p.scale_amount_max = 0.85
			ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.3, 0.45, 0.6, 0.8, 1.0])
			ramp.colors = PackedColorArray([Color(c1, 0.0), Color(c1, 1.0), Color(c2, 0.25), Color(c1, 0.95), Color(c2, 0.3), Color(c1, 0.85), Color(c1, 0.0)])
		"snow":
			p.lifetime = 10.0
			p.direction = Vector2(0.15, 1)
			p.spread = 15.0
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 90.0
			p.gravity = Vector2(6, 4)
			p.scale_amount_min = 0.12
			p.scale_amount_max = 0.32
			ramp.offsets = PackedFloat32Array([0.0, 0.1, 0.85, 1.0])
			ramp.colors = PackedColorArray([Color(c1, 0.0), Color(c1, 0.9), Color(c2, 0.7), Color(c2, 0.0)])
		_:
			# Poussière arcanique, éclats de lune : petites lueurs qui montent doucement.
			p.lifetime = 9.0
			p.direction = Vector2(0, -1)
			p.spread = 60.0
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 12.0
			p.gravity = Vector2(1, -3)
			p.scale_amount_min = 0.14
			p.scale_amount_max = 0.42
			ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.7, 1.0])
			ramp.colors = PackedColorArray([Color(c1, 0.0), Color(c1, 0.9), Color(c2, 0.6), Color(c2, 0.0)])
	p.color_ramp = ramp
	p.preprocess = p.lifetime
	p.emitting = true
	return p
