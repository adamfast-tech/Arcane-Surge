class_name PortraitArt
extends RefCounted
## Portraits de dialogue en pixel-art 64×64, générés par code (docs/design/07-narration.md §6.2).
## Lumière de lune en haut à droite, contour sombre de 1 px, palette commune (10-sprites.md §2).
## Expressions : neutre, joie, colere, triste, surpris.
## Remplacement par des images : assets/portraits/<perso>-<expression>.png, ou <perso>.png pour toutes.

const SIZE := 64
const OUTLINE := Color("120e1a")
const LIGHT := Vector3(0.55, -0.5, 0.67)

static var _cache: Dictionary = {}


static func texture(who: String, mood: String = "neutre") -> Texture2D:
	var key := "%s|%s" % [who, mood]
	if _cache.has(key):
		return _cache[key]
	for path in ["res://assets/portraits/%s-%s.png" % [who, mood], "res://assets/portraits/%s.png" % who]:
		if ResourceLoader.exists(path):
			var t: Texture2D = load(path)
			_cache[key] = t
			return t
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match who:
		"porteur":
			_porteur(img, mood)
		"sylwen":
			_sylwen(img, mood)
		"brann":
			_brann(img, mood)
		"ancien":
			_ancien(img, mood)
		"cerf":
			_cerf(img, mood)
		"sylvarche":
			_sylvarche(img, mood)
		"fee":
			_fee(img, mood)
		"voix":
			_voix(img, mood)
		"krag":
			_krag(img, mood)
		"gharok":
			_gharok(img, mood)
		"prevote":
			_prevote(img, mood)
		"varg":
			_varg(img, mood)
		"nyx":
			_nyx(img, mood)
		"vesper":
			_vesper(img, mood)
		"aurele":
			_aurele(img, mood)
		"corvin":
			_corvin(img, mood)
		_:
			return null
	_outline(img)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func has_portrait(who: String) -> bool:
	return who in ["porteur", "sylwen", "brann", "ancien", "cerf", "sylvarche", "fee", "voix", "krag", "gharok", "prevote", "varg", "nyx", "vesper", "aurele", "corvin"] \
		or ResourceLoader.exists("res://assets/portraits/%s.png" % who)


# ---------------------------------------------------------------- primitives

static func _ramp(hexes: Array) -> Array[Color]:
	var out: Array[Color] = []
	for h in hexes:
		out.append(Color(str(h)))
	return out


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return
	if c.a < 1.0:
		var b := img.get_pixel(x, y)
		if b.a <= 0.0:
			img.set_pixel(x, y, c)
			return
		c = b.lerp(Color(c, 1.0), c.a)
	img.set_pixel(x, y, c)


static func _shade(n: Vector3, ramp: Array[Color], bias: float = 0.0) -> Color:
	var l := n.normalized().dot(LIGHT.normalized()) + bias
	var k := ramp.size()
	# Seuils : ombre, ton moyen, clair (et reflet si la rampe a 4 tons).
	var th: PackedFloat32Array = PackedFloat32Array([0.28, 0.72, 0.93]) if k >= 4 else PackedFloat32Array([0.3, 0.8])
	var i := 0
	while i < th.size() and i < k - 1 and l > th[i]:
		i += 1
	return ramp[i]


## Ellipse ombrée comme un volume.
static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, ramp: Array[Color], bias: float = 0.0, flat: bool = false) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (float(x) + 0.5 - cx) / rx
			var ny := (float(y) + 0.5 - cy) / ry
			var d2 := nx * nx + ny * ny
			if d2 > 1.0:
				continue
			if flat:
				_px(img, x, y, ramp[0])
			else:
				_px(img, x, y, _shade(Vector3(nx, ny, sqrt(1.0 - d2)), ramp, bias))


## Polygone ombré : la normale est approchée par la position dans sa boîte englobante.
static func _poly(img: Image, pts: PackedVector2Array, ramp: Array[Color], bias: float = 0.0, flat: bool = false) -> void:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	var c := r.get_center()
	var hs := r.size * 0.5 + Vector2(0.5, 0.5)
	for y in range(int(floor(r.position.y)), int(ceil(r.end.y)) + 1):
		for x in range(int(floor(r.position.x)), int(ceil(r.end.x)) + 1):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			if not Geometry2D.is_point_in_polygon(p, pts):
				continue
			if flat:
				_px(img, x, y, ramp[0])
				continue
			var nx := clampf((p.x - c.x) / hs.x, -1.0, 1.0)
			var ny := clampf((p.y - c.y) / hs.y, -1.0, 1.0)
			var d2 := minf(0.96, nx * nx * 0.8 + ny * ny * 0.5)
			_px(img, x, y, _shade(Vector3(nx, ny, sqrt(1.0 - d2)), ramp, bias))


static func _line(img: Image, a: Vector2, b: Vector2, c: Color, w: int = 1) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in range(n + 1):
		var p := a.lerp(b, float(i) / float(maxi(1, n)))
		for dx in range(w):
			for dy in range(w):
				_px(img, int(round(p.x)) + dx, int(round(p.y)) + dy, c)


static func _glow(img: Image, cx: int, cy: int, r: int, c: Color, a: float) -> void:
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			var d := Vector2(x, y).length()
			if d <= float(r):
				_px(img, cx + x, cy + y, Color(c, a * (1.0 - d / float(r + 1))))


## Contour sombre de 1 px autour de la silhouette.
static func _outline(img: Image) -> void:
	var src := img.duplicate() as Image
	for y in range(SIZE):
		for x in range(SIZE):
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < SIZE and q.y < SIZE and src.get_pixel(q.x, q.y).a > 0.5:
					img.set_pixel(x, y, OUTLINE)
					break


## Reflet de lune : éclaircit le bord droit d'une forme (pixels opaques dont le voisin de droite est vide).
static func _rim(img: Image, x0: int, x1: int, y0: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x1, x0 - 1, -1):
			if img.get_pixel(clampi(x, 0, SIZE - 1), clampi(y, 0, SIZE - 1)).a > 0.5:
				_px(img, x, y, Color(c, 0.55))
				break


# ---------------------------------------------------------------- traits du visage

## Œil (coin haut-gauche ex, ey ; side = -1 œil gauche, +1 œil droit, côté intérieur vers le centre).
static func _eye(img: Image, ex: int, ey: int, side: int, mood: String, iris: Color, lash: Color) -> void:
	var white := Color("f4f0ff")
	var pupil := iris.darkened(0.55)
	var inner := ex + 3 if side < 0 else ex
	var outer := ex if side < 0 else ex + 3
	match mood:
		"joie":
			_px(img, ex, ey + 2, lash)
			_px(img, ex + 1, ey + 1, lash)
			_px(img, ex + 2, ey + 1, lash)
			_px(img, ex + 3, ey + 2, lash)
		"colere":
			for x in range(4):
				_px(img, ex + x, ey + 1, white)
			_px(img, ex + 1, ey + 1, iris)
			_px(img, ex + 2, ey + 1, pupil)
			for x in range(4):
				_px(img, ex + x, ey, lash)
			_px(img, inner, ey + 1, lash)
			_px(img, ex + 1, ey + 2, iris.darkened(0.2))
			_px(img, ex + 2, ey + 2, iris.darkened(0.2))
		"surpris":
			for y in range(3):
				for x in range(4):
					_px(img, ex + x, ey + y, white)
			_px(img, ex + 1, ey + 1, iris)
			_px(img, ex + 2, ey + 1, pupil)
			_px(img, ex + 1, ey + 2, iris)
			_px(img, ex + 2, ey + 2, iris)
			for x in range(4):
				_px(img, ex + x, ey - 1, lash)
		_:
			for x in range(4):
				_px(img, ex + x, ey + 1, white)
			_px(img, ex + 1, ey + 1, iris)
			_px(img, ex + 2, ey + 1, pupil)
			_px(img, ex + 1, ey + 2, iris.darkened(0.2))
			_px(img, ex + 2, ey + 2, iris.darkened(0.2))
			for x in range(4):
				_px(img, ex + x, ey, lash)
			if mood == "triste":
				_px(img, outer, ey + 1, lash)
			_px(img, ex + 1, ey + 1, white.lerp(iris, 0.3))


