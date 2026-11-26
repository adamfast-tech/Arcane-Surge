"""Boîte à outils de synthèse sonore d'Arcane Surge (docs/design/43-audio.md).

Tout est calculé en float32 mono (ou stéréo pour la musique) à SR Hz, puis encodé en OGG Vorbis par ffmpeg.
Briques : oscillateurs, bruits, enveloppes, filtres (fixes et balayés), FM, cordes pincées (Karplus-Strong),
distorsion, réverbération et compression (pedalboard), notes d'instruments réels (FluidSynth + FluidR3 GM),
mixage et normalisation de la sonie (on ne peut pas écouter : la sonie est mesurée)."""
import os, subprocess, tempfile, functools
import numpy as np
from scipy import signal
import pedalboard as pb

SR = 32000
SF2 = "/usr/share/sounds/sf2/FluidR3_GM.sf2"
rng = np.random.default_rng(1234)


def seed(n):
    """Graine du hasard, réglée en place : les modules qui ont importé « rng » suivent aussi (rendu reproductible)."""
    rng.bit_generator.state = np.random.default_rng(n).bit_generator.state


def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def silence(dur):
    return np.zeros(int(dur * SR), dtype=np.float64)


# ------------------------------------------------------------------ oscillateurs

def phase_of(freq, dur):
    """Phase intégrée d'une fréquence (constante, ou tableau qui varie dans le temps)."""
    n = int(dur * SR)
    f = np.broadcast_to(np.asarray(freq, dtype=np.float64), (n,)) if np.ndim(freq) == 0 else np.asarray(freq, dtype=np.float64)[:n]
    return 2 * np.pi * np.cumsum(f) / SR


def sine(freq, dur, ph0=0.0):
    return np.sin(phase_of(freq, dur) + ph0)


def saw(freq, dur, harmonics=40):
    """Dent de scie à bande limitée (additive) : pas de repliement."""
    ph = phase_of(freq, dur)
    f = float(np.max(freq)) if np.ndim(freq) else float(freq)
    nmax = max(1, min(harmonics, int((SR / 2) / max(f, 1.0))))
    out = np.zeros_like(ph)
    for k in range(1, nmax + 1):
        out += np.sin(k * ph) / k
    return out * (2 / np.pi)


def square(freq, dur, harmonics=30):
    ph = phase_of(freq, dur)
    f = float(np.max(freq)) if np.ndim(freq) else float(freq)
    nmax = max(1, min(harmonics, int((SR / 2) / max(f, 1.0))))
    out = np.zeros_like(ph)
    for k in range(1, nmax + 1, 2):
        out += np.sin(k * ph) / k
    return out * (4 / np.pi)


def tri(freq, dur):
    ph = phase_of(freq, dur)
    out = np.zeros_like(ph)
    for i, k in enumerate(range(1, 30, 2)):
        out += ((-1) ** i) * np.sin(k * ph) / (k * k)
    return out * (8 / np.pi ** 2)


def fm(carrier, ratio, index, dur, index_env=None):
    """Synthèse FM : cloches (ratio non entier), métal, timbres brillants."""
    n = int(dur * SR)
    ph_m = phase_of(np.asarray(carrier) * ratio, dur)
    idx = index if index_env is None else index * index_env[:n]
    return np.sin(phase_of(carrier, dur) + idx * np.sin(ph_m))


def noise(dur, color="white"):
    n = int(dur * SR)
    w = rng.standard_normal(n)
    if color == "white":
        return w / 3.0
    if color == "pink":
        b, a = [0.049922035, -0.095993537, 0.050612699, -0.004408786], [1, -2.494956002, 2.017265875, -0.522189400]
        return signal.lfilter(b, a, w) / 1.2
    if color == "brown":
        x = np.cumsum(w)
        x = signal.lfilter([1, -1], [1, -0.995], x)
        return x / (np.max(np.abs(x)) + 1e-9)
    raise ValueError(color)


def crackle(dur, density=40, decay=0.004):
    """Crépitement : grains de bruit très courts à fenêtre douce (feuilles, gravier, électricité statique).
    La fenêtre (Hann) évite les claquements à large bande d'une attaque instantanée."""
    n = int(dur * SR)
    out = np.zeros(n)
    k = int(density * dur)
    for p in rng.integers(0, n, k):
        ln = max(8, int(decay * SR * rng.uniform(1.0, 3.0)))
        seg = rng.standard_normal(ln) * np.hanning(ln) * rng.uniform(0.3, 1.0)
        out[p:p + ln] += seg[: max(0, min(ln, n - p))]
    return out


# ------------------------------------------------------------------ enveloppes

