# Chroniques d’Azeroth — prototype bêta

Prototype pour **WoW: Forever** : il relève la progression des quêtes Alliance, Horde et neutres des zones Classic, affiche une carte de progression et un catalogue de référence par zone.

## Installation

1. Copiez le dossier `ChroniquesAzeroth` dans :
   `World of Warcraft/_classic_beta_/Interface/AddOns/`
2. Relancez entièrement le client (la bêta détecte les addons au démarrage).
3. Cochez **Chroniques d’Azeroth** dans la liste des addons à l’écran des personnages.
4. Connectez-vous avec votre Humain puis tapez `/chroniques` (ou `/ca`).

## Ce qui fonctionne dans cette version

- Progression calculée à partir des quêtes que le client marque comme terminées ;
- Catalogue embarqué de 2 307 quêtes réparties sur les 46 zones extérieures et capitales Classic affichées ;
- Carte schématique dont la couleur et le pourcentage évoluent ;
- Un seul badge, déverrouillé lorsque toutes les quêtes requises de la zone sont terminées ;
- Une liste déroulante complète par zone, avec état individuel et regroupement des chaînes ;
- Niveau affiché entre crochets et couleur de difficulté adaptée au niveau du personnage ;
- XP de référence Classic embarquée, préfixée par `env.` pour ne pas la confondre avec une récompense Forever confirmée ;
- Pour une quête active, l'addon privilégie la récompense XP renvoyée directement par le client ;
- Clic sur une quête : fiche avec statut **EN COURS**, niveau, prérequis et suites connues de la série ;
- Les quêtes actuellement dans le journal sont marquées `>` en jaune ;
- Les objets d'une quête active sont lus directement dans le client et restent survolables ;
- Liste organisée en blocs de séries repliables : une quête ne peut appartenir qu’à un seul bloc ;
- Enregistrement local de chaque quête acceptée ou rendue après installation ;
- Sélecteur **Compte / Personnage** : le mode Compte reprend les validations du client ; le mode Personnage n'affiche que les quêtes enregistrées pour le personnage connecté.
- Les quêtes d'introduction facultatives restent dans la liste, mais ne sont pas comptées dans le 100 % : un choix de parcours ne doit pas rendre une zone impossible à terminer.
- En mode **Personnage**, une quête facultative terminée sur le compte mais sautée par ce personnage est masquée ; elle reste visible en mode **Compte**.
- Interface et structure prêtes pour étendre la base de données aux autres zones.

### Professions — phase 1 (0.17.0)

- L'onglet **Professions** est disponible : il affiche les métiers du personnage, leurs rangs et les recettes déjà mémorisées.
- L'addon n'analyse une liste de recettes que lorsque le joueur ouvre volontairement la fenêtre native correspondante. Aucun appel de chargement ni parcours de recettes n'est effectué à la connexion.
- Les recettes connues sont conservées par personnage dans les variables sauvegardées et leurs infobulles utilisent les données déjà fournies par le client.
- Le catalogue complet des patrons, des recettes manquantes et de leurs sources est prévu pour la phase 2.

### Habillage Héritage 0.18.0

- La fenêtre adopte un fond brun sombre légèrement texturé et des bordures natives de l'interface Blizzard, inspirés des fenêtres Héritage.
- Un médaillon rond de progression est ajouté dans l'en-tête gauche. Il est livré localement dans `Assets/heritage-medallion.tga`.
- Les cartes de zones sont maintenant des illustrations pleine largeur : seul le nom de la zone est affiché sur un cartouche sombre, sans pourcentage ni barre de progression.
- Les panneaux Zones, Récompenses et Quêtes n'emploient plus le motif décoratif généré : ils utilisent uniquement des textures et bordures client sobres.

### Ajustements Héritage 0.18.1

- Le cartouche supérieur expérimental est retiré : le titre reste complètement visible.
- Les tuiles Zones affichent maintenant `terminées / requises` en bas à droite, sans remettre de pourcentage.
- La légende de la liste de quêtes est supprimée ; la liste utilise l'espace libéré et son ascenseur est ancré dans la gouttière droite du panneau.

### Médaillon Héritage 0.18.2

