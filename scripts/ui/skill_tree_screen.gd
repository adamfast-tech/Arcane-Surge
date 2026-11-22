class_name SkillTreeScreen
extends Control
## Entraînement : arbre de compétences du Mage (docs/design/04-classes-races.md §3, maquette
## docs/mockups/Arbre.dc.html). Branches à 5 paliers, sort à débloquer, évolution, Clé de voûte.

signal back

var _branch := ""
var _reset_armed := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.68)
	var branches: Array = Profile.tree_db().get("branches", [])
	_branch = str(branches[0]["id"]) if not branches.is_empty() else ""
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	var col := UiTheme.scroll_column(self, 680.0, 16.0)
	col.add_theme_constant_override("separation", 14)
	var head := HBoxContainer.new()
	col.add_child(head)
	var b := UiTheme.back_button("Havre-Aube")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	var pts := UiTheme.label("%d point%s" % [Profile.skill_points_free(), "s" if Profile.skill_points_free() > 1 else ""], 24, UiTheme.GOLD)
	head.add_child(pts)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("ENTRAÎNEMENT", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title("ARBRE DU MAGE", 22, UiTheme.TEXT))
	col.add_child(UiTheme.wrap("Points : %d disponibles sur %d · Clés de voûte : %d / %d · 1 point par niveau à partir du niveau 2." % [
		Profile.skill_points_free(), Profile.skill_points_total(), Profile.keystones_taken(), int(Profile.tree_db().get("keystone_limit", 2))], 18, UiTheme.MUTED))
	# Onglets des branches.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	col.add_child(tabs)
	var current: Dictionary = {}
	for br in Profile.tree_db().get("branches", []):
		var id := str(br["id"])
		var bc := Color(str(br.get("color", "6fdccf")))
		var locked: bool = br.has("locked")
		var t := UiTheme.button("%s\n%s" % [str(br["name"]), "Acte 3" if locked else "%d points" % Profile.branch_spent(br)], 18)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.custom_minimum_size = Vector2(0, 70)
		t.icon = Icons.tex("lock" if locked else str(br.get("icon", "rune")), 40)
		t.add_theme_constant_override("icon_max_width", 20)
		t.add_theme_color_override("icon_normal_color", Color(UiTheme.MUTED, 0.6) if locked else bc)
		if id == _branch:
			current = br
			t.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), bc, 12, 2, 8, bc))
			t.add_theme_color_override("font_color", bc)
		if locked:
			t.add_theme_color_override("font_color", Color(UiTheme.MUTED, 0.7))
		t.pressed.connect(func() -> void:
			_branch = id
			_rebuild.call_deferred())
		tabs.add_child(t)
	if current.is_empty():
		return
	var bc2 := Color(str(current.get("color", "6fdccf")))
	col.add_child(UiTheme.label("%s · %s" % [str(current["name"]), str(current.get("theme", ""))], 22, bc2))
	if current.has("locked"):
		var c: Array = UiTheme.card(UiTheme.BORDER, 16)
		col.add_child(c[0])
		var h := HBoxContainer.new()
		(c[1] as VBoxContainer).add_child(h)
		h.add_child(UiTheme.icon_rect("lock", 28, UiTheme.MUTED))
		h.add_child(UiTheme.wrap(str(current["locked"]), 19, UiTheme.MUTED))
		return
	var spent := Profile.branch_spent(current)
	var i := 0
	for tier in current.get("tiers", []):
		i += 1
		var req := int(tier.get("req", 0))
		var open := spent >= req
		col.add_child(UiTheme.section("Palier %d · %s" % [i, "ouvert" if open else "%d points dans la branche" % req], UiTheme.TEAL if open else UiTheme.MUTED))
		for node in tier["nodes"]:
			col.add_child(_node_card(node, bc2, open))
	# Réinitialisation (Salle de méditation à venir) : gratuite la 1re fois.
	if Profile.skill_points_spent() > 0:
		var cost := Profile.reset_cost()
		var rs := UiTheme.button(("Confirmer la réinitialisation" if _reset_armed else "Réinitialiser l'arbre") + (" · gratuit" if cost == 0 else " · %d or" % cost), 19)
		rs.custom_minimum_size = Vector2(0, 56)
		rs.disabled = Profile.gold() < cost
		rs.pressed.connect(func() -> void:
			if not _reset_armed:
				_reset_armed = true
			elif Profile.reset_skills():
				_reset_armed = false
				_save()
			_rebuild.call_deferred())
		col.add_child(rs)


func _node_card(node: Dictionary, bc: Color, open: bool) -> PanelContainer:
	var id := str(node["id"])
	var kind := str(node.get("kind", "passive"))
	var rank := Profile.skill_rank(id)
	var mx := int(node.get("max", 1))
	var border := UiTheme.BORDER
	var ncol := UiTheme.TEXT
	var icon := "sparkle"
	var tag := "PASSIF"
	match kind:
		"spell":
			border = UiTheme.TEAL
			ncol = UiTheme.TEAL
			icon = str(node.get("unlock", "rune"))
			tag = "SORT"
		"evolution":
			border = UiTheme.VIOLET
			ncol = UiTheme.VIOLET
			icon = "meteore" if id.contains("meteore") else "champion"
			tag = "ÉVOLUTION"
		"keystone":
			border = UiTheme.GOLD
			ncol = UiTheme.GOLD
			icon = "rune"
			tag = "CLÉ DE VOÛTE"
	if rank > 0 and kind == "passive":
		border = bc
	var c: Array = UiTheme.card(Color(border, 0.85 if open else 0.4), 12)
	var pc: PanelContainer = c[0]
	if not open:
		pc.modulate = Color(1, 1, 1, 0.6)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	(c[1] as VBoxContainer).add_child(h)
	h.add_child(UiTheme.icon_rect(icon, 30, ncol if kind != "passive" else bc))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	top.add_child(UiTheme.label(str(node["name"]), 22, ncol))
	top.add_child(UiTheme.label("%s · %d / %d" % [tag, rank, mx], 15, UiTheme.GOLD if rank > 0 else UiTheme.MUTED))
	v.add_child(UiTheme.wrap(str(node.get("desc", "")), 17, UiTheme.MUTED))
	var block := Profile.invest_block(id)
	var inv := UiTheme.button("+1" if rank < mx else "MAX", 22)
	inv.custom_minimum_size = Vector2(72, 56)
	inv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inv.disabled = block != ""
	if block == "":
		inv.add_theme_color_override("font_color", UiTheme.GOLD)
		inv.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.85), 10, 2, 6))
	inv.pressed.connect(func() -> void:
		if Profile.invest(id):
			_save()
		_rebuild.call_deferred())
	h.add_child(inv)
	return pc


func _save() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
