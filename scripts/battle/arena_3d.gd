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
var _chimneys: Array[Vector3] = [] ## cheminées des chaumières (fumée)
var _pulse: Array = [] ## lueurs qui pulsent : [lumière, énergie, phase]
var _pylon_nodes: Array[Dictionary] = []
var _terrain_view: TerrainView
var _moss_cap: StandardMaterial3D
var day := false ## Zone 2 : Collines d'Ambre en plein jour.
var swamp := false ## Zone 3 : Marais Murmurants au crépuscule.
var frost := false ## Zone 4 : Pics Gelés, nuit d'aurore boréale.
var desert := false ## Zone 5 : Désert de Verre ; la lumière suit le cycle soleil/lune de la simulation.
var cinder := false ## Zone 6 : Forêt Cendrée, ciel de fumée rougeoyant, incendies et dragons.
var abyss := false ## Zone 7 : Cité Engloutie, lumière bleue sous-marine, marée, courants, tourbillons.
var _water: MeshInstance3D
var _water_mat: StandardMaterial3D
var _fire_nodes: Dictionary = {} ## id du foyer -> {root, ground, mat, flames}
var _dragons: Array[Dictionary] = [] ## passages de dragons en cours : {spr, shadow, y, age, dur, dir}
var _boss_lift := 0.0 ## hauteur du boss en vol (Drake ancien, Wyrm de cendre)
var _sun: DirectionalLight3D
var _day_k := 1.0 ## 1 = plein jour, 0 = nuit (transition douce)
var _fog_nodes: Array[Dictionary] = []
var _storm := false ## Collines d'Ambre sous l'orage (2-6, 2-10) : pluie, éclairs
var _storm_t := 3.0
var _bolt_k := 0.0
var _kick: Array[float] = [] ## recul de chaque lanceur quand il tire (1 → 0)
var _dt := 0.0
## Hauteur de vol des tirs de classe (au-dessus du sol).
const SHOT_LIFT := {"fleche": 0.3, "onde": 0.05, "lumiere": 0.75, "bouclier": 0.22, "hache": 0.24}
const SHOT_FPS := {"fleche": 7.0, "onde": 10.0, "lumiere": 6.0, "bouclier": 14.0, "hache": 18.0}
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
	abyss = WorldArt.zone == 7
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
	var pm := _pillar_mats()
	_terrain_view.setup(sim, pm[0], pm[1], _spell_fx)
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
	elif abyss:
		_env.ambient_light_color = Color("6aa8c8")
		_env.ambient_light_energy = 1.0
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
	elif abyss:
		_env.fog_light_color = Color("0e4a6a")
	_storm = WorldArt.scene in WorldArt.STORM_SCENES
	if _storm:
		# Orage sur les Collines : lumière grise et froide, brume sombre.
		_env.ambient_light_color = Color("9a98b0")
		_env.ambient_light_energy = 0.8
		_env.fog_light_color = Color("4a4a5e")
	if WorldArt.zone == 1 and WorldArt.scene != "" and WorldArt.scene != "pont" and not healed:
		# Lumière propre au lieu : chaude à la lisière, bleue sous la lune des fougères, rose au cercle des fées,
		# violette là où le Surge s'est enraciné.
		var amb: Dictionary = {"lisiere": ["c8a8a0", "4a3a50"], "sentier": ["8890c8", "2a3a4e"], "clairiere": ["90a8b8", "2d3c4e"],
			"roncier": ["9a78c0", "3a2450"], "fougeres": ["9ab0e8", "2a3a6a"], "cercle": ["c890c8", "4a2a50"], "source": ["80b8c8", "1f4050"],
			"coeur": ["b070d0", "3a1a50"], "sylvarche": ["9070b8", "2a1a40"]}
		var pair: Array = amb.get(WorldArt.scene, ["7078c0", "2d2c5e"])
		# Une nuance seulement : la lumière de nuit du Bois reste la base (contraste, couleurs profondes).
		_env.ambient_light_color = Color("7078c0").lerp(Color(str(pair[0])), 0.3)
		_env.fog_light_color = Color("2d2c5e").lerp(Color(str(pair[1])), 0.5)
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
	elif abyss:
		moon.light_color = Color("a8e8ff")
	moon.light_energy = 1.1
	if _storm:
		moon.light_color = Color("b8c0e0")
		moon.light_energy = 0.55
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
	# Zones 1 et 2 : chaque niveau a son lieu ; seul le pont (1-7) est une chaussée au-dessus du vide.
	var sc := WorldArt.scene
	var floor_set := sc != "" and sc != "pont"
	var pal := WorldArt.scene_palette(sc)
	_box(Vector3(WorldArt.GROUND_SIZE.x, 2.6, WorldArt.GROUND_SIZE.y), w3(c, -1.31), _stone_mat)
	if not floor_set:
		for y in [0.5, 5.5, 10.5, 15.5]:
			for x in [0.6, 8.4]:
				_box(Vector3(1.4, 14.0, 1.4), w3(Vector2(x, y), -8.5), _stone_mat)
	# Falaises boisées de part et d'autre (ou, au sol de la forêt, de l'herbe au niveau du chemin).
	var rock := _triplanar(WorldArt.rock_texture(), 0.4)
	var moss := _triplanar(WorldArt.moss_texture(), 0.5)
	if floor_set:
		moss.albedo_color = (pal["moss"] as Color).lerp(Color("3f6a3a"), 0.5).lightened(0.15) if WorldArt.zone == 1 else (pal["moss"] as Color).lightened(0.35)
	for side in [-1, 1]:
		var cx := 4.5 + float(side) * 14.5
		if floor_set:
			# Le sol de la forêt, un peu en contrebas du chemin : la brume s'y couche, comme sous le pont.
			# Ses parois descendent profond : derrière le Nexus, entre elles, s'ouvre le portail sombre d'où
			# viennent les ennemis, comme sur le pont.
			_box(Vector3(18.0, 12.0, 46.0), Vector3(cx, -6.8, -9.0), rock)
			_box(Vector3(18.0, 0.2, 46.0), Vector3(cx, -0.7, -9.0), moss)
			continue
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
	elif abyss:
		layers = [[-1.3, Color("4fa8c8"), 0.45, Vector2(0.014, 0.004)], [-2.8, Color("1a5a7a"), 0.6, Vector2(-0.01, 0.006)]]
	if floor_set:
		# Brume du sol de la forêt, de part et d'autre seulement : le portail derrière le Nexus garde sa
		# brume profonde (les deux nappes d'origine, plus bas).
		var mist_base: Color = (pal["mist"] as Color).lerp(Color("8a8ad0"), 0.4) if WorldArt.zone == 1 else (pal["mist"] as Color)
		var side_mist := [[-0.22, mist_base, 0.45 if WorldArt.zone == 1 else 0.3, Vector2(0.012, 0.004)], [-0.48, (pal["mist"] as Color).darkened(0.35), 0.55 if WorldArt.zone == 1 else 0.4, Vector2(-0.008, 0.006)]]
		for l2 in side_mist:
			for sx: float in [-15.5, 24.5]:
				var smi := MeshInstance3D.new()
				var smp := PlaneMesh.new()
				smp.size = Vector2(30.0, 60.0)
				smi.mesh = smp
				var ssm := ShaderMaterial.new()
				ssm.shader = mist_shader
				ssm.set_shader_parameter("noise_tex", noise)
				ssm.set_shader_parameter("tint", l2[1])
				ssm.set_shader_parameter("strength", l2[2])
				ssm.set_shader_parameter("speed", l2[3])
				smi.material_override = ssm
				smi.position = Vector3(sx, float(l2[0]), -10.0)
				add_child(smi)
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
	# Arbres (billboards verticaux) : sapins ; au sol de la forêt, l'essence suit le lieu.
	var pine := WorldArt.pine_texture() if not floor_set else WorldArt.tree_atlas(sc)
	var frames := 3 if not floor_set else 6
	var weights: Array = {"lisiere": [2, 2, 1, 4, 4, 0], "sentier": [4, 4, 4, 1, 0, 0], "clairiere": [2, 2, 1, 4, 3, 2],
		"roncier": [3, 3, 3, 0, 0, 4], "fougeres": [3, 3, 3, 2, 2, 0], "cercle": [3, 3, 2, 1, 1, 3], "source": [2, 3, 2, 3, 3, 0],
		"coeur": [3, 3, 3, 0, 1, 3], "sylvarche": [3, 3, 2, 1, 2, 2],
		# Collines d'Ambre : arbres isolés, vergers près des moulins, arbres morts sous l'orage.
		"route": [0, 0, 0, 3, 2, 2], "moulins": [0, 0, 0, 4, 4, 1], "pylones": [0, 0, 0, 1, 1, 4], "gue": [0, 0, 0, 3, 3, 1],
		"repaire": [0, 0, 0, 1, 1, 3], "orage": [0, 0, 0, 1, 0, 5], "caravane": [0, 0, 0, 3, 2, 2], "rebouteux": [0, 0, 0, 2, 2, 2],
		"traite": [0, 0, 0, 3, 3, 1], "fort": [0, 0, 0, 0, 1, 5],
		# Marais : saules pleureurs et arbres morts.
		"pilotis": [0, 0, 0, 4, 4, 2], "mares": [0, 0, 0, 2, 2, 4], "brume": [0, 0, 0, 3, 3, 3], "gue_morts": [0, 0, 0, 1, 1, 5],
		"croc": [0, 0, 0, 2, 2, 4], "saules": [0, 0, 0, 5, 5, 1], "barque": [0, 0, 0, 4, 4, 1], "sorciere": [0, 0, 0, 2, 2, 4],
		"refuge": [0, 0, 0, 2, 2, 3], "hydre": [0, 0, 0, 2, 2, 4],
		# Pics : sapins enneigés, quelques arbres morts au col et devant la forteresse.
		"col": [4, 4, 4, 0, 0, 1], "congeres": [4, 4, 3, 0, 0, 1], "porte_naine": [3, 3, 3, 0, 0, 1], "lac_gele": [3, 3, 3, 0, 0, 2],
		"sentinelle": [2, 2, 2, 0, 0, 2], "aurore": [3, 3, 3, 0, 0, 1], "chariot": [4, 4, 4, 0, 0, 1], "portes": [2, 2, 2, 0, 0, 2],
		"forteresse": [2, 2, 2, 0, 0, 2], "colosse": [1, 1, 1, 0, 0, 3],
		# Désert : palmiers à l'oasis, quelques-uns ailleurs, arbres morts.
		"dunes": [0, 0, 0, 1, 1, 2], "mirage": [0, 0, 0, 2, 2, 1], "oasis": [0, 0, 0, 5, 5, 0], "miroirs": [0, 0, 0, 1, 1, 1],
		"scarabee": [0, 0, 0, 1, 1, 3], "caravane_sable": [0, 0, 0, 2, 2, 1], "spectres": [0, 0, 0, 1, 1, 3], "sceaux": [0, 0, 0, 1, 1, 1],
		"college": [0, 0, 0, 1, 1, 1], "sphinx": [0, 0, 0, 1, 1, 2],
		# Forêt Cendrée : sapins et arbres morts calcinés ; au Pardon, des feuillus repoussent.
		"lisiere_cendree": [2, 2, 2, 1, 1, 4], "couloirs": [3, 3, 3, 0, 0, 3], "ailes": [1, 1, 1, 0, 0, 4], "coulee": [0, 0, 0, 0, 0, 5],
		"drake": [1, 1, 0, 0, 0, 4], "braisemont": [1, 1, 1, 1, 1, 3], "nid": [1, 1, 1, 0, 0, 3], "autels": [0, 0, 0, 0, 0, 4],
		"citadelle": [0, 0, 0, 0, 0, 3], "antre": [0, 0, 0, 0, 0, 3], "pardon": [2, 2, 2, 3, 3, 2],
		# Cité Engloutie : forêts d'algues, coraux morts (l'arbre mort, bleui).
		"quais": [0, 0, 0, 3, 3, 1], "grand_canal": [0, 0, 0, 3, 3, 1], "marees": [0, 0, 0, 5, 5, 1], "statues": [0, 0, 0, 3, 3, 1],
		"kraken": [0, 0, 0, 4, 4, 2], "cloche": [0, 0, 0, 3, 3, 1], "sirenes": [0, 0, 0, 5, 5, 0], "archives": [0, 0, 0, 2, 2, 2],
		"palais": [0, 0, 0, 3, 3, 1], "leviathan": [0, 0, 0, 2, 2, 3]}.get(sc, [1, 1, 1, 0, 0, 0])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = _quad_mesh()
	var spots: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	# Densité des arbres selon le lieu : clairsemés à la lisière, serrés sur le sentier.
	var tree_n: int = {"lisiere": 30, "sentier": 120, "clairiere": 44, "roncier": 80, "fougeres": 58, "cercle": 66, "source": 60, "coeur": 84, "sylvarche": 70,
		"route": 22, "moulins": 40, "pylones": 16, "gue": 36, "repaire": 18, "orage": 20, "caravane": 22, "rebouteux": 26, "traite": 26, "fort": 16,
		"pilotis": 44, "mares": 40, "brume": 56, "gue_morts": 34, "croc": 40, "saules": 60, "barque": 40, "sorciere": 50, "refuge": 36, "hydre": 38,
		"col": 80, "congeres": 70, "porte_naine": 50, "lac_gele": 56, "sentinelle": 36, "aurore": 60, "chariot": 76, "portes": 36, "forteresse": 30, "colosse": 20,
		"dunes": 10, "mirage": 14, "oasis": 46, "miroirs": 10, "scarabee": 10, "caravane_sable": 14, "spectres": 12, "sceaux": 10, "college": 12, "sphinx": 12,
		"lisiere_cendree": 50, "couloirs": 90, "ailes": 40, "coulee": 18, "drake": 26, "braisemont": 30, "nid": 40, "autels": 24, "citadelle": 14, "antre": 12, "pardon": 56,
		"quais": 30, "grand_canal": 26, "marees": 70, "statues": 30, "kraken": 50, "cloche": 34, "sirenes": 66, "archives": 20, "palais": 28, "leviathan": 30}.get(sc, 90)
	var dmin: float = {"lisiere": 10.0, "sentier": 6.2, "clairiere": 9.0, "roncier": 7.0, "fougeres": 8.0, "cercle": 7.5, "source": 9.0, "coeur": 6.8, "sylvarche": 7.5}.get(sc, 10.0)
	var ty := -0.7 if floor_set else -2.5
	for i in range(tree_n):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := 4.5 + side * rng.randf_range(dmin, 17.0)
		var y := rng.randf_range(-6.0, 34.0)
		spots.append([Vector3(x, ty, -y), rng.randf_range(3.0, 6.0), _pick(rng, weights) if floor_set else rng.randi_range(0, 2)])
	if not floor_set:
		for i in range(14):
			var side := -1.0 if i % 2 == 0 else 1.0
			spots.append([Vector3(4.5 + side * rng.randf_range(5.6, 7.0), -7.0, -rng.randf_range(-2.0, 22.0)), rng.randf_range(6.0, 8.5), rng.randi_range(0, 2)])
	mm.instance_count = spots.size()
	for i in range(spots.size()):
		var s: Array = spots[i]
		var hgt: float = s[1]
		var tf := Transform3D(Basis.from_scale(Vector3(hgt * (20.0 / 44.0 if not floor_set else 28.0 / 48.0), hgt, 1.0)), s[0])
		mm.set_instance_transform(i, tf)
		var shade := rng.randf_range(0.8, 1.05)
		mm.set_instance_color(i, Color(shade, shade, shade * 1.05) if not (sc in ["coeur", "sylvarche", "roncier"]) else Color(shade * 0.85, shade * 0.7, shade * 1.1))
		var v: int = s[2]
		mm.set_instance_custom_data(i, Color(float(v) / float(frames), 0.0, 1.0 / float(frames), 1.0))
		if floor_set and v == 5 and sc == "cercle":
			mm.set_instance_color(i, Color(1.12, 1.02, 1.12)) ## arbres lumineux du cercle des fées
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


