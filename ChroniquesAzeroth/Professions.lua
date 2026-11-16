-- Profession tracking: the embedded recipe catalogues, the character and account records,
-- and the reading of the native profession window and spellbook.

local _, ns = ...
local CA = ns.CA

-- These variables are declared before the reading functions so that Lua
-- captures them as locals: the data is filled in further down, before
-- the client can fire PLAYER_LOGIN.
local PROFESSION_DEFINITIONS, PROFESSION_BY_ID, PROFESSION_NAME_TO_ID, STATIC_PROFESSION_CATALOGS, STATIC_RECIPE_TO_PROFESSION
-- Increment this version when the way a catalogue is read changes,
-- so that an old, incomplete or wrong state can never be taken over as
-- a "learned" state by the new method.
local PROFESSION_CATALOG_SYNC_VERSION = 11

function CA:GetProfessionStorage()
  ChroniquesAzerothCharacterDB = ChroniquesAzerothCharacterDB or {}
  ChroniquesAzerothCharacterDB.professions = ChroniquesAzerothCharacterDB.professions or {}
  local storage = ChroniquesAzerothCharacterDB.professions
  -- Professions are saved per character, then indexed in the account
  -- variables. This lets the Account button merge the recipes actually
  -- read on several characters without borrowing data from a
  -- third-party addon.
  ChroniquesAzerothDB = ChroniquesAzerothDB or { completed = {}, accepted = {}, trackingMode = "account" }
  ChroniquesAzerothDB.professionCharacters = ChroniquesAzerothDB.professionCharacters or {}
  ChroniquesAzerothDB.professionCharacters[self:GetCharacterKey()] = storage
  return storage
end

function CA:PublishProfessionStorage(storage)
  if type(storage) ~= "table" then return end
  ChroniquesAzerothDB = ChroniquesAzerothDB or { completed = {}, accepted = {}, trackingMode = "account" }
  ChroniquesAzerothDB.professionCharacters = ChroniquesAzerothDB.professionCharacters or {}
  ChroniquesAzerothDB.professionCharacters[self:GetCharacterKey()] = storage
end

function CA:GetAccountProfessionStorage()
  -- Makes sure the logged-in character also takes part in the merge,
  -- even before it first opens a profession in this version.
  self:GetProfessionStorage()
  local aggregate = {}
  for _, characterStorage in pairs(ChroniquesAzerothDB.professionCharacters or {}) do
    if type(characterStorage) == "table" then
      for rawProfessionID, record in pairs(characterStorage) do
        local professionID = tonumber(rawProfessionID)
        if professionID and PROFESSION_BY_ID[professionID] and type(record) == "table" then
          local definition = PROFESSION_BY_ID[professionID]
          local merged = aggregate[professionID] or {
            name = self:GetProfessionName(definition), icon = definition.icon, rank = 0, maxRank = 0,
            learned = false, recipes = {}, characterCount = 0,
          }
          if record.learned then merged.characterCount = merged.characterCount + 1 end
          merged.name = record.name or merged.name
          merged.icon = record.icon or merged.icon
          merged.learned = merged.learned or record.learned == true
          merged.rank = math.max(tonumber(merged.rank) or 0, tonumber(record.rank) or 0)
          merged.maxRank = math.max(tonumber(merged.maxRank) or 0, tonumber(record.maxRank) or 0)
          if tonumber(record.catalogSyncVersion) == PROFESSION_CATALOG_SYNC_VERSION then
            merged.catalogSyncVersion = PROFESSION_CATALOG_SYNC_VERSION
            for recipeKey, recipe in pairs(record.recipes or {}) do
              if type(recipe) == "table" then
                local key = tostring(recipe.id or recipeKey)
                local mergedRecipe = merged.recipes[key] or {}
                mergedRecipe.id = recipe.id or mergedRecipe.id
                mergedRecipe.name = recipe.name or mergedRecipe.name
                mergedRecipe.icon = recipe.icon or mergedRecipe.icon
                mergedRecipe.link = recipe.link or mergedRecipe.link
                mergedRecipe.reagents = recipe.reagents or mergedRecipe.reagents
                -- A recipe becomes known for the account as soon as one
                -- synchronized character knows it; never the other way round.
                mergedRecipe.learned = mergedRecipe.learned or recipe.learned == true
                merged.recipes[key] = mergedRecipe
              end
            end
          end
          aggregate[professionID] = merged
        end
      end
    end
  end
  return aggregate
end

local function professionIDFor(name, skillLine)
  if type(skillLine) == "number" and PROFESSION_BY_ID[skillLine] then return skillLine end
  return PROFESSION_NAME_TO_ID[name]
end

-- The catalogues below are provided locally by the file
-- ProfessionCatalog.lua, generated from the Forever pages of Wowhead. They
-- make no network request: names and icons come from the spells
-- already present in the player's client.
local function catalogSourceText(code)
  if type(code) ~= "string" or code == "" then
    return CA:L("sourceUnknown")
  end
  local labels = {}
  if code:find("6", 1, true) then table.insert(labels, CA:L("trainer")) end
  if code:find("4", 1, true) then table.insert(labels, CA:L("vendor")) end
  if code:find("2", 1, true) then table.insert(labels, CA:L("loot")) end
  if code:find("5", 1, true) then table.insert(labels, CA:L("questSpecial")) end
  if code:find("1", 1, true) then table.insert(labels, CA:L("specialSource")) end
  return #labels > 0 and table.concat(labels, " - ") or CA:L("sourceUnknown")
