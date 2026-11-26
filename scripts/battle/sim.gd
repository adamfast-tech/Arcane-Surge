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
const ELEM_NAMES := {"feu": "Feu", "givre": "Givre", "foudre": "Foudre", "nature": "Nature", "lumiere": "Lumière", "ombre": "Ombre", "physique": "Physique"}
const SURGE_PER_BIG := 3.0
## Difficulté globale : Nexus et boss ont 20 % de PV en moins, les escortes 25 % de PV en plus.
const OBJECTIVE_HP_MULT := 0.8
const ESCORT_HP_MULT := 1.25


class Caster:
	var idx := 0
	var id := "" ## « player » ou identifiant du compagnon (data/party.json)
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
	var fire_acc := 1.0 ## 1 : prêt à tirer (le premier appui tire aussitôt)
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
	var class_fire := false ## compagnon : tir de sa classe (choix du Cercle) au lieu de ses troupes


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
var diff := 1.0 ## difficulté (Options) : vitesse et dégâts des ennemis, PV du Nexus et du boss
var forge_power := 1.0 ## force des portails FORGE (×2 si les Portes des Pics ont été réactivées, choix 4-9)
var wave_budget_mult := 1.0 ## taille des vagues (×0,85 si la forteresse a été scellée, choix 4-9)

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
var _nexus_dmg_pos := NEXUS_POS

## Objectif du niveau : "nexus" (un ou plusieurs), "boss" ou "escort".
var objective := "nexus"
var nexi: Array[Dictionary] = []
var boss: Unit = null
var boss_name := ""
var boss_phase := 0
var boss_timers: Dictionary = {}
var boss_shield_t := 0.0
var boss_shield_elem := ""
var escort: Unit = null
var escort_start_y := 1.6
var escort_goal_y := 13.8
var orbs: Array[Dictionary] = []
var orb_cfg: Dictionary = {}
var telegraphs: Array[Dictionary] = []
var end_reason := ""
## Effets de l'arbre de compétences du joueur ({clé: valeur}, voir data/skill_trees).
var mods: Dictionary = {}
## Zone 2 : Vent des steppes (rafales annoncées qui poussent les unités) et pylônes d'ambre.
var wind_cfg: Dictionary = {}
var wind_state := "calm" ## calm, warn, blow
var wind_t := 0.0
var wind_dir := 1.0
var pylons: Array[Dictionary] = []
## Bannières de guerre : tant qu'il en reste, le boss est en armure (dégâts ÷ 5).
var banners: Array[Unit] = []
# Zone 3 · Marais Murmurants : bancs de brume, têtes de l'Hydre et plaies à cautériser.
const MAX_HEADS := 6
const STUMP_TIME := 5.0
const FOG_CONCEAL := 0.8
var fog: Array[Dictionary] = [] ## {pos, r, density, vx}
var fog_cfg: Dictionary = {}
var heads: Array[Unit] = []
var stumps: Array[Dictionary] = [] ## {pos, t}
var ult_wards: Array[Dictionary] = [] ## {pos, r, t} : zones d'Ultime qui cautérisent les moignons
# Zone 4 : avalanches, runes du Colosse, portes corrompues.
var avalanche_cfg: Dictionary = {}
var avalanche_t := 0.0
var runes: Array[Unit] = []
var _gate_curses: Array[Dictionary] = [] ## {portal, t, kind, value, element}
var _immune_txt_t := 0.0
# Don racial (étape 13.2) : {id, name, cd, power} ; effets temporaires.
## Zone 5 : Désert de Verre (docs/design/33-zone5.md).
const DAY_BONUS := 1.25 ## le jour, le Feu +25 % ; la nuit, le Givre +25 %
var daynight_cfg: Dictionary = {} ## {day, night, start}
var is_day := true
var daynight_t := 0.0
var daynight_speed := 1.0 ## le Sphinx accélère le cycle (phase 3)
var mirage_reform := 12.0 ## secondes avant qu'un mirage dissipé se reforme ailleurs
var riddle: Dictionary = {} ## énigme du Sphinx en cours : {q, portals, right, t}
var riddles_right := 0
var riddles_wrong := 0
var boss_exposed_t := 0.0 ## bonne réponse : le Sphinx subit +50 % de dégâts
var _riddles_used: Array[int] = []
var riddle_need := 0 ## > 0 : invocations demandées par réponse, au lieu de la valeur du niveau (le Journal lu, 5-9)
var bonus_unique := "" ## objet unique gagné par un exploit en combat (les deux énigmes : Couronne de l'Énigme)
var _portal_seq := 500
## Énigmes du Sphinx de verre : la première réponse est la bonne (l'ordre des portails est tiré au sort).
const RIDDLES := [
	{"q": "Je coule sans eau et tombe sans bruit. Nul ne me remonte… sauf un Porteur.", "a": ["LE TEMPS", "LE SABLE", "LE SURGE"]},
	{"q": "Nains et elfes m'ont gravée il y a mille ans. Je m'ouvre sur la magie des Veines.", "a": ["UNE PORTE", "UNE RUNE", "UNE FORGE"]},
	{"q": "Il voulut défaire une seule mort, et il brisa le monde. Qui était-il ?", "a": ["UN PORTEUR", "UN ROI", "UN DIEU"]},
	{"q": "Le jour je brûle, la nuit je gèle. Je garde le Collège depuis trois siècles.", "a": ["LE DÉSERT", "LE SOLEIL", "LA LUNE"]},
	{"q": "Plus on me brise, plus je montre de visages.", "a": ["UN MIROIR", "UN CRÂNE", "UN SCEAU"]},
]

## Zone 6 : Forêt Cendrée (docs/design/37-zone6.md) : incendies, dragons, envol des boss.
const FIRE_TOP := 13.4 ## un incendie part de la lisière ennemie
const FIRE_STALL := 4.0 ## un couloir éteint au Givre ne repart qu'après 4 s
const LAVA_COOL := 6.0 ## une coulée de magma refroidie au Givre ne brûle plus pendant 6 s
const MAX_FIRES := 16
var wildfire_cfg: Dictionary = {} ## {first, every, max, width, speed, stop, life, dps}
var wildfire_t := 0.0
## Foyers : couloirs qui descendent vers la Barrière, foyers posés (dragons, cultistes, souffle), coulées de magma.
## {id, x, w, front, top, stop, speed, t, stall, patch, lava, cool}
var fires: Array[Dictionary] = []
var fire_dps := 0.0 ## PV perdus par seconde dans le feu par une invocation (la moitié pour les ennemis qui ne sont pas de Feu)
var fires_out := 0 ## foyers éteints au Givre
var fire_burned := 0.0 ## PV d'invocations brûlés (statistiques du simulateur)
var fire_by: Dictionary = {} ## PV brûlés par origine du feu (incendie, magma, flaque, cultiste, dragon, souffle)
var _fire_seq := 0
var dragon_cfg: Dictionary = {} ## {first, every, warn, dmg, band, patches}
var dragon_t := 0.0
## Zone 7 : Cité Engloutie (docs/design/39-zone7.md) : marées, courants, tourbillons.
const WATER_SLOW := 0.75 ## tes invocations dans l'eau
const WATER_HASTE := 1.2 ## les créatures aquatiques dans l'eau
var tide_cfg: Dictionary = {} ## {first, low, high, move, low_y, high_y}
var tide_state := "" ## low, rising, high, falling
var tide_t := 0.0
var tide_y := 0.0 ## niveau de l'eau : tout ce qui est sous cette rangée est sous l'eau
var currents: Array[Dictionary] = [] ## {y, h, dir, speed, flip, t}
var whirlpools: Array[Dictionary] = [] ## {pos, r, t, pull, dps}
var whirl_dps := 8.0 ## PV perdus par seconde au cœur d'un tourbillon (invocations)
var warn_bonus := 0.0 ## secondes d'annonce en plus pour les attaques des boss (Prémonitions, acte 7)
var story_dragons: Dictionary = {} ## passages de dragons ajoutés par l'histoire (story_mods)
var story_no_tide := false ## la marée retenue par l'histoire (Archives scellées)
## Acte 6 : la Marque du Wyrm (06-monde §4.1). Le compagnon marqué combat aux côtés du Wyrm en phase 3.
var flags_in: Array = [] ## drapeaux de l'histoire reçus au départ
var traitor_id := "" ## compagnon passé au Wyrm ("" sinon)
var traitor_unit: Unit = null
var traitor_broken := false ## réduit à 0 PV : brisé, pas mort (épargné si on le laisse)
var traitor_killed := false ## achevé par un sort une fois brisé
var story_out: Array[String] = [] ## drapeaux écrits par le combat, appliqués en cas de victoire
var _ash_renew := false ## Héritage de cendre (Renaissance) : la Barrière se ranime une fois

var don: Dictionary = {}
var don_t := 0.0
var rally_t := 0.0
var _bheal_t := 0.0 ## soin de Barrière sur la durée (grimoire du Clerc) : durée restante
var _bheal_rate := 0.0 ## PV par seconde
var breeze_t := 0.0
var charge_t := 0.0
var barrier_invuln_t := 0.0
var _fallen: Array[Dictionary] = []
var _miracle_used := false ## Clé de voûte Miracle (Clerc) : une seule fois par partie
var _dance_budget := 1.0 ## Danse parfaite : secondes de recharge rendues au plus par seconde
var _thirst_budget := 2.0 ## Soif : PV de Barrière rendus au plus par seconde
var _wrath_acc := 0.0 ## Courroux céleste : soins en excès à convertir en dégâts
var _legion_count := 0 ## Légion : squelettes invoqués depuis le dernier Colosse
var _last_crit := false
var _sid_owner := -1 ## lanceur du sort en cours (0 : le joueur)
var _sid := "" ## sort en cours de résolution : chaque évènement émis porte son identifiant (animations propres)
var frenzy_until := 0.0 ## fin de la dernière frénésie lancée (Rage de sang : la Barrière paie)
var sacrificed := 0 ## invocations sacrifiées (Moisson d'âmes)
## Sorts à impact différé (projectile, météore) et zones actives (pluie, racines, vortex).
var pending_impacts: Array[Dictionary] = []
var class_spawns: Array[Dictionary] = [] ## troupes de classe qui vont apparaître (décalées de quelques centièmes)
var _champ_acc := 0.0 ## charge du Champion : au rythme de l'ancien Flux (4 par seconde), quelle que soit la classe
var shot_buff_until := 0.0 ## Renfort lancé : les tirs de classe partent renforcés jusque-là
var shot_buff: Dictionary = {} ## {atk, crit, aspd, steal}
var terrain := BattleTerrain.new() ## sols, piliers, murs (scripts/battle/terrain.gd)
var zones: Array[Dictionary] = []
## Effets des fils du destin appliqués à ce niveau (textes affichés au départ).
var story_notes: Array[String] = []


# ---------------------------------------------------------------- mise en place

func setup(level_data: Dictionary, party: Dictionary, seed_value: int, opts: Dictionary = {}) -> void:
	level = level_data
	units_db = GameData.units()
	spells_db = GameData.spells()
	for k in spells_db.keys():
		spells_db[k]["id"] = k
	mods = opts.get("mods", {})
	echoes_db = GameData.echoes()
	rng.seed = seed_value
	autoplay = bool(opts.get("autoplay", false))
	solo = bool(opts.get("solo", false)) or bool(level.get("solo", false))
	enemy_mult = pow(1.045, float(level.get("global_level", 1)) - 1.0)
	diff = clampf(float(opts.get("difficulty", 1.0)), 0.25, 5.0)
	objective = str(level.get("objective", "nexus"))
	par_time = float(level.get("par_time", 150))
	for i in range(GRID_W * GRID_H):
		_grid_e.append([])
		_grid_a.append([])
	flags_in = opts.get("flags", [])
	_setup_nexi()
	_setup_portals()
	_setup_towers()
	_setup_casters(party, opts)
	_setup_objective()
	_apply_story_mods(opts)
	_setup_orbs()
	_setup_zone_mechanics()
	terrain.setup(self)
	don = opts.get("don", {})
	don_t = float(don.get("cd", 60.0)) * 0.3
	for pd in level.get("pools", []):
		terrain.add_poison(Vector2(float(pd["x"]), float(pd["y"])), float(pd.get("r", 1.2)), 0.0, true)
	for idd in level.get("ice", []):
		terrain.add_ice(Vector2(float(idd["x"]), float(idd["y"])), float(idd.get("r", 1.3)))
	for e in level.get("initial_enemies", []):
		_spawn_enemy(str(e["kind"]), Vector2(float(e["x"]), float(e["y"])))
	wave_t = float(level["waves"].get("first", 3.0))
	_flush()
	_sync_nexus()
	_log("%s %s : %s" % [str(level.get("number", "")), str(level.get("name", "")), str(level.get("type", ""))])


func _setup_nexi() -> void:
	if objective == "boss":
		return
	var hp := float((level.get("nexus", {}) as Dictionary).get("hp", 10000)) * OBJECTIVE_HP_MULT * diff
	var spots: Array = level.get("nexi", [{"x": NEXUS_POS.x, "y": NEXUS_POS.y}])
	for sp in spots:
		nexi.append({"pos": Vector2(float(sp["x"]), float(sp["y"])), "hp": hp, "max": hp, "alive": true, "flash": 0.0, "wither": 0.0})


func _setup_objective() -> void:
	if objective == "boss":
		var bd: Dictionary = level["boss"]
		boss = _make_unit(str(bd["kind"]), 1, Vector2(float(bd.get("x", 4.5)), float(bd.get("y", 14.4))))
		boss.hp = float(bd["hp"]) * OBJECTIVE_HP_MULT * diff
		boss.max_hp = boss.hp
		boss.hold_y = boss.pos.y
		boss.elite = true
		boss_name = str(units_db[boss.kind].get("name", "Boss"))
		_pending_enemies.append(boss)
		_enter_phase(0)
	elif objective == "escort":
		var ed: Dictionary = level["escort"]
		escort = _make_unit(str(ed.get("kind", "lantern")), 0, Vector2(float(ed.get("x", 4.5)), float(ed.get("y", 1.6))))
		escort.hp = float(ed.get("hp", 300)) * ESCORT_HP_MULT
		escort.max_hp = escort.hp
		escort.speed = float(ed.get("speed", 0.1))
		escort_start_y = escort.pos.y
		escort_goal_y = float(ed.get("goal_y", 13.8))
		_pending_allies.append(escort)


## « story_mods » du niveau : bonus ou malus selon les drapeaux de l'histoire (opts.flags).
func _apply_story_mods(opts: Dictionary) -> void:
	orb_cfg = level.get("orbs", {})
	var flags: Array = opts.get("flags", [])
	for m in level.get("story_mods", []):
		var need := str(m.get("if", ""))
		if need != "" and not flags.has(need):
			continue
		if m.has("barrier_shield"):
			barrier_shield += float(m["barrier_shield"])
		if m.has("mana"):
			casters[0].mana = minf(casters[0].mana_max, casters[0].mana + float(m["mana"]))
		if m.has("orbs"):
			orb_cfg = m["orbs"]
		if m.has("dragons"):
			# Les dragons hostiles (l'Œuf de cendre volé, acte 6) survolent aussi la zone.
			story_dragons = m["dragons"]
		if bool(m.get("no_tide", false)):
			story_no_tide = true
		if m.has("warn_bonus"):
			warn_bonus = float(m["warn_bonus"])
		if m.has("boss_hp") and boss != null:
			boss.hp = boss.max_hp * clampf(float(m["boss_hp"]), 0.05, 1.0)
		if m.has("riddle_need"):
			riddle_need = int(m["riddle_need"])
		if m.has("forge_mult"):
			forge_power *= float(m["forge_mult"])
		if m.has("budget_mult"):
			wave_budget_mult *= float(m["budget_mult"])
		if m.has("pool_add"):
			# Nouvelles unités dans les vagues (ex. Sentinelles anciennes réveillées) : copie du niveau.
			level = level.duplicate(true)
			var pool: Dictionary = level["waves"]["pool"]
			var add: Dictionary = m["pool_add"]
			for k in add.keys():
				pool[k] = float(pool.get(k, 0.0)) + float(add[k])
		if m.has("log"):
			_log(str(m["log"]))
			story_notes.append(str(m["log"]))


func _setup_zone_mechanics() -> void:
	fog_cfg = level.get("fog", {})
	for k in range(int(fog_cfg.get("count", 0))):
		_add_fog(rng.randf_range(1.5, W - 1.5), rng.randf_range(float(fog_cfg.get("y_min", 5.0)), float(fog_cfg.get("y_max", 12.0))))
	wind_cfg = level.get("wind", {})
	if not wind_cfg.is_empty():
		wind_t = float(wind_cfg.get("first", 8.0))
	for pd in level.get("pylons", []):
		pylons.append({"pos": Vector2(float(pd["x"]), float(pd["y"])), "portal": int(pd.get("portal", 0)),
			"every": float(pd.get("every", 14.0)), "dur": float(pd.get("dur", 5.0)), "t": float(pd.get("first", 6.0))})
	avalanche_cfg = level.get("avalanche", {})
	if not avalanche_cfg.is_empty():
		avalanche_t = float(avalanche_cfg.get("first", 12.0))
	daynight_cfg = level.get("daynight", {})
	if not daynight_cfg.is_empty():
		is_day = str(daynight_cfg.get("start", "jour")) == "jour"
		daynight_t = float(daynight_cfg.get("day" if is_day else "night", 30.0))
	mirage_reform = float(level.get("mirage_reform", 12.0))
	wildfire_cfg = level.get("wildfire", {})
	# Le feu ne suit pas le niveau des ennemis : il se règle sur les PV des invocations (environ 1 s pour en brûler une).
	fire_dps = float(wildfire_cfg.get("dps", level.get("fire_dps", 9.0))) * diff
	if not wildfire_cfg.is_empty():
		wildfire_t = float(wildfire_cfg.get("first", 12.0))
	dragon_cfg = level.get("dragons", story_dragons)
	if not dragon_cfg.is_empty():
		dragon_t = float(dragon_cfg.get("first", 14.0))
	tide_cfg = {} if story_no_tide else level.get("tide", {})
	if not tide_cfg.is_empty():
		tide_state = "low"
		tide_y = float(tide_cfg.get("low_y", 2.0))
		tide_t = float(tide_cfg.get("first", tide_cfg.get("low", 20.0)))
	for cd in level.get("currents", []):
		currents.append({"y": float(cd["y"]), "h": float(cd.get("h", 1.4)), "dir": float(cd.get("dir", 1.0)),
			"speed": float(cd.get("speed", 0.8)), "flip": float(cd.get("flip", 0.0)), "t": float(cd.get("flip", 0.0))})
	whirl_dps = 8.0 * diff
	for ld in level.get("lava", []):
		add_fire_patch(Vector2(float(ld["x"]), float(ld["y"])), float(ld.get("r", 1.0)), 0.0, "magma")
	for md in level.get("mirrors", []):
		# Miroirs de verre : immobiles, ils renvoient les tirs et, le jour, projettent un rayon de soleil.
		var mr := _spawn_enemy(str(md.get("kind", "glass_mirror")), Vector2(float(md["x"]), float(md["y"])))
		mr.hold_y = mr.pos.y


## Vent des steppes : calme, puis rafale annoncée (l'herbe ploie), puis poussée latérale.
func _update_wind() -> void:
	if wind_cfg.is_empty():
		return
	wind_t -= TICK
	if wind_t > 0.0:
		return
	match wind_state:
		"calm":
			wind_state = "warn"
			wind_dir = -1.0 if rng.randf() < 0.5 else 1.0
			wind_t = float(wind_cfg.get("warn", 1.6))
			_event({"t": "wind", "dir": wind_dir, "phase": "warn", "dur": wind_t})
			_log("Le vent se lève vers la %s…" % ("droite" if wind_dir > 0.0 else "gauche"))
		"warn":
			wind_state = "blow"
			wind_t = float(wind_cfg.get("dur", 2.6))
			_event({"t": "wind", "dir": wind_dir, "phase": "blow", "dur": wind_t})
		_:
			wind_state = "calm"
			var ev: Array = wind_cfg.get("every", [10, 14])
			wind_t = rng.randf_range(float(ev[0]), float(ev[1]))


func _wind_push(u: Unit) -> float:
	if wind_state != "blow" or u.hold_y > 0.0 or u.role in ["boss", "banniere", "escort"] or u.speed <= 0.0:
		return 0.0
	return wind_dir * float(wind_cfg.get("force", 1.1)) / maxf(1.0, u.weight * 0.7)


## Pylônes d'ambre : chacun surcharge régulièrement son portail (Foudre et ×2 pendant quelques secondes).
func _update_pylons() -> void:
	for py in pylons:
		py["t"] = float(py["t"]) - TICK
		if float(py["t"]) <= 0.0:
			py["t"] = float(py["every"])
			var i := int(py["portal"])
			if i >= 0 and i < portals.size():
				portals[i].charged_t = float(py["dur"])
				_event({"t": "beam", "a": py["pos"], "b": Vector2(portals[i].x, portals[i].y), "color": "F0D23C", "dur": 0.5, "w": 3.0})
				_event({"t": "ring", "pos": Vector2(portals[i].x, portals[i].y), "r": 1.2, "color": "F0D23C", "dur": 0.5})
				_log("Un pylône d'ambre surcharge un portail !")
	for p in portals:
		p.charged_t = maxf(0.0, p.charged_t - TICK)


## Fin d'escorte, selon ce qu'on escorte (Lanterne, chariot, barque).
func _escort_text(kind: String, arrived: bool) -> String:
	match kind:
		"lantern":
			return "La Lanterne de l'Aube purifie le Nexus !" if arrived else "La Lanterne s'est éteinte…"
		"barge":
			return "La barque des passeurs a traversé le marais !" if arrived else "La barque a sombré…"
		"rune_cart":
			return "Le chariot runique a atteint la forteresse !" if arrived else "Le chariot runique est brisé…"
	return "Le chariot de vivres est arrivé !" if arrived else "Le chariot est détruit…"


func heads_alive() -> int:
	var n := 0
	for h in heads:
		if h.alive:
			n += 1
	return n


# ---------------------------------------------------------------- zone 3 : brume, têtes de l'Hydre