## Œil lumineux (capuche, esprits) : barre ou point qui brille.
static func _glow_eye(img: Image, ex: int, ey: int, side: int, mood: String, core: Color, halo: Color) -> void:
	var inner := ex + 2 if side < 0 else ex
	var outer := ex if side < 0 else ex + 2
	_glow(img, ex + 1, ey, 3, halo, 0.35)
	match mood:
		"joie":
			_px(img, ex, ey + 1, core)
			_px(img, ex + 1, ey, core)
			_px(img, ex + 2, ey + 1, core)
		"colere":
			_px(img, outer, ey, core)
			_px(img, ex + 1, ey, core)
			_px(img, inner, ey + 1, core)
		"triste":
			_px(img, inner, ey, core)
			_px(img, ex + 1, ey, core)
			_px(img, outer, ey + 1, core)
		"surpris":
			_px(img, ex, ey, core)
			_px(img, ex + 1, ey, Color.WHITE)
			_px(img, ex + 2, ey, core)
			_px(img, ex + 1, ey - 1, core)
			_px(img, ex + 1, ey + 1, core)
		_:
			_px(img, ex, ey, core)
			_px(img, ex + 1, ey, Color.WHITE)
			_px(img, ex + 2, ey, core)


static func _brow(img: Image, ex: int, ey: int, side: int, mood: String, c: Color, thick: int = 1) -> void:
	# ey : ligne du sourcil au repos ; pente selon l'humeur (côté intérieur = vers le centre).
	for x in range(5):
		var t := float(x) / 4.0
		var inner_t := (1.0 - t) if side > 0 else t
		var dy := 0
		match mood:
			"colere":
				dy = int(round(inner_t * 2.0))
			"triste":
				dy = -int(round(inner_t * 2.0)) + 1
			"surpris":
				dy = -2 if x in [1, 2, 3] else -1
			"joie":
				dy = -1 if x in [1, 2, 3] else 0
		for k in range(thick):
			_px(img, ex - 1 + x, ey + dy + k, c)


static func _mouth(img: Image, cx: int, my: int, mood: String, c: Color, open_c: Color) -> void:
	match mood:
		"joie":
			_px(img, cx - 3, my - 1, c)
			for x in range(-2, 3):
				_px(img, cx + x, my, c)
			_px(img, cx + 3, my - 1, c)
			for x in range(-1, 2):
				_px(img, cx + x, my + 1, open_c)
		"colere":
			for x in range(-2, 3):
				_px(img, cx + x, my, c)
			_px(img, cx - 3, my + 1, c)
			_px(img, cx + 3, my + 1, c)
		"triste":
			_px(img, cx - 2, my + 1, c)
			for x in range(-1, 2):
				_px(img, cx + x, my, c)
			_px(img, cx + 2, my + 1, c)
		"surpris":
			_px(img, cx, my - 1, c)
			_px(img, cx - 1, my, c)
			_px(img, cx + 1, my, c)
			_px(img, cx, my, open_c)
			_px(img, cx, my + 1, c)
		_:
			for x in range(-1, 2):
				_px(img, cx + x, my, c)


# ---------------------------------------------------------------- personnages

## Toi : capuche bleu nuit, visage dans l'ombre, regard cyan (personnage générique, quelle que soit la race).
static func _porteur(img: Image, mood: String) -> void:
	var robe := _ramp(["1f5a66", "2f8f9a", "4fb8c0"])
	var hood := _ramp(["14204a", "1d2f5a", "2f4f8f", "4a6ab8"])
	_poly(img, PackedVector2Array([Vector2(4, 64), Vector2(8, 52), Vector2(20, 45), Vector2(44, 45), Vector2(56, 52), Vector2(60, 64)]), robe)
	# Capuche : drapé sur les épaules puis coiffe.
	_poly(img, PackedVector2Array([Vector2(12, 60), Vector2(13, 40), Vector2(16, 26), Vector2(22, 15), Vector2(32, 9), Vector2(42, 15), Vector2(48, 26), Vector2(51, 40), Vector2(52, 60), Vector2(42, 54), Vector2(22, 54)]), hood)
	# Intérieur sombre et visage dans l'ombre.
	_ellipse(img, 32.0, 34.0, 11.0, 14.0, _ramp(["0c0a1c"]), 0.0, true)
	_ellipse(img, 32.0, 37.0, 8.5, 10.5, _ramp(["2e2440", "45385c", "5e4e78"]))
	for y in range(20, 32):
		for x in range(20, 45):
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and y < 30:
				img.set_pixel(x, y, c.darkened(0.45 if y < 28 else 0.25))
	# Bord de la capuche, éclairé à droite.
	for a in range(200, 341, 4):
		var r := deg_to_rad(float(a))
		_px(img, 32 + int(round(cos(r) * 11.5)), 34 + int(round(sin(r) * 14.5)), Color("2f4f8f"))
	_rim(img, 10, 54, 12, 58, Color("8fa8ff"))
	_glow_eye(img, 26, 33, -1, mood, Color("4fe3d2"), Color("4fe3d2"))
	_glow_eye(img, 35, 33, 1, mood, Color("4fe3d2"), Color("4fe3d2"))
	_mouth(img, 32, 41, mood, Color("1a1428"), Color("0c0a1c"))
	# Col runique et fermoir.
	for x in range(21, 44):
		if x % 3 != 0:
			_px(img, x, 47 + (1 if x < 26 or x > 38 else 0), Color("4fe3d2"))
	_ellipse(img, 32.0, 49.0, 2.0, 2.0, _ramp(["a87a28", "f2c46b", "fff0b0"]))