end

local function parseStaticProfessionCatalogs()
  local source = type(_G.ChroniquesAzerothProfessionCatalog) == "table" and _G.ChroniquesAzerothProfessionCatalog or {}
  local catalogs = {}
  for professionID, packed in pairs(source) do
    if type(professionID) == "number" and type(packed) == "string" then
      local catalog = {}
      for token in packed:gmatch("[^,]+") do
        local id, skill, sourceCode, packedReagents = token:match("^(%d+):(%d*):([12456]*):?(.*)$")
        id = tonumber(id)
        if id then
          local reagents = {}
          for reagent in tostring(packedReagents or ""):gmatch("[^|]+") do
            local itemID, count = reagent:match("^(%d+)x(%d+)$")
            itemID = tonumber(itemID)
            if itemID then table.insert(reagents, { itemID = itemID, count = tonumber(count) or 1 }) end
          end
          table.insert(catalog, { id = id, skill = tonumber(skill) or 0, sourceCode = sourceCode or "", reagents = reagents })
        end
      end
      catalogs[professionID] = catalog
    end
  end
  return catalogs
end

STATIC_PROFESSION_CATALOGS = parseStaticProfessionCatalogs()
STATIC_RECIPE_TO_PROFESSION = {}
for professionID, catalog in pairs(STATIC_PROFESSION_CATALOGS) do
  for _, recipe in ipairs(catalog) do
    -- Some spells belong to several historical catalogues. The first
    -- profession declared then keeps priority, which is enough to
    -- identify the window currently open without touching its data.
    STATIC_RECIPE_TO_PROFESSION[recipe.id] = STATIC_RECIPE_TO_PROFESSION[recipe.id] or professionID
  end
end

local function catalogSpellInfo(recipeID)
  local name, icon
  if type(C_Spell) == "table" and type(C_Spell.GetSpellInfo) == "function" then
    local ok, info = pcall(C_Spell.GetSpellInfo, recipeID)
    if ok and type(info) == "table" then
      name, icon = info.name, info.iconID
    end
  end
  if (not name or name == "") and type(GetSpellInfo) == "function" then
    local ok, spellName, _, spellIcon = pcall(GetSpellInfo, recipeID)
    if ok then name, icon = spellName, icon or spellIcon end
  end
  return name or CA:L("recipeFallback", recipeID), icon
end

-- GetTradeSkillInfo provides a localized name but, on Forever, not always
-- a link holding the spell ID. The Chronicles catalogue builds its own
-- index locally and lazily from
-- GetSpellInfo: this is data the client already installed, with no
-- network call and no recipe loading.
local STATIC_RECIPE_ID_BY_NAME = {}
local function staticRecipeIDByName(professionID, recipeName)
  if type(recipeName) ~= "string" or recipeName == "" then return nil end
  local names = STATIC_RECIPE_ID_BY_NAME[professionID]
  if not names then
    names = {}
    for _, recipe in ipairs(STATIC_PROFESSION_CATALOGS[professionID] or {}) do
      local name = catalogSpellInfo(recipe.id)
      if type(name) == "string" and name ~= "" and not name:match("^Recette #") and not name:match("^Recipe #") then
        -- Keeping the first ID is enough for the rare namesakes:
        -- it belongs to the same profession and the native window gives it the
        -- same known/unknown state.
        names[name] = names[name] or recipe.id
      end
    end
    STATIC_RECIPE_ID_BY_NAME[professionID] = names
  end
  return names[recipeName]
end

-- GetItemInfo is asynchronous on Classic, so it may not provide a
-- reagent's name yet. Its icon, on the other hand, is often already
-- available by ID. It is read without a server request or waiting for the cache.
local function itemIconFor(itemID)
  itemID = tonumber(itemID)
  if not itemID then return nil end
  if type(C_Item) == "table" and type(C_Item.GetItemIconByID) == "function" then
    local ok, icon = pcall(C_Item.GetItemIconByID, itemID)
    if ok and icon then return icon end
  end
  if type(GetItemIcon) == "function" then
    local ok, icon = pcall(GetItemIcon, itemID)
    if ok and icon then return icon end
  end
  return nil
end

local function itemNameFor(itemID)
  itemID = tonumber(itemID)
  if not itemID then return nil end
  if type(C_Item) == "table" and type(C_Item.GetItemNameByID) == "function" then
    local ok, name = pcall(C_Item.GetItemNameByID, itemID)
    if ok and type(name) == "string" and name ~= "" then return name end
  end
  if type(GetItemInfo) == "function" then
    local ok, name = pcall(GetItemInfo, itemID)
    if ok and type(name) == "string" and name ~= "" then return name end
  end
  return nil
end

local function professionFromRecipeIDs(recipeIDs)
  local counts = {}
  for _, recipeID in ipairs(recipeIDs or {}) do
    local professionID = STATIC_RECIPE_TO_PROFESSION[tonumber(recipeID)]
    if professionID then counts[professionID] = (counts[professionID] or 0) + 1 end
  end
  local selectedID, bestCount
  for professionID, count in pairs(counts) do
    if not bestCount or count > bestCount then selectedID, bestCount = professionID, count end
  end
  return selectedID
end

