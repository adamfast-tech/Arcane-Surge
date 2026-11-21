class_name BattleSim
extends RefCounted
## Simulation du combat (docs/design/03-combat.md) : logique pure, sans nœud,
## pas fixe de 30 Hz, déterministe pour une graine donnée. Utilisée par l'écran
## de combat et par le simulateur sans affichage (tools/sim_cli.gd).

const W := 9.0
const H := 16.0
const TICK := 1.0 / 30.0
const BARRIER_Y := 1.0
const CASTER_Y := 0.35
const NEXUS_POS := Vector2(4.5, 15.0)
const NEXUS_R := 0.8
const HOMING_Y := 13.0
const MAX_ALLIES := 300
const MAX_ENEMIES := 200
const GRID_W := 10
const GRID_H := 17
const BEATS := {"feu": "nature", "nature": "foudre", "foudre": "givre", "givre": "feu"}
const ORDERS := ["focus_nexus", "defends", "suis_moi", "libre"]
const ORDER_LABELS := {"focus_nexus": "Focus Nexus", "defends": "Défends", "suis_moi": "Suis-moi", "libre": "Libre"}
const NEXUS_PULSE_INTERVAL := 2.5
const NEXUS_PULSE_RANGE := 1.7
const NEXUS_PULSE_DMG := 25.0
const SURGE_PER_KILL := 0.5
const SURGE_PER_BIG := 3.0


class Caster:
	var idx := 0
	var name := ""
	var class_id := ""
	var race_id := ""
	var level := 1
	var sprite := "mage"
	var side := "center"
	var is_bot := false
	var stats: Dictionary = {}
	var x := 4.5
	var prev_x := 4.5
	var target_x := 4.5
	var min_x := 0.5
	var max_x := 8.5
	var move_speed := 9.0
	var firing := false
	var fire_acc := 0.0
	var cadence := 4.0
	var familiar := "familiar_mage"
	var element := "physique"
	var atk_mult := 1.0
	var hp_mult := 1.0
	var crit := 0.05
	var mana := 50.0
	var mana_max := 100.0
	var mana_regen := 4.0
	var spells: Array[String] = []
	var spell_cd: Dictionary = {}
	var order := "libre"
	var personality := "equilibre"
	var think_interval := 0.4
	var aim_error := 0.4
	var brain: BotBrain = null


var rng := RandomNumberGenerator.new()
var level: Dictionary = {}
var units_db: Dictionary = {}
var spells_db: Dictionary = {}
var echoes_db: Array = []

var allies: Array[Unit] = []
var enemies: Array[Unit] = []
var portals: Array[Portal] = []
var towers: Array[Dictionary] = []
var casters: Array[Caster] = []
var spawn_queue: Array[Dictionary] = []
var events: Array[Dictionary] = []
var log_lines: Array[String] = []

var time := 0.0
var state := "running" ## running, echo, victory, defeat
var autoplay := false
var solo := false
var next_id := 1
var enemy_mult := 1.0

var nexus_hp := 1000.0
var nexus_max := 1000.0
var nexus_wither_t := 0.0
var nexus_flash := 0.0
var barrier_hp := 100.0
var barrier_max := 100.0
var barrier_shield := 0.0
var barrier_flash := 0.0
var surge := 0.0
var champion_charge := 0
var champion_need := 40
var champion_double := false
var champion_kind := "champion_golem"
var ultimate_id := "meteore"
var last_elem := "physique"
var effect_mult := 1.0
var seals_total := 0

var extra_number := 0
var cadence_mult := 1.0
var spell_cost_mult := 1.0
var barrier_cost_per_spell := 0.0
var fire_explode := false
var echoes_taken: Array[String] = []
var echo_thresholds: Array[float] = [0.66, 0.33]
var pending_echoes: Array[String] = []
var _echo_done: Array[bool] = [false, false]

var wave_t := 0.0
var wave_index := 0
var kills := 0
var summoned := 0
var fusions := 0
var healed_total := 0.0
var par_time := 150.0
var stars := 0
var peak_allies := 0

var _grid_e: Array = []
var _grid_a: Array = []
var _pending_allies: Array[Unit] = []
var _pending_enemies: Array[Unit] = []
var _fusion_count := 0
var _fusion_atk := 0.0
var _fusion_hp := 0.0
var _nexus_dmg_acc := 0.0
var _nexus_dmg_t := 0.0
var _heal_log_t := 0.0
var _shield_fx_t := 0.0
var _pulse_t := NEXUS_PULSE_INTERVAL


# ---------------------------------------------------------------- mise en place

func setup(level_data: Dictionary, party: Dictionary, seed_value: int, opts: Dictionary = {}) -> void:
	level = level_data
	units_db = GameData.units()
	spells_db = GameData.spells()
	echoes_db = GameData.echoes()
	rng.seed = seed_value
	autoplay = bool(opts.get("autoplay", false))
	solo = bool(opts.get("solo", false)) or bool(level.get("solo", false))
	enemy_mult = pow(1.045, float(level.get("global_level", 1)) - 1.0)
	nexus_max = float(level["nexus"]["hp"])
	nexus_hp = nexus_max
	par_time = float(level.get("par_time", 150))
	for i in range(GRID_W * GRID_H):
		_grid_e.append([])
		_grid_a.append([])
	_setup_portals()
	_setup_towers()
	_setup_casters(party)
	for e in level.get("initial_enemies", []):
		_spawn_enemy(str(e["kind"]), Vector2(float(e["x"]), float(e["y"])))
	wave_t = float(level["waves"].get("first", 3.0))
	_flush()
	_log("%s %s : %s" % [str(level.get("number", "")), str(level.get("name", "")), str(level.get("type", ""))])


func _setup_portals() -> void:
	var pid := 0
	for pd in level.get("portals", []):
		var p := Portal.new()
		pid += 1
		p.id = pid
		p.kind = str(pd["kind"])
		p.value = int(pd.get("value", 0))
		p.element = str(pd.get("element", ""))
		p.x = float(pd["x"])
		p.base_x = p.x
		p.y = float(pd["y"])
		p.width = float(pd.get("width", 2.0))
		p.motion = str(pd.get("motion", "none"))
		p.motion_range = float(pd.get("range", 0.0))
		p.motion_speed = float(pd.get("speed", 0.5))
		p.phase = float(pd.get("phase", 0.0))
		p.is_seal = bool(pd.get("seal", false))
		p.purity_needed = int(pd.get("purity", 10))
		p.charges = p.value
		portals.append(p)
		if p.is_seal:
			seals_total += 1
	portals.sort_custom(func(a: Portal, b: Portal) -> bool: return a.y < b.y)


