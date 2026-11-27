class_name ForgeScene
extends Control
## Les gestes de Durgan à la Forge, en volume (docs/design/46-forge-animee.md), par-dessus l'écran de la Forge.
##
## Fusion : Durgan rabat ses lunettes de forge, prend sur l'établi le premier objet et le pose sur l'enclume, puis
## les deux autres ; il lève son marteau et frappe trois fois (étincelles, secousses), les objets se mettent à
## tourner, se fondent dans un éclair, et l'objet né de la fusion apparaît au-dessus de l'enclume.
## Gravure : Durgan, de face, prend l'objet et le pose sur l'enclume, prend la rune choisie (la vraie, sa famille, sa
## couleur, son niveau), la montre, la pose sur l'objet et la grave à petits coups de marteau ; le glyphe s'allume.
##
## Tout est rendu par HeroModel (Durgan, l'enclume, l'établi, et les objets et runes mis en volume d'après leurs
## icônes). Toucher l'écran passe la scène ; à la fin, toucher la ferme.

signal finished

var SC := 15.0 ## pixels d'écran par cube (Durgan, enclume, établi), selon la largeur de l'écran
var IS := 5.0 ## pixels d'écran par pixel d'objet
var RS := 8.0 ## objet révélé, en grand
const LIGHT := "forge"
const HAND_L := Vector3(-6.0, 4.0, -0.6) ## main gauche de Durgan (repère du modèle)
const HAMMER := Vector3(7.0, 12.0, -1.0) ## tête du marteau
const PROP_C := 12.0 ## centre d'une icône (24 px) au-dessus de sa base

var mode := "fusion" ## « fusion » ou « gravure »
var items: Array = [] ## fusion : les 3 objets ; gravure : l'objet
var result: Dictionary = {} ## l'objet obtenu
var rune: Dictionary = {} ## gravure : la rune
var rune_text := "" ## gravure : ce que fait la rune

var _durgan: HeroModel
var _anvil: HeroModel
var _bench: HeroModel
var _yaw := PI
var _props: Dictionary = {} ## id -> {model, pos, scale, yaw, spin, vis, glow, col, held}
var _steps: Array = []
var _si := -1 ## étape en cours
var _st := 0.0 ## temps dans l'étape
var _pose_a: Dictionary = {}
var _pose_b: Dictionary = {}
var _pose_key := ""
var _sub := 0
var _laid := false
var _floor := 0.0
var _d_foot := Vector2.ZERO
var _a_foot := Vector2.ZERO
var _b_foot := Vector2.ZERO
var _anvil_top := Vector2.ZERO
var _reveal_at := Vector2.ZERO
var _tex: Dictionary = {} ## clé d'image -> ImageTexture
var _bg: Texture2D
var _radial: Texture2D
var _sparks: Array = [] ## {p, v, life, max, col, s}
var _rings: Array = [] ## {c, r0, r1, t, max, col}
var _flash := 0.0
var _flash_col := Color.WHITE
var _shake := 0.0
var _t := 0.0
var _rays := 0.0 ## rayons de lumière derrière l'objet révélé
var _rays_col := Color.WHITE
var _emblem := 0.0 ## gravure : glyphe allumé sur l'objet
var _done := false
var _labels: VBoxContainer
var _hint: Label
var _warm: Array = [] ## poses à préparer
var _budget := 0
var speed := 1.0 ## vitesse de la scène (aperçu au ralenti : « &fxspeed=0.25 »)


static func fusion(objs: Array, out: Dictionary) -> ForgeScene:
	var s := ForgeScene.new()
	s.mode = "fusion"
	s.items = objs
	s.result = out
	return s


static func engraving(it: Dictionary, r: Dictionary, out: Dictionary, effect: String) -> ForgeScene:
	var s := ForgeScene.new()
	s.mode = "gravure"
	s.items = [it]
	s.rune = r
	s.result = out
	s.rune_text = effect
	return s


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 20
	_durgan = HeroModel.new()
	_durgan.build_companion("durgan", "")
	_anvil = HeroModel.anvil()
	_bench = HeroModel.bench()
	_bg = RoomArt.scene("forge", Vector2i(180, 150))
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	_radial = gt
	_yaw = PI - 0.42 if mode == "fusion" else PI
	if mode == "fusion":
		for i in range(items.size()):
			_add_prop("i%d" % i, _icon_of(items[i]), IS, Profile.item_color(items[i]))
		_add_prop("out", _icon_of(result), RS, Profile.item_color(result))
	else:
		_add_prop("i0", _icon_of(items[0]), IS, Profile.item_color(items[0]))
		_add_prop("rune", HeroModel.from_icon((ItemArt.rune(str(rune.get("rune", "")), int(rune.get("level", 1)), ItemArt.S) as ImageTexture).get_image()), IS, Profile.rune_color(rune))
	_build_steps()
	_labels = VBoxContainer.new()
	_labels.alignment = BoxContainer.ALIGNMENT_CENTER
	_labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_labels.add_theme_constant_override("separation", 4)
	add_child(_labels)
	_hint = UiTheme.label("Touche l'écran pour passer", 15, Color(UiTheme.MUTED, 0.85))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)


