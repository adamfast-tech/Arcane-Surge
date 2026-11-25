class_name WorldArt
extends RefCounted
## Textures pixel-art du décor, générées par code (zone 1 : chaussée en ruine au clair de lune,
## d'après docs/art/style-reference-01.jpg).

const PX_PER_M := 16
## Zone couverte par la texture du sol, en coordonnées logiques (x, y).
const GROUND_MIN := Vector2(-1.0, -1.5)
const GROUND_SIZE := Vector2(11.0, 19.0)
## Zone du décor (1 : Bois des Lucioles, nuit ; 2 : Collines d'Ambre, plein jour ; 3 : Marais Murmurants, crépuscule).
static var zone := 1


## Zone 2 : décor de jour. Verts -> herbe sèche dorée, bleus et violets -> grès ocre, le tout éclairci.
static func _warm(img: Image, grass_h: float = 0.115, lift: float = 1.0) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var h := c.h
			var out: Color
			if c.s > 0.12 and h > 0.18 and h < 0.5:
				out = Color.from_hsv(grass_h + (h - 0.18) * 0.12, clampf(c.s * 0.8 + 0.12, 0.0, 0.6), clampf(c.v * 1.2 * lift + 0.04, 0.0, 0.8), c.a)
			elif h >= 0.5 and h < 0.9 or c.s <= 0.12:
				out = Color.from_hsv(0.075 + 0.02 * c.v, clampf(c.s * 0.35 + 0.16, 0.0, 0.5), clampf(c.v * 1.15 * lift + 0.06, 0.0, 0.8), c.a)
			else:
				out = Color.from_hsv(h, c.s, clampf(c.v * 1.15, 0.0, 1.0), c.a)
			img.set_pixel(x, y, out)


## Zone 3 : marais au crépuscule. Herbe -> vert-gris, pierre -> gris violacé, teintes rabattues.
static func _swamp(img: Image, lift: float = 1.0) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var h := c.h
			var out: Color
			if c.s > 0.12 and h > 0.18 and h < 0.5:
				out = Color.from_hsv(0.28 + (h - 0.18) * 0.1, clampf(c.s * 0.45 + 0.05, 0.0, 0.4), clampf(c.v * 1.05 * lift + 0.04, 0.0, 0.7), c.a)
			elif h >= 0.5 and h < 0.9 or c.s <= 0.12:
				out = Color.from_hsv(0.78, clampf(c.s * 0.35 + 0.06, 0.0, 0.3), clampf(c.v * 1.0 * lift + 0.05, 0.0, 0.7), c.a)
			else:
				out = Color.from_hsv(h, c.s * 0.7, c.v, c.a)
			img.set_pixel(x, y, out)


## Zone 4 : Pics Gelés de nuit. Herbe -> neige bleutée, pierre -> granit bleu glacier, teintes froides.
static func _frost(img: Image, lift: float = 1.0) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var h := c.h
			var out: Color
			if c.s > 0.12 and h > 0.18 and h < 0.5:
				out = Color.from_hsv(0.56, clampf(c.s * 0.25 + 0.06, 0.0, 0.3), clampf(c.v * 1.6 * lift + 0.18, 0.0, 0.92), c.a)
			elif h >= 0.5 and h < 0.9 or c.s <= 0.12:
				out = Color.from_hsv(0.6, clampf(c.s * 0.4 + 0.12, 0.0, 0.45), clampf(c.v * 1.08 * lift + 0.05, 0.0, 0.75), c.a)
			else:
				out = Color.from_hsv(h, c.s * 0.6, c.v, c.a)
			img.set_pixel(x, y, out)


## Zone 5 : Désert de Verre. Herbe -> sable doré, pierre -> grès ocre, éclats de verre turquoise.
static func _desert(img: Image, lift: float = 1.0) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var h := c.h
			var out: Color
			if c.s > 0.12 and h > 0.18 and h < 0.5:
				out = Color.from_hsv(0.1 + (h - 0.18) * 0.04, clampf(c.s * 0.35 + 0.3, 0.0, 0.55), clampf(c.v * 0.95 * lift + 0.2, 0.0, 0.78), c.a)
			elif h >= 0.5 and h < 0.9 or c.s <= 0.12:
				out = Color.from_hsv(0.07 + 0.02 * c.v, clampf(c.s * 0.3 + 0.28, 0.0, 0.5), clampf(c.v * 1.05 * lift + 0.08, 0.0, 0.74), c.a)
			else:
				out = Color.from_hsv(0.48, clampf(c.s * 0.7, 0.0, 0.7), clampf(c.v * 1.1, 0.0, 1.0), c.a)
			img.set_pixel(x, y, out)


## Zone 6 : Forêt Cendrée. Herbe -> cendre grise semée de braises, pierre -> basalte, feuillage calciné.
static func _cinder(img: Image, lift: float = 1.0) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var h := c.h
			var out: Color
			if c.s > 0.12 and h > 0.18 and h < 0.5:
				out = Color.from_hsv(0.03, clampf(c.s * 0.25 + 0.08, 0.0, 0.3), clampf(c.v * 0.7 * lift + 0.06, 0.0, 0.5), c.a)
				if (x * 7 + y * 13) % 97 == 0:
					out = Color.from_hsv(0.06, 0.85, 0.95, c.a)
			elif h >= 0.5 and h < 0.9 or c.s <= 0.12:
				out = Color.from_hsv(0.02, clampf(c.s * 0.2 + 0.1, 0.0, 0.3), clampf(c.v * 0.85 * lift + 0.03, 0.0, 0.6), c.a)
			else:
				out = Color.from_hsv(0.05, clampf(c.s, 0.0, 1.0), clampf(c.v * 1.1, 0.0, 1.0), c.a)
			img.set_pixel(x, y, out)


## Zone 7 : Cité Engloutie. Herbe -> algues turquoise, pierre -> pierre bleutée couverte de corail.
static func _abyss(img: Image, lift: float = 1.0) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var h := c.h
			var out: Color
			if c.s > 0.12 and h > 0.18 and h < 0.5:
				out = Color.from_hsv(0.46 + (h - 0.18) * 0.1, clampf(c.s * 0.6 + 0.2, 0.0, 0.7), clampf(c.v * 0.95 * lift + 0.04, 0.0, 0.7), c.a)
				if (x * 11 + y * 7) % 89 == 0:
					out = Color.from_hsv(0.95, 0.5, 0.85, c.a)
			elif h >= 0.5 and h < 0.9 or c.s <= 0.12:
				out = Color.from_hsv(0.56, clampf(c.s * 0.4 + 0.2, 0.0, 0.5), clampf(c.v * 0.9 * lift + 0.03, 0.0, 0.65), c.a)
			else:
				out = Color.from_hsv(0.5, clampf(c.s * 0.6, 0.0, 0.7), clampf(c.v, 0.0, 1.0), c.a)
			img.set_pixel(x, y, out)


## Recoloriage du décor selon la zone (2 : jour, 3 : marais, 4 : glace, 5 : désert, 6 : cendres, 7 : abysses).
static func _zone_tint(img: Image, warm_h: float = 0.115, lift: float = 1.0) -> void:
	match zone:
		7:
			_abyss(img, lift)
		6:
			_cinder(img, lift)
		2:
			_warm(img, warm_h, lift)
		3:
			_swamp(img)
		4:
			_frost(img, lift)
		5:
			_desert(img, lift)


static func _tex(img: Image, mipmaps: bool = false) -> ImageTexture:
	if mipmaps:
		img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if c.a < 1.0:
		c = img.get_pixel(x, y).lerp(Color(c, 1.0), c.a)
	img.set_pixel(x, y, c)


static func _pget(img: Image, x: int, y: int) -> Color:
	return img.get_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1))


