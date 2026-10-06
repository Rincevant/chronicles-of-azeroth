"""Convertit le manifeste d'illustrations de zones en textures TGA pour WoW.

Le script est volontairement déterministe : l'ordre des 47 entrées du CSV est
vérifié, chaque image est redressée selon son orientation EXIF puis recadrée au
format panoramique unique utilisé par les cartes et bannières de l'addon.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

from PIL import Image, ImageOps


EXPECTED_ZONE_KEYS = [
    "elwynn", "westfall", "redridge", "duskwood", "lochmodan", "dunmorogh",
    "wetlands", "badlands", "searinggorge", "burningsteppes", "swampofsorrows",
    "blastedlands", "deadwind", "arathi", "hillsbrad", "alterac", "hinterlands",
    "silverpine", "tirisfal", "stranglethorn", "westernplaguelands",
    "easternplaguelands", "blackrock-mountain", "durotar", "mulgore",
    "teldrassil", "darkshore", "barrens", "stonetalon", "ashenvale",
    "thousandneedles", "desolace", "feralas", "dustwallow", "tanaris", "azshara",
    "felwood", "ungoro", "winterspring", "moonglade", "silithus", "stormwind",
    "ironforge", "undercity", "darnassus", "orgrimmar", "thunderbluff",
]

SPECIAL_SOURCE_NAMES = {
    23: "23-blackrock-mountain.jpg",
    42: "42-stormwind.jpg",
    43: "43-ironforge.jpg",
}

TARGET_SIZE = (768, 256)


def source_name(index: int) -> str:
    return SPECIAL_SOURCE_NAMES.get(index, f"{index:02d}.jpg")


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: import_zone_art.py MANIFEST.csv SOURCE_DIRECTORY OUTPUT_DIRECTORY")
        return 2

    manifest_path = Path(sys.argv[1])
    source_directory = Path(sys.argv[2])
    output_directory = Path(sys.argv[3])
    with manifest_path.open("r", encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter=";"))

    if len(rows) != len(EXPECTED_ZONE_KEYS):
        raise ValueError(f"Manifest has {len(rows)} rows; expected {len(EXPECTED_ZONE_KEYS)}.")
    if any(not row.get("url_image") or not row.get("nom_fr") for row in rows):
        raise ValueError("Manifest contains an entry without a zone name or image URL.")

    output_directory.mkdir(parents=True, exist_ok=True)
    written = []
    for index, (row, key) in enumerate(zip(rows, EXPECTED_ZONE_KEYS), start=1):
        source_path = source_directory / source_name(index)
        if not source_path.is_file() or source_path.stat().st_size == 0:
            raise FileNotFoundError(f"Missing source for {row['nom_fr']}: {source_path}")

        with Image.open(source_path) as original:
            image = ImageOps.exif_transpose(original).convert("RGB")
            image = ImageOps.fit(image, TARGET_SIZE, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
            output_path = output_directory / f"zone-{key}.tga"
            image.save(output_path, format="TGA")
            written.append(output_path)
            print(f"{index:02d}/47 {row['nom_fr']} -> {output_path.name}")

    total = sum(path.stat().st_size for path in written)
    print(f"Converted {len(written)} textures ({total / 1024 / 1024:.1f} MiB).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
