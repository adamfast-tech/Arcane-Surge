extends SceneTree
## Test de fumée de l'interface, sur une sauvegarde de test (user://smoke_save.json) :
## prologue et intro → combat → Écho → victoire → dialogue de fin → rejouer → défaite → pause →
## écrans hors combat → choix de l'histoire et leurs effets → objectifs spéciaux.
##   godot --headless --path . --script res://tools/ui_smoke.gd

var main: Control


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _screen() -> Control:
	return main.get("_screen")


## Fait défiler les dialogues affichés (Passer, et 1re option à chaque choix) jusqu'au combat ou au menu.
func _through_dialogues(pick: int = 0) -> int:
	var n := 0
	while _screen() is DialogueScreen and n < 40:
		var d: DialogueScreen = _screen()
		if d.get("_waiting_choice"):
			var btns: Array = []
			for ch in d.choice_box.get_children():
				if ch is Button and not (ch as Button).disabled:
					btns.append(ch)
			(btns[mini(pick, btns.size() - 1)] as Button).pressed.emit()
		else:
			d._skip()
		n += 1
		await _frames(3)
	return n


## Classes jouables (étape 13.3) : invocation, Champion, Ultime et Clés de voûte, en simulation pure.
## Grimoires de classe (docs/design/29-grimoires-de-classe.md) : 60 techniques de l'Archer, 7 rangs,
## 8 disciplines ; recettes d'animation uniques et valides ; icônes ; achat réservé à la voie ; chaque
## technique se lance en combat ; Bibliothèque (onglet Classes, grimoire).
const RECIPE_LAYERS := ["rain", "drop", "rise", "ring", "orbit", "fling", "flutter", "sweep", "twinkle", "paws", "allies", "allyburst",
	"glyph", "glyph2", "hglyph", "rays", "cracks", "vring", "swirl", "bubbles", "tide", "accretion", "tentacles", "sound", "crescent",
	"slash", "arc", "crackle", "fireflies", "vines", "hexwall", "burst", "puffs", "dust", "flash", "orb", "fall", "pillar", "pillars",
	"shock", "zone", "mist", "embers", "snow", "spores", "net", "moon", "thick", "streak", "rings", "hop", "links", "each"]
const RANK_COUNTS := {"novice": 9, "intermediaire": 9, "apprenti": 9, "mage": 9, "maitre": 8, "archimage": 8, "interdit": 8}


const GRIMOIRES := ["archer", "epeiste", "clerc", "necromancien", "chevalier", "berserker"] ## classes dont le grimoire est écrit (60 techniques chacune)


func _grimoire_ok() -> bool:
	var recipes := {}
	var errs: Array[String] = []
	for cls in GRIMOIRES:
		if not _grimoire_class_ok(str(cls), recipes, errs):
			break
	if not errs.is_empty():
		push_error("grimoire de classe : %s" % [errs])
		return false
	return await _grimoire_buy_ok()


func _grimoire_class_ok(cls: String, recipes: Dictionary, errs: Array[String]) -> bool:
	var ids := Profile.class_grimoire(cls)
	var ranks := {}
	var discs := {}
	for id in ids:
		var sp: Dictionary = GameData.spells()[id]
		ranks[str(sp["rank"])] = int(ranks.get(str(sp["rank"]), 0)) + 1
		discs[str(sp["disc"])] = int(discs.get(str(sp["disc"]), 0)) + 1
		var v: Dictionary = sp.get("vfx", {})
		var key := JSON.stringify(v, "", true)
		if recipes.has(key):
			errs.append("%s : même animation que %s" % [id, recipes[key]])
		recipes[key] = id
		for part in v.keys():
			if part in ["shot", "c2"]:
				continue
			for layer in v[part]:
				var bits := str(layer).split(":")
				if bits[0] == "each":
					bits = bits.slice(1)
				var kind := bits[0]
				if not RECIPE_LAYERS.has(kind):
					errs.append("%s : couche inconnue %s" % [id, layer])
				var a1 := bits[1] if bits.size() > 1 else ""
				if kind in ["rain", "drop", "rise", "ring", "orbit", "fling", "flutter", "sweep", "allies", "streak", "hop"] and not FxArt.SPRITES.has(a1):
					errs.append("%s : sprite inconnu %s" % [id, layer])
		if v.has("shot") and not FxArt.SPRITES.has(str((v["shot"] as Dictionary).get("sp", "arrow"))):
			errs.append("%s : sprite de tir inconnu" % id)
		if not Icons.has(id) or Icons.tex(id, 48) == null:
			errs.append("%s : icône illisible" % id)
		if Profile.spell_price(id) < Profile.SPELL_PRICE_MIN:
			errs.append("%s : prix" % id)
	for r in RANK_COUNTS.keys():
		if int(ranks.get(r, 0)) != int(RANK_COUNTS[r]):
			errs.append("rang %s : %d techniques" % [r, int(ranks.get(r, 0))])
	if discs.size() != 8 or Profile.disciplines(cls).size() != 8:
		errs.append("%s, disciplines : %d" % [cls, discs.size()])
	for d in Profile.disciplines(cls):
		if int(discs.get(str((d as Dictionary)["id"]), 0)) > 8:
			errs.append("discipline %s : plus de 8 techniques (cases du Tiroir)" % str(d["id"]))
		if not GameData.spells().has(str(d["icon"])):
			errs.append("discipline %s : icône inconnue" % str(d["id"]))
	# Chaque technique se lance en combat.
	var refused: Array[String] = []
	var lv := GameData.level("z01_l05")
	for id in ids:
		var sim := BattleSim.new()
		sim.setup(lv, GameData.party(), 7, {"solo": true, "player_level": 30, "player_class": cls, "deck": [id]})
		sim.player().firing = true
		for k in range(120):
			sim.step()
		var c := sim.player()
		c.mana = c.mana_max
		c.spell_cd.clear()
		sim.barrier_hp = sim.barrier_max * 0.5
		var big := sim.strongest_enemy()
		var target: Vector2 = big.pos if big != null else Vector2(4.5, 7.0)
		if str((GameData.spells()[id] as Dictionary)["type"]) in ["harvest", "mirror"]:
			# Sacrifice, dédoublement : viser ses propres invocations.
			for a in sim.allies:
				if a.alive and a.owner_idx == 0 and a.role == "familier":
					target = a.pos
					break
		if not sim.cast_spell(c, id, target):
			refused.append(id)
		for k in range(90):
			sim.step()
		sim.terrain.sim = null
	if not refused.is_empty():
		errs.append("%s, refusés en combat : %s" % [cls, refused])
	print("grimoire %s : %d techniques · rangs %s · %d disciplines · %d animations uniques (tous grimoires)" % [cls, ids.size(), ranks, discs.size(), recipes.size()])
	return errs.is_empty()


## Achat réservé à la voie ; technique d'une autre voie gardée mais hors du deck ; Bibliothèque.
## Options (clé à molette) : difficulté appliquée au combat, écoles élémentaires réservées au Mage,
## techniques de départ, écran Options.
func _options_ok() -> bool:
	var errs: Array[String] = []
	var cls0 := Profile.player_class()
	var lv := GameData.level("z01_l03")
	Profile.set_difficulty("fou")
	var o := Profile.battle_opts()
	var s1 := BattleSim.new()
	s1.setup(lv, GameData.party(), 3, {"solo": true, "difficulty": 1.0})
	var s2 := BattleSim.new()
	s2.setup(lv, GameData.party(), 3, {"solo": true, "difficulty": float(o["difficulty"])})
	var e1 := s1._make_unit("goblin", 1, Vector2(4.0, 10.0)) if GameData.units().has("goblin") else s1._make_unit("mushroom", 1, Vector2(4.0, 10.0))
	var e2 := s2._make_unit(e1.kind, 1, Vector2(4.0, 10.0))
	var nx1 := float(s1.nexi[0]["max"]) if not s1.nexi.is_empty() else 1.0
	var nx2 := float(s2.nexi[0]["max"]) if not s2.nexi.is_empty() else 2.0
	if not is_equal_approx(float(o["difficulty"]), 2.0) or not is_equal_approx(e2.speed, e1.speed * 2.0) or not is_equal_approx(e2.atk, e1.atk * 2.0) or not is_equal_approx(nx2, nx1 * 2.0):
		errs.append("difficulté : mult %s, vitesse %.2f/%.2f, attaque %.1f/%.1f, Nexus %d/%d" % [o["difficulty"], e2.speed, e1.speed, e2.atk, e1.atk, int(nx2), int(nx1)])
	s1.terrain.sim = null
	s2.terrain.sim = null
	Profile.set_difficulty("normal")
	# Chaque voie son grimoire : l'Archer perd les écoles élémentaires mais garde ses techniques de départ.
	Profile.data["player"]["class"] = "archer"
	Profile.set_elem_for_all(false)
	var known := Profile.known_spells()
	var deck := Profile.deck()
	var elem_left := 0
	for id in deck:
		if Profile.is_elemental(id):
			elem_left += 1
	var block := Profile.learn_block("comete")
	var starters_ok := known.has("fleche_vive") and known.has("salve") and known.has("marque_chasseur") and known.has("purifier")
	Profile.set_elem_for_all(true)
	var back_ok := Profile.known_spells().has("boule_de_feu")
	Profile.data["player"]["class"] = cls0
	if known.has("boule_de_feu") or elem_left > 0 or deck.is_empty() or block != "Réservé au Mage (Options)" or not starters_ok or not back_ok:
		errs.append("grimoires séparés : connus %s · deck %s · %s" % [known, deck, block])
	var scr := OptionsScreen.new()
	root.add_child(scr)
	await _frames(2)
	scr.queue_free()
	# Ambiance enrichie : fond animé (shader, particules), panneaux en relief, titres dorés.
	Profile.set_ambience(true)
	var lib := LibraryScreen.new()
	root.add_child(lib)
	await _frames(3)
	var amb_found := false
	for ch in lib.get_children():
		if ch is Ambience:
			amb_found = true
	lib.queue_free()
	Profile.set_ambience(false)
	if not amb_found or RuneBox.rich:
		errs.append("ambiance : couche %s, relief resté %s" % [amb_found, RuneBox.rich])
	print("options : difficulté ×%s (vitesse %.2f → %.2f, Nexus %d → %d) · Archer sans écoles : %d sorts, deck %d · %s" % [o["difficulty"], e1.speed, e2.speed, int(nx1), int(nx2), known.size(), deck.size(), block])
	if not errs.is_empty():
		push_error("options : %s" % [errs])
		return false
	return true


func _grimoire_buy_ok() -> bool:
	var errs: Array[String] = []
	var cls0 := Profile.player_class()
	var gold0 := Profile.gold()
	Profile.data["player"]["class"] = "mage"
	var block_mage := Profile.learn_block("collet")
	Profile.data["player"]["class"] = "archer"
	Profile.data["gold"] = 100000
	var learned_ok := Profile.learn("collet") and Profile.known_spells().has("collet")
	Profile.data["player"]["class"] = "mage"
	var hidden := not Profile.known_spells().has("collet") and Profile.learned("collet")
	Profile.data["player"]["class"] = "archer"
	var lib := LibraryScreen.new()
	root.add_child(lib)
	lib.set("_school", "classes")
	lib.set("_class_view", "archer")
	lib.call("_rebuild")
	await _frames(2)
	var lib_elem := 0
	for cid in LibraryScreen.catalogue():
		if (GameData.spells()[cid] as Dictionary).has("grimoire"):
			lib_elem += 1
	lib.queue_free()
	(Profile._spells_state()["known"] as Array).erase("collet")
	Profile.data["player"]["class"] = cls0
	Profile.data["gold"] = gold0
	if not block_mage.begins_with("Voie") or not learned_ok or not hidden or lib_elem != 0:
		errs.append("achat : %s · appris %s · caché hors voie %s · techniques dans le catalogue élémentaire %d" % [block_mage, learned_ok, hidden, lib_elem])
	print("grimoires : achat hors voie « %s »" % block_mage)
	if not errs.is_empty():
		push_error("grimoire de classe : %s" % [errs])
		return false
	return true


func _classes_ok() -> bool:
	var classes: Dictionary = GameData.party()["classes"]
	var lv := GameData.level("z01_l05")
	var out: Array[String] = []
	for cls in ["archer", "epeiste", "clerc", "necromancien", "chevalier", "berserker"]:
		var cd: Dictionary = classes[cls]
		var s := BattleSim.new()
		s.setup(lv, GameData.party(), 7, {"player_class": cls, "solo": true})
		var pc := s.player()
		var fam := s._spawn_familiar(pc, Vector2(4.5, 3.0))
		s._flush()
		s._build_grids()
		for k in range(12):
			var e := s._spawn_enemy("mushroom", Vector2(3.5 + float(k % 4) * 0.6, 8.0 + float(k / 4) * 0.5))
			e.hp = 9999.0
			e.max_hp = 9999.0
		s._flush()
		s._build_grids()
		var n0 := s.allies.size()
		var sh0 := s.barrier_shield
		s.surge = 100.0
		var ult := s.cast_ultimate(Vector2(4.5, 8.5))
		for k in range(40):
			s.step()
		var effect := true
		match cls:
			"necromancien":
				effect = s.allies.size() >= n0 + 15
			"berserker":
				effect = fam.frenzy_t > 0.0
			"chevalier":
				effect = s.barrier_shield > sh0
		var want_fam := str(cd.get("player_familiar", cd["familiar"]))
		var ok: bool = pc.class_id == cls and fam.kind == want_fam and s.champion_kind == str(cd["champion"]) and s.ultimate_id == str(cd["ultimate"]) and ult and effect
		out.append("%s %s/%s/%s %s" % [cls, fam.kind, s.champion_kind, s.ultimate_id, "ok" if ok else "ÉCHEC"])
		s.terrain.sim = null
		if not ok:
			print("  classes : ", out)
			push_error("classe %s incorrecte" % cls)
			return false
	# Clés de voûte : Miracle, Inébranlable, Légion, Avant-garde, Danse parfaite.
	var k2 := BattleSim.new()
	k2.setup(lv, GameData.party(), 9, {"player_class": "clerc", "solo": true, "mods": {"miracle": 1.0, "barrier_cap": 5.0, "legion": 1.0, "vanguard": 1.0}})
	var b0 := k2.barrier_hp
	k2._hurt_barrier(40.0)
	var capped := b0 - k2.barrier_hp
	k2.barrier_hp = 0.0
	k2._check_end()
	var miracle := k2.state == "running" and k2.barrier_hp >= k2.barrier_max * 0.49
	k2.surge = 0.0
	var arm := {"type": "army", "count": 20, "kind": "skeleton", "radius": 1.5, "damage": 0}
	k2._apply_spell(k2.player(), arm, Vector2(4.5, 6.0))
	var colossus := false
	for u in k2._pending_allies:
		if u.kind == "champion_bone":
			colossus = true
	k2._flush()
	k2.champion_charge = k2.champion_need
	var y0 := BattleSim.CASTER_Y + 0.7
	k2.summon_champion()
	var charged := false
	for u in k2._pending_allies:
		if u.role == "champion" and u.pos.y > y0 + 2.0:
			charged = true
	k2.terrain.sim = null
	print("  classes : ", out, " · Clés : Inébranlable -", int(capped), " · Miracle ", miracle, " · Légion ", colossus, " · Avant-garde ", charged)
	if capped > 5.01 or not miracle or not colossus or not charged:
		push_error("Clés de voûte de classe incorrectes")
		return false
	# Arbres (étape 13.10) : 64 compétences par classe, 7 paliers, liens valides, effets connus, prérequis.
	var tree_errs: Array[String] = []
	var known_mods := ["unit_atk", "unit_hp", "unit_def", "unit_range", "unit_speed", "unit_regen", "lifesteal", "crit", "cadence", "spell_cost", "cd_red",
		"mana_regen", "barrier_max", "barrier_dr", "barrier_regen", "start_shield", "surge_gain", "kill_mana", "champ_atk", "champ_hp", "ult_dmg", "ult_radius",
		"spell_dmg", "burn_dmg", "burn_dur", "poison_dmg", "frozen_dur", "frozen_vuln", "zone_slow", "dodge", "portal_plus", "free_clone", "heal_bonus",
		"aura_heal", "spawn_shield", "riposte", "mark_vuln", "bot_atk", "skeleton_bonus", "skeleton_chance", "anti_heal", "low_barrier_atk", "venom",
		"hunt_mark", "ghost_double", "frenzy_dur", "chain_bonus", "army_count", "portal_split"]
	var n_total := 0
	var sim_src := FileAccess.get_file_as_string("res://scripts/battle/sim.gd")
	for cls in ["mage", "archer", "epeiste", "clerc", "necromancien", "chevalier", "berserker"]:
		var td: Dictionary = GameData.load_json("res://data/skill_trees/%s.json" % cls)
		var ids := {}
		var n_cls := 0
		for br in td["branches"]:
			if (br["tiers"] as Array).size() != 7:
				tree_errs.append("%s/%s : %d paliers" % [cls, br["id"], (br["tiers"] as Array).size()])
			for t in br["tiers"]:
				for nd in t["nodes"]:
					ids[str(nd["id"])] = true
		for br in td["branches"]:
			var first := true
			for t in br["tiers"]:
				for nd in t["nodes"]:
					n_cls += 1
					if not nd.has("x") or str(nd.get("desc", "")) == "":
						tree_errs.append("%s/%s : x ou description" % [cls, nd["id"]])
					if not first and (nd.get("parents", []) as Array).is_empty():
						tree_errs.append("%s/%s : sans parent" % [cls, nd["id"]])
					for pid in nd.get("parents", []):
						if not ids.has(str(pid)):
							tree_errs.append("%s/%s : parent inconnu %s" % [cls, nd["id"], pid])
					if str(nd.get("kind", "passive")) == "passive":
						for mk in (nd.get("mods", {}) as Dictionary).keys():
							var mks := str(mk)
							if not (known_mods.has(mks) or sim_src.contains('_mod("%s")' % mks) or mks.begins_with("elem_dmg.") or mks.begins_with("unit_elem.") or mks.begins_with("resist.") or mks.begins_with("radius.") or mks.begins_with("dur.")):
								tree_errs.append("%s/%s : effet inconnu %s" % [cls, nd["id"], mks])
				first = false
		n_total += n_cls
		if n_cls < 64:
			tree_errs.append("%s : %d compétences" % [cls, n_cls])
	print("  arbres : %d compétences au total" % n_total)
	if not tree_errs.is_empty():
		push_error("arbres : %s" % [tree_errs])
		return false
	# Voies du Surge (13.3b) : 3e branche par classe, verrouillée sans la Vérité des Cendres.
	var surge_ok := true
	for cls in ["archer", "epeiste", "clerc", "necromancien", "chevalier", "berserker"]:
		var tree: Dictionary = GameData.load_json("res://data/skill_trees/%s.json" % cls)
		var brs: Array = tree["branches"]
		var last: Dictionary = brs[brs.size() - 1]
		var keys: Array = []
		for kn in ((last["tiers"] as Array).back() as Dictionary)["nodes"]:
			if (kn as Dictionary).has("flag"):
				keys.append(kn)
		if brs.size() != 3 or str(last.get("unlock_flag", "")) != "s1.verite_cendres" or keys.size() != 2 \
				or str(keys[0].get("flag", "")) != "s1.voie_aube" or str(keys[1].get("flag", "")) != "s1.voie_cendres":
			surge_ok = false
	var k3 := BattleSim.new()
	k3.setup(lv, GameData.party(), 11, {"player_class": "necromancien", "solo": true,
		"mods": {"harvest_barrier": 1.0, "purify_double": 1.0, "blood_rage": 1.0}})
	var pl := k3.player()
	for k in range(12):
		var a := k3._spawn_familiar(pl, Vector2(3.8 + float(k % 4) * 0.4, 5.0 + float(k / 4) * 0.3))
		a.vx = 0.0
	k3._flush()
	k3._build_grids()
	var before := k3.allies.size()
	var mir := k3._apply_spell(pl, {"type": "mirror", "radius": 2.0, "count": 5, "color": "B8C8FF"}, Vector2(4.4, 5.3))
	k3._flush()
	k3._build_grids()
	var mirrored := k3.allies.size() - before
	k3.barrier_hp = k3.barrier_max - 40.0
	var bh0 := k3.barrier_hp
	var harv := k3._apply_spell(pl, {"type": "harvest", "radius": 2.5, "count": 20, "damage": 25, "element": "ombre", "color": "8E62E0"}, Vector2(4.4, 5.3))
	var gained := k3.barrier_hp - bh0
	var neg: Portal = null
	for pt in k3.portals:
		if not pt.is_seal:
			neg = pt
			break
	var doubled := true
	if neg != null:
		neg.kind = "sub"
		neg.value = 3
		k3._purify(neg)
		doubled = neg.kind == "mult" and neg.value == 2
	k3.frenzy_until = k3.time + 5.0
	var bb := k3.barrier_hp
	for k in range(30):
		k3.step()
	var drained := k3.barrier_hp < bb
	k3.terrain.sim = null
	print("  Voies du Surge : arbres ", surge_ok, " · Lames miroirs +", mirrored, " · Sacrifice ", k3.sacrificed, " (Barrière +", snappedf(gained, 0.1), ") · portail purifié ×2 ", doubled, " · Rage de sang ", drained)
	if not surge_ok or not mir or mirrored != 5 or not harv or k3.sacrificed < 12 or gained < 5.9 or not doubled or not drained:
		push_error("Voies du Surge des classes incorrectes")
		return false
	return true


