-- Main window: header, tabs, faction and tracking selectors, footer, and the active view.
--
-- Views are created on first display. Each view is a table with Build(frame) and
-- Refresh(); MainFrame calls Refresh when the view is shown and whenever progress, names
-- or settings change while it is visible.

local _, ns = ...

local MainFrame = {}
ns.MainFrame = MainFrame

local L = ns.L
local UI, Theme = ns.UI, ns.Theme
local C = Theme.colors
local Tracking, Faction = ns.Const.Tracking, ns.Const.Faction

-- Default size of the window, and the smallest it can be resized to: below it, the fixed
-- columns of the views and the tabs no longer fit.
local WIDTH, HEIGHT = 1200, 680
local MIN_WIDTH, MIN_HEIGHT = 1080, 600
local TABS_LEFT, TABS_RIGHT, TAB_SPACING = 132, 24, 8
local CONTENT_TOP = 168
-- Places a link can be followed back to, the oldest dropped beyond this count.
local HISTORY_LIMIT = 30

ns.Views = ns.Views or {}

-- Tab order and the view that renders each tab. A tab is shown when the file of its view is
-- loaded, so that the TOC alone decides which tabs the window offers.
-- `global` names the client's own label when it has one (see ns:GameLabel).
local ALL_TABS = {
    { id = "quests", global = "QUESTS_LABEL", label = "TAB_QUESTS", icon = "quests", view = "Quests" },
    { id = "professions", global = "TRADE_SKILLS", label = "TAB_PROFESSIONS", icon = "professions", view = "Professions" },
    { id = "dungeons", global = "DUNGEONS", label = "TAB_DUNGEONS", icon = "dungeons", view = "Dungeons" },
    { id = "raids", global = "RAIDS", label = "TAB_RAIDS", icon = "raids", view = "Raids" },
    { id = "achievements", global = "LEGACY_CHALLENGE_FRAME_TITLE", label = "TAB_ACHIEVEMENTS", icon = "achievements", view = "Achievements" },
    { id = "collections", label = "TAB_COLLECTIONS", icon = "collections", view = "Collections" },
    { id = "feedback", label = "TAB_FEEDBACK", icon = "feedback", view = "Feedback", untracked = true },
}
local TABS = {}

-- State shared by every view: the faction shown and the tracking mode.
MainFrame.state = { faction = nil }

function MainFrame:View()
    return ns.Quests:CurrentView(self.state.faction)
end

-------------------------------------------------------------------------------
-- Construction
-------------------------------------------------------------------------------

-- Position and size of the window, kept in the settings once the user moved or resized it.
local function saveGeometry(frame)
    local settings = ns.Database:Settings()
    local point, _, relativePoint, x, y = frame:GetPoint()
    settings.position = { point, relativePoint, x, y }
    settings.size = { math.floor(frame:GetWidth() + 0.5), math.floor(frame:GetHeight() + 0.5) }
end

-- Tooltip of a progress: the percentage, then what it counts.
local function progressLine(counts)
    if counts.total == 0 then return L.UNAVAILABLE end
    return string.format(L.PROGRESS_TOOLTIP, math.floor(counts.done / counts.total * 100), counts.done, counts.total)
end

local function buildHeader(frame)
    -- The starred medallion is the signature of Chronicles of Azeroth: it overlaps the top
    -- left corner of the window, as on the Legacy windows.
    local medallion = frame:CreateTexture(nil, "OVERLAY")
    medallion:SetTexture(Theme.MEDALLION)
    medallion:SetSize(92, 92)
    medallion:SetPoint("TOPLEFT", -12, 10)

    -- Overall progress: every tab weighs the same.
    local ring = UI.ProgressRing(frame, 84)
    ring:SetPoint("TOPRIGHT", -52, -8)
    ring:SetShown(ns.Progress ~= nil)
    ring:EnableMouse(true)
    ring:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.OVERALL_PROGRESS, 1, 0.82, 0)
        local progress = MainFrame.progress
        if progress then
            for _, tab in ipairs(TABS) do
                GameTooltip:AddDoubleLine(ns:GameLabel(tab.global, tab.label), progressLine(progress[tab.id]), 1, 1, 1, 1, 1, 1)
            end
        end
        GameTooltip:AddLine(L.OVERALL_PROGRESS_NOTE, 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    ring:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.ring = ring

    local title = UI.Text(frame, 26, C.gold, "body", "CENTER")
    title:SetPoint("TOP", 0, -20)
    title:SetText(L.ADDON_TITLE:upper())
    local subtitle = UI.Text(frame, 14, { 0.70, 0.75, 0.80, 1 }, "body", "CENTER")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -6)
    subtitle:SetText(L.ADDON_SUBTITLE)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function() frame:Hide() end)

    -- The header drags the window.
    local drag = CreateFrame("Frame", nil, frame)
    drag:SetPoint("TOPLEFT", 120, 0)
    drag:SetPoint("TOPRIGHT", -50, 0)
    drag:SetHeight(84)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() frame:StartMoving() end)
    drag:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        saveGeometry(frame)
    end)end