const MAX_FOG := 4


func _add_fog(x: float, y: float) -> void:
	if fog.size() >= MAX_FOG:
		# Brume déjà épaisse : le banc le plus dissipé se reforme ailleurs.
		var thin: Dictionary = fog[0]
		for f in fog:
			if float(f["density"]) < float(thin["density"]):
				thin = f
		thin["pos"] = Vector2(x, y)
		thin["density"] = 1.0
		return
	var r := float(fog_cfg.get("r", 2.2))
	var sp := float(fog_cfg.get("speed", 0.25))
	fog.append({"pos": Vector2(x, y), "r": r, "density": 1.0, "vx": sp if rng.randf() < 0.5 else -sp})


## Bancs de brume : ils dérivent, cachent les ennemis (-20 % de dégâts subis) et se reforment ;
## les invocations de Lumière les dissipent en les traversant.
func _update_fog() -> void:
	for e in enemies:
		e.fogged = false
	for f in fog:
		var p: Vector2 = f["pos"]
		var r := float(f["r"])
		p.x += float(f["vx"]) * TICK
		if p.x < r * 0.5 or p.x > W - r * 0.5:
			f["vx"] = -float(f["vx"])
		f["pos"] = p
		var lights := 0
		for a in _query(_grid_a, p, r):
			if a.alive and a.element == "lumiere":
				lights += 1
		var d := float(f["density"])
		if lights > 0:
			d -= 0.03 * float(mini(lights, 10)) * TICK * 10.0
		else:
			d += 0.04 * TICK
		f["density"] = clampf(d, 0.0, 1.0)
		if float(f["density"]) < 0.35:
			continue
		for e in _query(_grid_e, p, r):
			if e.alive and e.pos.distance_to(p) <= r and e.role != "boss":
				e.fogged = true


## Dissipe la brume autour d'un point (Purifier). Retourne vrai si un banc a été touché.
func clear_fog(at: Vector2, r: float) -> bool:
	var hit := false
	for f in fog:
		if (f["pos"] as Vector2).distance_to(at) <= r + float(f["r"]):
			f["density"] = 0.0
			hit = true
	if hit:
		_event({"t": "ring", "pos": at, "r": r + 1.0, "color": "FFF6C8", "dur": 0.6})
		_log("La lumière dissipe la brume.")
	return hit


## Plaies de l'Hydre : brûlées (Feu) dans les 5 s, elles se referment ; sinon deux têtes repoussent.
func _update_stumps() -> void:
	for w in ult_wards:
		w["t"] = float(w["t"]) - TICK
	ult_wards = ult_wards.filter(func(w: Dictionary) -> bool: return float(w["t"]) > 0.0)
	var i := 0
	while i < stumps.size():
		var st: Dictionary = stumps[i]
		st["t"] = float(st["t"]) - TICK
		# Une invocation de Feu au contact de la plaie la cautérise.
		for a in _query(_grid_a, st["pos"], 0.9):
			if a.alive and a.element == "feu":
				st["t"] = -99.0
				break
		for w in ult_wards:
			if (w["pos"] as Vector2).distance_to(st["pos"]) <= float(w["r"]) + 0.4:
				st["t"] = -99.0
		# Un sol de braises sur la plaie la cautérise aussi.
		for s in terrain.surfaces:
			if str(s["kind"]) == "braises" and (s["pos"] as Vector2).distance_to(st["pos"]) <= float(s["r"]) + 0.4:
				st["t"] = -99.0
		if float(st["t"]) <= -50.0:
			_event({"t": "text", "pos": st["pos"], "text": "CAUTÉRISÉE !", "color": "FFB04A"})
			_log("Plaie cautérisée : la tête ne repoussera pas.")
			stumps.remove_at(i)
			continue
		if float(st["t"]) <= 0.0:
			var n := 0
			for k in range(2):
				if heads_alive() >= MAX_HEADS:
					break
				_spawn_head(st["pos"] + Vector2((float(k) - 0.5) * 1.1, 0.0))
				n += 1
			if n > 0:
				_log("%d têtes repoussent !" % n)
				_event({"t": "text", "pos": st["pos"], "text": "×%d TÊTES !" % n, "color": "9AD03A"})
			stumps.remove_at(i)
			continue
		i += 1


func _spawn_head(p: Vector2) -> Unit:
	var h := _spawn_enemy("hydra_head", Vector2(clampf(p.x, 0.8, W - 0.8), p.y))
	h.hold_y = h.pos.y
	heads.append(h)
	_event({"t": "ring", "pos": h.pos, "r": 0.9, "color": "9AD03A", "dur": 0.5})
	return h


## Feu qui touche une plaie : elle est cautérisée.
func burn_stumps(at: Vector2, r: float) -> void:
	for st in stumps:
		if (st["pos"] as Vector2).distance_to(at) <= r + 0.6:
			st["t"] = -99.0


func banners_alive() -> int:
	var n := 0
	for b in banners:
		if b.alive:
			n += 1
	return n


func _setup_orbs() -> void:
	if orb_cfg.is_empty():
		return
	for i in range(int(orb_cfg.get("count", 5))):
		orbs.append({"pos": _orb_spot(), "alive": true, "t": 0.0})


func _orb_spot() -> Vector2:
	return Vector2(rng.randf_range(0.8, W - 0.8), rng.randf_range(2.6, 11.8))


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
		p.mirage = bool(pd.get("mirage", false))
		p.spots = pd.get("spots", [])
		portals.append(p)
		if p.is_seal:
			seals_total += 1
	portals.sort_custom(func(a: Portal, b: Portal) -> bool: return a.y < b.y)


func _setup_towers() -> void:
	for td in level.get("towers", []):
		var hp := float(td.get("hp", 300)) * enemy_mult
		towers.append({
			"pos": Vector2(float(td["x"]), float(td["y"])), "hp": hp, "max": hp,
			"atk": float(td.get("atk", 12)) * enemy_mult * diff, "range": float(td.get("range", 3.0)),
			"interval": float(td.get("interval", 1.0)), "cd": 1.0, "r": 0.45, "alive": true, "flash": 0.0,
		})


func _setup_casters(party: Dictionary, opts: Dictionary = {}) -> void:
	var classes: Dictionary = party["classes"]
	var races: Dictionary = party["races"]
	var pd: Dictionary = (party["player"] as Dictionary).duplicate()
	if opts.has("player_level"):
		pd["level"] = int(opts["player_level"])
	if opts.has("weapon_element"):
		pd["weapon_element"] = str(opts["weapon_element"])
	if opts.has("player_race") and (races as Dictionary).has(str(opts["player_race"])):
		pd["race"] = str(opts["player_race"])
	if opts.has("look"):
		# Sprite du héros dessiné selon son apparence (SpriteAtlas « player »).
		pd["sprite"] = "player"
	if opts.has("player_class") and classes.has(str(opts["player_class"])) and bool((classes[str(opts["player_class"])] as Dictionary).get("playable", false)):
		pd["class"] = str(opts["player_class"])
	var pc := _make_caster(0, pd, classes, races, opts.get("gear", {}))
	pc.min_x = 0.5
	pc.max_x = W - 0.5
	pc.x = W * 0.5
	pc.prev_x = pc.x
	pc.target_x = pc.x
	for s in opts.get("deck", pd["deck"]):
		if spells_db.has(str(s)):
			pc.spells.append(str(s))
	pc.crit += _mod("crit")
	pc.mana_regen *= 1.0 + _mod("mana_regen")
	if bool(opts.get("debug_mana", false)):
		pc.mana_regen *= 20.0
	spell_cost_mult *= 1.0 - _mod("spell_cost")
	pc.cadence *= 1.0 + _mod("cadence")
	var cls: Dictionary = classes[pc.class_id]
	pc.familiar = str(cls.get("player_familiar", pc.familiar))
	effect_mult = float(cls.get("effect_mult", 1.0))
	champion_kind = str(cls.get("champion", "champion_golem"))
	ultimate_id = str(cls.get("ultimate", "meteore"))
	barrier_max = roundf((100.0 + float(pc.stats["vig"]) * 0.5) * (1.0 + _mod("barrier_max")))
	barrier_hp = barrier_max
	# Rune Gard sur un bijou : bouclier de Barrière dès le départ.
	barrier_shield += _mod("start_shield")
	if autoplay:
		pc.brain = BotBrain.new()
		pc.think_interval = 0.35
		pc.aim_error = 0.3
	casters.append(pc)
	if solo:
		return
	var allowed: Variant = level.get("party", null)
	var active: Array = opts.get("active", [])
	var flags: Array = opts.get("flags", [])
	# Candidats : autorisés par le niveau et déjà recrutés. Au-delà de 2, ceux choisis au Cercle.
	var cands: Array[Dictionary] = []
	for bd in party["bots"]:
		var bid := str(bd.get("id", ""))
		if allowed is String and str(allowed) == "traitre":
			# « Les Cendres du Pardon » : seul le compagnon marqué combat à tes côtés.
			if flags.has("s1.traitre_" + bid):
				cands.append(bd)
			continue
		if allowed is Array and not (allowed as Array).has(bid):
			continue
		if str(bd.get("requires", "")) != "" and not flags.has(str(bd["requires"])):
			continue
		if Story.companion_lost(bid, flags if not flags.is_empty() else ["-"]):
			continue
		cands.append(bd)
	var chosen: Array[Dictionary] = []
	for bd in cands:
		if cands.size() <= 2 or active.is_empty() or active.has(str(bd.get("id", ""))):
			chosen.append(bd)
	for bd in cands:
		if chosen.size() >= 2:
			break
		if not chosen.has(bd):
			chosen.append(bd)
	chosen.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return cands.find(x) < cands.find(y))
	for bi in range(chosen.size()):
		var bd: Dictionary = chosen[bi]
		var bdd: Dictionary = (bd as Dictionary).duplicate()
		if opts.has("bot_level"):
			bdd["level"] = int(opts["bot_level"])
		# Progression propre du compagnon (étape 13.4) : niveau, voie (classe) et équipement.
		var mine_bot: Dictionary = (opts.get("bots", {}) as Dictionary).get(str(bd.get("id", "")), {})
		var bot_gear: Dictionary = mine_bot.get("gear", {})
		if mine_bot.has("level"):
			bdd["level"] = int(mine_bot["level"])
		if mine_bot.has("class") and classes.has(str(mine_bot["class"])):
			bdd["class"] = str(mine_bot["class"])
		if mine_bot.has("weapon_element"):
			bdd["weapon_element"] = str(mine_bot["weapon_element"])
		# Réglages du Cercle : ordre par défaut, sort emporté, côtés échangés, amitié.
		var circ: Dictionary = opts.get("circle", {})
		var mine: Dictionary = circ.get(str(bd.get("id", "")), {})
		if mine.has("order"):
			bdd["order"] = str(mine["order"])
		if mine.has("spell") and spells_db.has(str(mine["spell"])):
			bdd["spells"] = [str(mine["spell"])]
		var class_fire := str(mine.get("fire", "")) == "classe"
		var heritage := flags.has("s1.heritage_" + str(bd.get("id", "")))
		if heritage:
			# Héritage de cendre : Sang du Wyrm (familiers de Feu, +15 %), Souffle de cendre, aura de braise.
			bdd["weapon_element"] = "feu"
			bdd["sprite"] = str(bd.get("sprite", "")) + "_cendre"
			var sps: Array = (bdd.get("spells", []) as Array).duplicate()
			if not sps.has("souffle_de_cendre"):
				sps.append("souffle_de_cendre")
			bdd["spells"] = sps
			_ash_renew = true
		var c := _make_caster(casters.size(), bdd, classes, races, bot_gear)
		if heritage:
			c.atk_mult *= 1.15
		c.is_bot = true
		c.class_fire = class_fire
		c.side = str(bd.get("side", "left"))
		if chosen.size() == 2:
			c.side = "left" if bi == 0 else "right"
		if bool(circ.get("swap", false)):
			c.side = "right" if c.side == "left" else "left"
		if int((opts.get("loyalty", {}) as Dictionary).get(c.id, 50)) >= 75:
			c.atk_mult *= 1.05
			c.hp_mult *= 1.05
		# Totem (Berserker) : Cri de guerre, Clé de voûte Chef de clan (+30 %).
		var clan := 1.0 + _mod("bot_atk") + (0.3 if _mod("clan_chief") > 0.0 else 0.0)
		c.atk_mult *= clan
		c.hp_mult *= 1.0 + (0.3 if _mod("clan_chief") > 0.0 else 0.0)
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
		c.order = str(bdd.get("order", "libre"))
		c.think_interval = float(bd.get("think", 0.4))
		c.aim_error = float(bd.get("aim_error", 0.4))
		c.cadence *= float(bd.get("cadence_mult", 1.0))
		for s in bdd.get("spells", []):
			c.spells.append(str(s))
		c.brain = BotBrain.new()
		c.firing = true
		casters.append(c)


func _make_caster(idx: int, d: Dictionary, classes: Dictionary, races: Dictionary, gear: Dictionary = {}) -> Caster:
	var c := Caster.new()
	c.idx = idx
	c.id = str(d.get("id", "player" if idx == 0 else ""))
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
		c.stats[k] = b + b / 10.0 * float(c.level - 1) + float(race.get(k, 0)) + float(gear.get(k, 0))
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
	don_t = maxf(0.0, don_t - TICK)
	rally_t = maxf(0.0, rally_t - TICK)
	breeze_t = maxf(0.0, breeze_t - TICK)
	charge_t = maxf(0.0, charge_t - TICK)
	barrier_invuln_t = maxf(0.0, barrier_invuln_t - TICK)
	_update_casters()
	if _mod("barrier_regen") > 0.0 and barrier_hp > 0.0:
		# Clé de voûte Aube éternelle : la Barrière se répare lentement.
		barrier_hp = minf(barrier_max, barrier_hp + _mod("barrier_regen") * TICK)
	if _bheal_t > 0.0 and barrier_hp > 0.0:
		# Prière fervente, Renouveau… : la Barrière se soigne pendant quelques secondes.
		_bheal_t -= TICK
		barrier_hp = minf(barrier_max, barrier_hp + _bheal_rate * TICK)
		if _bheal_t <= 0.0:
			_bheal_rate = 0.0
	_update_portals()
	_update_waves()
	_update_wind()
	_update_pylons()
	_update_avalanche()
	_update_wildfire()
	_update_dragons()
	_update_tide()
	_update_currents()
	_update_daynight()
	_update_riddle()
	_update_gate_curses()
	_move_units()
	_cross_portals()
	_tick_status()
	_build_grids()
	ClassFire.hits(self)
	_update_impacts()
	_update_zones()
	_update_fog()
	_update_stumps()
	_update_fires()
	_update_whirlpools()
	terrain.update()
	_resolve_contacts()
	_ranged_attacks()
	_towers_attack()
	_enemy_abilities()
	_update_boss()
	_update_telegraphs()
	_update_orbs()
	_update_ambush()
	_nexus_pulse()
	_reach_checks()
	_flush()
	_sync_nexus()
	peak_allies = maxi(peak_allies, allies.size())
	_check_end()


func _update_casters() -> void:
	if not class_spawns.is_empty():
		ClassFire.update_spawns(self, TICK)
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
			# Le tir se recharge pendant qu'on ne tire pas : un nouvel appui tire aussitôt si l'intervalle est passé.
			c.fire_acc = minf(1.0, c.fire_acc + TICK * ClassFire.rate(self, c))
			continue
		if c.idx == 0:
			# Le Champion se charge au même rythme pour toutes les classes (l'ancien Flux : 4 par seconde).
			_champ_acc += TICK * c.cadence * cadence_mult * (1.5 if breeze_t > 0.0 else 1.0)
			while _champ_acc >= 1.0:
				_champ_acc -= 1.0
				champion_charge = mini(champion_need, champion_charge + 1)
		# Tir normal propre à la classe (scripts/battle/class_fire.gd).
		c.fire_acc += TICK * ClassFire.rate(self, c)
		while c.fire_acc >= 1.0:
			c.fire_acc -= 1.0
			ClassFire.volley(self, c)


func _update_portals() -> void:
	for p in portals:
		if p.mirage:
			_update_mirage(p)
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
		* (1.0 + float(wd.get("growth", 0.04)) * float(wave_index)) * wave_budget_mult
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
			# Soigneur au plafond : on le remplace par l'unité la plus courante de la vague.
			pick = str(kinds[0])
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
		if u.shot != "":
			ClassFire.move(self, u)
			continue
		u.anim += TICK
		if u.rise_t > 0.0:
			# Squelette qui sort de terre : il n'avance qu'une fois debout.
			u.rise_t -= TICK
			continue
		if u.role == "escort":
			if not u.engaged and u.speed_factor() > 0.0:
				u.pos.y = minf(escort_goal_y, u.pos.y + u.speed * u.speed_factor() * TICK)
			continue
		if u.engaged:
			continue
		var sf := u.speed_factor()
		if sf <= 0.0:
			continue
		sf *= _slide(u) * _water(u)
		if u.pos.y > HOMING_Y:
			u.vx = clampf((_homing_target_x(u) - u.pos.x) * 1.5, -1.8, 1.8)
		u.pos.x = clampf(u.pos.x + u.vx * sf * TICK + (_wind_push(u) + _current_push(u)) * TICK, 0.2, W - 0.2)
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
		var sf_e := e.speed_factor() * _slide(e) * _water(e)
		if escort != null and escort.alive and e.pos.y > escort.pos.y and e.pos.y - escort.pos.y < 4.0:
			# Les ennemis convergent vers la Lanterne de l'Aube.
			e.pos.x = clampf(e.pos.x + clampf(escort.pos.x - e.pos.x, -0.9, 0.9) * sf_e * TICK, 0.3, W - 0.3)
		e.pos.y = terrain.block_y(e, e.pos.y - e.speed * sf_e * TICK) if not terrain.walls.is_empty() else e.pos.y - e.speed * sf_e * TICK
		e.pos.x = clampf(e.pos.x + (_wind_push(e) + _current_push(e)) * TICK, 0.3, W - 0.3)


func _homing_target_x(u: Unit) -> float:
	for t in towers:
		if t["alive"] and absf(u.pos.x - (t["pos"] as Vector2).x) < 1.3:
			return (t["pos"] as Vector2).x
	if boss != null and boss.alive:
		# Colosse runique : une invocation de l'élément d'une rune va droit sur elle.
		for ru in runes:
			if ru.alive and ru.element == u.element:
				return ru.pos.x
		return boss.pos.x
	var best := NEXUS_POS.x
	var bd := 1e9
	for n in nexi:
		if n["alive"]:
			var d := absf((n["pos"] as Vector2).x - u.pos.x)
			if d < bd:
				bd = d
				best = (n["pos"] as Vector2).x
	return best


# ---------------------------------------------------------------- portails

func _cross_portals() -> void:
	for u in allies:
		if not u.alive or u.role == "escort":
			continue
		for p in portals:
			if not p.active():
				continue
			if u.prev_pos.y < p.y and u.pos.y >= p.y and absf(u.pos.x - p.x) <= p.width * 0.5 and not u.crossed.has(p.id):
				u.crossed[p.id] = true
				_apply_portal(p, u)
				if not u.alive:
					break


func _apply_portal(p: Portal, u: Unit) -> void:
	p.flash_t = 0.2
	if p.mirage:
		# Mirage (zone 5) : l'invocation passe au travers, sans effet, et le mirage se dissipe.
		_reveal_mirage(p)
		return
	if p.kind == "answer":
		# Énigme du Sphinx : seules les invocations du héros répondent ; la première réponse qui en
		# reçoit assez est retenue.
		if u.owner_idx != 0:
			return
		p.counter += 1
		if p.counter >= p.need and not riddle.is_empty():
			_resolve_riddle(p.id == int(riddle["right"]))
		return
	if u.owner_idx == 0 and (u.attack_range > 0.0 or u.shot != "") and _mod("portal_split") > 0.0 and not p.is_negative() and rng.randf() < _mod("portal_split"):
		# Flèches astrales : un tireur du joueur se divise en passant un portail.
		_add_ally(_clone(u, Vector2(rng.randf_range(-0.3, 0.3), -0.06)))
	if p.charged_t > 0.0 and not p.is_negative():
		u.element = "foudre"
		_add_ally(_clone(u, Vector2(rng.randf_range(-0.3, 0.3), -0.08)))
	if p.is_negative() and u.wings:
		# Fée (Ailes) : le premier portail négatif est survolé.
		u.wings = false
		return
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
				var bonus_a := 1 if u.owner_idx == 0 and _mod("portal_plus") > 0.0 and rng.randf() < _mod("portal_plus") else 0
				for i in range(p.value + extra_number + bonus_a):
					_add_ally(_clone(u, Vector2(rng.randf_range(-0.4, 0.4), -0.12 - 0.1 * float(i % 4))))
				_event({"t": "text", "pos": Vector2(p.x, p.y + 0.5), "text": "+%d" % (p.value + extra_number), "color": "4FE3D2"})
		"mult":
			var bonus := 1 if u.owner_idx == 0 and _mod("portal_plus") > 0.0 and rng.randf() < _mod("portal_plus") else 0
			for i in range(p.value - 1 + extra_number + bonus):
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
			u.scale *= 1.3
			u.speed *= 0.8
		"haste":
			u.speed *= 1.4
		"aegis":
			u.shield += 10.0
		"forge":
			# Porte naine (zone 4) : l'invocation ressort cuirassée (deux fois plus si les Portes sont réactivées).
			u.defense += 10.0 * forge_power
			u.hp *= 1.0 + 0.25 * forge_power
			u.max_hp *= 1.0 + 0.25 * forge_power
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
	if _mod("purify_double") > 0.0 and not p.is_seal and not (p.kind == "mult" and p.value >= 2):
		# Clé de voûte (Aube) de la Purification : le portail purifié devient ×2.
		p.kind = "mult"
		p.value = 2
		p.ready = true
	_event({"t": "ring", "pos": Vector2(p.x, p.y), "r": 1.5, "color": "FFF6C8", "dur": 0.7})
	_log("Portail purifié")
	if p.is_seal and not nexus_shielded():
		_log("Sceaux brisés : le Nexus est vulnérable !")
		for n in nexi:
			_event({"t": "ring", "pos": n["pos"], "r": 2.0, "color": "FFF6C8", "dur": 0.9})
	return true