local function cachedRecipeIDByName(record, professionID, recipeName)
  if type(recipeName) ~= "string" or recipeName == "" then return nil end
  -- The Classic client also resolves a spell by its localized name. Trying
  -- this API first avoids depending on a
  -- name preloaded in our compact catalogue. The ID stays limited to the
  -- current profession so that a class spell of the same name never counts.
  if type(C_Spell) == "table" and type(C_Spell.GetSpellInfo) == "function" then
    local infoOK, info = pcall(C_Spell.GetSpellInfo, recipeName)
    local recipeID = infoOK and type(info) == "table" and tonumber(info.spellID) or nil
    if recipeID and STATIC_RECIPE_TO_PROFESSION[recipeID] == professionID then return recipeID end
  end
  if type(GetSpellInfo) == "function" then
    local lookupOK, _, _, _, _, _, _, recipeID = pcall(GetSpellInfo, recipeName)
    recipeID = lookupOK and tonumber(recipeID) or nil
    if recipeID and STATIC_RECIPE_TO_PROFESSION[recipeID] == professionID then return recipeID end
  end
  for _, recipe in pairs(record and record.recipes or {}) do
    if recipe.name == recipeName and type(recipe.id) == "number" then return recipe.id end
  end
  return staticRecipeIDByName(professionID, recipeName)
end

-- Reads only the ranks the client already exposes. This function opens
-- no profession window and requests no extra data.
function CA:ReadPlayerProfessions()
  local storage, found = self:GetProfessionStorage(), {}
  local couldRead = false

  if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
    local ok, first, second, archaeology, fishing, cooking, firstAid = pcall(GetProfessions)
    if ok then
      for _, professionIndex in pairs({ first, second, archaeology, fishing, cooking, firstAid }) do
        if type(professionIndex) == "number" then
          local infoOK, name, icon, rank, maxRank, _, _, skillLine = pcall(GetProfessionInfo, professionIndex)
          local professionID = infoOK and professionIDFor(name, skillLine)
          if professionID then
            found[professionID] = true
            local definition, record = PROFESSION_BY_ID[professionID], storage[professionID] or {}
            record.name = name or self:GetProfessionName(definition)
            record.icon = icon or definition.icon
            record.rank = tonumber(rank) or 0
            record.maxRank = tonumber(maxRank) or record.maxRank or 0
            record.learned = true
            record.recipes = record.recipes or {}
            storage[professionID] = record
            couldRead = true
          end
        end
      end
    end
  end

  -- The Forever client may still expose the historical skill lines.
  -- The fallback does not change the visual state of the native frames (no ExpandSkillHeader).
  if not couldRead and type(GetNumSkillLines) == "function" and type(GetSkillLineInfo) == "function" then
    local countOK, lineCount = pcall(GetNumSkillLines)
    if countOK and type(lineCount) == "number" then
      for skillIndex = 1, lineCount do
        local infoOK, name, isHeader, _, rank, _, _, maxRank = pcall(GetSkillLineInfo, skillIndex)
        local professionID = infoOK and not isHeader and professionIDFor(name)
        if professionID then
          found[professionID] = true
          local definition, record = PROFESSION_BY_ID[professionID], storage[professionID] or {}
          record.name = name or self:GetProfessionName(definition)
          record.icon = record.icon or definition.icon
          record.rank = tonumber(rank) or 0
          record.maxRank = tonumber(maxRank) or record.maxRank or 0
          record.learned = true
          record.recipes = record.recipes or {}
          storage[professionID] = record
          couldRead = true
        end
      end
    end
  end

  if couldRead then
    for professionID, record in pairs(storage) do
      if not found[professionID] then record.learned = false end
    end
  end
  self:PublishProfessionStorage(storage)
  return storage
end

-- The catalogue forces no loading on the server side. It only records
-- what the Blizzard interface exposes when the player opens a profession.
function CA:RecordProfessionRecipe(record, recipeID, name, icon, link, learned, source)
  if type(name) ~= "string" or name == "" then return false end
  record.recipes = record.recipes or {}
  local key = tostring(recipeID or link or name)
  local recipe = record.recipes[key] or {}
  recipe.id = type(recipeID) == "number" and recipeID or recipe.id
  recipe.name = name
  recipe.icon = icon or recipe.icon
  recipe.link = type(link) == "string" and link or recipe.link
  -- A recipe is learned only once a Blizzard source has stated it.
  -- Older versions kept nil as "learned", which could turn a whole
  -- historical catalogue into false positives.
  recipe.learned = learned == true
  if type(source) == "string" and source ~= "" then recipe.source = source end
  record.recipes[key] = recipe
  return true
end

-- Shortcut for NEW_RECIPE_LEARNED / LEARNED_SPELL_IN_TAB. The
-- catalogue gives the profession of the spell; no Blizzard window is
-- opened and no data is requested from the server here. This signal
-- completes a record already made by ScanOpenProfession.
function CA:RecordProfessionSpellLearned(recipeID)
  recipeID = tonumber(recipeID)
  local professionID = recipeID and STATIC_RECIPE_TO_PROFESSION[recipeID]
  if not professionID then return false end

  local definition = PROFESSION_BY_ID[professionID]
  if not definition then return false end
  local storage = self:ReadPlayerProfessions()
  local record = storage[professionID] or {}
  record.name = record.name or self:GetProfessionName(definition)
  record.icon = record.icon or definition.icon
  record.learned, record.recipes = true, record.recipes or {}

  local staticRecipe
  for _, recipe in ipairs(STATIC_PROFESSION_CATALOGS[professionID] or {}) do
    if recipe.id == recipeID then staticRecipe = recipe; break end
  end
  if not staticRecipe then return false end
  local name, icon = catalogSpellInfo(recipeID)
  self:RecordProfessionRecipe(record, recipeID, name, icon, nil, true)
  storage[professionID] = record
  self:PublishProfessionStorage(storage)
  return true
