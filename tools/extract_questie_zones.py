"""Read the baked QuestieDB metadata and list quests for selected parent zones.

This intentionally uses only the data shipped with the user's QuestieDB addon.
It decodes the compact CBOR scalar rows needed for the catalogue audit.
"""
from __future__ import annotations

import base64
import re
import sys
from collections import defaultdict
from pathlib import Path


ROOT = Path(r"C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\QuestieDB")
TOC = ROOT / "QuestieDB_Forever.toc"
SUBZONES = ROOT / "support" / "Forever" / "Zones" / "subZoneToParentZone.lua"
XP = ROOT / "support" / "Forever" / "QuestXP" / "xpDB-classic.lua"
TARGETS = {1: "Dun Morogh", 38: "Loch Modan", 40: "Westfall"}
LEVEL_LIMITS = {1: 12, 38: 22, 40: 20, 141: 12, 148: 22}
EXCLUDED = {1: {5841, 7673, 7674, 7675, 7676}, 141: {5842}, 148: {960, 961}}


def decode_cbor(data: bytes):
    """Minimal CBOR reader for Questie scalar metadata rows."""
    offset = 0

    def take(count: int) -> bytes:
        nonlocal offset
        result = data[offset : offset + count]
        offset += count
        return result

    def read_length(additional: int) -> int:
        if additional < 24:
            return additional
        width = {24: 1, 25: 2, 26: 4, 27: 8}[additional]
        return int.from_bytes(take(width), "big")

    def read():
        initial = take(1)[0]
        major, additional = initial >> 5, initial & 31
        if major == 0:
            return read_length(additional)
        if major == 1:
            return -1 - read_length(additional)
        if major == 2:
            return take(read_length(additional))
        if major == 3:
            return take(read_length(additional)).decode("utf-8")
        if major == 4:
            return [read() for _ in range(read_length(additional))]
        if major == 5:
            return {read(): read() for _ in range(read_length(additional))}
        if major == 6:
            read_length(additional)
            return read()
        if major == 7:
            return {20: False, 21: True, 22: None}.get(additional)
        raise ValueError(f"unsupported CBOR type {major}:{additional}")

    value = read()
    if offset != len(data):
        raise ValueError("trailing CBOR bytes")
    return value


def main() -> None:
    zone_ids = defaultdict(set)
    for area, parent in re.findall(r"\[(\d+)\]\s*=\s*(\d+),\s*--", SUBZONES.read_text(encoding="utf-8")):
        parent = int(parent)
        if parent in TARGETS:
            zone_ids[parent].add(int(area))
    for parent in TARGETS:
        zone_ids[parent].add(parent)

    xp = {int(qid): int(amount) for qid, _level, amount in re.findall(
        r"\[(\d+)\]\s*=\s*\{(-?\d+),\s*(-?\d+)\}", XP.read_text(encoding="utf-8")
    )}
    quests = defaultdict(list)
    line_re = re.compile(r"^## X-Quest-(\d+)-S: ([A-Za-z0-9+/=]+)$")
    for line in TOC.read_text(encoding="utf-8").splitlines():
        match = line_re.match(line)
        if not match:
            continue
        quest_id, encoded = int(match.group(1)), match.group(2)
        row = decode_cbor(base64.b64decode(encoded))
        area = row.get(17)
        for parent, areas in zone_ids.items():
            if area in areas:
                quests[parent].append((quest_id, row.get(5), row.get(4), xp.get(quest_id), row.get(1), area))

    if "--lua" in sys.argv:
        for parent, label in TARGETS.items():
            entries = sorted(quests[parent], key=lambda entry: (entry[1] or 999, entry[0]))
            limit = LEVEL_LIMITS.get(parent)
            if limit is not None:
                entries = [entry for entry in entries if entry[0] not in EXCLUDED.get(parent, set()) and (entry[1] or 99) <= limit]
            print(label + " ids = { " + ", ".join("{ id = %d }" % entry[0] for entry in entries) + " },")
            for quest_id, level, required, amount, _name, _area in entries:
                xp_value = (", %d" % amount) if amount is not None else ""
                print("[%d]={%s,%s%s}," % (quest_id, level or "nil", required or "nil", xp_value), end=" ")
            print("\n")
        return

    for parent, label in TARGETS.items():
        entries = sorted(quests[parent], key=lambda entry: (entry[1] or 999, entry[0]))
        print(f"## {label} ({len(entries)} quests; areas {sorted(zone_ids[parent])})")
        for quest_id, level, required, amount, name, area in entries:
            print(f"{quest_id:5}  q{str(level):>3} r{str(required):>3} xp {str(amount):>5}  a{area:<5} {name or ''}")


if __name__ == "__main__":
    main()
