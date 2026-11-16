-- Quest progress.
--
-- The completed quests of the logged-in character are read from the client at login and
-- after every turn-in, and stored in its record, so that the account view can merge the
-- progress of every character. A "view" (tracking mode + faction) decides which quests
-- are visible and which completions count; statuses and totals are computed for a view
-- and cached until the progress changes.

local _, ns = ...

local Quests = ns:RegisterModule("Quests")

local Q, Flag, Status = ns.Const.Quest, ns.Const.QuestFlag, ns.Const.Status
local Tracking = ns.Const.Tracking
local NOT_COUNTED = Flag.REPEATABLE + Flag.DAILY + Flag.WEEKLY

local revision = 0 -- bumped on every progress change, invalidates the caches
local statsCache = {}
local mergedCompleted, mergedRevision
local characterCompleted, characterRevision

-------------------------------------------------------------------------------
-- Snapshot of the character's progress
-------------------------------------------------------------------------------

local function changed()
    revision = revision + 1
    statsCache = {}
    ns:SendMessageDelayed("CA_PROGRESS_CHANGED", 0.3)
end

-- Other progress, such as a profession learned, changes what the character can do.
ns:RegisterMessage("CA_PROGRESS_CHANGED", function() statsCache = {} end)

local MAX_SNAPSHOT_RETRIES = 3
local snapshotRetries = 0

function Quests:Snapshot()
    local completed, source = ns.Compat.GetCompletedQuests()
    if not source then
        ns.Log:Warn("The client exposes no list of completed quests; progress cannot be read")
        return
    end
    local record = ns.Database:Character()
    local count, known = 0, 0
    for questID in pairs(completed) do
        count = count + 1
        if ns.Data.Quests[questID] then known = known + 1 end
    end
    -- Right after login the client may not have received the list yet: an empty answer
    -- never replaces saved progress, it is asked again a little later.
    if count == 0 and next(record.quests) and snapshotRetries < MAX_SNAPSHOT_RETRIES then
        snapshotRetries = snapshotRetries + 1
        ns.Log:Info("Completed quest list empty (attempt %d); keeping the saved progress and retrying", snapshotRetries)
        C_Timer.After(5, function() ns:SafeCall("Quests.Snapshot", Quests.Snapshot, Quests) end)
        return
    end
    record.quests = completed
    ns.Log:Info("Completed quests read with %s: %d (%d in the catalogue)", source, count, known)
    changed()
end

function Quests:OnLogin()
    self:Snapshot()
end

ns:RegisterEvent("QUEST_TURNED_IN", function(_, questID)
    local record = ns.Database:Character()
    if record and questID then
        record.quests[questID] = true
        -- The server forgets a repeatable quest: it is kept apart, through the next snapshot.
        local row = ns.Data.Quests[questID]
        if row and Quests.IsRepeating(row) then record.repeatables[questID] = true end
        ns.Log:Debug("Quest %d turned in", questID)
        changed()
    end
end)

-- Accepting or abandoning a quest changes the displayed statuses, not the totals.
local function logChanged()
    ns:SendMessageDelayed("CA_PROGRESS_CHANGED", 0.3)
end
ns:RegisterEvent("QUEST_ACCEPTED", logChanged)
ns:RegisterEvent("QUEST_REMOVED", logChanged)

-------------------------------------------------------------------------------
-- Views
-------------------------------------------------------------------------------

-- Returns the view of the current settings: { tracking, faction, possible, key }.
function Quests:CurrentView(faction)
    local settings = ns.Database:Settings()
    local tracking = settings.tracking
    faction = faction or ns.Player.faction
    local possible = settings.possibleOnly ~= false
    return { tracking = tracking, faction = faction, possible = possible,
        key = tracking .. ":" .. tostring(faction) .. ":" .. (possible and "possible" or "all") }
end

-- Quests done in a view: those the server reports completed, and the repeatable quests
-- turned in or marked done, by the character, or for the account by any character and by
-- the account's own marks.
local function completedSet(view)
    if view.tracking ~= Tracking.ACCOUNT then
        if characterRevision ~= revision then
            local record = ns.Database:Character()
            characterCompleted = {}
            for questID in pairs(record.quests) do characterCompleted[questID] = true end
            for questID in pairs(record.repeatables or {}) do characterCompleted[questID] = true end
            characterRevision = revision
        end
        return characterCompleted
    end
    if mergedRevision ~= revision then
        mergedCompleted = {}
        for _, record in ns.Database:Characters() do
            for questID in pairs(record.quests or {}) do mergedCompleted[questID] = true end
            for questID in pairs(record.repeatables or {}) do mergedCompleted[questID] = true end
        end
        for questID in pairs(ns.Database:DoneRepeatables()) do mergedCompleted[questID] = true end
        mergedRevision = revision
    end
    return mergedCompleted
end

-- What the character can do (its race, class and professions) limits the character view of
-- its own faction, unless the "show everything" switch is on; otherwise only the faction
-- matters.
function Quests:UsesCharacterFilter(view)
    return view.possible and view.tracking == Tracking.CHARACTER and view.faction == ns.Player.faction
