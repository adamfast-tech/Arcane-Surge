class_name ArenaView
extends Node2D
## Rendu pixel-art de l'arène dans un SubViewport basse résolution, agrandi
## ensuite d'un facteur entier (pixels nets). Positions interpolées entre deux pas.

var sim: BattleSim
var font: Font
var font_small: Font
var ppm := 32
var origin := Vector2.ZERO
var vp_size := Vector2i(360, 640)
var alpha := 0.0
var bg: Texture2D
var fx: Array[Dictionary] = []
var t := 0.0
var shake := 0.0
var flash := 0.0
var aim_active := false
var aim_pos := Vector2(-100.0, -100.0)
var aim_radius := 1.0
var aim_color := Color.WHITE
var _buckets: Array = []


func setup(s: BattleSim, size: Vector2i, f: Font) -> void:
	sim = s
	font = f
	font_small = UiTheme.font_small()
	for i in range(36):
		_buckets.append([])
	resize(size)


func resize(size: Vector2i) -> void:
	vp_size = size
	ppm = maxi(8, int(floor(minf(float(size.x) / 9.6, float(size.y) / 16.6))))
	origin = Vector2(floor((float(size.x) - 9.0 * ppm) * 0.5), floor((float(size.y) - 16.0 * ppm) * 0.5))
	bg = ArenaArt.build(size, ppm, origin)
	queue_redraw()


func to_px(p: Vector2) -> Vector2:
	return origin + Vector2(p.x * ppm, (BattleSim.H - p.y) * ppm)


func to_logic(px: Vector2) -> Vector2:
	var l := (px - origin) / float(ppm)
	return Vector2(l.x, BattleSim.H - l.y)


func consume_events(events: Array[Dictionary]) -> void:
	for e in events:
		match str(e["t"]):
			"barrier":
				shake = 0.25
			"flash":
				flash = 0.35
			_:
				var d := e.duplicate()
				d["age"] = 0.0
				if not d.has("dur"):
					d["dur"] = 0.8 if str(e["t"]) == "text" else 0.35
				fx.append(d)
	while fx.size() > 350:
		fx.remove_at(0)


func _process(delta: float) -> void:
	t += delta
	shake = maxf(0.0, shake - delta)
	flash = maxf(0.0, flash - delta)
	var i := 0
	while i < fx.size():
		var e: Dictionary = fx[i]
		e["age"] = float(e["age"]) + delta
		if float(e["age"]) >= float(e["dur"]):
			fx.remove_at(i)
		else:
			i += 1
	queue_redraw()


func _draw() -> void:
	if sim == null or bg == null:
		return
	var off := Vector2.ZERO
	if shake > 0.0:
		off = Vector2(randi_range(-1, 1), randi_range(-1, 1)) * ceilf(shake * 6.0)
	draw_set_transform(off)
	draw_texture(bg, Vector2.ZERO)
	_draw_barrier()
	for p in sim.portals:
		_draw_portal(p)
	_draw_towers()
	_draw_nexus()
	_draw_units()
	for p in sim.portals:
		_draw_portal_label(p)
	_draw_casters()
	_draw_fx()
	_draw_aim()
	draw_set_transform(Vector2.ZERO)
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(vp_size)), Color(1.0, 0.95, 0.85, flash * 1.2))


# ---------------------------------------------------------------- éléments fixes

func _draw_barrier() -> void:
	var y := to_px(Vector2(0.0, BattleSim.BARRIER_Y)).y
	var x0 := origin.x
	var w := 9.0 * ppm
	var col := Color("f2c46b")
	if sim.barrier_flash > 0.0:
		col = Color("ff6b6b")
	draw_rect(Rect2(x0, y - 1.0, w, 3.0), Color(col, 0.35))
	draw_rect(Rect2(x0, y, w, 1.0), col)
	var x := x0 + 3.0
	while x < x0 + w:
		draw_rect(Rect2(x, y - 2.0, 1.0, 2.0), col)
		x += 7.0
	if sim.barrier_shield > 0.0:
		draw_rect(Rect2(x0, y - 4.0, w, 1.0), Color("4fe3d2"))