static func _icon_of(it: Dictionary) -> HeroModel:
	var base := str(it.get("base", ""))
	var tex := ItemArt.item(base, ItemArt.S)
	if tex == null:
		tex = ItemArt.rune("kaor", 1, ItemArt.S)
	return HeroModel.from_icon((tex as Texture2D).get_image())


func _add_prop(id: String, m: HeroModel, sc: float, col: Color) -> void:
	_props[id] = {"model": m, "pos": Vector2.ZERO, "scale": sc, "yaw": 0.0, "spin": 0.0, "vis": false, "glow": 0.0, "col": col,
		"held": false, "from": Vector2.ZERO, "to": Vector2.ZERO, "moving": false, "tex": null}


# ---------------------------------------------------------------- poses de Durgan

## Poses de Durgan : {partie: [rotation (degrés), décalage]} (voir HeroModel.pose()). goggles : lunettes rabattues
## (0 : relevées sur le front, 1 : sur les yeux ; entre les deux, il est en train de les abaisser).
static func dpose(name: String, goggles: float) -> Dictionary:
	var V := Vector3.ZERO
	var rest_r := [Vector3(8, 0, 6), V]
	var d := {}
	match name:
		"rest":
			d = {"armR": rest_r, "armL": [Vector3(4, 0, -4), V]}
		"g_up":
			# La main saisit les lunettes sur le haut du front.
			d = {"armL": [Vector3(168, 0, 30), V], "head": [Vector3(6, 0, 0), V], "armR": rest_r}
		"g_pull":
			# Il les fait basculer vers ses yeux.
			d = {"armL": [Vector3(152, 0, 30), V], "head": [Vector3(0, 0, 0), V], "armR": rest_r}
		"g_set":
			# Elles claquent en place ; il baisse un peu la tête pour les ajuster.
			d = {"armL": [Vector3(138, 0, 30), V], "head": [Vector3(-8, 0, 0), V], "armR": rest_r}
		"reach0", "reach1", "reach2":
			var k := int(name.right(1))
			d = {"armL": [Vector3(66, 0, -30.0 - 9.0 * float(k)), V], "body": [Vector3(-10, 0, 0), V], "head": [Vector3(-12, 0, 0), V], "armR": rest_r}
		"lift":
			d = {"armL": [Vector3(112, 0, -12), V], "head": [Vector3(4, 0, 0), V], "armR": rest_r}
		"place":
			d = {"armL": [Vector3(64, 0, 22), V], "body": [Vector3(-10, 0, 0), V], "head": [Vector3(-14, 0, 0), V], "armR": rest_r}
		"raise":
			d = {"armR": [Vector3(160, 0, 8), V], "wpnR": [Vector3(-150, 0, 0), V], "armL": [Vector3(28, 0, -14), V],
				"body": [Vector3(5, 0, 0), V], "head": [Vector3(6, 0, 0), V]}
		"strike":
			d = {"armR": [Vector3(72, 0, -8), V], "wpnR": [Vector3(52, 0, 0), V], "armL": [Vector3(28, 0, -14), V],
				"body": [Vector3(-12, 0, 0), V], "head": [Vector3(-14, 0, 0), V]}
		"recoil":
			d = {"armR": [Vector3(96, 0, 0), V], "wpnR": [Vector3(12, 0, 0), V], "armL": [Vector3(28, 0, -14), V], "body": [Vector3(-6, 0, 0), V]}
		"show":
			d = {"armL": [Vector3(134, 0, -6), V], "head": [Vector3(10, 0, 0), V], "armR": rest_r}
		"eng_a":
			d = {"armL": [Vector3(60, 0, 20), V], "armR": [Vector3(60, 0, -16), V], "wpnR": [Vector3(30, 0, 0), V],
				"body": [Vector3(-9, 0, 0), V], "head": [Vector3(-18, 0, 0), V]}
		"eng_b":
			d = {"armL": [Vector3(60, 0, 20), V], "armR": [Vector3(78, 0, -16), V], "wpnR": [Vector3(6, 0, 0), V],
				"body": [Vector3(-9, 0, 0), V], "head": [Vector3(-18, 0, 0), V]}
		"triumph":
			d = {"armR": [Vector3(168, 0, 6), V], "wpnR": [Vector3(-165, 0, 0), V], "armL": [Vector3(30, 0, -32), V],
				"head": [Vector3(10, 0, 0), V], "root": [V, Vector3(0, 1, 0)]}
	d["goggles"] = [Vector3(55.0 * (1.0 - clampf(goggles, 0.0, 1.0)), 0, 0), V]
	return d


