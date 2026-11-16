-- The slash commands and the game events the addon follows.

local _, ns = ...
local CA = ns.CA

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
end)