func nexus_shielded() -> bool:
	if objective == "escort":
		return true
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
	u.atk = float(d.get("atk", 10)) * m * (diff if team == 1 else 1.0)
	u.defense = float(d.get("def", 0))
	u.speed = float(d.get("speed", 2.0)) * (diff if team == 1 else 1.0)
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
	u.heal_aura = float(d.get("heal_aura", 0.0))
	u.lifesteal = float(d.get("lifesteal", 0.0))
	u.reflect = float(d.get("reflect", 0.0))
	u.anim = rng.randf() * 10.0
	return u


## « k_atk », « k_hp », « size », « rise » : troupes renforcées (squelettes du Nécromancien : ×2, ×2, 1,1,
## sortie de terre).
func _spawn_familiar(c: Caster, p: Vector2, k_atk: float = 1.0, k_hp: float = 1.0, size: float = 1.0, rise: float = 0.0) -> Unit:
	var u := _make_unit(c.familiar, 0, p)
	u.owner_idx = c.idx
	u.atk *= c.atk_mult * k_atk
	u.hp *= c.hp_mult * k_hp
	u.scale = size
	u.radius *= size
	u.rise_t = rise
	if c.idx == 0:
		_player_unit_mods(u)
	u.max_hp = u.hp
	u.crit = c.crit
	if u.element == "physique":
		u.element = c.element
	summoned += 1
	_add_ally(u)
	if c.idx == 0 and _mod("free_clone") > 0.0 and rng.randf() < _mod("free_clone"):
		# Rune Mult sur une arme : l'invocation arrive parfois en double.
		_add_ally(_clone(u, Vector2(rng.randf_range(-0.3, 0.3), -0.1)))
	if c.idx == 0 and _mod("ghost_double") > 0.0 and rng.randf() < _mod("ghost_double"):
		# Double fantôme (Lame spectrale) : l'invocation surgit avec son double.
		_add_ally(_clone(u, Vector2(rng.randf_range(-0.3, 0.3), -0.1)))
	return u


## Passifs de race et arbre d'héritage sur une invocation du joueur.
func _player_unit_mods(u: Unit) -> void:
	u.speed *= 1.0 + _mod("unit_speed")
	u.atk *= 1.0 + _mod("unit_atk")
	u.hp *= 1.0 + _mod("unit_hp")
	u.defense += 20.0 * _mod("unit_def")
	if u.attack_range > 0.0:
		u.attack_range *= 1.0 + _mod("unit_range")
	if _mod("fairy_wings") > 0.0:
		u.wings = true
	if u.kind in ["skeleton", "familiar_necro"] and _mod("skeleton_bonus") > 0.0:
		u.atk *= 1.0 + _mod("skeleton_bonus")
		u.hp *= 1.0 + _mod("skeleton_bonus")
	u.lifesteal += _mod("lifesteal")
	if _mod("spawn_shield") > 0.0:
		# Rune de protection (Garde runique) : bouclier à l'invocation.
		u.shield = maxf(u.shield, u.hp * _mod("spawn_shield"))
	if u.heal_aura > 0.0:
		u.heal_aura *= 1.0 + _mod("aura_heal")
	if u.kind in ["skeleton", "familiar_necro"] and _mod("legion") > 0.0:
		# Clé de voûte Légion : tous les 20 squelettes, un Colosse d'os se lève.
		_legion_count += 1
		if _legion_count >= 20:
			_legion_count = 0
			var g := _make_unit("champion_bone", 0, u.pos)
			g.owner_idx = 0
			g.atk *= casters[0].atk_mult if not casters.is_empty() else 1.0
			g.hp *= casters[0].hp_mult if not casters.is_empty() else 1.0
			g.max_hp = g.hp
			_pending_allies.append(g)
			_event({"t": "summon", "pos": g.pos, "dur": 0.9, "color": "B8B0C8"})
			_log("Légion : un Colosse d'os se lève !")


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
	c.heal_aura = u.heal_aura
	c.lifesteal = u.lifesteal
	c.crit_mult = u.crit_mult
	c.wings = u.wings
	c.crossed = u.crossed.duplicate()
	c.anim = rng.randf() * 10.0
	c.scale = u.scale
	if u.shot != "":
		# Un tir dédoublé par un portail garde sa course : mêmes ennemis déjà touchés, même portée.
		c.shot = u.shot
		c.pierce = u.pierce
		c.travel = u.travel
		c.hit_ids = u.hit_ids.duplicate()
		c.anim = u.anim
		c.frenzy_t = u.frenzy_t
		c.buff_t = u.buff_t
		c.buff_atk = u.buff_atk
		c.buff_crit = u.buff_crit
		c.buff_steal = u.buff_steal
		return c
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
		u.enraged_t = maxf(0.0, u.enraged_t - TICK)
		if u.flash_t > 0.0:
			u.flash_t -= TICK
		if u.burn_t > 0.0:
			u.burn_t -= TICK
			_damage(u, u.burn_dps * TICK, "feu")
			if u.burn_t <= 0.0:
				u.burn_dps = 0.0
		if u.bleed_t > 0.0 and u.alive:
			u.bleed_t -= TICK
			_damage(u, u.bleed_dps * TICK, "physique")
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
		u.marked_t = maxf(0.0, u.marked_t - TICK)
		u.weak_t = maxf(0.0, u.weak_t - TICK)
	var regen := _mod("unit_regen")
	_dance_budget = minf(1.0, _dance_budget + TICK)
	var last_stand := _mod("rage_low") > 0.0 and barrier_hp < barrier_max * 0.25
	if _mod("blood_rage") > 0.0 and time < frenzy_until and barrier_hp > 1.0:
		# Clé de voûte (Cendres) : la Rage consomme la Barrière.
		barrier_hp = maxf(1.0, barrier_hp - 1.5 * TICK)
	_thirst_budget = minf(2.0, _thirst_budget + 2.0 * TICK)
	for u in allies:
		if not u.alive:
			continue
		u.atk_cd -= TICK * (1.0 + u.buff_aspd)
		if u.buff_t > 0.0:
			u.buff_t -= TICK
			if u.buff_t <= 0.0:
				u.buff_atk = 0.0
				u.buff_crit = 0.0
				u.buff_aspd = 0.0
				u.buff_steal = 0.0
				u.buff_thorns = 0.0
		if u.life_t > 0.0:
			u.life_t -= TICK
			if u.life_t <= 0.0:
				# Invocation temporaire (Baliste, bêtes) : elle s'efface.
				u.alive = false
				_event({"t": "puff", "pos": u.pos, "color": "C8F5A0"})
				continue
		u.frenzy_t = maxf(0.0, u.frenzy_t - TICK)
		if last_stand:
			# Clé de voûte (Aube) : sous 25 % de Barrière, Rage permanente.
			u.frenzy_t = maxf(u.frenzy_t, 0.5)
		if u.heal_aura > 0.0:
			u.aura_t -= TICK
			if u.aura_t <= 0.0 and not _grid_a.is_empty():
				# Aura de soin : chaque seconde, les alliés proches regagnent des PV.
				u.aura_t = 1.0
				var amt := u.heal_aura * (1.0 + _mod("heal_bonus"))
				for a: Unit in _query(_grid_a, u.pos, 1.6):
					if a.alive:
						var miss: float = a.max_hp - a.hp
						a.hp = minf(a.max_hp, a.hp + amt)
						healed_total += minf(miss, amt)
						if amt > miss:
							_wrath_acc += amt - miss
		if regen > 0.0 and u.owner_idx == 0 and u.hp < u.max_hp:
			u.hp = minf(u.max_hp, u.hp + u.max_hp * regen * TICK)
		if u.flash_t > 0.0:
			u.flash_t -= TICK
		if u.slow_t > 0.0:
			u.slow_t -= TICK
			if u.slow_t <= 0.0:
				u.slow_stacks = 0
	for n in nexi:
		n["flash"] = maxf(0.0, float(n["flash"]) - TICK)
		n["wither"] = maxf(0.0, float(n["wither"]) - TICK)
	if _wrath_acc >= 20.0:
		_wrath(_wrath_acc)
		_wrath_acc = 0.0
	barrier_flash = maxf(0.0, barrier_flash - TICK)
	_immune_txt_t = maxf(0.0, _immune_txt_t - TICK)
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
		if a.alive and a.shot == "":
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
		if traitor_broken and u == traitor_unit:
			continue
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
		if not a.alive or a.shot != "":
			continue
		var best: Unit = null
		var best_d := 1e9
		var cx := clampi(int(a.pos.x), 0, GRID_W - 1)
		var cy := clampi(int(a.pos.y), 0, GRID_H - 1)
		for yy in range(maxi(0, cy - 1), mini(GRID_H - 1, cy + 1) + 1):
			for xx in range(maxi(0, cx - 1), mini(GRID_W - 1, cx + 1) + 1):
				for e in _grid_e[yy * GRID_W + xx]:
					if not e.alive or (e.role == "rune" and e.element != a.element) or (traitor_broken and e == traitor_unit):
						continue
					var rr: float = a.radius + e.radius
					var d2: float = a.pos.distance_squared_to(e.pos)
					if d2 <= rr * rr and d2 < best_d:
						best_d = d2
						best = e
		if best == null:
			continue
		if best == boss and boss.airborne_t > 0.0:
			# Boss en vol : l'invocation l'attend sous lui (seuls les tirs et les sorts l'atteignent).
			a.engaged = true
			continue
		if best == boss and not a.siege:
			# Comme sur un Nexus : l'invocation frappe une fois le boss et se dissipe.
			_hit(a, best)
			a.alive = false
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
		if t != null and t.role == "rune" and t.element != a.element:
			t = boss if boss != null and boss.alive and boss.pos.distance_to(a.pos) <= a.attack_range + boss.radius else null
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
			if boss != null and boss.alive:
				var amount_b := boss.max_hp * float(d["heal_boss"]) if d.has("heal_boss") else float(d.get("heal_nexus", 0.0)) * enemy_mult
				if bool(d.get("solar", false)) and is_day and not daynight_cfg.is_empty():
					amount_b *= 1.5
				if boss.wither_t > 0.0:
					amount_b *= 0.5
				amount_b = _steal_heal(amount_b)
				if boss.hp < boss.max_hp:
					var before_b := boss.hp
					boss.hp = minf(boss.max_hp, boss.hp + amount_b)
					healed_total += boss.hp - before_b
					_event({"t": "beam", "a": e.pos, "b": boss.pos, "color": "6FE39A", "dur": 0.35})
					_event({"t": "text", "pos": boss.pos + Vector2(1.4, -0.4), "text": "+%d" % int(boss.hp - before_b), "color": "6FE39A"})
					if _heal_log_t <= 0.0:
						_heal_log_t = 8.0
						_log("Les Fleurs-sèves soignent %s !" % boss_name)
			else:
				var target: Dictionary = {}
				var worst := 2.0
				for n in nexi:
					if n["alive"] and float(n["hp"]) / float(n["max"]) < worst:
						worst = float(n["hp"]) / float(n["max"])
						target = n
				var amount := float(d.get("heal_nexus", 0.0)) * enemy_mult
				if bool(d.get("solar", false)) and is_day and not daynight_cfg.is_empty():
					# Prêtresse solaire : ses soins sont plus forts le jour.
					amount *= 1.5
				if not target.is_empty() and float(target["wither"]) > 0.0:
					amount *= 0.5
				if amount > 0.0 and not target.is_empty() and float(target["hp"]) < float(target["max"]):
					amount = _steal_heal(amount)
				if amount > 0.0 and not target.is_empty() and float(target["hp"]) < float(target["max"]):
					var before := float(target["hp"])
					target["hp"] = minf(float(target["max"]), before + amount)
					healed_total += float(target["hp"]) - before
					_event({"t": "beam", "a": e.pos, "b": target["pos"], "color": "6FE39A", "dur": 0.35})
					_event({"t": "text", "pos": (target["pos"] as Vector2) + Vector2(1.0, -0.2), "text": "+%d" % int(float(target["hp"]) - before), "color": "6FE39A"})
					if _heal_log_t <= 0.0:
						_heal_log_t = 8.0
						_log("Soin ennemi : %s régénère le Nexus !" % str(d.get("name", "un soigneur")))
			var hu := float(d.get("heal_units", 0.0)) * (1.0 - clampf(_mod("anti_heal"), 0.0, 0.8))
			if hu > 0.0:
				for o in _query(_grid_e, e.pos, 1.5):
					if o != e and o != boss:
						o.hp = minf(o.max_hp, o.hp + _dot_base(o) * hu * (0.5 if o.wither_t > 0.0 else 1.0))
		elif e.role == "lanceur":
			var tgt := _nearest(_grid_a, e.pos, float(d.get("cast_range", 3.5)))
			if tgt == null:
				continue
			e.cast_cd = e.cast_interval
			var r := float(d.get("cast_radius", 1.0))
			var chill := float(d.get("cast_chill", 0.0))
			for a in _query(_grid_a, tgt.pos, r):
				_damage(a, e.atk * (1.3 if e.enraged_t > 0.0 else 1.0) * affinity(e.element, a.element), "")
				if chill > 0.0 and a.alive:
					# Élémentaire de blizzard : les invocations touchées sont engourdies.
					a.slow_stacks = maxi(a.slow_stacks, 3)
					a.slow_t = maxf(a.slow_t, chill)
			_event({"t": "ring", "pos": tgt.pos, "r": r, "color": "FFF2A8", "dur": 0.35})
			if d.has("ignite"):
				# Cultiste du Wyrm : sa boule de feu laisse un foyer.
				add_fire_patch(tgt.pos, float(d["ignite"]), 4.0, "cultiste")
			if d.has("blink") and e.pos.y > 7.5 and e.hold_y <= 0.0 and not e.engaged:
				# Spectre du Collège : il se dématérialise et réapparaît plus près de la Barrière.
				_event({"t": "puff", "pos": e.pos, "color": "8A7CC8"})
				e.pos.y -= float(d["blink"])
				e.prev_pos = e.pos
				_event({"t": "puff", "pos": e.pos, "color": "8A7CC8"})
		elif e.role == "oeuf":
			# Œuf de wyrm : il éclot en Wyverneaux.
			for k in range(int(d.get("hatch_count", 2))):
				if enemies.size() + _pending_enemies.size() >= MAX_ENEMIES:
					break
				_spawn_enemy(str(d.get("hatch", "wyvernling")), e.pos + Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.1)))
			_event({"t": "ring", "pos": e.pos, "r": 1.0, "color": "FF6A2A", "dur": 0.5})
			_event({"t": "text", "pos": e.pos + Vector2(0.0, 0.6), "text": "ÉCLOSION !", "color": "FFB04A"})
			_log("Un œuf éclot : des Wyverneaux !")
			e.alive = false
		elif e.role == "miroir":
			e.cast_cd = e.cast_interval
			if not daynight_cfg.is_empty() and not is_day:
				continue
			# Miroir de verre : le jour, il renvoie le soleil en un rayon le long de sa colonne.
			var hw := float(d.get("beam_width", 1.2)) * 0.5
			_telegraph(Rect2(e.pos.x - hw, BARRIER_Y, hw * 2.0, e.pos.y - 0.5 - BARRIER_Y), float(d.get("beam_delay", 1.4)), float(d.get("beam_dmg", 30.0)), 0.0)
			telegraphs.back()["sun"] = true


## Soins ennemis réduits par le Sceau sacré ; 20 % volés au profit de la Barrière (Clé des Cendres).
func _steal_heal(amount: float) -> float:
	amount *= 1.0 - clampf(_mod("anti_heal"), 0.0, 0.8)
	if _mod("heal_steal") > 0.0:
		var stolen := amount * 0.2
		amount -= stolen
		if barrier_hp < barrier_max:
			barrier_hp = minf(barrier_max, barrier_hp + stolen * 0.25)
			_event({"t": "text", "pos": Vector2(W * 0.5, BARRIER_Y + 0.6), "text": "+%d volé" % maxi(1, int(stolen * 0.25)), "color": "FFF0A0"})
	return amount


## Le Nexus repousse périodiquement les unités qui l'assiègent.
func _nexus_pulse() -> void:
	_pulse_t -= TICK
	if _pulse_t > 0.0:
		return
	_pulse_t = NEXUS_PULSE_INTERVAL
	if boss != null and boss.alive:
		var hit_b := false
		var br := boss.radius + 1.1
		for a in _query(_grid_a, boss.pos, br):
			_damage(a, NEXUS_PULSE_DMG * 1.4 * enemy_mult * diff * 100.0 / (100.0 + a.defense), "")
			hit_b = true
		if hit_b:
			_event({"t": "ring", "pos": boss.pos, "r": br, "color": "D93CF2", "dur": 0.4})
	for n in nexi:
		if not n["alive"]:
			continue
		var hit := false
		for a in _query(_grid_a, n["pos"], NEXUS_PULSE_RANGE):
			if a.role == "escort":
				continue
			_damage(a, NEXUS_PULSE_DMG * enemy_mult * diff * 100.0 / (100.0 + a.defense), "")
			hit = true
		if hit:
			_event({"t": "ring", "pos": n["pos"], "r": NEXUS_PULSE_RANGE, "color": "B07CFF", "dur": 0.4})


func _reach_checks() -> void:
	var shielded := nexus_shielded()
	for a in allies:
		if not a.alive or a.role == "escort":
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
		for n in nexi:
			if not n["alive"]:
				continue
			var np: Vector2 = n["pos"]
			var rn := NEXUS_R + a.radius
			if a.pos.distance_squared_to(np) > rn * rn:
				continue
			if a.siege:
				a.engaged = true
				if a.atk_cd > 0.0:
					break
				a.atk_cd = a.atk_interval
			else:
				a.alive = false
			if shielded:
				if _shield_fx_t <= 0.0:
					_shield_fx_t = 0.4
					_event({"t": "ring", "pos": np, "r": 1.3, "color": "D93CF2", "dur": 0.35})
				break
			var dmg := a.atk * (1.5 if rng.randf() < a.crit else 1.0)
			n["hp"] = float(n["hp"]) - dmg
			n["flash"] = 0.12
			_nexus_dmg_acc += dmg
			_nexus_dmg_pos = np
			if a.element == "ombre":
				n["wither"] = 5.0
			if float(n["hp"]) <= 0.0:
				n["hp"] = 0.0
				n["alive"] = false
				surge = minf(100.0, surge + 15.0)
				_event({"t": "ring", "pos": np, "r": 3.0, "color": "F2C46B", "dur": 1.0})
				if not _all_nexi_dead():
					_log("Un Nexus est détruit !")
			break
	for e in enemies:
		if e.alive and e.pos.y <= BARRIER_Y:
			e.alive = false
			_hurt_barrier(e.weight * diff * (0.7 if e.weak_t > 0.0 else 1.0))
	_nexus_dmg_t += TICK
	if _nexus_dmg_t >= 0.4:
		_nexus_dmg_t = 0.0
		if _nexus_dmg_acc >= 1.0:
			_event({"t": "text", "pos": _nexus_dmg_pos + Vector2(rng.randf_range(-0.7, 0.7), -0.5), "text": "-%d" % int(_nexus_dmg_acc), "color": "FFFFFF"})
		_nexus_dmg_acc = 0.0


func _defeated_word() -> String:
	return "vaincue" if boss != null and bool(units_db[boss.kind].get("fem", false)) else "vaincu"


func _all_nexi_dead() -> bool:
	for n in nexi:
		if n["alive"]:
			return false
	return true


func _sync_nexus() -> void:
	var hp := 0.0
	var mx := 0.0
	var fl := 0.0
	var wi := 0.0
	for n in nexi:
		hp += maxf(0.0, float(n["hp"]))
		mx += float(n["max"])
		fl = maxf(fl, float(n["flash"]))
		wi = maxf(wi, float(n["wither"]))
	nexus_hp = hp
	nexus_max = maxf(1.0, mx)
	nexus_flash = fl
	nexus_wither_t = wi


# ---------------------------------------------------------------- boss, attaques annoncées, lucioles

func _enter_phase(i: int) -> void:
	boss_phase = i
	boss_timers.clear()
	var phases: Array = level["boss"].get("phases", [])
	if i < phases.size():
		var list: Array = phases[i]
		for j in range(list.size()):
			boss_timers[j] = float((list[j] as Dictionary).get("cd", 10.0)) * (0.45 if j == 0 else 0.75)
	var onp: Array = level["boss"].get("on_phase", [])
	if i < onp.size():
		for ab in onp[i]:
			_boss_ability(ab)
	if i > 0:
		_log("%s entre en phase %d !" % [boss_name, i + 1])
		_event({"t": "ring", "pos": boss.pos, "r": 3.0, "color": "D93CF2", "dur": 0.8})


func _update_boss() -> void:
	if boss == null or not boss.alive:
		return
	boss_shield_t = maxf(0.0, boss_shield_t - TICK)
	boss_exposed_t = maxf(0.0, boss_exposed_t - TICK)
	if boss.airborne_t > 0.0:
		boss.airborne_t -= TICK
		if boss.airborne_t <= 0.0:
			boss.airborne_t = 0.0
			_log("%s se pose : frappe-le !" % boss_name)
			_event({"t": "ring", "pos": boss.pos, "r": 3.2, "color": "FF9B4A", "dur": 0.7})
			_event({"t": "shake"})
	var ratio := boss.hp / boss.max_hp
	var want := 2 if ratio <= 0.33 else (1 if ratio <= 0.66 else 0)
	if want > boss_phase:
		_enter_phase(want)
	var phases: Array = level["boss"].get("phases", [])
	if boss_phase >= phases.size():
		return
	var list: Array = phases[boss_phase]
	for j in range(list.size()):
		boss_timers[j] = float(boss_timers.get(j, 5.0)) - TICK
		if float(boss_timers[j]) <= 0.0:
			var ab: Dictionary = list[j]
			boss_timers[j] = float(ab.get("cd", 10.0))
			_boss_ability(ab)


