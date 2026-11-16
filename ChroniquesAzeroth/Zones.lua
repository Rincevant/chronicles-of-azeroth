-- The zone catalogue: zones, their artwork and the starter quest data that the embedded
-- catalogue completes at load time.

local _, ns = ...
local CA = ns.CA

-- Classic Alliance zone catalogue. IDs stay centralized here so that they
-- can be checked and extended without changing the interface.
CA.zones = {
  {
    key = "elwynn", name = "Forêt d’Elwynn", continent = "Royaumes de l’Est",
    faction = "Alliance", minLevel = 1, maxLevel = 12, questTitle = "QUÊTES D’ELWYNN", mapTitle = "FORÊT D’ELWYNN",
    cardArt = "zone-elwynn.tga", heroArt = "zone-elwynn.tga",
    -- Former starter catalogue; replaced at load time by the full Forever catalogue.
    -- IDs come from the Forever client this database refers to; titles are
    -- still read from the client so that they follow the player's language.
    quests = {
      { id = 783 }, { id = 16 },
      -- This introduction can be skipped: Eagan directly offers
      -- "Wolves Across the Border". It is listed, but not required.
      { id = 5261, optional = true, reason = "Introduction facultative" },
      { id = 7 }, { id = 33 }, { id = 15 }, { id = 18 }, { id = 3905 },
      { id = 3903 }, { id = 3904 }, { id = 6 }, { id = 54 }, { id = 2158 },
      { id = 21 }, { id = 84 }, { id = 85 }, { id = 107 }, { id = 86 },
      { id = 111 }, { id = 106 }, { id = 112 }, { id = 47 }, { id = 60 },
      { id = 61 }, { id = 114 }, { id = 62 }, { id = 87 }, { id = 5545 },
      { id = 88 }, { id = 83 }, { id = 40 }, { id = 46 }, { id = 59 },
      { id = 39 }, { id = 45 }, { id = 37 }, { id = 35 }, { id = 147 },
      { id = 52 }, { id = 109 }, { id = 71 }, { id = 11 }, { id = 123 },
      { id = 76 }, { id = 239 }, { id = 176 },
    },
    dungeons = { "Les Mortemines" },
  },
  {
    key = "dunmorogh", name = "Dun Morogh", continent = "Royaumes de l’Est",
    faction = "Alliance", minLevel = 1, maxLevel = 12, questTitle = "QUÊTES DE DUN MOROGH", mapTitle = "DUN MOROGH",
    cardArt = "zone-dunmorogh.tga", heroArt = "zone-dunmorogh.tga",
    -- Former 1-12 catalogue. Mount exchanges, the "Welcome!" quest that
    -- Forever lacks and Gnomeregan are deliberately left out.
    quests = {
      { id = 179 }, { id = 403 }, { id = 170 }, { id = 183 }, { id = 233 },
      { id = 3361 }, { id = 182 }, { id = 234 }, { id = 218 }, { id = 282 },
      { id = 400 }, { id = 420 }, { id = 2160 }, { id = 3364 }, { id = 3365 },
      { id = 310 }, { id = 317 }, { id = 5541 }, { id = 308 }, { id = 311 },
      { id = 313 }, { id = 318 }, { id = 319 }, { id = 320 }, { id = 287 },
      { id = 315 }, { id = 432 }, { id = 291 }, { id = 412 }, { id = 413 },
      { id = 414 }, { id = 415 }, { id = 419 }, { id = 6722 }, { id = 417 },
      { id = 433 }, { id = 312 }, { id = 314 },
    },
  },
  {
    key = "westfall", name = "Marche de l’Ouest", continent = "Royaumes de l’Est",
    faction = "Alliance", minLevel = 9, maxLevel = 20, questTitle = "QUÊTES DE MARCHE DE L’OUEST", mapTitle = "MARCHE DE L’OUEST",
    cardArt = "zone-westfall.tga", heroArt = "zone-westfall.tga",
    -- Former 9-20 catalogue; the level 44 "Sweet Amber" quests
    -- belong to another progression range.
    quests = {
      { id = 184 }, { id = 36 }, { id = 6181 }, { id = 6261 }, { id = 6281 },
      { id = 6285 }, { id = 12 }, { id = 22 }, { id = 64 }, { id = 38 },
      { id = 13 }, { id = 102 }, { id = 151 }, { id = 9 }, { id = 117 },
      { id = 153 }, { id = 103 }, { id = 136 }, { id = 138 }, { id = 139 },
      { id = 140 }, { id = 14 }, { id = 65 }, { id = 132 }, { id = 135 },
      { id = 141 }, { id = 142 }, { id = 155 }, { id = 152 }, { id = 104 },
    },
  },
  {
    key = "lochmodan", name = "Loch Modan", continent = "Royaumes de l’Est",
    faction = "Alliance", minLevel = 10, maxLevel = 22, questTitle = "QUÊTES DE LOCH MODAN", mapTitle = "LOCH MODAN",
    cardArt = "zone-lochmodan.tga", heroArt = "zone-lochmodan.tga",
    quests = {
      { id = 6387 }, { id = 6388 }, { id = 6391 }, { id = 6392 }, { id = 416 },
      { id = 418 }, { id = 224 }, { id = 267 }, { id = 1338 }, { id = 237 },
      { id = 263 }, { id = 273 }, { id = 298 }, { id = 301 }, { id = 302 },
      { id = 307 }, { id = 309 }, { id = 385 }, { id = 454 }, { id = 1339 },
      { id = 2038 }, { id = 257 }, { id = 217 }, { id = 258 }, { id = 161 },
      { id = 199 }, { id = 250 }, { id = 274 }, { id = 278 }, { id = 280 },
      { id = 297 }, { id = 436 }, { id = 255 }, { id = 271 }, { id = 283 },
      { id = 531 }, { id = 256 },
    },
  },
  {
    key = "teldrassil", name = "Teldrassil", continent = "Kalimdor",
    faction = "Alliance", minLevel = 1, maxLevel = 12, questTitle = "QUÊTES DE TELDRASSIL", mapTitle = "TELDRASSIL",
    cardArt = "zone-teldrassil.tga", heroArt = "zone-teldrassil.tga",
    -- Former 1-12 night elf starting path. The "Welcome!"
    -- introduction is not part of the retained Forever catalogue.
    quests = {
      { id = 458 }, { id = 456 }, { id = 457 }, { id = 459 }, { id = 916 },
      { id = 3519 }, { id = 3521 }, { id = 3522 }, { id = 4495 }, { id = 488 },
      { id = 917 }, { id = 920 }, { id = 921 }, { id = 928 }, { id = 929 },
      { id = 997 }, { id = 2159 }, { id = 475 }, { id = 476 }, { id = 2438 },
      { id = 489 }, { id = 918 }, { id = 919 }, { id = 922 }, { id = 932 },
      { id = 487 }, { id = 2459 }, { id = 2541 }, { id = 483 }, { id = 923 },
      { id = 933 }, { id = 2498 }, { id = 2499 }, { id = 930 }, { id = 931 },
      { id = 2399 }, { id = 2561 }, { id = 934 }, { id = 935 }, { id = 937 },
      { id = 940 }, { id = 7383 }, { id = 486 }, { id = 927 }, { id = 938 },
      { id = 941 },
    },
  },
  {
    key = "darkshore", name = "Sombrivage", continent = "Kalimdor",
    faction = "Alliance", minLevel = 10, maxLevel = 22, questTitle = "QUÊTES DE SOMBRIVAGE", mapTitle = "SOMBRIVAGE",
    cardArt = "zone-darkshore.tga", heroArt = "zone-darkshore.tga",
    -- Darkshore is shown under its French name, Sombrivage. The two
    -- "Onu is meditating" quests, which have no Classic progression, are left out.
    quests = {
      { id = 983 }, { id = 6341 }, { id = 6342 }, { id = 6343 }, { id = 953 },
      { id = 954 }, { id = 955 }, { id = 958 }, { id = 1001 }, { id = 956 },
      { id = 957 }, { id = 3524 }, { id = 4722 }, { id = 4723 }, { id = 984 },
      { id = 985 }, { id = 1002 }, { id = 1141 }, { id = 2118 }, { id = 4681 },
      { id = 4728 }, { id = 4811 }, { id = 4812 }, { id = 4813 }, { id = 4725 },
      { id = 4727 }, { id = 4761 }, { id = 4762 }, { id = 5713 }, { id = 963 },
      { id = 1003 }, { id = 2138 }, { id = 4730 }, { id = 944 }, { id = 947 },
      { id = 948 }, { id = 949 }, { id = 950 }, { id = 982 }, { id = 1138 },
      { id = 945 }, { id = 965 }, { id = 966 }, { id = 967 }, { id = 2139 },
      { id = 4740 }, { id = 4763 }, { id = 4731 }, { id = 4732 }, { id = 4733 },
      { id = 729 }, { id = 731 }, { id = 741 }, { id = 942 }, { id = 951 },
      { id = 968 }, { id = 986 }, { id = 993 }, { id = 995 }, { id = 2078 },
      { id = 2098 }, { id = 5321 }, { id = 970 }, { id = 994 },
    },
  },
}

