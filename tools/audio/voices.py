"""Voix des personnages des cinématiques : un babillage à la « Animal Crossing » par personnage, dans le style de
l'Ancien Tobin : chaque lettre de la réplique déclenche une courte syllabe nette (« bi », « pa », « da »…), vite
enchaînées, à la hauteur et au timbre du personnage ; les grandes créatures parlent plus grave et plus lentement.

Usage : python3 tools/audio/voices.py [--only motif] [--png dossier]
Chaque voix a son timbre : hauteur, taille du conduit vocal (formants), souffle, raucité (orcs, dragons),
chuchotement (la Voix, l'Ourdisseur), écho (spectres, Sphinx), sifflantes (reptiliens). Elle produit N syllables
« consonne + voyelle », rangées dans une bande (assets/audio/voice/<voix>.ogg, une syllabe toutes les SLOT s) que le jeu enchaîne pendant que le texte s'écrit
(scripts/ui/voice_babble.gd), plus haut quand le personnage est joyeux, plus bas quand il est triste."""
import os, sys, argparse, hashlib
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
from synth import *

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "audio", "voice")
## Syllabes de la bande, dans l'ordre (le jeu choisit la syllabe d'après la lettre : voice_babble.gd, LETTER).
SYLS = [("", "a"), ("", "é"), ("", "i"), ("", "o"), ("", "u"), ("b", "a"), ("p", "i"), ("d", "a"), ("t", "é"), ("k", "a"),
        ("g", "o"), ("m", "o"), ("n", "a"), ("l", "i"), ("r", "a"), ("s", "a"), ("f", "o"), ("j", "i"), ("h", "a"), ("w", "a"),
        ("z", "u"), ("v", "é")]
N_SYL = len(SYLS)
SLOT = 0.22 ## place d'une syllabe dans la bande de la voix (s)

VOWELS = {"a": (800, 1200, 2700), "e": (450, 1850, 2600), "i": (310, 2250, 3000), "o": (480, 850, 2600), "u": (330, 800, 2400),
          "é": (390, 2100, 2800), "ou": (340, 700, 2300), "an": (650, 1000, 2500)}

# id -> paramètres : f0 (Hz), fs (taille du conduit : < 1 grand, > 1 petit), breath, growl, vib, whisper, echo,
# hiss (part de sifflantes), chorus (voix doublées), lp (filtre passe-bas, Hz), rate (débit : durée des syllabes)
VOICES = {
    "porteur": dict(f0=165, fs=1.05, breath=0.08),
    "brann": dict(f0=98, fs=0.86, breath=0.05, growl=0.25),
    "sylwen": dict(f0=232, fs=1.17, breath=0.22, vib=0.012),
    "nyx": dict(f0=190, fs=1.08, breath=0.25, echo=0.18),
    "krag": dict(f0=84, fs=0.8, breath=0.06, growl=0.6),
    "ignara": dict(f0=212, fs=1.1, breath=0.12, growl=0.15),
    "ssareth": dict(f0=138, fs=0.98, breath=0.3, hiss=0.6),
    "ysolde": dict(f0=242, fs=1.18, breath=0.15),
    "thalren": dict(f0=118, fs=0.96, breath=0.16, vib=0.03),
    "orrin": dict(f0=96, fs=0.88, breath=0.12, growl=0.15, echo=0.45, chorus=2),
    "prevote": dict(f0=202, fs=1.08, breath=0.06),
    "aurele": dict(f0=218, fs=1.12, breath=0.07),
    "ancien": dict(f0=112, fs=0.94, breath=0.18, vib=0.04),
    "voix": dict(f0=150, fs=1.0, whisper=1.0, echo=0.55, chorus=2),
    "vesper": dict(f0=116, fs=0.93, breath=0.22),
    "sphinx": dict(f0=172, fs=1.0, breath=0.08, echo=0.5, chorus=3),
    "durgan": dict(f0=104, fs=0.87, breath=0.08, growl=0.3),
    "fee": dict(f0=520, fs=1.45, breath=0.1, vib=0.02, rate=0.7),
    "varg": dict(f0=108, fs=0.92, breath=0.07, growl=0.35, rate=1.3),
    "sylvarche": dict(f0=68, fs=0.75, breath=0.05, growl=0.3, echo=0.3, rate=2.2),
    "gharok": dict(f0=78, fs=0.78, breath=0.05, growl=0.6, rate=1.6),
    "mere_dragon": dict(f0=118, fs=0.8, breath=0.15, growl=0.4, echo=0.3, rate=1.9),
    "cerf": dict(f0=72, fs=0.74, breath=0.08, echo=0.4, rate=2.2),
    "corvin": dict(f0=134, fs=1.0, breath=0.1, nasal=1.0),
    "leviathan": dict(f0=58, fs=0.7, breath=0.05, growl=0.2, echo=0.45, lp=1800, rate=2.4),
    "wyrm": dict(f0=64, fs=0.72, breath=0.2, growl=0.8, echo=0.25, rate=2.1),
    "ourdisseur": dict(f0=160, fs=1.05, whisper=1.0, echo=0.45, chorus=3, rate=1.7),
    "morvaen": dict(f0=124, fs=0.97, breath=0.15, echo=0.35),
    "narrateur": dict(quill=True),
}


