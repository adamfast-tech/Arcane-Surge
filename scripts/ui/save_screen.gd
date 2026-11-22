class_name SaveScreen
extends Control
## Sauvegarde (Havre-Aube) : progression de cet appareil et du compte Académie, envoi ou
## récupération manuels, versions précédentes gardées par le serveur, copies de secours locales.
## Chaque remplacement demande une confirmation et garde une copie de secours.

signal back
signal open_login

var _col: VBoxContainer
var _overlay: Control
var _remote: Variant = null ## null : inconnu ou injoignable ; {} : aucune sauvegarde en ligne
var _history: Array = []
var _loading := false
var _busy := false
var _msg := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.7)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rebuild()
	_load_remote()


func _online() -> bool:
	return Cloud.instance != null and Cloud.instance.is_online()


func _load_remote() -> void:
	if not _online():
		return
	_loading = true
	_rebuild()
	_remote = await Cloud.instance.fetch_remote()
	_history = await Cloud.instance.fetch_history()
	_loading = false
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		if ch is ScrollContainer:
			ch.queue_free()
	_col = UiTheme.scroll_column(self, 680.0, 16.0)
	move_child(_overlay, get_child_count() - 1)
	var head := HBoxContainer.new()
	_col.add_child(head)
	var b := UiTheme.back_button("Havre-Aube")
	b.pressed.connect(func() -> void: back.emit())
	head.add_child(b)
	head.add_child(UiTheme.spacer())
	_col.add_child(UiTheme.title("SAUVEGARDE", 46, UiTheme.GOLD))
	_col.add_child(UiTheme.wrap("Choisis quelle progression garder. Avant chaque remplacement, une copie de secours est gardée.", 18, UiTheme.MUTED))
	if _msg != "":
		_col.add_child(UiTheme.wrap(_msg, 19, UiTheme.TEAL))
	# Cet appareil.
	var dev: Array = UiTheme.card(UiTheme.BORDER, 16)
	_col.add_child(dev[0])
	_card_head(dev[1], "rune", "CET APPAREIL")
	(dev[1] as VBoxContainer).add_child(UiTheme.label(Profile.summary(Profile.data), 21))
	(dev[1] as VBoxContainer).add_child(UiTheme.label("Sauvegardée le %s" % Profile.save_date(Profile.data), 17, UiTheme.MUTED))
	# Compte Académie.
	var acc: Array = UiTheme.card(UiTheme.BORDER, 16)
	_col.add_child(acc[0])
	var av: VBoxContainer = acc[1]
	_card_head(av, "cloud", "COMPTE ACADÉMIE" + (" · %s" % Cloud.instance.username if _online() else ""))
	if not _online():
		av.add_child(UiTheme.wrap("Non connecté : ta progression n'est enregistrée que sur cet appareil. Connecte-toi pour l'envoyer sur ton compte.", 18, UiTheme.MUTED))
		var login := _primary("Se connecter")
		login.pressed.connect(func() -> void: open_login.emit())
		av.add_child(login)
	elif _loading:
		av.add_child(UiTheme.label("Lecture de la sauvegarde en ligne…", 18, UiTheme.MUTED))
	elif typeof(_remote) == TYPE_NIL:
		av.add_child(UiTheme.label("Sauvegarde en ligne injoignable.", 18, UiTheme.GOLD))
		if Cloud.instance.last_error != "":
			av.add_child(UiTheme.label("(%s)" % Cloud.instance.last_error, 15, UiTheme.MUTED))
		var retry := UiTheme.button("Réessayer", 19)
		retry.custom_minimum_size = Vector2(0, 52)
		retry.pressed.connect(_load_remote)
		av.add_child(retry)
	elif (_remote as Dictionary).is_empty():
		av.add_child(UiTheme.label("Aucune sauvegarde sur le compte.", 19, UiTheme.MUTED))
	else:
		av.add_child(UiTheme.label(Profile.summary(_remote), 21))
		av.add_child(UiTheme.label("Sauvegardée le %s" % Profile.save_date(_remote), 17, UiTheme.MUTED))
	if _online() and not _loading:
		var up := _primary("Envoyer cette progression sur le compte")
		up.pressed.connect(func() -> void: _confirm("Envoyer sur le compte ?",
			"La sauvegarde du compte sera remplacée par celle de cet appareil :\n%s" % Profile.summary(Profile.data),
			_do_push))
		_col.add_child(up)
		if _remote is Dictionary and not (_remote as Dictionary).is_empty():
			var down := UiTheme.button("Utiliser la sauvegarde du compte", 20)
			down.custom_minimum_size = Vector2(0, 60)
			var rd: Dictionary = _remote
			down.pressed.connect(func() -> void: _confirm("Utiliser la sauvegarde du compte ?",
				"La progression de cet appareil sera remplacée par :\n%s" % Profile.summary(rd),
				_do_adopt.bind(rd, "Sauvegarde du compte chargée.")))
			_col.add_child(down)
		if not _history.is_empty():
			_col.add_child(UiTheme.section("Versions précédentes du compte"))
			for h in _history:
				if h is Dictionary and h.get("data") is Dictionary:
					_col.add_child(_version_row(h["data"], "Version du compte"))
	var backups: Array = []
	for t in [["appareil", "Copie de cet appareil (avant le dernier remplacement)"], ["compte", "Copie d'une sauvegarde du compte"]]:
		var d := Profile.read_backup(str(t[0]))
		if not d.is_empty():
			backups.append([d, str(t[1])])
	if not backups.is_empty():
		_col.add_child(UiTheme.section("Copies de secours de cet appareil"))
		for bk in backups:
			_col.add_child(_version_row(bk[0], str(bk[1])))


