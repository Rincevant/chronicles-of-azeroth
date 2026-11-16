# Changelog

The versions of Chronicles of Azeroth, newest first. The section of a version is used as
the notes of its GitHub release.

## Unreleased

- **Collections** tab: mounts, pets, toys, appearance sets and titles, owned or missing, with
  the source of each item.
- **Legacy challenges** tab, read from the game, with their criteria and rewards; within reach,
  the categories of another class or of an unlearned profession are left out.
- **Dungeons** and **Raids** tabs: the bosses of each instance, defeated or not, and its quests,
  which a link from a recipe or a quest opens on their instance.
- Quests and professions come from data generated from the client tables of the Forever
  build, QuestieDB and Wowhead: 5,724 quests across the zones of both continents and the quest
  categories, and the complete recipe catalogue of every profession, with reagents and
  sources (trainer, vendor, drop, quest).
- Quest details tell the giver and the turn-in NPC, with a map waypoint, the experience and
  the reputation; a quest out of reach is shown locked, with the reason (level, prerequisite,
  profession rank).
- Quests can be ignored, which takes them out of the counts; repeatable quests are remembered
  once turned in and never count.
- Every list has the same search and the same filter (all, to do, done); quests and recipes
  link to each other, and a Back link returns to where a link was followed.
- A faction selector shows the quests of the other faction, and the character view keeps only
  what the character can do, unless the switch shows everything.
- The window can be moved, resized and scaled (`/ca scale`); the minimap button can be hidden
  (`/ca minimap`). The zones Chronicles of Azeroth illustrates keep their artwork; the others
  show their map or a loading screen.
- The saved variables of the previous versions are converted at the first login: each
  character keeps the quests and recipes it had recorded.
- A log is kept in the saved variables: the APIs the client provides, the quests turned in
  and any error of the addon, which no longer interrupts the game. `/ca help`, `/ca log`,
  `/ca debug` and `/ca clearlog` complete `/ca diag`.
- The **Professions** tab uses the layout of the **Quests** tab: the professions on the
  left; in the middle, the selected profession with a progress ring of its learned recipes,
  then the details of the selected recipe; on the right, the recipes of the profession.
- The code is split into modules: core, zones, quests, professions, one file per tab and
  shared widgets.

## 0.25.1-beta — 2026-10-06

- The **Feedback** tab offers a Discord link besides the GitHub issues, and the README
  explains where to send each kind of feedback.

## 0.25.0-beta — 2026-10-06 — English and feedback

- Chronicles picks French on a `frFR` client and English on every other client. The 2,307
  quest titles are shipped in both languages; recipe and reagent names are read in the
  client's language.
- Interface labels, zones, continents, professions, tabs and tracking states are localized
  in English, without Questie, ATT or any network access.
- A **Feedback** tab prepares a selectable diagnostic report. Nothing is sent
  automatically: the player copies it with `Ctrl+C`, then pastes it into the chosen channel
  (a GitHub issue for bugs, Discord for quick discussion).

## 0.24.5 — Font compatibility and navigation

- Linked quests are separated by a comma: the Unicode arrow, missing from the Classic
  details font, can no longer show up as a rectangle.
- Interface texts avoid the Unicode symbols the beta fonts do not guarantee; French
  characters (accents, apostrophes and ligatures) stay encoded in UTF-8.
- The **Achievements** and **Collections** tabs are removed. The **Toys**, **Dungeons** and
  **Raids** tabs now say **(coming soon)**.

## 0.24.4 — Faction fix

- The faction label is left-justified and anchored right after its emblem. The room kept
  for the label can no longer centre it far from the icon.

## 0.24.3 — Header medallion

- The experimental portrait is removed. The starred Chronicles medallion is back, with its
  metallic ring and a discreet overlap of the top left corner of the frame.

## 0.24.2 — Header portrait and spacing

- The inner golden medallion is replaced by an original round portrait with its bronze
  ring, slightly overlapping the top left corner of the frame.
- The faction name moves closer to its emblem. Both groups of the context bar move up, to
  leave a visible margin above the lower panels.

## 0.24.1 — Context bar alignment

