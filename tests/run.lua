-- Offline tests of Chronicles of Azeroth, run with a Lua 5.1 interpreter from the repository root:
--
--     lua5.1 tests/run.lua            (English client)
--     CA_TEST_LOCALE=frFR lua5.1 tests/run.lua
--
-- The addon is loaded in TOC order on top of tests/wow_stub.lua, then logs in, opens its
-- window and goes through every tab and list. The run fails on any error the addon logs,
-- on any missing translation and on any failed assertion.

package.path = "./tests/?.lua;" .. package.path
local Stub = require("wow_stub")

local ADDON = "ChroniquesAzeroth"
local failures = 0

local function fail(message, ...)
    failures = failures + 1
    io.stderr:write("FAIL: " .. string.format(message, ...) .. "\n")
end

local function check(condition, message, ...)
    if not condition then fail(message, ...) end
end

-------------------------------------------------------------------------------
-- Loading
-------------------------------------------------------------------------------

local ns = {}
local function loadToc()
    local files = {}
    for line in io.lines(ADDON .. "/" .. ADDON .. ".toc") do
        line = line:gsub("\r", "")
        if line ~= "" and not line:match("^##") then files[#files + 1] = (line:gsub("\\", "/")) end
    end
    for _, file in ipairs(files) do
        local chunk, err = loadfile(ADDON .. "/" .. file)
        if not chunk then error("cannot load " .. file .. ": " .. err) end
        chunk(ADDON, ns)
    end
    return #files
end

local fileCount = loadToc()
Stub.Fire("ADDON_LOADED", ADDON)
-- The client fires some events before the login, when no character record exists yet.
Stub.Fire("SKILL_LINES_CHANGED")
Stub.Fire("PLAYER_LOGIN")
Stub.Advance(1)

-------------------------------------------------------------------------------
-- Scenarios
-------------------------------------------------------------------------------

local function errorsInLog()
    local errors = {}
    for _, entry in ipairs(ChroniquesAzerothDB.log.entries) do
        if entry:find(" ERROR ", 1, true) or entry:find("Missing localized string", 1, true) then errors[#errors + 1] = entry end
    end
    return errors
end

-- Data sanity
check(ns.Diagnostics.Count(ns.Data.Quests) > 4000, "quest data looks too small")
check(ns.Data.Races.raceBits[1] == 0, "human race bit should be 0")
check(ns.HasBit(ns.Data.Races.allianceRaces, 32), "the Skyborne alliance bit (32) must be readable")
check(not ns.HasBit(ns.Data.Races.allianceRaces, 1), "orcs are not alliance")

-- Progress
local record = ns.Database:Character()
check(record and record.quests[783], "completed quests should be read at login")
local view = ns.Quests:CurrentView()
check(ns.Quests:Status(783, view) == "done", "quest 783 should be done")
check(ns.Quests:Status(18, view) == "active", "quest 18 is in the log")
Stub.Fire("QUEST_TURNED_IN", 18)
Stub.Advance(1)
check(ns.Quests:Status(18, view) == "done", "a turned-in quest becomes done")

-- Zones are named after their map, as the world map shows them; without a map name from the
-- client, the shipped one is used.
check(ns.Names.Area(40) == "Map 1436", "a zone is named after its map")
local getMapInfo = C_Map.GetMapInfo
C_Map.GetMapInfo = function() return nil end
check(ns.Names.Area(40) == ns.Data.Strings[GetLocale()].maps[1436], "a zone falls back to the shipped map name")
C_Map.GetMapInfo = getMapInfo

-- Names: first lookup pending, then answered by the server
local pendingTitle = ns.Names.Quest(176)
Stub.Advance(1)
check(pendingTitle == nil and ns.Names.Quest(176) == "Quest 176", "quest titles are requested then cached")
check(ns.Database:Cache("quests")[176] == "Quest 176", "titles are cached in the saved variables")

-- Window and tabs
SlashCmdList.CHRONIQUESAZEROTH("")
local frame = ChroniquesAzerothFrame
check(frame and frame:IsShown(), "the window opens with /ca")

-- The tabs the window offers: those whose view the TOC loads.
local function present(tabs)
    local result = {}
    for _, tab in ipairs(tabs) do
        if frame.tabs[tab] then result[#result + 1] = tab end
    end
    return result
end

local function clickRows(list, count)
    for i = 1, math.min(count, #list.rows) do
        local row = list.rows[i]
        if row:IsShown() then row:Click() end
    end
end

for _, tab in ipairs(present({ "quests", "professions", "dungeons", "raids", "achievements", "collections" })) do
    ns.MainFrame:SelectTab(tab)
    local active = ns.MainFrame.activeView
    check(active and active.frame:IsShown(), "tab %s shows its view", tab)
    -- Click through the lists of the view.
    for _, key in ipairs({ "zones", "quests", "professions", "recipes", "instances", "entries", "kinds", "categories", "achievements" }) do
        local list = active[key]
        if type(list) == "table" and list.rows then clickRows(list, 6) end
    end
    Stub.Advance(1)
end

-- Quests view behaviour
ns.MainFrame:SelectTab("quests")
local questsView = ns.MainFrame.activeView
for _, value in ipairs({ "kalimdor", "other", "categories", "ek" }) do questsView:SelectContinent(value) end
check(#questsView.zones.items > 0, "the zone list is not empty")
check(#questsView.quests.items > 0, "the quest list of the selected zone is not empty")
-- The player stands in a building of Elwynn Forest: the zone is found through the parent maps.
questsView.selectedGroup = nil
check(questsView:InitialContinent() == "ek" and questsView.selectedGroup and questsView.selectedGroup.id == 12,
    "the zone the player is in is selected first")
-- Artwork of the zones without a map of their own, and of the areas that only name quests.
local function findGroup(continentValue, id)
    for _, group in ipairs(questsView:GroupsOf(continentValue)) do
        if group.id == id then return group end
    end
end
local alchemyOrders = findGroup("categories", 181)
check(not findGroup("categories", 16941) and alchemyOrders, "the crafting orders leave the area that only names them")
local ordersChain
for _, chain in ipairs(alchemyOrders.chains) do
    if ns.Data.Quests[chain[1]][ns.Const.Quest.CRAFT] == 171 then ordersChain = chain end
end
check(ordersChain and #ordersChain > 1, "the crafting orders of a profession form one chain in its category")
local artOf = function(group)
    questsView:SelectGroup(group)
    return questsView.banner.art.request
end
local warrior = artOf(findGroup("categories", 81))
check(warrior and tostring(warrior.fileID):find("category-warrior.tga", 1, true), "a class category shows its artwork")
local alchemyArt = artOf(alchemyOrders)
check(alchemyArt and tostring(alchemyArt.fileID):find("profession-alchemy.tga", 1, true),
    "a quest category of a profession shows the artwork of its profession")
questsView.banner.art:SetLoadingScreen(131824, true)
local framed = questsView.banner.art.request
check(framed.top and framed.top > 0 and framed.bottom < 1,
    "a framed loading screen is cropped to its painting, without the logo band")
local blackrock = artOf(findGroup("ek", 25))
check(tostring(blackrock.fileID):find("zone-blackrock-mountain.tga", 1, true),
    "Blackrock Mountain shows the artwork of its banner")
local riverglades = artOf(findGroup("ek", 16591))
check(tostring(riverglades.fileID):find("zone-riverglades.tga", 1, true), "a Forever zone shows its cropped artwork")
local elwynnArt = artOf(findGroup("ek", 12))
check(elwynnArt.kind == "file" and tostring(elwynnArt.fileID):find("zone-elwynn.tga", 1, true),
    "a zone Chronicles of Azeroth illustrates shows its own artwork")
local steppes = artOf(findGroup("ek", 46))
check(tostring(steppes.fileID):find("zone-blackrock-mountain.tga", 1, true), "the Burning Steppes banner shows Blackrock Mountain")
local noArt = { kind = "zone", id = 99999, continent = ns.Const.Continent.EASTERN_KINGDOMS, chains = {} }
check(artOf(noArt) == nil, "a zone without an artwork of the addon stays plain")
-- Every group of the quests and professions tabs has its artwork, and every artwork its file.
for _, list in pairs(ns.Quests:Groups()) do
    for _, group in ipairs(list) do
        check(artOf(group), "the %s %d has an artwork", group.kind, group.id)
    end
end
for _, art in ipairs({ ns.Theme.zoneArt, ns.Theme.bannerArt, ns.Theme.categoryArt, ns.Theme.professionArt }) do
    for _, path in pairs(art) do
        local file = io.open((path:gsub("^Interface\\AddOns\\", ""):gsub("\\", "/")), "rb")
        check(file, "the artwork %s is shipped", path)
        if file then file:close() end
    end
end
for skillLine in pairs(ns.Data.Professions) do
    check(ns.Theme.professionArt[skillLine], "the profession %d has an artwork", skillLine)
end
questsView:SelectContinent("ek")

-- One wheel notch moves the zone cards one by one.
questsView.zones:SetItems(questsView.zones.items)
questsView.zones:Scroll(1)
check(questsView.zones.offset == 1, "a wheel notch scrolls the zone list by one card (moved %d)", questsView.zones.offset)
local previousMin, previousMax = 0, 0
for _, group in ipairs(questsView:GroupsOf("ek")) do
    local low, high = group.levels and group.levels[1] or 99, group.levels and group.levels[2] or 99
    check(low > previousMin or (low == previousMin and high >= previousMax),
        "zones are sorted by level (zone %d)", group.id)
    previousMin, previousMax = low, high
end

-- A collection API answering in another order puts a non-text value in a name.
if ns.Collections then
local getPetInfo = C_PetJournal.GetPetInfoBySpeciesID
C_PetJournal.GetPetInfoBySpeciesID = function(id)
    if id == ns.Data.Collections.pets[1] then return getPetInfo, 132599 end
    return getPetInfo(id)
end
ns.Collections:Invalidate("pets")
local pets = ns.Collections:Entries("pets")
C_PetJournal.GetPetInfoBySpeciesID = getPetInfo
ns.Collections:Invalidate("pets")
check(pets and #pets > 0, "a collection keeps its valid entries when one name is not a text")
end

-- Every tab is laid out on the shared page; the cards of a list show different artwork.
for _, tab in ipairs(present({ "quests", "professions", "dungeons", "raids", "achievements", "collections" })) do
    ns.MainFrame:SelectTab(tab)
    local active = ns.MainFrame.activeView
    check(active.page and active.page.groups and active.page.items and active.page.banner and active.page.filters,
        "tab %s is laid out on the shared page", tab)
    local seen, repeated = {}, nil
    for _, row in ipairs(active.page.groups.rows) do
        local request = row:IsShown() and row.art.request
        if request and request.kind == "file" then
            if seen[request.fileID] then repeated = request.fileID end
            seen[request.fileID] = true
        end
    end
    check(not repeated, "tab %s shows each artwork once in its list (%s repeated)", tab, tostring(repeated))
end
if frame.tabs.collections then
    ns.MainFrame:SelectTab("collections")
    local listsToys = false
    for _, kind in ipairs(ns.MainFrame.activeView.kinds.items) do if kind == "toys" then listsToys = true end end
    check(listsToys, "the toy box is a kind of the collections tab")
end

-- Lists of groups: levels first (lowest, then highest), then the others; names otherwise.
local sorted = ns.UI.SortByLevel({
    { name = "Zeta" }, { name = "beta", levels = { 10, 20 } }, { name = "Alpha", levels = { 10, 20 } },
    { name = "Gamma", levels = { 10, 15 } }, { name = "Étoile" }, { name = "Delta", levels = { 5, 60 } },
}, function(group) return group.levels end, function(group) return group.name end)
local order = {}
for _, group in ipairs(sorted) do order[#order + 1] = group.name end
check(table.concat(order, ",") == "Delta,Gamma,Alpha,beta,Étoile,Zeta", "groups are sorted by level then name (%s)",
    table.concat(order, ","))

-- Legacy challenges within reach: the categories of other classes and unlearned professions
-- are hidden, the others listed in alphabetical order.
if frame.tabs.achievements then
ns.MainFrame:SelectTab("achievements")
local challengeNames = {}
for _, category in ipairs(ns.MainFrame.activeView.categories.items) do challengeNames[#challengeNames + 1] = category.name end
local expectedChallenges = GetLocale() == "frFR" and "Exploration,Forge,Paladin" or "Blacksmithing,Exploration,Paladin"
check(table.concat(challengeNames, ",") == expectedChallenges,
    "challenge categories within reach, in alphabetical order (%s)", table.concat(challengeNames, ","))
frame.filter:Click()
check(#ns.MainFrame.activeView.categories.items == 5, "every challenge category is listed without the filter")
frame.filter:Click()
end

-- A quest title the server does not send falls back to the shipped title of the client's
-- language, and is asked again later.
local requestQuest = C_QuestLog.RequestLoadQuestByID
C_QuestLog.RequestLoadQuestByID = function(questID)
    C_Timer.After(0.1, function() Stub.Fire("QUEST_DATA_LOAD_RESULT", questID, false) end)
end
check(ns.Names.Quest(93928) == nil, "a quest title is first requested")
-- The requests of the tabs gone through before are ahead in the queue.
Stub.Advance(15)
local shipped = ns:GameString("quests", 93928) or ns.Data.Quests[93928][ns.Const.Quest.NAME_FALLBACK]
check(GetLocale() == "enUS" or ns:GameString("quests", 783) == "Menace intérieure", "the %s data ships localized quest titles", GetLocale())
check(ns.Names.Quest(93928) == shipped, "an unanswered quest title uses the shipped one (%s)", tostring(ns.Names.Quest(93928)))
C_QuestLog.RequestLoadQuestByID = requestQuest
Stub.Advance(130)
ns.Names.Quest(93928)
Stub.Advance(2)
check(ns.Names.Quest(93928) == "Quest 93928", "an unanswered quest title is asked again later")

-- Ignored quests: out of the counts of the view; a character follows the account unless it
-- made its own choice.
local characterView = ns.MainFrame:View()
local accountView = { tracking = "account", faction = characterView.faction, possible = true, key = "test:account" }
local welcome = 5805
local elwynnZone = findGroup("ek", 12)
local function total(view)
    return ns.Quests:Summary("test:ignore:" .. tostring(ns.Quests:Revision()) .. view.key, elwynnZone.chains, view).total
end
local before = total(characterView)
ns.Quests:SetIgnored(welcome, characterView, true)
check(ns.Quests:Status(welcome, characterView) == ns.Const.Status.IGNORED and total(characterView) == before - 1,
    "a quest ignored for the character leaves its counts")
check(not ns.Quests:IsVisible(welcome, characterView), "an ignored quest is hidden within reach")
check(not ns.Quests:IsIgnored(welcome, accountView), "a quest ignored for a character stays counted for the account")
ns.Quests:SetIgnored(welcome, characterView, false)
check(ns.Database:Character().ignored[welcome] == nil, "a choice equal to the account's is dropped")
ns.Quests:SetIgnored(welcome, accountView, true)
local ignored, source = ns.Quests:IgnoreState(welcome, characterView)
check(ignored and source == "account", "a character without a choice follows the account")
ns.Quests:SetIgnored(welcome, characterView, false)
check(not ns.Quests:IsIgnored(welcome, characterView) and ns.Quests:IsIgnored(welcome, accountView),
    "a character's own choice overrides the account's")
ns.Quests:SetIgnored(welcome, accountView, false)
ignored, source = ns.Quests:IgnoreState(welcome, characterView)
check(not ignored and source == "character", "a character keeps its own choice when the account changes")
ns.Database:Character().ignored[welcome] = nil
Stub.Advance(1)

-- Every tab has content
local expectations = {
    professions = "recipes", dungeons = "entries", raids = "entries",
    collections = "entries", achievements = "achievements",
}
for tab, listKey in pairs(expectations) do
  if frame.tabs[tab] then
    ns.MainFrame:SelectTab(tab)
    local list = ns.MainFrame.activeView[listKey]
    check(list and #list.items > 0, "tab %s lists entries in %s", tab, listKey)
    local shown = 0
    for _, row in ipairs(list and list.rows or {}) do if row:IsShown() then shown = shown + 1 end end
    check(shown > 0, "tab %s draws rows", tab)
  end
end

-- Progress gauges: one bar per tab, the ring the mean of the tabs that count something.
Stub.Advance(0.1)
local progress = ns.MainFrame.progress
check(not ns.Progress or progress ~= nil, "the gauges are drawn once the window is shown")
if progress then
    check(progress.quests.total > 0 and progress.professions.total > 0 and progress.dungeons.total > 0,
        "the quests, professions and dungeons gauges count entries")
    local sum, counted = 0, 0
    for _, tab in ipairs(ns.Progress.TABS) do
        local counts = progress[tab]
        if counts.total > 0 then sum, counted = sum + counts.done / counts.total, counted + 1 end
    end
    check(math.abs(progress.overall - sum / counted) < 1e-9, "the overall progress is the mean of the tabs")
    check(frame.ring.percent:GetText() == string.format("%d%%", math.floor(progress.overall * 100)),
        "the ring shows the overall percentage")
    check(frame.tabs.quests.progress.fraction ~= nil, "the tab bars are filled")
    frame.tabs.quests:GetScript("OnEnter")(frame.tabs.quests)
    frame.ring:GetScript("OnEnter")(frame.ring)
end

-- Resizing: the tabs share the new width, the size is kept, and a saved size is held within
-- the bounds.
if frame.grip then
local tabWidth = frame.tabs.quests:GetWidth()
frame:SetSize(1500, 800)
frame:GetScript("OnSizeChanged")(frame)
check(frame.tabs.quests:GetWidth() > tabWidth, "the tabs widen with the window")
frame.grip:GetScript("OnMouseDown")(frame.grip, "LeftButton")
frame.grip:GetScript("OnMouseUp")(frame.grip, "LeftButton")
local size = ns.Database:Settings().size
check(size and size[1] == 1500 and size[2] == 800, "the window size is saved once resized")
local fitWidth, fitHeight = ns.MainFrame:FitSize(200, 5000)
check(fitWidth >= 1000 and fitHeight <= 1080, "a saved size is held within the bounds of the screen")
end

-- Quest details of an active quest, with objectives and a waypoint button
ns.MainFrame:SelectTab("quests")
questsView = ns.MainFrame.activeView
questsView:OnQuestClick({ kind = "quest", id = 176 })
check(#questsView.details.widgets.line > 0, "quest details are drawn")
for _, button in ipairs(questsView.details.widgets.button or {}) do
    if button:IsShown() then button:Click() end
end

-- Tracking modes and faction switch; the character filter only applies to the character.
frame.tracking:Click()
check(ns.Database:Settings().tracking == "account" and not frame.filter.available,
    "the tracking switch goes to the account, where the character filter does not apply")
frame.faction:Click()
Stub.Advance(1)
frame.tracking:Click()
check(ns.Database:Settings().tracking == "character", "the tracking switch comes back to the character")
check(not frame.filter.available, "the character filter does not apply to the other faction")
frame.faction:Click()
check(frame.filter.available, "the character filter applies to the character in its own faction")
Stub.Advance(1)

-- Character filter: the character (stub) knows Blacksmithing only.
local Q = ns.Const.Quest
-- The first quest, by id, that matches and counts in the totals: the order of pairs() would
-- otherwise pick a different quest on another interpreter, sometimes a repeatable one.
local function questNeeding(predicate)
    local found
    for questID, row in pairs(ns.Data.Quests) do
        if predicate(row) and ns.Quests:IsCounted(questID) and ns.Player:CanRace(row[Q.RACES])
            and ns.Player:CanClass(row[Q.CLASSES]) and (not found or questID < found) then
            found = questID
        end
    end
    return found
end
local skinning = questNeeding(function(row) return row[Q.SKILL] and row[Q.SKILL][1] == 393 end)
local smithing = questNeeding(function(row) return row[Q.SKILL] and row[Q.SKILL][1] == 164 end)
local order = questNeeding(function(row) return row[Q.CRAFT] and row[Q.CRAFT] ~= 164 end)
local alchemy = questNeeding(function(row) return row[Q.AREA] == -181 end)
check(skinning and smithing and order and alchemy, "the data has quests needing professions")
local possibleView = ns.MainFrame:View()
check(possibleView.possible, "the character filter is active by default")
check(not ns.Quests:IsVisible(skinning, possibleView), "a quest of an unlearned profession is hidden")
check(ns.Quests:IsVisible(smithing, possibleView), "a quest of a learned profession is shown")
check(not ns.Quests:IsVisible(order, possibleView), "a crafting order of an unlearned profession is hidden")
check(not ns.Quests:IsVisible(alchemy, possibleView), "a quest of an unlearned profession category is hidden")
ns.MainFrame:SelectTab("professions")
local shownProfessions = ns.MainFrame.activeView.professions.items
check(#shownProfessions == 1 and shownProfessions[1].skillLine == 164, "only the learned professions are listed")
ns.MainFrame:SelectTab("quests")
local filteredTotal = ns.Quests:Summary("test:skinning", { { skinning, smithing } }, possibleView).total
frame.filter:Click()
local everythingView = ns.MainFrame:View()
check(not everythingView.possible and ns.Quests:IsVisible(skinning, everythingView),
    "the filter switch shows the quests of every profession")
check(ns.Quests:Summary("test:skinning", { { skinning, smithing } }, everythingView).total > filteredTotal,
    "the counts follow the character filter")
ns.MainFrame:SelectTab("professions")
check(#ns.MainFrame.activeView.professions.items == #ns.Professions:List(), "every profession is listed without the filter")
-- The recipe search also finds a recipe by the names of the item it creates and of the items
-- that teach it.
do
    local R = ns.Const.Recipe
    local professionsView = ns.MainFrame.activeView
    local created, taught
    for _, profession in ipairs(ns.Professions:List()) do
        for _, recipe in ipairs(profession.recipes) do
            if not created and recipe[R.CREATED_ITEM] then created = { profession.skillLine, recipe } end
            local source = recipe[R.SOURCES] and recipe[R.SOURCES][1]
            if not taught and source and source.item then taught = { profession.skillLine, recipe, source.item } end
        end
    end
    local function finds(skillLine, recipe, query)
        professionsView.selected, professionsView.query = skillLine, query
        professionsView:RefreshRecipes()
        for _, item in ipairs(professionsView.recipes.items) do
            if item == recipe then return true end
        end
        return false
    end
    Stub.itemNames[created[2][R.CREATED_ITEM]] = "Searched Cuirass"
    check(finds(created[1], created[2], "searched cuirass"), "a recipe is found by the name of the item it creates")
    Stub.itemNames[taught[3]] = "Plans: Searched Plans"
    check(finds(taught[1], taught[2], "searched plans"), "a recipe is found by the name of the item that teaches it")
    professionsView.query = ""
end
frame.filter:Click()
ns.MainFrame:SelectTab("quests")

-- Crafting orders: a group named after the prefix of their titles, whose rows drop it.
local questName = ns.Names.Quest
ns.Names.Quest = function(questID) return "Commission d'artisan\194\160: élixir " .. questID end
local orders = ns.QuestWidgets.BuildItems({ ordersChain }, everythingView, { [ordersChain[1]] = true })
local orderRow = questsView.quests.rows[1]
ns.QuestWidgets.FillRow(orderRow, orders[1], everythingView)
check(orders[1].kind == "chain" and orderRow.name:GetText() == "Commission d'artisan",
    "the crafting orders are grouped under the prefix of their titles (%s)", orderRow.name:GetText())
ns.QuestWidgets.FillRow(orderRow, orders[2], everythingView)
check(orderRow.name:GetText():sub(1, 7) == "Élixir", "an order shows the item it asks for, capitalized (%s)", orderRow.name:GetText())
ns.Names.Quest = function(questID) return "Writ: Item " .. questID end
orders = ns.QuestWidgets.BuildItems({ { ordersChain[1] } }, everythingView, {})
ns.Names.Quest = questName
check(orders[1].kind == "chain" and orders[1].label == "Writ", "a single order is still shown in its group")

-- A quest needing a higher profession rank is locked; the character (stub) has 75 in Blacksmithing.
local hardSmithing = questNeeding(function(row)
    return row[Q.SKILL] and row[Q.SKILL][1] == 164 and row[Q.SKILL][2] > 75 and not row[Q.PRE_ALL] and not row[Q.PRE_ANY]
end)
local playerLevel = ns.Player.level
ns.Player.level = 60
local status, reason = ns.Quests:Status(hardSmithing, possibleView)
ns.Player.level = playerLevel
check(status == ns.Const.Status.LOCKED and reason == "skill", "a quest above the profession rank is locked (%s, %s)",
    tostring(status), tostring(reason))

-- The state filter of the item lists: "to do" and "done" narrow the list, never the counts.
local elwynn = findGroup("ek", 12)
questsView:SelectGroup(elwynn)
local filter = questsView.stateFilter
local everyChainOpen = setmetatable({}, { __index = function() return true end })
local function listedStates(state)
    filter.buttons[state]:Click()
    local done, todo = 0, 0
    for _, item in ipairs(ns.QuestWidgets.BuildItems(elwynn.chains, possibleView, everyChainOpen, nil, filter)) do
        if item.kind == "quest" then
            if ns.Quests:Status(item.id, possibleView) == ns.Const.Status.DONE then done = done + 1 else todo = todo + 1 end
        end
    end
    return done, todo
end
local before = ns.Quests:Summary("zone:12", elwynn.chains, possibleView).done
local allDone, allTodo = listedStates(1)
local todoDone, todoTodo = listedStates(2)
local doneDone, doneTodo = listedStates(3)
check(allDone > 0 and allTodo > 0, "every quest is listed without a state filter")
check(todoDone == 0 and todoTodo == allTodo, "the to-do filter lists only the remaining quests")
check(doneTodo == 0 and doneDone == allDone, "the done filter lists only the completed quests")
check(ns.Database:Settings().listFilters.quests == "done", "the state filter of a list is remembered")
check(ns.Quests:Summary("zone:12", elwynn.chains, possibleView).done == before, "the state filter keeps the counts")
filter.buttons[1]:Click()
for _, tab in ipairs(present({ "professions", "dungeons", "raids", "achievements", "collections" })) do
    ns.MainFrame:SelectTab(tab)
    local stateFilter = ns.MainFrame.activeView.filters
    check(stateFilter and stateFilter.Keeps, "tab %s offers the state filter", tab)
    if stateFilter then
        stateFilter.buttons[2]:Click()
        stateFilter.buttons[1]:Click()
    end
end
ns.MainFrame:SelectTab("quests")

-- Professions: known spells were read
check(ns.Database:Character().recipes[2660], "known recipes are read from the spellbook")

-- Links: a recipe rewarded by a quest leads to the quest, the quest back to its recipes, and
-- Back returns through every place in turn.
local R = ns.Const.Recipe
local linkedSpell, linkedQuest, unlistedSpell, instanceSpell, instanceQuest
for _, profession in ipairs(ns.Professions:List()) do
    for _, recipe in ipairs(profession.recipes) do
        for _, source in ipairs(recipe[R.SOURCES] or {}) do
            for _, questID in ipairs(source.questRewards or {}) do
                local tab = ns.MainFrame:QuestTab(questID)
                if tab == "quests" then
                    if not linkedSpell then linkedSpell, linkedQuest = recipe[R.SPELL], questID end
                elseif tab then
                    if not instanceSpell then instanceSpell, instanceQuest = recipe[R.SPELL], questID end
                elseif not unlistedSpell then
                    unlistedSpell = recipe[R.SPELL]
                end
            end
        end
    end
end
check(linkedSpell ~= nil, "the data has a recipe rewarded by a listed quest")

-- The back button of the shown view.
-- The back button of the shown view; a view without the shared page (Feedback) has none.
local noBack = { IsShown = function() return false end }
local function backButton()
    local page = ns.MainFrame.activeView.page
    return page and page.back or noBack
end

local function inSight(list, matches)
    for _, row in ipairs(list.rows) do
        if row:IsShown() and row.item ~= nil and matches(row.item) then return true end
    end
    return false
end

-- The links of a detail panel, as drawn: { text, onClick, tooltip }.
local function linksOf(panel)
    local links = {}
    for i = 1, panel.used.link or 0 do
        local link = panel.widgets.link[i].link
        links[#links + 1] = { text = link.text:GetText(), onClick = link.onClick, tooltip = link.tooltip }
    end
    return links
end

local startTab = frame.tabs.collections and "collections" or "feedback"
if linkedSpell then
    ns.MainFrame:SelectTab("professions")
    local professionsView = ns.MainFrame.activeView
    professionsView.filters.value = "done" -- hides the recipe, which no character has learned
    ns.MainFrame:SelectTab(startTab)
    ns.MainFrame:Open("professions", linkedSpell)
    check(ns.MainFrame.activeTab == "professions" and professionsView.selectedRecipe == linkedSpell, "a link opens its recipe")
    check(inSight(professionsView.recipes, function(recipe) return recipe[R.SPELL] == linkedSpell end),
        "the linked recipe is listed despite the filter, and scrolled into sight")
    check(inSight(professionsView.professions, function(profession) return profession.skillLine == professionsView.selected end),
        "the profession of the linked recipe is scrolled into sight")
    check(backButton():IsShown(), "the back button shows once a link is followed")
    check((ns.MainFrame:BackTooltip() or ""):find(frame.tabs[startTab].label:GetText(), 1, true) ~= nil,
        "the back button tells where it returns to")
    frame:Hide()
    frame:Show()
    check(backButton():IsShown(), "closing and opening the window keeps the way back")

    local questLink
    for _, link in ipairs(linksOf(professionsView.details)) do
        if link.onClick and not questLink then questLink = link end
    end
    check(questLink ~= nil and questLink.tooltip == ns.L.LINK_QUEST, "the recipe links to the quest that rewards it")
    if questLink then
        questLink.onClick()
        local questsView = ns.MainFrame.activeView
        check(ns.MainFrame.activeTab == "quests" and questsView.selectedQuest == linkedQuest, "the quest link opens the quest")
        local recipeName = ns.Professions.RecipeName(ns.Professions:Recipe(linkedSpell)) or ("#" .. linkedSpell)
        check(ns.MainFrame:BackTooltip() == string.format(ns.L.BACK_TO_RECIPE, recipeName),
            "the back link names the recipe it returns to")
        check(inSight(questsView.quests, function(item) return item.kind == "quest" and item.id == linkedQuest end),
            "the linked quest is scrolled into sight")
        check(inSight(questsView.zones, function(group) return group == ns.Quests:GroupOf(linkedQuest) end),
            "the zone of the linked quest is scrolled into sight")

        local rewarded = ns.Professions:RecipesRewardedBy(linkedQuest)[1]
        local rewardedRecipe = rewarded and ns.Professions:Recipe(rewarded)
        local rewardedName = rewardedRecipe and (ns.Professions.RecipeName(rewardedRecipe) or ns.L.LOADING)
        local recipeLink
        for _, link in ipairs(linksOf(questsView.details)) do
            if link.onClick and link.text == rewardedName and not recipeLink then recipeLink = link end
        end
        check(recipeLink ~= nil, "the quest links to the recipes it rewards")
        if recipeLink then
            recipeLink.onClick()
            check(ns.MainFrame.activeTab == "professions", "the recipe link opens the professions tab")
            ns.MainFrame:Back()
            check(ns.MainFrame.activeTab == "quests" and questsView.selectedQuest == linkedQuest, "back returns to the quest")
        end
        ns.MainFrame:Back()
        check(ns.MainFrame.activeTab == "professions" and professionsView.selectedRecipe == linkedSpell, "back returns to the recipe")
    end
    ns.MainFrame:Back()
    check(ns.MainFrame.activeTab == startTab and not backButton():IsShown(), "back returns to where the first link was followed")

    -- Navigating by hand forgets the way back.
    ns.MainFrame:Open("professions", linkedSpell)
    check(backButton():IsShown(), "a link offers the way back")
    local row = professionsView.recipes.rows[1]
    row:GetScript("OnClick")(row)
    check(not backButton():IsShown() and #ns.MainFrame.history == 0, "selecting another recipe forgets the way back")
    ns.MainFrame:Open("professions", linkedSpell)
    frame.tabs.quests:GetScript("OnClick")(frame.tabs.quests)
    check(#ns.MainFrame.history == 0, "choosing a tab forgets the way back")
    professionsView.filters.value = "all"
end

if unlistedSpell then
    ns.MainFrame:Open("professions", unlistedSpell)
    local missing = false
    for _, link in ipairs(linksOf(ns.MainFrame.activeView.details)) do
        if not link.onClick and link.tooltip == ns.L.LINK_MISSING then missing = true end
    end
    check(missing, "a quest outside the catalogue keeps a link that says it is missing")
    ns.MainFrame:Back()
end

-- A quest listed by an instance opens in the dungeons or raids tab, on its instance.
check(not ns.Instances or instanceSpell ~= nil, "the data has a recipe rewarded by an instance quest")
if instanceSpell and ns.Instances then
    ns.MainFrame:Open("professions", instanceSpell)
    local questLink
    for _, link in ipairs(linksOf(ns.MainFrame.activeView.details)) do
        if link.onClick and not questLink then questLink = link end
    end
    check(questLink ~= nil, "a recipe links to the instance quest that rewards it")
    if questLink then
        questLink.onClick()
        local instancesView = ns.MainFrame.activeView
        local instance = ns.Instances:OfQuest(instanceQuest)
        check(ns.MainFrame.activeTab == ns.MainFrame:QuestTab(instanceQuest) and instancesView.selected == instance
            and instancesView.selectedEntry == instanceQuest, "an instance quest opens on its instance")
        check(inSight(instancesView.entries, function(item) return item.kind == "quest" and item.id == instanceQuest end),
            "the linked instance quest is scrolled into sight")
        ns.MainFrame:Back()
        check(ns.MainFrame.activeTab == "professions", "back returns from an instance to the recipe")
    end
    ns.MainFrame:Back()
end

-- A quest links to the quests it depends on and to the profession it asks for.
local questWithPrerequisite, questWithSkill
for questID, row in pairs(ns.Data.Quests) do
    local pre = row[ns.Const.Quest.PRE_ALL]
    if not questWithPrerequisite and ns.Quests:GroupOf(questID) and pre and #pre == 1 and ns.Quests:GroupOf(pre[1]) then
        questWithPrerequisite = questID
    end
    local skill = row[ns.Const.Quest.SKILL]
    if not questWithSkill and ns.Quests:GroupOf(questID) and skill and ns.Data.Professions[skill[1]] then
        questWithSkill = questID
    end
end
check(questWithPrerequisite ~= nil, "the data has a quest with a listed prerequisite")
if questWithPrerequisite then
    ns.MainFrame:Open("quests", questWithPrerequisite)
    local prerequisite = ns.Data.Quests[questWithPrerequisite][ns.Const.Quest.PRE_ALL][1]
    local found
    for _, link in ipairs(linksOf(ns.MainFrame.activeView.details)) do
        if link.onClick and link.text == (ns.Names.Quest(prerequisite) or ns.L.LOADING) and not found then found = link end
    end
    check(found ~= nil, "a quest links to its prerequisite")
    if found then
        found.onClick()
        check(ns.MainFrame.activeView.selectedQuest == prerequisite, "the prerequisite link opens the prerequisite")
        ns.MainFrame:Back()
    end
    ns.MainFrame:Back()
end
check(questWithSkill ~= nil, "the data has a quest asking for a listed profession")
if questWithSkill then
    ns.MainFrame:Open("quests", questWithSkill)
    local skillLine = ns.Data.Quests[questWithSkill][ns.Const.Quest.SKILL][1]
    local opened = false
    for _, link in ipairs(linksOf(ns.MainFrame.activeView.details)) do
        if link.onClick and not opened and link.text:find(ns.Names.SkillLine(skillLine) or ("#" .. skillLine), 1, true) then
            link.onClick()
            opened = true
        end
    end
    check(opened and ns.MainFrame.activeTab == "professions" and ns.MainFrame.activeView.selected == skillLine,
        "a quest links to the profession it asks for")
    ns.MainFrame:Back()
    ns.MainFrame:Back()
end

-- Repeatable quests: the server forgets them, so a turned in or hand-marked one stays done
-- through the next snapshot, leaves "to do", and never counts.
local repeatingQuests = {}
for questID, row in pairs(ns.Data.Quests) do
    if ns.Quests.IsRepeating(row) and ns.Quests:GroupOf(questID) then repeatingQuests[#repeatingQuests + 1] = questID end
end
table.sort(repeatingQuests)
check(#repeatingQuests >= 2, "the data has repeatable quests, which the client table leaves out")
if #repeatingQuests >= 2 then
    local characterView = { tracking = ns.Const.Tracking.CHARACTER, faction = ns.Player.faction, possible = false,
        key = "test:repeatables" }
    local marked, turnedIn = repeatingQuests[1], repeatingQuests[2]
    local group = ns.Quests:GroupOf(marked)
    local before = ns.Quests:Summary(group.kind .. ":" .. group.id .. ":before", group.chains, characterView)
    check(ns.Quests:Status(marked, characterView) == ns.Const.Status.REPEATABLE, "a repeatable quest starts as repeatable")
    ns.Quests:SetRepeatableDone(marked, characterView, true)
    Stub.Fire("QUEST_TURNED_IN", turnedIn)
    ns.Quests:Snapshot()
    check(ns.Quests:Status(marked, characterView) == ns.Const.Status.DONE, "a repeatable quest marked done stays done")
    check(ns.Quests:Status(turnedIn, characterView) == ns.Const.Status.DONE, "a repeatable quest turned in stays done")
    local after = ns.Quests:Summary(group.kind .. ":" .. group.id .. ":after", group.chains, characterView)
    check(after.total == before.total, "repeatable quests never count in the totals")
    local accountView = { tracking = ns.Const.Tracking.ACCOUNT, faction = ns.Player.faction, possible = false,
        key = "test:repeatables:account" }
    local done, source = ns.Quests:RepeatableState(marked, accountView)
    check(done and source == "characters", "the account view sees what a character did")
    ns.Quests:SetRepeatableDone(marked, characterView, false)
    check(ns.Quests:Status(marked, characterView) == ns.Const.Status.REPEATABLE, "unmarking a repeatable quest makes it repeatable again")

    ns.MainFrame:Open("quests", marked)
    local panel = ns.MainFrame.activeView.details
    local offered = false
    for i = 1, panel.used.button or 0 do
        local text = panel.widgets.button[i].label:GetText() or ""
        if text:find(ns.L.MARK_DONE, 1, true) then offered = true end
    end
    check(offered, "the details of a repeatable quest offer to mark it done")
    ns.MainFrame:Back()
end

-- Recipe list: the level of the created item and the rank, sorted by rank, then level
-- (none last), then name.
ns.MainFrame:SelectTab("professions")
local recipesView = ns.MainFrame.activeView
local leveled
for _, profession in ipairs(ns.Professions:List()) do
    for _, recipe in ipairs(profession.recipes) do
        if recipe[R.LEVEL] and not leveled then leveled = recipe end
    end
end
check(leveled ~= nil, "the data has the level the created items ask for")
if leveled then
    ns.MainFrame:Open("professions", leveled[R.SPELL])
    local shown
    for _, row in ipairs(recipesView.recipes.rows) do
        if row:IsShown() and row.item == leveled then shown = row end
    end
    check(shown and shown.level:GetText() == string.format(ns.L.LEVEL_SHORT, leveled[R.LEVEL])
        and shown.rank:GetText() == (leveled[R.MIN_RANK] and string.format(ns.L.RANK_SHORT, leveled[R.MIN_RANK]) or ""),
        "a recipe row shows its level and rank")
    local items = recipesView.recipes.items
    local ordered = true
    for i = 2, #items do
        local a, b = items[i - 1], items[i]
        local rankA, rankB = ns.Professions.ProgressionRank(a), ns.Professions.ProgressionRank(b)
        if rankA > rankB or (rankA == rankB and (a[R.LEVEL] or math.huge) > (b[R.LEVEL] or math.huge)) then
            ordered = false
        end
    end
    check(ordered, "recipes are sorted by rank, then by level, those without a level last")
    check(ns.Professions.ProgressionRank({ [R.TRIVIAL_LOW] = 175 }) == 175
        and ns.Professions.ProgressionRank({ [R.MIN_RANK] = 150, [R.TRIVIAL_LOW] = 175 }) == 150
        and ns.Professions.ProgressionRank({ [R.TRIVIAL_LOW] = 0 }) == math.huge,
        "a recipe without a known rank is placed by the rank it turns yellow at")
    ns.MainFrame:Back()
end

-- Learning ranks: from the recipe items, so that they spread over the profession; a recipe
-- above the character's rank is out of reach.
local ranked, aboveOne = 0, 0
for _, recipe in ipairs(ns.Data.Professions[164].recipes) do
    if recipe[R.MIN_RANK] then
        ranked = ranked + 1
        if recipe[R.MIN_RANK] > 1 then aboveOne = aboveOne + 1 end
    end
end
check(aboveOne * 2 > ranked, "most blacksmithing recipes are learned above rank 1")
local high = { [R.SPELL] = 1, [R.MIN_RANK] = 300 }
check(ns.Professions.RankTooLow(high, 150) and ns.Professions.RankTooLow(high, nil)
    and not ns.Professions.RankTooLow(high, 300) and not ns.Professions.RankTooLow({ [R.SPELL] = 2 }, 1),
    "a recipe is out of reach below its learning rank, and never when that rank is unknown")

-- Item names the server may not answer for are shipped from the client tables, for the
-- recipes' items first.
local firstRecipe = ns.Data.Professions[164].recipes[1]
local shippedItem = firstRecipe and firstRecipe[R.CREATED_ITEM]
check(shippedItem and ns:GameString("items", shippedItem) ~= nil, "the names of the recipes' items are shipped")

-- Slash commands
for _, command in ipairs({ "help", "diag", "log 5", "debug", "debug", "rescan", "scale 1.2", "scale 9", "minimap", "minimap", "nope" }) do
    SlashCmdList.CHRONIQUESAZEROTH(command)
end
Stub.Advance(2)
SlashCmdList.CHRONIQUESAZEROTH("")
check(not frame:IsShown(), "/ca toggles the window closed")

-------------------------------------------------------------------------------
-- Chronicles of Azeroth: the Feedback tab, the minimap button, the saved variables of the
-- versions before 0.26
-------------------------------------------------------------------------------

-- Text sizes follow the size the client gives its standard text.
check(ns.Theme.FontSize(13) == 13, "text keeps its size with the default client font")
Stub.fontSize = 10
check(ns.Theme.FontSize(12) == 10 and ns.Theme.FontSize(18) == 15, "text follows a smaller client font")
Stub.fontSize = 12

-- The report gathers the version, the character, the tab shown before and the last log lines.
SlashCmdList.CHRONIQUESAZEROTH("")
ns.MainFrame:SelectTab("quests")
ns.MainFrame:SelectTab("feedback")
local feedbackView = ns.MainFrame.activeView
local prepare
for _, widget in ipairs(Stub.Descendants(feedbackView.frame)) do
    if widget.label and widget.label:GetText() == ns.L.PREPARE_REPORT then prepare = widget end
end
check(prepare ~= nil, "the Feedback tab offers to prepare the report")
if prepare then prepare:Click() end
local report = feedbackView.edit:GetText() or ""
check(report:find(ns.Compat.GetAddOnVersion(), 1, true) and report:find(ns.Player.key, 1, true)
    and report:find("quests", 1, true) and report:find("github.com/Rincevant/chronicles-of-azeroth", 1, true),
    "the report tells the version, the character, the tab shown before and where to send it")
check(ns.Database:Character().feedbackDraft == report, "the report is kept for the character")
-- A report taller than its box scrolls, and the cursor going down brings its line into view.
local reportScroll = feedbackView.scroll
reportScroll._scrollRange = 3000
reportScroll:GetScript("OnScrollRangeChanged")(reportScroll)
check(reportScroll.bar:IsShown(), "a report taller than its box shows a scroll bar")
feedbackView.edit:GetScript("OnCursorChanged")(feedbackView.edit, 0, -2500, 1, 14)
check(reportScroll:GetVerticalScroll() > 0, "the box scrolls to keep the cursor in view")

-- A right click on the minimap button switches the tracking mode.
local minimapButton = ChroniquesAzerothMinimapButton
local trackingBefore = ns.Database:Settings().tracking
minimapButton:GetScript("OnClick")(minimapButton, "RightButton")
check(ns.Database:Settings().tracking ~= trackingBefore, "a right click on the minimap button switches the tracking")
minimapButton:GetScript("OnClick")(minimapButton, "RightButton")
check(ns.Database:Settings().tracking == trackingBefore, "a second right click switches it back")
SlashCmdList.CHRONIQUESAZEROTH("")

-- The addon compartment, declared in the TOC, opens and closes the window.
local compartment = {}
for line in io.lines(ADDON .. "/" .. ADDON .. ".toc") do
    local field, value = (line:gsub("\r", "")):match("^## (AddonCompartmentFunc%a*): (%S+)")
    if field then compartment[field] = value end
end
check(compartment.AddonCompartmentFunc and _G[compartment.AddonCompartmentFunc]
    and _G[compartment.AddonCompartmentFuncOnEnter] and _G[compartment.AddonCompartmentFuncOnLeave],
    "the TOC declares the addon compartment functions the addon defines")
local wasShown = frame:IsShown()
_G[compartment.AddonCompartmentFunc]()
check(frame:IsShown() ~= wasShown, "the addon compartment toggles the window")
_G[compartment.AddonCompartmentFunc]()

-- The saved variables of a version before 0.26 become the records of their characters.
do
    local current, currentCharacter = ChroniquesAzerothDB, ChroniquesAzerothCharacterDB
    ChroniquesAzerothDB = {
        schemaVersion = 2, trackingMode = "account", minimapAngle = 123,
        completed = { [7] = 1600000000 }, legacyCompleted = { [1] = 1600000000 },
        characters = { ["Old-Realm"] = { name = "Old", realm = "Realm", completed = { [7] = 1600000000, [33] = 1600000000 } } },
        professionCharacters = { ["Old-Realm"] = { [164] = { recipes = { ["2660"] = { learned = true }, ["2661"] = { learned = false } } } } },
    }
    ChroniquesAzerothCharacterDB = { professions = { [185] = { recipes = { ["2538"] = { learned = true } } } }, feedbackDraft = "draft" }
    ns.Database:Initialize()
    local old = ChroniquesAzerothDB.characters["Old-Realm"]
    check(old and old.quests[7] and old.quests[33], "the quests of a former character are kept")
    check(old and old.recipes[2660] and not old.recipes[2661], "the learned recipes of a former character are kept")
    check(ChroniquesAzerothDB.settings.tracking == "account" and ChroniquesAzerothDB.settings.minimap.angle == 123,
        "the tracking mode and the minimap button carry over")
    check(ChroniquesAzerothDB.schemaVersion == nil and ChroniquesAzerothDB.completed == nil, "the former fields are dropped")
    ns.Database:TouchCharacter()
    check(ns.Database:Character().recipes[2538] and ns.Database:Character().feedbackDraft == "draft",
        "the recipes and draft saved for the character join its record")
    check(ChroniquesAzerothCharacterDB == nil, "the former character saved variables are emptied")
    ChroniquesAzerothDB, ChroniquesAzerothCharacterDB = current, currentCharacter
    ns.Database:Initialize()
    ns.Database:TouchCharacter()
end

-------------------------------------------------------------------------------
-- Localization completeness
-------------------------------------------------------------------------------

local function localeTable(path, locale)
    local captured
    local fakeNs = { RegisterLocale = function(_, _, strings) captured = strings end }
    local savedGetLocale = GetLocale
    GetLocale = function() return locale end
    assert(loadfile(path))(ADDON, fakeNs)
    GetLocale = savedGetLocale
    return captured
end

local english = localeTable(ADDON .. "/Locales/enUS.lua", "enUS")
local french = localeTable(ADDON .. "/Locales/frFR.lua", "frFR")
for key in pairs(english) do check(french[key] ~= nil, "frFR lacks %s", key) end
for key in pairs(french) do check(english[key] ~= nil, "frFR has %s, unknown in enUS", key) end
-- French typography: no ordinary space before : ; ! ? » nor after «, which a line could
-- otherwise start or end with.
for key, value in pairs(french) do
    if type(value) == "string" then
        for _, sequence in ipairs({ " :", " ;", " !", " ?", " \194\187", "\194\171 " }) do
            check(not value:find(sequence, 1, true), "frFR %s has an ordinary space where a no-break one belongs", key)
        end
    end
end

-------------------------------------------------------------------------------
-- Result
-------------------------------------------------------------------------------

for _, entry in ipairs(errorsInLog()) do fail("logged: %s", entry) end
io.write(string.format("[%s] %d files loaded, %d log entries, %d failures", GetLocale(), fileCount,
    #ChroniquesAzerothDB.log.entries, failures) .. "\n")
if os.getenv("CA_TEST_VERBOSE") then
    for _, entry in ipairs(ChroniquesAzerothDB.log.entries) do io.write(entry, "\n") end
end
if failures > 0 then os.exit(1) end
