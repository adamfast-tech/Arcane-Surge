class_name TerrainView
extends Node3D
## Rendu du terrain interactif (BattleTerrain) : sols laissés par les sorts, cratères et brûlures qui
## restent jusqu'à la fin du combat, piliers qui basculent sur la chaussée, murs de pierre.

const MAX_DECALS := 40
const WALL_TINT := Color(1.25, 1.0, 0.72)

var sim: BattleSim
var fx: SpellFx
var stone: Material
var cap: Material
var t := 0.0
var _pillars: Dictionary = {} ## id -> {root, pivot, side, h, fall, age, dur, hit_t}
var _walls: Dictionary = {} ## id -> {node, mat, age, hp}
var _surf: Dictionary = {} ## id -> {mesh, mat, parts, kind, age, r, seen}
var _decals: Array[Node3D] = []


static func w3(p: Vector2, h: float = 0.0) -> Vector3:
	return Vector3(p.x, h, -p.y)


func setup(s: BattleSim, stone_mat: Material, cap_mat: Material, spell_fx: SpellFx) -> void:
	sim = s
	stone = stone_mat
	cap = cap_mat
	fx = spell_fx
	for p in sim.terrain.props:
		_build_pillar(p)


func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# ---------------------------------------------------------------- piliers

func _build_pillar(p: Dictionary) -> void:
	var root := Node3D.new()
	root.position = w3(p["pos"])
	add_child(root)
	var pivot := Node3D.new()
	root.add_child(pivot)
	var h := float(p["h"])
	_box(Vector3(0.6, h, 0.6), Vector3(0.0, h * 0.5, 0.0), stone, pivot)
	_box(Vector3(0.66, 0.08, 0.66), Vector3(0.0, h + 0.04, 0.0), cap, pivot)
	if bool(p["block"]):
		var b := _box(Vector3(0.45, 0.3, 0.4), Vector3(-float(p["side"]) * 0.1, 0.15, -0.7), stone, root)
		b.rotation.y = float(p["block_rot"])
	_pillars[int(p["id"])] = {"root": root, "pivot": pivot, "side": float(p["side"]), "h": h, "fall": false, "age": 0.0, "dur": 0.5, "hit_t": 0.0}


## Évènements du terrain (retourne faux si l'évènement ne le concerne pas).
func handle(e: Dictionary) -> bool:
	match str(e["t"]):
		"prop_hit":
			var pn: Dictionary = _pillars.get(int(e["id"]), {})
			if not pn.is_empty():
				pn["hit_t"] = 0.2
				fx.dust(pn["root"].position + Vector3(0.0, 0.6, 0.0), Vector3(0.3, 0.4, 0.3), Color("a89878"), 10)
		"prop_fall":
			var pn: Dictionary = _pillars.get(int(e["id"]), {})
			if not pn.is_empty():
				pn["fall"] = true
				pn["age"] = 0.0
				pn["dur"] = float(e.get("dur", 0.5))
		"prop_crash":
			var pn: Dictionary = _pillars.get(int(e["id"]), {})
			var rc: Rect2 = e["rect"]
			fx.dust(w3(rc.get_center(), 0.2), Vector3(rc.size.x * 0.5, 0.2, 0.5), Color("b8a888"), 60)
			if not pn.is_empty():
				# Débris éparpillés sur la chaussée.
				var root: Node3D = pn["root"]
				for k in range(5):
					var q := Vector2(randf_range(rc.position.x, rc.end.x), randf_range(rc.position.y, rc.end.y))
					var b := _box(Vector3(randf_range(0.15, 0.3), randf_range(0.1, 0.2), randf_range(0.15, 0.3)), w3(q, 0.08) - root.position, stone, root)
					b.rotation.y = randf() * TAU
		"wall":
			var root := Node3D.new()
			root.position = w3(e["pos"])
			add_child(root)
			var mat := StandardMaterial3D.new()
			if stone is StandardMaterial3D:
				mat = (stone as StandardMaterial3D).duplicate()
			var hw := float(e["hw"])
			_box(Vector3(hw * 2.0, 1.0, 0.44), Vector3(0.0, 0.5, 0.0), mat, root)
			for k in range(int(hw * 2.0 / 0.5)):
				var cren := _box(Vector3(0.28, 0.18, 0.46), Vector3(-hw + 0.25 + float(k) * 0.5, 1.09, 0.0), mat, root)
				cren.visible = k % 2 == 0
			mat.albedo_color = WALL_TINT
			# Barre de vie du mur.
			var bg := StandardMaterial3D.new()
			bg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			bg.albedo_color = Color("1a1410")
			_box(Vector3(hw * 1.6, 0.07, 0.06), Vector3(0.0, 1.45, 0.25), bg, root)
			var fm := StandardMaterial3D.new()
			fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			fm.albedo_color = Color("e8c070")
			var fill := _box(Vector3(hw * 1.6, 0.07, 0.07), Vector3(0.0, 1.45, 0.26), fm, root)
			root.scale = Vector3(1.0, 0.05, 1.0)
			_walls[int(e["id"])] = {"node": root, "mat": mat, "age": 0.0, "hp": -1.0, "fill": fill, "fill_mat": fm, "hw": hw}
			fx.dust(root.position + Vector3(0.0, 0.1, 0.0), Vector3(hw, 0.1, 0.4), Color("b8a888"), 40)
		"wall_break":
			var wn: Dictionary = _walls.get(int(e["id"]), {})
			fx.dust(w3(e["pos"], 0.5), Vector3(float(e["hw"]), 0.5, 0.3), Color("a89878"), 50)
			if not wn.is_empty():
				(wn["node"] as Node3D).queue_free()
				_walls.erase(int(e["id"]))
		_:
			return false
	return true


