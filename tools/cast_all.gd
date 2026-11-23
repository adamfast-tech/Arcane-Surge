extends SceneTree
## Lance chaque technique d'un grimoire de classe une fois en combat (contrôle d'erreurs) :
## godot --headless --path . --script res://tools/cast_all.gd -- --class=archer

func _init() -> void:
	var cls := "archer"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--class="):
			cls = a.trim_prefix("--class=")
	Profile.data = Profile.default_data()
	var ids := Profile.class_grimoire(cls)
	var lv := GameData.level("z01_l05")
	var bad: Array[String] = []
	for id in ids:
		var s := BattleSim.new()
		s.setup(lv, GameData.party(), 7, {"solo": true, "player_level": 30, "player_class": cls, "deck": [id]})
		s.player().firing = true
		for k in range(150):
			s.step()
		var c := s.player()
		c.mana = c.mana_max
		c.spell_cd.clear()
		s.barrier_hp = s.barrier_max * 0.5
		var target := Vector2(4.5, 7.0)
		var big := s.strongest_enemy()
		if big != null:
			target = big.pos
		var ok := s.cast_spell(c, id, target)
		var kinds := {}
		for e in s.events:
			kinds[str(e["t"])] = true
		for k in range(240):
			s.step()
			for e in s.events:
				kinds[str(e["t"])] = true
			s.events.clear()
		if not ok:
			bad.append(id)
		var sd: Dictionary = GameData.spells()[id]
		print("%-18s %-13s %s  puissance %4d  prix %5d  mana %2d  %s" % [id, str(sd["rank"]), "ok " if ok else "NON", Profile.spell_power(id), Profile.spell_price(id), int(sd["mana"]), ",".join(PackedStringArray(kinds.keys()))])
		s.terrain.sim = null
	print("refusés : %s" % ", ".join(bad))
	quit()