static func lerp_pose(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out := {}
	var keys: Array = a.keys()
	for k in b.keys():
		if not keys.has(k):
			keys.append(k)
	for k in keys:
		var pa: Array = a.get(k, [Vector3.ZERO, Vector3.ZERO])
		var pb: Array = b.get(k, [Vector3.ZERO, Vector3.ZERO])
		var oa: Vector3 = pa[1] if pa.size() > 1 else Vector3.ZERO
		var ob: Vector3 = pb[1] if pb.size() > 1 else Vector3.ZERO
		out[k] = [(pa[0] as Vector3).lerp(pb[0], t), oa.lerp(ob, t)]
	return out


# ---------------------------------------------------------------- la séquence

func _step(d: float, pose: String, g: float, fx: Callable = Callable(), grab: String = "", drop: String = "", to: Vector2 = Vector2.ZERO) -> void:
	_steps.append({"d": d, "pose": pose, "g": g, "fx": fx, "grab": grab, "drop": drop, "to": to})


func _build_steps() -> void:
	_steps.clear()
	if mode == "fusion":
		# Il enfile ses lunettes : la main les prend sur le front, les fait basculer, elles claquent sur ses yeux.
		_step(0.6, "rest", 0.0)
		_step(0.34, "g_up", 0.0)
		_step(0.3, "g_pull", 0.55)
		_step(0.14, "g_set", 1.0, func() -> void: Snd.sfx("forge_goggles", -2.0))
		_step(0.22, "g_set", 1.0)
		_step(0.26, "rest", 1.0)
		for k in range(items.size()):
			var id := "i%d" % k
			_step(0.3, "reach%d" % k, 1.0, Callable(), id)
			_step(0.24, "lift", 1.0, func() -> void: Snd.sfx("forge_pick", -4.0, 1.0 + 0.08 * float(k)))
			_step(0.3, "place", 1.0, Callable(), "", id, Vector2(-1, k))
			_step(0.12, "place", 1.0, func() -> void:
				Snd.sfx("forge_place", -3.0, 1.0 - 0.05 * float(k))
				_dust(_slot_pos(k) + Vector2(0, PROP_C * IS), 6))
		for n in range(3):
			_step(0.3, "raise", 1.0, func() -> void: Snd.sfx("forge_whoosh", -6.0, 1.0 + 0.1 * float(n)))
			_step(0.1, "strike", 1.0, func() -> void: _strike(n))
			_step(0.22, "recoil", 1.0)
		_step(1.45, "rest", 1.0, _merge)
		_step(0.5, "triumph", 1.0, _reveal)
		_step(1.2, "triumph", 1.0)
	else:
		_step(0.6, "rest", 0.0)
		_step(0.3, "reach0", 0.0, Callable(), "i0")
		_step(0.24, "lift", 0.0, func() -> void: Snd.sfx("forge_pick", -4.0))
		_step(0.3, "place", 0.0, Callable(), "", "i0", Vector2(-1, 1))
		_step(0.14, "place", 0.0, func() -> void:
			Snd.sfx("forge_place", -3.0)
			_dust(_slot_pos(1) + Vector2(0, PROP_C * IS), 6))
		_step(0.3, "reach1", 0.0, Callable(), "rune")
		_step(0.5, "show", 0.0, _rune_wake)
		_step(0.3, "place", 0.0, Callable(), "", "rune", Vector2(-2, 1))
		for n in range(4):
			_step(0.13, "eng_b", 0.0)
			_step(0.11, "eng_a", 0.0, func() -> void: _tap(n))
		_step(0.4, "eng_a", 0.0, _rune_seal)
		_step(0.6, "show", 0.0, _engraved)
		_step(1.2, "show", 0.0)


## Une image d'écran : avance la scène.
func _process(delta: float) -> void:
	delta *= speed
	if get_parent() != null and get_index() != get_parent().get_child_count() - 1:
		move_to_front()
	_t += delta
	_budget = 3
	if not _laid:
		if size.x < 10.0:
			return
		_layout()
	# Préparer les poses à l'avance (pendant le plan d'ouverture).
	while not _warm.is_empty() and _budget > 0:
		var w: Array = _warm.pop_front()
		_durgan.frame_pose(_yaw, str(w[0]), w[1], LIGHT)
		_budget -= 1
	if not _done:
		_st += delta
		while _si < _steps.size() and (_si < 0 or _st >= float(_steps[_si]["d"])):
			if _si >= 0:
				_st -= float(_steps[_si]["d"])
				_end_step(_steps[_si])
			_si += 1
			if _si >= _steps.size():
				_finish()
				break
			_begin_step(_steps[_si])
		if not _done:
			_update_step()
	_update_fx(delta)
	queue_redraw()


func _layout() -> void:
	_laid = true
	# Échelle entière : Durgan occupe environ un tiers de la largeur (écran étroit) ou de la hauteur.
	SC = clampf(floorf(minf(size.x * 0.4, size.y * 0.3) / 19.0), 6.0, 20.0)
	IS = maxf(2.0, floorf(SC / 3.0))
	RS = maxf(3.0, floorf(SC * 0.55))
	for id in _props.keys():
		_props[id]["scale"] = RS if id == "out" else IS
	_floor = size.y * 0.7
	if mode == "fusion":
		_d_foot = Vector2(size.x * 0.46, _floor - 6.0)
	else:
		_d_foot = Vector2(size.x * 0.5, _floor - SC * 3.0)
	# L'enclume sous le coup de marteau (fusion) ou devant Durgan (gravure) ; l'établi là où sa main gauche se tend.
	var strike := _screen(dpose("strike", 0.0), "wpnR", HAMMER)
	if mode == "fusion":
		_a_foot = Vector2(strike.x, _floor + SC * 2.0)
	else:
		_a_foot = Vector2(_d_foot.x + SC * 0.5, _floor + SC * 4.0)
	_anvil_top = _a_foot - Vector2(0, 8.0 * SC)
	var reach := _screen(dpose("reach0", 0.0), "armL", HAND_L)
	_b_foot = Vector2(reach.x + SC * 1.5, reach.y + PROP_C * IS + 8.0 * SC)
	# Les objets attendent sur l'établi, chacun là où la main ira le prendre.
	var keys := ["i0", "i1", "i2"] if mode == "fusion" else ["i0", "rune"]
	for k in range(keys.size()):
		if not _props.has(keys[k]):
			continue
		var hp := _screen(dpose("reach%d" % k, 0.0), "armL", HAND_L)
		var p: Dictionary = _props[keys[k]]
		p["pos"] = Vector2(hp.x, _b_foot.y - 8.0 * SC - PROP_C * IS)
		p["vis"] = true
	# L'objet révélé flotte au-dessus de la tête de Durgan, au centre.
	_reveal_at = Vector2(size.x * 0.5, _d_foot.y - 21.0 * SC - PROP_C * RS - SC * 2.0)
	_reveal_at.y = maxf(_reveal_at.y, size.y * 0.06 + PROP_C * RS)
	# Le nom de l'objet sous la scène, sur le sol sombre.
	_labels.position = Vector2(24, _floor + SC * 5.0)
	_labels.size = Vector2(size.x - 48.0, 100.0)
	_hint.position = Vector2(0, size.y - 70.0)
	_hint.size = Vector2(size.x, 30.0)
	# Les poses à préparer.
	var prev := "rest"
	var prev_g := 0.0
	for s in _steps:
		var a := dpose(prev, prev_g)
		var b := dpose(str(s["pose"]), float(s["g"]))
		for k in [1, 2]:
			_warm.append(["%s%.2f>%s%.2f|%d" % [prev, prev_g, s["pose"], float(s["g"]), k], lerp_pose(a, b, float(k) / 2.0)])
		prev = str(s["pose"])
		prev_g = float(s["g"])


## Point du modèle de Durgan (partie, repère du modèle) à l'écran, pour une pose.
func _screen(pose_d: Dictionary, part: String, p: Vector3) -> Vector2:
	var ip := _durgan.project(_yaw, pose_d, part, p)
	return _d_foot + (ip - Vector2(float(HeroModel.W) * 0.5, float(HeroModel.H - 2))) * SC


## Place d'un objet sur l'enclume (centre de son icône).
func _slot_pos(k: int) -> Vector2:
	var dx := (float(k) - 1.0) * SC * 3.0 if mode == "fusion" else 0.0
	return _anvil_top + Vector2(dx, -PROP_C * IS + 4.0)


func _begin_step(s: Dictionary) -> void:
	var prev_pose := "rest"
	var prev_g := 0.0
	if _si > 0:
		prev_pose = str(_steps[_si - 1]["pose"])
		prev_g = float(_steps[_si - 1]["g"])
	_pose_a = dpose(prev_pose, prev_g)
	_pose_b = dpose(str(s["pose"]), float(s["g"]))
	_pose_key = "%s%.2f>%s%.2f" % [prev_pose, prev_g, s["pose"], float(s["g"])]
	var fx: Callable = s["fx"]
	if fx.is_valid():
		fx.call()
	var grab := str(s["grab"])
	if grab != "" and _props.has(grab):
		var p: Dictionary = _props[grab]
		p["from"] = p["pos"]
		p["moving"] = true
	var drop := str(s["drop"])
	if drop != "" and _props.has(drop):
		var p2: Dictionary = _props[drop]
		p2["held"] = false
		p2["from"] = p2["pos"]
		var to: Vector2 = s["to"]
		p2["to"] = _slot_pos(int(to.y)) if to.x == -1.0 else _slot_pos(1) + Vector2(0, -2.0)
		p2["moving"] = true


func _end_step(s: Dictionary) -> void:
	var grab := str(s["grab"])
	if grab != "" and _props.has(grab):
		_props[grab]["held"] = true
		_props[grab]["moving"] = false
	var drop := str(s["drop"])
	if drop != "" and _props.has(drop):
		_props[drop]["pos"] = _props[drop]["to"]
		_props[drop]["moving"] = false


func _cur_pose() -> Dictionary:
	return lerp_pose(_pose_a, _pose_b, float(_sub) / 2.0)


func _update_step() -> void:
	var s: Dictionary = _steps[_si]
	var k := clampf(_st / maxf(0.001, float(s["d"])), 0.0, 1.0)
	_sub = 1 if k < 0.5 else 2
	var e := k * k * (3.0 - 2.0 * k)
	var hand := _screen(_cur_pose(), "armL", HAND_L)
	for id in _props.keys():
		var p: Dictionary = _props[id]
		if bool(p["held"]):
			p["pos"] = hand + Vector2(0, PROP_C * IS * 0.35)
		elif bool(p["moving"]):
			var to: Vector2 = p["to"] if str(s["drop"]) == id else hand + Vector2(0, PROP_C * IS * 0.35)
			p["pos"] = (p["from"] as Vector2).lerp(to, e)


# ---------------------------------------------------------------- évènements

func _strike(n: int) -> void:
	Snd.sfx("forge_strike", -2.0, 1.0 + 0.06 * float(n))
	_shake = 0.22 + 0.06 * float(n)
	_flash_on(Color(1.0, 0.75, 0.4), 0.12, 0.35)
	var at := _anvil_top + Vector2(0, -6)
	_burst(at, Color("ffc060"), 26 + n * 8, 520.0)
	_burst(at, Color("fff0c0"), 10, 380.0)
	_rings.append({"c": at, "r0": 10.0, "r1": 120.0 + 30.0 * float(n), "t": 0.0, "max": 0.35, "col": Color("ffb050")})
	for k in range(items.size()):
		var p: Dictionary = _props["i%d" % k]
		p["glow"] = 0.35 + 0.22 * float(n)


func _merge() -> void:
	Snd.sfx("forge_fuse", -2.0)
	for k in range(items.size()):
		var p: Dictionary = _props["i%d" % k]
		p["spin"] = 5.0 + float(k)
		p["glow"] = 1.0
		p["merge_from"] = p["pos"]
	_rings.append({"c": _anvil_top + Vector2(0, -60), "r0": 140.0, "r1": 10.0, "t": 0.0, "max": 1.4, "col": Profile.item_color(result)})


func _reveal() -> void:
	Snd.sfx("forge_reveal", -2.0)
	_flash_on(Color.WHITE, 0.5, 0.95)
	_shake = 0.3
	for k in range(items.size()):
		_props["i%d" % k]["vis"] = false
	var o: Dictionary = _props["out"]
	o["vis"] = true
	o["pos"] = _reveal_at
	o["spin"] = 1.1
	o["glow"] = 1.0
	_rays = 1.0
	_rays_col = Profile.item_color(result)
	_burst(_reveal_at, _rays_col, 40, 600.0)
	_burst(_reveal_at, Color.WHITE, 16, 420.0)
	_rings.append({"c": _reveal_at, "r0": 20.0, "r1": 260.0, "t": 0.0, "max": 0.7, "col": _rays_col})
	_show_text(Profile.item_name(result), Profile.item_color(result), "%s · issu de la fusion" % str(Profile.rarity_of(result).get("name", "")))


func _rune_wake() -> void:
	Snd.sfx("rune_glow", -2.0)
	var p: Dictionary = _props["rune"]
	p["glow"] = 1.0
	_rings.append({"c": p["pos"], "r0": 10.0, "r1": 90.0, "t": 0.0, "max": 0.6, "col": p["col"]})
	_burst(p["pos"], p["col"], 14, 220.0)


func _tap(n: int) -> void:
	Snd.sfx("engrave_tap", -3.0, 1.0 + 0.05 * float(n))
	if n == 0:
		Snd.sfx("engrave_scratch", -6.0)
	var col: Color = _props["rune"]["col"]
	var at: Vector2 = _props["i0"]["pos"]
	_burst(at, col, 10 + n * 3, 260.0)
	_burst(at, Color("fff0c0"), 5, 200.0)
	_shake = 0.08
	_props["i0"]["glow"] = 0.25 + 0.15 * float(n)


func _rune_seal() -> void:
	Snd.sfx("rune_set", -2.0)
	var col: Color = _props["rune"]["col"]
	_props["rune"]["vis"] = false
	_emblem = 1.0
	_flash_on(col.lightened(0.4), 0.3, 0.5)
	var at: Vector2 = _props["i0"]["pos"]
	_rings.append({"c": at, "r0": 8.0, "r1": 160.0, "t": 0.0, "max": 0.6, "col": col})
	_burst(at, col, 34, 480.0)


func _engraved() -> void:
	var p: Dictionary = _props["i0"]
	p["from"] = p["pos"]
	p["rise"] = 0.0
	_rays = 0.8
	_rays_col = _props["rune"]["col"]
	_show_text("%s gravée" % Profile.rune_name(rune), Profile.rune_color(rune), "sur %s · %s" % [Profile.item_name(result if not result.is_empty() else items[0]), rune_text])


func _show_text(title: String, col: Color, sub: String) -> void:
	for ch in _labels.get_children():
		ch.queue_free()
	var t := UiTheme.title(title.to_upper(), 34, col)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_constant_override("outline_size", 8)
	t.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.9))
	_labels.add_child(t)
	var s := UiTheme.label(sub, 18, UiTheme.TEXT)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_labels.add_child(s)