- Both continent buttons now have the same width and their own continent icons; the
  Eastern Kingdoms label stays within its button.
- The **Faction** and **Tracking** groups are anchored on a shared centre line: emblem,
  label and Account / Character buttons share the same vertical alignment.

## 0.24.0 — Professions: account and complete catalogues

- The **Account / Character** selector also applies to professions: the Character mode
  reads only the recipes known by the logged-in character; the Account mode shows their
  union over the characters already synchronized with Chronicles.
- Recipe states stay saved per character, then indexed in the account variables. Logging
  in once with an existing character is enough for it to join the account's union.
- Eight complete catalogues ship with the addon: **Alchemy** (194), **Blacksmithing** (501),
  **Enchanting** (262), **Engineering** (276), **Leatherworking** (593), **Tailoring** (463),
  **Cooking** (133) and **First Aid** (31), that is **2,453 recipes**.
- Gathering professions deliberately show no false recipe counter. For every crafting
  recipe, the reagents and the known acquisition category are embedded in the addon; no
  third-party addon or network access is needed while playing.

## 0.23.3 — Minimap shortcut

- A Chronicles medallion is available around the minimap. A left click opens or closes the
  window; a right click switches tracking between **Account** and **Character**.
- The button is dragged around the edge of the minimap. Its position is saved in the
  Chronicles variables.

## 0.23.2 — Consistent chain blocks

- The list builds a single block per chain component: every prerequisite and follow-up
  linked within a zone stays together, even when a step has several links.
- A collapsed block shows only its header and progress; expanded, it shows each ID once,
  in the order of the chain. Identical titles of distinct steps can no longer appear in
  separate groups.
- The generator also checks these components: the shipped version holds 997 blocks,
  429 of which are multi-quest chains, with no missing member or duplicated assignment.

## 0.23.1 — Chain audit

- Repeatable quests, mount exchanges, contextual "Welcome!" entries and technical markers
  no longer count in the zone totals.
- Each ID is unique within its zone. Chain links are normalized in both directions, so
  that a follow-up declared without a matching prerequisite stays in the same visual group.
- Optional quests stay visible but do not inflate the required progress.

## 0.23.0 — Self-contained quest catalogue

- The 46 zones shown get a local catalogue generated from the Forever data: French titles,
  levels, reference XP, faction and chain links.
- `QuestCatalog.lua` is loaded with Chronicles. There is no longer any loading, global
  variable or declared dependency on Questie or QuestieDB.
- Faction-specific quests are filtered in neutral zones according to the logged-in
  character; the catalogue still keeps both factions locally.
- The reading of historical completions is spread over several frames at login, so that
  the full catalogue causes no noticeable slowdown.

## 0.22.3 — Self-contained profession synchronization

- Study of the All The Things addon: on the Classic/Forever client, it synchronizes recipes
  on `TRADE_SKILL_SHOW` by walking `GetNumTradeSkills` and `GetTradeSkillInfo`, then records
  the known spells. It does not rely on the full modern pattern list to decide that a recipe
  is learned.
- Chronicles adopts the same criterion and accepts the Forever-specific types `used` and
  `none`, besides `optimal`, `medium`, `easy` and `trivial`. These two types caused the
  false `0 / 506`.
- Chronicles also listens to `TRADE_SKILL_LIST_UPDATE`, `NEW_RECIPE_LEARNED` and
  `LEARNED_SPELL_IN_TAB`, like ATT: a newly learned recipe is recorded even while the
  Chronicles page is closed.
- The display outside the profession window remains possible thanks to the local save of
  the last reliable record. Opening Blacksmithing once is still needed to build the
  character's full list.
- Identification fix: the Forever profession window mostly returns localized names, which
  the compact catalogue does not embed. Chronicles therefore builds its local
  `spell name → spell ID` index through `GetSpellInfo`, like ATT's `SpellNameToSpellID`
  index. The recipes read can now be matched with the 506 catalogue entries and counted.
- ATT 5.3.15 remains only a reference studied for the Blizzard flow. Chronicles reads no
  data, saved variable or library of another addon: it works with no dependency outside
  the WoW client.