func _setup_towers() -> void:
	for td in level.get("towers", []):
		var hp := float(td.get("hp", 300)) * enemy_mult
		towers.append({
			"pos": Vector2(float(td["x"]), float(td["y"])), "hp": hp, "max": hp,
			"atk": float(td.get("atk", 12)) * enemy_mult, "range": float(td.get("range", 3.0)),
			"interval": float(td.get("interval", 1.0)), "cd": 1.0, "r": 0.45, "alive": true, "flash": 0.0,
		})


func _setup_casters(party: Dictionary) -> void:
	var classes: Dictionary = party["classes"]
	var races: Dictionary = party["races"]
	var pd: Dictionary = party["player"]
	var pc := _make_caster(0, pd, classes, races)
	pc.min_x = 0.5
	pc.max_x = W - 0.5
	pc.x = W * 0.5
	pc.prev_x = pc.x
	pc.target_x = pc.x
	for s in pd["deck"]:
		pc.spells.append(str(s))
	var cls: Dictionary = classes[pc.class_id]
	effect_mult = float(cls.get("effect_mult", 1.0))
	champion_kind = str(cls.get("champion", "champion_golem"))
	ultimate_id = str(cls.get("ultimate", "meteore"))
	barrier_max = roundf(100.0 + float(pc.stats["vig"]) * 0.5)
	barrier_hp = barrier_max
	if autoplay:
		pc.brain = BotBrain.new()
		pc.think_interval = 0.35
		pc.aim_error = 0.3
	casters.append(pc)
	if solo:
		return
	for bd in party["bots"]:
		var c := _make_caster(casters.size(), bd, classes, races)
		c.is_bot = true
		c.side = str(bd.get("side", "left"))
		if c.side == "left":
			c.min_x = 0.5
			c.max_x = 4.6
			c.x = 2.0
		else:
			c.min_x = 4.4
			c.max_x = W - 0.5
			c.x = 7.0
		c.prev_x = c.x
		c.target_x = c.x
		c.move_speed = 4.0
		c.personality = str(bd.get("personality", "equilibre"))
		c.order = str(bd.get("order", "libre"))
		c.think_interval = float(bd.get("think", 0.4))
		c.aim_error = float(bd.get("aim_error", 0.4))
		c.cadence *= float(bd.get("cadence_mult", 1.0))
		for s in bd.get("spells", []):
			c.spells.append(str(s))
		c.brain = BotBrain.new()
		c.firing = true
		casters.append(c)


func _make_caster(idx: int, d: Dictionary, classes: Dictionary, races: Dictionary) -> Caster:
	var c := Caster.new()
	c.idx = idx
	c.name = str(d["name"])
	c.class_id = str(d["class"])
	c.race_id = str(d["race"])
	c.level = int(d.get("level", 1))
	c.sprite = str(d.get("sprite", "mage"))
	var cls: Dictionary = classes[c.class_id]
	var race: Dictionary = races.get(c.race_id, {})
	var base: Dictionary = cls["base"]
	for k in ["pou", "vig", "esp", "cel", "des"]:
		var b := float(base.get(k, 0))
		c.stats[k] = b + b / 10.0 * float(c.level - 1) + float(race.get(k, 0))
	c.familiar = str(cls.get("familiar", "familiar_mage"))
	c.atk_mult = 1.0 + float(c.stats["pou"]) / 100.0
	c.hp_mult = 1.0 + float(c.stats["vig"]) / 100.0
	c.mana_max = 100.0 + float(c.stats["esp"])
	c.mana = c.mana_max * 0.5
	c.mana_regen = 4.0 + float(c.stats["esp"]) * 0.05
	c.cadence = 4.0 * (1.0 + float(c.stats["cel"]) * 0.005)
	c.crit = 0.05 + float(c.stats["des"]) * 0.001 + float(race.get("crit", 0.0))
	c.element = str(d.get("weapon_element", "physique"))
	return c


# ---------------------------------------------------------------- boucle

func step() -> void:
	if state != "running":
		return
	time += TICK
	_update_casters()
	_update_portals()
	_update_waves()
	_move_units()
	_cross_portals()
	_tick_status()
	_build_grids()
	_resolve_contacts()
	_ranged_attacks()
	_towers_attack()
	_enemy_abilities()
	_nexus_pulse()
	_reach_checks()
	_flush()
	peak_allies = maxi(peak_allies, allies.size())
	_check_end()


func _update_casters() -> void:
	for c in casters:
		c.prev_x = c.x
		if c.brain != null:
			c.brain.update(self, c, TICK)
		var mv := c.move_speed * TICK
		c.x = clampf(c.x + clampf(c.target_x - c.x, -mv, mv), c.min_x, c.max_x)
		c.mana = minf(c.mana_max, c.mana + c.mana_regen * TICK)
		for k in c.spell_cd.keys():
			c.spell_cd[k] = maxf(0.0, float(c.spell_cd[k]) - TICK)
		if not c.firing:
			c.fire_acc = minf(c.fire_acc, 0.99)
			continue
		c.fire_acc += TICK * c.cadence * cadence_mult
		while c.fire_acc >= 1.0:
			c.fire_acc -= 1.0
			var u := _spawn_familiar(c, Vector2(c.x + rng.randf_range(-0.12, 0.12), CASTER_Y + 0.45))
			if u != null and c.idx == 0:
				champion_charge = mini(champion_need, champion_charge + 1)


func _update_portals() -> void:
	for p in portals:
		if p.motion == "slide":
			p.phase += TICK * p.motion_speed
			p.x = clampf(p.base_x + sin(p.phase) * p.motion_range, p.width * 0.5, W - p.width * 0.5)
		if p.flash_t > 0.0:
			p.flash_t -= TICK
		if p.kind == "add" and not p.ready:
			p.recharge_t += TICK
			if p.recharge_t >= Portal.ADD_RECHARGE:
				p.recharge_t = 0.0
				p.ready = true
		elif p.kind == "sub" and p.charges <= 0:
			p.recharge_t += TICK
			if p.recharge_t >= Portal.SUB_RECHARGE:
				p.recharge_t = 0.0
				p.charges = p.value