- Le médaillon de Chroniques d’Azeroth est désormais posé dans un support circulaire natif, légèrement superposé au coin supérieur gauche de la fenêtre, à l’image des fenêtres Héritage.

### Correctif Tirisfal et interface 0.18.3

- Le support Minimap est retiré du médaillon : l'emblème rond reste seul et est positionné à l'intérieur du coin supérieur gauche.
- Le raccourcissement des noms respecte désormais l'UTF-8 ; les apostrophes françaises ne peuvent plus produire de carré de remplacement.
- Deathknell (zone 154) est rattaché aux Clairières de Tirisfal. La quête réprouvée de départ **Réveil brutal** (ID 363) est également embarquée comme ancrage afin que sa validation soit visible immédiatement.

### Barre de contexte 0.18.4

- La barre sous les onglets reste affichée dans **Quêtes**, **Professions** et les futurs onglets.
- Les filtres statiques (extension, continents et niveaux) sont retirés.
- La faction du personnage connecté s'affiche avec son emblème Blizzard natif, Alliance ou Horde.

### Catalogue des métiers 0.19.0

- L’onglet **Professions** présente les métiers, le catalogue de recettes et une fiche de détail avec composants et mode d’obtention.
- À l’ouverture volontaire d’un métier natif, les recettes apprises **et non apprises** que le client expose sont mémorisées ; la liste est virtualisée pour rester fluide sur les grands catalogues.
- Les composants et le texte de provenance sont lus uniquement pour la recette sélectionnée. Si le client Forever ne fournit pas une provenance, l’interface l’indique explicitement au lieu d’inventer une source.

### Catalogues métiers Forever 0.20.0

- Les listes complètes de **Forge** (506 recettes), **Cuisine** (133) et **Secourisme** (32) sont désormais livrées avec l’addon, même lorsque le personnage n’a pas encore appris le métier.
- Chaque ligne indique la compétence requise et l’état appris / à obtenir. Dès que le métier est ouvert volontairement dans le client, l’état réel des recettes est synchronisé pour le personnage.
- La fiche montre la catégorie d’acquisition connue (maître, vendeur, butin ou source spéciale). Les composants et une éventuelle provenance détaillée sont demandés uniquement pour la recette sélectionnée via les API déjà exposées par le client Forever.

### Correctif métiers 0.20.1

- L’ouverture d’un métier attend maintenant que la liste native soit réellement disponible avant de synchroniser les recettes apprises ; le compteur `apprises / catalogue` reflète ainsi la forge déjà connue par le personnage.
- Les icônes de recettes proviennent en priorité de la fenêtre de métier native, et les icônes de composants sont résolues directement par ID sans attendre le chargement de leur nom.
- Le bouton d’actualisation et son texte explicatif sont retirés : la synchronisation est automatique à l’ouverture volontaire du métier, et la place libérée sert à afficher plus de recettes.

### Correctif comptage des recettes 0.20.2

- La synchronisation Forever lit désormais `isLearned`, l’état réellement fourni par le client, au lieu de considérer une propriété absente comme une recette apprise. Les anciennes données erronées ne sont plus comptées et sont remplacées à la prochaine ouverture du métier.
- Les recettes effectivement apprises sont distinguées par un fond et un texte vert sombre dans la liste centrale ; les recettes restantes conservent le fond sombre neutre.
- Les métiers de récolte n’affichent plus leur rang dans la colonne de gauche : ce rang pouvait être confondu avec un compteur de recettes.

### Correctif de source de recettes 0.20.3

- Le compteur ne dépend plus des drapeaux modernes du catalogue Forever, qui marquent des patrons disponibles comme appris. Les seules recettes comptées sont celles que la fenêtre classique identifie avec une difficulté de recette connue.
- Une migration invalide le faux état mémorisé par les versions précédentes avant la prochaine synchronisation fiable.
- Le caractère de coche non pris en charge par la police Classic est retiré des niveaux : plus aucun rectangle de remplacement à côté de `Niv.`.

### Synchronisation des recettes 0.21.0

- Révision de migration intermédiaire, remplacée par la lecture de la fenêtre native décrite en 0.21.1 : le grimoire ne reflète pas tous les patrons métiers sur ce client.

