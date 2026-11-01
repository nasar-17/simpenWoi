#!/usr/bin/env python3
"""Install a supplied PNG/WebP/JPEG logo as Android legacy and adaptive icons.

Usage: python3 tool/install_launcher_logo.py logo.png --background '#F7F5EF'
Requires Pillow. Does not invent branding or remove the source logo's background.
SVG input should first be exported to a transparent PNG of at least 432 px.
"""
import argparse
from pathlib import Path
from PIL import Image, ImageColor, ImageOps

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'android/app/src/main/res'
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
ADAPTIVE = '''<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
'''


def centered(image, canvas_size, logo_size, background):
    fitted = ImageOps.contain(image, (logo_size, logo_size), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (canvas_size, canvas_size), background)
    canvas.alpha_composite(fitted, ((canvas_size - fitted.width) // 2,
                                  (canvas_size - fitted.height) // 2))
    return canvas


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('logo', type=Path)
    parser.add_argument('--background', default='#F7F5EF')
    args = parser.parse_args()
    color = ImageColor.getrgb(args.background)
    if len(color) != 3:
        parser.error('The adaptive icon background must be an opaque RGB color.')
    with Image.open(args.logo) as opened:
        image = ImageOps.exif_transpose(opened).convert('RGBA')
    if min(image.size) < 432:
        parser.error('Use a source at least 432 px on its shortest side for xxxhdpi.')
    for density, scale in DENSITIES.items():
        folder = RES / f'mipmap-{density}'
        folder.mkdir(parents=True, exist_ok=True)
        centered(image, round(48 * scale), round(40 * scale), (*color, 255)).save(
            folder / 'ic_launcher.png'
        )
        # Keep all essential artwork inside Android's 66/108 dp safe zone.
        centered(image, round(108 * scale), round(66 * scale), (0, 0, 0, 0)).save(
            folder / 'ic_launcher_foreground.png'
        )
    adaptive = RES / 'mipmap-anydpi-v26'
    adaptive.mkdir(parents=True, exist_ok=True)
    (adaptive / 'ic_launcher.xml').write_text(ADAPTIVE)
    values = RES / 'values'
    values.mkdir(parents=True, exist_ok=True)
    hex_color = '#{:02X}{:02X}{:02X}'.format(*color)
    (values / 'launcher_colors.xml').write_text(
        '<resources>\n    <color name="launcher_background">'
        + hex_color + '</color>\n</resources>\n'
    )
    print('Installed supplied logo in five densities and an Android 8+ adaptive icon.')


if __name__ == '__main__':
    main()
