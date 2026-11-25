class_name SpellFx
extends Node3D
## Animations des sorts et pouvoirs dans l'arène 3D : projectiles (Boule de feu, Météore),
## explosions, pluie de givre, racines, vortex d'ombre, éclair en chaîne, onde de choc,
## colonne de lumière (Purifier), bouclier, invocation du Champion, flèche de précision.
## Les nœuds (particules, sprites, lumières) sont créés à la demande puis libérés ; les effets
## en traits (foudre, spirale, ondes) sont ajoutés aux lignes de l'arène par collect().

const TEXEL := 0.058

var t := 0.0
var _nodes: Array[Dictionary] = []
var _line_fx: Array[Dictionary] = []
var _pmesh: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var sig: SpellSig ## signatures propres à chaque sort (scripts/battle/spell_sig.gd)


static func w3(p: Vector2, h: float = 0.0) -> Vector3:
	return Vector3(p.x, h, -p.y)


func _ready() -> void:
	_rng.seed = 4321
	sig = SpellSig.new(self)


## Prend en charge un évènement de la simulation ; retourne faux s'il ne concerne pas un sort.
func handle(e: Dictionary) -> bool:
	if e.has("sid") and sig != null:
		# Animation propre au sort ; à défaut, l'animation générique de la phase.
		if sig.play(e):
			return true
		if str(e["t"]) == "spell":
			return true
	elif str(e["t"]) == "spell":
		return true
	var col := Color(str(e.get("color", "FFFFFF")))
	match str(e["t"]):
		"fireball", "meteor":
			_projectile(e)
		"explosion":
			_explosion(e, col)
		"rain":
			_rain(e, col)
		"roots":
			_roots(e, col)
		"vortex":
			_vortex(e, col)
		"blaze":
			_blaze(e, col)
		"wave":
			_wave(e, col)
		"lightning":
			_lightning(e, col)
		"pillar":
			_pillar(w3(e["pos"]), col, 6.0, float(e.get("dur", 1.0)), 1.0)
			_burst(w3(e["pos"], 0.2), 30, [Color(1, 1, 0.92, 1), Color(col, 0.9), Color(col, 0.0)], 3.0, 0.11, 0.9, 1.5, 25.0)
			_line_fx.append({"kind": "shock", "pos": e["pos"], "r": 1.2, "age": 0.0, "dur": 0.6, "color": col})
		"shield":
			_shield(col)
		"summon":
			_pillar(w3(e["pos"]), col, 3.2, 0.8, 0.8)
			_burst(w3(e["pos"], 0.15), 32, [Color(1, 0.95, 0.8, 1), col, Color(col, 0.0)], 2.6, 0.12, 0.8, -3.0, 70.0)
		"arrow":
			_line_fx.append({"kind": "arrow", "a": e["a"], "b": e["b"], "age": 0.0, "dur": float(e.get("dur", 0.3)), "color": col})
		"wind":
			_wind(e)
		"bolt":
			# Éclair tombé du ciel (Orage, Colère du ciel) : cible marquée, puis frappe à l'impact.
			_line_fx.append({"kind": "mark", "pos": e["to"], "r": float(e.get("r", 1.0)), "age": 0.0, "dur": float(e["dur"]), "color": col})
			_line_fx.append({"kind": "bolt", "pos": e["to"], "age": -float(e["dur"]), "dur": 0.35, "color": col, "seed": _rng.randi() % 1000})
		"column":
			_column(e, col)
		"quake":
			_quake(e, col)
		"steam":
			var sp3 := w3(e["pos"], 0.3)
			var sr := float(e.get("r", 1.5))
			_burst(sp3, 40 + int(sr * 20.0), [Color(1, 1, 1, 0.95), Color(0.9, 0.95, 1.0, 0.6), Color(1, 1, 1, 0.0)], 2.6, 0.35, 1.3, 1.2, 70.0)
			_flash(sp3 + Vector3(0, 0.4, 0), sr * 2.0, Color(1, 1, 1, 0.8), 0.4)
		"ground":
			var gp := w3(e["pos"], 0.15)
			_burst(gp, 26, [Color.WHITE, col, Color(col, 0.0)], 1.8, 0.1, 0.6, -2.0, 70.0)
			_line_fx.append({"kind": "shock", "pos": e["pos"], "r": float(e.get("r", 1.5)), "age": 0.0, "dur": 0.5, "color": col})
		"avalanche":
			# Avalanche : une coulée de neige dévale toute la rangée.
			var r: Rect2 = e["rect"]
			var c3 := w3(r.get_center(), 0.3)
			var ext := Vector3(r.size.x * 0.5, 0.2, r.size.y * 0.5)
			sig.emit(c3 + Vector3(0, 1.2, 0), ext, 160, 0.9, Vector3(0.2, -1.0, 0.0), 25.0, Vector2(2.0, 5.0), -6.0, 0.16,
				[Color.WHITE, Color("eaf4fb"), Color(0.7, 0.85, 1.0, 0.0)])
			dust(c3, ext, Color("dcecf8"), 120)
			_line_fx.append({"kind": "shock", "pos": r.get_center(), "r": r.size.x * 0.5, "age": 0.0, "dur": 0.5, "color": Color("eaf4fb")})
		"trap":
			_explosion(e, col)
		"rally":
			_line_fx.append({"kind": "shock", "pos": e.get("from", e["pos"]), "r": 2.5, "age": 0.0, "dur": 0.6, "color": col})
		"storm":
			_rain(e, col)
			_line_fx.append({"kind": "storm", "pos": e["pos"], "r": float(e["r"]), "age": 0.0, "dur": float(e["dur"]), "color": col})
		"shot_fire", "shot_hit", "shot_beam", "shot_end", "rise", "fireflies":
			# Tirs de classe (scripts/battle/shot_fx.gd).
			ShotFx.play(self, e)
		_:
			return false
	return true


