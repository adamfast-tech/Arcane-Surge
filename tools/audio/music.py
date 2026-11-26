"""Musiques d'Arcane Surge : partitions écrites en Python, jouées par FluidSynth (FluidR3 GM), mixées et
bouclées sans couture.

Usage : python3 tools/audio/music.py [--only motif] [--png dossier]
Chaque morceau a une tonalité, un mode, une grille d'accords (degrés), une mélodie (motif de degrés transposé
sur chaque accord, ou écrite note à note pour les thèmes) et un arrangement (nappes, basse, arpèges, ostinato,
percussions). Le rendu dépasse la fin de la boucle ; la queue (réverbération, notes tenues) est repliée sur le
début : la boucle ne s'entend pas. Encodage OGG stéréo, 24 kHz."""
import os, sys, argparse, subprocess, tempfile, wave
import numpy as np
import mido
sys.path.insert(0, os.path.dirname(__file__))
from synth import *
import pedalboard as pb

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "audio", "music")
MSR = 32000

SCALES = {"ionian": [0, 2, 4, 5, 7, 9, 11], "dorian": [0, 2, 3, 5, 7, 9, 10], "phrygian": [0, 1, 3, 5, 7, 8, 10],
          "aeolian": [0, 2, 3, 5, 7, 8, 10], "mixolydian": [0, 2, 4, 5, 7, 9, 10], "lydian": [0, 2, 4, 6, 7, 9, 11],
          "hijaz": [0, 1, 4, 5, 7, 8, 10], "harmonic": [0, 2, 3, 5, 7, 8, 11]}
NOTE = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


