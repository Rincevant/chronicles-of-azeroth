local ADDON_NAME = ...
local CA = CreateFrame("Frame")
CA:RegisterEvent("PLAYER_LOGIN")
CA:RegisterEvent("QUEST_TURNED_IN")
CA:RegisterEvent("QUEST_ACCEPTED")
CA:RegisterEvent("ZONE_CHANGED_NEW_AREA")
CA:RegisterEvent("GET_ITEM_INFO_RECEIVED")
-- La lecture des recettes se déclenche uniquement à partir des signaux du
-- métier natif : aucune exploration de données de profession au chargement.
CA:RegisterEvent("TRADE_SKILL_SHOW")
-- Ils arrivent quand la liste native devient réellement prête et lors de
-- l'apprentissage d'une recette, même si Chroniques est fermé.
CA:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
CA:RegisterEvent("NEW_RECIPE_LEARNED")
CA:RegisterEvent("SKILL_LINES_CHANGED")
-- Les variantes historiques ne sont pas présentes sur tous les clients.
pcall(CA.RegisterEvent, CA, "CRAFT_SHOW")
pcall(CA.RegisterEvent, CA, "CRAFT_UPDATE")
pcall(CA.RegisterEvent, CA, "CRAFT_CLOSE")
pcall(CA.RegisterEvent, CA, "LEARNED_SPELL_IN_TAB")
CA:RegisterEvent("TRADE_SKILL_CLOSE")

-- Chroniques suit la langue du client : le français reste la langue par
-- défaut des clients frFR, tous les autres clients reçoivent l'anglais.
CA.locale = (GetLocale and GetLocale() == "frFR") and "frFR" or "enUS"
CA.VERSION = "0.25.0-beta"

local TEXT = {
  frFR = {
    addonTitle = "CHRONIQUES D’AZEROTH", subtitle = "Collectionneur - Quêtes et métiers",
    quests = "Quêtes", professions = "Professions", toysSoon = "Jouets (à venir)", dungeonsSoon = "Donjons (à venir)", raidsSoon = "Raids (à venir)", feedback = "Feedback",
    faction = "FACTION :", tracking = "SUIVI :", account = "COMPTE", character = "PERSONNAGE",
    zones = "ZONES", easternKingdoms = "Royaumes de l’Est", kalimdor = "Kalimdor", searchZone = "Rechercher une zone...",
    completed = "TERMINÉ", rewards = "RÉCOMPENSES", prerequisites = "Prérequis", next = "Suite",
    professionCatalogs = "Catalogues Forever", recipeCatalog = "CATALOGUE DES RECETTES", recipeDetail = "DÉTAIL DE LA RECETTE", components = "COMPOSANTS", obtainRecipe = "OBTENIR LA RECETTE",
    selectRecipe = "Sélectionnez une recette", detailWillAppear = "Le détail apparaîtra ici.", learnedRecipe = "RECETTE APPRISE", learnRecipe = "RECETTE À APPRENDRE", skill = "COMPÉTENCE",
    sourceUnknown = "Obtention non précisée dans le catalogue Forever.", trainer = "Maître de profession", vendor = "Vendeur", loot = "Butin", questSpecial = "Quête, réputation ou source spéciale", specialSource = "Source spéciale",
    openProfessionComponents = "Ouvrez ce métier dans le jeu pour lire les composants de cette recette.", componentsWillAppear = "Les composants apparaîtront ici.", sourceWillAppear = "Le lieu d’obtention sera affiché pour la recette sélectionnée.", learnedAccount = "Déjà apprise sur le compte.", learnedCharacter = "Déjà apprise par ce personnage.", sourceClientUnavailable = "Source non fournie par le client Forever pour cette recette. Ouvrez un maître ou un vendeur : toute information exposée par le jeu est mémorisée ici.",
    feedbackTitle = "VOS RETOURS", feedbackDescription = "Chroniques ne peut pas envoyer de données sur Internet. Préparez le rapport, copiez-le avec Ctrl+C, puis collez-le dans le canal de retours choisi.", prepareReport = "PRÉPARER LE RAPPORT", feedbackCopyHint = "Le rapport est sélectionné : Ctrl+C pour le copier. Aucun envoi automatique.", feedbackDestination = "Canal recommandé : un ticket GitHub pour les bugs, Discord pour les échanges rapides.",
    noZoneQuests = "Aucune quête extérieure répertoriée dans cette zone", noQuestListed = "AUCUNE QUÊTE RÉPERTORIÉE", noZoneQuestDetail = "Le catalogue embarqué est chargé ; cette zone ne possède pas de quête extérieure dans les données Forever.", rewardsWhenSelected = "Récompenses disponibles quand une quête est sélectionnée.",
    questInProgress = "EN COURS - dans votre journal", questCompleted = "TERMINÉE", questDiscover = "À DÉCOUVRIR", required = "requis", optional = "fac.", level = "Niv.", questsRequired = "%d / %d requises terminées - %d à faire", questCount = "%d / %d quêtes - %s",
    object = "objet", objects = "objets", hoverIcons = "survolez les icônes", questFallback = "Quête %d", questUnavailable = "Titre de quête indisponible", recipeFallback = "Recette #%d", itemFallback = "Objet #%d",
    currentRank = "Rang actuel : %s", listedOnCharacters = "Répertorié sur %d personnage%s - meilleur rang : %s", catalogNotLearnedAccount = "Catalogue Forever complet - métier non appris sur les personnages synchronisés.", catalogNotLearnedCharacter = "Catalogue Forever complet - métier non appris par ce personnage.", professionNotLearned = "Ce métier n’est pas appris par ce personnage.", recipeCatalogSummary = "CATALOGUE - %d RECETTES - %d APPRISES", recipesListed = "%d recettes répertoriées", noRecipeListed = "Aucune recette répertoriée", known = "APPRISE", obtain = "À OBTENIR", characterOwner = "PAR CE PERSONNAGE", accountOwner = "SUR LE COMPTE",
    footerQuests = "/chroniques pour ouvrir - Les quêtes validées sont détectées et mémorisées", footerProfessions = "Les recettes apprises se synchronisent automatiquement à l’ouverture du métier.", footerFeedback = "Onglet Feedback : préparez un rapport, copiez-le avec Ctrl+C, puis envoyez-le.",
    minimapOpen = "Clic gauche : ouvrir ou fermer", minimapToggle = "Clic droit : alterner Compte / Personnage", minimapDrag = "Glisser : déplacer autour de la minicarte", trackingChanged = "suivi %s.", addonLoaded = "chargé. Utilisez l’icône autour de la minicarte ou", questDetected = "quête validée détectée (ID %d).",
    reportVersion = "Version", reportLocale = "Langue", reportCharacter = "Personnage", reportRealm = "Royaume", reportSection = "Onglet", reportTracking = "Suivi", reportZone = "Zone", reportProfession = "Métier", reportProblem = "Décrivez le problème", reportSteps = "Étapes pour reproduire", reportExpected = "Résultat attendu", reportActual = "Résultat obtenu",
  },
  enUS = {
    addonTitle = "CHRONICLES OF AZEROTH", subtitle = "Collector - Quests and professions",
    quests = "Quests", professions = "Professions", toysSoon = "Toys (coming soon)", dungeonsSoon = "Dungeons (coming soon)", raidsSoon = "Raids (coming soon)", feedback = "Feedback",
    faction = "FACTION:", tracking = "TRACKING:", account = "ACCOUNT", character = "CHARACTER",
    zones = "ZONES", easternKingdoms = "Eastern Kingdoms", kalimdor = "Kalimdor", searchZone = "Search a zone...",
    completed = "COMPLETED", rewards = "REWARDS", prerequisites = "Prerequisites", next = "Follow-up",
    professionCatalogs = "Forever Catalogs", recipeCatalog = "RECIPE CATALOG", recipeDetail = "RECIPE DETAILS", components = "REAGENTS", obtainRecipe = "OBTAIN RECIPE",
    selectRecipe = "Select a recipe", detailWillAppear = "Details will appear here.", learnedRecipe = "RECIPE LEARNED", learnRecipe = "RECIPE TO LEARN", skill = "SKILL",
    sourceUnknown = "Acquisition is not specified in the Forever catalog.", trainer = "Profession trainer", vendor = "Vendor", loot = "Loot", questSpecial = "Quest, reputation, or special source", specialSource = "Special source",
    openProfessionComponents = "Open this profession in-game to read this recipe's reagents.", componentsWillAppear = "Reagents will appear here.", sourceWillAppear = "The acquisition source will appear for the selected recipe.", learnedAccount = "Already learned on the account.", learnedCharacter = "Already learned by this character.", sourceClientUnavailable = "The Forever client did not provide a source for this recipe. Open a trainer or vendor: every detail exposed by the game is stored here.",
    feedbackTitle = "YOUR FEEDBACK", feedbackDescription = "Chronicles cannot send data to the Internet. Prepare the report, copy it with Ctrl+C, then paste it into the feedback channel you choose.", prepareReport = "PREPARE REPORT", feedbackCopyHint = "The report is selected: press Ctrl+C to copy it. Nothing is sent automatically.", feedbackDestination = "Recommended channel: a GitHub issue for bugs, Discord for quick discussion.",
    noZoneQuests = "No outdoor quests are listed for this zone", noQuestListed = "NO QUESTS LISTED", noZoneQuestDetail = "The embedded catalog is loaded; this zone has no outdoor quests in the Forever data.", rewardsWhenSelected = "Rewards are available when a quest is selected.",
    questInProgress = "IN PROGRESS - in your quest log", questCompleted = "COMPLETED", questDiscover = "TO DISCOVER", required = "required", optional = "opt.", level = "Lvl.", questsRequired = "%d / %d required completed - %d remaining", questCount = "%d / %d quests - %s",
    object = "item", objects = "items", hoverIcons = "hover the icons", questFallback = "Quest %d", questUnavailable = "Quest title unavailable", recipeFallback = "Recipe #%d", itemFallback = "Item #%d",
    currentRank = "Current rank: %s", listedOnCharacters = "Recorded on %d character%s - highest rank: %s", catalogNotLearnedAccount = "Full Forever catalog - profession not learned on synchronized characters.", catalogNotLearnedCharacter = "Full Forever catalog - profession not learned by this character.", professionNotLearned = "This profession is not learned by this character.", recipeCatalogSummary = "CATALOG - %d RECIPES - %d LEARNED", recipesListed = "%d recipes listed", noRecipeListed = "No recipes listed", known = "LEARNED", obtain = "TO OBTAIN", characterOwner = "BY THIS CHARACTER", accountOwner = "ON ACCOUNT",
    footerQuests = "/chronicles to open - Completed quests are detected and saved", footerProfessions = "Learned recipes synchronize automatically when the profession window opens.", footerFeedback = "Feedback: prepare a report, copy it with Ctrl+C, then send it.",
    minimapOpen = "Left-click: open or close", minimapToggle = "Right-click: switch Account / Character", minimapDrag = "Drag: move around the minimap", trackingChanged = "tracking: %s.", addonLoaded = "loaded. Use the icon around the minimap or", questDetected = "completed quest detected (ID %d).",
    reportVersion = "Version", reportLocale = "Locale", reportCharacter = "Character", reportRealm = "Realm", reportSection = "Tab", reportTracking = "Tracking", reportZone = "Zone", reportProfession = "Profession", reportProblem = "Describe the problem", reportSteps = "Steps to reproduce", reportExpected = "Expected result", reportActual = "Actual result",
  },
}

function CA:L(key, ...)
  local value = (TEXT[self.locale] and TEXT[self.locale][key]) or TEXT.enUS[key] or key
  if select("#", ...) > 0 then return string.format(value, ...) end
  return value
end

local ZONE_NAMES = {
  elwynn = { frFR = "Forêt d’Elwynn", enUS = "Elwynn Forest" }, dunmorogh = { frFR = "Dun Morogh", enUS = "Dun Morogh" }, westfall = { frFR = "Marche de l’Ouest", enUS = "Westfall" }, lochmodan = { frFR = "Loch Modan", enUS = "Loch Modan" }, teldrassil = { frFR = "Teldrassil", enUS = "Teldrassil" }, darkshore = { frFR = "Sombrivage", enUS = "Darkshore" },
  badlands = { frFR = "Terres ingrates", enUS = "Badlands" }, blastedlands = { frFR = "Terres foudroyées", enUS = "Blasted Lands" }, swampofsorrows = { frFR = "Marais des Chagrins", enUS = "Swamp of Sorrows" }, duskwood = { frFR = "Bois de la Pénombre", enUS = "Duskwood" }, wetlands = { frFR = "Les Paluns", enUS = "Wetlands" }, westernplaguelands = { frFR = "Maleterres de l’Ouest", enUS = "Western Plaguelands" }, stranglethorn = { frFR = "Vallée de Strangleronce", enUS = "Stranglethorn Vale" }, alterac = { frFR = "Montagnes d’Alterac", enUS = "Alterac Mountains" }, deadwind = { frFR = "Défilé de Deuillevent", enUS = "Deadwind Pass" }, redridge = { frFR = "Les Carmines", enUS = "Redridge Mountains" }, arathi = { frFR = "Hautes-terres d’Arathi", enUS = "Arathi Highlands" }, burningsteppes = { frFR = "Steppes ardentes", enUS = "Burning Steppes" }, hinterlands = { frFR = "Les Hinterlands", enUS = "The Hinterlands" }, searinggorge = { frFR = "Gorge des Vents brûlants", enUS = "Searing Gorge" }, tirisfal = { frFR = "Clairières de Tirisfal", enUS = "Tirisfal Glades" }, silverpine = { frFR = "Forêt des Pins-Argentés", enUS = "Silverpine Forest" }, easternplaguelands = { frFR = "Maleterres de l’Est", enUS = "Eastern Plaguelands" }, hillsbrad = { frFR = "Contreforts de Hautebrande", enUS = "Hillsbrad Foothills" }, stormwind = { frFR = "Hurlevent", enUS = "Stormwind City" }, ironforge = { frFR = "Forgefer", enUS = "Ironforge" }, undercity = { frFR = "Fossoyeuse", enUS = "Undercity" },
  durotar = { frFR = "Durotar", enUS = "Durotar" }, dustwallow = { frFR = "Marécage d’Âprefange", enUS = "Dustwallow Marsh" }, azshara = { frFR = "Azshara", enUS = "Azshara" }, barrens = { frFR = "Les Tarides", enUS = "The Barrens" }, mulgore = { frFR = "Mulgore", enUS = "Mulgore" }, ashenvale = { frFR = "Orneval", enUS = "Ashenvale" }, feralas = { frFR = "Féralas", enUS = "Feralas" }, felwood = { frFR = "Gangrebois", enUS = "Felwood" }, thousandneedles = { frFR = "Mille pointes", enUS = "Thousand Needles" }, desolace = { frFR = "Désolace", enUS = "Desolace" }, stonetalon = { frFR = "Les Serres-Rocheuses", enUS = "Stonetalon Mountains" }, tanaris = { frFR = "Tanaris", enUS = "Tanaris" }, ungoro = { frFR = "Cratère d’Un’Goro", enUS = "Un'Goro Crater" }, moonglade = { frFR = "Reflet-de-Lune", enUS = "Moonglade" }, winterspring = { frFR = "Berceau-de-l’Hiver", enUS = "Winterspring" }, silithus = { frFR = "Silithus", enUS = "Silithus" }, orgrimmar = { frFR = "Orgrimmar", enUS = "Orgrimmar" }, thunderbluff = { frFR = "Les Pitons-du-Tonnerre", enUS = "Thunder Bluff" }, darnassus = { frFR = "Darnassus", enUS = "Darnassus" },
}

function CA:GetZoneName(zone)
  local names = zone and ZONE_NAMES[zone.key]
  return (names and names[self.locale]) or (zone and zone.name) or ""
end

function CA:GetContinentName(key)
  return key == "kalimdor" and self:L("kalimdor") or self:L("easternKingdoms")
end

function CA:GetFactionName(faction)
  if faction == "Neutre" then return self.locale == "frFR" and "Neutre" or "Neutral" end
  return faction or ""
end

function CA:GetZoneQuestTitle(zone)
  if self.locale == "frFR" and zone and zone.questTitle then return zone.questTitle end
  local prefix = self.locale == "frFR" and "QUÊTES DE " or "QUESTS OF "
  return prefix .. string.upper(self:GetZoneName(zone))
end