- The scan waits for the native window to settle, runs again if Chronicles is opened after
  the profession, and exposes `/ca diag` for checks: it prints the number of native
  entries, known recipes, resolved IDs and recorded recipes.
- Names returned by `GetTradeSkillInfo` are resolved first through the local API
  `GetSpellInfo(name)` / `C_Spell.GetSpellInfo(name)`, then through Chronicles' own index.
  No name, ID or recipe state is borrowed from ATT.
- Forever fix: the visibility of `TradeSkillFrame` is not reliable on this client, while
  `GetTradeSkillLine` and `GetNumTradeSkills` do expose the active profession. Chronicles
  now relies on these two native APIs to allow the record.

## 0.21.0 — Recipe synchronization

- Intermediate migration revision, replaced by the native window reading: the spellbook
  does not reflect every profession pattern on this client.

## 0.20.3 — Recipe source fix

- The counter no longer depends on the modern flags of the Forever catalogue, which mark
  available patterns as learned. Only the recipes the classic window identifies with a
  known recipe difficulty are counted.
- A migration invalidates the false state recorded by earlier versions before the next
  reliable synchronization.
- The check mark character, which the Classic font does not support, is removed from the
  levels: no more replacement rectangle next to `Lvl`.

## 0.20.2 — Recipe count fix

- The Forever synchronization now reads `isLearned`, the state the client actually
  provides, instead of taking a missing property for a learned recipe. Old wrong data is no
  longer counted and is replaced the next time the profession is opened.
- Learned recipes stand out with a dark green background and text in the middle list; the
  others keep the neutral dark background.
- Gathering professions no longer show their rank in the left column: it could be mistaken
  for a recipe counter.

## 0.20.1 — Profession fix

- Opening a profession now waits for the native list to be really available before
  synchronizing the learned recipes; the `learned / catalogue` counter thus reflects the
  blacksmithing the character already knows.
- Recipe icons come first from the native profession window, and reagent icons are
  resolved directly by ID without waiting for their name to load.
- The refresh button and its explanation are removed: synchronization is automatic when the
  profession is opened, and the room freed shows more recipes.

## 0.20.0 — Forever profession catalogues

- The complete lists of **Blacksmithing** (506 recipes), **Cooking** (133) and **First Aid**
  (32) ship with the addon, even when the character has not learned the profession yet.
- Each row shows the required skill and the learned / to obtain state. As soon as the
  profession is opened in the client, the actual state of its recipes is synchronized for
  the character.
- The details show the known acquisition category (trainer, vendor, drop or special
  source). Reagents and any detailed source are requested only for the selected recipe,
  through the APIs the Forever client already exposes.

## 0.19.0 — Profession catalogue

- The **Professions** tab shows the professions, the recipe catalogue and a details card
  with reagents and how to obtain the recipe.
- When a native profession is opened, the learned **and unlearned** recipes the client
  exposes are recorded; the list is virtualized to stay smooth on large catalogues.
- Reagents and the source text are read only for the selected recipe. When the Forever
  client provides no source, the interface says so instead of making one up.

## 0.18.4 — Context bar

- The bar under the tabs stays visible in **Quests**, **Professions** and future tabs.
- The static filters (expansion, continents and levels) are removed.
- The faction of the logged-in character is shown with its native Blizzard emblem,
  Alliance or Horde.

## 0.18.3 — Tirisfal and interface fix

- The minimap holder is removed from the medallion: the round emblem stands alone, inside
  the top left corner.
- Name shortening now respects UTF-8; French apostrophes can no longer produce a
  replacement square.
- Deathknell (zone 154) is attached to Tirisfal Glades. The starting Forsaken quest
  **Rude Awakening** (ID 363) is also embedded as an anchor, so that its completion shows
  immediately.

## 0.18.2 — Legacy medallion

- The Chronicles of Azeroth medallion sits in a native round holder, slightly overlapping
  the top left corner of the window, like the Legacy windows.

## 0.18.1 — Legacy adjustments

- The experimental top cartouche is removed: the title stays fully visible.
- Zone tiles show `completed / required` in the bottom right corner, without a percentage.
- The quest list legend is removed; the list uses the freed room and its scroll bar is
  anchored in the right gutter of the panel.