static func _disc(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(-r, r + 1):
		var half := int(sqrt(float(r * r - y * y)))
		for x in range(-half, half + 1):
			_px(img, cx + x, cy + y, c)


## Sol de l'arène : herbe au clair de lune, chemin pavé, sol corrompu près du Nexus, parvis.
## La ligne 0 correspond au fond de l'arène (y logique maximal).
## healed : la forêt guérie (Sylvarche purifiée) a une herbe plus verte et des veines dorées.
static func ground_texture(healed: bool = false) -> ImageTexture:
	var w := int(GROUND_SIZE.x * PX_PER_M)
	var h := int(GROUND_SIZE.y * PX_PER_M)
	var pal := scene_palette(scene) if zone == 1 else {}
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for row in range(h):
		var ly := GROUND_MIN.y + GROUND_SIZE.y - (float(row) + 0.5) / PX_PER_M
		var col: Color
		if ly > 12.8:
			col = Color("2c2a48").lerp(Color("2a3a3a"), clampf((16.5 - ly) / 3.7, 0.0, 1.0))
		elif ly > 1.0:
			col = Color("2a4a36").lerp(Color("35593f"), clampf((12.8 - ly) / 11.8, 0.0, 1.0))
			if not pal.is_empty():
				col = (pal["grass"] as Color).lerp((pal["grass"] as Color).lightened(0.15), clampf((12.8 - ly) / 11.8, 0.0, 1.0))
			if healed:
				col = col.lerp(Color("3f7a3a"), 0.45)
		else:
			col = Color("3b3854")
		img.fill_rect(Rect2i(0, row, w, 1), col)
	# Grain de l'herbe et touffes.
	for i in range(w * h / 5):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, h - 1)
		var b := _pget(img, x, y)
		_px(img, x, y, b.lightened(0.10) if rng.randf() < 0.55 else b.darkened(0.16))
	for i in range(w * h / 60):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, h - 1)
		var b := _pget(img, x, y)
		_px(img, x, y, b.lightened(0.22))
		_px(img, x, y - 1, b.lightened(0.14))
	# Petites fleurs (blanc lunaire, violet, jaune).
	var flowers := [Color("e8e4ff"), Color("b89cf0"), Color("f2e28b"), Color("cfe8ff")]
	for i in range(w * h / (70 if healed else 150)):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(int(3.0 * PX_PER_M), h - 1)
		_px(img, x, y, flowers[rng.randi_range(0, flowers.size() - 1)])
	# Détails du sol propres au lieu (zone 1).
	match scene if zone == 1 else "":
		"lisiere":
			# Ornières de charrettes le long du chemin.
			for rx in [int((3.8 - GROUND_MIN.x) * PX_PER_M), int((5.2 - GROUND_MIN.x) * PX_PER_M)]:
				for y in range(int(3.0 * PX_PER_M), h - int(2.0 * PX_PER_M)):
					_px(img, rx + int(sin(float(y) * 0.05) * 1.5), y, Color("2a2218"))
		"clairiere":
			# Feuilles mortes et éclats de bois.
			var lc := [Color("8a5a2a"), Color("a8702a"), Color("c88a3a"), Color("6a4a2a")]
			for i in range(w * h / 45):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), lc[rng.randi_range(0, 3)])
		"roncier", "sylvarche":
			# Vrilles de ronces (ou racines) qui traversent le sol.
			for v2 in range(22):
				var p2 := Vector2(rng.randf_range(0.0, float(w)), rng.randf_range(0.0, float(h)))
				var d2 := Vector2.from_angle(rng.randf_range(0.0, TAU))
				for k in range(60):
					_px(img, int(p2.x), int(p2.y), Color("2a1430") if scene == "roncier" else Color("3a2a22"))
					if k % 5 == 0:
						_px(img, int(p2.x) + 1, int(p2.y), Color("8e62e0") if scene == "roncier" else Color("5a4030"))
					d2 = d2.rotated(rng.randf_range(-0.3, 0.3))
					p2 += d2
		"fougeres":
			# Pousses de fougère et reflets de lune.
			for i in range(w * h / 70):
				var fx := rng.randi_range(0, w - 1)
				var fy := rng.randi_range(0, h - 1)
				_px(img, fx, fy, Color("3f7a4a"))
				_px(img, fx + 1, fy - 1, Color("5f9a5a"))
			for i in range(w * h / 120):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color("b8c8ff"))
		"cercle":
			# Fleurs de fée, roses et blanches.
			for i in range(w * h / 28):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(int(2.0 * PX_PER_M), h - 1), Color("f7a8e0") if rng.randf() < 0.6 else Color("ffe8f8"))
		"source":
			# Flaques claires.
			for i in range(18):
				var pc := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(int(2.0 * PX_PER_M), h - int(2.0 * PX_PER_M)))
				_disc(img, pc.x, pc.y, rng.randi_range(2, 5), Color("2f6a7a"))
				_px(img, pc.x - 1, pc.y - 1, Color("9ff0ff"))
		"coeur":
			# Éclats de cristal et veines du Surge partout.
			for v3 in range(30):
				var p3 := Vector2(rng.randf_range(0.0, float(w)), rng.randf_range(0.0, float(h)))
				for k in range(50):
					_px(img, int(p3.x), int(p3.y), Color("5b3a8a") if k % 6 != 0 else Color("d98cff"))
					p3 += Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	# Veines corrompues dans la zone ennemie.
	for v in range(10):
		var p := Vector2(rng.randf_range(0.0, float(w)), rng.randf_range(0.0, 3.0 * PX_PER_M))
		for s in range(70):
			if healed:
				_px(img, int(p.x), int(p.y), Color("8a7a2a") if s % 7 != 0 else Color("f2e28b"))
			else:
				_px(img, int(p.x), int(p.y), Color("5b3a8a") if s % 7 != 0 else Color("b07cff"))
			p += Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(0.3, 1.0))
	# Chemin pavé central.
	var x0 := int((3.35 - GROUND_MIN.x) * PX_PER_M)
	var x1 := int((5.65 - GROUND_MIN.x) * PX_PER_M)
	var y_top := int((GROUND_MIN.y + GROUND_SIZE.y - 14.3) * PX_PER_M)
	var y_bot := int((GROUND_MIN.y + GROUND_SIZE.y - 1.0) * PX_PER_M)
	var path_kind := str(pal.get("path", "cobbles"))
	if path_kind == "dirt":
		# Chemin de terre battue, bords irréguliers.
		for y in range(y_top, y_bot):
			var wob := int(sin(float(y) * 0.07) * 3.0)
			for x in range(x0 - 4 + wob, x1 + 4 + wob):
				var edge := mini(x - (x0 - 4 + wob), (x1 + 4 + wob) - x)
				if edge < 3 and rng.randf() < 0.5:
					continue
				var dc := Color("4a3e30") if rng.randf() < 0.7 else Color("5a4a38")
				_px(img, x, y, dc if rng.randf() < 0.92 else Color("6a5a48"))
	elif path_kind == "moss":
		_cobbles(img, rng, Rect2i(x0, y_top, x1 - x0, y_bot - y_top), 5)
		for i in range((x1 - x0) * (y_bot - y_top) / 3):
			_px(img, rng.randi_range(x0, x1), rng.randi_range(y_top, y_bot), Color("3f6a44") if rng.randf() < 0.6 else Color("4f7a4a"))
	elif path_kind == "grass":
		# Pas de chemin : l'herbe foulée, un peu plus claire.
		for i in range((x1 - x0) * (y_bot - y_top) / 2):
			var gx := rng.randi_range(x0, x1)
			var gy := rng.randi_range(y_top, y_bot)
			_px(img, gx, gy, _pget(img, gx, gy).lightened(0.08))
	else:
		_cobbles(img, rng, Rect2i(x0, y_top, x1 - x0, y_bot - y_top), 5)
	# Parvis derrière la Barrière : grandes dalles.
	_cobbles(img, rng, Rect2i(0, y_bot, w, h - y_bot), 8)
	# Bordures de la chaussée (pierres de taille, mousse).
	var ex0 := int((0.0 - GROUND_MIN.x) * PX_PER_M)
	var ex1 := int((9.0 - GROUND_MIN.x) * PX_PER_M)
	if pal.is_empty():
		_cobbles(img, rng, Rect2i(0, 0, ex0, h), 6)
		_cobbles(img, rng, Rect2i(ex1, 0, w - ex1, h), 6)
	else:
		# Au sol de la forêt : de l'herbe jusqu'au bord, pas de pierres de taille.
		for r2 in [Rect2i(0, 0, ex0, y_bot), Rect2i(ex1, 0, w - ex1, y_bot)]:
			for y in range(r2.position.y, r2.end.y):
				for x in range(r2.position.x, r2.end.x):
					_px(img, x, y, (pal["moss"] as Color).lightened(0.05) if rng.randf() < 0.6 else (pal["moss"] as Color).darkened(0.1))
	for y in range(h):
		_px(img, ex0 - 1, y, Color("1a1f2a"))
		_px(img, ex1, y, Color("1a1f2a"))
		for k in range(2):
			if rng.randf() < 0.45:
				_px(img, ex0 - 3 - k, y, Color("4f7a3a"))
			if rng.randf() < 0.45:
				_px(img, ex1 + 2 + k, y, Color("4f7a3a"))
	_zone_tint(img)
	return _tex(img, true)


