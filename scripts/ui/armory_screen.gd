class_name ArmoryScreen
extends Control
## L'Armurerie d'Aldric (docs/design/44-armurerie-cosmetiques.md), depuis Havre-Aube :
## - ÉQUIPEMENT : un arrivage toutes les 5 h ; une vitrine (mythique 1 fois sur 8, épique ou légendaire 1 fois
##   sur 6) et 6 offres courantes, à acheter avec de l'or, comparées à l'équipement porté ;
## - CURIOSITÉS : 8 kits de cosmétiques insolites (tête, tenue, dos, arme), portés par-dessus l'équipement ;
##   un kit donne un bonus à 2 pièces et un bonus spécial à 4. Un essayage en volume montre le héros avec.

signal back

const ALDRIC := Color("e0a050")
const TABS := [["equip", "ÉQUIPEMENT", "forge", "Arrivage toutes les 5 h"], ["curios", "CURIOSITÉS", "sparkle", "Kits cosmétiques"]]

## Bruits de la boutique, un par arrivage.
const RUMORS: Array[String] = [
	"Les caisses arrivent par la route des Collines. Parfois, une merveille dort sous la paille.",
	"Aldric garde sa plus belle pièce pour la vitrine. Certains jours, elle brille plus que d'habitude.",
	"On raconte qu'une lame mythique est passée par ici. Elle n'est pas restée une heure.",
	"Tout ce qui est ici a été aiguisé et poli par Aldric lui-même. Enfin, presque tout.",
	"Ce qui part ne revient jamais : la charrette ne repasse pas deux fois avec la même cargaison.",
	"Plus tu vas loin, plus Aldric fait venir du solide. Il suit tes exploits de près.",
	"Le perroquet du comptoir n'est pas à vendre. Il a essayé de mordre le dernier qui a demandé.",
	"Une rumeur court : les clients patients repartent avec ce qui brille le plus.",
]

var _tab := "equip"
var _msg := ""
var _msg_col := UiTheme.GOLD
var _try: Dictionary = {} ## essayage : {emplacement: pièce}
var _kit := "" ## kit dont on regarde une pièce
var _piece := "" ## pièce choisie (achat, port)
var _count: Label
var _left := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.55, 0.0, "forge", "armurerie")
	var tm := Timer.new()
	tm.wait_time = 1.0
	tm.autostart = true
	tm.timeout.connect(_tick)
	add_child(tm)
	_rebuild()


## Compte à rebours de l'arrivage ; à zéro, le nouvel arrivage s'affiche.
func _tick() -> void:
	var left := Profile.shop_seconds_left()
	if left > _left and _left > 0:
		_rebuild()
		return
	_left = left
	if is_instance_valid(_count):
		_count.text = _clock(left)


static func _clock(s: int) -> String:
	return "%d h %02d min %02d s" % [s / 3600, (s % 3600) / 60, s % 60]


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
	head.add_child(GearUi.purse())
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	col.add_child(tv)
	tv.add_child(UiTheme.title("ARMURERIE", 46, UiTheme.GOLD))
	tv.add_child(UiTheme.title("LA BOUTIQUE D'ALDRIC", 20, UiTheme.TEXT))
	col.add_child(GearUi.speaker_banner("aldric", "Aldric", "Armurier et marchand de curiosités", _msg if _msg != "" else _line(),
		_msg_col if _msg != "" else UiTheme.TEXT, ALDRIC))
	col.add_child(_tabs())
	if _tab == "curios":
		_curios(col)
	else:
		_equip(col)


func _line() -> String:
	if _tab == "curios":
		return "Mes curiosités ne te rendront pas invincible… enfin, un peu plus solide. Et tellement plus élégant."
	var offers := Profile.shop_offers()
	var show: Dictionary = (offers[0] as Dictionary) if not offers.is_empty() else {}
	var rar := str((show.get("item", {}) as Dictionary).get("rarity", ""))
	if not bool(show.get("sold", true)) and rar == "mythique":
		return "Regarde-moi cette vitrine… un mythique. Ça ne m'arrive presque jamais. Il ne restera pas."
	if not bool(show.get("sold", true)) and rar in ["legendaire", "epique"]:
		return "Belle pièce en vitrine aujourd'hui. À ta place, je ne la laisserais pas filer."
	return "Arrivage frais ! Le prochain dans quelques heures : ce qui brille ne reste jamais longtemps."


