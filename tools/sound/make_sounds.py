#!/usr/bin/env python3
"""Regenerate src/sound/sot_swear.wav and sot_break.wav (original, CC0).

Pure synthesis with numpy: no samples, no third-party audio.
16-bit PCM, mono, 44.1 kHz. Deterministic (fixed noise seed).
"""
import pathlib
import wave

import numpy as np

SR = 44100
OUT = pathlib.Path(__file__).resolve().parents[2] / "src" / "sound"


def env(n, d):
    t = np.arange(n) / SR
    e = np.exp(-t / d * 3)
    k = int(0.005 * SR)
    e[:k] *= np.linspace(0, 1, k)
    return e


def tone(f, n, d, parts=((1, 1), (2.01, 0.4), (3.03, 0.2), (4.2, 0.1))):
    t = np.arange(n) / SR
    return sum(a * np.sin(2 * np.pi * f * m * t) for m, a in parts) * env(n, d)


def write(name, x):
    x = x / np.max(np.abs(x)) * 0.7
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    # Swear: a low struck note, then the fifth above it. Settled.
    n = int(1.6 * SR)
    s = int(0.35 * SR)
    x = tone(110, n, 1.4)
    x[s:] += 0.8 * tone(164.8, n - s, 1.2)
    write("sot_swear.wav", x)
    # Break: a crack of noise over a falling, out-of-tune pair. Unsettled.
    n = int(1.4 * SR)
    t = np.arange(n) / SR
    crack = np.random.default_rng(7).normal(0, 1, n) * np.exp(-t * 25) * 0.6
    ph = 2 * np.pi * np.cumsum(155.6 * np.exp(-t * 0.4)) / SR
    write("sot_break.wav", (np.sin(ph) + 0.5 * np.sin(ph * 1.414)) * env(n, 0.9) + crack)


if __name__ == "__main__":
    main()