### Synchronisation métier autonome 0.22.3

- Analyse de l’addon All The Things fourni : sur le client Classic/Forever, il synchronise les recettes lors de `TRADE_SKILL_SHOW` en parcourant `GetNumTradeSkills` et `GetTradeSkillInfo`, puis mémorise les sorts connus. Il ne dépend pas de la liste moderne complète des patrons pour décider qu’une recette est apprise.
- Chroniques adopte le même critère et accepte les types propres à Forever `used` et `none`, en plus de `optimal`, `medium`, `easy` et `trivial`. Ces deux types étaient la cause du faux `0 / 506`.
- Chroniques écoute aussi `TRADE_SKILL_LIST_UPDATE`, `NEW_RECIPE_LEARNED` et `LEARNED_SPELL_IN_TAB`, comme ATT : une recette nouvellement apprise est mémorisée même si sa page Chroniques est fermée.
- L’affichage hors fenêtre de métier reste possible grâce à la sauvegarde locale du dernier relevé fiable. Ouvrir Forge est néanmoins nécessaire une première fois pour établir la liste complète du personnage.
- Correctif d’identification : la fenêtre métier Forever retourne principalement les noms localisés ; le catalogue compact ne les embarque pas. Chroniques construit donc son index local `nom de sort → ID de sort` via `GetSpellInfo`, comme l’index `SpellNameToSpellID` d’ATT. Les recettes lues peuvent désormais être rapprochées des 506 entrées du catalogue et comptées.
- ATT 5.3.15 reste uniquement une référence étudiée pour le flux Blizzard. Chroniques ne lit aucune donnée, variable sauvegardée ou bibliothèque d’un autre addon : il fonctionne sans dépendance hors client WoW.
- Le scan attend que la fenêtre native soit stable, se relance si Chroniques est ouverte après le métier et expose `/ca diag` en cas de vérification : il affiche le nombre d’entrées natives, de recettes connues, d’IDs résolus et de recettes mémorisées.
- Les noms retournés par `GetTradeSkillInfo` sont maintenant résolus d’abord par l’API locale `GetSpellInfo(nom)`/`C_Spell.GetSpellInfo(nom)`, puis par l’index interne de Chroniques. Aucun nom, ID ou état de recette n’est emprunté à ATT.
- Correctif Forever : la visibilité de `TradeSkillFrame` n’est pas fiable sur ce client, alors que `GetTradeSkillLine` et `GetNumTradeSkills` exposent bien le métier actif. Chroniques s’appuie désormais sur ces deux API natives pour autoriser le relevé.

### Catalogue de quêtes autonome 0.23.0

- Les 46 zones affichées reçoivent un catalogue local généré à partir des données Forever : titres français, niveaux, XP de référence, faction et liens de série.
- Le fichier `QuestCatalog.lua` est chargé avec Chroniques. Il n’existe plus aucun chargement, variable globale ou dépendance déclarée vers Questie ou QuestieDB.
- Les quêtes spécifiques à une faction sont filtrées dans les zones neutres selon le personnage connecté ; le catalogue conserve néanmoins les deux factions localement.
- La lecture des validations historiques est étalée sur plusieurs images à la connexion afin que le catalogue complet ne crée pas de ralentissement perceptible.

### Audit des chaînes 0.23.1

- Les quêtes répétables, les échanges de monture, les entrées « Bienvenue ! » contextuelles et les marqueurs techniques ne participent plus aux totaux de zone.
- Chaque ID est unique dans sa zone. Les liens de chaîne sont normalisés dans les deux sens afin qu'une suite déclarée sans prérequis réciproque reste dans le même groupe visuel.
- Les quêtes facultatives restent visibles mais ne gonflent pas la progression requise.

### Blocs de séries cohérents 0.23.2