static func _sylwen(img: Image, mood: String) -> void:
	var skin := _ramp(["b07a6a", "e0ae8e", "f6d4b6"])
	var hair := _ramp(["8a6a2a", "c89a3a", "e8c870", "f6e6a0"])
	var green := _ramp(["22301a", "3f5a30", "4f6b3a", "7faa4a"])
	# Plumes du carquois derrière l'épaule gauche.
	for i in range(3):
		var base := Vector2(13 + i * 3, 52)
		var tip := Vector2(7 + i * 3, 37 + i * 2)
		_line(img, base, tip, Color("8a5a2b"))
		for f in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(0, 1)]:
			_px(img, int(tip.x) + f.x, int(tip.y) + f.y, Color("e8e4ff") if f.y <= 0 else Color("b8b4d0"))
	_poly(img, PackedVector2Array([Vector2(4, 64), Vector2(8, 53), Vector2(21, 47), Vector2(43, 47), Vector2(56, 53), Vector2(60, 64)]), green)
	# Bandoulière du carquois.
	for i in range(18):
		_px(img, 14 + i, 50 + int(i * 0.8), Color("6a4a2a"))
		_px(img, 15 + i, 50 + int(i * 0.8), Color("8a5a2b"))
		_px(img, 16 + i, 50 + int(i * 0.8), Color("6a4a2a"))
	_ellipse(img, 32.0, 46.0, 4.0, 4.0, skin)
	# Capuche verte.
	_poly(img, PackedVector2Array([Vector2(13, 52), Vector2(14, 34), Vector2(17, 21), Vector2(24, 13), Vector2(32, 10), Vector2(40, 13), Vector2(47, 21), Vector2(50, 34), Vector2(51, 52), Vector2(42, 47), Vector2(22, 47)]), green)
	_ellipse(img, 32.0, 31.0, 11.5, 13.0, _ramp(["2a3a1e"]), 0.0, true)
	# Oreilles pointues qui sortent de la capuche.
	_poly(img, PackedVector2Array([Vector2(21, 29), Vector2(8, 19), Vector2(11, 23), Vector2(21, 35)]), skin, 0.1)
	_poly(img, PackedVector2Array([Vector2(43, 29), Vector2(56, 19), Vector2(53, 23), Vector2(43, 35)]), skin, 0.1)
	_ellipse(img, 32.0, 32.5, 10.0, 11.5, skin)
	# Frange blonde.
	_poly(img, PackedVector2Array([Vector2(21, 28), Vector2(22, 21), Vector2(27, 17), Vector2(32, 16), Vector2(38, 17), Vector2(42, 21), Vector2(43, 28), Vector2(40, 24), Vector2(37, 26), Vector2(34, 23), Vector2(30, 25), Vector2(27, 23), Vector2(24, 26)]), hair)
	# Tresse sur l'épaule droite.
	for i in range(7):
		var y := 38.0 + float(i) * 3.6
		_ellipse(img, 44.0 + float(i) * 0.6 + (0.8 if i % 2 == 0 else -0.8), y, 2.6, 2.2, hair)
	_ellipse(img, 48.0, 63.0, 2.0, 1.5, green)
	_brow(img, 26, 29, -1, mood, Color("a8803a"))
	_brow(img, 36, 29, 1, mood, Color("a8803a"))
	_eye(img, 25, 31, -1, mood, Color("4f9a3a"), Color("3a2626"))
	_eye(img, 35, 31, 1, mood, Color("4f9a3a"), Color("3a2626"))
	_px(img, 32, 36, Color("c8907a"))
	_px(img, 33, 37, Color("b07a6a"))
	if mood == "joie":
		_px(img, 24, 37, Color("f0a0a0"))
		_px(img, 40, 37, Color("f0a0a0"))
	_mouth(img, 32, 40, mood, Color("a05a5a"), Color("5a2a3a"))
	_rim(img, 8, 58, 10, 63, Color("cfe8a0"))


static func _brann(img: Image, mood: String) -> void:
	var skin := _ramp(["9a5a4a", "d08a6a", "eab090"])
	var steel := _ramp(["4a5068", "7a849c", "c8d0e0", "eef2ff"])
	var ivory := _ramp(["8a7a5a", "c8b890", "e8dcc0", "fff6e0"])
	var beard := _ramp(["7a3a1a", "b8582a", "e07a3a", "f0a060"])
	var cape := _ramp(["4a1a1e", "7a2a2a", "a83a3a", "c85a4a"])
	_poly(img, PackedVector2Array([Vector2(2, 64), Vector2(4, 50), Vector2(16, 43), Vector2(48, 43), Vector2(60, 50), Vector2(62, 64)]), cape)
	_ellipse(img, 11.0, 52.0, 9.0, 7.0, steel)
	_ellipse(img, 53.0, 52.0, 9.0, 7.0, steel)
	# Cornes.
	_poly(img, PackedVector2Array([Vector2(20, 24), Vector2(14, 21), Vector2(9, 15), Vector2(6, 6), Vector2(11, 11), Vector2(16, 15), Vector2(22, 19)]), ivory)
	_poly(img, PackedVector2Array([Vector2(44, 24), Vector2(50, 21), Vector2(55, 15), Vector2(58, 6), Vector2(53, 11), Vector2(48, 15), Vector2(42, 19)]), ivory)
	_ellipse(img, 32.0, 34.0, 13.0, 12.0, skin)
	# Casque d'acier, bandeau et nasal.
	_ellipse(img, 32.0, 25.0, 15.0, 12.0, steel)
	_redraw_face_band(img, skin)
	for x in range(17, 48):
		_px(img, x, 25, Color("4a5068"))
		_px(img, x, 26, Color("7a849c"))
		_px(img, x, 27, Color("4a5068"))
	for x in [19, 25, 39, 45]:
		_px(img, x, 26, Color("f2c46b"))
	for y in range(26, 36):
		_px(img, 31, y, Color("7a849c"))
		_px(img, 32, y, Color("c8d0e0"))
		_px(img, 33, y, Color("4a5068"))
	# Barbe rousse tressée.
	_poly(img, PackedVector2Array([Vector2(18, 34), Vector2(19, 44), Vector2(23, 53), Vector2(28, 59), Vector2(32, 61), Vector2(36, 59), Vector2(41, 53), Vector2(45, 44), Vector2(46, 34), Vector2(42, 39), Vector2(36, 41), Vector2(28, 41), Vector2(22, 39)]), beard)
	for side in [-1, 1]:
		var bx: int = 32 + side * 7
		for i in range(4):
			_ellipse(img, float(bx) + float(side) * 0.5 * i, 54.0 + float(i) * 2.8, 2.2, 1.8, beard)
		_px(img, bx + side * 2 - 1, 62, Color("f2c46b"))
		_px(img, bx + side * 2, 62, Color("fff0b0"))
	# Moustache.
	_ellipse(img, 27.0, 40.0, 5.0, 2.2, beard, 0.15)
	_ellipse(img, 37.0, 40.0, 5.0, 2.2, beard, 0.15)
	_ellipse(img, 32.0, 36.5, 3.2, 3.0, skin, 0.2)
	_brow(img, 26, 29, -1, mood, Color("c8682a"), 2)
	_brow(img, 37, 29, 1, mood, Color("c8682a"), 2)
	var eye := Color("2a1a1a")
	for e in [[25, -1], [37, 1]]:
		var ex: int = e[0]
		match mood:
			"joie":
				_px(img, ex, 33, eye)
				_px(img, ex + 1, 32, eye)
				_px(img, ex + 2, 33, eye)
			"surpris":
				_px(img, ex, 32, Color.WHITE)
				_px(img, ex + 1, 32, eye)
				_px(img, ex + 1, 33, eye)
				_px(img, ex + 2, 32, Color.WHITE)
			_:
				_px(img, ex + 1, 32, eye)
				_px(img, ex + 2, 32, eye)
				_px(img, ex + 1, 33, eye)
				_px(img, ex + 2, 33, Color("f4f0ff") if mood != "colere" else eye)
	match mood:
		"joie":
			for x in range(29, 36):
				_px(img, x, 43, Color("3a1a1a"))
			for x in range(30, 35):
				_px(img, x, 44, Color("f4f0ff"))
		"surpris":
			_ellipse(img, 32.0, 43.5, 1.6, 1.6, _ramp(["3a1a1a"]), 0.0, true)
		"colere":
			for x in range(29, 36):
				_px(img, x, 43, Color("3a1a1a"))
	_rim(img, 2, 62, 6, 63, Color("ffe0c0"))


## Le dôme du casque couvre le haut du visage : on redessine le bas du visage par-dessus.
static func _redraw_face_band(img: Image, skin: Array[Color]) -> void:
	for y in range(27, 47):
		for x in range(19, 46):
			var nx := (float(x) + 0.5 - 32.0) / 13.0
			var ny := (float(y) + 0.5 - 34.0) / 12.0
			var d2 := nx * nx + ny * ny
			if d2 <= 1.0:
				_px(img, x, y, _shade(Vector3(nx, ny, sqrt(1.0 - d2)), skin))