-- Catalogue de zones Alliance Classic. Les IDs restent centralisés ici afin
-- d'être vérifiables et d'être étendus sans modifier l'interface.
CA.zones = {
  {
    key = "elwynn", name = "Forêt d’Elwynn", continent = "Royaumes de l’Est",
    faction = "Alliance", minLevel = 1, maxLevel = 12, questTitle = "QUÊTES D’ELWYNN", mapTitle = "FORÊT D’ELWYNN",
    cardArt = "zone-elwynn.tga", heroArt = "zone-elwynn.tga",
    -- Ancien catalogue de démarrage ; remplacé au chargement par le catalogue Forever complet.
    -- Les IDs viennent du client Forever référencé par cette base ; les titres
    -- restent lus dans le client afin de respecter la langue du joueur.
    quests = {
      { id = 783 }, { id = 16 },
      -- Cette introduction peut être contournée : Eagan propose directement
      -- « Des loups de l’autre côté ». Elle est affichée, mais pas requise.
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
    -- Ancien catalogue 1–12. Les échanges de monture, la quête
    -- « Bienvenue ! » absente de Forever et Gnomeregan sont volontairement exclus.
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
    -- Ancien catalogue 9–20 ; les quêtes « Sweet Amber » niveau 44
    -- appartiennent à une autre tranche de progression.
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
    -- Ancien parcours de départ kaldorei 1–12. L'introduction
    -- « Welcome! » ne fait pas partie du catalogue Forever retenu.
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
    -- Darkshore est affiché sous son nom français : Sombrivage. Les deux
    -- quêtes « Onu is meditating » sans progression Classic sont exclues.
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

-- Couverture géographique Classic. Les IDs restent disponibles pour les
-- illustrations et pour rattacher les sous-zones à leur grande zone.
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
  -- 154 est Deathknell : sans cette sous-zone, « Réveil brutal » (363),
  -- première quête réprouvée, n'était jamais rattachée à Tirisfal.
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

-- Ancien ancrage de départ. Le catalogue embarqué le remplace ensuite par sa
-- liste complète, sans attendre une indexation externe.
local STARTER_QUESTS_BY_ZONE = { tirisfal = { 363 } }
for _, zone in ipairs(CA.zones) do
  for _, questID in ipairs(STARTER_QUESTS_BY_ZONE[zone.key] or {}) do
    table.insert(zone.quests, { id = questID })
  end
end

-- Les 47 illustrations du manifeste sont converties en TGA dans Assets/.
-- Une seule illustration sert à la fois aux vignettes et à la bannière pour
-- limiter le nombre de textures chargées par l'interface. Mont Blackrock est
-- l'illustration de bannière des Steppes ardentes : c'est la zone voisine et
-- cela permet d'exposer la totalité du manifeste sans créer une fausse zone.
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

-- Les badges reviendront après stabilisation du suivi de zone.
CA.badges = {}

-- Métadonnées de démarrage : niveau de quête,
-- niveau minimum et XP de référence Classic. L'XP est une estimation pour
-- une quête non active ; le client reste l'autorité pour la récompense réelle.
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

-- Liens de séries Classic de démarrage. Chaque quête peut
-- avoir plusieurs suites : elles sont affichées explicitement dans la fiche.
CA.questLinks = {
  [783] = { next = { 7, 18, 5261 } }, [7] = { previous = { 783 }, next = { 15 } },
  [15] = { previous = { 7 }, next = { 21 } }, [21] = { previous = { 15 }, next = { 54 } },
  [18] = { previous = { 783 }, next = { 6 } }, [6] = { previous = { 18 } },
  [5261] = { previous = { 783 }, next = { 33 } }, [33] = { previous = { 5261 }, next = { 3903 } },
  -- Milly est accessible après « Les loups derrière la frontière » (33),
  -- puis sa série se poursuit dans cet ordre.
  [3903] = { previous = { 33 }, next = { 3904 } }, [3904] = { previous = { 3903 }, next = { 3905 } }, [3905] = { previous = { 3904 } },
  [85] = { next = { 86 } }, [86] = { previous = { 85 }, next = { 84 } }, [84] = { previous = { 86 }, next = { 87 } }, [87] = { previous = { 84 } },
  [106] = { next = { 111 } }, [111] = { previous = { 106 }, next = { 107 } }, [107] = { previous = { 111 }, next = { 112 } }, [112] = { previous = { 107 }, next = { 114 } }, [114] = { previous = { 112 } },
  [62] = { next = { 76 } }, [76] = { previous = { 62 }, next = { 239, 11 } }, [239] = { previous = { 76 } }, [11] = { previous = { 76 } },
  [40] = { next = { 35 } }, [35] = { previous = { 40 }, next = { 37 } }, [37] = { previous = { 35 }, next = { 45 } }, [45] = { previous = { 37 }, next = { 71 } }, [71] = { previous = { 45 }, next = { 39 } }, [39] = { previous = { 71 }, next = { 46, 59 } }, [46] = { previous = { 39 } }, [59] = { previous = { 39 } },
  [123] = { next = { 147 } }, [147] = { previous = { 123 } },
}

CA.questRewardIndex = {}
CA.questTitleFallbacks = { [363] = CA.locale == "frFR" and "Réveil brutal" or "Rude Awakening" }

-- Catalogue entièrement embarqué, généré au build depuis les données Forever.
-- Cette initialisation ne lit aucune variable d'un autre addon : Chroniques
-- reste utilisable sans extension complémentaire.
function CA:LoadEmbeddedQuestCatalog()
  local catalog = ChroniquesAzerothQuestCatalog
  if type(catalog) ~= "table" or type(catalog.zones) ~= "table" or type(catalog.quests) ~= "table" then
    self.zoneQuestIndexReady = true
    return
  end

  self.questMeta = {}
  self.questLinks = {}
  self.questTitleFallbacks = {}
  self.questSides = {}
  for questID, entry in pairs(catalog.quests) do
    if type(entry) == "table" then
      self.questMeta[questID] = { entry.q or entry.r or 1, entry.r or 1, entry.x }
      self.questTitleFallbacks[questID] = (self.locale == "frFR" and entry.t) or entry.e or entry.t or self:L("questFallback", questID)
      self.questSides[questID] = entry.s
      if entry.p or entry.n then
        self.questLinks[questID] = { previous = entry.p or {}, next = entry.n or {} }
      end
    end
  end

  for _, zone in ipairs(self.zones) do
    local questIDs = catalog.zones[zone.key]
    if type(questIDs) == "table" then
      zone.quests = {}
      for _, questID in ipairs(questIDs) do
        local entry = catalog.quests[questID]
        if entry then table.insert(zone.quests, { id = questID, side = entry.s, optional = entry.o == true }) end
      end
    end
  end
  self.zoneQuestIndexReady = true
end

CA:LoadEmbeddedQuestCatalog()

function CA:GetTrackingMode()
  return (ChroniquesAzerothDB and ChroniquesAzerothDB.trackingMode) or "account"
end

function CA:IsQuestCompletedForCharacter(questID)
  return ChroniquesAzerothCharacterDB and ChroniquesAzerothCharacterDB.completed and ChroniquesAzerothCharacterDB.completed[questID] or false
end

function CA:IsQuestCompletedByClient(questID)
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then return C_QuestLog.IsQuestFlaggedCompleted(questID) end
  if IsQuestFlaggedCompleted then return IsQuestFlaggedCompleted(questID) end
  return false
end

function CA:IsQuestCompletedForAccount(questID)
  if ChroniquesAzerothDB and ChroniquesAzerothDB.completed and ChroniquesAzerothDB.completed[questID] then return true end
  return false
end

function CA:GetCharacterKey()
  local name = UnitName("player") or "Inconnu"
  local realm = GetRealmName and GetRealmName() or "Royaume"
  return name .. "-" .. realm
end

function CA:RebuildAccountCompleted()
  local merged = {}
  -- Conserve les observations antérieures, sans les attribuer à un personnage.
  for questID, savedAt in pairs(ChroniquesAzerothDB.legacyCompleted or {}) do merged[questID] = savedAt end
  for _, character in pairs(ChroniquesAzerothDB.characters or {}) do
    for questID, savedAt in pairs(character.completed or {}) do merged[questID] = savedAt end
  end
  ChroniquesAzerothDB.completed = merged
end

function CA:SyncCurrentCharacter()
  local key = self:GetCharacterKey()
  ChroniquesAzerothCharacterDB.completed = ChroniquesAzerothCharacterDB.completed or {}
  ChroniquesAzerothDB.characters = ChroniquesAzerothDB.characters or {}
  local snapshot = ChroniquesAzerothDB.characters[key] or { completed = {} }
  snapshot.name = UnitName("player") or key
  snapshot.realm = GetRealmName and GetRealmName() or ""
  snapshot.completed = snapshot.completed or {}

  snapshot.lastSync = time()
  ChroniquesAzerothDB.characters[key] = snapshot
  self:RebuildAccountCompleted()

  -- Le catalogue couvre désormais plus de 2 500 quêtes. Les vérifications
  -- historiques sont étalées pour que la connexion reste fluide, tout en
  -- préservant l'import des validations antérieures à l'installation.
  if self.completionScanStarted then return end
  self.completionScanStarted = true
  local questIDs, seen = {}, {}
  for _, zone in ipairs(self.zones) do
    for _, quest in ipairs(self:GetAccessibleZoneQuests(zone)) do
      if not seen[quest.id] then seen[quest.id] = true; table.insert(questIDs, quest.id) end
    end
  end
  local cursor, scanner = 1, CreateFrame("Frame")
  scanner:SetScript("OnUpdate", function(frame)
    local last = math.min(cursor + 74, #questIDs)
    for index = cursor, last do
      local questID = questIDs[index]
      if self:IsQuestCompletedByClient(questID) then
        local savedAt = time()
        ChroniquesAzerothCharacterDB.completed[questID] = savedAt
        snapshot.completed[questID] = savedAt
      end
    end
    cursor = last + 1
    if cursor <= #questIDs then return end
    snapshot.lastSync = time()
    ChroniquesAzerothDB.characters[key] = snapshot
    self:RebuildAccountCompleted()
    frame:SetScript("OnUpdate", nil)
    if self.frame and self.frame:IsShown() then self:Refresh() end
  end)
end

function CA:IsQuestCompleted(questID)
  if self:GetTrackingMode() == "character" then return self:IsQuestCompletedForCharacter(questID) end
  return self:IsQuestCompletedForAccount(questID)
end

function CA:SetTrackingMode(mode)
  ChroniquesAzerothDB.trackingMode = mode
  self:Refresh()
end

function CA:QuestName(questID)
  self.questNameCache = self.questNameCache or {}
  local cached = self.questNameCache[questID]
  if cached then return cached end
  if C_QuestLog and C_QuestLog.GetTitleForQuestID then
    local title = C_QuestLog.GetTitleForQuestID(questID)
    if title and title ~= "" then
      self.questNameCache[questID] = title
      return title
    end
  end
  local fallbackTitle = self.questTitleFallbacks and self.questTitleFallbacks[questID]
  if fallbackTitle then
    self.questNameCache[questID] = fallbackTitle
    return fallbackTitle
  end
  return self:L("questUnavailable")
end

-- Les niveaux et l'XP de référence sont fournis par QuestCatalog.lua, chargé
-- avec l'addon. Aucun index externe n'est consulté pendant Refresh.
function CA:GetQuestMeta(questID)
  return self.questMeta[questID]
end

function CA:GetQuestDifficultyColor(questID)
  local meta = self:GetQuestMeta(questID)
  local level = meta and meta[1]
  local playerLevel = UnitLevel("player") or 1
  if not level then return 1, .82, .35 end
  if level >= playerLevel + 5 then return 1, .1, .1 end
  if level >= playerLevel + 3 then return 1, .5, .1 end
  if level >= playerLevel - 2 then return 1, .82, .35 end
  return .62, .62, .62
end

function CA:GetXPDisplay(questID, classicXP)
  -- Une quête active peut fournir la récompense exacte via le client.
  -- Les quêtes non acceptées utilisent l'estimation Classic embarquée.
  if GetQuestLogRewardXP then
    -- Forever attend l'ID de quête, et non l'index de son journal.
    local ok, xp = pcall(GetQuestLogRewardXP, questID)
    if ok and type(xp) == "number" and xp > 0 then return xp .. " XP" end
  end
  -- La police de la bêta ne contient pas tous les symboles Unicode. Un
  -- préfixe ASCII reste lisible dans toutes les polices locales.
  return classicXP and ((self.locale == "frFR" and "env. " or "approx. ") .. classicXP .. " XP") or nil
end

function CA:IsQuestInLog(questID)
  if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
    local index = C_QuestLog.GetLogIndexForQuestID(questID)
    return type(index) == "number" and index > 0
  end
  return false
end

local function copperText(copper)
  if type(copper) ~= "number" or copper <= 0 then return nil end
  local gold, silver, coin = math.floor(copper / 10000), math.floor((copper % 10000) / 100), copper % 100
  local parts = {}
  local suffixes = CA.locale == "frFR" and { " po", " pa", " pc" } or { "g", "s", "c" }
  if gold > 0 then table.insert(parts, gold .. suffixes[1]) end
  if silver > 0 then table.insert(parts, silver .. suffixes[2]) end
  if coin > 0 then table.insert(parts, coin .. suffixes[3]) end
  return table.concat(parts, " ")
end

function CA:GetRewardSummary(questID)
  local meta = self:GetQuestMeta(questID)
  local displayedXP = self:GetXPDisplay(questID, meta and meta[3])
  local text = displayedXP and ("XP: " .. displayedXP) or "XP: —"
  if self:IsQuestInLog(questID) and GetQuestLogRewardMoney then
    local ok, money = pcall(GetQuestLogRewardMoney, questID)
    local formatted = ok and copperText(money)
    if formatted then text = text .. " - " .. (self.locale == "frFR" and "Argent : " or "Money: ") .. formatted end
  end
  return text
end

function CA:GetQuestRewardItems(questID)
  -- Pour éviter une donnée inventée, les récompenses ne sont montrées que
  -- lorsque le client les expose pour une quête réellement dans le journal.
  if not self:IsQuestInLog(questID) then return self.questRewardIndex[questID] or {} end
  local items, choices = {}, {}
  local function addItem(target, itemName, texture, amount, itemID)
    if type(itemName) ~= "string" or itemName == "" then return end
    -- Une récompense unique doit être traitée comme 1 et jamais comparée à nil.
    table.insert(target, { name = itemName, texture = texture, amount = tonumber(amount) or 1, itemID = itemID })
  end
  if C_QuestLog and C_QuestLog.GetQuestRewardInfo then
    for itemIndex = 1, 6 do
      -- Réponses : nom, texture, quantité, qualité, utilisable, itemID.
      -- pcall ajoute sa propre valeur booléenne en première position.
      local ok, itemName, texture, amount, _, _, itemID = pcall(C_QuestLog.GetQuestRewardInfo, itemIndex, questID)
      if ok then addItem(items, itemName, texture, amount, itemID) end
    end
  end
  -- L'API Classic/Forever exposée dans le client de la bêta est cette
  -- variante globale (index de récompense, ID de quête).
  if #items == 0 and GetQuestLogRewardInfo then
    local count = GetNumQuestLogRewards and GetNumQuestLogRewards(questID) or 6
    for itemIndex = 1, count do
      local ok, itemName, texture, amount, _, _, itemID = pcall(GetQuestLogRewardInfo, itemIndex, questID)
      if ok then addItem(items, itemName, texture, amount, itemID) end
    end
  end
  -- Les récompenses au choix ont leur propre API : c'est notamment le cas
  -- de « La confrérie des voleurs » et de ses armes de milice.
  if GetQuestLogChoiceInfo and GetNumQuestLogChoices then
    local okCount, count = pcall(GetNumQuestLogChoices, questID)
    if okCount and type(count) == "number" then
      for itemIndex = 1, count do
        local ok, itemName, texture, amount, _, _, itemID = pcall(GetQuestLogChoiceInfo, itemIndex, questID)
        if ok then addItem(choices, itemName, texture, amount, itemID) end
      end
    end
  end
  for _, item in ipairs(choices) do item.choice = true; table.insert(items, item) end
  if #items == 0 then return self.questRewardIndex[questID] or {} end
  return items
end

function CA:LinkNames(ids)
  if not ids or #ids == 0 then return "—" end
  local names = {}
  for _, id in ipairs(ids) do table.insert(names, self:QuestName(id)) end
  -- La flèche Unicode était affichée comme un rectangle par la police de
  -- détail des quêtes. La virgule est volontairement un séparateur ASCII.
  return table.concat(names, ", ")
end

function CA:GetQuestLinks(questID)
  local links = { previous = {}, next = {} }
  local function addUnique(target, values)
    if type(values) ~= "table" then return end
    for _, value in pairs(values) do
      if type(value) == "number" then
        local exists = false
        for _, known in ipairs(target) do if known == value then exists = true; break end end
        if not exists then table.insert(target, value) end
      end
    end
  end
  local catalogLinks = self.questLinks[questID]
  if catalogLinks then
    addUnique(links.previous, catalogLinks.previous)
    addUnique(links.next, catalogLinks.next)
  end
  return links
end

function CA:BuildQuestTree(zone)
  local inZone, parentFor, children = {}, {}, {}
  local zoneQuests = self:GetAccessibleZoneQuests(zone)
  for _, quest in ipairs(zoneQuests) do inZone[quest.id] = true; children[quest.id] = {} end
  for _, quest in ipairs(zoneQuests) do
    local links = self:GetQuestLinks(quest.id)
    -- Un prérequis situé dans cette zone devient le parent visuel. Si une
    -- quête offre plusieurs alternatives, la première connue suffit pour
    -- l'arbre ; les autres restent visibles dans la fiche détaillée.
    for _, prerequisite in ipairs(links.previous) do
      if inZone[prerequisite] then parentFor[quest.id] = prerequisite; break end
    end
    if parentFor[quest.id] then table.insert(children[parentFor[quest.id]], quest.id) end
  end
  local ordered, visited = {}, {}
  local function addBranch(questID, depth)
    if visited[questID] then return end
    visited[questID] = true
    table.insert(ordered, { id = questID, depth = depth })
    table.sort(children[questID], function(a, b)
      local aMeta, bMeta = self:GetQuestMeta(a), self:GetQuestMeta(b)
      local aLevel, bLevel = aMeta and aMeta[1] or 0, bMeta and bMeta[1] or 0
      return aLevel == bLevel and a < b or aLevel < bLevel
    end)
    for _, childID in ipairs(children[questID]) do addBranch(childID, depth + 1) end
  end
  for _, quest in ipairs(zoneQuests) do if not parentFor[quest.id] then addBranch(quest.id, 0) end end
  -- Protection contre une donnée externe cyclique ou un parent absent.
  for _, quest in ipairs(zoneQuests) do addBranch(quest.id, 0) end
  return ordered
end

function CA:BuildQuestDisplay(zone)
  -- Une "série" est un composant complet du graphe de prérequis de la zone,
  -- et non plus seulement la branche d'une racine. L'ancien affichage pouvait
  -- séparer une même série dès qu'une quête avait plusieurs prérequis, ce qui
  -- faisait paraître ses étapes en double et laissait des barres verticales
  -- sans en-tête apparent.
  local zoneQuests = self:GetAccessibleZoneQuests(zone)
  local inZone, neighbors, parentFor, children = {}, {}, {}, {}
  for _, quest in ipairs(zoneQuests) do
    inZone[quest.id] = true
    neighbors[quest.id], children[quest.id] = {}, {}
  end

  local function questLevel(questID)
    local meta = self:GetQuestMeta(questID)
    return meta and meta[1] or 0
  end
  local function byLevelThenID(a, b)
    local aLevel, bLevel = questLevel(a), questLevel(b)
    return aLevel == bLevel and a < b or aLevel < bLevel
  end
  local function linkTogether(leftID, rightID)
    if not (inZone[leftID] and inZone[rightID]) then return end
    neighbors[leftID][rightID] = true
    neighbors[rightID][leftID] = true
  end

  -- Les liens sont lus dans les deux sens : le catalogue normalise déjà ces
  -- données, mais cela garde l'affichage robuste si une fiche ne renseigne
  -- qu'un précédent ou qu'un suivant.
  for _, quest in ipairs(zoneQuests) do
    local prerequisites = {}
    local links = self:GetQuestLinks(quest.id)
    for _, previousID in ipairs(links.previous or {}) do
      if inZone[previousID] then
        table.insert(prerequisites, previousID)
        linkTogether(quest.id, previousID)
      end
    end
    for _, nextID in ipairs(links.next or {}) do linkTogether(quest.id, nextID) end
    if #prerequisites > 0 then
      table.sort(prerequisites, byLevelThenID)
      parentFor[quest.id] = prerequisites[1]
      table.insert(children[parentFor[quest.id]], quest.id)
    end
  end
  for _, childIDs in pairs(children) do table.sort(childIDs, byLevelThenID) end

  -- Construit les composants non orientés. Chaque ID de quête appartient à un
  -- seul bloc, donc une quête n'est jamais répétée par le rendu de la liste.
  local components, seen = {}, {}
  for _, quest in ipairs(zoneQuests) do
    if not seen[quest.id] then
      local component, queue, cursor = {}, { quest.id }, 1
      seen[quest.id] = true
      while cursor <= #queue do
        local questID = queue[cursor]
        cursor = cursor + 1
        table.insert(component, questID)
        for neighborID in pairs(neighbors[questID]) do
          if not seen[neighborID] then
            seen[neighborID] = true
            table.insert(queue, neighborID)
          end
        end
      end
      table.sort(component, byLevelThenID)
      table.insert(components, component)
    end
  end

  local function orderedComponent(component)
    local isMember, ordered, displayed = {}, {}, {}
    for _, questID in ipairs(component) do isMember[questID] = true end
    local roots = {}
    for _, questID in ipairs(component) do
      if not parentFor[questID] or not isMember[parentFor[questID]] then table.insert(roots, questID) end
    end
    table.sort(roots, byLevelThenID)
    local function addBranch(questID)
      if displayed[questID] then return end
      displayed[questID] = true
      table.insert(ordered, questID)
      for _, childID in ipairs(children[questID]) do
        if isMember[childID] then addBranch(childID) end
      end
    end
    for _, rootID in ipairs(roots) do addBranch(rootID) end
    -- Les graphes cycliques ou incomplets restent visibles, mais toujours dans
    -- leur bloc unique plutôt qu'en doublon à la fin de la liste.
    for _, questID in ipairs(component) do addBranch(questID) end
    return ordered
  end

  local blocks = {}
  for _, component in ipairs(components) do
    local ordered = orderedComponent(component)
    table.insert(blocks, { ids = ordered, first = ordered[1] })
  end
  table.sort(blocks, function(a, b) return byLevelThenID(a.first, b.first) end)

  self.expandedGroups = self.expandedGroups or {}
  local entries = {}
  for _, block in ipairs(blocks) do
    local questIDs = block.ids
    if #questIDs == 1 then
      table.insert(entries, { id = questIDs[1], child = false })
    else
      local done, minLevel, maxLevel = 0, nil, nil
      for _, questID in ipairs(questIDs) do
        if self:IsQuestCompleted(questID) then done = done + 1 end
        local level = questLevel(questID)
        minLevel = not minLevel and level or math.min(minLevel, level)
        maxLevel = not maxLevel and level or math.max(maxLevel, level)
      end
      local headerID = questIDs[1]
      table.insert(entries, {
        id = headerID, group = true, expanded = self.expandedGroups[headerID] == true,
        groupDone = done, groupTotal = #questIDs,
        groupMinLevel = minLevel, groupMaxLevel = maxLevel,
      })
      if self.expandedGroups[headerID] then
        for index = 2, #questIDs do table.insert(entries, { id = questIDs[index], child = true }) end
      end
    end
  end
  return entries
end

function CA:InitializeQuestCatalog()
  -- QuestCatalog.lua est chargé avant ce fichier par le TOC. Il n'y a ni
  -- index asynchrone, ni addon tiers, ni appel réseau à attendre.
  self.zoneQuestIndexReady = true
  self.questRewardIndex = self.questRewardIndex or {}
end

function CA:RecordQuest(questID, state, accountOnly)
  if not questID then return end
  ChroniquesAzerothDB = ChroniquesAzerothDB or { completed = {}, accepted = {}, trackingMode = "account" }
  ChroniquesAzerothCharacterDB = ChroniquesAzerothCharacterDB or { completed = {}, accepted = {} }
  ChroniquesAzerothDB.completed = ChroniquesAzerothDB.completed or {}
  ChroniquesAzerothDB.accepted = ChroniquesAzerothDB.accepted or {}
  ChroniquesAzerothCharacterDB.completed = ChroniquesAzerothCharacterDB.completed or {}
  ChroniquesAzerothCharacterDB.accepted = ChroniquesAzerothCharacterDB.accepted or {}
  if state == "completed" then
    ChroniquesAzerothDB.completed[questID] = time()
    if not accountOnly then
      ChroniquesAzerothCharacterDB.completed[questID] = time()
      local key = self:GetCharacterKey()
      ChroniquesAzerothDB.characters = ChroniquesAzerothDB.characters or {}
      ChroniquesAzerothDB.characters[key] = ChroniquesAzerothDB.characters[key] or { completed = {} }
      ChroniquesAzerothDB.characters[key].completed = ChroniquesAzerothDB.characters[key].completed or {}
      ChroniquesAzerothDB.characters[key].completed[questID] = time()
      self:RebuildAccountCompleted()
    end
  elseif state == "accepted" then
    ChroniquesAzerothDB.accepted[questID] = time()
    if not accountOnly then ChroniquesAzerothCharacterDB.accepted[questID] = time() end
  end
end

function CA:QuestLists(zone)
  local completedList, remainingList, optionalList = {}, {}, {}
  for _, quest in ipairs(self:GetAccessibleZoneQuests(zone)) do
    local entry = { id = quest.id, name = quest.title or self:QuestName(quest.id) }
    if self:IsQuestCompleted(quest.id) then
      table.insert(completedList, entry)
      -- Permet aussi de récupérer les quêtes finies avant l'installation de l'addon.
      if self:GetTrackingMode() == "account" then self:RecordQuest(quest.id, "completed", true) end
    elseif quest.optional then
      entry.reason = quest.reason
      table.insert(optionalList, entry)
    else
      table.insert(remainingList, entry)
    end
  end
  table.sort(completedList, function(a, b) return a.name < b.name end)
  table.sort(remainingList, function(a, b) return a.name < b.name end)
  return completedList, remainingList, optionalList
end

function CA:ZoneProgress(zone)
  local done, required, optional = 0, 0, 0
  for _, quest in ipairs(self:GetAccessibleZoneQuests(zone)) do
    if quest.optional then
      optional = optional + 1
    else
      required = required + 1
      if self:IsQuestCompleted(quest.id) then done = done + 1 end
    end
  end
  return done, required, required > 0 and math.floor(done / required * 100 + 0.5) or 0, optional
end

function CA:GetSelectedZone()
  local key = self.selectedZoneKey or self.zones[1].key
  for _, zone in ipairs(self.zones) do
    if zone.key == key then return zone end
  end
  self.selectedZoneKey = self.zones[1].key
  return self.zones[1]
end

local function shortText(text, limit)
  text, limit = tostring(text or ""), tonumber(limit) or 0
  if limit < 1 then return "" end
  -- string.sub travaille en octets : il coupait l'apostrophe typographique
  -- d'« l’Est » en deux, ce que le client affichait comme un carré. Ce
  -- parcours respecte les séquences UTF-8 sans dépendre de la lib utf8,
  -- absente de certains clients Classic.
  local cursor, characters, total = 1, 0, #text
  while cursor <= total and characters < limit do
    local byte = string.byte(text, cursor)
    local width = byte < 0x80 and 1 or (byte < 0xE0 and 2 or (byte < 0xF0 and 3 or (byte < 0xF8 and 4 or 1)))
    if cursor + width - 1 > total then break end
    cursor, characters = cursor + width, characters + 1
  end
  if cursor <= total then return string.sub(text, 1, cursor - 1) .. "..." end
  return text
end

-- Emblèmes Blizzard natifs : l'indicateur reste correct quel que soit le
-- personnage connecté, sans embarquer une image externe pour les factions.
local FACTION_ICON_TEXTURES = {
  Alliance = "Interface\\TargetingFrame\\UI-PVP-Alliance",
  Horde = "Interface\\TargetingFrame\\UI-PVP-Horde",
}

function CA:GetPlayerFaction()
  local faction = UnitFactionGroup and UnitFactionGroup("player") or nil
  return faction == "Horde" and "Horde" or "Alliance"
end

function CA:IsZoneAccessible(zone)
  return zone.faction ~= (self:GetPlayerFaction() == "Alliance" and "Horde" or "Alliance")
end

function CA:IsQuestAccessible(questID, quest)
  local side = (quest and quest.side) or (self.questSides and self.questSides[questID])
  return side == nil or side == "" or side == (self:GetPlayerFaction() == "Alliance" and "A" or "H")
end

function CA:GetAccessibleZoneQuests(zone)
  local quests = {}
  for _, quest in ipairs(zone.quests or {}) do
    if self:IsQuestAccessible(quest.id, quest) then table.insert(quests, quest) end
  end
  return quests
end

local function normalizedSearch(text)
  text = string.lower(tostring(text or ""))
  -- Les remplacements sont écrits caractère par caractère : les classes Lua
  -- travaillent sur les octets et ne conviennent pas à l'UTF-8 français.
  text = text:gsub("à", "a"):gsub("â", "a"):gsub("ä", "a"):gsub("À", "a"):gsub("Â", "a"):gsub("Ä", "a")
  text = text:gsub("é", "e"):gsub("è", "e"):gsub("ê", "e"):gsub("ë", "e"):gsub("É", "e"):gsub("È", "e"):gsub("Ê", "e"):gsub("Ë", "e")
  text = text:gsub("î", "i"):gsub("ï", "i"):gsub("Î", "i"):gsub("Ï", "i"):gsub("ô", "o"):gsub("ö", "o"):gsub("Ô", "o"):gsub("Ö", "o")
  text = text:gsub("ù", "u"):gsub("û", "u"):gsub("ü", "u"):gsub("Ù", "u"):gsub("Û", "u"):gsub("Ü", "u"):gsub("ç", "c"):gsub("Ç", "c")
  return text:gsub("[’'%-]", " ")
end

function CA:IsZoneVisible(zone)
  if not self:IsZoneAccessible(zone) then return false end
  if zone.continentKey ~= self.activeContinent then return false end
  local query = normalizedSearch(self.zoneSearchQuery)
  return query == "" or normalizedSearch(self:GetZoneName(zone)):find(query, 1, true) ~= nil
end

function CA:GetFirstVisibleZone()
  for _, zone in ipairs(self.zones) do if self:IsZoneVisible(zone) then return zone end end
  return nil
end

function CA:RefreshZoneList(resetScroll)
  if not self.zoneRows or not self.zoneScrollChild then return end
  local visibleRow = 0
  for index, zone in ipairs(self.zones) do
    local row = self.zoneRows[index]
    local shown = self:IsZoneVisible(zone)
    row.button:SetShown(shown)
    if shown then
      row.button:ClearAllPoints()
      row.button:SetPoint("TOPLEFT", 0, -(visibleRow * 76))
      visibleRow = visibleRow + 1
    end
  end
  self.zoneScrollChild:SetHeight(math.max(285, visibleRow * 76))
  if resetScroll and self.zoneScroll then self.zoneScroll:SetVerticalScroll(0) end
end

function CA:SetActiveContinent(continent)
  self.activeContinent = continent == "kalimdor" and "kalimdor" or "east"
  local first = self:GetFirstVisibleZone()
  if first then self.selectedZoneKey = first.key end
  self:RefreshZoneList(true)
  self:Refresh()
end

-- Ces variables sont déclarées avant les fonctions de lecture afin que Lua
-- les capture bien comme locales : les données sont renseignées plus bas,
-- avant que le client ne puisse déclencher PLAYER_LOGIN.
local PROFESSION_DEFINITIONS, PROFESSION_BY_ID, PROFESSION_NAME_TO_ID, STATIC_PROFESSION_CATALOGS, STATIC_RECIPE_TO_PROFESSION
-- Incrémente cette version lorsque la méthode de lecture d'un catalogue
-- évolue. Ainsi un ancien état incomplet ou erroné ne peut jamais être repris
-- comme un état « appris » par la nouvelle méthode.
local PROFESSION_CATALOG_SYNC_VERSION = 11

function CA:GetProfessionStorage()
  ChroniquesAzerothCharacterDB = ChroniquesAzerothCharacterDB or {}
  ChroniquesAzerothCharacterDB.professions = ChroniquesAzerothCharacterDB.professions or {}
  local storage = ChroniquesAzerothCharacterDB.professions
  -- Les métiers restent enregistrés par personnage, puis sont indexés dans
  -- les variables de compte. Cela permet au bouton Compte d'agréger les
  -- recettes réellement lues sur plusieurs personnages sans emprunter de
  -- données à un addon tiers.
  ChroniquesAzerothDB = ChroniquesAzerothDB or { completed = {}, accepted = {}, trackingMode = "account" }
  ChroniquesAzerothDB.professionCharacters = ChroniquesAzerothDB.professionCharacters or {}
  ChroniquesAzerothDB.professionCharacters[self:GetCharacterKey()] = storage
  return storage
end

function CA:PublishProfessionStorage(storage)
  if type(storage) ~= "table" then return end
  ChroniquesAzerothDB = ChroniquesAzerothDB or { completed = {}, accepted = {}, trackingMode = "account" }
  ChroniquesAzerothDB.professionCharacters = ChroniquesAzerothDB.professionCharacters or {}
  ChroniquesAzerothDB.professionCharacters[self:GetCharacterKey()] = storage
end

function CA:GetAccountProfessionStorage()
  -- Garantit que le personnage connecté participe lui aussi à l'agrégat,
  -- même avant sa première ouverture de métier dans cette version.
  self:GetProfessionStorage()
  local aggregate = {}
  for _, characterStorage in pairs(ChroniquesAzerothDB.professionCharacters or {}) do
    if type(characterStorage) == "table" then
      for rawProfessionID, record in pairs(characterStorage) do
        local professionID = tonumber(rawProfessionID)
        if professionID and PROFESSION_BY_ID[professionID] and type(record) == "table" then
          local definition = PROFESSION_BY_ID[professionID]
          local merged = aggregate[professionID] or {
            name = self:GetProfessionName(definition), icon = definition.icon, rank = 0, maxRank = 0,
            learned = false, recipes = {}, characterCount = 0,
          }
          if record.learned then merged.characterCount = merged.characterCount + 1 end
          merged.name = record.name or merged.name
          merged.icon = record.icon or merged.icon
          merged.learned = merged.learned or record.learned == true
          merged.rank = math.max(tonumber(merged.rank) or 0, tonumber(record.rank) or 0)
          merged.maxRank = math.max(tonumber(merged.maxRank) or 0, tonumber(record.maxRank) or 0)
          if tonumber(record.catalogSyncVersion) == PROFESSION_CATALOG_SYNC_VERSION then
            merged.catalogSyncVersion = PROFESSION_CATALOG_SYNC_VERSION
            for recipeKey, recipe in pairs(record.recipes or {}) do
              if type(recipe) == "table" then
                local key = tostring(recipe.id or recipeKey)
                local mergedRecipe = merged.recipes[key] or {}
                mergedRecipe.id = recipe.id or mergedRecipe.id
                mergedRecipe.name = recipe.name or mergedRecipe.name
                mergedRecipe.icon = recipe.icon or mergedRecipe.icon
                mergedRecipe.link = recipe.link or mergedRecipe.link
                mergedRecipe.reagents = recipe.reagents or mergedRecipe.reagents
                -- Une recette devient connue au niveau du compte dès qu'un
                -- personnage synchronisé la connaît ; jamais l'inverse.
                mergedRecipe.learned = mergedRecipe.learned or recipe.learned == true
                merged.recipes[key] = mergedRecipe
              end
            end
          end
          aggregate[professionID] = merged
        end
      end
    end
  end
  return aggregate
end

local function professionIDFor(name, skillLine)
  if type(skillLine) == "number" and PROFESSION_BY_ID[skillLine] then return skillLine end
  return PROFESSION_NAME_TO_ID[name]
end

-- Les catalogues ci-dessous sont fournis localement par le fichier
-- ProfessionCatalog.lua, généré depuis les pages Forever de Wowhead. Ils ne
-- déclenchent aucune requête réseau : les noms et les icônes viennent des
-- sortilèges déjà présents dans le client du joueur.
local function catalogSourceText(code)
  if type(code) ~= "string" or code == "" then
    return CA:L("sourceUnknown")
  end
  local labels = {}
  if code:find("6", 1, true) then table.insert(labels, CA:L("trainer")) end
  if code:find("4", 1, true) then table.insert(labels, CA:L("vendor")) end
  if code:find("2", 1, true) then table.insert(labels, CA:L("loot")) end
  if code:find("5", 1, true) then table.insert(labels, CA:L("questSpecial")) end
  if code:find("1", 1, true) then table.insert(labels, CA:L("specialSource")) end
  return #labels > 0 and table.concat(labels, " - ") or CA:L("sourceUnknown")
end

local function parseStaticProfessionCatalogs()
  local source = type(_G.ChroniquesAzerothProfessionCatalog) == "table" and _G.ChroniquesAzerothProfessionCatalog or {}
  local catalogs = {}
  for professionID, packed in pairs(source) do
    if type(professionID) == "number" and type(packed) == "string" then
      local catalog = {}
      for token in packed:gmatch("[^,]+") do
        local id, skill, sourceCode, packedReagents = token:match("^(%d+):(%d*):([12456]*):?(.*)$")
        id = tonumber(id)
        if id then
          local reagents = {}
          for reagent in tostring(packedReagents or ""):gmatch("[^|]+") do
            local itemID, count = reagent:match("^(%d+)x(%d+)$")
            itemID = tonumber(itemID)
            if itemID then table.insert(reagents, { itemID = itemID, count = tonumber(count) or 1 }) end
          end
          table.insert(catalog, { id = id, skill = tonumber(skill) or 0, sourceCode = sourceCode or "", reagents = reagents })
        end
      end
      catalogs[professionID] = catalog
    end
  end
  return catalogs
end

STATIC_PROFESSION_CATALOGS = parseStaticProfessionCatalogs()
STATIC_RECIPE_TO_PROFESSION = {}
for professionID, catalog in pairs(STATIC_PROFESSION_CATALOGS) do
  for _, recipe in ipairs(catalog) do
    -- Certains sorts appartiennent à plusieurs catalogues historiques. Le
    -- premier métier déclaré conserve alors la priorité, ce qui suffit à
    -- identifier la fenêtre actuellement ouverte sans toucher à ses données.
    STATIC_RECIPE_TO_PROFESSION[recipe.id] = STATIC_RECIPE_TO_PROFESSION[recipe.id] or professionID
  end
end

local function catalogSpellInfo(recipeID)
  local name, icon
  if type(C_Spell) == "table" and type(C_Spell.GetSpellInfo) == "function" then
    local ok, info = pcall(C_Spell.GetSpellInfo, recipeID)
    if ok and type(info) == "table" then
      name, icon = info.name, info.iconID
    end
  end
  if (not name or name == "") and type(GetSpellInfo) == "function" then
    local ok, spellName, _, spellIcon = pcall(GetSpellInfo, recipeID)
    if ok then name, icon = spellName, icon or spellIcon end
  end
  return name or CA:L("recipeFallback", recipeID), icon
end

-- GetTradeSkillInfo fournit un nom localisé mais, sur Forever, pas toujours
-- un lien qui contient l'ID du sort. Le catalogue de Chroniques construit son
-- propre index localement et paresseusement depuis
-- GetSpellInfo : ce sont des données déjà installées par le client, sans
-- appel réseau ni chargement de recette.
local STATIC_RECIPE_ID_BY_NAME = {}
local function staticRecipeIDByName(professionID, recipeName)
  if type(recipeName) ~= "string" or recipeName == "" then return nil end
  local names = STATIC_RECIPE_ID_BY_NAME[professionID]
  if not names then
    names = {}
    for _, recipe in ipairs(STATIC_PROFESSION_CATALOGS[professionID] or {}) do
      local name = catalogSpellInfo(recipe.id)
      if type(name) == "string" and name ~= "" and not name:match("^Recette #") and not name:match("^Recipe #") then
        -- Conserver le premier ID suffit pour les rares homonymes :
        -- il appartient à la même profession et la fenêtre native en donne le
        -- même état connu/inconnu.
        names[name] = names[name] or recipe.id
      end
    end
    STATIC_RECIPE_ID_BY_NAME[professionID] = names
  end
  return names[recipeName]
end

-- GetItemInfo est asynchrone sur Classic : il peut donc ne pas encore fournir
-- le nom d'un composant. Son icône, en revanche, est souvent déjà disponible
-- par ID. On la lit sans requête serveur ni attente du cache.
local function itemIconFor(itemID)
  itemID = tonumber(itemID)
  if not itemID then return nil end
  if type(C_Item) == "table" and type(C_Item.GetItemIconByID) == "function" then
    local ok, icon = pcall(C_Item.GetItemIconByID, itemID)
    if ok and icon then return icon end
  end
  if type(GetItemIcon) == "function" then
    local ok, icon = pcall(GetItemIcon, itemID)
    if ok and icon then return icon end
  end
  return nil
end

local function itemNameFor(itemID)
  itemID = tonumber(itemID)
  if not itemID then return nil end
  if type(C_Item) == "table" and type(C_Item.GetItemNameByID) == "function" then
    local ok, name = pcall(C_Item.GetItemNameByID, itemID)
    if ok and type(name) == "string" and name ~= "" then return name end
  end
  if type(GetItemInfo) == "function" then
    local ok, name = pcall(GetItemInfo, itemID)
    if ok and type(name) == "string" and name ~= "" then return name end
  end
  return nil
end

local function professionFromRecipeIDs(recipeIDs)
  local counts = {}
  for _, recipeID in ipairs(recipeIDs or {}) do
    local professionID = STATIC_RECIPE_TO_PROFESSION[tonumber(recipeID)]
    if professionID then counts[professionID] = (counts[professionID] or 0) + 1 end
  end
  local selectedID, bestCount
  for professionID, count in pairs(counts) do
    if not bestCount or count > bestCount then selectedID, bestCount = professionID, count end
  end
  return selectedID
end

local function cachedRecipeIDByName(record, professionID, recipeName)
  if type(recipeName) ~= "string" or recipeName == "" then return nil end
  -- Le client Classic résout aussi un sort par son nom localisé. Essayer
  -- cette API d'abord évite de dépendre d'un
  -- nom préchargé dans notre catalogue compact. L'ID reste borné au métier
  -- actuel afin qu'un sort homonyme de classe ne soit jamais comptabilisé.
  if type(C_Spell) == "table" and type(C_Spell.GetSpellInfo) == "function" then
    local infoOK, info = pcall(C_Spell.GetSpellInfo, recipeName)
    local recipeID = infoOK and type(info) == "table" and tonumber(info.spellID) or nil
    if recipeID and STATIC_RECIPE_TO_PROFESSION[recipeID] == professionID then return recipeID end
  end
  if type(GetSpellInfo) == "function" then
    local lookupOK, _, _, _, _, _, _, recipeID = pcall(GetSpellInfo, recipeName)
    recipeID = lookupOK and tonumber(recipeID) or nil
    if recipeID and STATIC_RECIPE_TO_PROFESSION[recipeID] == professionID then return recipeID end
  end
  for _, recipe in pairs(record and record.recipes or {}) do
    if recipe.name == recipeName and type(recipe.id) == "number" then return recipe.id end
  end
  return staticRecipeIDByName(professionID, recipeName)
end

-- Lit uniquement les rangs que le client expose déjà. Cette fonction n'ouvre
-- aucune fenêtre de métier et ne demande aucune donnée supplémentaire.
function CA:ReadPlayerProfessions()
  local storage, found = self:GetProfessionStorage(), {}
  local couldRead = false

  if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
    local ok, first, second, archaeology, fishing, cooking, firstAid = pcall(GetProfessions)
    if ok then
      for _, professionIndex in pairs({ first, second, archaeology, fishing, cooking, firstAid }) do
        if type(professionIndex) == "number" then
          local infoOK, name, icon, rank, maxRank, _, _, skillLine = pcall(GetProfessionInfo, professionIndex)
          local professionID = infoOK and professionIDFor(name, skillLine)
          if professionID then
            found[professionID] = true
            local definition, record = PROFESSION_BY_ID[professionID], storage[professionID] or {}
            record.name = name or self:GetProfessionName(definition)
            record.icon = icon or definition.icon
            record.rank = tonumber(rank) or 0
            record.maxRank = tonumber(maxRank) or record.maxRank or 0
            record.learned = true
            record.recipes = record.recipes or {}
            storage[professionID] = record
            couldRead = true
          end
        end
      end
    end
  end

  -- Le client Forever peut encore exposer les lignes de compétence historiques.
  -- Le repli ne modifie pas l'état visuel des cadres natifs (pas d'ExpandSkillHeader).
  if not couldRead and type(GetNumSkillLines) == "function" and type(GetSkillLineInfo) == "function" then
    local countOK, lineCount = pcall(GetNumSkillLines)
    if countOK and type(lineCount) == "number" then
      for skillIndex = 1, lineCount do
        local infoOK, name, isHeader, _, rank, _, _, maxRank = pcall(GetSkillLineInfo, skillIndex)
        local professionID = infoOK and not isHeader and professionIDFor(name)
        if professionID then
          found[professionID] = true
          local definition, record = PROFESSION_BY_ID[professionID], storage[professionID] or {}
          record.name = name or self:GetProfessionName(definition)
          record.icon = record.icon or definition.icon
          record.rank = tonumber(rank) or 0
          record.maxRank = tonumber(maxRank) or record.maxRank or 0
          record.learned = true
          record.recipes = record.recipes or {}
          storage[professionID] = record
          couldRead = true
        end
      end
    end
  end

  if couldRead then
    for professionID, record in pairs(storage) do
      if not found[professionID] then record.learned = false end
    end
  end
  self:PublishProfessionStorage(storage)
  return storage
end

-- Le catalogue ne force aucun chargement côté serveur. Il mémorise uniquement
-- ce que l'interface Blizzard expose lorsque le joueur ouvre son métier.
function CA:RecordProfessionRecipe(record, recipeID, name, icon, link, learned, source)
  if type(name) ~= "string" or name == "" then return false end
  record.recipes = record.recipes or {}
  local key = tostring(recipeID or link or name)
  local recipe = record.recipes[key] or {}
  recipe.id = type(recipeID) == "number" and recipeID or recipe.id
  recipe.name = name
  recipe.icon = icon or recipe.icon
  recipe.link = type(link) == "string" and link or recipe.link
  -- Une recette n'est apprise que lorsqu'une source Blizzard l'a affirmé.
  -- Les anciennes versions conservaient nil comme « apprise », ce qui a pu
  -- transformer tout un catalogue historique en faux positif.
  recipe.learned = learned == true
  if type(source) == "string" and source ~= "" then recipe.source = source end
  record.recipes[key] = recipe
  return true
end

-- Raccourci pour NEW_RECIPE_LEARNED / LEARNED_SPELL_IN_TAB. Le
-- catalogue donne le métier correspondant au sort ; aucune fenêtre Blizzard
-- n'est ouverte et aucune donnée n'est demandée au serveur ici. Ce signal
-- complète un relevé déjà établi par ScanOpenProfession.
function CA:RecordProfessionSpellLearned(recipeID)
  recipeID = tonumber(recipeID)
  local professionID = recipeID and STATIC_RECIPE_TO_PROFESSION[recipeID]
  if not professionID then return false end

  local definition = PROFESSION_BY_ID[professionID]
  if not definition then return false end
  local storage = self:ReadPlayerProfessions()
  local record = storage[professionID] or {}
  record.name = record.name or self:GetProfessionName(definition)
  record.icon = record.icon or definition.icon
  record.learned, record.recipes = true, record.recipes or {}

  local staticRecipe
  for _, recipe in ipairs(STATIC_PROFESSION_CATALOGS[professionID] or {}) do
    if recipe.id == recipeID then staticRecipe = recipe; break end
  end
  if not staticRecipe then return false end
  local name, icon = catalogSpellInfo(recipeID)
  self:RecordProfessionRecipe(record, recipeID, name, icon, nil, true)
  storage[professionID] = record
  self:PublishProfessionStorage(storage)
  return true
end

function CA:GetProfessionRecipes(record, professionID)
  local recipes, seen = {}, {}
  local savedRecipes = record and record.recipes or {}
  -- Les versions antérieures supposaient à tort qu'une propriété absente
  -- signifiait « apprise ». Leur état est conservé pour les noms/icônes, mais
  -- ne compte jamais comme appris avant une resynchronisation fiable.
  local hasReliableLearnedState = record and tonumber(record.catalogSyncVersion) == PROFESSION_CATALOG_SYNC_VERSION

  -- Le catalogue statique garantit une liste complète, y compris pour une
  -- profession que le personnage ne possède pas encore. Une entrée mémorisée
  -- depuis la fenêtre native garde toujours la priorité pour le nom, l'icône,
  -- l'état « apprise » et une provenance plus précise éventuelle.
  for _, staticRecipe in ipairs(STATIC_PROFESSION_CATALOGS[professionID] or {}) do
    local key = tostring(staticRecipe.id)
    local saved = savedRecipes[key]
    local recipe = {
      key = key,
      id = staticRecipe.id,
      name = (saved and saved.name) or staticRecipe.name,
      icon = (saved and saved.icon) or staticRecipe.icon,
      link = saved and saved.link,
      learned = hasReliableLearnedState and saved and saved.learned == true or false,
      requiredSkill = staticRecipe.skill,
      source = (saved and saved.sourceLocale == self.locale and saved.source) or catalogSourceText(staticRecipe.sourceCode),
      reagents = (saved and saved.reagents) or staticRecipe.reagents,
      staticEntry = staticRecipe,
    }
    seen[key] = true
    table.insert(recipes, recipe)
  end

  -- Les listes natives Forever peuvent aussi contenir une recette récente non
  -- encore présente dans la prochaine révision du catalogue embarqué : elle
  -- reste donc visible au lieu d'être masquée.
  for key, saved in pairs(savedRecipes) do
    if not seen[key] then
      table.insert(recipes, {
        key = key,
        id = saved.id,
        name = saved.name,
        icon = saved.icon,
        link = saved.link,
        learned = hasReliableLearnedState and saved.learned == true or false,
        source = saved.source,
        reagents = saved.reagents,
      })
    end
  end

  table.sort(recipes, function(a, b)
    local aSkill, bSkill = tonumber(a.requiredSkill) or 0, tonumber(b.requiredSkill) or 0
    if aSkill ~= bSkill then return aSkill < bSkill end
    return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
  end)
  return recipes
end

-- La résolution d'un sort peut être coûteuse pour les catalogues Forever
-- étendus. Elle est donc faite seulement pour les lignes visibles et pour la
-- recette sélectionnée, jamais pour les 506 entrées à la connexion.
function CA:HydrateProfessionRecipe(recipe)
  if not recipe then return recipe end

  -- Quand la fenêtre native du métier est encore disponible, elle est la
  -- meilleure source pour l'icône de l'objet fabriqué. Le sort de métier
  -- peut en effet avoir une icône générique violette, différente de l'objet.
  if type(C_TradeSkillUI) == "table" and type(C_TradeSkillUI.GetRecipeInfo) == "function" and type(recipe.id) == "number" then
    local infoOK, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipe.id)
    if infoOK and type(info) == "table" then
      if type(info.name) == "string" and info.name ~= "" then recipe.name = info.name end
      recipe.icon = info.icon or info.iconID or recipe.icon
    end
  end

  -- Les noms persistés peuvent provenir d'une ancienne session dans une autre
  -- langue. Le sort local est l'autorité et reflète toujours la langue du
  -- client actuel ; cette lecture ne concerne que les lignes visibles.
  local localizedName, localizedIcon = catalogSpellInfo(recipe.id)
  if localizedName and localizedName ~= "" then recipe.name = localizedName end
  recipe.icon = recipe.icon or localizedIcon
  if recipe.staticEntry then
    recipe.staticEntry.name = recipe.name
    recipe.staticEntry.icon = recipe.icon
  end
  return recipe
end

function CA:GetProfessionCatalogStats(record, professionID)
  local total, known, seen = 0, 0, {}
  local savedRecipes = record and record.recipes or {}
  local hasReliableLearnedState = record and tonumber(record.catalogSyncVersion) == PROFESSION_CATALOG_SYNC_VERSION
  for _, recipe in ipairs(STATIC_PROFESSION_CATALOGS[professionID] or {}) do
    local key, saved = tostring(recipe.id), savedRecipes[tostring(recipe.id)]
    seen[key], total = true, total + 1
    if hasReliableLearnedState and saved and saved.learned == true then known = known + 1 end
  end
  for key, saved in pairs(savedRecipes) do
    if not seen[key] then
      total = total + 1
      if hasReliableLearnedState and saved.learned == true then known = known + 1 end
    end
  end
  return total, known
end

function CA:ReadRecipeSourceText(recipeID)
  if type(C_TradeSkillUI) ~= "table" or type(C_TradeSkillUI.GetRecipeSourceText) ~= "function" then return nil end
  local ok, source = pcall(C_TradeSkillUI.GetRecipeSourceText, recipeID)
  return ok and type(source) == "string" and source ~= "" and source or nil
end

function CA:CacheProfessionRecipeDetails(recipe, record)
  if not recipe or type(recipe.id) ~= "number" then return end
  local source = self:ReadRecipeSourceText(recipe.id)
  if source then recipe.source = source end
  local stored = record and type(record.recipes) == "table" and record.recipes[tostring(recipe.id)] or nil
  if source and stored then
    stored.source = source
    stored.sourceLocale = self.locale
  end
  if type(C_TradeSkillUI) ~= "table" or type(C_TradeSkillUI.GetRecipeSchematic) ~= "function" then
    if stored then self:PublishProfessionStorage(self:GetProfessionStorage()) end
    return
  end

  local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipe.id, false)
  if not ok or type(schematic) ~= "table" then
    if stored then self:PublishProfessionStorage(self:GetProfessionStorage()) end
    return
  end

  -- La fiche de schéma expose l'icône du résultat sur les clients Forever.
  -- On ne consulte que la recette sélectionnée : pas de parcours massif des
  -- schémas, donc aucune pause quand une profession est ouverte.
  local outputItemID = tonumber(schematic.outputItemID)
  local outputIcon = schematic.icon or schematic.outputItemIcon or itemIconFor(outputItemID)
  if outputIcon then
    recipe.icon = outputIcon
    if stored then stored.icon = outputIcon end
    if recipe.staticEntry then recipe.staticEntry.icon = outputIcon end
  end

  if type(schematic.reagentSlotSchematics) ~= "table" then return end
  local reagents = {}
  for _, slot in ipairs(schematic.reagentSlotSchematics) do
    local reagent = type(slot) == "table" and type(slot.reagents) == "table" and slot.reagents[1] or nil
    local itemID = type(reagent) == "table" and tonumber(reagent.itemID) or nil
    if itemID then
      table.insert(reagents, {
        itemID = itemID,
        count = tonumber(slot.quantityRequired) or tonumber(reagent.quantityRequired) or tonumber(reagent.quantity) or 1,
      })
    end
  end
  if #reagents > 0 then recipe.reagents = reagents end
  -- Seuls les détails de la recette sélectionnée sont mémorisés. Cela évite
  -- de scanner des centaines de schémas à l'ouverture d'une profession.
  if stored and #reagents > 0 then stored.reagents = reagents end
  if stored then self:PublishProfessionStorage(self:GetProfessionStorage()) end
end

local function nativeFrameIsVisible(frame)
  if not frame or type(frame.IsVisible) ~= "function" then return false end
  local ok, visible = pcall(frame.IsVisible, frame)
  return ok and visible and true or false
end

-- Forever mélange les anciens cadres Classic et les API plus récentes selon
-- la build. Centraliser la lecture évite qu'un seul indicateur absent bloque
-- tout le relevé. Les champs servent également au diagnostic /ca diag.
local function readNativeProfessionContext()
  local context = {
    lineAPI = type(GetTradeSkillLine) == "function",
    listAPI = type(GetNumTradeSkills) == "function" and type(GetTradeSkillInfo) == "function",
    tradeFrame = nativeFrameIsVisible(_G.TradeSkillFrame),
    craftFrame = nativeFrameIsVisible(_G.CraftFrame),
    entries = 0,
  }
  context.frameVisible = context.tradeFrame or context.craftFrame

  if type(IsTradeSkillLinked) == "function" then
    local ok, linked = pcall(IsTradeSkillLinked)
    context.linked = ok and linked and true or false
  end
  if type(C_TradeSkillUI) == "table" then
    if type(C_TradeSkillUI.IsTradeSkillLinked) == "function" then
      local ok, linked = pcall(C_TradeSkillUI.IsTradeSkillLinked)
      context.linked = context.linked or (ok and linked and true or false)
    end
    if type(C_TradeSkillUI.IsTradeSkillGuild) == "function" then
      local ok, guild = pcall(C_TradeSkillUI.IsTradeSkillGuild)
      context.guild = ok and guild and true or false
    end
  end

  if context.lineAPI then
    local ok, name, rank, maxRank = pcall(GetTradeSkillLine)
    if ok then
      context.name, context.rank, context.maxRank = name, rank, maxRank
    end
  end
  -- Certains cadres Forever renseignent le titre avant GetTradeSkillLine.
  -- C'est une donnée de l'interface Blizzard, pas une hypothèse sur le métier.
  if (type(context.name) ~= "string" or context.name == "") and _G.TradeSkillFrameTitleText and type(_G.TradeSkillFrameTitleText.GetText) == "function" then
    local ok, title = pcall(_G.TradeSkillFrameTitleText.GetText, _G.TradeSkillFrameTitleText)
    if ok and type(title) == "string" and title ~= "" then context.name = title end
  end
  if context.listAPI then
    local ok, count = pcall(GetNumTradeSkills)
    if ok and type(count) == "number" then context.entries = count end
  end
  context.professionID = professionIDFor(context.name)
  return context
end

local function nativeProfessionWindowIsUsable()
  local context = readNativeProfessionContext()
  return not context.linked and not context.guild
    and (context.professionID ~= nil or context.entries > 0 or context.frameVisible)
end

-- Repli autonome : les recettes sont des sorts du personnage. Quand Forever
-- n'expose pas sa liste de métier à un addon, IsSpellKnown reste l'API
-- Blizzard disponible pour déterminer les recettes que CE personnage connaît.
-- On ne l'emploie que sur le catalogue local du métier concerné (506 entrées
-- au plus), jamais pour deviner ou obtenir des recettes distantes.
local function isRecipeSpellKnown(recipeID)
  -- IsSpellKnown est présent sur les builds Classic. IsPlayerSpell est le
  -- repli fourni par certaines builds hybrides de Forever.
  if type(IsSpellKnown) == "function" then
    local ok, known = pcall(IsSpellKnown, recipeID)
    if ok and known then return true, "IsSpellKnown" end
  end
  if type(IsPlayerSpell) == "function" then
    local ok, known = pcall(IsPlayerSpell, recipeID)
    if ok and known then return true, "IsPlayerSpell" end
  end
  return false, nil
