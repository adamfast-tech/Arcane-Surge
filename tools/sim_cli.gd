extends SceneTree
## Simulateur sans affichage pour l'équilibrage (docs/design/03-combat.md §14).
## Le joueur et les bots sont pilotés par l'IA. Exemple :
##   godot --headless --path . --script res://tools/sim_cli.gd -- --level=z01_l08 --runs=20
## « --krag » : Krag recruté et emmené avec Sylwen (au lieu de Brann) ; « --active=brann,krag » pour choisir.
## « --flags=s1.portes_reactivees » : drapeaux d'histoire (story_mods des niveaux) ;
## « --class=chevalier » : classe du héros ; « --mods=barrier_cap:5,miracle:1 » : effets d'arbre forcés.


func _init() -> void:
	var level_id := "z01_l08"
	var runs := 10
	var solo := false
	var krag := false
	var active: Array = ["sylwen", "krag"]
	var deck: Array = []
	var diffm := 1.0
	var cls := "mage"
	var mods := {}
	var flags: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			level_id = a.trim_prefix("--level=")
		elif a.begins_with("--runs="):
			runs = int(a.trim_prefix("--runs="))
		elif a == "--solo":
			solo = true
		elif a.begins_with("--class="):
			cls = a.trim_prefix("--class=")
		elif a.begins_with("--mods="):
			for kv in a.trim_prefix("--mods=").split(","):
				var p := kv.split(":")
				if p.size() == 2:
					mods[p[0]] = float(p[1])
		elif a == "--krag":
			krag = true
		elif a.begins_with("--diff="):
			diffm = float(a.trim_prefix("--diff="))
		elif a.begins_with("--deck="):
			deck = Array(a.trim_prefix("--deck=").split(","))
		elif a.begins_with("--flags="):
			flags = Array(a.trim_prefix("--flags=").split(","))
		elif a.begins_with("--active="):
			krag = true
			active = Array(a.trim_prefix("--active=").split(","))
	var lv := GameData.level(level_id)
	var party := GameData.party()
	var wins := 0
	var total_time := 0.0
	var total_barrier := 0.0
	var total_stars := 0
	var total_us := 0
	var total_steps := 0
	var peak := 0
	var casts := {}
	print("Simulation %s (%s), %d parties%s%s, classe %s" % [level_id, str(lv.get("name", "")), runs, " en solo" if solo else "", " avec Krag" if krag else "", cls])
	for i in range(runs):
		var s := BattleSim.new()
		var gl := int(lv.get("global_level", 1))
		var k := 1.0 + 0.12 * float(gl - 1)
		var gear := {"pou": roundf(4.0 * k), "esp": roundf(4.0 * k), "vig": roundf(3.0 * k), "cel": roundf(2.0 * k), "des": roundf(1.0 * k)}
		var o := {"autoplay": true, "solo": solo, "player_level": gl, "bot_level": maxi(1, gl - 1), "gear": gear, "player_class": cls, "mods": mods}
		if not deck.is_empty():
			o["deck"] = deck
		o["difficulty"] = diffm
		o["flags"] = flags.duplicate()
		if krag:
			(o["flags"] as Array).append("s1.krag_allie")
			o["active"] = active
		s.setup(lv, party, 1000 + i, o)
		var t0 := Time.get_ticks_usec()
		var steps := 0
		while (s.state == "running" or s.state == "echo") and s.time < 900.0:
			s.step()
			for ev in s.events:
				if str(ev["t"]) == "spell" and ev.has("sid") and ev.has("from") and absf((ev["from"] as Vector2).x - s.player().x) < 0.01:
					casts[str(ev["sid"])] = int(casts.get(str(ev["sid"]), 0)) + 1
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
		s.terrain.sim = null
		print("  #%02d %-8s %5.1fs  barrière %3d%%  étoiles %d  kills %4d  invocations %5d  soins +%d  reste %d%%  %s" % [
			i + 1, s.state, s.time, int(100.0 * s.barrier_hp / s.barrier_max), s.stars, s.kills, s.summoned,
			int(s.healed_total), int(100.0 * s.objective_ratio()), s.objective_info()])
	print("Lancers du héros : %s" % JSON.stringify(casts))
	print("Résumé : victoires %d/%d · durée moy. %.1fs (réf. %ss) · barrière moy. %d%% · étoiles moy. %.2f · pic d'alliés %d · %.3f ms/pas" % [
		wins, runs, total_time / runs, str(lv.get("par_time", "?")), int(100.0 * total_barrier / runs),
		float(total_stars) / runs, peak, float(total_us) / maxf(1.0, float(total_steps)) / 1000.0])
	quit()