end

function CA:GetProfessionRecipes(record, professionID)
  local recipes, seen = {}, {}
  local savedRecipes = record and record.recipes or {}
  -- Earlier versions wrongly assumed that a missing property meant
  -- "learned". Their state is kept for names and icons, but never
  -- counts as learned before a reliable resynchronization.
  local hasReliableLearnedState = record and tonumber(record.catalogSyncVersion) == PROFESSION_CATALOG_SYNC_VERSION

  -- The static catalogue guarantees a complete list, including for a
  -- profession the character does not have yet. An entry recorded from
  -- the native window always keeps priority for the name, the icon, the
  -- "learned" state and a possibly more precise source.
  for _, staticRecipe in ipairs(STATIC_PROFESSION_CATALOGS[professionID] or {}) do
    local key = tostring(staticRecipe.id)
    local saved = savedRecipes[key]
    local recipe = {
      key = key,
      id = staticRecipe.id,
      name = (saved and saved.name) or staticRecipe.name,
      icon = (saved and saved.icon) or staticRecipe.icon,
      link = saved and saved.link,
      learned = hasReliableLearnedState and saved and saved.learned == true or false,
      requiredSkill = staticRecipe.skill,
      source = (saved and saved.sourceLocale == self.locale and saved.source) or catalogSourceText(staticRecipe.sourceCode),
      reagents = (saved and saved.reagents) or staticRecipe.reagents,
      staticEntry = staticRecipe,
    }
    seen[key] = true
    table.insert(recipes, recipe)
  end

  -- The native Forever lists may also hold a recent recipe that is not
  -- in the embedded catalogue yet: it stays visible
  -- instead of being hidden.
  for key, saved in pairs(savedRecipes) do
    if not seen[key] then
      table.insert(recipes, {
        key = key,
        id = saved.id,
        name = saved.name,
        icon = saved.icon,
        link = saved.link,
        learned = hasReliableLearnedState and saved.learned == true or false,
        source = saved.source,
        reagents = saved.reagents,
      })
    end
  end

  table.sort(recipes, function(a, b)
    local aSkill, bSkill = tonumber(a.requiredSkill) or 0, tonumber(b.requiredSkill) or 0
    if aSkill ~= bSkill then return aSkill < bSkill end
    return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
  end)
  return recipes
end

-- Resolving a spell can be costly for the large Forever catalogues.
-- It is therefore done only for the visible rows and for the
-- selected recipe, never for all 506 entries at login.
function CA:HydrateProfessionRecipe(recipe)
  if not recipe then return recipe end

  -- While the native profession window is still available, it is the
  -- best source for the icon of the crafted item. The profession spell
  -- may indeed have a generic purple icon, different from the item.
  if type(C_TradeSkillUI) == "table" and type(C_TradeSkillUI.GetRecipeInfo) == "function" and type(recipe.id) == "number" then
    local infoOK, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipe.id)
    if infoOK and type(info) == "table" then
      if type(info.name) == "string" and info.name ~= "" then recipe.name = info.name end
      recipe.icon = info.icon or info.iconID or recipe.icon
    end
  end

  -- Saved names may come from an earlier session in another
  -- language. The local spell is the authority and always follows the
  -- current client language; this reading only concerns the visible rows.
  local localizedName, localizedIcon = catalogSpellInfo(recipe.id)
  if localizedName and localizedName ~= "" then recipe.name = localizedName end
  recipe.icon = recipe.icon or localizedIcon
  if recipe.staticEntry then
    recipe.staticEntry.name = recipe.name
    recipe.staticEntry.icon = recipe.icon
  end
  return recipe
end

function CA:GetProfessionCatalogStats(record, professionID)
  local total, known, seen = 0, 0, {}
  local savedRecipes = record and record.recipes or {}
  local hasReliableLearnedState = record and tonumber(record.catalogSyncVersion) == PROFESSION_CATALOG_SYNC_VERSION
  for _, recipe in ipairs(STATIC_PROFESSION_CATALOGS[professionID] or {}) do
    local key, saved = tostring(recipe.id), savedRecipes[tostring(recipe.id)]
    seen[key], total = true, total + 1
    if hasReliableLearnedState and saved and saved.learned == true then known = known + 1 end
  end
  for key, saved in pairs(savedRecipes) do
    if not seen[key] then
      total = total + 1
      if hasReliableLearnedState and saved.learned == true then known = known + 1 end
    end
  end
  return total, known
end

function CA:ReadRecipeSourceText(recipeID)
  if type(C_TradeSkillUI) ~= "table" or type(C_TradeSkillUI.GetRecipeSourceText) ~= "function" then return nil end
  local ok, source = pcall(C_TradeSkillUI.GetRecipeSourceText, recipeID)
  return ok and type(source) == "string" and source ~= "" and source or nil
end

