class_name FxArt
extends RefCounted
## Textures pixel-art des effets de sorts, générées par code et mises en cache.

static var _cache: Dictionary = {}


static func _cached(key: String) -> ImageTexture:
	return _cache.get(key, null)


static func _store(key: String, img: Image) -> ImageTexture:
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Boule de feu (12 px) ou météore arcanique (16 px) : anneaux de couleur du cœur vers le bord.
static func orb(kind: String) -> ImageTexture:
	var key := "orb_" + kind
	if _cache.has(key):
		return _cached(key)
	var n := 16 if kind == "meteor" else 12
	var rings: Array = ["fff6c8", "ffd45a", "ff8a2a", "c8402a"]
	if kind == "meteor":
		rings = ["ffffff", "e8d0ff", "b07cff", "8e62e0", "ff9b4a"]
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := (float(n) - 1.0) * 0.5
	for y in range(n):
		for x in range(n):
			# Lumière en haut à droite : le cœur est décalé vers le haut-droit.
			var d := Vector2(float(x) - c - 0.8, float(y) - c + 0.8).length() / (c + 0.5)
			var e := Vector2(float(x) - c, float(y) - c).length() / (c + 0.5)
			if e > 1.0:
				continue
			var i := clampi(int(d * float(rings.size())), 0, rings.size() - 1)
			img.set_pixel(x, y, Color(str(rings[i])))
	# Contour sombre.
	var src := img.duplicate() as Image
	for y in range(n):
		for x in range(n):
			if src.get_pixel(x, y).a > 0.0:
				continue
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + dd
				if q.x >= 0 and q.y >= 0 and q.x < n and q.y < n and src.get_pixel(q.x, q.y).a > 0.0:
					img.set_pixel(x, y, Color("3a1206") if kind != "meteor" else Color("1a1035"))
					break
	return _store(key, img)


## Halo doux (pour les éclairs de lumière, en mélange additif).
## Orbe teinté à la couleur d'un sort (projectiles autres que la Boule de feu).
static func orb_tint(col: Color) -> ImageTexture:
	var key := "orbt_" + col.to_html(false)
	if _cache.has(key):
		return _cached(key)
	var n := 12
	var rings: Array = [Color.WHITE, col.lightened(0.55), col, col.darkened(0.35)]
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := (float(n) - 1.0) * 0.5
	for y in range(n):
		for x in range(n):
			var d := Vector2(float(x) - c - 0.8, float(y) - c + 0.8).length() / (c + 0.5)
			var e := Vector2(float(x) - c, float(y) - c).length() / (c + 0.5)
			if e > 1.0:
				continue
			img.set_pixel(x, y, rings[clampi(int(d * float(rings.size())), 0, rings.size() - 1)])
	var src := img.duplicate() as Image
	for y in range(n):
		for x in range(n):
			if src.get_pixel(x, y).a > 0.0:
				continue
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + dd
				if q.x >= 0 and q.y >= 0 and q.x < n and q.y < n and src.get_pixel(q.x, q.y).a > 0.0:
					img.set_pixel(x, y, col.darkened(0.75))
					break
	return _store(key, img)


static func flash() -> ImageTexture:
	if _cache.has("flash"):
		return _cached("flash")
	var n := 32
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in range(n):
		for x in range(n):
			var d := Vector2(float(x) - 15.5, float(y) - 15.5).length() / 16.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return _store("flash", img)


## Brûlure au sol (disque sombre aux bords irréguliers).
static func scorch() -> ImageTexture:
	if _cache.has("scorch"):
		return _cached("scorch")
	var n := 32
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for y in range(n):
		for x in range(n):
			var d := Vector2(float(x) - 15.5, float(y) - 15.5).length() / 16.0 + rng.randf_range(-0.08, 0.08)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.08, 0.04, 0.05, minf(0.75, a * 1.4)))
	return _store("scorch", img)


