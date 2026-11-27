class_name HeroModel
extends RefCounted
## Le héros en volume (docs/design/14-interface.md, « Équipement ») : un petit modèle en cubes (voxels) construit
## d'après son apparence (PlayerLook), sa race et sa classe, puis rendu en pixel art sous n'importe quel angle.
## Sert au personnage qu'on fait tourner dans l'Équipement ; base pour donner des angles aux personnages.
##
## Repère du modèle : x vers la droite du héros, y vers le haut (0 sous les pieds), z vers son dos
## (le héros regarde vers -z). Angle 0 : vu de dos, comme en combat ; PI : de face.

const W := 36 ## largeur de l'image rendue (pixels) : de la marge pour les bras levés et les armes
const H := 44 ## hauteur de l'image rendue : de la marge pour un saut, une arme brandie
const FOOT_W := 28 ## encombrement du héros au repos (mise en page)
const FOOT_H := 33
const STEPS := 48 ## angles mis en cache (7,5° chacun)
const OUTLINE := Color("0e0a1c")
const IVORY := Color("e8dcc0")

## Voxels : Vector3i -> [couleur, émissif, partie]
var vox: Dictionary = {}
var _surface: Array = [] ## [position, normale, couleur, émissif, partie]
var _part := "body" ## partie du corps des voxels posés (squelette des animations)
var _keep := false ## repeindre un voxel sans changer sa partie
## Pivots des parties (articulations) : hanches, cou, épaules, mains, haut de la cape…
var pivots: Dictionary = {}
var _cache: Dictionary = {}
var _wx := 0 ## décalage horizontal de l'arme (main plus écartée)
var _wy := 0 ## décalage vertical de l'arme (main plus basse)
var _mirror := false ## arme dans la main gauche (archère)

static var _models: Dictionary = {}

## Tenues cosmétiques : ombre, foncé, principal, clair, liseré.
const TENUE := {
	"boulanger": ["9a8a7a", "c8bca8", "f2ece0", "ffffff", "c89048"],
	"corsaire": ["3a0e0e", "6a1a1a", "b8322a", "d85a4a", "e0b850"],
	"courge": ["2a1a0a", "1a1a1a", "e8702a", "ff9a4a", "1a1a1a"],
	"carton": ["6a4a2a", "9a7448", "c8a070", "e0c090", "e8d8b8"],
	"ruche": ["9a9070", "c8c0a0", "f0ead0", "ffffff", "e8b83a"],
	"grenouille": ["1a4a1a", "2a6a2a", "4aa04a", "8fd06a", "d8e8a0"],
	"sporelin": ["3a2410", "5a3a1a", "7a5230", "a07040", "d83a3a"],
	"stellaire": ["0a1030", "14204a", "1e2e6a", "3a4a9a", "fff0a0"],
}
## Couvre-chefs : « hat » se pose sur les cheveux ; « full » couvre toute la tête ; « hood » remplace la coiffure.
const HEAD_MODE := {"boulanger": "hat", "corsaire": "hat", "courge": "full", "carton": "full", "ruche": "full",
	"grenouille": "hood", "sporelin": "hat", "stellaire": "hat"}

## Compagnons qui ont leur modèle en volume (les autres gardent leur sprite).
const COMPANIONS := ["brann", "sylwen", "krag", "nyx", "ignara", "ssareth"]


## Modèle du héros actuel (apparence, race, classe), gardé en cache.
static func of(look: Dictionary, race: String, cls: String, cos: Dictionary = {}, gear: Dictionary = {}) -> HeroModel:
	var key := PlayerLook.key(look, race) + "|" + cls + "|" + JSON.stringify(cos) + "|" + JSON.stringify(gear)
	if not _models.has(key):
		if _models.size() > 10:
			_models.clear()
		var m := HeroModel.new()
		m.build(look, race, cls, cos, gear)
		_models[key] = m
	return _models[key]


static func has_companion(who: String) -> bool:
	return who in COMPANIONS


## Modèle d'un compagnon, avec l'arme de sa voie actuelle.
static func of_companion(who: String, cls: String) -> HeroModel:
	var key := "comp|%s|%s" % [who, cls]
	if not _models.has(key):
		if _models.size() > 6:
			_models.clear()
		var m := HeroModel.new()
		m.build_companion(who, cls)
		_models[key] = m
	return _models[key]


## Image du héros pour un angle (radians, 0 = de dos), arrondi au pas de cache le plus proche.
func image_at(yaw: float, light: String = "jour") -> Image:
	return frame_at(yaw, "", 0, light)


# ---------------------------------------------------------------- construction

func _put(x: int, y: int, z: int, c: Color, glow: bool = false) -> void:
	var q := Vector3i(x, y, z)
	var part := _part
	if _keep and vox.has(q):
		part = str(vox[q][2])
	vox[q] = [c, glow, part]


func _clear(x: int, y: int, z: int) -> void:
	vox.erase(Vector3i(x, y, z))


## Ellipse pleine dans le plan horizontal y (centre cx, cz ; demi-axes rx, rz).
func _disc(y: int, cx: float, cz: float, rx: float, rz: float, c: Color) -> void:
	for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 2):
		for z in range(int(floor(cz - rz)) - 1, int(ceil(cz + rz)) + 2):
			var dx := (float(x) - cx) / rx
			var dz := (float(z) - cz) / rz
			if dx * dx + dz * dz <= 1.0:
				_put(x, y, z, c)


## cos : cosmétiques portés par-dessus l'équipement, {emplacement: « kit.emplacement »} (tête, tenue, dos, arme).
## gear : l'équipement porté, {emplacement: {t, m, c, g, r, base}} (Profile.gear_look) ; voir HeroGear.
func build(look: Dictionary, race: String, cls: String, cos: Dictionary = {}, gear: Dictionary = {}) -> void:
	vox.clear()
	_cache.clear()
	_wx = 0
	_wy = 0
	_mirror = false
	_keep = false
	pivots = HERO_PIVOTS.duplicate()
	var pal := PlayerLook.palette(look, race)
	var o: Array = pal["outfit"]
	var hr: Array = pal["hair"]
	var sk: Array = pal["skin"]
	var eyes: Color = pal["eyes"]
	var head := str(pal["head"])
	var trim := eyes
	var k_tenue := str(cos.get("tenue", "")).get_slice(".", 0)
	var k_tete := str(cos.get("tete", "")).get_slice(".", 0)
	var k_dos := str(cos.get("dos", "")).get_slice(".", 0)
	var k_arme := str(cos.get("arme", "")).get_slice(".", 0)
	if TENUE.has(k_tenue):
		var tp: Array = TENUE[k_tenue]
		o = [Color(str(tp[0])), Color(str(tp[1])), Color(str(tp[2])), Color(str(tp[3]))]
		trim = Color(str(tp[4]))
	var gt: Variant = HeroGear.trim_of(gear)
	if gt != null and not TENUE.has(k_tenue):
		trim = gt
	var head_mode := str(HEAD_MODE.get(k_tete, ""))
	var gear_head := ""
	if head_mode == "" and gear.has("head"):
		gear_head = HeroGear.head_mode(gear["head"])
	if gear_head == "hat" and head == "capuche":
		head = "courts"
	if head_mode == "hat" and head == "capuche":
		head = "courts" ## un chapeau se pose sur des cheveux, pas sur une capuche
	var tr := str(pal["trait"])
	var tunic := int(pal["sil"]) == 1
	var boot := Color("2a2030")
	var belt := Color("6a4a2a")
	var gold := Color("e0b850")
	# Jambes et bottes.
	_part = "legs"
	for side: int in [-2, 1]:
		for y in range(0, 6 if tunic else 3):
			for x in range(side, side + 2):
				for z in range(-1, 1):
					_put(x, y, z, boot if y == 0 else (o[0] if tunic else boot))
	# Robe longue (évasée) ou tunique et cape.
	_part = "body"
	var y0 := 6 if tunic else 2
	for y in range(y0, 15):
		var f := clampf(float(y - 2) / 8.0, 0.0, 1.0) ## 0 en bas de la robe, 1 à la taille
		var rx := lerpf(5.6, 4.1, f) if y <= 10 else lerpf(4.1, 4.6, float(y - 10) / 4.0)
		var rz := lerpf(3.3, 2.5, f) if y <= 10 else 2.5
		_disc(y, 0.0, 0.0, rx, rz, o[2])
	# Liseré de l'ourlet et de l'ouverture de la robe (devant), couture du dos, ceinture et boucle.
	for x in range(-6, 7):
		for z in range(-4, 5):
			if vox.has(Vector3i(x, y0, z)):
				_put(x, y0, z, trim)
	for y in range(y0, 10):
		_put(0, y, _front(0, y), trim)
	for y in range(y0 + 1, 13):
		_put(-1, y, _back(-1, y), trim)
	for x in range(-6, 7):
		for z in range(-4, 5):
			if vox.has(Vector3i(x, 10, z)):
				_put(x, 10, z, belt)
	_put(0, 10, _front(0, 10), gold)
	# Col de la tenue (plus clair).
	_disc(14, 0.0, 0.0, 3.0, 2.2, o[3])
	# Cape (tunique) : un pan dans le dos, des épaules au mollet.
	_part = "cape"
	if tunic:
		for y in range(3, 15):
			var half := 3 if y > 11 else 4
			for x in range(-half, half + 1):
				_put(x, y, 3 if y >= 8 else 4, o[1])
	# Bras : manches plus sombres, mains.
	_part = "arms"
	for side: int in [-1, 1]:
		var ax := side * 5
		for y in range(8, 14):
			_put(ax, y, 0, o[1])
			_put(ax, y, -1 if y < 11 else 0, o[1])
			if y > 11:
				_put(ax - side, y, 0, o[1])
		_put(ax, 7, 0, sk[1])
		_put(ax, 7, -1, sk[1])
	# L'équipement porté : armure (sauf sous une tenue cosmétique), gants, bottes.
	if gear.has("armor") and not TENUE.has(k_tenue):
		HeroGear.armor(self, gear["armor"], y0, tunic)
	if gear.has("hands"):
		HeroGear.hands(self, gear["hands"])
	if gear.has("feet"):
		HeroGear.feet(self, gear["feet"], tunic)
	# Cou et tête.
	_part = "head"
	_put(0, 15, 0, sk[0])
	_put(-1, 15, 0, sk[0])
	for y in range(16, 23):
		var dy := (float(y) - 19.0) / 3.6
		var k := sqrt(maxf(0.0, 1.0 - dy * dy))
		_disc(y, 0.0, 0.0, 3.6 * k + 0.15, 3.2 * k + 0.15, sk[1])
	_face(pal, sk, eyes)
	# Coiffure (un couvre-chef intégral ou une capuche cosmétique la remplace).
	_part = "head"
	if (head_mode == "" or head_mode == "hat") and gear_head != "full" and gear_head != "hood":
		match head:
			"capuche":
				_hood(o)
			_:
				_hair(head, hr)
	if head_mode != "":
		_cos_head(k_tete)
	elif gear_head != "":
		HeroGear.head(self, gear["head"], str((gear["head"] as Dictionary).get("base", "")))
	# Traits de race.
	match tr:
		"ears":
			for side: int in [-1, 1]:
				_put(side * 4, 19, 0, sk[1])
				_put(side * 5, 20, 1, sk[1])
				_put(side * 5, 21, 1, sk[2])
		"horns":
			for side: int in [-1, 1]:
				for q in [Vector3i(2, 22, 0), Vector3i(3, 23, 1), Vector3i(3, 24, 1), Vector3i(4, 25, 2)]:
					_put(side * q.x, q.y, q.z, IVORY)
			_part = "tail"
			_tail(sk)
		"tail":
			_part = "tail"
			_tail(sk)
		"wings":
			_part = "back"
			for side: int in [-1, 1]:
				for y in range(7, 17):
					var span := 5 - absi(y - 12) / 2
					for k in range(span):
						var edge := k == span - 1 or y == 7 or y == 16
						_put(side * (2 + k), y, 3 + k / 3, Color("5a4a78") if edge else Color(0.85, 0.8, 1.0), not edge)
		"tusks":
			for side: int in [-1, 1]:
				_put(side * 1, 17, -4, IVORY)
		"beard":
			for y in range(14, 18):
				for x in range(-2, 3):
					if absi(x) + (17 - y) <= 4:
						_put(x, y, _front(x, y) - (1 if y < 16 else 0), hr[1] if (x + y) % 3 else hr[0])
		"ghost":
			# Revenant : l'ourlet effiloché.
			_part = "body"
			for x in [-5, -2, 2, 5]:
				for z in range(-4, 5):
					_clear(x, y0, z)
	if TENUE.has(k_tenue):
		_part = "body"
		_keep = true
		_cos_tenue(k_tenue, y0)
		_keep = false
	if gear.has("amulet"):
		HeroGear.amulet(self, gear["amulet"])
	if gear.has("charm"):
		HeroGear.charm(self, gear["charm"])
	if k_dos != "":
		_part = "cape" if k_dos in ["courge", "carton", "stellaire"] else "back"
		_cos_back(k_dos, sk)
	_part = "hand"
	if k_arme != "":
		_cos_weapon(k_arme)
	elif gear.has("weapon"):
		HeroGear.weapon(self, gear["weapon"])
	else:
		_weapon(cls if not (cls == "chevalier" and gear.has("offhand")) else "epeiste", o, eyes)
	if gear.has("offhand"):
		HeroGear.offhand(self, gear["offhand"])
	_build_surface()