static func _pick(rng: RandomNumberGenerator, weights: Array) -> int:
	var total := 0
	for wv in weights:
		total += int(wv)
	var r := rng.randi_range(1, maxi(1, total))
	for i in range(weights.size()):
		r -= int(weights[i])
		if r <= 0:
			return i
	return 0


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
	if abyss:
		# Bulles qui montent vers la surface.
		ramp = Gradient.new()
		ramp.set_color(0, Color(0.8, 0.95, 1.0, 0.0))
		ramp.set_color(1, Color(0.8, 0.95, 1.0, 0.0))
		ramp.add_point(0.3, Color(0.85, 0.97, 1.0, 0.8))
		ramp.add_point(0.8, Color(0.7, 0.9, 1.0, 0.6))
		ff.amount = 100
		ff.direction = Vector3(0.0, 1.0, 0.0)
		ff.spread = 15.0
		ff.initial_velocity_min = 0.3
		ff.initial_velocity_max = 0.7
		ff.gravity = Vector3(0.03, 0.2, 0.0)
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
	var pal2 := WorldArt.scene_palette(WorldArt.scene)
	if not pal2.is_empty():
		# Lucioles à la couleur du lieu, nombreuses sur le sentier.
		var mc: Color = pal2["motes"]
		ramp = Gradient.new()
		ramp.set_color(0, Color(mc, 0.0))
		ramp.set_color(1, Color(mc, 0.0))
		ramp.add_point(0.2, Color(mc, 1.0))
		ramp.add_point(0.8, Color(mc.lightened(0.2), 0.9))
		ff.amount = {"sentier": 110, "cercle": 70, "coeur": 60, "sylvarche": 60, "source": 50, "lisiere": 24,
			"pylones": 70, "repaire": 50, "fort": 60, "rebouteux": 50}.get(WorldArt.scene, 40)
		if WorldArt.zone == 2 and WorldArt.scene in ["repaire", "fort", "pylones"]:
			# Braises des feux de camp, étincelles d'ambre : elles montent.
			ff.gravity = Vector3(0.05, 0.25, 0.0)
			ff.initial_velocity_max = 0.45
	ff.color_ramp = ramp
	add_child(ff)
	_build_scene_props()
	_build_foliage()
	_build_ambience()


## Objets propres au lieu du combat (zone 1) : sur les bords, au sol de la forêt.
func _build_scene_props() -> void:
	if WorldArt.scene == "":
		return
	if WorldArt.zone == 2:
		_build_hills_props()
		return
	if WorldArt.zone == 3:
		_build_swamp_props()
		return
	if WorldArt.zone == 4:
		_build_frost_props()
		return
	if WorldArt.zone == 5:
		_build_desert_props()
		return
	if WorldArt.zone == 6:
		_build_cinder_props()
		return
	if WorldArt.zone == 7:
		_build_abyss_props()
		return
	var sc := WorldArt.scene
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sc)
	match sc:
		"lisiere":
			var cot := WorldArt.cottage_texture()
			for i in range(6):
				var side := -1.0 if i % 2 == 0 else 1.0
				var cp := Vector2(4.5 + side * rng.randf_range(7.0, 8.5), 1.5 + float(i / 2) * 6.0 + rng.randf_range(-1.0, 1.0))
				_prop(cot, cp, 1.6)
				_chimneys.append(w3(cp + Vector2(0.25, 0.0), -0.7 + 30.0 * TEXEL * 1.6))
			var lamp := WorldArt.lamp_texture()
			for i in range(6):
				var side2 := -1.0 if i % 2 == 0 else 1.0
				var lp := Vector2(4.5 + side2 * 5.9, 1.0 + float(i / 2) * 6.0)
				_prop(lamp, lp, 1.0)
				_prop_light(lp, 1.4, Color("ffc870"), 0.9, 3.0)
		"sentier":
			var lamp2 := WorldArt.lamp_texture()
			for i in range(8):
				var side3 := -1.0 if i % 2 == 0 else 1.0
				var lp2 := Vector2(4.5 + side3 * 5.8, -0.5 + float(i / 2) * 4.6)
				_prop(lamp2, lp2, 0.9, Color(0.9, 1.1, 0.8))
				_prop_light(lp2, 1.2, Color("e8f28b"), 0.6, 2.5)
		"clairiere":
			var stump := WorldArt.stump_texture()
			var lg := WorldArt.log_texture()
			for i in range(12):
				_prop(stump, _side_spot(rng), rng.randf_range(1.0, 1.6))
			for i in range(4):
				_prop(lg, _side_spot(rng), 1.3)
		"roncier":
			var br := WorldArt.bramble_texture()
			for i in range(18):
				_prop(br, _side_spot(rng), rng.randf_range(1.0, 1.7))
			var rs := WorldArt.runestone_texture()
			for x: float in [-1.7, 10.7]:
				_prop(rs, Vector2(x, 15.5), 1.5)
				_prop_light(Vector2(x, 15.5), 1.2, Color("d93cf2"), 0.8, 3.0)
		"fougeres":
			var fern := WorldArt.fern_texture()
			for i in range(26):
				_prop(fern, _side_spot(rng), rng.randf_range(1.2, 2.0))
			var moon := OmniLight3D.new()
			moon.light_color = Color("b8d0ff")
			moon.light_energy = 0.8
			moon.omni_range = 14.0
			moon.position = w3(Vector2(4.5, 12.0), 7.0)
			add_child(moon)
		"cercle":
			var mush := WorldArt.mushroom_texture()
			for side4: float in [-1.0, 1.0]:
				var ctr := Vector2(4.5 + side4 * 8.0, 9.0)
				for k in range(14):
					var a := float(k) / 14.0 * TAU
					_prop(mush, ctr + Vector2(cos(a) * 2.4, sin(a) * 3.4), 1.2, Color(1.3, 1.1, 1.3))
				_prop_light(ctr, 0.6, Color("ff9ce8"), 1.0, 4.0)
		"source":
			for side5: float in [-1.0, 1.0]:
				var water := MeshInstance3D.new()
				var wm := PlaneMesh.new()
				wm.size = Vector2(4.0, 14.0)
				water.mesh = wm
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.12, 0.3, 0.38, 0.75)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.emission_enabled = true
				mat.emission = Color("1f5a66")
				mat.emission_energy_multiplier = 0.18
				mat.roughness = 0.2
				water.material_override = mat
				water.position = w3(Vector2(4.5 + side5 * 7.6, 8.0), 0.02)
				add_child(water)
			var reeds := WorldArt.reeds_texture()
			for i in range(16):
				var side6 := -1.0 if i % 2 == 0 else 1.0
				_prop(reeds, Vector2(4.5 + side6 * rng.randf_range(5.4, 5.9), rng.randf_range(1.5, 15.0)), 1.1)
		"coeur":
			var cr := WorldArt.crystal_texture()
			for i in range(10):
				var sp := _side_spot(rng)
				_prop(cr, sp, rng.randf_range(1.0, 1.8), Color(1.2, 1.0, 1.3))
				if i % 3 == 0:
					_prop_light(sp, 1.0, Color("d93cf2"), 0.9, 3.5)
		"sylvarche":
			var root := WorldArt.root_texture()
			for i in range(14):
				_prop(root, _side_spot(rng), rng.randf_range(1.2, 2.0))


