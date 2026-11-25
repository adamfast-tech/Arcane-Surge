class_name FigureArt
extends RefCounted
## Personnages en pied des cinématiques (docs/design/41-cinematiques.md) : créatures et esprits qui se tiennent
## dans le décor au lieu de flotter. Chacun est dessiné d'un seul tenant, avec son anatomie : volumes ombrés
## (ellipses, membres modelés en cylindres), contour sombre et reflet de lune, comme les portraits.
## Zone 1 : le Grand Cerf, la Sylvarche, la fée, Morvaen, la Voix, la Lanterne de l'Aube.

## id -> [largeur, hauteur, part de la hauteur de scène, en vol, centre de la tête (x, y)]
const SPEC := {
	"cerf": [150, 150, 0.9, false, Vector2(46, 50)],
	"sylvarche": [140, 172, 1.05, false, Vector2(70, 104)],
	"fee": [56, 84, 0.36, true, Vector2(28, 22)],
	"morvaen": [72, 150, 0.86, false, Vector2(34, 28)],
	"voix": [72, 150, 0.86, false, Vector2(34, 28)],
	"lanterne": [40, 104, 0.42, false, Vector2(14, 32)],
}

static var _cache: Dictionary = {}


static func has(id: String) -> bool:
	return SPEC.has(id)


## Part de la hauteur de scène qu'occupe le personnage.
static func height_share(id: String) -> float:
	return float(SPEC[id][2]) if SPEC.has(id) else 0.8


static func flies(id: String) -> bool:
	return bool(SPEC[id][3]) if SPEC.has(id) else false


## Centre de la tête (pixels de l'image) : les effets « @subject » visent là.
static func head_center(id: String) -> Vector2:
	return SPEC[id][4] if SPEC.has(id) else Vector2(32, 32)


