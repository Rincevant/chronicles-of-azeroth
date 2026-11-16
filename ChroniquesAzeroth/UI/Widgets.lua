-- Building blocks shared by every view: panels, labels, buttons, tabs, the three columns of
-- the browsing tabs, scrolling lists and the progress ring.

local _, ns = ...

-- The artwork ships with the addon. TGA is used on purpose: the
-- Classic client supports it without depending on the PNG import
-- of a given game version.
ns.ASSET_PATH = "Interface\\AddOns\\ChroniquesAzeroth\\Assets\\"
-- Progress green inspired by the bars of the Blizzard journal: deeper
-- and less fluorescent than the green of completed quests.
ns.PROGRESS_TEXT_COLOR = { .30, .68, .14 }
ns.PROGRESS_RING_COLOR = { .25, .56, .10 }

function ns.shortText(text, limit)
  text, limit = tostring(text or ""), tonumber(limit) or 0
  if limit < 1 then return "" end
  -- string.sub works on bytes: it cut the typographic apostrophe of
  -- "l’Est" in two, which the client showed as a square. This walk
  -- respects UTF-8 sequences without relying on the utf8 library,
  -- which some Classic clients lack.
  local cursor, characters, total = 1, 0, #text
  while cursor <= total and characters < limit do
    local byte = string.byte(text, cursor)
    local width = byte < 0x80 and 1 or (byte < 0xE0 and 2 or (byte < 0xF0 and 3 or (byte < 0xF8 and 4 or 1)))
    if cursor + width - 1 > total then break end
    cursor, characters = cursor + width, characters + 1
  end
  if cursor <= total then return string.sub(text, 1, cursor - 1) .. "..." end
  return text
end

local function panel(parent, width, height, r, g, b)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetSize(width, height)
  -- Native texture, discreetly tiled: no illustrated frame or generated
  -- ornament is used in the browsing panels.
  f:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  f:SetBackdropColor(r or .10, g or .065, b or .030, .96)
  f:SetBackdropBorderColor(.65, .42, .15, 1)
  return f
end
ns.panel = panel

local function label(parent, text, size, color)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetFont(STANDARD_TEXT_FONT, size or 12, "")
  fs:SetTextColor(unpack(color or {1, .82, .35}))
  fs:SetText(text)
  return fs
end
ns.label = label

local function useQuestFont(fontString, size, isTitle)
  fontString:SetFont(isTitle and "Fonts\\MORPHEUS.TTF" or "Fonts\\FRIZQT__.TTF", size, "")
end
ns.useQuestFont = useQuestFont

function ns.modeButton(parent, text, x, y, onClick)
  local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
  button:SetSize(105, 22); button:SetPoint("TOPLEFT", x, y)
  button:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  button.text = label(button, text, 10, {.8, .84, .9}); button.text:SetPoint("CENTER")
  button:SetScript("OnClick", onClick)
  return button
end

function ns.continentTab(parent, text, iconPath, x, width, onClick)
  local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
  tab:SetSize(width, 25); tab:SetPoint("TOPLEFT", x, -40)
  tab:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 9 })
  tab.icon = tab:CreateTexture(nil, "ARTWORK"); tab.icon:SetSize(16, 16); tab.icon:SetPoint("LEFT", 7, 0); tab.icon:SetTexture(iconPath)
  -- Both continents get the same room; the label stays within its
  -- button, including for "Royaumes de l’Est".
  tab.text = label(tab, text, 6.5, {.62, .66, .70})
  tab.text:SetSize(width - 37, 20); tab.text:SetPoint("LEFT", tab.icon, "RIGHT", 4, 0)
  tab.text:SetJustifyH("LEFT"); tab.text:SetJustifyV("MIDDLE"); tab.text:SetWordWrap(false)
  tab:SetScript("OnClick", onClick)
  return tab
end

function ns.topTab(parent, text, iconPath, x, width, enabled, onClick)
  local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
  tab:SetSize(width, 29); tab:SetPoint("TOPLEFT", x, -57)
  tab:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  tab:SetBackdropColor(.045, .055, .07, 1)
  tab:SetBackdropBorderColor(.35, .38, .42, .65)
  tab.icon = tab:CreateTexture(nil, "ARTWORK"); tab.icon:SetSize(19, 19); tab.icon:SetPoint("LEFT", 9, 0); tab.icon:SetTexture(iconPath)
  tab.text = label(tab, text, enabled and 8.5 or 7.2, enabled and {.80, .84, .90} or {.52, .56, .60})
  tab.text:SetSize(width - 37, 24); tab.text:SetPoint("LEFT", tab.icon, "RIGHT", 5, 0)
  tab.text:SetJustifyH("LEFT"); tab.text:SetJustifyV("MIDDLE"); tab.text:SetWordWrap(false)
  tab.available = enabled and true or false
  if tab.available and onClick then tab:SetScript("OnClick", onClick) else tab:Disable() end
  return tab
