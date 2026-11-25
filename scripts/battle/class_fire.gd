class_name ClassFire
extends RefCounted
## Tir normal de chaque classe (docs/design/42-tirs-de-classe.md) : ce que le héros et ses compagnons
## envoient en continu, hors sorts. Le Nécromancien et le Mage invoquent des troupes ; les autres classes
## lancent des tirs (flèche, onde d'épée, orbe de lumière, bouclier, haches).
## Un tir est une unité alliée particulière (Unit.shot) : il traverse les portails comme une invocation
## (dédoublé par +N et ×N, coloré par un portail d'élément, absorbé par -N…), touche les tours, le boss et
## le Nexus, mais aucun ennemi ne peut le viser ni le blesser.

const ONDE_RANGE := 5.6 ## l'onde de l'Épéiste s'éteint après 5,6 cases ; un portail positif la relance
## every : secondes entre deux salves (à cadence de base) ; n : unités ou tirs par salve ;
## mult : dégâts par rapport aux troupes de la classe (son familier) ; speed (cases/s), radius (cases).
const SPEC := {
	"necromancien": {"every": 0.3, "n": 2, "atk": 2.0, "hp": 2.0, "size": 1.1, "rise": 0.45},
	"mage": {"every": 0.2, "n": 3},
	"archer": {"every": 0.5, "shot": "fleche", "mult": 3.0, "speed": 12.0, "radius": 0.16, "pierce": 3},
	"epeiste": {"every": 0.4, "shot": "onde", "mult": 1.5, "speed": 8.0, "radius": 0.9, "range": ONDE_RANGE},
	"clerc": {"every": 0.6, "shot": "lumiere", "mult": 1.5, "speed": 6.5, "radius": 0.22},
	"chevalier": {"every": 0.8, "shot": "bouclier", "mult": 4.0, "speed": 9.0, "radius": 0.26},
	"berserker": {"every": 0.15, "n": 2, "shot": "hache", "mult": 0.7, "speed": 10.0, "radius": 0.16},
}
const LIGHT_AOE := 0.95 ## rayon du rayon de lumière du Clerc
const LIGHT_HEAL := 0.4 ## Barrière rendue par ennemi touché par le rayon…
const LIGHT_HEAL_MAX := 1.6 ## … et au plus par rayon
const SHIELD_PUSH := 0.45 ## recul de l'ennemi frappé par le bouclier du Chevalier (la moitié autour de lui)
const SHIELD_SLOW := 1.2 ## secondes de ralentissement
const AXE_FAN := 1.7 ## vitesse latérale de départ des haches (éventail), qui s'amortit
## Couleur propre à chaque classe (traînées, éclats) : on reconnaît le tir d'un coup d'œil.
const COLOR := {
	"necromancien": "B07CFF", "mage": "4FE3D2", "archer": "B8F07A", "epeiste": "CFE8FF",
	"clerc": "FFE27A", "chevalier": "8FB8FF", "berserker": "FF5A4A",
}
const SHOT_CLASS := {"fleche": "archer", "onde": "epeiste", "lumiere": "clerc", "bouclier": "chevalier", "hache": "berserker"}


static func spec(class_id: String) -> Dictionary:
	return SPEC.get(class_id, LEGACY)


## Ancien Flux : un familier toutes les 0,25 s.
const LEGACY := {"every": 0.25, "n": 1}
## Les compagnons gardent l'ancien Flux (leurs troupes tiennent le terrain) : s'ils tiraient eux aussi, plus
## personne ne retiendrait les ennemis (simulations : 0 victoire sur 4 au Colosse runique, 4-5, et au 6-8 pour
## l'Archer, le Clerc et le Chevalier ; 4 sur 4 avec leurs troupes).
const COMPANIONS_FIRE := false


## Tir d'un lanceur : celui de sa classe pour le héros ; l'ancien Flux pour les compagnons.
static func spec_of(c: BattleSim.Caster) -> Dictionary:
	if c.is_bot and not COMPANIONS_FIRE:
		return LEGACY
	return spec(c.class_id)


