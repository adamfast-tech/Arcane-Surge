class_name CosmeticThumb
extends Control
## Vignette d'une pièce cosmétique : le héros du joueur qui ne porte que cette pièce, rendu en pixel art
## (HeroModel) sous l'angle qui la montre le mieux (de dos pour une cape, recadré sur la tête pour un
## chapeau). Les vignettes sont gardées en cache ; une seule est rendue par image, pour ne pas figer l'écran.

static var _cache: Dictionary = {}
static var _frame := -1 ## dernière image où une vignette a été rendue

var piece := ""
var dim := false ## pièce non possédée : vignette assombrie
var _key := ""
var _tex: Texture2D


static func make(id: String, px: int, owned: bool = true) -> CosmeticThumb:
	var t := CosmeticThumb.new()
	t.piece = id
	t.dim = not owned
	t.custom_minimum_size = Vector2(px, float(HeroModel.FOOT_H * 3 + 4)) # le héros en pied, pixels triplés
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return t


func _ready() -> void:
	_key = "%s|%s|%s|%s" % [JSON.stringify(Profile.look()), Profile.race(), Profile.player_class(), piece]
	_tex = _cache.get(_key)
	set_process(_tex == null)


func _process(_d: float) -> void:
	if Engine.get_process_frames() == _frame:
		return
	_frame = Engine.get_process_frames()
	_tex = _render()
	_cache[_key] = _tex
	if _cache.size() > 80:
		_cache.clear()
		_cache[_key] = _tex
	set_process(false)
	queue_redraw()


func _render() -> Texture2D:
	var slot := piece.get_slice(".", 1)
	var m := HeroModel.new()
	m.build(Profile.look(), Profile.race(), Profile.player_class(), {slot: piece})
	var yaw := PI + 0.35
	if slot == "dos":
		yaw = 0.55
	elif slot == "arme":
		yaw = PI + 0.7
	var img := m.image_at(yaw)
	var used := img.get_used_rect()
	if slot == "tete":
		# Recadré sur la tête et ce qui la coiffe.
		used = Rect2i(used.position.x, used.position.y, used.size.x, mini(used.size.y, 17))
	var out := img.get_region(used)
	return ImageTexture.create_from_image(out)


func _draw() -> void:
	if _tex == null:
		# En attente du rendu : une silhouette discrète.
		draw_circle(size * 0.5, minf(size.x, size.y) * 0.18, Color(1, 1, 1, 0.06))
		return
	var ts := _tex.get_size()
	var k := floorf(minf(size.x / ts.x, size.y / ts.y))
	k = maxf(1.0, k)
	var sz := ts * k
	var mod := Color(0.55, 0.55, 0.6, 0.85) if dim else Color.WHITE
	draw_texture_rect(_tex, Rect2(((size - sz) * 0.5).floor(), sz), false, mod)
