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
				if ch is Button:
					btns.append(ch)
			(btns[mini(pick, btns.size() - 1)] as Button).pressed.emit()
		else:
			d._skip()
		n += 1
		await _frames(3)
	return n


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
	Profile.set_look("head", "tresse")
	Profile.set_look("hair", "roux")
	Profile.set_look("outfit", "ocre")
	cr._rebuild()
	await _frames(2)
	var cr_name: String = cr.get_script().get_global_name()
	cr.done.emit()
	await _frames(3)
	var bo := Profile.battle_opts()
	print("création : écran ", cr_name, " · Revenant ", rev, " · Nain ", nain, " · Archer ", arch, " · créé ", Profile.created(),
		" · ", Profile.race(), " ", Profile.look()["head"], " · écran ", _screen().get_script().get_global_name(), " · sprite combat ", bo.has("look"))
	if rev or not nain or arch or not Profile.created() or not (_screen() is HubScreen):
		push_error("création du personnage incorrecte")
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
