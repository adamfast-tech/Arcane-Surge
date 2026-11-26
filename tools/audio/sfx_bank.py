"""Banque d'effets sonores d'Arcane Surge : sorts (par famille de timbre), combat, interface, météo.

Usage : python3 tools/audio/sfx_bank.py [--only motif] [--png dossier]
Chaque son est une fonction qui renvoie un signal mono ; il est normalisé à la sonie de sa catégorie puis encodé
dans assets/audio/sfx/<nom>.ogg. Les familles de sorts (FAMILIES) ont toutes : cast (lancement), hit (impact
léger), boom (gros impact) et loop (zone qui dure, bouclable) ; certaines ont aussi proj (projectile).
Le jeu choisit la famille d'un sort (discipline, école, élément) et varie hauteur et couches selon le sort
(scripts/core/audio.gd, SpellAudio)."""
import os, sys, argparse, hashlib
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
from synth import *

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "audio", "sfx")

# Sonie visée par catégorie (dB, mesure de synth.loudness) : l'équilibre du mixage se règle ici.
LOUD = {"cast": -19.0, "hit": -18.0, "boom": -15.5, "loop": -24.0, "proj": -22.0, "ui": -22.0, "battle": -20.0,
        "small": -25.0, "big": -15.0, "summon": -19.0, "weather": -17.0, "roar": -16.5}

REG = {}


def snd(name, cat, loop=False):
    def deco(fn):
        REG[name] = (fn, cat, loop)
        return fn
    return deco


def add(*xs):
    """Somme de signaux de longueurs différentes (complétés par du silence)."""
    n = max(len(x) for x in xs)
    out = np.zeros(n)
    for x in xs:
        out[:len(x)] += x
    return out


def midi_hz(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# ================================================================== briques de design sonore

def whoosh(dur, f0, f1, peak=0.5, q=1.5, color="pink"):
    """Souffle qui passe : bruit filtré dont la fréquence glisse, enveloppe en cloche."""
    n = noise(dur, color)
    x = filt_sweep(n, sweep(dur, f0, f1), "band", q)
    e = env_curve(dur, [(0, 0), (dur * peak, 1), (dur, 0)])
    return x * e ** 1.5


def embers(dur, density=30):
    """Braises qui crépitent : petits claquements de hauteurs variées (pas un bruit blanc)."""
    out = silence(dur)
    for _ in range(int(density * dur)):
        t0 = rng.uniform(0, dur - 0.02)
        f = rng.uniform(900, 5000)
        d = rng.uniform(0.004, 0.015)
        k = bp(noise(d + 0.01), f * 0.7, f * 1.4) * env_exp(d + 0.01, d * 0.4)
        out = mix(dur, (0, out, 1), (t0, k, rng.uniform(0.3, 1.0)))
    return out


def rustle(dur, density=60, lo=1500, hi=6000):
    """Bruissement de feuilles, sable, gravier : grains de bruit filtrés de 10 à 40 ms."""
    out = silence(dur)
    for _ in range(int(density * dur)):
        t0 = rng.uniform(0, max(0.001, dur - 0.05))
        ln = rng.uniform(0.01, 0.04)
        g = bp(noise(ln), lo, hi) * np.hanning(int(ln * SR))
        out = mix(dur, (0, out, 1), (t0, g, rng.uniform(0.2, 1.0)))
    return out


def thump(f, dur=0.4, drop=1.5, click=0.3):
    t = t_axis(dur)
    body = sine(f * (1 + drop * np.exp(-t / 0.04)), dur) * env_exp(dur, dur * 0.35)
    ck = hp(noise(dur), 1500) * env_exp(dur, 0.006)
    return body + ck * click


def rumble(dur, fc=140, am=3.0, depth=0.5):
    x = lp(noise(dur, "brown"), fc, 2)
    mod = 1 - depth + depth * (0.5 + 0.5 * np.sin(2 * np.pi * am * t_axis(dur) + rng.uniform(0, 6)))
    return x * mod


def sparkle(dur, n=14, f_lo=2500, f_hi=7000, decay=0.12, t_end=None):
    out = silence(dur)
    t_end = dur * 0.7 if t_end is None else t_end
    for _ in range(n):
        t0 = rng.uniform(0, t_end)
        f = rng.uniform(f_lo, f_hi)
        d = min(dur - t0, decay * rng.uniform(0.6, 1.6))
        if d <= 0.01:
            continue
        p = fm(f, 2.0, 0.45, d, env_exp(d, d * 0.3)) * env_exp(d, d * 0.3)
        out = mix(dur, (0, out, 1), (t0, p, rng.uniform(0.15, 0.45)))
    return lp(out, 9000)


def bell(f, dur, bright=1.0):
    ratios = [0.5, 1.0, 1.183, 1.506, 2.0, 2.514, 2.662, 3.011, 4.166]
    amps = [0.5, 1.0, 0.6, 0.5, 0.45, 0.3, 0.25, 0.2, 0.12]
    decs = [dur * 0.9, dur * 0.6, dur * 0.4, dur * 0.35, dur * 0.3, dur * 0.2, dur * 0.18, dur * 0.12, dur * 0.08]
    return modal([f * r for r in ratios], [a * (bright if i > 3 else 1) for i, a in enumerate(amps)], decs, dur)


def glass_shatter(dur, n=40, lo=2500, hi=9000):
    out = hp(noise(dur), 2500) * env_exp(dur, 0.05) * 0.8
    for _ in range(n):
        t0 = rng.exponential(0.08)
        if t0 >= dur - 0.02:
            continue
        f = rng.uniform(lo, hi)
        d = min(dur - t0, rng.uniform(0.05, 0.3))
        ping = modal([f, f * 1.47, f * 2.09], [1, 0.5, 0.3], [d * 0.4, d * 0.25, d * 0.15], d)
        out = mix(dur, (0, out, 1), (t0, ping, rng.uniform(0.15, 0.5)))
    return out


def metal_ring(f, dur, amt=1.0):
    ratios = [1.0, 2.76, 5.40, 8.93, 13.34]
    x = modal([f * r for r in ratios], [1, 0.5, 0.28, 0.14, 0.07], [dur * 0.5, dur * 0.3, dur * 0.18, dur * 0.1, dur * 0.06], dur) * amt
    return lp(x, 8000)


def wood_knock(f=300, dur=0.25):
    return modal([f, f * 2.3, f * 3.9], [1, 0.5, 0.25], [0.05, 0.03, 0.02], dur) + bp(noise(dur), 400, 3000) * env_exp(dur, 0.01) * 0.5


def bone_clicks(dur, n=10, lo=1200, hi=3500):
    out = silence(dur)
    for _ in range(n):
        t0 = rng.uniform(0, dur * 0.8)
        f = rng.uniform(lo, hi)
        d = 0.05
        k = modal([f, f * 1.8, f * 2.9], [1, 0.5, 0.3], [0.012, 0.008, 0.005], d) + bp(noise(d), 800, 5000) * env_exp(d, 0.004) * 0.6
        out = mix(dur, (0, out, 1), (t0, k, rng.uniform(0.3, 0.9)))
    return out


def formant_voice(f0, dur, vowels=("a", "o"), growl=0.0, breath=0.1, vib=5.0, vib_amt=0.01):
    """Voix synthétique : impulsions glottales filtrées par les formants des voyelles (rugissements,
    gémissements d'esprits, chœurs étranges)."""
    F = {"a": (800, 1150, 2900), "e": (400, 1600, 2700), "i": (300, 2300, 3000), "o": (450, 800, 2830), "u": (325, 700, 2530),
         "ou": (350, 600, 2400), "ae": (650, 1700, 2600)}
    t = t_axis(dur)
    f = np.asarray(f0, dtype=np.float64) if np.ndim(f0) else np.full(len(t), float(f0))
    f = f[:len(t)] * (1 + vib_amt * np.sin(2 * np.pi * vib * t)) * (1 + growl * 0.08 * rng.standard_normal(len(t)).cumsum() / np.sqrt(len(t)))
    src = saw(f, dur, 60)
    if growl > 0:
        src = src * (1 + growl * np.sin(2 * np.pi * f * 0.5 * t))
        src = drive(src, 1 + growl * 3)
    src = src + noise(dur) * breath
    out = silence(dur)
    seg = len(vowels)
    for i, v in enumerate(vowels):
        a, b = int(len(t) * i / seg), int(len(t) * (i + 1) / seg)
        part = silence(dur)
        for k, (fc, q) in enumerate(zip(F[v], (6, 8, 10))):
            part += reson(src, fc, q) * (1.0, 0.6, 0.3)[k]
        w = np.zeros(len(t))
        w[a:b] = 1
        w = lp(w, 20, 1)
        out += part * w
    return out


def heartbeat(dur, bpm=70):
    out = silence(dur)
    per = 60 / bpm
    t0 = 0.0
    while t0 < dur:
        out = mix(dur, (0, out, 1), (t0, thump(55, 0.3, 0.6, 0.05), 1.0), (t0 + 0.22, thump(50, 0.3, 0.5, 0.05), 0.7))
        t0 += per
    return out


def splash(dur, lo=400, hi=4000, drops=12):
    x = bp(noise(dur), lo, hi) * env_curve(dur, [(0, 0), (0.01, 1), (0.15, 0.5), (dur, 0)])
    for _ in range(drops):
        t0 = rng.uniform(0.02, dur * 0.8)
        f = rng.uniform(600, 1600)
        d = 0.08
        drop = sine(sweep(d, f, f * 2.2), d) * env_exp(d, 0.02)
        x = mix(dur, (0, x, 1), (t0, drop, rng.uniform(0.1, 0.3)))
    return x


def zap(dur, f0=2000, f1=200):
    car = sweep(dur, f0, f1)
    x = fm(car, 1.5, 6, dur, env_exp(dur, dur * 0.5)) * env_exp(dur, dur * 0.4)
    return x + bp(crackle(dur, 200, 0.002), 2000, 8000) * env_exp(dur, dur * 0.3) * 0.4


def thunder(dur=2.4, crack=1.0):
    ck = hp(noise(0.12), 800) * env_exp(0.12, 0.03) * 1.5 * crack
    snap = bp(crackle(0.4, 200, 0.003), 1500, 8000) * env_exp(0.4, 0.08)
    roll = rumble(dur, 220, 2.5, 0.6) * env_curve(dur, [(0, 0), (0.05, 1), (0.5, 0.8), (dur, 0)]) * 1.6
    return mix(dur, (0, ck, 1), (0, snap, 0.8), (0.02, roll, 1))


def make_loop(x, xfade=0.4):
    """Boucle sans couture : la fin est fondue dans le début."""
    n = int(xfade * SR)
    a = x[:n].copy()
    b = x[-n:].copy()
    w = np.linspace(0, 1, n)
    body = x[n:-n].copy() if len(x) > 2 * n else x.copy()
    head = b * (1 - w) + a * w
    return np.concatenate([head, body])


def gm_chord(prog, notes, dur, vel=100, t=0.0, chan=0):
    return gm([(t, n, dur * 0.8, vel) for n in notes], prog, dur, chan)


def drum(note, dur=1.0, vel=110):
    return gm([(0, note, 0.2, vel)], 0, dur, 9)


# ================================================================== familles de sorts
# Chaque famille : cast, hit, boom, loop ; proj facultatif.

FAMILIES = {}


def family(name):
    def deco(cls):
        FAMILIES[name] = cls
        return cls
    return deco


@family("feu")
class Feu:
    @staticmethod
    def cast(v):
        d = 0.9
        ign = whoosh(d, 300, 2500, 0.55, 1.2) * 1.2
        flare = lp(noise(d, "pink"), 1800) * env_curve(d, [(0, 0), (0.45, 0.2), (0.6, 1), (d, 0)])
        crk = embers(d, 35) * env_curve(d, [(0, 0), (0.5, 1), (d, 0)]) * 0.18
        return mix(d, (0, ign, 1), (0, flare, 0.8), (0, crk, 1))

    @staticmethod
    def hit(v):
        d = 0.9
        boom = lp(noise(d, "brown"), 400) * env_exp(d, 0.18) * 1.2
        body = lp(noise(d, "pink"), 3000) * env_exp(d, 0.1)
        crk = embers(d, 30) * env_curve(d, [(0, 0), (0.03, 1), (d, 0)]) * 0.15
        return mix(d, (0, boom, 1), (0, body, 0.8), (0.02, crk, 1), (0, thump(70, 0.5, 1.2, 0.2), 0.7))

    @staticmethod
    def boom(v):
        d = 1.8
        boom = lp(noise(d, "brown"), 300) * env_exp(d, 0.4) * 1.3
        body = lp(noise(d, "pink"), 2500) * env_exp(d, 0.2)
        crk = embers(d, 40) * env_curve(d, [(0, 0), (0.05, 1), (0.8, 0.2), (d, 0)]) * 0.12
        sub = sine(sweep(d, 80, 32), d) * env_exp(d, 0.3)
        return reverb(mix(d, (0, boom, 1), (0, body, 0.8), (0.02, crk, 1), (0, sub, 0.9)), 0.5, 0.18)

    @staticmethod
    def loop(v):
        d = 4.0
        roar = lp(noise(d, "brown"), 500) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.7 * t_axis(d)))
        crk = embers(d, 25) * 0.16
        hiss = bp(noise(d), 2000, 6000) * 0.05
        return make_loop(roar + crk + hiss)

    @staticmethod
    def proj(v):
        d = 0.8
        return whoosh(d, 200, 1400, 0.7, 1.0) + embers(d, 25) * env_curve(d, [(0, 0), (0.6, 1), (d, 0)]) * 0.12