## Collines d'Ambre (zone 2) : les objets du lieu, sur les bords du terrain (docs/design/41-cinematiques.md).
func _build_hills_props() -> void:
	var sc := WorldArt.scene
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sc) + 2
	match sc:
		"route":
			var burnt := WorldArt.cart_texture(true)
			for i in range(3):
				var cp := _side_spot(rng)
				_prop(burnt, cp, 1.6)
				_chimneys.append(w3(cp, -0.2))
			var stone := WorldArt.milestone_texture()
			for i in range(5):
				_prop(stone, _side_spot(rng), 1.5)
		"moulins":
			var mill := WorldArt.windmill_texture()
			for i in range(4):
				var side := -1.0 if i % 2 == 0 else 1.0
				_prop(mill, Vector2(4.5 + side * rng.randf_range(8.0, 9.5), 2.0 + float(i / 2) * 9.0 + rng.randf_range(-1.0, 1.0)), 2.4)
			var hay := WorldArt.haystack_texture()
			for i in range(8):
				_prop(hay, _side_spot(rng), rng.randf_range(1.3, 1.7))
		"pylones":
			var spire := WorldArt.amber_spire_texture()
			for i in range(10):
				var sp := _side_spot(rng)
				_prop(spire, sp, rng.randf_range(1.2, 2.0), Color(1.25, 1.1, 1.0))
				if i % 2 == 0:
					_prop_light(sp, 1.2, Color("ffa040"), 1.0, 3.5)
		"gue":
			# La rivière passe de part et d'autre du gué : eau claire, roseaux, totems du clan au passage.
			for side2: float in [-1.0, 1.0]:
				var water := MeshInstance3D.new()
				var wm := PlaneMesh.new()
				wm.size = Vector2(5.0, 40.0)
				water.mesh = wm
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.25, 0.5, 0.58, 0.8)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.roughness = 0.15
				mat.metallic_specular = 0.8
				water.material_override = mat
				water.position = w3(Vector2(4.5 + side2 * 7.8, 8.0), -0.62)
				add_child(water)
			var totem := WorldArt.totem_texture(false)
			for x: float in [-1.4, 10.4]:
				_prop(totem, Vector2(x, 12.5), 1.4)
		"repaire":
			var tent := WorldArt.tent_texture(Color("8a6a48"), Color("4a3420"))
			for i in range(6):
				_prop(tent, _side_spot(rng), rng.randf_range(1.6, 2.0))
			var pal := WorldArt.palisade_texture()
			for i in range(8):
				var side3 := -1.0 if i % 2 == 0 else 1.0
				_prop(pal, Vector2(4.5 + side3 * 9.2, 1.0 + float(i / 2) * 4.6), 1.8)
			var crate := WorldArt.crate_texture(true)
			for i in range(5):
				var cp2 := _side_spot(rng)
				_prop(crate, cp2, 1.4, Color(1.15, 1.0, 1.2))
				if i % 2 == 0:
					_prop_light(cp2, 0.6, Color("d98cff"), 0.7, 2.5)
			_hills_fires(rng, 2)
		"orage":
			var storm_totem := WorldArt.totem_texture(true)
			for i in range(6):
				var tp := _side_spot(rng)
				_prop(storm_totem, tp, rng.randf_range(1.3, 1.7))
				_prop_light(tp, 1.6, Color("9fe0ff"), 0.8, 3.0)
			var tent2 := WorldArt.tent_texture(Color("5a5a6a"), Color("2a2a30"))
			for i in range(3):
				_prop(tent2, _side_spot(rng), 1.7)
		"caravane":
			var wagon := WorldArt.cart_texture(false)
			for i in range(4):
				_prop(wagon, _side_spot(rng), 1.7)
			var crate2 := WorldArt.crate_texture(false)
			for i in range(6):
				_prop(crate2, _side_spot(rng), 1.2)
			var stone2 := WorldArt.milestone_texture()
			for i in range(3):
				_prop(stone2, _side_spot(rng), 1.5)
			var mill2 := WorldArt.windmill_texture()
			_prop(mill2, Vector2(-4.0, 16.0), 2.4)
		"rebouteux":
			var tent3 := WorldArt.tent_texture(Color("8a8a5a"), Color("4a4a2a"))
			for i in range(4):
				_prop(tent3, _side_spot(rng), 1.8)
			var rack := WorldArt.rack_texture()
			for i in range(6):
				_prop(rack, _side_spot(rng), 1.4)
			_hills_fires(rng, 2)
		"traite":
			# Les deux camps face à face : la Prévôté (bleu) à gauche, les clans (rouge) à droite.
			for side4: float in [-1.0, 1.0]:
				var blue := side4 < 0.0
				var tent4 := WorldArt.tent_texture(Color("3a6ad0") if blue else Color("c83a2a"), Color("e8dcc0") if blue else Color("4a2018"))
				var flag := WorldArt.banner_pole_texture(Color("3a6ad0") if blue else Color("c83a2a"), false)
				for k in range(3):
					_prop(tent4, Vector2(4.5 + side4 * rng.randf_range(7.0, 9.0), 2.0 + float(k) * 5.5), 1.9)
				for k2 in range(4):
					_prop(flag, Vector2(4.5 + side4 * 5.7, 1.0 + float(k2) * 4.2), 1.3)
		"fort":
			var pal2 := WorldArt.palisade_texture()
			for i in range(14):
				var side5 := -1.0 if i % 2 == 0 else 1.0
				_prop(pal2, Vector2(4.5 + side5 * 8.6, -0.5 + float(i / 2) * 2.7), 2.0)
			var tower := WorldArt.watchtower_texture()
			for i in range(4):
				var side6 := -1.0 if i % 2 == 0 else 1.0
				var tw := Vector2(4.5 + side6 * 9.6, 3.0 + float(i / 2) * 9.0)
				_prop(tower, tw, 2.2)
				_prop_light(tw, 2.0, Color("ff9b4a"), 0.8, 3.5)
			var skull := WorldArt.banner_pole_texture(Color("a82a2a"), true)
			for i in range(4):
				var side7 := -1.0 if i % 2 == 0 else 1.0
				_prop(skull, Vector2(4.5 + side7 * 5.8, 2.0 + float(i / 2) * 7.0), 1.4)
			_hills_fires(rng, 2)


## Marais Murmurants (zone 3) : eau de part et d'autre, maisons sur pilotis, stèles, ossements, pierres du Cercle.
func _build_swamp_props() -> void:
	var sc := WorldArt.scene
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sc) + 3
	if WorldArt.SWAMP_WATER.has(sc):
		for side: float in [-1.0, 1.0]:
			var water := MeshInstance3D.new()
			var wm := PlaneMesh.new()
			wm.size = Vector2(16.0, 44.0)
			water.mesh = wm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(Color(str(WorldArt.SWAMP_WATER[sc])), 0.85)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 0.1
			mat.metallic_specular = 0.9
			if sc == "mares":
				mat.emission_enabled = true
				mat.emission = Color("4a8a20")
				mat.emission_energy_multiplier = 0.25
			water.material_override = mat
			water.position = w3(Vector2(4.5 + side * 13.5, 8.0), -0.6)
			add_child(water)
	var reeds := WorldArt.reeds_texture()
	for i in range(14):
		var side2 := -1.0 if i % 2 == 0 else 1.0
		_prop(reeds, Vector2(4.5 + side2 * rng.randf_range(5.3, 5.8), rng.randf_range(0.5, 16.0)), 1.1, Color(0.8, 0.85, 0.75))
	match sc:
		"pilotis", "barque":
			var hut := WorldArt.stilt_house_texture()
			for i in range(5 if sc == "pilotis" else 2):
				var side3 := -1.0 if i % 2 == 0 else 1.0
				var hp := Vector2(4.5 + side3 * rng.randf_range(7.5, 9.5), 1.5 + float(i) * 3.5)
				_prop(hut, hp, 2.0)
				_prop_light(hp, 1.4, Color("f2c46b"), 0.8, 3.0)
			var lamp := WorldArt.lamp_texture()
			for i in range(6):
				var side4 := -1.0 if i % 2 == 0 else 1.0
				var lp := Vector2(4.5 + side4 * 5.9, 1.0 + float(i / 2) * 6.0)
				_prop(lamp, lp, 1.0)
				_prop_light(lp, 1.4, Color("ffc870"), 0.8, 2.8)
			var boat := WorldArt.boat_texture()
			for i in range(2 if sc == "pilotis" else 5):
				_prop(boat, Vector2(4.5 + (-1.0 if i % 2 == 0 else 1.0) * rng.randf_range(6.5, 9.0), rng.randf_range(1.0, 16.0)), 1.6)
		"mares", "croc", "hydre":
			var rib := WorldArt.ribcage_texture()
			for i in range(3 if sc == "mares" else 5):
				_prop(rib, _side_spot(rng), rng.randf_range(1.4, 2.0))
			if sc != "mares":
				var skull := WorldArt.big_skull_texture()
				for i in range(2):
					_prop(skull, _side_spot(rng), 1.8)
		"gue_morts":
			var grave := WorldArt.grave_texture()
			for i in range(16):
				_prop(grave, _side_spot(rng), rng.randf_range(1.0, 1.5))
			for i in range(4):
				var gp := _side_spot(rng)
				_prop_light(gp, 0.8, Color("8fd8ff"), 0.9, 3.0)
		"saules":
			var stone := WorldArt.ash_stone_texture()
			for side5: float in [-1.0, 1.0]:
				var ctr := Vector2(4.5 + side5 * 8.0, 9.0)
				for k in range(10):
					var a := float(k) / 10.0 * TAU
					_prop(stone, ctr + Vector2(cos(a) * 2.4, sin(a) * 3.4), 1.3)
				_prop_light(ctr, 0.6, Color("ff7a2a"), 1.1, 4.0)
				_chimneys.append(w3(ctr, -0.4))
		"sorciere":
			var pot := WorldArt.cauldron_texture()
			for x: float in [-1.6, 10.6]:
				var cp := Vector2(x, 13.0)
				_prop(pot, cp, 1.5)
				_prop_light(cp, 0.8, Color("8ae050"), 1.0, 3.5)
				_chimneys.append(w3(cp, 0.4))
			var hut2 := WorldArt.stilt_house_texture()
			_prop(hut2, Vector2(-4.5, 15.0), 2.2)
			var rib2 := WorldArt.ribcage_texture()
			for i in range(3):
				_prop(rib2, _side_spot(rng), 1.5)
		"refuge":
			var ruin := WorldArt.ruin_pillar_texture()
			for i in range(10):
				var rp := _side_spot(rng)
				_prop(ruin, rp, rng.randf_range(1.4, 2.0))
				if i % 3 == 0:
					_prop_light(rp, 1.8, Color("b07cff"), 0.8, 3.0)
			var grave2 := WorldArt.grave_texture()
			for i in range(4):
				_prop(grave2, _side_spot(rng), 1.2)


## Marais : reflets sur l'eau, bulles de poison, nappes de brume plus épaisses dans la Brume.
func _build_swamp_ambience() -> void:
	var sc := WorldArt.scene
	if WorldArt.SWAMP_WATER.has(sc):
		for side: float in [-1.0, 1.0]:
			var gl := CPUParticles3D.new()
			gl.amount = 24
			gl.lifetime = 1.6
			gl.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			gl.emission_box_extents = Vector3(5.0, 0.0, 16.0)
			gl.position = w3(Vector2(4.5 + side * 9.0, 8.0), -0.56)
			gl.gravity = Vector3.ZERO
			gl.initial_velocity_max = 0.0
			gl.mesh = _particle_mesh(0.07)
			var gr := Gradient.new()
			gr.set_color(0, Color(0.85, 0.95, 0.9, 0.0))
			gr.set_color(1, Color(0.85, 0.95, 0.9, 0.0))
			gr.add_point(0.5, Color(0.9, 1.0, 0.95, 0.7))
			gl.color_ramp = gr
			add_child(gl)
	if sc in ["mares", "croc", "sorciere"]:
		var bub := CPUParticles3D.new()
		bub.amount = 40
		bub.lifetime = 2.2
		bub.preprocess = 2.2
		bub.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		bub.emission_box_extents = Vector3(10.0, 0.1, 11.0)
		bub.position = Vector3(4.5, -0.5, -8.0)
		bub.direction = Vector3(0, 1, 0)
		bub.spread = 10.0
		bub.initial_velocity_min = 0.2
		bub.initial_velocity_max = 0.5
		bub.gravity = Vector3.ZERO
		bub.mesh = _particle_mesh(0.09)
		var bg := Gradient.new()
		bg.set_color(0, Color(0.6, 1.0, 0.3, 0.0))
		bg.set_color(1, Color(0.6, 1.0, 0.3, 0.0))
		bg.add_point(0.3, Color(0.7, 1.0, 0.4, 0.8))
		bub.color_ramp = bg
		add_child(bub)
	if sc in ["brume", "hydre", "gue_morts"]:
		# Brume épaisse qui roule au ras du sol, jusque sur le terrain.
		var mist_shader: Shader = load("res://shaders/mist.gdshader")
		var mi := MeshInstance3D.new()
		var mp := PlaneMesh.new()
		mp.size = Vector2(40.0, 40.0)
		mi.mesh = mp
		var sm := ShaderMaterial.new()
		sm.shader = mist_shader
		sm.set_shader_parameter("noise_tex", WorldArt.mist_texture())
		sm.set_shader_parameter("tint", Color("d8e0d8"))
		sm.set_shader_parameter("strength", 0.28 if sc == "brume" else 0.2)
		sm.set_shader_parameter("speed", Vector2(0.01, 0.004))
		mi.material_override = sm
		mi.position = Vector3(4.5, 0.25, -8.0)
		add_child(mi)


