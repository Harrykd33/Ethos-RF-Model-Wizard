"""Convert the supplied logo to an Ethos mask. Optional asset build: requires Pillow.

The generated mask is checked in; normal ZIP packaging needs only the standard library.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    with Image.open(ROOT / "assets/Model Wizard RF Helicopter Logo.png") as source:
        # Preserve the complete logo and aspect ratio, with black strokes on white.
        logo = source.convert("RGBA")
        background = Image.new("RGBA", logo.size, "white")
        background.alpha_composite(logo)
        mask = background.convert("L")
        mask.thumbnail((144, 112), Image.Resampling.LANCZOS)
        # Ethos positions tool icons below its label row. Bottom padding moves
        # the complete logo into the tile's free label space without clipping.
        tile = Image.new("L", (144, 160), 255)
        tile.paste(mask, ((144 - mask.width) // 2, 8))
        tile.save(ROOT / "rotorflight-model-wizard/legacy-icon.png")


if __name__ == "__main__":
    main()
