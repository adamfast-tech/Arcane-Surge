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
	"orrin": [96, 140, 0.7, false, Vector2(48, 34), false],
	"sphinx": [140, 124, 0.95, false, Vector2(70, 34), false],
	"gharok": [112, 168, 0.88, false, Vector2(48, 36), false],
	"mere_dragon": [200, 176, 0.98, false, Vector2(100, 34), false],
	"wyrm": [200, 176, 1.0, false, Vector2(100, 34), false],
	"leviathan": [200, 176, 1.0, false, Vector2(100, 34), false],
	"ourdisseur": [96, 146, 0.84, false, Vector2(48, 33), false],
}
const OX := 16 ## le portrait (64 px) est posé au milieu d'une image de 96 px
const SOX := 38 ## le Sphinx : son portrait au milieu d'une image de 140 px
const DOX := 68 ## les dragons : leur portrait au milieu d'une image de 200 px (ailes déployées)

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
			"orrin":
				_robe(img, hi, 7.0, 0.25, false)
			"sphinx":
				_sphinx(img)
			"gharok":
				_gharok(img, hi)
			"mere_dragon", "wyrm":
				_dragon(img, id == "wyrm")
			"leviathan":
				_leviathan(img)
			"ourdisseur":
				_robe(img, hi, 6.0, 0.3, false)
		var hox := OX
		if id == "sphinx":
			hox = SOX
		elif id in ["mere_dragon", "wyrm", "leviathan"]:
			hox = DOX
		img.blend_rect(hi, Rect2i(0, 0, 64, 64), Vector2i(hox, 0))
		if id == "ourdisseur":
			# L'Ourdisseur : sa robe se défait en fils qui pendent jusqu'au sol, violets et turquoise.
			for k in range(11):
				var fx := 22 + k * 5
				var col := Color("4fe3d2") if k % 3 == 0 else Color("b8a0e8")
				for y in range(70, img.get_height() - 2):
					var xx := fx + int(sin(float(y) * 0.12 + float(k)) * 2.0)
					if y % 7 != k % 7:
						PortraitArt._px(img, xx, y, Color(col, 0.85))
		if id == "voix" or id == "orrin" or id == "ourdisseur":
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



## Le Sphinx de verre, couché : la tête coiffée du portrait, un corps de lion de verre derrière elle, les
## pattes avant allongées devant, les hanches de part et d'autre ; liserés d'or.
static func _sphinx(img: Image) -> void:
	var glass := PortraitArt._ramp(["1e5a70", "4a9ab8", "8ad0e8", "d8f6ff"])
	var cx := float(SOX) + 32.0
	PortraitArt._ellipse(img, cx, 86.0, 62.0, 18.0, glass)
	for side: float in [-1.0, 1.0]:
		PortraitArt._ellipse(img, cx + side * 48.0, 92.0, 20.0, 18.0, glass)
		PortraitArt._ellipse(img, cx + side * 60.0, 108.0, 9.0, 5.0, glass)
	PortraitArt._poly(img, PackedVector2Array([Vector2(cx - 16.0, 56), Vector2(cx + 16.0, 56), Vector2(cx + 19.0, 104), Vector2(cx - 19.0, 104)]), glass)
	for side2: float in [-1.0, 1.0]:
		var px := cx + side2 * 13.0
		PortraitArt._poly(img, PackedVector2Array([Vector2(px - 8.0, 96), Vector2(px + 8.0, 96), Vector2(px + 9.0, 118), Vector2(px - 9.0, 118)]), glass)
		PortraitArt._ellipse(img, px, 118.0, 10.0, 4.5, glass)
		for k in range(3):
			PortraitArt._px(img, int(px) - 5 + k * 5, 121, Color("f2d070"))
	for x in range(int(cx) - 18, int(cx) + 19):
		PortraitArt._px(img, x, 66, Color("e8b84a"))
		PortraitArt._px(img, x, 67, Color("a87a2a"))
	for k in range(6):
		PortraitArt._line(img, Vector2(cx - 50.0 + float(k) * 20.0, 74.0), Vector2(cx - 46.0 + float(k) * 20.0, 96.0), Color(1, 1, 1, 0.35))



