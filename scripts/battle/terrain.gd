class_name BattleTerrain
extends RefCounted
## Terrain interactif de l'arène (docs/design/19-terrain-interactif.md) : sols laissés par les sorts
## (braises, verglas, eau, miasme, champ statique, runes, cratères, gravats, fissures, failles),
## réactions entre éléments (vapeur, gel, électrocution, incendie, résonance), piliers en ruine qui
## s'effondrent sur les ennemis, murs de pierre qui bloquent le passage, séismes.

## Effets des sols sur les ennemis qui s'y trouvent.
const KINDS := {
	"braises": {"name": "Braises", "elem": "feu", "burn": true, "dur": 5.0},
	"verglas": {"name": "Verglas", "slow": 0.35, "conduct": true, "dur": 7.0},
	"eau": {"name": "Eau", "slow": 0.25, "conduct": true, "dur": 9.0},
	"miasme": {"name": "Miasme", "expose": true, "dur": 6.0},
	"statique": {"name": "Champ statique", "elem": "foudre", "conduct": true, "dur": 7.0},
	"rune": {"name": "Rune piège", "dur": 25.0},
	"cratere": {"name": "Cratère", "slow": 0.2, "permanent": true},
	"gravats": {"name": "Gravats", "slow": 0.3, "dur": 25.0},
	"fissure": {"name": "Fissure", "slow": 0.25, "dur": 12.0},
	"faille": {"name": "Faille", "elem": "physique", "slow": 0.5, "dur": 8.0},
	# Zone 3 : les mares de poison frappent les invocations alliées (les bêtes du marais y sont immunisées).
	"poison": {"name": "Mare de poison", "ally": true, "slow": 0.3, "dur": 8.0},
	# Zone 4 : la glace fait glisser tout le monde (invocations et ennemis) ; le Feu la fait fondre un moment.
	"glace": {"name": "Glace", "slide": true, "conduct": true, "permanent": true},
}
const MAX_SURFACES := 48
const MAX_CRATERS := 14
const MAX_RUNES := 3
## Hausse des dégâts subis dans le Miasme.
const EXPOSE_MULT := 1.3

var sim: BattleSim
var surfaces: Array[Dictionary] = []
var props: Array[Dictionary] = [] ## piliers en ruine le long de la chaussée
var walls: Array[Dictionary] = []
var reactions := 0
var _next_id := 1


func setup(s: BattleSim) -> void:
	sim = s
	_build_pillars()


## Piliers en ruine (mêmes positions que le décor : graine fixe).
func _build_pillars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for y in [1.8, 4.2, 7.8, 9.6, 12.2, 15.4]:
		for side in [-1, 1]:
			if rng.randf() < 0.25:
				continue
			var x := -0.55 if side < 0 else 9.55
			var h := rng.randf_range(0.6, 2.4)
			var p := {"id": _id(), "pos": Vector2(x, float(y)), "h": h, "side": side, "alive": true, "fall_t": -1.0,
				"hp": 0.0, "max_hp": 0.0, "block": false, "block_rot": 0.0}
			if rng.randf() < 0.6:
				p["block"] = true
				p["block_rot"] = rng.randf_range(-0.6, 0.6)
			props.append(p)
	for p in props:
		p["max_hp"] = (40.0 + 30.0 * float(p["h"])) * sim.enemy_mult
		p["hp"] = p["max_hp"]


func _id() -> int:
	_next_id += 1
	return _next_id


# ---------------------------------------------------------------- mise à jour

