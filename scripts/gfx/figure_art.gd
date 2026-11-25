class_name FigureArt
extends RefCounted
## Personnages en pied des cinématiques (docs/design/41-cinematiques.md) : créatures et esprits qui se tiennent
## dans le décor au lieu de flotter.
## Le haut reste leur portrait, tel quel (PortraitArt : mêmes traits, bouche, expressions) ; le bas le prolonge
## à partir de sa dernière ligne de pixels (mêmes couleurs, mêmes motifs, sans coupure), puis prend sa forme :
## tronc et racines, robe en corolle et jambes, robe qui tombe jusqu'au sol.
## Le Grand Cerf est une image peinte (assets/figures/cerf.png) : sa tête est celle du portrait, son corps entier.

## id -> [largeur, hauteur, part de la hauteur de scène, en vol, centre de la tête (x, y), image peinte]
const SPEC := {
	"cerf": [149, 420, 0.9, false, Vector2(72, 83), true],
	"sylvarche": [96, 124, 1.0, false, Vector2(48, 33), false],
	"fee": [96, 100, 0.34, true, Vector2(48, 34), false],
	"morvaen": [96, 146, 0.84, false, Vector2(48, 34), false],
	"voix": [96, 146, 0.84, false, Vector2(48, 33), false],
	"lanterne": [40, 104, 0.42, false, Vector2(14, 32), false],
	"varg": [96, 152, 0.72, false, Vector2(48, 34), false],
	"gharok": [112, 168, 0.88, false, Vector2(48, 36), false],
}
const OX := 16 ## le portrait (64 px) est posé au milieu d'une image de 96 px

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


## Image peinte (taille libre à l'écran) plutôt que pixel-art (agrandi d'un facteur entier).
static func painted(id: String) -> bool:
	return bool(SPEC[id][5]) if SPEC.has(id) else false


