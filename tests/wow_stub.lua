-- Minimal WoW client emulation for the offline tests.
--
-- Widgets accept only the methods listed below, so a misspelled or non-existent widget
-- method fails the tests instead of failing in the game. Game APIs return small,
-- deterministic fixtures. Timers and OnUpdate scripts run when the test advances the clock.

local Stub = {}

local locale = os.getenv("CA_TEST_LOCALE") or "enUS"
local clock = 0
local timers = {}
local eventFrames = {}
local updateFrames = {}

-------------------------------------------------------------------------------
-- Widgets
-------------------------------------------------------------------------------

local NOOP_METHODS = {
    -- Region / frame
    "SetPoint", "ClearAllPoints", "SetAllPoints", "SetFrameStrata", "SetFrameLevel", "SetToplevel", "SetMovable",
    "SetClampedToScreen", "EnableMouse", "EnableMouseWheel", "RegisterForDrag", "RegisterForClicks", "StartMoving",
    "StopMovingOrSizing", "SetClipsChildren", "SetHighlightTexture", "SetAlpha", "UnregisterEvent", "Raise", "Lower",
    "Enable", "Disable",
    -- Backdrop
    "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor",
    -- Texture
    "SetTexture", "SetColorTexture", "SetTexCoord", "SetRotation", "SetGradient", "SetVertexColor", "SetBlendMode",
    "SetDrawLayer", "SetDesaturated",
    -- Font string / edit box
    "SetFont", "SetTextColor", "SetJustifyH", "SetJustifyV", "SetWordWrap", "SetNonSpaceWrap", "SetShadowOffset",
    "SetShadowColor", "SetAutoFocus", "SetTextInsets", "ClearFocus", "SetFocus", "SetMaxLetters", "SetMultiLine",
    "HighlightText",
    -- Scroll frame
    "SetScrollChild",
    -- Tooltip
    "SetOwner", "ClearLines", "AddLine", "AddDoubleLine", "SetHyperlink", "SetItemByID", "SetSpellByID",
}

local Widget = {}
-- Widget methods are capitalized; lowercase keys are the addon's own fields and may be nil.
Widget.__index = function(self, key)
    local method = Widget[key]
    if method then return method end
    if type(key) == "string" and key:match("^%u") then
        error(string.format("unknown widget method %s on %s", key, rawget(self, "_type") or "?"), 2)
    end
    return nil
end

for _, name in ipairs(NOOP_METHODS) do Widget[name] = function() end end

function Widget:SetSize(width, height) self._width, self._height = width, height end
function Widget:SetWidth(width) self._width = width end
function Widget:SetHeight(height) self._height = height end
function Widget:GetWidth() return self._width or 400 end
function Widget:GetHeight() return self._height or 300 end
function Widget:GetLeft() return 100 end
function Widget:GetBottom() return 100 end
function Widget:GetFrameLevel()
    local level, parent = 0, self._parent
    while parent do level, parent = level + 1, parent._parent end
    return level
end
function Widget:GetEffectiveScale() return 1 end
function Widget:Show()
    local wasShown = self._shown
    self._shown = true
    if not wasShown and self._scripts.OnShow then self._scripts.OnShow(self) end
end
function Widget:Hide()
    local wasShown = self._shown
    self._shown = false
    if wasShown and self._scripts.OnHide then self._scripts.OnHide(self) end
end
function Widget:SetShown(shown) if shown then self:Show() else self:Hide() end end
function Widget:IsShown() return self._shown end
function Widget:IsVisible()
    local widget = self
    while widget do
        if not widget._shown then return false end
        widget = widget._parent
    end
    return true
end
function Widget:SetScript(event, handler)
    self._scripts[event] = handler
    if event == "OnUpdate" then updateFrames[self] = handler and true or nil end
end
function Widget:GetScript(event) return self._scripts[event] end
function Widget:HookScript(event, handler)
    local previous = self._scripts[event]
    self:SetScript(event, function(...) if previous then previous(...) end handler(...) end)
end
function Widget:SetText(text) self._text = text end
function Widget:GetText() return self._text end
function Widget:GetStringHeight() return 14 end
function Widget:GetStringWidth() return #(self._text or "") * 6 end
function Widget:SetVerticalScroll(value) self._scroll = value end
function Widget:GetVerticalScroll() return self._scroll or 0 end
function Widget:RegisterEvent(event)
    if not Stub.knownEvents[event] then error("unknown event " .. event) end
    eventFrames[self] = eventFrames[self] or {}
    eventFrames[self][event] = true
end
function Widget:Click(button)
    if self._scripts.OnClick then self._scripts.OnClick(self, button or "LeftButton") end
end
function Widget:GetChildren() return unpack(self._children) end

local function newWidget(kind, parent)
    local widget = setmetatable({ _type = kind, _scripts = {}, _children = {}, _shown = true, _parent = parent }, Widget)
    if parent then table.insert(parent._children, widget) end
    return widget
end

function Widget:CreateTexture() return newWidget("Texture", self) end
function Widget:CreateFontString() return newWidget("FontString", self) end

