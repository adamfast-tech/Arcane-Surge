class_name Arena3D
extends Node3D
## Rendu 2,5D de l'arène : scène 3D rendue en basse résolution puis agrandie (pixels nets),
## caméra inclinée derrière les lanceurs, chaussée de ruines au-dessus d'un gouffre brumeux,
## clair de lune, halos lumineux. Lit l'état de BattleSim (logique pure).
## Repère : position logique (x, y) -> monde (x, hauteur, -y). Le joueur est en z ≈ 0,
## le Nexus vers z = -15. La caméra regarde vers -z.

const TEXEL := 0.058 ## mètres par pixel de sprite
const MAX_SPRITES := 1000
const MAX_SHADOWS := 560
const PITCH_DEG := 50.0
const FOV := 40.0
const BAR_W := 0.62

var sim: BattleSim
var font: Font
var alpha := 0.0
var t := 0.0
var shake := 0.0
var flash := 0.0
var aim_active := false
var aim_pos := Vector2(-100.0, -100.0)
var aim_radius := 1.0
var aim_color := Color.WHITE

var cam: Camera3D
var _cam_base := Transform3D.IDENTITY
var _env: Environment
var _units_mm: MultiMesh
var _shadow_mm: MultiMesh
var _trees_mm: MultiMesh
var _billboard: Shader
var _stone_mat: StandardMaterial3D
var _fx_lines: ImmediateMesh
var _fx_points: ImmediateMesh
var _fx_mat: StandardMaterial3D
var _fx_pt_mat: StandardMaterial3D
var _fx: Array[Dictionary] = []
var _spell_fx: SpellFx
var _labels: Array[Label3D] = []
var _label_next := 0
var _portal_nodes: Array[Dictionary] = []
var _tower_nodes: Array[Dictionary] = []
var _nexus_nodes: Array[Dictionary] = []
var _escort_light: OmniLight3D
var _barrier_mat: StandardMaterial3D
var _barrier_shield: MeshInstance3D
var _casters: Array[Sprite3D] = []
var _staff_fx: CPUParticles3D
var _staff_light: OmniLight3D
var _torch_lights: Array[OmniLight3D] = []
var _pylon_nodes: Array[Dictionary] = []
var _terrain_view: TerrainView
var _moss_cap: StandardMaterial3D
var day := false ## Zone 2 : Collines d'Ambre en plein jour.
var swamp := false ## Zone 3 : Marais Murmurants au crépuscule.
var frost := false ## Zone 4 : Pics Gelés, nuit d'aurore boréale.
var desert := false ## Zone 5 : Désert de Verre ; la lumière suit le cycle soleil/lune de la simulation.
var cinder := false ## Zone 6 : Forêt Cendrée, ciel de fumée rougeoyant, incendies et dragons.
var _fire_nodes: Dictionary = {} ## id du foyer -> {root, ground, mat, flames}
var _dragons: Array[Dictionary] = [] ## passages de dragons en cours : {spr, shadow, y, age, dur, dir}
var _boss_lift := 0.0 ## hauteur du boss en vol (Drake ancien, Wyrm de cendre)
var _sun: DirectionalLight3D
var _day_k := 1.0 ## 1 = plein jour, 0 = nuit (transition douce)
var _fog_nodes: Array[Dictionary] = []
## Forêt guérie (la Sylvarche a été purifiée) : sol plus vert, veines dorées, lucioles.
var healed := false


static func w3(p: Vector2, h: float = 0.0) -> Vector3:
	return Vector3(p.x, h, -p.y)


func setup(s: BattleSim, f: Font, forest_healed: bool = false) -> void:
	sim = s
	font = f
	healed = forest_healed
	day = WorldArt.zone == 2
	swamp = WorldArt.zone == 3
	frost = WorldArt.zone == 4
	desert = WorldArt.zone == 5
	cinder = WorldArt.zone == 6
	_billboard = load("res://shaders/billboard_atlas.gdshader")
	_stone_mat = _triplanar(WorldArt.stone_texture(), 0.55)
	_build_environment()
	_build_terrain()
	_build_props()
	_build_pylons()
	_build_portals()
	_build_towers()
	_build_nexus()
	_build_barrier()
	_build_units()
	_build_casters()
	_build_fx()
	_spell_fx = SpellFx.new()
	add_child(_spell_fx)
	_terrain_view = TerrainView.new()
	add_child(_terrain_view)
	_terrain_view.setup(sim, _stone_mat, _moss_cap, _spell_fx)
	cam = Camera3D.new()
	cam.fov = FOV
	cam.near = 0.5
	cam.far = 220.0
	add_child(cam)
	cam.current = true


# ---------------------------------------------------------------- caméra

## Recule la caméra jusqu'à ce que toute l'arène (et un peu de ciel) soit visible.
func fit_camera(size: Vector2i) -> void:
	if cam == null:
		return
	var pts: Array[Vector3] = [
		w3(Vector2(-0.2, -0.7)), w3(Vector2(9.2, -0.7)), w3(Vector2(-0.2, 16.0)), w3(Vector2(9.2, 16.0)),
		w3(BattleSim.NEXUS_POS, 3.0),
	]
	var pitch := deg_to_rad(PITCH_DEG)
	var dir := Vector3(0.0, sin(pitch), cos(pitch))
	var target := w3(Vector2(4.5, 7.0))
	var lo := 4.0
	var hi := 120.0
	for i in range(30):
		var mid := (lo + hi) * 0.5
		cam.look_at_from_position(target + dir * mid, target, Vector3.UP)
		if _all_visible(pts, size):
			hi = mid
		else:
			lo = mid
	cam.look_at_from_position(target + dir * hi, target, Vector3.UP)
	_cam_base = cam.transform
	var far_d := cam.global_position.distance_to(w3(Vector2(4.5, 16.5)))
	_env.fog_depth_begin = far_d + 2.0
	_env.fog_depth_end = far_d + 34.0
	var stretch := 1.0 / maxf(0.3, cos(pitch))
	(_trees_mm_instance().material_override as ShaderMaterial).set_shader_parameter("upright_stretch", stretch)


func _all_visible(pts: Array[Vector3], size: Vector2i) -> bool:
	var m := Vector2(size) * 0.01
	for p in pts:
		if cam.is_position_behind(p):
			return false
		var s := cam.unproject_position(p)
		if s.x < m.x or s.y < m.y or s.x > size.x - m.x or s.y > size.y - m.y:
			return false
	return true


## Position logique visée par un point de l'écran (pixels du SubViewport).
func pick(screen: Vector2) -> Vector2:
	if cam == null:
		return Vector2(-100.0, -100.0)
	var o := cam.project_ray_origin(screen)
	var d := cam.project_ray_normal(screen)
	if d.y > -1e-4:
		return Vector2(-100.0, -100.0)
	var hit := o + d * (-o.y / d.y)
	return Vector2(hit.x, -hit.z)


# ---------------------------------------------------------------- construction