static func _ancien(img: Image, mood: String) -> void:
	var skin := _ramp(["a8786a", "d8a888", "f0c8a8"])
	var white := _ramp(["8a8aa0", "c8c8d8", "f0f0f8"])
	var robe := _ramp(["3a2e2a", "6a4a2a", "8a5a2b", "a87a48"])
	_poly(img, PackedVector2Array([Vector2(4, 64), Vector2(8, 52), Vector2(20, 46), Vector2(44, 46), Vector2(56, 52), Vector2(60, 64)]), robe)
	_poly(img, PackedVector2Array([Vector2(10, 58), Vector2(22, 48), Vector2(30, 52), Vector2(20, 64), Vector2(8, 64)]), _ramp(["22301a", "3f5a30", "4f6b3a"]))
	_poly(img, PackedVector2Array([Vector2(54, 58), Vector2(42, 48), Vector2(34, 52), Vector2(44, 64), Vector2(56, 64)]), _ramp(["22301a", "3f5a30", "4f6b3a"]))
	_poly(img, PackedVector2Array([Vector2(23, 20), Vector2(18, 24), Vector2(16, 31), Vector2(17, 38), Vector2(20, 42), Vector2(23, 36)]), white)
	_poly(img, PackedVector2Array([Vector2(41, 20), Vector2(46, 24), Vector2(48, 31), Vector2(47, 38), Vector2(44, 42), Vector2(41, 36)]), white)
	_ellipse(img, 32.0, 31.0, 11.0, 13.5, skin)
	# Rides du front.
	for x in range(27, 38):
		_px(img, x, 22, Color("b88a74"))
	for x in range(29, 36):
		_px(img, x, 25, Color("b88a74"))
	# Barbe longue et moustache.
	_poly(img, PackedVector2Array([Vector2(21, 35), Vector2(22, 45), Vector2(26, 55), Vector2(32, 62), Vector2(38, 55), Vector2(42, 45), Vector2(43, 35), Vector2(38, 40), Vector2(32, 42), Vector2(26, 40)]), white)
	_ellipse(img, 28.0, 39.5, 4.5, 1.8, white, 0.2)
	_ellipse(img, 36.0, 39.5, 4.5, 1.8, white, 0.2)
	_ellipse(img, 32.0, 35.5, 2.5, 2.5, skin, 0.2)
	_brow(img, 26, 28, -1, mood, Color("e8e8f4"), 2)
	_brow(img, 37, 28, 1, mood, Color("e8e8f4"), 2)
	for ex in [25, 37]:
		match mood:
			"joie":
				_px(img, ex, 32, Color("3a2a2a"))
				_px(img, ex + 1, 31, Color("3a2a2a"))
				_px(img, ex + 2, 32, Color("3a2a2a"))
			"surpris":
				_px(img, ex + 1, 31, Color("3a2a2a"))
				_px(img, ex + 1, 32, Color("3a2a2a"))
				_px(img, ex, 31, Color("f4f0ff"))
				_px(img, ex + 2, 31, Color("f4f0ff"))
			_:
				_px(img, ex, 31, Color("3a2a2a"))
				_px(img, ex + 1, 31, Color("3a2a2a"))
				_px(img, ex + 2, 31, Color("3a2a2a"))
				_px(img, ex + 1, 32, Color("5a4a6a"))
		_px(img, ex - 1, 33, Color("b88a74"))
	if mood in ["joie", "surpris"]:
		_mouth(img, 32, 42, mood, Color("6a4a4a"), Color("3a2a2a"))
	_rim(img, 4, 60, 14, 63, Color("ffe8c8"))


## Le Grand Cerf, purifié : pelage gris-mauve, bois lumineux.
static func _cerf(img: Image, mood: String) -> void:
	var fur := _ramp(["3a2e3a", "5a4a5a", "8a7a8a", "b0a0b0"])
	var muzzle := _ramp(["6a5a6a", "9a8a9a", "c0b0c0"])
	var horn := Color("cfe6ff")
	_glow(img, 32, 14, 22, Color("9ff0ff"), 0.16)
	for s in [-1, 1]:
		var b := Vector2(32 + s * 6, 20)
		var t := Vector2(32 + s * 22, 3)
		_line(img, b, t, horn, 2)
		_line(img, b.lerp(t, 0.35), b.lerp(t, 0.35) + Vector2(s * 1, -9), horn, 2)
		_line(img, b.lerp(t, 0.65), b.lerp(t, 0.65) + Vector2(s * 2, -8), horn, 1)
		_line(img, b.lerp(t, 0.55), b.lerp(t, 0.55) + Vector2(s * 9, 2), horn, 1)
	_poly(img, PackedVector2Array([Vector2(12, 64), Vector2(17, 48), Vector2(25, 41), Vector2(39, 41), Vector2(47, 48), Vector2(52, 64)]), fur)
	_ellipse(img, 32.0, 55.0, 6.0, 5.0, _ramp(["8a7a8a", "b0a0b0", "d8ccd8"]))
	_poly(img, PackedVector2Array([Vector2(25, 26), Vector2(13, 17), Vector2(10, 20), Vector2(14, 26), Vector2(23, 31)]), fur)
	_poly(img, PackedVector2Array([Vector2(39, 26), Vector2(51, 17), Vector2(54, 20), Vector2(50, 26), Vector2(41, 31)]), fur)
	_ellipse(img, 32.0, 29.0, 9.5, 10.0, fur)
	_ellipse(img, 32.0, 40.0, 5.0, 8.0, muzzle)
	_ellipse(img, 32.0, 46.0, 3.2, 2.0, _ramp(["1a1426", "2a2038"]))
	_px(img, 31, 46, Color("07060f"))
	_px(img, 33, 46, Color("07060f"))
	for e in [[26, -1], [36, 1]]:
		_glow_eye(img, e[0], 30, e[1], mood, Color("cfffff"), Color("9ff0ff"))
	_rim(img, 8, 56, 18, 63, Color("cfe6ff"))


## La Sylvarche : visage d'écorce ; « joie » = purifiée (feuillage vert, sève dorée).
static func _sylvarche(img: Image, mood: String) -> void:
	var pure := mood == "joie"
	var leaves := _ramp(["22301a", "3f5a30", "4f6b3a", "7faa4a"]) if pure else _ramp(["1a1035", "3b2a6b", "5a2a7a", "8e62e0"])
	var bark := _ramp(["2a1e1a", "3a2e2a", "5a4030", "7a5a40"])
	var glow := Color("f2e28b") if pure else Color("d93cf2")
	_ellipse(img, 18.0, 15.0, 13.0, 11.0, leaves)
	_ellipse(img, 46.0, 15.0, 13.0, 11.0, leaves)
	_ellipse(img, 32.0, 9.0, 14.0, 9.0, leaves)
	_poly(img, PackedVector2Array([Vector2(10, 64), Vector2(14, 42), Vector2(18, 24), Vector2(32, 17), Vector2(46, 24), Vector2(50, 42), Vector2(54, 64)]), bark)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(14):
		var x := rng.randi_range(16, 48)
		var y0 := rng.randi_range(22, 50)
		for y in range(y0, mini(63, y0 + rng.randi_range(4, 12))):
			if img.get_pixel(x, y).a > 0.5:
				_px(img, x, y, bark[0])
	# Fissures de corruption (ou sève dorée).
	var crack := Color("f2c46b") if pure else Color("b07cff")
	for path in [[Vector2(20, 30), Vector2(24, 40), Vector2(21, 52)], [Vector2(44, 28), Vector2(41, 38), Vector2(45, 50)], [Vector2(32, 48), Vector2(30, 56), Vector2(33, 63)]]:
		for i in range(path.size() - 1):
			_line(img, path[i], path[i + 1], crack)
	var mood_eyes := "triste" if mood == "triste" else ("colere" if mood == "colere" else "neutre")
	for e in [[23, -1], [37, 1]]:
		_ellipse(img, float(e[0]) + 2.5, 33.0, 4.0, 3.0, _ramp(["0c0812"]), 0.0, true)
		_glow_eye(img, e[0] + 1, 33, e[1], mood_eyes, glow.lightened(0.4), glow)
	_ellipse(img, 32.0, 44.0, 6.0, 2.5, _ramp(["0c0812"]), 0.0, true)
	_glow(img, 32, 44, 4, glow, 0.25)
	_rim(img, 6, 60, 2, 63, Color("cfc8ff"))


