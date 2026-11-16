-- Quest tracking: the embedded catalogue, the account and character progress, quest
-- details, chains and zone filtering.

local _, ns = ...
local CA = ns.CA


-- Fully embedded catalogue, generated at build time from the Forever data.
-- This initialization reads no variable of another addon: Chronicles
-- stays usable without any companion addon.
function CA:LoadEmbeddedQuestCatalog()
  local catalog = ChroniquesAzerothQuestCatalog
  if type(catalog) ~= "table" or type(catalog.zones) ~= "table" or type(catalog.quests) ~= "table" then
    self.zoneQuestIndexReady = true
    return
  end

  self.questMeta = {}
  self.questLinks = {}
  self.questTitleFallbacks = {}
  self.questSides = {}
  for questID, entry in pairs(catalog.quests) do
    if type(entry) == "table" then
      self.questMeta[questID] = { entry.q or entry.r or 1, entry.r or 1, entry.x }
      self.questTitleFallbacks[questID] = (self.locale == "frFR" and entry.t) or entry.e or entry.t or self:L("questFallback", questID)
      self.questSides[questID] = entry.s
      if entry.p or entry.n then
        self.questLinks[questID] = { previous = entry.p or {}, next = entry.n or {} }
      end
    end
  end

  for _, zone in ipairs(self.zones) do
    local questIDs = catalog.zones[zone.key]
    if type(questIDs) == "table" then
      zone.quests = {}
      for _, questID in ipairs(questIDs) do
        local entry = catalog.quests[questID]
        if entry then table.insert(zone.quests, { id = questID, side = entry.s, optional = entry.o == true }) end
      end
    end
  end
  self.zoneQuestIndexReady = true
end

CA:LoadEmbeddedQuestCatalog()

function CA:GetTrackingMode()
  return (ChroniquesAzerothDB and ChroniquesAzerothDB.trackingMode) or "account"
end

function CA:IsQuestCompletedForCharacter(questID)
  return ChroniquesAzerothCharacterDB and ChroniquesAzerothCharacterDB.completed and ChroniquesAzerothCharacterDB.completed[questID] or false
end

function CA:IsQuestCompletedByClient(questID)
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then return C_QuestLog.IsQuestFlaggedCompleted(questID) end
  if IsQuestFlaggedCompleted then return IsQuestFlaggedCompleted(questID) end
  return false
end

function CA:IsQuestCompletedForAccount(questID)
  if ChroniquesAzerothDB and ChroniquesAzerothDB.completed and ChroniquesAzerothDB.completed[questID] then return true end
  return false
end

function CA:GetCharacterKey()
  local name = UnitName("player") or "Inconnu"
  local realm = GetRealmName and GetRealmName() or "Royaume"
  return name .. "-" .. realm
end

function CA:RebuildAccountCompleted()
  local merged = {}
  -- Keeps the earlier observations, without attributing them to a character.
  for questID, savedAt in pairs(ChroniquesAzerothDB.legacyCompleted or {}) do merged[questID] = savedAt end
  for _, character in pairs(ChroniquesAzerothDB.characters or {}) do
    for questID, savedAt in pairs(character.completed or {}) do merged[questID] = savedAt end
  end
  ChroniquesAzerothDB.completed = merged
end

