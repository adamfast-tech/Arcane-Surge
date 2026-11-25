class_name SpellSig
extends RefCounted
## Signatures visuelles propres à chaque sort (étape « animations uniques »).
## La simulation marque chaque évènement d'un sort avec son identifiant (« sid ») ; SpellFx confie ces
## évènements à play(), qui appelle la méthode s_<sort>(phase, e) si elle existe. Une méthode renvoie vrai
## quand elle remplace l'animation générique de cette phase, faux pour la garder (ou la compléter).
## Phases : spell (lancement), fireball/meteor (projectile), explosion, rain/roots/vortex/blaze/storm (zones),
## column, beam, arrow, lightning, wave, bolt, pillar, shield, ring, puff, summon, ground, quake.

var fx: SpellFx
var _rng := RandomNumberGenerator.new()
var _links: Array[Dictionary] = [] ## Constellation : points d'impact récents reliés par des traits
var recipe: SpellRecipe ## animations des grimoires de classe, décrites dans spells.json (« vfx »)


func _init(owner: SpellFx) -> void:
	fx = owner
	_rng.seed = 9137
	recipe = SpellRecipe.new(self)


func play(e: Dictionary) -> bool:
	var sid := str(e.get("sid", ""))
	var m := "s_" + sid
	if not has_method(m):
		var sp: Dictionary = GameData.spells().get(sid, {})
		if sp.has("vfx"):
			return recipe.play(str(e["t"]), e, sp["vfx"])
		return false
	return bool(call(m, str(e["t"]), e))


# ================================================================ outils

static func w3(p: Vector2, h: float = 0.0) -> Vector3:
	return Vector3(p.x, h, -p.y)


func _c(e: Dictionary) -> Color:
	return Color(str(e.get("color", "FFFFFF")))


func line(kind: String, d: Dictionary) -> void:
	d["kind"] = kind
	if not d.has("age"):
		d["age"] = 0.0
	fx._line_fx.append(d)


func sprite3(tex: Texture2D, scale: float, transparent: bool = false) -> Sprite3D:
	var spr := Sprite3D.new()
	spr.texture = tex
	spr.pixel_size = SpellFx.TEXEL * scale
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.shaded = false
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED if transparent else SpriteBase3D.ALPHA_CUT_DISCARD
	return spr


## Sprite qui se déplace de « from » à « to » (arc, rotation par images, ondulation, traînée, fondu).
func mover(tex: Texture2D, from: Vector3, to: Vector3, fly: float, o: Dictionary = {}) -> Sprite3D:
	var spr := sprite3(tex, float(o.get("scale", 1.6)), bool(o.get("fade", false)))
	spr.position = from
	spr.visible = false
	if o.has("tint"):
		spr.modulate = o["tint"]
	fx.add_child(spr)
	var trail: CPUParticles3D = null
	if o.has("trail"):
		trail = CPUParticles3D.new()
		trail.amount = int(o.get("trail_n", 24))
		trail.lifetime = float(o.get("trail_life", 0.35))
		trail.local_coords = false
		trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		trail.emission_sphere_radius = float(o.get("trail_r", 0.06))
		trail.direction = Vector3.UP
		trail.spread = 180.0
		trail.initial_velocity_min = 0.05
		trail.initial_velocity_max = float(o.get("trail_v", 0.4))
		trail.gravity = Vector3(0, float(o.get("trail_g", 0.5)), 0)
		trail.mesh = fx._pm(float(o.get("trail_size", 0.09)))
		trail.color_ramp = fx._ramp(o["trail"])
		trail.emitting = false
		spr.add_child(trail)
	var linger := float(o.get("linger", 0.0))
	fx._nodes.append({"kind": "mover", "node": spr, "trail": trail, "age": -float(o.get("delay", 0.0)), "fly": fly,
		"dur": fly + linger + (trail.lifetime + 0.05 if trail != null else 0.0), "linger": linger, "from": from, "to": to,
		"arc": float(o.get("arc", 0.0)), "frames": o.get("frames", []), "spin": float(o.get("spin", 0.08)),
		"wiggle": float(o.get("wiggle", 0.0)), "sway": float(o.get("sway", 0.0)), "fade": bool(o.get("fade", false)),
		"grow": float(o.get("grow", 1.0))})
	return spr


## Sprite qui sort du sol (cristal, tombe, main, ronce), base au sol, puis rentre.
func riser(tex: Texture2D, pos: Vector2, scale: float, dur: float, delay: float = 0.0, grow: float = 0.22) -> void:
	var spr := sprite3(tex, scale)
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.offset = Vector2(0, tex.get_height() * 0.5)
	spr.flip_h = _rng.randf() < 0.5
	spr.position = w3(pos, 0.0)
	spr.scale = Vector3(1.0, 0.01, 1.0)
	fx.add_child(spr)
	fx._nodes.append({"kind": "root", "node": spr, "age": -delay, "dur": dur, "grow": grow})


## Sprites qui tournent autour d'un point (haches, éclats de miroir).
func orbit(tex_frames: Array, center: Vector3, r: float, n: int, speed: float, dur: float, scale: float) -> void:
	for i in range(n):
		var spr := sprite3(tex_frames[0], scale)
		spr.position = center
		fx.add_child(spr)
		fx._nodes.append({"kind": "orbit", "node": spr, "age": 0.0, "dur": dur, "center": center, "r": r,
			"phase": TAU * float(i) / float(n), "speed": speed, "frames": tex_frames})


## Sphère pleine (soleil noir, trou noir, astre) : grossit, palpite, se résorbe ; peut se déplacer.
func sphere(from: Vector3, to: Vector3, r: float, col: Color, dur: float, add: bool = false) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 20
	sm.rings = 10
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if add:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = col
	mi.material_override = m
	mi.position = from
	mi.scale = Vector3.ONE * 0.05
	fx.add_child(mi)
	fx._nodes.append({"kind": "sphere", "node": mi, "mat": m, "age": 0.0, "dur": dur, "from": from, "to": to, "col": col})


## Émetteur de particules générique (continu pendant « stop » s, ou d'un coup si stop <= 0).
func emit(p: Vector3, ext: Vector3, amount: int, life: float, dir: Vector3, spread: float, v: Vector2, grav: float,
		size: float, cols: Array, stop: float = 0.0, damp: float = 0.0) -> CPUParticles3D:
	var b := CPUParticles3D.new()
	b.amount = clampi(amount, 1, 400)
	b.lifetime = life
	b.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	b.emission_box_extents = ext
	b.direction = dir
	b.spread = spread
	b.initial_velocity_min = v.x
	b.initial_velocity_max = v.y
	b.gravity = Vector3(0, grav, 0)
	b.damping_min = damp
	b.damping_max = damp * 1.5
	b.scale_amount_min = 0.7
	b.scale_amount_max = 1.4
	b.mesh = fx._pm(size)
	b.color_ramp = fx._ramp(cols)
	b.position = p
	fx.add_child(b)
	if stop <= 0.0:
		b.one_shot = true
		b.explosiveness = 0.9
		b.emitting = true
		fx._nodes.append({"kind": "free", "node": b, "age": 0.0, "dur": life + 0.2})
	else:
		fx._nodes.append({"kind": "emitter", "node": b, "age": 0.0, "stop": stop, "dur": stop + life + 0.05})
	return b


func spin_frames(name: String, col: Color) -> Array:
	return [FxArt.sprite(name, col, 0), FxArt.sprite(name, col, 1), FxArt.sprite(name, col, 2), FxArt.sprite(name, col, 3)]


func _flash(p: Vector3, size: float, col: Color, dur: float) -> void:
	fx._flash(p, size, col, dur)


func _light(p: Vector3, col: Color, reach: float, energy: float, dur: float) -> void:
	fx._light(p, col, reach, energy, dur)


func _burst(p: Vector3, n: int, cols: Array, speed: float, size: float, life: float, grav: float, spread: float) -> void:
	fx._burst(p, n, cols, speed, size, life, grav, spread)


func _rand_in(r: float) -> Vector2:
	return Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * r


## Marque de zone persistante (cercle en pointillés), comme les zones génériques.
func zone_ring(pos: Vector2, r: float, col: Color, dur: float) -> void:
	line("zone", {"pos": pos, "r": r, "dur": dur, "color": col})



## Trait épaissi (trois traits décalés) : lisible même sur un écran de téléphone.
func seg(lines: Array, a: Vector3, b: Vector3, col: Color) -> void:
	lines.append([a, b, col])
	lines.append([a + Vector3(0, 0.035, 0), b + Vector3(0, 0.035, 0), col])
	lines.append([a + Vector3(0.03, 0, 0.03), b + Vector3(0.03, 0, 0.03), Color(col, col.a * 0.8)])


func ring3(lines: Array, c: Vector2, r: float, col: Color, h: float) -> void:
	var n := 32
	for i in range(n):
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		seg(lines, w3(c + Vector2(cos(a0), sin(a0)) * r, h), w3(c + Vector2(cos(a1), sin(a1)) * r, h), col)


# ================================================================ animation des nœuds (appelé par SpellFx)

func animate(f: Dictionary, age: float, k: float, node: Node3D) -> void:
	match str(f["kind"]):
		"mover":
			if age < 0.0:
				node.visible = false
				return
			node.visible = true
			var fly := float(f["fly"])
			var kf := clampf(age / maxf(0.001, fly), 0.0, 1.0)
			var p: Vector3 = (f["from"] as Vector3).lerp(f["to"], kf)
			p.y += sin(kf * PI) * float(f["arc"])
			var wig := float(f["wiggle"])
			if wig > 0.0:
				p.x += sin(age * 38.0) * wig
				p.y += cos(age * 29.0) * wig * 0.6
			var sw := float(f["sway"])
			if sw > 0.0:
				p.x += sin(age * 3.2 + float(f["from"].x)) * sw
			node.position = p
			var frames: Array = f["frames"]
			if not frames.is_empty():
				(node as Sprite3D).texture = frames[int(age / float(f["spin"])) % frames.size()]
			var g := float(f["grow"])
			if g != 1.0:
				node.scale = Vector3.ONE * lerpf(1.0, g, kf)
			var tr: CPUParticles3D = f["trail"]
			if tr != null:
				tr.emitting = kf < 1.0
			if kf >= 1.0:
				var lg := float(f["linger"])
				var a := 1.0 - clampf((age - fly) / maxf(0.01, lg), 0.0, 1.0) if lg > 0.0 else 0.0
				(node as Sprite3D).modulate.a = a
			elif bool(f["fade"]):
				(node as Sprite3D).modulate.a = minf(1.0, kf * 5.0) * (1.0 - kf * 0.3)
		"orbit":
			var ang := float(f["phase"]) + age * float(f["speed"])
			var rr := float(f["r"]) * minf(1.0, age / 0.25)
			node.position = (f["center"] as Vector3) + Vector3(cos(ang) * rr, 0.15 * sin(age * 6.0 + float(f["phase"])), sin(ang) * rr)
			var fr: Array = f["frames"]
			(node as Sprite3D).texture = fr[int(age / 0.06) % fr.size()]
			(node as Sprite3D).modulate.a = clampf((float(f["dur"]) - age) / 0.25, 0.0, 1.0)
		"sphere":
			var s := sin(minf(1.0, k * 3.0) * PI * 0.5) * (1.0 - smoothstep(0.82, 1.0, k))
			node.scale = Vector3.ONE * maxf(0.02, s * (1.0 + 0.06 * sin(age * 9.0)))
			node.position = (f["from"] as Vector3).lerp(f["to"], k)
			(f["mat"] as StandardMaterial3D).albedo_color = Color(f["col"], float((f["col"] as Color).a) * (1.0 - smoothstep(0.85, 1.0, k)))


# ================================================================ traits (appelé par SpellFx.collect)