- La liste construit maintenant un bloc unique par composant de chaîne : tous les prérequis et toutes les suites reliés dans une zone restent ensemble, même lorsqu’une étape possède plusieurs liens.
- Un bloc replié ne montre que son en-tête et son avancement ; déplié, il montre chaque ID une seule fois dans l’ordre de la série. Les titres identiques correspondant à des étapes distinctes ne peuvent donc plus apparaître dans des groupes séparés.
- Le générateur vérifie aussi ces composants : la version livrée contient 997 blocs, dont 429 séries multi-quêtes, sans membre manquant ni affectation dupliquée.

### Raccourci de minicarte 0.23.3

- Un médaillon Chroniques est disponible autour de la minicarte. Le clic gauche ouvre ou ferme la fenêtre ; le clic droit bascule le suivi entre **Compte** et **Personnage**.
- Le bouton se déplace par glisser-déposer sur le pourtour de la minicarte. Sa position est enregistrée dans les variables de Chroniques.

### Professions — compte et catalogues complets 0.24.0

- Le sélecteur **Compte / Personnage** s'applique désormais aussi aux métiers : le mode Personnage lit exclusivement les recettes connues du personnage connecté ; le mode Compte affiche leur union sur les personnages qui ont déjà été synchronisés avec Chroniques.
- Les états de recettes restent sauvegardés séparément par personnage puis sont indexés dans les variables de compte. Il suffit de se connecter une fois avec un personnage existant pour qu'il rejoigne l'union du compte.
- Huit catalogues complets sont livrés localement : **Alchimie** (194), **Forge** (501), **Enchantement** (262), **Ingénierie** (276), **Travail du cuir** (593), **Couture** (463), **Cuisine** (133) et **Secourisme** (31), soit **2 453 recettes**.
- Les métiers de récolte n'affichent volontairement aucun faux compteur de recettes. Pour chaque recette de fabrication, les composants et la catégorie d'obtention disponibles sont embarqués dans l'addon ; aucun addon tiers ni accès réseau n'est nécessaire pendant le jeu.

### Alignement de la barre de contexte 0.24.1

- Les deux boutons de continent ont désormais une largeur identique et des icônes de continent dédiées ; le libellé des Royaumes de l’Est reste contenu dans son bouton.
- Les ensembles **Faction** et **Suivi** sont ancrés sur une ligne centrale commune : emblème, libellé et boutons Compte / Personnage partagent le même alignement vertical.

### Portrait d’en-tête et respiration 0.24.2

- Le médaillon doré interne est remplacé par un portrait circulaire original doté de son anneau bronze, légèrement superposé au coin supérieur gauche du cadre.
- Le nom de faction est rapproché de son emblème. Les deux groupes de la barre de contexte sont remontés afin de laisser une marge visible avant les panneaux inférieurs.

### Médaillon d’en-tête 0.24.3

- Le portrait expérimental est retiré. Le médaillon étoilé de Chroniques retrouve sa place, avec son anneau métallique et un chevauchement discret du coin supérieur gauche du cadre.

### Anglais et feedback 0.25.0

- Chroniques choisit automatiquement le français sur un client `frFR` et l’anglais sur les autres clients. Les 2 307 titres de quêtes sont embarqués dans les deux langues ; les noms de recettes et de composants sont lus dans la langue du client.
- Les intitulés d’interface, zones, continents, métiers, onglets et états de suivi sont localisés en anglais sans nécessiter Questie, ATT ni accès réseau.
- Un onglet **Feedback** prépare un rapport de diagnostic sélectionnable. Rien n’est envoyé automatiquement : le joueur le copie avec `Ctrl+C`, puis le colle dans le canal choisi (ticket GitHub conseillé pour les bugs, Discord pour les échanges rapides).

### Compatibilité de police et navigation 0.24.5

- Les séparateurs entre les quêtes liées emploient désormais une virgule : la flèche Unicode, absente de la police de détail Classic, ne peut plus apparaître sous forme de rectangle.
- Les textes affichés par l’interface évitent les symboles Unicode non garantis par les polices de la bêta ; les caractères français (accents, apostrophes et ligatures) restent encodés en UTF-8.
- Les onglets **Hauts faits** et **Collections** sont retirés. Les onglets **Jouets**, **Donjons** et **Raids** indiquent désormais **(à venir)**.

### Correction Faction 0.24.4