## Sols du terrain interactif (scripts/battle/terrain.gd), vus de dessus, bords transparents.
static func ground(kind: String) -> ImageTexture:
	var key := "ground_" + kind
	if _cache.has(key):
		return _cached(key)
	var n := 64
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var c := (float(n) - 1.0) * 0.5
	var base := Color(0, 0, 0, 0)
	var alpha := 0.6
	match kind:
		"braises":
			base = Color("2a1610")
			alpha = 0.85
		"verglas":
			base = Color("bfe8ff")
			alpha = 0.6
		"eau":
			base = Color("2f6aa8")
			alpha = 0.6
		"miasme":
			base = Color("4a2278")
			alpha = 0.5
		"statique":
			base = Color("1e1a3a")
			alpha = 0.45
		"cratere":
			base = Color("1e1510")
			alpha = 0.9
		"faille":
			base = Color("0e0a08")
			alpha = 0.95
		"poison":
			base = Color("4a7a2a")
			alpha = 0.75
		"glace":
			base = Color("cfeaff")
			alpha = 0.62
	# Disque aux bords irréguliers (sauf runes, gravats et fissures, dessinés à part).
	if not kind in ["rune", "gravats", "fissure"]:
		for y in range(n):
			for x in range(n):
				var d := Vector2(float(x) - c, float(y) - c).length() / (c + 0.5) + rng.randf_range(-0.06, 0.06)
				if d > 1.0:
					continue
				var a := alpha * clampf((1.0 - d) * 3.0, 0.0, 1.0)
				var col := base
				if kind == "cratere":
					# Fond sombre, bord relevé éclairé.
					col = base.lerp(Color("6a5038"), clampf((d - 0.45) / 0.4, 0.0, 1.0))
					if d > 0.78 and d < 0.9:
						col = Color("8a7050")
					a = clampf((1.0 - d) * 6.0, 0.0, 1.0) * alpha
				elif kind == "eau" and int(d * 9.0) % 3 == 0:
					col = base.lightened(0.25)
				elif kind == "poison" and rng.randf() < 0.06:
					col = Color("a8d050")
				elif kind == "glace":
					# Glace lisse : reflets clairs en diagonale et craquelures.
					if (x + y) % 11 < 2:
						col = Color("f4fbff")
					elif d > 0.85:
						col = Color("9fd0f0")
				img.set_pixel(x, y, Color(col, a))
	match kind:
		"braises":
			for k in range(7):
				var p := Vector2(c, c)
				var dir := Vector2.from_angle(rng.randf() * TAU)
				for st in range(26):
					if p.distance_to(Vector2(c, c)) > c * 0.85:
						break
					img.set_pixel(int(p.x), int(p.y), Color("ff8a3a") if st % 4 != 0 else Color("ffd070"))
					dir = dir.rotated(rng.randf_range(-0.6, 0.6))
					p += dir
			for k in range(30):
				var q := Vector2.from_angle(rng.randf() * TAU) * rng.randf() * c * 0.8 + Vector2(c, c)
				img.set_pixel(int(q.x), int(q.y), Color("ffb04a"))
		"verglas":
			for k in range(6):
				var p := Vector2.from_angle(rng.randf() * TAU) * rng.randf() * c * 0.5 + Vector2(c, c)
				var dir := Vector2.from_angle(rng.randf() * TAU)
				for st in range(20):
					if p.distance_to(Vector2(c, c)) > c * 0.9:
						break
					img.set_pixel(int(p.x), int(p.y), Color(1, 1, 1, 0.9))
					p += dir
			for k in range(14):
				var q := Vector2.from_angle(rng.randf() * TAU) * rng.randf() * c * 0.8 + Vector2(c, c)
				img.set_pixel(int(q.x), int(q.y), Color.WHITE)
		"statique":
			for k in range(5):
				var p := Vector2(c, c)
				var dir := Vector2.from_angle(rng.randf() * TAU)
				for st in range(30):
					if p.distance_to(Vector2(c, c)) > c * 0.9:
						break
					img.set_pixel(int(p.x), int(p.y), Color("f0d23c"))
					p += dir.rotated(rng.randf_range(-1.0, 1.0))
		"miasme":
			for k in range(24):
				var q := Vector2.from_angle(rng.randf() * TAU) * rng.randf() * c * 0.75 + Vector2(c, c)
				var r := rng.randi_range(2, 5)
				for y in range(-r, r + 1):
					for x in range(-r, r + 1):
						if x * x + y * y <= r * r:
							var px := clampi(int(q.x) + x, 0, n - 1)
							var py := clampi(int(q.y) + y, 0, n - 1)
							img.set_pixel(px, py, img.get_pixel(px, py).lerp(Color(0.55, 0.3, 0.85, 0.55), 0.4))
		"piege":
			# Piège posé (grimoire de l'Archer) : mâchoires en couronne, teintées à la couleur du sort.
			for a in range(0, 360, 2):
				var v := Vector2.from_angle(deg_to_rad(float(a)))
				var q: Vector2 = v * c * 0.62 + Vector2(c, c)
				img.set_pixel(int(q.x), int(q.y), Color(0.85, 0.85, 0.85))
			for k in range(12):
				var a0 := float(k) * TAU / 12.0
				var a1 := (float(k) + 0.5) * TAU / 12.0
				var a2 := float(k + 1) * TAU / 12.0
				for st in range(14):
					var f := float(st) / 13.0
					var q1 := (Vector2.from_angle(a0) * c * 0.62).lerp(Vector2.from_angle(a1) * c * 0.9, f) + Vector2(c, c)
					var q2 := (Vector2.from_angle(a1) * c * 0.9).lerp(Vector2.from_angle(a2) * c * 0.62, f) + Vector2(c, c)
					img.set_pixel(int(q1.x), int(q1.y), Color.WHITE)
					img.set_pixel(int(q2.x), int(q2.y), Color.WHITE)
			for k in range(4):
				var v2 := Vector2.from_angle(float(k) * TAU / 4.0 + 0.4) * c * 0.25 + Vector2(c, c)
				img.set_pixel(int(v2.x), int(v2.y), Color.WHITE)
		"rune":
			for a in range(0, 360, 2):
				var v := Vector2.from_angle(deg_to_rad(float(a)))
				for rr in [c * 0.9, c * 0.75]:
					var q: Vector2 = v * rr + Vector2(c, c)
					img.set_pixel(int(q.x), int(q.y), Color("d8c0ff"))
			var tri := [Vector2(c, c * 0.35), Vector2(c * 1.55, c * 1.45), Vector2(c * 0.45, c * 1.45)]
			for k in range(3):
				var a0: Vector2 = tri[k]
				var b0: Vector2 = tri[(k + 1) % 3]
				for st in range(40):
					var q := a0.lerp(b0, float(st) / 39.0)
					img.set_pixel(int(q.x), int(q.y), Color("b07cff"))
			for k in range(8):
				var v := Vector2.from_angle(float(k) * TAU / 8.0) * c * 0.82 + Vector2(c, c)
				img.set_pixel(int(v.x), int(v.y), Color.WHITE)
		"gravats":
			for k in range(26):
				var q := Vector2.from_angle(rng.randf() * TAU) * rng.randf() * c * 0.85 + Vector2(c, c)
				var r := rng.randi_range(1, 4)
				var sc := Color("8a7a60").lerp(Color("5a4a3a"), rng.randf())
				for y in range(-r, r + 1):
					for x in range(-r, r + 1):
						if absi(x) + absi(y) <= r:
							img.set_pixel(clampi(int(q.x) + x, 0, n - 1), clampi(int(q.y) + y, 0, n - 1), sc if y > -r / 2 else sc.lightened(0.25))
		"fissure":
			for k in range(4):
				var p := Vector2(c, c)
				var dir := Vector2.from_angle(rng.randf() * TAU)
				for st in range(34):
					if p.distance_to(Vector2(c, c)) > c * 0.95:
						break
					img.set_pixel(int(p.x), int(p.y), Color("140e0a"))
					img.set_pixel(clampi(int(p.x) + 1, 0, n - 1), int(p.y), Color(0.08, 0.05, 0.04, 0.6))
					dir = dir.rotated(rng.randf_range(-0.5, 0.5))
					p += dir
		"faille":
			# Bords déchiquetés : un liseré clair autour du gouffre.
			var src := img.duplicate() as Image
			for y in range(n):
				for x in range(n):
					if src.get_pixel(x, y).a > 0.3:
						continue
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var q: Vector2i = Vector2i(x, y) + d
						if q.x >= 0 and q.y >= 0 and q.x < n and q.y < n and src.get_pixel(q.x, q.y).a > 0.3:
							img.set_pixel(x, y, Color("6a5038"))
							break
	return _store(key, img)


