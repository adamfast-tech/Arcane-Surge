class_name PlaceArt
extends RefCounted
## Façades en pixel art de la place d'Havre-Aube (HavrePlace) : chaque lieu a son allure (pierre, colombages, tour,
## enclos, feu de camp…), ses fenêtres (allumées le soir et la nuit), son enseigne. Fond transparent.

## Ciel (haut, bas) et collines lointaines, selon l'heure.
const SKY := {
	"aube": ["2a2a5a", "f0a07a", "4a3a5a"],
	"jour": ["5a9ad8", "bfe0f0", "5a7a6a"],
	"crepuscule": ["3a2050", "e0704a", "3a2a3a"],
	"nuit": ["080a1e", "1e2a4a", "141a2a"],
}
## Rue pavée (fond, pavés).
const STREET := {
	"aube": ["4a3e48", "5a4e56"],
	"jour": ["6a6460", "7e7872"],
	"crepuscule": ["4a3a3a", "5a4846"],
	"nuit": ["1e1e2a", "2a2a38"],
}

static var _img: Image
static var _rng := RandomNumberGenerator.new()


static func _c(h: String) -> Color:
	return Color(h)


static func _rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(maxi(0, y), mini(_img.get_height(), y + h)):
		for xx in range(maxi(0, x), mini(_img.get_width(), x + w)):
			_img.set_pixel(xx, yy, c)


static func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < _img.get_width() and y < _img.get_height():
		_img.set_pixel(x, y, c)


## Mur de pierre ou de briques : un fond, des joints, quelques pierres plus claires ou plus sombres.
static func _wall(x: int, y: int, w: int, h: int, base: Color, brick: bool) -> void:
	_rect(x, y, w, h, base)
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var row := (yy - y) / 4
			var joint := (yy - y) % 4 == 3 or (brick and (xx - x + (row % 2) * 4) % 8 == 0)
			if joint:
				_px(xx, yy, base.darkened(0.25))
			elif _rng.randf() < 0.08:
				_px(xx, yy, base.lightened(0.08) if _rng.randf() < 0.5 else base.darkened(0.08))


## Toit en pente (deux pans) avec ses rangs de tuiles.
static func _roof(x: int, y: int, w: int, h: int, col: Color) -> void:
	for i in range(h):
		var inset := int(float(i) * float(w) * 0.5 / float(h))
		var yy := y + h - 1 - i
		for xx in range(x + inset, x + w - inset):
			var tile := (yy - y) % 3 == 0
			_px(xx, yy, col.darkened(0.25) if tile else (col if (xx + yy) % 5 else col.lightened(0.08)))
	for xx in range(x, x + w):
		_px(xx, y + h - 1, col.darkened(0.45))


## Fenêtre : cadre, carreaux, et la lumière de l'intérieur le soir.
static func _window(x: int, y: int, w: int, h: int, lit: bool, frame: Color, arched: bool = false) -> void:
	var glass := _c("ffd27a") if lit else _c("2a3a52")
	_rect(x - 1, y - 1, w + 2, h + 2, frame)
	_rect(x, y, w, h, glass)
	if lit:
		_rect(x, y, w, 1, _c("fff0b0"))
	else:
		_px(x, y, _c("8aa8c8"))
	_rect(x + w / 2, y, 1, h, frame)
	_rect(x, y + h / 2, w, 1, frame)
	if arched:
		for xx in range(x, x + w):
			_px(xx, y - 2, frame)
		_px(x, y - 1, Color(0, 0, 0, 0))
		_px(x + w - 1, y - 1, Color(0, 0, 0, 0))


static func _door(x: int, y: int, w: int, h: int, wood: Color, glow: Color = Color(0, 0, 0, 0)) -> void:
	_rect(x - 1, y - 1, w + 2, h + 1, wood.darkened(0.45))
	if glow.a > 0.0:
		_rect(x, y, w, h, glow)
		return
	_rect(x, y, w, h, wood)
	for xx in range(x + 2, x + w, 3):
		_rect(xx, y, 1, h, wood.darkened(0.2))
	_px(x + w - 3, y + h / 2, _c("e0b850"))