func _update_waves() -> void:
	wave_t -= TICK
	if wave_t <= 0.0:
		_queue_wave()
		var iv: Array = level["waves"].get("interval", [8, 12])
		wave_t = rng.randf_range(float(iv[0]), float(iv[1]))
	var i := 0
	while i < spawn_queue.size():
		var s: Dictionary = spawn_queue[i]
		s["t"] = float(s["t"]) - TICK
		if float(s["t"]) <= 0.0:
			if enemies.size() + _pending_enemies.size() < MAX_ENEMIES:
				_spawn_enemy(str(s["kind"]), Vector2(float(s["x"]), float(s["y"])))
			spawn_queue.remove_at(i)
		else:
			i += 1


func _queue_wave() -> void:
	var wd: Dictionary = level["waves"]
	var budget := (float(wd.get("budget_base", 20)) + float(wd.get("budget_per_level", 6)) * float(wd.get("local_level", 1))) \
		* (1.0 + float(wd.get("growth", 0.04)) * float(wave_index))
	var pool: Dictionary = wd["pool"]
	var kinds: Array = pool.keys()
	var total_w := 0.0
	var min_cost := 999.0
	for k in kinds:
		total_w += float(pool[k])
		min_cost = minf(min_cost, float(units_db[str(k)].get("cost", 1)))
	var clusters: Array[float] = []
	for c in range(rng.randi_range(2, 3)):
		clusters.append(rng.randf_range(1.0, W - 1.0))
	var n := 0
	var guard := 0
	var spawn_y := float(wd.get("spawn_y", 14.6))
	while budget >= min_cost and guard < 500:
		guard += 1
		var r := rng.randf() * total_w
		var pick := str(kinds[0])
		for k in kinds:
			r -= float(pool[k])
			if r <= 0.0:
				pick = str(k)
				break
		var cost := float(units_db[pick].get("cost", 1))
		if cost > budget:
			continue
		var cap := int(units_db[pick].get("max_alive", 0))
		if cap > 0 and _count_kind(pick) >= cap:
			pick = "mushroom" if units_db.has("mushroom") else pick
			cost = float(units_db[pick].get("cost", 1))
		budget -= cost
		var cx: float = clusters[n % clusters.size()]
		spawn_queue.append({
			"t": float(n) * 0.12 + rng.randf() * 0.2, "kind": pick,
			"x": clampf(cx + rng.randf_range(-0.7, 0.7), 0.4, W - 0.4),
			"y": spawn_y + rng.randf_range(-0.2, 0.3),
		})
		n += 1
	wave_index += 1


func _count_kind(kind: String) -> int:
	var n := 0
	for e in enemies:
		if e.alive and e.kind == kind:
			n += 1
	for e in _pending_enemies:
		if e.kind == kind:
			n += 1
	for s in spawn_queue:
		if str(s["kind"]) == kind:
			n += 1
	return n


func _move_units() -> void:
	for u in allies:
		u.prev_pos = u.pos
		if not u.alive:
			continue
		u.anim += TICK
		if u.engaged:
			continue
		var sf := u.speed_factor()
		if sf <= 0.0:
			continue
		if u.pos.y > HOMING_Y:
			u.vx = clampf((_homing_target_x(u) - u.pos.x) * 1.5, -1.8, 1.8)
		u.pos.x = clampf(u.pos.x + u.vx * sf * TICK, 0.2, W - 0.2)
		u.pos.y = minf(H - 0.2, u.pos.y + u.speed * sf * TICK)
	for e in enemies:
		e.prev_pos = e.pos
		if not e.alive:
			continue
		e.anim += TICK
		if e.engaged:
			continue
		if e.hold_y > 0.0 and e.pos.y <= e.hold_y:
			continue
		e.pos.y -= e.speed * e.speed_factor() * TICK


func _homing_target_x(u: Unit) -> float:
	for t in towers:
		if t["alive"] and absf(u.pos.x - (t["pos"] as Vector2).x) < 1.3:
			return (t["pos"] as Vector2).x
	return NEXUS_POS.x


# ---------------------------------------------------------------- portails

func _cross_portals() -> void:
	for u in allies:
		if not u.alive:
			continue
		for p in portals:
			if u.prev_pos.y < p.y and u.pos.y >= p.y and absf(u.pos.x - p.x) <= p.width * 0.5 and not u.crossed.has(p.id):
				u.crossed[p.id] = true
				_apply_portal(p, u)
				if not u.alive:
					break


func _apply_portal(p: Portal, u: Unit) -> void:
	p.flash_t = 0.2
	if p.is_negative() and u.element == "lumiere":
		# La Lumière ignore les portails négatifs et affaiblit les sceaux.
		if p.is_seal and not p.purified:
			p.purity += 1
			if p.purity >= p.purity_needed:
				_purify(p)
		return
	match p.kind:
		"add":
			if p.ready:
				p.ready = false
				p.recharge_t = 0.0
				for i in range(p.value + extra_number):
					_add_ally(_clone(u, Vector2(rng.randf_range(-0.4, 0.4), -0.12 - 0.1 * float(i % 4))))
				_event({"t": "text", "pos": Vector2(p.x, p.y + 0.5), "text": "+%d" % (p.value + extra_number), "color": "4FE3D2"})
		"mult":
			for i in range(p.value - 1 + extra_number):
				_add_ally(_clone(u, Vector2(rng.randf_range(-0.3, 0.3), -0.08)))
		"elem":
			u.element = p.element
			if u.owner_idx == 0:
				last_elem = p.element
		"power":
			u.atk *= 1.5
		"giant":
			u.hp *= 2.0
			u.max_hp *= 2.0
			u.radius *= 1.3
			u.speed *= 0.8
		"haste":
			u.speed *= 1.4
		"aegis":
			u.shield += 10.0
		"sub":
			if p.charges > 0:
				p.charges -= 1
				p.recharge_t = 0.0
				u.alive = false
				_event({"t": "puff", "pos": u.pos, "color": "D93CF2"})
		"div":
			p.counter += 1
			if p.counter % maxi(2, p.value) == 0:
				u.alive = false
				_event({"t": "puff", "pos": u.pos, "color": "D93CF2"})
		"corrupt":
			p.counter += 1
			if p.counter % 5 == 0:
				u.alive = false
				_spawn_enemy(str(level.get("corrupt_spawn", "mushroom")), u.pos + Vector2(0.0, 0.3))
				_event({"t": "puff", "pos": u.pos, "color": "D93CF2"})
		"entrave":
			u.slow_stacks = 2
			u.slow_t = 3.0