## Pics Gelés (zone 4) : statues naines, piliers runiques, braseros, flèches de glace, wagonnets, portes scellées.
func _build_frost_props() -> void:
	var sc := WorldArt.scene
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sc) + 4
	match sc:
		"col", "chariot":
			var statue := WorldArt.dwarf_statue_texture()
			for i in range(4):
				var side := -1.0 if i % 2 == 0 else 1.0
				_prop(statue, Vector2(4.5 + side * 6.2, 2.0 + float(i / 2) * 8.0), 1.6)
			var stone := WorldArt.milestone_texture()
			for i in range(5):
				_prop(stone, _side_spot(rng), 1.4, Color(0.85, 0.9, 1.05))
			if sc == "chariot":
				var cart := WorldArt.minecart_texture()
				for i in range(3):
					_prop(cart, _side_spot(rng), 1.6)
				var rp := WorldArt.rune_pillar_texture()
				for i in range(4):
					var p := _side_spot(rng)
					_prop(rp, p, 1.4)
					_prop_light(p, 1.6, Color("8fe3f2"), 0.7, 3.0)
		"congeres":
			var spire := WorldArt.ice_spire_texture()
			for i in range(6):
				_prop(spire, _side_spot(rng), rng.randf_range(1.0, 1.6))
		"porte_naine", "portes", "forteresse":
			var door := WorldArt.great_door_texture()
			for x: float in [-3.2, 12.2]:
				_prop(door, Vector2(x, 14.0), 2.4)
				_prop_light(Vector2(x, 14.0), 2.0, Color("4a6aff"), 0.9, 4.0)
			var statue2 := WorldArt.dwarf_statue_texture()
			for i in range(4):
				var side2 := -1.0 if i % 2 == 0 else 1.0
				_prop(statue2, Vector2(4.5 + side2 * 6.3, 3.0 + float(i / 2) * 6.0), 1.8)
			var braz := WorldArt.brazier_texture()
			for i in range(4):
				var side3 := -1.0 if i % 2 == 0 else 1.0
				var bp := Vector2(4.5 + side3 * 5.8, 1.0 + float(i / 2) * 8.0)
				_prop(braz, bp, 1.2)
				_prop_light(bp, 1.1, Color("ff9b4a"), 1.0, 3.0)
			if sc == "forteresse":
				var flag := WorldArt.banner_pole_texture(Color("2a4a8a"), false)
				for i in range(4):
					_prop(flag, _side_spot(rng), 1.4)
		"lac_gele", "aurore":
			var spire2 := WorldArt.ice_spire_texture()
			for i in range(10 if sc == "aurore" else 6):
				var sp := _side_spot(rng)
				_prop(spire2, sp, rng.randf_range(1.2, 2.0), Color(1.1, 1.15, 1.2))
				if sc == "aurore" and i % 3 == 0:
					_prop_light(sp, 1.4, Color("5ff0a8"), 0.7, 3.0)
		"sentinelle":
			var rp2 := WorldArt.rune_pillar_texture()
			for i in range(10):
				var side4 := -1.0 if i % 2 == 0 else 1.0
				var pp := Vector2(4.5 + side4 * rng.randf_range(5.8, 8.5), 0.5 + float(i / 2) * 3.4)
				_prop(rp2, pp, 1.6)
				if i % 2 == 0:
					_prop_light(pp, 1.8, Color("8fe3f2"), 0.8, 3.2)
		"colosse":
			var rp3 := WorldArt.rune_pillar_texture()
			for i in range(8):
				var side5 := -1.0 if i % 2 == 0 else 1.0
				_prop(rp3, Vector2(4.5 + side5 * 6.4, 1.0 + float(i / 2) * 4.2), 2.0)
			var braz2 := WorldArt.brazier_texture()
			for i in range(6):
				var bp2 := _side_spot(rng)
				_prop(braz2, bp2, 1.3)
				_prop_light(bp2, 1.1, Color("ff9b4a"), 1.1, 3.2)
				_chimneys.append(w3(bp2, 1.0))


## Pics : rafales de neige au col et sur les congères, reflets sur le lac gelé.
func _build_frost_ambience() -> void:
	var sc := WorldArt.scene
	if sc in ["col", "congeres", "chariot"]:
		var gust := CPUParticles3D.new()
		gust.amount = 90
		gust.lifetime = 2.0
		gust.preprocess = 2.0
		gust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		gust.emission_box_extents = Vector3(2.0, 1.2, 12.0)
		gust.position = Vector3(-6.0, 1.2, -8.0)
		gust.direction = Vector3(1.0, -0.05, 0.0)
		gust.spread = 6.0
		gust.initial_velocity_min = 6.0
		gust.initial_velocity_max = 9.0
		gust.gravity = Vector3(0.0, -0.3, 0.0)
		var q := QuadMesh.new()
		q.size = Vector2(0.3, 0.025)
		var gm := StandardMaterial3D.new()
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gm.vertex_color_use_as_albedo = true
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		q.material = gm
		gust.mesh = q
		var gg := Gradient.new()
		gg.set_color(0, Color(1, 1, 1, 0.0))
		gg.set_color(1, Color(1, 1, 1, 0.0))
		gg.add_point(0.3, Color(1, 1, 1, 0.6))
		gust.color_ramp = gg
		add_child(gust)
	if sc in ["lac_gele", "aurore"]:
		var gl := CPUParticles3D.new()
		gl.amount = 40
		gl.lifetime = 1.6
		gl.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		gl.emission_box_extents = Vector3(10.0, 0.0, 12.0)
		gl.position = Vector3(4.5, 0.05, -8.0)
		gl.gravity = Vector3.ZERO
		gl.initial_velocity_max = 0.0
		gl.mesh = _particle_mesh(0.07)
		var gr := Gradient.new()
		gr.set_color(0, Color(0.9, 1.0, 1.0, 0.0))
		gr.set_color(1, Color(0.9, 1.0, 1.0, 0.0))
		gr.add_point(0.5, Color(0.95, 1.0, 1.0, 0.85))
		gl.color_ramp = gr
		add_child(gl)


## Désert de Verre (zone 5) : obélisques, colonnes du Collège, miroirs, amas de verre, statues brisées, oasis.
func _build_desert_props() -> void:
	var sc := WorldArt.scene
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sc) + 5
	var glass := WorldArt.glass_cluster_texture()
	for i in range(8):
		var gp := _side_spot(rng)
		_prop(glass, gp, rng.randf_range(1.0, 1.6), Color(1.1, 1.15, 1.15))
		if i % 3 == 0:
			_prop_light(gp, 0.8, Color("6ae0e0"), 0.6, 2.5)
	match sc:
		"dunes", "mirage", "scarabee", "caravane_sable", "spectres":
			var ob := WorldArt.obelisk_texture()
			for i in range(4):
				var side := -1.0 if i % 2 == 0 else 1.0
				_prop(ob, Vector2(4.5 + side * rng.randf_range(6.5, 9.0), 2.0 + float(i) * 4.0), 1.8)
			var statue := WorldArt.broken_statue_texture()
			for i in range(2):
				_prop(statue, _side_spot(rng), 1.6)
			if sc == "caravane_sable":
				var cart := WorldArt.cart_texture(false)
				for i in range(3):
					_prop(cart, _side_spot(rng), 1.6)
				var tent := WorldArt.tent_texture(Color("e8d8b0"), Color("a8845a"))
				for i in range(3):
					_prop(tent, _side_spot(rng), 1.8)
		"oasis":
			for side2: float in [-1.0, 1.0]:
				var water := MeshInstance3D.new()
				var wm := PlaneMesh.new()
				wm.size = Vector2(6.0, 14.0)
				water.mesh = wm
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.2, 0.55, 0.65, 0.85)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.roughness = 0.1
				mat.metallic_specular = 0.9
				water.material_override = mat
				water.position = w3(Vector2(4.5 + side2 * 8.5, 8.0), -0.6)
				add_child(water)
			var reeds := WorldArt.reeds_texture()
			for i in range(14):
				var side3 := -1.0 if i % 2 == 0 else 1.0
				_prop(reeds, Vector2(4.5 + side3 * rng.randf_range(5.4, 6.0), rng.randf_range(1.0, 15.0)), 1.1)
			var tent2 := WorldArt.tent_texture(Color("e8d8b0"), Color("c84a3a"))
			for i in range(2):
				_prop(tent2, _side_spot(rng), 1.8)
		"miroirs", "sceaux", "college", "sphinx":
			var col := WorldArt.sand_column_texture()
			for i in range(10):
				var side4 := -1.0 if i % 2 == 0 else 1.0
				_prop(col, Vector2(4.5 + side4 * rng.randf_range(5.8, 8.5), 0.5 + float(i / 2) * 3.4), 1.8)
			if sc == "miroirs" or sc == "college":
				var mirror := WorldArt.glass_mirror_texture()
				for i in range(4):
					var mp := _side_spot(rng)
					_prop(mirror, mp, 1.6)
					_prop_light(mp, 1.0, Color("e8ffff"), 0.6, 2.5)
			if sc == "sphinx" or sc == "sceaux":
				var ob2 := WorldArt.obelisk_texture()
				for x: float in [-1.6, 10.6]:
					_prop(ob2, Vector2(x, 14.0), 2.2)
					_prop_light(Vector2(x, 14.0), 2.2, Color("6ae0e0"), 0.8, 3.5)
			var statue2 := WorldArt.broken_statue_texture()
			for i in range(3):
				_prop(statue2, _side_spot(rng), 1.6)


## Désert : voiles de sable que le vent emporte, et (oasis) reflets sur l'eau.
func _build_desert_ambience() -> void:
	var sc := WorldArt.scene
	var sand := CPUParticles3D.new()
	sand.amount = 70
	sand.lifetime = 3.0
	sand.preprocess = 3.0
	sand.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sand.emission_box_extents = Vector3(3.0, 0.4, 12.0)
	sand.position = Vector3(-4.0, 0.3, -8.0)
	sand.direction = Vector3(1.0, 0.1, 0.0)
	sand.spread = 8.0
	sand.initial_velocity_min = 3.0
	sand.initial_velocity_max = 5.0
	sand.gravity = Vector3(0.0, -0.1, 0.0)
	var q := QuadMesh.new()
	q.size = Vector2(0.5, 0.03)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.vertex_color_use_as_albedo = true
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = qm
	sand.mesh = q
	var sg := Gradient.new()
	sg.set_color(0, Color(1.0, 0.88, 0.6, 0.0))
	sg.set_color(1, Color(1.0, 0.88, 0.6, 0.0))
	sg.add_point(0.4, Color(1.0, 0.9, 0.65, 0.45))
	sand.color_ramp = sg
	add_child(sand)
	if sc == "oasis":
		for side: float in [-1.0, 1.0]:
			var gl := CPUParticles3D.new()
			gl.amount = 22
			gl.lifetime = 1.4
			gl.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			gl.emission_box_extents = Vector3(2.5, 0.0, 6.5)
			gl.position = w3(Vector2(4.5 + side * 8.5, 8.0), -0.56)
			gl.gravity = Vector3.ZERO
			gl.initial_velocity_max = 0.0
			gl.mesh = _particle_mesh(0.08)
			var gr := Gradient.new()
			gr.set_color(0, Color(1.0, 1.0, 0.9, 0.0))
			gr.set_color(1, Color(1.0, 1.0, 0.9, 0.0))
			gr.add_point(0.5, Color(1.0, 1.0, 0.95, 0.9))
			gl.color_ramp = gr
			add_child(gl)


