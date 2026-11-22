class_name Icons
extends RefCounted
## Icônes au trait fin (concept UI) : dessins SVG 24×24 tracés en blanc, convertis en image à la
## taille voulue au lancement, puis teintés par modulate ou par les couleurs d'icône des boutons.

const HEAD := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"#ffffff\" stroke-width=\"%s\" stroke-linecap=\"round\" stroke-linejoin=\"round\">"

const SHAPES := {
	# Interface
	"rune": "<path d=\"M12 2l6 10-6 10-6-10z\"/><path d=\"M12 7l3 5-3 5-3-5z\"/>",
	"map": "<path d=\"M3 6l6-2 6 2 6-2v14l-6 2-6-2-6 2z\"/><path d=\"M9 4v14M15 6v14\"/>",
	"chevron": "<path d=\"M9 5l7 7-7 7\"/>",
	"back": "<path d=\"M15 5l-7 7 7 7\"/>",
	"lock": "<rect x=\"5\" y=\"11\" width=\"14\" height=\"10\" rx=\"1.5\"/><path d=\"M8 11V8a4 4 0 0 1 8 0v3\"/><path d=\"M12 15v2\"/>",
	"book": "<path d=\"M4 5c3-1.5 5.5-1.5 8 0v15c-2.5-1.5-5-1.5-8 0z\"/><path d=\"M12 5c2.5-1.5 5-1.5 8 0v15c-3-1.5-5.5-1.5-8 0\"/>",
	"target": "<circle cx=\"12\" cy=\"12\" r=\"8\"/><circle cx=\"12\" cy=\"12\" r=\"3.5\"/><path d=\"M12 2v4M12 18v4M2 12h4M18 12h4\"/>",
	"circle": "<circle cx=\"8\" cy=\"8\" r=\"3\"/><circle cx=\"16\" cy=\"8\" r=\"3\"/><path d=\"M3 20c0-3 2.2-5 5-5s5 2 5 5M11 20c0-3 2.2-5 5-5s5 2 5 5\"/>",
	"moon": "<path d=\"M15 3a8 8 0 1 0 6 13A7 7 0 0 1 15 3z\"/><path d=\"M7 4l.8 1.9 1.9.8-1.9.8L7 9.4l-.8-1.9-1.9-.8 1.9-.8z\"/>",
	"coin": "<circle cx=\"12\" cy=\"12\" r=\"8\"/><path d=\"M12 8l3 4-3 4-3-4z\"/>",
	"dust": "<path d=\"M11 3l1.6 5 5 1.6-5 1.6L11 16.2l-1.6-5-5-1.6 5-1.6z\"/><path d=\"M18.5 14.5l.7 1.8 1.8.7-1.8.7-.7 1.8-.7-1.8-1.8-.7 1.8-.7z\"/>",
	"cloud": "<path d=\"M7 18h10a4 4 0 0 0 .5-8 6 6 0 0 0-11.5 1.5A3.5 3.5 0 0 0 7 18z\"/>",
	"logout": "<path d=\"M10 4H5v16h5\"/><path d=\"M14 8l4 4-4 4M18 12H9\"/>",
	"star": "<path d=\"M12 3l2.6 5.6 6 .7-4.5 4 1.3 6-5.4-3.2-5.4 3.2 1.3-6-4.5-4 6-.7z\"/>",
	"pause": "<path d=\"M9 5v14M15 5v14\"/>",
	"play": "<path d=\"M7 4l12 8-12 8z\"/>",
	"forge": "<path d=\"M3 7h14c0 2.2 1.6 3.8 4 4-2.2 1.2-4.6 1.6-7 1.6L13 16H9l-1-3.4C5 12.6 3 10 3 7z\"/><path d=\"M6 20h10M9 16v4M13 16v4\"/>",
	"sparkle": "<path d=\"M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5L18 18M6 18l2.5-2.5M15.5 8.5L18 6\"/>",
	# Objets (un visuel par objet)
	"baton_chene": "<path d=\"M6 21L14.5 8.5\"/><path d=\"M14.5 8.5c-1-2.2 0-4.4 2.2-5.4.9 2 2.8 2.2 4.1 1.2-.4 2.6-3 4.6-6.3 4.2z\"/><path d=\"M9.4 16.2l-1.6-1M11.6 13l1.5.9\"/>",
	"baguette_saule": "<path d=\"M4 20L15 9\"/><path d=\"M15 9l2-2\"/><path d=\"M19 2.5v3.5M17.2 4.2h3.6M15.2 2.8l.9.9M21.2 8.2l-.9-.9\"/>",
	"baton_lune": "<path d=\"M6.5 21L14 10.5\"/><path d=\"M17 3a5 5 0 1 0 3.5 8.2A4.2 4.2 0 0 1 17 3z\"/>",
	"baton_seve": "<path d=\"M6 21L13.5 10\"/><path d=\"M13.5 10c0-3 2-5.2 5.4-6.1 0 3.2-2.1 5.4-5.4 6.1z\"/><path d=\"M13.5 10c-1.8-1.3-4-1.3-5.3.6 2 1.2 4 1.2 5.3-.6z\"/><path d=\"M16.4 7l1.2-1.2\"/>",
	"orbe_luciole": "<circle cx=\"12\" cy=\"10\" r=\"6\"/><path d=\"M8 20h8M10 16l-1 4M14 16l1 4\"/><path d=\"M9.5 9a2.6 2.6 0 0 1 2.5-2.5\"/><circle cx=\"13.5\" cy=\"11.5\" r=\".6\"/>",
	"capuche_toile": "<path d=\"M5 20c0-6.5 2-14 7-15.5 5 1.5 7 9 7 15.5\"/><path d=\"M8.6 20c0-4.2 1.5-8 3.4-8s3.4 3.8 3.4 8\"/><path d=\"M5 20h14\"/>",
	"robe_apprenti": "<path d=\"M9 3l3 2 3-2 4.5 3.5-2.2 3-1.8-1 1 11.5H8.5l1-11.5-1.8 1-2.2-3z\"/><path d=\"M12 5v15M9.5 13h5\"/>",
	"gants_cuir": "<path d=\"M7 21v-6c-1.8-.9-2.8-2.6-1.8-3.6s2 0 2.8 1V6.5a1.7 1.7 0 0 1 3.4 0V5a1.7 1.7 0 0 1 3.4 0v4a1.7 1.7 0 0 1 3.2.8V15c0 3.2-2.2 6-5.2 6z\"/><path d=\"M7 18h11\"/>",
	"bottes_marche": "<path d=\"M7 3h6v10l5 2.5c1.3.7 2 1.8 2 3V21H7z\"/><path d=\"M7 17.5h13M7 7h6\"/>",
	"amulette_mousse": "<path d=\"M6.5 3l5.5 7 5.5-7\"/><circle cx=\"12\" cy=\"15\" r=\"5\"/><circle cx=\"12\" cy=\"15\" r=\"1.8\"/>",
	"anneau_cuivre": "<circle cx=\"12\" cy=\"15\" r=\"6\"/><path d=\"M9.5 6.2L12 2.8l2.5 3.4L12 9z\"/>",
	"charme_luciole": "<path d=\"M10 3h4M10.5 3v4.2L7 13a5 5 0 0 0 4.3 7.5h1.4A5 5 0 0 0 17 13l-3.5-5.8V3\"/><circle cx=\"12\" cy=\"15\" r=\"1.6\"/><path d=\"M8.5 12.5h7\"/>",
	# Sorts et pouvoirs
	"boule_de_feu": "<path d=\"M12 21c-4 0-7-2.8-7-6.5 0-3.5 3-5.5 4-9 2 1.5 3 3.5 3 5.5 1-1 1.5-2.2 1.5-3.5 2.5 2 4.5 4.5 4.5 7.5 0 3.5-2.5 6-6 6z\"/><path d=\"M12 21c-1.8 0-3-1.2-3-2.8 0-1.8 1.5-2.7 2-4.2 1.8 1.2 4 2.4 4 4.4 0 1.5-1.3 2.6-3 2.6z\"/>",
	"pluie_de_givre": "<path d=\"M7 13.5h10a3.5 3.5 0 0 0 .3-7 5 5 0 0 0-9.6 1A3 3 0 0 0 7 13.5z\"/><path d=\"M8 16.5l-1 3.5M12 16.5l-1 3.5M16 16.5l-1 3.5\"/>",
	"racines": "<path d=\"M12 3v9\"/><path d=\"M12 12c-2 2-5 2-7 5M12 12c2 2 5 2 7 5M12 12v9M12 15.5l-3 4M12 15.5l3 4\"/><path d=\"M12 6.5c1.5-2 3.5-2.6 5.2-2.1-1 2.1-3.1 3-5.2 2.1z\"/>",
	"eclair_chaine": "<path d=\"M13 2L5 13h6l-1 9 8-12h-6z\"/>",
	"vortex_ombre": "<path d=\"M12 12c1-1 2.2-.2 2.2 1 0 2-3.2 3-4.4 1.8-2-2-1.4-5.6 1.6-6.4 3.4-.9 6.6 1.6 6.6 5 0 4.4-4 7.4-8.2 6.6-4.4-.8-6.8-5.2-5.6-9.4\"/>",
	"onde_arcanique": "<circle cx=\"12\" cy=\"12\" r=\"2\"/><path d=\"M7.8 7.8a6 6 0 0 0 0 8.4M16.2 7.8a6 6 0 0 1 0 8.4M5 5a10 10 0 0 0 0 14M19 5a10 10 0 0 1 0 14\"/>",
	"purifier": "<circle cx=\"12\" cy=\"12\" r=\"4\"/><path d=\"M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M5 19l2-2M17 7l2-2\"/>",
	"meteore": "<circle cx=\"16\" cy=\"8\" r=\"4\"/><path d=\"M13 11L4 20M12.4 8.2L6 14.6M15.8 11.6L9.4 18\"/>",
	"champion": "<path d=\"M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z\"/><path d=\"M12 8v8M8.5 12h7\"/>",
	"brasier": "<path d=\"M4 21h16\"/><path d=\"M7 21c-2-2-2-5 0-7 0 2 1 3 2 3 0-3 1-6 4-8 0 3 2 4 2 6 1-1 1.5-2 1.5-3 2 2 2.5 5.5.5 9\"/><path d=\"M10.5 21c-1-1-1-2.5 0-3.5.5 1 1.5 1.5 2.5 1.5 0-1 .5-2 1.5-2.5.5 1.5.5 3-.5 4.5\"/>",
	"prison_glace": "<path d=\"M12 2v20M3.3 7l17.4 10M3.3 17L20.7 7\"/><path d=\"M9.5 3.5L12 6l2.5-2.5M9.5 20.5L12 18l2.5 2.5M3 10.5l3.4-.9-.9-3.4M21 13.5l-3.4.9.9 3.4M3 13.5l3.4.9-.9 3.4M21 10.5l-3.4-.9.9-3.4\"/>",
	"bouclier_arcanique": "<path d=\"M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z\"/><path d=\"M12 8l3 4-3 4-3-4z\"/>",
	"javelot_foudre": "<path d=\"M4 20L17 7\"/><path d=\"M17 7l3-4-4 1.5\"/><path d=\"M9 9l2 2-2 1 2 2\"/>",
	"nuee_lucioles": "<circle cx=\"7\" cy=\"8\" r=\"1.6\"/><circle cx=\"16\" cy=\"6\" r=\"1.3\"/><circle cx=\"12\" cy=\"13\" r=\"2\"/><circle cx=\"18\" cy=\"15\" r=\"1.3\"/><circle cx=\"6\" cy=\"17\" r=\"1.3\"/><path d=\"M4 22h16\"/>",
	"charge_bastion": "<path d=\"M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z\"/><path d=\"M12 7v10M9 14l3 3 3-3\"/>",
	"volee_fleches": "<path d=\"M5 19L15 9M8 21l10-10M3 15l10-10\"/><path d=\"M12 5h3v3M15 9h3v3M10 3h3v3\"/>",
	"bouclier_leve": "<path d=\"M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z\"/>",
	"tir_precision": "<path d=\"M4 20L18 6\"/><path d=\"M14 5h5v5\"/><path d=\"M4 20l1-4 3 3z\"/>",
}

