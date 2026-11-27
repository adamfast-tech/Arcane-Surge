class_name CineStage
extends Control
## Mise en scène des dialogues (docs/design/41-cinematiques.md).
## - Personnages en grands bustes animés (entrée, respiration, bouche, clignements, réactions, actions),
##   créatures et esprits en « présence » au centre, avec leur aura.
## - Calques d'effets en pixel-art (SubViewport basse résolution) : lueurs, rayons, cercles runiques qui se
##   tracent, éclairs, failles, ondes de choc, entailles, volutes, particules ; bulles d'émotion.
## - Caméra : lent travelling, poussée et recul, mise au point sur un personnage, à-coups amortis (ressort).
## - Étalonnage des couleurs, bandes cinéma, fondus, ambiance animée du décor, feuilles qui tombent.
## Indications facultatives d'une réplique : « cam », « fx », « act », « grade », « emote » (voir play_cues).

const PLATE_MOOD := {
	"fracture": "arcane", "surge": "arcane", "nexus": "arcane", "college": "arcane", "sphinx": "arcane", "tour": "moon",
	"lysbourg": "dawn", "foret": "mist", "sentier": "mist", "clairiere": "mist", "roncier": "arcane", "fougeres": "mist", "cercle_fees": "arcane", "foret_gueri": "dawn", "source": "mist", "pont": "mist", "sylvarche": "arcane", "collines": "dawn",
	"steppe": "steppe", "moulins": "steppe", "campement": "campfire", "orage": "steppe", "traite": "steppe", "fort": "steppe",
	"route": "steppe", "pylones": "steppe", "gue": "steppe", "caravane": "steppe", "rebouteux": "campfire",
	"marais": "swamp", "cercle": "swamp", "hydre": "swamp", "refuge": "campfire",
	"pilotis": "swamp", "mares": "swamp", "brume": "swamp", "gue_morts": "swamp", "croc": "swamp", "barque": "swamp", "sorciere": "swamp",
	"pics": "snow", "porte": "snow", "lac": "snow", "forteresse": "snow", "colosse": "forge", "forge": "forge",
	"col": "snow", "congeres": "snow", "sentinelle": "snow", "aurore": "snow", "chariot": "snow", "portes": "snow",
	"dunes": "desert", "oasis": "desert", "miroirs": "desert", "desert_nuit": "moon",
	"mirage": "desert", "scarabee": "desert", "caravane_sable": "desert", "sceaux": "desert",
	"cendres": "cinder", "coulee": "cinder", "braisemont": "cinder", "nid": "cinder", "autels": "arcane", "citadelle": "cinder",
	"caldeira": "forge", "antre": "cinder", "lisiere_cendree": "cinder", "couloirs": "cinder", "ailes": "cinder", "drake": "cinder", "pardon": "dawn",
	"cite": "abyss", "quais": "abyss", "canal": "abyss", "statues": "abyss", "archives": "arcane", "palais": "abyss", "abysse": "abyss",
	"marees": "abyss", "kraken": "abyss", "cloche": "abyss", "portes_archives": "arcane", "sirenes": "abyss", "fil": "arcane", "fosse": "abyss",
}
## Décors où des feuilles tombent.
const LEAFY := ["foret", "foret_gueri", "source", "pont", "collines", "lysbourg", "sylvarche", "sentier", "clairiere", "fougeres", "cercle_fees", "roncier"]
## Créatures et esprits : ils apparaissent en présence au centre, pas en buste.
const PRESENCE := ["cerf", "sylvarche", "voix", "wyrm", "mere_dragon", "leviathan", "ourdisseur", "sphinx", "orrin", "morvaen", "varg", "gharok"]
## Sujets de scène (sprites de combat) montrés par leur portrait.
const SUBJECT_PORTRAIT := {"stag": "cerf", "sylvarche": "sylvarche", "pixie": "fee", "varg": "varg", "gharok": "gharok", "glass_sphinx": "sphinx",
	"mere_dragon": "mere_dragon", "ash_wyrm": "wyrm", "leviathan": "leviathan"}
const MAX_FIGURES := 4
## Deux personnages au plus à l'écran : celui qui parle et celui à qui il répond, un de chaque côté.
const MAX_VISIBLE := 2

## Vocabulaire des indications (vérifié par tools/ui_smoke.gd).
const CAMS := ["zoom", "zoom_out", "reset", "punch", "shake", "tremble", "pan_left", "pan_right", "pan_up", "push", "pull", "kick", "focus"]
const FXS := ["flash", "white", "fade", "lightning", "sparkles", "embers", "bloom", "ring", "rays", "bolt", "beam", "crack",
	"seal", "spiral", "flux", "gate", "arrow", "swarm", "clang", "steam", "thorns", "glitter", "hooves", "drip", "ferns", "lanes", "timestop", "flicker", "wind", "eyes", "veins", "fountain", "heartbeat", "willo", "cage", "shatter", "roots", "splinters", "renewal",
	"slash", "wisps", "charge", "burst", "leaves", "dust", "shock",
	"smoke", "arcs", "shieldwall", "howl", "drums", "rain", "banners", "pact", "shadow", "coins", "chant", "sigils", "cheer", "bars",
	"bubbles", "fogbank", "lanterns", "ripples", "bonerise", "chains", "jaws", "ashring", "heads", "moths", "whispers",
	"blizzard", "avalanche", "icecrack", "runes", "anvil", "aurora", "breath", "doors", "spectral",
	"sandstorm", "heatwave", "mirage", "glint", "sundisk", "hourglass", "riddle", "pages",
	"firewall", "ashfall", "wingshadow", "lavaflow", "eggglow", "phoenix", "wyrmmark", "dragonfire", "ashswirl",
	"current", "tide", "tentacles", "ink", "song", "threads", "bellring", "nacre", "blacktide"]
const ACTS := ["jump", "hop", "shake", "hurt", "attack", "droop", "kneel", "glow", "fall", "exit", "enter", "rise", "turn", "step", "cast", "echo"]
const SUBJECT_ACTS := ["roar", "hit", "fall", "glow", "rise", "fade", "appear"]
const GRADES := {"none": "ffffff", "night": "8c98d8", "violet": "c8a0f0", "warm": "ffd8ac", "dawn": "ffe6cc", "cold": "b8d6ff",
	"red": "ff9c8c", "green": "c8f2b8", "dark": "6c6c8c", "gold": "fff0c4"}
const MOOD_EMOTE := {"surpris": "!", "colere": "anger", "triste": "drop", "joie": "note"}
## Bulles d'émotion (o : contour, autre lettre : couleur de EMOTE_COL).
const EMOTES := {
	"!": [".ooo.", "owwwo", "owwwo", "owwwo", ".owo.", ".owo.", "..o..", ".ooo.", ".owo.", ".ooo."],
	"?": [".oooo.", "owwwwo", "oo..wo", "...owo", "..owwo", "..owo.", "..oo..", "..oo..", "..owo.", "..oo.."],
	"anger": [".oo.oo.", "orroror", "oro.oro", ".......", "oro.oro", "orroror", ".oo.oo."],
	"drop": ["..o..", ".obo.", ".obo.", "obbbo", "obwbo", "obbbo", ".ooo."],
	"note": ["..oooo", "..oyyo", "..oyoo", "..oyo.", "oooyo.", "oyyyo.", "oyyyo.", ".ooo.."],
	"dots": ["ooooooooo", "owoowoowo", "ooooooooo"],
}
const EMOTE_COL := {"o": "1a1426", "w": "fff6e0", "r": "ff4a3a", "b": "8fd8ff", "y": "ffd86a"}

var art: TextureRect ## le décor, cadré par la caméra
var subject: TextureRect ## la présence (créature, esprit) au centre
var ground_y := 600.0 ## haut du panneau de texte : les bustes s'y appuient
var top_y := 0.0
var px := 4.0 ## taille d'un pixel des effets
var talking := false ## l'orateur parle (le texte s'écrit)
var cast_fixed := false
var hold := false ## carton-titre : plan d'ensemble, sans personnages
var _visible: Array[String] = []

var _t := 0.0
var _scene_t := 0.0
# Caméra.
var _zoom := 1.0
var _zoom_to := 1.0
var _focus := Vector2.ZERO
var _focus_to := Vector2.ZERO
var _focus_set := false
var _pan := Vector2.ZERO
var _pan_to := Vector2.ZERO
var _kick := Vector2.ZERO
var _kick_v := Vector2.ZERO
var _punch := 0.0
var _trem := 0.0
var _drift_dir := 1.0
var _cam_s := 1.0
var _cam_off := Vector2.ZERO
# Calques.
var _ambient: Ambience
var _mood := ""
var _plate := ""
var _boxes: Dictionary = {} ## calque -> SubViewportContainer
var _figs_box: Control
var _ghost_box: Control
var _grade := Color.WHITE ## étalonnage : teinte du décor, des personnages et des effets de matière
var _grade_to := Color.WHITE
var _lb_top: ColorRect
var _lb_bot: ColorRect
var _lb := 0.0
var _flash: ColorRect
var _flash_t := 0.0
var _flash_dur := 0.3
var _flash_peak := 1.0
var _bolt2_t := -1.0
# Personnages et présence.
var _figs: Dictionary = {} ## id -> état du buste
var _order: Array[String] = []
var _speaker := ""
var _mouth := 0
var _mouth_blink := false
var _pres: Dictionary = {} ## présence (sujet) : nom, portrait, temps, action…
## La troupe : le héros et ses compagnons en pied, en volume, petits dans le décor derrière les bustes ; ils se
## tournent vers celui qui parle (ou vers la créature au centre) et font les gestes de la scène.
const TROUPE_MAX := 3
var _troupe: Dictionary = {} ## id -> HeroTurntable
var _troupe_sh: Dictionary = {} ## id -> ombre au sol (TextureRect)
var _troupe_order: Array[String] = []
var _troupe_box: Control
var _aura: Dictionary = {}
var _ghosts: Array = []
# Effets.
var _fx: Array = []
var _parts: Array = []
var _emotes: Array = []
var _last_anchor := ""
var _fig_mat: Shader
var _title: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SpriteAtlas.set_player(Profile.look(), Profile.race(), Profile.player_class())
	_fig_mat = load("res://shaders/cine_figure.gdshader")
	_boxes["back"] = _fx_box("back", false)
	_troupe_box = _plain_layer()
	_ghost_box = _plain_layer()
	_figs_box = _plain_layer()
	_boxes["front"] = _fx_box("front", false)
	_boxes["light"] = _fx_box("light", true)
	_lb_top = _bar()
	_lb_bot = _bar()
	if OS.has_feature("web"):
		var q := str(JavaScriptBridge.eval("window.location.search", true))
		if q.contains("cdbg="):
			var hide := q.get_slice("cdbg=", 1).get_slice("&", 0).split(",")
			for h in hide:
				if _boxes.has(h):
					(_boxes[h] as Control).visible = false
				elif h == "figs":
					_figs_box.visible = false
	if subject != null:
		var sm := ShaderMaterial.new()
		sm.shader = _fig_mat
		subject.material = sm
		subject.visible = false


func _plain_layer() -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


func _bar() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color("05040a")
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


## Calque d'effets en basse résolution, agrandi sans lissage ; additif pour la lumière.
func _fx_box(layer: String, additive: bool) -> SubViewportContainer:
	var box := SubViewportContainer.new()
	box.stretch = true
	box.stretch_shrink = int(px)
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		box.material = m
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	box.add_child(vp)
	var fx := CineFx.new()
	fx.stage = self
	fx.layer = layer
	vp.add_child(fx)
	return box


## Le voile de fondu vit au-dessus de la scène, sous le panneau de texte.
func make_flash_layer() -> ColorRect:
	_flash = ColorRect.new()
	_flash.color = Color(0, 0, 0, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return _flash


## Le joueur passe le carton-titre : il s'efface vite.
func end_title() -> void:
	if _title != null and is_instance_valid(_title):
		var tw := _title.create_tween()
		tw.tween_property(_title, "modulate:a", 0.0, 0.25)
		tw.tween_callback(_title.queue_free)
	_title = null


## Carton-titre au début d'une scène (intro d'un niveau, prologue) : il apparaît au centre, puis s'efface.
func title_card(text: String) -> void:
	if text.strip_edges() == "":
		return
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	var parts := text.split(" ", false, 1)
	var big := text
	var small := ""
	if parts.size() == 2 and parts[0].contains("-"):
		small = parts[0]
		big = parts[1]
	if small != "":
		var s := UiTheme.title(small, 26, UiTheme.CYAN)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.06))
		s.add_theme_constant_override("outline_size", 8)
		box.add_child(s)
	var l := UiTheme.title(big.to_upper(), 54 if size.x > size.y else 40, UiTheme.GOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.06))
	l.add_theme_constant_override("outline_size", 12)
	box.add_child(l)
	var line := ColorRect.new()
	line.color = Color(UiTheme.GOLD, 0.8)
	line.custom_minimum_size = Vector2(minf(size.x * 0.4, 420.0), 3)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(line)
	add_child(box)
	_title = box
	box.size = Vector2(size.x * 0.9, 0)
	box.position = Vector2(size.x * 0.05, _sh() * 0.3)
	box.modulate.a = 0.0
	var tw := box.create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.5).set_delay(0.3)
	tw.parallel().tween_property(line, "custom_minimum_size:x", minf(size.x * 0.5, 560.0), 1.6).set_delay(0.3)
	tw.tween_interval(0.9)
	tw.tween_property(box, "modulate:a", 0.0, 0.5)
	tw.tween_callback(box.queue_free)


func set_px(p: float) -> void:
	if is_equal_approx(p, px):
		return
	px = p
	for k in _boxes.keys():
		(_boxes[k] as SubViewportContainer).stretch_shrink = int(px)


func _sh() -> float:
	return maxf(160.0, ground_y - top_y)


# ---------------------------------------------------------------- scène

## Nouvelle scène : bandes cinéma, sortie du noir, distribution vide (ou imposée), caméra au repos.
func begin_scene(sc: Dictionary) -> void:
	for id in _figs.keys():
		(_figs[id]["rect"] as TextureRect).queue_free()
	_figs.clear()
	_order.clear()
	_visible.clear()
	_speaker = ""
	for tid in _troupe.keys():
		(_troupe[tid] as Node).queue_free()
		(_troupe_sh[tid] as Node).queue_free()
	_troupe.clear()
	_troupe_sh.clear()
	_troupe_order.clear()
	_fx.clear()
	_parts.clear()
	_emotes.clear()
	_aura = {}
	if not _pres.is_empty():
		_aura = _add_fx("aura", "subject", Dialogues.color(str(_pres["pid"])) if str(_pres["pid"]) != "" else Color("fff0b0"), "light", 1e9)
	_zoom = 1.0
	_zoom_to = 1.0
	_pan = Vector2.ZERO
	_pan_to = Vector2.ZERO
	_kick = Vector2.ZERO
	_kick_v = Vector2.ZERO
	_focus_set = false
	_drift_dir = -_drift_dir
	_scene_t = 0.0
	_lb = 0.0
	_flash_on(Color.BLACK, 0.8, 1.0)
	_grade_to = Color(str(GRADES.get(str(sc.get("grade", "none")), "ffffff")))
	cast_fixed = sc.has("cast")
	for c in sc.get("cast", []):
		var cd: Dictionary = c if c is Dictionary else {"id": str(c)}
		var side := 0.0
		if str(cd.get("side", "")) == "left":
			side = -1.0
		elif str(cd.get("side", "")) == "right":
			side = 1.0
		if _visible.size() < MAX_VISIBLE and not bool(cd.get("hidden", false)):
			_show_fig(Dialogues.resolve_who(str(cd["id"])), side)
		_troupe_add(Dialogues.resolve_who(str(cd["id"])))
	if sc.has("cam"):
		for c in _list(sc["cam"]):
			_camera(c)
	if _plate in LEAFY:
		_start_leaves()


## Décor : son ambiance animée.
func set_plate(kind: String) -> void:
	_plate = kind
	if kind in LEAFY:
		_start_leaves()
	else:
		for e in _fx.duplicate():
			if str(e["kind"]) == "emit_leaves":
				_fx.erase(e)
	var mood := str(PLATE_MOOD.get(kind, "mist"))
	if mood != _mood or _ambient == null:
		_mood = mood
		if _ambient != null:
			_ambient.queue_free()
			_ambient = null
		if Profile.ambience_on():
			_ambient = Ambience.new()
			_ambient.mood = mood
			add_child(_ambient)
			move_child(_ambient, 0)


## Nouveau plan (changement de décor) : le travelling repart.
func new_shot() -> void:
	_scene_t = 0.0
	_drift_dir = -_drift_dir
	_pan_to = Vector2.ZERO
	_zoom_to = 1.0
	_focus_set = false
	if _plate in LEAFY:
		_start_leaves()


# ---------------------------------------------------------------- présence (sujet)

## Sujet de la scène : créature ou esprit au centre (son portrait, ou son sprite), avec son aura.
func set_subject(name: String) -> void:
	if subject == null:
		return
	if name == "":
		if not _pres.is_empty() and not bool(_pres.get("fading", false)):
			_subject_act("fade")
		return
	var pid := ""
	if name.begins_with("portrait:"):
		pid = name.substr(9)
	elif SUBJECT_PORTRAIT.has(name):
		pid = str(SUBJECT_PORTRAIT[name])
	if not _pres.is_empty() and str(_pres["name"]) == name and not bool(_pres.get("fading", false)):
		return
	# Personnage en pied (il se tient dans le décor), sinon portrait ou sprite.
	var fig := pid if FigureArt.has(pid) else ("lanterne" if name == "lantern" else "")
	_pres = {"name": name, "pid": pid, "fig": fig, "t": 0.0, "act": "", "act_t": 0.0, "tint": Color.WHITE, "fading": false, "mood": "neutre"}
	if fig != "":
		subject.texture = FigureArt.texture(fig, "neutre")
	else:
		subject.texture = PortraitArt.texture(pid, "neutre") if pid != "" else SpriteAtlas.single(name)
	subject.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	subject.stretch_mode = TextureRect.STRETCH_SCALE
	subject.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	subject.visible = true
	subject.modulate = Color.WHITE
	var col := Dialogues.color(pid) if pid != "" else Color("fff0b0")
	_aura = _add_fx("aura", "subject", col, "light", 1e9)
	_add_fx("bloom", "subject", col, "light", 1.2)
	_reflow()


func set_tint(c: Color) -> void:
	if _pres.is_empty():
		return
	_pres["tint"] = c
	if not _aura.is_empty():
		_aura["col"] = c.lerp(Color.WHITE, 0.2) if c != Color.WHITE else _aura["col"]


func has_figure(who: String) -> bool:
	return _figs.has(who) or (not _pres.is_empty() and str(_pres["pid"]) == who)


# ---------------------------------------------------------------- répliques

## Une réplique commence : l'orateur entre en scène (buste, ou présence pour une créature), réagit à son humeur.
func speak(who: String, mood: String) -> void:
	_speaker = who
	_troupe_add(who)
	if who == "narrateur" or not PortraitArt.has_portrait(who):
		return
	if who in PRESENCE or (not _pres.is_empty() and str(_pres["pid"]) == who):
		if _pres.is_empty() or str(_pres["pid"]) != who:
			set_subject("portrait:" + who)
		_pres["mood"] = mood
		return
	_show_fig(who, 0.0)
	if not _figs.has(who):
		return
	var f: Dictionary = _figs[who]
	var before := str(f["mood"])
	f["mood"] = mood
	(f["rect"] as TextureRect).move_to_front()
	if mood != before:
		if str(f["persist"]) == "droop" and mood != "triste":
			f["persist"] = ""
		match mood:
			"surpris":
				_act(who, "jump")
			"colere":
				_act(who, "shake")
			"joie":
				_act(who, "hop")
			"triste":
				f["persist"] = "droop"
		if MOOD_EMOTE.has(mood):
			_emote(who, str(MOOD_EMOTE[mood]))


## Bouche et paupières de l'orateur (calculées par l'écran de dialogue pendant l'écriture du texte).
func set_mouth(talk: int, blink: bool) -> void:
	_mouth = talk
	_mouth_blink = blink


## Indications de mise en scène d'une réplique :
## « cam » : push, pull, focus:<repère>, kick, tremble, pan_left, pan_right, pan_up, reset (et zoom, zoom_out,
##   punch, shake, conservés) ;
## « fx » : « effet[@repère][:RRGGBB] » — bloom, ring, shock, rays, bolt, beam, crack, slash, wisps, seal, spiral, flux, gate,
##   charge, burst, embers, leaves, dust, fade, white (et flash, lightning, sparkles) ;
##   repères : un personnage, subject, center, sky, ground, left, right ;
## « act » : {qui: action} — jump, hop, shake, hurt, attack, droop, kneel, glow, fall, exit, enter, rise, turn,
##   step, cast ; « subject » : roar, hit, fall, glow, rise, fade, appear ;
## « grade » : étalonnage (night, violet, warm, dawn, cold, red, green, dark, gold, none) ;
## « emote » : {qui: !, ?, anger, drop, note, dots}.
func play_cues(l: Dictionary) -> void:
	if l.has("grade"):
		_grade_to = Color(str(GRADES.get(str(l["grade"]), "ffffff")))
	if l.has("title"):
		title_card(str(l["title"]))
	if l.has("cam"):
		for c in _list(l["cam"]):
			_camera(c)
	_last_anchor = ""
	if l.has("act"):
		var acts: Dictionary = l["act"]
		for who in acts.keys():
			var w := Dialogues.resolve_who(str(who))
			var what := str(acts[who])
			if w == "subject":
				_subject_act(what)
				_last_anchor = "subject"
			else:
				if what != "exit":
					_show_fig(w, 0.0)
				else:
					_visible.erase(w)
				if _figs.has(w):
					_act(w, what)
					_last_anchor = w
	if l.has("emote"):
		var ems: Dictionary = l["emote"]
		for who in ems.keys():
			_emote(Dialogues.resolve_who(str(who)), str(ems[who]))
	if l.has("fx"):
		for f in _list(l["fx"]):
			_effect(f)