@family("givre")
class Givre:
    @staticmethod
    def cast(v):
        d = 1.0
        breath = whoosh(d, 3000, 900, 0.4, 1.0, "white") * 0.6
        shim = sparkle(d, 18, 3000, 8000, 0.25)
        tone = fm(midi_hz(88), 3.5, 1.0, d, env_exp(d, 0.4)) * env_exp(d, 0.5) * 0.25
        return mix(d, (0, breath, 1), (0.05, shim, 1.0), (0.1, tone, 1))

    @staticmethod
    def hit(v):
        d = 0.8
        return mix(d, (0, glass_shatter(d, 30), 1), (0, thump(110, 0.3, 0.8, 0.2), 0.5))

    @staticmethod
    def boom(v):
        d = 1.6
        crack = hp(noise(0.3), 1500) * env_exp(0.3, 0.05)
        return reverb(mix(d, (0, crack, 1), (0, glass_shatter(d, 70, 2000, 10000), 1.2), (0, thump(60, 0.8, 0.6, 0.3), 0.8),
                          (0.05, rumble(d, 200) * env_exp(d, 0.4), 0.6)), 0.55, 0.2)

    @staticmethod
    def loop(v):
        d = 4.0
        wind = filt_sweep(noise(d, "pink"), 900 + 600 * np.sin(2 * np.pi * 0.25 * t_axis(d)), "band", 1.5)
        tink = sparkle(d, 22, 3000, 9000, 0.2, d * 0.95) * 0.5
        return make_loop(wind + tink)

    @staticmethod
    def proj(v):
        d = 0.7
        return whoosh(d, 1500, 4000, 0.6, 1.5, "white") * 0.8 + sparkle(d, 8, 4000, 9000, 0.1) * 0.5


@family("foudre")
class Foudre:
    @staticmethod
    def cast(v):
        d = 0.9
        hum = saw(sweep(d, 60, 240), d) * env_curve(d, [(0, 0), (0.7, 1), (d, 0)]) * 0.25
        hum = lp(hum, 2500)
        stat = bp(crackle(d, 120, 0.002), 2500, 7000) * env_curve(d, [(0, 0.2), (0.75, 1), (d, 0)]) * 0.35
        return mix(d, (0, hum, 1), (0, stat, 1), (0.72, zap(0.18, 4000, 800), 0.5))

    @staticmethod
    def hit(v):
        d = 0.9
        return mix(d, (0, zap(0.25, 5000, 300), 1), (0.02, thunder(0.85, 0.8), 0.6))

    @staticmethod
    def boom(v):
        d = 2.6
        return reverb(mix(d, (0, zap(0.3, 6000, 200), 0.8), (0.01, thunder(2.5, 1.2), 1.0)), 0.6, 0.2)

    @staticmethod
    def loop(v):
        d = 4.0
        stat = bp(crackle(d, 70, 0.002), 2500, 7000) * 0.3
        hum = lp(saw(120, d) * 0.08, 800) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.5 * t_axis(d)))
        x = stat + hum
        for k in range(3):
            x = mix(d, (0, x, 1), (rng.uniform(0.3, d - 0.5), zap(0.2, 4000, 500), 0.4))
        return make_loop(x)

    @staticmethod
    def proj(v):
        d = 0.5
        return zap(d, 3000, 1200) * 0.8


@family("nature")
class Nature:
    @staticmethod
    def cast(v):
        d = 1.0
        rustle_ = rustle(d, 90) * env_curve(d, [(0, 0), (0.4, 1), (d, 0)])
        creak = formant_voice(sweep(d, 70, 95), d, ("o", "u"), 0.2, 0.0, 2, 0.02) * env_curve(d, [(0, 0), (0.3, 1), (0.8, 0.6), (d, 0)]) * 0.25
        chime = gm_chord(46, [67, 71, 74], d, 80)  # harpe
        return mix(d, (0, rustle_, 0.6), (0, creak, 1), (0.1, chime, 0.5))

    @staticmethod
    def hit(v):
        d = 0.8
        crack = wood_knock(220, 0.4) + wood_knock(330, 0.4) * 0.6
        tear = bp(noise(d), 300, 3000) * env_exp(d, 0.12)
        return mix(d, (0, crack, 1), (0.01, tear, 0.7), (0, thump(80, 0.4, 0.8, 0.1), 0.6))

    @staticmethod
    def boom(v):
        d = 1.6
        rise = rustle(d, 120, 600, 4000) * env_curve(d, [(0, 0), (0.15, 1), (d, 0)]) * 0.7
        return reverb(mix(d, (0, rise, 0.9), (0, wood_knock(150, 0.6), 1.2), (0.08, wood_knock(260, 0.5), 0.8),
                          (0, rumble(d, 160) * env_exp(d, 0.5), 0.8)), 0.5, 0.2)

    @staticmethod
    def loop(v):
        d = 4.0
        leaves = rustle(d, 50) * 0.35
        creak = rumble(d, 300, 0.3, 0.8) * 0.4
        return make_loop(leaves + creak)


@family("ombre")
class Ombre:
    @staticmethod
    def cast(v):
        d = 1.1
        swell = whoosh(d, 150, 900, 0.75, 1.0, "pink") * 1.2
        whisper = formant_voice(sweep(d, 140, 110), d, ("i", "e", "a"), 0.0, 1.5, 4, 0.0) * 0.12
        whisper = hp(whisper, 1200)
        low = sine(sweep(d, 55, 40), d) * env_curve(d, [(0, 0), (0.8, 1), (d, 0)]) * 0.5
        return mix(d, (0, swell, 1), (0, whisper, 1), (0, low, 1))

    @staticmethod
    def hit(v):
        d = 1.0
        rev = whoosh(0.4, 200, 1500, 0.95, 1.0) * 0.8
        boom = thump(50, d, 1.0, 0.1) + lp(noise(d, "brown"), 200) * env_exp(d, 0.25)
        return mix(d + 0.4, (0, rev, 1), (0.38, boom, 1.0), (0.38, sine(sweep(d, 120, 40), d) * env_exp(d, 0.3), 0.4))

    @staticmethod
    def boom(v):
        d = 2.0
        rev = whoosh(0.6, 120, 1200, 0.95, 0.8) * 1.0
        void = lp(noise(d, "brown"), 160) * env_exp(d, 0.6) * 1.5
        drone = sum(sine(f, d) for f in (41, 61.5, 82)) * env_exp(d, 0.6) * 0.3
        return reverb(mix(d + 0.6, (0, rev, 1), (0.55, void, 1), (0.55, drone, 1), (0.55, thump(45, 1.0, 0.8, 0.1), 1)), 0.7, 0.3)

    @staticmethod
    def loop(v):
        d = 4.0
        t = t_axis(d)
        drone = (sine(55, d) + 0.5 * sine(82.4, d) + 0.3 * sine(110.6, d)) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.5 * t)) * 0.4
        swirl = filt_sweep(noise(d, "pink"), 500 + 350 * np.sin(2 * np.pi * 0.5 * t), "band", 2) * 0.6
        return make_loop(drone + swirl)


@family("lumiere")
class Lumiere:
    @staticmethod
    def cast(v):
        d = 1.2
        ch = gm_chord(52, [72, 76, 79], d, 90)  # chœur « ah »
        bel = gm([(0.05, 84, 0.6, 80), (0.15, 88, 0.6, 70)], 9, d)  # glockenspiel
        shim = sparkle(d, 12, 4000, 9000, 0.25)
        return mix(d, (0, ch, 1.0), (0, bel, 0.6), (0.1, shim, 0.6))

    @staticmethod
    def hit(v):
        d = 1.0
        return mix(d, (0, bell(midi_hz(76), d, 0.8), 0.6), (0, thump(120, 0.3, 0.5, 0.2), 0.4), (0, sparkle(d, 10, 5000, 10000, 0.2), 0.7))

    @staticmethod
    def boom(v):
        d = 2.0
        ch = gm_chord(52, [60, 64, 67, 72], d, 110)
        bl = gm([(0, 72, 1.5, 110)], 14, d)  # cloche tubulaire
        return reverb(mix(d, (0, ch, 1), (0, bl, 0.9), (0, thump(70, 0.8, 0.8, 0.2), 0.7), (0.05, sparkle(d, 25, 3000, 10000, 0.3), 0.6)), 0.7, 0.3)

    @staticmethod
    def loop(v):
        d = 4.0
        pad = gm([(0, 72, 3.9, 70), (0, 76, 3.9, 60), (0, 79, 3.9, 60)], 53, d)  # voix « oh »
        shim = sparkle(d, 16, 4000, 9000, 0.3, d * 0.95) * 0.4
        return make_loop(pad + shim)


@family("arcane")
class Arcane:
    @staticmethod
    def cast(v):
        d = 0.9
        notes = [72, 76, 79, 84, 88]
        arp = gm([(i * 0.07, n, 0.4, 90) for i, n in enumerate(notes)], 8, d)  # célesta
        shim = filt_sweep(saw(sweep(d, 300, 1200), d), sweep(d, 600, 5000), "band", 3) * env_curve(d, [(0, 0), (0.5, 1), (d, 0)]) * 0.15
        return mix(d, (0, arp, 1), (0, shim, 1))

    @staticmethod
    def hit(v):
        d = 0.8
        burst = fm(sweep(d, 1200, 300), 2.01, 4, d, env_exp(d, 0.2)) * env_exp(d, 0.2)
        return mix(d, (0, burst, 0.6), (0, thump(90, 0.3, 0.8, 0.2), 0.6), (0, sparkle(d, 10, 2500, 7000, 0.15), 0.5))

    @staticmethod
    def boom(v):
        d = 1.8
        burst = fm(sweep(d, 900, 150), 1.5, 6, d, env_exp(d, 0.4)) * env_exp(d, 0.4)
        return reverb(mix(d, (0, burst, 0.6), (0, thump(55, 0.8, 1.0, 0.2), 0.9), (0, sparkle(d, 25, 2000, 8000, 0.3), 0.6)), 0.6, 0.25)

    @staticmethod
    def loop(v):
        d = 4.0
        t = t_axis(d)
        war = sine(220 * (1 + 0.02 * np.sin(2 * np.pi * 6 * t)), d) * 0.2 + sine(330 * (1 + 0.03 * np.sin(2 * np.pi * 5 * t)), d) * 0.12
        return make_loop(war * (0.7 + 0.3 * np.sin(2 * np.pi * 0.5 * t)) + sparkle(d, 12, 3000, 8000, 0.2, d * 0.95) * 0.3)