## Colonne de lumière : lumineuse au centre, s'efface en haut.
static func beam() -> ImageTexture:
	if _cache.has("beam"):
		return _cached("beam")
	var w := 16
	var h := 64
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var fy := clampf(float(y) / float(h) * 1.4, 0.0, 1.0)
		for x in range(w):
			var fx := 1.0 - absf(float(x) - 7.5) / 8.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(fx * fx * fy, 0.0, 1.0)))
	return _store("beam", img)


## Racine épineuse qui sort du sol (2 variantes, 12×26 px, base en bas).
static func root(variant: int) -> ImageTexture:
	var key := "root_%d" % variant
	if _cache.has(key):
		return _cached(key)
	var w := 12
	var h := 26
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color("1f3a1e")
	var mid := Color("3f6a32")
	var light := Color("8fd16a")
	var bark := Color("5a4030")
	var ph := 0.0 if variant == 0 else 1.7
	for y in range(h):
		var k := float(h - 1 - y) / float(h - 1)
		var cx := 5.5 + sin(k * 5.0 + ph) * 2.2 * k
		var half := lerpf(2.2, 0.4, k)
		for x in range(w):
			var dx := float(x) - cx
			if absf(dx) <= half:
				var c := mid
				if dx > half - 1.0:
					c = light
				elif dx < -half + 1.0:
					c = dark
				if y > h - 5:
					c = bark if dx <= 0.0 else bark.lightened(0.2)
				img.set_pixel(x, y, c)
		# Épines.
		if y % 5 == 2 and y < h - 4:
			var side := 1 if (y / 5) % 2 == 0 else -1
			var tx := int(round(cx + float(side) * (half + 1.0)))
			if tx >= 0 and tx < w:
				img.set_pixel(tx, y, Color("c8f5a0"))
	# Contour.
	var src := img.duplicate() as Image
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.0:
				continue
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + dd
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixel(q.x, q.y).a > 0.0:
					img.set_pixel(x, y, Color("120e1a"))
					break
	return _store(key, img)