## Forêt Cendrée (zone 6) : troncs calcinés, incendies, coulées de lave, os de dragon, nids de phénix,
## autels du Wyrm, remparts de basalte, campement des réfugiés.
func _build_cinder_props() -> void:
	var sc := WorldArt.scene
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sc) + 6
	var charred := WorldArt.charred_tree_texture()
	for i in range({"couloirs": 12, "lisiere_cendree": 10, "pardon": 6}.get(sc, 7)):
		_prop(charred, _side_spot(rng), rng.randf_range(1.6, 2.4))
	var stone := WorldArt.ash_stone_texture()
	for i in range(5):
		_prop(stone, _side_spot(rng), rng.randf_range(1.0, 1.5), Color(0.6, 0.55, 0.55))
	if sc in WorldArt.LAVA_SCENES:
		for side: float in [-1.0, 1.0]:
			var lava := MeshInstance3D.new()
			var lm := PlaneMesh.new()
			lm.size = Vector2(3.0, 22.0)
			lava.mesh = lm
			var mat := StandardMaterial3D.new()
			var lt := WorldArt.lava_texture()
			mat.albedo_texture = lt
			mat.emission_enabled = true
			mat.emission_texture = lt
			mat.emission_energy_multiplier = 1.4
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			mat.uv1_scale = Vector3(1.0, 7.0, 1.0)
			mat.roughness = 0.8
			lava.material_override = mat
			lava.position = w3(Vector2(4.5 + side * 7.3, 8.0), -0.57)
			add_child(lava)
			for k in range(3):
				_prop_light(Vector2(4.5 + side * 7.0, 2.0 + float(k) * 6.0), 0.4, Color("ff6a1a"), 1.2, 5.0)
	match sc:
		"lisiere_cendree", "couloirs":
			_hills_fires(rng, 4 if sc == "lisiere_cendree" else 8)
			if sc == "couloirs":
				# Murs de flammes qui bordent les couloirs.
				var flame := WorldArt.flame_texture()
				for i in range(16):
					var side2 := -1.0 if i % 2 == 0 else 1.0
					var f := _prop(flame, Vector2(4.5 + side2 * rng.randf_range(5.8, 6.4), float(i / 2) * 2.2), 1.3, Color(1.5, 1.2, 1.0))
					f.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		"ailes", "drake":
			var skull := WorldArt.big_skull_texture()
			for i in range(3 if sc == "ailes" else 5):
				_prop(skull, _side_spot(rng), rng.randf_range(1.8, 2.4), Color(0.85, 0.75, 0.7))
			var rib := WorldArt.ribcage_texture()
			for i in range(3):
				_prop(rib, _side_spot(rng), rng.randf_range(1.8, 2.4), Color(0.85, 0.75, 0.7))
			_hills_fires(rng, 2)
		"braisemont":
			var tent := WorldArt.tent_texture(Color("8a7a6a"), Color("a84a2a"))
			for i in range(4):
				_prop(tent, _side_spot(rng), 1.8)
			var cart := WorldArt.cart_texture(true)
			for i in range(3):
				_prop(cart, _side_spot(rng), 1.6)
			_hills_fires(rng, 3)
		"nid":
			var nest := WorldArt.phoenix_nest_texture()
			for i in range(6):
				var np := _side_spot(rng)
				_prop(nest, np, rng.randf_range(1.4, 1.9), Color(1.3, 1.15, 1.0))
				_prop_light(np, 0.6, Color("ffb040"), 1.0, 3.5)
		"autels", "antre":
			var altar := WorldArt.wyrm_altar_texture()
			for i in range(6 if sc == "autels" else 3):
				var ap := _side_spot(rng)
				_prop(altar, ap, 1.7)
				_prop_light(ap, 0.8, Color("e84a6a"), 0.9, 3.5)
			var banner := WorldArt.banner_pole_texture(Color("6a1a2a"), true)
			for x: float in [-1.4, 10.4]:
				_prop(banner, Vector2(x, 13.0), 1.8)
			if sc == "antre":
				var skull2 := WorldArt.big_skull_texture()
				for i in range(4):
					_prop(skull2, _side_spot(rng), rng.randf_range(2.0, 2.6), Color(0.75, 0.65, 0.6))
		"citadelle":
			var wall := WorldArt.basalt_wall_texture()
			for i in range(10):
				var side3 := -1.0 if i % 2 == 0 else 1.0
				var wp := Vector2(4.5 + side3 * rng.randf_range(6.5, 8.0), 1.0 + float(i / 2) * 3.6)
				_prop(wall, wp, 2.0)
				if i % 3 == 0:
					_prop_light(wp, 1.2, Color("ff8a3a"), 0.8, 3.0)
			var brazier := WorldArt.brazier_texture()
			for x2: float in [-1.0, 10.0]:
				for y2: float in [4.0, 12.0]:
					_prop(brazier, Vector2(x2, y2), 1.5)
					_prop_light(Vector2(x2, y2), 1.0, Color("ff9a4a"), 1.0, 3.5)
			var banner2 := WorldArt.banner_pole_texture(Color("8a2a1a"), false)
			for i in range(4):
				_prop(banner2, _side_spot(rng), 1.8)
		"pardon":
			var stump := WorldArt.charred_tree_texture()
			for i in range(4):
				_prop(stump, _side_spot(rng), rng.randf_range(1.0, 1.4))


## Cité Engloutie (zone 7) : coraux, anémones, bénitiers, lanternes des quais, épaves et ancres, canaux,
## statues d'Archivistes, cloches de plongée, étagères noyées, arches de corail, tentacules, os du Léviathan.
func _build_abyss_props() -> void:
	var sc := WorldArt.scene
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sc) + 7
	var corals := [WorldArt.coral_texture(Color("e87aa0")), WorldArt.coral_texture(Color("ff9a6a")), WorldArt.coral_texture(Color("b07cff"))]
	for i in range(10 if sc in ["sirenes", "marees"] else 6):
		_prop(corals[i % 3], _side_spot(rng), rng.randf_range(1.0, 1.5))
	var clam := WorldArt.giant_clam_texture()
	for i in range(5 if sc == "sirenes" else 2):
		var cp := _side_spot(rng)
		_prop(clam, cp, 1.3)
		_prop_light(cp, 0.4, Color("e8f4ff"), 0.6, 2.5)
	match sc:
		"quais", "grand_canal", "cloche":
			var lamp := WorldArt.quay_lamp_texture()
			for i in range(8):
				var side := -1.0 if i % 2 == 0 else 1.0
				var lp := Vector2(4.5 + side * 5.6, 1.0 + float(i / 2) * 4.4)
				_prop(lamp, lp, 1.5)
				_prop_light(lp, 1.2, Color("6ad8f0"), 0.9, 3.0)
			if sc == "grand_canal":
				for side2: float in [-1.0, 1.0]:
					var water := MeshInstance3D.new()
					var wm := PlaneMesh.new()
					wm.size = Vector2(3.2, 22.0)
					water.mesh = wm
					var mat := StandardMaterial3D.new()
					mat.albedo_color = Color(0.06, 0.22, 0.28, 0.85)
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mat.roughness = 0.1
					mat.metallic_specular = 0.9
					water.material_override = mat
					water.position = w3(Vector2(4.5 + side2 * 7.4, 8.0), -0.57)
					add_child(water)
			else:
				var boat := WorldArt.boat_texture()
				for i in range(2):
					_prop(boat, _side_spot(rng), 1.6, Color(0.6, 0.8, 0.95))
				var anchor := WorldArt.anchor_texture()
				for i in range(3):
					_prop(anchor, _side_spot(rng), 1.3)
			if sc == "cloche":
				var bell := WorldArt.diving_bell_texture()
				for x: float in [-1.4, 10.4]:
					_prop(bell, Vector2(x, 9.0), 1.9)
					_prop_light(Vector2(x, 9.0), 1.0, Color("ffd070"), 1.0, 3.0)
		"marees", "kraken":
			var boat2 := WorldArt.boat_texture()
			for i in range(3):
				_prop(boat2, _side_spot(rng), 1.7, Color(0.55, 0.75, 0.9))
			var anchor2 := WorldArt.anchor_texture()
			for i in range(3):
				_prop(anchor2, _side_spot(rng), 1.3)
			if sc == "kraken":
				var tent := WorldArt.tentacle_texture()
				for i in range(6):
					var side3 := -1.0 if i % 2 == 0 else 1.0
					_prop(tent, Vector2(4.5 + side3 * rng.randf_range(6.0, 8.5), 2.0 + float(i) * 2.4), rng.randf_range(1.6, 2.2))
		"statues", "palais", "archives":
			var statue := WorldArt.archivist_statue_texture()
			for i in range(8 if sc == "statues" else 4):
				var side4 := -1.0 if i % 2 == 0 else 1.0
				var stp := Vector2(4.5 + side4 * rng.randf_range(5.7, 6.4), 1.0 + float(i / 2) * (4.0 if sc == "statues" else 7.0))
				_prop(statue, stp, 1.8)
				_prop_light(stp, 1.4, Color("8fe3f2"), 0.5, 2.0)
			var col := WorldArt.sand_column_texture()
			for i in range(4):
				_prop(col, _side_spot(rng), 1.8, Color(0.6, 0.75, 0.95))
			if sc == "palais":
				var arch := WorldArt.coral_arch_texture()
				for x2: float in [-1.6, 10.6]:
					for y2: float in [3.0, 11.0]:
						_prop(arch, Vector2(x2, y2), 1.9)
				var lamp2 := WorldArt.quay_lamp_texture()
				for x3: float in [-0.6, 9.6]:
					_prop(lamp2, Vector2(x3, 14.0), 1.6)
					_prop_light(Vector2(x3, 14.0), 1.2, Color("6ad8f0"), 1.0, 3.0)
			if sc == "archives":
				var shelf := WorldArt.sunken_shelf_texture()
				for i in range(10):
					var side5 := -1.0 if i % 2 == 0 else 1.0
					_prop(shelf, Vector2(4.5 + side5 * rng.randf_range(6.2, 8.5), 0.5 + float(i / 2) * 3.4), 1.8)
		"sirenes":
			var arch2 := WorldArt.coral_arch_texture()
			for i in range(3):
				_prop(arch2, _side_spot(rng), 1.8)
			for i in range(4):
				_prop_light(_side_spot(rng), 0.8, Color("ff8ab8"), 0.8, 3.5)
		"leviathan":
			var rib := WorldArt.ribcage_texture()
			for i in range(6):
				_prop(rib, _side_spot(rng), rng.randf_range(2.0, 2.8), Color(0.75, 0.85, 0.9))
			var skull := WorldArt.big_skull_texture()
			for i in range(2):
				_prop(skull, _side_spot(rng), 2.4, Color(0.7, 0.8, 0.88))
			var tent2 := WorldArt.tentacle_texture()
			for i in range(4):
				_prop(tent2, _side_spot(rng), rng.randf_range(2.0, 2.6))


