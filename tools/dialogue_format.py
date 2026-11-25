"""Remet un fichier de dialogues au format « une réplique par ligne » (celui de data/dialogues/fr/z01.json),
sans changer son contenu, pour que tools/cine_cues.py puisse y poser les indications de mise en scène.
Usage : python3 tools/dialogue_format.py data/dialogues/fr/z03.json"""
import json, sys

p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
J = lambda v: json.dumps(v, ensure_ascii=False)
out = ['{']
keys = list(d.keys())
for ki, k in enumerate(keys):
    v = d[k]
    comma = ',' if ki < len(keys) - 1 else ''
    if k == 'scenes':
        out.append('  "scenes": {')
        items = list(v.items())
        for i, (sk, sv) in enumerate(items):
            out.append('    %s: {' % J(sk))
            for hk, hv in sv.items():
                if hk != 'lines':
                    out.append('      %s: %s,' % (J(hk), J(hv)))
            out.append('      "lines": [')
            ls = sv['lines']
            for j, l in enumerate(ls):
                out.append('        %s%s' % (J(l), ',' if j < len(ls) - 1 else ''))
            out.append('      ]')
            out.append('    }' + (',' if i < len(items) - 1 else ''))
        out.append('  }' + comma)
    elif isinstance(v, dict):
        out.append('  %s: {' % J(k))
        items = list(v.items())
        for i, (bk, bv) in enumerate(items):
            last = ',' if i < len(items) - 1 else ''
            if isinstance(bv, list):
                out.append('    %s: [' % J(bk))
                for j, l in enumerate(bv):
                    out.append('      %s%s' % (J(l), ',' if j < len(bv) - 1 else ''))
                out.append('    ]' + last)
            else:
                out.append('    %s: %s%s' % (J(bk), J(bv), last))
        out.append('  }' + comma)
    else:
        out.append('  %s: %s%s' % (J(k), J(v), comma))
out.append('}')
txt = '\n'.join(out) + '\n'
assert json.loads(txt) == d
open(p, 'w', encoding='utf-8').write(txt)
print('ok', len(txt.splitlines()), 'lignes')