func _boss_ability(ab: Dictionary) -> void:
	match str(ab["type"]):
		"row_sweep":
			var used: Array[float] = []
			for k in range(int(ab.get("count", 1))):
				var y := _target_row(used)
				used.append(y)
				var hw := float(ab.get("width", 1.2)) * 0.5
				_telegraph(Rect2(0.0, y - hw, W, hw * 2.0), float(ab.get("delay", 1.5)), float(ab.get("dmg", 40)), float(ab.get("barrier", 2.0)))
				if bool(ab.get("sun", false)):
					telegraphs.back()["sun"] = true
				if bool(ab.get("wave", false)):
					# Vague déferlante : elle repousse tes invocations vers la Barrière.
					telegraphs.back()["wave"] = true
					telegraphs.back()["push"] = float(ab.get("push", 2.5))
				if bool(ab.get("dragon", false)):
					# Mitraillage d'un dragon : la rangée garde des foyers.
					telegraphs.back()["dragon"] = true
					telegraphs.back()["patches"] = int(ab.get("patches", 2))
			_log(str(ab.get("log", "%s : balayage de racines !")) % boss_name)
		"lane_strike":
			var used_x: Array[float] = []
			for k in range(int(ab.get("count", 1))):
				var x := _target_lane(used_x)
				used_x.append(x)
				var hw := float(ab.get("width", 1.4)) * 0.5
				_telegraph(Rect2(x - hw, BARRIER_Y, hw * 2.0, boss.pos.y - 0.6 - BARRIER_Y), float(ab.get("delay", 1.2)), float(ab.get("dmg", 40)), float(ab.get("barrier", 3.0)))
				if bool(ab.get("sun", false)):
					telegraphs.back()["sun"] = true
				if bool(ab.get("fire", false)):
					# Souffle de feu : le couloir reste en flammes.
					telegraphs.back()["fire"] = true
				if bool(ab.get("tentacle", false)):
					telegraphs.back()["tentacle"] = true
			_log(str(ab.get("log", "%s charge !")) % boss_name)
		"summon":
			var kind := str(ab.get("kind", "mushroom"))
			for k in range(int(ab.get("count", 4))):
				if enemies.size() + _pending_enemies.size() >= MAX_ENEMIES:
					break
				_spawn_enemy(kind, boss.pos + Vector2(rng.randf_range(-2.4, 2.4), rng.randf_range(-1.8, -0.8)))
			_event({"t": "ring", "pos": boss.pos, "r": 2.5, "color": "FF6B8A", "dur": 0.5})
		"healers":
			var kind := str(ab.get("kind", "flower"))
			var count := int(ab.get("count", 3))
			for k in range(count):
				var x := boss.pos.x + (float(k) - float(count - 1) * 0.5) * 2.2
				var f := _spawn_enemy(kind, Vector2(clampf(x, 0.6, W - 0.6), boss.pos.y - 1.9))
				f.hold_y = f.pos.y
			_log("Des Fleurs-sèves éclosent : elles soignent %s !" % boss_name)
		"banners":
			# Bannières de guerre : tant qu'elles tiennent, le boss est en armure.
			var xs: Array = ab.get("xs", [1.6, 4.5, 7.4])
			for x in xs:
				var bn := _spawn_enemy(str(ab.get("kind", "war_banner")), Vector2(float(x), float(ab.get("y", boss.pos.y - 2.4))))
				bn.hold_y = bn.pos.y
				banners.append(bn)
			_log("Des bannières de guerre se dressent : %s est en armure !" % boss_name)
			_event({"t": "ring", "pos": boss.pos, "r": 3.0, "color": "C8402A", "dur": 0.7})
		"cry":
			for e in enemies:
				if e.alive:
					e.enraged_t = float(ab.get("dur", 6.0))
			_log("%s pousse un cri de guerre : les ennemis enragent !" % boss_name)
			_event({"t": "ring", "pos": boss.pos, "r": 4.0, "color": "FF4A3A", "dur": 0.8})
			_event({"t": "shake"})
		"heads":
			for x in ab.get("xs", [3.0, 4.5, 6.0]):
				_spawn_head(Vector2(float(x), float(ab.get("y", boss.pos.y - 1.7))))
			_log("%s dresse ses têtes : tant qu'elles vivent, son corps est protégé !" % boss_name)
		"fog":
			for k in range(int(ab.get("count", 1))):
				_add_fog(rng.randf_range(1.5, W - 1.5), rng.randf_range(4.0, 11.0))
			_log("%s souffle une brume épaisse." % boss_name)
		"venom":
			var used_x: Array[float] = []
			for k in range(int(ab.get("count", 1))):
				var x := _target_lane(used_x)
				used_x.append(x)
				var hw := float(ab.get("width", 1.4)) * 0.5
				_telegraph(Rect2(x - hw, BARRIER_Y, hw * 2.0, boss.pos.y - 0.6 - BARRIER_Y), float(ab.get("delay", 1.3)), float(ab.get("dmg", 40)), 2.0, true)
			_log("%s crache son venin !" % boss_name)
		"runes":
			# Colosse runique : des runes corporelles protègent son corps ; chacune ne craint qu'un élément.
			var els: Array = ab.get("elements", ["feu", "nature"])
			var xs: Array = ab.get("xs", [3.4, 5.6])
			for k in range(mini(els.size(), xs.size())):
				var ru := _spawn_enemy("body_rune", Vector2(float(xs[k]), float(ab.get("y", boss.pos.y - 1.7))))
				ru.element = str(els[k])
				ru.hp *= float(ab.get("hp_mult", 1.0))
				ru.max_hp = ru.hp
				ru.hold_y = ru.pos.y
				runes.append(ru)
			_log("Des runes s'allument sur %s : chacune ne craint qu'un élément !" % boss_name)
			_event({"t": "ring", "pos": boss.pos, "r": 3.0, "color": "8FD0FF", "dur": 0.7})
		"rotate_runes":
			var cycle := ["feu", "nature", "givre"]
			var names: Array[String] = []
			for ru in runes:
				if ru.alive:
					ru.element = str(cycle[(cycle.find(ru.element) + 1) % cycle.size()])
					names.append(str(ELEM_NAMES.get(ru.element, ru.element)))
					_event({"t": "ring", "pos": ru.pos, "r": 0.9, "color": str(SpriteAtlas.ELEM.get(ru.element, ["", "", "ffffff"])[2]), "dur": 0.5})
			if not names.is_empty():
				_log("Les runes tournent : %s." % ", ".join(names))
		"corrupt_gates":
			# Le Colosse corrompt des Portes runiques : un portail positif devient ÷2 un moment.
			var cands: Array[Portal] = []
			for pt in portals:
				if not pt.is_negative() and not pt.is_seal:
					var cursed := false
					for gc in _gate_curses:
						if gc["portal"] == pt:
							cursed = true
					if not cursed:
						cands.append(pt)
			for k in range(mini(int(ab.get("count", 1)), cands.size())):
				var pt: Portal = cands[rng.randi() % cands.size()]
				cands.erase(pt)
				_gate_curses.append({"portal": pt, "t": float(ab.get("dur", 10.0)), "kind": pt.kind, "value": pt.value, "element": pt.element})
				pt.kind = "div"
				pt.value = 2
				pt.flash_t = 0.5
				_event({"t": "ring", "pos": Vector2(pt.x, pt.y), "r": 1.4, "color": "D93CF2", "dur": 0.6})
			_log("%s corrompt une Porte runique !" % boss_name)
		"avalanche":
			_avalanche(float(ab.get("band", 1.6)), float(ab.get("dmg", 40.0)), float(ab.get("warn", 1.8)))
		"flood":
			for k in range(int(ab.get("count", 6))):
				terrain.add_poison(Vector2(rng.randf_range(0.8, W - 0.8), rng.randf_range(2.5, 11.5)), rng.randf_range(0.9, 1.4), float(ab.get("dur", 14.0)), false)
			_log("%s inonde le marais de poison !" % boss_name)
			_event({"t": "shake"})
		"riddle":
			_start_riddle(ab)
		"traitor":
			_spawn_traitor()
		"whirlpool":
			var none_f: Array[float] = []
			var wp := Vector2(W * 0.5, 7.5) if bool(ab.get("center", false)) else Vector2(_target_lane(none_f), clampf(_target_row(none_f), 4.0, 10.0))
			add_whirlpool(wp, float(ab.get("r", 1.8)), float(ab.get("dur", 8.0)))
			_log("%s creuse un tourbillon : il aspire tes invocations !" % boss_name)
		"swallow":
			# Le Léviathan avale un portail (à marée haute, il en avale deux).
			var n_sw := 2 if tide_state == "high" else 1
			var cands: Array[Portal] = []
			for pt in portals:
				if pt.active() and not pt.is_negative() and not pt.is_seal:
					cands.append(pt)
			for k in range(mini(n_sw, cands.size())):
				var pt: Portal = cands[rng.randi() % cands.size()]
				cands.erase(pt)
				pt.swallowed = true
				_gate_curses.append({"portal": pt, "t": float(ab.get("dur", 10.0)), "kind": pt.kind, "value": pt.value, "element": pt.element, "swallowed": true})
				_event({"t": "ring", "pos": Vector2(pt.x, pt.y), "r": 1.6, "color": "2A6AB8", "dur": 0.8})
			_log("%s avale un portail !" % boss_name)
		"take_off":
			boss.airborne_t = float(ab.get("dur", 8.0))
			_log("%s s'envole : seuls les tirs et les sorts l'atteignent !" % boss_name)
			_event({"t": "ring", "pos": boss.pos, "r": 3.0, "color": "FFB04A", "dur": 0.7})
			_event({"t": "text", "pos": boss.pos + Vector2(0.0, -1.4), "text": "EN VOL !", "color": "FFD070"})
		"eggs":
			# Œufs du Wyrm : ils éclosent en Wyverneaux si on ne les brise pas à temps.
			var count := int(ab.get("count", 3))
			for k in range(count):
				if enemies.size() + _pending_enemies.size() >= MAX_ENEMIES:
					break
				var x := clampf(boss.pos.x + (float(k) - float(count - 1) * 0.5) * 2.4, 0.8, W - 0.8)
				var egg := _spawn_enemy(str(ab.get("kind", "dragon_egg")), Vector2(x, boss.pos.y - 2.3))
				egg.hold_y = egg.pos.y
				egg.cast_cd = egg.cast_interval
			_log("%s pond ses œufs : brise-les avant qu'ils n'éclosent !" % boss_name)
			_event({"t": "ring", "pos": boss.pos, "r": 3.0, "color": "FF6A2A", "dur": 0.7})
		"mirage_gates":
			# Le Sphinx change des portails en mirages : ils gardent leur aspect, mais n'ont plus d'effet.
			var cands: Array[Portal] = []
			for pt in portals:
				if not pt.is_negative() and not pt.is_seal and not pt.mirage and pt.kind != "answer":
					cands.append(pt)
			for k in range(mini(int(ab.get("count", 1)), cands.size())):
				var pt: Portal = cands[rng.randi() % cands.size()]
				cands.erase(pt)
				pt.mirage = true
				_gate_curses.append({"portal": pt, "t": float(ab.get("dur", 12.0)), "kind": pt.kind, "value": pt.value, "element": pt.element, "mirage": true})
			_log("%s tisse des mirages : un portail ment !" % boss_name)
			_event({"t": "ring", "pos": boss.pos, "r": 3.0, "color": "F2C46B", "dur": 0.7})
		"fast_cycle":
			if daynight_cfg.is_empty():
				daynight_cfg = {"day": 20.0, "night": 20.0}
				daynight_t = 20.0
			daynight_speed = float(ab.get("speed", 3.0))
			_log("%s affole le ciel : le jour et la nuit se succèdent à toute allure !" % boss_name)
		"force_day":
			if daynight_cfg.is_empty():
				daynight_cfg = {"day": 25.0, "night": 20.0}
			if not is_day:
				_switch_daynight()
			daynight_t = float(ab.get("dur", 18.0))
			_log("%s appelle le soleil : le Feu brûle plus fort !" % boss_name)
		"shield":
			boss_shield_t = float(ab.get("dur", 8.0))
			boss_shield_elem = str(ab.get("element", "feu"))
			_log("%s : seul le %s blesse %s !" % [shield_word().capitalize(), str(ELEM_NAMES.get(boss_shield_elem, boss_shield_elem)), boss_name])
			_event({"t": "ring", "pos": boss.pos, "r": 2.0, "color": "8A5A30", "dur": 0.6})


## Avalanche (zone 4) : une rangée entière, annoncée, frappe amis et ennemis et les ensevelit 1 s.
func _avalanche(band: float, dmg: float, warn: float) -> void:
	var y := rng.randf_range(4.2, 12.4)
	var r := Rect2(0.0, y - band * 0.5, W, band)
	telegraphs.append({"rect": r, "t": warn, "dur": warn, "dmg": dmg, "barrier": 0.0, "avalanche": true})
	_event({"t": "text", "pos": Vector2(W * 0.5, y + 0.6), "text": "AVALANCHE !", "color": "EAF4FB"})
	_log("La montagne gronde : avalanche !")


func _update_avalanche() -> void:
	if avalanche_cfg.is_empty():
		return
	avalanche_t -= TICK
	if avalanche_t > 0.0:
		return
	var ev: Array = avalanche_cfg.get("every", [16, 20])
	avalanche_t = rng.randf_range(float(ev[0]), float(ev[1]))
	_avalanche(float(avalanche_cfg.get("band", 1.6)), float(avalanche_cfg.get("dmg", 40.0)), float(avalanche_cfg.get("warn", 1.8)))


## Portes runiques corrompues par le Colosse : elles redeviennent elles-mêmes après un temps.
func _update_gate_curses() -> void:
	var i := 0
	while i < _gate_curses.size():
		var gc: Dictionary = _gate_curses[i]
		gc["t"] = float(gc["t"]) - TICK
		if float(gc["t"]) <= 0.0:
			var pt: Portal = gc["portal"]
			pt.kind = str(gc["kind"])
			pt.value = int(gc["value"])
			pt.element = str(gc["element"])
			if bool(gc.get("mirage", false)):
				pt.mirage = false
				pt.revealed_t = 0.0
				pt.hidden_t = 0.0
			if bool(gc.get("swallowed", false)):
				pt.swallowed = false
			pt.flash_t = 0.4
			_event({"t": "ring", "pos": Vector2(pt.x, pt.y), "r": 1.2, "color": "8FD0FF", "dur": 0.5})
			_gate_curses.remove_at(i)
			continue
		i += 1


## Glace : vitesse ×1,6 sur la glace, ×1,3 pendant l'élan (0,8 s après en être sorti).
func _slide(u: Unit) -> float:
	if u.slide_t <= 0.0 or u.role in ["boss", "escort", "rune", "tete", "banniere"]:
		return 1.0
	u.slide_t = maxf(0.0, u.slide_t - TICK)
	return 1.6 if u.slide_t > 0.65 else 1.3


func runes_alive() -> int:
	var n := 0
	for ru in runes:
		if ru.alive:
			n += 1
	return n


func shield_word() -> String:
	return "écorce" if boss != null and boss.kind == "sylvarche" else "runes"


func _telegraph(r: Rect2, delay: float, dmg: float, barrier_dmg: float, venom: bool = false) -> void:
	var k := 1.3 if boss != null and boss.alive and boss.enraged_t > 0.0 else 1.0
	delay += warn_bonus
	telegraphs.append({"rect": r, "t": delay, "dur": delay, "dmg": dmg * enemy_mult * diff * k, "barrier": barrier_dmg * diff, "venom": venom})


func _update_telegraphs() -> void:
	var i := 0
	while i < telegraphs.size():
		var tg: Dictionary = telegraphs[i]
		tg["t"] = float(tg["t"]) - TICK
		if float(tg["t"]) > 0.0:
			i += 1
			continue
		var r: Rect2 = tg["rect"]
		var aval := bool(tg.get("avalanche", false))
		var push := float(tg.get("push", 0.0))
		for a in allies:
			if a.alive and a.shot == "" and r.has_point(a.pos):
				var dmg := float(tg["dmg"]) * 100.0 / (100.0 + a.defense)
				_damage(a, dmg * (0.4 if a.role == "escort" else 1.0), "")
				if push > 0.0 and a.alive and a.role != "escort":
					# Vague déferlante : l'invocation est rejetée vers la Barrière.
					a.pos.y = maxf(BARRIER_Y + 0.6, a.pos.y - push)
					a.prev_pos = a.pos
				if aval and a.alive:
					a.slow_stacks = maxi(a.slow_stacks, 4)
					a.slow_t = maxf(a.slow_t, 1.5)
		if aval:
			# L'avalanche n'épargne personne : les ennemis de la rangée sont blessés et ensevelis.
			for e in enemies:
				if e.alive and r.has_point(e.pos) and e.role not in ["boss", "rune", "tete", "banniere"]:
					_damage(e, float(tg["dmg"]) * enemy_mult * 100.0 / (100.0 + e.defense), "givre")
					if e.alive:
						e.rooted_t = maxf(e.rooted_t, 1.0)
			_event({"t": "avalanche", "rect": r, "dur": 0.6})
			_event({"t": "shake"})
		if float(tg["barrier"]) > 0.0:
			_hurt_barrier(float(tg["barrier"]))
		if bool(tg.get("wave", false)):
			_event({"t": "wave", "y": r.get_center().y, "dur": 0.9})
		if bool(tg.get("dragon", false)):
			# Passage de dragon : des foyers restent sur la rangée mitraillée.
			for k in range(int(tg.get("patches", 2))):
				add_fire_patch(Vector2(rng.randf_range(0.9, W - 0.9), r.get_center().y), 0.75, 7.0, "dragon")
			_event({"t": "dragon", "y": r.get_center().y, "dur": 1.1})
		if bool(tg.get("fire", false)):
			# Souffle de feu : le couloir brûle encore quelques secondes.
			_add_fire(r.get_center().x, r.size.x * 0.8, r.position.y + 1.2, r.end.y, 0.0, 7.0, true, "souffle")
		if bool(tg.get("venom", false)):
			# Souffle de venin : des mares de poison restent le long du couloir.
			for k in range(3):
				terrain.add_poison(Vector2(r.get_center().x, lerpf(r.position.y + 1.5, r.end.y - 1.0, float(k) / 2.0)), 0.8, 10.0, false)
		var sk := "hit"
		for key in ["tentacle", "fire", "venom", "wave", "dragon", "avalanche", "sun"]:
			if bool(tg.get(key, false)):
				sk = key
		_event({"t": "strike", "rect": r, "dur": 0.35, "kind": sk})
		telegraphs.remove_at(i)


func _target_row(avoid: Array[float]) -> float:
	var best_y := rng.randf_range(3.0, 11.0)
	var best_n := -1
	var y := 2.5
	while y <= 12.0:
		var ok := true
		for v in avoid:
			if absf(v - y) < 2.0:
				ok = false
		if ok:
			var n := 0
			for a in allies:
				if a.alive and a.shot == "" and absf(a.pos.y - y) <= 0.7:
					n += 1
			if n > best_n:
				best_n = n
				best_y = y
		y += 0.5
	return best_y


func _target_lane(avoid: Array[float]) -> float:
	var best_x := rng.randf_range(1.0, W - 1.0)
	var best_n := -1
	var x := 0.8
	while x <= W - 0.8:
		var ok := true
		for v in avoid:
			if absf(v - x) < 1.8:
				ok = false
		if ok:
			var n := 0
			for a in allies:
				if a.alive and a.shot == "" and a.pos.y < boss.pos.y and absf(a.pos.x - x) <= 0.7:
					n += 1
			if n > best_n:
				best_n = n
				best_x = x
		x += 0.5
	return best_x


## Escorte : des groupes surgissent sur les flancs, juste devant la Lanterne.
var _ambush_t := 12.0


func _update_ambush() -> void:
	if escort == null or not escort.alive:
		return
	var am: Dictionary = level.get("ambush", {})
	if am.is_empty():
		return
	_ambush_t -= TICK
	if _ambush_t > 0.0:
		return
	_ambush_t = float(am.get("every", 14.0))
	var side := 0.4 if rng.randf() < 0.5 else W - 0.4
	var y := minf(escort.pos.y + float(am.get("ahead", 2.6)), H - 1.5)
	for k in range(int(am.get("count", 5))):
		_spawn_enemy(str(am.get("kind", "rabbit")), Vector2(side + rng.randf_range(-0.3, 0.3) * signf(4.5 - side), y + rng.randf_range(-0.5, 0.5)))
	_log("Embuscade sur le flanc !")


func _update_orbs() -> void:
	for o in orbs:
		if not o["alive"]:
			o["t"] = float(o["t"]) - TICK
			if float(o["t"]) <= 0.0:
				o["alive"] = true
				o["pos"] = _orb_spot()
			continue
		if _query(_grid_a, o["pos"], 0.45).is_empty():
			continue
		o["alive"] = false
		o["t"] = float(orb_cfg.get("respawn", 6.0))
		var c := casters[0]
		var m := float(orb_cfg.get("mana", 6.0))
		c.mana = minf(c.mana_max, c.mana + m)
		_event({"t": "text", "pos": o["pos"], "text": "+%d mana" % int(m), "color": "9FF0FF"})
		_event({"t": "ring", "pos": o["pos"], "r": 0.6, "color": "F2E28B", "dur": 0.4})


func _hurt_barrier(amount: float) -> void:
	if barrier_invuln_t > 0.0:
		return
	amount *= 1.0 - clampf(_mod("barrier_dr"), 0.0, 0.6)
	if _mod("barrier_cap") > 0.0:
		# Clé de voûte Inébranlable : la Barrière perd au plus 5 PV par coup.
		amount = minf(amount, _mod("barrier_cap"))
	if barrier_shield > 0.0:
		var a := minf(barrier_shield, amount)
		barrier_shield -= a
		amount -= a
	if amount <= 0.0:
		return
	barrier_hp -= amount
	barrier_flash = 0.25
	_event({"t": "barrier"})
	if _ash_renew and barrier_hp > 0.0 and barrier_hp < barrier_max * 0.25:
		# Héritage de cendre (Renaissance) : le compagnon racheté ranime la Barrière, une fois.
		_ash_renew = false
		barrier_hp = minf(barrier_max, barrier_hp + 20.0)
		_log("Renaissance : la braise du compagnon ranime la Barrière (+20) !")
		_event({"t": "ring", "pos": Vector2(W * 0.5, BARRIER_Y), "r": 3.0, "color": "FF9B4A", "dur": 0.8})


