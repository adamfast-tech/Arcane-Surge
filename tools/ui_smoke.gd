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
	# Voies du Surge (13.3b) : 3e branche par classe, verrouillée sans la Vérité des Cendres.
	var surge_ok := true
	for cls in ["archer", "epeiste", "clerc", "necromancien", "chevalier", "berserker"]:
		var tree: Dictionary = GameData.load_json("res://data/skill_trees/%s.json" % cls)
		var brs: Array = tree["branches"]
		var last: Dictionary = brs[brs.size() - 1]
		var keys: Array = (last["tiers"] as Array)[4]["nodes"]
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
	if not _classes_ok():
		quit(1)
		return
	if not await _meditation_ok():
		quit(1)
		return
	if not _zone4_ok():
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
	b.exit_requested.emit("map")
	await _frames(10)
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