func _purify(p: Portal) -> bool:
	if not p.purify():
		return false
	_event({"t": "ring", "pos": Vector2(p.x, p.y), "r": 1.5, "color": "FFF6C8", "dur": 0.7})
	_log("Portail purifié")
	if p.is_seal and not nexus_shielded():
		_log("Sceaux brisés : le Nexus est vulnérable !")
		_event({"t": "ring", "pos": NEXUS_POS, "r": 2.0, "color": "FFF6C8", "dur": 0.9})
	return true


func nexus_shielded() -> bool:
	for p in portals:
		if p.is_seal and not p.purified:
			return true
	return false


func seals_purified() -> int:
	var n := 0
	for p in portals:
		if p.is_seal and p.purified:
			n += 1
	return n


# ---------------------------------------------------------------- unités

func _make_unit(kind: String, team: int, p: Vector2) -> Unit:
	var d: Dictionary = units_db[kind]
	var u := Unit.new()
	u.id = next_id
	next_id += 1
	u.team = team
	u.kind = kind
	u.role = str(d.get("role", "sbire"))
	u.sprite = str(d.get("sprite", kind))
	u.pos = p
	u.prev_pos = p
	var m := enemy_mult if team == 1 else 1.0
	u.hp = float(d.get("hp", 10)) * m
	u.max_hp = u.hp
	u.atk = float(d.get("atk", 10)) * m
	u.defense = float(d.get("def", 0))
	u.speed = float(d.get("speed", 2.0))
	u.radius = float(d.get("radius", 0.22))
	u.weight = float(d.get("weight", 1))
	u.element = str(d.get("element", "physique"))
	u.atk_interval = float(d.get("atk_interval", 0.5))
	u.attack_range = float(d.get("range", 0.0))
	u.front_block = float(d.get("front_block", 0.0))
	u.cast_interval = float(d.get("cast_interval", 0.0))
	u.cast_cd = u.cast_interval * rng.randf_range(0.3, 1.0)
	u.siege = bool(d.get("siege", false))
	u.hold_y = float(d.get("hold_y", -1.0))
	u.elite = u.role == "elite"
	u.anim = rng.randf() * 10.0
	return u


func _spawn_familiar(c: Caster, p: Vector2) -> Unit:
	var u := _make_unit(c.familiar, 0, p)
	u.owner_idx = c.idx
	u.atk *= c.atk_mult
	u.hp *= c.hp_mult
	u.max_hp = u.hp
	u.crit = c.crit
	if u.element == "physique":
		u.element = c.element
	summoned += 1
	_add_ally(u)
	return u


func _clone(u: Unit, off: Vector2) -> Unit:
	var c := Unit.new()
	c.id = next_id
	next_id += 1
	c.team = 0
	c.kind = u.kind
	c.role = u.role
	c.sprite = u.sprite
	c.pos = Vector2(clampf(u.pos.x + off.x, 0.2, W - 0.2), u.pos.y + off.y)
	c.prev_pos = c.pos
	c.vx = u.vx
	c.speed = u.speed
	c.hp = u.max_hp
	c.max_hp = u.max_hp
	c.atk = u.atk
	c.defense = u.defense
	c.radius = u.radius
	c.weight = u.weight
	c.element = u.element
	c.atk_interval = u.atk_interval
	c.attack_range = u.attack_range
	c.crit = u.crit
	c.siege = u.siege
	c.elite = u.elite
	c.owner_idx = u.owner_idx
	c.shield = u.shield
	c.crossed = u.crossed.duplicate()
	c.anim = rng.randf() * 10.0
	summoned += 1
	return c


## Ajoute une invocation. Au-delà du plafond, 10 familiers fusionnent en 1 élite (Fusion arcanique).
func _add_ally(u: Unit) -> void:
	if allies.size() + _pending_allies.size() >= MAX_ALLIES and u.role == "familier":
		_fusion_count += 1
		_fusion_atk += u.atk
		_fusion_hp += u.max_hp
		if _fusion_count >= 10:
			var e := _make_unit("elite_fusion", 0, u.pos)
			e.atk = _fusion_atk
			e.hp = _fusion_hp
			e.max_hp = _fusion_hp
			e.element = u.element
			e.owner_idx = u.owner_idx
			e.crit = u.crit
			e.crossed = u.crossed.duplicate()
			_pending_allies.append(e)
			_fusion_count = 0
			_fusion_atk = 0.0
			_fusion_hp = 0.0
			fusions += 1
			_event({"t": "ring", "pos": u.pos, "r": 0.8, "color": "4FE3D2", "dur": 0.5})
		return
	_pending_allies.append(u)


func _spawn_enemy(kind: String, p: Vector2) -> Unit:
	var u := _make_unit(kind, 1, p)
	_pending_enemies.append(u)
	return u


# ---------------------------------------------------------------- combat

func _tick_status() -> void:
	for u in enemies:
		if not u.alive:
			continue
		u.atk_cd -= TICK
		u.cast_cd -= TICK
		if u.flash_t > 0.0:
			u.flash_t -= TICK
		if u.burn_t > 0.0:
			u.burn_t -= TICK
			_damage(u, u.burn_dps * TICK, "feu")
			if u.burn_t <= 0.0:
				u.burn_dps = 0.0
		if u.poison_t > 0.0 and u.alive:
			u.poison_t -= TICK
			_damage(u, u.poison_unit * float(u.poison_stacks) * TICK, "nature")
			if u.poison_t <= 0.0:
				u.poison_stacks = 0
		if u.slow_t > 0.0:
			u.slow_t -= TICK
			if u.slow_t <= 0.0:
				u.slow_stacks = 0
		u.frozen_t = maxf(0.0, u.frozen_t - TICK)
		u.rooted_t = maxf(0.0, u.rooted_t - TICK)
		u.wither_t = maxf(0.0, u.wither_t - TICK)
	for u in allies:
		if not u.alive:
			continue
		u.atk_cd -= TICK
		if u.flash_t > 0.0:
			u.flash_t -= TICK
		if u.slow_t > 0.0:
			u.slow_t -= TICK
			if u.slow_t <= 0.0:
				u.slow_stacks = 0
	nexus_wither_t = maxf(0.0, nexus_wither_t - TICK)
	nexus_flash = maxf(0.0, nexus_flash - TICK)
	barrier_flash = maxf(0.0, barrier_flash - TICK)
	_heal_log_t = maxf(0.0, _heal_log_t - TICK)
	_shield_fx_t = maxf(0.0, _shield_fx_t - TICK)
	for t in towers:
		t["flash"] = maxf(0.0, float(t["flash"]) - TICK)


