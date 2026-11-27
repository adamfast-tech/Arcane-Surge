class_name HavrePlace
extends Control
## La place d'Havre-Aube (docs/design/49-havre-aube-place.md) : une rue en pixel art, plus large que l'écran, bordée
## des lieux du village ; le héros en volume s'y promène. Toucher la rue l'y fait marcher ; toucher un lieu ou son
## gardien l'y conduit, puis l'ouvre. Chaque marchand se tient en volume devant sa boutique (Durgan à la Forge,
## Aldric à l'Armurerie, Ossian à la Bibliothèque, Sœur Aelis à la Méditation) et se tourne vers le héros qui
## approche ; les compagnons du Cercle attendent autour du feu. Le jour, l'aube, le crépuscule et la nuit suivent
## l'heure de Havre-Aube (fenêtres allumées le soir).

signal open(room: String) ## map, equipment, forge, armory, library, skills, circle, meditation, tower, quests

const S := 3.0 ## pixels d'écran par pixel du décor
const H := 430.0 ## hauteur de la place
const STREET_Y := 352.0 ## pieds des personnages (haut de la rue + marge)
const GROUND := 316.0 ## pied des façades
const GAP := 12 ## espace entre deux lieux (pixels du décor)
const WALK := 260.0 ## vitesse de marche (px par seconde)
const PX := 3 ## taille d'un pixel des personnages en volume

## Lieux, de gauche à droite : identifiant, nom affiché, salle ouverte, largeur et hauteur du dessin (pixels du
## décor), gardien en volume, et décalage de sa place devant la porte.
const SPOTS := [
	{"id": "portail", "name": "Porte du monde", "room": "map", "w": 70, "h": 84, "npc": ""},
	{"id": "maison", "name": "Ta maison", "room": "equipment", "w": 66, "h": 64, "npc": ""},
	{"id": "defis", "name": "Défis", "room": "quests", "w": 44, "h": 52, "npc": ""},
	{"id": "forge", "name": "Forge", "room": "forge", "w": 80, "h": 80, "npc": "durgan"},
	{"id": "armurerie", "name": "Armurerie", "room": "armory", "w": 78, "h": 74, "npc": "aldric"},
	{"id": "bibliotheque", "name": "Bibliothèque", "room": "library", "w": 78, "h": 94, "npc": "ossian"},
	{"id": "entrainement", "name": "Entraînement", "room": "skills", "w": 72, "h": 54, "npc": ""},
	{"id": "cercle", "name": "Le Cercle", "room": "circle", "w": 92, "h": 56, "npc": ""},
	{"id": "meditation", "name": "Méditation", "room": "meditation", "w": 66, "h": 104, "npc": "aelis"},
	{"id": "tour", "name": "Tour des Échos", "room": "tower", "w": 56, "h": 124, "npc": ""},
]

var phase := "jour"
var _x0: Dictionary = {} ## id -> abscisse du lieu dans la rue (px écran, monde)
var _tex: Dictionary = {} ## id -> ImageTexture de la façade
var _world_w := 0.0
var _cam := 0.0
var _hero: HeroTurntable
var _hero_x := 0.0
var _target := -1.0
var _goal := "" ## salle à ouvrir à l'arrivée
var _npcs: Dictionary = {} ## id -> HeroTurntable
var _crew: Array = [] ## compagnons autour du feu
var _press := Vector2.ZERO
var _t := 0.0
var _toast := ""
var _toast_t := 0.0
var _font: Font
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	custom_minimum_size = Vector2(0, H)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	phase = Ambience.havre_phase() if Profile.ambience_on() else "jour"
	_font = UiTheme.title_font()
	var x := float(GAP) * S
	for sp in SPOTS:
		_x0[str(sp["id"])] = x
		_tex[str(sp["id"])] = ImageTexture.create_from_image(PlaceArt.facade(str(sp["id"]), int(sp["w"]), int(sp["h"]), phase))
		x += (float(sp["w"]) + float(GAP)) * S
	_world_w = x
	var light := phase
	# Les gardiens devant leur porte.
	for sp in SPOTS:
		var who := str(sp["npc"])
		if who == "" or (who == "aelis" and not Profile.meditation_unlocked()):
			continue
		var tt := _figure(HeroModel.of_companion(who, ""), light)
		_npcs[str(sp["id"])] = tt
	# Les compagnons du Cercle, autour du feu.
	for who in Profile.active_companions():
		if HeroModel.has_companion(who) and _crew.size() < 2:
			_crew.append(_figure(HeroModel.of_companion(who, Profile.companion_class(who)), light))
	# Le héros, devant sa maison.
	_hero = _figure(HeroModel.of(Profile.look(), Profile.race(), Profile.player_class(), Profile.visible_cosmetics(), Profile.gear_look()), light)
	_hero.yaw = PI + 0.4
	_hero_x = _door("maison") + 70.0
	_cam = clampf(_hero_x - 300.0, 0.0, maxf(0.0, _world_w - 600.0))
	set_process(true)