func _tabs() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for t in TABS:
		var id := str(t[0])
		var on := id == _tab
		var rb: Array = UiTheme.rich_button(70, "primary" if on else "tile")
		var bt: Button = rb[0]
		var h: HBoxContainer = rb[1]
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 8)
		h.add_child(UiTheme.icon_rect(str(t[2]), 24, ALDRIC if on else UiTheme.MUTED))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(v)
		v.add_child(UiTheme.label(str(t[1]), 18, UiTheme.GOLD if on else UiTheme.TEXT))
		v.add_child(UiTheme.label(str(t[3]), 13, UiTheme.MUTED))
		bt.pressed.connect(func() -> void:
			Snd.click()
			_tab = id
			_msg = ""
			_rebuild.call_deferred())
		row.add_child(bt)
	return row


func _say(text: String, c: Color = UiTheme.GOLD) -> void:
	_msg = text
	_msg_col = c


func _save() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()


# ---------------------------------------------------------------- équipement

func _equip(col: VBoxContainer) -> void:
	var offers := Profile.shop_offers()
	_left = Profile.shop_seconds_left()
	# Arrivage : compte à rebours et chances de la vitrine.
	var c: Array = UiTheme.card(Color(ALDRIC, 0.45), 12)
	col.add_child(c[0])
	var v: VBoxContainer = c[1]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(UiTheme.icon_rect("moon", 22, ALDRIC))
	h.add_child(UiTheme.label("Prochain arrivage dans", 16, UiTheme.MUTED))
	_count = UiTheme.label(_clock(_left), 18, UiTheme.GOLD)
	h.add_child(_count)
	# Un bruit de boutique, qui change à chaque arrivage.
	var rumor := HBoxContainer.new()
	rumor.add_theme_constant_override("separation", 8)
	v.add_child(rumor)
	var ri := UiTheme.icon_rect("sparkle", 16, Color(ALDRIC, 0.7))
	ri.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rumor.add_child(ri)
	var rl := UiTheme.wrap(RUMORS[posmod(Profile.shop_period(), RUMORS.size())], 14, Color(UiTheme.TEXT, 0.72))
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rumor.add_child(rl)
	if offers.is_empty():
		return
	col.add_child(UiTheme.section("Vitrine du jour", ALDRIC))
	col.add_child(_offer_card(0, offers[0], true))
	col.add_child(UiTheme.section("Arrivage courant"))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	col.add_child(g)
	for i in range(1, offers.size()):
		g.add_child(_offer_card(i, offers[i], false))


