class_name HeroGear
extends RefCounted
## L'équipement porté, dessiné sur le héros en volume (HeroModel) : chaque objet change son allure, d'après son
## type (data/items.json, « art.t »), sa matière (« art.m », palette d'ItemArt.MAT), sa teinte (« art.c »,
## ItemArt.DYE), sa gemme (« art.g ») et sa rareté (liserés, lueur des objets légendaires et mythiques).
## La tenue garde la couleur choisie à la création : l'armure s'y ajoute (plastron, mailles, fourrure, tabard…).
## Repère : voir HeroModel (x à droite du héros, y vers le haut, z vers son dos ; main droite en x 5, y 7).

const RANK := {"commun": 0, "rare": 1, "epique": 2, "legendaire": 3, "mythique": 4}


## Palettes d'un objet : matière (4 tons), teinte (4 tons), gemme, couleur de rareté, rang de rareté.
static func pal(g: Dictionary) -> Dictionary:
	var m: Array = ItemArt.MAT.get(str(g.get("m", "iron")), ItemArt.MAT["iron"])
	var c: Array = ItemArt.DYE.get(str(g.get("c", "")), ItemArt._dye_for(str(g.get("m", "iron"))))
	var rk := int(RANK.get(str(g.get("r", "commun")), 0))
	var rc := Color(str(((Profile.items_db()["rarities"] as Dictionary).get(str(g.get("r", "commun")), {}) as Dictionary).get("color", "B8B8C8")))
	return {"m": [Color(str(m[0])), Color(str(m[1])), Color(str(m[2])), Color(str(m[3]))],
		"c": [Color(str(c[0])), Color(str(c[1])), Color(str(c[2])), Color(str(c[3]))],
		"g": Color(str(g.get("g", "")) if str(g.get("g", "")) != "" else "4fe3d2"), "rc": rc, "rk": rk}


## Liseré de la tenue : la couleur de rareté de l'armure (épique et plus), sinon "" (couleur des yeux).
static func trim_of(gear: Dictionary) -> Variant:
	if not gear.has("armor"):
		return null
	var p := pal(gear["armor"])
	return p["rc"] if int(p["rk"]) >= 2 else null


# ---------------------------------------------------------------- armure

