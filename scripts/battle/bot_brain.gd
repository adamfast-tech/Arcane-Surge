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
	# Plaie de l'Hydre : la brûler avec un sort de Feu avant qu'elle ne repousse.
	if not sim.stumps.is_empty():
		for id in c.spells:
			var fs: Dictionary = sim.spells_db[id]
			if str(fs.get("element", "")) == "feu" and str(fs["type"]) in ["aoe", "zone", "barrage", "ground"] and sim.spell_ready(c, id):
				if sim.cast_spell(c, id, sim.stumps[0]["pos"]):
					return
	# Forêt Cendrée : éteindre au Givre l'incendie qui descend (ou le foyer où passent les invocations).
	if not sim.fires.is_empty():
		var ft := sim.fire_target()
		if ft.x >= 0.0:
			for id in c.spells:
				var gs: Dictionary = sim.spells_db[id]
				if str(gs.get("element", "")) == "givre" and str(gs["type"]) in ["aoe", "zone", "column", "barrage"] and not bool(gs.get("single", false)) and sim.spell_ready(c, id):
					if sim.cast_spell(c, id, ft):
						return
	for id in c.spells:
		if not sim.spell_ready(c, id):
			continue
		var sp: Dictionary = sim.spells_db[id]
		if float(sp.get("barrier_cost", 0.0)) > 0.0 and sim.barrier_hp < sim.barrier_max * 0.6:
			continue
		match str(sp["type"]):
			"barrage":
				var cl := sim.densest_enemy(float(sp.get("spread", 2.0)), 12.0)
				if int(cl["n"]) >= 6 and sim.cast_spell(c, id, cl["pos"]):
					return
			"wall":
				# Mur de pierre : couper une masse qui approche de la Barrière.
				var cl := sim.densest_enemy(1.6, 7.0)
				if int(cl["n"]) >= 6 and sim.cast_spell(c, id, (cl["pos"] as Vector2) - Vector2(0.0, 1.0)):
					return
			"quake":
				var cl := sim.densest_enemy(minf(float(sp.get("band", 2.0)), 3.0), 12.0)
				if int(cl["n"]) >= 8 and sim.cast_spell(c, id, cl["pos"]):
					return
			"ground":
				var gk := str(sp.get("ground_kind", ""))
				if gk == "piege":
					# Pièges : sur le chemin d'une masse qui approche (les ennemis descendent vers la Barrière).
					var tc := sim.densest_enemy(float(sp.get("blast_r", 1.4)) + 0.6, 10.0)
					if int(tc["n"]) >= 3 and sim.cast_spell(c, id, (tc["pos"] as Vector2) - Vector2(0.0, 0.9)):
						return
					continue
				var cl := sim.densest_enemy(float(sp.get("radius", 2.0)) + (1.0 if gk == "rune" else 0.0), 9.0 if gk == "rune" else 12.0)
				if int(cl["n"]) >= (3 if gk == "rune" else 5) and sim.cast_spell(c, id, cl["pos"]):
					return
			"barrier_heal":
				if sim.barrier_hp < sim.barrier_max * 0.7:
					if sim.cast_spell(c, id, Vector2(c.x, 2.0)):
						return
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
			"rally":
				# Renfort : quand l'armée est nombreuse et au contact.
				var fighting := 0
				for a in sim.allies:
					if a.alive and a.engaged:
						fighting += 1
				if fighting >= 8 and sim.cast_spell(c, id, Vector2(c.x, 4.0)):
					return
			"aoe":
				if bool(sp.get("single", false)):
					# Tir unique : la plus grosse cible (soigneur d'abord).
					var hp0 := sim.healer_pos()
					var big := sim.strongest_enemy(12.5)
					if hp0.x >= 0.0 and sim.cast_spell(c, id, hp0):
						return
					if big != null and (big.max_hp >= 60.0 or float(sp.get("mana", 0)) <= 20.0) and sim.cast_spell(c, id, big.pos):
						return
					continue
				var hp := sim.healer_pos()
				if hp.x >= 0.0 and sim.cast_spell(c, id, hp):
					return
				var cl := sim.densest_enemy(float(sp.get("radius", 1.5)), 12.0)
				if int(cl["n"]) >= 5 and sim.cast_spell(c, id, cl["pos"]):
					return
			"zone":
				var zr := float(sp.get("radius", 1.5))
				if sp.has("slow"):
					# Racines : retenir les ennemis qui approchent de la Barrière.
					var cl := sim.densest_enemy(zr, 6.0)
					if int(cl["n"]) >= 4 and sim.cast_spell(c, id, cl["pos"]):
						return
				elif sp.has("pull"):
					var cl := sim.densest_enemy(zr, 11.0)
					if int(cl["n"]) >= 6 and sim.cast_spell(c, id, cl["pos"]):
						return
				else:
					var cl := sim.densest_enemy(zr, 12.0)
					if int(cl["n"]) >= 5 and sim.cast_spell(c, id, cl["pos"]):
						return
			"chain":
				var hp := sim.healer_pos()
				if hp.x >= 0.0 and sim.cast_spell(c, id, hp):
					return
				var cl := sim.densest_enemy(float(sp.get("range", 2.4)), 12.0)
				if int(cl["n"]) >= 3 and sim.cast_spell(c, id, cl["pos"]):
					return
			"wave":
				# Onde arcanique : repousser une masse arrivée près de la Barrière.
				var cl := sim.densest_enemy(float(sp.get("radius", 2.0)), 4.5)
				if int(cl["n"]) >= 4 and sim.cast_spell(c, id, cl["pos"]):
					return
			"army":
				# Horde : des squelettes entre la Barrière et la masse ennemie.
				var cl := sim.densest_enemy(2.0, 11.0)
				if int(cl["n"]) >= 4 and sim.cast_spell(c, id, (cl["pos"] as Vector2) - Vector2(0.0, 1.2)):
					return
			"frenzy":
				# Hurlement : quand beaucoup d'invocations sont au contact.
				if sim.allies.size() >= 14 and sim.total_threat() > 6.0 and sim.cast_spell(c, id, Vector2(c.x, 4.0)):
					return
			"purify":
				var target := sim.purify_target()
				if target.x >= 0.0 and sim.cast_spell(c, id, target):
					return
				if float(sp.get("damage", 0.0)) > 0.0:
					# Exorcisme : sans portail à purifier, frapper une masse.
					var cl := sim.densest_enemy(float(sp.get("radius", 2.0)), 12.0)
					if int(cl["n"]) >= 5 and sim.cast_spell(c, id, cl["pos"]):
						return
			"mirror":
				# Lames miroirs : dédoubler une mêlée de ses propres invocations.
				var best := Vector2(-1.0, -1.0)
				var bn := 0
				for a in sim.allies:
					if a.alive and a.owner_idx == c.idx and a.role == "familier" and a.pos.y > 3.0:
						var k := 0
						for b in sim.allies:
							if b.owner_idx == c.idx and b.alive and b.pos.distance_squared_to(a.pos) < 3.2:
								k += 1
						if k > bn:
							bn = k
							best = a.pos
						break
				if bn >= 6 and sim.cast_spell(c, id, best):
					return
			"harvest":
				# Moisson d'âmes : sacrifier des invocations prises dans une masse ennemie.
				var cl := sim.densest_enemy(2.0, 11.0)
				if int(cl["n"]) >= 6 and sim.cast_spell(c, id, cl["pos"]):
					return
	if c.idx != 0:
		return
	# Pilotage automatique du joueur (simulateur) : Don racial, Champion et Ultime.
	if sim.don_ready():
		var did := str(sim.don.get("id", ""))
		var low := sim.barrier_hp < sim.barrier_max * 0.75
		if (did in ["rempart_runique", "mue"] and low) or (did not in ["rempart_runique", "mue"] and sim.time > 8.0):
			var cl := sim.densest_enemy(1.6, 6.5)
			sim.use_don(cl["pos"] if int(cl["n"]) > 0 else Vector2(-1.0, -1.0))
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