static func _cobbles(img: Image, rng: RandomNumberGenerator, r: Rect2i, tile: int) -> void:
	var row := 0
	var y := r.position.y
	while y < r.end.y:
		var x := r.position.x - (tile / 2 if row % 2 == 1 else 0)
		while x < r.end.x:
			var a := maxi(x, r.position.x)
			var b := mini(x + tile - 1, r.end.x)
			var hh := mini(tile - 1, r.end.y - y)
			if b > a and hh > 0 and rng.randf() > 0.06:
				var stone := Color("4a4a60").lerp(Color("6a6a84"), rng.randf())
				img.fill_rect(Rect2i(a, y, b - a, hh), stone)
				img.fill_rect(Rect2i(a, y, b - a, 1), stone.lightened(0.18))
				img.fill_rect(Rect2i(a, y + hh - 1, b - a, 1), stone.darkened(0.25))
				if rng.randf() < 0.35:
					_px(img, a + rng.randi_range(0, maxi(0, b - a - 1)), y + hh - 1, Color("5f8a44"))
				if rng.randf() < 0.15:
					_px(img, a + rng.randi_range(0, maxi(0, b - a - 1)), y + rng.randi_range(0, hh - 1), Color("7faa4a"))
			x += tile
		y += tile
		row += 1


## Blocs de pierre (murs de la chaussée, piliers, portails, tours) — à répéter.
static func stone_texture() -> ImageTexture:
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	img.fill(Color("26243a"))
	for by in range(4):
		var off := 0 if by % 2 == 0 else 8
		for bx in range(-1, 3):
			var x := bx * 16 + off
			var c := Color("4c4a64").lerp(Color("66647e"), rng.randf())
			img.fill_rect(Rect2i(x + 1, by * 8 + 1, 14, 6), c)
			img.fill_rect(Rect2i(x + 1, by * 8 + 1, 14, 1), c.lightened(0.2))
			img.fill_rect(Rect2i(x + 1, by * 8 + 6, 14, 1), c.darkened(0.25))
			for k in range(3):
				_px(img, (x + 2 + rng.randi_range(0, 11)) % 32, by * 8 + 2 + rng.randi_range(0, 3), c.darkened(0.12))
	for i in range(26):
		var x := rng.randi_range(0, 31)
		var y := rng.randi_range(0, 31)
		_px(img, x, y, Color("4f7a3a"))
		if rng.randf() < 0.5:
			_px(img, x, y + 1, Color("3f6a32"))
	_zone_tint(img)
	return _tex(img, true)


## Roche des falaises, sombre et moussue.
static func rock_texture() -> ImageTexture:
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	img.fill(Color("23263a"))
	for i in range(220):
		var x := rng.randi_range(0, 31)
		var y := rng.randi_range(0, 31)
		_px(img, x, y, Color("2f3350") if rng.randf() < 0.6 else Color("1a1c2c"))
	for i in range(60):
		_px(img, rng.randi_range(0, 31), rng.randi_range(0, 31), Color("35553a"))
	_zone_tint(img, 0.115, 0.85)
	return _tex(img, true)


## Herbe sombre du haut des falaises.
static func moss_texture() -> ImageTexture:
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	img.fill(Color("22402e"))
	for i in range(300):
		_px(img, rng.randi_range(0, 31), rng.randi_range(0, 31), Color("2e5238") if rng.randf() < 0.6 else Color("1a3022"))
	for i in range(8):
		_px(img, rng.randi_range(0, 31), rng.randi_range(0, 31), Color("d8d4f8"))
	_zone_tint(img)
	return _tex(img, true)


## Trois sapins (atlas horizontal 3 × 20×44 px).
static func pine_texture() -> ImageTexture:
	var fw := 20
	var fh := 44
	var img := Image.create_empty(fw * 3, fh, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var dark := [Color("0f2420"), Color("12281f"), Color("102a26")]
	var mid := [Color("1d3d33"), Color("1f4336"), Color("1a3a34")]
	var lit := [Color("3a6a5a"), Color("3f7058"), Color("3a6670")]
	for v in range(3):
		var ox := v * fw
		var cx := ox + fw / 2
		img.fill_rect(Rect2i(cx - 1, fh - 7, 2, 7), Color("2a1e18"))
		var layers := 5 + v
		for l in range(layers):
			var top := 2 + int(float(l) * float(fh - 12) / float(layers))
			var bottom := top + 10 + l
			for y in range(top, mini(bottom, fh - 5)):
				var half := int(float(y - top + 1) * (0.45 + 0.05 * float(v)) + 1.0)
				half = mini(half, fw / 2 - 1)
				for x in range(-half, half + 1):
					var c: Color = mid[v]
					if x < -half + 2:
						c = dark[v]
					elif x > half - 2 and y % 3 != 0:
						c = lit[v]
					if absi(x) == half and rng.randf() < 0.4:
						continue
					_px(img, cx + x, y, c)
		_px(img, cx, 1, lit[v])
	_zone_tint(img, 0.2, 0.9)
	return _tex(img)


## Ciel nocturne : dégradé, étoiles, nuages fins et pleine lune.
static func sky_texture() -> ImageTexture:
	var w := 160
	var h := 120
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	for y in range(h):
		var k := float(y) / float(h - 1)
		img.fill_rect(Rect2i(0, y, w, 1), Color("070818").lerp(Color("3a3478"), pow(k, 1.6)))
	for i in range(170):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, int(h * 0.8))
		_px(img, x, y, Color(0.9, 0.9, 1.0, rng.randf_range(0.35, 1.0)))
	for i in range(14):
		var y := rng.randi_range(int(h * 0.3), h - 10)
		var x := rng.randi_range(-20, w)
		var len := rng.randi_range(18, 50)
		for s in range(len):
			_px(img, x + s, y + int(sin(float(s) * 0.2) * 1.5), Color(0.62, 0.6, 0.9, 0.25))
	# Lune (avec halo et cratères).
	var mx := int(w * 0.72)
	var my := int(h * 0.22)
	for r in range(18, 9, -1):
		_disc(img, mx, my, r, Color(0.75, 0.75, 1.0, 0.05))
	_disc(img, mx, my, 9, Color("e8e4d0"))
	_disc(img, mx + 2, my - 2, 6, Color("f6f2e2"))
	for c in [Vector2i(-3, 2), Vector2i(3, 3), Vector2i(-1, -4), Vector2i(4, -1)]:
		_px(img, mx + c.x, my + c.y, Color("c8c2b0"))
		_px(img, mx + c.x + 1, my + c.y, Color("c8c2b0"))
	return _tex(img)


## Chaîne de montagnes (silhouette avec transparence au-dessus de la crête).
static func mountains_texture(seed_value: int, base: Color, light: Color) -> ImageTexture:
	var w := 256
	var h := 72
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var ridge: Array[float] = []
	var y := float(h) * 0.5
	var slope := 0.0
	for x in range(w):
		slope = clampf(slope + rng.randf_range(-0.35, 0.35), -1.4, 1.4)
		if y < h * 0.12 or y > h * 0.8:
			slope = -slope
		y = clampf(y + slope, h * 0.08, h * 0.85)
		ridge.append(y)
	for x in range(w):
		var top := int(ridge[x])
		for yy in range(top, h):
			var c := base
			if yy - top < 2 and x > 0 and ridge[x] < ridge[x - 1]:
				c = light
			_px(img, x, yy, c)
	return _tex(img)


## Tour du Croissant : silhouette du château, fenêtres éclairées, croissant au sommet.
static func castle_texture() -> ImageTexture:
	return _tex(castle_image())


static func castle_image() -> Image:
	var w := 64
	var h := 96
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var body := Color("1c1a33")
	var edge := Color("34305a")
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	# Remparts et tours.
	var towers := [[4, 52, 10], [16, 40, 9], [26, 14, 12], [40, 36, 10], [52, 50, 9]]
	img.fill_rect(Rect2i(0, 66, w, h - 66), body)
	for t in towers:
		var x: int = t[0]
		var top: int = t[1]
		var tw: int = t[2]
		img.fill_rect(Rect2i(x, top, tw, h - top), body)
		img.fill_rect(Rect2i(x + tw - 1, top, 1, h - top), edge)
		for c in range(0, tw, 3):
			img.fill_rect(Rect2i(x + c, top - 2, 2, 2), body)
		for k in range(4):
			if rng.randf() < 0.8:
				_px(img, x + rng.randi_range(2, tw - 3), top + 6 + k * 9 + rng.randi_range(0, 3), Color("f2c46b"))
	# Flèche centrale et croissant.
	for y in range(2, 16):
		var half := int(float(y) / 5.0)
		img.fill_rect(Rect2i(32 - half, y, half * 2 + 1, 1), body)
	for a in range(0, 360, 6):
		var r := deg_to_rad(float(a))
		var px := 32 + int(cos(r) * 5.0)
		var py := 6 + int(sin(r) * 5.0)
		if cos(r) < 0.3:
			_px(img, px, py, Color("cfc8ff"))
	return img


