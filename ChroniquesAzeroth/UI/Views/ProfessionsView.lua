-- Professions tab, on the page of every tab: professions on the left, the selected
-- profession and recipe (reagents and how to obtain it) in the middle, the recipe catalogue
-- on the right.

local _, ns = ...

local View = {}
ns.Views.Professions = View

local L = ns.L
local UI, Theme, Layout = ns.UI, ns.Theme, ns.Layout
local C = Theme.colors
local R = ns.Const.Recipe


local function recipeName(recipe)
    return ns.Professions.RecipeName(recipe) or L.LOADING
end

local function recipeIcon(recipe)
    local created = recipe[R.CREATED_ITEM]
    return (created and ns.Names.ItemIcon(created)) or ns.Names.SpellIcon(recipe[R.SPELL])
end

-------------------------------------------------------------------------------
-- Rows
-------------------------------------------------------------------------------

local function buildProfessionCard(row)
    UI.ArtCard(row)
end

-- A recipe row reads as a quest row: the name, the level the created item asks for, then
-- the rank the recipe asks for. Whether the recipe is known shows in the color of the name.
local function buildRecipeRow(row)
    UI.DecorateRow(row)
    row.icon = UI.FramedIcon(row, 26)
    row.icon:SetPoint("LEFT", 6, 0)
    row.name = UI.Text(row, 13)
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
    row.rank = UI.Text(row, 11, C.textDim, "body", "RIGHT")
    row.rank:SetWidth(64)
    row.rank:SetPoint("RIGHT", -10, 0)
    row.level = UI.Text(row, 11, C.goldDim, "body", "RIGHT")
    row.level:SetWidth(56)
    row.level:SetPoint("RIGHT", row.rank, "LEFT", -6, 0)
    row.name:SetPoint("RIGHT", row.level, "LEFT", -6, 0)
end

-------------------------------------------------------------------------------
-- Construction
-------------------------------------------------------------------------------

function View:Build(frame)
    self.query, self.professionQuery = "", ""
    local page = Layout.Page(frame, {
        groupsTitle = L.PROFESSIONS_TITLE,
        groupSearch = L.SEARCH,
        onGroupSearch = function(text)
            self.professionQuery = text
            self:Refresh()
        end,
        buildGroup = buildProfessionCard,
        fillGroup = function(row, profession) self:FillProfessionRow(row, profession) end,
        detailsTitle = L.SELECTED_RECIPE,
        itemSearch = L.SEARCH_RECIPE,
        onItemSearch = function(text)
            self.query = text
            self:RefreshRecipes()
        end,
        filterKey = "recipes",
        onFilter = function() self:RefreshRecipes() end,
        buildItem = buildRecipeRow,
        fillItem = function(row, recipe) self:FillRecipeRow(row, recipe) end,
        itemSpacing = 3,
    })
    self.page = page
    self.professions, self.recipes, self.filters = page.groups, page.items, page.filters
    self.title, self.banner, self.details = page.title, page.banner, page.details
    self.recipesTitle, self.recipeCount = page.itemsTitle, page.footer
end

-------------------------------------------------------------------------------
-- Rows content
-------------------------------------------------------------------------------

