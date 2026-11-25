class_name CineFx
extends Node2D
## Calque d'effets des cinématiques, dessiné en basse résolution (pixel-art) dans un SubViewport :
## « light » (additif : lueurs, rayons, cercles, éclairs), « back » (derrière les personnages : volutes,
## poussière) et « front » (devant : feuilles, bulles d'émotion). Le dessin lui-même est dans CineStage.

var stage: CineStage
var layer := "light"


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if stage != null:
		stage.draw_layer(self, layer)
