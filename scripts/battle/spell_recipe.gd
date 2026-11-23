class_name SpellRecipe
extends RefCounted
## Animations des grimoires de classe (docs/design/29-grimoires-de-classe.md) : chaque technique décrit
## son animation dans data/spells.json (« vfx ») en couches, assemblées ici à partir des briques de SpellSig.
##
## Clés d'une recette, par phase :
## - « shot » : projectile (aoe à délai, barrages) {sp, sc, arc, from: caster|sky|oblique|lob, n, spin, trail, wig, q, orb, grow}.
## - « cast » : au lancement, autour du lanceur.
## - « hit » : impact (explosion, onde, armée, renfort, soin) ; « trap » : piège déclenché ; « set » : piège posé.
## - « col » : colonne ; « chain » : ricochets ; « zone » : zone durable ; « pop » : chaque invocation qui surgit.
## - « c2 » : couleur secondaire.
## Une couche s'écrit « genre:arg1:arg2 » (ex. « rain:arrow:12 », « glyph:target », « burst:40 »).

var sig: SpellSig
var fx: SpellFx
var _rng := RandomNumberGenerator.new()

const PHASE_KEY := {"spell": "cast", "explosion": "hit", "wave": "hit", "ring": "hit", "rally": "hit", "shield": "hit",
	"trap": "trap", "ground": "set", "puff": "pop", "column": "col", "lightning": "chain", "pillar": "pure", "wall": "hit", "quake": "hit",
	"rain": "zone", "roots": "zone", "vortex": "zone", "blaze": "zone", "storm": "zone", "zonefx": "zone"}


func _init(owner: SpellSig) -> void:
	sig = owner
	fx = owner.fx
	_rng.seed = 4271


func play(ph: String, e: Dictionary, v: Dictionary) -> bool:
	var col := Color(str(e.get("color", "FFFFFF")))
	var c2 := Color(str(v.get("c2", col.lightened(0.5).to_html(false))))
	if ph in ["shot", "fireball", "meteor"]:
		if not v.has("shot"):
			return false
		_shot(v["shot"], e, col, c2)
		return true
	if ph in ["beam", "arrow"]:
		return v.has("col")
	var key := str(PHASE_KEY.get(ph, ""))
	if ph == "ring" and v.has("ring"):
		key = "ring"
	if key == "trap" and not v.has("trap"):
		key = "hit"
	if key == "" or not v.has(key):
		return false
	var ctx := {"col": col, "c2": c2, "e": e, "dur": 0.9, "r": float(e.get("r", 1.0)), "pos": e.get("pos", Vector2(4.5, 6.0))}
	match key:
		"cast":
			ctx["pos"] = e.get("from", Vector2(4.5, 1.0))
			ctx["r"] = 1.0
		"col":
			var a := Vector2(float(e["x"]), float(e["y0"]))
			var b := Vector2(float(e["x"]), float(e["y1"]))
			ctx["a"] = a
			ctx["b"] = b
			ctx["pos"] = a.lerp(b, 0.5)
			ctx["r"] = maxf(0.3, float(e.get("w", 0.8)) * 0.5)
			ctx["dur"] = 0.7
		"chain":
			var pts: Array = e["pts"]
			ctx["pts"] = pts
			ctx["pos"] = pts[pts.size() - 1]
			ctx["r"] = 0.6
			ctx["dur"] = float(e.get("dur", 0.45)) + 0.3
		"zone":
			ctx["dur"] = float(e.get("dur", 3.0))
		"hit":
			if ph == "shield":
				ctx["pos"] = Vector2(BattleSim.W * 0.5, BattleSim.BARRIER_Y)
				ctx["r"] = 3.5
				ctx["barrier"] = true
			elif ph == "rally":
				ctx["pos"] = e.get("from", Vector2(4.5, 1.0))
				ctx["pts"] = e.get("pts", [])
				ctx["r"] = 2.0
			elif ph == "wall":
				ctx["r"] = float(e.get("hw", 1.3))
			elif ph == "quake":
				# Séisme : toute la largeur de l'arène, sur une bande.
				ctx["a"] = Vector2(0.4, (ctx["pos"] as Vector2).y)
				ctx["b"] = Vector2(BattleSim.W - 0.4, (ctx["pos"] as Vector2).y)
				ctx["r"] = float(e.get("band", 1.0)) * 0.4
			ctx["dur"] = maxf(0.6, float(e.get("dur", 0.8))) if ph != "rally" else 1.2
		"pop":
			ctx["r"] = 0.5
			ctx["dur"] = 0.7
		"set":
			ctx["dur"] = 0.8
		"pure":
			ctx["r"] = 1.4
			ctx["dur"] = 1.1
	for layer in v[key]:
		_layer(str(layer), ctx)
	return true


