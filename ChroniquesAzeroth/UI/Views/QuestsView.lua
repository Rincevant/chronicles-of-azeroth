-- Quests tab: zones on the left, the zone summary and the selected quest in the middle,
-- the zone's quest chains on the right.

local _, ns = ...

local View = {}
ns.Views.Quests = View

local L = ns.L
local UI, Theme, Layout, QuestWidgets = ns.UI, ns.Theme, ns.Layout, ns.QuestWidgets
local C = Theme.colors
local Continent = ns.Const.Continent

local GROUP_BUTTONS = {
    { value = "ek", label = "CONTINENT_EASTERN_KINGDOMS", continents = { Continent.EASTERN_KINGDOMS } },
    { value = "kalimdor", label = "CONTINENT_KALIMDOR", continents = { Continent.KALIMDOR } },
    { value = "other", label = "CONTINENT_OTHER", continents = { Continent.OTHER, Continent.BATTLEGROUNDS } },
    { value = "categories", label = "CONTINENT_CATEGORIES", continents = { Continent.CATEGORIES } },
}


-------------------------------------------------------------------------------
-- Zone cards
-------------------------------------------------------------------------------

-- Artwork of a zone or a category: the one the addon ships for it, a quest category of a
-- profession showing that of its profession; without one, the card stays plain.
local function ShowGroupArt(art, group, banner)
    local own
    if group.kind == "zone" then
        own = (banner and Theme.bannerArt[group.id]) or Theme.zoneArt[group.id]
    else
        own = Theme.categoryArt[group.id] or (group.skill and Theme.professionArt[group.skill])
    end
    if own and art:SetFile(own, Theme.ZONE_ART_RATIO) then return end
    art:Clear()
end

local function buildZoneCard(row)
    UI.ArtCard(row)
end

function View:FillZoneCard(row, group)
    local summary = ns.Quests:Summary(group.kind .. ":" .. group.id, group.chains, self.mainFrame:View())
    row.name:SetText(ns.Quests:GroupName(group))
    row.count:SetText(string.format("%d / %d", summary.done, summary.total))
    local complete = summary.total > 0 and summary.done >= summary.total
    row.count:SetTextColor(Theme.Unpack(complete and C.green or C.text))
    row.levels:SetText(group.levels and QuestWidgets.LevelText(group.levels[1], group.levels[2]) or "")
    ShowGroupArt(row.art, group)
    local selected = self.selectedGroup == group
    row.border:SetColor(selected and C.gold or (complete and C.greenBorder or C.borderDim))
    row:SetScript("OnClick", function()
        ns.MainFrame:ForgetHistory()
        self:SelectGroup(group)
    end)
end

-------------------------------------------------------------------------------
-- Construction
-------------------------------------------------------------------------------