## Les dragons de la Forêt Cendrée, assis comme un chat de garde : ailes déployées derrière eux, long cou sous
## la tête du portrait, poitrail aux écailles de ventre, pattes avant plantées (griffes), cuisses repliées,
## queue enroulée. La Mère-Dragon est cuivre et or ; le Wyrm est noir de cendre, fendu de lave, ailes déchirées.
static func _dragon(img: Image, wyrm: bool) -> void:
	var cx := float(DOX) + 32.0
	var hide := PortraitArt._ramp(["1a1214", "2e2428", "443a3e", "5e5256"] if wyrm else ["6a2e10", "b0561a", "e08a38", "ffc070"])
	var memb := PortraitArt._ramp(["1e0e0e", "3a1a16", "5a2a20"] if wyrm else ["5a1e0c", "8a3a16", "c06028"])
	var bone := Color("6a5a5e") if wyrm else Color("ffcf80")
	var belly := PortraitArt._ramp(["2a2224", "3e3234", "524446"] if wyrm else ["c88a40", "f0c070", "ffe0a0"])
	var glow := Color("ff6a1a")
	# Ailes : bras de l'aile de l'épaule au poignet, doigts jusqu'au bord ; la membrane entre eux, bord festonné.
	for side: float in [-1.0, 1.0]:
		var sh := Vector2(cx + side * 16.0, 80.0)
		var wrist := Vector2(cx + side * 62.0, 22.0)
		var tips := [Vector2(cx + side * 96.0, 8.0), Vector2(cx + side * 98.0, 48.0), Vector2(cx + side * 86.0, 86.0), Vector2(cx + side * 58.0, 108.0)]
		for f in range(tips.size() - 1):
			var a: Vector2 = tips[f]
			var b: Vector2 = tips[f + 1]
			var mid := (a + b) * 0.5 + Vector2(-side * 8.0, -6.0)
			PortraitArt._poly(img, PackedVector2Array([wrist, a, mid, b]), memb, -0.1 * side)
		PortraitArt._poly(img, PackedVector2Array([sh, wrist, tips[3] as Vector2, Vector2(cx + side * 22.0, 104.0)]), memb, -0.1 * side)
		if wyrm:
			# Ailes déchirées : des trous dans la membrane, bords rongés de braise.
			for hcen in [Vector2(cx + side * 80.0, 40.0), Vector2(cx + side * 70.0, 78.0), Vector2(cx + side * 44.0, 92.0)]:
				var hc: Vector2 = hcen
				for yy in range(-5, 6):
					for xx in range(-4, 5):
						if Vector2(float(xx), float(yy) * 0.8).length() <= 4.0:
							img.set_pixel(int(hc.x) + xx, int(hc.y) + yy, Color(0, 0, 0, 0))
				PortraitArt._px(img, int(hc.x) + 4, int(hc.y), glow)
				PortraitArt._px(img, int(hc.x) - 4, int(hc.y) + 1, glow)
		PortraitArt._line(img, sh, wrist, bone, 2)
		for tp in tips:
			PortraitArt._line(img, wrist, tp as Vector2, bone, 1)
		# Griffe au poignet.
		PortraitArt._line(img, wrist, wrist + Vector2(side * 3.0, -5.0), Color("f0e8d8"), 1)
	# Queue : elle part de la cuisse droite et s'enroule devant, pointe en fer de lance.
	var tail := [Vector2(cx + 34.0, 150.0), Vector2(cx + 62.0, 160.0), Vector2(cx + 80.0, 150.0), Vector2(cx + 84.0, 132.0)]
	for i in range(tail.size() - 1):
		_limb(img, tail[i] as Vector2, tail[i + 1] as Vector2, 9.0 - float(i) * 2.4, 9.0 - float(i + 1) * 2.4, hide)
	PortraitArt._poly(img, PackedVector2Array([Vector2(cx + 84.0, 136.0), Vector2(cx + 78.0, 124.0), Vector2(cx + 86.0, 116.0), Vector2(cx + 90.0, 126.0)]), PortraitArt._ramp(["3a0e0a", "6a1a12"] if wyrm else ["8a3a12", "c86020"]))
	# Cuisses repliées, puis le corps.
	for side2: float in [-1.0, 1.0]:
		PortraitArt._ellipse(img, cx + side2 * 30.0, 146.0, 22.0, 20.0, hide, 0.1 * side2)
		PortraitArt._ellipse(img, cx + side2 * 40.0, 166.0, 12.0, 5.0, hide)
	PortraitArt._ellipse(img, cx, 122.0, 34.0, 36.0, hide)
	# Long cou sous la tête.
	PortraitArt._poly(img, PackedVector2Array([Vector2(cx - 10.0, 50.0), Vector2(cx + 10.0, 50.0), Vector2(cx + 20.0, 96.0), Vector2(cx - 20.0, 96.0)]), hide)
	# Écailles de ventre : plaques claires du cou au bas du poitrail.
	for k in range(13):
		var y := 62 + k * 7
		var half := 6.0 + float(k) * 1.4 if k < 7 else 15.0 - float(k - 7) * 1.6
		PortraitArt._poly(img, PackedVector2Array([Vector2(cx - half, float(y)), Vector2(cx + half, float(y)), Vector2(cx + half - 1.0, float(y + 6)), Vector2(cx - half + 1.0, float(y + 6))]), belly)
		for x in range(int(cx - half) + 1, int(cx + half)):
			PortraitArt._px(img, x, y + 6, belly[0].darkened(0.3))
	# Pattes avant plantées, griffes d'ivoire.
	for side3: float in [-1.0, 1.0]:
		var top := Vector2(cx + side3 * 22.0, 104.0)
		var knee := Vector2(cx + side3 * 26.0, 136.0)
		var foot := Vector2(cx + side3 * 24.0, 164.0)
		_limb(img, top, knee, 10.0, 8.0, hide)
		_limb(img, knee, foot, 8.0, 7.0, hide)
		PortraitArt._ellipse(img, foot.x, 168.0, 11.0, 5.0, hide)
		for c in range(4):
			var clx := int(foot.x) - 8 + c * 5
			PortraitArt._px(img, clx, 172, Color("f0e8d8"))
			PortraitArt._px(img, clx, 173, Color("c8b8a8"))
	if wyrm:
		# Fissures de lave sur tout le corps, comme sur son visage.
		var rng := RandomNumberGenerator.new()
		rng.seed = 6010
		for v in range(16):
			var p := Vector2(cx + rng.randf_range(-40.0, 40.0), rng.randf_range(84.0, 166.0))
			var d := Vector2.from_angle(rng.randf_range(0.6, 2.5))
			for q in range(rng.randi_range(5, 11)):
				if img.get_pixel(int(p.x), int(p.y)).a > 0.5:
					PortraitArt._px(img, int(p.x), int(p.y), glow if q % 3 else Color("ffd060"))
				d = d.rotated(rng.randf_range(-0.5, 0.5))
				p += d
		PortraitArt._glow(img, int(cx), 120, 30, glow, 0.12)
	else:
		# Reflets d'or sur les écailles.
		for i in range(40):
			var gx := int(cx) + (i * 37) % 80 - 40
			var gy := 90 + (i * 53) % 76
			if img.get_pixel(gx, gy).a > 0.5:
				PortraitArt._px(img, gx, gy, Color("ffe8a0"))