## Salle de méditation et compagnons (étape 13.4), sur une copie de la progression restaurée ensuite.
func _meditation_ok() -> bool:
	var keep: Dictionary = Profile.data.duplicate(true)
	var locked_before := not Profile.meditation_unlocked()
	var refused := not Profile.change_class("chevalier")
	Profile.data["levels"]["z01_l10"] = {"stars": 1, "best": 200.0, "clears": 1}
	Profile.data["player"]["level"] = maxi(30, Profile.level())
	Profile.data["gold"] = 5000
	var opened := Profile.meditation_unlocked()
	# Voies : chaque classe garde son arbre ; configurations enregistrées puis rechargées.
	Profile.skill_ranks().clear()
	var inv_m := Profile.invest("combustion")
	var to_chev := Profile.change_class("chevalier")
	var chev_empty := Profile.skill_points_spent() == 0
	var inv_c := Profile.invest("armure_lourde")
	Profile.save_config(0)
	Profile.change_class("mage")
	var mage_kept := Profile.skill_rank("combustion") == 1
	Profile.change_class("chevalier")
	Profile.reset_skills()
	var err := Profile.load_config(0)
	var cfg_ok := err == "" and Profile.player_class() == "chevalier" and Profile.skill_rank("armure_lourde") == 1
	Profile.change_class("mage")
	# Harmonie : −5 Corruption pour 100 or.
	Story.add_value("corruption", 20 - Story.value("corruption"))
	var g0 := Profile.gold()
	var removed := Profile.harmony()
	var harm_ok := removed == 5 and Story.value("corruption") == 15 and g0 - Profile.gold() == 100
	print("méditation : fermée avant l'acte 2 ", locked_before and refused, " · ouverte ", opened, " · Mage ", inv_m, " -> Chevalier ", to_chev, " (arbre vierge ", chev_empty, ", ", inv_c,
		") · arbre du Mage gardé ", mage_kept, " · configuration ", cfg_ok, " · Harmonie −", removed)
	if not (locked_before and refused and opened and inv_m and to_chev and chev_empty and inv_c and mage_kept and cfg_ok and harm_ok):
		push_error("Salle de méditation incorrecte")
		return false
	# Compagnons : XP 80 % en combat, 30 % à Havre-Aube ; équipement ; changement de voie.
	var r := Profile.apply_battle("z01_l03", true, 3, 60.0, ["brann"])
	var cr: Dictionary = r.get("companions", {})
	var xp_ok: bool = cr.has("brann") and cr.has("sylwen") and bool(cr["brann"]["active"]) and not bool(cr["sylwen"]["active"]) \
		and int(cr["brann"]["xp"]) > int(cr["sylwen"]["xp"]) * 2
	var it := Profile.make_item("baton_chene", "rare", 10, RandomNumberGenerator.new())
	(Profile.data["inventory"] as Array).append(it)
	var uid := str(it["uid"])
	var pg := Profile.gear_stats().duplicate()
	Profile.equip_to("brann", uid)
	var on_brann := Profile.holder_of(uid) == "brann" and not Profile.gear_stats_of("brann").is_empty() and Profile.gear_stats() == pg
	Profile.equip_to("player", uid)
	var moved := Profile.holder_of(uid) == "player" and Profile.equipment_of("brann").is_empty()
	Profile.equip_to("brann", uid)
	var cls_ok := Profile.set_companion_class("brann", "clerc") and Profile.companion_spells("brann")[0] == "priere" \
		and str((Profile.circle()["brann"] as Dictionary).get("spell", "")) == "priere"
	var sim := BattleSim.new()
	sim.setup(GameData.level("z01_l05"), GameData.party(), 5, Profile.battle_opts())
	var bot: BattleSim.Caster = null
	for c in sim.casters:
		if c.id == "brann":
			bot = c
	var sim_ok := bot != null and bot.class_id == "clerc" and bot.familiar == "familiar_acolyte" and bot.level == Profile.companion_level("brann") \
		and bot.spells.has("priere") and float(bot.stats["pou"]) > 0.0
	sim.terrain.sim = null
	print("compagnons : XP Brann ", cr.get("brann", {}).get("xp", 0), " (combat) / Sylwen ", cr.get("sylwen", {}).get("xp", 0), " (Havre-Aube) · équipement ", on_brann, "/", moved,
		" · Brann en Clerc ", cls_ok, " · en combat ", sim_ok, " (niv. ", bot.level if bot != null else -1, ", ", bot.familiar if bot != null else "", ")")
	if not (xp_ok and on_brann and moved and cls_ok and sim_ok):
		push_error("progression des compagnons incorrecte")
		return false
	# Écrans : Méditation, équipement d'un compagnon, Cercle.
	main.call("_show_room", "meditation")
	await _frames(3)
	var med_ok := _screen() is MeditationScreen
	main.call("_show_equipment", "brann", true)
	await _frames(3)
	var eq_ok := _screen() is EquipmentScreen and (_screen() as EquipmentScreen).who == "brann"
	main.call("_show_room", "circle")
	await _frames(3)
	var circ_ok := _screen() is CircleScreen
	print("écrans : Méditation ", med_ok, " · équipement de Brann ", eq_ok, " · Cercle ", circ_ok)
	Profile.data = keep
	main.call("_show_hub")
	await _frames(3)
	if not (med_ok and eq_ok and circ_ok):
		push_error("écrans de la Salle de méditation ou des compagnons incorrects")
		return false
	return true


## Zone 4 (étape 14.1) : glace, Porte Forge, avalanche, runes du Colosse, portes corrompues, dégel.
func _zone4_ok() -> bool:
	var s := BattleSim.new()
	s.setup(GameData.level("z04_l01"), GameData.party(), 3, {"solo": true})
	var ice := 0
	for sf in s.terrain.surfaces:
		if str(sf["kind"]) == "glace":
			ice += 1
	var spot: Vector2 = s.terrain.surfaces[0]["pos"]
	var u := s._spawn_familiar(s.player(), spot - Vector2(0.0, 0.2))
	s._flush()
	s._build_grids()
	var y0 := u.pos.y
	s.terrain.update()
	s._move_units()
	var slid := u.slide_t > 0.0 and u.pos.y - y0 > u.speed * BattleSim.TICK * 1.2
	# Porte Forge.
	var forge := Portal.new()
	forge.kind = "forge"
	var d0 := u.defense
	s._apply_portal(forge, u)
	var forged := u.defense >= d0 + 9.9 and forge.label() == "FORGE"
	# Dégel : le Feu fait fondre la glace, qui regèle 12 s plus tard.
	s.terrain.on_impact(s.player(), {"element": "feu", "type": "aoe"}, spot, 0.8, 50.0)
	var melted := str(s.terrain.surfaces[0]["kind"]) == "eau"
	for k in range(int(12.5 / BattleSim.TICK)):
		s.terrain.update()
	var refrozen := str(s.terrain.surfaces[0]["kind"]) == "glace"
	# Avalanche : la rangée annoncée frappe aussi les ennemis et les ensevelit.
	var foe := s._spawn_enemy("yeti", Vector2(4.5, 8.0))
	s._flush()
	s.telegraphs.clear()
	s._avalanche(1.6, 40.0, 0.1)
	var tg: Dictionary = s.telegraphs[0]
	tg["rect"] = Rect2(0.0, 7.2, BattleSim.W, 1.6)
	var hp0 := foe.hp
	for k in range(6):
		s._update_telegraphs()
	var buried := foe.hp < hp0 and foe.rooted_t > 0.0
	s.terrain.sim = null
	# Colosse runique : runes, immunités, protection du corps, rotation, portes corrompues.
	var b := BattleSim.new()
	b.setup(GameData.level("z04_l10"), GameData.party(), 4, {"solo": true})
	b._flush()
	b._build_grids()
	var n_runes := b.runes_alive()
	var ru: Unit = b.runes[0]
	var rh := ru.hp
	b._damage(ru, 100.0, "foudre" if ru.element != "foudre" else "givre")
	var immune := ru.hp == rh
	b._damage(ru, 100.0, ru.element)
	var hurt := ru.hp < rh
	var bh := b.boss.hp
	b._damage(b.boss, 100.0, "physique")
	var shielded := absf((bh - b.boss.hp) - 30.0) < 0.01
	var e0 := ru.element
	b._boss_ability({"type": "rotate_runes"})
	var rotated := ru.element != e0
	var pos_before := 0
	for pt in b.portals:
		if not pt.is_negative():
			pos_before += 1
	b._boss_ability({"type": "corrupt_gates", "count": 1, "dur": 0.2})
	var pos_cursed := 0
	for pt in b.portals:
		if not pt.is_negative():
			pos_cursed += 1
	for k in range(10):
		b._update_gate_curses()
	var pos_after := 0
	for pt in b.portals:
		if not pt.is_negative():
			pos_after += 1
	b.terrain.sim = null
	var gates := pos_cursed == pos_before - 1 and pos_after == pos_before
	print("zone 4 : glace ", ice, " plaques, glisse ", slid, " · Forge ", forged, " · dégel ", melted, "/", refrozen, " · avalanche ", buried,
		" · Colosse : ", n_runes, " runes, immunité ", immune, ", bon élément ", hurt, ", corps protégé ", shielded, ", rotation ", rotated, ", portes ", gates)
	if not (ice >= 2 and slid and forged and melted and refrozen and buried and n_runes == 2 and immune and hurt and shielded and rotated and gates):
		push_error("mécaniques de la zone 4 incorrectes")
		return false
	return true


## Zone 5 (étape 15.1) : cycle soleil/lune, mirages, miroirs (renvoi des tirs, rayon de jour),
## énigmes du Sphinx (bonne et mauvaise réponse, Couronne de l'Énigme), sprites.
func _zone5_ok() -> bool:
	var errs: Array[String] = []
	for k in ["glass_scarab", "sand_jackal", "sandstone_golem", "mummy_archer", "mirror_construct", "college_specter", "solar_priestess",
			"crystal_scorpion", "glass_mirror", "sun_scarab", "glass_sphinx", "desert_caravan"]:
		if SpriteAtlas.single(k) == null:
			errs.append("sprite %s" % k)
	# Jour : Feu +25 % ; nuit : Givre +25 %.
	var s := BattleSim.new()
	s.setup(GameData.level("z05_l01"), GameData.party(), 3, {"solo": true})
	var foe := s._spawn_enemy("sandstone_golem", Vector2(4.5, 9.0))
	s._flush()
	var h0 := foe.hp
	s._damage(foe, 100.0, "feu")
	var day_fire := h0 - foe.hp
	s._switch_daynight()
	h0 = foe.hp
	s._damage(foe, 100.0, "feu")
	var night_fire := h0 - foe.hp
	h0 = foe.hp
	s._damage(foe, 100.0, "givre")
	var night_frost := h0 - foe.hp
	if not (s.is_day == false and is_equal_approx(day_fire, 125.0) and is_equal_approx(night_fire, 100.0) and is_equal_approx(night_frost, 125.0)):
		errs.append("jour/nuit %s/%s/%s" % [day_fire, night_fire, night_frost])
	s.terrain.sim = null
	# Mirage : sans effet ; révélé à l'approche, il se dissipe puis se reforme ailleurs.
	var m := BattleSim.new()
	m.setup(GameData.level("z05_l02"), GameData.party(), 5, {"solo": true})
	var mp: Portal = null
	for pt in m.portals:
		if pt.mirage:
			mp = pt
	var u := m._spawn_familiar(m.player(), Vector2(mp.x, mp.y - 0.4))
	m._flush()
	var n0 := m.allies.size() + m._pending_allies.size()
	m._apply_portal(mp, u)
	var no_effect := m.allies.size() + m._pending_allies.size() == n0 and mp.revealed_t > 0.0 and mp.label() == "MIRAGE"
	var x0 := mp.x
	for k in range(int((1.3 + m.mirage_reform + 0.2) / BattleSim.TICK)):
		m._update_portals()
	var reformed := mp.active() and mp.label() != "MIRAGE"
	m.terrain.sim = null
	if not no_effect or not reformed:
		errs.append("mirage effet %s, reformé %s (x %.1f -> %.1f)" % [no_effect, reformed, x0, mp.x])
	# Miroirs : renvoi des tirs ; rayon de soleil le jour seulement.
	var r := BattleSim.new()
	r.setup(GameData.level("z05_l04"), GameData.party(), 6, {"solo": true})
	r._flush()
	var mirror: Unit = null
	for e in r.enemies:
		if e.kind == "glass_mirror":
			mirror = e
	var shooter := r._make_unit("skeleton_archer", 0, mirror.pos - Vector2(0.0, 2.0))
	r._add_ally(shooter)
	r._flush()
	var sh0 := shooter.hp
	shooter.hp = 500.0
	shooter.max_hp = 500.0
	r._hit(shooter, mirror)
	var reflected := shooter.hp < 500.0
	r._build_grids()
	mirror.cast_cd = 0.0
	r.telegraphs.clear()
	r._enemy_abilities()
	var beam_day := r.telegraphs.size() == 1 and bool(r.telegraphs[0].get("sun", false))
	r._switch_daynight()
	mirror.cast_cd = 0.0
	r.telegraphs.clear()
	r._enemy_abilities()
	var beam_night := r.telegraphs.size()
	r.terrain.sim = null
	if not reflected or not beam_day or beam_night != 0:
		errs.append("miroir renvoi %s, rayon jour %s, nuit %d (PV tireur %s)" % [reflected, beam_day, beam_night, sh0])
	# Énigmes du Sphinx.
	var b := BattleSim.new()
	b.setup(GameData.level("z05_l10"), GameData.party(), 8, {"solo": true})
	b._flush()
	var verdicts: Array[String] = []
	for want in [true, false, true]:
		b._boss_ability({"type": "riddle", "need": 3, "time": 40, "y": 7.8, "xs": [1.7, 4.5, 7.3]})
		var answers := 0
		var pick: Portal = null
		for pt in b.portals:
			if pt.kind == "answer":
				answers += 1
				if (pt.id == int(b.riddle["right"])) == want:
					pick = pt
		var bh := b.boss.hp
		b._damage(b.boss, 100.0, "physique")
		var guarded := bh - b.boss.hp < 20.0
		var helper := b._spawn_familiar(b.player(), Vector2(pick.x, 7.0))
		helper.owner_idx = 1
		b._apply_portal(pick, helper)
		var ignored := not b.riddle.is_empty() and pick.counter == 0
		for k in range(3):
			b._apply_portal(pick, b._spawn_familiar(b.player(), Vector2(pick.x, 7.0)))
		var gone := 0
		for pt in b.portals:
			if pt.kind == "answer":
				gone += 1
		verdicts.append("%d réponses, gardé %s, compagnon ignoré %s, résolue %s" % [answers, guarded, ignored, b.riddle.is_empty() and gone == 0])
		if answers != 3 or not guarded or not ignored or not b.riddle.is_empty() or gone != 0:
			errs.append("énigme : %s" % verdicts.back())
	var exposed := b.boss_exposed_t > 0.0
	var enraged := b.boss.enraged_t > 0.0
	if b.riddles_right != 2 or b.riddles_wrong != 1 or not exposed or not enraged or b.bonus_unique != "couronne_enigme":
		errs.append("énigmes : justes %d, fausses %d, exposé %s, enragé %s, unique « %s »" % [b.riddles_right, b.riddles_wrong, exposed, enraged, b.bonus_unique])
	b.terrain.sim = null
	# Couronne de l'Énigme : donnée une seule fois.
	var inv0: Array = (Profile.data["inventory"] as Array).duplicate(true)
	var r1 := Profile.apply_battle("z05_l10", true, 3, 300.0, [], "couronne_enigme")
	var r2 := Profile.apply_battle("z05_l10", true, 3, 300.0, [], "couronne_enigme")
	var crowns := 0
	for it in Profile.data["inventory"]:
		if str(it["base"]) == "couronne_enigme":
			crowns += 1
	Profile.data["inventory"] = inv0
	if crowns != 1:
		errs.append("Couronne de l'Énigme ×%d" % crowns)
	print("zone 5 : jour/nuit Feu %d → %d, Givre de nuit %d · mirage sans effet %s, reformé %s · miroir : renvoi %s, rayon de jour %s, la nuit %d · énigmes %s · Couronne ×%d (%d objets, puis %d)" % [
		day_fire, night_fire, night_frost, no_effect, reformed, reflected, beam_day, beam_night, verdicts, crowns, (r1["items"] as Array).size(), (r2["items"] as Array).size()])
	if not errs.is_empty():
		push_error("zone 5 : %s" % [errs])
		return false
	return true