end

local function spellbookAPIIsAvailable()
  return type(IsSpellKnown) == "function" or type(IsPlayerSpell) == "function"
end

-- Une migration de méthode ne doit jamais conserver des « appris » posés par
-- un ancien relevé incomplet. Les données utiles (nom, icône, lien, sources)
-- restent, seul l'état appris est réinitialisé puis reconstruit par les API
-- Blizzard de la version courante.
local function resetStaleRecipeLearnedState(record)
  if tonumber(record.catalogSyncVersion) == PROFESSION_CATALOG_SYNC_VERSION then return end
  for _, recipe in pairs(record.recipes or {}) do
    recipe.learned = false
  end
  record.catalogSyncVersion = nil
end

local function recordKnownRecipesFromSpellbook(owner, record, professionID, scanInfo)
  if not spellbookAPIIsAvailable() then
    if scanInfo then scanInfo.spellbookAPI = false end
    return 0
  end
  if scanInfo then scanInfo.spellbookAPI = true end
  local known = 0
  for _, staticRecipe in ipairs(STATIC_PROFESSION_CATALOGS[professionID] or {}) do
    local isKnown = isRecipeSpellKnown(staticRecipe.id)
    if isKnown then
      local recipeName, icon = catalogSpellInfo(staticRecipe.id)
      if owner:RecordProfessionRecipe(record, staticRecipe.id, recipeName, icon, nil, true) then
        known = known + 1
      end
    end
  end
  if scanInfo then scanInfo.spellbook = known end
  return known
