-- Quest list and quest details, shared by the quest, dungeon and raid views.

local _, ns = ...

local QuestWidgets = {}
ns.QuestWidgets = QuestWidgets

local L = ns.L
local UI, Theme = ns.UI, ns.Theme
local C = Theme.colors
local Q, Status, Flag, Entity = ns.Const.Quest, ns.Const.Status, ns.Const.QuestFlag, ns.Const.Entity

QuestWidgets.STATUS_COLORS = {
    [Status.DONE] = C.green,
    [Status.ACTIVE] = C.yellow,
    [Status.AVAILABLE] = C.text,
    [Status.LOCKED] = C.gray,
    [Status.REPEATABLE] = C.blue,
    [Status.IGNORED] = C.gray,
}

local function questName(questID)
    local name = ns.Names.Quest(questID)
    if name then return name end
    -- A prerequisite outside the catalogue has no fallback name.
    return ns.Data.Quests[questID] and L.LOADING or ("#" .. questID)
end

-- Level range text: "Lvl 6-8" or "Lvl 9".
function QuestWidgets.LevelText(low, high)
    if not low then return "" end
    if high and high ~= low then return string.format(L.LEVEL_RANGE, low, high) end
    return string.format(L.LEVEL_SHORT, low)
end

-------------------------------------------------------------------------------
-- List items: chains (expandable) and quests
-------------------------------------------------------------------------------

-- Prefix ending with a colon that most titles of a list share, such as the "Craftsman's
-- Writ:" of the crafting orders: the rows then show what tells the quests apart.
local function sharedPrefix(chains)
    local counts, named = {}, 0
    for _, chain in ipairs(chains) do
        for _, questID in ipairs(chain) do
            local name = ns.Names.Quest(questID)
            if name then
                named = named + 1
                local prefix = name:match("^(.-%s?:%s+)%S")
                if prefix then counts[prefix] = (counts[prefix] or 0) + 1 end
            end
        end
    end
    for prefix, count in pairs(counts) do
        if count >= 3 and count * 2 >= named then return prefix end
    end
    return nil
end

