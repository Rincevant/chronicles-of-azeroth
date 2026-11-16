-- The addon frame, its events, its version and its localized texts.

local _, ns = ...
local CA = CreateFrame("Frame")
ns.CA = CA
CA:RegisterEvent("PLAYER_LOGIN")
CA:RegisterEvent("QUEST_TURNED_IN")
CA:RegisterEvent("QUEST_ACCEPTED")
CA:RegisterEvent("ZONE_CHANGED_NEW_AREA")
CA:RegisterEvent("GET_ITEM_INFO_RECEIVED")
-- Recipes are read only on the signals of the native profession window:
-- no profession data is explored at load time.
CA:RegisterEvent("TRADE_SKILL_SHOW")
-- They arrive when the native list is really ready and when a recipe is
-- learned, even while Chronicles is closed.
CA:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
CA:RegisterEvent("NEW_RECIPE_LEARNED")
CA:RegisterEvent("SKILL_LINES_CHANGED")
-- The historical variants do not exist on every client.
pcall(CA.RegisterEvent, CA, "CRAFT_SHOW")
pcall(CA.RegisterEvent, CA, "CRAFT_UPDATE")
pcall(CA.RegisterEvent, CA, "CRAFT_CLOSE")
pcall(CA.RegisterEvent, CA, "LEARNED_SPELL_IN_TAB")
CA:RegisterEvent("TRADE_SKILL_CLOSE")

-- Chronicles follows the client language: French stays the language of frFR
-- clients, every other client gets English.
CA.locale = (GetLocale and GetLocale() == "frFR") and "frFR" or "enUS"
CA.VERSION = "0.25.1-beta"
CA.GITHUB_ISSUES_URL = "https://github.com/Rincevant/chronicles-of-azeroth/issues"
CA.DISCORD_URL = "https://discord.gg/hmQTKkdRzB"

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
    feedbackTitle = "VOS RETOURS", feedbackDescription = "Chroniques ne peut pas envoyer de données sur Internet. Préparez le rapport, copiez-le avec Ctrl+C, puis collez-le dans le canal de retours choisi.", prepareReport = "PRÉPARER LE RAPPORT", feedbackCopyHint = "Le rapport est sélectionné : Ctrl+C pour le copier. Aucun envoi automatique.", feedbackDestination = "Bugs : github.com/Rincevant/chronicles-of-azeroth/issues  •  Communauté : discord.gg/hmQTKkdRzB", copyDiscord = "COPIER LE LIEN DISCORD", discordCopyHint = "Lien Discord sélectionné : Ctrl+C pour le copier.",
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
    feedbackTitle = "YOUR FEEDBACK", feedbackDescription = "Chronicles cannot send data to the Internet. Prepare the report, copy it with Ctrl+C, then paste it into the feedback channel you choose.", prepareReport = "PREPARE REPORT", feedbackCopyHint = "The report is selected: press Ctrl+C to copy it. Nothing is sent automatically.", feedbackDestination = "Bugs: github.com/Rincevant/chronicles-of-azeroth/issues  •  Community: discord.gg/hmQTKkdRzB", copyDiscord = "COPY DISCORD LINK", discordCopyHint = "Discord link selected: press Ctrl+C to copy it.",
    noZoneQuests = "No outdoor quests are listed for this zone", noQuestListed = "NO QUESTS LISTED", noZoneQuestDetail = "The embedded catalog is loaded; this zone has no outdoor quests in the Forever data.", rewardsWhenSelected = "Rewards are available when a quest is selected.",
    questInProgress = "IN PROGRESS - in your quest log", questCompleted = "COMPLETED", questDiscover = "TO DISCOVER", required = "required", optional = "opt.", level = "Lvl.", questsRequired = "%d / %d required completed - %d remaining", questCount = "%d / %d quests - %s",
    object = "item", objects = "items", hoverIcons = "hover the icons", questFallback = "Quest %d", questUnavailable = "Quest title unavailable", recipeFallback = "Recipe #%d", itemFallback = "Item #%d",
    currentRank = "Current rank: %s", listedOnCharacters = "Recorded on %d character%s - highest rank: %s", catalogNotLearnedAccount = "Full Forever catalog - profession not learned on synchronized characters.", catalogNotLearnedCharacter = "Full Forever catalog - profession not learned by this character.", professionNotLearned = "This profession is not learned by this character.", recipeCatalogSummary = "CATALOG - %d RECIPES - %d LEARNED", recipesListed = "%d recipes listed", noRecipeListed = "No recipes listed", known = "LEARNED", obtain = "TO OBTAIN", characterOwner = "BY THIS CHARACTER", accountOwner = "ON ACCOUNT",
    footerQuests = "/chronicles to open - Completed quests are detected and saved", footerProfessions = "Learned recipes synchronize automatically when the profession window opens.", footerFeedback = "Feedback: prepare a report, copy it with Ctrl+C, then send it.",
    minimapOpen = "Left-click: open or close", minimapToggle = "Right-click: switch Account / Character", minimapDrag = "Drag: move around the minimap", trackingChanged = "tracking: %s.", addonLoaded = "loaded. Use the icon around the minimap or", questDetected = "completed quest detected (ID %d).",
    reportVersion = "Version", reportLocale = "Locale", reportCharacter = "Character", reportRealm = "Realm", reportSection = "Tab", reportTracking = "Tracking", reportZone = "Zone", reportProfession = "Profession", reportProblem = "Describe the problem", reportSteps = "Steps to reproduce", reportExpected = "Expected result", reportActual = "Actual result",
  },
}

-- Adds the texts of a module, { frFR = { key = text }, enUS = { ... } }, to the tables above.
function CA:AddTexts(texts)
  for locale, entries in pairs(texts) do
    TEXT[locale] = TEXT[locale] or {}
    for key, value in pairs(entries) do TEXT[locale][key] = value end
  end
end

-- Runs fn protected: an error is written to the log with its traceback instead of breaking
-- the caller, and the same error is reported once, then every hundred occurrences.
local failureCounts = {}
function ns.SafeCall(context, fn, ...)
  local args, count = { ... }, select("#", ...)
  local ok, result = xpcall(function() return fn(unpack(args, 1, count)) end, function(err)
    return tostring(err) .. "\n" .. (debugstack and debugstack(2, 12, 0) or "")
  end)
  if ok then return result end
  if not ns.Log then
    geterrorhandler()(result)
    return nil
  end
  local key = context .. "|" .. (result:match("^[^\n]*") or "")
  failureCounts[key] = (failureCounts[key] or 0) + 1
  if failureCounts[key] == 1 then
    ns.Log:Error("%s failed: %s", context, result)
  elseif failureCounts[key] % 100 == 0 then
    ns.Log:Error("%s failed %d times (last: %s)", context, failureCounts[key], result:match("^[^\n]*"))
  end
  return nil
end

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
