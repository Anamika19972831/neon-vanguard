#!/usr/bin/env python3
"""Procedurally synthesises every sound effect and the music loop.

Run from the project root:  python3 tools/generate_audio.py
Replace any generated .wav in assets/audio with your own recordings anytime
(keep the same file names).
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
random.seed(42)


def save(name, samples, gain=0.9):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = gain / max(peak, 1.0) if peak > 1 else gain
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in samples))


def sine(p): return math.sin(2 * math.pi * p)
def square(p): return 1.0 if (p % 1) < 0.5 else -1.0
def saw(p): return 2 * (p % 1) - 1


def tone(dur, f0, f1=None, wf=sine, decay=4.0, vol=1.0):
    f1 = f1 or f0
    n = int(SR * dur)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        f = f0 * (f1 / f0) ** t
        phase += f / SR
        env = math.exp(-decay * t) * min(1, i / (SR * 0.004))
        out.append(wf(phase) * env * vol)
    return out


def noise(dur, k0=0.5, k1=0.02, decay=3.0, vol=1.0):
    n = int(SR * dur)
    out, y = [], 0.0
    for i in range(n):
        t = i / n
        k = k0 + (k1 - k0) * t
        y += k * ((random.random() * 2 - 1) - y)
        out.append(y * math.exp(-decay * t) * vol)
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


# ---- sound effects ----
save("shoot.wav", tone(0.09, 1200, 450, square, decay=6, vol=0.5))
save("explosion.wav", mix(noise(0.65, 0.55, 0.02, 3.2, 1.0),
                          tone(0.5, 90, 35, sine, decay=4, vol=0.9)))
save("hit.wav", mix(tone(0.25, 200, 80, saw, decay=7, vol=0.6),
                    noise(0.2, 0.4, 0.05, 6, 0.5)))

arp = []
for f in (523.25, 659.25, 783.99, 1046.5):
    arp += mix(tone(0.09, f, f, sine, 5, 0.7), tone(0.09, f, f, square, 5, 0.2))
save("powerup.wav", arp)

siren = []
for i in range(8):
    siren += tone(0.2, 440 if i % 2 == 0 else 330, None, saw, decay=1.5, vol=0.5)
save("boss.wav", mix(siren, tone(1.6, 55, 55, sine, decay=0.8, vol=0.7)))

# ---- music: 8 s loop, 120 BPM, Am - F - C - G ----
BPM = 120
beat = 60 / BPM
total = int(SR * beat * 16)
bgm = [0.0] * total


def add(start_s, samples):
    s0 = int(start_s * SR)
    for i, v in enumerate(samples):
        if s0 + i < total:
            bgm[s0 + i] += v


def note(freq, dur, wf, vol, decay):
    return tone(dur, freq, freq, wf, decay, vol)


hz = lambda m: 440 * 2 ** ((m - 69) / 12)
chords = [  # (bass midi, chord midi tones)
    (45, (57, 60, 64)),  # Am
    (41, (53, 57, 60)),  # F
    (48, (55, 60, 64)),  # C
    (43, (55, 59, 62)),  # G
]
for c, (bass, tones) in enumerate(chords):
    t0 = c * 4 * beat
    for e in range(8):  # eighth-note bass
        m = bass + (12 if e % 4 == 3 else 0)
        add(t0 + e * beat / 2, note(hz(m), beat / 2 * 0.9, saw, 0.20, 5))
    for s in range(16):  # sixteenth-note arpeggio
        m = tones[[0, 1, 2, 1][s % 4]] + (12 if (s // 4) % 2 else 0)
        add(t0 + s * beat / 4, note(hz(m + 12), beat / 4 * 0.9, square, 0.07, 7))
    for b in range(4):  # kick + hat
        add(t0 + b * beat, tone(0.14, 130, 45, sine, 5, 0.9))
        add(t0 + b * beat + beat / 2, noise(0.04, 0.9, 0.5, 8, 0.25))

save("bgm.wav", bgm, gain=0.8)
print("audio generated ->", os.path.abspath(OUT))