func _figure(m: HeroModel, light: String) -> HeroTurntable:
	var tt := HeroTurntable.new()
	tt.interactive = false
	tt.px_scale = PX
	tt.light = light
	tt.yaw = PI
	tt.setup_model(m)
	add_child(tt)
	return tt


## Abscisse (monde) de la porte d'un lieu.
func _door(id: String) -> float:
	for sp in SPOTS:
		if str(sp["id"]) == id:
			return float(_x0[id]) + float(sp["w"]) * S * 0.5
	return 0.0


func _spot_at(wx: float, y: float) -> Dictionary:
	for sp in SPOTS:
		var x0 := float(_x0[str(sp["id"])])
		var top := GROUND - float(sp["h"]) * S
		if wx >= x0 and wx <= x0 + float(sp["w"]) * S and y >= top and y <= STREET_Y + 10.0:
			return sp
	return {}


func _unlocked(room: String) -> bool:
	match room:
		"meditation":
			return Profile.meditation_unlocked()
		"tower":
			return Profile.tower_unlocked()
	return true


func _process(delta: float) -> void:
	_t += delta
	if _toast_t > 0.0:
		_toast_t -= delta
	# Le héros marche vers sa cible ; la caméra le suit.
	if _target >= 0.0:
		var d := _target - _hero_x
		var step := WALK * delta
		if absf(d) <= step:
			_hero_x = _target
			_target = -1.0
			_hero.play("idle")
			_hero.yaw = PI + 0.4
			if _goal != "":
				var g := _goal
				_goal = ""
				open.emit(g)
		else:
			_hero_x += step * signf(d)
			_hero.yaw = PI * 0.5 if d > 0.0 else PI * 1.5
			if _hero.current_anim() != "walk":
				_hero.play("walk")
	var w := size.x
	var want := clampf(_hero_x - w * 0.5, 0.0, maxf(0.0, _world_w - w))
	_cam = lerpf(_cam, want, clampf(delta * 4.0, 0.0, 1.0))
	_place(_hero, _hero_x)
	for id in _npcs.keys():
		var tt: HeroTurntable = _npcs[id]
		var nx := _door(str(id)) + 46.0
		_place(tt, nx)
		# Le gardien se tourne vers le héros qui approche.
		var near := absf(_hero_x - nx) < 180.0
		var want_yaw := PI - 0.7 * signf(_hero_x - nx) if near else PI
		tt.yaw = lerp_angle(tt.yaw, want_yaw, clampf(delta * 5.0, 0.0, 1.0))
	var fire := _door("cercle")
	for i in range(_crew.size()):
		var tt2: HeroTurntable = _crew[i]
		var cx := fire + (-62.0 if i == 0 else 62.0)
		_place(tt2, cx, -8.0)
		tt2.yaw = PI - 0.9 if i == 0 else PI + 0.9
	queue_redraw()


func _place(tt: HeroTurntable, wx: float, dy: float = 0.0) -> void:
	tt.size = tt.custom_minimum_size
	tt.position = Vector2(wx - _cam - tt.size.x * 0.5, STREET_Y + dy - tt.size.y)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := e as InputEventMouseButton
		if mb.pressed:
			_press = mb.position
		elif mb.position.distance_to(_press) < 14.0:
			_tap(mb.position)


