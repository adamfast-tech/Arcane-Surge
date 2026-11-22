class_name LoginScreen
extends Control
## Connexion avec le compte Académie (même pseudo et mot de passe), ou jeu sans compte.
## Version web : la saisie se fait dans de vrais champs HTML posés sur les champs du jeu
## (collage, trousseau iCloud et gestionnaires de mots de passe), voir WebForm.

signal done

var from_hub := false
var _id: LineEdit
var _pw: LineEdit
var _status: Label
var _go: Button
var _guest: Button
var _busy := false
var _web: JavaScriptObject = null
var _web_cb: JavaScriptObject = null
var _web_last := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.55)
	var col := UiTheme.scroll_column(self, 560.0, 60.0, true)
	var title := UiTheme.title("ARCANE SURGE", 60, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := UiTheme.label("Connexion avec ton compte Académie", 24, UiTheme.TEXT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var c: Array = UiTheme.card(UiTheme.GOLD, 20)
	col.add_child(c[0])
	var v: VBoxContainer = c[1]
	v.add_child(UiTheme.label("Pseudo ou e-mail", 20, UiTheme.MUTED))
	_id = LineEdit.new()
	_id.placeholder_text = "ton pseudo Académie"
	_id.custom_minimum_size = Vector2(0, 56)
	_id.add_theme_font_size_override("font_size", 24)
	v.add_child(_id)
	v.add_child(UiTheme.label("Mot de passe", 20, UiTheme.MUTED))
	_pw = LineEdit.new()
	_pw.secret = true
	_pw.custom_minimum_size = Vector2(0, 56)
	_pw.add_theme_font_size_override("font_size", 24)
	_pw.text_submitted.connect(func(_t: String) -> void: _login())
	v.add_child(_pw)
	_go = UiTheme.button("SE CONNECTER", 26)
	_go.custom_minimum_size = Vector2(0, 68)
	_go.add_theme_color_override("font_color", UiTheme.GOLD)
	_go.pressed.connect(_login)
	v.add_child(_go)
	_status = UiTheme.wrap("", 20, UiTheme.MUTED)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_status)
	_guest = UiTheme.button("Retour à Havre-Aube" if from_hub else "Jouer sans compte", 22)
	_guest.custom_minimum_size = Vector2(0, 60)
	_guest.pressed.connect(_play_guest)
	col.add_child(_guest)
	var note := UiTheme.wrap("Sans compte, la progression reste sur cet appareil. Tu pourras te connecter plus tard depuis Havre-Aube : elle sera alors envoyée sur ton compte.", 18, UiTheme.MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(note)
	if WebForm.available():
		_setup_web()


# ---------------------------------------------------------------- champs HTML (web)

func _setup_web() -> void:
	_web = WebForm.install(_id.placeholder_text, "")
	_web_cb = JavaScriptBridge.create_callback(_on_web_submit)
	_web.cb = _web_cb
	for e in [_id, _pw]:
		var le: LineEdit = e
		le.editable = false
		le.focus_mode = Control.FOCUS_NONE
		le.mouse_filter = Control.MOUSE_FILTER_IGNORE
		le.placeholder_text = ""


## Recale les champs HTML sur les champs Godot quand la mise en page bouge (défilement, rotation).
func _process(_delta: float) -> void:
	if _web == null:
		return
	var vis := get_viewport().get_visible_rect().size
	var data := JSON.stringify({"vw": vis.x, "vh": vis.y, "font": 24, "radius": 10, "user": _rect_of(_id), "pass": _rect_of(_pw)})
	if data != _web_last:
		_web_last = data
		_web.place(data)


func _rect_of(c: Control) -> Array:
	if not c.is_visible_in_tree():
		return [0, 0, 0, 0]
	var r := c.get_global_rect()
	return [r.position.x, r.position.y, r.size.x, r.size.y]


func _exit_tree() -> void:
	if _web != null:
		_web.remove()
		_web = null


func _on_web_submit(_args: Array) -> void:
	if _web == null:
		return
	var v: Variant = JSON.parse_string(str(_web.values()))
	if v is Dictionary:
		_do_login(str(v.get("u", "")), str(v.get("p", "")))


# ---------------------------------------------------------------- connexion

func _login() -> void:
	if _web != null:
		# Vraie soumission du formulaire HTML : le navigateur peut alors enregistrer le mot de passe.
		_web.submit()
		return
	_do_login(_id.text, _pw.text)


func _do_login(ident: String, password: String) -> void:
	if _busy:
		return
	if ident.strip_edges() == "" or password == "":
		_status.text = "Renseigne ton pseudo (ou e-mail) et ton mot de passe."
		return
	_busy = true
	_go.disabled = true
	_guest.disabled = true
	_status.text = "Connexion…"
	var err: String = await Cloud.instance.login(ident.strip_edges(), password)
	if err != "":
		_status.text = err
		_busy = false
		_go.disabled = false
		_guest.disabled = false
		return
	_status.text = "Connecté : %s. Synchronisation…" % Cloud.instance.username
	await Cloud.instance.sync_pull()
	done.emit()


func _play_guest() -> void:
	if not from_hub:
		Profile.data["settings"]["guest"] = true
		Profile.save_local()
	done.emit()
