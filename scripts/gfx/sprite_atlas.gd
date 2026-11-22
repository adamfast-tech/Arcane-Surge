class_name SpriteAtlas
extends RefCounted
## Sprites pixel-art (cartes ASCII ombrées, 2 images d'animation) réunis dans un atlas unique.
## Alliés vus de dos (ils avancent vers le Nexus), ennemis vus de face.
## Remplacement : déposer res://assets/sprites/<nom>.png (les images côte à côte) pour
## remplacer le sprite généré du même nom.

const ELEM := {
	"physique": ["2a2f45", "5a6378", "aeb8cc", "e8eefc"],
	"feu": ["3a1206", "8a3a12", "ff8a3a", "ffd08a"],
	"givre": ["0e2a45", "2e6e9a", "7fd0ff", "d8f6ff"],
	"foudre": ["3a3206", "8a7a10", "f0d23c", "fff6a8"],
	"nature": ["0f2a18", "2e5d3a", "6fbf4a", "c8f5a0"],
	"lumiere": ["4a3a10", "b89a3a", "f5e7a0", "fffbe8"],
	"ombre": ["1a1035", "3b2a6b", "8e62e0", "d0b0ff"],
}
## Hauteur en jeu (mètres) : un sprite remplacé, quelle que soit sa résolution, garde cette taille.
const HEIGHT_M := {
	"mage": 1.5, "brann": 1.25, "sylwen": 1.45, "krag": 1.55, "berserker": 0.74, "nyx": 1.05,
	"familiar": 0.64, "knight": 0.75, "archer": 0.75, "skeleton": 0.7, "golem": 1.0, "fusion": 0.66,
	"mushroom": 0.58, "rabbit": 0.62, "bear": 0.9, "pixie": 0.52, "turtle": 0.58, "wisp": 0.7, "dryad": 1.05,
	"cross": 0.29, "px": 1.0,
	"stag": 1.7, "sylvarche": 3.6, "flower": 0.6, "lantern": 1.25, "orb": 0.3,
	"pillard": 0.62, "slinger": 0.6, "wolf_rider": 0.78, "ogre": 1.05, "clan_guard": 0.72, "storm_shaman": 0.85, "bonesetter": 0.8, "varg": 1.45, "gharok": 2.7, "war_banner": 1.6, "storm_totem": 1.2, "caravan": 1.3, "pylon": 1.6,
	"bog_zombie": 0.72, "plague_rat": 0.42, "slime_abomination": 1.0, "spitting_toad": 0.5, "shield_skeleton": 0.74, "renegade_adept": 0.82, "mist_witch": 0.86, "croc_lich": 1.4, "hydra": 2.9, "hydra_head": 1.2, "barge": 1.2,
}
## Sprites dont les lettres o/d/m/l prennent les couleurs de l'élément.
const RECOLOR := ["familiar", "knight", "archer", "golem", "fusion", "berserker"]