end

-- Cette lecture ne requiert pas la fenêtre de métier. Elle est donc le chemin
-- principal sur les builds Forever qui n'exposent pas GetTradeSkillLine aux
-- addons tiers alors que le personnage connaît bien le métier.
function CA:ScanKnownProfessionSpellbooks()
  local storage = self:ReadPlayerProfessions()
  local info = { professions = 0, known = 0, spellbookAPI = spellbookAPIIsAvailable() }
  for _, definition in ipairs(PROFESSION_DEFINITIONS) do
    local record = storage[definition.id]
    if record and record.learned and #(STATIC_PROFESSION_CATALOGS[definition.id] or {}) > 0 then
      info.professions = info.professions + 1
      record.recipes = record.recipes or {}
      resetStaleRecipeLearnedState(record)
      local perProfession = {}
      local known = recordKnownRecipesFromSpellbook(self, record, definition.id, perProfession)
      info.known = info.known + known
      if known > 0 then record.catalogSyncVersion = PROFESSION_CATALOG_SYNC_VERSION end
    end
  end
  self.lastProfessionSpellbookScanInfo = info
  self:PublishProfessionStorage(storage)
  if self.activeSection == "professions" then self:RefreshProfessions() end
  return info.known
end

function CA:QueueKnownProfessionSpellbookScan()
  if self.professionSpellbookScanQueued then return end
  self.professionSpellbookScanQueued = true
  local function scan()
    CA.professionSpellbookScanQueued = nil
    CA:ScanKnownProfessionSpellbooks()
  end
  if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
    C_Timer.After(.75, scan)
  else
    scan()
  end
end

function CA:ScanOpenProfession()
  local context = readNativeProfessionContext()
  local scanInfo = {
    entries = context.entries or 0, candidates = 0, resolved = 0, saved = 0, recipeIDs = 0,
    frame = context.frameVisible, lineAPI = context.lineAPI, listAPI = context.listAPI,
  }
  if context.linked or context.guild then
    scanInfo.reason = "métier lié ou de guilde"
    self.lastProfessionScanInfo = scanInfo
    return false
  end
  local recipeIDs = {}
  if type(C_TradeSkillUI) == "table" and type(C_TradeSkillUI.GetAllRecipeIDs) == "function" then
    local listOK, value = pcall(C_TradeSkillUI.GetAllRecipeIDs)
    if listOK and type(value) == "table" then recipeIDs = value end
  end
  scanInfo.recipeIDs = #recipeIDs

  local name, rank, maxRank = context.name, context.rank, context.maxRank
  -- Selon l'étape de chargement de la fenêtre Classic, GetTradeSkillLine peut
  -- être vide alors que les recettes sont déjà exposées. Les IDs du catalogue
  -- permettent alors d'identifier le métier, sans deviner ni charger de data.
  local professionID = context.professionID or professionFromRecipeIDs(recipeIDs)
  local storage = self:ReadPlayerProfessions()
  -- Lorsque la fenêtre Forever est visible mais ne publie ni ligne ni liste,
  -- le dernier métier ouvert / sélectionné est un contexte sûr : il doit être
  -- déjà appris par le personnage. Cela permet le repli IsSpellKnown sans
  -- attribuer des recettes à une profession arbitraire.
  if not professionID and (context.frameVisible or self.professionNativeWindowObserved) then
    local preferred = self.lastScannedProfessionID or self.selectedProfessionID
    if preferred and storage[preferred] and storage[preferred].learned then professionID = preferred end
    if not professionID then
      for _, definition in ipairs(PROFESSION_DEFINITIONS) do
        if storage[definition.id] and storage[definition.id].learned then
          professionID = definition.id
          break
        end
      end
    end
  end
  scanInfo.name, scanInfo.professionID = name, professionID
  if not professionID then
    scanInfo.spellbook = self:ScanKnownProfessionSpellbooks()
    scanInfo.spellbookAPI = spellbookAPIIsAvailable()
    scanInfo.reason = "métier non identifié"
    self.lastProfessionScanInfo = scanInfo
    return false
  end

  local definition, record = PROFESSION_BY_ID[professionID], storage[professionID] or {}
  if not definition then
    scanInfo.reason = "métier absent du catalogue"
    self.lastProfessionScanInfo = scanInfo
    return false
  end
  record.name = (type(name) == "string" and name ~= "" and name) or record.name or self:GetProfessionName(definition)
  record.icon = record.icon or definition.icon
  record.rank = tonumber(rank) or record.rank or 0
  record.maxRank = tonumber(maxRank) or record.maxRank or 0
  record.learned, record.recipes = true, record.recipes or {}
  resetStaleRecipeLearnedState(record)
  storage[professionID] = record

  local scanned, knownScanned = 0, 0
  if type(C_TradeSkillUI) == "table" and type(C_TradeSkillUI.GetRecipeInfo) == "function" then
    for _, recipeID in ipairs(recipeIDs) do
      local infoOK, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
      if infoOK and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
        local link
        if type(C_TradeSkillUI.GetRecipeLink) == "function" then
          local linkOK, value = pcall(C_TradeSkillUI.GetRecipeLink, recipeID)
          if linkOK then link = value end
        end
        -- Sur ce client Forever, les drapeaux modernes indiquent que la
        -- recette existe dans le catalogue, pas qu'elle est connue par le
        -- personnage. Ils ne sont donc jamais utilisés pour le comptage.
        local recipeLearned = false
        -- La provenance et les composants sont lus seulement pour la recette
        -- sélectionnée : parcourir ces détails pour des milliers d'entrées
        -- à l'ouverture du métier créerait une pause inutile.
        if self:RecordProfessionRecipe(record, recipeID, info.name, info.icon or info.iconID, link, recipeLearned) then
          scanned = scanned + 1
        end
      end
    end
  end

  -- La fenêtre native est l'autorité. Forever emploie aussi « used » et « none » pour
  -- des recettes connues ; les exclure laisse artificiellement le compteur à
  -- zéro. Les en-têtes restent exclus car ils n'ont aucun de ces types.
  if context.listAPI and context.entries > 0 then
    local knownRecipeTypes = { optimal = true, medium = true, easy = true, trivial = true, used = true, none = true }
    local recipeCount = context.entries
    if type(recipeCount) == "number" then
      for recipeIndex = 1, recipeCount do
        local infoOK, recipeName, recipeType = pcall(GetTradeSkillInfo, recipeIndex)
        if infoOK and knownRecipeTypes[recipeType] then
          scanInfo.candidates = scanInfo.candidates + 1
          local link, icon
          if type(GetTradeSkillRecipeLink) == "function" then
            local linkOK, value = pcall(GetTradeSkillRecipeLink, recipeIndex)
            if linkOK then link = value end
          end
          if type(GetTradeSkillIcon) == "function" then
            local iconOK, value = pcall(GetTradeSkillIcon, recipeIndex)
            if iconOK then icon = value end
          end
          local recipeID = type(link) == "string" and tonumber(link:match("|Hspell:(%d+)") or link:match("|Henchant:(%d+)") or link:match("|Htrade:(%d+)")) or nil
          recipeID = recipeID or cachedRecipeIDByName(record, professionID, recipeName)
          if recipeID then scanInfo.resolved = scanInfo.resolved + 1 end
          if self:RecordProfessionRecipe(record, recipeID, recipeName, icon, link, true) then
            scanned = scanned + 1
            knownScanned = knownScanned + 1
            scanInfo.saved = scanInfo.saved + 1
          end
        end
      end
    end
  end

  -- Complète le résultat de la liste native ou prend entièrement le relais
  -- lorsqu'elle n'est pas publiée par Forever. La même recette ne peut être
  -- comptée qu'une fois : RecordProfessionRecipe utilise l'ID du catalogue.
  knownScanned = knownScanned + recordKnownRecipesFromSpellbook(self, record, professionID, scanInfo)

  self.selectedProfessionID = professionID
  self.lastScannedProfessionID = professionID
  self.professionDetailRecipeKey = nil
  if knownScanned > 0 then record.catalogSyncVersion = PROFESSION_CATALOG_SYNC_VERSION end
  self:PublishProfessionStorage(storage)
  scanInfo.known, scanInfo.catalogVersion = knownScanned, record.catalogSyncVersion
  self.lastProfessionScanInfo = scanInfo
  if self.professionRecipeScroll then self.professionRecipeScroll:SetVerticalScroll(0) end
  if self.activeSection == "professions" then self:RefreshProfessions() end
  return knownScanned > 0
