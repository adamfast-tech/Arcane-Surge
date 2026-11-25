class_name ShotFx
extends RefCounted
## Animations des tirs de classe (docs/design/42-tirs-de-classe.md), jouées par SpellFx : le geste du
## lanceur (corde qui claque, coup d'épée, halo, bouclier arraché, haches tournoyantes, os qui sortent de
## terre, lucioles), puis l'impact propre à chaque tir. Chaque classe a sa couleur (ClassFire.COLOR).


static func play(fx: SpellFx, e: Dictionary) -> void:
	var col := Color(str(e.get("color", "FFFFFF")))
	var pos: Vector2 = e.get("pos", Vector2.ZERO)
	match str(e["t"]):
		"shot_fire":
			match str(e.get("kind", "")):
				"fleche":
					_line(fx, "tir_bow", pos, col, 0.2)
				"onde":
					_line(fx, "tir_swing", pos, col, 0.2)
				"lumiere":
					_line(fx, "tir_halo", pos, col, 0.35)
					fx._flash(SpellFx.w3(pos, 1.25), 0.7, col, 0.22)
				"bouclier":
					fx._line_fx.append({"kind": "shock", "pos": pos + Vector2(0.0, 0.1), "r": 0.6, "age": 0.0, "dur": 0.3, "color": Color("c8b89a")})
					_line(fx, "tir_heave", pos, col, 0.22)
				"hache":
					_line(fx, "tir_whirl", pos, col, 0.14)
		"shot_hit":
			var p3 := SpellFx.w3(pos, 0.4)
			match str(e.get("kind", "")):
				"fleche":
					fx._burst(p3, 6, [Color.WHITE, col, Color(col, 0.0)], 1.6, 0.06, 0.25, -4.0, 60.0)
					_line(fx, "tir_spark", pos, col, 0.15)
				"onde":
					_line(fx, "tir_slash", pos, col, 0.2)
				"bouclier":
					fx._burst(SpellFx.w3(pos, 0.15), 12, [Color("d8ccb0"), Color("8a7a60"), Color(0.5, 0.45, 0.35, 0.0)], 2.2, 0.09, 0.45, -5.0, 70.0)
					fx._flash(SpellFx.w3(pos, 0.45), 0.8, col.lerp(Color.WHITE, 0.4), 0.18)
				"hache":
					fx._burst(p3, 5, [Color("ffd0a0"), col, Color(col, 0.0)], 1.8, 0.05, 0.22, -5.0, 70.0)
					_line(fx, "tir_spark", pos, col, 0.12)
		"shot_shock":
			# Onde de choc du bouclier : deux anneaux qui balaient le groupe, poussière soulevée.
			var r := float(e.get("r", 1.0))
			fx._line_fx.append({"kind": "shock", "pos": pos, "r": r * 1.15, "age": 0.0, "dur": 0.45, "color": col})
			fx._line_fx.append({"kind": "shock", "pos": pos, "r": r * 0.7, "age": -0.08, "dur": 0.4, "color": col.lerp(Color.WHITE, 0.5)})
			fx.dust(SpellFx.w3(pos, 0.1), Vector3(r * 0.8, 0.1, r * 0.8), Color("c8b89a"), 18)
		"shot_beam":
			# Le rayon tombe du ciel sur le groupe ; un éclat d'or rejoint la Barrière qu'il soigne.
			fx._pillar(SpellFx.w3(pos), col, 5.5, 0.45, 0.85)
			fx._line_fx.append({"kind": "shock", "pos": pos, "r": float(e.get("r", 0.95)), "age": 0.0, "dur": 0.4, "color": col})
			fx._burst(SpellFx.w3(pos, 0.2), 14, [Color.WHITE, col, Color(col, 0.0)], 2.4, 0.07, 0.5, 1.5, 50.0)
			if int(e.get("n", 0)) > 0:
				_line(fx, "tir_mend", pos, col, 0.45)
		"shot_end":
			if str(e.get("kind", "")) == "onde":
				_line(fx, "tir_fade", pos, col, 0.22)
			else:
				fx._flash(SpellFx.w3(pos, 0.8), 0.5, col, 0.2)
		"rise":
			# Squelette du Nécromancien : cercle de runes, terre et os projetés.
			_line(fx, "tir_runes", pos, col, 0.5)
			fx._burst(SpellFx.w3(pos, 0.05), 12, [Color("6a5038"), Color("3a2a1c"), Color(0.2, 0.15, 0.1, 0.0)], 2.4, 0.08, 0.5, -7.0, 35.0)
			fx._burst(SpellFx.w3(pos, 0.1), 5, [Color("e8e0d0"), Color("b8b0c8"), Color(0.7, 0.7, 0.8, 0.0)], 2.0, 0.05, 0.45, -6.0, 30.0)
		"fireflies":
			# Mage : trois lucioles jaillissent du bâton et filent chacune à sa place.
			var lf := {"kind": "tir_motes", "pos": e.get("from", pos), "pts": e.get("pts", []), "age": 0.0, "dur": 0.35, "color": col}
			fx._line_fx.append(lf)