func update() -> void:
	var dt := BattleSim.TICK
	for e in sim.enemies:
		e.exposed_t = maxf(0.0, e.exposed_t - dt)
	for a in sim.allies:
		a.zone_slow = 0.0
	var i := 0
	while i < surfaces.size():
		var s: Dictionary = surfaces[i]
		if not bool(s.get("permanent", false)):
			s["t"] = float(s["t"]) - dt
		if float(s["t"]) <= 0.0:
			if bool(s.get("refreeze", false)):
				# La glace fondue regèle.
				s["kind"] = "glace"
				s["permanent"] = true
				s["t"] = 1e9
				s.erase("refreeze")
				i += 1
				continue
			surfaces.remove_at(i)
			continue
		_surface_tick(s, dt)
		if bool(s.get("gone", false)):
			surfaces.remove_at(i)
			continue
		i += 1
	var j := 0
	while j < walls.size():
		var w: Dictionary = walls[j]
		w["t"] = float(w["t"]) - dt
		if float(w["t"]) <= 0.0 or float(w["hp"]) <= 0.0:
			sim._event({"t": "wall_break", "id": w["id"], "pos": w["pos"], "hw": w["hw"]})
			_add_surface("gravats", w["pos"], float(w["hw"]) * 0.8, 10.0)
			walls.remove_at(j)
			continue
		j += 1
	for p in props:
		if float(p["fall_t"]) > 0.0:
			p["fall_t"] = float(p["fall_t"]) - dt
			if float(p["fall_t"]) <= 0.0:
				_pillar_crash(p)


func _surface_tick(s: Dictionary, dt: float) -> void:
	var kind := str(s["kind"])
	var info: Dictionary = KINDS[kind]
	if bool(info.get("slide", false)):
		var pos: Vector2 = s["pos"]
		var r := float(s["r"])
		for grid in [sim._grid_a, sim._grid_e]:
			for u: Unit in sim._query(grid, pos, r + 0.3):
				if u.alive and u.pos.distance_to(pos) <= r:
					u.slide_t = 0.8
		return
	if bool(info.get("ally", false)):
		# Mare de poison : ralentit et empoisonne les invocations (sauf Revenant : immunité au poison).
		if sim._mod("poison_immune") > 0.0:
			return
		var pos: Vector2 = s["pos"]
		var r := float(s["r"])
		var pdps := float(s.get("dps", 0.0))
		if pdps <= 0.0:
			pdps = 1.0 * sim.enemy_mult
		for a in sim._query(sim._grid_a, pos, r + 0.3):
			if not a.alive or a.pos.distance_to(pos) > r + a.radius * 0.5 or a.role == "escort":
				continue
			a.zone_slow = maxf(a.zone_slow, float(info.get("slow", 0.0)))
			sim._damage(a, pdps * dt, "nature")
		return
	var hits := _enemies_in(s)
	var slow := float(info.get("slow", 0.0))
	var dps := float(s.get("dps", 0.0))
	var elem := str(info.get("elem", ""))
	s["acc"] = float(s.get("acc", 0.0)) + dt
	var pulse := float(s["acc"]) >= 1.0
	if pulse:
		s["acc"] = float(s["acc"]) - 1.0
	match kind:
		"statique":
			# Décharges régulières sur 3 ennemis au plus.
			s["zap_acc"] = float(s.get("zap_acc", 0.0)) + dt
			if float(s["zap_acc"]) >= 0.8:
				s["zap_acc"] = 0.0
				var n := 0
				for e in hits:
					if n >= 3:
						break
					sim._damage(e, sim._calc(float(s.get("zap", 30.0)), "foudre", 0.0, e, false), "foudre")
					sim._event({"t": "beam", "a": (s["pos"] as Vector2) + Vector2(sim.rng.randf_range(-0.4, 0.4), 0.0), "b": e.pos, "color": "FFF6A8", "dur": 0.15, "w": 2.0})
					n += 1
			return
		"rune":
			if not hits.is_empty():
				# La rune explose au passage d'un ennemi.
				var pos: Vector2 = s["pos"]
				var r := float(s.get("blast_r", 2.0))
				for e in sim._query(sim._grid_e, pos, r + 0.3):
					if e.alive:
						sim._damage(e, sim._calc(float(s.get("blast", 120.0)), "arcane", 0.05, e, false), "arcane")
				sim._event({"t": "explosion", "pos": pos, "r": r, "color": "B07CFF", "dur": 0.7, "big": true})
				sim._event({"t": "text", "pos": pos, "text": "RUNE !", "color": "D8C0FF"})
				s["gone"] = true
			return
	for e in hits:
		if slow > 0.0 and e.role != "boss":
			e.zone_slow = maxf(e.zone_slow, slow)
		if dps > 0.0:
			sim._damage(e, sim._calc(dps, elem, 0.0, e, false) * dt, elem)
		if pulse and bool(info.get("burn", false)) and e.alive:
			sim._apply_status(e, "feu")
		if bool(info.get("expose", false)):
			e.exposed_t = 0.25


