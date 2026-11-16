-- Feedback tab: a diagnostic report to copy into a GitHub issue or the Discord. The addon
-- cannot send anything on the Internet: the player copies the report and pastes it.

local _, ns = ...

local View = {}
ns.Views.Feedback = View

local L = ns.L
local UI, Theme = ns.UI, ns.Theme
local C = Theme.colors

local GITHUB_ISSUES_URL = "https://github.com/Rincevant/chronicles-of-azeroth/issues"
local DISCORD_URL = "https://discord.gg/hmQTKkdRzB"
View.GITHUB_ISSUES_URL, View.DISCORD_URL = GITHUB_ISSUES_URL, DISCORD_URL

-- Where the player stands in the window, so that the report tells what was shown.
local function selection(mainFrame)
    local lines = {}
    for tabID, view in pairs(mainFrame.frame and mainFrame.frame.views or {}) do
        local location = view.Location and ns:SafeCall("feedback location", view.Location, view)
        if location and location.back then lines[#lines + 1] = string.format("%s: %s", tabID, location.back) end
    end
    table.sort(lines)
    return lines
end

function View:BuildReport()
    local view = self.mainFrame:View()
    local lines = {
        L.ADDON_TITLE .. " - " .. L.TAB_FEEDBACK,
        L.REPORT_VERSION .. ": " .. ns.Compat.GetAddOnVersion() .. " (client " .. ns.Compat.GetClientBuild() .. ")",
        L.REPORT_LOCALE .. ": " .. tostring(GetLocale()),
        L.REPORT_CHARACTER .. ": " .. tostring(ns.Player.key),
        L.REPORT_TRACKING .. ": " .. (view.tracking == ns.Const.Tracking.ACCOUNT and L.TRACKING_ACCOUNT or L.TRACKING_CHARACTER),
        L.REPORT_TAB .. ": " .. tostring(self.mainFrame.previousTab or self.mainFrame.activeTab),
    }
    for _, line in ipairs(selection(self.mainFrame)) do lines[#lines + 1] = line end
    for _, line in ipairs({ "", L.REPORT_PROBLEM .. ":", "", L.REPORT_STEPS .. ":", "", L.REPORT_EXPECTED .. ":", "",
        L.REPORT_ACTUAL .. ":", "", "GitHub: " .. GITHUB_ISSUES_URL, "Discord: " .. DISCORD_URL }) do
        lines[#lines + 1] = line
    end
    -- The last log entries tell what the addon did before the problem.
    lines[#lines + 1] = ""
    for _, entry in ipairs(ns.Log:Tail(15)) do lines[#lines + 1] = entry end
    return table.concat(lines, "\n")
end

local function select(edit, text)
    edit:SetText(text)
    edit:SetFocus()
    edit:HighlightText()
end

function View:Build(frame)
    local panel = UI.Panel(frame)
    panel:SetAllPoints()
    local title = UI.Heading(panel, 22, L.FEEDBACK_TITLE, "fancy")
    title:SetPoint("TOP", 0, -18)
    local description = UI.Paragraph(panel, 13, C.text)
    description:SetPoint("TOPLEFT", 28, -56)
    description:SetPoint("TOPRIGHT", -28, -56)
    description:SetText(L.FEEDBACK_DESCRIPTION)

    local prepare = UI.Button(panel, 240, 30, L.PREPARE_REPORT, function()
        local report = self:BuildReport()
        local record = ns.Database:Character()
        if record then record.feedbackDraft = report end
        select(self.edit, report)
        self.hint:SetText(L.FEEDBACK_COPY_HINT)
    end)
    prepare:SetPoint("TOPLEFT", 28, -100)
    prepare:SetActive(true)
    self.hint = UI.Text(panel, 12, C.blue)
    self.hint:SetPoint("LEFT", prepare, "RIGHT", 16, 0)
    self.hint:SetPoint("RIGHT", panel, "RIGHT", -28, 0)
    self.hint:SetText(L.FEEDBACK_SELECT_HINT)

    local box = UI.Panel(panel, C.panelDark, C.borderDim)
    box:SetPoint("TOPLEFT", 28, -142)
    box:SetPoint("BOTTOMRIGHT", -28, 62)
    -- The report is longer than the box: it scrolls.
    local scroll, edit = UI.ScrollingEditBox(box, 12)
    scroll:SetPoint("TOPLEFT", 10, -8)
    scroll:SetPoint("BOTTOMRIGHT", -6, 8)
    self.scroll = scroll
    edit:SetScript("OnTextChanged", function(box, userInput)
        local record = ns.Database:Character()
        if userInput and record then record.feedbackDraft = box:GetText() end
    end)
    self.edit = edit

    local discord = UI.Button(panel, 220, 26, L.COPY_DISCORD, function()
        select(self.edit, DISCORD_URL)
        self.hint:SetText(L.DISCORD_COPY_HINT)
    end)
    discord:SetPoint("BOTTOMLEFT", 28, 22)
    local destination = UI.Text(panel, 12, C.goldDim)
    destination:SetPoint("LEFT", discord, "RIGHT", 16, 0)
    destination:SetPoint("RIGHT", panel, "RIGHT", -28, 0)
    destination:SetText(L.FEEDBACK_DESTINATION)
end

function View:Refresh()
    local record = ns.Database:Character()
    if self.edit:GetText() == nil or self.edit:GetText() == "" then
        self.edit:SetText(record and record.feedbackDraft or "")
    end
    self.mainFrame:SetFooter(L.FOOTER_FEEDBACK)
end