## z de la face avant (le plus petit z occupé) d'une colonne, ou -3.
func _front(x: int, y: int) -> int:
	for z in range(-6, 7):
		if vox.has(Vector3i(x, y, z)):
			return z
	return -3


## z de la face arrière (le plus grand z occupé) d'une colonne, ou 3.
func _back(x: int, y: int) -> int:
	for z in range(6, -7, -1):
		if vox.has(Vector3i(x, y, z)):
			return z
	return 3


## Visage : yeux, sourcils, bouche, et le trait du visage (doux, anguleux, balafré).
func _face(pal: Dictionary, sk: Array, eyes: Color) -> void:
	var face := int(pal["face"])
	for side: int in [-1, 1]:
		var ex := side
		_put(ex, 19, _front(ex, 19), eyes, true)
		_put(ex, 20, _front(ex, 20), sk[0])
	_put(0, 17, _front(0, 17), sk[0].darkened(0.25))
	if face == 1:
		# Anguleux : mâchoire taillée.
		for side: int in [-1, 1]:
			_clear(side * 3, 16, -1)
			_clear(side * 3, 16, 0)
			_clear(side * 2, 16, -2)
	elif face == 2:
		# Balafré : une cicatrice claire en travers de la joue gauche.
		for q in [Vector3i(-3, 20, 0), Vector3i(-3, 19, 0), Vector3i(-2, 18, 0)]:
			_put(q.x, q.y, _front(q.x, q.y), Color("e8b0a0"))


## Cheveux : calotte sur le haut et l'arrière de la tête, puis longs, tresse ou courts.
func _hair(head: String, hr: Array) -> void:
	for y in range(18, 24):
		var dy := (float(y) - 19.0) / 3.6
		var k := sqrt(maxf(0.0, 1.0 - dy * dy))
		var rx := 3.6 * k + 0.9
		var rz := 3.2 * k + 0.9
		for x in range(-5, 6):
			for z in range(-5, 6):
				var dx := float(x) / rx
				var dz := float(z) / rz
				if dx * dx + dz * dz > 1.0:
					continue
				# Le visage reste dégagé : devant, sous la frange.
				if z < -1 and y < 21 and absi(x) <= 2:
					continue
				if vox.has(Vector3i(x, y, z)) and not (z > -2 or y >= 21):
					continue
				_put(x, y, z, hr[1] if (x * 3 + y + z) % 4 else hr[2])
	# Mèches sur les tempes et la nuque.
	for side: int in [-1, 1]:
		for y in range(17, 20):
			_put(side * 4, y, 1, hr[1])
	for x in range(-3, 4):
		_put(x, 17, 3, hr[0])
		_put(x, 16, 2, hr[0])
	match head:
		"longs":
			for y in range(10, 17):
				for x in range(-3, 4):
					_put(x, y, _back(x, 16) + 1 if y < 16 else 3, hr[1] if (x + y) % 3 else hr[0])
		"tresse":
			for y in range(7, 17):
				_put(0, y, 3, hr[1] if y % 2 == 0 else hr[0])
				_put(-1, y, 3, hr[0] if y % 2 == 0 else hr[1])
			_put(0, 6, 3, Color("6a4a2a"))


## Capuche : une coque autour de la tête, ouverte devant sur le visage, qui retombe sur les épaules.
func _hood(o: Array) -> void:
	for y in range(15, 25):
		var dy := (float(y) - 19.5) / 4.6
		var k := sqrt(maxf(0.0, 1.0 - dy * dy))
		var rx := 3.6 * k + 1.2
		var rz := 3.2 * k + 1.4
		for x in range(-6, 7):
			for z in range(-6, 7):
				var dx := float(x) / rx
				var dz := (float(z) - 0.4) / rz
				var d := dx * dx + dz * dz
				if d > 1.0:
					continue
				if vox.has(Vector3i(x, y, z)) and d < 0.55:
					continue
				# Ouverture du visage.
				if z < 0 and absi(x) <= 2 and y >= 16 and y <= 21:
					continue
				_put(x, y, z, o[2] if d > 0.75 else o[0])
	# Pointe de la capuche, dans le dos.
	_put(0, 24, 3, o[2])
	_put(0, 23, 4, o[2])
	_put(0, 22, 5, o[2])


## Queue (draconique, reptilien) : elle part du bas du dos et descend en s'affinant.
func _tail(sk: Array) -> void:
	var pts := [Vector3i(0, 6, 3), Vector3i(0, 5, 4), Vector3i(1, 4, 5), Vector3i(1, 3, 6), Vector3i(2, 2, 6), Vector3i(2, 1, 7), Vector3i(3, 1, 7)]
	for i in range(pts.size()):
		var q: Vector3i = pts[i]
		_put(q.x, q.y, q.z, sk[1] if i % 2 == 0 else sk[0])
		if i < 3:
			_put(q.x + 1, q.y, q.z, sk[1])


## Voxel d'arme : décalé vers la main du personnage, et retourné dans la main gauche si besoin.
func _pw(x: int, y: int, z: int, c: Color, glow: bool = false) -> void:
	var nx := -x if _mirror else x
	if nx > 0:
		nx += _wx
	elif nx < 0:
		nx -= _wx
	_put(nx, y + _wy, z, c, glow)


## Arme de la classe, dans la main droite (x 5, y 7).
func _weapon(cls: String, o: Array, eyes: Color) -> void:
	var wood := Color("8a5a2b")
	var steel := Color("d8dce8")
	var steel_d := Color("8a90a0")
	var gold := Color("e0b850")
	match cls:
		"archer":
			# Arc tenu droit, la corde vers le héros ; carquois dans le dos.
			for y in range(3, 20):
				var b := int(round(2.4 * sin(PI * float(y - 3) / 16.0)))
				_pw(6, y, -1 - b, wood)
				_pw(6, y, -1, Color(0.92, 0.92, 0.96))
			var held := _part
			_part = "back"
			for y in range(9, 17):
				_pw(-2, y, 3, Color("6a4a2a"))
				_pw(-1, y, 3, Color("6a4a2a"))
			for x in [-2, -1]:
				_pw(x, 17, 3, Color("e8e8f0"))
				_pw(x, 18, 3, Color("c04a3a"))
			_part = held
		"epeiste":
			for y in range(9, 23):
				_pw(6, y, -1, steel if y < 22 else Color.WHITE)
				if y > 10:
					_pw(6, y, -2, steel_d)
			for x in range(5, 8):
				_pw(x, 8, -1, gold)
			_pw(6, 7, -1, Color("5a3a22"))
			_pw(6, 6, -1, gold)
		"clerc":
			for y in range(4, 17):
				_pw(6, y, -1, Color("b08a40"))
			for q in [Vector3i(5, 17, -1), Vector3i(7, 17, -1), Vector3i(6, 18, -1), Vector3i(5, 19, -1), Vector3i(7, 19, -1), Vector3i(6, 20, -1)]:
				_pw(q.x, q.y, q.z, gold)
			_pw(6, 19, -1, Color("fff6c8"), true)
			_pw(6, 17, -1, Color("fff6c8"), true)
		"necromancien":
			for y in range(2, 21):
				_pw(6, y, -1, Color("3a2a3a"))
			for x in range(5, 8):
				for y in range(21, 24):
					_pw(x, y, -1, IVORY)
					_pw(x, y, 0, IVORY)
			_pw(5, 22, -2, Color("8e62e0"), true)
			_pw(7, 22, -2, Color("8e62e0"), true)
			_pw(6, 21, -2, Color("2a2030"))
		"chevalier":
			# Épée dans la main droite, bouclier au bras gauche.
			for y in range(9, 21):
				_pw(6, y, -1, steel)
			for x in range(5, 8):
				_pw(x, 8, -1, gold)
			for y in range(6, 15):
				for z in range(-3, 3):
					var edge := y == 6 or y == 14 or z == -3 or z == 2
					_pw(-6, y, z, Color("a8b0c0") if edge else o[2])
			for y in range(7, 14):
				_pw(-7, y, 0, gold)
			for z in range(-2, 2):
				_pw(-7, 10, z, gold)
		"berserker":
			for y in range(2, 19):
				_pw(6, y, -1, Color("6a4a2a"))
			for y in range(15, 21):
				var w := 3 - absi(y - 18) / 2
				for k in range(1, w + 1):
					_pw(6, y, -1 - k, steel if k < w else Color.WHITE)
					_pw(6, y, -1 + k, steel_d if k < w else steel)
		_:
			# Mage : bâton de bois et orbe lumineuse.
			for y in range(2, 25):
				_pw(6, y, -1, wood)
			for q in [Vector3i(6, 25, -1), Vector3i(5, 26, -1), Vector3i(7, 26, -1), Vector3i(6, 26, -2), Vector3i(6, 26, 0), Vector3i(6, 27, -1)]:
				_pw(q.x, q.y, q.z, eyes.lightened(0.35), true)
			_pw(6, 26, -1, Color.WHITE, true)


# ---------------------------------------------------------------- cosmétiques

## Anneau (coque d'ellipse) dans le plan y : voxels entre deux rayons.
func _ring(y: int, rx: float, rz: float, w: float, c: Color, cz: float = 0.0) -> void:
	for x in range(int(-rx) - 2, int(rx) + 3):
		for z in range(int(-rz) - 2, int(rz) + 3):
			var d := Vector2(float(x) / rx, (float(z) - cz) / rz).length()
			if d <= 1.0 and d >= 1.0 - w:
				_put(x, y, z, c)