## Bruit doux et répétable pour la brume.
static func mist_texture() -> ImageTexture:
	var n := 64
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 9
	noise.frequency = 0.06
	noise.fractal_octaves = 3
	for y in range(n):
		for x in range(n):
			# Échantillonnage sur un tore pour un motif sans couture.
			var ax := float(x) / n * TAU
			var ay := float(y) / n * TAU
			var v := noise.get_noise_3d(cos(ax) * 10.0, sin(ax) * 10.0 + cos(ay) * 10.0, sin(ay) * 10.0)
			var g := clampf(v * 0.5 + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(g, g, g, 1.0))
	return _tex(img)


## Ombre au sol (ellipse douce).
static func blob_texture() -> ImageTexture:
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(16):
		for x in range(16):
			var d := Vector2((x - 7.5) / 7.5, (y - 7.5) / 7.5).length()
			if d < 1.0:
				img.set_pixel(x, y, Color(0.02, 0.02, 0.06, 0.55 * (1.0 - d * d)))
	return _tex(img)


## Bannière bleue à sigle (comme sur l'image de référence) et flamme de torche.
static func banner_texture() -> ImageTexture:
	var img := Image.create_empty(12, 26, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(5, 0, 2, 26), Color("5a3e26"))
	img.fill_rect(Rect2i(1, 2, 10, 1), Color("7a5636"))
	img.fill_rect(Rect2i(1, 3, 10, 15), Color("2a3a8a"))
	img.fill_rect(Rect2i(1, 3, 1, 15), Color("1e2a66"))
	for y in range(6, 14):
		_px(img, 6, y, Color("d8d4f8"))
	for x in range(4, 9):
		_px(img, x, 9, Color("d8d4f8"))
	_px(img, 5, 7, Color("d8d4f8"))
	_px(img, 7, 7, Color("d8d4f8"))
	for x in range(1, 11):
		if x % 3 != 0:
			_px(img, x, 18, Color("2a3a8a"))
	return _tex(img)


static func flame_texture() -> ImageTexture:
	var img := Image.create_empty(5, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rows := ["..y..", ".yoy.", ".ooy.", "yowoy", "yowoy", ".ooo.", "..o..", "..b.."]
	var pal := {"y": Color("ffd45a"), "o": Color("ff8a2a"), "w": Color("fff6d8"), "b": Color("5a3e26")}
	for y in range(rows.size()):
		for x in range(5):
			var ch: String = rows[y][x]
			if pal.has(ch):
				img.set_pixel(x, y, pal[ch])
	return _tex(img)


## Toile de fond peinte derrière la scène 3D (taille du SubViewport) : ciel étoilé, lune,
## montagnes, Tour du Croissant et son faisceau, nappes de brume vers le bas.
static func backdrop(size: Vector2i) -> ImageTexture:
	if zone == 2:
		return _backdrop_day(size)
	if zone == 3:
		return _backdrop_swamp(size)
	if zone == 4:
		return _backdrop_frost(size)
	if zone == 5:
		return _backdrop_desert(size)
	if zone == 6:
		return _backdrop_ash(size)
	if zone == 7:
		return _backdrop_abyss(size)
	var w := maxi(8, size.x)
	var h := maxi(8, size.y)
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1701
	var stops := [[0.0, Color("04050f")], [0.32, Color("12123a")], [0.55, Color("23224f")], [0.72, Color("2d2c5e")], [1.0, Color("242454")]]
	for y in range(h):
		var k := float(y) / float(h - 1)
		var c: Color = stops[0][1]
		for i in range(stops.size() - 1):
			var a: Array = stops[i]
			var b: Array = stops[i + 1]
			if k >= float(a[0]) and k <= float(b[0]):
				c = (a[1] as Color).lerp(b[1], (k - float(a[0])) / (float(b[0]) - float(a[0])))
		img.fill_rect(Rect2i(0, y, w, 1), c)
	for i in range(w * h / 260):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, int(h * 0.5))
		_px(img, x, y, Color(0.92, 0.92, 1.0, rng.randf_range(0.3, 1.0)))
		if rng.randf() < 0.05:
			_px(img, x + 1, y, Color(0.92, 0.92, 1.0, 0.4))
			_px(img, x - 1, y, Color(0.92, 0.92, 1.0, 0.4))
			_px(img, x, y + 1, Color(0.92, 0.92, 1.0, 0.4))
			_px(img, x, y - 1, Color(0.92, 0.92, 1.0, 0.4))
	# Lune et halo.
	var mr := maxi(7, int(minf(w, h) * 0.045))
	var mx := int(w * 0.8)
	var my := int(h * 0.11)
	for r in range(mr * 3, mr, -1):
		_disc(img, mx, my, r, Color(0.7, 0.72, 1.0, 0.035))
	_disc(img, mx, my, mr, Color("e8e4d0"))
	_disc(img, mx + mr / 4, my - mr / 4, int(mr * 0.65), Color("f6f2e2"))
	for c in [Vector2i(-mr / 3, mr / 4), Vector2i(mr / 3, mr / 3), Vector2i(-mr / 6, -mr / 2)]:
		_px(img, mx + c.x, my + c.y, Color("c8c2b0"))
		_px(img, mx + c.x + 1, my + c.y, Color("c8c2b0"))
	# Nuages fins.
	for i in range(int(w / 18.0)):
		var y := rng.randi_range(int(h * 0.18), int(h * 0.45))
		var x := rng.randi_range(-30, w)
		var len := rng.randi_range(20, 70)
		for sx in range(len):
			_px(img, x + sx, y + int(sin(float(sx) * 0.15) * 2.0), Color(0.55, 0.55, 0.9, 0.22))
	# Montagnes lointaines.
	_ridge(img, rng, int(h * 0.36), int(h * 0.12), Color("1f1e48"), Color("3a3a78"))
	var forest_scene := scene != "" and scene != "pont"
	# Tour du Croissant (avec faisceau violet) : on la voit depuis le pont.
	var castle := castle_image() if not forest_scene else Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
	var cx := int(w * 0.66) - castle.get_width() / 2
	var cy := int(h * 0.5) - castle.get_height()
	for y in range(0, cy + 14):
		var a := 0.22 * (1.0 - float(y) / float(cy + 14))
		for dx in range(-1, 2):
			_px(img, cx + 32 + dx, y, Color(0.75, 0.5, 1.0, a * (1.0 if dx == 0 else 0.5)))
	img.blend_rect(castle, Rect2i(Vector2i.ZERO, castle.get_size()), Vector2i(cx, cy))
	# Montagnes proches et brume.
	_ridge(img, rng, int(h * 0.5), int(h * 0.08), Color("17163a"), Color("2a2a5c"))
	if forest_scene:
		# L'horizon du lieu, puis la lisière de sapins devant.
		_backdrop_scene(img, rng, scene)
		for i in range(int(w / 4.0)):
			var px2 := rng.randi_range(-4, w + 4)
			var ph := rng.randi_range(int(h * 0.05), int(h * 0.11))
			var pb := int(h * 0.58) + rng.randi_range(-2, 3)
			for yy in range(ph):
				var half := int(float(yy) * 0.35) + 1
				img.fill_rect(Rect2i(px2 - half, pb - ph + yy, half * 2 + 1, 1), Color("0e1828") if scene not in ["coeur", "sylvarche", "roncier"] else Color("1a1028"))
	for i in range(int(w * h / 900.0)):
		var y := rng.randi_range(int(h * 0.52), h - 1)
		var x := rng.randi_range(-40, w)
		var len := rng.randi_range(30, 90)
		for sx in range(len):
			_px(img, x + sx, y, Color(0.5, 0.5, 0.85, 0.12))
	return _tex(img)