func _build_grids() -> void:
	for cell in _grid_e:
		cell.clear()
	for cell in _grid_a:
		cell.clear()
	for e in enemies:
		if e.alive:
			_grid_e[_cell(e.pos)].append(e)
	for a in allies:
		if a.alive:
			_grid_a[_cell(a.pos)].append(a)


func _cell(p: Vector2) -> int:
	return clampi(int(p.y), 0, GRID_H - 1) * GRID_W + clampi(int(p.x), 0, GRID_W - 1)


func _query(grid: Array, p: Vector2, r: float) -> Array:
	var out: Array = []
	var x0 := maxi(0, int(floor(p.x - r)))
	var x1 := mini(GRID_W - 1, int(floor(p.x + r)))
	var y0 := maxi(0, int(floor(p.y - r)))
	var y1 := mini(GRID_H - 1, int(floor(p.y + r)))
	var r2 := r * r
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			for u in grid[cy * GRID_W + cx]:
				if u.alive and u.pos.distance_squared_to(p) <= r2:
					out.append(u)
	return out


func _nearest(grid: Array, p: Vector2, r: float) -> Unit:
	var best: Unit = null
	var bd := r * r
	for u in _query(grid, p, r):
		var d: float = u.pos.distance_squared_to(p)
		if d <= bd:
			bd = d
			best = u
	return best


func _resolve_contacts() -> void:
	for e in enemies:
		e.engaged = false
	for a in allies:
		a.engaged = false
		if not a.alive:
			continue
		var best: Unit = null
		var best_d := 1e9
		var cx := clampi(int(a.pos.x), 0, GRID_W - 1)
		var cy := clampi(int(a.pos.y), 0, GRID_H - 1)
		for yy in range(maxi(0, cy - 1), mini(GRID_H - 1, cy + 1) + 1):
			for xx in range(maxi(0, cx - 1), mini(GRID_W - 1, cx + 1) + 1):
				for e in _grid_e[yy * GRID_W + xx]:
					if not e.alive:
						continue
					var rr: float = a.radius + e.radius
					var d2: float = a.pos.distance_squared_to(e.pos)
					if d2 <= rr * rr and d2 < best_d:
						best_d = d2
						best = e
		if best == null:
			continue
		a.engaged = true
		best.engaged = true
		var a_can := a.atk_cd <= 0.0
		var e_can := best.atk_cd <= 0.0
		if a_can:
			a.atk_cd = a.atk_interval
			_hit(a, best)
		if e_can:
			best.atk_cd = best.atk_interval
			_hit(best, a)


func _ranged_attacks() -> void:
	for a in allies:
		if not a.alive or a.attack_range <= 0.0 or a.engaged or a.atk_cd > 0.0:
			continue
		var t := _nearest(_grid_e, a.pos, a.attack_range)
		if t != null:
			a.atk_cd = a.atk_interval
			_event({"t": "beam", "a": a.pos, "b": t.pos, "color": "C8F5A0", "dur": 0.08})
			_hit(a, t)
	for e in enemies:
		if not e.alive or e.attack_range <= 0.0 or e.engaged or e.atk_cd > 0.0:
			continue
		var t := _nearest(_grid_a, e.pos, e.attack_range)
		if t != null:
			e.atk_cd = e.atk_interval
			_event({"t": "beam", "a": e.pos, "b": t.pos, "color": "D93CF2", "dur": 0.08})
			_hit(e, t)


func _towers_attack() -> void:
	for t in towers:
		if not t["alive"]:
			continue
		t["cd"] = float(t["cd"]) - TICK
		if float(t["cd"]) > 0.0:
			continue
		var target := _nearest(_grid_a, t["pos"], float(t["range"]))
		if target != null:
			t["cd"] = float(t["interval"])
			_event({"t": "beam", "a": t["pos"], "b": target.pos, "color": "B07CFF", "dur": 0.12})
			_damage(target, float(t["atk"]) * 100.0 / (100.0 + target.defense), "")


func _enemy_abilities() -> void:
	for e in enemies:
		if not e.alive or e.cast_interval <= 0.0 or e.cast_cd > 0.0 or e.frozen_t > 0.0:
			continue
		var d: Dictionary = units_db[e.kind]
		if e.role == "soigneur":
			e.cast_cd = e.cast_interval
			var amount := float(d.get("heal_nexus", 0.0)) * enemy_mult
			if nexus_wither_t > 0.0:
				amount *= 0.5
			if amount > 0.0 and nexus_hp < nexus_max:
				var before := nexus_hp
				nexus_hp = minf(nexus_max, nexus_hp + amount)
				healed_total += nexus_hp - before
				_event({"t": "beam", "a": e.pos, "b": NEXUS_POS, "color": "6FE39A", "dur": 0.35})
				_event({"t": "text", "pos": NEXUS_POS + Vector2(1.0, -0.2), "text": "+%d" % int(nexus_hp - before), "color": "6FE39A"})
				if _heal_log_t <= 0.0:
					_heal_log_t = 8.0
					_log("Une Dryade soigne le Nexus !")
			var hu := float(d.get("heal_units", 0.0))
			if hu > 0.0:
				for o in _query(_grid_e, e.pos, 1.5):
					if o != e:
						o.hp = minf(o.max_hp, o.hp + o.max_hp * hu * (0.5 if o.wither_t > 0.0 else 1.0))
		elif e.role == "lanceur":
			var tgt := _nearest(_grid_a, e.pos, float(d.get("cast_range", 3.5)))
			if tgt == null:
				continue
			e.cast_cd = e.cast_interval
			var r := float(d.get("cast_radius", 1.0))
			for a in _query(_grid_a, tgt.pos, r):
				_damage(a, e.atk * affinity(e.element, a.element), "")
			_event({"t": "ring", "pos": tgt.pos, "r": r, "color": "FFF2A8", "dur": 0.35})


## Le Nexus repousse périodiquement les unités qui l'assiègent.
func _nexus_pulse() -> void:
	_pulse_t -= TICK
	if _pulse_t > 0.0:
		return
	_pulse_t = NEXUS_PULSE_INTERVAL
	var hit := false
	for a in _query(_grid_a, NEXUS_POS, NEXUS_PULSE_RANGE):
		_damage(a, NEXUS_PULSE_DMG * enemy_mult * 100.0 / (100.0 + a.defense), "")
		hit = true
	if hit:
		_event({"t": "ring", "pos": NEXUS_POS, "r": NEXUS_PULSE_RANGE, "color": "B07CFF", "dur": 0.4})


