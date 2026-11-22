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


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x < 2.0 or rect.size.y < 2.0:
		return
	if bg.a > 0.0:
		RenderingServer.canvas_item_add_polygon(to_canvas_item, _outline(rect, 0.0), PackedColorArray([bg]))
	if border.a > 0.0 and border_w > 0.0:
		var pts := _outline(rect, border_w * 0.5)
		pts.append(pts[0])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, pts, PackedColorArray([border]), border_w, true)
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