static func _line(fx: SpellFx, kind: String, pos: Vector2, col: Color, dur: float) -> void:
	fx._line_fx.append({"kind": kind, "pos": pos, "age": 0.0, "dur": dur, "color": col, "seed": fx._rng.randi() % 1000})


## Effets en traits ; « k » : avancement de 0 à 1.
static func draw(fx: SpellFx, lf: Dictionary, lines: Array, points: Array, k: float) -> void:
	var col: Color = lf["color"]
	var pos: Vector2 = lf["pos"]
	var a := 1.0 - k
	match str(lf["kind"]):
		"tir_bow":
			# La corde de l'arc claque : un arc qui se tend puis se détend, et deux plumes vertes.
			var bend := 0.22 * (1.0 - k * 2.0)
			_arc(lines, pos + Vector2(0.0, 0.55), 0.32, bend, Color(Color.WHITE, a), 0.95)
			points.append([SpellFx.w3(pos + Vector2(-0.12, 0.5 + k * 0.4), 1.0), Color(col, a)])
			points.append([SpellFx.w3(pos + Vector2(0.12, 0.5 + k * 0.4), 1.0), Color(col, a)])
		"tir_swing":
			# Coup d'épée : un arc balaie de gauche à droite devant l'Épéiste.
			var span := clampf(k * 1.6, 0.0, 1.0)
			var prev := Vector2.ZERO
			for i in range(13):
				var ang := lerpf(PI * 0.95, PI * 0.95 - PI * 0.9 * span, float(i) / 12.0)
				var p := pos + Vector2(cos(ang) * 0.95, 0.25 + sin(ang) * 0.75)
				if i > 0:
					lines.append([SpellFx.w3(prev, 0.6), SpellFx.w3(p, 0.6), Color(col.lerp(Color.WHITE, 0.5), a)])
					lines.append([SpellFx.w3(prev, 0.56), SpellFx.w3(p, 0.56), Color(col, a * 0.6)])
				prev = p
		"tir_halo":
			fx._ring(lines, pos + Vector2(0.0, 0.2), 0.3 + 0.45 * k, Color(col, a), 0.08)
			for i in range(4):
				var ang := TAU * float(i) / 4.0 + k * 2.0
				points.append([SpellFx.w3(pos + Vector2(cos(ang), sin(ang)) * 0.35, 0.4 + k * 1.2), Color(Color.WHITE, a)])
		"tir_heave":
			# Le Chevalier arrache son bouclier : deux traits de vitesse vers l'avant.
			for sx: float in [-0.25, 0.25]:
				lines.append([SpellFx.w3(pos + Vector2(sx, 0.4 + k * 0.6), 0.45), SpellFx.w3(pos + Vector2(sx, 0.9 + k * 0.9), 0.45), Color(col, a)])
		"tir_whirl":
			_arc(lines, pos + Vector2(-0.3, 0.45), 0.18, 0.12 * (1.0 - k), Color(col, a), 0.7)
			_arc(lines, pos + Vector2(0.3, 0.45), 0.18, 0.12 * (1.0 - k), Color(col, a), 0.7)
		"tir_spark":
			var r := 0.08 + 0.18 * k
			for d: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				lines.append([SpellFx.w3(pos + d * r * 0.4, 0.45), SpellFx.w3(pos + d * r, 0.45), Color(col.lerp(Color.WHITE, 0.3), a)])
		"tir_slash":
			# Entaille de l'onde : un trait blanc en biais, doublé de la couleur de l'Épéiste.
			var s := float(int(lf.get("seed", 0)) % 2) * 2.0 - 1.0
			var d2 := Vector2(0.32 * s, 0.22)
			lines.append([SpellFx.w3(pos - d2, 0.3), SpellFx.w3(pos + d2, 0.7), Color(Color.WHITE, a)])
			lines.append([SpellFx.w3(pos - d2 + Vector2(0.04, 0.0), 0.28), SpellFx.w3(pos + d2 + Vector2(0.04, 0.0), 0.68), Color(col, a * 0.8)])
		"tir_fade":
			# L'onde s'éteint : l'arc s'élargit et s'efface.
			var prev2 := Vector2.ZERO
			for i in range(11):
				var u := float(i) / 5.0 - 1.0
				var p2 := pos + Vector2(u * (0.9 + 0.4 * k), -0.45 * u * u + 0.1 * k)
				if i > 0:
					lines.append([SpellFx.w3(prev2, 0.15), SpellFx.w3(p2, 0.15), Color(col, a * 0.8)])
				prev2 = p2
		"tir_mend":
			# Éclat d'or qui file soigner la Barrière.
			var bp := Vector2(pos.x, BattleSim.BARRIER_Y)
			var m := pos.lerp(bp, k)
			var h := 0.6 + sin(k * PI) * 0.8
			points.append([SpellFx.w3(m, h), Color(Color.WHITE, 1.0)])
			points.append([SpellFx.w3(pos.lerp(bp, maxf(0.0, k - 0.08)), h - 0.05), Color(col, 0.7)])
			if k > 0.85:
				fx._ring(lines, bp, 0.35 * (k - 0.85) / 0.15 + 0.1, Color(col, 1.0 - (k - 0.85) / 0.15), 0.1)
		"tir_runes":
			# Cercle de runes violet qui tourne au sol, sous le squelette qui sort de terre.
			fx._ring(lines, pos, 0.42, Color(col, a), 0.04)
			for i in range(5):
				var ang := TAU * float(i) / 5.0 + k * 3.0
				var p3 := pos + Vector2(cos(ang), sin(ang)) * 0.42
				lines.append([SpellFx.w3(p3, 0.04), SpellFx.w3(p3 + Vector2(cos(ang), sin(ang)) * 0.14, 0.04), Color(col.lerp(Color.WHITE, 0.3), a)])
		"tir_motes":
			var from: Vector2 = lf["pos"]
			for p4: Vector2 in lf["pts"]:
				for tr in range(3):
					var kk := clampf(k * 1.25 - float(tr) * 0.08, 0.0, 1.0)
					var m4 := from.lerp(p4, kk)
					var h4 := lerpf(1.3, 0.4, kk) + sin(kk * PI) * 0.5
					points.append([SpellFx.w3(m4, h4), Color(Color.WHITE.lerp(col, float(tr) / 2.0), 1.0 - float(tr) * 0.3)])
				if k > 0.8:
					fx._ring(lines, p4, 0.12 + (k - 0.8) * 1.2, Color(col, (1.0 - k) * 5.0), 0.3)


## Arc horizontal (en x) bombé de « bend » vers l'avant.
static func _arc(lines: Array, center: Vector2, half: float, bend: float, col: Color, h: float) -> void:
	var prev := Vector2.ZERO
	for i in range(9):
		var u := float(i) / 4.0 - 1.0
		var p := center + Vector2(u * half, bend * (1.0 - u * u))
		if i > 0:
			lines.append([SpellFx.w3(prev, h), SpellFx.w3(p, h), col])
		prev = p