- Le libellé de faction est maintenant justifié à gauche et directement ancré après son emblème. La zone réservée au libellé ne peut plus le centrer artificiellement loin de l’icône.

### Habillage 0.8.0

- La zone d’Elwynn est maintenant illustrée dans le panneau de gauche ; la carte de zone reste lisible dans son cartouche inférieur.
- La partie haute du panneau central devient une bannière de progression : illustration d’Elwynn, compteur de pourcentage, barre et total de quêtes.
- La fiche de quête adopte le parchemin du journal Blizzard et la police de quête du jeu ; les informations y utilisent des couleurs prévues pour une lecture sur parchemin.
- La liste de droite garde les séries repliables et reçoit un fond de journal brun, discret afin que les états de quêtes restent lisibles.

Les textures d’illustration sont stockées dans `Assets/` au format TGA, pour une compatibilité directe avec le client Classic.

### Révision 0.9.0

- La colonne des zones utilise maintenant des cartes cliquables : l’illustration est contenue dans la carte d’Elwynn, ce qui prépare l’ajout de Marche de l’Ouest, Dun Morogh et des autres zones.
- Le compteur supérieur devient une jauge circulaire composée de segments autour du pourcentage ; la barre sous le total de quêtes est supprimée et les quêtes facultatives ne figurent plus dans ce cartouche.
- Le panneau inférieur devient **Récompenses**, avec le traitement brun/noir stable du journal de quêtes à la place de l’ancien fond de parchemin qui se découpait mal.
- Les séries de droite ont un en-tête brun encadré et des enfants sur fond sombre, afin de correspondre au comportement du journal : un `+` révèle uniquement les quêtes liées.
- Audit QuestieDB Forever : ajout de l’ID 16 (*Give Gerard a Drink*, dont le titre reste localisé par le client) et correction de la chaîne ID 123 (*The Collector*) → ID 147 (*Manhunt*). Les échanges de montures niveau 60 associés à Elwynn ne sont pas retenus dans la progression 1–12.

### Révision 0.10.0

- Le compteur circulaire ne contient plus de double cadre carré : il ne conserve que le pourcentage et les segments de progression.
- Le panneau **Récompenses** est agrandi et les icônes d’objets passent à 46 px, tout en gardant leur infobulle Blizzard.
- La liste de droite est recentrée dans son panneau ; les contrôles de séries deviennent de grands `+` / `−` jaunes, sans cartouche noir.
- Ajout de trois cartes de zones illustrées et cliquables. Chaque carte charge sa propre progression, bannière centrale, titre et liste : **Dun Morogh** (38 quêtes, niveaux 1–12), **Marche de l’Ouest** (30 quêtes, niveaux 9–20) et **Loch Modan** (37 quêtes, niveaux 10–22).
- Les catalogues proviennent de QuestieDB Forever ; sont exclus les échanges répétables de montures, la quête *Welcome!* non retenue pour Forever, Gnomeregan dans la carte de Dun Morogh et les quêtes de niveau 44 hors de la tranche de Marche de l’Ouest.

### Révision 0.11.0

- Les titres sont préchargés par ID dès qu’une zone est affichée. Pendant l’aller-retour asynchrone du client, l’interface affiche « Chargement de la quête… » au lieu d’un identifiant technique `Quête #…`, puis se rafraîchit automatiquement à la réception des données localisées.
- Correction du changement de zone : le titre central, le continent/faction et le panneau de quêtes utilisent désormais tous la zone effectivement sélectionnée.
- Le contenu déroulant de droite est déplacé vers le centre du panneau ; les libellés de séries ne passent plus sur deux lignes.
- Ajout de **Teldrassil** (46 quêtes, niveaux 1–12) et de **Sombrivage** — nom français de *Darkshore* — (64 quêtes, niveaux 10–22), avec cartes et bannières illustrées. La colonne des zones devient défilable pour conserver des cartes lisibles.

### Correctif critique 0.11.1

- Les titres viennent du catalogue local sans préchargement par ID. Cela évite les rappels synchrones de `Refresh` observés sur le client Forever.
- Les titres déjà connus du client restent prioritaires ; sinon l'addon lit seulement le titre de référence Questie, sans émettre de requête native ni écouter l'événement de chargement des données de quête.

