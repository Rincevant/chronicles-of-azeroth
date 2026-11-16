-- Offline tests of Chronicles of Azeroth, run with a Lua 5.1 interpreter from the repository
-- root:
--
--     lua5.1 tests/run.lua                         (English client)
--     CA_TEST_LOCALE=frFR lua5.1 tests/run.lua     (French client)
--
-- The addon is loaded in TOC order on top of tests/wow_stub.lua, with the saved variables
-- of a fresh install, then of a previous version. Each run logs in, opens the window and
-- goes through every tab. Any Lua error, and any failed check, fails the run.

package.path = "./tests/?.lua;" .. package.path

local ADDON = "ChroniquesAzeroth"
local failures = 0
local Stub

local function fail(message, ...)
    failures = failures + 1
    io.stderr:write("FAIL: " .. string.format(message, ...) .. "\n")
end

local function check(condition, message, ...)
    if not condition then fail(message, ...) end
end

local function tocFiles()
    local files = {}
    for line in io.lines(ADDON .. "/" .. ADDON .. ".toc") do
        line = line:gsub("\r", "")
        if line ~= "" and not line:match("^##") then files[#files + 1] = (line:gsub("\\", "/")) end
    end
    return files
end

local function count(map)
    local total = 0
    for _ in pairs(map or {}) do total = total + 1 end
    return total
end

-- Loads the client emulation and the addon into a clean global environment, so that each
-- scenario starts from a fresh game session.
local pristine = {}
for key, value in pairs(_G) do pristine[key] = value end

local function startSession(accountDB, characterDB, setup)
    for key in pairs(_G) do
        if pristine[key] == nil then _G[key] = nil end
    end
    for key, value in pairs(pristine) do _G[key] = value end
    package.loaded.wow_stub = nil
    Stub = require("wow_stub")
    if setup then setup(Stub) end
    ChroniquesAzerothDB, ChroniquesAzerothCharacterDB = accountDB, characterDB
    local files = tocFiles()
    -- The client passes every file of the addon the same private table.
    local namespace = {}
    for _, file in ipairs(files) do
        local chunk, err = loadfile(ADDON .. "/" .. file)
        if not chunk then error("cannot load " .. file .. ": " .. err) end
        chunk(ADDON, namespace)
    end
    Stub.Fire("PLAYER_LOGIN")
    -- Lets the login scan of completed quests and the delayed spellbook scan finish.
    Stub.Advance(5)
    return #files
end

local function mainWindow()
    for _, child in ipairs(UIParent._children) do
        if child._type == "Frame" and child._width == 1100 then return child end
    end
end

local function sectionTabs(window)
    local tabs = {}
    for _, widget in ipairs(Stub.Descendants(window)) do
        if widget.section then tabs[widget.section] = widget end
    end
    return tabs
end

local function textsUnder(root)
    local texts = {}
    for _, widget in ipairs(Stub.Descendants(root)) do
        if type(widget._text) == "string" and widget._text ~= "" then table.insert(texts, widget._text) end
    end
    return texts
end

local function hasText(root, pattern)
    for _, text in ipairs(textsUnder(root)) do
        if text:find(pattern) then return true end
    end
    return false
end

-------------------------------------------------------------------------------
-- Fresh install
-------------------------------------------------------------------------------

local fileCount = startSession(nil, nil)
check(fileCount == 15, "the TOC lists %d files, 15 expected", fileCount)
check(type(ChroniquesAzerothQuestCatalog) == "table", "the quest catalogue is loaded")
check(type(ChroniquesAzerothProfessionCatalog) == "table", "the profession catalogue is loaded")

check(type(ChroniquesAzerothDB) == "table", "the account saved variables are created")
check(type(ChroniquesAzerothCharacterDB) == "table", "the character saved variables are created")
check(ChroniquesAzerothDB.schemaVersion == 2, "the account saved variables use schema 2")
check(ChroniquesAzerothDB.trackingMode == "account", "the default tracking mode is the account")

for questID in pairs(Stub.completedQuests) do
    check(ChroniquesAzerothCharacterDB.completed[questID], "quest %d turned in before the install is imported", questID)
    check(ChroniquesAzerothDB.completed[questID], "quest %d is merged into the account progress", questID)
end
check(ChroniquesAzerothDB.characters["Tester-Forever"], "the character has its account record")

local window = mainWindow()
check(window ~= nil, "the main window is created")
check(_G.ChroniquesAzerothMinimapButton ~= nil, "the minimap button is created")

-- The slash command toggles the window.
local wasShown = window:IsShown()
SlashCmdList.CHRONIQUESAZEROTH("")
check(window:IsShown() ~= wasShown, "/chroniques toggles the window")
if not window:IsShown() then SlashCmdList.CHRONIQUESAZEROTH("") end
check(window:IsShown(), "the window is open")

-- Quests tab: the Elwynn Forest quests are listed with their client titles.
local tabs = sectionTabs(window)
for _, section in ipairs({ "quests", "professions", "feedback" }) do
    check(tabs[section] ~= nil, "the %s tab exists", section)
end
tabs.quests:Click()
check(hasText(window, "^Quest %d+") or hasText(window, "Quest %d+"), "the quest list shows quest titles")

-- Quest events are recorded for the character.
Stub.Fire("QUEST_ACCEPTED", 21)
check(ChroniquesAzerothCharacterDB.accepted and ChroniquesAzerothCharacterDB.accepted[21], "an accepted quest is recorded")
Stub.completedQuests[21] = true
Stub.Fire("QUEST_TURNED_IN", 21)
check(ChroniquesAzerothCharacterDB.completed[21], "a turned-in quest is recorded for the character")
check(ChroniquesAzerothDB.completed[21], "a turned-in quest is merged into the account progress")

-- Professions tab: the known profession and its spellbook recipes are read.
tabs.professions:Click()
Stub.Fire("SKILL_LINES_CHANGED")
Stub.Advance(5)
check(hasText(window, "Blacksmithing") or hasText(window, "Forge"), "the professions tab lists Blacksmithing")

-- Every browsing tab uses the three columns of the Quests tab, at the same place.
local function columnLayout(columns)
    local layout = {}
    for _, column in ipairs(columns) do table.insert(layout, column._width .. "x" .. column._height) end
    return table.concat(layout, " ")
end
local function browsingColumns(root)
    local columns = {}
    for _, child in ipairs(root._children) do
        if child._type == "Frame" and child._height == 400 and child._width ~= 1050 then table.insert(columns, child) end
    end
    return columns
end
local questColumns = browsingColumns(window)
local professionView
for _, child in ipairs(window._children) do
    if child._width == 1050 and #browsingColumns(child) == 3 then professionView = child end
end
check(columnLayout(questColumns) == "245x400 405x400 380x400", "the Quests tab has its three columns (%s)", columnLayout(questColumns))
check(professionView ~= nil and columnLayout(browsingColumns(professionView)) == columnLayout(questColumns),
    "the Professions tab has the columns of the Quests tab")

-- Professions tab: the recipes are listed on the right; selecting one shows its details in
-- the middle, with the progress of the profession.
local recipeRows = {}
for _, widget in ipairs(Stub.Descendants(professionView)) do
    if widget._type == "Button" and widget.recipe and widget:IsShown() then table.insert(recipeRows, widget) end
end
check(#recipeRows > 0, "the recipe list shows recipes")
if recipeRows[2] then
    recipeRows[2]:Click()
    check(hasText(professionView, "^" .. recipeRows[2].recipe.name:gsub("%p", "%%%0") .. "$"), "the selected recipe is detailed")
end
check(hasText(professionView, "^%d+%%$"), "the profession shows its progress ring")

-- Feedback tab: the report is prepared without any network access.
tabs.feedback:Click()
local reportPrepared = false
for _, widget in ipairs(Stub.Descendants(window)) do
    if widget._type == "Button" and widget.text and widget._scripts.OnClick then
        local label = widget.text._text or ""
        if label:find("REPORT") or label:find("RAPPORT") then
            widget:Click()
            reportPrepared = true
        end
    end
end
check(reportPrepared, "the feedback tab has a button that prepares the report")
local reportFound = false
for _, widget in ipairs(Stub.Descendants(window)) do
    if widget._type == "EditBox" and type(widget._text) == "string" and widget._text:find("0%.%d+") then reportFound = true end
end
check(reportFound, "the feedback report is written into its text box")

-- The diagnostic command runs without errors.
SlashCmdList.CHRONIQUESAZEROTH("diag")

-- The log is kept in the account saved variables, and the commands read it.
local function logHas(pattern)
    for _, entry in ipairs(ChroniquesAzerothDB.log.entries) do
        if entry:find(pattern) then return true end
    end
    return false
end
check(logHas(" INFO Chronicles of Azeroth .* loaded"), "the log records the login")
check(logHas(" INFO diag: Completed quests: "), "the diagnostic report is written to the log")
check(logHas(" INFO Quest 21 turned in"), "a turned-in quest is logged")
local chatBefore = #Stub.chat
SlashCmdList.CHRONIQUESAZEROTH("log 3")
check(#Stub.chat - chatBefore == 3, "/ca log 3 prints the last three entries")
SlashCmdList.CHRONIQUESAZEROTH("help")
check(Stub.chat[#Stub.chat]:find("/ca clearlog", 1, true) ~= nil, "/ca help lists the commands")
SlashCmdList.CHRONIQUESAZEROTH("debug")
check(ChroniquesAzerothDB.log.debug == true, "/ca debug turns detailed logging on")
SlashCmdList.CHRONIQUESAZEROTH("debug")
check(ChroniquesAzerothDB.log.debug == nil, "/ca debug turns detailed logging off")

check(not logHas(" ERROR "), "no error was logged during the session")

-- An error in an event handler reaches the log instead of breaking the addon.
local unitFactionGroup = UnitFactionGroup
UnitFactionGroup = function() error("client failure") end
local handled = pcall(Stub.Fire, "ZONE_CHANGED_NEW_AREA")
UnitFactionGroup = unitFactionGroup
check(handled, "an error in an event handler does not escape it")
check(logHas(" ERROR event ZONE_CHANGED_NEW_AREA failed: .*client failure"), "an error in an event handler is logged")

-------------------------------------------------------------------------------
-- Upgrade from saved variables written before schema 2
-------------------------------------------------------------------------------

startSession({ completed = { [7] = 1600000000, [1] = 1600000000 }, accepted = {} }, nil)
check(ChroniquesAzerothDB.schemaVersion == 2, "old saved variables are migrated to schema 2")
check(ChroniquesAzerothDB.legacyCompleted and ChroniquesAzerothDB.legacyCompleted[1], "old account completions are kept")
check(ChroniquesAzerothDB.completed[1], "old account completions stay in the account progress")
check(ChroniquesAzerothDB.completed[783], "the character's completions are added to the account progress")

-------------------------------------------------------------------------------
-- Horde character on an existing account
-------------------------------------------------------------------------------

local accountDB = ChroniquesAzerothDB
startSession(accountDB, nil, function(stub) stub.faction = "Horde" end)
check(count(ChroniquesAzerothDB.characters) >= 1, "the account keeps its character records")
SlashCmdList.CHRONIQUESAZEROTH("")
check(mainWindow():IsShown(), "the window opens for a second session")

-------------------------------------------------------------------------------

if failures > 0 then
    io.stderr:write(string.format("%d check(s) failed\n", failures))
    os.exit(1)
end
io.write(string.format("All checks passed (%s client)\n", os.getenv("CA_TEST_LOCALE") or "enUS"))