func _hit(src: Unit, tgt: Unit, mult: float = 1.0) -> void:
	if tgt.team == 0 and tgt.owner_idx == 0 and _mod("dodge") > 0.0 and rng.randf() < minf(0.4, _mod("dodge")):
		# Rune Wyrd sur une armure : l'invocation esquive le coup.
		return
	if src.team == 0 and src.owner_idx == 0:
		mult *= 1.0 + _mod("unit_elem." + src.element)
	if src.enraged_t > 0.0:
		mult *= 1.3
	if src.team == 0 and rally_t > 0.0:
		mult *= 1.2
	if src.team == 0 and charge_t > 0.0 and tgt.role not in ["boss", "banniere", "tete"] and tgt.hold_y <= 0.0:
		tgt.pos.y = minf(H - 0.6, tgt.pos.y + 0.12)
	if src.buff_t > 0.0:
		mult *= 1.0 + src.buff_atk
	if src.team == 1 and src.weak_t > 0.0:
		mult *= 0.7
	if src.frenzy_t > 0.0:
		mult *= 2.2 if (src.owner_idx == 0 and _mod("blood_rage") > 0.0) else 1.4
	if src.team == 0 and src.owner_idx == 0 and _mod("low_barrier_atk") > 0.0 and barrier_hp < barrier_max * 0.5:
		# Au bord du gouffre (Fureur primordiale) : plus la Barrière vacille, plus on frappe fort.
		mult *= 1.0 + _mod("low_barrier_atk")
	var dmg := _calc(src.atk * mult, src.element, src.crit + src.buff_crit, tgt, src.team == 0, src.crit_mult)
	var crit := _last_crit
	_damage(tgt, dmg, src.element)
	if src.team == 0 and tgt.reflect > 0.0 and src.attack_range > 0.0 and src.alive:
		# Miroirs (zone 5) : une part du tir revient sur le tireur.
		_damage(src, dmg * tgt.reflect, "lumiere")
		_event({"t": "beam", "a": tgt.pos, "b": src.pos, "color": "FFE9A8", "dur": 0.1})
	if src.team == 0:
		_on_hit_effects(src, tgt, dmg, src.element)
		_class_on_hit(src, tgt, dmg, crit)
	else:
		var thorns := (_mod("riposte") if tgt.owner_idx == 0 else 0.0) + (tgt.buff_thorns if tgt.buff_t > 0.0 else 0.0)
		if thorns > 0.0 and src.alive:
			# Riposte (Épéiste, arbre ou renfort) : les invocations renvoient une part des coups reçus.
			_damage(src, dmg * thorns, "physique")


## Effets des arbres de classe sur un coup porté par une invocation (étape 13.3).
func _class_on_hit(src: Unit, tgt: Unit, dmg: float, crit: bool) -> void:
	var steal := src.lifesteal + (0.1 if src.frenzy_t > 0.0 else 0.0) + (src.buff_steal if src.buff_t > 0.0 else 0.0)
	if steal > 0.0 and src.alive:
		var h := dmg * steal
		src.hp = minf(src.max_hp, src.hp + h)
		if _mod("thirst") > 0.0 and src.owner_idx == 0 and _thirst_budget > 0.0 and barrier_hp < barrier_max:
			# Clé de voûte Soif : le vol de vie soigne aussi la Barrière.
			var b := minf(_thirst_budget, maxf(0.05, dmg * 0.01))
			_thirst_budget -= b
			barrier_hp = minf(barrier_max, barrier_hp + b)
	if src.owner_idx != 0:
		return
	if _mod("hunt_mark") > 0.0 and tgt.alive and rng.randf() < _mod("hunt_mark"):
		tgt.marked_t = 4.0
	if crit and _mod("perfect_dance") > 0.0 and _dance_budget > 0.0:
		# Clé de voûte Danse parfaite : chaque critique réduit les recharges de 0,2 s.
		var cut := minf(_dance_budget, 0.2)
		_dance_budget -= cut
		var pc := casters[0]
		for k in pc.spell_cd.keys():
			pc.spell_cd[k] = maxf(0.0, float(pc.spell_cd[k]) - cut)


## Courroux céleste (Clerc) : les soins en excès frappent les ennemis les plus proches de la Barrière.
func _wrath(amount: float) -> void:
	if _mod("wrath") <= 0.0:
		return
	var n := 0
	for e in enemies:
		if e.alive and e.pos.y < BARRIER_Y + 4.0:
			_damage(e, amount * 0.5, "lumiere")
			_event({"t": "beam", "a": Vector2(e.pos.x, BARRIER_Y), "b": e.pos, "color": "FFF0A0", "dur": 0.15})
			n += 1
			if n >= 3:
				break


func _calc(atk: float, elem: String, crit: float, tgt: Unit, frontal: bool, crit_mult: float = 1.5) -> float:
	var d := atk * affinity(elem, tgt.element)
	_last_crit = rng.randf() < crit
	if _last_crit:
		d *= crit_mult
	d *= 100.0 / (100.0 + maxf(0.0, tgt.defense))
	if tgt.team == 1:
		if tgt.frozen_t > 0.0:
			d *= 1.0 + _mod("frozen_vuln")
		if tgt.burn_t > 0.0:
			d *= 1.0 + _mod("burning_vuln")
		if tgt.exposed_t > 0.0:
			d *= BattleTerrain.EXPOSE_MULT
		if tgt.fogged:
			d *= FOG_CONCEAL
		if tgt.marked_t > 0.0:
			d *= 1.15 + _mod("mark_vuln")
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
	if not tgt.alive or amount <= 0.0 or tgt.shot != "":
		return
	if tgt == boss and boss_shield_t > 0.0 and elem != boss_shield_elem:
		amount *= 0.1
	if tgt == boss and banners_alive() > 0:
		amount *= 0.2
	if tgt == boss and heads_alive() > 0:
		amount *= 0.25
	if tgt == boss and runes_alive() > 0:
		amount *= 0.3
	if tgt == boss and not riddle.is_empty():
		amount *= 0.1
	if tgt == boss and boss_exposed_t > 0.0:
		amount *= 1.5
	if not daynight_cfg.is_empty():
		# Désert de Verre : le jour, le Feu brûle plus fort ; la nuit, le Givre mord plus fort.
		if (elem == "feu" and is_day) or (elem == "givre" and not is_day):
			amount *= DAY_BONUS
	if tgt.role == "rune" and elem != tgt.element and (_sid == "" or _sid != ultimate_id):
		# Rune corporelle : seul son élément la blesse (une Ultime, elle, la brise quel que soit l'élément).
		if _immune_txt_t <= 0.0:
			_immune_txt_t = 1.2
			_event({"t": "text", "pos": tgt.pos + Vector2(0.0, 0.5), "text": "IMMUNISÉE : %s" % str(ELEM_NAMES.get(tgt.element, tgt.element)).to_upper(), "color": "C8D8FF"})
		return
	if tgt.team == 0 and elem == "feu" and _mod("fire_resist") > 0.0:
		amount *= 1.0 - _mod("fire_resist")
	if tgt.team == 0 and elem != "" and _mod("resist." + elem) > 0.0:
		# Runes élémentaires sur une armure : les invocations résistent à cet élément.
		amount *= 1.0 - clampf(_mod("resist." + elem), 0.0, 0.6)
	if tgt.shield > 0.0:
		var a := minf(tgt.shield, amount)
		tgt.shield -= a
		amount -= a
	if tgt == traitor_unit and not _traitor_damage(tgt, amount):
		return
	tgt.hp -= amount
	tgt.flash_t = 0.08
	if elem != "":
		tgt.last_elem = elem
	if tgt.hp <= 0.0:
		_kill(tgt)


## Base des dégâts sur la durée : PV max, plafonnés pour que boss et élites ne fondent pas.
func _dot_base(tgt: Unit) -> float:
	return minf(tgt.max_hp, 150.0 * enemy_mult)


func _apply_status(tgt: Unit, elem: String) -> void:
	if not tgt.alive:
		return
	match elem:
		"feu":
			tgt.burn_t = 3.0 + _mod("burn_dur")
			tgt.burn_dps = maxf(tgt.burn_dps, 0.03 * _dot_base(tgt) * effect_mult * (1.0 + _mod("burn_dmg")))
		"givre":
			tgt.slow_stacks += 1
			tgt.slow_t = 3.0
			if tgt.slow_stacks >= (2 if _mod("zero_absolu") > 0.0 else 3):
				tgt.frozen_t = (1.5 + _mod("frozen_dur")) * effect_mult
				tgt.slow_stacks = 0
		"nature":
			tgt.poison_stacks = mini(5, tgt.poison_stacks + 1)
			tgt.poison_t = 4.0
			tgt.poison_unit = 0.02 * _dot_base(tgt) * effect_mult * (1.0 + _mod("poison_dmg"))
		"ombre":
			tgt.wither_t = 5.0


func _on_hit_effects(src: Unit, tgt: Unit, dmg: float, elem: String) -> void:
	if src.owner_idx == 0 and _mod("venom") > 0.0 and rng.randf() < _mod("venom"):
		_apply_status(tgt, "nature")
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
	if u.team == 1 and not u.reborn and u.last_elem != "givre":
		var rb := float((units_db.get(u.kind, {}) as Dictionary).get("rebirth", 0.0))
		if rb > 0.0:
			# Phénix mineur : il renaît de ses cendres, sauf si le Givre l'a frappé en dernier.
			u.reborn = true
			u.hp = u.max_hp * rb
			_event({"t": "ring", "pos": u.pos, "r": 1.2, "color": "FFB04A", "dur": 0.6})
			_event({"t": "text", "pos": u.pos + Vector2(0.0, 0.6), "text": "RENAÎT !", "color": "FFD070"})
			_log("Le phénix renaît de ses cendres ! Achève-le au Givre.")
			return
	u.alive = false
	if u == boss:
		_log("%s est %s !" % [boss_name, _defeated_word()])
	if u == escort:
		_log(_escort_text(u.kind, false))
	if u.team == 1:
		for z in zones:
			if bool(z.get("raise", false)) and u.pos.distance_to(z["pos"]) <= float(z["r"]) + 0.2:
				# Terre des morts : l'ennemi tombé dans la zone se relève en squelette.
				_raise_unit("skeleton", int(z["c"]), u.pos, float(z.get("life", 0.0)))
				break
	if u.team == 1 and u.burn_t > 0.0 and _mod("embrasement") > 0.0:
		# Clé de voûte Embrasement : la brûlure se propage aux ennemis proches.
		for e in _query(_grid_e, u.pos, 1.5):
			if e != u and e.alive:
				_apply_status(e, "feu")
		_event({"t": "ring", "pos": u.pos, "r": 1.5, "color": "FF6A3A", "dur": 0.35})
	if u.team == 1 and u.marked_t > 0.0 and _mod("thorn_burst") > 0.0:
		# Clé de voûte Maître de la traque : la proie marquée explose en épines.
		for e in _query(_grid_e, u.pos, 1.4):
			if e != u and e.alive:
				_damage(e, u.max_hp * 0.25 + 20.0 * enemy_mult, "nature")
				_apply_status(e, "nature")
				e.marked_t = 4.0
		_event({"t": "ring", "pos": u.pos, "r": 1.4, "color": "8FD16A", "dur": 0.35})
	if u.team == 1 and u.wither_t > 0.0 and _mod("pandemic") > 0.0:
		# Clé de voûte Pandémie : la Flétrissure se propage.
		for e in _query(_grid_e, u.pos, 1.6):
			if e != u and e.alive:
				_apply_status(e, "ombre")
				_apply_status(e, "nature")
		_event({"t": "ring", "pos": u.pos, "r": 1.6, "color": "8E62E0", "dur": 0.35})
	if u.team == 1:
		var dp := float((units_db.get(u.kind, {}) as Dictionary).get("death_pool", 0.0))
		if dp > 0.0:
			terrain.add_poison(u.pos, dp, 8.0, false)
		var fp := float((units_db.get(u.kind, {}) as Dictionary).get("fire_pool", 0.0))
		if fp > 0.0:
			# Golem de magma, Démon des cendres : une flaque de feu reste où il tombe (elle brûle moitié moins).
			add_fire_patch(u.pos, fp, 4.0, "flaque")
			fires.back()["k"] = 0.5
		if heads.has(u):
			stumps.append({"pos": u.pos, "t": STUMP_TIME})
			_event({"t": "text", "pos": u.pos + Vector2(0.0, 0.6), "text": "TRANCHÉE ! Brûle la plaie !", "color": "FFB04A"})
			_log("Tête tranchée : brûle la plaie avant 5 s, sinon deux têtes repoussent !")
	if u.team == 1:
		kills += 1
		var big := u.role in ["brute", "bouclier", "lanceur", "soigneur"] or u.elite
		surge = minf(100.0, surge + (SURGE_PER_BIG if big else SURGE_PER_KILL) * (1.0 + _mod("surge_gain")))
		if _mod("kill_mana") > 0.0:
			# Clé de voûte Cendres vives : chaque ennemi abattu rend du mana.
			casters[0].mana = minf(casters[0].mana_max, casters[0].mana + _mod("kill_mana"))
		_event({"t": "puff", "pos": u.pos, "color": "FF6B8A"})
		if u.role == "soigneur":
			_log("Soigneur ennemi abattu")
		if u.last_elem == "ombre" and rng.randf() < 0.05 + _mod("skeleton_chance"):
			var s := _make_unit("skeleton", 0, u.pos)
			s.owner_idx = 0
			_player_unit_mods(s)
			_add_ally(s)
	else:
		_event({"t": "puff", "pos": u.pos, "color": "4FE3D2"})
		if u.owner_idx == 0 and u.role in ["familier", "elite", "champion"]:
			_fallen.append({"kind": u.kind, "element": u.element, "atk": u.atk, "hp": u.max_hp})
			if _fallen.size() > 14:
				_fallen.pop_front()
		if u.owner_idx == 0 and _mod("rune_burst") > 0.0:
			# Clé de voûte (Cendres) de la Garde runique : l'invocation explose en runes.
			for e in _query(_grid_e, u.pos, 0.8):
				_damage(e, u.atk * 0.8, "lumiere")
			_event({"t": "ring", "pos": u.pos, "r": 0.8, "color": "4FE3D2", "dur": 0.25})
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
	var won := false
	match objective:
		"boss":
			won = boss != null and not boss.alive
		"escort":
			won = escort != null and escort.alive and escort.pos.y >= escort_goal_y - 0.01
		_:
			won = _all_nexi_dead()
	if won:
		state = "victory"
		if traitor_id != "":
			# Le Wyrm tombé, la Marque se dissipe : le compagnon brisé (ou jamais abattu) est épargné.
			story_out.append("s1.traitre_tue" if traitor_killed else "s1.traitre_epargne")
			if traitor_killed:
				story_out.append("s1.mort_" + traitor_id)
		stars = 1
		if barrier_hp / barrier_max > 0.5:
			stars += 1
			if time <= par_time:
				stars += 1
		match objective:
			"boss":
				end_reason = "%s est %s !" % [boss_name, _defeated_word()]
			"escort":
				end_reason = _escort_text(escort.kind, true)
			_:
				end_reason = "Le Nexus est détruit !" if nexi.size() <= 1 else "Les Nexus sont détruits !"
		_log("Victoire !")
		_event({"t": "ring", "pos": objective_pos(), "r": 4.0, "color": "F2C46B", "dur": 1.2})
		return
	var lost_escort := escort != null and not escort.alive
	if barrier_hp <= 0.0 and not lost_escort and _mod("miracle") > 0.0 and not _miracle_used:
		# Clé de voûte Miracle : une fois par partie, la Barrière tombée remonte à 50 %.
		_miracle_used = true
		barrier_hp = barrier_max * 0.5
		barrier_invuln_t = 2.0
		_event({"t": "shield", "dur": 1.6, "color": "FFF0A0"})
		_event({"t": "text", "pos": Vector2(W * 0.5, BARRIER_Y + 0.8), "text": "MIRACLE !", "color": "FFF0A0"})
		_event({"t": "flash"})
		_log("Miracle : la Barrière se relève !")
		return
	if barrier_hp <= 0.0 or lost_escort:
		barrier_hp = maxf(0.0, barrier_hp)
		state = "defeat"
		if lost_escort:
			end_reason = _escort_text(escort.kind, false)
		else:
			end_reason = "La Barrière est tombée…"
		_log(end_reason)
		return
	var ratio := objective_ratio()
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
	if state != "running" or c.mana < spell_cost(c, id) or float(c.spell_cd.get(id, 0.0)) > 0.0:
		return false
	# Magie interdite : il faut pouvoir payer son prix en Barrière.
	return barrier_hp > float(spells_db[id].get("barrier_cost", 0.0)) + 1.0


## Lance un sort à la position logique « at ». Retourne false s'il n'a pas pu être lancé.
func cast_spell(c: Caster, id: String, at: Vector2) -> bool:
	if not spell_ready(c, id):
		return false
	var sp: Dictionary = spells_db[id]
	_sid = id
	_sid_owner = c.idx
	_event({"t": "spell", "pos": at, "from": Vector2(c.x, CASTER_Y + 0.3), "r": float(sp.get("radius", 1.0)), "color": str(sp.get("color", "FFFFFF"))})
	var ok := _apply_spell(c, sp, at)
	if ok and sp.has("rally") and str(sp["type"]) != "rally":
		# Sort de grimoire qui porte aussi un renfort (Curée, Marque de mort).
		_rally(c, sp["rally"], at, str(sp.get("color", "FFFFFF")))
	_sid = ""
	if not ok:
		return false
	c.mana -= spell_cost(c, id)
	c.spell_cd[id] = float(sp.get("cd", 0)) * (1.0 - clampf(_mod("cd_red"), 0.0, 0.4) if c.idx == 0 else 1.0)
	var price := float(sp.get("barrier_cost", 0.0))
	if price > 0.0:
		# Prix de la magie interdite : prélevé sur la Barrière elle-même (le bouclier ne protège pas).
		barrier_hp = maxf(1.0, barrier_hp - price)
		barrier_flash = 0.25
		_event({"t": "barrier"})
		_event({"t": "text", "pos": Vector2(W * 0.5, BARRIER_Y + 0.6), "text": "-%d Barrière" % int(price), "color": "D93CF2"})
		_log("Magie interdite : la Barrière paie le prix (-%d)." % int(price))
	if c.idx == 0 and barrier_cost_per_spell > 0.0:
		_hurt_barrier(barrier_cost_per_spell)
	if c.is_bot:
		_log("%s : %s" % [c.name, str(sp["name"])])
	return true