def env_adsr(dur, a=0.01, d=0.1, s=0.7, r=0.2):
    n = int(dur * SR)
    t = np.arange(n) / SR
    e = np.ones(n) * s
    e[t < a] = t[t < a] / max(a, 1e-6)
    m = (t >= a) & (t < a + d)
    e[m] = 1 - (1 - s) * (t[m] - a) / max(d, 1e-6)
    rel = t > dur - r
    e[rel] *= np.clip((dur - t[rel]) / max(r, 1e-6), 0, 1)
    return e


def env_exp(dur, decay, attack=0.002):
    t = t_axis(dur)
    e = np.exp(-t / max(decay, 1e-6))
    if attack > 0:
        e *= np.clip(t / attack, 0, 1)
    return e


def env_curve(dur, points):
    """Enveloppe par points [(t, valeur)…], interpolation linéaire."""
    t = t_axis(dur)
    xs, ys = zip(*points)
    return np.interp(t, xs, ys)


def sweep(dur, f0, f1, curve="exp"):
    t = t_axis(dur) / max(dur, 1e-6)
    if curve == "exp":
        return f0 * (f1 / f0) ** t
    return f0 + (f1 - f0) * t


# ------------------------------------------------------------------ filtres

def lp(x, fc, order=2):
    fc = min(fc, SR * 0.45)
    b, a = signal.butter(order, fc / (SR / 2), "low")
    return signal.lfilter(b, a, x)


def hp(x, fc, order=2):
    b, a = signal.butter(order, max(fc, 10) / (SR / 2), "high")
    return signal.lfilter(b, a, x)


def bp(x, lo, hi, order=2):
    hi = min(hi, SR * 0.45)
    b, a = signal.butter(order, [max(lo, 10) / (SR / 2), hi / (SR / 2)], "band")
    return signal.lfilter(b, a, x)


def reson(x, fc, q=8.0):
    """Résonateur (pic étroit) : formants, tubes, cloches."""
    fc = min(fc, SR * 0.45)
    b, a = signal.iirpeak(fc / (SR / 2), q)
    return signal.lfilter(b, a, x)


def filt_sweep(x, fcs, kind="low", q=0.707, block=64):
    """Filtre dont la fréquence suit le tableau fcs (balayage). Filtre à variables d'état « TPT »
    (Zavalishin) : stable quelle que soit la fréquence, contrairement au filtre de Chamberlin."""
    n = len(x)
    fcs = np.broadcast_to(np.asarray(fcs, dtype=np.float64), (n,)) if np.ndim(fcs) == 0 else np.asarray(fcs, dtype=np.float64)
    k = 1.0 / q
    out = np.zeros(n)
    ic1 = 0.0
    ic2 = 0.0
    for s0 in range(0, n, block):
        fc = float(min(max(fcs[min(s0, n - 1)], 20.0), SR * 0.45))
        g = np.tan(np.pi * fc / SR)
        a1 = 1.0 / (1.0 + g * (g + k))
        a2 = g * a1
        a3 = g * a2
        seg = x[s0:s0 + block]
        o = np.empty(len(seg))
        for i in range(len(seg)):
            v3 = seg[i] - ic2
            v1 = a1 * ic1 + a2 * v3
            v2 = ic2 + a2 * ic1 + a3 * v3
            ic1 = 2.0 * v1 - ic1
            ic2 = 2.0 * v2 - ic2
            if kind == "low":
                o[i] = v2
            elif kind == "band":
                o[i] = v1 * k
            else:
                o[i] = seg[i] - k * v1 - v2
        out[s0:s0 + block] = o
    return out


def comb_tube(x, freq, fb=0.85):
    """Peigne à rétroaction : tube, métal creux, voix d'outre-tombe."""
    d = max(1, int(SR / freq))
    y = np.copy(x)
    for i in range(d, len(y)):
        y[i] += fb * y[i - d]
    return y


# ------------------------------------------------------------------ sources physiques

def pluck(freq, dur, bright=0.5, decay=0.996):
    """Corde pincée (Karplus-Strong) : corde d'arc, luth, harpe."""
    n = int(dur * SR)
    p = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, p)
    buf = lp(buf, 1500 + 8000 * bright, 1)
    out = np.zeros(n)
    idx = 0
    for i in range(n):
        out[i] = buf[idx]
        nxt = (idx + 1) % p
        buf[idx] = decay * 0.5 * (buf[idx] + buf[nxt])
        idx = nxt
    return out