const DEFS := {
	"familiar": {"pal": {"w": "ffffff"}, "frames": [[
		"...oooo...",
		"..oddddo..",
		".odmmmmdo.",
		".odmmmmdo.",
		".odmllmdo.",
		"..odmmdo..",
		".oddmmddo.",
		"odmmllmmdo",
		"odmlwwlmdo",
		".odmllmdo.",
		"..odo.odo.",
		"..oo...oo.",
	], [
		"...oooo...",
		"..oddddo..",
		".odmmmmdo.",
		".odmmmmdo.",
		".odmllmdo.",
		"..odmmdo..",
		".oddmmddo.",
		"odmmllmmdo",
		"odmlwwlmdo",
		".odmllmdo.",
		".odo..odo.",
		".oo....oo.",
	]]},
	"knight": {"pal": {"s": "c8d0e0", "S": "7a849c", "k": "3a2e2a", "b": "7a5230", "B": "d8b048"}, "frames": [[
		"...oooo...",
		"..oSssSo..",
		"..oSssSo..",
		"...oSSo...",
		"..oddmdo..",
		".odmmmmdo.",
		"obbdmmmdo.",
		"obBbmmldo.",
		"obbdmmmdo.",
		".oodmmdoo.",
		"..oSo.oSo.",
		"..oko.oko.",
		"..ooo.ooo.",
	], [
		"...oooo...",
		"..oSssSo..",
		"..oSssSo..",
		"...oSSo...",
		"..oddmdo..",
		".odmmmmdo.",
		"obbdmmmdo.",
		"obBbmmldo.",
		"obbdmmmdo.",
		".oodmmdoo.",
		".oSo..oSo.",
		".oko..oko.",
		".ooo..ooo.",
	]]},
	"archer": {"pal": {"G": "2f6a45", "g": "5fbf7a", "y": "9a6a3a", "k": "3a2e2a"}, "frames": [[
		"...ooo....",
		"..oGgGo...",
		".oGgggGo..",
		".oGgggGo.y",
		"..oGGGo.oy",
		".odmmmdooy",
		"odmmlmmdoy",
		"odmmmmmdoy",
		".odmmmdo.y",
		"..odmdo..y",
		"..oo.oo...",
		".oko.oko..",
		".oo...oo..",
	], [
		"...ooo....",
		"..oGgGo...",
		".oGgggGo..",
		".oGgggGo.y",
		"..oGGGo.oy",
		".odmmmdooy",
		"odmmlmmdoy",
		"odmmmmmdoy",
		".odmmmdo.y",
		"..odmdo..y",
		"..oo..oo..",
		".oko..oko.",
		".oo....oo.",
	]]},
	"skeleton": {"pal": {"o": "3a3448", "b": "e8e4d8", "p": "b07cff"}, "frames": [[
		"...oooo...",
		"..obbbbo..",
		"..obbbbo..",
		"...obbo...",
		"..oobboo..",
		".obobbobo.",
		".o.obbo.o.",
		"...obbo...",
		"..oboobo..",
		"..ob..bo..",
		"..ob..bo..",
		"..oo..oo..",
	], [
		"...oooo...",
		"..obbbbo..",
		"..obbbbo..",
		"...obbo...",
		"..oobboo..",
		".obobbobo.",
		".o.obbo.o.",
		"...obbo...",
		"..oboobo..",
		".ob....bo.",
		".ob....bo.",
		".oo....oo.",
	]]},
	"golem": {"pal": {"o": "1a1528", "S": "5a5670", "s": "8a86a0"}, "frames": [[
		".....oooooo.....",
		"....oSssssSo....",
		"....oSsmmsSo....",
		"..oooSssssSooo..",
		".oSSSoSSSSoSSSo.",
		"oSssSSSmmSSSssSo",
		"oSsSSSmllmSSSsSo",
		"oSSoSSSmmSSSoSSo",
		".oo.oSSSSSSo.oo.",
		"...oSSoSSoSSo...",
		"...oSSo..oSSo...",
		"...oSSo..oSSo...",
		"..oSSSo..oSSSo..",
		"..ooooo..ooooo..",
	], [
		".....oooooo.....",
		"....oSssssSo....",
		"....oSsmmsSo....",
		"..oooSssssSooo..",
		".oSSSoSSSSoSSSo.",
		"oSssSSSmmSSSssSo",
		"oSsSSSmllmSSSsSo",
		"oSSoSSSmmSSSoSSo",
		".oo.oSSSSSSo.oo.",
		"...oSSoSSoSSo...",
		"..oSSo....oSSo..",
		"..oSSo....oSSo..",
		".oSSSo....oSSSo.",
		".ooooo....ooooo.",
	]]},
	"fusion": {"pal": {"w": "ffffff"}, "frames": [[
		".....oo.....",
		"....omlo....",
		"...omllmo...",
		"..omlwwlmo..",
		".omlwwwwlmo.",
		"omllwwwwllmo",
		".omlwwwwlmo.",
		"..omlwwlmo..",
		"...omllmo...",
		"..o.omlo.o..",
		".o...oo...o.",
	], [
		".....oo.....",
		"....omlo....",
		"...omllmo...",
		"..omlwwlmo..",
		".omlwwwwlmo.",
		"omllwwwwllmo",
		".omlwwwwlmo.",
		"..omlwwlmo..",
		"...omllmo...",
		".o..omlo..o.",
		"o....oo....o",
	]]},
	"mage": {"pal": {"o": "0e0a1c", "H": "2f4f8f", "h": "1d2f5a", "C": "2f8f9a", "c": "1f5a66", "t": "4fe3d2", "b": "6a4a2a", "s": "8a5a2b", "g": "9ff0ff", "w": "ffffff", "k": "2a2030"}, "frames": [[
		"............g.",
		"...........gwg",
		"....ooo.....g.",
		"...oHHHo....s.",
		"..oHHhhHo...s.",
		"..oHhhhhHo..s.",
		"..ohhhhhho.os.",
		"..ochhhhco.Cs.",
		".ocCchhcCCoCCo",
		".occCCCCCcCo..",
		"occCCtCCCCcco.",
		"occCCtCCCCcco.",
		"ocbbbbbbbbbco.",
		"occCCtCCCCcco.",
		"occCCtCCCCCcco",
		"occCCtCCCCCcco",
		".occCtCCCCCcco",
		".ocCctttttccco",
		"...okko.okko..",
		"...okko.okko..",
		"...oooo.oooo..",
	], [
		"............g.",
		"...........gwg",
		"....ooo.....g.",
		"...oHHHo....s.",
		"..oHHhhHo...s.",
		"..oHhhhhHo..s.",
		"..ohhhhhho.os.",
		"..ochhhhco.Cs.",
		".ocCchhcCCoCCo",
		".occCCCCCcCo..",
		"occCCtCCCCcco.",
		"occCCtCCCCcco.",
		"ocbbbbbbbbbco.",
		"occCCtCCCCcco.",
		"occCCtCCCCCcco",
		"occCCtCCCCCcco",
		"occCCtCCCCCcco",
		".ocCctttttccco",
		"..okko...okko.",
		"..okko...okko.",
		"..oooo...oooo.",
	]]},
	"brann": {"pal": {"o": "120e1a", "s": "c8d0e0", "S": "7a849c", "n": "e8e0c8", "R": "c84a3a", "r": "9a2a2a", "B": "d8b048", "b": "7a5230", "y": "d9773a", "k": "3a2e2a"}, "frames": [[
		"....oooooo....",
		"n..oSssssSo..n",
		"no.oSssssSo.on",
		".nooSSSSSSoon.",
		"..yoSSSSSSoy..",
		".oyRRBBBBRRyo.",
		"oSRRBbbbbBRRSo",
		"oSRBbbBBbbBRSo",
		"oSRBbbBBbbBRSo",
		"oSRRBbbbbBRRSo",
		".oRRRBBBBRRRo.",
		".oRRRRRRRRRRo.",
		".orrRRRRRRrro.",
		"..oSSo..oSSo..",
		"..oSSo..oSSo..",
		"..okko..okko..",
		"..oooo..oooo..",
	], [
		"....oooooo....",
		"n..oSssssSo..n",
		"no.oSssssSo.on",
		".nooSSSSSSoon.",
		"..yoSSSSSSoy..",
		".oyRRBBBBRRyo.",
		"oSRRBbbbbBRRSo",
		"oSRBbbBBbbBRSo",
		"oSRBbbBBbbBRSo",
		"oSRRBbbbbBRRSo",
		".oRRRBBBBRRRo.",
		".oRRRRRRRRRRo.",
		".orrRRRRRRrro.",
		".oSSo....oSSo.",
		".oSSo....oSSo.",
		".okko....okko.",
		".oooo....oooo.",
	]]},
	"sylwen": {"pal": {"o": "0f1a12", "G": "3f7a4a", "g": "2a5a36", "e": "f0d0b0", "h": "e8c870", "H": "b8983a", "l": "8a5a2b", "q": "6a4a2a", "w": "e8e4d8", "c": "2f5a3a", "C": "4a8a5a", "k": "3a2e2a"}, "frames": [[
		"....oooo....",
		"...oGGGGo...",
		"e.oGgggGGo.e",
		"eeoGggggGoee",
		"..oGgggggo..",
		"...ohhhho...",
		".lo.ohhho.w.",
		".loCChhCCqw.",
		"l.oCChhCCqq.",
		"l.ocCChCcqqo",
		"l.occChCccqo",
		".locccHccco.",
		".l.occccco..",
		"..l.occcco..",
		"...okk.kko..",
		"...okk.kko..",
		"...ooo.ooo..",
	], [
		"....oooo....",
		"...oGGGGo...",
		"e.oGgggGGo.e",
		"eeoGggggGoee",
		"..oGgggggo..",
		"...ohhhho...",
		".lo.ohhho.w.",
		".loCChhCCqw.",
		"l.oCChhCCqq.",
		"l.ocCChCcqqo",
		"l.occChCccqo",
		".locccHccco.",
		".l.occccco..",
		"..l.occcco..",
		"..okk...kko.",
		"..okk...kko.",
		"..ooo...ooo.",
	]]},
	"mushroom": {"pal": {"o": "1e0f2a", "P": "9c4dcc", "w": "e7d6f5", "D": "5e2a85", "c": "e8d8b0", "e": "ff3a5a"}, "frames": [[
		"...oooooo...",
		"..oPPwPPPo..",
		".oPwPPPPwPo.",
		"oPPPPPwPPPPo",
		"oDDDDDDDDDDo",
		".oooccccooo.",
		"...oecceo...",
		"...occcco...",
		"...occcco...",
		"...oo..oo...",
	], [
		"............",
		"...oooooo...",
		"..oPPwPPPo..",
		".oPwPPPPwPo.",
		"oPPPPPwPPPPo",
		"oDDDDDDDDDDo",
		".oooccccooo.",
		"...oecceo...",
		"...occcco...",
		"..oo....oo..",
	]]},
	"rabbit": {"pal": {"o": "2a2020", "b": "8a7a68", "e": "ff3a5a", "n": "e88aa0", "t": "c8b8a0"}, "frames": [[
		"..oo....oo..",
		".obo....obo.",
		".obo....obo.",
		".oboooooobo.",
		"obbbbbbbbbbo",
		"obebbbbbbebo",
		"obbbbnnbbbbo",
		".obbbbbbbbo.",
		".otbbbbbbto.",
		"..obbbbbbo..",
		"..oo....oo..",
	], [
		"............",
		"..oo....oo..",
		".obo....obo.",
		".oboooooobo.",
		"obbbbbbbbbbo",
		"obebbbbbbebo",
		"obbbbnnbbbbo",
		".obbbbbbbbo.",
		".otbbbbbbto.",
		"..obbbbbbo..",
		"...oo..oo...",
	]]},
	"bear": {"pal": {"o": "16200f", "M": "3f5a30", "g": "7faa4a", "e": "ff3a5a", "n": "101810", "w": "8a9a70"}, "frames": [[
		"..ooo........ooo..",
		".oMMMo......oMMMo.",
		".oMMMMooooooMMMMo.",
		"oMMgMMMMMMMMMMgMMo",
		"oMMMMeMMMMMMeMMMMo",
		"oMgMMMMMMMMMMMMgMo",
		"oMMMMMMMnnMMMMMMMo",
		".oMMMMMwwwwMMMMMo.",
		"oMMMoMMMMMMMMoMMMo",
		"oMgMoMMMgMMMMoMgMo",
		"oMMMoMMMMMMMMoMMMo",
		".ooo.oMMMMMMo.ooo.",
		"....oMMo..oMMo....",
		"....oMMo..oMMo....",
		"...oooo....oooo...",
	], [
		"..ooo........ooo..",
		".oMMMo......oMMMo.",
		".oMMMMooooooMMMMo.",
		"oMMgMMMMMMMMMMgMMo",
		"oMMMMeMMMMMMeMMMMo",
		"oMgMMMMMMMMMMMMgMo",
		"oMMMMMMMnnMMMMMMMo",
		".oMMMMMwwwwMMMMMo.",
		"oMMMoMMMMMMMMoMMMo",
		"oMgMoMMMgMMMMoMgMo",
		"oMMMoMMMMMMMMoMMMo",
		".ooo.oMMMMMMo.ooo.",
		"...oMMo....oMMo...",
		"...oMMo....oMMo...",
		"..oooo......oooo..",
	]]},
	"pixie": {"pal": {"w": "6b4a9c", "W": "b07cff", "o": "120a1e", "d": "2a1a3a", "e": "d93cf2", "v": "5a2a7a"}, "frames": [[
		"ww........ww",
		"wWw..oo..wWw",
		".wWwoddowWw.",
		".wWwdeedwWw.",
		"..wwoddoww..",
		"....oddo....",
		"...odvvdo...",
		"...odvvdo...",
		"....o..o....",
	], [
		"............",
		"w....oo....w",
		"wW..oddo..Ww",
		"wWwwdeedwwWw",
		".wWwoddowWw.",
		"..wwoddoww..",
		"...odvvdo...",
		"...odvvdo...",
		"....o..o....",
	]]},
	"turtle": {"pal": {"o": "1e120a", "b": "6a4528", "B": "8a5a30", "g": "6faa4a", "L": "4f6b3a", "H": "5e7f4a", "e": "ff3a5a"}, "frames": [[
		"....oooooooo....",
		"...obBbBbBbBbo..",
		"..obBbgbBbBbBbo.",
		".obBbBbBbBgbBbo.",
		".obbbbbbbbbbbbo.",
		"oooooooooooooooo",
		".oLLo.oHHo.oLLo.",
		".oLLo.oeeo.oLLo.",
		".oLLo..oo..oLLo.",
		".oooo......oooo.",
	], [
		"....oooooooo....",
		"...obBbBbBbBbo..",
		"..obBbgbBbBbBbo.",
		".obBbBbBbBgbBbo.",
		".obbbbbbbbbbbbo.",
		"oooooooooooooooo",
		"oLLo..oHHo..oLLo",
		"oLLo..oeeo..oLLo",
		"oLLo...oo...oLLo",
		"oooo........oooo",
	]]},
	"wisp": {"pal": {"y": "c8a040", "Y": "f2c46b", "w": "fff6d8", "k": "5a3a10"}, "frames": [[
		"....y....",
		"...yYy...",
		"..yYwYy..",
		".yYwwwYy.",
		".yYwwwYy.",
		"yYwkwkwYy",
		".yYwwwYy.",
		"..yYwYy..",
		"..yYYYy..",
		"...yYy...",
		"....y....",
		"...y.y...",
	], [
		"...y.....",
		"...yYy...",
		"..yYwYy..",
		".yYwwwYy.",
		".yYwwwYy.",
		"yYwkwkwYy",
		".yYwwwYy.",
		"..yYwYy..",
		"..yYYYy..",
		"...yYy...",
		"...y.....",
		"....y.y..",
	]]},
	"dryad": {"pal": {"o": "1e2414", "b": "5e7f4a", "B": "3e5a32", "e": "6fe39a"}, "frames": [[
		"o..o.oo.o..o",
		".oo.oBBo.oo.",
		"..oBBbbBBo..",
		"..oBbbbbBo..",
		"..obebbebo..",
		"..obbbbbbo..",
		"...obbbbo...",
		"oo.obbbbo.oo",
		".oobbBBbboo.",
		"...obBBbo...",
		"...obbbbo...",
		"...obBBbo...",
		"..obbbbbbo..",
		"..obBbbBbo..",
		".obbbbbbbbo.",
		".obBbbbbBbo.",
		"obbbo..obbbo",
		"oooo....oooo",
	], [
		"o..o.oo.o..o",
		".oo.oBBo.oo.",
		"..oBBbbBBo..",
		"..oBbbbbBo..",
		"..obebbebo..",
		"..obbbbbbo..",
		"...obbbbo...",
		".o.obbbbo.o.",
		"o.obbBBbbo.o",
		"...obBBbo...",
		"...obbbbo...",
		"...obBBbo...",
		"..obbbbbbo..",
		"..obBbbBbo..",
		".obbbbbbbbo.",
		".obBbbbbBbo.",
		"obbbo..obbbo",
		"oooo....oooo",
	]]},
	"stag": {"pal": {"o": "120a10", "a": "d8c8a0", "b": "5a3a2a", "B": "7a5238", "e": "d93cf2", "n": "1a0f0a", "w": "e8e0d0", "m": "4f7a3a"}, "frames": [[
		"a..a............a..a",
		".aa.a..........a.aa.",
		"...aa..........aa...",
		"....aa..oooo..aa....",
		".....aaobbbboaa.....",
		"......obbbbbbo......",
		"......obebbebo......",
		"......obbbbbbo......",
		".......obnnbo.......",
		"....ooowwwwwwooo....",
		"...obbbwwwwwwbbbo...",
		"..obbbbbwwwwbbbbbo..",
		"..obmbbbbbbbbbbmbo..",
		"..obbbbbbbbbbbbbbo..",
		"...obbbmbbbbmbbbo...",
		"...oBBo......oBBo...",
		"...oBBo......oBBo...",
		"...obbo......obbo...",
		"...oooo......oooo...",
	], [
		"a..a............a..a",
		".aa.a..........a.aa.",
		"...aa..........aa...",
		"....aa..oooo..aa....",
		".....aaobbbboaa.....",
		"......obbbbbbo......",
		"......obebbebo......",
		"......obbbbbbo......",
		".......obnnbo.......",
		"....ooowwwwwwooo....",
		"...obbbwwwwwwbbbo...",
		"..obbbbbwwwwbbbbbo..",
		"..obmbbbbbbbbbbmbo..",
		"..obbbbbbbbbbbbbbo..",
		"...obbbmbbbbmbbbo...",
		"..oBBo........oBBo..",
		"..oBBo........oBBo..",
		"..obbo........obbo..",
		"..oooo........oooo..",
	]]},
	"flower": {"pal": {"o": "1e1a14", "P": "b04a8a", "y": "f2c46b", "e": "2a0a1a", "g": "4f8a3a"}, "frames": [[
		"...oooo...",
		"..oPPPPo..",
		".oPPyyPPo.",
		".oPyeeyPo.",
		".oPPyyPPo.",
		"..oPPPPo..",
		"...oggo...",
		"..o.gg.o..",
		".ogo.gogo.",
		"...ogggo..",
		"..oooooo..",
	], [
		"..oo..oo..",
		".oPPooPPo.",
		".oPPyyPPo.",
		".oPyeeyPo.",
		".oPPyyPPo.",
		"..oPPPPo..",
		"...oggo...",
		"..o.gg.o..",
		".ogo.gogo.",
		"...ogggo..",
		"..oooooo..",
	]]},
	"lantern": {"pal": {"o": "120e1a", "h": "6a4a2a", "c": "8a6a4a", "C": "a8845a", "y": "ffd45a", "w": "fff6d8", "m": "5a5670", "k": "3a2e2a"}, "frames": [[
		".....mmmm.....",
		"....myyyym....",
		"....mywwym....",
		"....myyyym....",
		".....mmmm.....",
		"......mm......",
		".....ohho.....",
		"....ohhhho....",
		"....ohhhho....",
		"...occCCcco...",
		"..occcCCccco..",
		"..occcCCccco..",
		"..occcCCccco..",
		"...occcccco...",
		"...oko..oko...",
		"...oko..oko...",
		"...ooo..ooo...",
	], [
		".....mmmm.....",
		"....myyyym....",
		"....mywwym....",
		"....myyyym....",
		".....mmmm.....",
		"......mm......",
		".....ohho.....",
		"....ohhhho....",
		"....ohhhho....",
		"...occCCcco...",
		"..occcCCccco..",
		"..occcCCccco..",
		"..occcCCccco..",
		"...occcccco...",
		"..oko....oko..",
		"..oko....oko..",
		"..ooo....ooo..",
	]]},
	"orb": {"pal": {"y": "f2e28b", "w": "ffffff", "o": "b8a040"}, "frames": [[
		".ooo.",
		"oyyyo",
		"oywyo",
		"oyyyo",
		".ooo.",
	], [
		".....",
		".ooo.",
		".owo.",
		".ooo.",
		".....",
	]]},
	"sylvarche": {"pal": {}, "procedural": true, "frames": [[], []]},
	"star": {"pal": {"a": "f2c46b"}, "frames": [[
		"....a....",
		"....a....",
		"...aaa...",
		"aaaaaaaaa",
		".aaaaaaa.",
		"..aaaaa..",
		"..aa.aa..",
		".aa...aa.",
		".a.....a.",
	]]},
	"star_off": {"pal": {"a": "4a3d7a"}, "frames": [[
		"....a....",
		"....a....",
		"...aaa...",
		"aaaaaaaaa",
		".aaaaaaa.",
		"..aaaaa..",
		"..aa.aa..",
		".aa...aa.",
		".a.....a.",
	]]},
	"krag": {"pal": {"o": "120e1a", "g": "4f7a3e", "G": "74a058", "h": "1a1418", "H": "3a2e2a", "f": "8a6a3a", "F": "b08a50", "l": "4a3a2a", "a": "c8d0e0", "A": "7a849c", "w": "6a4a2a", "r": "a83a2a"}, "frames": [[
		"......oooo......",
		".....oHHHHo.....",
		".....ohhhho.....",
		"....oggGGggo....",
		"....ogGGGGgo....",
		".aa.oogggggoo.aa",
		"aAAoFFfgggfFFoAa",
		".wwFFFfgggfFFFw.",
		"..wogGgggggGgow.",
		"..wogggggggggow.",
		"..woggrrrrrggow.",
		"...ollllllllo...",
		"...olllolllo....",
		"...oggo.oggo....",
		"...ollo.ollo....",
		"...oooo.oooo....",
	], [
		"......oooo......",
		".....oHHHHo.....",
		".....ohhhho.....",
		"....oggGGggo....",
		"....ogGGGGgo....",
		".aa.oogggggoo.aa",
		"aAAoFFfgggfFFoAa",
		".wwFFFfgggfFFFw.",
		"..wogGgggggGgow.",
		"..wogggggggggow.",
		"..woggrrrrrggow.",
		"...ollllllllo...",
		"...olllolllo....",
		"..oggo...oggo...",
		"..ollo...ollo...",
		"..oooo...oooo...",
	]]},
	"berserker": {"pal": {"g": "4f7a3e", "G": "74a058", "a": "c8d0e0", "w": "6a4a2a"}, "frames": [[
		"...oooo...",
		"..oggggo..",
		"..ogGGgo..",
		"...oggo...",
		"a.oddmdo..",
		"aoddmmmdo.",
		"wodmmmmdo.",
		"wodmmlmdo.",
		".odmmmmdo.",
		"..oddddo..",
		"..ogo.ogo.",
		"..ooo.ooo.",
	], [
		"...oooo...",
		"..oggggo..",
		"..ogGGgo..",
		"...oggo...",
		"a.oddmdo..",
		"aoddmmmdo.",
		"wodmmmmdo.",
		"wodmmlmdo.",
		".odmmmmdo.",
		"..oddddo..",
		".ogo..ogo.",
		".ooo..ooo.",
	]]},
	"nyx": {"pal": {"o": "120e1a", "w": "6a5a8a", "W": "9a8ab8", "x": "c8b8e8", "h": "b8b4c8", "H": "e0dcec", "d": "3a2a5a", "D": "5a3a8a", "s": "c8b0c8", "g": "d93cf2"}, "frames": [[
		"..oo......oo..",
		".oWWo....oWWo.",
		"oWxWWo..oWWxWo",
		"oWWxWWooWWxWWo",
		"owWWWohhoWWWwo",
		".owWohHHhoWwo.",
		"..owohhhhowo..",
		"...oohhhhoo...",
		"....oDDDDo....",
		"...oDddddDo...",
		"...odDgDddo...",
		"...odddddDo...",
		"....os.so.....",
		"....oo.oo.....",
	], [
		"..oo......oo..",
		".oWWo....oWWo.",
		"oWxWWo..oWWxWo",
		"oWWxWWooWWxWWo",
		"owWWWohhoWWWwo",
		".owWohHHhoWwo.",
		"..owohhhhowo..",
		"...oohhhhoo...",
		"....oDDDDo....",
		"...oDddddDo...",
		"...odDgDddo...",
		"...odddddDo...",
		"...os...so....",
		"...oo...oo....",
	]]},
	# Zone 2 · Collines d'Ambre.
	"pillard": {"pal": {"o": "1a120c", "h": "7a5230", "H": "a8743a", "s": "e0a882", "e": "2a1a1a", "r": "b83a2a", "t": "5a4a3a", "b": "2a1e16", "d": "c8d0e0", "l": "4a3a2a"}, "frames": [[
		"....oooooo....",
		"...ohhHHHHo...",
		"..ohhhHHHHHo..",
		"..ohhsssssho..",
		"..ohseesesho..",
		"..ohssssssho..",
		"...orrrrrro...",
		"..ottrrrrtto..",
		".odtttbbtttto.",
		".odottttttoto.",
		"..o.ottttoo...",
		"....ollool....",
		"....ol..lo....",
		"...obo..obo...",
	], [
		"....oooooo....",
		"...ohhHHHHo...",
		"..ohhhHHHHHo..",
		"..ohhsssssho..",
		"..ohseesesho..",
		"..ohssssssho..",
		"...orrrrrro...",
		"..ottrrrrtto..",
		".odtttbbtttto.",
		".odottttttoto.",
		"..o.ottttoo...",
		"....ollool....",
		"...ol....lo...",
		"..obo....obo..",
	]]},
	"slinger": {"pal": {"o": "1a120c", "h": "5a6a3a", "H": "7f8f4a", "s": "e0a882", "e": "2a1a1a", "t": "8a6a3a", "b": "3a2a1a", "c": "c8b890", "l": "4a3a2a", "/": "c8b890", "|": "c8b890"}, "frames": [[
		"..........cc..",
		"....oooo.c..c.",
		"...ohhHHo.cc..",
		"..ohhHHHHo/...",
		"..ohsssso/....",
		"..oseesso.....",
		"..ossssso.....",
		"...ottttto....",
		"..otttbbtto...",
		"..otottttoo...",
		"...ottttto....",
		"...olloollo...",
		"...ol....lo...",
		"..obo....obo..",
	], [
		".........c....",
		"....oooo..c...",
		"...ohhHHo.cc..",
		"..ohhHHHHo|...",
		"..ohsssso|....",
		"..oseesso.....",
		"..ossssso.....",
		"...ottttto....",
		"..otttbbtto...",
		"..otottttoo...",
		"...ottttto....",
		"...olloollo...",
		"....ol..lo....",
		"...obo..obo...",
	]]},
	"wolf_rider": {"pal": {"o": "16120e", "w": "6a6a72", "W": "9a9aa2", "n": "2a2a30", "e": "ff3a3a", "g": "6a8a5a", "G": "8aaa6a", "x": "e8e0c8", "r": "7a4a2a", "k": "c8d0e0"}, "frames": [[
		"........oooo........",
		".......oggGgo.......",
		".......ogeGgo.......",
		"......orrrrrro......",
		"..oo..orrrrrrok.....",
		".oWWo.oorrrrook.....",
		"oWwwWooooooooooooo..",
		"oWeWwwwwwwwwwwwWWWo.",
		"onxnwwwwwWwwwwwwwwo.",
		".oxwwwwwwwwwwwwwwo..",
		"..owwwoooooowwwwo...",
		"..oww.......owwo....",
		"..ono.......ono.....",
	], [
		"........oooo........",
		".......oggGgo.......",
		".......ogeGgo.......",
		"......orrrrrro......",
		"..oo..orrrrrrok.....",
		".oWWo.oorrrrook.....",
		"oWwwWooooooooooooo..",
		"oWeWwwwwwwwwwwwWWWo.",
		"onxnwwwwwWwwwwwwwwo.",
		".oxwwwwwwwwwwwwwwo..",
		"..owwwoooooowwwwo...",
		"...oww.....owwo.....",
		"...ono.....ono......",
	]]},
	"ogre": {"pal": {"o": "1a0f0a", "s": "c8875a", "S": "e0a070", "d": "8a5a3a", "e": "ff3a3a", "n": "5a2a1a", "a": "e8a33d", "A": "ffd070", "f": "6a4a2a", "F": "8a6a3a", "w": "e8e0c8"}, "frames": [[
		"......oooooooo......",
		".....osSSSSSSso.....",
		"....osSeSSSSeSso....",
		"..ooosSSSnnSSSsooo..",
		".oaAoosSwwwwSsooAao.",
		"oaAAaosssssssssoaAao",
		"oaaaosssssssssssoaao",
		"osssossdsssssdssosso",
		"ossosssssssssssssoso",
		"ossoffffffffffffosso",
		".ooofFFFFFFFFFFfooo.",
		"....offffffffffo....",
		"....osssoooossso....",
		"....osso....osso....",
		"...ooooo....ooooo...",
	], [
		"......oooooooo......",
		".....osSSSSSSso.....",
		"....osSeSSSSeSso....",
		"..ooosSSSnnSSSsooo..",
		".oaAoosSwwwwSsooAao.",
		"oaAAaosssssssssoaAao",
		"oaaaosssssssssssoaao",
		"osssossdsssssdssosso",
		"ossosssssssssssssoso",
		"ossoffffffffffffosso",
		".ooofFFFFFFFFFFfooo.",
		"....offffffffffo....",
		"...osssoo..oosssso..",
		"...osso......osso...",
		"..ooooo......ooooo..",
	]]},
	"clan_guard": {"pal": {"o": "120e0a", "g": "6a8a5a", "G": "8aaa6a", "e": "ff3a3a", "t": "e8e0c8", "m": "7a849c", "M": "c8d0e0", "w": "7a5230", "W": "a8743a", "y": "d8b048", "l": "4a3a2a"}, "frames": [[
		".....oooooo.....",
		"....omMMMMmo....",
		"....oggGGggo....",
		"....ogeggego....",
		"....ogtggtgo....",
		"..oooooooooooo..",
		".owwWWWWWWWWwwo.",
		".owWWyyyyyyWWwo.",
		".owWWyWWWWyWWwo.",
		".owWWyyyyyyWWwo.",
		".owwWWWWWWWWwwo.",
		"..oowwwwwwwwoo..",
		"....olloollo....",
		"....ol....lo....",
		"...ooo....ooo...",
	], [
		".....oooooo.....",
		"....omMMMMmo....",
		"....oggGGggo....",
		"....ogeggego....",
		"....ogtggtgo....",
		"..oooooooooooo..",
		".owwWWWWWWWWwwo.",
		".owWWyyyyyyWWwo.",
		".owWWyWWWWyWWwo.",
		".owWWyyyyyyWWwo.",
		".owwWWWWWWWWwwo.",
		"..oowwwwwwwwoo..",
		"...olloo.ollo...",
		"...ol......lo...",
		"..ooo......ooo..",
	]]},
	"storm_shaman": {"pal": {"o": "120e0a", "g": "6a8a5a", "G": "8aaa6a", "e": "9ff0ff", "f": "6a5040", "F": "9a8060", "b": "c8b890", "y": "f0d23c", "Y": "fff6a8", "w": "7a5230", "p": "b07cff"}, "frames": [[
		"..............yY",
		"...oooooo....yYy",
		"..obbFFbbo...oyo",
		"..offggffo...ow.",
		"..ogeggego...ow.",
		"..oggGGggo...ow.",
		".offffffffo..ow.",
		"offFFFFFFFfooow.",
		"offfFpFFpFFfgow.",
		"offFFFFFFFFfoow.",
		".offffffffffo.w.",
		"..offffffffo..w.",
		"...offffffo...w.",
		"...ogo..ogo.....",
		"..ooo....ooo....",
	], [
		".............Y..",
		"...oooooo...yYy.",
		"..obbFFbbo...oyo",
		"..offggffo...ow.",
		"..ogeggego...ow.",
		"..oggGGggo...ow.",
		".offffffffo..ow.",
		"offFFFFFFFfooow.",
		"offfFpFFpFFfgow.",
		"offFFFFFFFFfoow.",
		".offffffffffo.w.",
		"..offffffffo..w.",
		"...offffffo...w.",
		"..ogo....ogo....",
		".ooo......ooo...",
	]]},
	"bonesetter": {"pal": {"o": "120a14", "r": "4a3a5a", "R": "6a5a7a", "s": "b8a8a0", "e": "d93cf2", "b": "e8e0c8", "t": "5a4030", "n": "2a1a2a"}, "frames": [[
		"..b.............",
		".bbb..oooooo....",
		"..b..orRRRRro...",
		"..b.orRRRRRRro..",
		"..b.orrsssrrro..",
		"..b.orseesrrro..",
		"..bo.osssssoo...",
		"..bororrrrrrro..",
		"..borRRrrrrRRro.",
		"..bbrrrRrrrrrro.",
		"..b.orrrrRrrrro.",
		"..b..orrrrrrro..",
		"..b..onrrrrno...",
		"..b...on..no....",
		"......oo..oo....",
	], [
		"..b.............",
		".bbb..oooooo....",
		"..b..orRRRRro...",
		"..b.orRRRRRRro..",
		"..b.orrsssrrro..",
		"..b.orseesrrro..",
		"..bo.osssssoo...",
		"..bororrrrrrro..",
		"..borRRrrrrRRro.",
		"..bbrrrRrrrrrro.",
		"..b.orrrrRrrrro.",
		"..b..orrrrrrro..",
		"..b..onrrrrno...",
		"..b..on....no...",
		".....oo....oo...",
	]]},
	"varg": {"pal": {"o": "140c08", "h": "7a849c", "H": "c8d0e0", "n": "e8dcc0", "s": "e0a882", "e": "ff3a3a", "B": "6a3a1a", "r": "a82a2a", "R": "c84a3a", "t": "5a4a3a", "b": "2a1e16", "a": "c8d0e0", "w": "6a4a2a", "l": "4a3a2a"}, "frames": [[
		"n...................n.",
		"nn....oooooooo.....nn.",
		".nnoohhHHHHHHhhoonn...",
		"...ohhhHHHHHHhhho.....",
		"...ohhsssssssshho.....",
		"....osseessesso.......",
		"....oBsssssssBo...aa..",
		"...rroBBBBBBBorr.aaaa.",
		"..rRrottttttttorRraa..",
		".orRrottbbbbttorRrow..",
		".orrrottttttttorrrow..",
		".orroottttttttoorrow..",
		"..oo.otttttttto.oo.w..",
		".....oltllltlo.....w..",
		".....oll...llo........",
		"....obbo...obbo.......",
	], [
		"n...................n.",
		"nn....oooooooo.....nn.",
		".nnoohhHHHHHHhhoonn...",
		"...ohhhHHHHHHhhho.....",
		"...ohhsssssssshho.....",
		"....osseessesso.......",
		"....oBsssssssBo...aa..",
		"...rroBBBBBBBorr.aaaa.",
		"..rRrottttttttorRraa..",
		".orRrottbbbbttorRrow..",
		".orrrottttttttorrrow..",
		".orroottttttttoorrow..",
		"..oo.otttttttto.oo.w..",
		"....oltll...lltlo..w..",
		"....oll.......llo.....",
		"...obbo.......obbo....",
	]]},
	"gharok": {"pal": {"o": "0e0a08", "g": "5a7a4a", "G": "7a9a5a", "e": "d93cf2", "E": "ff9cff", "t": "e8e0c8", "n": "e8dcc0", "N": "b8a888", "m": "5a6070", "M": "8a90a0", "f": "5a4030", "F": "7a5a40", "r": "7a2a2a", "a": "c8d0e0", "A": "8a90a0", "w": "5a3a20", "y": "f0d23c"}, "frames": [[
		"N..........................N",
		"NN........oooooooo........NN",
		".NNn....ommMMMMMMmmo....nNN.",
		"..NNnn.ommmMMMMMMmmmo.nnNN..",
		"....nNNommMMMMMMMMMmmNNn....",
		"......ogggGGGGGGGGgggo......",
		"......ogEeGGGGGGGGeEgo......",
		"......oggggGGGGGGggggo..aa..",
		"......ogtgggggggggtgggo.aAAa",
		".....ffoggggggggggggoffaAAAa",
		"...ffFFfoooooooooooofFFfaAa.",
		"..fFFFFmmMMMMMMMMMMmmFFFfaw.",
		".ofFFFmmmMMyMMMMyMMmmmFFFow.",
		".ogFFFmmMMMMMMMMMMMMmmFFgow.",
		".oggfmmmmMMMMMMMMMMmmmmfgow.",
		".oggo.ommmMMMMMMMMmmmo.ogow.",
		"..oo..orrrrrrrrrrrrrro..oow.",
		"......orrrrrrrrrrrrrro....w.",
		"......offfFFFFFFFFfffo....w.",
		"......offfo......offfo......",
		"......offfo......offfo......",
		".....ommmmo......ommmmo.....",
	], [
		"N..........................N",
		"NN........oooooooo........NN",
		".NNn....ommMMMMMMmmo....nNN.",
		"..NNnn.ommmMMMMMMmmmo.nnNN..",
		"....nNNommMMMMMMMMMmmNNn....",
		"......ogggGGGGGGGGgggo......",
		"......ogEeGGGGGGGGeEgo......",
		"......oggggGGGGGGggggo..aa..",
		"......ogtgggggggggtgggo.aAAa",
		".....ffoggggggggggggoffaAAAa",
		"...ffFFfoooooooooooofFFfaAa.",
		"..fFFFFmmMMMMMMMMMMmmFFFfaw.",
		".ofFFFmmmMMyMMMMyMMmmmFFFow.",
		".ogFFFmmMMMMMMMMMMMMmmFFgow.",
		".oggfmmmmMMMMMMMMMMmmmmfgow.",
		".oggo.ommmMMMMMMMMmmmo.ogow.",
		"..oo..orrrrrrrrrrrrrro..oow.",
		"......orrrrrrrrrrrrrro....w.",
		"......offfFFFFFFFFfffo....w.",
		".....offfo........offfo.....",
		".....offfo........offfo.....",
		"....ommmmo........ommmmo....",
	]]},
	"war_banner": {"pal": {"o": "140c08", "w": "6a4a2a", "W": "8a6a3a", "r": "a82a2a", "R": "c84a3a", "y": "d8b048", "k": "2a1e16"}, "frames": [[
		"..oyo.....",
		"..oWo.....",
		"..oWooooo.",
		"..oWRRRRRo",
		"..oWRryrRo",
		"..oWRyyyRo",
		"..oWRryrRo",
		"..oWRRRRRo",
		"..oWRRRRro",
		"..oWRoRoRo",
		"..oWo.o.o.",
		"..oWo.....",
		"..oWo.....",
		"..oWo.....",
		"..oWo.....",
		"..oWo.....",
		".ooWoo....",
		"okkkkko...",
	], [
		"..oyo.....",
		"..oWo.....",
		"..oWoooooo",
		"..oWRRRRRo",
		"..oWRryrRo",
		"..oWRyyyRo",
		"..oWRryrRo",
		"..oWRRRRRo",
		"..oWRRRRRo",
		"..oWoRoRo.",
		"..oWo.o.o.",
		"..oWo.....",
		"..oWo.....",
		"..oWo.....",
		"..oWo.....",
		"..oWo.....",
		".ooWoo....",
		"okkkkko...",
	]]},
	"storm_totem": {"pal": {"o": "140c08", "w": "6a4a2a", "W": "8a6a3a", "e": "9ff0ff", "y": "f0d23c", "Y": "fff6a8", "g": "5a7a4a"}, "frames": [[
		"...yYy...",
		"..yYYYy..",
		"...yYy...",
		"..ooooo..",
		".oWWWWWo.",
		".oWeWeWo.",
		".oWWWWWo.",
		".owwyyww.",
		".oWWWWWo.",
		"ooWgWgWoo",
		"oWWWWWWWo",
		".oWeWeWo.",
		".oWWWWWo.",
		".owwwwwo.",
		".oWWWWWo.",
		"ooooooooo",
	], [
		"..y.Y.y..",
		"...YYY...",
		"..yYYYy..",
		"..ooooo..",
		".oWWWWWo.",
		".oWeWeWo.",
		".oWWWWWo.",
		".owwyyww.",
		".oWWWWWo.",
		"ooWgWgWoo",
		"oWWWWWWWo",
		".oWeWeWo.",
		".oWWWWWo.",
		".owwwwwo.",
		".oWWWWWo.",
		"ooooooooo",
	]]},
	"caravan": {"pal": {"o": "140c08", "c": "e8dcc0", "C": "c8b890", "w": "7a5230", "W": "a8743a", "k": "3a2a1a", "y": "d8b048", "r": "a82a2a"}, "frames": [[
		".....oooooooooooo.....",
		"...ooccccccccccccoo...",
		"..occcCcccccccCcccco..",
		".occccCccccccccCcccco.",
		".oCccccccccccccccccCo.",
		".oCcccccrrrrrrcccccCo.",
		".oooooooooooooooooooo.",
		".oWWWWWWWWWWWWWWWWWWo.",
		".owwwwwwyywwyywwwwwwo.",
		".oooooooooooooooooooo.",
		"..okkko........okkko..",
		".okoykko......okkyko..",
		"..okkko........okkko..",
		"...ooo..........ooo...",
	], [
		".....oooooooooooo.....",
		"...ooccccccccccccoo...",
		"..occcCcccccccCcccco..",
		".occccCccccccccCcccco.",
		".oCccccccccccccccccCo.",
		".oCcccccrrrrrrcccccCo.",
		".oooooooooooooooooooo.",
		".oWWWWWWWWWWWWWWWWWWo.",
		".owwwwwwyywwyywwwwwwo.",
		".oooooooooooooooooooo.",
		"..okkko........okkko..",
		".okkyko........okoyko.",
		"..okkko........okkko..",
		"...ooo..........ooo...",
	]]},
	"pylon": {"pal": {"o": "140c08", "a": "e8a33d", "A": "ffd070", "w": "fff6d8", "s": "5a5670", "S": "8a86a0"}, "frames": [[
		"....o....",
		"...oAo...",
		"..oAwAo..",
		"..oaAAo..",
		".oaAwAAo.",
		".oaaAAAo.",
		".oaaAAAo.",
		"..oaAAo..",
		"..oaaAo..",
		"...oao...",
		"...oSo...",
		"..oSSSo..",
		"..osSSo..",
		".osSSSSo.",
		"ooooooooo",
	], [
		"....o....",
		"...oAo...",
		"..oAAAo..",
		"..oawAo..",
		".oaAAAAo.",
		".oaawAAo.",
		".oaaAAAo.",
		"..oaAAo..",
		"..oaaAo..",
		"...oao...",
		"...oSo...",
		"..oSSSo..",
		"..osSSo..",
		".osSSSSo.",
		"ooooooooo",
	]]},
	# Zone 3 · Marais Murmurants.
	"bog_zombie": {"pal": {"o": "141a14", "s": "7a9a6a", "S": "9ab88a", "e": "d93cf2", "m": "3a2a2a", "r": "4a5a4a", "b": "6a5a3a", "g": "3a3a30"}, "frames": [[
		"....oooo....",
		"...ossSso...",
		"..osSssSso..",
		"..oseSseso..",
		"..osssssso..",
		"...osmmso...",
		"..orrrrrro..",
		".osrrbbrrso.",
		"os.orrrro.so",
		"o..orrrro..o",
		"...oggggo...",
		"...og..go...",
		"...og..go...",
		"..ooo..ooo..",
	], [
		"....oooo....",
		"...ossSso...",
		"..osSssSso..",
		"..oseSseso..",
		"..osssssso..",
		"...osmmso...",
		"..orrrrrro..",
		".osrrbbrrso.",
		"os.orrrro.so",
		"o..orrrro..o",
		"...oggggo...",
		"...og...go..",
		"..og....og..",
		".ooo....ooo.",
	]]},
	"plague_rat": {"pal": {"o": "141a10", "p": "b88a8a", "g": "6a6a52", "G": "8a8a6a", "e": "e8f03a", "n": "2a2a20"}, "frames": [[
		"..............",
		"..oo......oo..",
		".oppo....oppo.",
		".oppooooooppo.",
		"..ogggggggggo.",
		".ogeggGGggegoo",
		"oggggGGggggggo",
		"onggggggggggo.",
		".oggggggggggo.",
		"..oo.oo.oo.oo.",
	], [
		"..............",
		"..oo......oo..",
		".oppo....oppo.",
		".oppooooooppo.",
		"..ogggggggggo.",
		".ogeggGGggegoo",
		"oggggGGggggggo",
		"onggggggggggo.",
		".oggggggggggo.",
		".oo..oo.oo..o.",
	]]},
	"slime_abomination": {"pal": {"o": "10180e", "v": "5a8a3a", "V": "8ab85a", "e": "f0e050", "m": "2a3a1a", "w": "c8d8a8", "B": "a8d070"}, "frames": [[
		"......oooooo......",
		"....oovvVVvvoo....",
		"...ovvVVVVVVvvo...",
		"..ovvveVVVVevvvo..",
		"..ovvvvvvvvvvvvo..",
		".ovvvvmmmmmmvvvvo.",
		".ovvvvmwwwwmvvvvo.",
		"ovvvvvvvvvvvvvvvvo",
		"ovvBvvvvvvvvvvBvvo",
		"ovvvvvvvvBvvvvvvvo",
		".ovvvvvvvvvvvvvvo.",
		"..ovvvvvvvvvvvvo..",
		"...ooovvvvvvooo...",
		".....oo....oo.....",
	], [
		"......oooooo......",
		"....oovvVVvvoo....",
		"...ovvVVVVVVvvo...",
		"..ovvveVVVVevvvo..",
		"..ovvvvvvvvvvvvo..",
		".ovvvvmmmmmmvvvvo.",
		".ovvvvmwwwwmvvvvo.",
		"ovvvvvvvvvvvvvvvvo",
		"ovvBvvvvvvvvvvBvvo",
		"ovvvvvvvvBvvvvvvvo",
		".ovvvvvvvvvvvvvvo.",
		"..ovvvvvvvvvvvvo..",
		"....ooovvvvooo....",
		"......oo..oo......",
	]]},
	"spitting_toad": {"pal": {"o": "10180e", "g": "4a6a3a", "G": "6a8a4a", "e": "f0a03a", "y": "a8b870", "m": "6a2a2a", "w": "9ad03a"}, "frames": [[
		"....oooooo....",
		"..ooggGGggoo..",
		".ogegGGGGgego.",
		".oggggggggggo.",
		"oggyyyyyyyyggo",
		"ogyymmmmmmyygo",
		".oyyyyyyyyyyo.",
		".oggggggggggo.",
		"ogg.oggggo.ggo",
		"oo...oooo...oo",
	], [
		"....oooooo....",
		"..ooggGGggoo..",
		".ogegGGGGgego.",
		".oggggggggggo.",
		"oggyyyyyyyyggo",
		"ogyymwwwwmyygo",
		".oyyyyyyyyyyo.",
		".oggggggggggo.",
		".ogg.oggo.ggo.",
		".oo...oo...oo.",
	]]},
	"shield_skeleton": {"pal": {"o": "14121c", "b": "e8e4d8", "e": "d93cf2", "n": "8a8678", "W": "7a5a3a", "w": "5a4a3a", "R": "8e62e0"}, "frames": [[
		"...ooooo.......",
		"..obbbbbo......",
		"..obebebo......",
		"..obbbbbo......",
		"...obnbo.......",
		".ooooooooooo...",
		"oWWWWWWWWWWWo..",
		"oWwwwwwwwwwWo..",
		"oWwwRRRRRwwWo..",
		"oWwwRwwwRwwWo..",
		"oWwwRRRRRwwWo..",
		"oWwwwwwwwwwWo..",
		".ooooooooooo...",
		"...ob...bo.....",
		"..oob...boo....",
	], [
		"...ooooo.......",
		"..obbbbbo......",
		"..obebebo......",
		"..obbbbbo......",
		"...obnbo.......",
		".ooooooooooo...",
		"oWWWWWWWWWWWo..",
		"oWwwwwwwwwwWo..",
		"oWwwRRRRRwwWo..",
		"oWwwRwwwRwwWo..",
		"oWwwRRRRRwwWo..",
		"oWwwwwwwwwwWo..",
		".ooooooooooo...",
		"..ob.....bo....",
		".oob.....boo...",
	]]},
	"renegade_adept": {"pal": {"o": "100c18", "h": "3a2a4a", "H": "5a4a6a", "s": "c8b0a0", "e": "b07cff", "p": "7a52c8", "P": "d8c0ff"}, "frames": [[
		"....oooooo....",
		"...ohhhhhho...",
		"..ohhHHHHhho..",
		"..ohssssssho..",
		"..ohseeseesho.",
		"..ohsssssho...",
		".ohhhhhhhhho..",
		"ohhhHhppHhhho.",
		"ohhhhpPPphhho.",
		"ohhhhhpphhhhoP",
		".ohhhhhhhhhooP",
		"..ohhhhhhhho.P",
		"...ohhhhhho..P",
		"...oho..oho...",
		"..ooo....ooo..",
	], [
		"....oooooo....",
		"...ohhhhhho...",
		"..ohhHHHHhho..",
		"..ohssssssho..",
		"..ohseeseesho.",
		"..ohsssssho...",
		".ohhhhhhhhho..",
		"ohhhHhppHhhho.",
		"ohhhhpPPphhho.",
		"ohhhhhpphhhhoP",
		".ohhhhhhhhhooP",
		"..ohhhhhhhho.P",
		"...ohhhhhho..P",
		"..oho....oho..",
		".ooo......ooo.",
	]]},
	"mist_witch": {"pal": {"o": "10140e", "h": "3a3a4a", "s": "9ab8a0", "e": "c8f0a0", "f": "6a7a8a", "F": "9aa8b8", "L": "c9d1c4"}, "frames": [[
		"......o.......",
		".....oho......",
		"....ohhho.....",
		"...ohhhhho....",
		"..oooooooooo..",
		"...ossssso....",
		"...oseesso....",
		"...osssso.....",
		"..offfffffo.L.",
		".offFFFFFffoLL",
		"offffFFffffoL.",
		"offfffffffffo.",
		".offfffffffo..",
		"..offffffffo..",
		"...offfffo....",
		"....oo..oo....",
	], [
		"......o.......",
		".....oho......",
		"....ohhho.....",
		"...ohhhhho....",
		"..oooooooooo..",
		"...ossssso....",
		"...oseesso....",
		"...osssso.....",
		"..offfffffo.L.",
		".offFFFFFffoLL",
		"offffFFffffoL.",
		"offfffffffffo.",
		".offfffffffo..",
		"..offffffffo..",
		"...offfffo....",
		"...oo....oo...",
	]]},
	"croc_lich": {"pal": {"o": "0e140e", "b": "4a5a4a", "B": "6a7a6a", "e": "d93cf2", "t": "2a1a1a", "w": "e8e4d8", "R": "8e62e0", "r": "5a3a8a"}, "frames": [[
		"...........oooooo...........",
		"........oooBBBBBBooo........",
		"......ooBBbbbbbbbbBBoo......",
		".....oBBbbeebbbbeebbBBo.....",
		"....oBbbbbbbbbbbbbbbbbBo....",
		"...obbbbbbbbbbbbbbbbbbbbo...",
		"..obbbttttttttttttttttbbbo..",
		"..obbtwtwtwtwtwtwtwtwtwbbo..",
		"..obbbbbbbbbbbbbbbbbbbbbbo..",
		"...obbbbbbbbbbbbbbbbbbbbo...",
		"..ooRRRbbbbbbbbbbbbbbRRRoo..",
		".oRRrRbbbbBBBBBBbbbbRrRRRo..",
		".oRrrRobbbbbbbbbbbboRrrRRo..",
		"..ooo..obbbo..obbbo..ooo....",
		"......oooo....oooo..........",
	], [
		"...........oooooo...........",
		"........oooBBBBBBooo........",
		"......ooBBbbbbbbbbBBoo......",
		".....oBBbbeebbbbeebbBBo.....",
		"....oBbbbbbbbbbbbbbbbbBo....",
		"...obbbbbbbbbbbbbbbbbbbbo...",
		"..obbbttttttttttttttttbbbo..",
		"..obbtwtwtwtwtwtwtwtwtwbbo..",
		"..obbbbbbbbbbbbbbbbbbbbbbo..",
		"...obbbbbbbbbbbbbbbbbbbbo...",
		"..ooRRRbbbbbbbbbbbbbbRRRoo..",
		".oRRrRbbbbBBBBBBbbbbRrRRRo..",
		".oRrrRobbbbbbbbbbbboRrrRRo..",
		"..ooo..obbbo..obbbo..ooo....",
		".......oooo....oooo.........",
	]]},
	"hydra": {"pal": {"o": "0e140e", "g": "3a6a4a", "G": "5a8a5a", "e": "f0d23c", "t": "e8e4d8", "y": "9ab870"}, "frames": [[
		"............................",
		"...........oooooo...........",
		"..........ogGGGGgo..........",
		"..........ogeGGego..........",
		"..........ogggggggo.........",
		"...........ogtttgo..........",
		"............oggggo..........",
		"............ogggo...........",
		"......oooooooggggooooooo....",
		"....ooggggggggggggggggggoo..",
		"...oggGGgggggggggggggGGgggo.",
		"..ogggGGgggyyyyyyyggggGGgggo",
		"..oggggggggyyyyyyyggggggggo.",
		".ogggggggggyyyyyyyggggggggo.",
		".oggggggggggyyyyyggggggggo..",
		"..oggggggggggggggggggggoo...",
		"...ooggggoooooooooggggo.....",
		".....ogggo.......ogggo......",
		"....ooooo.......ooooo.......",
	], [
		"............................",
		"...........oooooo...........",
		"..........ogGGGGgo..........",
		"..........ogeGGego..........",
		"..........ogggggggo.........",
		"...........ogtttgo..........",
		"............oggggo..........",
		"............ogggo...........",
		"......oooooooggggooooooo....",
		"....ooggggggggggggggggggoo..",
		"...oggGGgggggggggggggGGgggo.",
		"..ogggGGgggyyyyyyyggggGGgggo",
		"..oggggggggyyyyyyyggggggggo.",
		".ogggggggggyyyyyyyggggggggo.",
		".oggggggggggyyyyyggggggggo..",
		"..oggggggggggggggggggggoo...",
		"...ooggggoooooooooggggo.....",
		".....ogggo.......ogggo......",
		"....ooooo.......ooooo.......",
	]]},
	"hydra_head": {"pal": {"o": "0e140e", "g": "3a6a4a", "G": "5a8a5a", "e": "f0d23c", "t": "2a1a1a", "w": "e8e4d8"}, "frames": [[
		"...oooooo...",
		"..oGGGGGGo..",
		".oGgeGGegGo.",
		".oGGGGGGGGo.",
		"oGGttttttGGo",
		"oGtwtwtwtwGo",
		".oGGGGGGGGo.",
		"..oggggggo..",
		"...ogggggo..",
		"....ogggo...",
		"....ogggo...",
		"...ogggggo..",
	], [
		"...oooooo...",
		"..oGGGGGGo..",
		".oGgeGGegGo.",
		".oGGGGGGGGo.",
		"oGGGGGGGGGGo",
		"oGttttttttGo",
		".oGwtwtwtwo.",
		"..oggggggo..",
		"...ogggggo..",
		"....ogggo...",
		"....ogggo...",
		"...ogggggo..",
	]]},
	"barge": {"pal": {"o": "10140e", "w": "6a4a2a", "W": "8a6a3a", "c": "c8b890", "y": "f2c46b", "Y": "fff6c8", "b": "3a5a6a", "B": "5a8aa0"}, "frames": [[
		"..........y...........",
		".........oYo..........",
		".........oyo..........",
		"..........w...........",
		"..........w...........",
		"...oooooooooooooooo...",
		"..owwWWWWWWWWWWWWwwo..",
		".owwWWccccccccccWWwwo.",
		"owwwwwwwwwwwwwwwwwwwwo",
		".owwwwwwwwwwwwwwwwwwo.",
		"..oooooooooooooooooo..",
		".bBbBbBbBbBbBbBbBbBbB.",
	], [
		"..........y...........",
		".........oYo..........",
		".........oyo..........",
		"..........w...........",
		"..........w...........",
		"...oooooooooooooooo...",
		"..owwWWWWWWWWWWWWwwo..",
		".owwWWccccccccccWWwwo.",
		"owwwwwwwwwwwwwwwwwwwwo",
		".owwwwwwwwwwwwwwwwwwo.",
		"..oooooooooooooooooo..",
		".BbBbBbBbBbBbBbBbBbBb.",
	]]},
	"cross": {"pal": {"g": "6fe39a", "o": "0f2a18"}, "frames": [[
		".ooo.",
		"oggo.",
		"ogggo",
		".ggo.",
		".oo..",
	]]},
	"px": {"pal": {"w": "ffffff"}, "frames": [["w"]]},
}