### Révision 0.11.2

- La fenêtre principale utilise désormais la strate `DIALOG`, devient prioritaire à chaque ouverture et remonte également au premier plan lors d'un clic sur son fond. Les panneaux standards d'autres addons ne peuvent plus recouvrir l'interface ; les infobulles Blizzard restent naturellement au-dessus.

### Direction visuelle 0.12.0

- Ajout d'une barre de navigation supérieure : **Quêtes** est l’onglet actif ; **Professions**, **Jouets**, **Donjons**, **Raids**, **Hauts faits** et **Collections** sont volontairement grisés en attendant leur contenu. Les pictogrammes viennent des icônes déjà présentes dans le client.
- Refonte de la colonne **Zones** : fond de journal, cartes compactes, total terminé/total requis, contour lumineux de sélection et ascenseur recentré à l’intérieur du panneau.
- Refonte de la liste de droite : les séries ont des boutons `+` / `−` utilisant les textures natives Blizzard ; chaque en-tête affiche sa plage de niveaux et son avancement. Les quêtes individuelles affichent leur niveau, leur XP de référence et une coche Blizzard lorsqu’elles sont terminées.
- Le cadre **Récompenses** adapte sa hauteur au contenu : aucune grande zone encadrée vide lorsque la quête ne possède pas d’objet à afficher.

### Correctif visuel 0.12.1

- La sélection d’une zone n’utilise plus la texture d’action étirée qui blanchissait les illustrations. Elle est remplacée par une simple bordure dorée ; le fond du panneau **Zones** est désormais teinté brun-jaune, plus proche des cadres de journal du jeu.

### Correctif visuel 0.12.2

- Les cartes de zones reprennent de la largeur. La sélection est maintenant dessinée par quatre traits dorés visibles, sans halo blanc.
- L'ascenseur de la liste Zones est ancré comme celui des cadres Blizzard : les boutons haut/bas et le curseur restent intégralement dans la colonne de droite du panneau.

### Refonte Zones 0.13.0

- La fenêtre et les colonnes latérales sont élargies afin de conserver des informations lisibles.
- Chaque zone est maintenant une carte de liste : vignette à gauche, nom, pourcentage, barre et total à droite. Le cadre de sélection est une bordure de type infobulle Blizzard contenue dans la carte, ce qui évite les bords tronqués par le défilement.
- Ajout d'un champ de recherche visuel dans la colonne des zones, prêt à être rendu interactif lors de l'ajout d'un catalogue plus long.

### Correctif visuel 0.13.1

- La barre de progression d'une carte de zone est maintenant indépendante du compteur : elle ne peut plus recouvrir `terminées / total`.
- Le nom de zone est limité avant la colonne de pourcentage, qui reste toujours lisible pour les noms longs.
- La sélection reçoit un double contour doré interne, plus lumineux et sans risque de découpe par l'ascenseur.

### Catalogue Classic complet 0.14.0

- La colonne **Zones** couvre désormais 46 grandes zones extérieures et capitales Classic : les Royaumes de l’Est et Kalimdor, pour l’Alliance, la Horde et les zones neutres. Les zones de départ et petits hameaux sont correctement rattachés à leur région principale.
- Le catalogue de quêtes est livré directement avec l’addon : l’ouverture est immédiate et indépendante des autres addons.
- Une zone sans quête extérieure réelle affiche un état explicite, sans suggérer qu'une dépendance manque.
- Les donjons, raids et champs de bataille resteront dans leurs onglets dédiés : ils ne sont volontairement pas mélangés à la carte des zones extérieures.

### Navigation de faction et continents 0.15.0

- La navigation détecte la faction du personnage connecté. Pour un personnage Alliance, les zones strictement Horde ne sont plus proposées et les quêtes Horde-only de zones neutres sont exclues localement.
- Les zones sont séparées en deux onglets **Royaumes de l’Est** et **Kalimdor**. Changer d’onglet sélectionne automatiquement la première zone accessible du continent.
- Le champ **Rechercher une zone…** est désormais un vrai champ de recherche : le filtrage est instantané, conserve la sélection cohérente et accepte les recherches françaises avec ou sans accents.

