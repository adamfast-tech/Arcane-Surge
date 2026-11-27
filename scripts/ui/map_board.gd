class_name MapBoard
extends Control
## Carte d'une zone (docs/design/14-interface.md) : un terrain en pixel art propre à la zone, un sentier
## sinueux du premier niveau (en bas) jusqu'au boss (en haut), les décors de la zone le long du chemin,
## un médaillon par niveau (type, numéro, étoiles), le héros posté au prochain niveau, et une brume sur
## ce qui reste verrouillé. Le chemin parcouru brille d'or ; vers le prochain niveau, des pas sarcelle.

signal picked(level_id: String)

const S := 3 ## taille d'un pixel du décor (comme les accessoires des combats)
const GAP := 178.0 ## écart vertical entre deux niveaux
const BOTTOM := 140.0
const TOP := 200.0

## Type de niveau → icône et couleur du médaillon.
const KIND := {"Assaut": ["swords", "4fe3d2"], "Mini-boss": ["horns", "ff9b4a"], "Boss": ["skull", "ff6b6b"],
	"Escorte": ["flag", "6fdccf"], "Purification": ["purifier", "6fe39a"], "Siège": ["tower", "b07cff"]}

## Couleur d'emblème de chaque zone.
const ZONE_COL := {1: "8fe08a", 2: "f2b84b", 3: "9cc4a2", 4: "a6dcff", 5: "f0d48a", 6: "ff7a3a", 7: "4aa8ff"}

## Terrain : sol bas, sol haut, taches sombre/claire, plaques, bord et fond du chemin, détail du chemin.
const PAL := {
	1: ["1d3b2b", "0f241c", "122a20", "2a4d3a", "2c5a3a", "1a1410", "5e4a33", "7c6247"],
	2: ["8a6a32", "5e4422", "6e5026", "a07c3e", "93803a", "4e381a", "c4a068", "a88650"],
	3: ["2b3b2f", "1a2620", "1f2c25", "3a4c3c", "2f4a48", "1c160f", "6a5a40", "3e3324"],
	4: ["c6d6e6", "9fb4cc", "8ea6c4", "e4eef8", "a8d4f0", "7890a8", "e8f0f8", "c4d4e4"],
	5: ["d4b070", "b48c52", "c09a5a", "e6c486", "bff4ff", "6a5030", "a88a5a", "8a6e44"],
	6: ["2c2422", "181212", "1e1818", "3c3230", "ff6a2a", "100a0a", "463834", "ff8a3a"],
	7: ["123250", "081a2e", "0c2440", "1e4664", "3a5a6a", "0a1a28", "3a5a70", "2a4458"],
}

## Particules d'ambiance : couleur, nombre, mouvement.
const PARTS := {1: ["d8ff7a", 34, "wander"], 2: ["ffd27a", 26, "drift"], 3: ["b8d8c0", 18, "mist"], 4: ["ffffff", 46, "fall"],
	5: ["fff0c0", 26, "drift"], 6: ["ff8a3a", 40, "rise"], 7: ["9fd8ff", 32, "rise"]}

var zone := 1
var ids: Array = []
var selected := ""
var _pts: Array[Vector2] = [] ## centres des médaillons, du premier niveau au dernier
var _road := PackedVector2Array()
var _seg := PackedInt32Array() ## pour chaque point du chemin : le niveau vers lequel il mène
var _props: Array = [] ## [texture, région (Rect2() = toute), pied (Vector2), échelle]
var _medals: Dictionary = {}
var _parts := PackedVector2Array()
var _pphase := PackedFloat32Array()
var _fog: Array = [] ## [centre, rayon, teinte]
var _terrain: Texture2D
var _t := 0.0
var _anim := true
var _hero: Control ## le héros en volume (HeroTurntable), ou sa figure
var _hero_foot := Vector2.ZERO
var _hero_i := -1 ## niveau près duquel il se tient
var _walk := PackedVector2Array() ## trajet en cours (pieds), vide s'il ne marche pas
var _walk_d := 0.0 ## distance parcourue sur le trajet
var _walk_to := -1
const WALK_SPEED := 300.0 ## px par seconde
const IDLE_YAW := PI + 0.45 ## au repos : de trois quarts face
var _runs: Array = [] ## étapes du chemin, calculées une fois : [état, points]
var _base: Layer ## terrain, décors, chemin fixe, ombre du héros : dessinés une seule fois
var _dyn: Layer ## pas animés, anneau du héros, brume, particules : redessinés à chaque image
var _top: Layer ## vignette et cadre : dessinés une seule fois
var _rng := RandomNumberGenerator.new()

static var _cache: Dictionary = {}
static var _puff: GradientTexture2D


func setup(z: int, level_ids: Array, width: float) -> void:
	zone = z
	ids = level_ids
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	var n := ids.size()
	var h := BOTTOM + TOP + GAP * float(maxi(n - 1, 0))
	custom_minimum_size = Vector2(width, h)
	size = custom_minimum_size
	_anim = Profile.ambience_on()
	_rng.seed = 7919 * z + n
	# Centres des médaillons : un lacet de part et d'autre de la carte.
	_pts.clear()
	var phase := float(z) * 0.9
	for i in range(n):
		var x := width * (0.5 + 0.25 * sin(float(i) * 1.22 + phase))
		_pts.append(Vector2(x, h - BOTTOM - GAP * float(i)))
	_build_road(h)
	var key := "%d:%d:%d" % [z, int(width), n]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_paint(int(width) / S + 1, int(h) / S + 1))
	_terrain = _cache[key]
	_place_props(width, h)
	_build_runs()
	_build_medals()
	_build_fog(width)
	_build_parts(width, h)
	# Trois calques sous les médaillons, dans l'ordre de dessin : seul le calque animé se redessine à chaque
	# image ; le reste garde ses commandes de dessin (rien n'est recalculé).
	_base = _layer(0)
	_dyn = _layer(1)
	_top = _layer(2)
	set_process(_anim)