function CA:CacheProfessionRecipeDetails(recipe, record)
  if not recipe or type(recipe.id) ~= "number" then return end
  local source = self:ReadRecipeSourceText(recipe.id)
  if source then recipe.source = source end
  local stored = record and type(record.recipes) == "table" and record.recipes[tostring(recipe.id)] or nil
  if source and stored then
    stored.source = source
    stored.sourceLocale = self.locale
  end
  if type(C_TradeSkillUI) ~= "table" or type(C_TradeSkillUI.GetRecipeSchematic) ~= "function" then
    if stored then self:PublishProfessionStorage(self:GetProfessionStorage()) end
    return
  end

  local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipe.id, false)
  if not ok or type(schematic) ~= "table" then
    if stored then self:PublishProfessionStorage(self:GetProfessionStorage()) end
    return
  end

  -- The schematic exposes the icon of the result on Forever clients.
  -- Only the selected recipe is read: no mass walk through the
  -- schematics, so no freeze when a profession is opened.
  local outputItemID = tonumber(schematic.outputItemID)
  local outputIcon = schematic.icon or schematic.outputItemIcon or itemIconFor(outputItemID)
  if outputIcon then
    recipe.icon = outputIcon
    if stored then stored.icon = outputIcon end
    if recipe.staticEntry then recipe.staticEntry.icon = outputIcon end
  end

  if type(schematic.reagentSlotSchematics) ~= "table" then return end
  local reagents = {}
  for _, slot in ipairs(schematic.reagentSlotSchematics) do
    local reagent = type(slot) == "table" and type(slot.reagents) == "table" and slot.reagents[1] or nil
    local itemID = type(reagent) == "table" and tonumber(reagent.itemID) or nil
    if itemID then
      table.insert(reagents, {
        itemID = itemID,
        count = tonumber(slot.quantityRequired) or tonumber(reagent.quantityRequired) or tonumber(reagent.quantity) or 1,
      })
    end
  end
  if #reagents > 0 then recipe.reagents = reagents end
  -- Only the details of the selected recipe are recorded. This avoids
  -- scanning hundreds of schematics when a profession is opened.
  if stored and #reagents > 0 then stored.reagents = reagents end
  if stored then self:PublishProfessionStorage(self:GetProfessionStorage()) end
end

local function nativeFrameIsVisible(frame)
  if not frame or type(frame.IsVisible) ~= "function" then return false end
  local ok, visible = pcall(frame.IsVisible, frame)
  return ok and visible and true or false
end

-- Forever mixes the old Classic frames and the more recent APIs depending
-- on the build. Reading them in one place keeps a single missing flag from
-- blocking the whole record. The fields also feed the /ca diag diagnostic.
local function readNativeProfessionContext()
  local context = {
    lineAPI = type(GetTradeSkillLine) == "function",
    listAPI = type(GetNumTradeSkills) == "function" and type(GetTradeSkillInfo) == "function",
    tradeFrame = nativeFrameIsVisible(_G.TradeSkillFrame),
    craftFrame = nativeFrameIsVisible(_G.CraftFrame),
    entries = 0,
  }
  context.frameVisible = context.tradeFrame or context.craftFrame

  if type(IsTradeSkillLinked) == "function" then
    local ok, linked = pcall(IsTradeSkillLinked)
    context.linked = ok and linked and true or false
  end
  if type(C_TradeSkillUI) == "table" then
    if type(C_TradeSkillUI.IsTradeSkillLinked) == "function" then
      local ok, linked = pcall(C_TradeSkillUI.IsTradeSkillLinked)
      context.linked = context.linked or (ok and linked and true or false)
    end
    if type(C_TradeSkillUI.IsTradeSkillGuild) == "function" then
      local ok, guild = pcall(C_TradeSkillUI.IsTradeSkillGuild)
      context.guild = ok and guild and true or false
    end
  end

  if context.lineAPI then
    local ok, name, rank, maxRank = pcall(GetTradeSkillLine)
    if ok then
      context.name, context.rank, context.maxRank = name, rank, maxRank
    end
  end
  -- Some Forever frames fill in the title before GetTradeSkillLine.
  -- This is data from the Blizzard interface, not a guess about the profession.
  if (type(context.name) ~= "string" or context.name == "") and _G.TradeSkillFrameTitleText and type(_G.TradeSkillFrameTitleText.GetText) == "function" then
    local ok, title = pcall(_G.TradeSkillFrameTitleText.GetText, _G.TradeSkillFrameTitleText)
    if ok and type(title) == "string" and title ~= "" then context.name = title end
  end
  if context.listAPI then
    local ok, count = pcall(GetNumTradeSkills)
    if ok and type(count) == "number" then context.entries = count end
  end
  context.professionID = professionIDFor(context.name)
  return context
end

local function nativeProfessionWindowIsUsable()
  local context = readNativeProfessionContext()
  return not context.linked and not context.guild
    and (context.professionID ~= nil or context.entries > 0 or context.frameVisible)
end

