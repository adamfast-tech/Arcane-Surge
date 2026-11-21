class_name Portal
extends RefCounted
## Portail runique traversé par les invocations alliées.
## Positifs : add (+N, se recharge 1,5 s), mult (×N), elem, power, giant, haste, aegis.
## Négatifs : sub (-N : absorbe N unités puis se recharge 4 s), div (÷N), corrupt, entrave.

const ELEM_LABEL := {
	"feu": "FEU", "givre": "GIVRE", "foudre": "FOUDRE", "nature": "NATURE",
	"lumiere": "LUMIÈRE", "ombre": "OMBRE", "physique": "PHYS.",
}
const ADD_RECHARGE := 1.5
const SUB_RECHARGE := 4.0

var id := 0
var kind := "add"
var value := 0
var element := ""
var x := 4.5
var base_x := 4.5
var y := 5.0
var width := 2.0
var motion := "none"
var motion_range := 0.0
var motion_speed := 0.5
var phase := 0.0
var is_seal := false
var purified := false
var purity := 0
var purity_needed := 10
var charges := 0
var ready := true
var recharge_t := 0.0
var counter := 0
var flash_t := 0.0


func is_negative() -> bool:
	return kind == "sub" or kind == "div" or kind == "corrupt" or kind == "entrave"


func label() -> String:
	match kind:
		"add":
			return "+%d" % value
		"mult":
			return "×%d" % value
		"sub":
			return "-%d" % value
		"div":
			return "÷%d" % value
		"elem":
			return str(ELEM_LABEL.get(element, element.to_upper()))
		"power":
			return "PUISSANCE"
		"giant":
			return "GÉANT"
		"haste":
			return "HÂTE"
		"aegis":
			return "ÉGIDE"
		"corrupt":
			return "CORRUPTION"
		"entrave":
			return "ENTRAVE"
	return "?"


func color() -> Color:
	match kind:
		"add", "mult":
			return Color("4fe3d2")
		"elem":
			return Color(str(SpriteAtlas.ELEM.get(element, ["", "", "ffffff", ""])[2]))
		"power", "giant", "haste", "aegis":
			return Color("f2c46b")
	return Color("d93cf2")


## Retourne true si le portail était négatif et vient d'être purifié.
func purify() -> bool:
	if not is_negative():
		return false
	match kind:
		"sub":
			kind = "add"
			ready = true
		"div":
			kind = "mult"
			value = 2
		"corrupt":
			kind = "elem"
			element = "lumiere"
		"entrave":
			kind = "haste"
	purified = true
	purity = purity_needed
	return true
