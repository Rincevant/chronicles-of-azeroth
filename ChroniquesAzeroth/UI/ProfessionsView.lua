-- The Professions tab: professions on the left, the selected profession and recipe in the
-- middle, the recipes of the profession on the right.

local _, ns = ...
local CA = ns.CA
local label, shortText = ns.label, ns.shortText
local PROFESSION_DEFINITIONS, PROFESSION_BY_ID = ns.PROFESSION_DEFINITIONS, ns.PROFESSION_BY_ID
local STATIC_PROFESSION_CATALOGS, GATHERING_PROFESSION_IDS = ns.STATIC_PROFESSION_CATALOGS, ns.GATHERING_PROFESSION_IDS
local itemIconFor, itemNameFor = ns.itemIconFor, ns.itemNameFor

local PROFESSION_RECIPE_ROW_HEIGHT = 24
-- Virtualized list: even a very large Forever profession stays smooth and
-- does not create hundreds of buttons when the addon loads.
local PROFESSION_RECIPE_VISIBLE_ROWS = 14
local RECIPE_LIST_HEIGHT = 331
local REAGENT_ROWS = 4
local QUESTION_MARK = "Interface/Icons/INV_Misc_QuestionMark"

local function infoBox(parent)
  local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  box:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 13, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  box:SetBackdropColor(.035, .030, .020, .94); box:SetBackdropBorderColor(.78, .58, .20, 1)
  return box
end

