/*
 * Build-time importer for the embedded Chroniques profession catalogue.
 *
 * Wowhead Forever exposes the exact spell list, skill requirement and source
 * category for every crafting skill. This script downloads those public pages
 * once while building; the generated Lua file is the only data used in game.
 * Chroniques never reads Wowhead, ATT, Questie or another addon at runtime.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const output = path.join(root, "ChroniquesAzeroth", "ProfessionCatalog.lua");
const reportOnly = process.argv.includes("--report");
const debug = process.argv.includes("--debug");

// Gathering skills have ranks, not recipe catalogues. The eight skills below
// are the professions for which the native UI presents learnable recipes.
const professions = [
  { id: 171, route: "professions", slug: "alchemy", names: ["Alchimie", "Alchemy"] },
  { id: 164, route: "professions", slug: "blacksmithing", names: ["Forge", "Blacksmithing"] },
  { id: 333, route: "professions", slug: "enchanting", names: ["Enchantement", "Enchanting"] },
  { id: 202, route: "professions", slug: "engineering", names: ["Ingénierie", "Engineering"] },
  { id: 165, route: "professions", slug: "leatherworking", names: ["Travail du cuir", "Leatherworking"] },
  { id: 197, route: "professions", slug: "tailoring", names: ["Couture", "Tailoring"] },
  { id: 185, route: "secondary-skills", slug: "cooking", names: ["Cuisine", "Cooking"] },
  { id: 129, route: "secondary-skills", slug: "first-aid", names: ["Secourisme", "Premiers soins", "First Aid"] },
];

function normalizeName(value) {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLocaleLowerCase("fr-FR")
    .trim();
}

function sourceCode(source) {
  const allowed = new Set([1, 2, 4, 5, 6]);
  const values = Array.isArray(source) ? source : [source];
  return [...new Set(values.map(Number).filter((value) => allowed.has(value)))].sort((a, b) => a - b).join("");
}

function packedReagents(reagents) {
  if (!Array.isArray(reagents)) return "";
  return reagents
    .map((reagent) => {
      const itemID = Array.isArray(reagent) ? Number(reagent[0]) : Number(reagent?.itemID);
      const count = Array.isArray(reagent) ? Number(reagent[1]) : Number(reagent?.count);
      return Number.isInteger(itemID) && itemID > 0 ? `${itemID}x${Math.max(1, Number.isFinite(count) ? count : 1)}` : null;
    })
    .filter(Boolean)
    .join("|");
}

function quoteBareObjectKeys(serialized) {
  let output = "";
  let quoted = false;
  let escaped = false;
  for (let index = 0; index < serialized.length; index += 1) {
    const character = serialized[index];
    if (quoted) {
      output += character;
      if (escaped) escaped = false;
      else if (character === "\\") escaped = true;
      else if (character === '"') quoted = false;
      continue;
    }
    if (character === '"') {
      quoted = true;
      output += character;
      continue;
    }
    if (character === "{" || character === ",") {
      const key = serialized.slice(index + 1).match(/^(\s*)([A-Za-z_$][A-Za-z0-9_$]*)(\s*:)/);
      if (key) {
        output += `${character}${key[1]}"${key[2]}"${key[3]}`;
        index += key[0].length;
        continue;
      }
    }
    output += character;
  }
  return output;
}

// Extracts the `listviewspells` data assignment without evaluating remote
// JavaScript. Wowhead adds a few unquoted presentation keys (`quality`,
// `popularity`), which are converted to JSON keys by the scanner above.
function extractSpellsList(html, professionID) {
  const marker = "listviewspells =";
  const markerIndex = html.indexOf(marker);
  if (markerIndex < 0) throw new Error(`No spell data found for profession ${professionID}`);
  const arrayStart = html.indexOf("[", markerIndex);

  let depth = 0;
  let quoted = false;
  let escaped = false;
  for (let index = arrayStart; index < html.length; index += 1) {
    const character = html[index];
    if (quoted) {
      if (escaped) escaped = false;
      else if (character === "\\") escaped = true;
      else if (character === '"') quoted = false;
      continue;
    }
    if (character === '"') {
      quoted = true;
    } else if (character === "[") {
      depth += 1;
    } else if (character === "]") {
      depth -= 1;
      if (depth === 0) return JSON.parse(quoteBareObjectKeys(html.slice(arrayStart, index + 1)));
    }
  }
  throw new Error(`Unterminated spell data for profession ${professionID}`);
}

async function readProfession(profession) {
  const url = `https://www.wowhead.com/forever/fr/spells/${profession.route}/${profession.slug}`;
  const response = await fetch(url, {
    headers: {
      "User-Agent": "ChroniquesAzeroth catalogue builder (local development)",
      "Accept-Language": "fr-FR,fr;q=0.9",
    },
  });
  if (!response.ok) throw new Error(`Wowhead returned ${response.status} for ${url}`);
  const entries = extractSpellsList(await response.text(), profession.id);
  if (debug) console.log(`Raw ${profession.id}: count=${entries.length}; first=${JSON.stringify(entries.slice(0, 3))}; last=${JSON.stringify(entries.slice(-3))}`);
  const professionNames = new Set(profession.names.map(normalizeName));
  const recipes = new Map();
  for (const entry of entries) {
    const id = Number(entry.id);
    const name = typeof entry.name === "string" ? entry.name : "";
    if (!Number.isInteger(id) || id <= 0 || !name || professionNames.has(normalizeName(name))) continue;
    const skills = Array.isArray(entry.skill) ? entry.skill.map(Number) : [];
    if (skills.length > 0 && !skills.includes(profession.id)) continue;
    recipes.set(id, {
      id,
      skill: Math.max(0, Number(entry.learnedat) || 0),
      source: sourceCode(entry.source),
      reagents: packedReagents(entry.reagents),
    });
  }
  return [...recipes.values()].sort((left, right) => left.skill - right.skill || left.id - right.id);
}

const catalogs = new Map();
for (const profession of professions) {
  const recipes = await readProfession(profession);
  if (recipes.length === 0) throw new Error(`No recipes retained for profession ${profession.id}`);
  catalogs.set(profession.id, recipes);
  console.log(`${profession.id}: ${recipes.length} recipes`);
}

const total = [...catalogs.values()].reduce((sum, recipes) => sum + recipes.length, 0);
if (reportOnly) {
  console.log(`Report only: ${total} recipes across ${catalogs.size} professions`);
  process.exit(0);
}

const lines = [
  "-- AUTO-GENERATED by tools/generate_forever_profession_catalog.mjs. DO NOT EDIT.",
  "-- Build input: Wowhead Forever skill pages. This file is self-contained at runtime.",
  "-- Format: spell ID : required skill : source categories : itemIDxcount|... (2=butin, 4=vendeur, 5=quête/spécial, 6=maître).",
  "_G.ChroniquesAzerothProfessionCatalog = {",
];
for (const profession of professions) {
  const packed = catalogs.get(profession.id).map((recipe) => `${recipe.id}:${recipe.skill}:${recipe.source}:${recipe.reagents}`).join(",");
  lines.push(`  [${profession.id}] = [=[${packed}]=],`);
}
lines.push("}", "");
fs.writeFileSync(output, lines.join("\n"), "utf8");
console.log(`Wrote ${path.relative(root, output)}: ${total} recipes across ${catalogs.size} professions`);