## Une offre : l'objet, sa rareté, ses stats, la comparaison avec l'équipé et le bouton d'achat.
func _offer_card(i: int, o: Dictionary, big: bool) -> PanelContainer:
	var it: Dictionary = o["item"]
	var sold := bool(o.get("sold", false))
	var rcol := Profile.item_color(it)
	var c: Array = UiTheme.card(Color(rcol, 0.75 if big else 0.5), 14 if big else 10)
	var pc: PanelContainer = c[0]
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if sold:
		pc.modulate = Color(1, 1, 1, 0.5)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 8)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var slot := str(Profile.base_of(it).get("slot", ""))
	var stage := Control.new()
	var px := 112 if big else 70
	stage.custom_minimum_size = Vector2(px + 12, px + 12)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(stage)
	if big:
		stage.add_child(GearUi.pedestal(rcol, px + 12, px + 12))
	var tile := GearUi.item_button(it, slot, px)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.position = Vector2(6, 6)
	stage.add_child(tile)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	if big:
		info.add_child(UiTheme.label("VITRINE", 14, ALDRIC))
	var nm := UiTheme.label(Profile.item_name(it), 22 if big else 17, rcol)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(nm)
	var slot_name := str((Profile.items_db()["slots"] as Dictionary).get(slot, slot))
	info.add_child(UiTheme.label("%s · %s · iLvl %d" % [str(Profile.rarity_of(it).get("name", "")), slot_name, int(it.get("ilvl", 1))], 14 if big else 13, UiTheme.MUTED))
	info.add_child(GearUi.stat_chips(Profile.item_stats(it), 15 if big else 13))
	var cmp := Profile.compare_to_equipped("player", it)
	if str(cmp.get("vs", "")) == "":
		info.add_child(UiTheme.label("Emplacement libre chez toi", 14, UiTheme.GOOD))
	else:
		var pw := int(cmp.get("power", 0))
		info.add_child(UiTheme.label(("Mieux que l'équipé · Puissance +%d" % pw) if pw > 0 else ("Moins bien que l'équipé (%d)" % pw if pw < 0 else "Équivalent à l'équipé"), 14, UiTheme.GOOD if pw > 0 else UiTheme.MUTED))
	var why := Profile.shop_buy_block(i)
	var buy := UiTheme.button("VENDU" if sold else "ACHETER · %d or" % int(o["price"]), 19 if big else 16)
	buy.icon = Icons.tex("coin", 40)
	buy.add_theme_constant_override("icon_max_width", 18)
	buy.custom_minimum_size = Vector2(0, 56 if big else 48)
	buy.disabled = why != ""
	if why == "":
		buy.add_theme_color_override("font_color", UiTheme.GOLD)
		buy.add_theme_color_override("icon_normal_color", UiTheme.GOLD)
		buy.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.95), Color(UiTheme.GOLD, 0.9), 12, 2, 8, UiTheme.GOLD))
	buy.pressed.connect(func() -> void:
		var got := Profile.shop_buy(i)
		if not got.is_empty():
			Snd.sfx("loot_rare" if str(got["rarity"]) in ["epique", "legendaire", "mythique"] else "loot", -4.0)
			_say("%s est à toi ! Il t'attend dans ta réserve (Équipement)." % Profile.item_name(got))
			_save()
		_rebuild.call_deferred())
	v.add_child(buy)
	if why == "Or insuffisant":
		var poor := UiTheme.label("Il te manque %d or" % (int(o["price"]) - Profile.gold()), 13, UiTheme.FIRE)
		poor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(poor)
	return pc


# ---------------------------------------------------------------- curiosités

func _curios(col: VBoxContainer) -> void:
	var worn := Profile.worn_cosmetics()
	var look := worn.duplicate()
	for k in _try.keys():
		look[k] = _try[k]
	# Essayage : le héros en volume, avec les pièces portées et celles qu'on essaie.
	var c: Array = UiTheme.card(Color(ALDRIC, 0.45), 12)
	col.add_child(c[0])
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 6)
	var top := HBoxContainer.new()
	v.add_child(top)
	top.add_child(UiTheme.label("ESSAYAGE", 17, ALDRIC))
	top.add_child(UiTheme.spacer())
	if not _try.is_empty():
		var rst := UiTheme.button("Retirer l'essai", 14)
		rst.custom_minimum_size = Vector2(0, 38)
		rst.pressed.connect(func() -> void:
			_try.clear()
			_rebuild.call_deferred())
		top.add_child(rst)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, float(HeroModel.H * HeroTurntable.SCALE) + 30.0)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(stage)
	var ped := GearUi.pedestal(ALDRIC, 230, 60)
	ped.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	ped.offset_left = -115
	ped.offset_right = 115
	ped.offset_top = -64
	ped.offset_bottom = -4
	stage.add_child(ped)
	var tt := HeroTurntable.new()
	tt.setup(Profile.look(), Profile.race(), Profile.player_class(), look)
	tt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	var hw := float(HeroModel.W * HeroTurntable.SCALE) * 0.5
	tt.offset_left = -hw
	tt.offset_right = hw
	tt.offset_top = -16.0 - float(HeroModel.H * HeroTurntable.SCALE)
	tt.offset_bottom = -16.0
	stage.add_child(tt)
	var hint := UiTheme.label("Glisse pour le faire tourner · pièces essayées en surbrillance", 13, Color(UiTheme.MUTED, 0.85))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	# Bonus des kits portés.
	var counts := Profile.cosmetic_kit_counts()
	var kits: Dictionary = Profile.cosmetics_db()["kits"]
	var active: Array[String] = []
	for kit in counts.keys():
		var n := int(counts[kit])
		if n >= 2 and kits.has(kit):
			active.append("%s : %s" % [str(kits[kit]["name"]), str(kits[kit]["bonus2"]["text"]) + (", " + str(kits[kit]["bonus4"]["text"]) if n >= 4 else "")])
	if not active.is_empty():
		v.add_child(UiTheme.wrap("Bonus actifs · " + " · ".join(active), 14, UiTheme.GOOD))
	col.add_child(UiTheme.wrap("Les pièces se portent par-dessus ton équipement (Équipement, « Apparence »). 2 pièces d'un même kit donnent un bonus ; le kit complet, un bonus spécial.", 15, UiTheme.MUTED))
	for kit in kits.keys():
		col.add_child(_kit_card(str(kit), kits[kit], worn))


