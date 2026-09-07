#!/usr/bin/env python3
"""Generate short royalty-free kid SFX as WAV files.

Correct is a bright rising chime. Wrong is a low buzzy thud. They must be
easy to tell apart even on laptop speakers.
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SR = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "sounds"


def write(name: str, frames: list[int]) -> None:
    path = OUT / name
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(b"".join(struct.pack("<h", sample) for sample in frames))
    print(path)


def _env(i: int, n: int, attack: float, release: float) -> float:
    return min(1.0, i / (SR * attack)) * min(1.0, (n - i) / (SR * release))


def chime(notes: list[float], note_dur: float, volume: float, gap: float) -> list[int]:
    frames: list[int] = []
    for freq in notes:
        n = int(SR * note_dur)
        for i in range(n):
            t = i / SR
            env = _env(i, n, 0.01, 0.05)
            sample = math.sin(2 * math.pi * freq * t)
            sample += 0.22 * math.sin(4 * math.pi * freq * t)
            frames.append(int(max(-1, min(1, volume * env * sample)) * 32767))
        frames.extend([0] * int(SR * gap))
    return frames


def buzz(freq: float, dur: float, volume: float) -> list[int]:
    n = int(SR * dur)
    frames: list[int] = []
    for i in range(n):
        t = i / SR
        env = _env(i, n, 0.008, 0.09)
        pitch = freq * (1.0 - 0.18 * t / dur)
        sample = 0.55 * math.sin(2 * math.pi * pitch * t)
        sample += 0.28 * math.sin(2 * math.pi * pitch * 1.5 * t)
        sample += 0.18 * (1.0 if int(t * pitch * 2) % 2 == 0 else -1.0)
        frames.append(int(max(-1, min(1, volume * env * sample)) * 32767))
    return frames


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    write("correct.wav", chime([523.25, 659.25, 783.99, 1046.50], 0.13, 0.34, 0.03))
    write("wrong.wav", buzz(174.61, 0.48, 0.28))
    write("levelup.wav", chime([523.25, 783.99, 1046.50, 1318.51], 0.15, 0.30, 0.035))


if __name__ == "__main__":
    main()
