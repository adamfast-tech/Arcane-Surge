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
			_swamp(img, lift)
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
	var pal := scene_palette(scene)
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
	# Détails du sol propres au lieu.
	match scene:
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
			for i in range(w * h / 900):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color("8898c8"))
		"cercle":
			# Fleurs de fée, roses et blanches.
			for i in range(w * h / 70):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(int(2.0 * PX_PER_M), h - 1), Color("c87ab0") if rng.randf() < 0.6 else Color("f7a8e0"))
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
		"route", "caravane":
			# Ornières de chariots, cailloux, et (caravane) traces de sabots.
			for rx in [int((3.8 - GROUND_MIN.x) * PX_PER_M), int((5.2 - GROUND_MIN.x) * PX_PER_M)]:
				for y in range(int(2.0 * PX_PER_M), h - int(2.0 * PX_PER_M)):
					var ox := int(sin(float(y) * 0.05) * 1.5)
					_px(img, rx + ox, y, Color("4a3a22"))
					_px(img, rx + ox + 1, y, Color("5a4a2a"))
			for i in range(w * h / 120):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color("a89870") if rng.randf() < 0.5 else Color("6a5a40"))
			if scene == "caravane":
				for i in range(80):
					var hx := rng.randi_range(int((3.6 - GROUND_MIN.x) * PX_PER_M), int((5.4 - GROUND_MIN.x) * PX_PER_M))
					var hy := rng.randi_range(int(2.0 * PX_PER_M), h - int(2.0 * PX_PER_M))
					_px(img, hx, hy, Color("3a2e1e"))
					_px(img, hx + 1, hy, Color("3a2e1e"))
		"moulins":
			# Rangs de chaume doré de part et d'autre (champs moissonnés).
			for y in range(0, h, 3):
				for x in range(0, w):
					var lx := GROUND_MIN.x + float(x) / PX_PER_M
					if (lx < 0.3 or lx > 8.7) and rng.randf() < 0.7:
						_px(img, x, y, Color("c8a850") if rng.randf() < 0.6 else Color("a8883a"))
		"pylones":
			# Terre craquelée, veines d'ambre qui luisent.
			for v4 in range(26):
				var p4 := Vector2(rng.randf_range(0.0, float(w)), rng.randf_range(0.0, float(h)))
				var d4 := Vector2.from_angle(rng.randf_range(0.0, TAU))
				for k in range(40):
					_px(img, int(p4.x), int(p4.y), Color("e8a040") if k % 4 != 0 else Color("ffd080"))
					d4 = d4.rotated(rng.randf_range(-0.5, 0.5))
					p4 += d4
		"gue":
			# Galets mouillés et boue près de l'eau.
			for i in range(w * h / 60):
				var gx := rng.randi_range(0, w - 1)
				var lx2 := GROUND_MIN.x + float(gx) / PX_PER_M
				if lx2 < 1.2 or lx2 > 7.8:
					_px(img, gx, rng.randi_range(0, h - 1), Color("5a5040") if rng.randf() < 0.6 else Color("8a8070"))
		"repaire", "fort":
			# Boue piétinée, cendres et os.
			for i in range(16):
				var pc2 := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(int(2.0 * PX_PER_M), h - int(2.0 * PX_PER_M)))
				_disc(img, pc2.x, pc2.y, rng.randi_range(3, 7), Color("3a3020") if scene == "repaire" else Color("2a2620"))
			for i in range(w * h / 260):
				var bx := rng.randi_range(0, w - 1)
				var by := rng.randi_range(0, h - 1)
				_px(img, bx, by, Color("d8d0b8"))
				_px(img, bx + 1, by, Color("c8c0a8"))
		"orage":
			# Boue sombre et flaques qui reflètent le ciel d'orage.
			for i in range(22):
				var pc3 := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(int(2.0 * PX_PER_M), h - int(2.0 * PX_PER_M)))
				_disc(img, pc3.x, pc3.y, rng.randi_range(2, 5), Color("3a3a40"))
				_px(img, pc3.x - 1, pc3.y - 1, Color("8a8aa8"))
		"rebouteux":
			# Herbes coupées et petits os.
			for i in range(w * h / 90):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color("8aa850") if rng.randf() < 0.7 else Color("d8d0b8"))
		"pilotis", "barque":
			# Planches tombées, mousse et flaques sombres.
			for i in range(14):
				var pc4 := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(int(2.0 * PX_PER_M), h - int(2.0 * PX_PER_M)))
				_disc(img, pc4.x, pc4.y, rng.randi_range(2, 4), Color("1e2a26"))
			for i in range(w * h / 200):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color("4a3a2a"))
		"mares", "croc", "sorciere":
			# Flaques de poison verdâtres et bulles.
			for i in range(20):
				var pc5 := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(int(2.0 * PX_PER_M), h - int(2.0 * PX_PER_M)))
				_disc(img, pc5.x, pc5.y, rng.randi_range(2, 5), Color("3a5a1e"))
				_px(img, pc5.x, pc5.y - 1, Color("a8e050"))
		"brume", "hydre":
			# Vase, roseaux couchés, flaques claires.
			for i in range(w * h / 70):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color("3a4a38") if rng.randf() < 0.7 else Color("6a7a68"))
		"gue_morts":
			# Ossements et dalles funéraires enfoncées dans la vase.
			for i in range(w * h / 220):
				var bx2 := rng.randi_range(0, w - 1)
				var by2 := rng.randi_range(0, h - 1)
				_px(img, bx2, by2, Color("d8d0c0"))
				_px(img, bx2 + 1, by2 + 1, Color("c8c0b0"))
			for i in range(10):
				var sx3 := rng.randi_range(0, w - 8)
				var sy3 := rng.randi_range(int(2.0 * PX_PER_M), h - int(2.0 * PX_PER_M))
				img.fill_rect(Rect2i(sx3, sy3, 6, 3), Color("5a5a6a"))
		"saules":
			# Cendres en cercle et brindilles.
			for i in range(w * h / 90):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color("6a6a6a") if rng.randf() < 0.6 else Color("ff8a3a"))
		"refuge":
			# Pierres tombées, éclats arcaniques.
			for i in range(w * h / 120):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color("6a6a78") if rng.randf() < 0.8 else Color("b07cff"))
		"col", "chariot":
			# Traces de pas et (chariot) deux rails sombres dans la neige.
			for i in range(120):
				var fx3 := rng.randi_range(int((3.9 - GROUND_MIN.x) * PX_PER_M), int((5.1 - GROUND_MIN.x) * PX_PER_M))
				var fy3 := rng.randi_range(int(2.0 * PX_PER_M), h - int(2.0 * PX_PER_M))
				_px(img, fx3, fy3, Color("1e3028"))
			if scene == "chariot":
				for rx2 in [int((4.0 - GROUND_MIN.x) * PX_PER_M), int((5.0 - GROUND_MIN.x) * PX_PER_M)]:
					for y in range(int(1.0 * PX_PER_M), h - int(1.5 * PX_PER_M)):
						_px(img, rx2, y, Color("1a1a20"))
						if y % 5 == 0:
							for x in range(int((3.8 - GROUND_MIN.x) * PX_PER_M), int((5.2 - GROUND_MIN.x) * PX_PER_M)):
								_px(img, x, y, Color("3a2a20"))
		"congeres":
			# Grandes congères claires.
			for i in range(26):
				var pc6 := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
				_disc(img, pc6.x, pc6.y, rng.randi_range(5, 12), Color("4a7a52"))
		"lac_gele":
			# Fissures dans la glace.
			for v5 in range(18):
				var p5 := Vector2(rng.randf_range(0.0, float(w)), rng.randf_range(0.0, float(h)))
				var d5 := Vector2.from_angle(rng.randf_range(0.0, TAU))
				for k in range(30):
					_px(img, int(p5.x), int(p5.y), Color("1a2a40"))
					d5 = d5.rotated(rng.randf_range(-0.6, 0.6))
					p5 += d5
		"porte_naine", "sentinelle", "portes", "forteresse", "colosse":
			# Lignes de runes cyan gravées dans la pierre.
			for i in range(14):
				var ry2 := rng.randi_range(int(2.0 * PX_PER_M), h - int(2.0 * PX_PER_M))
				var rx3 := rng.randi_range(0, w - 20)
				for k in range(rng.randi_range(6, 16)):
					_px(img, rx3 + k, ry2, Color("8fe3f2") if k % 3 != 0 else Color("2a3a5a"))
		"aurore":
			# Reflets verts de l'aurore sur la neige.
			for i in range(w * h / 80):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color("5ff0a8") if rng.randf() < 0.5 else Color("b07cff"))
		"traite":
			# Herbe foulée par les deux camps, fleurs des prés.
			for i in range(w * h / 80):
				_px(img, rng.randi_range(0, w - 1), rng.randi_range(int(2.0 * PX_PER_M), h - 1), Color("e85a3a") if rng.randf() < 0.5 else Color("f2d04a"))
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
	elif path_kind == "planks":
		# Passerelle de planches sur pilotis, aux joints sombres.
		for y in range(y_top, y_bot):
			var row := (y - y_top) % 6
			for x in range(x0 - 2, x1 + 2):
				var c3 := Color("5a4630") if row != 5 else Color("2a2018")
				if (x + (y - y_top) / 6 * 7) % 23 == 0:
					c3 = Color("2a2018")
				_px(img, x, y, c3.lightened(0.06) if rng.randf() < 0.2 else c3)
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
	if not pal.is_empty():
		_ground_richness(img, rng, x0, x1, y_top, y_bot)
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
	_zone_tint(img, float(pal.get("warm_h", 0.115)), float(pal.get("lift", 1.0)))
	if path_kind == "planks":
		# Les planches gardent leur bois (la teinte du marais les grisait).
		for y in range(y_top, y_bot):
			var row2 := (y - y_top) % 6
			for x in range(x0 - 2, x1 + 2):
				var c4 := Color("6a5238") if row2 != 5 else Color("2a2018")
				if (x + (y - y_top) / 6 * 7) % 23 == 0:
					c4 = Color("2a2018")
				_px(img, x, y, c4.darkened(0.08) if (x * 13 + y * 7) % 5 == 0 else c4)
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
	var storm := scene in STORM_SCENES
	var stops := [[0.0, Color("3f86c8")], [0.3, Color("6fb0e0")], [0.48, Color("b8d8e8")], [0.58, Color("f0d8a0")], [1.0, Color("c89858")]]
	if storm:
		# Orage : ciel d'encre, lueur jaune sale sur l'horizon.
		stops = [[0.0, Color("16161e")], [0.3, Color("2a2a3a")], [0.48, Color("4a4a58")], [0.58, Color("7a6a50")], [1.0, Color("5a4a34")]]
	for y in range(h):
		var k := float(y) / float(h - 1)
		var c: Color = stops[0][1]
		for i in range(stops.size() - 1):
			var a: Array = stops[i]
			var b: Array = stops[i + 1]
			if k >= float(a[0]) and k <= float(b[0]):
				c = (a[1] as Color).lerp(b[1], (k - float(a[0])) / (float(b[0]) - float(a[0])))
		img.fill_rect(Rect2i(0, y, w, 1), c)
	# Soleil et halo (caché par l'orage).
	var sr := maxi(7, int(minf(w, h) * 0.05))
	var sx := int(w * 0.24)
	var sy := int(h * 0.1)
	if not storm:
		for r in range(sr * 4, sr, -1):
			_disc(img, sx, sy, r, Color(1.0, 0.95, 0.75, 0.03))
		_disc(img, sx, sy, sr, Color("fff2c0"))
		_disc(img, sx, sy, int(sr * 0.7), Color("fffbe8"))
	else:
		# Nuages d'orage en rouleaux, et un éclair figé dans le lointain.
		for i in range(int(w / 6.0)):
			var cy2 := rng.randi_range(0, int(h * 0.3))
			var cx2 := rng.randi_range(-30, w)
			var r2 := rng.randi_range(6, 16)
			_disc(img, cx2, cy2, r2, Color(0.12, 0.12, 0.16, 0.5))
			_disc(img, cx2 + 2, cy2 + 2, r2 - 3, Color(0.22, 0.22, 0.3, 0.35))
		var bx := float(w) * 0.42
		var by := float(h) * 0.12
		while by < h * 0.45:
			var nx := bx + rng.randf_range(-6.0, 6.0)
			var ny := by + rng.randf_range(4.0, 9.0)
			for k in range(10):
				var tt := float(k) / 9.0
				_px(img, int(lerpf(bx, nx, tt)), int(lerpf(by, ny, tt)), Color("e8f0ff"))
				_px(img, int(lerpf(bx, nx, tt)) + 1, int(lerpf(by, ny, tt)), Color(0.6, 0.7, 1.0, 0.5))
			bx = nx
			by = ny
	# Nuages blancs en bandes.
	for i in range(maxi(3, int(w / 40.0)) if not storm else 0):
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
	_ridge(img, rng, int(h * 0.5), int(h * 0.06), Color("b07a40") if not storm else Color("5a4a34"), Color("e8b060") if not storm else Color("7a6a48"))
	_backdrop_hills(img, rng, scene)
	_ridge(img, rng, int(h * 0.56), int(h * 0.05), Color("8a5a2a") if not storm else Color("3a3024"), Color("c88a40") if not storm else Color("5a4a34"))
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
	"z02_l01": "route", "z02_l02": "moulins", "z02_l03": "pylones", "z02_l04": "gue", "z02_l05": "repaire",
	"z02_l06": "orage", "z02_l07": "caravane", "z02_l08": "rebouteux", "z02_l09": "traite", "z02_l10": "fort",
	"z03_l01": "pilotis", "z03_l02": "mares", "z03_l03": "brume", "z03_l04": "gue_morts", "z03_l05": "croc",
	"z03_l06": "saules", "z03_l07": "barque", "z03_l08": "sorciere", "z03_l09": "refuge", "z03_l10": "hydre",
	"z04_l01": "col", "z04_l02": "congeres", "z04_l03": "porte_naine", "z04_l04": "lac_gele", "z04_l05": "sentinelle",
	"z04_l06": "aurore", "z04_l07": "chariot", "z04_l08": "portes", "z04_l09": "forteresse", "z04_l10": "colosse",
}
## Pics Gelés (zone 4) : lieux taillés par les nains (pavés, runes cyan).
const DWARF_SCENES := ["porte_naine", "sentinelle", "portes", "forteresse", "colosse"]
## Lieux du marais (zone 3) où l'eau borde le terrain, et sa couleur.
const SWAMP_WATER := {"pilotis": "2f4a48", "mares": "3a5a2a", "brume": "34484a", "gue_morts": "1e2a30", "croc": "2a3a2a",
	"barque": "2f4a48", "hydre": "263a3a", "saules": "2f4044"}