func _run() -> void:
	Profile.save_path = "user://smoke_save.json"
	if FileAccess.file_exists(Profile.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Profile.save_path))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	# Attendre la fin de l'écran de chargement (au moins 1,2 s).
	var guard := 0
	while not (_screen() is HubScreen or _screen() is LoginScreen) and guard < 5000:
		await _frames(1)
		guard += 1
	print("démarrage : ", _screen().get_script().get_global_name())
	# Création du personnage : race, apparence ; Revenant verrouillé ; classes non jouables refusées.
	main.call("_show_hub")
	await _frames(3)
	var cr: CreationScreen = _screen()
	var rev := Profile.set_race("revenant")
	var nain := Profile.set_race("nain")
	var arch := Profile.set_class("archer")
	var archer_tree := (Profile.tree_db().get("branches", []) as Array).size()
	Profile.set_class("mage")
	Profile.set_look("head", "tresse")
	Profile.set_look("hair", "roux")
	Profile.set_look("outfit", "ocre")
	cr._rebuild()
	await _frames(2)
	var cr_name: String = cr.get_script().get_global_name()
	cr.done.emit()
	await _frames(3)
	# Héritage : points (niveau et actes terminés), un rang dans « Peau de pierre ».
	Profile.data["player"]["level"] = maxi(10, int(Profile.data["player"]["level"]))
	var ht := Profile.heritage_total()
	var inv_ok := Profile.race_invest("n_pierre")
	print("héritage : ", ht, " point(s) · Peau de pierre ", inv_ok, " (rang ", Profile.race_rank("n_pierre"), ") · Don ", Profile.don_info().get("name", ""), " ", int(Profile.don_info().get("cd", 0)), " s · DÉF bonus ", Profile.race_mods().get("unit_def", 0.0))
	if ht < 1 or not inv_ok or absf(float(Profile.race_mods().get("unit_def", 0.0)) - 0.2) > 0.001:
		push_error("héritage racial incorrect")
		quit(1)
		return
	var bo := Profile.battle_opts()
	print("création : écran ", cr_name, " · Revenant ", rev, " · Nain ", nain, " · Archer ", arch, " (arbre ", archer_tree, " branches) · créé ", Profile.created(),
		" · ", Profile.race(), " ", Profile.look()["head"], " · écran ", _screen().get_script().get_global_name(), " · sprite combat ", bo.has("look"))
	if rev or not nain or not arch or archer_tree < 2 or Profile.player_class() != "mage" or not Profile.created() or not (_screen() is HubScreen):
		push_error("création du personnage incorrecte")
		quit(1)
		return
	if not _class_fire_ok():
		quit(1)
		return
	if not _drawer_groups_ok():
		quit(1)
		return
	if not _classes_ok():
		quit(1)
		return
	if not await _meditation_ok():
		quit(1)
		return
	if not _zone4_ok():
		quit(1)
		return
	if not _zone5_ok():
		quit(1)
		return
	if not _zone6_ok():
		quit(1)
		return
	if not _zone7_ok():
		quit(1)
		return
	if not await _gear_ok():
		quit(1)
		return
	if not await _rooms_art_ok():
		quit(1)
		return
	if not await _autofire_ok():
		quit(1)
		return
	if not await _compare_ok():
		quit(1)
		return
	if not await _map_ok():
		quit(1)
		return
	if not _hero_model_ok():
		quit(1)
		return
	if not await _armory_ok():
		quit(1)
		return
	if not await _hero_rig_ok():
		quit(1)
		return
	if not await _troupe_ok():
		quit(1)
		return
	if not await _forge_scene_ok():
		quit(1)
		return
	if not await _quests_tower_ok():
		quit(1)
		return
	if not _babble_ok():
		quit(1)
		return
	# Bibliothèque, onglet Classes : Ultime, sorts d'arbre et sorts de compagnon de chaque classe.
	var cs := LibraryScreen.class_spells("chevalier")
	var tree_ids: Array[String] = []
	for tsp in cs["tree"]:
		tree_ids.append(str(tsp["id"]))
	var lib := LibraryScreen.new()
	root.add_child(lib)
	lib.set("_school", "classes")
	lib.set("_class_view", "chevalier")
	lib.call("_rebuild")
	await _frames(2)
	var lib_ok: bool = str(cs["ultimate"]) == "rempart_sacre" and tree_ids.has("bouclier_leve") and tree_ids.has("charge_bastion") and tree_ids.has("cercle_runique") \
		and (cs["companion"] as Array).has("bouclier_leve")
	print("bibliothèque, classes : Chevalier ", cs["ultimate"], " · arbre ", tree_ids, " · compagnon ", cs["companion"])
	lib.queue_free()
	if not lib_ok:
		push_error("onglet Classes de la Bibliothèque incorrect")
		quit(1)
		return
	if not await _grimoire_ok():
		quit(1)
		return
	if not await _options_ok():
		quit(1)
		return
	# Animations : chaque sort a sa signature déclarée dans SpellSig (scripts/battle/spell_sig.gd),
	# ou sa recette (« vfx », grimoires de classe : scripts/battle/spell_recipe.gd).
	var sig := SpellSig.new(null)
	var sans: Array[String] = []
	for sid in GameData.spells().keys():
		if not sig.has_method("s_" + str(sid)) and not (GameData.spells()[sid] as Dictionary).has("vfx"):
			sans.append(str(sid))
	print("animations : ", GameData.spells().size() - sans.size(), "/", GameData.spells().size(), " sorts avec signature", (" · sans : %s" % [sans]) if not sans.is_empty() else "")
	if not sans.is_empty():
		push_error("sorts sans animation propre")
		quit(1)
		return
	# Dialogues : prologue + intro de 1-1, lus jusqu'au bout (tap), avec l'historique.
	main.call("_play", "z01_l01", false)
	await _frames(5)
	# Écran de préparation : choix Deck / Tiroir, puis « Combattre ».
	var prep: PrepScreen = _screen()
	print("préparation : ", prep.level_id, " · mode ", Profile.spell_mode())
	prep.start.emit()
	await _frames(5)
	var d: DialogueScreen = _screen()
	print("dialogue : ", d.scenes)
	d._open_history()
	await _frames(2)
	d._close_history()
	var taps := 0
	while _screen() is DialogueScreen and taps < 200:
		d._tap()
		taps += 1
		await _frames(1)
	print("taps : ", taps, " · écran : ", _screen().get_class(), " · prologue vu : ", Story.seen("prologue"), " · intro vue : ", Story.seen("z01_l01_intro"))
	var b: BattleScreen = _screen()
	b.sim.debug_set_ratio(0.0)
	await _frames(10)
	b.exit_requested.emit("map")
	await _frames(5)
	print("après 1-1 : ", _screen().get_class(), " · outro : ", (_screen() as DialogueScreen).scenes if _screen() is DialogueScreen else [])
	await _through_dialogues()
	print("  -> ", _screen().get_class(), " · outro vue : ", Story.seen("z01_l01_outro"))
	# Combat complet (Écho, sorts, Champion, Ultime, ordre), puis victoire et dialogue de fin.
	main.call("_start", "z01_l08", false)
	await _frames(10)
	b = _screen()
	b.sim.set_player_firing(true)
	await _frames(60)
	b.sim.debug_set_ratio(0.6)
	await _frames(5)
	print("état après 60 % : ", b.sim.state, " · fenêtre Écho : ", b._echo_open)
	b._choose_echo(b.sim.pending_echoes[0])
	b._on_spell_pressed(0, false)
	b._cast_aimed(Vector2(4.5, 8.0))
	b._on_champion()
	b.sim.surge = 100.0
	b._on_ultimate_pressed()
	b._cast_aimed(Vector2(4.5, 12.0))
	b.sim.cycle_order(1)
	await _frames(10)
	print("réplique : ", b.bark_text.text if b.bark_panel.visible else "(aucune)")
	# Tous les sorts du joueur, avec leurs animations (impacts différés, zones, chaîne, onde).
	var pc := b.sim.player()
	var cast := 0
	for i in range(pc.spells.size()):
		pc.mana = pc.mana_max
		pc.spell_cd.clear()
		var tgt := Vector2(4.5, 8.0)
		var cl := b.sim.densest_enemy(2.0)
		if int(cl["n"]) > 0:
			tgt = cl["pos"]
		b._on_spell_pressed(i, false)
		b._cast_aimed(tgt)
		cast += 1 if float(pc.spell_cd.get(pc.spells[i], 0.0)) > 0.0 else 0
		await _frames(2)
	print("sorts lancés : ", cast, "/", pc.spells.size(), " · zones ", b.sim.zones.size(), " · impacts en vol ", b.sim.pending_impacts.size())
	await _frames(40)
	print("après 40 images : zones ", b.sim.zones.size(), " · impacts ", b.sim.pending_impacts.size(), " · effets ", b.arena._spell_fx.get_child_count())
	b.sim.debug_set_ratio(0.3)
	await _frames(5)
	print("2e Écho : ", b.sim.state, " · fenêtre : ", b._echo_open)
	b._choose_echo(b.sim.pending_echoes[0])
	b.sim.debug_set_ratio(0.0)
	await _frames(10)
	print("état : ", b.sim.state, " · fenêtre de fin : ", b._end_open, " · étoiles : ", b.sim.stars)
	b.restart_requested.emit()
	await _frames(5)
	await _through_dialogues()
	await _frames(5)
	b = _screen()
	b.sim.barrier_hp = 0.0
	await _frames(10)
	print("état : ", b.sim.state, " · fenêtre de fin : ", b._end_open)
	# Fin de mission : le bouton « Équipement » mène directement à l'écran d'équipement.
	var gear_btn: Button = null
	for n in b.find_children("*", "Button", true, false):
		if (n as Button).text == "Équipement":
			gear_btn = n
	if gear_btn == null:
		push_error("fin de mission : bouton Équipement absent")
		quit(1)
		return
	gear_btn.pressed.emit()
	await _frames(10)
	print("fin de mission → ", _screen().get_script().get_global_name())
	if not (_screen() is EquipmentScreen):
		push_error("fin de mission : le bouton Équipement n'ouvre pas l'équipement")
		quit(1)
		return
	main.call("_start", "z01_l01", true)
	await _frames(10)
	b = _screen()
	b._open_pause()
	await _frames(5)
	print("pause : ", b.paused)
	b._on_resume()
	await _frames(5)
	# Écrans hors combat : Havre-Aube, carte, équipement, connexion.
	main.call("_show_hub")
	await _frames(5)
	main.call("_show_map")
	await _frames(5)
	main.call("_show_equipment")
	await _frames(5)
	var eq: EquipmentScreen = _screen()
	var inv: Array = Profile.data["inventory"]
	if inv.size() > 0:
		Profile.equip(str(inv[inv.size() - 1]["uid"]))
		eq.call("_rebuild")
	await _frames(5)
	# Salles 10.3 : arbre (1 point dans Combustion), Bibliothèque (deck), Cercle (ordre de Brann).
	main.call("_show_room", "skills")
	await _frames(5)
	var pts0 := Profile.skill_points_free()
	var invested := Profile.invest("combustion")
	var blocked := Profile.invest_block("braises")
	# Prérequis : Feu dévorant (palier 10) n'est relié qu'à Braises et Étincelle.
	var prereq_txt := ""
	var keep_ranks: Dictionary = Profile.skill_ranks().duplicate()
	var keep_level := Profile.level()
	Profile.data["player"]["level"] = maxi(40, Profile.level())
	for k in range(5):
		Profile.invest("ardeur")
	for k in range(4):
		Profile.invest("combustion")
	Profile.invest("torche_vivante")
	prereq_txt = Profile.invest_block("feu_devorant")
	var sk: SkillTreeScreen = _screen()
	sk._sel = "feu_devorant"
	sk._rebuild()
	await _frames(4)
	print("  arbre : prérequis « %s » · médaillons %d" % [prereq_txt, sk.find_children("", "SkillTreeView", true, false).size()])
	if not prereq_txt.begins_with("Prérequis") or sk.find_children("", "SkillTreeView", true, false).is_empty():
		push_error("arbre : prérequis ou vue incorrects")
		quit(1)
		return
	Profile.skill_ranks().clear()
	for k in keep_ranks.keys():
		Profile.skill_ranks()[k] = keep_ranks[k]
	Profile.data["player"]["level"] = keep_level
	main.call("_show_room", "library")
	await _frames(5)
	var t1 := Profile.toggle_deck("onde_arcanique")
	var deck_after := Profile.deck().size()
	Profile.toggle_deck("onde_arcanique")
	# Prix des sorts proportionnels à la puissance : un Novice s'achète tout de suite ; un Interdit
	# s'achète à n'importe quel niveau avec assez d'or, et donne de la Corruption.
	var g0 := Profile.gold()
	var p_nov := Profile.spell_price("etincelle")
	var nov := Profile.learn("etincelle")
	var forb := Profile.learn_block("soleil_noir")
	var cor0 := Story.value("corruption")
	var p_forb := Profile.spell_price("soleil_noir")
	Profile.data["gold"] = p_forb
	var forb_ok := Profile.learn("soleil_noir")
	var cor1 := Story.value("corruption")
	Profile.data["gold"] = g0 - p_nov
	(Profile.data["spells"]["known"] as Array).erase("soleil_noir")
	Story.add_value("corruption", cor0 - cor1)
	var ordered := Profile.spell_price("etincelle") < Profile.spell_price("boule_de_feu") and Profile.spell_price("boule_de_feu") < Profile.spell_price("comete") \
		and Profile.spell_price("comete") < Profile.spell_price("soleil_noir")
	print("prix : Étincelle ", p_nov, " or, apprise ", nov, " · Comète ", Profile.spell_price("comete"), " · Soleil noir ", p_forb, " (", forb, ") puis acheté ", forb_ok,
		" · Corruption ", cor0, " -> ", cor1, " · croissants ", ordered, " · catalogue ", LibraryScreen.catalogue().size())
	if not nov or not forb_ok or forb != "Or insuffisant" or cor1 - cor0 != 10 or not ordered or LibraryScreen.catalogue().size() != 56:
		push_error("rangs des sorts : apprentissage incorrect")
		quit(1)
		return
	main.call("_show_room", "circle")
	await _frames(5)
	Profile.set_circle("brann", "order", "focus_nexus")
	Profile.set_circle("sylwen", "spell", "volee_fleches")
	print("arbre : points ", pts0, " · Combustion ", invested, " (", Profile.skill_rank("combustion"), ") · Braises bloqué : ", blocked, " · mods ", Profile.skill_mods())
	print("deck : retrait ", "ok" if t1 == "" else t1, " -> ", deck_after, " sorts · deck ", Profile.deck().size(), " · Cercle ", Profile.circle())
	main.call("_start", "z01_l03", false)
	await _frames(10)
	var bt: BattleScreen = _screen()
	var bots := []
	for cc in bt.sim.casters:
		bots.append("%s:%s:%s" % [cc.id, cc.order, ",".join(cc.spells)])
	print("combat : sorts ", bt.sim.player().spells.size(), " · ", bots, " · mods ", bt.sim.mods.size())
	Profile.set_circle("brann", "order", "defends")
	Profile.set_circle("sylwen", "spell", "tir_precision")
	main.call("_show_save")
	await _frames(5)
	print("sauvegarde : ", _screen().get_script().get_global_name(), " · ", Profile.summary(Profile.data), " · ", Profile.save_date(Profile.data))
	main.call("_show_login", true)
	await _frames(5)
	print("niveau joueur : ", Profile.level(), " · or : ", Profile.gold(), " · objets : ", inv.size(), " · puissance : ", Profile.power())
	# Choix de l'histoire : 1-9 « Libérer les fées » (A), 1-10 « Abattre la Sylvarche » (B).
	var loy0 := Story.loyalty("sylwen")
	main.call("_show_dialogue", ["z01_l09_outro"], Callable(main, "_show_map"))
	await _frames(3)
	await _through_dialogues(0)
	print("1-9 : fées libérées ", Story.has_flag("s1.fees_liberees"), " · Sylwen ", loy0, " -> ", Story.loyalty("sylwen"))
	var items0 := (Profile.data["inventory"] as Array).size()
	main.call("_show_dialogue", ["z01_l10_outro"], Callable(main, "_show_map"))
	await _frames(3)
	await _through_dialogues(1)
	var staff := false
	for it in Profile.data["inventory"]:
		staff = staff or str(it["base"]) == "baton_seve"
	print("1-10 : abattue ", Story.has_flag("s1.sylvarche_abattue"), " · Sylwen ", Story.loyalty("sylwen"), " · Bâton ", staff, " · objets ", items0, " -> ", (Profile.data["inventory"] as Array).size(), " · choix ", Story.choice("z01_l10"))
	# Acte 2 : 2-9 (l'option [Humain / Clerc] est masquée pour un Mage elfe), puis ✦ 2-10 « Achever ».
	var c9: Dictionary = (Dialogues.scene("z02_l09_outro")["lines"] as Array).back()
	var vis := 0
	for o in c9["options"]:
		if Story.check(o):
			vis += 1
	main.call("_show_dialogue", ["z02_l09_outro"], Callable(main, "_show_map"))
	await _frames(3)
	await _through_dialogues(1)
	main.call("_show_dialogue", ["z02_l10_outro"], Callable(main, "_show_map"))
	await _frames(3)
	await _through_dialogues(1)
	var croc := false
	for it in Profile.data["inventory"]:
		croc = croc or str(it["base"]) == "croc_gharok"
	print("2-9 : options visibles ", vis, " · choix ", Story.choice("z02_l09"), " · 2-10 : ", Story.choice("z02_l10"), " · Krag allié ", Story.has_flag("s1.krag_allie"),
		" · loyauté ", Story.loyalty("krag"), " · Croc ", croc, " · disponibles ", Profile.companions_available())
	if vis != 2 or not Story.has_flag("s1.krag_allie") or Story.loyalty("krag") != 20 or not croc:
		push_error("acte 2 : choix 2-9 / 2-10 incorrects")
		quit(1)
		return
	# Autre fil : Ambreval défendu en 2-9 puis Gharok achevé -> Krag part.
	var saved: Dictionary = (Story.st() as Dictionary).duplicate(true)
	Story.st()["choices"]["z02_l09"] = {"opt": "A", "t": 0}
	Story.set_flag("s1.krag_allie", false)
	var c10: Dictionary = {}
	for l in Dialogues.scene("z02_l10_outro")["lines"]:
		if (l as Dictionary).has("choice"):
			c10 = l
	Story.apply(c10["options"][1]["effects"])
	print("  fil A puis B : Krag parti ", Story.has_flag("s1.krag_parti"), " · allié ", Story.has_flag("s1.krag_allie"))
	if not Story.has_flag("s1.krag_parti") or Story.has_flag("s1.krag_allie"):
		push_error("acte 2 : Krag doit partir si Ambreval a été défendu puis Gharok achevé")
		quit(1)
		return
	Profile.data["story"] = saved
	# Acte 3 : Nyx rejoint (3-6), 3-9 « Protéger Corvin », ✦ 3-10 « Voie des Cendres » -> branche Voie du Surge.
	var arc: Dictionary = {}
	for br in Profile.tree_db()["branches"]:
		if str(br["id"]) == "arcano":
			arc = br
	var locked0 := Profile.branch_locked(arc) != ""
	for sid in ["z03_l06_outro", "z03_l09_outro", "z03_l10_outro"]:
		main.call("_show_dialogue", [sid], Callable(main, "_show_map"))
		await _frames(3)
		await _through_dialogues(1)
	print("acte 3 : Nyx alliée ", Story.has_flag("s1.nyx_allie"), " · loyauté ", Story.loyalty("nyx"), " · 3-9 ", Story.choice("z03_l09"), " · 3-10 ", Story.choice("z03_l10"),
		" · Corruption ", Story.value("corruption"), " · Voie du Surge : verrouillée avant ", locked0, ", après ", Profile.branch_locked(arc) != "",
		" · Aube éternelle « ", Profile.invest_block("aube_eternelle"), " » · Cendres vives « ", Profile.invest_block("cendres_vives"), " »")
	if not Story.has_flag("s1.nyx_allie") or Story.loyalty("nyx") != 80 or not locked0 or Profile.branch_locked(arc) != "" or not Profile.invest_block("aube_eternelle").begins_with("Réservé") or Profile.invest_block("cendres_vives").begins_with("Réservé"):
		push_error("acte 3 incorrect")
		quit(1)
		return
	if not await _act4_ok():
		quit(1)
		return
	if not await _act5_ok():
		quit(1)
		return
	if not await _act6_ok():
		quit(1)
		return
	if not await _act7_ok():
		quit(1)
		return
	if not await _cine_ok():
		quit(1)
		return
	if not await _replay_scenes_ok():
		quit(1)
		return
	if not await _audio_ok():
		quit(1)
		return
	main.call("_show_room", "circle")
	await _frames(5)
	Profile.swap_active("krag", "brann")
	print("Cercle : actifs ", Profile.active_companions())
	# Objectifs spéciaux : boss (avec l'aide des fées), escorte, siège, lucioles.
	for id in ["z01_l05", "z01_l07", "z01_l09", "z01_l10", "z01_l02", "z02_l03", "z02_l07", "z02_l10", "z03_l03", "z03_l10"]:
		main.call("_start", id, false)
		await _frames(30)
		var bs: BattleScreen = _screen()
		if id == "z01_l10":
			print("  fées : bouclier ", bs.sim.barrier_shield, " · lucioles ", bs.sim.orbs.size(), " · notes ", bs.sim.story_notes.size())
		bs.sim.set_player_firing(true)
		await _frames(90)
		print(id, " · ", bs.sim.objective_title(), " · ", bs.sim.objective_info(), " · état ", bs.sim.state)
		if id == "z03_l03":
			var f0 := bs.sim.fog.size()
			var cleared := bs.sim.clear_fog(bs.sim.fog[0]["pos"], 1.0)
			print("  brume : ", f0, " bancs · Purifier dissipe ", cleared, " (densité ", bs.sim.fog[0]["density"], ")")
			if f0 < 1 or not cleared:
				push_error("brume incorrecte")
				quit(1)
				return
		if id == "z03_l10":
			# Tête tranchée -> plaie ; Boule de feu sur la plaie -> cautérisée, pas de repousse.
			var h0 := bs.sim.heads_alive()
			var hd: Unit = bs.sim.heads[0]
			bs.sim._damage(hd, hd.hp + 1.0, "physique")
			var st_n := bs.sim.stumps.size()
			var hp := bs.sim.player()
			hp.mana = hp.mana_max
			hp.spell_cd.clear()
			var burned := bs.sim.cast_spell(hp, "boule_de_feu", bs.sim.stumps[0]["pos"])
			for k in range(30):
				bs.sim.step()
			print("  Hydre : têtes ", h0, " -> plaie ", st_n, " · Boule de feu ", burned, " · plaies restantes ", bs.sim.stumps.size(), " · têtes ", bs.sim.heads_alive())
			if h0 != 3 or st_n != 1 or not bs.sim.stumps.is_empty() or bs.sim.heads_alive() != 2:
				push_error("têtes de l'Hydre incorrectes")
				quit(1)
				return
		if id == "z02_l03":
			# Barrage (Orage) et magie interdite (Soleil noir, -20 Barrière).
			var pcs: BattleSim.Caster = bs.sim.player()
			pcs.spells.append_array(["orage", "soleil_noir"])
			pcs.mana = pcs.mana_max
			var b0 := bs.sim.barrier_hp
			var ok1 := bs.sim.cast_spell(pcs, "orage", Vector2(4.5, 9.0))
			pcs.mana = pcs.mana_max
			var ok2 := bs.sim.cast_spell(pcs, "soleil_noir", Vector2(4.5, 10.0))
			print("  sorts : Orage ", ok1, " · impacts en attente ", bs.sim.pending_impacts.size(), " · Soleil noir ", ok2, " · Barrière ", int(b0), " -> ", int(bs.sim.barrier_hp))
			await _frames(40)
			if not ok1 or not ok2 or b0 - bs.sim.barrier_hp < 19.0:
				push_error("sorts : barrage ou prix en Barrière incorrect")
				quit(1)
				return
			# Terrain interactif : marais + foudre (électrocution), banquise + feu (vapeur), mur, séisme, cataclysme.
			var tr: BattleTerrain = bs.sim.terrain
			pcs.spells.append_array(["marais", "javelot_foudre", "banquise", "boule_de_feu", "mur_pierre", "seisme", "cataclysme", "rune_piege"])
			var casts := []
			for sid in ["marais", "javelot_foudre", "banquise", "boule_de_feu", "mur_pierre", "rune_piege", "seisme"]:
				pcs.mana = pcs.mana_max
				var at := Vector2(4.5, 8.0)
				if sid in ["banquise", "boule_de_feu"]:
					at = Vector2(4.5, 11.0)
				casts.append(bs.sim.cast_spell(pcs, sid, at))
				await _frames(14)
			var standing := 0
			for pr in tr.props:
				if bool(pr["alive"]):
					standing += 1
			bs.sim.barrier_hp = bs.sim.barrier_max
			pcs.mana = pcs.mana_max
			var cata := bs.sim.cast_spell(pcs, "cataclysme", Vector2(4.5, 8.0))
			await _frames(30)
			var fallen := 0
			for pr in tr.props:
				if not bool(pr["alive"]):
					fallen += 1
			var kinds := {}
			for sf in tr.surfaces:
				kinds[str(sf["kind"])] = true
			print("  terrain : lancers ", casts, " · réactions ", tr.reactions, " · murs ", tr.walls.size(), " · sols ", kinds.keys(), " · piliers debout ", standing, " · Cataclysme ", cata, " : ", fallen, "/", tr.props.size(), " à terre")
			if casts.has(false) or tr.reactions < 2 or fallen != tr.props.size() or not kinds.has("cratere"):
				push_error("terrain interactif incorrect")
				quit(1)
				return
		bs.sim.debug_set_ratio(0.0)
		if id == "z01_l05":
			# Race Nain : passif Sang de pierre (DÉF des invocations) et Don Rempart runique.
			var fam: Unit = null
			for al in bs.sim.allies:
				if al.owner_idx == 0 and al.role == "familier":
					fam = al
					break
			var sh0 := bs.sim.barrier_shield
			bs.sim.don_t = 0.0
			var used := bs.sim.use_don()
			print("  race : Don ", bs.sim.don.get("id", ""), " lancé ", used, " · bouclier ", int(sh0), " -> ", int(bs.sim.barrier_shield), " · recharge ", int(bs.sim.don_t),
				" s · DÉF d'une invocation ", fam.defense if fam != null else -1.0)
			if not used or bs.sim.barrier_shield <= sh0 or bs.sim.don_t < 40.0 or (fam != null and fam.defense < 2.9):
				push_error("Don racial ou passif incorrect")
				quit(1)
				return
		if id == "z01_l05":
			print("  héros : sprite ", bs.sim.player().sprite, " · race ", bs.sim.player().race_id, " · hauteur ", SpriteAtlas.height_m("player"))
			if bs.sim.player().sprite != "player" or bs.sim.player().race_id != "nain":
				push_error("sprite du héros incorrect")
				quit(1)
				return
		if id.begins_with("z02"):
			var ids: Array[String] = []
			for cc in bs.sim.casters:
				ids.append("%s@%s" % [cc.id, cc.side])
			print("  équipe ", ids)
			print("  zone 2 : décor ", WorldArt.zone, " · pylônes ", bs.sim.pylons.size(), " · vent ", not bs.sim.wind_cfg.is_empty(), " · bannières ", bs.sim.banners_alive())
		if bs.sim.boss != null:
			bs.sim.boss.hp = 0.0
			bs.sim.boss.alive = false
		await _frames(10)
		print("  -> ", bs.sim.state, " · ", bs.sim.end_reason)
		bs.exit_requested.emit("map")
		await _frames(3)
		await _through_dialogues()
	if WorldArt.zone != 1:
		push_error("décor : la zone doit revenir à 1 hors combat")
		quit(1)
		return
	# Mode Tiroir : écoles -> sorts d'une école (appui), choix au relâcher, lancer, retour aux écoles.
	Profile.set_spell_mode("drawer")
	main.call("_start", "z02_l03", false)
	await _frames(10)
	var dt: BattleScreen = _screen()
	var pl: BattleSim.Caster = dt.sim.player()
	pl.mana = pl.mana_max
	dt._on_cell_down(0)
	await _frames(2)
	var opened: String = dt._drawer
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.pressed = false
	rel.position = dt.spell_btns[1].get_global_rect().get_center()
	dt._input(rel)
	var chosen: String = dt.aiming
	dt._cast_aimed(Vector2(4.5, 9.0))
	await _frames(2)
	print("tiroir : ", pl.spells.size(), " sorts · écoles ", dt._by_school.keys(), " · ouvert ", opened, " · choisi ", chosen, " · revenu aux écoles ", dt._drawer == "", " · cases ", dt.spell_btns.size())
	if opened != "feu" or chosen == "" or dt._drawer != "" or dt.aiming != "" or dt.spell_btns.size() != 8:
		push_error("tiroir de sorts incorrect")
		quit(1)
		return
	Profile.set_spell_mode("deck")
	dt.exit_requested.emit("map")
	await _frames(5)
	await _through_dialogues()
	# Synchronisation : la progression la plus avancée n'est jamais écrasée par une plus récente.
	var fresh := Profile.default_data()
	fresh["updated"] = Profile.updated() + 1000.0
	var advanced := Profile.data.duplicate(true)
	print("sync : partie neuve plus récente remplace la progression ? ", Cloud.prefer_remote(advanced, fresh),
		" · progression du compte remplace une partie neuve ? ", Cloud.prefer_remote(fresh, advanced))
	if Cloud.prefer_remote(advanced, fresh) or not Cloud.prefer_remote(fresh, advanced):
		push_error("synchronisation : la progression la plus avancée doit l'emporter")
		quit(1)
		return
		print("scènes vues : ", (Story.st()["seen"] as Dictionary).size(), " · forêt guérie : ", Profile.battle_opts()["healed"])
	print("OK smoke")
	quit()