-- Self-contained fallback: recipes are spells of the character. When Forever
-- does not expose its profession list to an addon, IsSpellKnown remains the
-- Blizzard API available to tell which recipes THIS character knows.
-- It is used only on the local catalogue of the profession concerned (506
-- entries at most), never to guess or fetch remote recipes.
local function isRecipeSpellKnown(recipeID)
  -- IsSpellKnown exists on Classic builds. IsPlayerSpell is the
  -- fallback some hybrid Forever builds provide.
  if type(IsSpellKnown) == "function" then
    local ok, known = pcall(IsSpellKnown, recipeID)
    if ok and known then return true, "IsSpellKnown" end
  end
  if type(IsPlayerSpell) == "function" then
    local ok, known = pcall(IsPlayerSpell, recipeID)
    if ok and known then return true, "IsPlayerSpell" end
  end
  return false, nil
end

local function spellbookAPIIsAvailable()
  return type(IsSpellKnown) == "function" or type(IsPlayerSpell) == "function"
end

-- A change of method must never keep "learned" states set by an
-- older, incomplete record. The useful data (name, icon, link, sources)
-- stays; only the learned state is reset, then rebuilt by the Blizzard
-- APIs of the current version.
local function resetStaleRecipeLearnedState(record)
  if tonumber(record.catalogSyncVersion) == PROFESSION_CATALOG_SYNC_VERSION then return end
  for _, recipe in pairs(record.recipes or {}) do
    recipe.learned = false
  end
  record.catalogSyncVersion = nil
end

local function recordKnownRecipesFromSpellbook(owner, record, professionID, scanInfo)
  if not spellbookAPIIsAvailable() then
    if scanInfo then scanInfo.spellbookAPI = false end
    return 0
  end
  if scanInfo then scanInfo.spellbookAPI = true end
  local known = 0
  for _, staticRecipe in ipairs(STATIC_PROFESSION_CATALOGS[professionID] or {}) do
    local isKnown = isRecipeSpellKnown(staticRecipe.id)
    if isKnown then
      local recipeName, icon = catalogSpellInfo(staticRecipe.id)
      if owner:RecordProfessionRecipe(record, staticRecipe.id, recipeName, icon, nil, true) then
        known = known + 1
      end
    end
  end
  if scanInfo then scanInfo.spellbook = known end
  return known
end

-- This reading does not need the profession window. It is therefore the main
-- path on Forever builds that do not expose GetTradeSkillLine to
-- third-party addons although the character does know the profession.
function CA:ScanKnownProfessionSpellbooks()
  local storage = self:ReadPlayerProfessions()
  local info = { professions = 0, known = 0, spellbookAPI = spellbookAPIIsAvailable() }
  for _, definition in ipairs(PROFESSION_DEFINITIONS) do
    local record = storage[definition.id]
    if record and record.learned and #(STATIC_PROFESSION_CATALOGS[definition.id] or {}) > 0 then
      info.professions = info.professions + 1
      record.recipes = record.recipes or {}
      resetStaleRecipeLearnedState(record)
      local perProfession = {}
      local known = recordKnownRecipesFromSpellbook(self, record, definition.id, perProfession)
      info.known = info.known + known
      if known > 0 then record.catalogSyncVersion = PROFESSION_CATALOG_SYNC_VERSION end
    end
  end
  self.lastProfessionSpellbookScanInfo = info
  self:PublishProfessionStorage(storage)
  if self.activeSection == "professions" then self:RefreshProfessions() end
  return info.known
end

function CA:QueueKnownProfessionSpellbookScan()
  if self.professionSpellbookScanQueued then return end
  self.professionSpellbookScanQueued = true
  local function scan()
    CA.professionSpellbookScanQueued = nil
    CA:ScanKnownProfessionSpellbooks()
  end
  if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
    C_Timer.After(.75, scan)
  else
    scan()
  end
end

