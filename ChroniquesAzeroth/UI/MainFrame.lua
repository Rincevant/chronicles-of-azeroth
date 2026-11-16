-- The main window: header, navigation tabs, context bar and the refresh of the active tab.

local _, ns = ...
local CA = ns.CA
local panel, label, modeButton, topTab = ns.panel, ns.label, ns.modeButton, ns.topTab
local ASSET_PATH = ns.ASSET_PATH

-- Native Blizzard emblems: the indicator stays right whatever the
-- logged-in character, without shipping an external image for the factions.
local FACTION_ICON_TEXTURES = {
  Alliance = "Interface\\TargetingFrame\\UI-PVP-Alliance",
  Horde = "Interface\\TargetingFrame\\UI-PVP-Horde",
}

function CA:RefreshNavigationTabs()
  for _, tab in ipairs(self.navigationTabs or {}) do
    local active = tab.section == self.activeSection
    tab:SetBackdropColor(active and .25 or .045, active and .15 or .055, active and .025 or .07, 1)
    tab:SetBackdropBorderColor(active and 1 or .35, active and .72 or .38, active and .16 or .42, active and 1 or .65)
    if active then
      tab.text:SetTextColor(1, .84, .32)
    elseif tab.available then
      tab.text:SetTextColor(.80, .84, .90)
    else
      tab.text:SetTextColor(.52, .56, .60)
    end
  end
end

function CA:SetActiveSection(section)
  if section ~= "quests" and section ~= "professions" and section ~= "feedback" then return end
  self.activeSection = section
  local questsVisible = section == "quests"
  local professionsVisible = section == "professions"
  local feedbackVisible = section == "feedback"
  for _, widget in ipairs(self.questPanels or {}) do
    if questsVisible then widget:Show() else widget:Hide() end
  end
  if self.professionView then
    if professionsVisible then self.professionView:Show() else self.professionView:Hide() end
  end
  if self.feedbackView then
    if feedbackVisible then self.feedbackView:Show() else self.feedbackView:Hide() end
  end
  if self.footer then
    self.footer:SetText(questsVisible
      and self:L("footerQuests")
      or (professionsVisible and self:L("footerProfessions") or self:L("footerFeedback")))
  end
  self:RefreshNavigationTabs()
  self:Refresh()
end

