extends SceneTree
## Planche des fonds de salles (contrôle visuel), en portrait et en paysage :
##   godot --headless --path . --script res://tools/room_sheet.gd -- --out=/chemin/planche.png [--land]
func _init() -> void:
	var out := "user://room_sheet.png"
	var land := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a == "--land":
			land = true
	var size := RoomArt.size_for(Vector2(1920, 1080) if land else Vector2(720, 1280))
	var kinds: Array = RoomArt.KINDS.duplicate()
	for z in RoomArt.ZONE_PLATES.keys():
		kinds.append("zone%d" % int(z))
	var cols := 5 if not land else 3
	var rows := int(ceil(float(kinds.size()) / float(cols)))
	var sheet := Image.create_empty(cols * (size.x + 4), rows * (size.y + 4), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("000000"))
	var t0 := Time.get_ticks_msec()
	for i in range(kinds.size()):
		var t := Time.get_ticks_msec()
		var im := RoomArt.scene(str(kinds[i]), size).get_image()
		print(kinds[i], " ", Time.get_ticks_msec() - t, " ms")
		sheet.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i((i % cols) * (size.x + 4), int(i / cols) * (size.y + 4)))
	print("total ", Time.get_ticks_msec() - t0, " ms, taille ", size)
	sheet.save_png(out)
	quit()