func _ready() -> void:
	set_process(_anim)


func _process(delta: float) -> void:
	_t += delta
	if not _walk.is_empty():
		_step_walk(delta)
	elif _hero != null and not (_hero is HeroTurntable):
		_hero.position.y = _hero_foot.y - _hero.size.y + sin(_t * 2.4) * 3.0
	for k in _medals:
		(_medals[k] as Medal).tick(_t)
	if _dyn != null:
		_dyn.queue_redraw()


## Centre du médaillon d'un niveau (pour faire défiler la carte jusqu'à lui).
func point_of(id: String) -> Vector2:
	var i := ids.find(id)
	return _pts[i] if i >= 0 else Vector2.ZERO


func select(id: String) -> void:
	selected = id
	for k in _medals:
		var m := _medals[k] as Medal
		m.selected = str(k) == id
		m.redraw()
	var i := ids.find(id)
	if i >= 0 and _hero is HeroTurntable and i != _hero_i and i != _walk_to:
		_start_walk(i)


# ---------------------------------------------------------------- le héros marche d'un niveau à l'autre

## Où le héros se tient près d'un niveau : à côté de son médaillon, du côté opposé à son nom.
func _stand_of(i: int) -> Vector2:
	var p := _pts[i]
	var right2 := p.x < size.x * 0.5
	var r := (_medals[str(ids[i])] as Medal).diameter * 0.5
	return Vector2(p.x + (-(r + 44.0) if right2 else r + 44.0), p.y + 34.0)


## Premier point du chemin au médaillon du niveau i.
func _road_index(i: int) -> int:
	for k in range(_seg.size()):
		if _seg[k] == i + 1:
			return k
	return _seg.size() - 1


## Trajet : il quitte sa place, suit le chemin jusqu'au médaillon choisi, puis s'écarte à côté de lui.
func _start_walk(i: int) -> void:
	var from_k := _road_index(_hero_i) if _walk.is_empty() else _nearest_road(_hero_foot)
	var to_k := _road_index(i)
	var path := PackedVector2Array([_hero_foot])
	var stepk := 1 if to_k >= from_k else -1
	var k := from_k
	while true:
		path.append(_road[k] + Vector2(0, 6))
		if k == to_k:
			break
		k += stepk
	path.append(_stand_of(i))
	_walk = path
	_walk_d = 0.0
	_walk_to = i
	(_hero as HeroTurntable).play("walk")
	set_process(true)


func _nearest_road(p: Vector2) -> int:
	var best := 0
	var bd := 1e18
	for k in range(_road.size()):
		var d := _road[k].distance_squared_to(p)
		if d < bd:
			bd = d
			best = k
	return best


func _step_walk(delta: float) -> void:
	_walk_d += WALK_SPEED * delta
	var left := _walk_d
	var pos := _walk[_walk.size() - 1]
	var dir := Vector2.ZERO
	var done := true
	for k in range(_walk.size() - 1):
		var a := _walk[k]
		var b := _walk[k + 1]
		var l := a.distance_to(b)
		if left <= l and l > 0.001:
			pos = a.lerp(b, left / l)
			dir = (b - a) / l
			done = false
			break
		left -= l
	_hero_foot = pos
	var tt := _hero as HeroTurntable
	_hero.position = Vector2(_hero_foot.x - _hero.size.x * 0.5, _hero_foot.y - _hero.size.y)
	if done:
		_walk = PackedVector2Array()
		_hero_i = _walk_to
		_walk_to = -1
		tt.yaw = IDLE_YAW
		tt.play("idle")
		set_process(_anim)
		if _dyn != null:
			_dyn.queue_redraw()
		return
	if dir.length() > 0.1:
		# Tourné dans le sens du trajet : vers le haut de la carte, on le voit de dos ; vers le bas, de face.
		var want := atan2(dir.x, -dir.y)
		tt.yaw = lerp_angle(tt.yaw, want, minf(1.0, delta * 10.0))
	if tt.current_anim() != "walk":
		tt.play("walk")


# ---------------------------------------------------------------- géométrie

func _build_road(h: float) -> void:
	_road = PackedVector2Array()
	_seg = PackedInt32Array()
	if _pts.is_empty():
		return
	var ctrl: Array[Vector2] = [Vector2(_pts[0].x, h + 40.0)]
	ctrl.append_array(_pts)
	var last := _pts[_pts.size() - 1]
	ctrl.append(Vector2(last.x + (40.0 if last.x < size.x * 0.5 else -40.0), last.y - 110.0))
	for k in range(ctrl.size() - 1):
		var p0 := ctrl[maxi(k - 1, 0)]
		var p1 := ctrl[k]
		var p2 := ctrl[k + 1]
		var p3 := ctrl[mini(k + 2, ctrl.size() - 1)]
		var steps := int(p1.distance_to(p2) / 3.0) + 2
		for s in range(steps):
			var t := float(s) / float(steps)
			_road.append(_catmull(p0, p1, p2, p3, t))
			_seg.append(k) ## k = 0 : l'entrée de la zone, vers le premier niveau


static func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


func _dist_road(p: Vector2) -> float:
	var best := 1e9
	for i in range(0, _road.size(), 4):
		best = minf(best, p.distance_squared_to(_road[i]))
	return sqrt(best)


## État de l'étape k du chemin : « done » (parcourue), « next » (vers le prochain niveau) ou « locked ».
func _seg_state(k: int) -> String:
	if k >= ids.size():
		return "done" if _cleared(ids.size() - 1) else "locked"
	if _cleared(k) and (k == 0 or _cleared(k - 1)):
		return "done"
	if Profile.is_unlocked(str(ids[k])):
		return "next"
	return "locked"


func _cleared(i: int) -> bool:
	return i >= 0 and i < ids.size() and int(Profile.level_record(str(ids[i]))["clears"]) > 0


# ---------------------------------------------------------------- terrain