static var _texture: ImageTexture
static var _frames: Dictionary = {} ## clé -> Array[Dictionary{uv: Rect2, px: Rect2i, w, h}]
static var _singles: Dictionary = {}


static func texture() -> ImageTexture:
	if _texture == null:
		_build()
	return _texture


## Image n° « index » (modulo) du sprite « name » ; « element » pour les sprites recolorés.
static func frame(name: String, element: String = "", index: int = 0) -> Dictionary:
	if _texture == null:
		_build()
	var key := name
	if RECOLOR.has(name):
		key = name + "@" + (element if ELEM.has(element) else "physique")
	var arr: Array = _frames.get(key, _frames.get("familiar@physique"))
	return arr[index % arr.size()]


static func height_m(name: String) -> float:
	return float(HEIGHT_M.get(name, 0.7))


static func frame_count(name: String) -> int:
	if _texture == null:
		_build()
	var key := name + "@physique" if RECOLOR.has(name) else name
	return (_frames.get(key, [0]) as Array).size()


## Texture autonome d'une image de sprite (icônes de l'interface).
static func single(name: String, index: int = 0) -> ImageTexture:
	var key := "%s#%d" % [name, index]
	if not _singles.has(key):
		var imgs := _images_for(name, "")
		_singles[key] = ImageTexture.create_from_image(imgs[index % imgs.size()])
	return _singles[key]