function CreateFrame(kind, name, parent, template)
    local frame = newWidget(kind, parent)
    if template and template:find("UIPanelScrollFrameTemplate", 1, true) then
        frame.ScrollBar = newWidget("Slider", frame)
        frame.ScrollBar.ScrollUpButton = newWidget("Button", frame.ScrollBar)
        frame.ScrollBar.ScrollDownButton = newWidget("Button", frame.ScrollBar)
    end
    if name then _G[name] = frame end
    return frame
end

-- Every widget created under a root, depth first.
function Stub.Descendants(root, into)
    into = into or {}
    for _, child in ipairs(root._children) do
        table.insert(into, child)
        Stub.Descendants(child, into)
    end
    return into
end

UIParent = newWidget("Frame")
UIParent:SetSize(1920, 1080)
Minimap = newWidget("Frame", UIParent)
Minimap:SetSize(140, 140)
GameTooltip = newWidget("GameTooltip", UIParent)
GameTooltip:Hide()
UISpecialFrames = {}
SlashCmdList = {}
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"

-------------------------------------------------------------------------------
-- Events, timers and frame updates
-------------------------------------------------------------------------------

Stub.knownEvents = {}
for _, event in ipairs({ "PLAYER_LOGIN", "QUEST_TURNED_IN", "QUEST_ACCEPTED", "ZONE_CHANGED_NEW_AREA",
    "GET_ITEM_INFO_RECEIVED", "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_CLOSE",
    "NEW_RECIPE_LEARNED", "SKILL_LINES_CHANGED", "CRAFT_SHOW", "CRAFT_UPDATE", "CRAFT_CLOSE",
    "LEARNED_SPELL_IN_TAB" }) do
    Stub.knownEvents[event] = true
end

function Stub.Fire(event, ...)
    for frame, events in pairs(eventFrames) do
        if events[event] and frame._scripts.OnEvent then frame._scripts.OnEvent(frame, event, ...) end
    end
end

C_Timer = {}
function C_Timer.After(delay, callback) table.insert(timers, { at = clock + delay, callback = callback }) end

-- Advances the clock by steps of one rendered frame, running the OnUpdate scripts of
-- every frame and the timers that fall due.
local FRAME_TIME = 1 / 30
function Stub.Advance(seconds)
    local target = clock + seconds
    while clock < target do
        clock = math.min(target, clock + FRAME_TIME)
        local updating = {}
        for frame in pairs(updateFrames) do table.insert(updating, frame) end
        for _, frame in ipairs(updating) do
            local handler = frame._scripts.OnUpdate
            if handler then handler(frame, FRAME_TIME) end
        end
        while true do
            table.sort(timers, function(a, b) return a.at < b.at end)
            local nextTimer = timers[1]
            if not nextTimer or nextTimer.at > clock then break end
            table.remove(timers, 1)
            nextTimer.callback()
        end
    end
end

function GetTime() return clock end
date = os.date
time = os.time

-------------------------------------------------------------------------------
-- Client
-------------------------------------------------------------------------------

Stub.chat = {}
function print(...)
    local parts = {}
    for index = 1, select("#", ...) do parts[index] = tostring(select(index, ...)) end
    table.insert(Stub.chat, table.concat(parts, " "))
end

function GetLocale() return locale end
function GetBuildInfo() return "1.60.1", "70888", "Nov 10 2026", 16001 end
function GetCursorPosition() return 0, 0 end

-------------------------------------------------------------------------------
-- Player
-------------------------------------------------------------------------------

Stub.faction = "Alliance"
function UnitName() return "Tester" end
function GetRealmName() return "Forever" end
function UnitFactionGroup() return Stub.faction, Stub.faction end
function UnitLevel() return 12 end

-------------------------------------------------------------------------------
-- Game data fixtures
-------------------------------------------------------------------------------

-- Quests the server reports as turned in by the character.
Stub.completedQuests = { [783] = true, [7] = true, [15] = true, [33] = true }
Stub.questLog = { [18] = 1 }

C_QuestLog = {}
function C_QuestLog.IsQuestFlaggedCompleted(questID) return Stub.completedQuests[questID] == true end
function C_QuestLog.GetTitleForQuestID(questID) return "Quest " .. questID end
function C_QuestLog.GetLogIndexForQuestID(questID) return Stub.questLog[questID] end

C_Item = {}
function C_Item.GetItemNameByID(itemID) return "Item " .. itemID end
function C_Item.GetItemIconByID() return 134400 end
function C_Item.RequestLoadItemDataByID() end
function GetItemInfo(itemID) return "Item " .. tostring(itemID), nil, 1, 1, 1, "Trade Goods", "", 20, "", 134400 end
function GetItemIcon() return 134400 end

function GetSpellInfo(spell) return "Spell " .. tostring(spell), nil, 136241 end
-- Blacksmithing: Rough Sharpening Stone (2660) and Rough Grinding Stone (3320) are known.
Stub.knownSpells = { [2660] = true, [3320] = true }
function IsSpellKnown(spellID) return Stub.knownSpells[spellID] == true end
function IsPlayerSpell(spellID) return Stub.knownSpells[spellID] == true end

-- The character knows Blacksmithing (164) at rank 75.
function GetProfessions() return 1, nil, nil, nil, nil, nil end
function GetProfessionInfo() return locale == "frFR" and "Forge" or "Blacksmithing", 136241, 75, 150, 0, 0, 164 end

return Stub