func _build_environment() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_CLEAR_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color("7890c0") if healed else Color("7078c0")
	_env.ambient_light_energy = 1.0
	if day:
		_env.ambient_light_color = Color("e0c8a0")
		_env.ambient_light_energy = 0.9
	elif swamp:
		_env.ambient_light_color = Color("9a8ab8")
		_env.ambient_light_energy = 0.95
	elif frost:
		_env.ambient_light_color = Color("9ab8e0")
		_env.ambient_light_energy = 1.05
	elif desert:
		_env.ambient_light_color = Color("e8c890")
		_env.ambient_light_energy = 1.0
	elif cinder:
		_env.ambient_light_color = Color("c8806a")
		_env.ambient_light_energy = 0.95
	_env.fog_enabled = true
	_env.fog_mode = Environment.FOG_MODE_DEPTH
	_env.fog_light_color = Color("26405a") if healed else Color("2d2c5e")
	if day:
		_env.fog_light_color = Color("d8b880")
	elif swamp:
		_env.fog_light_color = Color("6e7f6a")
	elif frost:
		_env.fog_light_color = Color("4a6a8e")
	elif desert:
		_env.fog_light_color = Color("c89a5a")
	elif cinder:
		_env.fog_light_color = Color("5a2a1e")
	_env.fog_depth_begin = 40.0
	_env.fog_depth_end = 80.0
	_env.glow_enabled = true
	_env.glow_intensity = 0.45
	_env.glow_bloom = 0.0
	_env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color("fff0d0") if day else (Color("d0c8e8") if swamp else (Color("c8f0ff") if frost else Color("b4c0ff")))
	if cinder:
		moon.light_color = Color("ffb890")
	moon.light_energy = 1.1
	moon.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	add_child(moon)
	_sun = moon
	if desert:
		_day_k = 1.0 if sim.is_day else 0.0
		_apply_daylight()


func _triplanar(tex: Texture2D, scale: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	m.roughness = 1.0
	return m


func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent != null else self).add_child(mi)
	return mi


func _unshaded(col: Color, transparent: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _build_terrain() -> void:
	# Dessus de la chaussée.
	var top := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = WorldArt.GROUND_SIZE
	top.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_texture = WorldArt.ground_texture(healed)
	gm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	gm.roughness = 1.0
	top.material_override = gm
	top.position = w3(WorldArt.GROUND_MIN + WorldArt.GROUND_SIZE * 0.5)
	add_child(top)
	# Murs de la chaussée et piles du pont qui plongent dans la brume.
	var c := WorldArt.GROUND_MIN + WorldArt.GROUND_SIZE * 0.5
	_box(Vector3(WorldArt.GROUND_SIZE.x, 2.6, WorldArt.GROUND_SIZE.y), w3(c, -1.31), _stone_mat)
	for y in [0.5, 5.5, 10.5, 15.5]:
		for x in [0.6, 8.4]:
			_box(Vector3(1.4, 14.0, 1.4), w3(Vector2(x, y), -8.5), _stone_mat)
	# Falaises boisées de part et d'autre.
	var rock := _triplanar(WorldArt.rock_texture(), 0.4)
	var moss := _triplanar(WorldArt.moss_texture(), 0.5)
	for side in [-1, 1]:
		var cx := 4.5 + float(side) * 14.5
		_box(Vector3(18.0, 10.0, 46.0), Vector3(cx, -7.6, -9.0), rock)
		_box(Vector3(18.0, 0.2, 46.0), Vector3(cx, -2.5, -9.0), moss)
		for k in range(4):
			var rx := 4.5 + float(side) * (6.2 + float(k) * 1.3)
			_box(Vector3(1.6, 1.2 + float(k) * 0.4, 2.2), Vector3(rx, -2.2, 3.0 - float(k) * 9.5), rock)
	# Brume.
	var mist_shader: Shader = load("res://shaders/mist.gdshader")
	var noise := WorldArt.mist_texture()
	var layers := [[-1.4, Color("8a8ad0"), 0.45, Vector2(0.012, 0.004)], [-3.0, Color("6a6ab8"), 0.55, Vector2(-0.008, 0.006)]]
	if day:
		layers = [[-1.4, Color("f0d8a8"), 0.3, Vector2(0.02, 0.003)], [-3.0, Color("d8b888"), 0.4, Vector2(-0.012, 0.005)]]
	elif swamp:
		layers = [[-1.2, Color("c9d1c4"), 0.6, Vector2(0.01, 0.004)], [-2.6, Color("6e7f6a"), 0.7, Vector2(-0.008, 0.005)]]
	elif frost:
		layers = [[-1.3, Color("eaf4fb"), 0.45, Vector2(0.018, 0.004)], [-2.8, Color("7fb7e0"), 0.55, Vector2(-0.012, 0.006)]]
	elif cinder:
		layers = [[-1.3, Color("6a3a30"), 0.5, Vector2(0.01, 0.006)], [-2.8, Color("3a2020"), 0.6, Vector2(-0.008, 0.008)]]
	for l in layers:
		var mi := MeshInstance3D.new()
		var mp := PlaneMesh.new()
		mp.size = Vector2(70.0, 60.0)
		mi.mesh = mp
		var sm := ShaderMaterial.new()
		sm.shader = mist_shader
		sm.set_shader_parameter("noise_tex", noise)
		sm.set_shader_parameter("tint", l[1])
		sm.set_shader_parameter("strength", l[2])
		sm.set_shader_parameter("speed", l[3])
		mi.material_override = sm
		mi.position = Vector3(4.5, float(l[0]), -10.0)
		add_child(mi)
	# Sapins (billboards verticaux).
	var pine := WorldArt.pine_texture()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = _quad_mesh()
	var spots: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	for i in range(90):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := 4.5 + side * rng.randf_range(6.0, 17.0)
		var y := rng.randf_range(-6.0, 34.0)
		spots.append([Vector3(x, -2.5, -y), rng.randf_range(3.0, 6.0), rng.randi_range(0, 2)])
	for i in range(14):
		var side := -1.0 if i % 2 == 0 else 1.0
		spots.append([Vector3(4.5 + side * rng.randf_range(5.6, 7.0), -7.0, -rng.randf_range(-2.0, 22.0)), rng.randf_range(6.0, 8.5), rng.randi_range(0, 2)])
	mm.instance_count = spots.size()
	for i in range(spots.size()):
		var s: Array = spots[i]
		var hgt: float = s[1]
		var tf := Transform3D(Basis.from_scale(Vector3(hgt * 20.0 / 44.0, hgt, 1.0)), s[0])
		mm.set_instance_transform(i, tf)
		var shade := rng.randf_range(0.8, 1.05)
		mm.set_instance_color(i, Color(shade, shade, shade * 1.05))
		var v: int = s[2]
		mm.set_instance_custom_data(i, Color(float(v) / 3.0, 0.0, 1.0 / 3.0, 1.0))
	var tmi := MultiMeshInstance3D.new()
	tmi.name = "Trees"
	tmi.multimesh = mm
	var tmat := ShaderMaterial.new()
	tmat.shader = _billboard
	tmat.set_shader_parameter("atlas", pine)
	tmat.set_shader_parameter("upright", true)
	tmat.set_shader_parameter("upright_stretch", 1.5)
	tmi.material_override = tmat
	tmi.custom_aabb = AABB(Vector3(-30.0, -15.0, -60.0), Vector3(70.0, 40.0, 80.0))
	add_child(tmi)
	_trees_mm = mm


func _trees_mm_instance() -> MultiMeshInstance3D:
	return get_node("Trees") as MultiMeshInstance3D


func _build_props() -> void:
	var moss_cap := _unshaded(Color("a09048") if day else (Color("4a5a48") if swamp else (Color("dcecf8") if frost else (Color("e8c890") if desert else Color("3f6a3a")))))
	moss_cap.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	# Piliers en ruine le long de la chaussée : construits par TerrainView (ils peuvent s'effondrer).
	_moss_cap = moss_cap
	# Bannière près des lanceurs (comme sur l'image de référence).
	var banner := Sprite3D.new()
	banner.texture = WorldArt.banner_texture()
	banner.pixel_size = TEXEL
	banner.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	banner.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	banner.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	banner.shaded = false
	banner.offset = Vector2(0.0, 13.0)
	banner.position = w3(Vector2(-0.55, 0.4))
	add_child(banner)
	# Torches.
	var flame := WorldArt.flame_texture()
	for x in [-0.55, 9.55]:
		_box(Vector3(0.12, 0.8, 0.12), w3(Vector2(x, -0.6), 0.4), _stone_mat)
		var f := Sprite3D.new()
		f.texture = flame
		f.pixel_size = TEXEL
		f.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		f.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		f.shaded = false
		f.modulate = Color(1.4, 1.2, 1.0)
		f.position = w3(Vector2(x, -0.6), 0.95)
		add_child(f)
		var l := OmniLight3D.new()
		l.light_color = Color("ff9b4a")
		l.light_energy = 1.4
		l.omni_range = 4.0
		l.position = w3(Vector2(x, -0.6), 1.1)
		add_child(l)
		_torch_lights.append(l)
	# Lucioles.
	var ff := CPUParticles3D.new()
	ff.amount = 34
	ff.lifetime = 6.0
	ff.preprocess = 6.0
	ff.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ff.emission_box_extents = Vector3(11.0, 1.4, 11.0)
	ff.position = Vector3(4.5, 0.9, -8.0)
	ff.direction = Vector3(0, 1, 0)
	ff.spread = 180.0
	ff.initial_velocity_min = 0.05
	ff.initial_velocity_max = 0.25
	ff.gravity = Vector3.ZERO
	ff.mesh = _particle_mesh(0.07)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.95, 0.55, 0.0))
	ramp.set_color(1, Color(1.0, 0.95, 0.55, 0.0))
	ramp.add_point(0.2, Color(1.0, 0.95, 0.6, 1.0))
	ramp.add_point(0.8, Color(0.85, 1.0, 0.55, 1.0))
	if swamp:
		# Feux follets verdâtres au-dessus du marais.
		ramp = Gradient.new()
		ramp.set_color(0, Color(0.6, 1.0, 0.5, 0.0))
		ramp.set_color(1, Color(0.6, 1.0, 0.5, 0.0))
		ramp.add_point(0.5, Color(0.7, 1.0, 0.55, 0.9))
	if frost:
		# Neige qui tombe doucement sur les Pics.
		ramp = Gradient.new()
		ramp.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
		ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		ramp.add_point(0.15, Color(0.95, 0.98, 1.0, 0.9))
		ramp.add_point(0.85, Color(0.9, 0.95, 1.0, 0.8))
		ff.amount = 120
		ff.position = Vector3(4.5, 4.0, -8.0)
		ff.emission_box_extents = Vector3(11.0, 2.0, 11.0)
		ff.direction = Vector3(0.2, -1.0, 0.0)
		ff.spread = 20.0
		ff.initial_velocity_min = 0.4
		ff.initial_velocity_max = 0.8
		ff.gravity = Vector3(0.05, -0.1, 0.0)
	if desert:
		# Voiles de sable doré qui filent avec le vent du désert.
		ramp = Gradient.new()
		ramp.set_color(0, Color(1.0, 0.85, 0.55, 0.0))
		ramp.set_color(1, Color(1.0, 0.85, 0.55, 0.0))
		ramp.add_point(0.5, Color(1.0, 0.9, 0.65, 0.7))
		ff.amount = 90
		ff.initial_velocity_max = 0.9
		ff.gravity = Vector3(0.35, 0.02, 0.0)
	if cinder:
		# Braises qui montent de la forêt en feu.
		ramp = Gradient.new()
		ramp.set_color(0, Color(1.0, 0.6, 0.2, 0.0))
		ramp.set_color(1, Color(1.0, 0.3, 0.1, 0.0))
		ramp.add_point(0.2, Color(1.0, 0.85, 0.4, 1.0))
		ramp.add_point(0.7, Color(1.0, 0.45, 0.15, 0.9))
		ff.amount = 110
		ff.direction = Vector3(0.1, 1.0, 0.0)
		ff.spread = 25.0
		ff.initial_velocity_min = 0.3
		ff.initial_velocity_max = 0.9
		ff.gravity = Vector3(0.08, 0.25, 0.0)
	if day:
		# Pollen et poussière dorée dans la lumière de midi.
		ramp = Gradient.new()
		ramp.set_color(0, Color(1.0, 0.9, 0.7, 0.0))
		ramp.set_color(1, Color(1.0, 0.9, 0.7, 0.0))
		ramp.add_point(0.5, Color(1.0, 0.92, 0.75, 0.75))
		ff.initial_velocity_max = 0.5
		ff.gravity = Vector3(0.12, 0.0, 0.0)
	ff.color_ramp = ramp
	add_child(ff)