## Un toucher : vers un lieu (puis l'ouvrir), ou un point de la rue.
func _tap(p: Vector2) -> void:
	var wx := p.x + _cam
	var sp := _spot_at(wx, p.y)
	if sp.is_empty():
		for id in _npcs.keys():
			if absf(wx - (_door(str(id)) + 46.0)) < 30.0 and p.y > STREET_Y - 110.0:
				sp = _spot_of(str(id))
	if not sp.is_empty():
		var room := str(sp["room"])
		if not _unlocked(room):
			_toast = "%s : fermé jusqu'à la fin de l'acte 1" % str(sp["name"])
			_toast_t = 2.2
			Snd.sfx("ui_error", -8.0)
			return
		Snd.click()
		_goal = room
		_target = clampf(_door(str(sp["id"])), 30.0, _world_w - 30.0)
		return
	_goal = ""
	_target = clampf(wx, 30.0, _world_w - 30.0)


func _spot_of(id: String) -> Dictionary:
	for sp in SPOTS:
		if str(sp["id"]) == id:
			return sp
	return {}


## Envoie le héros vers un lieu (et l'ouvre à l'arrivée), comme un toucher.
func go_to(room: String) -> void:
	for sp in SPOTS:
		if str(sp["room"]) == room:
			_goal = room
			_target = _door(str(sp["id"]))