## Un kit : son nom, son thème, ses 4 pièces, ses bonus ; la pièce choisie s'achète ou se porte.
func _kit_card(kit: String, kd: Dictionary, worn: Dictionary) -> PanelContainer:
	var kc := Color(str(kd["color"]))
	var c: Array = UiTheme.card(Color(kc, 0.55) if kit == _kit else UiTheme.BORDER, 12)
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 8)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	tv.add_child(UiTheme.title(str(kd["name"]).to_upper(), 22, kc))
	tv.add_child(UiTheme.label(str(kd["theme"]), 14, UiTheme.MUTED))
	var owned := 0
	var wearing := 0
	for slot in kd["pieces"].keys():
		var pid := "%s.%s" % [kit, slot]
		if Profile.cosmetic_owned(pid):
			owned += 1
		if str(worn.get(slot, "")) == pid:
			wearing += 1
	h.add_child(GearUi.pill("%d / 4" % owned, kc, 14))
	var try_all := UiTheme.button("Essayer", 14)
	try_all.custom_minimum_size = Vector2(0, 38)
	try_all.pressed.connect(func() -> void:
		for slot2 in kd["pieces"].keys():
			_try[str(slot2)] = "%s.%s" % [kit, slot2]
		_kit = kit
		_piece = ""
		_rebuild.call_deferred())
	h.add_child(try_all)
	# Les 4 pièces.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	for slot in ["tete", "tenue", "dos", "arme"]:
		var pid := "%s.%s" % [kit, slot]
		var mine := Profile.cosmetic_owned(pid)
		var on := str(worn.get(slot, "")) == pid
		var picked := pid == _piece
		var rb: Array = UiTheme.rich_button(196, "tile")
		var bt: Button = rb[0]
		var bh: HBoxContainer = rb[1]
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bd := UiTheme.GOLD if picked else (kc if on else Color(kc, 0.35))
		bt.add_theme_stylebox_override("normal", UiTheme.box(Color(kc.darkened(0.85), 0.95), bd, 12, 2 if picked or on else 1, 6, UiTheme.GOLD if picked else Color(0, 0, 0, 0)))
		var pv := VBoxContainer.new()
		pv.add_theme_constant_override("separation", 2)
		pv.alignment = BoxContainer.ALIGNMENT_CENTER
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bh.add_child(pv)
		var th := CosmeticThumb.make(pid, 84, mine or picked)
		th.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pv.add_child(th)
		var nl := UiTheme.label(str(kd["pieces"][slot]), 12, UiTheme.TEXT if mine else UiTheme.MUTED)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.custom_minimum_size = Vector2(60, 0)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.add_child(nl)
		var tag := "PORTÉ" if on else ("À TOI" if mine else "%d or" % int(kd["price"]))
		var tl := UiTheme.label(tag, 12, UiTheme.GOOD if on else (UiTheme.TEAL if mine else UiTheme.GOLD))
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.add_child(tl)
		bt.pressed.connect(func() -> void:
			Snd.click()
			_kit = kit
			_piece = pid
			_try[slot] = pid
			_rebuild.call_deferred())
		row.add_child(bt)
	# Bonus du kit.
	v.add_child(UiTheme.label("2 pièces : %s" % str(kd["bonus2"]["text"]), 14, UiTheme.GOOD if wearing >= 2 else UiTheme.MUTED))
	v.add_child(UiTheme.label("Kit complet : %s" % str(kd["bonus4"]["text"]), 14, UiTheme.GOOD if wearing >= 4 else UiTheme.MUTED))
	# Action sur la pièce choisie dans ce kit.
	if _kit == kit and _piece != "":
		var info := Profile.cosmetic_info(_piece)
		var slot3 := str(info["slot"])
		var act := HBoxContainer.new()
		act.add_theme_constant_override("separation", 8)
		v.add_child(act)
		var al := UiTheme.label(str(info["name"]), 16, kc)
		al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		act.add_child(al)
		var pid2 := _piece
		if not Profile.cosmetic_owned(pid2):
			var why := Profile.cosmetic_buy_block(pid2)
			var buy := UiTheme.button("ACHETER · %d or" % int(info["price"]), 16)
			buy.icon = Icons.tex("coin", 40)
			buy.add_theme_constant_override("icon_max_width", 18)
			buy.custom_minimum_size = Vector2(200, 48)
			buy.disabled = why != ""
			if why == "":
				buy.add_theme_color_override("font_color", UiTheme.GOLD)
				buy.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.95), Color(UiTheme.GOLD, 0.9), 12, 2, 8, UiTheme.GOLD))
			buy.pressed.connect(func() -> void:
				if Profile.buy_cosmetic(pid2):
					Profile.wear_cosmetic(slot3, pid2)
					Snd.sfx("loot_rare", -5.0)
					_say("%s : à toi, et déjà sur ton dos. Fière allure !" % str(info["name"]))
					_save()
				_rebuild.call_deferred())
			act.add_child(buy)
			if why == "Or insuffisant":
				var poor := UiTheme.label("Il te manque %d or" % (int(info["price"]) - Profile.gold()), 13, UiTheme.FIRE)
				v.add_child(poor)
		else:
			var on2 := str(worn.get(slot3, "")) == pid2
			var wb := UiTheme.button("RETIRER" if on2 else "PORTER", 16)
			wb.custom_minimum_size = Vector2(160, 48)
			if not on2:
				wb.add_theme_color_override("font_color", UiTheme.TEAL)
			wb.pressed.connect(func() -> void:
				Profile.wear_cosmetic(slot3, "" if on2 else pid2)
				_try.erase(slot3)
				Snd.click()
				_save()
				_rebuild.call_deferred())
			act.add_child(wb)
	# Acheter les pièces manquantes d'un coup.
	var missing: Array[String] = []
	for slot4 in kd["pieces"].keys():
		if not Profile.cosmetic_owned("%s.%s" % [kit, slot4]):
			missing.append("%s.%s" % [kit, slot4])
	if missing.size() >= 2:
		var total := missing.size() * int(kd["price"])
		var kb := UiTheme.button("ACHETER LES %d PIÈCES MANQUANTES · %d or" % [missing.size(), total], 15)
		kb.custom_minimum_size = Vector2(0, 46)
		kb.disabled = Profile.gold() < total
		kb.pressed.connect(func() -> void:
			if Profile.gold() >= total:
				for pid3 in missing:
					Profile.buy_cosmetic(pid3)
					Profile.wear_cosmetic(Profile.cosmetic_info(pid3)["slot"], pid3)
				Snd.sfx("loot_rare", -3.0)
				_say("Le kit %s complet ! Bonus : %s." % [str(kd["name"]), str(kd["bonus4"]["text"])])
				_try.clear()
				_save()
			_rebuild.call_deferred())
		v.add_child(kb)
	return c[0]
