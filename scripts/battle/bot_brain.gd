class_name BotBrain
extends RefCounted
## IA par utilité des bots (docs/design/03-combat.md §9) : à intervalle régulier, le bot
## note chaque position X possible (portails, menace sur la Barrière, accès au Nexus)
## et vise la meilleure. Sert aussi au pilotage automatique du joueur (simulateur).

const PERSONALITIES := {
	"equilibre": {"portal": 1.0, "def": 1.0, "nexus": 1.0},
	"agressif": {"portal": 1.3, "def": 0.5, "nexus": 1.6},
	"defensif": {"portal": 0.7, "def": 1.8, "nexus": 0.6},
	"opportuniste": {"portal": 1.8, "def": 0.8, "nexus": 0.8},
}

var think_t := 0.0
var spell_t := 0.3


func update(sim: BattleSim, c: BattleSim.Caster, dt: float) -> void:
	think_t -= dt
	spell_t -= dt
	if think_t <= 0.0:
		think_t = c.think_interval
		_choose_position(sim, c)
	if spell_t <= 0.0:
		spell_t = 0.5
		_use_abilities(sim, c)


func _choose_position(sim: BattleSim, c: BattleSim.Caster) -> void:
	c.firing = true
	if c.order == "suis_moi" and c.idx != 0:
		var px := sim.casters[0].x + (-1.0 if c.side == "left" else 1.0)
		c.target_x = clampf(px, c.min_x, c.max_x)
		return
	var w: Dictionary = PERSONALITIES.get(c.personality, PERSONALITIES["equilibre"])
	var wp := float(w["portal"])
	var wd := float(w["def"])
	var wn := float(w["nexus"])
	match c.order:
		"focus_nexus":
			wn *= 3.0
			wd *= 0.5
		"defends":
			wd *= 3.0
			wn *= 0.4
	var player_x := sim.casters[0].x
	var best_x := c.x
	var best_s := -1e9
	var x := c.min_x
	while x <= c.max_x + 0.001:
		var s := wp * sim.portal_value_at(x) + wd * sim.threat_at(x) + wn * sim.nexus_access_at(x)
		if c.idx != 0:
			s -= 1.5 * maxf(0.0, 1.0 - absf(x - player_x) / 1.2)
		s -= absf(x - c.x) * 0.15
		if s > best_s:
			best_s = s
			best_x = x
		x += 0.5
	c.target_x = clampf(best_x + sim.rng.randf_range(-c.aim_error, c.aim_error), c.min_x, c.max_x)


func _use_abilities(sim: BattleSim, c: BattleSim.Caster) -> void:
	for id in c.spells:
		if not sim.spell_ready(c, id):
			continue
		var sp: Dictionary = sim.spells_db[id]
		match str(sp["type"]):
			"barrier_shield":
				if sim.barrier_hp < sim.barrier_max * 0.6 or sim.total_threat() > 10.0:
					if sim.cast_spell(c, id, Vector2(c.x, 2.0)):
						return
			"column":
				var hp := sim.healer_pos()
				if hp.x >= 0.0:
					if sim.cast_spell(c, id, hp):
						return
				var col := sim.best_column(float(sp.get("width", 0.8)))
				if int(col["n"]) >= 5 and sim.cast_spell(c, id, Vector2(float(col["x"]), 8.0)):
					return
			"aoe":
				if sp.has("root"):
					var cl := sim.densest_enemy(float(sp.get("radius", 1.5)), 6.0)
					if int(cl["n"]) >= 4 and sim.cast_spell(c, id, cl["pos"]):
						return
				else:
					var hp := sim.healer_pos()
					if hp.x >= 0.0 and sim.cast_spell(c, id, hp):
						return
					var cl := sim.densest_enemy(float(sp.get("radius", 1.5)), 12.0)
					if int(cl["n"]) >= 5 and sim.cast_spell(c, id, cl["pos"]):
						return
			"purify":
				var target := sim.purify_target()
				if target.x >= 0.0 and sim.cast_spell(c, id, target):
					return
	if c.idx != 0:
		return
	# Pilotage automatique du joueur (simulateur) : Champion et Ultime.
	if sim.champion_charge >= sim.champion_need:
		sim.summon_champion()
	if sim.ultimate_ready():
		var hp := sim.healer_pos()
		var cl := sim.densest_enemy(3.0)
		var target: Vector2 = sim.objective_pos()
		if hp.x >= 0.0:
			target = hp
		elif int(cl["n"]) >= 8 or sim.nexus_shielded():
			target = cl["pos"]
		sim.cast_ultimate(target)