## Acte 4 (docs/design/32-narration-zone4.md) : 20 scènes, feu de camp, 4-9 (option [Brann · loyauté 60]
## ouverte à un Mage elfe, sinon montrée verrouillée), ✦ 4-10 « Briser son cœur » (Enclume-Cœur,
## matériaux), honneur de Forgecœur (titre de Brann), effets en combat (portails FORGE ×2, vagues).
func _act4_ok() -> bool:
	for n in range(1, 11):
		for part in ["intro", "outro"]:
			if not Dialogues.has_scene("z04_l%02d_%s" % [n, part]):
				push_error("acte 4 : scène manquante z04_l%02d_%s" % [n, part])
				return false
	for who in ["durgan", "ysolde", "orrin"]:
		for mood in ["neutre", "joie", "triste", "colere", "surpris"]:
			if PortraitArt.texture(who, mood) == null:
				push_error("acte 4 : portrait %s/%s absent" % [who, mood])
				return false
	for kind in ["pics", "porte", "lac", "forteresse", "colosse", "forge"]:
		if StoryArt.plate(kind, Vector2i(320, 180)) == null:
			push_error("acte 4 : planche %s absente" % kind)
			return false
	var saved: Dictionary = (Story.st() as Dictionary).duplicate(true)
	var inv0: Array = (Profile.data["inventory"] as Array).duplicate(true)
	var mats0: Dictionary = (Profile.data["materials"] as Dictionary).duplicate(true)
	var race0 := str(Profile.data["player"].get("race", ""))
	Profile.data["player"]["race"] = "elfe"
	Story.st()["loyalty"]["brann"] = 55
	var givre0 := int(Profile.data["materials"].get("cristal_givre", 0))
	main.call("_show_dialogue", ["z04_l06_outro"], Callable(main, "_show_map"))
	await _frames(3)
	await _through_dialogues(1)
	main.call("_show_dialogue", ["z04_l08_outro"], Callable(main, "_show_map"))
	await _frames(3)
	await _through_dialogues(0)
	var loy8 := Story.loyalty("brann")
	# 4-9 : Brann à 70 -> l'option [Brann · loyauté 60] est ouverte, l'option [Nain] reste masquée.
	main.call("_show_dialogue", ["z04_l09_outro"], Callable(main, "_show_map"))
	await _frames(3)
	var open9 := 0
	var locked9 := 0
	var guard := 0
	while guard < 40 and _screen() is DialogueScreen and not bool((_screen() as DialogueScreen).get("_waiting_choice")):
		(_screen() as DialogueScreen)._skip()
		guard += 1
		await _frames(3)
	if _screen() is DialogueScreen:
		for ch in (_screen() as DialogueScreen).choice_box.get_children():
			if ch is Button:
				if (ch as Button).disabled:
					locked9 += 1
				else:
					open9 += 1
	await _through_dialogues(0)
	main.call("_show_dialogue", ["z04_l10_outro"], Callable(main, "_show_map"))
	await _frames(3)
	await _through_dialogues(1)
	var anvil := false
	for it in Profile.data["inventory"]:
		anvil = anvil or str(it["base"]) == "enclume_coeur"
	var givre := int(Profile.data["materials"].get("cristal_givre", 0)) - givre0
	print("acte 4 : Brann ", loy8, " -> ", Story.loyalty("brann"), " · 4-6 ", Story.choice("z04_l06"), " · vérité ", Story.has_flag("s1.verite_orrin"),
		" · 4-9 ", Story.choice("z04_l09"), " (options ouvertes ", open9, ", verrouillées ", locked9, ") · Portes ", Story.has_flag("s1.portes_reactivees"),
		" · ✦ 4-10 ", Story.choice("z04_l10"), " · Enclume-Cœur ", anvil, " · Cristal de givre +", givre,
		" · honneur ", Story.has_flag("s1.honneur_forgecoeur"), " · titre « ", Dialogues.subtitle("brann"), " »")
	if loy8 != 70 or open9 != 2 or locked9 != 0 or Story.choice("z04_l09") != "A" or not Story.has_flag("s1.portes_reactivees") \
			or Story.choice("z04_l10") != "B" or not anvil or givre != 9 or not Story.has_flag("s1.honneur_forgecoeur") \
			or not Dialogues.subtitle("brann").begins_with("Héritier de Forgecœur"):
		push_error("acte 4 : choix incorrects")
		return false
	# Brann à 50 : l'option réservée apparaît verrouillée (cadenas), on scelle la forteresse.
	Story.st()["loyalty"]["brann"] = 50
	(Story.st()["choices"] as Dictionary).erase("z04_l09")
	main.call("_show_dialogue", ["z04_l09_outro"], Callable(main, "_show_map"))
	await _frames(3)
	open9 = 0
	locked9 = 0
	guard = 0
	while guard < 40 and _screen() is DialogueScreen and not bool((_screen() as DialogueScreen).get("_waiting_choice")):
		(_screen() as DialogueScreen)._skip()
		guard += 1
		await _frames(3)
	if _screen() is DialogueScreen:
		for ch in (_screen() as DialogueScreen).choice_box.get_children():
			if ch is Button:
				if (ch as Button).disabled:
					locked9 += 1
				else:
					open9 += 1
	await _through_dialogues(0)
	print("  4-9 avec Brann à 50 : ouvertes ", open9, ", verrouillées ", locked9, " · choix ", Story.choice("z04_l09"), " · scellée ", Story.has_flag("s1.forteresse_scellee"), " · Brann ", Story.loyalty("brann"))
	if open9 != 1 or locked9 != 1 or Story.choice("z04_l09") != "B" or not Story.has_flag("s1.forteresse_scellee") or Story.loyalty("brann") != 35:
		push_error("acte 4 : option verrouillée incorrecte")
		return false
	# Un Nain voit l'option [Nain] (et pas celle de Brann), quelle que soit la loyauté.
	Profile.data["player"]["race"] = "nain"
	var c9: Dictionary = (Dialogues.scene("z04_l09_outro")["lines"] as Array).back()
	var tags: Array[String] = []
	for o in c9["options"]:
		if Story.check(o):
			tags.append(str(o.get("tag", "-")))
	Profile.data["player"]["race"] = race0
	print("  4-9 pour un Nain : ", tags)
	if tags != ["Nain", "-"]:
		push_error("acte 4 : options pour un Nain incorrectes")
		return false
	# En combat : portails FORGE ×2, Sentinelles anciennes dans les vagues, vagues réduites (forteresse scellée).
	main.call("_start", "z04_l03", false)
	await _frames(30)
	var bs: BattleScreen = _screen()
	var pool: Dictionary = bs.sim.level["waves"]["pool"]
	var base_pool: Dictionary = GameData.level("z04_l03")["waves"]["pool"]
	print("  z04_l03 : FORGE ×", bs.sim.forge_power, " · vagues ×", bs.sim.wave_budget_mult, " · Sentinelles ", pool.get("ancient_sentinel", 0), " (niveau d'origine ", base_pool.get("ancient_sentinel", 0), ") · notes ", bs.sim.story_notes.size())
	if not is_equal_approx(bs.sim.forge_power, 2.0) or not is_equal_approx(bs.sim.wave_budget_mult, 0.85) or float(pool.get("ancient_sentinel", 0)) < 0.5 \
			or base_pool.has("ancient_sentinel") or bs.sim.story_notes.size() != 2:
		push_error("acte 4 : effets en combat incorrects")
		return false
	main.call("_show_map")
	await _frames(5)
	Profile.data["story"] = saved
	Profile.data["inventory"] = inv0
	Profile.data["materials"] = mats0
	return true


## Acte 5 (docs/design/34-narration-zone5.md) : 20 scènes, portraits, planches ; élèves libérés (5-7),
## Journal lu (5-9 : Fragment de Morvaen, énigmes à 8 invocations), ✦ 5-10 « Révéler son Sceau » ;
## Journal brûlé : bouclier de Thalren devant le Sphinx.
func _act5_ok() -> bool:
	for n in range(1, 11):
		for part in ["intro", "outro"]:
			if not Dialogues.has_scene("z05_l%02d_%s" % [n, part]):
				push_error("acte 5 : scène manquante z05_l%02d_%s" % [n, part])
				return false
	for who in ["thalren", "sphinx"]:
		for mood in ["neutre", "joie", "triste", "colere", "surpris"]:
			if PortraitArt.texture(who, mood) == null:
				push_error("acte 5 : portrait %s/%s absent" % [who, mood])
				return false
	for kind in ["dunes", "oasis", "miroirs", "college", "desert_nuit", "sphinx"]:
		if StoryArt.plate(kind, Vector2i(320, 180)) == null:
			push_error("acte 5 : planche %s absente" % kind)
			return false
	var saved: Dictionary = (Story.st() as Dictionary).duplicate(true)
	var nyx0 := Story.loyalty("nyx")
	var cor0 := Story.value("corruption")
	for sid in ["z05_l07_outro", "z05_l09_outro", "z05_l10_outro"]:
		main.call("_show_dialogue", [sid], Callable(main, "_show_map"))
		await _frames(3)
		await _through_dialogues(0)
	print("acte 5 : 5-7 ", Story.choice("z05_l07"), " (Nyx ", nyx0, " -> ", Story.loyalty("nyx"), ") · 5-9 ", Story.choice("z05_l09"), " (Fragments ", Story.value("fragments"),
		", Corruption ", cor0, " -> ", Story.value("corruption"), ") · ✦ 5-10 ", Story.choice("z05_l10"), " · faiblesse ", Story.has_flag("s1.faiblesse_morvaen"), " · Archivistes ", Story.value("rep.archivistes"))
	if Story.choice("z05_l07") != "A" or Story.loyalty("nyx") < nyx0 + 9 or Story.choice("z05_l09") != "A" or Story.value("fragments") != 1 \
			or Story.value("corruption") != mini(100, cor0 + 10) or Story.choice("z05_l10") != "A" or not Story.has_flag("s1.faiblesse_morvaen") or Story.value("rep.archivistes") != 10:
		push_error("acte 5 : choix incorrects")
		return false
	# Effets devant le Sphinx : Journal lu -> énigmes à 8 ; Journal brûlé -> bouclier de Thalren.
	var a := BattleSim.new()
	a.setup(GameData.level("z05_l10"), GameData.party(), 2, {"solo": true, "flags": ["s1.journal_lu"]})
	a._flush()
	a._boss_ability({"type": "riddle", "need": 12, "y": 7.8, "xs": [1.7, 4.5, 7.3]})
	var need := 0
	for pt in a.portals:
		if pt.kind == "answer":
			need = pt.need
	a.terrain.sim = null
	var b := BattleSim.new()
	b.setup(GameData.level("z05_l10"), GameData.party(), 2, {"solo": true, "flags": ["s1.thalren_confiance"]})
	var shield := b.barrier_shield
	b.terrain.sim = null
	print("  Sphinx : Journal lu -> %d invocations par réponse · Journal brûlé -> bouclier de Thalren +%d" % [need, int(shield)])
	Profile.data["story"] = saved
	if need != 8 or shield < 25.0:
		push_error("acte 5 : effets en combat incorrects")
		return false
	return true


## Équipement (docs/design/35-equipement-runes-forge.md) : catalogue et icônes, gravure de runes (effet selon
## la catégorie), retrait, fusion de runes, fusion d'objets (règles, Mythique), runes au butin, effets en
## combat, écrans de la Forge et de l'Équipement.
func _gear_ok() -> bool:
	var errs: Array[String] = []
	var db := Profile.items_db()
	var bases: Dictionary = db["bases"]
	for id in bases.keys():
		if ItemArt.item(str(id), 48) == null:
			errs.append("icône %s" % id)
	for z in range(1, 8):
		if ((db["loot_pool"] as Dictionary).get(str(z), []) as Array).size() < 36:
			errs.append("butin de zone %d" % z)
	var fams: Dictionary = db["runes"]["families"]
	for f in fams.keys():
		if ItemArt.rune(str(f), 3, 48) == null:
			errs.append("rune %s" % f)
		for cat in ["arme", "armure", "bijou", "charme"]:
			if Profile.rune_effect({"rune": f, "level": 1, "rarity": "commun"}, cat).is_empty():
				errs.append("effet %s/%s" % [f, cat])
	var saved := Profile.data.duplicate(true)
	Profile.data["gold"] = 999999
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	# Gravure : la même rune Pyr agit autrement sur une arme (sorts de Feu) et sur une armure (résistance).
	var wuid := str(Profile.equipment_of("player").get("weapon", ""))
	var weapon := Profile.find_item(wuid)
	weapon["runes"] = []
	var pyr := Profile.make_rune("pyr", 3, "epique")
	var kaor := Profile.make_rune("kaor", 2, "rare")
	Profile.rune_inventory().append_array([pyr, kaor])
	var ok1 := Profile.engrave(wuid, str(pyr["uid"]))
	var fire_spells := float(Profile.all_mods().get("elem_dmg.feu", 0.0))
	var helm := Profile.make_item("heaume_milicien", "commun", 10, rng)
	(Profile.data["inventory"] as Array).append(helm)
	Profile.equip(str(helm["uid"]))
	var pou0 := int(Profile.item_stats(helm).get("pou", 0))
	var ok2 := Profile.engrave(str(helm["uid"]), str(kaor["uid"]))
	var pou1 := int(Profile.item_stats(helm).get("pou", 0))
	var extra := Profile.make_rune("vigr", 1, "commun")
	Profile.rune_inventory().append(extra)
	var full := Profile.engrave_block(helm, extra)
	var back := Profile.unengrave(str(helm["uid"]), 0)
	var armor_pyr := Profile.rune_effect_text(pyr, "armure")
	if not ok1 or fire_spells <= 0.0 or not ok2 or pou1 <= pou0 or full == "" or not back or Profile.find_rune(str(kaor["uid"])).is_empty() or not armor_pyr.begins_with("Résistance au Feu"):
		errs.append("gravure : arme %s (Feu %.3f), armure %s (POU %d -> %d), plein « %s », retrait %s, « %s »" % [ok1, fire_spells, ok2, pou0, pou1, full, back, armor_pyr])
	# En combat : sorts de Feu renforcés, bouclier de départ, résistance des invocations.
	var bo := Profile.battle_opts()
	var sim := BattleSim.new()
	bo["mods"]["start_shield"] = 12.0
	bo["mods"]["resist.physique"] = 0.5
	bo["solo"] = true
	sim.setup(GameData.level("z01_l01"), GameData.party(), 3, bo)
	var fire_mult := sim._elem_mult(sim.player(), {"element": "feu"})
	var u := sim._spawn_familiar(sim.player(), Vector2(4.5, 3.0))
	sim._flush()
	var h0 := u.hp
	sim._damage(u, 10.0, "physique")
	var resisted := absf((h0 - u.hp) - 5.0) < 0.01
	if fire_mult <= 1.0 or sim.barrier_shield < 12.0 or not resisted:
		errs.append("combat : Feu ×%.3f, bouclier %.1f, résistance %s" % [fire_mult, sim.barrier_shield, resisted])
	sim.terrain.sim = null
	# Fusion de runes : 3 identiques -> niveau au-dessus ; différentes -> refus.
	var trio: Array = []
	for k in range(3):
		var r := Profile.make_rune("isa", 2, "rare")
		Profile.rune_inventory().append(r)
		trio.append(str(r["uid"]))
	var mixed: Array = [trio[0], trio[1], str(extra["uid"])]
	var refuse := Profile.rune_fuse_block(mixed)
	var fused_r := Profile.fuse_runes(trio)
	if refuse == "" or int(fused_r.get("level", 0)) != 3 or str(fused_r.get("rune", "")) != "isa":
		errs.append("fusion de runes : refus « %s », résultat %s" % [refuse, fused_r])
	# Fusion d'objets : 3 communs -> rare « fusion », qui peut refusionner ; 3 légendaires -> Mythique.
	var com: Array = []
	for k in range(3):
		var it := Profile.make_item("gants_cuir" if k == 0 else "bottes_marche", "commun", 5 + k, rng)
		(Profile.data["inventory"] as Array).append(it)
		com.append(str(it["uid"]))
	var out := Profile.fuse_items(com)
	var again := Profile.fusion_item_block(out)
	var leg: Array = []
	for k in range(3):
		var it := Profile.make_item("anneau_cuivre", "legendaire", 20, rng)
		(Profile.data["inventory"] as Array).append(it)
		leg.append(str(it["uid"]))
	var mixed_items: Array = [leg[0], leg[1], str(out["uid"])]
	var refuse_i := Profile.fusion_block(mixed_items)
	var myth := Profile.fuse_items(leg)
	var equipped_block := Profile.fusion_item_block(helm)
	# Un objet fusionné refusionne : 3 rares « fusion » -> épique.
	var re_fused: Array = [str(out["uid"])]
	for k in range(2):
		var it2 := Profile.make_item("gants_cuir", "rare", 8, rng)
		it2["fused"] = true
		(Profile.data["inventory"] as Array).append(it2)
		re_fused.append(str(it2["uid"]))
	Profile.data["gold"] = Profile.gold() + 5000
	var epic := Profile.fuse_items(re_fused)
	if str(epic.get("rarity", "")) != "epique" or not bool(epic.get("fused", false)):
		errs.append("refusion d'objets fusionnés : %s" % epic.get("rarity", "refusée"))
	if str(out.get("rarity", "")) != "rare" or str(out.get("base", "")) != "gants_cuir" or int(out.get("ilvl", 0)) != 7 or not bool(out.get("fused", false)) or again != "" \
			or refuse_i == "" or str(myth.get("rarity", "")) != "mythique" or Profile.sockets_of(myth) != 4 or equipped_block == "":
		errs.append("fusion d'objets : %s %s iLvl %s, refusion « %s », mélange « %s », mythique %s, équipé « %s »" % [out.get("base", ""), out.get("rarity", ""), out.get("ilvl", 0), again, refuse_i, myth.get("rarity", ""), equipped_block])
	if bases.size() < 180:
		errs.append("catalogue : %d objets" % bases.size())
	# Légendaire de boss : la Fiole des Trois Venins finit par tomber, une seule fois.
	var vials := 0
	for k in range(60):
		Profile.apply_battle("z03_l10", true, 3, 300.0)
	for it in Profile.data["inventory"]:
		if str(it["base"]) == "fiole_trois_venins":
			vials += 1
	if vials != 1:
		errs.append("Fiole des Trois Venins ×%d en 60 victoires" % vials)
	# Butin : un boss donne au moins une rune.
	var n0 := Profile.rune_inventory().size()
	var rew := Profile.apply_battle("z03_l10", true, 3, 300.0)
	if (rew.get("runes", []) as Array).is_empty() or Profile.rune_inventory().size() <= n0:
		errs.append("aucune rune au butin d'un boss")
	print("équipement : %d objets, %d runes · Pyr III épique : arme « %s », armure « %s » · Kaor II sur un heaume : POU %d -> %d · fusion %s -> %s, Mythique %s · butin du boss : %d rune(s)" % [
		bases.size(), fams.size(), Profile.rune_effect_text(pyr, "arme"), armor_pyr, pou0, pou1, "commun", out.get("rarity", ""), myth.get("rarity", ""), (rew.get("runes", []) as Array).size()])
	# Écrans : Forge (3 onglets) et Équipement.
	main.call("_show_forge", str(helm["uid"]), "equipment", "player")
	await _frames(4)
	for t in ["fusion", "runes", "gravure"]:
		var fs: ForgeScreen = _screen()
		fs.tab = t
		fs._rebuild()
		await _frames(3)
	main.call("_show_equipment", "player")
	await _frames(4)
	if not (_screen() is EquipmentScreen):
		errs.append("écran Équipement")
	Profile.data = saved
	main.call("_show_map")
	await _frames(3)
	if not errs.is_empty():
		push_error("équipement : %s" % [errs])
		return false
	return true