## Le Léviathan, serpent des abysses : le long cou plonge sous la tête du portrait et s'enroule en grands
## anneaux de part et d'autre ; nageoires pectorales déployées, épines dorsales, points de lumière ;
## la Marée noire du Surge le ronge (taches d'encre aux reflets violets).
static func _leviathan(img: Image) -> void:
	var cx := float(DOX) + 32.0
	var hide := PortraitArt._ramp(["122a40", "1e4a6e", "2e6a94", "4a8ab8"])
	var belly := PortraitArt._ramp(["3a6a7a", "6aa0a8", "a0d0d0"])
	var fin := PortraitArt._ramp(["14505e", "2a8a98", "5ac8c8"])
	# Anneaux : le corps sort du sol et y replonge en arches, de part et d'autre du cou, épines sur le dos.
	for hump in [[-44.0, 22.0, 44.0, 11.0], [-82.0, 14.0, 30.0, 8.0], [44.0, 22.0, 44.0, 11.0], [82.0, 14.0, 30.0, 8.0]]:
		var hc := cx + float(hump[0])
		var hr := float(hump[1])
		var hh := float(hump[2])
		var th := float(hump[3])
		var arc: Array[Vector2] = []
		for k in range(13):
			var a := lerpf(PI, TAU, float(k) / 12.0)
			arc.append(Vector2(hc + cos(a) * hr, 174.0 + sin(a) * hh))
		for k in range(arc.size() - 1):
			_limb(img, arc[k], arc[k + 1], th, th, hide)
		for k in range(2, arc.size() - 2, 2):
			var sp: Vector2 = arc[k]
			var up := (sp - Vector2(hc, 174.0)).normalized()
			PortraitArt._poly(img, PackedVector2Array([sp + up * th * 0.6 + up.orthogonal() * 3.0, sp + up * th * 0.6 - up.orthogonal() * 3.0, sp + up * (th + 8.0)]), fin)
	# Nageoires pectorales.
	for side2: float in [-1.0, 1.0]:
		var root := Vector2(cx + side2 * 16.0, 98.0)
		PortraitArt._poly(img, PackedVector2Array([root, root + Vector2(side2 * 40.0, -18.0), root + Vector2(side2 * 46.0, 6.0), root + Vector2(side2 * 30.0, 18.0)]), fin, -0.1 * side2)
		for r in range(3):
			PortraitArt._line(img, root, root + Vector2(side2 * (40.0 - float(r) * 5.0), -14.0 + float(r) * 12.0), Color("8ae8e0"), 1)
	# Le cou qui descend du menton et plonge dans le sol.
	var neck: Array[Vector2] = [Vector2(cx, 52.0), Vector2(cx + 6.0, 84.0), Vector2(cx - 4.0, 120.0), Vector2(cx + 2.0, 150.0), Vector2(cx, 176.0)]
	for k in range(neck.size() - 1):
		_limb(img, neck[k], neck[k + 1], 12.0 + float(k) * 2.5, 12.0 + float(k + 1) * 2.5, hide)
	for k in range(14):
		var y := 60 + k * 8
		var f := float(y - 52) / 124.0
		var nx := cx + sin(f * 5.0) * 4.0
		var half := 5.0 + f * 7.0
		PortraitArt._poly(img, PackedVector2Array([Vector2(nx - half, float(y)), Vector2(nx + half, float(y)), Vector2(nx + half - 1.0, float(y + 6)), Vector2(nx - half + 1.0, float(y + 6))]), belly)
	# Points de lumière et Marée noire.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7010
	for i in range(40):
		var gx := rng.randi_range(int(cx) - 90, int(cx) + 90)
		var gy := rng.randi_range(60, 172)
		if img.get_pixel(gx, gy).a > 0.5:
			PortraitArt._px(img, gx, gy, Color("aef8ff"))
	for i in range(7):
		var tx := rng.randi_range(int(cx) - 80, int(cx) + 80)
		var ty := rng.randi_range(90, 160)
		for yy in range(-4, 5):
			for xx in range(-6, 7):
				if Vector2(float(xx), float(yy) * 1.5).length() <= 6.0 - rng.randf() * 2.0 and img.get_pixel(tx + xx, ty + yy).a > 0.5:
					PortraitArt._px(img, tx + xx, ty + yy, Color("120a1e") if (xx + yy) % 4 else Color("5a2a8a"))
