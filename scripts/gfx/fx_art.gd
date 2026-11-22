class_name FxArt
extends RefCounted
## Textures pixel-art des effets de sorts, générées par code et mises en cache.

static var _cache: Dictionary = {}


static func _cached(key: String) -> ImageTexture:
	return _cache.get(key, null)


static func _store(key: String, img: Image) -> ImageTexture:
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Boule de feu (12 px) ou météore arcanique (16 px) : anneaux de couleur du cœur vers le bord.
static func orb(kind: String) -> ImageTexture:
	var key := "orb_" + kind
	if _cache.has(key):
		return _cached(key)
	var n := 16 if kind == "meteor" else 12
	var rings: Array = ["fff6c8", "ffd45a", "ff8a2a", "c8402a"]
	if kind == "meteor":
		rings = ["ffffff", "e8d0ff", "b07cff", "8e62e0", "ff9b4a"]
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := (float(n) - 1.0) * 0.5
	for y in range(n):
		for x in range(n):
			# Lumière en haut à droite : le cœur est décalé vers le haut-droit.
			var d := Vector2(float(x) - c - 0.8, float(y) - c + 0.8).length() / (c + 0.5)
			var e := Vector2(float(x) - c, float(y) - c).length() / (c + 0.5)
			if e > 1.0:
				continue
			var i := clampi(int(d * float(rings.size())), 0, rings.size() - 1)
			img.set_pixel(x, y, Color(str(rings[i])))
	# Contour sombre.
	var src := img.duplicate() as Image
	for y in range(n):
		for x in range(n):
			if src.get_pixel(x, y).a > 0.0:
				continue
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + dd
				if q.x >= 0 and q.y >= 0 and q.x < n and q.y < n and src.get_pixel(q.x, q.y).a > 0.0:
					img.set_pixel(x, y, Color("3a1206") if kind != "meteor" else Color("1a1035"))
					break
	return _store(key, img)


## Halo doux (pour les éclairs de lumière, en mélange additif).
## Orbe teinté à la couleur d'un sort (projectiles autres que la Boule de feu).
static func orb_tint(col: Color) -> ImageTexture:
	var key := "orbt_" + col.to_html(false)
	if _cache.has(key):
		return _cached(key)
	var n := 12
	var rings: Array = [Color.WHITE, col.lightened(0.55), col, col.darkened(0.35)]
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := (float(n) - 1.0) * 0.5
	for y in range(n):
		for x in range(n):
			var d := Vector2(float(x) - c - 0.8, float(y) - c + 0.8).length() / (c + 0.5)
			var e := Vector2(float(x) - c, float(y) - c).length() / (c + 0.5)
			if e > 1.0:
				continue
			img.set_pixel(x, y, rings[clampi(int(d * float(rings.size())), 0, rings.size() - 1)])
	var src := img.duplicate() as Image
	for y in range(n):
		for x in range(n):
			if src.get_pixel(x, y).a > 0.0:
				continue
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + dd
				if q.x >= 0 and q.y >= 0 and q.x < n and q.y < n and src.get_pixel(q.x, q.y).a > 0.0:
					img.set_pixel(x, y, col.darkened(0.75))
					break
	return _store(key, img)


static func flash() -> ImageTexture:
	if _cache.has("flash"):
		return _cached("flash")
	var n := 32
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in range(n):
		for x in range(n):
			var d := Vector2(float(x) - 15.5, float(y) - 15.5).length() / 16.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return _store("flash", img)


## Brûlure au sol (disque sombre aux bords irréguliers).
static func scorch() -> ImageTexture:
	if _cache.has("scorch"):
		return _cached("scorch")
	var n := 32
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for y in range(n):
		for x in range(n):
			var d := Vector2(float(x) - 15.5, float(y) - 15.5).length() / 16.0 + rng.randf_range(-0.08, 0.08)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.08, 0.04, 0.05, minf(0.75, a * 1.4)))
	return _store("scorch", img)


## Colonne de lumière : lumineuse au centre, s'efface en haut.
static func beam() -> ImageTexture:
	if _cache.has("beam"):
		return _cached("beam")
	var w := 16
	var h := 64
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var fy := clampf(float(y) / float(h) * 1.4, 0.0, 1.0)
		for x in range(w):
			var fx := 1.0 - absf(float(x) - 7.5) / 8.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(fx * fx * fy, 0.0, 1.0)))
	return _store("beam", img)


## Racine épineuse qui sort du sol (2 variantes, 12×26 px, base en bas).
static func root(variant: int) -> ImageTexture:
	var key := "root_%d" % variant
	if _cache.has(key):
		return _cached(key)
	var w := 12
	var h := 26
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color("1f3a1e")
	var mid := Color("3f6a32")
	var light := Color("8fd16a")
	var bark := Color("5a4030")
	var ph := 0.0 if variant == 0 else 1.7
	for y in range(h):
		var k := float(h - 1 - y) / float(h - 1)
		var cx := 5.5 + sin(k * 5.0 + ph) * 2.2 * k
		var half := lerpf(2.2, 0.4, k)
		for x in range(w):
			var dx := float(x) - cx
			if absf(dx) <= half:
				var c := mid
				if dx > half - 1.0:
					c = light
				elif dx < -half + 1.0:
					c = dark
				if y > h - 5:
					c = bark if dx <= 0.0 else bark.lightened(0.2)
				img.set_pixel(x, y, c)
		# Épines.
		if y % 5 == 2 and y < h - 4:
			var side := 1 if (y / 5) % 2 == 0 else -1
			var tx := int(round(cx + float(side) * (half + 1.0)))
			if tx >= 0 and tx < w:
				img.set_pixel(tx, y, Color("c8f5a0"))
	# Contour.
	var src := img.duplicate() as Image
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.0:
				continue
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + dd
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixel(q.x, q.y).a > 0.0:
					img.set_pixel(x, y, Color("120e1a"))
					break
	return _store(key, img)
