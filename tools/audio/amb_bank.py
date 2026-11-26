"""Ambiances en boucle d'Arcane Surge (combats, cinématiques, salles de Havre-Aube).

Usage : python3 tools/audio/amb_bank.py [--only motif] [--png dossier]
Chaque ambiance dure LEN secondes et boucle sans couture (la fin est fondue dans le début). Les évènements rares
(hibou, tonnerre lointain) y sont peu nombreux : le jeu peut en ajouter au hasard (thunder_far…)."""
import os, sys, argparse, hashlib
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
from synth import *
import sfx_bank as B

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "audio", "amb")
LEN = 12.0
XF = 1.2
REG = {}


def amb(name):
    def deco(fn):
        REG[name] = fn
        return fn
    return deco


def T():
    return LEN + XF


def gusts(d, base=500, rate=0.12, depth=0.7, q=1.2, color="pink"):
    """Vent : bruit filtré dont la fréquence et le volume ondulent lentement (rafales)."""
    t = t_axis(d)
    ph = rng.uniform(0, 6)
    mod = 0.5 + 0.5 * np.sin(2 * np.pi * rate * t + ph) * np.sin(2 * np.pi * rate * 0.37 * t + ph * 2)
    x = filt_sweep(noise(d, color), base * (0.7 + 0.8 * mod), "band", q)
    return x * (1 - depth + depth * mod)


def crickets(d, n=3, f=4600, rate=14.0):
    out = silence(d)
    for k in range(n):
        ff = f * rng.uniform(0.9, 1.1)
        r = rate * rng.uniform(0.8, 1.2)
        t0 = 0.0
        while t0 < d - 1.0:
            burst = rng.uniform(0.3, 0.9)
            ln = int(burst * SR)
            t = np.arange(ln) / SR
            chirp = np.sin(2 * np.pi * ff * t) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * r * t))) * np.hanning(ln)
            out = mix(d, (0, out, 1), (t0, chirp, rng.uniform(0.15, 0.35)))
            t0 += burst + rng.uniform(0.3, 1.6)
    return out


def owl(d):
    out = silence(d)
    for t0 in (rng.uniform(1.5, 4.5), rng.uniform(7, 9.5)):
        for k, (ln, f) in enumerate(((0.35, 390), (0.6, 380))):
            h = sine(f * (1 + 0.02 * np.sin(2 * np.pi * 5 * t_axis(ln))), ln) * env_curve(ln, [(0, 0), (0.05, 1), (ln * 0.7, 0.8), (ln, 0)])
            out = mix(d, (0, out, 1), (t0 + k * 0.55, h + 0.3 * sine(f * 2, ln) * env_curve(ln, [(0, 0), (0.05, 1), (ln, 0)]), 0.25))
    return out


def birds(d, n=10):
    out = silence(d)
    for _ in range(n):
        t0 = rng.uniform(0, d - 1)
        f0 = rng.uniform(2500, 4500)
        for k in range(rng.integers(2, 6)):
            ln = rng.uniform(0.06, 0.15)
            ch = sine(sweep(ln, f0 * rng.uniform(0.9, 1.3), f0 * rng.uniform(0.7, 1.1)), ln) * np.hanning(int(ln * SR))
            out = mix(d, (0, out, 1), (t0 + k * ln * 1.3, ch, rng.uniform(0.1, 0.25)))
    return out


def rain(d, density=900, heavy=1.0):
    drops = B.rustle(d, density, 2500, 9000) * 0.5
    hiss = bp(noise(d, "pink"), 1200, 8000) * 0.25 * heavy
    patter = silence(d)
    for _ in range(int(d * 25 * heavy)):
        t0 = rng.uniform(0, d - 0.05)
        f = rng.uniform(1500, 4000)
        ln = 0.03
        patter = mix(d, (0, patter, 1), (t0, sine(sweep(ln, f, f * 1.6), ln) * env_exp(ln, 0.008), rng.uniform(0.05, 0.2)))
    return drops + hiss + patter


def frogs(d):
    out = silence(d)
    for _ in range(14):
        t0 = rng.uniform(0, d - 1)
        f = rng.uniform(140, 320)
        for k in range(rng.integers(1, 4)):
            ln = 0.18
            t = t_axis(ln)
            c = saw(f * (1 + 0.3 * t / ln), ln, 20) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 45 * t))) * env_curve(ln, [(0, 0), (0.02, 1), (ln, 0)])
            c = reson(c, f * 4, 4) + reson(c, f * 7, 6) * 0.5
            out = mix(d, (0, out, 1), (t0 + k * 0.26, c, rng.uniform(0.15, 0.35)))
    return out


def bubbles(d, n=40, lo=250, hi=900):
    out = silence(d)
    for _ in range(n):
        t0 = rng.uniform(0, d - 0.1)
        f = rng.uniform(lo, hi)
        ln = 0.09
        out = mix(d, (0, out, 1), (t0, sine(sweep(ln, f, f * 2.4), ln) * env_exp(ln, 0.03), rng.uniform(0.1, 0.4)))
    return out