@family("terre")
class Terre:
    @staticmethod
    def cast(v):
        d = 0.9
        grind = rustle(d, 150, 200, 2500) * env_curve(d, [(0, 0), (0.6, 1), (d, 0)])
        return mix(d, (0, grind, 1), (0, rumble(d, 180) * env_curve(d, [(0, 0), (0.6, 1), (d, 0)]), 0.8))

    @staticmethod
    def hit(v):
        d = 0.9
        rocks = rustle(d, 80, 300, 3000) * env_exp(d, 0.2)
        return mix(d, (0, thump(60, 0.6, 1.2, 0.4), 1.2), (0.01, rocks, 0.8))

    @staticmethod
    def boom(v):
        d = 2.2
        rocks = rustle(d, 100, 200, 2500) * env_curve(d, [(0, 0), (0.05, 1), (d, 0)])
        return reverb(mix(d, (0, thump(42, 1.2, 1.0, 0.4), 1.4), (0, rumble(d, 120) * env_exp(d, 0.7), 1.3), (0.03, rocks, 0.7)), 0.5, 0.15)

    @staticmethod
    def loop(v):
        d = 4.0
        return make_loop(rumble(d, 130, 1.3, 0.5) * 1.2 + rustle(d, 25, 300, 2000) * 0.25)


@family("poison")
class Poison:
    @staticmethod
    def cast(v):
        d = 0.9
        bub = silence(d)
        for _ in range(14):
            t0 = rng.uniform(0, d * 0.8)
            f = rng.uniform(300, 900)
            dd = 0.09
            bub = mix(d, (0, bub, 1), (t0, sine(sweep(dd, f, f * 2.5), dd) * env_exp(dd, 0.03), rng.uniform(0.2, 0.5)))
        hiss = bp(noise(d), 3000, 7000) * env_curve(d, [(0, 0), (0.5, 0.6), (d, 0)])
        return mix(d, (0, bub, 1), (0, hiss, 0.15))

    @staticmethod
    def hit(v):
        d = 0.8
        return mix(d, (0, splash(d, 300, 2500, 10), 1), (0.02, bp(noise(d), 2500, 7000) * env_exp(d, 0.2), 0.15))

    @staticmethod
    def boom(v):
        d = 1.5
        return reverb(mix(d, (0, splash(d, 200, 2500, 25), 1.2), (0, thump(60, 0.6, 0.6, 0.2), 0.7),
                          (0.05, bp(noise(d), 2500, 7000) * env_exp(d, 0.3), 0.15)), 0.5, 0.2)

    @staticmethod
    def loop(v):
        d = 4.0
        bub = silence(d)
        for _ in range(40):
            t0 = rng.uniform(0, d - 0.1)
            f = rng.uniform(250, 800)
            dd = 0.09
            bub = mix(d, (0, bub, 1), (t0, sine(sweep(dd, f, f * 2.5), dd) * env_exp(dd, 0.03), rng.uniform(0.15, 0.4)))
        flies = sum(saw(f * (1 + 0.04 * np.sin(2 * np.pi * r * t_axis(d))), d, 12) for f, r in ((210, 7), (236, 5), (190, 9))) * 0.03
        return make_loop(bub + bp(flies, 150, 2000))


@family("sang")
class Sang:
    @staticmethod
    def cast(v):
        d = 1.1
        return mix(d, (0, heartbeat(d, 90), 1.2), (0.1, splash(0.6, 200, 1500, 6), 0.4), (0, whoosh(d, 150, 600, 0.8, 1.0, "brown"), 0.5))

    @staticmethod
    def hit(v):
        d = 0.7
        squelch = lp(splash(d, 150, 1800, 8), 2000)
        return mix(d, (0, squelch, 1.1), (0, thump(80, 0.3, 0.8, 0.1), 0.6))

    @staticmethod
    def boom(v):
        d = 1.6
        return reverb(mix(d, (0, lp(splash(d, 120, 1500, 20), 1800), 1.3), (0, thump(48, 0.9, 1.0, 0.1), 1.0), (0, heartbeat(d, 60), 0.6)), 0.5, 0.2)

    @staticmethod
    def loop(v):
        d = 4.0
        return make_loop(heartbeat(d, 75) * 0.9 + lp(noise(d, "brown"), 300) * 0.3)


@family("os")
class Os:
    @staticmethod
    def cast(v):
        d = 0.9
        return mix(d, (0, bone_clicks(d, 16), 1), (0, rumble(d, 180) * env_curve(d, [(0, 0), (0.5, 1), (d, 0)]), 0.5))

    @staticmethod
    def hit(v):
        d = 0.7
        crack = bp(noise(0.08), 1000, 5000) * env_exp(0.08, 0.01)
        return mix(d, (0, crack, 1.2), (0, bone_clicks(d, 10, 1500, 4000), 0.8), (0, thump(90, 0.3, 0.6, 0.2), 0.6))

    @staticmethod
    def boom(v):
        d = 1.4
        return reverb(mix(d, (0, bone_clicks(d, 40, 900, 4000), 1.2), (0, thump(55, 0.7, 1.0, 0.3), 1.0), (0, rumble(d, 150) * env_exp(d, 0.4), 0.7)), 0.5, 0.2)

    @staticmethod
    def loop(v):
        d = 4.0
        return make_loop(bone_clicks(d, 50, 800, 3500) * 0.7 + rumble(d, 140, 0.5, 0.4) * 0.6)


@family("ames")
class Ames:
    @staticmethod
    def cast(v):
        d = 1.3
        wail = formant_voice(sweep(d, 520, 380), d, ("ou", "o", "a"), 0.0, 0.4, 5, 0.03) * env_curve(d, [(0, 0), (0.3, 1), (d, 0)])
        return reverb(mix(d, (0, wail, 0.5), (0, whoosh(d, 300, 1200, 0.5, 1.0), 0.6)), 0.8, 0.4, tail=0.6)

    @staticmethod
    def hit(v):
        d = 0.9
        wisp = formant_voice(sweep(d, 700, 300), d, ("i", "ou"), 0.0, 0.6, 6, 0.04) * env_exp(d, 0.3)
        return reverb(mix(d, (0, wisp, 0.5), (0, whoosh(0.5, 2000, 300, 0.2, 1.2), 0.8)), 0.7, 0.35)

    @staticmethod
    def boom(v):
        d = 1.8
        chorus_ = sum(formant_voice(sweep(d, f, f * 0.6), d, ("a", "ou"), 0.0, 0.5, 5, 0.04) for f in (300, 380, 450)) * 0.3
        return reverb(mix(d, (0, chorus_ * env_exp(d, 0.6), 0.6), (0, thump(55, 0.8, 0.8, 0.1), 0.8), (0, whoosh(d, 2000, 200, 0.15, 1.0), 0.7)), 0.8, 0.4)

    @staticmethod
    def loop(v):
        d = 4.0
        t = t_axis(d)
        moan = formant_voice(300 + 60 * np.sin(2 * np.pi * 0.25 * t), d, ("ou", "o"), 0.0, 0.5, 4, 0.03) * 0.25
        return make_loop(moan + filt_sweep(noise(d, "pink"), 800 + 400 * np.sin(2 * np.pi * 0.3 * t), "band", 2) * 0.4)


@family("malefice")
class Malefice:
    @staticmethod
    def cast(v):
        d = 1.2
        wh = sum(hp(formant_voice(sweep(d, f, f * 1.1), d, ("i", "e", "a", "i"), 0.0, 2.0, 3, 0.0), 1500) * rng.uniform(0.5, 1)
                 for f in (120, 150, 180)) * 0.15
        dis = sine(sweep(d, 466, 440), d) * env_curve(d, [(0, 0), (0.6, 1), (d, 0)]) * 0.08 + sine(sweep(d, 494, 466), d) * env_curve(d, [(0, 0), (0.6, 1), (d, 0)]) * 0.08
        return reverb(mix(d, (0, wh, 1), (0, dis, 1)), 0.7, 0.35, tail=0.4)

    @staticmethod
    def hit(v):
        d = 0.8
        sting = fm(sweep(d, 900, 600), 1.414, 3, d, env_exp(d, 0.2)) * env_exp(d, 0.25) * 0.5
        return mix(d, (0, sting, 1), (0, whoosh(0.4, 400, 2000, 0.3, 1.0), 0.5), (0, thump(70, 0.3, 0.5, 0.1), 0.4))

    @staticmethod
    def boom(v):
        d = 1.8
        sting = fm(sweep(d, 700, 300), 1.414, 5, d, env_exp(d, 0.5)) * env_exp(d, 0.6) * 0.5
        return reverb(mix(d, (0, sting, 1), (0, thump(45, 1.0, 0.8, 0.1), 0.9), (0, Malefice.cast(v)[:int(d * SR)], 0.4)), 0.7, 0.3)

    @staticmethod
    def loop(v):
        d = 4.0
        t = t_axis(d)
        wh = hp(formant_voice(140 + 20 * np.sin(2 * np.pi * 0.3 * t), d, ("i", "e", "a", "o"), 0.0, 2.0, 3, 0.0), 1500) * 0.12
        return make_loop(wh + sine(58, d) * 0.15)


@family("morts")
class Morts:
    @staticmethod
    def cast(v):
        d = 1.2
        dirt = rustle(d, 80, 200, 2000) * env_curve(d, [(0, 0), (0.4, 1), (d, 0)])
        groan = formant_voice(sweep(d, 85, 70), d, ("o", "a"), 0.6, 0.2, 3, 0.03) * env_curve(d, [(0, 0), (0.5, 1), (d, 0)]) * 0.35
        return mix(d, (0, dirt, 0.8), (0, groan, 1), (0.2, bone_clicks(1.0, 12), 0.7), (0, rumble(d, 150) * env_curve(d, [(0, 0), (0.5, 1), (d, 0)]), 0.6))

    @staticmethod
    def hit(v):
        return Os.hit(v)

    @staticmethod
    def boom(v):
        d = 1.8
        bl = gm([(0, 43, 1.6, 110)], 14, d)  # glas
        return reverb(mix(d, (0, bl, 0.9), (0, Morts.cast(v)[:int(d * SR)], 0.8), (0, thump(48, 0.9, 0.8, 0.1), 0.8)), 0.7, 0.3)

    @staticmethod
    def loop(v):
        d = 4.0
        return make_loop(rumble(d, 150, 0.6, 0.5) * 0.6 + bone_clicks(d, 25, 900, 3000) * 0.5)