-- Classic geographic coverage. IDs stay available for the artwork
-- and to attach subzones to their parent zone.
local CLASSIC_ZONE_AREAS = {
  elwynn = { 12, 6170 },
  dunmorogh = { 1, 131, 133, 135, 146, 801, 6137, 6176, 6457 },
  westfall = { 40 },
  lochmodan = { 38 },
  teldrassil = { 141, 257, 6450 },
  darkshore = { 148, 442 },
  badlands = { 3 }, blastedlands = { 4 }, swampofsorrows = { 8 }, duskwood = { 10 }, wetlands = { 11 },
  westernplaguelands = { 28 }, stranglethorn = { 33, 5287, 5339 }, alterac = { 36 }, deadwind = { 41 },
  redridge = { 44 }, arathi = { 45 }, burningsteppes = { 46 }, hinterlands = { 47 }, searinggorge = { 51 },
  -- 154 is Deathknell: without this subzone, "Rude Awakening" (363),
  -- the first Forsaken quest, was never attached to Tirisfal.
  tirisfal = { 85, 154, 155, 6454 }, silverpine = { 130 }, easternplaguelands = { 139 }, hillsbrad = { 267 },
  stormwind = { 1519 }, ironforge = { 1537 }, undercity = { 1497 },
  durotar = { 14, 365, 6451, 6453 }, dustwallow = { 15 }, azshara = { 16 }, barrens = { 17, 392 },
  mulgore = { 215, 6452 }, ashenvale = { 331 }, feralas = { 357 }, felwood = { 361 }, thousandneedles = { 400 },
  desolace = { 405 }, stonetalon = { 406 }, tanaris = { 440 }, ungoro = { 490 }, moonglade = { 493 },
  winterspring = { 618 }, silithus = { 1377 }, orgrimmar = { 1637 }, thunderbluff = { 1638 }, darnassus = { 1657 },
}