## Lieux d'orage (zone 2) : ciel noir, pluie, éclairs.
const STORM_SCENES := ["orage", "fort"]
static var scene := "" ## lieu du combat en cours (zones 1 et 2), "" ailleurs


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
		# Zone 2, Collines d'Ambre : couleurs finales (la teinte de la zone les éclaircit à peine) ;
		# warm_h : teinte de l'herbe sèche, lift : lumière (plus sombre sous l'orage).
		"route":
			return {"grass": Color("8a7a3e"), "path": "dirt", "mist": Color("e8d0a0"), "moss": Color("7a6a34"), "motes": Color(1.0, 0.9, 0.65), "warm_h": 0.115, "lift": 1.0}
		"moulins":
			return {"grass": Color("7e8a3e"), "path": "dirt", "mist": Color("e8e0b0"), "moss": Color("6a7a34"), "motes": Color(1.0, 0.97, 0.75), "warm_h": 0.15, "lift": 1.0}
		"pylones":
			return {"grass": Color("6e6234"), "path": "dirt", "mist": Color("f0c080"), "moss": Color("5e5430"), "motes": Color(1.0, 0.7, 0.3), "warm_h": 0.1, "lift": 0.95}
		"gue":
			return {"grass": Color("6a7a40"), "path": "grass", "mist": Color("c8d8d0"), "moss": Color("5a6a38"), "motes": Color(0.95, 0.95, 0.8), "warm_h": 0.14, "lift": 1.0}
		"repaire":
			return {"grass": Color("6a5a32"), "path": "dirt", "mist": Color("c8a080"), "moss": Color("5a4a2a"), "motes": Color(1.0, 0.6, 0.3), "warm_h": 0.1, "lift": 0.9}
		"orage":
			return {"grass": Color("4e5434"), "path": "dirt", "mist": Color("8a8aa0"), "moss": Color("3e4430"), "motes": Color(0.8, 0.85, 1.0), "warm_h": 0.13, "lift": 0.72}
		"caravane":
			return {"grass": Color("8a7a3e"), "path": "dirt", "mist": Color("e8d0a0"), "moss": Color("7a6a34"), "motes": Color(1.0, 0.9, 0.65), "warm_h": 0.12, "lift": 1.0}
		"rebouteux":
			return {"grass": Color("6e6e38"), "path": "dirt", "mist": Color("c8d0a0"), "moss": Color("5e5e30"), "motes": Color(0.8, 1.0, 0.6), "warm_h": 0.14, "lift": 0.95}
		"traite":
			return {"grass": Color("7e7a3c"), "path": "grass", "mist": Color("e8d8b0"), "moss": Color("6e6a34"), "motes": Color(1.0, 0.95, 0.7), "warm_h": 0.13, "lift": 1.0}
		"fort":
			return {"grass": Color("4a4630"), "path": "dirt", "mist": Color("7a7080"), "moss": Color("3a382a"), "motes": Color(1.0, 0.55, 0.25), "warm_h": 0.1, "lift": 0.72}
		# Zone 3, Marais Murmurants : couleurs du Bois, que la teinte du marais rabat en vert-gris et gris violacé.
		"pilotis":
			return {"grass": Color("2f4a36"), "path": "planks", "mist": Color("c9d1c4"), "moss": Color("3f5a3a"), "motes": Color(1.0, 0.85, 0.5), "lift": 1.0}
		"mares":
			return {"grass": Color("2a4a30"), "path": "dirt", "mist": Color("a8c898"), "moss": Color("3a5a30"), "motes": Color(0.6, 1.0, 0.4), "lift": 0.95}
		"brume":
			return {"grass": Color("2a3f36"), "path": "dirt", "mist": Color("e0e8e0"), "moss": Color("34503a"), "motes": Color(0.85, 0.95, 0.9), "lift": 1.05}
		"gue_morts":
			return {"grass": Color("28342e"), "path": "dirt", "mist": Color("a8b0c0"), "moss": Color("2e3a34"), "motes": Color(0.7, 0.9, 1.0), "lift": 0.85}
		"croc":
			return {"grass": Color("2a3a2a"), "path": "dirt", "mist": Color("9ab890"), "moss": Color("34442e"), "motes": Color(0.7, 1.0, 0.5), "lift": 0.9}
		"saules":
			return {"grass": Color("2c4436"), "path": "grass", "mist": Color("c0b0d0"), "moss": Color("3a5040"), "motes": Color(1.0, 0.6, 0.3), "lift": 1.0}
		"barque":
			return {"grass": Color("2a4438"), "path": "planks", "mist": Color("c9d1c4"), "moss": Color("34503a"), "motes": Color(1.0, 0.85, 0.5), "lift": 1.0}
		"sorciere":
			return {"grass": Color("283a30"), "path": "dirt", "mist": Color("b8c8b0"), "moss": Color("2e4234"), "motes": Color(0.75, 1.0, 0.6), "lift": 0.9}
		"refuge":
			return {"grass": Color("2a3434"), "path": "cobbles", "mist": Color("b0a8c8"), "moss": Color("343c3a"), "motes": Color(0.85, 0.6, 1.0), "lift": 0.95}
		"hydre":
			return {"grass": Color("263a30"), "path": "dirt", "mist": Color("c0d0c8"), "moss": Color("2e4034"), "motes": Color(0.8, 0.95, 0.9), "lift": 0.95}
		# Zone 4, Pics Gelés : couleurs du Bois, que la teinte des Pics change en neige bleutée et granit glacier.
		"col":
			return {"grass": Color("2f4a36"), "path": "dirt", "mist": Color("dcecf8"), "moss": Color("3f5a3a"), "motes": Color(0.95, 0.98, 1.0), "lift": 1.0}
		"congeres":
			return {"grass": Color("35593f"), "path": "grass", "mist": Color("eaf4fb"), "moss": Color("4a6a48"), "motes": Color(0.95, 0.98, 1.0), "lift": 1.05}
		"porte_naine", "portes", "forteresse":
			return {"grass": Color("2f4a36"), "path": "cobbles", "mist": Color("c8dcec"), "moss": Color("3f5a3a"), "motes": Color(0.6, 0.9, 1.0), "lift": 0.95}
		"lac_gele":
			return {"grass": Color("2f4a3e"), "path": "grass", "mist": Color("d8ecf8"), "moss": Color("3f5a48"), "motes": Color(0.85, 0.95, 1.0), "lift": 1.0}
		"sentinelle":
			return {"grass": Color("2a4034"), "path": "cobbles", "mist": Color("b8d0e8"), "moss": Color("3a5038"), "motes": Color(0.55, 0.9, 1.0), "lift": 0.9}
		"aurore":
			return {"grass": Color("2f4a3a"), "path": "grass", "mist": Color("b8f0d8"), "moss": Color("3f5a40"), "motes": Color(0.5, 1.0, 0.7), "lift": 0.95}
		"chariot":
			return {"grass": Color("2f4a36"), "path": "dirt", "mist": Color("dcecf8"), "moss": Color("3f5a3a"), "motes": Color(0.6, 0.9, 1.0), "lift": 1.0}
		"colosse":
			return {"grass": Color("263830"), "path": "cobbles", "mist": Color("a8c0e0"), "moss": Color("34483a"), "motes": Color(1.0, 0.75, 0.4), "lift": 0.85}
	return {}