func _enemies_in(s: Dictionary) -> Array:
	var out: Array = []
	if s.has("rect"):
		var rc: Rect2 = s["rect"]
		for e in sim._query(sim._grid_e, rc.get_center(), rc.size.length() * 0.5 + 0.3):
			if e.alive and rc.grow(e.radius).has_point(e.pos):
				out.append(e)
		return out
	var pos: Vector2 = s["pos"]
	var r := float(s["r"])
	for e in sim._query(sim._grid_e, pos, r + 0.3):
		if e.alive and e.pos.distance_to(pos) <= r + e.radius * 0.5:
			out.append(e)
	return out


## Murs de pierre : l'ennemi qui descend vers la Barrière s'arrête devant et frappe le mur.
func block_y(e: Unit, ny: float) -> float:
	for w in walls:
		var wp: Vector2 = w["pos"]
		var top := wp.y + float(w["hh"])
		if absf(e.pos.x - wp.x) > float(w["hw"]) + e.radius or e.pos.y < top - 0.05:
			continue
		if ny < top + e.radius:
			w["hp"] = float(w["hp"]) - e.atk * BattleSim.TICK / maxf(0.3, e.atk_interval)
			w["flash"] = 0.08
			return maxf(ny, top + e.radius)
	return ny


# ---------------------------------------------------------------- sorts de terrain