@family("fleche")
class Fleche:
    @staticmethod
    def cast(v):
        d = 0.6
        creak = rustle(0.3, 60, 600, 3000) * env_curve(0.3, [(0, 0), (0.25, 1), (0.3, 0)]) * 0.4
        string = pluck(98, 0.5, 0.9, 0.992) * env_exp(0.5, 0.12)
        thwip = bp(noise(0.25), 1500, 7000) * env_exp(0.25, 0.04)
        return mix(d, (0, creak, 1), (0.28, string, 1), (0.29, thwip, 0.7))

    @staticmethod
    def hit(v):
        d = 0.5
        thunk = add(wood_knock(240, 0.3) * 0.9, thump(130, 0.25, 0.6, 0.5) * 0.6)
        return mix(d, (0, thunk, 1), (0, bp(noise(0.1), 2000, 6000) * env_exp(0.1, 0.01), 0.5))

    @staticmethod
    def boom(v):
        # Volée : des dizaines de flèches qui sifflent puis se plantent.
        d = 2.0
        out = silence(d)
        for _ in range(16):
            t0 = rng.uniform(0, 0.7)
            w = whoosh(0.4, rng.uniform(2500, 4000), rng.uniform(700, 1200), 0.8, 3.0, "white") * 0.5
            out = mix(d, (0, out, 1), (t0, w, rng.uniform(0.3, 0.7)), (t0 + 0.4, Fleche.hit(v), rng.uniform(0.15, 0.4)))
        return out

    @staticmethod
    def loop(v):
        d = 4.0
        out = silence(d)
        for _ in range(18):
            t0 = rng.uniform(0, d - 0.6)
            out = mix(d, (0, out, 1), (t0, whoosh(0.4, 3500, 900, 0.8, 3.0, "white"), 0.4), (t0 + 0.38, Fleche.hit(v), 0.2))
        return make_loop(out)

    @staticmethod
    def proj(v):
        d = 0.5
        return whoosh(d, 4500, 1200, 0.75, 3.0, "white")


@family("piege")
class Piege:
    @staticmethod
    def cast(v):
        d = 0.6
        clk = add(metal_ring(1800, 0.15) * 0.4, bp(noise(0.05), 2000, 8000) * env_exp(0.05, 0.005))
        ratchet = silence(0.3)
        for k in range(5):
            ratchet = mix(0.3, (0, ratchet, 1), (k * 0.05, bp(noise(0.02), 1500, 6000) * env_exp(0.02, 0.003), 0.6))
        return mix(d, (0, ratchet, 1), (0.3, clk, 1))

    @staticmethod
    def hit(v):
        d = 0.6
        snap = add(metal_ring(900, 0.4) * 0.6, bp(noise(0.06), 1000, 6000) * env_exp(0.06, 0.008) * 1.2)
        return mix(d, (0, snap, 1), (0, thump(100, 0.3, 0.8, 0.3), 0.7))

    @staticmethod
    def boom(v):
        d = 1.4
        return mix(d, (0, Piege.hit(v), 1), (0.05, Feu.hit(v)[:int(0.9 * SR)], 0.6), (0, Terre.hit(v)[:int(0.9 * SR)], 0.6))

    @staticmethod
    def loop(v):
        d = 4.0
        out = rumble(d, 200, 0.4, 0.3) * 0.2
        for k in range(6):
            out = mix(d, (0, out, 1), (k * 0.66 + rng.uniform(0, 0.2), metal_ring(rng.uniform(800, 1600), 0.2), 0.25))
        return make_loop(out)


@family("astral")
class Astral:
    @staticmethod
    def cast(v):
        d = 1.2
        arp = gm([(i * 0.09, n, 0.6, 85) for i, n in enumerate([79, 84, 86, 91, 96])], 8, d)
        return reverb(mix(d, (0, arp, 1), (0, sparkle(d, 20, 5000, 11000, 0.3), 0.6)), 0.8, 0.35, tail=0.5)

    @staticmethod
    def hit(v):
        d = 0.8
        return reverb(mix(d, (0, gm([(0, 91, 0.5, 90)], 10, d), 0.8), (0, sparkle(d, 12, 5000, 11000, 0.2), 0.7), (0, thump(120, 0.3, 0.5, 0.3), 0.4)), 0.6, 0.3)

    @staticmethod
    def boom(v):
        d = 1.8
        st = gm([(0, 72, 1.5, 100), (0, 79, 1.5, 90), (0, 84, 1.5, 90)], 8, d)
        return reverb(mix(d, (0, st, 1), (0, thump(60, 0.8, 0.8, 0.2), 0.7), (0, sparkle(d, 40, 4000, 11000, 0.4), 0.7)), 0.8, 0.35)

    @staticmethod
    def loop(v):
        d = 4.0
        return make_loop(sparkle(d, 30, 4000, 11000, 0.4, d * 0.95) * 0.6 + gm([(0, 84, 3.9, 50), (0, 91, 3.9, 45)], 89, d) * 0.6)


@family("betes")
class Betes:
    @staticmethod
    def cast(v):
        d = 1.4
        # Cor de chasse puis cris de bêtes.
        horn = gm([(0, 55, 0.5, 100), (0.5, 62, 0.8, 110)], 60, d)
        return mix(d, (0, horn, 1))

    @staticmethod
    def hit(v):
        d = 0.6
        claw = bp(noise(0.2), 1000, 6000) * env_exp(0.2, 0.04)
        return mix(d, (0, claw, 0.8), (0.03, claw, 0.6), (0, thump(110, 0.3, 0.8, 0.2), 0.6))

    @staticmethod
    def boom(v):
        d = 1.6
        roar = formant_voice(sweep(d, 140, 90), d, ("a", "o"), 0.9, 0.3, 3, 0.03) * env_curve(d, [(0, 0), (0.1, 1), (d, 0)])
        return reverb(mix(d, (0, roar, 0.6), (0, thump(60, 0.6, 0.8, 0.2), 0.6)), 0.5, 0.2)

    @staticmethod
    def loop(v):
        d = 4.0
        out = rumble(d, 250, 0.5, 0.4) * 0.3
        for k in range(4):
            out = mix(d, (0, out, 1), (k + rng.uniform(0, 0.4), Betes.hit(v), 0.4))
        return make_loop(out)


@family("lame")
class Lame:
    @staticmethod
    def cast(v):
        d = 0.7
        draw = bp(noise(0.4), 2500, 9000) * env_curve(0.4, [(0, 0), (0.3, 1), (0.4, 0)]) * 0.4
        ring = metal_ring(1350, 0.6) * 0.5
        return mix(d, (0, draw, 1), (0.35, ring, 1), (0.35, whoosh(0.3, 2500, 800, 0.4, 2.0, "white"), 0.6))

    @staticmethod
    def hit(v):
        d = 0.6
        swish = whoosh(0.25, 3500, 900, 0.6, 2.5, "white")
        cut = bp(noise(0.08), 2000, 7000) * env_exp(0.08, 0.012)
        return mix(d, (0, swish, 0.8), (0.18, cut, 1.0), (0.18, metal_ring(2100, 0.3), 0.25), (0.18, thump(120, 0.2, 0.5, 0.1), 0.5))

    @staticmethod
    def boom(v):
        d = 1.4
        out = silence(d)
        for k in range(5):
            out = mix(d, (0, out, 1), (k * 0.09, Lame.hit(v), rng.uniform(0.5, 0.8)))
        return reverb(mix(d, (0, out, 1), (0.4, metal_ring(900, 0.9), 0.4)), 0.5, 0.2)

    @staticmethod
    def loop(v):
        d = 4.0
        out = silence(d)
        for k in range(10):
            out = mix(d, (0, out, 1), (k * 0.38 + rng.uniform(0, 0.1), whoosh(0.3, 3500, 900, 0.6, 2.5, "white"), 0.5))
        return make_loop(out)

    @staticmethod
    def proj(v):
        return whoosh(0.5, 3500, 900, 0.5, 2.0, "white")


@family("spectre")
class Spectre:
    @staticmethod
    def cast(v):
        d = 1.0
        return reverb(mix(d, (0, Lame.cast(v), 0.7), (0, Ames.cast(v)[:int(d * SR)], 0.6)), 0.8, 0.35)

    @staticmethod
    def hit(v):
        d = 0.8
        return reverb(mix(d, (0, Lame.hit(v), 0.8), (0, Ames.hit(v)[:int(d * SR)], 0.4)), 0.7, 0.3)

    @staticmethod
    def boom(v):
        d = 1.6
        return mix(d, (0, Lame.boom(v), 0.8), (0, Ames.boom(v)[:int(d * SR)], 0.5))

    @staticmethod
    def loop(v):
        return Ames.loop(v)


@family("garde")
class Garde:
    @staticmethod
    def cast(v):
        d = 0.9
        clang = add(metal_ring(620, 0.8) * 0.8, thump(150, 0.3, 0.5, 0.6) * 0.6)
        hum = sine(220, d) * env_curve(d, [(0, 0), (0.2, 1), (d, 0)]) * 0.15 + sine(330, d) * env_curve(d, [(0, 0), (0.2, 1), (d, 0)]) * 0.08
        return reverb(mix(d, (0, clang, 1), (0.05, hum, 1)), 0.5, 0.25)

    @staticmethod
    def hit(v):
        d = 0.7
        return mix(d, (0, metal_ring(780, 0.6), 0.8), (0, thump(140, 0.3, 0.5, 0.8), 0.7))

    @staticmethod
    def boom(v):
        d = 1.6
        return reverb(mix(d, (0, metal_ring(420, 1.4), 1.0), (0, thump(70, 0.8, 0.8, 0.6), 1.0), (0.05, Lumiere.hit(v)[:int(0.9 * SR)], 0.4)), 0.6, 0.25)

    @staticmethod
    def loop(v):
        d = 4.0
        t = t_axis(d)
        return make_loop((sine(220, d) * 0.12 + sine(330.5, d) * 0.08 + sine(441, d) * 0.04) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.5 * t)))


@family("hache")
class Hache:
    @staticmethod
    def cast(v):
        d = 0.8
        return mix(d, (0, whoosh(0.5, 300, 1500, 0.7, 1.2, "pink"), 1.0), (0.42, thump(90, 0.35, 1.0, 0.3), 0.8))

    @staticmethod
    def hit(v):
        d = 0.7
        chop = add(wood_knock(180, 0.3) * 0.8, bp(noise(0.12), 500, 4000) * env_exp(0.12, 0.02))
        return mix(d, (0, whoosh(0.25, 2000, 500, 0.6, 1.5), 0.6), (0.2, chop, 1), (0.2, thump(80, 0.4, 1.0, 0.2), 0.9), (0.2, metal_ring(700, 0.3), 0.2))

    @staticmethod
    def boom(v):
        d = 1.4
        whirl = sum(whoosh(0.3, 1500, 500, 0.5, 1.5) for _ in range(1)) * 1.0
        out = silence(d)
        for k in range(4):
            out = mix(d, (0, out, 1), (k * 0.14, whoosh(0.3, 1800, 500, 0.5, 1.5), 0.7))
        return mix(d, (0, out, 1), (0.6, Hache.hit(v), 1.2), (0.6, Terre.hit(v)[:int(0.8 * SR)], 0.6))

    @staticmethod
    def loop(v):
        d = 4.0
        out = silence(d)
        for k in range(16):
            out = mix(d, (0, out, 1), (k * 0.25, whoosh(0.3, 1500, 500, 0.5, 1.5), 0.5))
        return make_loop(out)

    @staticmethod
    def proj(v):
        d = 0.6
        out = silence(d)
        for k in range(4):
            out = mix(d, (0, out, 1), (k * 0.13, whoosh(0.2, 1500, 600, 0.5, 2.0), 0.6))
        return out


