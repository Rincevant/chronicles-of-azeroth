-- Dungeons and Raids tabs, on the page of every tab: instances on the left, the instance
-- summary and the selected boss or quest in the middle, the bosses and quests of the
-- instance on the right.

local _, ns = ...

local L = ns.L
local UI, Theme, Layout, QuestWidgets = ns.UI, ns.Theme, ns.Layout, ns.QuestWidgets
local C = Theme.colors
local Kind = ns.Const.Instance


local function buildInstanceCard(row)
    UI.ArtCard(row)
end

local function buildEntryRow(row)
    QuestWidgets.BuildRow(row)
    row.icon = UI.FramedIcon(row, 22)
    row.icon:SetPoint("LEFT", 8, 0)
    row.header = UI.Text(row, 13, C.gold)
    row.header:SetPoint("LEFT", 10, 0)
end

local function newView(kind)
    local View = {}

    function View:Build(frame)
        self.expanded = {}
        self.query, self.entryQuery = "", ""
        local page = Layout.Page(frame, {
            groupsTitle = kind == Kind.RAID and L.RAIDS or L.DUNGEONS,
            groupSearch = L.SEARCH_INSTANCE,
            onGroupSearch = function(text)
                self.query = text
                self:Refresh()
            end,
            buildGroup = buildInstanceCard,
            fillGroup = function(row, instance) self:FillCard(row, instance) end,
            detailsTitle = L.SELECTED_ENTRY,
            itemSearch = L.SEARCH,
            onItemSearch = function(text)
                self.entryQuery = text
                self:Refresh()
            end,
            filterKey = kind == Kind.RAID and "raids" or "dungeons",
            onFilter = function() self:Refresh() end,
            itemHeight = 32,
            buildItem = buildEntryRow,
            fillItem = function(row, item) self:FillEntry(row, item) end,
            itemSpacing = 3,
        })
        self.page = page
        self.instances, self.entries, self.filters = page.groups, page.items, page.filters
        self.title, self.banner, self.details = page.title, page.banner, page.details
        self.entriesTitle, self.count = page.itemsTitle, page.footer
    end

    function View:FillCard(row, instance)
        local summary = ns.Instances:Summary(instance, self.mainFrame:View())
        row.name:SetText(ns.Instances:Name(instance))
        row.count:SetText(string.format("%d / %d", summary.done, summary.total))
        local complete = summary.total > 0 and summary.done >= summary.total
        row.count:SetTextColor(Theme.Unpack(complete and C.green or C.text))
        row.levels:SetText(instance.levels and QuestWidgets.LevelText(instance.levels[1], instance.levels[2]) or "")
        if not row.art:SetLoadingScreen(instance.art, instance.artFramed) then row.art:Clear() end
        row.border:SetColor(self.selected == instance and C.gold or (complete and C.greenBorder or C.borderDim))
        row:SetScript("OnClick", function()
            ns.MainFrame:ForgetHistory()
            self.selected = instance
            self.selectedEntry, self.forcedQuest = nil, nil
            self.entries.offset = 0
            self:Refresh()
        end)
    end

    -- Entries of the list: a bosses header and bosses, then a quests header and quests.
    function View:BuildEntries(instance, view)
        local items = {}
        local defeated = ns.Instances:Defeated(view.tracking)
        local bosses = {}
        for _, encounterID in ipairs(instance.bosses) do
            if self.filters:Keeps(defeated[encounterID])
                and UI.Matches(ns.Names.Encounter(encounterID) or "", self.entryQuery) then
                bosses[#bosses + 1] = { kind = "boss", id = encounterID }
            end
        end
        if #bosses > 0 then
            items[#items + 1] = { kind = "header", text = L.BOSSES }
            for _, boss in ipairs(bosses) do items[#items + 1] = boss end
        end
        local questItems = QuestWidgets.BuildItems(instance.chains, view, self.expanded, self.entryQuery, self.filters,
            self.forcedQuest)
        if #questItems > 0 then
            items[#items + 1] = { kind = "header", text = L.QUESTS }
            for _, item in ipairs(questItems) do items[#items + 1] = item end
        end
        return items
    end

    function View:FillEntry(row, item)
        local isHeader, isBoss = item.kind == "header", item.kind == "boss"
        row.header:SetShown(isHeader)
        row.icon:SetShown(isBoss)
        for _, region in ipairs({ row.name, row.level, row.right }) do region:SetShown(not isHeader) end
        row.check:Hide()
        row.marker:Hide()
        row.expand:Hide()
        row:SetScript("OnClick", nil)
        if isHeader then
            row.header:SetText(item.text:upper())
            row:SetState(false, { bg = { 0, 0, 0, 0 }, border = { 0, 0, 0, 0 } })
            return
        end
        if isBoss then
            local defeated = ns.Instances:Defeated(self.mainFrame:View().tracking)[item.id]
            row.icon:SetIcon(Theme.icons.boss)
            row.name:ClearAllPoints()
            row.name:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
            row.name:SetPoint("RIGHT", row.level, "LEFT", -6, 0)
            row.name:SetText(ns.Names.Encounter(item.id) or ("#" .. item.id))
            row.name:SetTextColor(Theme.Unpack(defeated and C.green or C.text))
            row.level:SetText("")
            row.right:SetText(defeated and L.DEFEATED or "")
            row.right:SetTextColor(Theme.Unpack(C.green))
            row.check:SetShown(defeated)
            row:SetState(self.selectedEntry == item.id and self.selectedKind == "boss")
            row:SetScript("OnClick", function() self:SelectEntry(item) end)
            return
        end
        QuestWidgets.FillRow(row, item, self.mainFrame:View(), self.selectedKind == "quest" and self.selectedEntry or nil)
        row:SetScript("OnClick", function() self:SelectEntry(item) end)
    end

    function View:SelectEntry(item)
        if item.kind == "chain" then self.expanded[item.id] = not self.expanded[item.id] else ns.MainFrame:ForgetHistory() end
        if item.id ~= self.forcedQuest then self.forcedQuest = nil end
        self.selectedEntry = item.id
        self.selectedKind = item.kind == "boss" and "boss" or "quest"
        self:Refresh()
    end

    local function indexOf(items, matches)
        for index, item in ipairs(items) do
            if matches(item) then return index end
        end
        return nil
    end

    -- Shows a quest a link leads to: its instance and the quest selected, both lists scrolled
    -- to them, listed even when the view or the filters hide it. The searches are cleared so
    -- that they do not hide it.
    function View:Reveal(questID)
        local instance = ns.Instances:OfQuest(questID)
        if not instance or instance.kind ~= kind then return false end
        self.query, self.entryQuery = "", ""
        self.page.groupSearch:SetText("")
        self.page.itemSearch:SetText("")
        if self.selected ~= instance then self.entries.offset = 0 end
        self.selected = instance
        self.selectedEntry, self.selectedKind, self.forcedQuest = questID, "quest", questID
        self:Refresh()
        local instanceIndex = indexOf(self.instances.items, function(item) return item == instance end)
        if instanceIndex then self.instances:Reveal(instanceIndex) end
        local entryIndex = indexOf(self.entries.items, function(item) return item.kind == "quest" and item.id == questID end)
        if entryIndex then self.entries:Reveal(entryIndex) end
        return true
    end

    -- Where the view stands, for the Back link.
    function View:Location()
        local raid = kind == Kind.RAID
        local back
        if self.selectedEntry and self.selectedKind == "quest" then
            back = string.format(raid and L.BACK_TO_RAID_QUEST or L.BACK_TO_DUNGEON_QUEST,
                ns.Names.Quest(self.selectedEntry) or ("#" .. self.selectedEntry))
        elseif self.selectedEntry then
            back = string.format(L.BACK_TO_BOSS, ns.Names.Encounter(self.selectedEntry) or ("#" .. self.selectedEntry))
        elseif self.selected then
            back = string.format(raid and L.BACK_TO_RAID or L.BACK_TO_DUNGEON, ns.Instances:Name(self.selected))
        end
        return { back = back, selected = self.selected, entry = self.selectedEntry, entryKind = self.selectedKind,
            forced = self.forcedQuest, instancesOffset = self.instances.offset, entriesOffset = self.entries.offset }
    end

    function View:Restore(location)
        self.selected, self.selectedEntry, self.selectedKind = location.selected, location.entry, location.entryKind
        self.forcedQuest = location.forced
        self.instances.offset, self.entries.offset = location.instancesOffset, location.entriesOffset
        self:Refresh()
    end

    function View:ShowBoss(encounterID)
        local panel = self.details
        panel:Clear("boss:" .. encounterID)
        local defeated = ns.Instances:Defeated(self.mainFrame:View().tracking)[encounterID]
        panel:Title(Theme.icons.boss, ns.Names.Encounter(encounterID) or ("#" .. encounterID),
            defeated and L.DEFEATED or L.NOT_DEFEATED, C.gold, defeated and C.green or C.orange)
        panel:Line(ns.Instances:Name(self.selected), C.text, 12)
        panel:Space(6)
        panel:Line(L.BOSS_TRACKING_NOTE, C.textDim, 11)
        panel:Finish()
    end

    function View:Refresh()
        local view = self.mainFrame:View()
        local list = {}
        for _, instance in ipairs(ns.Instances:List(kind)) do
            if UI.Matches(ns.Instances:Name(instance), self.query) then list[#list + 1] = instance end
        end
        UI.SortByLevel(list, function(item) return item.levels end, function(item) return ns.Instances:Name(item) end)
        if not self.selected then self.selected = list[1] end
        self.instances:SetItems(list, true)

        local instance = self.selected
        if not instance then
            self.title:SetText("")
            self.entriesTitle:SetText("")
            self.count:SetText("")
            self.entries:SetItems({})
            self.details:Clear()
            self.details:Line(L.NO_INSTANCE, C.textDim)
            self.details:Finish()
            return
        end
        local name = ns.Instances:Name(instance)
        local summary = ns.Instances:Summary(instance, view)
        self.title:SetText(name)
        local banner = self.banner
        banner.name:SetText(name:upper())
        local parts = { kind == Kind.RAID and L.RAID or L.DUNGEON }
        if instance.levels then parts[#parts + 1] = QuestWidgets.LevelText(instance.levels[1], instance.levels[2]) end
        if instance.players and instance.players > 0 then parts[#parts + 1] = string.format(L.PLAYERS, instance.players) end
        banner.subtitle:SetText(table.concat(parts, "  ·  "))
        banner.caption:SetText(string.format(L.INSTANCE_CAPTION, summary.bossesDone, summary.bosses, summary.questsDone, summary.quests))
        banner.ring:SetProgress(summary.done, summary.total, summary.total > 0 and summary.done >= summary.total and L.COMPLETE or L.DONE)
        if not banner.art:SetLoadingScreen(instance.art, instance.artFramed) then banner.art:Clear() end

        self.entriesTitle:SetText(string.format(L.INSTANCE_ENTRIES_OF, name):upper())
        local entries = self:BuildEntries(instance, view)
        local listed = 0
        for _, item in ipairs(entries) do
            if item.kind ~= "header" then listed = listed + 1 end
        end
        self.entries:SetItems(entries, true)
        self.count:SetText(string.format(L.ENTRIES_LISTED, listed))
        if self.selectedKind == "boss" and self.selectedEntry then
            self:ShowBoss(self.selectedEntry)
        elseif self.selectedKind == "quest" and self.selectedEntry then
            local note = self.selectedEntry == self.forcedQuest
                and QuestWidgets.HiddenNote(self.selectedEntry, view, self.filters) or nil
            QuestWidgets.ShowDetails(self.details, self.selectedEntry, view, note)
        else
            self.details:Clear()
            self.details:Line(L.SELECT_ENTRY, C.textDim)
            self.details:Finish()
        end
        self.mainFrame:SetFooter(L.FOOTER_INSTANCES)
    end

    return View
end

ns.Views.Dungeons = newView(Kind.DUNGEON)
ns.Views.Raids = newView(Kind.RAID)
