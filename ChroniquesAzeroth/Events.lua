-- The slash commands and the game events the addon follows.

local _, ns = ...
local CA = ns.CA

CA:AddTexts({
  frFR = {
    helpLines = {
      "/ca : ouvrir ou fermer la fenêtre",
      "/ca help : lister les commandes",
      "/ca diag : lister ce que le client fournit et relire les métiers",
      "/ca log [nombre] : afficher les dernières entrées du journal",
      "/ca debug : activer ou couper le journal détaillé",
      "/ca clearlog : vider le journal",
    },
    unknownCommand = "commande inconnue : %s", debugOn = "journal détaillé activé.", debugOff = "journal détaillé coupé.",
    logCleared = "journal vidé.",
  },
  enUS = {
    helpLines = {
      "/ca: open or close the window",
      "/ca help: list the commands",
      "/ca diag: list what the client provides and read the professions again",
      "/ca log [count]: print the last log entries",
      "/ca debug: toggle detailed logging",
      "/ca clearlog: clear the log",
    },
    unknownCommand = "unknown command: %s", debugOn = "detailed logging on.", debugOff = "detailed logging off.",
    logCleared = "log cleared.",
  },
})

local function say(message, ...)
  print("|cffd6a33a" .. CA:L("addonTitle") .. "|r: " .. string.format(message, ...))
end

local commands = {}

commands[""] = function()
  CA.frame:SetShown(not CA.frame:IsShown()); CA:Refresh()
end
commands.show = commands[""]

commands.help = function()
  for _, line in ipairs(CA:L("helpLines")) do say("%s", line) end
end

commands.diag = function()
  for _, line in ipairs(ns.Diagnostics:Report()) do say("%s", line) end
  CA:ScanKnownProfessionSpellbooks()
  CA:ScanOpenProfession()
  CA:PrintProfessionScanDiagnostics()
end
commands.scan = commands.diag

commands.log = function(argument)
  for _, entry in ipairs(ns.Log:Tail(tonumber(argument) or 20)) do print(entry) end
end

commands.debug = function()
  ns.Log:SetDebug(not ns.Log:IsDebug())
  say("%s", ns.Log:IsDebug() and CA:L("debugOn") or CA:L("debugOff"))
end

commands.clearlog = function()
  ns.Log:Clear()
  say("%s", CA:L("logCleared"))
end

SLASH_CHRONIQUESAZEROTH1 = "/chroniques"
SLASH_CHRONIQUESAZEROTH2 = "/ca"
SlashCmdList.CHRONIQUESAZEROTH = function(input)
  local command, argument = tostring(input or ""):match("^%s*(%S*)%s*(.-)%s*$")
  command = string.lower(command or "")
  local handler = commands[command]
  if not handler then
    say(CA:L("unknownCommand"), command)
    handler = commands.help
  end
  ns.SafeCall("command " .. command, handler, argument)
end

local function onLogin()
  ChroniquesAzerothDB = ChroniquesAzerothDB or { completed = {}, accepted = {}, trackingMode = "account" }
  ChroniquesAzerothDB.trackingMode = ChroniquesAzerothDB.trackingMode or "account"
  ChroniquesAzerothDB.log = ChroniquesAzerothDB.log or {}
  ns.Log:Attach(ChroniquesAzerothDB.log)
  ns.Log:Info("Chronicles of Azeroth %s loaded (client %s, locale %s)", CA.VERSION, ns.Diagnostics.ClientBuild(), tostring(GetLocale()))
  ns.Diagnostics:Run()
  ChroniquesAzerothCharacterDB = ChroniquesAzerothCharacterDB or { completed = {}, accepted = {} }
  -- Non-destructive migration: the former account state could not tell
  -- which character had completed each quest.
  if ChroniquesAzerothDB.schemaVersion ~= 2 then
    ChroniquesAzerothDB.legacyCompleted = ChroniquesAzerothDB.completed or {}
    ChroniquesAzerothDB.characters = ChroniquesAzerothDB.characters or {}
    ChroniquesAzerothDB.schemaVersion = 2
  end
  CA:SyncCurrentCharacter()
  CA:CreateUI(); CA:CreateMinimapButton(); CA:InitializeQuestCatalog(); CA:Refresh()
  -- The spellbook is available without opening a profession window. The short
  -- delay lets the client finish restoring the character's spells after
  -- /reload or login.
  CA:QueueKnownProfessionSpellbookScan()
  print("|cffd6a33a" .. CA:L("addonTitle") .. "|r " .. CA:L("addonLoaded") .. " |cff66ff66/chroniques|r.")
end

local function onEvent(event, ...)
  if event == "PLAYER_LOGIN" then
    onLogin()
  elseif event == "QUEST_TURNED_IN" then
    local questID = ...
    CA:RecordQuest(questID, "completed")
    ns.Log:Info("Quest %s turned in", tostring(questID))
    print("|cff66ff66Chroniques: " .. CA:L("questDetected", questID) .. "|r")
    CA:Refresh()
  elseif event == "QUEST_ACCEPTED" then
    local questID = ...
    CA:RecordQuest(questID, "accepted")
    ns.Log:Debug("Quest %s accepted", tostring(questID))
    CA:Refresh()
  elseif event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" or event == "CRAFT_UPDATE" then
    -- On Forever, the list may arrive just after this signal. The queue makes
    -- a second, short reading if needed, only after the native profession
    -- window was opened by the player.
    CA.professionNativeWindowObserved = true
    CA:QueueProfessionScan()
  elseif event == "SKILL_LINES_CHANGED" then
    -- Fired when a profession is learned or unlearned; updates the
    -- self-contained record even if the profession window is never opened.
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
end

-- Every event is handled protected: an error reaches the log instead of breaking the addon.
CA:SetScript("OnEvent", function(_, event, ...)
  ns.SafeCall("event " .. event, onEvent, event, ...)
end)