func draw(lf: Dictionary, lines: Array, points: Array, k: float) -> void:
	var col: Color = lf["color"]
	var age := float(lf["age"])
	var dur := float(lf["dur"])
	var fade := minf(1.0, age / 0.2) * clampf((dur - age) / 0.3, 0.0, 1.0)
	var t := fx.t
	match str(lf["kind"]):
		"glyph":
			_glyph(lines, lf, col, k, fade, t)
		"rays":
			var pos: Vector2 = lf["pos"]
			var n := int(lf.get("n", 8))
			var len := float(lf["r"]) * (0.3 + 0.9 * (1.0 - pow(1.0 - k, 2.0)))
			var h := float(lf.get("h", 0.4))
			for i in range(n):
				var a := TAU * float(i) / float(n) + float(lf.get("rot", 0.0))
				var d := Vector2(cos(a), sin(a))
				var l2 := len * (1.0 if i % 2 == 0 else 0.6)
				seg(lines, w3(pos + d * l2 * 0.25, h), w3(pos + d * l2, h), Color(col.lerp(Color.WHITE, 0.3), 1.0 - k))
				seg(lines, w3(pos + d * l2 * 0.25, h + 0.04), w3(pos + d * l2, h + 0.04), Color(col, (1.0 - k) * 0.7))
		"arc":
			# Faux : un arc qui balaie le cercle, laissant une traînée.
			var pos: Vector2 = lf["pos"]
			var r := float(lf["r"])
			var head := float(lf.get("a0", 0.0)) + TAU * 1.1 * (1.0 - pow(1.0 - k, 2.0))
			for j in range(18):
				var f := float(j) / 17.0
				var a0 := head - f * 1.6
				var a1 := head - (f + 1.0 / 17.0) * 1.6
				var cc := Color(col.lerp(Color.WHITE, 0.6 * (1.0 - f)), (1.0 - f) * (1.0 - k * 0.7))
				for dr in [-0.08, 0.0, 0.08]:
					seg(lines, w3(Vector2(cos(a0), sin(a0)) * (r + dr) + pos, 0.5), w3(Vector2(cos(a1), sin(a1)) * (r + dr) + pos, 0.5), cc)
		"wisps":
			# Âmes : volutes qui montent en spirale, puis filent vers le lanceur.
			var srcs: Array = lf["pts"]
			var to: Vector2 = lf.get("to", Vector2(-1.0, -1.0))
			for i in range(srcs.size()):
				var p0: Vector2 = srcs[i]
				var kk := clampf(k * 1.3 - float(i % 5) * 0.06, 0.0, 1.0)
				var rise := kk * 2.4
				var sp := p0 + Vector2(sin(kk * 9.0 + float(i)) * 0.25, 0.0)
				if to.x >= 0.0 and kk > 0.55:
					sp = sp.lerp(to, (kk - 0.55) / 0.45)
				var base := w3(sp, 0.3 + rise)
				var cc := Color(col.lerp(Color.WHITE, 0.4), (1.0 - kk) * fade + 0.15 * fade)
				points.append([base, cc])
				points.append([base + Vector3(0.05, -0.08, 0), Color(col, cc.a * 0.7)])
				seg(lines, base, base + Vector3(sin(t * 8.0 + float(i)) * 0.08, -0.35, 0), Color(col, cc.a * 0.5))
		"cracks":
			var pos: Vector2 = lf["pos"]
			var r := float(lf["r"]) * minf(1.0, age / 0.25)
			var n := int(lf.get("n", 7))
			var seed_v := int(lf.get("seed", 3))
			for i in range(n):
				_rng.seed = seed_v * 97 + i * 13
				var a := TAU * float(i) / float(n) + _rng.randf_range(-0.3, 0.3)
				var prev := pos
				var steps := 5
				for s in range(1, steps + 1):
					var q := pos + Vector2(cos(a), sin(a)) * r * float(s) / float(steps) + Vector2(_rng.randf_range(-0.15, 0.15), _rng.randf_range(-0.15, 0.15))
					seg(lines, w3(prev, 0.06), w3(q, 0.06), Color(col, fade))
					seg(lines, w3(prev, 0.07), w3(q, 0.07), Color(col.lerp(Color.WHITE, 0.5), fade * 0.5))
					prev = q
		"tide":
			# Marée d'ombre : un mur liquide, crêtes irrégulières, qui s'élargit puis retombe.
			var pos: Vector2 = lf["pos"]
			var r := float(lf["r"]) * (0.2 + 1.0 * (1.0 - pow(1.0 - k, 2.0)))
			var hmax := 2.0 * sin(k * PI)
			var seg := 36
			for s in range(seg):
				var a := TAU * float(s) / float(seg)
				var b := pos + Vector2(cos(a), sin(a)) * r
				var crest := hmax * (0.6 + 0.4 * sin(float(s) * 1.7 + t * 6.0))
				seg(lines, w3(b, 0.05), w3(b, crest), Color(col.lightened(0.15), 0.95 * (1.0 - k)))
				var a2 := TAU * float(s + 1) / float(seg)
				var b2 := pos + Vector2(cos(a2), sin(a2)) * r
				var crest2 := hmax * (0.6 + 0.4 * sin(float(s + 1) * 1.7 + t * 6.0))
				seg(lines, w3(b, crest), w3(b2, crest2), Color(col.lerp(Color.WHITE, 0.35), 1.0 - k))
		"tentacles":
			var pos: Vector2 = lf["pos"]
			var n := int(lf.get("n", 6))
			for i in range(n):
				var a := TAU * float(i) / float(n) + 0.4
				var base := pos + Vector2(cos(a), sin(a)) * float(lf["r"]) * 0.6
				var prev := w3(base, 0.0)
				var hh := 1.6 * sin(minf(1.0, k * 1.6) * PI * 0.5) * (1.0 - smoothstep(0.7, 1.0, k))
				for j in range(1, 9):
					var f := float(j) / 8.0
					var q := base + Vector2(sin(t * 4.0 + f * 5.0 + float(i)) * 0.25 * f, 0.0)
					var p := w3(q, hh * f)
					seg(lines, prev, p, Color(col, fade * (1.0 - f * 0.5)))
					seg(lines, prev + Vector3(0.04, 0, 0), p + Vector3(0.04, 0, 0), Color(col.darkened(0.3), fade * (1.0 - f * 0.5)))
					prev = p
		"vring":
			# Anneau vertical face caméra (couronne d'éclipse, halo, astre) à une hauteur donnée.
			var c: Vector2 = lf["pos"]
			var h := float(lf.get("h", 3.0))
			var r := float(lf["r"]) * (float(lf.get("r0", 1.0)) + (1.0 - float(lf.get("r0", 1.0))) * minf(1.0, k * 3.0))
			var seg := 32
			var jitter := float(lf.get("jitter", 0.0))
			for s in range(seg):
				var a0 := TAU * float(s) / float(seg)
				var a1 := TAU * float(s + 1) / float(seg)
				var j0 := 1.0 + jitter * sin(a0 * 7.0 + t * 9.0)
				var j1 := 1.0 + jitter * sin(a1 * 7.0 + t * 9.0)
				var p0 := Vector3(c.x + cos(a0) * r * j0, h + sin(a0) * r * j0, -c.y)
				var p1 := Vector3(c.x + cos(a1) * r * j1, h + sin(a1) * r * j1, -c.y)
				seg(lines, p0, p1, Color(col, fade))
				if jitter > 0.0 and s % 2 == 0:
					seg(lines, p0, Vector3(c.x + cos(a0) * r * (1.25 + jitter), h + sin(a0) * r * (1.25 + jitter), -c.y), Color(col, fade * 0.6))
		"accretion":
			# Disque d'accrétion incliné qui tourne autour du trou noir.
			var c: Vector2 = lf["pos"]
			var h := float(lf.get("h", 1.0))
			for ring: float in [1.0, 0.78, 0.6]:
				var r := float(lf["r"]) * ring
				var seg := 30
				for s in range(seg):
					var a0 := TAU * float(s) / float(seg) + t * 2.5 / ring
					var a1 := TAU * float(s + 1) / float(seg) + t * 2.5 / ring
					var p0 := Vector3(c.x + cos(a0) * r, h + sin(a0) * r * 0.22, -c.y + sin(a0) * r * 0.55)
					var p1 := Vector3(c.x + cos(a1) * r, h + sin(a1) * r * 0.22, -c.y + sin(a1) * r * 0.55)
					seg(lines, p0, p1, Color(col.lerp(Color.WHITE, 0.5 * (1.0 - ring)), fade * (0.4 + 0.6 * float(s % 3 != 0))))
			for j in range(24):
				# Matière aspirée.
				var ph := fposmod(float(j) * 0.173 + age * 0.7, 1.0)
				var a := float(j) * 2.11 + t
				var rr := float(lf["r"]) * 2.2 * (1.0 - ph)
				points.append([Vector3(c.x + cos(a) * rr, h * ph + 0.1, -c.y + sin(a) * rr), Color(col.lerp(Color.WHITE, ph), fade)])
		"fireflies":
			var a: Vector2 = lf["a"]
			var b: Vector2 = lf["b"]
			var n := int(lf.get("n", 18))
			for i in range(n):
				var ph := clampf(k * 1.4 - float(i) * 0.02, 0.0, 1.0)
				var p := a.lerp(b + Vector2(-3.6 + 7.2 * float(i) / float(n - 1), 0.0), ph)
				p += Vector2(sin(t * 5.0 + float(i) * 1.3), cos(t * 4.0 + float(i))) * 0.35
				var blink := 0.5 + 0.5 * sin(t * 12.0 + float(i) * 2.0)
				points.append([w3(p, 0.6 + 0.4 * sin(t * 3.0 + float(i))), Color(col.lerp(Color.WHITE, blink * 0.5), fade * (0.4 + 0.6 * blink))])
		"thickbeam":
			var a: Vector2 = lf["a"]
			var b: Vector2 = lf["b"]
			var h := float(lf.get("h", 0.6))
			var wd := float(lf.get("w", 0.3)) * (1.0 - k * 0.6)
			var flick := 0.75 + 0.25 * sin(t * 50.0)
			for o in range(-3, 4):
				var off := float(o) / 3.0 * wd
				var cc := Color(col.lerp(Color.WHITE, 1.0 - absf(off) / maxf(0.01, wd)), fade * flick * (1.0 - absf(off) / maxf(0.01, wd) * 0.6))
				seg(lines, Vector3(a.x + off, h, -a.y), Vector3(b.x + off, h, -b.y), cc)
				seg(lines, Vector3(a.x, h + off * 0.6, -a.y), Vector3(b.x, h + off * 0.6, -b.y), Color(cc, cc.a * 0.6))
			var rings := int(lf.get("rings", 0))
			for i in range(rings):
				var f := fposmod(float(i) / float(rings) + age * 1.5, 1.0)
				var c := a.lerp(b, f)
				var rr := wd * 2.2
				for s in range(12):
					var a0 := TAU * float(s) / 12.0
					var a1 := TAU * float(s + 1) / 12.0
					seg(lines, Vector3(c.x + cos(a0) * rr, h + sin(a0) * rr, -c.y), Vector3(c.x + cos(a1) * rr, h + sin(a1) * rr, -c.y), Color(col, fade * 0.8))
		"slash":
			var a: Vector2 = lf["a"]
			var b: Vector2 = lf["b"]
			var h := float(lf.get("h", 0.5))
			var head := clampf(k * 3.0, 0.0, 1.0)
			var tail := clampf(k * 3.0 - 0.6, 0.0, 1.0)
			var pa := a.lerp(b, tail)
			var pb := a.lerp(b, head)
			for o in [-0.03, 0.0, 0.03]:
				seg(lines, w3(pa + Vector2(o, 0), h), w3(pb + Vector2(o, 0), h), Color(Color.WHITE, 1.0 - k))
			seg(lines, w3(pa + Vector2(0.08, 0), h - 0.05), w3(pb + Vector2(0.08, 0), h - 0.05), Color(col, (1.0 - k) * 0.7))
			seg(lines, w3(pa - Vector2(0.08, 0), h + 0.05), w3(pb - Vector2(0.08, 0), h + 0.05), Color(col, (1.0 - k) * 0.7))
		"crescent":
			# Entaille en croissant (Tranche-orage, Hache).
			var c: Vector2 = lf["pos"]
			var r := float(lf["r"])
			var rot := float(lf.get("rot", 0.0))
			for j in range(12):
				var f0 := float(j) / 12.0
				var f1 := float(j + 1) / 12.0
				var a0 := rot - 1.2 + 2.4 * f0
				var a1 := rot - 1.2 + 2.4 * f1
				var th := 0.12 * sin(f0 * PI)
				seg(lines, Vector3(c.x + cos(a0) * r, 0.6 + sin(a0) * r * 0.5, -c.y), Vector3(c.x + cos(a1) * r, 0.6 + sin(a1) * r * 0.5, -c.y), Color(Color.WHITE, 1.0 - k))
				seg(lines, Vector3(c.x + cos(a0) * (r - th), 0.6 + sin(a0) * (r - th) * 0.5, -c.y), Vector3(c.x + cos(a1) * (r - th), 0.6 + sin(a1) * (r - th) * 0.5, -c.y), Color(col, 1.0 - k))
		"sound":
			# Ondes sonores : arcs qui partent du lanceur vers l'avant.
			var c: Vector2 = lf["pos"]
			for i in range(4):
				var kk := clampf(k * 1.4 - float(i) * 0.12, 0.0, 1.0)
				if kk <= 0.0 or kk >= 1.0:
					continue
				var r := 0.6 + kk * float(lf["r"])
				for j in range(10):
					var a0 := PI * 0.5 - 0.9 + 1.8 * float(j) / 10.0
					var a1 := PI * 0.5 - 0.9 + 1.8 * float(j + 1) / 10.0
					seg(lines, w3(c + Vector2(cos(a0), sin(a0)) * r, 0.6), w3(c + Vector2(cos(a1), sin(a1)) * r, 0.6), Color(col, 1.0 - kk))
					seg(lines, w3(c + Vector2(cos(a0), sin(a0)) * r, 0.9), w3(c + Vector2(cos(a1), sin(a1)) * r, 0.9), Color(col, (1.0 - kk) * 0.5))
		"links":
			var pts: Array = lf["pts"]
			for i in range(1, pts.size()):
				var a: Vector2 = pts[i - 1]
				var b: Vector2 = pts[i]
				seg(lines, w3(a, 0.35), w3(b, 0.35), Color(col, fade * 0.8))
				points.append([w3(b, 0.4), Color(Color.WHITE, fade)])
		"swirl":
			# Blizzard : rafales circulaires de neige.
			var c: Vector2 = lf["pos"]
			var r := float(lf["r"])
			for arm in range(5):
				var rot := t * (2.2 + 0.3 * float(arm)) + float(arm) * 1.26
				var rr := r * (0.35 + 0.13 * float(arm))
				for j in range(6):
					var a0 := rot + float(j) * 0.18
					var a1 := rot + float(j + 1) * 0.18
					seg(lines, w3(c + Vector2(cos(a0), sin(a0)) * rr, 0.3 + 0.1 * float(arm)), w3(c + Vector2(cos(a1), sin(a1)) * rr, 0.3 + 0.1 * float(arm)), Color(col, fade * float(j) / 6.0))
		"hexwall":
			# Bouclier arcanique : alvéoles hexagonales au-dessus de la Barrière.
			var y := float(lf.get("y", BattleSim.BARRIER_Y))
			var hh := 1.6 * minf(1.0, k * 4.0)
			var size := 0.42
			var row := 0
			var z := 0.25
			while z < hh:
				var off := 0.0 if row % 2 == 0 else size * 0.87
				var x := 0.2 + off
				while x < 8.8:
					var cc := Color(col, fade * (0.6 + 0.35 * sin(t * 4.0 + x + z * 2.0)))
					for s in range(6):
						var a0 := TAU * float(s) / 6.0
						var a1 := TAU * float(s + 1) / 6.0
						seg(lines, Vector3(x + cos(a0) * size * 0.5, z + sin(a0) * size * 0.5, -y), Vector3(x + cos(a1) * size * 0.5, z + sin(a1) * size * 0.5, -y), cc)
					x += size * 1.74
				z += size * 0.75
				row += 1
		"crackle":
			# Arcs électriques autour d'un point qui avance (javelot) ou au sol (champ statique).
			var a: Vector2 = lf["a"]
			var b: Vector2 = lf.get("b", a)
			var p := a.lerp(b, clampf(k * float(lf.get("speed", 1.0)), 0.0, 1.0))
			var r := float(lf.get("r", 0.5))
			_rng.seed = int(t * 20.0) * 31 + int(a.x * 10.0)
			for i in range(int(lf.get("n", 4))):
				var q0 := p + _rand_in(r)
				var prev := w3(q0, float(lf.get("h", 0.5)) + _rng.randf_range(-0.2, 0.2))
				for j in range(3):
					var q := q0 + _rand_in(r * 0.6)
					var nx := w3(q, float(lf.get("h", 0.5)) + _rng.randf_range(-0.3, 0.3))
					seg(lines, prev, nx, Color(col.lerp(Color.WHITE, 0.4), fade))
					prev = nx
		"vines":
			# Sève vitale : lianes qui poussent le long de la Barrière.
			var n := 10
			for i in range(n):
				var x := 0.5 + 8.0 * float(i) / float(n - 1)
				var hh := 1.4 * minf(1.0, k * 2.5) * (0.7 + 0.3 * sin(float(i) * 1.9))
				var prev := Vector3(x, 0.05, -BattleSim.BARRIER_Y)
				for j in range(1, 7):
					var f := float(j) / 6.0
					var p := Vector3(x + sin(f * 6.0 + float(i) + t * 2.0) * 0.18, hh * f, -BattleSim.BARRIER_Y)
					seg(lines, prev, p, Color(col, fade))
					prev = p
				points.append([prev, Color(Color("f2e28b"), fade)])
		"crackseg":
			var a: Vector2 = lf["a"]
			var b: Vector2 = lf["b"]
			var q := a.lerp(b, minf(1.0, age / 0.08))
			seg(lines, w3(a, 0.05), w3(q, 0.05), Color(col, fade))
			seg(lines, w3(a + Vector2(0.05, 0.0), 0.07), w3(q + Vector2(0.05, 0.0), 0.07), Color(Color("ffe0a0"), fade * 0.7))
			seg(lines, w3(a - Vector2(0.05, 0.0), 0.04), w3(q - Vector2(0.05, 0.0), 0.04), Color(col.darkened(0.4), fade))
		"net", "moon":
			recipe.draw(lf, lines, points, k, fade)
		"bubbles":
			var c: Vector2 = lf["pos"]
			var r := float(lf["r"])
			for i in range(int(lf.get("n", 16))):
				var ph := fposmod(float(i) * 0.31 + age * 0.8, 1.0)
				_rng.seed = i * 7 + int(age * 0.8 + float(i) * 0.31) * 131
				var q := c + _rand_in(r)
				var h := ph * 0.6
				var s := 0.04 + ph * 0.06
				var cc := Color(col.lerp(Color.WHITE, 0.3), fade * (1.0 - ph))
				for j in range(6):
					var a0 := TAU * float(j) / 6.0
					var a1 := TAU * float(j + 1) / 6.0
					seg(lines, Vector3(q.x + cos(a0) * s, h + 0.05 + sin(a0) * s, -q.y), Vector3(q.x + cos(a1) * s, h + 0.05 + sin(a1) * s, -q.y), cc)


