class_name ItemArt
extends RefCounted
## Icônes d'équipement et de runes en pixel-art coloré, générées par code (docs/design/35-equipement-runes-forge.md).
## Chaque objet a un visuel « art » dans data/items.json : type (bâton, arc, heaume…), matière (bois, fer, or,
## os, verre…), teinte (tissu, cuir) et gemme. Rendu en 24×24 puis agrandi au plus proche voisin.

const S := 24
const OUTLINE := Color("140e1c")

## Matières : sombre, moyen, clair, reflet.
const MAT := {
	"wood": ["4a2e1a", "7a5230", "a8743a", "d0a060"], "darkwood": ["241a1e", "3e2e34", "5a4650", "7a6470"],
	"moonwood": ["5a6488", "8a94c0", "c0c8ec", "f0f2ff"], "iron": ["34384a", "5e6478", "9aa2b8", "e0e6f2"],
	"steel": ["4a5068", "7a849c", "c8d0e0", "ffffff"], "gold": ["7a5418", "c08a2a", "f2c46b", "fff0b0"],
	"bronze": ["5a3418", "945a28", "c8843a", "f0b870"], "copper": ["5a2a18", "9a4a28", "d07040", "f0a878"],
	"silver": ["5a6070", "9aa2b4", "d8dee8", "ffffff"], "bone": ["6a5a40", "a8987a", "dcd0b0", "fff8e4"],
	"crystal": ["2a6a88", "4fa8c8", "a8e4f0", "ffffff"], "frost": ["3a6a98", "6fa8d8", "bfe4ff", "ffffff"],
	"obsidian": ["120e1a", "2a2438", "4a4060", "8a7aa8"], "leather": ["3a2414", "6a4228", "9a6438", "c8925a"],
	"fur": ["6a6a74", "a8a8b4", "dcdce4", "ffffff"], "stone": ["3a3a44", "64646e", "9696a0", "c8c8d0"],
}
## Teintes (tissu, cuir, ruban).
const DYE := {
	"green": ["1e4a24", "2e7a36", "4fa848", "8fd870"], "moss": ["2a3a1e", "45602e", "6a8a42", "9ab868"],
	"red": ["5a1418", "9a2a2a", "c8402a", "f07a5a"], "blue": ["1a2a5a", "2a4a8a", "4a72c0", "8aaaf0"],
	"violet": ["2a1848", "4a2e7a", "7a50b8", "b090f0"], "white": ["8a8a9a", "c8c8d4", "eeeef4", "ffffff"],
	"grey": ["3a3a44", "5e5e6a", "8a8a96", "b8b8c4"], "brown": ["3a2414", "6a4228", "9a6438", "c8925a"],
	"sand": ["7a5a2a", "b88a4a", "e0b878", "f8e0b0"], "teal": ["145a5e", "1e8a8e", "3fc1c9", "9ff0f0"],
	"black": ["0e0c14", "201c2a", "38324a", "5a5070"], "ash": ["3a3640", "5e5864", "8a8490", "b8b2bc"],
	"fur": ["6a6a74", "a8a8b4", "dcdce4", "ffffff"],
}

static var _cache: Dictionary = {}


## Icône d'un objet (base de data/items.json) ; null si la base n'a pas de visuel.
static func item(base_id: String, px: int = 48) -> Texture2D:
	var key := "i|%s|%d" % [base_id, px]
	if _cache.has(key):
		return _cache[key]
	var base: Dictionary = (Profile.items_db()["bases"] as Dictionary).get(base_id, {})
	if not base.has("art"):
		return null
	var art: Dictionary = base["art"]
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var m: Array = MAT.get(str(art.get("m", "iron")), MAT["iron"])
	var c: Array = DYE.get(str(art.get("c", "")), _dye_for(str(art.get("m", "iron"))))
	var g := Color(str(art.get("g", "4fe3d2")))
	draw(img, str(art.get("t", "anneau")), m, c, g)
	_outline(img)
	var tex := _scaled(img, px)
	_cache[key] = tex
	return tex


## Pierre de rune : galet d'ardoise, glyphe gravé à la couleur de la famille, points de niveau.
static func rune(family: String, level: int, px: int = 48) -> Texture2D:
	var key := "r|%s|%d|%d" % [family, level, px]
	if _cache.has(key):
		return _cache[key]
	var fam: Dictionary = (Profile.items_db()["runes"]["families"] as Dictionary).get(family, {})
	var col := Color(str(fam.get("color", "4fe3d2")))
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var slate := ["1e1c2a", "34324a", "4e4a68", "6e6a8e"]
	_ell(img, 12.0, 11.5, 9.0, 10.0, _c(slate[1]))
	_ell(img, 12.5, 12.5, 8.0, 9.0, _c(slate[0]))
	_ell(img, 11.0, 10.0, 7.0, 7.5, _c(slate[1]))
	_ell(img, 10.0, 8.0, 4.0, 3.5, _c(slate[2]))
	_px(img, 8, 6, _c(slate[3]))
	_px(img, 9, 6, _c(slate[3]))
	# Lueur du glyphe.
	for y in range(4, 19):
		for x in range(5, 19):
			if img.get_pixel(x, y).a > 0.5:
				var d := Vector2(x, y).distance_to(Vector2(12, 11))
				if d < 7.0:
					_px(img, x, y, Color(col, 0.18 * (1.0 - d / 7.0)))
	_glyph(img, family, col)
	# Points de niveau (I à V).
	var n := clampi(level, 1, 5)
	var x0 := 12 - n
	for i in range(n):
		_px(img, x0 + i * 2, 19, col.lightened(0.3))
	_outline(img)
	var tex := _scaled(img, px)
	_cache[key] = tex
	return tex