## Sorts « wall », « quake » et « ground ». Retourne false si le sort n'a pas pu être lancé.
func cast(c: BattleSim.Caster, sp: Dictionary, at: Vector2) -> bool:
	var col := str(sp.get("color", "FFFFFF"))
	match str(sp["type"]):
		"wall":
			var y := clampf(at.y, BattleSim.BARRIER_Y + 1.4, 12.0)
			var x := clampf(at.x, 1.0, BattleSim.W - 1.0)
			var hp := float(sp.get("amount", 300)) * sim.enemy_mult * c.atk_mult
			var w := {"id": _id(), "pos": Vector2(x, y), "hw": float(sp.get("width", 2.6)) * 0.5, "hh": 0.22,
				"hp": hp, "max_hp": hp, "t": float(sp.get("dur", 10.0)), "flash": 0.0}
			walls.append(w)
			sim._event({"t": "wall", "id": w["id"], "pos": w["pos"], "hw": w["hw"], "color": col})
			sim._event({"t": "shake"})
			return true
		"quake":
			var band := float(sp.get("band", 2.0))
			var dmg := float(sp.get("damage", 60)) * c.atk_mult * sim._elem_mult(c, sp)
			var stun := float(sp.get("stun", 1.0))
			for e in sim.enemies:
				if e.alive and absf(e.pos.y - at.y) <= band:
					sim._damage(e, sim._calc(dmg, "physique", c.crit, e, false), "physique")
					if e.alive and e.role != "boss":
						e.rooted_t = maxf(e.rooted_t, stun)
			for t in sim.towers:
				if t["alive"] and absf((t["pos"] as Vector2).y - at.y) <= band + 0.5:
					t["hp"] = float(t["hp"]) - dmg
					t["flash"] = 0.1
			for p in props:
				if bool(p["alive"]) and float(p["fall_t"]) < 0.0 and absf((p["pos"] as Vector2).y - at.y) <= band + 0.6:
					_topple(p)
			for k in range(int(sp.get("cracks", 4))):
				var cp := Vector2(sim.rng.randf_range(0.8, BattleSim.W - 0.8), clampf(at.y + sim.rng.randf_range(-band, band), BattleSim.BARRIER_Y + 0.8, BattleSim.H - 0.6))
				_add_surface("fissure", cp, sim.rng.randf_range(0.7, 1.1), 12.0)
			for k in range(int(sp.get("craters", 0))):
				var cp := Vector2(sim.rng.randf_range(1.0, BattleSim.W - 1.0), sim.rng.randf_range(3.0, BattleSim.H - 2.0))
				_add_surface("cratere", cp, sim.rng.randf_range(0.8, 1.3), 0.0)
				sim._event({"t": "explosion", "pos": cp, "r": 1.4, "color": col, "dur": 0.7, "big": true})
			sim._event({"t": "quake", "pos": at, "band": minf(band, BattleSim.H), "color": col})
			sim._event({"t": "shake"})
			if band > 6.0:
				sim._event({"t": "flash"})
			return true
		"ground":
			var kind := str(sp.get("ground_kind", "braises"))
			var r := float(sp.get("radius", 2.0)) * (1.0 + sim._spell_mod(c, "radius.", sp))
			# Le sol déclenche aussi les réactions (ex. Terre brûlée sur un Marais : vapeur).
			_reactions(c, sp, at, r, float(sp.get("damage", sp.get("dps", 10))) * c.atk_mult, Rect2())
			if kind == "rune":
				var runes: Array = []
				for s in surfaces:
					if str(s["kind"]) == "rune":
						runes.append(s)
				while runes.size() >= MAX_RUNES:
					surfaces.erase(runes.pop_front())
			var s := _add_surface(kind, at, r, float(sp.get("dur", 0.0)))
			s["dps"] = float(sp.get("dps", 0.0)) * c.atk_mult * sim._elem_mult(c, sp)
			s["zap"] = float(sp.get("zap", 0.0)) * c.atk_mult
			s["blast"] = float(sp.get("blast", 0.0)) * c.atk_mult
			s["blast_r"] = float(sp.get("blast_r", 2.0))
			if kind == "rune":
				s["r"] = 0.8
			var dmg := float(sp.get("damage", 0)) * c.atk_mult * sim._elem_mult(c, sp)
			if dmg > 0.0:
				var elem := str(sp.get("element", ""))
				for e in sim._query(sim._grid_e, at, r + 0.3):
					if e.alive:
						sim._damage(e, sim._calc(dmg, elem, c.crit, e, false), elem)
			sim._event({"t": "ground", "pos": at, "r": r, "kind": kind, "color": col})
			return true
	return false


# ---------------------------------------------------------------- impacts des sorts

## Appelé à chaque impact de sort (zone, colonne, chaîne, vague, zone durable) : réactions entre
## éléments, sols laissés par le sort, dégâts aux piliers. « rect » non vide : impact en colonne.
func on_impact(c: BattleSim.Caster, sp: Dictionary, at: Vector2, r: float, dmg: float, rect: Rect2 = Rect2()) -> void:
	if str(sp.get("element", "")) == "feu" and not sim.stumps.is_empty():
		if rect.size != Vector2.ZERO:
			for st in sim.stumps:
				if rect.grow(0.6).has_point(st["pos"]):
					st["t"] = -99.0
		else:
			sim.burn_stumps(at, r)
	_reactions(c, sp, at, r, dmg, rect)
	_leave_ground(c, sp, at, r, dmg, rect)
	for p in props:
		if not bool(p["alive"]) or float(p["fall_t"]) >= 0.0:
			continue
		var pp: Vector2 = p["pos"]
		var hit := rect.grow(0.6).has_point(pp) if rect.size != Vector2.ZERO else pp.distance_to(at) <= r + 0.6
		if hit:
			p["hp"] = float(p["hp"]) - dmg
			sim._event({"t": "prop_hit", "id": p["id"]})
			if float(p["hp"]) <= 0.0:
				_topple(p)


