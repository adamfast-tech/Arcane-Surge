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
	"check": "<path d=\"M4 12.5l5 5L20 6.5\"/>",
	"up": "<path d=\"M12 20V5M5 12l7-7 7 7\"/>",
	"wrench": "<path d=\"M14.7 6.3a4 4 0 0 0-5.4 5.4L3 18l3 3 6.3-6.3a4 4 0 0 0 5.4-5.4l-2.6 2.6-2.4-.6-.6-2.4z\"/>",
	"swords": "<path d=\"M4 3.5L15.5 15M13 17.5l4.5-4.5M15.5 15l4 4.5\"/><path d=\"M20 3.5L8.5 15M11 17.5L6.5 13M8.5 15l-4 4.5\"/>",
	"skull": "<path d=\"M12 3c-4.4 0-8 3.2-8 7.5 0 2.6 1.3 4.4 3 5.5V20h10v-4c1.7-1.1 3-2.9 3-5.5C20 6.2 16.4 3 12 3z\"/><circle cx=\"9\" cy=\"11\" r=\"1.8\"/><circle cx=\"15\" cy=\"11\" r=\"1.8\"/><path d=\"M12 13.8l-1 2h2zM10 20v-2M14 20v-2\"/>",
	"horns": "<path d=\"M6 14a6 6 0 0 1 12 0v3H6z\"/><path d=\"M6.5 11.5C4 10.5 3 8 3.4 5c1.4 1.9 2.9 2.9 4.6 3.3M17.5 11.5C20 10.5 21 8 20.6 5c-1.4 1.9-2.9 2.9-4.6 3.3\"/><path d=\"M12 14v3M8.5 20.5h7M9 17v3.5M15 17v3.5\"/>",
	"flag": "<path d=\"M5 21V3.5\"/><path d=\"M5 4.5h12l-2.5 4 2.5 4H5\"/>",
	"tower": "<path d=\"M6 21V9.5h12V21z\"/><path d=\"M5 9.5V5h2.6v2h2.6V5h3.6v2h2.6V5H19v4.5\"/><path d=\"M10 21v-3.5a2 2 0 0 1 4 0V21\"/>",
	"sound": "<path d=\"M4 9h4l5-4v14l-5-4H4z\"/><path d=\"M16 9a4 4 0 0 1 0 6M18.5 6.5a7.5 7.5 0 0 1 0 11\"/>",
	"star_fill": "<path fill=\"#ffffff\" d=\"M12 3l2.6 5.6 6 .7-4.5 4 1.3 6-5.4-3.2-5.4 3.2 1.3-6-4.5-4 6-.7z\"/>",
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
	"enclume_coeur": "<path d=\"M3 7h14c0 2.2 1.6 3.8 4 4-2.2 1.2-4.6 1.6-7 1.6L13 16H9l-1-3.4C5 12.6 3 10 3 7z\"/><path d=\"M6 20h10M9 16v4M13 16v4\"/><path d=\"M10 6.5c-.9-1.2-2.8-.6-2.6.9.2 1.2 2.6 2.6 2.6 2.6s2.4-1.4 2.6-2.6c.2-1.5-1.7-2.1-2.6-.9z\"/>",
	"couronne_enigme": "<path d=\"M4 18h16l1-10-5 4-4-7-4 7-5-4z\"/><path d=\"M4 21h16\"/><path d=\"M12 12.5l1.6 1.6L12 15.7l-1.6-1.6z\"/>",
	"croc_gharok": "<path d=\"M9 3h6l-1 3h-4z\"/><path d=\"M10 6c-2 4-2 9 2 15 4-6 4-11 2-15\"/><path d=\"M12 9l-1.5 3h3L12 16\"/>",
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
	"etincelle": "<path d=\"M12 4v4M12 16v4M4 12h4M16 12h4M7 7l2 2M15 15l2 2M17 7l-2 2M9 15l-2 2\"/><circle cx=\"12\" cy=\"12\" r=\"1.5\"/>",
	"mur_flammes": "<path d=\"M3 21h18M3 17h18M7 17v4M12 17v4M17 17v4\"/><path d=\"M5 17c-1-2 0-3.5 1-5 .5 1 1 1.5 1.5 2 .5-2.5 1.5-4 2-6 1 1.5 2 3 2 5 .5-.7 1-1.5 1-2.5 1.5 1.5 2 3.5 1.5 5.5 1-1 1.5-2 1.5-3 1.5 1.5 1.5 3 1.5 4\"/>",
	"comete": "<circle cx=\"16\" cy=\"8\" r=\"3.5\"/><path d=\"M13.5 10.5L4 20M12 8L5 15M16 12l-7 7\"/>",
	"pluie_meteores": "<circle cx=\"8\" cy=\"16\" r=\"2.5\"/><circle cx=\"17\" cy=\"11\" r=\"2\"/><circle cx=\"14\" cy=\"19\" r=\"1.5\"/><path d=\"M6.5 14L3 10M15.5 9.5L13 6M13 17.5L11 15\"/>",
	"soleil_noir": "<circle cx=\"12\" cy=\"12\" r=\"4.5\"/><circle cx=\"12\" cy=\"12\" r=\"2\" /><path d=\"M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M18.7 5.3l-2.1 2.1M7.4 16.6l-2.1 2.1\"/>",
	"eclat_givre": "<path d=\"M12 3l3 6-3 12-3-12z\"/><path d=\"M9 9h6\"/>",
	"lance_glace": "<path d=\"M12 2l2.5 5h-5zM12 7v15\"/><path d=\"M9 12l3 2 3-2M9 16l3 2 3-2\"/>",
	"blizzard": "<path d=\"M3 8h12a3 3 0 1 0-3-3M3 12h16a3 3 0 1 1-3 3M3 16h8\"/><path d=\"M18 19l1 1M20 18l1-1\"/>",
	"hiver_eternel": "<path d=\"M2 20l7-12 4 6 3-4 6 10z\"/><path d=\"M6.5 12.5L9 13l1.5-1M14.5 13.5L16 14l1.5-.5\"/><path d=\"M19 3v4M17 5h4\"/>",
	"tombeau_glace": "<path d=\"M6 21V9l6-6 6 6v12z\"/><path d=\"M9 21v-6h6v6M12 7v4M10 9h4\"/>",
	"decharge": "<path d=\"M13 3L8 12h4l-1 9 5-10h-4z\"/>",
	"orage": "<path d=\"M7 11h10a3.5 3.5 0 0 0 .3-7 5 5 0 0 0-9.6 1A3 3 0 0 0 7 11z\"/><path d=\"M11 13l-2 4h3l-1.5 4M16 13l-1 2\"/>",
	"tempete": "<path d=\"M5 9h11a3 3 0 1 0-3-3M3 13h15a3 3 0 1 1-3 3\"/><path d=\"M8 16l-1.5 3h2.5l-1 3\"/>",
	"jugement_celeste": "<path d=\"M12 2v4M8 4l1.5 2.5M16 4l-1.5 2.5\"/><path d=\"M13 8l-4 7h3l-1 7 5-9h-3l1-5z\"/>",
	"colere_ciel": "<path d=\"M3 7h18\"/><path d=\"M6 7l-2 6h3l-1.5 6M13 7l-2 5h3l-1.5 5M19 7l-1.5 4h2.5l-1 4\"/>",
	"ronces": "<path d=\"M3 19c4-1 6-4 8-8s5-6 10-7\"/><path d=\"M7 16l-1-3M11 11l2 1M15 7l-1-2.5M9 14l2.5 1\"/>",
	"epines": "<path d=\"M3 20h18\"/><path d=\"M5 20l2-8 2 8M10 20l2-12 2 12M15 20l2-8 2 8\"/>",
	"etreinte_foret": "<path d=\"M12 21V11\"/><path d=\"M12 11c-4 0-7-2.5-7-6 3 0 7 2 7 6zM12 11c4 0 7-2.5 7-6-3 0-7 2-7 6z\"/><path d=\"M6 21c2-3 4-4 6-4s4 1 6 4\"/>",
	"seve_vitale": "<path d=\"M12 3c3 4 6 7.5 6 11a6 6 0 0 1-12 0c0-3.5 3-7 6-11z\"/><path d=\"M12 11v6M9 14h6\"/>",
	"floraison_putride": "<circle cx=\"12\" cy=\"10\" r=\"2\"/><path d=\"M12 8c0-3 3-4 3-4s1 3-1 5M14 10c3 0 4 3 4 3s-3 1-5-1M12 12c0 3-3 4-3 4s-1-3 1-5M10 10c-3 0-4-3-4-3s3-1 5 1\"/><path d=\"M12 14v7M8 21h8\"/>",
	"trait_ombre": "<path d=\"M5 19L19 5\"/><path d=\"M14 5h5v5\"/><path d=\"M7 13l-2 2M11 17l-2 2\"/>",
	"brume_funeste": "<path d=\"M3 9c3-2 6 2 9 0s6-2 9 0M3 14c3-2 6 2 9 0s6-2 9 0M5 19c2-1.5 5 1.5 7 0s5-1.5 7 0\"/>",
	"maree_ombre": "<path d=\"M2 15c3 0 4-5 8-5 3 0 4 3 3 5-1 1.5-3 1-3-.5\"/><path d=\"M2 19c4 0 6-1 10-1s6 1 10 1\"/>",
	"puits_neant": "<circle cx=\"12\" cy=\"12\" r=\"9\"/><circle cx=\"12\" cy=\"12\" r=\"5\"/><circle cx=\"12\" cy=\"12\" r=\"1.5\"/>",
	"eclipse": "<circle cx=\"12\" cy=\"12\" r=\"8\"/><path d=\"M15 5a7 7 0 0 1 0 14 8 8 0 0 0 0-14z\"/>",
	"moisson_ames": "<path d=\"M4 21L14 11\"/><path d=\"M14 11c0-5 3-8 7-8-1 5-3 8-7 8z\"/><path d=\"M6 8c1-2 3-2 3 0s-2 2-3 3\"/>",
	"projectile_arcanique": "<circle cx=\"15\" cy=\"9\" r=\"3\"/><path d=\"M12.5 11.5L5 19M10 9H5M15 14v5\"/>",
	"rayon_arcanique": "<path d=\"M12 2v20\"/><path d=\"M9 4v16M15 4v16\" stroke-dasharray=\"2 2\"/><circle cx=\"12\" cy=\"12\" r=\"2\"/>",
	"distorsion": "<circle cx=\"12\" cy=\"13\" r=\"7\"/><path d=\"M12 9v4l3 2M9 3h6M12 3v3\"/>",
	"nova_arcanique": "<path d=\"M12 3l2 7 7 2-7 2-2 7-2-7-7-2 7-2z\"/>",
	"dechirure": "<path d=\"M12 2l-2 6 3 2-3 4 2 3-2 5\"/><path d=\"M7 5c-3 4-3 10 0 14M17 5c3 4 3 10 0 14\"/>",
	"jet_pierres": "<circle cx=\"8\" cy=\"15\" r=\"3\"/><circle cx=\"16\" cy=\"9\" r=\"2.5\"/><circle cx=\"17\" cy=\"17\" r=\"2\"/><path d=\"M4 8l3 2M10 4l1 3\"/>",
	"pic_rocheux": "<path d=\"M3 20h18\"/><path d=\"M5 20l3-9 2 4 2-11 2 9 2-5 3 12\"/>",
	"mur_pierre": "<path d=\"M3 20h18M3 8h18M3 12h18M3 16h18M3 8v12M21 8v12M8 8v4M15 8v4M11 12v4M18 12v4M6 16v4M14 16v4\"/>",
	"eboulement": "<path d=\"M3 20h18\"/><path d=\"M3 20L9 8l3 4 3-6 6 14\"/><circle cx=\"17\" cy=\"5\" r=\"1.5\"/><circle cx=\"20\" cy=\"9\" r=\"1\"/>",
	"seisme": "<path d=\"M2 12h3l2-5 3 10 3-12 3 9 2-4h4\"/>",
	"faille_tellurique": "<path d=\"M3 20h7l1-3 2 2 1-4 1 2 1-3 1 6h4\"/><path d=\"M12 4l-1 4 2 2-1 3\"/>",
	"cataclysme": "<circle cx=\"12\" cy=\"12\" r=\"9\"/><path d=\"M12 3l-1 5 3 2-2 4 2 2-1 5M3 12l5-1 2 2M21 12l-5 1-2-2\"/>",
	"terre_brulee": "<path d=\"M3 20h18\"/><path d=\"M6 20c-1-2 0-3 1-4 0 1 1 1.5 1.5 2 0-2 1-3 1.5-4.5 1 1.5 2 3 2 4.5 1-1 1-2 1-3 1.5 1.5 2 3 1.5 5\"/><path d=\"M4 17h2M18 17h2\"/>",
	"banquise": "<path d=\"M3 16h18\"/><path d=\"M3 16l3-5h12l3 5M8 11l1-3h6l1 3\"/><path d=\"M6 20h4M14 20h4\"/>",
	"champ_statique": "<path d=\"M3 18h18\"/><path d=\"M6 18l2-4 2 2 2-5 2 3 2-2 2 6\"/><path d=\"M12 3v3M9 5l1 2M15 5l-1 2\"/>",
	"marais": "<path d=\"M3 15c2-1.5 4 1.5 6 0s4-1.5 6 0 4 1.5 6 0M3 19c2-1.5 4 1.5 6 0s4-1.5 6 0 4 1.5 6 0\"/><path d=\"M8 12V6M8 6c-1 0-2-1-2-2M16 12V8\"/>",
	"miasme": "<path d=\"M5 18c-2 0-3-2-2-3.5S6 13 6 13c0-3 3-5 6-4 1-2 4-2 5 0 3 0 4 3 3 5 1 2 0 4-2 4z\"/><circle cx=\"10\" cy=\"14\" r=\".8\"/><circle cx=\"14\" cy=\"14\" r=\".8\"/>",
	"rune_piege": "<circle cx=\"12\" cy=\"12\" r=\"8\"/><path d=\"M12 6l4 9H8z\"/><path d=\"M12 10v3\"/>",
	"linceul": "<path d=\"M5 20c0-8 3-15 7-16 4 1 7 8 7 16-2-1-3-1-4 0-1-1-2-1-3 0-1-1-2-1-3 0-1-1-3-1-4 0z\"/><circle cx=\"10\" cy=\"10\" r=\".8\"/><circle cx=\"14\" cy=\"10\" r=\".8\"/>",
	"ossements": "<path d=\"M6 6l12 12M8.5 4.5a2 2 0 1 0-2 2M15.5 19.5a2 2 0 1 0 2-2M4.5 8.5a2 2 0 1 0 2-2M19.5 15.5a2 2 0 1 0-2 2\"/>",
	"hache_tournoyante": "<path d=\"M6 18L16 8\"/><path d=\"M13 5c3-1 6 0 7 2-1 3-3 4-6 4z\"/><path d=\"M4 9a8 8 0 0 1 4-5M20 15a8 8 0 0 1-4 5\"/>",
	"bond_furieux": "<path d=\"M4 20c3-8 7-12 13-14\"/><path d=\"M13 5h5v5\"/><path d=\"M6 13l-2-2M9 9L8 6\"/>",
	"bouclier_leve": "<path d=\"M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z\"/>",
	"tir_precision": "<path d=\"M4 20L18 6\"/><path d=\"M14 5h5v5\"/><path d=\"M4 20l1-4 3 3z\"/>",
	# Classes (étape 13.3)
	"constellation": "<circle cx=\"6\" cy=\"7\" r=\"1.4\"/><circle cx=\"13\" cy=\"4\" r=\"1.4\"/><circle cx=\"18\" cy=\"10\" r=\"1.4\"/><circle cx=\"10\" cy=\"14\" r=\"1.4\"/><circle cx=\"16\" cy=\"19\" r=\"1.4\"/><path d=\"M7.2 6.5l4.6-2M14.2 5l2.8 4M16.9 11l-5.6 2.4M11 15.2l4 2.8\"/>",
	"lames_miroirs": "<path d=\"M3 20L12 11M21 20l-9-9\"/><path d=\"M10 9l2-6 2 6\"/><path d=\"M12 11v10\" stroke-dasharray=\"2 2\"/><path d=\"M5 15l2 2M19 15l-2 2\"/>",
	"exorcisme": "<path d=\"M12 3v18M7 8h10\"/><circle cx=\"12\" cy=\"8\" r=\"7\"/><path d=\"M4 18l3-2M20 18l-3-2\"/>",
	"sacrifice_ames": "<path d=\"M4 20C8 8 14 4 20 4c-2 3-6 4-9 5\"/><path d=\"M4 20l3-3\"/><circle cx=\"15\" cy=\"15\" r=\"2\"/><circle cx=\"19\" cy=\"19\" r=\"1.2\"/><circle cx=\"11\" cy=\"19\" r=\"1.2\"/>",
	"cercle_runique": "<circle cx=\"12\" cy=\"12\" r=\"9\"/><circle cx=\"12\" cy=\"12\" r=\"5\"/><path d=\"M12 3v4M12 17v4M3 12h4M17 12h4\"/><path d=\"M11 11l2 2M13 11l-2 2\"/>",
	"rage_primordiale": "<path d=\"M5 20c0-6 3-9 7-9s7 3 7 9\"/><path d=\"M9 11L7 4l4 4 1-5 1 5 4-4-2 7\"/><path d=\"M9 16h.01M15 16h.01\"/>",
	"fente": "<path d=\"M4 20L17 7\"/><path d=\"M15 4l5 5\"/><path d=\"M4 20l2.5-1L5 17.5z\"/><path d=\"M19 15l2 2M17 18l1.5 1.5\"/>",
	"tranche_orage": "<path d=\"M5 19L16 8\"/><path d=\"M14 6l4 4\"/><path d=\"M13 3l-2 4h3l-2 4\"/><path d=\"M20 12l-2 3h2.5l-2 3\"/>",
	"priere": "<path d=\"M12 21V11\"/><path d=\"M8 13c0-4 2-7 4-9 2 2 4 5 4 9\"/><path d=\"M5 21h14\"/><path d=\"M4 9l2 1M20 9l-2 1M12 1v1\"/>",
	"horde": "<circle cx=\"7\" cy=\"9\" r=\"2.6\"/><circle cx=\"17\" cy=\"9\" r=\"2.6\"/><circle cx=\"12\" cy=\"6\" r=\"2.6\"/><path d=\"M4 20c0-3 1.4-5 3-5s3 2 3 5M14 20c0-3 1.4-5 3-5s3 2 3 5M9 17c0-2.4 1.4-4 3-4s3 1.6 3 4\"/>",
	"malediction_masse": "<circle cx=\"12\" cy=\"12\" r=\"8\"/><path d=\"M8.5 10.5l2 1.5-2 1.5M15.5 10.5l-2 1.5 2 1.5\"/><path d=\"M12 4v2M12 18v2M4 12h2M18 12h2\"/>",
	"hurlement": "<path d=\"M6 9v6l5 4V5z\"/><path d=\"M14 9c1 1 1 5 0 6M17 7c2.4 2.4 2.4 7.6 0 10M20 5c3.4 3.4 3.4 10.6 0 14\"/>",
	"lance_solaire": "<path d=\"M12 22V6\"/><path d=\"M9 9l3-7 3 7\"/><circle cx=\"12\" cy=\"14\" r=\"3\"/><path d=\"M6 14H4M20 14h-2M7.8 9.8l-1.4-1.4M16.2 9.8l1.4-1.4\"/>",
	"pluie_etoiles": "<path d=\"M8 3l1 2.4 2.4 1-2.4 1L8 9.8 7 7.4 4.6 6.4 7 5.4z\"/><path d=\"M17 8l.8 1.8 1.8.8-1.8.8-.8 1.8-.8-1.8-1.8-.8 1.8-.8z\"/><path d=\"M10 21l4-8M15 21l3-6M5 20l3-6\"/>",
	"mille_lames": "<path d=\"M4 20L14 10M8 20l9-9M12 20l8-8\"/><path d=\"M12 8l2 2M15 9l2 2M18 10l2 2\"/><path d=\"M3 4l5 5\"/>",
	"jugement_solaire": "<circle cx=\"12\" cy=\"9\" r=\"4\"/><path d=\"M12 1v2M12 15v2M4 9H2M22 9h-2M6.3 3.3l1.4 1.4M16.3 13.3l1.4 1.4M17.7 3.3l-1.4 1.4M7.7 13.3l-1.4 1.4\"/><path d=\"M5 22c2-2 4-3 7-3s5 1 7 3\"/>",
	"armee_des_morts": "<path d=\"M8 10a4 4 0 1 1 8 0v3h-8z\"/><circle cx=\"10.3\" cy=\"9.5\" r=\".9\"/><circle cx=\"13.7\" cy=\"9.5\" r=\".9\"/><path d=\"M10 13v2M12 13v2M14 13v2\"/><path d=\"M3 21l3-4M21 21l-3-4M12 21v-3\"/>",
	"rempart_sacre": "<path d=\"M12 3l7 3v5c0 5-3 8.5-7 10-4-1.5-7-5-7-10V6z\"/><path d=\"M12 7v9M8.5 10.5h7\"/>",
	"dechainement": "<path d=\"M12 3c2 3 5 4 5 9a5 5 0 0 1-10 0c0-3 1.5-4 2-6 1 1 1.5 2 1.5 3 1-2 1.5-4 1.5-6z\"/><path d=\"M3 9l2 1M21 9l-2 1M4 16l2-.5M20 16l-2-.5\"/>",
}