local CLASSIC_ZONE_CATALOG = {
  { key = "badlands", name = "Terres ingrates", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 35, maxLevel = 45 },
  { key = "blastedlands", name = "Terres foudroyées", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 45, maxLevel = 55 },
  { key = "swampofsorrows", name = "Marais des Chagrins", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 35, maxLevel = 45 },
  { key = "duskwood", name = "Bois de la Pénombre", continent = "Royaumes de l’Est", faction = "Alliance", minLevel = 20, maxLevel = 30 },
  { key = "wetlands", name = "Les Paluns", continent = "Royaumes de l’Est", faction = "Alliance", minLevel = 20, maxLevel = 30 },
  { key = "westernplaguelands", name = "Maleterres de l’Ouest", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 51, maxLevel = 58 },
  { key = "stranglethorn", name = "Vallée de Strangleronce", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 30, maxLevel = 45 },
  { key = "alterac", name = "Montagnes d’Alterac", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 30, maxLevel = 40 },
  { key = "deadwind", name = "Défilé de Deuillevent", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 55, maxLevel = 60 },
  { key = "redridge", name = "Les Carmines", continent = "Royaumes de l’Est", faction = "Alliance", minLevel = 15, maxLevel = 25 },
  { key = "arathi", name = "Hautes-terres d’Arathi", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 30, maxLevel = 40 },
  { key = "burningsteppes", name = "Steppes ardentes", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 50, maxLevel = 58 },
  { key = "hinterlands", name = "Les Hinterlands", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 40, maxLevel = 50 },
  { key = "searinggorge", name = "Gorge des Vents brûlants", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 43, maxLevel = 50 },
  { key = "tirisfal", name = "Clairières de Tirisfal", continent = "Royaumes de l’Est", faction = "Horde", minLevel = 1, maxLevel = 12 },
  { key = "silverpine", name = "Forêt des Pins-Argentés", continent = "Royaumes de l’Est", faction = "Horde", minLevel = 10, maxLevel = 20 },
  { key = "easternplaguelands", name = "Maleterres de l’Est", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 53, maxLevel = 60 },
  { key = "hillsbrad", name = "Contreforts de Hautebrande", continent = "Royaumes de l’Est", faction = "Neutre", minLevel = 20, maxLevel = 30 },
  { key = "stormwind", name = "Hurlevent", continent = "Royaumes de l’Est", faction = "Alliance", minLevel = 1, maxLevel = 60 },
  { key = "ironforge", name = "Forgefer", continent = "Royaumes de l’Est", faction = "Alliance", minLevel = 1, maxLevel = 60 },
  { key = "undercity", name = "Fossoyeuse", continent = "Royaumes de l’Est", faction = "Horde", minLevel = 1, maxLevel = 60 },
  { key = "durotar", name = "Durotar", continent = "Kalimdor", faction = "Horde", minLevel = 1, maxLevel = 12 },
  { key = "dustwallow", name = "Marécage d’Âprefange", continent = "Kalimdor", faction = "Neutre", minLevel = 35, maxLevel = 45 },
  { key = "azshara", name = "Azshara", continent = "Kalimdor", faction = "Neutre", minLevel = 45, maxLevel = 55 },
  { key = "barrens", name = "Les Tarides", continent = "Kalimdor", faction = "Horde", minLevel = 10, maxLevel = 25 },
  { key = "mulgore", name = "Mulgore", continent = "Kalimdor", faction = "Horde", minLevel = 1, maxLevel = 12 },
  { key = "ashenvale", name = "Orneval", continent = "Kalimdor", faction = "Neutre", minLevel = 18, maxLevel = 30 },
  { key = "feralas", name = "Féralas", continent = "Kalimdor", faction = "Neutre", minLevel = 40, maxLevel = 50 },
  { key = "felwood", name = "Gangrebois", continent = "Kalimdor", faction = "Neutre", minLevel = 48, maxLevel = 55 },
  { key = "thousandneedles", name = "Mille pointes", continent = "Kalimdor", faction = "Neutre", minLevel = 25, maxLevel = 35 },
  { key = "desolace", name = "Désolace", continent = "Kalimdor", faction = "Neutre", minLevel = 30, maxLevel = 40 },
  { key = "stonetalon", name = "Les Serres-Rocheuses", continent = "Kalimdor", faction = "Neutre", minLevel = 15, maxLevel = 27 },
  { key = "tanaris", name = "Tanaris", continent = "Kalimdor", faction = "Neutre", minLevel = 40, maxLevel = 50 },
  { key = "ungoro", name = "Cratère d’Un’Goro", continent = "Kalimdor", faction = "Neutre", minLevel = 48, maxLevel = 55 },
  { key = "moonglade", name = "Reflet-de-Lune", continent = "Kalimdor", faction = "Neutre", minLevel = 10, maxLevel = 60 },
  { key = "winterspring", name = "Berceau-de-l’Hiver", continent = "Kalimdor", faction = "Neutre", minLevel = 53, maxLevel = 60 },
  { key = "silithus", name = "Silithus", continent = "Kalimdor", faction = "Neutre", minLevel = 55, maxLevel = 60 },
  { key = "orgrimmar", name = "Orgrimmar", continent = "Kalimdor", faction = "Horde", minLevel = 1, maxLevel = 60 },
  { key = "thunderbluff", name = "Les Pitons-du-Tonnerre", continent = "Kalimdor", faction = "Horde", minLevel = 1, maxLevel = 60 },
  { key = "darnassus", name = "Darnassus", continent = "Kalimdor", faction = "Alliance", minLevel = 1, maxLevel = 60 },
}