## Couvre-chefs des kits.
func _cos_head(kit: String) -> void:
	_part = "head"
	match kit:
		"boulanger":
			# Toque blanche : bandeau, fût, puis le bouffant du dessus.
			_disc(22, 0.0, 0.0, 3.4, 3.1, Color("dcd8d0"))
			for y in range(23, 26):
				_disc(y, 0.0, 0.0, 3.2, 2.9, Color("f6f4ee"))
			for y in range(26, 29):
				_disc(y, 0.0, 0.0, 3.9 - float(y - 26) * 0.6, 3.6 - float(y - 26) * 0.6, Color.WHITE)
		"corsaire":
			# Tricorne noir aux bords dorés, coins relevés, plume rouge.
			_disc(22, 0.0, 0.0, 4.8, 4.5, Color("1a1a1a"))
			_ring(22, 4.8, 4.5, 0.22, Color("e0b850"))
			for a in [-PI * 0.5, PI * 0.5 + 0.9, PI * 0.5 - 0.9]:
				var p := Vector2.from_angle(a) * 4.0
				_put(int(round(p.x)), 23, int(round(p.y)), Color("1a1a1a"))
				_put(int(round(p.x * 1.15)), 24, int(round(p.y * 1.15)), Color("e0b850"))
			for y in range(23, 26):
				_disc(y, 0.0, 0.0, 3.0, 2.8, Color("1a1a1a"))
			for y in range(24, 28):
				_put(-3, y, 1, Color("e84a4a"))
			_put(-4, 27, 2, Color("ff7a6a"))
		"courge":
			# Tête de citrouille : côtes orange, visage sculpté qui luit, tige verte.
			for y in range(15, 24):
				var dy := (float(y) - 19.5) / 4.0
				var k := sqrt(maxf(0.0, 1.0 - dy * dy))
				for x in range(-5, 6):
					for z in range(-5, 6):
						var d := Vector2(float(x) / (4.5 * k + 0.2), float(z) / (4.3 * k + 0.2)).length()
						if d <= 1.0:
							_put(x, y, z, Color("c85a1a") if absi(x) % 2 == 0 and d > 0.7 else Color("e8702a"))
			var glow := Color("ffd050")
			for q in [Vector3i(-2, 20, 0), Vector3i(2, 20, 0), Vector3i(-3, 21, 0), Vector3i(3, 21, 0), Vector3i(-1, 21, 0), Vector3i(1, 21, 0)]:
				_put(q.x, q.y, _front(q.x, q.y), glow, true)
			for x in range(-3, 4):
				_put(x, 17 + (1 if x % 2 == 0 else 0), _front(x, 17), glow, true)
			_put(0, 24, 0, Color("4a7a2a"))
			_put(0, 25, 0, Color("4a7a2a"))
			_put(1, 25, 0, Color("6a9a3a"))
		"carton":
			# Heaume en carton : une boîte, une fente pour les yeux, du ruban adhésif et une plume.
			for y in range(16, 24):
				for x in range(-4, 5):
					for z in range(-4, 5):
						_put(x, y, z, Color("e8d8b8") if x == 0 or y == 23 else Color("c8a070"))
			for x in range(-3, 4):
				_put(x, 20, -4, Color("2a2018"))
			for y in range(24, 27):
				_put(0, y, 1, Color("e84a4a"))
			_put(0, 27, 2, Color("ff7a6a"))
		"ruche":
			# Chapeau de paille et voile à mailles (on devine le visage au travers).
			_disc(22, 0.0, 0.0, 5.2, 5.0, Color("e8c870"))
			for y in range(23, 25):
				_disc(y, 0.0, 0.0, 3.0, 2.9, Color("d8b050"))
			for y in range(16, 22):
				for x in range(-5, 6):
					for z in range(-5, 6):
						var d2 := Vector2(float(x) / 4.6, float(z) / 4.4).length()
						if d2 <= 1.0 and d2 >= 0.78 and (x + y + z) % 2 == 0:
							_put(x, y, z, Color("dcdce8"))
		"grenouille":
			# Capuche-grenouille : coque verte ouverte sur le visage, deux gros yeux ronds sur le dessus.
			_hood([Color("1a4a1a"), Color("2a6a2a"), Color("4aa04a"), Color("8fd06a")])
			for side: int in [-1, 1]:
				for x in range(-1, 2):
					for y in range(-1, 2):
						for z in range(-1, 2):
							if absi(x) + absi(y) + absi(z) <= 2:
								_put(side * 2 + x, 24 + y, -1 + z, Color("f0f0e8"))
				_put(side * 2, 24, -3, Color("1a1a1a"))
				_put(side * 2, 25, -2, Color("4aa04a"))
		"sporelin":
			# Chapeau d'amanite : grand dôme rouge à pois blancs, lamelles claires dessous.
			for y in range(22, 27):
				var rr := 5.6 - float(y - 22) * 1.0
				_disc(y, 0.0, 0.0, rr, rr * 0.95, Color("d83a3a"))
			for x in range(-6, 7):
				for z in range(-6, 7):
					for y in range(22, 27):
						if vox.has(Vector3i(x, y, z)) and (x * 7 + z * 3 + y * 5) % 6 == 0:
							_put(x, y, z, Color("f6f0e8"))
			_ring(22, 5.6, 5.3, 0.3, Color("e8dcc0"))
		"stellaire":
			# Couronne d'étoiles : un cercle d'or et cinq pointes qui luisent.
			_ring(22, 3.9, 3.6, 0.28, Color("e0b850"))
			for i in range(5):
				var p2 := Vector2.from_angle(-PI * 0.5 + float(i) * TAU / 5.0)
				var x2 := int(round(p2.x * 3.6))
				var z2 := int(round(p2.y * 3.3))
				_put(x2, 23, z2, Color("fff0a0"), true)
				_put(x2, 24, z2, Color("fffbe0"), true)


## Motifs des tenues (la palette est déjà appliquée au corps).
func _cos_tenue(kit: String, y0: int) -> void:
	match kit:
		"boulanger":
			# Tablier crème taché de farine.
			for y in range(y0 + 1, 11):
				for x in range(-2, 3):
					_put(x, y, _front(x, y), Color("ffffff") if (x * 3 + y) % 5 == 0 else Color("e8d8b0"))
		"corsaire":
			# Revers noirs et boutons d'or.
			for y in range(9, 15):
				for side: int in [-1, 1]:
					_put(side * 2, y, _front(side * 2, y), Color("1a1a1a"))
			for y in range(y0 + 2, 13, 2):
				_put(0, y, _front(0, y), Color("e0b850"))
		"courge":
			for x in range(-6, 7):
				for z in range(-4, 5):
					for y in range(y0, 15, 3):
						if vox.has(Vector3i(x, y, z)):
							_put(x, y, z, Color("1a1a1a"))
		"carton":
			# Ruban adhésif en travers et un blason dessiné au feutre.
			for y in range(y0, 15):
				var x := (y - y0) % 9 - 4
				_put(x, y, _front(x, y), Color("e8d8b8"))
				_put(x, y, _back(x, y), Color("e8d8b8"))
			for q in [Vector2i(-1, 8), Vector2i(0, 8), Vector2i(1, 8), Vector2i(0, 7), Vector2i(-1, 9), Vector2i(1, 9), Vector2i(0, 9)]:
				_put(q.x, q.y, _front(q.x, q.y), Color("c83a3a"))
		"ruche":
			# Fermeture éclair et ceinture jaune.
			for y in range(y0, 15):
				_put(0, y, _front(0, y), Color("a8b0c0"))
			for x in range(-6, 7):
				for z in range(-4, 5):
					if vox.has(Vector3i(x, 9, z)):
						_put(x, 9, z, Color("e8b83a"))
		"grenouille":
			# Ventre clair.
			for y in range(y0 + 1, 12):
				for x in range(-2, 3):
					if absi(x) + absi(y - 7) / 2 <= 3:
						_put(x, y, _front(x, y), Color("d8e8a0"))
		"sporelin":
			# Petits chapeaux rouges sur l'ourlet.
			for x in range(-5, 6, 2):
				_put(x, y0 + 1, _front(x, y0 + 1), Color("d83a3a"))
				_put(x, y0 + 1, _back(x, y0 + 1), Color("d83a3a"))
		"stellaire":
			# Étoiles brodées qui luisent.
			for x in range(-6, 7):
				for z in range(-4, 5):
					for y in range(y0, 15):
						if vox.has(Vector3i(x, y, z)) and (x * 13 + z * 7 + y * 11) % 17 == 0:
							_put(x, y, z, Color("fff0a0"), true)


## Pièces de dos.
func _cos_back(kit: String, sk: Array) -> void:
	match kit:
		"boulanger":
			# Sac de farine, rayé de bleu, noué en haut.
			for y in range(7, 14):
				for x in range(-3, 3):
					for z in range(3, 6):
						_put(x, y, z, Color("5a7ac8") if y == 10 else Color("e8dcc0"))
			_put(-1, 14, 4, Color("8a5a2b"))
			_put(0, 14, 4, Color("8a5a2b"))
		"corsaire":
			# Perroquet sur l'épaule droite : rouge, aile verte, bec jaune, queue bleue.
			for q in [Vector3i(4, 15, 0), Vector3i(4, 16, 0), Vector3i(4, 16, -1), Vector3i(4, 17, -1)]:
				_put(q.x, q.y, q.z, Color("e8322a"))
			_put(5, 15, 0, Color("3aa84a"))
			_put(5, 16, 1, Color("3aa84a"))
			_put(4, 17, -2, Color("f2c83a"))
			_put(4, 18, -1, Color("e8322a"))
			_put(4, 14, 1, Color("3a6ac8"))
			_put(4, 13, 2, Color("3a6ac8"))
			_put(3, 17, -2, Color("1a1a1a"))
		"courge":
			for y in range(3, 15):
				var half := 4 if y < 12 else 3
				for x in range(-half, half + 1):
					var leaf := [Color("e8702a"), Color("c84a2a"), Color("8a5a2a"), Color("e8b84a")]
					_put(x, y, 3 if y >= 8 else 4, leaf[(x * 5 + y * 3 + 7) % 4])
		"carton":
			for y in range(3, 15):
				var half2 := 4 if y < 12 else 3
				for x in range(-half2, half2 + 1):
					_put(x, y, 3 if y >= 8 else 4, Color("c83a3a") if (x + y) % 2 == 0 else Color("f0ece0"))
		"ruche":
			# Ruche portative en anneaux, son entrée, et trois abeilles qui tournent autour.
			for y in range(6, 15):
				var rr := 3.2 - absf(float(y) - 10.0) * 0.32
				for x in range(-4, 5):
					for z in range(2, 9):
						if Vector2(float(x) / rr, (float(z) - 5.0) / (rr * 0.9)).length() <= 1.0:
							_put(x, y, z, Color("a87a1a") if y % 2 == 0 else Color("e8b83a"))
			_put(0, 8, _back(0, 8), Color("2a1a0a"))
			for q in [Vector3i(4, 14, 6), Vector3i(-4, 12, 7), Vector3i(3, 16, 5)]:
				_put(q.x, q.y, q.z, Color("f2c83a"), true)
		"grenouille":
			# Nénuphar porte-bonheur dans le dos, et sa fleur rose.
			for y in range(5, 15):
				for x in range(-5, 6):
					var d := Vector2(float(x), float(y) - 10.0).length()
					if d <= 4.6 and not (x >= 0 and absi(y - 10) <= 0 and x <= 4):
						_put(x, y, 4, Color("3a8a3a") if d < 3.6 else Color("2a6a2a"))
			for q in [Vector3i(0, 13, 5), Vector3i(-1, 13, 5), Vector3i(1, 13, 5), Vector3i(0, 14, 5)]:
				_put(q.x, q.y, q.z, Color("f0a0c0"))
			_put(0, 13, 6, Color("f2c83a"))
		"sporelin":
			# Hotte d'osier, des champignons qui en sortent.
			for y in range(7, 14):
				for x in range(-3, 4):
					for z in range(3, 6):
						_put(x, y, z, Color("8a5a2b") if (x + y) % 2 == 0 else Color("6a4220"))
			for q in [Vector3i(-2, 14, 4), Vector3i(1, 14, 4), Vector3i(2, 15, 5)]:
				_put(q.x, q.y, q.z, Color("e8dcc0"))
				_put(q.x, q.y + 1, q.z, Color("d83a3a"))
				_put(q.x + 1, q.y + 1, q.z, Color("d83a3a"))
		"stellaire":
			for y in range(2, 15):
				var half3 := 4 if y < 12 else 3
				for x in range(-half3, half3 + 1):
					var star := (x * 7 + y * 5) % 11 == 0
					_put(x, y, 3 if y >= 8 else 4, Color("fff0a0") if star else Color("14204a"), star)


