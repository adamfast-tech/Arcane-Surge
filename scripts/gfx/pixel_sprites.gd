class_name PixelSprites
extends RefCounted
## Sprites pixel-art générés à partir de cartes ASCII (aucun fichier image externe).
## Lettres « a »/« b » des sprites alliés recolorées selon l'élément de l'unité.

const ELEM := {
	"physique": ["5a6378", "cfd6e6"],
	"feu": ["8a3a12", "ff9b4a"],
	"givre": ["2e6e9a", "9fe3ff"],
	"foudre": ["8a7a10", "ffe45c"],
	"nature": ["2e5d3a", "8fd16a"],
	"lumiere": ["b89a3a", "fff6c8"],
	"ombre": ["3b2a6b", "b07cff"],
}

const RECOLOR := ["familiar", "knight", "archer", "golem", "fusion"]

const MAPS := {
	"familiar": {"pal": {"c": "fffbe8"}, "rows": [
		"..aa..",
		".abba.",
		"abccba",
		"abccba",
		".abba.",
		"..bb..",
		".b..b.",
	]},
	"knight": {"pal": {"h": "c0c8d8", "k": "1a1a2a", "s": "9aa4b8", "d": "3a2e2a"}, "rows": [
		".hhhh.",
		"hhkkhh",
		".hhhh.",
		"abbbba",
		"abbbba",
		"sabbas",
		".a..a.",
		".d..d.",
	]},
	"archer": {"pal": {"h": "3f7a4a", "k": "c8f5e0", "l": "8a5a2b", "d": "3a2e2a"}, "rows": [
		"..hh..",
		".hhhh.",
		".hkkh.",
		"abbbbl",
		"abbbbl",
		".bbbbl",
		".a..a.",
		".d..d.",
	]},
	"golem": {"pal": {"c": "fffbe8"}, "rows": [
		"...aaaaa...",
		"..abbbbba..",
		".abbcbcbba.",
		".abbbbbbba.",
		"aabbbbbbbaa",
		"abaabbbaaba",
		"abbabbbabba",
		"abbabbbabba",
		".aaabbbaaa.",
		"..abbabba..",
		"..abb.bba..",
		"..aaa.aaa..",
	]},
	"fusion": {"pal": {"c": "ffffff"}, "rows": [
		"....a....",
		"...aba...",
		"..abcba..",
		".abcccba.",
		"abcccccba",
		".abcccba.",
		"..abcba..",
		".a.aba.a.",
		"a...a...a",
	]},
	"skeleton": {"pal": {"a": "5a5468", "b": "e8e4d8", "k": "b07cff"}, "rows": [
		".aaaa.",
		"abbbba",
		"abkbka",
		".abba.",
		"aabbaa",
		".abba.",
		".a..a.",
		".a..a.",
	]},
	"mage": {"pal": {"h": "2f4f8f", "f": "f0d0b0", "k": "1a1a2a", "r": "2f6fa0", "t": "4fe3d2", "b": "3a2e2a"}, "rows": [
		"...hh...",
		"..hhhh..",
		".hhhhhh.",
		"..fkkf..",
		"..ffff..",
		".rrttrr.",
		"rrrttrrr",
		".rrttrr.",
		".rrrrrr.",
		"rrrrrrrr",
		".bb..bb.",
	]},
	"brann": {"pal": {"h": "c0c8d8", "f": "f0d0b0", "k": "1a1a2a", "o": "d9773a", "s": "8a6a3a", "b": "9aa4b8", "a": "5a5670", "d": "3a2e2a"}, "rows": [
		"..hhhh..",
		".hhhhhh.",
		".hfkkfh.",
		".oooooo.",
		"sooooooa",
		"sbbbbbba",
		"sbbbbbba",
		".bbbbbb.",
		".dd..dd.",
	]},
	"sylwen": {"pal": {"g": "3f7a4a", "f": "f0d0b0", "k": "1a1a2a", "y": "c8a040", "l": "8a5a2b", "d": "3a2e2a"}, "rows": [
		"...gg...",
		"..gggg..",
		".gfkkfg.",
		".gffffg.",
		"..gggg.l",
		".gggggl.",
		"gggyyggl",
		".gggggl.",
		".gg..gg.",
		".dd..dd.",
	]},
	"mushroom": {"pal": {"a": "3b1f4f", "b": "9c4dcc", "w": "e7d6f5", "c": "e8d8b0", "e": "ff5470"}, "rows": [
		"..aaa..",
		".abwba.",
		"abbbbwa",
		"aaaaaaa",
		"..cec..",
		"..ccc..",
		"..c.c..",
	]},
	"rabbit": {"pal": {"a": "3a3030", "b": "7a6a5a", "e": "ff5470"}, "rows": [
		".a...a.",
		".a...a.",
		".abbba.",
		"abebeba",
		"abbbbba",
		".abbba.",
		".a...a.",
	]},
	"bear": {"pal": {"a": "22301a", "b": "4f6b3a", "e": "ff5470", "c": "8fd16a"}, "rows": [
		".aa.....aa.",
		"abba...abba",
		"abbbbbbbbba",
		"abebbbbbeba",
		"abbbbcbbbba",
		"abbbbbbbbba",
		".abbbbbbba.",
		".abbbbbbba.",
		".aa.aa.aa..",
	]},
	"pixie": {"pal": {"a": "6b4a9c", "b": "2a1a3a", "c": "d93cf2"}, "rows": [
		"a.....a",
		"aa.b.aa",
		"aabcbaa",
		".abbba.",
		"..b.b..",
		"..c.c..",
	]},
	"turtle": {"pal": {"a": "2b1a10", "b": "7a5230", "c": "5e3b20", "d": "4f6b3a"}, "rows": [
		"..aaaaa..",
		".abcbcba.",
		"abcbcbcba",
		"abbbbbbba",
		"aaaaaaaaa",
		".dd...dd.",
		".dd...dd.",
	]},
	"wisp": {"pal": {"a": "f2c46b", "b": "fff2a8", "c": "ffffff"}, "rows": [
		"..a..",
		".aba.",
		"abcba",
		"abcba",
		".aba.",
		"..a..",
		"..a..",
	]},
	"dryad": {"pal": {"a": "3b4a2e", "b": "5e7f4a", "e": "6fe39a", "c": "6b4a2e"}, "rows": [
		"a.a.a.a",
		".aaaaa.",
		".abbba.",
		".bebeb.",
		".bbbbb.",
		"..bbb..",
		".bbcbb.",
		"bb.c.bb",
		"...c...",
		"..ccc..",
	]},
	"star": {"pal": {}, "rows": [
		"....a....",
		"....a....",
		"...aaa...",
		"aaaaaaaaa",
		".aaaaaaa.",
		"..aaaaa..",
		"..aa.aa..",
		".aa...aa.",
		".a.....a.",
	]},
}

