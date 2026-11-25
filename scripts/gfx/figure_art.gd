class_name FigureArt
extends RefCounted
## Personnages en pied des cinématiques (docs/design/41-cinematiques.md) : créatures et esprits qui se tiennent
## dans le décor au lieu de flotter. Le haut du corps est leur portrait (PortraitArt, avec sa bouche et ses
## expressions) ; le reste du corps est dessiné ici, dans le même style (rampes de couleur, contour, reflet).
## Zone 1 : le Grand Cerf, la Sylvarche, la fée, Morvaen, la Voix, la Lanterne de l'Aube.


## id -> [largeur, hauteur, x du portrait, y du portrait, part de la hauteur de scène, en vol]
const SPEC := {
	"cerf": [96, 150, 16, 0, 0.92, false],
	"sylvarche": [128, 168, 32, 0, 1.08, false],
	"fee": [64, 104, 0, 0, 0.42, true],
	"morvaen": [80, 152, 8, 0, 0.86, false],
	"voix": [80, 152, 8, 0, 0.86, false],
	"lanterne": [40, 104, -1, 0, 0.42, false],
}

static var _cache: Dictionary = {}


static func has(id: String) -> bool:
	return SPEC.has(id)


## Part de la hauteur de scène qu'occupe le personnage.
static func height_share(id: String) -> float:
	return float(SPEC[id][4]) if SPEC.has(id) else 0.8


static func flies(id: String) -> bool:
	return bool(SPEC[id][5]) if SPEC.has(id) else false


## Où est la tête (centre, en pixels de l'image) : les effets « @subject » visent là.
static func head_center(id: String) -> Vector2:
	if id == "lanterne":
		return Vector2(20, 30)
	var sp: Array = SPEC.get(id, [64, 64, 0, 0])
	return Vector2(float(sp[2]) + 32.0, float(sp[3]) + 32.0)


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
			_cerf_body(img, mood)
		"sylvarche":
			_sylvarche_body(img, mood)
		"fee":
			_fee_body(img, mood)
		"morvaen":
			_robe_body(img, PortraitArt._ramp(["14204a", "1f5a66", "2f8f9a", "4fb8c0"]), true)
		"voix":
			_robe_body(img, PortraitArt._ramp(["07060f", "120e1a", "1a1035", "2a1e4a"]), false)
		"lanterne":
			_lantern(img)
	if int(sp[2]) >= 0:
		# Le haut du corps : le portrait, avec sa bouche et ses yeux.
		var head := PortraitArt.frame(id if id != "morvaen" else "morvaen", mood, talk, blink)
		if head != null:
			var hi := head.get_image()
			hi.convert(Image.FORMAT_RGBA8)
			img.blend_rect(hi, Rect2i(0, 0, 64, 64), Vector2i(int(sp[2]), int(sp[3])))
	if id == "voix":
		# La Voix n'a pas de pieds : son ombre se dissout vers le sol.
		for y in range(100, img.get_height()):
			var k := 1.0 - float(y - 100) / float(img.get_height() - 100)
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


# ---------------------------------------------------------------- corps

## Le Grand Cerf, de face : poitrail, ventre, quatre pattes fines et sabots.
static func _cerf_body(img: Image, mood: String) -> void:
	var fur := PortraitArt._ramp(["3a2e3a", "5a4a5a", "8a7a8a", "b0a0b0"])
	var dark := PortraitArt._ramp(["241c26", "3a2e3a", "5a4a5a"])
	var hoof := PortraitArt._ramp(["120e1a", "2a2038"])
	var o := 16.0
	# Pattes arrière, derrière, plus sombres.
	for s: float in [-1.0, 1.0]:
		var x := 48.0 + s * 30.0
		PortraitArt._poly(img, PackedVector2Array([Vector2(x - 3, 92), Vector2(x + 3, 92), Vector2(x + 2, 120), Vector2(x + 3, 140), Vector2(x - 2, 140), Vector2(x - 3, 120)]), dark)
		PortraitArt._poly(img, PackedVector2Array([Vector2(x - 3, 140), Vector2(x + 3, 140), Vector2(x + 4, 145), Vector2(x - 4, 145)]), hoof, 0.0, true)
	# Corps vu de face : il s'élargit sous le poitrail.
	PortraitArt._poly(img, PackedVector2Array([Vector2(o + 12, 60), Vector2(o + 52, 60), Vector2(o + 60, 80), Vector2(o + 56, 100), Vector2(o + 8, 100), Vector2(o + 4, 80)]), fur)
	PortraitArt._ellipse(img, o + 32.0, 66.0, 7.0, 8.0, PortraitArt._ramp(["8a7a8a", "b0a0b0", "d8ccd8"]))
	# Pattes avant, avec le genou et le sabot.
	for s: float in [-1.0, 1.0]:
		var x := 48.0 + s * 11.0
		PortraitArt._poly(img, PackedVector2Array([Vector2(x - 4, 96), Vector2(x + 4, 96), Vector2(x + 3, 118), Vector2(x + 4, 122), Vector2(x + 2, 142), Vector2(x - 2, 142), Vector2(x - 3, 122), Vector2(x - 4, 118)]), fur)
		PortraitArt._poly(img, PackedVector2Array([Vector2(x - 3, 141), Vector2(x + 3, 141), Vector2(x + 4, 148), Vector2(x - 4, 148)]), hoof, 0.0, true)
	if mood == "colere":
		# Corrompu : traînées violettes sur le pelage.
		for path in [[Vector2(30, 70), Vector2(34, 84), Vector2(30, 98)], [Vector2(66, 72), Vector2(62, 86), Vector2(66, 99)]]:
			for i in range(path.size() - 1):
				PortraitArt._line(img, path[i], path[i + 1], Color("b07cff"))
	PortraitArt._rim(img, 0, 95, 60, 149, Color("cfe6ff"))


