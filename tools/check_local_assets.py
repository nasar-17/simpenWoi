#!/usr/bin/env python3
"""Validate packaged Android assets without Flutter or third-party packages."""
from pathlib import Path
import struct
import wave
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'android/app/src/main/res'
for source in RES.rglob('*.xml'):
    ET.parse(source)
ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml')

sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
for density, size in sizes.items():
    source = RES / f'mipmap-{density}/ic_launcher.png'
    image = source.read_bytes()
    assert image[:8] == b'\x89PNG\r\n\x1a\n', source
    assert struct.unpack('>II', image[16:24]) == (size, size), source

with wave.open(str(RES / 'raw/simpenwoi_chime.wav'), 'rb') as sound:
    assert (sound.getnchannels(), sound.getsampwidth(), sound.getframerate()) == (1, 2, 24000)
    assert sound.getnframes() == 17280
    samples = struct.unpack('<17280h', sound.readframes(17280))
    assert 10000 < max(map(abs, samples)) < 32767
    assert samples[0] == 0 and all(sample == 0 for sample in samples[-20:])
print('PASS: Android XML, all five launcher densities, and notification PCM audio')