function View:FillProfessionRow(row, profession)
    local tracking = ns.Database:Settings().tracking
    row.name:SetText(ns.Names.SkillLine(profession.skillLine) or ("#" .. profession.skillLine))
    local rank = ns.Professions:Rank(profession.skillLine, tracking)
    row.levels:SetText(rank and string.format(L.RANK_OF, rank.rank, rank.maxRank) or L.NOT_LEARNED)
    local summary = ns.Professions:Summary(profession.skillLine, self.known)
    local complete = summary.total > 0 and summary.done >= summary.total
    row.count:SetText(#profession.recipes > 0 and string.format("%d / %d", summary.done, summary.total) or "")
    row.count:SetTextColor(Theme.Unpack(complete and C.green or C.text))
    if not row.art:SetArtwork(ns.Data.Artwork.professions[profession.skillLine]) then row.art:Clear() end
    row.border:SetColor(self.selected == profession.skillLine and C.gold or (complete and C.greenBorder or C.borderDim))
    row:SetScript("OnClick", function()
        ns.MainFrame:ForgetHistory()
        self.selected = profession.skillLine
        self.selectedRecipe = nil
        self.forcedProfession, self.forcedRecipe = nil, nil
        self.recipes.offset = 0
        self:Refresh()
    end)
end

function View:FillRecipeRow(row, recipe)
    local spellID = recipe[R.SPELL]
    local known = self.known[spellID]
    row.icon:SetIcon(recipeIcon(recipe))
    row.name:SetText(recipeName(recipe))
    row.level:SetText(recipe[R.LEVEL] and string.format(L.LEVEL_SHORT, recipe[R.LEVEL]) or "")
    row.rank:SetText(recipe[R.MIN_RANK] and string.format(L.RANK_SHORT, recipe[R.MIN_RANK]) or "")
    if known then
        local difficulty = ns.Professions.Difficulty(recipe, self.rankValue)
        row.name:SetTextColor(Theme.Unpack(difficulty and Theme.difficulty[difficulty] or C.green))
        row:SetState(self.selectedRecipe == spellID, { bg = { 0.05, 0.16, 0.07, 0.95 }, border = C.greenBorder })
    else
        -- Out of reach while the rank is too low, as a quest above the character's level.
        row.name:SetTextColor(Theme.Unpack(ns.Professions.RankTooLow(recipe, self.rankValue) and C.gray or C.text))
        row:SetState(self.selectedRecipe == spellID)
    end
    row:SetScript("OnClick", function()
        ns.MainFrame:ForgetHistory()
        self.selectedRecipe = spellID
        if spellID ~= self.forcedRecipe then self.forcedRecipe = nil end
        self.recipes:Redraw()
        self:ShowRecipe(recipe)
    end)
end

-------------------------------------------------------------------------------
-- Recipe details
-------------------------------------------------------------------------------

local function npcText(npcID)
    local name = ns.Names.Npc(npcID) or ("#" .. npcID)
    local row = ns.Data.Npcs[npcID]
    local place = row and row[2]
    if place then
        return string.format("%s %s", name, Theme.Colorize(string.format("(%s)", ns.Names.Area(place[1]) or "?"), C.textDim)), place
    end
    return name, nil
end

local function waypointButton(panel, place, label)
    if not (place and place[4]) then return end
    panel:Button(L.SHOW_ON_MAP, function()
        if ns.Compat.SetWaypoint(place[4], place[2], place[3]) then
            print(string.format("|cffffd200%s|r: %s", L.ADDON_TITLE, string.format(L.WAYPOINT_SET, label)))
        else
            print(string.format("|cffffd200%s|r: %s", L.ADDON_TITLE, L.WAYPOINT_UNAVAILABLE))
        end
    end)
end

function View:ShowRecipe(recipe)
    local panel = self.details
    panel:Clear(recipe and ("recipe:" .. recipe[R.SPELL]) or nil)
    if not recipe then
        panel:Line(L.SELECT_RECIPE, C.textDim)
        panel:Finish()
        return
    end
    local spellID = recipe[R.SPELL]
    local known = self.known[spellID]
    local tooLow = not known and ns.Professions.RankTooLow(recipe, self.rankValue)
    local state = known and L.RECIPE_LEARNED or (tooLow and L.RECIPE_RANK_TOO_LOW or L.RECIPE_TO_LEARN)
    panel:Title(recipeIcon(recipe), recipeName(recipe), state, C.gold, known and C.green or (tooLow and C.gray or C.orange))
    if spellID == self.forcedRecipe and self:IsHidden(recipe) then panel:Line(L.SHOWN_DESPITE_FILTERS, C.orange, 11) end
    if recipe[R.MIN_RANK] then
        local line = string.format(L.REQUIRED_RANK, recipe[R.MIN_RANK])
        if tooLow then line = line .. "  ·  " .. string.format(L.CURRENT_RANK_SHORT, self.rankValue or 0) end
        panel:Line(line, tooLow and C.orange or C.text, 12)
    end
    if recipe[R.TRIVIAL_HIGH] > 0 then
        panel:Line(string.format(L.SKILL_UP_RANGE, recipe[R.TRIVIAL_LOW], recipe[R.TRIVIAL_HIGH]), C.textDim, 11)
    end

    local created = recipe[R.CREATED_ITEM]
    if created then
        panel:Heading(L.CREATES)
        panel:IconLine(ns.Names.ItemIcon(created), ns.Names.Item(created) or L.LOADING, nil, C.text, nil, function(tooltip)
            tooltip:SetHyperlink("item:" .. created)
        end)
    end

    panel:Heading(L.REAGENTS)
    for _, reagent in ipairs(recipe[R.REAGENTS] or {}) do
        local itemID, count = reagent[1], reagent[2]
        panel:IconLine(ns.Names.ItemIcon(itemID), ns.Names.Item(itemID) or L.LOADING, "x" .. count, C.text, nil,
            function(tooltip) tooltip:SetHyperlink("item:" .. itemID) end)
    end

    panel:Heading(L.HOW_TO_OBTAIN)
    local sources = recipe[R.SOURCES]
    if recipe[R.AUTO_LEARNED] == 1 then
        local rank = recipe[R.MIN_RANK]
        panel:Line(rank and rank > 1 and string.format(L.SOURCE_AUTO_AT, rank) or L.SOURCE_AUTO, C.text, 12)
    elseif not sources then
        panel:Line(L.SOURCE_TRAINER, C.text, 12)
    end
    for _, source in ipairs(sources or {}) do
        local recipeItem = source.item
        panel:IconLine(ns.Names.ItemIcon(recipeItem), ns.Names.Item(recipeItem) or L.LOADING, nil, C.gold, nil,
            function(tooltip) tooltip:SetHyperlink("item:" .. recipeItem) end)
        local any = false
        for _, npcID in ipairs(source.vendors or {}) do
            local text, place = npcText(npcID)
            panel:Line(string.format("%s %s", Theme.Colorize(L.SOURCE_VENDOR, C.goldDim), text), C.text, 12, nil, 8)
            waypointButton(panel, place, ns.Names.Npc(npcID) or "")
            any = true
        end
        for _, npcID in ipairs(source.npcDrops or {}) do
            local text, place = npcText(npcID)
            panel:Line(string.format("%s %s", Theme.Colorize(L.SOURCE_DROP, C.goldDim), text), C.text, 12, nil, 8)
            waypointButton(panel, place, ns.Names.Npc(npcID) or "")
            any = true
        end
        for _, objectID in ipairs(source.objectDrops or {}) do
            panel:Line(string.format("%s %s", Theme.Colorize(L.SOURCE_OBJECT, C.goldDim),
                ns.Names.Object(objectID) or ("#" .. objectID)), C.text, 12, nil, 8)
            any = true
        end
        for _, questID in ipairs(source.questRewards or {}) do
            ns.QuestWidgets.QuestLink(panel, L.SOURCE_QUEST, questID, 8)
            any = true
        end
        if not any then panel:Line(L.SOURCE_UNKNOWN, C.textDim, 11, nil, 8) end
    end
    panel:Finish()
end

-------------------------------------------------------------------------------
-- Links
-------------------------------------------------------------------------------

-- Whether the view or the filters would leave a recipe out without a link leading to it.
function View:IsHidden(recipe)
    if not self.filters:Keeps(self.known[recipe[R.SPELL]]) then return true end
    local owner = ns.Professions:OwnerOf(recipe[R.SPELL])
    for _, profession in ipairs(ns.Professions:Shown(self.mainFrame:View())) do
        if profession.skillLine == owner then return false end
    end
    return true
end

local function indexOf(items, matches)
    for index, item in ipairs(items) do
        if matches(item) then return index end
    end
    return nil
end

-- Shows what a link leads to, a recipe spell or { skillLine = profession }: the profession
-- and the recipe selected, both lists scrolled to them. The searches are cleared so that
-- they do not hide them.
function View:Reveal(target)
    local spellID = type(target) == "number" and target or nil
    local skillLine = spellID and ns.Professions:OwnerOf(spellID) or (type(target) == "table" and target.skillLine)
    if not (skillLine and ns.Data.Professions[skillLine]) then return false end
    self.professionQuery, self.query = "", ""
    self.page.groupSearch:SetText("")
    self.page.itemSearch:SetText("")
    if self.selected ~= skillLine then self.recipes.offset = 0 end
    self.selected, self.selectedRecipe = skillLine, spellID
    self.forcedProfession, self.forcedRecipe = skillLine, spellID
    self:Refresh()
    local professionIndex = indexOf(self.professions.items, function(item) return item.skillLine == skillLine end)
    if professionIndex then self.professions:Reveal(professionIndex) end
    local recipeIndex = spellID and indexOf(self.recipes.items, function(item) return item[R.SPELL] == spellID end)
    if recipeIndex then self.recipes:Reveal(recipeIndex) end
    return true
end

-- Where the view stands, for the Back button.
function View:Location()
    local recipe = self.selectedRecipe and ns.Professions:Recipe(self.selectedRecipe)
    local back
    if recipe then
        back = string.format(L.BACK_TO_RECIPE, ns.Professions.RecipeName(recipe) or ("#" .. self.selectedRecipe))
    elseif self.selected then
        back = string.format(L.BACK_TO_PROFESSION, ns.Names.SkillLine(self.selected) or ("#" .. self.selected))
    end
    return { back = back, selected = self.selected, recipe = self.selectedRecipe, forcedProfession = self.forcedProfession,
        forcedRecipe = self.forcedRecipe, professionsOffset = self.professions.offset, recipesOffset = self.recipes.offset }
end

function View:Restore(location)
    self.selected, self.selectedRecipe = location.selected, location.recipe
    self.forcedProfession, self.forcedRecipe = location.forcedProfession, location.forcedRecipe
    self.professions.offset, self.recipes.offset = location.professionsOffset, location.recipesOffset
    self:Refresh()
end

-- A search finds a recipe by its own name, which is the spell's, and by the names of the item
-- it creates and of the items that teach it, which the client may word differently.
local function matchesQuery(recipe, query)
    if UI.Matches(recipeName(recipe), query) then return true end
    local created = recipe[R.CREATED_ITEM]
    if created and UI.Matches(ns.Names.Item(created) or "", query) then return true end
    for _, source in ipairs(recipe[R.SOURCES] or {}) do
        if source.item and UI.Matches(ns.Names.Item(source.item) or "", query) then return true end
    end
    return false
end

-------------------------------------------------------------------------------
-- Refresh
-------------------------------------------------------------------------------

function View:RefreshRecipes()
    local profession = self.selected and ns.Professions:Get(self.selected)
    if not profession then
        self.recipes:SetItems({})
        self.recipeCount:SetText("")
        return
    end
    local items = {}
    for _, recipe in ipairs(profession.recipes) do
        -- The recipe a link leads to is listed whatever the filters hide.
        if recipe[R.SPELL] == self.forcedRecipe
            or (self.filters:Keeps(self.known[recipe[R.SPELL]]) and (self.query == "" or matchesQuery(recipe, self.query))) then
            items[#items + 1] = recipe
        end
    end
    -- By rank in the progression (the learning rank, or the yellow one when it is unknown),
    -- then by the level of the created item (items without one after those with one), then
    -- by name.
    local names = {}
    for _, recipe in ipairs(items) do names[recipe] = recipeName(recipe) end
    table.sort(items, function(a, b)
        local rankA, rankB = ns.Professions.ProgressionRank(a), ns.Professions.ProgressionRank(b)
        if rankA ~= rankB then return rankA < rankB end
        local levelA, levelB = a[R.LEVEL] or math.huge, b[R.LEVEL] or math.huge
        if levelA ~= levelB then return levelA < levelB end
        if names[a] ~= names[b] then return names[a] < names[b] end
        return a[R.SPELL] < b[R.SPELL]
    end)
    self.recipes:SetItems(items, true)
    self.recipeCount:SetText(string.format(L.RECIPES_LISTED, #items))
end

-- The character has learned no profession: the filter leaves nothing to show.
function View:ShowEmpty()
    self.rankValue = nil
    self.title:SetText("")
    local banner = self.banner
    banner.name:SetText("")
    banner.subtitle:SetText(L.NO_PROFESSION_LEARNED)
    banner.caption:SetText("")
    banner.ring:SetProgress(0, 0, "")
    banner.art:Clear()
    self.recipesTitle:SetText(L.RECIPES:upper())
    self.recipes:SetItems({})
    self.recipeCount:SetText("")
    self:ShowRecipe(nil)
    self.mainFrame:SetFooter(L.FOOTER_PROFESSIONS)
end

function View:Refresh()
    local tracking = ns.Database:Settings().tracking
    self.known = ns.Professions:Known(tracking)
    local list = {}
    local forcedListed = false
    for _, profession in ipairs(ns.Professions:Shown(self.mainFrame:View())) do
        if profession.skillLine == self.forcedProfession
            or UI.Matches(ns.Names.SkillLine(profession.skillLine) or "", self.professionQuery) then
            list[#list + 1] = profession
            forcedListed = forcedListed or profession.skillLine == self.forcedProfession
        end
    end
    -- The profession a link leads to is listed even when the character filter hides it.
    if self.forcedProfession and not forcedListed then
        for _, profession in ipairs(ns.Professions:List()) do
            if profession.skillLine == self.forcedProfession then list[#list + 1] = profession end
        end
    end
    local listed = false
    for _, profession in ipairs(list) do
        if profession.skillLine == self.selected then listed = true end
    end
    UI.SortByLevel(list, function() return nil end, function(profession) return ns.Names.SkillLine(profession.skillLine) end)
    if not listed then
        self.selected, self.selectedRecipe = nil, nil
    end
    self.professions:SetItems(list, true)
    if #list == 0 then
        self:ShowEmpty()
        return
    end
    if not self.selected then
        for _, profession in ipairs(list) do
            if ns.Professions:Rank(profession.skillLine, tracking) and #profession.recipes > 0 then
                self.selected = profession.skillLine
                break
            end
        end
        self.selected = self.selected or (list[1] and list[1].skillLine)
    end

    local profession = ns.Professions:Get(self.selected)
    local rank = ns.Professions:Rank(self.selected, tracking)
    self.rankValue = rank and rank.rank
    local name = ns.Names.SkillLine(self.selected) or ""
    self.title:SetText(name)
    local summary = ns.Professions:Summary(self.selected, self.known)
    local banner = self.banner
    banner.name:SetText(name:upper())
    banner.subtitle:SetText(rank and string.format(L.CURRENT_RANK, rank.rank, rank.maxRank) or L.NOT_LEARNED)
    local trackingName = tracking == ns.Const.Tracking.ACCOUNT and L.TRACKING_ACCOUNT or L.TRACKING_CHARACTER
    banner.caption:SetText(string.format(L.RECIPES_CAPTION, summary.done, summary.total, trackingName))
    banner.ring:SetProgress(summary.done, summary.total, summary.total > 0 and summary.done >= summary.total and L.COMPLETE or L.DONE)
    if not banner.art:SetArtwork(ns.Data.Artwork.professions[self.selected]) then banner.art:Clear() end
    self.recipesTitle:SetText(string.format(L.RECIPES_OF, name):upper())
    self:RefreshRecipes()

    local selectedRecipe
    for _, recipe in ipairs(profession and profession.recipes or {}) do
        if recipe[R.SPELL] == self.selectedRecipe then selectedRecipe = recipe end
    end
    self:ShowRecipe(selectedRecipe)
    self.mainFrame:SetFooter(L.FOOTER_PROFESSIONS)
end