func _reach_checks() -> void:
	var shielded := nexus_shielded()
	for a in allies:
		if not a.alive:
			continue
		var touched := false
		for t in towers:
			if not t["alive"]:
				continue
			var tp: Vector2 = t["pos"]
			var rr: float = float(t["r"]) + a.radius
			if a.pos.distance_squared_to(tp) > rr * rr:
				continue
			touched = true
			if a.siege:
				a.engaged = true
				if a.atk_cd > 0.0:
					break
				a.atk_cd = a.atk_interval
			else:
				a.alive = false
			t["hp"] = float(t["hp"]) - a.atk * (1.5 if rng.randf() < a.crit else 1.0)
			t["flash"] = 0.1
			if float(t["hp"]) <= 0.0:
				t["alive"] = false
				surge = minf(100.0, surge + 10.0)
				_event({"t": "ring", "pos": tp, "r": 1.4, "color": "F2C46B", "dur": 0.6})
				_log("Tour de garde détruite (+10 Surge)")
			break
		if touched or not a.alive:
			continue
		var rn := NEXUS_R + a.radius
		if a.pos.distance_squared_to(NEXUS_POS) > rn * rn:
			continue
		if a.siege:
			a.engaged = true
			if a.atk_cd > 0.0:
				continue
			a.atk_cd = a.atk_interval
		else:
			a.alive = false
		if shielded:
			if _shield_fx_t <= 0.0:
				_shield_fx_t = 0.4
				_event({"t": "ring", "pos": NEXUS_POS, "r": 1.3, "color": "D93CF2", "dur": 0.35})
			continue
		var dmg := a.atk * (1.5 if rng.randf() < a.crit else 1.0)
		nexus_hp -= dmg
		nexus_flash = 0.12
		_nexus_dmg_acc += dmg
		if a.element == "ombre":
			nexus_wither_t = 5.0
	for e in enemies:
		if e.alive and e.pos.y <= BARRIER_Y:
			e.alive = false
			_hurt_barrier(e.weight)
	_nexus_dmg_t += TICK
	if _nexus_dmg_t >= 0.4:
		_nexus_dmg_t = 0.0
		if _nexus_dmg_acc >= 1.0:
			_event({"t": "text", "pos": NEXUS_POS + Vector2(rng.randf_range(-0.7, 0.7), -0.5), "text": "-%d" % int(_nexus_dmg_acc), "color": "FFFFFF"})
		_nexus_dmg_acc = 0.0


func _hurt_barrier(amount: float) -> void:
	if barrier_shield > 0.0:
		var a := minf(barrier_shield, amount)
		barrier_shield -= a
		amount -= a
	if amount <= 0.0:
		return
	barrier_hp -= amount
	barrier_flash = 0.25
	_event({"t": "barrier"})


func _hit(src: Unit, tgt: Unit, mult: float = 1.0) -> void:
	var dmg := _calc(src.atk * mult, src.element, src.crit, tgt, src.team == 0)
	_damage(tgt, dmg, src.element)
	if src.team == 0:
		_on_hit_effects(src, tgt, dmg, src.element)


func _calc(atk: float, elem: String, crit: float, tgt: Unit, frontal: bool) -> float:
	var d := atk * affinity(elem, tgt.element)
	if rng.randf() < crit:
		d *= 1.5
	d *= 100.0 / (100.0 + maxf(0.0, tgt.defense))
	if frontal and tgt.front_block > 0.0:
		d *= 1.0 - tgt.front_block
	return d


static func affinity(a: String, b: String) -> float:
	if a == "" or b == "" or a == "physique" or b == "physique":
		return 1.0
	if (a == "lumiere" and b == "ombre") or (a == "ombre" and b == "lumiere"):
		return 1.5
	if BEATS.get(a, "") == b:
		return 1.5
	if BEATS.get(b, "") == a:
		return 0.75
	return 1.0


func _damage(tgt: Unit, amount: float, elem: String) -> void:
	if not tgt.alive or amount <= 0.0:
		return
	if tgt.shield > 0.0:
		var a := minf(tgt.shield, amount)
		tgt.shield -= a
		amount -= a
	tgt.hp -= amount
	tgt.flash_t = 0.08
	if elem != "":
		tgt.last_elem = elem
	if tgt.hp <= 0.0:
		_kill(tgt)


func _apply_status(tgt: Unit, elem: String) -> void:
	if not tgt.alive:
		return
	match elem:
		"feu":
			tgt.burn_t = 3.0
			tgt.burn_dps = maxf(tgt.burn_dps, 0.03 * tgt.max_hp * effect_mult)
		"givre":
			tgt.slow_stacks += 1
			tgt.slow_t = 3.0
			if tgt.slow_stacks >= 3:
				tgt.frozen_t = 1.5 * effect_mult
				tgt.slow_stacks = 0
		"nature":
			tgt.poison_stacks = mini(5, tgt.poison_stacks + 1)
			tgt.poison_t = 4.0
			tgt.poison_unit = 0.02 * tgt.max_hp * effect_mult
		"ombre":
			tgt.wither_t = 5.0


func _on_hit_effects(src: Unit, tgt: Unit, dmg: float, elem: String) -> void:
	match elem:
		"feu", "givre", "nature", "ombre":
			_apply_status(tgt, elem)
			if elem == "ombre" and src.alive:
				src.hp = minf(src.max_hp, src.hp + dmg * 0.1)
		"foudre":
			var n := 0
			for e in _query(_grid_e, tgt.pos, 1.5):
				if e == tgt:
					continue
				_event({"t": "beam", "a": tgt.pos, "b": e.pos, "color": "FFE45C", "dur": 0.1})
				_damage(e, dmg * 0.5 * effect_mult, "foudre")
				n += 1
				if n >= 2:
					break
		"lumiere":
			for a in _query(_grid_a, src.pos, 1.0):
				a.hp = minf(a.max_hp, a.hp + dmg * 0.05 * effect_mult)