def glottal(f0, dur, growl=0.0, vib=0.0):
    t = t_axis(dur)
    f = f0 * (1 + vib * np.sin(2 * np.pi * 5.5 * t)) * (1 + 0.004 * np.cumsum(rng.standard_normal(len(t))) / np.sqrt(len(t) + 1))
    src = saw(f, dur, 50)
    if growl > 0:
        sub = saw(f * 0.5, dur, 25)
        src = src + growl * 0.6 * sub
        src = drive(src * (1 + growl), 1 + growl * 2.5)
    return src


def vowel(f0, dur, v, p):
    fs = p.get("fs", 1.0)
    if p.get("whisper", 0.0) >= 1.0:
        src = noise(dur, "white") * 1.5
    else:
        src = glottal(f0, dur, p.get("growl", 0.0), p.get("vib", 0.0)) + noise(dur) * p.get("breath", 0.1) * 2.0
    out = silence(dur)
    for k, (fc, q, g) in enumerate(zip(VOWELS[v], (5, 7, 9), (1.0, 0.7, 0.35))):
        out += reson(src, fc * fs, q) * g
    if p.get("nasal", 0.0) > 0:
        out = out * 0.6 + reson(src, 250 * fs, 6) * 0.6 * p["nasal"] + reson(src, 2200 * fs, 10) * 0.2
    return out


def consonant(kind, p):
    fs = p.get("fs", 1.0)
    if kind in "ptk":
        lo, hi = {"p": (300, 1500), "t": (2500, 6000), "k": (1500, 3500)}[kind]
        d = 0.025
        return bp(noise(d), lo * fs, hi * fs) * env_exp(d, 0.008) * 0.8
    if kind in "bdg":
        lo, hi = {"b": (200, 1200), "d": (1500, 4500), "g": (1000, 3000)}[kind]
        d = 0.03
        return (bp(noise(d), lo * fs, hi * fs) * env_exp(d, 0.01) * 0.5 + sine(p.get("f0", 150), d) * env_exp(d, 0.02) * 0.3)
    if kind in "sfc":
        lo, hi = {"s": (4000, 9000), "f": (1500, 7000), "c": (2200, 6000)}[kind]
        d = 0.07 if kind == "s" else 0.06
        return bp(noise(d), lo, hi) * env_curve(d, [(0, 0), (0.02, 1), (d, 0)]) * (0.5 if kind == "s" else 0.35)
    if kind in "mnlr":
        d = 0.045
        f0 = p.get("f0", 150)
        hum = reson(glottal(f0, d, p.get("growl", 0.0)), 260 * fs, 6) * env_curve(d, [(0, 0), (0.01, 1), (d, 0.6)])
        if kind == "r":
            hum *= 0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 28 * t_axis(d)))
        return hum * 0.5
    return silence(0.01)