static func _fee(img: Image, mood: String) -> void:
	var wr: Array[Color] = [Color(0.75, 0.9, 1.0, 0.6)]
	for sd in [-1, 1]:
		var up := PackedVector2Array()
		var low := PackedVector2Array()
		for p in [Vector2(26, 36), Vector2(16, 22), Vector2(8, 13), Vector2(3, 16), Vector2(4, 28), Vector2(12, 37), Vector2(22, 41)]:
			up.append(Vector2(32.0 + (p.x - 32.0) * sd, p.y))
		for p in [Vector2(24, 44), Vector2(13, 44), Vector2(6, 50), Vector2(9, 56), Vector2(17, 54), Vector2(25, 48)]:
			low.append(Vector2(32.0 + (p.x - 32.0) * sd, p.y))
		_poly(img, up, wr, 0.0, true)
		_poly(img, low, wr, 0.0, true)
		_line(img, Vector2(32 - sd * 7, 37), Vector2(32 - sd * 22, 17), Color("cfe8ff"))
		_line(img, Vector2(32 - sd * 8, 45), Vector2(32 - sd * 19, 51), Color("cfe8ff"))
	var dress := _ramp(["8a4a7a", "c87ab0", "f7a8e0", "ffd8f4"])
	var skin := _ramp(["b89ac8", "e0c8f0", "f8ecff"])
	var hair := _ramp(["c87ab0", "f7a8e0", "ffe0f4"])
	_poly(img, PackedVector2Array([Vector2(14, 64), Vector2(19, 54), Vector2(27, 50), Vector2(37, 50), Vector2(45, 54), Vector2(50, 64)]), dress)
	_ellipse(img, 32.0, 48.0, 3.0, 3.0, skin)
	_ellipse(img, 32.0, 29.0, 13.0, 11.0, hair)
	_poly(img, PackedVector2Array([Vector2(21, 34), Vector2(14, 27), Vector2(16, 31), Vector2(21, 38)]), skin)
	_poly(img, PackedVector2Array([Vector2(43, 34), Vector2(50, 27), Vector2(48, 31), Vector2(43, 38)]), skin)
	_ellipse(img, 32.0, 35.0, 10.0, 10.5, skin)
	_poly(img, PackedVector2Array([Vector2(22, 32), Vector2(23, 24), Vector2(32, 20), Vector2(41, 24), Vector2(42, 32), Vector2(38, 27), Vector2(32, 29), Vector2(26, 27)]), hair)
	_ellipse(img, 20.0, 40.0, 2.5, 6.0, hair)
	_ellipse(img, 44.0, 40.0, 2.5, 6.0, hair)
	_eye(img, 25, 34, -1, mood, Color("8e62e0"), Color("5a2a7a"))
	_eye(img, 35, 34, 1, mood, Color("8e62e0"), Color("5a2a7a"))
	_mouth(img, 32, 41, mood, Color("b06a9a"), Color("6a2a5a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in range(10):
		var p := Vector2i(rng.randi_range(4, 60), rng.randi_range(4, 60))
		if img.get_pixel(p.x, p.y).a < 0.1:
			_px(img, p.x, p.y, Color("ffe0f4") if i % 2 == 0 else Color("9ff0ff"))
	if mood == "triste":
		for y in range(SIZE):
			for x in range(SIZE):
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					img.set_pixel(x, y, Color(c.lerp(Color("8a86a0"), 0.35), c.a))


## Voix inconnue : silhouette couronnée, regard violet.
static func _voix(img: Image, mood: String) -> void:
	var dark := _ramp(["07060f", "120e1a", "1a1035", "2a1e4a"])
	_glow(img, 32, 30, 26, Color("5a2a7a"), 0.3)
	for i in range(5):
		var x := 20 + i * 6
		var h := 14 - absi(2 - i) * 3
		_poly(img, PackedVector2Array([Vector2(x - 3, 19), Vector2(x, 18 - h), Vector2(x + 3, 19)]), _ramp(["1a1035", "3b2a6b", "8e62e0"]))
		_px(img, x, 18 - h + 1, Color("d93cf2"))
	_poly(img, PackedVector2Array([Vector2(6, 64), Vector2(12, 40), Vector2(18, 22), Vector2(32, 14), Vector2(46, 22), Vector2(52, 40), Vector2(58, 64)]), dark)
	_ellipse(img, 32.0, 34.0, 10.0, 12.0, _ramp(["050409"]), 0.0, true)
	_glow_eye(img, 26, 33, -1, "colere" if mood == "neutre" else mood, Color("ff9cff"), Color("d93cf2"))
	_glow_eye(img, 35, 33, 1, "colere" if mood == "neutre" else mood, Color("ff9cff"), Color("d93cf2"))
	_rim(img, 4, 60, 12, 63, Color("b07cff"))


# ---------------------------------------------------------------- acte 2 · Collines d'Ambre

## Crocs d'orc : deux défenses ivoire qui remontent des coins de la bouche.
static func _tusks(img: Image, cx: int, my: int, spread: int, h: int) -> void:
	for side in [-1, 1]:
		var x: int = cx + side * spread
		for k in range(h):
			_px(img, x, my - k, Color("e8dcc0") if k < h - 1 else Color("fff6e0"))
			if k < h - 2:
				_px(img, x + side, my - k, Color("b8a888"))


## Krag : jeune orc des Enfants de la Fureur. Chignon noir, peintures de guerre, crocs, cape de fourrure.
static func _krag(img: Image, mood: String) -> void:
	var skin := _ramp(["3a5a2e", "5a8a44", "7aaa5a", "9ac870"])
	var fur := _ramp(["4a3420", "7a5a30", "a8804a", "c8a068"])
	var hair := _ramp(["0e0a10", "1a1418", "2e2630"])
	_poly(img, PackedVector2Array([Vector2(24, 40), Vector2(40, 40), Vector2(42, 50), Vector2(22, 50)]), skin)
	_poly(img, PackedVector2Array([Vector2(1, 64), Vector2(3, 52), Vector2(12, 46), Vector2(24, 47), Vector2(32, 52), Vector2(40, 47), Vector2(52, 46), Vector2(61, 52), Vector2(63, 64)]), fur)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(70):
		var fx := rng.randi_range(2, 61)
		var fy := rng.randi_range(48, 63)
		if img.get_pixel(fx, fy).a > 0.5:
			_px(img, fx, fy, Color("4a3420") if i % 3 == 0 else Color("c8a068"))
	# Collier de crocs et pierre d'ambre.
	for i in range(7):
		var a := deg_to_rad(20.0 + float(i) * 23.0)
		_px(img, 32 + int(cos(a) * 9.0), 45 + int(sin(a) * 4.0), Color("e8dcc0"))
	_ellipse(img, 32.0, 50.0, 2.4, 2.4, _ramp(["a8641e", "e8a33d", "ffd070"]))
	# Oreilles pointues.
	_poly(img, PackedVector2Array([Vector2(20, 30), Vector2(12, 25), Vector2(14, 30), Vector2(20, 36)]), skin, 0.1)
	_poly(img, PackedVector2Array([Vector2(44, 30), Vector2(52, 25), Vector2(50, 30), Vector2(44, 36)]), skin, 0.1)
	_px(img, 13, 27, Color("e8a33d"))
	_px(img, 13, 28, Color("ffd070"))
	_ellipse(img, 32.0, 31.0, 12.5, 12.5, skin)
	_ellipse(img, 32.0, 38.5, 12.0, 7.0, skin)
	# Crâne rasé sur les côtés, crête et chignon noirs.
	_poly(img, PackedVector2Array([Vector2(27, 26), Vector2(26, 19), Vector2(29, 14), Vector2(35, 14), Vector2(38, 19), Vector2(37, 26), Vector2(32, 23)]), hair)
	_poly(img, PackedVector2Array([Vector2(29, 14), Vector2(28, 8), Vector2(31, 4), Vector2(35, 5), Vector2(36, 9), Vector2(35, 14)]), hair)
	for x in range(28, 37):
		_px(img, x, 12, Color("e8a33d"))
	# Peintures de guerre rouges sous les yeux.
	for side in [-1, 1]:
		var bx: int = 32 + side * 9
		for k in range(3):
			_px(img, bx - 2 + k, 36 + k % 2, Color("a83a2a"))
			_px(img, bx - 2 + k, 38 + k % 2, Color("a83a2a"))
	# Cicatrice sur le sourcil gauche.
	_line(img, Vector2(24, 26), Vector2(28, 33), Color("2e4a24"))
	_brow(img, 26, 29, -1, mood, Color("1a1418"), 2)
	_brow(img, 37, 29, 1, mood, Color("1a1418"), 2)
	_eye(img, 25, 31, -1, mood, Color("e8a33d"), Color("1a1418"))
	_eye(img, 36, 31, 1, mood, Color("e8a33d"), Color("1a1418"))
	_px(img, 31, 37, Color("3a5a2e"))
	_px(img, 33, 37, Color("3a5a2e"))
	_mouth(img, 32, 42, mood, Color("2a3a20"), Color("1a1418"))
	_tusks(img, 32, 43, 5, 4)
	_rim(img, 2, 62, 4, 63, Color("ffe8b0"))


## Gharok : seigneur de guerre orc. Possédé (neutre, colère, surpris) : yeux magenta, veines du Surge.
## Libéré (joie, triste) : regard ambre, traits fatigués.
static func _gharok(img: Image, mood: String) -> void:
	var freed := mood in ["joie", "triste"]
	var skin := _ramp(["34462e", "4e6a40", "6a8a54", "86a46a"])
	var steel := _ramp(["3a3e50", "5a6070", "8a90a0", "c8d0e0"])
	var horn := _ramp(["8a7a5a", "c8b890", "e8dcc0", "fff6e0"])
	var red := _ramp(["4a1414", "7a2a2a", "a83a3a"])
	if not freed:
		_glow(img, 32, 30, 30, Color("d93cf2"), 0.12)
	_poly(img, PackedVector2Array([Vector2(0, 64), Vector2(1, 46), Vector2(14, 40), Vector2(50, 40), Vector2(63, 46), Vector2(64, 64)]), red)
	_ellipse(img, 9.0, 48.0, 10.0, 8.0, steel)
	_ellipse(img, 55.0, 48.0, 10.0, 8.0, steel)
	for x in [5, 9, 13, 51, 55, 59]:
		_px(img, x, 44, Color("e8dcc0"))
		_px(img, x, 43, Color("fff6e0"))
	# Grandes cornes recourbées.
	_poly(img, PackedVector2Array([Vector2(20, 22), Vector2(11, 20), Vector2(5, 13), Vector2(3, 3), Vector2(8, 9), Vector2(14, 13), Vector2(22, 16)]), horn)
	_poly(img, PackedVector2Array([Vector2(44, 22), Vector2(53, 20), Vector2(59, 13), Vector2(61, 3), Vector2(56, 9), Vector2(50, 13), Vector2(42, 16)]), horn)
	_ellipse(img, 32.0, 33.0, 14.0, 13.0, skin)
	_ellipse(img, 32.0, 41.0, 14.0, 8.0, skin)
	# Casque d'acier.
	_ellipse(img, 32.0, 20.0, 15.0, 7.5, steel)
	for x in range(17, 48):
		_px(img, x, 25, Color("3a3e50"))
		_px(img, x, 26, Color("8a90a0") if x % 4 != 0 else Color("f2c46b"))
	# Bouc gris tressé.
	_poly(img, PackedVector2Array([Vector2(27, 46), Vector2(29, 55), Vector2(32, 60), Vector2(35, 55), Vector2(37, 46)]), _ramp(["6a6a72", "9a9aa2", "c8c8d0"]))
	_px(img, 32, 58, Color("e8a33d"))
	_brow(img, 25, 30, -1, mood, Color("1e2a18"), 2)
	_brow(img, 38, 30, 1, mood, Color("1e2a18"), 2)
	if freed:
		_eye(img, 24, 32, -1, mood, Color("e8a33d"), Color("1e2a18"))
		_eye(img, 37, 32, 1, mood, Color("e8a33d"), Color("1e2a18"))
	else:
		_glow_eye(img, 25, 33, -1, mood, Color("ff9cff"), Color("d93cf2"))
		_glow_eye(img, 37, 33, 1, mood, Color("ff9cff"), Color("d93cf2"))
		# Veines du Surge.
		for v in [[Vector2(20, 36), Vector2(23, 42)], [Vector2(44, 36), Vector2(41, 43)], [Vector2(29, 29), Vector2(27, 25)]]:
			_line(img, v[0], v[1], Color("b03ad0"))
	_px(img, 31, 39, Color("34462e"))
	_px(img, 33, 39, Color("34462e"))
	_mouth(img, 32, 44, mood, Color("1e2a18"), Color("0e0a08"))
	_tusks(img, 32, 45, 6, 5)
	_rim(img, 1, 62, 3, 40, Color("ffe0c0") if freed else Color("f0b0ff"))


## Prévôte Maëlle d'Ambreval : couronne de tresses rousses, gorgerin d'acier, tabard aux couleurs de l'Aube.
static func _prevote(img: Image, mood: String) -> void:
	var skin := _ramp(["b07a62", "e0aa88", "f6d0b0"])
	var hair := _ramp(["6a2a14", "a8461e", "d0682e", "e8904a"])
	var tabard := _ramp(["1d2f5a", "2f4f8f", "4a6ab8"])
	var steel := _ramp(["4a5068", "7a849c", "c8d0e0", "eef2ff"])
	_poly(img, PackedVector2Array([Vector2(3, 64), Vector2(6, 51), Vector2(19, 45), Vector2(45, 45), Vector2(58, 51), Vector2(61, 64)]), tabard)
	# Soleil d'or de l'Aube sur le tabard.
	_ellipse(img, 32.0, 57.0, 3.0, 3.0, _ramp(["a87a28", "f2c46b", "fff0b0"]))
	for d in [Vector2i(0, -5), Vector2i(0, 5), Vector2i(-5, 0), Vector2i(5, 0), Vector2i(-4, -4), Vector2i(4, -4)]:
		_px(img, 32 + d.x, 57 + d.y, Color("f2c46b"))
	_poly(img, PackedVector2Array([Vector2(19, 46), Vector2(22, 41), Vector2(42, 41), Vector2(45, 46), Vector2(40, 49), Vector2(24, 49)]), steel)
	_ellipse(img, 32.0, 31.0, 10.5, 12.5, skin)
	# Couronne de tresses.
	for i in range(11):
		var a := deg_to_rad(190.0 + float(i) * 16.0)
		_ellipse(img, 32.0 + cos(a) * 11.0, 26.0 + sin(a) * 8.5, 3.2, 2.6, hair)
	_poly(img, PackedVector2Array([Vector2(22, 27), Vector2(25, 20), Vector2(32, 18), Vector2(39, 20), Vector2(42, 27), Vector2(37, 23), Vector2(32, 22), Vector2(27, 23)]), hair)
	# Mèche sur l'épaule.
	for i in range(4):
		_ellipse(img, 20.0 - float(i) * 0.4, 36.0 + float(i) * 3.4, 2.4, 2.0, hair)
	_brow(img, 26, 28, -1, mood, Color("8a3a1a"))
	_brow(img, 37, 28, 1, mood, Color("8a3a1a"))
	_eye(img, 25, 30, -1, mood, Color("4a7ab8"), Color("3a2020"))
	_eye(img, 36, 30, 1, mood, Color("4a7ab8"), Color("3a2020"))
	for f in [Vector2i(26, 35), Vector2i(28, 36), Vector2i(37, 35), Vector2i(39, 36)]:
		_px(img, f.x, f.y, Color("c8805a"))
	_px(img, 32, 35, Color("c8907a"))
	_mouth(img, 32, 39, mood, Color("9a4a4a"), Color("5a2a2a"))
	_rim(img, 4, 60, 8, 63, Color("ffe0c0"))


## Varg, chef pillard : casque à cornes, balafre, barbe de trois jours, cape rouge.
static func _varg(img: Image, mood: String) -> void:
	var skin := _ramp(["9a6a52", "c8926e", "e0b08c"])
	var steel := _ramp(["3a3e50", "5a6070", "8a90a0", "c8d0e0"])
	var horn := _ramp(["8a7a5a", "c8b890", "e8dcc0"])
	var cape := _ramp(["4a1414", "7a2a2a", "a83a3a", "c84a3a"])
	_poly(img, PackedVector2Array([Vector2(2, 64), Vector2(5, 50), Vector2(18, 44), Vector2(46, 44), Vector2(59, 50), Vector2(62, 64)]), cape)
	_poly(img, PackedVector2Array([Vector2(20, 45), Vector2(24, 41), Vector2(40, 41), Vector2(44, 45), Vector2(32, 52)]), _ramp(["5a4a3a", "7a6a50", "9a8a6a"]))
	_poly(img, PackedVector2Array([Vector2(20, 23), Vector2(13, 18), Vector2(10, 9), Vector2(15, 14), Vector2(22, 17)]), horn)
	_poly(img, PackedVector2Array([Vector2(44, 23), Vector2(51, 18), Vector2(54, 9), Vector2(49, 14), Vector2(42, 17)]), horn)
	_ellipse(img, 32.0, 33.0, 11.0, 12.5, skin)
	_ellipse(img, 32.0, 21.0, 13.0, 7.0, steel)
	for x in range(19, 46):
		_px(img, x, 25, Color("3a3e50"))
	for y in range(25, 33):
		_px(img, 32, y, Color("8a90a0"))
	# Barbe de trois jours.
	for y in range(39, 46):
		for x in range(23, 42):
			if (x * 3 + y * 5) % 7 == 0 and img.get_pixel(x, y).a > 0.5:
				_px(img, x, y, Color("8a5a44"))
	_brow(img, 26, 29, -1, mood, Color("3a2a20"), 2)
	_brow(img, 37, 29, 1, mood, Color("3a2a20"), 2)
	_eye(img, 25, 31, -1, mood, Color("8a90a0"), Color("2a1a14"))
	_eye(img, 36, 31, 1, mood, Color("8a90a0"), Color("2a1a14"))
	# Balafre.
	_line(img, Vector2(36, 28), Vector2(41, 39), Color("8a4a3a"))
	_mouth(img, 32, 41, mood, Color("4a2a20"), Color("2a1414"))
	_rim(img, 3, 61, 8, 63, Color("ffd8b0"))


# ---------------------------------------------------------------- acte 3 · Marais Murmurants

## Nyx : fée assombrie du Cercle des Cendres. Ailes de phalène, cheveux cendrés, regard violet, sourire en coin.
static func _nyx(img: Image, mood: String) -> void:
	var skin := _ramp(["9a88a8", "cbb8d4", "e8dcf0"])
	var hair := _ramp(["3a3448", "5e5872", "8a84a0", "b8b2cc"])
	var wing := _ramp(["3a3050", "5a4a78", "8a7aa8", "b8a8d8"])
	var robe := _ramp(["1e1430", "3a2a5a", "5a3a8a"])
	_glow(img, 32, 30, 28, Color("8e62e0"), 0.1)
	# Ailes de phalène derrière la tête.
	_poly(img, PackedVector2Array([Vector2(28, 30), Vector2(10, 8), Vector2(3, 14), Vector2(5, 30), Vector2(12, 40), Vector2(26, 38)]), wing)
	_poly(img, PackedVector2Array([Vector2(36, 30), Vector2(54, 8), Vector2(61, 14), Vector2(59, 30), Vector2(52, 40), Vector2(38, 38)]), wing)
	for e in [Vector2(11, 20), Vector2(53, 20)]:
		_ellipse(img, e.x, e.y, 3.0, 3.0, _ramp(["1e1430", "d93cf2"]), 0.0)
	_poly(img, PackedVector2Array([Vector2(8, 64), Vector2(12, 52), Vector2(22, 47), Vector2(42, 47), Vector2(52, 52), Vector2(56, 64)]), robe)
	# Pendentif d'os.
	_line(img, Vector2(26, 48), Vector2(32, 54), Color("8a8678"))
	_line(img, Vector2(38, 48), Vector2(32, 54), Color("8a8678"))
	_ellipse(img, 32.0, 56.0, 2.0, 2.6, _ramp(["a8a498", "e8e4d8"]))
	_ellipse(img, 32.0, 33.0, 10.0, 12.0, skin)
	# Petites oreilles pointues.
	_poly(img, PackedVector2Array([Vector2(23, 30), Vector2(16, 24), Vector2(18, 29), Vector2(23, 35)]), skin, 0.1)
	_poly(img, PackedVector2Array([Vector2(41, 30), Vector2(48, 24), Vector2(46, 29), Vector2(41, 35)]), skin, 0.1)
	# Cheveux cendrés en bataille.
	_poly(img, PackedVector2Array([Vector2(20, 34), Vector2(19, 22), Vector2(23, 15), Vector2(30, 11), Vector2(38, 12), Vector2(45, 19), Vector2(46, 34), Vector2(42, 26), Vector2(39, 29), Vector2(36, 23), Vector2(32, 28), Vector2(28, 22), Vector2(25, 28), Vector2(22, 27)]), hair)
	for q in [Vector2i(24, 12), Vector2i(31, 9), Vector2i(39, 10), Vector2i(44, 15)]:
		_px(img, q.x, q.y, Color("5e5872"))
	_brow(img, 26, 28, -1, mood, Color("7a7488"))
	_brow(img, 37, 28, 1, mood, Color("7a7488"))
	_glow_eye(img, 25, 32, -1, mood, Color("e8c8ff"), Color("b07cff"))
	_glow_eye(img, 37, 32, 1, mood, Color("e8c8ff"), Color("b07cff"))
	if mood == "joie":
		# Sourire en coin.
		for x in range(30, 36):
			_px(img, x, 39 - (1 if x > 33 else 0), Color("5a3a5a"))
	else:
		_mouth(img, 32, 39, mood, Color("7a5070"), Color("3a2a3a"))
	_rim(img, 4, 60, 6, 63, Color("e8d8ff"))


## Vesper : gardien du Cercle des Cendres. Robe cendre, masque d'os relevé sur le front, barbe grise.
static func _vesper(img: Image, mood: String) -> void:
	var skin := _ramp(["8a7068", "b89888", "d8b8a8"])
	var robe := _ramp(["2a2a30", "4a4a52", "6a6a74", "8a8a94"])
	var bone := _ramp(["8a8678", "c8c4b4", "e8e4d8", "fffef0"])
	_poly(img, PackedVector2Array([Vector2(3, 64), Vector2(7, 50), Vector2(19, 44), Vector2(45, 44), Vector2(57, 50), Vector2(61, 64)]), robe)
	_poly(img, PackedVector2Array([Vector2(12, 56), Vector2(14, 34), Vector2(19, 20), Vector2(32, 13), Vector2(45, 20), Vector2(50, 34), Vector2(52, 56), Vector2(42, 48), Vector2(22, 48)]), robe)
	_ellipse(img, 32.0, 33.0, 10.5, 12.5, skin)
	# Masque d'os relevé.
	_ellipse(img, 32.0, 21.0, 10.0, 5.5, bone)
	for e in [Vector2(28, 21), Vector2(36, 21)]:
		_ellipse(img, e.x, e.y, 2.0, 1.6, _ramp(["1a1418"]), 0.0, true)
	# Barbe grise courte.
	_poly(img, PackedVector2Array([Vector2(23, 37), Vector2(25, 45), Vector2(32, 49), Vector2(39, 45), Vector2(41, 37), Vector2(36, 41), Vector2(28, 41)]), _ramp(["6a6a72", "9a9aa2", "c8c8d0"]))
	_brow(img, 26, 29, -1, mood, Color("8a8a92"), 2)
	_brow(img, 37, 29, 1, mood, Color("8a8a92"), 2)
	_eye(img, 25, 31, -1, mood, Color("9aa0a8"), Color("2a2a30"))
	_eye(img, 36, 31, 1, mood, Color("9aa0a8"), Color("2a2a30"))
	_mouth(img, 32, 42, mood, Color("4a3a3a"), Color("2a1a1a"))
	# Braise au collier.
	_glow(img, 32, 52, 4, Color("ff8a3a"), 0.4)
	_ellipse(img, 32.0, 52.0, 1.8, 1.8, _ramp(["c8402a", "ff8a3a", "ffd070"]))
	_rim(img, 3, 61, 12, 63, Color("d8d8e8"))


## Aurèle : inquisitrice de l'Ordre de l'Aube. Armure blanc et or, cheveux blonds courts, regard dur.
static func _aurele(img: Image, mood: String) -> void:
	var skin := _ramp(["b88a72", "e0b496", "f6d6bc"])
	var plate := _ramp(["8a8a9a", "c8c8d8", "eeeef8", "ffffff"])
	var gold := _ramp(["8a6a28", "c89a3a", "f2c46b", "fff0b0"])
	var hair := _ramp(["a8803a", "d8b060", "f0d890"])
	_poly(img, PackedVector2Array([Vector2(2, 64), Vector2(5, 49), Vector2(18, 43), Vector2(46, 43), Vector2(59, 49), Vector2(62, 64)]), plate)
	_ellipse(img, 10.0, 50.0, 9.0, 7.0, gold)
	_ellipse(img, 54.0, 50.0, 9.0, 7.0, gold)
	# Soleil de l'Aube sur le plastron.
	_ellipse(img, 32.0, 57.0, 3.2, 3.2, gold)
	for d in [Vector2i(0, -5), Vector2i(-5, 0), Vector2i(5, 0), Vector2i(-4, -4), Vector2i(4, -4)]:
		_px(img, 32 + d.x, 57 + d.y, Color("f2c46b"))
	_ellipse(img, 32.0, 32.0, 10.5, 12.5, skin)
	_poly(img, PackedVector2Array([Vector2(21, 32), Vector2(21, 22), Vector2(26, 17), Vector2(33, 15), Vector2(40, 17), Vector2(44, 23), Vector2(44, 32), Vector2(41, 25), Vector2(35, 23), Vector2(28, 24), Vector2(24, 28)]), hair)
	_brow(img, 26, 28, -1, "colere" if mood == "neutre" else mood, Color("a8803a"), 2)
	_brow(img, 37, 28, 1, "colere" if mood == "neutre" else mood, Color("a8803a"), 2)
	_eye(img, 25, 30, -1, mood, Color("3a6ab8"), Color("3a2a2a"))
	_eye(img, 36, 30, 1, mood, Color("3a6ab8"), Color("3a2a2a"))
	_px(img, 32, 35, Color("c8907a"))
	_mouth(img, 32, 39, mood, Color("9a4a4a"), Color("4a2a2a"))
	_rim(img, 2, 62, 10, 63, Color("fff6d8"))


## Corvin : jeune adepte renégat du Cercle. Capuche bleu-gris, cheveux bruns en désordre, rune au visage.
static func _corvin(img: Image, mood: String) -> void:
	var skin := _ramp(["a8806a", "d8ac8e", "f0ccb0"])
	var hood := _ramp(["1e2a3a", "3a4a5e", "5a6a82", "7a8aa2"])
	var hair := _ramp(["3a2414", "5a3a20", "7a5230"])
	_poly(img, PackedVector2Array([Vector2(4, 64), Vector2(8, 51), Vector2(20, 45), Vector2(44, 45), Vector2(56, 51), Vector2(60, 64)]), hood)
	_poly(img, PackedVector2Array([Vector2(13, 54), Vector2(14, 34), Vector2(18, 21), Vector2(32, 12), Vector2(46, 21), Vector2(50, 34), Vector2(51, 54), Vector2(42, 47), Vector2(22, 47)]), hood)
	_ellipse(img, 32.0, 33.0, 10.0, 12.0, skin)
	_poly(img, PackedVector2Array([Vector2(22, 30), Vector2(22, 22), Vector2(28, 18), Vector2(35, 18), Vector2(42, 22), Vector2(42, 29), Vector2(39, 24), Vector2(36, 27), Vector2(33, 23), Vector2(30, 27), Vector2(27, 23), Vector2(25, 28)]), hair)
	# Rune tatouée sur la joue.
	for q in [Vector2i(39, 35), Vector2i(40, 36), Vector2i(41, 35), Vector2i(40, 37), Vector2i(40, 38)]:
		_px(img, q.x, q.y, Color("b07cff"))
	_brow(img, 26, 29, -1, "triste" if mood == "neutre" else mood, Color("3a2414"))
	_brow(img, 37, 29, 1, "triste" if mood == "neutre" else mood, Color("3a2414"))
	_eye(img, 25, 31, -1, mood, Color("6a4a2a"), Color("2a1a14"))
	_eye(img, 36, 31, 1, mood, Color("6a4a2a"), Color("2a1a14"))
	_mouth(img, 32, 40, mood, Color("8a5a4a"), Color("3a2020"))
	_rim(img, 8, 58, 12, 63, Color("c8d8f0"))
