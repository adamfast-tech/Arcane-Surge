class_name ArenaArt
extends RefCounted
## Décor pixel-art de l'arène, généré par code (zone 1 : Bois des Lucioles, de nuit).

const CANOPY := ["13241a", "1a3022", "0f1d15", "162a1e", "1c3626"]


static func build(size: Vector2i, ppm: int, origin: Vector2) -> ImageTexture:
	var img := Image.create_empty(maxi(1, size.x), maxi(1, size.y), false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	img.fill(Color("0d1712"))
	var ax := int(origin.x)
	var ay := int(origin.y)
	var aw := 9 * ppm
	var ah := 16 * ppm

	# Canopée autour de l'arène.
	var blobs := int(float(size.x * size.y) / 700.0)
	for i in range(blobs):
		var c := Vector2i(rng.randi_range(0, size.x - 1), rng.randi_range(0, size.y - 1))
		_disc(img, c, rng.randi_range(3, 11), Color(str(CANOPY[rng.randi_range(0, CANOPY.size() - 1)])))

	# Sol de l'arène : dégradé du sol corrompu (haut) vers l'herbe (bas).
	for y in range(ah):
		var ly := 16.0 - float(y) / float(ppm)
		var col: Color
		if ly > 12.5:
			col = Color("2b2342").lerp(Color("292c40"), (16.0 - ly) / 3.5)
		elif ly > 1.0:
			col = Color("25392d").lerp(Color("2c4a35"), (12.5 - ly) / 11.5)
		else:
			col = Color("3a3550")
		img.fill_rect(Rect2i(ax, ay + y, aw, 1), col)

	# Grain d'herbe.
	for i in range(int(float(aw * ah) / 12.0)):
		var x := ax + rng.randi_range(0, aw - 1)
		var y := ay + rng.randi_range(0, ah - 1)
		var base := _pget(img, x, y)
		_pset(img, x, y, base.lightened(0.09) if rng.randf() < 0.5 else base.darkened(0.14))

	# Veines corrompues dans la zone ennemie.
	for v in range(7):
		var p := Vector2(ax + rng.randf_range(0.0, aw), ay + rng.randf_range(0.0, 3.0 * ppm))
		for s in range(ppm * 2):
			_pset(img, int(p.x), int(p.y), Color("4b2e6b"))
			p += Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(0.2, 1.0))

	# Chemin pavé central (comme les ruines de l'image de référence).
	var tile := maxi(4, int(ppm / 5.0))
	var px0 := ax + int(3.4 * ppm)
	var px1 := ax + int(5.6 * ppm)
	var py0 := ay + int(2.2 * ppm)
	var py1 := ay + int(15.0 * ppm)
	var row := 0
	var yy := py0
	while yy < py1:
		var xx := px0 - (int(tile / 2.0) if row % 2 == 1 else 0)
		while xx < px1:
			var x0 := maxi(xx, px0)
			var x1 := mini(xx + tile - 1, px1)
			if x1 > x0 and rng.randf() > 0.08:
				var stone := Color("464659").lerp(Color("5a5a70"), rng.randf())
				img.fill_rect(Rect2i(x0, yy, x1 - x0, tile - 1), stone)
				_pset(img, x0, yy, stone.lightened(0.15))
				if rng.randf() < 0.3:
					_pset(img, x0 + rng.randi_range(0, maxi(0, x1 - x0 - 1)), yy + tile - 2, Color("4f6b3a"))
			xx += tile
		yy += tile
		row += 1

	# Parvis de pierre derrière la Barrière.
	for i in range(int(aw / 3.0)):
		var x := ax + rng.randi_range(0, aw - 1)
		_pset(img, x, ay + ah - rng.randi_range(1, ppm), Color("2e2a42"))

	# Bordures de l'arène : lisière de mousse.
	for y in range(ah):
		for k in range(2):
			_pset(img, ax - 1 - k, ay + y, Color("0a120e"))
			_pset(img, ax + aw + k, ay + y, Color("0a120e"))
		if rng.randf() < 0.35:
			_pset(img, ax, ay + y, Color("4f6b3a"))
		if rng.randf() < 0.35:
			_pset(img, ax + aw - 1, ay + y, Color("4f6b3a"))

	# Ruines : piliers brisés dans les marges, si la place le permet.
	if ax >= ppm / 2:
		for i in range(6):
			var side := -1 if i % 2 == 0 else 1
			var bx := ax - int(ppm * 0.55) if side < 0 else ax + aw + int(ppm * 0.15)
			var by := ay + int(rng.randf_range(2.0, 14.0) * ppm)
			_pillar(img, bx, by, maxi(4, int(ppm * 0.35)), rng.randi_range(int(ppm * 0.6), int(ppm * 1.3)), rng)

	# Lucioles.
	for i in range(int(float(size.x * size.y) / 2500.0)):
		var x := rng.randi_range(0, size.x - 1)
		var y := rng.randi_range(0, size.y - 1)
		_pset(img, x, y, Color("f2e28b"))
		if rng.randf() < 0.4:
			_pset(img, x + 1, y, Color(0.95, 0.89, 0.55, 0.5))
	return ImageTexture.create_from_image(img)


static func _pillar(img: Image, x: int, y: int, w: int, h: int, rng: RandomNumberGenerator) -> void:
	var stone := Color("4a4860")
	img.fill_rect(Rect2i(x, y - h, w, h), stone)
	img.fill_rect(Rect2i(x, y - h, 1, h), stone.lightened(0.2))
	img.fill_rect(Rect2i(x + w - 1, y - h, 1, h), stone.darkened(0.3))
	var by := y - h
	while by < y:
		img.fill_rect(Rect2i(x, by, w, 1), stone.darkened(0.25))
		by += 4
	for i in range(h):
		if rng.randf() < 0.3:
			_pset(img, x + rng.randi_range(0, w - 1), y - i, Color("5e7f4a"))


static func _disc(img: Image, c: Vector2i, r: int, col: Color) -> void:
	for y in range(-r, r + 1):
		var half := int(sqrt(float(r * r - y * y)))
		var yy := c.y + y
		if yy < 0 or yy >= img.get_height():
			continue
		var x0 := maxi(0, c.x - half)
		var x1 := mini(img.get_width() - 1, c.x + half)
		if x1 >= x0:
			img.fill_rect(Rect2i(x0, yy, x1 - x0 + 1, 1), col)


static func _pget(img: Image, x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return Color.BLACK
	return img.get_pixel(x, y)


static func _pset(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if c.a < 1.0:
		c = img.get_pixel(x, y).lerp(Color(c, 1.0), c.a)
	img.set_pixel(x, y, c)