static func armor(m: HeroModel, g: Dictionary, y0: int, tunic: bool) -> void:
	var p := pal(g)
	var mt: Array = p["m"]
	var dy: Array = p["c"]
	var glow := int(p["rk"]) >= 4
	m._part = "body"
	match str(g.get("t", "")):
		"robe":
			# Écharpe en travers de la poitrine (épaule gauche -> hanche droite), bande brodée au-dessus de l'ourlet.
			for k in range(0, 7):
				var x := -3 + k
				var y := 14 - k
				if y >= 9:
					m._put(x, y, m._front(x, y), dy[2] if k % 2 else dy[3])
					m._put(x, y, m._back(x, y), dy[1])
			for x in range(-6, 7):
				for z in range(-4, 5):
					if m.vox.has(Vector3i(x, y0 + 2, z)) and (x + z) % 2 == 0:
						m._put(x, y0 + 2, z, dy[2])
		"tunique":
			# Tabard devant et derrière, bordé.
			for y in range(y0, 14):
				for x in range(-2, 3):
					var edge := absi(x) == 2 or y == y0
					m._put(x, y, m._front(x, y), dy[3] if edge else dy[2])
					m._put(x, y, m._back(x, y), dy[1] if edge else dy[2])
		"manteau":
			# Mantelet de fourrure sur les épaules, col relevé.
			for y in range(12, 16):
				var rx := 5.4 - float(y - 12) * 0.55
				var rz := 3.4 - float(y - 12) * 0.4
				for x in range(-6, 7):
					for z in range(-5, 6):
						var d := Vector2(float(x) / rx, float(z) / rz).length()
						# Le col ne remonte que sur la nuque : le menton reste dégagé.
						if d <= 1.0 and d > 0.6 and not (y >= 14 and z < 1):
							m._put(x, y, z, mt[(x * 3 + y + z) % 3 + 1] if str(g.get("m", "")) == "fur" else (dy[2] if (x + y) % 3 else dy[3]))
			# Le manteau retombe dans le dos.
			for y in range(y0 + 2, 12):
				for x in range(-3, 4):
					m._put(x, y, m._back(x, y) + (1 if y < 11 else 0), dy[1] if (x + y) % 4 else dy[2])
		"brigandine":
			# Cuir clouté sur le buste, petites épaulières.
			for y in range(9, 15):
				for x in range(-4, 5):
					for zf in [m._front(x, y), m._back(x, y)]:
						var stud := (x + y) % 2 == 0 and y < 14
						m._put(x, y, zf, mt[3] if stud else (dy[1] if y % 3 else dy[2]))
			_pauldrons(m, [dy[1], dy[2], mt[2]], false)
		"cuirasse":
			# Plastron de métal (arête au centre), dossière, épaulières.
			for y in range(9, 15):
				for x in range(-4, 5):
					var zf := m._front(x, y)
					var c: Color = mt[3] if x == 0 else (mt[2] if absi(x) < 3 else mt[1])
					m._put(x, y, zf, c, glow and x == 0)
					m._put(x, y, m._back(x, y), mt[1] if absi(x) > 2 else mt[2])
			_pauldrons(m, [mt[1], mt[2], mt[3]], true)
		"mailles":
			# Cotte de mailles : un damier de mailles sur le buste et les hanches.
			for y in range(y0 + 1, 15):
				for x in range(-6, 7):
					for z in range(-4, 5):
						var q := Vector3i(x, y, z)
						if m.vox.has(q) and str(m.vox[q][2]) == "body" and (absi(z) >= 2 or absi(x) >= 3):
							m._put(x, y, z, mt[2] if (x + y + z) % 2 == 0 else mt[1])
	# Ourlet à la couleur de la rareté pour les armures épiques et plus (lumineux sur une mythique).
	if int(p["rk"]) >= 2:
		for x in range(-6, 7):
			for z in range(-4, 5):
				if m.vox.has(Vector3i(x, y0, z)):
					m._put(x, y0, z, p["rc"], glow)


static func _pauldrons(m: HeroModel, c: Array, metal: bool) -> void:
	m._part = "arms"
	for side: int in [-1, 1]:
		for y in range(12, 15):
			for x in range(4, 7):
				for z in range(-2, 2):
					if y == 14 and x == 6:
						continue
					m._put(side * x, y, z, c[2] if y == 14 or (metal and x == 5 and z == -1) else c[1] if y == 13 else c[0])
	m._part = "body"


# ---------------------------------------------------------------- mains et pieds

static func hands(m: HeroModel, g: Dictionary) -> void:
	var p := pal(g)
	var mt: Array = p["m"]
	var dy: Array = p["c"]
	m._part = "arms"
	for side: int in [-1, 1]:
		var x := side * 5
		match str(g.get("t", "")):
			"gants":
				for z in [-1, 0]:
					m._put(x, 7, z, mt[1] if str(g.get("m", "")) == "leather" else dy[1])
					m._put(x, 8, z, dy[2])
			"gantelets":
				for y in range(7, 10):
					for z in [-1, 0]:
						m._put(x, y, z, mt[2] if y < 9 else mt[3])
				m._put(x + side, 8, -1, mt[1])
			"brassards":
				for y in range(8, 11):
					for z in [-1, 0]:
						m._put(x, y, z, mt[2] if y != 9 else dy[2])
				m._put(x + side, 9, -1, mt[3])
			_:
				# Bandes : des bandelettes enroulées.
				for y in range(7, 10):
					for z in [-1, 0]:
						m._put(x, y, z, dy[3] if (y + z) % 2 == 0 else dy[2])


