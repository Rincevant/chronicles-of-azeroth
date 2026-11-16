-- The Feedback tab: a diagnostic report to copy into a GitHub issue or the Discord.

local _, ns = ...
local CA = ns.CA
local panel, label = ns.panel, ns.label

function CA:BuildFeedbackReport()
  local zone = self:GetSelectedZone()
  local profession = ns.PROFESSION_BY_ID[self.selectedProfessionID or 0]
  local mode = self:GetTrackingMode() == "account" and self:L("account") or self:L("character")
  return table.concat({
    self:L("addonTitle") .. " - " .. self:L("feedback"),
    self:L("reportVersion") .. ": " .. self.VERSION,
    self:L("reportLocale") .. ": " .. tostring(GetLocale and GetLocale() or self.locale),
    self:L("reportCharacter") .. ": " .. tostring(UnitName("player") or "?"),
    self:L("reportRealm") .. ": " .. tostring(GetRealmName and GetRealmName() or "?"),
    self:L("reportSection") .. ": " .. tostring(self.activeSection or "quests"),
    self:L("reportTracking") .. ": " .. mode,
    self:L("reportZone") .. ": " .. self:GetZoneName(zone),
    self:L("reportProfession") .. ": " .. (profession and self:GetProfessionName(profession) or "-"),
    "",
    self:L("reportProblem") .. ":",
    "",
    self:L("reportSteps") .. ":",
    "",
    self:L("reportExpected") .. ":",
    "",
    self:L("reportActual") .. ":",
    "",
    "GitHub: " .. self.GITHUB_ISSUES_URL,
    "Discord: " .. self.DISCORD_URL,
  }, "\n")
end

function CA:PrepareFeedbackReport()
  local report = self:BuildFeedbackReport()
  if ChroniquesAzerothCharacterDB then ChroniquesAzerothCharacterDB.feedbackDraft = report end
  if self.feedbackReportEdit then
    self.feedbackReportEdit:SetText(report)
    self.feedbackReportEdit:SetFocus()
    self.feedbackReportEdit:HighlightText()
  end
end

function CA:RefreshFeedback()
  if self.feedbackCopyHint then self.feedbackCopyHint:SetText(self:L("feedbackCopyHint")) end
end

function CA:CopyFeedbackLink(url, hint)
  if self.feedbackReportEdit then
    self.feedbackReportEdit:SetText(url)
    self.feedbackReportEdit:SetFocus()
    self.feedbackReportEdit:HighlightText()
  end
  if self.feedbackCopyHint then self.feedbackCopyHint:SetText(hint) end
end

function CA:CreateFeedbackUI(parent)
  local view = CreateFrame("Frame", nil, parent)
  view:SetSize(1050, 400); view:SetPoint("TOPLEFT", 25, -118)
  self.feedbackView = view

  local content = panel(view, 1050, 400)
  content:SetPoint("TOPLEFT", 0, 0)
  local title = label(content, self:L("feedbackTitle"), 18); title:SetPoint("TOP", 0, -18)
  local description = label(content, self:L("feedbackDescription"), 10, {.78, .80, .76})
  description:SetPoint("TOPLEFT", 28, -54); description:SetWidth(994); description:SetJustifyH("LEFT"); description:SetWordWrap(true)

  local prepare = CreateFrame("Button", nil, content, "BackdropTemplate")
  prepare:SetSize(230, 28); prepare:SetPoint("TOPLEFT", 28, -93)
  prepare:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  prepare:SetBackdropColor(.21, .13, .025, 1); prepare:SetBackdropBorderColor(.86, .62, .12, .95)
  prepare.text = label(prepare, self:L("prepareReport"), 10, {1, .84, .32}); prepare.text:SetPoint("CENTER")
  prepare:SetScript("OnEnter", function(button) button:SetBackdropColor(.33, .20, .035, 1) end)
  prepare:SetScript("OnLeave", function(button) button:SetBackdropColor(.21, .13, .025, 1) end)
  prepare:SetScript("OnClick", function() self:PrepareFeedbackReport() end)

  local hint = label(content, self:L("feedbackCopyHint"), 9, {.68, .76, .84}); hint:SetPoint("LEFT", prepare, "RIGHT", 16, 0); hint:SetWidth(700); hint:SetJustifyH("LEFT")
  self.feedbackCopyHint = hint

  local edit = CreateFrame("EditBox", nil, content, "BackdropTemplate")
  edit:SetPoint("TOPLEFT", 28, -134); edit:SetSize(994, 174)
  edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFont(STANDARD_TEXT_FONT, 10, "")
  edit:SetTextColor(.92, .89, .76); edit:SetTextInsets(10, 10, 8, 8); edit:SetJustifyH("LEFT"); edit:SetJustifyV("TOP")
  edit:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  edit:SetBackdropColor(.01, .014, .018, .90); edit:SetBackdropBorderColor(.40, .29, .12, .85)
  edit:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  edit:SetScript("OnTextChanged", function(box, userInput)
    if userInput and ChroniquesAzerothCharacterDB then ChroniquesAzerothCharacterDB.feedbackDraft = box:GetText() end
  end)
  self.feedbackReportEdit = edit

  local discord = CreateFrame("Button", nil, content, "BackdropTemplate")
  discord:SetSize(190, 24); discord:SetPoint("TOPLEFT", 28, -319)
  discord:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10 })
  discord:SetBackdropColor(.12, .09, .22, 1); discord:SetBackdropBorderColor(.57, .42, .94, .95)
  discord.text = label(discord, self:L("copyDiscord"), 9, {.80, .70, 1}); discord.text:SetPoint("CENTER")
  discord:SetScript("OnEnter", function(button) button:SetBackdropColor(.22, .15, .38, 1) end)
  discord:SetScript("OnLeave", function(button) button:SetBackdropColor(.12, .09, .22, 1) end)
  discord:SetScript("OnClick", function() self:CopyFeedbackLink(self.DISCORD_URL, self:L("discordCopyHint")) end)

  local destination = label(content, self:L("feedbackDestination"), 10, {.88, .72, .32})
  destination:SetPoint("LEFT", discord, "RIGHT", 16, 0); destination:SetWidth(790); destination:SetJustifyH("LEFT"); destination:SetWordWrap(true)
  view:Hide()
end