static func texture(id: String, mood: String = "neutre", talk: int = 0, blink: bool = false) -> Texture2D:
	if not SPEC.has(id):
		return null
	var key := "%s|%s|%d|%s" % [id, mood, talk, str(blink)]
	if _cache.has(key):
		return _cache[key]
	var sp: Array = SPEC[id]
	var img := Image.create_empty(int(sp[0]), int(sp[1]), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match id:
		"cerf":
			_cerf(img, mood)
		"sylvarche":
			_sylvarche(img, mood)
		"fee":
			_fee(img, mood, talk, blink)
		"morvaen":
			_morvaen(img)
		"voix":
			_voix(img, mood)
		"lanterne":
			_lantern(img)
	if id == "voix":
		# La Voix n'a pas de pieds : son ombre se dissout vers le sol.
		for y in range(96, img.get_height()):
			var k := 1.0 - float(y - 96) / float(img.get_height() - 96)
			for x in range(img.get_width()):
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					img.set_pixel(x, y, Color(c, c.a * k))
	else:
		PortraitArt._outline(img)
		PortraitArt._rim(img, 0, img.get_width() - 1, 0, img.get_height() - 1, Color("cfd8ff"))
	var tex := ImageTexture.create_from_image(img)
	if _cache.size() > 80:
		_cache.clear()
	_cache[key] = tex
	return tex


# ---------------------------------------------------------------- outils

static func _r(hexes: Array) -> Array[Color]:
	return PortraitArt._ramp(hexes)


static func _e(img: Image, cx: float, cy: float, rx: float, ry: float, ramp: Array[Color], bias: float = 0.0) -> void:
	PortraitArt._ellipse(img, cx, cy, rx, ry, ramp, bias)


static func _poly(img: Image, pts: Array, ramp: Array[Color], bias: float = 0.0, flat: bool = false) -> void:
	PortraitArt._poly(img, PackedVector2Array(pts), ramp, bias, flat)


## Membre modelé : un cylindre qui s'affine de a (rayon r0) à b (rayon r1), ombré comme un volume.
static func _limb(img: Image, a: Vector2, b: Vector2, r0: float, r1: float, ramp: Array[Color], bias: float = 0.0) -> void:
	var ab := b - a
	var len2 := maxf(0.001, ab.length_squared())
	var rmax := maxf(r0, r1)
	var x0 := int(floor(minf(a.x, b.x) - rmax))
	var x1 := int(ceil(maxf(a.x, b.x) + rmax))
	var y0 := int(floor(minf(a.y, b.y) - rmax))
	var y1 := int(ceil(maxf(a.y, b.y) + rmax))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
			var on := a + ab * t
			var r := lerpf(r0, r1, t)
			var off := p - on
			var d := off.length()
			if d > r:
				continue
			var n2 := off / maxf(0.001, r)
			PortraitArt._px(img, x, y, PortraitArt._shade(Vector3(n2.x, n2.y, sqrt(maxf(0.0, 1.0 - n2.length_squared()))), ramp, bias))


## Chemin de lignes (ramures, branches, fissures).
static func _path(img: Image, pts: Array, c: Color, w: int = 1) -> void:
	for i in range(pts.size() - 1):
		PortraitArt._line(img, pts[i], pts[i + 1], c, w)


# ---------------------------------------------------------------- le Grand Cerf

## De trois quarts, tourné vers la gauche, la tête vers nous : ramure de lumière, cou puissant, poitrail clair,
## corps, cuisses, pattes fines aux genoux marqués, sabots.
static func _cerf(img: Image, mood: String) -> void:
	var fur := _r(["2e2430", "4a3c4a", "766676", "a898a8"])
	var far := _r(["1c1620", "2e2430", "4a3c4a"])
	var light := _r(["8a7a8a", "b0a0b0", "d8ccd8"])
	var hoof := _r(["120e1a", "2a2038"])
	var horn := Color("cfe6ff")
	var o := Vector2(0, 10)
	# Halo de la ramure.
	PortraitArt._glow(img, 48, 22, 30, Color("9ff0ff"), 0.14)
	# Pattes du fond, plus sombres.
	_limb(img, Vector2(64, 96) + o, Vector2(61, 118) + o, 4.5, 3.0, far)
	_limb(img, Vector2(61, 118) + o, Vector2(60, 134) + o, 2.6, 2.2, far)
	_e(img, 60.0, 135.5 + o.y, 3.0, 2.0, hoof)
	_limb(img, Vector2(116, 88) + o, Vector2(124, 110) + o, 8.0, 4.0, far)
	_limb(img, Vector2(124, 110) + o, Vector2(119, 134) + o, 3.0, 2.2, far)
	_e(img, 119.0, 135.5 + o.y, 3.0, 2.0, hoof)
	# Corps : tonneau, croupe, poitrail.
	_e(img, 92.0, 84.0 + o.y, 34.0, 16.0, fur)
	_e(img, 114.0, 80.0 + o.y, 17.0, 18.0, fur, 0.05)
	_e(img, 62.0, 82.0 + o.y, 16.0, 18.0, fur, 0.05)
	_e(img, 128.0, 68.0 + o.y, 3.5, 5.5, light)
	# Pattes de devant (près de nous).
	_limb(img, Vector2(62, 92) + o, Vector2(66, 116) + o, 6.0, 3.2, fur)
	_limb(img, Vector2(66, 116) + o, Vector2(65, 134) + o, 2.8, 2.3, fur)
	_e(img, 65.0, 136.0 + o.y, 3.2, 2.2, hoof)
	_limb(img, Vector2(110, 92) + o, Vector2(118, 112) + o, 9.0, 4.2, fur)
	_limb(img, Vector2(118, 112) + o, Vector2(114, 134) + o, 3.0, 2.3, fur)
	_e(img, 114.0, 136.0 + o.y, 3.2, 2.2, hoof)
	# Cou puissant et jabot clair.
	_limb(img, Vector2(60, 76) + o, Vector2(50, 44) + o, 12.0, 7.5, fur)
	_e(img, 53.0, 68.0 + o.y, 4.5, 8.0, light, 0.1)
	# Tête de trois quarts : crâne, chanfrein, mufle, oreilles.
	_poly(img, [Vector2(40, 36) + o, Vector2(28, 28) + o, Vector2(31, 34) + o, Vector2(40, 40) + o], fur)
	_poly(img, [Vector2(56, 34) + o, Vector2(68, 26) + o, Vector2(66, 32) + o, Vector2(57, 39) + o], fur)
	_e(img, 48.0, 38.0 + o.y, 10.0, 9.0, fur)
	_limb(img, Vector2(47, 42) + o, Vector2(42, 54) + o, 6.5, 4.2, fur)
	_e(img, 41.5, 55.5 + o.y, 4.0, 3.0, light)
	_e(img, 41.0, 56.5 + o.y, 2.0, 1.3, _r(["07060f", "1a1426"]))
	# Yeux lumineux.
	var eye := Color("cfffff")
	for e: Vector2 in [Vector2(43, 39), Vector2(52, 38)]:
		PortraitArt._glow(img, int(e.x), int(e.y + o.y), 3, Color("9ff0ff"), 0.4)
		PortraitArt._px(img, int(e.x), int(e.y + o.y), eye)
		PortraitArt._px(img, int(e.x) + 1, int(e.y + o.y), Color("9ff0ff"))
	# Ramure : deux merrains qui s'ouvrent, avec leurs andouillers.
	for s: float in [-1.0, 1.0]:
		var b := Vector2(48.0 + s * 4.0, 30.0) + o
		var m1 := b + Vector2(s * 8.0, -10.0)
		var m2 := m1 + Vector2(s * 10.0, -10.0)
		var m3 := m2 + Vector2(s * 6.0, -12.0)
		_path(img, [b, m1, m2, m3], horn, 2)
		_path(img, [m1, m1 + Vector2(-s * 2.0, -9.0)], horn, 1)
		_path(img, [m2, m2 + Vector2(-s * 3.0, -10.0)], horn, 1)
		_path(img, [m2, m2 + Vector2(s * 9.0, -2.0)], horn, 1)
		_path(img, [m3, m3 + Vector2(s * 5.0, -3.0)], horn, 1)
		PortraitArt._px(img, int(m3.x), int(m3.y), Color.WHITE)
	if mood == "colere":
		# Corrompu : traînées violettes sur le pelage, lueur malade dans la ramure.
		for p in [[Vector2(78, 76), Vector2(84, 86), Vector2(80, 96)], [Vector2(104, 74), Vector2(100, 86), Vector2(106, 96)], [Vector2(56, 60), Vector2(60, 72)]]:
			var pts: Array = []
			for q: Vector2 in p:
				pts.append(q + o)
			_path(img, pts, Color("b07cff"))
		PortraitArt._glow(img, 48, 22, 24, Color("d93cf2"), 0.12)


# ---------------------------------------------------------------- la Sylvarche

## L'arbre-mère entier : couronne en grappes, tronc noueux qui s'évase, visage creusé dans l'écorce, racines.
## « joie » : purifiée (feuillage vert, sève dorée) ; sinon corrompue (feuillage violet, fissures du Surge).
static func _sylvarche(img: Image, mood: String) -> void:
	var pure := mood == "joie"
	var leaves := _r(["22301a", "3f5a30", "4f6b3a", "7faa4a"]) if pure else _r(["1a1035", "3b2a6b", "5a2a7a", "8e62e0"])
	var bark := _r(["241a16", "3a2e2a", "5a4030", "7a5a40"])
	var dark_bark := _r(["1a120e", "2a1e1a", "3a2e2a"])
	var glow := Color("f2e28b") if pure else Color("d93cf2")
	# Racines.
	for r: Array in [[Vector2(56, 148), Vector2(24, 168), 7.0], [Vector2(84, 148), Vector2(118, 168), 7.0], [Vector2(62, 152), Vector2(46, 170), 5.0],
			[Vector2(78, 152), Vector2(94, 170), 5.0], [Vector2(70, 154), Vector2(70, 170), 4.0]]:
		_limb(img, r[0], r[1], float(r[2]), 1.5, dark_bark)
	# Branches maîtresses, derrière la couronne.
	_limb(img, Vector2(66, 78), Vector2(36, 46), 7.0, 3.0, bark)
	_limb(img, Vector2(74, 76), Vector2(106, 44), 7.0, 3.0, bark)
	_limb(img, Vector2(70, 70), Vector2(70, 34), 6.0, 3.0, bark)
	# Couronne : des grappes de feuillage, plus sombres dessous.
	for c: Array in [[70.0, 26.0, 30.0, 18.0], [38.0, 40.0, 26.0, 17.0], [102.0, 40.0, 26.0, 17.0], [24.0, 56.0, 18.0, 12.0],
			[116.0, 56.0, 18.0, 12.0], [54.0, 20.0, 20.0, 13.0], [88.0, 20.0, 20.0, 13.0], [70.0, 50.0, 28.0, 12.0]]:
		_e(img, float(c[0]), float(c[1]), float(c[2]), float(c[3]), leaves)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in range(70):
		var p := Vector2(rng.randf_range(8, 132), rng.randf_range(8, 66))
		if img.get_pixel(int(p.x), int(p.y)).a > 0.5:
			PortraitArt._px(img, int(p.x), int(p.y), leaves[3] if rng.randf() < 0.5 else leaves[0])
	# Tronc noueux qui s'évase vers le sol.
	_limb(img, Vector2(70, 152), Vector2(67, 112), 22.0, 15.0, bark)
	_limb(img, Vector2(67, 112), Vector2(70, 66), 15.0, 12.0, bark)
	for i in range(26):
		var x := rng.randi_range(52, 88)
		var y0 := rng.randi_range(64, 140)
		for y in range(y0, mini(150, y0 + rng.randi_range(4, 12))):
			if img.get_pixel(x, y).a > 0.5:
				PortraitArt._px(img, x, y, bark[0])
	# Visage creusé dans l'écorce : orbites, regard, bouche creuse.
	var sad := mood == "triste"
	for e: Vector2 in [Vector2(61, 101), Vector2(79, 101)]:
		_e(img, e.x, e.y, 5.0, 3.5 if not sad else 3.0, _r(["0c0812"]))
		PortraitArt._glow(img, int(e.x), int(e.y), 4, glow, 0.35)
		PortraitArt._px(img, int(e.x), int(e.y) + (1 if sad else 0), glow.lightened(0.5))
		PortraitArt._px(img, int(e.x) + 1, int(e.y) + (1 if sad else 0), glow)
	_path(img, [Vector2(55, 94), Vector2(62, 96), Vector2(67, 95)], bark[3])
	_path(img, [Vector2(73, 95), Vector2(78, 96), Vector2(85, 94)], bark[3])
	_e(img, 70.0, 118.0, 6.0, 3.5, _r(["0c0812"]))
	PortraitArt._glow(img, 70, 118, 5, glow, 0.2)
	# Fissures du Surge (ou sève dorée).
	var crack := Color("f2c46b") if pure else Color("b07cff")
	_path(img, [Vector2(58, 72), Vector2(62, 86), Vector2(57, 92)], crack)
	_path(img, [Vector2(82, 74), Vector2(78, 88), Vector2(83, 92)], crack)
	_path(img, [Vector2(68, 126), Vector2(65, 138), Vector2(70, 150)], crack)
	_path(img, [Vector2(76, 124), Vector2(80, 138)], crack)


# ---------------------------------------------------------------- la fée

## Une fée entière, en vol : ailes translucides nervurées, robe en corolle, bras et jambes fines.
static func _fee(img: Image, mood: String, talk: int, blink: bool) -> void:
	var wing: Array[Color] = [Color(0.75, 0.9, 1.0, 0.55)]
	var dress := _r(["8a4a7a", "c87ab0", "f7a8e0", "ffd8f4"])
	var skin := _r(["b89ac8", "e0c8f0", "f8ecff"])
	var hair := _r(["c87ab0", "f7a8e0", "ffe0f4"])
	for sd: float in [-1.0, 1.0]:
		var up: Array = []
		for p: Vector2 in [Vector2(26, 34), Vector2(16, 22), Vector2(6, 12), Vector2(1, 16), Vector2(3, 28), Vector2(12, 36), Vector2(22, 40)]:
			up.append(Vector2(28.0 + (p.x - 28.0) * sd, p.y))
		var low: Array = []
		for p: Vector2 in [Vector2(25, 42), Vector2(14, 44), Vector2(6, 52), Vector2(9, 58), Vector2(18, 55), Vector2(25, 47)]:
			low.append(Vector2(28.0 + (p.x - 28.0) * sd, p.y))
		_poly(img, up, wing, 0.0, true)
		_poly(img, low, wing, 0.0, true)
		_path(img, [Vector2(28.0 - sd * 3.0, 36), Vector2(28.0 - sd * 20.0, 16)], Color("cfe8ff"))
		_path(img, [Vector2(28.0 - sd * 3.0, 44), Vector2(28.0 - sd * 17.0, 54)], Color("cfe8ff"))
	# Jambes fines, pointes de pied.
	_limb(img, Vector2(25, 60), Vector2(23, 76), 1.8, 1.2, skin)
	_limb(img, Vector2(31, 60), Vector2(35, 74), 1.8, 1.2, skin)
	# Robe en corolle et buste.
	_poly(img, [Vector2(20, 44), Vector2(36, 44), Vector2(46, 60), Vector2(38, 64), Vector2(32, 60), Vector2(28, 64), Vector2(24, 60), Vector2(18, 64), Vector2(10, 60)], dress)
	_e(img, 28.0, 39.0, 6.0, 8.0, dress)
	# Bras.
	_limb(img, Vector2(23, 34), Vector2(16, 46), 2.0, 1.4, skin)
	_limb(img, Vector2(33, 34), Vector2(40, 44), 2.0, 1.4, skin)
	# Tête : cheveux, oreilles pointues, visage.
	_e(img, 28.0, 20.0, 10.0, 9.5, hair)
	_poly(img, [Vector2(20, 22), Vector2(14, 16), Vector2(16, 21), Vector2(20, 25)], skin)
	_poly(img, [Vector2(36, 22), Vector2(42, 16), Vector2(40, 21), Vector2(36, 25)], skin)
	_e(img, 28.0, 23.0, 7.0, 7.5, skin)
	_poly(img, [Vector2(21, 21), Vector2(22, 15), Vector2(28, 13), Vector2(34, 15), Vector2(35, 21), Vector2(31, 18), Vector2(28, 19), Vector2(25, 18)], hair)
	var eye := Color("5a2a7a")
	for ex: int in [25, 31]:
		if blink or mood == "joie":
			PortraitArt._px(img, ex - 1, 23, eye)
			PortraitArt._px(img, ex, 23, eye)
		else:
			PortraitArt._px(img, ex, 23, eye)
			PortraitArt._px(img, ex, 22, Color("8e62e0"))
			PortraitArt._px(img, ex + 1, 22, Color.WHITE)
	if talk > 0:
		PortraitArt._px(img, 28, 27, Color("6a2a5a"))
		PortraitArt._px(img, 28, 28 if talk == 2 else 27, Color("6a2a5a"))
	else:
		PortraitArt._px(img, 28, 27, Color("b06a9a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in range(8):
		var p := Vector2i(rng.randi_range(2, 54), rng.randi_range(2, 80))
		if img.get_pixel(p.x, p.y).a < 0.1:
			PortraitArt._px(img, p.x, p.y, Color("ffe0f4") if i % 2 == 0 else Color("9ff0ff"))


# ---------------------------------------------------------------- Morvaen et la Voix

## Morvaen, l'archimage : capuche profonde, regard turquoise, longue robe à plis, ceinture d'or, bâton à l'orbe.
static func _morvaen(img: Image) -> void:
	var robe := _r(["101838", "1d2f5a", "2f4f8f", "4a6ab8"])
	var inner := _r(["1f5a66", "2f8f9a", "4fb8c0"])
	var skin := _r(["5a4a4a", "8a7068", "b0948a"])
	# Bâton derrière la main.
	_limb(img, Vector2(57, 14), Vector2(59, 148), 1.6, 1.4, _r(["3a2a1a", "5a4030", "7a5a40"]))
	_e(img, 57.0, 12.0, 4.5, 4.5, _r(["1f5a66", "4fb8c0", "9ff0ff", "e8ffff"]))
	PortraitArt._glow(img, 57, 12, 9, Color("9ff0ff"), 0.3)
	# Robe : elle s'évase jusqu'au sol, pan central plus clair.
	_poly(img, [Vector2(20, 40), Vector2(48, 40), Vector2(54, 80), Vector2(64, 146), Vector2(4, 146), Vector2(14, 80)], robe)
	_poly(img, [Vector2(30, 46), Vector2(38, 46), Vector2(42, 146), Vector2(26, 146)], inner)
	for x: float in [18.0, 50.0]:
		_path(img, [Vector2(x, 84), Vector2(x + (x - 34.0) * 0.4, 146)], robe[0])
	_path(img, [Vector2(16, 76), Vector2(52, 76)], Color("c8a040"), 2)
	# Bras : l'un pend, l'autre tient le bâton.
	_limb(img, Vector2(22, 46), Vector2(16, 82), 6.0, 4.5, robe)
	_e(img, 16.0, 85.0, 3.0, 3.0, skin)
	_limb(img, Vector2(46, 46), Vector2(56, 70), 6.0, 4.5, robe)
	_e(img, 57.0, 72.0, 3.0, 3.0, skin)
	# Capuche et visage dans l'ombre.
	_poly(img, [Vector2(20, 44), Vector2(22, 24), Vector2(34, 10), Vector2(46, 24), Vector2(48, 44)], robe)
	_e(img, 34.0, 30.0, 8.0, 10.0, _r(["07060f"]))
	for ex: int in [31, 37]:
		PortraitArt._glow(img, ex, 29, 3, Color("4fe3d2"), 0.45)
		PortraitArt._px(img, ex, 29, Color("cfffff"))


## La Voix : une ombre couronnée, au regard violet, qui se dissout vers le sol.
static func _voix(img: Image, mood: String) -> void:
	var dark := _r(["07060f", "120e1a", "1a1035", "2a1e4a"])
	PortraitArt._glow(img, 34, 40, 30, Color("5a2a7a"), 0.25)
	_poly(img, [Vector2(18, 40), Vector2(50, 40), Vector2(60, 100), Vector2(66, 150), Vector2(2, 150), Vector2(8, 100)], dark)
	_poly(img, [Vector2(18, 46), Vector2(22, 22), Vector2(34, 12), Vector2(46, 22), Vector2(50, 46)], dark)
	for i in range(5):
		var x := 22 + i * 6
		var h := 12 - absi(2 - i) * 3
		_poly(img, [Vector2(x - 3, 18), Vector2(x, 17 - h), Vector2(x + 3, 18)], _r(["1a1035", "3b2a6b", "8e62e0"]))
		PortraitArt._px(img, x, 17 - h + 1, Color("d93cf2"))
	_e(img, 34.0, 30.0, 8.0, 10.0, _r(["050409"]))
	var ey := 29 if mood != "triste" else 30
	for ex: int in [31, 37]:
		PortraitArt._glow(img, ex, ey, 3, Color("d93cf2"), 0.5)
		PortraitArt._px(img, ex, ey, Color("ff9cff"))
	# Volutes d'ombre qui s'échappent de la robe.
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for i in range(6):
		var p := Vector2(rng.randf_range(8, 64), rng.randf_range(70, 140))
		for s in range(14):
			PortraitArt._px(img, int(p.x), int(p.y), Color(0.35, 0.16, 0.5, 0.5))
			p += Vector2(rng.randf_range(-1.0, 1.0), -1.0)


# ---------------------------------------------------------------- la Lanterne

## La Lanterne de l'Aube, accrochée à sa perche plantée dans le sol.
static func _lantern(img: Image) -> void:
	var wood := _r(["3a2a1a", "5a4030", "7a5a40"])
	_poly(img, [Vector2(28, 14), Vector2(32, 14), Vector2(32, 104), Vector2(28, 104)], wood)
	_poly(img, [Vector2(10, 12), Vector2(32, 12), Vector2(32, 16), Vector2(10, 16)], wood)
	PortraitArt._line(img, Vector2(14, 16), Vector2(14, 20), Color("2a2038"))
	var metal := _r(["2a2038", "5a5670", "8a86a0"])
	_poly(img, [Vector2(8, 20), Vector2(20, 20), Vector2(22, 24), Vector2(6, 24)], metal)
	_poly(img, [Vector2(7, 24), Vector2(21, 24), Vector2(21, 40), Vector2(7, 40)], _r(["f2c46b", "ffe08a", "fff6d0"]))
	_e(img, 14.0, 32.0, 3.0, 5.0, _r(["fff6d0", "ffffff"]))
	for x: int in [7, 14, 21]:
		PortraitArt._line(img, Vector2(x, 24), Vector2(x, 40), Color("3a3048"))
	_poly(img, [Vector2(6, 40), Vector2(22, 40), Vector2(19, 44), Vector2(9, 44)], metal)
	PortraitArt._glow(img, 14, 32, 12, Color("ffd070"), 0.25)
