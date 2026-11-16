-- Visual theme: colors, fonts and icons shared by every widget.
--
-- Borders, check marks and the progress ring are drawn with plain color textures rather
-- than texture files, so the look does not depend on art the Forever client may lack.

local _, ns = ...

local Theme = {}
ns.Theme = Theme

Theme.colors = {
    window = { 0.075, 0.042, 0.020, 0.98 },
    panel = { 0.12, 0.070, 0.028, 0.97 },
    panelDark = { 0.035, 0.030, 0.020, 0.94 },
    row = { 0.10, 0.08, 0.055, 0.9 },
    rowAlt = { 0.085, 0.067, 0.047, 0.9 },
    rowHover = { 0.16, 0.12, 0.07, 0.95 },
    selected = { 0.07, 0.28, 0.40, 0.95 },
    selectedBorder = { 0.25, 0.55, 0.75, 1 },
    border = { 0.66, 0.43, 0.15, 1 },
    borderDim = { 0.40, 0.29, 0.12, 0.85 },
    gold = { 1, 0.80, 0.25, 1 },
    goldDim = { 0.80, 0.64, 0.30, 1 },
    text = { 0.93, 0.88, 0.78, 1 },
    textDim = { 0.62, 0.57, 0.49, 1 },
    green = { 0.35, 0.86, 0.38, 1 },
    greenDark = { 0.10, 0.30, 0.12, 0.95 },
    greenBorder = { 0.30, 0.70, 0.32, 1 },
    yellow = { 1, 0.88, 0.30, 1 },
    orange = { 1, 0.55, 0.20, 1 },
    red = { 0.90, 0.25, 0.20, 1 },
    redDark = { 0.40, 0.08, 0.06, 1 },
    gray = { 0.55, 0.55, 0.55, 1 },
    blue = { 0.45, 0.70, 1, 1 },
    ringTrack = { 0.20, 0.17, 0.12, 0.9 },
}

-- Difficulty colors of recipes, as in the profession window.
Theme.difficulty = {
    orange = { 1, 0.50, 0.25, 1 },
    yellow = { 1, 1, 0, 1 },
    green = { 0.25, 0.75, 0.25, 1 },
    gray = { 0.50, 0.50, 0.50, 1 },
}

-- Fonts follow the client language (STANDARD_TEXT_FONT covers every alphabet the client
-- supports); the decorative serif is used only where it has the glyphs.
local WESTERN = { enUS = true, enGB = true, frFR = true, deDE = true, esES = true, esMX = true, itIT = true, ptBR = true }
Theme.fonts = {
    body = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
    fancy = WESTERN[GetLocale()] and "Fonts\\MORPHEUS.TTF" or (STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"),
}

Theme.icons = {
    addon = "Interface\\Icons\\INV_Misc_Map02",
    quests = "Interface\\Icons\\INV_Misc_Note_01",
    professions = "Interface\\Icons\\Trade_BlackSmithing",
    toys = "Interface\\Icons\\INV_Misc_Gift_01",
    dungeons = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
    raids = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    achievements = "Interface\\Icons\\INV_Jewelry_Talisman_01",
    collections = "Interface\\Icons\\Ability_Mount_RidingHorse",
    alliance = "Interface\\TargetingFrame\\UI-PVP-Alliance",
    character = "Interface\\Icons\\INV_Helmet_08",
    account = "Interface\\Icons\\INV_Misc_Book_09",
    possible = "Interface\\Icons\\INV_Misc_Spyglass_03",
    everything = "Interface\\Icons\\INV_Misc_Map_01",
    horde = "Interface\\TargetingFrame\\UI-PVP-Horde",
    search = "Interface\\Common\\UI-Searchbox-Icon",
    question = "Interface\\Icons\\INV_Misc_QuestionMark",
    mounts = "Interface\\Icons\\Ability_Mount_RidingHorse",
    pets = "Interface\\Icons\\INV_Box_PetCarrier_01",
    sets = "Interface\\Icons\\INV_Chest_Plate03",
    titles = "Interface\\Icons\\INV_Scroll_03",
    boss = "Interface\\Icons\\INV_Misc_Bone_ElfSkull_01",
    feedback = "Interface\\Icons\\INV_Misc_Note_06",
}

-- Artwork shipped with the addon for the zones it illustrates, by area id: full-width cards
-- and banners of 768 x 256 pixels. Other zones show the art the data gives them.
local ASSET_PATH = "Interface\\AddOns\\ChroniquesAzeroth\\Assets\\"
Theme.ZONE_ART_RATIO = 3
Theme.zoneArt = {}
for areaID, file in pairs({
    [12] = "elwynn", [1] = "dunmorogh", [40] = "westfall", [38] = "lochmodan", [141] = "teldrassil",
    [148] = "darkshore", [3] = "badlands", [4] = "blastedlands", [8] = "swampofsorrows", [10] = "duskwood",
    [11] = "wetlands", [28] = "westernplaguelands", [33] = "stranglethorn", [36] = "alterac", [41] = "deadwind",
    [44] = "redridge", [45] = "arathi", [46] = "burningsteppes", [47] = "hinterlands", [51] = "searinggorge",
    [85] = "tirisfal", [130] = "silverpine", [139] = "easternplaguelands", [267] = "hillsbrad",
    [1519] = "stormwind", [1537] = "ironforge", [1497] = "undercity", [14] = "durotar", [15] = "dustwallow",
    [16] = "azshara", [17] = "barrens", [215] = "mulgore", [331] = "ashenvale", [357] = "feralas",
    [361] = "felwood", [400] = "thousandneedles", [405] = "desolace", [406] = "stonetalon", [440] = "tanaris",
    [490] = "ungoro", [493] = "moonglade", [618] = "winterspring", [1377] = "silithus", [1637] = "orgrimmar",
    [1638] = "thunderbluff", [1657] = "darnassus",
}) do
    Theme.zoneArt[areaID] = ASSET_PATH .. "zone-" .. file .. ".tga"
end
-- Banners that show another artwork than the card: Blackrock Mountain stands for the Burning
-- Steppes, its neighbour, which shows the whole manifest without a card of its own.
Theme.bannerArt = { [46] = ASSET_PATH .. "zone-blackrock-mountain.tga" }
Theme.MEDALLION = ASSET_PATH .. "heritage-medallion.tga"

function Theme.Unpack(color)
    return color[1], color[2], color[3], color[4] or 1
end

-- Wraps text in a color escape sequence.
function Theme.Colorize(text, color)
    return string.format("|cff%02x%02x%02x%s|r", color[1] * 255, color[2] * 255, color[3] * 255, tostring(text))
end