function CA:SyncCurrentCharacter()
  local key = self:GetCharacterKey()
  ChroniquesAzerothCharacterDB.completed = ChroniquesAzerothCharacterDB.completed or {}
  ChroniquesAzerothDB.characters = ChroniquesAzerothDB.characters or {}
  local snapshot = ChroniquesAzerothDB.characters[key] or { completed = {} }
  snapshot.name = UnitName("player") or key
  snapshot.realm = GetRealmName and GetRealmName() or ""
  snapshot.completed = snapshot.completed or {}

  snapshot.lastSync = time()
  ChroniquesAzerothDB.characters[key] = snapshot
  self:RebuildAccountCompleted()

  -- The catalogue now covers more than 2,300 quests. The historical checks
  -- are spread over several frames so that the login stays smooth, while
  -- still importing the quests completed before the install.
  if self.completionScanStarted then return end
  self.completionScanStarted = true
  local questIDs, seen = {}, {}
  for _, zone in ipairs(self.zones) do
    for _, quest in ipairs(self:GetAccessibleZoneQuests(zone)) do
      if not seen[quest.id] then seen[quest.id] = true; table.insert(questIDs, quest.id) end
    end
  end
  local cursor, scanner = 1, CreateFrame("Frame")
  scanner:SetScript("OnUpdate", function(frame)
    local last = math.min(cursor + 74, #questIDs)
    for index = cursor, last do
      local questID = questIDs[index]
      if self:IsQuestCompletedByClient(questID) then
        local savedAt = time()
        ChroniquesAzerothCharacterDB.completed[questID] = savedAt
        snapshot.completed[questID] = savedAt
      end
    end
    cursor = last + 1
    if cursor <= #questIDs then return end
    snapshot.lastSync = time()
    ChroniquesAzerothDB.characters[key] = snapshot
    self:RebuildAccountCompleted()
    frame:SetScript("OnUpdate", nil)
    if self.frame and self.frame:IsShown() then self:Refresh() end
  end)
end

function CA:IsQuestCompleted(questID)
  if self:GetTrackingMode() == "character" then return self:IsQuestCompletedForCharacter(questID) end
  return self:IsQuestCompletedForAccount(questID)
end

function CA:SetTrackingMode(mode)
  ChroniquesAzerothDB.trackingMode = mode
  self:Refresh()
end

function CA:QuestName(questID)
  self.questNameCache = self.questNameCache or {}
  local cached = self.questNameCache[questID]
  if cached then return cached end
  if C_QuestLog and C_QuestLog.GetTitleForQuestID then
    local title = C_QuestLog.GetTitleForQuestID(questID)
    if title and title ~= "" then
      self.questNameCache[questID] = title
      return title
    end
  end
  local fallbackTitle = self.questTitleFallbacks and self.questTitleFallbacks[questID]
  if fallbackTitle then
    self.questNameCache[questID] = fallbackTitle
    return fallbackTitle
  end
  return self:L("questUnavailable")
end

-- Levels and reference XP come from QuestCatalog.lua, loaded with the
-- addon. No external index is read during Refresh.
function CA:GetQuestMeta(questID)
  return self.questMeta[questID]
end

function CA:GetQuestDifficultyColor(questID)
  local meta = self:GetQuestMeta(questID)
  local level = meta and meta[1]
  local playerLevel = UnitLevel("player") or 1
  if not level then return 1, .82, .35 end
  if level >= playerLevel + 5 then return 1, .1, .1 end
  if level >= playerLevel + 3 then return 1, .5, .1 end
  if level >= playerLevel - 2 then return 1, .82, .35 end
  return .62, .62, .62
end

function CA:GetXPDisplay(questID, classicXP)
  -- An active quest can provide its exact reward through the client.
  -- Quests not accepted yet use the embedded Classic estimate.
  if GetQuestLogRewardXP then
    -- Forever expects the quest ID, not the index in the quest log.
    local ok, xp = pcall(GetQuestLogRewardXP, questID)
    if ok and type(xp) == "number" and xp > 0 then return xp .. " XP" end
  end
  -- The beta font lacks some Unicode symbols. An ASCII prefix
  -- stays readable in every local font.
  return classicXP and ((self.locale == "frFR" and "env. " or "approx. ") .. classicXP .. " XP") or nil
end

function CA:IsQuestInLog(questID)
  if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
    local index = C_QuestLog.GetLogIndexForQuestID(questID)
    return type(index) == "number" and index > 0
  end
  return false
end

local function copperText(copper)
  if type(copper) ~= "number" or copper <= 0 then return nil end
  local gold, silver, coin = math.floor(copper / 10000), math.floor((copper % 10000) / 100), copper % 100
  local parts = {}
  local suffixes = CA.locale == "frFR" and { " po", " pa", " pc" } or { "g", "s", "c" }
  if gold > 0 then table.insert(parts, gold .. suffixes[1]) end
  if silver > 0 then table.insert(parts, silver .. suffixes[2]) end
  if coin > 0 then table.insert(parts, coin .. suffixes[3]) end
  return table.concat(parts, " ")
end

function CA:GetRewardSummary(questID)
  local meta = self:GetQuestMeta(questID)
  local displayedXP = self:GetXPDisplay(questID, meta and meta[3])
  local text = displayedXP and ("XP: " .. displayedXP) or "XP: —"
  if self:IsQuestInLog(questID) and GetQuestLogRewardMoney then
    local ok, money = pcall(GetQuestLogRewardMoney, questID)
    local formatted = ok and copperText(money)
    if formatted then text = text .. " - " .. (self.locale == "frFR" and "Argent : " or "Money: ") .. formatted end
  end
  return text
end

function CA:GetQuestRewardItems(questID)
  -- To avoid made-up data, rewards are shown only when the client
  -- exposes them for a quest that is actually in the log.
  if not self:IsQuestInLog(questID) then return self.questRewardIndex[questID] or {} end
  local items, choices = {}, {}
  local function addItem(target, itemName, texture, amount, itemID)
    if type(itemName) ~= "string" or itemName == "" then return end
    -- A single reward must be treated as 1 and never compared with nil.
    table.insert(target, { name = itemName, texture = texture, amount = tonumber(amount) or 1, itemID = itemID })
  end
  if C_QuestLog and C_QuestLog.GetQuestRewardInfo then
    for itemIndex = 1, 6 do
      -- Returns: name, texture, count, quality, usable, itemID.
      -- pcall adds its own boolean in first position.
      local ok, itemName, texture, amount, _, _, itemID = pcall(C_QuestLog.GetQuestRewardInfo, itemIndex, questID)
      if ok then addItem(items, itemName, texture, amount, itemID) end
    end
  end
  -- The Classic/Forever API exposed by the beta client is this
  -- global variant (reward index, quest ID).
  if #items == 0 and GetQuestLogRewardInfo then
    local count = GetNumQuestLogRewards and GetNumQuestLogRewards(questID) or 6
    for itemIndex = 1, count do
      local ok, itemName, texture, amount, _, _, itemID = pcall(GetQuestLogRewardInfo, itemIndex, questID)
      if ok then addItem(items, itemName, texture, amount, itemID) end
    end
  end
  -- Choice rewards have their own API: this is the case, for example, of
  -- "The Defias Brotherhood" and its militia weapons.
  if GetQuestLogChoiceInfo and GetNumQuestLogChoices then
    local okCount, count = pcall(GetNumQuestLogChoices, questID)
    if okCount and type(count) == "number" then
      for itemIndex = 1, count do
        local ok, itemName, texture, amount, _, _, itemID = pcall(GetQuestLogChoiceInfo, itemIndex, questID)
        if ok then addItem(choices, itemName, texture, amount, itemID) end
      end
    end
  end
  for _, item in ipairs(choices) do item.choice = true; table.insert(items, item) end
  if #items == 0 then return self.questRewardIndex[questID] or {} end
  return items
end

function CA:LinkNames(ids)
  if not ids or #ids == 0 then return "—" end
  local names = {}
  for _, id in ipairs(ids) do table.insert(names, self:QuestName(id)) end
  -- The Unicode arrow was shown as a rectangle by the quest details
  -- font. The comma is deliberately an ASCII separator.
  return table.concat(names, ", ")
end

function CA:GetQuestLinks(questID)
  local links = { previous = {}, next = {} }
  local function addUnique(target, values)
    if type(values) ~= "table" then return end
    for _, value in pairs(values) do
      if type(value) == "number" then
        local exists = false
        for _, known in ipairs(target) do if known == value then exists = true; break end end
        if not exists then table.insert(target, value) end
      end
    end
  end
  local catalogLinks = self.questLinks[questID]
  if catalogLinks then
    addUnique(links.previous, catalogLinks.previous)
    addUnique(links.next, catalogLinks.next)
  end
  return links
end

function CA:BuildQuestTree(zone)
  local inZone, parentFor, children = {}, {}, {}
  local zoneQuests = self:GetAccessibleZoneQuests(zone)
  for _, quest in ipairs(zoneQuests) do inZone[quest.id] = true; children[quest.id] = {} end
  for _, quest in ipairs(zoneQuests) do
    local links = self:GetQuestLinks(quest.id)
    -- A prerequisite located in this zone becomes the visual parent. When a
    -- quest offers several alternatives, the first known one is enough for
    -- the tree; the others stay visible in the details.
    for _, prerequisite in ipairs(links.previous) do
      if inZone[prerequisite] then parentFor[quest.id] = prerequisite; break end
    end
    if parentFor[quest.id] then table.insert(children[parentFor[quest.id]], quest.id) end
  end
  local ordered, visited = {}, {}
  local function addBranch(questID, depth)
    if visited[questID] then return end
    visited[questID] = true
    table.insert(ordered, { id = questID, depth = depth })
    table.sort(children[questID], function(a, b)
      local aMeta, bMeta = self:GetQuestMeta(a), self:GetQuestMeta(b)
      local aLevel, bLevel = aMeta and aMeta[1] or 0, bMeta and bMeta[1] or 0
      return aLevel == bLevel and a < b or aLevel < bLevel
    end)
    for _, childID in ipairs(children[questID]) do addBranch(childID, depth + 1) end
  end
  for _, quest in ipairs(zoneQuests) do if not parentFor[quest.id] then addBranch(quest.id, 0) end end
  -- Guards against cyclic external data or a missing parent.
  for _, quest in ipairs(zoneQuests) do addBranch(quest.id, 0) end
  return ordered
end

function CA:BuildQuestDisplay(zone)
  -- A "chain" is a whole connected component of the zone's prerequisite
  -- graph, no longer just the branch of one root. The former display could
  -- split a chain as soon as a quest had several prerequisites, which made
  -- its steps look duplicated and left vertical bars without a visible
  -- header.
  local zoneQuests = self:GetAccessibleZoneQuests(zone)
  local inZone, neighbors, parentFor, children = {}, {}, {}, {}
  for _, quest in ipairs(zoneQuests) do
    inZone[quest.id] = true
    neighbors[quest.id], children[quest.id] = {}, {}
  end

  local function questLevel(questID)
    local meta = self:GetQuestMeta(questID)
    return meta and meta[1] or 0
  end
  local function byLevelThenID(a, b)
    local aLevel, bLevel = questLevel(a), questLevel(b)
    return aLevel == bLevel and a < b or aLevel < bLevel
  end
  local function linkTogether(leftID, rightID)
    if not (inZone[leftID] and inZone[rightID]) then return end
    neighbors[leftID][rightID] = true
    neighbors[rightID][leftID] = true
  end

  -- Links are read in both directions: the catalogue already normalizes
  -- them, but this keeps the display robust when an entry only records
  -- a previous or a next quest.
  for _, quest in ipairs(zoneQuests) do
    local prerequisites = {}
    local links = self:GetQuestLinks(quest.id)
    for _, previousID in ipairs(links.previous or {}) do
      if inZone[previousID] then
        table.insert(prerequisites, previousID)
        linkTogether(quest.id, previousID)
      end
    end
    for _, nextID in ipairs(links.next or {}) do linkTogether(quest.id, nextID) end
    if #prerequisites > 0 then
      table.sort(prerequisites, byLevelThenID)
      parentFor[quest.id] = prerequisites[1]
      table.insert(children[parentFor[quest.id]], quest.id)
    end
  end
  for _, childIDs in pairs(children) do table.sort(childIDs, byLevelThenID) end

  -- Builds the undirected components. Each quest ID belongs to a single
  -- block, so the list never repeats a quest.
  local components, seen = {}, {}
  for _, quest in ipairs(zoneQuests) do
    if not seen[quest.id] then
      local component, queue, cursor = {}, { quest.id }, 1
      seen[quest.id] = true
      while cursor <= #queue do
        local questID = queue[cursor]
        cursor = cursor + 1
        table.insert(component, questID)
        for neighborID in pairs(neighbors[questID]) do
          if not seen[neighborID] then
            seen[neighborID] = true
            table.insert(queue, neighborID)
          end
        end
      end
      table.sort(component, byLevelThenID)
      table.insert(components, component)
    end
  end

  local function orderedComponent(component)
    local isMember, ordered, displayed = {}, {}, {}
    for _, questID in ipairs(component) do isMember[questID] = true end
    local roots = {}
    for _, questID in ipairs(component) do
      if not parentFor[questID] or not isMember[parentFor[questID]] then table.insert(roots, questID) end
    end
    table.sort(roots, byLevelThenID)
    local function addBranch(questID)
      if displayed[questID] then return end
      displayed[questID] = true
      table.insert(ordered, questID)
      for _, childID in ipairs(children[questID]) do
        if isMember[childID] then addBranch(childID) end
      end
    end
    for _, rootID in ipairs(roots) do addBranch(rootID) end
    -- Cyclic or incomplete graphs stay visible, but always within their
    -- single block rather than duplicated at the end of the list.
    for _, questID in ipairs(component) do addBranch(questID) end
    return ordered
  end

  local blocks = {}
  for _, component in ipairs(components) do
    local ordered = orderedComponent(component)
    table.insert(blocks, { ids = ordered, first = ordered[1] })
  end
  table.sort(blocks, function(a, b) return byLevelThenID(a.first, b.first) end)

  self.expandedGroups = self.expandedGroups or {}
  local entries = {}
  for _, block in ipairs(blocks) do
    local questIDs = block.ids
    if #questIDs == 1 then
      table.insert(entries, { id = questIDs[1], child = false })
    else
      local done, minLevel, maxLevel = 0, nil, nil
      for _, questID in ipairs(questIDs) do
        if self:IsQuestCompleted(questID) then done = done + 1 end
        local level = questLevel(questID)
        minLevel = not minLevel and level or math.min(minLevel, level)
        maxLevel = not maxLevel and level or math.max(maxLevel, level)
      end
      local headerID = questIDs[1]
      table.insert(entries, {
        id = headerID, group = true, expanded = self.expandedGroups[headerID] == true,
        groupDone = done, groupTotal = #questIDs,
        groupMinLevel = minLevel, groupMaxLevel = maxLevel,
      })
      if self.expandedGroups[headerID] then
        for index = 2, #questIDs do table.insert(entries, { id = questIDs[index], child = true }) end
      end
    end
  end
  return entries
end

function CA:InitializeQuestCatalog()
  -- The TOC loads QuestCatalog.lua before this file. There is no
  -- asynchronous index, third-party addon or network call to wait for.
  self.zoneQuestIndexReady = true
  self.questRewardIndex = self.questRewardIndex or {}
end

function CA:RecordQuest(questID, state, accountOnly)
  if not questID then return end
  ChroniquesAzerothDB = ChroniquesAzerothDB or { completed = {}, accepted = {}, trackingMode = "account" }
  ChroniquesAzerothCharacterDB = ChroniquesAzerothCharacterDB or { completed = {}, accepted = {} }
  ChroniquesAzerothDB.completed = ChroniquesAzerothDB.completed or {}
  ChroniquesAzerothDB.accepted = ChroniquesAzerothDB.accepted or {}
  ChroniquesAzerothCharacterDB.completed = ChroniquesAzerothCharacterDB.completed or {}
  ChroniquesAzerothCharacterDB.accepted = ChroniquesAzerothCharacterDB.accepted or {}
  if state == "completed" then
    ChroniquesAzerothDB.completed[questID] = time()
    if not accountOnly then
      ChroniquesAzerothCharacterDB.completed[questID] = time()
      local key = self:GetCharacterKey()
      ChroniquesAzerothDB.characters = ChroniquesAzerothDB.characters or {}
      ChroniquesAzerothDB.characters[key] = ChroniquesAzerothDB.characters[key] or { completed = {} }
      ChroniquesAzerothDB.characters[key].completed = ChroniquesAzerothDB.characters[key].completed or {}
      ChroniquesAzerothDB.characters[key].completed[questID] = time()
      self:RebuildAccountCompleted()
    end
  elseif state == "accepted" then
    ChroniquesAzerothDB.accepted[questID] = time()
    if not accountOnly then ChroniquesAzerothCharacterDB.accepted[questID] = time() end
  end
end

function CA:QuestLists(zone)
  local completedList, remainingList, optionalList = {}, {}, {}
  for _, quest in ipairs(self:GetAccessibleZoneQuests(zone)) do
    local entry = { id = quest.id, name = quest.title or self:QuestName(quest.id) }
    if self:IsQuestCompleted(quest.id) then
      table.insert(completedList, entry)
      -- Also picks up the quests completed before the addon was installed.
      if self:GetTrackingMode() == "account" then self:RecordQuest(quest.id, "completed", true) end
    elseif quest.optional then
      entry.reason = quest.reason
      table.insert(optionalList, entry)
    else
      table.insert(remainingList, entry)
    end
  end
  table.sort(completedList, function(a, b) return a.name < b.name end)
  table.sort(remainingList, function(a, b) return a.name < b.name end)
  return completedList, remainingList, optionalList
end

function CA:ZoneProgress(zone)
  local done, required, optional = 0, 0, 0
  for _, quest in ipairs(self:GetAccessibleZoneQuests(zone)) do
    if quest.optional then
      optional = optional + 1
    else
      required = required + 1
      if self:IsQuestCompleted(quest.id) then done = done + 1 end
    end
  end
  return done, required, required > 0 and math.floor(done / required * 100 + 0.5) or 0, optional
end

function CA:GetSelectedZone()
  local key = self.selectedZoneKey or self.zones[1].key
  for _, zone in ipairs(self.zones) do
    if zone.key == key then return zone end
  end
  self.selectedZoneKey = self.zones[1].key
  return self.zones[1]
end

function CA:GetPlayerFaction()
  local faction = UnitFactionGroup and UnitFactionGroup("player") or nil
  return faction == "Horde" and "Horde" or "Alliance"
end

function CA:IsZoneAccessible(zone)
  return zone.faction ~= (self:GetPlayerFaction() == "Alliance" and "Horde" or "Alliance")
end

function CA:IsQuestAccessible(questID, quest)
  local side = (quest and quest.side) or (self.questSides and self.questSides[questID])
  return side == nil or side == "" or side == (self:GetPlayerFaction() == "Alliance" and "A" or "H")
end

function CA:GetAccessibleZoneQuests(zone)
  local quests = {}
  for _, quest in ipairs(zone.quests or {}) do
    if self:IsQuestAccessible(quest.id, quest) then table.insert(quests, quest) end
  end
  return quests
end

local function normalizedSearch(text)
  text = string.lower(tostring(text or ""))
  -- Replacements are written character by character: Lua character classes
  -- work on bytes and do not suit French UTF-8.
  text = text:gsub("à", "a"):gsub("â", "a"):gsub("ä", "a"):gsub("À", "a"):gsub("Â", "a"):gsub("Ä", "a")
  text = text:gsub("é", "e"):gsub("è", "e"):gsub("ê", "e"):gsub("ë", "e"):gsub("É", "e"):gsub("È", "e"):gsub("Ê", "e"):gsub("Ë", "e")
  text = text:gsub("î", "i"):gsub("ï", "i"):gsub("Î", "i"):gsub("Ï", "i"):gsub("ô", "o"):gsub("ö", "o"):gsub("Ô", "o"):gsub("Ö", "o")
  text = text:gsub("ù", "u"):gsub("û", "u"):gsub("ü", "u"):gsub("Ù", "u"):gsub("Û", "u"):gsub("Ü", "u"):gsub("ç", "c"):gsub("Ç", "c")
  return text:gsub("[’'%-]", " ")
end

function CA:IsZoneVisible(zone)
  if not self:IsZoneAccessible(zone) then return false end
  if zone.continentKey ~= self.activeContinent then return false end
  local query = normalizedSearch(self.zoneSearchQuery)
  return query == "" or normalizedSearch(self:GetZoneName(zone)):find(query, 1, true) ~= nil
end

function CA:GetFirstVisibleZone()
  for _, zone in ipairs(self.zones) do if self:IsZoneVisible(zone) then return zone end end
  return nil
end
