class_name SkillTreeScreen
extends Control
## Entraînement : arbre de compétences de la classe (docs/design/36-arbres-competences.md). Chaque branche
## est un vrai arbre : 7 paliers de médaillons reliés (SkillTreeView), du palier ouvert d'office jusqu'aux
## Clés de voûte ; une compétence s'ouvre avec assez de points dans la branche et un rang dans une compétence
## reliée au-dessus. Toucher un médaillon affiche son effet dans le panneau du bas, d'où l'on investit.

signal back

var _branch := ""
var _reset_armed := false
var _sel := "" ## compétence sélectionnée
var _detail: PanelContainer
var _pts_label: Label
var _info_label: Label
var _tab_buttons: Dictionary = {} ## branche -> bouton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.5, 0.0, "gold", "entrainement")
	var branches: Array = Profile.tree_db().get("branches", [])
	_branch = str(branches[0]["id"]) if not branches.is_empty() else ""
	_rebuild()
	resized.connect(_place_detail)


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
	_pts_label = pts
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("ENTRAÎNEMENT", 46, UiTheme.GOLD))
	var cname := str((GameData.party()["classes"] as Dictionary).get(Profile.player_class(), {}).get("name", "Mage")).to_upper()
	tv.add_child(UiTheme.title(("ARBRE DE L'" if cname.substr(0, 1) in ["A", "E", "É", "I", "O", "U"] else "ARBRE DU ") + cname, 22, UiTheme.TEXT))
	_info_label = UiTheme.wrap("", 18, UiTheme.MUTED)
	col.add_child(_info_label)
	if Profile.meditation_unlocked():
		col.add_child(UiTheme.wrap("Changer de voie et enregistrer jusqu'à 3 configurations : Salle de méditation.", 16, UiTheme.TEAL))
	# Onglets des branches.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	col.add_child(tabs)
	var current: Dictionary = {}
	for br in Profile.tree_db().get("branches", []):
		var id := str(br["id"])
		var bc := Color(str(br.get("color", "6fdccf")))
		var locked: bool = Profile.branch_locked(br) != ""
		var t := UiTheme.button("%s\n%s" % [str(br["name"]), "Acte 3" if locked else "%d points" % Profile.branch_spent(br)], 18)
		_tab_buttons[id] = t
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
			_sel = ""
			_rebuild.call_deferred())
		tabs.add_child(t)
	# Héritage racial : arbre de la race, points d'héritage.
	var ri: Dictionary = (GameData.party()["races"] as Dictionary).get(Profile.race(), {})
	var rc := Color(str(ri.get("color", "F2C46B")))
	var ht := UiTheme.button("Héritage\n%d / %d pts" % [Profile.heritage_spent(), Profile.heritage_total()], 18)
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ht.custom_minimum_size = Vector2(0, 70)
	ht.icon = Icons.tex("sparkle", 40)
	ht.add_theme_constant_override("icon_max_width", 20)
	ht.add_theme_color_override("icon_normal_color", rc)
	if _branch == "heritage":
		ht.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL2, 0.96), rc, 12, 2, 8, rc))
		ht.add_theme_color_override("font_color", rc)
	ht.pressed.connect(func() -> void:
		_branch = "heritage"
		_sel = ""
		_rebuild.call_deferred())
	tabs.add_child(ht)
	_refresh_counts()
	if _branch == "heritage":
		_show_detail(false)
		_heritage_view(col, ri, rc)
		return
	if current.is_empty():
		return
	var bc2 := Color(str(current.get("color", "6fdccf")))
	# Bannière de la branche.
	var banner: Array = UiTheme.card(Color(bc2, 0.7), 12)
	col.add_child(banner[0])
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 12)
	(banner[1] as VBoxContainer).add_child(bh)
	bh.add_child(UiTheme.icon_rect(str(current.get("icon", "rune")), 40, bc2))
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 0)
	bv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(bv)
	bv.add_child(UiTheme.title(str(current["name"]).to_upper(), 26, bc2))
	bv.add_child(UiTheme.wrap(str(current.get("theme", "")), 16, UiTheme.MUTED))
	if Profile.branch_locked(current) != "":
		var c: Array = UiTheme.card(UiTheme.BORDER, 16)
		col.add_child(c[0])
		var h := HBoxContainer.new()
		(c[1] as VBoxContainer).add_child(h)
		h.add_child(UiTheme.icon_rect("lock", 28, UiTheme.MUTED))
		# Le texte prend toute la largeur restante (sinon il se replie lettre par lettre).
		var why := UiTheme.wrap(Profile.branch_locked(current), 19, UiTheme.MUTED)
		why.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(why)
		_show_detail(false)
		return
	var spent := Profile.branch_spent(current)
	var next_req := -1
	for tier in current.get("tiers", []):
		if int(tier.get("req", 0)) > spent:
			next_req = int(tier["req"])
			break
	bv.add_child(UiTheme.label("%d points investis%s" % [spent, (" · palier suivant à %d" % next_req) if next_req > 0 else " · tous les paliers ouverts"], 17, UiTheme.GOLD))
	col.add_child(UiTheme.wrap("Rond : passif · carré : nouveau sort · hexagone : évolution · losange : Clé de voûte (2 au plus). Une compétence s'ouvre quand la branche a assez de points (chiffre à gauche) et qu'une compétence reliée au-dessus a au moins un rang.", 15, UiTheme.MUTED))
	var tree := SkillTreeView.new()
	tree.setup(current, _sel)
	tree.picked.connect(func(id: String) -> void:
		_sel = id
		_refresh_detail())
	col.add_child(tree)
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
	# Place pour le panneau de détail, fixé en bas de l'écran.
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 230)
	col.add_child(pad)
	_show_detail(true)
	_refresh_detail()