static func _scaled(img: Image, px: int) -> ImageTexture:
	var k := maxi(1, int(round(float(px) / float(S))))
	var big := img.duplicate() as Image
	big.resize(S * k, S * k, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(big)


static func _dye_for(mat: String) -> Array:
	match mat:
		"gold", "bronze", "copper":
			return DYE["red"]
		"frost", "crystal", "silver", "moonwood":
			return DYE["blue"]
		"bone", "obsidian", "darkwood":
			return DYE["violet"]
	return DYE["brown"]


static func _c(h: String) -> Color:
	return Color(h)


# ---------------------------------------------------------------- primitives

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= S or y >= S:
		return
	if c.a < 1.0:
		var b := img.get_pixel(x, y)
		if b.a <= 0.0:
			img.set_pixel(x, y, c)
			return
		c = b.lerp(Color(c, 1.0), c.a)
	img.set_pixel(x, y, c)


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_px(img, xx, yy, c)


static func _line(img: Image, a: Vector2, b: Vector2, c: Color, w: int = 1) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in range(n + 1):
		var p := a.lerp(b, float(i) / float(maxi(1, n)))
		for dx in range(w):
			for dy in range(w):
				_px(img, int(round(p.x)) + dx, int(round(p.y)) + dy, c)


static func _ell(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (float(x) + 0.5 - cx) / rx
			var ny := (float(y) + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				_px(img, x, y, c)


## Boule ombrée : sombre en bas à droite, reflet en haut à gauche.
static func _ball(img: Image, cx: float, cy: float, r: float, ramp: Array) -> void:
	_ell(img, cx, cy, r, r, _c(ramp[0]))
	_ell(img, cx - r * 0.15, cy - r * 0.15, r * 0.8, r * 0.8, _c(ramp[1]))
	_ell(img, cx - r * 0.3, cy - r * 0.3, r * 0.5, r * 0.5, _c(ramp[2]))
	_px(img, int(cx - r * 0.45), int(cy - r * 0.45), _c(ramp[3]))


static func _gem(img: Image, cx: int, cy: int, g: Color, big: bool = false) -> void:
	if big:
		_ell(img, float(cx) + 0.5, float(cy) + 0.5, 2.2, 2.2, g.darkened(0.35))
		_ell(img, float(cx) + 0.2, float(cy) + 0.2, 1.4, 1.4, g)
		_px(img, cx - 1, cy - 1, g.lightened(0.6))
	else:
		_px(img, cx, cy, g)
		_px(img, cx + 1, cy, g.darkened(0.3))
		_px(img, cx, cy + 1, g.darkened(0.3))
		_px(img, cx + 1, cy + 1, g.darkened(0.45))
		_px(img, cx, cy, g.lightened(0.35))


static func _poly(img: Image, pts: PackedVector2Array, c: Color) -> void:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	for y in range(int(floor(r.position.y)), int(ceil(r.end.y)) + 1):
		for x in range(int(floor(r.position.x)), int(ceil(r.end.x)) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), pts):
				_px(img, x, y, c)


## Contour sombre de 1 px.
static func _outline(img: Image) -> void:
	var src := img.duplicate() as Image
	for y in range(S):
		for x in range(S):
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < S and q.y < S and src.get_pixel(q.x, q.y).a > 0.5:
					img.set_pixel(x, y, OUTLINE)
					break


## Hampe en diagonale (du bas à gauche vers le haut à droite), 2 px d'épaisseur, ombrée.
static func _shaft(img: Image, a: Vector2, b: Vector2, ramp: Array) -> void:
	_line(img, a, b, _c(ramp[0]), 2)
	_line(img, a, b, _c(ramp[1]))
	_line(img, a + Vector2(0, -1), b + Vector2(0, -1), _c(ramp[2]))


# ---------------------------------------------------------------- types d'objets

static func draw(img: Image, t: String, m: Array, c: Array, g: Color) -> void:
	match t:
		"baton":
			_shaft(img, Vector2(3, 21), Vector2(16, 8), m)
			_line(img, Vector2(15, 9), Vector2(17, 4), _c(m[1]), 2)
			_line(img, Vector2(17, 9), Vector2(21, 6), _c(m[1]), 2)
			_ball(img, 18.5, 6.5, 2.8, [g.darkened(0.45).to_html(false), g.darkened(0.15).to_html(false), g.to_html(false), g.lightened(0.6).to_html(false)])
			_rect(img, 9, 14, 2, 2, _c(c[2]))
			_px(img, 8, 16, _c(c[1]))
			_px(img, 11, 13, _c(c[1]))
		"baguette":
			_line(img, Vector2(4, 20), Vector2(17, 7), _c(m[1]), 2)
			_line(img, Vector2(4, 19), Vector2(17, 6), _c(m[2]))
			_line(img, Vector2(4, 20), Vector2(8, 16), _c(c[1]), 2)
			_line(img, Vector2(4, 19), Vector2(8, 15), _c(c[2]))
			_gem(img, 18, 5, g, true)
			for p in [Vector2i(21, 3), Vector2i(15, 2), Vector2i(22, 8)]:
				_px(img, p.x, p.y, g.lightened(0.5))
		"sceptre":
			_shaft(img, Vector2(5, 20), Vector2(13, 11), m)
			_rect(img, 4, 19, 3, 3, _c(m[2]))
			_ell(img, 16.0, 8.0, 5.0, 5.0, _c(m[0]))
			_ell(img, 15.6, 7.6, 4.0, 4.0, _c(m[2]))
			_ell(img, 16.0, 8.0, 2.6, 2.6, _c(m[0]))
			_gem(img, 15, 7, g, true)
			for p in [Vector2i(16, 2), Vector2i(21, 8), Vector2i(10, 7), Vector2i(16, 13)]:
				_px(img, p.x, p.y, _c(m[3]))
		"masse":
			_shaft(img, Vector2(4, 21), Vector2(12, 12), DYE["brown"] if c == DYE["white"] else c)
			_ball(img, 15.0, 9.0, 4.2, m)
			for p in [Vector2i(15, 3), Vector2i(21, 9), Vector2i(9, 8), Vector2i(19, 4), Vector2i(20, 14)]:
				_px(img, p.x, p.y, _c(m[2]))
				_px(img, p.x, p.y + 1, _c(m[1]))
			_gem(img, 14, 8, g)
		"arc":
			for i in range(19):
				var y := 3 + i
				var x := 6 + int(round(7.0 * sin(PI * float(i) / 18.0)))
				_px(img, x, y, _c(m[1]))
				_px(img, x + 1, y, _c(m[0]))
				_px(img, x - 1, y, _c(m[2]) if i % 3 != 0 else _c(m[1]))
			_line(img, Vector2(5, 3), Vector2(5, 21), Color("e8e0d0"))
			_rect(img, 11, 10, 3, 5, _c(c[1]))
			_rect(img, 11, 10, 1, 5, _c(c[2]))
			_gem(img, 6, 2, g)
			_gem(img, 6, 21, g)
			_line(img, Vector2(6, 12), Vector2(21, 12), _c("c8b890"))
			_px(img, 21, 11, _c("e8e0d0"))
			_px(img, 21, 13, _c("e8e0d0"))
			_px(img, 22, 12, _c("e8e0d0"))
		"arbalete":
			_shaft(img, Vector2(4, 20), Vector2(16, 8), c)
			_line(img, Vector2(9, 5), Vector2(20, 16), _c(m[1]), 2)
			_line(img, Vector2(9, 4), Vector2(20, 15), _c(m[2]))
			_line(img, Vector2(9, 5), Vector2(12, 15), Color("e8e0d0"))
			_line(img, Vector2(20, 16), Vector2(12, 15), Color("e8e0d0"))
			_line(img, Vector2(13, 11), Vector2(20, 4), _c("9a9aa8"))
			_px(img, 21, 3, _c("e0e6f2"))
			_gem(img, 14, 10, g)
		"epee":
			_poly(img, PackedVector2Array([Vector2(9, 13), Vector2(19, 3), Vector2(21, 3), Vector2(21, 5), Vector2(11, 15)]), _c(m[1]))
			_line(img, Vector2(10, 13), Vector2(19, 4), _c(m[3]))
			_line(img, Vector2(11, 15), Vector2(20, 5), _c(m[0]))
			_line(img, Vector2(6, 11), Vector2(12, 17), _c("c08a2a") if m != MAT["gold"] else _c(m[0]), 2)
			_line(img, Vector2(4, 19), Vector2(9, 14), _c(c[1]), 2)
			_line(img, Vector2(4, 18), Vector2(8, 14), _c(c[2]))
			_gem(img, 2, 20, g)
		"dague":
			_poly(img, PackedVector2Array([Vector2(11, 12), Vector2(17, 5), Vector2(19, 5), Vector2(13, 14)]), _c(m[1]))
			_line(img, Vector2(12, 12), Vector2(18, 5), _c(m[3]))
			_line(img, Vector2(8, 10), Vector2(13, 15), _c(c[1]), 2)
			_line(img, Vector2(6, 17), Vector2(10, 13), _c(c[0]), 2)
			_line(img, Vector2(6, 16), Vector2(9, 13), _c(c[2]))
			_gem(img, 4, 18, g)
		"faux":
			_shaft(img, Vector2(4, 22), Vector2(15, 3), DYE["black"] if c == DYE["black"] else MAT["darkwood"])
			for i in range(12):
				var u := float(i) / 11.0
				var x := 15.0 - 13.0 * u
				var y := 3.0 + 6.0 * sin(u * PI * 0.9) + 1.0 * u
				_px(img, int(x), int(y), _c(m[1]))
				_px(img, int(x), int(y) + 1, _c(m[0]))
				_px(img, int(x), int(y) - 1, _c(m[3]) if i % 2 == 0 else _c(m[2]))
			_gem(img, 14, 5, g)
		"hache":
			_shaft(img, Vector2(4, 21), Vector2(15, 6), MAT["wood"])
			_poly(img, PackedVector2Array([Vector2(13, 6), Vector2(19, 2), Vector2(22, 7), Vector2(21, 12), Vector2(16, 10)]), _c(m[1]))
			_line(img, Vector2(19, 2), Vector2(22, 7), _c(m[3]))
			_line(img, Vector2(22, 7), Vector2(21, 12), _c(m[3]))
			_line(img, Vector2(13, 6), Vector2(16, 10), _c(m[0]))
			_line(img, Vector2(8, 15), Vector2(10, 13), _c(c[2]), 2)
			_gem(img, 17, 6, g)
		"marteau":
			_shaft(img, Vector2(4, 21), Vector2(13, 11), MAT["wood"])
			_poly(img, PackedVector2Array([Vector2(10, 7), Vector2(16, 1), Vector2(22, 7), Vector2(16, 13)]), _c(m[1]))
			_line(img, Vector2(10, 7), Vector2(16, 1), _c(m[3]))
			_line(img, Vector2(16, 13), Vector2(22, 7), _c(m[0]))
			_line(img, Vector2(13, 7), Vector2(16, 4), _c(m[2]))
			_gem(img, 15, 7, g, true)
			_line(img, Vector2(6, 18), Vector2(8, 16), _c(c[2]), 2)
		"lance":
			_shaft(img, Vector2(2, 22), Vector2(16, 8), MAT["wood"])
			_poly(img, PackedVector2Array([Vector2(15, 8), Vector2(18, 3), Vector2(22, 2), Vector2(21, 6), Vector2(17, 10)]), _c(m[1]))
			_line(img, Vector2(17, 6), Vector2(21, 3), _c(m[3]))
			_line(img, Vector2(13, 11), Vector2(10, 9), _c(c[2]), 2)
			_line(img, Vector2(12, 12), Vector2(9, 12), _c(c[1]), 2)
			_gem(img, 15, 9, g)
		"orbe":
			_poly(img, PackedVector2Array([Vector2(6, 21), Vector2(18, 21), Vector2(16, 17), Vector2(8, 17)]), _c(m[1]))
			_line(img, Vector2(8, 17), Vector2(16, 17), _c(m[2]))
			_line(img, Vector2(7, 16), Vector2(5, 11), _c(m[1]), 2)
			_line(img, Vector2(17, 16), Vector2(19, 11), _c(m[1]), 2)
			_ball(img, 12.0, 10.0, 6.5, [g.darkened(0.5).to_html(false), g.darkened(0.2).to_html(false), g.to_html(false), g.lightened(0.7).to_html(false)])
			for p in [Vector2i(10, 7), Vector2i(14, 12), Vector2i(12, 9)]:
				_px(img, p.x, p.y, Color(1, 1, 1, 0.7))
		"bouclier":
			var face: Array = c if c != DYE["brown"] else m
			_poly(img, PackedVector2Array([Vector2(3, 3), Vector2(21, 3), Vector2(21, 11), Vector2(12, 22), Vector2(3, 11)]), _c(m[0]))
			_poly(img, PackedVector2Array([Vector2(5, 5), Vector2(19, 5), Vector2(19, 11), Vector2(12, 19), Vector2(5, 11)]), _c(face[1]))
			_poly(img, PackedVector2Array([Vector2(5, 5), Vector2(12, 5), Vector2(12, 19), Vector2(5, 11)]), _c(face[2]))
			_line(img, Vector2(3, 3), Vector2(21, 3), _c(m[2]))
			_ball(img, 12.0, 10.0, 2.6, m)
			_gem(img, 11, 9, g)
		"carquois":
			_poly(img, PackedVector2Array([Vector2(5, 17), Vector2(14, 6), Vector2(19, 10), Vector2(10, 21)]), _c(m[1]))
			_line(img, Vector2(5, 17), Vector2(14, 6), _c(m[2]))
			_line(img, Vector2(8, 14), Vector2(12, 18), _c(c[2]), 2)
			_line(img, Vector2(11, 10), Vector2(15, 14), _c(c[2]), 2)
			for k in range(3):
				var bx := 14 + k * 2
				_line(img, Vector2(bx, 7), Vector2(bx + 4, 2), _c("c8b890"))
				_px(img, bx + 4, 1, g)
				_px(img, bx + 5, 2, g.darkened(0.3))
		"tome":
			_rect(img, 4, 4, 15, 17, _c(c[0]))
			_rect(img, 5, 4, 13, 16, _c(c[1]))
			_rect(img, 5, 4, 3, 16, _c(c[0]))
			_rect(img, 18, 5, 2, 15, _c("eee8d8"))
			for y in range(6, 19, 2):
				_px(img, 19, y, _c("c8c0a8"))
			_rect(img, 9, 7, 7, 1, _c(m[2]))
			_rect(img, 9, 16, 7, 1, _c(m[2]))
			_gem(img, 12, 11, g, true)
			_rect(img, 17, 11, 3, 2, _c(m[2]))
		"lanterne":
			_ell(img, 12.0, 3.0, 3.0, 2.0, _c(m[1]))
			_ell(img, 12.0, 3.0, 1.5, 1.0, Color(0, 0, 0, 0))
			img.set_pixel(12, 3, Color(0, 0, 0, 0))
			_poly(img, PackedVector2Array([Vector2(7, 7), Vector2(17, 7), Vector2(15, 5), Vector2(9, 5)]), _c(m[1]))
			_rect(img, 7, 7, 11, 12, _c(m[0]))
			_rect(img, 8, 8, 9, 10, g)
			_rect(img, 9, 9, 3, 7, g.lightened(0.5))
			_rect(img, 12, 8, 1, 10, _c(m[1]))
			_rect(img, 6, 19, 13, 2, _c(m[1]))
			_rect(img, 6, 19, 13, 1, _c(m[2]))
		"miroir":
			_line(img, Vector2(5, 20), Vector2(10, 15), _c(m[1]), 2)
			_ell(img, 14.0, 10.0, 7.0, 7.0, _c(m[0]))
			_ell(img, 13.7, 9.7, 6.0, 6.0, _c(m[2]))
			_ell(img, 14.0, 10.0, 4.6, 4.6, g.darkened(0.2))
			_ell(img, 13.0, 9.0, 3.2, 3.2, g)
			_line(img, Vector2(11, 8), Vector2(13, 6), Color(1, 1, 1, 0.9))
		"capuche":
			_poly(img, PackedVector2Array([Vector2(3, 21), Vector2(5, 10), Vector2(9, 4), Vector2(12, 2), Vector2(16, 4), Vector2(19, 10), Vector2(21, 21)]), _c(c[1]))
			_poly(img, PackedVector2Array([Vector2(3, 21), Vector2(5, 10), Vector2(9, 4), Vector2(12, 2), Vector2(10, 9), Vector2(8, 21)]), _c(c[2]))
			_ell(img, 12.0, 14.0, 5.0, 6.0, _c(c[0]))
			_ell(img, 12.0, 15.0, 3.8, 4.8, _c("120e1a"))
			_line(img, Vector2(12, 2), Vector2(10, 9), _c(c[3]))
		"couronne":
			if m == MAT["wood"]:
				# Couronne de feuilles.
				for i in range(9):
					var a := PI + float(i) * PI / 8.0
					var lx := 12.0 + cos(a) * 8.0
					var ly := 13.0 + sin(a) * 6.0
					_ell(img, lx, ly, 2.2, 1.4, _c(c[1]))
					_px(img, int(lx), int(ly) - 1, _c(c[3]))
				_ell(img, 12.0, 16.0, 9.0, 3.0, _c(c[0]))
				_ell(img, 12.0, 15.5, 7.0, 2.0, Color(0, 0, 0, 0))
				_gem(img, 12, 7, g)
			else:
				_rect(img, 3, 12, 19, 6, _c(m[1]))
				_rect(img, 3, 12, 19, 1, _c(m[3]))
				_rect(img, 3, 17, 19, 1, _c(m[0]))
				for k in range(5):
					var tx := 4 + k * 4
					_poly(img, PackedVector2Array([Vector2(tx - 1, 12), Vector2(tx + 1, 5 + (2 if k % 2 == 1 else 0)), Vector2(tx + 3, 12)]), _c(m[2]))
					_px(img, tx + 1, 4 + (2 if k % 2 == 1 else 0), g)
				_gem(img, 11, 14, g, true)
				_gem(img, 5, 14, g)
				_gem(img, 18, 14, g)
		"heaume":
			_ell(img, 12.0, 11.0, 8.5, 8.0, _c(m[0]))
			_ell(img, 11.5, 10.5, 7.5, 7.0, _c(m[1]))
			_ell(img, 9.5, 8.0, 3.5, 3.0, _c(m[2]))
			_rect(img, 4, 11, 17, 9, _c(m[1]))
			_rect(img, 4, 19, 17, 2, _c(m[0]))
			_rect(img, 6, 13, 13, 2, _c("120e1a"))
			_rect(img, 11, 13, 2, 6, _c(m[2]))
			if c == DYE["fur"]:
				_poly(img, PackedVector2Array([Vector2(4, 9), Vector2(0, 5), Vector2(1, 1), Vector2(3, 6), Vector2(6, 8)]), _c("e8dcc0"))
				_poly(img, PackedVector2Array([Vector2(20, 9), Vector2(24, 5), Vector2(23, 1), Vector2(21, 6), Vector2(18, 8)]), _c("e8dcc0"))
			else:
				_line(img, Vector2(12, 3), Vector2(16, 0), _c(c[2]), 2)
				_line(img, Vector2(13, 3), Vector2(18, 1), _c(c[1]), 2)
			_gem(img, 11, 10, g)
		"masque":
			_poly(img, PackedVector2Array([Vector2(4, 4), Vector2(20, 4), Vector2(21, 12), Vector2(17, 20), Vector2(12, 22), Vector2(7, 20), Vector2(3, 12)]), _c(m[1]))
			_poly(img, PackedVector2Array([Vector2(4, 4), Vector2(12, 4), Vector2(12, 22), Vector2(7, 20), Vector2(3, 12)]), _c(m[2]))
			_ell(img, 8.0, 10.0, 2.5, 1.6, _c("120e1a"))
			_ell(img, 16.0, 10.0, 2.5, 1.6, _c("120e1a"))
			_line(img, Vector2(6, 14), Vector2(9, 17), _c(c[2]))
			_line(img, Vector2(18, 14), Vector2(15, 17), _c(c[2]))
			_rect(img, 10, 17, 4, 1, _c(m[0]))
			_gem(img, 11, 5, g)
		"nemes":
			_poly(img, PackedVector2Array([Vector2(2, 22), Vector2(4, 9), Vector2(7, 3), Vector2(12, 1), Vector2(17, 3), Vector2(20, 9), Vector2(22, 22), Vector2(17, 22), Vector2(16, 14), Vector2(8, 14), Vector2(7, 22)]), _c(m[1]))
			for y in range(3, 23, 3):
				for x in range(2, 23):
					if img.get_pixel(x, y).a > 0.5:
						_px(img, x, y, _c(c[2]))
			_ell(img, 12.0, 11.0, 4.5, 5.5, _c(m[2]) if m != MAT["crystal"] else g.lightened(0.3))
			_px(img, 10, 10, _c("120e1a"))
			_px(img, 14, 10, _c("120e1a"))
			_rect(img, 7, 5, 11, 1, _c(m[3]))
			_gem(img, 11, 3, g)
		"robe":
			_poly(img, PackedVector2Array([Vector2(8, 2), Vector2(16, 2), Vector2(22, 8), Vector2(20, 11), Vector2(17, 9), Vector2(19, 22), Vector2(5, 22), Vector2(7, 9), Vector2(4, 11), Vector2(2, 8)]), _c(c[1]))
			_poly(img, PackedVector2Array([Vector2(8, 2), Vector2(12, 2), Vector2(12, 22), Vector2(5, 22), Vector2(7, 9), Vector2(4, 11), Vector2(2, 8)]), _c(c[2]))
			_poly(img, PackedVector2Array([Vector2(9, 2), Vector2(15, 2), Vector2(12, 7)]), _c(c[0]))
			_rect(img, 7, 12, 11, 2, _c(m[1]))
			_rect(img, 11, 12, 2, 2, g)
			_line(img, Vector2(5, 22), Vector2(19, 22), g.darkened(0.2))
		"tunique":
			_poly(img, PackedVector2Array([Vector2(7, 3), Vector2(17, 3), Vector2(22, 8), Vector2(19, 11), Vector2(17, 9), Vector2(18, 19), Vector2(6, 19), Vector2(7, 9), Vector2(5, 11), Vector2(2, 8)]), _c(c[1]))
			_poly(img, PackedVector2Array([Vector2(7, 3), Vector2(12, 3), Vector2(12, 19), Vector2(6, 19), Vector2(7, 9), Vector2(5, 11), Vector2(2, 8)]), _c(c[2]))
			_poly(img, PackedVector2Array([Vector2(10, 3), Vector2(14, 3), Vector2(12, 7)]), _c(c[0]))
			_rect(img, 6, 13, 13, 2, _c(m[0]))
			_rect(img, 11, 13, 3, 2, _c(m[2]) if g == Color("4fe3d2") else g)
			_rect(img, 6, 19, 13, 2, _c(c[0]))
		"mailles":
			_poly(img, PackedVector2Array([Vector2(7, 3), Vector2(17, 3), Vector2(22, 9), Vector2(19, 12), Vector2(17, 10), Vector2(18, 21), Vector2(6, 21), Vector2(7, 10), Vector2(5, 12), Vector2(2, 9)]), _c(m[1]))
			for y in range(4, 22):
				for x in range(2, 23):
					if img.get_pixel(x, y).a > 0.5 and (x + y) % 2 == 0:
						_px(img, x, y, _c(m[2]) if x < 12 else _c(m[0]))
			_rect(img, 6, 13, 13, 2, _c(c[1]))
			_gem(img, 11, 13, g)
		"cuirasse":
			_poly(img, PackedVector2Array([Vector2(6, 4), Vector2(18, 4), Vector2(19, 12), Vector2(16, 20), Vector2(8, 20), Vector2(5, 12)]), _c(m[1]))
			_poly(img, PackedVector2Array([Vector2(6, 4), Vector2(12, 4), Vector2(12, 20), Vector2(8, 20), Vector2(5, 12)]), _c(m[2]))
			_ell(img, 4.0, 6.0, 3.5, 3.0, _c(m[1]))
			_ell(img, 20.0, 6.0, 3.5, 3.0, _c(m[0]))
			_line(img, Vector2(8, 11), Vector2(16, 11), _c(m[0]))
			_line(img, Vector2(7, 5), Vector2(11, 5), _c(m[3]))
			_rect(img, 8, 19, 8, 2, _c(c[1]))
			_gem(img, 11, 8, g, true)
		"manteau":
			var cl: Array = c if c != DYE["grey"] else m
			_poly(img, PackedVector2Array([Vector2(7, 5), Vector2(17, 5), Vector2(21, 15), Vector2(22, 22), Vector2(2, 22), Vector2(3, 15)]), _c(cl[1]))
			_poly(img, PackedVector2Array([Vector2(7, 5), Vector2(12, 5), Vector2(11, 22), Vector2(2, 22), Vector2(3, 15)]), _c(cl[2]))
			_poly(img, PackedVector2Array([Vector2(12, 8), Vector2(14, 22), Vector2(10, 22)]), _c("120e1a"))
			_line(img, Vector2(4, 21), Vector2(6, 12), _c(cl[3]))
			_ell(img, 12.0, 6.0, 8.0, 3.5, _c(m[1]))
			_ell(img, 11.5, 5.5, 7.0, 2.6, _c(m[2]))
			for x in range(5, 20, 2):
				_px(img, x, 3, _c(m[3]))
				_px(img, x + 1, 9, _c(m[0]))
			_gem(img, 11, 8, g if g != Color("4fe3d2") else Color("f2c46b"), true)
		"gants":
			_poly(img, PackedVector2Array([Vector2(4, 21), Vector2(4, 12), Vector2(5, 6), Vector2(7, 6), Vector2(8, 11), Vector2(9, 4), Vector2(11, 4), Vector2(12, 10), Vector2(13, 5), Vector2(15, 5), Vector2(15, 11), Vector2(17, 8), Vector2(19, 9), Vector2(16, 16), Vector2(14, 21)]), _c(m[1]))
			_poly(img, PackedVector2Array([Vector2(4, 21), Vector2(4, 12), Vector2(5, 6), Vector2(7, 6), Vector2(8, 11), Vector2(9, 4), Vector2(10, 4), Vector2(9, 21)]), _c(m[2]))
			_rect(img, 3, 18, 12, 4, _c(c[1]))
			_rect(img, 3, 18, 12, 1, _c(c[3]))
		"gantelets":
			_poly(img, PackedVector2Array([Vector2(4, 21), Vector2(4, 12), Vector2(5, 6), Vector2(7, 6), Vector2(8, 11), Vector2(9, 4), Vector2(11, 4), Vector2(12, 10), Vector2(13, 5), Vector2(15, 5), Vector2(15, 11), Vector2(17, 8), Vector2(19, 9), Vector2(16, 16), Vector2(14, 21)]), _c(m[1]))
			_poly(img, PackedVector2Array([Vector2(4, 21), Vector2(4, 12), Vector2(5, 6), Vector2(7, 6), Vector2(8, 11), Vector2(9, 4), Vector2(10, 4), Vector2(9, 21)]), _c(m[2]))
			for y in [8, 11]:
				_line(img, Vector2(4, y), Vector2(15, y), _c(m[0]))
			_line(img, Vector2(5, 5), Vector2(6, 5), _c(m[3]))
			_line(img, Vector2(9, 3), Vector2(10, 3), _c(m[3]))
			_poly(img, PackedVector2Array([Vector2(2, 15), Vector2(17, 15), Vector2(19, 22), Vector2(1, 22)]), _c(m[0]))
			_line(img, Vector2(2, 15), Vector2(17, 15), _c(m[3]))
			_line(img, Vector2(2, 18), Vector2(18, 18), _c(m[1]))
			_gem(img, 9, 19, g)
		"bandages":
			_poly(img, PackedVector2Array([Vector2(4, 21), Vector2(4, 12), Vector2(5, 6), Vector2(7, 6), Vector2(8, 11), Vector2(9, 4), Vector2(11, 4), Vector2(12, 10), Vector2(13, 5), Vector2(15, 5), Vector2(15, 11), Vector2(17, 8), Vector2(19, 9), Vector2(16, 16), Vector2(14, 21)]), _c("e8dcc0"))
			_poly(img, PackedVector2Array([Vector2(4, 21), Vector2(4, 12), Vector2(5, 6), Vector2(7, 6), Vector2(8, 11), Vector2(9, 4), Vector2(10, 4), Vector2(9, 21)]), _c("fff6e4"))
			for y in range(7, 22, 3):
				for x in range(3, 20):
					var yy := y - int(float(x - 3) * 0.35)
					if img.get_pixel(x, yy).a > 0.5:
						_px(img, x, yy, _c(c[1]))
			_rect(img, 3, 19, 12, 3, _c(c[0]))
			_line(img, Vector2(14, 20), Vector2(19, 23), _c(c[2]))
		"bottes":
			_poly(img, PackedVector2Array([Vector2(7, 2), Vector2(15, 2), Vector2(15, 14), Vector2(21, 17), Vector2(22, 21), Vector2(6, 21)]), _c(m[1]))
			_poly(img, PackedVector2Array([Vector2(7, 2), Vector2(10, 2), Vector2(10, 21), Vector2(6, 21)]), _c(m[2]))
			_rect(img, 6, 2, 10, 4, _c(c[1]))
			_rect(img, 6, 2, 10, 1, _c(c[3]))
			_rect(img, 6, 20, 17, 2, _c(m[0]))
			_gem(img, 13, 12, g)
		"sandales":
			for sx in [7.5, 16.5]:
				_ell(img, sx, 12.5, 4.2, 9.0, _c(m[0]))
				_ell(img, sx - 0.4, 12.0, 3.4, 8.2, _c(m[2]))
				_ell(img, sx, 14.0, 2.2, 5.0, _c(m[1]))
				var ix := int(sx)
				_line(img, Vector2(ix - 3, 7), Vector2(ix, 10), _c(c[1]), 2)
				_line(img, Vector2(ix + 3, 7), Vector2(ix, 10), _c(c[1]), 2)
				_line(img, Vector2(ix - 3, 15), Vector2(ix + 3, 15), _c(c[2]), 2)
				_px(img, ix, 10, g)
		"greves":
			_poly(img, PackedVector2Array([Vector2(7, 2), Vector2(16, 2), Vector2(16, 13), Vector2(21, 16), Vector2(22, 21), Vector2(6, 21)]), _c(m[1]))
			_poly(img, PackedVector2Array([Vector2(7, 2), Vector2(11, 2), Vector2(11, 21), Vector2(6, 21)]), _c(m[2]))
			for y in [6, 10, 14]:
				_line(img, Vector2(7, y), Vector2(16, y), _c(m[0]))
			_ell(img, 11.0, 12.0, 2.5, 2.0, _c(m[3]))
			_gem(img, 11, 11, g)
			_rect(img, 6, 20, 17, 2, _c(m[0]))
		"medaillon":
			_line(img, Vector2(4, 2), Vector2(12, 11), _c(m[2]))
			_line(img, Vector2(20, 2), Vector2(12, 11), _c(m[1]))
			_ell(img, 12.0, 15.0, 6.5, 6.5, _c(m[0]))
			_ell(img, 11.6, 14.6, 5.5, 5.5, _c(m[2]))
			_ell(img, 12.0, 15.0, 3.5, 3.5, _c(m[1]))
			_gem(img, 11, 14, g, true)
		"pendentif":
			_line(img, Vector2(4, 2), Vector2(12, 9), _c(m[2]))
			_line(img, Vector2(20, 2), Vector2(12, 9), _c(m[1]))
			_poly(img, PackedVector2Array([Vector2(12, 9), Vector2(17, 15), Vector2(12, 22), Vector2(7, 15)]), _c(m[1]))
			_poly(img, PackedVector2Array([Vector2(12, 9), Vector2(12, 22), Vector2(7, 15)]), _c(m[2]))
			_ell(img, 12.0, 15.0, 2.6, 3.4, g.darkened(0.25))
			_ell(img, 11.6, 14.4, 1.6, 2.2, g)
			_px(img, 11, 13, g.lightened(0.6))
		"anneau":
			_ell(img, 12.0, 14.0, 8.5, 7.0, _c(m[0]))
			_ell(img, 11.6, 13.6, 7.6, 6.2, _c(m[2]))
			_ell(img, 12.0, 14.5, 5.2, 4.2, Color(0, 0, 0, 0))
			for y in range(24):
				for x in range(24):
					var nx := (float(x) + 0.5 - 12.0) / 5.2
					var ny := (float(y) + 0.5 - 14.5) / 4.2
					if nx * nx + ny * ny <= 1.0:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
			_line(img, Vector2(6, 18), Vector2(10, 20), _c(m[1]))
			_ell(img, 12.0, 6.0, 3.6, 3.0, _c(m[1]))
			_gem(img, 11, 5, g, true)
		"chevaliere":
			_ell(img, 12.0, 15.0, 8.0, 6.5, _c(m[0]))
			_ell(img, 11.6, 14.6, 7.2, 5.8, _c(m[2]))
			for y in range(24):
				for x in range(24):
					var nx := (float(x) + 0.5 - 12.0) / 4.8
					var ny := (float(y) + 0.5 - 15.5) / 3.8
					if nx * nx + ny * ny <= 1.0:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
			_rect(img, 7, 3, 10, 7, _c(m[1]))
			_rect(img, 7, 3, 10, 1, _c(m[3]))
			_rect(img, 9, 5, 6, 3, g.darkened(0.3))
			_px(img, 11, 6, g.lightened(0.4))
			_px(img, 12, 5, g)
		"fiole":
			_rect(img, 10, 2, 4, 3, _c("8a5a2b"))
			_rect(img, 10, 5, 4, 3, _c("bfe6f0"))
			_ell(img, 12.0, 15.0, 7.0, 7.0, _c("bfe6f0"))
			_ell(img, 12.0, 16.0, 6.0, 5.5, g.darkened(0.15))
			_ell(img, 12.0, 12.5, 6.0, 1.2, g.lightened(0.3))
			_line(img, Vector2(8, 11), Vector2(7, 16), Color(1, 1, 1, 0.8))
			_line(img, Vector2(14, 4), Vector2(19, 9), _c(c[2]))
			for p in [Vector2i(10, 16), Vector2i(13, 18), Vector2i(15, 15)]:
				_px(img, p.x, p.y, g.lightened(0.5))
		"plume":
			for i in range(18):
				var u := float(i) / 17.0
				var cx := 5.0 + 13.0 * u
				var cy := 21.0 - 18.0 * u
				var half := 3.6 * sin(u * PI) + 0.4
				for k in range(-int(half), int(half) + 1):
					_px(img, int(cx) + k, int(cy) - k / 2, _c(c[2]) if k < 0 else _c(c[1]))
			_line(img, Vector2(4, 22), Vector2(18, 3), _c(c[3]))
			_line(img, Vector2(4, 22), Vector2(7, 18), _c("8a7a5a"))
			_px(img, 12, 12, g)
		"croc":
			_line(img, Vector2(4, 3), Vector2(12, 8), _c(c[1]))
			_line(img, Vector2(20, 3), Vector2(12, 8), _c(c[2]))
			_poly(img, PackedVector2Array([Vector2(8, 8), Vector2(16, 8), Vector2(15, 13), Vector2(12, 22), Vector2(10, 14)]), _c(m[1]))
			_poly(img, PackedVector2Array([Vector2(8, 8), Vector2(12, 8), Vector2(12, 22), Vector2(10, 14)]), _c(m[2]))
			_line(img, Vector2(13, 9), Vector2(14, 13), _c(m[0]))
			_rect(img, 9, 8, 6, 2, _c(c[1]))
			_gem(img, 11, 8, g)
		"cristal":
			_poly(img, PackedVector2Array([Vector2(12, 1), Vector2(16, 7), Vector2(15, 20), Vector2(9, 20), Vector2(8, 7)]), _c(m[1]))
			_poly(img, PackedVector2Array([Vector2(12, 1), Vector2(12, 20), Vector2(9, 20), Vector2(8, 7)]), _c(m[2]))
			_poly(img, PackedVector2Array([Vector2(6, 9), Vector2(8, 13), Vector2(7, 21), Vector2(4, 21), Vector2(3, 13)]), _c(m[0]))
			_poly(img, PackedVector2Array([Vector2(18, 10), Vector2(21, 14), Vector2(20, 21), Vector2(16, 21), Vector2(16, 14)]), _c(m[1]))
			_line(img, Vector2(11, 3), Vector2(10, 16), _c(m[3]))
			_rect(img, 3, 21, 19, 1, _c("5a6478"))
			_px(img, 12, 9, g.lightened(0.5))
		"sablier":
			_rect(img, 5, 2, 14, 2, _c(m[1]))
			_rect(img, 5, 20, 14, 2, _c(m[1]))
			_rect(img, 5, 2, 14, 1, _c(m[3]))
			_line(img, Vector2(6, 4), Vector2(6, 19), _c(m[0]))
			_line(img, Vector2(17, 4), Vector2(17, 19), _c(m[0]))
			_poly(img, PackedVector2Array([Vector2(8, 4), Vector2(16, 4), Vector2(12, 11), Vector2(12, 12), Vector2(16, 19), Vector2(8, 19), Vector2(12, 12), Vector2(12, 11)]), _c("cfe8f0"))
			_poly(img, PackedVector2Array([Vector2(9, 6), Vector2(15, 6), Vector2(12, 10)]), g)
			_poly(img, PackedVector2Array([Vector2(12, 14), Vector2(15, 19), Vector2(9, 19)]), g.darkened(0.15))
			_px(img, 12, 12, g)
		"enclume":
			_poly(img, PackedVector2Array([Vector2(2, 7), Vector2(18, 7), Vector2(22, 9), Vector2(16, 11), Vector2(14, 14), Vector2(16, 19), Vector2(6, 19), Vector2(8, 14), Vector2(6, 11)]), _c(m[1]))
			_line(img, Vector2(2, 7), Vector2(18, 7), _c(m[3]))
			_rect(img, 4, 19, 15, 3, _c(m[0]))
			_ball(img, 11.0, 10.0, 2.4, [g.darkened(0.4).to_html(false), g.to_html(false), g.lightened(0.3).to_html(false), "ffffff"])
		"rapiere":
			_line(img, Vector2(10, 13), Vector2(21, 2), _c(m[1]))
			_line(img, Vector2(10, 12), Vector2(20, 2), _c(m[3]))
			_line(img, Vector2(11, 14), Vector2(21, 3), _c(m[0]))
			# Garde en coquille et branche.
			_ell(img, 9.0, 14.0, 3.2, 2.6, _c(m[1]))
			_ell(img, 8.6, 13.6, 2.2, 1.6, _c(m[3]))
			for i in range(7):
				var a := PI * 0.2 + float(i) * PI / 7.0
				_px(img, 8 + int(cos(a) * 4.5), 15 + int(sin(a) * 4.5), _c(m[2]))
			_line(img, Vector2(4, 20), Vector2(8, 16), _c(c[1]), 2)
			_line(img, Vector2(4, 19), Vector2(7, 16), _c(c[2]))
			_gem(img, 2, 21, g)
		"fleau":
			_shaft(img, Vector2(3, 21), Vector2(10, 14), MAT["wood"] if c != DYE["teal"] else c)
			_rect(img, 9, 13, 3, 3, _c(m[2]))
			for i in range(5):
				var p := Vector2(11, 12).lerp(Vector2(15, 7), float(i) / 4.0)
				_px(img, int(p.x), int(p.y), _c(m[2]) if i % 2 == 0 else _c(m[0]))
			_ball(img, 17.0, 6.0, 3.6, m)
			for q in [Vector2i(17, 1), Vector2i(22, 6), Vector2i(17, 11), Vector2i(12, 5), Vector2i(20, 2), Vector2i(21, 10)]:
				_px(img, q.x, q.y, _c(m[3]))
			_gem(img, 16, 5, g)
		"glaive":
			_shaft(img, Vector2(2, 22), Vector2(14, 10), MAT["wood"])
			_poly(img, PackedVector2Array([Vector2(13, 11), Vector2(16, 4), Vector2(21, 1), Vector2(22, 4), Vector2(19, 10), Vector2(15, 13)]), _c(m[1]))
			_line(img, Vector2(16, 4), Vector2(21, 1), _c(m[3]))
			_line(img, Vector2(22, 4), Vector2(19, 10), _c(m[2]))
			_line(img, Vector2(15, 13), Vector2(13, 11), _c(m[0]))
			_px(img, 20, 8, _c(m[0]))
			_line(img, Vector2(11, 13), Vector2(9, 11), _c(c[2]), 2)
			_gem(img, 15, 9, g)
		"cimeterre":
			for i in range(15):
				var u := float(i) / 14.0
				var x := 9.0 + 12.0 * u
				var y := 14.0 - 12.0 * u + 4.0 * sin(u * PI)
				_px(img, int(x), int(y), _c(m[1]))
				_px(img, int(x), int(y) + 1, _c(m[0]))
				_px(img, int(x) - 1, int(y) - 1, _c(m[3]) if i % 2 == 0 else _c(m[2]))
				if u > 0.6:
					_px(img, int(x) + 1, int(y) + 1, _c(m[1]))
			_line(img, Vector2(7, 12), Vector2(11, 16), _c("c08a2a"), 2)
			_line(img, Vector2(4, 19), Vector2(8, 15), _c(c[1]), 2)
			_line(img, Vector2(4, 18), Vector2(7, 15), _c(c[2]))
			_gem(img, 2, 20, g)
		"cor":
			for i in range(16):
				var u := float(i) / 15.0
				var x := 4.0 + 15.0 * u
				var y := 16.0 - 9.0 * u * u
				var r := 1.0 + 3.0 * u
				_ell(img, x, y, 1.2, r, _c(m[1]))
				_px(img, int(x), int(y - r + 1.0), _c(m[3]))
			_ell(img, 19.5, 7.0, 2.0, 4.0, _c(m[0]))
			_ell(img, 19.8, 7.0, 1.2, 3.0, _c("2a1a10"))
			_rect(img, 8, 13, 2, 4, _c(c[1]))
			_rect(img, 13, 10, 2, 5, _c(c[1]))
			_line(img, Vector2(9, 17), Vector2(14, 15), _c(c[2]))
			_px(img, 4, 16, g)
		"crane":
			_ell(img, 12.0, 10.0, 8.0, 7.5, _c(m[1]))
			_ell(img, 10.5, 8.5, 5.5, 5.0, _c(m[2]))
			_ell(img, 9.0, 6.5, 2.0, 1.5, _c(m[3]))
			_rect(img, 7, 15, 10, 5, _c(m[1]))
			_rect(img, 7, 15, 5, 5, _c(m[2]))
			_ell(img, 8.5, 11.0, 2.4, 2.4, _c("120e1a"))
			_ell(img, 15.5, 11.0, 2.4, 2.4, _c("120e1a"))
			_px(img, 8, 11, g)
			_px(img, 15, 11, g)
			_poly(img, PackedVector2Array([Vector2(11, 15), Vector2(13, 15), Vector2(12, 13)]), _c("120e1a"))
			for x in [8, 10, 12, 14, 16]:
				_px(img, x, 19, _c("120e1a"))
			_line(img, Vector2(7, 21), Vector2(17, 21), _c(m[0]))
		"chapeau":
			_ell(img, 12.0, 19.0, 11.0, 3.2, _c(c[0]))
			_ell(img, 11.5, 18.5, 10.0, 2.4, _c(c[1]))
			_poly(img, PackedVector2Array([Vector2(6, 18), Vector2(10, 9), Vector2(13, 4), Vector2(18, 1), Vector2(16, 6), Vector2(17, 18)]), _c(c[1]))
			_poly(img, PackedVector2Array([Vector2(6, 18), Vector2(10, 9), Vector2(13, 4), Vector2(11, 18)]), _c(c[2]))
			_rect(img, 7, 15, 10, 2, _c(m[1]))
			_gem(img, 11, 15, g)
			_px(img, 18, 1, g.lightened(0.4))
		"bandeau":
			_ell(img, 12.0, 11.0, 9.5, 6.5, _c(c[1]))
			_ell(img, 11.0, 10.0, 7.0, 4.5, _c(c[2]))
			_ell(img, 12.0, 11.5, 6.5, 3.6, Color(0, 0, 0, 0))
			for y in range(24):
				for x in range(24):
					var nx := (float(x) + 0.5 - 12.0) / 6.5
					var ny := (float(y) + 0.5 - 11.5) / 3.6
					if nx * nx + ny * ny <= 1.0:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
			_poly(img, PackedVector2Array([Vector2(18, 14), Vector2(22, 20), Vector2(19, 21), Vector2(17, 16)]), _c(c[1]))
			_poly(img, PackedVector2Array([Vector2(19, 14), Vector2(23, 17), Vector2(21, 19), Vector2(18, 16)]), _c(c[2]))
			_gem(img, 11, 5, g, true)
		"brigandine":
			_poly(img, PackedVector2Array([Vector2(7, 3), Vector2(17, 3), Vector2(22, 8), Vector2(19, 11), Vector2(17, 9), Vector2(18, 21), Vector2(6, 21), Vector2(7, 9), Vector2(5, 11), Vector2(2, 8)]), _c(c[1]))
			_poly(img, PackedVector2Array([Vector2(7, 3), Vector2(12, 3), Vector2(12, 21), Vector2(6, 21), Vector2(7, 9), Vector2(5, 11), Vector2(2, 8)]), _c(c[2]))
			_poly(img, PackedVector2Array([Vector2(10, 3), Vector2(14, 3), Vector2(12, 7)]), _c(c[0]))
			for y in range(9, 20, 3):
				for x in range(7, 18, 3):
					_px(img, x, y, _c(m[3]))
					_px(img, x + 1, y + 1, _c(m[0]))
			_rect(img, 6, 15, 13, 2, _c(m[1]))
			_gem(img, 11, 15, g)
		"brassards":
			# Deux brassards : tubes évasés vus de trois quarts, ouverture sombre, sangles.
			for k in range(2):
				var ox := 6.0 + float(k) * 10.0
				var strap: Color = _c(c[1]) if c != DYE["brown"] else _c(m[0])
				_poly(img, PackedVector2Array([Vector2(ox - 4.5, 5), Vector2(ox + 4.5, 5), Vector2(ox + 3.0, 21), Vector2(ox - 3.0, 21)]), _c(m[1]))
				_poly(img, PackedVector2Array([Vector2(ox - 4.5, 5), Vector2(ox - 1.0, 5), Vector2(ox - 1.5, 21), Vector2(ox - 3.0, 21)]), _c(m[2]))
				_ell(img, ox, 5.0, 4.5, 1.8, _c(m[3]))
				_ell(img, ox, 5.2, 3.2, 1.0, _c("120e1a"))
				_ell(img, ox, 21.0, 3.0, 1.2, _c(m[0]))
				for y in [10, 16]:
					_line(img, Vector2(ox - 4.0, y), Vector2(ox + 4.0, y), strap)
				_gem(img, int(ox) - 1, 12, g)
		"collier":
			for i in range(13):
				var a := PI * 0.05 + float(i) * PI * 0.9 / 12.0
				var x := 12.0 + cos(a) * 9.0
				var y := 6.0 + sin(a) * 9.0
				_px(img, int(x), int(y), _c(c[1]))
			for k in range(5):
				var a := PI * 0.3 + float(k) * PI * 0.4 / 4.0
				var bx := 12.0 + cos(a) * 9.0
				var by := 6.0 + sin(a) * 9.0
				_poly(img, PackedVector2Array([Vector2(bx - 1.5, by), Vector2(bx + 1.5, by), Vector2(bx, by + 5.0)]), _c(m[2]))
				_px(img, int(bx) - 1, int(by), _c(m[3]))
			_gem(img, 11, 15, g)
		"talisman":
			_line(img, Vector2(6, 1), Vector2(12, 6), _c(m[2]))
			_line(img, Vector2(18, 1), Vector2(12, 6), _c(m[1]))
			_ell(img, 12.0, 14.0, 8.0, 8.0, _c(m[0]))
			_ell(img, 11.6, 13.6, 7.0, 7.0, _c(m[2]))
			_ell(img, 12.0, 14.0, 5.0, 5.0, _c(m[1]))
			for i in range(8):
				var a := float(i) * TAU / 8.0
				_px(img, 12 + int(round(cos(a) * 6.0)), 14 + int(round(sin(a) * 6.0)), _c(m[3]))
			_poly(img, PackedVector2Array([Vector2(12, 10), Vector2(15, 14), Vector2(12, 18), Vector2(9, 14)]), g)
			_px(img, 11, 12, g.lightened(0.5))
		"totem":
			_rect(img, 8, 3, 8, 18, _c(m[1]))
			_rect(img, 8, 3, 3, 18, _c(m[2]))
			_poly(img, PackedVector2Array([Vector2(4, 4), Vector2(8, 6), Vector2(8, 9), Vector2(3, 7)]), _c(c[1]))
			_poly(img, PackedVector2Array([Vector2(20, 4), Vector2(16, 6), Vector2(16, 9), Vector2(21, 7)]), _c(c[1]))
			_ell(img, 10.0, 7.0, 1.4, 1.4, g)
			_ell(img, 14.0, 7.0, 1.4, 1.4, g)
			_poly(img, PackedVector2Array([Vector2(11, 9), Vector2(13, 9), Vector2(12, 12)]), _c("c08a2a"))
			_rect(img, 8, 14, 8, 1, _c(m[0]))
			_rect(img, 10, 16, 4, 2, _c(c[2]))
			_rect(img, 7, 20, 10, 2, _c(m[0]))
		"de":
			_poly(img, PackedVector2Array([Vector2(4, 8), Vector2(12, 4), Vector2(20, 8), Vector2(12, 12)]), _c(m[3]))
			_poly(img, PackedVector2Array([Vector2(4, 8), Vector2(12, 12), Vector2(12, 21), Vector2(4, 17)]), _c(m[2]))
			_poly(img, PackedVector2Array([Vector2(12, 12), Vector2(20, 8), Vector2(20, 17), Vector2(12, 21)]), _c(m[1]))
			_px(img, 12, 8, _c(c[1]))
			for q in [Vector2i(6, 11), Vector2i(9, 15), Vector2i(7, 17)]:
				_px(img, q.x, q.y, _c(c[1]))
			for q in [Vector2i(15, 12), Vector2i(17, 14), Vector2i(15, 16), Vector2i(17, 18)]:
				_px(img, q.x, q.y, _c(c[0]))
			_gem(img, 11, 7, g)
		"cloche":
			_rect(img, 11, 1, 2, 3, _c(m[0]))
			_poly(img, PackedVector2Array([Vector2(8, 5), Vector2(16, 5), Vector2(18, 15), Vector2(21, 18), Vector2(3, 18), Vector2(6, 15)]), _c(m[1]))
			_poly(img, PackedVector2Array([Vector2(8, 5), Vector2(12, 5), Vector2(11, 18), Vector2(3, 18), Vector2(6, 15)]), _c(m[2]))
			_line(img, Vector2(9, 6), Vector2(8, 14), _c(m[3]))
			_rect(img, 3, 17, 18, 2, _c(m[0]))
			_ball(img, 12.0, 20.5, 2.0, [g.darkened(0.4).to_html(false), g.to_html(false), g.lightened(0.3).to_html(false), "ffffff"])
			_line(img, Vector2(13, 2), Vector2(19, 1), _c(c[2]))
		"oeil":
			_ell(img, 12.0, 12.0, 10.0, 6.5, _c(m[1]))
			_ell(img, 12.0, 12.0, 9.0, 5.5, _c("f0f0f8"))
			_ell(img, 12.0, 12.0, 4.5, 4.5, g.darkened(0.3))
			_ell(img, 12.0, 12.0, 3.2, 3.2, g)
			_ell(img, 12.0, 12.0, 1.5, 2.6, _c("120e1a"))
			_px(img, 10, 10, Color.WHITE)
			_px(img, 11, 10, Color.WHITE)
			for x in range(4, 21, 3):
				_px(img, x, 5 + int(absf(float(x) - 12.0) / 3.0), _c(c[1]))
			_line(img, Vector2(12, 18), Vector2(12, 22), _c(c[1]))
			_px(img, 12, 22, g)
		_:
			_ball(img, 12.0, 12.0, 7.0, m)


# ---------------------------------------------------------------- glyphes des runes

static func _glyph(img: Image, family: String, col: Color) -> void:
	var lines: Array = []
	match family:
		"kaor":
			lines = [[9, 5, 9, 16], [9, 10, 15, 5], [9, 10, 15, 16]]
		"vigr":
			lines = [[8, 6, 12, 16], [12, 16, 16, 6], [10, 11, 14, 11]]
		"ilm":
			lines = [[12, 5, 12, 16], [9, 7, 15, 7], [9, 14, 15, 14]]
		"sael":
			lines = [[8, 6, 15, 9], [15, 9, 8, 12], [8, 12, 15, 15]]
		"wyrd":
			lines = [[8, 5, 12, 10], [16, 5, 12, 10], [12, 10, 12, 16], [9, 16, 15, 16]]
		"pyr":
			lines = [[12, 5, 8, 15], [12, 5, 16, 15], [10, 11, 14, 11], [12, 11, 12, 15]]
		"isa":
			lines = [[12, 5, 12, 16], [8, 8, 16, 13], [16, 8, 8, 13]]
		"thun":
			lines = [[14, 5, 10, 10], [10, 10, 14, 11], [14, 11, 10, 16]]
		"ver":
			lines = [[12, 16, 12, 9], [12, 9, 8, 5], [12, 9, 16, 5], [12, 12, 9, 10]]
		"lux":
			lines = [[12, 5, 12, 16], [7, 10, 17, 10], [9, 7, 15, 13], [15, 7, 9, 13]]
		"nox":
			lines = [[9, 6, 15, 6], [15, 6, 9, 15], [9, 15, 15, 15]]
		"ark":
			lines = [[8, 15, 12, 5], [12, 5, 16, 15], [8, 15, 16, 15], [12, 9, 12, 12]]
		"ferr":
			lines = [[9, 5, 9, 16], [9, 5, 15, 8], [9, 10, 14, 12]]
		"mor":
			lines = [[8, 16, 8, 6], [8, 6, 12, 11], [12, 11, 16, 6], [16, 6, 16, 16]]
		"gard":
			lines = [[8, 6, 16, 6], [8, 6, 8, 12], [16, 6, 16, 12], [8, 12, 12, 16], [16, 12, 12, 16]]
		"mult":
			lines = [[8, 6, 16, 15], [16, 6, 8, 15], [12, 5, 12, 16]]
		_:
			lines = [[12, 5, 12, 16]]
	for l in lines:
		_line(img, Vector2(l[0], l[1]), Vector2(l[2], l[3]), col)
	for l in lines:
		_px(img, int(l[0]), int(l[1]), col.lightened(0.45))