## Fonds des salles : chaque scène se génère (portrait et paysage), chaque salle a la sienne, la Carte suit la zone.
func _rooms_art_ok() -> bool:
	for kind in RoomArt.KINDS:
		for v in [Vector2(720, 1280), Vector2(2275, 1280)]:
			var tex := RoomArt.scene(str(kind), RoomArt.size_for(v))
			if tex == null or tex.get_width() < 96 or tex.get_height() < 96:
				push_error("fond de salle manquant : %s" % kind)
				return false
	var seen := {}
	for sc in [ForgeScreen.new(), EquipmentScreen.new(), SkillTreeScreen.new(), MeditationScreen.new(), LibraryScreen.new(), CircleScreen.new(), OptionsScreen.new()]:
		root.add_child(sc)
		await process_frame
		var art := sc.get_node_or_null("BackdropArt") as TextureRect
		if art == null or art.texture == null or art.texture is CompressedTexture2D or seen.has(art.texture):
			push_error("fond de salle non spécifique : %s" % sc.get_class())
			return false
		seen[art.texture] = true
		sc.queue_free()
	var map := MapScreen.new()
	map.zone = 1
	root.add_child(map)
	await process_frame
	var t1: Texture2D = (map.get_node("BackdropArt") as TextureRect).texture
	UiTheme.set_scene(map, "zone4")
	if (map.get_node("BackdropArt") as TextureRect).texture == t1:
		push_error("la Carte ne change pas de décor avec la zone")
		return false
	map.queue_free()
	print("salles : %d fonds générés" % RoomArt.KINDS.size())
	return true


## Tir automatique : le choix est gardé dans le profil et repris au combat suivant.
func _autofire_ok() -> bool:
	var before := Profile.auto_fire_on()
	Profile.set_auto_fire(true)
	var bs := BattleScreen.new()
	bs.level_id = "z01_l02"
	root.add_child(bs)
	await _frames(2)
	var on_start := bs.auto_fire and bs.sim.player().firing
	var b := Button.new()
	bs._on_toggle_autofire(b)
	b.free()
	var saved_off := not Profile.auto_fire_on()
	bs.queue_free()
	await _frames(1)
	var bs2 := BattleScreen.new()
	bs2.level_id = "z01_l02"
	root.add_child(bs2)
	await _frames(2)
	var off_next := not bs2.auto_fire and not bs2.sim.player().firing
	bs2.queue_free()
	Profile.set_auto_fire(before)
	print("tir auto : repris au départ %s · coupé et gardé %s · combat suivant sans tir %s" % [on_start, saved_off, off_next])
	if not (on_start and saved_off and off_next):
		push_error("le choix du tir automatique n'est pas gardé")
		return false
	return true


## Comparaison avec l'équipé : objets meilleurs signalés et triés en tête, anneau le plus faible remplacé.
## Héros en volume (Équipement) : chaque classe et chaque race se rend sous tous les angles ; la face, le dos et
## les profils diffèrent ; la vue tournante de l'Équipement existe pour le héros.
func _hero_model_ok() -> bool:
	var errs: Array[String] = []
	var races: Array = (GameData.party()["races"] as Dictionary).keys()
	var classes: Array = (GameData.party()["classes"] as Dictionary).keys()
	for i in range(maxi(races.size(), classes.size())):
		var race := str(races[i % races.size()])
		var cls := str(classes[i % classes.size()])
		var m := HeroModel.new()
		m.build({"head": PlayerLook.HEADS.keys()[i % 4], "sil": i % 2, "face": i % 3}, race, cls)
		var seen: Dictionary = {}
		for k in range(0, HeroModel.STEPS, 6):
			var img := m.image_at(float(k) / float(HeroModel.STEPS) * TAU)
			var used := img.get_used_rect()
			if used.size.x < 8 or used.size.y < 22:
				errs.append("%s %s : image vide à l'angle %d (%s)" % [race, cls, k, used])
			seen[Marshalls.raw_to_base64(img.get_data()).sha256_text()] = true
		if seen.size() < 6:
			errs.append("%s %s : %d vues différentes seulement" % [race, cls, seen.size()])
	var es := EquipmentScreen.new()
	root.add_child(es)
	var tt := es.find_children("*", "HeroTurntable", true, false)
	es.queue_free()
	if tt.is_empty():
		errs.append("pas de vue tournante dans l'Équipement")
	# Brann et Sylwen aussi, avec l'arme de leur voie.
	for who in HeroModel.COMPANIONS:
		for cls in ["chevalier", "archer", "mage"]:
			var cm := HeroModel.of_companion(str(who), cls)
			var front := cm.image_at(PI)
			var back := cm.image_at(0.0)
			if front.get_used_rect().size.y < 18 or front.get_data() == back.get_data():
				errs.append("%s (%s) : rendu incorrect" % [who, cls])
		var es2 := EquipmentScreen.new()
		es2.who = str(who)
		root.add_child(es2)
		if es2.find_children("*", "HeroTurntable", true, false).is_empty():
			errs.append("pas de vue tournante pour %s" % who)
		es2.queue_free()
	if not errs.is_empty():
		push_error("héros en volume : %s" % [errs])
		return false
	print("héros en volume : %d races, %d classes, %d angles · vue tournante dans l'Équipement · compagnons %s" % [races.size(), classes.size(), HeroModel.STEPS, HeroModel.COMPANIONS])
	return true


## Armurerie d'Aldric (docs/design/44-armurerie-cosmetiques.md) : arrivage toutes les 5 h (vitrine mythique
## 1 fois sur 8, épique ou légendaire 1 fois sur 6), achat à l'or, curiosités : kits de 4 pièces portées
## par-dessus l'équipement (bonus à 2 et à 4 pièces), panneau Apparence de l'Équipement.
func _armory_ok() -> bool:
	var errs: Array[String] = []
	var saved: Dictionary = Profile.data.duplicate(true)
	# Probabilités de la vitrine.
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	var n := 20000
	var cnt := {}
	for i in range(n):
		var r := Profile.shop_showcase_rarity(rng)
		cnt[r] = int(cnt.get(r, 0)) + 1
	var myth := float(cnt.get("mythique", 0)) / float(n)
	var high := float(int(cnt.get("epique", 0)) + int(cnt.get("legendaire", 0))) / float(n)
	if absf(myth - 0.125) > 0.01 or absf(high - 1.0 / 6.0) > 0.012 or int(cnt.get("rare", 0)) == 0:
		errs.append("vitrine : mythique %.3f, épique+légendaire %.3f" % [myth, high])
	# Arrivage : 7 offres (vitrine en tête), à l'or, sans uid ; même période → mêmes offres ; période suivante → nouvel arrivage.
	var now := 1.8e9
	Profile.data["shop"] = {"period": -1, "offers": []}
	var offers := Profile.shop_offers(now)
	var first := JSON.stringify(offers)
	if offers.size() != 7 or not bool(offers[0]["showcase"]) or str(offers[0]["item"]["uid"]) != "":
		errs.append("arrivage : %d offres" % offers.size())
	for o in offers:
		if int(o["price"]) <= 0 or int(o["price"]) % 5 != 0:
			errs.append("prix incorrect : %s" % o["price"])
	if JSON.stringify(Profile.shop_offers(now + 60.0)) != first:
		errs.append("l'arrivage change dans la même période")
	if JSON.stringify(Profile.shop_offers(now + Profile.shop_period_len())) == first:
		errs.append("pas de nouvel arrivage après 5 h")
	var left := Profile.shop_seconds_left(now)
	if left <= 0 or left > int(Profile.shop_period_len()):
		errs.append("compte à rebours : %d" % left)
	# Achat.
	Profile.data["gold"] = 0
	if Profile.shop_buy_block(1) != "Or insuffisant":
		errs.append("achat sans or accepté")
	var price := int(Profile.shop_offers(now + Profile.shop_period_len())[1]["price"])
	Profile.data["gold"] = price + 7
	var inv0 := (Profile.data["inventory"] as Array).size()
	var bought := Profile.shop_buy(1)
	if bought.is_empty() or Profile.gold() != 7 or (Profile.data["inventory"] as Array).size() != inv0 + 1 or str(bought["uid"]) == "" \
			or Profile.shop_buy_block(1) != "Déjà vendu":
		errs.append("achat d'équipement incorrect")
	# Curiosités : achat, port, bonus de kit.
	Profile.data["cosmetics"] = {"owned": [], "worn": {}, "show": true}
	var db := Profile.cosmetics_db()
	var kits: Dictionary = db["kits"]
	if kits.size() < 8:
		errs.append("%d kits seulement" % kits.size())
	for kit in kits.keys():
		if (kits[kit]["pieces"] as Dictionary).size() != 4:
			errs.append("kit %s incomplet" % kit)
	Profile.data["gold"] = 100000
	var p0 := Profile.power()
	var b0 := Profile.gear_stats_of("player").duplicate()
	for slot in ["tete", "tenue"]:
		if not Profile.buy_cosmetic("boulanger." + slot):
			errs.append("achat boulanger.%s refusé" % slot)
		Profile.wear_cosmetic(slot, "boulanger." + slot)
	if Profile.cosmetic_buy_block("boulanger.tete") != "Déjà à toi":
		errs.append("pièce achetée deux fois")
	var b2 := Profile.gear_stats_of("player")
	if int(b2.get("vig", 0)) - int(b0.get("vig", 0)) != 6 or Profile.power() <= p0 or Profile.all_mods().has("barrier_flat"):
		errs.append("bonus à 2 pièces : %s → %s" % [b0.get("vig", 0), b2.get("vig", 0)])
	for slot in ["dos", "arme"]:
		Profile.buy_cosmetic("boulanger." + slot)
		Profile.wear_cosmetic(slot, "boulanger." + slot)
	if absf(float(Profile.all_mods().get("barrier_flat", 0.0)) - 100.0) > 0.01:
		errs.append("bonus à 4 pièces absent")
	Profile.wear_cosmetic("tete", "corsaire.tete") # pas possédée : refusée
	if str(Profile.worn_cosmetics()["tete"]) != "boulanger.tete":
		errs.append("pièce non possédée portée")
	# Combat : la barrière gagne 100 points avec le kit complet.
	var mods_full := Profile.all_mods()
	Profile.wear_cosmetic("arme", "")
	var mods_3 := Profile.all_mods()
	var s1 := BattleSim.new()
	s1.setup(GameData.level("z01_l05"), GameData.party(), 11, {"solo": true, "mods": mods_full})
	var s0 := BattleSim.new()
	s0.setup(GameData.level("z01_l05"), GameData.party(), 11, {"solo": true, "mods": mods_3})
	if absf(s1.barrier_max - s0.barrier_max - 100.0) > 0.5:
		errs.append("barrière : %.0f contre %.0f" % [s1.barrier_max, s0.barrier_max])
	# Rendu : chaque kit change l'apparence, de face comme de dos.
	var look := {"head": PlayerLook.HEADS.keys()[0], "sil": 0, "face": 0}
	var plain := HeroModel.new()
	plain.build(look, "humain", "chevalier")
	for kit in kits.keys():
		var cos := {}
		for slot in db["slots"].keys():
			cos[slot] = "%s.%s" % [kit, slot]
		var m := HeroModel.new()
		m.build(look, "humain", "chevalier", cos)
		for yaw in [PI, 0.0]:
			var img := m.image_at(yaw)
			if img.get_used_rect().size.y < 22 or img.get_data() == plain.image_at(yaw).get_data():
				errs.append("kit %s : rendu inchangé (angle %.1f)" % [kit, yaw])
	# Écrans : Armurerie (deux onglets) et Apparence de l'Équipement.
	for tab in ["equip", "curios"]:
		var ar := ArmoryScreen.new()
		ar._tab = tab
		root.add_child(ar)
		await _frames(2)
		var btns := ar.find_children("*", "Button", true, false).size()
		if btns < 8:
			errs.append("Armurerie (%s) : %d boutons" % [tab, btns])
		if tab == "curios" and ar.find_children("*", "HeroTurntable", true, false).is_empty():
			errs.append("pas d'essayage dans les Curiosités")
		ar.queue_free()
	var es := EquipmentScreen.new()
	root.add_child(es)
	await _frames(2)
	var found := false
	for l in es.find_children("*", "Label", true, false):
		if (l as Label).text == "APPARENCE":
			found = true
	if not found:
		errs.append("pas de panneau Apparence dans l'Équipement")
	es.queue_free()
	Profile.data = saved
	if not errs.is_empty():
		push_error("armurerie : %s" % [errs])
		return false
	print("armurerie : vitrine mythique %.1f %%, épique/légendaire %.1f %% · arrivage de %d offres, renouvelé toutes les %d h · %d kits de curiosités, bonus 2/4 pièces · barrière +100 · Apparence" % [myth * 100.0, high * 100.0, offers.size(), int(Profile.shop_period_len() / 3600.0), kits.size()])
	return true


## Héros en volume animé (docs/design/45-heros-anime.md) : squelette et animations, éclairages de scène,
## équipement porté dessiné sur le modèle, création avec le héros qui tourne, carte du héros.
func _hero_rig_ok() -> bool:
	var errs: Array[String] = []
	var saved: Dictionary = Profile.data.duplicate(true)
	var look := {"head": "courts", "sil": 1, "face": 0}
	var plain := HeroModel.new()
	plain.build(look, "humain", "chevalier")
	var front := PI + 0.6
	# Animations : chaque image se rend, et les gestes bougent vraiment.
	var models := {"héros": plain, "brann": HeroModel.of_companion("brann", "chevalier"), "sylwen": HeroModel.of_companion("sylwen", "archer"),
		"krag": HeroModel.of_companion("krag", "berserker"), "nyx": HeroModel.of_companion("nyx", "necromancien"),
		"ignara": HeroModel.of_companion("ignara", "mage"), "ssareth": HeroModel.of_companion("ssareth", "clerc")}
	var rest := plain.frame_at(front, "", 0)
	for mk in models.keys():
		var m: HeroModel = models[mk]
		for an in HeroModel.ANIMS.keys():
			var seen := {}
			for f in range(int(HeroModel.ANIMS[an]["frames"])):
				var img := m.frame_at(front, str(an), f)
				if img.get_used_rect().size.y < 16:
					errs.append("%s %s %d : image vide" % [mk, an, f])
				seen[img.get_data().hex_encode().sha256_text()] = true
			if seen.size() < 2:
				errs.append("%s %s : aucune image ne bouge" % [mk, an])
	if plain.frame_at(front, "victory", 6).get_used_rect().position.y >= rest.get_used_rect().position.y:
		errs.append("victoire : l'arme n'est pas brandie au-dessus de la tête")
	# Éclairages.
	for lid in HeroModel.LIGHTS.keys():
		if str(lid) != "jour" and plain.frame_at(front, "", 0, str(lid)).get_data() == rest.get_data():
			errs.append("éclairage %s sans effet" % lid)
	# Équipement : chaque objet (sauf les anneaux) change l'allure du héros.
	var bases: Dictionary = Profile.items_db()["bases"]
	var plain_back := plain.frame_at(0.6, "", 0)
	var n_items := 0
	for b in bases.keys():
		var bd: Dictionary = bases[b]
		var slot := str(bd["slot"])
		if slot == "ring" or not bd.has("art"):
			continue
		var art: Dictionary = bd["art"]
		var g := {slot: {"t": str(art.get("t", "")), "m": str(art.get("m", "iron")), "c": str(art.get("c", "")), "g": str(art.get("g", "")), "r": "epique", "base": str(b)}}
		var m2 := HeroModel.new()
		m2.build(look, "humain", "chevalier", {}, g)
		n_items += 1
		if m2.frame_at(front, "", 0).get_data() == rest.get_data() and m2.frame_at(0.6, "", 0).get_data() == plain_back.get_data():
			errs.append("%s (%s) : invisible sur le héros" % [b, art.get("t", "")])
	# Profil : allure de l'équipement porté, casque masqué.
	Profile.data["inventory"] = []
	Profile.data["equipped"] = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for pk in [["heaume_cornu", "rare"], ["cuirasse_naine", "epique"], ["epee_ecuyer", "legendaire"]]:
		var it := Profile.make_item(str(pk[0]), str(pk[1]), 10, rng)
		(Profile.data["inventory"] as Array).append(it)
		Profile.equip(str(it["uid"]))
	var gl := Profile.gear_look()
	if not (gl.has("head") and gl.has("armor") and gl.has("weapon")) or str(gl["armor"]["r"]) != "epique":
		errs.append("allure de l'équipement : %s" % [gl.keys()])
	Profile.set_helmet_shown(false)
	if Profile.gear_look().has("head"):
		errs.append("casque masqué toujours dessiné")
	Profile.set_helmet_shown(true)
	# Vue tournante : un geste joué revient au repos.
	var tt := HeroTurntable.new()
	root.add_child(tt)
	tt.setup(Profile.look(), Profile.race(), Profile.player_class(), {}, Profile.gear_look())
	tt.play("cast")
	for i in range(40):
		tt._process(0.1)
	if tt.current_anim() != "idle":
		errs.append("après un sort, la vue tournante reste sur %s" % tt.current_anim())
	tt.queue_free()
	# Écrans : Équipement (poses, lumière, carte), création, carte du héros.
	var es := EquipmentScreen.new()
	root.add_child(es)
	await _frames(2)
	var labels: Array[String] = []
	for bt in es.find_children("*", "Button", true, false):
		labels.append((bt as Button).text)
	for want in ["Victoire", "Sort", "Marche", "Feu de camp", "Carte du héros", "Casque visible"]:
		if not labels.has(want):
			errs.append("Équipement : bouton « %s » absent" % want)
	var hc: HeroCard = es.open_card()
	await _frames(2)
	if hc._card == null or hc._card.find_children("*", "TextureRect", true, false).size() < 4:
		errs.append("carte du héros incomplète")
	es.queue_free()
	var cs := CreationScreen.new()
	root.add_child(cs)
	await _frames(2)
	if cs.find_children("*", "HeroTurntable", true, false).is_empty():
		errs.append("pas de héros qui tourne à la création")
	cs.queue_free()
	Profile.data = saved
	if not errs.is_empty():
		push_error("héros animé : %s" % [errs])
		return false
	print("héros animé : %d animations (héros, Brann, Sylwen) · %d éclairages · %d objets visibles sur le héros · casque masquable · création et carte du héros" % [HeroModel.ANIMS.size(), HeroModel.LIGHTS.size(), n_items])
	return true


## Les personnages en volume partout (docs/design/45-heros-anime.md, § 8 à 12) : en combat, au Cercle autour du
## feu, sur la carte (le héros marche d'un niveau à l'autre) et dans les cinématiques (la troupe en pied).
func _troupe_ok() -> bool:
	var errs: Array[String] = []
	# Combat : le héros et chaque compagnon ont leur modèle ; un sort le tourne vers sa cible ; la victoire le
	# retourne vers nous.
	for who in ["player"] + HeroModel.COMPANIONS:
		var cv := CasterVox.for_caster(str(who), "chevalier")
		if cv == null or cv.tex == null or cv.rest_h < 12.0:
			errs.append("combat : pas de modèle pour %s" % who)
	var cv2 := CasterVox.for_caster("player", Profile.player_class())
	cv2.cast_at(4.5, 8.5)
	for i in range(12):
		cv2.step(0.05, 0.0, false)
	if cv2.yaw <= 0.2:
		errs.append("combat : le lanceur ne se tourne pas vers sa cible (%.2f)" % cv2.yaw)
	cv2.finish(true)
	for i in range(80):
		cv2.step(0.05, 0.0, false)
	if absf(cv2.yaw - PI) > 0.3 or cv2._forced != "victory":
		errs.append("combat : victoire mal jouée (%.2f, %s)" % [cv2.yaw, cv2._forced])
	var cv3 := CasterVox.for_caster("player", Profile.player_class())
	for i in range(6):
		cv3.step(0.05, 0.02, false)
	if cv3.yaw <= 0.1 or cv3._anim != "walk":
		errs.append("combat : se déplacer ne le tourne pas (%.2f, %s)" % [cv3.yaw, cv3._anim])
	# Le Cercle : les trois personnages en volume autour du feu.
	var cs := CircleScreen.new()
	root.add_child(cs)
	await _frames(2)
	var figs := cs.find_children("*", "HeroTurntable", true, false)
	if figs.size() < 2:
		errs.append("Cercle : %d personnage(s) en volume" % figs.size())
	for f in figs:
		if (f as HeroTurntable).light != "camp" or (f as HeroTurntable).interactive:
			errs.append("Cercle : personnage mal éclairé ou interactif")
			break
	cs.queue_free()
	# La carte : le héros attend au prochain niveau, puis marche vers celui qu'on choisit.
	var saved_levels: Dictionary = (Profile.data["levels"] as Dictionary).duplicate(true)
	var ids: Array = GameData.level_index()["zones"][0]["levels"]
	for k in range(4):
		Profile.data["levels"][str(ids[k])] = {"stars": 2, "best": 100.0, "clears": 1}
	var m := MapScreen.new()
	m.zone = 1
	root.add_child(m)
	await _frames(3)
	var board: MapBoard = m._board
	if not (board._hero is HeroTurntable):
		errs.append("carte : pas de héros en volume")
	else:
		var start := board._hero_i
		board.select(str(ids[1]))
		var walking := not board._walk.is_empty()
		for i in range(400):
			if board._walk.is_empty():
				break
			board._process(0.05)
		if not walking or board._hero_i != 1 or start == 1:
			errs.append("carte : le héros ne marche pas jusqu'au niveau choisi (%s, %d → %d)" % [walking, start, board._hero_i])
	m.queue_free()
	Profile.data["levels"] = saved_levels
	# Cinématiques : la troupe en pied, tournée vers celui qui parle, qui fait les gestes de la scène.
	var st := CineStage.new()
	st.size = Vector2(720, 1280)
	st.ground_y = 1000.0
	root.add_child(st)
	await _frames(1)
	st.begin_scene({"cast": ["porteur", "brann"]})
	st.speak("brann", "neutre")
	st.speak("sylwen", "joie")
	await _frames(2)
	if st._troupe.size() != 3 or not st._troupe.has("porteur"):
		errs.append("cinématique : troupe %s" % [st._troupe.keys()])
	else:
		st._act("brann", "cast")
		if (st._troupe["brann"] as HeroTurntable).current_anim() != "cast":
			errs.append("cinématique : le geste n'est pas joué")
		for i in range(30):
			st._process(0.05)
		var hero: HeroTurntable = st._troupe["porteur"]
		if hero.px_scale < 2 or hero.position.y > st.ground_y:
			errs.append("cinématique : troupe mal placée")
	st.queue_free()
	if not errs.is_empty():
		push_error("personnages en volume : %s" % [errs])
		return false
	print("personnages en volume : %d compagnons en volume · combat (se tourne, lance, célèbre) · Cercle autour du feu · marche sur la carte · troupe des cinématiques" % HeroModel.COMPANIONS.size())
	return true