func _apply_spell(c: Caster, sp: Dictionary, at: Vector2) -> bool:
	var col := str(sp.get("color", "FFFFFF"))
	var from := Vector2(c.x, CASTER_Y + 0.3)
	match str(sp["type"]):
		"aoe":
			var delay := float(sp.get("delay", 0.0))
			if delay > 0.0:
				# Projectile (Boule de feu) ou chute (Météore) : l'impact suit l'animation.
				pending_impacts.append({"t": delay, "c": c.idx, "sp": sp, "at": at})
				_event({"t": str(sp.get("fx", "fireball")), "from": from, "to": at, "dur": delay, "r": float(sp.get("radius", 1.0)), "color": col,
					"tint": bool(sp.get("tint", false))})
				return true
			_resolve_aoe(c, sp, at)
			return true
		"barrage":
			# Pluie d'impacts (météores, éclairs) autour du point visé, l'un après l'autre.
			var n := int(sp.get("count", 5))
			var spread := float(sp.get("spread", 2.0))
			var sub := sp.duplicate()
			sub["type"] = "aoe"
			sub.erase("barrier_cost")
			sub.erase("rally")
			var elems: Array = sp.get("multi_elem", [])
			var cols: Array = sp.get("multi_color", [])
			for k in range(n):
				var p := at + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * spread
				if bool(sp.get("line", false)):
					# Tirs alignés (Ceinture d'Orion) : en travers du point visé.
					p = at + Vector2((float(k) - float(n - 1) * 0.5) * spread / maxf(1.0, float(n - 1)) * 2.0, 0.0)
				p = Vector2(clampf(p.x, 0.3, W - 0.3), clampf(p.y, BARRIER_Y + 0.8, H - 0.5))
				var one := sub
				if not elems.is_empty():
					# Flèches trinité, du chaos : chaque impact a son élément.
					one = sub.duplicate()
					one["element"] = str(elems[k % elems.size()])
					if not cols.is_empty():
						one["color"] = str(cols[k % cols.size()])
				pending_impacts.append({"t": 0.45 + float(k) * float(sp.get("interval", 0.25)), "c": c.idx, "sp": one, "at": p,
					"fx": str(sp.get("fx", "meteor")), "lead": 0.45, "from": from})
			return true
		"zone":
			var dur := float(sp.get("dur", 3.0)) + _spell_mod(c, "dur.", sp)
			var zr := float(sp.get("radius", 1.5)) * (1.0 + _spell_mod(c, "radius.", sp))
			var zslow := float(sp.get("slow", 0.0))
			if zslow > 0.0 and c.idx == 0:
				zslow = minf(0.9, zslow + _mod("zone_slow"))
			zones.append({"pos": at, "r": zr, "t": dur, "dps": float(sp.get("dps", 0)) * c.atk_mult * _elem_mult(c, sp),
				"ally_shield": float(sp.get("ally_shield", 0.0)) * c.hp_mult, "ally_heal": float(sp.get("ally_heal", 0.0)),
				"c": c.idx, "spawn": str(sp.get("spawn", "")), "spawn_every": float(sp.get("spawn_every", 2.0)), "spawn_acc": 0.0,
				"raise": bool(sp.get("raise", false)), "life": float(sp.get("life", 0.0)),
				"ally_atk": float(sp.get("ally_atk", 0.0)), "ally_aspd": float(sp.get("ally_aspd", 0.0)),
				"elem": str(sp.get("element", "")), "slow": zslow, "pull": float(sp.get("pull", 0.0)),
				"stack_every": float(sp.get("stack_every", 0.0)), "stack_acc": 0.0})
			_event({"t": str(sp.get("fx", "rain")), "pos": at, "r": zr, "dur": dur, "color": col})
			if float(sp.get("damage", 0.0)) > 0.0:
				# Fleur de mort : un premier coup, puis la zone.
				var burst := sp.duplicate()
				burst["type"] = "aoe"
				burst["radius"] = zr
				_resolve_aoe(c, burst, at)
			terrain.on_impact(c, sp, at, zr, float(sp.get("dps", 0)) * c.atk_mult * 2.0)
			return true
		"rally":
			# Renfort (Cor de chasse, Œil d'aigle…) : les invocations frappent plus fort, plus vite, plus juste.
			return _rally(c, sp, at, col) > 0 or float(sp.get("damage", 0.0)) > 0.0
		"chain":
			return _chain(c, sp, at, from)
		"wall", "quake", "ground":
			return terrain.cast(c, sp, at)
		"barrier_heal":
			if barrier_hp >= barrier_max:
				return false
			var heal := float(sp.get("amount", 15)) * (1.0 + _mod("heal_bonus"))
			if float(sp.get("over", 0.0)) > 0.0:
				# Soin sur la durée.
				var over := float(sp["over"])
				_bheal_rate = maxf(_bheal_rate, heal / over)
				_bheal_t = maxf(_bheal_t, over)
				_event({"t": "shield", "dur": 1.0, "color": col})
				_event({"t": "text", "pos": Vector2(W * 0.5, BARRIER_Y + 0.6), "text": "+%d Barrière (%d s)" % [int(heal), int(over)], "color": "F2E28B"})
				return true
			if barrier_hp + heal > barrier_max:
				_wrath_acc += barrier_hp + heal - barrier_max
			barrier_hp = minf(barrier_max, barrier_hp + heal)
			_event({"t": "shield", "dur": 1.0, "color": col})
			_event({"t": "text", "pos": Vector2(W * 0.5, BARRIER_Y + 0.6), "text": "+%d Barrière" % int(sp.get("amount", 15)), "color": "F2E28B"})
			return true
		"wave":
			_wave(c, sp, at)
			if float(sp.get("shield", 0.0)) > 0.0:
				# Rempart sacré : la Barrière gagne un bouclier, les invocations aussi.
				barrier_shield += float(sp["shield"])
				for a in allies:
					if a.alive and a.owner_idx == 0:
						a.shield = maxf(a.shield, a.max_hp * 0.3)
				_event({"t": "shield", "dur": 1.2, "color": col})
			return true
		"army":
			# Armée des morts, Horde : des squelettes surgissent autour du point visé.
			var ar := float(sp.get("radius", 2.0))
			if float(sp.get("damage", 0.0)) > 0.0:
				var hit := sp.duplicate()
				hit["type"] = "aoe"
				_resolve_aoe(c, hit, at)
			var extra := int(_mod("army_count")) * (1 if c.idx == 0 and str(sp.get("kind", "skeleton")) == "skeleton" else 0)
			var kinds: Array = sp.get("kinds", [])
			for k in range(int(sp.get("count", 6)) + extra):
				var p := at + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * ar
				p = Vector2(clampf(p.x, 0.4, W - 0.4), clampf(p.y, BARRIER_Y + 0.6, H - 1.0))
				var sk := _make_unit(str(kinds[k % kinds.size()]) if not kinds.is_empty() else str(sp.get("kind", "skeleton")), 0, p)
				sk.life_t = float(sp.get("life", 0.0))
				sk.owner_idx = c.idx
				sk.atk *= c.atk_mult
				sk.hp *= c.hp_mult
				if c.idx == 0:
					_player_unit_mods(sk)
				sk.max_hp = sk.hp
				sk.crit = c.crit
				summoned += 1
				_add_ally(sk)
				_event({"t": "puff", "pos": p, "color": col})
			_event({"t": "ring", "pos": at, "r": ar, "color": col, "dur": 0.6})
			return true
		"mirror":
			# Lames miroirs : les invocations du joueur proches du point visé se dédoublent.
			var mr := float(sp.get("radius", 2.0))
			var n := 0
			for a: Unit in _query(_grid_a, at, mr):
				if a.alive and a.owner_idx == c.idx and a.role in ["familier", "elite"]:
					_add_ally(_clone(a, Vector2(rng.randf_range(-0.3, 0.3), 0.1)))
					n += 1
					if n >= int(sp.get("count", 10)):
						break
			_event({"t": "ring", "pos": at, "r": mr, "color": col, "dur": 0.5})
			if n > 0:
				_event({"t": "text", "pos": at + Vector2(0.0, 0.6), "text": "×%d" % n, "color": col})
			return n > 0
		"harvest":
			# Moisson d'âmes : les invocations sacrifiées explosent en Ombre.
			var hr := float(sp.get("radius", 2.0))
			var n2 := 0
			for a: Unit in _query(_grid_a, at, hr):
				if not a.alive or a.owner_idx != c.idx or a.role not in ["familier", "elite"]:
					continue
				a.alive = false
				n2 += 1
				var bd := (float(sp.get("damage", 25)) + a.atk * 2.0) * _elem_mult(c, sp)
				for e: Unit in _query(_grid_e, a.pos, 0.9):
					_damage(e, _calc(bd, "ombre", c.crit, e, false), "ombre")
					_apply_status(e, "ombre")
				_event({"t": "puff", "pos": a.pos, "color": col})
				if n2 >= int(sp.get("count", 20)):
					break
			if n2 == 0:
				return false
			sacrificed += n2
			if float(sp.get("heal_per", 0.0)) > 0.0:
				# Transfusion : chaque invocation sacrifiée soigne la Barrière.
				barrier_hp = minf(barrier_max, barrier_hp + float(sp["heal_per"]) * float(n2))
				_event({"t": "shield", "dur": 0.8, "color": col})
			if float(sp.get("surge_gain", 0.0)) > 0.0 and c.idx == 0:
				surge = minf(100.0, surge + float(sp["surge_gain"]))
			if c.idx == 0 and _mod("harvest_barrier") > 0.0:
				# Clé de voûte (Aube) de la Liche : 20 sacrifiés → Barrière +10.
				barrier_hp = minf(barrier_max, barrier_hp + 0.5 * float(n2))
				_event({"t": "shield", "dur": 0.8, "color": col})
			if c.idx == 0 and _mod("harvest_surge") > 0.0:
				# Clé de voûte (Cendres) de la Liche : 20 sacrifiés → Surge +15.
				surge = minf(100.0, surge + 0.75 * float(n2))
			_event({"t": "ring", "pos": at, "r": hr, "color": col, "dur": 0.6})
			_event({"t": "text", "pos": at + Vector2(0.0, 0.6), "text": "%d âmes" % n2, "color": col})
			return true
		"frenzy":
			# Déchaînement, Hurlement : un choc, puis toutes les invocations entrent en frénésie.
			if float(sp.get("damage", 0.0)) > 0.0:
				var hit2 := sp.duplicate()
				hit2["type"] = "aoe"
				_resolve_aoe(c, hit2, at)
			var fd := float(sp.get("dur", 6.0)) + (_mod("frenzy_dur") if c.idx == 0 else 0.0)
			frenzy_until = maxf(frenzy_until, time + fd)
			for a in allies:
				if a.alive:
					a.frenzy_t = maxf(a.frenzy_t, fd)
			_event({"t": "ring", "pos": Vector2(W * 0.5, CASTER_Y + 2.0), "r": 4.0, "color": col, "dur": 0.7})
			_event({"t": "text", "pos": Vector2(W * 0.5, CASTER_Y + 2.4), "text": "FRÉNÉSIE !", "color": col})
			return true
		"purify":
			if float(sp.get("damage", 0.0)) > 0.0:
				# Exorcisme : la purification frappe aussi les ennemis de Lumière.
				var ex := sp.duplicate()
				ex["type"] = "aoe"
				_resolve_aoe(c, ex, at)
			var pr := float(sp.get("radius", 2.5)) * (1.0 + _spell_mod(c, "radius.", sp))
			var cleared := clear_fog(at, pr)
			cleared = terrain.cleanse(at, pr) or cleared
			cleared = reveal_mirages(at, pr) or cleared
			var best: Portal = null
			var bd := 1e9
			for p in portals:
				if not p.is_negative():
					continue
				var d := Vector2(p.x, p.y).distance_to(at)
				if d < bd and d <= pr + p.width * 0.5:
					bd = d
					best = p
			if best == null:
				if cleared or float(sp.get("damage", 0.0)) > 0.0:
					_event({"t": "pillar", "pos": at, "dur": 1.1, "color": col})
				return cleared or float(sp.get("damage", 0.0)) > 0.0
			_purify(best)
			_event({"t": "pillar", "pos": Vector2(best.x, best.y), "dur": 1.1, "color": col})
			return true
		"barrier_shield":
			barrier_shield += float(sp.get("amount", 10))
			_event({"t": "ring", "pos": Vector2(W * 0.5, BARRIER_Y), "r": 2.5, "color": col, "dur": 0.5})
			_event({"t": "shield", "dur": 1.0, "color": col})
			return true
		"column":
			var w := float(sp.get("width", 0.8))
			var dmg := float(sp.get("damage", 30)) * c.atk_mult * _elem_mult(c, sp)
			var elem := str(sp.get("element", ""))
			for e in enemies:
				if e.alive and absf(e.pos.x - at.x) <= w * 0.5 + e.radius:
					_strike(c, sp, e, dmg, elem, Vector2(at.x, BARRIER_Y))
					if e.alive and elem in ["feu", "givre", "nature", "ombre"] and sp.has("grimoire"):
						_apply_status(e, elem)
			_event({"t": "beam", "a": Vector2(at.x, BARRIER_Y), "b": Vector2(at.x, H - 0.4), "color": col, "dur": 0.3, "w": 3.0})
			_event({"t": "arrow", "a": Vector2(at.x, BARRIER_Y), "b": Vector2(at.x, H - 0.4), "color": col, "dur": 0.3})
			_event({"t": "column", "fx": str(sp.get("fx", "beam")), "x": at.x, "w": w, "y0": BARRIER_Y, "y1": H - 0.4, "color": col})
			terrain.on_impact(c, sp, at, w * 0.5, dmg, Rect2(Vector2(at.x - w * 0.5, BARRIER_Y), Vector2(w, H - 0.4 - BARRIER_Y)))
			return true
	return false


func _mod(k: String) -> float:
	return float(mods.get(k, 0.0))


## Bonus de l'arbre propre à un sort (« radius.boule_de_feu », « dur.pluie_de_givre »), pour le joueur.
func _spell_mod(c: Caster, prefix: String, sp: Dictionary) -> float:
	return _mod(prefix + str(sp.get("id", ""))) if c.idx == 0 else 0.0


## Bonus de dégâts de l'arbre pour l'élément du sort (« elem_dmg.feu »), pour le joueur.
func _elem_mult(c: Caster, sp: Dictionary) -> float:
	return 1.0 + (_mod("elem_dmg." + str(sp.get("element", ""))) + _mod("spell_dmg") if c.idx == 0 else 0.0)


## Impact d'un sort de zone instantané (ou à la fin de son projectile).
func _resolve_aoe(c: Caster, sp: Dictionary, at: Vector2) -> void:
	var col := str(sp.get("color", "FFFFFF"))
	var r := float(sp.get("radius", 1.0)) * (1.0 + _spell_mod(c, "radius.", sp))
	var dmg := float(sp.get("damage", 0)) * c.atk_mult * _elem_mult(c, sp)
	var elem := str(sp.get("element", ""))
	var targets: Array = _query(_grid_e, at, r + 0.3)
	if bool(sp.get("single", false)):
		targets = _single_target(targets)
	for e: Unit in targets:
		_strike(c, sp, e, dmg, elem, at)
		if not e.alive:
			continue
		_apply_status(e, elem)
		if sp.has("root") and e.role != "boss":
			e.rooted_t = maxf(e.rooted_t, float(sp["root"]))
		if sp.has("freeze") and e.role != "boss":
			e.frozen_t = maxf(e.frozen_t, float(sp["freeze"]) + _mod("frozen_dur"))
	for t in towers:
		if t["alive"] and at.distance_to(t["pos"]) <= r + 0.45:
			t["hp"] = float(t["hp"]) - dmg
			t["flash"] = 0.1
			if float(t["hp"]) <= 0.0:
				t["alive"] = false
				surge = minf(100.0, surge + 10.0)
				_log("Tour de garde détruite (+10 Surge)")
	var nr := float(sp.get("nexus_ratio", 0.0))
	if nr > 0.0 and not nexus_shielded():
		for n in nexi:
			if n["alive"] and at.distance_to(n["pos"]) <= r + NEXUS_R:
				n["hp"] = float(n["hp"]) - dmg * nr
				n["flash"] = 0.2
				if float(n["hp"]) <= 0.0:
					n["hp"] = 0.0
					n["alive"] = false
				_event({"t": "text", "pos": (n["pos"] as Vector2) + Vector2(0.0, -0.8), "text": "-%d" % int(dmg * nr), "color": "FFFFFF"})
		_sync_nexus()
	terrain.on_impact(c, sp, at, r, dmg)
	if float(sp.get("barrier_heal", 0.0)) > 0.0:
		var bh := float(sp["barrier_heal"]) * (1.0 + _mod("heal_bonus"))
		if barrier_hp + bh > barrier_max:
			_wrath_acc += barrier_hp + bh - barrier_max
		barrier_hp = minf(barrier_max, barrier_hp + bh)
		_event({"t": "shield", "dur": 1.0, "color": col})
	if bool(sp.get("is_ult", false)) and c.idx == 0:
		if _mod("ult_heal") > 0.0 and barrier_hp < barrier_max:
			# Clé (Aube) des Flèches astrales : chaque impact de l'Ultime soigne la Barrière.
			barrier_hp = minf(barrier_max, barrier_hp + 2.0 * _mod("ult_heal"))
		if _mod("ult_wither") > 0.0:
			# Clé (Cendres) : l'Ultime flétrit et empoisonne.
			for e: Unit in _query(_grid_e, at, r + 0.3):
				if e.alive:
					_apply_status(e, "ombre")
					_apply_status(e, "nature")
	if bool(sp.get("chain_bolt", false)):
		# Orage d'acier : chaque impact de Mille lames lance un arc de foudre.
		var bolt := {"damage": dmg * 0.4 / maxf(0.01, c.atk_mult), "bounces": 3, "range": 2.2, "element": "foudre", "color": "FFE45C"}
		_chain(c, bolt, at, at)
	if float(sp.get("surge_gain", 0.0)) > 0.0 and c.idx == 0:
		surge = minf(100.0, surge + float(sp["surge_gain"]))
	var big := bool(sp.get("impact_flash", false))
	_event({"t": "explosion", "pos": at, "r": r, "color": col, "dur": 0.8 if big else 0.6, "big": big, "ice": bool(sp.get("fx_ice", false))})
	if big:
		_event({"t": "flash"})
		_event({"t": "shake"})


## Coup d'un sort sur un ennemi, avec les effets du grimoire de classe : exécution (cible affaiblie),
## gros gibier (élites et boss), proie marquée, critique en plus ; puis marque, givre, recul, statuts.
func _strike(c: Caster, sp: Dictionary, e: Unit, dmg: float, elem: String, origin: Vector2) -> void:
	var d := dmg
	if sp.has("execute") and e.hp < e.max_hp * 0.35:
		d *= 1.0 + float(sp["execute"])
	if sp.has("big_game") and (e.role in ["boss", "elite", "brute", "tete"] or e.max_hp >= 200.0):
		d *= 1.0 + float(sp["big_game"])
	if sp.has("marked_bonus") and e.marked_t > 0.0:
		d *= 1.0 + float(sp["marked_bonus"])
	_damage(e, _calc(d, elem, c.crit + float(sp.get("crit_add", 0.0)), e, false), elem)
	if not e.alive:
		return
	if sp.has("mark"):
		e.marked_t = maxf(e.marked_t, float(sp["mark"]))
	if sp.has("chill") and e.role != "boss":
		e.slow_stacks = mini(4, e.slow_stacks + int(sp["chill"]))
		e.slow_t = maxf(e.slow_t, 3.0)
	if sp.has("knock") and e.role not in ["boss", "tete", "banniere", "rune"] and e.hold_y <= 0.0:
		var away := (e.pos - origin).normalized() if e.pos.distance_squared_to(origin) > 0.01 else Vector2(0.0, 1.0)
		away.y = maxf(away.y, 0.35)
		e.pos = Vector2(clampf(e.pos.x + away.x * float(sp["knock"]) * 0.4, 0.3, W - 0.3), minf(H - 0.6, e.pos.y + away.y * float(sp["knock"])))
	for st in sp.get("status", []):
		_apply_status(e, str(st))
	if sp.has("weak"):
		e.weak_t = maxf(e.weak_t, float(sp["weak"]))
	if sp.has("wither"):
		# Flétrissure (Souffle de cendre) : les soins reçus sont réduits de moitié.
		e.wither_t = maxf(e.wither_t, float(sp["wither"]))
	if sp.has("stun") and e.role != "boss":
		e.rooted_t = maxf(e.rooted_t, float(sp["stun"]))
	if sp.has("bleed") and e.alive:
		# Saignement : 3,5 % des PV (plafonnés) par seconde.
		e.bleed_t = maxf(e.bleed_t, float(sp["bleed"]))
		e.bleed_dps = maxf(e.bleed_dps, 0.035 * _dot_base(e) * effect_mult)


## Tir unique : la plus grosse cible de la zone (élite, boss), sinon la plus proche du centre.
func _single_target(targets: Array) -> Array:
	var best: Unit = null
	for e: Unit in targets:
		if e.alive and (best == null or e.max_hp > best.max_hp):
			best = e
	return [best] if best != null else []


## Renfort du grimoire de classe : les invocations (toutes, ou celles du rayon) gagnent dégâts, cadence,
## critique, bouclier ou soin pendant « dur » s. Retourne le nombre d'invocations renforcées.
func _rally(c: Caster, r: Dictionary, at: Vector2, col: String) -> int:
	var dur := float(r.get("dur", 6.0))
	var rad := float(r.get("radius", 0.0))
	var n := 0
	var pts: Array = []
	# Les tirs de classe lancés pendant le Renfort en profitent aussi (ils ne vivent pas assez longtemps
	# pour le recevoir en vol).
	shot_buff_until = maxf(shot_buff_until, time + dur)
	shot_buff = {"atk": float(r.get("atk", 0.0)), "crit": float(r.get("crit", 0.0)), "aspd": float(r.get("aspd", 0.0)), "steal": float(r.get("steal", 0.0))}
	for a in allies:
		if not a.alive or a.role == "escort" or a.shot != "":
			continue
		if rad > 0.0 and a.pos.distance_to(at) > rad:
			continue
		if pts.size() < 24 and n % 2 == 0:
			pts.append(a.pos)
		a.buff_t = maxf(a.buff_t, dur)
		a.buff_atk = maxf(a.buff_atk, float(r.get("atk", 0.0)))
		a.buff_crit = maxf(a.buff_crit, float(r.get("crit", 0.0)))
		a.buff_aspd = maxf(a.buff_aspd, float(r.get("aspd", 0.0)))
		a.buff_steal = maxf(a.buff_steal, float(r.get("steal", 0.0)))
		a.buff_thorns = maxf(a.buff_thorns, float(r.get("thorns", 0.0)))
		if r.has("shield"):
			a.shield = maxf(a.shield, a.max_hp * float(r["shield"]))
		if r.has("heal"):
			a.hp = minf(a.max_hp, a.hp + a.max_hp * float(r["heal"]))
		n += 1
	_event({"t": "rally", "pos": at, "from": Vector2(c.x, CASTER_Y + 0.3), "r": rad if rad > 0.0 else 4.0, "color": col, "n": n, "dur": dur, "pts": pts})
	if ClassFire.spec_of(c).has("shot"):
		# Classe qui tire (Archer, Épéiste…) : le Renfort porte sur ses tirs, même sans invocation.
		n += 1
	if n > 0:
		_event({"t": "text", "pos": Vector2(c.x, CASTER_Y + 1.6), "text": str(r.get("label", "RENFORT !")), "color": col})
	return n


func _update_impacts() -> void:
	var i := 0
	while i < pending_impacts.size():
		var p: Dictionary = pending_impacts[i]
		p["t"] = float(p["t"]) - TICK
		if p.has("lead") and float(p["t"]) <= float(p["lead"]):
			# Barrage : l'animation de chute part juste avant l'impact.
			var sp: Dictionary = p["sp"]
			_sid = str(sp.get("id", ""))
			_event({"t": str(p["fx"]), "from": p["from"], "to": p["at"], "pos": p["at"], "dur": maxf(0.05, float(p["t"])),
				"r": float(sp.get("radius", 1.0)), "color": str(sp.get("color", "FFFFFF")), "tint": bool(sp.get("tint", false))})
			p.erase("lead")
			_sid = ""
		if float(p["t"]) <= 0.0:
			pending_impacts.remove_at(i)
			_sid = str((p["sp"] as Dictionary).get("id", ""))
			_sid_owner = int(p["c"])
			_resolve_aoe(casters[int(p["c"])], p["sp"], p["at"])
			_sid = ""
		else:
			i += 1