## Emplacement d'équipement → icône (silhouette des emplacements vides).
const SLOT_ICON := {
	"weapon": "baton_chene", "offhand": "orbe_luciole", "head": "capuche_toile", "armor": "robe_apprenti",
	"hands": "gants_cuir", "feet": "bottes_marche", "amulet": "amulette_mousse", "ring1": "anneau_cuivre",
	"ring2": "anneau_cuivre", "ring": "anneau_cuivre", "charm": "charme_luciole",
}

static var _cache: Dictionary = {}


static func has(name: String) -> bool:
	return SHAPES.has(name) or _svg_of(name) != ""


## Icône d'une technique de grimoire de classe : son tracé est dans data/spells.json (« svg »).
static func _svg_of(name: String) -> String:
	return str((GameData.spells().get(name, {}) as Dictionary).get("svg", ""))


## Icône blanche de « px » pixels de côté (à teinter). Trait plus épais pour les petites tailles.
## Vrai si l'icône de cet objet est déjà en couleurs (ne pas la teinter à la couleur de la rareté).
static func item_colored(base_id: String) -> bool:
	return ((Profile.items_db()["bases"] as Dictionary).get(base_id, {}) as Dictionary).has("art")


static func tex(name: String, px: int = 48, stroke: float = 1.5) -> Texture2D:
	var key := "%s|%d|%.2f" % [name, px, stroke]
	if _cache.has(key):
		return _cache[key]
	var body := str(SHAPES.get(name, ""))
	if body == "":
		body = _svg_of(name)
	if body == "":
		body = str(SHAPES["rune"])
	var svg := (HEAD % str(stroke)) + body + "</svg>"
	var img := Image.new()
	if img.load_svg_from_string(svg, float(px) / 24.0) != OK:
		push_warning("Icons : icône illisible %s" % name)
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Icône d'un objet (par sa base) ou, à défaut, de son emplacement.
## Icône d'un objet : pixel-art en couleurs (ItemArt) si la base a un visuel, sinon icône au trait.
static func item(base_id: String, slot: String, px: int = 48) -> Texture2D:
	var art := ItemArt.item(base_id, px)
	if art != null:
		return art
	if SHAPES.has(base_id):
		return tex(base_id, px)
	return tex(str(SLOT_ICON.get(slot, "rune")), px)