## Cité Engloutie : neige marine qui dérive, rayons de la surface, bancs de poissons ; méduses (sirènes,
## palais), pages qui flottent (archives).
func _build_abyss_ambience() -> void:
	var sc := WorldArt.scene
	var snow := CPUParticles3D.new()
	snow.amount = 60
	snow.lifetime = 10.0
	snow.preprocess = 10.0
	snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	snow.emission_box_extents = Vector3(10.0, 2.5, 12.0)
	snow.position = Vector3(4.5, 3.0, -8.0)
	snow.direction = Vector3(0.3, -0.2, 0.0)
	snow.spread = 40.0
	snow.initial_velocity_min = 0.05
	snow.initial_velocity_max = 0.2
	snow.gravity = Vector3(0.02, -0.02, 0.0)
	snow.mesh = _particle_mesh(0.04)
	var sg := Gradient.new()
	sg.set_color(0, Color(0.85, 0.95, 1.0, 0.0))
	sg.set_color(1, Color(0.85, 0.95, 1.0, 0.0))
	sg.add_point(0.5, Color(0.9, 0.97, 1.0, 0.6))
	snow.color_ramp = sg
	add_child(snow)
	# Rayons de la surface : de longs voiles obliques, à peine visibles, qui ondulent.
	if sc != "leviathan":
		for i in range(5):
			var ray := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(1.4, 12.0)
			ray.mesh = q
			var rm := StandardMaterial3D.new()
			rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			rm.albedo_color = Color(0.5, 0.85, 1.0, 0.08)
			rm.cull_mode = BaseMaterial3D.CULL_DISABLED
			ray.material_override = rm
			ray.position = Vector3(-1.0 + float(i) * 2.8, 4.0, -4.0 - float(i % 3) * 5.0)
			ray.rotation_degrees = Vector3(0.0, 0.0, 18.0)
			add_child(ray)
			var tw := create_tween().set_loops()
			tw.tween_property(rm, "albedo_color:a", 0.14, 2.0 + float(i) * 0.4)
			tw.tween_property(rm, "albedo_color:a", 0.04, 2.0 + float(i) * 0.4)
	# Bancs de poissons qui traversent au loin, de part et d'autre.
	for side: float in [-1.0, 1.0]:
		var fish := CPUParticles3D.new()
		fish.amount = 24
		fish.lifetime = 9.0
		fish.preprocess = 9.0
		fish.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		fish.emission_box_extents = Vector3(0.6, 0.6, 1.2)
		fish.position = Vector3(4.5 + side * 9.0, 2.2, -10.0)
		fish.direction = Vector3(0.0, 0.0, 1.0)
		fish.spread = 6.0
		fish.initial_velocity_min = 1.1
		fish.initial_velocity_max = 1.4
		fish.gravity = Vector3.ZERO
		var fq := QuadMesh.new()
		fq.size = Vector2(0.14, 0.05)
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.vertex_color_use_as_albedo = true
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		fq.material = fm
		fish.mesh = fq
		var fg := Gradient.new()
		fg.set_color(0, Color(0.6, 0.8, 0.9, 0.0))
		fg.set_color(1, Color(0.6, 0.8, 0.9, 0.0))
		fg.add_point(0.15, Color(0.7, 0.88, 0.95, 0.8))
		fg.add_point(0.85, Color(0.7, 0.88, 0.95, 0.8))
		fish.color_ramp = fg
		add_child(fish)
	if sc in ["sirenes", "palais", "archives", "leviathan"]:
		var jelly := CPUParticles3D.new()
		jelly.amount = 14
		jelly.lifetime = 12.0
		jelly.preprocess = 12.0
		jelly.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		jelly.emission_box_extents = Vector3(10.0, 1.0, 11.0)
		jelly.position = Vector3(4.5, 0.5, -8.0)
		jelly.direction = Vector3(0.0, 1.0, 0.0)
		jelly.spread = 10.0
		jelly.initial_velocity_min = 0.15
		jelly.initial_velocity_max = 0.3
		jelly.gravity = Vector3.ZERO
		jelly.mesh = _particle_mesh(0.22)
		var jg := Gradient.new()
		var jc := Color("ff8ab8") if sc == "sirenes" else Color("8fe3f2")
		jg.set_color(0, Color(jc, 0.0))
		jg.set_color(1, Color(jc, 0.0))
		jg.add_point(0.3, Color(jc, 0.5))
		jg.add_point(0.7, Color(jc.lightened(0.3), 0.4))
		jelly.color_ramp = jg
		add_child(jelly)
	if sc == "archives":
		var pages := CPUParticles3D.new()
		pages.amount = 16
		pages.lifetime = 10.0
		pages.preprocess = 10.0
		pages.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		pages.emission_box_extents = Vector3(10.0, 1.5, 11.0)
		pages.position = Vector3(4.5, 1.5, -8.0)
		pages.spread = 180.0
		pages.initial_velocity_min = 0.05
		pages.initial_velocity_max = 0.15
		pages.gravity = Vector3(0.0, 0.02, 0.0)
		pages.angular_velocity_min = -40.0
		pages.angular_velocity_max = 40.0
		pages.mesh = _particle_mesh(0.12)
		var pg := Gradient.new()
		pg.set_color(0, Color(0.95, 0.9, 0.8, 0.0))
		pg.set_color(1, Color(0.95, 0.9, 0.8, 0.0))
		pg.add_point(0.5, Color(0.95, 0.92, 0.82, 0.7))
		pages.color_ramp = pg
		add_child(pages)


## Forêt Cendrée : cendre qui tombe, étincelles au-dessus de la lave, ombre d'ailes qui balaie l'arène.
func _build_cinder_ambience() -> void:
	var sc := WorldArt.scene
	var ash := CPUParticles3D.new()
	ash.amount = 30 if sc == "pardon" else 70
	ash.lifetime = 8.0
	ash.preprocess = 8.0
	ash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ash.emission_box_extents = Vector3(10.0, 0.5, 12.0)
	ash.position = Vector3(4.5, 6.0, -8.0)
	ash.direction = Vector3(0.2, -1.0, 0.0)
	ash.spread = 25.0
	ash.initial_velocity_min = 0.3
	ash.initial_velocity_max = 0.6
	ash.gravity = Vector3(0.08, -0.06, 0.0)
	ash.angular_velocity_min = -90.0
	ash.angular_velocity_max = 90.0
	ash.mesh = _particle_mesh(0.06)
	var ag := Gradient.new()
	ag.set_color(0, Color(0.55, 0.52, 0.5, 0.0))
	ag.set_color(1, Color(0.4, 0.38, 0.36, 0.0))
	ag.add_point(0.2, Color(0.6, 0.57, 0.55, 0.8))
	ag.add_point(0.8, Color(0.45, 0.42, 0.4, 0.7))
	ash.color_ramp = ag
	add_child(ash)
	if sc in WorldArt.LAVA_SCENES:
		for side: float in [-1.0, 1.0]:
			var sp := CPUParticles3D.new()
			sp.amount = 30
			sp.lifetime = 1.2
			sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			sp.emission_box_extents = Vector3(1.3, 0.0, 10.0)
			sp.position = w3(Vector2(4.5 + side * 7.3, 8.0), -0.5)
			sp.direction = Vector3(0.0, 1.0, 0.0)
			sp.spread = 20.0
			sp.initial_velocity_min = 0.8
			sp.initial_velocity_max = 1.8
			sp.gravity = Vector3(0.0, -2.0, 0.0)
			sp.mesh = _particle_mesh(0.07)
			var sg := Gradient.new()
			sg.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
			sg.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
			sp.color_ramp = sg
			add_child(sp)
	if sc in ["ailes", "nid", "citadelle", "drake"]:
		# Un dragon passe au-dessus : son ombre glisse sur l'arène, toutes les quelques secondes.
		var shadow := Sprite3D.new()
		shadow.texture = FxArt.flash()
		shadow.shaded = false
		shadow.transparent = true
		shadow.modulate = Color(0.05, 0.02, 0.02, 0.4)
		shadow.pixel_size = 0.22
		shadow.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		shadow.scale = Vector3(1.8, 1.0, 1.0)
		add_child(shadow)
		var a := w3(Vector2(-12.0, 4.0), 0.05)
		var b := w3(Vector2(22.0, 13.0), 0.05)
		shadow.position = a
		var tw := create_tween().set_loops()
		tw.tween_property(shadow, "position", b, 3.2)
		tw.tween_interval(7.0)
		tw.tween_callback(func() -> void: shadow.position = a)


## Feux de camp : flamme, lueur qui danse, fumée.
func _hills_fires(rng: RandomNumberGenerator, n: int) -> void:
	var flame := WorldArt.flame_texture()
	for i in range(n):
		var side := -1.0 if i % 2 == 0 else 1.0
		var fp := Vector2(4.5 + side * rng.randf_range(6.2, 7.5), rng.randf_range(3.0, 13.0))
		var f := _prop(flame, fp, 1.5, Color(1.5, 1.25, 1.0))
		f.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		var l := OmniLight3D.new()
		l.light_color = Color("ff9b4a")
		l.light_energy = 1.3
		l.omni_range = 4.0
		l.position = w3(fp, 0.2)
		add_child(l)
		_torch_lights.append(l)
		_chimneys.append(w3(fp, 0.4))


## Collines d'Ambre : brins et graines d'herbe sèche que le vent emporte ; pluie sous l'orage ; reflets du gué.
func _build_hills_ambience() -> void:
	var sc := WorldArt.scene
	if _storm:
		var rain := CPUParticles3D.new()
		rain.amount = 260
		rain.lifetime = 1.1
		rain.preprocess = 1.1
		rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		rain.emission_box_extents = Vector3(12.0, 0.5, 13.0)
		rain.position = Vector3(4.5, 7.0, -9.0)
		rain.direction = Vector3(0.18, -1.0, 0.0)
		rain.spread = 4.0
		rain.initial_velocity_min = 7.0
		rain.initial_velocity_max = 9.0
		rain.gravity = Vector3(0.0, -4.0, 0.0)
		var q := QuadMesh.new()
		q.size = Vector2(0.02, 0.32)
		var rm := StandardMaterial3D.new()
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rm.vertex_color_use_as_albedo = true
		rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		q.material = rm
		rain.mesh = q
		var rg := Gradient.new()
		rg.set_color(0, Color(0.75, 0.8, 0.95, 0.0))
		rg.set_color(1, Color(0.75, 0.8, 0.95, 0.0))
		rg.add_point(0.3, Color(0.8, 0.85, 1.0, 0.55))
		rain.color_ramp = rg
		add_child(rain)
		return
	var straw := CPUParticles3D.new()
	straw.amount = 34 if sim.wind_cfg.is_empty() else 60
	straw.lifetime = 7.0
	straw.preprocess = 7.0
	straw.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	straw.emission_box_extents = Vector3(10.0, 1.2, 11.0)
	straw.position = Vector3(4.5, 1.6, -8.0)
	straw.direction = Vector3(1.0, 0.1, 0.0)
	straw.spread = 20.0
	straw.initial_velocity_min = 0.4
	straw.initial_velocity_max = 1.0
	straw.gravity = Vector3(0.15, -0.03, 0.0)
	straw.angular_velocity_min = -180.0
	straw.angular_velocity_max = 180.0
	straw.mesh = _particle_mesh(0.07)
	var sg := Gradient.new()
	sg.set_color(0, Color("e8c870"))
	sg.set_color(1, Color("c8a050"))
	sg.add_point(0.5, Color("f2e0a0"))
	straw.color_initial_ramp = sg
	add_child(straw)
	if sc == "gue":
		for side: float in [-1.0, 1.0]:
			var gl := CPUParticles3D.new()
			gl.amount = 26
			gl.lifetime = 1.3
			gl.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			gl.emission_box_extents = Vector3(2.2, 0.0, 16.0)
			gl.position = w3(Vector2(4.5 + side * 7.8, 8.0), -0.58)
			gl.gravity = Vector3.ZERO
			gl.initial_velocity_max = 0.0
			gl.mesh = _particle_mesh(0.08)
			var gr := Gradient.new()
			gr.set_color(0, Color(1.0, 1.0, 0.9, 0.0))
			gr.set_color(1, Color(1.0, 1.0, 0.9, 0.0))
			gr.add_point(0.5, Color(1.0, 1.0, 0.95, 0.9))
			gl.color_ramp = gr
			add_child(gl)