function View:Build(frame)
    self.expanded = {}
    self.query = ""
    local page = Layout.Page(frame, {
        groupsTitle = L.ZONES,
        -- The continent buttons, two per line, above the zone search.
        controlsHeight = 68,
        buildControls = function(left, top)
            local groupButtons = {}
            local buttonWidth = math.floor((Layout.LEFT_WIDTH - 32 - 6) / 2)
            for index, option in ipairs(GROUP_BUTTONS) do
                local button = UI.Button(left, buttonWidth, 26, L[option.label], function()
                    ns.MainFrame:ForgetHistory()
                    self:SelectContinent(option.value)
                end)
                local column, line = (index - 1) % 2, math.floor((index - 1) / 2)
                button:SetPoint("TOPLEFT", 16 + column * (buttonWidth + 6), top - line * 32)
                button.value = option.value
                groupButtons[#groupButtons + 1] = button
            end
            self.groupButtons = groupButtons
        end,
        groupSearch = L.SEARCH_ZONE,
        onGroupSearch = function(text)
            self.zoneQuery = text
            self:RefreshZones()
        end,
        buildGroup = buildZoneCard,
        fillGroup = function(row, group) self:FillZoneCard(row, group) end,
        detailsTitle = L.SELECTED_QUEST,
        itemSearch = L.SEARCH_QUEST,
        onItemSearch = function(text)
            self.query = text
            self:RefreshQuests()
        end,
        filterKey = "quests",
        onFilter = function()
            self.quests.offset = 0
            self:RefreshQuests()
        end,
        buildItem = QuestWidgets.BuildRow,
        fillItem = function(row, item)
            QuestWidgets.FillRow(row, item, self.mainFrame:View(), self.selectedQuest)
            row:SetScript("OnClick", function() self:OnQuestClick(item) end)
        end,
    })
    self.page = page
    self.zones, self.quests, self.stateFilter = page.groups, page.items, page.filters
    self.centerTitle, self.banner, self.details = page.title, page.banner, page.details
    self.rightTitle, self.questFooter = page.itemsTitle, page.footer

    self:SelectContinent(self:InitialContinent(), true)
end

-------------------------------------------------------------------------------
-- Selection
-------------------------------------------------------------------------------

-- Starts on the zone the player is in. The client reports the most precise map, which may
-- be a building or a cave inside the zone: its parents are tried in turn.
function View:InitialContinent()
    local maps = ns.Compat.GetPlayerMaps()
    local byMap = {}
    for _, groups in pairs(ns.Quests:Groups()) do
        for _, group in ipairs(groups) do
            -- A category shows the map of a place it is not.
            if group.uiMap and group.continent ~= Continent.CATEGORIES then byMap[group.uiMap] = group end
        end
    end
    for _, uiMap in ipairs(maps) do
        local group = byMap[uiMap]
        if group then
            for _, option in ipairs(GROUP_BUTTONS) do
                for _, continent in ipairs(option.continents) do
                    if continent == group.continent then
                        self.selectedGroup = group
                        return option.value
                    end
                end
            end
        end
    end
    ns.Log:Info("No quest zone matches the player's maps [%s]", table.concat(maps, ", "))
    return ns.Player.faction == ns.Const.Faction.HORDE and "kalimdor" or "ek"
end

function View:GroupsOf(continentValue)
    self.sortedGroups = self.sortedGroups or {}
    if self.sortedGroups[continentValue] then return self.sortedGroups[continentValue] end
    local option
    for _, candidate in ipairs(GROUP_BUTTONS) do
        if candidate.value == continentValue then option = candidate end
    end
    local groups = {}
    local all = ns.Quests:Groups()
    for _, continent in ipairs(option.continents) do
        for _, group in ipairs(all[continent] or {}) do groups[#groups + 1] = group end
    end
    UI.SortByLevel(groups, function(group) return group.levels end, function(group) return ns.Quests:GroupName(group) end)
    self.sortedGroups[continentValue] = groups
    return groups
end

function View:SetContinent(value)
    self.continent = value
    for _, button in ipairs(self.groupButtons) do button:SetActive(button.value == value) end
end

function View:SelectContinent(value, initial)
    self:SetContinent(value)
    local groups = self:GroupsOf(value)
    local keep = false
    for _, group in ipairs(groups) do
        if group == self.selectedGroup then keep = true end
    end
    -- Without the player's zone, the first zone that has quests for the current view.
    if not keep then
        local view = self.mainFrame:View()
        self.selectedGroup = groups[1]
        for _, group in ipairs(groups) do
            if ns.Quests:Summary(group.kind .. ":" .. group.id, group.chains, view).total > 0 then
                self.selectedGroup = group
                break
            end
        end
    end
    self:RefreshZones()
    self:SelectGroup(self.selectedGroup, initial)
end

-- Groups of the current continent that match the zone search, with a summary that
-- hides zones without visible quests for the current view.
function View:VisibleGroups()
    local view = self.mainFrame:View()
    local result = {}
    for _, group in ipairs(self:GroupsOf(self.continent)) do
        if UI.Matches(ns.Quests:GroupName(group), self.zoneQuery) then
            local summary = ns.Quests:Summary(group.kind .. ":" .. group.id, group.chains, view)
            if summary.total > 0 or group == self.selectedGroup then result[#result + 1] = group end
        end
    end
    return result
end

function View:RefreshZones()
    self.zones:SetItems(self:VisibleGroups(), true)
end

function View:SelectGroup(group, initial)
    if group ~= self.selectedGroup then
        self.selectedQuest, self.forcedQuest = nil, nil
    end
    self.selectedGroup = group
    if group then
        local ids = {}
        for _, chain in ipairs(group.chains) do
            for _, questID in ipairs(chain) do ids[#ids + 1] = questID end
        end
        ns.Names.Prefetch(ids)
        if not initial then ns.Log:Debug("Zone %s:%d selected (%d quests)", group.kind, group.id, #ids) end
    end
    self.quests.offset = 0
    self:Refresh()
end

-- Opening or closing a chain only changes how the list looks; selecting a quest is
-- navigating, which forgets where links were followed from.
function View:OnQuestClick(item)
    if item.kind == "chain" then
        self.expanded[item.id] = not self.expanded[item.id]
    else
        ns.MainFrame:ForgetHistory()
    end
    if item.id ~= self.forcedQuest then self.forcedQuest = nil end
    self.selectedQuest = item.id
    self:RefreshQuests()
    self:ShowQuest(item.id)
end

-- Details of a quest, telling when a link shows it although the view or the filters hide it.
function View:ShowQuest(questID)
    local view = self.mainFrame:View()
    local note = questID == self.forcedQuest and QuestWidgets.HiddenNote(questID, view, self.stateFilter) or nil
    QuestWidgets.ShowDetails(self.details, questID, view, note)
end

-------------------------------------------------------------------------------
-- Links
-------------------------------------------------------------------------------

local function indexOf(items, matches)
    for index, item in ipairs(items) do
        if matches(item) then return index end
    end
    return nil
end

-- Shows a quest a link leads to: its continent and zone, the quest selected and both lists
-- scrolled to them. The searches are cleared so that they do not hide it.
function View:Reveal(questID)
    local group = ns.Quests:GroupOf(questID)
    if not group then return false end
    for _, option in ipairs(GROUP_BUTTONS) do
        for _, continent in ipairs(option.continents) do
            if continent == group.continent then self:SetContinent(option.value) end
        end
    end
    self.zoneQuery, self.query = "", ""
    self.page.groupSearch:SetText("")
    self.page.itemSearch:SetText("")
    self:SelectGroup(group)
    self.selectedQuest, self.forcedQuest = questID, questID
    self:Refresh()
    local zoneIndex = indexOf(self.zones.items, function(item) return item == group end)
    if zoneIndex then self.zones:Reveal(zoneIndex) end
    local questIndex = indexOf(self.quests.items, function(item) return item.kind == "quest" and item.id == questID end)
    if questIndex then self.quests:Reveal(questIndex) end
    return true
end

-- Where the view stands, for the Back button.
function View:Location()
    local back
    if self.selectedQuest then
        back = string.format(L.BACK_TO_QUEST, ns.Names.Quest(self.selectedQuest) or ("#" .. self.selectedQuest))
    elseif self.selectedGroup then
        back = string.format(self.selectedGroup.kind == "sort" and L.BACK_TO_CATEGORY or L.BACK_TO_ZONE,
            ns.Quests:GroupName(self.selectedGroup))
    end
    return { back = back, continent = self.continent, group = self.selectedGroup, quest = self.selectedQuest,
        forced = self.forcedQuest, zonesOffset = self.zones.offset, questsOffset = self.quests.offset }
end

function View:Restore(location)
    self:SetContinent(location.continent)
    self.selectedGroup, self.selectedQuest, self.forcedQuest = location.group, location.quest, location.forced
    self.zones.offset, self.quests.offset = location.zonesOffset, location.questsOffset
    self:Refresh()
end

-------------------------------------------------------------------------------
-- Refresh
-------------------------------------------------------------------------------

function View:RefreshQuests()
    local group = self.selectedGroup
    if not group then
        self.quests:SetItems({})
        return
    end
    local view = self.mainFrame:View()
    local items = QuestWidgets.BuildItems(group.chains, view, self.expanded, self.query, self.stateFilter, self.forcedQuest)
    self.quests:SetItems(items, true)
    local summary = ns.Quests:Summary(group.kind .. ":" .. group.id, group.chains, view)
    self.questFooter:SetText(string.format(L.QUESTS_FOOTER, summary.done, summary.total, summary.total - summary.done))
end

function View:Refresh()
    local view = self.mainFrame:View()
    self:RefreshZones()
    local group = self.selectedGroup
    if not group then
        self.centerTitle:SetText("")
        self.rightTitle:SetText(L.QUESTS:upper())
        self.details:Clear()
        self.details:Finish()
        return
    end
    local name = ns.Quests:GroupName(group)
    self.centerTitle:SetText(name)
    self.rightTitle:SetText(string.format(L.QUESTS_OF, name):upper())

    local summary = ns.Quests:Summary(group.kind .. ":" .. group.id, group.chains, view)
    local banner = self.banner
    banner.name:SetText(name:upper())
    local continentName = L[GROUP_BUTTONS[1].label]
    for _, option in ipairs(GROUP_BUTTONS) do
        if option.value == self.continent then continentName = L[option.label] end
    end
    local factionName = view.faction == ns.Const.Faction.HORDE and L.FACTION_HORDE or L.FACTION_ALLIANCE
    banner.subtitle:SetText(string.format("%s  ·  %s", continentName, factionName))
    local trackingName = view.tracking == ns.Const.Tracking.ACCOUNT and L.TRACKING_ACCOUNT or L.TRACKING_CHARACTER
    banner.caption:SetText(string.format(L.QUESTS_CAPTION, summary.done, summary.total, trackingName))
    banner.ring:SetProgress(summary.done, summary.total, summary.total > 0 and summary.done >= summary.total and L.COMPLETE or L.DONE)
    ShowGroupArt(banner.art, group, true)

    self:RefreshQuests()
    if self.selectedQuest then
        self:ShowQuest(self.selectedQuest)
    else
        self.details:Clear()
        self.details:Line(L.SELECT_QUEST, C.textDim)
        self.details:Finish()
    end
    self.mainFrame:SetFooter(L.FOOTER_QUESTS)
end