## Glyphes au sol : cercle de runes, pentacle, hexagramme, flocon, horloge, croix, soleil.
func _glyph(lines: Array, lf: Dictionary, col: Color, k: float, fade: float, t: float) -> void:
	var c: Vector2 = lf["pos"]
	var grow := minf(1.0, float(lf["age"]) / float(lf.get("grow", 0.3)))
	var r := float(lf["r"]) * (0.3 + 0.7 * (1.0 - pow(1.0 - grow, 2.0)))
	var rot := float(lf.get("rot", 0.0)) + t * float(lf.get("spin", 0.0))
	var h := float(lf.get("h", 0.06))
	var cc := Color(col, fade * float(lf.get("alpha", 1.0)))
	var shape := str(lf.get("shape", "runes"))
	var poly := func(n: int, rr: float, ro: float, step: int) -> void:
		for i in range(n):
			var a0 := ro + TAU * float(i) / float(n)
			var a1 := ro + TAU * float((i + step) % n) / float(n)
			seg(lines, w3(c + Vector2(cos(a0), sin(a0)) * rr, h), w3(c + Vector2(cos(a1), sin(a1)) * rr, h), cc)
	match shape:
		"runes":
			ring3(lines, c, r, cc, h)
			ring3(lines, c, r * 0.78, cc, h)
			for i in range(12):
				var a := rot + TAU * float(i) / 12.0
				var p := c + Vector2(cos(a), sin(a)) * r * 0.89
				var tng := Vector2(-sin(a), cos(a)) * 0.08
				var nrm := Vector2(cos(a), sin(a)) * 0.07
				match i % 3:
					0:
						seg(lines, w3(p - tng - nrm, h), w3(p + tng + nrm, h), cc)
						seg(lines, w3(p + tng - nrm, h), w3(p - tng + nrm, h), cc)
					1:
						seg(lines, w3(p - nrm, h), w3(p + nrm, h), cc)
						seg(lines, w3(p - tng, h), w3(p + nrm, h), cc)
					_:
						seg(lines, w3(p - tng - nrm, h), w3(p + nrm, h), cc)
						seg(lines, w3(p + nrm, h), w3(p + tng - nrm, h), cc)
			poly.call(3, r * 0.72, -rot * 0.7, 1)
			poly.call(3, r * 0.72, -rot * 0.7 + PI, 1)
		"penta":
			ring3(lines, c, r, cc, h)
			poly.call(5, r * 0.96, rot - PI * 0.5, 2)
		"hexa":
			ring3(lines, c, r, cc, h)
			poly.call(3, r * 0.95, rot, 1)
			poly.call(3, r * 0.95, rot + PI, 1)
			ring3(lines, c, r * 0.45, cc, h)
		"snow":
			for i in range(6):
				var a := rot + TAU * float(i) / 6.0
				var d := Vector2(cos(a), sin(a))
				seg(lines, w3(c, h), w3(c + d * r, h), cc)
				for f: float in [0.45, 0.72]:
					var p := c + d * r * f
					var b1 := Vector2(cos(a + 0.7), sin(a + 0.7)) * r * 0.22
					var b2 := Vector2(cos(a - 0.7), sin(a - 0.7)) * r * 0.22
					seg(lines, w3(p, h), w3(p + b1, h), cc)
					seg(lines, w3(p, h), w3(p + b2, h), cc)
		"clock":
			ring3(lines, c, r, cc, h)
			ring3(lines, c, r * 0.66, Color(cc, cc.a * 0.7), h)
			for i in range(12):
				var a := TAU * float(i) / 12.0
				var d := Vector2(cos(a), sin(a))
				seg(lines, w3(c + d * r * 0.85, h), w3(c + d * r, h), cc)
			var ha := t * 0.6
			var ma := -t * 2.4
			seg(lines, w3(c, h), w3(c + Vector2(cos(ha), sin(ha)) * r * 0.5, h), cc)
			seg(lines, w3(c, h), w3(c + Vector2(cos(ma), sin(ma)) * r * 0.82, h), Color(Color.WHITE, cc.a))
		"cross":
			ring3(lines, c, r, cc, h)
			for o in [-0.06, 0.0, 0.06]:
				seg(lines, w3(c + Vector2(o, -r * 0.9), h), w3(c + Vector2(o, r * 0.9), h), cc)
				seg(lines, w3(c + Vector2(-r * 0.55, r * 0.2 + o), h), w3(c + Vector2(r * 0.55, r * 0.2 + o), h), cc)
		"sun":
			ring3(lines, c, r * 0.45, cc, h)
			for i in range(16):
				var a := rot + TAU * float(i) / 16.0
				var d := Vector2(cos(a), sin(a))
				seg(lines, w3(c + d * r * 0.55, h), w3(c + d * r * (1.0 if i % 2 == 0 else 0.78), h), cc)
		"tri":
			ring3(lines, c, r, cc, h)
			poly.call(3, r, rot, 1)
			poly.call(3, r * 0.5, -rot, 1)
		"target":
			# Mire de chasseur : deux cercles, quatre traits, qui se resserrent.
			var rr := r * (1.3 - 0.3 * minf(1.0, k * 2.0))
			ring3(lines, c, rr, cc, h)
			ring3(lines, c, rr * 0.4, cc, h)
			for i in range(4):
				var a := rot + TAU * float(i) / 4.0
				var d := Vector2(cos(a), sin(a))
				seg(lines, w3(c + d * rr * 0.55, h), w3(c + d * rr * 1.15, h), cc)
		"eye":
			for i in range(16):
				var f0 := -1.0 + 2.0 * float(i) / 16.0
				var f1 := -1.0 + 2.0 * float(i + 1) / 16.0
				for sgn: float in [1.0, -1.0]:
					seg(lines, w3(c + Vector2(f0 * r, sgn * r * 0.45 * (1.0 - f0 * f0)), h), w3(c + Vector2(f1 * r, sgn * r * 0.45 * (1.0 - f1 * f1)), h), cc)
			ring3(lines, c, r * 0.26, cc, h)
			poly.call(6, r * 0.1, rot, 1)
		"web":
			for i in range(8):
				var a := rot + TAU * float(i) / 8.0
				seg(lines, w3(c, h), w3(c + Vector2(cos(a), sin(a)) * r, h), cc)
			for f: float in [0.35, 0.65, 0.95]:
				poly.call(8, r * f, rot, 1)
		"star":
			poly.call(5, r, rot - PI * 0.5, 2)
			ring3(lines, c, r * 0.3, cc, h)
		"fang":
			# Mâchoires d'un piège : couronne de dents.
			ring3(lines, c, r * 0.55, cc, h)
			for i in range(14):
				var a0 := TAU * float(i) / 14.0
				var a1 := TAU * (float(i) + 0.5) / 14.0
				var a2 := TAU * float(i + 1) / 14.0
				seg(lines, w3(c + Vector2(cos(a0), sin(a0)) * r * 0.55, h), w3(c + Vector2(cos(a1), sin(a1)) * r, h), cc)
				seg(lines, w3(c + Vector2(cos(a1), sin(a1)) * r, h), w3(c + Vector2(cos(a2), sin(a2)) * r * 0.55, h), cc)


# ================================================================ FEU

func s_boule_de_feu(_ph: String, _e: Dictionary) -> bool:
	return false # référence : boule de feu et explosion génériques