class Song:
    def __init__(self, name, bpm, key, scale, bars, beats=4):
        self.name, self.bpm, self.beats, self.bars = name, bpm, beats, bars
        self.root = 60 + NOTE[key]
        self.scale = SCALES[scale]
        self.tracks = []  # [program, chan, vol, pan, rev, notes[(beat, midi, dur, vel)]]

    def track(self, program, vol=100, pan=64, rev=40, chan=None):
        ch = chan if chan is not None else len([t for t in self.tracks if t[1] != 9])
        if ch >= 9 and chan is None:
            ch += 1
        t = [program, ch, vol, pan, rev, []]
        self.tracks.append(t)
        return t

    def deg(self, d, octv=0):
        """Degré de la gamme (1 = tonique ; 8 = tonique à l'octave) -> note MIDI."""
        d0 = d - 1
        return self.root + 12 * (octv + d0 // 7) + self.scale[d0 % 7]

    def chord(self, d, octv=0, n=3):
        return [self.deg(d + 2 * k, octv) for k in range(n)]

    def add(self, tr, beat, midi, dur, vel=90):
        tr[5].append((beat, int(midi), dur, int(max(1, min(127, vel)))))

    @property
    def length_beats(self):
        return self.bars * self.beats


# ------------------------------------------------------------------ arrangements

def pad(s, tr, prog, octv=0, vel=70, n=3, every=None):
    """Nappe : l'accord de chaque mesure tenu (ou rejoué toutes les « every » temps)."""
    for b, d in enumerate(prog):
        if d is None:
            continue
        step = every or s.beats
        for k in range(0, s.beats, step):
            for m in s.chord(d, octv, n):
                s.add(tr, b * s.beats + k, m, step * 0.98, vel)


def bass(s, tr, prog, pattern=(0, 2), octv=-2, vel=95, fifth=False):
    for b, d in enumerate(prog):
        if d is None:
            continue
        for i, k in enumerate(pattern):
            nxt = pattern[i + 1] if i + 1 < len(pattern) else s.beats
            m = s.deg(d, octv) + (7 if fifth and i % 2 == 1 else 0)
            s.add(tr, b * s.beats + k, m, (nxt - k) * 0.95, vel - (0 if i == 0 else 10))


def arp(s, tr, prog, step=0.5, octv=0, vel=70, shape=(0, 1, 2, 3, 2, 1), n=4):
    for b, d in enumerate(prog):
        if d is None:
            continue
        notes = s.chord(d, octv, 3) + [s.deg(d, octv + 1)]
        k = 0.0
        i = 0
        while k < s.beats - 1e-6:
            s.add(tr, b * s.beats + k, notes[shape[i % len(shape)] % len(notes)], step * 1.6, vel - (0 if i % 4 == 0 else 12))
            k += step
            i += 1


def ostinato(s, tr, prog, step=0.5, octv=-1, vel=85, figure=(0, 0, 4, 0, 0, 4, 0, 5)):
    """Ostinato de cordes (croches ou doubles) : la tonique de l'accord et ses voisines."""
    for b, d in enumerate(prog):
        if d is None:
            continue
        k = 0.0
        i = 0
        while k < s.beats - 1e-6:
            s.add(tr, b * s.beats + k, s.deg(d + figure[i % len(figure)], octv), step * 0.85, vel - (0 if i % 4 == 0 else 15))
            k += step
            i += 1


def melody(s, tr, notes, start_bar=0, octv=1, vel=95):
    """notes : [(degré ou None, durée en temps)]."""
    beat = start_bar * s.beats
    for d, dur in notes:
        if d is not None:
            s.add(tr, beat, s.deg(d, octv), dur * 0.95, vel)
        beat += dur


def motif_melody(s, tr, prog, motif, octv=1, vel=92, cadence_every=4):
    """Mélodie tirée d'un motif (degrés relatifs à l'accord, durées) transposé sur chaque accord ; une note
    longue sur la tonique de l'accord toutes les « cadence_every » mesures (fin de phrase)."""
    for b, d in enumerate(prog):
        if d is None:
            continue
        if (b + 1) % cadence_every == 0:
            s.add(tr, b * s.beats, s.deg(d + 2, octv), s.beats * 0.5, vel)
            s.add(tr, b * s.beats + s.beats * 0.5, s.deg(d, octv), s.beats * 0.48, vel - 5)
            continue
        beat = b * s.beats
        for rel, dur in motif[b % 2] if isinstance(motif[0], list) else motif:
            if rel is not None:
                s.add(tr, beat, s.deg(d + rel, octv), dur * 0.92, vel - (0 if beat % s.beats == 0 else 8))
            beat += dur


def drums(s, pattern, bars=None, vel=100, start=0):
    """Percussions (canal 10) : pattern = {note: [temps…]} répété à chaque mesure."""
    tr = next((t for t in s.tracks if t[1] == 9), None) or s.track(0, 110, 64, 25, chan=9)
    for b in (bars if bars is not None else range(start, s.bars)):
        for note, beats in pattern.items():
            for k in beats:
                v = vel if k == int(k) else vel - 15
                s.add(tr, b * s.beats + k, note, 0.2, v + int(rng.integers(-6, 6)))
    return tr


def fill(s, bar, note=47, n=8, vel=110):
    tr = next((t for t in s.tracks if t[1] == 9), None) or s.track(0, 110, 64, 25, chan=9)
    for i in range(n):
        s.add(tr, bar * s.beats + s.beats - n * 0.25 + i * 0.25, note - (i // 3) * 2, 0.2, vel - 20 + i * 4)


# ------------------------------------------------------------------ rendu

def to_midi(s):
    mid = mido.MidiFile(ticks_per_beat=480)
    meta = mido.MidiTrack()
    mid.tracks.append(meta)
    meta.append(mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(s.bpm)))
    for prog, ch, vol, pan, rev, notes in s.tracks:
        tr = mido.MidiTrack()
        mid.tracks.append(tr)
        if ch != 9:
            tr.append(mido.Message("program_change", channel=ch, program=prog))
        tr.append(mido.Message("control_change", channel=ch, control=7, value=vol))
        tr.append(mido.Message("control_change", channel=ch, control=10, value=pan))
        tr.append(mido.Message("control_change", channel=ch, control=91, value=rev))
        tr.append(mido.Message("control_change", channel=ch, control=93, value=10))
        ev = []
        for (b, m, d, v) in notes:
            ev.append((b, 1, m, v))
            ev.append((b + d, 0, m, 0))
        ev.sort(key=lambda e: (e[0], e[1]))
        last = 0
        for (b, on, m, v) in ev:
            tk = int(round(b * 480))
            tr.append(mido.Message("note_on" if on else "note_off", channel=ch, note=m, velocity=v, time=max(0, tk - last)))
            last = tk
    return mid


def render(s, tail=4.0):
    mid = to_midi(s)
    with tempfile.TemporaryDirectory() as d:
        mp = os.path.join(d, "s.mid")
        wp = os.path.join(d, "s.wav")
        mid.save(mp)
        subprocess.run(["fluidsynth", "-ni", "-g", "0.6", "-r", str(MSR), "-R", "1", "-C", "1", "-F", wp, SF2, mp],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        with wave.open(wp) as w:
            raw = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768.0
    x = raw.reshape(-1, 2)
    loop_n = int(round(s.length_beats * 60.0 / s.bpm * MSR))
    need = loop_n + int(tail * MSR)
    if len(x) < need:
        x = np.concatenate([x, np.zeros((need - len(x), 2))])
    # Polissage : un peu de salle, compression douce, limiteur.
    y = pb.Pedalboard([pb.Reverb(room_size=0.55, damping=0.5, wet_level=0.12, dry_level=0.92, width=1.0),
                       pb.Compressor(threshold_db=-18, ratio=2.5, attack_ms=15, release_ms=200),
                       pb.Limiter(threshold_db=-1.5, release_ms=120)])(x.T.astype(np.float32), MSR).T.astype(np.float64)
    # Boucle : la queue (au-delà de la dernière mesure) est repliée sur le début.
    t_n = len(y) - loop_n
    loop = y[:loop_n].copy()
    loop[:t_n] += y[loop_n:loop_n + t_n]
    return loop


def loud_st(x):
    from synth import loudness as L
    return L(x.mean(axis=1))


def finish(x, target=-17.0):
    cur = loud_st(x)
    x = x * 10 ** ((target - cur) / 20)
    m = np.max(np.abs(x))
    if m > 0.95:
        x = x * 0.95 / m
    return x


# ================================================================== morceaux

SONGS = {}


def song(fn):
    SONGS[fn.__name__] = fn
    return fn


@song
def havre():
    """Thème principal (Havre-Aube, écran titre) : chaleureux et un peu nostalgique."""
    s = Song("havre", 84, "D", "ionian", 16)
    prog = [1, 6, 4, 5, 1, 3, 4, 5, 6, 4, 1, 5, 4, 5, 1, 1]
    strings = s.track(48, 78, 64, 60)
    pad(s, strings, prog, 0, 62)
    harp = s.track(46, 92, 40, 50)
    arp(s, harp, prog, 0.5, 0, 70, (0, 1, 2, 3, 2, 1, 0, 1))
    cello = s.track(42, 95, 70, 40)
    bass(s, cello, prog, (0, 2), -2, 85)
    A = [(3, 1.5), (4, 0.5), (5, 2), (6, 1), (5, 1), (3, 2), (4, 1.5), (5, 0.5), (6, 1), (8, 1), (7, 2), (5, 2),
         (3, 1.5), (4, 0.5), (5, 2), (7, 1), (6, 1), (5, 2), (6, 1), (8, 1), (9, 1), (8, 1), (7, 1), (6, 1), (5, 2)]
    B = [(8, 1.5), (7, 0.5), (6, 2), (6, 1), (5, 1), (4, 2), (5, 1), (3, 1), (5, 1), (8, 1), (7, 3), (5, 1),
         (6, 1.5), (8, 0.5), (6, 1), (4, 1), (5, 1), (7, 1), (9, 2), (8, 4), (None, 2), (5, 1), (7, 1)]
    flute = s.track(73, 96, 80, 55)
    melody(s, flute, A, 0, 1, 92)
    horn = s.track(60, 100, 56, 55)
    melody(s, horn, B, 8, 0, 95)
    vln = s.track(40, 70, 72, 60)
    melody(s, vln, B, 8, 1, 70)
    timp = s.track(47, 90, 64, 40)
    for b in (8, 12, 14):
        s.add(timp, b * 4, s.deg(1, -2), 1, 85)
    cel = s.track(8, 80, 90, 70)
    for k, d in enumerate([8, 10, 12, 15]):
        s.add(cel, 14 * 4 + k * 0.5, s.deg(d, 1), 1.5, 70)
    return s


@song
def map():
    """Carte du monde : l'aventure qui commence, pizzicati et bois."""
    s = Song("map", 104, "G", "ionian", 16)
    prog = [1, 5, 6, 4, 1, 5, 4, 5, 6, 3, 4, 1, 2, 5, 1, 5]
    pz = s.track(45, 100, 50, 40)
    arp(s, pz, prog, 0.5, -1, 80, (0, 2, 1, 2))
    st = s.track(49, 70, 64, 60)
    pad(s, st, prog, 0, 55)
    b = s.track(32, 95, 64, 30)
    bass(s, b, prog, (0, 1.5, 2, 3.5), -2, 85)
    motif = [[(0, 1), (2, 0.5), (4, 0.5), (3, 1), (2, 1)], [(4, 1.5), (3, 0.5), (2, 1), (1, 1)]]
    cl = s.track(71, 95, 76, 50)
    motif_melody(s, cl, prog[:8], motif, 1, 90)
    ob = s.track(68, 92, 60, 50)
    motif_melody(s, ob, [None] * 8 + prog[8:], [[(2, 1), (1, 0.5), (0, 0.5), (2, 1), (4, 1)], [(5, 1.5), (4, 0.5), (2, 2)]], 1, 88)
    drums(s, {35: [0, 2], 75: [1, 3], 54: [0.5, 1.5, 2.5, 3.5]}, vel=70)
    return s


def battle_base(s, prog, lead_prog, lead_motif, perc, strings_fig=(0, 0, 4, 0, 0, 4, 0, 5), drum_vel=105, choir=True,
                bass_pat=(0, 0.75, 1.5, 2, 2.75, 3.5)):
    st = s.track(48, 92, 64, 45)
    ostinato(s, st, prog, 0.5, -1, 90, strings_fig)
    lo = s.track(43, 100, 64, 35)
    bass(s, lo, prog, bass_pat, -2, 98)
    pd = s.track(52 if choir else 49, 70, 64, 70)
    pad(s, pd, prog, 0, 60)
    ld = s.track(lead_prog, 100, 70, 55)
    motif_melody(s, ld, prog, lead_motif, 1 if lead_prog not in (60, 61, 57, 42) else 0, 98)
    drums(s, perc, vel=drum_vel)
    for b in range(3, s.bars, 4):
        fill(s, b, 47, 6, 108)
    drums(s, {49: [0]}, bars=range(0, s.bars, 8), vel=100)
    return s


@song
def battle_z1():
    """Forêt du Murmure : mystère et élan, harpe et flûte au-dessus des cordes."""
    s = Song("battle_z1", 116, "D", "dorian", 24)
    prog = [1, 7, 4, 1, 1, 7, 6, 5, 4, 5, 1, 7, 4, 5, 6, 5, 1, 7, 4, 1, 6, 4, 5, 5]
    battle_base(s, prog, 73, [[(0, 0.5), (2, 0.5), (4, 1), (3, 0.5), (2, 0.5), (1, 1)], [(2, 1), (4, 1), (5, 1.5), (4, 0.5)]],
                {116: [0, 2.5], 117: [1.5, 3], 70: [0.5, 1.5, 2.5, 3.5]}, choir=True)
    hp_ = s.track(46, 85, 30, 50)
    arp(s, hp_, prog, 0.25, 0, 60, (0, 1, 2, 3))
    return s


@song
def battle_z2():
    """Collines d'Ambre : galop, cuivres et violon des steppes."""
    s = Song("battle_z2", 132, "A", "mixolydian", 24)
    prog = [1, 7, 4, 1, 1, 7, 5, 5, 4, 4, 1, 1, 7, 4, 5, 5, 1, 7, 4, 1, 6, 7, 1, 5]
    battle_base(s, prog, 110, [[(0, 0.5), (0, 0.5), (2, 0.5), (4, 0.5), (5, 1), (4, 1)], [(2, 0.5), (3, 0.5), (4, 1), (2, 1), (0, 1)]],
                {35: [0, 1.5, 2], 38: [1, 3], 116: [0, 2], 54: [0.5, 1.5, 2.5, 3.5]}, choir=False)
    br = s.track(61, 85, 55, 45)
    for b, d in enumerate(prog):
        if b % 2 == 0:
            for m in s.chord(d, -1):
                s.add(br, b * 4, m, 0.4, 95)
                s.add(br, b * 4 + 1.5, m, 0.4, 85)
    return s


@song
def battle_z3():
    """Marais Murmurants : trémolos graves, clarinette, chœur étouffé."""
    s = Song("battle_z3", 100, "E", "phrygian", 24)
    prog = [1, 2, 1, 7, 6, 2, 1, 1, 4, 2, 1, 7, 6, 7, 1, 2, 1, 2, 1, 7, 6, 5, 4, 2]
    battle_base(s, prog, 71, [[(0, 1), (1, 0.5), (0, 0.5), (4, 1.5), (3, 0.5)], [(2, 1), (1, 1), (0, 2)]],
                {117: [0, 1.5, 2.5], 41: [3, 3.5], 69: [0.5, 1.5, 2.5, 3.5]}, (0, 1, 0, 1, 0, 1, 0, 4), drum_vel=95, choir=True)
    tr = s.track(44, 80, 64, 60)
    pad(s, tr, prog, -1, 60)
    return s


@song
def battle_z4():
    """Pics Gelés : ostinato de glockenspiel, cors épiques, timbales."""
    s = Song("battle_z4", 120, "B", "aeolian", 24)
    prog = [1, 6, 3, 7, 1, 6, 4, 5, 6, 7, 1, 1, 4, 5, 6, 5, 1, 6, 3, 7, 4, 6, 7, 5]
    battle_base(s, prog, 60, [[(0, 1.5), (2, 0.5), (4, 1), (5, 1)], [(4, 1), (2, 1), (1, 1), (2, 1)]],
                {47: [0, 2], 116: [0, 1.5, 2, 3], 81: [1, 3]}, choir=True)
    gl = s.track(9, 75, 85, 60)
    arp(s, gl, prog, 0.5, 1, 62, (0, 2, 1, 3, 2, 1))
    return s


@song
def battle_z5():
    """Désert de Verre : mode « hijaz », luth pincé, flûte de roseau, tambours sur la peau."""
    s = Song("battle_z5", 112, "D", "hijaz", 24)
    prog = [1, 2, 1, 7, 1, 2, 4, 5, 6, 5, 4, 2, 1, 2, 7, 1, 4, 5, 4, 2, 1, 7, 2, 1]
    battle_base(s, prog, 77, [[(0, 0.5), (1, 0.5), (2, 1), (1, 0.5), (0, 0.5), (1, 1)], [(4, 1.5), (3, 0.5), (2, 1), (1, 1)]],
                {60: [0, 0.75, 1.5, 2.5, 3], 62: [1, 2, 3.5], 63: [1.75, 3.75], 54: [0.5, 2.5]}, (0, 1, 2, 1, 0, 1, 2, 4), choir=False)
    oud = s.track(106, 85, 40, 40)
    arp(s, oud, prog, 0.5, 0, 72, (0, 1, 0, 2, 0, 1, 3, 1))
    return s


@song
def battle_z6():
    """Forêt Cendrée : taikos, cuivres graves, chœur, urgence."""
    s = Song("battle_z6", 138, "C", "aeolian", 24)
    prog = [1, 1, 6, 7, 1, 1, 4, 5, 6, 6, 7, 7, 1, 4, 5, 5, 1, 1, 6, 7, 4, 6, 7, 5]
    battle_base(s, prog, 61, [[(0, 1), (2, 0.5), (4, 0.5), (5, 1), (4, 1)], [(2, 0.5), (1, 0.5), (0, 1), (4, 2)]],
                {116: [0, 0.5, 1.5, 2, 3], 35: [0, 2], 38: [1, 3], 52: [3.5]}, drum_vel=112, choir=True)
    tb = s.track(57, 90, 64, 40)
    bass(s, tb, prog, (0, 2), -1, 95)
    return s


@song
def battle_z7():
    """Cité Engloutie : nappes, harpe et marimba, voix « oh », un pas qui ondule."""
    s = Song("battle_z7", 104, "F#", "dorian", 24)
    prog = [1, 4, 1, 7, 6, 4, 5, 5, 1, 4, 1, 7, 3, 4, 5, 5, 6, 4, 1, 7, 6, 4, 2, 5]
    battle_base(s, prog, 53, [[(0, 1), (2, 1), (4, 1.5), (5, 0.5)], [(4, 1), (2, 1), (0, 2)]],
                {117: [0, 2.5], 70: [0.5, 1, 1.5, 2.5, 3, 3.5], 64: [1, 3]}, (0, 2, 4, 2, 0, 2, 4, 5), drum_vel=90, choir=False)
    mr = s.track(12, 85, 80, 70)
    arp(s, mr, prog, 0.25, 0, 60, (0, 2, 1, 3))
    hp_ = s.track(46, 80, 40, 70)
    arp(s, hp_, prog, 0.5, 1, 55, (3, 2, 1, 0))
    return s


@song
def boss_1():
    """Boss (zones 1 à 3) : ostinato acharné, cuivres, chœur, timbales."""
    s = Song("boss_1", 146, "A", "harmonic", 24)
    prog = [1, 1, 6, 5, 1, 1, 4, 5, 6, 4, 5, 1, 6, 4, 2, 5, 1, 1, 6, 5, 4, 6, 5, 5]
    battle_base(s, prog, 61, [[(0, 0.5), (0, 0.5), (4, 1), (3, 0.5), (2, 0.5), (1, 1)], [(0, 1), (6, 1), (4, 2)]],
                {116: [0, 1, 2, 3], 35: [0, 0.5, 2], 38: [1, 3], 47: [3.5]}, (0, 0, 2, 0, 0, 2, 0, 4), drum_vel=115, choir=True)
    oh = s.track(55, 80, 64, 40)
    for b in range(0, s.bars, 4):
        s.add(oh, b * 4, s.deg(prog[b], -1), 1, 110)
    return s


@song
def boss_2():
    """Boss (zones 4 à 7) : plus grave et plus large, chœur et cuivres en accords."""
    s = Song("boss_2", 152, "D", "harmonic", 24)
    prog = [1, 6, 1, 5, 4, 6, 5, 5, 1, 6, 2, 5, 6, 4, 5, 1, 1, 6, 1, 5, 4, 2, 5, 5]
    battle_base(s, prog, 60, [[(0, 1), (2, 1), (4, 0.5), (5, 0.5), (4, 1)], [(2, 0.5), (1, 0.5), (0, 1), (4, 1), (7, 1)]],
                {116: [0, 0.5, 1, 2, 2.5, 3], 35: [0, 2], 38: [1, 3], 49: [], 47: [3, 3.5]}, (0, 0, 4, 0, 0, 5, 0, 4), drum_vel=118, choir=True)
    br = s.track(61, 92, 64, 45)
    pad(s, br, prog, -1, 85, 3, 2)
    return s


@song
def cine_calm():
    """Cinématiques paisibles : cordes lentes, harpe, flûte."""
    s = Song("cine_calm", 66, "F", "ionian", 12)
    prog = [1, 6, 4, 5, 1, 3, 4, 5, 6, 4, 2, 5]
    st = s.track(49, 75, 64, 70)
    pad(s, st, prog, 0, 55)
    hp_ = s.track(46, 85, 45, 60)
    arp(s, hp_, prog, 1.0, 0, 60, (0, 1, 2, 3))
    cl = s.track(42, 85, 70, 50)
    bass(s, cl, prog, (0,), -2, 75)
    fl = s.track(73, 82, 80, 65)
    melody(s, fl, [(5, 3), (6, 1), (5, 2), (3, 2), (4, 3), (5, 1), (2, 4), (3, 3), (5, 1), (6, 2), (5, 2), (4, 2), (3, 2), (2, 4)], 4, 1, 72)
    return s


@song
def cine_mystery():
    """Mystère, magie, secrets : célesta, nappes, chœur lointain."""
    s = Song("cine_mystery", 72, "E", "dorian", 12)
    prog = [1, 2, 1, 4, 1, 2, 6, 5, 1, 4, 7, 1]
    pd = s.track(89, 75, 64, 80)
    pad(s, pd, prog, 0, 55)
    ch = s.track(53, 60, 64, 90)
    pad(s, ch, [p if i % 2 == 0 else None for i, p in enumerate(prog)], 1, 45)
    ce = s.track(8, 85, 80, 80)
    arp(s, ce, prog, 0.75, 1, 55, (0, 3, 1, 2))
    lo = s.track(43, 80, 64, 50)
    bass(s, lo, prog, (0,), -2, 70)
    return s


@song
def cine_tension():
    """Tension, danger : pulsations graves, trémolos, timbales."""
    s = Song("cine_tension", 92, "C", "phrygian", 12)
    prog = [1, 1, 2, 1, 1, 1, 7, 2, 1, 6, 2, 1]
    tr = s.track(44, 80, 64, 50)
    pad(s, tr, prog, -1, 65)
    lo = s.track(43, 95, 64, 40)
    ostinato(s, lo, prog, 0.5, -2, 80, (0, 0, 0, 0, 0, 0, 1, 0))
    tm = s.track(47, 90, 64, 40)
    for b in range(s.bars):
        s.add(tm, b * 4, s.deg(1, -2), 1, 80 if b % 2 else 95)
        if b % 4 == 3:
            for k in range(8):
                s.add(tm, b * 4 + 2 + k * 0.25, s.deg(1, -2), 0.25, 60 + k * 6)
    hn = s.track(60, 80, 64, 60)
    melody(s, hn, [(None, 16), (5, 4), (6, 2), (5, 2), (2, 8), (None, 16)], 0, -1, 80)
    return s


@song
def cine_heroic():
    """Héroïque : fin d'acte, victoire, serment. Cuivres et cordes."""
    s = Song("cine_heroic", 88, "C", "ionian", 12)
    prog = [1, 5, 6, 4, 1, 5, 4, 5, 6, 4, 5, 1]
    st = s.track(48, 85, 64, 60)
    pad(s, st, prog, 0, 70)
    lo = s.track(43, 90, 64, 40)
    bass(s, lo, prog, (0, 2), -2, 85)
    hn = s.track(60, 100, 60, 55)
    melody(s, hn, [(5, 1.5), (5, 0.5), (8, 2), (7, 1), (5, 1), (6, 2), (6, 1.5), (5, 0.5), (4, 2), (3, 2), (4, 1), (5, 1),
                   (5, 1.5), (5, 0.5), (8, 2), (9, 1), (8, 1), (7, 2), (6, 2), (5, 2), (5, 4), (6, 2), (4, 2), (5, 2), (7, 2),
                   (8, 4), (None, 4)], 0, 0, 98)
    tp = s.track(56, 85, 70, 55)
    for b in (3, 7, 11):
        for m in s.chord(prog[b], 0):
            s.add(tp, b * 4 + 3, m, 0.9, 95)
    tm = s.track(47, 95, 64, 40)
    for b in range(s.bars):
        s.add(tm, b * 4, s.deg(1 if prog[b] != 5 else 5, -2), 1, 80)
    return s


def build(name, png_dir=""):
    seed(abs(hash(name)) % (2 ** 31))
    s = SONGS[name]()
    x = render(s)
    x = finish(x, -17.0 if not name.startswith("cine") else -20.0)
    p = os.path.join(OUT, name + ".ogg")
    write_ogg(p, x, quality=0, sr=MSR, stereo=True, out_sr=24000)
    if png_dir:
        os.makedirs(png_dir, exist_ok=True)
        import synth
        old = synth.SR
        synth.SR = MSR
        spectrogram_png(os.path.join(png_dir, name + ".png"), x.mean(axis=1), "%s %.0fs" % (name, len(x) / MSR))
        synth.SR = old
    return os.path.getsize(p), len(x) / MSR


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--png", default="")
    a = ap.parse_args()
    total = 0
    for n in SONGS:
        if a.only not in n:
            continue
        sz, dur = build(n, a.png)
        total += sz
        print("%-14s %5.1fs %6.1f kB" % (n, dur, sz / 1024))
    print("total %.1f kB" % (total / 1024))


if __name__ == "__main__":
    main()
