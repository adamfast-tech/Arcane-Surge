extends SceneTree
## Simulateur sans affichage pour l'équilibrage (docs/design/03-combat.md §14).
## Le joueur et les bots sont pilotés par l'IA. Exemple :
##   godot --headless --path . --script res://tools/sim_cli.gd -- --level=z01_l08 --runs=20


func _init() -> void:
	var level_id := "z01_l08"
	var runs := 10
	var solo := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			level_id = a.trim_prefix("--level=")
		elif a.begins_with("--runs="):
			runs = int(a.trim_prefix("--runs="))
		elif a == "--solo":
			solo = true
	var lv := GameData.level(level_id)
	var party := GameData.party()
	var wins := 0
	var total_time := 0.0
	var total_barrier := 0.0
	var total_stars := 0
	var total_us := 0
	var total_steps := 0
	var peak := 0
	print("Simulation %s (%s), %d parties%s" % [level_id, str(lv.get("name", "")), runs, " en solo" if solo else ""])
	for i in range(runs):
		var s := BattleSim.new()
		var gl := int(lv.get("global_level", 1))
		var k := 1.0 + 0.12 * float(gl - 1)
		var gear := {"pou": roundf(4.0 * k), "esp": roundf(4.0 * k), "vig": roundf(3.0 * k), "cel": roundf(2.0 * k), "des": roundf(1.0 * k)}
		s.setup(lv, party, 1000 + i, {"autoplay": true, "solo": solo, "player_level": gl, "bot_level": maxi(1, gl - 1), "gear": gear})
		var t0 := Time.get_ticks_usec()
		var steps := 0
		while (s.state == "running" or s.state == "echo") and s.time < 900.0:
			s.step()
			s.events.clear()
			steps += 1
		total_us += Time.get_ticks_usec() - t0
		total_steps += steps
		peak = maxi(peak, s.peak_allies)
		var win := s.state == "victory"
		if win:
			wins += 1
		total_time += s.time
		total_barrier += s.barrier_hp / s.barrier_max
		total_stars += s.stars
		print("  #%02d %-8s %5.1fs  barrière %3d%%  étoiles %d  kills %4d  invocations %5d  soins +%d  reste %d%%  %s" % [
			i + 1, s.state, s.time, int(100.0 * s.barrier_hp / s.barrier_max), s.stars, s.kills, s.summoned,
			int(s.healed_total), int(100.0 * s.objective_ratio()), s.objective_info()])
	print("Résumé : victoires %d/%d · durée moy. %.1fs (réf. %ss) · barrière moy. %d%% · étoiles moy. %.2f · pic d'alliés %d · %.3f ms/pas" % [
		wins, runs, total_time / runs, str(lv.get("par_time", "?")), int(100.0 * total_barrier / runs),
		float(total_stars) / runs, peak, float(total_us) / maxf(1.0, float(total_steps)) / 1000.0])
	quit()
