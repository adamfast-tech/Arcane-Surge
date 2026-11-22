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
	# Dialogues : prologue + intro de 1-1, lus jusqu'au bout (tap), avec l'historique.
	main.call("_play", "z01_l01", false)
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
	# Objectifs spéciaux : boss (avec l'aide des fées), escorte, siège, lucioles.
	for id in ["z01_l05", "z01_l07", "z01_l09", "z01_l10", "z01_l02"]:
		main.call("_start", id, false)
		await _frames(30)
		var bs: BattleScreen = _screen()
		if id == "z01_l10":
			print("  fées : bouclier ", bs.sim.barrier_shield, " · lucioles ", bs.sim.orbs.size(), " · notes ", bs.sim.story_notes.size())
		bs.sim.set_player_firing(true)
		await _frames(90)
		print(id, " · ", bs.sim.objective_title(), " · ", bs.sim.objective_info(), " · état ", bs.sim.state)
		bs.sim.debug_set_ratio(0.0)
		if id == "z01_l05" or id == "z01_l10":
			bs.sim.boss.hp = 0.0
			bs.sim.boss.alive = false
		await _frames(10)
		print("  -> ", bs.sim.state, " · ", bs.sim.end_reason)
		bs.exit_requested.emit("map")
		await _frames(3)
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