# ---------------------------------------------------------------- sorts

func _projectile(e: Dictionary) -> void:
	var meteor := str(e["t"]) == "meteor"
	var to: Vector2 = e["to"]
	var tint := bool(e.get("tint", false))
	var col := Color(str(e.get("color", "FFFFFF")))
	var spr := Sprite3D.new()
	spr.texture = FxArt.orb_tint(col) if tint else FxArt.orb("meteor" if meteor else "fire")
	spr.pixel_size = TEXEL * (2.6 if meteor else 1.9) * (1.25 if tint and meteor else 1.0)
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.shaded = false
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	add_child(spr)
	var trail := CPUParticles3D.new()
	trail.amount = 48 if meteor else 28
	trail.lifetime = 0.5 if meteor else 0.32
	trail.local_coords = false
	trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 0.14 if meteor else 0.07
	trail.direction = Vector3.UP
	trail.spread = 180.0
	trail.initial_velocity_min = 0.1
	trail.initial_velocity_max = 0.5
	trail.gravity = Vector3(0, 0.8, 0)
	trail.mesh = _pm(0.16 if meteor else 0.11)
	if tint:
		trail.color_ramp = _ramp([Color.WHITE, col.lightened(0.4), col, Color(col.darkened(0.4), 0.0)])
	elif meteor:
		trail.color_ramp = _ramp([Color("ffffff"), Color("e8d0ff"), Color("b07cff"), Color(0.55, 0.25, 0.9, 0.0)])
	else:
		trail.color_ramp = _ramp([Color("fff3b0"), Color("ffb04a"), Color("e0502a"), Color(0.5, 0.12, 0.08, 0.0)])
	spr.add_child(trail)
	var from: Vector3 = w3(e["from"], 1.1)
	if meteor:
		from = w3(to + Vector2(-2.4, 3.2), 9.5)
	spr.position = from
	_nodes.append({"kind": "projectile", "node": spr, "trail": trail, "age": 0.0, "fly": float(e["dur"]),
		"dur": float(e["dur"]) + trail.lifetime + 0.05, "from": from, "to": w3(to, 0.35), "arc": 0.0 if meteor else 1.7})


func _explosion(e: Dictionary, col: Color) -> void:
	var big := bool(e.get("big", false))
	var r := float(e.get("r", 1.5))
	var pos: Vector2 = e["pos"]
	var p := w3(pos, 0.3)
	var hot := Color("ffffff") if big else Color("fff3b0")
	var sec := Color("ff9b4a") if big else col.darkened(0.25)
	_flash(p + Vector3(0, 0.35, 0), r * 2.7, hot.lerp(col, 0.3), 0.42)
	_burst(p, 30 + int(r * 10.0) + (60 if big else 0), [hot, col, sec, Color(sec.darkened(0.5), 0.0)],
		3.4 + r * 1.7, 0.18 if big else 0.13, 0.85, -6.0, 75.0)
	_burst(p, 14 + (24 if big else 0), [Color(0.32, 0.26, 0.3, 0.75), Color(0.18, 0.16, 0.2, 0.0)], 1.0 + r * 0.5, 0.24, 1.1, 0.9, 95.0)
	_light(p + Vector3(0, 0.7, 0), col.lerp(Color.WHITE, 0.2), r * 2.8, 3.2 if big else 2.2, 0.4)
	if bool(e.get("ice", false)):
		# Prison de glace : éclats de cristal et givre au sol au lieu de la brûlure.
		_burst(p, 30, [Color.WHITE, Color("cff4ff"), Color(0.6, 0.85, 1.0, 0.0)], 3.0, 0.1, 0.6, -7.0, 70.0)
		_disc(pos, r, Color(0.7, 0.92, 1.0, 0.3), 2.0)
	else:
		_scorch(pos, r * 0.85, 2.0)
	_ripple(pos, r, Color(col, 0.35), 0.45)
	_line_fx.append({"kind": "shock", "pos": pos, "r": r, "age": 0.0, "dur": 0.45, "color": col})
	if big:
		_line_fx.append({"kind": "shock", "pos": pos, "r": r * 1.5, "age": -0.12, "dur": 0.6, "color": Color("ff9b4a")})


func _rain(e: Dictionary, col: Color) -> void:
	var r := float(e["r"])
	var dur := float(e["dur"])
	var pos: Vector2 = e["pos"]
	var p := CPUParticles3D.new()
	p.amount = 40 + int(r * 20.0)
	p.lifetime = 0.5
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(r * 0.72, 0.05, r * 0.72)
	p.direction = Vector3.DOWN
	p.spread = 6.0
	p.initial_velocity_min = 5.5
	p.initial_velocity_max = 7.5
	p.gravity = Vector3(0, -4.0, 0)
	p.mesh = _streak()
	p.color_ramp = _ramp([Color(0.92, 0.99, 1.0, 0.95), Color(col, 0.85), Color(col, 0.0)])
	p.position = w3(pos, 3.5)
	add_child(p)
	_nodes.append({"kind": "emitter", "node": p, "age": 0.0, "stop": dur, "dur": dur + p.lifetime + 0.05})
	var s := CPUParticles3D.new()
	s.amount = 22
	s.lifetime = 0.35
	s.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	s.emission_box_extents = Vector3(r * 0.7, 0.02, r * 0.7)
	s.direction = Vector3.UP
	s.spread = 45.0
	s.initial_velocity_min = 0.8
	s.initial_velocity_max = 1.8
	s.gravity = Vector3(0, -8.0, 0)
	s.mesh = _pm(0.08)
	s.color_ramp = _ramp([Color(1, 1, 1, 0.9), Color(col, 0.0)])
	s.position = w3(pos, 0.08)
	add_child(s)
	_nodes.append({"kind": "emitter", "node": s, "age": 0.0, "stop": dur, "dur": dur + s.lifetime + 0.05})
	_disc(pos, r, Color(0.6, 0.88, 1.0, 0.2), dur)
	_line_fx.append({"kind": "zone", "pos": pos, "r": r, "age": 0.0, "dur": dur, "color": col})