## Collines d'Ambre : ciel de midi, soleil, nuages blancs, collines ocre et fort orc au loin.
static func _backdrop_day(size: Vector2i) -> ImageTexture:
	var w := maxi(8, size.x)
	var h := maxi(8, size.y)
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2207
	var stops := [[0.0, Color("3f86c8")], [0.3, Color("6fb0e0")], [0.48, Color("b8d8e8")], [0.58, Color("f0d8a0")], [1.0, Color("c89858")]]
	for y in range(h):
		var k := float(y) / float(h - 1)
		var c: Color = stops[0][1]
		for i in range(stops.size() - 1):
			var a: Array = stops[i]
			var b: Array = stops[i + 1]
			if k >= float(a[0]) and k <= float(b[0]):
				c = (a[1] as Color).lerp(b[1], (k - float(a[0])) / (float(b[0]) - float(a[0])))
		img.fill_rect(Rect2i(0, y, w, 1), c)
	# Soleil et halo.
	var sr := maxi(7, int(minf(w, h) * 0.05))
	var sx := int(w * 0.24)
	var sy := int(h * 0.1)
	for r in range(sr * 4, sr, -1):
		_disc(img, sx, sy, r, Color(1.0, 0.95, 0.75, 0.03))
	_disc(img, sx, sy, sr, Color("fff2c0"))
	_disc(img, sx, sy, int(sr * 0.7), Color("fffbe8"))
	# Nuages blancs en bandes.
	for i in range(maxi(3, int(w / 40.0))):
		var cy := rng.randi_range(int(h * 0.06), int(h * 0.36))
		var cx := rng.randi_range(-40, w)
		var len := rng.randi_range(30, 90)
		for k in range(3):
			var yy := cy + k * 2
			var off := k * 6
			for dx in range(off, len - off):
				_px(img, cx + dx, yy, Color(1.0, 1.0, 1.0, 0.55 - 0.12 * float(k)))
		for dx in range(4, len - 4):
			_px(img, cx + dx, cy + 6, Color(0.75, 0.8, 0.9, 0.25))
	# Collines lointaines bleutées, puis collines d'ambre.
	_ridge(img, rng, int(h * 0.42), int(h * 0.05), Color("8aa0b8"), Color("b0c4d4"))
	# Fort orc : palissade et tour sur la crête.
	var fx := int(w * 0.68)
	var fy := int(h * 0.44)
	var fort := Color("5a4838")
	for k in range(-18, 19):
		var ph := 6 + (3 if absi(k) % 3 == 0 else 0)
		img.fill_rect(Rect2i(fx + k, fy - ph, 1, ph), fort)
	img.fill_rect(Rect2i(fx - 4, fy - 20, 8, 20), fort)
	img.fill_rect(Rect2i(fx - 6, fy - 22, 12, 3), fort)
	img.fill_rect(Rect2i(fx, fy - 30, 1, 8), Color("3a2a20"))
	img.fill_rect(Rect2i(fx + 1, fy - 30, 5, 3), Color("a82a2a"))
	_ridge(img, rng, int(h * 0.5), int(h * 0.06), Color("b07a40"), Color("e8b060"))
	_ridge(img, rng, int(h * 0.56), int(h * 0.05), Color("8a5a2a"), Color("c88a40"))
	# Brume de chaleur au pied des collines.
	for i in range(int(w * h / 1100.0)):
		var y := rng.randi_range(int(h * 0.55), h - 1)
		var x := rng.randi_range(-40, w)
		var len := rng.randi_range(30, 90)
		for dx in range(len):
			_px(img, x + dx, y, Color(1.0, 0.9, 0.7, 0.1))
	return _tex(img)


## Marais Murmurants : ciel de crépuscule violet pâle, saules en silhouette, maisons sur pilotis
## et lanternes, brume au ras de l'eau.
static func _backdrop_swamp(size: Vector2i) -> ImageTexture:
	var w := maxi(8, size.x)
	var h := maxi(8, size.y)
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3303
	var stops := [[0.0, Color("1e1a2e")], [0.3, Color("4a3e62")], [0.5, Color("9c8ab4")], [0.62, Color("c9d1c4")], [1.0, Color("2f3a33")]]
	for y in range(h):
		var k := float(y) / float(h - 1)
		var c: Color = stops[0][1]
		for i in range(stops.size() - 1):
			var a: Array = stops[i]
			var b: Array = stops[i + 1]
			if k >= float(a[0]) and k <= float(b[0]):
				c = (a[1] as Color).lerp(b[1], (k - float(a[0])) / (float(b[0]) - float(a[0])))
		img.fill_rect(Rect2i(0, y, w, 1), c)
	for i in range(w * h / 500):
		_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, int(h * 0.3)), Color(0.95, 0.92, 1.0, rng.randf_range(0.2, 0.8)))
	# Lune voilée.
	var mr := maxi(6, int(minf(w, h) * 0.04))
	var mx := int(w * 0.3)
	var my := int(h * 0.16)
	for r in range(mr * 3, mr, -1):
		_disc(img, mx, my, r, Color(0.9, 0.85, 1.0, 0.035))
	_disc(img, mx, my, mr, Color("e8e0f0"))
	# Rives lointaines.
	_ridge(img, rng, int(h * 0.5), int(h * 0.03), Color("5a5a6e"), Color("7a7a90"))
	# Saules pleureurs.
	for i in range(maxi(4, int(w / 70.0))):
		var tx := rng.randi_range(0, w)
		var base := int(h * 0.56) + rng.randi_range(-4, 4)
		var th := rng.randi_range(int(h * 0.1), int(h * 0.16))
		img.fill_rect(Rect2i(tx - 1, base - th, 3, th), Color("2a2a30"))
		_disc(img, tx, base - th, int(th * 0.45), Color("3a4a40"))
		for k in range(30):
			var sx := tx + rng.randi_range(-int(th * 0.5), int(th * 0.5))
			var sy := base - th + rng.randi_range(-int(th * 0.2), int(th * 0.2))
			for d in range(rng.randi_range(4, int(th * 0.7))):
				_px(img, sx, sy + d, Color("354538"))
	# Maisons sur pilotis et lanternes.
	for i in range(3):
		var hx := int(w * (0.2 + 0.3 * float(i))) + rng.randi_range(-10, 10)
		var hb := int(h * 0.57)
		img.fill_rect(Rect2i(hx, hb - 10, 14, 8), Color("2a2622"))
		for r in range(5):
			img.fill_rect(Rect2i(hx - 1 + r, hb - 10 - r, 16 - r * 2, 1), Color("3a3028"))
		for p in [hx + 1, hx + 6, hx + 12]:
			img.fill_rect(Rect2i(p, hb - 2, 1, 6), Color("2a2622"))
		_disc(img, hx + 7, hb - 6, 1, Color("f2c46b"))
		for r in range(5, 1, -1):
			_disc(img, hx + 7, hb - 6, r, Color(1.0, 0.8, 0.4, 0.05))
	# Eau sombre et brume au ras de l'eau.
	img.fill_rect(Rect2i(0, int(h * 0.6), w, h - int(h * 0.6)), Color("2f3a33"))
	for i in range(int(w * h / 600.0)):
		var y := rng.randi_range(int(h * 0.5), h - 1)
		var x := rng.randi_range(-40, w)
		for dx in range(rng.randi_range(30, 100)):
			_px(img, x + dx, y, Color(0.8, 0.85, 0.82, 0.12))
	return _tex(img)


## Zone 4 : nuit glacée, aurore boréale ondoyante, sommets enneigés, forteresse naine aux runes cyan.
static func _backdrop_frost(size: Vector2i) -> ImageTexture:
	var w := maxi(8, size.x)
	var h := maxi(8, size.y)
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4404
	var stops := [[0.0, Color("060a1c")], [0.3, Color("102044")], [0.5, Color("23395b")], [0.62, Color("4a6a8e")], [1.0, Color("1a2a44")]]
	for y in range(h):
		var k := float(y) / float(h - 1)
		var c: Color = stops[0][1]
		for i in range(stops.size() - 1):
			var a: Array = stops[i]
			var b: Array = stops[i + 1]
			if k >= float(a[0]) and k <= float(b[0]):
				c = (a[1] as Color).lerp(b[1], (k - float(a[0])) / (float(b[0]) - float(a[0])))
		img.fill_rect(Rect2i(0, y, w, 1), c)
	for i in range(w * h / 300):
		_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, int(h * 0.42)), Color(0.9, 0.95, 1.0, rng.randf_range(0.25, 0.9)))
	# Aurore boréale : rideaux verts et cyan, frangés de violet.
	var cols: Array[Color] = [Color(0.31, 0.89, 0.82), Color(0.56, 0.82, 0.42), Color(0.69, 0.49, 1.0)]
	for band in range(3):
		var y0 := float(h) * (0.08 + 0.07 * float(band))
		var amp := float(h) * 0.05
		var ph := rng.randf() * TAU
		var col: Color = cols[band]
		for x in range(w):
			var cy := y0 + sin(float(x) / float(w) * TAU * 1.3 + ph) * amp + sin(float(x) * 0.07 + ph) * amp * 0.25
			var tall := maxi(2, int(float(h) * (0.06 + 0.04 * sin(float(x) * 0.05 + ph * 2.0))))
			for d in range(tall):
				var a := 0.16 * (1.0 - float(d) / float(tall)) * (0.6 + 0.4 * sin(float(x) * 0.21 + ph))
				var yy := int(cy) + d
				if yy >= 0 and yy < h:
					img.set_pixel(x, yy, img.get_pixel(x, yy).lerp(col, a))
	# Sommets enneigés.
	_ridge(img, rng, int(h * 0.42), int(h * 0.06), Color("2a3a5a"), Color("eaf4fb"))
	_ridge(img, rng, int(h * 0.5), int(h * 0.04), Color("3a5070"), Color("cfe6f8"))
	# Forteresse naine taillée dans la montagne, runes cyan.
	var fx := int(w * 0.62)
	var fb := int(h * 0.56)
	var fw := maxi(24, int(w * 0.18))
	img.fill_rect(Rect2i(fx, fb - int(h * 0.1), fw, int(h * 0.1)), Color("1e2a3e"))
	for t in range(3):
		var tx := fx + int(float(fw) * (0.1 + 0.4 * float(t)))
		img.fill_rect(Rect2i(tx, fb - int(h * 0.15), maxi(4, fw / 6), int(h * 0.05)), Color("24324a"))
	img.fill_rect(Rect2i(fx + fw / 2 - 4, fb - 12, 8, 12), Color("0e1420"))
	for r in range(6):
		var rx := fx + rng.randi_range(4, fw - 4)
		var ry := fb - rng.randi_range(4, maxi(5, int(h * 0.09)))
		for k in range(3, 0, -1):
			_disc(img, rx, ry, k, Color(0.31, 0.89, 0.82, 0.08))
		_px(img, rx, ry, Color("4fe3d2"))
	# Plaine enneigée et poudrerie.
	img.fill_rect(Rect2i(0, int(h * 0.58), w, h - int(h * 0.58)), Color("1a2a44"))
	for i in range(int(w * h / 500.0)):
		var y := rng.randi_range(int(h * 0.5), h - 1)
		var x := rng.randi_range(-40, w)
		for dx in range(rng.randi_range(20, 80)):
			_px(img, x + dx, y, Color(0.85, 0.92, 1.0, 0.1))
	return _tex(img)