# ---------------------------------------------------------------- mise à jour

func update(delta: float) -> void:
	t += delta
	for id in _pillars.keys():
		var pn: Dictionary = _pillars[id]
		var pivot: Node3D = pn["pivot"]
		if bool(pn["fall"]):
			pn["age"] = float(pn["age"]) + delta
			var k := clampf(float(pn["age"]) / maxf(0.05, float(pn["dur"])), 0.0, 1.0)
			var bounce := 0.06 * sin(clampf(float(pn["age"]) - float(pn["dur"]), 0.0, 0.3) * 20.0) * (1.0 if k >= 1.0 else 0.0)
			pivot.rotation.z = float(pn["side"]) * (PI * 0.5 * k * k - bounce)
		if float(pn["hit_t"]) > 0.0:
			pn["hit_t"] = float(pn["hit_t"]) - delta
			pivot.position.x = randf_range(-0.04, 0.04) if float(pn["hit_t"]) > 0.0 else 0.0
	for id in _walls.keys():
		var wn: Dictionary = _walls[id]
		var node: Node3D = wn["node"]
		wn["age"] = float(wn["age"]) + delta
		node.scale.y = clampf(float(wn["age"]) / 0.25, 0.05, 1.0)
		for w in sim.terrain.walls:
			if int(w["id"]) == int(id):
				var ratio := clampf(float(w["hp"]) / maxf(1.0, float(w["max_hp"])), 0.0, 1.0)
				var hit := float(wn["hp"]) >= 0.0 and float(w["hp"]) < float(wn["hp"]) - 0.01
				wn["hp"] = float(w["hp"])
				(wn["mat"] as StandardMaterial3D).albedo_color = WALL_TINT.lerp(Color(0.55, 0.45, 0.4), 1.0 - ratio)
				var fill: MeshInstance3D = wn["fill"]
				fill.scale.x = maxf(0.02, ratio)
				fill.position.x = -float(wn["hw"]) * 0.8 * (1.0 - ratio)
				(wn["fill_mat"] as StandardMaterial3D).albedo_color = Color("e05a3a").lerp(Color("e8c070"), ratio)
				node.position.x = (w["pos"] as Vector2).x + (randf_range(-0.03, 0.03) if hit else 0.0)
	_update_surfaces(delta)