static func _build() -> void:
	var entries: Array = [] # [key, Image]
	for name in DEFS.keys():
		if RECOLOR.has(name):
			for el in ELEM.keys():
				var imgs := _images_for(str(name), str(el))
				for i in range(imgs.size()):
					entries.append([str(name) + "@" + str(el), imgs[i]])
		else:
			for img in _images_for(str(name), ""):
				entries.append([str(name), img])
	# Rangement en étagères.
	var atlas_w := 512
	var x := 1
	var y := 1
	var shelf_h := 0
	var places: Array = []
	for e in entries:
		var img: Image = e[1]
		if x + img.get_width() + 1 > atlas_w:
			x = 1
			y += shelf_h + 1
			shelf_h = 0
		places.append(Vector2i(x, y))
		x += img.get_width() + 1
		shelf_h = maxi(shelf_h, img.get_height())
	var atlas_h := 1
	while atlas_h < y + shelf_h + 2:
		atlas_h *= 2
	var atlas := Image.create_empty(atlas_w, atlas_h, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))
	_frames.clear()
	for i in range(entries.size()):
		var key: String = entries[i][0]
		var img: Image = entries[i][1]
		var p: Vector2i = places[i]
		atlas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), p)
		var uv := Rect2(Vector2(p) / Vector2(atlas_w, atlas_h), Vector2(img.get_size()) / Vector2(atlas_w, atlas_h))
		if not _frames.has(key):
			_frames[key] = []
		(_frames[key] as Array).append({"uv": uv, "px": Rect2i(p, img.get_size()), "w": img.get_width(), "h": img.get_height()})
	_texture = ImageTexture.create_from_image(atlas)


