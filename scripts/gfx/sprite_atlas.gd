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
## Sprites dont les lettres o/d/m/l prennent les couleurs de l'élément.
const RECOLOR := ["familiar", "knight", "archer", "golem", "fusion"]

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
		var tex: Texture2D = load(override)
		var full := tex.get_image()
		full.decompress()
		full.convert(Image.FORMAT_RGBA8)
		var def: Dictionary = DEFS.get(name, {})
		var n := maxi(1, (def.get("frames", [[]]) as Array).size())
		var fw := int(full.get_width() / float(n))
		for i in range(n):
			out.append(full.get_region(Rect2i(i * fw, 0, fw, full.get_height())))
		return out
	var d: Dictionary = DEFS[name]
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