end

-- TRADE_SKILL_SHOW arrive parfois avant que le client ait rempli la liste.
-- Cette file laisse donc la fenêtre Blizzard se stabiliser, puis effectue un
-- seul repli si nécessaire.
function CA:QueueProfessionScan(isRetry)
  if self.professionScanQueued then return end
  self.professionScanQueued = true
  local function scan()
    CA.professionScanQueued = nil
    local didScan = CA:ScanOpenProfession()
    if not didScan and not isRetry and type(C_Timer) == "table" and type(C_Timer.After) == "function" then
      C_Timer.After(1.00, function() CA:QueueProfessionScan(true) end)
    end
  end
  if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
    C_Timer.After(.50, scan)
  else
    scan()
  end
end

-- Lorsqu'on ouvre Chroniques après la fenêtre de métier, certains clients
-- Forever n'envoient plus TRADE_SKILL_SHOW à notre frame. Cette vérification
-- autonome garantit une lecture unique de la fenêtre déjà visible.
function CA:EnsureVisibleProfessionScan()
  if not nativeProfessionWindowIsUsable() then
    self.professionNativeWindowObserved = nil
    return
  end
  if self.professionNativeWindowObserved then return end
  self.professionNativeWindowObserved = true
  self:QueueProfessionScan()
end

function CA:PrintProfessionScanDiagnostics()
  local info = self.lastProfessionScanInfo or {}
  local spellbookInfo = self.lastProfessionSpellbookScanInfo or {}
  print("|cffd6a33aChroniques métiers|r "
    .. "métier=" .. tostring(info.name or "?")
    .. " • entrées=" .. tostring(info.entries or 0)
    .. " • connues=" .. tostring(info.candidates or 0)
    .. " • IDs=" .. tostring(info.resolved or 0)
    .. " • mémorisées=" .. tostring(info.saved or 0)
    .. " • grimoire=" .. tostring(info.spellbook or spellbookInfo.known or 0)
    .. " • métiers=" .. tostring(spellbookInfo.professions or 0)
    .. " • sorts=" .. ((info.spellbookAPI or spellbookInfo.spellbookAPI) and "oui" or "non")
    .. " • cadre=" .. (info.frame and "oui" or "non")
    .. " • API=" .. ((info.lineAPI or info.listAPI) and "oui" or "non")
    .. (info.reason and (" • " .. info.reason) or ""))
end

local function panel(parent, width, height, r, g, b)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetSize(width, height)
  -- Texture native, répétée discrètement : aucun cadre illustré ou ornement
  -- généré n'est utilisé dans les panneaux de consultation.
  f:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  f:SetBackdropColor(r or .10, g or .065, b or .030, .96)
  f:SetBackdropBorderColor(.65, .42, .15, 1)
  return f
end

local function label(parent, text, size, color)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetFont(STANDARD_TEXT_FONT, size or 12, "")
  fs:SetTextColor(unpack(color or {1, .82, .35}))
  fs:SetText(text)
  return fs
end

-- Les illustrations sont livrées avec l'add-on. Le format TGA est utilisé
-- volontairement : il est pris en charge par le client Classic sans dépendre
-- de l'import PNG d'une version précise du jeu.
local ASSET_PATH = "Interface\\AddOns\\ChroniquesAzeroth\\Assets\\"
local QUEST_ROW_HEIGHT = 24
-- Vert de progression inspiré des barres du journal Blizzard : plus profond
-- et moins fluorescent que le vert de validation des quêtes terminées.
local PROGRESS_BAR_COLOR = { .16, .42, .07 }
local PROGRESS_TEXT_COLOR = { .30, .68, .14 }
local PROGRESS_RING_COLOR = { .25, .56, .10 }
local PROFESSION_RECIPE_ROW_HEIGHT = 24
-- Liste virtualisée : même un métier Forever très fourni reste fluide et ne
-- crée pas des centaines de boutons au chargement de l'addon.
local PROFESSION_RECIPE_VISIBLE_ROWS = 14
-- Une zone Classic dépasse rarement 300 quêtes ; cette réserve évite toute
-- reconstruction de panneaux et protège la liste si Forever ajoute de
-- nouvelles quêtes à une zone.
local MAX_QUEST_ROWS = 500

-- Phase 1 : répertoire visuel des métiers Classic et de leurs rangs. Les
-- patrons absents / leurs sources seront ajoutés avec le catalogue de phase 2.
PROFESSION_DEFINITIONS = {
  { id = 171, names = { frFR = "Alchimie", enUS = "Alchemy" }, icon = "Interface\\Icons\\Trade_Alchemy" },
  { id = 164, names = { frFR = "Forge", enUS = "Blacksmithing" }, icon = "Interface\\Icons\\Trade_BlackSmithing" },
  { id = 333, names = { frFR = "Enchantement", enUS = "Enchanting" }, icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings" },
  { id = 202, names = { frFR = "Ingénierie", enUS = "Engineering" }, icon = "Interface\\Icons\\Trade_Engineering" },
  { id = 182, names = { frFR = "Herboristerie", enUS = "Herbalism" }, icon = "Interface\\Icons\\Trade_Herbalism" },
  { id = 165, names = { frFR = "Travail du cuir", enUS = "Leatherworking" }, icon = "Interface\\Icons\\Trade_LeatherWorking" },
  { id = 186, names = { frFR = "Minage", enUS = "Mining" }, icon = "Interface\\Icons\\Trade_Mining" },
  { id = 393, names = { frFR = "Dépeçage", enUS = "Skinning" }, icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
  { id = 197, names = { frFR = "Couture", enUS = "Tailoring" }, icon = "Interface\\Icons\\Trade_Tailoring" },
  { id = 185, names = { frFR = "Cuisine", enUS = "Cooking" }, icon = "Interface\\Icons\\INV_Misc_Food_15" },
  { id = 356, names = { frFR = "Pêche", enUS = "Fishing" }, icon = "Interface\\Icons\\Trade_Fishing" },
  { id = 129, names = { frFR = "Secourisme", enUS = "First Aid" }, icon = "Interface\\Icons\\Spell_Holy_SealOfSalvation" },
}
PROFESSION_BY_ID, PROFESSION_NAME_TO_ID = {}, {
  ["Alchemy"] = 171, ["Alchimie"] = 171,
  ["Blacksmithing"] = 164, ["Forge"] = 164,
  ["Enchanting"] = 333, ["Enchantement"] = 333,
  ["Engineering"] = 202, ["Ingénierie"] = 202,
  ["Herbalism"] = 182, ["Herboristerie"] = 182,
  ["Leatherworking"] = 165, ["Travail du cuir"] = 165,
  ["Mining"] = 186, ["Minage"] = 186,
  ["Skinning"] = 393, ["Dépeçage"] = 393,
  ["Tailoring"] = 197, ["Couture"] = 197,
  ["Cooking"] = 185, ["Cuisine"] = 185,
  ["Fishing"] = 356, ["Pêche"] = 356,
  ["First Aid"] = 129, ["Premiers soins"] = 129, ["Secourisme"] = 129,
}
local GATHERING_PROFESSION_IDS = {
  [182] = true, -- Herboristerie
  [186] = true, -- Minage
  [393] = true, -- Dépeçage
  [356] = true, -- Pêche
}
for _, profession in ipairs(PROFESSION_DEFINITIONS) do PROFESSION_BY_ID[profession.id] = profession end

function CA:GetProfessionName(definition)
  return (definition and definition.names and definition.names[self.locale]) or (definition and definition.name) or ""
end

local function useQuestFont(fontString, size, isTitle)
  fontString:SetFont(isTitle and "Fonts\\MORPHEUS.TTF" or "Fonts\\FRIZQT__.TTF", size, "")
end

local function modeButton(parent, text, x, y, onClick)
  local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
  button:SetSize(105, 22); button:SetPoint("TOPLEFT", x, y)
  button:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  button.text = label(button, text, 10, {.8, .84, .9}); button.text:SetPoint("CENTER")
  button:SetScript("OnClick", onClick)
  return button
end

local function continentTab(parent, text, iconPath, x, width, onClick)
  local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
  tab:SetSize(width, 25); tab:SetPoint("TOPLEFT", x, -40)
  tab:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 9 })
  tab.icon = tab:CreateTexture(nil, "ARTWORK"); tab.icon:SetSize(16, 16); tab.icon:SetPoint("LEFT", 7, 0); tab.icon:SetTexture(iconPath)
  -- Les deux continents ont la même place ; le libellé reste dans son
  -- bouton, y compris pour « Royaumes de l’Est ».
  tab.text = label(tab, text, 6.5, {.62, .66, .70})
  tab.text:SetSize(width - 37, 20); tab.text:SetPoint("LEFT", tab.icon, "RIGHT", 4, 0)
  tab.text:SetJustifyH("LEFT"); tab.text:SetJustifyV("MIDDLE"); tab.text:SetWordWrap(false)
  tab:SetScript("OnClick", onClick)
  return tab
end

local function topTab(parent, text, iconPath, x, width, enabled, onClick)
  local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
  tab:SetSize(width, 29); tab:SetPoint("TOPLEFT", x, -57)
  tab:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  tab:SetBackdropColor(.045, .055, .07, 1)
  tab:SetBackdropBorderColor(.35, .38, .42, .65)
  tab.icon = tab:CreateTexture(nil, "ARTWORK"); tab.icon:SetSize(19, 19); tab.icon:SetPoint("LEFT", 9, 0); tab.icon:SetTexture(iconPath)
  tab.text = label(tab, text, enabled and 8.5 or 7.2, enabled and {.80, .84, .90} or {.52, .56, .60})
  tab.text:SetSize(width - 37, 24); tab.text:SetPoint("LEFT", tab.icon, "RIGHT", 5, 0)
  tab.text:SetJustifyH("LEFT"); tab.text:SetJustifyV("MIDDLE"); tab.text:SetWordWrap(false)
  tab.available = enabled and true or false
  if tab.available and onClick then tab:SetScript("OnClick", onClick) else tab:Disable() end
  return tab
end

function CA:RefreshNavigationTabs()
  for _, tab in ipairs(self.navigationTabs or {}) do
    local active = tab.section == self.activeSection
    tab:SetBackdropColor(active and .25 or .045, active and .15 or .055, active and .025 or .07, 1)
    tab:SetBackdropBorderColor(active and 1 or .35, active and .72 or .38, active and .16 or .42, active and 1 or .65)
    if active then
      tab.text:SetTextColor(1, .84, .32)
    elseif tab.available then
      tab.text:SetTextColor(.80, .84, .90)
    else
      tab.text:SetTextColor(.52, .56, .60)
    end
  end
end

function CA:SetActiveSection(section)
  if section ~= "quests" and section ~= "professions" and section ~= "feedback" then return end
  self.activeSection = section
  local questsVisible = section == "quests"
  local professionsVisible = section == "professions"
  local feedbackVisible = section == "feedback"
  for _, widget in ipairs(self.questPanels or {}) do
    if questsVisible then widget:Show() else widget:Hide() end
  end
  if self.professionView then
    if professionsVisible then self.professionView:Show() else self.professionView:Hide() end
  end
  if self.feedbackView then
    if feedbackVisible then self.feedbackView:Show() else self.feedbackView:Hide() end
  end
  if self.footer then
    self.footer:SetText(questsVisible
      and self:L("footerQuests")
      or (professionsVisible and self:L("footerProfessions") or self:L("footerFeedback")))
  end
  self:RefreshNavigationTabs()
  self:Refresh()
end

function CA:CreateProfessionUI(parent)
  local view = CreateFrame("Frame", nil, parent)
  view:SetSize(1050, 400); view:SetPoint("TOPLEFT", 25, -118)
  self.professionView = view

  local left = panel(view, 250, 400)
  left:SetPoint("TOPLEFT", 0, 0)
  local leftTitle = label(left, self:L("professions"), 16); leftTitle:SetPoint("TOPLEFT", 15, -14)
  local leftSubtitle = label(left, self:L("professionCatalogs"), 8, {.72, .78, .82}); leftSubtitle:SetPoint("TOPLEFT", 16, -35)
  self.professionRows = {}
  for index, definition in ipairs(PROFESSION_DEFINITIONS) do
    local row = CreateFrame("Button", nil, left, "BackdropTemplate")
    row:SetSize(220, 23); row:SetPoint("TOPLEFT", 15, -52 - ((index - 1) * 27))
    row:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 7 })
    local icon = row:CreateTexture(nil, "ARTWORK"); icon:SetSize(17, 17); icon:SetPoint("LEFT", 5, 0); icon:SetTexture(definition.icon)
    local name = label(row, self:GetProfessionName(definition), 9, {.80, .84, .90}); name:SetPoint("LEFT", icon, "RIGHT", 5, 0); name:SetWidth(125); name:SetJustifyH("LEFT")
    local rank = label(row, "—", 8, {.72, .78, .82}); rank:SetPoint("RIGHT", -6, 0)
    local professionID = definition.id
    row:SetScript("OnClick", function()
      self.selectedProfessionID = professionID
      self.selectedProfessionRecipeKey = nil
      self.professionDetailRecipeKey = nil
      if self.professionRecipeScroll then self.professionRecipeScroll:SetVerticalScroll(0) end
      self:RefreshProfessions()
    end)
    self.professionRows[index] = { button = row, icon = icon, name = name, rank = rank, definition = definition }
  end

  local center = panel(view, 470, 400)
  center:SetPoint("TOPLEFT", left, "TOPRIGHT", 15, 0)
  self.professionTitle = label(center, string.upper(self:L("professions")), 18); self.professionTitle:SetPoint("TOP", 0, -13)
  self.professionStatus = label(center, "", 10, {.72, .78, .82}); self.professionStatus:SetPoint("TOP", self.professionTitle, "BOTTOM", 0, -5)
  self.professionKnownTitle = label(center, self:L("recipeCatalog"), 11, {1, .82, .34}); self.professionKnownTitle:SetPoint("TOPLEFT", 18, -58)
  local scroll = CreateFrame("ScrollFrame", nil, center, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 18, -77); scroll:SetSize(435, 301)
  local child = CreateFrame("Frame", nil, scroll); child:SetSize(413, 301); scroll:SetScrollChild(child)
  self.professionRecipeScroll, self.professionRecipeChild = scroll, child
  self.professionRecipeRows = {}
  for index = 1, PROFESSION_RECIPE_VISIBLE_ROWS do
    local row = CreateFrame("Button", nil, child, "BackdropTemplate")
    row:SetSize(413, PROFESSION_RECIPE_ROW_HEIGHT); row:SetPoint("TOPLEFT", 0, -((index - 1) * PROFESSION_RECIPE_ROW_HEIGHT))
    row:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 6 })
    local icon = row:CreateTexture(nil, "ARTWORK"); icon:SetSize(17, 17); icon:SetPoint("LEFT", 4, 0)
    local name = label(row, "", 9, {.86, .86, .80}); name:SetPoint("LEFT", icon, "RIGHT", 6, 0); name:SetWidth(275); name:SetJustifyH("LEFT"); name:SetWordWrap(false)
    local known = label(row, "", 7, {.42, .82, .38}); known:SetPoint("RIGHT", -7, 0)
    row:SetScript("OnClick", function(button)
      if not button.recipe then return end
      self.selectedProfessionRecipeKey = button.recipe.key
      self.professionDetailRecipeKey = nil
      self:RefreshProfessions()
    end)
    row:SetScript("OnEnter", function(button)
      local recipe = button.recipe
      if not recipe then return end
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      if recipe.link then
        GameTooltip:SetHyperlink(recipe.link)
      elseif recipe.id and type(GameTooltip.SetSpellByID) == "function" then
        GameTooltip:SetSpellByID(recipe.id)
      else
        GameTooltip:AddLine(recipe.name, 1, .82, .34)
      end
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:Hide()
    self.professionRecipeRows[index] = { button = row, icon = icon, name = name, known = known }
  end
  scroll:SetScript("OnVerticalScroll", function(frame, offset)
    frame:SetVerticalScroll(offset)
    self:RenderProfessionRecipeRows()
  end)
  self.professionRecipeSummary = label(center, "", 8, {.72, .78, .82}); self.professionRecipeSummary:SetPoint("BOTTOM", 0, 12)

  local right = panel(view, 285, 400)
  right:SetPoint("TOPLEFT", center, "TOPRIGHT", 15, 0)
  local detailTitle = label(right, self:L("recipeDetail"), 14); detailTitle:SetPoint("TOP", 0, -15)
  local detailIcon = right:CreateTexture(nil, "ARTWORK"); detailIcon:SetSize(38, 38); detailIcon:SetPoint("TOPLEFT", 16, -47)
  local detailName = label(right, "", 12, {1, .82, .34}); detailName:SetPoint("TOPLEFT", detailIcon, "TOPRIGHT", 9, -1); detailName:SetWidth(210); detailName:SetJustifyH("LEFT"); detailName:SetWordWrap(true)
  local detailState = label(right, "", 8, {.72, .78, .82}); detailState:SetPoint("TOPLEFT", detailName, "BOTTOMLEFT", 0, -4); detailState:SetWidth(210); detailState:SetJustifyH("LEFT")
  local componentsTitle = label(right, self:L("components"), 10, {1, .82, .34}); componentsTitle:SetPoint("TOPLEFT", 16, -105)
  local componentsBox = CreateFrame("Frame", nil, right, "BackdropTemplate"); componentsBox:SetSize(253, 108); componentsBox:SetPoint("TOPLEFT", 16, -121)
  componentsBox:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 7 })
  componentsBox:SetBackdropColor(.018, .025, .025, .78); componentsBox:SetBackdropBorderColor(.35, .25, .10, .65)
  self.professionComponentRows = {}
  for index = 1, 4 do
    local row = CreateFrame("Frame", nil, componentsBox)
    row:SetSize(241, 22); row:SetPoint("TOPLEFT", 6, -4 - ((index - 1) * 24))
    local icon = row:CreateTexture(nil, "ARTWORK"); icon:SetSize(18, 18); icon:SetPoint("LEFT", 1, 0)
    local name = label(row, "", 8, {.84, .84, .77}); name:SetPoint("LEFT", icon, "RIGHT", 5, 0); name:SetWidth(172); name:SetJustifyH("LEFT"); name:SetWordWrap(false)
    local count = label(row, "", 8, {1, .78, .28}); count:SetPoint("RIGHT", -2, 0)
    row:Hide()
    self.professionComponentRows[index] = { frame = row, icon = icon, name = name, count = count }
  end
  local componentHint = label(componentsBox, "", 8, {.66, .70, .72}); componentHint:SetPoint("CENTER", 0, 0); componentHint:SetWidth(225); componentHint:SetJustifyH("CENTER"); componentHint:SetWordWrap(true)
  self.professionComponentHint = componentHint
  local sourceTitle = label(right, self:L("obtainRecipe"), 10, {1, .82, .34}); sourceTitle:SetPoint("TOPLEFT", 16, -244)
  local sourceBox = CreateFrame("Frame", nil, right, "BackdropTemplate"); sourceBox:SetSize(253, 100); sourceBox:SetPoint("TOPLEFT", 16, -260)
  sourceBox:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 7 })
  sourceBox:SetBackdropColor(.018, .025, .025, .78); sourceBox:SetBackdropBorderColor(.35, .25, .10, .65)
  local sourceText = label(sourceBox, "", 8, {.82, .80, .70}); sourceText:SetPoint("TOPLEFT", 8, -8); sourceText:SetWidth(237); sourceText:SetJustifyH("LEFT"); sourceText:SetJustifyV("TOP"); sourceText:SetWordWrap(true)
  self.professionDetailIcon, self.professionDetailName = detailIcon, detailName
  self.professionDetailState, self.professionSourceText = detailState, sourceText
  view:Hide()