## Armes cosmétiques (par-dessus l'arme de la classe), dans la main droite.
func _cos_weapon(kit: String) -> void:
	match kit:
		"boulanger":
			# Baguette dorée, entaillée.
			for y in range(4, 19):
				for z in [-1, -2]:
					_pw(6, y, z, Color("f0c070") if y % 3 == 0 and z == -2 else Color("d89a4a"))
		"corsaire":
			# Sabre courbe à garde d'or.
			for y in range(9, 21):
				var cz := -1 - int(round(1.6 * sin(PI * float(y - 9) / 14.0)))
				_pw(6, y, cz, Color("d8dce8") if y < 20 else Color.WHITE)
			for x in range(5, 8):
				_pw(x, 8, -1, Color("e0b850"))
			_pw(6, 7, -1, Color("3a2a1a"))
			_pw(6, 6, -1, Color("e0b850"))
		"courge":
			# Lanterne-courge au bout d'un bâton.
			for y in range(4, 17):
				_pw(6, y, -1, Color("6a4a2a"))
			for x in range(5, 8):
				for y in range(15, 18):
					for z in range(-3, -1):
						_pw(x, y, z, Color("e8702a"))
			_pw(6, 16, -4, Color("ffd050"), true)
			_pw(6, 18, -2, Color("4a7a2a"))
		"carton":
			# Épée de bois, garde clouée.
			for y in range(9, 20):
				for z in [-1, -2]:
					_pw(6, y, z, Color("c8a070") if y < 19 else Color("e0c090"))
			for x in range(5, 8):
				_pw(x, 8, -1, Color("8a5a2b"))
			_pw(6, 8, -2, Color("a8b0c0"))
			_pw(6, 7, -1, Color("6a4a2a"))
		"ruche":
			# Enfumoir de métal, et sa fumée.
			for y in range(5, 11):
				for x in range(6, 8):
					for z in range(-2, 0):
						_pw(x, y, z, Color("a8b0c0") if y > 5 else Color("6a4a2a"))
			for q in [Vector3i(7, 12, -1), Vector3i(6, 13, -2), Vector3i(7, 15, -1), Vector3i(6, 16, -2)]:
				_pw(q.x, q.y, q.z, Color("dcdce8"))
		"grenouille":
			# Parapluie ouvert, au-dessus de la tête.
			for y in range(6, 24):
				_pw(6, y, -1, Color("2a2a2a"))
			_pw(5, 6, -1, Color("2a2a2a"))
			for y in range(23, 26):
				var rr := 5.0 - float(y - 23) * 1.6
				for x in range(-5, 6):
					for z in range(-5, 6):
						if Vector2(float(x), float(z)).length() <= rr:
							_pw(6 + x if 6 + x != 0 else 1, y, -1 + z, Color("8fd06a") if (x + z) % 3 == 0 else Color("4aa04a"))
		"sporelin":
			for y in range(2, 20):
				_pw(6, y, -1, Color("8a5a2b"))
			for y in range(20, 23):
				var rr2 := 2.6 - float(y - 20) * 0.8
				for x in range(-3, 4):
					for z in range(-3, 4):
						if Vector2(float(x), float(z)).length() <= rr2:
							_pw(6 + x, y, -1 + z, Color("f6f0e8") if (x + z + y) % 3 == 0 else Color("d83a3a"))
		"stellaire":
			# Sceptre d'argent, étoile filante à sa pointe.
			for y in range(6, 20):
				_pw(6, y, -1, Color("d8dce8") if y % 4 else Color("e0b850"))
			for q in [Vector3i(6, 21, -1), Vector3i(5, 21, -1), Vector3i(7, 21, -1), Vector3i(6, 22, -1), Vector3i(6, 20, -1)]:
				_pw(q.x, q.y, q.z, Color("fff0a0"), true)
			for q in [Vector3i(6, 19, 1), Vector3i(6, 18, 2), Vector3i(6, 17, 3)]:
				_pw(q.x, q.y, q.z, Color("8fb8ff"), true)


# ---------------------------------------------------------------- compagnons

func build_companion(who: String, cls: String) -> void:
	vox.clear()
	_cache.clear()
	_wx = 0
	_wy = 0
	_mirror = false
	_keep = false
	pivots = HERO_PIVOTS.duplicate() if who != "brann" else BRANN_PIVOTS.duplicate()
	match who:
		"brann":
			_brann(cls)
		"sylwen":
			_sylwen(cls)
		"krag":
			_krag(cls)
		"nyx":
			_nyx(cls)
		"ignara":
			_ignara(cls)
		"ssareth":
			_ssareth(cls)
		"durgan":
			_durgan()
	_build_surface()


## Brann : nain chevalier. Casque d'acier à cornes et nasal, barbe rousse tressée aux perles d'or, armure sous
## un tabard rouge, cape rouge, bouclier rond (au bras s'il est chevalier, dans le dos sinon). Plus petit.
func _brann(cls: String) -> void:
	var steel := Color("7a849c")
	var steel_l := Color("c8d0e0")
	var steel_d := Color("4a5068")
	var red := Color("a83a3a")
	var red_d := Color("7a2a2a")
	var gold := Color("d8b048")
	var wood := Color("7a5230")
	var beard := Color("d9773a")
	var beard_d := Color("b8582a")
	var skin := Color("d08a6a")
	var boot := Color("3a2e2a")
	# Jambières et bottes.
	_part = "legs"
	for side: int in [-2, 1]:
		for y in range(0, 4):
			for x in range(side, side + 2):
				for z in range(-1, 1):
					_put(x, y, z, boot if y == 0 else steel)
	# Corps trapu en armure, tabard rouge devant et derrière, ceinture à boucle d'or.
	_part = "body"
	for y in range(4, 12):
		var rx := 4.7 + (0.4 if y >= 6 and y <= 9 else 0.0)
		_disc(y, 0.0, 0.0, rx, 3.0, steel)
	for y in range(3, 11):
		for x in range(-2, 3):
			_put(x, y, _front(x, y), red if y > 3 else gold)
			_put(x, y, _back(x, y), red)
	for x in range(-5, 6):
		for z in range(-4, 5):
			if vox.has(Vector3i(x, 6, z)):
				_put(x, 6, z, wood)
	_put(0, 6, _front(0, 6), gold)
	# Cape rouge dans le dos, des épaules aux mollets.
	_part = "cape"
	for y in range(2, 12):
		var half := 4 if y < 10 else 3
		for x in range(-half, half + 1):
			_put(x, y, 4, red_d if (x + y) % 5 else red)
	# Épaulières, bras d'acier, gantelets.
	_part = "arms"
	for side: int in [-1, 1]:
		for y in range(10, 12):
			for x in range(5, 7):
				for z in range(-1, 2):
					_put(side * x, y, z, steel_l)
		for y in range(5, 10):
			_put(side * 6, y, 0, steel)
			_put(side * 6, y, -1, steel)
		_put(side * 6, 4, 0, steel_d)
		_put(side * 6, 4, -1, steel_d)
	# Tête.
	_part = "head"
	for y in range(12, 19):
		var dy := (float(y) - 15.0) / 3.4
		var k := sqrt(maxf(0.0, 1.0 - dy * dy))
		_disc(y, 0.0, 0.0, 3.4 * k + 0.15, 3.1 * k + 0.15, skin)
	# Casque : coque d'acier sur le haut, bandeau aux rivets d'or, nasal, cornes d'ivoire.
	for y in range(15, 20):
		var dy2 := (float(y) - 15.0) / 4.2
		var k2 := sqrt(maxf(0.0, 1.0 - dy2 * dy2))
		for x in range(-5, 6):
			for z in range(-5, 6):
				var dx := float(x) / (3.4 * k2 + 0.9)
				var dz := float(z) / (3.1 * k2 + 0.9)
				if dx * dx + dz * dz <= 1.0:
					_put(x, y, z, steel_d if y == 15 else steel)
	for x in range(-4, 5):
		for z in range(-4, 5):
			if vox.has(Vector3i(x, 15, z)) and (x * 3 + z) % 4 == 0:
				_put(x, 15, z, gold)
	for y in range(13, 16):
		_put(0, y, _front(0, y) - (1 if y < 15 else 0), steel_l)
	for side: int in [-1, 1]:
		for q in [Vector3i(4, 16, 0), Vector3i(5, 16, 0), Vector3i(6, 17, 0), Vector3i(6, 18, 0), Vector3i(7, 19, 1)]:
			_put(side * q.x, q.y, q.z, IVORY)
	# Yeux sombres sous le casque.
	for side: int in [-1, 1]:
		_put(side, 14, _front(side, 14), Color("2a1a1a"))
	# Barbe rousse : de la bouche à la ceinture, deux tresses aux perles d'or ; moustache.
	for y in range(7, 14):
		var half2 := 3 - (13 - y) / 3
		for x in range(-half2, half2 + 1):
			_put(x, y, _front(x, y) - (0 if y > 11 else 1), beard if (x + y) % 3 else beard_d)
	for side: int in [-1, 1]:
		for y in range(5, 8):
			_put(side * 2, y, _front(side * 2, 9) - 1, beard_d if y % 2 else beard)
		_put(side * 2, 4, _front(side * 2, 9) - 1, gold)
	for x in range(-2, 3):
		_put(x, 13, _front(x, 13), beard_d)
	# Arme : sa main est plus bas et plus écartée que celle du héros.
	_part = "hand"
	_wx = 1
	_wy = -3
	_weapon(cls, [steel_d, red_d, red, beard], Color("d8b048"))
	if cls != "chevalier":
		# Le bouclier rond, dans le dos.
		_part = "back"
		for y in range(4, 13):
			for x in range(-4, 5):
				var d := Vector2(float(x), float(y) - 8.0).length()
				if d <= 4.2:
					var rim := d > 3.2
					var cross := x == 0 or y == 8
					_put(x, y, 5, gold if rim or cross else wood)


## Sylwen : elfe archère. Capuche et mantelet verts, oreilles qui en sortent, frange et tresse blondes sur
## l'épaule droite, tunique verte ceinturée d'or, carquois dans le dos, arc tenu dans la main gauche.
func _sylwen(cls: String) -> void:
	var skin := Color("f0d0b0")
	var skin_d := Color("d8b090")
	var hair := Color("e8c870")
	var hair_d := Color("b8983a")
	var hood := Color("3f7a4a")
	var hood_d := Color("2a5a36")
	var tunic := Color("4a8a5a")
	var tunic_d := Color("2f5a3a")
	var belt := Color("b8983a")
	var legs := Color("3a2e2a")
	var eyes := Color("4f9a3a")
	# Jambes (chausses sombres), bottes.
	_part = "legs"
	for side: int in [-2, 1]:
		for y in range(0, 6):
			for x in range(side, side + 2):
				for z in range(-1, 1):
					_put(x, y, z, Color("2a2018") if y == 0 else legs)
	# Tunique, ceinture d'or, ourlet.
	_part = "body"
	for y in range(6, 15):
		var rx := 4.4 if y < 8 else (4.0 if y <= 10 else lerpf(4.0, 4.4, float(y - 10) / 4.0))
		_disc(y, 0.0, 0.0, rx, 2.5, tunic)
	for x in range(-5, 6):
		for z in range(-4, 5):
			if vox.has(Vector3i(x, 6, z)):
				_put(x, 6, z, tunic_d)
			if vox.has(Vector3i(x, 10, z)):
				_put(x, 10, z, belt)
	# Mantelet vert sur les épaules.
	_part = "body"
	_disc(14, 0.0, 0.0, 4.8, 3.0, hood)
	_disc(13, 0.0, 0.0, 4.6, 2.9, hood_d)
	# Bras (manches sombres) et mains.
	_part = "arms"
	for side: int in [-1, 1]:
		for y in range(8, 14):
			_put(side * 5, y, 0, tunic_d)
			_put(side * 5, y, -1 if y < 11 else 0, tunic_d)
		_put(side * 5, 7, 0, skin)
		_put(side * 5, 7, -1, skin)
	# Cou, tête, visage.
	_part = "head"
	_put(0, 15, 0, skin_d)
	for y in range(16, 23):
		var dy := (float(y) - 19.0) / 3.6
		var k := sqrt(maxf(0.0, 1.0 - dy * dy))
		_disc(y, 0.0, 0.0, 3.5 * k + 0.15, 3.1 * k + 0.15, skin)
	for side: int in [-1, 1]:
		_put(side, 19, _front(side, 19), eyes, true)
		_put(side, 20, _front(side, 20), hair_d)
	_put(0, 17, _front(0, 17), Color("c8907a"))
	# Capuche verte (ouverte sur le visage), frange blonde, oreilles qui sortent sur les côtés.
	_hood([hood_d, hood_d, hood, hood])
	for x in range(-2, 3):
		_put(x, 21, _front(x, 21), hair)
		if absi(x) < 2:
			_put(x, 20, _front(x, 20) if x != 0 else _front(x, 20), hair if x == 0 else hair_d)
	for side: int in [-1, 1]:
		_put(side * 5, 19, 0, skin)
		_put(side * 6, 20, 1, skin)
		_put(side * 7, 21, 1, skin_d)
	# Tresse blonde sur l'épaule droite, devant.
	_part = "body"
	for y in range(8, 16):
		_put(3, y, -3, hair if y % 2 == 0 else hair_d)
	_put(3, 7, -3, hood_d)
	# Carquois dans le dos (côté droit) et ses plumes.
	_part = "back"
	if cls == "archer":
		for y in range(9, 17):
			_put(1, y, 3, Color("6a4a2a"))
			_put(2, y, 3, Color("6a4a2a"))
		for x in [1, 2]:
			_put(x, 17, 3, Color("e8e4d8"))
			_put(x, 18, 3, Color("e8e4d8"))
		# Arc dans la main gauche.
		_part = "hand"
		_mirror = true
		for y in range(3, 20):
			var b2 := int(round(2.4 * sin(PI * float(y - 3) / 16.0)))
			_pw(6, y, -1 - b2, Color("8a5a2b"))
			_pw(6, y, -1, Color(0.92, 0.92, 0.96))
		_mirror = false
	else:
		_part = "hand"
		_weapon(cls, [hood_d, tunic_d, tunic, hood], eyes)