## Zone 5 : désert de verre au crépuscule (le combat le teinte de jour ou de nuit) : étoiles, grand soleil
## bas, dunes dorées, ruines du Collège et éclats de verre turquoise.
static func _backdrop_desert(size: Vector2i) -> ImageTexture:
	var w := maxi(8, size.x)
	var h := maxi(8, size.y)
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5505
	var stops := [[0.0, Color("2a5a9a")], [0.3, Color("5a8ac0")], [0.46, Color("e8b880")], [0.56, Color("f2d090")], [1.0, Color("8a6a3a")]]
	for y in range(h):
		var k := float(y) / float(h - 1)
		var c: Color = stops[0][1]
		for i in range(stops.size() - 1):
			var a: Array = stops[i]
			var b: Array = stops[i + 1]
			if k >= float(a[0]) and k <= float(b[0]):
				c = (a[1] as Color).lerp(b[1], (k - float(a[0])) / (float(b[0]) - float(a[0])))
		img.fill_rect(Rect2i(0, y, w, 1), c)
	for i in range(w * h / 320):
		_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, int(h * 0.3)), Color(1.0, 0.98, 0.9, rng.randf_range(0.15, 0.45)))
	# Grand soleil bas sur l'horizon.
	var sx := int(w * 0.3)
	var sy := int(h * 0.47)
	var sr := maxi(6, int(minf(w, h) * 0.09))
	for r in range(sr * 3, sr, -1):
		_disc(img, sx, sy, r, Color(1.0, 0.75, 0.4, 0.03))
	_disc(img, sx, sy, sr, Color("ffd890"))
	_disc(img, sx - sr / 4, sy - sr / 4, int(sr * 0.6), Color("fff0c0"))
	# Dunes lointaines, puis ruines du Collège.
	_ridge(img, rng, int(h * 0.5), int(h * 0.03), Color("a8703a"), Color("f2c46b"))
	var cx := int(w * 0.66)
	var cb := int(h * 0.53)
	for t in range(5):
		var tx := cx + int(float(w) * 0.035 * float(t))
		var th := int(h * (0.06 + 0.035 * float((t * 7) % 3)))
		img.fill_rect(Rect2i(tx, cb - th, maxi(3, int(w * 0.018)), th), Color("5a3a2a"))
	img.fill_rect(Rect2i(cx - int(w * 0.01), cb - int(h * 0.12), int(w * 0.2), maxi(2, int(h * 0.012))), Color("5a3a2a"))
	_disc(img, cx + int(w * 0.09), cb - int(h * 0.13), maxi(3, int(w * 0.03)), Color("5a3a2a"))
	_ridge(img, rng, int(h * 0.56), int(h * 0.025), Color("c8904a"), Color("ffe0a0"))
	img.fill_rect(Rect2i(0, int(h * 0.6), w, h - int(h * 0.6)), Color("b88a4a"))
	# Éclats de verre turquoise et voiles de sable.
	for i in range(maxi(6, w / 30)):
		var gx := rng.randi_range(0, w - 1)
		var gy := rng.randi_range(int(h * 0.52), int(h * 0.62))
		_px(img, gx, gy, Color("9ff0f0"))
		_px(img, gx + 1, gy, Color(0.25, 0.76, 0.79, 0.6))
	for i in range(int(w * h / 600.0)):
		var y := rng.randi_range(int(h * 0.45), h - 1)
		var x := rng.randi_range(-40, w)
		for dx in range(rng.randi_range(20, 70)):
			_px(img, x + dx, y, Color(1.0, 0.9, 0.7, 0.08))
	return _tex(img)


## Zone 6 : ciel de fumée rougeoyant, volcan lointain, forêt calcinée en flammes, dragons sur l'horizon.
static func _backdrop_ash(size: Vector2i) -> ImageTexture:
	var w := maxi(8, size.x)
	var h := maxi(8, size.y)
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6606
	var stops := [[0.0, Color("140a0e")], [0.28, Color("3a1418")], [0.46, Color("8a2a1a")], [0.56, Color("d8602a")], [0.62, Color("5a2a1e")], [1.0, Color("1e1412")]]
	for y in range(h):
		var k := float(y) / float(h - 1)
		var c: Color = stops[0][1]
		for i in range(stops.size() - 1):
			var a: Array = stops[i]
			var b: Array = stops[i + 1]
			if k >= float(a[0]) and k <= float(b[0]):
				c = (a[1] as Color).lerp(b[1], (k - float(a[0])) / (float(b[0]) - float(a[0])))
		img.fill_rect(Rect2i(0, y, w, 1), c)
	# Volutes de fumée.
	for i in range(int(w * h / 500.0)):
		var y := rng.randi_range(int(h * 0.05), int(h * 0.45))
		var x := rng.randi_range(-40, w)
		for dx in range(rng.randi_range(20, 80)):
			_px(img, x + dx, y + int(sin(float(dx) * 0.1) * 2.0), Color(0.1, 0.06, 0.06, 0.18))
	# Volcan et sa coulée.
	var vx := int(w * 0.72)
	var vb := int(h * 0.55)
	var vh := int(h * 0.2)
	for y in range(vh):
		var half := int(float(y) * 1.3) + 3
		img.fill_rect(Rect2i(vx - half, vb - vh + y, half * 2, 1), Color("2a1a1a"))
	for y in range(vh):
		_px(img, vx + int(sin(float(y) * 0.4) * 2.0), vb - vh + y, Color("ff7a2a"))
	for r in range(int(h * 0.08), 2, -1):
		_disc(img, vx, vb - vh, r, Color(1.0, 0.45, 0.15, 0.03))
	# Dragons sur l'horizon.
	for i in range(3):
		var dx := int(w * (0.2 + 0.22 * float(i))) + rng.randi_range(-8, 8)
		var dy := int(h * (0.22 + 0.06 * float(i % 2)))
		var sp := 3 + i
		for k in range(-sp, sp + 1):
			_px(img, dx + k, dy - absi(k) / 2, Color("1a0a0a"))
		_px(img, dx, dy + 1, Color("1a0a0a"))
	# Forêt calcinée : troncs noirs, braises et flammes.
	_ridge(img, rng, int(h * 0.56), int(h * 0.02), Color("2a1614"), Color("6a2a1a"))
	for i in range(maxi(10, int(w / 9.0))):
		var tx := rng.randi_range(0, w)
		var base := int(h * 0.6) + rng.randi_range(-4, 4)
		var th := rng.randi_range(int(h * 0.06), int(h * 0.16))
		img.fill_rect(Rect2i(tx, base - th, 2, th), Color("140a08"))
		for b in range(2):
			var by := base - th + rng.randi_range(2, maxi(3, th / 2))
			var dir := -1 if b == 0 else 1
			for d in range(rng.randi_range(3, 7)):
				_px(img, tx + dir * d, by - d / 2, Color("140a08"))
		if rng.randf() < 0.45:
			for f in range(rng.randi_range(3, 7)):
				_px(img, tx + rng.randi_range(-2, 3), base - th + rng.randi_range(-3, th / 2), Color("ffb050") if rng.randf() < 0.5 else Color("ff5a1a"))
	img.fill_rect(Rect2i(0, int(h * 0.62), w, h - int(h * 0.62)), Color("1e1412"))
	for i in range(int(w * h / 260.0)):
		_px(img, rng.randi_range(0, w - 1), rng.randi_range(int(h * 0.3), h - 1), Color(1.0, rng.randf_range(0.4, 0.8), 0.2, rng.randf_range(0.3, 0.9)))
	return _tex(img)