func _card_head(v: VBoxContainer, icon: String, text: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(UiTheme.icon_rect(icon, 22))
	h.add_child(UiTheme.section(text, UiTheme.TEAL))


func _primary(text: String) -> Button:
	var b := UiTheme.button(text, 20)
	b.custom_minimum_size = Vector2(0, 62)
	b.add_theme_color_override("font_color", UiTheme.GOLD)
	b.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.WARM, 0.94), Color(UiTheme.GOLD, 0.85), 14, 2, 8, UiTheme.GOLD))
	b.add_theme_stylebox_override("hover", UiTheme.box(Color(UiTheme.WARM.lightened(0.05), 0.96), UiTheme.GOLD, 14, 2, 8, UiTheme.GOLD))
	return b


func _version_row(d: Dictionary, label: String) -> PanelContainer:
	var c: Array = UiTheme.card(UiTheme.BORDER, 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	(c[1] as VBoxContainer).add_child(h)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiTheme.label(label, 16, UiTheme.MUTED))
	v.add_child(UiTheme.wrap(Profile.summary(d), 19))
	v.add_child(UiTheme.label("Sauvegardée le %s" % Profile.save_date(d), 16, UiTheme.MUTED))
	var r := UiTheme.button("Restaurer", 18)
	r.custom_minimum_size = Vector2(120, 52)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.pressed.connect(func() -> void: _confirm("Restaurer cette version ?",
		"La progression de cet appareil%s sera remplacée par :\n%s" % [" et du compte" if _online() else "", Profile.summary(d)],
		_do_adopt.bind(d, "Version restaurée.")))
	h.add_child(r)
	return c[0]


# ---------------------------------------------------------------- actions

func _do_push() -> void:
	await Cloud.instance.push(true)
	_msg = "Progression de cet appareil envoyée sur le compte." if not Cloud.instance.message.begins_with("Échec") else Cloud.instance.message


func _do_adopt(d: Dictionary, done: String) -> void:
	if _online():
		await Cloud.instance.adopt(d)
	else:
		Profile.backup(Profile.data, "appareil")
		Profile.replace_with(d)
		Profile.save_local()
	_msg = done


## Fenêtre de confirmation ; l'action (asynchrone) s'exécute sur « Confirmer ».
func _confirm(title: String, text: String, action: Callable) -> void:
	if _busy:
		return
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(UiTheme.BG, 0.8)
	_overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var c: Array = UiTheme.card(UiTheme.GOLD, 22)
	(c[0] as PanelContainer).custom_minimum_size = Vector2(minf(600.0, size.x - 40.0), 0)
	center.add_child(c[0])
	var v: VBoxContainer = c[1]
	v.add_theme_constant_override("separation", 14)
	v.add_child(UiTheme.title(title, 30, UiTheme.GOLD))
	v.add_child(UiTheme.wrap(text, 19, UiTheme.TEXT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var cancel := UiTheme.button("Annuler", 20)
	cancel.custom_minimum_size = Vector2(0, 58)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(_close_confirm)
	row.add_child(cancel)
	var ok := _primary("Confirmer")
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.pressed.connect(func() -> void:
		if _busy:
			return
		_busy = true
		ok.text = "…"
		await action.call()
		_busy = false
		_close_confirm()
		_load_remote()
		_rebuild())
	row.add_child(ok)


func _close_confirm() -> void:
	for ch in _overlay.get_children():
		ch.queue_free()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