# ---------------------------------------------------------------- projectiles

func _shot(s: Dictionary, e: Dictionary, col: Color, c2: Color) -> void:
	var to: Vector2 = e.get("to", e.get("pos", Vector2(4.5, 6.0)))
	var from: Vector2 = e.get("from", Vector2(4.5, 1.0))
	var dur := float(e.get("dur", 0.4))
	var mode := str(s.get("from", "caster"))
	var n := int(s.get("n", 1))
	var spr := str(s.get("sp", "arrow"))
	var tint := Color(str(s.get("tint", col.to_html(false))))
	var q := int(s.get("q", 0 if mode == "sky" or mode == "oblique" else 2))
	for i in range(n):
		var off := Vector2((float(i) - float(n - 1) * 0.5) * 0.4, 0.0)
		var a3: Vector3
		var b3 := SpellSig.w3(to + off * 0.4, 0.3)
		var arc := float(s.get("arc", 0.6))
		match mode:
			"sky":
				a3 = SpellSig.w3(to + off, 6.5)
				arc = 0.0
			"oblique":
				a3 = SpellSig.w3(to + off + Vector2(-1.4, -2.2), 5.0)
				arc = 0.0
			"lob":
				a3 = SpellSig.w3(from + off, 1.0)
				arc = maxf(arc, 2.6)
			_:
				a3 = SpellSig.w3(from + off, 1.0)
		var o := {"scale": float(s.get("sc", 1.8)), "arc": arc, "delay": float(i) * 0.05, "linger": 0.05, "grow": float(s.get("grow", 1.0))}
		if bool(s.get("spin", false)):
			o["frames"] = sig.spin_frames(spr, tint)
			o["spin"] = 0.05
		if bool(s.get("trail", false)):
			o["trail"] = [Color.WHITE, col, Color(c2, 0.0)]
			o["trail_n"] = 26
			o["trail_life"] = 0.3
			o["trail_size"] = 0.06
		if s.has("wig"):
			o["wiggle"] = float(s["wig"])
		if s.has("sway"):
			o["sway"] = float(s["sway"])
		sig.mover(FxArt.sprite(spr, tint, q), a3, b3, dur, o)
		if s.has("orb") and i == 0:
			sig.sphere(a3, b3, float(s["orb"]), Color(col, 0.75), dur, true)


# ---------------------------------------------------------------- couches

func _spot(ctx: Dictionary) -> Vector2:
	if ctx.has("a"):
		var a: Vector2 = ctx["a"]
		var b: Vector2 = ctx["b"]
		return a.lerp(b, _rng.randf_range(0.08, 1.0)) + Vector2(_rng.randf_range(-1.0, 1.0) * float(ctx["r"]), 0.0)
	if ctx.has("barrier"):
		return Vector2(_rng.randf_range(0.6, BattleSim.W - 0.6), BattleSim.BARRIER_Y + _rng.randf_range(0.0, 0.4))
	return (ctx["pos"] as Vector2) + Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * float(ctx["r"])