static func color(class_id: String) -> String:
	return str(COLOR.get(class_id, "4FE3D2"))


## Salves par seconde : cadence de la classe × Célérité et effets (Brise, échos), et pour le Berserker
## la rage : jusqu'à ×2 quand la Barrière est basse.
static func rate(s: BattleSim, c: BattleSim.Caster) -> float:
	var sp := spec_of(c)
	var r := (c.cadence / 4.0) / float(sp["every"]) * s.cadence_mult
	if s.breeze_t > 0.0 and c.idx == 0:
		r *= 1.5
	if c.class_id == "berserker" and sp.has("shot"):
		r *= rage(s)
	if s.time < s.shot_buff_until:
		r *= 1.0 + float(s.shot_buff.get("aspd", 0.0))
	return r


## Rage du Berserker : ×1 Barrière pleine, ×2 à 25 % ou moins.
static func rage(s: BattleSim) -> float:
	return 1.0 + clampf((1.0 - s.barrier_hp / maxf(1.0, s.barrier_max)) / 0.75, 0.0, 1.0)


static func volley(s: BattleSim, c: BattleSim.Caster) -> void:
	var sp := spec_of(c)
	var kind := str(sp.get("shot", ""))
	var n := int(sp.get("n", 1))
	var y0 := BattleSim.CASTER_Y + 0.45
	if kind == "":
		_troops(s, c, sp, n, y0)
		return
	for i in range(n):
		var off := 0.0 if n == 1 else (-0.14 if i == 0 else 0.14)
		var u := _make_shot(s, c, sp, kind, Vector2(clampf(c.x + off, 0.2, BattleSim.W - 0.2), y0))
		if kind == "hache":
			u.vx = (-1.0 if i == 0 else 1.0) * AXE_FAN * s.rng.randf_range(0.8, 1.1)
	s._event({"t": "shot_fire", "kind": kind, "c": c.idx, "pos": Vector2(c.x, BattleSim.CASTER_Y + 0.3), "color": color(c.class_id)})


## Nécromancien : deux squelettes sortent de terre devant lui ; Mage : trois lucioles d'un coup.
static func _troops(s: BattleSim, c: BattleSim.Caster, sp: Dictionary, n: int, y0: float) -> void:
	var pts: Array = []
	var rise := float(sp.get("rise", 0.0))
	for i in range(n):
		var off := 0.0 if n == 1 else lerpf(-0.34, 0.34, float(i) / float(n - 1))
		var p := Vector2(clampf(c.x + off + s.rng.randf_range(-0.06, 0.06), 0.3, BattleSim.W - 0.3), y0 + (0.35 if rise > 0.0 else 0.0) + s.rng.randf_range(-0.05, 0.05))
		var u := s._spawn_familiar(c, p, float(sp.get("atk", 1.0)), float(sp.get("hp", 1.0)), float(sp.get("size", 1.0)), rise)
		if u != null:
			pts.append(u.pos)
	if c.class_id == "necromancien":
		for p: Vector2 in pts:
			s._event({"t": "rise", "pos": p, "c": c.idx, "color": color(c.class_id)})
	elif c.class_id == "mage":
		s._event({"t": "fireflies", "from": Vector2(c.x, BattleSim.CASTER_Y + 0.3), "pts": pts, "c": c.idx, "color": color(c.class_id)})


