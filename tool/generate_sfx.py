#!/usr/bin/env python3
"""Generate short royalty-free kid SFX as WAV files."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SR = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "sounds"


def synth(notes: list[float], note_dur: float = 0.13, volume: float = 0.32, gap: float = 0.035) -> list[int]:
    frames: list[int] = []
    for freq in notes:
        n = int(SR * note_dur)
        for i in range(n):
            t = i / SR
            env = min(1.0, i / (SR * 0.012)) * min(1.0, (n - i) / (SR * 0.04))
            sample = math.sin(2 * math.pi * freq * t)
            sample += 0.18 * math.sin(4 * math.pi * freq * t)
            frames.append(int(max(-1, min(1, volume * env * sample)) * 32767))
        frames.extend([0] * int(SR * gap))
    return frames


def write(name: str, frames: list[int]) -> None:
    path = OUT / name
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(b"".join(struct.pack("<h", sample) for sample in frames))
    print(path)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    write("correct.wav", synth([523.25, 659.25, 783.99, 1046.50], 0.11, 0.30, 0.025))
    write("wrong.wav", synth([329.63, 277.18, 246.94], 0.16, 0.22, 0.02))
    write("levelup.wav", synth([523.25, 783.99, 1046.50, 1318.51], 0.14, 0.28, 0.03))


if __name__ == "__main__":
    main()