## Piliers du bord du chemin selon le lieu (zone 1) : poteaux de bois, souches, pierres maudites, pierres de fée,
## cristaux, bois de la Sylvarche ; ailleurs, la pierre et sa mousse.
func _pillar_mats() -> Array:
	if WorldArt.scene == "" or WorldArt.scene == "pont":
		return [_stone_mat, _moss_cap]
	var body := _triplanar(WorldArt.stone_texture(), 0.55)
	var cap := StandardMaterial3D.new()
	cap.roughness = 1.0
	match WorldArt.scene:
		# Collines d'Ambre : poteaux de bois, pierre veinée d'ambre, totems, pieux de palissade.
		"route", "caravane", "moulins", "rebouteux":
			body.albedo_color = Color(0.95, 0.72, 0.5)
			cap.albedo_color = Color("d8b060") if WorldArt.scene != "rebouteux" else Color("e8e0c8")
		"pylones":
			body.albedo_color = Color(0.9, 0.78, 0.62)
			cap.albedo_color = Color("ffb050")
			cap.emission_enabled = true
			cap.emission = Color("e88a20")
			cap.emission_energy_multiplier = 0.8
		"gue":
			body.albedo_color = Color(0.8, 0.85, 0.85)
			cap.albedo_color = Color("6a7a40")
		"repaire", "fort":
			body.albedo_color = Color(0.6, 0.45, 0.35)
			cap.albedo_color = Color("a82a2a")
		"orage":
			body.albedo_color = Color(0.55, 0.5, 0.5)
			cap.albedo_color = Color("9fe0ff")
			cap.emission_enabled = true
			cap.emission = Color("6ac8ff")
			cap.emission_energy_multiplier = 0.6
		"traite":
			body.albedo_color = Color(1.0, 0.92, 0.78)
			cap.albedo_color = Color("f2c46b")
		# Marais : pieux de bois, pierres moussues, stèles, pierres du Cercle, ruines.
		"pilotis", "barque", "brume", "hydre":
			body.albedo_color = Color(0.7, 0.58, 0.45)
			cap.albedo_color = Color("5a6a48")
		"mares", "croc", "sorciere":
			body.albedo_color = Color(0.7, 0.8, 0.65)
			cap.albedo_color = Color("6aa83a")
			cap.emission_enabled = true
			cap.emission = Color("4a8a20")
			cap.emission_energy_multiplier = 0.5
		"gue_morts":
			body.albedo_color = Color(0.8, 0.82, 0.9)
			cap.albedo_color = Color("bfe8ff")
			cap.emission_enabled = true
			cap.emission = Color("6ab8e0")
			cap.emission_energy_multiplier = 0.5
		"saules":
			body.albedo_color = Color(0.75, 0.72, 0.78)
			cap.albedo_color = Color("ff8a3a")
			cap.emission_enabled = true
			cap.emission = Color("e85a1a")
			cap.emission_energy_multiplier = 0.7
		"refuge":
			body.albedo_color = Color(0.85, 0.82, 0.95)
			cap.albedo_color = Color("b07cff")
			cap.emission_enabled = true
			cap.emission = Color("8a4ad0")
			cap.emission_energy_multiplier = 0.6
		# Pics : pierre naine aux runes cyan, bornes enneigées, braises de la forge du Colosse.
		"col", "congeres", "chariot", "lac_gele", "aurore":
			body.albedo_color = Color(0.9, 0.95, 1.05)
			cap.albedo_color = Color("f4f8ff")
		"porte_naine", "sentinelle", "portes", "forteresse":
			body.albedo_color = Color(0.8, 0.85, 1.0)
			cap.albedo_color = Color("8fe3f2")
			cap.emission_enabled = true
			cap.emission = Color("4ab8e0")
			cap.emission_energy_multiplier = 0.6
		# Désert : grès doré coiffé de verre turquoise.
		"dunes", "mirage", "scarabee", "caravane_sable", "oasis", "spectres":
			body.albedo_color = Color(1.05, 0.95, 0.8)
			cap.albedo_color = Color("6ae0e0")
			cap.emission_enabled = true
			cap.emission = Color("2a9aa8")
			cap.emission_energy_multiplier = 0.5
		"miroirs", "sceaux", "college", "sphinx":
			body.albedo_color = Color(1.1, 1.0, 0.85)
			cap.albedo_color = Color("f2d070")
			cap.emission_enabled = true
			cap.emission = Color("e8a040")
			cap.emission_energy_multiplier = 0.5
		# Forêt Cendrée : basalte noir, braises au sommet ; marque du Wyrm aux autels ; mousse neuve au Pardon.
		"lisiere_cendree", "couloirs", "ailes", "drake", "coulee", "antre", "nid", "braisemont", "citadelle":
			body.albedo_color = Color(0.55, 0.48, 0.48)
			cap.albedo_color = Color("4a2a20")
			cap.emission_enabled = true
			cap.emission = Color("a8380c")
			cap.emission_energy_multiplier = 0.45
		"autels":
			body.albedo_color = Color(0.5, 0.45, 0.55)
			cap.albedo_color = Color("4a1a2a")
			cap.emission_enabled = true
			cap.emission = Color("a01a40")
			cap.emission_energy_multiplier = 0.5
		"pardon":
			body.albedo_color = Color(0.6, 0.55, 0.55)
			cap.albedo_color = Color("6aa83a")
		# Cité Engloutie : pierre bleutée coiffée de corail rose, ou de runes cyan des Archivistes.
		"quais", "grand_canal", "marees", "kraken", "cloche", "sirenes":
			body.albedo_color = Color(0.75, 0.88, 1.0)
			cap.albedo_color = Color("8a4a6a")
		"statues", "archives", "palais", "leviathan":
			body.albedo_color = Color(0.72, 0.82, 0.98)
			cap.albedo_color = Color("2a6a80")
			cap.emission_enabled = true
			cap.emission = Color("1a7a90")
			cap.emission_energy_multiplier = 0.35
		"colosse":
			body.albedo_color = Color(0.7, 0.72, 0.85)
			cap.albedo_color = Color("ff9a4a")
			cap.emission_enabled = true
			cap.emission = Color("e8701a")
			cap.emission_energy_multiplier = 0.7
		"lisiere":
			body.albedo_color = Color(0.85, 0.6, 0.42)
			cap.albedo_color = Color("8a6a3a")
		"clairiere", "sylvarche":
			body.albedo_color = Color(0.62, 0.45, 0.38) if WorldArt.scene == "clairiere" else Color(0.45, 0.36, 0.42)
			cap.albedo_color = Color("c8a070") if WorldArt.scene == "clairiere" else Color("5a3a6a")
		"roncier":
			body.albedo_color = Color(0.6, 0.52, 0.72)
			cap.albedo_color = Color("5a2a6a")
			cap.emission_enabled = true
			cap.emission = Color("8e3ac8")
			cap.emission_energy_multiplier = 0.4
		"cercle":
			body.albedo_color = Color(1.05, 1.0, 1.1)
			cap.albedo_color = Color("f7a8e0")
			cap.emission_enabled = true
			cap.emission = Color("ff9ce8")
			cap.emission_energy_multiplier = 0.8
		"coeur":
			body.albedo_color = Color(0.75, 0.5, 1.0)
			body.emission_enabled = true
			body.emission = Color("6a2a9a")
			body.emission_energy_multiplier = 0.35
			cap.albedo_color = Color("ffb0ff")
			cap.emission_enabled = true
			cap.emission = Color("d93cf2")
			cap.emission_energy_multiplier = 0.9
		"source":
			body.albedo_color = Color(0.7, 0.85, 0.95)
			cap.albedo_color = Color("3f8a7a")
		_:
			cap.albedo_color = Color("3f6a3a")
	return [body, cap]


## Végétation des combats (zone 1, hors du pont) : touffes, fleurs, buissons, rochers, fougères, cailloux et
## détails du lieu, le long des bords du terrain, clairsemés sur le terrain, et partout sur le sol de la forêt.
## Elle ondule au vent ; certains détails luisent (champignons, cristaux, fleurs de lune).
func _build_foliage() -> void:
	var sc := WorldArt.scene
	if sc == "" or sc == "pont":
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sc) + 11
	var glow: Array = WorldArt.FOLIAGE_GLOW.get(sc, WorldArt.FOLIAGE_GLOW_Z4.get(sc, []))
	var items: Array = [] ## [position, taille, image]
	# Bords du terrain : herbes hautes, fleurs, touffes, cailloux.
	for i in range(90):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := 4.5 + side * rng.randf_range(3.95, 4.5)
		items.append([w3(Vector2(x, rng.randf_range(-0.5, 15.8)), 0.0), rng.randf_range(0.32, 0.55), [0, 1, 2, 3, 10, 10, 7, 11][rng.randi_range(0, 7)]])
	# Sur le terrain : quelques touffes basses et cailloux.
	for i in range(55):
		items.append([w3(Vector2(rng.randf_range(0.6, 8.4), rng.randf_range(0.8, 14.5)), 0.0), rng.randf_range(0.16, 0.26), [0, 1, 7, 11, 2][rng.randi_range(0, 4)]])
	# Sol de la forêt de part et d'autre : tout, plus grand, avec les détails du lieu.
	for i in range(200):
		var side2 := -1.0 if i % 2 == 0 else 1.0
		var x2 := 4.5 + side2 * rng.randf_range(5.3, 11.0)
		var f: int = [0, 1, 2, 3, 4, 4, 5, 6, 6, 8, 9, 10, 8, 9][rng.randi_range(0, 13)]
		var big := 1.6 if f in [4, 5, 8, 9] else 1.0
		items.append([w3(Vector2(x2, rng.randf_range(-3.0, 24.0)), -0.6), rng.randf_range(0.45, 0.9) * big, f])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = _quad_mesh()
	mm.instance_count = items.size()
	for i in range(items.size()):
		var it: Array = items[i]
		var sz: float = it[1]
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(sz, sz, 1.0)), it[0]))
		var f2: int = it[2]
		var sh := rng.randf_range(0.82, 1.05)
		mm.set_instance_color(i, Color(sh, sh, sh, 0.8 if f2 in glow else 0.0))
		mm.set_instance_custom_data(i, Color(float(f2) / float(WorldArt.FOLIAGE_N), 0.0, 1.0 / float(WorldArt.FOLIAGE_N), 1.0))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/foliage.gdshader")
	mat.set_shader_parameter("atlas", WorldArt.foliage_atlas(sc))
	# Le vent des steppes couche l'herbe plus fort quand il souffle sur le niveau.
	mat.set_shader_parameter("sway", 0.12 if not sim.wind_cfg.is_empty() else (0.08 if WorldArt.zone == 2 else 0.05))
	mat.set_shader_parameter("stretch", 1.0 / maxf(0.3, cos(deg_to_rad(PITCH_DEG))))
	mi.material_override = mat
	mi.custom_aabb = AABB(Vector3(-15.0, -2.0, -30.0), Vector3(40.0, 8.0, 40.0))
	add_child(mi)


## Ambiance animée du lieu : feuilles qui tombent, fumée des cheminées, reflets sur l'eau ; les lueurs pulsent.
func _build_ambience() -> void:
	var sc := WorldArt.scene
	if sc == "" or sc == "pont":
		return
	if WorldArt.zone == 2:
		_build_hills_ambience()
	if WorldArt.zone == 3:
		_build_swamp_ambience()
	if WorldArt.zone == 4:
		_build_frost_ambience()
	if WorldArt.zone == 5:
		_build_desert_ambience()
	if WorldArt.zone == 6:
		_build_cinder_ambience()
	if WorldArt.zone == 7:
		_build_abyss_ambience()
	if sc in ["lisiere", "sentier", "clairiere", "fougeres", "source", "sylvarche", "roncier"]:
		var lv := CPUParticles3D.new()
		lv.amount = 26
		lv.lifetime = 9.0
		lv.preprocess = 9.0
		lv.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		lv.emission_box_extents = Vector3(9.0, 0.5, 11.0)
		lv.position = Vector3(4.5, 5.0, -8.0)
		lv.direction = Vector3(0.3, -1.0, 0.0)
		lv.spread = 25.0
		lv.initial_velocity_min = 0.25
		lv.initial_velocity_max = 0.5
		lv.gravity = Vector3(0.12, -0.05, 0.0)
		lv.angular_velocity_min = -90.0
		lv.angular_velocity_max = 90.0
		lv.mesh = _particle_mesh(0.11)
		var cr := Gradient.new()
		var cols: Array = [Color("8a5a2a"), Color("c88a3a"), Color("4f7a3a")]
		if sc in ["sylvarche", "roncier"]:
			cols = [Color("5a2a7a"), Color("8e62e0"), Color("3a2a4a")]
		elif sc == "source":
			cols = [Color("4f8a5a"), Color("8ac870"), Color("3f6a4a")]
		cr.set_color(0, cols[0])
		cr.set_color(1, cols[1])
		cr.add_point(0.5, cols[2])
		lv.color_initial_ramp = cr
		add_child(lv)
	if sc == "source":
		for side: float in [-1.0, 1.0]:
			var gl := CPUParticles3D.new()
			gl.amount = 22
			gl.lifetime = 1.4
			gl.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			gl.emission_box_extents = Vector3(1.8, 0.0, 6.5)
			gl.position = w3(Vector2(4.5 + side * 7.6, 8.0), 0.06)
			gl.gravity = Vector3.ZERO
			gl.initial_velocity_max = 0.0
			gl.mesh = _particle_mesh(0.08)
			var gr := Gradient.new()
			gr.set_color(0, Color(0.8, 1.0, 1.0, 0.0))
			gr.set_color(1, Color(0.8, 1.0, 1.0, 0.0))
			gr.add_point(0.5, Color(0.9, 1.0, 1.0, 0.9))
			gl.color_ramp = gr
			add_child(gl)
	for c in _chimneys:
		var sm := CPUParticles3D.new()
		sm.amount = 10
		sm.lifetime = 3.5
		sm.preprocess = 3.5
		sm.position = c
		sm.direction = Vector3(0.15, 1.0, 0.0)
		sm.spread = 10.0
		sm.initial_velocity_min = 0.3
		sm.initial_velocity_max = 0.5
		sm.gravity = Vector3(0.08, 0.05, 0.0)
		sm.scale_amount_min = 1.0
		sm.scale_amount_max = 2.2
		sm.mesh = _particle_mesh(0.22)
		var sg := Gradient.new()
		sg.set_color(0, Color(0.55, 0.52, 0.65, 0.0))
		sg.set_color(1, Color(0.4, 0.4, 0.5, 0.0))
		sg.add_point(0.25, Color(0.6, 0.58, 0.7, 0.5))
		sm.color_ramp = sg
		add_child(sm)