def membrane(f0, dur, drop=0.5, decay=0.25, tone=0.7):
    """Peau de tambour : fréquence qui chute, bruit de frappe."""
    f = f0 * (1 + drop * np.exp(-t_axis(dur) / 0.03))
    body = sine(f, dur) * env_exp(dur, decay)
    hit = lp(noise(dur), 3000) * env_exp(dur, 0.02)
    return body * tone + hit * (1 - tone)


def modal(freqs, amps, decays, dur):
    """Objet résonant (cloche, verre, enclume, os) : somme de modes amortis."""
    out = np.zeros(int(dur * SR))
    for f, a, d in zip(freqs, amps, decays):
        if f < SR / 2:
            out += a * sine(f, dur, rng.uniform(0, 6.28)) * env_exp(dur, d, 0.0005)
    return out


# ------------------------------------------------------------------ effets

def drive(x, amount=2.0):
    return np.tanh(x * amount) / np.tanh(amount)


def fade(x, fin=0.005, fout=0.05):
    n = len(x)
    a = min(n, int(fin * SR))
    b = min(n, int(fout * SR))
    x = x.copy()
    if a > 0:
        x[:a] *= np.linspace(0, 1, a)
    if b > 0:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def board(x, *fx):
    """Chaîne pedalboard (réverbération, chorus, délai, compression…)."""
    y = pb.Pedalboard(list(fx))(x.astype(np.float32), SR)
    return y.astype(np.float64)


def reverb(x, size=0.6, wet=0.3, damp=0.5, width=1.0, tail=1.0):
    x = np.concatenate([x, silence(tail)])
    return board(x, pb.Reverb(room_size=size, damping=damp, wet_level=wet, dry_level=1 - wet * 0.5, width=width))


def delay(x, t=0.18, fb=0.35, mix=0.3, tail=0.8):
    x = np.concatenate([x, silence(tail)])
    return board(x, pb.Delay(delay_seconds=t, feedback=fb, mix=mix))


def chorus(x, rate=0.8, depth=0.3, mix=0.5):
    return board(x, pb.Chorus(rate_hz=rate, depth=depth, mix=mix))


def pitch(x, semis):
    return board(x, pb.PitchShift(semitones=semis))


def compress(x, thr=-18, ratio=4):
    return board(x, pb.Compressor(threshold_db=thr, ratio=ratio, attack_ms=2, release_ms=120))


# ------------------------------------------------------------------ instruments réels (FluidSynth)

def _midi_bytes(notes, program, bank=0, chan=0):
    import mido
    mid = mido.MidiFile(ticks_per_beat=480)
    tr = mido.MidiTrack()
    mid.tracks.append(tr)
    tr.append(mido.MetaMessage("set_tempo", tempo=500000))
    if bank:
        tr.append(mido.Message("control_change", channel=chan, control=0, value=bank))
    tr.append(mido.Message("program_change", channel=chan, program=program))
    ev = []
    for (t, n, d, v) in notes:
        ev.append((t, "on", n, v))
        ev.append((t + d, "off", n, 0))
    ev.sort(key=lambda e: (e[0], e[1] == "on"))
    last = 0.0
    for (t, kind, n, v) in ev:
        dt = int(round((t - last) * 960))
        last = t
        tr.append(mido.Message("note_on" if kind == "on" else "note_off", channel=chan, note=int(n), velocity=int(v), time=max(0, dt)))
    return mid