func _layer(spec: String, ctx: Dictionary) -> void:
	var p := spec.split(":")
	var kind := p[0]
	var a1 := p[1] if p.size() > 1 else ""
	var a2 := p[2] if p.size() > 2 else ""
	var col: Color = ctx["col"]
	var c2: Color = ctx["c2"]
	var pos: Vector2 = ctx["pos"]
	var r := float(ctx["r"])
	var dur := float(ctx["dur"])
	var n := int(a2) if a2 != "" else (int(a1) if a1.is_valid_int() else 8)
	var zone := dur > 1.5
	match kind:
		"rain", "drop":
			# Pluie de sprites (oblique) ou chute verticale.
			var spread := minf(dur * 0.7, 0.5) if not zone else dur * 0.85
			for i in range(n):
				var q := _spot(ctx)
				var top := SpellSig.w3(q + (Vector2(-0.7, -1.3) if kind == "rain" else Vector2.ZERO), 4.4 if kind == "rain" else 6.0)
				sig.mover(FxArt.sprite(a1, col, 0), top, SpellSig.w3(q, 0.15), 0.28 if kind == "rain" else 0.22,
					{"scale": 1.4 if kind == "rain" else 1.9, "delay": spread * float(i) / float(maxi(1, n)), "linger": 0.5})
		"rise":
			for i in range(n):
				sig.riser(FxArt.sprite(a1, col, 0), _spot(ctx), _rng.randf_range(1.3, 2.0), dur if zone else 1.0, _rng.randf() * 0.25)
		"ring":
			for i in range(n):
				var ang := TAU * float(i) / float(n)
				sig.riser(FxArt.sprite(a1, col, 0), pos + Vector2(cos(ang), sin(ang)) * r * 0.9, 1.8, dur if zone else 1.1, float(i) * 0.03)
		"orbit":
			sig.orbit(sig.spin_frames(a1, col), SpellSig.w3(pos, 0.7), r * 0.7, n, 6.0, dur if zone else 0.9, 1.5)
		"fling":
			for i in range(n):
				var ang := TAU * float(i) / float(n) + _rng.randf() * 0.4
				var q := pos + Vector2(cos(ang), sin(ang)) * r * _rng.randf_range(0.9, 1.4)
				sig.mover(FxArt.sprite(a1, col, i % 4), SpellSig.w3(pos, 0.4), SpellSig.w3(q, 0.1), 0.4,
					{"scale": 1.3, "arc": 0.9, "linger": 0.3, "frames": sig.spin_frames(a1, col), "spin": 0.06})
		"flutter":
			# Chute lente qui ondoie (feuilles, plumes).
			for i in range(n):
				var q := _spot(ctx)
				sig.mover(FxArt.sprite(a1, col, 0), SpellSig.w3(q, 3.2), SpellSig.w3(q + Vector2(0.4, 0.0), 0.1), 1.4,
					{"scale": 1.2, "delay": _rng.randf() * minf(dur, 1.6), "sway": 0.35, "fade": true, "linger": 0.3})
		"sweep":
			# Silhouettes qui traversent la zone (cerfs, loups spectraux, cavaliers).
			for i in range(n):
				var y := pos.y + _rng.randf_range(-r, r) * 0.8
				sig.mover(FxArt.sprite(a1, col, 0), SpellSig.w3(Vector2(pos.x - r - 1.5, y), 0.45), SpellSig.w3(Vector2(pos.x + r + 1.5, y), 0.45), 0.6,
					{"scale": 2.0, "delay": float(i) * 0.07, "fade": true, "trail": [Color.WHITE, col, Color(c2, 0.0)], "trail_n": 16, "trail_life": 0.3, "trail_size": 0.07})
		"twinkle":
			for i in range(n):
				var q := _spot(ctx)
				var h := _rng.randf_range(1.0, 2.6)
				sig.mover(FxArt.sprite(a1 if a1 != "" and not a1.is_valid_int() else "spark", c2, 0), SpellSig.w3(q, h), SpellSig.w3(q, h - 0.3), dur,
					{"scale": 1.4, "delay": _rng.randf() * 0.3, "fade": true})
		"paws":
			# Empreintes qui mènent du lanceur au point visé.
			var from: Vector2 = (ctx["e"] as Dictionary).get("from", pos - Vector2(0.0, 3.0))
			for i in range(n):
				var f := float(i + 1) / float(n)
				var q := from.lerp(pos, f) + Vector2(0.18 if i % 2 == 0 else -0.18, 0.0)
				sig.riser(FxArt.sprite("paw", col, 0), q, 1.1, 0.7, f * 0.35, 0.05)
		"allies":
			var pts: Array = ctx.get("pts", [])
			for i in range(mini(pts.size(), 24)):
				var q: Vector2 = pts[i]
				sig.mover(FxArt.sprite(a1, col, 0), SpellSig.w3(q, 0.5), SpellSig.w3(q, 1.3), 0.6, {"scale": 1.1, "delay": float(i) * 0.02, "fade": true, "linger": 0.2})
		"allyburst":
			var pts2: Array = ctx.get("pts", [])
			for i in range(mini(pts2.size(), 24)):
				fx._burst(SpellSig.w3(pts2[i], 0.4), 8, [Color.WHITE, col, Color(c2, 0.0)], 1.6, 0.06, 0.5, 2.0, 120.0)
		"glyph":
			sig.line("glyph", {"pos": pos, "r": r, "shape": a1, "spin": 1.4 if a2 == "" else float(a2), "dur": dur + 0.2, "color": col})
		"glyph2":
			sig.line("glyph", {"pos": pos, "r": r * 0.6, "shape": a1, "spin": -2.0, "dur": dur + 0.2, "color": c2, "h": 0.1})
		"hglyph":
			# Glyphe en l'air, au-dessus de la cible.
			sig.line("glyph", {"pos": pos, "r": r * 0.7, "shape": a1, "spin": 1.0, "dur": dur + 0.2, "color": c2, "h": 2.2})
		"rays":
			sig.line("rays", {"pos": pos, "r": r * 1.2, "n": n, "dur": 0.6, "color": col, "rot": _rng.randf() * TAU})
		"cracks":
			sig.line("cracks", {"pos": pos, "r": r, "n": n, "dur": maxf(dur, 1.0), "color": col, "seed": _rng.randi() % 99})
		"vring":
			for i in range(n):
				sig.line("vring", {"pos": pos, "h": 0.4 + 0.5 * float(i), "r": r * (0.7 - 0.12 * float(i)), "dur": 0.6, "age": -0.07 * float(i), "color": col if i % 2 == 0 else c2, "r0": 0.2})
		"swirl", "bubbles", "tide", "accretion":
			sig.line(kind, {"pos": pos, "r": r, "n": maxi(8, n * 2), "dur": dur, "color": col})
		"tentacles":
			sig.line("tentacles", {"pos": pos, "r": r, "n": n, "dur": dur, "color": col})
		"sound":
			sig.line("sound", {"pos": pos, "r": maxf(2.5, r * 2.0), "dur": 0.8, "color": col})
		"crescent":
			for i in range(maxi(1, n)):
				sig.line("crescent", {"pos": pos, "r": r * 0.8, "rot": TAU * float(i) / float(maxi(1, n)), "dur": 0.45, "age": -0.08 * float(i), "color": col})
		"slash":
			for i in range(maxi(1, n)):
				var ang := _rng.randf() * PI
				var d := Vector2(cos(ang), sin(ang)) * r
				sig.line("slash", {"a": pos - d, "b": pos + d, "dur": 0.4, "age": -0.06 * float(i), "color": col})
		"arc":
			sig.line("arc", {"pos": pos, "r": r * 0.9, "dur": 0.6, "color": col, "a0": _rng.randf() * TAU})
		"crackle":
			sig.line("crackle", {"a": ctx.get("a", pos), "b": ctx.get("b", pos), "r": r, "n": maxi(3, n), "dur": maxf(0.5, dur), "color": col, "speed": 1.6})
		"fireflies":
			var to: Vector2 = Vector2(pos.x, BattleSim.BARRIER_Y) if not ctx.has("barrier") else Vector2(BattleSim.W * 0.5, BattleSim.BARRIER_Y)
			sig.line("fireflies", {"a": pos, "b": to, "n": n, "dur": 1.4, "color": col})
		"vines":
			sig.line("vines", {"dur": 1.4, "color": col})
		"hexwall":
			sig.line("hexwall", {"dur": 1.2, "color": col})
		"burst":
			fx._burst(SpellSig.w3(pos, 0.35), n, [Color.WHITE, col, c2, Color(c2, 0.0)], 3.2 + r, 0.06, 0.6, -6.0, 160.0)
		"puffs":
			fx._burst(SpellSig.w3(pos, 0.3), n, [Color(c2, 0.9), Color(col, 0.6), Color(col, 0.0)], 1.0 + r * 0.5, 0.22, 1.1, 0.6, 90.0)
		"dust":
			fx.dust(SpellSig.w3(pos, 0.1), Vector3(r * 0.7, 0.05, r * 0.7), Color("b8a888"), maxi(20, n * 3))
		"flash":
			fx._flash(SpellSig.w3(pos, 0.8), r * 2.2, c2, 0.2)
			fx._light(SpellSig.w3(pos, 1.0), col, r * 3.0, 2.4, 0.4)
		"orb":
			sig.sphere(SpellSig.w3(pos, 1.0), SpellSig.w3(pos, 1.4), float(a1) if a1 != "" else 0.5, Color(col, 0.7), dur, true)
		"fall":
			sig.sphere(SpellSig.w3(pos + Vector2(-0.6, 0.4), 6.0), SpellSig.w3(pos, 0.4), float(a1) if a1 != "" else 0.7, Color(col, 0.85), 0.55, true)
		"pillar":
			fx._pillar(SpellSig.w3(pos), col, 6.0, maxf(0.8, minf(dur, 1.6)), maxf(0.8, r))
		"pillars":
			for i in range(n):
				fx._pillar(SpellSig.w3(_spot(ctx)), col, 4.0, 0.7, 0.5)
		"shock":
			fx._line_fx.append({"kind": "shock", "pos": pos, "r": r * 1.1, "age": 0.0, "dur": 0.5, "color": col})
		"zone":
			sig.zone_ring(pos, r, col, dur)
		"mist":
			sig.emit(SpellSig.w3(pos, 0.15), Vector3(r * 0.7, 0.05, r * 0.7), maxi(20, int(r * r * 14.0)), 1.6, Vector3.UP, 60.0, Vector2(0.05, 0.3), 0.1, 0.32,
				[Color(c2, 0.0), Color(col, 0.45), Color(col, 0.0)], dur if zone else 0.8)
		"embers":
			sig.emit(SpellSig.w3(pos, 0.1), Vector3(r * 0.7, 0.05, r * 0.7), maxi(16, n * 4), 1.2, Vector3.UP, 25.0, Vector2(0.6, 1.6), 1.0, 0.07,
				[Color.WHITE, c2, col, Color(col, 0.0)], dur if zone else 0.7)
		"snow":
			sig.emit(SpellSig.w3(pos, 3.0), Vector3(r * 0.8, 0.1, r * 0.8), maxi(24, n * 4), 1.6, Vector3.DOWN, 20.0, Vector2(0.6, 1.4), -1.5, 0.07,
				[Color.WHITE, c2, Color(c2, 0.0)], dur if zone else 0.9)
		"spores":
			sig.emit(SpellSig.w3(pos, 0.2), Vector3(r * 0.7, 0.1, r * 0.7), maxi(20, n * 4), 1.8, Vector3.UP, 70.0, Vector2(0.2, 0.7), 0.25, 0.09,
				[Color(c2, 0.9), col, Color(col, 0.0)], dur if zone else 1.0, 1.0)
		"net":
			sig.line("net", {"pos": pos, "r": r, "dur": maxf(1.2, dur), "color": col})
		"moon":
			sig.line("moon", {"pos": pos, "r": r * 0.8, "dur": 1.2, "color": col})
		"thick":
			sig.line("thickbeam", {"a": ctx.get("a", pos), "b": ctx.get("b", pos), "w": maxf(0.15, r * 0.6), "dur": 0.6, "color": col, "rings": n if a1 != "" else 0, "h": 0.6})
		"streak":
			var a: Vector2 = ctx.get("a", pos)
			var b: Vector2 = ctx.get("b", pos)
			sig.mover(FxArt.sprite(a1, col, 2), SpellSig.w3(a, 0.6), SpellSig.w3(b, 0.6), 0.35, {"scale": 2.6 + float(a2 if a2 != "" else "0"), "linger": 0.1,
				"trail": [Color.WHITE, col, Color(c2, 0.0)], "trail_n": 30, "trail_life": 0.25, "trail_size": 0.05})
		"rings":
			var a3: Vector2 = ctx.get("a", pos)
			var b3: Vector2 = ctx.get("b", pos)
			for i in range(n):
				sig.line("vring", {"pos": a3.lerp(b3, (float(i) + 0.5) / float(n)), "h": 0.6, "r": maxf(0.3, r), "dur": 0.5, "age": -0.05 * float(i), "color": col if i % 2 == 0 else c2, "r0": 0.2})
		"hop":
			# Ricochets : le projectile saute de cible en cible.
			var pts: Array = ctx.get("pts", [])
			var step := 0.4 / maxf(1.0, float(pts.size() - 1))
			for i in range(1, pts.size()):
				sig.mover(FxArt.sprite(a1, col, 2), SpellSig.w3(pts[i - 1], 0.6), SpellSig.w3(pts[i], 0.5), step, {"scale": 1.6, "arc": 0.5, "delay": step * float(i - 1),
					"trail": [Color.WHITE, col, Color(c2, 0.0)], "trail_n": 12, "trail_life": 0.2, "trail_size": 0.05})
		"links":
			sig.line("links", {"pts": ctx.get("pts", []), "dur": 0.9, "color": col})
		"each":
			# Couche répétée sur chaque cible d'un ricochet (« each:burst:12 »).
			var pts4: Array = ctx.get("pts", [])
			for i in range(1, pts4.size()):
				var sub := ctx.duplicate()
				sub["pos"] = pts4[i]
				sub["r"] = 0.5
				sub.erase("pts")
				_layer(":".join(p.slice(1)), sub)