end

-- Every browsing tab shares the same three columns, those of the Quests tab: the groups
-- on the left, the selected group and item in the middle, the items of the group on the
-- right. The columns start at (x, y) within their parent.
ns.COLUMN_HEIGHT = 400
function ns.columns(parent, x, y)
  local left = panel(parent, 245, ns.COLUMN_HEIGHT); left:SetPoint("TOPLEFT", x, y)
  left:SetBackdropColor(.12, .070, .028, .97); left:SetBackdropBorderColor(.66, .43, .15, 1)
  local center = panel(parent, 405, ns.COLUMN_HEIGHT); center:SetPoint("TOPLEFT", left, "TOPRIGHT", 15, 0)
  local right = panel(parent, 380, ns.COLUMN_HEIGHT); right:SetPoint("TOPLEFT", center, "TOPRIGHT", 15, 0)
  right:SetBackdropColor(.16, .095, .040, .97); right:SetBackdropBorderColor(.66, .43, .15, 1)
  return left, center, right
end

-- A scrolling list at (x, y) of its parent, whose scroll bar is anchored like those of the
-- Blizzard frames: the buttons stay in the right column, not on top of the start of the list.
function ns.scrollList(parent, x, y, width, height, childWidth, childHeight)
  local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", x, y); scroll:SetSize(width, height)
  local child = CreateFrame("Frame", nil, scroll); child:SetSize(childWidth, childHeight)
  scroll:SetScrollChild(child)
  if scroll.ScrollBar then
    local buttonHeight = scroll.ScrollBar.ScrollUpButton and scroll.ScrollBar.ScrollUpButton:GetHeight() or 16
    scroll.ScrollBar:ClearAllPoints()
    scroll.ScrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", -16, -buttonHeight - 1)
    scroll.ScrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", -16, buttonHeight + 1)
    scroll.ScrollBar:SetWidth(16)
  end
  return scroll, child
end

-- The title band of a section of the middle column, in the quest font of the journal.
function ns.sectionHeader(parent, text, y)
  local header = panel(parent, 368, 27); header:SetPoint("TOPLEFT", 18, y)
  header:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  header:SetBackdropColor(.13, .075, .028, 1); header:SetBackdropBorderColor(.62, .40, .12, 1)
  local title = label(header, text, 16, {1, .82, .34}); title:SetPoint("CENTER", 0, 1); useQuestFont(title, 17, true)
  return header, title
end

-- The details box of the middle column, under its section header.
function ns.detailBox(parent, y, height)
  local detail = panel(parent, 368, height); detail:SetPoint("TOPLEFT", 18, y)
  detail:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 13, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  detail:SetBackdropColor(.12, .070, .028, 1); detail:SetBackdropBorderColor(.62, .40, .12, 1)
  return detail
end

-- The round progress counter: a percentage within a ring of segments. It deliberately has
-- no square background or border, so that it sits on any artwork.
local RING_SEGMENTS = 28
function ns.progressRing(parent, caption)
  local orb = CreateFrame("Frame", nil, parent); orb:SetSize(90, 90)
  orb.text = label(orb, "", 22, ns.PROGRESS_TEXT_COLOR); orb.text:SetPoint("CENTER", 0, 5)
  local captionText = label(orb, caption, 7, {.8, .86, .76}); captionText:SetPoint("TOP", orb.text, "BOTTOM", 0, -1)
  orb.segments = {}
  for segmentIndex = 1, RING_SEGMENTS do
    local segment = orb:CreateTexture(nil, "ARTWORK")
    local angle = math.rad((segmentIndex - 1) * (360 / RING_SEGMENTS) - 90)
    segment:SetTexture("Interface/Buttons/WHITE8X8")
    segment:SetSize(4, 9); segment:SetPoint("CENTER", orb, "CENTER", math.cos(angle) * 39, math.sin(angle) * 39)
    if segment.SetRotation then segment:SetRotation(angle) end
    orb.segments[segmentIndex] = segment
  end
  return orb
end

function ns.paintProgressRing(segments, pct)
  for ringIndex, segment in ipairs(segments or {}) do
    if ringIndex <= math.floor((pct / 100) * #segments + .5) then
      segment:SetVertexColor(unpack(ns.PROGRESS_RING_COLOR))
    else
      segment:SetVertexColor(.16, .18, .15, .95)
    end
  end
end