func _finish() -> void:
	_done = true
	_hint.text = "Touche pour revenir à la Forge"


## Passer la scène : tout de suite l'état final.
func skip() -> void:
	if _done:
		return
	if not _laid:
		_layout()
	_sparks.clear()
	_rings.clear()
	for id in _props.keys():
		var p: Dictionary = _props[id]
		p["held"] = false
		p["moving"] = false
	var last := "triumph" if mode == "fusion" else "show"
	var lg := 1.0 if mode == "fusion" else 0.0
	_pose_a = dpose(last, lg)
	_pose_b = _pose_a
	_pose_key = "%s%.2f>%s%.2f" % [last, lg, last, lg]
	_si = _steps.size() - 1
	if mode == "fusion":
		_reveal()
	else:
		_props["i0"]["pos"] = _slot_pos(1)
		_rune_seal()
		_engraved()
		_props["i0"]["rise"] = 1.0
	_flash = 0.0
	_finish()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if _done:
			finished.emit()
			queue_free()
		else:
			skip()


# ---------------------------------------------------------------- effets

func _flash_on(col: Color, dur: float, peak: float) -> void:
	_flash_col = col
	_flash = peak
	_flash_col.a = dur


func _burst(at: Vector2, col: Color, n: int, speed: float) -> void:
	for i in range(n):
		var a := randf_range(-PI * 0.95, -PI * 0.05)
		var v := Vector2.from_angle(a) * randf_range(speed * 0.3, speed)
		_sparks.append({"p": at, "v": v, "life": 0.0, "max": randf_range(0.35, 0.9), "col": col, "s": float(randi_range(2, 4))})