static func feet(m: HeroModel, g: Dictionary, tunic: bool) -> void:
	var p := pal(g)
	var mt: Array = p["m"]
	var dy: Array = p["c"]
	m._part = "legs"
	var top := 4 if tunic else 2
	for side: int in [-2, 1]:
		for x in range(side, side + 2):
			for z in range(-1, 1):
				match str(g.get("t", "")):
					"greves":
						for y in range(0, top + 1):
							m._put(x, y, z, mt[1] if y == 0 else (mt[3] if y == top and z == -1 else mt[2]))
						if z == -1:
							m._put(x, 0, -2, mt[1])
					"sandales":
						m._put(x, 0, z, mt[1])
						if tunic:
							for y in range(1, 3):
								m._put(x, y, z, dy[2] if (y + x) % 2 == 0 else Color("e0ae8e"))
					_:
						for y in range(0, top):
							m._put(x, y, z, mt[1] if y == 0 else (dy[2] if y == top - 1 else mt[2]))
						if z == -1:
							m._put(x, 0, -2, mt[1])


# ---------------------------------------------------------------- tête

## Couvre-chef ; renvoie le mode de coiffure : "full" (il remplace les cheveux), "hat" (il se pose dessus),
## "hood" (capuche) ; "" s'il n'y a rien.
static func head_mode(g: Dictionary) -> String:
	match str(g.get("t", "")):
		"heaume", "nemes":
			return "full"
		"capuche":
			return "hood"
		"chapeau", "couronne", "bandeau", "masque":
			return "hat"
	return ""