## Pylônes d'ambre (zone 2) : cristal sur socle, s'illumine avant de surcharger son portail.
func _build_pylons() -> void:
	for py in sim.pylons:
		var fr := SpriteAtlas.frame("pylon")
		var s := Sprite3D.new()
		s.texture = SpriteAtlas.single("pylon")
		s.pixel_size = SpriteAtlas.height_m("pylon") / float((fr["px"] as Rect2i).size.y)
		s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		s.shaded = false
		s.centered = false
		s.offset = Vector2(-float((fr["px"] as Rect2i).size.x) * 0.5, 0.0)
		s.position = w3(py["pos"])
		add_child(s)
		var l := OmniLight3D.new()
		l.light_color = Color("ffb84a")
		l.light_energy = 0.6
		l.omni_range = 2.4
		l.position = w3(py["pos"], 1.2)
		add_child(l)
		_pylon_nodes.append({"py": py, "sprite": s, "light": l})


## Bancs de brume (zone 3) : nappes de brume qui dérivent ; plus pâles quand la Lumière les dissipe.
func _update_fog_banks() -> void:
	while _fog_nodes.size() < sim.fog.size():
		var root := Node3D.new()
		add_child(root)
		var puffs: Array = []
		for k in range(7):
			var spr := Sprite3D.new()
			spr.texture = FxArt.flash()
			spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			spr.shaded = false
			spr.transparent = true
			spr.no_depth_test = false
			spr.modulate = Color(0.82, 0.88, 0.84, 0.0)
			root.add_child(spr)
			puffs.append([spr, Vector2(randf_range(-0.7, 0.7), randf_range(-0.7, 0.7)), randf_range(0.6, 1.1), randf() * TAU])
		_fog_nodes.append({"root": root, "puffs": puffs})
	for i in range(_fog_nodes.size()):
		var fn: Dictionary = _fog_nodes[i]
		if i >= sim.fog.size():
			(fn["root"] as Node3D).visible = false
			continue
		var f: Dictionary = sim.fog[i]
		var r := float(f["r"])
		var d := float(f["density"])
		(fn["root"] as Node3D).position = w3(f["pos"], 0.0)
		for pf in fn["puffs"]:
			var spr: Sprite3D = pf[0]
			var off: Vector2 = pf[1]
			var sc: float = pf[2]
			var ph: float = pf[3]
			spr.position = Vector3(off.x * r + sin(t * 0.4 + ph) * 0.3, 0.5 + 0.25 * sin(t * 0.6 + ph), -off.y * r)
			spr.pixel_size = r * sc * 2.4 / 32.0
			spr.modulate = Color(0.82, 0.88, 0.84, 0.62 * d)


func _update_pylons() -> void:
	for pn in _pylon_nodes:
		var py: Dictionary = pn["py"]
		var left := float(py["t"])
		var charge := clampf(1.0 - left / 2.0, 0.0, 1.0) # s'allume pendant les 2 dernières secondes
		var pulse := 0.5 + 0.5 * sin(t * (4.0 + 14.0 * charge))
		var k := 1.0 + charge * (0.6 + 0.6 * pulse)
		(pn["sprite"] as Sprite3D).modulate = Color(k, k * 0.95, k * 0.8)
		(pn["light"] as OmniLight3D).light_energy = 0.5 + 0.3 * sin(t * 2.0) + charge * 2.2 * pulse


func _particle_mesh(size: float) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	q.material = m
	return q


func _quad_mesh() -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.0)
	q.center_offset = Vector3(0.0, 0.5, 0.0)
	return q