func _dust(at: Vector2, n: int) -> void:
	for i in range(n):
		var v := Vector2(randf_range(-80.0, 80.0), randf_range(-60.0, -10.0))
		_sparks.append({"p": at, "v": v, "life": 0.0, "max": 0.5, "col": Color(0.6, 0.55, 0.5, 0.7), "s": 3.0})


func _update_fx(delta: float) -> void:
	for sp in _sparks.duplicate():
		sp["life"] = float(sp["life"]) + delta
		if float(sp["life"]) > float(sp["max"]):
			_sparks.erase(sp)
			continue
		sp["v"] = (sp["v"] as Vector2) + Vector2(0, 900.0) * delta
		sp["p"] = (sp["p"] as Vector2) + (sp["v"] as Vector2) * delta
	for r in _rings.duplicate():
		r["t"] = float(r["t"]) + delta
		if float(r["t"]) > float(r["max"]):
			_rings.erase(r)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta / maxf(0.05, _flash_col.a) * 1.0)
	_shake = maxf(0.0, _shake - delta)
	_rays = maxf(0.0, _rays - delta * 0.15) if _done else _rays
	for id in _props.keys():
		var p: Dictionary = _props[id]
		p["yaw"] = float(p["yaw"]) + float(p["spin"]) * delta
		if not bool(p["held"]) and not bool(p["moving"]) and float(p["glow"]) > 0.0 and id != "out":
			p["glow"] = maxf(0.0, float(p["glow"]) - delta * 0.4)
		if p.has("merge_from") and bool(p["vis"]):
			# Les objets montent en tournant et se rejoignent au-dessus de l'enclume.
			var k := clampf(float(p.get("mt", 0.0)) / 1.4, 0.0, 1.0)
			p["mt"] = float(p.get("mt", 0.0)) + delta
			var e := k * k
			p["pos"] = (p["merge_from"] as Vector2).lerp(_reveal_at, e) + Vector2.from_angle(_t * 7.0 + float(id.right(1)) * TAU / 3.0) * 40.0 * (1.0 - e) * k
			p["scale"] = lerpf(IS, IS * 0.6, e)
		if p.has("rise"):
			p["rise"] = minf(1.0, float(p["rise"]) + delta * 1.5)
			var k2 := float(p["rise"])
			p["pos"] = (p["from"] as Vector2).lerp(_reveal_at, k2 * k2 * (3.0 - 2.0 * k2))
			p["scale"] = lerpf(IS, RS, k2)
	if _emblem > 0.0:
		_emblem = minf(1.0, _emblem + delta)