## Vent des steppes : traits d'air (annonce), puis rafale de poussière et d'herbe qui balaie l'arène.
func _wind(e: Dictionary) -> void:
	var dir := float(e.get("dir", 1.0))
	var dur := float(e.get("dur", 2.0))
	var blow := str(e.get("phase", "")) == "blow"
	_line_fx.append({"kind": "wind", "dir": dir, "blow": blow, "age": 0.0, "dur": dur, "color": Color("fff4dc"), "seed": _rng.randf() * 10.0})
	if not blow:
		return
	var p := CPUParticles3D.new()
	p.amount = 90
	p.lifetime = 0.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(1.0, 0.5, 8.0)
	p.direction = Vector3(dir, 0.04, 0.0)
	p.spread = 5.0
	p.initial_velocity_min = 9.0
	p.initial_velocity_max = 13.0
	p.gravity = Vector3.ZERO
	p.mesh = _hstreak()
	p.color_ramp = _ramp([Color(1, 0.96, 0.85, 0.0), Color(1, 0.96, 0.85, 0.75), Color(0.95, 0.85, 0.6, 0.0)])
	p.position = w3(Vector2(4.5 - dir * 6.0, 8.0), 0.55)
	add_child(p)
	_nodes.append({"kind": "emitter", "node": p, "age": 0.0, "stop": dur, "dur": dur + p.lifetime + 0.05})
	var d := CPUParticles3D.new()
	d.amount = 40
	d.lifetime = 1.0
	d.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	d.emission_box_extents = Vector3(1.0, 0.3, 8.0)
	d.direction = Vector3(dir, 0.25, 0.0)
	d.spread = 20.0
	d.initial_velocity_min = 6.0
	d.initial_velocity_max = 9.0
	d.gravity = Vector3(0, -1.5, 0)
	d.mesh = _pm(0.07)
	d.color_ramp = _ramp([Color("e8c070"), Color("b8a048"), Color(0.8, 0.6, 0.3, 0.0)])
	d.position = w3(Vector2(4.5 - dir * 6.0, 8.0), 0.3)
	add_child(d)
	_nodes.append({"kind": "emitter", "node": d, "age": 0.0, "stop": dur, "dur": dur + d.lifetime + 0.05})


## Sorts en colonne : gerbe d'effets le long de la colonne visée (flammes, glace, épines, ombre, rayon).
func _column(e: Dictionary, col: Color) -> void:
	var x := float(e["x"])
	var y0 := float(e["y0"])
	var y1 := float(e["y1"])
	var w := float(e.get("w", 0.8))
	var kind := str(e.get("fx", "beam"))
	var mid := Vector2(x, (y0 + y1) * 0.5)
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.85
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(w * 0.35, 0.05, (y1 - y0) * 0.5)
	p.direction = Vector3.UP
	p.position = w3(mid, 0.1)
	match kind:
		"flames":
			p.amount = 200
			p.lifetime = 0.9
			p.spread = 14.0
			p.initial_velocity_min = 1.6
			p.initial_velocity_max = 3.6
			p.gravity = Vector3(0, 1.5, 0)
			p.mesh = _pm(0.24)
			p.color_ramp = _ramp([Color("fff3b0"), Color("ffb04a"), col, Color(0.5, 0.1, 0.05, 0.0)])
			_light(w3(mid, 1.0), col, 7.0, 2.4, 0.6)
		"ice", "thorns", "stone":
			p.amount = 140
			p.lifetime = 0.7
			p.spread = 8.0
			p.initial_velocity_min = 2.4
			p.initial_velocity_max = 4.2
			p.gravity = Vector3(0, -9.0, 0)
			p.mesh = _streak() if kind != "stone" else _pm(0.16)
			p.color_ramp = _ramp([Color.WHITE, col, Color(col.darkened(0.3), 0.0)])
			if kind == "stone":
				p.color_ramp = _ramp([Color("d8c8a8"), col, Color(col.darkened(0.4), 0.0)])
				dust(w3(mid, 0.2), Vector3(w * 0.4, 0.1, (y1 - y0) * 0.5), Color("b8a888"), 50)
		"shadow":
			p.amount = 120
			p.lifetime = 0.9
			p.spread = 30.0
			p.initial_velocity_min = 0.6
			p.initial_velocity_max = 1.6
			p.gravity = Vector3(0, 0.8, 0)
			p.mesh = _pm(0.18)
			p.color_ramp = _ramp([Color(col.lightened(0.3), 0.9), col, Color(0.1, 0.05, 0.2, 0.0)])
		_:
			p.amount = 60
			p.lifetime = 0.5
			p.spread = 40.0
			p.initial_velocity_min = 0.8
			p.initial_velocity_max = 2.0
			p.gravity = Vector3.ZERO
			p.mesh = _pm(0.1)
			p.color_ramp = _ramp([Color.WHITE, col, Color(col, 0.0)])
			_light(w3(mid, 1.0), col, 7.0, 2.0, 0.4)
	add_child(p)
	p.emitting = true
	_nodes.append({"kind": "free", "node": p, "age": 0.0, "dur": p.lifetime + 0.2})
	_line_fx.append({"kind": "colband", "x": x, "w": w, "y0": y0, "y1": y1, "age": 0.0, "dur": 0.45, "color": col})