# ---------------------------------------------------------------- éléments des animations de sorts

## Petits sprites des animations propres à chaque sort (scripts/battle/spell_sig.gd). Lettres :
## K contour, D/C/L/W teinte du sort (sombre, base, claire, blanc), b/B os, e orbites, g/G/h pierre,
## w bois, m/M métal, y or, v/n végétal, p rose, r baie rouge.
const SPRITES := {
	"shard": ["..K..", ".KLK.", ".KWK.", "KLWCK", "KLCCK", "KCCDK", "KCCDK", ".KCK.", ".KCK.", ".KDK.", "..K.."],
	"crystal": ["...K...", "..KWK..", "..KLK..", ".KLWCK.", ".KLCCK.", ".KLCCK.", ".KLCDK.", "KLWCCDK", "KLCCCDK", "KLCCCDK",
		"KLCCDDK", "KLCCDDK", "KCCCDDK", "KCCDDDK", "KKKKKKK"],
	"rock": ["..KKKK...", ".KLLCCK..", "KLLCCCDKK", "KLCCCDDDK", "KCCCDDDDK", ".KCDDDDK.", "..KKDDK..", "....KK..."],
	"bone": [".KK.....KK.", "KbbKKKKKbbK", ".KbbbbbbbK.", "KbBKKKKKBbK", ".KK.....KK."],
	"skull": [".KKKKKK.", "KbbbbbbK", "KbbbbbbK", "KeebbeeK", "KeebbeeK", "KbbbebbK", ".KbbbbK.", ".KbKbKK."],
	"star": ["....K....", "...KWK...", "...KWK...", "KKKLWLKKK", "KLWWWWWLK", "KKKLWLKKK", "...KWK...", "...KWK...", "....K...."],
	"blade": ["..K..", ".KyK.", "..K..", "KyyyK", ".KmK.", ".KmK.", ".KWK.", ".KmK.", ".KWK.", ".KmK.", ".KmK.", ".KWK.", ".KMK.", "..K..", "..K.."],
	"arrow": ["K...K", "KC.CK", ".KCK.", "..w..", "..w..", "..w..", "..w..", "..w..", "..w..", ".KmK.", ".KmK.", "..K.."],
	"feather": ["...KK.", "..KWLK", ".KWLLK", ".KWLCK", "KWLLCK", "KWLCK.", "KLLCK.", "KLCK..", ".KCK..", ".KK...", "K....."],
	"leaf": ["....KK.", "..KKLK.", ".KLLCK.", "KLCCK..", "KCCK...", "KK....."],
	"bulb": ["..KKKKK..", ".KpCpCpK.", "KpCWCpCpK", "KCpCpCpCK", ".KpCpCpK.", "..KKKKK..", "....v....", "...Kv....", "....vK...", "...KvK...", "..KvvvK.."],
	"axe": ["........KKK.", ".......KmmmK", "......KmmWmK", ".....KwKmmmK", "....KwK.KmK.", "...KwK...K..", "..KwK.......", ".KwK........", "KwK.........", "KK.........."],
	"tomb": ["..KKKK..", ".KgGGgK.", "KgGGGGgK", "KgGhhGgK", "KghhhhgK", "KghhhhgK", "KgGhhGgK", "KgGhhGgK", "KggggggK", "KhhhhhhK", "KKKKKKKK"],
	"hand": ["K.K.K..", "b.b.bK.", "b.b.b.b", "bKbKbKb", "bbbbbbK", ".bbbbb.", ".KbbbK.", "..bbb..", "..KbK..", "..bbb.."],
	"ghost": ["...KKKK...", "..KWWLLK..", ".KWWLLLLK.", ".KWeLLeLK.", ".KWeLLeLK.", "KWWLLLLLLK", "KWLLLLLLCK", "KWLLLLLLCK",
		"KLLLLLLCCK", "KLLLLLCCCK", "KLLCLLCLCK", "KLK.KCK.KK", ".K...K...."],
	"spear": [".W.", "KLK", "KLK", "KCK", "KCK", "KCK", "DCD", ".D.", ".D.", ".D.", ".D.", ".D.", ".D.", ".D."],
	"bramble": ["...K....", "..KnK.r.", "..KvK.K.", ".rKvKKvK", ".KvvKvK.", "..KvvK..", "KvK.vK..", ".KvKvK.r", "..KvvKKv", "...KvvK.",
		"...KvK..", "..KvvK..", "..KnnK..", "..KnnK.."],
	"spark": ["..L..", ".LWL.", "LWWWL", ".LWL.", "..L.."],
	"slab": ["KKKKKKKKK", "KWLLLLLCK", "KLLCCCCDK", "KLCCCCCDK", "KLCCCCDDK", "KLCCCCDDK", "KLCCCDDDK", "KCCCCDDDK", "KCCCDDDDK", "KKKKKKKKK"],
	"shield": [".KKKKK.", "KLWWWLK", "KLWCWLK", "KLCCCLK", "KLWCWLK", ".KLCLK.", "..KLK..", "...K..."],
	# Grimoire de l'Archer.
	"paw": [".K.K.K.", "KCKCKCK", ".K.K.K.", "..KKK..", ".KCCCK.", ".KCLCK.", "..KKK.."],
	"horn": ["........KK", "......KKLK", "KK..KKCCCK", "KLKKCCCCDK", "KCCCCCDDK.", ".KKKDDKK..", "....KK...."],
	"eye": ["..KKKKK..", ".KLLKLLK.", "KLLKCKLLK", ".KLLKLLK.", "..KKKKK.."],
	"moon": ["..KKK..", ".KLLK..", "KLLK...", "KLK....", "KLK....", "KLK....", "KLLK...", ".KLLK..", "..KKK.."],
	"caltrop": ["...K...", "..KLK..", "K.KLK.K", ".KLWLK.", "K.KCK.K", "..KCK..", "...K..."],
	"jaw": ["K.K.K.K.K.K", "KLKLKLKLKLK", "KLLLLLLLLLK", "KCCCCCCCCCK", ".KKKKKKKKK.", "....KwK...."],
	"stag": [".K.K........", "KLKLK.......", ".KLK........", "..KLK.......", "..KCCK......", "...KCCKKKKK.", "...KCCCCCCCK", "....KCCCCCK.", "....KCK.KCK.", "....KK..KK.."],
	"wolf": ["K...........", "KCK.........", "KCCKKKKKKK..", ".KCCCCCCCCKK", "KWCCCCCCCK..", ".KKCKKKKCK..", "...KK...KK.."],
	"flame": ["..K..", ".KLK.", ".KLK.", "KLWLK", "KCLCK", "KCCCK", ".KDK.", "..K.."],
	"drop": ["..K..", ".KLK.", ".KLK.", "KLWCK", "KCCCK", "KCCDK", ".KKK."],
	# Grimoire de l'Épéiste.
	"katana": ["..K...", ".KwK..", ".KwK..", "KyyyK.", ".KCK..", ".KCWK.", "..KCK.", "..KCK.", "..KCWK", "...KCK", "...KCK", "....KK"],
	"rapier": ["..K..", ".KwK.", "KyyyK", "KyKyK", "..C..", "..C..", "..W..", "..C..", "..C..", "..C..", "..W..", "..C..", "..K.."],
	"dagger": [".K.", "KwK", "KyK", "KCK", "KWK", "KCK", ".K."],
	"petal": ["..KK.", ".KLLK", "KLWLK", "KCLK.", ".KK.."],
	"falcon": ["K.........K", "KCK.....KCK", ".KCKK.KKCK.", "..KCCLCCK..", "...KCWCK...", "....KyK....", ".....K....."],
}
const FIXED := {"K": "120e1a", "b": "e8dcc0", "B": "a89c80", "e": "1a0f0a", "g": "8a7a60", "G": "b8a888", "h": "5a4a3a",
	"w": "8a5a2b", "m": "c8d0e0", "M": "7a8090", "y": "e0b850", "v": "6fbf4a", "n": "2f5a24", "p": "d87ab0", "r": "c83a2a"}


## Sprite d'animation teinté à la couleur du sort ; « quarter » le tourne de 90° × n (rotations).
static func sprite(name: String, col: Color, quarter: int = 0) -> ImageTexture:
	var key := "spr_%s_%s_%d" % [name, col.to_html(false), quarter]
	if _cache.has(key):
		return _cached(key)
	var rows: Array = SPRITES.get(name, SPRITES["spark"])
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, str(r).length())
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var tint := {"D": col.darkened(0.45), "C": col, "L": col.lightened(0.45), "W": col.lightened(0.85)}
	for y in range(h):
		var r := str(rows[y])
		for x in range(r.length()):
			var ch := r[x]
			if tint.has(ch):
				img.set_pixel(x, y, tint[ch])
			elif FIXED.has(ch):
				img.set_pixel(x, y, Color(str(FIXED[ch])))
	for i in range(posmod(quarter, 4)):
		img.rotate_90(CLOCKWISE)
	return _store(key, img)
