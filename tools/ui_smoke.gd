extends SceneTree
## Test de fumée de l'interface : menu → combat → Écho → victoire → rejouer → défaite → pause.
##   godot --headless --path . --script res://tools/ui_smoke.gd


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _run() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(5)
	main.call("_start", "z01_l08", false)
	await _frames(10)
	var b: BattleScreen = main.get("_screen")
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
	b.sim.debug_set_ratio(0.3)
	await _frames(5)
	print("2e Écho : ", b.sim.state, " · fenêtre : ", b._echo_open)
	b._choose_echo(b.sim.pending_echoes[0])
	b.sim.debug_set_ratio(0.0)
	await _frames(10)
	print("état : ", b.sim.state, " · fenêtre de fin : ", b._end_open, " · étoiles : ", b.sim.stars)
	b.restart_requested.emit()
	await _frames(10)
	b = main.get("_screen")
	b.sim.barrier_hp = 0.0
	await _frames(10)
	print("état : ", b.sim.state, " · fenêtre de fin : ", b._end_open)
	b.exit_requested.emit("map")
	await _frames(10)
	main.call("_start", "z01_l01", true)
	await _frames(10)
	b = main.get("_screen")
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
	var eq: EquipmentScreen = main.get("_screen")
	var inv: Array = Profile.data["inventory"]
	if inv.size() > 0:
		Profile.equip(str(inv[inv.size() - 1]["uid"]))
		eq.call("_rebuild")
	await _frames(5)
	main.call("_show_login", true)
	await _frames(5)
	print("niveau joueur : ", Profile.level(), " · or : ", Profile.gold(), " · objets : ", inv.size(), " · puissance : ", Profile.power())
	# Objectifs spéciaux : boss, escorte, siège.
	for id in ["z01_l05", "z01_l07", "z01_l09", "z01_l10", "z01_l02"]:
		main.call("_start", id, false)
		await _frames(30)
		var bs: BattleScreen = main.get("_screen")
		bs.sim.set_player_firing(true)
		await _frames(90)
		print(id, " · ", bs.sim.objective_title(), " · ", bs.sim.objective_info(), " · état ", bs.sim.state)
		bs.sim.debug_set_ratio(0.0)
		if id == "z01_l05" or id == "z01_l10":
			bs.sim.boss.hp = 0.0
			bs.sim.boss.alive = false
		await _frames(10)
		print("  -> ", bs.sim.state, " · ", bs.sim.end_reason)
	print("OK smoke")
	quit()
