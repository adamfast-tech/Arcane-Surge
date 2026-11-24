class_name SkillTreeView
extends Control
## Arbre de compétences dessiné comme dans un RPG (docs/design/36-arbres-competences.md) : médaillons reliés
## par des chemins lumineux, du palier 1 (en haut) à la Clé de voûte (en bas). Formes : rond (passif),
## carré (sort), hexagone (évolution), losange (Clé de voûte). États : verrouillé, accessible (pulse),
## investi (halo à la couleur de la branche), maîtrisé (anneau d'or). Toucher un médaillon le sélectionne.

signal picked(id: String)

const ROW_H := 124.0
const TOP := 34.0
const LEFT := 44.0
const RIGHT := 16.0
const NODE := 84.0

var branch: Dictionary = {}
var color := Color("6fdccf")
var selected := ""
var _t := 0.0
var _pos: Dictionary = {} ## id -> centre
var _nodes: Dictionary = {} ## id -> nœud
var _views: Dictionary = {} ## id -> SkillNodeView
var _reqs: Array[int] = []
var _stars: Array[Vector3] = []


func setup(br: Dictionary, sel: String) -> void:
	branch = br
	color = Color(str(br.get("color", "6fdccf")))
	selected = sel
	mouse_filter = Control.MOUSE_FILTER_PASS
	var rows: Array = br.get("tiers", [])
	custom_minimum_size = Vector2(0, TOP + ROW_H * float(rows.size()) + 8.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(br.get("id", "")))
	for i in range(70):
		_stars.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.3, 1.0)))
	for tier in rows:
		_reqs.append(int(tier.get("req", 0)))
		for node in tier["nodes"]:
			var id := str(node["id"])
			_nodes[id] = node
			var v := SkillNodeView.new()
			v.node = node
			v.view = self
			_views[id] = v
			add_child(v)
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var w := maxf(200.0, size.x)
	var i := 0
	for tier in branch.get("tiers", []):
		var y := TOP + ROW_H * float(i) + ROW_H * 0.42
		for node in tier["nodes"]:
			var x := LEFT + (w - LEFT - RIGHT) * (0.1 + 0.8 * float(node.get("x", 1.5)) / 3.0)
			var id := str(node["id"])
			_pos[id] = Vector2(x, y)
			var v: SkillNodeView = _views[id]
			v.size = Vector2(NODE + 20.0, NODE + 22.0)
			v.position = Vector2(x - v.size.x * 0.5, y - NODE * 0.5 - 4.0)
		i += 1
	queue_redraw()


func select(id: String) -> void:
	selected = id
	for v in _views.values():
		(v as Control).queue_redraw()
	picked.emit(id)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# Fond : ciel nocturne à la couleur de la branche, étoiles qui scintillent.
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.035, 0.07, 0.86)
	bg.border_color = Color(color, 0.35)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(16)
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	for k in range(6):
		var r := w * (0.55 - 0.07 * float(k))
		draw_circle(Vector2(w * 0.5, h * 0.12), r, Color(color, 0.012))
	for s in _stars:
		var tw := 0.5 + 0.5 * sin(_t * 1.6 + s.z * 20.0)
		draw_circle(Vector2(s.x * w, s.y * h), 0.9 + s.z, Color(1, 1, 1, 0.08 + 0.22 * s.z * tw))
	var font := get_theme_default_font()
	var spent := Profile.branch_spent(branch)
	# Paliers : séparateurs et seuil en points.
	for i in range(_reqs.size()):
		var y := TOP + ROW_H * float(i) + ROW_H * 0.42
		var open := spent >= _reqs[i]
		if i > 0:
			var ys := TOP + ROW_H * float(i) - 6.0
			var x := LEFT
			while x < w - RIGHT:
				draw_line(Vector2(x, ys), Vector2(minf(x + 8.0, w - RIGHT), ys), Color(color, 0.12 if open else 0.06), 1.0)
				x += 16.0
		var c := Vector2(24.0, y)
		draw_circle(c, 17.0, Color(0.05, 0.06, 0.1, 0.95))
		draw_arc(c, 17.0, 0.0, TAU, 32, Color(color, 0.9) if open else Color(0.5, 0.5, 0.6, 0.5), 2.0, true)
		var txt := str(_reqs[i])
		var fs := 15
		var tsz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, c + Vector2(-tsz.x * 0.5, tsz.y * 0.32), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, UiTheme.GOLD if open else Color(0.6, 0.6, 0.7, 0.7))
	# Chemins entre les compétences : lumineux quand les deux bouts sont investis.
	for id in _nodes.keys():
		var node: Dictionary = _nodes[id]
		for pid in node.get("parents", []):
			if not _pos.has(str(pid)):
				continue
			var a: Vector2 = _pos[str(pid)] + Vector2(0, NODE * 0.42)
			var b: Vector2 = _pos[id] - Vector2(0, NODE * 0.42)
			var pr := Profile.skill_rank(str(pid)) > 0
			var cr := Profile.skill_rank(str(id)) > 0
			var pts := _curve(a, b)
			if pr and cr:
				draw_polyline(pts, Color(color, 0.22), 11.0, true)
				draw_polyline(pts, Color(color, 0.95), 4.0, true)
				# Étincelle qui court le long du chemin.
				var k := fmod(_t * 0.6 + float(hash(str(pid) + id) % 100) / 100.0, 1.0)
				draw_circle(pts[int(k * float(pts.size() - 1))], 3.0, Color(1, 1, 0.9, 0.9))
			elif pr:
				draw_polyline(pts, Color(color, 0.45 + 0.15 * sin(_t * 3.0)), 3.0, true)
			else:
				draw_polyline(pts, Color(0.55, 0.55, 0.68, 0.22), 2.0, true)