function CA:ScanOpenProfession()
  local context = readNativeProfessionContext()
  local scanInfo = {
    entries = context.entries or 0, candidates = 0, resolved = 0, saved = 0, recipeIDs = 0,
    frame = context.frameVisible, lineAPI = context.lineAPI, listAPI = context.listAPI,
  }
  if context.linked or context.guild then
    scanInfo.reason = "métier lié ou de guilde"
    self.lastProfessionScanInfo = scanInfo
    return false
  end
  local recipeIDs = {}
  if type(C_TradeSkillUI) == "table" and type(C_TradeSkillUI.GetAllRecipeIDs) == "function" then
    local listOK, value = pcall(C_TradeSkillUI.GetAllRecipeIDs)
    if listOK and type(value) == "table" then recipeIDs = value end
  end
  scanInfo.recipeIDs = #recipeIDs

  local name, rank, maxRank = context.name, context.rank, context.maxRank
  -- Depending on the loading stage of the Classic window, GetTradeSkillLine may
  -- be empty while the recipes are already exposed. The catalogue IDs
  -- then identify the profession, without guessing or loading data.
  local professionID = context.professionID or professionFromRecipeIDs(recipeIDs)
  local storage = self:ReadPlayerProfessions()
  -- When the Forever window is visible but publishes neither a line nor a list,
  -- the last profession opened or selected is a safe context: the character
  -- must already have learned it. This allows the IsSpellKnown fallback without
  -- attributing recipes to an arbitrary profession.
  if not professionID and (context.frameVisible or self.professionNativeWindowObserved) then
    local preferred = self.lastScannedProfessionID or self.selectedProfessionID
    if preferred and storage[preferred] and storage[preferred].learned then professionID = preferred end
    if not professionID then
      for _, definition in ipairs(PROFESSION_DEFINITIONS) do
        if storage[definition.id] and storage[definition.id].learned then
          professionID = definition.id
          break
        end
      end
    end
  end
  scanInfo.name, scanInfo.professionID = name, professionID
  if not professionID then
    scanInfo.spellbook = self:ScanKnownProfessionSpellbooks()
    scanInfo.spellbookAPI = spellbookAPIIsAvailable()
    scanInfo.reason = "métier non identifié"
    self.lastProfessionScanInfo = scanInfo
    return false
  end

  local definition, record = PROFESSION_BY_ID[professionID], storage[professionID] or {}
  if not definition then
    scanInfo.reason = "métier absent du catalogue"
    self.lastProfessionScanInfo = scanInfo
    return false
  end
  record.name = (type(name) == "string" and name ~= "" and name) or record.name or self:GetProfessionName(definition)
  record.icon = record.icon or definition.icon
  record.rank = tonumber(rank) or record.rank or 0
  record.maxRank = tonumber(maxRank) or record.maxRank or 0
  record.learned, record.recipes = true, record.recipes or {}
  resetStaleRecipeLearnedState(record)
  storage[professionID] = record

  local scanned, knownScanned = 0, 0
  if type(C_TradeSkillUI) == "table" and type(C_TradeSkillUI.GetRecipeInfo) == "function" then
    for _, recipeID in ipairs(recipeIDs) do
      local infoOK, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
      if infoOK and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
        local link
        if type(C_TradeSkillUI.GetRecipeLink) == "function" then
          local linkOK, value = pcall(C_TradeSkillUI.GetRecipeLink, recipeID)
          if linkOK then link = value end
        end
        -- On this Forever client, the modern flags tell that the
        -- recipe exists in the catalogue, not that the character
        -- knows it. They are therefore never used for counting.
        local recipeLearned = false
        -- The source and the reagents are read only for the selected
        -- recipe: walking through these details for thousands of entries
        -- when the profession opens would cause a needless freeze.
        if self:RecordProfessionRecipe(record, recipeID, info.name, info.icon or info.iconID, link, recipeLearned) then
          scanned = scanned + 1
        end
      end
    end
  end

  -- The native window is the authority. Forever also uses "used" and "none" for
  -- known recipes; leaving them out would keep the counter at zero for no
  -- reason. Headers stay excluded as they have none of these types.
  if context.listAPI and context.entries > 0 then
    local knownRecipeTypes = { optimal = true, medium = true, easy = true, trivial = true, used = true, none = true }
    local recipeCount = context.entries
    if type(recipeCount) == "number" then
      for recipeIndex = 1, recipeCount do
        local infoOK, recipeName, recipeType = pcall(GetTradeSkillInfo, recipeIndex)
        if infoOK and knownRecipeTypes[recipeType] then
          scanInfo.candidates = scanInfo.candidates + 1
          local link, icon
          if type(GetTradeSkillRecipeLink) == "function" then
            local linkOK, value = pcall(GetTradeSkillRecipeLink, recipeIndex)
            if linkOK then link = value end
          end
          if type(GetTradeSkillIcon) == "function" then
            local iconOK, value = pcall(GetTradeSkillIcon, recipeIndex)
            if iconOK then icon = value end
          end
          local recipeID = type(link) == "string" and tonumber(link:match("|Hspell:(%d+)") or link:match("|Henchant:(%d+)") or link:match("|Htrade:(%d+)")) or nil
          recipeID = recipeID or cachedRecipeIDByName(record, professionID, recipeName)
          if recipeID then scanInfo.resolved = scanInfo.resolved + 1 end
          if self:RecordProfessionRecipe(record, recipeID, recipeName, icon, link, true) then
            scanned = scanned + 1
            knownScanned = knownScanned + 1
            scanInfo.saved = scanInfo.saved + 1
          end
        end
      end
    end
  end

  -- Completes the result of the native list, or takes over entirely
  -- when Forever does not publish it. A recipe can only be counted
  -- once: RecordProfessionRecipe uses the catalogue ID.
  knownScanned = knownScanned + recordKnownRecipesFromSpellbook(self, record, professionID, scanInfo)

  self.selectedProfessionID = professionID
  self.lastScannedProfessionID = professionID
  self.professionDetailRecipeKey = nil
  if knownScanned > 0 then record.catalogSyncVersion = PROFESSION_CATALOG_SYNC_VERSION end
  self:PublishProfessionStorage(storage)
  scanInfo.known, scanInfo.catalogVersion = knownScanned, record.catalogSyncVersion
  self.lastProfessionScanInfo = scanInfo
  if self.professionRecipeScroll then self.professionRecipeScroll:SetVerticalScroll(0) end
  if self.activeSection == "professions" then self:RefreshProfessions() end
  return knownScanned > 0
end

-- TRADE_SKILL_SHOW sometimes arrives before the client has filled the list.
-- This queue therefore lets the Blizzard window settle, then makes a
-- single fallback reading if needed.
function CA:QueueProfessionScan(isRetry)
  if self.professionScanQueued then return end
  self.professionScanQueued = true
  local function scan()
    CA.professionScanQueued = nil
    local didScan = CA:ScanOpenProfession()
    if not didScan and not isRetry and type(C_Timer) == "table" and type(C_Timer.After) == "function" then
      C_Timer.After(1.00, function() CA:QueueProfessionScan(true) end)
    end
  end
  if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
    C_Timer.After(.50, scan)
  else
    scan()
  end