## Séisme : la terre se soulève sur toute la largeur de la bande (poussière, roches projetées).
func _quake(e: Dictionary, col: Color) -> void:
	var pos: Vector2 = e["pos"]
	var band := minf(float(e.get("band", 2.0)), 8.0)
	var cy := clampf(pos.y, band, BattleSim.H - band) if band >= 7.9 else pos.y
	dust(w3(Vector2(4.5, cy), 0.1), Vector3(4.6, 0.1, band), Color("b8a888"), 80 + int(band * 20.0))
	var r := CPUParticles3D.new()
	r.one_shot = true
	r.explosiveness = 0.9
	r.amount = 40 + int(band * 10.0)
	r.lifetime = 1.0
	r.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	r.emission_box_extents = Vector3(4.6, 0.05, band)
	r.direction = Vector3.UP
	r.spread = 20.0
	r.initial_velocity_min = 2.0
	r.initial_velocity_max = 4.5
	r.gravity = Vector3(0, -12.0, 0)
	r.mesh = _pm(0.12)
	r.color_ramp = _ramp([Color("8a7a60"), Color("5a4a3a"), Color(0.3, 0.25, 0.2, 0.0)])
	r.position = w3(Vector2(4.5, cy), 0.1)
	add_child(r)
	r.emitting = true
	_nodes.append({"kind": "free", "node": r, "age": 0.0, "dur": 1.2})
	_line_fx.append({"kind": "shock", "pos": Vector2(4.5, cy), "r": 4.8, "age": 0.0, "dur": 0.6, "color": col})


## Nuage de poussière (impacts, piliers, murs, séismes).
func dust(p: Vector3, ext: Vector3, col: Color, amount: int) -> void:
	var b := CPUParticles3D.new()
	b.one_shot = true
	b.explosiveness = 0.85
	b.amount = clampi(amount, 4, 300)
	b.lifetime = 1.1
	b.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	b.emission_box_extents = ext
	b.direction = Vector3.UP
	b.spread = 60.0
	b.initial_velocity_min = 0.4
	b.initial_velocity_max = 1.6
	b.gravity = Vector3(0, -0.6, 0)
	b.damping_min = 0.6
	b.damping_max = 1.4
	b.scale_amount_min = 0.8
	b.scale_amount_max = 1.8
	b.mesh = _pm(0.2)
	b.color_ramp = _ramp([Color(col, 0.8), Color(col.darkened(0.15), 0.5), Color(col, 0.0)])
	b.position = p
	add_child(b)
	b.emitting = true
	_nodes.append({"kind": "free", "node": b, "age": 0.0, "dur": 1.3})


func _roots(e: Dictionary, col: Color) -> void:
	var r := float(e["r"])
	var dur := float(e["dur"])
	var pos: Vector2 = e["pos"]
	var n := 9 + int(r * 4.0)
	for i in range(n):
		var a := _rng.randf() * TAU
		var d := sqrt(_rng.randf()) * r * 0.92
		var spr := Sprite3D.new()
		spr.texture = FxArt.root(i % 2)
		spr.pixel_size = TEXEL * _rng.randf_range(1.2, 1.7)
		spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		spr.shaded = false
		spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		spr.offset = Vector2(0, 13)
		spr.flip_h = _rng.randf() < 0.5
		spr.position = w3(pos + Vector2(cos(a), sin(a)) * d, 0.0)
		spr.scale = Vector3(1.0, 0.01, 1.0)
		add_child(spr)
		_nodes.append({"kind": "root", "node": spr, "age": -_rng.randf_range(0.0, 0.25), "dur": dur, "grow": 0.22})
	var l := CPUParticles3D.new()
	l.amount = 16
	l.lifetime = 0.9
	l.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	l.emission_box_extents = Vector3(r * 0.7, 0.05, r * 0.7)
	l.direction = Vector3.UP
	l.spread = 35.0
	l.initial_velocity_min = 0.5
	l.initial_velocity_max = 1.2
	l.gravity = Vector3(0, 0.2, 0)
	l.mesh = _pm(0.09)
	l.color_ramp = _ramp([Color("c8f5a0"), Color(col, 0.8), Color(0.2, 0.4, 0.15, 0.0)])
	l.position = w3(pos, 0.1)
	add_child(l)
	_nodes.append({"kind": "emitter", "node": l, "age": 0.0, "stop": dur, "dur": dur + l.lifetime + 0.05})
	_disc(pos, r, Color(0.22, 0.42, 0.16, 0.28), dur)
	_line_fx.append({"kind": "zone", "pos": pos, "r": r, "age": 0.0, "dur": dur, "color": col})