func _label(size: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.font = font
	l.font_size = size
	l.pixel_size = 0.0085
	l.outline_size = 12
	l.outline_modulate = Color(0.04, 0.03, 0.09, 0.95)
	l.modulate = col
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	l.render_priority = 10
	l.outline_render_priority = 9
	return l


func _build_portals() -> void:
	for p in sim.portals:
		_build_portal(p)


func _portals_changed() -> bool:
	for i in range(_portal_nodes.size()):
		if _portal_nodes[i]["portal"] != sim.portals[i]:
			return true
	return false


func _sync_portal_nodes() -> void:
	var keep: Array[Dictionary] = []
	for pn in _portal_nodes:
		if sim.portals.has(pn["portal"]):
			keep.append(pn)
		else:
			(pn["root"] as Node3D).queue_free()
	_portal_nodes = keep
	for p in sim.portals:
		var known := false
		for pn in _portal_nodes:
			known = known or pn["portal"] == p
		if not known:
			_build_portal(p)
	var order: Array[Dictionary] = []
	for p in sim.portals:
		for pn in _portal_nodes:
			if pn["portal"] == p:
				order.append(pn)
	_portal_nodes = order


func _build_portal(p: Portal) -> void:
	var root := Node3D.new()
	root.position = w3(Vector2(p.x, p.y))
	add_child(root)
	var half := p.width * 0.5
	var col := p.color()
	_box(Vector3(0.26, 1.45, 0.26), Vector3(-half - 0.13, 0.725, 0.0), _stone_mat, root)
	_box(Vector3(0.26, 1.45, 0.26), Vector3(half + 0.13, 0.725, 0.0), _stone_mat, root)
	_box(Vector3(p.width + 0.6, 0.2, 0.32), Vector3(0.0, 1.5, 0.0), _stone_mat, root)
	var panel := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(p.width, 1.3)
	panel.mesh = qm
	var pmat := _unshaded(Color(col, 0.35), true)
	panel.material_override = pmat
	panel.position = Vector3(0.0, 0.7, 0.0)
	root.add_child(panel)
	var strip := MeshInstance3D.new()
	var sp := PlaneMesh.new()
	sp.size = Vector2(p.width, 0.16)
	strip.mesh = sp
	var smat := _unshaded(col)
	strip.material_override = smat
	strip.position = Vector3(0.0, 0.03, 0.0)
	root.add_child(strip)
	var lab := _label(46 if p.kind == "answer" else 72, Color.WHITE)
	lab.position = Vector3(0.0, 2.05, 0.0)
	lab.text = p.label()
	root.add_child(lab)
	var seal := _label(44, Color("e070ff"))
	seal.position = Vector3(0.0, 2.65, 0.0)
	root.add_child(seal)
	var light := OmniLight3D.new()
	light.light_color = col
	light.light_energy = 0.9
	light.omni_range = 2.6
	light.position = Vector3(0.0, 0.8, 0.4)
	root.add_child(light)
	_portal_nodes.append({"portal": p, "root": root, "panel": pmat, "strip": smat, "label": lab, "seal": seal, "light": light})


func _build_towers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for tw in sim.towers:
		var root := Node3D.new()
		root.position = w3(tw["pos"])
		add_child(root)
		var parts: Array[Node3D] = []
		for k in range(3):
			var b := _box(Vector3(0.8 - float(k) * 0.08, 0.55, 0.8 - float(k) * 0.08), Vector3(0.0, 0.3 + float(k) * 0.56, 0.0), _stone_mat, root)
			b.rotation.y = rng.randf_range(-0.2, 0.2)
			parts.append(b)
		var crystal := MeshInstance3D.new()
		crystal.mesh = _octahedron()
		var cm := StandardMaterial3D.new()
		cm.albedo_color = Color("b07cff")
		cm.emission_enabled = true
		cm.emission = Color("9a6aff")
		cm.emission_energy_multiplier = 1.4
		crystal.material_override = cm
		crystal.scale = Vector3(0.25, 0.42, 0.25)
		crystal.position = Vector3(0.0, 2.15, 0.0)
		root.add_child(crystal)
		parts.append(crystal)
		var l := OmniLight3D.new()
		l.light_color = Color("b07cff")
		l.light_energy = 1.0
		l.omni_range = 3.0
		l.position = Vector3(0.0, 2.1, 0.0)
		root.add_child(l)
		parts.append(l)
		var rubble := _box(Vector3(0.9, 0.25, 0.9), Vector3(0.0, 0.12, 0.0), _stone_mat, root)
		rubble.visible = false
		_tower_nodes.append({"data": tw, "parts": parts, "rubble": rubble, "crystal": crystal})


func _build_nexus() -> void:
	for n in sim.nexi:
		var root := Node3D.new()
		root.position = w3(n["pos"])
		add_child(root)
		var ped := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.85
		cyl.bottom_radius = 1.1
		cyl.height = 0.5
		cyl.radial_segments = 8
		ped.mesh = cyl
		ped.material_override = _stone_mat
		ped.position = Vector3(0.0, 0.25, 0.0)
		root.add_child(ped)
		var crystal := MeshInstance3D.new()
		crystal.mesh = _octahedron()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("c8a0ff")
		mat.emission_enabled = true
		mat.emission = Color("8a52ff")
		mat.emission_energy_multiplier = 1.6
		crystal.material_override = mat
		crystal.scale = Vector3(0.62, 1.25, 0.62)
		crystal.position = Vector3(0.0, 1.9, 0.0)
		root.add_child(crystal)
		var light := OmniLight3D.new()
		light.light_color = Color("a070ff")
		light.light_energy = 2.2
		light.omni_range = 6.5
		light.position = Vector3(0.0, 1.9, 0.0)
		root.add_child(light)
		var shield := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 1.55
		sph.height = 3.1
		sph.radial_segments = 16
		sph.rings = 8
		shield.mesh = sph
		shield.material_override = _unshaded(Color(0.85, 0.24, 0.95, 0.16), true)
		shield.position = Vector3(0.0, 1.5, 0.0)
		root.add_child(shield)
		var rubble := _box(Vector3(1.2, 0.3, 1.0), Vector3(0.0, 0.6, 0.0), _stone_mat, root)
		rubble.rotation.y = 0.4
		rubble.visible = false
		_nexus_nodes.append({"data": n, "crystal": crystal, "mat": mat, "light": light, "shield": shield, "rubble": rubble})
	if sim.escort != null:
		_escort_light = OmniLight3D.new()
		_escort_light.light_color = Color("ffd45a")
		_escort_light.light_energy = 1.6
		_escort_light.omni_range = 3.5
		add_child(_escort_light)


func _octahedron() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0, 1, 0)
	var bottom := Vector3(0, -1, 0)
	var ring := [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)]
	for i in range(4):
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 4]
		for v in [top, b, a, bottom, a, b]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


func _build_barrier() -> void:
	var y := BattleSim.BARRIER_Y
	var strip := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(9.0, 0.12)
	strip.mesh = pm
	_barrier_mat = _unshaded(Color("f2c46b"))
	strip.material_override = _barrier_mat
	strip.position = w3(Vector2(4.5, y), 0.025)
	add_child(strip)
	var x := 0.0
	while x <= 9.0:
		var post := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.08, 0.32, 0.08)
		post.mesh = bm
		post.material_override = _barrier_mat
		post.position = w3(Vector2(x, y), 0.16)
		add_child(post)
		x += 1.5
	_barrier_shield = MeshInstance3D.new()
	var sm := PlaneMesh.new()
	sm.size = Vector2(9.0, 0.08)
	_barrier_shield.mesh = sm
	_barrier_shield.material_override = _unshaded(Color("4fe3d2"))
	_barrier_shield.position = w3(Vector2(4.5, y + 0.2), 0.03)
	add_child(_barrier_shield)