@family("cri")
class Cri:
    @staticmethod
    def cast(v):
        d = 1.2
        shout = sum(formant_voice(sweep(d, f, f * 0.85), d, ("a", "o"), 0.8, 0.3, 5, 0.02) for f in (130, 155, 175)) * 0.25
        shout *= env_curve(d, [(0, 0), (0.08, 1), (0.8, 0.8), (d, 0)])
        return reverb(mix(d, (0, shout, 1), (0, drum(41, d), 0.5)), 0.5, 0.2)

    @staticmethod
    def hit(v):
        d = 0.8
        return mix(d, (0, drum(36, d, 120), 1.0), (0, thump(70, 0.5, 0.8, 0.3), 0.6))

    @staticmethod
    def boom(v):
        d = 1.8
        roar = formant_voice(sweep(d, 110, 80), d, ("a", "a", "o"), 1.0, 0.4, 3, 0.03) * env_curve(d, [(0, 0), (0.1, 1), (1.4, 0.8), (d, 0)])
        return reverb(mix(d, (0, roar, 0.7), (0, drum(49, d), 0.4), (0, thump(50, 1.0, 0.8, 0.2), 0.8)), 0.6, 0.25)

    @staticmethod
    def loop(v):
        d = 4.0
        return make_loop(heartbeat(d, 110) * 0.8 + rumble(d, 200, 1.8, 0.5) * 0.3)


@family("clan")
class Clan:
    @staticmethod
    def cast(v):
        d = 1.2
        dr = gm([(0, 47, 0.3, 120), (0.3, 47, 0.3, 110), (0.6, 47, 0.3, 127)], 116, d)  # taiko
        return mix(d, (0, dr, 1.0), (0.6, Cri.cast(v)[:int(0.6 * SR)], 0.4))

    @staticmethod
    def hit(v):
        d = 0.7
        return mix(d, (0, gm([(0, 45, 0.3, 120)], 116, d), 1.0), (0, wood_knock(200, 0.3), 0.5))

    @staticmethod
    def boom(v):
        d = 1.8
        dr = gm([(0, 40, 0.3, 127), (0.12, 45, 0.3, 120), (0.24, 40, 0.5, 127)], 116, d)
        return reverb(mix(d, (0, dr, 1.0), (0, thump(48, 1.0, 0.8, 0.2), 0.8)), 0.6, 0.25)

    @staticmethod
    def loop(v):
        d = 4.0
        return make_loop(gm([(k * 0.5, 45 if k % 2 == 0 else 50, 0.3, 110 if k % 4 == 0 else 85) for k in range(8)], 116, d) * 0.8)


@family("seisme")
class Seisme:
    @staticmethod
    def cast(v):
        d = 1.0
        return mix(d, (0, rumble(d, 120) * env_curve(d, [(0, 0), (0.7, 1), (d, 0)]), 1.2), (0.75, thump(45, 0.5, 1.2, 0.4), 1.0))

    @staticmethod
    def hit(v):
        return Terre.hit(v)

    @staticmethod
    def boom(v):
        d = 2.4
        return reverb(mix(d, (0, thump(35, 1.6, 1.2, 0.5), 1.6), (0, rumble(d, 100, 6, 0.6) * env_exp(d, 0.9), 1.6), (0.05, Terre.boom(v)[:int(d * SR)], 0.6)), 0.5, 0.15)

    @staticmethod
    def loop(v):
        return Terre.loop(v)


@family("chevalier")
class Chevalier:
    @staticmethod
    def cast(v):
        d = 1.2
        tr = gm([(0, 60, 0.25, 110), (0.25, 67, 0.25, 110), (0.5, 72, 0.6, 120)], 56, d)  # trompette
        clank = metal_ring(900, 0.4) * 0.3
        return reverb(mix(d, (0, tr, 1), (0.5, clank, 1)), 0.6, 0.25)

    @staticmethod
    def hit(v):
        d = 0.7
        return mix(d, (0, metal_ring(520, 0.6), 0.7), (0, thump(110, 0.4, 0.8, 0.5), 1.0))

    @staticmethod
    def boom(v):
        # Charge : galop qui arrive, choc.
        d = 2.0
        out = silence(d)
        for k in range(10):
            t0 = k * 0.12
            g = 0.2 + 0.8 * k / 10
            out = mix(d, (0, out, 1), (t0, thump(90, 0.2, 0.6, 0.6), g * 0.6), (t0 + 0.05, thump(80, 0.2, 0.6, 0.6), g * 0.5))
        return reverb(mix(d, (0, out, 1), (1.2, metal_ring(400, 0.8), 0.8), (1.2, thump(55, 0.8, 1.0, 0.4), 1.2)), 0.5, 0.2)

    @staticmethod
    def loop(v):
        d = 4.0
        out = silence(d)
        for k in range(8):
            out = mix(d, (0, out, 1), (k * 0.5, thump(85, 0.25, 0.5, 0.5), 0.4), (k * 0.5 + 0.25, metal_ring(rng.uniform(700, 1100), 0.2), 0.15))
        return make_loop(out)


@family("forteresse")
class Forteresse:
    @staticmethod
    def cast(v):
        d = 1.0
        return mix(d, (0, Terre.cast(v), 1), (0.6, metal_ring(500, 0.4), 0.3))

    @staticmethod
    def hit(v):
        d = 1.0
        grind = rustle(d, 120, 150, 2000) * env_curve(d, [(0, 0), (0.1, 1), (0.8, 0.6), (d, 0)])
        return mix(d, (0, grind, 1), (0.8, thump(55, 0.3, 0.8, 0.5), 1.0), (0, rumble(d, 120) * env_curve(d, [(0, 0), (0.2, 1), (d, 0)]), 0.8))

    @staticmethod
    def boom(v):
        d = 1.8
        return reverb(mix(d, (0, Forteresse.hit(v), 1.2), (0.95, metal_ring(300, 0.8), 0.5)), 0.5, 0.2)

    @staticmethod
    def loop(v):
        return Garde.loop(v)


@family("justice")
class Justice:
    @staticmethod
    def cast(v):
        d = 1.2
        return mix(d, (0, Lumiere.cast(v), 0.8), (0.55, metal_ring(700, 0.6), 0.5))

    @staticmethod
    def hit(v):
        d = 1.0
        return mix(d, (0, metal_ring(500, 0.8), 0.6), (0, thump(80, 0.5, 1.0, 0.5), 1.0), (0, sparkle(d, 10, 4000, 9000, 0.2), 0.5))

    @staticmethod
    def boom(v):
        d = 2.0
        return reverb(mix(d, (0, Lumiere.boom(v)[:int(d * SR)], 0.8), (0, thump(45, 1.0, 1.0, 0.6), 1.1), (0, metal_ring(350, 1.2), 0.6)), 0.6, 0.2)

    @staticmethod
    def loop(v):
        return Lumiere.loop(v)


@family("soin")
class Soin:
    @staticmethod
    def cast(v):
        d = 1.3
        gl = gm([(i * 0.05, n, 0.5, 85) for i, n in enumerate([67, 71, 74, 79, 83, 86])], 46, d)  # glissando de harpe
        return reverb(mix(d, (0, gl, 1), (0.2, sparkle(d, 10, 4000, 9000, 0.3), 0.5)), 0.7, 0.3, tail=0.4)

    @staticmethod
    def hit(v):
        d = 1.0
        return reverb(mix(d, (0, gm([(0, 79, 0.6, 85), (0.08, 86, 0.6, 75)], 10, d), 1.0), (0, sparkle(d, 8, 4000, 9000, 0.25), 0.4)), 0.7, 0.3)

    @staticmethod
    def boom(v):
        d = 2.0
        ch = gm_chord(53, [67, 71, 74, 79], d, 95)
        return reverb(mix(d, (0, ch, 1), (0, Soin.cast(v)[:int(d * SR)], 0.7)), 0.8, 0.35)

    @staticmethod
    def loop(v):
        d = 4.0
        return make_loop(gm([(0, 67, 3.9, 60), (0, 74, 3.9, 55), (0, 79, 3.9, 50)], 89, d) + sparkle(d, 14, 4000, 9000, 0.3, d * 0.95) * 0.4)


@family("anges")
class Anges:
    @staticmethod
    def cast(v):
        d = 1.6
        ch = gm([(0, 64, 1.4, 90), (0, 67, 1.4, 85), (0, 72, 1.4, 85), (0.2, 76, 1.2, 80)], 52, d)
        return reverb(mix(d, (0, ch, 1), (0, sparkle(d, 14, 4000, 10000, 0.3), 0.6), (0, whoosh(d, 600, 2500, 0.5, 1.0), 0.3)), 0.8, 0.35)

    @staticmethod
    def hit(v):
        return Lumiere.hit(v)

    @staticmethod
    def boom(v):
        return Lumiere.boom(v)

    @staticmethod
    def loop(v):
        return Lumiere.loop(v)


@family("purif")
class Purif:
    @staticmethod
    def cast(v):
        d = 1.4
        bells = gm([(0, 72, 1.0, 90), (0.12, 76, 1.0, 85), (0.24, 79, 1.0, 85), (0.36, 84, 1.0, 80)], 9, d)
        return reverb(mix(d, (0, bells, 0.8), (0, whoosh(d, 2000, 7000, 0.4, 1.0, "white"), 0.4)), 0.8, 0.35)

    @staticmethod
    def hit(v):
        d = 1.0
        return reverb(mix(d, (0, whoosh(0.6, 6000, 1500, 0.2, 1.0, "white"), 0.6), (0, bell(midi_hz(84), d), 0.4)), 0.7, 0.3)

    @staticmethod
    def boom(v):
        d = 2.0
        return reverb(mix(d, (0, Purif.cast(v)[:int(d * SR)], 1.0), (0, gm_chord(52, [72, 79, 84], d, 100), 0.8)), 0.8, 0.3)

    @staticmethod
    def loop(v):
        return Lumiere.loop(v)


@family("sacre")
class Sacre:
    """Châtiment, rayons, sanctuaire : la Lumière qui frappe."""
    @staticmethod
    def cast(v):
        d = 1.0
        beam = saw(sweep(d, 440, 880), d) * env_curve(d, [(0, 0), (0.6, 1), (d, 0)]) * 0.12
        beam = filt_sweep(beam, sweep(d, 1000, 6000), "low", 1.5)
        return reverb(mix(d, (0, beam, 1), (0, sparkle(d, 14, 4000, 9000, 0.2), 0.6), (0.6, bell(midi_hz(81), 0.6), 0.3)), 0.7, 0.3)

    @staticmethod
    def hit(v):
        d = 1.0
        return mix(d, (0, Lumiere.hit(v), 1), (0, zap(0.2, 6000, 1500), 0.3))

    @staticmethod
    def boom(v):
        d = 2.2
        return reverb(mix(d, (0, thunder(d, 0.8), 0.7), (0, Lumiere.boom(v)[:int(d * SR)], 0.9)), 0.6, 0.25)

    @staticmethod
    def loop(v):
        d = 4.0
        t = t_axis(d)
        beam = (sine(440, d) * 0.1 + sine(880.5, d) * 0.06 + sine(1320, d) * 0.03) * (0.8 + 0.2 * np.sin(2 * np.pi * 7 * t))
        return make_loop(beam + sparkle(d, 12, 4000, 9000, 0.2, d * 0.95) * 0.3)


@family("tempete")
class Tempete:
    """Lames d'orage : l'acier et la foudre."""
    @staticmethod
    def cast(v):
        d = 0.9
        return mix(d, (0, Lame.cast(v), 0.7), (0, Foudre.cast(v), 0.6))

    @staticmethod
    def hit(v):
        d = 0.9
        return mix(d, (0, Lame.hit(v), 0.8), (0.15, zap(0.3, 5000, 400), 0.6))

    @staticmethod
    def boom(v):
        return Foudre.boom(v)

    @staticmethod
    def loop(v):
        return Foudre.loop(v)