end

-- Profession a quest needs: its required skill, the profession that makes the item of a
-- crafting order, or the profession of its category.
function Quests.RequiredProfession(row)
    local skill = (row[Q.SKILL] and row[Q.SKILL][1]) or row[Q.CRAFT]
    if not skill and row[Q.AREA] < 0 then
        local sort = ns.Data.QuestSorts[-row[Q.AREA]]
        skill = sort and sort.skill
    end
    return skill and ns.Data.Professions[skill] and skill or nil
end

-------------------------------------------------------------------------------
-- Repeatable quests
-------------------------------------------------------------------------------

-- Whether a quest can be done again (repeatable, daily or weekly): it never counts in the
-- totals, and the server does not remember it as completed.
function Quests.IsRepeating(row)
    return not Quests.FlagsExclude(row[Q.FLAGS], NOT_COUNTED)
end

-- A repeatable quest is done once turned in, or once marked done by hand: by the character
-- in its view, for the account in the account view. Returns the state and where it comes
-- from: "character", "account", or "characters" when only a character of the account did it.
function Quests:RepeatableState(questID, view)
    if view.tracking ~= Tracking.ACCOUNT then
        return ns.Database:Character().repeatables[questID] == true, "character"
    end
    if ns.Database:DoneRepeatables()[questID] then return true, "account" end
    for _, record in ns.Database:Characters() do
        if record.repeatables and record.repeatables[questID] then return true, "characters" end
    end
    return false, "account"
end

function Quests:SetRepeatableDone(questID, view, done)
    local account = view.tracking == Tracking.ACCOUNT
    local set = account and ns.Database:DoneRepeatables() or ns.Database:Character().repeatables
    set[questID] = done or nil
    ns.Log:Info("Repeatable quest %d %s for the %s", questID, done and "marked done" or "no longer marked done",
        account and "account" or "character")
    changed()
end

-------------------------------------------------------------------------------
-- Ignored quests
-------------------------------------------------------------------------------

-- A quest the player cannot or does not want to do is ignored: it leaves the counts. The
-- account view uses the account's choice; a character uses its own choice when it made
-- one, the account's otherwise. Returns the state and where it comes from ("character" or
-- "account").
function Quests:IgnoreState(questID, view)
    local account = ns.Database:IgnoredQuests()[questID] == true
    if view.tracking == Tracking.ACCOUNT then return account, "account" end
    local own = ns.Database:Character().ignored[questID]
    if own ~= nil then return own, "character" end
    return account, "account"
end

function Quests:IsIgnored(questID, view)
    return (self:IgnoreState(questID, view))
end

-- Sets the choice of the view's level. A character's choice equal to the account's is
-- dropped, so that the character follows the account again.
function Quests:SetIgnored(questID, view, ignored)
    local accountSet = ns.Database:IgnoredQuests()
    if view.tracking == Tracking.ACCOUNT then
        accountSet[questID] = ignored or nil
    else
        local own = ns.Database:Character().ignored
        if ignored == (accountSet[questID] == true) then own[questID] = nil else own[questID] = ignored end
    end
    ns.Log:Info("Quest %d %s for the %s", questID, ignored and "ignored" or "no longer ignored",
        view.tracking == Tracking.ACCOUNT and "account" or "character")
    changed()
end

function Quests:IsVisible(questID, view)
    local row = ns.Data.Quests[questID]
    if not row then return false end
    local races = row[Q.RACES]
    if self:UsesCharacterFilter(view) then
        local profession = Quests.RequiredProfession(row)
        if self:IsIgnored(questID, view) and not completedSet(view)[questID] then return false end
        return ns.Player:CanRace(races) and ns.Player:CanClass(row[Q.CLASSES])
            and (not profession or ns.Professions:HasLearned(profession))
    end
    return races == 0 or ns.MasksIntersect(races, ns.Player:FactionRaces(view.faction))
end

function Quests:IsCounted(questID)
    local row = ns.Data.Quests[questID]
    return row ~= nil and Quests.FlagsExclude(row[Q.FLAGS], NOT_COUNTED)
end

-- True when none of the `excluded` flag bits is set in `flags`.
function Quests.FlagsExclude(flags, excluded)
    local bitValue = 1
    while bitValue <= excluded do
        if excluded % (bitValue * 2) >= bitValue and flags % (bitValue * 2) >= bitValue then return false end
        bitValue = bitValue * 2
    end
    return true
end

function Quests.HasFlag(flags, flag)
    return flags % (flag * 2) >= flag
end

local function allDone(list, completed)
    if not list then return true end
    for _, id in ipairs(list) do
        if not completed[id] then return false end
    end
    return true
end

local function anyDone(list, completed)
    if not list then return true end
    for _, id in ipairs(list) do
        if completed[id] then return true end
    end
    return false
end