func s_etincelle(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"fireball":
			mover(FxArt.sprite("spark", Color("ffd45a")), w3(e["from"], 1.0), w3(e["to"], 0.4), float(e["dur"]),
				{"scale": 2.2, "wiggle": 0.12, "arc": 0.4, "trail": [Color.WHITE, Color("ffd45a"), Color(1, 0.5, 0.1, 0.0)], "trail_n": 30, "trail_life": 0.25, "trail_size": 0.05})
			return true
		"explosion":
			var p := w3(e["pos"], 0.3)
			_burst(p, 60, [Color.WHITE, Color("fff3b0"), col, Color(col, 0.0)], 4.5, 0.05, 0.6, -9.0, 160.0)
			_flash(p + Vector3(0, 0.3, 0), 1.6, Color("fff3b0"), 0.18)
			line("rays", {"pos": e["pos"], "r": float(e["r"]) * 0.9, "n": 10, "dur": 0.25, "color": col})
			return true
	return false


func s_comete(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"meteor":
			# Comète : arrive à l'horizontale depuis le fond de l'arène, longue queue.
			var to: Vector2 = e["to"]
			var from := w3(Vector2(to.x + 3.0, to.y + 9.0), 4.5)
			var spr := mover(FxArt.orb_tint(col), from, w3(to, 0.3), float(e["dur"]), {"scale": 3.0,
				"trail": [Color.WHITE, Color("fff3b0"), col, Color(0.4, 0.1, 0.05, 0.0)], "trail_n": 90, "trail_life": 0.9, "trail_size": 0.16, "trail_v": 0.15, "trail_g": 0.0})
			spr.modulate = Color(1.2, 1.1, 1.0)
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			var r := float(e["r"])
			_flash(w3(pos, 0.6), r * 1.4, Color("fff3b0"), 0.4)
			emit(w3(pos, 0.1), Vector3(0.2, 0.05, 0.2), 120, 0.7, Vector3(0, 0.25, 0), 88.0, Vector2(4.0, 7.0), -2.0, 0.14,
				[Color.WHITE, Color("ffb04a"), col, Color(0.3, 0.1, 0.05, 0.0)], 0.0, 1.5)
			fx._scorch(pos, r * 1.1, 3.5)
			line("shock", {"pos": pos, "r": r * 1.3, "dur": 0.5, "color": Color("ffb04a")})
			line("cracks", {"pos": pos, "r": r * 0.9, "n": 9, "dur": 1.6, "color": Color("ff6a2a"), "seed": 5})
			_light(w3(pos, 1.0), col, r * 3.0, 3.0, 0.5)
			return true
	return false


func s_pluie_meteores(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"meteor":
			var to: Vector2 = e["to"]
			mover(FxArt.sprite("rock", Color("c0502a"), _rng.randi() % 4), w3(to + Vector2(-1.2, 1.6), 7.5), w3(to, 0.3), float(e["dur"]),
				{"scale": 2.2, "frames": spin_frames("rock", Color("c0502a")), "spin": 0.07,
				"trail": [Color("fff3b0"), Color("ff8a3a"), Color(0.25, 0.22, 0.25, 0.7), Color(0.2, 0.2, 0.2, 0.0)], "trail_n": 40, "trail_life": 0.6, "trail_size": 0.14, "trail_g": 1.2})
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			_burst(w3(pos, 0.2), 36, [Color("fff3b0"), col, Color(0.3, 0.15, 0.1, 0.0)], 3.4, 0.12, 0.6, -8.0, 70.0)
			_burst(w3(pos, 0.2), 14, [Color("6a4a3a"), Color(0.3, 0.25, 0.2, 0.0)], 3.0, 0.16, 0.8, -12.0, 60.0)
			fx._scorch(pos, float(e["r"]), 2.5)
			line("shock", {"pos": pos, "r": float(e["r"]), "dur": 0.35, "color": col})
			return true
	return false


func s_soleil_noir(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"spell":
			# Un soleil noir se forme au-dessus de la cible, couronne de flammes.
			var at: Vector2 = e["pos"]
			sphere(w3(at, 4.2), w3(at, 0.6), 0.75, Color(0.03, 0.0, 0.02, 0.95), 1.0)
			line("vring", {"pos": at, "h": 4.0, "r": 1.05, "dur": 0.95, "color": Color("ff6a2a"), "jitter": 0.18, "r0": 0.2})
			line("vring", {"pos": at, "h": 4.0, "r": 1.3, "dur": 0.95, "color": Color("c83a2a"), "jitter": 0.3, "r0": 0.1})
			emit(w3(at, 4.0), Vector3(0.6, 0.6, 0.1), 60, 0.6, Vector3.UP, 180.0, Vector2(0.4, 1.0), 0.0, 0.12,
				[Color("ffb04a"), Color("c83a2a"), Color(0.2, 0.0, 0.0, 0.0)], 0.9)
			return true
		"meteor":
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			var r := float(e["r"])
			# Implosion, puis éruption pourpre.
			emit(w3(pos, 0.5), Vector3(r, 0.4, r), 140, 0.35, Vector3.UP, 180.0, Vector2(0.1, 0.2), 0.0, 0.12,
				[Color(0.1, 0.0, 0.0, 0.0), Color(0.1, 0.0, 0.02, 0.9), Color(0.0, 0.0, 0.0, 0.0)])
			_burst(w3(pos, 0.4), 160, [Color("ffd0a0"), Color("ff6a2a"), col, Color(0.15, 0.0, 0.0, 0.0)], 7.0, 0.18, 1.0, -3.0, 90.0)
			line("vring", {"pos": pos, "h": 1.2, "r": r * 0.9, "dur": 0.7, "color": Color("ff6a2a"), "jitter": 0.25, "r0": 0.1})
			line("shock", {"pos": pos, "r": r * 1.4, "dur": 0.8, "color": col})
			fx._scorch(pos, r, 4.0)
			_light(w3(pos, 1.5), Color("ff3a1a"), r * 3.5, 4.0, 0.8)
			return true
	return false


func s_terre_brulee(ph: String, e: Dictionary) -> bool:
	if ph != "ground":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	# Vague de feu au ras du sol qui s'étend jusqu'au bord de la zone.
	for i in range(14):
		var a := TAU * float(i) / 14.0
		var d := Vector2(cos(a), sin(a))
		emit(w3(pos + d * r * 0.85, 0.1), Vector3(0.12, 0.05, 0.12), 18, 0.6, Vector3.UP, 15.0, Vector2(1.0, 2.2), 1.2, 0.12,
			[Color("fff3b0"), Color("ff8a3a"), Color(0.5, 0.1, 0.05, 0.0)], 0.6)
	line("cracks", {"pos": pos, "r": r, "n": 10, "dur": 2.0, "color": Color("ff6a2a"), "seed": 8})
	line("shock", {"pos": pos, "r": r, "dur": 0.6, "color": _c(e)})
	return true


# ================================================================ GIVRE

func s_eclat_givre(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"fireball":
			var spr := mover(FxArt.sprite("shard", col, 2), w3(e["from"], 1.0), w3(e["to"], 0.4), float(e["dur"]),
				{"scale": 1.8, "trail": [Color.WHITE, col, Color(col, 0.0)], "trail_n": 20, "trail_life": 0.3, "trail_size": 0.06, "trail_g": -0.5})
			spr.modulate = Color(1.1, 1.1, 1.2)
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			_burst(w3(pos, 0.3), 40, [Color.WHITE, col, Color(col, 0.0)], 3.6, 0.07, 0.5, -7.0, 120.0)
			for i in range(6):
				var d := Vector2.from_angle(TAU * float(i) / 6.0 + 0.3)
				mover(FxArt.sprite("shard", col, i % 4), w3(pos, 0.4), w3(pos + d * float(e["r"]), 0.1), 0.35, {"scale": 1.0, "linger": 0.3})
			line("glyph", {"pos": pos, "r": float(e["r"]) * 0.7, "shape": "snow", "dur": 0.5, "color": col, "grow": 0.12})
			return true
	return false


func s_prison_glace(ph: String, e: Dictionary) -> bool:
	if ph != "explosion":
		return false
	var col := _c(e)
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	# Cage de cristaux qui jaillissent en cercle.
	for i in range(10):
		var a := TAU * float(i) / 10.0
		riser(FxArt.sprite("crystal", col), pos + Vector2(cos(a), sin(a)) * r * 0.85, 1.9, 2.2, float(i) * 0.02, 0.15)
	riser(FxArt.sprite("crystal", col.lightened(0.2)), pos, 2.6, 2.2, 0.1, 0.18)
	fx._disc(pos, r, Color(0.7, 0.92, 1.0, 0.35), 2.2)
	_burst(w3(pos, 0.3), 40, [Color.WHITE, col, Color(col, 0.0)], 3.0, 0.08, 0.6, -6.0, 80.0)
	line("glyph", {"pos": pos, "r": r, "shape": "hexa", "dur": 2.2, "color": col, "spin": 0.3})
	return true


func s_lance_glace(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"beam", "arrow":
			return true
		"column":
			var x := float(e["x"])
			var y0 := float(e["y0"])
			var y1 := float(e["y1"])
			mover(FxArt.sprite("shard", col, 2), w3(Vector2(x, y0), 0.6), w3(Vector2(x, y1), 0.6), 0.55,
				{"scale": 4.4, "linger": 0.2, "trail": [Color.WHITE, col, Color(col, 0.0)], "trail_n": 60, "trail_life": 0.5, "trail_size": 0.1, "trail_g": -1.0})
			for i in range(7):
				var y := lerpf(y0 + 1.0, y1 - 0.5, float(i) / 6.0)
				riser(FxArt.sprite("crystal", col), Vector2(x + _rng.randf_range(-0.25, 0.25), y), 1.3, 1.2, 0.05 + float(i) * 0.04, 0.12)
			line("colband", {"x": x, "w": float(e.get("w", 0.8)), "y0": y0, "y1": y1, "dur": 0.6, "color": col})
			return true
	return false


func s_blizzard(ph: String, e: Dictionary) -> bool:
	if ph != "rain":
		return false
	var col := _c(e)
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var dur := float(e["dur"])
	# Tempête de neige tourbillonnante : flocons emportés à l'horizontale, brouillard blanc.
	var p := emit(w3(pos, 0.8), Vector3(r * 0.7, 0.6, r * 0.7), 90 + int(r * 30.0), 0.9, Vector3(1, -0.2, 0.3), 40.0, Vector2(2.0, 4.0), -1.0, 0.07,
		[Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.95), Color(col, 0.0)], dur)
	p.orbit_velocity_min = 0.6
	p.orbit_velocity_max = 1.0
	emit(w3(pos, 0.2), Vector3(r * 0.6, 0.1, r * 0.6), 16, 1.6, Vector3.UP, 30.0, Vector2(0.1, 0.3), 0.0, 0.6,
		[Color(1, 1, 1, 0.0), Color(0.95, 0.98, 1.0, 0.22), Color(1, 1, 1, 0.0)], dur)
	fx._disc(pos, r, Color(0.9, 0.96, 1.0, 0.16), dur)
	line("swirl", {"pos": pos, "r": r, "dur": dur, "color": Color(1, 1, 1, 0.9)})
	zone_ring(pos, r, col, dur)
	return true


func s_hiver_eternel(ph: String, e: Dictionary) -> bool:
	if ph != "explosion":
		return false
	var col := _c(e)
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	# Nova de givre : un immense flocon se dessine, onde de froid, neige qui retombe.
	line("glyph", {"pos": pos, "r": r, "shape": "snow", "dur": 1.6, "color": col, "grow": 0.35, "spin": 0.4})
	line("shock", {"pos": pos, "r": r * 1.2, "dur": 0.7, "color": Color.WHITE})
	_flash(w3(pos, 0.6), r * 1.3, Color(0.85, 0.95, 1.0), 0.45)
	emit(w3(pos, 3.0), Vector3(r * 0.7, 0.2, r * 0.7), 120, 1.4, Vector3.DOWN, 20.0, Vector2(0.6, 1.4), -0.8, 0.07,
		[Color(1, 1, 1, 0.0), Color.WHITE, Color(col, 0.0)], 0.9)
	fx._disc(pos, r, Color(0.8, 0.95, 1.0, 0.2), 2.0)
	_light(w3(pos, 1.0), col, r * 3.0, 2.5, 0.6)
	return true


func s_tombeau_glace(ph: String, e: Dictionary) -> bool:
	if ph != "explosion":
		return false
	var col := _c(e)
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	# Dalles de glace qui s'écrasent depuis le ciel sur toute la zone, puis éclats.
	for i in range(9):
		var q := pos + _rand_in(r * 0.85)
		mover(FxArt.sprite("crystal", col.lightened(0.15), 2), w3(q, 8.0), w3(q, 0.7), 0.35 + _rng.randf() * 0.25,
			{"scale": 2.2, "linger": 0.8, "delay": float(i) * 0.05,
			"trail": [Color.WHITE, col, Color(col, 0.0)], "trail_n": 14, "trail_life": 0.3, "trail_size": 0.07})
	for i in range(14):
		var a := TAU * float(i) / 14.0
		riser(FxArt.sprite("crystal", col), pos + Vector2(cos(a), sin(a)) * r * 0.75, 2.2, 2.6, 0.3 + float(i) * 0.02, 0.12)
	fx._disc(pos, r, Color(0.85, 0.97, 1.0, 0.22), 3.0)
	_burst(w3(pos, 0.4), 120, [Color.WHITE, col, Color(col, 0.0)], 6.0, 0.1, 0.9, -6.0, 85.0)
	line("glyph", {"pos": pos, "r": r * 0.9, "shape": "snow", "dur": 2.5, "color": Color.WHITE, "grow": 0.5, "alpha": 0.7})
	return true


func s_banquise(ph: String, e: Dictionary) -> bool:
	if ph != "ground":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	line("cracks", {"pos": pos, "r": r, "n": 12, "dur": 1.8, "color": Color("e8fbff"), "seed": 21})
	for i in range(6):
		riser(FxArt.sprite("shard", _c(e), 0), pos + _rand_in(r * 0.8), 1.1, 1.2, float(i) * 0.05, 0.1)
	_burst(w3(pos, 0.1), 30, [Color.WHITE, _c(e), Color(1, 1, 1, 0.0)], 2.0, 0.06, 0.5, -3.0, 80.0)
	return true


# ================================================================ FOUDRE

func s_decharge(ph: String, e: Dictionary) -> bool:
	if ph != "lightning":
		return false
	var pts: Array = e["pts"]
	# Petite décharge : arc fin et nerveux, étincelles aux cibles.
	line("lightning", {"pts": pts, "dur": 0.5, "color": Color("bfe8ff")})
	for i in range(1, pts.size()):
		mover(FxArt.sprite("spark", Color("bfe8ff")), w3(pts[i], 0.6), w3(pts[i], 1.1), 0.5, {"scale": 3.0, "wiggle": 0.1})
		_burst(w3(pts[i], 0.5), 10, [Color.WHITE, Color("bfe8ff"), Color(0.6, 0.8, 1.0, 0.0)], 2.0, 0.04, 0.3, -6.0, 180.0)
	return true


func s_javelot_foudre(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"beam", "arrow":
			return true
		"column":
			var x := float(e["x"])
			var a := Vector2(x, float(e["y0"]))
			var b := Vector2(x, float(e["y1"]))
			mover(FxArt.sprite("spear", col, 0), w3(a, 0.7), w3(b, 0.7), 0.5,
				{"scale": 3.2, "linger": 0.15, "trail": [Color.WHITE, col, Color(col, 0.0)], "trail_n": 50, "trail_life": 0.3, "trail_size": 0.06})
			line("crackle", {"a": a, "b": b, "speed": 1.0, "r": 0.45, "n": 5, "h": 0.7, "dur": 0.5, "color": col})
			line("colband", {"x": x, "w": float(e.get("w", 0.8)), "y0": a.y, "y1": b.y, "dur": 0.4, "color": col})
			_light(w3((a + b) * 0.5, 1.0), col, 7.0, 2.5, 0.4)
			return true
	return false


func s_jugement_celeste(ph: String, e: Dictionary) -> bool:
	if ph != "lightning":
		return false
	var pts: Array = e["pts"]
	var col := _c(e)
	# Chaque cible est frappée par une colonne de foudre dorée venue du ciel, couronnée d'un halo.
	for i in range(1, pts.size()):
		var p: Vector2 = pts[i]
		line("bolt", {"pos": p, "age": -0.06 * float(i), "dur": 0.4, "color": col, "seed": _rng.randi() % 1000})
		line("vring", {"pos": p, "h": 3.2, "r": 0.5, "dur": 0.6, "color": Color("fff6a8"), "r0": 0.3})
		_flash(w3(p, 0.6), 1.8, Color("fff6a8"), 0.3)
	return true


func s_colere_ciel(ph: String, e: Dictionary) -> bool:
	match ph:
		"spell":
			# Le ciel s'assombrit au-dessus de l'arène.
			var at: Vector2 = e["pos"]
			fx._disc(at, 5.5, Color(0.05, 0.05, 0.1, 0.35), 2.6)
			return true
		"bolt":
			var to: Vector2 = e["to"]
			line("mark", {"pos": to, "r": float(e.get("r", 1.0)), "dur": float(e["dur"]), "color": _c(e)})
			for o in [-0.08, 0.0, 0.08]:
				line("bolt", {"pos": to + Vector2(o, 0.0), "age": -float(e["dur"]), "dur": 0.4, "color": Color("fff6a8"), "seed": _rng.randi() % 1000})
			return true
	return false


func s_champ_statique(ph: String, e: Dictionary) -> bool:
	if ph != "ground":
		return false
	var pos: Vector2 = e["pos"]
	line("crackle", {"a": pos, "r": float(e["r"]), "n": 7, "h": 0.15, "dur": 1.6, "color": _c(e)})
	_burst(w3(pos, 0.2), 30, [Color.WHITE, _c(e), Color(1, 1, 0.5, 0.0)], 2.5, 0.05, 0.4, -4.0, 120.0)
	return true


# ================================================================ NATURE

func s_ronces(ph: String, e: Dictionary) -> bool:
	if ph != "roots":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var dur := float(e["dur"])
	for i in range(10 + int(r * 4.0)):
		riser(FxArt.sprite("bramble", _c(e)), pos + _rand_in(r * 0.9), _rng.randf_range(1.1, 1.5), dur, _rng.randf() * 0.25)
	emit(w3(pos, 0.2), Vector3(r * 0.7, 0.05, r * 0.7), 10, 1.0, Vector3.UP, 40.0, Vector2(0.3, 0.8), -1.0, 0.07,
		[Color("e84a4a"), Color("a02a34"), Color(0.4, 0.1, 0.1, 0.0)], dur)
	fx._disc(pos, r, Color(0.25, 0.3, 0.12, 0.3), dur)
	zone_ring(pos, r, _c(e), dur)
	return true


func s_nuee_lucioles(ph: String, e: Dictionary) -> bool:
	match ph:
		"spell":
			line("fireflies", {"a": e["from"], "b": Vector2(4.5, BattleSim.BARRIER_Y + 0.3), "n": 22, "dur": 2.0, "color": Color("f2e28b")})
			for i in range(12):
				var x := 0.6 + 7.8 * float(i) / 11.0
				var src := (e["pos"] as Vector2) + _rand_in(1.5)
				mover(FxArt.sprite("spark", Color("f2e28b")), w3(src, 1.2), w3(Vector2(x, BattleSim.BARRIER_Y), 0.6), 1.2,
					{"scale": 2.4, "sway": 0.35, "arc": 0.8, "delay": float(i) * 0.05, "linger": 0.4,
					"trail": [Color(1, 1, 0.8, 0.9), Color("f2e28b"), Color(1, 0.9, 0.4, 0.0)], "trail_n": 10, "trail_life": 0.4, "trail_size": 0.05, "trail_g": 0.0})
			return true
		"shield":
			for i in range(5):
				_light(w3(Vector2(1.0 + 1.75 * float(i), BattleSim.BARRIER_Y), 0.7), Color("f2e28b"), 2.5, 1.2, 1.6)
			return true
	return false


func s_etreinte_foret(ph: String, e: Dictionary) -> bool:
	if ph != "roots":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var dur := float(e["dur"])
	var col := _c(e)
	# Grandes racines, pluie de feuilles et ombre de canopée.
	for i in range(8 + int(r * 3.0)):
		var spr_pos := pos + _rand_in(r * 0.9)
		riser(FxArt.root(i % 2), spr_pos, _rng.randf_range(2.0, 2.6), dur, _rng.randf() * 0.3, 0.3)
	for i in range(14):
		var q := pos + _rand_in(r)
		mover(FxArt.sprite("leaf", col, i % 4), w3(q, 3.5 + _rng.randf()), w3(q + Vector2(0.4, 0.0), 0.05), 1.6 + _rng.randf(),
			{"scale": 1.3, "sway": 0.35, "delay": _rng.randf() * maxf(0.1, dur - 1.8), "linger": 0.4})
	fx._disc(pos, r * 1.1, Color(0.05, 0.15, 0.05, 0.4), dur)
	zone_ring(pos, r, col, dur)
	return true


func s_seve_vitale(ph: String, e: Dictionary) -> bool:
	match ph:
		"spell":
			line("vines", {"dur": 2.2, "color": Color("6fbf4a")})
			return true
		"shield":
			emit(w3(Vector2(4.5, BattleSim.BARRIER_Y), 0.1), Vector3(4.3, 0.05, 0.1), 60, 1.2, Vector3.UP, 10.0, Vector2(0.8, 1.6), -0.4, 0.09,
				[Color("e8ffd0"), Color("8fd16a"), Color(0.3, 0.6, 0.2, 0.0)])
			for i in range(8):
				var x := 0.6 + float(i)
				mover(FxArt.sprite("leaf", Color("8fd16a"), i % 4), w3(Vector2(x, BattleSim.BARRIER_Y), 0.2), w3(Vector2(x + 0.3, BattleSim.BARRIER_Y), 1.8), 1.2,
					{"scale": 1.2, "sway": 0.2, "delay": float(i) * 0.06, "fade": true})
			return true
	return false


func s_floraison_putride(ph: String, e: Dictionary) -> bool:
	if ph != "roots":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var dur := float(e["dur"])
	var col := _c(e)
	for i in range(7 + int(r * 2.0)):
		riser(FxArt.sprite("bulb", col), pos + _rand_in(r * 0.85), _rng.randf_range(1.3, 1.8), dur, _rng.randf() * 0.4, 0.35)
	emit(w3(pos, 0.4), Vector3(r * 0.7, 0.2, r * 0.7), 40, 2.0, Vector3.UP, 50.0, Vector2(0.2, 0.6), 0.1, 0.16,
		[Color(0.8, 0.5, 0.7, 0.0), Color(0.75, 0.85, 0.35, 0.45), Color(0.6, 0.4, 0.6, 0.0)], dur)
	fx._disc(pos, r, Color(0.35, 0.4, 0.1, 0.32), dur)
	zone_ring(pos, r, col, dur)
	return true


func s_marais(ph: String, e: Dictionary) -> bool:
	if ph != "ground":
		return false
	var pos: Vector2 = e["pos"]
	line("bubbles", {"pos": pos, "r": float(e["r"]) * 0.8, "n": 18, "dur": 2.0, "color": _c(e)})
	line("shock", {"pos": pos, "r": float(e["r"]), "dur": 0.8, "color": _c(e)})
	_burst(w3(pos, 0.1), 40, [Color.WHITE, _c(e), Color(0.2, 0.4, 0.6, 0.0)], 2.5, 0.08, 0.6, -6.0, 50.0)
	return true


# ================================================================ OMBRE

func s_trait_ombre(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"beam", "arrow":
			return true
		"column":
			# Lance d'ombre : une pique d'encre file le long de la colonne, laissant des volutes noires.
			var x := float(e["x"])
			var a := Vector2(x, float(e["y0"]))
			var b := Vector2(x, float(e["y1"]))
			mover(FxArt.sprite("spear", col, 0), w3(a, 0.6), w3(b, 0.6), 0.6,
				{"scale": 3.2, "linger": 0.2, "trail": [Color(col.lightened(0.3), 0.9), Color(0.1, 0.0, 0.15, 0.9), Color(0.0, 0.0, 0.0, 0.0)], "trail_n": 70, "trail_life": 0.8, "trail_size": 0.16, "trail_v": 0.3, "trail_g": 0.6})
			line("slash", {"a": a, "b": b, "h": 0.6, "dur": 0.5, "color": col})
			emit(w3((a + b) * 0.5, 0.3), Vector3(0.22, 0.1, (b.y - a.y) * 0.5), 110, 1.3, Vector3.UP, 25.0, Vector2(0.3, 0.9), 0.4, 0.2,
				[Color(col.lightened(0.3), 0.0), Color(0.12, 0.02, 0.2, 0.9), Color(col, 0.5), Color(0.0, 0.0, 0.0, 0.0)])
			return true
	return false


func s_vortex_ombre(_ph: String, _e: Dictionary) -> bool:
	return false # référence : vortex générique (spirales aspirantes)


func s_brume_funeste(ph: String, e: Dictionary) -> bool:
	if ph != "vortex":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var dur := float(e["dur"])
	var col := _c(e)
	# Brume rampante : nappes sombres au ras du sol, crânes pâles qui affleurent.
	emit(w3(pos, 0.25), Vector3(r * 0.8, 0.1, r * 0.8), 46, 2.4, Vector3(1, 0.05, 0), 30.0, Vector2(0.1, 0.35), 0.0, 0.55,
		[Color(0.1, 0.05, 0.15, 0.0), Color(0.18, 0.08, 0.28, 0.55), Color(0.1, 0.05, 0.15, 0.0)], dur)
	emit(w3(pos, 0.1), Vector3(r * 0.7, 0.05, r * 0.7), 20, 1.5, Vector3.UP, 20.0, Vector2(0.2, 0.5), 0.1, 0.08,
		[Color(col.lightened(0.4), 0.0), Color(col, 0.7), Color(col, 0.0)], dur)
	for i in range(int(dur / 0.7)):
		var q := pos + _rand_in(r * 0.7)
		mover(FxArt.sprite("skull", Color.WHITE), w3(q, 0.1), w3(q, 1.1), 1.1, {"scale": 1.2, "fade": true, "delay": float(i) * 0.7, "tint": Color(0.85, 0.75, 1.0, 0.6)})
	fx._disc(pos, r, Color(0.08, 0.02, 0.14, 0.5), dur)
	zone_ring(pos, r, col, dur)
	return true


func s_maree_ombre(ph: String, e: Dictionary) -> bool:
	if ph != "wave":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var col := _c(e)
	# Marée noire : un mur liquide s'élève et déferle, des tentacules jaillissent.
	line("tide", {"pos": pos, "r": r, "dur": 0.9, "color": col})
	line("tentacles", {"pos": pos, "r": r, "n": 7, "dur": 1.1, "color": col.darkened(0.2)})
	_burst(w3(pos, 0.4), 120, [Color(col.lightened(0.2), 0.9), Color(0.08, 0.02, 0.12, 0.9), Color(0.0, 0.0, 0.0, 0.0)], 5.5, 0.18, 0.9, -7.0, 70.0)
	fx._ripple(pos, r * 1.1, Color(0.05, 0.0, 0.1, 0.6), 0.9)
	return true


func s_puits_neant(ph: String, e: Dictionary) -> bool:
	if ph != "vortex":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var dur := float(e["dur"])
	var col := _c(e)
	# Trou noir : sphère d'un noir absolu, disque d'accrétion incliné, matière aspirée, halo déformé.
	sphere(w3(pos, 1.0), w3(pos, 1.0), 0.45, Color(0.0, 0.0, 0.0, 1.0), dur)
	line("accretion", {"pos": pos, "h": 1.0, "r": minf(r, 1.4), "dur": dur, "color": col})
	line("vring", {"pos": pos, "h": 1.0, "r": 0.62, "dur": dur, "color": Color(col.lightened(0.5), 0.9), "jitter": 0.06})
	fx._disc(pos, r, Color(0.04, 0.0, 0.08, 0.65), dur)
	_light(w3(pos, 1.0), col, r * 2.0, 1.6, dur)
	zone_ring(pos, r, col, dur)
	return true


func s_eclipse(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"spell":
			# Une lune noire glisse devant un astre au-dessus de la cible : couronne éclatante.
			var at: Vector2 = e["pos"]
			line("vring", {"pos": at, "h": 4.2, "r": 1.1, "dur": 1.05, "color": Color("f2e6ff"), "jitter": 0.12, "r0": 0.6})
			line("vring", {"pos": at, "h": 4.2, "r": 1.45, "dur": 1.05, "color": col.lightened(0.3), "jitter": 0.35, "r0": 0.4})
			sphere(w3(at + Vector2(-1.4, 0.0), 4.2), w3(at, 4.2), 1.05, Color(0.02, 0.0, 0.05, 1.0), 1.05)
			fx._disc(at, float(e["r"]), Color(0.05, 0.0, 0.1, 0.45), 1.6)
			return true
		"meteor":
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			var r := float(e["r"])
			fx._pillar(w3(pos), col.lightened(0.2), 7.0, 0.9, 1.6)
			emit(w3(pos, 0.4), Vector3(r, 0.3, r), 150, 0.8, Vector3.DOWN, 30.0, Vector2(0.5, 1.5), -2.0, 0.15,
				[Color(col.lightened(0.4), 0.9), Color(0.08, 0.0, 0.12, 0.9), Color(0.0, 0.0, 0.0, 0.0)])
			line("vring", {"pos": pos, "h": 0.8, "r": r * 0.8, "dur": 0.6, "color": Color("f2e6ff"), "r0": 0.2})
			line("shock", {"pos": pos, "r": r * 1.2, "dur": 0.7, "color": col})
			return true
	return false


func s_moisson_ames(ph: String, e: Dictionary) -> bool:
	if ph != "explosion":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var col := _c(e)
	# Une faux spectrale balaie tout le cercle ; les âmes montent puis filent vers le lanceur.
	line("arc", {"pos": pos, "r": r * 0.9, "dur": 0.7, "color": col, "a0": _rng.randf() * TAU})
	var pts: Array = []
	for i in range(16):
		pts.append(pos + _rand_in(r * 0.85))
	line("wisps", {"pts": pts, "to": Vector2(4.5, BattleSim.CASTER_Y + 0.5), "dur": 1.6, "color": Color("f0d0ff")})
	_flash(w3(pos, 0.8), r * 1.1, Color(col, 0.6), 0.3)
	fx._ripple(pos, r, Color(col, 0.4), 0.6)
	return true


func s_miasme(ph: String, e: Dictionary) -> bool:
	if ph != "ground":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	line("bubbles", {"pos": pos, "r": r * 0.8, "n": 14, "dur": 2.0, "color": Color("9AD03A")})
	emit(w3(pos, 0.2), Vector3(r * 0.7, 0.1, r * 0.7), 40, 1.4, Vector3.UP, 30.0, Vector2(0.2, 0.6), 0.1, 0.3,
		[Color(0.5, 0.3, 0.7, 0.0), Color(0.45, 0.6, 0.25, 0.45), Color(0.4, 0.2, 0.5, 0.0)], 1.6)
	return true


func s_linceul(ph: String, e: Dictionary) -> bool:
	if ph != "vortex":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var dur := float(e["dur"])
	var col := _c(e)
	# Linceul : des draps spectraux descendent en ondoyant et enveloppent la zone.
	for i in range(int(dur * 2.4)):
		var q := pos + _rand_in(r * 0.8)
		mover(FxArt.sprite("ghost", Color("d8d0f0")), w3(q, 3.0), w3(q, 0.35), 1.6, {"scale": 1.7, "sway": 0.3, "fade": true,
			"delay": float(i) / 2.4, "linger": 0.4, "tint": Color(1, 1, 1, 0.75)})
	emit(w3(pos, 0.5), Vector3(r * 0.7, 0.3, r * 0.7), 30, 1.2, Vector3.UP, 180.0, Vector2(0.05, 0.2), 0.0, 0.1,
		[Color(0.9, 0.9, 1.0, 0.0), Color(0.85, 0.85, 1.0, 0.5), Color(0.8, 0.8, 1.0, 0.0)], dur)
	fx._disc(pos, r, Color(0.6, 0.55, 0.8, 0.22), dur)
	zone_ring(pos, r, col, dur)
	return true


func s_ossements(ph: String, e: Dictionary) -> bool:
	match ph:
		"meteor":
			var to: Vector2 = e["to"]
			mover(FxArt.sprite("bone", Color.WHITE), w3(e["from"], 1.0), w3(to, 0.3), float(e["dur"]),
				{"scale": 1.7, "arc": 2.6, "frames": spin_frames("bone", Color.WHITE), "spin": 0.05})
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			_burst(w3(pos, 0.3), 26, [Color("e8dcc0"), Color("a89c80"), Color(0.6, 0.55, 0.45, 0.0)], 3.2, 0.09, 0.6, -10.0, 70.0)
			for i in range(3):
				var d := Vector2.from_angle(_rng.randf() * TAU)
				mover(FxArt.sprite("bone", Color.WHITE, i), w3(pos, 0.4), w3(pos + d * 0.8, 0.05), 0.4, {"scale": 0.9, "arc": 0.7, "linger": 0.5})
			line("shock", {"pos": pos, "r": float(e["r"]), "dur": 0.3, "color": Color("e8e4d8")})
			return true
	return false


func s_horde(ph: String, e: Dictionary) -> bool:
	match ph:
		"spell":
			var at: Vector2 = e["pos"]
			line("cracks", {"pos": at, "r": 1.8, "n": 8, "dur": 1.6, "color": Color("8e62e0"), "seed": 13})
			return true
		"puff":
			# Chaque squelette surgit : une main osseuse sort de terre.
			riser(FxArt.sprite("hand", Color.WHITE), e["pos"], 1.4, 0.9, 0.0, 0.15)
			_burst(w3(e["pos"], 0.1), 10, [Color("b8b0c8"), Color(0.3, 0.2, 0.4, 0.0)], 1.5, 0.1, 0.5, -3.0, 60.0)
			return true
		"ring":
			return true
	return false


func s_armee_des_morts(ph: String, e: Dictionary) -> bool:
	match ph:
		"spell":
			# Des pierres tombales jaillissent en cercle, feux follets verts sur chacune.
			var at: Vector2 = e["pos"]
			var r := float(e["r"])
			for i in range(10):
				var a := TAU * float(i) / 10.0
				var q := at + Vector2(cos(a), sin(a)) * r * 0.9
				riser(FxArt.sprite("tomb", Color.WHITE), q, 1.6, 3.0, float(i) * 0.04, 0.2)
				emit(w3(q, 0.9), Vector3(0.05, 0.05, 0.05), 10, 0.7, Vector3.UP, 15.0, Vector2(0.4, 0.8), 0.6, 0.1,
					[Color("c8ffb0"), Color("6fe39a"), Color(0.2, 0.5, 0.3, 0.0)], 2.6)
			line("glyph", {"pos": at, "r": r, "shape": "penta", "dur": 3.0, "color": Color("6fe39a"), "spin": 0.2})
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			_burst(w3(pos, 0.4), 80, [Color("e0ffd0"), Color("6fe39a"), Color(0.15, 0.3, 0.2, 0.0)], 5.0, 0.14, 0.9, -3.0, 88.0)
			line("shock", {"pos": pos, "r": float(e["r"]) * 1.2, "dur": 0.7, "color": Color("6fe39a")})
			return true
		"puff":
			riser(FxArt.sprite("hand", Color.WHITE), e["pos"], 1.3, 0.8, 0.0, 0.12)
			return true
		"ring":
			return true
	return false


func s_malediction_masse(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"spell":
			line("glyph", {"pos": e["pos"], "r": float(e["r"]), "shape": "penta", "dur": 0.8, "color": col, "spin": 1.5, "grow": 0.35})
			return true
		"fireball":
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			var r := float(e["r"])
			emit(w3(pos, 0.1), Vector3(r * 0.7, 0.05, r * 0.7), 120, 0.9, Vector3.UP, 10.0, Vector2(1.2, 2.8), 1.0, 0.14,
				[Color("e8d0ff"), col, Color(0.2, 0.05, 0.3, 0.0)])
			line("glyph", {"pos": pos, "r": r, "shape": "penta", "dur": 0.8, "color": Color("e8d0ff"), "grow": 0.01})
			_light(w3(pos, 0.8), col, r * 2.5, 2.4, 0.6)
			return true
	return false


func s_sacrifice_ames(ph: String, e: Dictionary) -> bool:
	match ph:
		"puff":
			# Chaque invocation sacrifiée libère une âme qui monte.
			line("wisps", {"pts": [e["pos"]], "dur": 1.0, "color": Color("e0c0ff")})
			_burst(w3(e["pos"], 0.4), 16, [Color("f0d0ff"), Color("8e62e0"), Color(0.1, 0.0, 0.2, 0.0)], 2.6, 0.1, 0.5, -1.0, 140.0)
			return true
		"ring":
			var pos: Vector2 = e["pos"]
			emit(w3(pos, 0.5), Vector3(float(e["r"]), 0.3, float(e["r"])), 80, 0.4, Vector3.UP, 180.0, Vector2(0.05, 0.1), 0.0, 0.1,
				[Color(0.6, 0.3, 0.9, 0.0), Color(0.55, 0.3, 0.9, 0.9), Color(0.1, 0.0, 0.2, 0.0)])
			line("glyph", {"pos": pos, "r": float(e["r"]), "shape": "tri", "dur": 0.8, "color": Color("8e62e0"), "spin": -1.0})
			return true
	return false


# ================================================================ ARCANE

func s_projectile_arcanique(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"fireball":
			mover(FxArt.orb_tint(col), w3(e["from"], 1.0), w3(e["to"], 0.4), float(e["dur"]),
				{"scale": 1.4, "wiggle": 0.06, "arc": 0.8, "trail": [Color.WHITE, col.lightened(0.3), Color(col, 0.0)], "trail_n": 40, "trail_life": 0.45, "trail_size": 0.05, "trail_v": 0.8, "trail_g": 0.0})
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			line("glyph", {"pos": pos, "r": float(e["r"]), "shape": "tri", "dur": 0.45, "color": col, "spin": 3.0, "grow": 0.1})
			_burst(w3(pos, 0.4), 24, [Color.WHITE, col, Color(col, 0.0)], 2.2, 0.06, 0.6, 0.5, 180.0)
			_flash(w3(pos, 0.5), 1.5, col, 0.25)
			return true
	return false


func s_onde_arcanique(_ph: String, _e: Dictionary) -> bool:
	return false # référence : onde de choc générique


func s_bouclier_arcanique(ph: String, e: Dictionary) -> bool:
	match ph:
		"shield":
			line("hexwall", {"dur": 1.8, "color": _c(e).lightened(0.25)})
			emit(w3(Vector2(4.5, BattleSim.BARRIER_Y), 0.6), Vector3(4.3, 0.6, 0.05), 90, 1.0, Vector3.UP, 180.0, Vector2(0.1, 0.4), 0.0, 0.07,
				[Color.WHITE, _c(e), Color(_c(e), 0.0)])
			for i in range(5):
				fx._flash(w3(Vector2(0.9 + 1.8 * float(i), BattleSim.BARRIER_Y), 0.8), 1.6, Color(_c(e), 0.6), 0.8)
			return true
		"ring":
			return true
	return false


func s_rayon_arcanique(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"beam", "arrow":
			return true
		"column":
			var x := float(e["x"])
			var a := Vector2(x, BattleSim.CASTER_Y + 0.4)
			var b := Vector2(x, float(e["y1"]))
			line("thickbeam", {"a": a, "b": b, "h": 0.7, "w": 0.5, "rings": 7, "dur": 0.9, "color": col})
			line("thickbeam", {"a": a, "b": b, "h": 0.7, "w": 0.18, "dur": 0.9, "color": Color(0.95, 0.9, 1.0)})
			for i in range(6):
				fx._flash(w3(a.lerp(b, float(i) / 5.0), 0.7), 1.4, Color(col, 0.8), 0.6)
			_light(w3((a + b) * 0.5, 1.0), col, 8.0, 2.5, 0.6)
			emit(w3((a + b) * 0.5, 0.7), Vector3(0.15, 0.15, (b.y - a.y) * 0.5), 140, 0.7, Vector3.UP, 180.0, Vector2(0.4, 1.2), 0.0, 0.1,
				[Color.WHITE, col, Color(col, 0.0)])
			return true
	return false


func s_distorsion(ph: String, e: Dictionary) -> bool:
	if ph != "vortex":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var dur := float(e["dur"])
	var col := _c(e)
	# Distorsion du temps : cadran géant, aiguilles qui tournent, particules suspendues.
	line("glyph", {"pos": pos, "r": r, "shape": "clock", "dur": dur, "color": col})
	line("glyph", {"pos": pos, "r": r * 0.4, "shape": "runes", "dur": dur, "color": Color(col, 0.7), "spin": -0.4, "h": 0.5})
	emit(w3(pos, 0.8), Vector3(r * 0.7, 0.6, r * 0.7), 50, 3.0, Vector3.UP, 180.0, Vector2(0.01, 0.06), 0.0, 0.07,
		[Color(col.lightened(0.5), 0.0), Color(col.lightened(0.5), 0.8), Color(col, 0.0)], dur)
	fx._disc(pos, r, Color(0.5, 0.4, 0.8, 0.18), dur)
	return true


func s_nova_arcanique(ph: String, e: Dictionary) -> bool:
	if ph != "explosion":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var col := _c(e)
	line("rays", {"pos": pos, "r": r * 1.2, "n": 16, "dur": 0.6, "color": col})
	line("glyph", {"pos": pos, "r": r * 0.8, "shape": "hexa", "dur": 0.7, "color": Color.WHITE, "spin": 2.0, "grow": 0.1})
	_flash(w3(pos, 0.8), r * 1.2, col.lightened(0.4), 0.4)
	_burst(w3(pos, 0.5), 90, [Color.WHITE, col.lightened(0.3), col, Color(col, 0.0)], 6.0, 0.08, 0.6, 0.0, 180.0)
	return true


func s_dechirure(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"spell":
			# Une faille verticale s'ouvre dans l'air au-dessus de la cible.
			var at: Vector2 = e["pos"]
			fx._pillar(w3(at, 0.5), col, 3.2, 0.7, 0.35)
			line("vring", {"pos": at, "h": 2.1, "r": 0.5, "dur": 0.7, "color": Color("f0e0ff"), "jitter": 0.5, "r0": 0.05})
			return true
		"meteor":
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			var r := float(e["r"])
			for i in range(10):
				var d := Vector2.from_angle(TAU * float(i) / 10.0)
				mover(FxArt.sprite("shard", col, i % 4), w3(pos, 1.4), w3(pos + d * r, 0.2), 0.35, {"scale": 1.6, "linger": 0.3})
			_flash(w3(pos, 1.0), r * 1.1, col, 0.35)
			line("shock", {"pos": pos, "r": r, "dur": 0.5, "color": col})
			line("cracks", {"pos": pos, "r": r, "n": 6, "dur": 1.0, "color": Color("f0e0ff"), "seed": 2})
			return true
	return false


func s_rune_piege(ph: String, e: Dictionary) -> bool:
	if ph != "ground":
		return false
	line("glyph", {"pos": e["pos"], "r": float(e["r"]), "shape": "runes", "dur": 1.4, "color": _c(e), "spin": 0.6})
	return true


# ================================================================ TERRE

func s_jet_pierres(ph: String, e: Dictionary) -> bool:
	match ph:
		"fireball":
			mover(FxArt.sprite("rock", Color("b8905a")), w3(e["from"], 1.0), w3(e["to"], 0.3), float(e["dur"]),
				{"scale": 1.6, "arc": 1.8, "frames": spin_frames("rock", Color("b8905a")), "spin": 0.06})
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			fx.dust(w3(pos, 0.2), Vector3(0.4, 0.1, 0.4), Color("b8a888"), 30)
			_burst(w3(pos, 0.3), 18, [Color("c8a070"), Color("6a5038"), Color(0.3, 0.25, 0.2, 0.0)], 3.0, 0.1, 0.6, -12.0, 60.0)
			return true
	return false


func s_eboulement(ph: String, e: Dictionary) -> bool:
	match ph:
		"meteor":
			var to: Vector2 = e["to"]
			mover(FxArt.sprite("rock", Color("9a7a50")), w3(to + Vector2(0.0, 2.5), 5.0), w3(to, 0.4), float(e["dur"]),
				{"scale": 3.4, "frames": spin_frames("rock", Color("9a7a50")), "spin": 0.1,
				"trail": [Color(0.7, 0.65, 0.55, 0.6), Color(0.5, 0.45, 0.4, 0.0)], "trail_n": 20, "trail_life": 0.5, "trail_size": 0.2})
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			fx.dust(w3(pos, 0.2), Vector3(0.8, 0.1, 0.8), Color("b8a888"), 70)
			line("cracks", {"pos": pos, "r": float(e["r"]), "n": 6, "dur": 1.2, "color": Color("5a4a3a"), "seed": int(pos.x * 7.0)})
			_burst(w3(pos, 0.3), 20, [Color("9a7a50"), Color(0.35, 0.3, 0.25, 0.0)], 3.5, 0.18, 0.7, -12.0, 60.0)
			return true
	return false


func s_faille_tellurique(ph: String, e: Dictionary) -> bool:
	match ph:
		"beam", "arrow":
			return true
		"column":
			# La terre se fend le long de la colonne : faille rougeoyante et roches projetées.
			var x := float(e["x"])
			var y0 := float(e["y0"])
			var y1 := float(e["y1"])
			var prev := Vector2(x, y0)
			for i in range(1, 15):
				var q := Vector2(x + _rng.randf_range(-0.3, 0.3), lerpf(y0, y1, float(i) / 14.0))
				line("crackseg", {"a": prev, "b": q, "dur": 1.8, "color": Color("ff8a3a"), "age": -0.03 * float(i)})
				prev = q
			emit(w3(Vector2(x, (y0 + y1) * 0.5), 0.1), Vector3(0.25, 0.05, (y1 - y0) * 0.5), 90, 1.0, Vector3.UP, 15.0, Vector2(2.5, 5.0), -12.0, 0.15,
				[Color("ffb04a"), Color("8a6a40"), Color(0.3, 0.2, 0.15, 0.0)])
			fx.dust(w3(Vector2(x, (y0 + y1) * 0.5), 0.2), Vector3(0.5, 0.1, (y1 - y0) * 0.5), Color("b8a888"), 80)
			_light(w3(Vector2(x, (y0 + y1) * 0.5), 0.5), Color("ff6a2a"), 6.0, 2.0, 1.2)
			return true
	return false


func s_cataclysme(ph: String, e: Dictionary) -> bool:
	if ph != "quake":
		return false
	# En plus du séisme : roches qui pleuvent sur toute l'arène et ciel rougi.
	for i in range(12):
		var q := Vector2(_rng.randf_range(0.6, 8.4), _rng.randf_range(3.0, 15.0))
		mover(FxArt.sprite("rock", Color("d8a050"), i % 4), w3(q, 7.0), w3(q, 0.3), 0.6, {"scale": 2.6, "delay": float(i) * 0.08,
			"trail": [Color("ffb04a"), Color(0.4, 0.2, 0.1, 0.0)], "trail_n": 16, "trail_life": 0.4, "trail_size": 0.12})
	fx._disc(Vector2(4.5, 8.0), 8.0, Color(0.5, 0.15, 0.05, 0.25), 1.6)
	return false


# ================================================================ SORTS DES COMPAGNONS ET DES CLASSES

func s_charge_bastion(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"beam", "arrow":
			return true
		"column":
			var x := float(e["x"])
			var a := Vector2(x, float(e["y0"]))
			var b := Vector2(x, float(e["y1"]))
			mover(FxArt.sprite("shield", col), w3(a, 0.5), w3(b, 0.5), 0.5, {"scale": 2.4,
				"trail": [Color(0.8, 0.75, 0.65, 0.7), Color(0.6, 0.55, 0.5, 0.0)], "trail_n": 40, "trail_life": 0.6, "trail_size": 0.18, "trail_g": 0.3})
			fx.dust(w3((a + b) * 0.5, 0.1), Vector3(0.4, 0.05, (b.y - a.y) * 0.5), Color("b8a888"), 60)
			line("shock", {"pos": b, "r": 1.0, "dur": 0.5, "age": -0.5, "color": col})
			return true
	return false


func s_volee_fleches(ph: String, e: Dictionary) -> bool:
	if ph != "explosion":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	# Une volée de flèches retombe en pluie oblique sur la zone.
	for i in range(14):
		var q := pos + _rand_in(r)
		mover(FxArt.sprite("arrow", _c(e)), w3(q + Vector2(-0.6, -1.2), 4.0), w3(q, 0.15), 0.3, {"scale": 1.3, "delay": float(i) * 0.025, "linger": 0.6})
	fx.dust(w3(pos, 0.1), Vector3(r * 0.6, 0.05, r * 0.6), Color("b8a888"), 30)
	return true


func s_bouclier_leve(ph: String, e: Dictionary) -> bool:
	match ph:
		"shield":
			# Un rang de boucliers se lève le long de la Barrière.
			for i in range(7):
				var x := 0.9 + float(i) * 1.2
				mover(FxArt.sprite("shield", _c(e)), w3(Vector2(x, BattleSim.BARRIER_Y), -0.2), w3(Vector2(x, BattleSim.BARRIER_Y), 0.7), 0.3,
					{"scale": 2.6, "delay": float(i) * 0.04, "linger": 0.9})
			return true
		"ring":
			return true
	return false


func s_tir_precision(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"beam", "arrow":
			return true
		"column":
			var x := float(e["x"])
			var a := Vector2(x, float(e["y0"]))
			var b := Vector2(x, float(e["y1"]))
			mover(FxArt.sprite("arrow", col, 2), w3(a, 0.55), w3(b, 0.55), 0.4, {"scale": 3.2, "linger": 0.15,
				"trail": [Color.WHITE, col, Color(col, 0.0)], "trail_n": 30, "trail_life": 0.25, "trail_size": 0.04})
			for i in range(4):
				line("vring", {"pos": a.lerp(b, 0.2 + 0.2 * float(i)), "h": 0.55, "r": 0.55, "dur": 0.5, "age": -0.06 * float(i), "color": col.lightened(0.3), "r0": 0.2})
			return true
	return false


func s_hache_tournoyante(ph: String, e: Dictionary) -> bool:
	if ph != "explosion":
		return false
	var pos: Vector2 = e["pos"]
	orbit(spin_frames("axe", _c(e)), w3(pos, 0.6), float(e["r"]) * 0.7, 3, 9.0, 0.7, 1.6)
	line("crescent", {"pos": pos, "r": float(e["r"]) * 0.8, "rot": 0.0, "dur": 0.4, "color": _c(e)})
	line("crescent", {"pos": pos, "r": float(e["r"]) * 0.8, "rot": PI, "dur": 0.4, "age": -0.15, "color": _c(e)})
	return true


func s_bond_furieux(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"beam", "arrow":
			return true
		"column":
			# Bond : une silhouette fauve s'élève et retombe au bout de la colonne.
			var x := float(e["x"])
			var a := Vector2(x, float(e["y0"]))
			var b := Vector2(x, minf(float(e["y1"]), float(e["y0"]) + 8.0))
			mover(FxArt.sprite("axe", col), w3(a, 0.6), w3(b, 0.3), 0.45, {"scale": 2.2, "arc": 3.0, "frames": spin_frames("axe", col), "spin": 0.05,
				"trail": [Color("ffd0a0"), col, Color(col, 0.0)], "trail_n": 30, "trail_life": 0.3, "trail_size": 0.1})
			line("shock", {"pos": b, "r": 1.4, "dur": 0.5, "age": -0.45, "color": col})
			line("cracks", {"pos": b, "r": 1.2, "n": 6, "dur": 1.0, "age": -0.45, "color": Color("6a4a2a"), "seed": 4})
			return true
	return false


func s_lance_solaire(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"beam", "arrow":
			return true
		"column":
			var x := float(e["x"])
			var a := Vector2(x, float(e["y0"]))
			var b := Vector2(x, float(e["y1"]))
			mover(FxArt.sprite("spear", Color("ffe9a0"), 0), w3(a, 0.8), w3(b, 0.8), 0.5, {"scale": 3.4, "linger": 0.15,
				"trail": [Color.WHITE, Color("fff0a0"), Color(1, 0.9, 0.5, 0.0)], "trail_n": 60, "trail_life": 0.6, "trail_size": 0.08, "trail_g": 0.8})
			line("glyph", {"pos": b, "r": 1.0, "shape": "sun", "dur": 0.6, "age": -0.3, "color": col, "spin": 2.0})
			_light(w3((a + b) * 0.5, 1.0), Color("fff0a0"), 8.0, 2.4, 0.5)
			return true
	return false


func s_fente(ph: String, e: Dictionary) -> bool:
	match ph:
		"beam", "arrow":
			return true
		"column":
			var x := float(e["x"])
			var a := Vector2(x, float(e["y0"]))
			var b := Vector2(x, float(e["y1"]))
			line("slash", {"a": a, "b": b, "h": 0.55, "dur": 0.5, "color": _c(e)})
			line("slash", {"a": a + Vector2(0.12, 0.0), "b": b + Vector2(0.12, 0.0), "h": 0.7, "dur": 0.5, "age": -0.05, "color": _c(e)})
			_burst(w3(b, 0.5), 14, [Color.WHITE, _c(e), Color(1, 1, 1, 0.0)], 2.0, 0.05, 0.3, 0.0, 120.0)
			emit(w3((a + b) * 0.5, 0.6), Vector3(0.08, 0.05, (b.y - a.y) * 0.5), 90, 0.45, Vector3(1, 0.2, 0), 60.0, Vector2(1.0, 2.5), -3.0, 0.06,
				[Color.WHITE, Color("c8d8ff"), Color(0.7, 0.8, 1.0, 0.0)])
			for i in range(4):
				fx._flash(w3(a.lerp(b, 0.2 + 0.2 * float(i)), 0.6), 0.9, Color(0.85, 0.9, 1.0, 0.8), 0.35)
			return true
	return false


func s_tranche_orage(ph: String, e: Dictionary) -> bool:
	if ph != "lightning":
		return false
	var pts: Array = e["pts"]
	line("lightning", {"pts": pts, "dur": 0.4, "color": _c(e)})
	for i in range(1, pts.size()):
		line("crescent", {"pos": pts[i], "r": 0.9, "rot": _rng.randf() * TAU, "dur": 0.45, "age": -0.04 * float(i), "color": _c(e)})
		mover(FxArt.sprite("spark", _c(e)), w3(pts[i], 0.6), w3(pts[i], 1.0), 0.4, {"scale": 2.6, "wiggle": 0.1})
	return true


func s_priere(ph: String, e: Dictionary) -> bool:
	match ph:
		"spell":
			for i in range(14):
				var x := 0.4 + 8.2 * float(i) / 13.0
				mover(FxArt.sprite("feather", Color("f2e28b"), i % 2), w3(Vector2(x, BattleSim.BARRIER_Y + 0.4), 4.0), w3(Vector2(x, BattleSim.BARRIER_Y), 0.2), 1.4,
					{"scale": 1.3, "sway": 0.3, "delay": _rng.randf() * 0.4, "fade": true})
			return true
		"shield":
			for i in range(4):
				fx._pillar(w3(Vector2(1.2 + 2.2 * float(i), BattleSim.BARRIER_Y)), Color("f2e28b"), 4.0, 1.0, 0.6)
			return true
	return false


func s_hurlement(ph: String, e: Dictionary) -> bool:
	match ph:
		"spell":
			line("sound", {"pos": e["from"], "r": 6.0, "dur": 0.9, "color": _c(e)})
			line("sound", {"pos": e["from"], "r": 4.0, "dur": 0.9, "age": -0.2, "color": Color("ffd0a0")})
			_burst(w3((e["from"] as Vector2) + Vector2(0.0, 0.6), 0.8), 50, [Color("ffd0a0"), _c(e), Color(0.6, 0.2, 0.1, 0.0)], 4.0, 0.1, 0.6, -2.0, 50.0)
			return true
		"ring":
			return true
	return false


func s_constellation(ph: String, e: Dictionary) -> bool:
	match ph:
		"spell":
			_links.clear()
			return true
		"meteor":
			var to: Vector2 = e["to"]
			mover(FxArt.sprite("star", _c(e)), w3(to + Vector2(0.0, 1.0), 6.0), w3(to, 0.4), float(e["dur"]), {"scale": 1.6,
				"trail": [Color.WHITE, _c(e), Color(_c(e), 0.0)], "trail_n": 20, "trail_life": 0.4, "trail_size": 0.05, "trail_g": 0.0})
			_links.append({"p": to})
			var pts: Array = []
			for l in _links:
				pts.append(l["p"])
			line("links", {"pts": pts, "dur": 1.0, "age": -float(e["dur"]), "color": _c(e)})
			return true
		"explosion":
			line("rays", {"pos": e["pos"], "r": 0.8, "n": 4, "dur": 0.3, "color": Color.WHITE, "rot": PI * 0.25})
			_flash(w3(e["pos"], 0.5), 1.2, _c(e), 0.25)
			return true
	return false


func s_lames_miroirs(ph: String, e: Dictionary) -> bool:
	match ph:
		"ring":
			var pos: Vector2 = e["pos"]
			orbit(spin_frames("shard", _c(e)), w3(pos, 0.7), float(e["r"]) * 0.8, 6, 5.0, 0.8, 1.5)
			_flash(w3(pos, 0.8), 2.4, _c(e), 0.3)
			return true
	return false


func s_exorcisme(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"explosion":
			var pos: Vector2 = e["pos"]
			line("glyph", {"pos": pos, "r": float(e["r"]), "shape": "cross", "dur": 0.9, "color": col, "grow": 0.12})
			_flash(w3(pos, 0.8), float(e["r"]) * 1.2, Color.WHITE, 0.4)
			_burst(w3(pos, 0.3), 60, [Color.WHITE, col, Color(col, 0.0)], 3.5, 0.08, 0.8, 1.5, 70.0)
			return true
		"pillar":
			fx._pillar(w3(e["pos"]), Color("fff6c8"), 7.0, 1.0, 1.4)
			return true
	return false


func s_cercle_runique(ph: String, e: Dictionary) -> bool:
	if ph != "vortex":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var dur := float(e["dur"])
	var col := _c(e)
	line("glyph", {"pos": pos, "r": r, "shape": "runes", "dur": dur, "color": col, "spin": 0.5})
	line("glyph", {"pos": pos, "r": r * 0.55, "shape": "hexa", "dur": dur, "color": Color(col, 0.7), "spin": -0.8, "h": 0.08})
	emit(w3(pos, 0.1), Vector3(r * 0.7, 0.05, r * 0.7), 30, 1.4, Vector3.UP, 5.0, Vector2(0.4, 0.9), 0.0, 0.06,
		[Color.WHITE, col, Color(col, 0.0)], dur)
	_light(w3(pos, 0.6), col, r * 2.0, 1.4, dur)
	return true


func s_rage_primordiale(ph: String, e: Dictionary) -> bool:
	match ph:
		"spell":
			var from: Vector2 = e["from"]
			emit(w3(Vector2(4.5, 4.0), 0.4), Vector3(4.2, 0.3, 3.0), 120, 1.4, Vector3.UP, 60.0, Vector2(0.3, 1.0), 0.2, 0.14,
				[Color(0.9, 0.2, 0.1, 0.0), Color(0.75, 0.08, 0.05, 0.55), Color(0.3, 0.0, 0.0, 0.0)])
			line("sound", {"pos": from, "r": 4.0, "dur": 0.7, "color": Color("d9442a")})
			_light(w3(from + Vector2(0.0, 2.0), 1.0), Color("ff3a1a"), 8.0, 2.4, 0.7)
			return true
		"ring":
			return true
	return false


# ================================================================ ULTIMES

func s_meteore(_ph: String, _e: Dictionary) -> bool:
	return false # référence : météore arcanique générique


func s_pluie_etoiles(ph: String, e: Dictionary) -> bool:
	match ph:
		"meteor":
			var to: Vector2 = e["to"]
			mover(FxArt.sprite("star", _c(e)), w3(to + Vector2(-1.0, 2.0), 8.0), w3(to, 0.3), float(e["dur"]), {"scale": 2.4,
				"trail": [Color.WHITE, Color("fff6c8"), Color(1, 0.95, 0.7, 0.0)], "trail_n": 40, "trail_life": 0.6, "trail_size": 0.06, "trail_g": 0.0, "trail_v": 0.6})
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			line("rays", {"pos": pos, "r": float(e["r"]) * 1.2, "n": 8, "dur": 0.4, "color": Color("fff6c8"), "rot": _rng.randf()})
			_burst(w3(pos, 0.4), 30, [Color.WHITE, Color("fff6c8"), Color(1, 0.9, 0.6, 0.0)], 3.0, 0.06, 0.6, 0.5, 180.0)
			_flash(w3(pos, 0.5), 2.0, Color("fff6c8"), 0.3)
			return true
	return false


func s_mille_lames(ph: String, e: Dictionary) -> bool:
	match ph:
		"bolt":
			var to: Vector2 = e["to"]
			mover(FxArt.sprite("blade", _c(e)), w3(to, 6.0), w3(to, 0.4), float(e["dur"]), {"scale": 2.0, "linger": 0.35,
				"trail": [Color.WHITE, Color(0.85, 0.9, 1.0, 0.5), Color(1, 1, 1, 0.0)], "trail_n": 16, "trail_life": 0.2, "trail_size": 0.04})
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			_burst(w3(pos, 0.3), 16, [Color.WHITE, Color("e8eef8"), Color(0.6, 0.7, 0.8, 0.0)], 3.0, 0.05, 0.3, -6.0, 120.0)
			line("crescent", {"pos": pos, "r": 0.5, "rot": _rng.randf() * TAU, "dur": 0.25, "color": _c(e)})
			return true
	return false


func s_jugement_solaire(ph: String, e: Dictionary) -> bool:
	var col := _c(e)
	match ph:
		"meteor":
			# Un astre descend lentement, rayons tournants.
			var to: Vector2 = e["to"]
			sphere(w3(to, 7.0), w3(to, 0.6), 0.8, Color(1.0, 0.92, 0.55, 0.95), float(e["dur"]) + 0.1, true)
			line("glyph", {"pos": to, "r": float(e["r"]), "shape": "sun", "dur": float(e["dur"]) + 0.6, "color": col, "spin": 1.2})
			return true
		"explosion":
			var pos: Vector2 = e["pos"]
			var r := float(e["r"])
			_flash(w3(pos, 1.0), r * 1.4, Color("fff6c8"), 0.5)
			line("rays", {"pos": pos, "r": r * 1.6, "n": 24, "dur": 0.8, "color": col})
			fx._pillar(w3(pos), Color("fff0a0"), 9.0, 0.9, 2.4)
			_burst(w3(pos, 0.5), 140, [Color.WHITE, Color("fff6c8"), col, Color(col, 0.0)], 7.0, 0.1, 0.9, 1.0, 90.0)
			return true
	return false


func s_rempart_sacre(ph: String, e: Dictionary) -> bool:
	if ph != "wave":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	var col := _c(e)
	# Dôme doré : anneaux verticaux tournés qui dessinent une coupole, puis onde.
	for i in range(5):
		line("vring", {"pos": pos + Vector2(0.0, (float(i) - 2.0) * r * 0.25), "h": 0.0, "r": r * sqrt(1.0 - pow((float(i) - 2.0) * 0.25, 2.0)) * 0.9,
			"dur": 0.9, "color": col, "r0": 0.2})
	line("wave", {"pos": pos, "r": r, "dur": 0.8, "color": col})
	_flash(w3(pos, 0.8), r * 1.0, col, 0.4)
	for i in range(6):
		var d := Vector2.from_angle(TAU * float(i) / 6.0)
		mover(FxArt.sprite("shield", col), w3(pos, 0.8), w3(pos + d * r * 0.8, 0.8), 0.4, {"scale": 1.8, "linger": 0.4})
	return true


func s_dechainement(ph: String, e: Dictionary) -> bool:
	match ph:
		"explosion":
			var pos: Vector2 = e["pos"]
			var r := float(e["r"])
			emit(w3(pos, 0.1), Vector3(r * 0.2, 0.05, r * 0.2), 160, 0.8, Vector3(0, 0.3, 0), 88.0, Vector2(4.0, 8.0), 0.0, 0.16,
				[Color("ffd0a0"), Color("e8703a"), Color("a02a1a"), Color(0.2, 0.0, 0.0, 0.0)], 0.0, 2.0)
			line("shock", {"pos": pos, "r": r * 1.3, "dur": 0.7, "color": Color("e8703a")})
			line("cracks", {"pos": pos, "r": r, "n": 10, "dur": 1.6, "color": Color("a02a1a"), "seed": 9})
			fx._scorch(pos, r, 2.5)
			return true
		"spell":
			line("sound", {"pos": e["from"], "r": 8.0, "dur": 1.0, "color": Color("e8703a")})
			return false
		"ring":
			return true
	return false

# ================================================================ SORTS DE RÉFÉRENCE
# Ces sorts gardent l'animation générique de leur phase, qu'ils sont désormais seuls à utiliser.


func s_brasier(_ph: String, _e: Dictionary) -> bool:
	return false # référence : brasier générique (flammes montantes, disque rougeoyant)


func s_mur_flammes(_ph: String, _e: Dictionary) -> bool:
	return false # référence : colonne de flammes générique


func s_pluie_de_givre(_ph: String, _e: Dictionary) -> bool:
	return false # référence : pluie de givre générique (gouttes verticales)


func s_eclair_chaine(_ph: String, _e: Dictionary) -> bool:
	return false # référence : éclair en chaîne générique


func s_orage(_ph: String, _e: Dictionary) -> bool:
	return false # référence : éclairs tombés du ciel génériques


func s_tempete(_ph: String, _e: Dictionary) -> bool:
	return false # référence : tempête générique (pluie et éclairs)


func s_racines(_ph: String, _e: Dictionary) -> bool:
	return false # référence : racines génériques


func s_epines(_ph: String, _e: Dictionary) -> bool:
	return false # référence : colonne d'épines générique


func s_pic_rocheux(_ph: String, _e: Dictionary) -> bool:
	return false # référence : colonne de roches générique


func s_mur_pierre(_ph: String, _e: Dictionary) -> bool:
	return false # référence : mur dessiné par TerrainView


func s_seisme(_ph: String, _e: Dictionary) -> bool:
	return false # référence : séisme générique (bande de poussière)


func s_purifier(_ph: String, _e: Dictionary) -> bool:
	return false # référence : colonne de lumière générique


# ================================================================ ACTE 6 · souffles draconiques

## Souffle draconique (Ignara) : un torrent de flammes court le long de la colonne, des braises en jaillissent.
func s_souffle_draconique(ph: String, e: Dictionary) -> bool:
	match ph:
		"beam", "arrow":
			return true
		"column":
			var x := float(e["x"])
			var a := Vector2(x, float(e["y0"]))
			var b := Vector2(x, float(e["y1"]))
			for i in range(10):
				var p := a.lerp(b, float(i) / 9.0)
				emit(w3(p, 0.3), Vector3(0.18, 0.08, 0.18), 14, 0.5, Vector3.UP, 25.0, Vector2(0.8, 1.8), 0.6, 0.1,
					[Color("fff3b0"), Color("ff8a3a"), Color(0.6, 0.12, 0.04, 0.0)], 0.04 * float(i))
			line("vring", {"pos": a, "h": 0.4, "r": 0.6, "dur": 0.4, "color": Color("ffb050"), "r0": 0.2})
			return true
	return false


## Souffle de cendre (Héritage) : un nuage de braises et de cendre noire qui retombe sur la zone.
func s_souffle_de_cendre(ph: String, e: Dictionary) -> bool:
	if ph != "explosion":
		return false
	var pos: Vector2 = e["pos"]
	var r := float(e["r"])
	_burst(w3(pos, 0.4), 26, [Color("ffd070"), Color("ff6a2a"), Color(0.15, 0.1, 0.1, 0.0)], 2.6, 0.06, 0.7, 0.4, 180.0)
	emit(w3(pos, 0.2), Vector3(r * 0.6, 0.05, r * 0.6), 30, 1.0, Vector3.UP, 30.0, Vector2(0.4, 1.0), -0.2, 0.12,
		[Color(0.3, 0.25, 0.25, 0.8), Color(0.12, 0.1, 0.1, 0.5), Color(0.05, 0.05, 0.05, 0.0)], 0.0)
	line("shock", {"pos": pos, "r": r, "dur": 0.5, "color": Color("ff6a2a")})
	return true


## Chant des Archives (Ssareth) : des fils de corail lumineux montent de la Barrière, comme des notes.
func s_chant_archives(ph: String, e: Dictionary) -> bool:
	match ph:
		"spell":
			for i in range(12):
				var x := 0.4 + 8.2 * float(i) / 11.0
				emit(w3(Vector2(x, BattleSim.BARRIER_Y), 0.1), Vector3(0.1, 0.02, 0.1), 10, 1.2, Vector3.UP, 8.0, Vector2(0.8, 1.6), -0.2, 0.06,
					[Color("bff6ff"), Color("4fe3d2"), Color(0.3, 0.8, 0.8, 0.0)], 0.03 * float(i))
			return true
		"shield", "heal", "ring":
			return true
	return false