## Le lieu se joue-t-il au sol (pas sur la chaussée au-dessus du vide) ?
static func floor_scene() -> bool:
	return scene != "" and scene != "pont"


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


# ---------------------------------------------------------------- zone 1 · végétation et arbres des combats

const FOLIAGE_N := 12 ## images de 16×16 dans la planche de végétation
const FOLIAGE_GLOW_Z4 := {"porte_naine": [9], "sentinelle": [9], "portes": [9], "forteresse": [9], "colosse": [8, 9], "aurore": [8], "lac_gele": [8]}
const FOLIAGE_GLOW := {"sentier": [9], "fougeres": [9], "cercle": [8, 9], "coeur": [8], "sylvarche": [9], "pylones": [8], "repaire": [9],
	"pilotis": [9], "barque": [9], "mares": [8], "sorciere": [8], "gue_morts": [9], "refuge": [9], "saules": [9]}


## Couleurs de fleurs selon le lieu.
static func _flower_cols(s: String) -> Array:
	match s:
		"lisiere":
			return [Color("f2e28b"), Color("f4f0ff")]
		"sentier":
			return [Color("f2e28b"), Color("9ff0ff")]
		"clairiere":
			return [Color("f4f0ff"), Color("f2a050")]
		"roncier":
			return [Color("8e62e0"), Color("5a2a7a")]
		"fougeres":
			return [Color("cfe0ff"), Color("9ab8ff")]
		"cercle":
			return [Color("f7a8e0"), Color("ffe8f8")]
		"source":
			return [Color("9ff0ff"), Color("f4f0ff")]
		"coeur":
			return [Color("d98cff"), Color("ff9ce8")]
		"sylvarche":
			return [Color("b07cff"), Color("f4f0ff")]
		"route", "caravane", "traite":
			return [Color("e85a3a"), Color("f2d04a")]
		"moulins":
			return [Color("ff6a4a"), Color("f2e28b")]
		"pylones":
			return [Color("ffb050"), Color("ffd080")]
		"gue":
			return [Color("f2d04a"), Color("e87a4a")]
		"repaire", "fort":
			return [Color("c84a3a"), Color("8a6a3a")]
		"orage":
			return [Color("c8c8a0"), Color("8a8a6a")]
		"rebouteux":
			return [Color("a8d070"), Color("e8e0a0")]
		"pilotis", "barque", "brume":
			return [Color("e8e0ff"), Color("f2e28b")]
		"mares", "croc", "sorciere":
			return [Color("a8e050"), Color("c87ab0")]
		"gue_morts", "hydre":
			return [Color("cfe8ff"), Color("8a8aa8")]
		"saules":
			return [Color("ff8a3a"), Color("e8e0ff")]
		"refuge":
			return [Color("b07cff"), Color("e8e0ff")]
		"col", "congeres", "lac_gele", "chariot":
			return [Color("f4f8ff"), Color("cfe8ff")]
		"porte_naine", "sentinelle", "portes", "forteresse":
			return [Color("8fe3f2"), Color("f4f8ff")]
		"aurore":
			return [Color("5ff0a8"), Color("b07cff")]
		"colosse":
			return [Color("ffb050"), Color("8fe3f2")]
	return [Color("f4f0ff"), Color("f2e28b")]


static func _blade(img: Image, ox: int, x: int, y0: int, hgt: int, lean: float, base: Color, tip: Color) -> void:
	for k in range(hgt):
		var t := float(k) / float(maxi(1, hgt - 1))
		_px(img, ox + x + int(round(lean * t * float(hgt) * 0.35)), y0 - k, base.lerp(tip, t))