# ================================================================== sons particuliers de sort (phases)

@snd("beam", "cast")
def s_beam():
    d = 1.2
    t = t_axis(d)
    core = saw(220 * (1 + 0.004 * np.sin(2 * np.pi * 30 * t)), d) * 0.2
    core = filt_sweep(core, 1500 + 800 * np.sin(2 * np.pi * 3 * t), "low", 2)
    return mix(d, (0, core * env_curve(d, [(0, 0), (0.05, 1), (1.0, 0.8), (d, 0)]), 1), (0, zap(0.2, 3000, 800), 0.5))


@snd("thunder", "boom")
def s_thunder():
    return reverb(thunder(3.0, 1.2), 0.6, 0.2)


@snd("thunder_far", "weather")
def s_thunder_far():
    return lp(thunder(3.5, 0.3), 900)


@snd("quake", "boom")
def s_quake():
    return Seisme.boom(0)


@snd("wave_swoosh", "cast")
def s_wave():
    d = 1.0
    return mix(d, (0, whoosh(d, 400, 2500, 0.45, 0.8), 1.2), (0.3, splash(0.6, 300, 3000, 4), 0.3))


@snd("summon_rise", "summon")
def s_summon_rise():
    d = 1.0
    return reverb(mix(d, (0, whoosh(d, 300, 2500, 0.8, 1.2), 0.8), (0.75, thump(90, 0.3, 0.8, 0.3), 0.8), (0.75, sparkle(0.4, 8), 0.5)), 0.5, 0.2)


@snd("shield_up", "cast")
def s_shield():
    d = 1.2
    t = t_axis(d)
    hum = (sine(330, d) * 0.15 + sine(495, d) * 0.1 + sine(660, d) * 0.06) * env_curve(d, [(0, 0), (0.15, 1), (0.8, 0.6), (d, 0)])
    return reverb(mix(d, (0, hum, 1), (0, sparkle(d, 12, 3000, 8000, 0.25), 0.6), (0, whoosh(0.5, 800, 3000, 0.5, 1.0), 0.4)), 0.6, 0.3)


@snd("rally_horn", "cast")
def s_rally():
    d = 1.6
    return reverb(gm([(0, 55, 0.35, 110), (0.35, 60, 0.35, 110), (0.7, 67, 0.8, 120)], 60, d), 0.6, 0.25)


@snd("forbidden", "boom")
def s_forbidden():
    """Couche des sorts interdits : chœur grave dissonant, souffle qui s'inverse, coup sourd."""
    d = 2.2
    ch = gm([(0, 36, 2.0, 100), (0, 42, 2.0, 90), (0, 47, 2.0, 90)], 52, d)
    rev = whoosh(0.8, 100, 900, 0.95, 0.8) * 1.2
    return reverb(mix(d, (0, ch, 0.8), (0, rev, 1.0), (0.78, thump(38, 1.2, 1.0, 0.1), 1.2)), 0.8, 0.35)


@snd("grand_cast", "cast")
def s_grand():
    """Couche des sorts d'Archimage : montée orchestrale."""
    d = 1.4
    st = gm([(0, 48, 1.3, 100), (0, 55, 1.3, 90), (0, 60, 1.3, 90)], 48, d)
    return mix(d, (0, st * env_curve(d, [(0, 0), (1.0, 1), (d, 0)]), 1), (0, gm([(0.0, 40, 0.3, 90), (0.6, 40, 0.3, 110), (1.0, 40, 0.3, 127)], 47, d), 0.9))


@snd("ultimate", "big")
def s_ultimate():
    d = 3.2
    rise = whoosh(1.4, 100, 4000, 0.98, 1.0) * 1.2
    hit = mix(2.0, (0, thump(35, 2.0, 1.4, 0.4), 1.5), (0, rumble(2.0, 120) * env_exp(2.0, 0.8), 1.5), (0, glass_shatter(2.0, 50), 0.6))
    ch = gm([(1.3, 48, 1.8, 120), (1.3, 55, 1.8, 110), (1.3, 60, 1.8, 110), (1.3, 64, 1.8, 110)], 52, d)
    return reverb(mix(d, (0, rise, 1), (1.35, hit, 1.0), (0, ch, 0.8), (1.3, gm([(0, 36, 0.4, 127)], 55, 1.5), 1.0)), 0.7, 0.3)


# ================================================================== touches propres à chaque sort (couche d'attaque)

@snd("sw_spark", "small")
def s_sw_spark():
    return sparkle(0.5, 8, 4000, 9000, 0.15)


@snd("sw_glass", "small")
def s_sw_glass():
    return modal([2637, 3951, 5274], [1, 0.5, 0.25], [0.3, 0.2, 0.1], 0.6)


@snd("sw_ping", "small")
def s_sw_ping():
    return metal_ring(1760, 0.5)


@snd("sw_air", "small")
def s_sw_air():
    return whoosh(0.45, 800, 4000, 0.4, 1.2)


@snd("sw_sub", "small")
def s_sw_sub():
    return sine(sweep(0.6, 70, 38), 0.6) * env_exp(0.6, 0.2) * 1.5


@snd("sw_rattle", "small")
def s_sw_rattle():
    return bone_clicks(0.4, 7, 900, 2600)


@snd("sw_whisper", "small")
def s_sw_whisper():
    return hp(formant_voice(sweep(0.6, 150, 130), 0.6, ("i", "a"), 0.0, 2.0, 3, 0.0), 1500) * env_curve(0.6, [(0, 0), (0.2, 1), (0.6, 0)]) * 0.3


# ================================================================== invocations (armées de sorts)

def _summon_kind(kind):
    d = 1.4
    if kind == "bones":
        return Morts.cast(0)
    if kind == "wolf":
        f = sweep(1.4, 380, 560)
        f = np.where(t_axis(1.4) > 0.7, 560 - (t_axis(1.4) - 0.7) * 250, f)
        howl = formant_voice(f, d, ("ou", "o", "ou"), 0.1, 0.2, 5, 0.01) * env_curve(d, [(0, 0), (0.2, 1), (1.1, 0.8), (d, 0)])
        return reverb(howl * 0.6, 0.7, 0.3)
    if kind == "bear":
        return reverb(formant_voice(sweep(d, 95, 70), d, ("a", "o"), 1.2, 0.4, 3, 0.03) * env_curve(d, [(0, 0), (0.1, 1), (d, 0)]) * 0.6, 0.5, 0.2)
    if kind == "bird":
        out = silence(d)
        for k in range(3):
            out = mix(d, (0, out, 1), (k * 0.28, sine(sweep(0.25, 3800, 2400), 0.25) * env_exp(0.25, 0.1) + sine(sweep(0.25, 5200, 3600), 0.25) * env_exp(0.25, 0.08) * 0.4, 0.5))
        return reverb(out, 0.6, 0.3)
    if kind == "stag":
        return reverb(formant_voice(sweep(d, 160, 230), d, ("o", "a"), 0.3, 0.3, 4, 0.02) * env_curve(d, [(0, 0), (0.3, 1), (d, 0)]) * 0.5, 0.7, 0.3)
    if kind == "angel":
        return Anges.cast(0)
    if kind == "knight":
        out = silence(d)
        for k in range(6):
            out = mix(d, (0, out, 1), (k * 0.18, metal_ring(rng.uniform(800, 1300), 0.25), 0.25), (k * 0.18, thump(110, 0.2, 0.4, 0.4), 0.4))
        return mix(d, (0, out, 1), (0, gm([(0, 60, 0.3, 100), (0.3, 64, 0.5, 110)], 56, d), 0.5))
    if kind == "blade":
        return mix(d, (0, Lame.cast(0), 1), (0.3, Lame.cast(0), 0.6))
    if kind == "warrior":
        return mix(d, (0, Cri.cast(0)[:int(d * SR)], 1))
    if kind == "totem":
        return mix(d, (0, wood_knock(160, 0.5), 1), (0.25, wood_knock(200, 0.5), 0.8), (0.5, gm([(0, 45, 0.4, 110)], 116, 0.8), 0.8))
    if kind == "giant":
        out = silence(d)
        for k in range(3):
            out = mix(d, (0, out, 1), (k * 0.42, thump(40, 0.6, 1.0, 0.4), 1.0), (k * 0.42, rumble(0.5, 120) * env_exp(0.5, 0.2), 0.8))
        return out
    if kind == "golem":
        return mix(d, (0, Forteresse.hit(0)[:int(d * SR)], 1), (0.2, bone_clicks(1.0, 20, 600, 2000), 0.6))
    if kind == "spirit":
        return Ames.cast(0)
    if kind == "crystal":
        return reverb(mix(d, (0, sparkle(d, 20, 3000, 9000, 0.3), 1), (0, bell(midi_hz(84), d), 0.4)), 0.7, 0.3)
    if kind == "void":
        return Ombre.cast(0)
    if kind == "machine":
        out = silence(d)
        for k in range(6):
            out = mix(d, (0, out, 1), (k * 0.1, wood_knock(rng.uniform(300, 500), 0.15), 0.6))
        return mix(d, (0, out, 1), (0.7, metal_ring(600, 0.5), 0.4))
    raise ValueError(kind)


for _k in ["bones", "wolf", "bear", "bird", "stag", "angel", "knight", "blade", "warrior", "totem", "giant", "golem", "spirit", "crystal", "void", "machine"]:
    snd("summon_" + _k, "summon")((lambda k: lambda: _summon_kind(k))(_k))


# ================================================================== cris des créatures (boss, sujets des cinématiques)