-- Turns chains into list items for a view. `expanded[rootID]` opens a chain. A state
-- `filter` (UI.StateFilter) narrows the quests listed; the counts keep them all. The
-- `forced` quest, which a link leads to, is listed whatever the view and the filters hide,
-- and its chain is opened.
function QuestWidgets.BuildItems(chains, view, expanded, query, filter, forced)
    local items = {}
    local prefix = sharedPrefix(chains)
    for _, chain in ipairs(chains) do
        local summary = ns.Quests:ChainSummary(chain, view)
        local visible = summary.quests
        if filter then
            local kept = {}
            for _, questID in ipairs(visible) do
                local status = ns.Quests:Status(questID, view)
                -- An ignored quest is not to be done: "to do" leaves it out.
                if filter:Keeps(status == Status.DONE) and not (filter.value == "todo" and status == Status.IGNORED) then
                    kept[#kept + 1] = questID
                end
            end
            visible = kept
        end
        if query and query ~= "" then
            local matching = {}
            for _, questID in ipairs(visible) do
                if UI.Matches(ns.Names.Quest(questID) or "", query) then matching[#matching + 1] = questID end
            end
            visible = matching
        end
        local holdsForced = false
        if forced then
            for _, questID in ipairs(chain) do
                if questID == forced then holdsForced = true end
            end
        end
        if holdsForced then
            local kept = {}
            for _, questID in ipairs(visible) do kept[questID] = true end
            visible = {}
            for _, questID in ipairs(chain) do
                if kept[questID] or questID == forced then visible[#visible + 1] = questID end
            end
            if #visible > 1 then expanded[visible[1]] = true end
        end
        if #visible == 1 then
            items[#items + 1] = { kind = "quest", id = visible[1], prefix = prefix }
        elseif #visible > 1 then
            local root = visible[1]
            local open = expanded[root] or (query and query ~= "")
            items[#items + 1] = { kind = "chain", id = root, summary = summary, open = open, prefix = prefix }
            if open then
                for _, questID in ipairs(visible) do
                    items[#items + 1] = { kind = "quest", id = questID, indent = true, prefix = prefix }
                end
            end
        end
    end
    return items
end

-- Upper case first letter, including the accented letters of Latin-1 (two bytes in UTF-8,
-- which the client's string.upper leaves as they are).
local function capitalize(text)
    local first, second = text:byte(1, 2)
    if first and first >= 97 and first <= 122 then
        return string.char(first - 32) .. text:sub(2)
    end
    if first == 0xC3 and second and second >= 0xA0 and second <= 0xBE and second ~= 0xB7 then
        return string.char(0xC3, second - 0x20) .. text:sub(3)
    end
    return text
end

local function rowName(item)
    local name = questName(item.id)
    if item.prefix and name:sub(1, #item.prefix) == item.prefix then return capitalize(name:sub(#item.prefix + 1)) end
    return name
end

-- Builds the widgets of one list row.
function QuestWidgets.BuildRow(row)
    UI.DecorateRow(row)
    row.expand = UI.ExpandBox(row, 18)
    row.expand:SetPoint("LEFT", 8, 0)
    row.marker = UI.Glyph(row, "arrow", 12, C.yellow)
    row.marker:SetPoint("LEFT", 12, 0)
    row.name = UI.Text(row, 13)
    row.level = UI.Text(row, 11, C.goldDim, "body", "RIGHT")
    row.level:SetWidth(70)
    row.right = UI.Text(row, 11, C.text, "body", "RIGHT")
    row.right:SetWidth(60)
    row.check = UI.Glyph(row, "check", 16, C.green)
    row.check:SetPoint("RIGHT", -6, 0)
    row.right:SetPoint("RIGHT", row.check, "LEFT", -6, 0)
    row.level:SetPoint("RIGHT", row.right, "LEFT", -8, 0)
    row.name:SetPoint("RIGHT", row.level, "LEFT", -6, 0)
end

-- Shows an item in a row; `selected` is the selected quest id.
function QuestWidgets.FillRow(row, item, view, selected)
    local isChain = item.kind == "chain"
    row.expand:SetShown(isChain)
    row.name:ClearAllPoints()
    row.name:SetPoint("RIGHT", row.level, "LEFT", -6, 0)
    row.name:SetPoint("LEFT", row, "LEFT", 34 + (item.indent and 14 or 0), 0)

    if isChain then
        local summary = item.summary
        row.expand:SetExpanded(item.open)
        row.name:SetText(rowName(item))
        local complete = summary.total > 0 and summary.done >= summary.total
        row.name:SetTextColor(Theme.Unpack(complete and C.green or C.gold))
        row.level:SetText(QuestWidgets.LevelText(summary.low, summary.high))
        row.right:SetText(string.format("%d / %d", summary.done, summary.total))
        row.right:SetTextColor(Theme.Unpack(complete and C.green or C.text))
        row.check:Hide()
        row.marker:Hide()
        row:SetState(false, { bg = { 0.13, 0.09, 0.05, 0.95 }, border = C.borderDim })
        return
    end

    local quest = ns.Data.Quests[item.id]
    local status = ns.Quests:Status(item.id, view)
    row.name:SetText(rowName(item))
    row.name:SetTextColor(Theme.Unpack(QuestWidgets.STATUS_COLORS[status] or C.text))
    row.level:SetText(QuestWidgets.LevelText(quest[Q.LEVEL]))
    local xp = quest[Q.XP]
    row.right:SetText(xp and string.format(L.XP_SHORT, xp) or "")
    row.right:SetTextColor(Theme.Unpack(C.textDim))
    row.check:SetShown(status == Status.DONE)
    row.marker:SetShown(status == Status.ACTIVE)
    row:SetState(selected == item.id)
end

-------------------------------------------------------------------------------
-- Details
-------------------------------------------------------------------------------

local followers -- [questID] = { quests that require it }

local function followersOf(questID)
    if not followers then
        followers = {}
        local function add(from, to)
            followers[from] = followers[from] or {}
            table.insert(followers[from], to)
        end
        for id, row in pairs(ns.Data.Quests) do
            for _, pre in ipairs(row[Q.PRE_ALL] or {}) do add(pre, id) end
            for _, pre in ipairs(row[Q.PRE_ANY] or {}) do add(pre, id) end
        end
        for id, row in pairs(ns.Data.Quests) do
            local nextID = row[Q.NEXT]
            if nextID then
                local list = followers[id]
                local present = false
                for _, existing in ipairs(list or {}) do if existing == nextID then present = true end end
                if not present then add(id, nextID) end
            end
        end
        for _, list in pairs(followers) do table.sort(list) end
    end
    return followers[questID]
end

local QUEST_LINK_TOOLTIPS = { quests = "LINK_QUEST", dungeons = "LINK_DUNGEON_QUEST", raids = "LINK_RAID_QUEST" }

-- A link to a quest, in whichever tab lists it; a quest outside the catalogue keeps the
-- look of a link and says it is missing.
function QuestWidgets.QuestLink(panel, label, questID, indent)
    local tab = ns.MainFrame:QuestTab(questID)
    panel:LinkLine(label, questName(questID), tab and function() ns.MainFrame:Open(tab, questID) end or nil,
        tab and L[QUEST_LINK_TOOLTIPS[tab]] or L.LINK_MISSING, indent)
end

-- Links to several quests: on the label's line for one, one per line under it for more.
local function questLinks(panel, label, ids)
    if #ids == 1 then
        QuestWidgets.QuestLink(panel, label, ids[1])
        return
    end
    panel:Line(label, C.goldDim, 12)
    for _, id in ipairs(ids) do QuestWidgets.QuestLink(panel, "", id, 12) end
end

-- A link to a profession, with the rank it asks for when given.
local function professionLink(panel, label, skillLine, rank)
    local name = ns.Names.SkillLine(skillLine) or ("#" .. skillLine)
    if rank then name = string.format("%s (%d)", name, rank) end
    local listed = ns.Data.Professions[skillLine] ~= nil
    panel:LinkLine(label, name, listed and function() ns.MainFrame:Open("professions", { skillLine = skillLine }) end or nil,
        listed and L.LINK_PROFESSION or L.LINK_MISSING)
end

-- The note of a quest a link shows although the view or the state `filter` hides it, or nil.
function QuestWidgets.HiddenNote(questID, view, filter)
    local status = ns.Quests:Status(questID, view)
    local filtered = filter and (not filter:Keeps(status == Status.DONE) or (filter.value == "todo" and status == Status.IGNORED))
    if filtered or not ns.Quests:IsVisible(questID, view) then return L.SHOWN_DESPITE_FILTERS end
    return nil
end

local function statusText(status, reason)
    if status == Status.DONE then
        if reason == "exclusive" then return L.STATUS_CLOSED end
        if reason == "breadcrumb" then return L.STATUS_SKIPPED end
        return L.STATUS_DONE
    end
    if status == Status.LOCKED then
        if reason == "level" then return L.STATUS_LOCKED_LEVEL end
        if reason == "skill" then return L.STATUS_LOCKED_SKILL end
        return L.STATUS_LOCKED_PREREQ
    end
    return L["STATUS_" .. status:upper()]
end

-- Location of a giver: uiMapID, x, y, area name — or nil.
local function locate(entity)
    if not entity then return nil end
    local row
    if entity[1] == Entity.NPC then row = ns.Data.Npcs[entity[2]]
    elseif entity[1] == Entity.OBJECT then row = ns.Data.Objects[entity[2]] end
    local place = row and row[2]
    if not place then return nil end
    return place[4], place[2], place[3], ns.Names.Area(place[1])
end

local function entityLine(panel, label, entity)
    local name = ns.Names.Entity(entity)
    if not name then return end
    local uiMap, x, y, areaName = locate(entity)
    local text = string.format("%s %s", Theme.Colorize(label, C.goldDim), name)
    if areaName then text = text .. Theme.Colorize(string.format(" (%s %.0f, %.0f)", areaName, x, y), C.textDim) end
    panel:Line(text)
    if uiMap then
        panel:Button(L.SHOW_ON_MAP, function()
            if ns.Compat.SetWaypoint(uiMap, x, y) then
                ns.Log:Debug("Waypoint set on map %d at %.1f, %.1f", uiMap, x, y)
                print(string.format("|cffffd200%s|r: %s", L.ADDON_TITLE, string.format(L.WAYPOINT_SET, name)))
            else
                ns.Log:Info("Waypoint unavailable on map %s", tostring(uiMap))
                print(string.format("|cffffd200%s|r: %s", L.ADDON_TITLE, L.WAYPOINT_UNAVAILABLE))
            end
        end)
    end
end

-- Fills a detail panel with everything known about a quest; `note`, when given, is shown
-- under its status.
function QuestWidgets.ShowDetails(panel, questID, view, note)
    panel:Clear("quest:" .. tostring(questID))
    local quest = ns.Data.Quests[questID]
    if not quest then
        panel:Line(L.SELECT_QUEST, C.textDim)
        panel:Finish()
        return
    end
    local status, reason = ns.Quests:Status(questID, view)
    panel:Line(questName(questID), C.gold, 20, "fancy")
    local levelText = string.format(L.QUEST_LEVEL_LINE, quest[Q.LEVEL], quest[Q.MIN_LEVEL])
    panel:Line(string.format("%s  ·  %s", Theme.Colorize(statusText(status, reason):upper(), QuestWidgets.STATUS_COLORS[status] or C.text),
        Theme.Colorize(levelText, C.green)), C.text, 13)

    local flags = quest[Q.FLAGS]
    local notes = {}
    if ns.Quests.HasFlag(flags, Flag.DAILY) then notes[#notes + 1] = L.FLAG_DAILY end
    if ns.Quests.HasFlag(flags, Flag.WEEKLY) then notes[#notes + 1] = L.FLAG_WEEKLY end
    if ns.Quests.HasFlag(flags, Flag.REPEATABLE) and #notes == 0 then notes[#notes + 1] = L.FLAG_REPEATABLE end
    if ns.Quests.HasFlag(flags, Flag.EVENT) then notes[#notes + 1] = L.FLAG_EVENT end
    if ns.Quests.HasFlag(flags, Flag.BREADCRUMB) then notes[#notes + 1] = L.FLAG_BREADCRUMB end
    if #notes > 0 then panel:Line(table.concat(notes, "  ·  "), C.blue, 11) end
    if note then panel:Line(note, C.orange, 11) end

    -- Ignoring a quest takes it out of the counts of the current view, until it is undone.
    if status ~= Status.DONE then
        local ignored, source = ns.Quests:IgnoreState(questID, view)
        if ignored then
            panel:Line(source == "account" and L.IGNORED_FOR_ACCOUNT or L.IGNORED_FOR_CHARACTER, C.gray, 11)
        end
        local account = view.tracking == ns.Const.Tracking.ACCOUNT
        local label = ignored and L.UNIGNORE_QUEST or L.IGNORE_QUEST
        panel:Button(string.format("%s (%s)", label, account and L.TRACKING_ACCOUNT or L.TRACKING_CHARACTER), function()
            ns.Quests:SetIgnored(questID, view, not ignored)
        end)
    end
    -- A repeatable quest is marked done by hand: the server does not remember it.
    if ns.Quests.IsRepeating(quest) then
        local done, source = ns.Quests:RepeatableState(questID, view)
        local scope = view.tracking == ns.Const.Tracking.ACCOUNT and L.TRACKING_ACCOUNT or L.TRACKING_CHARACTER
        if done and source == "characters" then
            panel:Line(L.REPEATABLE_DONE_BY_CHARACTER, C.gray, 11)
        elseif done or status ~= Status.DONE then
            panel:Button(string.format("%s (%s)", done and L.UNMARK_DONE or L.MARK_DONE, scope), function()
                ns.Quests:SetRepeatableDone(questID, view, not done)
            end)
        end
    end
    panel:Space(6)

    local prerequisites = {}
    for _, id in ipairs(quest[Q.PRE_ALL] or {}) do prerequisites[#prerequisites + 1] = id end
    for _, id in ipairs(quest[Q.PRE_ANY] or {}) do prerequisites[#prerequisites + 1] = id end
    if #prerequisites == 0 then
        panel:Line(string.format("%s %s", Theme.Colorize(L.PREREQUISITES, C.goldDim), L.NONE), C.text, 12)
    else
        questLinks(panel, L.PREREQUISITES, prerequisites)
        if quest[Q.PRE_ANY] and #quest[Q.PRE_ANY] > 1 then panel:Line(L.PREREQUISITES_ANY, C.textDim, 11) end
    end
    local nextQuests = followersOf(questID)
    if nextQuests then questLinks(panel, L.FOLLOW_UPS, nextQuests) end
    if quest[Q.EXCLUSIVE] then questLinks(panel, L.EXCLUSIVE_WITH, quest[Q.EXCLUSIVE]) end
    if quest[Q.BREADCRUMB_FOR] then QuestWidgets.QuestLink(panel, L.LEADS_TO, quest[Q.BREADCRUMB_FOR]) end
    local skill = quest[Q.SKILL]
    if skill then professionLink(panel, L.REQUIRES, skill[1], skill[2]) end
    -- A crafting order asks for an item made by a profession.
    if quest[Q.CRAFT] then professionLink(panel, L.ORDER_PROFESSION, quest[Q.CRAFT]) end

    panel:Space(4)
    entityLine(panel, L.GIVER, quest[Q.GIVER])
    if quest[Q.ENDER] and not (quest[Q.GIVER] and quest[Q.ENDER][1] == quest[Q.GIVER][1] and quest[Q.ENDER][2] == quest[Q.GIVER][2]) then
        entityLine(panel, L.ENDER, quest[Q.ENDER])
    end

    local rewards = {}
    if quest[Q.XP] then rewards[#rewards + 1] = string.format(L.XP_LINE, quest[Q.XP]) end
    for _, reputation in ipairs(quest[Q.REPUTATION] or {}) do
        local faction = ns.Names.Faction(reputation[1])
        if faction then rewards[#rewards + 1] = string.format(L.REPUTATION_LINE, reputation[2], faction) end
    end
    local recipes = ns.Professions:RecipesRewardedBy(questID)
    if #rewards > 0 or #recipes > 0 then
        panel:Heading(L.REWARDS)
        for _, line in ipairs(rewards) do panel:Line(line, C.text, 12) end
        for _, spellID in ipairs(recipes) do
            local recipe = ns.Professions:Recipe(spellID)
            panel:LinkLine(L.REWARD_RECIPE, recipe and ns.Professions.RecipeName(recipe) or L.LOADING,
                function() ns.MainFrame:Open("professions", spellID) end, L.LINK_RECIPE)
        end
    end

    if status == Status.ACTIVE then
        local objectives = ns.Compat.GetQuestObjectives(questID)
        if objectives then
            panel:Heading(L.OBJECTIVES)
            for _, objective in ipairs(objectives) do
                panel:Line(objective.text, objective.finished and C.green or C.text, 12)
            end
        end
    end
    panel:Finish()
end