## Planche de végétation du lieu : 0-1 touffes d'herbe, 2-3 fleurs, 4 buisson, 5 rocher, 6 fougère, 7 cailloux,
## 8-9 détails du lieu, 10 herbes hautes, 11 brindilles et feuilles.
static func foliage_atlas(s: String) -> ImageTexture:
	var img := Image.create_empty(16 * FOLIAGE_N, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(s) + 7
	var pal := scene_palette(s)
	var g: Color = pal.get("grass", Color("2a4a36"))
	var gdark := g.darkened(0.25)
	var glit := g.lightened(0.45)
	var fc := _flower_cols(s)
	# 0, 1 : touffes d'herbe.
	for f in range(2):
		var ox := f * 16
		for b in range(7 + f * 2):
			_blade(img, ox, 4 + rng.randi_range(0, 8), 15, rng.randi_range(5, 10), rng.randf_range(-1.5, 1.5), gdark, glit)
	# 2, 3 : fleurs dans l'herbe.
	for f in range(2):
		var ox := (2 + f) * 16
		for b in range(6):
			_blade(img, ox, 4 + rng.randi_range(0, 8), 15, rng.randi_range(4, 8), rng.randf_range(-1.2, 1.2), gdark, glit)
		for k in range(4):
			var fx := ox + rng.randi_range(3, 12)
			var fy := rng.randi_range(4, 9)
			var col: Color = fc[(k + f) % 2]
			_px(img, fx, fy, col)
			_px(img, fx + 1, fy, col.darkened(0.15))
			_px(img, fx, fy + 1, col.darkened(0.25))
			_px(img, fx + 1, fy + 1, col.darkened(0.1))
			_px(img, fx, fy + 2, gdark)
	# 4 : buisson (trois volumes, lumière de lune en haut à droite).
	for e in [[8, 10, 6, 5], [5, 11, 4, 4], [11, 11, 4, 4]]:
		var cx: int = e[0]
		var cy: int = e[1]
		var rx: int = e[2]
		var ry: int = e[3]
		for y in range(-ry, ry + 1):
			for x in range(-rx, rx + 1):
				var d := pow(float(x) / float(rx), 2.0) + pow(float(y) / float(ry), 2.0)
				if d <= 1.0:
					var c := g.darkened(0.15)
					if x > 0 and y < 0 and d > 0.35:
						c = glit
					elif x < 0 and y > 0:
						c = gdark
					_px(img, 64 + cx + x, cy + y, c)
	# 5 : rocher moussu.
	for y in range(-5, 6):
		for x in range(-7, 8):
			var d2 := pow(float(x) / 7.0, 2.0) + pow(float(y) / 5.0, 2.0)
			if d2 <= 1.0:
				var c2 := Color("4a4a60")
				if x > 1 and y < -1:
					c2 = Color("6a6a84")
				elif x < -2 or y > 2:
					c2 = Color("2e2e40")
				if y < -3 and x < 2:
					c2 = Color("3f6a3a")
				_px(img, 80 + 8 + x, 10 + y, c2)
	# 6 : petite fougère.
	for fr in range(5):
		var ang := lerpf(-PI * 0.88, -PI * 0.12, float(fr) / 4.0)
		var p := Vector2(96 + 8, 15)
		var dv := Vector2.from_angle(ang)
		for k in range(9):
			_px(img, int(p.x), int(p.y), Color("2f6a44"))
			if k % 2 == 1:
				var n := dv.orthogonal()
				_px(img, int(p.x + n.x), int(p.y + n.y), Color("4f8a54"))
			dv = dv.rotated(0.08 if ang < -PI * 0.5 else -0.08)
			p += dv
	# 7 : cailloux.
	for pb in [[4, 13, 2], [9, 12, 3], [13, 14, 1]]:
		for y in range(-int(pb[2]), int(pb[2]) + 1):
			for x in range(-int(pb[2]) - 1, int(pb[2]) + 2):
				_px(img, 112 + int(pb[0]) + x, int(pb[1]) + y, Color("5a5a70") if y < 0 else Color("3a3a4e"))
	# 10 : herbes hautes.
	for b in range(9):
		_blade(img, 160, 3 + rng.randi_range(0, 10), 15, rng.randi_range(9, 14), rng.randf_range(-1.0, 1.0), gdark, glit.lightened(0.1))
	# 11 : brindilles et feuilles.
	for k in range(5):
		_px(img, 176 + rng.randi_range(2, 13), rng.randi_range(11, 15), [Color("8a5a2a"), Color("a8702a"), Color("5a4030")][k % 3])
	for x in range(3, 13):
		_px(img, 176 + x, 13 - int(float(x - 3) * 0.3), Color("4a3428"))
	# Teinte de la zone (herbe sèche des Collines), puis 8, 9 : détails propres au lieu, à leurs couleurs.
	_zone_tint(img, float(pal.get("warm_h", 0.115)), float(pal.get("lift", 1.0)))
	_scene_detail(img, 128, s, 0, rng, fc)
	_scene_detail(img, 144, s, 1, rng, fc)
	return _tex(img)


static func _scene_detail(img: Image, ox: int, s: String, which: int, rng: RandomNumberGenerator, fc: Array) -> void:
	match s + str(which):
		"col0", "congeres0", "chariot0", "lac_gele1":
			# Rocher sous un chapeau de neige.
			for y in range(-5, 6):
				for x in range(-7, 8):
					if pow(float(x) / 7.0, 2.0) + pow(float(y) / 5.0, 2.0) <= 1.0:
						_px(img, ox + 8 + x, 10 + y, Color("f4f8ff") if y < -1 else (Color("6a7a98") if x > 0 else Color("3a4a6a")))
		"col1", "congeres1", "chariot1":
			# Petit sapin enneigé.
			for y in range(3, 15):
				var hw2 := (y - 3) / 2
				for x in range(-hw2, hw2 + 1):
					_px(img, ox + 8 + x, y, Color("f4f8ff") if (y % 3 == 0 and absi(x) < hw2) else Color("2a4a4a"))
			_px(img, ox + 8, 15, Color("3a2a20"))
		"lac_gele0", "aurore0":
			# Éclat de glace dressé (il luit).
			for y in range(3, 16):
				var hw3 := int(3.0 * (1.0 - float(y - 3) / 13.0)) + 1 if y < 9 else 3 - (y - 9) / 3
				for x in range(-hw3, hw3 + 1):
					_px(img, ox + 8 + x, y, Color("e8f8ff") if x == 0 else (Color("8fd0f0") if x > 0 else Color("4a8ab0")))
		"aurore1":
			# Herbe gelée scintillante.
			for k in range(6):
				_blade(img, ox, 3 + k * 2, 15, 7 + k % 3, float(k - 3) * 0.2, Color("4a6a8a"), Color("c8f0ff"))
		"porte_naine0", "sentinelle0", "portes0", "forteresse0":
			# Bouclier nain à demi enfoui dans la neige.
			for y in range(5, 14):
				for x in range(4, 13):
					if Vector2(float(x) - 8.0, float(y) - 9.0).length() <= 4.5:
						_px(img, ox + x, y, Color("6a7a98") if x < 9 else Color("4a5a78"))
			_px(img, ox + 8, 9, Color("d8b048"))
			for x in range(2, 14):
				_px(img, ox + x, 13, Color("f4f8ff"))
				_px(img, ox + x, 14, Color("dceaf6"))
		"porte_naine1", "sentinelle1", "portes1", "forteresse1", "colosse1":
			# Pierre runique cyan (elle luit).
			for y in range(5, 16):
				for x in range(5, 11):
					_px(img, ox + x, y, Color("5a6a88") if x < 9 else Color("3a4a68"))
			for y: int in [7, 10, 13]:
				_px(img, ox + 7, y, Color("8fe3f2"))
				_px(img, ox + 8, y, Color("c8f8ff"))
		"colosse0":
			# Enclume (le métal rougeoie).
			for x in range(3, 14):
				_px(img, ox + x, 8, Color("ff9a4a") if x > 9 else Color("4a4a58"))
				_px(img, ox + x, 9, Color("3a3a48"))
			for y in range(10, 15):
				for x in range(6, 11):
					_px(img, ox + x, y, Color("2a2a38"))
			for x in range(4, 13):
				_px(img, ox + x, 15, Color("2a2a38"))
		"pilotis0", "barque0", "brume0", "hydre0":
			# Roseaux et quenouilles du marais.
			for k in range(6):
				_blade(img, ox, 3 + k * 2, 15, 9 + (k % 3) * 2, float(k - 3) * 0.15, Color("3a4a30"), Color("6a7a50"))
			for k2 in range(3):
				for y in range(4):
					_px(img, ox + 5 + k2 * 3, 4 + (k2 % 2) * 2 + y, Color("5a3a22"))
		"pilotis1", "barque1":
			# Petite lanterne posée (elle luit).
			for y in range(8, 15):
				_px(img, ox + 8, y, Color("3a3028"))
			for y in range(9, 13):
				for x in range(6, 11):
					_px(img, ox + x, y, Color("f2c46b") if x != 8 else Color("fff6d0"))
		"mares0", "croc0", "sorciere0":
			# Champignon vénéneux luisant.
			for y in range(10, 16):
				_px(img, ox + 8, y, Color("c8c0b0"))
			for y in range(6, 10):
				for x in range(5, 12):
					_px(img, ox + x, y, Color("8ae050") if (x + y) % 3 else Color("d8ff8a"))
		"mares1", "croc1", "sorciere1":
			# Ossements dans la vase.
			for k in range(9):
				_px(img, ox + 3 + k, 13 - (k % 2), Color("d8d0c0"))
			for y in range(9, 13):
				for x in range(10, 14):
					_px(img, ox + x, y, Color("e8e0d0"))
			_px(img, ox + 11, 11, Color("1a1410"))
		"brume1", "hydre1":
			# Souche pourrie, couverte de mousse grise.
			for y in range(8, 16):
				for x in range(4, 12):
					_px(img, ox + x, y, Color("3a3028") if x > 5 else Color("2a2018"))
			for x in range(4, 12):
				_px(img, ox + x, 8, Color("6a7a6a"))
		"gue_morts0":
			# Stèle funéraire penchée.
			for y in range(4, 16):
				for x in range(5, 11):
					_px(img, ox + x + (16 - y) / 6, y, Color("7a7a88") if x < 9 else Color("5a5a68"))
			_px(img, ox + 8, 7, Color("3a3a48"))
			_px(img, ox + 7, 8, Color("3a3a48"))
			_px(img, ox + 9, 8, Color("3a3a48"))
		"gue_morts1":
			# Feu follet posé sur la vase (il luit).
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(0, -2)]:
				_px(img, ox + 8 + d.x, 10 + d.y, Color("bfe8ff"))
		"saules0":
			# Pierre dressée du cercle, gravée de cendre.
			for y in range(3, 16):
				for x in range(5, 11):
					_px(img, ox + x, y, Color("6a6a78") if x < 9 else Color("4a4a58"))
			_px(img, ox + 7, 7, Color("ff8a3a"))
			_px(img, ox + 8, 9, Color("ff8a3a"))
		"saules1":
			# Braises d'un feu rituel (elles luisent).
			for k in range(7):
				_px(img, ox + 4 + k, 14 - (k % 2), Color("ff8a3a") if k % 2 else Color("ffd080"))
			for x in range(3, 13):
				_px(img, ox + x, 15, Color("3a2a20"))
		"refuge0":
			# Colonne brisée.
			for y in range(5, 16):
				for x in range(5, 11):
					_px(img, ox + x, y, Color("8a8a98") if x < 9 else Color("6a6a78"))
			for x in range(4, 12):
				_px(img, ox + x, 5, Color("aaaab8"))
		"refuge1":
			# Éclat de cristal arcanique (il luit).
			for y in range(5, 16):
				var hw := (y - 5) / 3
				for x in range(-hw, hw + 1):
					_px(img, ox + 8 + x, y, Color("d8a8ff") if x >= 0 else Color("8a4ad0"))
		"route0", "caravane1":
			# Roue de chariot brisée.
			for a in range(24):
				var ang := float(a) / 24.0 * TAU
				_px(img, ox + 8 + int(round(cos(ang) * 5.0)), 10 + int(round(sin(ang) * 5.0)), Color("6a4a2a"))
			for a2 in range(4):
				var ang2 := float(a2) / 4.0 * PI + 0.3
				for r in range(5):
					_px(img, ox + 8 + int(round(cos(ang2) * float(r))), 10 + int(round(sin(ang2) * float(r))), Color("8a6a3a"))
		"route1", "caravane0":
			# Borne de pierre.
			for y in range(6, 16):
				for x in range(5, 11):
					_px(img, ox + x, y, Color("a89878") if x < 9 else Color("7a6a50"))
			_px(img, ox + 7, 8, Color("5a4a38"))
			_px(img, ox + 7, 10, Color("5a4a38"))
		"moulins0":
			# Gerbe de blé liée.
			for k in range(9):
				_blade(img, ox, 4 + k, 15, 10 - absi(k - 4), float(k - 4) * 0.25, Color("a8803a"), Color("f2d070"))
			for x in range(5, 12):
				_px(img, ox + x, 11, Color("6a4a2a"))
		"moulins1":
			# Botte de foin.
			for y in range(8, 16):
				for x in range(2, 14):
					_px(img, ox + x, y, Color("d8b050") if (x + y) % 3 else Color("a8803a"))
		"pylones0":
			# Éclat d'ambre planté (il luit).
			for y in range(3, 16):
				var half := int(3.0 * (1.0 - absf(float(y) - 10.0) / 8.0)) + 1
				for x in range(-half, half + 1):
					_px(img, ox + 8 + x, y, Color("ffd080") if x == 0 else (Color("e8a040") if x > 0 else Color("a86020")))
		"pylones1":
			# Rocher fendu, veiné d'ambre.
			for y in range(-5, 6):
				for x in range(-7, 8):
					if pow(float(x) / 7.0, 2.0) + pow(float(y) / 5.0, 2.0) <= 1.0:
						_px(img, ox + 8 + x, 10 + y, Color("8a7458") if x > 0 else Color("5a4a38"))
			for y in range(5, 15):
				_px(img, ox + 8 + (y % 2), y, Color("ffb050"))
		"gue0":
			# Roseaux de la rive.
			for k in range(7):
				_blade(img, ox, 3 + k * 2, 15, 9 + (k % 3) * 2, float(k - 3) * 0.2, Color("4a5a2a"), Color("a8a050"))
				_px(img, ox + 3 + k * 2, 15 - 9 - (k % 3) * 2, Color("6a4a2a"))
		"gue1":
			# Galets mouillés.
			for pb in [[5, 12, 3], [10, 13, 2], [8, 9, 2]]:
				for y in range(-int(pb[2]), int(pb[2]) + 1):
					for x in range(-int(pb[2]) - 1, int(pb[2]) + 2):
						_px(img, ox + int(pb[0]) + x, int(pb[1]) + y, Color("9a9a90") if y < 0 else Color("5a6060"))
				_px(img, ox + int(pb[0]), int(pb[1]) - int(pb[2]), Color("e8f0f0"))
		"repaire0", "fort1":
			# Tas d'os et un crâne.
			for k in range(8):
				_px(img, ox + 3 + k, 14 - (k % 3), Color("d8d0b8"))
				_px(img, ox + 4 + k, 15, Color("b8b098"))
			for y in range(7, 12):
				for x in range(6, 11):
					_px(img, ox + x, y, Color("e8e0c8"))
			_px(img, ox + 7, 9, Color("2a2018"))
			_px(img, ox + 9, 9, Color("2a2018"))
		"repaire1":
			# Caisse d'ambre volée qui bourdonne de violet (elle luit).
			for y in range(7, 16):
				for x in range(3, 13):
					_px(img, ox + x, y, Color("7a5a32") if (x + y) % 4 else Color("5a4024"))
			for x in range(4, 12):
				_px(img, ox + x, 9, Color("d98cff"))
				_px(img, ox + x, 13, Color("b07cff"))
		"orage0", "fort0":
			# Lance brisée plantée.
			for k in range(12):
				_px(img, ox + 6 + k / 4, 15 - k, Color("5a4030"))
			_px(img, ox + 9, 3, Color("a8a8b8"))
			_px(img, ox + 9, 2, Color("d8d8e8"))
		"orage1":
			# Petit totem de tempête.
			for y in range(4, 16):
				for x in range(6, 10):
					_px(img, ox + x, y, Color("4a3a30") if y % 4 else Color("6a5a48"))
			_px(img, ox + 7, 6, Color("9fe0ff"))
			_px(img, ox + 8, 6, Color("9fe0ff"))
		"rebouteux0":
			# Bottes d'herbes qui sèchent.
			for k in range(6):
				_blade(img, ox, 4 + k * 2, 15, 8, float(k - 3) * 0.15, Color("5a7a3a"), Color("a8d070"))
			for x in range(4, 14):
				_px(img, ox + x, 12, Color("8a6a3a"))
		"rebouteux1":
			# Crâne de bête, os en croix.
			for k in range(9):
				_px(img, ox + 3 + k, 6 + k, Color("d8d0b8"))
				_px(img, ox + 12 - k, 6 + k, Color("d8d0b8"))
			for y in range(5, 9):
				for x in range(6, 10):
					_px(img, ox + x, y, Color("e8e0c8"))
		"traite0", "traite1":
			# Petit fanion : bleu de la Prévôté (0), rouge des clans (1).
			for y in range(3, 16):
				_px(img, ox + 5, y, Color("6a4a2a"))
			var fc2 := Color("3a6ad0") if which == 0 else Color("c83a2a")
			for y in range(3, 9):
				for x in range(6, 13 - (y - 3) / 2):
					_px(img, ox + x, y, fc2 if (x + y) % 5 else fc2.lightened(0.2))
		"lisiere0":
			# Botte de foin.
			for y in range(8, 16):
				for x in range(2, 14):
					_px(img, ox + x, y, Color("c8a050") if (x + y) % 3 else Color("a8802a"))
		"lisiere1":
			# Tonneau.
			for y in range(5, 16):
				for x in range(4, 12):
					_px(img, ox + x, y, Color("6a4a2a") if x not in [4, 11] else Color("4a3420"))
			for x in range(4, 12):
				_px(img, ox + x, 7, Color("3a3a48"))
				_px(img, ox + x, 13, Color("3a3a48"))
		"clairiere0", "sylvarche0":
			# Branche cassée (ou racine qui affleure).
			for x in range(1, 15):
				var y := 13 - int(sin(float(x) / 14.0 * PI) * (5.0 if s == "sylvarche" else 2.0))
				_px(img, ox + x, y, Color("5a4030"))
				_px(img, ox + x, y + 1, Color("3a2a20"))
		"clairiere1":
			# Champignons bruns.
			for m in [[5, 10], [10, 12]]:
				for x in range(-2, 3):
					_px(img, ox + int(m[0]) + x, int(m[1]) - 2, Color("8a5a3a"))
				_px(img, ox + int(m[0]), int(m[1]) - 1, Color("e8dcc0"))
				_px(img, ox + int(m[0]), int(m[1]), Color("e8dcc0"))
		"roncier0", "coeur1":
			# Rameau d'épines.
			var p := Vector2(ox + 3, 15)
			for k in range(14):
				_px(img, int(p.x), int(p.y), Color("2a1430"))
				if k % 3 == 1:
					_px(img, int(p.x) + 1, int(p.y) - 1, Color("b07cff"))
				p += Vector2(0.7, -0.8)
		"roncier1":
			# Pierre runique tombée.
			for y in range(9, 15):
				for x in range(2, 14):
					_px(img, ox + x, y, Color("4a4660"))
			_px(img, ox + 7, 11, Color("d93cf2"))
			_px(img, ox + 8, 12, Color("d93cf2"))
		"sentier0", "source1":
			# Pierre plate (ou nénuphar).
			for y in range(-2, 3):
				for x in range(-6, 7):
					if pow(float(x) / 6.0, 2.0) + pow(float(y) / 2.0, 2.0) <= 1.0:
						_px(img, ox + 8 + x, 13 + y, Color("5a5a70") if s == "sentier" else Color("3f7a4a"))
			if s == "source":
				_px(img, ox + 9, 12, Color("f4f0ff"))
		"sentier1", "fougeres1", "sylvarche1":
			# Fleur lumineuse (luciole posée, fleur de lune, champignon violet).
			_blade(img, ox, 8, 15, 6, 0.0, Color("2f5a3a"), Color("4f8a54"))
			var col: Color = Color("f2e28b") if s == "sentier" else (Color("e8f0ff") if s == "fougeres" else Color("b07cff"))
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				_px(img, ox + 8 + d.x, 8 + d.y, col)
		"fougeres0":
			# Grande fronde.
			for k in range(14):
				_px(img, ox + 2 + k, 15 - int(float(k) * 0.9), Color("2f6a44"))
				_px(img, ox + 2 + k, 14 - int(float(k) * 0.9), Color("4f8a54"))
		"cercle0", "cercle1":
			# Champignon de fée (petit ou grand).
			var r := 3 if which == 0 else 5
			for y in range(-r + 1, 1):
				for x in range(-r, r + 1):
					if absi(x) <= r + y:
						_px(img, ox + 8 + x, 9 + y, Color("f7a8e0"))
			for y in range(10, 16):
				_px(img, ox + 8, y, Color("e8dcc0"))
				_px(img, ox + 9, y, Color("c8bca0"))
			_px(img, ox + 7, 8, Color.WHITE)
		"source0":
			# Roseaux.
			for k in range(5):
				_blade(img, ox, 3 + k * 2, 15, 11 + (k % 2) * 3, 0.3, Color("2f6a44"), Color("6a8a4a"))
			_px(img, ox + 5, 4, Color("6a4a2a"))
			_px(img, ox + 5, 5, Color("6a4a2a"))
		"coeur0":
			# Éclat de cristal.
			for y in range(16):
				var half := int(4.0 * (1.0 - absf(float(y) - 9.0) / 9.0))
				for x in range(-half, half + 1):
					_px(img, ox + 8 + x, 15 - y, Color("5a2a7a") if x < 0 else Color("d98cff"))
		_:
			_blade(img, ox, 8, 15, 8, 0.0, Color("2f5a3a"), Color("4f8a54"))