# ---------------------------------------------------------------- dessin

func _texture(key: String, img: Image) -> ImageTexture:
	var t: ImageTexture = _tex.get(key)
	if t == null:
		t = ImageTexture.create_from_image(img)
		_tex[key] = t
		if _tex.size() > 260:
			_tex.clear()
			_tex[key] = t
	return t


## Image d'un modèle posé au sol (pieds en foot), à l'échelle sc.
func _draw_model(tex: Texture2D, foot: Vector2, sc: float, mod: Color = Color.WHITE) -> void:
	var sz := Vector2(HeroModel.W, HeroModel.H) * sc
	draw_texture_rect(tex, Rect2(foot - Vector2(float(HeroModel.W) * 0.5, float(HeroModel.H - 2)) * sc, sz), false, mod)


func _prop_tex(id: String) -> Texture2D:
	var p: Dictionary = _props[id]
	var m: HeroModel = p["model"]
	var yaw := float(p["yaw"])
	var img := m.cached(yaw, "", 0, LIGHT)
	if img == null and _budget > 0:
		_budget -= 1
		img = m.frame_at(yaw, "", 0, LIGHT)
	if img == null:
		return p["tex"]
	var step := posmod(int(round(yaw / TAU * float(HeroModel.STEPS))), HeroModel.STEPS)
	var t := _texture("%s|%d" % [id, step], img)
	p["tex"] = t
	return t


