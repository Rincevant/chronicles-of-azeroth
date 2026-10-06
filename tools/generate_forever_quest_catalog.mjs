/* Build Chroniques' self-contained Classic zone quest catalogue.
 *
 * QuestieDB is only a build-time source. The generated Lua file ships inside
 * Chroniques and no client code loads Questie or QuestieDB at runtime.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = path.join(root, "QuestieDB-source");
const output = path.join(root, "ChroniquesAzeroth", "QuestCatalog.lua");

const zoneAreas = {
  elwynn: 12, dunmorogh: 1, westfall: 40, lochmodan: 38, teldrassil: 141, darkshore: 148,
  badlands: 3, blastedlands: 4, swampofsorrows: 8, duskwood: 10, wetlands: 11,
  westernplaguelands: 28, stranglethorn: 33, alterac: 36, deadwind: 41, redridge: 44,
  arathi: 45, burningsteppes: 46, hinterlands: 47, searinggorge: 51, tirisfal: 85,
  silverpine: 130, easternplaguelands: 139, hillsbrad: 267, stormwind: 1519,
  ironforge: 1537, undercity: 1497, durotar: 14, dustwallow: 15, azshara: 16,
  barrens: 17, mulgore: 215, ashenvale: 331, feralas: 357, felwood: 361,
  thousandneedles: 400, desolace: 405, stonetalon: 406, tanaris: 440, ungoro: 490,
  moonglade: 493, winterspring: 618, silithus: 1377, orgrimmar: 1637,
  thunderbluff: 1638, darnassus: 1657,
};

// Entries intentionally absent from a zone's completion total.  The generic
// filters below handle repeatables and technical placeholders; these IDs are
// malformed or context-only records in the Forever source and were already
// excluded from Chroniques' manually audited starter catalogues.
const ignoredQuestIds = new Set([5805, 5841, 5842, 960, 961]);
const optionalQuestIds = new Set([5261]);

function read(file) {
  return fs.readFileSync(file, "utf8");
}

function tablePayload(sourceText, marker) {
  const start = sourceText.indexOf(marker);
  if (start < 0) throw new Error(`Missing marker: ${marker}`);
  const body = start + marker.length;
  const end = sourceText.indexOf("]]", body);
  if (end < 0) throw new Error(`Unclosed payload: ${marker}`);
  return sourceText.slice(body, end);
}

function balancedBrace(sourceText, start) {
  let depth = 0;
  let quote = null;
  for (let index = start; index < sourceText.length; index += 1) {
    const char = sourceText[index];
    if (quote) {
      if (char === "\\") {
        index += 1;
      } else if (char === quote) {
        quote = null;
      }
    } else if (char === "'" || char === '"') {
      quote = char;
    } else if (char === "{") {
      depth += 1;
    } else if (char === "}") {
      depth -= 1;
      if (depth === 0) return index + 1;
    }
  }
  throw new Error("Unclosed Lua table");
}

function* topLevelEntries(payload) {
  const keyRe = /\[(\d+)\]\s*=\s*\{/g;
  for (let match = keyRe.exec(payload); match; match = keyRe.exec(payload)) {
    const valueStart = match.index + match[0].length - 1;
    const valueEnd = balancedBrace(payload, valueStart);
    yield [Number(match[1]), payload.slice(valueStart, valueEnd)];
    keyRe.lastIndex = valueEnd;
  }
}

function splitFields(value) {
  if (!value.startsWith("{") || !value.endsWith("}")) throw new Error("Expected Lua table");
  const fields = [];
  let begin = 1;
  let depth = 0;
  let quote = null;
  for (let index = 1; index < value.length - 1; index += 1) {
    const char = value[index];
    if (quote) {
      if (char === "\\") {
        index += 1;
      } else if (char === quote) {
        quote = null;
      }
    } else if (char === "'" || char === '"') {
      quote = char;
    } else if ("{[(".includes(char)) {
      depth += 1;
    } else if ("}])".includes(char)) {
      depth -= 1;
    } else if (char === "," && depth === 0) {
      fields.push(value.slice(begin, index).trim());
      begin = index + 1;
    }
  }
  const trailing = value.slice(begin, -1).trim();
  if (trailing) fields.push(trailing);
  return fields;
}

function luaString(field) {
  const text = field.trim();
  if (!text || (text[0] !== "'" && text[0] !== '"')) return null;
  const quote = text[0];
  let result = "";
  for (let index = 1; index < text.length; index += 1) {
    const char = text[index];
    if (char === quote) return result;
    if (char !== "\\") {
      result += char;
      continue;
    }
    index += 1;
    const escaped = text[index];
    const simple = { n: "\n", r: "\r", t: "\t", "\\": "\\", '"': '"', "'": "'" };
    if (Object.hasOwn(simple, escaped)) {
      result += simple[escaped];
    } else if (/\d/.test(escaped)) {
      const digits = text.slice(index, index + 3).match(/^\d{1,3}/)[0];
      result += String.fromCharCode(Number(digits));
      index += digits.length - 1;
    } else {
      result += escaped;
    }
  }
  throw new Error("Unclosed Lua string");
}

function integer(field) {
  const text = (field ?? "").trim();
  return /^-?\d+$/.test(text) ? Number(text) : null;
}

function questIds(field) {
  if (!field || field.trim() === "nil") return [];
  return [...field.matchAll(/\d+/g)].map((match) => Number(match[0]));
}

function luaQuote(value) {
  return `"${value.replaceAll("\\", "\\\\").replaceAll('"', '\\"').replaceAll("\n", "\\n").replaceAll("\r", "\\r")}"`;
}

function loadFrenchTranslations() {
  const text = read(path.join(source, "l10n", "Forever", "lookupQuests", "frFR.lua"));
  const payload = tablePayload(text, "loadstring([[return {");
  const translations = new Map();
  for (const [questId, value] of topLevelEntries(payload)) {
    const title = luaString(splitFields(value)[0]);
    if (title) translations.set(questId, title);
  }
  return translations;
}

function loadParents() {
  const text = read(path.join(source, "support", "Forever", "Zones", "subZoneToParentZone.lua"));
  const parents = new Map();
  for (const match of text.matchAll(/\[(\d+)\]\s*=\s*(\d+),/g)) parents.set(Number(match[1]), Number(match[2]));
  return parents;
}

function loadXp() {
  const text = read(path.join(source, "support", "Forever", "QuestXP", "xpDB-classic.lua"));
  const xp = new Map();
  for (const match of text.matchAll(/\[(\d+)\]\s*=\s*\{(-?\d+),\s*(-?\d+)\}/g)) {
    xp.set(Number(match[1]), { level: Number(match[2]), amount: Number(match[3]) });
  }
  return xp;
}

function rootArea(area, parents) {
  const seen = new Set();
  while (parents.has(area) && !seen.has(area)) {
    seen.add(area);
    area = parents.get(area);
  }
  return area;
}

function factionSide(requiredRaces) {
  if (!requiredRaces) return null;
  const mask = requiredRaces >>> 0;
  const alliance = Boolean(mask & 77);
  const horde = Boolean(mask & 178);
  if (alliance && !horde) return "A";
  if (horde && !alliance) return "H";
  return null;
}

if (!fs.existsSync(path.join(source, "data", "Forever", "foreverQuestDB.lua"))) {
  throw new Error("QuestieDB-source is missing. Clone the official source before generating the catalogue.");
}

const frenchTranslations = loadFrenchTranslations();
const parents = loadParents();
const xp = loadXp();
const rootToZone = new Map(Object.entries(zoneAreas).map(([key, area]) => [area, key]));
const payload = tablePayload(read(path.join(source, "data", "Forever", "foreverQuestDB.lua")), "QuestieDB.questData = [[return {");
const zones = new Map(Object.keys(zoneAreas).map((key) => [key, []]));
const quests = new Map();

for (const [questId, raw] of topLevelEntries(payload)) {
  const fields = splitFields(raw);
  if (fields.length < 17) continue;
  const area = integer(fields[16]);
  if (area === null || area <= 0) continue;
  const zone = rootToZone.get(rootArea(area, parents));
  if (!zone) continue;
  const requiredLevel = integer(fields[3]);
  const questLevel = integer(fields[4]);
  const xpEntry = xp.get(questId);
  const englishTitle = luaString(fields[0]) ?? `Quest ${questId}`;
  const title = frenchTranslations.get(questId) ?? englishTitle;
  const specialFlags = integer(fields[23]) ?? 0;
  // `specialFlags & 1` is Questie's explicit repeatable marker. Repeatable
  // exchanges and turn-ins cannot belong to a finite 100 % zone total.
  if (ignoredQuestIds.has(questId) || specialFlags & 1 || englishTitle === "Welcome!" || englishTitle.startsWith("DND ")) continue;
  quests.set(questId, {
    title,
    englishTitle,
    questLevel: questLevel ?? requiredLevel ?? xpEntry?.level ?? 1,
    requiredLevel: requiredLevel ?? 1,
    xp: xpEntry?.amount ?? null,
    side: factionSide(integer(fields[5])),
    optional: optionalQuestIds.has(questId),
    previous: [...new Set([...questIds(fields[11]), ...questIds(fields[12])])].sort((a, b) => a - b),
    next: [...new Set([...questIds(fields[13]), ...questIds(fields[21])])].sort((a, b) => a - b),
  });
  zones.get(zone).push(questId);
}

// Normalize chains in both directions. Some Forever rows only record a
// `nextQuestInChain`, while the target has no explicit prerequisite. The UI
// groups by prerequisite, so add the inverse link only when both quests are
// assigned to the same visible Chroniques zone.
const questZones = new Map();
for (const [zone, ids] of zones) for (const questId of ids) questZones.set(questId, zone);
for (const [questId, quest] of quests) {
  for (const nextId of quest.next) {
    const next = quests.get(nextId);
    if (next && questZones.get(questId) === questZones.get(nextId) && !next.previous.includes(questId)) {
      next.previous.push(questId);
      next.previous.sort((a, b) => a - b);
    }
  }
  for (const previousId of quest.previous) {
    const previous = quests.get(previousId);
    if (previous && questZones.get(questId) === questZones.get(previousId) && !previous.next.includes(questId)) {
      previous.next.push(questId);
      previous.next.sort((a, b) => a - b);
    }
  }
}

let duplicateAssignments = 0;
const assignmentZones = new Map();
for (const key of Object.keys(zoneAreas)) {
  duplicateAssignments += zones.get(key).length - new Set(zones.get(key)).size;
  const unique = [...new Set(zones.get(key))];
  for (const questId of unique) {
    const assignedZones = assignmentZones.get(questId) ?? [];
    assignedZones.push(key);
    assignmentZones.set(questId, assignedZones);
  }
  unique.sort((a, b) => quests.get(a).questLevel - quests.get(b).questLevel || a - b);
  zones.set(key, unique);
}
const crossZoneDuplicateAssignments = [...assignmentZones.values()].filter((assignedZones) => assignedZones.length > 1).length;

const lines = [
  "-- AUTO-GENERATED by tools/generate_forever_quest_catalog.mjs. DO NOT EDIT.",
  "-- Build input: QuestieDB Forever source. This file is self-contained at runtime.",
  "ChroniquesAzerothQuestCatalog = {",
  "  schema = 2,",
  "  zones = {",
];
for (const key of Object.keys(zoneAreas)) lines.push(`    ${key} = { ${zones.get(key).join(", ")} },`);
lines.push("  },", "  quests = {");
for (const questId of [...quests.keys()].sort((a, b) => a - b)) {
  const quest = quests.get(questId);
  const fields = [`t=${luaQuote(quest.title)}`, `e=${luaQuote(quest.englishTitle)}`, `q=${quest.questLevel}`, `r=${quest.requiredLevel}`];
  if (quest.xp) fields.push(`x=${quest.xp}`);
  if (quest.side) fields.push(`s=${luaQuote(quest.side)}`);
  if (quest.optional) fields.push("o=true");
  if (quest.previous.length) fields.push(`p={${quest.previous.join(",")}}`);
  if (quest.next.length) fields.push(`n={${quest.next.join(",")}}`);
  lines.push(`    [${questId}] = {${fields.join(", ")}},`);
}
lines.push("  },", "}", "");
fs.writeFileSync(output, lines.join("\n"), "utf8");

let intraZoneLinks = 0;
let asymmetricIntraZoneLinks = 0;
for (const [questId, quest] of quests) {
  for (const nextId of quest.next) {
    const next = quests.get(nextId);
    if (next && questZones.get(questId) === questZones.get(nextId)) {
      intraZoneLinks += 1;
      if (!next.previous.includes(questId)) asymmetricIntraZoneLinks += 1;
    }
  }
}

// The UI renders one expandable block per connected in-zone quest chain.
// Audit those blocks here so a malformed source link can never make an ID
// appear in more than one visual group.
let componentCount = 0;
let chainedComponentCount = 0;
let largestComponent = 0;
let componentMembershipErrors = 0;
for (const [zone, ids] of zones) {
  const inZone = new Set(ids);
  const neighbors = new Map(ids.map((id) => [id, new Set()]));
  for (const questId of ids) {
    const quest = quests.get(questId);
    for (const linkedId of [...quest.previous, ...quest.next]) {
      if (inZone.has(linkedId)) {
        neighbors.get(questId).add(linkedId);
        neighbors.get(linkedId).add(questId);
      }
    }
  }
  const visited = new Set();
  for (const startId of ids) {
    if (visited.has(startId)) continue;
    componentCount += 1;
    const stack = [startId];
    let size = 0;
    visited.add(startId);
    while (stack.length) {
      const currentId = stack.pop();
      size += 1;
      for (const linkedId of neighbors.get(currentId)) {
        if (!visited.has(linkedId)) {
          visited.add(linkedId);
          stack.push(linkedId);
        }
      }
    }
    if (size > 1) chainedComponentCount += 1;
    largestComponent = Math.max(largestComponent, size);
  }
  componentMembershipErrors += ids.length - visited.size;
}
console.log(`Wrote ${path.relative(root, output)}: ${quests.size} quests across ${zones.size} zones`);
console.log(`Audit: ${duplicateAssignments} duplicate IDs inside a zone; ${crossZoneDuplicateAssignments} IDs assigned to multiple zones; ${intraZoneLinks} intra-zone links; ${asymmetricIntraZoneLinks} asymmetric links`);
console.log(`Chain audit: ${componentCount} blocks; ${chainedComponentCount} multi-quest blocks; largest=${largestComponent}; ${componentMembershipErrors} missing memberships`);
for (const key of Object.keys(zoneAreas)) console.log(`${key}: ${zones.get(key).length}`);