end

function CA:RenderProfessionRecipeRows()
  local recipes = self.professionRecipeData or {}
  local offset = self.professionRecipeScroll and self.professionRecipeScroll:GetVerticalScroll() or 0
  local firstIndex = math.max(1, math.floor(offset / PROFESSION_RECIPE_ROW_HEIGHT) + 1)
  for visibleIndex, row in ipairs(self.professionRecipeRows or {}) do
    local recipeIndex = firstIndex + visibleIndex - 1
    local recipe = recipes[recipeIndex]
    if recipe then
      self:HydrateProfessionRecipe(recipe)
      row.button.recipe = recipe
      row.button:ClearAllPoints()
      row.button:SetPoint("TOPLEFT", 0, -((recipeIndex - 1) * PROFESSION_RECIPE_ROW_HEIGHT))
      row.icon:SetTexture(recipe.icon or "Interface/Icons/INV_Misc_QuestionMark")
      row.name:SetText(shortText(recipe.name, 39))
      local learned = recipe.learned == true
      local level = tonumber(recipe.requiredSkill) or 0
      -- La police Classic de Forever ne possède pas toujours le glyphe de
      -- validation :
      -- elle le rendait sous forme d'un rectangle à côté du niveau.
      row.known:SetText(level > 0 and (self:L("level") .. " " .. level) or (learned and self:L("known") or self:L("obtain")))
      row.known:SetTextColor(learned and .42 or 1, learned and .82 or .68, learned and .38 or .22)
      local selected = recipe.key == self.selectedProfessionRecipeKey
      if selected then
        row.button:SetBackdropColor(.10, .28, .34, .94)
        row.button:SetBackdropBorderColor(.20, .62, .90, .9)
        row.name:SetTextColor(.92, .94, .88)
      elseif learned then
        -- Vert sombre volontairement discret : les recettes maîtrisées se
        -- repèrent instantanément, sans confondre leur fond avec la sélection.
        row.button:SetBackdropColor(.025, .105, .040, .94)
        row.button:SetBackdropBorderColor(.12, .42, .16, .72)
        row.name:SetTextColor(.50, .91, .54)
      else
        row.button:SetBackdropColor(.02, .035, .045, .94)
        row.button:SetBackdropBorderColor(.16, .22, .22, .35)
        row.name:SetTextColor(.86, .86, .80)
      end
      row.button:Show()
    else
      row.button.recipe = nil
      row.button:Hide()
    end
  end
end

function CA:RefreshProfessionDetails(recipe)
  self:HydrateProfessionRecipe(recipe)
  local hasRecipe = recipe ~= nil
  self.professionDetailIcon:SetTexture(hasRecipe and (recipe.icon or "Interface/Icons/INV_Misc_QuestionMark") or "Interface/Icons/INV_Misc_QuestionMark")
  self.professionDetailName:SetText(hasRecipe and recipe.name or self:L("selectRecipe"))
  if not hasRecipe then
    self.professionDetailState:SetText(self:L("detailWillAppear"))
  elseif recipe.learned == true then
    local owner = self:GetTrackingMode() == "account" and self:L("accountOwner") or self:L("characterOwner")
    self.professionDetailState:SetText((tonumber(recipe.requiredSkill) or 0) > 0 and (self:L("learnedRecipe") .. " - " .. self:L("skill") .. " " .. recipe.requiredSkill) or (self:L("learnedRecipe") .. " " .. owner))
    self.professionDetailState:SetTextColor(.42, .82, .38)
  else
    self.professionDetailState:SetText((tonumber(recipe.requiredSkill) or 0) > 0 and (self:L("learnRecipe") .. " - " .. self:L("skill") .. " " .. recipe.requiredSkill) or self:L("learnRecipe"))
    self.professionDetailState:SetTextColor(1, .68, .22)
  end

  local reagents = hasRecipe and recipe.reagents or nil
  for index, row in ipairs(self.professionComponentRows or {}) do
    local reagent = reagents and reagents[index]
    if reagent then
      if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(reagent.itemID) end
      local itemName, itemIcon = itemNameFor(reagent.itemID), itemIconFor(reagent.itemID)
      row.icon:SetTexture(itemIcon or "Interface/Icons/INV_Misc_QuestionMark")
      row.name:SetText(itemName or self:L("itemFallback", reagent.itemID))
      row.count:SetText("x" .. (tonumber(reagent.count) or 1))
      row.frame:Show()
    else
      row.frame:Hide()
    end
  end
  if reagents and #reagents > 0 then
    local extra = #reagents - #self.professionComponentRows
    self.professionComponentHint:SetText(extra > 0 and ("+ " .. extra .. " " .. self:L("components")) or "")
  elseif hasRecipe then
    self.professionComponentHint:SetText(self:L("openProfessionComponents"))
  else
    self.professionComponentHint:SetText(self:L("componentsWillAppear"))
  end

  if not hasRecipe then
    self.professionSourceText:SetText(self:L("sourceWillAppear"))
  elseif type(recipe.source) == "string" and recipe.source ~= "" then
    self.professionSourceText:SetText(recipe.source)
  elseif recipe.learned == true then
    self.professionSourceText:SetText(self:GetTrackingMode() == "account" and self:L("learnedAccount") or self:L("learnedCharacter"))
  else
    self.professionSourceText:SetText(self:L("sourceClientUnavailable"))
  end
end