func _build_units() -> void:
	var tex := SpriteAtlas.texture()
	_units_mm = MultiMesh.new()
	_units_mm.transform_format = MultiMesh.TRANSFORM_3D
	_units_mm.use_colors = true
	_units_mm.use_custom_data = true
	_units_mm.mesh = _quad_mesh()
	_units_mm.instance_count = MAX_SPRITES
	_units_mm.visible_instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = _units_mm
	var mat := ShaderMaterial.new()
	mat.shader = _billboard
	mat.set_shader_parameter("atlas", tex)
	mi.material_override = mat
	mi.custom_aabb = AABB(Vector3(-5.0, -2.0, -22.0), Vector3(20.0, 10.0, 28.0))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_shadow_mm = MultiMesh.new()
	_shadow_mm.transform_format = MultiMesh.TRANSFORM_3D
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.0, 1.0)
	_shadow_mm.mesh = plane
	_shadow_mm.instance_count = MAX_SHADOWS
	_shadow_mm.visible_instance_count = 0
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _shadow_mm
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_texture = WorldArt.blob_texture()
	smat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	smi.material_override = smat
	smi.custom_aabb = mi.custom_aabb
	add_child(smi)


func _build_casters() -> void:
	var tex := SpriteAtlas.texture()
	for c in sim.casters:
		var s := Sprite3D.new()
		s.texture = tex
		s.region_enabled = true
		s.pixel_size = TEXEL
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		s.shaded = false
		s.modulate = Color(1.1, 1.1, 1.15)
		add_child(s)
		_casters.append(s)
	_staff_fx = CPUParticles3D.new()
	_staff_fx.amount = 22
	_staff_fx.lifetime = 0.9
	_staff_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_staff_fx.emission_sphere_radius = 0.22
	_staff_fx.direction = Vector3(0, 1, 0)
	_staff_fx.spread = 180.0
	_staff_fx.initial_velocity_min = 0.2
	_staff_fx.initial_velocity_max = 0.6
	_staff_fx.gravity = Vector3(0, 0.4, 0)
	_staff_fx.tangential_accel_min = 2.0
	_staff_fx.tangential_accel_max = 4.0
	_staff_fx.mesh = _particle_mesh(0.07)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.55, 1.0, 0.95, 1.0))
	ramp.set_color(1, Color(0.75, 0.45, 1.0, 0.0))
	_staff_fx.color_ramp = ramp
	add_child(_staff_fx)
	if healed:
		var ff := CPUParticles3D.new()
		ff.amount = 48
		ff.lifetime = 6.0
		ff.preprocess = 6.0
		ff.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		ff.emission_box_extents = Vector3(6.0, 1.2, 9.0)
		ff.position = Vector3(4.5, 1.4, -8.0)
		ff.direction = Vector3(0, 1, 0)
		ff.spread = 180.0
		ff.initial_velocity_min = 0.05
		ff.initial_velocity_max = 0.25
		ff.gravity = Vector3.ZERO
		ff.mesh = _particle_mesh(0.06)
		var fr := Gradient.new()
		fr.set_color(0, Color(0.95, 0.9, 0.45, 0.0))
		fr.add_point(0.3, Color(0.95, 0.9, 0.45, 1.0))
		fr.add_point(0.7, Color(0.85, 1.0, 0.55, 1.0))
		fr.set_color(fr.get_point_count() - 1, Color(0.85, 1.0, 0.55, 0.0))
		ff.color_ramp = fr
		add_child(ff)
	_staff_light = OmniLight3D.new()
	_staff_light.light_color = Color("4fe3d2")
	_staff_light.light_energy = 1.2
	_staff_light.omni_range = 3.2
	add_child(_staff_light)


func _build_fx() -> void:
	_fx_lines = ImmediateMesh.new()
	_fx_points = ImmediateMesh.new()
	_fx_mat = StandardMaterial3D.new()
	_fx_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fx_mat.vertex_color_use_as_albedo = true
	_fx_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fx_pt_mat = _fx_mat.duplicate()
	_fx_pt_mat.use_point_size = true
	_fx_pt_mat.point_size = 3.0
	for m in [_fx_lines, _fx_points]:
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.custom_aabb = AABB(Vector3(-10.0, -2.0, -25.0), Vector3(30.0, 12.0, 32.0))
		add_child(mi)
	for i in range(28):
		var l := _label(56, Color.WHITE)
		l.visible = false
		add_child(l)
		_labels.append(l)


# ---------------------------------------------------------------- évènements

func consume_events(events: Array[Dictionary]) -> void:
	for e in events:
		match str(e["t"]):
			"barrier":
				shake = 0.25
			"shake":
				shake = 0.45
			"flash":
				flash = 0.35
			"text":
				_spawn_label(e)
			"dragon":
				_spawn_dragon(float(e["y"]), float(e.get("dur", 1.1)))
			"prop_hit", "prop_fall", "prop_crash", "wall", "wall_break":
				if _terrain_view != null:
					_terrain_view.handle(e)
			_:
				# Animations de sorts (projectiles, zones, foudre…) : SpellFx ; le reste en traits.
				if _spell_fx == null or not _spell_fx.handle(e):
					var d := e.duplicate()
					d["age"] = 0.0
					if not d.has("dur"):
						d["dur"] = 0.35
					_fx.append(d)
	while _fx.size() > 320:
		_fx.remove_at(0)


func _spawn_label(e: Dictionary) -> void:
	var l := _labels[_label_next]
	_label_next = (_label_next + 1) % _labels.size()
	l.text = str(e["text"])
	l.modulate = Color(str(e.get("color", "FFFFFF")))
	l.position = w3(e["pos"], 1.2)
	l.set_meta("age", 0.0)
	l.visible = true


# ---------------------------------------------------------------- mise à jour

func _process(delta: float) -> void:
	if sim == null or cam == null:
		return
	t += delta
	shake = maxf(0.0, shake - delta)
	flash = maxf(0.0, flash - delta)
	cam.transform = _cam_base
	if shake > 0.0:
		cam.position += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * shake * 0.5
	_update_portals()
	_update_pylons()
	if desert:
		var want := 1.0 if sim.is_day else 0.0
		if not is_equal_approx(_day_k, want):
			_day_k = move_toward(_day_k, want, delta * 0.6)
			_apply_daylight()
	if not sim.fog.is_empty():
		_update_fog_banks()
	if not sim.fires.is_empty() or not _fire_nodes.is_empty():
		_update_fires(delta)
	if not _dragons.is_empty():
		_update_dragons(delta)
	if sim.boss != null:
		_boss_lift = move_toward(_boss_lift, 1.8 if (sim.boss.alive and sim.boss.airborne_t > 0.0) else 0.0, delta * 2.4)
	_update_towers()
	_update_nexus()
	_update_barrier()
	_update_units()
	_update_casters()
	_update_labels(delta)
	_draw_fx(delta)
	if _terrain_view != null:
		_terrain_view.update(delta)
	for l in _torch_lights:
		l.light_energy = 1.25 + 0.25 * sin(t * 11.0 + l.position.x) + 0.1 * sin(t * 23.0)


## Désert de Verre : soleil doré le jour, lune bleutée la nuit (lumière, ambiance, brouillard).
func _apply_daylight() -> void:
	if _sun == null or _env == null:
		return
	var k := _day_k
	_sun.light_color = Color("8aa0e8").lerp(Color("fff0c8"), k)
	_sun.light_energy = lerpf(0.75, 1.25, k)
	_env.ambient_light_color = Color("6a70b0").lerp(Color("e8c890"), k)
	_env.ambient_light_energy = lerpf(0.85, 1.0, k)
	_env.fog_light_color = Color("2a2a5a").lerp(Color("c89a5a"), k)


