-- Minimap button and addon compartment entry. The button wears the medallion of the window;
-- a left click opens or closes the window, a right click switches the tracking between the
-- account and the character. It can be dragged around the minimap; its angle is saved.

local _, ns = ...

local MinimapButton = ns:RegisterModule("MinimapButton")

local L = ns.L
local Tracking = ns.Const.Tracking

local function place(button, angle)
    local radians = math.rad(tonumber(angle) or 225)
    local radius = (Minimap:GetWidth() or 140) / 2 + 9
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radius, math.sin(radians) * radius)
end

-- Angle of the cursor around the minimap, in degrees. Some Lua clients only expose
-- math.atan(y): the quadrant is then restored by hand.
local function cursorAngle()
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = Minimap:GetCenter()
    local dx, dy = x / scale - cx, y / scale - cy
    if math.atan2 then return math.deg(math.atan2(dy, dx)) end
    local radians
    if dx > 0 then
        radians = math.atan(dy / dx)
    elseif dx < 0 then
        radians = math.atan(dy / dx) + (dy >= 0 and math.pi or -math.pi)
    else
        radians = dy >= 0 and math.pi / 2 or -math.pi / 2
    end
    return math.deg(radians)
end

local function showTooltip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:SetText(L.ADDON_TITLE, 1, 0.82, 0.25)
    GameTooltip:AddLine(L.MINIMAP_TOOLTIP, 1, 1, 1, true)
    GameTooltip:AddLine(L.MINIMAP_TRACKING, 1, 1, 1, true)
    GameTooltip:Show()
end

function MinimapButton:SwitchTracking()
    local settings = ns.Database:Settings()
    settings.tracking = settings.tracking == Tracking.ACCOUNT and Tracking.CHARACTER or Tracking.ACCOUNT
    ns.Log:Debug("Tracking mode: %s", settings.tracking)
    print(string.format("|cffd6a33a%s|r: %s", L.ADDON_TITLE,
        string.format(L.TRACKING_CHANGED, settings.tracking == Tracking.ACCOUNT and L.TRACKING_ACCOUNT or L.TRACKING_CHARACTER)))
    ns.MainFrame:Refresh()
end

function MinimapButton:OnLogin()
    local settings = ns.Database:Settings().minimap
    if not Minimap then return end
    local button = CreateFrame("Button", "ChroniquesAzerothMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(ns.Theme.MEDALLION)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints()

    button:SetScript("OnClick", function(self, mouseButton)
        -- A drag ends with a click, which must not open the window.
        if self.dragged then
            self.dragged = nil
            return
        end
        if mouseButton == "RightButton" then
            MinimapButton:SwitchTracking()
        else
            ns.MainFrame:Toggle()
        end
    end)
    button:SetScript("OnEnter", showTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            settings.angle = cursorAngle()
            place(self, settings.angle)
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self.dragged = true
    end)

    place(button, settings.angle)
    button:SetShown(not settings.hidden)
    self.button = button
end

function MinimapButton:SetHidden(hidden)
    ns.Database:Settings().minimap.hidden = hidden
    if self.button then self.button:SetShown(not hidden) end
end

-- Addon compartment (declared in the TOC).
function ChroniquesAzeroth_OnAddonCompartmentClick()
    ns.MainFrame:Toggle()
end

function ChroniquesAzeroth_OnAddonCompartmentEnter(_, button)
    showTooltip(button)
end

function ChroniquesAzeroth_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