@functools.lru_cache(maxsize=256)
def _gm_cached(key):
    notes, program, dur, chan = key
    mid = _midi_bytes(list(notes), program, chan=chan)
    with tempfile.TemporaryDirectory() as d:
        mp = os.path.join(d, "n.mid")
        wp = os.path.join(d, "n.wav")
        mid.save(mp)
        subprocess.run(["fluidsynth", "-ni", "-g", "0.8", "-r", str(SR), "-R", "0", "-C", "0", "-F", wp, SF2, mp],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        import wave
        with wave.open(wp) as w:
            raw = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768.0
            ch = w.getnchannels()
    if ch == 2:
        raw = raw.reshape(-1, 2).mean(axis=1)
    n = int(dur * SR)
    if len(raw) >= n:
        raw = raw[:n].copy()
        f = min(n, int(0.08 * SR))
        raw[-f:] *= np.linspace(1, 0, f)
    else:
        raw = np.concatenate([raw, np.zeros(n - len(raw))])
    if np.max(np.abs(raw)) < 2e-3:
        raise ValueError("FluidSynth : note muette (programme %d, notes %s)" % (program, [x[1] for x in notes]))
    return raw


def gm(notes, program, dur, chan=0):
    """Notes jouées par un instrument General MIDI : [(début s, note MIDI, durée s, vélocité)].
    chan=9 : percussions (note = instrument : 35 grosse caisse, 49 cymbale, 57 cymbale crash…)."""
    key = (tuple(tuple(x) for x in notes), int(program), float(dur), int(chan))
    return _gm_cached(key).copy()


# ------------------------------------------------------------------ mixage, sonie, export

def mix(dur, *layers):
    """layers : (début s, signal, gain)."""
    out = silence(dur)
    for (t0, sig, g) in layers:
        a = int(t0 * SR)
        if a >= len(out):
            continue
        b = min(len(out), a + len(sig))
        seg = np.array(sig[: b - a], dtype=np.float64) * g
        # Bords adoucis (3 ms, 12 ms) : une couche coupée net claquerait.
        fi = min(len(seg), int(0.003 * SR))
        fo = min(len(seg), int(0.012 * SR))
        if fi > 1:
            seg[:fi] *= np.linspace(0, 1, fi)
        if fo > 1 and b - a < len(sig):
            seg[-fo:] *= np.linspace(1, 0, fo)
        elif fo > 1:
            seg[-fo:] *= np.linspace(1, 0, fo) ** 0.5
        out[a:b] += seg
    return out


def pad_to(x, dur):
    n = int(dur * SR)
    return x[:n] if len(x) >= n else np.concatenate([x, np.zeros(n - len(x))])


def loudness(x, win=0.4):
    """Sonie approchée : RMS (dB) de la fenêtre la plus forte, après une pondération qui atténue les graves
    (proche de la pondération K)."""
    y = hp(x, 120, 1)
    y = y + 0.4 * hp(y, 2000, 1)
    n = max(1, int(win * SR))
    if len(y) <= n:
        return 20 * np.log10(np.sqrt(np.mean(y ** 2)) + 1e-9)
    sq = np.convolve(y ** 2, np.ones(n) / n, mode="valid")
    return 10 * np.log10(np.max(sq) + 1e-12)


def normalize(x, target_db=-16.0, peak=0.9, squash=3.0):
    """Amène le son à la sonie visée. Les crêtes sont d'abord tassées d'au plus « squash » dB par un
    compresseur rapide (pas de saturation), puis le gain est limité pour ne jamais dépasser « peak »."""
    x = x - np.mean(x)
    cur = loudness(x)
    g = 10 ** ((target_db - cur) / 20)
    y = x * g
    m = np.max(np.abs(y)) + 1e-9
    if m > peak and squash > 0:
        y = board(y / m * 0.5, pb.Compressor(threshold_db=-6 - squash * 2, ratio=6, attack_ms=0.5, release_ms=80)) * (m / 0.5)
        y = y * 10 ** ((target_db - loudness(y)) / 20)
        m = np.max(np.abs(y)) + 1e-9
    if m > peak:
        y = y * peak / m
    return y


def trim_tail(x, thr_db=-60.0):
    a = np.abs(x)
    thr = 10 ** (thr_db / 20) * np.max(a)
    idx = np.where(a > thr)[0]
    if len(idx) == 0:
        return x
    return fade(x[: idx[-1] + int(0.02 * SR)], 0.0, 0.03)


def write_ogg(path, x, quality=3, sr=SR, stereo=False, out_sr=None):
    """Encode en OGG Vorbis (ffmpeg, libvorbis). out_sr : rééchantillonne d'abord (22050 pour les ambiances)."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = np.asarray(x, dtype=np.float64)
    if out_sr and out_sr != sr:
        from math import gcd
        g = gcd(int(out_sr), int(sr))
        x = signal.resample_poly(x, int(out_sr) // g, int(sr) // g, axis=0)
        sr = out_sr
    x = np.asarray(x, dtype=np.float32)
    if stereo:
        data = x.reshape(-1).tobytes()
        ch = 2
    else:
        data = x.tobytes()
        ch = 1
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "f32le", "-ar", str(sr), "-ac", str(ch), "-i", "-",
                    "-c:a", "libvorbis", "-q:a", str(quality), path], input=data, check=True)


def spectrogram_png(path, x, title=""):
    """Image du spectre dans le temps : seul moyen de « voir » un son qu'on ne peut pas écouter."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    f, t, s = signal.spectrogram(x, SR, nperseg=512, noverlap=384)
    plt.figure(figsize=(6, 2.4))
    plt.pcolormesh(t, f, 10 * np.log10(s + 1e-12), shading="auto", vmin=-110, vmax=-20, cmap="magma")
    plt.ylim(0, 12000)
    plt.title(title, fontsize=8)
    plt.tight_layout()
    plt.savefig(path, dpi=80)
    plt.close()