def chimes(d, notes=(76, 79, 83, 86, 88), n=12):
    out = silence(d)
    for _ in range(n):
        t0 = rng.uniform(0, d - 2)
        nn = notes[rng.integers(0, len(notes))]
        out = mix(d, (0, out, 1), (t0, B.bell(B.midi_hz(nn), 2.0, 0.6), rng.uniform(0.05, 0.15)))
    return out


# ------------------------------------------------------------------ ambiances

@amb("forest_night")
def a_forest_night():
    d = T()
    return gusts(d, 400, 0.08, 0.6) * 0.35 + crickets(d, 3) + owl(d) + B.rustle(d, 20) * 0.2


@amb("forest_day")
def a_forest_day():
    d = T()
    return gusts(d, 600, 0.1, 0.6) * 0.3 + birds(d, 12) + B.rustle(d, 25) * 0.2


@amb("wind_plains")
def a_wind_plains():
    d = T()
    return gusts(d, 450, 0.09, 0.8, 1.0) * 0.8 + B.rustle(d, 30, 2000, 7000) * 0.1 + birds(d, 2) * 0.5


@amb("rain")
def a_rain():
    d = T()
    return rain(d, 900, 1.0) + lp(noise(d, "brown"), 200) * 0.15


@amb("storm")
def a_storm():
    d = T()
    return rain(d, 1400, 1.6) + gusts(d, 350, 0.15, 0.8) * 0.6 + lp(noise(d, "brown"), 180) * 0.3


@amb("swamp")
def a_swamp():
    d = T()
    flies = bp(sum(saw(f * (1 + 0.04 * np.sin(2 * np.pi * r * t_axis(d))), d, 12) for f, r in ((220, 6), (236, 5))) * 0.02, 150, 2500)
    return frogs(d) + bubbles(d, 30) * 0.6 + crickets(d, 2, 3800, 20) * 0.6 + gusts(d, 300, 0.06, 0.5) * 0.2 + flies * env_curve(d, [(0, 0), (4, 1), (8, 0), (d, 0)])


@amb("wind_snow")
def a_wind_snow():
    d = T()
    howl = filt_sweep(noise(d, "pink"), 700 + 300 * np.sin(2 * np.pi * 0.07 * t_axis(d)), "band", 4.0) * 0.6
    return gusts(d, 900, 0.1, 0.7, 1.5) * 0.7 + howl + B.rustle(d, 40, 4000, 9000) * 0.05


@amb("blizzard")
def a_blizzard():
    d = T()
    howl = filt_sweep(noise(d, "pink"), 800 + 400 * np.sin(2 * np.pi * 0.11 * t_axis(d)), "band", 5.0) * 0.8
    return gusts(d, 1100, 0.2, 0.6, 1.3) * 1.0 + howl + B.rustle(d, 200, 4000, 10000) * 0.25 + B.sparkle(d, 25, 4000, 9000, 0.2, d) * 0.2


@amb("desert_wind")
def a_desert_wind():
    d = T()
    return gusts(d, 700, 0.07, 0.7, 1.0, "white") * 0.5 + B.rustle(d, 120, 3000, 9000) * 0.2 + B.sparkle(d, 6, 5000, 9000, 0.2, d) * 0.15


@amb("desert_night")
def a_desert_night():
    d = T()
    return gusts(d, 500, 0.05, 0.6) * 0.35 + crickets(d, 2, 5200, 18) * 0.7 + B.rustle(d, 30, 3000, 8000) * 0.1


@amb("fire_forest")
def a_fire_forest():
    d = T()
    roar = lp(noise(d, "brown"), 450) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.2 * t_axis(d)))
    return roar * 0.9 + B.embers(d, 30) * 0.18 + gusts(d, 300, 0.1, 0.6) * 0.3


@amb("lava")
def a_lava():
    d = T()
    blorp = silence(d)
    for _ in range(18):
        t0 = rng.uniform(0, d - 0.4)
        f = rng.uniform(60, 140)
        ln = 0.35
        blorp = mix(d, (0, blorp, 1), (t0, lp(sine(sweep(ln, f, f * 2.0), ln) * env_exp(ln, 0.1) + noise(ln, "brown") * env_exp(ln, 0.05) * 0.5, 600), rng.uniform(0.3, 0.7)))
    return B.rumble(d, 110, 0.3, 0.5) * 1.0 + blorp + B.embers(d, 12) * 0.12 + bp(noise(d), 2000, 6000) * 0.04


@amb("underwater")
def a_underwater():
    d = T()
    t = t_axis(d)
    drone = (sine(55, d) * 0.3 + sine(82.5, d) * 0.15) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.05 * t))
    current = lp(gusts(d, 250, 0.06, 0.7, 1.0), 800) * 0.7
    song = silence(d)
    for t0 in (rng.uniform(2, 4), rng.uniform(7, 9)):
        ln = 2.2
        f = 180 + 60 * np.sin(np.pi * t_axis(ln) / ln)
        song = mix(d, (0, song, 1), (t0, lp(B.formant_voice(f, ln, ("ou", "o"), 0.0, 0.1, 2, 0.02), 1200) * env_curve(ln, [(0, 0), (0.6, 1), (ln, 0)]), 0.08))
    return drone + current + bubbles(d, 45, 300, 1200) * 0.5 + song


