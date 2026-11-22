class_name Unit
extends RefCounted
## Une unité de l'arène (invocation alliée ou ennemi). Données pures, pas de nœud.

var id := 0
var team := 0 ## 0 = allié, 1 = ennemi
var kind := ""
var role := ""
var sprite := ""
var owner_idx := -1 ## lanceur d'origine (alliés)
var pos := Vector2.ZERO
var prev_pos := Vector2.ZERO
var vx := 0.0
var speed := 2.0
var hp := 10.0
var max_hp := 10.0
var atk := 10.0
var defense := 0.0
var radius := 0.22
var weight := 1.0
var element := "physique"
var atk_interval := 0.5
var atk_cd := 0.0
var attack_range := 0.0
var crit := 0.05
var front_block := 0.0
var cast_interval := 0.0
var cast_cd := 0.0
var hold_y := -1.0
var siege := false
var elite := false
var alive := true
var engaged := false
var crossed: Dictionary = {}
var last_elem := ""

# Statuts
var burn_t := 0.0
var burn_dps := 0.0
var slow_stacks := 0
var slow_t := 0.0
var frozen_t := 0.0
var poison_stacks := 0
var poison_t := 0.0
var poison_unit := 0.0
var rooted_t := 0.0
var wither_t := 0.0
var shield := 0.0
var enraged_t := 0.0 ## cri de guerre (Gharok, Varg) : +30 % de dégâts
var zone_slow := 0.0 ## ralentissement des zones de sorts (Racines), recalculé à chaque pas

# Rendu
var flash_t := 0.0
var anim := 0.0


func speed_factor() -> float:
	if frozen_t > 0.0 or rooted_t > 0.0:
		return 0.0
	return maxf(0.25, 1.0 - 0.15 * float(slow_stacks)) * (1.0 - zone_slow)