static func _list(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if v is Array:
		for x in v:
			out.append(str(x))
	else:
		out.append(str(v))
	return out


func _camera(c: String) -> void:
	var name := c.get_slice(":", 0)
	match name:
		"push", "zoom":
			_zoom_to = 1.16
		"pull", "zoom_out":
			_zoom_to = 0.97
		"reset":
			_zoom_to = 1.0
			_pan_to = Vector2.ZERO
			_focus_set = false
		"focus":
			_focus_to = _anchor_pos(c.get_slice(":", 1) if c.contains(":") else "subject")
			_focus_set = true
			_zoom_to = 1.2
		"kick", "shake":
			_kick_impulse(16.0)
		"punch":
			_kick_impulse(10.0)
			_punch = 1.0
		"tremble":
			_trem = 1.8
		"pan_left":
			_pan_to = Vector2(size.x * 0.05, 0.0)
		"pan_right":
			_pan_to = Vector2(-size.x * 0.05, 0.0)
		"pan_up":
			_pan_to = Vector2(0.0, _sh() * 0.06)


func _kick_impulse(amp: float) -> void:
	var dir := Vector2.from_angle(randf_range(0.0, TAU))
	dir.y = absf(dir.y) * 0.6 + 0.4
	_kick_v += dir.normalized() * amp * 26.0


## « effet@repère:couleur ».
func _effect(spec: String) -> void:
	var col_s := ""
	var head := spec
	if spec.contains(":"):
		col_s = spec.get_slice(":", 1)
		head = spec.get_slice(":", 0)
	var kind := head.get_slice("@", 0)
	var anchor := head.get_slice("@", 1) if head.contains("@") else ""
	if anchor == "":
		anchor = _last_anchor if _last_anchor != "" else "auto"
	var col := Color(col_s) if col_s != "" else Color.WHITE
	var sh := _sh()
	match kind:
		"fade":
			_flash_on(Color.BLACK, 1.3, 1.0)
		"white":
			_flash_on(Color.WHITE, 0.5, 0.55)
			_fx_set(_add_fx("bloom", anchor, Color.WHITE, "light", 1.4), "r", sh * 0.8)
			_add_fx("ring", anchor, Color.WHITE, "light", 0.8)
		"flash", "bloom":
			var b := _add_fx("bloom", anchor, col, "light", 1.3)
			b["r"] = sh * (0.7 if kind == "flash" else 0.45)
		"ring", "shock":
			var r := _add_fx("ring", anchor, col, "light", 0.9)
			if kind == "shock":
				r["sq"] = 0.32
				r["R"] = size.x * 0.5
				_dust(_anchor_pos("ground"), 14)
		"rays":
			_add_fx("rays", anchor, col, "light", 3.0)
		"seal":
			# Le Sceau d'Écho se grave : un cercle traversé d'une ligne, et ses échos dans le temps.
			var se := _add_fx("seal", anchor, col, "light", 3.4)
			se["r"] = sh * 0.12
			if _figs.has(anchor):
				se["off"] = Vector2(0.0, sh * 0.22) ## sur la main, devant la poitrine
			_fx_set(_add_fx("bloom", anchor, col, "light", 2.0), "off", se.get("off", Vector2.ZERO))
		"spiral":
			# Le sortilège de Morvaen : un cadran dont les aiguilles tournent à rebours, des bras de lumière qui s'enroulent.
			_fx_set(_add_fx("spiral", anchor, col, "light", 4.0), "r", sh * 0.34)
		"flux":
			# Le Surge canalisé : des rubans d'énergie convergent vers celui qui canalise.
			_fx_set(_add_fx("flux", anchor, col, "light", 1.8), "r", sh * 0.55)
		"arrow":
			# Flèche de semonce : partie de celui qui parle, elle se plante aux pieds du repère et vibre.
			var ar := _add_fx("arrow", anchor, col if col_s != "" else Color("e8dcc0"), "front", 2.4)
			var from := Vector2(size.x * 1.05, sh * 0.3)
			if _figs.has(_speaker):
				var sf: Dictionary = _figs[_speaker]
				from = sf["head"] if (sf["head"] as Vector2) != Vector2.ZERO else Vector2(size.x * (1.05 if float(sf["side"]) > 0.0 else -0.05), sh * 0.35)
			ar["from"] = from
			ar["off"] = Vector2(0.0, sh * 0.3)
			ar["landed"] = false
		"clang":
			# Coup de bouclier : étoile d'impact métallique et éclats.
			var cl := _add_fx("clang", anchor, col if col_s != "" else Color("fff0b0"), "light", 0.5)
			if _figs.has(anchor):
				cl["off"] = Vector2(-float(_figs[anchor]["side"]) * sh * 0.22, sh * 0.15)
			_burst(_fx_pos(cl), Color("e8e8ff"), 18, "light")
			_kick_impulse(7.0)
		"steam":
			# Colère comique : deux bouffées de vapeur sortent de chaque côté de la tête.
			var st := _add_fx("emit_steam", anchor, Color("f0f0ff"), "front", 1.2)
			st["rate"] = 16.0
		"thorns":
			# Ronces maudites des fées : elles poussent du sol en se tordant, hérissées d'épines.
			var th := _add_fx("thorns", anchor, col if col_s != "" else Color("7a3a8a"), "back", 4.5)
			var stems := PackedVector2Array()
			for i in range(7):
				stems.append(Vector2(randf_range(-1.0, 1.0), randf_range(0.6, 1.0)))
			th["pts"] = stems
			th["r"] = sh * 0.5
		"glitter":
			# Poussière de fée : de petites étoiles qui scintillent et s'éteignent autour du repère.
			var gl := _add_fx("emit_glitter", anchor, col if col_s != "" else Color("ffb8f0"), "light", 3.5)
			gl["rate"] = 45.0
		"drip":
			# Lumière qui ruisselle (des bois du Cerf) : des gouttes tombent du haut du repère.
			var dr := _add_fx("emit_drip", anchor, col if col_s != "" else Color("b07cff"), "light", 4.0)
			dr["rate"] = 18.0
		"ferns":
			# Les fougères volent quand une bête en jaillit.
			var gp2 := _anchor_pos(anchor if anchor != "auto" else "ground")
			for i in range(36):
				var a := randf_range(-PI * 0.9, -PI * 0.1)
				_part({"p": gp2 + Vector2(randf_range(-0.3, 0.3) * size.x * 0.5, 0.0), "v": Vector2.from_angle(a) * randf_range(120, 300),
					"max": randf_range(1.0, 1.6), "col": [Color("3f7a4a"), Color("5fa05a"), Color("2a5a36")][i % 3], "size": 1.0, "layer": "front",
					"grav": Vector2(0, 240), "drag": 1.2, "sway": 20.0, "kind": "leaf"})
		"lanes":
			# Couloirs de danger : des bandes rouges clignotent au sol, là où la bête va charger.
			var ln := _add_fx("lanes", "ground", col if col_s != "" else Color("ff4a3a"), "back", 2.6)
			ln["pts"] = PackedVector2Array([Vector2(randf_range(0.22, 0.36), 0), Vector2(randf_range(0.45, 0.55), 0), Vector2(randf_range(0.64, 0.78), 0)])
		"timestop":
			# Le monde se fige (un Écho) : bandes de distorsion qui glissent, onde lente autour du repère.
			var ts := _add_fx("timestop", anchor, col if col_s != "" else Color("9ff0ff"), "light", 2.6)
			var bands := PackedVector2Array()
			for i in range(9):
				bands.append(Vector2(randf(), randf_range(1.0, 5.0)))
			ts["pts"] = bands
			_fx_set(_add_fx("ring", anchor, col if col_s != "" else Color("9ff0ff"), "light", 2.4), "R", sh * 1.2)
		"flicker":
			# Flamme fragile (la Lanterne) : un halo chaud qui vacille, des étincelles qui montent.
			var fl := _add_fx("flicker", anchor, col if col_s != "" else Color("ffc860"), "light", 4.5)
			fl["r"] = sh * 0.3
			var fs2 := _add_fx("emit_embers_at", anchor, col if col_s != "" else Color("ffc860"), "light", 4.5)
			fs2["rate"] = 10.0
		"wind":
			# Coup de vent : des traînées traversent l'écran ; la flamme et les feuilles ploient.
			var wd := _add_fx("wind", anchor, Color("d8e8ff"), "front", 1.6)
			var streaks := PackedVector2Array()
			for i in range(14):
				streaks.append(Vector2(randf(), randf_range(0.0, 0.5)))
			wd["pts"] = streaks
			for f in _fx:
				if str(f["kind"]) == "flicker":
					f["gust"] = 1.0
		"eyes":
			# Embuscade : des paires d'yeux s'allument dans les fourrés, sur les flancs.
			var ey := _add_fx("eyes", anchor, col if col_s != "" else Color("ff5a3a"), "light", 3.5)
			var pairs := PackedVector2Array()
			for i in range(6):
				var left := i % 2 == 0
				pairs.append(Vector2(randf_range(0.02, 0.2) if left else randf_range(0.8, 0.98), randf_range(0.45, 0.85)))
			ey["pts"] = pairs
		"veins":
			# La corruption rampe : des veines violettes se ramifient sur le sol depuis le repère.
			var vn := _add_fx("veins", anchor if anchor != "auto" else "ground", col if col_s != "" else Color("b07cff"), "back", 4.0)
			var branches: Array = []
			for i in range(8):
				var dir := -1.0 if i % 2 == 0 else 1.0
				var pts4 := PackedVector2Array([Vector2.ZERO])
				var p4 := Vector2.ZERO
				for j in range(10):
					p4 += Vector2(dir * randf_range(8.0, 20.0), randf_range(-5.0, 5.0) + float(i / 2) * 1.5)
					pts4.append(p4)
				branches.append(pts4)
			vn["br"] = branches
		"fountain":
			# La Source rejaillit : un jet d'eau claire qui monte et retombe en gouttes.
			var fo := _add_fx("emit_fountain", anchor if anchor != "auto" else "ground", col if col_s != "" else Color("9fe3ff"), "light", 4.0)
			fo["rate"] = 170.0
			_fx_set(_add_fx("ring", anchor if anchor != "auto" else "ground", col if col_s != "" else Color("9fe3ff"), "light", 1.0), "sq", 0.3)
		"heartbeat":
			# Le Cœur de la Forêt bat : double battement sourd, la lumière enfle avec lui.
			var hb := _add_fx("heartbeat", anchor, col if col_s != "" else Color("d93cf2"), "light", 4.2)
			hb["r"] = sh * 0.6
			hb["beat"] = -1
		"willo":
			# Feux-follets : des orbes froids dérivent en laissant une traîne.
			var wo := _add_fx("willo", anchor, col if col_s != "" else Color("8fe8ff"), "light", 4.5)
			var orbs := PackedVector2Array()
			for i in range(5):
				orbs.append(Vector2(randf() * TAU, randf_range(0.6, 1.4)))
			wo["pts"] = orbs
			wo["r"] = sh * 0.35
		"cage":
			# Cage de ronces : des barreaux épineux enferment le sujet.
			_fx_set(_add_fx("cage", anchor, col if col_s != "" else Color("5a3a6a"), "front", 1e9), "r", sh * 0.3)
		"shatter":
			# La cage vole en éclats : barreaux en morceaux, poussière de lumière.
			for e9 in _fx.duplicate():
				if str(e9["kind"]) in ["cage", "sigils", "bars", "chains", "heads", "wyrmmark", "blacktide"]:
					_fx.erase(e9)
			var sp3 := _anchor_pos(anchor)
			for i in range(40):
				_part({"p": sp3 + Vector2(randf_range(-1, 1) * sh * 0.25, randf_range(-1, 1) * sh * 0.25), "v": Vector2.from_angle(randf() * TAU) * randf_range(120, 320),
					"max": randf_range(0.7, 1.2), "col": Color("6a4a7a"), "size": 1.0, "layer": "front", "grav": Vector2(0, 420), "drag": 1.0, "kind": "leaf"})
			var gl2 := _add_fx("emit_glitter", anchor, col if col_s != "" else Color("ffe4f6"), "light", 2.0)
			gl2["rate"] = 60.0
			_kick_impulse(8.0)
		"roots":
			# Racines qui se tordent : elles sortent du sol par les côtés et rampent vers le centre.
			var rt := _add_fx("roots", anchor if anchor != "auto" else "ground", col if col_s != "" else Color("5a3a2a"), "back", 4.5)
			var rs2 := PackedVector2Array()
			for i in range(6):
				rs2.append(Vector2(-1.0 if i % 2 == 0 else 1.0, randf_range(0.0, 1.0)))
			rt["pts"] = rs2
		"splinters":
			# Éclats d'écorce : le bois se fend, des copeaux volent, la poussière retombe.
			var sp4 := _anchor_pos(anchor)
			for i in range(44):
				_part({"p": sp4 + Vector2(randf_range(-1, 1) * sh * 0.15, randf_range(-1, 1) * sh * 0.15), "v": Vector2.from_angle(randf_range(-PI, 0.0)) * randf_range(160, 380),
					"max": randf_range(0.8, 1.3), "col": [Color("6a4a2a"), Color("9a6a3a"), Color("c8a070")][i % 3], "size": 1.0, "layer": "front",
					"grav": Vector2(0, 520), "drag": 0.8, "kind": "leaf"})
			_dust(_anchor_pos("ground"), 16)
			_kick_impulse(12.0)
		"renewal":
			# Renouveau : feuilles claires et lueurs vertes montent du sol en tournoyant.
			var rn := _add_fx("emit_renewal", anchor if anchor != "auto" else "ground", col if col_s != "" else Color("8fd16a"), "light", 4.0)
			rn["rate"] = 40.0
		"hooves":
			# Martèlement au loin : le sol bat, la poussière saute, à intervalles réguliers.
			var hv := _add_fx("hooves", "ground", Color("d8c8b0"), "back", 3.2)
			hv["beat"] = -1
		"swarm":
			# Essaim de lucioles qui tourne autour du repère.
			var sw := _add_fx("swarm", anchor, col if col_s != "" else Color("fff3b0"), "light", 4.0)
			var seeds := PackedVector2Array()
			for i in range(26):
				seeds.append(Vector2(randf() * TAU, randf_range(0.5, 1.0)))
			sw["pts"] = seeds
			sw["r"] = sh * 0.22
		"gate":
			# Les portes runiques du chemin : une arche qui se dessine, ses runes s'allument une à une.
			_fx_set(_add_fx("gate", anchor, col, "light", 2.8), "r", sh * 0.2)
		"bolt", "lightning":
			_add_fx("bolt", anchor, col if col_s != "" else Color("cfe0ff"), "light", 0.45)
			_fx_set(_add_fx("bloom", anchor, col if col_s != "" else Color("cfe0ff"), "light", 0.6), "r", sh * 0.5)
			_flash_on(Color("e8f0ff"), 0.16, 0.45)
			_bolt2_t = 0.22
			_burst(_anchor_pos(anchor), col if col_s != "" else Color("cfe0ff"), 24, "light")
			_kick_impulse(8.0)
		"beam":
			_add_fx("beam", anchor, col, "light", 1.6)
			_add_fx("bloom", anchor, col, "light", 1.6)
		"crack":
			_add_fx("crack", anchor if anchor != "auto" else "sky", col, "light", 4.0)
		"slash":
			_add_fx("slash", anchor, col, "light", 0.5)
		"wisps":
			var e := _add_fx("emit_wisps", anchor, col, "back", 3.5)
			e["rate"] = 26.0
		"charge":
			var e2 := _add_fx("emit_charge", anchor, col, "light", 1.3)
			e2["rate"] = 70.0
			_fx_set(_add_fx("bloom", anchor, col, "light", 1.8), "r", sh * 0.25)
		"burst", "sparks", "sparkles":
			_burst(_anchor_pos(anchor), col if col_s != "" else Color("fff3b0"), 46, "light")
			_fx_set(_add_fx("ring", anchor, col if col_s != "" else Color("fff3b0"), "light", 0.6), "R", sh * 0.22)
		"embers":
			var e3 := _add_fx("emit_embers", "ground", col if col_s != "" else Color("ffb050"), "light", 4.0)
			e3["rate"] = 40.0
		"leaves":
			_start_leaves()
		"dust":
			_dust(_anchor_pos(anchor), 16)
		# Collines d'Ambre (zone 2).
		"smoke":
			# Fumée noire qui monte au loin : une colonne de volutes qui s'élargit en montant.
			var sm := _add_fx("emit_smoke", anchor if anchor != "auto" else "sky", col if col_s != "" else Color("6a6068"), "back", 5.0)
			sm["rate"] = 9.0
		"arcs":
			# Les pylônes d'ambre crépitent : des arcs dorés sautent d'un cristal à l'autre.
			var ac := _add_fx("arcs", anchor, col if col_s != "" else Color("ffc860"), "light", 2.6)
			ac["r"] = sh * 0.4
			_fx_set(_add_fx("bloom", anchor, col if col_s != "" else Color("ffc860"), "light", 1.0), "r", sh * 0.35)
		"shieldwall":
			# Mur de boucliers : une rangée de pavois se dresse d'un coup et frappe le sol.
			_add_fx("shieldwall", anchor if anchor != "auto" else "ground", col if col_s != "" else Color("8a6a40"), "front", 3.2)
			_dust(_anchor_pos("ground"), 18)
			_kick_impulse(10.0)
		"howl":
			# Hurlement des loups : des ondes de son qui montent du repère, et le décor frissonne.
			_add_fx("howl", anchor, col if col_s != "" else Color("d8e0f0"), "light", 2.2)
			_kick_impulse(4.0)
		"drums":
			# Tambours de guerre : deux coups sourds puis un, le sol bat avec eux.
			var dr := _add_fx("drums", "ground", col if col_s != "" else Color("c84a3a"), "back", 3.8)
			dr["beat"] = -1
		"rain":
			# Pluie d'orage sur toute la scène.
			_add_fx("rain", "center", col if col_s != "" else Color("a8b8e0"), "front", 1e9)
		"banners":
			# Les bannières de guerre claquent dans le vent de l'orage.
			_add_fx("banners", "center", col if col_s != "" else Color("a82a2a"), "back", 1e9)
		"pact":
			# Le Traité : un ruban bleu et un ruban rouge viennent l'un vers l'autre, se nouent, et l'or jaillit.
			_add_fx("pact", anchor if anchor != "auto" else "center", col if col_s != "" else Color("f2c46b"), "light", 3.0)
		"shadow":
			# Le Surge se tord sous la peau : des volutes violettes ondulent autour du repère.
			var shd := _add_fx("shadow", anchor, col if col_s != "" else Color("b03ad8"), "light", 4.5)
			shd["r"] = sh * 0.3
		"coins":
			# Pièces d'or jetées en l'air, qui retombent en tintant.
			var cp := _anchor_pos(anchor)
			for i in range(26):
				_part({"p": cp + Vector2(randf_range(-10, 10), 0.0), "v": Vector2(randf_range(-120, 120), -randf_range(220, 380)), "max": randf_range(1.0, 1.5),
					"col": [Color("f2c46b"), Color("ffe08a"), Color("c8902a")][i % 3], "size": 2.0, "layer": "front", "grav": Vector2(0, 700), "drag": 0.3, "kind": "sq"})
		"chant":
			# Le chant de la rebouteuse : des volutes vertes et dorées montent en spirale.
			var ch := _add_fx("emit_chant", anchor, col if col_s != "" else Color("a8e070"), "light", 3.5)
			ch["rate"] = 16.0
			_fx_set(_add_fx("ring", anchor, col if col_s != "" else Color("a8e070"), "light", 1.2), "sq", 0.4)
		"sigils":
			# Deux sceaux de Surge flottent et pulsent de part et d'autre du repère (jusqu'à « shatter »).
			var sg := _add_fx("sigils", anchor, col if col_s != "" else Color("d93cf2"), "light", 1e9)
			sg["r"] = sh * 0.1
		"cheer":
			# Vivats : chapeaux et fleurs jetés en l'air sur toute la largeur.
			for i in range(60):
				_part({"p": Vector2(randf() * size.x, ground_y + 10.0), "v": Vector2(randf_range(-60, 60), -randf_range(280, 460)), "max": randf_range(1.4, 2.2),
					"col": [Color("f2c46b"), Color("e85a3a"), Color("6fa8e8"), Color("f4f0e0")][i % 4], "size": 2.0 if i % 3 else 1.0, "layer": "front",
					"grav": Vector2(0, 420), "drag": 0.5, "sway": 20.0, "kind": "leaf" if i % 2 else "sq"})
		"bars":
			# Cage de bois : barreaux et traverses autour du repère (jusqu'à « shatter »).
			_fx_set(_add_fx("bars", anchor, col if col_s != "" else Color("7a5a32"), "front", 1e9), "r", sh * 0.26)
		# Marais Murmurants (zone 3).
		"bubbles":
			# Bulles de poison qui montent de la vase sur toute la largeur.
			var bu := _add_fx("emit_bubbles", "ground", col if col_s != "" else Color("8ae050"), "light", 4.0)
			bu["rate"] = 30.0
		"fogbank":
			# Un mur de brume roule à travers la scène.
			_add_fx("fogbank", "center", col if col_s != "" else Color("d8e0d8"), "front", 6.0)
		"lanterns":
			# Lanternes qui dansent au-dessus de l'eau.
			var ln := _add_fx("lanterns", "ground", col if col_s != "" else Color("ffc870"), "light", 1e9)
			var lp := PackedVector2Array()
			for i in range(7):
				lp.append(Vector2(randf_range(0.05, 0.95), randf_range(0.0, 1.0)))
			ln["pts"] = lp
		"ripples":
			# Ronds dans l'eau, l'un après l'autre.
			for i in range(4):
				var rp := _add_fx("ring", anchor if anchor != "auto" else "ground", col if col_s != "" else Color("c8e0e0"), "back", 1.4 + 0.3 * float(i))
				rp["sq"] = 0.22
				rp["R"] = sh * (0.25 + 0.12 * float(i))
				rp["t"] = -0.3 * float(i)
		"bonerise":
			# Des os et des mains de squelettes sortent de la vase.
			var br2 := _add_fx("bonerise", "ground", col if col_s != "" else Color("e8e0d0"), "back", 3.5)
			var bp := PackedVector2Array()
			for i in range(9):
				bp.append(Vector2(randf_range(0.05, 0.95), randf_range(0.6, 1.0)))
			br2["pts"] = bp
			_dust(_anchor_pos("ground"), 12)
		"chains":
			# Chaînes de runes autour du repère (jusqu'à « shatter »).
			_fx_set(_add_fx("chains", anchor, col if col_s != "" else Color("8ae050"), "light", 1e9), "r", sh * 0.3)
		"jaws":
			# Des mâchoires immenses claquent sur le repère.
			_fx_set(_add_fx("jaws", anchor, col if col_s != "" else Color("e8e0d0"), "front", 1.0), "r", sh * 0.32)
			_kick_impulse(14.0)
		"ashring":
			# Cercle rituel de cendre au sol, ses runes de braise s'allument une à une.
			var ar3 := _add_fx("ashring", anchor if anchor != "auto" else "ground", col if col_s != "" else Color("ff8a3a"), "back", 4.5)
			ar3["r"] = sh * 0.5
		"heads":
			# Les cous de l'Hydre se dressent hors de l'eau et ondulent, les yeux jaunes allumés.
			_fx_set(_add_fx("heads", "ground", col if col_s != "" else Color("1e2a22"), "back", 1e9), "r", sh * 0.6)
		"moths":
			# Phalènes qui voltigent autour du repère (Nyx).
			var mo := _add_fx("moths", anchor, col if col_s != "" else Color("c8b8e8"), "light", 4.0)
			var mp := PackedVector2Array()
			for i in range(9):
				mp.append(Vector2(randf() * TAU, randf_range(0.6, 1.4)))
			mo["pts"] = mp
			mo["r"] = sh * 0.25
		# Pics Gelés (zone 4).
		"blizzard":
			# Blizzard : des rafales de neige filent en travers de toute la scène.
			_add_fx("blizzard", "center", col if col_s != "" else Color("f4f8ff"), "front", 1e9)
		"avalanche":
			# Avalanche : une vague de neige dévale du haut de la scène, le sol tremble.
			_add_fx("avalanche", "center", col if col_s != "" else Color("f4f8ff"), "front", 2.6)
			_kick_impulse(18.0)
		"icecrack":
			# La glace se fend : des fissures courent depuis le repère.
			var ic := _add_fx("icecrack", anchor if anchor != "auto" else "ground", col if col_s != "" else Color("c8f0ff"), "light", 3.5)
			var cr3: Array = []
			for i in range(6):
				var pts11 := PackedVector2Array([Vector2.ZERO])
				var pp := Vector2.ZERO
				var dir2 := Vector2.from_angle(float(i) / 6.0 * TAU + randf_range(-0.3, 0.3))
				for j in range(9):
					dir2 = dir2.rotated(randf_range(-0.5, 0.5))
					pp += dir2 * randf_range(6.0, 12.0)
					pts11.append(pp * Vector2(1.0, 0.35))
				cr3.append(pts11)
			ic["br"] = cr3
			_kick_impulse(5.0)
		"runes":
			# Les runes s'allument une à une en arc autour du repère.
			_fx_set(_add_fx("runes", anchor, col if col_s != "" else Color("8fe3f2"), "light", 3.5), "r", sh * 0.3)
		"anvil":
			# Coups de marteau sur l'enclume : trois gerbes d'étincelles.
			var an := _add_fx("anvil", anchor, col if col_s != "" else Color("ffb050"), "light", 1.8)
			an["beat"] = -1
		"aurora":
			# Aurore boréale : des rideaux verts et violets ondulent dans le ciel.
			_add_fx("aurora", "sky", col if col_s != "" else Color("5ff0a8"), "back", 1e9)
		"breath":
			# Souffle glacé : des bouffées blanches devant le visage.
			var bt := _add_fx("emit_breath", anchor, col if col_s != "" else Color("e8f4ff"), "front", 2.4)
			bt["rate"] = 6.0
		"doors":
			# Les grandes Portes s'entrouvrent dans un soupir de givre ; une lumière bleue filtre entre les battants.
			_add_fx("doors", "center", col if col_s != "" else Color("8fd0ff"), "back", 4.0)
			_kick_impulse(6.0)
		"spectral":
			# Volutes spectrales bleues qui montent autour du repère (le Thane Orrin).
			var sp5 := _add_fx("emit_spectral", anchor, col if col_s != "" else Color("8fd0ff"), "light", 4.0)
			sp5["rate"] = 18.0
		# Forêt Cendrée (zone 6).
		"firewall":
			# Un mur de flammes se lève devant le décor, langues de feu qui dansent sur toute la largeur.
			_add_fx("firewall", "ground", col if col_s != "" else Color("ff7a2a"), "back", 4.5)
			_flash_on(Color("ff9a4a"), 0.4, 0.25)
		"ashfall":
			# Les braises tombent comme une neige rouge : flocons de cendre grise, quelques braises qui luisent.
			var af := _add_fx("emit_ashfall", "sky", col if col_s != "" else Color("ff7a2a"), "front", 5.0)
			af["rate"] = 40.0
		"wingshadow":
			# Une ombre immense glisse sur la scène : un dragon passe au-dessus, ailes battantes.
			_add_fx("wingshadow", "sky", col if col_s != "" else Color("0a0404"), "front", 2.4)
			_kick_impulse(4.0)
		"lavaflow":
			# Une coulée de magma s'avance au pied de la scène, des bulles éclatent à sa surface.
			var lf := _add_fx("lavaflow", "ground", col if col_s != "" else Color("ff5a1a"), "back", 4.5)
			lf["rate"] = 0.0
		"eggglow":
			# L'Œuf noir veiné de feu : ses veines s'allument au rythme d'un cœur.
			var eg := _add_fx("eggglow", anchor if anchor != "auto" else "center", col if col_s != "" else Color("ff6a2a"), "light", 4.0)
			eg["r"] = sh * 0.07
			var veins: Array = []
			for i in range(5):
				var pts14 := PackedVector2Array()
				var vp := Vector2(randf_range(-0.5, 0.5), randf_range(-0.9, -0.4))
				for j in range(6):
					pts14.append(vp)
					vp += Vector2(randf_range(-0.25, 0.25), randf_range(0.15, 0.3))
				veins.append(pts14)
			eg["br"] = veins
		"phoenix":
			# Un phénix d'or s'élève en battant des ailes, une traînée d'étincelles derrière lui.
			var ph := _add_fx("emit_phoenix", anchor if anchor != "auto" else "center", col if col_s != "" else Color("ffb040"), "light", 2.8)
			ph["rate"] = 40.0
			_flash_on(Color("ffd070"), 0.4, 0.25)
		"wyrmmark":
			# La Marque du Wyrm : une rune rouge (cercle, croc et trois griffures) qui pulse et cherche une épaule.
			_fx_set(_add_fx("wyrmmark", anchor, col if col_s != "" else Color("ff3a2a"), "light", 6.0), "r", sh * 0.09)
		"dragonfire":
			# Le souffle du dragon : un jet de flammes part de sa gueule et balaie le sol.
			var df := _add_fx("emit_dragonfire", anchor if anchor != "auto" else "subject", col if col_s != "" else Color("ff7a2a"), "front", 1.8)
			df["rate"] = 110.0
			df["dir"] = -1.0 if randf() < 0.5 else 1.0
			_flash_on(Color("ffb060"), 0.5, 0.35)
			_kick_impulse(6.0)
		"ashswirl":
			# Un tourbillon de cendres dorées monte autour du repère.
			var asw := _add_fx("emit_ashswirl", anchor, col if col_s != "" else Color("ffd070"), "light", 3.5)
			asw["rate"] = 70.0
		# Cité Engloutie (zone 7).
		"current":
			# Un courant traverse la scène : longs filets d'eau claire et bulles emportées de côté.
			_add_fx("current", "center", col if col_s != "" else Color("bff0ff"), "front", 3.5)
		"tide":
			# La marée monte : l'eau s'élève depuis le bas de la scène, sa surface ondule, puis redescend.
			_add_fx("tide", "ground", col if col_s != "" else Color("4fa8c8"), "front", 4.0)
			_trem = maxf(_trem, 0.3)
		"tentacles":
			# Des tentacules jaillissent du sol, se tordent, puis replongent.
			var tn := _add_fx("tentacles", "ground", col if col_s != "" else Color("6a3a7a"), "back", 3.6)
			var tps := PackedVector2Array()
			for i in range(5):
				tps.append(Vector2(randf_range(0.05, 0.95), randf_range(0.6, 1.0)))
			tn["pts"] = tps
			_kick_impulse(7.0)
			_dust(_anchor_pos("ground"), 10)
		"ink":
			# Un nuage d'encre se répand et masque tout un instant.
			var ik := _add_fx("emit_ink", anchor if anchor != "auto" else "subject", col if col_s != "" else Color("140a1e"), "front", 2.2)
			ik["rate"] = 40.0
		"song":
			# Le chant des Sirènes : des ondes sinueuses roses partent du repère, des notes de lumière scintillent.
			_add_fx("song", anchor, col if col_s != "" else Color("ff9ad0"), "light", 4.0)
			var sg2 := _add_fx("emit_glitter", anchor, col if col_s != "" else Color("ffb0e0"), "light", 3.5)
			sg2["rate"] = 18.0
		"threads":
			# Les fils des Archives : des milliers de fils lumineux tendus du sol à la voûte ; un fil se distingue.
			var thr := _add_fx("threads", "center", col if col_s != "" else Color("ffe08a"), "light", 5.0)
			var xs := PackedVector2Array()
			for i in range(46):
				xs.append(Vector2(randf(), randf()))
			thr["pts"] = xs
		"bellring":
			# La cloche sonne : trois coups graves, des ondes qui roulent dans l'eau.
			var bl := _add_fx("bellring", anchor if anchor != "auto" else "subject", col if col_s != "" else Color("ffe08a"), "light", 2.8)
			bl["beat"] = -1
		"nacre":
			# Une bulle de nacre se forme autour de chacun : reflets irisés, un éclat qui tourne.
			for who in _figs.keys():
				_fx_set(_add_fx("nacre", str(who), col if col_s != "" else Color("e8f4ff"), "light", 3.5), "r", sh * 0.24)
			if _figs.is_empty():
				_fx_set(_add_fx("nacre", "center", col if col_s != "" else Color("e8f4ff"), "light", 3.5), "r", sh * 0.24)
		"blacktide":
			# La Marée noire du Surge : des volutes d'encre violette ondulent autour du repère (jusqu'à « shatter »).
			_fx_set(_add_fx("blacktide", anchor, col if col_s != "" else Color("5a2a8a"), "back", 8.0), "r", sh * 0.32)
		# Désert de Verre (zone 5).
		"sandstorm":
			# Tempête de sable : voiles dorés en travers de la scène, l'air jaunit.
			_add_fx("sandstorm", "center", col if col_s != "" else Color("f2d090"), "front", 4.0)
		"heatwave":
			# L'air tremble au-dessus du sable : lignes de chaleur ondulantes.
			_add_fx("heatwave", "ground", col if col_s != "" else Color("fff0c8"), "light", 4.0)
		"mirage":
			# Un mirage : deux silhouettes translucides apparaissent, ondulent, puis s'effacent.
			_fx_set(_add_fx("mirage", anchor if anchor != "auto" else "center", col if col_s != "" else Color("d8c8ff"), "light", 4.0), "r", sh * 0.3)
		"glint":
			# Le soleil accroche le verre : des éclats scintillent un peu partout.
			var gl3 := _add_fx("emit_glint", "ground", col if col_s != "" else Color("e8ffff"), "light", 3.0)
			gl3["rate"] = 22.0
		"sundisk":
			# Un disque solaire éblouissant et sa couronne (le Scarabée-soleil).
			_fx_set(_add_fx("sundisk", anchor, col if col_s != "" else Color("ffd070"), "light", 3.5), "r", sh * 0.22)
			_flash_on(Color("fff0c0"), 0.4, 0.3)
		"hourglass":
			# Un sablier : le sable coule… puis s'arrête net (l'aube de la Fracture).
			_fx_set(_add_fx("hourglass", anchor if anchor != "auto" else "center", col if col_s != "" else Color("f2d090"), "light", 4.0), "r", sh * 0.14)
		"riddle":
			# Les énigmes du Sphinx : des glyphes dorés tournent autour du repère.
			_fx_set(_add_fx("riddle", anchor, col if col_s != "" else Color("f2c46b"), "light", 4.0), "r", sh * 0.32)
		"pages":
			# Les pages du Journal s'envolent et tournent autour du repère.
			var pg := _add_fx("emit_pages", anchor, col if col_s != "" else Color("f4ecd8"), "front", 2.5)
			pg["rate"] = 10.0
		"whispers":
			# La brume parle : des volutes de murmures dérivent et s'effacent.
			var wh := _add_fx("whispers", "center", col if col_s != "" else Color("d8d0f0"), "light", 4.0)
			var wp2 := PackedVector2Array()
			for i in range(10):
				wp2.append(Vector2(randf_range(0.05, 0.9), randf_range(0.15, 0.7)))
			wh["pts"] = wp2


func _fx_set(e: Dictionary, key: String, v: Variant) -> void:
	e[key] = v


func _flash_on(col: Color, dur: float, peak: float) -> void:
	if _flash == null:
		return
	_flash.color = Color(col, peak)
	_flash_dur = dur
	_flash_peak = peak
	_flash_t = dur


func _add_fx(kind: String, anchor: String, col: Color, layer: String, dur: float) -> Dictionary:
	var sh := _sh()
	var e := {"kind": kind, "anchor": anchor, "col": col, "layer": layer, "t": 0.0, "dur": dur, "r": sh * 0.4, "R": sh * 0.5,
		"sq": 1.0, "rot": randf() * TAU, "acc": 0.0, "rate": 0.0, "pts": PackedVector2Array(), "gen": -1.0}
	if kind == "crack":
		var y := _anchor_pos(anchor).y
		var pts := PackedVector2Array()
		var n := 18
		for i in range(n + 1):
			var f := float(i) / float(n)
			pts.append(Vector2(lerpf(-0.05, 1.05, f) * size.x, y + randf_range(-1.0, 1.0) * sh * 0.05 + sin(f * 7.0) * sh * 0.03))
		e["pts"] = pts
	_fx.append(e)
	return e


# ---------------------------------------------------------------- personnages

## Met un personnage en scène. S'il y en a déjà deux, le plus ancien sort ; le nouveau prend le côté libre
## (le héros à gauche, les autres à droite, de préférence).
func _show_fig(id: String, side_pref: float) -> void:
	if id == "" or not PortraitArt.has_portrait(id) or id in PRESENCE:
		return
	if _visible.has(id) and _figs.has(id) and float(_figs[id]["xt"]) < 0.0:
		_visible.erase(id)
		_visible.append(id)
		return
	_visible.erase(id)
	while _visible.size() >= MAX_VISIBLE:
		var old: String = _visible[0]
		_visible.remove_at(0)
		if _figs.has(old):
			_figs[old]["xt"] = 0.0
	var side := side_pref
	if side == 0.0:
		side = -1.0 if id == "porteur" else 1.0
	if _visible.size() == 1 and _figs.has(_visible[0]) and float(_figs[_visible[0]]["side"]) == side:
		side = -side
	if _figs.has(id):
		# Il sortait : on le remplace par une entrée neuve.
		(_figs[id]["rect"] as TextureRect).queue_free()
		_figs.erase(id)
		_order.erase(id)
	_add_fig(id, side, false)
	_visible.append(id)


func _add_fig(id: String, side: float, hidden: bool) -> void:
	if id == "" or _figs.has(id) or not PortraitArt.has_portrait(id) or id in PRESENCE:
		return
	if side == 0.0:
		side = -1.0 if id == "porteur" else 1.0
	var r := TextureRect.new()
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = _fig_mat
	r.material = m
	_figs_box.add_child(r)
	_order.append(id)
	_figs[id] = {"rect": r, "mat": m, "side": side, "ex": 0.0, "xt": -1.0, "hidden": hidden, "mood": "neutre", "act": "",
		"act_t": 0.0, "persist": "", "blink_t": randf_range(1.0, 3.5), "dark": 0.0, "sc": 1.0, "tkey": "", "flip": false,
		"head": Vector2.ZERO, "ph": randf() * TAU, "ghost_t": 0.0, "glow_col": Dialogues.color(id), "slashed": false}


func _act(id: String, what: String) -> void:
	_troupe_act(id, what)
	if not _figs.has(id):
		return
	var f: Dictionary = _figs[id]
	match what:
		"enter":
			f["hidden"] = false
			f["ex"] = 0.0
			return
		"exit":
			f["xt"] = 0.0
		"rise":
			f["persist"] = ""
		"droop", "kneel", "fall", "step":
			f["persist"] = what
		"turn":
			f["flip"] = not bool(f["flip"])
		"echo":
			f["echo_n"] = 0
		"glow", "cast":
			var col: Color = f["glow_col"]
			_fx_set(_add_fx("bloom", id, col, "light", 1.4), "r", _sh() * 0.32)
			var e := _add_fx("emit_motes", id, col, "light", 1.6)
			e["rate"] = 40.0
			if what == "cast":
				_fx_set(_add_fx("flux", id, col, "light", 1.8), "r", _sh() * 0.55)
	f["act"] = what
	f["act_t"] = 0.0
	f["slashed"] = false


# ---------------------------------------------------------------- la troupe en pied

## Ajoute un membre du groupe (le héros, un compagnon) qui a son modèle en volume.
func _troupe_add(id: String) -> void:
	if _troupe.has(id) or _troupe.size() >= TROUPE_MAX:
		return
	var m: HeroModel = null
	if id == "porteur":
		m = HeroModel.of(Profile.look(), Profile.race(), Profile.player_class(), Profile.visible_cosmetics(), Profile.gear_look())
	elif HeroModel.has_companion(id):
		m = HeroModel.of_companion(id, Profile.companion_class(id))
	if m == null:
		return
	var tt := HeroTurntable.new()
	tt.interactive = false
	tt.px_scale = troupe_scale()
	tt.yaw = PI
	tt.setup_model(m)
	tt.modulate.a = 0.0
	# Une ombre douce sous ses pieds le pose sur le sol du décor.
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	var shd := TextureRect.new()
	shd.texture = gt
	shd.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shd.stretch_mode = TextureRect.STRETCH_SCALE
	shd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shd.modulate.a = 0.0
	_troupe_box.add_child(shd)
	_troupe_sh[id] = shd
	_troupe_box.add_child(tt)
	_troupe[id] = tt
	# Le héros au milieu du groupe.
	if id == "porteur":
		_troupe_order.insert(_troupe_order.size() / 2, id)
	else:
		_troupe_order.append(id)


func troupe_scale() -> int:
	return clampi(int(_sh() / 260.0), 2, 6)


## Gestes de la scène joués par le personnage en pied.
func _troupe_act(id: String, what: String) -> void:
	if not _troupe.has(id):
		return
	var tt: HeroTurntable = _troupe[id]
	match what:
		"cast", "attack", "glow":
			tt.play("cast")
		"hurt", "shake":
			tt.play("hit")
		"kneel", "fall", "droop":
			tt.play("defeat")
		"jump", "hop":
			tt.play("victory")
		"step", "enter":
			tt.play_for("walk", 0.9)
		"rise":
			tt.play("idle")
		"turn":
			tt.yaw += PI


func _update_troupe(delta: float) -> void:
	var n := _troupe_order.size()
	if n == 0:
		return
	var sh := _sh()
	var pres := not _pres.is_empty() and subject != null and subject.visible
	# Au loin, sur le sol du décor, juste au-dessus des bustes (qui occupent le bas de la scène).
	var bust_top := ground_y - 64.0 * _fig_scale()
	var feet := minf(top_y + sh * 0.7, bust_top - 6.0)
	var cx := size.x * 0.5
	var xs: Array[float] = []
	for i in range(n):
		# Une créature au centre : le groupe s'écarte et lui fait face, de dos.
		xs.append(size.x * (0.5 + (float(i) - float(n - 1) * 0.5) * (0.24 if pres else 0.14)))
	var spk := _troupe_order.find(_speaker)
	var depth_s := 1.0 + (_cam_s - 1.0) * 0.7
	var ps := troupe_scale()
	for i in range(n):
		var tt: HeroTurntable = _troupe[_troupe_order[i]]
		tt.set_px_scale(ps)
		tt.modulate.a = minf(1.0, tt.modulate.a + delta * 2.0) if not hold else maxf(0.0, tt.modulate.a - delta * 4.0)
		var x := xs[i]
		var want := PI
		if pres:
			want = clampf((cx - x) / size.x * 2.2, -1.0, 1.0) ## de dos, vers la créature
		elif spk >= 0 and spk != i:
			want = PI - signf(xs[spk] - x) * 0.85 ## vers celui qui parle
		elif spk == i:
			want = PI + clampf((cx - x) / size.x * 3.0, -0.5, 0.5) + (0.0 if n > 1 else 0.35)
		else:
			want = PI + (0.4 if x < cx else -0.4)
		tt.yaw = lerp_angle(tt.yaw, want, clampf(delta * 5.0, 0.0, 1.0))
		var p := _cam_point(Vector2(x, feet), 0.7)
		tt.scale = Vector2(depth_s, depth_s)
		tt.size = tt.custom_minimum_size
		tt.pivot_offset = Vector2(tt.size.x * 0.5, tt.size.y)
		tt.position = p - Vector2(tt.size.x * 0.5, tt.size.y)
		var shd: TextureRect = _troupe_sh[_troupe_order[i]]
		shd.size = Vector2(float(ps) * 22.0, float(ps) * 6.0) * depth_s
		shd.position = p - Vector2(shd.size.x * 0.5, shd.size.y * 0.6)
		shd.modulate.a = tt.modulate.a


func _emote(id: String, kind: String) -> void:
	if not EMOTES.has(kind):
		return
	for em in _emotes:
		if str(em["who"]) == id:
			_emotes.erase(em)
			break
	_emotes.append({"who": id, "kind": kind, "t": 0.0, "dur": 1.9})


func _subject_act(what: String) -> void:
	if _pres.is_empty():
		return
	_pres["act"] = what
	_pres["act_t"] = 0.0
	var sh := _sh()
	var col: Color = _aura.get("col", Color.WHITE)
	match what:
		"roar":
			_fx_set(_add_fx("ring", "subject", col, "light", 1.0), "R", sh * 0.7)
			_add_fx("rays", "subject", col, "light", 1.4)
			_kick_impulse(14.0)
			_dust(_anchor_pos("ground"), 18)
		"hit":
			_burst(_anchor_pos("subject"), Color.WHITE, 40, "light")
			_add_fx("slash", "subject", Color.WHITE, "light", 0.5)
			_kick_impulse(12.0)
		"glow":
			_fx_set(_add_fx("bloom", "subject", col, "light", 1.6), "r", sh * 0.6)
			_add_fx("rays", "subject", col, "light", 2.4)
		"fade":
			_pres["fading"] = true
			var e := _add_fx("emit_dissolve", "subject", col, "light", 1.4)
			e["rate"] = 90.0
		"appear", "rise":
			_pres["t"] = 0.0 if what == "appear" else _pres["t"]
			_add_fx("bloom", "subject", col, "light", 1.4)
		"fall":
			_dust(_anchor_pos("ground"), 20)


# ---------------------------------------------------------------- repères

func _anchor_pos(name: String) -> Vector2:
	var sh := _sh()
	match name:
		"center":
			return Vector2(size.x * 0.5, top_y + sh * 0.45)
		"sky":
			return Vector2(size.x * 0.5, top_y + sh * 0.16)
		"ground":
			return Vector2(size.x * 0.5, ground_y - sh * 0.04)
		"left":
			return Vector2(size.x * 0.2, top_y + sh * 0.45)
		"right":
			return Vector2(size.x * 0.8, top_y + sh * 0.45)
		"subject", "auto":
			if not _pres.is_empty() and subject != null and subject.visible:
				return _pres.get("center", Vector2(size.x * 0.5, top_y + sh * 0.4))
			return Vector2(size.x * 0.5, top_y + sh * 0.42)
	if _figs.has(name):
		return _figs[name]["head"]
	return Vector2(size.x * 0.5, top_y + sh * 0.45)


func _cam_point(p: Vector2, depth: float) -> Vector2:
	var s := 1.0 + (_cam_s - 1.0) * depth
	return _focus + (p - _focus) * s + _cam_off * depth


# ---------------------------------------------------------------- image par image

func _process(delta: float) -> void:
	_t += delta
	_scene_t += delta
	_update_camera(delta)
	_update_figures(delta)
	_update_troupe(delta)
	_update_presence(delta)
	_update_fx(delta)
	_update_parts(delta)
	_update_ghosts(delta)
	for em in _emotes.duplicate():
		em["t"] = float(em["t"]) + delta
		if float(em["t"]) > float(em["dur"]):
			_emotes.erase(em)
	_grade = _grade.lerp(_grade_to, clampf(delta * 1.5, 0.0, 1.0))
	if art != null:
		art.self_modulate = _grade
	_figs_box.modulate = _grade
	_troupe_box.modulate = _grade
	(_boxes["back"] as Control).modulate = _grade
	_lb = lerpf(_lb, size.y * 0.06, clampf(delta * 2.5, 0.0, 1.0))
	_lb_top.position = Vector2.ZERO
	_lb_top.size = Vector2(size.x, _lb)
	_lb_bot.position = Vector2(0.0, size.y - _lb)
	_lb_bot.size = Vector2(size.x, _lb)
	if _flash != null and _flash_t > 0.0:
		_flash_t -= delta
		var k := clampf(_flash_t / maxf(0.01, _flash_dur), 0.0, 1.0)
		_flash.color.a = k * k * _flash_peak
	if _bolt2_t > 0.0:
		_bolt2_t -= delta
		if _bolt2_t <= 0.0:
			_flash_on(Color("e8f0ff"), 0.2, 0.35)


func _update_camera(delta: float) -> void:
	if art == null:
		return
	var center := Vector2(size.x * 0.5, top_y + _sh() * 0.5)
	if not _focus_set:
		_focus_to = center
	if _focus == Vector2.ZERO:
		_focus = center
	var k := 1.0 - exp(-delta * 1.5)
	_zoom = lerpf(_zoom, _zoom_to, k)
	_focus = _focus.lerp(_focus_to, k)
	_pan = _pan.lerp(_pan_to, k)
	# À-coup amorti : un ressort ramène l'image en place en une oscillation.
	# (en petits pas : une image lente ne doit pas faire diverger le ressort)
	var left := minf(delta, 0.25)
	while left > 0.0:
		var h := minf(left, 1.0 / 120.0)
		left -= h
		var acc := -_kick * 200.0 - _kick_v * 14.0
		_kick_v += acc * h
		_kick += _kick_v * h
	if not (is_finite(_kick.x) and is_finite(_kick.y)) or _kick.length() > 200.0:
		_kick = Vector2.ZERO
		_kick_v = Vector2.ZERO
	_punch = maxf(0.0, _punch - delta * 3.0)
	var trem := Vector2.ZERO
	if _trem > 0.0:
		_trem -= delta
		trem = Vector2(sin(_t * 43.0), cos(_t * 37.0)) * 2.5 * clampf(_trem, 0.0, 1.0)
	var u := clampf(_scene_t / 26.0, 0.0, 1.0)
	var breath := 1.04 + 0.06 * u + 0.004 * sin(_t * 0.5)
	_cam_s = breath * _zoom * (1.0 + 0.05 * sin(_punch * PI))
	var drift := Vector2(_drift_dir * u * size.x * 0.022, sin(_t * 0.22) * 3.0)
	_cam_off = drift + _pan + _kick + trem
	art.pivot_offset = _focus
	art.scale = Vector2.ONE * _cam_s
	art.position = _cam_off


func _fig_scale() -> float:
	var narrow := size.x < size.y
	return clampf(floorf(minf(_sh() * (0.62 if narrow else 0.95), size.x * (0.46 if narrow else 0.3)) / 64.0), 2.0, 10.0)


## Places : une par côté ; avec une créature au centre, les bustes s'écartent vers les bords.
func _reflow() -> void:
	var narrow := size.x < size.y
	var x := 0.25 if narrow else (0.16 if not _pres.is_empty() else 0.22)
	for id in _order:
		var f: Dictionary = _figs[id]
		f["slot"] = x if float(f["side"]) < 0.0 else 1.0 - x
		f["rank"] = 0


func _update_figures(delta: float) -> void:
	_reflow()
	var k := _fig_scale()
	var fs := Vector2(64.0, 64.0) * k
	var sh := _sh()
	for id in _order.duplicate():
		var f: Dictionary = _figs[id]
		var r: TextureRect = f["rect"]
		var m: ShaderMaterial = f["mat"]
		var side := float(f["side"])
		var speaking: bool = id == _speaker
		# Bouche et paupières.
		f["blink_t"] = float(f["blink_t"]) - delta
		var blink := float(f["blink_t"]) < 0.0
		if float(f["blink_t"]) < -0.13:
			f["blink_t"] = randf_range(2.2, 4.8)
		var talk := 0
		if speaking:
			talk = _mouth
			blink = blink or _mouth_blink
		var tkey := "%s|%d|%s" % [str(f["mood"]), talk, str(blink)]
		if tkey != str(f["tkey"]):
			f["tkey"] = tkey
			r.texture = PortraitArt.frame(id, str(f["mood"]), talk, blink)
		r.flip_h = bool(f["flip"]) if side < 0.0 else not bool(f["flip"])
		r.visible = not bool(f["hidden"])
		r.size = fs
		# Entrée et sortie.
		var tx := float(f.get("slot", 0.2)) * size.x
		var off_x := -fs.x * 0.7 if side < 0.0 else size.x + fs.x * 0.7
		f["ex"] = minf(1.0, float(f["ex"]) + delta / 0.55)
		var x := lerpf(off_x, tx, _ease_out_back(float(f["ex"])))
		var alpha := clampf(float(f["ex"]) * 2.5, 0.0, 1.0)
		if float(f["xt"]) >= 0.0:
			f["xt"] = float(f["xt"]) + delta / 0.45
			x = lerpf(tx, off_x, _ease_in(clampf(float(f["xt"]), 0.0, 1.0)))
			alpha = 1.0 - clampf(float(f["xt"]), 0.0, 1.0)
			if float(f["xt"]) >= 1.0:
				r.queue_free()
				_figs.erase(id)
				_order.erase(id)
				_visible.erase(id)
				continue
		if hold:
			# Plan d'ensemble (carton-titre) : les personnages entreront après.
			r.visible = false
			f["ex"] = 0.0
			continue
		# L'orateur s'avance dans la lumière, les autres reculent dans l'ombre.
		var lit: bool = speaking or _speaker == "" or not _figs.has(_speaker)
		f["dark"] = lerpf(float(f["dark"]), 0.0 if lit else 0.55, clampf(delta * 6.0, 0.0, 1.0))
		f["sc"] = lerpf(float(f["sc"]), (1.0 if lit else 0.95) * (0.92 if int(f.get("rank", 0)) > 0 and not speaking else 1.0), clampf(delta * 6.0, 0.0, 1.0))
		var toward := -side ## vers le centre
		var dx := toward * size.x * (0.012 if speaking else 0.0)
		var dy := 0.0
		var sx := 1.0 - 0.006 * sin(_t * 2.1 + float(f["ph"]))
		var sy := 1.0 + 0.012 * sin(_t * 2.1 + float(f["ph"]))
		var rot := 0.0
		var flash := 0.0
		var flash_col := Color.WHITE
		var rim := Color(0, 0, 0, 0)
		var desat := 0.0 if lit else 0.3
		if speaking and talking:
			dy -= absf(sin(_t * 8.0)) * k * 0.35
		match str(f["persist"]):
			"droop":
				dy += fs.y * 0.03
				desat = maxf(desat, 0.35)
			"kneel":
				dy += fs.y * 0.1
			"step":
				dx += toward * size.x * 0.04
			"fall":
				rot = -toward * 0.22
				dy += fs.y * 0.12
				f["dark"] = maxf(float(f["dark"]), 0.4)
		f["act_t"] = float(f["act_t"]) + delta
		var at := float(f["act_t"])
		match str(f["act"]):
			"jump":
				var u := at / 0.38
				dy -= sin(PI * clampf(u, 0.0, 1.0)) * fs.y * 0.07
				if u > 1.0 and u < 1.5:
					sy *= 1.0 - 0.06 * sin(PI * (u - 1.0) / 0.5)
					sx *= 1.0 + 0.04 * sin(PI * (u - 1.0) / 0.5)
			"hop":
				dy -= absf(sin(TAU * clampf(at / 0.6, 0.0, 1.0))) * fs.y * 0.035
			"shake":
				var env := clampf(1.0 - at / 0.5, 0.0, 1.0)
				dx += sin(at * 52.0) * k * 1.2 * env + toward * size.x * 0.025 * clampf(1.0 - at / 1.4, 0.0, 1.0)
				rim = Color(1.0, 0.3, 0.2, 0.9 * clampf(1.0 - at / 0.8, 0.0, 1.0))
			"hurt":
				var env2 := clampf(1.0 - at / 0.45, 0.0, 1.0)
				dx += -toward * size.x * 0.035 * env2 + sin(at * 60.0) * k * env2
				flash = clampf(1.0 - at / 0.18, 0.0, 1.0)
				flash_col = Color(1.0, 0.85, 0.85)
			"attack":
				var d := 0.0
				if at < 0.16:
					d = _ease_out(at / 0.16)
				elif at < 0.32:
					d = 1.0
				elif at < 0.62:
					d = 1.0 - _ease_in_out((at - 0.32) / 0.3)
				var foe := not _pres.is_empty()
				dx += toward * size.x * (0.12 if foe else 0.05) * d
				rot += toward * (0.06 if foe else 0.03) * d
				if at < 0.2:
					f["ghost_t"] = float(f["ghost_t"]) - delta
					if float(f["ghost_t"]) <= 0.0:
						f["ghost_t"] = 0.035
						_spawn_ghost(r, f["glow_col"])
				if at >= 0.16 and not bool(f["slashed"]) and not _pres.is_empty():
					f["slashed"] = true
					var hit := Vector2(tx + dx + toward * fs.x * 0.45, ground_y - fs.y * 0.45)
					var s := _add_fx("slash", "", Color.WHITE, "light", 0.45)
					s["at"] = hit
					s["rot"] = 0.0 if toward > 0.0 else PI
					_burst(hit, f["glow_col"], 26, "light")
					_kick_impulse(9.0)
			"echo":
				# Échos du temps : des doubles du personnage glissent de part et d'autre et s'effacent.
				var n_e := int(at / 0.28)
				if n_e > int(f.get("echo_n", 0)) and n_e <= 6:
					f["echo_n"] = n_e
					var g := _spawn_ghost(r, Color("9ff0ff"))
					g["dx"] = (1.0 if n_e % 2 == 0 else -1.0) * fs.x * (0.12 + 0.05 * float(n_e))
					g["life"] = 0.9
				flash = 0.25 * clampf(1.0 - at / 0.4, 0.0, 1.0)
				flash_col = Color("9ff0ff")
			"glow", "cast":
				var env3 := clampf(1.0 - at / 1.6, 0.0, 1.0)
				flash = 0.45 * clampf(1.0 - at / 0.6, 0.0, 1.0)
				flash_col = f["glow_col"]
				rim = Color(f["glow_col"], 0.9 * env3)
				dy -= fs.y * 0.015 * sin(PI * clampf(at / 1.2, 0.0, 1.0))
		# Position finale : un buste s'appuie sur le panneau ; la caméra le déplace un peu.
		var bottom := Vector2(tx + dx, ground_y + fs.y * 0.14 + dy)
		var s2 := float(f["sc"])
		var b2 := _cam_point(bottom, 0.25)
		var cs := 1.0 + (_cam_s - 1.0) * 0.25
		r.pivot_offset = Vector2(fs.x * 0.5, fs.y)
		r.scale = Vector2(sx * s2 * cs, sy * s2 * cs)
		r.rotation = rot
		r.position = b2 - r.pivot_offset
		r.modulate = Color(1, 1, 1, alpha)
		m.set_shader_parameter("dark", float(f["dark"]))
		m.set_shader_parameter("flash", flash)
		m.set_shader_parameter("flash_col", flash_col)
		m.set_shader_parameter("rim_col", rim)
		m.set_shader_parameter("desat", desat)
		f["head"] = b2 + Vector2(0.0, -fs.y * 0.62 * s2 * cs)
		f["bottom"] = b2
		f["S"] = fs.y * s2 * cs * sy


func _spawn_ghost(r: TextureRect, col: Color) -> Dictionary:
	var g := TextureRect.new()
	g.texture = r.texture
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_SCALE
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.flip_h = r.flip_h
	g.size = r.size
	g.pivot_offset = r.pivot_offset
	g.scale = r.scale
	g.rotation = r.rotation
	g.position = r.position
	g.modulate = Color(col.lightened(0.3), 0.5)
	var cm := CanvasItemMaterial.new()
	cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	g.material = cm
	_ghost_box.add_child(g)
	var gd := {"r": g, "t": 0.0, "x0": g.position.x, "dx": 0.0, "life": 0.28}
	_ghosts.append(gd)
	return gd


func _update_ghosts(delta: float) -> void:
	for g in _ghosts.duplicate():
		g["t"] = float(g["t"]) + delta
		var r: TextureRect = g["r"]
		var life := float(g["life"])
		var gu := clampf(float(g["t"]) / life, 0.0, 1.0)
		r.modulate.a = 0.5 * (1.0 - gu)
		r.position.x = float(g["x0"]) + float(g["dx"]) * _ease_out(gu)
		if float(g["t"]) > life:
			r.queue_free()
			_ghosts.erase(g)


func _update_presence(delta: float) -> void:
	if subject == null or _pres.is_empty() or subject.texture == null:
		return
	_pres["t"] = float(_pres["t"]) + delta
	var t := float(_pres["t"])
	var pid := str(_pres["pid"])
	var sh := _sh()
	var tw := float(subject.texture.get_width())
	var th := float(subject.texture.get_height())
	var narrow := size.x < size.y
	var fig := str(_pres.get("fig", ""))
	var k := 2.0
	if fig != "":
		# En pied : sa taille suit la hauteur de la scène (le Cerf est immense, la fée minuscule), en multiple entier.
		var feet := ground_y + sh * 0.08 - (sh * 0.3 if FigureArt.flies(fig) else 0.0)
		if FigureArt.painted(fig):
			# Image peinte : taille libre, lissée.
			k = minf(sh * FigureArt.height_share(fig) / th, minf(size.x * 1.2 / tw, (feet - size.y * 0.06 - 10.0) / th))
			subject.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		else:
			k = maxf(1.0, roundf(sh * FigureArt.height_share(fig) / th))
			k = minf(k, maxf(1.0, floorf(size.x * 1.2 / tw)))
			# La tête reste dans le cadre, sous la bande cinéma.
			k = minf(k, maxf(1.0, floorf((feet - size.y * 0.06 - 10.0) / th)))
			subject.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	elif pid != "":
		k = clampf(floorf(minf(sh * (0.6 if narrow else 1.0), size.x * (0.78 if narrow else 0.4)) / th), 2.0, 14.0)
	else:
		k = clampf(floorf(sh * (0.3 if narrow else 0.42) / th), 2.0, 24.0)
	var fs := Vector2(tw, th) * k
	if fig != "":
		var talk2 := _mouth if _speaker == pid else 0
		var key2 := "fig|%s|%s|%d" % [fig, str(_pres["mood"]), talk2]
		if key2 != str(_pres.get("tkey", "")):
			_pres["tkey"] = key2
			subject.texture = FigureArt.texture(fig, str(_pres["mood"]), talk2, false)
	elif pid != "":
		var talk := _mouth if _speaker == pid else 0
		var key := "%s|%s|%d" % [pid, str(_pres["mood"]), talk]
		if key != str(_pres.get("tkey", "")):
			_pres["tkey"] = key
			subject.texture = PortraitArt.frame(pid, str(_pres["mood"]), talk, false)
	var grow := _ease_out(clampf(t / 0.9, 0.0, 1.0))
	var sc := lerpf(0.9, 1.0, grow)
	var alpha := grow
	# Un portrait seul flotte doucement ; un personnage en pied respire, et seuls ceux qui volent planent.
	# Les sprites de combat (pillards, loups, gardes…) se tiennent au sol eux aussi.
	var sprite_body := fig == "" and pid == ""
	var dy := sin(t * 0.9) * k * 1.5 if (fig == "" and not sprite_body) or FigureArt.flies(fig) else 0.0
	var dx := 0.0
	var rot := 0.0
	var flash := 0.0
	var flash_col := Color.WHITE
	var dark := 0.0
	var desat := 0.0
	_pres["act_t"] = float(_pres["act_t"]) + delta
	var at := float(_pres["act_t"])
	match str(_pres["act"]):
		"roar":
			sc *= 1.0 + 0.1 * sin(PI * clampf(at / 0.5, 0.0, 1.0))
			flash = 0.5 * clampf(1.0 - at / 0.7, 0.0, 1.0)
			flash_col = Color(1.0, 0.45, 0.45)
		"hit":
			dx = sin(at * 55.0) * k * 1.5 * clampf(1.0 - at / 0.4, 0.0, 1.0)
			flash = clampf(1.0 - at / 0.22, 0.0, 1.0)
		"fall":
			var u := _ease_in_out(clampf(at / 0.9, 0.0, 1.0))
			dy += fs.y * 0.1 * u
			rot = 0.05 * u
			dark = 0.3 * u
			desat = 0.4 * u
		"glow":
			flash = 0.65 * clampf(1.0 - at / 1.1, 0.0, 1.0)
			flash_col = _aura.get("col", Color.WHITE)
		"fade":
			alpha *= clampf(1.0 - at / 1.3, 0.0, 1.0)
			sc *= 1.0 + 0.05 * clampf(at / 1.3, 0.0, 1.0)
			if at > 1.35 and bool(_pres.get("fading", false)):
				subject.visible = false
				if not _aura.is_empty():
					_fx.erase(_aura)
				_aura = {}
				_pres = {}
				return
		"rise":
			sc *= lerpf(0.94, 1.0, clampf(at / 0.8, 0.0, 1.0))
	# Sur un écran en hauteur, la créature se tient au-dessus des bustes (dans le ciel du décor), sinon au centre.
	var base_y := ground_y + (fs.y * 0.1 if pid != "" else -sh * 0.04)
	if narrow:
		base_y = ground_y - _fig_scale() * 64.0 * 0.62
	if sprite_body:
		base_y = ground_y + sh * 0.04
	if fig != "":
		# Les pieds au sol du décor, derrière les bustes (qui cachent le bas du corps, comme au premier plan).
		base_y = ground_y + sh * 0.08
		if FigureArt.flies(fig):
			base_y -= sh * 0.3
		sc *= 1.0 + 0.008 * sin(t * 1.4)
	var bottom := Vector2(size.x * 0.5 + dx, base_y + dy)
	if fig != "":
		# La tête au centre de l'écran (le Cerf, de trois quarts, a la tête sur la gauche de son image) ;
		# le corps peut déborder du cadre.
		bottom.x += (tw * 0.5 - FigureArt.head_center(fig).x) * k * 0.85
	var b2 := _cam_point(bottom, 0.7)
	var cs := 1.0 + (_cam_s - 1.0) * 0.7
	subject.size = fs
	subject.pivot_offset = Vector2(fs.x * 0.5, fs.y)
	subject.scale = Vector2.ONE * sc * cs
	subject.rotation = rot
	subject.position = b2 - subject.pivot_offset
	var tint: Color = _pres["tint"]
	subject.modulate = Color(tint * _grade, alpha)
	var m := subject.material as ShaderMaterial
	if m != null:
		m.set_shader_parameter("flash", flash)
		m.set_shader_parameter("flash_col", flash_col)
		m.set_shader_parameter("dark", dark)
		m.set_shader_parameter("desat", desat)
		m.set_shader_parameter("rim_col", Color(_aura.get("col", Color.WHITE), 0.5))
	if fig != "":
		var hc := FigureArt.head_center(fig)
		_pres["center"] = b2 + Vector2((hc.x - tw * 0.5) * k * sc * cs, -(th - hc.y) * k * sc * cs)
	else:
		_pres["center"] = b2 + Vector2(0.0, -fs.y * 0.55 * sc * cs)
	if not _aura.is_empty():
		_aura["r"] = fs.x * 0.6 * sc * cs
		_aura["alpha"] = alpha


# ---------------------------------------------------------------- effets

func _update_fx(delta: float) -> void:
	for e in _fx.duplicate():
		e["t"] = float(e["t"]) + delta
		var kind := str(e["kind"])
		if kind.begins_with("emit_"):
			e["acc"] = float(e["acc"]) + float(e["rate"]) * delta
			while float(e["acc"]) >= 1.0:
				e["acc"] = float(e["acc"]) - 1.0
				_emit(e)
		if kind == "heartbeat":
			var hb2 := int(float(e["t"]) / 1.1)
			if hb2 != int(e["beat"]) and float(e["t"]) < float(e["dur"]) - 0.5:
				e["beat"] = hb2
				_punch = 0.6
		if kind == "anvil":
			var beat3 := int(float(e["t"]) / 0.5)
			if beat3 != int(e["beat"]) and beat3 < 3:
				e["beat"] = beat3
				_burst(_fx_pos(e), e["col"], 30, "light")
				_kick_v += Vector2(0.0, 50.0)
				var rg3 := _add_fx("ring", "", e["col"], "light", 0.4)
				rg3["at"] = _fx_pos(e)
				rg3["R"] = _sh() * 0.15
		if kind == "bellring":
			var beat5 := int(float(e["t"]) / 0.8)
			if beat5 != int(e["beat"]) and beat5 < 3:
				e["beat"] = beat5
				_kick_v += Vector2(0.0, 70.0)
				for q in range(2):
					var rg5 := _add_fx("ring", "", e["col"], "light", 1.1 + 0.3 * float(q))
					rg5["at"] = _fx_pos(e)
					rg5["R"] = _sh() * (0.45 + 0.25 * float(q))
		if kind == "drums":
			# Rythme : boum… boum… BOUM (le troisième plus fort).
			var beat2 := int(float(e["t"]) / 0.55)
			if beat2 != int(e["beat"]) and float(e["t"]) < float(e["dur"]) - 0.4:
				e["beat"] = beat2
				var strong := beat2 % 3 == 2
				_kick_v += Vector2(0.0, 90.0 if strong else 45.0)
				var g2 := _anchor_pos("ground")
				var rg2 := _add_fx("ring", "", e["col"], "back", 0.6)
				rg2["at"] = g2
				rg2["sq"] = 0.22
				rg2["R"] = _sh() * (0.5 if strong else 0.3)
				if strong:
					_dust(g2, 10)
		if kind == "hooves":
			var beat := int(float(e["t"]) / 0.42)
			if beat != int(e["beat"]) and float(e["t"]) < float(e["dur"]) - 0.4:
				e["beat"] = beat
				var g := _anchor_pos("ground") + Vector2(randf_range(-0.25, 0.25) * size.x, 0.0)
				_dust(g, 5 + beat)
				_kick_v += Vector2(0.0, 60.0 + 25.0 * float(beat))
				var rg := _add_fx("ring", "", Color("d8c8b0"), "back", 0.5)
				rg["at"] = g
				rg["sq"] = 0.25
				rg["R"] = _sh() * (0.2 + 0.05 * float(beat))
		if float(e["t"]) > float(e["dur"]):
			_fx.erase(e)


func _fx_pos(e: Dictionary) -> Vector2:
	if e.has("at"):
		return e["at"]
	return _anchor_pos(str(e["anchor"])) + (e.get("off", Vector2.ZERO) as Vector2)


## Une particule pour un émetteur.
func _emit(e: Dictionary) -> void:
	var c := _fx_pos(e)
	var col: Color = e["col"]
	var sh := _sh()
	match str(e["kind"]):
		"emit_wisps":
			var p := c + Vector2(randf_range(-1.0, 1.0) * sh * 0.22, randf_range(-0.2, 0.3) * sh * 0.3)
			_part({"p": p, "v": Vector2(randf_range(-6, 6), randf_range(-38, -18)), "max": randf_range(1.4, 2.4), "col": col,
				"size": 2.0 if randf() < 0.4 else 1.0, "layer": "back", "sway": randf_range(10, 22), "kind": "sq"})
			if randf() < 0.35:
				_part({"p": p, "v": Vector2(0, randf_range(-30, -14)), "max": 1.6, "col": col.lightened(0.5), "size": 1.0, "layer": "light",
					"sway": 14.0, "kind": "sq"})
		"emit_charge":
			var a := randf() * TAU
			var rr := sh * randf_range(0.25, 0.45)
			_part({"p": c + Vector2.from_angle(a) * rr, "v": Vector2.from_angle(a + PI) * 40.0, "max": 1.0, "col": col.lightened(0.3),
				"size": 1.0 if randf() < 0.7 else 2.0, "layer": "light", "target": c, "speed": rr * 1.6, "kind": "sq"})
		"emit_motes":
			var p2 := c + Vector2(randf_range(-0.6, 0.6) * sh * 0.25, randf_range(0.0, 0.7) * sh * 0.3)
			_part({"p": p2, "v": Vector2(randf_range(-8, 8), randf_range(-60, -30)), "max": randf_range(0.8, 1.4), "col": col.lightened(0.35),
				"size": 1.0, "layer": "light", "sway": 8.0, "kind": "sq"})
		"emit_dissolve":
			var hs := sh * 0.32
			var p3 := c + Vector2(randf_range(-1.0, 1.0) * hs, randf_range(-1.0, 1.0) * hs)
			_part({"p": p3, "v": Vector2(randf_range(-10, 10), randf_range(-70, -30)), "max": randf_range(1.0, 1.8), "col": col.lightened(0.3),
				"size": 1.0 if randf() < 0.6 else 2.0, "layer": "light", "sway": 12.0, "kind": "sq"})
		"emit_embers_at":
			_part({"p": c + Vector2(randf_range(-1.0, 1.0) * sh * 0.05, -sh * 0.05), "v": Vector2(randf_range(-12, 12), randf_range(-60, -30)),
				"max": randf_range(0.8, 1.4), "col": col.lerp(Color.WHITE, randf() * 0.4), "size": 1.0, "layer": "light", "sway": 10.0, "kind": "sq"})
		"emit_fountain":
			_part({"p": c + Vector2(randf_range(-10, 10), 0.0), "v": Vector2(randf_range(-90, 90), -randf_range(480, 660)), "max": randf_range(1.6, 2.2),
				"col": col.lerp(Color.WHITE, randf() * 0.5), "size": 2.0 if randf() < 0.5 else 1.0, "layer": "light", "grav": Vector2(0, 560), "drag": 0.2,
				"kind": "sq"})
		"emit_renewal":
			var rp2 := Vector2(randf_range(0.05, 0.95) * size.x, ground_y + 6.0)
			_part({"p": rp2, "v": Vector2(randf_range(-20, 20), randf_range(-120, -70)), "max": randf_range(2.0, 3.2), "col": col.lerp(Color("e8ffb0"), randf()),
				"size": 1.0, "layer": "light" if randf() < 0.5 else "front", "sway": 40.0, "drag": 0.2, "kind": "leaf" if randf() < 0.5 else "sq"})
		"emit_drip":
			var top := c + Vector2(randf_range(-1.0, 1.0) * sh * 0.3, -sh * randf_range(0.25, 0.45))
			_part({"p": top, "v": Vector2(0.0, randf_range(10, 30)), "max": randf_range(0.9, 1.4), "col": col.lightened(0.2), "size": 1.0,
				"layer": "light", "grav": Vector2(0, 220), "drag": 0.2, "kind": "sq"})
		"emit_glitter":
			var gp := c + Vector2.from_angle(randf() * TAU) * sh * randf_range(0.05, 0.32)
			_part({"p": gp, "v": Vector2(randf_range(-6, 6), randf_range(-14, 4)), "max": randf_range(0.5, 0.9), "col": col.lerp(Color.WHITE, randf() * 0.6),
				"size": 1.0, "layer": "light", "kind": "star"})
		"emit_steam":
			if _figs.has(str(e["anchor"])):
				var sf: Dictionary = _figs[str(e["anchor"])]
				var big := float(sf.get("S", sh))
				var side_x := -1.0 if randf() < 0.5 else 1.0
				var hp := (sf.get("bottom", c) as Vector2) + Vector2(side_x * big * 0.24, -big * 0.6)
				_part({"p": hp, "v": Vector2(side_x * randf_range(40, 80), randf_range(-70, -40)), "max": randf_range(0.5, 0.8), "col": col,
					"size": randf_range(6.0, 11.0), "layer": "front", "drag": 2.0, "kind": "puff"})
		"emit_embers":
			_part({"p": Vector2(randf() * size.x, ground_y + 10.0), "v": Vector2(randf_range(-10, 10), randf_range(-90, -50)),
				"max": randf_range(2.0, 3.5), "col": col.lerp(Color("ffe08a"), randf()), "size": 1.0, "layer": "light", "sway": 18.0, "kind": "sq"})
		"emit_smoke":
			_part({"p": c + Vector2(randf_range(-8, 8), randf_range(-4, 4)), "v": Vector2(randf_range(-4, 12), randf_range(-40, -22)), "max": randf_range(2.4, 3.4), "col": col,
				"size": randf_range(3.0, 6.0), "layer": "back", "drag": 0.2, "sway": 10.0, "kind": "puff"})
		"emit_breath":
			if _figs.has(str(e["anchor"])):
				var bf: Dictionary = _figs[str(e["anchor"])]
				var big2 := float(bf.get("S", sh))
				var side_x2 := 1.0 if float(bf.get("side", 1.0)) < 0.0 else -1.0
				var hp3 := (bf.get("bottom", c) as Vector2) + Vector2(side_x2 * big2 * 0.18, -big2 * 0.42)
				_part({"p": hp3, "v": Vector2(side_x2 * randf_range(30, 60), randf_range(-14, -4)), "max": randf_range(0.8, 1.2), "col": col,
					"size": randf_range(3.0, 6.0), "layer": "front", "drag": 1.5, "kind": "puff"})
		"emit_spectral":
			var sa := randf() * TAU
			_part({"p": c + Vector2(cos(sa) * sh * 0.22, sin(sa) * sh * 0.08 + sh * 0.1), "v": Vector2(randf_range(-8, 8), randf_range(-60, -30)), "max": randf_range(1.2, 2.0),
				"col": col.lerp(Color.WHITE, randf() * 0.4), "size": 1.0 if randf() < 0.6 else 2.0, "layer": "light", "sway": 16.0, "kind": "sq"})
		"emit_glint":
			_part({"p": Vector2(randf() * size.x, ground_y - randf_range(0.0, sh * 0.35)), "v": Vector2.ZERO, "max": randf_range(0.4, 0.8),
				"col": col, "size": 1.0, "layer": "light", "kind": "star"})
		"emit_ink":
			_part({"p": c + Vector2(randf_range(-1, 1) * sh * 0.1, randf_range(-1, 1) * sh * 0.08), "v": Vector2.from_angle(randf() * TAU) * randf_range(60, 200),
				"max": randf_range(1.4, 2.2), "col": col.lerp(Color("2a1a3a"), randf() * 0.5), "size": randf_range(18.0, 36.0), "layer": "front", "drag": 1.6, "kind": "puff"})
		"emit_ashfall":
			var ember := randf() < 0.22
			_part({"p": Vector2(randf() * size.x, top_y + randf_range(-10.0, sh * 0.1)), "v": Vector2(randf_range(-10, 20), randf_range(30, 60)),
				"max": randf_range(2.5, 4.0), "col": col.lerp(Color("ffd070"), randf() * 0.5) if ember else Color("8a8480").lerp(Color("4a4440"), randf()),
				"size": 1.0 if ember or randf() < 0.6 else 2.0, "layer": "light" if ember else "front", "sway": randf_range(14, 30), "kind": "sq"})
		"emit_phoenix":
			var bp := c + _phoenix_off(float(e["t"]))
			_part({"p": bp + Vector2(randf_range(-4, 4), randf_range(0, 6)), "v": Vector2(randf_range(-30, 30), randf_range(10, 60)), "max": randf_range(0.6, 1.1),
				"col": col.lerp(Color("fff0a0"), randf() * 0.6), "size": 1.0 if randf() < 0.7 else 2.0, "layer": "light", "grav": Vector2(0, 60), "drag": 1.2, "kind": "sq"})
		"emit_dragonfire":
			var dir3 := float(e.get("dir", 1.0))
			var to := Vector2(size.x * (0.5 + dir3 * 0.38), ground_y + sh * 0.02)
			var aim := (to - c).normalized().rotated(randf_range(-0.12, 0.12))
			var sp6 := randf_range(420.0, 620.0)
			_part({"p": c + aim * sh * 0.04, "v": aim * sp6, "max": randf_range(0.45, 0.75), "col": [Color("fff0a0"), Color("ffb040"), Color("ff6a1a"), Color("d83a1a")][randi() % 4],
				"size": randf_range(5.0, 12.0), "layer": "front", "drag": 1.4, "kind": "puff"})
		"emit_ashswirl":
			var sa4 := randf() * TAU
			var rr4 := sh * randf_range(0.12, 0.3)
			var tang := Vector2.from_angle(sa4 + PI * 0.5)
			_part({"p": c + Vector2.from_angle(sa4) * rr4 * Vector2(1.0, 0.45) + Vector2(0, sh * 0.15), "v": tang * randf_range(90, 160) + Vector2(0, -randf_range(40, 90)),
				"max": randf_range(1.0, 1.8), "col": col.lerp(Color.WHITE, randf() * 0.5), "size": 1.0 if randf() < 0.7 else 2.0, "layer": "light",
				"sway": 20.0, "drag": 0.6, "kind": "sq"})
		"emit_pages":
			var pa := randf() * TAU
			_part({"p": c + Vector2.from_angle(pa) * sh * 0.08, "v": Vector2.from_angle(pa) * randf_range(60, 120) + Vector2(0, -40), "max": randf_range(1.2, 1.8),
				"col": col, "size": 3.0, "layer": "front", "grav": Vector2(0, 40), "drag": 0.8, "sway": 30.0, "kind": "leaf"})
		"emit_bubbles":
			_part({"p": Vector2(randf() * size.x, ground_y + randf_range(-4.0, 10.0)), "v": Vector2(randf_range(-6, 6), randf_range(-70, -35)), "max": randf_range(0.8, 1.6),
				"col": col.lerp(Color.WHITE, randf() * 0.3), "size": 2.0 if randf() < 0.4 else 1.0, "layer": "light", "sway": 10.0, "kind": "sq"})
		"emit_chant":
			var a6 := randf() * TAU
			_part({"p": c + Vector2.from_angle(a6) * sh * 0.12, "v": Vector2.from_angle(a6 + PI * 0.5) * 50.0 + Vector2(0, -50), "max": randf_range(1.2, 1.8),
				"col": col.lerp(Color("ffe08a"), randf() * 0.6), "size": 1.0, "layer": "light", "sway": 24.0, "kind": "star" if randf() < 0.4 else "sq"})
		"emit_leaves":
			var leaf_c: Array = [Color("4f8a3e"), Color("7ab04f"), Color("c8a040"), Color("a8602a")]
			_part({"p": Vector2(randf_range(-0.1, 1.0) * size.x, -8.0), "v": Vector2(randf_range(20, 45), randf_range(28, 50)),
				"max": randf_range(6.0, 10.0), "col": leaf_c[randi() % leaf_c.size()], "size": 1.0, "layer": "front", "sway": 30.0,
				"kind": "leaf", "drag": 0.0})


func _start_leaves() -> void:
	for e in _fx:
		if str(e["kind"]) == "emit_leaves":
			return
	var e2 := _add_fx("emit_leaves", "sky", Color.WHITE, "front", 1e9)
	e2["rate"] = 1.6


func _part(d: Dictionary) -> void:
	if _parts.size() > 700:
		return
	d["life"] = 0.0
	d["ph"] = randf() * TAU
	if not d.has("grav"):
		d["grav"] = Vector2.ZERO
	if not d.has("drag"):
		d["drag"] = 0.6
	if not d.has("sway"):
		d["sway"] = 0.0
	_parts.append(d)


func _burst(at: Vector2, col: Color, n: int, layer: String) -> void:
	for i in range(n):
		var a := randf() * TAU
		var sp := randf_range(90.0, 320.0)
		_part({"p": at, "v": Vector2.from_angle(a) * sp, "max": randf_range(0.45, 0.9), "col": col.lerp(Color.WHITE, randf() * 0.5),
			"size": 2.0 if randf() < 0.3 else 1.0, "layer": layer, "grav": Vector2(0, 260), "drag": 2.2, "kind": "sq"})


func _dust(at: Vector2, n: int) -> void:
	for i in range(n):
		var dir := -1.0 if i % 2 == 0 else 1.0
		_part({"p": at + Vector2(randf_range(-0.3, 0.3) * size.x * 0.3, randf_range(-6, 6)), "v": Vector2(dir * randf_range(40, 140), randf_range(-30, -5)),
			"max": randf_range(0.7, 1.2), "col": Color("b8a898"), "size": randf_range(8.0, 18.0), "layer": "back", "drag": 2.5, "kind": "puff"})


func _update_parts(delta: float) -> void:
	var keep: Array = []
	for p in _parts:
		p["life"] = float(p["life"]) + delta
		if float(p["life"]) > float(p["max"]):
			continue
		var v: Vector2 = p["v"]
		var pos: Vector2 = p["p"]
		if p.has("target"):
			var tgt: Vector2 = p["target"]
			var to := tgt - pos
			if to.length() < 6.0:
				continue
			v = v.lerp(to.normalized() * float(p["speed"]), clampf(delta * 5.0, 0.0, 1.0))
		v += (p["grav"] as Vector2) * delta
		v *= 1.0 - clampf(float(p["drag"]) * delta, 0.0, 1.0)
		pos += v * delta
		pos.x += sin(float(p["ph"]) + float(p["life"]) * 3.0) * float(p["sway"]) * delta
		p["v"] = v
		p["p"] = pos
		keep.append(p)
	_parts = keep


# ---------------------------------------------------------------- dessin (calques basse résolution)

func draw_layer(ci: CanvasItem, layer: String) -> void:
	var k := 1.0 / px
	for e in _fx:
		if str(e["layer"]) == layer:
			_draw_fx(ci, e, k)
	for p in _parts:
		if str(p["layer"]) != layer:
			continue
		var u := float(p["life"]) / float(p["max"])
		var col: Color = p["col"]
		var a := 1.0 - u * u
		var pos: Vector2 = (p["p"] as Vector2) * k
		match str(p["kind"]):
			"puff":
				ci.draw_circle(pos, float(p["size"]) * k * (0.6 + u), Color(col, 0.35 * (1.0 - u)))
			"star":
				var tw := sin(u * PI)
				var arm := 1.0 + floorf(tw * 4.0)
				ci.draw_circle(pf_glow(pos), 3.0 + arm, Color(col, tw * 0.15))
				var pf := pos.floor()
				ci.draw_rect(Rect2(pf, Vector2.ONE), Color(Color.WHITE, tw))
				ci.draw_rect(Rect2(pf - Vector2(arm, 0), Vector2(arm * 2.0 + 1.0, 1)), Color(col, tw * 0.8))
				ci.draw_rect(Rect2(pf - Vector2(0, arm), Vector2(1, arm * 2.0 + 1.0)), Color(col, tw * 0.8))
			"leaf":
				var flip := sin(float(p["ph"]) + float(p["life"]) * 5.0) > 0.0
				ci.draw_rect(Rect2(pos.floor(), Vector2(2, 1) if flip else Vector2(1, 2)), Color(col, minf(1.0, (1.0 - u) * 3.0)))
			_:
				var s := float(p["size"])
				ci.draw_rect(Rect2(pos.floor(), Vector2(s, s)), Color(col, a))
	if layer == "front":
		for em in _emotes:
			_draw_emote(ci, em, k)


func _draw_fx(ci: CanvasItem, e: Dictionary, k: float) -> void:
	var t := float(e["t"])
	var dur := float(e["dur"])
	var u := clampf(t / maxf(0.01, dur), 0.0, 1.0)
	var c := _fx_pos(e) * k
	var col: Color = e["col"]
	match str(e["kind"]):
		"bloom", "aura":
			var a := 0.0
			if str(e["kind"]) == "aura":
				a = (0.4 + 0.12 * sin(_t * 2.0)) * float(e.get("alpha", 1.0))
			else:
				a = t / 0.08 if t < 0.08 else 1.0 - (t - 0.08) / maxf(0.01, dur - 0.08)
			var rr := float(e["r"]) * k
			for i in range(7):
				var f := 1.0 - float(i) / 7.0
				ci.draw_circle(c, rr * f, Color(col, a * 0.07))
			if str(e["kind"]) == "bloom":
				ci.draw_circle(c, rr * 0.08, Color(Color.WHITE, a * 0.5))
		"ring":
			var r := float(e["R"]) * k * _ease_out(u)
			var a2 := 1.0 - u
			ci.draw_set_transform(c, 0.0, Vector2(1.0, float(e["sq"])))
			ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, Color(col, a2), maxf(1.0, 3.0 * (1.0 - u)))
			ci.draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, 48, Color(col, a2 * 0.4), 1.0)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"rays":
			var a3 := minf(1.0, t / 0.3) * minf(1.0, (dur - t) / 0.8)
			var rot := float(e["rot"]) + t * 0.25
			var big := float(e["r"]) * k * 2.2
			for i in range(10):
				var ang := rot + float(i) * TAU / 10.0
				var w := 0.05 + 0.02 * sin(_t * 3.0 + float(i))
				ci.draw_primitive(PackedVector2Array([c, c + Vector2.from_angle(ang - w) * big, c + Vector2.from_angle(ang + w) * big]),
					PackedColorArray([Color(col, a3 * 0.3), Color(col, 0.0), Color(col, 0.0)]), PackedVector2Array())
		"seal":
			var r0 := float(e["r"]) * k
			var p := clampf(t / 0.9, 0.0, 1.0)
			var a4 := minf(1.0, (dur - t) / 0.6)
			var cc := Color(col, a4)
			# Échos : copies du Sceau qui s'élargissent et pâlissent, l'une après l'autre.
			for j in range(4):
				var et := fmod(t - 0.35 * float(j), 1.4)
				if t > 0.9 + 0.35 * float(j) and et >= 0.0:
					var eu := et / 1.4
					var er := r0 * (1.0 + eu * 1.8)
					var ec := Color(col, a4 * 0.5 * (1.0 - eu))
					ci.draw_arc(c, er, 0.0, TAU, 40, ec, 1.0)
					var ed := Vector2.from_angle(-PI / 3.0) * er * 1.25
					ci.draw_line((c - ed).floor(), (c + ed).floor(), ec, 1.0)
			ci.draw_arc(c, r0, -PI * 0.5, -PI * 0.5 + p * TAU, 40, Color(col, a4 * 0.35), 3.0)
			ci.draw_arc(c, r0, -PI * 0.5, -PI * 0.5 + p * TAU, 40, Color(Color.WHITE, a4), 1.0)
			if t > 0.6:
				var q := clampf((t - 0.6) / 0.4, 0.0, 1.0)
				var d := Vector2.from_angle(-PI / 3.0) * r0 * 1.25
				ci.draw_line((c - d).floor(), (c - d + d * 2.0 * q).floor(), Color(col, a4 * 0.4), 3.0)
				ci.draw_line((c - d).floor(), (c - d + d * 2.0 * q).floor(), cc, 1.0)
			ci.draw_circle(c, r0 * 0.25 * (1.0 + 0.25 * sin(_t * 8.0)), Color(Color.WHITE, a4 * 0.5))
		"spiral":
			var r1 := float(e["r"]) * k
			var a5 := minf(1.0, t / 0.6) * minf(1.0, (dur - t) / 0.8)
			# Cadran du temps : douze marques qui tournent lentement, deux aiguilles qui tournent à rebours.
			for j in range(12):
				var ang := -t * 0.3 + float(j) * TAU / 12.0
				var p0 := c + Vector2.from_angle(ang) * r1 * 0.92
				var p1 := c + Vector2.from_angle(ang) * r1 * (0.8 if j % 3 == 0 else 0.86)
				ci.draw_line(p0.floor(), p1.floor(), Color(col, a5 * 0.8), 1.0)
			ci.draw_arc(c, r1, 0.0, TAU, 64, Color(col, a5 * 0.35), 1.0)
			ci.draw_line(c.floor(), (c + Vector2.from_angle(-t * 4.0) * r1 * 0.55).floor(), Color(Color.WHITE, a5), 1.0)
			ci.draw_line(c.floor(), (c + Vector2.from_angle(-t * 0.9) * r1 * 0.38).floor(), Color(col.lightened(0.4), a5), 2.0)
			# Bras de lumière qui s'enroulent vers le centre.
			for arm in range(3):
				var pts := PackedVector2Array()
				for j in range(24):
					var f := float(j) / 23.0
					var ang2 := float(arm) * TAU / 3.0 + f * 5.0 - t * 1.6
					pts.append((c + Vector2.from_angle(ang2) * r1 * 0.75 * (1.0 - f)).floor())
				ci.draw_polyline(pts, Color(col, a5 * 0.55), 1.0)
		"flux":
			var r2 := float(e["r"]) * k
			var a6 := minf(1.0, t / 0.25) * minf(1.0, (dur - t) / 0.5)
			for i in range(6):
				var ang3 := float(i) * TAU / 6.0 + 0.4 + float(e["rot"])
				var start := c + Vector2.from_angle(ang3) * r2
				var perp := Vector2.from_angle(ang3 + PI * 0.5)
				var pts2 := PackedVector2Array()
				var head := clampf(t / 0.7, 0.0, 1.0)
				for j in range(20):
					var f2 := float(j) / 19.0 * head
					var wave := sin(f2 * TAU * 1.5 - t * 9.0 + float(i)) * r2 * 0.08 * (1.0 - f2)
					pts2.append((start.lerp(c, f2) + perp * wave).floor())
				ci.draw_polyline(pts2, Color(col, a6 * 0.3), 3.0)
				ci.draw_polyline(pts2, Color(col.lightened(0.4), a6 * 0.9), 1.0)
			ci.draw_circle(c, r2 * 0.06 * (1.0 + 0.3 * sin(_t * 10.0)), Color(Color.WHITE, a6 * 0.6))
		"arrow":
			var to := _fx_pos(e)
			var from: Vector2 = e["from"]
			var fly := clampf(t / 0.2, 0.0, 1.0)
			var pos := from.lerp(to, fly)
			var dir := (to - from).normalized()
			if fly >= 1.0 and not bool(e["landed"]):
				e["landed"] = true
				_dust(to, 8)
				_kick_impulse(6.0)
			var wob := 0.0 if fly < 1.0 else sin(t * 60.0) * 0.12 * maxf(0.0, 1.0 - (t - 0.2) / 0.5)
			var d2 := dir.rotated(wob)
			var a8 := minf(1.0, (dur - t) / 0.4)
			var tip := (pos * k).floor()
			var tail := tip - d2 * 22.0
			ci.draw_line(tail, tip, Color(Color("8a5a2b"), a8), 2.0)
			ci.draw_line(tip, tip - d2.rotated(0.55) * 5.0, Color(col, a8), 2.0)
			ci.draw_line(tip, tip - d2.rotated(-0.55) * 5.0, Color(col, a8), 2.0)
			ci.draw_line(tail, tail - d2.rotated(0.5) * 6.0, Color(Color("8fd16a"), a8), 2.0)
			ci.draw_line(tail, tail - d2.rotated(-0.5) * 6.0, Color(Color("8fd16a"), a8), 2.0)
			if fly < 1.0:
				ci.draw_line(tail, tail - d2 * 30.0, Color(Color.WHITE, 0.35), 1.0)
		"clang":
			var a10 := 1.0 - u
			var rc := _sh() * 0.07 * k * (0.6 + 0.6 * _ease_out(u))
			for i in range(4):
				var ang5 := float(i) * PI * 0.5 + PI * 0.25
				ci.draw_line(c.floor(), (c + Vector2.from_angle(ang5) * rc).floor(), Color(col, a10), 2.0)
			for i in range(4):
				var ang6 := float(i) * PI * 0.5
				ci.draw_line(c.floor(), (c + Vector2.from_angle(ang6) * rc * 0.55).floor(), Color(Color.WHITE, a10), 1.0)
			ci.draw_arc(c, rc * 0.8, 0.0, TAU, 24, Color(col, a10 * 0.6), 1.0)
		"thorns":
			var stems2: PackedVector2Array = e["pts"]
			var hgt := float(e["r"]) * k
			var a11 := minf(1.0, (dur - t) / 0.8)
			var grow := _ease_out(clampf(t / 1.4, 0.0, 1.0))
			var gnd := (_anchor_pos("ground") * k).y + 4.0
			for i in range(stems2.size()):
				var st2 := stems2[i]
				var x0 := c.x + st2.x * hgt * 0.9
				var pts3 := PackedVector2Array()
				var n2 := 14
				for j in range(n2 + 1):
					var f3 := float(j) / float(n2) * grow * st2.y
					var sway := sin(f3 * 5.0 + float(i) + t * 1.5) * hgt * 0.06 * f3
					pts3.append(Vector2(x0 + sway + st2.x * f3 * hgt * 0.25, gnd - f3 * hgt).floor())
				ci.draw_polyline(pts3, Color(Color("2a1430"), a11), 3.0)
				ci.draw_polyline(pts3, Color(col, a11), 1.0)
				for j in range(2, pts3.size(), 3):
					var sp2 := pts3[j]
					var sd2 := 1.0 if j % 2 == 0 else -1.0
					ci.draw_line(sp2, sp2 + Vector2(sd2 * 3.0, -2.0), Color(col.lightened(0.3), a11), 1.0)
		"timestop":
			var bands2: PackedVector2Array = e["pts"]
			var a13 := minf(1.0, t / 0.15) * minf(1.0, (dur - t) / 0.6)
			var W := size.x * k
			var H := _sh() * k
			for i in range(bands2.size()):
				var bd := bands2[i]
				var by := fmod(bd.x * H + t * (8.0 + float(i) * 3.0), H)
				var off2 := sin(t * 23.0 + float(i) * 5.0) * 6.0
				var on := sin(t * 17.0 + float(i) * 2.3) > -0.2
				if on:
					ci.draw_rect(Rect2(off2, by, W, bd.y), Color(col, a13 * 0.13))
					ci.draw_rect(Rect2(off2 + W * 0.1 * float(i % 3), by, W * 0.25, 1.0), Color(Color.WHITE, a13 * 0.35))
		"flicker":
			var gust := float(e.get("gust", 0.0))
			e["gust"] = maxf(0.0, gust - 0.016)
			var fa := minf(1.0, t / 0.4) * minf(1.0, (dur - t) / 0.6)
			var jit := 0.85 + 0.1 * sin(_t * 17.0) + 0.06 * sin(_t * 31.0) - gust * 0.45
			var fr := float(e["r"]) * k * jit
			for i in range(6):
				var fq := 1.0 - float(i) / 6.0
				ci.draw_circle(c + Vector2(gust * 6.0 * fq, 0.0), fr * fq, Color(col, fa * 0.11))
			ci.draw_circle(c, fr * 0.12, Color(Color("fff6d0"), fa * 0.7 * jit))
		"wind":
			var st3: PackedVector2Array = e["pts"]
			var W2 := size.x * k
			var H2 := _sh() * k
			for i in range(st3.size()):
				var sd3 := st3[i]
				var sx := fmod(sd3.x * W2 + t * W2 * (0.9 + sd3.y), W2 * 1.3) - W2 * 0.15
				var sy2 := H2 * (0.15 + 0.7 * fmod(sd3.x * 7.3, 1.0)) + sin(t * 6.0 + float(i)) * 3.0
				var ln2 := W2 * (0.06 + 0.06 * sd3.y)
				ci.draw_line(Vector2(sx, sy2).floor(), Vector2(sx - ln2, sy2 + 1.0).floor(), Color(col, (1.0 - u) * 0.45), 1.0)
		"eyes":
			var pr: PackedVector2Array = e["pts"]
			var a14 := minf(1.0, (dur - t) / 0.5)
			for i in range(pr.size()):
				var on2 := clampf((t - 0.25 * float(i)) / 0.3, 0.0, 1.0)
				var blink2 := fmod(t + float(i) * 0.7, 2.3) < 0.12
				if on2 <= 0.0 or blink2:
					continue
				var ep := Vector2(pr[i].x * size.x, top_y + pr[i].y * _sh()) * k
				var ec2 := Color(col, a14 * on2)
				ci.draw_circle(ep + Vector2(3.0, 0.5), 6.0, Color(col, a14 * on2 * 0.18))
				ci.draw_rect(Rect2(ep.floor(), Vector2(2, 1)), ec2)
				ci.draw_rect(Rect2(ep.floor() + Vector2(5, 0), Vector2(2, 1)), ec2)
		"veins":
			var brs: Array = e["br"]
			var grow2 := clampf(t / 1.8, 0.0, 1.0)
			var a15 := minf(1.0, (dur - t) / 0.8) * (0.75 + 0.25 * sin(_t * 5.0))
			var sc2 := _sh() * k / 110.0
			for b in brs:
				var bp: PackedVector2Array = b
				var n3 := int(grow2 * float(bp.size() - 1)) + 1
				var seg := PackedVector2Array()
				for j in range(mini(n3 + 1, bp.size())):
					seg.append((c + bp[j] * sc2).floor())
				if seg.size() >= 2:
					ci.draw_polyline(seg, Color(col, a15 * 0.35), 3.0)
					ci.draw_polyline(seg, Color(col.lightened(0.3), a15), 1.0)
		"heartbeat":
			var ph2 := fmod(t, 1.1)
			var thump := maxf(exp(-ph2 * 9.0), 0.7 * exp(-maxf(0.0, ph2 - 0.22) * 9.0) * (1.0 if ph2 > 0.22 else 0.0))
			var a16 := minf(1.0, (dur - t) / 0.6)
			var hr := float(e["r"]) * k * (0.6 + 0.4 * thump)
			for i in range(6):
				var hq := 1.0 - float(i) / 6.0
				ci.draw_circle(c, hr * hq, Color(col, a16 * 0.06 * (0.4 + thump)))
		"willo":
			var ob: PackedVector2Array = e["pts"]
			var wr := float(e["r"]) * k
			var a17 := minf(1.0, t / 0.5) * minf(1.0, (dur - t) / 0.7)
			for i in range(ob.size()):
				var o2 := ob[i]
				for tr in range(6):
					var tt := t - float(tr) * 0.06
					var op := c + Vector2(cos(o2.x + tt * o2.y) * wr * 1.4, sin(o2.x * 2.0 + tt * o2.y * 1.6) * wr * 0.5)
					var ta := a17 * (1.0 - float(tr) / 6.0)
					if tr == 0:
						ci.draw_circle(op, 4.0, Color(col, ta * 0.2))
						ci.draw_rect(Rect2(op.floor() - Vector2.ONE, Vector2(2, 2)), Color(Color.WHITE, ta))
					else:
						ci.draw_rect(Rect2(op.floor(), Vector2.ONE), Color(col, ta * 0.6))
		"current":
			var W17 := size.x * k
			var H17 := size.y * k
			var ca := minf(1.0, t / 0.6) * minf(1.0, (dur - t) / 0.8)
			for i in range(40):
				var cx5 := fmod(float(i) * 61.7 + t * (220.0 + float(i % 4) * 50.0), W17 + 80.0) - 40.0
				var cy5 := (top_y * k) + fmod(float(i) * 31.3, H17 * 0.8) + sin(_t * 2.0 + float(i)) * 4.0
				var pts15 := PackedVector2Array()
				for q in range(6):
					pts15.append(Vector2(cx5 - float(q) * 5.0, cy5 + sin(float(q) * 0.9 + _t * 4.0) * 1.5).floor())
				ci.draw_polyline(pts15, Color(col, ca * 0.35), 1.0)
				if i % 5 == 0:
					ci.draw_arc(Vector2(cx5 + 6.0, cy5 - 3.0).floor(), 1.5, 0.0, TAU, 8, Color(col, ca * 0.7), 1.0)
		"tide":
			var W18 := size.x * k
			var H18 := size.y * k
			var lv := sin(PI * clampf(t / dur, 0.0, 1.0))
			var surf := (ground_y - _sh() * 0.55 * lv) * k
			var pts16 := PackedVector2Array()
			for q in range(33):
				var qx2 := W18 * float(q) / 32.0
				pts16.append(Vector2(qx2, surf + sin(_t * 3.0 + float(q) * 0.7) * 2.5 * k * 4.0).floor())
			var poly := pts16.duplicate()
			poly.append(Vector2(W18, H18))
			poly.append(Vector2(0.0, H18))
			ci.draw_colored_polygon(poly, Color(col, 0.22 * lv))
			ci.draw_polyline(pts16, Color(Color("d8f8ff"), 0.6 * lv), 1.0)
		"tentacles":
			var tg := _sh() * k
			var tu := t / dur
			var up := _ease_out(clampf(tu / 0.25, 0.0, 1.0)) * (1.0 - _ease_in(clampf((tu - 0.75) / 0.25, 0.0, 1.0)))
			var base15 := (ground_y + _sh() * 0.03) * k
			var tpts: PackedVector2Array = e["pts"]
			for i in range(tpts.size()):
				var tx := tpts[i].x * size.x * k
				var hgt := tg * 0.55 * tpts[i].y * up
				var prev := Vector2(tx, base15)
				for q in range(1, 13):
					var f := float(q) / 12.0
					var curl := sin(_t * 2.2 + float(i) * 1.3 + f * 3.0) * tg * 0.06 * f + (f * f * tg * 0.08 * (1.0 if i % 2 == 0 else -1.0))
					var p := Vector2(tx + curl, base15 - hgt * f)
					var wid := maxf(1.0, tg * 0.035 * (1.0 - f * 0.8))
					ci.draw_line(prev, p, col, wid)
					if q % 3 == 0 and wid > 2.0:
						ci.draw_circle(p + Vector2(wid * 0.4, 0.0), wid * 0.22, Color("e8c8d8"))
					prev = p
		"song":
			var sr5 := _sh() * k * 0.5
			var sa5 := minf(1.0, t / 0.4) * minf(1.0, (dur - t) / 0.8)
			for q in range(3):
				var ph2 := fmod(t / 1.2 + float(q) / 3.0, 1.0)
				var rr6 := sr5 * (0.15 + ph2)
				var pts17 := PackedVector2Array()
				for a6 in range(41):
					var ang7 := float(a6) / 40.0 * TAU
					var wob := 1.0 + 0.06 * sin(ang7 * 6.0 + _t * 4.0)
					pts17.append(c + Vector2(cos(ang7), sin(ang7) * 0.55) * rr6 * wob)
				ci.draw_polyline(pts17, Color(col, sa5 * (1.0 - ph2) * 0.6), 1.0)
		"threads":
			var W19 := size.x * k
			var ta := minf(1.0, t / 1.0) * minf(1.0, (dur - t) / 1.0)
			var xs2: PackedVector2Array = e["pts"]
			var pal3: Array = [Color("4fe3d2"), Color("8fe0ff"), Color("e86a8a"), Color("b07cff")]
			for i in range(xs2.size()):
				var tx2 := xs2[i].x * W19
				var c6: Color = pal3[i % 4]
				var fl2 := 0.35 + 0.25 * sin(_t * 2.0 + xs2[i].y * 9.0)
				ci.draw_line(Vector2(tx2, top_y * k), Vector2(tx2 + sin(_t * 0.6 + float(i)) * 2.0, ground_y * k), Color(c6, ta * fl2), 1.0)
			var beat6 := pow(maxf(0.0, sin(_t * 3.2)), 3.0)
			var gx3 := W19 * 0.5
			for i in range(5):
				ci.draw_line(Vector2(gx3, top_y * k), Vector2(gx3, ground_y * k), Color(col, ta * (0.08 + 0.06 * beat6)), 1.0 + float(i) * 2.0)
			ci.draw_line(Vector2(gx3, top_y * k), Vector2(gx3, ground_y * k), Color(Color("fff6d0"), ta), 1.0)
		"nacre":
			var nr := float(e["r"]) * k
			var na := minf(1.0, t / 0.5) * minf(1.0, (dur - t) / 0.8)
			var nc := c + Vector2(0.0, nr * 0.35)
			for q in range(24):
				var a8 := float(q) / 24.0 * TAU
				var hue := fmod(float(q) / 24.0 + _t * 0.2, 1.0)
				ci.draw_line(nc + Vector2.from_angle(a8) * nr, nc + Vector2.from_angle(a8 + TAU / 24.0) * nr, Color(Color.from_hsv(hue, 0.25, 1.0), na * 0.7), 1.0)
			ci.draw_circle(nc, nr, Color(col, na * 0.06))
			var hl := nc + Vector2.from_angle(-2.2 + sin(_t) * 0.3) * nr * 0.7
			ci.draw_circle(hl, 2.0, Color(Color.WHITE, na * 0.8))
		"blacktide":
			var br6 := float(e["r"]) * k
			var ba3 := minf(1.0, t / 0.8) * minf(1.0, (dur - t) / 0.8)
			for q in range(9):
				var a9 := float(q) / 9.0 * TAU + _t * 0.3
				var pts18 := PackedVector2Array()
				for d in range(10):
					var f3 := float(d) / 9.0
					var ang8 := a9 + sin(_t * 1.5 + float(q) + f3 * 3.0) * 0.5
					pts18.append(c + Vector2.from_angle(ang8) * br6 * (0.3 + f3 * 0.9) * Vector2(1.0, 0.8))
				ci.draw_polyline(pts18, Color(Color("120a1e"), ba3 * 0.8), 3.0)
				ci.draw_polyline(pts18, Color(col, ba3 * 0.5), 1.0)
		"firewall":
			var W14 := size.x * k
			var fa := minf(1.0, t / 0.5) * minf(1.0, (dur - t) / 0.8)
			var base14 := (ground_y + _sh() * 0.02) * k
			for q in range(26):
				var fx3 := W14 * (float(q) + 0.5) / 26.0 + sin(_t * 3.0 + float(q)) * 3.0 * k
				var fh3 := _sh() * k * (0.12 + 0.08 * sin(_t * 7.0 + float(q) * 1.7) + 0.04 * float(q % 3)) * fa
				var fw3 := W14 / 26.0 * 0.9
				for layer3 in range(3):
					var sc3 := 1.0 - float(layer3) * 0.3
					var c3: Color = [Color("c82a10"), col, Color("ffe08a")][layer3]
					ci.draw_colored_polygon(PackedVector2Array([Vector2(fx3 - fw3 * sc3, base14), Vector2(fx3 + fw3 * sc3, base14),
						Vector2(fx3 + sin(_t * 9.0 + float(q)) * fw3 * 0.6, base14 - fh3 * sc3)]), Color(c3, fa * 0.85))
			ci.draw_rect(Rect2(0.0, base14 - _sh() * k * 0.25, W14, _sh() * k * 0.25), Color(col, fa * 0.08))
		"wingshadow":
			var W15 := size.x * k
			var S := W15 * 0.9
			var u15 := t / dur
			var wc := Vector2(lerpf(-0.6, 1.6, u15) * W15, (top_y + _sh() * 0.3) * k + sin(u15 * PI) * _sh() * 0.05 * k)
			var wa := sin(PI * clampf(u15, 0.0, 1.0))
			var flap := 1.0 + 0.35 * sin(_t * 6.0)
			for side7: float in [-1.0, 1.0]:
				var wing := PackedVector2Array()
				for pt in [Vector2(0.0, -0.04), Vector2(0.18, -0.16), Vector2(0.5, -0.1), Vector2(0.4, 0.0), Vector2(0.32, 0.08), Vector2(0.22, 0.02), Vector2(0.12, 0.1), Vector2(0.0, 0.06)]:
					var pv: Vector2 = pt
					wing.append(wc + Vector2(side7 * pv.x, pv.y * flap) * S)
				ci.draw_colored_polygon(wing, Color(col, wa * 0.6))
			ci.draw_circle(wc + Vector2(0, -0.12) * S, S * 0.04, Color(col, wa * 0.6))
			ci.draw_line(wc, wc + Vector2(0.04, 0.32) * S, Color(col, wa * 0.6), maxf(2.0, S * 0.02))
			ci.draw_rect(Rect2(0.0, 0.0, W15, size.y * k), Color(col, wa * 0.12))
		"lavaflow":
			var W16 := size.x * k
			var la := minf(1.0, t / 0.8) * minf(1.0, (dur - t) / 0.8)
			var ly0 := (ground_y - _sh() * 0.02) * k
			var lh := _sh() * 0.06 * k
			var step := maxf(2.0, 3.0 * k)
			var xq := 0.0
			while xq < W16:
				var n6 := 0.5 + 0.5 * sin(xq * 0.05 / k - t * 2.2) * cos(xq * 0.021 / k + t * 1.3)
				var top6 := ly0 - lh * (0.5 + 0.5 * sin(xq * 0.03 / k + t))
				ci.draw_rect(Rect2(xq, top6, step, ly0 + lh - top6), Color(Color("8a1a0a").lerp(col, n6), la))
				if n6 > 0.8:
					ci.draw_rect(Rect2(xq, top6 + 2.0, step, step), Color(Color("ffe08a"), la))
				xq += step
			ci.draw_rect(Rect2(0.0, ly0 - lh * 3.0, W16, lh * 2.0), Color(col, la * 0.12))
		"eggglow":
			var er := float(e["r"]) * k
			var ea := minf(1.0, t / 0.6) * minf(1.0, (dur - t) / 0.8)
			var beat4 := pow(maxf(0.0, sin(_t * 4.0)), 4.0)
			for i in range(6):
				ci.draw_circle(c, er * (2.4 - float(i) * 0.25), Color(col, ea * 0.05 * (0.5 + beat4)))
			ci.draw_set_transform(c, 0.0, Vector2(1.0, 1.3))
			ci.draw_circle(Vector2.ZERO, er, Color(Color("1a1010"), ea))
			ci.draw_arc(Vector2.ZERO, er, PI * 1.1, PI * 1.6, 10, Color(Color("4a3a3a"), ea), 1.0)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for br5 in e["br"]:
				var vl := PackedVector2Array()
				for vp2 in (br5 as PackedVector2Array):
					vl.append((c + vp2 * Vector2(er, er * 1.3)).floor())
				ci.draw_polyline(vl, Color(col.lerp(Color("ffe08a"), beat4), ea * (0.5 + 0.5 * beat4)), 1.0)
		"emit_phoenix":
			var pc := c + _phoenix_off(t) * k
			var pa2 := minf(1.0, t / 0.3) * minf(1.0, (dur - t) / 0.6)
			var ps := _sh() * 0.07 * k
			var fl := sin(_t * 12.0)
			for side8: float in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([pc, pc + Vector2(side8 * ps * 1.4, -ps * (0.3 + 0.7 * fl)), pc + Vector2(side8 * ps * 0.9, ps * 0.2)]), Color(col, pa2))
				ci.draw_line(pc + Vector2(side8 * ps * 0.3, -ps * 0.1), pc + Vector2(side8 * ps * 1.2, -ps * (0.25 + 0.65 * fl)), Color(Color("fff0a0"), pa2), 1.0)
			ci.draw_circle(pc, ps * 0.3, Color(Color("ffe08a"), pa2))
			ci.draw_circle(pc + Vector2(0, -ps * 0.35), ps * 0.16, Color(Color("fff6d0"), pa2))
			for q in range(3):
				ci.draw_line(pc + Vector2(0, ps * 0.2), pc + Vector2((float(q) - 1.0) * ps * 0.4, ps * (1.0 + 0.2 * sin(_t * 5.0 + float(q)))), Color(Color("ff6a1a"), pa2), 2.0)
			for i in range(5):
				ci.draw_circle(pc, ps * (1.6 - float(i) * 0.25), Color(col, pa2 * 0.06))
		"wyrmmark":
			var mr4 := float(e["r"]) * k
			var ma3 := minf(1.0, t / 0.5) * minf(1.0, (dur - t) / 0.8)
			var pul := 0.6 + 0.4 * sin(_t * 5.0)
			var mc2 := c + Vector2(0, sin(_t * 1.6) * mr4 * 0.15)
			for i in range(5):
				ci.draw_circle(mc2, mr4 * (1.8 - float(i) * 0.25), Color(col, ma3 * 0.05 * pul))
			ci.draw_arc(mc2, mr4, 0.0, TAU, 32, Color(col, ma3 * pul), 2.0)
			ci.draw_arc(mc2 + Vector2(mr4 * 0.15, 0), mr4 * 0.55, PI * 0.6, PI * 1.6, 14, Color(Color("ffb050"), ma3), 2.0)
			for q in range(3):
				var o4 := (float(q) - 1.0) * mr4 * 0.3
				ci.draw_line(mc2 + Vector2(o4 - mr4 * 0.15, -mr4 * 0.55), mc2 + Vector2(o4 + mr4 * 0.2, mr4 * 0.55), Color(col.lightened(0.3), ma3 * pul), 2.0)
		"sandstorm":
			var W12 := size.x * k
			var H12 := size.y * k
			var sa2 := minf(1.0, t / 0.8) * minf(1.0, (dur - t) / 1.0)
			ci.draw_rect(Rect2(0.0, 0.0, W12, H12), Color(col, sa2 * 0.12))
			for i in range(60):
				var sx5 := fmod(float(i) * 47.3 + t * (180.0 + float(i % 5) * 40.0), W12 + 60.0) - 30.0
				var sy5 := fmod(float(i) * 29.7, H12) + sin(_t * 3.0 + float(i)) * 3.0
				ci.draw_line(Vector2(sx5, sy5).floor(), Vector2(sx5 - 14.0, sy5 + 1.0).floor(), Color(col, sa2 * 0.45), 1.0)
		"heatwave":
			var W13 := size.x * k
			var ha := minf(1.0, t / 0.8) * minf(1.0, (dur - t) / 0.8)
			for j in range(6):
				var hy := (ground_y - _sh() * (0.05 + 0.08 * float(j))) * k
				var pts13 := PackedVector2Array()
				for q in range(24):
					var hx := W13 * float(q) / 23.0
					pts13.append(Vector2(hx, hy + sin(_t * 5.0 + float(q) * 0.8 + float(j)) * 2.0).floor())
				ci.draw_polyline(pts13, Color(col, ha * 0.18), 1.0)
		"mirage":
			var mr3 := float(e["r"]) * k
			var ma2 := sin(PI * clampf(t / dur, 0.0, 1.0))
			for side5: float in [-1.0, 1.0]:
				var fc := c + Vector2(side5 * mr3 * 0.5, 0.0)
				for q in range(14):
					var wob2 := sin(_t * 6.0 + float(q) * 0.7) * 3.0
					var yy3 := fc.y - mr3 + float(q) * mr3 * 0.14
					var half3 := mr3 * (0.12 if q < 4 else 0.2)
					ci.draw_line(Vector2(fc.x - half3 + wob2, yy3).floor(), Vector2(fc.x + half3 + wob2, yy3).floor(), Color(col, ma2 * 0.35), 1.0)
		"sundisk":
			var sr4 := float(e["r"]) * k
			var sa3 := minf(1.0, t / 0.4) * minf(1.0, (dur - t) / 0.8)
			for q in range(16):
				var ang5 := float(q) / 16.0 * TAU + _t * 0.4
				ci.draw_line(c + Vector2.from_angle(ang5) * sr4 * 1.1, c + Vector2.from_angle(ang5) * sr4 * (1.6 + 0.2 * sin(_t * 3.0 + float(q))), Color(col, sa3 * 0.6), 2.0)
			for i in range(6):
				ci.draw_circle(c, sr4 * (1.0 - float(i) * 0.12), Color(col.lerp(Color.WHITE, float(i) / 6.0), sa3 * 0.3))
		"hourglass":
			var hr3 := float(e["r"]) * k
			var hga := minf(1.0, t / 0.5) * minf(1.0, (dur - t) / 0.8)
			var top3 := c + Vector2(0, -hr3)
			var bot3 := c + Vector2(0, hr3)
			var frame_c := Color(Color("c8a060"), hga)
			ci.draw_line(top3 + Vector2(-hr3 * 0.7, 0), top3 + Vector2(hr3 * 0.7, 0), frame_c, 2.0)
			ci.draw_line(bot3 + Vector2(-hr3 * 0.7, 0), bot3 + Vector2(hr3 * 0.7, 0), frame_c, 2.0)
			for side6: float in [-1.0, 1.0]:
				ci.draw_line(top3 + Vector2(side6 * hr3 * 0.6, 0), c + Vector2(side6 * 1.5, 0), Color(Color("e8f8ff"), hga * 0.7), 1.0)
				ci.draw_line(c + Vector2(side6 * 1.5, 0), bot3 + Vector2(side6 * hr3 * 0.6, 0), Color(Color("e8f8ff"), hga * 0.7), 1.0)
			var flow := clampf(t / 2.0, 0.0, 1.0)
			var stopped := t > 2.0
			ci.draw_colored_polygon(PackedVector2Array([top3 + Vector2(-hr3 * 0.5 * (1.0 - flow), hr3 * 0.1), top3 + Vector2(hr3 * 0.5 * (1.0 - flow), hr3 * 0.1), c]), Color(col, hga))
			ci.draw_colored_polygon(PackedVector2Array([bot3 + Vector2(-hr3 * 0.5, -1.0), bot3 + Vector2(hr3 * 0.5, -1.0), bot3 + Vector2(0, -hr3 * 0.6 * flow - 1.0)]), Color(col, hga))
			if not stopped:
				ci.draw_line(c, c + Vector2(0, hr3 * 0.9), Color(col, hga), 1.0)
		"riddle":
			var rr8 := float(e["r"]) * k
			var ra3 := minf(1.0, t / 0.6) * minf(1.0, (dur - t) / 0.8)
			for q in range(6):
				var ang6 := float(q) / 6.0 * TAU + t * 0.7
				var gp2 := c + Vector2(cos(ang6) * rr8, sin(ang6) * rr8 * 0.4)
				ci.draw_circle(gp2, 5.0, Color(col, ra3 * 0.18))
				ci.draw_arc(gp2 + Vector2(0, -2), 2.0, -PI, PI * 0.5, 8, Color(col.lightened(0.3), ra3), 1.0)
				ci.draw_rect(Rect2(gp2.floor() + Vector2(0, 2), Vector2(1, 1)), Color(col.lightened(0.3), ra3))
		"blizzard":
			var W9 := size.x * k
			var H9 := size.y * k
			var ba2 := minf(1.0, t / 0.8)
			for i in range(70):
				var bx6 := fmod(float(i) * 53.1 + t * (260.0 + float(i % 4) * 60.0), W9 + 40.0) - 20.0
				var by6 := fmod(float(i) * 37.9 + t * 30.0, H9)
				ci.draw_line(Vector2(bx6, by6).floor(), Vector2(bx6 - 8.0 - float(i % 3) * 3.0, by6 + 2.0).floor(), Color(col, ba2 * (0.25 + 0.15 * float(i % 3))), 1.0)
		"avalanche":
			var W10 := size.x * k
			var front_y := (top_y + (ground_y - top_y) * _ease_in(clampf(t / 1.6, 0.0, 1.0))) * k
			var av := minf(1.0, (dur - t) / 0.6)
			ci.draw_rect(Rect2(0.0, top_y * k, W10, front_y - top_y * k), Color(col, av * 0.35))
			for q in range(14):
				var qx := W10 * float(q) / 13.0
				ci.draw_circle(Vector2(qx, front_y + sin(_t * 8.0 + float(q)) * 3.0), 6.0 + float(q % 3) * 2.0, Color(col, av * 0.7))
		"icecrack":
			var ia := minf(1.0, (dur - t) / 0.8)
			var ig := clampf(t / 0.7, 0.0, 1.0)
			for br4 in e["br"]:
				var pts12 := br4 as PackedVector2Array
				var n4 := maxi(2, int(float(pts12.size()) * ig))
				var line4 := PackedVector2Array()
				for q in range(n4):
					line4.append((c + pts12[q]).floor())
				ci.draw_polyline(line4, Color(col, ia), 1.0)
		"runes":
			var rr7 := float(e["r"]) * k
			var ra2 := minf(1.0, (dur - t) / 0.6)
			for q in range(8):
				var on4 := clampf((t - 0.2 * float(q)) / 0.25, 0.0, 1.0)
				if on4 <= 0.0:
					continue
				var ang4 := PI + float(q) / 7.0 * PI
				var rp3 := c + Vector2(cos(ang4) * rr7, sin(ang4) * rr7 * 0.6)
				ci.draw_circle(rp3, 5.0, Color(col, ra2 * on4 * 0.2))
				ci.draw_line(rp3 + Vector2(0, -3), rp3 + Vector2(0, 3), Color(col.lightened(0.3), ra2 * on4), 1.0)
				ci.draw_line(rp3 + Vector2(-2, -1), rp3 + Vector2(2, 1), Color(col.lightened(0.3), ra2 * on4), 1.0)
		"aurora":
			var W11 := size.x * k
			var aa2 := minf(1.0, t / 1.5)
			for band in range(3):
				var bc := col if band != 1 else Color("b07cff")
				var y0 := (top_y + _sh() * (0.04 + 0.08 * float(band))) * k
				for x5 in range(0, int(W11), 2):
					var yy2 := y0 + sin(float(x5) * 0.04 + _t * 0.6 + float(band) * 1.7) * 8.0
					ci.draw_line(Vector2(float(x5), yy2), Vector2(float(x5), yy2 + 18.0), Color(bc, aa2 * 0.12), 2.0)
		"doors":
			var dg := _ease_in_out(clampf(t / 2.2, 0.0, 1.0))
			var da := minf(1.0, (dur - t) / 0.8)
			var dh := _sh() * k * 0.5
			var dw := size.x * k * 0.14
			var dc := Vector2(size.x * k * 0.5, (ground_y - _sh() * 0.05) * k)
			var gap := dw * 0.9 * dg
			ci.draw_rect(Rect2(dc.x - gap, dc.y - dh, gap * 2.0, dh), Color(col, da * 0.35 * dg))
			for side4: float in [-1.0, 1.0]:
				var x6 := dc.x + side4 * gap - (dw if side4 < 0.0 else 0.0)
				ci.draw_rect(Rect2(x6, dc.y - dh, dw, dh), Color(Color("2e3652"), da))
				ci.draw_rect(Rect2(x6, dc.y - dh, dw, 2.0), Color(Color("8a8a98"), da))
		"fogbank":
			var W8 := size.x * k
			var fa2 := minf(1.0, t / 1.2) * minf(1.0, (dur - t) / 1.5)
			for j in range(5):
				var fy2 := (ground_y - _sh() * (0.1 + 0.15 * float(j))) * k
				var off := fmod(t * (14.0 + 6.0 * float(j)) + float(j) * 70.0, W8 + 120.0) - 60.0
				for q in range(4):
					var fx3 := fmod(off + float(q) * (W8 + 120.0) / 4.0, W8 + 120.0) - 60.0
					ci.draw_circle(Vector2(fx3, fy2), _sh() * k * (0.12 + 0.03 * float(q % 2)), Color(col, fa2 * 0.12))
		"lanterns":
			var la := minf(1.0, t / 0.8)
			var lp2: PackedVector2Array = e["pts"]
			for i in range(lp2.size()):
				var lx2 := lp2[i].x * size.x * k
				var ly2 := (ground_y - _sh() * (0.05 + 0.18 * lp2[i].y)) * k + sin(_t * 1.6 + float(i)) * 2.0
				ci.draw_circle(Vector2(lx2, ly2), 6.0, Color(col, la * 0.12))
				ci.draw_rect(Rect2(Vector2(lx2, ly2).floor() - Vector2(1, 1), Vector2(2, 3)), Color(col.lightened(0.4), la))
				ci.draw_line(Vector2(lx2, ly2 + 3.0).floor(), Vector2(lx2, ly2 + 8.0).floor(), Color(col, la * 0.2), 1.0)
		"bonerise":
			var bp2: PackedVector2Array = e["pts"]
			var gy4 := (ground_y + 4.0) * k
			var ba := minf(1.0, (dur - t) / 0.6)
			for i in range(bp2.size()):
				var g4 := _ease_out(clampf((t - 0.2 * float(i)) / 0.8, 0.0, 1.0))
				if g4 <= 0.0:
					continue
				var bx5 := bp2[i].x * size.x * k
				var bh2 := _sh() * k * 0.12 * bp2[i].y * g4
				ci.draw_line(Vector2(bx5, gy4).floor(), Vector2(bx5, gy4 - bh2).floor(), Color(col, ba), 2.0)
				for f9 in range(3):
					var fa3 := -PI * 0.5 + (float(f9) - 1.0) * 0.5
					ci.draw_line(Vector2(bx5, gy4 - bh2).floor(), (Vector2(bx5, gy4 - bh2) + Vector2.from_angle(fa3) * 4.0 * g4).floor(), Color(col, ba), 1.0)
		"chains":
			var cr2 := float(e["r"]) * k
			var cg2 := clampf(t / 0.7, 0.0, 1.0)
			for j in range(3):
				var yy := c.y + (float(j) - 1.0) * cr2 * 0.6
				var links := int(14.0 * cg2)
				for q in range(links):
					var ang3 := float(q) / 14.0 * TAU + t * 0.6 * (1.0 if j % 2 == 0 else -1.0)
					var lp3 := Vector2(c.x + cos(ang3) * cr2, yy + sin(ang3) * cr2 * 0.2)
					var front := sin(ang3) > 0.0
					ci.draw_rect(Rect2(lp3.floor() - Vector2(1, 1), Vector2(3, 2)), Color(col, 0.9 if front else 0.35))
		"jaws":
			var jr := float(e["r"]) * k
			var jc := _ease_in(clampf(t / 0.25, 0.0, 1.0))
			var ja := minf(1.0, (dur - t) / 0.4)
			for side3: float in [-1.0, 1.0]:
				var jy := c.y + side3 * jr * (1.0 - jc) * 0.8
				ci.draw_arc(Vector2(c.x, jy), jr, PI if side3 < 0.0 else 0.0, TAU if side3 < 0.0 else PI, 24, Color(col, ja), 3.0)
				for q in range(7):
					var tx5 := c.x - jr * 0.8 + float(q) * jr * 1.6 / 6.0
					ci.draw_line(Vector2(tx5, jy).floor(), Vector2(tx5, jy - side3 * 6.0).floor(), Color(col, ja), 2.0)
		"ashring":
			var ar4 := float(e["r"]) * k
			var aa := minf(1.0, t / 0.6) * minf(1.0, (dur - t) / 0.8)
			ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.25))
			ci.draw_arc(Vector2.ZERO, ar4, 0.0, TAU, 56, Color(Color("6a6a6a"), aa), 3.0)
			for q in range(10):
				var on3 := clampf((t - 0.25 * float(q)) / 0.3, 0.0, 1.0)
				if on3 > 0.0:
					var rp2 := Vector2.from_angle(float(q) / 10.0 * TAU) * ar4
					ci.draw_circle(rp2, 5.0, Color(col, aa * on3 * 0.25))
					ci.draw_rect(Rect2(rp2 - Vector2(1, 1), Vector2(3, 3)), Color(col.lightened(0.3), aa * on3))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"heads":
			var hr2 := float(e["r"]) * k
			var hg := _ease_out(clampf(t / 1.6, 0.0, 1.0))
			var gy5 := (ground_y + 6.0) * k
			for j in range(5):
				var base_x := c.x + (float(j) - 2.0) * hr2 * 0.28
				var pts9 := PackedVector2Array()
				var hp2 := Vector2(base_x, gy5)
				for q in range(14):
					var f10 := float(q) / 13.0
					hp2 = Vector2(base_x + (float(j) - 2.0) * hr2 * 0.25 * f10 + sin(_t * 1.3 + f10 * 3.0 + float(j)) * 6.0 * f10, gy5 - hr2 * 0.9 * f10 * hg)
					pts9.append(hp2.floor())
				ci.draw_polyline(pts9, Color(col, 1.0), 6.0)
				ci.draw_circle(hp2, 6.0, Color(col, 1.0))
				ci.draw_rect(Rect2(hp2.floor() + Vector2(1, -2), Vector2(2, 1)), Color("f0d23c"))
		"moths":
			var ma := minf(1.0, t / 0.5) * minf(1.0, (dur - t) / 0.8)
			var mr2 := float(e["r"]) * k
			var mp2: PackedVector2Array = e["pts"]
			for i in range(mp2.size()):
				var mo2 := mp2[i]
				var mpos := c + Vector2(cos(mo2.x + t * mo2.y * 1.5) * mr2 * 1.3, sin(mo2.x * 1.7 + t * mo2.y * 2.1) * mr2 * 0.7)
				var flap := absf(sin(_t * 18.0 + float(i)))
				ci.draw_rect(Rect2(mpos.floor() - Vector2(1.0 + flap * 2.0, 0), Vector2(1.0 + flap * 2.0, 2)), Color(col, ma))
				ci.draw_rect(Rect2(mpos.floor() + Vector2(1, 0), Vector2(1.0 + flap * 2.0, 2)), Color(col, ma))
				ci.draw_rect(Rect2(mpos.floor(), Vector2(1, 2)), Color(Color("2a2038"), ma))
		"whispers":
			var wa := minf(1.0, t / 0.8) * minf(1.0, (dur - t) / 1.0)
			var wp3: PackedVector2Array = e["pts"]
			for i in range(wp3.size()):
				var wx2 := (wp3[i].x * size.x + t * 10.0) * k
				var wy2 := (top_y + wp3[i].y * _sh()) * k
				var pts10 := PackedVector2Array()
				for q in range(10):
					pts10.append(Vector2(wx2 + float(q) * 3.0, wy2 + sin(_t * 4.0 + float(q) * 0.9 + float(i)) * 2.0).floor())
				ci.draw_polyline(pts10, Color(col, wa * (0.3 + 0.3 * sin(_t * 2.0 + float(i)))), 1.0)
		"arcs":
			var a20 := minf(1.0, t / 0.15) * minf(1.0, (dur - t) / 0.5)
			var ar2 := float(e["r"]) * k
			# Les arcs changent de forme plusieurs fois par seconde.
			var seed2 := int(t * 14.0)
			for j in range(3):
				var rs := RandomNumberGenerator.new()
				rs.seed = seed2 * 31 + j * 7
				var a0 := c + Vector2(-ar2 + rs.randf() * ar2 * 0.3, rs.randf_range(-0.4, 0.4) * ar2)
				var b0 := c + Vector2(ar2 - rs.randf() * ar2 * 0.3, rs.randf_range(-0.4, 0.4) * ar2)
				var pts6 := PackedVector2Array([a0])
				for q in range(1, 8):
					pts6.append(a0.lerp(b0, float(q) / 8.0) + Vector2(0.0, rs.randf_range(-1.0, 1.0) * ar2 * 0.18))
				pts6.append(b0)
				ci.draw_polyline(pts6, Color(col, a20 * 0.35), 3.0)
				ci.draw_polyline(pts6, Color(Color("fff6d0"), a20), 1.0)
		"shieldwall":
			var gy3 := c.y + 4.0
			var W4 := size.x * k
			var up := _ease_out_back(clampf(t / 0.35, 0.0, 1.0))
			var a21 := minf(1.0, (dur - t) / 0.6)
			for i in range(7):
				var sx3 := W4 * (0.08 + 0.14 * float(i))
				var hgt := _sh() * k * 0.16 * up
				var wd := W4 * 0.06
				var rect := Rect2(Vector2(sx3 - wd * 0.5, gy3 - hgt), Vector2(wd, hgt))
				ci.draw_rect(rect, Color(Color("1a1008"), a21))
				ci.draw_rect(rect.grow(-1.0), Color(col, a21))
				ci.draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(rect.size.x - 2.0, 2.0)), Color(col.lightened(0.3), a21))
				ci.draw_circle(rect.get_center(), wd * 0.18, Color(Color("c8c8d0"), a21))
		"howl":
			for j in range(3):
				var ht := t - float(j) * 0.3
				if ht <= 0.0:
					continue
				var hu := clampf(ht / 1.4, 0.0, 1.0)
				var hr := _sh() * k * (0.08 + 0.45 * hu)
				ci.draw_arc(c, hr, -PI * 0.85, -PI * 0.15, 24, Color(col, (1.0 - hu) * 0.8), 1.0)
				ci.draw_arc(c, hr * 0.92, -PI * 0.8, -PI * 0.2, 20, Color(col, (1.0 - hu) * 0.35), 1.0)
		"rain":
			var W5 := size.x * k
			var H5 := size.y * k
			for i in range(110):
				var fx2 := fmod(float(i) * 37.13 + t * 40.0, W5 + 20.0) - 10.0
				var fy := fmod(float(i) * 91.7 + t * (380.0 + float(i % 5) * 30.0), H5 + 20.0) - 10.0
				ci.draw_line(Vector2(fx2, fy).floor(), Vector2(fx2 - 2.0, fy + 7.0).floor(), Color(col, 0.35 + 0.1 * float(i % 3)), 1.0)
		"banners":
			var W6 := size.x * k
			var a22 := minf(1.0, t / 0.8)
			# Sur les bords du cadre : le personnage du milieu reste dégagé.
			for j in range(2):
				var bx3 := W6 * (0.05 + 0.8 * float(j))
				var by3 := top_y * k + _sh() * k * 0.08
				var bh := _sh() * k * 0.16
				ci.draw_line(Vector2(bx3, by3 - 4.0).floor(), Vector2(bx3, by3 + bh * 1.6).floor(), Color(Color("2a1a10"), a22), 2.0)
				var cloth := PackedVector2Array()
				var segs := 8
				for q in range(segs + 1):
					var f5 := float(q) / float(segs)
					cloth.append(Vector2(bx3 + f5 * bh * 0.9, by3 + sin(_t * 6.0 - f5 * 4.0 + float(j)) * 3.0 * f5))
				for q in range(segs, -1, -1):
					var f6 := float(q) / float(segs)
					cloth.append(Vector2(bx3 + f6 * bh * 0.9, by3 + bh + sin(_t * 6.0 - f6 * 4.0 + float(j)) * 3.0 * f6))
				ci.draw_colored_polygon(cloth, Color(col, a22))
				ci.draw_circle(Vector2(bx3 + bh * 0.4, by3 + bh * 0.5), bh * 0.14, Color(Color("e8e0c8"), a22))
		"pact":
			var pu := clampf(t / 1.4, 0.0, 1.0)
			var a23 := minf(1.0, (dur - t) / 0.6)
			var W7 := size.x * k
			for side: float in [-1.0, 1.0]:
				var rc := Color("4a7ae8") if side < 0.0 else Color("d83a2a")
				var pts7 := PackedVector2Array()
				for q in range(20):
					var f7 := float(q) / 19.0 * pu
					var x7 := lerpf(c.x + side * W7 * 0.5, c.x, f7)
					pts7.append(Vector2(x7, c.y + sin(f7 * 9.0 + t * 4.0 + side) * 6.0 * (1.0 - f7)).floor())
				ci.draw_polyline(pts7, Color(rc, a23), 3.0)
				ci.draw_polyline(pts7, Color(rc.lightened(0.4), a23), 1.0)
			if t > 1.4:
				var gu := clampf((t - 1.4) / 0.8, 0.0, 1.0)
				ci.draw_circle(c, _sh() * k * 0.25 * _ease_out(gu), Color(col, (1.0 - gu) * 0.35))
				ci.draw_arc(c, _sh() * k * 0.32 * _ease_out(gu), 0.0, TAU, 40, Color(col, (1.0 - gu)), 1.0)
				ci.draw_circle(c, 3.0, Color(Color.WHITE, a23))
		"shadow":
			var sr2 := float(e["r"]) * k
			var a24 := minf(1.0, t / 0.6) * minf(1.0, (dur - t) / 0.8)
			for j in range(7):
				var ang2 := float(j) / 7.0 * TAU + t * 0.6
				var pts8 := PackedVector2Array()
				for q in range(12):
					var f8 := float(q) / 11.0
					var rr6 := sr2 * (0.3 + 0.9 * f8)
					var wob := sin(t * 3.0 + f8 * 6.0 + float(j)) * 0.35
					pts8.append((c + Vector2.from_angle(ang2 + wob * f8) * rr6).floor())
				ci.draw_polyline(pts8, Color(col, a24 * 0.6), 2.0)
				ci.draw_polyline(pts8, Color(col.lightened(0.4), a24 * 0.8), 1.0)
		"sigils":
			var sr3 := float(e["r"]) * k
			var a25 := minf(1.0, t / 0.6)
			for side2: float in [-1.0, 1.0]:
				var sc2 := c + Vector2(side2 * _sh() * k * 0.32, -_sh() * k * 0.05 + sin(t * 1.5 + side2) * 3.0)
				var pulse := 1.0 + 0.08 * sin(t * 4.0 + side2)
				ci.draw_circle(sc2, sr3 * 1.6 * pulse, Color(col, a25 * 0.12))
				ci.draw_arc(sc2, sr3 * pulse, 0.0, TAU, 32, Color(col, a25), 1.0)
				ci.draw_arc(sc2, sr3 * 0.65 * pulse, t, t + PI * 1.4, 20, Color(col.lightened(0.4), a25), 1.0)
				for q in range(6):
					var rp := sc2 + Vector2.from_angle(float(q) / 6.0 * TAU - t * 0.8) * sr3 * 0.82 * pulse
					ci.draw_rect(Rect2(rp.floor(), Vector2(2, 2)), Color(Color.WHITE, a25 * 0.8))
		"bars":
			var br3 := float(e["r"]) * k
			var bg := clampf(t / 0.6, 0.0, 1.0)
			var bottom2 := c.y + br3 * 1.1
			var topb := bottom2 - br3 * 2.4 * bg
			for i in range(6):
				var bx4 := c.x - br3 + float(i) * br3 * 2.0 / 5.0
				ci.draw_line(Vector2(bx4, bottom2).floor(), Vector2(bx4, topb).floor(), Color(Color("1a1008"), 1.0), 4.0)
				ci.draw_line(Vector2(bx4, bottom2).floor(), Vector2(bx4, topb).floor(), Color(col, 1.0), 2.0)
			for ty2: float in [topb, lerpf(topb, bottom2, 0.5), bottom2]:
				ci.draw_line(Vector2(c.x - br3 - 3.0, ty2).floor(), Vector2(c.x + br3 + 3.0, ty2).floor(), Color(col.darkened(0.3), 1.0), 3.0)
		"cage":
			var cr := float(e["r"]) * k
			var cg := clampf(t / 0.8, 0.0, 1.0)
			var base2 := c.y + cr
			for i in range(7):
				var bx2 := c.x - cr + float(i) * cr * 2.0 / 6.0
				var top2 := base2 - cr * 2.0 * cg * (0.9 + 0.1 * sin(float(i) * 1.7))
				ci.draw_line(Vector2(bx2, base2).floor(), Vector2(bx2 + sin(float(i)) * 2.0, top2).floor(), Color(Color("1a0e20"), 1.0), 3.0)
				ci.draw_line(Vector2(bx2, base2).floor(), Vector2(bx2 + sin(float(i)) * 2.0, top2).floor(), Color(col, 1.0), 1.0)
				for j in range(3):
					var ty := lerpf(base2, top2, 0.25 + 0.25 * float(j))
					ci.draw_line(Vector2(bx2, ty).floor(), Vector2(bx2 + (2.0 if j % 2 == 0 else -2.0), ty - 2.0).floor(), Color(col.lightened(0.2), 1.0), 1.0)
		"roots":
			var rr4: PackedVector2Array = e["pts"]
			var gy2 := (_anchor_pos("ground") * k).y + 6.0
			var W3 := size.x * k
			var a18 := minf(1.0, (dur - t) / 0.8)
			var g3 := _ease_out(clampf(t / 1.6, 0.0, 1.0))
			for i in range(rr4.size()):
				var r5 := rr4[i]
				var sx2 := 0.0 if r5.x < 0.0 else W3
				var pts5 := PackedVector2Array()
				for j in range(16):
					var f4 := float(j) / 15.0 * g3
					var x3 := lerpf(sx2, W3 * 0.5, f4 * (0.55 + 0.3 * r5.y))
					var y3 := gy2 - f4 * _sh() * k * (0.15 + 0.25 * r5.y) - sin(f4 * 6.0 + t * 2.0 + float(i)) * 6.0 * f4
					pts5.append(Vector2(x3, y3).floor())
				ci.draw_polyline(pts5, Color(Color("1a0e0a"), a18), 5.0)
				ci.draw_polyline(pts5, Color(col, a18), 3.0)
				ci.draw_polyline(pts5, Color(col.lightened(0.25), a18), 1.0)
		"lanes":
			var xs: PackedVector2Array = e["pts"]
			var gy := (_anchor_pos("ground") * k).y
			var a12 := minf(1.0, t / 0.2) * minf(1.0, (dur - t) / 0.5) * (0.55 + 0.45 * sin(t * 14.0))
			var lw := size.x * k * 0.07
			for q3 in xs:
				var lx2 := q3.x * size.x * k
				ci.draw_rect(Rect2(lx2 - lw * 0.5, gy - _sh() * k * 0.75, lw, _sh() * k * 0.75), Color(col, a12 * 0.22))
				ci.draw_rect(Rect2(lx2 - lw * 0.5, gy - _sh() * k * 0.75, 1.0, _sh() * k * 0.75), Color(col, a12 * 0.7))
				ci.draw_rect(Rect2(lx2 + lw * 0.5 - 1.0, gy - _sh() * k * 0.75, 1.0, _sh() * k * 0.75), Color(col, a12 * 0.7))
		"swarm":
			var seeds2: PackedVector2Array = e["pts"]
			var rs := float(e["r"]) * k
			var a9 := minf(1.0, t / 0.5) * minf(1.0, (dur - t) / 0.8)
			for i in range(seeds2.size()):
				var sd := seeds2[i]
				var ang4 := sd.x + t * (1.2 + sd.y)
				var rr3 := rs * sd.y * (0.8 + 0.2 * sin(t * 2.0 + sd.x * 3.0))
				var fp := c + Vector2(cos(ang4) * rr3, sin(ang4 * 1.3) * rr3 * 0.55)
				var fl := 0.55 + 0.45 * sin(_t * 9.0 + sd.x * 7.0)
				ci.draw_circle(fp, 2.0, Color(col, a9 * 0.18 * fl))
				ci.draw_rect(Rect2(fp.floor(), Vector2.ONE), Color(col.lightened(0.3), a9 * fl))
		"gate":
			var gw := float(e["r"]) * k * 0.8
			var gh := float(e["r"]) * k * 1.3
			var a7 := minf(1.0, (dur - t) / 0.6)
			var p2 := clampf(t / 0.9, 0.0, 1.0)
			var base_y := c.y + gh * 0.5
			var lx := c.x - gw * 0.5
			var rx := c.x + gw * 0.5
			var top := base_y - gh + gw * 0.5
			var pil := clampf(p2 * 2.0, 0.0, 1.0)
			var gc := Color(col, a7)
			ci.draw_line(Vector2(lx, base_y).floor(), Vector2(lx, lerpf(base_y, top, pil)).floor(), gc, 1.0)
			ci.draw_line(Vector2(rx, base_y).floor(), Vector2(rx, lerpf(base_y, top, pil)).floor(), gc, 1.0)
			if p2 > 0.5:
				var q2 := (p2 - 0.5) * 2.0
				ci.draw_arc(Vector2(c.x, top), gw * 0.5, PI, PI + q2 * PI * 0.5, 16, gc, 1.0)
				ci.draw_arc(Vector2(c.x, top), gw * 0.5, TAU, TAU - q2 * PI * 0.5, 16, gc, 1.0)
			# Les runes du linteau et des piliers s'allument une à une.
			for j in range(7):
				var lit := clampf((t - 0.9 - float(j) * 0.12) / 0.2, 0.0, 1.0)
				if lit <= 0.0:
					continue
				var rp := Vector2(lx + 2.0, base_y - 3.0 - float(j) * (gh - gw * 0.5) / 7.0) if j < 4 else Vector2(rx - 3.0, base_y - 3.0 - float(j - 4) * (gh - gw * 0.5) / 3.5)
				ci.draw_rect(Rect2(rp.floor(), Vector2(1, 2)), Color(col.lightened(0.5), a7 * lit))
			if t > 1.6:
				var g2 := clampf((t - 1.6) / 0.4, 0.0, 1.0)
				ci.draw_rect(Rect2(Vector2(lx + 1.0, top), Vector2(gw - 1.0, base_y - top)), Color(col, a7 * 0.12 * g2))
		"bolt":
			if t - float(e["gen"]) > 0.05:
				e["gen"] = t
				e["pts"] = _bolt_path(_fx_pos(e))
			if t < 0.38 and int(t * 30.0) % 3 != 2:
				var pts2: PackedVector2Array = e["pts"]
				var scaled := PackedVector2Array()
				for q2 in pts2:
					scaled.append((q2 * k).floor())
				ci.draw_polyline(scaled, Color(col, 0.5), 3.0)
				ci.draw_polyline(scaled, Color.WHITE, 1.0)
		"beam":
			var ww := float(e["r"]) * k * 0.4 * sin(PI * u)
			ci.draw_rect(Rect2(c.x - ww * 0.5, 0.0, ww, c.y), Color(col, 0.45))
			ci.draw_rect(Rect2(c.x - ww * 0.15, 0.0, ww * 0.3, c.y), Color(Color.WHITE, 0.8 * sin(PI * u)))
		"crack":
			var pts3: PackedVector2Array = e["pts"]
			var reveal := clampf(t / 0.7, 0.0, 1.0)
			var n := int(reveal * float(pts3.size() - 1)) + 1
			var a5 := minf(1.0, (dur - t) / 0.8)
			var sub := PackedVector2Array()
			for i in range(mini(n + 1, pts3.size())):
				sub.append((pts3[i] * k).floor())
			if sub.size() >= 2:
				var pulse := 0.3 + 0.12 * sin(_t * 7.0)
				ci.draw_polyline(sub, Color(col, pulse * a5), 7.0)
				ci.draw_polyline(sub, Color(col, 0.8 * a5), 3.0)
				ci.draw_polyline(sub, Color(Color.WHITE, a5), 1.0)
		"slash":
			var span := PI * 0.9
			var prog := clampf(t / 0.12, 0.0, 1.0)
			var a6 := 1.0 - clampf((t - 0.12) / 0.33, 0.0, 1.0)
			var r2 := _sh() * 0.12 * k
			var a0 := float(e["rot"]) - span * 0.5
			for i in range(3):
				ci.draw_arc(c, r2 - float(i), a0, a0 + span * prog, 24, Color(col if i > 0 else Color.WHITE, a6 * (1.0 - float(i) * 0.25)), 2.0 - float(i) * 0.5)