## Zone 7 : sous la mer, rayons de lumière venus de la surface, tours englouties, bulles, bancs de poissons.
static func _backdrop_abyss(size: Vector2i) -> ImageTexture:
	var w := maxi(8, size.x)
	var h := maxi(8, size.y)
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7707
	var stops := [[0.0, Color("1a6a8a")], [0.25, Color("0e4a6a")], [0.55, Color("082a44")], [1.0, Color("041224")]]
	for y in range(h):
		var k := float(y) / float(h - 1)
		var c: Color = stops[0][1]
		for i in range(stops.size() - 1):
			var a: Array = stops[i]
			var b: Array = stops[i + 1]
			if k >= float(a[0]) and k <= float(b[0]):
				c = (a[1] as Color).lerp(b[1], (k - float(a[0])) / (float(b[0]) - float(a[0])))
		img.fill_rect(Rect2i(0, y, w, 1), c)
	# Rayons de lumière obliques depuis la surface.
	for r in range(6):
		var x0 := rng.randi_range(0, w)
		var ww := rng.randi_range(6, 18)
		for y in range(int(h * 0.6)):
			var a := 0.07 * (1.0 - float(y) / (h * 0.6))
			for dx in range(ww):
				_px(img, x0 + dx + y / 3, y, Color(0.7, 0.95, 1.0, a))
	# Tours englouties et dômes de la cité.
	for i in range(maxi(5, w / 60)):
		var tx := rng.randi_range(0, w)
		var tb := int(h * 0.62) + rng.randi_range(-4, 6)
		var th := rng.randi_range(int(h * 0.1), int(h * 0.26))
		var tw := rng.randi_range(5, 10)
		img.fill_rect(Rect2i(tx, tb - th, tw, th), Color("0a2236"))
		_disc(img, tx + tw / 2, tb - th, tw / 2 + 1, Color("0c2840"))
		for k in range(3):
			_px(img, tx + tw / 2, tb - th + 6 + k * 7, Color("4fe3d2"))
	_ridge(img, rng, int(h * 0.62), int(h * 0.02), Color("061a2a"), Color("1a4a5a"))
	img.fill_rect(Rect2i(0, int(h * 0.64), w, h - int(h * 0.64)), Color("051624"))
	# Bancs de poissons, bulles, coraux.
	for i in range(4):
		var fx := rng.randi_range(0, w)
		var fy := rng.randi_range(int(h * 0.15), int(h * 0.45))
		for k in range(8):
			_px(img, fx + k * 3 + rng.randi_range(-1, 1), fy + rng.randi_range(-2, 2), Color(0.6, 0.85, 0.95, 0.6))
	for i in range(int(w * h / 300.0)):
		_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color(0.8, 0.95, 1.0, rng.randf_range(0.15, 0.5)))
	for i in range(maxi(6, w / 25)):
		var cx := rng.randi_range(0, w)
		var cb := int(h * 0.64) + rng.randi_range(0, 6)
		for k in range(rng.randi_range(4, 9)):
			_px(img, cx + rng.randi_range(-2, 2), cb - k, Color("e86a8a") if i % 2 == 0 else Color("ff9a6a"))
	return _tex(img)


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
		img.fill_rect(Rect2i(x, top, 1, h - top), body)
		if top <= prev:
			_px(img, x, top, edge)
		prev = top


# ---------------------------------------------------------------- zone 1 · un lieu par niveau

## Chaque niveau du Bois des Lucioles a son lieu (docs/design/41-cinematiques.md, « Combats ») : le même que
## ses cinématiques. Le pont (1-7) garde la chaussée au-dessus du vide ; les autres sont au sol de la forêt.
const LEVEL_SCENE := {
	"z01_l01": "lisiere", "z01_l02": "sentier", "z01_l03": "clairiere", "z01_l04": "roncier", "z01_l05": "fougeres",
	"z01_l06": "cercle", "z01_l07": "pont", "z01_l08": "source", "z01_l09": "coeur", "z01_l10": "sylvarche",
}
static var scene := "" ## lieu du combat en cours (zone 1), "" ailleurs


## Couleurs d'un lieu : herbe, chemin, brume, lucioles.
static func scene_palette(s: String) -> Dictionary:
	match s:
		"lisiere":
			return {"grass": Color("2f4a36"), "path": "dirt", "mist": Color("9a8ab8"), "moss": Color("3f5a3a"), "motes": Color(1.0, 0.85, 0.55)}
		"sentier":
			return {"grass": Color("23402e"), "path": "dirt", "mist": Color("8a9ad0"), "moss": Color("2f5a3a"), "motes": Color(1.0, 0.95, 0.55)}
		"clairiere":
			return {"grass": Color("31523a"), "path": "grass", "mist": Color("8a8ad0"), "moss": Color("3f6a3a"), "motes": Color(1.0, 0.95, 0.6)}
		"roncier":
			return {"grass": Color("2a3330"), "path": "dirt", "mist": Color("8a6ab0"), "moss": Color("3a3a40"), "motes": Color(0.85, 0.55, 1.0)}
		"fougeres":
			return {"grass": Color("284a3a"), "path": "grass", "mist": Color("a0b8e8"), "moss": Color("2f5a40"), "motes": Color(0.8, 0.95, 1.0)}
		"cercle":
			return {"grass": Color("2c4636"), "path": "moss", "mist": Color("c08ad0"), "moss": Color("3a5a40"), "motes": Color(1.0, 0.7, 0.92)}
		"source":
			return {"grass": Color("2a4a40"), "path": "dirt", "mist": Color("8ac8e0"), "moss": Color("2f5a48"), "motes": Color(0.7, 0.95, 1.0)}
		"coeur":
			return {"grass": Color("2a2440"), "path": "dirt", "mist": Color("a050d0"), "moss": Color("3a2a4a"), "motes": Color(0.9, 0.5, 1.0)}
		"sylvarche":
			return {"grass": Color("2a2c3c"), "path": "dirt", "mist": Color("9060c8"), "moss": Color("332e44"), "motes": Color(0.85, 0.55, 1.0)}
	return {}