## 0.18.0 — Legacy look

- The window gets a slightly textured dark brown background and native Blizzard borders,
  inspired by the Legacy windows.
- A round progress medallion is added to the left of the header. It ships locally in
  `Assets/heritage-medallion.tga`.
- Zone cards become full-width artwork: only the zone name is shown, on a dark cartouche,
  without a percentage or progress bar.
- The Zones, Rewards and Quests panels no longer use the generated decorative pattern: they
  use only plain client textures and borders.

## 0.17.0 — Professions, phase 1

- The **Professions** tab shows the character's professions, their ranks and the recipes
  already recorded.
- The addon reads a recipe list only when the player opens the matching native window. No
  loading call or recipe walk happens at login.
- Known recipes are saved per character in the saved variables, and their tooltips use the
  data the client already provides.
- The full catalogue of patterns, missing recipes and their sources is planned for phase 2.

## 0.16.1 — Readability

- The quest list gets 20 more pixels of usable width and a taller scroll area. Titles,
  levels, XP and check marks are spaced in their own columns up to the scroll bar.
- Progress bars, zone percentages and progress rings use a darker forest green, inspired by
  the Blizzard journal.
- The **Kalimdor** tab uses a nature icon available on the Forever client.
- When no reference XP is known, the interface shows `—` instead of the ambiguous `XP ?`.

## 0.16.0 — Zone artwork

- The 47 links of the manifest were imported, checked and converted into 768 × 256 RGB TGA
  textures, a safe format for the Classic client.
- The 46 zones and capitals of the catalogue use their own artwork both in the left card
  and in the central banner. The extra **Blackrock Mountain** artwork is used for the
  banner of the Burning Steppes.
- Cards crop the panoramic artwork instead of stretching it, which keeps the landscape and
  avoids any distortion in the zone list.
- `tools/import_zone_art.py` rebuilds the textures from the manifest and checks that none of
  its 47 entries is missing.

## 0.15.0 — Faction and continent navigation

- Navigation detects the faction of the logged-in character. For an Alliance character,
  strictly Horde zones are no longer offered and Horde-only quests of neutral zones are
  excluded locally.
- Zones are split into two tabs, **Eastern Kingdoms** and **Kalimdor**. Switching tab
  selects the first accessible zone of the continent.
- The **Search a zone…** field is now a real search field: filtering is instant, keeps the
  selection consistent and accepts French searches with or without accents.

## 0.14.0 — Complete Classic catalogue

- The **Zones** column covers 46 large Classic outdoor zones and capitals: the Eastern
  Kingdoms and Kalimdor, for the Alliance, the Horde and neutral zones. Starting zones and
  small hamlets are attached to their main region.
- The quest catalogue ships with the addon: opening is immediate and independent of other
  addons.
- A zone without any real outdoor quest says so explicitly, without suggesting that a
  dependency is missing.
- Dungeons, raids and battlegrounds will stay in their own tabs: they are deliberately not
  mixed with the outdoor zone map.

## 0.13.1 — Visual fix

- The progress bar of a zone card is now independent of the counter: it can no longer cover
  `completed / total`.
- The zone name is cut before the percentage column, which stays readable for long names.
- The selection gets a double inner golden outline, brighter and never clipped by the
  scroll bar.

## 0.13.0 — Zones redesign

- The window and the side columns are wider, to keep the information readable.
- Each zone is a list card: thumbnail on the left; name, percentage, bar and total on the
  right. The selection frame is a Blizzard tooltip-style border contained in the card,
  which avoids edges clipped by scrolling.
- A visual search field is added to the zone column, ready to become interactive once the
  catalogue grows.

## 0.12.2 — Visual fix

- Zone cards get their width back. The selection is drawn by four visible golden lines,
  without a white halo.
- The scroll bar of the Zones list is anchored like those of the Blizzard frames: the
  up/down buttons and the thumb stay entirely within the right column of the panel.

## 0.12.1 — Visual fix

- Selecting a zone no longer uses the stretched action texture that washed out the artwork.
  It is replaced by a plain golden border; the background of the **Zones** panel is tinted
  brown-yellow, closer to the game's journal frames.

