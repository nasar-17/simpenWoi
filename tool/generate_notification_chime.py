#!/usr/bin/env python3
"""Generate simpenWoi's original three-note 'sim-pen-woi' chime, using only stdlib.

CC0: the synthesized composition and output may be used and modified freely.
No sampled music or third-party audio is included. Run from any directory.
"""
from pathlib import Path
import math
import struct
import wave

SAMPLE_RATE = 24000
DURATION = 0.72
# Starts, frequencies (C5, G5, C6), and amplitudes of three soft bell notes.
NOTES = ((0.0, 523.251, 0.50), (0.15, 783.991, 0.43), (0.30, 1046.502, 0.38))
OUTPUT = Path(__file__).resolve().parents[1] / (
    'android/app/src/main/res/raw/simpenwoi_chime.wav'
)


def samples():
    for frame in range(round(SAMPLE_RATE * DURATION)):
        time = frame / SAMPLE_RATE
        value = 0.0
        for start, frequency, amplitude in NOTES:
            elapsed = time - start
            if 0.0 <= elapsed < 0.42:
                attack = min(1.0, elapsed / 0.008)
                release = min(1.0, (0.42 - elapsed) / 0.04)
                envelope = attack * release * math.exp(-9.0 * elapsed)
                fundamental = math.sin(math.tau * frequency * elapsed)
                harmonic = 0.13 * math.sin(math.tau * frequency * 2 * elapsed)
                value += amplitude * envelope * (fundamental + harmonic)
        # End fades fully to zero rather than cutting a waveform mid-period.
        value *= min(1.0, max(0.0, (DURATION - time) / 0.04))
        yield round(value * 32767)


def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    values = list(samples())
    assert max(abs(value) for value in values) < 32767, 'Audio would clip'
    with wave.open(str(OUTPUT), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(struct.pack('<' + 'h' * len(values), *values))
    print(f'{OUTPUT}: {DURATION}s, mono PCM16 at {SAMPLE_RATE} Hz')


if __name__ == '__main__':
    main()