### Illustrations des zones 0.16.0

- Les 47 liens du manifeste fourni ont été importés, contrôlés et convertis en textures TGA RGB de 768 × 256, un format sûr pour le client Classic.
- Les 46 zones et capitales du catalogue utilisent désormais leur illustration dédiée aussi bien dans la vignette de gauche que dans la bannière centrale. L’illustration supplémentaire de **Mont Blackrock** est utilisée pour la bannière des Steppes ardentes.
- Les vignettes recadrent les illustrations panoramiques au lieu de les étirer, ce qui préserve le paysage et évite toute déformation sur la liste des zones.
- `tools/import_zone_art.py` permet de reconstruire les textures à partir du manifeste et vérifie qu’aucune de ses 47 entrées n’est manquante.

### Ajustement de lisibilité 0.16.1

- La liste de quêtes utilise 20 px supplémentaires de largeur utile et une zone de défilement plus haute. Les titres, niveaux, XP et coches sont espacés dans des colonnes dédiées jusqu’au bord de l’ascenseur.
- Les barres de progression, pourcentages de zones et anneaux de progression utilisent un vert forêt plus sombre, inspiré du journal Blizzard.
- L’onglet **Kalimdor** emploie maintenant une icône de nature disponible sur le client Forever.
- Lorsqu'aucune XP de référence n'est connue, l’interface affiche `—` au lieu de l’ambigu `XP ?`.

## Sources et règles de comptage

Le catalogue est généré au développement depuis les données publiques Forever puis embarqué dans `QuestCatalog.lua`. À l’exécution, Chroniques ne charge ni ne consulte Questie/QuestieDB : le client Forever reste la seule autorité pour le statut dans le journal ainsi que les récompenses exactes (XP, argent et objets) d’une quête active.

Le catalogue Classic de référence d'Elwynn a été recoupé avec QuestieDB Forever, [ForeverDB — Elwynn Forest](https://foreverdb.net/quests/elwynn-forest) et les pages [Wowhead Forever](https://www.wowhead.com/forever/fr/quest=7), le 4 octobre 2026. Il contient 45 quêtes requises et une introduction facultative.

[ForeverChanges](https://foreverchanges.pro/fr/quest/7) est la source complémentaire pour identifier les quêtes et changements propres à Forever. Ses titres peuvent être en anglais : l'addon ne les recopie pas et continue de demander le titre localisé au client du joueur.

Une quête est **requise** par défaut : elle compte dans le dénominateur du pourcentage. Elle devient **facultative** uniquement lorsqu'un parcours réellement accessible permet de la contourner sans bloquer la zone. L'introduction `Eagan Peltskinner` (ID 5261) est le premier cas validé : le PNJ propose directement la quête suivante. Cette règle ne repose donc pas sur une supposition de l'API. Pour les futurs embranchements exclusifs, les quêtes seront regroupées : compléter une branche validera le groupe, sans imposer les autres.

## Limite assumée de la bêta

Les listes de quêtes et l’API de Forever peuvent évoluer avant la sortie. La liste d’IDs est volontairement centralisée au début de `ChroniquesAzeroth.lua`, afin de la valider puis de l’enrichir sans toucher à l’interface. Les donjons et raids sont affichés comme prochaine étape : leur lecture réelle sera ajoutée après avoir vérifié l’événement/API disponible dans ton client bêta.

En mode **Personnage**, les quêtes terminées avant la mise à jour ne peuvent pas être séparées avec certitude des quêtes faites par les autres personnages si le client Forever les expose au niveau du compte. À partir de cette version, toute quête acceptée ou rendue est enregistrée dans un fichier propre au personnage.

## Synchronisation compte et personnages

À chaque connexion, l'addon lit les quêtes terminées du personnage actuellement connecté, enregistre sa liste personnelle puis fusionne toutes les listes personnelles connues dans la progression du compte. Il ne lit pas les fichiers `WTF` d'autres personnages pendant le jeu : les addons WoW n'y ont pas accès. Pour importer l'historique d'un ancien personnage, il suffit donc de se connecter une fois avec lui après l'installation de cette version.