## Durgan Enclume, le forgeron : vieux nain chauve au crâne noirci de suie, grande barbe grise tressée d'anneaux de
## fer, lunettes de forge (partie « goggles » : relevées sur le front, elles descendent sur les yeux), manches
## retroussées sur des avant-bras noueux, tablier de cuir à sangles, marteau de forge dans la main droite.
func _durgan() -> void:
	pivots = BRANN_PIVOTS.duplicate()
	pivots["goggles"] = Vector3(0, 17, -2)
	var skin := [Color("8a4a3a"), Color("c07a5a"), Color("e0a07a")]
	var grey := [Color("5a5a68"), Color("9a9aa8"), Color("cfcfd8"), Color("f0f0f6")]
	var tunic := [Color("3a1e14"), Color("6a3420"), Color("8a4a2a")]
	var leather := [Color("2a1a10"), Color("4a2e1a"), Color("6a4428"), Color("8a5e38")]
	var brass := Color("e0a840")
	var iron := [Color("2a2834"), Color("4a4858"), Color("7a7890"), Color("b0aec0")]
	# Jambes (chausses) et bottes de cuir.
	_part = "legs"
	for side: int in [-2, 1]:
		for y in range(0, 4):
			for x in range(side, side + 2):
				for z in range(-1, 1):
					_put(x, y, z, leather[0] if y < 2 else tunic[0])
	# Corps trapu, tunique.
	_part = "body"
	for y in range(4, 12):
		var rx := 4.8 + (0.4 if y >= 6 and y <= 9 else 0.0)
		_disc(y, 0.0, 0.0, rx, 3.1, tunic[1] if (y + 1) % 4 else tunic[2])
	# Tablier de cuir devant, sangles sur les épaules, poche aux outils.
	for y in range(3, 11):
		for x in range(-3, 4):
			_put(x, y, _front(x, y) - (1 if y < 4 else 0), leather[2] if absi(x) < 3 else leather[1])
	for y in range(10, 12):
		for side: int in [-1, 1]:
			_put(side * 2, y, _front(side * 2, y), leather[1])
			_put(side * 2, y, _back(side * 2, y), leather[1])
	for x in range(-2, 1):
		_put(x, 6, _front(x, 6) - 1, leather[3])
	_put(-1, 7, _front(-1, 7) - 1, iron[2])
	_put(-2, 7, _front(-2, 7) - 1, iron[1])
	# Ceinture.
	for x in range(-6, 7):
		for z in range(-4, 5):
			if vox.has(Vector3i(x, 4, z)) and str(vox[Vector3i(x, 4, z)][2]) == "body":
				_put(x, 4, z, leather[1])
	# Bras : manches retroussées, avant-bras nus, brassard de cuir à droite, mains noircies.
	_part = "arms"
	for side: int in [-1, 1]:
		for y in range(9, 12):
			for x in range(5, 7):
				for z in range(-1, 1):
					_put(side * x, y, z, tunic[2] if y > 9 else tunic[1])
		for y in range(5, 9):
			_put(side * 6, y, 0, skin[1] if side < 0 or y > 7 else leather[2])
			_put(side * 6, y, -1, skin[2] if side < 0 or y > 7 else leather[3])
		_put(side * 6, 4, 0, skin[0])
		_put(side * 6, 4, -1, skin[0])
	# Tête chauve, suie, oreilles, nez épais, yeux sous des sourcils broussailleux.
	_part = "head"
	for y in range(12, 19):
		var dy := (float(y) - 15.0) / 3.4
		var k := sqrt(maxf(0.0, 1.0 - dy * dy))
		_disc(y, 0.0, 0.0, 3.4 * k + 0.15, 3.1 * k + 0.15, skin[1])
	_keep = true
	for p in vox.keys():
		var q: Vector3i = p
		if str(vox[q][2]) == "head" and q.y >= 17 and (q.x * 5 + q.z * 3 + q.y) % 4 == 0:
			_put(q.x, q.y, q.z, skin[0])
	_keep = false
	for side: int in [-1, 1]:
		_put(side * 4, 15, 0, skin[1])
		_put(side, 15, _front(side, 15), Color("1a1010"))
		_put(side, 16, _front(side, 16), grey[1])
		_put(side * 2, 16, _front(side * 2, 16), grey[1])
	_put(0, 14, _front(0, 14) - 1, skin[0])
	_put(0, 15, _front(0, 15) - 1, skin[1])
	# Barbe grise, longue, tressée, avec deux anneaux de fer ; moustache.
	for y in range(6, 15):
		for x in range(-3, 4):
			var w := 3 if y > 11 else (2 if y > 8 else 1)
			if absi(x) > w:
				continue
			var ring := (y == 9 or y == 7) and absi(x) <= 1
			_put(x, y, _front(x, y) - (1 if y < 12 else 0), iron[2] if ring else (grey[2] if (x + y) % 3 else grey[1]))
	for x in range(-3, 4):
		_put(x, 14, _front(x, 14), grey[3] if absi(x) > 1 else grey[2])
	# Lunettes de forge : sangle de cuir autour du crâne, deux verres cerclés de laiton, relevées sur le front.
	_part = "goggles"
	for x in range(-4, 5):
		for z in range(-4, 5):
			var d := Vector2(float(x) / 3.6, float(z) / 3.3).length()
			if d <= 1.08 and d >= 0.85 and z >= -1:
				_put(x, 17, z, leather[0])
	for side: int in [-1, 1]:
		var cx := side * 2 - (1 if side < 0 else 0)
		for q in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			_put(cx + q.x, 17 + q.y, -4, Color("7ad0e0"), q.x == 0 and q.y == 1)
		for q in [Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, -1), Vector2i(1, -1)]:
			_put(cx + q.x, 17 + q.y, -4, brass)
	_put(0, 17, -4, leather[1])
	# Marteau de forge dans la main droite : manche de bois, tête d'acier (dans l'axe avant-arrière).
	_part = "hand"
	_wx = 1
	_wy = -3
	for y in range(3, 14):
		_pw(6, y, -1, Color("6a4428") if y % 3 else Color("4a2e1a"))
	for y in range(14, 17):
		for z in range(-4, 3):
			_pw(6, y, z, iron[3] if (z == -4 or z == 2) else (iron[2] if y == 16 else iron[1]))
			_pw(5, y, z, iron[1])
			_pw(7, y, z, iron[1])


## Corps commun des autres compagnons : jambes, robe longue ou tunique, ceinture, col, bras et mains, cou, tête
## et yeux. wide : carrure en plus (bras plus écartés au-delà de 0,9). Les traits propres viennent ensuite.
func _comp_body(o: Array, sk: Array, eyes: Color, tunic: bool, wide: float = 0.0, glow_eyes: bool = false, belt: Color = Color("6a4a2a")) -> void:
	var boot := Color("2a2030")
	_part = "legs"
	for side: int in [-2, 1]:
		for y in range(0, 6 if tunic else 3):
			for x in range(side, side + 2):
				for z in range(-1, 1):
					_put(x, y, z, boot if y == 0 else (o[0] if tunic else boot))
	_part = "body"
	var y0 := 6 if tunic else 2
	for y in range(y0, 15):
		var f := clampf(float(y - 2) / 8.0, 0.0, 1.0)
		var rx := (lerpf(5.6, 4.1, f) if y <= 10 else lerpf(4.1, 4.6, float(y - 10) / 4.0)) + wide
		var rz := (lerpf(3.3, 2.5, f) if y <= 10 else 2.5) + wide * 0.4
		if tunic:
			rx = (4.2 if y < 8 else (4.0 if y <= 10 else lerpf(4.0, 4.5, float(y - 10) / 4.0))) + wide
			rz = 2.5 + wide * 0.4
		_disc(y, 0.0, 0.0, rx, rz, o[2])
	for x in range(-7, 8):
		for z in range(-5, 6):
			if vox.has(Vector3i(x, y0, z)):
				_put(x, y0, z, o[3])
			if vox.has(Vector3i(x, 10, z)):
				_put(x, 10, z, belt)
	_disc(14, 0.0, 0.0, 3.0 + wide * 0.5, 2.2, o[3])
	_part = "arms"
	var aw := 6 if wide >= 0.9 else 5
	for side: int in [-1, 1]:
		var ax := side * aw
		for y in range(8, 14):
			_put(ax, y, 0, o[1])
			_put(ax, y, -1 if y < 11 else 0, o[1])
			if y > 11:
				_put(ax - side, y, 0, o[1])
		_put(ax, 7, 0, sk[1])
		_put(ax, 7, -1, sk[1])
	_part = "head"
	_put(0, 15, 0, sk[0])
	_put(-1, 15, 0, sk[0])
	for y in range(16, 23):
		var dy := (float(y) - 19.0) / 3.6
		var k := sqrt(maxf(0.0, 1.0 - dy * dy))
		_disc(y, 0.0, 0.0, 3.6 * k + 0.15, 3.2 * k + 0.15, sk[1])
	for side: int in [-1, 1]:
		_put(side, 19, _front(side, 19), eyes, glow_eyes)
	_put(0, 17, _front(0, 17), sk[0].darkened(0.25))