static func _make_shot(s: BattleSim, c: BattleSim.Caster, sp: Dictionary, kind: String, p: Vector2) -> Unit:
	var u := s._make_unit(c.familiar, 0, p)
	u.owner_idx = c.idx
	u.atk *= c.atk_mult
	if c.idx == 0:
		s._player_unit_mods(u)
	u.role = "tir"
	u.shot = kind
	u.sprite = "tir_" + kind
	u.atk *= float(sp.get("mult", 1.0))
	u.hp = 1.0
	u.max_hp = 1.0
	u.shield = 0.0
	u.defense = 0.0
	u.heal_aura = 0.0
	u.attack_range = 0.0
	u.front_block = 0.0
	u.siege = false
	u.speed = float(sp.get("speed", 9.0))
	u.radius = float(sp.get("radius", 0.2))
	u.pierce = int(sp.get("pierce", 1))
	u.travel = float(sp.get("range", 99.0))
	u.crit = c.crit
	u.anim = 0.0
	if u.element == "physique":
		u.element = c.element
	u.frenzy_t = maxf(0.0, s.frenzy_until - s.time)
	if s.time < s.shot_buff_until:
		u.buff_t = s.shot_buff_until - s.time
		u.buff_atk = float(s.shot_buff.get("atk", 0.0))
		u.buff_crit = float(s.shot_buff.get("crit", 0.0))
		u.buff_steal = float(s.shot_buff.get("steal", 0.0))
	s._add_ally(u)
	if c.idx == 0 and ((s._mod("free_clone") > 0.0 and s.rng.randf() < s._mod("free_clone")) or (s._mod("ghost_double") > 0.0 and s.rng.randf() < s._mod("ghost_double"))):
		# Rune Mult, Double fantôme : le tir part parfois en double.
		s._add_ally(s._clone(u, Vector2(s.rng.randf_range(-0.25, 0.25), -0.1)))
	return u


# ---------------------------------------------------------------- vol

static func move(s: BattleSim, u: Unit) -> void:
	u.anim += BattleSim.TICK
	var sf := maxf(0.25, 1.0 - 0.15 * float(u.slow_stacks))
	match u.shot:
		"hache":
			# Éventail : les haches s'écartent puis filent droit.
			u.vx *= 0.9
		"lumiere":
			# L'orbe du Clerc file vers le groupe d'ennemis le plus proche devant lui.
			var t := s._nearest(s._grid_e, u.pos + Vector2(0.0, 1.6), 2.4)
			u.vx = clampf((t.pos.x - u.pos.x) * 3.0, -3.0, 3.0) if t != null else u.vx * 0.85
	if u.pos.y > BattleSim.HOMING_Y:
		# En fin de course, comme les troupes : le tir s'infléchit vers le Nexus, la tour, le boss ou la rune
		# de son élément.
		u.vx = clampf((s._homing_target_x(u) - u.pos.x) * 2.5, -3.0, 3.0)
	var dy := u.speed * sf * BattleSim.TICK
	u.pos.x = clampf(u.pos.x + u.vx * BattleSim.TICK, 0.15, BattleSim.W - 0.15)
	u.pos.y += dy
	u.travel -= dy
	if u.travel <= 0.0 or u.pos.y >= BattleSim.H - 0.1:
		u.alive = false
		if u.shot == "onde" or u.shot == "lumiere":
			s._event({"t": "shot_end", "kind": u.shot, "pos": u.pos, "color": color(str(SHOT_CLASS.get(u.shot, "")))})


## L'onde de l'Épéiste repart de plus belle en traversant un portail positif (sinon elle ne quitterait
## jamais les abords du mur).
static func on_portal(_s: BattleSim, p: Portal, u: Unit) -> void:
	if u.shot == "onde" and not p.mirage and not p.is_negative():
		u.travel = maxf(u.travel, ONDE_RANGE)


# ---------------------------------------------------------------- impacts

static func hits(s: BattleSim) -> void:
	for u in s.allies:
		if not u.alive or u.shot == "":
			continue
		match u.shot:
			"onde":
				_hit_arc(s, u)
			"lumiere":
				_hit_light(s, u)
			_:
				_hit_line(s, u)


static func _valid(s: BattleSim, u: Unit, e: Unit) -> bool:
	if not e.alive or u.hit_ids.has(e.id):
		return false
	if e.role == "rune" and e.element != u.element:
		return false # rune d'un autre élément : le tir la traverse
	return not (s.traitor_broken and e == s.traitor_unit)


