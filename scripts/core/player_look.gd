class_name PlayerLook
extends RefCounted
## Apparence du héros (création de personnage, Miroir de Havre-Aube) : utilisée par le portrait
## (PortraitArt « porteur ») et par le sprite de combat (SpriteAtlas « player »).
## Rangée dans Profile.data["player"]["look"].

const HEADS := {"capuche": "Capuche", "courts": "Cheveux courts", "longs": "Cheveux longs", "tresse": "Tresse"}
const FACES := ["Doux", "Anguleux", "Balafré"]
const SILHOUETTES := ["Robe longue", "Cape et tunique"]
const EYES := {"cyan": "4fe3d2", "ambre": "f2b040", "vert": "6fd06a", "violet": "b07cff", "rouge": "e84a4a", "argent": "d8dce8"}
const HAIR := {"noir": "2a2430", "brun": "5a3a22", "chatain": "8a5a32", "roux": "c0602a", "blond": "e0c070", "blanc": "e8e8f0", "bleu": "4a6ab8", "rose": "d87ab0"}
## Tenue : ombre, foncé, principal, clair.
const OUTFITS := {
	"nuit": ["14204a", "1d2f5a", "2f4f8f", "4a6ab8"],
	"cramoisi": ["3a1014", "6a1a22", "a02a34", "c84a50"],
	"emeraude": ["0e2a1e", "1a4a32", "2a7a4e", "4aa06a"],
	"violet": ["1e1430", "3a2a5a", "5a3a8a", "8a62c0"],
	"cendre": ["2a2a30", "4a4a52", "6a6a74", "8e8e98"],
	"ocre": ["3a2410", "6a4220", "a06a30", "c89048"],
	"blanc": ["8a8a9a", "b8b8c8", "dcdce8", "f6f6fc"],
	"noir": ["0a0a10", "16161e", "26262e", "3a3a46"],
}
const DEFAULT := {"sil": 0, "face": 0, "head": "capuche", "skin": 1, "hair": "blanc", "eyes": "cyan", "outfit": "nuit"}


## Apparence complète (valeurs par défaut pour les clés absentes).
static func of(d: Dictionary) -> Dictionary:
	var out := DEFAULT.duplicate()
	for k in d.keys():
		out[k] = d[k]
	return out


static func race_info(race: String) -> Dictionary:
	return (GameData.party()["races"] as Dictionary).get(race, {})


## Couleurs résolues pour le dessin : peau (ombre, base, clair), cheveux, yeux, tenue (4 tons), trait de race.
static func palette(look: Dictionary, race: String) -> Dictionary:
	var lk := of(look)
	var ri := race_info(race)
	var skins: Array = ri.get("skins", ["e0ae8e"])
	var skin := Color(str(skins[clampi(int(lk["skin"]), 0, skins.size() - 1)]))
	var hair := Color(str(HAIR.get(str(lk["hair"]), "e8e8f0")))
	var out: Array = OUTFITS.get(str(lk["outfit"]), OUTFITS["nuit"])
	return {
		"skin": [skin.darkened(0.3), skin, skin.lightened(0.18)],
		"hair": [hair.darkened(0.35), hair, hair.lightened(0.2)],
		"eyes": Color(str(EYES.get(str(lk["eyes"]), "4fe3d2"))),
		"outfit": [Color(str(out[0])), Color(str(out[1])), Color(str(out[2])), Color(str(out[3]))],
		"trait": str(ri.get("trait", "none")),
		"head": str(lk["head"]),
		"face": int(lk["face"]),
		"sil": int(lk["sil"]),
		"height": float(ri.get("height", 1.5)),
	}


## Empreinte de l'apparence (caches des textures).
static func key(look: Dictionary, race: String) -> String:
	return "%s|%s" % [race, JSON.stringify(of(look))]