## Brasier : flammes qui montent du sol, disque rougeoyant, lumière orangée.
func _blaze(e: Dictionary, col: Color) -> void:
	var r := float(e["r"])
	var dur := float(e["dur"])
	var pos: Vector2 = e["pos"]
	var p := CPUParticles3D.new()
	p.amount = 40 + int(r * 16.0)
	p.lifetime = 0.7
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(r * 0.7, 0.05, r * 0.7)
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.6
	p.gravity = Vector3(0, 1.5, 0)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.6
	p.mesh = _pm(0.12)
	p.color_ramp = _ramp([Color("fff3b0"), Color("ffb04a"), Color("e0502a"), Color(0.3, 0.1, 0.1, 0.0)])
	p.position = w3(pos, 0.1)
	add_child(p)
	_nodes.append({"kind": "emitter", "node": p, "age": 0.0, "stop": dur, "dur": dur + p.lifetime + 0.05})
	_disc(pos, r, Color(0.9, 0.35, 0.12, 0.3), dur)
	_light(w3(pos, 0.9), col, r * 2.4, 2.0, dur)
	_line_fx.append({"kind": "zone", "pos": pos, "r": r, "age": 0.0, "dur": dur, "color": col})


func _vortex(e: Dictionary, col: Color) -> void:
	var r := float(e["r"])
	var dur := float(e["dur"])
	var pos: Vector2 = e["pos"]
	_disc(pos, r, Color(0.12, 0.03, 0.26, 0.6), dur)
	_light(w3(pos, 0.9), col, r * 2.2, 2.2, dur)
	_line_fx.append({"kind": "vortex", "pos": pos, "r": r, "age": 0.0, "dur": dur, "color": col})


func _wave(e: Dictionary, col: Color) -> void:
	var r := float(e["r"])
	var pos: Vector2 = e["pos"]
	_flash(w3(pos, 0.5), r * 2.0, col.lerp(Color.WHITE, 0.3), 0.35)
	_ripple(pos, r * 1.1, Color(col, 0.45), 0.6)
	_burst(w3(pos, 0.3), 46, [Color.WHITE, col, Color(col, 0.0)], 5.0, 0.12, 0.55, -1.0, 88.0)
	_light(w3(pos, 0.8), col, r * 2.5, 2.2, 0.35)
	_line_fx.append({"kind": "wave", "pos": pos, "r": r, "age": 0.0, "dur": float(e.get("dur", 0.7)), "color": col})


func _lightning(e: Dictionary, col: Color) -> void:
	var pts: Array = e["pts"]
	_line_fx.append({"kind": "lightning", "pts": pts, "age": 0.0, "dur": float(e.get("dur", 0.45)), "color": col})
	for i in range(1, pts.size()):
		_flash(w3(pts[i], 0.55), 1.4, col.lerp(Color.WHITE, 0.45), 0.32)
		_burst(w3(pts[i], 0.45), 12, [Color.WHITE, col, Color(col, 0.0)], 2.6, 0.1, 0.4, -5.0, 180.0)
	if pts.size() > 1:
		_light(w3(pts[1], 1.0), col, 4.5, 2.6, 0.3)


func _shield(col: Color) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.35
	p.amount = 70
	p.lifetime = 1.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(4.6, 0.05, 0.15)
	p.position = w3(Vector2(4.5, BattleSim.BARRIER_Y), 0.15)
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.4
	p.gravity = Vector3(0, 0.5, 0)
	p.mesh = _pm(0.11)
	p.color_ramp = _ramp([Color(1, 1, 1, 1), col, Color(col, 0.0)])
	add_child(p)
	p.emitting = true
	_nodes.append({"kind": "free", "node": p, "age": 0.0, "dur": 1.2})
	_light(w3(Vector2(4.5, BattleSim.BARRIER_Y), 0.8), col, 6.0, 1.8, 0.6)


# ---------------------------------------------------------------- éléments communs

func _pillar(base: Vector3, col: Color, height: float, dur: float, width: float) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(width, height)
	q.center_offset = Vector3(0, height * 0.5, 0)
	mi.mesh = q
	var m := _add_mat(FxArt.beam(), col)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mi.material_override = m
	mi.position = base
	add_child(mi)
	_nodes.append({"kind": "pillar", "node": mi, "mat": m, "age": 0.0, "dur": dur, "col": col})
	_light(base + Vector3(0, 1.2, 0), col, 3.5, 2.0, dur)


func _flash(p: Vector3, size: float, col: Color, dur: float) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	var m := _add_mat(FxArt.flash(), col)
	mi.material_override = m
	mi.position = p
	add_child(mi)
	_nodes.append({"kind": "flash", "node": mi, "mat": m, "age": 0.0, "dur": dur, "col": col})


## Disque au sol qui s'élargit et s'efface (impact, onde de choc).
func _ripple(pos: Vector2, r: float, col: Color, dur: float) -> void:
	_disc(pos, r, col, dur)
	var f: Dictionary = _nodes[_nodes.size() - 1]
	f["kind"] = "ripple"


func _disc(pos: Vector2, r: float, col: Color, dur: float) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.02
	cm.radial_segments = 32
	cm.rings = 1
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(col, 0.0)
	mi.material_override = m
	mi.position = w3(pos, 0.035)
	add_child(mi)
	_nodes.append({"kind": "disc", "node": mi, "mat": m, "age": 0.0, "dur": dur, "col": col})


func _scorch(pos: Vector2, r: float, dur: float) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(r * 2.0, r * 2.0)
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = FxArt.scorch()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mi.material_override = m
	mi.position = w3(pos, 0.03)
	add_child(mi)
	_nodes.append({"kind": "scorch", "node": mi, "mat": m, "age": 0.0, "dur": dur})