func _update_portals() -> void:
	# Portails qui apparaissent (énigmes du Sphinx) ou disparaissent en cours de combat.
	if _portal_nodes.size() != sim.portals.size() or _portals_changed():
		_sync_portal_nodes()
	for pn in _portal_nodes:
		var p: Portal = pn["portal"]
		var root: Node3D = pn["root"]
		root.position.x = p.x
		# Mirage : il ondule légèrement ; dissipé, il s'efface puis disparaît jusqu'à se reformer.
		root.visible = p.hidden_t <= 0.0
		if p.mirage:
			root.position.y = 0.04 * sin(t * 3.0 + float(p.id))
			root.scale = Vector3.ONE * (1.0 - 0.6 * clampf(1.0 - p.revealed_t / 1.2, 0.0, 1.0) if p.revealed_t > 0.0 else 1.0)
		var col := p.color()
		var dim := (p.kind == "add" and not p.ready) or (p.kind == "sub" and p.charges <= 0)
		var a := 0.3 + 0.08 * sin(t * 4.0 + float(p.id))
		if dim:
			a = 0.1
		if p.charged_t > 0.0 and not p.is_negative():
			a = 0.55 + 0.2 * sin(t * 14.0)
		if p.flash_t > 0.0:
			a = 0.75
		(pn["panel"] as StandardMaterial3D).albedo_color = Color(col, a)
		(pn["strip"] as StandardMaterial3D).albedo_color = col if not dim else col.darkened(0.5)
		var lab: Label3D = pn["label"]
		var text := p.label()
		if lab.text != text:
			lab.text = text
		lab.modulate = Color(1, 1, 1, 0.55) if dim else Color.WHITE
		var seal: Label3D = pn["seal"]
		seal.visible = p.is_seal and not p.purified
		if seal.visible:
			seal.text = "SCEAU %d/%d" % [p.purity, p.purity_needed]
		(pn["light"] as OmniLight3D).light_color = col
		(pn["light"] as OmniLight3D).light_energy = 2.4 if p.charged_t > 0.0 and not p.is_negative() else 0.9


func _update_towers() -> void:
	for tn in _tower_nodes:
		var alive: bool = tn["data"]["alive"]
		for n in tn["parts"]:
			(n as Node3D).visible = alive
		(tn["rubble"] as Node3D).visible = not alive
		if alive:
			var c: MeshInstance3D = tn["crystal"]
			c.rotation.y = t * 1.5
			c.position.y = 2.15 + sin(t * 2.0) * 0.06


func _update_nexus() -> void:
	var sealed := sim.nexus_shielded()
	for nn in _nexus_nodes:
		var n: Dictionary = nn["data"]
		var alive: bool = n["alive"]
		var crystal: MeshInstance3D = nn["crystal"]
		crystal.visible = alive
		(nn["light"] as OmniLight3D).visible = alive
		(nn["rubble"] as Node3D).visible = not alive
		(nn["shield"] as MeshInstance3D).visible = alive and sealed
		if not alive:
			continue
		crystal.rotation.y = t * 0.7
		crystal.position.y = 1.9 + sin(t * 1.6) * 0.1
		(nn["mat"] as StandardMaterial3D).emission_energy_multiplier = 1.6 + (2.5 if float(n["flash"]) > 0.0 else 0.0)
		(nn["light"] as OmniLight3D).light_energy = 2.0 + 0.4 * sin(t * 3.0)
		var sh: MeshInstance3D = nn["shield"]
		if sh.visible:
			sh.rotation.y = t * 0.5
			var k := 1.0 + 0.03 * sin(t * 4.0)
			sh.scale = Vector3(k, k, k)
	if _escort_light != null and sim.escort != null:
		_escort_light.visible = sim.escort.alive
		var ep := sim.escort.prev_pos.lerp(sim.escort.pos, alpha)
		_escort_light.position = w3(ep, 1.4)
		_escort_light.light_energy = 1.5 + 0.2 * sin(t * 7.0)


func _update_barrier() -> void:
	_barrier_mat.albedo_color = Color("ff5a5a") if sim.barrier_flash > 0.0 else Color("f2c46b")
	_barrier_shield.visible = sim.barrier_shield > 0.0


func _update_units() -> void:
	var cam_right := cam.global_transform.basis.x
	var cam_back := cam.global_transform.basis.z
	var n := 0
	var sn := 0
	for u in sim.allies:
		if n >= MAX_SPRITES - 3:
			break
		n = _put_unit(u, n, cam_right, cam_back)
		sn = _put_shadow(u, sn)
	for u in sim.enemies:
		if n >= MAX_SPRITES - 3:
			break
		n = _put_unit(u, n, cam_right, cam_back)
		sn = _put_shadow(u, sn)
	var orb_a := SpriteAtlas.frame("orb", "", 0)
	var orb_b := SpriteAtlas.frame("orb", "", 1)
	for o in sim.orbs:
		if not o["alive"] or n >= MAX_SPRITES - 2:
			continue
		var op: Vector2 = o["pos"]
		var fr: Dictionary = orb_a if int(t * 4.0 + op.x) % 3 != 0 else orb_b
		var oh := SpriteAtlas.height_m("orb")
		var ouv: Rect2 = fr["uv"]
		_units_mm.set_instance_transform(n, Transform3D(Basis.from_scale(Vector3(oh, oh, 1.0)), w3(op, 0.45 + sin(t * 2.5 + op.y) * 0.12)))
		_units_mm.set_instance_color(n, Color(1.6, 1.5, 1.0))
		_units_mm.set_instance_custom_data(n, Color(ouv.position.x, ouv.position.y, ouv.size.x, ouv.size.y))
		n += 1
	for tn in _tower_nodes:
		var tw: Dictionary = tn["data"]
		if tw["alive"] and float(tw["hp"]) < float(tw["max"]) and n < MAX_SPRITES - 2:
			n = _put_bar(w3(tw["pos"], 2.75), float(tw["hp"]) / float(tw["max"]), Color("ff6b8a"), n, cam_right, cam_back)
	_units_mm.visible_instance_count = n
	_shadow_mm.visible_instance_count = sn


func _put_unit(u: Unit, n: int, cam_right: Vector3, cam_back: Vector3) -> int:
	if not u.alive:
		return n
	var lp := u.prev_pos.lerp(u.pos, alpha)
	var moving := not u.engaged and u.speed_factor() > 0.0
	var fr := SpriteAtlas.frame(u.sprite, u.element, int(u.anim * 6.0) if moving else 0)
	var h := SpriteAtlas.height_m(u.sprite)
	var w := h * float(fr["w"]) / float(fr["h"])
	var bob := absf(sin(u.anim * 9.0)) * 0.035 if moving else 0.0
	if u == sim.boss and _boss_lift > 0.0:
		bob += _boss_lift + sin(t * 2.2) * 0.12
	var pos := w3(lp, bob)
	_units_mm.set_instance_transform(n, Transform3D(Basis.from_scale(Vector3(w, h, 1.0)), pos))
	_units_mm.set_instance_color(n, _tint(u))
	var uv: Rect2 = fr["uv"]
	_units_mm.set_instance_custom_data(n, Color(uv.position.x, uv.position.y, uv.size.x, uv.size.y))
	n += 1
	var big := ((u.team == 1 and u.max_hp >= 25.0) or u.role == "champion" or u.role == "elite") and not u.fogged
	if big and u.hp < u.max_hp:
		n = _put_bar(pos + Vector3(0.0, h + 0.12, 0.0), clampf(u.hp / u.max_hp, 0.0, 1.0), Color("ff6b8a") if u.team == 1 else Color("6fe39a"), n, cam_right, cam_back)
	if u.role == "soigneur":
		var cr := SpriteAtlas.frame("cross")
		var cuv: Rect2 = cr["uv"]
		var ch := SpriteAtlas.height_m("cross")
		_units_mm.set_instance_transform(n, Transform3D(Basis.from_scale(Vector3(ch, ch, 1.0)), pos + Vector3(0.0, h + 0.22, 0.0) + cam_back * 0.02))
		_units_mm.set_instance_color(n, Color(1.4, 1.4, 1.4))
		_units_mm.set_instance_custom_data(n, Color(cuv.position.x, cuv.position.y, cuv.size.x, cuv.size.y))
		n += 1
	return n