## Les gestes de Durgan à la Forge (docs/design/46-forge-animee.md) : la fusion (lunettes, trois objets posés sur
## l'enclume, trois coups de marteau, l'objet né de la fusion) et la gravure (l'objet, la rune choisie, les coups de
## burin, le glyphe allumé), lancées par les vrais boutons de la Forge, jouées jusqu'au bout ou passées.
func _forge_scene_ok() -> bool:
	var errs: Array[String] = []
	var saved: Dictionary = Profile.data.duplicate(true)
	# Durgan en volume : lunettes relevées, puis rabattues sur les yeux.
	var dm := HeroModel.new()
	dm.build_companion("durgan", "")
	var up := dm.frame_pose(PI, "t_up", ForgeScene.dpose("rest", 0.0), "forge")
	var down := dm.frame_pose(PI, "t_down", ForgeScene.dpose("rest", 1.0), "forge")
	if up.get_used_rect().size.y < 16 or up.get_data() == down.get_data():
		errs.append("Durgan : modèle ou lunettes incorrects")
	var hi := dm.project(PI, ForgeScene.dpose("raise", 1.0), "wpnR", ForgeScene.HAMMER)
	var lo := dm.project(PI, ForgeScene.dpose("strike", 1.0), "wpnR", ForgeScene.HAMMER)
	if hi.y >= lo.y:
		errs.append("Durgan : le marteau ne s'abat pas (%s → %s)" % [hi, lo])
	# Les objets et la rune en volume, d'après leurs icônes.
	var icon := HeroModel.from_icon((ItemArt.rune("pyr", 3, ItemArt.S) as ImageTexture).get_image())
	if icon.frame_at(0.0, "", 0, "forge").get_used_rect().size.x < 14:
		errs.append("rune en volume vide")
	# Lunettes : enfilées à deux mains avant le travail, gardées pendant tout le travail, remontées à la fin.
	for kind2 in ["fusion", "gravure"]:
		var probe := ForgeScene.new()
		probe.mode = kind2
		probe.items = [{}, {}, {}]
		probe._build_steps()
		var names: Array = []
		var work_g := 1.0
		for st in probe._steps:
			names.append(str(st["pose"]))
			if str(st["pose"]) in ["strike", "eng_a", "eng_b", "place"]:
				work_g = minf(work_g, float(st["g"]))
		var first_work := names.find("reach0")
		if names.find("g2_up") < 0 or names.find("g2_up") > first_work or work_g < 1.0 or float(probe._steps[-1]["g"]) != 0.0 or names.find("gup2") < first_work:
			errs.append("%s : lunettes mal mises, ôtées pendant le travail ou pas remontées" % kind2)
		var two := ForgeScene.dpose("g2_up", 0.0, false)
		if not (two.has("armL") and two.has("armR") and (two["armR"][0] as Vector3).x > 120.0):
			errs.append("lunettes : pas à deux mains")
		probe.free()
	# Les deux scènes jouées jusqu'au bout.
	var fs := ForgeScreen.new()
	root.add_child(fs)
	await _frames(1)
	for kind in ["fusion", "gravure"]:
		var sc := fs.demo_scene(kind)
		sc.size = Vector2(720, 1280)
		await _frames(1)
		var steps := 0
		for i in range(400):
			sc._process(0.05)
			steps = maxi(steps, sc._si)
			if sc._done:
				break
		if not sc._done or steps < 10:
			errs.append("%s : scène inachevée (%d étapes)" % [kind, steps])
		if kind == "fusion" and not bool(sc._props["out"]["vis"]):
			errs.append("fusion : l'objet né de la fusion n'apparaît pas")
		if kind == "gravure" and (sc._emblem <= 0.0 or bool(sc._props["rune"]["vis"])):
			errs.append("gravure : le glyphe ne s'allume pas sur l'objet")
		sc.queue_free()
	# Passer la scène : l'état final tout de suite.
	var sk := fs.demo_scene("fusion")
	sk.size = Vector2(720, 1280)
	await _frames(1)
	sk.skip()
	if not sk._done or not bool(sk._props["out"]["vis"]):
		errs.append("passer la fusion ne montre pas le résultat")
	sk.queue_free()
	# Les vrais boutons : FUSIONNER et la gravure lancent la scène.
	Profile.data["gold"] = 1000000
	Profile.data["inventory"] = []
	Profile.data["equipped"] = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var uids: Array[String] = []
	for b in ["epee_ecuyer", "lame_verre", "rapiere_aube", "baton_chene"]:
		var it := Profile.make_item(str(b), "rare", 20, rng)
		(Profile.data["inventory"] as Array).append(it)
		uids.append(str(it["uid"]))
	fs.tab = "fusion"
	fs._sel.assign(uids.slice(0, 3))
	fs._rebuild()
	await _frames(1)
	for bt in fs.find_children("*", "Button", true, false):
		if (bt as Button).text.begins_with("FUSIONNER") and not (bt as Button).disabled:
			(bt as Button).pressed.emit()
			break
	await _frames(1)
	if fs.find_children("*", "ForgeScene", false, false).is_empty():
		errs.append("FUSIONNER ne lance pas la scène de Durgan")
	for c in fs.find_children("*", "ForgeScene", false, false):
		c.queue_free()
	var r := Profile.make_rune("isa", 2, "rare")
	Profile.rune_inventory().append(r)
	fs.tab = "gravure"
	fs.focus_item = uids[3]
	fs._rune_pick = str(r["uid"])
	fs._engrave(Profile.find_item(uids[3]), "weapon")
	await _frames(1)
	var gs := fs.find_children("*", "ForgeScene", false, false)
	if gs.is_empty() or str((gs[0] as ForgeScene).rune.get("rune", "")) != "isa":
		errs.append("la gravure ne lance pas la scène avec la rune choisie")
	fs.queue_free()
	Profile.data = saved
	if not errs.is_empty():
		push_error("forge animée : %s" % [errs])
		return false
	print("forge animée : Durgan en volume (lunettes, marteau) · fusion et gravure jouées jusqu'au bout, passables, lancées par les boutons de la Forge avec la rune choisie")
	return true


## Défis et hauts faits (doc 47), Tour des Échos (doc 48).
func _quests_tower_ok() -> bool:
	var errs: Array[String] = []
	var saved: Dictionary = Profile.data.duplicate(true)
	Profile.data["quests"] = {}
	# Défis : 3 du jour et 2 de la semaine, stables dans la période, renouvelés à la suivante.
	var now := 1.8e9
	var qs := Profile.quests(now)
	var first := JSON.stringify(qs["daily"])
	if (qs["daily"] as Array).size() != 3 or (qs["weekly"] as Array).size() != 2:
		errs.append("défis : %d du jour, %d de la semaine" % [(qs["daily"] as Array).size(), (qs["weekly"] as Array).size()])
	if JSON.stringify(Profile.quests(now + 60.0)["daily"]) != first:
		errs.append("défis du jour changés dans la journée")
	Profile.quests(now + 86400.0 * 3.0)
	# Un défi « remporte N combats » avance avec les combats, se réclame une fois.
	Profile.data["quests"] = {"day": Profile.quest_day(), "daily": [{"id": "d_wins", "p": 0, "claimed": false}, {"id": "d_kills", "p": 0, "claimed": false}, {"id": "d_spells", "p": 0, "claimed": false}],
		"week": Profile.quest_week(), "weekly": [{"id": "w_wins", "p": 0, "claimed": false}, {"id": "w_spells", "p": 0, "claimed": false}]}
	var g0 := Profile.gold()
	for i in range(3):
		Profile.record_battle("z01_l01", true, {"kills": 60, "spells": 15, "elems": {"feu": 15}, "barrier_low": 0.9, "stars": 3, "gold": 50})
	var d: Array = Profile.quests()["daily"]
	if not (Profile.quest_done(d[0]) and Profile.quest_done(d[1]) and Profile.quest_done(d[2])):
		errs.append("défis : progression %s" % [d])
	if Profile.quests_claimable() < 3:
		errs.append("défis : %d à réclamer" % Profile.quests_claimable())
	var got := Profile.claim_quest(false, 0)
	if got.is_empty() or Profile.gold() <= g0 or not Profile.claim_quest(false, 0).is_empty():
		errs.append("défis : réclamer incorrect")
	# Hauts faits : « Premiers pas » débloqué, titre porté.
	if not Profile.achievement_unlocked("premiers_pas"):
		errs.append("haut fait « Premiers pas » non débloqué")
	Profile.set_title("premiers_pas")
	if Profile.title() != "Apprenti canalisateur":
		errs.append("titre : %s" % Profile.title())
	Profile.set_title("legende")
	if Profile.title() != "Apprenti canalisateur":
		errs.append("titre d'un haut fait verrouillé accepté")
	# Tour des Échos : étages composés, boss tous les 10, bonus, défaite qui clôt l'ascension.
	Profile.data["levels"]["z01_l10"] = {"stars": 1, "best": 200.0, "clears": 1}
	Profile.tower_start()
	var run := Profile.tower_run()
	var l1 := Profile.tower_level(1, int(run["seed"]))
	var l5 := Profile.tower_level(5, int(run["seed"]))
	var l10 := Profile.tower_level(10, int(run["seed"]))
	var l30 := Profile.tower_level(30, int(run["seed"]))
	if str(l10.get("objective", "")) != "boss" or str(l5.get("type", "")) != "Mini-boss" or l1.has("story_mods") or str(l1.get("type", "")) in ["Boss", "Mini-boss", "Escorte"]:
		errs.append("tour : étages mal composés (%s, %s, %s)" % [l1.get("type"), l5.get("type"), l10.get("type")])
	if l30.has("nexus") and l1.has("nexus") and float(l30["nexus"]["hp"]) <= float(GameData.level(str(l30["decor_id"]))["nexus"]["hp"]):
		errs.append("tour : pas de renforcement")
	var r1 := Profile.tower_floor_done(true)
	if int(r1.get("gold", 0)) <= 0 or int(Profile.tower_run()["floor"]) != 2 or (Profile.tower_run()["choice"] as Array).size() != 3:
		errs.append("tour : victoire d'étage incorrecte")
	var boon := str(Profile.tower_run()["choice"][0])
	Profile.tower_pick_boon(boon)
	var mods := Profile.tower_opts(2)["mods"] as Dictionary
	var bm: Dictionary = Profile.tower_boon(boon)["mods"]
	var mk := str(bm.keys()[0])
	if float(mods.get(mk, 0.0)) < float(bm[mk]) - 0.001:
		errs.append("tour : bonus non appliqué (%s)" % boon)
	Profile.tower_floor_done(false)
	if not Profile.tower_run().is_empty() or Profile.tower_best() != 1:
		errs.append("tour : la défaite ne clôt pas l'ascension (record %d)" % Profile.tower_best())
	# Un étage se joue : le combat accepte un niveau composé.
	Profile.tower_start()
	var o := Profile.tower_opts(1)
	o["level_data"] = Profile.tower_level(1, int(Profile.tower_run()["seed"]))
	var bs := BattleScreen.new()
	bs.configure("tour", false, o)
	root.add_child(bs)
	await _frames(3)
	if bs.sim == null or str(bs._level.get("id", "")) != "tour_1":
		errs.append("tour : l'étage ne se lance pas")
	bs.queue_free()
	await _frames(1)
	Profile.tower_abandon()
	# Écrans.
	var qsc := QuestsScreen.new()
	root.add_child(qsc)
	await _frames(1)
	qsc.tab = "hauts"
	qsc._rebuild()
	await _frames(1)
	if qsc.find_children("*", "Button", true, false).size() < 20:
		errs.append("écran des hauts faits incomplet")
	qsc.queue_free()
	var tsc := TowerScreen.new()
	root.add_child(tsc)
	await _frames(2)
	var labels: Array[String] = []
	for bt in tsc.find_children("*", "Button", true, false):
		labels.append((bt as Button).text)
	if not labels.has("COMMENCER L'ASCENSION"):
		errs.append("Tour : pas de bouton pour commencer (%s)" % [labels])
	tsc.queue_free()
	Profile.data = saved
	if not errs.is_empty():
		push_error("défis, tour : %s" % [errs])
		return false
	print("défis et hauts faits (3 du jour, 2 de la semaine, titres) · Tour des Échos (étages, boss, bonus, record)")
	return true


## Babillage à la « Animal Crossing » (docs/design/43-audio.md) : une syllabe par lettre (un même mot sonne pareil),
## débit vif pour les gens, lent pour les grandes créatures, bouche au rythme des syllabes, bandes de 22 syllabes.
func _babble_ok() -> bool:
	var errs: Array[String] = []
	if VoiceBabble.syllable_of("b") != 5 or VoiceBabble.syllable_of("É") != 1 or VoiceBabble.syllable_of(" ") != -1 or VoiceBabble.syllable_of("!") != -1:
		errs.append("lettres -> syllabes incorrectes")
	var counts := {}
	for who in ["brann", "cerf"]:
		var before := Snd.played().size()
		var b := VoiceBabble.new()
		b.start(who, "neutre", "Bonjour, voyageur ! Tu viens de loin ?")
		var shown := 0.0
		var mouths := {}
		for i in range(60):
			shown += 0.05 * 45.0
			b.tick(0.05, int(shown))
			mouths[b.mouth()] = true
		var got: Array = Snd.played().slice(before)
		var n := 0
		for name in got:
			if str(name).begins_with("voice/%s_" % who):
				n += 1
		counts[who] = n
		if who == "brann" and mouths.size() < 2:
			errs.append("la bouche ne suit pas les syllabes")
	if int(counts.get("brann", 0)) < 8 or int(counts.get("cerf", 0)) >= int(counts.get("brann", 0)):
		errs.append("débits : %s" % [counts])
	for v in VoiceBabble.VOICES:
		var st: AudioStream = load("res://assets/audio/voice/%s.ogg" % v)
		if st == null or st.get_length() < float(VoiceBabble.N_SYL) * 0.22 - 0.15:
			errs.append("bande de voix %s trop courte" % v)
	if not errs.is_empty():
		push_error("babillage : %s" % [errs])
		return false
	print("babillage : une syllabe par lettre · %d syllabes chez Brann, %d chez le Grand Cerf pour la même réplique · %d voix" % [int(counts["brann"]), int(counts["cerf"]), VoiceBabble.VOICES.size()])
	return true


## Carte du monde : un médaillon par niveau, toucher un niveau le choisit, JOUER le lance.
func _map_ok() -> bool:
	var m := MapScreen.new()
	m.zone = 1
	root.add_child(m)
	await _frames(3)
	var board: MapBoard = m._board
	var ok1 := board != null and board._medals.size() == m._ids.size() and m._ids.size() >= 10 and board.size.y > 1500.0
	var got: Array[String] = [""]
	m.play.connect(func(id: String, _solo: bool) -> void: got[0] = id)
	var target := str(m._ids[0])
	(board._medals[target] as MapBoard.Medal).pressed.emit()
	await _frames(1)
	var ok2 := m.selected == target and board.selected == target
	for b in m.find_children("*", "Button", true, false):
		if (b as Button).text in ["JOUER", "REJOUER"] and not (b as Button).disabled:
			(b as Button).pressed.emit()
			break
	var ok3 := got[0] == target
	# Changer de zone reconstruit la carte avec les niveaux de la zone.
	m.zone = 2
	m.selected = ""
	m._build()
	await _frames(2)
	var ok4 := str(m._ids[0]) == "z02_l01" and m._board.zone == 2
	m.queue_free()
	if not (ok1 and ok2 and ok3 and ok4):
		push_error("carte : %s %s %s %s" % [ok1, ok2, ok3, ok4])
		return false
	print("carte : %d médaillons, choix et JOUER" % m._ids.size())
	return true


func _compare_ok() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var inv: Array = Profile.data["inventory"]
	var eq: Dictionary = Profile.equipment_of("player")
	var saved_eq := eq.duplicate()
	var weak := Profile.make_item("bottes_marche", "commun", 2, rng)
	var strong := Profile.make_item("bottes_marche", "legendaire", 40, rng)
	var worse := Profile.make_item("bottes_marche", "commun", 1, rng)
	inv.append_array([weak, strong, worse])
	var feet_slot := str(Profile.base_of(weak).get("slot", ""))
	eq[feet_slot] = str(weak["uid"])
	var c_strong := Profile.compare_to_equipped("player", strong)
	var c_worse := Profile.compare_to_equipped("player", worse)
	var ok1 := bool(c_strong["better"]) and int(c_strong["power"]) > 0 and str(c_strong["vs"]) == str(weak["uid"]) \
		and not bool(c_worse["better"]) and Profile.better_items("player").has(strong)
	# Anneaux : avec deux anneaux portés, c'est le plus faible qui est comparé puis remplacé.
	var r_lo := Profile.make_item("anneau_cuivre", "commun", 2, rng)
	var r_hi := Profile.make_item("anneau_cuivre", "legendaire", 40, rng)
	var r_new := Profile.make_item("anneau_cuivre", "epique", 30, rng)
	inv.append_array([r_lo, r_hi, r_new])
	eq["ring1"] = str(r_hi["uid"])
	eq["ring2"] = str(r_lo["uid"])
	var c_ring := Profile.compare_to_equipped("player", r_new)
	Profile.equip_to("player", str(r_new["uid"]))
	var ok2 := bool(c_ring["better"]) and str(c_ring["vs"]) == str(r_lo["uid"]) and str(eq["ring1"]) == str(r_hi["uid"]) and str(eq["ring2"]) == str(r_new["uid"])
	# Écran : le meilleur objet en tête de l'inventaire, avec son bandeau.
	eq["ring2"] = str(r_lo["uid"])
	var gold0 := Profile.gold()
	Profile.data["gold"] = gold0 + 100000
	var es := EquipmentScreen.new()
	root.add_child(es)
	await _frames(2)
	var ok3 := es._better_by_slot.get(EquipmentScreen._slot_key(feet_slot), 0) as int >= 1 and bool(es._cmp[str(strong["uid"])]["better"])
	# Améliorer un objet porté sans le retirer : le bouton est sur la ligne de l'objet équipé.
	var up0 := int(weak.get("up", 0))
	var p0 := Profile.power()
	var up_btn: Button = null
	es._sel = "slot:" + feet_slot ## la fiche montre l'emplacement choisi
	es._rebuild()
	await _frames(2)
	for b in es.find_children("*", "Button", true, false):
		if str((b as Button).get_meta("uid", "")) == str(weak["uid"]) and not (b as Button).disabled:
			up_btn = b
			break
	var found := up_btn != null
	if found:
		up_btn.pressed.emit() ## l'écran se reconstruit : le bouton est libéré
		await _frames(2)
	var ok4 := found and int(weak.get("up", 0)) == up0 + 1 and str(eq.get(feet_slot, "")) == str(weak["uid"]) and Profile.power() >= p0
	Profile.data["gold"] = gold0
	es.queue_free()
	for it in [weak, strong, worse, r_lo, r_hi, r_new]:
		inv.erase(it)
	eq.clear()
	for k in saved_eq.keys():
		eq[k] = saved_eq[k]
	print("comparaison : bottes meilleures %s · anneau le plus faible remplacé %s · écran %s · amélioration sans retirer %s" % [ok1, ok2, ok3, ok4])
	if not (ok1 and ok2 and ok3 and ok4):
		push_error("comparaison avec l'équipé incorrecte")
		return false
	return true


