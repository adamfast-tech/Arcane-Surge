class_name RoomArt
extends RefCounted
## Fonds des salles (docs/design/31-ambiance.md) : une scène en pixel-art par écran, générée par code à la
## taille de l'écran puis agrandie au plus proche voisin. Le sujet est au centre : il reste visible en portrait
## comme en paysage, les côtés se remplissent (râteliers, étagères, pierres…) selon la largeur.
## La Carte reprend les planches de zone de StoryArt.

const ZONE_PLATES := {1: "foret", 2: "steppe", 3: "marais", 4: "pics", 5: "dunes", 6: "cendres"}
const KINDS := ["forge", "armurerie", "entrainement", "meditation", "bibliotheque", "cercle", "archives", "atelier", "creation", "camp"]

static var _cache: Dictionary = {}


## Taille de rendu adaptée à l'écran : environ 3 à 4 px d'écran par pixel, 480 px au plus sur le grand côté.
static func size_for(view: Vector2) -> Vector2i:
	var v := view if view.x > 8.0 and view.y > 8.0 else Vector2(720, 1280)
	var px := maxf(3.0, maxf(v.x, v.y) / 480.0)
	return Vector2i(int(v.x / px), int(v.y / px))


static func scene(kind: String, size: Vector2i) -> ImageTexture:
	if kind.begins_with("zone"):
		return StoryArt.plate(str(ZONE_PLATES.get(int(kind.trim_prefix("zone")), "foret")), size)
	var w := clampi(size.x, 96, 520)
	var h := clampi(size.y, 96, 520)
	var key := "%s|%d|%d" % [kind, w, h]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	match kind:
		"forge":
			_forge(img, rng)
		"armurerie":
			_armurerie(img, rng)
		"entrainement":
			_entrainement(img, rng)
		"meditation":
			_meditation(img, rng)
		"bibliotheque":
			_bibliotheque(img, rng)
		"cercle":
			_cercle(img, rng)
		"archives":
			_archives(img, rng)
		"atelier":
			_atelier(img, rng)
		"creation":
			_creation(img, rng)
		_:
			_camp(img, rng)
	var tex := ImageTexture.create_from_image(img)
	if _cache.size() > 16:
		_cache.clear()
	_cache[key] = tex
	return tex


# ---------------------------------------------------------------- outils

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	StoryArt._px(img, x, y, c)


static func _rect(img: Image, x: int, y: int, rw: int, rh: int, c: Color) -> void:
	if rw <= 0 or rh <= 0:
		return
	if c.a >= 1.0:
		img.fill_rect(Rect2i(x, y, rw, rh), c)
		return
	var r := Rect2i(x, y, rw, rh).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	for yy in range(r.position.y, r.end.y):
		for xx in range(r.position.x, r.end.x):
			_px(img, xx, yy, c)


static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var n := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in range(n + 1):
		var k := float(i) / float(maxi(1, n))
		_px(img, int(round(lerpf(x0, x1, k))), int(round(lerpf(y0, y1, k))), c)


static func _glow(img: Image, cx: int, cy: int, r: int, c: Color, a: float) -> void:
	StoryArt._glow_px(img, cx, cy, r, c, a)


static func _ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for y in range(-ry, ry + 1):
		var half := int(float(rx) * sqrt(maxf(0.0, 1.0 - pow(float(y) / float(maxi(1, ry)), 2.0))))
		_rect(img, cx - half, cy + y, half * 2 + 1, 1, c)


static func _ring(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color, from: float = 0.0, to: float = TAU) -> void:
	var n := maxi(24, int(float(rx + ry) * 3.2))
	for i in range(n):
		var a := lerpf(from, to, float(i) / float(n))
		_px(img, cx + int(round(cos(a) * rx)), cy + int(round(sin(a) * ry)), c)


## Mur de pierres : rangs décalés, chaque bloc légèrement nuancé, joints sombres.
static func _bricks(img: Image, rng: RandomNumberGenerator, y0: int, y1: int, base: Color, bw: int, bh: int) -> void:
	var w := img.get_width()
	_rect(img, 0, y0, w, y1 - y0, base.darkened(0.45))
	var row := 0
	var y := y0
	while y < y1:
		var off := (bw / 2) * (row % 2)
		var x := -off
		while x < w:
			var c := base.lightened(rng.randf_range(-0.12, 0.1))
			_rect(img, x + 1, y + 1, bw - 1, mini(bh - 1, y1 - y - 1), c)
			_rect(img, x + 1, y + 1, bw - 2, 1, c.lightened(0.12))
			x += bw
		y += bh
		row += 1


