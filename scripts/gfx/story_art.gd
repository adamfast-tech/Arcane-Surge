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
	var corrupt := kind in ["nexus", "sylvarche", "lysbourg"]
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
		_pine(img, rng.randi_range(-4, w + 4), int(h * 0.66) + rng.randi_range(-3, 3), rng.randi_range(int(h * 0.12), int(h * 0.2)), far, far_l)
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
	var ff := 20 if kind == "foret" else 8
	if healed or kind == "source":
		ff = 70
	_fireflies(img, rng, int(ff * w / 240.0), int(h * 0.3), h - 4, Color("f2e28b") if not corrupt else Color("d98cff"))


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


# ---------------------------------------------------------------- icônes (glyphes absents des polices)

## « sparkle » : étoile à 4 branches (✦) ; « next » : triangle vers le bas (▼).
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