-- Returns the status of a quest in a view and, for locked quests, the reason
-- ("level", "skill" or "prerequisite"); for closed alternatives, "exclusive" or "breadcrumb".
function Quests:Status(questID, view)
    local row = ns.Data.Quests[questID]
    local completed = completedSet(view)
    if completed[questID] then return Status.DONE end
    local flags = row[Q.FLAGS]
    if not Quests.FlagsExclude(flags, NOT_COUNTED) then return Status.REPEATABLE end
    if row[Q.EXCLUSIVE] and anyDone(row[Q.EXCLUSIVE], completed) then
        return Status.DONE, "exclusive"
    end
    local target = row[Q.BREADCRUMB_FOR]
    if target and completed[target] then return Status.DONE, "breadcrumb" end
    if self:IsIgnored(questID, view) then return Status.IGNORED end
    if ns.Compat.IsOnQuest(questID) then return Status.ACTIVE end
    if not allDone(row[Q.PRE_ALL], completed) or not anyDone(row[Q.PRE_ANY], completed) then
        return Status.LOCKED, "prerequisite"
    end
    if view.tracking == Tracking.CHARACTER and (ns.Player.level or 0) < row[Q.MIN_LEVEL] then
        return Status.LOCKED, "level"
    end
    local skill = row[Q.SKILL]
    if view.tracking == Tracking.CHARACTER and skill and ns.Professions:RankBelow(skill[1], skill[2]) then
        return Status.LOCKED, "skill"
    end
    return Status.AVAILABLE
end

-------------------------------------------------------------------------------
-- Totals
-------------------------------------------------------------------------------

-- Summarizes a chain for a view: visible quests, counted total, completed count, level range.
function Quests:ChainSummary(chain, view)
    local visible, done, total, low, high = {}, 0, 0, nil, nil
    for _, questID in ipairs(chain) do
        if self:IsVisible(questID, view) then
            visible[#visible + 1] = questID
            local row = ns.Data.Quests[questID]
            local level = row[Q.LEVEL]
            if level > 0 then
                low = math.min(low or level, level)
                high = math.max(high or level, level)
            end
            local status = self:Status(questID, view)
            if Quests.FlagsExclude(row[Q.FLAGS], NOT_COUNTED) and status ~= Status.IGNORED then
                total = total + 1
                if status == Status.DONE then done = done + 1 end
            end
        end
    end
    return { quests = visible, done = done, total = total, low = low, high = high }
end

-- Totals of a list of chains (a zone, a category or an instance), cached per view.
function Quests:Summary(cacheKey, chains, view)
    local key = view.key .. "|" .. cacheKey
    local cached = statsCache[key]
    if cached then return cached end
    local done, total = 0, 0
    for _, chain in ipairs(chains) do
        local summary = self:ChainSummary(chain, view)
        done, total = done + summary.done, total + summary.total
    end
    cached = { done = done, total = total }
    statsCache[key] = cached
    return cached
end

-- Zones grouped by continent, each { kind, id, chains, levels, continent, uiMap }.
function Quests:Groups()
    if self.groups then return self.groups end
    local groups = {}
    local Continent = ns.Const.Continent
    for areaID, zone in pairs(ns.Data.Zones) do
        local continent = zone.continent or Continent.OTHER
        groups[continent] = groups[continent] or {}
        table.insert(groups[continent], { kind = "zone", id = areaID, chains = zone.chains, levels = zone.levels,
            continent = continent, uiMap = zone.uiMap, art = zone.art, artFramed = zone.artFramed })
    end
    -- Areas that only name a set of quests are already among the categories.
    groups[Continent.CATEGORIES] = groups[Continent.CATEGORIES] or {}
    for sortID, sort in pairs(ns.Data.QuestSorts) do
        table.insert(groups[Continent.CATEGORIES], { kind = "sort", id = sortID, chains = sort.chains,
            levels = sort.levels, continent = Continent.CATEGORIES, uiMap = sort.uiMap, art = sort.art,
            artRatio = sort.artRatio, artFramed = sort.artFramed })
    end
    self.groups = groups
    return groups
end

-- Group that lists a quest, a zone before a category; nil for a quest outside the catalogue.
function Quests:GroupOf(questID)
    if not self.groupOf then
        local groupOf = {}
        for _, groups in pairs(self:Groups()) do
            for _, group in ipairs(groups) do
                for _, chain in ipairs(group.chains) do
                    for _, id in ipairs(chain) do
                        local current = groupOf[id]
                        if not current or (current.kind == "sort" and group.kind == "zone") then groupOf[id] = group end
                    end
                end
            end
        end
        self.groupOf = groupOf
    end
    return self.groupOf[questID]
end

function Quests:GroupName(group)
    if group.kind == "sort" then
        return ns.Names.QuestSort(group.id) or (group.id == 0 and ns.L.QUESTS_MISC) or ns.L.QUESTS_MISC
    end
    return ns.Names.Area(group.id) or string.format("#%d", group.id)
end

function Quests:Revision()
    return revision
end