func _paint(w: int, h: int) -> Image:
	var pal: Array = PAL.get(zone, PAL[1])
	var c_lo := Color(str(pal[0]))
	var c_hi := Color(str(pal[1]))
	var c_dk := Color(str(pal[2]))
	var c_lt := Color(str(pal[3]))
	var c_patch := Color(str(pal[4]))
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var f := 1.0 - float(y) / float(h)
		# Dégradé en paliers (aspect pixel art) : le bas de la carte est plus clair, l'antre du boss plus sombre.
		var q := floorf(f * 7.0) / 7.0
		img.fill_rect(Rect2i(0, y, w, 1), c_lo.lerp(c_hi, 1.0 - q))
	var rng := RandomNumberGenerator.new()
	rng.seed = 101 * zone
	# Plaques (mousse, flaques, congères, dunes, cendres, sable).
	for i in range(int(float(w * h) / 900.0)):
		var cx := rng.randi_range(0, w)
		var cy := rng.randi_range(0, h)
		_blob(img, rng, cx, cy, rng.randi_range(6, 18), rng.randi_range(3, 8), Color(c_lt if i % 3 else c_dk, 0.55))
	match zone:
		2:
			_waves(img, rng, Color(c_lt, 0.6), Color(c_dk, 0.5), 22, 3.0)
		3:
			for i in range(int(float(w * h) / 2600.0)):
				var px := rng.randi_range(0, w)
				var py := rng.randi_range(0, h)
				var rx := rng.randi_range(8, 20)
				var ry := rng.randi_range(4, 8)
				_blob(img, rng, px, py, rx + 2, ry + 1, Color("4a6a5a"))
				_blob(img, rng, px, py, rx, ry, c_patch)
				_blob(img, rng, px - 2, py - 1, rx / 3, 1, Color("5f8a80"))
		4:
			for i in range(int(float(w * h) / 3200.0)):
				var px := rng.randi_range(0, w)
				var py := rng.randi_range(0, h)
				_blob(img, rng, px, py, rng.randi_range(10, 22), rng.randi_range(4, 9), c_patch)
			for i in range(int(float(w * h) / 700.0)):
				_blob(img, rng, rng.randi_range(0, w), rng.randi_range(0, h), rng.randi_range(2, 5), rng.randi_range(1, 3), Color("5a6878"))
		5:
			_waves(img, rng, Color(c_lt, 0.7), Color(c_dk, 0.6), 14, 2.0)
		6:
			for i in range(int(float(w * h) / 1500.0)):
				_crack(img, rng, Vector2(rng.randi_range(0, w), rng.randi_range(0, h)), c_patch)
		7:
			for i in range(int(float(w * h) / 1800.0)):
				_tiles(img, rng, rng.randi_range(0, w), rng.randi_range(0, h), Color("2a4a5e"), Color("16324a"))
	# Grain : quelques pixels plus sombres ou plus clairs.
	for i in range(int(float(w * h) / 7.0)):
		var x := rng.randi_range(0, w - 1)
		var y2 := rng.randi_range(0, h - 1)
		img.set_pixel(x, y2, img.get_pixel(x, y2).darkened(0.12) if rng.randf() < 0.6 else img.get_pixel(x, y2).lightened(0.08))
	_paint_road(img, pal, rng)
	return img


func _paint_road(img: Image, pal: Array, rng: RandomNumberGenerator) -> void:
	var edge := Color(str(pal[5]))
	var fill := Color(str(pal[6]))
	var det := Color(str(pal[7]))
	var re := 7
	var rf := 5
	var pts := PackedVector2Array()
	for p in _road:
		pts.append(p / float(S))
	for p in pts:
		_disc(img, int(p.x), int(p.y), re, edge)
	for p in pts:
		_disc(img, int(p.x), int(p.y), rf, fill)
	for i in range(1, pts.size()):
		var d := (pts[i] - pts[i - 1]).normalized()
		var nrm := Vector2(-d.y, d.x)
		var p := pts[i]
		match zone:
			2, 5:
				# Ornières (collines) ou pavés usés (désert).
				for s in [-2.5, 2.5]:
					_px(img, p + nrm * float(s), det)
			3:
				# Planches d'un ponton.
				if i % 4 == 0:
					for s in range(-rf + 1, rf):
						_px(img, p + nrm * float(s), det)
			4:
				if i % 5 == 0:
					_px(img, p + nrm * (1.5 if i % 10 == 0 else -1.5), det)
			6:
				if rng.randf() < 0.08:
					_px(img, p + nrm * rng.randf_range(-3.0, 3.0), det)
			7:
				if i % 5 == 0:
					for s in range(-rf + 1, rf):
						_px(img, p + nrm * float(s), det)
			_:
				if rng.randf() < 0.3:
					_px(img, p + nrm * rng.randf_range(-3.5, 3.5), det)