func _overlaps(s: Dictionary, at: Vector2, r: float, rect: Rect2) -> bool:
	if s.has("rect"):
		var sr: Rect2 = s["rect"]
		return sr.grow(r).has_point(at) if rect.size == Vector2.ZERO else sr.intersects(rect)
	var sp: Vector2 = s["pos"]
	if rect.size != Vector2.ZERO:
		return rect.grow(float(s["r"])).has_point(sp)
	return sp.distance_to(at) <= r + float(s["r"])


func _reactions(c: BattleSim.Caster, sp: Dictionary, at: Vector2, r: float, dmg: float, rect: Rect2) -> void:
	var elem := str(sp.get("element", ""))
	var label := ""
	var i := 0
	while i < surfaces.size():
		var s: Dictionary = surfaces[i]
		var kind := str(s["kind"])
		if not _overlaps(s, at, r, rect):
			i += 1
			continue
		var removed := false
		if elem == "feu" and kind == "poison":
			# Explosion toxique : le feu enflamme les vapeurs de la mare.
			var pp: Vector2 = s["pos"]
			for e in sim._query(sim._grid_e, pp, float(s["r"]) + 1.0):
				if e.alive and e.pos.distance_to(pp) <= float(s["r"]) + 1.0:
					sim._damage(e, sim._calc(dmg * 0.6, "feu", 0.0, e, false), "feu")
			sim._event({"t": "explosion", "pos": pp, "r": float(s["r"]) + 1.0, "color": "9AD03A", "dur": 0.6})
			label = "EXPLOSION TOXIQUE !"
			surfaces.remove_at(i)
			removed = true
		elif elem == "givre" and kind == "poison":
			s["kind"] = "verglas"
			s["permanent"] = false
			s["t"] = 8.0
			label = "GEL !"
		elif elem == "feu" and kind == "glace":
			# Le feu fait fondre la glace : de l'eau pendant 12 s, puis elle regèle.
			sim._event({"t": "steam", "pos": s["pos"], "r": float(s["r"])})
			s["kind"] = "eau"
			s["permanent"] = false
			s["t"] = 12.0
			s["refreeze"] = true
			label = "DÉGEL !"
		elif (elem == "feu" and kind in ["verglas", "eau"] and not bool(s.get("refreeze", false))) or (elem == "givre" and kind == "braises"):
			# Vapeur : le feu et la glace s'annulent dans une explosion de vapeur brûlante.
			for e in _enemies_in(s):
				sim._damage(e, sim._calc(dmg * 0.5, "physique", 0.0, e, false), "physique")
			sim._event({"t": "steam", "pos": s["pos"], "r": float(s["r"])})
			label = "VAPEUR !"
			surfaces.remove_at(i)
			removed = true
		elif elem == "givre" and kind == "eau":
			s["kind"] = "verglas"
			s["t"] = maxf(float(s["t"]), 8.0)
			for e in _enemies_in(s):
				if e.role != "boss":
					e.frozen_t = maxf(e.frozen_t, 1.5)
			label = "GEL !"
		elif elem == "foudre" and bool(KINDS[kind].get("conduct", false)):
			# Électrocution : la foudre court dans l'eau, la glace et le champ statique.
			var pts: Array = [s["pos"]]
			for e in _enemies_in(s):
				sim._damage(e, sim._calc(dmg * 0.6, "foudre", 0.0, e, false), "foudre")
				if pts.size() < 9:
					pts.append(e.pos)
			if pts.size() > 1:
				sim._event({"t": "lightning", "pts": pts, "dur": 0.4, "color": "FFF6A8"})
			label = "ÉLECTROCUTION !"
		elif elem == "arcane" and not kind in ["cratere", "gravats", "fissure", "rune", "poison"]:
			for e in _enemies_in(s):
				sim._damage(e, sim._calc(dmg * 0.4, "arcane", 0.0, e, false), "arcane")
			s["t"] = float(s["t"]) + 2.0
			sim._event({"t": "ring", "pos": s["pos"], "r": float(s["r"]), "color": "D8C0FF", "dur": 0.5})
			label = "RÉSONANCE !"
		if not removed:
			i += 1
	if elem == "feu":
		# Incendie : le feu embrase les zones de Nature (Racines, Ronces, Étreinte…).
		for z in sim.zones:
			if str(z["elem"]) != "nature":
				continue
			var zp: Vector2 = z["pos"]
			var near := rect.grow(float(z["r"])).has_point(zp) if rect.size != Vector2.ZERO else zp.distance_to(at) <= r + float(z["r"])
			if not near:
				continue
			z["elem"] = "feu"
			z["dps"] = float(z["dps"]) * 2.0 + dmg * 0.1
			z["slow"] = 0.0
			var b := _add_surface("braises", zp, float(z["r"]) * 1.1, maxf(float(z["t"]), 4.0) + 2.0)
			b["dps"] = dmg * 0.12
			label = "INCENDIE !"
	if label != "":
		reactions += 1
		sim._event({"t": "text", "pos": at + Vector2(0.0, 0.6), "text": label, "color": "FFF0C0"})
		sim._log("Réaction : %s" % label.trim_suffix(" !").capitalize())