static func _images_for(name: String, element: String) -> Array[Image]:
	var out: Array[Image] = []
	var override := "res://assets/sprites/%s.png" % name
	if ResourceLoader.exists(override):
		for path in [override, "res://assets/sprites/%s-2.png" % name]:
			if not ResourceLoader.exists(path):
				continue
			var tex: Texture2D = load(path)
			var img := tex.get_image()
			if img.is_compressed():
				img.decompress()
			img.convert(Image.FORMAT_RGBA8)
			if RECOLOR.has(name):
				_tint_neutral(img, element)
			out.append(img)
		return out
	var d: Dictionary = DEFS[name]
	if bool(d.get("procedural", false)):
		out.append(_gen_sylvarche(0))
		out.append(_gen_sylvarche(1))
		return out
	var pal: Dictionary = (d["pal"] as Dictionary).duplicate()
	if RECOLOR.has(name):
		var ec: Array = ELEM[element if ELEM.has(element) else "physique"]
		if not pal.has("o"):
			pal["o"] = ec[0]
		pal["d"] = ec[1]
		pal["m"] = ec[2]
		pal["l"] = ec[3]
	if not pal.has("o"):
		pal["o"] = "120e1a"
	for rows in d["frames"]:
		out.append(_rasterize(rows, pal))
	return out