## Planche d'arbres du lieu (6 images de 28×48) : 0-2 sapins, 3-4 feuillus, 5 arbre mort (ou lumineux au cercle).
static func tree_atlas(s: String) -> ImageTexture:
	var fw := 28
	var fh := 48
	var img := Image.create_empty(fw * 6, fh, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(s) + 3
	var violet := s in ["roncier", "coeur", "sylvarche"]
	# Sapins : étages de branches, ombre à gauche, lune à droite.
	var dark := [Color("0f2420"), Color("12281f"), Color("102a26")]
	var mid := [Color("1d3d33"), Color("1f4336"), Color("1a3a34")]
	var lit := [Color("3a6a5a"), Color("3f7058"), Color("3a6670")]
	for v in range(3):
		var cx := v * fw + fw / 2
		img.fill_rect(Rect2i(cx - 1, fh - 8, 3, 8), Color("2a1e18"))
		var layers := 6 + v
		for l in range(layers):
			var top := 2 + int(float(l) * float(fh - 14) / float(layers))
			var bottom := top + 11 + l
			for y in range(top, mini(bottom, fh - 6)):
				var half := mini(int(float(y - top + 1) * (0.5 + 0.05 * float(v)) + 1.0), fw / 2 - 1)
				for x in range(-half, half + 1):
					var c: Color = mid[v]
					if x < -half + 2:
						c = dark[v]
					elif x > half - 3 and y % 3 != 0:
						c = lit[v]
					if absi(x) == half and rng.randf() < 0.45:
						continue
					if violet:
						c = c.lerp(Color("3a2450"), 0.35)
					_px(img, cx + x, y, c)
		_px(img, cx, 1, lit[v])
	# Feuillus : tronc et couronne en grappes.
	var leaf := [Color("1f3a26"), Color("2f5a36"), Color("4f8a4a")]
	if s == "source":
		leaf = [Color("1a3a36"), Color("2a5a4e"), Color("4a8a7a")]
	elif violet:
		leaf = [Color("2a1a40"), Color("4a2a6a"), Color("7a4aa8")]
	elif s == "clairiere":
		leaf = [Color("2a3a1e"), Color("4a5a2a"), Color("8a8a3a")]
	elif s in ["moulins", "gue", "traite"]:
		# Vergers et rives : feuillage encore vert, doré par le soleil.
		leaf = [Color("2f4a26"), Color("4f6a36"), Color("8f9a4a")]
	elif s in ["route", "caravane", "pylones", "repaire", "rebouteux"]:
		leaf = [Color("4a3a1a"), Color("7a6a2a"), Color("b89a3a")]
	elif s in STORM_SCENES:
		leaf = [Color("2a2a22"), Color("3a3a2a"), Color("5a5a3a")]
	var willow: bool = s in ["pilotis", "mares", "brume", "gue_morts", "croc", "saules", "barque", "sorciere", "refuge", "hydre"]
	for v in range(2 if not willow else 0):
		var ox := (3 + v) * fw
		var cx2 := ox + fw / 2
		for y in range(fh - 18, fh):
			img.fill_rect(Rect2i(cx2 - 2 + (1 if y < fh - 10 else 0), y, 4 - (1 if y < fh - 10 else 0), 1), Color("3a2a22"))
		_px(img, cx2 + 1, fh - 12, Color("5a4232"))
		for blob in [[0, 16, 12, 11], [-6, 22, 8, 7], [6, 22, 8, 7], [0, 9, 9, 7], [-4 + v * 8, 28, 6, 5]]:
			var bx: int = cx2 + int(blob[0])
			var by: int = int(blob[1])
			var rx: int = int(blob[2])
			var ry: int = int(blob[3])
			for y in range(-ry, ry + 1):
				for x in range(-rx, rx + 1):
					var d := pow(float(x) / float(rx), 2.0) + pow(float(y) / float(ry), 2.0)
					if d > 1.0 or (d > 0.85 and rng.randf() < 0.5):
						continue
					var c: Color = leaf[1]
					if x > rx / 3 and y < 0:
						c = leaf[2]
					elif x < -rx / 3 or y > ry / 2:
						c = leaf[0]
					_px(img, bx + x, by + y, c)
	if willow:
		# Saules pleureurs du marais : tronc tordu, dôme de feuillage, longues mèches qui tombent.
		var wl := [Color("1e2e24"), Color("2e4434"), Color("4a6a4a")]
		for v in range(2):
			var oxw := (3 + v) * fw
			var cxw := oxw + fw / 2
			for y in range(fh - 22, fh):
				var bend := int(sin(float(y) * 0.2 + float(v)) * 1.5)
				img.fill_rect(Rect2i(cxw - 2 + bend, y, 4, 1), Color("2a2420"))
			for y in range(-9, 10):
				for x in range(-12, 13):
					var dd := pow(float(x) / 12.0, 2.0) + pow(float(y) / 9.0, 2.0)
					if dd <= 1.0 and not (dd > 0.8 and rng.randf() < 0.5):
						_px(img, cxw + x, 14 + y, wl[2] if (x > 3 and y < -2) else (wl[0] if y > 4 else wl[1]))
			for k in range(22):
				var sx4 := cxw + rng.randi_range(-12, 12)
				var sy4 := 14 + rng.randi_range(-2, 7)
				var ln := rng.randi_range(8, 24)
				for d in range(ln):
					_px(img, sx4 + int(sin(float(d) * 0.3) * 0.8), sy4 + d, wl[1] if d < ln - 3 else wl[0])
	# Arbre mort (branches nues) ou arbre lumineux du cercle des fées.
	var ox3 := 5 * fw
	var cx3 := ox3 + fw / 2
	if s == "cercle":
		for y in range(fh - 16, fh):
			img.fill_rect(Rect2i(cx3 - 1, y, 3, 1), Color("4a3a48"))
		for blob in [[0, 18, 11, 10], [-6, 26, 7, 6], [6, 26, 7, 6], [0, 10, 8, 6]]:
			var bx2: int = cx3 + int(blob[0])
			for y in range(-int(blob[3]), int(blob[3]) + 1):
				for x in range(-int(blob[2]), int(blob[2]) + 1):
					var d2 := pow(float(x) / float(blob[2]), 2.0) + pow(float(y) / float(blob[3]), 2.0)
					if d2 <= 1.0 and not (d2 > 0.8 and rng.randf() < 0.5):
						var pc := Color("8a4a7a")
						if x > 0 and y < 0:
							pc = Color("c87ab0")
						elif x < -2 or y > 2:
							pc = Color("5a2a5a")
						if rng.randf() < 0.07:
							pc = Color("ffd8f4")
						_px(img, bx2 + x, int(blob[1]) + y, pc)
	else:
		var trunk := Color("2a2026") if violet else Color("3a2e2a")
		for y in range(10, fh):
			var half3 := 1 + int(float(y - 10) / 14.0)
			img.fill_rect(Rect2i(cx3 - half3, y, half3 * 2, 1), trunk)
		for br in [[16, -1, 9, -7], [22, 1, 9, -6], [13, 1, 6, -9], [28, -1, 7, -4], [19, -1, 5, -10]]:
			var p := Vector2(cx3, br[0])
			for k in range(int(br[2])):
				_px(img, int(p.x), int(p.y), trunk)
				p += Vector2(float(br[1]) * 0.9, float(br[3]) / float(br[2]))
			if violet:
				_px(img, int(p.x), int(p.y), Color("b07cff"))
	var tp := scene_palette(s)
	if tp.has("warm_h"):
		_zone_tint(img, float(tp["warm_h"]), float(tp.get("lift", 1.0)))
	return _tex(img)


## Sol de la zone 1, plus riche : taches de couleur (bruit), brins d'herbe, cailloux, bords du chemin envahis,
## ombre le long des bords de l'arène.
static func _ground_richness(img: Image, rng: RandomNumberGenerator, x0: int, x1: int, y_top: int, y_bot: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	# Bruit de valeur : une grille grossière interpolée.
	var cell := 12
	var gw := w / cell + 2
	var gh := h / cell + 2
	var grid := PackedFloat32Array()
	grid.resize(gw * gh)
	for i in range(gw * gh):
		grid[i] = rng.randf_range(-1.0, 1.0)
	for y in range(h):
		for x in range(w):
			if x >= x0 - 2 and x <= x1 + 2 and y >= y_top and y <= y_bot:
				continue
			var fx := float(x) / float(cell)
			var fy := float(y) / float(cell)
			var ix := int(fx)
			var iy := int(fy)
			var tx := fx - float(ix)
			var ty := fy - float(iy)
			var a := lerpf(grid[iy * gw + ix], grid[iy * gw + ix + 1], tx)
			var b := lerpf(grid[(iy + 1) * gw + ix], grid[(iy + 1) * gw + ix + 1], tx)
			var n := lerpf(a, b, ty)
			var c := _pget(img, x, y)
			c = c.lightened(n * 0.09) if n > 0.0 else c.darkened(-n * 0.12)
			img.set_pixel(x, y, Color(c.r + n * 0.012, c.g + n * 0.02, c.b - n * 0.01, 1.0))
	# Brins d'herbe : base sombre, pointe claire.
	for i in range(w * h / 22):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(2, h - 1)
		if x >= x0 and x <= x1 and y >= y_top and y <= y_bot:
			continue
		var base := _pget(img, x, y)
		_px(img, x, y, base.darkened(0.18))
		_px(img, x, y - 1, base.lightened(0.12))
		if rng.randf() < 0.4:
			_px(img, x + (1 if rng.randf() < 0.5 else -1), y - 2, base.lightened(0.22))
	# Bords du chemin envahis par l'herbe.
	for y in range(y_top, y_bot):
		for side in [x0, x1]:
			for k in range(rng.randi_range(0, 3)):
				var gx: int = side + (k if side == x0 else -k)
				var gc := _pget(img, side - 3 if side == x0 else side + 3, y)
				_px(img, gx, y, gc.lightened(0.05))
	# Petits cailloux.
	for i in range(w * h / 500):
		var x2 := rng.randi_range(0, w - 1)
		var y2 := rng.randi_range(0, h - 1)
		_px(img, x2, y2, Color("5a5a6e"))
		_px(img, x2 + 1, y2, Color("3e3e52"))
	# Ombre le long des bords de l'arène.
	for y in range(h):
		for k in range(7):
			var a2 := 0.22 * (1.0 - float(k) / 7.0)
			for x in [k, w - 1 - k]:
				img.set_pixel(x, y, _pget(img, x, y).darkened(a2))


# ---------------------------------------------------------------- zone 2 · objets des combats (couleurs finales)

## Moulin à vent : tour de pierre chaulée, toit de bois, quatre ailes de toile.
static func windmill_texture() -> ImageTexture:
	var img := _sprite(30, 46)
	for y in range(18, 46):
		var half := int(lerpf(4.0, 7.0, float(y - 18) / 28.0))
		for x in range(-half, half + 1):
			_px(img, 15 + x, y, Color("e8dcc0") if x > -half + 2 else Color("b8a888"))
	for y in range(12, 19):
		var half2 := 8 - (y - 12)
		for x in range(-half2, half2 + 1):
			_px(img, 15 + x, y, Color("8a5a3a") if x < 0 else Color("a8704a"))
	img.fill_rect(Rect2i(13, 38, 4, 8), Color("5a3a22"))
	_px(img, 15, 28, Color("4a3a30"))
	for a: float in [0.6, 0.6 + PI * 0.5, 0.6 + PI, 0.6 + PI * 1.5]:
		var d := Vector2.from_angle(a)
		var n := d.orthogonal()
		for k in range(4, 15):
			var p := Vector2(15, 15) + d * float(k)
			_px(img, int(p.x), int(p.y), Color("6a4a2a"))
			for w2 in range(1, 4):
				var q := p + n * float(w2)
				_px(img, int(q.x), int(q.y), Color("f0e8d8") if (k + w2) % 3 else Color("c8b898"))
	return _tex(img)


## Tente : peau tendue sur des perches (repaire, rebouteux) ou toile aux couleurs d'un camp (traité).
static func tent_texture(body: Color, trim: Color) -> ImageTexture:
	var img := _sprite(28, 22)
	for y in range(4, 22):
		var half := int(float(y - 4) * 0.75) + 1
		for x in range(-half, half + 1):
			var c := body if x > 0 else body.darkened(0.25)
			if y == 21 or absi(x) == half:
				c = trim
			_px(img, 14 + x, y, c)
	for y in range(12, 22):
		_px(img, 14, y, Color("1a1410"))
		_px(img, 13, y, Color("2a2018") if y > 14 else body.darkened(0.4))
	for k in range(5):
		_px(img, 12 - k / 2, 3 - k / 2, Color("6a4a2a"))
		_px(img, 16 + k / 2, 3 - k / 2, Color("6a4a2a"))
	return _tex(img)


## Palissade : pieux taillés en pointe, liés par une corde.
static func palisade_texture() -> ImageTexture:
	var img := _sprite(32, 26)
	for k in range(8):
		var x0 := k * 4
		var top := 2 + (k % 3)
		for y in range(top, 26):
			for x in range(x0, x0 + 3):
				var c := Color("6a4a2a") if x == x0 else Color("8a6a40")
				if y < top + 2:
					c = Color("a8885a")
				_px(img, x, y, c)
	for x in range(32):
		_px(img, x, 10, Color("4a3420"))
		_px(img, x, 18, Color("4a3420"))
	return _tex(img)


## Totem des clans : têtes sculptées ; celui de l'orage porte des yeux qui crépitent.
static func totem_texture(storm: bool) -> ImageTexture:
	var img := _sprite(14, 36)
	for y in range(2, 36):
		for x in range(3, 11):
			var band := y / 8
			var c := Color("6a4a30") if band % 2 == 0 else Color("8a5a3a")
			if x == 3:
				c = c.darkened(0.3)
			_px(img, x, y, c)
		if y % 8 == 3:
			_px(img, 5, y, Color("9fe0ff") if storm else Color("f2c46b"))
			_px(img, 8, y, Color("9fe0ff") if storm else Color("f2c46b"))
		if y % 8 == 6:
			for x2 in range(5, 9):
				_px(img, x2, y, Color("2a1810"))
	for x in range(0, 14):
		_px(img, x, 4, Color("c83a2a"))
	return _tex(img)


## Chariot : caisse de bois sur deux roues ; brûlé, il est noirci et fume.
static func cart_texture(burnt: bool) -> ImageTexture:
	var img := _sprite(30, 20)
	var wood := Color("2a2220") if burnt else Color("8a6a40")
	var dark := Color("1a1614") if burnt else Color("5a4028")
	for y in range(5, 14):
		for x in range(2, 28):
			_px(img, x, y, wood if (x + y) % 5 else dark)
	if not burnt:
		for y in range(1, 6):
			for x in range(4, 26):
				_px(img, x, y, Color("e8dcc0") if y > 1 else Color("c8b898"))
	for cx: int in [8, 22]:
		for a in range(20):
			var ang := float(a) / 20.0 * TAU
			_px(img, cx + int(round(cos(ang) * 4.0)), 15 + int(round(sin(ang) * 4.0)), dark)
		_px(img, cx, 15, Color("3a3a40"))
	if burnt:
		for k in range(10):
			_px(img, 4 + k * 2, 5, Color("ff8a3a") if k % 3 == 0 else Color("3a2a20"))
	return _tex(img)


## Caisse (d'ambre volée : elle bourdonne de violet).
static func crate_texture(amber: bool) -> ImageTexture:
	var img := _sprite(14, 12)
	for y in range(12):
		for x in range(14):
			var c := Color("8a6a40") if (x + y) % 4 else Color("6a4a2a")
			if x == 0 or y == 0 or x == 13 or y == 11:
				c = Color("4a3420")
			_px(img, x, y, c)
	if amber:
		for x in range(2, 12):
			_px(img, x, 4, Color("d98cff"))
			_px(img, x, 7, Color("b07cff"))
	return _tex(img)


## Flèche d'ambre : un grand cristal sur un socle de pierre.
static func amber_spire_texture() -> ImageTexture:
	var img := _sprite(16, 34)
	for y in range(26):
		var half := int(6.0 * (1.0 - absf(float(y) - 17.0) / 17.0)) if y < 17 else int(6.0 * (1.0 - float(y - 17) / 11.0))
		for x in range(-half, half + 1):
			var c := Color("a86020") if x < 0 else Color("e8a040")
			if x == 0 or (x == 1 and y % 4 == 0):
				c = Color("ffe0a0")
			_px(img, 8 + x, y, c)
	for y in range(26, 34):
		for x in range(2, 14):
			_px(img, x, y, Color("8a7458") if x > 5 else Color("5a4a38"))
	return _tex(img)


## Étendard planté : bleu de la Prévôté, rouge des clans, ou rouge au crâne (Gharok).
static func banner_pole_texture(col: Color, skull: bool) -> ImageTexture:
	var img := _sprite(16, 40)
	for y in range(0, 40):
		_px(img, 3, y, Color("5a3a22"))
		_px(img, 4, y, Color("7a5a32"))
	_px(img, 3, 0, Color("d8c890"))
	_px(img, 4, 0, Color("d8c890"))
	for y in range(3, 22):
		for x in range(5, 15):
			if y > 18 and (x + y) % 3 == 0:
				continue
			_px(img, x, y, col if (x + y / 3) % 6 else col.lightened(0.18))
	if skull:
		for y in range(8, 13):
			for x in range(8, 12):
				_px(img, x, y, Color("e8e0c8"))
		_px(img, 9, 10, Color("2a1810"))
		_px(img, 11, 10, Color("2a1810"))
	else:
		for x in range(7, 13):
			_px(img, x, 11, col.lightened(0.45))
	return _tex(img)


## Séchoir du rebouteux : cadre de perches, herbes et os qui pendent.
static func rack_texture() -> ImageTexture:
	var img := _sprite(26, 24)
	for y in range(2, 24):
		_px(img, 2, y, Color("6a4a2a"))
		_px(img, 23, y, Color("6a4a2a"))
	for x in range(2, 24):
		_px(img, x, 3, Color("7a5a32"))
	for k in range(6):
		var x0 := 4 + k * 3
		var long := 5 + (k * 3) % 5
		for y in range(4, 4 + long):
			_px(img, x0, y, Color("8aa850") if k % 2 == 0 else Color("e8e0c8"))
		_px(img, x0, 4 + long, Color("5a7a3a") if k % 2 == 0 else Color("c8c0a8"))
	return _tex(img)


## Tour de guet de la palissade de Gharok.
static func watchtower_texture() -> ImageTexture:
	var img := _sprite(22, 48)
	for y in range(14, 48):
		for x: int in [4, 17]:
			_px(img, x, y, Color("5a3a22"))
			_px(img, x + 1, y, Color("7a5a32"))
		if y % 8 == 0:
			for x2 in range(4, 19):
				_px(img, x2, y + (x2 - 4) / 5, Color("6a4a2a"))
	for y in range(6, 15):
		for x in range(2, 20):
			_px(img, x, y, Color("8a6a40") if (x + y) % 4 else Color("6a4a2a"))
	for y in range(0, 6):
		var half := 10 - y * 2
		for x in range(-half, half + 1):
			_px(img, 11 + x, y + 2, Color("4a3420"))
	_px(img, 11, 9, Color("ff9b4a"))
	_px(img, 12, 9, Color("ffd080"))
	return _tex(img)


## Collines d'Ambre : l'horizon du lieu, entre les deux rangs de collines.
static func _backdrop_hills(img: Image, rng: RandomNumberGenerator, s: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var base := int(h * 0.53)
	match s:
		"route":
			# Une colonne de fumée noire monte au loin (la caravane attaquée).
			var cx := int(w * 0.3)
			for y in range(int(h * 0.12), base):
				var t := float(base - y) / float(base - int(h * 0.12))
				var half := int(2.0 + t * 9.0)
				var off := int(sin(float(y) * 0.06) * 4.0 * t) + int(t * 14.0)
				for x in range(-half, half + 1):
					_px(img, cx + off + x, y, Color(0.12, 0.1, 0.1, 0.55 * (1.0 - t * 0.6)))
		"moulins", "caravane":
			# Moulins sur la crête.
			for k in range(4 if s == "moulins" else 2):
				var mx := int(w * (0.15 + 0.22 * float(k))) + rng.randi_range(-6, 6)
				img.fill_rect(Rect2i(mx - 2, base - 12, 4, 12), Color("c8b8a0"))
				for a: float in [0.3, 0.3 + PI * 0.5, 0.3 + PI, 0.3 + PI * 1.5]:
					for r in range(1, 9):
						_px(img, mx + int(cos(a) * float(r)), base - 12 + int(sin(a) * float(r)), Color("e8dcc0"))
		"pylones":
			# Flèches d'ambre qui luisent sur l'horizon.
			for k in range(7):
				var px := int(w * (0.1 + 0.13 * float(k))) + rng.randi_range(-5, 5)
				var ph := rng.randi_range(8, 18)
				for y in range(ph):
					var half2 := int(float(y) * 0.25)
					for x in range(-half2, half2 + 1):
						_px(img, px + x, base - ph + y, Color("e8a040") if x >= 0 else Color("a86020"))
				for r2 in range(2, 7):
					_disc(img, px, base - ph, r2, Color(1.0, 0.7, 0.3, 0.04))
		"gue":
			# La rivière descend des collines.
			for y in range(base - 4, h):
				var t2 := float(y - base + 4) / float(h - base + 4)
				var cx2 := int(w * 0.5 + sin(t2 * 4.0) * w * 0.12)
				var half3 := int(2.0 + t2 * w * 0.06)
				for x in range(-half3, half3 + 1):
					_px(img, cx2 + x, y, Color(0.45, 0.65, 0.75, 0.75))
				_px(img, cx2 - half3 / 2, y, Color(0.85, 0.95, 1.0, 0.5))
		"repaire", "rebouteux":
			# Palissade, tentes et fumées des feux de camp.
			for k in range(-30, 31):
				var ph2 := 5 + (2 if absi(k) % 3 == 0 else 0)
				img.fill_rect(Rect2i(int(w * 0.3) + k, base - ph2, 1, ph2), Color("4a3828"))
			for k2 in range(5):
				var tx := int(w * (0.45 + 0.1 * float(k2)))
				for y in range(7):
					img.fill_rect(Rect2i(tx - y, base - 7 + y, y * 2 + 1, 1), Color("7a5a3a") if s == "repaire" else Color("8a8a5a"))
			for k3 in range(3):
				var sx2 := int(w * (0.25 + 0.25 * float(k3)))
				for y in range(int(h * 0.25), base):
					var t3 := float(base - y) / float(base - int(h * 0.25))
					_px(img, sx2 + int(sin(float(y) * 0.1) * 3.0 * t3), y, Color(0.4, 0.38, 0.36, 0.35 * (1.0 - t3)))
					_px(img, sx2 + 1 + int(sin(float(y) * 0.1) * 3.0 * t3), y, Color(0.4, 0.38, 0.36, 0.25 * (1.0 - t3)))
		"orage":
			# Totems de tempête sur la crête.
			for k in range(5):
				var tx2 := int(w * (0.12 + 0.18 * float(k)))
				img.fill_rect(Rect2i(tx2 - 1, base - 14, 3, 14), Color("2a2420"))
				_px(img, tx2, base - 12, Color("9fe0ff"))
		"traite":
			# Les deux camps face à face : tentes bleues à gauche, rouges à droite.
			for k in range(8):
				var left := k < 4
				var tx3 := int(w * (0.08 + 0.1 * float(k) + (0.1 if not left else 0.0)))
				var col := Color("3a6ad0") if left else Color("c83a2a")
				for y in range(6):
					img.fill_rect(Rect2i(tx3 - y, base - 6 + y, y * 2 + 1, 1), col.darkened(0.2 if y % 2 else 0.0))
				img.fill_rect(Rect2i(tx3, base - 12, 1, 6), Color("4a3420"))
				img.fill_rect(Rect2i(tx3 + 1, base - 12, 3, 2), col)
		"fort":
			# Le fort de Gharok, tout proche : palissade haute, tours, étendards rouges.
			var fx := int(w * 0.5)
			for k in range(-int(w * 0.3), int(w * 0.3)):
				var ph3 := 16 + (4 if absi(k) % 4 == 0 else 0)
				img.fill_rect(Rect2i(fx + k, base - ph3, 1, ph3), Color("2a2018"))
			for tk: float in [-0.28, -0.1, 0.1, 0.28]:
				var tx4 := fx + int(float(w) * tk)
				img.fill_rect(Rect2i(tx4 - 4, base - 32, 9, 32), Color("221a14"))
				img.fill_rect(Rect2i(tx4 - 6, base - 34, 13, 3), Color("2a2018"))
				img.fill_rect(Rect2i(tx4, base - 44, 1, 10), Color("1a1410"))
				img.fill_rect(Rect2i(tx4 + 1, base - 44, 6, 4), Color("a82a2a"))
				_px(img, tx4, base - 26, Color("ff9b4a"))


## Meule de foin des champs des moulins.
static func haystack_texture() -> ImageTexture:
	var img := _sprite(22, 18)
	for y in range(2, 18):
		var half := int(10.0 * sqrt(clampf(float(y - 1) / 16.0, 0.0, 1.0)))
		for x in range(-half, half + 1):
			var c := Color("d8b050") if x > -half / 2 else Color("a8803a")
			if (x * 3 + y * 5) % 7 == 0:
				c = Color("f2d070")
			_px(img, 11 + x, y, c)
	for x in range(2, 20):
		_px(img, x, 9, Color("8a6a2a"))
	return _tex(img)


## Borne de la route d'Ambre : pierre dressée, gravée.
static func milestone_texture() -> ImageTexture:
	var img := _sprite(10, 18)
	for y in range(2, 18):
		for x in range(1, 9):
			if y < 4 and (x == 1 or x == 8):
				continue
			_px(img, x, y, Color("b8a888") if x < 6 else Color("8a7a60"))
	for y: int in [6, 9, 12]:
		for x in range(3, 7):
			_px(img, x, y, Color("5a4a38"))
	return _tex(img)



# ---------------------------------------------------------------- zone 3 · objets des combats (couleurs finales)

## Maison sur pilotis : cabane de planches, toit de roseaux, fenêtre allumée, pieux dans l'eau.
static func stilt_house_texture() -> ImageTexture:
	var img := _sprite(30, 38)
	for p in [4, 12, 20, 26]:
		for y in range(24, 38):
			_px(img, p, y, Color("2a2018"))
			_px(img, p + 1, y, Color("3a2e22"))
	for y in range(12, 25):
		for x in range(3, 28):
			_px(img, x, y, Color("4a3a2a") if (y % 3) else Color("3a2e22"))
	for y in range(2, 13):
		var half := (y - 2) + 3
		for x in range(-half, half + 1):
			_px(img, 15 + x, y, Color("6a6a48") if (x + y) % 3 else Color("4a4a32"))
	for y in range(16, 21):
		for x in range(17, 22):
			_px(img, x, y, Color("f2c46b") if y > 16 else Color("fff0b0"))
	for x in range(1, 30):
		_px(img, x, 24, Color("2a2018"))
	return _tex(img)


## Stèle et croix penchée du gué des morts.
static func grave_texture() -> ImageTexture:
	var img := _sprite(14, 22)
	for y in range(4, 22):
		for x in range(3, 11):
			if y < 6 and (x == 3 or x == 10):
				continue
			_px(img, x + (22 - y) / 8, y, Color("7a7a88") if x < 8 else Color("5a5a68"))
	for x in range(5, 9):
		_px(img, x + 2, 9, Color("3a3a48"))
	_px(img, 8, 8, Color("3a3a48"))
	_px(img, 8, 10, Color("3a3a48"))
	return _tex(img)


## Cage thoracique d'une bête noyée (repaire du Crocodile-liche, antre de l'Hydre).
static func ribcage_texture() -> ImageTexture:
	var img := _sprite(30, 20)
	for x in range(2, 28):
		_px(img, x, 17, Color("c8c0a8"))
		_px(img, x, 18, Color("a8a088"))
	for k in range(6):
		var bx := 4 + k * 4
		for y in range(4 + absi(k - 3), 17):
			var dx := int(sin(float(y) * 0.25) * 1.5)
			_px(img, bx + dx, y, Color("e8e0d0"))
			_px(img, bx + dx + 1, y, Color("c8c0a8"))
	return _tex(img)


## Chaudron de la sorcière sur son feu, bouillon vert.
static func cauldron_texture() -> ImageTexture:
	var img := _sprite(20, 18)
	for y in range(5, 15):
		var half := int(8.0 * sqrt(maxf(0.0, 1.0 - pow(float(y - 9) / 7.0, 2.0)))) + 1
		for x in range(-half, half + 1):
			_px(img, 10 + x, y, Color("2a2a30") if x < 3 else Color("4a4a58"))
	for x in range(3, 18):
		_px(img, x, 5, Color("6aa83a"))
		_px(img, x, 4, Color("a8e050") if x % 3 else Color("d8ff8a"))
	for x in range(5, 16):
		_px(img, x, 16 + (x % 2), Color("ff8a3a") if x % 2 else Color("ffd080"))
	return _tex(img)


## Barque amarrée.
static func boat_texture() -> ImageTexture:
	var img := _sprite(32, 12)
	for y in range(4, 11):
		var inset := (y - 4) / 2
		for x in range(1 + inset, 31 - inset):
			_px(img, x, y, Color("5a4630") if y > 5 else Color("7a5a3a"))
	for x in range(2, 30):
		_px(img, x, 4, Color("8a6a40"))
	for y in range(0, 5):
		_px(img, 16, y, Color("3a2a1a"))
	return _tex(img)


## Pierre dressée du Cercle des Cendres, runes de braise.
static func ash_stone_texture() -> ImageTexture:
	var img := _sprite(12, 26)
	for y in range(2, 26):
		for x in range(2, 10):
			if y < 4 and (x == 2 or x == 9):
				continue
			_px(img, x, y, Color("6a6a74") if x < 7 else Color("4a4a54"))
	for y: int in [7, 12, 17]:
		_px(img, 5, y, Color("ff8a3a"))
		_px(img, 6, y + 1, Color("ffd080"))
	return _tex(img)


## Pilier en ruine du refuge de l'adepte (cristal arcanique au sommet).
static func ruin_pillar_texture() -> ImageTexture:
	var img := _sprite(14, 34)
	for y in range(8, 34):
		for x in range(3, 11):
			if y < 11 and x > 8:
				continue
			_px(img, x, y, Color("8a8a98") if x < 8 else Color("6a6a78"))
	for y in range(0, 9):
		var hw := y / 3
		for x in range(-hw, hw + 1):
			_px(img, 7 + x, y, Color("d8a8ff") if x >= 0 else Color("8a4ad0"))
	return _tex(img)


## Crâne de bête géante échoué sur la rive (antre de l'Hydre).
static func big_skull_texture() -> ImageTexture:
	var img := _sprite(28, 20)
	for y in range(2, 18):
		var half := int(12.0 * sqrt(maxf(0.0, 1.0 - pow(float(y - 9) / 9.0, 2.0))))
		for x in range(-half, half + 1):
			_px(img, 14 + x, y, Color("e0d8c8") if x < 4 else Color("b8b0a0"))
	for e in [Vector2i(9, 8), Vector2i(19, 8)]:
		for y in range(-2, 3):
			for x in range(-2, 3):
				_px(img, e.x + x, e.y + y, Color("1a1410"))
	for x in range(6, 23, 3):
		for y in range(15, 20):
			_px(img, x, y, Color("e8e0d0"))
	return _tex(img)



# ---------------------------------------------------------------- zone 4 · objets des combats (couleurs finales)

## Statue naine taillée dans la roche, barbe tressée, hache au repos, chapeau de neige.
static func dwarf_statue_texture() -> ImageTexture:
	var img := _sprite(20, 40)
	for y in range(30, 40):
		for x in range(2, 18):
			_px(img, x, y, Color("5a6a88") if x < 12 else Color("3a4a68"))
	for y in range(10, 30):
		var half := 6 + (y - 10) / 6
		for x in range(-half, half + 1):
			_px(img, 10 + x, y, Color("7a8aa8") if x < 2 else Color("5a6a88"))
	for y in range(2, 11):
		for x in range(-4, 5):
			if Vector2(float(x), float(y) - 6.0).length() <= 4.8:
				_px(img, 10 + x, y, Color("8a9ab8") if x < 1 else Color("6a7a98"))
	for y in range(9, 22):
		_px(img, 10, y, Color("aab8d0"))
		_px(img, 9 + (y % 2), y, Color("9aa8c0"))
	for y in range(12, 30):
		_px(img, 17, y, Color("4a3a30"))
	for y in range(12, 18):
		for x in range(14, 20):
			if absi(x - 17) + absi(y - 14) < 4:
				_px(img, x, y, Color("aab8d0"))
	for x in range(5, 16):
		_px(img, x, 2, Color("f4f8ff"))
		_px(img, x, 1, Color("ffffff"))
	_px(img, 8, 6, Color("8fe3f2"))
	_px(img, 12, 6, Color("8fe3f2"))
	return _tex(img)


## Pilier runique : pierre sombre, runes cyan qui luisent, chapeau de neige.
static func rune_pillar_texture() -> ImageTexture:
	var img := _sprite(12, 34)
	for y in range(3, 34):
		for x in range(2, 10):
			_px(img, x, y, Color("4a5a78") if x < 7 else Color("2e3a58"))
	for y: int in [8, 14, 20, 26]:
		for x in range(4, 8):
			_px(img, x, y, Color("8fe3f2") if x % 2 == 0 else Color("c8f8ff"))
	for x in range(1, 11):
		_px(img, x, 2, Color("f4f8ff"))
		_px(img, x, 3, Color("dceaf6"))
	return _tex(img)


## Brasero nain : vasque de fer sur pied, feu.
static func brazier_texture() -> ImageTexture:
	var img := _sprite(14, 22)
	for y in range(10, 22):
		_px(img, 7, y, Color("3a3a48"))
		_px(img, 6, y, Color("4a4a58"))
	for x in range(3, 12):
		_px(img, x, 21, Color("3a3a48"))
	for y in range(6, 10):
		for x in range(2 + (y - 6) / 2, 13 - (y - 6) / 2):
			_px(img, x, y, Color("5a5a68") if x < 8 else Color("3a3a48"))
	for k in range(9):
		_px(img, 3 + k, 5 - (k % 3), Color("ffd080") if k % 2 else Color("ff8a3a"))
	_px(img, 7, 1, Color("fff0b0"))
	return _tex(img)


## Flèche de glace : un grand cristal translucide.
static func ice_spire_texture() -> ImageTexture:
	var img := _sprite(16, 36)
	for y in range(36):
		var half := int(6.0 * (float(y) / 24.0)) if y < 24 else 6 - (y - 24) / 3
		for x in range(-half, half + 1):
			var c := Color("4a8ab0") if x < 0 else Color("8fd0f0")
			if x == 0 or (x == 1 and y % 5 == 0):
				c = Color("e8f8ff")
			_px(img, 8 + x, y, c)
	return _tex(img)


## Wagonnet runique sur ses rails, caisse cerclée de fer, runes cyan.
static func minecart_texture() -> ImageTexture:
	var img := _sprite(26, 18)
	for y in range(3, 13):
		var inset := (12 - y) / 4
		for x in range(2 + inset, 24 - inset):
			_px(img, x, y, Color("6a4a32") if (x + y) % 5 else Color("4a3222"))
	for x in range(2, 24):
		_px(img, x, 3, Color("8a8a98"))
		_px(img, x, 8, Color("5a5a68"))
	for x: int in [8, 13, 18]:
		_px(img, x, 6, Color("8fe3f2"))
	for cx: int in [7, 19]:
		for a in range(16):
			var ang := float(a) / 16.0 * TAU
			_px(img, cx + int(round(cos(ang) * 3.0)), 14 + int(round(sin(ang) * 3.0)), Color("3a3a48"))
	return _tex(img)


## Grande porte naine scellée : deux battants de pierre, chaînes, sceau de givre.
static func great_door_texture() -> ImageTexture:
	var img := _sprite(34, 42)
	for y in range(8, 42):
		for x in range(2, 32):
			_px(img, x, y, Color("3a4466") if x < 17 else Color("2e3652"))
	for y in range(0, 9):
		var half := int(15.0 * sqrt(maxf(0.0, 1.0 - pow(float(8 - y) / 8.0, 2.0))))
		for x in range(-half, half + 1):
			_px(img, 17 + x, y, Color("4a5272"))
	for y in range(8, 42):
		_px(img, 17, y, Color("141c34"))
	for k in range(14):
		_px(img, 4 + k * 2, 22 + (k % 2), Color("8a8a98"))
	_px(img, 17, 22, Color("c8d8ff"))
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		_px(img, 17 + d.x, 22 + d.y, Color("4a6aff"))
	return _tex(img)