## La Sylvarche entière : grande couronne de feuilles, tronc noueux, racines qui s'étalent.
static func _sylvarche_body(img: Image, mood: String) -> void:
	var pure := mood == "joie"
	var leaves := PortraitArt._ramp(["22301a", "3f5a30", "4f6b3a", "7faa4a"]) if pure else PortraitArt._ramp(["1a1035", "3b2a6b", "5a2a7a", "8e62e0"])
	var bark := PortraitArt._ramp(["2a1e1a", "3a2e2a", "5a4030", "7a5a40"])
	var crack := Color("f2c46b") if pure else Color("b07cff")
	# Couronne derrière le visage.
	PortraitArt._ellipse(img, 26.0, 22.0, 24.0, 16.0, leaves)
	PortraitArt._ellipse(img, 102.0, 22.0, 24.0, 16.0, leaves)
	PortraitArt._ellipse(img, 64.0, 12.0, 34.0, 12.0, leaves)
	# Tronc et racines.
	var o := 32.0
	PortraitArt._poly(img, PackedVector2Array([Vector2(o + 10, 60), Vector2(o + 54, 60), Vector2(o + 56, 110), Vector2(o + 62, 134), Vector2(o + 2, 134), Vector2(o + 8, 110)]), bark)
	for r in [[Vector2(o + 8, 126), Vector2(2, 164), Vector2(18, 166)], [Vector2(o + 20, 130), Vector2(28, 166), Vector2(44, 166)],
			[Vector2(o + 44, 130), Vector2(100, 166), Vector2(84, 166)], [Vector2(o + 56, 126), Vector2(126, 164), Vector2(110, 166)],
			[Vector2(o + 30, 132), Vector2(58, 167), Vector2(70, 167)]]:
		var a: Vector2 = r[0]
		PortraitArt._poly(img, PackedVector2Array([a + Vector2(-5, 0), a + Vector2(5, 0), r[2], r[1]]), bark)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in range(22):
		var x := rng.randi_range(int(o) + 12, int(o) + 52)
		var y0 := rng.randi_range(62, 120)
		for y in range(y0, mini(134, y0 + rng.randi_range(5, 14))):
			if img.get_pixel(x, y).a > 0.5:
				PortraitArt._px(img, x, y, bark[0])
	for path in [[Vector2(o + 22, 64), Vector2(o + 26, 88), Vector2(o + 20, 112)], [Vector2(o + 44, 66), Vector2(o + 40, 92), Vector2(o + 46, 120)]]:
		for i in range(path.size() - 1):
			PortraitArt._line(img, path[i], path[i + 1], crack)
	PortraitArt._rim(img, 0, 127, 0, 167, Color("cfc8ff"))


## La fée en entier : robe en corolle, jambes fines ; elle vole.
static func _fee_body(img: Image, _mood: String) -> void:
	var dress := PortraitArt._ramp(["8a4a7a", "c87ab0", "f7a8e0", "ffd8f4"])
	var skin := PortraitArt._ramp(["b89ac8", "e0c8f0", "f8ecff"])
	PortraitArt._poly(img, PackedVector2Array([Vector2(16, 60), Vector2(48, 60), Vector2(56, 78), Vector2(46, 84), Vector2(32, 80), Vector2(18, 84), Vector2(8, 78)]), dress)
	for s: float in [-1.0, 1.0]:
		var x := 32.0 + s * 5.0
		PortraitArt._line(img, Vector2(x, 82), Vector2(x + s * 2.0, 98), skin[1], 2)
		PortraitArt._px(img, int(x + s * 2.0), 99, skin[0])


## Longue robe qui tombe jusqu'au sol (Morvaen, avec son bâton ; la Voix, en ombre).
static func _robe_body(img: Image, robe: Array[Color], staff: bool) -> void:
	var o := 8.0
	if staff:
		PortraitArt._line(img, Vector2(o + 62, 18), Vector2(o + 64, 150), Color("5a4030"), 2)
		PortraitArt._ellipse(img, o + 62.0, 16.0, 4.0, 4.0, PortraitArt._ramp(["2f8f9a", "9ff0ff", "e8ffff"]))
	PortraitArt._poly(img, PackedVector2Array([Vector2(o + 4, 60), Vector2(o + 60, 60), Vector2(o + 64, 100), Vector2(o + 70, 150), Vector2(o - 6, 150), Vector2(o, 100)]), robe)
	# Plis de la robe.
	for x: float in [o + 18.0, o + 32.0, o + 46.0]:
		PortraitArt._line(img, Vector2(x, 72), Vector2(x + (x - o - 32.0) * 0.15, 148), robe[0])
	if staff:
		# Manche et main sur le bâton.
		PortraitArt._poly(img, PackedVector2Array([Vector2(o + 48, 62), Vector2(o + 60, 64), Vector2(o + 64, 84), Vector2(o + 56, 86)]), robe)
		PortraitArt._ellipse(img, o + 62.0, 84.0, 3.0, 3.0, PortraitArt._ramp(["8a6a5a", "c8a890", "e8d0b8"]))


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