static func _curve(a: Vector2, b: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var m := (b.y - a.y) * 0.5
	for i in range(17):
		var t := float(i) / 16.0
		var p := a.bezier_interpolate(a + Vector2(0, m), b - Vector2(0, m), b, t)
		out.append(p)
	return out


## État d'une compétence : « max », « on » (investie), « open » (accessible), « wait » (accessible sans point),
## « locked ».
static func state_of(id: String, node: Dictionary) -> String:
	var r := Profile.skill_rank(id)
	if r >= int(node.get("max", 1)):
		return "max"
	if r > 0:
		return "on"
	var why := Profile.invest_block(id)
	if why == "":
		return "open"
	if why == "Aucun point disponible":
		return "wait"
	return "locked"


## Icône d'une compétence : son sort, son évolution, ou l'effet principal.
static func node_icon(node: Dictionary) -> String:
	if node.has("icon"):
		return str(node["icon"])
	match str(node.get("kind", "passive")):
		"spell":
			return str(node.get("unlock", "rune"))
		"evolution":
			for k in (node.get("mods", {}) as Dictionary).keys():
				if str(k).begins_with("ult"):
					return "meteore"
			return "champion"
	var mods: Dictionary = node.get("mods", {})
	if mods.is_empty():
		return "rune"
	var k := str(mods.keys()[0])
	var el := k.get_slice(".", 1) if k.contains(".") else ""
	var by_el := {"feu": "boule_de_feu", "givre": "eclat_givre", "foudre": "eclair_chaine", "nature": "racines", "lumiere": "lance_solaire",
		"ombre": "vortex_ombre", "arcane": "onde_arcanique", "physique": "fente"}
	if el != "" and by_el.has(el) and not k.begins_with("radius") and not k.begins_with("dur"):
		return str(by_el[el])
	var by_key := {"burn_dmg": "brasier", "burn_dur": "brasier", "embrasement": "brasier", "burning_vuln": "mur_flammes",
		"frozen_dur": "prison_glace", "frozen_vuln": "lance_glace", "zero_absolu": "tombeau_glace", "zone_slow": "ronces",
		"poison_dmg": "epines", "venom": "epines", "pandemic": "miasme", "heal_bonus": "priere", "aura_heal": "seve_vitale",
		"miracle": "priere", "barrier_regen": "rempart_sacre", "barrier_max": "rempart_sacre", "barrier_dr": "bouclier_leve",
		"barrier_cap": "bouclier_leve", "start_shield": "bouclier_arcanique", "spawn_shield": "bouclier_arcanique", "unit_def": "bouclier_leve",
		"dodge": "lames_miroirs", "riposte": "mille_lames", "unit_atk": "fente", "low_barrier_atk": "rage_primordiale", "frenzy_dur": "dechainement",
		"unit_hp": "seve_vitale", "unit_regen": "seve_vitale", "lifesteal": "trait_ombre", "crit": "tir_precision", "mark_vuln": "tir_precision",
		"hunt_mark": "tir_precision", "unit_range": "volee_fleches", "portal_split": "volee_fleches", "cadence": "sparkle", "unit_speed": "bond_furieux",
		"spell_cost": "moon", "mana_regen": "moon", "kill_mana": "moon", "cd_red": "distorsion", "spell_dmg": "projectile_arcanique",
		"surge_gain": "comete", "ult_dmg": "meteore", "ult_radius": "meteore", "champ_atk": "champion", "champ_hp": "champion",
		"bot_atk": "hurlement", "clan_chief": "hurlement", "portal_plus": "constellation", "free_clone": "lames_miroirs", "ghost_double": "lames_miroirs",
		"skeleton_bonus": "horde", "skeleton_chance": "ossements", "army_count": "armee_des_morts", "legion": "armee_des_morts",
		"anti_heal": "exorcisme", "heal_steal": "exorcisme", "chain_bonus": "eclair_chaine", "thirst": "dechainement"}
	return str(by_key.get(k, "sparkle"))


# ---------------------------------------------------------------- médaillon

class SkillNodeView:
	extends Control

	var node: Dictionary = {}
	var view: SkillTreeView
	var _down := Vector2.ZERO
	var _tex: Texture2D

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		_tex = Icons.tex(SkillTreeView.node_icon(node), 72)

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var mb := ev as InputEventMouseButton
			if mb.pressed:
				_down = mb.global_position
			elif mb.global_position.distance_to(_down) < 14.0:
				view.select(str(node["id"]))

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var id := str(node["id"])
		var kind := str(node.get("kind", "passive"))
		var st := SkillTreeView.state_of(id, node)
		var c := Vector2(size.x * 0.5, SkillTreeView.NODE * 0.5 + 4.0)
		var r := SkillTreeView.NODE * 0.36
		if kind == "keystone":
			r *= 1.18
		var bc := view.color
		var t := view._t
		var ring := Color(0.45, 0.45, 0.55, 0.7)
		var fill := Color(0.06, 0.07, 0.11, 1.0)
		var icol := Color(0.55, 0.55, 0.65, 0.55)
		match st:
			"max":
				ring = UiTheme.GOLD
				fill = Color(bc.darkened(0.55), 1.0)
				icol = Color.WHITE
			"on":
				ring = bc
				fill = Color(bc.darkened(0.65), 1.0)
				icol = bc.lightened(0.35)
			"open":
				ring = Color(bc, 0.55 + 0.45 * (0.5 + 0.5 * sin(t * 4.0)))
				icol = Color(bc.lightened(0.2), 0.95)
			"wait":
				ring = Color(bc, 0.5)
				icol = Color(bc, 0.7)
		# Halo des compétences investies (plus large une fois maîtrisées).
		if st in ["on", "max"]:
			for k in range(5):
				var a := (0.16 if st == "max" else 0.1) * (1.0 - float(k) / 5.0) * (0.8 + 0.2 * sin(t * 2.0 + float(k)))
				draw_circle(c, r + 4.0 + float(k) * 3.0, Color(UiTheme.GOLD if st == "max" else bc, a))
		if view.selected == id:
			draw_arc(c, r + 9.0, 0.0, TAU, 48, Color(1, 1, 1, 0.9), 2.0, true)
		var pts := _shape(kind, c, r)
		draw_colored_polygon(pts, fill)
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, Color(0, 0, 0, 0.6), 6.0, true)
		draw_polyline(closed, ring, 3.0 if kind != "keystone" else 4.0, true)
		if kind == "keystone":
			var inner := _shape(kind, c, r * 0.78)
			var ic := inner.duplicate()
			ic.append(inner[0])
			draw_polyline(ic, Color(ring, 0.5), 1.5, true)
		if _tex != null:
			var s := r * 1.15
			draw_texture_rect(_tex, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false, icol)
		if st == "locked":
			var lock := Icons.tex("lock", 32)
			draw_texture_rect(lock, Rect2(c + Vector2(r * 0.45, r * 0.4), Vector2(15, 15)), false, Color(0.85, 0.85, 0.95, 0.85))
		# Rang : « 2/5 » sous le médaillon.
		var font := get_theme_default_font()
		var mx := int(node.get("max", 1))
		var txt := "%d/%d" % [Profile.skill_rank(id), mx]
		var fs := 15
		var tsz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var tp := Vector2(c.x - tsz.x * 0.5, c.y + r + 18.0)
		var pill := Rect2(tp + Vector2(-6, -tsz.y + 2), Vector2(tsz.x + 12, tsz.y + 2))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.03, 0.04, 0.08, 0.92)
		sb.border_color = Color(ring, 0.8)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(8)
		draw_style_box(sb, pill)
		draw_string(font, tp, txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, UiTheme.GOLD if st == "max" else (Color.WHITE if st == "on" else Color(0.75, 0.75, 0.85, 0.85)))

	static func _shape(kind: String, c: Vector2, r: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		match kind:
			"spell":
				# Carré aux coins coupés.
				var k := r * 0.86
				var cut := r * 0.3
				for p in [Vector2(-k + cut, -k), Vector2(k - cut, -k), Vector2(k, -k + cut), Vector2(k, k - cut), Vector2(k - cut, k), Vector2(-k + cut, k), Vector2(-k, k - cut), Vector2(-k, -k + cut)]:
					out.append(c + (p as Vector2))
			"evolution":
				for i in range(6):
					var a := float(i) * TAU / 6.0 + PI / 6.0
					out.append(c + Vector2(cos(a), sin(a)) * r * 1.02)
			"keystone":
				for p in [Vector2(0, -1.15), Vector2(1.15, 0), Vector2(0, 1.15), Vector2(-1.15, 0)]:
					out.append(c + (p as Vector2) * r)
			_:
				for i in range(28):
					var a := float(i) * TAU / 28.0
					out.append(c + Vector2(cos(a), sin(a)) * r)
		return out