function CA:CreateUI()
  local f = panel(UIParent, 1100, 565)
  f:SetPoint("CENTER")
  f:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", edgeSize = 22, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
  f:SetBackdropColor(.075, .042, .020, .98); f:SetBackdropBorderColor(.70, .48, .16, 1)
  -- Non-modal browsing window, but placed above the ordinary panels
  -- of other addons. DIALOG stays below the real WoW tooltips.
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetScript("OnShow", function(frame) frame:Raise() end)
  f:SetScript("OnMouseDown", function(frame) frame:Raise() end)
  f:Hide(); self.frame = f

  -- Header inspired by the Legacy window: dark band, golden line and
  -- round medallion without a square frame.
  local header = CreateFrame("Frame", nil, f, "BackdropTemplate")
  header:SetPoint("TOPLEFT", 22, -7); header:SetPoint("TOPRIGHT", -22, -7); header:SetHeight(32)
  header:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  header:SetBackdropColor(.17, .09, .035, 1); header:SetBackdropBorderColor(.64, .42, .14, 1)
  -- The wide cartouche hid the title on some beta clients: the
  -- medallion stays, but the decorative header no longer covers the text.
  header:Hide()
  -- The starred medallion is the signature of Chronicles. Its built-in ring
  -- keeps the metallic outline, with only a slight overlap of the
  -- top left corner of the frame.
  local medal = f:CreateTexture(nil, "OVERLAY")
  medal:SetTexture(ASSET_PATH .. "heritage-medallion.tga"); medal:SetSize(64, 64)
  medal:SetPoint("TOPLEFT", f, "TOPLEFT", -10, 5)
  local title = label(f, self:L("addonTitle"), 20)
  title:SetPoint("TOP", 0, -10)
  local subtitle = label(f, self:L("subtitle"), 12, {.7, .75, .8})
  subtitle:SetPoint("TOP", title, "BOTTOM", 0, -3)
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -5, -5)

  local tabDefs = {
    { key = "quests", text = self:L("quests"), icon = "Interface\\Icons\\INV_Misc_Note_01", enabled = true },
    { key = "professions", text = self:L("professions"), icon = "Interface\\Icons\\INV_Hammer_20", enabled = true },
    { key = "toys", text = self:L("toysSoon"), icon = "Interface\\Icons\\INV_Misc_Toy_10" },
    { key = "dungeons", text = self:L("dungeonsSoon"), icon = "Interface\\Icons\\INV_Misc_Bone_01" },
    { key = "raids", text = self:L("raidsSoon"), icon = "Interface\\Icons\\INV_Misc_Head_Human_02" },
    { key = "feedback", text = self:L("feedback"), icon = "Interface\\Icons\\INV_Misc_Note_06", enabled = true },
  }
  self.navigationTabs = {}
  for index, tabDef in ipairs(tabDefs) do
    local section = tabDef.key
    local tab = topTab(f, tabDef.text, tabDef.icon, 108 + (index - 1) * 144, 136, tabDef.enabled, function() self:SetActiveSection(section) end)
    tab.section = section
    self.navigationTabs[index] = tab
  end
  local tabDivider = f:CreateTexture(nil, "BORDER"); tabDivider:SetTexture("Interface/Buttons/WHITE8X8"); tabDivider:SetSize(955, 2); tabDivider:SetPoint("TOP", 0, -88); tabDivider:SetVertexColor(.58, .40, .12, .8)

  -- Context bar shared by every tab. The former content filters
  -- (expansion, continents and levels) no longer led to any action:
  -- only the faction of the logged-in character matters here.
  local contextDivider = f:CreateTexture(nil, "BORDER")
  contextDivider:SetTexture("Interface/Buttons/WHITE8X8"); contextDivider:SetSize(955, 1)
  contextDivider:SetPoint("TOP", 0, -115); contextDivider:SetVertexColor(.42, .29, .10, .65)
  -- Two groups on the same baseline: the text and the icons no longer
  -- seem to rise or fall depending on their font or texture.
  local factionGroup = CreateFrame("Frame", nil, f); factionGroup:SetSize(265, 24); factionGroup:SetPoint("TOPLEFT", 28, -90)
  local factionPrefix = label(factionGroup, self:L("faction"), 10, {.72, .84, .95}); factionPrefix:SetSize(60, 22); factionPrefix:SetPoint("LEFT", 0, 0); factionPrefix:SetJustifyH("LEFT"); factionPrefix:SetJustifyV("MIDDLE")
  local factionIcon = factionGroup:CreateTexture(nil, "ARTWORK"); factionIcon:SetSize(18, 18); factionIcon:SetPoint("LEFT", factionPrefix, "RIGHT", 3, 0)
  factionIcon:SetTexCoord(.08, .92, .08, .92)
  local factionName = label(factionGroup, "", 11, {.94, .84, .42}); factionName:SetSize(130, 22); factionName:SetPoint("LEFT", factionIcon, "RIGHT", 3, 0); factionName:SetJustifyH("LEFT"); factionName:SetJustifyV("MIDDLE")
  self.factionPrefix, self.factionIcon, self.factionName = factionPrefix, factionIcon, factionName
  local trackingGroup = CreateFrame("Frame", nil, f); trackingGroup:SetSize(315, 24); trackingGroup:SetPoint("TOPRIGHT", -28, -90)
  local tracking = label(trackingGroup, self:L("tracking"), 10, {.72, .84, .95}); tracking:SetSize(76, 22); tracking:SetPoint("LEFT", 0, 0); tracking:SetJustifyV("MIDDLE")
  self.tracking = tracking
  self.accountButton = modeButton(trackingGroup, self:L("account"), 80, -1, function() self:SetTrackingMode("account") end)
  self.characterButton = modeButton(trackingGroup, self:L("character"), 190, -1, function() self:SetTrackingMode("character") end)

  self:CreateQuestUI(f)
  local footer = label(f, self:L("footerQuests"), 10, {.66, .72, .8}); footer:SetPoint("BOTTOM", 0, 12)
  self.footer = footer
  self:CreateProfessionUI(f)
  self:CreateFeedbackUI(f)
  self.activeSection = self.activeSection or "quests"
  self:SetActiveSection(self.activeSection)
end

function CA:Refresh()
  if not self.frame then return end
  self:RefreshNavigationTabs()
  local faction = self:GetPlayerFaction()
  if self.factionName then
    self.factionName:SetText(self:GetFactionName(faction))
  end
  if self.factionIcon then
    self.factionIcon:SetTexture(FACTION_ICON_TEXTURES[faction] or "Interface/Icons/INV_Misc_QuestionMark")
  end
  local mode = self:GetTrackingMode()
  -- The selector is shared by Quests and Professions: painting it before the
  -- early return of the Professions tab avoids the former frozen look.
  self.accountButton:SetBackdropColor(mode == "account" and .12 or .035, mode == "account" and .38 or .055, mode == "account" and .18 or .09, 1)
  self.accountButton:SetBackdropBorderColor(mode == "account" and .25 or .45, mode == "account" and .9 or .45, mode == "account" and .35 or .45, 1)
  self.characterButton:SetBackdropColor(mode == "character" and .12 or .035, mode == "character" and .38 or .055, mode == "character" and .18 or .09, 1)
  self.characterButton:SetBackdropBorderColor(mode == "character" and .25 or .45, mode == "character" and .9 or .45, mode == "character" and .35 or .45, 1)
  if self.activeSection == "professions" then
    self:RefreshProfessions()
    return
  end
  if self.activeSection == "feedback" then
    self:RefreshFeedback()
    return
  end
  self:RefreshQuests()
end
