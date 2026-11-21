class_name LoginScreen
extends Control
## Connexion avec le compte Académie (même pseudo et mot de passe), ou jeu sans compte.

signal done

var from_hub := false
var _id: LineEdit
var _pw: LineEdit
var _status: Label
var _go: Button
var _guest: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiTheme.backdrop(self, 0.55)
	var col := UiTheme.scroll_column(self, 560.0, 60.0)
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


func _login() -> void:
	if _id.text.strip_edges() == "" or _pw.text == "":
		_status.text = "Renseigne ton pseudo (ou e-mail) et ton mot de passe."
		return
	_go.disabled = true
	_guest.disabled = true
	_status.text = "Connexion…"
	var err: String = await Cloud.instance.login(_id.text, _pw.text)
	if err != "":
		_status.text = err
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