## Arbre racial : passifs, Don racial et 5 nœuds de 3 rangs payés en points d'héritage.
func _heritage_view(col: VBoxContainer, ri: Dictionary, rc: Color) -> void:
	var free := Profile.heritage_total() - Profile.heritage_spent()
	col.add_child(UiTheme.label("Héritage %s · %d point%s disponible%s" % [str(ri.get("name", "")).to_lower(), free, "s" if free > 1 else "", "s" if free > 1 else ""], 22, rc))
	col.add_child(UiTheme.wrap("1 point d'héritage tous les 10 niveaux, plus 1 par acte terminé (boss de fin de zone vaincu).", 16, UiTheme.MUTED))
	var c: Array = UiTheme.card(Color(rc, 0.6), 12)
	col.add_child(c[0])
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 2)
	v.add_child(UiTheme.label("Passifs de race", 18, rc))
	for ps in ri.get("passives", []):
		v.add_child(UiTheme.wrap("· " + str(ps), 16, UiTheme.TEXT))
	v.add_child(UiTheme.label("Don racial · recharge %d s (bouton DON, touche D)" % int(Profile.don_info().get("cd", 0)), 18, UiTheme.GOLD))
	v.add_child(UiTheme.wrap(str(ri.get("don", "")), 16, UiTheme.TEXT))
	col.add_child(UiTheme.section("Arbre d'héritage", rc))
	for node in Profile.race_tree():
		var id := str(node["id"])
		var rank := Profile.race_rank(id)
		var mx := int(node.get("max", 3))
		var nc: Array = UiTheme.card(Color(rc, 0.85) if rank > 0 else UiTheme.BORDER, 12)
		col.add_child(nc[0])
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		(nc[1] as VBoxContainer).add_child(h)
		h.add_child(UiTheme.icon_rect("sparkle", 30, rc))
		var nv := VBoxContainer.new()
		nv.add_theme_constant_override("separation", 0)
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nv)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 8)
		nv.add_child(top)
		top.add_child(UiTheme.label(str(node["name"]), 22, rc))
		top.add_child(UiTheme.label("%d / %d" % [rank, mx], 15, UiTheme.GOLD if rank > 0 else UiTheme.MUTED))
		nv.add_child(UiTheme.wrap(str(node.get("desc", "")), 17, UiTheme.MUTED))
		var block := Profile.race_invest_block(id)
		var inv := UiTheme.button("+1" if rank < mx else "MAX", 22)
		inv.custom_minimum_size = Vector2(72, 56)
		inv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		inv.disabled = block != ""
		if block == "":
			inv.add_theme_color_override("font_color", UiTheme.GOLD)
			inv.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.85), 10, 2, 6))
		inv.pressed.connect(func() -> void:
			if Profile.race_invest(id):
				_save()
			_rebuild.call_deferred())
		h.add_child(inv)