for _, zone in ipairs(CA.zones) do zone.areaIDs = CLASSIC_ZONE_AREAS[zone.key] or {} end
for _, zone in ipairs(CLASSIC_ZONE_CATALOG) do
  zone.areaIDs = CLASSIC_ZONE_AREAS[zone.key] or {}
  zone.quests = {}
  table.insert(CA.zones, zone)
end
for _, zone in ipairs(CA.zones) do
  zone.continentKey = zone.continent == "Kalimdor" and "kalimdor" or "east"
end

-- Former starting anchor. The embedded catalogue then replaces it with its
-- complete list, without waiting for an external index.
local STARTER_QUESTS_BY_ZONE = { tirisfal = { 363 } }
for _, zone in ipairs(CA.zones) do
  for _, questID in ipairs(STARTER_QUESTS_BY_ZONE[zone.key] or {}) do
    table.insert(zone.quests, { id = questID })
  end
end

-- The 47 artworks of the manifest are converted to TGA in Assets/.
-- A single artwork serves both the cards and the banner, to limit the
-- number of textures the interface loads. Blackrock Mountain is the
-- banner artwork of the Burning Steppes: it is the neighbouring zone, and
-- this shows the whole manifest without creating a fake zone.
local ZONE_ART = {
  elwynn = "zone-elwynn.tga", westfall = "zone-westfall.tga", redridge = "zone-redridge.tga",
  duskwood = "zone-duskwood.tga", lochmodan = "zone-lochmodan.tga", dunmorogh = "zone-dunmorogh.tga",
  wetlands = "zone-wetlands.tga", badlands = "zone-badlands.tga", searinggorge = "zone-searinggorge.tga",
  burningsteppes = { card = "zone-burningsteppes.tga", hero = "zone-blackrock-mountain.tga" },
  swampofsorrows = "zone-swampofsorrows.tga", blastedlands = "zone-blastedlands.tga",
  deadwind = "zone-deadwind.tga", arathi = "zone-arathi.tga", hillsbrad = "zone-hillsbrad.tga",
  alterac = "zone-alterac.tga", hinterlands = "zone-hinterlands.tga", silverpine = "zone-silverpine.tga",
  tirisfal = "zone-tirisfal.tga", stranglethorn = "zone-stranglethorn.tga",
  westernplaguelands = "zone-westernplaguelands.tga", easternplaguelands = "zone-easternplaguelands.tga",
  durotar = "zone-durotar.tga", mulgore = "zone-mulgore.tga", teldrassil = "zone-teldrassil.tga",
  darkshore = "zone-darkshore.tga", barrens = "zone-barrens.tga", stonetalon = "zone-stonetalon.tga",
  ashenvale = "zone-ashenvale.tga", thousandneedles = "zone-thousandneedles.tga", desolace = "zone-desolace.tga",
  feralas = "zone-feralas.tga", dustwallow = "zone-dustwallow.tga", tanaris = "zone-tanaris.tga",
  azshara = "zone-azshara.tga", felwood = "zone-felwood.tga", ungoro = "zone-ungoro.tga",
  winterspring = "zone-winterspring.tga", moonglade = "zone-moonglade.tga", silithus = "zone-silithus.tga",
  stormwind = "zone-stormwind.tga", ironforge = "zone-ironforge.tga", undercity = "zone-undercity.tga",
  darnassus = "zone-darnassus.tga", orgrimmar = "zone-orgrimmar.tga", thunderbluff = "zone-thunderbluff.tga",
}