function CA:RefreshProfessions()
  if not self.professionView then return end
  self:EnsureVisibleProfessionScan()
  local characterStorage = self:ReadPlayerProfessions()
  local accountMode = self:GetTrackingMode() == "account"
  local storage = accountMode and self:GetAccountProfessionStorage() or characterStorage
  if not self.selectedProfessionID then
    for _, definition in ipairs(PROFESSION_DEFINITIONS) do
      if storage[definition.id] and storage[definition.id].learned then
        self.selectedProfessionID = definition.id
        break
      end
    end
    for _, definition in ipairs(PROFESSION_DEFINITIONS) do
      if not self.selectedProfessionID and #(STATIC_PROFESSION_CATALOGS[definition.id] or {}) > 0 then
        self.selectedProfessionID = definition.id
        break
      end
    end
    self.selectedProfessionID = self.selectedProfessionID or PROFESSION_DEFINITIONS[1].id
  end

  for _, row in ipairs(self.professionRows or {}) do
    local definition, record = row.definition, storage[row.definition.id]
    local learned = record and record.learned
    local selected = definition.id == self.selectedProfessionID
    row.icon:SetTexture((record and record.icon) or definition.icon)
    row.name:SetText(self:GetProfessionName(definition))
    local catalogTotal, catalogKnown = self:GetProfessionCatalogStats(record, definition.id)
    if GATHERING_PROFESSION_IDS[definition.id] then
      -- Ces métiers n'ont pas de catalogue de recettes : afficher leur rang
      -- ici le ferait passer pour un faux compteur de patrons connus.
      row.rank:SetText("")
      row.name:SetTextColor(selected and 1 or (learned and .84 or .52), selected and .84 or (learned and .86 or .56), selected and .32 or (learned and .70 or .60))
    elseif learned then
      local rank, maximum = tonumber(record.rank) or 0, tonumber(record.maxRank) or 0
      row.rank:SetText(catalogTotal > 0 and (catalogKnown .. " / " .. catalogTotal) or (maximum > 0 and (rank .. " / " .. maximum) or tostring(rank)))
      row.name:SetTextColor(selected and 1 or .84, selected and .84 or .86, selected and .32 or .70)
      row.rank:SetTextColor(.42, .82, .38)
    elseif catalogTotal > 0 then
      row.rank:SetText("0 / " .. catalogTotal)
      row.name:SetTextColor(selected and .88 or .52, selected and .76 or .56, selected and .38 or .60)
      row.rank:SetTextColor(.66, .62, .46)
    else
      row.rank:SetText("—")
      row.name:SetTextColor(selected and .88 or .52, selected and .76 or .56, selected and .38 or .60)
      row.rank:SetTextColor(.52, .56, .60)
    end
    row.button:SetBackdropColor(selected and .16 or .025, selected and .09 or .035, selected and .015 or .05, .98)
    row.button:SetBackdropBorderColor(selected and .84 or .28, selected and .58 or .32, selected and .16 or .38, selected and 1 or .55)
  end

  local definition = PROFESSION_BY_ID[self.selectedProfessionID] or PROFESSION_DEFINITIONS[1]
  local record = storage[definition.id]
  local learned = record and record.learned
  local recipes = self:GetProfessionRecipes(record, definition.id)
  self.professionTitle:SetText(self:GetProfessionName(definition))
  if learned then
    local rank, maximum = tonumber(record.rank) or 0, tonumber(record.maxRank) or 0
    local rankText = maximum > 0 and (rank .. " / " .. maximum) or tostring(rank)
    if accountMode then
      local characterCount = tonumber(record.characterCount) or 1
      self.professionStatus:SetText(self:L("listedOnCharacters", characterCount, characterCount > 1 and "s" or "", rankText))
    else
      self.professionStatus:SetText(self:L("currentRank", rankText))
    end
    self.professionStatus:SetTextColor(.42, .82, .38)
  elseif #recipes > 0 then
    self.professionStatus:SetText(accountMode
      and self:L("catalogNotLearnedAccount")
      or self:L("catalogNotLearnedCharacter"))
    self.professionStatus:SetTextColor(.78, .76, .67)
  else
    self.professionStatus:SetText(self:L("professionNotLearned"))
    self.professionStatus:SetTextColor(.78, .76, .67)
  end
  local knownCount = 0
  for _, recipe in ipairs(recipes) do if recipe.learned == true then knownCount = knownCount + 1 end end
  self.professionKnownTitle:SetText(self:L("recipeCatalogSummary", #recipes, knownCount))

  local selectedRecipe
  for _, recipe in ipairs(recipes) do
    if recipe.key == self.selectedProfessionRecipeKey then selectedRecipe = recipe; break end
  end
  if not selectedRecipe and recipes[1] then
    selectedRecipe = recipes[1]
    self.selectedProfessionRecipeKey = selectedRecipe.key
  end
  self:HydrateProfessionRecipe(selectedRecipe)
  if selectedRecipe and self.professionDetailRecipeKey ~= selectedRecipe.key then
    -- Les détails lus dans le client restent rattachés au personnage connecté,
    -- même si le panneau affiche l'union du compte.
    self:CacheProfessionRecipeDetails(selectedRecipe, characterStorage[definition.id])
    self.professionDetailRecipeKey = selectedRecipe.key
  end
  self.professionRecipeData = recipes
  self.professionRecipeChild:SetHeight(math.max(301, #recipes * PROFESSION_RECIPE_ROW_HEIGHT))
  self:RenderProfessionRecipeRows()
  self.professionRecipeSummary:SetText(#recipes > 0 and self:L("recipesListed", #recipes) or self:L("noRecipeListed"))
  self:RefreshProfessionDetails(selectedRecipe)
end

-- Bouton autour de la minicarte. Il est volontairement séparé du médaillon
-- décoratif de la fenêtre : l'un sert de raccourci permanent, l'autre reste
-- seulement l'emblème de l'interface Chroniques.
function CA:PlaceMinimapButton(angle)
  local button = self.minimapButton
  if not button or not Minimap then return end
  angle = tonumber(angle) or 225
  local radians = math.rad(angle)
  local radius = (Minimap:GetWidth() or 140) / 2 + 9
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radius, math.sin(radians) * radius)
end

local function minimapAngleFromOffset(offsetY, offsetX)
  if math.atan2 then return math.atan2(offsetY, offsetX) end
  -- Repli pour les clients Lua qui n'exposent que math.atan(y). Cette
  -- conversion conserve le bon quadrant lorsque le bouton passe à gauche de
  -- la minicarte.
  if offsetX > 0 then return math.atan(offsetY / offsetX) end
  if offsetX < 0 and offsetY >= 0 then return math.atan(offsetY / offsetX) + math.pi end
  if offsetX < 0 then return math.atan(offsetY / offsetX) - math.pi end
  return offsetY >= 0 and math.pi / 2 or -math.pi / 2
end

function CA:UpdateMinimapButtonPosition()
  if not Minimap or not self.minimapButton then return end
  local scale = Minimap:GetEffectiveScale()
  local cursorX, cursorY = GetCursorPosition()
  local centerX = Minimap:GetLeft() + Minimap:GetWidth() / 2
  local centerY = Minimap:GetBottom() + Minimap:GetHeight() / 2
  local offsetX = cursorX / scale - centerX
  local offsetY = cursorY / scale - centerY
  local radians = minimapAngleFromOffset(offsetY, offsetX)
  local angle = math.deg(radians)
  ChroniquesAzerothDB.minimapAngle = angle
  self:PlaceMinimapButton(angle)
end

function CA:CreateMinimapButton()
  if self.minimapButton or not Minimap then return end
  local button = CreateFrame("Button", "ChroniquesAzerothMinimapButton", Minimap)
  button:SetSize(32, 32)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints()
  icon:SetTexture(ASSET_PATH .. "heritage-medallion.tga")
  button.icon = icon
  local highlight = button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  highlight:SetBlendMode("ADD")
  highlight:SetAllPoints()

  button:SetScript("OnEnter", function(widget)
    GameTooltip:SetOwner(widget, "ANCHOR_LEFT")
    GameTooltip:SetText(CA:L("addonTitle"), 1, .82, .28)
    GameTooltip:AddLine(CA:L("minimapOpen"), .85, .85, .85)
    GameTooltip:AddLine(CA:L("minimapToggle"), .85, .85, .85)
    GameTooltip:AddLine(CA:L("minimapDrag"), .60, .70, .85)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  button:SetScript("OnDragStart", function(widget)
    widget.dragging = true
    widget:SetScript("OnUpdate", function() CA:UpdateMinimapButtonPosition() end)
  end)
  button:SetScript("OnDragStop", function(widget)
    widget.dragging = nil
    widget.dragged = true
    widget:SetScript("OnUpdate", nil)
  end)
  button:SetScript("OnClick", function(widget, mouseButton)
    if widget.dragged then
      widget.dragged = nil
      return
    end
    if mouseButton == "RightButton" then
      local mode = CA:GetTrackingMode() == "account" and "character" or "account"
      CA:SetTrackingMode(mode)
      print("|cffd6a33aChroniques|r: " .. CA:L("trackingChanged", mode == "account" and CA:L("account") or CA:L("character")))
      return
    end
    CA.frame:SetShown(not CA.frame:IsShown())
    CA:Refresh()
  end)

  self.minimapButton = button
  self:PlaceMinimapButton(ChroniquesAzerothDB and ChroniquesAzerothDB.minimapAngle)
end

function CA:BuildFeedbackReport()
  local zone = self:GetSelectedZone()
  local profession = PROFESSION_BY_ID[self.selectedProfessionID or 0]
  local mode = self:GetTrackingMode() == "account" and self:L("account") or self:L("character")
  return table.concat({
    self:L("addonTitle") .. " - " .. self:L("feedback"),
    self:L("reportVersion") .. ": " .. self.VERSION,
    self:L("reportLocale") .. ": " .. tostring(GetLocale and GetLocale() or self.locale),
    self:L("reportCharacter") .. ": " .. tostring(UnitName("player") or "?"),
    self:L("reportRealm") .. ": " .. tostring(GetRealmName and GetRealmName() or "?"),
    self:L("reportSection") .. ": " .. tostring(self.activeSection or "quests"),
    self:L("reportTracking") .. ": " .. mode,
    self:L("reportZone") .. ": " .. self:GetZoneName(zone),
    self:L("reportProfession") .. ": " .. (profession and self:GetProfessionName(profession) or "-"),
    "",
    self:L("reportProblem") .. ":",
    "",
    self:L("reportSteps") .. ":",
    "",
    self:L("reportExpected") .. ":",
    "",
    self:L("reportActual") .. ":",
  }, "\n")
end

function CA:PrepareFeedbackReport()
  local report = self:BuildFeedbackReport()
  if ChroniquesAzerothCharacterDB then ChroniquesAzerothCharacterDB.feedbackDraft = report end
  if self.feedbackReportEdit then
    self.feedbackReportEdit:SetText(report)
    self.feedbackReportEdit:SetFocus()
    self.feedbackReportEdit:HighlightText()
  end
end

function CA:RefreshFeedback()
  if self.feedbackCopyHint then self.feedbackCopyHint:SetText(self:L("feedbackCopyHint")) end
end

function CA:CreateFeedbackUI(parent)
  local view = CreateFrame("Frame", nil, parent)
  view:SetSize(1050, 400); view:SetPoint("TOPLEFT", 25, -118)
  self.feedbackView = view

  local content = panel(view, 1050, 400)
  content:SetPoint("TOPLEFT", 0, 0)
  local title = label(content, self:L("feedbackTitle"), 18); title:SetPoint("TOP", 0, -18)
  local description = label(content, self:L("feedbackDescription"), 10, {.78, .80, .76})
  description:SetPoint("TOPLEFT", 28, -54); description:SetWidth(994); description:SetJustifyH("LEFT"); description:SetWordWrap(true)

  local prepare = CreateFrame("Button", nil, content, "BackdropTemplate")
  prepare:SetSize(230, 28); prepare:SetPoint("TOPLEFT", 28, -93)
  prepare:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  prepare:SetBackdropColor(.21, .13, .025, 1); prepare:SetBackdropBorderColor(.86, .62, .12, .95)
  prepare.text = label(prepare, self:L("prepareReport"), 10, {1, .84, .32}); prepare.text:SetPoint("CENTER")
  prepare:SetScript("OnEnter", function(button) button:SetBackdropColor(.33, .20, .035, 1) end)
  prepare:SetScript("OnLeave", function(button) button:SetBackdropColor(.21, .13, .025, 1) end)
  prepare:SetScript("OnClick", function() self:PrepareFeedbackReport() end)

  local hint = label(content, self:L("feedbackCopyHint"), 9, {.68, .76, .84}); hint:SetPoint("LEFT", prepare, "RIGHT", 16, 0); hint:SetWidth(700); hint:SetJustifyH("LEFT")
  self.feedbackCopyHint = hint

  local edit = CreateFrame("EditBox", nil, content, "BackdropTemplate")
  edit:SetPoint("TOPLEFT", 28, -134); edit:SetSize(994, 200)
  edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFont(STANDARD_TEXT_FONT, 10, "")
  edit:SetTextColor(.92, .89, .76); edit:SetTextInsets(10, 10, 8, 8); edit:SetJustifyH("LEFT"); edit:SetJustifyV("TOP")
  edit:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  edit:SetBackdropColor(.01, .014, .018, .90); edit:SetBackdropBorderColor(.40, .29, .12, .85)
  edit:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  edit:SetScript("OnTextChanged", function(box, userInput)
    if userInput and ChroniquesAzerothCharacterDB then ChroniquesAzerothCharacterDB.feedbackDraft = box:GetText() end
  end)
  self.feedbackReportEdit = edit

  local destination = label(content, self:L("feedbackDestination"), 10, {.88, .72, .32})
  destination:SetPoint("TOPLEFT", 28, -348); destination:SetWidth(994); destination:SetJustifyH("LEFT"); destination:SetWordWrap(true)
  view:Hide()
end

function CA:CreateUI()
  local f = panel(UIParent, 1100, 565)
  f:SetPoint("CENTER")
  f:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", edgeSize = 22, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
  f:SetBackdropColor(.075, .042, .020, .98); f:SetBackdropBorderColor(.70, .48, .16, 1)
  -- Fenêtre de consultation non modale, mais placée au-dessus des panneaux
  -- ordinaires d'autres addons. DIALOG reste sous les vraies infobulles WoW.
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetScript("OnShow", function(frame) frame:Raise() end)
  f:SetScript("OnMouseDown", function(frame) frame:Raise() end)
  f:Hide(); self.frame = f

  -- En-tête inspiré de la fenêtre Héritage : bande sombre, filet doré et
  -- médaillon rond sans encadré carré.
  local header = CreateFrame("Frame", nil, f, "BackdropTemplate")
  header:SetPoint("TOPLEFT", 22, -7); header:SetPoint("TOPRIGHT", -22, -7); header:SetHeight(32)
  header:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  header:SetBackdropColor(.17, .09, .035, 1); header:SetBackdropBorderColor(.64, .42, .14, 1)
  -- Le cartouche large nuisait au titre sur certains clients beta : le
  -- médaillon reste, mais l'en-tête décoratif ne recouvre plus le texte.
  header:Hide()
  -- Le médaillon étoilé est la signature de Chroniques. Son anneau intégré
  -- conserve le contour métallique, avec seulement un léger chevauchement du
  -- coin supérieur gauche du cadre.
  local medal = f:CreateTexture(nil, "OVERLAY")
  medal:SetTexture(ASSET_PATH .. "heritage-medallion.tga"); medal:SetSize(64, 64)
  medal:SetPoint("TOPLEFT", f, "TOPLEFT", -10, 5)
  local title = label(f, self:L("addonTitle"), 20)
  title:SetPoint("TOP", 0, -10)
  local subtitle = label(f, self:L("subtitle"), 12, {.7, .75, .8})
  subtitle:SetPoint("TOP", title, "BOTTOM", 0, -3)
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -5, -5)

  local tabDefs = {
    { key = "quests", text = self:L("quests"), icon = "Interface\\Icons\\INV_Misc_Note_01", enabled = true },
    { key = "professions", text = self:L("professions"), icon = "Interface\\Icons\\INV_Hammer_20", enabled = true },
    { key = "toys", text = self:L("toysSoon"), icon = "Interface\\Icons\\INV_Misc_Toy_10" },
    { key = "dungeons", text = self:L("dungeonsSoon"), icon = "Interface\\Icons\\INV_Misc_Bone_01" },
    { key = "raids", text = self:L("raidsSoon"), icon = "Interface\\Icons\\INV_Misc_Head_Human_02" },
    { key = "feedback", text = self:L("feedback"), icon = "Interface\\Icons\\INV_Misc_Note_06", enabled = true },
  }
  self.navigationTabs = {}
  for index, tabDef in ipairs(tabDefs) do
    local section = tabDef.key
    local tab = topTab(f, tabDef.text, tabDef.icon, 108 + (index - 1) * 144, 136, tabDef.enabled, function() self:SetActiveSection(section) end)
    tab.section = section
    self.navigationTabs[index] = tab
  end
  local tabDivider = f:CreateTexture(nil, "BORDER"); tabDivider:SetTexture("Interface/Buttons/WHITE8X8"); tabDivider:SetSize(955, 2); tabDivider:SetPoint("TOP", 0, -88); tabDivider:SetVertexColor(.58, .40, .12, .8)

  -- Barre de contexte commune à tous les onglets. Les anciens filtres de
  -- contenu (extension, continents et niveaux) n'apportaient plus d'action :
  -- seule la faction connectée est pertinente ici.
  local contextDivider = f:CreateTexture(nil, "BORDER")
  contextDivider:SetTexture("Interface/Buttons/WHITE8X8"); contextDivider:SetSize(955, 1)
  contextDivider:SetPoint("TOP", 0, -115); contextDivider:SetVertexColor(.42, .29, .10, .65)
  -- Deux groupes sur la même ligne de base : le texte et les icônes ne
  -- semblent plus monter ou descendre selon leur police / texture.
  local factionGroup = CreateFrame("Frame", nil, f); factionGroup:SetSize(265, 24); factionGroup:SetPoint("TOPLEFT", 28, -90)
  local factionPrefix = label(factionGroup, self:L("faction"), 10, {.72, .84, .95}); factionPrefix:SetSize(60, 22); factionPrefix:SetPoint("LEFT", 0, 0); factionPrefix:SetJustifyH("LEFT"); factionPrefix:SetJustifyV("MIDDLE")
  local factionIcon = factionGroup:CreateTexture(nil, "ARTWORK"); factionIcon:SetSize(18, 18); factionIcon:SetPoint("LEFT", factionPrefix, "RIGHT", 3, 0)
  factionIcon:SetTexCoord(.08, .92, .08, .92)
  local factionName = label(factionGroup, "", 11, {.94, .84, .42}); factionName:SetSize(130, 22); factionName:SetPoint("LEFT", factionIcon, "RIGHT", 3, 0); factionName:SetJustifyH("LEFT"); factionName:SetJustifyV("MIDDLE")
  self.factionPrefix, self.factionIcon, self.factionName = factionPrefix, factionIcon, factionName
  local trackingGroup = CreateFrame("Frame", nil, f); trackingGroup:SetSize(315, 24); trackingGroup:SetPoint("TOPRIGHT", -28, -90)
  local tracking = label(trackingGroup, self:L("tracking"), 10, {.72, .84, .95}); tracking:SetSize(76, 22); tracking:SetPoint("LEFT", 0, 0); tracking:SetJustifyV("MIDDLE")
  self.tracking = tracking
  self.accountButton = modeButton(trackingGroup, self:L("account"), 80, -1, function() self:SetTrackingMode("account") end)
  self.characterButton = modeButton(trackingGroup, self:L("character"), 190, -1, function() self:SetTrackingMode("character") end)

  local left = panel(f, 245, 400); left:SetPoint("TOPLEFT", 25, -118)
  left:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  left:SetBackdropColor(.12, .070, .028, .97); left:SetBackdropBorderColor(.66, .43, .15, 1)
  local lh = label(left, self:L("zones"), 16); lh:SetPoint("TOPLEFT", 15, -14)
  self.activeContinent = self.activeContinent or "east"
  self.continentTabs = {
    east = continentTab(left, self:L("easternKingdoms"), "Interface\\Icons\\Achievement_Zone_EasternKingdoms_01", 12, 110, function() self:SetActiveContinent("east") end),
    kalimdor = continentTab(left, self:L("kalimdor"), "Interface\\Icons\\Achievement_Zone_Kalimdor_01", 123, 110, function() self:SetActiveContinent("kalimdor") end),
  }
  local zoneSearch = CreateFrame("Frame", nil, left, "BackdropTemplate"); zoneSearch:SetSize(221, 23); zoneSearch:SetPoint("TOPLEFT", 12, -72)
  zoneSearch:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 8 })
  zoneSearch:SetBackdropColor(.01, .015, .02, .92); zoneSearch:SetBackdropBorderColor(.42, .32, .16, .9)
  local zoneSearchIcon = zoneSearch:CreateTexture(nil, "ARTWORK"); zoneSearchIcon:SetTexture("Interface/Common/UI-Searchbox-Icon"); zoneSearchIcon:SetSize(15, 15); zoneSearchIcon:SetPoint("LEFT", 6, 0)
  local zoneSearchText = label(zoneSearch, self:L("searchZone"), 8, {.54, .54, .50}); zoneSearchText:SetPoint("LEFT", zoneSearchIcon, "RIGHT", 4, 0)
  local zoneSearchEdit = CreateFrame("EditBox", nil, zoneSearch)
  zoneSearchEdit:SetPoint("TOPLEFT", 2, 1); zoneSearchEdit:SetPoint("BOTTOMRIGHT", -2, -1)
  zoneSearchEdit:SetFont(STANDARD_TEXT_FONT, 9, "")
  zoneSearchEdit:SetTextColor(.9, .86, .72); zoneSearchEdit:SetTextInsets(25, 5, 0, 0)
  zoneSearchEdit:SetAutoFocus(false)
  zoneSearchEdit:SetScript("OnEscapePressed", function(edit) edit:ClearFocus() end)
  zoneSearchEdit:SetScript("OnTextChanged", function(edit)
    self.zoneSearchQuery = edit:GetText() or ""
    zoneSearchText:SetShown(self.zoneSearchQuery == "")
    if self.zoneRows then
      local first = self:GetFirstVisibleZone()
      if first then self.selectedZoneKey = first.key end
      self:RefreshZoneList(true)
      self:Refresh()
    end
  end)
  self.zoneSearchEdit = zoneSearchEdit
  self.selectedZoneKey = self.selectedZoneKey or self.zones[1].key
  local zoneScroll = CreateFrame("ScrollFrame", nil, left, "UIPanelScrollFrameTemplate")
  zoneScroll:SetPoint("TOPLEFT", 12, -102); zoneScroll:SetSize(221, 285)
  local zoneScrollChild = CreateFrame("Frame", nil, zoneScroll); zoneScrollChild:SetSize(201, math.max(285, #self.zones * 76))
  zoneScroll:SetScrollChild(zoneScrollChild)
  self.zoneScroll, self.zoneScrollChild = zoneScroll, zoneScrollChild
  if zoneScroll.ScrollBar then
    -- Même ancrage que les cadres Blizzard : les boutons restent dans la
    -- colonne de droite, et non plus superposés au début de la liste.
    local buttonHeight = zoneScroll.ScrollBar.ScrollUpButton and zoneScroll.ScrollBar.ScrollUpButton:GetHeight() or 16
    zoneScroll.ScrollBar:ClearAllPoints()
    zoneScroll.ScrollBar:SetPoint("TOPLEFT", zoneScroll, "TOPRIGHT", -16, -buttonHeight - 1)
    zoneScroll.ScrollBar:SetPoint("BOTTOMLEFT", zoneScroll, "BOTTOMRIGHT", -16, buttonHeight + 1)
    zoneScroll.ScrollBar:SetWidth(16)
  end
  self.zoneRows = {}
  for i, zone in ipairs(self.zones) do
    local row = CreateFrame("Button", nil, zoneScrollChild, "BackdropTemplate")
    row:SetSize(201, 70); row:SetPoint("TOPLEFT", 0, -(i - 1) * 76)
    local rowBackground = ASSET_PATH .. (zone.cardArt or "zone-elwynn.tga")
    -- La zone est une vraie vignette pleine largeur. Seul son titre repose
    -- sur un cartouche sombre afin de rester lisible sur toutes les images.
    row:SetBackdrop({ bgFile = rowBackground, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 11, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    row:SetBackdropColor(1, 1, 1, 1); row:SetBackdropBorderColor(.50, .35, .11, .9)
    local artShade = row:CreateTexture(nil, "BORDER"); artShade:SetAllPoints(); artShade:SetTexture("Interface/ChatFrame/ChatFrameBackground"); artShade:SetVertexColor(.01, .01, .005, .16)
    local caption = CreateFrame("Frame", nil, row, "BackdropTemplate")
    caption:SetPoint("BOTTOMLEFT", 5, 5); caption:SetPoint("BOTTOMRIGHT", -5, 5); caption:SetHeight(22)
    caption:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground" }); caption:SetBackdropColor(.005, .008, .010, .82)
    local name = label(caption, self:GetZoneName(zone), 10, {1, .86, .45}); name:SetPoint("LEFT", 7, 0); name:SetWidth(130); name:SetJustifyH("LEFT"); name:SetWordWrap(false)
    local count = label(caption, "", 9, {.96, .88, .55}); count:SetPoint("RIGHT", -7, 0)
    -- Le cadre reste entièrement dans la carte : il ne peut donc pas être
    -- coupé par le ScrollFrame sur la première ou la dernière ligne.
    local selected = CreateFrame("Frame", nil, row, "BackdropTemplate")
    selected:SetAllPoints()
    selected:SetFrameLevel(row:GetFrameLevel() + 3)
    selected:SetBackdrop({ edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14 })
    selected:SetBackdropBorderColor(1, .65, .06, 1)
    -- Le motif Blizzard assure les coins ; les quatre traits internes rendent
    -- la sélection lisible sans jamais dépasser de la carte dans le défilement.
    local selectedTop = selected:CreateTexture(nil, "OVERLAY"); selectedTop:SetColorTexture(1, .72, .08, 1); selectedTop:SetPoint("TOPLEFT", 2, -2); selectedTop:SetPoint("TOPRIGHT", -2, -2); selectedTop:SetHeight(2)
    local selectedBottom = selected:CreateTexture(nil, "OVERLAY"); selectedBottom:SetColorTexture(1, .72, .08, 1); selectedBottom:SetPoint("BOTTOMLEFT", 2, 2); selectedBottom:SetPoint("BOTTOMRIGHT", -2, 2); selectedBottom:SetHeight(2)
    local selectedLeft = selected:CreateTexture(nil, "OVERLAY"); selectedLeft:SetColorTexture(1, .72, .08, 1); selectedLeft:SetPoint("TOPLEFT", 2, -2); selectedLeft:SetPoint("BOTTOMLEFT", 2, 2); selectedLeft:SetWidth(2)
    local selectedRight = selected:CreateTexture(nil, "OVERLAY"); selectedRight:SetColorTexture(1, .72, .08, 1); selectedRight:SetPoint("TOPRIGHT", -2, -2); selectedRight:SetPoint("BOTTOMRIGHT", -2, 2); selectedRight:SetWidth(2)
    selected:Hide()
    local zoneKey = zone.key
    row:SetScript("OnClick", function() self.selectedZoneKey = zoneKey; self:Refresh() end)
    self.zoneRows[i] = { name = name, count = count, selected = selected, button = row }
  end

  local center = panel(f, 405, 400); center:SetPoint("TOPLEFT", left, "TOPRIGHT", 15, 0)
  local zoneName = label(center, self:GetZoneName(self.zones[1]), 20); zoneName:SetPoint("TOP", 0, -15); self.zoneName = zoneName
  local map = CreateFrame("Frame", nil, center, "BackdropTemplate"); map:SetSize(368, 126); map:SetPoint("TOP", 0, -45)
  map:SetBackdrop({ bgFile = ASSET_PATH .. "zone-elwynn.tga", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 13, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  map:SetBackdropColor(1, 1, 1, 1); map:SetBackdropBorderColor(.78, .58, .20, 1)
  local mapShade = map:CreateTexture(nil, "BORDER")
  mapShade:SetAllPoints(); mapShade:SetTexture("Interface/ChatFrame/ChatFrameBackground"); mapShade:SetVertexColor(.01, .02, .01, .16)
  local mapText = label(map, string.upper(self:GetZoneName(self.zones[1])), 12, {1, .86, .45}); mapText:SetPoint("TOPLEFT", 13, -12)
  local realm = label(map, self:GetContinentName("east") .. " - " .. self:GetFactionName("Alliance"), 9, {.92, .88, .74}); realm:SetPoint("TOPLEFT", 13, -31); self.realm = realm
  local count = label(map, "", 10, {.96, .93, .82}); count:SetPoint("BOTTOMLEFT", 14, 17); self.count = count
  -- Le compteur ne possède volontairement aucun fond ou bord carré : seuls
  -- le pourcentage et sa couronne circulaire restent visibles sur l'illustration.
  local orb = CreateFrame("Frame", nil, map); orb:SetSize(90, 90); orb:SetPoint("TOPRIGHT", -11, -17)
  self.progress = label(orb, "", 22, PROGRESS_TEXT_COLOR); self.progress:SetPoint("CENTER", 0, 5)
  local orbCaption = label(orb, self:L("completed"), 7, {.8, .86, .76}); orbCaption:SetPoint("TOP", self.progress, "BOTTOM", 0, -1)
  self.progressRing = {}
  for segmentIndex = 1, 28 do
    local segment = orb:CreateTexture(nil, "ARTWORK")
    local angle = math.rad((segmentIndex - 1) * (360 / 28) - 90)
    segment:SetTexture("Interface/Buttons/WHITE8X8")
    segment:SetSize(4, 9); segment:SetPoint("CENTER", orb, "CENTER", math.cos(angle) * 39, math.sin(angle) * 39)
    if segment.SetRotation then segment:SetRotation(angle) end
    self.progressRing[segmentIndex] = segment
  end
  self.mapText = mapText
  self.mapHero = map
  local rewardHeader = panel(center, 368, 27); rewardHeader:SetPoint("TOPLEFT", 18, -180)
  rewardHeader:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  rewardHeader:SetBackdropColor(.13, .075, .028, 1); rewardHeader:SetBackdropBorderColor(.62, .40, .12, 1)
  local bh = label(rewardHeader, self:L("rewards"), 16, {1, .82, .34}); bh:SetPoint("CENTER", 0, 1); useQuestFont(bh, 17, true)
  local detail = panel(center, 368, 180); detail:SetPoint("TOPLEFT", 18, -209)
  detail:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 13, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  detail:SetBackdropColor(.12, .070, .028, 1); detail:SetBackdropBorderColor(.62, .40, .12, 1)
  self.rewardDetail = detail
  self.detailTitle = label(detail, "", 15, {1, .82, .34}); self.detailTitle:SetPoint("TOPLEFT", 11, -9); self.detailTitle:SetWidth(346); self.detailTitle:SetJustifyH("LEFT"); useQuestFont(self.detailTitle, 16, true)
  self.detailStatus = label(detail, "", 10, {.85, .79, .62}); self.detailStatus:SetPoint("TOPLEFT", 11, -33); self.detailStatus:SetWidth(346); self.detailStatus:SetJustifyH("LEFT"); useQuestFont(self.detailStatus, 10)
  self.detailChain = label(detail, "", 9, {.78, .78, .73}); self.detailChain:SetPoint("TOPLEFT", 11, -52); self.detailChain:SetWidth(346); self.detailChain:SetJustifyH("LEFT"); useQuestFont(self.detailChain, 9)
  self.detailRewards = label(detail, "", 10, {1, .82, .34}); self.detailRewards:SetPoint("TOPLEFT", 11, -83); self.detailRewards:SetWidth(346); self.detailRewards:SetJustifyH("LEFT"); useQuestFont(self.detailRewards, 10)
  self.rewardButtons = {}
  for i = 1, 6 do
    local reward = CreateFrame("Button", nil, detail, "BackdropTemplate")
    reward:SetSize(46, 46); reward:SetPoint("TOPLEFT", 11 + (i - 1) * 56, -109)
    reward:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 7 })
    reward.icon = reward:CreateTexture(nil, "ARTWORK"); reward.icon:SetPoint("TOPLEFT", 3, -3); reward.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    reward.count = label(reward, "", 8, {1, 1, 1}); reward.count:SetPoint("BOTTOMRIGHT", -2, 1)
    reward:SetScript("OnEnter", function(button)
      if type(button.itemID) ~= "number" then return end
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(button.itemID)
      GameTooltip:Show()
    end)
    reward:SetScript("OnLeave", function() GameTooltip:Hide() end)
    reward:Hide(); self.rewardButtons[i] = reward
  end
  self.badgeTexts = {}

  local right = panel(f, 380, 400); right:SetPoint("TOPLEFT", center, "TOPRIGHT", 15, 0)
  right:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  right:SetBackdropColor(.16, .095, .040, .97); right:SetBackdropBorderColor(.66, .43, .15, 1)
  local rh = label(right, self:GetZoneQuestTitle(self.zones[1]), 15); rh:SetPoint("TOP", 0, -15); self.questTitle = rh
  local scroll = CreateFrame("ScrollFrame", nil, right, "UIPanelScrollFrameTemplate")
  -- Le contenu remplit maintenant la largeur utile du panneau. L'ascenseur
  -- reste dans sa propre gouttière, sans réduire inutilement les lignes.
  scroll:SetPoint("TOPLEFT", 10, -45); scroll:SetSize(360, 331)
  local maxQuestRows = MAX_QUEST_ROWS
  for _, zone in ipairs(self.zones) do maxQuestRows = math.max(maxQuestRows, #zone.quests) end
  local scrollChild = CreateFrame("Frame", nil, scroll); scrollChild:SetSize(338, maxQuestRows * QUEST_ROW_HEIGHT)
  scroll:SetScrollChild(scrollChild)
  if scroll.ScrollBar then
    local buttonHeight = scroll.ScrollBar.ScrollUpButton and scroll.ScrollBar.ScrollUpButton:GetHeight() or 16
    scroll.ScrollBar:ClearAllPoints()
    scroll.ScrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", -16, -buttonHeight - 1)
    scroll.ScrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", -16, buttonHeight + 1)
    scroll.ScrollBar:SetWidth(16)
  end
  self.questScrollChild = scrollChild
  self.questRows = {}
  for i = 1, maxQuestRows do
    local questID = self.zones[1].quests[i] and self.zones[1].quests[i].id
    local button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
    button:SetSize(338, QUEST_ROW_HEIGHT); button:SetPoint("TOPLEFT", 0, -((i - 1) * QUEST_ROW_HEIGHT))
    button:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 7 })
    button:SetBackdropColor(.10, .18, .28, 0)
    button.questID = questID
    button:SetScript("OnClick", function(clicked) self.selectedQuestID = clicked.questID; self:Refresh() end)
    -- Les contrôles reprennent les textures +/- natives du journal Blizzard.
    local toggle = CreateFrame("Button", nil, button)
    toggle:SetSize(22, 22); toggle:SetPoint("LEFT", 3, 0)
    toggle:RegisterForClicks("LeftButtonUp")
    toggle.icon = toggle:CreateTexture(nil, "ARTWORK"); toggle.icon:SetAllPoints(); toggle.icon:SetTexture("Interface/Buttons/UI-PlusButton-UP")
    toggle:Hide()
    local branch = button:CreateTexture(nil, "BORDER")
    branch:SetTexture("Interface/Buttons/WHITE8X8"); branch:SetSize(2, 19); branch:SetPoint("LEFT", 6, 0); branch:Hide()
    local state = label(button, "", 10, {.82, .86, .9}); state:SetWidth(20); state:SetJustifyH("CENTER")
    state:SetPoint("LEFT", 5, 0)
    local name = label(button, "", 10, {.82, .86, .9}); name:SetWidth(174); name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    name:SetPoint("LEFT", 30, 0)
    local level = label(button, "", 7, {.72, .78, .84}); level:SetWidth(50); level:SetJustifyH("RIGHT")
    level:SetPoint("LEFT", 208, 0)
    local xp = label(button, "", 7, {.66, .72, .8}); xp:SetWidth(50); xp:SetJustifyH("RIGHT")
    xp:SetPoint("LEFT", 263, 0)
    local check = button:CreateTexture(nil, "ARTWORK"); check:SetSize(15, 15); check:SetPoint("RIGHT", -5, 0); check:SetTexture("Interface/RaidFrame/ReadyCheck-Ready"); check:Hide()
    self.questRows[i] = { button = button, toggle = toggle, state = state, name = name, level = level, xp = xp, check = check, branch = branch }
  end
  self.questSummary = label(right, "", 10, {.66, .72, .8}); self.questSummary:SetPoint("BOTTOM", 0, 12)
  local footer = label(f, self:L("footerQuests"), 10, {.66, .72, .8}); footer:SetPoint("BOTTOM", 0, 12)
  self.footer = footer
  -- La barre de contexte reste visible dans les Métiers et les futurs onglets.
  self.questPanels = { left, center, right }
  self:CreateProfessionUI(f)
  self:CreateFeedbackUI(f)
  self.activeSection = self.activeSection or "quests"
  self:SetActiveSection(self.activeSection)
end

function CA:Refresh()
  if not self.frame then return end
  self:RefreshNavigationTabs()
  local faction = self:GetPlayerFaction()
  if self.factionName then
    self.factionName:SetText(self:GetFactionName(faction))
  end
  if self.factionIcon then
    self.factionIcon:SetTexture(FACTION_ICON_TEXTURES[faction] or "Interface/Icons/INV_Misc_QuestionMark")
  end
  local mode = self:GetTrackingMode()
  -- Le sélecteur est commun aux Quêtes et aux Métiers : le peindre avant le
  -- retour anticipé de l'onglet Métiers évite l'ancien état visuel figé.
  self.accountButton:SetBackdropColor(mode == "account" and .12 or .035, mode == "account" and .38 or .055, mode == "account" and .18 or .09, 1)
  self.accountButton:SetBackdropBorderColor(mode == "account" and .25 or .45, mode == "account" and .9 or .45, mode == "account" and .35 or .45, 1)
  self.characterButton:SetBackdropColor(mode == "character" and .12 or .035, mode == "character" and .38 or .055, mode == "character" and .18 or .09, 1)
  self.characterButton:SetBackdropBorderColor(mode == "character" and .25 or .45, mode == "character" and .9 or .45, mode == "character" and .35 or .45, 1)
  if self.activeSection == "professions" then
    self:RefreshProfessions()
    return
  end
  if self.activeSection == "feedback" then
    self:RefreshFeedback()
    return
  end
  if self.continentTabs then
    for key, tab in pairs(self.continentTabs) do
      local active = self.activeContinent == key
      tab:SetBackdropColor(active and .27 or .035, active and .16 or .045, active and .025 or .06, 1)
      tab:SetBackdropBorderColor(active and 1 or .38, active and .70 or .34, active and .10 or .18, active and 1 or .75)
      tab.text:SetTextColor(active and 1 or .62, active and .84 or .66, active and .28 or .70)
    end
  end
  local currentZone = self:GetSelectedZone()
  if not self:IsZoneVisible(currentZone) then
    local firstVisible = self:GetFirstVisibleZone()
    if firstVisible then self.selectedZoneKey = firstVisible.key end
  end
  self:RefreshZoneList(false)
  for i, zone in ipairs(self.zones) do
    local zoneDone, zoneTotal = self:ZoneProgress(zone)
    self.zoneRows[i].name:SetText(shortText(self:GetZoneName(zone), 22))
    self.zoneRows[i].count:SetText(zoneDone .. " / " .. zoneTotal)
    self.zoneRows[i].button:SetBackdropBorderColor(self.selectedZoneKey == zone.key and .95 or .68, self.selectedZoneKey == zone.key and .72 or .47, self.selectedZoneKey == zone.key and .24 or .15, 1)
    self.zoneRows[i].selected:SetShown(self.selectedZoneKey == zone.key)
  end

  local zone = self:GetSelectedZone()
  local done, total, pct = self:ZoneProgress(zone)
  self.zoneName:SetText(self:GetZoneName(zone))
  self.progress:SetText(pct .. "%")
  self.count:SetText(self:L("questCount", done, total, mode == "account" and self:L("account") or self:L("character")))
  self.mapText:SetText(string.upper(self:GetZoneName(zone)))
  self.realm:SetText(self:GetContinentName(zone.continentKey) .. " - " .. self:GetFactionName(zone.faction))
  self.questTitle:SetText(self:GetZoneQuestTitle(zone))
  local heroArt = zone.heroArt or "zone-elwynn.tga"
  if self.displayedHeroArt ~= heroArt then
    self.mapHero:SetBackdrop({ bgFile = ASSET_PATH .. heroArt, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 13, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    self.mapHero:SetBackdropColor(1, 1, 1, 1); self.mapHero:SetBackdropBorderColor(.78, .58, .20, 1)
    self.displayedHeroArt = heroArt
  end
  for ringIndex, segment in ipairs(self.progressRing or {}) do
    if ringIndex <= math.floor((pct / 100) * #self.progressRing + .5) then
      segment:SetVertexColor(unpack(PROGRESS_RING_COLOR))
    else
      segment:SetVertexColor(.16, .18, .15, .95)
    end
  end

  local availableQuests = self:GetAccessibleZoneQuests(zone)
  -- Certaines zones Classic (par exemple le Défilé de Deuillevent) n'ont
  -- réellement aucune quête extérieure dans les données Forever. Le panneau
  -- l'indique sans faire croire qu'un addon externe doit être activé.
  if #availableQuests == 0 then
    for _, row in ipairs(self.questRows) do
      row.state:Hide(); row.name:Hide(); row.level:Hide(); row.xp:Hide(); row.check:Hide(); row.button:Hide(); row.toggle:Hide(); row.branch:Hide()
    end
    self.questScrollChild:SetHeight(331)
    self.questSummary:SetText(self:L("noZoneQuests"))
    self.detailTitle:SetText(self:L("noQuestListed"))
    self.detailStatus:SetText(self:L("noZoneQuestDetail"))
    self.detailStatus:SetTextColor(.85, .79, .62)
    self.detailChain:SetText(self:L("prerequisites") .. ": —\n" .. self:L("next") .. ": —")
    self.detailRewards:SetText(self:L("rewardsWhenSelected"))
    self.rewardDetail:SetHeight(116)
    for _, button in ipairs(self.rewardButtons) do button.itemID = nil; button:Hide() end
    return
  end

  local selectedID, selectedQuest = self.selectedQuestID, nil
  for _, quest in ipairs(availableQuests) do
    if quest.id == selectedID then selectedQuest = quest; break end
  end
  if not selectedQuest then selectedQuest = availableQuests[1]; selectedID = selectedQuest.id end
  self.selectedQuestID = selectedID

  local tree = self:BuildQuestDisplay(zone)
  local requiredRemaining, visibleRow = total - done, 0
  for j, treeEntry in ipairs(tree) do
    -- Le plafond est volontairement large (500). Cette garde reste une
    -- sécurité supplémentaire si une future base contient une zone anormale.
    local row = self.questRows[j]
    if not row then break end
    local quest
    for _, candidate in ipairs(availableQuests) do if candidate.id == treeEntry.id then quest = candidate; break end end
    local complete = self:IsQuestCompleted(quest.id)
    local hideOptionalForCharacter = mode == "character" and quest.optional
      and not self:IsQuestCompletedForCharacter(quest.id)
      and self:IsQuestCompletedForAccount(quest.id)
    row.state:SetShown(not hideOptionalForCharacter)
    row.name:SetShown(not hideOptionalForCharacter)
    row.level:SetShown(not hideOptionalForCharacter)
    row.xp:SetShown(not hideOptionalForCharacter)
    row.check:Hide()
    row.button:SetShown(not hideOptionalForCharacter)
    row.toggle:SetShown(not hideOptionalForCharacter and treeEntry.group)
    row.branch:SetShown(not hideOptionalForCharacter and treeEntry.child and not treeEntry.group)
    if not hideOptionalForCharacter then
      row.button:ClearAllPoints(); row.button:SetPoint("TOPLEFT", 0, -(visibleRow * QUEST_ROW_HEIGHT))
      row.button.questID = quest.id
      row.toggle:ClearAllPoints(); row.toggle:SetPoint("LEFT", 3, 0)
      row.state:ClearAllPoints(); row.state:SetPoint("LEFT", 5, 0)
      row.name:ClearAllPoints(); row.name:SetPoint("LEFT", 30, 0); row.name:SetWidth(174)
      row.level:ClearAllPoints(); row.level:SetPoint("LEFT", 208, 0)
      row.xp:ClearAllPoints(); row.xp:SetPoint("LEFT", 263, 0)
      visibleRow = visibleRow + 1
      local meta = self:GetQuestMeta(quest.id)
      local questLevel, xp = meta and meta[1] or "?", meta and meta[3]
      local isGroup = treeEntry.group
      local displayName = shortText(self:QuestName(quest.id), isGroup and 24 or 26)
      if quest.id == selectedID then
        row.button:SetBackdropColor(.10, .31, .42, .96); row.button:SetBackdropBorderColor(.30, .62, .76, 1)
      elseif isGroup then
        row.button:SetBackdropColor(.16, .085, .018, .98); row.button:SetBackdropBorderColor(.62, .40, .12, 1)
      elseif treeEntry.child then
        row.button:SetBackdropColor(.015, .040, .055, .92); row.button:SetBackdropBorderColor(.15, .21, .21, .42)
      else
        row.button:SetBackdropColor(.035, .055, .070, .78); row.button:SetBackdropBorderColor(.15, .21, .21, .22)
      end
      if treeEntry.child and not isGroup then row.branch:SetVertexColor(.65, .48, .14, .9) end
      if isGroup then
        row.toggle.icon:SetTexture(treeEntry.expanded and "Interface/Buttons/UI-MinusButton-UP" or "Interface/Buttons/UI-PlusButton-UP")
        row.toggle.questID = quest.id
        row.toggle:SetScript("OnClick", function(toggle)
          self.expandedGroups[toggle.questID] = not self.expandedGroups[toggle.questID]
          self:Refresh()
        end)
      end
      local inLog = self:IsQuestInLog(quest.id)
      if isGroup then
        local firstLevel = treeEntry.groupMinLevel or questLevel
        local lastLevel = treeEntry.groupMaxLevel or questLevel
        row.state:Hide()
        row.name:SetText(displayName)
        row.level:SetText(firstLevel == lastLevel and (self:L("level") .. " " .. firstLevel) or (self:L("level") .. " " .. firstLevel .. "-" .. lastLevel))
        row.xp:SetText((treeEntry.groupDone or 0) .. " / " .. (treeEntry.groupTotal or 1))
        if treeEntry.groupDone == treeEntry.groupTotal then
          row.name:SetTextColor(.35, 1, .45); row.level:SetTextColor(.35, 1, .45); row.xp:SetTextColor(.35, 1, .45)
        else
          row.name:SetTextColor(1, .82, .35); row.level:SetTextColor(.88, .74, .34); row.xp:SetTextColor(.88, .74, .34)
        end
      elseif inLog then
        row.state:SetText(">"); row.name:SetText(displayName); row.level:SetText(self:L("level") .. " " .. questLevel); row.xp:SetText(xp and ("XP " .. xp) or "—")
        row.state:SetTextColor(1, .82, .2); row.name:SetTextColor(1, .82, .2)
        row.level:SetTextColor(.86, .76, .38); row.xp:SetTextColor(.86, .76, .38)
      elseif complete then
        row.state:SetText(""); row.name:SetText(displayName); row.level:SetText(self:L("level") .. " " .. questLevel); row.xp:SetText(xp and ("XP " .. xp) or "—")
        row.name:SetTextColor(.35, 1, .45); row.level:SetTextColor(.66, .88, .68); row.xp:SetTextColor(.66, .88, .68); row.check:Show()
      elseif quest.optional then
        row.state:SetText("~"); row.name:SetText(displayName .. " (" .. self:L("optional") .. ")"); row.level:SetText(self:L("level") .. " " .. questLevel); row.xp:SetText(xp and ("XP " .. xp) or "—")
        row.state:SetTextColor(.62, .75, .9); row.name:SetTextColor(.62, .75, .9)
        row.level:SetTextColor(.62, .75, .9); row.xp:SetTextColor(.62, .75, .9)
      else
        local r, g, b = self:GetQuestDifficultyColor(quest.id)
        row.state:SetText("•"); row.name:SetText(displayName); row.level:SetText(self:L("level") .. " " .. questLevel); row.xp:SetText(xp and ("XP " .. xp) or "—")
        row.state:SetTextColor(r, g, b); row.name:SetTextColor(r, g, b)
        row.level:SetTextColor(.72, .78, .84); row.xp:SetTextColor(.72, .78, .84)
      end
    end
  end
  for j = #tree + 1, #self.questRows do
    local row = self.questRows[j]
    row.state:Hide(); row.name:Hide(); row.level:Hide(); row.xp:Hide(); row.check:Hide(); row.button:Hide(); row.toggle:Hide(); row.branch:Hide()
  end
  self.questScrollChild:SetHeight(math.max(331, visibleRow * QUEST_ROW_HEIGHT))
  self.questSummary:SetText(self:L("questsRequired", done, total, requiredRemaining))

  local meta = self:GetQuestMeta(selectedID) or {}
  local inLog = self:IsQuestInLog(selectedID)
  local link = self:GetQuestLinks(selectedID)
  self.detailTitle:SetText(self:QuestName(selectedID))
  self.detailStatus:SetText((inLog and self:L("questInProgress") or (self:IsQuestCompleted(selectedID) and self:L("questCompleted") or self:L("questDiscover"))) .. " - " .. self:L("level") .. " " .. (meta[1] or "?") .. " (" .. self:L("required") .. " " .. (meta[2] or "?") .. ")")
  if inLog then
    self.detailStatus:SetTextColor(1, .82, .2)
  elseif self:IsQuestCompleted(selectedID) then
    self.detailStatus:SetTextColor(.35, 1, .45)
  else
    self.detailStatus:SetTextColor(.85, .79, .62)
  end
  self.detailChain:SetText(self:L("prerequisites") .. ": " .. self:LinkNames(link.previous) .. "\n" .. self:L("next") .. ": " .. self:LinkNames(link.next))
  local rewardItems = self:GetQuestRewardItems(selectedID)
  self.rewardDetail:SetHeight(#rewardItems > 0 and 164 or 116)
  local itemCount = #rewardItems
  self.detailRewards:SetText(self:GetRewardSummary(selectedID) .. (itemCount > 0 and (" - " .. itemCount .. " " .. (itemCount == 1 and self:L("object") or self:L("objects")) .. ", " .. self:L("hoverIcons")) or ""))
  for index, button in ipairs(self.rewardButtons) do
    local item = rewardItems[index]
    if item then
      local amount = tonumber(item.amount) or 1
      button.itemID = type(item.itemID) == "number" and item.itemID or nil
      if button.itemID and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(button.itemID) end
      local icon = item.texture
        or (button.itemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(button.itemID))
        or (button.itemID and GetItemIcon and GetItemIcon(button.itemID))
      button.icon:SetTexture(icon or "Interface/Icons/INV_Misc_QuestionMark")
      button.count:SetText(amount > 1 and amount or "")
      button:SetBackdropBorderColor(item.choice and 1 or .65, item.choice and .25 or .55, item.choice and .15 or .25, 1)
      button:Show()
    else
      button.itemID = nil; button:Hide()
    end
  end
end

SLASH_CHRONIQUESAZEROTH1 = "/chroniques"
SLASH_CHRONIQUESAZEROTH2 = "/ca"
SlashCmdList.CHRONIQUESAZEROTH = function(message)
  message = string.lower(tostring(message or "")):gsub("^%s+", ""):gsub("%s+$", "")
  if message == "diag" or message == "scan" then
    CA:ScanKnownProfessionSpellbooks()
    CA:ScanOpenProfession()
    CA:PrintProfessionScanDiagnostics()
    return
  end
  CA.frame:SetShown(not CA.frame:IsShown()); CA:Refresh()
end

CA:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    ChroniquesAzerothDB = ChroniquesAzerothDB or { completed = {}, accepted = {}, trackingMode = "account" }
    ChroniquesAzerothDB.trackingMode = ChroniquesAzerothDB.trackingMode or "account"
    ChroniquesAzerothCharacterDB = ChroniquesAzerothCharacterDB or { completed = {}, accepted = {} }
    -- Migration non destructive : l'ancien état compte ne pouvait pas indiquer
    -- quel personnage avait terminé chaque quête.
    if ChroniquesAzerothDB.schemaVersion ~= 2 then
      ChroniquesAzerothDB.legacyCompleted = ChroniquesAzerothDB.completed or {}
      ChroniquesAzerothDB.characters = ChroniquesAzerothDB.characters or {}
      ChroniquesAzerothDB.schemaVersion = 2
    end
    CA:SyncCurrentCharacter()
    CA:CreateUI(); CA:CreateMinimapButton(); CA:InitializeQuestCatalog(); CA:Refresh()
    -- Le grimoire est disponible sans ouvrir une fenêtre de métier. Le léger
    -- délai laisse au client finir de restaurer les sorts du personnage après
    -- /reload ou connexion.
    CA:QueueKnownProfessionSpellbookScan()
    print("|cffd6a33a" .. CA:L("addonTitle") .. "|r " .. CA:L("addonLoaded") .. " |cff66ff66/chroniques|r.")
  elseif event == "QUEST_TURNED_IN" then
    local questID = ...
    CA:RecordQuest(questID, "completed")
    print("|cff66ff66Chroniques: " .. CA:L("questDetected", questID) .. "|r")
    CA:Refresh()
  elseif event == "QUEST_ACCEPTED" then
    local questID = ...
    CA:RecordQuest(questID, "accepted")
    CA:Refresh()
  elseif event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" or event == "CRAFT_UPDATE" then
    -- La liste peut arriver juste après ce signal sur Forever. La file réalise
    -- une seconde lecture brève si nécessaire, uniquement après ouverture
    -- volontaire du métier natif.
    CA.professionNativeWindowObserved = true
    CA:QueueProfessionScan()
  elseif event == "SKILL_LINES_CHANGED" then
    -- Déclenché à l'apprentissage/à la suppression d'un métier ; met à jour
    -- le relevé autonome même si la fenêtre de métier ne sera jamais ouverte.
    CA:QueueKnownProfessionSpellbookScan()
    CA:Refresh()
  elseif event == "TRADE_SKILL_CLOSE" or event == "CRAFT_CLOSE" then
    CA.professionNativeWindowObserved = nil
  elseif event == "NEW_RECIPE_LEARNED" or event == "LEARNED_SPELL_IN_TAB" then
    if CA:RecordProfessionSpellLearned(...) and CA.activeSection == "professions" then
      CA:RefreshProfessions()
    end
  else
    CA:Refresh()
  end
end)
