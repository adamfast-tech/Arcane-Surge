class_name RuneBox
extends StyleBox
## Cadre de l'interface (concept UI) : coins coupés en biseau, bordure fine, et en option des
## coins plus clairs qui soulignent le biseau. Remplace les coins arrondis partout.

@export var bg := Color(0.07, 0.1, 0.15, 0.92)
@export var border := Color("2b4153")
@export var border_w := 2.0
@export var cut := 10.0
## Couleur des coins soulignés (transparent : aucun).
@export var accent := Color(0, 0, 0, 0)

## Ambiance enrichie (Options) : fond en dégradé, reflet sur l'arête du haut, rivets aux coins.
static var rich := false


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x < 2.0 or rect.size.y < 2.0:
		return
	if bg.a > 0.0:
		var poly := _outline(rect, 0.0)
		if rich and rect.size.y > 20.0:
			# Fond en dégradé vertical : plus clair en haut, comme une pierre éclairée d'en haut.
			var top := Color(bg.lightened(0.09), bg.a)
			var bot := Color(bg.darkened(0.22), bg.a)
			var cols := PackedColorArray()
			for q in poly:
				cols.append(top.lerp(bot, clampf((q.y - rect.position.y) / rect.size.y, 0.0, 1.0)))
			RenderingServer.canvas_item_add_polygon(to_canvas_item, poly, cols)
			# Reflet fin sous l'arête du haut.
			var c := minf(cut, minf(rect.size.x, rect.size.y) * 0.35)
			RenderingServer.canvas_item_add_line(to_canvas_item, rect.position + Vector2(c + 3.0, border_w + 1.5),
				Vector2(rect.end.x - c - 3.0, rect.position.y + border_w + 1.5), Color(1, 1, 1, 0.07 * bg.a), 1.0, true)
		else:
			RenderingServer.canvas_item_add_polygon(to_canvas_item, poly, PackedColorArray([bg]))
	if rich and accent.a > 0.0:
		# Bouton principal : halo de la couleur d'accent autour du cadre.
		var gl := _outline(rect, -3.0)
		gl.append(gl[0])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, gl, PackedColorArray([Color(accent, 0.22)]), 6.0, true)
	if border.a > 0.0 and border_w > 0.0:
		var pts := _outline(rect, border_w * 0.5)
		pts.append(pts[0])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, pts, PackedColorArray([border]), border_w, true)
		if rich and rect.size.x > 60.0 and rect.size.y > 36.0:
			# Double liseré : un filet intérieur, plus discret.
			var inner := _outline(rect, border_w + 3.5)
			inner.append(inner[0])
			RenderingServer.canvas_item_add_polyline(to_canvas_item, inner, PackedColorArray([Color(border, border.a * 0.38)]), 1.0, true)
		if rich and cut > 3.0 and rect.size.x > 70.0 and rect.size.y > 44.0:
			# Rivets : un petit losange clair au milieu de chaque biseau.
			var o := _outline(rect, border_w * 0.5)
			if o.size() == 8:
				var rc := Color(border.lightened(0.45), border.a)
				for i in [1, 3, 5, 7]:
					var mid: Vector2 = (o[i] + o[(i + 1) % 8]) * 0.5
					var s := 2.2
					RenderingServer.canvas_item_add_polygon(to_canvas_item, PackedVector2Array([mid + Vector2(0, -s), mid + Vector2(s, 0), mid + Vector2(0, s), mid + Vector2(-s, 0)]),
						PackedColorArray([rc]))
	if accent.a > 0.0 and cut > 0.0:
		var p := _outline(rect, border_w * 0.5)
		if p.size() == 8:
			for i in [1, 3, 5, 7]:
				RenderingServer.canvas_item_add_line(to_canvas_item, p[i], p[(i + 1) % 8], accent, border_w + 1.0, true)


## Contour du cadre (octogone à coins coupés), rentré de « inset » pixels.
func _outline(rect: Rect2, inset: float) -> PackedVector2Array:
	var x0 := rect.position.x + inset
	var y0 := rect.position.y + inset
	var x1 := rect.end.x - inset
	var y1 := rect.end.y - inset
	var c := minf(cut, minf(x1 - x0, y1 - y0) * 0.35)
	if c <= 0.5:
		return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])
	return PackedVector2Array([Vector2(x0 + c, y0), Vector2(x1 - c, y0), Vector2(x1, y0 + c), Vector2(x1, y1 - c),
		Vector2(x1 - c, y1), Vector2(x0 + c, y1), Vector2(x0, y1 - c), Vector2(x0, y0 + c)])
