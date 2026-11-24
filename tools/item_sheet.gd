extends SceneTree
## Planche de toutes les icônes d'équipement et de runes (contrôle visuel) :
##   godot --headless --path . --script res://tools/item_sheet.gd -- --out=/chemin/planche.png
func _init() -> void:
	var out := "user://item_sheet.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	var bases: Dictionary = Profile.items_db()["bases"]
	var ids: Array = bases.keys()
	var cell := 72
	var cols := 12
	var fams: Array = (Profile.items_db()["runes"]["families"] as Dictionary).keys()
	var n := ids.size() + fams.size()
	var rows := int(ceil(float(n) / float(cols)))
	var sheet := Image.create_empty(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("1a1626"))
	var i := 0
	for id in ids:
		var tex := ItemArt.item(str(id), 72)
		if tex != null:
			var im := tex.get_image()
			sheet.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i((i % cols) * cell, int(i / cols) * cell))
		i += 1
	for f in fams:
		var im := ItemArt.rune(str(f), (i % 5) + 1, 72).get_image()
		sheet.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i((i % cols) * cell, int(i / cols) * cell))
		i += 1
	sheet.save_png(out)
	print("planche : ", out, " (", n, " icônes)")
	quit()