func _light(p: Vector3, col: Color, reach: float, energy: float, dur: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.omni_range = reach
	l.light_energy = energy
	l.position = p
	add_child(l)
	_nodes.append({"kind": "light", "node": l, "age": 0.0, "dur": dur, "energy": energy})


func _burst(p: Vector3, amount: int, cols: Array, speed: float, size: float, life: float, gravity: float, spread: float) -> void:
	var b := CPUParticles3D.new()
	b.one_shot = true
	b.explosiveness = 0.95
	b.amount = amount
	b.lifetime = life
	b.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	b.emission_sphere_radius = 0.12
	b.direction = Vector3.UP
	b.spread = spread
	b.initial_velocity_min = speed * 0.45
	b.initial_velocity_max = speed
	b.gravity = Vector3(0, gravity, 0)
	b.damping_min = 0.5
	b.damping_max = 1.5
	b.scale_amount_min = 0.7
	b.scale_amount_max = 1.3
	b.mesh = _pm(size)
	b.color_ramp = _ramp(cols)
	b.position = p
	add_child(b)
	b.emitting = true
	_nodes.append({"kind": "free", "node": b, "age": 0.0, "dur": life + 0.15})


func _ramp(cols: Array) -> Gradient:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cs := PackedColorArray()
	for i in range(cols.size()):
		offs.append(float(i) / float(maxi(1, cols.size() - 1)))
		cs.append(cols[i])
	g.offsets = offs
	g.colors = cs
	return g


func _particle_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	# Garder l'échelle : les particules inactives (échelle nulle) restent invisibles au lieu de s'afficher
	# en carré noir, et la variation de taille des particules est respectée.
	m.billboard_keep_scale = true
	return m


func _pm(size: float) -> QuadMesh:
	var key := "p%.3f" % size
	if not _pmesh.has(key):
		var q := QuadMesh.new()
		q.size = Vector2(size, size)
		q.material = _particle_mat()
		_pmesh[key] = q
	return _pmesh[key]


## Gouttes de pluie : traits verticaux.
func _streak() -> QuadMesh:
	if not _pmesh.has("streak"):
		var q := QuadMesh.new()
		q.size = Vector2(0.05, 0.38)
		q.material = _particle_mat()
		_pmesh["streak"] = q
	return _pmesh["streak"]


## Traits de vent : horizontaux.
func _hstreak() -> QuadMesh:
	if not _pmesh.has("hstreak"):
		var q := QuadMesh.new()
		q.size = Vector2(0.55, 0.035)
		q.material = _particle_mat()
		_pmesh["hstreak"] = q
	return _pmesh["hstreak"]


## Matériau additif face caméra (halos, colonnes de lumière).
func _add_mat(tex: Texture2D, col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = tex
	m.albedo_color = col
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ---------------------------------------------------------------- animation

func _process(delta: float) -> void:
	t += delta
	var i := 0
	while i < _nodes.size():
		var f: Dictionary = _nodes[i]
		f["age"] = float(f["age"]) + delta
		var age := float(f["age"])
		var dur := float(f["dur"])
		var k := clampf(age / maxf(0.001, dur), 0.0, 1.0)
		var node: Node3D = f["node"]
		match str(f["kind"]):
			"projectile":
				var kf := clampf(age / float(f["fly"]), 0.0, 1.0)
				var p: Vector3 = (f["from"] as Vector3).lerp(f["to"], kf)
				p.y += sin(kf * PI) * float(f["arc"])
				node.position = p
				if kf >= 1.0:
					(f["trail"] as CPUParticles3D).emitting = false
					(node as Sprite3D).modulate = Color(1, 1, 1, 0)
			"flash":
				node.scale = Vector3.ONE * (0.6 + 0.7 * k)
				(f["mat"] as StandardMaterial3D).albedo_color = Color(f["col"], pow(1.0 - k, 1.5))
			"disc":
				var a := float((f["col"] as Color).a) * minf(1.0, age / 0.2) * clampf((dur - age) / 0.3, 0.0, 1.0)
				(f["mat"] as StandardMaterial3D).albedo_color = Color(f["col"], a * (0.85 + 0.15 * sin(t * 6.0)))
			"ripple":
				var e := 1.0 - pow(1.0 - k, 2.0)
				node.scale = Vector3(0.2 + 0.9 * e, 1.0, 0.2 + 0.9 * e)
				(f["mat"] as StandardMaterial3D).albedo_color = Color(f["col"], float((f["col"] as Color).a) * (1.0 - k))
			"scorch":
				(f["mat"] as StandardMaterial3D).albedo_color = Color(1, 1, 1, clampf((1.0 - k) * 1.6, 0.0, 1.0))
			"root":
				node.visible = age >= 0.0
				var g := clampf(age / float(f["grow"]), 0.0, 1.0)
				var s := g * clampf((dur - age) / 0.3, 0.0, 1.0)
				node.scale = Vector3(1.0, maxf(0.01, s * (1.0 + 0.04 * sin(t * 7.0 + node.position.x * 3.0))), 1.0)
			"pillar":
				var wgrow := sin(minf(k * 2.5, 1.0) * PI * 0.5)
				node.scale = Vector3(maxf(0.05, wgrow * (1.0 - smoothstep(0.7, 1.0, k))), 1.0, 1.0)
				(f["mat"] as StandardMaterial3D).albedo_color = Color(f["col"], 1.0 - k * k)
			"light":
				(node as OmniLight3D).light_energy = float(f["energy"]) * (1.0 - k) * minf(1.0, age / 0.05)
			"emitter":
				if age >= float(f["stop"]):
					(node as CPUParticles3D).emitting = false
				elif age < 0.05:
					(node as CPUParticles3D).emitting = true
			_:
				sig.animate(f, age, k, node)
		if age >= dur:
			node.queue_free()
			_nodes.remove_at(i)
		else:
			i += 1
	var j := 0
	while j < _line_fx.size():
		var lf: Dictionary = _line_fx[j]
		lf["age"] = float(lf["age"]) + delta
		if float(lf["age"]) >= float(lf["dur"]):
			_line_fx.remove_at(j)
		else:
			j += 1


## Ajoute les effets dessinés en traits aux lignes et points de l'arène.
func collect(lines: Array, points: Array) -> void:
	for lf in _line_fx:
		var age := float(lf["age"])
		if age < 0.0:
			continue
		var dur := float(lf["dur"])
		var k := clampf(age / dur, 0.0, 1.0)
		var col: Color = lf["color"]
		match str(lf["kind"]):
			"shock":
				var rr := float(lf["r"]) * (0.25 + 0.95 * (1.0 - pow(1.0 - k, 2.0)))
				_thick_ring(lines, lf["pos"], rr, Color(col, 1.0 - k), 0.08)
				_ring(lines, lf["pos"], rr * 0.62, Color(col.lerp(Color.WHITE, 0.4), (1.0 - k) * 0.7), 0.08)
			"zone":
				var fade := minf(1.0, age / 0.25) * clampf((dur - age) / 0.3, 0.0, 1.0)
				_dashed_ring(lines, lf["pos"], float(lf["r"]), Color(col, 0.8 * fade), t * 0.8, 0.07)
			"vortex":
				_vortex_lines(lines, points, lf, col)
			"wave":
				_wave_lines(lines, lf, col)
			"lightning":
				_lightning_lines(lines, lf, col, k)
			"wind":
				_wind_lines(lines, lf, age, dur)
			"mark":
				var mr := float(lf["r"]) * (1.2 - 0.4 * k)
				_ring(lines, lf["pos"], mr, Color(col, 0.35 + 0.5 * k), 0.06)
			"bolt":
				_bolt_lines(lines, lf["pos"], int(lf["seed"]), Color(col.lerp(Color.WHITE, 0.4), 1.0 - k))
			"storm":
				# Éclairs réguliers dans la zone de la Tempête.
				var slot := int(age * 3.0)
				if fmod(age * 3.0, 1.0) < 0.35 and age < dur - 0.3:
					_rng.seed = slot * 977 + int(float(lf["r"]) * 10.0)
					var off := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * float(lf["r"])
					_bolt_lines(lines, (lf["pos"] as Vector2) + off, slot, Color(col.lerp(Color.WHITE, 0.5), 0.9))
			"colband":
				var a := (1.0 - k) * 0.8
				var hx := float(lf["w"]) * 0.5
				for sx in [-hx, hx]:
					lines.append([w3(Vector2(float(lf["x"]) + sx, float(lf["y0"])), 0.08), w3(Vector2(float(lf["x"]) + sx, float(lf["y1"])), 0.08), Color(col, a)])
			"arrow":
				var a: Vector2 = lf["a"]
				var b: Vector2 = lf["b"]
				var p0 := w3(a.lerp(b, clampf(k * 1.1 - 0.15, 0.0, 1.0)), 0.55)
				var p1 := w3(a.lerp(b, clampf(k * 1.1, 0.0, 1.0)), 0.55)
				lines.append([p0, p1, Color(1, 1, 1, 1.0 - k * 0.5)])
				lines.append([p0 + Vector3(0, 0.04, 0), p1 + Vector3(0, 0.04, 0), Color(col, 1.0 - k * 0.5)])
			_:
				if str(lf["kind"]).begins_with("tir_"):
					ShotFx.draw(self, lf, lines, points, k)
				else:
					sig.draw(lf, lines, points, k)


## Éclair vertical, du ciel jusqu'au sol.
func _bolt_lines(lines: Array, pos: Vector2, seed_value: int, col: Color) -> void:
	_rng.seed = seed_value * 31 + int(t * 30.0)
	var prev := w3(pos, 7.0)
	var n := 12
	for i in range(1, n + 1):
		var f := float(i) / float(n)
		var q := pos + (Vector2(_rng.randf_range(-0.25, 0.25), _rng.randf_range(-0.1, 0.1)) if i < n else Vector2.ZERO)
		var p := w3(q, lerpf(7.0, 0.05, f))
		lines.append([prev, p, col])
		lines.append([prev + Vector3(0.03, 0, 0), p + Vector3(0.03, 0, 0), Color(1, 1, 1, col.a)])
		prev = p


func _wind_lines(lines: Array, lf: Dictionary, age: float, dur: float) -> void:
	var blow := bool(lf["blow"])
	var dir := float(lf["dir"])
	var fade := minf(1.0, age / 0.3) * clampf((dur - age) / 0.4, 0.0, 1.0)
	var col: Color = lf["color"]
	var n := 16 if blow else 10
	var speed := 11.0 if blow else 3.0
	var length := 1.3 if blow else 0.6
	var alpha := (0.55 if blow else 0.3) * fade
	for i in range(n):
		var y := 0.6 + float(i) * 14.8 / float(n - 1)
		var ph := fmod(float(lf["seed"]) * 7.3 + float(i) * 2.17, 1.0)
		var span := 13.0
		var x := fmod(ph * span + age * speed * (1.0 + 0.15 * float(i % 3)), span) - 2.0
		if dir < 0.0:
			x = 9.0 - x
		var h := 0.25 + 0.12 * float(i % 4)
		var wob := 0.06 * sin(t * 6.0 + float(i))
		lines.append([w3(Vector2(x, y + wob), h), w3(Vector2(x - dir * length, y + wob), h), Color(col, alpha)])


func _ring(lines: Array, center: Vector2, r: float, col: Color, h: float) -> void:
	var seg := 28
	for s in range(seg):
		var a0 := TAU * float(s) / float(seg)
		var a1 := TAU * float(s + 1) / float(seg)
		lines.append([w3(center + Vector2(cos(a0), sin(a0)) * r, h), w3(center + Vector2(cos(a1), sin(a1)) * r, h), col])


func _thick_ring(lines: Array, center: Vector2, r: float, col: Color, h: float) -> void:
	for dr in [-0.06, 0.0, 0.06]:
		_ring(lines, center, maxf(0.05, r + dr), col, h)


func _dashed_ring(lines: Array, center: Vector2, r: float, col: Color, rot: float, h: float) -> void:
	var seg := 32
	for s in range(0, seg, 2):
		var a0 := rot + TAU * float(s) / float(seg)
		var a1 := rot + TAU * float(s + 1) / float(seg)
		lines.append([w3(center + Vector2(cos(a0), sin(a0)) * r, h), w3(center + Vector2(cos(a1), sin(a1)) * r, h), col])


## Vortex : trois bras en spirale qui tournent et des particules aspirées vers le centre.
func _vortex_lines(lines: Array, points: Array, lf: Dictionary, col: Color) -> void:
	var pos: Vector2 = lf["pos"]
	var r := float(lf["r"])
	var age := float(lf["age"])
	var dur := float(lf["dur"])
	var fade := minf(1.0, age / 0.25) * clampf((dur - age) / 0.35, 0.0, 1.0)
	var rot := t * 5.0
	for arm in range(3):
		var prev := Vector3.ZERO
		for j in range(12):
			var f := float(j) / 11.0
			var ang := rot + float(arm) * TAU / 3.0 + f * 2.6
			var rad := r * (1.0 - f * 0.92)
			var p := w3(pos + Vector2(cos(ang), sin(ang)) * rad, 0.08 + f * 0.25)
			if j > 0:
				var cc := Color(col.lerp(Color.WHITE, f * 0.5), fade * (0.45 + 0.55 * f))
				lines.append([prev, p, cc])
				lines.append([prev + Vector3(0, 0.06, 0), p + Vector3(0, 0.06, 0), cc])
				lines.append([prev + Vector3(0.05, 0, 0.05), p + Vector3(0.05, 0, 0.05), Color(cc, cc.a * 0.7)])
			prev = p
	for j in range(28):
		var ph := fposmod(float(j) * 0.137 + age * 0.9, 1.0)
		var ang := float(j) * 2.39 + rot * 0.6 + ph * 4.0
		var rad := r * (1.0 - ph)
		points.append([w3(pos + Vector2(cos(ang), sin(ang)) * rad, 0.15 + ph * 0.5), Color(col.lerp(Color("d0b0ff"), ph), fade)])
	_ring(lines, pos, r, Color(col, 0.55 * fade), 0.06)


## Onde de choc : deux fronts qui s'élargissent, avec un mur de traits verticaux.
func _wave_lines(lines: Array, lf: Dictionary, col: Color) -> void:
	var pos: Vector2 = lf["pos"]
	var r := float(lf["r"])
	var age := float(lf["age"])
	var dur := float(lf["dur"])
	for off in [0.0, 0.14]:
		var kk := clampf((age - off) / (dur * 0.8), 0.0, 1.0)
		if kk <= 0.0 or kk >= 1.0:
			continue
		var rr := r * (0.15 + 1.05 * (1.0 - pow(1.0 - kk, 2.0)))
		var c := Color(col.lerp(Color.WHITE, 0.25), 1.0 - kk)
		_thick_ring(lines, pos, rr, c, 0.08)
		_ring(lines, pos, rr, Color(c, c.a * 0.6), 0.5 * (1.0 - kk) + 0.08)
		for s in range(24):
			var a := TAU * float(s) / 24.0
			var base := pos + Vector2(cos(a), sin(a)) * rr
			lines.append([w3(base, 0.08), w3(base, 0.5 * (1.0 - kk) + 0.08), Color(c, c.a * 0.7)])


## Éclair : ligne brisée qui scintille entre les cibles (cœur blanc, halo coloré).
func _lightning_lines(lines: Array, lf: Dictionary, col: Color, k: float) -> void:
	var pts: Array = lf["pts"]
	var slot := int(t * 24.0)
	var alpha := (1.0 - k) * (0.65 + 0.35 * sin(t * 70.0))
	for s in range(pts.size() - 1):
		var a: Vector2 = pts[s]
		var b: Vector2 = pts[s + 1]
		var ha := 1.1 if s == 0 else 0.5
		var n := maxi(3, int(a.distance_to(b) / 0.35))
		var perp := Vector2(-(b - a).y, (b - a).x).normalized()
		_rng.seed = slot * 131 + s * 17
		var prev := w3(a, ha)
		for i in range(1, n + 1):
			var f := float(i) / float(n)
			var q := a.lerp(b, f)
			var h := lerpf(ha, 0.5, f)
			if i < n:
				q += perp * _rng.randf_range(-0.22, 0.22)
				h += _rng.randf_range(-0.12, 0.12)
			var p := w3(q, h)
			var side := w3(perp * 0.06, 0.0)
			lines.append([prev, p, Color(1, 1, 1, alpha)])
			lines.append([prev + Vector3(0, 0.05, 0), p + Vector3(0, 0.05, 0), Color(1, 1, 1, alpha)])
			lines.append([prev - Vector3(0, 0.05, 0), p - Vector3(0, 0.05, 0), Color(col, alpha)])
			lines.append([prev + side, p + side, Color(col, alpha)])
			lines.append([prev - side + Vector3(0, 0.1, 0), p - side + Vector3(0, 0.1, 0), Color(col, alpha * 0.7)])
			prev = p