func _update_surfaces(delta: float) -> void:
	for id in _surf.keys():
		_surf[id]["seen"] = false
	for s in sim.terrain.surfaces:
		var id := int(s["id"])
		if not _surf.has(id):
			_surf[id] = _make_surface(s)
		var sn: Dictionary = _surf[id]
		sn["seen"] = true
		sn["age"] = float(sn["age"]) + delta
		var r := float(s["r"])
		if absf(r - float(sn["r"])) > 0.01 and not s.has("rect"):
			sn["r"] = r
			((sn["mesh"] as MeshInstance3D).mesh as PlaneMesh).size = Vector2(r * 2.0, r * 2.0)
		var kind := str(s["kind"])
		if kind != str(sn["kind"]):
			# Eau gelée en verglas : nouvelle texture.
			sn["kind"] = kind
			(sn["mat"] as StandardMaterial3D).albedo_texture = FxArt.ground(kind)
		var a := clampf(float(sn["age"]) / 0.25, 0.0, 1.0)
		if not bool(s.get("permanent", false)):
			a *= clampf(float(s["t"]) / 0.8, 0.0, 1.0)
		match kind:
			"rune":
				a *= 0.7 + 0.3 * sin(t * 5.0 + float(id))
			"statique":
				a *= 0.75 + 0.25 * sin(t * 31.0 + float(id) * 3.0)
			"braises":
				a *= 0.9 + 0.1 * sin(t * 7.0 + float(id))
		(sn["mat"] as StandardMaterial3D).albedo_color = Color(1, 1, 1, a)
	for id in _surf.keys():
		var sn: Dictionary = _surf[id]
		if bool(sn["seen"]):
			continue
		if str(sn["kind"]) == "braises":
			_add_scorch((sn["mesh"] as MeshInstance3D).position, float(sn["r"]))
		(sn["mesh"] as Node3D).queue_free()
		if sn["parts"] != null:
			(sn["parts"] as Node3D).queue_free()
		_surf.erase(id)


func _make_surface(s: Dictionary) -> Dictionary:
	var kind := str(s["kind"])
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	var r := float(s["r"])
	pm.size = (s["rect"] as Rect2).size if s.has("rect") else Vector2(r * 2.0, r * 2.0)
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = FxArt.ground(kind)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.albedo_color = Color(1, 1, 1, 0)
	mi.material_override = m
	mi.position = w3(s["pos"], 0.022 + float(int(s["id"]) % 9) * 0.002)
	if kind in ["fissure", "gravats", "cratere"]:
		mi.rotation.y = randf() * TAU
	add_child(mi)
	var parts: CPUParticles3D = null
	var pc: Array = []
	match kind:
		"braises":
			pc = [Color("ffd070"), Color("ff8a3a"), Color(0.6, 0.15, 0.05, 0.0)]
		"verglas":
			pc = [Color.WHITE, Color("cff4ff"), Color(0.8, 0.95, 1.0, 0.0)]
		"miasme":
			pc = [Color(0.7, 0.5, 1.0, 0.6), Color("5a2a9a"), Color(0.2, 0.05, 0.3, 0.0)]
		"statique":
			pc = [Color.WHITE, Color("f0d23c"), Color(0.9, 0.8, 0.2, 0.0)]
		"rune":
			pc = [Color.WHITE, Color("c8a8ff"), Color(0.6, 0.4, 1.0, 0.0)]
		"eau":
			pc = [Color(0.8, 0.9, 1.0, 0.6), Color("5aa0c8"), Color(0.3, 0.5, 0.8, 0.0)]
		"poison":
			pc = [Color(0.8, 1.0, 0.5, 0.8), Color("7ab040"), Color(0.3, 0.5, 0.15, 0.0)]
	if not pc.is_empty():
		parts = CPUParticles3D.new()
		var area := r * r
		parts.amount = clampi(int(area * (5.0 if kind == "verglas" else 9.0)), 6, 60)
		parts.lifetime = 0.5 if kind == "statique" else 1.4
		parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		parts.emission_box_extents = Vector3(r * 0.65, 0.05, r * 0.65)
		parts.direction = Vector3.UP
		parts.spread = 25.0 if kind != "statique" else 80.0
		parts.initial_velocity_min = 0.2
		parts.initial_velocity_max = 1.6 if kind == "statique" else 0.7
		parts.gravity = Vector3(0, 0.3, 0)
		var q := QuadMesh.new()
		q.size = Vector2(0.07, 0.07)
		var pm2 := StandardMaterial3D.new()
		pm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pm2.vertex_color_use_as_albedo = true
		pm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pm2.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		q.material = pm2
		parts.mesh = q
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		g.colors = PackedColorArray(pc)
		parts.color_ramp = g
		parts.position = w3(s["pos"], 0.08)
		add_child(parts)
	return {"mesh": mi, "mat": m, "parts": parts, "kind": kind, "age": 0.0, "r": r, "seen": true}


## Brûlure qui reste au sol jusqu'à la fin du combat.
func _add_scorch(pos: Vector3, r: float) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(r * 2.2, r * 2.2)
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = FxArt.scorch()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.albedo_color = Color(1, 1, 1, 0.7)
	mi.material_override = m
	mi.position = Vector3(pos.x, 0.018, pos.z)
	mi.rotation.y = randf() * TAU
	add_child(mi)
	_decals.append(mi)
	while _decals.size() > MAX_DECALS:
		_decals.pop_front().queue_free()