static func _px(img: Image, p: Vector2, c: Color) -> void:
	var x := int(p.x)
	var y := int(p.y)
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func _disc(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for dy in range(-r, r + 1):
		var hw := int(sqrt(float(r * r - dy * dy)) + 0.3)
		var y := cy + dy
		if y < 0 or y >= img.get_height():
			continue
		var x0 := maxi(cx - hw, 0)
		var x1 := mini(cx + hw, img.get_width() - 1)
		if x1 >= x0:
			img.fill_rect(Rect2i(x0, y, x1 - x0 + 1, 1), c)


static func _blob(img: Image, rng: RandomNumberGenerator, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for dy in range(-ry, ry + 1):
		var y := cy + dy
		if y < 0 or y >= img.get_height():
			continue
		var f := 1.0 - pow(float(dy) / float(maxi(ry, 1)), 2.0)
		var hw := int(float(rx) * sqrt(maxf(f, 0.0))) + rng.randi_range(-1, 1)
		for x in range(maxi(cx - hw, 0), mini(cx + hw, img.get_width() - 1) + 1):
			img.set_pixel(x, y, img.get_pixel(x, y).blend(c))


## Ondulations (collines, dunes) : des lignes claires et leurs ombres.
static func _waves(img: Image, rng: RandomNumberGenerator, lit: Color, dark: Color, step: int, amp: float) -> void:
	var y0 := rng.randi_range(0, step)
	while y0 < img.get_height() + step:
		var ph := rng.randf() * TAU
		var fr := rng.randf_range(0.05, 0.11)
		for x in range(img.get_width()):
			var y := y0 + int(sin(float(x) * fr + ph) * amp)
			if y >= 1 and y < img.get_height():
				img.set_pixel(x, y, img.get_pixel(x, y).blend(lit))
				img.set_pixel(x, y - 1, img.get_pixel(x, y - 1).blend(dark))
		y0 += step + rng.randi_range(-4, 4)


## Faille de lave (forêt cendrée) : un trait brisé qui rougeoie.
static func _crack(img: Image, rng: RandomNumberGenerator, p: Vector2, c: Color) -> void:
	var dir := Vector2.from_angle(rng.randf() * TAU)
	for i in range(rng.randi_range(8, 20)):
		_px(img, p, c)
		_px(img, p + Vector2(1, 0), Color(c.darkened(0.45), 0.9))
		dir = dir.rotated(rng.randf_range(-0.7, 0.7))
		p += dir


## Dalles englouties (cité) : un petit carrelage.
static func _tiles(img: Image, rng: RandomNumberGenerator, cx: int, cy: int, face: Color, joint: Color) -> void:
	var cols := rng.randi_range(2, 4)
	var rows := rng.randi_range(1, 3)
	for r in range(rows):
		for k in range(cols):
			var x := cx + k * 7 + (3 if r % 2 else 0)
			var y := cy + r * 5
			if x >= 0 and y >= 0 and x + 7 < img.get_width() and y + 5 < img.get_height():
				img.fill_rect(Rect2i(x, y, 7, 5), joint)
				img.fill_rect(Rect2i(x + 1, y + 1, 5, 3), face)


# ---------------------------------------------------------------- décors

## Accessoires de la zone : [texture, région, poids].
static func prop_set(z: int) -> Array:
	var out: Array = []
	var trees := func(scene: String, w: int) -> void:
		var at := WorldArt.tree_atlas(scene)
		for f in range(6):
			out.append([at, Rect2(28 * f, 0, 28, 48), w])
	match z:
		2:
			trees.call("moulins", 2)
			for t in [WorldArt.haystack_texture(), WorldArt.milestone_texture(), WorldArt.cart_texture(false)]:
				out.append([t, Rect2(), 3])
			for t in [WorldArt.windmill_texture(), WorldArt.watchtower_texture(), WorldArt.amber_spire_texture(), WorldArt.palisade_texture(),
					WorldArt.tent_texture(Color("8a5a2a"), Color("d8b070")), WorldArt.totem_texture(false)]:
				out.append([t, Rect2(), 2])
		3:
			trees.call("saules", 2)
			out.append([WorldArt.reeds_texture(), Rect2(), 14])
			for t in [WorldArt.grave_texture(), WorldArt.ribcage_texture(), WorldArt.cauldron_texture(), WorldArt.boat_texture(),
					WorldArt.ruin_pillar_texture(), WorldArt.ash_stone_texture(), WorldArt.stilt_house_texture(), WorldArt.big_skull_texture()]:
				out.append([t, Rect2(), 2])
		4:
			out.append([WorldArt.pine_texture(), Rect2(), 16])
			out.append([WorldArt.ice_spire_texture(), Rect2(), 6])
			for t in [WorldArt.dwarf_statue_texture(), WorldArt.rune_pillar_texture(), WorldArt.brazier_texture(), WorldArt.minecart_texture()]:
				out.append([t, Rect2(), 2])
		5:
			out.append([WorldArt.glass_cluster_texture(), Rect2(), 10])
			out.append([WorldArt.crystal_texture(), Rect2(), 6])
			for t in [WorldArt.obelisk_texture(), WorldArt.sand_column_texture(), WorldArt.glass_mirror_texture(), WorldArt.broken_statue_texture()]:
				out.append([t, Rect2(), 3])
		6:
			out.append([WorldArt.charred_tree_texture(), Rect2(), 16])
			out.append([WorldArt.ash_stone_texture(), Rect2(), 4])
			for t in [WorldArt.wyrm_altar_texture(), WorldArt.phoenix_nest_texture()]:
				out.append([t, Rect2(), 2])
		7:
			trees.call("quais", 2)
			for c in ["ff7a9a", "ffb46a", "b07cff", "6fdccf"]:
				out.append([WorldArt.coral_texture(Color(c)), Rect2(), 3])
			for t in [WorldArt.anchor_texture(), WorldArt.giant_clam_texture(), WorldArt.archivist_statue_texture(), WorldArt.diving_bell_texture(),
					WorldArt.sunken_shelf_texture(), WorldArt.quay_lamp_texture(), WorldArt.tentacle_texture()]:
				out.append([t, Rect2(), 2])
		_:
			trees.call("sentier", 4)
			for t in [WorldArt.fern_texture(), WorldArt.mushroom_texture(), WorldArt.stump_texture()]:
				out.append([t, Rect2(), 4])
			for t in [WorldArt.runestone_texture(), WorldArt.bramble_texture(), WorldArt.root_texture(), WorldArt.lamp_texture()]:
				out.append([t, Rect2(), 2])
	return out


## Emblème d'une zone (frise des zones) : son accessoire le plus parlant.
static func emblem(z: int) -> Array:
	match z:
		2:
			return [WorldArt.windmill_texture(), Rect2()]
		3:
			return [WorldArt.stilt_house_texture(), Rect2()]
		4:
			return [WorldArt.ice_spire_texture(), Rect2()]
		5:
			return [WorldArt.obelisk_texture(), Rect2()]
		6:
			return [WorldArt.charred_tree_texture(), Rect2()]
		7:
			return [WorldArt.coral_arch_texture(), Rect2()]
	return [WorldArt.tree_atlas("sentier"), Rect2(28 * 3, 0, 28, 48)]


## Repère au bout du chemin (l'antre du boss) et à l'entrée de la zone.
func _landmarks() -> Array:
	match zone:
		1:
			return [[WorldArt.tree_atlas("sylvarche"), Rect2(28 * 4, 0, 28, 48), 4.0], [WorldArt.cottage_texture(), Rect2(), 3.0]]
		2:
			return [[WorldArt.watchtower_texture(), Rect2(), 4.0], [WorldArt.milestone_texture(), Rect2(), 3.0]]
		3:
			return [[WorldArt.big_skull_texture(), Rect2(), 4.0], [WorldArt.boat_texture(), Rect2(), 3.0]]
		4:
			return [[WorldArt.great_door_texture(), Rect2(), 4.0], [WorldArt.rune_pillar_texture(), Rect2(), 3.0]]
		5:
			return [[WorldArt.obelisk_texture(), Rect2(), 4.0], [WorldArt.sand_column_texture(), Rect2(), 3.0]]
		6:
			return [[WorldArt.wyrm_altar_texture(), Rect2(), 4.0], [WorldArt.phoenix_nest_texture(), Rect2(), 3.0]]
	return [[WorldArt.coral_arch_texture(), Rect2(), 4.0], [WorldArt.quay_lamp_texture(), Rect2(), 3.0]]


func _place_props(w: float, h: float) -> void:
	_props.clear()
	var pool := prop_set(zone)
	var total := 0
	for e in pool:
		total += int(e[2])
	# Zones à garder libres : chaque médaillon et son nom.
	var keep: Array[Rect2] = []
	for p in _pts:
		var right := p.x < w * 0.5
		keep.append(Rect2(p.x - 70.0, p.y - 80.0, 140.0, 150.0))
		keep.append(Rect2(p.x + 50.0 if right else p.x - 290.0, p.y - 40.0, 240.0, 80.0))
	# Repères : l'antre du boss en haut, l'entrée de la zone en bas.
	var lm := _landmarks()
	if not _pts.is_empty():
		var top := _pts[_pts.size() - 1]
		var a: Array = lm[0]
		var side := -1.0 if top.x > w * 0.5 else 1.0
		_props.append([a[0], a[1], Vector2(clampf(top.x + side * 150.0, 70.0, w - 70.0), top.y - 50.0), float(a[2])])
		var b: Array = lm[1]
		var first := _pts[0]
		var side2 := -1.0 if first.x > w * 0.5 else 1.0
		_props.append([b[0], b[1], Vector2(clampf(first.x + side2 * 120.0, 60.0, w - 60.0), first.y + 110.0), float(b[2])])
		keep.append(Rect2(top.x + side * 150.0 - 70.0, top.y - 230.0, 140.0, 190.0))
	# Le héros attend au prochain niveau : sa place reste libre aussi.
	for i in range(_pts.size()):
		if Profile.is_unlocked(str(ids[i])) and not _cleared(i):
			var hx := _pts[i].x + (-110.0 if _pts[i].x < w * 0.5 else 110.0)
			keep.append(Rect2(hx - 50.0, _pts[i].y - 80.0, 100.0, 130.0))
			break
	var step := 70.0
	var y := 30.0
	while y < h + 60.0:
		var x := 10.0 + _rng.randf() * 30.0
		while x < w:
			var p := Vector2(x + _rng.randf_range(-20.0, 20.0), y + _rng.randf_range(-20.0, 20.0))
			x += step + _rng.randf_range(-10.0, 20.0)
			if _rng.randf() < 0.22 or _dist_road(p) < 60.0:
				continue
			# Tirage pondéré.
			var pick := _rng.randi_range(0, total - 1)
			var e: Array = pool[0]
			for c in pool:
				pick -= int(c[2])
				if pick < 0:
					e = c
					break
			var sc := float(S) if _rng.randf() < 0.75 else float(S) - 0.5
			var reg: Rect2 = e[1]
			var sz := (reg.size if reg.size != Vector2.ZERO else (e[0] as Texture2D).get_size()) * sc
			# Tout le dessin (pas seulement son pied) doit laisser libres les médaillons, les noms et le chemin.
			var body := Rect2(p - Vector2(sz.x * 0.5, sz.y), sz).grow(-4.0)
			var free := true
			for r in keep:
				if r.intersects(body):
					free = false
					break
			if not free or _dist_road(p - Vector2(0, sz.y * 0.5)) < 40.0 + sz.x * 0.3:
				continue
			_props.append([e[0], e[1], p, sc])
		y += step
	_props.sort_custom(func(a: Array, b: Array) -> bool: return (a[2] as Vector2).y < (b[2] as Vector2).y)


# ---------------------------------------------------------------- médaillons, héros, brume, particules

func _build_medals() -> void:
	for ch in get_children():
		ch.queue_free()
	_medals.clear()
	_hero = null
	var hero_i := -1
	for i in range(ids.size()):
		var id := str(ids[i])
		if hero_i < 0 and Profile.is_unlocked(id) and not _cleared(i):
			hero_i = i
	for i in range(ids.size()):
		var id := str(ids[i])
		var lv := GameData.level(id)
		var m := Medal.new()
		var kind := str(lv.get("type", "Assaut"))
		var k: Array = KIND.get(kind, KIND["Assaut"])
		m.kind = kind
		m.glyph = Icons.tex(str(k[0]), 96, 1.8)
		m.col = Color(str(k[1]))
		m.number = str(lv.get("number", ""))
		m.stars = int(Profile.level_record(id)["stars"])
		m.state = "done" if _cleared(i) else ("next" if Profile.is_unlocked(id) else "locked")
		m.selected = id == selected
		m.anim = _anim
		var d := 120.0 if kind == "Boss" else (104.0 if kind == "Mini-boss" else 90.0)
		m.setup(d)
		m.position = _pts[i] - m.center()
		m.pressed.connect(func() -> void: picked.emit(id))
		add_child(m)
		_medals[id] = m
		# Nom du niveau, du côté libre du lacet.
		var right := _pts[i].x < size.x * 0.5
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", -2)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.custom_minimum_size = Vector2(220, 0)
		var open := m.state != "locked"
		var nm := _outlined(str(lv.get("name", "")), 19, UiTheme.GOLD if m.state == "next" else (UiTheme.TEXT if open else UiTheme.MUTED))
		var sub := _outlined("%s · niv. %d" % [kind, int(lv.get("global_level", 1))], 15, Color(m.col, 0.95) if open else Color(UiTheme.MUTED, 0.8))
		for l in [nm, sub]:
			(l as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if right else HORIZONTAL_ALIGNMENT_RIGHT
			(l as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			(l as Label).custom_minimum_size = Vector2(220, 0)
			box.add_child(l)
		add_child(box)
		box.size = Vector2(220, 0)
		var half := d * 0.5
		box.position = Vector2(_pts[i].x + half + 14.0 if right else _pts[i].x - half - 14.0 - 220.0, _pts[i].y - 26.0)
	# Le héros attend au prochain niveau, du côté opposé à son nom.
	if hero_i >= 0:
		# Le héros en volume, qui respire ; il marchera vers le niveau choisi.
		var tt := HeroTurntable.new()
		tt.interactive = false
		tt.px_scale = 3
		tt.yaw = IDLE_YAW
		tt.light = str(HeroCard.ZONE_LIGHT.get(zone, "jour"))
		tt.setup(Profile.look(), Profile.race(), Profile.player_class(), Profile.visible_cosmetics(), Profile.gear_look())
		_hero = tt
		add_child(_hero)
		_hero.size = _hero.custom_minimum_size
		_hero_i = hero_i
		_walk = PackedVector2Array()
		_walk_to = -1
		_hero_foot = _stand_of(hero_i)
		_hero.position = Vector2(_hero_foot.x - _hero.size.x * 0.5, _hero_foot.y - _hero.size.y)


func _outlined(text: String, fs: int, c: Color) -> Label:
	var l := UiTheme.label(text, fs, c)
	l.add_theme_constant_override("outline_size", 7)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	return l


func _build_fog(w: float) -> void:
	_fog.clear()
	var first := -1
	for i in range(ids.size()):
		if not Profile.is_unlocked(str(ids[i])):
			first = i
			break
	if first < 0:
		return
	var y := _pts[first].y + GAP * 0.4
	var rng := RandomNumberGenerator.new()
	rng.seed = 31 * zone
	while y > -160.0:
		for k in range(4):
			_fog.append([Vector2(rng.randf_range(-40.0, w + 40.0), y + rng.randf_range(-40.0, 40.0)), rng.randf_range(150.0, 240.0), rng.randf()])
		y -= 110.0


func _build_parts(w: float, h: float) -> void:
	_parts = PackedVector2Array()
	_pphase = PackedFloat32Array()
	if not _anim:
		return
	var cfg: Array = PARTS.get(zone, PARTS[1])
	var n := int(float(cfg[1]) * h / 1800.0)
	for i in range(n):
		_parts.append(Vector2(_rng.randf() * w, _rng.randf() * h))
		_pphase.append(_rng.randf() * TAU)


# ---------------------------------------------------------------- dessin

## Calque de dessin de la carte : il délègue son dessin à la carte.
class Layer extends Control:
	var board: MapBoard
	var kind := 0

	func _draw() -> void:
		board._draw_layer(self, kind)


func _layer(kind: int) -> Layer:
	var l := Layer.new()
	l.board = self
	l.kind = kind
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = Vector2.ZERO
	l.size = size
	add_child(l)
	move_child(l, kind)
	return l


func _draw_layer(ci: CanvasItem, kind: int) -> void:
	match kind:
		0:
			_draw_base(ci)
		1:
			_draw_dyn(ci)
		_:
			_draw_top(ci)


## Fixe : terrain, décors (du fond vers l'avant, avec leur ombre), chemin verrouillé assombri et lueur dorée
## du chemin parcouru, ombre du héros.
func _draw_base(ci: CanvasItem) -> void:
	if _terrain != null:
		ci.draw_texture_rect(_terrain, Rect2(0, 0, float(_terrain.get_width() * S), float(_terrain.get_height() * S)), false)
	for e in _props:
		var tex: Texture2D = e[0]
		var reg: Rect2 = e[1]
		var foot: Vector2 = e[2]
		var sc: float = e[3]
		var sz := (reg.size if reg.size != Vector2.ZERO else tex.get_size()) * sc
		_shadow(ci, foot, sz.x * 0.42)
		var r := Rect2(foot - Vector2(sz.x * 0.5, sz.y), sz)
		if reg.size != Vector2.ZERO:
			ci.draw_texture_rect_region(tex, r, reg)
		else:
			ci.draw_texture_rect(tex, r, false)
	for run in _runs:
		var pl: PackedVector2Array = run[1]
		match str(run[0]):
			"locked":
				ci.draw_polyline(pl, Color(0.02, 0.03, 0.06, 0.45), 22.0, true)
			"done":
				ci.draw_polyline(pl, Color(UiTheme.GOLD, 0.16), 12.0, true)


## Animé : pas dorés et sarcelle, anneau du héros, brume sur le verrouillé, particules.
func _draw_dyn(ci: CanvasItem) -> void:
	for run in _runs:
		var pl: PackedVector2Array = run[1]
		match str(run[0]):
			"done":
				_dots(ci, pl, Color(UiTheme.GOLD, 0.9), 16.0, _t * 10.0, 2.6)
			"next":
				_dots(ci, pl, Color(UiTheme.TEAL, 0.95), 14.0, _t * 26.0, 3.2)
	if _hero != null:
		# Son ombre et son anneau le suivent quand il marche.
		_shadow(ci, _hero_foot + Vector2(0, -2), 26.0)
		var a := 0.35 + 0.2 * sin(_t * 3.0)
		ci.draw_arc(_hero_foot + Vector2(0, -3), 22.0, 0.0, TAU, 32, Color(UiTheme.TEAL, a), 2.0, true)
	if _puff == null:
		_puff = _radial()
	for f in _fog:
		var c: Vector2 = f[0]
		var r2: float = f[1]
		var drift := sin(_t * 0.25 + float(f[2]) * 6.0) * 18.0
		ci.draw_texture_rect(_puff, Rect2(c + Vector2(drift - r2, -r2 * 0.6), Vector2(r2 * 2.0, r2 * 1.2)), false, Color(0.03, 0.05, 0.09, 0.8))
		ci.draw_texture_rect(_puff, Rect2(c + Vector2(-drift - r2 * 0.6, -r2 * 0.3), Vector2(r2 * 1.2, r2 * 0.6)), false, Color(0.7, 0.78, 0.88, 0.07))
	_draw_parts(ci, size.x, size.y)


## Fixe : vignette sur les bords et cadre doré.
func _draw_top(ci: CanvasItem) -> void:
	var w := size.x
	var h := size.y
	for i in range(6):
		var a2 := 0.10 * float(6 - i) / 6.0
		ci.draw_rect(Rect2(float(i) * 4.0, 0, 4, h), Color(0, 0, 0, a2))
		ci.draw_rect(Rect2(w - float(i + 1) * 4.0, 0, 4, h), Color(0, 0, 0, a2))
	ci.draw_rect(Rect2(1, 1, w - 2, h - 2), Color(UiTheme.GOLD, 0.35), false, 2.0)


func _shadow(ci: CanvasItem, at: Vector2, rx: float) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var a := float(i) / 16.0 * TAU
		pts.append(at + Vector2(cos(a) * rx, sin(a) * rx * 0.3))
	ci.draw_colored_polygon(pts, Color(0, 0, 0, 0.28))


## Étapes du chemin et leur état (parcouru, vers le prochain niveau, verrouillé), calculées une seule fois.
func _build_runs() -> void:
	_runs.clear()
	var states: Dictionary = {}
	for k in range(ids.size() + 1):
		states[k] = _seg_state(k)
	var cur := -1
	var line := PackedVector2Array()
	for i in range(_road.size()):
		var k := _seg[i]
		if k != cur:
			if line.size() > 1:
				_runs.append([str(states.get(cur, "locked")), line])
			line = PackedVector2Array()
			if i > 0:
				line.append(_road[i - 1])
			cur = k
		line.append(_road[i])
	if line.size() > 1:
		_runs.append([str(states.get(cur, "locked")), line])


func _dots(ci: CanvasItem, pl: PackedVector2Array, c: Color, step: float, offset: float, r: float) -> void:
	var acc := fposmod(offset, step)
	var halo := Color(c, c.a * 0.22)
	for i in range(1, pl.size()):
		var a := pl[i - 1]
		var b := pl[i]
		var d := a.distance_to(b)
		while acc <= d:
			var p := a.lerp(b, acc / maxf(d, 0.001))
			ci.draw_circle(p, r + 2.5, halo)
			ci.draw_circle(p, r, c)
			acc += step
		acc -= d


func _draw_parts(ci: CanvasItem, w: float, h: float) -> void:
	if _parts.is_empty():
		return
	var cfg: Array = PARTS.get(zone, PARTS[1])
	var col := Color(str(cfg[0]))
	var mode := str(cfg[2])
	for i in range(_parts.size()):
		var p := _parts[i]
		var ph := _pphase[i]
		var q := p
		var a := 0.8
		var r := 2.2
		match mode:
			"wander":
				q = p + Vector2(sin(_t * 0.7 + ph) * 26.0, cos(_t * 0.5 + ph * 1.3) * 18.0)
				a = 0.25 + 0.75 * maxf(sin(_t * 2.0 + ph * 3.0), 0.0)
				r = 2.4
			"fall":
				q = Vector2(fposmod(p.x + sin(_t + ph) * 14.0 + _t * 8.0, w), fposmod(p.y + _t * 40.0 * (0.6 + 0.4 * sin(ph)), h))
				a = 0.75
				r = 1.8 + 0.8 * sin(ph)
			"rise":
				q = Vector2(p.x + sin(_t * 1.3 + ph) * 10.0, fposmod(p.y - _t * (30.0 + 14.0 * sin(ph)), h))
				a = 0.4 + 0.5 * absf(sin(_t * 1.7 + ph))
				r = 2.0
			"mist":
				q = Vector2(fposmod(p.x + _t * 9.0, w + 200.0) - 100.0, p.y)
				ci.draw_texture_rect(_puff, Rect2(q - Vector2(90, 26), Vector2(180, 52)), false, Color(col, 0.08))
				continue
			_:
				q = Vector2(fposmod(p.x + _t * 18.0 + sin(_t + ph) * 10.0, w), p.y + sin(_t * 0.8 + ph) * 12.0)
				a = 0.35 + 0.4 * absf(sin(_t * 1.1 + ph))
				r = 1.6
		ci.draw_circle(q, r * 2.6, Color(col, a * 0.18))
		ci.draw_circle(q, r, Color(col, a))


static func _radial() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


# ---------------------------------------------------------------- médaillon d'un niveau

class Medal extends Button:
	var kind := "Assaut"
	var glyph: Texture2D
	var col := Color.WHITE
	var number := ""
	var stars := 0
	var state := "locked" ## done | next | locked
	var selected := false
	var anim := true
	var diameter := 90.0
	var _t := 0.0
	var _under: Under ## ombre, halo du prochain niveau, anneau de sélection : seuls redessinés à chaque image

	func setup(d: float) -> void:
		diameter = d
		custom_minimum_size = Vector2(d + 24.0, d + 40.0)
		size = custom_minimum_size
		_under = Under.new()
		_under.medal = self
		_under.show_behind_parent = true
		_under.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_under.size = size
		add_child(_under)
		focus_mode = Control.FOCUS_NONE
		flat = true
		for s in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(s, StyleBoxEmpty.new())
		pivot_offset = center()
		pressed.connect(Snd.click)
		button_down.connect(func() -> void: scale = Vector2(0.93, 0.93))
		button_up.connect(func() -> void: scale = Vector2.ONE)

	func center() -> Vector2:
		return Vector2(size.x * 0.5, 20.0 + diameter * 0.5)

	func tick(t: float) -> void:
		_t = t
		if anim and (state == "next" or selected):
			_under.queue_redraw()

	## Tout redessiner (changement de sélection).
	func redraw() -> void:
		queue_redraw()
		_under.queue_redraw()

	func ring_color() -> Color:
		var lock := state == "locked"
		var ring := UiTheme.GOLD if state == "done" else (UiTheme.TEAL if state == "next" else Color("4a5868"))
		if kind == "Boss" and not lock:
			ring = Color("ff6b6b") if state == "next" else UiTheme.GOLD
		return ring

	## Sous le médaillon (dessiné avant lui) : son ombre, le halo qui palpite, l'anneau de sélection.
	func draw_under(ci: CanvasItem) -> void:
		var c := center()
		var r := diameter * 0.5
		var ring := ring_color()
		ci.draw_circle(c + Vector2(0, 7), r, Color(0, 0, 0, 0.4))
		if state == "next":
			var p := 0.5 + 0.5 * sin(_t * 3.0)
			ci.draw_circle(c, r + 10.0 + 4.0 * p, Color(ring, 0.10 + 0.08 * p))
			ci.draw_circle(c, r + 5.0, Color(ring, 0.18))
		if selected:
			ci.draw_arc(c, r + 7.0, 0.0, TAU, 72, Color(UiTheme.GOLD, 0.9), 3.0, true)
			for k in range(4):
				var a := _t * 0.8 + float(k) * PI * 0.5
				ci.draw_circle(c + Vector2.from_angle(a) * (r + 7.0), 3.5, UiTheme.GOLD)

	func _draw() -> void:
		var c := center()
		var r := diameter * 0.5
		var lock := state == "locked"
		var ring := ring_color()
		# Ornements : piques du boss (5) et du mini-boss (3).
		var spikes := 5 if kind == "Boss" else (3 if kind == "Mini-boss" else 0)
		for k in range(spikes):
			var a2 := -PI * 0.5 + (float(k) - float(spikes - 1) * 0.5) * 0.42
			var tip := c + Vector2.from_angle(a2) * (r + 16.0)
			var b1 := c + Vector2.from_angle(a2 - 0.16) * (r - 2.0)
			var b2 := c + Vector2.from_angle(a2 + 0.16) * (r - 2.0)
			draw_colored_polygon(PackedVector2Array([b1, tip, b2]), ring.darkened(0.25) if not lock else Color("2a323c"))
		var base := Color("2a2114") if state == "done" else (Color("0f2a2c") if state == "next" else Color("141a22"))
		if kind == "Boss" and not lock:
			base = Color("3a1414")
		draw_circle(c, r, base)
		draw_circle(c + Vector2(0, -r * 0.22), r * 0.72, Color(1, 1, 1, 0.05))
		draw_arc(c, r, 0.0, TAU, 72, ring, 4.0, true)
		draw_arc(c, r - 7.0, 0.0, TAU, 72, Color(ring, 0.35), 1.5, true)
		var ic := r * (1.0 if kind == "Boss" else 0.95)
		if lock:
			var lk := Icons.tex("lock", 96, 1.8)
			draw_texture_rect(lk, Rect2(c - Vector2(ic, ic) * 0.42, Vector2(ic, ic) * 0.84), false, Color("6a7888"))
		elif glyph != null:
			draw_texture_rect(glyph, Rect2(c - Vector2(ic, ic) * 0.5, Vector2(ic, ic)), false, col if state != "done" else UiTheme.GOLD.lerp(col, 0.35))
		# Numéro du niveau, sur un cartouche.
		var font := get_theme_default_font()
		var fs := 17
		var tw := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0
		var pr := Rect2(c.x - tw * 0.5, c.y + r - 10.0, tw, 24.0)
		draw_rect(pr, Color("0a0f16"))
		draw_rect(pr, ring if not lock else Color("3a4652"), false, 2.0)
		draw_string(font, Vector2(pr.position.x, pr.position.y + 18.0), number, HORIZONTAL_ALIGNMENT_CENTER, tw, fs, UiTheme.TEXT if not lock else UiTheme.MUTED)
		# Étoiles en couronne au-dessus du médaillon.
		if not lock:
			for k in range(3):
				var a3 := -PI * 0.5 + (float(k) - 1.0) * 0.5
				var sp := c + Vector2.from_angle(a3) * (r + (2.0 if spikes == 0 else 20.0))
				_star(sp, 10.0 if k == 1 else 8.5, k < stars)

	func _star(at: Vector2, r: float, on: bool) -> void:
		var pts := PackedVector2Array()
		for i in range(10):
			var a := -PI * 0.5 + float(i) * PI / 5.0
			pts.append(at + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.45))
		draw_colored_polygon(pts, UiTheme.GOLD if on else Color("1a2230"))
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, Color(0, 0, 0, 0.7) if on else Color(UiTheme.GOLD, 0.45), 1.5, true)


## Calque sous un médaillon (show_behind_parent) : il délègue son dessin au médaillon.
class Under extends Control:
	var medal: Medal

	func _draw() -> void:
		medal.draw_under(self)
