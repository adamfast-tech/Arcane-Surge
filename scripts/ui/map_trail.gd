class_name MapTrail
extends Control
## Carte (ambiance enrichie) : chemin lumineux entre deux niveaux. Les pas défilent vers le niveau suivant ;
## or pour un chemin parcouru, sarcelle vers le prochain niveau, gris éteint vers un niveau verrouillé.

var state := "done" ## done | next | locked
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 26)
	_t = randf() * 4.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var col := UiTheme.GOLD if state == "done" else (UiTheme.TEAL if state == "next" else Color(UiTheme.MUTED, 0.35))
	var speed := 0.0 if state == "locked" else (16.0 if state == "done" else 26.0)
	var x0 := 44.0
	var h := size.y + 10.0
	var step := 7.0
	var n := int(h / step) + 2
	for i in range(n):
		var y := fposmod(float(i) * step + _t * speed, h) - 5.0
		var p := Vector2(x0 + sin(y * 0.22 + 1.3) * 5.0, y)
		if state != "locked":
			draw_circle(p, 4.0, Color(col, 0.18))
		draw_circle(p, 1.8, Color(col, 0.9 if state != "locked" else 0.5))
	if state == "next":
		# Le prochain niveau : une lueur qui palpite au bout du chemin.
		var a := 0.35 + 0.25 * sin(_t * 3.0)
		draw_circle(Vector2(x0, size.y - 2.0), 7.0, Color(col, a * 0.5))