## Parties en gris neutre -> rampe de couleurs de l'élément (noir : foncé, gris : principal, blanc : reflet).
static func _tint_neutral(img: Image, element: String) -> void:
	var ec: Array = ELEM[element if ELEM.has(element) else "physique"]
	var ramp := [Color(str(ec[0])), Color(str(ec[1])), Color(str(ec[2])), Color(str(ec[3]))]
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a <= 0.0 or c.s > 0.15:
				continue
			var v := c.v
			var out: Color
			if v < 0.3:
				out = (ramp[0] as Color).lerp(ramp[1], v / 0.3)
			elif v < 0.7:
				out = (ramp[1] as Color).lerp(ramp[2], (v - 0.3) / 0.4)
			else:
				out = (ramp[2] as Color).lerp(ramp[3], (v - 0.7) / 0.3)
			out.a = c.a
			img.set_pixel(x, y, out)


static func _rasterize(rows: Array, pal: Dictionary) -> Image:
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, str(r).length())
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(h):
		var row := str(rows[y])
		for x in range(row.length()):
			var ch := row[x]
			if ch == "." or ch == " " or not pal.has(ch):
				continue
			img.set_pixel(x, y, Color(str(pal[ch])))
	return img


## Boss de la zone 1, dessiné par code : canopée corrompue, tronc à visage, bras-branches, racines.
static func _gen_sylvarche(frame: int) -> Image:
	var w := 34
	var h := 44
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var sway := float(frame)
	var leaves := [Color("223a24"), Color("3f6a3a"), Color("6f9a4a"), Color("8fc05a")]
	for y in range(0, 24):
		for x in range(w):
			var dx := (float(x) - 16.5 - sway * 0.8) / 15.5
			var dy := (float(y) - 11.0) / 11.0
			var d := dx * dx + dy * dy + rng.randf_range(-0.14, 0.14)
			if d >= 1.0:
				continue
			var shade := 1
			if dx + (-dy) > 0.55:
				shade = 3 if d < 0.55 else 2
			elif dx < -0.35 or dy > 0.45:
				shade = 0
			var c: Color = leaves[shade]
			var r := rng.randf()
			if r < 0.06:
				c = Color("8e62e0")
			elif r < 0.08:
				c = Color("d93cf2")
			img.set_pixel(x, y, c)
	for y in range(17, 38):
		var half := 4 + int(float(y - 17) / 7.0)
		for x in range(17 - half, 17 + half):
			var c := Color("4a3424")
			if (x * 3 + y) % 7 == 0:
				c = Color("3a2818")
			if x >= 17 + half - 2:
				c = Color("6a4a30")
			if x <= 17 - half:
				c = Color("2e2016")
			img.set_pixel(x, y, c)
	var glow := Color("ff8af0") if frame == 0 else Color("d93cf2")
	for e in [Vector2i(13, 23), Vector2i(19, 23)]:
		img.set_pixel(e.x, e.y, Color("d93cf2"))
		img.set_pixel(e.x + 1, e.y, Color("d93cf2"))
		img.set_pixel(e.x, e.y + 1, glow)
		img.set_pixel(e.x + 1, e.y + 1, glow)
	for x in range(14, 21):
		img.set_pixel(x, 28, Color("1a0f0a"))
	img.set_pixel(15, 29, Color("1a0f0a"))
	img.set_pixel(19, 29, Color("1a0f0a"))
	var arm_l := Vector2i(2, 16 - frame)
	var arm_r := Vector2i(31, 15 + frame)
	_line(img, Vector2i(12, 26), arm_l, Color("4a3424"))
	_line(img, Vector2i(12, 27), arm_l + Vector2i(0, 1), Color("2e2016"))
	_line(img, Vector2i(22, 26), arm_r, Color("6a4a30"))
	_line(img, Vector2i(22, 27), arm_r + Vector2i(0, 1), Color("4a3424"))
	_line(img, arm_l, arm_l + Vector2i(-1, -3), Color("4a3424"))
	_line(img, arm_r, arm_r + Vector2i(1, -3), Color("6a4a30"))
	for i in range(6):
		var sx := 11 + i * 2
		_line(img, Vector2i(sx, 37), Vector2i(3 + i * 6 + frame, 43), Color("3a2818"))
	for i in range(14):
		var p := Vector2i(rng.randi_range(12, 22), rng.randi_range(18, 36))
		if img.get_pixel(p.x, p.y).a > 0.0:
			img.set_pixel(p.x, p.y, Color("8e62e0"))
	_outline(img, Color("0c100a"))
	return img


static func _line(img: Image, a: Vector2i, b: Vector2i, c: Color) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in range(steps + 1):
		var t := float(i) / float(maxi(1, steps))
		var p := Vector2i(roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)))
		if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
			img.set_pixel(p.x, p.y, c)


static func _outline(img: Image, c: Color) -> void:
	var src := img.duplicate()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if src.get_pixel(x, y).a > 0.0:
				continue
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + o
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and src.get_pixel(q.x, q.y).a > 0.0:
					img.set_pixel(x, y, c)
					break
