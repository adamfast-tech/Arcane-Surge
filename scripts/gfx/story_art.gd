class_name StoryArt
extends RefCounted
## Illustrations des scènes de dialogue, en pixel-art généré par code (planches du prologue,
## décors de la zone 1). Rendu en basse résolution puis agrandi au plus proche voisin.

static var _cache: Dictionary = {}


static func plate(kind: String, size: Vector2i) -> ImageTexture:
	var w := clampi(size.x, 64, 640)
	var h := clampi(size.y, 64, 640)
	var key := "%s|%d|%d" % [kind, w, h]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	match kind:
		"fracture":
			_fracture(img, rng)
		"surge":
			_surge(img, rng)
		"collines":
			_collines(img, rng)
		"tour":
			_tour(img, rng)
		"steppe", "moulins", "campement", "orage", "traite", "fort", "route", "pylones", "gue", "caravane", "rebouteux":
			_ambre(img, rng, kind)
		"marais", "cercle", "hydre", "refuge", "pilotis", "mares", "brume", "gue_morts", "croc", "barque", "sorciere":
			_marais(img, rng, kind)
		"pics", "porte", "lac", "forteresse", "colosse", "col", "congeres", "sentinelle", "aurore", "chariot", "portes":
			_pics(img, rng, kind)
		"forge":
			_forge(img, rng)
		"dunes", "oasis", "miroirs", "college", "desert_nuit", "sphinx", "mirage", "scarabee", "caravane_sable", "sceaux":
			_desert(img, rng, kind)
		"cendres", "coulee", "braisemont", "nid", "autels", "citadelle", "caldeira", "antre", "lisiere_cendree", "couloirs", "ailes", "drake":
			_cendres(img, rng, kind)
		"pardon":
			_pardon(img, rng)
		"cite", "quais", "canal", "statues", "archives", "palais", "abysse", "marees", "kraken", "cloche", "portes_archives", "sirenes", "fil", "fosse":
			_cite(img, rng, kind)
		_:
			_forest(img, rng, kind)
	var tex := ImageTexture.create_from_image(img)
	if _cache.size() > 24:
		_cache.clear()
	_cache[key] = tex
	return tex


# ---------------------------------------------------------------- outils

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if c.a < 1.0:
		c = img.get_pixel(x, y).lerp(Color(c, 1.0), c.a)
	img.set_pixel(x, y, c)


static func _disc(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(-r, r + 1):
		var half := int(sqrt(float(r * r - y * y)))
		for x in range(-half, half + 1):
			_px(img, cx + x, cy + y, c)


static func _sky(img: Image, rng: RandomNumberGenerator, stops: Array, stars: float = 1.0) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		var k := float(y) / float(h - 1)
		var c: Color = stops[0][1]
		for i in range(stops.size() - 1):
			if k >= float(stops[i][0]) and k <= float(stops[i + 1][0]):
				c = (stops[i][1] as Color).lerp(stops[i + 1][1], (k - float(stops[i][0])) / (float(stops[i + 1][0]) - float(stops[i][0])))
		img.fill_rect(Rect2i(0, y, w, 1), c)
	for i in range(int(float(w * h) / 220.0 * stars)):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, int(h * 0.55))
		_px(img, x, y, Color(0.92, 0.92, 1.0, rng.randf_range(0.25, 0.95)))


static func _moon(img: Image, x: int, y: int, r: int) -> void:
	for rr in range(r * 3, r, -1):
		_disc(img, x, y, rr, Color(0.7, 0.72, 1.0, 0.035))
	_disc(img, x, y, r, Color("e8e4d0"))
	_disc(img, x + r / 4, y - r / 4, int(r * 0.65), Color("f6f2e2"))
	_px(img, x - r / 3, y + r / 4, Color("c8c2b0"))
	_px(img, x + r / 3, y + r / 3, Color("c8c2b0"))