static func pf_glow(p: Vector2) -> Vector2:
	return p.floor() + Vector2(0.5, 0.5)


func _bolt_path(target: Vector2) -> PackedVector2Array:
	var start := Vector2(target.x + randf_range(-0.12, 0.12) * size.x, top_y - 10.0)
	var pts := PackedVector2Array()
	var n := 10
	var perp := (target - start).orthogonal().normalized()
	for i in range(n + 1):
		var f := float(i) / float(n)
		var j := 0.0 if i == 0 or i == n else randf_range(-1.0, 1.0) * _sh() * 0.06 * (1.0 - absf(f - 0.5))
		pts.append(start.lerp(target, f) + perp * j)
	return pts


func _draw_emote(ci: CanvasItem, em: Dictionary, k: float) -> void:
	var who := str(em["who"])
	var kind := str(em["kind"])
	var t := float(em["t"])
	# Place sur la tête : veine de colère au coin du crâne, goutte sur la tempe (elle glisse), « ! » et « ? »
	# au-dessus, note à côté du visage. Les portraits ont la tête centrée, le crâne vers 80 % de leur hauteur.
	var spot := {"anger": Vector2(0.16, -0.8), "drop": Vector2(-0.21, -0.64), "!": Vector2(0.1, -0.98), "?": Vector2(0.1, -0.98),
		"note": Vector2(0.27, -0.84), "dots": Vector2(0.0, -0.96)}
	var sp: Vector2 = spot.get(kind, Vector2(0.1, -0.95))
	var base := Vector2.ZERO
	var big := 0.0
	if _figs.has(who):
		var f: Dictionary = _figs[who]
		if hold or bool(f["hidden"]) or float(f["xt"]) >= 0.0:
			return
		var toward := -float(f["side"])
		big = float(f.get("S", _fig_scale() * 64.0))
		base = (f.get("bottom", f["head"]) as Vector2) + Vector2(toward * sp.x * big, sp.y * big)
	elif not _pres.is_empty() and str(_pres["pid"]) == who:
		big = _sh() * 0.9
		base = (_pres.get("center", _anchor_pos("subject")) as Vector2) + Vector2(sp.x * big * 0.6, (sp.y + 0.55) * big * 0.6)
	else:
		return
	if kind == "drop":
		base.y += minf(t, 1.2) * big * 0.035
	var pop := minf(1.0, t / 0.12)
	var a := minf(1.0, (float(em["dur"]) - t) / 0.3)
	var hop := -absf(sin(t * 9.0)) * 2.0 * maxf(0.0, 1.0 - t / 0.6)
	var rows: Array = EMOTES[str(em["kind"])]
	var px2 := clampf(roundf(big * k / 44.0), 1.0, 3.0) ## taille d'un pixel de bulle, selon la taille du buste
	var pulse := 1.0 + (0.15 * absf(sin(t * 7.0)) if kind == "anger" else 0.0)
	var dim := Vector2(float(str(rows[0]).length()), float(rows.size())) * px2 * pulse
	var o := (base * k - dim * 0.5).floor() + Vector2(0.0, hop * 2.0 - (1.0 - pop) * 4.0)
	px2 *= pulse
	for y in range(rows.size()):
		var row := str(rows[y])
		for x in range(row.length()):
			var ch := row[x]
			if ch == ".":
				continue
			ci.draw_rect(Rect2(o + Vector2(x, y) * px2, Vector2.ONE * px2), Color(Color(str(EMOTE_COL.get(ch, "ffffff"))), a))


