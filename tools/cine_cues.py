"""Insère des indications de mise en scène (cam/fx/act/cast) dans un fichier de dialogues, en texte
(préserve la mise en forme). Usage : python3 tools/cine_cues.py data/dialogues/fr/z01.json tools/cine/cues_z01.py
Le module définit CAST = {scene: [...]} et CUES = [(scene, extrait_du_texte, {cues})]."""
import json, sys, importlib.util
path, mod = sys.argv[1], sys.argv[2]
spec = importlib.util.spec_from_file_location("cues", mod); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
s = open(path, encoding="utf-8").read()

def scene_span(s, sid):
    a = s.index('    "%s": {' % sid)
    b = s.find('\n    "', a + 10)
    return a, (b if b > 0 else len(s))

for sid, cast in m.CAST.items():
    a, b = scene_span(s, sid)
    block = s[a:b]
    if '"cast"' in block:
        continue
    i = block.index('"lines": [')
    line_start = block.rfind('\n', 0, i) + 1
    ind = block[line_start:i]
    block = block[:line_start] + ind + '"cast": ' + json.dumps(cast, ensure_ascii=False) + ',\n' + block[line_start:]
    s = s[:a] + block + s[b:]

for sid, snip, cues in m.CUES:
    a, b = scene_span(s, sid)
    block = s[a:b]
    n = block.count(snip)
    assert n == 1, (sid, snip, n)
    i = block.index(snip)
    o = block.rfind('{"', 0, i)
    obj_end = block.index('\n', i)
    if any(('"%s":' % k) in block[o:obj_end] for k in cues):
        continue
    ins = ''.join('"%s": %s, ' % (k, json.dumps(v, ensure_ascii=False)) for k, v in cues.items())
    block = block[:o + 1] + ins + block[o + 1:]
    s = s[:a] + block + s[b:]

json.loads(s)
open(path, "w", encoding="utf-8").write(s)
print("ok", len(m.CUES), "répliques,", len(m.CAST), "distributions")