static func _ridge(img: Image, rng: RandomNumberGenerator, base_y: int, amp: int, body: Color, edge: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var y := float(base_y)
	var slope := 0.0
	var prev := base_y
	for x in range(w):
		slope = clampf(slope + rng.randf_range(-0.4, 0.4), -1.3, 1.3)
		if y < base_y - amp or y > base_y + amp:
			slope = -slope * 0.8
		y += slope
		var top := int(y)
		img.fill_rect(Rect2i(x, top, 1, maxi(0, h - top)), body)
		if top <= prev:
			_px(img, x, top, edge)
		prev = top


## Sapin en silhouette (étages triangulaires), éclairé à droite par la lune.
static func _pine(img: Image, x: int, base: int, hgt: int, body: Color, light: Color) -> void:
	var tiers := clampi(hgt / 8, 3, 6)
	var dark := body.darkened(0.25)
	for t in range(tiers):
		var top := base - hgt + int(float(t) * float(hgt) * 0.78 / float(tiers))
		var bot := top + int(float(hgt) * 0.36)
		var half_max := maxi(2, int(float(hgt) * (0.13 + 0.12 * float(t) / float(tiers))))
		for y in range(top, mini(bot, base - 2)):
			var half := int(round(float(half_max) * float(y - top + 1) / float(maxi(1, bot - top))))
			for dx in range(-half, half + 1):
				var c := body
				if dx == half and dx > 0:
					c = light
				elif dx < -half / 3:
					c = dark
				_px(img, x + dx, y, c)
	img.fill_rect(Rect2i(x - 1, base - 3, 2, 3), body.darkened(0.4))


static func _fireflies(img: Image, rng: RandomNumberGenerator, n: int, y0: int, y1: int, col: Color) -> void:
	for i in range(n):
		var x := rng.randi_range(0, img.get_width() - 1)
		var y := rng.randi_range(y0, y1)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			_px(img, x + d.x, y + d.y, Color(col, 0.35))
		_px(img, x, y, col.lightened(0.3))


static func _mist(img: Image, rng: RandomNumberGenerator, y0: int, y1: int, col: Color, n: int) -> void:
	for i in range(n):
		var y := rng.randi_range(y0, y1)
		var x := rng.randi_range(-40, img.get_width())
		for sx in range(rng.randi_range(30, 90)):
			_px(img, x + sx, y, col)


# ---------------------------------------------------------------- planches

## Bois des Lucioles et ses variantes : lysbourg, foret, foret_gueri, source, pont, nexus, sylvarche.
static func _forest(img: Image, rng: RandomNumberGenerator, kind: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var healed := kind == "foret_gueri"
	var corrupt := kind in ["nexus", "sylvarche", "lysbourg", "roncier"]
	var open_center := kind in ["clairiere", "fougeres", "cercle_fees"] ## clairière : pas d'arbres au milieu
	var top := Color("04050f")
	var mid := Color("1d1a48") if not corrupt else Color("2a1448")
	var low := Color("2d2c5e") if not corrupt else Color("4a2060")
	if healed:
		mid = Color("1a2a4a")
		low = Color("2a4a5a")
	_sky(img, rng, [[0.0, top], [0.4, mid], [0.75, low], [1.0, low.darkened(0.3)]])
	_moon(img, int(w * 0.78), int(h * 0.14), maxi(5, int(minf(w, h) * 0.045)))
	if corrupt:
		# Lueur violette du Surge à l'horizon.
		for y in range(int(h * 0.35), int(h * 0.7)):
			var a := 0.18 * (1.0 - absf(float(y) - h * 0.55) / (h * 0.2))
			if a > 0.0:
				for x in range(w):
					_px(img, x, y, Color("b03cf2", a))
	_ridge(img, rng, int(h * 0.5), int(h * 0.06), Color("1f1e48"), Color("3a3a78"))
	var far := Color("15233a") if not healed else Color("17332f")
	var near := Color("0e1828") if not healed else Color("10261f")
	var far_l := Color("2a3f66") if not healed else Color("3a6a4a")
	var near_l := Color("24365a") if not healed else Color("3f7a4a")
	for i in range(int(w / 7.0)):
		var px := rng.randi_range(-4, w + 4)
		var ph := rng.randi_range(int(h * 0.12), int(h * 0.2))
		var pb := int(h * 0.66) + rng.randi_range(-3, 3)
		if open_center and px > int(w * 0.3) and px < int(w * 0.7):
			continue
		_pine(img, px, pb, ph, far, far_l)
	_mist(img, rng, int(h * 0.58), int(h * 0.7), Color(0.55, 0.55, 0.9, 0.15), int(w / 8.0))
	# Sol.
	var ground := Color("1a2a24") if not healed else Color("1f3a26")
	img.fill_rect(Rect2i(0, int(h * 0.72), w, h - int(h * 0.72)), ground)
	for i in range(w * 2):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(int(h * 0.72), h - 1)
		_px(img, x, y, ground.lightened(0.08) if rng.randf() < 0.5 else ground.darkened(0.15))
	match kind:
		"lysbourg":
			_village(img, rng)
		"source":
			_pond(img, rng)
		"pont":
			_bridge(img, rng)
		"nexus":
			_crystal(img, int(w * 0.5), int(h * 0.62), int(minf(w, h) * 0.13))
		"sentier":
			_path(img, rng)
		"clairiere":
			_clearing(img, rng)
		"roncier":
			_brambles(img, rng)
		"fougeres":
			_moonbeam(img)
		"cercle_fees":
			_fairy_ring(img, rng)
	# Arbres proches sur les bords.
	for side in [0, 1]:
		for k in range(3):
			var x := rng.randi_range(-6, int(w * 0.16)) if side == 0 else rng.randi_range(int(w * 0.84), w + 6)
			_pine(img, x, h + rng.randi_range(0, 6), rng.randi_range(int(h * 0.35), int(h * 0.55)), near, near.lightened(0.12) if not healed else near_l)
	if corrupt:
		for i in range(6):
			var p := Vector2(rng.randf_range(0.0, float(w)), float(h) - 1.0)
			for s in range(int(h * 0.18)):
				_px(img, int(p.x), int(p.y), Color("5b3a8a") if s % 6 != 0 else Color("b07cff"))
				p += Vector2(rng.randf_range(-1.0, 1.0), -rng.randf_range(0.4, 1.0))
	if kind == "fougeres":
		_ferns(img, rng)
	var ff := 20 if kind == "foret" else 8
	if healed or kind == "source" or kind == "sentier":
		ff = 70
	elif kind == "cercle_fees":
		ff = 40
	_fireflies(img, rng, int(ff * w / 240.0), int(h * 0.3), h - 4, Color("f2e28b") if not corrupt else Color("d98cff"))


## 1-2 · Le sentier des lucioles : un chemin de terre qui serpente jusqu'à l'horizon, bordé de pierres.
static func _path(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var y0 := int(h * 0.64)
	for y in range(y0, h):
		var t := float(y - y0) / float(h - y0)
		var cx := float(w) * 0.5 + sin(t * 3.2) * float(w) * 0.09 * t
		var half := lerpf(1.5, float(w) * 0.28, pow(t, 1.3))
		img.fill_rect(Rect2i(int(cx - half), y, int(half * 2.0) + 1, 1), Color("3a3328").lerp(Color("4a4232"), t))
		_px(img, int(cx - half), y, Color("5a4e3a"))
		_px(img, int(cx + half), y, Color("5a4e3a"))
		if rng.randf() < 0.25:
			_px(img, int(cx + rng.randf_range(-half, half)), y, Color("6a5e48"))
		if y % 5 == 0 and t > 0.15:
			for sd: float in [-1.0, 1.0]:
				_disc(img, int(cx + sd * (half + 3.0)), y, maxi(1, int(t * 2.5)), Color("4a4a5a"))


## 1-3 · La clairière brisée : souches éclatées, un tronc couché, branches cassées.
static func _clearing(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var bark := Color("3a2a22")
	for i in range(5):
		var x := rng.randi_range(int(w * 0.22), int(w * 0.78))
		var base := int(h * 0.7) + rng.randi_range(-2, 4)
		var sw := rng.randi_range(4, 8)
		var sh := rng.randi_range(5, 12)
		img.fill_rect(Rect2i(x, base - sh, sw, sh), bark)
		img.fill_rect(Rect2i(x + sw - 1, base - sh, 1, sh), Color("5a4232"))
		for k in range(sw):
			var jag := rng.randi_range(0, 4)
			img.fill_rect(Rect2i(x + k, base - sh - jag, 1, jag), Color("6a5040") if k % 2 == 0 else bark)
	var ly := int(h * 0.76)
	var lx := int(w * 0.3)
	var lw := int(w * 0.34)
	img.fill_rect(Rect2i(lx, ly, lw, 5), Color("4a3428"))
	img.fill_rect(Rect2i(lx, ly, lw, 1), Color("6a5040"))
	_disc(img, lx + lw, ly + 2, 3, Color("7a5a40"))
	_disc(img, lx + lw, ly + 2, 1, Color("4a3428"))
	for i in range(10):
		var a := Vector2(rng.randf_range(w * 0.15, w * 0.85), rng.randf_range(h * 0.72, h * 0.9))
		var b := a + Vector2(rng.randf_range(-8, 8), rng.randf_range(-3, 3))
		for k in range(10):
			var p := a.lerp(b, float(k) / 9.0)
			_px(img, int(p.x), int(p.y), Color("4a3a2e"))


## 1-4 · Le roncier : des ronces maudites étouffent les arbres ; deux pierres runiques (la porte maudite).
static func _brambles(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for sd: int in [-1, 1]:
		var x := int(w * 0.5) + sd * int(w * 0.09)
		img.fill_rect(Rect2i(x - 3, int(h * 0.52), 6, int(h * 0.2)), Color("4a4660"))
		img.fill_rect(Rect2i(x + 2, int(h * 0.52), 1, int(h * 0.2)), Color("6a6680"))
		for k in range(4):
			_px(img, x, int(h * 0.55) + k * 4, Color("d93cf2"))
	img.fill_rect(Rect2i(int(w * 0.41) - 3, int(h * 0.5), int(w * 0.18) + 6, 4), Color("4a4660"))
	for i in range(int(w / 3.0)):
		var p := Vector2(rng.randf_range(-10.0, float(w) + 10.0), rng.randf_range(h * 0.58, h * 0.95))
		var dir := Vector2.from_angle(rng.randf_range(-PI, 0.0))
		for s2 in range(rng.randi_range(10, 26)):
			_px(img, int(p.x), int(p.y), Color("2a1430") if s2 % 3 != 0 else Color("5a2a6a"))
			if s2 % 5 == 2:
				_px(img, int(p.x) + 1, int(p.y) - 1, Color("8e62e0"))
			dir = dir.rotated(rng.randf_range(-0.5, 0.5))
			p += dir


## 1-5 · Clairière aux fougères : un rai de lune tombe au milieu, là où le Cerf apparaît.
static func _moonbeam(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		var t := float(y) / float(h)
		var cx := lerpf(float(w) * 0.7, float(w) * 0.5, t)
		var half := lerpf(float(w) * 0.04, float(w) * 0.16, t)
		for x in range(int(cx - half), int(cx + half)):
			var edge := 1.0 - absf(float(x) - cx) / half
			_px(img, x, y, Color(0.75, 0.8, 1.0, 0.07 * edge))


static func _ferns(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for i in range(16):
		var left := i % 2 == 0
		var base := Vector2(rng.randf_range(0.0, w * 0.3) if left else rng.randf_range(w * 0.7, float(w)), float(h) + 2.0)
		if i >= 12:
			base = Vector2(rng.randf_range(w * 0.2, w * 0.8), h * 0.74)
		var ang := rng.randf_range(-PI * 0.8, -PI * 0.55) if not left else rng.randf_range(-PI * 0.45, -PI * 0.2)
		var ln := rng.randf_range(h * 0.12, h * 0.3) * (0.4 if i >= 12 else 1.0)
		var col := Color("2a5a36") if rng.randf() < 0.5 else Color("3f7a4a")
		var p := base
		var d := Vector2.from_angle(ang)
		for k in range(int(ln)):
			_px(img, int(p.x), int(p.y), col.darkened(0.2))
			if k % 2 == 0:
				var leaf := maxi(1, int((1.0 - float(k) / ln) * 5.0))
				var n := d.orthogonal()
				for q in range(1, leaf + 1):
					_px(img, int(p.x + n.x * q), int(p.y + n.y * q + q * 0.4), col)
					_px(img, int(p.x - n.x * q), int(p.y - n.y * q + q * 0.4), col.lightened(0.1))
			d = d.rotated(0.025 if left else -0.025)
			p += d


## 1-6 · Le cercle des fées : un anneau de champignons lumineux sur la mousse.
static func _fairy_ring(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var c := Vector2(w * 0.5, h * 0.75)
	var rx := w * 0.2
	var ry := h * 0.045
	for y in range(int(c.y - ry * 2.0), int(c.y + ry * 2.0)):
		for x in range(int(c.x - rx * 1.3), int(c.x + rx * 1.3)):
			var d := pow((float(x) - c.x) / rx, 2.0) + pow((float(y) - c.y) / ry, 2.0)
			if d < 1.2:
				_px(img, x, y, Color(1.0, 0.6, 0.9, 0.08 * (1.2 - d)))
	for i in range(16):
		var a := float(i) / 16.0 * TAU
		var mx := int(c.x + cos(a) * rx)
		var my := int(c.y + sin(a) * ry)
		var cap := 2 if i % 3 != 0 else 3
		img.fill_rect(Rect2i(mx, my - 2, 1, 3), Color("e8dcc0"))
		for dx in range(-cap, cap + 1):
			_px(img, mx + dx, my - 3, Color("f7a8e0"))
		_px(img, mx, my - 4, Color("ffd8f4"))
		_px(img, mx - 1, my - 3, Color("ffffff"))
	_fireflies(img, rng, 14, int(h * 0.62), int(h * 0.74), Color("ffb8f0"))


static func _village(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var base := int(h * 0.78)
	var x := int(w * 0.18)
	while x < int(w * 0.84):
		var hw := rng.randi_range(18, 30)
		var hh := rng.randi_range(12, 19)
		img.fill_rect(Rect2i(x, base - hh, hw, hh), Color("2a2238"))
		img.fill_rect(Rect2i(x + hw - 2, base - hh, 2, hh), Color("3a3050"))
		for r in range(hh / 2 + 3):
			img.fill_rect(Rect2i(x - 2 + r, base - hh - r, maxi(1, hw + 4 - r * 2), 1), Color("3a2030") if r > 0 else Color("4a2a3a"))
		var wx := x + hw / 2 - 2
		img.fill_rect(Rect2i(wx, base - hh + 4, 4, 4), Color("f2c46b"))
		img.fill_rect(Rect2i(wx + 1, base - hh + 4, 1, 4), Color("c8902a"))
		img.fill_rect(Rect2i(x + 3, base - 7, 4, 7), Color("1a1426"))
		for gy in range(-3, 4):
			for gx in range(-3, 6):
				_px(img, wx + gx, base - hh + 4 + gy, Color(1.0, 0.75, 0.35, 0.06))
		x += hw + rng.randi_range(6, 14)
	# Fumée violette : le Surge frappe.
	for i in range(5):
		var p := Vector2(rng.randf_range(w * 0.2, w * 0.8), float(base - 14))
		for s in range(40):
			_px(img, int(p.x), int(p.y), Color(0.75, 0.4, 1.0, 0.25))
			p += Vector2(rng.randf_range(-0.6, 0.9), -1.0)


static func _pond(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var cx := w / 2
	var cy := int(h * 0.84)
	var rx := int(w * 0.3)
	var ry := int(h * 0.08)
	for y in range(-ry, ry + 1):
		var half := int(float(rx) * sqrt(maxf(0.0, 1.0 - float(y * y) / float(ry * ry))))
		img.fill_rect(Rect2i(cx - half, cy + y, half * 2, 1), Color("1f5a66").lerp(Color("2f8f9a"), float(y + ry) / float(ry * 2)))
	for i in range(30):
		_px(img, cx + rng.randi_range(-rx + 4, rx - 4), cy + rng.randi_range(-ry + 2, ry - 2), Color("9ff0ff"))


static func _bridge(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var y := int(h * 0.66)
	var x0 := int(w * 0.08)
	var x1 := int(w * 0.92)
	var arch := (x1 - x0) / 3
	# Tablier, parapet et arches de pierre.
	img.fill_rect(Rect2i(x0, y, x1 - x0, 9), Color("5a5670"))
	img.fill_rect(Rect2i(x0, y, x1 - x0, 1), Color("8a86a0"))
	for k in range(3):
		var ax := x0 + arch * k + arch / 2
		var rx := arch / 2 - 3
		for yy in range(y + 9, mini(h, y + 9 + rx)):
			var dy := yy - (y + 9)
			var half := int(sqrt(maxf(0.0, float(rx * rx - dy * dy))))
			img.fill_rect(Rect2i(ax - arch / 2, yy, arch, 1), Color("4a4660"))
			img.fill_rect(Rect2i(ax - half, yy, half * 2, 1), Color("141228"))
	for px in range(x0, x1, 7):
		img.fill_rect(Rect2i(px, y - 5, 2, 5), Color("6a6680"))
	img.fill_rect(Rect2i(x0, y - 5, x1 - x0, 1), Color("8a86a0"))
	for i in range(int(w / 8.0)):
		_px(img, rng.randi_range(x0, x1), y - rng.randi_range(0, 1), Color("4f7a3a"))


## Nexus : cristal corrompu en losange, avec halo.
static func _crystal(img: Image, cx: int, cy: int, r: int) -> void:
	for rr in range(r * 2, r, -1):
		_disc(img, cx, cy, rr, Color(0.85, 0.24, 0.95, 0.03))
	for y in range(-r * 2, r * 2 + 1):
		var half := int(float(r) * (1.0 - absf(float(y)) / float(r * 2)))
		for x in range(-half, half + 1):
			var c := Color("5a2a7a") if x < 0 else Color("b07cff")
			if absi(x) <= 1 or absi(y) <= 0:
				c = Color("ffb0ff")
			_px(img, cx + x, cy + y, c)


static func _fracture(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_sky(img, rng, [[0.0, Color("020208")], [0.5, Color("140c30")], [1.0, Color("2a1448")]], 1.4)
	# La déchirure : un éclair figé dans le ciel.
	var p := Vector2(w * 0.05, h * 0.1)
	var pts: Array[Vector2] = [p]
	while p.x < w * 0.95:
		p += Vector2(rng.randf_range(w * 0.05, w * 0.1), rng.randf_range(-h * 0.02, h * 0.07))
		pts.append(p)
	var glow_r := maxi(8, int(h * 0.07))
	for pass_i in range(2):
		for i in range(pts.size() - 1):
			var a := pts[i]
			var b := pts[i + 1]
			var n := int(a.distance_to(b))
			for st in range(n):
				var q := a.lerp(b, float(st) / float(maxi(1, n)))
				if pass_i == 0:
					for gy in range(-glow_r, glow_r + 1, 2):
						_px(img, int(q.x), int(q.y) + gy, Color(0.75, 0.3, 1.0, 0.05 * (1.0 - absf(float(gy)) / float(glow_r))))
					continue
				_px(img, int(q.x), int(q.y) - 2, Color("d93cf2"))
				_px(img, int(q.x), int(q.y) - 1, Color("e0b0ff"))
				_px(img, int(q.x), int(q.y), Color("ffffff"))
				_px(img, int(q.x), int(q.y) + 1, Color("ffffff"))
				_px(img, int(q.x), int(q.y) + 2, Color("b07cff"))
	# Fissures secondaires.
	for i in range(1, pts.size() - 1):
		var q := pts[i]
		var dir := Vector2(rng.randf_range(-0.6, 0.6), 1.0 if rng.randf() < 0.6 else -1.0).normalized()
		for st in range(rng.randi_range(int(h * 0.05), int(h * 0.12))):
			_px(img, int(q.x), int(q.y), Color("d98cff"))
			q += dir + Vector2(rng.randf_range(-0.4, 0.4), 0.0)
	# Éclats qui tombent.
	for i in range(int(w / 6.0)):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(int(h * 0.2), int(h * 0.7))
		for s in range(rng.randi_range(2, 5)):
			_px(img, x + s / 2, y + s, Color(0.85, 0.6, 1.0, 0.7 - 0.12 * s))
	_ridge(img, rng, int(h * 0.72), int(h * 0.05), Color("120c26"), Color("3a2a6a"))
	var castle := WorldArt.castle_image()
	var cx := int(w * 0.5) - castle.get_width() / 2
	var cy := int(h * 0.8) - castle.get_height()
	img.blend_rect(castle, Rect2i(Vector2i.ZERO, castle.get_size()), Vector2i(cx, cy))
	_ridge(img, rng, int(h * 0.84), int(h * 0.03), Color("0a0818"), Color("2a1e4a"))


static func _surge(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_sky(img, rng, [[0.0, Color("04050f")], [0.5, Color("1d1a48")], [1.0, Color("2d2c5e")]])
	_moon(img, int(w * 0.2), int(h * 0.12), maxi(5, int(minf(w, h) * 0.04)))
	_ridge(img, rng, int(h * 0.55), int(h * 0.05), Color("1f1e48"), Color("3a3a78"))
	img.fill_rect(Rect2i(0, int(h * 0.62), w, h - int(h * 0.62)), Color("181a34"))
	# Vagues de magie brute.
	for band in range(5):
		var by := h * (0.3 + 0.1 * float(band))
		var col := Color("b07cff") if band % 2 == 0 else Color("4fe3d2")
		var amp := h * 0.03 + float(band) * 1.5
		var ph := rng.randf_range(0.0, TAU)
		for x in range(w):
			var y := by + sin(float(x) * 0.05 + ph) * amp + sin(float(x) * 0.013 + ph * 2.0) * amp * 0.8
			for t in range(4):
				_px(img, x, int(y) + t, Color(col, 0.5 - 0.11 * t))
			if rng.randf() < 0.04:
				_px(img, x, int(y) - 2, Color("ffffff"))
	_fireflies(img, rng, int(w / 4.0), int(h * 0.25), h - 2, Color("d98cff"))


static func _tour(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var bd := WorldArt.backdrop(Vector2i(w, h)).get_image()
	img.blit_rect(bd, Rect2i(0, 0, w, h), Vector2i.ZERO)
	_ridge(img, rng, int(h * 0.74), int(h * 0.04), Color("121230"), Color("2a2a5c"))
	for i in range(8):
		_pine(img, rng.randi_range(-4, w + 4), h + rng.randi_range(0, 8), rng.randi_range(int(h * 0.25), int(h * 0.4)), Color("0e1828"), Color("24365a"))
	_fireflies(img, rng, int(w / 10.0), int(h * 0.6), h - 2, Color("f2e28b"))


## Collines d'Ambre à l'aube : champs dorés, fumées de deux camps à l'horizon.
static func _collines(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_sky(img, rng, [[0.0, Color("1a1438")], [0.45, Color("5a3a6a")], [0.7, Color("e08a5a")], [1.0, Color("f2c46b")]], 0.4)
	_disc(img, int(w * 0.5), int(h * 0.66), int(minf(w, h) * 0.08), Color("ffe0a0"))
	_ridge(img, rng, int(h * 0.62), int(h * 0.05), Color("6a3a4a"), Color("a86a5a"))
	_ridge(img, rng, int(h * 0.72), int(h * 0.05), Color("8a5a2b"), Color("c89a3a"))
	_ridge(img, rng, int(h * 0.82), int(h * 0.04), Color("6a4a2a"), Color("e8c870"))
	for side in [0.18, 0.82]:
		var p := Vector2(w * side, h * 0.66)
		for s in range(int(h * 0.3)):
			_px(img, int(p.x), int(p.y), Color(0.3, 0.25, 0.3, 0.45))
			p += Vector2(rng.randf_range(-0.5, 0.8), -1.0)
	for i in range(w):
		_px(img, rng.randi_range(0, w - 1), rng.randi_range(int(h * 0.82), h - 1), Color("f6e6a0"))


# ---------------------------------------------------------------- acte 2 · Collines d'Ambre

## Collines d'Ambre et variantes : steppe, moulins, campement (crépuscule), orage, traite (village et
## campement face à face), fort (palissade de Gharok sous l'orage).
static func _ambre(img: Image, rng: RandomNumberGenerator, kind: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var storm := kind in ["orage", "fort"]
	if storm:
		_sky(img, rng, [[0.0, Color("140f22")], [0.4, Color("33264a")], [0.62, Color("5e4258")], [1.0, Color("7a5034")]], 0.0)
	elif kind in ["campement", "rebouteux"]:
		_sky(img, rng, [[0.0, Color("232454")], [0.42, Color("7a4458")], [0.62, Color("e0844a")], [1.0, Color("c8703a")]], 0.3)
	else:
		_sky(img, rng, [[0.0, Color("3f86c8")], [0.42, Color("8ec4e8")], [0.6, Color("f0d8a0")], [1.0, Color("c89858")]], 0.0)
	if storm:
		# Nuages bas et éclairs.
		for i in range(int(w / 14.0)):
			var cy := rng.randi_range(0, int(h * 0.3))
			var cx := rng.randi_range(-30, w)
			for dx in range(rng.randi_range(30, 80)):
				_px(img, cx + dx, cy + int(sin(float(dx) * 0.2) * 2.0), Color(0.1, 0.08, 0.16, 0.55))
		for bolt in range(3):
			var p := Vector2(rng.randf_range(w * 0.15, w * 0.85), 0.0)
			while p.y < h * 0.55:
				_px(img, int(p.x), int(p.y), Color("fff6a8"))
				_px(img, int(p.x) + 1, int(p.y), Color(0.95, 0.85, 0.3, 0.5))
				p += Vector2(rng.randf_range(-1.6, 1.6), 1.0)
	elif kind not in ["campement", "rebouteux"]:
		var sr := maxi(5, int(minf(w, h) * 0.06))
		var sx := int(w * 0.78)
		var sy := int(h * 0.14)
		for r in range(sr * 3, sr, -1):
			_disc(img, sx, sy, r, Color(1.0, 0.95, 0.75, 0.04))
		_disc(img, sx, sy, sr, Color("fff6d8"))
		for i in range(int(w / 40.0) + 2):
			var cy := rng.randi_range(int(h * 0.05), int(h * 0.32))
			var cx := rng.randi_range(-30, w)
			var len := rng.randi_range(24, 70)
			for k in range(3):
				for dx in range(k * 5, len - k * 5):
					_px(img, cx + dx, cy + k * 2, Color(1, 1, 1, 0.55 - 0.12 * float(k)))
	else:
		_disc(img, int(w * 0.3), int(h * 0.6), int(minf(w, h) * 0.07), Color("ffb070"))
	var far := Color("4a3a5a") if storm else (Color("6a4a6a") if kind in ["campement", "rebouteux"] else Color("8aa0b8"))
	var mid := Color("6a4a2a") if storm else Color("b07a40")
	var near := Color("4a3420") if storm else Color("8a5a2a")
	_ridge(img, rng, int(h * 0.42), int(h * 0.05), far, far.lightened(0.2))
	_ridge(img, rng, int(h * 0.52), int(h * 0.05), mid, mid.lightened(0.3))
	var mid_y := int(h * 0.52)
	match kind:
		"moulins":
			for k in range(3):
				_windmill(img, int(w * (0.2 + 0.3 * float(k))), mid_y - 2 + k * 3, int(h * (0.14 + 0.03 * float(k))), rng.randf() * PI)
		"campement":
			for k in range(6):
				_tent(img, int(w * (0.1 + 0.16 * float(k))) + rng.randi_range(-6, 6), mid_y + rng.randi_range(2, 10), rng.randi_range(10, 16))
			_fire(img, rng, int(w * 0.52), mid_y + 14)
		"orage":
			for k in range(4):
				_totem(img, int(w * (0.18 + 0.22 * float(k))), mid_y + rng.randi_range(0, 8), int(h * 0.12))
		"traite":
			var x := int(w * 0.04)
			while x < int(w * 0.42):
				var hw := rng.randi_range(10, 16)
				var hh := rng.randi_range(8, 12)
				img.fill_rect(Rect2i(x, mid_y + 6 - hh, hw, hh), Color("d8c8a8"))
				for r in range(hh / 2 + 2):
					img.fill_rect(Rect2i(x - 1 + r, mid_y + 6 - hh - r, maxi(1, hw + 2 - r * 2), 1), Color("a8462a"))
				img.fill_rect(Rect2i(x + hw / 2 - 1, mid_y + 6 - hh / 2, 3, 3), Color("f2c46b"))
				x += hw + rng.randi_range(4, 8)
			_banner(img, int(w * 0.44), mid_y + 6, int(h * 0.16), Color("2f4f8f"))
			for k in range(4):
				_tent(img, int(w * (0.62 + 0.1 * float(k))), mid_y + 6, rng.randi_range(10, 14))
			_banner(img, int(w * 0.56), mid_y + 6, int(h * 0.16), Color("a82a2a"))
			for side in [0.24, 0.76]:
				var p := Vector2(w * side, float(mid_y - 6))
				for st in range(int(h * 0.25)):
					_px(img, int(p.x), int(p.y), Color(0.35, 0.3, 0.3, 0.4))
					p += Vector2(rng.randf_range(-0.5, 0.9), -1.0)
		"fort":
			var top := mid_y - int(h * 0.1)
			for x in range(int(w * 0.12), int(w * 0.88)):
				var ph := int(h * 0.1) + (2 if x % 5 == 0 else 0)
				img.fill_rect(Rect2i(x, mid_y + 4 - ph, 1, ph), Color("3a2a1e") if x % 5 != 0 else Color("2a1e16"))
			img.fill_rect(Rect2i(int(w * 0.46), top - int(h * 0.1), int(w * 0.08), int(h * 0.2) + 4), Color("2a1e16"))
			for k in range(3):
				_banner(img, int(w * (0.25 + 0.25 * float(k))), top + 2, int(h * 0.14), Color("a82a2a"))
			_glow_px(img, int(w * 0.5), top - int(h * 0.06), 6, Color("d93cf2"), 0.25)
		"route":
			# Chariots renversés sur la route, et la colonne de fumée noire au loin.
			for k in range(2):
				var cx2 := int(w * (0.3 + 0.38 * float(k)))
				var cy2 := mid_y + 10 + k * 4
				img.fill_rect(Rect2i(cx2 - 12, cy2 - 7, 24, 7), Color("4a3020"))
				img.fill_rect(Rect2i(cx2 - 10, cy2 - 9, 20, 2), Color("6a4a2a"))
				for wx: int in [cx2 - 7, cx2 + 8]:
					_disc(img, wx, cy2, 4, Color("2a1e14"))
					_disc(img, wx, cy2, 2, Color("6a4a2a"))
			var sp := Vector2(w * 0.62, float(mid_y - 2))
			for st in range(int(h * 0.46)):
				var r2 := 2 + st / 9
				_disc(img, int(sp.x), int(sp.y), r2, Color(0.14, 0.11, 0.12, 0.08))
				sp += Vector2(rng.randf_range(-0.2, 0.7), -1.0)
		"pylones":
			# La crête des pylônes : de grands cristaux d'ambre, la foudre court de l'un à l'autre.
			var tops: Array[Vector2i] = []
			for k in range(5):
				var cx3 := int(w * (0.1 + 0.2 * float(k))) + rng.randi_range(-6, 6)
				var cy3 := mid_y + rng.randi_range(-2, 6)
				var ch := rng.randi_range(int(h * 0.1), int(h * 0.17))
				for y in range(ch):
					var half := int(float(ch - y) * 0.18) + 1
					for dx in range(-half, half + 1):
						_px(img, cx3 + dx, cy3 - y, Color("ffd070") if dx > 0 else (Color("fff0b0") if dx == 0 else Color("c8702a")))
				_glow_px(img, cx3, cy3 - ch / 2, 10, Color("ffc060"), 0.22)
				tops.append(Vector2i(cx3, cy3 - ch + 2))
			for k in range(tops.size() - 1):
				var a := Vector2(tops[k])
				var b := Vector2(tops[k + 1])
				for q in range(24):
					var f := float(q) / 23.0
					var p := a.lerp(b, f) + Vector2(0.0, rng.randf_range(-3.0, 3.0) - sin(f * PI) * 6.0)
					_px(img, int(p.x), int(p.y), Color("fff6c0"))
		"gue":
			# Le gué de la Rivière-Sèche : un lit de galets clairs qui serpente, des totems sur l'autre rive.
			for y in range(mid_y + 2, int(h * 0.8)):
				var f2 := float(y - mid_y) / (h * 0.3)
				var cx4 := int(w * 0.5 + sin(f2 * 3.0) * w * 0.15)
				var half2 := int(4.0 + f2 * w * 0.16)
				for dx in range(-half2, half2 + 1):
					_px(img, cx4 + dx, y, Color("d8c8a0") if (dx + y) % 4 else Color("a89878"))
			for k in range(4):
				_totem(img, int(w * (0.12 + 0.25 * float(k))), mid_y + 2, int(h * 0.08))
		"caravane":
			# La route qui serpente vers Ambreval, le chariot de vivres, les moulins au loin.
			for y in range(mid_y, int(h * 0.82)):
				var f3 := float(y - mid_y) / (h * 0.3)
				var cx5 := int(w * 0.5 + sin(f3 * 2.2 + 1.0) * w * 0.1)
				var half3 := int(2.0 + f3 * w * 0.1)
				img.fill_rect(Rect2i(cx5 - half3, y, half3 * 2, 1), Color("b8945a"))
			for k in range(2):
				_windmill(img, int(w * (0.15 + 0.7 * float(k))), mid_y - 2, int(h * 0.12), rng.randf() * PI)
			var wx2 := int(w * 0.46)
			var wy := mid_y + int(h * 0.09)
			img.fill_rect(Rect2i(wx2 - 10, wy - 12, 20, 7), Color("f0e8d8"))
			img.fill_rect(Rect2i(wx2 - 11, wy - 6, 22, 5), Color("6a4a2a"))
			for wx3: int in [wx2 - 7, wx2 + 7]:
				_disc(img, wx3, wy, 3, Color("2a1e14"))
		"rebouteux":
			# Le campement de la rebouteuse : sa hutte ronde, des tentes, une fumée verte qui monte.
			for k in range(4):
				_tent(img, int(w * (0.08 + 0.22 * float(k))) + rng.randi_range(-6, 6), mid_y + rng.randi_range(4, 10), rng.randi_range(10, 14))
			var hx := int(w * 0.55)
			for y in range(14):
				var half4 := int(sqrt(maxf(0.0, 196.0 - float(14 - y) * float(14 - y))) * 1.1)
				img.fill_rect(Rect2i(hx - half4, mid_y + 6 - 14 + y, half4 * 2, 1), Color("6a5a3a") if y % 3 else Color("8a7a4a"))
			img.fill_rect(Rect2i(hx - 2, mid_y - 2, 4, 8), Color("1a1410"))
			var sp2 := Vector2(float(hx), float(mid_y - 10))
			for st2 in range(int(h * 0.3)):
				_disc(img, int(sp2.x), int(sp2.y), 2 + st2 / 12, Color(0.55, 0.8, 0.45, 0.06))
				sp2 += Vector2(rng.randf_range(-0.6, 0.6), -1.0)
			_fire(img, rng, int(w * 0.3), mid_y + 14)
		"steppe":
			for k in range(3):
				var cx := int(w * (0.15 + 0.35 * float(k))) + rng.randi_range(-8, 8)
				var cy := mid_y + rng.randi_range(0, 6)
				for y in range(10):
					var half := 3 - absi(y - 4) / 2
					for dx in range(-half, half + 1):
						_px(img, cx + dx, cy - 10 + y, Color("ffd070") if dx > 0 else Color("e8a33d"))
				_glow_px(img, cx, cy - 6, 6, Color("ffd070"), 0.2)
	_ridge(img, rng, int(h * 0.66), int(h * 0.03), near, near.lightened(0.35))
	# Herbe haute au premier plan.
	var grass := [Color("e8c870"), Color("c8a048"), Color("a88a3a")]
	if storm:
		grass = [Color("8a7a4a"), Color("6a5a3a"), Color("5a4a2a")]
	for i in range(w * 2):
		var x := rng.randi_range(0, w - 1)
		var base := rng.randi_range(int(h * 0.72), h + 2)
		var len := rng.randi_range(3, 9)
		var lean := rng.randf_range(0.2, 0.6)
		for k in range(len):
			_px(img, x + int(float(k) * lean), base - k, grass[i % 3])


static func _glow_px(img: Image, cx: int, cy: int, r: int, c: Color, a: float) -> void:
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			var d := Vector2(x, y).length()
			if d <= float(r):
				_px(img, cx + x, cy + y, Color(c, a * (1.0 - d / float(r + 1))))


static func _windmill(img: Image, x: int, base: int, hgt: int, rot: float) -> void:
	for y in range(hgt):
		var half := 2 + int(float(y) * 0.18)
		img.fill_rect(Rect2i(x - half, base - hgt + y, half * 2 + 1, 1), Color("d8c8a8") if y % 6 != 0 else Color("b8a888"))
	var hub := Vector2(x, base - hgt)
	for k in range(4):
		var a := rot + float(k) * PI * 0.5
		var tip := hub + Vector2(cos(a), sin(a)) * float(hgt) * 0.75
		var n := int(hub.distance_to(tip))
		for i in range(n):
			var p := hub.lerp(tip, float(i) / float(maxi(1, n)))
			_px(img, int(p.x), int(p.y), Color("5a4030"))
			if i > n / 3:
				_px(img, int(p.x + cos(a + PI * 0.5) * 2.0), int(p.y + sin(a + PI * 0.5) * 2.0), Color("e8dcc0"))
	_px(img, x, base - hgt, Color("2a1e16"))


static func _tent(img: Image, x: int, base: int, hw: int) -> void:
	for y in range(hw):
		var half := int(float(y + 1) * 0.9)
		for dx in range(-half, half + 1):
			_px(img, x + dx, base - hw + y, Color("8a6a3a") if dx < 0 else Color("b08a50"))
	img.fill_rect(Rect2i(x - 1, base - 4, 3, 4), Color("2a1e16"))
	_px(img, x, base - hw - 1, Color("4a3420"))
	_px(img, x - 1, base - hw - 2, Color("4a3420"))
	_px(img, x + 1, base - hw - 2, Color("4a3420"))


static func _banner(img: Image, x: int, base: int, hgt: int, col: Color) -> void:
	img.fill_rect(Rect2i(x, base - hgt, 1, hgt), Color("4a3420"))
	img.fill_rect(Rect2i(x + 1, base - hgt + 1, 6, 8), col)
	_px(img, x + 3, base - hgt + 4, Color("f2c46b"))
	_px(img, x + 4, base - hgt + 4, Color("f2c46b"))


static func _totem(img: Image, x: int, base: int, hgt: int) -> void:
	img.fill_rect(Rect2i(x - 2, base - hgt, 5, hgt), Color("5a3e24"))
	for y in range(base - hgt + 2, base, 5):
		_px(img, x - 1, y, Color("9ff0ff"))
		_px(img, x + 1, y, Color("9ff0ff"))
	_glow_px(img, x, base - hgt - 2, 5, Color("f0d23c"), 0.4)
	_px(img, x, base - hgt - 2, Color("fff6a8"))


static func _fire(img: Image, rng: RandomNumberGenerator, x: int, y: int) -> void:
	_glow_px(img, x, y - 3, 10, Color("ff9b4a"), 0.3)
	for i in range(30):
		var dx := rng.randi_range(-3, 3)
		var dy := rng.randi_range(0, 7 - absi(dx))
		_px(img, x + dx, y - dy, Color("ffd070") if dy < 3 else Color("ff8a3a"))
	var p := Vector2(x, y - 8)
	for st in range(40):
		_px(img, int(p.x), int(p.y), Color(0.3, 0.25, 0.3, 0.35))
		p += Vector2(rng.randf_range(-0.6, 0.8), -1.0)


# ---------------------------------------------------------------- acte 3 · Marais Murmurants

## Marais au crépuscule et variantes : marais (pilotis, lanternes), cercle (saules et braseros de cendre),
## hydre (silhouette dans la brume), refuge (cabanes du Cercle assiégées).
static func _marais(img: Image, rng: RandomNumberGenerator, kind: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_sky(img, rng, [[0.0, Color("1a1628")], [0.38, Color("4a3e62")], [0.55, Color("9c8ab4")], [0.64, Color("c9d1c4")], [1.0, Color("2f3a33")]], 0.5)
	_moon(img, int(w * 0.72), int(h * 0.14), maxi(5, int(minf(w, h) * 0.045)))
	_ridge(img, rng, int(h * 0.44), int(h * 0.03), Color("4a4a5e"), Color("6a6a82"))
	var water := int(h * 0.56)
	var wcol := Color("2a3a24") if kind == "mares" else (Color("1a2228") if kind == "gue_morts" else Color("2a3530"))
	img.fill_rect(Rect2i(0, water, w, h - water), wcol)
	for i in range(int(w * h / 300.0)):
		var y := rng.randi_range(water, h - 1)
		var x := rng.randi_range(0, w - 1)
		for dx in range(rng.randi_range(4, 14)):
			_px(img, x + dx, y, Color(0.6, 0.65, 0.75, 0.12))
	# Saules pleureurs (repoussés sur les bords quand le lieu a quelque chose à montrer au milieu).
	var open_mid := kind in ["pilotis", "mares", "croc", "barque", "sorciere", "gue_morts", "hydre"]
	for i in range(maxi(3, int(w / 45.0)) if not open_mid else 4):
		var tx := rng.randi_range(-10, w + 10)
		if open_mid:
			tx = rng.randi_range(-int(w * 0.12), int(w * 0.12)) + (0 if i % 2 == 0 else w)
		var th := rng.randi_range(int(h * 0.16), int(h * 0.26))
		img.fill_rect(Rect2i(tx - 1, water - th, 3, th), Color("23222a"))
		_disc(img, tx, water - th, int(th * 0.4), Color("2e3d34"))
		for k in range(40):
			var sx := tx + rng.randi_range(-int(th * 0.45), int(th * 0.45))
			var sy := water - th + rng.randi_range(-int(th * 0.2), int(th * 0.15))
			for d in range(rng.randi_range(5, int(th * 0.8))):
				_px(img, sx, sy + d, Color("33463a"))
	match kind:
		"pilotis":
			# Le village sur pilotis : maisons serrées, passerelles de planches, lanternes.
			for i in range(5):
				var hx2 := int(w * (0.04 + 0.2 * float(i))) + rng.randi_range(-4, 4)
				var hb := water - rng.randi_range(2, 8)
				img.fill_rect(Rect2i(hx2, hb - 12, 16, 10), Color("2a2420"))
				for r in range(6):
					img.fill_rect(Rect2i(hx2 - 2 + r, hb - 12 - r, 20 - r * 2, 1), Color("3a3028"))
				for pp in [hx2 + 1, hx2 + 7, hx2 + 14]:
					img.fill_rect(Rect2i(pp, hb - 2, 1, 10), Color("2a2420"))
				_glow_px(img, hx2 + 8, hb - 7, 6, Color("f2c46b"), 0.35)
				_px(img, hx2 + 8, hb - 7, Color("fff0b0"))
				if i < 4:
					img.fill_rect(Rect2i(hx2 + 16, hb - 2, int(w * 0.2) - 16, 1), Color("4a3a28"))
			for i in range(6):
				var lx := rng.randi_range(int(w * 0.05), int(w * 0.95))
				var ly := water + rng.randi_range(6, int(h * 0.2))
				img.fill_rect(Rect2i(lx, ly - 14, 1, 14), Color("2a2018"))
				_glow_px(img, lx, ly - 15, 5, Color("ffc870"), 0.4)
				_px(img, lx, ly - 15, Color("fff0b0"))
		"mares":
			# Mares empoisonnées : bulles vertes, arbres morts, champignons qui luisent.
			for i in range(40):
				var bx2 := rng.randi_range(0, w - 1)
				var by2 := rng.randi_range(water + 2, h - 2)
				_disc(img, bx2, by2, rng.randi_range(1, 2), Color(0.6, 1.0, 0.35, 0.5))
			for i in range(4):
				var tx2 := int(w * (0.1 + 0.27 * float(i)))
				var th2 := rng.randi_range(int(h * 0.12), int(h * 0.2))
				img.fill_rect(Rect2i(tx2 - 1, water - th2, 3, th2 + 4), Color("1e1c22"))
				for b in range(3):
					var p2 := Vector2(tx2, water - th2 + b * 6)
					var dv := Vector2(-1.0 if b % 2 else 1.0, -0.6)
					for st in range(10):
						_px(img, int(p2.x), int(p2.y), Color("1e1c22"))
						p2 += dv
			for i in range(8):
				_glow_px(img, rng.randi_range(0, w - 1), water - rng.randi_range(0, 4), 4, Color("8ae050"), 0.35)
		"brume":
			# La Brume : des saules fantômes à demi effacés, et un mur de brouillard.
			for i in range(int(w * h / 90.0)):
				var y2 := rng.randi_range(int(h * 0.3), h - 1)
				var x2 := rng.randi_range(-60, w)
				for dx in range(rng.randi_range(40, 120)):
					_px(img, x2 + dx, y2, Color(0.85, 0.9, 0.88, 0.09))
		"gue_morts":
			# Le gué des morts : croix et stèles sur la rive, feux follets bleus au-dessus de l'eau noire.
			for i in range(9):
				var gx := int(w * (0.04 + 0.11 * float(i))) + rng.randi_range(-3, 3)
				var gy := water + rng.randi_range(-2, 4)
				var tall := rng.randi_range(8, 14)
				img.fill_rect(Rect2i(gx, gy - tall, 2, tall), Color("3a3a48"))
				if i % 2 == 0:
					img.fill_rect(Rect2i(gx - 3, gy - tall + 3, 8, 2), Color("3a3a48"))
			for i in range(7):
				var wx := rng.randi_range(0, w - 1)
				var wy := water + rng.randi_range(-int(h * 0.1), int(h * 0.12))
				_glow_px(img, wx, wy, 6, Color("8fd8ff"), 0.4)
				_px(img, wx, wy, Color("e8f8ff"))
		"croc":
			# Le repaire du Crocodile-liche : ruines englouties, et sa tête osseuse qui affleure, yeux verts.
			for i in range(3):
				var rx := int(w * (0.15 + 0.35 * float(i)))
				img.fill_rect(Rect2i(rx, water - 16, 6, 18), Color("3a3a44"))
				img.fill_rect(Rect2i(rx - 2, water - 18, 10, 3), Color("4a4a54"))
			var cx3 := int(w * 0.5)
			var cy3 := water - int(h * 0.02)
			for y in range(-6, 4):
				var half := int(float(w) * 0.16 * (1.0 - float(y + 6) / 12.0)) + 4
				img.fill_rect(Rect2i(cx3 - half, cy3 + y, half * 2, 1), Color("c8c0a8") if y < -2 else Color("8a8270"))
			for k in range(-6, 7):
				img.fill_rect(Rect2i(cx3 + k * 4, cy3 + 3, 2, 3), Color("e8e0d0"))
			for e in [-1, 1]:
				_glow_px(img, cx3 + e * int(w * 0.05), cy3 - 4, 6, Color("8ae050"), 0.6)
				_px(img, cx3 + e * int(w * 0.05), cy3 - 4, Color("d8ff8a"))
		"barque":
			# La barque des passeurs sur le chenal, sa lanterne à la proue.
			var bx3 := int(w * 0.5)
			var by3 := water - int(h * 0.01)
			for y in range(5):
				var inset := y
				img.fill_rect(Rect2i(bx3 - int(w * 0.14) + inset, by3 + y, int(w * 0.28) - inset * 2, 1), Color("3a2a1e"))
			img.fill_rect(Rect2i(bx3 + int(w * 0.1), by3 - 14, 1, 14), Color("2a2018"))
			_glow_px(img, bx3 + int(w * 0.1), by3 - 15, 7, Color("ffc870"), 0.45)
			img.fill_rect(Rect2i(bx3 - 8, by3 - 12, 3, 12), Color("1a1820"))
			_disc(img, bx3 - 7, by3 - 14, 2, Color("1a1820"))
			for k in range(4):
				img.fill_rect(Rect2i(int(w * (0.1 + 0.25 * float(k))), water - 4, 1, 12), Color("2a2420"))
		"sorciere":
			# La hutte de la sorcière sur pilotis, fenêtre verte, chaudron qui fume, os qui pendent.
			var hx3 := int(w * 0.62)
			var hb2 := water - 4
			img.fill_rect(Rect2i(hx3, hb2 - 16, 22, 14), Color("2a2420"))
			for r in range(9):
				img.fill_rect(Rect2i(hx3 - 3 + r, hb2 - 16 - r, 28 - r * 2, 1), Color("3a3a2a"))
			for pp2 in [hx3 + 2, hx3 + 10, hx3 + 19]:
				img.fill_rect(Rect2i(pp2, hb2 - 2, 1, 10), Color("2a2420"))
			_glow_px(img, hx3 + 8, hb2 - 10, 7, Color("8ae050"), 0.45)
			img.fill_rect(Rect2i(hx3 + 6, hb2 - 12, 4, 4), Color("c8ff8a"))
			for k in range(4):
				img.fill_rect(Rect2i(hx3 + 2 + k * 6, hb2 - 2, 1, 4 + k % 2 * 2), Color("d8d0c0"))
			var kx := int(w * 0.28)
			_disc(img, kx, water + 6, 6, Color("1a1a20"))
			_glow_px(img, kx, water + 10, 8, Color("ff8a3a"), 0.4)
			var sp3 := Vector2(float(kx), float(water))
			for st2 in range(int(h * 0.3)):
				_disc(img, int(sp3.x), int(sp3.y), 2 + st2 / 14, Color(0.55, 0.85, 0.45, 0.06))
				sp3 += Vector2(rng.randf_range(-0.6, 0.6), -1.0)
		"marais":
			for i in range(3):
				var hx := int(w * (0.18 + 0.32 * float(i)))
				img.fill_rect(Rect2i(hx, water - 14, 18, 10), Color("2a2420"))
				for r in range(6):
					img.fill_rect(Rect2i(hx - 2 + r, water - 14 - r, 22 - r * 2, 1), Color("3a3028"))
				for p in [hx + 1, hx + 8, hx + 16]:
					img.fill_rect(Rect2i(p, water - 4, 1, 8), Color("2a2420"))
				_glow_px(img, hx + 9, water - 9, 6, Color("f2c46b"), 0.35)
				_px(img, hx + 9, water - 9, Color("fff0b0"))
		"cercle", "refuge":
			# Cercle de pierres et braseros de cendre.
			var cx := int(w * 0.5)
			var cy := water - 2
			for k in range(7):
				var a := PI + float(k) * PI / 6.0
				var px := cx + int(cos(a) * w * 0.34)
				var py := cy + int(sin(a) * h * 0.06)
				img.fill_rect(Rect2i(px - 2, py - 10, 5, 10), Color("4a4a52"))
				if k % 2 == 0:
					_glow_px(img, px, py - 13, 6, Color("ff8a3a"), 0.4)
					_px(img, px, py - 13, Color("ffd070"))
			if kind == "refuge":
				for k in range(5):
					var p := Vector2(rng.randf_range(w * 0.15, w * 0.85), float(water - 12))
					for st in range(30):
						_px(img, int(p.x), int(p.y), Color(0.75, 0.4, 1.0, 0.25))
						p += Vector2(rng.randf_range(-0.6, 0.9), -1.0)
		"hydre":
			# Silhouette de l'hydre dans la brume : un corps, cinq cous.
			var bx := int(w * 0.5)
			_disc(img, bx, water + 2, int(w * 0.16), Color("1e2a22"))
			for k in range(5):
				var a := -PI * 0.5 + (float(k) - 2.0) * 0.38
				var p := Vector2(bx, water - 2)
				for st in range(int(h * 0.22)):
					var wv := sin(float(st) * 0.15 + float(k)) * 0.6
					p += Vector2(cos(a) + wv, sin(a))
					_disc(img, int(p.x), int(p.y), 2, Color("1e2a22"))
				_disc(img, int(p.x), int(p.y), 4, Color("1e2a22"))
				_px(img, int(p.x) + 1, int(p.y) - 1, Color("f0d23c"))
	# Brume au ras de l'eau.
	for i in range(int(w * h / 500.0)):
		var y := rng.randi_range(int(h * 0.45), h - 1)
		var x := rng.randi_range(-40, w)
		for dx in range(rng.randi_range(30, 100)):
			_px(img, x + dx, y, Color(0.8, 0.85, 0.82, 0.1))
	_fireflies(img, rng, int(w / 14.0), int(h * 0.4), h - 2, Color("a8e070"))


# ---------------------------------------------------------------- acte 4 · Pics Gelés

## Pic enneigé : un triangle de roche, sa calotte de neige, le flanc droit éclairé.
static func _peak(img: Image, cx: int, base: int, hw: int, hgt: int, body: Color, snow: Color) -> void:
	for y in range(base - hgt, base):
		var k := float(y - (base - hgt)) / float(maxi(1, hgt))
		var half := int(float(hw) * k)
		for dx in range(-half, half + 1):
			var c := body
			if k < 0.32 + 0.06 * sin(float(dx) * 0.7):
				c = snow if dx <= half / 3 else snow.darkened(0.18)
			elif dx > half * 2 / 3:
				c = body.lightened(0.12)
			_px(img, cx + dx, y, c)


static func _snowfall(img: Image, rng: RandomNumberGenerator, n: int) -> void:
	for i in range(n):
		var x := rng.randi_range(0, img.get_width() - 1)
		var y := rng.randi_range(0, img.get_height() - 1)
		_px(img, x, y, Color(1, 1, 1, rng.randf_range(0.35, 0.9)))
		if rng.randf() < 0.3:
			_px(img, x + 1, y, Color(1, 1, 1, 0.3))


## Rune lumineuse : une petite croix gravée et son halo.
static func _rune(img: Image, x: int, y: int, col: Color) -> void:
	_glow_px(img, x, y, 5, col, 0.4)
	for d in [Vector2i(0, -2), Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(-1, -1), Vector2i(1, 1)]:
		_px(img, x + d.x, y + d.y, col.lightened(0.35))


## Pics Gelés et leurs variantes : pics (route du col), porte (Porte naine), lac (lac gelé sous l'aurore),
## forteresse (les Portes scellées de Forgecœur), colosse (la salle du Cœur).
static func _pics(img: Image, rng: RandomNumberGenerator, kind: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	if kind == "colosse":
		_colosse(img, rng)
		return
	_sky(img, rng, [[0.0, Color("0c1226")], [0.4, Color("1e3458")], [0.62, Color("6a8ab0")], [0.75, Color("c8dcec")], [1.0, Color("e8f2fa")]], 0.9)
	if kind in ["lac", "aurore"]:
		# Aurore boréale : rubans verts et violets qui ondulent.
		for band in range(3):
			var col := Color("5ff0a8") if band != 1 else Color("b07cff")
			var y0 := h * (0.1 + 0.07 * float(band))
			for x in range(w):
				var yy := int(y0 + sin(float(x) * 0.035 + float(band) * 1.7) * h * 0.05)
				for d in range(int(h * 0.12)):
					_px(img, x, yy + d, Color(col, 0.16 * (1.0 - float(d) / (h * 0.12))))
	else:
		_moon(img, int(w * 0.78), int(h * 0.13), maxi(5, int(minf(w, h) * 0.04)))
	# Chaîne de pics au loin, puis au premier plan.
	for i in range(maxi(4, int(w / 70.0))):
		_peak(img, rng.randi_range(-20, w + 20), int(h * 0.56), rng.randi_range(int(w * 0.12), int(w * 0.2)), rng.randi_range(int(h * 0.22), int(h * 0.36)), Color("3a4a6a"), Color("dceaf6"))
	for i in range(maxi(3, int(w / 110.0))):
		_peak(img, rng.randi_range(-30, w + 30), int(h * 0.66), rng.randi_range(int(w * 0.14), int(w * 0.24)), rng.randi_range(int(h * 0.18), int(h * 0.3)), Color("2a3450"), Color("f0f6ff"))
	var ground := int(h * 0.64)
	img.fill_rect(Rect2i(0, ground, w, h - ground), Color("dfe9f4"))
	for i in range(int(w * h / 260.0)):
		_px(img, rng.randi_range(0, w - 1), rng.randi_range(ground, h - 1), Color("b8c8dc"))
	match kind:
		"pics":
			# Route du col en lacets, sapins enneigés.
			var p := Vector2(w * 0.15, h - 1)
			for st in range(int(h * 0.5)):
				var t := float(st) / (h * 0.5)
				p = Vector2(w * (0.5 + 0.3 * sin(t * 5.0)) , h - 1 - st * 0.75)
				for dx in range(-int(6.0 - 4.0 * t), int(6.0 - 4.0 * t) + 1):
					_px(img, int(p.x) + dx, int(p.y), Color("9aa8bc"))
			for i in range(maxi(4, int(w / 40.0))):
				var tx := rng.randi_range(0, w)
				if absf(float(tx) - w * 0.5) < w * 0.12:
					continue
				var th := rng.randi_range(int(h * 0.1), int(h * 0.2))
				var base := rng.randi_range(ground + 4, h - 2)
				_pine(img, tx, base, th, Color("1e3a3a"), Color("cfe8f0"))
				_px(img, tx, base - th, Color("ffffff"))
		"porte":
			# Falaise et arche naine aux runes vivantes.
			var cx := int(w * 0.5)
			# Falaise : sommet déchiqueté, strates et fissures.
			var ctop := float(h) * 0.24
			var cslope := 0.0
			for x in range(int(w * 0.16), int(w * 0.84)):
				cslope = clampf(cslope + rng.randf_range(-0.5, 0.5), -1.2, 1.2)
				ctop = clampf(ctop + cslope, h * 0.16, h * 0.3)
				var edge := minf(float(x) - w * 0.16, w * 0.84 - float(x))
				var top_y := int(ctop + maxf(0.0, w * 0.06 - edge) * 1.5)
				img.fill_rect(Rect2i(x, top_y, 1, ground - top_y), Color("2a3048"))
				_px(img, x, top_y, Color("dceaf6"))
				_px(img, x, top_y + 1, Color("9aa8c0"))
			for i in range(int(w * h / 700.0)):
				var rx := rng.randi_range(int(w * 0.18), int(w * 0.82))
				var ry := rng.randi_range(int(h * 0.3), ground - 2)
				for d in range(rng.randi_range(3, 9)):
					_px(img, rx + d, ry + (d / 3), Color("222840"))
			var aw := int(w * 0.17)
			var top := int(h * 0.3)
			for y in range(top, ground):
				for x in range(cx - aw, cx + aw + 1):
					var nx := float(x - cx) / float(aw)
					var arch_top := top + int(float(aw) * (1.0 - sqrt(maxf(0.0, 1.0 - nx * nx))))
					if y < arch_top:
						continue
					var inner := absf(nx) < 0.72 and y > arch_top + 5
					_px(img, x, y, Color("0e1830") if inner else Color("4a5272"))
			_glow_px(img, cx, int(h * 0.5), int(w * 0.12), Color("ff9a3a"), 0.35)
			for k in range(7):
				var a := PI + float(k) * PI / 6.0
				_rune(img, cx + int(cos(a) * aw * 0.86), top + aw + int(sin(a) * aw * 0.86), Color("ffb050") if k % 2 == 0 else Color("8fe3f2"))
		"col", "chariot":
			# La route du col en lacets entre les sapins ; statues naines qui la gardent ; (chariot) le chariot runique.
			var p := Vector2(w * 0.15, h - 1)
			for st in range(int(h * 0.5)):
				var t := float(st) / (h * 0.5)
				p = Vector2(w * (0.5 + 0.28 * sin(t * 5.0)), h - 1 - st * 0.75)
				for dx in range(-int(6.0 - 4.0 * t), int(6.0 - 4.0 * t) + 1):
					_px(img, int(p.x) + dx, int(p.y), Color("9aa8bc"))
			for k in range(2):
				var sx := int(w * (0.18 + 0.64 * float(k)))
				var sy := ground + int(h * 0.04)
				img.fill_rect(Rect2i(sx - 5, sy - 22, 10, 22), Color("4a5272"))
				_disc(img, sx, sy - 25, 5, Color("5a6282"))
				img.fill_rect(Rect2i(sx - 6, sy - 30, 12, 2), Color("f0f6ff"))
				_px(img, sx - 2, sy - 25, Color("8fe3f2"))
				_px(img, sx + 2, sy - 25, Color("8fe3f2"))
			for i in range(maxi(4, int(w / 40.0))):
				var tx := rng.randi_range(0, w)
				if absf(float(tx) - w * 0.5) < w * 0.14:
					continue
				var th := rng.randi_range(int(h * 0.1), int(h * 0.2))
				var base := rng.randi_range(ground + 4, h - 2)
				_pine(img, tx, base, th, Color("1e3a3a"), Color("cfe8f0"))
			if kind == "chariot":
				var cx := int(w * 0.5)
				var cy := ground + int(h * 0.02)
				img.fill_rect(Rect2i(cx - 14, cy - 10, 28, 9), Color("5a3a22"))
				img.fill_rect(Rect2i(cx - 15, cy - 11, 30, 2), Color("8a8a98"))
				for k2 in range(3):
					_glow_px(img, cx - 8 + k2 * 8, cy - 6, 4, Color("8fe3f2"), 0.5)
					_px(img, cx - 8 + k2 * 8, cy - 6, Color("c8f8ff"))
				for wx: int in [cx - 9, cx + 9]:
					_disc(img, wx, cy, 3, Color("2a2a38"))
		"congeres":
			# Les congères : de grandes vagues de neige figées au-dessus du chemin, prêtes à rompre.
			for k in range(4):
				var cx2 := int(w * (0.1 + 0.27 * float(k)))
				var cy2 := ground - int(h * 0.02)
				var rw := int(w * 0.18)
				for y in range(int(h * 0.1)):
					var half := int(float(rw) * sqrt(maxf(0.0, 1.0 - pow(float(y) / (h * 0.1), 2.0))))
					img.fill_rect(Rect2i(cx2 - half, cy2 - y, half * 2, 1), Color("f4f8ff") if y > 2 else Color("c8d8ec"))
				for d in range(rw):
					_px(img, cx2 - rw / 2 + d, cy2 - int(h * 0.1) + 2 + int(sin(float(d) * 0.3) * 2.0), Color("9ab0cc"))
			for i in range(int(w / 6.0)):
				var gx := rng.randi_range(0, w)
				var gy := rng.randi_range(int(h * 0.2), ground)
				for d in range(rng.randi_range(6, 18)):
					_px(img, gx + d, gy, Color(1, 1, 1, 0.3))
		"sentinelle", "portes":
			# Le seuil de la forteresse : deux grandes portes de pierre, sceaux de givre ; (sentinelle) la statue
			# immense de la Garde, marteau levé.
			var cx3 := int(w * 0.5)
			var wall := int(h * 0.3)
			img.fill_rect(Rect2i(int(w * 0.08), wall, int(w * 0.84), ground - wall), Color("2e3652"))
			var gw := int(w * 0.16)
			img.fill_rect(Rect2i(cx3 - gw, int(h * 0.36), gw * 2, ground - int(h * 0.36)), Color("141c34"))
			img.fill_rect(Rect2i(cx3 - 1, int(h * 0.36), 2, ground - int(h * 0.36)), Color("0a1020"))
			for k in range(6):
				var ry := int(h * 0.4) + k * int(h * 0.035)
				img.fill_rect(Rect2i(cx3 - gw + 4, ry, gw * 2 - 8, 1), Color("8a8a98"))
			for k in range(2):
				var sx2 := cx3 + (-1 if k == 0 else 1) * gw / 2
				_glow_px(img, sx2, int(h * 0.48), int(w * 0.05), Color("4a6aff"), 0.45)
				_px(img, sx2, int(h * 0.48), Color("c8d8ff"))
			if kind == "sentinelle":
				for side: int in [-1, 1]:
					var sx3: int = cx3 + side * int(w * 0.32)
					img.fill_rect(Rect2i(sx3 - 9, int(h * 0.26), 18, ground - int(h * 0.26)), Color("3a4466"))
					_disc(img, sx3, int(h * 0.24), 8, Color("4a5476"))
					_px(img, sx3 - 3, int(h * 0.24), Color("8fe3f2"))
					_px(img, sx3 + 3, int(h * 0.24), Color("8fe3f2"))
					img.fill_rect(Rect2i(sx3 + side * 10, int(h * 0.14), 4, int(h * 0.14)), Color("2a3048"))
					img.fill_rect(Rect2i(sx3 + side * 10 - 6, int(h * 0.12), 16, 8), Color("4a5272"))
		"lac", "aurore":
			# Lac gelé : un miroir bleuté, des silhouettes figées sous la glace.
			var lake := int(h * 0.7)
			img.fill_rect(Rect2i(0, lake, w, h - lake), Color("9ec4dc"))
			for i in range(int(w / 3.0)):
				var x := rng.randi_range(0, w - 1)
				var y := rng.randi_range(lake, h - 1)
				for dx in range(rng.randi_range(6, 24)):
					_px(img, x + dx, y, Color(1, 1, 1, 0.35))
			for k in range(maxi(5, int(w / 50.0))):
				var sx := int(w * (0.08 + 0.86 * float(k) / float(maxi(1, maxi(5, int(w / 50.0)) - 1))))
				var sy := lake + int(h * 0.1) + rng.randi_range(0, int(h * 0.12))
				img.fill_rect(Rect2i(sx - 3, sy - 8, 7, 12), Color(0.22, 0.32, 0.5, 0.55))
				_disc(img, sx, sy - 11, 3, Color(0.22, 0.32, 0.5, 0.55))
		"forteresse":
			# Forteresse taillée dans la montagne : remparts, tours, Portes scellées de givre noirci.
			var cx := int(w * 0.5)
			var wall := int(h * 0.36)
			img.fill_rect(Rect2i(int(w * 0.1), wall, int(w * 0.8), ground - wall), Color("2e3652"))
			for t in [0.14, 0.32, 0.68, 0.86]:
				var tx := int(w * t)
				img.fill_rect(Rect2i(tx - int(w * 0.04), wall - int(h * 0.12), int(w * 0.08), ground - wall + int(h * 0.12)), Color("3a4466"))
				for m in range(3):
					img.fill_rect(Rect2i(tx - int(w * 0.04) + m * int(w * 0.03), wall - int(h * 0.14), int(w * 0.02), int(h * 0.02)), Color("3a4466"))
				_glow_px(img, tx, wall - int(h * 0.06), 4, Color("8fe3f2"), 0.5)
			for x in range(int(w * 0.1), int(w * 0.9), maxi(4, int(w / 40.0))):
				img.fill_rect(Rect2i(x, wall - 4, maxi(2, int(w / 80.0)), 4), Color("2e3652"))
			var gw := int(w * 0.12)
			img.fill_rect(Rect2i(cx - gw, int(h * 0.42), gw * 2, ground - int(h * 0.42)), Color("141c34"))
			img.fill_rect(Rect2i(cx - 1, int(h * 0.42), 2, ground - int(h * 0.42)), Color("0a1020"))
			for k in range(2):
				var sx := cx + (-1 if k == 0 else 1) * gw / 2
				_glow_px(img, sx, int(h * 0.52), int(w * 0.05), Color("4a6aff"), 0.45)
				_disc(img, sx, int(h * 0.52), maxi(3, int(w * 0.025)), Color("2a3a8a"))
				_px(img, sx, int(h * 0.52), Color("c8d8ff"))
			# Bannières rouges du clan.
			for t in [0.25, 0.75]:
				var bx := int(w * t)
				img.fill_rect(Rect2i(bx - 3, wall + 4, 7, int(h * 0.1)), Color("7a2a2a"))
				_px(img, bx, wall + 8, Color("f2c46b"))
	_snowfall(img, rng, int(w * h / 180.0))


static func _colosse(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	# Salle du Cœur : voûte sombre, piliers runiques, grand cercle de runes au mur, autel du Cœur.
	_sky(img, rng, [[0.0, Color("06080f")], [0.5, Color("141a2c")], [1.0, Color("1e2438")]], 0.0)
	var cx := int(w * 0.5)
	var cy := int(h * 0.38)
	var r := int(minf(w, h) * 0.3)
	_glow_px(img, cx, cy, r + 10, Color("4a8aff"), 0.18)
	for k in range(3):
		var rr := r - k * int(r * 0.22)
		for a in range(360):
			var t := deg_to_rad(float(a))
			var col := Color("8fe3f2") if k != 1 else Color("f2c46b")
			_px(img, cx + int(cos(t) * rr), cy + int(sin(t) * rr), Color(col, 0.5 if k != 1 else 0.35))
	for k in range(8):
		var t := float(k) * TAU / 8.0
		_rune(img, cx + int(cos(t) * r * 0.89), cy + int(sin(t) * r * 0.89), [Color("ff7a3a"), Color("8fd16a"), Color("8fe3f2"), Color("f2c46b")][k % 4])
	for t in [0.06, 0.2, 0.8, 0.94]:
		var px := int(w * t)
		img.fill_rect(Rect2i(px - int(w * 0.035), 0, int(w * 0.07), h), Color("1a2034"))
		img.fill_rect(Rect2i(px + int(w * 0.02), 0, 2, h), Color("2a3450"))
		_rune(img, px, int(h * 0.3), Color("8fe3f2"))
	var floor_y := int(h * 0.78)
	img.fill_rect(Rect2i(0, floor_y, w, h - floor_y), Color("10141f"))
	# Marches et autel du Cœur, qui pulse d'or.
	for st in range(4):
		var sw := int(w * (0.36 - 0.06 * float(st)))
		img.fill_rect(Rect2i(cx - sw / 2, floor_y - (st + 1) * maxi(2, int(h * 0.025)), sw, maxi(2, int(h * 0.025))), Color("232a40") if st % 2 == 0 else Color("2a3250"))
	var ay := floor_y - 4 * maxi(2, int(h * 0.025))
	_glow_px(img, cx, ay - 6, int(w * 0.07), Color("ffd070"), 0.5)
	_disc(img, cx, ay - 6, maxi(2, int(w * 0.018)), Color("fff0b0"))
	# Givre qui tombe des voûtes.
	for i in range(int(w * h / 400.0)):
		_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color(0.7, 0.85, 1.0, rng.randf_range(0.2, 0.6)))


## La Forge de Havre-Aube : l'enclume de Durgan, le feu, les outils pendus.
static func _forge(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_sky(img, rng, [[0.0, Color("120a08")], [0.5, Color("2a160e")], [1.0, Color("3a2014")]], 0.0)
	# Foyer au fond, à gauche.
	var fx := int(w * 0.28)
	var fy := int(h * 0.5)
	img.fill_rect(Rect2i(fx - int(w * 0.14), int(h * 0.22), int(w * 0.28), int(h * 0.48)), Color("3a2a24"))
	img.fill_rect(Rect2i(fx - int(w * 0.1), int(h * 0.36), int(w * 0.2), int(h * 0.26)), Color("1a0e0a"))
	_glow_px(img, fx, fy, int(minf(w, h) * 0.3), Color("ff7a2a"), 0.3)
	for i in range(int(w * 0.6)):
		var x := fx + rng.randi_range(-int(w * 0.08), int(w * 0.08))
		var y := int(h * 0.6) - rng.randi_range(0, int(h * 0.12))
		_px(img, x, y, Color("ffb050") if rng.randf() < 0.6 else Color("ffe08a"))
	# Outils pendus au mur.
	for k in range(5):
		var tx := int(w * (0.55 + 0.08 * float(k)))
		img.fill_rect(Rect2i(tx, int(h * 0.18), 1, int(h * 0.14)), Color("6a5a50"))
		img.fill_rect(Rect2i(tx - 2, int(h * 0.32), 5, 3), Color("8a8a98"))
	var floor_y := int(h * 0.72)
	img.fill_rect(Rect2i(0, floor_y, w, h - floor_y), Color("22140e"))
	# L'enclume.
	var ax := int(w * 0.62)
	var ay := int(h * 0.62)
	img.fill_rect(Rect2i(ax - int(w * 0.12), ay, int(w * 0.24), int(h * 0.04)), Color("4a4a58"))
	img.fill_rect(Rect2i(ax - int(w * 0.04), ay + int(h * 0.04), int(w * 0.08), int(h * 0.06)), Color("3a3a46"))
	img.fill_rect(Rect2i(ax - int(w * 0.08), ay + int(h * 0.1), int(w * 0.16), int(h * 0.03)), Color("3a3a46"))
	img.fill_rect(Rect2i(ax - int(w * 0.12), ay, int(w * 0.24), 1), Color("ffb070"))
	# Étincelles.
	for i in range(int(w * h / 900.0)):
		var p := Vector2(rng.randf_range(w * 0.1, w * 0.9), rng.randf_range(h * 0.2, h * 0.7))
		_px(img, int(p.x), int(p.y), Color("ffd070") if rng.randf() < 0.5 else Color("ff8a3a"))


# ---------------------------------------------------------------- acte 5 · Désert de Verre

## Dune : une bosse de sable claire au sommet, ombrée sur le flanc gauche.
static func _dune(img: Image, cx: int, base: int, hw: int, hgt: int, body: Color, lit: Color) -> void:
	for x in range(cx - hw, cx + hw + 1):
		var k := float(x - cx) / float(maxi(1, hw))
		var top := base - int(float(hgt) * (1.0 - k * k) * (1.0 - 0.25 * k))
		for y in range(top, base + 1):
			_px(img, x, y, lit if k > -0.15 and y < top + 3 else body)


## Désert de Verre et ses variantes : dunes (plein jour), oasis, miroirs (crépuscule), college (ruines),
## desert_nuit (nuit des spectres), sphinx (salle de verre sous le Collège).
static func _desert(img: Image, rng: RandomNumberGenerator, kind: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	if kind == "sphinx":
		_sphinx_hall(img, rng)
		return
	match kind:
		"desert_nuit":
			_sky(img, rng, [[0.0, Color("0a0a20")], [0.5, Color("1a1a40")], [0.66, Color("3a3060")], [1.0, Color("2a2440")]], 1.4)
			_moon(img, int(w * 0.75), int(h * 0.15), maxi(5, int(minf(w, h) * 0.045)))
		"miroirs":
			_sky(img, rng, [[0.0, Color("2a1a48")], [0.35, Color("8a4a6a")], [0.55, Color("f29a5a")], [0.66, Color("ffd090")], [1.0, Color("8a5a3a")]], 0.4)
		"scarabee":
			# Ciel blanc de chaleur : le Scarabée pousse son soleil de verre.
			_sky(img, rng, [[0.0, Color("8ab0d8")], [0.4, Color("e8d8b0")], [0.6, Color("fff0c8")], [1.0, Color("d8a860")]], 0.0)
		_:
			_sky(img, rng, [[0.0, Color("2a5a9a")], [0.4, Color("6a9ad0")], [0.6, Color("f0d8a0")], [1.0, Color("c89a5a")]], 0.0)
	if kind in ["dunes", "oasis", "college", "mirage", "caravane_sable", "sceaux"]:
		var sx := int(w * 0.24)
		var sy := int(h * 0.2)
		var sr := maxi(5, int(minf(w, h) * 0.06))
		for r in range(sr * 3, sr, -1):
			_disc(img, sx, sy, r, Color(1.0, 0.9, 0.6, 0.035))
		_disc(img, sx, sy, sr, Color("fff4d0"))
	var night := kind == "desert_nuit"
	var far := Color("4a3a5a") if night else Color("d8a860")
	var near := Color("2a2440") if night else Color("c8904a")
	var lit := Color("6a5a8a") if night else Color("f2d090")
	for i in range(maxi(3, int(w / 90.0))):
		_dune(img, rng.randi_range(-20, w + 20), int(h * 0.62), rng.randi_range(int(w * 0.18), int(w * 0.32)), rng.randi_range(int(h * 0.08), int(h * 0.16)), far, lit)
	var ground := int(h * 0.66)
	img.fill_rect(Rect2i(0, ground, w, h - ground), near)
	for i in range(maxi(3, int(w / 110.0))):
		_dune(img, rng.randi_range(-30, w + 30), h, rng.randi_range(int(w * 0.2), int(w * 0.35)), rng.randi_range(int(h * 0.12), int(h * 0.24)), near, lit.darkened(0.1))
	match kind:
		"oasis":
			# Eau turquoise, palmiers et temple blanc.
			var wy := int(h * 0.7)
			for y in range(wy, wy + int(h * 0.08)):
				var half := int(w * 0.22 * (1.0 - absf(float(y - wy - int(h * 0.04))) / (h * 0.05)))
				img.fill_rect(Rect2i(int(w * 0.5) - half, y, half * 2, 1), Color("3fc1c9"))
			for k in range(4):
				var px := int(w * (0.22 + 0.18 * float(k)))
				var ph := int(h * (0.18 + 0.04 * float(k % 2)))
				for y in range(wy - ph, wy + 2):
					var tx := px + int(sin(float(y) * 0.08) * 2.0)
					_px(img, tx, y, Color("6a4a2a"))
					_px(img, tx + 1, y, Color("8a6a3a"))
				# Palmes : arcs épais qui retombent.
				var fr := maxi(6, int(w * 0.07))
				for a in range(7):
					var t := -PI + float(a) * PI / 6.0
					for r in range(fr):
						var fx := px + int(cos(t) * float(r))
						var fy := wy - ph + int(sin(t) * float(r) * 0.45) + (r * r) / (fr * 2)
						_px(img, fx, fy, Color("3f7a3a"))
						_px(img, fx, fy + 1, Color("2e5a2a"))
						if r % 3 == 0:
							_px(img, fx, fy + 2, Color("4f8a3a"))
			img.fill_rect(Rect2i(int(w * 0.66), int(h * 0.5), int(w * 0.16), int(h * 0.16)), Color("f4f1e8"))
			for c in range(4):
				img.fill_rect(Rect2i(int(w * 0.67) + c * int(w * 0.04), int(h * 0.5), 2, int(h * 0.16)), Color("c8c0a8"))
			_disc(img, int(w * 0.74), int(h * 0.48), maxi(3, int(w * 0.03)), Color("e6c15a"))
		"miroirs":
			# Deux grands miroirs plantés dans le sable, qui renvoient le couchant.
			for k in range(2):
				var mx := int(w * (0.3 + 0.4 * float(k)))
				var mh := int(h * 0.36)
				var mw := maxi(6, int(w * 0.07))
				var my := int(h * 0.68) - mh
				img.fill_rect(Rect2i(mx - mw / 2 - 2, my - 2, mw + 4, mh + 4), Color("8a5a2b"))
				for y in range(my, my + mh):
					for x in range(mx - mw / 2, mx + mw / 2):
						var kk := float(y - my) / float(mh)
						_px(img, x, y, Color("ffd8a0").lerp(Color("bfe6f0"), kk))
				for d in range(mh / 2):
					_px(img, mx - mw / 2 + 2 + d / 4, my + 3 + d, Color(1, 1, 1, 0.7))
				_glow_px(img, mx, my + mh / 3, mw, Color("ffe0a0"), 0.25)
		"college":
			# Le premier Collège à moitié enterré : dômes fendus, colonnes, éclats de verre.
			var cb := int(h * 0.68)
			for c in range(6):
				var cx := int(w * (0.2 + 0.12 * float(c)))
				var chh := int(h * (0.14 + 0.06 * float((c * 5) % 3)))
				img.fill_rect(Rect2i(cx, cb - chh, maxi(3, int(w * 0.025)), chh), Color("e8dcc0"))
				img.fill_rect(Rect2i(cx - 1, cb - chh, maxi(5, int(w * 0.035)), 2), Color("c8b890"))
			for k in range(2):
				var dx := int(w * (0.36 + 0.3 * float(k)))
				var dr := int(w * (0.1 - 0.03 * float(k)))
				for y in range(-dr, 1):
					var half := int(sqrt(float(dr * dr - y * y)))
					for x in range(-half, half + 1):
						var cut := x > half / 3 and y < -dr / 3 and k == 0
						if not cut:
							_px(img, dx + x, cb - int(h * 0.2) + y, Color("bfe6f0") if (x + y) % 5 != 0 else Color("e8ffff"))
			for i in range(int(w / 12.0)):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(cb, h - 1), Color("9ff0f0"))
		"desert_nuit":
			# Ruines et spectres d'élèves, translucides, un livre à la main.
			var cb := int(h * 0.7)
			for c in range(5):
				var cx := int(w * (0.15 + 0.17 * float(c)))
				img.fill_rect(Rect2i(cx, cb - int(h * 0.16), maxi(3, int(w * 0.025)), int(h * 0.16)), Color("3a3458"))
			for k in range(5):
				var gx := rng.randi_range(int(w * 0.1), int(w * 0.9))
				var gy := rng.randi_range(int(h * 0.6), int(h * 0.85))
				_glow_px(img, gx, gy, maxi(4, int(w * 0.03)), Color("a898e0"), 0.4)
				_disc(img, gx, gy - 3, 2, Color(0.85, 0.8, 1.0, 0.7))
				for y in range(gy - 1, gy + 6):
					for x in range(gx - 2 + (y - gy) / 3, gx + 3 - (y - gy) / 3):
						_px(img, x, y, Color(0.7, 0.62, 0.95, 0.5))
		"mirage":
			# Le mirage : un lac qui n'existe pas tremble sur l'horizon, et des portails qui ondulent.
			var my2 := int(h * 0.6)
			for y in range(my2, my2 + int(h * 0.04)):
				for x in range(int(w * 0.15), int(w * 0.85)):
					_px(img, x + int(sin(float(y) * 1.3) * 2.0), y, Color(0.6, 0.85, 1.0, 0.25))
			for k in range(3):
				var gx2 := int(w * (0.25 + 0.25 * float(k)))
				for y in range(int(h * 0.48), int(h * 0.6)):
					var wob := int(sin(float(y) * 0.6 + float(k)) * 2.0)
					_px(img, gx2 - 6 + wob, y, Color(0.5, 1.0, 0.95, 0.5))
					_px(img, gx2 + 6 + wob, y, Color(0.5, 1.0, 0.95, 0.5))
				for x in range(gx2 - 6, gx2 + 7):
					_px(img, x, int(h * 0.48), Color(0.5, 1.0, 0.95, 0.5))
		"scarabee":
			# Le Scarabée-soleil sur la crête, sa boule de verre incandescente.
			var bx2 := int(w * 0.62)
			var by2 := int(h * 0.56)
			var br := int(minf(w, h) * 0.09)
			_glow_px(img, bx2, by2, br * 2, Color("ffd070"), 0.3)
			_disc(img, bx2, by2, br, Color("ffe8a0"))
			_disc(img, bx2 - br / 3, by2 - br / 3, br / 3, Color("fffbe8"))
			var sx2 := bx2 - br - int(w * 0.1)
			for y in range(-int(h * 0.04), int(h * 0.04)):
				var half5 := int(float(w) * 0.09 * sqrt(maxf(0.0, 1.0 - pow(float(y) / (h * 0.04), 2.0))))
				img.fill_rect(Rect2i(sx2 - half5, by2 + y, half5 * 2, 1), Color("1e5a70") if y < 0 else Color("2a7a90"))
			for k in range(3):
				img.fill_rect(Rect2i(sx2 - int(w * 0.06) + k * int(w * 0.05), by2 + int(h * 0.04), 2, int(h * 0.03)), Color("123a48"))
		"caravane_sable":
			# La caravane au pied de la dune : chameaux chargés de tapis et de jarres.
			for k in range(3):
				var cx3 := int(w * (0.25 + 0.22 * float(k)))
				var cy3 := int(h * 0.64)
				img.fill_rect(Rect2i(cx3 - 9, cy3 - 10, 18, 6), Color("a8743a"))
				_disc(img, cx3 - 2, cy3 - 12, 4, Color("a8743a"))
				img.fill_rect(Rect2i(cx3 + 8, cy3 - 16, 3, 8), Color("a8743a"))
				_disc(img, cx3 + 11, cy3 - 17, 2, Color("a8743a"))
				for lx in [cx3 - 7, cx3 - 3, cx3 + 3, cx3 + 7]:
					img.fill_rect(Rect2i(lx, cy3 - 4, 1, 6), Color("8a5a2a"))
				img.fill_rect(Rect2i(cx3 - 8, cy3 - 15, 10, 4), Color("c83a2a") if k % 2 == 0 else Color("2a6ab0"))
		"sceaux":
			# Les grandes portes du Collège, scellées de violet, entre deux colonnes.
			var cb2 := int(h * 0.68)
			var gw2 := int(w * 0.14)
			img.fill_rect(Rect2i(int(w * 0.5) - gw2, cb2 - int(h * 0.26), gw2 * 2, int(h * 0.26)), Color("8a6a40"))
			img.fill_rect(Rect2i(int(w * 0.5) - 1, cb2 - int(h * 0.26), 2, int(h * 0.26)), Color("4a3420"))
			for k in range(2):
				var sx3 := int(w * 0.5) + (-1 if k == 0 else 1) * gw2 / 2
				_glow_px(img, sx3, cb2 - int(h * 0.14), int(w * 0.05), Color("d93cf2"), 0.45)
				_px(img, sx3, cb2 - int(h * 0.14), Color("ffc8ff"))
			for c2 in [0.24, 0.76]:
				img.fill_rect(Rect2i(int(w * c2) - 3, cb2 - int(h * 0.3), 7, int(h * 0.3)), Color("e8dcc0"))
		"dunes":
			for i in range(maxi(8, w / 20)):
				var gx := rng.randi_range(0, w - 1)
				var gy := rng.randi_range(int(h * 0.66), h - 1)
				_px(img, gx, gy, Color("9ff0f0"))
				_px(img, gx + 1, gy, Color("e8ffff"))
	# Voiles de sable (ou de brume froide la nuit).
	for i in range(int(w * h / 600.0)):
		var y := rng.randi_range(int(h * 0.5), h - 1)
		var x := rng.randi_range(-40, w)
		for dx in range(rng.randi_range(20, 70)):
			_px(img, x + dx, y, Color(0.7, 0.7, 1.0, 0.06) if night else Color(1.0, 0.92, 0.7, 0.08))


## La salle du Sphinx : verre sombre, colonnes, porte scellée, lueur violette.
static func _sphinx_hall(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_sky(img, rng, [[0.0, Color("0a0a18")], [0.5, Color("1a1a30")], [1.0, Color("2a2440")]], 0.0)
	for t in [0.08, 0.24, 0.76, 0.92]:
		var px := int(w * t)
		img.fill_rect(Rect2i(px - int(w * 0.03), 0, int(w * 0.06), h), Color("1e2a3a"))
		img.fill_rect(Rect2i(px + int(w * 0.015), 0, 2, h), Color("5a8aa0"))
		img.fill_rect(Rect2i(px - int(w * 0.03), int(h * 0.2), int(w * 0.06), 2), Color("e6c15a"))
	var cx := int(w * 0.5)
	var dw := int(w * 0.18)
	var top := int(h * 0.22)
	var floor_y := int(h * 0.8)
	img.fill_rect(Rect2i(cx - dw / 2, top, dw, floor_y - top), Color("141428"))
	for y in range(top, floor_y, 6):
		img.fill_rect(Rect2i(cx - dw / 2, y, dw, 1), Color("2a2a48"))
	img.fill_rect(Rect2i(cx - 1, top, 2, floor_y - top), Color("e6c15a"))
	_glow_px(img, cx, int(h * 0.48), int(w * 0.16), Color("b07cff"), 0.3)
	img.fill_rect(Rect2i(0, floor_y, w, h - floor_y), Color("10101e"))
	for x in range(0, w, maxi(6, w / 24)):
		_px(img, x, floor_y, Color("5a8aa0"))
	for i in range(int(w * h / 500.0)):
		_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color(0.8, 0.9, 1.0, rng.randf_range(0.1, 0.4)))


# ---------------------------------------------------------------- icônes (glyphes absents des polices)

## « sparkle » : étoile à 4 branches (✦) ; « next » : triangle vers le bas (▼).
# ---------------------------------------------------------------- acte 6 · Forêt Cendrée

## Arbre calciné : tronc noir, branches tordues, flammes aux extrémités si l'arbre brûle encore.
static func _burnt_tree(img: Image, rng: RandomNumberGenerator, x: int, base: int, hgt: int, burning: bool) -> void:
	var trunk := Color("120808")
	img.fill_rect(Rect2i(x - 1, base - hgt, 3, hgt), trunk)
	_px(img, x + 1, base - hgt, Color("3a1a12"))
	for b in range(rng.randi_range(3, 5)):
		var by := base - hgt + rng.randi_range(2, maxi(3, hgt * 2 / 3))
		var dir := -1 if b % 2 == 0 else 1
		var ln := rng.randi_range(hgt / 6 + 2, hgt / 3 + 3)
		var ex := x
		var ey := by
		for d in range(ln):
			ex = x + dir * d
			ey = by - d / 2
			_px(img, ex, ey, trunk)
		if burning and rng.randf() < 0.7:
			_glow_px(img, ex, ey - 2, 5, Color("ff7a2a"), 0.35)
			for f in range(6):
				_px(img, ex + rng.randi_range(-1, 1), ey - rng.randi_range(1, 4), Color("ffd070") if f % 2 == 0 else Color("ff6a2a"))
	if burning:
		_glow_px(img, x, base - hgt - 2, 6, Color("ff8a3a"), 0.4)
		for f in range(10):
			_px(img, x + rng.randi_range(-2, 2), base - hgt - rng.randi_range(0, 6), Color("ffe08a") if f % 3 == 0 else Color("ff7a2a"))


## Forêt Cendrée : ciel de fumée rougeoyant, arbres calcinés en flammes, braises, dragon dans les fumées.
## Variantes : coulee (rivières de magma), braisemont (village et gué), nid (nid des phénix), autels (autels du
## croissant), citadelle (forteresse draconide), caldeira (la Mère-Dragon enchaînée), antre (l'antre du Wyrm),
## lisiere_cendree (la lisière en flammes, le sable du désert au premier plan), couloirs (murs de flammes),
## ailes (dragons en vol, ombre de leurs ailes), drake (le piton du drake ancien).
static func _cendres(img: Image, rng: RandomNumberGenerator, kind: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	if kind in ["caldeira", "antre"]:
		_cendres_cave(img, rng, kind)
		return
	if kind == "lisiere_cendree":
		# Le ciel s'embrase depuis la forêt : le bas du ciel orange vif.
		_sky(img, rng, [[0.0, Color("1a0c10")], [0.3, Color("4a1a1a")], [0.5, Color("b03a1a")], [0.64, Color("f08a3a")], [0.7, Color("5a2416")], [1.0, Color("1a100e")]], 0.1)
	else:
		_sky(img, rng, [[0.0, Color("120a10")], [0.35, Color("3a141a")], [0.55, Color("8a2a1a")], [0.66, Color("d8602a")], [0.72, Color("4a1e16")], [1.0, Color("1a100e")]], 0.15)
	# Lune rougie derrière la fumée.
	var mx := int(w * 0.72)
	var my := int(h * 0.16)
	var mr := maxi(5, int(minf(w, h) * 0.05))
	_glow_px(img, mx, my, mr * 3, Color("ff8a5a"), 0.25)
	_disc(img, mx, my, mr, Color("f0a080"))
	# Volutes de fumée.
	for i in range(int(w * h / 420.0)):
		var y := rng.randi_range(int(h * 0.05), int(h * 0.5))
		var x := rng.randi_range(-40, w)
		for dx in range(rng.randi_range(20, 70)):
			_px(img, x + dx, y + int(sin(float(dx) * 0.12) * 2.0), Color(0.08, 0.04, 0.05, 0.2))
	# Dragon dans les fumées.
	var dx0 := int(w * 0.3)
	var dy0 := int(h * 0.22)
	var span := maxi(8, int(w * 0.07))
	for k in range(-span, span + 1):
		_px(img, dx0 + k, dy0 - absi(k) / 3 + (1 if absi(k) > span * 2 / 3 else 0), Color("1a0a0a"))
		_px(img, dx0 + k, dy0 - absi(k) / 3 + 1, Color("1a0a0a"))
	img.fill_rect(Rect2i(dx0 - 1, dy0 - 1, 3, 5), Color("1a0a0a"))
	# Collines lointaines en braises, puis forêt calcinée.
	_ridge(img, rng, int(h * 0.58), int(h * 0.03), Color("2a1412"), Color("8a3a1a"))
	var x := -rng.randi_range(0, 8)
	var burn_p := 0.85 if kind in ["lisiere_cendree", "couloirs"] else 0.45
	while x < w + 8:
		if kind == "couloirs" and absi(x - w / 2) < int(w * 0.12):
			x += rng.randi_range(int(w * 0.06), int(w * 0.11))
			continue
		_burnt_tree(img, rng, x, int(h * 0.68) + rng.randi_range(-3, 3), rng.randi_range(int(h * 0.12), int(h * 0.26)), rng.randf() < burn_p)
		x += rng.randi_range(int(w * 0.06), int(w * 0.11))
	for y in range(int(h * 0.68), h):
		var k := float(y - int(h * 0.68)) / float(maxi(1, h - int(h * 0.68)))
		img.fill_rect(Rect2i(0, y, w, 1), Color("2a1814").lerp(Color("120a08"), k))
	# Coulées de braises au sol et étincelles.
	for i in range(maxi(3, w / 60)):
		var lx := rng.randi_range(0, w)
		var ly := rng.randi_range(int(h * 0.72), h - 4)
		for d in range(rng.randi_range(10, 30)):
			_px(img, lx + d, ly + int(sin(float(d) * 0.3) * 1.5), Color("ff6a2a"))
	_fireflies(img, rng, int(w * h / 900.0), int(h * 0.2), h - 2, Color("ffb050"))
	var gy := int(h * 0.7)
	match kind:
		"lisiere_cendree":
			# La lisière : le sable du désert qui s'arrête net, la forêt en flammes derrière, une braise sur chaque arbre.
			for y in range(int(h * 0.82), h):
				var k2 := float(y - int(h * 0.82)) / maxf(1.0, h * 0.18)
				var sx0 := int(w * (0.55 - 0.25 * k2))
				img.fill_rect(Rect2i(0, y, sx0, 1), Color("a8844a").lerp(Color("6a4a2a"), k2))
				for d in range(3):
					_px(img, sx0 + d, y, Color("3a2418"))
			for k in range(int(w / 28)):
				_flame(img, rng, rng.randi_range(0, w), int(h * 0.68) + rng.randi_range(-2, 2), rng.randi_range(int(h * 0.05), int(h * 0.1)))
			_glow_px(img, w / 2, int(h * 0.64), int(w * 0.4), Color("ff7a2a"), 0.15)
		"couloirs":
			# Deux murs de flammes en perspective : ils convergent vers le fond, un couloir de cendre entre eux.
			var vx := w / 2
			var vy := int(h * 0.6)
			for side in [-1, 1]:
				for k3 in range(14):
					var f := float(k3) / 13.0
					var fx2 := int(lerpf(float(vx + side * int(w * 0.06)), float(vx + side * int(w * 0.62)), f))
					var fy2 := int(lerpf(float(vy), float(h + 6), f))
					_flame(img, rng, fx2, fy2, int(lerpf(h * 0.05, h * 0.3, f)))
			for y in range(vy, h):
				var k4 := float(y - vy) / maxf(1.0, float(h - vy))
				var half4 := int(lerpf(w * 0.05, w * 0.5, k4))
				img.fill_rect(Rect2i(vx - half4 + int(w * 0.03 * k4), y, maxi(1, half4 * 2 - int(w * 0.06 * k4)), 1), Color("3a2a26").lerp(Color("241a18"), k4))
			for i in range(w / 3):
				var ax3 := rng.randi_range(0, w)
				var ay3 := rng.randi_range(vy, h)
				_px(img, ax3, ay3, Color("6a6a6a") if rng.randf() < 0.7 else Color("ff8a3a"))
		"ailes":
			# Deux dragons immenses passent sous la fumée ; l'ombre de leurs ailes couvre la forêt.
			for dr in [[0.34, 0.2, 0.3], [0.74, 0.32, 0.18]]:
				_wing_silhouette(img, int(w * float(dr[0])), int(h * float(dr[1])), int(w * float(dr[2])), Color("140808"))
			for y in range(int(h * 0.6), int(h * 0.8)):
				var sa := 0.35 * (1.0 - absf(float(y - int(h * 0.7)) / (h * 0.1)))
				for x5 in range(int(w * 0.08), int(w * 0.62)):
					_px(img, x5, y, Color(0.03, 0.01, 0.01, sa))
			# Écailles marquées tombées des ailes : la Marque du Wyrm y brûle.
			for i in range(5):
				var mx2 := rng.randi_range(int(w * 0.1), int(w * 0.9))
				var my2 := rng.randi_range(int(h * 0.78), h - 6)
				_disc(img, mx2, my2, 2, Color("6a1a12"))
				_px(img, mx2, my2, Color("ff4a2a"))
		"drake":
			# Le perchoir du drake ancien : un piton de basalte, ossements et éclats d'écailles, griffures dans la roche.
			var px2 := w / 2
			var pb := int(h * 0.76)
			var pw := int(w * 0.3)
			# Rocher déchiqueté : sommet en dents de scie, flancs éclairés par les braises.
			var walk := 0.0
			for xx in range(px2 - int(pw * 0.7), px2 + int(pw * 0.7)):
				walk = clampf(walk + rng.randf_range(-1.6, 1.6), -float(h) * 0.04, float(h) * 0.04)
				var f5 := absf(float(xx - px2)) / (float(pw) * 0.7)
				var top5 := int(h * 0.44 + f5 * f5 * h * 0.3 + walk)
				for y in range(top5, pb + int(h * 0.03)):
					var k5 := float(y - top5) / maxf(1.0, float(pb - top5))
					var c5 := Color("2a1e22").lerp(Color("181012"), k5)
					if (xx + y / 3) % 9 == 0:
						c5 = c5.darkened(0.3)
					_px(img, xx, y, c5)
				_px(img, xx, top5, Color("8a4a2a") if xx > px2 else Color("4a2a24"))
				_px(img, xx, top5 + 1, Color("5a3024"))
			for k6 in range(3):
				for d2 in range(int(h * 0.12)):
					_px(img, px2 - pw / 6 + k6 * 5 + d2 / 4, int(h * 0.54) + d2, Color("ff7a2a") if d2 % 5 else Color("ffd070"))
			for i in range(maxi(6, w / 24)):
				var bx2 := rng.randi_range(int(w * 0.05), int(w * 0.95))
				var by2 := rng.randi_range(int(h * 0.8), h - 3)
				img.fill_rect(Rect2i(bx2, by2, rng.randi_range(5, 12), 2), Color("d8c8a8"))
				_px(img, bx2, by2 - 1, Color("d8c8a8"))
			_glow_px(img, px2, int(h * 0.5), int(w * 0.18), Color("ff9a4a"), 0.2)
		"coulee":
			# Rivières de magma qui serpentent jusqu'au premier plan.
			for k in range(3):
				var x0 := int(w * (0.15 + 0.35 * float(k))) + rng.randi_range(-10, 10)
				var fx := float(x0)
				for y in range(int(h * 0.62), h):
					fx += sin(float(y) * 0.06 + float(k)) * 0.8
					var half := 2 + int(float(y - int(h * 0.62)) * 0.06)
					for dx in range(-half, half + 1):
						_px(img, int(fx) + dx, y, Color("ffd070") if absi(dx) < half / 2 else Color("ff5a1a"))
				_glow_px(img, x0, int(h * 0.8), int(minf(w, h) * 0.12), Color("ff6a2a"), 0.2)
		"braisemont":
			# Le village : maisons à colombages, toits pointus, l'incendie derrière, le gué au premier plan.
			for k in range(5):
				var hx := int(w * (0.08 + 0.2 * float(k))) + rng.randi_range(-6, 6)
				var hb := gy - rng.randi_range(0, 6)
				var hw := maxi(10, int(w * 0.09))
				img.fill_rect(Rect2i(hx, hb - hw, hw, hw), Color("4a3428"))
				for yy in range(hw / 2 + 2):
					img.fill_rect(Rect2i(hx - 2 + yy, hb - hw - hw / 2 - 2 + yy, maxi(1, hw + 4 - yy * 2), 1), Color("2a1a14"))
				img.fill_rect(Rect2i(hx + hw / 3, hb - hw / 2, hw / 4, hw / 3), Color("ffb050"))
				_glow_px(img, hx + hw / 2, hb - hw - 4, hw, Color("ff6a2a"), 0.25)
			for y in range(int(h * 0.84), int(h * 0.92)):
				img.fill_rect(Rect2i(0, y, w, 1), Color("1e3a4a").lerp(Color("2a5a6a"), float(y - int(h * 0.84)) / maxf(1.0, h * 0.08)))
			for i in range(w / 6):
				_px(img, rng.randi_range(0, w), rng.randi_range(int(h * 0.84), int(h * 0.92)), Color("ff9b4a"))
			for k in range(6):
				var px := int(w * (0.3 + 0.07 * float(k)))
				img.fill_rect(Rect2i(px, int(h * 0.8), 2, 6), Color("1a1010"))
				_px(img, px, int(h * 0.8) - 1, Color("1a1010"))
		"nid":
			# Nid géant au sommet d'un piton, phénix d'or au centre.
			var nx := w / 2
			var ny := int(h * 0.5)
			var nr := int(minf(w, h) * 0.2)
			for y in range(ny, h):
				var half := int(float(y - ny) * 0.5) + nr / 2
				img.fill_rect(Rect2i(nx - half, y, half * 2, 1), Color("1e1210"))
			for i in range(nr * 8):
				var a := rng.randf_range(PI, TAU)
				var rr := rng.randf_range(nr * 0.6, nr * 1.05)
				var p0 := Vector2(nx + cos(a) * rr, ny + sin(a) * rr * 0.35)
				_px(img, int(p0.x), int(p0.y), Color("5a3a22") if i % 3 else Color("8a5a2a"))
			_glow_px(img, nx, ny - nr / 3, nr, Color("ffb050"), 0.5)
			for k in range(-nr / 2, nr / 2 + 1):
				_px(img, nx + k, ny - nr / 3 - absi(k) / 3, Color("ffd070"))
				_px(img, nx + k, ny - nr / 3 - absi(k) / 3 + 1, Color("ff8a2a"))
			_disc(img, nx, ny - nr / 3, maxi(2, nr / 6), Color("fff0a0"))
		"autels":
			# Marches du temple et deux autels d'obsidienne au croissant violet.
			for k in range(4):
				img.fill_rect(Rect2i(int(w * 0.2) + k * 4, gy - k * 4, int(w * 0.6) - k * 8, 4), Color("2a2026").lightened(0.05 * float(k)))
			for sx in [0.27, 0.73]:
				var ax := int(w * sx)
				var ab := gy + 2
				var aw := maxi(8, int(w * 0.08))
				img.fill_rect(Rect2i(ax - aw / 2, ab - aw * 2, aw, aw * 2), Color("140e16"))
				img.fill_rect(Rect2i(ax - aw / 2 - 2, ab - aw * 2 - 2, aw + 4, 3), Color("2a2030"))
				_glow_px(img, ax, ab - aw, aw, Color("b07cff"), 0.4)
				for t in range(12):
					var a := lerpf(-1.2, 1.2, float(t) / 11.0)
					_px(img, ax + int(sin(a) * aw * 0.3), ab - aw + int(cos(a) * aw * 0.3) - aw / 4, Color("d8b0ff"))
				_fire(img, rng, ax + aw, ab - aw * 2 - 4)
		"citadelle":
			# Forteresse draconide sur la montagne, bannières rouges.
			var cx := w / 2
			var cb := int(h * 0.62)
			var cw := int(w * 0.5)
			img.fill_rect(Rect2i(cx - cw / 2, cb - int(h * 0.12), cw, int(h * 0.12)), Color("1a1214"))
			for k in range(4):
				var tx := cx - cw / 2 + k * cw / 3
				var th := int(h * (0.18 + 0.05 * float(k % 2)))
				img.fill_rect(Rect2i(tx - 4, cb - th, 9, th), Color("221618"))
				for yy in range(6):
					img.fill_rect(Rect2i(tx - 5 + yy, cb - th - 6 + yy, maxi(1, 11 - yy * 2), 1), Color("3a1a1a"))
				_banner(img, tx + 5, cb - th + 4, 12, Color("a8221a"))
				_px(img, tx, cb - th / 2, Color("ffb050"))
	if kind != "cendres":
		_mist(img, rng, int(h * 0.6), h - 2, Color(0.2, 0.08, 0.06, 0.2), 20)


## Langue de flamme : base jaune, corps orange, pointe rouge qui ondule, lueur autour.
static func _flame(img: Image, rng: RandomNumberGenerator, x: int, base: int, hgt: int) -> void:
	_glow_px(img, x, base - hgt / 2, maxi(4, hgt), Color("ff7a2a"), 0.22)
	var hw := maxi(2, hgt / 4)
	for y in range(hgt):
		var k := float(y) / float(maxi(1, hgt))
		var half := int(float(hw) * (1.0 - k) * (0.8 + 0.2 * sin(k * 9.0 + float(x))))
		var sway := int(sin(k * 4.0 + float(x) * 0.3) * float(hw) * 0.5 * k)
		for dx in range(-half, half + 1):
			var c := Color("ffe08a") if k < 0.3 and absi(dx) < half / 2 + 1 else (Color("ff8a2a") if k < 0.7 else Color("d83a1a"))
			_px(img, x + dx + sway, base - y, c)
	if rng.randf() < 0.5:
		_px(img, x + rng.randi_range(-hw, hw), base - hgt - rng.randi_range(2, 6), Color("ffb050"))


## Silhouette de dragon en vol, ailes déployées (vue de dessous), de la taille « span ».
static func _wing_silhouette(img: Image, cx: int, cy: int, span: int, col: Color) -> void:
	var half := span / 2
	for k in range(-half, half + 1):
		var f := absf(float(k)) / float(maxi(1, half))
		var top := cy - int(float(span) * 0.18 * sin(f * PI * 0.9))
		var bot := cy + int(float(span) * 0.06 * (1.0 - f)) + int(3.0 * sin(f * 18.0))
		for y in range(top, bot + 1):
			_px(img, cx + k, y, col)
	img.fill_rect(Rect2i(cx - maxi(1, span / 40), cy - span / 6, maxi(2, span / 20), span / 2), col)
	for d in range(span / 4):
		_px(img, cx + int(sin(float(d) * 0.3) * 3.0), cy + span / 3 + d, col)
	_disc(img, cx, cy - span / 6, maxi(2, span / 26), col)


## Le Pardon : la forêt guérie à l'aube. Les troncs restent noirs, mais des pousses vertes les couvrent ;
## le feu de la Mère, redevenu doré, luit sous les cendres ; des cendres d'or flottent.
static func _pardon(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_sky(img, rng, [[0.0, Color("2a1e3a")], [0.3, Color("7a4a5a")], [0.52, Color("e8a060")], [0.64, Color("ffd890")], [0.7, Color("6a5a3a")], [1.0, Color("2a2a1a")]], 0.05)
	var sx := int(w * 0.5)
	var sy := int(h * 0.62)
	_glow_px(img, sx, sy, int(w * 0.35), Color("ffd070"), 0.3)
	_disc(img, sx, sy, maxi(5, int(minf(w, h) * 0.06)), Color("fff0c0"))
	_ridge(img, rng, int(h * 0.6), int(h * 0.03), Color("3a3a22"), Color("8a9a4a"))
	var x := -rng.randi_range(0, 8)
	while x < w + 8:
		var base := int(h * 0.7) + rng.randi_range(-3, 3)
		var hgt := rng.randi_range(int(h * 0.12), int(h * 0.26))
		_burnt_tree(img, rng, x, base, hgt, false)
		# Pousses vertes sur le tronc et au pied.
		for f in range(rng.randi_range(4, 9)):
			_px(img, x + rng.randi_range(-3, 3), base - rng.randi_range(0, hgt), Color("7ac83a") if f % 2 else Color("b8f070"))
		x += rng.randi_range(int(w * 0.06), int(w * 0.11))
	for y in range(int(h * 0.7), h):
		var k := float(y - int(h * 0.7)) / float(maxi(1, h - int(h * 0.7)))
		img.fill_rect(Rect2i(0, y, w, 1), Color("3a3a22").lerp(Color("1e2014"), k))
	for i in range(w * 2):
		var gx := rng.randi_range(0, w)
		var gy := rng.randi_range(int(h * 0.72), h)
		_px(img, gx, gy, Color("5a8a2a") if i % 3 else Color("9ad050"))
		if i % 4 == 0:
			_px(img, gx, gy - 1, Color("7ab83a"))
	# Le feu doré sous les cendres.
	for i in range(maxi(3, w / 70)):
		var lx := rng.randi_range(0, w)
		var ly := rng.randi_range(int(h * 0.76), h - 4)
		for d in range(rng.randi_range(8, 20)):
			_px(img, lx + d, ly + int(sin(float(d) * 0.3) * 1.5), Color("ffd070"))
		_glow_px(img, lx + 8, ly, 8, Color("ffd070"), 0.2)
	_fireflies(img, rng, int(w * h / 800.0), int(h * 0.2), h - 2, Color("ffe08a"))
	_mist(img, rng, int(h * 0.62), int(h * 0.75), Color(1.0, 0.9, 0.7, 0.12), 14)


## Cavernes : la caldeira de la Mère-Dragon (dragonne endormie, chaînes brisées, l'Œuf de cendre) et l'antre du Wyrm.
static func _cendres_cave(img: Image, rng: RandomNumberGenerator, kind: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var mother := kind == "caldeira"
	_sky(img, rng, [[0.0, Color("0a0606")], [0.5, Color("2a0e0a") if mother else Color("1a0a0c")], [1.0, Color("120808")]], 0.0)
	# Parois de basalte veinées de feu.
	for side in [0, 1]:
		for y in range(h):
			var k := float(y) / float(h)
			var x_edge := int(w * (0.12 + 0.1 * sin(k * 5.0 + float(side))))
			if side == 0:
				img.fill_rect(Rect2i(0, y, x_edge, 1), Color("1a1010"))
			else:
				img.fill_rect(Rect2i(w - x_edge, y, x_edge, 1), Color("1a1010"))
	for i in range(maxi(6, w / 25)):
		var vx := rng.randi_range(0, w)
		var vy := rng.randi_range(0, h)
		for d in range(rng.randi_range(8, 24)):
			_px(img, vx + d / 2, vy + d, Color("ff5a1a") if mother else Color("8a2a1a"))
	var cx := w / 2
	var cy := int(h * 0.55)
	var r := int(minf(w, h) * 0.32)
	_glow_px(img, cx, cy, r + 10, Color("ffb050") if mother else Color("ff3a1a"), 0.3)
	# Le dragon lui-même est le sujet de la scène (sprite au premier plan) : ici, son halo et ses yeux dans l'ombre.
	if mother:
		# Chaînes de cendre brisées et l'Œuf noir veiné de feu.
		for k in range(3):
			var ax := cx - r / 2 + k * r / 2
			for d in range(0, int(h * 0.2), 3):
				_px(img, ax + (d / 6) % 2, cy - r / 2 - d, Color("6a6060"))
		var ex := cx + r / 2
		var ey := cy + r / 2 + 10
		_disc(img, ex, ey, maxi(4, r / 5), Color("120a0a"))
		for d in range(r / 5):
			_px(img, ex - r / 10 + d / 2, ey - r / 10 + d, Color("ff6a2a"))
		_glow_px(img, ex, ey, r / 4, Color("ff6a2a"), 0.3)
	else:
		# Ossements et yeux dans l'ombre.
		for i in range(maxi(6, w / 20)):
			var bx := rng.randi_range(0, w)
			var by := rng.randi_range(int(h * 0.75), h - 3)
			img.fill_rect(Rect2i(bx, by, rng.randi_range(4, 9), 2), Color("c8b8a0"))
		for i in range(4):
			var gx := rng.randi_range(int(w * 0.1), int(w * 0.9))
			var gy2 := rng.randi_range(int(h * 0.1), int(h * 0.35))
			_px(img, gx, gy2, Color("ff6a2a"))
			_px(img, gx + 3, gy2, Color("ff6a2a"))
	_fireflies(img, rng, int(w * h / 700.0), int(h * 0.1), h - 2, Color("ffb050") if mother else Color("ff6a2a"))


# ---------------------------------------------------------------- acte 7 · Cité Engloutie

## La Cité Engloutie : lumière de la surface en rayons, tours et arches noyées, statues d'Archivistes, algues, bulles.
static func _cite(img: Image, rng: RandomNumberGenerator, kind: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	if kind in ["archives", "abysse", "kraken", "fil", "fosse"]:
		_cite_deep(img, rng, kind)
		return
	_sky(img, rng, [[0.0, Color("2a8aa8")], [0.2, Color("146a8a")], [0.5, Color("0a3a5a")], [1.0, Color("041428")]], 0.0)
	# Surface ondulante et rayons de lumière.
	for x in range(w):
		_px(img, x, 2 + int(sin(float(x) * 0.2) * 1.5), Color(0.8, 0.95, 1.0, 0.5))
	for r in range(5):
		var x0 := rng.randi_range(-20, w)
		var ww := rng.randi_range(5, 14)
		for y in range(int(h * 0.7)):
			var a := 0.08 * (1.0 - float(y) / (h * 0.7))
			for dx in range(ww):
				_px(img, x0 + dx + y / 4, y, Color(0.75, 0.95, 1.0, a))
	# Tours et dômes engloutis.
	var base := int(h * 0.66)
	for i in range(maxi(4, w / 45)):
		var tx := rng.randi_range(0, w)
		var th := rng.randi_range(int(h * 0.15), int(h * 0.4))
		var tw := rng.randi_range(8, 16)
		img.fill_rect(Rect2i(tx, base - th, tw, th), Color("0c2a40"))
		_disc(img, tx + tw / 2, base - th, tw / 2 + 2, Color("0e3048"))
		for k in range(th / 8):
			_px(img, tx + tw / 2, base - th + 4 + k * 8, Color("4fe3d2"))
		# Algues accrochées.
		for k in range(rng.randi_range(2, 5)):
			var sx := tx + rng.randi_range(0, tw)
			for d in range(rng.randi_range(4, 12)):
				_px(img, sx + int(sin(float(d) * 0.6) * 1.2), base - th + d, Color("2a8a6a"))
	# Arche centrale et statue d'Archiviste.
	var ax := w / 2
	var aw := int(w * 0.22)
	for k in range(-aw, aw + 1):
		var yy := base - int(h * 0.22) + int(float(k * k) / float(aw * aw) * h * 0.06)
		img.fill_rect(Rect2i(ax + k, yy, 1, 3), Color("123a54"))
	img.fill_rect(Rect2i(ax - aw, base - int(h * 0.16), 5, int(h * 0.16)), Color("123a54"))
	img.fill_rect(Rect2i(ax + aw - 4, base - int(h * 0.16), 5, int(h * 0.16)), Color("123a54"))
	var sx0 := ax - 3
	img.fill_rect(Rect2i(sx0, base - int(h * 0.12), 7, int(h * 0.12)), Color("1a4a5a"))
	_disc(img, ax, base - int(h * 0.12) - 3, 3, Color("1a4a5a"))
	_px(img, ax - 1, base - int(h * 0.12) - 3, Color("8fe0ff"))
	_px(img, ax + 1, base - int(h * 0.12) - 3, Color("8fe0ff"))
	# Fond marin, coraux, bulles, poissons.
	for y in range(base, h):
		img.fill_rect(Rect2i(0, y, w, 1), Color("0a2a3a").lerp(Color("041420"), float(y - base) / float(maxi(1, h - base))))
	for i in range(maxi(8, w / 14)):
		var cx := rng.randi_range(0, w)
		var cb := base + rng.randi_range(2, int((h - base) * 0.6))
		for d in range(rng.randi_range(3, 8)):
			_px(img, cx + rng.randi_range(-1, 1), cb - d, [Color("e86a8a"), Color("ff9a6a"), Color("4fe3d2")][i % 3])
	for i in range(int(w * h / 500.0)):
		var bx := rng.randi_range(0, w - 1)
		var by := rng.randi_range(0, h - 1)
		_px(img, bx, by, Color(0.85, 0.97, 1.0, rng.randf_range(0.2, 0.6)))
	for k in range(3):
		var fx := rng.randi_range(0, w)
		var fy := rng.randi_range(int(h * 0.2), int(h * 0.5))
		for j in range(6):
			_px(img, fx + j * 4, fy + rng.randi_range(-2, 2), Color(0.7, 0.9, 1.0, 0.7))
	match kind:
		"quais":
			# Quais de pierre et bateaux échoués au premier plan.
			img.fill_rect(Rect2i(0, int(h * 0.78), w, 4), Color("1a3a4a"))
			for k in range(3):
				var bx := int(w * (0.15 + 0.32 * float(k)))
				var by := int(h * 0.86)
				for yy in range(6):
					img.fill_rect(Rect2i(bx - 10 + yy, by + yy, 20 - yy * 2, 1), Color("3a2a1e"))
				img.fill_rect(Rect2i(bx, by - 14, 1, 14), Color("3a2a1e"))
		"canal":
			# Le canal : deux berges et un pont arqué.
			img.fill_rect(Rect2i(0, int(h * 0.7), w, int(h * 0.08)), Color("0e4a6a"))
			for k in range(-int(w * 0.2), int(w * 0.2)):
				var yy := int(h * 0.62) + int(float(k * k) / float(maxi(1, int(w * 0.2) * int(w * 0.2))) * h * 0.06)
				img.fill_rect(Rect2i(w / 2 + k, yy, 1, 3), Color("1a4a5a"))
			for k in range(10):
				_px(img, rng.randi_range(0, w), int(h * 0.74), Color(0.7, 0.95, 1.0, 0.8))
		"statues":
			# Rangée de statues de Porteurs, une sans visage.
			for k in range(5):
				var sx := int(w * (0.12 + 0.19 * float(k)))
				var sb := int(h * 0.86)
				img.fill_rect(Rect2i(sx - 3, sb - 22, 7, 22), Color("2a5a6a"))
				img.fill_rect(Rect2i(sx - 5, sb, 11, 3), Color("1a3a4a"))
				_disc(img, sx, sb - 25, 3, Color("2a5a6a") if k != 2 else Color("1a2a34"))
				_px(img, sx + 3, sb - 14, Color("4fe3d2"))
		"palais":
			# Le palais du gardien : façade de nacre à trois dômes, arches de corail, fenêtres turquoise,
			# grand portail lumineux, escalier qui descend vers le spectateur.
			var pw := int(w * 0.64)
			var px0 := w / 2 - pw / 2
			var pb := int(h * 0.74)
			var ph := int(h * 0.3)
			img.fill_rect(Rect2i(px0, pb - ph, pw, ph), Color("143e58"))
			for k in range(7):
				var cx2 := px0 + 4 + k * (pw - 8) / 6
				img.fill_rect(Rect2i(cx2, pb - ph + 6, 3, ph - 6), Color("bfd8e0"))
				_px(img, cx2 + 1, pb - ph + 5, Color("e8f4ff"))
			for k in range(6):
				var wx := px0 + 8 + k * (pw - 8) / 6
				for yy in range(pb - ph + 12, pb - ph + 22):
					img.fill_rect(Rect2i(wx, yy, maxi(2, (pw - 8) / 6 - 10), 1), Color("4fe3d2").lerp(Color("1a6a7a"), float(yy - pb + ph - 12) / 10.0))
			for d in [[0.5, 0.16], [0.24, 0.1], [0.76, 0.1]]:
				var dx := int(w * float(d[0]))
				var dr := int(w * float(d[1]) * 0.5)
				for yy in range(dr):
					var half := int(sqrt(float(dr * dr - yy * yy)))
					img.fill_rect(Rect2i(dx - half, pb - ph - yy, half * 2, 1), Color("1e5070").lerp(Color("2a6a8a"), float(yy) / float(maxi(1, dr))))
				_px(img, dx, pb - ph - dr - 1, Color("e8f4ff"))
				img.fill_rect(Rect2i(dx, pb - ph - dr - 6, 1, 5), Color("bfd8e0"))
			var gw := int(pw * 0.18)
			img.fill_rect(Rect2i(w / 2 - gw / 2, pb - int(ph * 0.6), gw, int(ph * 0.6)), Color("4fe3d2"))
			for yy in range(gw / 2):
				var half2 := int(sqrt(float((gw / 2) * (gw / 2) - yy * yy)))
				img.fill_rect(Rect2i(w / 2 - half2, pb - int(ph * 0.6) - yy, half2 * 2, 1), Color("4fe3d2"))
			_glow_px(img, w / 2, pb - int(ph * 0.4), int(minf(w, h) * 0.16), Color("4fe3d2"), 0.35)
			for k in range(5):
				var sw := gw + k * int(w * 0.05)
				img.fill_rect(Rect2i(w / 2 - sw / 2, pb + k * 3, sw, 3), Color("1a4a64").lerp(Color("0e2a3e"), float(k) / 5.0))
			for side: int in [-1, 1]:
				for k in range(9):
					var ax2 := w / 2 + side * (pw / 2 + 4)
					_px(img, ax2 + side * int(sin(float(k) * 0.5) * 3.0), pb - k * 4, Color("e87aa0"))
		"marees":
			# La grande marée : le courant couche les algues, soulève le sable ; au loin, une ombre respire.
			_glow_px(img, int(w * 0.75), int(h * 0.4), int(w * 0.25), Color("02060c"), 0.5)
			for i in range(maxi(30, w / 4)):
				var sy := rng.randi_range(int(h * 0.1), int(h * 0.9))
				var sx := rng.randi_range(-20, w)
				var ln := rng.randi_range(10, 40)
				for d in range(ln):
					_px(img, sx + d, sy + int(sin(float(d) * 0.2 + float(i)) * 1.5), Color(0.7, 0.95, 1.0, 0.25))
			for i in range(maxi(10, w / 20)):
				var kx := rng.randi_range(0, w)
				var kb := int(h * 0.9) + rng.randi_range(-4, 4)
				for d in range(rng.randi_range(14, 30)):
					_px(img, kx + d / 2 + int(sin(float(d) * 0.4) * 1.5), kb - d, Color("2a8a6a") if d % 3 else Color("4ab88a"))
			for y in range(int(h * 0.8), h):
				for i in range(w / 8):
					_px(img, rng.randi_range(0, w), y, Color(0.8, 0.75, 0.6, 0.3))
		"cloche":
			# La cloche de plongée des Archivistes, suspendue à ses chaînes au-dessus des quais, hublots allumés.
			img.fill_rect(Rect2i(0, int(h * 0.78), w, 4), Color("1a3a4a"))
			var bx2 := w / 2
			var bt := int(h * 0.26)
			var bh := int(h * 0.34)
			for side: int in [-1, 1]:
				for y in range(0, bt):
					if y % 3 != 2:
						_px(img, bx2 + side * 6 + side * y / 10, y, Color("5a6a6a"))
			for yy in range(bh):
				var half3 := int(float(bh) * (0.12 + 0.48 * sqrt(float(yy + 1) / float(bh))))
				var c3 := Color("2a5a4a").lerp(Color("4a7a5a"), float(yy) / float(bh))
				img.fill_rect(Rect2i(bx2 - half3, bt + yy, half3 * 2, 1), c3)
				_px(img, bx2 + half3 - 1, bt + yy, Color("8ab88a"))
			img.fill_rect(Rect2i(bx2 - int(float(bh) * 0.7), bt + bh, int(float(bh) * 1.4), 3), Color("1a3a2a"))
			for k in range(3):
				var hx := bx2 - int(bh * 0.3) + k * int(bh * 0.3)
				var hy := bt + int(bh * 0.6)
				_disc(img, hx, hy, maxi(2, bh / 14), Color("ffe08a"))
				_glow_px(img, hx, hy, bh / 6, Color("ffd070"), 0.3)
		"portes_archives":
			# Les portes des Archives : deux battants immenses gravés de fils, scellés par la corruption violette ;
			# des Archivistes immobiles de part et d'autre.
			var dw := int(w * 0.34)
			var dt := int(h * 0.2)
			var db := int(h * 0.8)
			img.fill_rect(Rect2i(w / 2 - dw / 2 - 6, dt - 6, dw + 12, db - dt + 6), Color("0c2234"))
			for side: int in [-1, 1]:
				var x0 := w / 2 if side > 0 else w / 2 - dw / 2
				img.fill_rect(Rect2i(x0, dt, dw / 2 - 1, db - dt), Color("1a4a5a"))
				for k in range(5):
					var lx := x0 + 3 + k * (dw / 2 - 6) / 4
					for y in range(dt + 4, db - 4, 2):
						_px(img, lx + int(sin(float(y) * 0.1 + float(k)) * 1.5), y, Color(0.31, 0.89, 0.82, 0.55))
			img.fill_rect(Rect2i(w / 2 - 1, dt, 2, db - dt), Color("05101a"))
			for v in range(8):
				var p := Vector2(w / 2, rng.randi_range(dt, db))
				var d := Vector2.from_angle(rng.randf_range(0.0, TAU))
				for k in range(rng.randi_range(10, 24)):
					_px(img, int(p.x), int(p.y), Color("b07cff") if k % 3 else Color("e0b0ff"))
					d = d.rotated(rng.randf_range(-0.6, 0.6))
					p += d
			_glow_px(img, w / 2, (dt + db) / 2, dw / 2, Color("b07cff"), 0.25)
			for k in range(6):
				var sx3 := int(w * (0.08 + 0.13 * float(k if k < 3 else k + 1)))
				var sb3 := int(h * 0.86)
				img.fill_rect(Rect2i(sx3 - 3, sb3 - 20, 7, 20), Color("2a4a5a"))
				_disc(img, sx3, sb3 - 23, 3, Color("2a4a5a"))
				_px(img, sx3 - 1, sb3 - 23, Color("ffe08a"))
				_px(img, sx3 + 1, sb3 - 23, Color("ffe08a"))
		"sirenes":
			# Le récif des Sirènes : arches de corail rose, bénitiers géants et leurs perles, rochers où chantent
			# des silhouettes à queue de poisson, lumière rose.
			_glow_px(img, w / 2, int(h * 0.5), int(w * 0.4), Color("ff8ab8"), 0.15)
			for i in range(maxi(6, w / 40)):
				var cx4 := rng.randi_range(0, w)
				var cb4 := int(h * 0.8) + rng.randi_range(-6, 6)
				for br in range(5):
					var p4 := Vector2(cx4, cb4)
					var a4 := -PI * 0.5 + rng.randf_range(-0.8, 0.8)
					for d in range(rng.randi_range(8, 22)):
						_px(img, int(p4.x), int(p4.y), Color("e87aa0") if d % 4 else Color("ffb0c8"))
						a4 += rng.randf_range(-0.2, 0.2)
						p4 += Vector2.from_angle(a4)
			for k in range(3):
				var rx := int(w * (0.2 + 0.3 * float(k)))
				var rb := int(h * 0.76)
				for yy in range(int(h * 0.12)):
					var half4 := int(float(h) * 0.07) - yy / 3
					img.fill_rect(Rect2i(rx - half4, rb - yy, half4 * 2, 1), Color("123048"))
				var top4 := rb - int(h * 0.12)
				img.fill_rect(Rect2i(rx - 2, top4 - 12, 4, 10), Color("2a6a7a"))
				_disc(img, rx, top4 - 15, 3, Color("2a6a7a"))
				for d in range(8):
					_px(img, rx + 2 + d, top4 - 2 + d / 3, Color("2a8a8a"))
				_px(img, rx + 10, top4 + 1, Color("4ab8a8"))
				_px(img, rx + 11, top4 + 2, Color("4ab8a8"))
				for n in range(3):
					_px(img, rx - 6 - n * 4, top4 - 18 - n * 3, Color("ffb0d8"))
			for k in range(4):
				var clx := int(w * (0.1 + 0.27 * float(k)))
				var cly := int(h * 0.9)
				for yy in range(-5, 3):
					for xx in range(-9, 10):
						if Vector2(float(xx), float(yy) * 1.7).length() <= 9.0:
							_px(img, clx + xx, cly + yy, Color("8a9ab0") if yy > -1 else Color("a8b8c8"))
				_disc(img, clx, cly - 1, 2, Color("f4f8ff"))
				_glow_px(img, clx, cly - 1, 6, Color("e8f4ff"), 0.4)


## Profondeurs : la salle des fils (archives) et la fosse du Léviathan (abysse).
static func _cite_deep(img: Image, rng: RandomNumberGenerator, kind: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var hall := kind == "archives" or kind == "fil"
	_sky(img, rng, [[0.0, Color("06142a") if hall else Color("020810")], [0.6, Color("0a2440") if hall else Color("041020")], [1.0, Color("040c18")]], 0.0)
	if hall:
		# Des milliers de fils de corail lumineux tendus du sol à la voûte, un fil noir au centre.
		for i in range(maxi(30, w / 3)):
			var x := rng.randi_range(0, w)
			var col: Color = [Color("4fe3d2"), Color("8fe0ff"), Color("e86a8a"), Color("b07cff")][rng.randi_range(0, 3)]
			for y in range(0, h, 2):
				_px(img, x + int(sin(float(y) * 0.05 + float(i)) * 2.0), y, Color(col, rng.randf_range(0.25, 0.6)))
		if kind == "fil":
			# Ta ligne : un fil d'or, tiède, plus brillant que tous les autres.
			for y in range(h):
				_px(img, w / 2 + int(sin(float(y) * 0.04) * 2.0), y, Color("ffe08a"))
				_px(img, w / 2 + 1 + int(sin(float(y) * 0.04) * 2.0), y, Color("fff6d0"))
			_glow_px(img, w / 2, int(h * 0.5), int(minf(w, h) * 0.2), Color("ffd070"), 0.3)
		else:
			for y in range(h):
				_px(img, w / 2, y, Color("0a0010"))
				_px(img, w / 2 + 1, y, Color("2a0a3a"))
			_glow_px(img, w / 2, int(h * 0.5), int(minf(w, h) * 0.15), Color("b07cff"), 0.25)
	elif kind == "kraken":
		# L'antre du kraken : grotte noire, tentacules qui sortent des parois, nuages d'encre, deux yeux jaunes.
		for side: int in [0, 1]:
			for y in range(h):
				var k := float(y) / float(h)
				var xe := int(w * (0.18 + 0.08 * sin(k * 6.0 + float(side))))
				if side == 0:
					img.fill_rect(Rect2i(0, y, xe, 1), Color("061420"))
				else:
					img.fill_rect(Rect2i(w - xe, y, xe, 1), Color("061420"))
		for t in range(6):
			var side2 := -1 if t % 2 == 0 else 1
			var p := Vector2(0.0 if side2 < 0 else float(w), rng.randf_range(h * 0.2, h * 0.9))
			var a := 0.0 if side2 < 0 else PI
			var r := float(minf(w, h)) * 0.04
			for d in range(int(w * 0.3)):
				a += sin(float(d) * 0.08 + float(t)) * 0.06
				p += Vector2.from_angle(a)
				var rr := r * (1.0 - float(d) / (w * 0.3))
				for yy in range(-int(rr), int(rr) + 1):
					_px(img, int(p.x), int(p.y) + yy, Color("3a1e4a") if yy < 0 else Color("5a2e6a"))
				if d % 6 == 0 and rr > 2.0:
					_px(img, int(p.x), int(p.y) + int(rr), Color("e8c8d8"))
		for i in range(10):
			_glow_px(img, rng.randi_range(0, w), rng.randi_range(int(h * 0.1), h), int(minf(w, h) * 0.1), Color("0a0612"), 0.5)
		for side3: int in [-1, 1]:
			var ex := w / 2 + side3 * int(w * 0.06)
			_glow_px(img, ex, int(h * 0.4), 8, Color("ffd040"), 0.5)
			_disc(img, ex, int(h * 0.4), 2, Color("fff0a0"))
	elif kind == "fosse":
		# La fosse du Léviathan, sans ses yeux (il s'y tient en personne) : parois de roche, lueur turquoise
		# au fond, points de lumière vivante, bulles.
		_glow_px(img, w / 2, int(h * 0.7), int(minf(w, h) * 0.35), Color("1a6a7a"), 0.35)
		for side4: int in [0, 1]:
			for y in range(h):
				var k4 := float(y) / float(h)
				var xe4 := int(w * (0.14 + 0.07 * sin(k4 * 7.0 + float(side4) * 2.0)))
				if side4 == 0:
					img.fill_rect(Rect2i(0, y, xe4, 1), Color("030a12"))
					_px(img, xe4, y, Color("0e2a3a"))
				else:
					img.fill_rect(Rect2i(w - xe4, y, xe4, 1), Color("030a12"))
					_px(img, w - xe4 - 1, y, Color("0e2a3a"))
		for i in range(int(w * h / 400.0)):
			_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color(0.6, 0.95, 1.0, rng.randf_range(0.15, 0.6)))
		for i in range(maxi(6, w / 30)):
			var gx4 := rng.randi_range(0, w)
			var gy4 := rng.randi_range(int(h * 0.2), h)
			_disc(img, gx4, gy4, 1, Color("aef8ff"))
			_glow_px(img, gx4, gy4, 4, Color("4fe3d2"), 0.3)
	else:
		# La fosse : deux yeux immenses s'allument dans le noir, des bulles montent.
		var ey := int(h * 0.45)
		for side: int in [-1, 1]:
			var ex := w / 2 + side * int(w * 0.14)
			_glow_px(img, ex, ey, int(minf(w, h) * 0.08), Color("6fdccf"), 0.5)
			_disc(img, ex, ey, maxi(3, int(minf(w, h) * 0.025)), Color("e8fbff"))
			img.fill_rect(Rect2i(ex, ey - 3, 1, 7), Color("04121a"))
		for i in range(int(w * h / 300.0)):
			_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color(0.6, 0.9, 1.0, rng.randf_range(0.1, 0.4)))


static func icon(kind: String, col: Color) -> ImageTexture:
	var key := "icon|%s|%s" % [kind, col.to_html()]
	if _cache.has(key):
		return _cache[key]
	var rows: Array = []
	match kind:
		"sparkle":
			rows = ["....#....", "....#....", "...###...", "..#####..", "#########", "..#####..", "...###...", "....#....", "....#...."]
		_:
			rows = ["#######", ".#####.", "..###..", "...#..."]
	var img := Image.create_empty(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(rows.size()):
		for x in range(str(rows[y]).length()):
			if str(rows[y])[x] == "#":
				img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex
