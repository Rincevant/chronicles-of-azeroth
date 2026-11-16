-- The Quests tab: zones on the left, the selected zone and quest in the middle, the quests
-- of the zone on the right.

local _, ns = ...
local CA = ns.CA
local label, shortText, useQuestFont, continentTab = ns.label, ns.shortText, ns.useQuestFont, ns.continentTab
local ASSET_PATH = ns.ASSET_PATH

local QUEST_ROW_HEIGHT = 24
-- A Classic zone rarely exceeds 300 quests; this margin avoids rebuilding
-- any panel and protects the list if Forever adds
-- new quests to a zone.
local MAX_QUEST_ROWS = 500

function CA:RefreshZoneList(resetScroll)
  if not self.zoneRows or not self.zoneScrollChild then return end
  local visibleRow = 0
  for index, zone in ipairs(self.zones) do
    local row = self.zoneRows[index]
    local shown = self:IsZoneVisible(zone)
    row.button:SetShown(shown)
    if shown then
      row.button:ClearAllPoints()
      row.button:SetPoint("TOPLEFT", 0, -(visibleRow * 76))
      visibleRow = visibleRow + 1
    end
  end
  self.zoneScrollChild:SetHeight(math.max(285, visibleRow * 76))
  if resetScroll and self.zoneScroll then self.zoneScroll:SetVerticalScroll(0) end
end

function CA:SetActiveContinent(continent)
  self.activeContinent = continent == "kalimdor" and "kalimdor" or "east"
  local first = self:GetFirstVisibleZone()
  if first then self.selectedZoneKey = first.key end
  self:RefreshZoneList(true)
  self:Refresh()
end

function CA:CreateQuestUI(f)
  local left, center, right = ns.columns(f, 25, -118)
  local lh = label(left, self:L("zones"), 16); lh:SetPoint("TOPLEFT", 15, -14)
  self.activeContinent = self.activeContinent or "east"
  self.continentTabs = {
    east = continentTab(left, self:L("easternKingdoms"), "Interface\\Icons\\Achievement_Zone_EasternKingdoms_01", 12, 110, function() self:SetActiveContinent("east") end),
    kalimdor = continentTab(left, self:L("kalimdor"), "Interface\\Icons\\Achievement_Zone_Kalimdor_01", 123, 110, function() self:SetActiveContinent("kalimdor") end),
  }
  local zoneSearch = CreateFrame("Frame", nil, left, "BackdropTemplate"); zoneSearch:SetSize(221, 23); zoneSearch:SetPoint("TOPLEFT", 12, -72)
  zoneSearch:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 8 })
  zoneSearch:SetBackdropColor(.01, .015, .02, .92); zoneSearch:SetBackdropBorderColor(.42, .32, .16, .9)
  local zoneSearchIcon = zoneSearch:CreateTexture(nil, "ARTWORK"); zoneSearchIcon:SetTexture("Interface/Common/UI-Searchbox-Icon"); zoneSearchIcon:SetSize(15, 15); zoneSearchIcon:SetPoint("LEFT", 6, 0)
  local zoneSearchText = label(zoneSearch, self:L("searchZone"), 8, {.54, .54, .50}); zoneSearchText:SetPoint("LEFT", zoneSearchIcon, "RIGHT", 4, 0)
  local zoneSearchEdit = CreateFrame("EditBox", nil, zoneSearch)
  zoneSearchEdit:SetPoint("TOPLEFT", 2, 1); zoneSearchEdit:SetPoint("BOTTOMRIGHT", -2, -1)
  zoneSearchEdit:SetFont(STANDARD_TEXT_FONT, 9, "")
  zoneSearchEdit:SetTextColor(.9, .86, .72); zoneSearchEdit:SetTextInsets(25, 5, 0, 0)
  zoneSearchEdit:SetAutoFocus(false)
  zoneSearchEdit:SetScript("OnEscapePressed", function(edit) edit:ClearFocus() end)
  zoneSearchEdit:SetScript("OnTextChanged", function(edit)
    self.zoneSearchQuery = edit:GetText() or ""
    zoneSearchText:SetShown(self.zoneSearchQuery == "")
    if self.zoneRows then
      local first = self:GetFirstVisibleZone()
      if first then self.selectedZoneKey = first.key end
      self:RefreshZoneList(true)
      self:Refresh()
    end
  end)
  self.zoneSearchEdit = zoneSearchEdit
  self.selectedZoneKey = self.selectedZoneKey or self.zones[1].key
  local zoneScroll, zoneScrollChild = ns.scrollList(left, 12, -102, 221, 285, 201, math.max(285, #self.zones * 76))
  self.zoneScroll, self.zoneScrollChild = zoneScroll, zoneScrollChild
  self.zoneRows = {}
  for i, zone in ipairs(self.zones) do
    local row = CreateFrame("Button", nil, zoneScrollChild, "BackdropTemplate")
    row:SetSize(201, 70); row:SetPoint("TOPLEFT", 0, -(i - 1) * 76)
    local rowBackground = ASSET_PATH .. (zone.cardArt or "zone-elwynn.tga")
    -- The zone is a real full-width card. Only its title rests
    -- on a dark cartouche, to stay readable on every image.
    row:SetBackdrop({ bgFile = rowBackground, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 11, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    row:SetBackdropColor(1, 1, 1, 1); row:SetBackdropBorderColor(.50, .35, .11, .9)
    local artShade = row:CreateTexture(nil, "BORDER"); artShade:SetAllPoints(); artShade:SetTexture("Interface/ChatFrame/ChatFrameBackground"); artShade:SetVertexColor(.01, .01, .005, .16)
    local caption = CreateFrame("Frame", nil, row, "BackdropTemplate")
    caption:SetPoint("BOTTOMLEFT", 5, 5); caption:SetPoint("BOTTOMRIGHT", -5, 5); caption:SetHeight(22)
    caption:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground" }); caption:SetBackdropColor(.005, .008, .010, .82)
    local name = label(caption, self:GetZoneName(zone), 10, {1, .86, .45}); name:SetPoint("LEFT", 7, 0); name:SetWidth(130); name:SetJustifyH("LEFT"); name:SetWordWrap(false)
    local count = label(caption, "", 9, {.96, .88, .55}); count:SetPoint("RIGHT", -7, 0)
    -- The frame stays entirely within the card, so the ScrollFrame cannot
    -- clip it on the first or the last row.
    local selected = CreateFrame("Frame", nil, row, "BackdropTemplate")
    selected:SetAllPoints()
    selected:SetFrameLevel(row:GetFrameLevel() + 3)
    selected:SetBackdrop({ edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14 })
    selected:SetBackdropBorderColor(1, .65, .06, 1)
    -- The Blizzard pattern draws the corners; the four inner lines make the
    -- selection readable without ever overflowing the card while scrolling.
    local selectedTop = selected:CreateTexture(nil, "OVERLAY"); selectedTop:SetColorTexture(1, .72, .08, 1); selectedTop:SetPoint("TOPLEFT", 2, -2); selectedTop:SetPoint("TOPRIGHT", -2, -2); selectedTop:SetHeight(2)
    local selectedBottom = selected:CreateTexture(nil, "OVERLAY"); selectedBottom:SetColorTexture(1, .72, .08, 1); selectedBottom:SetPoint("BOTTOMLEFT", 2, 2); selectedBottom:SetPoint("BOTTOMRIGHT", -2, 2); selectedBottom:SetHeight(2)
    local selectedLeft = selected:CreateTexture(nil, "OVERLAY"); selectedLeft:SetColorTexture(1, .72, .08, 1); selectedLeft:SetPoint("TOPLEFT", 2, -2); selectedLeft:SetPoint("BOTTOMLEFT", 2, 2); selectedLeft:SetWidth(2)
    local selectedRight = selected:CreateTexture(nil, "OVERLAY"); selectedRight:SetColorTexture(1, .72, .08, 1); selectedRight:SetPoint("TOPRIGHT", -2, -2); selectedRight:SetPoint("BOTTOMRIGHT", -2, 2); selectedRight:SetWidth(2)
    selected:Hide()
    local zoneKey = zone.key
    row:SetScript("OnClick", function() self.selectedZoneKey = zoneKey; self:Refresh() end)
    self.zoneRows[i] = { name = name, count = count, selected = selected, button = row }
  end

  local zoneName = label(center, self:GetZoneName(self.zones[1]), 20); zoneName:SetPoint("TOP", 0, -15); self.zoneName = zoneName
  local map = CreateFrame("Frame", nil, center, "BackdropTemplate"); map:SetSize(368, 126); map:SetPoint("TOP", 0, -45)
  map:SetBackdrop({ bgFile = ASSET_PATH .. "zone-elwynn.tga", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 13, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  map:SetBackdropColor(1, 1, 1, 1); map:SetBackdropBorderColor(.78, .58, .20, 1)
  local mapShade = map:CreateTexture(nil, "BORDER")
  mapShade:SetAllPoints(); mapShade:SetTexture("Interface/ChatFrame/ChatFrameBackground"); mapShade:SetVertexColor(.01, .02, .01, .16)
  local mapText = label(map, string.upper(self:GetZoneName(self.zones[1])), 12, {1, .86, .45}); mapText:SetPoint("TOPLEFT", 13, -12)
  local realm = label(map, self:GetContinentName("east") .. " - " .. self:GetFactionName("Alliance"), 9, {.92, .88, .74}); realm:SetPoint("TOPLEFT", 13, -31); self.realm = realm
  local count = label(map, "", 10, {.96, .93, .82}); count:SetPoint("BOTTOMLEFT", 14, 17); self.count = count
  -- The counter deliberately has no square background or border: only
  -- the percentage and its circular ring stay visible on the artwork.
  local orb = ns.progressRing(map, self:L("completed")); orb:SetPoint("TOPRIGHT", -11, -17)
  self.progress, self.progressRing = orb.text, orb.segments
  self.mapText = mapText
  self.mapHero = map
  ns.sectionHeader(center, self:L("rewards"), -180)
  local detail = ns.detailBox(center, -209, 180)
  self.rewardDetail = detail
  self.detailTitle = label(detail, "", 15, {1, .82, .34}); self.detailTitle:SetPoint("TOPLEFT", 11, -9); self.detailTitle:SetWidth(346); self.detailTitle:SetJustifyH("LEFT"); useQuestFont(self.detailTitle, 16, true)
  self.detailStatus = label(detail, "", 10, {.85, .79, .62}); self.detailStatus:SetPoint("TOPLEFT", 11, -33); self.detailStatus:SetWidth(346); self.detailStatus:SetJustifyH("LEFT"); useQuestFont(self.detailStatus, 10)
  self.detailChain = label(detail, "", 9, {.78, .78, .73}); self.detailChain:SetPoint("TOPLEFT", 11, -52); self.detailChain:SetWidth(346); self.detailChain:SetJustifyH("LEFT"); useQuestFont(self.detailChain, 9)
  self.detailRewards = label(detail, "", 10, {1, .82, .34}); self.detailRewards:SetPoint("TOPLEFT", 11, -83); self.detailRewards:SetWidth(346); self.detailRewards:SetJustifyH("LEFT"); useQuestFont(self.detailRewards, 10)
  self.rewardButtons = {}
  for i = 1, 6 do
    local reward = CreateFrame("Button", nil, detail, "BackdropTemplate")
    reward:SetSize(46, 46); reward:SetPoint("TOPLEFT", 11 + (i - 1) * 56, -109)
    reward:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 7 })
    reward.icon = reward:CreateTexture(nil, "ARTWORK"); reward.icon:SetPoint("TOPLEFT", 3, -3); reward.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    reward.count = label(reward, "", 8, {1, 1, 1}); reward.count:SetPoint("BOTTOMRIGHT", -2, 1)
    reward:SetScript("OnEnter", function(button)
      if type(button.itemID) ~= "number" then return end
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(button.itemID)
      GameTooltip:Show()
    end)
    reward:SetScript("OnLeave", function() GameTooltip:Hide() end)
    reward:Hide(); self.rewardButtons[i] = reward
  end
  self.badgeTexts = {}

  local rh = label(right, self:GetZoneQuestTitle(self.zones[1]), 15); rh:SetPoint("TOP", 0, -15); self.questTitle = rh
  local maxQuestRows = MAX_QUEST_ROWS
  for _, zone in ipairs(self.zones) do maxQuestRows = math.max(maxQuestRows, #zone.quests) end
  -- The content fills the usable width of the panel. The scroll bar
  -- stays in its own gutter, without needlessly narrowing the rows.
  local _, scrollChild = ns.scrollList(right, 10, -45, 360, 331, 338, maxQuestRows * QUEST_ROW_HEIGHT)
  self.questScrollChild = scrollChild
  self.questRows = {}
  for i = 1, maxQuestRows do
    local questID = self.zones[1].quests[i] and self.zones[1].quests[i].id
    local button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
    button:SetSize(338, QUEST_ROW_HEIGHT); button:SetPoint("TOPLEFT", 0, -((i - 1) * QUEST_ROW_HEIGHT))
    button:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 7 })
    button:SetBackdropColor(.10, .18, .28, 0)
    button.questID = questID
    button:SetScript("OnClick", function(clicked) self.selectedQuestID = clicked.questID; self:Refresh() end)
    -- The controls use the native +/- textures of the Blizzard journal.
    local toggle = CreateFrame("Button", nil, button)
    toggle:SetSize(22, 22); toggle:SetPoint("LEFT", 3, 0)
    toggle:RegisterForClicks("LeftButtonUp")
    toggle.icon = toggle:CreateTexture(nil, "ARTWORK"); toggle.icon:SetAllPoints(); toggle.icon:SetTexture("Interface/Buttons/UI-PlusButton-UP")
    toggle:Hide()
    local branch = button:CreateTexture(nil, "BORDER")
    branch:SetTexture("Interface/Buttons/WHITE8X8"); branch:SetSize(2, 19); branch:SetPoint("LEFT", 6, 0); branch:Hide()
    local state = label(button, "", 10, {.82, .86, .9}); state:SetWidth(20); state:SetJustifyH("CENTER")
    state:SetPoint("LEFT", 5, 0)
    local name = label(button, "", 10, {.82, .86, .9}); name:SetWidth(174); name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    name:SetPoint("LEFT", 30, 0)
    local level = label(button, "", 7, {.72, .78, .84}); level:SetWidth(50); level:SetJustifyH("RIGHT")
    level:SetPoint("LEFT", 208, 0)
    local xp = label(button, "", 7, {.66, .72, .8}); xp:SetWidth(50); xp:SetJustifyH("RIGHT")
    xp:SetPoint("LEFT", 263, 0)
    local check = button:CreateTexture(nil, "ARTWORK"); check:SetSize(15, 15); check:SetPoint("RIGHT", -5, 0); check:SetTexture("Interface/RaidFrame/ReadyCheck-Ready"); check:Hide()
    self.questRows[i] = { button = button, toggle = toggle, state = state, name = name, level = level, xp = xp, check = check, branch = branch }
  end
  self.questSummary = label(right, "", 10, {.66, .72, .8}); self.questSummary:SetPoint("BOTTOM", 0, 12)
  self.questPanels = { left, center, right }
end

function CA:RefreshQuests()
  local mode = self:GetTrackingMode()
  if self.continentTabs then
    for key, tab in pairs(self.continentTabs) do
      local active = self.activeContinent == key
      tab:SetBackdropColor(active and .27 or .035, active and .16 or .045, active and .025 or .06, 1)
      tab:SetBackdropBorderColor(active and 1 or .38, active and .70 or .34, active and .10 or .18, active and 1 or .75)
      tab.text:SetTextColor(active and 1 or .62, active and .84 or .66, active and .28 or .70)
    end
  end
  local currentZone = self:GetSelectedZone()
  if not self:IsZoneVisible(currentZone) then
    local firstVisible = self:GetFirstVisibleZone()
    if firstVisible then self.selectedZoneKey = firstVisible.key end
  end
  self:RefreshZoneList(false)
  for i, zone in ipairs(self.zones) do
    local zoneDone, zoneTotal = self:ZoneProgress(zone)
    self.zoneRows[i].name:SetText(shortText(self:GetZoneName(zone), 22))
    self.zoneRows[i].count:SetText(zoneDone .. " / " .. zoneTotal)
    self.zoneRows[i].button:SetBackdropBorderColor(self.selectedZoneKey == zone.key and .95 or .68, self.selectedZoneKey == zone.key and .72 or .47, self.selectedZoneKey == zone.key and .24 or .15, 1)
    self.zoneRows[i].selected:SetShown(self.selectedZoneKey == zone.key)
  end

  local zone = self:GetSelectedZone()
  local done, total, pct = self:ZoneProgress(zone)
  self.zoneName:SetText(self:GetZoneName(zone))
  self.progress:SetText(pct .. "%")
  self.count:SetText(self:L("questCount", done, total, mode == "account" and self:L("account") or self:L("character")))
  self.mapText:SetText(string.upper(self:GetZoneName(zone)))
  self.realm:SetText(self:GetContinentName(zone.continentKey) .. " - " .. self:GetFactionName(zone.faction))
  self.questTitle:SetText(self:GetZoneQuestTitle(zone))
  local heroArt = zone.heroArt or "zone-elwynn.tga"
  if self.displayedHeroArt ~= heroArt then
    self.mapHero:SetBackdrop({ bgFile = ASSET_PATH .. heroArt, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 13, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    self.mapHero:SetBackdropColor(1, 1, 1, 1); self.mapHero:SetBackdropBorderColor(.78, .58, .20, 1)
    self.displayedHeroArt = heroArt
  end
  ns.paintProgressRing(self.progressRing, pct)

  local availableQuests = self:GetAccessibleZoneQuests(zone)
  -- Some Classic zones (for example Deadwind Pass) really have
  -- no outdoor quest in the Forever data. The panel says so
  -- without suggesting that an external addon must be enabled.
  if #availableQuests == 0 then
    for _, row in ipairs(self.questRows) do
      row.state:Hide(); row.name:Hide(); row.level:Hide(); row.xp:Hide(); row.check:Hide(); row.button:Hide(); row.toggle:Hide(); row.branch:Hide()
    end
    self.questScrollChild:SetHeight(331)
    self.questSummary:SetText(self:L("noZoneQuests"))
    self.detailTitle:SetText(self:L("noQuestListed"))
    self.detailStatus:SetText(self:L("noZoneQuestDetail"))
    self.detailStatus:SetTextColor(.85, .79, .62)
    self.detailChain:SetText(self:L("prerequisites") .. ": —\n" .. self:L("next") .. ": —")
    self.detailRewards:SetText(self:L("rewardsWhenSelected"))
    self.rewardDetail:SetHeight(116)
    for _, button in ipairs(self.rewardButtons) do button.itemID = nil; button:Hide() end
    return
  end

  local selectedID, selectedQuest = self.selectedQuestID, nil
  for _, quest in ipairs(availableQuests) do
    if quest.id == selectedID then selectedQuest = quest; break end
  end
  if not selectedQuest then selectedQuest = availableQuests[1]; selectedID = selectedQuest.id end
  self.selectedQuestID = selectedID

  local tree = self:BuildQuestDisplay(zone)
  local requiredRemaining, visibleRow = total - done, 0
  for j, treeEntry in ipairs(tree) do
    -- The cap is deliberately generous (500). This guard is an extra
    -- safety net should a future database hold an abnormal zone.
    local row = self.questRows[j]
    if not row then break end
    local quest
    for _, candidate in ipairs(availableQuests) do if candidate.id == treeEntry.id then quest = candidate; break end end
    local complete = self:IsQuestCompleted(quest.id)
    local hideOptionalForCharacter = mode == "character" and quest.optional
      and not self:IsQuestCompletedForCharacter(quest.id)
      and self:IsQuestCompletedForAccount(quest.id)
    row.state:SetShown(not hideOptionalForCharacter)
    row.name:SetShown(not hideOptionalForCharacter)
    row.level:SetShown(not hideOptionalForCharacter)
    row.xp:SetShown(not hideOptionalForCharacter)
    row.check:Hide()
    row.button:SetShown(not hideOptionalForCharacter)
    row.toggle:SetShown(not hideOptionalForCharacter and treeEntry.group)
    row.branch:SetShown(not hideOptionalForCharacter and treeEntry.child and not treeEntry.group)
    if not hideOptionalForCharacter then
      row.button:ClearAllPoints(); row.button:SetPoint("TOPLEFT", 0, -(visibleRow * QUEST_ROW_HEIGHT))
      row.button.questID = quest.id
      row.toggle:ClearAllPoints(); row.toggle:SetPoint("LEFT", 3, 0)
      row.state:ClearAllPoints(); row.state:SetPoint("LEFT", 5, 0)
      row.name:ClearAllPoints(); row.name:SetPoint("LEFT", 30, 0); row.name:SetWidth(174)
      row.level:ClearAllPoints(); row.level:SetPoint("LEFT", 208, 0)
      row.xp:ClearAllPoints(); row.xp:SetPoint("LEFT", 263, 0)
      visibleRow = visibleRow + 1
      local meta = self:GetQuestMeta(quest.id)
      local questLevel, xp = meta and meta[1] or "?", meta and meta[3]
      local isGroup = treeEntry.group
      local displayName = shortText(self:QuestName(quest.id), isGroup and 24 or 26)
      if quest.id == selectedID then
        row.button:SetBackdropColor(.10, .31, .42, .96); row.button:SetBackdropBorderColor(.30, .62, .76, 1)
      elseif isGroup then
        row.button:SetBackdropColor(.16, .085, .018, .98); row.button:SetBackdropBorderColor(.62, .40, .12, 1)
      elseif treeEntry.child then
        row.button:SetBackdropColor(.015, .040, .055, .92); row.button:SetBackdropBorderColor(.15, .21, .21, .42)
      else
        row.button:SetBackdropColor(.035, .055, .070, .78); row.button:SetBackdropBorderColor(.15, .21, .21, .22)
      end
      if treeEntry.child and not isGroup then row.branch:SetVertexColor(.65, .48, .14, .9) end
      if isGroup then
        row.toggle.icon:SetTexture(treeEntry.expanded and "Interface/Buttons/UI-MinusButton-UP" or "Interface/Buttons/UI-PlusButton-UP")
        row.toggle.questID = quest.id
        row.toggle:SetScript("OnClick", function(toggle)
          self.expandedGroups[toggle.questID] = not self.expandedGroups[toggle.questID]
          self:Refresh()
        end)
      end
      local inLog = self:IsQuestInLog(quest.id)
      if isGroup then
        local firstLevel = treeEntry.groupMinLevel or questLevel
        local lastLevel = treeEntry.groupMaxLevel or questLevel
        row.state:Hide()
        row.name:SetText(displayName)
        row.level:SetText(firstLevel == lastLevel and (self:L("level") .. " " .. firstLevel) or (self:L("level") .. " " .. firstLevel .. "-" .. lastLevel))
        row.xp:SetText((treeEntry.groupDone or 0) .. " / " .. (treeEntry.groupTotal or 1))
        if treeEntry.groupDone == treeEntry.groupTotal then
          row.name:SetTextColor(.35, 1, .45); row.level:SetTextColor(.35, 1, .45); row.xp:SetTextColor(.35, 1, .45)
        else
          row.name:SetTextColor(1, .82, .35); row.level:SetTextColor(.88, .74, .34); row.xp:SetTextColor(.88, .74, .34)
        end
      elseif inLog then
        row.state:SetText(">"); row.name:SetText(displayName); row.level:SetText(self:L("level") .. " " .. questLevel); row.xp:SetText(xp and ("XP " .. xp) or "—")
        row.state:SetTextColor(1, .82, .2); row.name:SetTextColor(1, .82, .2)
        row.level:SetTextColor(.86, .76, .38); row.xp:SetTextColor(.86, .76, .38)
      elseif complete then
        row.state:SetText(""); row.name:SetText(displayName); row.level:SetText(self:L("level") .. " " .. questLevel); row.xp:SetText(xp and ("XP " .. xp) or "—")
        row.name:SetTextColor(.35, 1, .45); row.level:SetTextColor(.66, .88, .68); row.xp:SetTextColor(.66, .88, .68); row.check:Show()
      elseif quest.optional then
        row.state:SetText("~"); row.name:SetText(displayName .. " (" .. self:L("optional") .. ")"); row.level:SetText(self:L("level") .. " " .. questLevel); row.xp:SetText(xp and ("XP " .. xp) or "—")
        row.state:SetTextColor(.62, .75, .9); row.name:SetTextColor(.62, .75, .9)
        row.level:SetTextColor(.62, .75, .9); row.xp:SetTextColor(.62, .75, .9)
      else
        local r, g, b = self:GetQuestDifficultyColor(quest.id)
        row.state:SetText("•"); row.name:SetText(displayName); row.level:SetText(self:L("level") .. " " .. questLevel); row.xp:SetText(xp and ("XP " .. xp) or "—")
        row.state:SetTextColor(r, g, b); row.name:SetTextColor(r, g, b)
        row.level:SetTextColor(.72, .78, .84); row.xp:SetTextColor(.72, .78, .84)
      end
    end
  end
  for j = #tree + 1, #self.questRows do
    local row = self.questRows[j]
    row.state:Hide(); row.name:Hide(); row.level:Hide(); row.xp:Hide(); row.check:Hide(); row.button:Hide(); row.toggle:Hide(); row.branch:Hide()
  end
  self.questScrollChild:SetHeight(math.max(331, visibleRow * QUEST_ROW_HEIGHT))
  self.questSummary:SetText(self:L("questsRequired", done, total, requiredRemaining))

  local meta = self:GetQuestMeta(selectedID) or {}
  local inLog = self:IsQuestInLog(selectedID)
  local link = self:GetQuestLinks(selectedID)
  self.detailTitle:SetText(self:QuestName(selectedID))
  self.detailStatus:SetText((inLog and self:L("questInProgress") or (self:IsQuestCompleted(selectedID) and self:L("questCompleted") or self:L("questDiscover"))) .. " - " .. self:L("level") .. " " .. (meta[1] or "?") .. " (" .. self:L("required") .. " " .. (meta[2] or "?") .. ")")
  if inLog then
    self.detailStatus:SetTextColor(1, .82, .2)
  elseif self:IsQuestCompleted(selectedID) then
    self.detailStatus:SetTextColor(.35, 1, .45)
  else
    self.detailStatus:SetTextColor(.85, .79, .62)
  end
  self.detailChain:SetText(self:L("prerequisites") .. ": " .. self:LinkNames(link.previous) .. "\n" .. self:L("next") .. ": " .. self:LinkNames(link.next))
  local rewardItems = self:GetQuestRewardItems(selectedID)
  self.rewardDetail:SetHeight(#rewardItems > 0 and 164 or 116)
  local itemCount = #rewardItems
  self.detailRewards:SetText(self:GetRewardSummary(selectedID) .. (itemCount > 0 and (" - " .. itemCount .. " " .. (itemCount == 1 and self:L("object") or self:L("objects")) .. ", " .. self:L("hoverIcons")) or ""))
  for index, button in ipairs(self.rewardButtons) do
    local item = rewardItems[index]
    if item then
      local amount = tonumber(item.amount) or 1
      button.itemID = type(item.itemID) == "number" and item.itemID or nil
      if button.itemID and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(button.itemID) end
      local icon = item.texture
        or (button.itemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(button.itemID))
        or (button.itemID and GetItemIcon and GetItemIcon(button.itemID))
      button.icon:SetTexture(icon or "Interface/Icons/INV_Misc_QuestionMark")
      button.count:SetText(amount > 1 and amount or "")
      button:SetBackdropBorderColor(item.choice and 1 or .65, item.choice and .25 or .55, item.choice and .15 or .25, 1)
      button:Show()
    else
      button.itemID = nil; button:Hide()
    end
  end
end