# ---------------------------------------------------------------- courbes

static func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


static func _ease_in(x: float) -> float:
	return pow(clampf(x, 0.0, 1.0), 3.0)


static func _ease_in_out(x: float) -> float:
	var v := clampf(x, 0.0, 1.0)
	return v * v * (3.0 - 2.0 * v)


static func _ease_out_back(x: float) -> float:
	var v := clampf(x, 0.0, 1.0)
	var c1 := 1.4
	return 1.0 + (c1 + 1.0) * pow(v - 1.0, 3.0) + c1 * pow(v - 1.0, 2.0)


# ---------------------------------------------------------------- vérification des données

## Erreurs d'indications d'une réplique ou d'une scène (mots inconnus, personnage sans portrait).
static func check_cues(l: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	for c in _list(l.get("cam", [])):
		if not CAMS.has(c.get_slice(":", 0)):
			errs.append("cam " + c)
	for f in _list(l.get("fx", [])):
		var kind := f.get_slice(":", 0).get_slice("@", 0)
		if not FXS.has(kind):
			errs.append("fx " + f)
	if l.has("grade") and not GRADES.has(str(l["grade"])):
		errs.append("grade " + str(l["grade"]))
	var acts: Dictionary = l.get("act", {})
	for who in acts.keys():
		var w := str(who)
		var what := str(acts[who])
		if not (acts[who] is String):
			errs.append("act %s : %s" % [w, what])
		elif w == "subject":
			if not SUBJECT_ACTS.has(what):
				errs.append("act subject " + what)
		elif not (PortraitArt.has_portrait(w) or w == "traitre") or not ACTS.has(what):
			errs.append("act %s %s" % [w, what])
	var ems: Dictionary = l.get("emote", {})
	for who in ems.keys():
		if not EMOTES.has(str(ems[who])):
			errs.append("emote " + str(ems[who]))
	for c in l.get("cast", []):
		var id := str((c as Dictionary).get("id", "")) if c is Dictionary else str(c)
		if not (PortraitArt.has_portrait(id) or id == "traitre"):
			errs.append("cast " + id)
	return errs



## Course du phénix (en pixels d'écran depuis son repère) : il monte en spirale lâche.
func _phoenix_off(t: float) -> Vector2:
	var sh := _sh()
	return Vector2(sin(t * 2.4) * sh * 0.08, -t * sh * 0.22)