func _kill(u: Unit) -> void:
	if not u.alive:
		return
	u.alive = false
	if u.team == 1:
		kills += 1
		var big := u.role in ["brute", "bouclier", "lanceur", "soigneur"] or u.elite
		surge = minf(100.0, surge + (SURGE_PER_BIG if big else SURGE_PER_KILL))
		_event({"t": "puff", "pos": u.pos, "color": "FF6B8A"})
		if u.role == "soigneur":
			_log("Soigneur ennemi abattu")
		if u.last_elem == "ombre" and rng.randf() < 0.05:
			var s := _make_unit("skeleton", 0, u.pos)
			s.owner_idx = 0
			_add_ally(s)
	else:
		_event({"t": "puff", "pos": u.pos, "color": "4FE3D2"})
		if fire_explode and u.element == "feu":
			_event({"t": "ring", "pos": u.pos, "r": 0.9, "color": "FF9B4A", "dur": 0.3})
			for e in _query(_grid_e, u.pos, 0.9):
				_damage(e, u.atk * 0.6, "feu")


func _flush() -> void:
	if not _pending_allies.is_empty():
		allies.append_array(_pending_allies)
		_pending_allies.clear()
	if not _pending_enemies.is_empty():
		enemies.append_array(_pending_enemies)
		_pending_enemies.clear()
	_compact(allies)
	_compact(enemies)


func _compact(arr: Array[Unit]) -> void:
	var j := 0
	for i in range(arr.size()):
		var u := arr[i]
		if u.alive:
			arr[j] = u
			j += 1
	arr.resize(j)


func _check_end() -> void:
	if nexus_hp <= 0.0:
		nexus_hp = 0.0
		state = "victory"
		stars = 1
		if barrier_hp / barrier_max > 0.5:
			stars += 1
			if time <= par_time:
				stars += 1
		_log("Victoire !")
		_event({"t": "ring", "pos": NEXUS_POS, "r": 4.0, "color": "F2C46B", "dur": 1.2})
		return
	if barrier_hp <= 0.0:
		barrier_hp = 0.0
		state = "defeat"
		_log("La Barrière est tombée…")
		return
	var ratio := nexus_hp / nexus_max
	for i in range(echo_thresholds.size()):
		if not _echo_done[i] and ratio <= echo_thresholds[i]:
			_echo_done[i] = true
			_offer_echoes()
			return


# ---------------------------------------------------------------- Échos

func _offer_echoes() -> void:
	var pool: Array[String] = []
	for e in echoes_db:
		var id := str(e["id"])
		if not echoes_taken.has(id) or bool(e.get("stackable", false)):
			pool.append(id)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	pending_echoes.clear()
	for i in range(mini(3, pool.size())):
		pending_echoes.append(pool[i])
	if pending_echoes.is_empty():
		return
	state = "echo"
	if autoplay:
		choose_echo(pending_echoes[rng.randi_range(0, pending_echoes.size() - 1)])


func echo_def(id: String) -> Dictionary:
	for e in echoes_db:
		if str(e["id"]) == id:
			return e
	return {"id": id, "name": id, "desc": ""}


func choose_echo(id: String) -> void:
	echoes_taken.append(id)
	match id:
		"resonance":
			extra_number += 1
		"cendres_vives":
			fire_explode = true
		"flux_torrentiel":
			cadence_mult *= 1.25
		"pacte_ombre":
			spell_cost_mult *= 0.5
			barrier_cost_per_spell += 1.0
		"echo_jumeau":
			champion_double = true
		"bastion":
			barrier_max += 30.0
			barrier_hp += 30.0
	pending_echoes.clear()
	state = "running"
	_log("Écho choisi : %s" % str(echo_def(id)["name"]))


# ---------------------------------------------------------------- actions (joueur et bots)

func player() -> Caster:
	return casters[0]


func set_player_aim(x: float) -> void:
	var c := casters[0]
	c.target_x = clampf(x, c.min_x, c.max_x)


func set_player_firing(on: bool) -> void:
	casters[0].firing = on


func spell_cost(c: Caster, id: String) -> float:
	var cost := float(spells_db[id].get("mana", 0))
	if c.idx == 0:
		cost *= spell_cost_mult
	return cost


func spell_ready(c: Caster, id: String) -> bool:
	return state == "running" and c.mana >= spell_cost(c, id) and float(c.spell_cd.get(id, 0.0)) <= 0.0


## Lance un sort à la position logique « at ». Retourne false s'il n'a pas pu être lancé.
func cast_spell(c: Caster, id: String, at: Vector2) -> bool:
	if not spell_ready(c, id):
		return false
	var sp: Dictionary = spells_db[id]
	if not _apply_spell(c, sp, at):
		return false
	c.mana -= spell_cost(c, id)
	c.spell_cd[id] = float(sp.get("cd", 0))
	if c.idx == 0 and barrier_cost_per_spell > 0.0:
		_hurt_barrier(barrier_cost_per_spell)
	if c.is_bot:
		_log("%s : %s" % [c.name, str(sp["name"])])
	return true


func _apply_spell(c: Caster, sp: Dictionary, at: Vector2) -> bool:
	var col := str(sp.get("color", "FFFFFF"))
	match str(sp["type"]):
		"aoe":
			var r := float(sp.get("radius", 1.0))
			var dmg := float(sp.get("damage", 0)) * c.atk_mult
			var elem := str(sp.get("element", ""))
			for e in _query(_grid_e, at, r + 0.3):
				_damage(e, _calc(dmg, elem, c.crit, e, false), elem)
				if not e.alive:
					continue
				_apply_status(e, elem)
				if sp.has("root"):
					e.rooted_t = maxf(e.rooted_t, float(sp["root"]))
				if sp.has("slow_stacks"):
					e.slow_stacks += int(sp["slow_stacks"])
					e.slow_t = 3.0
					if e.slow_stacks >= 3:
						e.frozen_t = 1.5 * effect_mult
						e.slow_stacks = 0
			for t in towers:
				if t["alive"] and at.distance_to(t["pos"]) <= r + 0.45:
					t["hp"] = float(t["hp"]) - dmg
					t["flash"] = 0.1
					if float(t["hp"]) <= 0.0:
						t["alive"] = false
						surge = minf(100.0, surge + 10.0)
						_log("Tour de garde détruite (+10 Surge)")
			var nr := float(sp.get("nexus_ratio", 0.0))
			if nr > 0.0 and at.distance_to(NEXUS_POS) <= r + NEXUS_R and not nexus_shielded():
				nexus_hp -= dmg * nr
				nexus_flash = 0.2
				_event({"t": "text", "pos": NEXUS_POS + Vector2(0.0, -0.8), "text": "-%d" % int(dmg * nr), "color": "FFFFFF"})
			_event({"t": "ring", "pos": at, "r": r, "color": col, "dur": 0.45})
			return true
		"purify":
			var best: Portal = null
			var bd := 1e9
			for p in portals:
				if not p.is_negative():
					continue
				var d := Vector2(p.x, p.y).distance_to(at)
				if d < bd and d <= float(sp.get("radius", 2.5)) + p.width * 0.5:
					bd = d
					best = p
			if best == null:
				return false
			_purify(best)
			return true
		"barrier_shield":
			barrier_shield += float(sp.get("amount", 10))
			_event({"t": "ring", "pos": Vector2(W * 0.5, BARRIER_Y), "r": 2.5, "color": col, "dur": 0.5})
			return true
		"column":
			var w := float(sp.get("width", 0.8))
			var dmg := float(sp.get("damage", 30)) * c.atk_mult
			var elem := str(sp.get("element", ""))
			for e in enemies:
				if e.alive and absf(e.pos.x - at.x) <= w * 0.5 + e.radius:
					_damage(e, _calc(dmg, elem, c.crit, e, false), elem)
			_event({"t": "beam", "a": Vector2(at.x, BARRIER_Y), "b": Vector2(at.x, H - 0.4), "color": col, "dur": 0.3, "w": 3.0})
			return true
	return false