## Compteurs de points (en-tête, ligne d'info, onglets), mis à jour sans reconstruire l'écran.
func _refresh_counts() -> void:
	if _pts_label != null and is_instance_valid(_pts_label):
		_pts_label.text = "%d point%s" % [Profile.skill_points_free(), "s" if Profile.skill_points_free() > 1 else ""]
	if _info_label != null and is_instance_valid(_info_label):
		_info_label.text = "Points : %d disponibles sur %d · Clés de voûte : %d / %d · 1 point par niveau à partir du niveau 2." % [
			Profile.skill_points_free(), Profile.skill_points_total(), Profile.keystones_taken(), int(Profile.tree_db().get("keystone_limit", 2))]
	for br in Profile.tree_db().get("branches", []):
		var t: Button = _tab_buttons.get(str(br["id"]))
		if t != null and is_instance_valid(t):
			t.text = "%s\n%s" % [str(br["name"]), "Acte 3" if Profile.branch_locked(br) != "" else "%d points" % Profile.branch_spent(br)]


func _show_detail(on: bool) -> void:
	if _detail == null or not is_instance_valid(_detail):
		_detail = PanelContainer.new()
		_detail.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_detail)
	_detail.visible = on
	move_child(_detail, -1)
	_place_detail()


func _place_detail() -> void:
	if _detail == null or not is_instance_valid(_detail):
		return
	var w := minf(size.x - 24.0, 680.0)
	_detail.custom_minimum_size = Vector2(w, 0)
	_detail.size = Vector2(w, 0)
	_detail.reset_size()
	_detail.position = Vector2((size.x - w) * 0.5, size.y - _detail.size.y - 12.0)


## Panneau du bas : la compétence sélectionnée, son effet, ce qui la bloque, et le bouton +1.
func _refresh_detail() -> void:
	if _detail == null or not is_instance_valid(_detail):
		return
	for ch in _detail.get_children():
		ch.queue_free()
	var f := Profile.find_node(_sel) if _sel != "" else []
	var br: Dictionary = f[0] if not f.is_empty() else {}
	var bc := Color(str(br.get("color", "6fdccf"))) if not br.is_empty() else UiTheme.TEAL
	_detail.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL2, 0.97), Color(bc, 0.9), 14, 2, 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_detail.add_child(v)
	if f.is_empty():
		v.add_child(UiTheme.wrap("Touche une compétence de l'arbre pour voir son effet et y investir un point.", 18, UiTheme.MUTED))
		_place_detail.call_deferred()
		return
	var node: Dictionary = f[2]
	var tier: Dictionary = f[1]
	var id := str(node["id"])
	var kind := str(node.get("kind", "passive"))
	var rank := Profile.skill_rank(id)
	var mx := int(node.get("max", 1))
	var tags := {"spell": "NOUVEAU SORT", "evolution": "ÉVOLUTION", "keystone": "CLÉ DE VOÛTE"}
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	h.add_child(UiTheme.icon_rect(SkillTreeView.node_icon(node), 42, bc))
	var nv := VBoxContainer.new()
	nv.add_theme_constant_override("separation", 0)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nv)
	nv.add_child(UiTheme.title(str(node["name"]), 24, bc if kind != "keystone" else UiTheme.GOLD))
	nv.add_child(UiTheme.label("%s · rang %d / %d · palier à %d points" % [str(tags.get(kind, "PASSIF")), rank, mx, int(tier.get("req", 0))], 15, UiTheme.GOLD if rank > 0 else UiTheme.MUTED))
	var block := Profile.invest_block(id)
	var inv := UiTheme.button("+1" if rank < mx else "MAX", 24)
	inv.custom_minimum_size = Vector2(84, 60)
	inv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inv.disabled = block != ""
	if block == "":
		inv.add_theme_color_override("font_color", UiTheme.GOLD)
		inv.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.85), 10, 2, 6))
	inv.pressed.connect(func() -> void:
		if Profile.invest(id):
			_save()
		_refresh_counts()
		_refresh_detail())
	h.add_child(inv)
	v.add_child(UiTheme.wrap(str(node.get("desc", "")), 18, UiTheme.TEXT))
	if block != "" and rank < mx:
		v.add_child(UiTheme.wrap(block, 16, UiTheme.FIRE if block.begins_with("Prérequis") or block.begins_with("Palier") else UiTheme.MUTED))
	elif rank >= mx:
		v.add_child(UiTheme.label("Compétence maîtrisée.", 16, UiTheme.GOLD))
	_place_detail.call_deferred()


func _save() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