def _roar(kind):
    if kind == "dragon":
        d = 2.4
        f = sweep(d, 150, 95)
        v = formant_voice(f, d, ("a", "a", "o"), 1.4, 0.6, 3, 0.04) * env_curve(d, [(0, 0), (0.12, 1), (1.6, 0.8), (d, 0)])
        fire = lp(noise(d, "brown"), 700) * env_curve(d, [(0, 0), (0.3, 0.6), (d, 0)])
        return reverb(mix(d, (0, v, 0.8), (0, fire, 0.5), (0, sine(sweep(d, 55, 40), d) * env_curve(d, [(0, 0), (0.2, 1), (d, 0)]), 0.4)), 0.7, 0.3)
    if kind == "wyrm":
        d = 2.8
        v = formant_voice(sweep(d, 95, 60), d, ("o", "a", "o"), 1.8, 0.8, 2.5, 0.05) * env_curve(d, [(0, 0), (0.2, 1), (2.0, 0.8), (d, 0)])
        return reverb(mix(d, (0, v, 0.8), (0, rumble(d, 160) * env_curve(d, [(0, 0), (0.3, 1), (d, 0)]), 0.8), (0, Feu.loop(0)[:int(d * SR)] * env_curve(d, [(0, 0), (1, 0.6), (d, 0)]), 0.3)), 0.7, 0.35)
    if kind == "beast":
        d = 1.8
        v = formant_voice(sweep(d, 210, 140), d, ("a", "o"), 1.1, 0.5, 4, 0.03) * env_curve(d, [(0, 0), (0.08, 1), (1.3, 0.7), (d, 0)])
        return reverb(v * 0.8, 0.5, 0.2)
    if kind == "wolf":
        return _summon_kind("wolf")
    if kind == "bear":
        return _summon_kind("bear")
    if kind == "golem":
        d = 2.2
        grind = rustle(d, 150, 100, 1500) * env_curve(d, [(0, 0), (0.3, 1), (d, 0)])
        v = formant_voice(sweep(d, 55, 45), d, ("o", "u"), 1.5, 0.3, 1.5, 0.02) * env_curve(d, [(0, 0), (0.4, 1), (d, 0)]) * 0.6
        return reverb(mix(d, (0, grind, 0.8), (0, v, 1), (0, rumble(d, 120) * env_curve(d, [(0, 0), (0.4, 1), (d, 0)]), 1.0)), 0.6, 0.25)
    if kind == "hydra":
        d = 2.2
        out = silence(d)
        for k, f in enumerate((240, 300, 190)):
            h = formant_voice(sweep(1.4, f, f * 0.7), 1.4, ("i", "a"), 1.0, 1.2, 6, 0.03) * env_curve(1.4, [(0, 0), (0.1, 1), (1.4, 0)])
            hiss = bp(noise(1.4), 2500, 7000) * env_curve(1.4, [(0, 0), (0.2, 1), (1.4, 0)])
            out = mix(d, (0, out, 1), (k * 0.3, h, 0.5), (k * 0.3, hiss, 0.25))
        return reverb(out, 0.6, 0.3)
    if kind == "tree":
        d = 2.4
        creak = formant_voice(sweep(d, 60, 85), d, ("o", "u", "o"), 0.8, 0.0, 1.2, 0.04) * env_curve(d, [(0, 0), (0.4, 1), (d, 0)]) * 0.6
        return reverb(mix(d, (0, creak, 1), (0, rustle(d, 80) * env_curve(d, [(0, 0), (0.5, 1), (d, 0)]), 0.5), (0, rumble(d, 150) * 0.6, 0.6)), 0.7, 0.3)
    if kind == "sphinx":
        d = 2.4
        v = sum(formant_voice(sweep(d, f, f * 0.92), d, ("a", "o"), 0.5, 0.3, 4, 0.02) for f in (110, 165, 220)) * 0.3
        v = v * env_curve(d, [(0, 0), (0.3, 1), (1.8, 0.8), (d, 0)])
        return reverb(mix(d, (0, v, 1), (0, glass_shatter(1.0, 14, 3000, 9000), 0.25)), 0.85, 0.4)
    if kind == "sea":
        d = 3.0
        t = t_axis(d)
        f = 90 + 40 * np.sin(np.pi * t / d) - 25 * t / d
        song = formant_voice(f, d, ("ou", "o", "a", "ou"), 0.3, 0.2, 2, 0.02) * env_curve(d, [(0, 0), (0.5, 1), (2.4, 0.8), (d, 0)])
        return reverb(mix(d, (0, lp(song, 2500), 0.9), (0, rumble(d, 100) * 0.7, 0.6), (0.4, splash(1.5, 200, 2000, 10), 0.3)), 0.85, 0.45)
    if kind == "kraken":
        d = 2.0
        v = formant_voice(sweep(d, 120, 70), d, ("o", "ou"), 1.2, 0.5, 3, 0.05) * env_curve(d, [(0, 0), (0.2, 1), (d, 0)])
        return reverb(mix(d, (0, lp(v, 3000), 0.8), (0, splash(d, 200, 3000, 20), 0.6)), 0.7, 0.35)
    if kind == "undead":
        d = 2.0
        v = formant_voice(sweep(d, 160, 110), d, ("a", "o", "ou"), 0.9, 1.0, 5, 0.05) * env_curve(d, [(0, 0), (0.15, 1), (d, 0)])
        return reverb(mix(d, (0, v, 0.7), (0, bone_clicks(d, 14), 0.5)), 0.8, 0.4)
    if kind == "orc":
        d = 1.6
        v = formant_voice(sweep(d, 125, 100), d, ("a", "a", "o"), 1.0, 0.3, 4, 0.02) * env_curve(d, [(0, 0), (0.06, 1), (1.2, 0.9), (d, 0)])
        return reverb(mix(d, (0, v, 0.9), (0, drum(41, d), 0.4)), 0.5, 0.2)
    if kind == "insect":
        d = 1.6
        t = t_axis(d)
        chit = silence(d)
        for k in range(26):
            chit = mix(d, (0, chit, 1), (k * 0.055, bp(noise(0.03), 2000, 6000) * env_exp(0.03, 0.006), 0.6))
        buzz = saw(140 * (1 + 0.05 * np.sin(2 * np.pi * 30 * t)), d, 30) * env_curve(d, [(0, 0), (0.2, 1), (d, 0)]) * 0.2
        return reverb(mix(d, (0, chit, 1), (0, bp(buzz, 200, 4000), 1)), 0.5, 0.2)
    if kind == "stag":
        return _summon_kind("stag")
    if kind == "phoenix":
        d = 1.6
        sc = formant_voice(sweep(d, 900, 600), d, ("i", "e"), 0.4, 0.4, 7, 0.04) * env_curve(d, [(0, 0), (0.1, 1), (d, 0)])
        return reverb(mix(d, (0, sc, 0.5), (0, Feu.cast(0)[:int(d * SR)], 0.5)), 0.6, 0.3)
    if kind == "demon":
        d = 1.8
        v = formant_voice(sweep(d, 85, 65), d, ("a", "o"), 1.6, 0.8, 3, 0.05) * env_curve(d, [(0, 0), (0.1, 1), (d, 0)])
        return reverb(mix(d, (0, v, 0.8), (0, Feu.hit(0)[:int(d * SR)], 0.4)), 0.6, 0.3)
    if kind == "spirit":
        return Ames.cast(0)
    if kind == "small":
        d = 0.9
        return formant_voice(sweep(d, 330, 260), d, ("a", "i"), 0.6, 0.4, 6, 0.03) * env_curve(d, [(0, 0), (0.08, 1), (d, 0)]) * 0.6
    raise ValueError(kind)


for _k in ["dragon", "wyrm", "beast", "wolf", "bear", "golem", "hydra", "tree", "sphinx", "sea", "kraken", "undead", "orc", "insect", "stag", "phoenix", "demon", "spirit", "small"]:
    snd("roar_" + _k, "roar")((lambda k: lambda: _roar(k))(_k))


# ================================================================== tirs de classe

@snd("shot_necro", "small")
def s_shot_necro():
    return mix(0.6, (0, bone_clicks(0.5, 8), 1), (0, rustle(0.4, 50, 200, 1500) * env_exp(0.4, 0.15), 0.6))


@snd("shot_mage", "small")
def s_shot_mage():
    d = 0.5
    return mix(d, (0, sine(sweep(0.3, 1800, 2600), 0.3) * env_exp(0.3, 0.1), 0.6), (0.05, sparkle(0.4, 5, 3000, 7000, 0.1), 0.6))


@snd("shot_archer", "small")
def s_shot_archer():
    return Fleche.cast(0)[int(0.25 * SR):]


@snd("shot_epeiste", "small")
def s_shot_epeiste():
    return whoosh(0.5, 3500, 700, 0.35, 1.8, "white")


@snd("shot_clerc", "small")
def s_shot_clerc():
    d = 0.6
    return mix(d, (0, sine(1320, 0.4) * env_exp(0.4, 0.15), 0.4), (0, sine(1980, 0.4) * env_exp(0.4, 0.1), 0.2), (0, sparkle(0.4, 4, 4000, 8000, 0.1), 0.5))


@snd("shot_chevalier", "small")
def s_shot_chevalier():
    d = 0.6
    out = silence(d)
    for k in range(4):
        out = mix(d, (0, out, 1), (k * 0.12, whoosh(0.15, 1500, 700, 0.5, 2.0), 0.7))
    return out


@snd("shot_berserker", "small")
def s_shot_berserker():
    return Hache.proj(0)


@snd("shot_hit", "small")
def s_shot_hit():
    return thump(150, 0.25, 0.8, 0.6)


@snd("shot_light_hit", "small")
def s_shot_light_hit():
    return mix(0.8, (0, bell(midi_hz(88), 0.7), 0.4), (0, sparkle(0.6, 8, 4000, 9000, 0.15), 0.6))


@snd("shot_shock", "hit")
def s_shot_shock():
    return mix(0.8, (0, metal_ring(560, 0.6), 0.6), (0, thump(70, 0.6, 1.0, 0.4), 1.0), (0.02, rumble(0.6, 180) * env_exp(0.6, 0.2), 0.6))


# ================================================================== combat

@snd("flux", "small")
def s_flux():
    d = 0.3
    return sine(sweep(d, 500, 900), d) * env_exp(d, 0.06) * 0.6 + bp(noise(d), 1500, 4000) * env_exp(d, 0.03) * 0.2


def _hit(i):
    return thump(140 + i * 25, 0.2, 0.7, 0.6) + bp(noise(0.2), 800 + 300 * i, 4000) * env_exp(0.2, 0.015) * 0.5


def _die(i):
    return mix(0.5, (0, whoosh(0.4, 1200 + 300 * i, 300, 0.2, 1.0), 0.8), (0, thump(110 - i * 15, 0.3, 0.8, 0.3), 0.6))


for _i in range(3):
    snd("hit_%d" % _i, "small")((lambda i: lambda: _hit(i))(_i))
    snd("die_%d" % _i, "small")((lambda i: lambda: _die(i))(_i))


@snd("ally_die", "small")
def s_ally_die():
    return mix(0.5, (0, bone_clicks(0.4, 6, 900, 2500), 0.8), (0, whoosh(0.4, 900, 300, 0.2, 1.0), 0.5))


@snd("barrier_hit", "battle")
def s_barrier_hit():
    d = 0.9
    t = t_axis(d)
    ward = (sine(196, d) * 0.4 + sine(294, d) * 0.25) * env_exp(d, 0.3) * (1 + 0.3 * np.sin(2 * np.pi * 18 * t))
    return mix(d, (0, ward, 1), (0, thump(70, 0.5, 1.0, 0.4), 0.9), (0, glass_shatter(0.4, 8, 2500, 6000), 0.25))


@snd("barrier_low", "battle")
def s_barrier_low():
    return heartbeat(1.0, 72)


@snd("barrier_break", "big")
def s_barrier_break():
    d = 2.0
    return reverb(mix(d, (0, glass_shatter(d, 80, 1500, 9000), 1.2), (0, thump(45, 1.2, 1.0, 0.3), 1.2), (0, rumble(d, 150) * env_exp(d, 0.6), 1.0)), 0.6, 0.25)


@snd("nexus_hit", "battle")
def s_nexus_hit():
    d = 0.8
    return mix(d, (0, modal([1450, 2210, 3530], [1, 0.6, 0.35], [0.35, 0.2, 0.12], d), 0.6), (0, thump(130, 0.2, 0.5, 0.4), 0.6))


@snd("nexus_break", "big")
def s_nexus_break():
    d = 2.6
    return reverb(mix(d, (0, glass_shatter(d, 120, 1500, 10000), 1.2), (0, thump(40, 1.6, 1.2, 0.3), 1.2), (0.1, gm_chord(52, [48, 55, 60], 2.0, 110), 0.6)), 0.7, 0.3)


@snd("portal", "small")
def s_portal():
    d = 0.5
    return mix(d, (0, sine(sweep(d, 600, 1400), d) * env_exp(d, 0.12), 0.4), (0, sparkle(d, 4, 3000, 6000, 0.1), 0.5))


@snd("portal_bad", "small")
def s_portal_bad():
    d = 0.5
    return mix(d, (0, sine(sweep(d, 500, 220), d) * env_exp(d, 0.15), 0.5), (0, lp(noise(d), 600) * env_exp(d, 0.1), 0.4))


@snd("champion", "big")
def s_champion():
    d = 2.4
    fan = gm([(0, 60, 0.3, 120), (0.3, 64, 0.3, 120), (0.6, 67, 0.3, 120), (0.9, 72, 1.2, 127)], 61, d)
    return reverb(mix(d, (0, fan, 1), (0.9, drum(49, 1.5, 120), 0.7), (0.9, thump(50, 0.8, 1.0, 0.3), 0.9)), 0.6, 0.25)