func summon_champion() -> bool:
	if state != "running" or champion_charge < champion_need:
		return false
	var c := casters[0]
	var count := 2 if champion_double else 1
	champion_double = false
	for i in range(count):
		var x := clampf(c.x + (float(i) - float(count - 1) * 0.5) * 0.9, 0.5, W - 0.5)
		var u := _make_unit(champion_kind, 0, Vector2(x, CASTER_Y + 0.7))
		u.owner_idx = 0
		u.atk *= c.atk_mult
		u.hp *= c.hp_mult
		u.max_hp = u.hp
		u.crit = c.crit
		u.element = last_elem
		_pending_allies.append(u)
		_event({"t": "ring", "pos": u.pos, "r": 1.0, "color": "F2C46B", "dur": 0.5})
	champion_charge = 0
	_log("Champion invoqué : %s" % str(units_db[champion_kind]["name"]))
	return true


func ultimate_ready() -> bool:
	return state == "running" and surge >= 100.0


func cast_ultimate(at: Vector2) -> bool:
	if not ultimate_ready():
		return false
	var sp: Dictionary = spells_db[ultimate_id]
	_apply_spell(casters[0], sp, at)
	surge = 0.0
	_event({"t": "flash"})
	_log("ULTIME : %s" % str(sp["name"]))
	return true


func cycle_order(idx: int) -> void:
	if idx <= 0 or idx >= casters.size():
		return
	var c := casters[idx]
	set_order(idx, ORDERS[(ORDERS.find(c.order) + 1) % ORDERS.size()])


func set_order(idx: int, order: String) -> void:
	if idx <= 0 or idx >= casters.size():
		return
	casters[idx].order = order
	_log("%s : %s" % [casters[idx].name, str(ORDER_LABELS.get(order, order))])


# ---------------------------------------------------------------- aide à la décision (IA)

func portal_value_at(x: float) -> float:
	var v := 0.0
	var light := false
	for p in portals:
		if absf(x - p.x) > p.width * 0.5:
			continue
		if p.is_negative():
			if light:
				v += 3.0 if p.is_seal and not p.purified else 0.5
				continue
			match p.kind:
				"sub":
					v -= float(p.value) * 0.5
				"div", "corrupt":
					v -= 3.0
				_:
					v -= 1.0
			continue
		match p.kind:
			"mult":
				v += float(p.value - 1) * 3.0
			"add":
				v += float(p.value) * 0.35
			"elem":
				light = p.element == "lumiere"
				v += 1.0
			_:
				v += 1.0
	return v


func threat_at(x: float) -> float:
	var t := 0.0
	for e in enemies:
		if not e.alive or e.pos.y > 8.0:
			continue
		var dx := absf(e.pos.x - x)
		if dx > 1.2:
			continue
		t += e.weight * (1.0 + (8.0 - e.pos.y) / 4.0) * (1.0 - dx / 1.2)
	return t


func total_threat() -> float:
	var t := 0.0
	for e in enemies:
		if e.alive and e.pos.y < 6.0:
			t += e.weight * (1.0 + (6.0 - e.pos.y) / 3.0)
	return t


func nexus_access_at(x: float) -> float:
	var v := 2.0 / (1.0 + absf(x - NEXUS_POS.x))
	for e in enemies:
		if e.alive and e.role == "soigneur" and absf(e.pos.x - x) < 0.8:
			v += 3.0
	return v


func healer_pos() -> Vector2:
	for e in enemies:
		if e.alive and e.role == "soigneur":
			return e.pos
	return Vector2(-1.0, -1.0)


func healers_alive() -> int:
	var n := 0
	for e in enemies:
		if e.alive and e.role == "soigneur":
			n += 1
	return n


func densest_enemy(r: float, max_y: float = H) -> Dictionary:
	var best_pos := Vector2.ZERO
	var best_n := 0
	var step := maxi(1, int(enemies.size() / 40.0))
	var i := 0
	while i < enemies.size():
		var e := enemies[i]
		i += step
		if not e.alive or e.pos.y > max_y:
			continue
		var n := _query(_grid_e, e.pos, r).size()
		if n > best_n:
			best_n = n
			best_pos = e.pos
	return {"pos": best_pos, "n": best_n}


func best_column(w: float) -> Dictionary:
	var best_x := W * 0.5
	var best_n := 0
	var x := 0.5
	while x <= W - 0.5:
		var n := 0
		for e in enemies:
			if e.alive and absf(e.pos.x - x) <= w * 0.5:
				n += 1
		if n > best_n:
			best_n = n
			best_x = x
		x += 0.5
	return {"x": best_x, "n": best_n}


func purify_target() -> Vector2:
	var fallback := Vector2(-1.0, -1.0)
	for p in portals:
		if not p.is_negative():
			continue
		if p.is_seal:
			return Vector2(p.x, p.y)
		fallback = Vector2(p.x, p.y)
	return fallback


# ---------------------------------------------------------------- utilitaires

func _event(e: Dictionary) -> void:
	if events.size() < 400:
		events.append(e)


func _log(text: String) -> void:
	log_lines.append(text)
	if log_lines.size() > 40:
		log_lines.remove_at(0)