func _draw_portal(p: Portal) -> void:
	var c := to_px(Vector2(p.x, p.y)).round()
	var half := roundf(p.width * 0.5 * ppm)
	var col := p.color()
	var h := maxf(3.0, roundf(ppm * 0.18))
	var stone := Color("5a5670")
	var ph := roundf(ppm * 0.55)
	draw_rect(Rect2(c.x - half - 3.0, c.y - ph, 3.0, ph + 3.0), stone)
	draw_rect(Rect2(c.x + half, c.y - ph, 3.0, ph + 3.0), stone)
	draw_rect(Rect2(c.x - half - 3.0, c.y - ph, 3.0, 1.0), stone.lightened(0.3))
	draw_rect(Rect2(c.x + half, c.y - ph, 3.0, 1.0), stone.lightened(0.3))
	var a := 0.32 + 0.12 * sin(t * 4.0 + float(p.id))
	var dim := (p.kind == "add" and not p.ready) or (p.kind == "sub" and p.charges <= 0)
	if dim:
		a = 0.12
	if p.flash_t > 0.0:
		a = 0.85
	draw_rect(Rect2(c.x - half, c.y - h * 0.5, half * 2.0, h), Color(col, a))
	if p.is_negative():
		var x := c.x - half
		while x < c.x + half:
			draw_rect(Rect2(x, c.y - h * 0.5, minf(3.0, c.x + half - x), 1.0), col)
			draw_rect(Rect2(x, c.y + h * 0.5 - 1.0, minf(3.0, c.x + half - x), 1.0), col)
			x += 5.0
	else:
		draw_rect(Rect2(c.x - half, c.y - h * 0.5, half * 2.0, h), col, false, 1.0)
	if p.is_seal and not p.purified:
		var bw := half * 2.0
		var by := c.y + h * 0.5 + 2.0
		draw_rect(Rect2(c.x - half, by, bw, 2.0), Color(0.1, 0.05, 0.15, 0.9))
		draw_rect(Rect2(c.x - half, by, bw * float(p.purity) / float(maxi(1, p.purity_needed)), 2.0), Color("fff6c8"))
		var s := "SCEAU"
		var sw := font_small.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(font_small, Vector2(roundf(c.x - sw * 0.5), by + 15.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d93cf2"))


func _draw_portal_label(p: Portal) -> void:
	var c := to_px(Vector2(p.x, p.y)).round()
	var h := maxf(3.0, roundf(ppm * 0.18))
	var dim := (p.kind == "add" and not p.ready) or (p.kind == "sub" and p.charges <= 0)
	var text := p.label()
	var lf: Font = font if text.length() <= 4 else font_small
	var fs := (20 if text.length() <= 4 else 15) if ppm >= 28 else (10 if text.length() <= 4 else 15)
	var ts := lf.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var base := Vector2(roundf(c.x - ts.x * 0.5), roundf(c.y - h * 0.5 - 4.0))
	draw_rect(Rect2(base.x - 3.0, base.y - lf.get_ascent(fs) - 1.0, ts.x + 6.0, lf.get_ascent(fs) + 3.0), Color(0.05, 0.03, 0.1, 0.72))
	draw_string(lf, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE if not dim else Color(1, 1, 1, 0.5))


func _draw_towers() -> void:
	for tw in sim.towers:
		var c := to_px(tw["pos"]).round()
		var w := maxf(6.0, roundf(ppm * 0.42))
		var h := roundf(ppm * 0.95)
		if not tw["alive"]:
			draw_rect(Rect2(c.x - w * 0.5, c.y - 4.0, w, 4.0), Color("3a3850"))
			continue
		var stone := Color("4a4860") if float(tw["flash"]) <= 0.0 else Color("8a88a0")
		draw_rect(Rect2(c.x - w * 0.5 + 1.0, c.y + 1.0, w, 2.0), Color(0, 0, 0, 0.4))
		draw_rect(Rect2(c.x - w * 0.5, c.y - h, w, h), stone)
		draw_rect(Rect2(c.x - w * 0.5, c.y - h, 1.0, h), stone.lightened(0.2))
		var cy := c.y - h - 4.0 + roundf(sin(t * 2.0) * 1.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(c.x, cy - 5.0), Vector2(c.x + 3.0, cy), Vector2(c.x, cy + 4.0), Vector2(c.x - 3.0, cy)
		]), Color("b07cff"))
		var ratio := float(tw["hp"]) / float(tw["max"])
		draw_rect(Rect2(c.x - w * 0.5, c.y - h - 12.0, w, 2.0), Color(0.1, 0.05, 0.15))
		draw_rect(Rect2(c.x - w * 0.5, c.y - h - 12.0, w * ratio, 2.0), Color("c2456b"))