## Krag : jeune orc berserker, plus large. Peau verte, crâne rasé sur les côtés, crête et chignon noirs, peintures
## de guerre rouges, crocs, collier de crocs à la pierre d'ambre, cape de fourrure, pagne de cuir.
func _krag(cls: String) -> void:
	pivots = HERO_PIVOTS.duplicate()
	pivots["armR"] = Vector3(6, 13.5, -0.5)
	pivots["armL"] = Vector3(-6, 13.5, -0.5)
	pivots["wpnR"] = Vector3(6.5, 7, -1)
	pivots["wpnL"] = Vector3(-6.5, 7, -1)
	var sk := [Color("3a5a2e"), Color("5a8a44"), Color("7aaa5a")]
	var fur := [Color("4a3420"), Color("7a5a30"), Color("a8804a"), Color("c8a068")]
	var leather := [Color("2a1a10"), Color("4a3020"), Color("6a4628"), Color("8a6038")]
	var hair := Color("1a1418")
	_comp_body(leather, sk, Color("e8a33d"), true, 1.0, false, Color("3a2414"))
	# Torse nu au-dessus de la ceinture : la peau verte, des sangles de cuir en croix.
	_part = "body"
	_keep = true
	for y in range(11, 15):
		for x in range(-6, 7):
			for z in range(-4, 5):
				if vox.has(Vector3i(x, y, z)) and str(vox[Vector3i(x, y, z)][2]) == "body":
					_put(x, y, z, sk[1] if (x + y) % 5 else sk[2])
	for k in range(0, 5):
		_put(-2 + k, 14 - k, _front(-2 + k, 14 - k), leather[2])
		_put(2 - k, 14 - k, _front(2 - k, 14 - k), leather[1])
	_keep = false
	# Collier de crocs et pierre d'ambre.
	for x in range(-2, 3):
		_put(x, 14, _front(x, 14) - 1, IVORY if x % 2 == 0 else fur[1])
	_put(0, 13, _front(0, 13) - 1, Color("e8a33d"), true)
	# Cape de fourrure sur les épaules et dans le dos.
	_part = "cape"
	for y in range(5, 15):
		var half := 5 if y > 11 else 4
		for x in range(-half, half + 1):
			_put(x, y, 4 if y >= 8 else 5, fur[1] if (x * 3 + y) % 4 else fur[2])
	_part = "body"
	for x in range(-6, 7):
		for z in range(-4, 5):
			var d := Vector2(float(x) / 6.2, float(z) / 3.6).length()
			if d <= 1.0 and d > 0.55:
				_put(x, 15, z, fur[2] if (x + z) % 3 else fur[3])
	# Tête : bras plus larges, oreilles pointues, crocs, peintures, crête et chignon.
	_part = "head"
	for side: int in [-1, 1]:
		_put(side * 4, 19, 0, sk[1])
		_put(side * 5, 20, 0, sk[2])
		_put(side * 1, 16, _front(side, 16) - 1, IVORY)
		_put(side * 1, 18, _front(side, 18), Color("a83a2a"))
		_put(side * 2, 18, _front(side * 2, 18), Color("a83a2a"))
		_put(side * 1, 20, _front(side, 20), hair)
	for y in range(21, 25):
		for z in range(-3, 4):
			if Vector2(0.0, float(z)).length() <= 3.4 - float(y - 21) * 0.4:
				_put(0, y, z, hair)
				_put(-1 if y < 23 else 0, y, z, hair)
	for q in [Vector3i(0, 22, 3), Vector3i(0, 23, 4), Vector3i(0, 24, 4), Vector3i(-1, 23, 4), Vector3i(0, 25, 4)]:
		_put(q.x, q.y, q.z, hair)
	_put(0, 22, 4, Color("e8a33d"))
	_part = "hand"
	_wx = 1
	_weapon(cls, leather, Color("e8a33d"))


## Nyx : fée nécromancienne, plus menue. Peau lavande, cheveux cendrés en bataille, yeux violets qui luisent,
## ailes de phalène, robe longue violette, pendentif d'os.
func _nyx(cls: String) -> void:
	pivots = HERO_PIVOTS.duplicate()
	var sk := [Color("9a88a8"), Color("cbb8d4"), Color("e8dcf0")]
	var robe := [Color("1e1430"), Color("2e2048"), Color("3a2a5a"), Color("5a3a8a")]
	var hair := [Color("3a3448"), Color("5e5872"), Color("8a84a0")]
	var wing := [Color("3a3050"), Color("5a4a78"), Color("8a7aa8"), Color("b8a8d8")]
	_comp_body(robe, sk, Color("c8a0ff"), false, -0.3, true, Color("5a4a78"))
	# Ailes de phalène : deux paires, des ocelles.
	_part = "back"
	for side: int in [-1, 1]:
		for y in range(6, 19):
			var up := y >= 12
			var span := (6 - absi(y - 15) / 2) if up else (4 - absi(y - 9) / 2)
			for k in range(span):
				var edge := k == span - 1 or y == 6 or y == 18
				var eye := up and k == 3 and y == 15
				_put(side * (2 + k), y, 3 + k / 3, wing[0] if edge else (Color("e8c8ff") if eye else wing[2 if (k + y) % 3 else 1]), eye)
	# Pendentif d'os.
	_part = "body"
	_put(0, 13, _front(0, 13) - 1, Color("8a8678"))
	_put(0, 12, _front(0, 12) - 1, IVORY)
	# Petites oreilles pointues, cheveux cendrés en bataille.
	_part = "head"
	for side: int in [-1, 1]:
		_put(side * 4, 19, 0, sk[1])
		_put(side * 5, 20, 1, sk[2])
	_hair("courts", hair)
	for q in [Vector3i(-2, 24, 0), Vector3i(1, 24, -1), Vector3i(3, 23, 1), Vector3i(-4, 22, 1), Vector3i(0, 24, 2), Vector3i(2, 22, -3), Vector3i(-2, 22, -3)]:
		_put(q.x, q.y, q.z, hair[2] if q.y > 23 else hair[1])
	_part = "hand"
	_weapon(cls, robe, Color("b07cff"))


## Ignara : jeune draconique mage. Cheveux cuivre en flammes, cornes recourbées vers l'arrière, écailles cuivrées
## aux tempes, yeux d'ambre, robe cramoisie brodée d'or, queue, braises au creux de la main.
func _ignara(cls: String) -> void:
	pivots = HERO_PIVOTS.duplicate()
	var sk := [Color("a8644a"), Color("d8906a"), Color("f0b48a")]
	var robe := [Color("4a0e12"), Color("7a1a1a"), Color("b02a22"), Color("d8502a")]
	var hair := [Color("6a1a0e"), Color("a83a1a"), Color("e0602a"), Color("ffa050")]
	var horn := Color("6a5248")
	var gold := Color("f2c46b")
	_comp_body(robe, sk, Color("ffb030"), false, 0.0, false, gold)
	# Broderies d'or : ourlet et devant de la robe.
	_part = "body"
	for y in range(3, 14, 2):
		_put(0, y, _front(0, y), gold)
	for x in range(-6, 7):
		for z in range(-4, 5):
			if vox.has(Vector3i(x, 3, z)) and (x + z) % 2 == 0:
				_put(x, 3, z, gold)
	# Queue.
	_part = "tail"
	_tail([Color("7a3a1a"), Color("c8642a"), Color("f0a050")])
	# Cheveux de flammes : longs, qui s'éclaircissent vers les pointes.
	_part = "head"
	_hair("longs", [hair[0], hair[1], hair[2]])
	for q in [Vector3i(-1, 24, 1), Vector3i(1, 24, 0), Vector3i(0, 25, 1), Vector3i(2, 23, 2), Vector3i(-3, 23, 2)]:
		_put(q.x, q.y, q.z, hair[3], q.y >= 25)
	# Cornes recourbées vers l'arrière, écailles aux tempes.
	for side: int in [-1, 1]:
		for q in [Vector3i(2, 23, 0), Vector3i(3, 24, 1), Vector3i(3, 24, 2), Vector3i(3, 23, 3), Vector3i(3, 22, 4)]:
			_put(side * q.x, q.y, q.z, horn if q.z < 3 else Color("a88a70"))
		_put(side * 3, 19, _front(side * 3, 19), Color("c8642a"))
		_put(side * 3, 18, _front(side * 3, 18), Color("f0a050"))
	# Braises au creux de la main gauche.
	_part = "arms"
	_put(-5, 6, -1, Color("ffb050"), true)
	_put(-5, 5, -1, Color("ffe0a0"), true)
	_part = "hand"
	_weapon(cls, robe, Color("ff7a2a"))


## Ssareth : scribe reptilien clerc. Tête de lézard au museau allongé, écailles vert-de-gris, collerette turquoise,
## yeux d'or fendus, robe d'écume, collier de perles de corail, queue.
func _ssareth(cls: String) -> void:
	pivots = HERO_PIVOTS.duplicate()
	var sc := [Color("2a4a3a"), Color("4a7a5a"), Color("7aa880"), Color("a8d0a8")]
	var robe := [Color("4a7a8a"), Color("8ab8c0"), Color("d0e8ec"), Color("f4fbfc")]
	var frill := [Color("2a6a6a"), Color("3fa8a0"), Color("8fe0c8")]
	_comp_body(robe, [sc[0], sc[1], sc[2]], Color("fff06a"), false, 0.0, true, Color("3fa8a0"))
	# Écailles : un semis plus clair sur la tête.
	_part = "head"
	_keep = true
	for p in vox.keys():
		var q: Vector3i = p
		if str(vox[q][2]) == "head" and (q.x * 3 + q.y * 2 + q.z) % 5 == 0 and not bool(vox[q][1]):
			_put(q.x, q.y, q.z, sc[2])
	_keep = false
	# Museau allongé vers l'avant, narines.
	for y in range(16, 20):
		for x in range(-2, 3):
			var zf := _front(x, y)
			var reach := 2 if y < 19 else 1
			for k in range(1, reach + 1):
				if absi(x) + (1 if y == 19 else 0) <= 2:
					_put(x, y, zf - k, sc[1] if y > 16 else sc[0])
	_put(-1, 18, _front(-1, 18), Color("1a2a20"))
	_put(1, 18, _front(1, 18), Color("1a2a20"))
	# Pupilles fendues.
	for side: int in [-1, 1]:
		_put(side * 2, 19, _front(side * 2, 19), Color("2a1a08"))
	# Collerette derrière la tête.
	for y in range(16, 25):
		for x in range(-5, 6):
			var d := Vector2(float(x) / 5.2, (float(y) - 19.5) / 5.0).length()
			if d <= 1.0 and d > 0.5:
				_put(x, y, 3, frill[1] if d < 0.8 else frill[2])
				if d < 0.7:
					_put(x, y, 2, frill[0])
	# Collier de perles de corail.
	_part = "body"
	for x in range(-3, 4):
		_put(x, 14 if absi(x) > 1 else 13, _front(x, 14 if absi(x) > 1 else 13) - 1, Color("e86a8a") if x % 2 == 0 else Color("ffb0c0"))
	# Queue.
	_part = "tail"
	_tail([sc[0], sc[1], sc[2]])
	_part = "hand"
	_weapon(cls, robe, Color("f2c46b"))


## Surface du modèle : les voxels visibles et leur normale (vers les voisins vides).
func _build_surface() -> void:
	_surface.clear()
	var dirs := [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]
	for p in vox.keys():
		var q: Vector3i = p
		var n := Vector3.ZERO
		var exposed := false
		for d in dirs:
			var dd: Vector3i = d
			if not vox.has(q + dd):
				n += Vector3(dd)
				exposed = true
		if not exposed:
			continue
		var v: Array = vox[q]
		# Pièce fine (bâton, corde, lame) : ses faces opposées s'annulent ; elle garde sa couleur de base.
		_surface.append([q, n.normalized() if n != Vector3.ZERO else Vector3.ZERO, v[0], v[1], _side_part(str(v[2]), q.x)])


## Jambes, bras et main armée : gauche ou droite selon le côté du voxel.
func _side_part(part: String, x: int) -> String:
	match part:
		"legs":
			return "legL" if x < 0 else "legR"
		"arms":
			return "armL" if x < 0 else "armR"
		"hand":
			return "wpnL" if x < 0 else "wpnR"
	return part


# ---------------------------------------------------------------- squelette et animations