## La façade d'un lieu, de w × h pixels.
static func facade(id: String, w: int, h: int, phase: String) -> Image:
	_img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	_img.fill(Color(0, 0, 0, 0))
	_rng.seed = id.hash()
	var lit := phase == "nuit" or phase == "crepuscule"
	var night := phase == "nuit"
	var dim := 0.35 if night else (0.12 if phase == "crepuscule" else 0.0)
	match id:
		"portail":
			# Arche de pierre runique, et le portail bleu qui tourbillonne (animé par la place).
			_wall(4, 14, 14, h - 14, _c("6a6a7a"), false)
			_wall(w - 18, 14, 14, h - 14, _c("6a6a7a"), false)
			for i in range(w - 8):
				var a := float(i) / float(w - 9) * PI
				var yy := int(30.0 - sin(a) * 22.0)
				_rect(4 + i, yy - 4, 1, 8, _c("7a7a8a"))
				_px(4 + i, yy - 4, _c("9a9aaa"))
			_rect(18, 22, w - 36, h - 22, _c("10203a"))
			for k in range(6):
				_px(10, 30 + k * 8, _c("4fe3d2"))
				_px(w - 11, 30 + k * 8, _c("4fe3d2"))
		"maison":
			_wall(6, 26, w - 12, h - 26, _c("c8b090"), false)
			for yy in range(26, h, 8):
				_rect(6, yy, w - 12, 1, _c("6a4a2a"))
			_roof(2, 4, w - 4, 24, _c("8a3a2a"))
			_window(14, 36, 10, 10, lit, _c("6a4a2a"))
			_window(w - 24, 36, 10, 10, lit, _c("6a4a2a"))
			_door(w / 2 - 6, h - 20, 12, 20, _c("7a4a2a"))
			# Le coffre devant la porte.
			_rect(w / 2 + 10, h - 7, 12, 7, _c("6a4428"))
			_rect(w / 2 + 10, h - 7, 12, 2, _c("e0b850"))
		"defis":
			# Tableau d'affichage sur deux poteaux, papiers épinglés.
			_rect(6, 10, 4, h - 10, _c("5a3a22"))
			_rect(w - 10, 10, 4, h - 10, _c("5a3a22"))
			_rect(2, 8, w - 4, 30, _c("7a5230"))
			_rect(4, 10, w - 8, 26, _c("9a6a3a"))
			for k in range(5):
				var px := 7 + (k % 3) * 12
				var py := 13 + (k / 3) * 12
				_rect(px, py, 9, 9, _c("f0e8d0"))
				_rect(px + 1, py + 3, 6, 1, _c("8a8a9a"))
				_rect(px + 1, py + 5, 5, 1, _c("8a8a9a"))
				_px(px + 4, py, _c("d84a3a"))
			_rect(2, 6, w - 4, 2, _c("4a2e1a"))
		"forge":
			_wall(4, 22, w - 8, h - 22, _c("4a4048"), false)
			_roof(0, 6, w - 14, 18, _c("3a2a2a"))
			# Grande cheminée.
			_wall(w - 22, 0, 12, 40, _c("5a4a4a"), true)
			_rect(w - 24, 0, 16, 3, _c("2a2026"))
			_window(12, 34, 10, 9, true, _c("2a2026"))
			_door(w / 2 - 10, h - 26, 20, 26, _c("3a2414"), _c("ff8a3a") if true else Color(0, 0, 0, 0))
			_rect(w / 2 - 10, h - 26, 20, 3, _c("ffd070"))
			# Enclume de l'enseigne.
			_rect(w - 30, 30, 12, 3, _c("8a8a9a"))
			_rect(w - 27, 33, 6, 4, _c("6a6a7a"))
		"armurerie":
			_wall(4, 22, w - 8, h - 22, _c("e0d4b8"), false)
			for xx in range(4, w - 4, 12):
				_rect(xx, 22, 2, h - 22, _c("4a2e1a"))
			_rect(4, 22, w - 8, 2, _c("4a2e1a"))
			_rect(4, h - 30, w - 8, 2, _c("4a2e1a"))
			_roof(0, 4, w, 20, _c("4a5a7a"))
			# Vitrine : une épée et un bouclier.
			_rect(10, h - 26, 26, 20, _c("6a4a2a"))
			_rect(12, h - 24, 22, 16, _c("ffd27a") if lit else _c("3a4a62"))
			_rect(16, h - 23, 2, 14, _c("d8dce8"))
			_rect(14, h - 13, 6, 1, _c("e0b850"))
			for yy in range(h - 22, h - 12):
				for xx in range(24, 32):
					if Vector2(xx - 28, yy - (h - 17)).length() < 4.2:
						_px(xx, yy, _c("8a2e3a") if Vector2(xx - 28, yy - (h - 17)).length() < 3.0 else _c("e0b850"))
			_door(w - 26, h - 24, 14, 24, _c("6a3a22"))
			_window(w - 26, 30, 12, 10, lit, _c("4a2e1a"))
		"bibliotheque":
			_wall(4, 20, w - 8, h - 20, _c("8a8a96"), false)
			_roof(0, 2, w, 20, _c("3a4a3a"))
			for k in range(3):
				_window(10 + k * 22, 32, 10, 18, lit, _c("4a4a56"), true)
			_door(w / 2 - 8, h - 24, 16, 24, _c("4a3020"))
			_rect(w / 2 - 10, h - 26, 20, 2, _c("6a6a7a"))
			# Livre ouvert de l'enseigne.
			_rect(w / 2 - 6, 60, 12, 7, _c("f0e8d0"))
			_rect(w / 2, 60, 1, 7, _c("8a6a2a"))
		"entrainement":
			# Enclos de bois, mannequin de paille, cible.
			for xx in range(2, w - 2, 9):
				_rect(xx, h - 20, 3, 20, _c("7a5230"))
			_rect(0, h - 16, w, 2, _c("9a6a3a"))
			_rect(0, h - 8, w, 2, _c("9a6a3a"))
			_rect(20, h - 44, 4, 30, _c("6a4428"))
			_rect(13, h - 38, 18, 4, _c("6a4428"))
			for yy in range(h - 52, h - 30):
				for xx in range(14, 30):
					if Vector2(xx - 22, (yy - (h - 41)) * 0.8).length() < 7.5:
						_px(xx, yy, _c("d8b860") if (xx + yy) % 3 else _c("b89840"))
			_rect(19, h - 56, 6, 6, _c("d8b860"))
			for yy in range(h - 46, h - 22):
				for xx in range(w - 30, w - 6):
					var d := Vector2(xx - (w - 18), yy - (h - 34)).length()
					if d < 11.0:
						_px(xx, yy, _c("d83a2a") if int(d) % 4 < 2 else _c("f0e8d0"))
			_rect(w - 19, h - 22, 2, 22, _c("6a4428"))
		"cercle":
			# Bivouac : une tente, des rondins autour du feu (le feu est animé par la place).
			for yy in range(10, h - 6):
				var half := int(float(yy - 10) * 0.75)
				for xx in range(22 - half, 22 + half):
					_px(xx, yy, _c("8a7a5a") if (xx + yy) % 6 else _c("6a5a40"))
			_rect(20, h - 22, 4, 16, _c("2a2018"))
			_rect(w / 2 - 18, h - 6, 12, 5, _c("5a3a22"))
			_rect(w / 2 + 6, h - 6, 12, 5, _c("5a3a22"))
			_rect(w / 2 - 6, h - 4, 12, 4, _c("3a2414"))
			for k in range(3):
				_rect(w - 20 + k * 3, h - 18 + k * 4, 2, 18 - k * 4, _c("7a5230"))
		"meditation":
			# Tour blanche à coupole, soleil d'or.
			_wall(10, 30, w - 20, h - 30, _c("e8e4f0"), false)
			for i in range(20):
				var half2 := int(sqrt(maxf(0.0, 1.0 - pow(float(20 - i) / 20.0, 2.0))) * float(w - 20) * 0.5)
				_rect(w / 2 - half2, 10 + i, half2 * 2, 1, _c("d8c08a") if i < 18 else _c("c89a3a"))
			_rect(w / 2 - 1, 2, 2, 8, _c("f2c46b"))
			for k in range(8):
				var a := float(k) / 8.0 * TAU
				_px(w / 2 + int(cos(a) * 6.0), 48 + int(sin(a) * 6.0), _c("f2c46b"))
			for yy in range(44, 53):
				for xx in range(w / 2 - 4, w / 2 + 5):
					if Vector2(xx - w / 2, yy - 48).length() < 3.6:
						_px(xx, yy, _c("fff0b0"))
			_window(w / 2 - 4, 62, 8, 12, lit, _c("c89a3a"), true)
			_door(w / 2 - 7, h - 22, 14, 22, _c("c8a070"))
		"tour":
			# La Tour des Échos : flèche violette, fenêtres lumineuses, couronne d'échos.
			_wall(8, 20, w - 16, h - 20, _c("3a2a5a"), true)
			for i in range(22):
				var half3 := int(float(i) * float(w - 12) * 0.5 / 22.0)
				_rect(w / 2 - half3, i, half3 * 2, 1, _c("5a3a8a"))
			for k in range(5):
				_window(w / 2 - 3, 34 + k * 16, 6, 8, true, _c("2a1a4a"), true)
			_door(w / 2 - 7, h - 22, 14, 22, _c("2a1a4a"), _c("b07cff"))
	# Le soir et la nuit, tout s'assombrit (les fenêtres allumées gardent leur éclat).
	if dim > 0.0:
		for yy in range(h):
			for xx in range(w):
				var c := _img.get_pixel(xx, yy)
				if c.a > 0.0 and not (c.r > 0.9 and c.g > 0.6 and c.b < 0.6) and not (c.b > 0.8 and c.r > 0.6):
					_img.set_pixel(xx, yy, c.lerp(Color("0a0c20"), dim))
	return _img