## Zones actives : dégâts continus, ralentissement (Racines), attraction (Vortex), cumuls de givre.
func _update_zones() -> void:
	for e in enemies:
		e.zone_slow = 0.0
	var i := 0
	while i < zones.size():
		var z: Dictionary = zones[i]
		z["t"] = float(z["t"]) - TICK
		var pos: Vector2 = z["pos"]
		var elem := str(z["elem"])
		var slow := float(z["slow"])
		var pull := float(z["pull"])
		var dps := float(z["dps"])
		var stack := false
		if float(z["stack_every"]) > 0.0:
			z["stack_acc"] = float(z["stack_acc"]) + TICK
			if float(z["stack_acc"]) >= float(z["stack_every"]):
				z["stack_acc"] = float(z["stack_acc"]) - float(z["stack_every"])
				stack = true
		for e in _query(_grid_e, pos, float(z["r"]) + 0.25):
			if not e.alive:
				continue
			if slow > 0.0:
				e.zone_slow = maxf(e.zone_slow, slow)
			if pull > 0.0 and e.role != "boss" and e.hold_y <= 0.0:
				var d: Vector2 = pos - e.pos
				var dl: float = d.length()
				if dl > 0.25:
					e.pos += d / dl * minf(pull * TICK, dl - 0.25)
			if dps > 0.0:
				_damage(e, _calc(dps, elem, 0.0, e, false) * TICK, elem)
			if stack and e.alive:
				_apply_status(e, elem)
		if str(z.get("spawn", "")) != "":
			# Cimetière, Ossuaire, Nécropole : des morts sortent de terre à intervalle régulier.
			z["spawn_acc"] = float(z["spawn_acc"]) + TICK
			if float(z["spawn_acc"]) >= float(z["spawn_every"]):
				z["spawn_acc"] = 0.0
				var sp_pos: Vector2 = pos + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * float(z["r"]) * 0.8
				_raise_unit(str(z["spawn"]), int(z["c"]), sp_pos, float(z["life"]))
		if float(z.get("ally_atk", 0.0)) > 0.0 or float(z.get("ally_aspd", 0.0)) > 0.0:
			# Étendards, totems : les invocations proches frappent plus fort, plus vite.
			for a: Unit in _query(_grid_a, pos, float(z["r"])):
				if a.alive:
					a.buff_t = maxf(a.buff_t, 0.25)
					a.buff_atk = maxf(a.buff_atk, float(z["ally_atk"]))
					a.buff_aspd = maxf(a.buff_aspd, float(z.get("ally_aspd", 0.0)))
		if float(z.get("ally_heal", 0.0)) > 0.0:
			# Sanctuaires : les invocations dans la zone regagnent une part de leurs PV chaque seconde.
			for a: Unit in _query(_grid_a, pos, float(z["r"])):
				if a.alive and a.hp < a.max_hp:
					var h := a.max_hp * float(z["ally_heal"]) * TICK
					healed_total += minf(h, a.max_hp - a.hp)
					a.hp = minf(a.max_hp, a.hp + h)
		if float(z.get("ally_shield", 0.0)) > 0.0:
			# Cercle runique : les alliés dans le cercle gardent un bouclier.
			for a: Unit in _query(_grid_a, pos, float(z["r"])):
				if a.alive:
					a.shield = maxf(a.shield, float(z["ally_shield"]))
		if float(z["t"]) <= 0.0:
			zones.remove_at(i)
		else:
			i += 1


## Éclair en chaîne : frappe l'ennemi le plus proche du point visé (2,5 m), puis rebondit.
func _chain(c: Caster, sp: Dictionary, at: Vector2, from: Vector2) -> bool:
	var tgt: Unit = null
	var best := 2.5
	for e in _query(_grid_e, at, 2.5):
		var d0: float = e.pos.distance_to(at)
		if e.alive and d0 < best:
			best = d0
			tgt = e
	if tgt == null:
		return false
	var dmg := float(sp.get("damage", 40)) * c.atk_mult * _elem_mult(c, sp)
	var reach := float(sp.get("range", 2.4))
	var elem := str(sp.get("element", "foudre"))
	var pts: Array = [from]
	var hit := {}
	for k in range(int(sp.get("bounces", 5)) + (int(_mod("chain_bonus")) if c.idx == 0 else 0)):
		pts.append(tgt.pos)
		hit[tgt.id] = true
		_strike(c, sp, tgt, dmg, elem, pts[pts.size() - 2])
		if tgt.alive and elem in ["feu", "givre", "nature", "ombre"] and sp.has("grimoire"):
			_apply_status(tgt, elem)
		dmg *= float(sp.get("falloff", 0.8))
		var next: Unit = null
		var bd := reach
		for e in _query(_grid_e, tgt.pos, reach):
			if e.alive and not hit.has(e.id):
				var d: float = e.pos.distance_to(tgt.pos)
				if d < bd:
					bd = d
					next = e
		if next == null:
			break
		tgt = next
	_event({"t": "lightning", "pts": pts, "dur": 0.45, "color": str(sp.get("color", "F0D23C"))})
	terrain.on_impact(c, sp, pts[1], 1.0, float(sp.get("damage", 40)) * c.atk_mult)
	return true


## Onde arcanique : dégâts et recul vers le fond de l'arène (les boss et les soigneurs fixes résistent).
func _wave(c: Caster, sp: Dictionary, at: Vector2) -> void:
	var r := float(sp.get("radius", 2.4))
	var dmg := float(sp.get("damage", 20)) * c.atk_mult * _elem_mult(c, sp)
	var push := float(sp.get("push", 2.0))
	var elem := str(sp.get("element", ""))
	for e in _query(_grid_e, at, r + 0.3):
		if not e.alive:
			continue
		_damage(e, _calc(dmg, elem, c.crit, e, false), elem)
		if not e.alive or e.role in ["boss", "tete", "banniere"] or e.hold_y > 0.0:
			continue
		var k := 1.0 - 0.5 * clampf(e.pos.distance_to(at) / r, 0.0, 1.0)
		e.pos.y = minf(H - 0.6, e.pos.y + push * k)
		e.pos.x = clampf(e.pos.x + signf(e.pos.x - at.x) * push * 0.25 * k, 0.3, W - 0.3)
	_event({"t": "wave", "pos": at, "r": r, "dur": 0.7, "color": str(sp.get("color", "B07CFF"))})
	terrain.on_impact(c, sp, at, r, dmg)


# ---------------------------------------------------------------- Don racial (étape 13.2)

func don_ready() -> bool:
	return state == "running" and not don.is_empty() and don_t <= 0.0


## Lance le Don racial du joueur. « at » sert au Souffle (Draconique).
func use_don(at: Vector2 = Vector2(-1.0, -1.0)) -> bool:
	if not don_ready():
		return false
	var pw := 1.0 + float(don.get("power", 0.0))
	var c := casters[0]
	var col := str(don.get("color", "F2C46B"))
	match str(don.get("id", "")):
		"ralliement":
			rally_t = 6.0 * pw
			_event({"t": "ring", "pos": Vector2(c.x, CASTER_Y + 1.0), "r": 4.0, "color": col, "dur": 0.8})
			_log("Ralliement : attaque des invocations +20 %% pendant %d s !" % int(rally_t))
		"pas_de_brise":
			breeze_t = 5.0 * pw
			_event({"t": "ring", "pos": Vector2(c.x, CASTER_Y + 0.8), "r": 2.5, "color": col, "dur": 0.8})
			_log("Pas de brise : cadence du Flux +50 %% pendant %d s !" % int(breeze_t))
		"rempart_runique":
			var amount := (20.0 + float(c.level) * 0.5) * pw
			barrier_shield += amount
			_event({"t": "shield", "dur": 1.0, "color": col})
			_event({"t": "text", "pos": Vector2(W * 0.5, BARRIER_Y + 0.6), "text": "+%d bouclier" % int(amount), "color": col})
			_log("Rempart runique : la Barrière gagne %d de bouclier." % int(amount))
		"charge_des_clans":
			charge_t = 4.0 * pw
			_event({"t": "shake"})
			_log("Charge des clans : les invocations repoussent l'ennemi pendant %d s !" % int(charge_t))
		"nuee_feerique":
			var n := int(round(12.0 * pw))
			for k in range(n):
				var u := _make_unit("fairy_swarm", 0, Vector2(clampf(c.x + rng.randf_range(-1.5, 1.5), 0.4, W - 0.4), CASTER_Y + 0.5 + rng.randf_range(0.0, 0.6)))
				u.owner_idx = 0
				u.atk *= c.atk_mult
				u.hp *= c.hp_mult
				u.max_hp = u.hp
				_add_ally(u)
			barrier_hp = minf(barrier_max, barrier_hp + 10.0 * pw * (1.0 + _mod("heal_bonus")))
			_event({"t": "shield", "dur": 1.0, "color": col})
			_log("Nuée féerique : %d lucioles !" % n)
		"souffle":
			var x := at.x if at.x >= 0.0 else c.x
			var rc := Rect2(Vector2(x - 1.6, BARRIER_Y), Vector2(3.2, 5.5))
			var dmg := 70.0 * c.atk_mult * pw * (1.0 + _mod("elem_dmg.feu"))
			for e in enemies:
				if e.alive and rc.has_point(e.pos):
					_damage(e, _calc(dmg, "feu", c.crit, e, false), "feu")
					_apply_status(e, "feu")
			_event({"t": "column", "fx": "flames", "x": x, "w": 3.2, "y0": BARRIER_Y, "y1": BARRIER_Y + 5.5, "color": col})
			terrain.on_impact(c, {"element": "feu", "type": "aoe"}, Vector2(x, BARRIER_Y + 2.5), 1.6, dmg)
			_log("Souffle de dragon !")
		"mue":
			barrier_invuln_t = 2.0 * pw
			for a in allies:
				if a.alive:
					a.poison_stacks = 0
					a.slow_stacks = 0
					a.zone_slow = 0.0
			terrain.cleanse(Vector2(W * 0.5, BARRIER_Y + 2.0), 3.5)
			_event({"t": "shield", "dur": 1.2, "color": col})
			_log("Mue : effets néfastes purgés, Barrière invulnérable %.1f s." % barrier_invuln_t)
		"retour":
			var n := mini(_fallen.size(), int(round(10.0 * pw)))
			for k in range(n):
				var f: Dictionary = _fallen.pop_back()
				var u := _make_unit(str(f["kind"]), 0, Vector2(clampf(c.x + rng.randf_range(-1.5, 1.5), 0.4, W - 0.4), CASTER_Y + 0.6))
				u.owner_idx = 0
				u.element = str(f["element"])
				u.atk = float(f["atk"])
				u.hp = float(f["hp"])
				u.max_hp = u.hp
				_add_ally(u)
			_event({"t": "ring", "pos": Vector2(c.x, CASTER_Y + 1.0), "r": 3.0, "color": col, "dur": 0.8})
			_log("Retour : %d invocations relevées." % n)
		_:
			return false
	don_t = float(don.get("cd", 60.0))
	_event({"t": "text", "pos": Vector2(c.x, CASTER_Y + 1.6), "text": str(don.get("name", "Don")).to_upper(), "color": col})
	return true


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
		u.hp *= c.hp_mult * (1.0 + _mod("champ_hp"))
		u.max_hp = u.hp
		u.crit = c.crit
		u.element = "givre" if _mod("champ_givre") > 0.0 else last_elem
		u.atk *= 1.0 + _mod("champ_atk")
		if _mod("hawk_eye") > 0.0:
			# Clé de voûte Œil du faucon : critiques fréquents et dévastateurs.
			u.crit += 0.25
			u.crit_mult = 2.5
			u.attack_range = maxf(u.attack_range, 4.2) * 1.2
		if _mod("vanguard") > 0.0:
			# Clé de voûte Avant-garde : le Champion charge en ligne droite à son apparition.
			_charge_line(u)
		_pending_allies.append(u)
		if _mod("double_guard") > 0.0 or _mod("double_drain") > 0.0:
			# Lame spectrale : un double du Champion (Aube : protecteur ; Cendres : vampire).
			var g := _clone(u, Vector2(0.7 if x < W * 0.5 else -0.7, 0.0))
			g.atk *= 0.6
			g.hp = u.max_hp * 0.6
			g.max_hp = g.hp
			if _mod("double_guard") > 0.0:
				g.shield = g.max_hp * 0.5
				barrier_shield += 20.0
			else:
				g.lifesteal = 0.3
			_pending_allies.append(g)
			_event({"t": "summon", "pos": g.pos, "dur": 0.9, "color": "B8C8FF"})
		_event({"t": "ring", "pos": u.pos, "r": 1.0, "color": "F2C46B", "dur": 0.5})
		_event({"t": "summon", "pos": u.pos, "dur": 0.9, "color": "F2C46B"})
	champion_charge = 0
	_log("Champion invoqué : %s" % str(units_db[champion_kind]["name"]))
	return true


func _charge_line(u: Unit) -> void:
	var dmg := u.atk * 3.0
	for e in enemies:
		if e.alive and absf(e.pos.x - u.pos.x) <= 0.8 + e.radius:
			_damage(e, _calc(dmg, "lumiere", 0.0, e, false), "lumiere")
			if e.alive and e.role not in ["boss", "tete", "banniere"] and e.hold_y <= 0.0:
				e.pos.y = minf(H - 0.6, e.pos.y + 2.0)
	u.pos.y = minf(H * 0.6, u.pos.y + 4.0)
	u.prev_pos = u.pos
	_event({"t": "column", "fx": "beam", "x": u.pos.x, "w": 1.6, "y0": CASTER_Y + 0.7, "y1": H - 0.4, "color": "F2D48B"})
	_event({"t": "shake"})


func ultimate_ready() -> bool:
	return state == "running" and surge >= 100.0


func cast_ultimate(at: Vector2) -> bool:
	if not ultimate_ready():
		return false
	var sp: Dictionary = (spells_db[ultimate_id] as Dictionary).duplicate()
	sp["radius"] = float(sp.get("radius", 3.0)) * (1.0 + _mod("ult_radius"))
	sp["damage"] = float(sp.get("damage", 200)) * (1.0 + _mod("ult_dmg"))
	if sp.has("count"):
		sp["count"] = int(sp["count"]) + int(_mod("ult_count"))
	if sp.has("dur"):
		sp["dur"] = float(sp["dur"]) + _mod("ult_dur")
	if _mod("ult_chain") > 0.0:
		sp["chain_bolt"] = true
	sp["is_ult"] = true
	_sid = ultimate_id
	_sid_owner = 0
	_event({"t": "spell", "pos": at, "from": Vector2(casters[0].x, CASTER_Y + 0.3), "r": float(sp["radius"]), "color": str(sp.get("color", "FFFFFF")), "ult": true})
	_apply_spell(casters[0], sp, at)
	_sid = ""
	# Toute Ultime cautérise les moignons de l'hydre pendant 6 s dans sa zone (comme les braises du Météore).
	ult_wards.append({"pos": at, "r": maxf(float(sp["radius"]), float(sp.get("spread", 0.0)) + 0.5), "t": 6.0})
	surge = 0.0
	if not bool(sp.get("impact_flash", false)):
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
		if absf(x - p.x) > p.width * 0.5 or not p.active():
			continue
		if p.kind == "answer":
			# Énigme : l'IA connaît le lore et vise la bonne réponse.
			v += 8.0 if not riddle.is_empty() and p.id == int(riddle["right"]) else -4.0
			continue
		var before := v
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
				for ru in runes:
					if ru.alive and ru.element == p.element:
						v += 4.0
						break
			"forge":
				v += 1.5 * forge_power
			_:
				v += 1.0
		if p.mirage:
			# Un mirage ressemble à un vrai portail : l'IA s'y laisse prendre à moitié.
			v = before + (v - before) * 0.5
	for f in fires:
		# Incendies : l'IA évite d'envoyer ses invocations dans le feu.
		if absf(x - float(f["x"])) <= float(f["w"]) * 0.5 + 0.2 and float(f.get("cool", 0.0)) <= 0.0:
			v -= 2.0 * clampf((float(f["top"]) - float(f["front"])) / 5.0, 0.3, 1.6)
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
	var v := 0.0
	for tx in _objective_xs():
		v = maxf(v, 2.0 / (1.0 + absf(x - tx)))
	if escort != null and escort.alive:
		v += 1.5 / (1.0 + absf(x - escort.pos.x))
	for e in enemies:
		if e.alive and e.role == "soigneur" and absf(e.pos.x - x) < 0.8:
			v += 3.0
	return v


func _objective_xs() -> Array[float]:
	var out: Array[float] = []
	if boss != null and boss.alive:
		out.append(boss.pos.x)
	for n in nexi:
		if n["alive"]:
			out.append((n["pos"] as Vector2).x)
	if out.is_empty():
		out.append(NEXUS_POS.x)
	return out


# ---------------------------------------------------------------- objectif (interface et IA)

## Part restante de l'objectif : 1 au départ, 0 à la victoire.
func objective_ratio() -> float:
	match objective:
		"boss":
			return clampf(boss.hp / boss.max_hp, 0.0, 1.0) if boss != null else 0.0
		"escort":
			if escort == null:
				return 0.0
			return clampf(1.0 - (escort.pos.y - escort_start_y) / maxf(0.1, escort_goal_y - escort_start_y), 0.0, 1.0)
	return clampf(nexus_hp / maxf(1.0, nexus_max), 0.0, 1.0)


func objective_title() -> String:
	match objective:
		"boss":
			return boss_name.to_upper()
		"escort":
			return str(units_db.get(escort.kind, {}).get("name", "Escorte")).to_upper() if escort != null else "ESCORTE"
	return "NEXUS" if nexi.size() <= 1 else "%d NEXUS" % nexi.size()


## Valeur et maximum de la barre d'objectif.
func objective_bar() -> Vector2:
	match objective:
		"boss":
			return Vector2(maxf(0.0, boss.hp), boss.max_hp) if boss != null else Vector2(0.0, 1.0)
		"escort":
			return Vector2(1.0 - objective_ratio(), 1.0)
	return Vector2(nexus_hp, nexus_max)


func objective_info() -> String:
	var parts: Array[String] = []
	match objective:
		"boss":
			if boss != null:
				parts.append("%d / %d" % [int(ceil(maxf(0.0, boss.hp))), int(boss.max_hp)])
				parts.append("phase %d/3" % (boss_phase + 1))
				if boss_shield_t > 0.0:
					parts.append("%s : seul le %s blesse" % [shield_word().to_upper(), str(ELEM_NAMES.get(boss_shield_elem, boss_shield_elem))])
				if banners_alive() > 0:
					parts.append("ARMURE : %d bannière%s" % [banners_alive(), "s" if banners_alive() > 1 else ""])
				if heads_alive() > 0:
					parts.append("TÊTES : %d (corps protégé)" % heads_alive())
				if runes_alive() > 0:
					var rel: Array[String] = []
					for ru in runes:
						if ru.alive:
							rel.append(str(ELEM_NAMES.get(ru.element, ru.element)))
					parts.append("RUNES : %s (corps protégé)" % ", ".join(rel))
				if not stumps.is_empty():
					parts.append("BRÛLE %d plaie%s !" % [stumps.size(), "s" if stumps.size() > 1 else ""])
		"escort":
			if escort != null:
				parts.append("%s %d / %d PV" % [{"lantern": "Lanterne", "caravan": "Chariot", "barge": "Barque", "rune_cart": "Chariot runique"}.get(escort.kind, "Escorte"), int(ceil(maxf(0.0, escort.hp))), int(escort.max_hp)])
				parts.append("trajet %d %%" % int((1.0 - objective_ratio()) * 100.0))
		_:
			parts.append("%d / %d" % [int(ceil(nexus_hp)), int(nexus_max)])
			if nexi.size() > 1:
				var dead := 0
				for n in nexi:
					if not n["alive"]:
						dead += 1
				parts.append("%d/%d détruits" % [dead, nexi.size()])
			if nexus_shielded():
				parts.append("SCELLÉ (sceaux %d/%d)" % [seals_purified(), seals_total])
	if healers_alive() > 0:
		parts.append("soin ennemi")
	return " · ".join(parts)


func objective_pos() -> Vector2:
	if boss != null and boss.alive:
		return boss.pos
	for n in nexi:
		if n["alive"]:
			return n["pos"]
	if escort != null:
		return escort.pos
	return NEXUS_POS


## Débogage et tests : place l'objectif à une fraction donnée.
func debug_set_ratio(r: float) -> void:
	match objective:
		"boss":
			boss.hp = boss.max_hp * r
		"escort":
			escort.pos.y = escort_start_y + (escort_goal_y - escort_start_y) * (1.0 - r)
		_:
			for n in nexi:
				n["hp"] = float(n["max"]) * r
				if r <= 0.0:
					n["alive"] = false
			_sync_nexus()


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


## Invocation relevée par un sort (Cimetière, Terre des morts) : comme une armée, au compte du lanceur.
func _raise_unit(kind: String, ci: int, p: Vector2, life: float) -> void:
	if not units_db.has(kind) or allies.size() >= 600:
		return
	var c := casters[clampi(ci, 0, casters.size() - 1)]
	p = Vector2(clampf(p.x, 0.4, W - 0.4), clampf(p.y, BARRIER_Y + 0.6, H - 1.0))
	var u := _make_unit(kind, 0, p)
	u.owner_idx = c.idx
	u.atk *= c.atk_mult
	u.hp *= c.hp_mult
	if c.idx == 0:
		_player_unit_mods(u)
	u.max_hp = u.hp
	u.crit = c.crit
	u.life_t = life
	summoned += 1
	_add_ally(u)
	_event({"t": "puff", "pos": p, "color": "B07CFF"})


## Plus grosse cible à portée (boss, élite, brute) : visée des tirs uniques du grimoire.
func strongest_enemy(max_y: float = H) -> Unit:
	var best: Unit = null
	for e in enemies:
		if e.alive and e.pos.y <= max_y and e.role not in ["escort"] and (best == null or e.max_hp > best.max_hp):
			best = e
	return best


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

# ---------------------------------------------------------------- zone 5 : Désert de Verre

## Cycle soleil/lune : le jour, le Feu +25 % ; la nuit, le Givre +25 % (amis comme ennemis).
func _update_daynight() -> void:
	if daynight_cfg.is_empty():
		return
	daynight_t -= TICK * daynight_speed
	if daynight_t <= 0.0:
		_switch_daynight()


func _switch_daynight() -> void:
	is_day = not is_day
	daynight_t = float(daynight_cfg.get("day" if is_day else "night", 25.0))
	_event({"t": "daynight", "day": is_day})
	_event({"t": "text", "pos": Vector2(W * 0.5, 8.0), "text": "LE SOLEIL SE LÈVE" if is_day else "LA NUIT TOMBE", "color": "FFD070" if is_day else "9FB8FF"})
	_log("Le soleil se lève : Feu +25 %." if is_day else "La nuit tombe : Givre +25 %.")