## Traits propres aux recettes (appelés par SpellSig.draw).
func draw(lf: Dictionary, lines: Array, _points: Array, k: float, fade: float) -> bool:
	var col: Color = lf["color"]
	match str(lf["kind"]):
		"net":
			# Filet : un maillage qui tombe et se plaque au sol.
			var c: Vector2 = lf["pos"]
			var r := float(lf["r"])
			var h := maxf(0.06, 2.0 * (1.0 - minf(1.0, k * 4.0)))
			var nn := 6
			for i in range(nn + 1):
				var f := -1.0 + 2.0 * float(i) / float(nn)
				var sag := 0.15 * (1.0 - f * f)
				sig.seg(lines, SpellSig.w3(c + Vector2(-r, f * r), h), SpellSig.w3(c + Vector2(r, f * r), h + sag), Color(col, fade))
				sig.seg(lines, SpellSig.w3(c + Vector2(f * r, -r), h), SpellSig.w3(c + Vector2(f * r, r), h + sag), Color(col, fade))
			return true
		"moon":
			# Croissant de lune vertical au-dessus de la cible.
			var c2: Vector2 = lf["pos"]
			var r2 := float(lf["r"]) * minf(1.0, k * 3.0)
			var h2 := 2.0 + 0.3 * sin(k * PI)
			for i in range(20):
				var a0 := PI * 0.25 + PI * 1.5 * float(i) / 20.0
				var a1 := PI * 0.25 + PI * 1.5 * float(i + 1) / 20.0
				sig.seg(lines, Vector3(c2.x + cos(a0) * r2, h2 + sin(a0) * r2, -c2.y), Vector3(c2.x + cos(a1) * r2, h2 + sin(a1) * r2, -c2.y), Color(col.lerp(Color.WHITE, 0.4), fade))
				var r3 := r2 * 0.72
				sig.seg(lines, Vector3(c2.x + r2 * 0.28 + cos(a0) * r3, h2 + sin(a0) * r3, -c2.y), Vector3(c2.x + r2 * 0.28 + cos(a1) * r3, h2 + sin(a1) * r3, -c2.y), Color(col, fade * 0.8))
			return true
	return false
