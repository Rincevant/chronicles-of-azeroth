"""Converts the zone artwork manifests into TGA textures for WoW.

The script is deliberately deterministic. The original manifest of 47 zones is
checked entry by entry, and each image is straightened according to its EXIF
orientation, then cropped at its centre to the single panoramic format used by
the cards and banners of the addon.

With --crops, the images are read from tools/zone_art.csv instead: each row
names the page the image comes from, the image file and the band of it that
shows the subject, chosen by hand, so that the textures can be rebuilt as they
were made.
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
CROP_FIELDS = ("key", "area", "source", "file", "left", "top", "right", "bottom")


def source_name(index: int) -> str:
    return SPECIAL_SOURCE_NAMES.get(index, f"{index:02d}.jpg")


def import_crops(manifest_path: Path, source_directory: Path, output_directory: Path) -> int:
    """Textures of the hand-cropped manifest: each band keeps the ratio of the target."""
    with manifest_path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter=";"))
    if not rows or tuple(rows[0].keys()) != CROP_FIELDS:
        raise ValueError(f"{manifest_path} must have the columns {';'.join(CROP_FIELDS)}.")
    output_directory.mkdir(parents=True, exist_ok=True)
    for row in rows:
        box = tuple(int(row[field]) for field in ("left", "top", "right", "bottom"))
        width, height = box[2] - box[0], box[3] - box[1]
        if abs(width / height - TARGET_SIZE[0] / TARGET_SIZE[1]) > 0.01:
            raise ValueError(f"{row['key']}: the band {box} is not {TARGET_SIZE[0]}:{TARGET_SIZE[1]}.")
        if width < TARGET_SIZE[0]:
            raise ValueError(f"{row['key']}: the band is {width} pixels wide, less than {TARGET_SIZE[0]}.")
        source_path = source_directory / row["file"]
        with Image.open(source_path) as original:
            image = ImageOps.exif_transpose(original).convert("RGB")
            if box[2] > image.width or box[3] > image.height:
                raise ValueError(f"{row['key']}: the band {box} exceeds the image {image.size}.")
            image = image.crop(box).resize(TARGET_SIZE, Image.Resampling.LANCZOS)
            output_path = output_directory / f"zone-{row['key']}.tga"
            image.save(output_path, format="TGA")
            print(f"{row['key']} (area {row['area']}) -> {output_path.name}")
    print(f"Converted {len(rows)} textures.")
    return 0


def main() -> int:
    if len(sys.argv) == 5 and sys.argv[1] == "--crops":
        return import_crops(Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4]))
    if len(sys.argv) != 4:
        print("Usage: import_zone_art.py MANIFEST.csv SOURCE_DIRECTORY OUTPUT_DIRECTORY")
        print("       import_zone_art.py --crops tools/zone_art.csv SOURCE_DIRECTORY OUTPUT_DIRECTORY")
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