@amb("cave")
def a_cave():
    d = T()
    drips = silence(d)
    for _ in range(16):
        t0 = rng.uniform(0, d - 0.3)
        f = rng.uniform(900, 2200)
        ln = 0.12
        drips = mix(d, (0, drips, 1), (t0, sine(sweep(ln, f, f * 1.8), ln) * env_exp(ln, 0.03), rng.uniform(0.2, 0.5)))
    drips = delay(drips, 0.23, 0.35, 0.35, 0.0)[:len(drips)]
    return lp(noise(d, "brown"), 120) * 0.4 + drips + gusts(d, 200, 0.04, 0.5) * 0.15


@amb("havre")
def a_havre():
    d = T()
    bell_ = silence(d)
    for t0 in (rng.uniform(3, 5),):
        for k in range(3):
            bell_ = mix(d, (0, bell_, 1), (t0 + k * 1.1, B.bell(B.midi_hz(55 + (k % 2) * 5), 3.0, 0.6), 0.08))
    return gusts(d, 550, 0.08, 0.6) * 0.25 + birds(d, 9) * 0.8 + B.rustle(d, 20) * 0.15 + bell_


@amb("forge")
def a_forge():
    d = T()
    hits = silence(d)
    for t0 in (1.5, 1.95, 2.4, 7.0, 7.4):
        hits = mix(d, (0, hits, 1), (t0, B.metal_ring(1100 * rng.uniform(0.95, 1.05), 0.9), 0.18), (t0, B.thump(160, 0.3, 0.6, 0.8), 0.12))
    roar = lp(noise(d, "brown"), 400) * 0.6
    bellows = silence(d)
    for t0 in (4.0, 9.8):
        bellows = mix(d, (0, bellows, 1), (t0, B.whoosh(1.2, 300, 900, 0.5, 1.0, "brown"), 0.4))
    return roar + B.embers(d, 18) * 0.15 + hits + bellows


@amb("campfire")
def a_campfire():
    d = T()
    return lp(noise(d, "brown"), 350) * 0.35 + B.embers(d, 22) * 0.2 + crickets(d, 2, 4400, 12) * 0.6


@amb("library")
def a_library():
    d = T()
    tick = silence(d)
    for k in range(int(d)):
        tick = mix(d, (0, tick, 1), (k + 0.0, B.wood_knock(1800, 0.05), 0.08), (k + 0.5, B.wood_knock(1500, 0.05), 0.06))
    page = silence(d)
    for t0 in (rng.uniform(3, 4.5), rng.uniform(8, 10)):
        page = mix(d, (0, page, 1), (t0, bp(noise(0.4), 1500, 7000) * env_curve(0.4, [(0, 0), (0.12, 1), (0.25, 0.4), (0.4, 0)]), 0.04))
    return lp(noise(d, "pink"), 400) * 0.08 + tick + page + B.embers(d, 5) * 0.05


@amb("meditation")
def a_meditation():
    d = T()
    lap = silence(d)
    for k in range(8):
        t0 = k * 1.6 + rng.uniform(0, 0.4)
        lap = mix(d, (0, lap, 1), (t0, lp(B.whoosh(1.2, 200, 700, 0.4, 1.0), 1200), 0.3))
    return lap + chimes(d, (72, 76, 79, 83, 84), 8) + crickets(d, 1, 5000, 10) * 0.3


@amb("arcane_hum")
def a_arcane_hum():
    d = T()
    t = t_axis(d)
    hum = (sine(110, d) * 0.15 + sine(165.2, d) * 0.08 + sine(220.4, d) * 0.05) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.11 * t))
    return hum + B.sparkle(d, 18, 3000, 8000, 0.4, d) * 0.15 + gusts(d, 300, 0.05, 0.5) * 0.1


def render(name):
    seed(int(hashlib.md5(name.encode()).hexdigest()[:8], 16))
    B.seed(int(hashlib.md5(name.encode()).hexdigest()[8:16], 16))
    x = REG[name]()
    x = B.make_loop(np.asarray(x, dtype=np.float64), XF)
    return normalize(x, -24.0, 0.8, 0.0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--png", default="")
    a = ap.parse_args()
    total = 0
    for n in REG:
        if a.only not in n:
            continue
        x = render(n)
        p = os.path.join(OUT, n + ".ogg")
        write_ogg(p, x, quality=0, out_sr=22050)
        total += os.path.getsize(p)
        if a.png:
            os.makedirs(a.png, exist_ok=True)
            spectrogram_png(os.path.join(a.png, n + ".png"), x, n)
        print("%-16s %5.1fs %6.1f kB" % (n, len(x) / SR, os.path.getsize(p) / 1024))
    print("total %.1f kB" % (total / 1024))


if __name__ == "__main__":
    main()