func _side_spot(rng: RandomNumberGenerator) -> Vector2:
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	return Vector2(4.5 + side * rng.randf_range(5.6, 9.0), rng.randf_range(-0.5, 18.0))


## Objet du décor : une image dressée face à la caméra, posée au sol de la forêt.
func _prop(tex: Texture2D, p: Vector2, scale: float, mod: Color = Color.WHITE) -> Sprite3D:
	var s3 := Sprite3D.new()
	s3.texture = tex
	s3.pixel_size = TEXEL * scale
	s3.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s3.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s3.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s3.shaded = false
	s3.modulate = mod
	s3.offset = Vector2(0.0, float(tex.get_height()) * 0.5)
	s3.position = w3(p, -0.7 if absf(p.x - 4.5) > 5.2 else 0.0)
	add_child(s3)
	return s3


func _prop_light(p: Vector2, h: float, col: Color, energy: float, rng_m: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_m
	l.position = w3(p, h)
	add_child(l)
	_pulse.append([l, energy, randf() * TAU])


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
		_kick.append(0.0)
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
	# Lueur de l'arme aux couleurs du tir de la classe (cyan du Mage, violet du Nécromancien, or du Clerc…).
	var ccol := Color(ClassFire.color(sim.player().class_id))
	var ramp := Gradient.new()
	ramp.set_color(0, ccol.lerp(Color.WHITE, 0.35))
	ramp.set_color(1, Color(ccol.darkened(0.2), 0.0))
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
	_staff_light.light_color = ccol
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
			"shot_fire", "rise", "fireflies":
				# Tir de classe : le lanceur a un léger recul, puis l'animation du geste (ShotFx).
				var ci := int(e.get("c", -1))
				if ci >= 0 and ci < _kick.size():
					_kick[ci] = 1.0
				if _spell_fx != null:
					_spell_fx.handle(e)
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
	_dt = delta
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
	if not sim.tide_cfg.is_empty():
		_update_water()
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
	for pl in _pulse:
		(pl[0] as OmniLight3D).light_energy = float(pl[1]) * (0.78 + 0.22 * sin(t * 2.1 + float(pl[2])))
	if _storm and _sun != null:
		# Orage : un éclair de temps en temps (le ciel blanchit, puis la lumière retombe).
		_storm_t -= delta
		if _storm_t <= 0.0:
			_storm_t = randf_range(4.0, 9.0)
			_bolt_k = 1.0
			flash = maxf(flash, 0.12)
		_bolt_k = maxf(0.0, _bolt_k - delta * 3.0)
		_sun.light_energy = 0.55 + _bolt_k * (2.2 if fmod(_bolt_k, 0.3) > 0.12 else 0.8)
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
		var dim := (p.kind == "add" and not p.ready) or (p.kind == "sub" and p.charges <= 0) or p.submerged or p.swallowed
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
	if u.shot != "":
		return _put_shot(u, n)
	var lp := u.prev_pos.lerp(u.pos, alpha)
	var moving := not u.engaged and u.speed_factor() > 0.0 and u.rise_t <= 0.0
	var fr := SpriteAtlas.frame(u.sprite, u.element, int(u.anim * 6.0) if moving else 0)
	var h := SpriteAtlas.height_m(u.sprite) * u.scale
	var w := h * float(fr["w"]) / float(fr["h"])
	var bob := absf(sin(u.anim * 9.0)) * 0.035 if moving else 0.0
	if u.sprite == "luciole":
		# Luciole : elle vole, ailes battantes, et sa lueur pulse.
		fr = SpriteAtlas.frame(u.sprite, u.element, int(u.anim * 14.0))
		bob = 0.34 + sin(u.anim * 4.0 + float(u.id)) * 0.08
	if u.rise_t > 0.0:
		# Squelette du Nécromancien qui sort de terre (le sol cache ce qui est encore dessous).
		var rk := clampf(u.rise_t / float(ClassFire.SPEC["necromancien"]["rise"]), 0.0, 1.0)
		bob -= h * 0.95 * rk * rk
		lp.x += sin(u.rise_t * 40.0) * 0.03 * rk
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


## Tir de classe : sprite de l'élément, en vol au-dessus du sol, qui tourne (bouclier, haches) ou scintille.
func _put_shot(u: Unit, n: int) -> int:
	var lp := u.prev_pos.lerp(u.pos, alpha)
	var fr := SpriteAtlas.frame(u.sprite, u.element, int(u.anim * float(SHOT_FPS.get(u.shot, 8.0))))
	var h := SpriteAtlas.height_m(u.sprite) * u.scale
	var w := h * float(fr["w"]) / float(fr["h"])
	var lift := float(SHOT_LIFT.get(u.shot, 0.3))
	if u.shot == "lumiere":
		lift += sin(u.anim * 9.0) * 0.06
	elif u.shot == "onde":
		# L'onde s'élargit en quittant la lame.
		w *= 0.8 + 0.25 * minf(1.0, u.anim / 0.5)
	_units_mm.set_instance_transform(n, Transform3D(Basis.from_scale(Vector3(w, h, 1.0)), w3(lp, lift)))
	var glow := 1.8 if u.shot == "lumiere" else 1.35
	_units_mm.set_instance_color(n, Color(glow, glow, glow))
	var uv: Rect2 = fr["uv"]
	_units_mm.set_instance_custom_data(n, Color(uv.position.x, uv.position.y, uv.size.x, uv.size.y))
	return n + 1


## Traînées des tirs de classe, à la couleur de la classe : on reconnaît chaque tir d'un coup d'œil.
func _shot_trails(lines: Array, points: Array) -> void:
	for u in sim.allies:
		if not u.alive or u.shot == "":
			continue
		var lp := u.prev_pos.lerp(u.pos, alpha)
		var col := Color(ClassFire.color(str(ClassFire.SHOT_CLASS.get(u.shot, ""))))
		var dir := (u.pos - u.prev_pos)
		dir = dir.normalized() if dir.length_squared() > 0.000001 else Vector2(0.0, 1.0)
		var lift := float(SHOT_LIFT.get(u.shot, 0.3))
		match u.shot:
			"fleche":
				# Longue traînée verte, doublée pour rester lisible de loin.
				for k in range(4):
					var a := lp - dir * (0.2 + 0.3 * float(k))
					var b := lp - dir * (0.2 + 0.3 * float(k + 1))
					var ca := Color(col, 0.9 * (1.0 - float(k) / 4.0))
					lines.append([w3(a, lift + 0.12), w3(b, lift + 0.12), ca])
					lines.append([w3(a + Vector2(0.035, 0.0), lift + 0.1), w3(b + Vector2(0.035, 0.0), lift + 0.1), ca])
					lines.append([w3(a - Vector2(0.035, 0.0), lift + 0.1), w3(b - Vector2(0.035, 0.0), lift + 0.1), Color(1.0, 1.0, 1.0, ca.a * 0.6)])
			"onde":
				var half := u.radius
				for g in range(2):
					var back := 0.3 + 0.3 * float(g)
					var prev := Vector2.ZERO
					for i in range(9):
						var v := float(i) / 4.0 - 1.0
						var p := lp + Vector2(v * half, -back - 0.4 * v * v)
						if i > 0:
							lines.append([w3(prev, 0.12), w3(p, 0.12), Color(col, 0.55 - 0.25 * float(g))])
						prev = p
			"lumiere":
				lines.append([w3(lp, lift + 0.2), w3(lp, 0.02), Color(col, 0.25)])
				for k in range(3):
					var sp := lp - dir * (0.2 + 0.22 * float(k)) + Vector2(sin(t * 13.0 + float(k) * 2.0) * 0.08, 0.0)
					points.append([w3(sp, lift + 0.25 + 0.05 * float(k)), Color(col, 0.9 - 0.25 * float(k))])
			"bouclier":
				for sx: float in [-0.14, 0.14]:
					lines.append([w3(lp + Vector2(sx, -0.2), lift + 0.3), w3(lp + Vector2(sx, -0.75), lift + 0.3), Color(col, 0.6)])
			"hache":
				for k in range(4):
					var ang := u.anim * 26.0 - float(k) * 0.6
					var sp2 := lp - dir * (0.1 + 0.1 * float(k)) + Vector2(cos(ang), sin(ang)) * 0.12
					points.append([w3(sp2, lift + 0.22), Color(col, 0.85 - 0.2 * float(k))])


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
	if not u.alive or sn >= MAX_SHADOWS or u.shot == "onde" or u.shot == "lumiere":
		return sn
	var lp := u.prev_pos.lerp(u.pos, alpha)
	var r := u.radius if u.shot == "" else 0.09
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
		if u.sprite == "luciole":
			var gl := 1.3 + 0.25 * sin(u.anim * 6.0 + float(u.id))
			return Color(gl, gl, gl)
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
		if i < _kick.size() and _kick[i] > 0.0:
			# Recul du tir : le lanceur se tasse et recule d'un cheveu.
			var kk := _kick[i]
			s.position.z += kk * 0.09
			s.pixel_size *= 1.0 - kk * 0.04
			_kick[i] = maxf(0.0, kk - _dt * 7.0)
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
		elif bool(tg.get("wave", false)):
			tcol = Color(0.55, 0.9, 1.0)
		elif bool(tg.get("tentacle", false)):
			tcol = Color(0.75, 0.45, 0.95)
		_rect(lines, tg["rect"], Color(tcol, 0.45 + 0.5 * pulse), true)
	# Zone 7 : courants (flèches qui défilent) et tourbillons (spirales).
	for c in sim.currents:
		var cy := float(c["y"])
		var dir := float(c["dir"])
		var off := fposmod(t * float(c["speed"]) * 1.4, 1.2)
		var x := -0.6 + off
		while x < BattleSim.W:
			var a := Vector2(x if dir > 0.0 else BattleSim.W - x, cy)
			var b := a + Vector2(0.5 * dir, 0.0)
			lines.append([w3(a, 0.05), w3(b, 0.05), Color(0.6, 0.95, 1.0, 0.8)])
			lines.append([w3(a + Vector2(0.0, 0.06), 0.05), w3(b + Vector2(0.0, 0.06), 0.05), Color(0.6, 0.95, 1.0, 0.5)])
			lines.append([w3(b, 0.05), w3(b + Vector2(-0.18 * dir, 0.12), 0.05), Color(0.6, 0.95, 1.0, 0.55)])
			lines.append([w3(b, 0.05), w3(b + Vector2(-0.18 * dir, -0.12), 0.05), Color(0.6, 0.95, 1.0, 0.55)])
			x += 1.2
	for wp in sim.whirlpools:
		var wc: Vector2 = wp["pos"]
		var wr := float(wp["r"])
		for arm in range(3):
			var prev := wc
			for k in range(24):
				var ang := t * 3.0 + float(arm) * TAU / 3.0 + float(k) * 0.32
				var rr := wr * float(k) / 23.0
				var pnt := wc + Vector2(cos(ang), sin(ang)) * rr
				if k > 0:
					lines.append([w3(prev, 0.06), w3(pnt, 0.06), Color(0.5, 0.85, 1.0, 0.75)])
				prev = pnt
		_ring(lines, wc, wr, Color(0.4, 0.75, 1.0, 0.6), 0.06)
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
	_shot_trails(lines, points)
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


# ---------------------------------------------------------------- zone 7 · Cité Engloutie

## Marée : une nappe d'eau translucide couvre l'arène jusqu'au niveau de la marée.
func _update_water() -> void:
	if _water == null:
		_water = MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(BattleSim.W + 4.0, 1.0)
		_water.mesh = pm
		_water_mat = _unshaded(Color(0.2, 0.6, 0.8, 0.28), true)
		_water.material_override = _water_mat
		add_child(_water)
	var top := lerpf(_water.get_meta("y", sim.tide_y), sim.tide_y, 0.2)
	_water.set_meta("y", top)
	var h := maxf(0.05, top + 2.0)
	(_water.mesh as PlaneMesh).size = Vector2(BattleSim.W + 4.0, h)
	_water.position = w3(Vector2(BattleSim.W * 0.5, top - h * 0.5), 0.09 + 0.02 * sin(t * 1.6))
	_water_mat.albedo_color = Color(0.25, 0.65, 0.85, 0.24 + 0.04 * sin(t * 2.2))