static func texture(id: String, mood: String = "neutre", talk: int = 0, blink: bool = false) -> Texture2D:
	if not SPEC.has(id):
		return null
	var path := "res://assets/figures/%s.png" % id
	if painted(id) and ResourceLoader.exists(path):
		return load(path)
	var key := "%s|%s|%d|%s" % [id, mood, talk, str(blink)]
	if _cache.has(key):
		return _cache[key]
	var sp: Array = SPEC[id]
	var img := Image.create_empty(int(sp[0]), int(sp[1]), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if id == "lanterne":
		_lantern(img)
		PortraitArt._outline(img)
	else:
		var head := PortraitArt.frame(id, mood, talk, blink)
		var hi := head.get_image()
		hi.convert(Image.FORMAT_RGBA8)
		match id:
			"sylvarche":
				_sylvarche(img, hi, mood)
			"fee":
				_fee(img, hi)
			"morvaen":
				_robe(img, hi, 8.0, 0.35, true)
			"voix":
				_robe(img, hi, 6.0, 0.3, false)
			"varg":
				_varg(img, hi)
			"gharok":
				_gharok(img, hi)
		img.blend_rect(hi, Rect2i(0, 0, 64, 64), Vector2i(OX, 0))
		if id == "voix":
			# La Voix n'a pas de pieds : son ombre se dissout vers le sol.
			for y in range(84, img.get_height()):
				var k := 1.0 - float(y - 84) / float(img.get_height() - 84)
				for x in range(img.get_width()):
					var c := img.get_pixel(x, y)
					if c.a > 0.0:
						img.set_pixel(x, y, Color(c, c.a * k))
		else:
			PortraitArt._outline(img)
	var tex := ImageTexture.create_from_image(img)
	if _cache.size() > 80:
		_cache.clear()
	_cache[key] = tex
	return tex


# ---------------------------------------------------------------- prolonger le portrait

## Étendue opaque de la dernière ligne du portrait (sans le contour), en x du portrait.
static func _bottom_span(hi: Image) -> Vector2i:
	var y := hi.get_height() - 1
	var l := -1
	var r := -1
	for x in range(hi.get_width()):
		var c := hi.get_pixel(x, y)
		if c.a > 0.5 and not c.is_equal_approx(PortraitArt.OUTLINE):
			if l < 0:
				l = x
			r = x
	return Vector2i(l, r)


## Prolonge la dernière ligne du portrait vers le bas, de y0 à y1 : la forme s'élargit (flare de chaque côté)
## et chaque colonne garde la couleur de la colonne correspondante en haut (motifs, plis, écorce),
## un peu plus sombre vers le bas (darken).
static func _extend(img: Image, hi: Image, y0: int, y1: int, flare_l: float, flare_r: float, darken: float, wave: float = 0.0) -> void:
	var span := _bottom_span(hi)
	if span.x < 0:
		return
	var by := hi.get_height() - 1
	for y in range(y0, y1):
		var t := float(y - y0) / float(maxi(1, y1 - y0))
		var l := float(OX + span.x) - flare_l * t
		var r := float(OX + span.y) + flare_r * t
		for x in range(int(floor(l)), int(ceil(r)) + 1):
			var u := clampf((float(x) - l) / maxf(1.0, r - l), 0.0, 1.0)
			if wave > 0.0 and y > y1 - int(wave) - 1:
				# Bord ondulé (ourlet, corolle).
				if float(y1 - y) < wave * (0.5 + 0.5 * cos(u * TAU * 3.0)):
					continue
			var sx := clampi(int(round(lerpf(float(span.x), float(span.y), u))), span.x, span.y)
			var c := hi.get_pixel(sx, by)
			if c.a < 0.5 or c.is_equal_approx(PortraitArt.OUTLINE):
				continue
			PortraitArt._px(img, x, y, Color(c.darkened(darken * t), 1.0))


# ---------------------------------------------------------------- personnages

## La Sylvarche : le tronc du portrait descend, s'évase et plonge ses racines dans le sol ; les fissures
## (Surge violet, ou sève dorée une fois purifiée) continuent.
static func _sylvarche(img: Image, hi: Image, mood: String) -> void:
	var pure := mood == "joie"
	_extend(img, hi, 64, 112, 4.0, 4.0, 0.25)
	var bark := PortraitArt._ramp(["1a120e", "2a1e1a", "3a2e2a", "5a4030"])
	var base := 112.0
	for r: Array in [[Vector2(OX + 14, base - 6), Vector2(4, 123), 6.0], [Vector2(OX + 50, base - 6), Vector2(92, 123), 6.0],
			[Vector2(OX + 22, base - 2), Vector2(20, 123), 4.5], [Vector2(OX + 42, base - 2), Vector2(76, 123), 4.5],
			[Vector2(OX + 32, base), Vector2(OX + 30, 123), 4.0]]:
		_limb(img, r[0], r[1], float(r[2]), 1.5, bark)
	var crack := Color("f2c46b") if pure else Color("b07cff")
	PortraitArt._line(img, Vector2(OX + 33, 64), Vector2(OX + 31, 82), crack)
	PortraitArt._line(img, Vector2(OX + 31, 82), Vector2(OX + 35, 100), crack)
	PortraitArt._line(img, Vector2(OX + 21, 70), Vector2(OX + 18, 92), crack)
	PortraitArt._line(img, Vector2(OX + 45, 72), Vector2(OX + 48, 96), crack)


## La fée : la robe du portrait s'évase en corolle, puis deux jambes fines ; elle vole.
static func _fee(img: Image, hi: Image) -> void:
	_extend(img, hi, 64, 80, 7.0, 7.0, 0.18, 4.0)
	var skin := PortraitArt._ramp(["b89ac8", "e0c8f0", "f8ecff"])
	_limb(img, Vector2(OX + 28, 78), Vector2(OX + 27, 96), 1.8, 1.2, skin)
	_limb(img, Vector2(OX + 36, 78), Vector2(OX + 38, 94), 1.8, 1.2, skin)
	PortraitArt._px(img, OX + 27, 97, Color("c87ab0"))
	PortraitArt._px(img, OX + 38, 95, Color("c87ab0"))


## Morvaen et la Voix : la robe du portrait tombe jusqu'au sol en s'évasant, avec ses plis ; Morvaen a les pieds
## qui dépassent de l'ourlet.
static func _robe(img: Image, hi: Image, flare: float, darken: float, feet: bool) -> void:
	_extend(img, hi, 64, 144, flare, flare, darken, 2.0)
	var span := _bottom_span(hi)
	var fold := Color(0, 0, 0, 0.28)
	for k in range(1, 4):
		var x0 := float(OX + span.x) + float(span.y - span.x) * float(k) / 4.0
		var dx := (x0 - float(OX) - 32.0) * 0.22
		PortraitArt._line(img, Vector2(x0, 70), Vector2(x0 + dx, 140), fold)
	if feet:
		for fx: float in [float(OX) + 26.0, float(OX) + 38.0]:
			PortraitArt._ellipse(img, fx, 144.0, 3.5, 1.6, PortraitArt._ramp(["1a1426", "2a2038", "3a3048"]))


## Membre modelé : un cylindre qui s'affine de a (rayon r0) à b (rayon r1), ombré comme un volume.
static func _limb(img: Image, a: Vector2, b: Vector2, r0: float, r1: float, ramp: Array[Color]) -> void:
	var ab := b - a
	var len2 := maxf(0.001, ab.length_squared())
	var rmax := maxf(r0, r1)
	for y in range(int(floor(minf(a.y, b.y) - rmax)), int(ceil(maxf(a.y, b.y) + rmax)) + 1):
		for x in range(int(floor(minf(a.x, b.x) - rmax)), int(ceil(maxf(a.x, b.x) + rmax)) + 1):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
			var off := p - (a + ab * t)
			var r := lerpf(r0, r1, t)
			if off.length() > r:
				continue
			var n2 := off / maxf(0.001, r)
			PortraitArt._px(img, x, y, PortraitArt._shade(Vector3(n2.x, n2.y, sqrt(maxf(0.0, 1.0 - n2.length_squared()))), ramp))


## La Lanterne de l'Aube, accrochée à sa perche plantée dans le sol.
static func _lantern(img: Image) -> void:
	var wood := PortraitArt._ramp(["3a2a1a", "5a4030", "7a5a40"])
	PortraitArt._poly(img, PackedVector2Array([Vector2(28, 14), Vector2(32, 14), Vector2(32, 104), Vector2(28, 104)]), wood)
	PortraitArt._poly(img, PackedVector2Array([Vector2(10, 12), Vector2(32, 12), Vector2(32, 16), Vector2(10, 16)]), wood)
	PortraitArt._line(img, Vector2(14, 16), Vector2(14, 20), Color("2a2038"))
	var metal := PortraitArt._ramp(["2a2038", "5a5670", "8a86a0"])
	PortraitArt._poly(img, PackedVector2Array([Vector2(8, 20), Vector2(20, 20), Vector2(22, 24), Vector2(6, 24)]), metal)
	PortraitArt._poly(img, PackedVector2Array([Vector2(7, 24), Vector2(21, 24), Vector2(21, 40), Vector2(7, 40)]), PortraitArt._ramp(["f2c46b", "ffe08a", "fff6d0"]))
	PortraitArt._ellipse(img, 14.0, 32.0, 3.0, 5.0, PortraitArt._ramp(["fff6d0", "ffffff"]))
	for x: int in [7, 14, 21]:
		PortraitArt._line(img, Vector2(x, 24), Vector2(x, 40), Color("3a3048"))
	PortraitArt._poly(img, PackedVector2Array([Vector2(6, 40), Vector2(22, 40), Vector2(19, 44), Vector2(9, 44)]), metal)
	PortraitArt._glow(img, 14, 32, 12, Color("ffd070"), 0.25)



## Torse sous le portrait : une bande plus étroite que les épaules, centrée, dont chaque colonne garde la couleur
## de la colonne au-dessus (motifs, plis) ; largeur w0 en haut, w1 en bas, plus sombre vers le bas.
static func _torso(img: Image, hi: Image, y0: int, y1: int, w0: float, w1: float, darken: float) -> void:
	var span := _bottom_span(hi)
	if span.x < 0:
		return
	var by := hi.get_height() - 1
	var mid := float(span.x + span.y) * 0.5
	for y in range(y0, y1):
		var t := float(y - y0) / float(maxi(1, y1 - y0))
		var w := lerpf(w0, w1, t)
		var l := float(OX) + mid - w * 0.5
		for x in range(int(round(l)), int(round(l + w)) + 1):
			var u := clampf((float(x) - l) / maxf(1.0, w), 0.0, 1.0)
			var sx := clampi(int(round(mid - w0 * 0.5 + u * w0)), span.x, span.y)
			var c := hi.get_pixel(sx, by)
			if c.a < 0.5 or c.is_equal_approx(PortraitArt.OUTLINE):
				c = hi.get_pixel(clampi(int(mid), span.x, span.y), by)
			# Un peu d'ombre sur les flancs : le torse a du volume.
			var side := absf(u - 0.5) * 2.0
			PortraitArt._px(img, x, y, Color(c.darkened(darken * t + 0.18 * side * side), 1.0))


## Couleur de la dernière ligne du portrait, à « f » de la largeur (0 : bord gauche, 1 : bord droit).
static func _bottom_col(hi: Image, f: float) -> Color:
	var span := _bottom_span(hi)
	var x := clampi(int(round(lerpf(float(span.x), float(span.y), f))), span.x, span.y)
	return hi.get_pixel(x, hi.get_height() - 1)


static func _ramp_of(c: Color) -> Array[Color]:
	return [c.darkened(0.5), c.darkened(0.2), c, c.lightened(0.18)]


## Varg, chef pillard : torse dans la tunique rouge du portrait, bras qui pendent (manches rouges, mains nues),
## ceinture de cuir à boucle d'or, braies de cuir, bottes, et un sabre pendu à la hanche.
static func _varg(img: Image, hi: Image) -> void:
	var sleeve := _ramp_of(_bottom_col(hi, 0.12))
	var skin := PortraitArt._ramp(["6a3a28", "a86a4a", "d8946a"])
	for side: float in [-1.0, 1.0]:
		var sx := float(OX) + 32.0 + side * 22.0
		_limb(img, Vector2(sx, 62.0), Vector2(sx + side * 3.0, 96.0), 7.0, 5.5, sleeve)
		PortraitArt._ellipse(img, sx + side * 3.0, 99.0, 4.5, 4.5, skin)
	_torso(img, hi, 64, 98, 36.0, 30.0, 0.25)
	var belt := PortraitArt._ramp(["1a120c", "3a2418", "5a3a24"])
	PortraitArt._poly(img, PackedVector2Array([Vector2(OX + 16, 93), Vector2(OX + 48, 93), Vector2(OX + 48, 98), Vector2(OX + 16, 98)]), belt)
	PortraitArt._poly(img, PackedVector2Array([Vector2(OX + 29, 92), Vector2(OX + 35, 92), Vector2(OX + 35, 99), Vector2(OX + 29, 99)]), PortraitArt._ramp(["8a6a20", "d8b048", "fff0a0"]))
	var pants := PortraitArt._ramp(["1e1612", "3a2a20", "5a4030"])
	_limb(img, Vector2(OX + 25, 98), Vector2(OX + 23, 140), 7.0, 5.0, pants)
	_limb(img, Vector2(OX + 39, 98), Vector2(OX + 41, 140), 7.0, 5.0, pants)
	var boot := PortraitArt._ramp(["0e0a08", "2a1e18", "4a3428"])
	PortraitArt._ellipse(img, float(OX) + 22.0, 144.0, 7.0, 5.0, boot)
	PortraitArt._ellipse(img, float(OX) + 42.0, 144.0, 7.0, 5.0, boot)
	# Sabre au fourreau, sur la hanche gauche.
	PortraitArt._line(img, Vector2(OX + 15, 97), Vector2(OX + 7, 134), Color("2a1e18"), 3)
	PortraitArt._line(img, Vector2(OX + 15, 97), Vector2(OX + 7, 134), Color("8a8a98"))
	PortraitArt._line(img, Vector2(OX + 12, 94), Vector2(OX + 19, 97), Color("d8b048"), 2)


## Gharok, seigneur de guerre : torse cuirassé sous les épaulières, bras d'orc massifs aux brassards de fer, la
## hache de guerre en main, ceinture au crâne, pagne de fourrure rouge, jambes massives ; le Surge veine sa peau.
static func _gharok(img: Image, hi: Image) -> void:
	var skin := PortraitArt._ramp(["2a4a20", "4a7a34", "7aaa4a"])
	var iron := PortraitArt._ramp(["3a3a48", "6a6a7a", "a8a8b8"])
	# La hache, tenue de la main droite, le fer près du sol.
	PortraitArt._line(img, Vector2(OX + 60, 92), Vector2(OX + 66, 150), Color("3a2418"), 3)
	PortraitArt._poly(img, PackedVector2Array([Vector2(OX + 62, 128), Vector2(OX + 76, 122), Vector2(OX + 78, 146), Vector2(OX + 65, 142)]), iron)
	PortraitArt._line(img, Vector2(OX + 76, 122), Vector2(OX + 78, 146), Color("e8e8f0"))
	for side: float in [-1.0, 1.0]:
		var sx := float(OX) + 32.0 + side * 25.0
		_limb(img, Vector2(sx, 64.0), Vector2(sx + side * 3.0, 100.0), 9.5, 8.0, skin)
		PortraitArt._poly(img, PackedVector2Array([Vector2(sx + side * 3.0 - 8.5, 86), Vector2(sx + side * 3.0 + 8.5, 86), Vector2(sx + side * 3.0 + 8.0, 93), Vector2(sx + side * 3.0 - 8.0, 93)]), iron)
		PortraitArt._ellipse(img, sx + side * 3.0, 103.0, 6.5, 6.0, skin)
		PortraitArt._line(img, Vector2(sx - side * 2.0, 70), Vector2(sx + side * 1.0, 82), Color("d93cf2"))
	_torso(img, hi, 64, 102, 40.0, 36.0, 0.3)
	var belt := PortraitArt._ramp(["1a100c", "3a2418", "5a3a24"])
	PortraitArt._poly(img, PackedVector2Array([Vector2(OX + 13, 98), Vector2(OX + 51, 98), Vector2(OX + 51, 105), Vector2(OX + 13, 105)]), belt)
	# Boucle : un crâne.
	PortraitArt._ellipse(img, float(OX) + 32.0, 101.5, 5.0, 4.5, PortraitArt._ramp(["a8a088", "d8d0b8", "f4f0e0"]))
	PortraitArt._px(img, OX + 30, 101, Color("1a1410"))
	PortraitArt._px(img, OX + 34, 101, Color("1a1410"))
	# Pagne de fourrure rouge, à l'ourlet déchiqueté.
	var cloth := PortraitArt._ramp(["4a1010", "8a2020", "c03a2a"])
	for y in range(105, 124):
		var t := float(y - 105) / 19.0
		var l := float(OX) + 13.0 - 5.0 * t
		var r := float(OX) + 51.0 + 5.0 * t
		for x in range(int(l), int(r) + 1):
			if y > 118 and (x * 7 + y) % 5 < 2:
				continue
			var n := Vector3(clampf((float(x) - (l + r) * 0.5) / ((r - l) * 0.5), -1.0, 1.0), 0.0, 0.6)
			PortraitArt._px(img, x, y, PortraitArt._shade(n.normalized(), cloth))
	_limb(img, Vector2(OX + 23, 118), Vector2(OX + 21, 156), 9.0, 7.0, skin)
	_limb(img, Vector2(OX + 41, 118), Vector2(OX + 43, 156), 9.0, 7.0, skin)
	PortraitArt._line(img, Vector2(OX + 19, 128), Vector2(OX + 23, 146), Color("d93cf2"))
	PortraitArt._line(img, Vector2(OX + 45, 130), Vector2(OX + 42, 148), Color("d93cf2"))
	var boot := PortraitArt._ramp(["0e0a08", "2a1e18", "4a3428"])
	PortraitArt._ellipse(img, float(OX) + 20.0, 160.0, 10.0, 6.0, boot)
	PortraitArt._ellipse(img, float(OX) + 44.0, 160.0, 10.0, 6.0, boot)
	for bx: int in [OX + 20, OX + 44]:
		PortraitArt._line(img, Vector2(bx - 8, 155), Vector2(bx + 8, 155), Color("8a8a98"))