func _draw_nexus() -> void:
	var c := to_px(BattleSim.NEXUS_POS).round()
	var s := roundf(ppm * 0.62)
	var glow := 0.12 + 0.05 * sin(t * 3.0)
	draw_circle(c, s * 1.6, Color(0.69, 0.49, 1.0, glow))
	draw_rect(Rect2(c.x - s * 0.9, c.y + s * 0.6, s * 1.8, 3.0), Color("3a3550"))
	var body := Color("b07cff")
	if sim.nexus_flash > 0.0:
		body = Color("f4ecff")
	var top := c + Vector2(0.0, -s * 1.4 + sin(t * 2.0) * 1.5)
	draw_colored_polygon(PackedVector2Array([top, c + Vector2(s * 0.8, 0.0), c + Vector2(0.0, s * 0.8), c + Vector2(-s * 0.8, 0.0)]), body)
	draw_colored_polygon(PackedVector2Array([top + Vector2(0.0, s * 0.45), c + Vector2(s * 0.35, 0.0), c + Vector2(0.0, s * 0.35), c + Vector2(-s * 0.35, 0.0)]), Color("e7d6f5"))
	if sim.nexus_shielded():
		draw_arc(c + Vector2(0.0, -s * 0.3), s * 1.6, 0.0, TAU, 40, Color(0.85, 0.24, 0.95, 0.55 + 0.25 * sin(t * 5.0)), 2.0)
	if sim.nexus_wither_t > 0.0:
		draw_arc(c, s * 1.15, 0.0, TAU, 24, Color(0.23, 0.16, 0.42, 0.9), 2.0)


# ---------------------------------------------------------------- unités et lanceurs

func _draw_units() -> void:
	for b in _buckets:
		b.clear()
	for u in sim.allies:
		if u.alive:
			_buckets[clampi(int(u.pos.y * 2.0), 0, 35)].append(u)
	for e in sim.enemies:
		if e.alive:
			_buckets[clampi(int(e.pos.y * 2.0), 0, 35)].append(e)
	for i in range(35, -1, -1):
		for u in _buckets[i]:
			_draw_unit(u)


func _draw_unit(u: Unit) -> void:
	var p := to_px(u.prev_pos.lerp(u.pos, alpha)).round()
	var tex := PixelSprites.unit_tex(u)
	var sz := tex.get_size()
	var bob := 0.0
	if not u.engaged and u.speed_factor() > 0.0:
		bob = roundf(sin(u.anim * 9.0) * 0.8)
	draw_rect(Rect2(p.x - sz.x * 0.5 + 1.0, p.y - 1.0, sz.x - 2.0, 2.0), Color(0, 0, 0, 0.35))
	var mod := Color.WHITE
	if u.flash_t > 0.0:
		mod = Color(1.0, 0.5, 0.5) if u.team == 1 else Color(1.0, 1.0, 1.0, 0.55)
	elif u.frozen_t > 0.0:
		mod = Color(0.6, 0.85, 1.0)
	elif u.rooted_t > 0.0:
		mod = Color(0.75, 0.95, 0.55)
	elif u.burn_t > 0.0 and int(t * 10.0) % 2 == 0:
		mod = Color(1.0, 0.72, 0.5)
	elif u.poison_t > 0.0 and int(t * 8.0) % 3 == 0:
		mod = Color(0.7, 1.0, 0.6)
	var top_left := Vector2(roundf(p.x - sz.x * 0.5), p.y - sz.y - 1.0 + bob)
	draw_texture(tex, top_left, mod)
	if u.shield > 0.0:
		draw_rect(Rect2(top_left - Vector2(1, 1), sz + Vector2(2, 2)), Color("4fe3d2"), false, 1.0)
	var show_bar := (u.team == 1 and u.max_hp >= 25.0) or u.role == "champion" or u.role == "elite"
	if show_bar and u.hp < u.max_hp:
		var bw := maxf(6.0, sz.x)
		var by := top_left.y - 3.0
		draw_rect(Rect2(p.x - bw * 0.5, by, bw, 2.0), Color(0.08, 0.05, 0.12, 0.9))
		draw_rect(Rect2(p.x - bw * 0.5, by, bw * clampf(u.hp / u.max_hp, 0.0, 1.0), 2.0), Color("ff6b8a") if u.team == 1 else Color("6fe39a"))
	if u.role == "soigneur":
		draw_rect(Rect2(p.x - 1.0, top_left.y - 7.0, 3.0, 1.0), Color("6fe39a"))
		draw_rect(Rect2(p.x, top_left.y - 8.0, 1.0, 3.0), Color("6fe39a"))