## Zone 6 · Forêt Cendrée : incendies (avancée, brûlure, Givre), dragons, envol, phénix, œufs, flaques de magma.
func _zone6_ok() -> bool:
	var errs: Array[String] = []
	for k in ["ember_imp", "salamander", "drakonid", "wyvernling", "magma_golem", "wyrm_cultist", "minor_phoenix", "ash_demon",
			"dragon_egg", "ancient_drake", "ash_wyrm", "refugee_convoy"]:
		if SpriteAtlas.single(k) == null:
			errs.append("sprite %s" % k)
	var ids: Array = GameData.level_index()["levels"]
	for i in range(1, 11):
		if not ids.has("z06_l%02d" % i):
			errs.append("niveau z06_l%02d absent de l'index" % i)
	if (Profile.items_db()["loot_pool"] as Dictionary).get("6", []).size() != 36:
		errs.append("butin de zone 6")
	# Incendie : il descend vers la Barrière, brûle une invocation, épargne un ennemi de Feu ; le Givre le fait reculer.
	var s := BattleSim.new()
	s.setup(GameData.level("z06_l02"), GameData.party(), 3, {"solo": true})
	s.start_wildfire(4.5)
	var f: Dictionary = s.fires.back()
	var front0 := float(f["front"])
	for k in range(int(10.0 / BattleSim.TICK)):
		s._update_fires()
	var advanced := float(f["front"]) < front0 - 3.0
	var a := s._spawn_familiar(s.player(), Vector2(4.5, float(f["front"]) + 0.5))
	var imp := s._spawn_enemy("ember_imp", Vector2(4.5, float(f["front"]) + 1.0))
	var golem := s._spawn_enemy("drakonid", Vector2(4.6, float(f["front"]) + 1.2))
	s._flush()
	var ah := a.hp
	var ih := imp.hp
	var gh := golem.hp
	for k in range(int(0.5 / BattleSim.TICK)):
		s._update_fires()
	var burns := a.hp < ah and is_equal_approx(imp.hp, ih) and golem.hp < gh
	var cut_y := float(f["front"]) + 2.0
	var hit := s.extinguish(Vector2(4.5, cut_y - 1.0), 1.0)
	var pushed := hit and float(f["front"]) >= cut_y - 0.01 and float(f["stall"]) > 0.0
	if not (advanced and burns and pushed):
		errs.append("incendie avance %s, brûle %s, Givre %s" % [advanced, burns, pushed])
	# Le Givre lancé par un sort éteint un foyer posé (impact sur le terrain).
	s.add_fire_patch(Vector2(2.0, 6.0), 0.7, 6.0)
	var nf := s.fires.size()
	s.terrain.on_impact(s.player(), {"element": "givre", "type": "aoe"}, Vector2(2.0, 6.0), 1.2, 30.0)
	if s.fires.size() != nf - 1:
		errs.append("Givre sur un foyer : %d -> %d" % [nf, s.fires.size()])
	s.terrain.sim = null
	# Dragon : rangée annoncée, puis foyers laissés sur la rangée.
	var d := BattleSim.new()
	d.setup(GameData.level("z06_l03"), GameData.party(), 4, {"solo": true})
	d.dragon_t = 0.0
	d._update_dragons()
	var tg_ok := d.telegraphs.size() == 1 and bool(d.telegraphs[0].get("dragon", false))
	d.telegraphs[0]["t"] = 0.0
	var before := d.fires.size()
	d._update_telegraphs()
	if not tg_ok or d.fires.size() != before + 2:
		errs.append("dragon annonce %s, foyers %d" % [tg_ok, d.fires.size() - before])
	# Phénix : renaît une fois, sauf si le Givre l'a frappé en dernier ; œuf qui éclot ; flaque du Golem de magma.
	var ph := d._spawn_enemy("minor_phoenix", Vector2(3.0, 12.0))
	var ph2 := d._spawn_enemy("minor_phoenix", Vector2(6.0, 12.0))
	var mg := d._spawn_enemy("magma_golem", Vector2(4.5, 9.0))
	var egg := d._spawn_enemy("dragon_egg", Vector2(4.5, 12.0))
	d._flush()
	d._damage(ph, ph.hp + 1.0, "feu")
	var reborn := ph.alive and ph.reborn
	d._damage(ph, ph.hp + 1.0, "feu")
	var dead_after := not ph.alive
	d._damage(ph2, ph2.hp + 1.0, "givre")
	var frost_kill := not ph2.alive
	var f0 := d.fires.size()
	d._damage(mg, mg.hp + 1.0, "givre")
	var pool := d.fires.size() == f0 + 1
	var n_wyv := 0
	egg.cast_cd = 0.0
	d._enemy_abilities()
	d._flush()
	for e in d.enemies:
		if e.alive and e.kind == "wyvernling":
			n_wyv += 1
	if not (reborn and dead_after and frost_kill and pool and not egg.alive and n_wyv == 2):
		errs.append("phénix %s/%s/%s, flaque %s, œuf %s (%d wyverneaux)" % [reborn, dead_after, frost_kill, pool, not egg.alive, n_wyv])
	d.terrain.sim = null
	# Envol : les invocations au corps à corps attendent sous le boss ; un sort le touche.
	var b := BattleSim.new()
	b.setup(GameData.level("z06_l05"), GameData.party(), 5, {"solo": true})
	b._flush()
	b._boss_ability({"type": "take_off", "dur": 5.0})
	var u := b._spawn_familiar(b.player(), b.boss.pos - Vector2(0.0, 0.3))
	b._flush()
	b._build_grids()
	var bh := b.boss.hp
	b._resolve_contacts()
	var waits := u.alive and u.engaged and is_equal_approx(b.boss.hp, bh)
	b._damage(b.boss, 100.0, "givre")
	var spell_hits := b.boss.hp < bh
	for k in range(int(5.2 / BattleSim.TICK)):
		b._update_boss()
	var landed := b.boss.airborne_t <= 0.0
	b._build_grids()
	var bh2 := b.boss.hp
	b._resolve_contacts()
	if not (waits and spell_hits and landed and b.boss.hp < bh2):
		errs.append("envol attente %s, sort %s, posé %s, coup après %s" % [waits, spell_hits, landed, b.boss.hp < bh2])
	b._boss_ability({"type": "eggs", "count": 3})
	b._flush()
	var eggs := 0
	for e in b.enemies:
		if e.alive and e.kind == "dragon_egg":
			eggs += 1
	if eggs != 3:
		errs.append("œufs du Wyrm : %d" % eggs)
	b.terrain.sim = null
	if not errs.is_empty():
		push_error("zone 6 : " + " · ".join(errs))
		return false
	print("zone 6 : incendies, Givre, dragons, phénix, œufs, envol OK")
	return true


## Acte 6 : scènes, portraits, planches ; la Marque du Wyrm (choix du traître, résistance, combat, épargné ou achevé),
## la quête de rédemption et l'Héritage de cendre, l'exil ; les choix 6-7 et 6-9 devant le Wyrm.
func _act6_ok() -> bool:
	var errs: Array[String] = []
	for n in range(1, 11):
		for part in ["intro", "outro"]:
			if not Dialogues.has_scene("z06_l%02d_%s" % [n, part]):
				errs.append("scène z06_l%02d_%s" % [n, part])
	for sid in ["z06_r01_intro", "z06_r01_outro"]:
		if not Dialogues.has_scene(sid):
			errs.append("scène " + sid)
	for who in ["ignara", "mere_dragon", "wyrm"]:
		for mood in ["neutre", "joie", "triste", "colere", "surpris"]:
			if PortraitArt.texture(who, mood) == null:
				errs.append("portrait %s/%s" % [who, mood])
	for kind in ["cendres", "coulee", "braisemont", "nid", "autels", "citadelle", "caldeira", "antre"]:
		if StoryArt.plate(kind, Vector2i(320, 180)) == null:
			errs.append("planche " + kind)
	for spr in ["ignara", "brann_cendre", "sylwen_cendre", "krag_cendre", "nyx_cendre", "wyrm_mark"]:
		if SpriteAtlas.single(spr) == null:
			errs.append("sprite " + spr)
	var saved: Dictionary = (Story.st() as Dictionary).duplicate(true)
	var st: Dictionary = Story.st()
	for f in ["s1.acte6_marque", "s1.traitre", "s1.trahison", "s1.marque_resistee", "s1.traitre_krag", "s1.quete_pardon", "s1.redemption_krag", "s1.heritage_krag", "s1.exile_krag", "s1.mort_krag"]:
		Story.set_flag(f, false)
	st.erase("traitor")
	Story.set_flag("s1.krag_allie")
	Story.set_flag("s1.nyx_allie")
	st["loyalty"]["krag"] = 20
	st["loyalty"]["sylwen"] = 22
	st["loyalty"]["brann"] = 50
	st["loyalty"]["nyx"] = 60
	# Le plus bas sous 25 porte la Marque (Krag 20 plutôt que Sylwen 22).
	Story.apply({"traitor_check": true})
	if Story.traitor() != "krag" or not Story.has_flag("s1.traitre_krag"):
		errs.append("traître choisi : %s" % Story.traitor())
	# Loyauté remontée à 40 : il résiste à la Marque.
	st["loyalty"]["krag"] = 42
	Story.apply({"betrayal": true})
	var resisted := Story.has_flag("s1.marque_resistee") and not Story.has_flag("s1.trahison") and not Story.companion_lost("krag")
	Story.set_flag("s1.marque_resistee", false)
	Story.set_flag("s1.traitre")
	st["loyalty"]["krag"] = 20
	Story.apply({"betrayal": true})
	var betrayed := Story.has_flag("s1.trahison") and Story.companion_lost("krag") and not Profile.companions_available().has("krag")
	if not resisted or not betrayed:
		errs.append("Marque : résiste %s, trahit %s" % [resisted, betrayed])
	# Combat contre le Wyrm : Krag absent du groupe, puis à côté du Wyrm en phase 3.
	var fl: Array = ["s1.krag_allie", "s1.nyx_allie", "s1.ignara_allie", "s1.trahison", "s1.traitre", "s1.traitre_krag", "s1.phenix_epargne", "s1.pacte_dragons"]
	var w := BattleSim.new()
	w.setup(GameData.level("z06_l10"), GameData.party(), 4, {"flags": fl, "active": ["krag", "sylwen"]})
	w._flush()
	var ids: Array[String] = []
	for c in w.casters:
		ids.append(c.id)
	var mods_ok := w.barrier_shield >= 30.0 and w.boss.hp <= w.boss.max_hp * 0.86
	w._enter_phase(2)
	w._flush()
	var tu := w.traitor_unit
	if ids.has("krag") or tu == null or tu.sprite != "krag_cendre" or not mods_ok:
		errs.append("Wyrm : groupe %s, traître %s, bouclier/PV %s" % [ids, tu != null, mods_ok])
	else:
		w._damage(tu, tu.hp + 50.0, "physique")
		var broken := tu.alive and w.traitor_broken
		w._damage(tu, 999.0, "physique")
		w._sid = "souffle_draconique"
		w._sid_owner = 1
		w._damage(tu, 999.0, "feu")
		var bots_spare := tu.alive
		w._sid = "boule_de_feu"
		w._sid_owner = 0
		w._damage(tu, 10.0, "feu")
		w._sid = ""
		var killed := not tu.alive and w.traitor_killed
		w.boss.alive = false
		w._check_end()
		if not (broken and bots_spare and killed and w.story_out.has("s1.traitre_tue") and w.story_out.has("s1.mort_krag")):
			errs.append("traître brisé %s, épargné par les bots %s, achevé %s, fils %s" % [broken, bots_spare, killed, w.story_out])
	w.terrain.sim = null
	var w2 := BattleSim.new()
	w2.setup(GameData.level("z06_l10"), GameData.party(), 5, {"flags": fl})
	w2._flush()
	w2._enter_phase(2)
	w2._flush()
	w2._damage(w2.traitor_unit, w2.traitor_unit.hp + 1.0, "givre")
	w2.boss.alive = false
	w2._check_end()
	if not w2.story_out.has("s1.traitre_epargne"):
		errs.append("épargné : %s" % [w2.story_out])
	w2.terrain.sim = null
	# Épargné : tendre la main ouvre 6-R ; la victoire rachète Krag (loyauté 60, Héritage de cendre).
	Story.set_flag("s1.traitre_epargne")
	var locked := not Profile.is_unlocked("z06_r01")
	Story.set_flag("s1.quete_pardon")
	var open := Profile.is_unlocked("z06_r01")
	var r := BattleSim.new()
	r.setup(GameData.level("z06_r01"), GameData.party(), 6, {"flags": Story.active_flags()})
	var rparty: Array[String] = []
	for c in r.casters:
		if c.id != "player":
			rparty.append(c.id)
	r.terrain.sim = null
	var res := Profile.apply_battle("z06_r01", true, 3, 90.0, ["krag"])
	var back := Story.has_flag("s1.redemption_krag") and Story.loyalty("krag") == 60 and Profile.companions_available().has("krag") \
		and Profile.companion_spells("krag").has("souffle_de_cendre") and not (res.get("story", []) as Array).is_empty()
	var h := BattleSim.new()
	h.setup(GameData.level("z06_l05"), GameData.party(), 7, {"flags": Story.active_flags(), "active": ["krag", "sylwen"]})
	var kc: BattleSim.Caster = null
	for c in h.casters:
		if c.id == "krag":
			kc = c
	var heritage := kc != null and kc.sprite == "krag_cendre" and kc.spells.has("souffle_de_cendre") and kc.element == "feu"
	h.terrain.sim = null
	if not (locked and open and rparty == ["krag"] and back and heritage):
		errs.append("6-R fermé %s, ouvert %s, groupe %s, retour %s, Héritage %s" % [locked, open, rparty, back, heritage])
	# Laisser partir : le compagnon quitte le groupe.
	Story.set_flag("s1.redemption_krag", false)
	Story.apply({"exile": true})
	if not Story.companion_lost("krag") or Profile.companions_available().has("krag"):
		errs.append("exil")
	# Scènes à choix jouées à l'écran (sans traître : la Marque du Wyrm, option C).
	Profile.data["story"] = saved.duplicate(true)
	for sid in ["z06_l07_outro", "z06_l09_outro", "z06_l10_outro"]:
		main.call("_show_dialogue", [sid], Callable(main, "_show_map"))
		await _frames(3)
		await _through_dialogues(0)
	print("acte 6 : 6-7 %s · 6-9 %s · ✦ 6-10 %s · dragons %d · Ignara %d" % [Story.choice("z06_l07"), Story.choice("z06_l09"), Story.choice("z06_l10"), Story.value("rep.dragons"), Story.loyalty("ignara")])
	if Story.choice("z06_l07") != "A" or not Story.has_flag("s1.phenix_epargne") or Story.choice("z06_l09") != "A" or not Story.has_flag("s1.pacte_dragons") \
			or Story.choice("z06_l10") != "C" or not Story.has_flag("s1.marque_brisee"):
		errs.append("choix joués à l'écran")
	Profile.data["story"] = saved
	if not errs.is_empty():
		push_error("acte 6 : " + " · ".join(errs))
		return false
	print("acte 6 : scènes, Marque (choix, résistance, trahison), combat (brisé, achevé, épargné), 6-R, Héritage, exil OK")
	return true


## Zone 7 · Cité Engloutie : marée (portails noyés), eau (vitesse), courants, tourbillon, vague, portail avalé.
func _zone7_ok() -> bool:
	var errs: Array[String] = []
	for k in ["fishman", "thunder_eel", "titan_crab", "naga_archer", "coral_guard", "tide_mage", "siren", "abyss_horror", "young_kraken", "leviathan", "diving_bell"]:
		if SpriteAtlas.single(k) == null:
			errs.append("sprite " + k)
	var ids: Array = GameData.level_index()["levels"]
	for i in range(1, 11):
		if not ids.has("z07_l%02d" % i):
			errs.append("niveau z07_l%02d" % i)
	if StoryArt.plate("cite", Vector2i(320, 180)) == null:
		errs.append("planche cite")
	# Marée : les portails du premier rang se noient à marée haute, puis reviennent.
	var s := BattleSim.new()
	s.setup(GameData.level("z07_l03"), GameData.party(), 3, {"solo": true})
	var low_active := 0
	for p in s.portals:
		if p.y < 6.0 and p.active():
			low_active += 1
	s.tide_t = 0.0
	s._update_tide()
	for k in range(int(5.5 / BattleSim.TICK)):
		s._update_tide()
	var high_active := 0
	for p in s.portals:
		if p.y < 6.0 and p.active():
			high_active += 1
	var high := s.tide_state == "high"
	s.tide_t = 0.0
	s._update_tide()
	for k in range(int(5.5 / BattleSim.TICK)):
		s._update_tide()
	var back := 0
	for p in s.portals:
		if p.y < 6.0 and p.active():
			back += 1
	if not (low_active >= 3 and high and high_active == 0 and back == low_active):
		errs.append("marée basse %d, haute %s/%d, retour %d" % [low_active, high, high_active, back])
	# L'eau : invocation ralentie, homme-poisson plus rapide.
	s.tide_state = "high"
	s.tide_y = 6.0
	var a := s._spawn_familiar(s.player(), Vector2(4.5, 3.0))
	var f := s._spawn_enemy("fishman", Vector2(4.5, 4.0))
	var cr := s._spawn_enemy("titan_crab", Vector2(5.5, 4.0))
	s._flush()
	if not (is_equal_approx(s._water(a), BattleSim.WATER_SLOW) and is_equal_approx(s._water(f), BattleSim.WATER_HASTE) and is_equal_approx(s._water(cr), 1.0)):
		errs.append("eau %s/%s/%s" % [s._water(a), s._water(f), s._water(cr)])
	# Tourbillon : il attire et blesse les invocations, pas les ennemis.
	var near := s._spawn_familiar(s.player(), Vector2(6.5, 8.0))
	var inside := s._spawn_familiar(s.player(), Vector2(4.6, 8.0))
	inside.hp = 500.0
	inside.max_hp = 500.0
	var foe := s._spawn_enemy("fishman", Vector2(4.4, 8.1))
	s._flush()
	s.add_whirlpool(Vector2(4.5, 8.0), 2.0, 5.0)
	var d0 := near.pos.distance_to(Vector2(4.5, 8.0))
	var fh := foe.hp
	for k in range(int(1.0 / BattleSim.TICK)):
		s._update_whirlpools()
	var pulled := near.pos.distance_to(Vector2(4.5, 8.0)) < d0 - 0.5
	var hurt := inside.hp < 500.0 and is_equal_approx(foe.hp, fh)
	if not (pulled and hurt):
		errs.append("tourbillon attire %s, blesse %s" % [pulled, hurt])
	s.terrain.sim = null
	# Courant : il emporte les unités de sa rangée, puis s'inverse.
	var c := BattleSim.new()
	c.setup(GameData.level("z07_l02"), GameData.party(), 4, {"solo": true})
	var u := c._spawn_familiar(c.player(), Vector2(4.5, 7.6))
	c._flush()
	var p1 := c._current_push(u)
	c.currents[0]["t"] = 0.0
	c._update_currents()
	var p2 := c._current_push(u)
	if not (p1 > 0.0 and p2 < 0.0):
		errs.append("courant %s puis %s" % [p1, p2])
	c.terrain.sim = null
	# Léviathan : vague qui repousse, tentacule, portail avalé puis rendu.
	var b := BattleSim.new()
	b.setup(GameData.level("z07_l10"), GameData.party(), 5, {"solo": true})
	b._flush()
	var w := b._spawn_familiar(b.player(), Vector2(4.5, 9.0))
	b._flush()
	b._boss_ability({"type": "row_sweep", "delay": 0.0, "dmg": 1, "width": 1.6, "barrier": 0.0, "wave": true, "push": 2.6})
	var tg: Dictionary = b.telegraphs.back()
	tg["rect"] = Rect2(0.0, 8.2, BattleSim.W, 1.6)
	tg["t"] = 0.0
	w.hp = 999.0
	b._update_telegraphs()
	var pushed := w.pos.y < 7.0
	var act0 := 0
	for p in b.portals:
		if p.active():
			act0 += 1
	b._boss_ability({"type": "swallow", "dur": 2.0})
	var act1 := 0
	for p in b.portals:
		if p.active():
			act1 += 1
	for k in range(int(2.2 / BattleSim.TICK)):
		b._update_gate_curses()
	var act2 := 0
	for p in b.portals:
		if p.active():
			act2 += 1
	b._boss_ability({"type": "lane_strike", "delay": 1.0, "dmg": 10, "width": 1.4, "tentacle": true})
	var tent := bool(b.telegraphs.back().get("tentacle", false))
	if not (pushed and act1 < act0 and act2 == act0 and tent):
		errs.append("vague %s, avalé %d->%d->%d, tentacule %s" % [pushed, act0, act1, act2, tent])
	b.terrain.sim = null
	if not errs.is_empty():
		push_error("zone 7 : " + " · ".join(errs))
		return false
	print("zone 7 : marée, eau, tourbillon, courants, vague, portail avalé OK")
	return true


## Acte 7 : scènes, portraits, planches ; Ssareth (méfiant après le mensonge au Sphinx), choix joués à l'écran,
## Prémonitions, et leurs effets en combat (marée retenue, annonces plus longues, bouclier, dragons de l'Œuf volé).
func _act7_ok() -> bool:
	var errs: Array[String] = []
	for n in range(1, 11):
		for part in ["intro", "outro"]:
			if not Dialogues.has_scene("z07_l%02d_%s" % [n, part]):
				errs.append("scène z07_l%02d_%s" % [n, part])
	for who in ["ssareth", "leviathan", "ourdisseur"]:
		for mood in ["neutre", "joie", "triste", "colere", "surpris"]:
			if PortraitArt.texture(who, mood) == null:
				errs.append("portrait %s/%s" % [who, mood])
	for kind in ["quais", "canal", "statues", "archives", "palais", "abysse"]:
		if StoryArt.plate(kind, Vector2i(320, 180)) == null:
			errs.append("planche " + kind)
	if SpriteAtlas.single("ssareth") == null:
		errs.append("sprite ssareth")
	var saved: Dictionary = (Story.st() as Dictionary).duplicate(true)
	Story.set_flag("s1.sphinx_mensonge")
	for sid in ["z07_l01_outro", "z07_l07_outro", "z07_l09_outro", "z07_l10_outro"]:
		main.call("_show_dialogue", [sid], Callable(main, "_show_map"))
		await _frames(3)
		await _through_dialogues(0)
	print("acte 7 : Ssareth %d · 7-7 %s · 7-9 %s · ✦ 7-10 %s · Archivistes %d · Fragments %d" % [Story.loyalty("ssareth"), Story.choice("z07_l07"),
		Story.choice("z07_l09"), Story.choice("z07_l10"), Story.value("rep.archivistes"), Story.value("fragments")])
	if not Story.has_flag("s1.ssareth_allie") or not Profile.companions_available().has("ssareth"):
		errs.append("Ssareth non recruté")
	if Story.choice("z07_l07") != "A" or Story.choice("z07_l09") != "A" or not Story.has_flag("s1.premonitions") or Story.choice("z07_l10") != "A" or not Story.has_flag("s1.leviathan_libere"):
		errs.append("choix joués à l'écran")
	var pm := Story.premonition({"set": ["s1.x"], "add": {"loy.ssareth": 5, "corruption": 3}, "grant": {"base": "trident_archives"}})
	if not (pm.contains("Loyauté") and pm.contains("Corruption") and pm.contains("Objet") and pm.contains("Fil du destin")):
		errs.append("prémonition « %s »" % pm)
	Profile.data["story"] = saved
	# Effets en combat.
	var base := BattleSim.new()
	base.setup(GameData.level("z07_l10"), GameData.party(), 2, {"solo": true})
	var a := BattleSim.new()
	a.setup(GameData.level("z07_l10"), GameData.party(), 2, {"solo": true, "flags": ["s1.archives_scellees", "s1.ligne_lue", "s1.sirenes_delivrees"]})
	a._flush()
	a._boss_ability({"type": "lane_strike", "delay": 1.0, "dmg": 10, "width": 1.4})
	var warned := float(a.telegraphs.back()["dur"]) >= 1.49
	if not (not base.tide_cfg.is_empty() and a.tide_cfg.is_empty() and warned and a.barrier_shield >= 25.0):
		errs.append("Léviathan : marée %s/%s, annonce %s, bouclier %s" % [base.tide_cfg.is_empty(), a.tide_cfg.is_empty(), warned, a.barrier_shield])
	base.terrain.sim = null
	a.terrain.sim = null
	var d0 := BattleSim.new()
	d0.setup(GameData.level("z07_l02"), GameData.party(), 3, {"solo": true})
	var d1 := BattleSim.new()
	d1.setup(GameData.level("z07_l02"), GameData.party(), 3, {"solo": true, "flags": ["s1.oeuf_vole"]})
	if not (d0.dragon_cfg.is_empty() and not d1.dragon_cfg.is_empty()):
		errs.append("dragons de l'Œuf volé")
	d0.terrain.sim = null
	d1.terrain.sim = null
	if not errs.is_empty():
		push_error("acte 7 : " + " · ".join(errs))
		return false
	print("acte 7 : scènes, Ssareth, Prémonitions, Léviathan, dragons hostiles OK")
	return true


