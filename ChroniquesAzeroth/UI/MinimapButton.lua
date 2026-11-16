-- The button around the minimap.

local _, ns = ...
local CA = ns.CA
local ASSET_PATH = ns.ASSET_PATH

-- Button around the minimap. It is deliberately separate from the
-- decorative medallion of the window: one is a permanent shortcut, the
-- other only the emblem of the Chronicles interface.
function CA:PlaceMinimapButton(angle)
  local button = self.minimapButton
  if not button or not Minimap then return end
  angle = tonumber(angle) or 225
  local radians = math.rad(angle)
  local radius = (Minimap:GetWidth() or 140) / 2 + 9
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radius, math.sin(radians) * radius)
end

local function minimapAngleFromOffset(offsetY, offsetX)
  if math.atan2 then return math.atan2(offsetY, offsetX) end
  -- Fallback for Lua clients that only expose math.atan(y). This
  -- conversion keeps the right quadrant when the button moves to the left
  -- of the minimap.
  if offsetX > 0 then return math.atan(offsetY / offsetX) end
  if offsetX < 0 and offsetY >= 0 then return math.atan(offsetY / offsetX) + math.pi end
  if offsetX < 0 then return math.atan(offsetY / offsetX) - math.pi end
  return offsetY >= 0 and math.pi / 2 or -math.pi / 2
end

function CA:UpdateMinimapButtonPosition()
  if not Minimap or not self.minimapButton then return end
  local scale = Minimap:GetEffectiveScale()
  local cursorX, cursorY = GetCursorPosition()
  local centerX = Minimap:GetLeft() + Minimap:GetWidth() / 2
  local centerY = Minimap:GetBottom() + Minimap:GetHeight() / 2
  local offsetX = cursorX / scale - centerX
  local offsetY = cursorY / scale - centerY
  local radians = minimapAngleFromOffset(offsetY, offsetX)
  local angle = math.deg(radians)
  ChroniquesAzerothDB.minimapAngle = angle
  self:PlaceMinimapButton(angle)
end

function CA:CreateMinimapButton()
  if self.minimapButton or not Minimap then return end
  local button = CreateFrame("Button", "ChroniquesAzerothMinimapButton", Minimap)
  button:SetSize(32, 32)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints()
  icon:SetTexture(ASSET_PATH .. "heritage-medallion.tga")
  button.icon = icon
  local highlight = button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  highlight:SetBlendMode("ADD")
  highlight:SetAllPoints()

  button:SetScript("OnEnter", function(widget)
    GameTooltip:SetOwner(widget, "ANCHOR_LEFT")
    GameTooltip:SetText(CA:L("addonTitle"), 1, .82, .28)
    GameTooltip:AddLine(CA:L("minimapOpen"), .85, .85, .85)
    GameTooltip:AddLine(CA:L("minimapToggle"), .85, .85, .85)
    GameTooltip:AddLine(CA:L("minimapDrag"), .60, .70, .85)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  button:SetScript("OnDragStart", function(widget)
    widget.dragging = true
    widget:SetScript("OnUpdate", function() CA:UpdateMinimapButtonPosition() end)
  end)
  button:SetScript("OnDragStop", function(widget)
    widget.dragging = nil
    widget.dragged = true
    widget:SetScript("OnUpdate", nil)
  end)
  button:SetScript("OnClick", function(widget, mouseButton)
    if widget.dragged then
      widget.dragged = nil
      return
    end
    if mouseButton == "RightButton" then
      local mode = CA:GetTrackingMode() == "account" and "character" or "account"
      CA:SetTrackingMode(mode)
      print("|cffd6a33aChroniques|r: " .. CA:L("trackingChanged", mode == "account" and CA:L("account") or CA:L("character")))
      return
    end
    CA.frame:SetShown(not CA.frame:IsShown())
    CA:Refresh()
  end)

  self.minimapButton = button
  self:PlaceMinimapButton(ChroniquesAzerothDB and ChroniquesAzerothDB.minimapAngle)
end