def syllable(p, i):
    """Syllabe i de la bande (SYLS[i]) pour la voix p : consonne brève et nette, voyelle courte (plus longue pour les
    grandes créatures, « rate »), petit contour de hauteur, comme le babillage de l'Ancien Tobin."""
    rate = p.get("rate", 1.0)
    c, v = SYLS[i]
    vd = rng.uniform(0.05, 0.065) * rate
    f0 = p["f0"] * rng.uniform(0.97, 1.05) * (1.04 if v in ("i", "é") else 1.0)
    contour = f0 * (1 + rng.uniform(-0.05, 0.07) * t_axis(vd) / vd)
    vw = vowel(contour, vd, v, p) * env_curve(vd, [(0, 0), (0.006, 1), (vd * 0.6, 0.9), (vd, 0)])
    parts = []
    if c:
        k = {"j": "c", "h": "f", "w": "b", "z": "s", "v": "f"}.get(c, c)
        cs = consonant(k, p)
        parts.append(cs[:int(0.03 * SR * min(rate, 1.6))])
    parts.append(vw)
    x = np.concatenate(parts)
    if p.get("hiss", 0.0) > 0 and c in ("s", "z", ""):
        x = np.concatenate([x, bp(noise(0.04), 4000, 9000) * env_curve(0.04, [(0, 1), (0.04, 0)]) * 0.3 * p["hiss"]])
    return x


def render_voice(name):
    p = VOICES[name]
    seed(int(hashlib.md5(name.encode()).hexdigest()[:8], 16))
    out = []
    for i in range(N_SYL):
        if p.get("quill"):
            # Le narrateur n'a pas de voix : la plume qui gratte le parchemin.
            d = 0.06
            x = bp(noise(d), 2500, 7000) * env_curve(d, [(0, 0), (0.01, 1), (d, 0)]) * rng.uniform(0.3, 0.6)
            out.append(normalize(x, -34.0, 0.5, 0.0))
            continue
        x = syllable(p, i)
        ch = int(p.get("chorus", 0))
        if ch > 1:
            # Voix doublées, légèrement désaccordées et décalées : spectre, Sphinx, l'Ourdisseur.
            layers = [x]
            for k in range(1, ch):
                q = pitch(x, rng.uniform(-0.6, 0.6) + (-12 if k == 2 else 0))
                layers.append(np.concatenate([silence(0.012 * k), q])[:len(x) + int(0.03 * SR)] * 0.6)
            n = max(len(l) for l in layers)
            x = sum(np.concatenate([l, np.zeros(n - len(l))]) for l in layers)
        if p.get("lp"):
            x = lp(x, p["lp"], 2)
        e = p.get("echo", 0.0)
        if e > 0:
            x = reverb(x, 0.45, e, 0.5, tail=0.12)
        x = lp(hp(x, 90, 2), 7500, 2)
        x = trim_tail(fade(x, 0.002, 0.012))
        out.append(normalize(x, -19.0, 0.85, 3.0))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--png", default="")
    a = ap.parse_args()
    total = 0
    for name in VOICES:
        if a.only not in name:
            continue
        syls = render_voice(name)
        # Une bande par voix : la syllabe i commence à i × SLOT secondes (lue par tranche dans le jeu).
        strip = silence(SLOT * len(syls))
        for i, x in enumerate(syls):
            x = x[:int((SLOT - 0.02) * SR)]
            strip[int(i * SLOT * SR):int(i * SLOT * SR) + len(x)] += fade(x, 0.0, 0.015)
        path = os.path.join(OUT, "%s.ogg" % name)
        write_ogg(path, strip, quality=0, out_sr=22050)
        total += os.path.getsize(path)
        if a.png:
            os.makedirs(a.png, exist_ok=True)
            spectrogram_png(os.path.join(a.png, name + ".png"), np.concatenate([np.concatenate([s, silence(0.04)]) for s in syls]), name)
        print("%-12s %d syllabes" % (name, len(syls)))
    print("total %.1f kB" % (total / 1024))


if __name__ == "__main__":
    main()