func _draw() -> void:
	var w := size.x
	# Ciel et lointain (parallaxe).
	var sky: Array = PlaceArt.SKY.get(phase, PlaceArt.SKY["jour"])
	for i in range(12):
		var k := float(i) / 12.0
		draw_rect(Rect2(0, H * 0.8 * k, w, H * 0.8 / 12.0 + 1.0), Color(sky[0]).lerp(Color(sky[1]), k))
	if phase == "nuit":
		_rng.seed = 7
		for i in range(40):
			var sx := fposmod(_rng.randf() * 1400.0 - _cam * 0.1, w)
			draw_rect(Rect2(sx, _rng.randf() * 150.0, 2, 2), Color(1, 1, 1, 0.4 + 0.4 * sin(_t * 2.0 + float(i))))
	_rng.seed = 11
	var hill := Color(sky[2])
	for i in range(28):
		var hx := float(i) * 120.0 - fposmod(_cam * 0.35, 120.0) - 60.0
		var hh := 60.0 + _rng.randf() * 50.0
		draw_rect(Rect2(hx, GROUND - hh - 30.0, 124.0, hh + 40.0), hill)
		draw_rect(Rect2(hx + 30.0, GROUND - hh - 52.0, 18.0, 30.0), hill)
	# Les façades.
	for sp in SPOTS:
		var id := str(sp["id"])
		var x := float(_x0[id]) - _cam
		var ww := float(sp["w"]) * S
		if x > w or x + ww < 0.0:
			continue
		var hh2 := float(sp["h"]) * S
		draw_texture_rect(_tex[id], Rect2(x, GROUND - hh2, ww, hh2), false)
		_animate(id, x, ww, hh2)
	# La rue pavée.
	draw_rect(Rect2(0, GROUND, w, H - GROUND), Color(PlaceArt.STREET[phase][0]))
	_rng.seed = 23
	for row in range(5):
		var y := GROUND + 6.0 + float(row) * 22.0
		var off := fposmod(-_cam + float(row % 2) * 18.0, 36.0)
		for i in range(int(w / 36.0) + 2):
			draw_rect(Rect2(off + float(i) * 36.0 - 36.0, y, 30.0, 14.0), Color(PlaceArt.STREET[phase][1]))
	draw_rect(Rect2(0, GROUND, w, 4), Color(0, 0, 0, 0.35))
	# Ombres des personnages.
	for tt in [_hero] + _npcs.values() + _crew:
		var c := (tt as Control).position + Vector2((tt as Control).size.x * 0.5, (tt as Control).size.y)
		draw_circle(c + Vector2(0, -2), 22.0, Color(0, 0, 0, 0.3))
	# Enseignes : le nom de chaque lieu au-dessus de sa porte.
	for sp in SPOTS:
		var id2 := str(sp["id"])
		var cx := _door(id2) - _cam
		if cx < -120.0 or cx > w + 120.0:
			continue
		var top := GROUND - float(sp["h"]) * S
		var name := str(sp["name"])
		var locked := not _unlocked(str(sp["room"]))
		var tw := _font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		var r := Rect2(cx - tw * 0.5 - 10.0, top - 34.0, tw + 20.0, 28.0)
		draw_rect(r, Color(0.05, 0.04, 0.06, 0.78))
		draw_rect(r, Color(UiTheme.GOLD if not locked else UiTheme.MUTED, 0.7), false, 2.0)
		draw_string(_font, Vector2(r.position.x + 10.0, r.position.y + 21.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UiTheme.GOLD if not locked else UiTheme.MUTED)
		if id2 == "defis" and Profile.quests_claimable() > 0:
			draw_circle(Vector2(r.end.x, r.position.y), 9.0, UiTheme.DANGER)
	if _toast_t > 0.0:
		var tw2 := _font.get_string_size(_toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var r2 := Rect2(w * 0.5 - tw2 * 0.5 - 12.0, 14.0, tw2 + 24.0, 32.0)
		draw_rect(r2, Color(0.05, 0.04, 0.06, 0.85))
		draw_string(_font, Vector2(r2.position.x + 12.0, r2.position.y + 23.0), _toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UiTheme.TEXT)


## Ce qui bouge sur les façades : fumée de la forge, portail qui tourbillonne, feu du Cercle, lueur de la Tour.
func _animate(id: String, x: float, ww: float, hh: float) -> void:
	var top := GROUND - hh
	match id:
		"forge":
			for i in range(5):
				var k := fposmod(_t * 0.35 + float(i) * 0.2, 1.0)
				draw_circle(Vector2(x + ww * 0.78 + sin(_t + float(i)) * 6.0 + k * 14.0, top - k * 70.0), 6.0 + k * 10.0, Color(0.5, 0.48, 0.5, 0.35 * (1.0 - k)))
			draw_rect(Rect2(x + ww * 0.36, GROUND - 22.0 * S, ww * 0.28, 22.0 * S), Color(1.0, 0.5, 0.15, 0.12 + 0.06 * sin(_t * 6.0)))
		"portail":
			var c := Vector2(x + ww * 0.5, GROUND - 32.0 * S)
			for i in range(4):
				var rr := (10.0 + float(i) * 7.0) * S * 0.5
				draw_arc(c, rr, _t * (1.5 + float(i) * 0.4), _t * (1.5 + float(i) * 0.4) + 4.2, 24, Color(0.4, 0.8, 1.0, 0.5 - 0.08 * float(i)), 3.0)
		"cercle":
			var f := Vector2(x + ww * 0.5, GROUND + 6.0)
			for k2 in range(3):
				var sx := float(k2 - 1) * 9.0
				var hgt := 30.0 + 8.0 * sin(_t * 7.0 + float(k2) * 2.0)
				draw_colored_polygon(PackedVector2Array([f + Vector2(sx - 9, 0), f + Vector2(sx + sin(_t * 6.0 + float(k2)) * 4.0, -hgt), f + Vector2(sx + 9, 0)]),
					Color([Color("ff6a2a"), Color("ffb44a"), Color("ff8a3a")][k2], 0.9))
			draw_circle(f + Vector2(0, -6), 40.0, Color(1.0, 0.55, 0.2, 0.08 + 0.03 * sin(_t * 9.0)))
		"tour":
			var g := 0.5 + 0.5 * sin(_t * 2.0)
			draw_circle(Vector2(x + ww * 0.5, top + 14.0 * S), 14.0 + 6.0 * g, Color(0.7, 0.5, 1.0, 0.25 + 0.2 * g))