@snd("surge_full", "battle")
def s_surge_full():
    d = 1.4
    return reverb(mix(d, (0, whoosh(d, 300, 5000, 0.9, 1.5), 0.8), (0, gm([(i * 0.06, n, 0.4, 90) for i, n in enumerate([72, 76, 79, 84, 88, 91])], 8, d), 0.8)), 0.6, 0.3)


@snd("telegraph", "battle")
def s_telegraph():
    d = 1.0
    t = t_axis(d)
    return (sine(220, d) * 0.3 + sine(233, d) * 0.3) * env_curve(d, [(0, 0), (0.2, 1), (0.8, 1), (d, 0)]) * (0.6 + 0.4 * (np.sin(2 * np.pi * 8 * t) > 0))


@snd("victory", "big")
def s_victory():
    d = 3.0
    fan = gm([(0, 67, 0.2, 110), (0.2, 67, 0.2, 110), (0.4, 67, 0.2, 110), (0.6, 72, 1.6, 127)], 61, d)
    chord = gm([(0.6, 48, 2.0, 110), (0.6, 55, 2.0, 100), (0.6, 64, 2.0, 100)], 48, d)
    return reverb(mix(d, (0, fan, 1), (0, chord, 0.8), (0.6, drum(57, 2.0, 120), 0.6), (0.6, gm([(0, 36, 0.4, 120)], 47, 1.5), 0.8)), 0.6, 0.25)


@snd("defeat", "big")
def s_defeat():
    d = 3.2
    line = gm([(0, 67, 0.6, 100), (0.6, 63, 0.6, 95), (1.2, 60, 1.8, 90)], 57, d)
    pad = gm([(1.2, 48, 2.0, 90), (1.2, 51, 2.0, 85), (1.2, 55, 2.0, 85)], 49, d)
    return reverb(mix(d, (0, line, 1), (0, pad, 0.8), (1.2, gm([(0, 36, 0.4, 100)], 47, 1.5), 0.7)), 0.7, 0.3)


@snd("star", "ui")
def s_star():
    d = 0.8
    return reverb(mix(d, (0, gm([(0, 84, 0.4, 100), (0.08, 91, 0.5, 100)], 9, d), 1), (0, sparkle(d, 10, 5000, 10000, 0.2), 0.5)), 0.6, 0.25)


@snd("loot", "ui")
def s_loot():
    d = 0.7
    return mix(d, (0, gm([(0, 79, 0.3, 90), (0.07, 84, 0.4, 90)], 10, d), 1), (0, sparkle(d, 6, 4000, 9000, 0.15), 0.4))


@snd("loot_rare", "ui")
def s_loot_rare():
    d = 1.4
    return reverb(mix(d, (0, gm([(i * 0.07, n, 0.6, 100) for i, n in enumerate([72, 76, 79, 84, 88])], 8, d), 1), (0, sparkle(d, 20, 4000, 10000, 0.3), 0.7),
                      (0, whoosh(d, 800, 5000, 0.4, 1.2), 0.4)), 0.7, 0.3)


@snd("level_up", "ui")
def s_level_up():
    d = 1.8
    return reverb(mix(d, (0, gm([(0, 60, 0.15, 110), (0.15, 64, 0.15, 110), (0.3, 67, 0.15, 110), (0.45, 72, 1.0, 120)], 56, d), 1),
                      (0.45, gm_chord(48, [60, 64, 67], 1.3, 100, 0), 0.6)), 0.6, 0.25)


# ================================================================== évènements de l'arène

@snd("dragon_pass", "weather")
def s_dragon_pass():
    d = 2.2
    wing = silence(d)
    for k in range(4):
        wing = mix(d, (0, wing, 1), (k * 0.45, lp(whoosh(0.4, 150, 700, 0.5, 1.0, "brown"), 900), 1.0))
    roar = formant_voice(sweep(1.4, 180, 110), 1.4, ("a", "o"), 1.2, 0.5, 3, 0.04) * env_curve(1.4, [(0, 0), (0.15, 1), (1.4, 0)])
    return reverb(mix(d, (0, wing, 1), (0.3, roar, 0.5)), 0.7, 0.3)


@snd("avalanche", "weather")
def s_avalanche():
    d = 3.0
    return mix(d, (0, rumble(d, 250, 4, 0.5) * env_curve(d, [(0, 0), (0.6, 1), (2.2, 1), (d, 0)]), 1.5), (0, whoosh(d, 400, 2000, 0.6, 0.8), 0.6))


@snd("tentacle", "weather")
def s_tentacle():
    d = 1.2
    return mix(d, (0, splash(d, 200, 3000, 15), 1.0), (0, lp(whoosh(0.6, 200, 900, 0.6, 1.0, "brown"), 1200), 0.8), (0.5, thump(60, 0.6, 1.0, 0.3), 1.0))


@snd("whirlpool", "weather")
def s_whirlpool():
    d = 3.0
    t = t_axis(d)
    sw = filt_sweep(noise(d, "pink"), 400 + 300 * np.sin(2 * np.pi * 1.2 * t), "band", 2) * env_curve(d, [(0, 0), (0.6, 1), (2.4, 1), (d, 0)])
    return mix(d, (0, sw, 1.2), (0, lp(noise(d, "brown"), 200) * env_curve(d, [(0, 0), (1, 1), (d, 0)]), 0.7))


@snd("wave_crash", "weather")
def s_wave_crash():
    d = 2.4
    rush = whoosh(1.0, 300, 2500, 0.85, 0.8)
    crash = splash(1.6, 200, 5000, 20) * 1.3
    return mix(d, (0, rush, 1), (0.8, crash, 1), (0.8, thump(55, 0.6, 0.8, 0.2), 0.8))


@snd("wildfire", "weather")
def s_wildfire():
    d = 2.0
    return mix(d, (0, whoosh(d, 200, 1500, 0.4, 0.9), 1.0), (0, Feu.loop(0)[:int(d * SR)] * env_curve(d, [(0, 0), (0.4, 1), (d, 0)]), 0.8))


@snd("gong_day", "weather")
def s_gong():
    d = 3.0
    return reverb(bell(midi_hz(45), d, 0.7), 0.7, 0.3)


@snd("wall_rise", "hit")
def s_wall_rise():
    return Forteresse.hit(0)


@snd("rubble", "hit")
def s_rubble():
    d = 1.2
    return mix(d, (0, rustle(d, 120, 200, 3000) * env_exp(d, 0.3), 1.0), (0, thump(60, 0.5, 1.0, 0.4), 1.0))


@snd("tree_fall", "hit")
def s_tree_fall():
    d = 2.0
    creak = formant_voice(sweep(1.0, 90, 60), 1.0, ("o", "u"), 0.5, 0.0, 2, 0.03) * 0.3
    leaves = rustle(1.2, 100) * env_curve(1.2, [(0, 0), (0.6, 1), (1.2, 0)])
    return mix(d, (0, creak, 1), (0.6, leaves, 0.8), (1.1, thump(50, 0.8, 1.0, 0.4), 1.2), (1.1, wood_knock(120, 0.6), 0.7))


@snd("trap_snap", "hit")
def s_trap_snap():
    return Piege.hit(0)


# ================================================================== interface

@snd("ui_click", "ui")
def s_ui_click():
    d = 0.12
    return wood_knock(900, d) * 0.6 + sine(1600, d) * env_exp(d, 0.02) * 0.3


@snd("ui_back", "ui")
def s_ui_back():
    d = 0.18
    return sine(sweep(d, 900, 600), d) * env_exp(d, 0.05) * 0.5 + wood_knock(700, d) * 0.4


@snd("ui_open", "ui")
def s_ui_open():
    d = 0.45
    return mix(d, (0, whoosh(d, 600, 2500, 0.5, 1.2), 0.6), (0.1, sine(1320, 0.3) * env_exp(0.3, 0.08), 0.25))


@snd("ui_confirm", "ui")
def s_ui_confirm():
    d = 0.6
    return gm([(0, 76, 0.2, 90), (0.08, 83, 0.4, 90)], 8, d)


@snd("ui_error", "ui")
def s_ui_error():
    d = 0.35
    return (square(196, d, 8) * 0.15 + square(185, d, 8) * 0.15) * env_exp(d, 0.12)


@snd("ui_page", "ui")
def s_ui_page():
    d = 0.4
    return bp(noise(d), 1500, 7000) * env_curve(d, [(0, 0), (0.12, 1), (0.25, 0.4), (d, 0)]) * 0.8


@snd("ui_coin", "ui")
def s_ui_coin():
    d = 0.5
    return modal([2093, 3136, 4186], [1, 0.6, 0.3], [0.2, 0.12, 0.08], d) * 0.6 + modal([2637, 3951], [1, 0.5], [0.15, 0.1], d) * 0.4


@snd("ui_anvil", "ui")
def s_ui_anvil():
    d = 1.0
    return mix(d, (0, metal_ring(1100, 0.9), 1.0), (0, thump(160, 0.3, 0.6, 0.8), 0.5), (0, sparkle(0.6, 8, 3000, 7000, 0.1), 0.4))


@snd("ui_equip", "ui")
def s_ui_equip():
    d = 0.4
    return mix(d, (0, bp(noise(d), 600, 3000) * env_exp(d, 0.08), 0.6), (0.05, metal_ring(1500, 0.3), 0.25))


@snd("ui_text", "small")
def s_ui_text():
    d = 0.05
    return bp(noise(d), 2000, 6000) * env_exp(d, 0.008) * 0.5


# ================================================================== production

def family_names():
    out = []
    for fam, cls in FAMILIES.items():
        for part in ("cast", "hit", "boom", "loop", "proj"):
            if hasattr(cls, part):
                out.append(("%s_%s" % (fam, part), fam, part))
    return out


def render(name):
    """Rend le son « name » (registre ou famille) : signal normalisé, sonie de sa catégorie, et s'il boucle."""
    seed(int(hashlib.md5(name.encode()).hexdigest()[:8], 16))
    if name in REG:
        fn, cat, loop = REG[name]
        x = fn()
    else:
        fam, part = name.rsplit("_", 1)
        x = getattr(FAMILIES[fam], part)(0)
        cat = {"cast": "cast", "hit": "hit", "boom": "boom", "loop": "loop", "proj": "proj"}[part]
        loop = part == "loop"
    x = np.asarray(x, dtype=np.float64)
    if not loop:
        x = trim_tail(fade(x, 0.002, 0.04))
    x = normalize(x, LOUD[cat])
    return x, cat, loop


def all_names():
    return [n for (n, _, _) in family_names()] + list(REG.keys())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--png", default="")
    a = ap.parse_args()
    names = [n for n in all_names() if a.only in n]
    total = 0
    bad = []
    for n in names:
        try:
            x, cat, loop = render(n)
        except Exception as ex:
            import traceback
            bad.append((n, traceback.format_exc().strip().splitlines()[-3:]))
            continue
        p = os.path.join(OUT, n + ".ogg")
        write_ogg(p, x, quality=1, out_sr=24000)
        total += os.path.getsize(p)
        if a.png:
            os.makedirs(a.png, exist_ok=True)
            spectrogram_png(os.path.join(a.png, n + ".png"), x, "%s (%s, %.1f dB)" % (n, cat, loudness(x)))
        print("%-26s %-7s %5.2fs %6.1f kB" % (n, cat, len(x) / SR, os.path.getsize(p) / 1024))
    print("total %.1f kB, %d sons" % (total / 1024, len(names) - len(bad)))
    for n, tb in bad:
        print("ÉCHEC", n, " | ".join(tb))


if __name__ == "__main__":
    main()