end

-- When Chronicles is opened after the profession window, some Forever
-- clients no longer send TRADE_SKILL_SHOW to our frame. This
-- self-contained check guarantees a single reading of the window already shown.
function CA:EnsureVisibleProfessionScan()
  if not nativeProfessionWindowIsUsable() then
    self.professionNativeWindowObserved = nil
    return
  end
  if self.professionNativeWindowObserved then return end
  self.professionNativeWindowObserved = true
  self:QueueProfessionScan()
end

function CA:PrintProfessionScanDiagnostics()
  local info = self.lastProfessionScanInfo or {}
  local spellbookInfo = self.lastProfessionSpellbookScanInfo or {}
  print("|cffd6a33aChroniques métiers|r "
    .. "métier=" .. tostring(info.name or "?")
    .. " • entrées=" .. tostring(info.entries or 0)
    .. " • connues=" .. tostring(info.candidates or 0)
    .. " • IDs=" .. tostring(info.resolved or 0)
    .. " • mémorisées=" .. tostring(info.saved or 0)
    .. " • grimoire=" .. tostring(info.spellbook or spellbookInfo.known or 0)
    .. " • métiers=" .. tostring(spellbookInfo.professions or 0)
    .. " • sorts=" .. ((info.spellbookAPI or spellbookInfo.spellbookAPI) and "oui" or "non")
    .. " • cadre=" .. (info.frame and "oui" or "non")
    .. " • API=" .. ((info.lineAPI or info.listAPI) and "oui" or "non")
    .. (info.reason and (" • " .. info.reason) or ""))
end


-- Phase 1: visual directory of the Classic professions and their ranks.
-- Missing patterns and their sources will come with the phase 2 catalogue.
PROFESSION_DEFINITIONS = {
  { id = 171, names = { frFR = "Alchimie", enUS = "Alchemy" }, icon = "Interface\\Icons\\Trade_Alchemy" },
  { id = 164, names = { frFR = "Forge", enUS = "Blacksmithing" }, icon = "Interface\\Icons\\Trade_BlackSmithing" },
  { id = 333, names = { frFR = "Enchantement", enUS = "Enchanting" }, icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings" },
  { id = 202, names = { frFR = "Ingénierie", enUS = "Engineering" }, icon = "Interface\\Icons\\Trade_Engineering" },
  { id = 182, names = { frFR = "Herboristerie", enUS = "Herbalism" }, icon = "Interface\\Icons\\Trade_Herbalism" },
  { id = 165, names = { frFR = "Travail du cuir", enUS = "Leatherworking" }, icon = "Interface\\Icons\\Trade_LeatherWorking" },
  { id = 186, names = { frFR = "Minage", enUS = "Mining" }, icon = "Interface\\Icons\\Trade_Mining" },
  { id = 393, names = { frFR = "Dépeçage", enUS = "Skinning" }, icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
  { id = 197, names = { frFR = "Couture", enUS = "Tailoring" }, icon = "Interface\\Icons\\Trade_Tailoring" },
  { id = 185, names = { frFR = "Cuisine", enUS = "Cooking" }, icon = "Interface\\Icons\\INV_Misc_Food_15" },
  { id = 356, names = { frFR = "Pêche", enUS = "Fishing" }, icon = "Interface\\Icons\\Trade_Fishing" },
  { id = 129, names = { frFR = "Secourisme", enUS = "First Aid" }, icon = "Interface\\Icons\\Spell_Holy_SealOfSalvation" },
}
PROFESSION_BY_ID, PROFESSION_NAME_TO_ID = {}, {
  ["Alchemy"] = 171, ["Alchimie"] = 171,
  ["Blacksmithing"] = 164, ["Forge"] = 164,
  ["Enchanting"] = 333, ["Enchantement"] = 333,
  ["Engineering"] = 202, ["Ingénierie"] = 202,
  ["Herbalism"] = 182, ["Herboristerie"] = 182,
  ["Leatherworking"] = 165, ["Travail du cuir"] = 165,
  ["Mining"] = 186, ["Minage"] = 186,
  ["Skinning"] = 393, ["Dépeçage"] = 393,
  ["Tailoring"] = 197, ["Couture"] = 197,
  ["Cooking"] = 185, ["Cuisine"] = 185,
  ["Fishing"] = 356, ["Pêche"] = 356,
  ["First Aid"] = 129, ["Premiers soins"] = 129, ["Secourisme"] = 129,
}
local GATHERING_PROFESSION_IDS = {
  [182] = true, -- Herbalism
  [186] = true, -- Mining
  [393] = true, -- Skinning
  [356] = true, -- Fishing
}
for _, profession in ipairs(PROFESSION_DEFINITIONS) do PROFESSION_BY_ID[profession.id] = profession end

function CA:GetProfessionName(definition)
  return (definition and definition.names and definition.names[self.locale]) or (definition and definition.name) or ""
end

ns.PROFESSION_DEFINITIONS, ns.PROFESSION_BY_ID = PROFESSION_DEFINITIONS, PROFESSION_BY_ID
ns.STATIC_PROFESSION_CATALOGS, ns.GATHERING_PROFESSION_IDS = STATIC_PROFESSION_CATALOGS, GATHERING_PROFESSION_IDS
ns.itemIconFor, ns.itemNameFor = itemIconFor, itemNameFor
