-- Saved variables.
--
-- ChroniquesAzerothDB (account) holds the settings, the log, the text caches and one record
-- per character, so that the account view can merge the progress of every character the
-- addon has seen. Each record is written by its own character only.

local _, ns = ...

local Database = {}
ns.Database = Database

local SCHEMA_VERSION = 1

local DEFAULT_SETTINGS = {
    tracking = ns.Const.Tracking.CHARACTER,
    possibleOnly = true, -- character view: only what the character can do
    scale = 1,
    minimap = { angle = 200, hidden = false },
    listFilters = {}, -- state filter of each item list: "all", "todo" or "done"
}

local function copyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                copyDefaults(target[key], value)
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            copyDefaults(target[key], value)
        end
    end
end

-- Learned recipes of a profession storage of the versions before 1.0:
-- [professionID] = { recipes = { ["spellID"] = { learned = true } } }.
local function legacyRecipes(storage, into)
    for _, profession in pairs(storage or {}) do
        for spellID, recipe in pairs(type(profession) == "table" and profession.recipes or {}) do
            if type(recipe) == "table" and recipe.learned == true and tonumber(spellID) then
                into[tonumber(spellID)] = true
            end
        end
    end
    return into
end

-- Saved variables of the versions before 1.0 (schemaVersion 2) keep, for each character, the
-- quests it completed and the recipes it learned; they become its record. The tracking mode
-- and the position of the minimap button carry over. Completions recorded before the
-- characters were told apart cannot be given to one of them: each character reads its own
-- again from the client at its next login.
local function migrateLegacy(db)
    if db.schemaVersion == nil then return end
    local characters, migrated = {}, 0
    for key, legacy in pairs(type(db.characters) == "table" and db.characters or {}) do
        local quests = {}
        for questID in pairs(type(legacy) == "table" and legacy.completed or {}) do
            if tonumber(questID) then quests[tonumber(questID)] = true end
        end
        characters[key] = { name = legacy.name, realm = legacy.realm, quests = quests,
            recipes = legacyRecipes(db.professionCharacters and db.professionCharacters[key], {}),
            professions = {}, bosses = {}, ignored = {}, repeatables = {} }
        migrated = migrated + 1
    end
    db.characters = characters
    db.settings = db.settings or {}
    if db.trackingMode == "character" or db.trackingMode == "account" then db.settings.tracking = db.trackingMode end
    if tonumber(db.minimapAngle) then db.settings.minimap = { angle = tonumber(db.minimapAngle), hidden = false } end
    for _, field in ipairs({ "schemaVersion", "completed", "accepted", "trackingMode", "minimapAngle",
        "legacyCompleted", "professionCharacters", "badges" }) do
        db[field] = nil
    end
    ns.Log:Info("Saved variables of a version before 1.0 migrated: %d characters", migrated)
end

function Database:Initialize()
    ChroniquesAzerothDB = ChroniquesAzerothDB or {}
    local db = ChroniquesAzerothDB
    db.log = db.log or {}
    ns.Log:Attach(db.log)
    migrateLegacy(db)

    if (db.schema or SCHEMA_VERSION) > SCHEMA_VERSION then
        ns.Log:Warn("Saved data comes from a newer version (schema %s)", tostring(db.schema))
    end
    db.schema = SCHEMA_VERSION
    db.settings = db.settings or {}
    copyDefaults(db.settings, DEFAULT_SETTINGS)
    db.characters = db.characters or {}
    db.ignoredQuests = db.ignoredQuests or {} -- [questID] = true, for the account view
    db.doneRepeatables = db.doneRepeatables or {} -- [questID] = true, marked done for the account
    db.cache = db.cache or {}

    -- Text caches depend on the client language and build: a new build may rename things.
    local build = ns.Compat.GetClientBuild()
    if db.cacheBuild ~= build then
        if db.cacheBuild then ns.Log:Info("Client build changed (%s -> %s): text cache cleared", db.cacheBuild, build) end
        db.cache = {}
        db.cacheBuild = build
    end
    local locale = GetLocale()
    db.cache[locale] = db.cache[locale] or {}

    self.db = db
    ns.Log:Debug("Saved variables ready: %d characters known", self:CountCharacters())
end

function Database:Settings()
    return self.db.settings
end

-- Text cache of the client language: Database:Cache("quests")[questID] = title.
function Database:Cache(kind)
    local cache = self.db.cache[GetLocale()]
    cache[kind] = cache[kind] or {}
    return cache[kind]
end

function Database:ClearCache()
    self.db.cache = { [GetLocale()] = {} }
end

function Database:CountCharacters()
    local count = 0
    for _ in pairs(self.db.characters) do count = count + 1 end
    return count
end

-- Creates or refreshes the record of the logged-in character.
function Database:TouchCharacter()
    local player = ns.Player
    local record = self.db.characters[player.key] or {}
    record.name = player.name
    record.realm = player.realm
    record.class = player.classFile
    record.race = player.raceID
    record.faction = player.faction
    record.level = player.level
    record.lastSeen = time()
    record.quests = record.quests or {}
    record.recipes = record.recipes or {}
    record.professions = record.professions or {}
    record.bosses = record.bosses or {}
    -- [questID] = true (ignored) or false (not ignored); absent, the account's choice applies.
    record.ignored = record.ignored or {}
    -- [questID] = true: repeatable quests turned in or marked done, which the server's list
    -- of completed quests does not keep.
    record.repeatables = record.repeatables or {}
    -- The recipes a version before 1.0 kept in the saved variables of the character join its
    -- record, once.
    if type(ChroniquesAzerothCharacterDB) == "table" then
        legacyRecipes(ChroniquesAzerothCharacterDB.professions, record.recipes)
        record.feedbackDraft = record.feedbackDraft or ChroniquesAzerothCharacterDB.feedbackDraft
        ChroniquesAzerothCharacterDB = nil
    end
    self.db.characters[player.key] = record
    self.character = record
end

function Database:Character()
    return self.character
end

-- Quests ignored for the account: [questID] = true.
function Database:IgnoredQuests()
    return self.db.ignoredQuests
end

-- Repeatable quests marked done for the account: [questID] = true.
function Database:DoneRepeatables()
    return self.db.doneRepeatables
end

-- Iterates over the records of every known character.
function Database:Characters()
    return pairs(self.db.characters)
end