static func head(m: HeroModel, g: Dictionary, base: String) -> void:
	var p := pal(g)
	var mt: Array = p["m"]
	var dy: Array = p["c"]
	var gem: Color = p["g"]
	var shine := int(p["rk"]) >= 3
	m._part = "head"
	match str(g.get("t", "")):
		"heaume":
			# Coque de métal sur toute la tête, fente des yeux, nasal ; cornes ou crête selon le heaume.
			for y in range(16, 25):
				var dyy := (float(y) - 19.5) / 4.4
				var k := sqrt(maxf(0.0, 1.0 - dyy * dyy))
				var rx := 3.6 * k + 1.0
				var rz := 3.2 * k + 1.0
				for x in range(-5, 6):
					for z in range(-5, 6):
						var d := Vector2(float(x) / rx, float(z) / rz).length()
						if d > 1.0 or d < 0.6:
							continue
						if z < 0 and y == 19 and absi(x) >= 1 and absi(x) <= 2:
							m._put(x, y, z, Color("0e0a1c"))
							continue
						m._put(x, y, z, mt[3] if y == 21 and z < 0 else (mt[2] if (y + absi(x)) % 5 else mt[1]))
			for y in range(17, 21):
				m._put(0, y, m._front(0, y) - 1, mt[3])
			if base.contains("cornu") or base.contains("drake") or base.contains("taureau"):
				for side: int in [-1, 1]:
					for q in [Vector3i(4, 22, 0), Vector3i(5, 23, 0), Vector3i(6, 24, 1), Vector3i(6, 25, 1), Vector3i(6, 26, 2)]:
						m._put(side * q.x, q.y, q.z, HeroModel.IVORY)
			else:
				for z in range(-3, 5):
					m._put(0, 25, z, dy[2])
					m._put(0, 26, z, dy[3] if z % 2 == 0 else dy[2])
		"capuche":
			m._hood([dy[0], dy[1], dy[2], dy[3]])
		"chapeau":
			# Chapeau pointu : large bord, cône qui part en arrière, ruban et gemme.
			for x in range(-6, 7):
				for z in range(-6, 7):
					var d := Vector2(float(x) / 5.6, float(z) / 5.0).length()
					if d <= 1.0:
						m._put(x, 22, z, dy[1] if d > 0.8 else dy[2])
			for i in range(0, 9):
				var r := 3.4 - float(i) * 0.38
				var cz := float(i) * 0.35
				for x in range(-4, 5):
					for z in range(-4, 7):
						if Vector2(float(x) / maxf(r, 0.6), (float(z) - cz) / maxf(r, 0.6)).length() <= 1.0:
							m._put(x, 23 + i, z, dy[3] if i == 1 else dy[2] if (x + i) % 4 else dy[1])
			m._put(0, 24, m._front(0, 24), gem, true)
		"couronne":
			# Anneau d'or (ou de la matière), pointes, gemme au front.
			for x in range(-5, 6):
				for z in range(-5, 6):
					var d := Vector2(float(x) / 3.9, float(z) / 3.5).length()
					if d <= 1.05 and d >= 0.72:
						m._put(x, 22, z, mt[2])
						if (x + z) % 2 == 0:
							m._put(x, 23, z, mt[3])
							if absi(x) + absi(z) > 3 and (x * 7 + z) % 3 == 0:
								m._put(x, 24, z, mt[2])
			m._put(0, 22, m._front(0, 22), gem, true)
		"bandeau":
			for x in range(-5, 6):
				for z in range(-5, 6):
					var d := Vector2(float(x) / 3.9, float(z) / 3.6).length()
					if d <= 1.05 and d >= 0.7:
						m._put(x, 21, z, dy[2] if (x + z) % 3 else dy[3])
			# Les pans noués derrière.
			for q in [Vector3i(0, 20, 4), Vector3i(1, 19, 5), Vector3i(-1, 19, 5), Vector3i(1, 18, 5), Vector3i(-1, 17, 5)]:
				m._put(q.x, q.y, q.z, dy[1])
			if shine:
				m._put(0, 21, m._front(0, 21), gem, true)
		"masque":
			# Masque sur le visage : plaque, yeux qui luisent.
			for y in range(17, 22):
				for x in range(-3, 4):
					var zf := m._front(x, y) - 1
					var eye := y == 19 and absi(x) == 1
					m._put(x, y, zf, gem if eye else (mt[3] if y == 21 or x == 0 else mt[2]), eye)
			for side: int in [-1, 1]:
				m._put(side * 4, 22, -1, dy[2])
				m._put(side * 4, 23, 0, dy[3])
		"nemes":
			# Coiffe rayée qui couvre la tête et retombe sur les épaules.
			for y in range(14, 24):
				var dyy := (float(y) - 20.0) / 4.0
				var k := sqrt(maxf(0.0, 1.0 - dyy * dyy)) if y >= 18 else 1.0
				var rx := 3.6 * k + 1.0 if y >= 18 else 4.6
				var rz := 3.2 * k + 1.0 if y >= 18 else 3.0
				for x in range(-5, 6):
					for z in range(-4, 6):
						var d := Vector2(float(x) / rx, float(z) / rz).length()
						if d > 1.0 or d < 0.62:
							continue
						if z < 0 and absi(x) <= 2 and y >= 15 and y <= 21:
							continue
						if y < 18 and absi(x) < 3 and z < 1:
							continue
						m._put(x, y, z, mt[2] if y % 2 == 0 else dy[2])
			m._put(0, 22, m._front(0, 22), gem, true)


# ---------------------------------------------------------------- arme et main gauche