func _draw_casters() -> void:
	var lane_x := 0.0
	for c in sim.casters:
		var x := lerpf(c.prev_x, c.x, alpha)
		var p := to_px(Vector2(x, BattleSim.CASTER_Y)).round()
		var tex := PixelSprites.get_tex(c.sprite)
		var sz := tex.get_size()
		if c.idx == 0:
			lane_x = p.x
			draw_circle(p + Vector2(0, -1), 6.0, Color(0.31, 0.89, 0.82, 0.25 + (0.15 if c.firing else 0.0)))
		draw_rect(Rect2(p.x - sz.x * 0.5, p.y - 1.0, sz.x, 2.0), Color(0, 0, 0, 0.4))
		draw_texture(tex, Vector2(roundf(p.x - sz.x * 0.5), p.y - sz.y))
		if c.idx == 0:
			var tip := Vector2(p.x + sz.x * 0.5 + 1.0, p.y - sz.y - 2.0)
			draw_line(Vector2(p.x + sz.x * 0.5 + 1.0, p.y), tip, Color("8a5a2b"), 1.0)
			draw_rect(Rect2(tip.x - 1.0, tip.y - 1.0, 3.0, 3.0), Color("4fe3d2") if c.firing else Color("2a8a80"))
	# Ligne de visée du joueur.
	var top_y := to_px(Vector2(0.0, BattleSim.H - 0.5)).y
	var y := to_px(Vector2(0.0, BattleSim.CASTER_Y + 1.0)).y
	while y > top_y:
		draw_rect(Rect2(lane_x, y, 1.0, 2.0), Color(0.31, 0.89, 0.82, 0.22))
		y -= 7.0


# ---------------------------------------------------------------- effets

func _draw_fx() -> void:
	for e in fx:
		var k := float(e["age"]) / float(e["dur"])
		var col := Color(str(e.get("color", "FFFFFF")))
		match str(e["t"]):
			"ring":
				var r := float(e["r"]) * ppm * (0.5 + 0.5 * k)
				draw_arc(to_px(e["pos"]), r, 0.0, TAU, 32, Color(col, 1.0 - k), 2.0)
				if k < 0.3:
					draw_circle(to_px(e["pos"]), r * 0.9, Color(col, 0.18 * (1.0 - k / 0.3)))
			"beam":
				draw_line(to_px(e["a"]), to_px(e["b"]), Color(col, 1.0 - k), float(e.get("w", 1.0)))
			"puff":
				var p := to_px(e["pos"])
				var d := 1.0 + k * 5.0
				var cc := Color(col, 1.0 - k)
				draw_rect(Rect2(p + Vector2(-d, -d - 4.0), Vector2(2, 2)), cc)
				draw_rect(Rect2(p + Vector2(d, -d - 4.0), Vector2(2, 2)), cc)
				draw_rect(Rect2(p + Vector2(-d, d - 4.0), Vector2(1, 1)), cc)
				draw_rect(Rect2(p + Vector2(d, d - 4.0), Vector2(1, 1)), cc)
			"text":
				var fs := 20 if ppm >= 28 else 10
				var s := str(e["text"])
				var tw := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				var p := (to_px(e["pos"]) + Vector2(-tw * 0.5, -k * 14.0)).round()
				draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.05, 0.03, 0.1, 1.0 - k))
				draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(col, 1.0 - k * k))


func _draw_aim() -> void:
	if not aim_active or aim_pos.x < -50.0:
		return
	var c := to_px(aim_pos).round()
	var r := aim_radius * ppm
	draw_arc(c, r, 0.0, TAU, 40, Color(aim_color, 0.9), 1.0)
	draw_circle(c, r, Color(aim_color, 0.12))
	draw_rect(Rect2(c.x - 3.0, c.y, 7.0, 1.0), aim_color)
	draw_rect(Rect2(c.x, c.y - 3.0, 1.0, 7.0), aim_color)