func _draw() -> void:
	if not _laid:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.02, 0.03, 0.96))
		return
	var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake * 26.0
	draw_set_transform(off, 0.0, Vector2.ONE)
	# L'atelier : le fond de la Forge, assombri, la lueur du foyer qui palpite, le sol de pierre.
	draw_rect(Rect2(-off, size), Color(0.03, 0.02, 0.03, 1.0))
	draw_texture_rect(_bg, Rect2(Vector2(0, 0), Vector2(size.x, _floor + 40.0)), false, Color(0.55, 0.45, 0.42))
	var pulse := 0.8 + 0.2 * sin(_t * 5.0) + 0.06 * sin(_t * 13.0)
	draw_texture_rect(_radial, Rect2(Vector2(size.x * 0.78 - 260.0, _floor - 420.0), Vector2(520, 520)), false, Color(1.0, 0.45, 0.15, 0.32 * pulse))
	draw_rect(Rect2(0, _floor, size.x, size.y - _floor), Color(0.07, 0.05, 0.06, 1.0))
	draw_rect(Rect2(0, _floor - 2.0, size.x, 3.0), Color(0.25, 0.14, 0.1, 0.8))
	draw_texture_rect(_radial, Rect2(_a_foot - Vector2(12, 3) * SC, Vector2(24, 6) * SC), false, Color(0, 0, 0, 0.55))
	draw_texture_rect(_radial, Rect2(_d_foot - Vector2(8, 2) * SC, Vector2(16, 4) * SC), false, Color(0, 0, 0, 0.5))
	# L'établi, Durgan, l'enclume.
	var bi := _bench.frame_at(_yaw, "", 0, LIGHT)
	_draw_model(_texture("bench", bi), _b_foot, SC)
	var key := "%s|%d" % [_pose_key if _pose_key != "" else "rest0.00>rest0.00", _sub]
	var di := _durgan.frame_pose(_yaw, key, _cur_pose() if _pose_key != "" else dpose("rest", 0.0), LIGHT)
	_draw_model(_texture("d|" + key, di), _d_foot, SC)
	var ai := _anvil.frame_at(_yaw, "", 0, LIGHT)
	_draw_model(_texture("anvil", ai), _a_foot, SC)
	# Rayons derrière l'objet révélé.
	if _rays > 0.0:
		var c := _reveal_at
		for i in range(12):
			var a := _t * 0.6 + float(i) / 12.0 * TAU
			var pts := PackedVector2Array([c, c + Vector2.from_angle(a - 0.08) * 420.0, c + Vector2.from_angle(a + 0.08) * 420.0])
			draw_colored_polygon(pts, Color(_rays_col, 0.12 * _rays))
		draw_texture_rect(_radial, Rect2(c - Vector2(180, 180), Vector2(360, 360)), false, Color(_rays_col, 0.45 * _rays))
	# Les objets et la rune.
	for id in _props.keys():
		var p: Dictionary = _props[id]
		if not bool(p["vis"]):
			continue
		var t := _prop_tex(id)
		if t == null:
			continue
		var sc := float(p["scale"])
		var pos: Vector2 = p["pos"]
		var gl := float(p["glow"])
		if gl > 0.0:
			var r := 20.0 * sc * (0.8 + 0.2 * sin(_t * 9.0))
			draw_texture_rect(_radial, Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(p["col"], 0.55 * gl))
		var foot := pos + Vector2(0, PROP_C * sc)
		_draw_model(t, foot, sc, Color.WHITE.lerp(Color(1.4, 1.3, 1.1), gl * 0.4))
		if id == "i0" and _emblem > 0.0 and mode == "gravure":
			# Le glyphe de la rune gravée, qui s'allume sur l'objet.
			var rt := ItemArt.rune(str(rune.get("rune", "")), int(rune.get("level", 1)), 48)
			var es := 11.0 * sc
			var ga := (0.6 + 0.4 * sin(_t * 6.0)) * _emblem
			draw_texture_rect(_radial, Rect2(pos - Vector2(es, es), Vector2(es, es) * 2.0), false, Color(p.get("rcol", _props["rune"]["col"]), 0.6 * ga))
			draw_texture_rect(rt, Rect2(pos - Vector2(es, es) * 0.5, Vector2(es, es)), false, Color(1, 1, 1, _emblem))
	# Anneaux d'onde.
	for r2 in _rings:
		var k := float(r2["t"]) / float(r2["max"])
		var rad := lerpf(float(r2["r0"]), float(r2["r1"]), k)
		draw_arc(r2["c"], rad, 0.0, TAU, 48, Color(r2["col"], 0.8 * (1.0 - k)), 4.0 * (1.0 - k) + 1.0, true)
	# Étincelles : de petits carrés, comme les pixels du décor.
	for sp in _sparks:
		var a2 := 1.0 - float(sp["life"]) / float(sp["max"])
		var s := float(sp["s"])
		draw_rect(Rect2((sp["p"] as Vector2) - Vector2(s, s) * 0.5, Vector2(s, s)), Color(sp["col"], a2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(_flash_col.r, _flash_col.g, _flash_col.b, clampf(_flash, 0.0, 1.0)))