## Arme en main droite, d'après son type. Les objets légendaires et mythiques ont une gemme qui luit ;
## un mythique a aussi le fil de sa lame lumineux.
static func weapon(m: HeroModel, g: Dictionary) -> void:
	var p := pal(g)
	var mt: Array = p["m"]
	var dy: Array = p["c"]
	var gem: Color = p["g"]
	var rk := int(p["rk"])
	var lit := rk >= 3
	var edge := rk >= 4
	var woody := str(g.get("m", "")) in ["wood", "darkwood", "moonwood", "bone"]
	var wd: Color = mt[1] if woody else Color(str(ItemArt.MAT["wood"][1]))
	m._part = "hand"
	match str(g.get("t", "")):
		"baton":
			for y in range(2, 24):
				m._pw(6, y, -1, mt[1] if y % 5 else mt[2])
			for q in [Vector3i(5, 24, -1), Vector3i(7, 24, -1), Vector3i(6, 25, -2), Vector3i(6, 25, 0), Vector3i(5, 26, -1), Vector3i(7, 26, -1)]:
				m._pw(q.x, q.y, q.z, mt[2])
			m._pw(6, 25, -1, gem.lightened(0.3), true)
			m._pw(6, 26, -1, Color.WHITE if lit else gem, true)
		"baguette":
			for y in range(5, 14):
				m._pw(6, y, -1, mt[2] if y > 7 else dy[1])
			m._pw(6, 14, -1, gem, true)
			m._pw(6, 15, -1, Color.WHITE, true)
		"sceptre":
			for y in range(4, 16):
				m._pw(6, y, -1, mt[2] if y % 4 else mt[3])
			for q in [Vector3i(5, 16, -1), Vector3i(7, 16, -1), Vector3i(6, 16, -2), Vector3i(6, 16, 0), Vector3i(5, 18, -1), Vector3i(7, 18, -1), Vector3i(6, 19, -1)]:
				m._pw(q.x, q.y, q.z, mt[3])
			m._pw(6, 17, -1, gem, true)
			m._pw(6, 18, -1, gem.lightened(0.4), lit)
		"arc", "arbalete":
			if str(g.get("t", "")) == "arbalete":
				# Arbalète tenue devant : la crosse vers l'avant, l'arc en travers.
				for z in range(-5, 1):
					m._pw(6, 8, z, wd)
				for x in range(3, 10):
					m._pw(x, 9, -5, mt[2] if absi(x - 6) < 3 else mt[1])
				m._pw(6, 9, -4, Color(0.9, 0.9, 0.95))
			else:
				for y in range(3, 21):
					var b := int(round(2.6 * sin(PI * float(y - 3) / 17.0)))
					m._pw(6, y, -1 - b, mt[1] if (y == 11 or y == 12) else mt[2])
					m._pw(6, y, -1, Color(0.92, 0.92, 0.96))
				m._pw(6, 11, -4, dy[2])
			_quiver(m, dy)
		"epee", "rapiere", "cimeterre", "dague":
			var t := str(g.get("t", ""))
			var top := 22 if t == "epee" else (23 if t == "rapiere" else (20 if t == "cimeterre" else 15))
			for y in range(9, top):
				var bend := 0
				if t == "cimeterre":
					bend = int(round(pow(float(y - 9) / float(top - 9), 2.0) * 3.0))
				m._pw(6, y, -1 - bend, Color.WHITE if (y == top - 1 or edge) else mt[2], edge)
				if t != "rapiere" and y > 10 and y < top - 1:
					m._pw(6, y, -2 - bend, mt[1])
			if t == "rapiere":
				for q in [Vector3i(5, 8, -2), Vector3i(7, 8, -2), Vector3i(5, 8, 0), Vector3i(7, 8, 0), Vector3i(6, 8, -2)]:
					m._pw(q.x, q.y, q.z, mt[3])
			for x in range(5, 8):
				m._pw(x, 8, -1, mt[3] if t != "dague" else dy[2])
			m._pw(6, 7, -1, dy[1])
			m._pw(6, 6, -1, gem if lit else mt[3], lit)
		"hache", "marteau", "masse", "fleau":
			var t2 := str(g.get("t", ""))
			for y in range(2, 18):
				m._pw(6, y, -1, wd if y % 4 else dy[2])
			match t2:
				"hache":
					for y in range(14, 21):
						var w := 3 - absi(y - 17) / 2
						for k in range(1, w + 1):
							m._pw(6, y, -1 - k, (Color.WHITE if k == w else mt[2]), edge and k == w)
						m._pw(6, y, 0, mt[1])
				"marteau":
					for y in range(17, 21):
						for z in range(-4, 3):
							m._pw(6, y, z, mt[3] if (z == -4 or z == 2) else mt[2])
							m._pw(5, y, z, mt[1])
				"masse":
					for q in [Vector3i(6, 18, -1), Vector3i(6, 19, -1), Vector3i(5, 18, -1), Vector3i(7, 18, -1), Vector3i(6, 18, -2), Vector3i(6, 18, 0), Vector3i(5, 19, -1), Vector3i(7, 19, -1), Vector3i(6, 19, -2), Vector3i(6, 19, 0), Vector3i(6, 20, -1)]:
						m._pw(q.x, q.y, q.z, mt[2])
					for q in [Vector3i(4, 18, -1), Vector3i(8, 19, -1), Vector3i(6, 18, -3), Vector3i(6, 19, 1), Vector3i(6, 21, -1)]:
						m._pw(q.x, q.y, q.z, mt[3])
				"fleau":
					# La chaîne retombe, la boule à pointes au bout.
					for q in [Vector3i(6, 18, -2), Vector3i(6, 18, -3), Vector3i(6, 17, -4), Vector3i(6, 16, -4)]:
						m._pw(q.x, q.y, q.z, mt[1])
					for q in [Vector3i(6, 14, -4), Vector3i(6, 15, -4), Vector3i(5, 14, -4), Vector3i(7, 14, -4), Vector3i(6, 14, -5), Vector3i(6, 14, -3)]:
						m._pw(q.x, q.y, q.z, mt[2])
					m._pw(6, 13, -4, mt[3])
			if lit:
				m._pw(6, 6, -1, gem, true)
		"faux", "glaive", "lance":
			var t3 := str(g.get("t", ""))
			for y in range(1, 26):
				m._pw(6, y, -1, wd if y % 6 else dy[2])
			match t3:
				"faux":
					for k in range(0, 7):
						var y := 25 - k / 3
						m._pw(6, y, -2 - k, Color.WHITE if k == 6 else mt[2], edge)
						if k < 5:
							m._pw(6, y - 1, -2 - k, mt[1])
				"glaive":
					for y in range(26, 31):
						m._pw(6, y, -1, Color.WHITE if y == 30 else mt[2], edge)
						if y < 29:
							m._pw(6, y, -2, mt[1])
					m._pw(5, 26, -1, mt[3])
					m._pw(7, 26, -1, mt[3])
				"lance":
					for y in range(26, 30):
						m._pw(6, y, -1, Color.WHITE if y == 29 else mt[2], edge)
					m._pw(5, 26, -1, mt[2])
					m._pw(7, 26, -1, mt[2])
					m._pw(6, 25, -2, dy[2])
					m._pw(6, 24, -2, dy[3])
			if lit:
				m._pw(6, 25, 0, gem, true)
		_:
			for y in range(2, 22):
				m._pw(6, y, -1, mt[2])
	if edge:
		m._pw(6, 7, -1, p["rc"], true)


