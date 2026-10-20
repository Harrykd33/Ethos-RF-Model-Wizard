"""Build native Ethos helicopter masks from the supplied icon. Requires Pillow.

Generated masks are checked in; ZIP packaging uses only the standard library.
"""
from pathlib import Path
from PIL import Image, ImageOps, ImageFilter

ROOT = Path(__file__).resolve().parents[1]


def main():
    with Image.open(ROOT / "assets/Model Wizard Helicopter Icon.png") as source:
        width, height = source.size
        # Extract the helicopter, excluding the supplied title and tile frame.
        region = source.convert("L").crop((int(width * 0.14), int(height * 0.36),
                                          int(width * 0.86), int(height * 0.80)))
        bounds = region.point(lambda value: 255 if value > 180 else 0).getbbox()
        if not bounds:
            raise ValueError("Helicopter artwork missing")
        glyph = region.crop(bounds).point(lambda value: 255 - max(0, min(255, (value - 64) * 255 // 191)))
        glyph = ImageOps.expand(glyph, border=24, fill=255)
        glyph.thumbnail((124, 64), Image.Resampling.LANCZOS)
        # Match the stronger strokes of native System glyphs at radio resolution.
        glyph = glyph.filter(ImageFilter.MinFilter(3))
        mask = Image.new("L", (128, 80), 255)
        mask.paste(glyph, ((128 - glyph.width) // 2, (80 - glyph.height) // 2))
        for name in ("icon.png", "legacy-icon.png"):
            mask.save(ROOT / "rotorflight-model-wizard" / name)


if __name__ == "__main__":
    main()