for _, zone in ipairs(CA.zones) do
  local art = ZONE_ART[zone.key]
  if art then
    zone.cardArt = type(art) == "table" and art.card or art
    zone.heroArt = type(art) == "table" and art.hero or art
  end
end

-- Badges will come back once zone tracking is stable.
CA.badges = {}

-- Starter metadata: quest level,
-- minimum level and Classic reference XP. The XP is an estimate for a
-- quest that is not active; the client stays the authority on the actual reward.
CA.questMeta = {
  [6]={5,2,335}, [7]={2,1,170}, [11]={10,6,840}, [15]={3,1,250}, [16]={1,1}, [18]={4,2,355}, [21]={5,1,450}, [33]={2,1,170},
  [35]={10,7,420}, [37]={10,7,210}, [39]={10,7,1050}, [40]={10,7,85}, [45]={10,7,420}, [46]={10,7,840}, [47]={7,4,630},
  [52]={10,7,630}, [54]={5,1,225}, [59]={10,7,210}, [60]={7,3,475}, [61]={7,3,790}, [62]={7,4,475}, [71]={10,7,210},
  [76]={10,4,840}, [83]={9,4,780}, [84]={6,5,135}, [85]={6,5,135}, [86]={6,5,405}, [87]={8,5,880}, [88]={9,6,780},
  [106]={6,5,135}, [107]={6,5,135}, [109]={10,9,630}, [111]={6,5,135}, [112]={7,5,315}, [114]={7,5,790}, [123]={10,7,210},
  [147]={10,7,840}, [176]={11,5,880}, [239]={10,6,210}, [783]={1,1,40}, [2158]={5,1,110}, [3903]={4,2,35}, [3904]={4,2,180},
  [3905]={4,2,355}, [5261]={2,1,85}, [5545]={9,5,780},
  [179]={1,1,80}, [363]={1,1,40}, [403]={1,1}, [170]={2,1,170}, [183]={3,1,250}, [233]={3,1,190}, [3361]={3,3,250}, [182]={4,1,355}, [234]={4,1,270},
  [218]={5,1,560}, [282]={5,1,335}, [400]={5,2,110}, [420]={5,1,335}, [2160]={5,1,110}, [3364]={5,4,225}, [3365]={5,4,450}, [310]={6,2,135},
  [317]={6,2,680}, [5541]={6,5,540}, [308]={7,1}, [311]={7,2,630}, [313]={7,4,630}, [318]={7,2,160}, [319]={8,2,530}, [320]={8,2,880},
  [287]={9,7,590}, [315]={9,5,780}, [432]={9,5,590}, [291]={10,1,420}, [412]={10,7,840}, [413]={10,8,420}, [414]={10,8,630}, [415]={10,8,85},
  [419]={10,8,420}, [6722]={10,10,85}, [417]={11,8,660}, [433]={11,6,660}, [312]={12,7,910}, [314]={12,6,910},
  [184]={9,8,590}, [36]={10,9,420}, [6181]={10,10,210}, [6261]={10,10,210}, [6281]={10,10,420}, [6285]={10,10,1050}, [12]={12,9,910},
  [22]={12,9,910}, [64]={12,9,910}, [38]={13,9,910}, [13]={14,9,980}, [102]={14,8,980}, [151]={14,9,1250}, [9]={15,8,1050}, [117]={15,10},
  [153]={15,10,1050}, [103]={16,10,1150}, [136]={16,10,580}, [138]={16,10,580}, [139]={16,10,580}, [140]={16,10,1150}, [14]={17,9,1600},
  [65]={18,14,1350}, [132]={18,14,680}, [135]={18,14,680}, [141]={18,14,340}, [142]={18,14,1350}, [155]={18,14,1700}, [152]={19,10,1450}, [104]={20,15,1550},
  [6387]={10,10,210}, [6388]={10,10,210}, [6391]={10,10,420}, [6392]={10,10,1050}, [416]={11,10,880}, [418]={11,7,880}, [224]={12,10,910},
  [267]={12,10,910}, [1338]={14,9,980}, [237]={15,10,1050}, [263]={15,10,1050}, [273]={15,10,270}, [298]={15,10,270}, [301]={15,10,540},
  [302]={15,10,270}, [307]={15,9,1350}, [309]={15,10,1050}, [385]={15,10,1050}, [454]={15,10,105}, [1339]={15,9,540}, [2038]={15,12,1050},
  [257]={16,11,880}, [217]={17,10,1600}, [258]={17,11,950}, [161]={18,16,1350}, [199]={18,16,1350}, [250]={18,16,680}, [274]={18,16,340},
  [278]={18,16,1350}, [280]={18,16,680}, [297]={18,13,1350}, [436]={18,13,340}, [255]={19,15,1800}, [271]={20,15,780}, [283]={20,16,1950},
  [531]={20,15,1550}, [256]={22,17,1750},
  [458]={1,1,40}, [456]={2,1,170}, [457]={3,1,250}, [459]={3,1,250}, [916]={4,3,355}, [3519]={4,2,90}, [3521]={4,2,355}, [3522]={4,2,445},
  [4495]={4,2,270}, [488]={5,4,450}, [917]={5,1,560}, [920]={5,1,45}, [921]={5,1,335}, [928]={5,1,225}, [929]={5,1,335}, [997]={5,4,225},
  [2159]={5,1,110}, [475]={6,4,270}, [476]={6,4,540}, [2438]={6,1,405}, [489]={7,4,630}, [918]={7,4,630}, [919]={7,4,790}, [922]={7,4,315},
  [932]={7,4,630}, [487]={8,5,700}, [2459]={8,1,880}, [2541]={8,3,700}, [483]={9,4,780}, [923]={9,4,980}, [933]={9,1,780}, [2498]={9,4,80},
  [2499]={9,4,980}, [930]={10,4,840}, [931]={10,4,840}, [2399]={10,4,85}, [2561]={10,3,1050}, [934]={11,1,660}, [935]={11,1,1100},
  [937]={11,6,440}, [940]={11,6,220}, [7383]={11,1,660}, [486]={12,4,1150}, [927]={12,5,455}, [938]={12,7,910}, [941]={12,9,910},
  [983]={10,7,840}, [6341]={10,10,210}, [6342]={10,10,420}, [6343]={10,10,1050}, [953]={12,9,910}, [954]={12,7,680}, [955]={12,7,910},
  [958]={12,9,910}, [1001]={12,7,1150}, [956]={13,7,910}, [957]={13,7,680}, [3524]={13,11,680}, [4722]={13,11,455}, [4723]={13,11,455},
  [984]={14,10,740}, [985]={14,10,980}, [1002]={14,7,980}, [1141]={14,10,980}, [2118]={14,10,980}, [4681]={14,11,980}, [4728]={14,12,490},
  [4811]={14,12,490}, [4812]={14,12,490}, [4813]={14,12,980}, [4725]={15,12,540}, [4727]={15,12,540}, [4761]={15,11,105}, [4762]={15,11,800},
  [5713]={15,10,1050}, [963]={16,11,880}, [1003]={16,7,1150}, [2138]={16,10,1150}, [4730]={16,12,580}, [944]={17,12,630}, [947]={17,12,1250},
  [948]={17,12,630}, [949]={17,12,1250}, [950]={17,12,950}, [982]={17,13,1250}, [1138]={17,15,1250}, [945]={18,10,1350}, [965]={18,13,680},
  [966]={18,13,1350}, [967]={18,13,1000}, [2139]={18,10,1350}, [4740]={18,15,1700}, [4763]={18,15,1700}, [4731]={19,13,730}, [4732]={19,13,730},
  [4733]={19,13,730}, [729]={20,15,1150}, [731]={20,15,1950}, [741]={20,15,1150}, [942]={20,15,1550}, [951]={20,12,1950}, [968]={20,10,1950},
  [986]={20,10,1550}, [993]={20,10,780}, [995]={20,10,780}, [2078]={20,14,1150}, [2098]={20,14,1550}, [5321]={20,17,1550}, [970]={21,13,1650},
  [994]={22,10,1750},
}

