"""Pose les indications de mise en scène d'une zone dans son fichier de dialogues, en texte (la mise en forme
du fichier est gardée : une réplique par ligne). Usage :
    python3 tools/cine_cues.py data/dialogues/fr/z01.json tools/cine/cues_z01.py
Le module de la zone définit :
    SCENE = {scene: {"cast": [...], "grade": "..."}}   (en-tête de scène ; CAST = {scene: [...]} accepté aussi)
    CUES = [(scene, extrait_du_texte, {"cam": ..., "fx": ..., "act": ..., "grade": ..., "emote": ..., ...})]
Chaque réplique visée est réécrite : ses anciennes indications (cam, fx, act, grade, emote) sont remplacées
par les nouvelles. Relancer le script ne change rien."""
import json, sys, importlib.util

CUE_KEYS = ("cam", "fx", "act", "grade", "emote")
path, mod = sys.argv[1], sys.argv[2]
spec = importlib.util.spec_from_file_location("cues", mod)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
s = open(path, encoding="utf-8").read()


def scene_span(s, sid):
    a = s.index('    "%s": {' % sid)
    b = s.find('\n    "', a + 10)
    return a, (b if b > 0 else len(s))


scenes = dict(getattr(m, "SCENE", {}))
for sid, cast in getattr(m, "CAST", {}).items():
    scenes.setdefault(sid, {})["cast"] = cast
for sid, head in scenes.items():
    a, b = scene_span(s, sid)
    block = s[a:b]
    i = block.index('"lines": [')
    line_start = block.rfind('\n', 0, i) + 1
    ind = block[line_start:i]
    header = block[:line_start]
    kept = [ln for ln in header.split('\n') if not any(ln.strip().startswith('"%s":' % k) for k in head)]
    new = '\n'.join(kept)
    for k, v in head.items():
        new += ind + '"%s": %s,\n' % (k, json.dumps(v, ensure_ascii=False))
    block = new + block[line_start:]
    s = s[:a] + block + s[b:]

for sid, snip, cues in m.CUES:
    a, b = scene_span(s, sid)
    block = s[a:b]
    n = block.count(snip)
    assert n == 1, (sid, snip, n)
    i = block.index(snip)
    o = block.index('{', block.rfind('\n', 0, i) + 1)
    e = block.index('\n', i)
    line = block[o:e]
    comma = line.endswith(',')
    obj = json.loads(line[:-1] if comma else line)
    rest = {k: v for k, v in obj.items() if k not in CUE_KEYS and k not in cues}
    out = dict(cues)
    out.update(rest)
    block = block[:o] + json.dumps(out, ensure_ascii=False) + (',' if comma else '') + block[e:]
    s = s[:a] + block + s[b:]

json.loads(s)
open(path, "w", encoding="utf-8").write(s)
print("ok", len(m.CUES), "répliques,", len(scenes), "en-têtes de scène")