## Sol de dalles en perspective : rangs qui s'élargissent vers le bas, joints vers un point de fuite.
static func _flagstones(img: Image, y0: int, base: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_rect(img, 0, y0, w, h - y0, base)
	var y := float(y0)
	var step := 3.0
	var row := 0
	while y < h:
		var c := base.lightened(0.05 if row % 2 == 0 else -0.04)
		_rect(img, 0, int(y) + 1, w, int(step) - 1, c)
		_rect(img, 0, int(y), w, 1, base.darkened(0.35))
		y += step
		step *= 1.35
		row += 1
	var cx := w / 2
	for k in range(-12, 13):
		_line(img, cx + k * 6, y0, cx + k * 40, h + 10, Color(base.darkened(0.4), 0.8))


## Plancher : lattes horizontales et joints décalés.
static func _planks(img: Image, rng: RandomNumberGenerator, y0: int, base: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var y := y0
	var hh := 2
	while y < h:
		_rect(img, 0, y, w, hh, base.lightened(rng.randf_range(-0.06, 0.06)))
		_rect(img, 0, y, w, 1, base.darkened(0.3))
		var x := rng.randi_range(0, 30)
		while x < w:
			_rect(img, x, y, 1, hh, base.darkened(0.3))
			x += rng.randi_range(26, 60)
		y += hh
		hh = mini(hh + 1, 12)


static func _torch(img: Image, x: int, y: int, u: int) -> void:
	_glow(img, x, y - u * 3, u * 16, Color("ff9b4a"), 0.32)
	_rect(img, x - u, y, u * 2, u * 4, Color("4a3424"))
	_rect(img, x - u * 2, y - u, u * 4, u, Color("6a6a74"))
	for i in range(u * 3):
		var half := maxi(0, u - i / 3)
		_rect(img, x - half, y - 1 - i, half * 2 + 1, 1, Color("ffe08a") if i < u else Color("ff8a3a"))


static func _candle(img: Image, x: int, y: int, hgt: int) -> void:
	_glow(img, x, y - hgt - 2, 7, Color("ffc870"), 0.35)
	_rect(img, x, y - hgt, 2, hgt, Color("e8e0c8"))
	_px(img, x, y - hgt - 1, Color("ffe08a"))
	_px(img, x, y - hgt - 2, Color("fff6c8"))


static func _gear(img: Image, cx: int, cy: int, r: int, teeth: int, body: Color, lit: Color, rot: float = 0.0) -> void:
	for y in range(-r - 3, r + 4):
		for x in range(-r - 3, r + 4):
			var d := Vector2(x, y).length()
			var a := atan2(float(y), float(x)) + rot
			var tooth := fposmod(a * float(teeth) / TAU, 1.0) < 0.5
			if d <= float(r) or (tooth and d <= float(r + 3)):
				var c := body
				if d < float(r) * 0.28:
					c = body.darkened(0.55)
				elif d < float(r) * 0.72 and fposmod(a * 3.0 / TAU, 1.0) > 0.18:
					c = body.darkened(0.45)
				elif x + y < -r / 2:
					c = lit
				_px(img, cx + x, cy + y, c)


## Arme pour râtelier : épée, lance, hache ou masse, dressée.
static func _weapon(img: Image, x: int, base: int, hgt: int, kind: int) -> void:
	var steel := Color("b8c0cc")
	var wood := Color("6a4a2a")
	match kind % 4:
		0:
			_rect(img, x, base - hgt, 2, int(hgt * 0.7), steel)
			_px(img, x, base - hgt - 1, steel)
			_rect(img, x - 2, base - int(hgt * 0.3), 6, 1, Color("d8b04a"))
			_rect(img, x, base - int(hgt * 0.3) + 1, 2, int(hgt * 0.3) - 1, wood)
		1:
			_rect(img, x, base - hgt + 4, 1, hgt - 4, wood)
			for i in range(5):
				_rect(img, x - (2 - absi(2 - i)) / 2, base - hgt + i, 1 + (2 - absi(2 - i)), 1, steel)
		2:
			_rect(img, x, base - hgt, 1, hgt, wood)
			_rect(img, x + 1, base - hgt + 1, 3, 5, steel)
			_rect(img, x + 4, base - hgt, 1, 7, steel.lightened(0.2))
		_:
			_rect(img, x, base - hgt + 3, 1, hgt - 3, wood)
			_rect(img, x - 2, base - hgt, 5, 4, Color("8a8a98"))
			_px(img, x, base - hgt - 1, Color("8a8a98"))


static func _shield(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	StoryArt._disc(img, cx, cy, r, Color("4a3424"))
	StoryArt._disc(img, cx, cy, r - 1, col)
	_rect(img, cx - r + 1, cy, r * 2 - 1, 1, col.darkened(0.3))
	_rect(img, cx, cy - r + 1, 1, r * 2 - 1, col.darkened(0.3))
	StoryArt._disc(img, cx, cy, maxi(1, r / 3), Color("c8b070"))


# ---------------------------------------------------------------- scènes

## Forge : grand foyer central, hotte, soufflet, outils pendus, établi de gravure aux runes, enclume.
static func _forge(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var s := mini(w, h)
	var u := maxi(1, s / 60)
	var cx := w / 2
	var floor_y := int(h * 0.7)
	_bricks(img, rng, 0, floor_y, Color("3a2420"), u * 6, u * 3)
	_flagstones(img, floor_y, Color("24160e"))
	# Foyer et hotte.
	var hw := int(s * 0.26)
	var top := floor_y - int(s * 0.42)
	for y in range(0, top):
		var k := float(y) / float(maxi(1, top))
		var half := int(lerpf(float(hw) * 0.45, float(hw) * 1.12, k))
		_rect(img, cx - half, y, half * 2, 1, Color("4a3a34").darkened(0.15 * (1.0 - k)))
		_px(img, cx - half, y, Color("2a1e18"))
		_px(img, cx + half - 1, y, Color("6a5448"))
	_rect(img, cx - int(hw * 1.18), top - u * 2, int(hw * 2.36), u * 3, Color("5a463c"))
	_rect(img, cx - hw, top, hw * 2, floor_y - top, Color("4a3a34"))
	for yy in range(top + u * 2, floor_y, u * 3):
		for xx in range(cx - hw + ((yy / (u * 3)) % 2) * u * 3, cx + hw - u, u * 6):
			_rect(img, xx, yy, u * 5, 1, Color("3a2c26"))
	var ow := int(hw * 0.7)
	var oh := int(s * 0.26)
	_rect(img, cx - ow, floor_y - oh + ow / 2, ow * 2, oh - ow / 2, Color("140806"))
	StoryArt._disc(img, cx, floor_y - oh + ow / 2, ow, Color("140806"))
	_rect(img, cx - hw, floor_y, hw * 2, 1, Color("2a1e18"))
	_glow(img, cx, floor_y - u * 6, int(s * 0.5), Color("ff6a2a"), 0.34)
	_glow(img, cx, floor_y - u * 4, int(s * 0.2), Color("ffb050"), 0.45)
	# Braises et flammes.
	for i in range(int(ow * 6)):
		var x := cx + rng.randi_range(-ow + 2, ow - 2)
		var y := floor_y - 1 - rng.randi_range(0, u * 3)
		_px(img, x, y, [Color("ff4a1a"), Color("ff8a3a"), Color("ffd070")][rng.randi_range(0, 2)])
	for i in range(14):
		var x := cx + rng.randi_range(-ow + u * 2, ow - u * 2)
		var fh := rng.randi_range(u * 4, int(oh * 0.75))
		for j in range(fh):
			var k := float(j) / float(fh)
			var c := Color("fff0a0").lerp(Color("ff5a1a"), k)
			_px(img, x + int(sin(float(j) * 0.4 + float(i)) * 1.5), floor_y - u * 2 - j, Color(c, 1.0 - k * 0.6))
	# Soufflet à gauche du foyer.
	var bx := cx - hw - int(s * 0.12)
	var by := floor_y - u * 2
	for i in range(u * 8):
		var half := int(float(i) * 0.45)
		_rect(img, bx - u * 4 + i, by - half - u, 1, half * 2 + u * 2, Color("6a3a22") if i % 3 else Color("4a2616"))
	_rect(img, bx + u * 4, by - 1, u * 5, 2, Color("8a8a98"))
	_rect(img, bx - u * 7, by - 1, u * 3, 2, Color("6a4a2a"))
	# Outils pendus.
	var rx0 := cx - hw - int(s * 0.42)
	var rack_y := floor_y - int(s * 0.5)
	_rect(img, rx0, rack_y, int(s * 0.3), u, Color("5a3a22"))
	for k in range(5):
		var tx := rx0 + u * 3 + k * int(s * 0.06)
		_rect(img, tx, rack_y + u, 1, u * 7 + (k % 2) * u * 2, Color("6a5a50"))
		if k % 2 == 0:
			_rect(img, tx - u, rack_y + u * 8, u * 3, u * 2, Color("8a8a98"))
		else:
			_line(img, tx, rack_y + u * 9, tx - u, rack_y + u * 11, Color("8a8a98"))
			_line(img, tx, rack_y + u * 9, tx + u, rack_y + u * 11, Color("8a8a98"))
	# Établi de gravure et runes flottantes à droite.
	var ex := cx + hw + int(s * 0.06)
	var ey := floor_y - u * 5
	_rect(img, ex, ey, int(s * 0.3), u * 2, Color("6a4a2a"))
	_rect(img, ex + u, ey + u * 2, u, floor_y - ey, Color("4a3020"))
	_rect(img, ex + int(s * 0.3) - u * 2, ey + u * 2, u, floor_y - ey, Color("4a3020"))
	var cols := [Color("4fe3d2"), Color("b07cff"), Color("f2c46b")]
	for k in range(3):
		var rx := ex + u * 4 + k * int(s * 0.09)
		var ry := ey - u * 6 - (k % 2) * u * 3
		_glow(img, rx, ry, u * 6, cols[k], 0.35)
		_rect(img, rx - u, ry - u * 2, u * 3, u * 4, Color("4a4a58"))
		StoryArt._rune(img, rx, ry, cols[k])
	# Lingots sur l'étagère.
	var sy := floor_y - int(s * 0.52)
	_rect(img, ex, sy, int(s * 0.3), u, Color("5a3a22"))
	for k in range(6):
		_rect(img, ex + u * 2 + k * u * 5, sy - u * 2, u * 4, u * 2, [Color("e6c15a"), Color("c8ccd8"), Color("d8884a")][k % 3])
	# Enclume au premier plan, lame rougeoyante.
	var ax := cx
	var ay := floor_y + int((h - floor_y) * 0.42)
	_rect(img, ax - u * 3, ay + u * 4, u * 6, u * 6, Color("4a3020"))
	_rect(img, ax - u * 4, ay + u * 2, u * 8, u * 2, Color("3a3a46"))
	_rect(img, ax - u * 7, ay - u, u * 14, u * 3, Color("4a4a58"))
	for i in range(u * 4):
		_rect(img, ax - u * 7 - i, ay - u + i / 2, 1, maxi(1, u * 2 - i / 2), Color("4a4a58"))
	_rect(img, ax - u * 7, ay - u, u * 14, 1, Color("ffb070"))
	_rect(img, ax - u * 5, ay - u * 2, u * 9, u, Color("ff7a2a"))
	_rect(img, ax - u * 5, ay - u * 2, u * 9, 1, Color("ffd070"))
	_glow(img, ax, ay - u * 2, u * 7, Color("ff8a3a"), 0.4)
	_line(img, ax + u * 8, ay + u * 9, ax + u * 12, ay - u * 2, Color("6a4a2a"))
	_rect(img, ax + u * 10, ay - u * 4, u * 4, u * 2, Color("6a6a78"))
	# Baquet de trempe.
	var qx := cx + int(s * 0.32)
	_rect(img, qx - u * 4, ay, u * 8, u * 7, Color("5a3a22"))
	_rect(img, qx - u * 4, ay + u * 2, u * 8, 1, Color("8a8a98"))
	_rect(img, qx - u * 4, ay + u * 5, u * 8, 1, Color("8a8a98"))
	_rect(img, qx - u * 3, ay, u * 6, 1, Color("3a5a6a"))
	StoryArt._mist(img, rng, ay - u * 10, ay - u, Color(0.9, 0.9, 0.95, 0.12), 6)
	# Étincelles.
	for i in range(int(w * h / 700.0)):
		var p := Vector2(cx + rng.randf_range(-s * 0.5, s * 0.5), rng.randf_range(h * 0.15, ay))
		_px(img, int(p.x), int(p.y), Color("ffd070") if rng.randf() < 0.5 else Color("ff8a3a"))


## Armurerie (Équipement) : armure sur son mannequin devant une bannière, râteliers d'armes et boucliers.
static func _armurerie(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var s := mini(w, h)
	var u := maxi(1, s / 60)
	var cx := w / 2
	var floor_y := int(h * 0.7)
	_bricks(img, rng, 0, floor_y, Color("34343e"), u * 6, u * 3)
	_flagstones(img, floor_y, Color("1c1c24"))
	# Tapis rouge vers le mannequin.
	for y in range(floor_y + u * 2, h):
		var k := float(y - floor_y) / float(maxi(1, h - floor_y))
		var half := int(lerpf(float(u) * 6.0, float(s) * 0.3, k))
		_rect(img, cx - half, y, half * 2, 1, Color("6a1a22").lerp(Color("8a2a2a"), k))
		_px(img, cx - half, y, Color("d8b04a"))
		_px(img, cx + half - 1, y, Color("d8b04a"))
	# Bannière.
	var bw := int(s * 0.17)
	var btop := int(h * 0.08)
	var bbot := floor_y - int(s * 0.12)
	_rect(img, cx - bw - u, btop - u, bw * 2 + u * 2, u, Color("6a4a2a"))
	for y in range(btop, bbot):
		var cut := maxi(0, y - (bbot - bw))
		_rect(img, cx - bw, y, bw - cut, 1, Color("1e3a7a"))
		_rect(img, cx + cut, y, bw - cut, 1, Color("1e3a7a"))
		_px(img, cx - bw, y, Color("d8b04a"))
		_px(img, cx + bw - 1, y, Color("d8b04a"))
	var ey := mini(btop + int((bbot - btop) * 0.3), floor_y + u * 4 - int(s * 0.44) - u * 14)
	for i in range(u * 5):
		_rect(img, cx - i, ey - u * 5 + i, i * 2 + 1, 1, Color("f2c46b"))
		_rect(img, cx - i, ey + u * 5 - i, i * 2 + 1, 1, Color("f2c46b"))
	StoryArt._disc(img, cx, ey, u * 2, Color("1e3a7a"))
	# Torches.
	for sx: int in [-1, 1]:
		_torch(img, cx + sx * int(s * 0.27), floor_y - int(s * 0.48), u)
	# Mannequin et armure.
	var my := floor_y + u * 4
	_ellipse(img, cx, my, u * 7, u * 2, Color("2a2a34"))
	_rect(img, cx - 1, my - u * 12, 2, u * 12, Color("5a3a22"))
	var ch := my - int(s * 0.44)
	# Cape.
	for y in range(ch + u * 3, my - u * 6):
		var half := u * 7 + (y - ch) / 6
		_rect(img, cx - half, y, half * 2, 1, Color("7a1a22") if y % 5 else Color("5a1018"))
	# Cuirasse.
	for y in range(ch + u * 3, ch + u * 17):
		var k := float(y - ch - u * 3) / float(u * 14)
		var half := int(lerpf(float(u) * 6.0, float(u) * 4.0, k))
		_rect(img, cx - half, y, half * 2, 1, Color("9aa4b4"))
		_px(img, cx - half, y, Color("5a6070"))
		_rect(img, cx + half - u, y, u, 1, Color("c8d0dc"))
	_rect(img, cx - u * 4, ch + u * 17, u * 8, u * 4, Color("7a8494"))
	for i in range(3):
		_rect(img, cx - u * 4, ch + u * 17 + i * u + i, u * 8, 1, Color("d8b04a"))
	_rect(img, cx - 1, ch + u * 4, 2, u * 12, Color("d8b04a"))
	# Épaulières.
	for sx: int in [-1, 1]:
		StoryArt._disc(img, cx + sx * u * 7, ch + u * 4, u * 3, Color("8a94a4"))
		_rect(img, cx + sx * u * 7 - u * 3, ch + u * 4, u * 6, 1, Color("d8b04a"))
	# Heaume et plumet.
	StoryArt._disc(img, cx, ch - u, u * 3, Color("9aa4b4"))
	_rect(img, cx - u * 3, ch - u, u * 6, u * 3, Color("9aa4b4"))
	_rect(img, cx - u * 2, ch, u * 4, 1, Color("1a1a22"))
	_rect(img, cx, ch - u * 2, 1, u * 4, Color("1a1a22"))
	for i in range(u * 6):
		_rect(img, cx - u + int(sin(float(i) * 0.5) * 2.0), ch - u * 4 - i, u * 2, 1, Color("c82a3a"))
	_glow(img, cx, ch + u * 8, int(s * 0.2), Color("f2c46b"), 0.12)
	# Râteliers et boucliers, de part et d'autre, jusqu'aux bords.
	var k := 0
	var off := int(s * 0.42)
	while off < w / 2 + int(s * 0.1):
		for sx: int in [-1, 1]:
			var rx := cx + sx * off
			var rw := int(s * 0.16)
			var top := floor_y - int(s * 0.34)
			_rect(img, rx - rw / 2, top, rw, u, Color("5a3a22"))
			_rect(img, rx - rw / 2, floor_y - u * 3, rw, u, Color("5a3a22"))
			_rect(img, rx - rw / 2, top, u, floor_y - top, Color("4a3020"))
			_rect(img, rx + rw / 2 - u, top, u, floor_y - top, Color("4a3020"))
			for j in range(4):
				_weapon(img, rx - rw / 2 + u * 2 + j * (rw - u * 4) / 3, floor_y - u * 3, int(s * 0.28) + (j % 2) * u * 2, j + k + (1 if sx > 0 else 0))
			_shield(img, rx, top - u * 7, u * 4, [Color("8a2a2a"), Color("2a5a8a"), Color("2a6a4a")][(k + (1 if sx > 0 else 0)) % 3])
			# Coffre au pied.
			_rect(img, rx - u * 5, floor_y + u * 2, u * 10, u * 5, Color("5a3a22"))
			_rect(img, rx - u * 5, floor_y + u * 2, u * 10, 1, Color("d8b04a"))
			_rect(img, rx - 1, floor_y + u * 3, u, u, Color("f2c46b"))
		off += int(s * 0.24)
		k += 1


## Entrainement (arbre de compétences) : un grand arbre aux nœuds dorés reliés comme des constellations,
## mannequins d'entraînement et cible au crépuscule.
static func _entrainement(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var s := mini(w, h)
	var u := maxi(1, s / 60)
	var cx := w / 2
	var hz := int(h * 0.68)
	StoryArt._sky(img, rng, [[0.0, Color("0a0820")], [0.35, Color("24183e")], [0.55, Color("6a3a5a")], [0.68, Color("d8885a")], [1.0, Color("d8885a")]], 0.8)
	StoryArt._ridge(img, rng, hz - int(s * 0.05), int(s * 0.03), Color("3a2a48"), Color("5a3a5a"))
	StoryArt._ridge(img, rng, hz - int(s * 0.01), int(s * 0.015), Color("24202e"), Color("3a3040"))
	for y in range(hz, h):
		var k := float(y - hz) / float(maxi(1, h - hz))
		_rect(img, 0, y, w, 1, Color("2a3a22").lerp(Color("141c12"), k))
	for i in range(int(w * 1.2)):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(hz + 2, h - 1)
		_rect(img, x, y - 2, 1, 2, Color("3a5a2a"))
	# Clôture.
	for x in range(-int(rng.randi_range(0, 8)), w, u * 7):
		_rect(img, x, hz - u * 3, u, u * 4, Color("3a2a1e"))
	_rect(img, 0, hz - u * 2, w, 1, Color("3a2a1e"))
	# Le grand arbre (réduit en paysage pour tenir sous le bord haut).
	var sky_s := s
	s = mini(s, int(hz * 1.1))
	var root_y := hz + int(s * 0.06)
	var crown := hz - int(s * 0.5)
	var tw := int(s * 0.05)
	for y in range(crown + int(s * 0.12), root_y):
		var k := float(y - crown) / float(maxi(1, root_y - crown))
		var half := tw + int(pow(k, 4.0) * s * 0.08)
		_rect(img, cx - half, y, half * 2, 1, Color("3a2618"))
		_rect(img, cx - half, y, u, 1, Color("24160e"))
		_rect(img, cx + half - u, y, u, 1, Color("5a3e26"))
	for sx: int in [-1, 1]:
		_line(img, cx, crown + int(s * 0.2), cx + sx * int(s * 0.2), crown + int(s * 0.06), Color("3a2618"))
		_line(img, cx, crown + int(s * 0.2) + 1, cx + sx * int(s * 0.2), crown + int(s * 0.06) + 1, Color("3a2618"))
	var blobs := [[0, 0, 0.2], [-0.17, 0.05, 0.14], [0.17, 0.05, 0.14], [-0.1, -0.1, 0.13], [0.1, -0.1, 0.13], [-0.27, 0.12, 0.09], [0.27, 0.12, 0.09], [0, -0.16, 0.11]]
	for b in blobs:
		StoryArt._disc(img, cx + int(float(b[0]) * s), crown + int(float(b[1]) * s), int(float(b[2]) * s), Color("16301e"))
	for b in blobs:
		var bx := cx + int(float(b[0]) * s)
		var by := crown + int(float(b[1]) * s)
		var r := int(float(b[2]) * s)
		StoryArt._disc(img, bx + r / 5, by - r / 5, int(r * 0.7), Color("1e4028"))
		for i in range(r):
			_px(img, bx + rng.randi_range(-r / 2, r), by - rng.randi_range(0, r), Color("2a5a34"))
	# Constellation de compétences dans la ramure.
	var nodes := [Vector2(0, 0.2), Vector2(-0.1, 0.08), Vector2(0.1, 0.08), Vector2(-0.2, 0.0), Vector2(0, -0.02), Vector2(0.2, 0.0),
		Vector2(-0.26, 0.12), Vector2(0.26, 0.12), Vector2(-0.12, -0.12), Vector2(0.12, -0.12), Vector2(0, -0.2)]
	var links := [[0, 1], [0, 2], [1, 3], [1, 4], [2, 4], [2, 5], [3, 6], [5, 7], [3, 8], [4, 8], [4, 9], [5, 9], [8, 10], [9, 10]]
	for l in links:
		var a: Vector2 = nodes[l[0]]
		var b: Vector2 = nodes[l[1]]
		_line(img, cx + int(a.x * s), crown + int(a.y * s), cx + int(b.x * s), crown + int(b.y * s), Color(1.0, 0.85, 0.45, 0.55))
	for i in range(nodes.size()):
		var n: Vector2 = nodes[i]
		var nx := cx + int(n.x * s)
		var ny := crown + int(n.y * s)
		var col := Color("4fe3d2") if i in [0, 4, 10] else Color("f2c46b")
		_glow(img, nx, ny, u * 4, col, 0.55)
		StoryArt._disc(img, nx, ny, maxi(1, u), col.lightened(0.4))
	s = sky_s
	# Mannequins d'entraînement.
	for sx: int in [-1, 1]:
		var dx := cx + sx * int(s * 0.36)
		var dy := hz + int(s * 0.14)
		_rect(img, dx - 1, dy - u * 16, 2, u * 16, Color("4a3020"))
		_rect(img, dx - u * 5, dy - u * 12, u * 10, u, Color("4a3020"))
		_ellipse(img, dx, dy - u * 9, u * 3, u * 5, Color("c8a050"))
		_rect(img, dx - u * 3, dy - u * 9, u * 6, 1, Color("8a6a30"))
		_rect(img, dx - u * 3, dy - u * 6, u * 6, 1, Color("8a6a30"))
		StoryArt._disc(img, dx, dy - u * 16, u * 2, Color("d8c090"))
		_px(img, dx - 1, dy - u * 16, Color("3a2a1e"))
		_px(img, dx + 1, dy - u * 16, Color("3a2a1e"))
	# Cible et râtelier, si la largeur le permet.
	var tx := cx + int(s * 0.62)
	if tx < w + u * 4:
		var ty := hz + int(s * 0.08)
		_rect(img, tx - 1, ty - u * 4, 2, u * 8, Color("4a3020"))
		for r in [u * 6, u * 5, u * 4, u * 3, u * 2, u]:
			StoryArt._disc(img, tx, ty - u * 6, r, Color("e8e0c8") if (r / u) % 2 == 0 else Color("c82a3a"))
		_line(img, tx - u * 6, ty - u * 10, tx, ty - u * 6, Color("6a4a2a"))
	var wx := cx - int(s * 0.62)
	if wx > -u * 6:
		var wy := hz + int(s * 0.1)
		_rect(img, wx - u * 5, wy - u * 8, u * 10, u, Color("4a3020"))
		for j in range(4):
			_weapon(img, wx - u * 4 + j * u * 3, wy, u * 12, j)
	StoryArt._fireflies(img, rng, int(w / 9), int(h * 0.2), h - 4, Color("f2c46b"))


## Méditation : sanctuaire au bord d'un lac sous la lune, plateforme au cercle lumineux, lanternes de pierre.
static func _meditation(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var s := mini(w, h)
	var u := maxi(1, s / 60)
	var cx := w / 2
	var wy := int(h * 0.6)
	StoryArt._sky(img, rng, [[0.0, Color("04051a")], [0.4, Color("161a44")], [0.6, Color("343a6e")], [1.0, Color("343a6e")]], 1.3)
	var mx := cx + int(s * 0.2)
	var my := int(h * 0.15)
	StoryArt._moon(img, mx, my, maxi(5, int(s * 0.07)))
	# Montagnes lointaines.
	for k in range(-3, 4):
		StoryArt._peak(img, cx + k * int(s * 0.24) + rng.randi_range(-8, 8), wy, int(s * 0.2), int(s * rng.randf_range(0.14, 0.26)), Color("1c1e40"), Color("4a4e80"))
	StoryArt._mist(img, rng, wy - int(s * 0.08), wy, Color(0.7, 0.75, 1.0, 0.12), 26)
	# Lac et reflet de la lune.
	for y in range(wy, h):
		var k := float(y - wy) / float(maxi(1, h - wy))
		_rect(img, 0, y, w, 1, Color("1a1e48").lerp(Color("080a20"), k))
	for i in range(int(w * 0.6)):
		var y := rng.randi_range(wy + 1, h - 1)
		var x := rng.randi_range(0, w)
		_rect(img, x, y, rng.randi_range(3, 12), 1, Color(0.5, 0.55, 0.9, 0.25))
	for y in range(wy + 1, h, 2):
		var spread := int(float(y - wy) * 0.12) + u * 2
		_rect(img, mx - spread + rng.randi_range(-2, 2), y, rng.randi_range(spread, spread * 2), 1, Color(0.95, 0.93, 0.8, 0.55))
	# Saule à gauche.
	var tx := cx - int(s * 0.34)
	_rect(img, tx - u, wy - int(s * 0.3), u * 2, int(s * 0.3) + u * 3, Color("1a1422"))
	StoryArt._disc(img, tx, wy - int(s * 0.33), int(s * 0.12), Color("142a2a"))
	for i in range(28):
		var sx := tx + rng.randi_range(-int(s * 0.13), int(s * 0.13))
		var sl := rng.randi_range(int(s * 0.08), int(s * 0.24))
		for j in range(sl):
			_px(img, sx + int(sin(float(j) * 0.2) * 1.0), wy - int(s * 0.33) + j, Color("2a4a3a") if j % 3 else Color("3a6a4a"))
	for i in range(30):
		_px(img, tx + rng.randi_range(-int(s * 0.2), int(s * 0.25)), wy - rng.randi_range(-int(s * 0.1), int(s * 0.4)), Color("ffb0d0"))
	# Plateforme de méditation et cercle lumineux.
	var py := wy + int((h - wy) * 0.42)
	var prx := int(s * 0.3)
	var pry := maxi(u * 3, int(s * 0.07))
	_ellipse(img, cx, py + u * 2, prx, pry, Color("2a2a3e"))
	_ellipse(img, cx, py, prx, pry, Color("5a5a74"))
	_ellipse(img, cx, py, prx - u * 2, pry - u, Color("6a6a86"))
	_glow(img, cx, py, int(prx * 0.9), Color("9ff0ff"), 0.22)
	_ring(img, cx, py, int(prx * 0.7), int(pry * 0.7), Color("bff6ff"))
	_ring(img, cx, py, int(prx * 0.45), int(pry * 0.45), Color("c8b0ff"))
	for i in range(8):
		var a := float(i) * TAU / 8.0
		_px(img, cx + int(cos(a) * prx * 0.58), py + int(sin(a) * pry * 0.58), Color("ffffff"))
	_ellipse(img, cx, py - u, u * 4, u * 2, Color("6a3a6a"))
	# Cristal flottant au-dessus du cercle.
	var cy := py - int(s * 0.16)
	_glow(img, cx, cy, u * 8, Color("c8b0ff"), 0.4)
	for y in range(-u * 4, u * 4 + 1):
		var half := int(float(u) * 1.6 * (1.0 - absf(float(y)) / float(u * 4)))
		_rect(img, cx - half, cy + y, half * 2 + 1, 1, Color("e8e0ff") if y < 0 else Color("a890e8"))
	# Lanternes de pierre.
	for sx: int in [-1, 1]:
		var lx := cx + sx * int(s * 0.4)
		var ly := py + int(s * 0.04)
		_rect(img, lx - u * 2, ly - u * 6, u * 4, u * 6, Color("4a4a5a"))
		_rect(img, lx - u * 3, ly - u * 9, u * 6, u * 3, Color("5a5a6e"))
		_rect(img, lx - u, ly - u * 8, u * 2, u * 2, Color("ffd070"))
		_rect(img, lx - u * 4, ly - u * 10, u * 8, u, Color("3a3a4a"))
		_glow(img, lx, ly - u * 8, u * 9, Color("ffc870"), 0.3)
	# Bougies flottantes.
	for i in range(10):
		var fx := rng.randi_range(0, w - 1)
		var fy := rng.randi_range(wy + u * 3, h - u * 2)
		if absi(fx - cx) < prx and absi(fy - py) < pry * 2:
			continue
		_rect(img, fx - 1, fy, 3, 1, Color("8a5a8a"))
		_px(img, fx, fy - 1, Color("ffe08a"))
		_glow(img, fx, fy - 1, 4, Color("ffc870"), 0.3)


## Bibliothèque : murs d'étagères, grande fenêtre en arc sous la lune, pupitre au grimoire lumineux, livres volants.
static func _bibliotheque(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var s := mini(w, h)
	var u := maxi(1, s / 60)
	var cx := w / 2
	var floor_y := int(h * 0.72)
	_rect(img, 0, 0, w, floor_y, Color("24160e"))
	var spines := [Color("7a2a2a"), Color("2a5a3a"), Color("2a3a6a"), Color("8a6a2a"), Color("5a2a6a"), Color("6a4a2a"), Color("2a5a6a"), Color("9a8a6a")]
	var rowh := maxi(u * 7, int(s * 0.12))
	var y := int(h * 0.03)
	while y + rowh < floor_y:
		_rect(img, 0, y + rowh - u, w, u, Color("4a2e1a"))
		_rect(img, 0, y + rowh - u, w, 1, Color("6a4a2a"))
		var x := rng.randi_range(0, 4)
		while x < w:
			var bw := rng.randi_range(u * 2, u * 3)
			var bh := int(float(rowh - u * 2) * rng.randf_range(0.6, 0.95))
			if rng.randf() < 0.06:
				x += u * 4
				continue
			var c: Color = spines[rng.randi_range(0, spines.size() - 1)]
			_rect(img, x, y + rowh - u - bh, bw, bh, c)
			_rect(img, x, y + rowh - u - bh, 1, bh, c.lightened(0.18))
			_rect(img, x, y + rowh - u - bh + bh / 4, bw, 1, Color("d8b04a"))
			x += bw + (1 if rng.randf() < 0.3 else 0)
		y += rowh
	# Fenêtre en arc.
	var ww := int(s * 0.2)
	var wt := int(h * 0.1)
	var wb := floor_y - int(s * 0.16)
	_rect(img, cx - ww - u * 3, wt - u * 2, ww * 2 + u * 6, wb - wt + u * 4, Color("3a2a22"))
	StoryArt._disc(img, cx, wt + ww, ww + u * 3, Color("3a2a22"))
	for yy in range(wt, wb):
		var k := float(yy - wt) / float(maxi(1, wb - wt))
		_rect(img, cx - ww, yy, ww * 2, 1, Color("101a44").lerp(Color("2a3a7a"), k))
	StoryArt._disc(img, cx, wt + ww, ww, Color("101a44"))
	for i in range(40):
		var sx := cx + rng.randi_range(-ww + 2, ww - 2)
		var sy := rng.randi_range(wt, wb - 2)
		_px(img, sx, sy, Color(1, 1, 1, rng.randf_range(0.3, 0.9)))
	StoryArt._moon(img, cx + ww / 3, wt + ww, maxi(3, ww / 4))
	_rect(img, cx - 1, wt, 2, wb - wt, Color("3a2a22"))
	for yy in range(wt + ww, wb, maxi(u * 6, (wb - wt) / 4)):
		_rect(img, cx - ww, yy, ww * 2, 1, Color("3a2a22"))
	# Rayon de lune vers le sol.
	for yy in range(wb, h):
		var k := float(yy - wb) / float(maxi(1, h - wb))
		var half := int(lerpf(float(ww), float(ww) * 2.2, k))
		_rect(img, cx - half + int(k * s * 0.1), yy, half * 2, 1, Color(0.6, 0.7, 1.0, 0.08 * (1.0 - k)))
	# Plancher.
	_planks(img, rng, floor_y, Color("2a1a10"))
	for yy in range(floor_y, h):
		var k := float(yy - floor_y) / float(maxi(1, h - floor_y))
		var half := int(lerpf(float(ww), float(ww) * 2.4, k))
		_rect(img, cx - half, yy, half * 2, 1, Color(0.6, 0.7, 1.0, 0.07))
	# Échelle.
	var lx := cx - int(s * 0.36)
	_line(img, lx, floor_y + u * 2, lx + u * 8, int(h * 0.12), Color("6a4a2a"))
	_line(img, lx + u * 5, floor_y + u * 2, lx + u * 13, int(h * 0.12), Color("6a4a2a"))
	for i in range(1, 12):
		var k := float(i) / 12.0
		var ya := int(lerpf(floor_y + u * 2, h * 0.12, k))
		var xa := int(lerpf(lx, lx + u * 8, k))
		_rect(img, xa, ya, u * 5, 1, Color("8a6a3a"))
	# Pupitre et grimoire.
	var py := floor_y + int((h - floor_y) * 0.5)
	_rect(img, cx - u * 2, py - u * 8, u * 4, u * 10, Color("4a3020"))
	_rect(img, cx - u * 6, py + u * 2, u * 12, u * 2, Color("4a3020"))
	for i in range(u * 3):
		_rect(img, cx - u * 8 + i, py - u * 8 - i, u * 16 - i * 2, 1, Color("5a3a22"))
	_rect(img, cx - u * 7, py - u * 12, u * 7, u * 2, Color("e8e0c8"))
	_rect(img, cx, py - u * 12, u * 7, u * 2, Color("d8d0b8"))
	_glow(img, cx, py - u * 14, int(s * 0.16), Color("b07cff"), 0.4)
	for i in range(3):
		StoryArt._rune(img, cx - u * 6 + i * u * 6, py - u * 20 - (i % 2) * u * 4, [Color("b07cff"), Color("4fe3d2"), Color("f2c46b")][i])
	# Livres volants.
	for i in range(4):
		var fx := cx + int((-0.32 + 0.21 * float(i)) * s) + rng.randi_range(-4, 4)
		var fy := int(h * 0.25) + rng.randi_range(0, int(h * 0.25))
		_glow(img, fx, fy, u * 6, Color("ffe8b0"), 0.18)
		for j in range(u * 4):
			_px(img, fx - j, fy - j / 2, Color("e8e0c8"))
			_px(img, fx + j, fy - j / 2, Color("e8e0c8"))
			_px(img, fx - j, fy - j / 2 + 1, Color("7a2a2a"))
			_px(img, fx + j, fy - j / 2 + 1, Color("7a2a2a"))
	# Chandeliers.
	for sx: int in [-1, 1]:
		var cxx := cx + sx * int(s * 0.25)
		_rect(img, cxx, floor_y - u * 2, 1, u * 10, Color("8a6a3a"))
		_rect(img, cxx - u * 3, floor_y - u * 2, u * 6, 1, Color("8a6a3a"))
		for j in [-u * 3, 0, u * 3]:
			_candle(img, cxx + j, floor_y - u * 2, u * 2)


## Cercle (compagnons) : feu de camp dans une clairière, cercle de pierres levées, tentes et guirlande de lanternes.
static func _cercle(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var s := mini(w, h)
	var u := maxi(1, s / 60)
	var cx := w / 2
	var hz := int(h * 0.58)
	StoryArt._sky(img, rng, [[0.0, Color("05061a")], [0.5, Color("141a3a")], [0.58, Color("24284a")], [1.0, Color("24284a")]], 1.2)
	StoryArt._moon(img, cx - int(s * 0.28), int(h * 0.12), maxi(4, int(s * 0.04)))
	StoryArt._ridge(img, rng, hz - int(s * 0.04), int(s * 0.02), Color("101828"), Color("1a2438"))
	var x := -rng.randi_range(0, 10)
	while x < w + 10:
		StoryArt._pine(img, x, hz + u * 2, rng.randi_range(int(s * 0.14), int(s * 0.3)), Color("0c1418"), Color("1a2a30"))
		x += rng.randi_range(int(s * 0.05), int(s * 0.09))
	for y in range(hz, h):
		var k := float(y - hz) / float(maxi(1, h - hz))
		_rect(img, 0, y, w, 1, Color("1a2418").lerp(Color("0e140e"), k))
	var fy := hz + int((h - hz) * 0.45)
	_glow(img, cx, fy, int(s * 0.55), Color("ff8a3a"), 0.22)
	# Pierres levées en arc derrière le feu.
	for i in range(-4, 5):
		var a := float(i) * 0.36
		var px := cx + int(sin(a) * s * 0.42)
		var py := fy - int(cos(a) * s * 0.12) - u * 2
		var sh := int(s * (0.12 + 0.02 * float(2 - absi(i) % 3)))
		var sw := maxi(u * 2, int(s * 0.03))
		_rect(img, px - sw, py - sh, sw * 2, sh, Color("4a4e5a"))
		_rect(img, px - sw, py - sh, u, sh, Color("2e323c"))
		_rect(img, px + sw - u, py - sh, u, sh, Color("6a6e7a"))
		_rect(img, px - sw + u, py - sh, sw * 2 - u * 2, u, Color("3a5a3a"))
		if i % 2 == 0:
			StoryArt._rune(img, px, py - sh / 2, Color("4fe3d2"))
	# Tentes.
	for sx: int in [-1, 1]:
		StoryArt._tent(img, cx + sx * int(s * 0.36), fy + u * 4, int(s * 0.14))
	# Guirlande de lanternes.
	var l0 := Vector2(cx - int(s * 0.48), hz - int(s * 0.04))
	var l1 := Vector2(cx + int(s * 0.48), hz - int(s * 0.04))
	_rect(img, int(l0.x), int(l0.y), 1, fy - int(l0.y), Color("3a2a1e"))
	_rect(img, int(l1.x), int(l1.y), 1, fy - int(l1.y), Color("3a2a1e"))
	for i in range(41):
		var k := float(i) / 40.0
		var p := l0.lerp(l1, k) + Vector2(0, sin(k * PI) * s * 0.06)
		_px(img, int(p.x), int(p.y), Color("3a2a1e"))
		if i % 5 == 2:
			_glow(img, int(p.x), int(p.y) + 2, u * 3, Color("ffc870"), 0.45)
			_rect(img, int(p.x) - 1, int(p.y) + 1, 2, 2, Color("ffd070"))
	# Feu, bûches et pierres.
	for i in range(8):
		var a := float(i) * TAU / 8.0
		StoryArt._disc(img, cx + int(cos(a) * u * 6), fy + int(sin(a) * u * 2), maxi(1, u), Color("5a5a64"))
	_line(img, cx - u * 4, fy + u, cx + u * 4, fy - u, Color("4a2e1a"))
	_line(img, cx - u * 4, fy - u, cx + u * 4, fy + u, Color("4a2e1a"))
	for i in range(u * 3):
		StoryArt._fire(img, rng, cx + rng.randi_range(-u, u), fy)
	# Bancs de rondins.
	for sx: int in [-1, 1]:
		var bx := cx + sx * int(s * 0.2)
		var by := fy + int(s * 0.1)
		_rect(img, bx - u * 6, by, u * 12, u * 3, Color("5a3a22"))
		_rect(img, bx - u * 6, by, u * 12, 1, Color("8a5a32"))
		StoryArt._disc(img, bx + sx * u * 6, by + u, u, Color("b08a50"))
	StoryArt._fireflies(img, rng, int(w / 14), hz - int(s * 0.1), h - 4, Color("ffd070"))


## Archives (sauvegardes) : salle voûtée, cristaux de mémoire sur leurs socles, grand cristal central.
static func _archives(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var s := mini(w, h)
	var u := maxi(1, s / 60)
	var cx := w / 2
	var floor_y := int(h * 0.7)
	_bricks(img, rng, 0, floor_y, Color("26223e"), u * 6, u * 3)
	# Floor sombre et poli.
	for y in range(floor_y, h):
		var k := float(y - floor_y) / float(maxi(1, h - floor_y))
		_rect(img, 0, y, w, 1, Color("1a1830").lerp(Color("0c0a18"), k))
	for y in range(floor_y, h, 4):
		_rect(img, 0, y, w, 1, Color("221e3a"))
	# Arcades et niches.
	var bay := int(s * 0.28)
	var cols := [Color("4fe3d2"), Color("f2c46b"), Color("b07cff")]
	var i := 0
	var bx := cx - bay * int(ceil(float(w) / float(bay) / 2.0 + 1.0))
	while bx < w + bay:
		var nw := int(bay * 0.36)
		var top := int(h * 0.18)
		_rect(img, bx - nw, top + nw, nw * 2, floor_y - top - nw, Color("0e0c1c"))
		StoryArt._disc(img, bx, top + nw, nw, Color("0e0c1c"))
		_rect(img, bx + bay / 2 - u * 2, 0, u * 4, floor_y, Color("3a3456"))
		_rect(img, bx + bay / 2 - u * 2, 0, u, floor_y, Color("4a4468"))
		if absi(bx - cx) > bay / 3:
			var c: Color = cols[i % 3]
			var py := floor_y - u * 6
			_rect(img, bx - u * 3, py, u * 6, u * 6, Color("4a4468"))
			_rect(img, bx - u * 4, py, u * 8, u, Color("5a5480"))
			var gy := py - u * 7
			_glow(img, bx, gy, u * 10, c, 0.35)
			for yy in range(-u * 4, u * 4 + 1):
				var half := int(float(u) * 2.0 * (1.0 - absf(float(yy)) / float(u * 4)))
				_rect(img, bx - half, gy + yy, half * 2 + 1, 1, c.lightened(0.3) if yy < 0 else c)
			# Reflet sur le sol.
			for yy in range(floor_y + 2, mini(h, floor_y + int(s * 0.16)), 2):
				_rect(img, bx - u, yy, u * 2, 1, Color(c, 0.18 * (1.0 - float(yy - floor_y) / (s * 0.16))))
		bx += bay
		i += 1
	# Grand cristal central sur son autel, cercle gravé au sol.
	var ay := floor_y + int((h - floor_y) * 0.35)
	_ellipse(img, cx, ay + u * 2, int(s * 0.22), maxi(u * 2, int(s * 0.05)), Color("221e3a"))
	_ring(img, cx, ay + u * 2, int(s * 0.2), maxi(u * 2, int(s * 0.045)), Color("4fe3d2"))
	_ring(img, cx, ay + u * 2, int(s * 0.14), maxi(u, int(s * 0.03)), Color("9ff0ff"))
	_rect(img, cx - u * 6, ay - u * 6, u * 12, u * 8, Color("3a3456"))
	_rect(img, cx - u * 7, ay - u * 6, u * 14, u, Color("5a5480"))
	var gy := ay - int(s * 0.2)
	_glow(img, cx, gy, int(s * 0.28), Color("4fe3d2"), 0.32)
	var ch := int(s * 0.11)
	for yy in range(-ch, ch + 1):
		var half := int(float(ch) * 0.42 * (1.0 - absf(float(yy)) / float(ch)))
		_rect(img, cx - half, gy + yy, half, 1, Color("2a9a9a"))
		_rect(img, cx, gy + yy, half + 1, 1, Color("8ff0e8"))
	_rect(img, cx, gy - ch, 1, ch * 2, Color("e8ffff"))
	for k in range(10):
		var a := float(k) * TAU / 10.0
		_px(img, cx + int(cos(a) * s * 0.17), gy + int(sin(a) * s * 0.05), Color("bff6ff"))


## Atelier (options) : engrenages de laiton au mur, sphère armillaire sur le bureau, fioles et chandelles.
static func _atelier(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var s := mini(w, h)
	var u := maxi(1, s / 60)
	var cx := w / 2
	var floor_y := int(h * 0.72)
	var x := 0
	while x < w:
		var pw := u * 8
		_rect(img, x, 0, pw, floor_y, Color("2e2218").lightened(rng.randf_range(-0.05, 0.05)))
		_rect(img, x, 0, 1, floor_y, Color("1e140e"))
		x += pw
	_rect(img, 0, int(h * 0.42), w, u * 2, Color("4a3424"))
	_planks(img, rng, floor_y, Color("24180e"))
	# Engrenages.
	var gears := [[-0.26, 0.2, 0.12, 12], [-0.1, 0.32, 0.07, 9], [0.22, 0.14, 0.09, 10], [0.33, 0.3, 0.06, 8], [-0.4, 0.38, 0.06, 8], [0.46, 0.2, 0.1, 11], [-0.55, 0.16, 0.08, 10]]
	for g in gears:
		var gx := cx + int(float(g[0]) * s)
		var gy := int(float(g[1]) * h)
		if gx < -s * 0.15 or gx > w + s * 0.15:
			continue
		_gear(img, gx, gy, int(float(g[2]) * s), int(g[3]), Color("8a6a2a"), Color("c8a050"), float(g[0]) * 3.0)
	# Étagère de fioles à droite.
	var sx := cx + int(s * 0.2)
	var sy := int(h * 0.52)
	_rect(img, sx, sy, int(s * 0.28), u, Color("5a3a22"))
	for k in range(5):
		var fc: Color = [Color("4fe3d2"), Color("c82a5a"), Color("f2c46b"), Color("7ad16a"), Color("b07cff")][k]
		var fx := sx + u * 2 + k * u * 5
		_rect(img, fx, sy - u * 4, u * 3, u * 4, fc)
		_rect(img, fx + u, sy - u * 6, u, u * 2, Color("c8c0b0"))
		_px(img, fx, sy - u * 4, fc.lightened(0.5))
	# Bureau et sphère armillaire.
	var dy := floor_y - u * 2
	_rect(img, cx - int(s * 0.34), dy, int(s * 0.68), u * 3, Color("5a3a22"))
	_rect(img, cx - int(s * 0.34), dy, int(s * 0.68), 1, Color("8a5a32"))
	_rect(img, cx - int(s * 0.3), dy + u * 3, u * 2, h - dy, Color("3a2416"))
	_rect(img, cx + int(s * 0.3) - u * 2, dy + u * 3, u * 2, h - dy, Color("3a2416"))
	var ay := dy - int(s * 0.17)
	var r := int(s * 0.12)
	_rect(img, cx - 1, ay + r, 2, dy - ay - r, Color("8a6a2a"))
	_rect(img, cx - u * 4, dy - u, u * 8, u, Color("8a6a2a"))
	_glow(img, cx, ay, int(r * 1.4), Color("4fe3d2"), 0.25)
	_ring(img, cx, ay, r, r, Color("c8a050"))
	_ring(img, cx, ay, r, r / 3, Color("d8b04a"))
	_ring(img, cx, ay, r / 3, r, Color("a88a3a"))
	_ring(img, cx, ay, int(r * 0.8), int(r * 0.55), Color("c8a050"), -0.6, PI - 0.6)
	StoryArt._disc(img, cx, ay, maxi(2, r / 5), Color("9ff0ff"))
	# Parchemin, plume et chandelles.
	_rect(img, cx - int(s * 0.28), dy - u, u * 10, u, Color("e8dcc0"))
	_line(img, cx - int(s * 0.2), dy - u, cx - int(s * 0.16), dy - u * 7, Color("e8e8f0"))
	_candle(img, cx + int(s * 0.18), dy, u * 4)
	_candle(img, cx + int(s * 0.23), dy, u * 3)
	_candle(img, cx - int(s * 0.12), dy, u * 2)


## Création du personnage : cercle de pierres levées sur un plateau, cercle d'invocation et colonne de lumière.
static func _creation(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var s := mini(w, h)
	var u := maxi(1, s / 60)
	var cx := w / 2
	var hz := int(h * 0.56)
	StoryArt._sky(img, rng, [[0.0, Color("040418")], [0.4, Color("141440")], [0.56, Color("2a2a5a")], [1.0, Color("2a2a5a")]], 1.2)
	# Aurore.
	for x in range(w):
		var yb := int(h * 0.2 + sin(float(x) * 0.035) * h * 0.05 + sin(float(x) * 0.011) * h * 0.04)
		for j in range(int(h * 0.12)):
			var k := float(j) / (h * 0.12)
			_px(img, x, yb + j, Color(Color("4fe3d2").lerp(Color("b07cff"), k), 0.14 * (1.0 - k)))
	StoryArt._moon(img, cx + int(s * 0.3), int(h * 0.1), maxi(4, int(s * 0.04)))
	for k in range(-3, 4):
		StoryArt._peak(img, cx + k * int(s * 0.26) + rng.randi_range(-10, 10), hz, int(s * 0.22), int(s * rng.randf_range(0.1, 0.2)), Color("161838"), Color("3a3e70"))
	for y in range(hz, h):
		var k := float(y - hz) / float(maxi(1, h - hz))
		_rect(img, 0, y, w, 1, Color("1c1e36").lerp(Color("0a0a18"), k))
	var gy := hz + int((h - hz) * 0.45)
	var rx := int(s * 0.42)
	var ry := maxi(u * 4, int(s * 0.12))
	# Colonne de lumière.
	for y in range(0, gy):
		var k := float(y) / float(maxi(1, gy))
		var half := int(float(u) * (3.0 + 4.0 * k))
		_rect(img, cx - half, y, half * 2, 1, Color(0.6, 0.95, 1.0, 0.05 + 0.14 * k))
		_rect(img, cx - 1, y, 2, 1, Color(0.85, 1.0, 1.0, 0.1 + 0.3 * k))
	# Cercle d'invocation.
	_glow(img, cx, gy, int(rx * 0.8), Color("4fe3d2"), 0.25)
	_ring(img, cx, gy, int(rx * 0.62), int(ry * 0.62), Color("9ff0ff"))
	_ring(img, cx, gy, int(rx * 0.5), int(ry * 0.5), Color("4fe3d2"))
	_ring(img, cx, gy, int(rx * 0.3), int(ry * 0.3), Color("c8b0ff"))
	for i in range(12):
		var a := float(i) * TAU / 12.0
		_rect(img, cx + int(cos(a) * rx * 0.56), gy + int(sin(a) * ry * 0.56) - 1, 2, 2, Color("ffffff"))
	# Pierres levées, de l'arrière vers l'avant.
	var stones: Array = []
	for i in range(9):
		var a := float(i) * TAU / 9.0 + 0.2
		stones.append([sin(a), cos(a)])
	stones.sort_custom(func(p: Array, q: Array) -> bool: return float(p[0]) < float(q[0]))
	for st in stones:
		var py := gy + int(float(st[0]) * ry)
		var px := cx + int(float(st[1]) * rx)
		var near := (float(st[0]) + 1.0) * 0.5
		var sh := int(s * (0.1 + 0.08 * near))
		var sw := maxi(u * 2, int(s * (0.025 + 0.015 * near)))
		_rect(img, px - sw, py - sh, sw * 2, sh, Color("3a3e54"))
		_rect(img, px - sw, py - sh, u, sh, Color("262a3c"))
		_rect(img, px + sw - u, py - sh, u, sh, Color("5a6080"))
		_rect(img, px - sw, py - sh, sw * 2, u, Color("4a5070"))
		_rect(img, px - u, py - sh / 2, u * 2, u, Color("4fe3d2"))
	StoryArt._mist(img, rng, gy - u * 4, h - 2, Color(0.6, 0.7, 1.0, 0.1), 30)


## Préparation : tente de commandement, table de guerre avec sa carte et ses pions, lanterne, bannières.
static func _camp(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var s := mini(w, h)
	var u := maxi(1, s / 60)
	var cx := w / 2
	var floor_y := int(h * 0.7)
	# Toile rayée.
	var x := 0
	var stripe := u * 6
	while x < w:
		_rect(img, x, 0, stripe, floor_y, Color("4a3a28") if (x / stripe) % 2 == 0 else Color("56442e"))
		x += stripe
	# Pans du toit qui convergent vers le mât.
	for y in range(0, int(h * 0.3)):
		var k := float(y) / (h * 0.3)
		var half := int(lerpf(float(u) * 4.0, float(w) * 0.75, k))
		_rect(img, 0, y, cx - half, 1, Color("3a2c1e"))
		_rect(img, cx + half, y, w - cx - half, 1, Color("3a2c1e"))
	_rect(img, cx - u, 0, u * 2, floor_y, Color("5a3a22"))
	# Ouverture sur le crépuscule.
	var ot := int(h * 0.2)
	for y in range(ot, floor_y):
		var k := float(y - ot) / float(maxi(1, floor_y - ot))
		var half := int(k * s * 0.16)
		var c := Color("2a1a3e").lerp(Color("d8784a"), k)
		_rect(img, cx - half, y, half * 2, 1, c)
		_px(img, cx - half - 1, y, Color("6a5236"))
		_px(img, cx + half, y, Color("6a5236"))
	for y in range(floor_y - int(s * 0.04), floor_y):
		var half := int(float(y - ot) / float(maxi(1, floor_y - ot)) * s * 0.16)
		_rect(img, cx - half, y, half * 2, 1, Color("2a2030"))
	for i in range(3):
		StoryArt._tent(img, cx - int(s * 0.08) + i * int(s * 0.08), floor_y - int(s * 0.02), u * 3)
	_rect(img, cx - u, ot, u * 2, floor_y - ot, Color("5a3a22"))
	# Sol de terre battue et tapis.
	for y in range(floor_y, h):
		var k := float(y - floor_y) / float(maxi(1, h - floor_y))
		_rect(img, 0, y, w, 1, Color("2a2016").lerp(Color("16100a"), k))
	# Bannières.
	for sx: int in [-1, 1]:
		var bx := cx + sx * int(s * 0.32)
		var bc := Color("1e5a5a") if sx < 0 else Color("7a2a22")
		_rect(img, bx, int(h * 0.12), 1, floor_y - int(h * 0.12), Color("4a3020"))
		for y in range(int(h * 0.14), int(h * 0.14) + int(s * 0.3)):
			var cut := maxi(0, y - (int(h * 0.14) + int(s * 0.24)))
			_rect(img, bx + 1 + cut / 2, y, u * 7 - cut, 1, bc)
		_rect(img, bx + u * 2, int(h * 0.14) + u * 6, u * 3, u * 3, Color("f2c46b"))
	# Râtelier et coffre.
	var rx := cx - int(s * 0.46)
	if rx > -u * 8:
		_rect(img, rx - u * 5, floor_y - u * 14, u * 10, u, Color("4a3020"))
		for j in range(4):
			_weapon(img, rx - u * 4 + j * u * 3, floor_y, u * 14, j)
	var kx := cx + int(s * 0.44)
	_rect(img, kx - u * 6, floor_y - u * 2, u * 12, u * 6, Color("5a3a22"))
	_rect(img, kx - u * 6, floor_y - u * 2, u * 12, 1, Color("d8b04a"))
	# Table de guerre.
	var ty := floor_y + int((h - floor_y) * 0.3)
	var tw := int(s * 0.36)
	for i in range(u * 8):
		var half := tw - u * 4 + i / 2
		_rect(img, cx - half, ty + i, half * 2, 1, Color("5a3a22"))
	_rect(img, cx - tw, ty + u * 8, tw * 2, u * 2, Color("3a2416"))
	_rect(img, cx - tw + u * 2, ty + u * 10, u * 2, h - ty, Color("2a1a10"))
	_rect(img, cx + tw - u * 4, ty + u * 10, u * 2, h - ty, Color("2a1a10"))
	for i in range(u * 6):
		var half := tw - u * 7 + i / 2
		_rect(img, cx - half, ty + u + i, half * 2, 1, Color("d8c8a0"))
	_line(img, cx - tw + u * 9, ty + u * 2, cx + u * 2, ty + u * 6, Color("4a7aaa"))
	for i in range(6):
		_px(img, cx - u * 6 + i * u * 3, ty + u * 3 + (i % 2), Color("c82a2a"))
	for p in [[-0.2, 3, "c82a2a"], [0.05, 2, "2a6aaa"], [0.15, 5, "c82a2a"], [-0.05, 4, "f2c46b"]]:
		var px := cx + int(float(p[0]) * s)
		var py := ty + int(p[1]) * u
		_rect(img, px, py - u * 2, u, u * 2, Color(str(p[2])))
		_px(img, px, py - u * 2 - 1, Color(str(p[2])).lightened(0.4))
	# Lanterne suspendue.
	var ly := int(h * 0.38)
	_rect(img, cx, int(h * 0.3), 1, ly - int(h * 0.3), Color("3a2a1e"))
	_glow(img, cx, ly + u * 3, int(s * 0.28), Color("ffb050"), 0.3)
	_rect(img, cx - u * 2, ly, u * 4, u * 5, Color("3a2a1e"))
	_rect(img, cx - u, ly + u, u * 2, u * 3, Color("ffd070"))
	_candle(img, cx + int(s * 0.2), ty + u * 2, u * 2)