## Part écoulée de la phase en cours (jour ou nuit), pour l'affichage.
func daynight_ratio() -> float:
	if daynight_cfg.is_empty():
		return 0.0
	var full := float(daynight_cfg.get("day" if is_day else "night", 25.0))
	return clampf(1.0 - daynight_t / maxf(0.1, full), 0.0, 1.0)


## Mirage : révélé quand une invocation l'approche ; il se dissipe, puis se reforme ailleurs.
func _update_mirage(p: Portal) -> void:
	if p.revealed_t > 0.0:
		p.revealed_t -= TICK
		if p.revealed_t <= 0.0:
			p.revealed_t = 0.0
			p.hidden_t = mirage_reform if not p.spots.is_empty() else 999.0
		return
	if p.hidden_t > 0.0:
		p.hidden_t -= TICK
		if p.hidden_t <= 0.0:
			p.hidden_t = 0.0
			_relocate_mirage(p)
		return
	if _nearest(_grid_a, Vector2(p.x, p.y - 0.6), 0.75) != null:
		_reveal_mirage(p)


func _reveal_mirage(p: Portal) -> void:
	if not p.mirage or p.revealed_t > 0.0 or p.hidden_t > 0.0:
		return
	p.revealed_t = 1.2
	_event({"t": "text", "pos": Vector2(p.x, p.y + 0.6), "text": "MIRAGE !", "color": "F2E0B0"})
	_event({"t": "puff", "pos": Vector2(p.x, p.y), "color": "F2E0B0"})


## Un mirage se reforme sur un autre emplacement libre de sa rangée, avec un autre faux effet.
func _relocate_mirage(p: Portal) -> void:
	var free: Array[float] = []
	for sx in p.spots:
		var ok := true
		for o in portals:
			if o != p and absf(o.y - p.y) < 0.6 and absf(o.x - float(sx)) < (o.width + p.width) * 0.5:
				ok = false
		if ok and absf(float(sx) - p.x) > 0.5:
			free.append(float(sx))
	if not free.is_empty():
		p.x = free[rng.randi() % free.size()]
		p.base_x = p.x
	var fakes := [["mult", 2], ["mult", 3], ["add", 5]]
	var f: Array = fakes[rng.randi() % fakes.size()]
	p.kind = str(f[0])
	p.value = int(f[1])
	p.ready = true
	_event({"t": "ring", "pos": Vector2(p.x, p.y), "r": 1.0, "color": "F2E0B0", "dur": 0.5})


## La Lumière (Purifier) dissipe les mirages proches. Retourne true si au moins un l'a été.
func reveal_mirages(at: Vector2, r: float) -> bool:
	var any := false
	for p in portals:
		if p.mirage and p.active() and Vector2(p.x, p.y).distance_to(at) <= r + p.width * 0.5:
			_reveal_mirage(p)
			any = true
	return any


func mirages_active() -> int:
	var n := 0
	for p in portals:
		if p.mirage and p.active():
			n += 1
	return n


## Énigme du Sphinx : 3 portails-réponses ; le Sphinx est protégé jusqu'à la réponse.
func _start_riddle(ab: Dictionary) -> void:
	if not riddle.is_empty():
		return
	var pool: Array[int] = []
	for k in range(RIDDLES.size()):
		if not _riddles_used.has(k):
			pool.append(k)
	if pool.is_empty():
		for k in range(RIDDLES.size()):
			pool.append(k)
	var idx: int = pool[rng.randi() % pool.size()]
	_riddles_used.append(idx)
	var rd: Dictionary = RIDDLES[idx]
	var answers: Array = rd["a"]
	var order: Array[int] = [0, 1, 2]
	for i in range(2, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	var xs: Array = ab.get("xs", [1.7, 4.5, 7.3])
	var made: Array[Portal] = []
	var right_id := 0
	for i in range(3):
		var p := Portal.new()
		_portal_seq += 1
		p.id = _portal_seq
		p.kind = "answer"
		p.answer = str(answers[order[i]])
		p.need = riddle_need if riddle_need > 0 else int(ab.get("need", 10))
		p.x = float(xs[i])
		p.base_x = p.x
		p.y = float(ab.get("y", 7.8))
		p.width = float(ab.get("width", 1.9))
		if order[i] == 0:
			right_id = p.id
		portals.append(p)
		made.append(p)
	portals.sort_custom(func(a: Portal, b: Portal) -> bool: return a.y < b.y)
	riddle = {"q": str(rd["q"]), "portals": made, "right": right_id, "t": float(ab.get("time", 40.0))}
	_log("Énigme du Sphinx : « %s »" % str(rd["q"]))
	_event({"t": "text", "pos": Vector2(W * 0.5, 9.0), "text": "ÉNIGME !", "color": "F2C46B"})
	_event({"t": "ring", "pos": boss.pos if boss != null else Vector2(W * 0.5, 13.0), "r": 3.5, "color": "F2C46B", "dur": 0.8})


func _update_riddle() -> void:
	if riddle.is_empty():
		return
	riddle["t"] = float(riddle["t"]) - TICK
	if float(riddle["t"]) <= 0.0:
		_log("Le Sphinx s'impatiente : pas de réponse, c'est une mauvaise réponse.")
		_resolve_riddle(false)


func _resolve_riddle(ok: bool) -> void:
	for p in riddle.get("portals", []):
		portals.erase(p)
	riddle = {}
	if boss == null or not boss.alive:
		return
	if ok:
		riddles_right += 1
		boss_exposed_t = 20.0
		if riddles_right >= 2:
			bonus_unique = str(level.get("riddle_reward", ""))
		_log("Bonne réponse ! %s est exposé : +50 %% de dégâts pendant 20 s." % boss_name)
		_event({"t": "text", "pos": boss.pos + Vector2(0.0, -1.2), "text": "BONNE RÉPONSE !", "color": "F2C46B"})
		_event({"t": "ring", "pos": boss.pos, "r": 3.0, "color": "FFF0B0", "dur": 0.8})
	else:
		riddles_wrong += 1
		var before := boss.hp
		boss.hp = minf(boss.max_hp, boss.hp + boss.max_hp * 0.1)
		boss.enraged_t = 20.0
		_log("Mauvaise réponse : %s se renforce (+%d PV, coups +30 %%)." % [boss_name, int(boss.hp - before)])
		_event({"t": "text", "pos": boss.pos + Vector2(0.0, -1.2), "text": "MAUVAISE RÉPONSE", "color": "FF6A5A"})
		_event({"t": "ring", "pos": boss.pos, "r": 3.0, "color": "FF4A3A", "dur": 0.8})


## Texte de l'énigme en cours ("" sinon), pour le bandeau du combat.
func riddle_text() -> String:
	return str(riddle.get("q", ""))


func _event(e: Dictionary) -> void:
	if _sid != "" and not e.has("sid"):
		e["sid"] = _sid
	if events.size() < 400:
		events.append(e)


func _log(text: String) -> void:
	log_lines.append(text)
	if log_lines.size() > 40:
		log_lines.remove_at(0)


# ---------------------------------------------------------------- zone 6 · Forêt Cendrée

## Incendie : un couloir de feu part de la lisière ennemie et descend vers la Barrière.
func _update_wildfire() -> void:
	if wildfire_cfg.is_empty():
		return
	wildfire_t -= TICK
	if wildfire_t > 0.0:
		return
	var ev: Array = wildfire_cfg.get("every", [18, 24])
	wildfire_t = rng.randf_range(float(ev[0]), float(ev[1]))
	var n := 0
	for f in fires:
		if not bool(f["patch"]):
			n += 1
	if n < int(wildfire_cfg.get("max", 1)):
		start_wildfire(_fire_lane())


func start_wildfire(x: float) -> void:
	var c := wildfire_cfg
	_add_fire(x, float(c.get("width", 1.4)), FIRE_TOP - 0.4, FIRE_TOP, float(c.get("speed", 0.5)), float(c.get("life", 22.0)), false, "incendie")
	fires.back()["stop"] = float(c.get("stop", 3.2))
	_event({"t": "text", "pos": Vector2(x, 12.4), "text": "LA FORÊT S'EMBRASE !", "color": "FFB04A"})
	_log("Un incendie dévale la forêt : éteins-le au Givre !")


## Colonne de l'incendie : loin des autres couloirs, plutôt là où passent les invocations.
func _fire_lane() -> float:
	var best := rng.randf_range(1.2, W - 1.2)
	var best_s := -1e9
	var x := 1.2
	while x <= W - 1.2:
		var ok := true
		for f in fires:
			if not bool(f["patch"]) and absf(float(f["x"]) - x) < 2.2:
				ok = false
		if ok:
			var s := rng.randf() * 2.0
			for a in allies:
				if a.alive and a.shot == "" and absf(a.pos.x - x) < 0.8:
					s += 0.15
			if s > best_s:
				best_s = s
				best = x
		x += 0.5
	return best


func _add_fire(x: float, w: float, front: float, top: float, speed: float, life: float, patch: bool, src: String = "") -> Dictionary:
	_fire_seq += 1
	var f := {"id": _fire_seq, "x": x, "w": w, "front": front, "top": top, "stop": front, "speed": speed,
		"t": life if life > 0.0 else 1e9, "stall": 0.0, "patch": patch, "lava": life <= 0.0, "cool": 0.0, "src": src}
	fires.append(f)
	while fires.size() > MAX_FIRES:
		var dropped := false
		for o in fires:
			if bool(o["patch"]) and not bool(o["lava"]):
				fires.erase(o)
				dropped = true
				break
		if not dropped:
			break
	return f


## Foyer posé (passage de dragon, boule de feu, flaque d'un golem) ; life <= 0 : coulée de magma permanente.
func add_fire_patch(pos: Vector2, r: float, life: float, src: String = "") -> void:
	_add_fire(pos.x, r * 2.0, pos.y - r, pos.y + r, 0.0, life, true, src)


func fire_rect(f: Dictionary) -> Rect2:
	var w := float(f["w"])
	return Rect2(float(f["x"]) - w * 0.5, float(f["front"]), w, maxf(0.0, float(f["top"]) - float(f["front"])))


## Le feu avance et brûle : les invocations (l'escorte un peu), et les ennemis qui ne sont pas de Feu.
func _update_fires() -> void:
	var i := 0
	while i < fires.size():
		var f: Dictionary = fires[i]
		f["t"] = float(f["t"]) - TICK
		if float(f["t"]) <= 0.0:
			fires.remove_at(i)
			continue
		if float(f["cool"]) > 0.0:
			f["cool"] = float(f["cool"]) - TICK
			i += 1
			continue
		if float(f["stall"]) > 0.0:
			f["stall"] = float(f["stall"]) - TICK
		elif float(f["speed"]) > 0.0:
			f["front"] = maxf(float(f["stop"]), float(f["front"]) - float(f["speed"]) * TICK)
		var r := fire_rect(f)
		var dps := fire_dps * float(f.get("k", 1.0))
		for a in allies:
			if a.alive and a.shot == "" and r.grow(a.radius * 0.5).has_point(a.pos):
				fire_burned += minf(a.hp, dps * TICK)
				fire_by[str(f["src"])] = float(fire_by.get(str(f["src"]), 0.0)) + minf(a.hp, dps * TICK)
				_damage(a, dps * TICK * (0.4 if a.role == "escort" else 1.0), "feu")
		for e in enemies:
			if e.alive and e.element != "feu" and e.role not in ["boss", "rune", "tete", "banniere", "oeuf"] and r.has_point(e.pos):
				_damage(e, dps * 0.5 * TICK, "feu")
		i += 1


## Le Givre éteint le feu : un foyer disparaît, un couloir recule au-dessus de l'impact et marque une pause,
## une coulée de magma refroidit un moment. Retourne vrai si un foyer a été touché.
func extinguish(at: Vector2, r: float, rect: Rect2 = Rect2()) -> bool:
	if fires.is_empty():
		return false
	var area := rect if rect.size != Vector2.ZERO else Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0)
	var hit := false
	var i := 0
	while i < fires.size():
		var f: Dictionary = fires[i]
		var fr := fire_rect(f)
		if not fr.intersects(area):
			i += 1
			continue
		hit = true
		_event({"t": "steam", "pos": fr.get_center(), "r": minf(1.6, maxf(fr.size.x, fr.size.y) * 0.5)})
		if bool(f["lava"]):
			f["cool"] = LAVA_COOL
		elif bool(f["patch"]) or area.end.y >= float(f["top"]) - 0.3:
			fires.remove_at(i)
			fires_out += 1
			continue
		else:
			f["front"] = maxf(float(f["front"]), area.end.y)
			f["stall"] = FIRE_STALL
		i += 1
	if hit:
		_event({"t": "text", "pos": at + Vector2(0.0, 0.6), "text": "ÉTEINT !", "color": "BFE4FF"})
	return hit


## Point à éteindre en priorité : le front de l'incendie le plus bas, ou un foyer où passent les invocations.
func fire_target() -> Vector2:
	var best := Vector2(-1.0, -1.0)
	var best_s := 0.0
	for f in fires:
		if bool(f["lava"]):
			continue
		var fr := fire_rect(f)
		var s := 0.0
		if not bool(f["patch"]):
			s = 3.0 + (FIRE_TOP - float(f["front"])) * 0.4
		for a in allies:
			if a.alive and a.shot == "" and fr.grow(0.6).has_point(a.pos):
				s += 0.3
		if s > best_s:
			best_s = s
			best = Vector2(float(f["x"]), float(f["front"]) + 0.6) if not bool(f["patch"]) else fr.get_center()
	return best if best_s >= 2.0 else Vector2(-1.0, -1.0)


func wildfires_active() -> int:
	var n := 0
	for f in fires:
		if not bool(f["patch"]):
			n += 1
	return n


## Dragons : une ombre ailée annonce un passage sur une rangée ; il blesse les invocations et laisse des foyers.
func _update_dragons() -> void:
	if dragon_cfg.is_empty():
		return
	dragon_t -= TICK
	if dragon_t > 0.0:
		return
	var ev: Array = dragon_cfg.get("every", [18, 24])
	dragon_t = rng.randf_range(float(ev[0]), float(ev[1]))
	var none: Array[float] = []
	var y := _target_row(none)
	var hw := float(dragon_cfg.get("band", 1.4)) * 0.5
	var warn := float(dragon_cfg.get("warn", 1.7))
	telegraphs.append({"rect": Rect2(0.0, y - hw, W, hw * 2.0), "t": warn, "dur": warn, "dmg": float(dragon_cfg.get("dmg", 44.0)) * enemy_mult * diff,
		"barrier": 0.0, "dragon": true, "patches": int(dragon_cfg.get("patches", 2))})
	_event({"t": "text", "pos": Vector2(W * 0.5, y + 0.7), "text": "UN DRAGON !", "color": "FF9B4A"})
	_log("Une ombre ailée passe sur la forêt : un dragon !")


# ---------------------------------------------------------------- acte 6 : la Marque du Wyrm

## Compagnon passé au Wyrm (drapeaux « s1.trahison » et « s1.traitre_<id> ») : il apparaît en phase 3.
func _traitor_from_flags() -> String:
	if not flags_in.has("s1.trahison"):
		return ""
	for f in flags_in:
		var fs := str(f)
		if fs.begins_with("s1.traitre_") and fs not in ["s1.traitre_epargne", "s1.traitre_tue"]:
			var who := fs.trim_prefix("s1.traitre_")
			if not flags_in.has("s1.redemption_" + who):
				return who
	return ""


func _spawn_traitor() -> void:
	var who := _traitor_from_flags()
	if who == "" or traitor_unit != null:
		return
	traitor_id = who
	var p := boss.pos + Vector2(2.4 if boss.pos.x < W * 0.5 else -2.4, -1.8)
	traitor_unit = _spawn_enemy("ash_traitor", Vector2(clampf(p.x, 1.0, W - 1.0), p.y))
	traitor_unit.hold_y = traitor_unit.pos.y
	traitor_unit.sprite = who + "_cendre"
	var nm := str(Story.COMPANIONS.get(who, who))
	_log("%s se dresse aux côtés du Wyrm, la Marque en flammes ! À 0 PV, la Marque se brise ; un de tes sorts l'achèverait ensuite." % nm)
	_event({"t": "ring", "pos": traitor_unit.pos, "r": 2.0, "color": "FF6A2A", "dur": 0.8})
	_event({"t": "text", "pos": traitor_unit.pos + Vector2(0.0, 0.8), "text": nm.to_upper() + " !", "color": "FF9B4A"})


## Le compagnon marqué ne meurt pas sous les coups : à 0 PV il est brisé ; brisé, seul un sort l'achève.
## Retourne vrai si les dégâts s'appliquent normalement.
func _traitor_damage(tgt: Unit, amount: float) -> bool:
	var nm := str(Story.COMPANIONS.get(traitor_id, traitor_id))
	if traitor_broken:
		# Seul un sort lancé par le joueur l'achève (pas ceux des compagnons, ni les coups).
		if _sid == "" or _sid_owner != 0:
			return false
		traitor_killed = true
		tgt.hp = 0.0
		_log("%s ne se relèvera pas. La Marque s'éteint avec sa vie." % nm)
		_event({"t": "text", "pos": tgt.pos + Vector2(0.0, 0.8), "text": "ACHEVÉ", "color": "FF4A3A"})
		_kill(tgt)
		return false
	if tgt.hp - amount > 0.0:
		return true
	traitor_broken = true
	tgt.hp = 1.0
	tgt.cast_interval = 0.0
	tgt.atk = 0.0
	_log("%s est à terre, sans forces : la Marque est brisée. Épargne ton compagnon : un de tes sorts l'achèverait." % nm)
	_event({"t": "text", "pos": tgt.pos + Vector2(0.0, 0.8), "text": "À TERRE", "color": "FFD070"})
	_event({"t": "ring", "pos": tgt.pos, "r": 1.4, "color": "FFD070", "dur": 0.7})
	return false


# ---------------------------------------------------------------- zone 7 · Cité Engloutie

## Marée : basse, puis elle monte (annoncée), reste haute, redescend. Sous l'eau, les portails n'agissent plus.
func _update_tide() -> void:
	if tide_cfg.is_empty():
		return
	tide_t -= TICK
	var low_y := float(tide_cfg.get("low_y", 2.0))
	var high_y := float(tide_cfg.get("high_y", 6.0))
	var move := maxf(0.5, float(tide_cfg.get("move", 5.0)))
	match tide_state:
		"rising":
			tide_y = minf(high_y, tide_y + (high_y - low_y) / move * TICK)
		"falling":
			tide_y = maxf(low_y, tide_y - (high_y - low_y) / move * TICK)
	if tide_t <= 0.0:
		match tide_state:
			"low":
				tide_state = "rising"
				tide_t = move
				_event({"t": "text", "pos": Vector2(W * 0.5, high_y + 0.6), "text": "LA MARÉE MONTE !", "color": "8FE0FF"})
				_log("La marée monte : les portails du premier rang vont être noyés.")
			"rising":
				tide_state = "high"
				tide_t = float(tide_cfg.get("high", 12.0))
				tide_y = high_y
			"high":
				tide_state = "falling"
				tide_t = move
				_log("La marée redescend.")
			_:
				tide_state = "low"
				tide_t = float(tide_cfg.get("low", 20.0))
				tide_y = low_y
	for p in portals:
		var was := p.submerged
		p.submerged = p.y < tide_y - 0.2
		if p.submerged != was:
			p.flash_t = 0.3


## Dans l'eau : tes invocations ralentissent, les créatures aquatiques accélèrent.
func _water(u: Unit) -> float:
	if tide_cfg.is_empty() or u.pos.y >= tide_y or u.role in ["boss", "escort"]:
		return 1.0
	if u.team == 0:
		return WATER_SLOW
	return WATER_HASTE if bool((units_db.get(u.kind, {}) as Dictionary).get("aquatic", false)) else 1.0


## Courants latéraux : une rangée qui emporte les unités d'un côté, puis de l'autre.
func _update_currents() -> void:
	for c in currents:
		if float(c["flip"]) <= 0.0:
			continue
		c["t"] = float(c["t"]) - TICK
		if float(c["t"]) <= 0.0:
			c["t"] = float(c["flip"])
			c["dir"] = -float(c["dir"])
			_event({"t": "text", "pos": Vector2(W * 0.5, float(c["y"]) + 0.5), "text": "LE COURANT S'INVERSE", "color": "8FE0FF"})


func _current_push(u: Unit) -> float:
	if currents.is_empty() or u.hold_y > 0.0 or u.role in ["boss", "banniere", "rune", "tete"] or u.speed <= 0.0:
		return 0.0
	for c in currents:
		if absf(u.pos.y - float(c["y"])) <= float(c["h"]) * 0.5:
			return float(c["dir"]) * float(c["speed"]) / maxf(1.0, u.weight * 0.6)
	return 0.0


## Tourbillon : il aspire les invocations proches et blesse celles qui sont en son cœur (les ennemis l'ignorent).
func add_whirlpool(pos: Vector2, r: float, dur: float) -> void:
	whirlpools.append({"pos": pos, "r": r, "t": dur, "pull": 1.4})
	_event({"t": "ring", "pos": pos, "r": r, "color": "4FA8C8", "dur": 0.8})


func _update_whirlpools() -> void:
	var i := 0
	while i < whirlpools.size():
		var wp: Dictionary = whirlpools[i]
		wp["t"] = float(wp["t"]) - TICK
		if float(wp["t"]) <= 0.0:
			whirlpools.remove_at(i)
			continue
		var c: Vector2 = wp["pos"]
		var r := float(wp["r"])
		for a in allies:
			if not a.alive or a.role == "escort" or a.shot != "":
				continue
			var d := a.pos.distance_to(c)
			if d > r * 1.8:
				continue
			if d > 0.05:
				# Aspiration en spirale vers le centre.
				var to := (c - a.pos) / d
				var side := Vector2(-to.y, to.x)
				a.pos += (to * float(wp["pull"]) + side * 0.6) * TICK
			if d <= r * 0.6:
				_damage(a, whirl_dps * TICK, "")
		i += 1


func tide_label() -> String:
	match tide_state:
		"rising":
			return "La marée monte"
		"high":
			return "Marée haute : le premier rang est noyé (%d s)" % int(ceil(tide_t))
		"falling":
			return "La marée redescend"
	return ""