## Sols laissés par les sorts : explicites (« ground ») ou selon l'élément et la taille de l'impact.
func _leave_ground(c: BattleSim.Caster, sp: Dictionary, at: Vector2, r: float, dmg: float, rect: Rect2) -> void:
	if str(sp.get("type", "")) == "ground":
		return
	var g: Variant = sp.get("ground", null)
	if g is Dictionary:
		var gd: Dictionary = g
		var s := _add_surface(str(gd.get("kind", "braises")), at, r * float(gd.get("r", 1.0)), float(gd.get("dur", 0.0)), rect if bool(gd.get("along", false)) else Rect2())
		s["dps"] = dmg * float(gd.get("dps", 0.0))
		return
	if g is String and str(g) == "none":
		return
	var elem := str(sp.get("element", ""))
	var t := str(sp.get("type", ""))
	if rect.size != Vector2.ZERO or c.idx != 0:
		return
	if t == "aoe":
		if sp.has("delay") and float(sp.get("damage", 0)) >= 100.0 or bool(sp.get("crater", false)):
			_add_surface("cratere", at, r * 0.5, 0.0)
		match elem:
			"feu":
				var s := _add_surface("braises", at, r * 0.7, 4.0)
				s["dps"] = dmg * 0.1
			"givre":
				_add_surface("verglas", at, r * 0.8, 6.0)
			"ombre":
				_add_surface("miasme", at, r * 0.7, 5.0)
	elif t == "zone" and elem == "givre":
		_add_surface("verglas", at, r, float(sp.get("dur", 3.0)) + 3.0)


## Mare de poison (marais, mort d'un Rat de peste, venin et inondation de l'Hydre).
## Plaque de glace permanente (zone 4).
func add_ice(pos: Vector2, r: float) -> void:
	_add_surface("glace", pos, r, 0.0)


func add_poison(pos: Vector2, r: float, dur: float, permanent: bool) -> void:
	var s := _add_surface("poison", pos, r, dur)
	if permanent:
		s["permanent"] = true
		s["t"] = 1e9