static func _quiver(m: HeroModel, dy: Array) -> void:
	var held := m._part
	m._part = "back"
	for y in range(9, 17):
		m._put(-2, y, 3, dy[1])
		m._put(-1, y, 3, dy[1] if y % 3 else dy[2])
	for x in [-2, -1]:
		m._put(x, 17, 3, Color("e8e8f0"))
		m._put(x, 18, 3, Color("c04a3a"))
	m._part = held


## Main gauche : bouclier, livre, orbe, lanterne, crâne, cor…
static func offhand(m: HeroModel, g: Dictionary) -> void:
	var p := pal(g)
	var mt: Array = p["m"]
	var dy: Array = p["c"]
	var gem: Color = p["g"]
	var lit := int(p["rk"]) >= 3
	m._part = "hand"
	match str(g.get("t", "")):
		"bouclier":
			for y in range(6, 15):
				for z in range(-4, 3):
					var d := Vector2(float(z) + 1.0, (float(y) - 10.0) * 0.9).length()
					if d > 4.3:
						continue
					var rim := d > 3.4
					var boss := d < 1.2
					m._put(-6, y, z, (p["rc"] if int(p["rk"]) >= 2 else mt[3]) if rim else (mt[3] if boss else (dy[2] if (y + z) % 5 else dy[1])), boss and lit)
					m._put(-7, y, z, mt[1])
		"carquois":
			m._part = "back"
			_quiver(m, dy)
		"tome":
			for y in range(6, 11):
				for z in range(-3, 1):
					m._put(-6, y, z, dy[2] if z > -3 else mt[2])
					m._put(-7, y, z, Color("f0e8d0") if y > 6 and y < 10 and z > -3 else dy[1])
			m._put(-6, 8, -3, gem, lit)
		"orbe":
			# L'orbe flotte au-dessus de la main gauche.
			for q in [Vector3i(-6, 10, -1), Vector3i(-6, 11, -1), Vector3i(-5, 10, -1), Vector3i(-7, 10, -1), Vector3i(-6, 10, -2), Vector3i(-6, 10, 0), Vector3i(-6, 9, -1)]:
				m._put(q.x, q.y, q.z, gem, true)
			m._put(-6, 10, -1, Color.WHITE, true)
			for q in [Vector3i(-5, 8, -1), Vector3i(-7, 8, -1), Vector3i(-6, 8, -2)]:
				m._put(q.x, q.y, q.z, mt[2])
		"lanterne":
			for y in range(3, 7):
				m._put(-6, y, -1, mt[1] if y == 3 or y == 6 else gem, y > 3 and y < 6)
				m._put(-6, y, -2, mt[1] if y == 3 or y == 6 else gem.lightened(0.3), y > 3 and y < 6)
			m._put(-6, 7, -1, mt[2])
		"crane":
			for y in range(7, 11):
				for z in range(-3, 0):
					m._put(-6, y, z, Color("e8dcc0") if y > 7 else Color("c8b898"))
			m._put(-6, 9, -3, gem, true)
			m._put(-6, 8, -3, Color("2a2030"))
		"cor":
			for k in range(0, 6):
				m._put(-6, 7 + k / 2, -1 - k, mt[2] if k < 5 else mt[3])
			m._put(-6, 10, -6, mt[3])
			m._put(-6, 9, -6, mt[1])
		"miroir":
			for y in range(8, 12):
				for z in range(-3, 0):
					m._put(-6, y, z, Color("d8e8f8") if y > 8 and y < 11 and z == -2 else mt[2], y == 10 and z == -2)
			m._put(-6, 7, -1, dy[2])
		"enclume":
			for z in range(-3, 1):
				m._put(-6, 8, z, mt[2])
				m._put(-6, 7, z, mt[1])
			m._put(-6, 9, -2, mt[3])
			m._put(-6, 6, -1, mt[1])
		_:
			m._put(-6, 8, -1, mt[2])


# ---------------------------------------------------------------- bijoux

static func amulet(m: HeroModel, g: Dictionary) -> void:
	var p := pal(g)
	var mt: Array = p["m"]
	m._part = "body"
	for x in range(-2, 3):
		var y := 14 if absi(x) == 2 else 13
		m._put(x, y, m._front(x, y), mt[2])
	m._put(0, 12, m._front(0, 12), p["g"], int(p["rk"]) >= 2)
	m._put(0, 11, m._front(0, 11), mt[3])


static func charm(m: HeroModel, g: Dictionary) -> void:
	var p := pal(g)
	var mt: Array = p["m"]
	m._part = "body"
	m._put(3, 10, m._front(3, 10) - 1, mt[2])
	m._put(3, 9, m._front(3, 9) - 1, p["g"], int(p["rk"]) >= 2)
	m._put(3, 8, m._front(3, 8) - 1, mt[1])