## Emplacement d'équipement → icône (silhouette des emplacements vides).
const SLOT_ICON := {
	"weapon": "baton_chene", "offhand": "orbe_luciole", "head": "capuche_toile", "armor": "robe_apprenti",
	"hands": "gants_cuir", "feet": "bottes_marche", "amulet": "amulette_mousse", "ring1": "anneau_cuivre",
	"ring2": "anneau_cuivre", "ring": "anneau_cuivre", "charm": "charme_luciole",
}

static var _cache: Dictionary = {}


static func has(name: String) -> bool:
	return SHAPES.has(name)


## Icône blanche de « px » pixels de côté (à teinter). Trait plus épais pour les petites tailles.
static func tex(name: String, px: int = 48, stroke: float = 1.5) -> Texture2D:
	var key := "%s|%d|%.2f" % [name, px, stroke]
	if _cache.has(key):
		return _cache[key]
	var body := str(SHAPES.get(name, SHAPES["rune"]))
	var svg := (HEAD % str(stroke)) + body + "</svg>"
	var img := Image.new()
	if img.load_svg_from_string(svg, float(px) / 24.0) != OK:
		push_warning("Icons : icône illisible %s" % name)
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Icône d'un objet (par sa base) ou, à défaut, de son emplacement.
static func item(base_id: String, slot: String, px: int = 48) -> Texture2D:
	if SHAPES.has(base_id):
		return tex(base_id, px)
	return tex(str(SLOT_ICON.get(slot, "rune")), px)