-- Starter Classic chain links. A quest can have several
-- follow-ups: they are listed explicitly in its details.
CA.questLinks = {
  [783] = { next = { 7, 18, 5261 } }, [7] = { previous = { 783 }, next = { 15 } },
  [15] = { previous = { 7 }, next = { 21 } }, [21] = { previous = { 15 }, next = { 54 } },
  [18] = { previous = { 783 }, next = { 6 } }, [6] = { previous = { 18 } },
  [5261] = { previous = { 783 }, next = { 33 } }, [33] = { previous = { 5261 }, next = { 3903 } },
  -- Milly is available after "Wolves Across the Border" (33),
  -- then her chain goes on in this order.
  [3903] = { previous = { 33 }, next = { 3904 } }, [3904] = { previous = { 3903 }, next = { 3905 } }, [3905] = { previous = { 3904 } },
  [85] = { next = { 86 } }, [86] = { previous = { 85 }, next = { 84 } }, [84] = { previous = { 86 }, next = { 87 } }, [87] = { previous = { 84 } },
  [106] = { next = { 111 } }, [111] = { previous = { 106 }, next = { 107 } }, [107] = { previous = { 111 }, next = { 112 } }, [112] = { previous = { 107 }, next = { 114 } }, [114] = { previous = { 112 } },
  [62] = { next = { 76 } }, [76] = { previous = { 62 }, next = { 239, 11 } }, [239] = { previous = { 76 } }, [11] = { previous = { 76 } },
  [40] = { next = { 35 } }, [35] = { previous = { 40 }, next = { 37 } }, [37] = { previous = { 35 }, next = { 45 } }, [45] = { previous = { 37 }, next = { 71 } }, [71] = { previous = { 45 }, next = { 39 } }, [39] = { previous = { 71 }, next = { 46, 59 } }, [46] = { previous = { 39 } }, [59] = { previous = { 39 } },
  [123] = { next = { 147 } }, [147] = { previous = { 123 } },
}

CA.questRewardIndex = {}
CA.questTitleFallbacks = { [363] = CA.locale == "frFR" and "Réveil brutal" or "Rude Awakening" }