## Flèche, bouclier, hache : ennemis sur le trajet du dernier pas, du plus proche au plus loin.
static func _hit_line(s: BattleSim, u: Unit) -> void:
	var a := u.prev_pos
	var b := u.pos
	var ab := b - a
	var len2 := maxf(0.0001, ab.length_squared())
	var cands: Array = []
	for e: Unit in s._query(s._grid_e, (a + b) * 0.5, sqrt(len2) * 0.5 + u.radius + 1.6):
		if not _valid(s, u, e):
			continue
		var k := clampf((e.pos - a).dot(ab) / len2, 0.0, 1.0)
		var rr := u.radius + e.radius
		if e.pos.distance_squared_to(a + ab * k) <= rr * rr:
			cands.append([k, e])
	if cands.is_empty():
		return
	cands.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	for ce: Array in cands:
		var e: Unit = ce[1]
		u.hit_ids[e.id] = true
		s._hit(u, e)
		if u.shot == "bouclier":
			_shield_bash(s, e)
		s._event({"t": "shot_hit", "kind": u.shot, "pos": e.pos, "color": color(str(SHOT_CLASS.get(u.shot, "")))})
		u.pierce -= 1
		if u.pierce <= 0:
			u.alive = false
			return


## Bouclier du Chevalier : l'ennemi frappé recule et ralentit, ceux d'à côté un peu moins.
static func _shield_bash(s: BattleSim, tgt: Unit) -> void:
	for e: Unit in s._query(s._grid_e, tgt.pos, 0.75):
		if not e.alive:
			continue
		var k := 1.0 if e == tgt else 0.5
		e.slow_stacks = maxi(e.slow_stacks, 2)
		e.slow_t = maxf(e.slow_t, SHIELD_SLOW * k)
		if e.role in ["boss", "rune", "tete", "banniere"] or e.hold_y > 0.0:
			continue
		var push := SHIELD_PUSH * k * (0.5 if e.elite else 1.0)
		e.pos.y = minf(BattleSim.H - 0.6, e.pos.y + push)


## Onde de l'Épéiste : un large arc qui touche tout ce qu'il balaie.
static func _hit_arc(s: BattleSim, u: Unit) -> void:
	var y0 := u.prev_pos.y - 0.25
	var y1 := u.pos.y + 0.25
	for e: Unit in s._query(s._grid_e, u.pos, u.radius + 1.2):
		if not _valid(s, u, e):
			continue
		if e.pos.y + e.radius < y0 or e.pos.y - e.radius > y1 or absf(e.pos.x - u.pos.x) > u.radius + e.radius:
			continue
		u.hit_ids[e.id] = true
		s._hit(u, e)
		s._event({"t": "shot_hit", "kind": "onde", "pos": e.pos, "color": color("epeiste")})


## Orbe du Clerc : au contact d'un ennemi, un rayon de lumière tombe sur son groupe ; chaque ennemi touché
## rend un peu de Barrière.
static func _hit_light(s: BattleSim, u: Unit) -> void:
	var first := s._nearest(s._grid_e, u.pos, u.radius + 0.5)
	if first == null or not _valid(s, u, first):
		return
	var center := Vector2.ZERO
	var group: Array = s._query(s._grid_e, first.pos, LIGHT_AOE)
	for e: Unit in group:
		center += e.pos
	center /= float(maxi(1, group.size()))
	var n := 0
	for e: Unit in s._query(s._grid_e, center, LIGHT_AOE):
		if _valid(s, u, e):
			u.hit_ids[e.id] = true
			s._hit(u, e)
			n += 1
	if n > 0 and s.barrier_hp > 0.0 and s.barrier_hp < s.barrier_max:
		var h := minf(LIGHT_HEAL_MAX, LIGHT_HEAL * float(n)) * (1.0 + s._mod("heal_bonus"))
		var before := s.barrier_hp
		s.barrier_hp = minf(s.barrier_max, s.barrier_hp + h)
		s.healed_total += s.barrier_hp - before
	s._event({"t": "shot_beam", "pos": center, "r": LIGHT_AOE, "n": n, "color": color("clerc")})
	u.alive = false