function CA:CreateProfessionUI(parent)
  local view = CreateFrame("Frame", nil, parent)
  view:SetSize(1050, ns.COLUMN_HEIGHT); view:SetPoint("TOPLEFT", 25, -118)
  self.professionView = view
  local left, center, right = ns.columns(view, 0, 0)

  -- Left: the professions.
  local leftTitle = label(left, self:L("professions"), 16); leftTitle:SetPoint("TOPLEFT", 15, -14)
  local leftSubtitle = label(left, self:L("professionCatalogs"), 8, {.72, .78, .82}); leftSubtitle:SetPoint("TOPLEFT", 16, -35)
  self.professionRows = {}
  for index, definition in ipairs(PROFESSION_DEFINITIONS) do
    local row = CreateFrame("Button", nil, left, "BackdropTemplate")
    row:SetSize(215, 23); row:SetPoint("TOPLEFT", 15, -52 - ((index - 1) * 27))
    row:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 7 })
    local icon = row:CreateTexture(nil, "ARTWORK"); icon:SetSize(17, 17); icon:SetPoint("LEFT", 5, 0); icon:SetTexture(definition.icon)
    local name = label(row, self:GetProfessionName(definition), 9, {.80, .84, .90}); name:SetPoint("LEFT", icon, "RIGHT", 5, 0); name:SetWidth(125); name:SetJustifyH("LEFT")
    local rank = label(row, "—", 8, {.72, .78, .82}); rank:SetPoint("RIGHT", -6, 0)
    local professionID = definition.id
    row:SetScript("OnClick", function()
      self.selectedProfessionID = professionID
      self.selectedProfessionRecipeKey = nil
      self.professionDetailRecipeKey = nil
      if self.professionRecipeScroll then self.professionRecipeScroll:SetVerticalScroll(0) end
      self:RefreshProfessions()
    end)
    self.professionRows[index] = { button = row, icon = icon, name = name, rank = rank, definition = definition }
  end

  -- Middle: the selected profession, then the selected recipe.
  self.professionTitle = label(center, self:L("professions"), 20); self.professionTitle:SetPoint("TOP", 0, -15)
  local hero = infoBox(center); hero:SetSize(368, 126); hero:SetPoint("TOP", 0, -45)
  local heroIcon = hero:CreateTexture(nil, "ARTWORK"); heroIcon:SetSize(52, 52); heroIcon:SetPoint("TOPLEFT", 13, -14)
  self.professionHeroIcon = heroIcon
  self.professionHeroName = label(hero, "", 12, {1, .86, .45}); self.professionHeroName:SetPoint("TOPLEFT", heroIcon, "TOPRIGHT", 10, 0)
  self.professionHeroName:SetWidth(170); self.professionHeroName:SetJustifyH("LEFT"); self.professionHeroName:SetWordWrap(false)
  self.professionStatus = label(hero, "", 9, {.72, .78, .82}); self.professionStatus:SetPoint("TOPLEFT", self.professionHeroName, "BOTTOMLEFT", 0, -5)
  self.professionStatus:SetWidth(170); self.professionStatus:SetJustifyH("LEFT"); self.professionStatus:SetWordWrap(true)
  self.professionKnownTitle = label(hero, "", 9, {.96, .93, .82}); self.professionKnownTitle:SetPoint("BOTTOMLEFT", 14, 17)
  self.professionKnownTitle:SetWidth(250); self.professionKnownTitle:SetJustifyH("LEFT"); self.professionKnownTitle:SetWordWrap(false)
  local orb = ns.progressRing(hero, self:L("known")); orb:SetPoint("TOPRIGHT", -11, -17)
  self.professionProgress, self.professionProgressRing = orb.text, orb.segments

  ns.sectionHeader(center, self:L("recipeDetail"), -180)
  local detail = ns.detailBox(center, -209, 180)
  local detailIcon = detail:CreateTexture(nil, "ARTWORK"); detailIcon:SetSize(32, 32); detailIcon:SetPoint("TOPLEFT", 11, -10)
  local detailName = label(detail, "", 12, {1, .82, .34}); detailName:SetPoint("TOPLEFT", detailIcon, "TOPRIGHT", 8, 0)
  detailName:SetWidth(306); detailName:SetJustifyH("LEFT"); detailName:SetWordWrap(false)
  local detailState = label(detail, "", 8, {.72, .78, .82}); detailState:SetPoint("TOPLEFT", detailName, "BOTTOMLEFT", 0, -4)
  detailState:SetWidth(306); detailState:SetJustifyH("LEFT")
  local componentsTitle = label(detail, self:L("components"), 10, {1, .82, .34}); componentsTitle:SetPoint("TOPLEFT", 11, -52)
  self.professionComponentRows = {}
  for index = 1, REAGENT_ROWS do
    local column, line = (index - 1) % 2, math.floor((index - 1) / 2)
    local row = CreateFrame("Frame", nil, detail)
    row:SetSize(170, 20); row:SetPoint("TOPLEFT", 11 + column * 176, -68 - line * 22)
    local icon = row:CreateTexture(nil, "ARTWORK"); icon:SetSize(18, 18); icon:SetPoint("LEFT", 1, 0)
    local name = label(row, "", 8, {.84, .84, .77}); name:SetPoint("LEFT", icon, "RIGHT", 5, 0); name:SetWidth(118); name:SetJustifyH("LEFT"); name:SetWordWrap(false)
    local count = label(row, "", 8, {1, .78, .28}); count:SetPoint("RIGHT", -2, 0)
    row:Hide()
    self.professionComponentRows[index] = { frame = row, icon = icon, name = name, count = count }
  end
  local componentHint = label(detail, "", 8, {.66, .70, .72}); componentHint:SetJustifyH("LEFT"); componentHint:SetWordWrap(true)
  self.professionComponentHint = componentHint
  local sourceTitle = label(detail, self:L("obtainRecipe"), 10, {1, .82, .34}); sourceTitle:SetPoint("TOPLEFT", 11, -118)
  local sourceText = label(detail, "", 8, {.82, .80, .70}); sourceText:SetPoint("TOPLEFT", 11, -134)
  sourceText:SetWidth(346); sourceText:SetJustifyH("LEFT"); sourceText:SetJustifyV("TOP"); sourceText:SetWordWrap(true)
  self.professionDetailIcon, self.professionDetailName = detailIcon, detailName
  self.professionDetailState, self.professionSourceText = detailState, sourceText

  -- Right: the recipes of the profession.
  local listTitle = label(right, self:L("recipeCatalog"), 15); listTitle:SetPoint("TOP", 0, -15)
  local scroll, child = ns.scrollList(right, 10, -45, 360, RECIPE_LIST_HEIGHT, 338, RECIPE_LIST_HEIGHT)
  self.professionRecipeScroll, self.professionRecipeChild = scroll, child
  self.professionRecipeRows = {}
  for index = 1, PROFESSION_RECIPE_VISIBLE_ROWS do
    local row = CreateFrame("Button", nil, child, "BackdropTemplate")
    row:SetSize(338, PROFESSION_RECIPE_ROW_HEIGHT); row:SetPoint("TOPLEFT", 0, -((index - 1) * PROFESSION_RECIPE_ROW_HEIGHT))
    row:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 6 })
    local icon = row:CreateTexture(nil, "ARTWORK"); icon:SetSize(17, 17); icon:SetPoint("LEFT", 4, 0)
    local name = label(row, "", 9, {.86, .86, .80}); name:SetPoint("LEFT", icon, "RIGHT", 6, 0); name:SetWidth(240); name:SetJustifyH("LEFT"); name:SetWordWrap(false)
    local known = label(row, "", 7, {.42, .82, .38}); known:SetPoint("RIGHT", -7, 0)
    row:SetScript("OnClick", function(button)
      if not button.recipe then return end
      self.selectedProfessionRecipeKey = button.recipe.key
      self.professionDetailRecipeKey = nil
      self:RefreshProfessions()
    end)
    row:SetScript("OnEnter", function(button)
      local recipe = button.recipe
      if not recipe then return end
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      if recipe.link then
        GameTooltip:SetHyperlink(recipe.link)
      elseif recipe.id and type(GameTooltip.SetSpellByID) == "function" then
        GameTooltip:SetSpellByID(recipe.id)
      else
        GameTooltip:AddLine(recipe.name, 1, .82, .34)
      end
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:Hide()
    self.professionRecipeRows[index] = { button = row, icon = icon, name = name, known = known }
  end
  scroll:SetScript("OnVerticalScroll", function(frame, offset)
    frame:SetVerticalScroll(offset)
    self:RenderProfessionRecipeRows()
  end)
  self.professionRecipeSummary = label(right, "", 10, {.66, .72, .8}); self.professionRecipeSummary:SetPoint("BOTTOM", 0, 12)
  view:Hide()
end

function CA:RenderProfessionRecipeRows()
  local recipes = self.professionRecipeData or {}
  local offset = self.professionRecipeScroll and self.professionRecipeScroll:GetVerticalScroll() or 0
  local firstIndex = math.max(1, math.floor(offset / PROFESSION_RECIPE_ROW_HEIGHT) + 1)
  for visibleIndex, row in ipairs(self.professionRecipeRows or {}) do
    local recipeIndex = firstIndex + visibleIndex - 1
    local recipe = recipes[recipeIndex]
    if recipe then
      self:HydrateProfessionRecipe(recipe)
      row.button.recipe = recipe
      row.button:ClearAllPoints()
      row.button:SetPoint("TOPLEFT", 0, -((recipeIndex - 1) * PROFESSION_RECIPE_ROW_HEIGHT))
      row.icon:SetTexture(recipe.icon or QUESTION_MARK)
      row.name:SetText(shortText(recipe.name, 34))
      local learned = recipe.learned == true
      local level = tonumber(recipe.requiredSkill) or 0
      -- The Classic font of Forever does not always have the check mark
      -- glyph: it rendered it as a rectangle next to the level.
      row.known:SetText(level > 0 and (self:L("level") .. " " .. level) or (learned and self:L("known") or self:L("obtain")))
      row.known:SetTextColor(learned and .42 or 1, learned and .82 or .68, learned and .38 or .22)
      local selected = recipe.key == self.selectedProfessionRecipeKey
      if selected then
        row.button:SetBackdropColor(.10, .28, .34, .94)
        row.button:SetBackdropBorderColor(.20, .62, .90, .9)
        row.name:SetTextColor(.92, .94, .88)
      elseif learned then
        -- Deliberately discreet dark green: mastered recipes stand out at
        -- a glance, without mistaking their background for the selection.
        row.button:SetBackdropColor(.025, .105, .040, .94)
        row.button:SetBackdropBorderColor(.12, .42, .16, .72)
        row.name:SetTextColor(.50, .91, .54)
      else
        row.button:SetBackdropColor(.02, .035, .045, .94)
        row.button:SetBackdropBorderColor(.16, .22, .22, .35)
        row.name:SetTextColor(.86, .86, .80)
      end
      row.button:Show()
    else
      row.button.recipe = nil
      row.button:Hide()
    end
  end
end

function CA:RefreshProfessionDetails(recipe)
  self:HydrateProfessionRecipe(recipe)
  local hasRecipe = recipe ~= nil
  self.professionDetailIcon:SetTexture(hasRecipe and (recipe.icon or QUESTION_MARK) or QUESTION_MARK)
  self.professionDetailName:SetText(hasRecipe and recipe.name or self:L("selectRecipe"))
  if not hasRecipe then
    self.professionDetailState:SetText(self:L("detailWillAppear"))
  elseif recipe.learned == true then
    local owner = self:GetTrackingMode() == "account" and self:L("accountOwner") or self:L("characterOwner")
    self.professionDetailState:SetText((tonumber(recipe.requiredSkill) or 0) > 0 and (self:L("learnedRecipe") .. " - " .. self:L("skill") .. " " .. recipe.requiredSkill) or (self:L("learnedRecipe") .. " " .. owner))
    self.professionDetailState:SetTextColor(.42, .82, .38)
  else
    self.professionDetailState:SetText((tonumber(recipe.requiredSkill) or 0) > 0 and (self:L("learnRecipe") .. " - " .. self:L("skill") .. " " .. recipe.requiredSkill) or self:L("learnRecipe"))
    self.professionDetailState:SetTextColor(1, .68, .22)
  end

  local reagents = hasRecipe and recipe.reagents or nil
  for index, row in ipairs(self.professionComponentRows or {}) do
    local reagent = reagents and reagents[index]
    if reagent then
      if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(reagent.itemID) end
      local itemName, itemIcon = itemNameFor(reagent.itemID), itemIconFor(reagent.itemID)
      row.icon:SetTexture(itemIcon or QUESTION_MARK)
      row.name:SetText(itemName or self:L("itemFallback", reagent.itemID))
      row.count:SetText("x" .. (tonumber(reagent.count) or 1))
      row.frame:Show()
    else
      row.frame:Hide()
    end
  end
  -- With reagents, the hint only counts those beyond the rows, beside the section title;
  -- without them, it explains why the section is empty, in place of the rows.
  local hint = self.professionComponentHint
  hint:ClearAllPoints()
  if reagents and #reagents > 0 then
    local extra = #reagents - #self.professionComponentRows
    hint:SetPoint("TOPRIGHT", -11, -53); hint:SetWidth(150); hint:SetJustifyH("RIGHT")
    hint:SetText(extra > 0 and ("+ " .. extra .. " " .. self:L("components")) or "")
  else
    hint:SetPoint("TOPLEFT", 11, -70); hint:SetWidth(346); hint:SetJustifyH("LEFT")
    hint:SetText(hasRecipe and self:L("openProfessionComponents") or self:L("componentsWillAppear"))
  end

  if not hasRecipe then
    self.professionSourceText:SetText(self:L("sourceWillAppear"))
  elseif type(recipe.source) == "string" and recipe.source ~= "" then
    self.professionSourceText:SetText(recipe.source)
  elseif recipe.learned == true then
    self.professionSourceText:SetText(self:GetTrackingMode() == "account" and self:L("learnedAccount") or self:L("learnedCharacter"))
  else
    self.professionSourceText:SetText(self:L("sourceClientUnavailable"))
  end
end

function CA:RefreshProfessions()
  if not self.professionView then return end
  self:EnsureVisibleProfessionScan()
  local characterStorage = self:ReadPlayerProfessions()
  local accountMode = self:GetTrackingMode() == "account"
  local storage = accountMode and self:GetAccountProfessionStorage() or characterStorage
  if not self.selectedProfessionID then
    for _, definition in ipairs(PROFESSION_DEFINITIONS) do
      if storage[definition.id] and storage[definition.id].learned then
        self.selectedProfessionID = definition.id
        break
      end
    end
    for _, definition in ipairs(PROFESSION_DEFINITIONS) do
      if not self.selectedProfessionID and #(STATIC_PROFESSION_CATALOGS[definition.id] or {}) > 0 then
        self.selectedProfessionID = definition.id
        break
      end
    end
    self.selectedProfessionID = self.selectedProfessionID or PROFESSION_DEFINITIONS[1].id
  end

  for _, row in ipairs(self.professionRows or {}) do
    local definition, record = row.definition, storage[row.definition.id]
    local learned = record and record.learned
    local selected = definition.id == self.selectedProfessionID
    row.icon:SetTexture((record and record.icon) or definition.icon)
    row.name:SetText(self:GetProfessionName(definition))
    local catalogTotal, catalogKnown = self:GetProfessionCatalogStats(record, definition.id)
    if GATHERING_PROFESSION_IDS[definition.id] then
      -- These professions have no recipe catalogue: showing their rank
      -- here would make it look like a false count of known patterns.
      row.rank:SetText("")
      row.name:SetTextColor(selected and 1 or (learned and .84 or .52), selected and .84 or (learned and .86 or .56), selected and .32 or (learned and .70 or .60))
    elseif learned then
      local rank, maximum = tonumber(record.rank) or 0, tonumber(record.maxRank) or 0
      row.rank:SetText(catalogTotal > 0 and (catalogKnown .. " / " .. catalogTotal) or (maximum > 0 and (rank .. " / " .. maximum) or tostring(rank)))
      row.name:SetTextColor(selected and 1 or .84, selected and .84 or .86, selected and .32 or .70)
      row.rank:SetTextColor(.42, .82, .38)
    elseif catalogTotal > 0 then
      row.rank:SetText("0 / " .. catalogTotal)
      row.name:SetTextColor(selected and .88 or .52, selected and .76 or .56, selected and .38 or .60)
      row.rank:SetTextColor(.66, .62, .46)
    else
      row.rank:SetText("—")
      row.name:SetTextColor(selected and .88 or .52, selected and .76 or .56, selected and .38 or .60)
      row.rank:SetTextColor(.52, .56, .60)
    end
    row.button:SetBackdropColor(selected and .16 or .025, selected and .09 or .035, selected and .015 or .05, .98)
    row.button:SetBackdropBorderColor(selected and .84 or .28, selected and .58 or .32, selected and .16 or .38, selected and 1 or .55)
  end

  local definition = PROFESSION_BY_ID[self.selectedProfessionID] or PROFESSION_DEFINITIONS[1]
  local record = storage[definition.id]
  local learned = record and record.learned
  local recipes = self:GetProfessionRecipes(record, definition.id)
  local professionName = self:GetProfessionName(definition)
  self.professionTitle:SetText(professionName)
  self.professionHeroName:SetText(string.upper(professionName))
  self.professionHeroIcon:SetTexture((record and record.icon) or definition.icon)
  if learned then
    local rank, maximum = tonumber(record.rank) or 0, tonumber(record.maxRank) or 0
    local rankText = maximum > 0 and (rank .. " / " .. maximum) or tostring(rank)
    if accountMode then
      local characterCount = tonumber(record.characterCount) or 1
      self.professionStatus:SetText(self:L("listedOnCharacters", characterCount, characterCount > 1 and "s" or "", rankText))
    else
      self.professionStatus:SetText(self:L("currentRank", rankText))
    end
    self.professionStatus:SetTextColor(.42, .82, .38)
  elseif #recipes > 0 then
    self.professionStatus:SetText(accountMode
      and self:L("catalogNotLearnedAccount")
      or self:L("catalogNotLearnedCharacter"))
    self.professionStatus:SetTextColor(.78, .76, .67)
  else
    self.professionStatus:SetText(self:L("professionNotLearned"))
    self.professionStatus:SetTextColor(.78, .76, .67)
  end
  local knownCount = 0
  for _, recipe in ipairs(recipes) do if recipe.learned == true then knownCount = knownCount + 1 end end
  self.professionKnownTitle:SetText(self:L("recipeCatalogSummary", #recipes, knownCount))
  local pct = #recipes > 0 and math.floor(knownCount / #recipes * 100 + 0.5) or 0
  self.professionProgress:SetText(pct .. "%")
  ns.paintProgressRing(self.professionProgressRing, pct)

  local selectedRecipe
  for _, recipe in ipairs(recipes) do
    if recipe.key == self.selectedProfessionRecipeKey then selectedRecipe = recipe; break end
  end
  if not selectedRecipe and recipes[1] then
    selectedRecipe = recipes[1]
    self.selectedProfessionRecipeKey = selectedRecipe.key
  end
  self:HydrateProfessionRecipe(selectedRecipe)
  if selectedRecipe and self.professionDetailRecipeKey ~= selectedRecipe.key then
    -- The details read from the client stay attached to the logged-in character,
    -- even when the panel shows the account's union.
    self:CacheProfessionRecipeDetails(selectedRecipe, characterStorage[definition.id])
    self.professionDetailRecipeKey = selectedRecipe.key
  end
  self.professionRecipeData = recipes
  self.professionRecipeChild:SetHeight(math.max(RECIPE_LIST_HEIGHT, #recipes * PROFESSION_RECIPE_ROW_HEIGHT))
  self:RenderProfessionRecipeRows()
  self.professionRecipeSummary:SetText(#recipes > 0 and self:L("recipesListed", #recipes) or self:L("noRecipeListed"))
  self:RefreshProfessionDetails(selectedRecipe)
end
