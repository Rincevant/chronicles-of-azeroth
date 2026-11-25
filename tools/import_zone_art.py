"""Converts the zone artwork manifests into TGA textures for WoW.

The script is deliberately deterministic. The original manifest of 47 zones is
checked entry by entry, and each image is straightened according to its EXIF
orientation, then cropped at its centre to the single panoramic format used by
the cards and banners of the addon.

With --crops, the images are read from tools/zone_art.csv instead: each row
names the zone, quest category or profession it illustrates, the page the image
comes from, the image file and the band of it that shows the subject, chosen by
hand, so that the textures can be rebuilt as they were made. A row may join two
images on a slanted seam, such as the banners of the two factions.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


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
CROP_FIELDS = ("key", "kind", "id", "source", "file", "left", "top", "right", "bottom")
# Prefix of the texture of each kind of group the manifest illustrates.
KIND_PREFIXES = {"zone": "zone", "category": "category", "profession": "profession"}
# A row with two sources (fields holding two values separated by "|") is a montage: each
# band fills HALF_WIDTH pixels of a side, and the right one covers the left one beyond a
# slanted seam running from SEAM_TOP at the top to SEAM_BOTTOM at the bottom.
HALF_WIDTH = 450
SEAM_TOP, SEAM_BOTTOM = 430, 338
SEAM_SOFTNESS = 3


def source_name(index: int) -> str:
    return SPECIAL_SOURCE_NAMES.get(index, f"{index:02d}.jpg")


def crop_band(source_path: Path, box: tuple[int, int, int, int], size: tuple[int, int], key: str) -> Image.Image:
    """The band `box` of an image, checked to have the ratio of `size` and enough pixels,
    resized to `size`. A band may be up to 1/16 narrower than the size: the enlargement then
    stays invisible."""
    width, height = box[2] - box[0], box[3] - box[1]
    if abs(width / height - size[0] / size[1]) > 0.01:
        raise ValueError(f"{key}: the band {box} is not {size[0]}:{size[1]}.")
    if width < size[0] * 15 / 16:
        raise ValueError(f"{key}: the band is {width} pixels wide, too few for {size[0]}.")
    with Image.open(source_path) as original:
        image = ImageOps.exif_transpose(original).convert("RGB")
        if box[2] > image.width or box[3] > image.height:
            raise ValueError(f"{key}: the band {box} exceeds the image {image.size}.")
        return image.crop(box).resize(size, Image.Resampling.LANCZOS)


def import_crops(manifest_path: Path, source_directory: Path, output_directory: Path) -> int:
    """Textures of the hand-cropped manifest."""
    with manifest_path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter=";"))
    if not rows or tuple(rows[0].keys()) != CROP_FIELDS:
        raise ValueError(f"{manifest_path} must have the columns {';'.join(CROP_FIELDS)}.")
    output_directory.mkdir(parents=True, exist_ok=True)
    for row in rows:
        if row["kind"] not in KIND_PREFIXES:
            raise ValueError(f"{row['key']}: unknown kind {row['kind']!r}.")
        files = row["file"].split("|")
        boxes = list(zip(*(map(int, row[field].split("|")) for field in ("left", "top", "right", "bottom"))))
        if len(files) != len(boxes) or len(files) not in (1, 2):
            raise ValueError(f"{row['key']}: one or two sources, each with its band.")
        if len(files) == 1:
            image = crop_band(source_directory / files[0], boxes[0], TARGET_SIZE, row["key"])
        else:
            half = (HALF_WIDTH, TARGET_SIZE[1])
            left, right = (crop_band(source_directory / f, b, half, row["key"]) for f, b in zip(files, boxes))
            image = Image.new("RGB", TARGET_SIZE)
            image.paste(left, (0, 0))
            layer = Image.new("RGB", TARGET_SIZE)
            layer.paste(right, (TARGET_SIZE[0] - HALF_WIDTH, 0))
            mask = Image.new("L", TARGET_SIZE, 0)
            ImageDraw.Draw(mask).polygon([(SEAM_TOP, 0), (TARGET_SIZE[0], 0), TARGET_SIZE, (SEAM_BOTTOM, TARGET_SIZE[1])], fill=255)
            image.paste(layer, (0, 0), mask.filter(ImageFilter.GaussianBlur(SEAM_SOFTNESS)))
        output_path = output_directory / f"{KIND_PREFIXES[row['kind']]}-{row['key']}.tga"
        image.save(output_path, format="TGA")
        print(f"{row['key']} ({row['kind']} {row['id']}) -> {output_path.name}")
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