## 0.12.0 — Visual direction

- A top navigation bar is added: **Quests** is the active tab; **Professions**, **Toys**,
  **Dungeons**, **Raids**, **Achievements** and **Collections** are deliberately greyed out
  until they have content. The icons come from the client.
- Redesign of the **Zones** column: journal background, compact cards, completed / required
  total, bright selection outline and scroll bar moved inside the panel.
- Redesign of the right list: chains have `+` / `−` buttons with the native Blizzard
  textures; each header shows its level range and progress. Single quests show their
  level, their reference XP and a Blizzard check mark once completed.
- The **Rewards** frame fits its height to its content: no large empty frame when the quest
  has no item to show.

## 0.11.2

- The main window uses the `DIALOG` strata, comes to the front each time it opens and also
  when its background is clicked. Ordinary panels of other addons can no longer cover it;
  Blizzard tooltips naturally stay above it.

## 0.11.1 — Critical fix

- Titles come from the local catalogue, without preloading by ID. This avoids the
  synchronous `Refresh` callbacks observed on the Forever client.
- Titles the client already knows keep priority; otherwise the addon only reads the Questie
  reference title, without any native request or listening to the quest data event.

## 0.11.0

- Titles are preloaded by ID as soon as a zone is shown. During the client's asynchronous
  round trip, the interface shows "Loading quest…" instead of a technical `Quest #…`, then
  refreshes itself when the localized data arrives.
- Zone switching fix: the central title, the continent / faction and the quest panel all
  use the zone actually selected.
- The scrolling content on the right moves to the centre of the panel; chain labels no
  longer wrap onto two lines.
- **Teldrassil** (46 quests, levels 1–12) and **Darkshore** (64 quests, levels 10–22) are
  added, with cards and banner artwork. The zone column becomes scrollable to keep the cards
  readable.

## 0.10.0

- The round counter no longer has a double square frame: it keeps only the percentage and
  the progress segments.
- The **Rewards** panel is larger and item icons grow to 46 px, still with their Blizzard
  tooltip.
- The right list is recentred in its panel; chain controls become large yellow `+` / `−`,
  without a black cartouche.
- Three illustrated, clickable zone cards are added. Each card loads its own progress,
  central banner, title and list: **Dun Morogh** (38 quests, levels 1–12), **Westfall**
  (30 quests, levels 9–20) and **Loch Modan** (37 quests, levels 10–22).
- The catalogues come from QuestieDB Forever; left out are the repeatable mount exchanges,
  the *Welcome!* quest not retained for Forever, Gnomeregan on the Dun Morogh card and the
  level 44 quests outside the Westfall range.

## 0.9.0

- The zone column uses clickable cards: the artwork sits within the Elwynn card, which
  prepares the addition of Westfall, Dun Morogh and the other zones.
- The top counter becomes a round gauge made of segments around the percentage; the bar
  under the quest total is removed and optional quests no longer appear in this cartouche.
- The lower panel becomes **Rewards**, with the stable brown/black treatment of the quest
  log instead of the former parchment background, which did not cut out well.
- Chains on the right get a framed brown header and children on a dark background, to
  match the journal's behaviour: a `+` reveals only the linked quests.
- QuestieDB Forever audit: ID 16 (*Give Gerard a Drink*, whose title stays localized by
  the client) is added and the chain of ID 123 (*The Collector*) → ID 147 (*Manhunt*) is
  fixed. The level 60 mount exchanges attached to Elwynn are not kept in the 1–12
  progress.

## 0.8.0 — Look

- Elwynn Forest is illustrated in the left panel; the zone map stays readable in its lower
  cartouche.
- The top of the central panel becomes a progress banner: Elwynn artwork, percentage
  counter, bar and quest total.
- The quest details use the parchment of the Blizzard journal and the game's quest font;
  their information uses colours meant for reading on parchment.
- The right list keeps its collapsible chains and gets a discreet brown journal background,
  so that quest states stay readable.

The artwork textures are stored in `Assets/` as TGA, for direct compatibility with the
Classic client.