## Articulations du héros (et de Sylwen) : hanches, cou, épaules, mains, haut de la cape, base de la queue.
const HERO_PIVOTS := {
	"body": Vector3(0, 6, 0), "head": Vector3(0, 15.5, 0), "armR": Vector3(5, 13.5, -0.5), "armL": Vector3(-5, 13.5, -0.5),
	"legR": Vector3(1.5, 5.5, -0.5), "legL": Vector3(-1.5, 5.5, -0.5), "cape": Vector3(0, 14.5, 3.5), "tail": Vector3(0, 6, 3),
	"back": Vector3(0, 12, 3), "wpnR": Vector3(5.5, 7, -1), "wpnL": Vector3(-5.5, 7, -1), "root": Vector3.ZERO,
}
## Brann, plus trapu : épaules et mains plus basses et plus écartées.
const BRANN_PIVOTS := {
	"body": Vector3(0, 4, 0), "head": Vector3(0, 12, 0), "armR": Vector3(6, 11, -0.5), "armL": Vector3(-6, 11, -0.5),
	"legR": Vector3(1.5, 3.5, -0.5), "legL": Vector3(-1.5, 3.5, -0.5), "cape": Vector3(0, 11.5, 4), "tail": Vector3(0, 4, 3),
	"back": Vector3(0, 9, 4), "wpnR": Vector3(6.5, 4, -1), "wpnL": Vector3(-6.5, 4, -1), "root": Vector3.ZERO,
}
## Parties portées par le buste (elles suivent son inclinaison).
const ON_BODY := ["head", "armR", "armL", "cape", "back", "tail"]

## Animations : nombre d'images, durée d'une image (s), en boucle ou non.
const ANIMS := {
	"idle": {"frames": 4, "dt": 0.28, "loop": true, "name": "Repos"},
	"walk": {"frames": 8, "dt": 0.1, "loop": true, "name": "Marche"},
	"cast": {"frames": 7, "dt": 0.1, "loop": false, "name": "Sort"},
	"hit": {"frames": 5, "dt": 0.09, "loop": false, "name": "Coup reçu"},
	"victory": {"frames": 7, "dt": 0.12, "loop": false, "name": "Victoire"},
	"defeat": {"frames": 7, "dt": 0.13, "loop": false, "name": "Défaite"},
}


## Pose d'une image d'animation : {partie: [rotation (degrés, autour de x, y, z), décalage]}, plus « _flash »
## (blanchit le héros, coup reçu) et « _glow » (l'arme s'illumine, sort lancé). Rotation positive autour de x :
## un bras ou une jambe part vers l'avant ; le buste ou la tête basculent vers l'arrière.
static func pose(anim: String, f: int) -> Dictionary:
	var V := Vector3.ZERO
	match anim:
		"idle":
			# Respiration : épaules et tête descendent d'un pixel, la cape ondule.
			var down := f == 2
			var mid := f == 1 or f == 3
			return {"head": [V, Vector3(0, -1 if down else 0, 0)], "armR": [Vector3(0, 0, 3 if mid else 0), Vector3(0, -1 if down else 0, 0)],
				"armL": [Vector3(0, 0, -3 if mid else 0), Vector3(0, -1 if down else 0, 0)], "cape": [Vector3(-3.0 * float(f % 2 + (2 if down else 0)), 0, 0), V]}
		"walk":
			var ph := float(f) / 8.0 * TAU
			var sw := sin(ph)
			return {"legR": [Vector3(30.0 * sw, 0, 0), V], "legL": [Vector3(-30.0 * sw, 0, 0), V],
				"armR": [Vector3(-24.0 * sw, 0, 4), V], "armL": [Vector3(24.0 * sw, 0, -4), V],
				"root": [V, Vector3(0, 1 if absf(sw) < 0.5 else 0, 0)], "body": [Vector3(-5, 0, 0), V],
				"cape": [Vector3(-10.0 - 8.0 * absf(sw), 0, 0), V], "head": [Vector3(3, 0, 0), V]}
		"cast":
			# Élan vers l'arrière, l'arme se lève et se tend vers l'avant, éclat, puis retour.
			var arm: Array = [-30.0, 35.0, 95.0, 100.0, 100.0, 55.0, 15.0]
			var wrist: Array = [10.0, -50.0, -125.0, -130.0, -128.0, -70.0, -18.0]
			var lean: Array = [6.0, -2.0, -9.0, -10.0, -8.0, -4.0, 0.0]
			var g: Array = [0.0, 0.0, 1.0, 0.7, 0.4, 0.0, 0.0]
			return {"armR": [Vector3(float(arm[f]), 0, 4), V], "wpnR": [Vector3(float(wrist[f]), 0, 0), V],
				"armL": [Vector3(float(arm[f]) * 0.35, 0, -10), V], "wpnL": [Vector3(-float(arm[f]) * 0.3, 0, 0), V],
				"body": [Vector3(float(lean[f]), 0, 0), V], "head": [Vector3(float(lean[f]) * 0.6, 0, 0), V],
				"cape": [Vector3(-float(f % 3) * 4.0 - 4.0, 0, 0), V], "_glow": float(g[f])}
		"hit":
			var k: float = [1.0, 0.8, 0.5, 0.2, 0.0][f]
			return {"body": [Vector3(14.0 * k, 0, 4.0 * k), V], "head": [Vector3(14.0 * k, 0, -6.0 * k), V],
				"armR": [Vector3(-25.0 * k, 0, 30.0 * k), V], "armL": [Vector3(-25.0 * k, 0, -30.0 * k), V],
				"root": [V, Vector3(0, 0, round(1.5 * k))], "cape": [Vector3(-16.0 * k, 0, 0), V], "_flash": 0.75 if f == 0 else (0.3 if f == 1 else 0.0)}
		"victory":
			# Appel, saut, arme brandie au-dessus de la tête (elle reste droite), regard vers le ciel.
			var arm2: Array = [-20.0, 60.0, 150.0, 172.0, 175.0, 175.0, 175.0]
			var up: Array = [-1, 1, 3, 2, 0, 0, 0]
			var lean2: Array = [-8.0, 0.0, 4.0, 5.0, 4.0, 3.0, 3.0]
			var a2 := float(arm2[f])
			return {"armR": [Vector3(a2, 0, -6.0 if a2 > 120.0 else 3.0), V], "wpnR": [Vector3(-a2 * 0.95, 0, 0), V],
				"armL": [Vector3(0, 0, -28.0 if f >= 2 else -6.0), V], "root": [V, Vector3(0, int(up[f]), 0)],
				"body": [Vector3(float(lean2[f]), 0, 0), V], "head": [Vector3(float(lean2[f]) * 2.5, 0, 0), V],
				"legR": [Vector3(-12.0 if int(up[f]) > 0 else 0.0, 0, 0), V], "legL": [Vector3(18.0 if int(up[f]) > 0 else 0.0, 0, 0), V],
				"cape": [Vector3(-22.0 if int(up[f]) > 0 else -6.0, 0, 0), V], "_glow": 0.6 if f >= 3 else 0.0}
		"defeat":
			# Il chancelle, met un genou à terre, s'appuie sur son arme, tête basse.
			var t := float(f) / 6.0
			var kneel := clampf(t * 1.6, 0.0, 1.0)
			return {"body": [Vector3(-26.0 * kneel, 0, 6.0 * sin(t * PI)), V], "head": [Vector3(-28.0 * kneel, 0, 0), V],
				"legL": [Vector3(85.0 * kneel, 0, 0), V], "legR": [Vector3(-35.0 * kneel, 0, 0), V],
				"root": [V, Vector3(0, -round(3.0 * kneel), 0)],
				"armR": [Vector3(45.0 * kneel, 0, 6), V], "wpnR": [Vector3(-38.0 * kneel, 0, 0), V],
				"armL": [Vector3(20.0 * kneel, 0, -4), V], "cape": [Vector3(4.0 * kneel, 0, 0), V]}
	return {}


func _xf(part: String, pose_d: Dictionary) -> Transform3D:
	var d: Array = pose_d.get(part, [])
	if d.is_empty():
		return Transform3D.IDENTITY
	var rot: Vector3 = d[0]
	var off: Vector3 = d[1] if d.size() > 1 else Vector3.ZERO
	var piv: Vector3 = pivots.get(part, Vector3.ZERO)
	var b := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	return Transform3D(b, piv + off - b * piv)


## Transformation de chaque partie pour une pose (squelette : racine → buste → tête, bras, cape ; bras → arme).
func _skeleton(pose_d: Dictionary) -> Dictionary:
	var root := _xf("root", pose_d)
	var body := root * _xf("body", pose_d)
	var out := {"root": root, "body": body, "legR": root * _xf("legR", pose_d), "legL": root * _xf("legL", pose_d)}
	for part in ON_BODY:
		out[part] = body * _xf(str(part), pose_d)
	out["goggles"] = (out["head"] as Transform3D) * _xf("goggles", pose_d)
	out["wpnR"] = (out["armR"] as Transform3D) * _xf("wpnR", pose_d)
	out["wpnL"] = (out["armL"] as Transform3D) * _xf("wpnL", pose_d)
	return out


static var _budget_frame := -1 ## dernière image d'écran où une image du héros a été rendue


## Image rendue si elle est en cache, ou si aucune autre ne l'a été à cette image d'écran ; sinon null (on garde
## l'image précédente et on réessaie à l'image suivante). Une seule image rendue par image d'écran, pour tous les
## personnages en volume affichés, garde l'écran fluide.
func frame_budgeted(yaw: float, anim: String, f: int, light: String = "jour") -> Image:
	var img := cached(yaw, anim, f, light)
	if img != null:
		return img
	var now := Engine.get_process_frames()
	if now == _budget_frame:
		return null
	_budget_frame = now
	return frame_at(yaw, anim, f, light)


## Image d'une pose libre (dictionnaire de pose(), clé donnée pour le cache) sous l'angle yaw.
func frame_pose(yaw: float, key: String, pose_d: Dictionary, light: String = "jour") -> Image:
	var step := posmod(int(round(yaw / TAU * float(STEPS))), STEPS)
	var k := "P|%s|%d|%s" % [key, step, light]
	if not _cache.has(k):
		if _cache.size() > 600:
			_cache.clear()
		_cache[k] = render(float(step) / float(STEPS) * TAU, pose_d, light)
	return _cache[k]


func has_pose(yaw: float, key: String, light: String = "jour") -> bool:
	var step := posmod(int(round(yaw / TAU * float(STEPS))), STEPS)
	return _cache.has("P|%s|%d|%s" % [key, step, light])


## Où tombe dans l'image (en pixels, depuis son coin haut gauche) un point du modèle porté par une partie, pour une
## pose et un angle : la main qui tient un objet, le haut de l'enclume…
func project(yaw: float, pose_d: Dictionary, part: String, p: Vector3) -> Vector2:
	var step := posmod(int(round(yaw / TAU * float(STEPS))), STEPS)
	var y2 := float(step) / float(STEPS) * TAU
	var right := Vector3(cos(y2), 0.0, -sin(y2))
	var xf: Transform3D = _skeleton(pose_d).get(part, Transform3D.IDENTITY)
	var q := xf * p
	return Vector2(q.dot(right) + float(W) * 0.5, float(H - 2) - q.y + 0.5)


## Un objet en volume d'après son icône en pixel art : chaque pixel devient une colonne de cubes (épaisseur thick).
## L'icône est vue de face sous l'angle 0, posée sur y = 0.
static func from_icon(img: Image, thick: int = 2) -> HeroModel:
	var m := HeroModel.new()
	var w := img.get_width()
	var h := img.get_height()
	for iy in range(h):
		for ix in range(w):
			var c := img.get_pixel(ix, iy)
			if c.a < 0.5:
				continue
			for z in range(thick):
				m.vox[Vector3i(ix - w / 2, h - 1 - iy, -z)] = [Color(c.r, c.g, c.b), false, "body"]
	m._build_surface()
	return m


## L'enclume de Durgan : pied, taille, table, bigorne et talon, en fer noirci.
static func anvil() -> HeroModel:
	var m := HeroModel.new()
	var dk := Color("1e1c26")
	var mid := Color("3a3848")
	var lt := Color("5e5c70")
	var shine := Color("8a88a0")
	for y in range(0, 3):
		for x in range(-5, 6):
			for z in range(-3, 3):
				m._put(x, y, z, dk if y == 0 else mid)
	for y in range(3, 5):
		for x in range(-2, 3):
			for z in range(-2, 2):
				m._put(x, y, z, mid)
	for y in range(5, 8):
		for x in range(-6, 8):
			for z in range(-3, 3):
				m._put(x, y, z, shine if y == 7 and absi(x) < 5 else (lt if y == 7 else mid))
	# Bigorne (la corne) et talon.
	for k in range(0, 5):
		var half := 2 - k / 2
		for y in range(7 - half, 8):
			for z in range(-half, half):
				m._put(-7 - k, y, z, lt if y == 7 else mid)
	m._build_surface()
	return m