func _put_bar(pos: Vector3, frac: float, col: Color, n: int, cam_right: Vector3, cam_back: Vector3) -> int:
	var px := SpriteAtlas.frame("px")
	var uv: Rect2 = px["uv"]
	var custom := Color(uv.position.x, uv.position.y, uv.size.x, uv.size.y)
	_units_mm.set_instance_transform(n, Transform3D(Basis.from_scale(Vector3(BAR_W, 0.06, 1.0)), pos))
	_units_mm.set_instance_color(n, Color(0.08, 0.05, 0.12))
	_units_mm.set_instance_custom_data(n, custom)
	var fw := BAR_W * frac
	var fpos := pos + cam_right * (-(BAR_W - fw) * 0.5) + cam_back * 0.015
	_units_mm.set_instance_transform(n + 1, Transform3D(Basis.from_scale(Vector3(maxf(0.001, fw), 0.06, 1.0)), fpos))
	_units_mm.set_instance_color(n + 1, col)
	_units_mm.set_instance_custom_data(n + 1, custom)
	return n + 2


func _put_shadow(u: Unit, sn: int) -> int:
	if not u.alive or sn >= MAX_SHADOWS:
		return sn
	var lp := u.prev_pos.lerp(u.pos, alpha)
	var r := u.radius
	_shadow_mm.set_instance_transform(sn, Transform3D(Basis.from_scale(Vector3(r * 2.6, 1.0, r * 1.5)), w3(lp, 0.012)))
	return sn + 1


func _tint(u: Unit) -> Color:
	if u.fogged and u.flash_t <= 0.0:
		return Color(0.38, 0.44, 0.42)
	if u == sim.boss and sim.boss_shield_t > 0.0:
		return Color(0.95, 0.7, 0.45) if u.flash_t <= 0.0 else Color(1.3, 1.0, 0.7)
	if u.flash_t > 0.0:
		if u.role == "boss":
			return Color(1.2, 1.05, 1.05)
		return Color(1.9, 0.75, 0.75) if u.team == 1 else Color(1.8, 1.8, 1.8)
	if u.frozen_t > 0.0:
		return Color(0.65, 0.9, 1.45)
	if u.rooted_t > 0.0 or u.zone_slow > 0.0:
		return Color(0.85, 1.2, 0.6)
	if u.burn_t > 0.0 and int(t * 10.0) % 2 == 0:
		return Color(1.5, 0.95, 0.6)
	if u.weak_t > 0.0 and int(t * 6.0) % 3 == 0:
		return Color(0.85, 0.7, 1.3)
	if u.bleed_t > 0.0 and int(t * 9.0) % 3 == 0:
		return Color(1.55, 0.6, 0.6)
	if u.poison_t > 0.0 and int(t * 8.0) % 3 == 0:
		return Color(0.8, 1.3, 0.75)
	if u.team == 0:
		return Color(1.12, 1.12, 1.18)
	return Color.WHITE


func _update_casters() -> void:
	var cam_right := cam.global_transform.basis.x
	var cam_up := cam.global_transform.basis.y
	for i in range(_casters.size()):
		var c := sim.casters[i]
		var s := _casters[i]
		var x := lerpf(c.prev_x, c.x, alpha)
		var moving := absf(c.x - c.prev_x) > 0.001 or c.firing
		var fr := SpriteAtlas.frame(c.sprite, "", int(t * 5.0) if moving else 0)
		var px: Rect2i = fr["px"]
		s.region_rect = Rect2(px)
		s.pixel_size = SpriteAtlas.height_m(c.sprite) / float(px.size.y)
		s.offset = Vector2(0.0, float(px.size.y) * 0.5)
		s.position = w3(Vector2(x, BattleSim.CASTER_Y), 0.0)
		if i == 0:
			var wm := float(px.size.x) * s.pixel_size
			var hm := float(px.size.y) * s.pixel_size
			var tip := s.position + cam_right * (0.39 * wm) + cam_up * (0.93 * hm)
			_staff_fx.position = tip
			_staff_fx.emitting = c.firing
			_staff_light.position = tip
			_staff_light.light_energy = 1.6 if c.firing else 0.7


func _update_labels(delta: float) -> void:
	for l in _labels:
		if not l.visible:
			continue
		var age := float(l.get_meta("age", 0.0)) + delta
		l.set_meta("age", age)
		if age >= 0.9:
			l.visible = false
			continue
		l.position.y += delta * 0.9
		l.modulate.a = 1.0 - age / 0.9


func _draw_fx(delta: float) -> void:
	var i := 0
	while i < _fx.size():
		var e: Dictionary = _fx[i]
		e["age"] = float(e["age"]) + delta
		if float(e["age"]) >= float(e["dur"]):
			_fx.remove_at(i)
		else:
			i += 1
	_fx_lines.clear_surfaces()
	_fx_points.clear_surfaces()
	var lines: Array = [] # [Vector3, Vector3, Color]
	var points: Array = [] # [Vector3, Color]
	for e in _fx:
		var k := float(e["age"]) / float(e["dur"])
		var col := Color(str(e.get("color", "FFFFFF")))
		match str(e["t"]):
			"ring":
				_ring(lines, e["pos"], float(e["r"]) * (0.45 + 0.55 * k), Color(col, 1.0 - k), 0.06)
				if k < 0.35:
					_ring(lines, e["pos"], float(e["r"]) * 0.3 * (1.0 + k), Color(col, 0.6 * (1.0 - k)), 0.06)
			"beam":
				lines.append([w3(e["a"], 0.45), w3(e["b"], 0.35), Color(col, 1.0 - k)])
			"puff":
				var c := w3(e["pos"], 0.3 + k * 0.4)
				var d := 0.1 + k * 0.35
				var cc := Color(col, 1.0 - k)
				for o in [Vector3(-d, 0, 0), Vector3(d, 0, 0), Vector3(0, d, 0), Vector3(0, 0, d), Vector3(0, 0, -d)]:
					points.append([c + o, cc])
	# Attaques annoncées (zones rouges) et impacts.
	for tg in sim.telegraphs:
		var k2 := 1.0 - float(tg["t"]) / maxf(0.01, float(tg["dur"]))
		var pulse := 0.5 + 0.5 * sin(t * (10.0 + 14.0 * k2))
		var tcol := Color(0.85, 0.95, 1.0) if bool(tg.get("avalanche", false)) else (Color(1.0, 0.82, 0.35) if bool(tg.get("sun", false)) else Color(1.0, 0.25, 0.3))
		if bool(tg.get("dragon", false)) or bool(tg.get("fire", false)):
			tcol = Color(1.0, 0.55, 0.15)
		_rect(lines, tg["rect"], Color(tcol, 0.45 + 0.5 * pulse), true)
	# Plaies de l'Hydre : cercle orange qui se resserre (brûle-les avant 5 s).
	for st in sim.stumps:
		var left := clampf(float(st["t"]) / BattleSim.STUMP_TIME, 0.0, 1.0)
		var pulse2 := 0.5 + 0.5 * sin(t * (8.0 + 10.0 * (1.0 - left)))
		_ring(lines, st["pos"], 0.4 + 0.5 * left, Color(1.0, 0.6, 0.2, 0.5 + 0.5 * pulse2), 0.08)
		_ring(lines, st["pos"], 0.25, Color(0.6, 1.0, 0.3, 0.8), 0.08)
	for e in _fx:
		if str(e["t"]) == "strike":
			var k3 := float(e["age"]) / float(e["dur"])
			_rect(lines, e["rect"], Color(1.0, 0.85, 0.6, 1.0 - k3), true)
	# Ligne de visée du joueur et cercle de ciblage.
	var px := lerpf(sim.player().prev_x, sim.player().x, alpha)
	var y := BattleSim.CASTER_Y + 1.2
	while y < BattleSim.H - 1.0:
		lines.append([w3(Vector2(px, y), 0.04), w3(Vector2(px, y + 0.25), 0.04), Color(0.31, 0.89, 0.82, 0.35)])
		y += 0.6
	if aim_active and aim_pos.x > -50.0:
		_ring(lines, aim_pos, aim_radius, Color(aim_color, 0.95), 0.07)
		_ring(lines, aim_pos, aim_radius * 0.15, Color(aim_color, 0.95), 0.07)
	if _spell_fx != null:
		_spell_fx.collect(lines, points)
	if not lines.is_empty():
		_fx_lines.surface_begin(Mesh.PRIMITIVE_LINES, _fx_mat)
		for l in lines:
			_fx_lines.surface_set_color(l[2])
			_fx_lines.surface_add_vertex(l[0])
			_fx_lines.surface_set_color(l[2])
			_fx_lines.surface_add_vertex(l[1])
		_fx_lines.surface_end()
	if not points.is_empty():
		_fx_points.surface_begin(Mesh.PRIMITIVE_POINTS, _fx_pt_mat)
		for p in points:
			_fx_points.surface_set_color(p[1])
			_fx_points.surface_add_vertex(p[0])
		_fx_points.surface_end()


