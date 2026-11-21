extends SceneTree
## Exporte les sprites actuels (1 px = 1 px) dans un dossier, pour la planche de référence.
##   godot --headless --path . --script res://tools/export_sprites.gd -- --out=/chemin/absolu


func _initialize() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	if out == "":
		push_error("--out=/chemin requis")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	for name in SpriteAtlas.DEFS.keys():
		if name in ["star", "star_off", "cross", "px"]:
			continue
		var el := "physique" if SpriteAtlas.RECOLOR.has(name) else ""
		var imgs: Array[Image] = SpriteAtlas._images_for(str(name), el)
		for i in range(imgs.size()):
			imgs[i].save_png("%s/%s_%d.png" % [out, name, i + 1])
	print("ok")
	quit()