static func _sprite(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


## Chaumière de Lysbourg : murs à colombages, toit de chaume, fenêtre allumée, porte.
static func cottage_texture() -> ImageTexture:
	var img := _sprite(40, 36)
	img.fill_rect(Rect2i(6, 16, 28, 20), Color("4a3e50"))
	img.fill_rect(Rect2i(30, 16, 4, 20), Color("5e5068"))
	for x in [6, 19, 33]:
		img.fill_rect(Rect2i(x, 16, 1, 20), Color("2a2030"))
	img.fill_rect(Rect2i(6, 24, 28, 1), Color("2a2030"))
	for r in range(14):
		img.fill_rect(Rect2i(2 + r, 16 - r, 36 - r * 2, 1), Color("6a5030") if r % 3 != 0 else Color("8a6a3a"))
	img.fill_rect(Rect2i(10, 19, 6, 5), Color("f2c46b"))
	img.fill_rect(Rect2i(12, 19, 1, 5), Color("a87a28"))
	img.fill_rect(Rect2i(23, 26, 6, 10), Color("2a1e18"))
	img.fill_rect(Rect2i(26, 6, 3, 8), Color("3a3048"))
	return _tex(img)


## Lanterne sur poteau (bord du chemin).
static func lamp_texture() -> ImageTexture:
	var img := _sprite(8, 26)
	img.fill_rect(Rect2i(3, 6, 2, 20), Color("3a2a1a"))
	img.fill_rect(Rect2i(1, 2, 6, 5), Color("2a2038"))
	img.fill_rect(Rect2i(2, 3, 4, 3), Color("ffd070"))
	return _tex(img)


## Souche éclatée et tronc couché (la clairière brisée).
static func stump_texture() -> ImageTexture:
	var img := _sprite(18, 14)
	img.fill_rect(Rect2i(3, 4, 12, 10), Color("3a2a22"))
	img.fill_rect(Rect2i(12, 4, 3, 10), Color("5a4232"))
	for k in range(12):
		var jag := (k * 7) % 5
		img.fill_rect(Rect2i(3 + k, 4 - jag, 1, jag), Color("6a5040") if k % 2 == 0 else Color("3a2a22"))
	return _tex(img)


static func log_texture() -> ImageTexture:
	var img := _sprite(38, 10)
	img.fill_rect(Rect2i(0, 2, 34, 8), Color("4a3428"))
	img.fill_rect(Rect2i(0, 2, 34, 1), Color("6a5040"))
	_disc(img, 34, 6, 4, Color("7a5a40"))
	_disc(img, 34, 6, 2, Color("4a3428"))
	return _tex(img)


## Roncier maudit : buisson d'épines violettes.
static func bramble_texture() -> ImageTexture:
	var img := _sprite(30, 22)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for i in range(18):
		var p := Vector2(rng.randf_range(4, 26), 21.0)
		var d := Vector2.from_angle(rng.randf_range(-PI * 0.85, -PI * 0.15))
		for s in range(rng.randi_range(10, 20)):
			_px(img, int(p.x), int(p.y), Color("2a1430") if s % 3 else Color("4a2458"))
			if s % 4 == 1:
				_px(img, int(p.x) + 1, int(p.y) - 1, Color("b07cff"))
			d = d.rotated(rng.randf_range(-0.4, 0.4))
			p += d
	return _tex(img)


## Pierre runique dressée (la porte maudite).
static func runestone_texture() -> ImageTexture:
	var img := _sprite(12, 28)
	img.fill_rect(Rect2i(2, 2, 8, 26), Color("4a4660"))
	img.fill_rect(Rect2i(8, 2, 2, 26), Color("6a6680"))
	img.fill_rect(Rect2i(3, 0, 6, 2), Color("4a4660"))
	for k in range(5):
		_px(img, 5, 5 + k * 4, Color("d93cf2"))
		_px(img, 6, 6 + k * 4, Color("d93cf2"))
	return _tex(img)


## Grande fougère.
static func fern_texture() -> ImageTexture:
	var img := _sprite(28, 20)
	for f in range(6):
		var ang := lerpf(-PI * 0.92, -PI * 0.08, float(f) / 5.0)
		var p := Vector2(14, 19)
		var d := Vector2.from_angle(ang)
		var col := Color("2f6a44") if f % 2 == 0 else Color("3f7a4a")
		for k in range(13):
			_px(img, int(p.x), int(p.y), col.darkened(0.2))
			var n := d.orthogonal()
			if k % 2 == 0 and k > 1:
				_px(img, int(p.x + n.x * 2.0), int(p.y + n.y * 2.0), col)
				_px(img, int(p.x - n.x * 2.0), int(p.y - n.y * 2.0), col.lightened(0.1))
			d = d.rotated(0.06 if ang < -PI * 0.5 else -0.06)
			p += d
	return _tex(img)


## Champignon lumineux (le cercle des fées).
static func mushroom_texture() -> ImageTexture:
	var img := _sprite(10, 11)
	img.fill_rect(Rect2i(4, 5, 2, 6), Color("e8dcc0"))
	for y in range(5):
		var half := 4 - absi(2 - y) / 2 if y > 0 else 2
		img.fill_rect(Rect2i(5 - half, y + 1, half * 2, 1), Color("f7a8e0") if y > 0 else Color("ffd8f4"))
	_px(img, 3, 3, Color("ffffff"))
	_px(img, 6, 2, Color("ffffff"))
	return _tex(img)


## Roseaux (la Source).
static func reeds_texture() -> ImageTexture:
	var img := _sprite(14, 20)
	for k in range(7):
		var x := 1 + k * 2
		var top := 2 + (k * 5) % 7
		img.fill_rect(Rect2i(x, top, 1, 20 - top), Color("3f7a4a") if k % 2 else Color("5a8a4a"))
		if k % 3 == 0:
			img.fill_rect(Rect2i(x, top, 1, 3), Color("6a4a2a"))
	return _tex(img)


## Cristal du Surge (le Cœur corrompu).
static func crystal_texture() -> ImageTexture:
	var img := _sprite(16, 30)
	for y in range(30):
		var half := int(7.0 * (1.0 - absf(float(y) - 20.0) / 20.0)) if y < 20 else int(7.0 * (1.0 - float(y - 20) / 12.0))
		for x in range(-half, half + 1):
			var c := Color("5a2a7a") if x < 0 else Color("b07cff")
			if absi(x) <= 0:
				c = Color("ffb0ff")
			_px(img, 8 + x, y, c)
	return _tex(img)


## Racine qui sort du sol (le domaine de la Sylvarche).
static func root_texture() -> ImageTexture:
	var img := _sprite(30, 14)
	for k in range(30):
		var y := int(12.0 - sin(float(k) / 29.0 * PI) * 10.0)
		img.fill_rect(Rect2i(k, y, 1, 14 - y), Color("3a2e2a") if k % 5 else Color("5a4030"))
		if k % 7 == 3:
			_px(img, k, y + 1, Color("b07cff"))
	return _tex(img)


## Fond du combat selon le lieu (zone 1) : le ciel de nuit commun, puis l'horizon du lieu.
static func _backdrop_scene(img: Image, rng: RandomNumberGenerator, s: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	match s:
		"lisiere":
			# Les toits de Lysbourg sur l'horizon, fenêtres allumées, fumées.
			var x := int(w * 0.1)
			while x < int(w * 0.9):
				var hw := rng.randi_range(10, 18)
				var hh := rng.randi_range(6, 10)
				var base := int(h * 0.5)
				img.fill_rect(Rect2i(x, base - hh, hw, hh + 4), Color("1a1830"))
				for r in range(hh / 2 + 2):
					img.fill_rect(Rect2i(x - 1 + r, base - hh - r, maxi(1, hw + 2 - r * 2), 1), Color("201a30"))
				_px(img, x + hw / 2, base - hh + 3, Color("f2c46b"))
				_px(img, x + hw / 2 + 1, base - hh + 3, Color("f2c46b"))
				for k in range(18):
					_px(img, x + hw / 2 + int(sin(float(k) * 0.4) * 2.0), base - hh - 4 - k, Color(0.6, 0.55, 0.8, 0.25))
				x += hw + rng.randi_range(4, 12)
		"fougeres":
			# Un grand rai de lune tombe sur la clairière.
			for y in range(h):
				var t := float(y) / float(h)
				var cx := lerpf(w * 0.78, w * 0.5, t)
				var half := lerpf(w * 0.03, w * 0.2, t)
				for xx in range(int(cx - half), int(cx + half)):
					_px(img, xx, y, Color(0.75, 0.82, 1.0, 0.06 * (1.0 - absf(float(xx) - cx) / half)))
		"cercle":
			# Une aurore rose au-dessus des arbres.
			for y in range(int(h * 0.2), int(h * 0.45)):
				var a := 0.08 * sin(float(y - int(h * 0.2)) / (h * 0.25) * PI)
				for xx in range(w):
					_px(img, xx, y + int(sin(float(xx) * 0.05) * 4.0), Color(1.0, 0.55, 0.9, a))
		"coeur", "roncier":
			# La lueur violette du Surge monte de l'horizon.
			for y in range(int(h * 0.3), int(h * 0.6)):
				var a := (0.2 if s == "coeur" else 0.12) * (1.0 - absf(float(y) - h * 0.5) / (h * 0.2))
				if a > 0.0:
					for xx in range(w):
						_px(img, xx, y, Color(0.69, 0.24, 0.95, a))
			if s == "coeur":
				var cx2 := int(w * 0.5)
				for y in range(int(h * 0.28), int(h * 0.5)):
					var half := int(float(y - int(h * 0.28)) * 0.35)
					for xx in range(-half, half + 1):
						_px(img, cx2 + xx, y, Color("5a2a7a") if xx < 0 else Color("b07cff"))
		"sylvarche":
			# L'arbre-mère sur l'horizon : un tronc immense et sa couronne violette.
			var cx3 := int(w * 0.5)
			var base2 := int(h * 0.52)
			for y in range(int(h * 0.22), base2):
				var half := int(lerpf(w * 0.03, w * 0.06, float(y - int(h * 0.22)) / float(base2 - int(h * 0.22))))
				img.fill_rect(Rect2i(cx3 - half, y, half * 2, 1), Color("1a1422"))
			for c in [[0.5, 0.16, 0.22, 0.1], [0.36, 0.22, 0.14, 0.07], [0.64, 0.22, 0.14, 0.07], [0.5, 0.26, 0.18, 0.06]]:
				var ccx := int(w * float(c[0]))
				var ccy := int(h * float(c[1]))
				var rx := int(w * float(c[2]))
				var ry := int(h * float(c[3]))
				for yy in range(-ry, ry + 1):
					var half2 := int(float(rx) * sqrt(maxf(0.0, 1.0 - float(yy * yy) / float(ry * ry))))
					img.fill_rect(Rect2i(ccx - half2, ccy + yy, half2 * 2, 1), Color("2a1640"))
			for i in range(40):
				_px(img, rng.randi_range(int(w * 0.25), int(w * 0.75)), rng.randi_range(int(h * 0.1), int(h * 0.32)), Color("b07cff"))