func _rect(lines: Array, r: Rect2, col: Color, hatch: bool) -> void:
	var a := r.position
	var b := r.end
	var h := 0.07
	var corners := [Vector2(a.x, a.y), Vector2(b.x, a.y), Vector2(b.x, b.y), Vector2(a.x, b.y)]
	for i in range(4):
		lines.append([w3(corners[i], h), w3(corners[(i + 1) % 4], h), col])
	if hatch:
		# Hachures à 45° (droites x - y = c) découpées dans le rectangle.
		var c := a.x - b.y
		while c < b.x - a.y:
			var x0 := maxf(a.x, a.y + c)
			var x1 := minf(b.x, b.y + c)
			if x1 > x0:
				lines.append([w3(Vector2(x0, x0 - c), h), w3(Vector2(x1, x1 - c), h), Color(col, col.a * 0.55)])
			c += 0.34


func _ring(lines: Array, center: Vector2, r: float, col: Color, h: float) -> void:
	var seg := 28
	for s in range(seg):
		var a0 := TAU * float(s) / float(seg)
		var a1 := TAU * float(s + 1) / float(seg)
		lines.append([w3(center + Vector2(cos(a0), sin(a0)) * r, h), w3(center + Vector2(cos(a1), sin(a1)) * r, h), col])


# ---------------------------------------------------------------- zone 6 · Forêt Cendrée

## Incendies et foyers : un sol rougeoyant et des flammes en billboard, qui suivent le front du couloir.
func _update_fires(delta: float) -> void:
	var seen := {}
	for f in sim.fires:
		var id := int(f["id"])
		seen[id] = true
		if not _fire_nodes.has(id):
			_fire_nodes[id] = _make_fire_node(f)
		var fn: Dictionary = _fire_nodes[id]
		var r := sim.fire_rect(f)
		var root: Node3D = fn["root"]
		root.position = w3(r.get_center(), 0.0)
		var gm: MeshInstance3D = fn["ground"]
		(gm.mesh as PlaneMesh).size = Vector2(maxf(0.05, r.size.x), maxf(0.05, r.size.y))
		var cool := float(f.get("cool", 0.0)) > 0.0
		var lava := bool(f.get("lava", false))
		var mat: StandardMaterial3D = fn["mat"]
		var flick := 0.75 + 0.25 * sin(t * 9.0 + float(id))
		mat.albedo_color = Color(0.35, 0.3, 0.3, 0.5) if cool else (Color(1.0, 0.42, 0.12, 0.55 * flick) if not lava else Color(1.0, 0.35, 0.08, 0.7 * flick))
		var flames: Array = fn["flames"]
		var n := flames.size()
		for k in range(n):
			var fl: Array = flames[k]
			var spr: Sprite3D = fl[0]
			var u := float(fl[1])
			var ox := float(fl[2])
			var on := not cool and (r.size.y > 0.4 or k < 2)
			spr.visible = on
			if not on:
				continue
			var p := Vector2(r.get_center().x + ox * r.size.x * 0.45, r.position.y + u * r.size.y)
			var s := 0.55 + 0.25 * sin(t * 7.0 + float(k) * 1.7)
			spr.position = w3(p, 0.32 * s) - root.position
			spr.pixel_size = 0.11 * s
			spr.modulate = Color(1.3, 0.9, 0.6, 0.9)
	for id in _fire_nodes.keys():
		if not seen.has(id):
			(_fire_nodes[id]["root"] as Node3D).queue_free()
			_fire_nodes.erase(id)


func _make_fire_node(f: Dictionary) -> Dictionary:
	var root := Node3D.new()
	add_child(root)
	var gm := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.0, 1.0)
	gm.mesh = pm
	gm.position = Vector3(0.0, 0.03, 0.0)
	var mat := _unshaded(Color(1.0, 0.42, 0.12, 0.5), true)
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.material_override = mat
	root.add_child(gm)
	var flames: Array = []
	var count := 3 if bool(f["patch"]) else 9
	for k in range(count):
		var spr := Sprite3D.new()
		spr.texture = WorldArt.flame_texture()
		spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		spr.shaded = false
		spr.transparent = true
		spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		root.add_child(spr)
		flames.append([spr, (float(k) + 0.5) / float(count), randf_range(-1.0, 1.0)])
	return {"root": root, "ground": gm, "mat": mat, "flames": flames}


## Passage d'un dragon : sa silhouette traverse la rangée mitraillée, son ombre glisse au sol.
func _spawn_dragon(y: float, dur: float) -> void:
	var spr := Sprite3D.new()
	spr.texture = SpriteAtlas.single("ash_wyrm", 0)
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.shaded = false
	spr.transparent = true
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.pixel_size = 2.6 / 18.0
	spr.modulate = Color(0.25, 0.12, 0.1, 0.95)
	add_child(spr)
	var sh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3.2, 1.4)
	sh.mesh = pm
	sh.material_override = _unshaded(Color(0.0, 0.0, 0.0, 0.35), true)
	add_child(sh)
	var dir := 1.0 if randf() < 0.5 else -1.0
	_dragons.append({"spr": spr, "shadow": sh, "y": y, "age": 0.0, "dur": dur * 1.6, "dir": dir})
	shake = maxf(shake, 0.3)


func _update_dragons(delta: float) -> void:
	var i := 0
	while i < _dragons.size():
		var d: Dictionary = _dragons[i]
		d["age"] = float(d["age"]) + delta
		var k := float(d["age"]) / float(d["dur"])
		if k >= 1.0:
			(d["spr"] as Node3D).queue_free()
			(d["shadow"] as Node3D).queue_free()
			_dragons.remove_at(i)
			continue
		var x := lerpf(-3.0, BattleSim.W + 3.0, k) if float(d["dir"]) > 0.0 else lerpf(BattleSim.W + 3.0, -3.0, k)
		(d["spr"] as Sprite3D).position = w3(Vector2(x, float(d["y"])), 3.2 + sin(k * PI) * 0.6)
		(d["shadow"] as MeshInstance3D).position = w3(Vector2(x, float(d["y"])), 0.04)
		i += 1