static var _cache: Dictionary = {}


static func get_tex(sprite: String, element: String = "") -> Texture2D:
	var key := sprite
	if RECOLOR.has(sprite):
		key = sprite + "_" + (element if ELEM.has(element) else "physique")
	if _cache.has(key):
		return _cache[key]
	var def: Dictionary = MAPS.get(sprite, MAPS["familiar"])
	var pal: Dictionary = (def["pal"] as Dictionary).duplicate()
	if RECOLOR.has(sprite):
		var ec: Array = ELEM[element if ELEM.has(element) else "physique"]
		pal["a"] = ec[0]
		pal["b"] = ec[1]
	var tex := _build(def["rows"], pal)
	_cache[key] = tex
	return tex


static func star(on: bool) -> Texture2D:
	var key := "star_on" if on else "star_off"
	if _cache.has(key):
		return _cache[key]
	var tex := _build(MAPS["star"]["rows"], {"a": "f2c46b" if on else "4a3d7a"})
	_cache[key] = tex
	return tex


static func unit_tex(u: Unit) -> Texture2D:
	return get_tex(u.sprite, u.element)


static func _build(rows: Array, pal: Dictionary) -> ImageTexture:
	var h := rows.size()
	var w := str(rows[0]).length()
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(h):
		var row := str(rows[y])
		if row.length() != w:
			push_error("PixelSprites : ligne de longueur incorrecte (%s)" % row)
		for x in range(mini(w, row.length())):
			var ch := row[x]
			if ch == "." or not pal.has(ch):
				continue
			img.set_pixel(x, y, Color(str(pal[ch])))
	return ImageTexture.create_from_image(img)