-- The tabs share the width of the window, and follow it when the window is resized.
local function layoutTabs(frame)
    local count = #TABS
    local width = math.floor((frame:GetWidth() - TABS_LEFT - TABS_RIGHT - TAB_SPACING * (count - 1)) / count)
    for index, tab in ipairs(TABS) do
        local button = frame.tabs[tab.id]
        button:SetWidth(width)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", TABS_LEFT + (index - 1) * (width + TAB_SPACING), -92)
    end
end

local function buildTabs(frame)
    frame.tabs = {}
    for _, tab in ipairs(TABS) do
        local button = UI.TabButton(frame, 100, 36, Theme.icons[tab.icon], ns:GameLabel(tab.global, tab.label), function()
            MainFrame:ForgetHistory()
            MainFrame:SelectTab(tab.id)
        end)
        -- Progress of the tab, a thin bar along its bottom edge, its figures in the tooltip.
        button.progress = UI.ProgressBar(button, 3)
        button.progress:SetPoint("BOTTOMLEFT", 1, 1)
        button.progress:SetPoint("BOTTOMRIGHT", -1, 1)
        button:SetScript("OnEnter", function(self)
            local progress = MainFrame.progress
            if not progress then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(self.label:GetText() or "", 1, 0.82, 0)
            GameTooltip:AddLine(progressLine(progress[tab.id]), 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button.tab = tab
        frame.tabs[tab.id] = button
    end
    layoutTabs(frame)
    local rule = UI.Solid(frame, "ARTWORK", C.borderDim)
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", 120, -134)
    rule:SetPoint("TOPRIGHT", -24, -134)
end

-- The three switches of the header share one style and spread over the width of the window:
-- the faction on the left, the tracking mode in the middle, the filter on the right.
local function buildSelectors(frame)
    local faction = UI.Toggle(frame, L.FACTION_LABEL, function()
        local current = MainFrame.state.faction or ns.Player.faction
        MainFrame.state.faction = current == Faction.ALLIANCE and Faction.HORDE or Faction.ALLIANCE
        ns.Log:Debug("Faction shown: %s", MainFrame.state.faction)
        MainFrame:Refresh()
    end)
    faction:SetPoint("TOPLEFT", 28, -142)
    frame.faction = faction

    local tracking = UI.Toggle(frame, L.TRACKING_LABEL, function()
        local settings = ns.Database:Settings()
        settings.tracking = settings.tracking == Tracking.ACCOUNT and Tracking.CHARACTER or Tracking.ACCOUNT
        ns.Log:Debug("Tracking mode: %s", settings.tracking)
        MainFrame:Refresh()
    end)
    tracking:SetPoint("TOP", 0, -142)
    frame.tracking = tracking

    local filter = UI.Toggle(frame, L.FILTER_LABEL, function()
        local settings = ns.Database:Settings()
        settings.possibleOnly = settings.possibleOnly == false
        ns.Log:Debug("Character filter: %s", tostring(settings.possibleOnly))
        MainFrame:Refresh()
    end)
    filter:SetPoint("TOPRIGHT", -28, -142)
    frame.filter = filter
end

local function buildFooter(frame)
    local footer = UI.Text(frame, 12, C.textDim, "body", "CENTER")
    footer:SetPoint("BOTTOM", 0, 14)
    frame.footer = footer
end

local function create()
    TABS = {}
    for _, tab in ipairs(ALL_TABS) do
        if ns.Views[tab.view] then TABS[#TABS + 1] = tab end
    end
    local frame = CreateFrame("Frame", "ChroniquesAzerothFrame", UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()

    -- The window of Chronicles of Azeroth: the native tooltip texture within the gilded
    -- border of the Blizzard dialogs.
    local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    backdrop:SetAllPoints()
    backdrop:SetFrameLevel(frame:GetFrameLevel())
    backdrop:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16,
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", edgeSize = 22,
        insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    backdrop:SetBackdropColor(Theme.Unpack(C.window))
    backdrop:SetBackdropBorderColor(0.70, 0.48, 0.16, 1)

    buildHeader(frame)
    buildTabs(frame)
    buildSelectors(frame)
    buildFooter(frame)

    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", 24, -CONTENT_TOP)
    frame.content:SetPoint("BOTTOMRIGHT", -24, 38)
    frame.views = {}

    frame.grip = UI.ResizeGrip(frame, function() saveGeometry(frame) end)
    frame:SetScript("OnSizeChanged", function() ns:SafeCall("window resize", layoutTabs, frame) end)

    frame:SetScript("OnShow", function()
        ns.Log:Debug("Window shown")
        MainFrame:Refresh()
    end)
    table.insert(UISpecialFrames, "ChroniquesAzerothFrame") -- closes with Escape
    return frame
end

-------------------------------------------------------------------------------
-- Behaviour
-------------------------------------------------------------------------------

function MainFrame:Frame()
    if not self.frame then
        self.frame = create()
        local settings = ns.Database:Settings()
        self:ApplyScale(settings.scale or 1)
        local size = settings.size
        if size then self.frame:SetSize(self:FitSize(size[1], size[2])) end
        local position = settings.position
        if position then
            self.frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
        else
            self.frame:SetPoint("CENTER")
        end
        self:SelectTab(settings.tab or "quests", true)
    end
    return self.frame
end

function MainFrame:SelectTab(id, silent)
    local frame = self:Frame()
    local tab
    for _, candidate in ipairs(TABS) do
        if candidate.id == id then tab = candidate end
    end
    tab = tab or TABS[1]
    for tabID, button in pairs(frame.tabs) do button:SetActive(tabID == tab.id) end
    for _, view in pairs(frame.views) do view.frame:Hide() end

    local view = frame.views[tab.id]
    if not view then
        local definition = ns.Views[tab.view]
        view = setmetatable({ mainFrame = self }, { __index = definition })
        view.frame = CreateFrame("Frame", nil, frame.content)
        view.frame:SetAllPoints()
        ns:SafeCall("view " .. tab.id .. " build", view.Build, view, view.frame)
        frame.views[tab.id] = view
    end
    view.frame:Show()
    self.activeView = view
    if tab.id ~= self.activeTab then self.previousTab = self.activeTab end
    self.activeTab = tab.id
    self:UpdateBack()
    ns.Database:Settings().tab = tab.id
    if not silent then ns.Log:Debug("Tab %s", tab.id) end
    self:Refresh()
end

-------------------------------------------------------------------------------
-- Links between the tabs
-------------------------------------------------------------------------------

-- The places links were followed from, the last one on top. Following links one after the
-- other stacks them; any other navigation forgets them, so that Back only ever undoes links.
-- They live as long as the views keep their state: through closing the window, not a reload.
MainFrame.history = {}

local function tabLabel(id)
    for _, tab in ipairs(TABS) do
        if tab.id == id then return ns:GameLabel(tab.global, tab.label) end
    end
    return id
end

-- Opens an element of a tab, as a link does: the tab is selected and its view shows the
-- element, selected and scrolled into sight in its lists. The place left is kept for Back.
function MainFrame:Open(tabID, id)
    self:Frame()
    local current = self.activeView
    if current then
        local location = current.Location and current:Location()
        local place = location and location.back or string.format(L.BACK_TO_TAB, tabLabel(self.activeTab))
        table.insert(self.history, { tab = self.activeTab, location = location, label = place })
        if #self.history > HISTORY_LIMIT then table.remove(self.history, 1) end
    end
    self:SelectTab(tabID)
    local view = self.activeView
    local shown = view.Reveal and ns:SafeCall("view " .. tabID .. " reveal", view.Reveal, view, id)
    if not shown then ns.Log:Info("Link to %s %s: the element could not be shown", tabID, tostring(id)) end
    self:UpdateBack()
end

-- Tab that lists a quest: the quests tab for a zone or a category, the dungeons or raids
-- tab for an instance quest; nil for a quest outside the catalogue.
function MainFrame:QuestTab(questID)
    if ns.Quests:GroupOf(questID) then return "quests" end
    local instance = ns.Instances and ns.Instances:OfQuest(questID)
    if instance then return instance.kind == ns.Const.Instance.RAID and "raids" or "dungeons" end
    return nil
end

-- Returns to the place the last link was followed from.
function MainFrame:Back()
    local entry = table.remove(self.history)
    if not entry then return end
    self:SelectTab(entry.tab)
    local view = self.activeView
    if entry.location and view.Restore then
        ns:SafeCall("view " .. entry.tab .. " restore", view.Restore, view, entry.location)
    end
    self:UpdateBack()
end

-- Navigation by hand: the places links were followed from are forgotten.
function MainFrame:ForgetHistory()
    if #self.history == 0 then return end
    self.history = {}
    self:UpdateBack()
end

-- Tooltip of the back button: where it returns to.
function MainFrame:BackTooltip()
    local entry = self.history[#self.history]
    return entry and entry.label or nil
end

-- The back button stands in the details header of the shown view, while there is a place
-- to return to.
function MainFrame:UpdateBack()
    if not self.frame then return end
    for _, view in pairs(self.frame.views) do
        local back = view.page and view.page.back
        if back then back:SetShown(view == self.activeView and #self.history > 0) end
    end
end

-- Redraws the selectors and the active view.
function MainFrame:Refresh()
    local frame = self.frame
    if not frame or not frame:IsShown() then return end
    local faction = self.state.faction or ns.Player.faction
    local horde = faction == Faction.HORDE
    frame.faction:SetValue(horde and Theme.icons.horde or Theme.icons.alliance,
        horde and L.FACTION_HORDE or L.FACTION_ALLIANCE, L.FACTION_TOOLTIP)
    local settings = ns.Database:Settings()
    local account = settings.tracking == Tracking.ACCOUNT
    frame.tracking:SetValue(account and Theme.icons.account or Theme.icons.character,
        account and L.TRACKING_ACCOUNT or L.TRACKING_CHARACTER,
        account and L.TRACKING_TOOLTIP_ACCOUNT or L.TRACKING_TOOLTIP_CHARACTER)
    local possible = settings.possibleOnly ~= false
    frame.filter:SetValue(possible and Theme.icons.possible or Theme.icons.everything,
        possible and L.FILTER_POSSIBLE or L.FILTER_EVERYTHING,
        possible and L.FILTER_TOOLTIP_POSSIBLE or L.FILTER_TOOLTIP_EVERYTHING)
    frame.filter:SetAvailable(not account and faction == ns.Player.faction, L.FILTER_UNAVAILABLE)
    local view = self.activeView
    if view and view.Refresh then
        ns:SafeCall("view " .. tostring(self.activeTab) .. " refresh", view.Refresh, view)
    end
    self:ScheduleProgress()
end

-- The gauges count every tab: they are drawn on the next frame, after the view, and only
-- while the window is shown.
function MainFrame:ScheduleProgress()
    if self.progressScheduled then return end
    self.progressScheduled = true
    C_Timer.After(0, function()
        self.progressScheduled = nil
        ns:SafeCall("progress", self.RefreshProgress, self)
    end)
end

function MainFrame:RefreshProgress()
    local frame = self.frame
    if not frame or not frame:IsShown() or not ns.Progress then return end
    local progress = ns.Progress:Compute(self:View())
    self.progress = progress
    for _, tab in ipairs(TABS) do
        local counts = progress[tab.id]
        frame.tabs[tab.id].progress:SetProgress(counts.done, counts.total)
    end
    local overall = progress.overall
    if overall then
        frame.ring:SetProgress(math.floor(overall * 1000), 1000, overall >= 1 and L.COMPLETE or L.OVERALL)
    else
        frame.ring:SetProgress(0, 0, "")
    end
end

function MainFrame:SetFooter(text)
    if self.frame then self.frame.footer:SetText(text or "") end
end

function MainFrame:Toggle()
    local frame = self:Frame()
    frame:SetShown(not frame:IsShown())
end

function MainFrame:SetScale(scale)
    ns.Database:Settings().scale = scale
    if self.frame then
        self:ApplyScale(scale)
        self.frame:SetSize(self:FitSize(self.frame:GetWidth(), self.frame:GetHeight()))
    end
end

-- The window can grow up to the screen, whose size in the window's units depends on its scale.
function MainFrame:MaxSize()
    local scale = self.frame:GetScale() or 1
    return math.max(MIN_WIDTH, UIParent:GetWidth() / scale), math.max(MIN_HEIGHT, UIParent:GetHeight() / scale)
end

function MainFrame:ApplyScale(scale)
    self.frame:SetScale(scale)
    local maxWidth, maxHeight = self:MaxSize()
    ns.Compat.SetResizeBounds(self.frame, MIN_WIDTH, MIN_HEIGHT, maxWidth, maxHeight)
end

-- A saved size within the bounds of the current screen and scale.
function MainFrame:FitSize(width, height)
    local maxWidth, maxHeight = self:MaxSize()
    return math.min(math.max(width or WIDTH, MIN_WIDTH), maxWidth), math.min(math.max(height or HEIGHT, MIN_HEIGHT), maxHeight)
end

ns:RegisterMessage("CA_PROGRESS_CHANGED", function() MainFrame:Refresh() end)
ns:RegisterMessage("CA_NAMES_UPDATED", function() MainFrame:Refresh() end)
ns:RegisterMessage("CA_COLLECTIONS_CHANGED", function() MainFrame:Refresh() end)