## Établi de bois où attendent les objets.
static func bench() -> HeroModel:
	var m := HeroModel.new()
	var wd := [Color("3a2414"), Color("5a3a22"), Color("7a5230"), Color("9a6a3a")]
	for x in [-9, 8]:
		for z in [-3, 2]:
			for y in range(0, 6):
				m._put(x, y, z, wd[1])
	for y in range(6, 8):
		for x in range(-10, 10):
			for z in range(-4, 4):
				m._put(x, y, z, wd[3] if y == 7 and (x + z) % 5 else wd[2])
	m._build_surface()
	return m


## Image déjà rendue, ou null (pour ne rendre qu'un nombre limité d'images par image d'écran).
func cached(yaw: float, anim: String, f: int, light: String = "jour") -> Image:
	var step := posmod(int(round(yaw / TAU * float(STEPS))), STEPS)
	return _cache.get("%s|%d|%d|%s" % [anim, f, step, light])


## Image d'une animation (image f) sous l'angle yaw, avec un éclairage ; gardée en cache.
func frame_at(yaw: float, anim: String, f: int, light: String = "jour") -> Image:
	var step := posmod(int(round(yaw / TAU * float(STEPS))), STEPS)
	var key := "%s|%d|%d|%s" % [anim, f, step, light]
	if not _cache.has(key):
		if _cache.size() > 600:
			_cache.clear()
		_cache[key] = render(float(step) / float(STEPS) * TAU, pose(anim, f), light)
	return _cache[key]


# ---------------------------------------------------------------- éclairage

## Éclairages de scène. key : lumière principale (direction, couleur, force) ; dans le repère de la vue
## (« view » : elle suit la caméra) ou du monde (« world » : elle reste du côté de la source quand le héros
## tourne). shade : teinte des ombres ; tint : teinte d'ensemble ; rim : liseré de contre-jour.
const LIGHTS := {
	"jour": {"name": "Jour", "space": "view", "dir": Vector3(-0.55, 0.6, 0.6), "key": Color.WHITE, "lit": 0.16,
		"shade": Color.BLACK, "s1": 0.22, "s2": 0.42},
	"aube": {"name": "Aube", "space": "view", "dir": Vector3(-0.7, 0.35, 0.6), "key": Color("ffd0a0"), "lit": 0.3,
		"shade": Color("3a2050"), "s1": 0.26, "s2": 0.48, "tint": Color("ffb8a0"), "tint_k": 0.1, "rim": Color("ffe0b0"), "rim_dir": Vector3(0.8, 0.2, -0.4)},
	"crepuscule": {"name": "Crépuscule", "space": "view", "dir": Vector3(0.75, 0.3, 0.55), "key": Color("ff9a5a"), "lit": 0.32,
		"shade": Color("2a1440"), "s1": 0.3, "s2": 0.52, "tint": Color("c07090"), "tint_k": 0.12},
	"nuit": {"name": "Nuit", "space": "view", "dir": Vector3(0.3, 0.8, -0.2), "key": Color("b8d0ff"), "lit": 0.22,
		"shade": Color("0a0c24"), "s1": 0.36, "s2": 0.56, "tint": Color("3a4a8a"), "tint_k": 0.32, "rim": Color("a0c0ff"), "rim_dir": Vector3(-0.7, 0.4, -0.5)},
	"feu": {"name": "Feu de camp", "space": "world", "dir": Vector3(-0.6, 0.05, -0.8), "key": Color("ffa040"), "lit": 0.4,
		"shade": Color("140a24"), "s1": 0.4, "s2": 0.62, "tint": Color("a05030"), "tint_k": 0.18, "rim": Color("ffc070"), "rim_dir": Vector3(-0.9, 0.1, -0.3)},
	"lave": {"name": "Lave", "space": "view", "dir": Vector3(0.1, -0.85, 0.5), "key": Color("ff5a20"), "lit": 0.45,
		"shade": Color("1a0404"), "s1": 0.36, "s2": 0.6, "tint": Color("801a10"), "tint_k": 0.16},
	"abysses": {"name": "Abysses", "space": "view", "dir": Vector3(0.2, 0.9, 0.3), "key": Color("70f0e0"), "lit": 0.3,
		"shade": Color("021420"), "s1": 0.34, "s2": 0.56, "tint": Color("1a6a7a"), "tint_k": 0.3, "rim": Color("8ff0ff"), "rim_dir": Vector3(0.6, 0.3, -0.7)},
	"forge": {"name": "Forge", "hidden": true, "space": "view", "dir": Vector3(0.75, 0.25, 0.55), "key": Color("ffb060"), "lit": 0.36,
		"shade": Color("1a0c18"), "s1": 0.34, "s2": 0.56, "tint": Color("c08050"), "tint_k": 0.14, "rim": Color("ff7a30"), "rim_dir": Vector3(-0.85, 0.3, -0.3)},
	"camp": {"name": "Bivouac", "hidden": true, "space": "world", "dir": Vector3(0.35, 0.12, -1.0), "key": Color("ffa050"), "lit": 0.42,
		"shade": Color("120a22"), "s1": 0.38, "s2": 0.6, "tint": Color("b06038"), "tint_k": 0.16, "rim": Color("9ab0ff"), "rim_dir": Vector3(-0.85, 0.45, -0.2)},
	"lampe": {"name": "Lanterne", "space": "view", "dir": Vector3(0.6, 0.55, 0.6), "key": Color("ffd890"), "lit": 0.3,
		"shade": Color("1e1020"), "s1": 0.28, "s2": 0.5, "tint": Color("c09060"), "tint_k": 0.1},
}


# ---------------------------------------------------------------- rendu

## Rendu en pixel art sous l'angle yaw (radians, 0 = de dos) : projection orthographique, tampon de profondeur,
## ombrage en paliers sous l'éclairage choisi, contours intérieurs et contour sombre. pose_d : voir pose().
func render(yaw: float, pose_d: Dictionary = {}, light_id: String = "jour") -> Image:
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var depth := PackedFloat32Array()
	depth.resize(W * H)
	depth.fill(1e9)
	var fwd := Vector3(-sin(yaw), 0.0, -cos(yaw)) ## de la caméra vers la scène
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var lt: Dictionary = LIGHTS.get(light_id, LIGHTS["jour"])
	var ld: Vector3 = (lt["dir"] as Vector3).normalized()
	if str(lt.get("space", "view")) == "world":
		ld = Vector3(ld.dot(right), ld.y, -ld.dot(fwd)) ## lumière du monde, ramenée dans le repère de la vue
	var light := ld ## repère de la vue : x droite, y haut, z vers le spectateur
	var key: Color = lt["key"]
	var lit_k := float(lt["lit"])
	var shade: Color = lt["shade"]
	var s1 := float(lt["s1"])
	var s2 := float(lt["s2"])
	var tint: Color = lt.get("tint", Color.WHITE)
	var tint_k := float(lt.get("tint_k", 0.0))
	var rim_k := 0.0
	var rim_dir := Vector3.ZERO
	var rim: Color = lt.get("rim", Color.WHITE)
	if lt.has("rim"):
		rim_k = 0.45
		rim_dir = (lt["rim_dir"] as Vector3).normalized()
	var flash := float(pose_d.get("_flash", 0.0))
	var glow_k := float(pose_d.get("_glow", 0.0))
	var skel := _skeleton(pose_d) if not pose_d.is_empty() else {}
	var cx := float(W) * 0.5
	var subs := [-0.34, 0.0, 0.34]
	var subs3 := [Vector3(-0.3, -0.3, -0.3), Vector3(0.3, -0.3, -0.3), Vector3(-0.3, 0.3, -0.3), Vector3(0.3, 0.3, -0.3),
		Vector3(-0.3, -0.3, 0.3), Vector3(0.3, -0.3, 0.3), Vector3(-0.3, 0.3, 0.3), Vector3(0.3, 0.3, 0.3)]
	for s in _surface:
		var q: Vector3i = s[0]
		var n: Vector3 = s[1]
		var part := str(s[4])
		var xf: Transform3D = skel.get(part, Transform3D.IDENTITY)
		var turned := not xf.basis.is_equal_approx(Basis.IDENTITY)
		if turned:
			n = xf.basis * n
		var nv := Vector3(n.dot(right), n.y, -n.dot(fwd))
		if nv.z < -0.75:
			continue ## face tournée vers l'arrière : cachée
		var c: Color = s[2]
		var glow := bool(s[3])
		if not glow and n != Vector3.ZERO:
			var lum := nv.dot(light)
			if tint_k > 0.0:
				c = c.lerp(c * tint, tint_k)
			if lum > 0.5:
				c = c.lerp(key, lit_k)
			elif lum < -0.35:
				c = c.lerp(shade, s2)
			elif lum < 0.05:
				c = c.lerp(shade, s1)
			if rim_k > 0.0 and nv.dot(rim_dir) > 0.62:
				c = c.lerp(rim, rim_k)
		elif glow and glow_k > 0.0:
			c = c.lerp(Color.WHITE, 0.45 * glow_k)
		if glow_k > 0.0 and part.begins_with("wpn"):
			c = c.lerp(Color(1.0, 0.96, 0.8), 0.25 * glow_k)
		if flash > 0.0:
			c = c.lerp(Color.WHITE, flash)
		if not turned:
			var o3 := xf.origin
			var row := H - 2 - (q.y + int(round(o3.y)))
			if row < 0 or row >= H:
				continue
			for ox in subs:
				for oz in subs:
					var p := Vector3(float(q.x) + float(ox) + o3.x, 0.0, float(q.z) + float(oz) + o3.z)
					var col := int(floor(p.dot(right) + cx))
					if col < 0 or col >= W:
						continue
					var dep := p.dot(fwd)
					var i := row * W + col
					if dep < depth[i]:
						depth[i] = dep
						img.set_pixel(col, row, c)
		else:
			var qv := Vector3(q)
			for o in subs3:
				var p := xf * (qv + (o as Vector3))
				var row := H - 2 - int(floor(p.y + 0.5))
				if row < 0 or row >= H:
					continue
				var col := int(floor(p.dot(right) + cx))
				if col < 0 or col >= W:
					continue
				var dep := Vector3(p.x, 0.0, p.z).dot(fwd)
				var i := row * W + col
				if dep < depth[i]:
					depth[i] = dep
					img.set_pixel(col, row, c)
	# Contours intérieurs : là où une partie passe devant une autre (bâton devant la robe, bras devant le
	# corps, capuche autour du visage), le pixel de derrière s'assombrit, comme un trait de pixel art.
	var lined := img.duplicate() as Image
	for y in range(H):
		for x in range(W):
			var i := y * W + x
			if depth[i] > 1e8:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var dd: Vector2i = d
				var xx := x + dd.x
				var yy := y + dd.y
				if xx < 0 or yy < 0 or xx >= W or yy >= H:
					continue
				var j := yy * W + xx
				if depth[j] < 1e8 and depth[j] < depth[i] - 1.6:
					lined.set_pixel(x, y, img.get_pixel(x, y).darkened(0.55))
					break
	img = lined
	# Contour sombre autour de la silhouette, comme les sprites du jeu.
	var out := img.duplicate() as Image
	for y in range(H):
		for x in range(W):
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var dd: Vector2i = d
				var xx := x + dd.x
				var yy := y + dd.y
				if xx >= 0 and yy >= 0 and xx < W and yy < H and img.get_pixel(xx, yy).a > 0.0:
					out.set_pixel(x, y, OUTLINE)
					break
	return out