## Purifier assainit les mares de poison. Retourne vrai si une mare a été touchée.
func cleanse(at: Vector2, r: float) -> bool:
	var hit := false
	var i := 0
	while i < surfaces.size():
		var s: Dictionary = surfaces[i]
		if str(s["kind"]) in ["poison", "miasme"] and (s["pos"] as Vector2).distance_to(at) <= r + float(s["r"]):
			surfaces.remove_at(i)
			hit = true
			continue
		i += 1
	if hit:
		sim._event({"t": "text", "pos": at, "text": "ASSAINI", "color": "FFF6C8"})
	return hit


func _add_surface(kind: String, pos: Vector2, r: float, dur: float, rect: Rect2 = Rect2()) -> Dictionary:
	var info: Dictionary = KINDS[kind]
	var permanent := bool(info.get("permanent", false))
	if dur <= 0.0:
		dur = float(info.get("dur", 6.0))
	# Même sol tout proche : on le ravive au lieu d'en empiler un autre.
	if rect.size == Vector2.ZERO:
		for s in surfaces:
			if str(s["kind"]) == kind and not s.has("rect") and (s["pos"] as Vector2).distance_to(pos) < 0.6:
				s["r"] = maxf(float(s["r"]), r)
				s["t"] = maxf(float(s["t"]), dur)
				return s
	var s := {"id": _id(), "kind": kind, "pos": pos, "r": r, "t": 1e9 if permanent else dur, "dur": dur, "permanent": permanent, "acc": 0.0}
	if rect.size != Vector2.ZERO:
		s["rect"] = rect
		s["pos"] = rect.get_center()
		s["r"] = maxf(rect.size.x, rect.size.y) * 0.5
	surfaces.append(s)
	if kind == "cratere":
		var craters: Array = []
		for o in surfaces:
			if str(o["kind"]) == "cratere":
				craters.append(o)
		if craters.size() > MAX_CRATERS:
			surfaces.erase(craters[0])
	while surfaces.size() > MAX_SURFACES:
		var dropped := false
		for o in surfaces:
			if not bool(o["permanent"]):
				surfaces.erase(o)
				dropped = true
				break
		if not dropped:
			break
	return s


# ---------------------------------------------------------------- piliers

## Le pilier bascule vers la chaussée ; il écrase les ennemis en tombant (0,5 s plus tard).
func _topple(p: Dictionary) -> void:
	p["alive"] = false
	p["fall_t"] = 0.5
	sim._event({"t": "prop_fall", "id": p["id"], "dur": 0.5})
	sim._log("Un pilier s'effondre !")


func _pillar_crash(p: Dictionary) -> void:
	var base: Vector2 = p["pos"]
	var side := float(p["side"])
	var length := float(p["h"]) * 1.4 + 0.6
	var x0 := base.x
	var x1 := base.x - side * length
	var rc := Rect2(Vector2(minf(x0, x1), base.y - 0.55), Vector2(absf(x1 - x0), 1.1))
	var dmg := (60.0 + 50.0 * float(p["h"])) * sim.enemy_mult
	var n := 0
	for e in sim._query(sim._grid_e, rc.get_center(), length * 0.5 + 0.8):
		if e.alive and rc.grow(e.radius).has_point(e.pos):
			sim._damage(e, sim._calc(dmg, "physique", 0.0, e, false), "physique")
			if e.alive and e.role != "boss":
				e.rooted_t = maxf(e.rooted_t, 1.0)
			n += 1
	var inside := Rect2(Vector2(maxf(0.1, rc.position.x), rc.position.y), Vector2(minf(BattleSim.W - 0.1, rc.end.x) - maxf(0.1, rc.position.x), rc.size.y))
	if inside.size.x > 0.2:
		_add_surface("gravats", Vector2.ZERO, 0.0, 25.0, inside)
	sim._event({"t": "prop_crash", "id": p["id"], "pos": base, "rect": rc})
	sim._event({"t": "shake"})
	if n > 0:
		sim._event({"t": "text", "pos": rc.get_center() + Vector2(0.0, 0.5), "text": "ÉCRASÉS ×%d" % n, "color": "E8DCC0"})
