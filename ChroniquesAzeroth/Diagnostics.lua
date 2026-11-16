-- Startup diagnostics: the log records which client APIs exist, so that a feature that
-- misbehaves on the Forever client can be traced to a missing function from the log alone.

local _, ns = ...
local CA = ns.CA

local Diagnostics = {}
ns.Diagnostics = Diagnostics

-- Dotted paths of the APIs the addon can use; "|" separates alternatives.
local PROBES = {
  { "Completed quests", "C_QuestLog.IsQuestFlaggedCompleted|IsQuestFlaggedCompleted" },
  { "Quest titles", "C_QuestLog.GetTitleForQuestID" },
  { "Quest log lookup", "C_QuestLog.GetLogIndexForQuestID" },
  { "Quest rewards", "GetNumQuestLogRewards|C_QuestLog.GetQuestRewardInfo" },
  { "Item names", "C_Item.GetItemNameByID|GetItemInfo" },
  { "Item data requests", "C_Item.RequestLoadItemDataByID" },
  { "Spell names", "C_Spell.GetSpellInfo|GetSpellInfo" },
  { "Known spells", "IsSpellKnown|IsPlayerSpell" },
  { "Professions", "GetProfessions|GetNumSkillLines" },
  { "Profession window", "GetTradeSkillLine|C_TradeSkillUI.GetAllRecipeIDs" },
  { "Recipe details", "C_TradeSkillUI.GetRecipeSchematic|GetTradeSkillInfo" },
}

local function resolve(path)
  local value = _G
  for part in path:gmatch("[^%.]+") do
    if type(value) ~= "table" then return nil end
    value = value[part]
  end
  return value
end

-- Returns the first available alternative of a probe, or nil.
function Diagnostics.Find(alternatives)
  for path in alternatives:gmatch("[^|]+") do
    if resolve(path) ~= nil then return path end
  end
  return nil
end

function Diagnostics.ClientBuild()
  if not GetBuildInfo then return "?" end
  local version, build = GetBuildInfo()
  return tostring(version) .. "." .. tostring(build)
end

function Diagnostics:Run()
  local missing = {}
  for _, probe in ipairs(PROBES) do
    local found = self.Find(probe[2])
    if found then
      ns.Log:Debug("API %-20s -> %s", probe[1], found)
    else
      missing[#missing + 1] = probe[1]
    end
  end
  if #missing > 0 then
    ns.Log:Info("Unavailable APIs: %s", table.concat(missing, ", "))
  else
    ns.Log:Info("Every probed API is available")
  end
end

-- Full report for /ca diag, printed to the chat and written to the log.
function Diagnostics:Report()
  local lines = { string.format("Version %s, client %s, locale %s", CA.VERSION, self.ClientBuild(), tostring(GetLocale())) }
  for _, probe in ipairs(PROBES) do
    lines[#lines + 1] = string.format("%s: %s", probe[1], self.Find(probe[2]) or "MISSING")
  end
  for _, line in ipairs(lines) do ns.Log:Info("diag: %s", line) end
  return lines
end