## Cinématiques des dialogues (docs/design/41-cinematiques.md) : vocabulaire des indications de toutes les zones,
## portraits animés (bouche, clignement), puis le prologue et la zone 1 joués à l'écran, réplique par réplique.
func _cine_ok() -> bool:
	var errs: Array[String] = []
	var cued := 0
	for z in range(1, 8):
		var scs: Dictionary = Dialogues.db(z).get("scenes", {})
		for sid in scs.keys():
			var sc: Dictionary = scs[sid]
			for e in CineStage.check_cues(sc):
				errs.append("%s : %s" % [sid, e])
			var stack: Array = (sc.get("lines", []) as Array).duplicate()
			while not stack.is_empty():
				var l: Dictionary = stack.pop_back()
				for opt in l.get("options", []):
					stack.append_array(opt.get("then", []))
				if l.has("cam") or l.has("fx") or l.has("act"):
					cued += 1
				for e in CineStage.check_cues(l):
					errs.append("%s : %s" % [sid, e])
	for who in ["brann", "sylwen", "porteur", "krag", "ignara"]:
		var base := PortraitArt.texture(who, "neutre").get_image()
		if PortraitArt.frame(who, "neutre", 2, false).get_image().get_data() == base.get_data():
			errs.append("bouche immobile : " + who)
		if PortraitArt.frame(who, "colere", 0, true).get_image().get_data() == PortraitArt.texture(who, "colere").get_image().get_data():
			errs.append("pas de clignement : " + who)
	var ids: Array = ["prologue"]
	for z in [1, 2, 3, 4, 5, 6, 7]:
		for n in range(1, 11):
			ids.append("z%02d_l%02d_intro" % [z, n])
			ids.append("z%02d_l%02d_outro" % [z, n])
		if z == 6:
			ids.append_array(["z06_r01_intro", "z06_r01_outro"])
	var saved: Dictionary = (Story.st() as Dictionary).duplicate(true)
	main.call("_show_dialogue", ids, Callable(main, "_show_map"))
	await _frames(3)
	var max_actors := 0
	var lines := 0
	var guard := 0
	while _screen() is DialogueScreen and guard < 5200:
		var d: DialogueScreen = _screen()
		if d.get("_waiting_choice"):
			for ch in d.choice_box.get_children():
				if ch is Button and not (ch as Button).disabled:
					(ch as Button).pressed.emit()
					break
		else:
			d._tap()
			if not bool(d.get("_typing")):
				lines += 1
		await _frames(2)
		if _screen() is DialogueScreen:
			max_actors = maxi(max_actors, ((_screen() as DialogueScreen).stage.get("_visible") as Array).size())
		guard += 1
	Profile.data["story"] = saved
	if max_actors != 2:
		errs.append("personnages à l'écran : %d au plus (2 attendus)" % max_actors)
	if not errs.is_empty():
		push_error("cinématiques : %s" % [errs])
		return false
	print("cinématiques : %d répliques mises en scène · zones 1 à 7 jouées (%d répliques, %d personnages à l'écran au plus)" % [cued, lines, max_actors])
	return true


## Revoir ou passer les cinématiques (préparation) : le choix n'apparaît que pour une mission déjà réussie ;
## « Passer » va droit au combat ; « Revoir » rejoue l'intro, ses choix déjà faits, sans en rejouer les effets.
func _prep_has_scene_choice(p: PrepScreen) -> bool:
	for l in p.find_children("*", "Label", true, false):
		if (l as Label).text.to_upper() == "CINÉMATIQUES":
			return true
	return false


func _replay_scenes_ok() -> bool:
	var errs: Array[String] = []
	var lid := "z01_l03"
	var saved_levels: Dictionary = (Profile.data["levels"] as Dictionary).duplicate(true)
	var saved_story: Dictionary = (Story.st() as Dictionary).duplicate(true)
	var saved_replay := Profile.replay_scenes()
	(Profile.data["levels"] as Dictionary).erase(lid)
	main.call("_play", lid, false)
	await _frames(3)
	if _prep_has_scene_choice(_screen() as PrepScreen):
		errs.append("choix visible sur une mission jamais réussie")
	(Profile.data["levels"] as Dictionary)[lid] = {"stars": 3, "best": 60.0, "clears": 1}
	Story.mark_seen(lid + "_intro")
	Story.mark_seen(lid + "_outro")
	if Story.choice("z01_l03") == "":
		Story.st()["choices"]["z01_l03"] = {"opt": "A", "t": 0}
	main.call("_play", lid, false)
	await _frames(3)
	var prep: PrepScreen = _screen()
	if not _prep_has_scene_choice(prep):
		errs.append("choix absent sur une mission réussie")
	Profile.set_replay_scenes(false)
	prep.start.emit()
	await _frames(3)
	var skipped := _screen() is BattleScreen
	if not skipped:
		errs.append("Passer : %s au lieu du combat" % _screen().get_class())
	Profile.set_replay_scenes(true)
	var loy := Story.loyalty("brann")
	main.call("_play", lid, false)
	await _frames(3)
	(_screen() as PrepScreen).start.emit()
	await _frames(3)
	var replayed := _screen() is DialogueScreen and bool((_screen() as DialogueScreen).replay)
	if not replayed:
		errs.append("Revoir : %s au lieu de l'intro" % _screen().get_class())
	var guard := 0
	while _screen() is DialogueScreen and guard < 200:
		var d: DialogueScreen = _screen()
		if d.get("_waiting_choice"):
			errs.append("Revoir : choix redemandé")
			break
		d._tap()
		guard += 1
		await _frames(2)
	if not (_screen() is BattleScreen):
		errs.append("Revoir : pas de combat après l'intro")
	if Story.loyalty("brann") != loy:
		errs.append("Revoir : effets rejoués (Brann %d -> %d)" % [loy, Story.loyalty("brann")])
	Profile.data["levels"] = saved_levels
	Profile.data["story"] = saved_story
	Profile.set_replay_scenes(saved_replay)
	main.call("_show_map")
	await _frames(3)
	if not errs.is_empty():
		push_error("cinématiques revues : %s" % [errs])
		return false
	print("cinématiques revues : choix réservé aux missions réussies · Passer -> combat · Revoir -> intro rejouée (%d répliques), sans effets" % guard)
	return true


## Tir normal de chaque classe (docs/design/42-tirs-de-classe.md).
func _fire_sim(cls: String) -> BattleSim:
	var s := BattleSim.new()
	s.setup(GameData.level("z01_l05"), GameData.party(), 11, {"player_class": cls, "solo": true})
	s.wave_t = 9999.0
	s.spawn_queue.clear()
	s.portals.clear()
	return s


func _fire_steps(s: BattleSim, n: int) -> void:
	for k in range(n):
		s.step()


func _foe(s: BattleSim, p: Vector2) -> Unit:
	var e := s._spawn_enemy("mushroom", p)
	e.hp = 9999.0
	e.max_hp = 9999.0
	e.speed = 0.0
	return e


func _class_fire_ok() -> bool:
	var out: Array[String] = []
	var errs: Array[String] = []
	# Cadence : salves en 3 s (Célérité comprise) et contenu de chaque salve.
	for cls: String in ClassFire.SPEC.keys():
		var s := _fire_sim(cls)
		var pc := s.player()
		s.set_player_firing(true)
		var volleys := 0
		var units := 0
		var kinds := {}
		for k in range(90):
			s.step()
			for ev in s.events:
				if str(ev["t"]) in ["shot_fire", "fireflies"] or (str(ev["t"]) == "rise"):
					volleys += 1
			s.events.clear()
		for a in s.allies:
			if a.owner_idx == 0:
				units += 1
				kinds[a.shot if a.shot != "" else a.kind] = true
		var sp: Dictionary = ClassFire.SPEC[cls]
		var per_s := minf((pc.cadence / 4.0) / float(sp["every"]), 1.0 / float(sp.get("min_every", 0.01)))
		var want: float = (floorf(3.0 * per_s - 0.001) + 1.0) * (int(sp.get("n", 1)) if not sp.has("shot") else 1)
		if absf(float(volleys) - want) > 1.0:
			errs.append("%s : %d salves en 3 s (attendu %.0f)" % [cls, volleys, want])
		out.append("%s %d" % [cls, volleys])
		if cls == "necromancien":
			var sk: Unit = null
			for a in s.allies:
				if a.owner_idx == 0:
					sk = a
					break
			var base := float(GameData.units()[pc.familiar]["atk"]) * pc.atk_mult
			if sk == null or absf(sk.scale - 1.1) > 0.001 or absf(sk.atk / base - 2.0) > 0.05:
				errs.append("nécromancien : squelette %s" % (str([sk.scale, sk.atk / base]) if sk != null else "absent"))
		if not sp.has("shot"):
			# Jamais en rang : les troupes d'une salve n'ont ni la même place ni le même instant.
			var s2 := _fire_sim(cls)
			ClassFire.volley(s2, s2.player())
			var first := s2._pending_allies.size()
			_fire_steps(s2, 8)
			var ys := {}
			for a in s2.allies:
				ys[snappedf(a.pos.y - a.prev_pos.y * 0.0, 0.001)] = true
			if first >= int(sp["n"]) or s2.allies.size() != int(sp["n"]) or ys.size() < 2:
				errs.append("%s : troupes alignées ou simultanées (%d d'un coup, %d places)" % [cls, first, ys.size()])
	# Archer : la flèche traverse 2 ennemis et s'arrête dans le 3e.
	var ar := _fire_sim("archer")
	var foes: Array[Unit] = []
	for k in range(5):
		foes.append(_foe(ar, Vector2(ar.player().x, 3.0 + 0.6 * float(k))))
	ar._flush()
	ClassFire.volley(ar, ar.player())
	_fire_steps(ar, 40)
	var touched := 0
	for e in foes:
		if e.hp < e.max_hp:
			touched += 1
	if touched != 5:
		errs.append("archer : %d ennemis touchés (5 attendus)" % touched)
	# Épéiste : l'onde touche tout l'arc et file jusqu'au bout du terrain.
	var ep := _fire_sim("epeiste")
	var row: Array[Unit] = []
	for k in range(4):
		row.append(_foe(ep, Vector2(ep.player().x - 0.75 + 0.5 * float(k), 3.0)))
	ep._flush()
	ClassFire.volley(ep, ep.player())
	var far := 0.0
	for k in range(75):
		ep.step()
		for a in ep.allies:
			if a.shot == "onde":
				far = maxf(far, a.pos.y)
	var arc_hits := 0
	for e in row:
		if e.hp < e.max_hp:
			arc_hits += 1
	if arc_hits != 4 or far < 13.5:
		errs.append("épéiste : arc %d/4 · portée %.1f" % [arc_hits, far])
	# Clerc : le rayon tombe sur le groupe et rend de la Barrière.
	var cl := _fire_sim("clerc")
	for k in range(3):
		_foe(cl, Vector2(cl.player().x + 0.3 * float(k - 1), 4.0))
	cl._flush()
	cl.barrier_hp = 50.0
	ClassFire.volley(cl, cl.player())
	var beam := false
	for k in range(40):
		cl.step()
		for ev in cl.events:
			if str(ev["t"]) == "shot_beam" and int(ev["n"]) == 3:
				beam = true
		cl.events.clear()
	if not beam or cl.barrier_hp <= 50.0:
		errs.append("clerc : rayon %s · barrière %.1f" % [beam, cl.barrier_hp])
	# Chevalier : le bouclier frappe le premier ennemi, le repousse et le ralentit.
	var kn := _fire_sim("chevalier")
	var front := _foe(kn, Vector2(kn.player().x, 4.0))
	var side := _foe(kn, Vector2(kn.player().x + 0.7, 4.1))
	var back := _foe(kn, Vector2(kn.player().x, 6.0))
	kn._flush()
	ClassFire.volley(kn, kn.player())
	var y_hit := 0.0
	for k in range(30):
		kn.step()
		if front.hp < front.max_hp and y_hit == 0.0:
			y_hit = front.pos.y
	if front.hp >= front.max_hp or side.hp >= side.max_hp or back.hp < back.max_hp or y_hit < 4.3 or front.slow_stacks < 2:
		errs.append("chevalier : premier %s · onde de choc %s · loin épargné %s · recul %.2f" % [front.hp < front.max_hp, side.hp < side.max_hp, back.hp >= back.max_hp, y_hit - 4.0])
	# Berserker : cadence ×2 quand la Barrière est basse.
	var bz := _fire_sim("berserker")
	var r_full := ClassFire.rate(bz, bz.player())
	bz.barrier_hp = bz.barrier_max * 0.2
	var r_low := ClassFire.rate(bz, bz.player())
	if absf(r_low / r_full - 2.0) > 0.01:
		errs.append("berserker : rage ×%.2f" % (r_low / r_full))
	# Portails : une flèche passée par un ×2 en ressort doublée ; un tir n'est ni visé ni blessé.
	var pm := _fire_sim("archer")
	var dbl := Portal.new()
	dbl.id = 901
	dbl.kind = "mult"
	dbl.value = 2
	dbl.x = pm.player().x
	dbl.y = 3.0
	dbl.width = 2.0
	pm.portals.append(dbl)
	ClassFire.volley(pm, pm.player())
	_fire_steps(pm, 12)
	var arrows := 0
	var safe := true
	for a in pm.allies:
		if a.shot == "fleche":
			arrows += 1
			pm._damage(a, 999.0, "feu")
			safe = safe and a.alive
	pm._build_grids()
	var in_grid := false
	for cell in pm._grid_a:
		for a in cell:
			if a.shot != "":
				in_grid = true
	if arrows != 2 or not safe or in_grid:
		errs.append("portail ×2 : %d flèches · intouchables %s · hors grille %s" % [arrows, safe, not in_grid])
	# Compagnon : ses troupes par défaut, le tir de sa classe si le Cercle le demande.
	var cs := BattleSim.new()
	cs.setup(GameData.level("z01_l05"), GameData.party(), 12, {"circle": {"brann": {"fire": "classe"}}, "active": ["brann", "sylwen"]})
	var comp_ok := cs.casters.size() == 3
	for c in cs.casters:
		if c.is_bot:
			var shoots := ClassFire.spec_of(c).has("shot")
			comp_ok = comp_ok and shoots == (c.id == "brann")
	if not comp_ok:
		errs.append("compagnons : choix du tir ignoré")
	print("tirs de classe : apparitions en 3 s ", out, " · flèche ", touched, " ennemis · onde ", arc_hits, " en arc, portée %.1f · clerc barrière %.1f · chevalier recul %.2f · rage berserker ×%.1f · ×2 → %d flèches · compagnons %s" % [far, cl.barrier_hp, y_hit - 4.0, r_low / r_full, arrows, comp_ok])
	if not errs.is_empty():
		push_error("tirs de classe : %s" % [errs])
		return false
	return true


## Sorts de classe (grimoire, arbre de l'Entraînement) : dans les disciplines de leur classe, jamais dans
## les écoles élémentaires du Tiroir ni dans le catalogue général de la Bibliothèque.
func _drawer_groups_ok() -> bool:
	var errs: Array[String] = []
	var per := {}
	for cls: String in (GameData.party()["classes"] as Dictionary).keys():
		var discs: Array[String] = []
		for d in Profile.disciplines(cls):
			discs.append("d:" + str((d as Dictionary)["id"]))
		var tree: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/skill_trees/%s.json" % cls))
		for br in tree.get("branches", []):
			for tier in br.get("tiers", []):
				for node in tier["nodes"]:
					if not node.has("unlock"):
						continue
					var sid := str(node["unlock"])
					var g := Profile.drawer_group(sid)
					if cls == "mage":
						if not BattleScreen.DRAWER.has(g):
							errs.append("%s (%s) → %s" % [sid, cls, g])
					elif not discs.has(g) or LibraryScreen.catalogue().has(sid):
						errs.append("%s (%s) → %s" % [sid, cls, g])
					per[cls] = int(per.get(cls, 0)) + 1
		for sid in Profile.class_grimoire(cls):
			if not discs.has(Profile.drawer_group(sid)):
				errs.append("%s (grimoire %s) → %s" % [sid, cls, Profile.drawer_group(sid)])
	var nec := [Profile.drawer_group("horde"), Profile.drawer_group("malediction_masse"), Profile.drawer_group("sacrifice_ames")]
	print("tiroir : sorts d'arbre par classe ", per, " · nécromancien ", nec, " · Purifier ", Profile.drawer_group("purifier"))
	if not errs.is_empty():
		push_error("sorts de classe mal rangés : %s" % [errs])
		return false
	return true



## Son (docs/design/43-audio.md) : chaque sort a ses sons et une signature unique ; tous les sons référencés
## (combat, cinématiques, voix, ambiances, musiques, écrans) existent ; des sons sont vraiment partis.
func _audio_ok() -> bool:
	var errs: Array[String] = []
	var need: Dictionary = {}
	var sigs: Dictionary = {}
	for id in GameData.spells().keys():
		for n in SpellAudio.sounds_of(str(id)):
			need["sfx/" + n] = "sort " + str(id)
		var p := SpellAudio.profile(str(id))
		var sg := SpellAudio._sig(p)
		if sigs.has(sg):
			errs.append("même son : %s et %s" % [sigs[sg], id])
		sigs[sg] = id
	for fam in SpellAudio.FAMILIES:
		for part in ["cast", "hit", "boom", "loop"]:
			need["sfx/%s_%s" % [fam, part]] = "famille"
	for v in BattleAudio.SHOT.values():
		need["sfx/" + str(v)] = "tir"
	for v in BattleAudio.ROAR.values():
		need["sfx/roar_" + str(v)] = "cri"
	for v in CineAudio.CREATURE.values():
		need["sfx/roar_" + str(v)] = "cri"
	for v in SpellAudio.SUMMON.values():
		need["sfx/summon_" + str(v)] = "invocation"
	for table in [CineAudio.FX, CineAudio.ACT]:
		for v in (table as Dictionary).values():
			need["sfx/" + str((v as Array)[0])] = "cinématique"
	for v in CineAudio.MOOD_MUSIC.values():
		need["music/" + str(v)] = "cinématique"
	for v in CineAudio.GRADE_MUSIC.values():
		need["music/" + str(v)] = "cinématique"
	for z in range(1, 8):
		need["music/battle_z%d" % z] = "combat"
	for n in ["boss_1", "boss_2", "havre", "map", "cine_heroic"]:
		need["music/" + n] = "musique"
	for n in ["ui_click", "ui_confirm", "victory", "defeat", "barrier_hit", "nexus_hit", "nexus_break", "telegraph", "whirlpool",
			"thunder_far", "dragon_pass", "avalanche", "tentacle", "wave_crash", "level_up", "loot_rare", "ultimate", "grand_cast", "forbidden"]:
		need["sfx/" + n] = "combat"
	for v in VoiceBabble.VOICES:
		need["voice/" + str(v)] = "voix"
	var missing := 0
	for path in need.keys():
		if not Snd.has(str(path)):
			errs.append("son absent : %s (%s)" % [path, need[path]])
			missing += 1
	# Des sons sont vraiment partis pendant les combats et les cinématiques joués plus haut.
	var played := Snd.played()
	var casts := 0
	var voices := 0
	for n in played:
		if str(n).ends_with("_cast"):
			casts += 1
		if str(n).begins_with("voice/"):
			voices += 1
	# Volumes de la sauvegarde : appliqués même quand ils changent sans passer par les Options (chargement local
	# ou cloud après le démarrage de l'audio), sinon on entend les volumes par défaut jusqu'au premier réglage.
	var opts := Profile._options()
	if not (opts.get("vol") is Dictionary):
		opts["vol"] = {}
	var vols: Dictionary = opts["vol"]
	var had := vols.has("music")
	var old_m := float(vols.get("music", 0.0))
	vols["music"] = 0.3
	await create_timer(0.8).timeout
	var want := linear_to_db(Profile.audio_vol("master") * 0.3) if Profile.sound_on() else -80.0
	var got := float((Snd._a().get("_off") as Dictionary).get("music", 0.0)) if Snd._a() != null else 0.0
	if absf(got - want) > 0.1:
		errs.append("volume de la sauvegarde non appliqué : musique %.1f dB au lieu de %.1f dB" % [got, want])
	if had:
		vols["music"] = old_m
	else:
		vols.erase("music")
	if AudioServer.bus_count != 1:
		# Sur le web, un bus ajouté en cours de route n'est pas raccordé à la sortie : plus aucun son.
		errs.append("%d bus audio (le Master seul est raccordé sur le web)" % AudioServer.bus_count)
	if Snd._a() == null:
		errs.append("autoload Audio absent")
	elif played.is_empty():
		errs.append("aucun son joué")
	if not errs.is_empty():
		push_error("son : %s" % [errs.slice(0, 20)])
		return false
	print("son : %d sorts, %d signatures uniques · %d sons vérifiés · journal %d (lancements %d, syllabes %d)" % [GameData.spells().size(), sigs.size(), need.size(), played.size(), casts, voices])
	return true
