# Étape 10.2 ter — Refonte de l'interface (concept UI)

> D'après le concept fourni (chargement, Havre-Aube, Équipement & Forge). Code : `scripts/core/ui_theme.gd`, `scripts/core/rune_box.gd`, `scripts/gfx/icons.gd`.

## 1. Langage visuel
| Élément | Choix |
|---|---|
| Palette | Bleu nuit (`#0b111a` fond, `#101a26` panneaux, `#162333` boutons), bordures acier-sarcelle `#2b4153`, sarcelle `#6fdccf` pour les icônes et le survol, or `#f2c46b` pour l'action principale et les monnaies |
| Cadres | Coins coupés en biseau (`RuneBox`), bordure de 2 px. Les boutons principaux ont un fond chaud, une bordure or et des coins soulignés |
| Icônes | **Au trait fin** (style de la maquette) : dessins SVG 24×24, convertis à la taille voulue au lancement, teintés à la volée |
| Polices | Jersey 15 pour les titres (Pixelify Sans confondait « B » et « G »), Jersey 10 pour le texte |
| Illustration | Moins assombrie ; dégradé sombre en bas de Havre-Aube pour la lisibilité |

## 2. Icônes (41)
- **Interface** : rune, carte, chevron, retour, cadenas, livre, cible, cercle, lune, pièce, poussière, nuage, déconnexion, étoile, pause, lecture, enclume, étincelle.
- **Objets** : une icône par objet — Bâton de chêne, Baguette de saule, Bâton de bois-lune, Bâton de la Première Sève, Orbe de lucioles, Capuche, Robe, Gants, Bottes, Médaillon, Anneau, Charme. La couleur de l'icône et de son cadre est celle de la **rareté**. Les emplacements vides reprennent l'icône du type d'objet, en gris.
- **Sorts et pouvoirs** : Boule de feu, Pluie de givre, Racines, Éclair en chaîne, Vortex d'ombre, Onde arcanique, Purifier, Météore, Champion, Bouclier levé, Tir de précision (à la couleur du sort sur les boutons de combat).

## 3. Écrans
| Écran | Contenu |
|---|---|
| Chargement | « ARCANE » (or) / « SURGE », séparateur runique, illustration, « Éveil des runes » et barre de chargement (1,2 s minimum) |
| Havre-Aube | Profil (portrait, niveau, or, poussière, barre d'XP, titre de haut fait), titre, place du village où le héros se promène (`docs/design/49-havre-aube-place.md`), **Continuer** (bouton principal), tuiles Défis et Tour des Échos (docs 47, 48), tuiles Carte et Équipement, petites tuiles Forge, Armurerie (rareté de la vitrine ou temps avant l'arrivage), Entraînement, Bibliothèque, Cercle, Méditation, liste « Prochainement » avec cadenas (loyauté du Cercle, fil de l'Observatoire), état de la sauvegarde et du compte |
| Équipement | Retour, Forge, bourse ; onglets du porteur ; poupée (héros en volume qu'on fait tourner, 10 emplacements autour, Puissance, flèches vertes des meilleurs objets) ; Apparence du héros (4 pièces cosmétiques, Visible/Masquée, lien vers l'Armurerie ; Poses, Lumière, Casque visible/masqué, Carte du héros : `docs/design/45-heros-anime.md`) ; 5 stats en cases colorées ; fiche de l'emplacement ou de l'objet touché (Améliorer sans retirer, Runes, Retirer ; ou Équiper, Améliorer, Recycler avec la comparaison) ; réserve en grille avec filtres. Détail : `docs/design/35-equipement-runes-forge.md` |
| Armurerie | Bandeau d'Aldric qui commente, onglets Équipement et Curiosités ; Équipement : compte à rebours de l'arrivage et un bruit de boutique qui change à chaque arrivage, vitrine en grand, 6 offres en grille (stats, comparaison, ACHETER) ; Curiosités : essayage sur le héros en volume, une carte par kit (4 vignettes, bonus 2 et 4 pièces, achat, port). Détail : `docs/design/44-armurerie-cosmetiques.md` |
| Cercle, carte, cinématiques | Personnages en volume : autour du feu au Cercle (lumière du bivouac), le héros qui marche entre les niveaux sur la carte, la troupe en pied derrière les bustes des cinématiques. Détail : `docs/design/45-heros-anime.md` |
| Forge | Bandeau de Durgan qui commente, 3 onglets à icône ; fusion et gravure jouées par Durgan en volume (`docs/design/46-forge-animee.md`) ; Gravure (grille d'objets, enclume avec les emplacements en grand, besace de runes et fiche « Graver ») ; Fusion (cercle rituel 3 → 1, grille de réserve) ; Runes (barre de fusion, fiche avec Recycler, grille) |
| Carte du monde | En haut : retour, Puissance, étoiles de la zone, frise des 7 zones (emblème de la zone, numéro d'acte, arc d'or des étoiles gagnées, coche quand la zone est finie, cadenas sinon). Au centre, la carte illustrée de la zone (`scripts/ui/map_board.gd`, détail ci-dessous). En bas, la fiche du niveau touché : type, étoiles, record, description, jauge Puissance / conseillée (Prêt, Ardu, Périlleux), bouton Solo (+25 % d'XP) et JOUER, ou « Verrouillé » avec le niveau à finir avant |
| Combat | Icône de chaque sort au-dessus de son nom, icônes de pause et d'Ultime, étoiles de fin au trait |

## Défilement tactile

- Dans toute liste défilante (Bibliothèque, Carte, Équipement, Entraînement, Cercle, Sauvegarde, historique des dialogues), on fait défiler en glissant le doigt n'importe où, y compris sur une carte ou un bouton (`scripts/core/touch_scroll.gd`).
- Les boutons et les cadres d'une liste laissent passer les évènements vers le conteneur (`MOUSE_FILTER_PASS`).
- Au-delà de 14 px de glissé, l'appui devient un défilement, et l'appui en cours sur un bouton est annulé : relâcher ne le déclenche pas.
- Un écran reconstruit après un clic garde sa position de défilement.

## Carte du monde (`scripts/ui/map_screen.gd`, `scripts/ui/map_board.gd`)

- **Terrain** propre à chaque zone, peint en pixel art au lancement (pixel ×3, comme les décors de combat), gardé en cache : sous-bois des Lucioles, collines d'Ambre (ondulations), mares du Marais, neige et lacs gelés des Pics, dunes du Désert, failles de lave de la Forêt cendrée, dalles englouties de la Cité. Le chemin a sa matière : terre, ornières, ponton, neige tassée, pavés, basalte, dalles.
- **Sentier** en lacet, du premier niveau (en bas) au boss (en haut). Parcouru : lueur d'or et pas dorés. Vers le prochain niveau : pas sarcelle qui avancent. Au-delà : assombri, sous une brume qui couvre tout ce qui est verrouillé.
- **Décors** tirés des accessoires des combats de la zone (arbres, moulins, maisons sur pilotis, sapins et flèches de glace, obélisques et cristaux, arbres calcinés et autels, coraux et statues), placés loin du chemin et des noms. Un repère marque l'antre du boss (la Sylvarche, la tour de guet, le grand crâne, la Porte naine, l'obélisque, l'autel du Wyrm, l'arche de corail) et un autre l'entrée de la zone.
- **Médaillons** : un par niveau, à l'icône de son type (Assaut : épées, Mini-boss : casque à cornes, Boss : crâne, Escorte : drapeau, Purification : soleil, Siège : tour). Or quand il est gagné, sarcelle et palpitant pour le prochain, gris avec un cadenas sinon. Le boss est plus grand, avec 5 piques ; le mini-boss en a 3. Numéro sur un cartouche, 3 étoiles en couronne, nom et type à côté.
- **Héros** : son sprite attend à côté du prochain niveau.
- **Particules** selon la zone : lucioles, pollen, nappes de brume, neige, sable, braises, bulles (option d'ambiance « Enrichie » ; sinon la carte est fixe).
- À l'ouverture, la carte défile jusqu'au niveau choisi (le prochain de la zone, sinon le dernier ouvert).
- **Fluidité** : la carte est dessinée en trois calques sous les médaillons. Le terrain, les décors, le chemin fixe et l'ombre du héros, puis la vignette et le cadre, sont dessinés une seule fois ; seul le calque animé (pas, anneau du héros, brume, particules) se redessine à chaque image, et le découpage du chemin est calculé à l'ouverture. Le halo d'un médaillon vit dans un calque sous lui : le médaillon n'est plus redessiné à chaque image. Image identique au pixel près (vérifiée par comparaison de captures) ; calcul par image de la carte divisé par environ 2,5.
- Aperçus : `?room=map`, `&zone=4` pour une zone, `&prog=14` pour les 14 premiers niveaux gagnés. `&fps=1` (sur n'importe quel écran) affiche un compteur d'images par seconde discret, en haut à gauche.

## Bibliothèque (`scripts/ui/library_screen.gd`)

- **Ossian**, l'archiviste (portrait dans `scripts/gfx/portrait_art.gd` : cheveux blancs, demi-lunes d'argent, plume, robe d'étude verte, clé des archives), commente en bandeau ; sa phrase change avec l'école choisie.
- **Deck** en barre de sorts : 7 emplacements (icône, lueur à la couleur du sort, cadre au rang, mana), répartition par école et mana moyen. Toucher un sort l'ouvre dans la fiche.
- **Écoles** en médaillons (Tous, Feu, Givre, Foudre, Nature, Ombre, Arcane, Terre, Classes) avec un arc d'or : la part des sorts appris.
- **Sorts** en grille de tuiles, par rang (Novice à Interdit) ; chaque rang indique sorts appris / total et sa fourchette de prix. Une tuile montre l'état du sort : connu (en couleur, mana), dans le deck (coche sarcelle), à apprendre (pâle, prix en or, rouge s'il manque de l'or), verrouillé (cadenas, niveau requis) ; étincelle violette sur la magie interdite.
- **Classes** : 7 médaillons (emblème : leur Ultime, point sarcelle sur ta voie, arc des techniques apprises), puis GRIMOIRE (disciplines en pastilles avec leur compte, techniques par rang) ou LA VOIE (Ultime, sorts d'arbre, sorts de compagnon).
- **Fiche du sort**, fixe en bas : grande tuile, nom, rang, école ou discipline, stats en pastilles (Puissance, Mana, Recharge, Zone, Dégâts, Durée), description, bouton Écouter (la signature sonore du sort), et l'action : AJOUTER AU DECK / RETIRER DU DECK, ou APPRENDRE avec le prix et ce qui bloque (niveau, or manquant, voie, Corruption).
- Aperçus : `?room=library`, `&tab=feu` (ou une autre école, `classes`), `&class=archer`.

## Salle de méditation (`scripts/ui/meditation_screen.gd`)

- **Sœur Aelis** commente en bandeau ; sa phrase change avec l'onglet (et quand la Corruption atteint 30).
- Trois onglets à icône : VOIES, CONFIGURATIONS, HARMONIE.
- **VOIES** : un mandala (cercles de runes, couronne de traits qui tourne lentement, étoile à 7 branches) ; le héros au centre, les 7 voies en médaillons autour (emblème : leur Ultime ; point sarcelle sur la voie actuelle). Toucher une voie l'illumine et ouvre sa fiche : le héros dans cette voie (sa tenue et son arme), la description, les points déjà placés dans son arbre, l'Ultime, les disciplines du grimoire, puis EMPRUNTER CETTE VOIE. Plus bas, chaque compagnon : portrait, voie actuelle et les 7 voies en petits médaillons (un toucher change sa voie).
- **CONFIGURATIONS** : 3 sceaux (I, II, III). Un sceau gravé montre la voie, les points de l'arbre, le deck en icônes et les Clés de voûte ; CHARGER (gratuit) ou REMPLACER. Un sceau libre propose ENREGISTRER ICI.
- **HARMONIE** : la Corruption sur une jauge circulaire (repères à 30 et 60), son état en une phrase, MÉDITER (prix, Corruption −5) ; puis la réinitialisation de l'arbre de la voie actuelle, en deux touchers.

## Le Cercle (`scripts/ui/circle_screen.gd`)

- **Formation de combat** autour d'un feu de camp animé (flammes, étincelles, lueur au sol). Le bivouac est dressé là où en est l'histoire : derrière le feu, l'illustration du lieu du prochain combat (la planche de ses cinématiques, ou la plus proche), à la tombée de la nuit. Elle est traitée en arrière-plan lointain : rendue petite (pixels de 2), elle ne montre que son ciel, son horizon (placé au-dessus des têtes, sous une légère brume) et son sujet, décalé entre le compagnon de gauche et le héros ; au premier plan, le sol du bivouac prend la couleur du terrain de la zone. Le bandeau indique « Bivouac · zone » et la prochaine étape. Dans la formation : le héros au centre, les 2 compagnons emmenés à gauche et à droite, avec leur côté (GAUCHE · BRANN…), et ÉCHANGER LES CÔTÉS. Ceux qui restent à Havre-Aube sont en petits portraits. Toucher un compagnon ouvre sa fiche.
- **Onglets** des compagnons (portrait, nom, niveau).
- **Fiche** : portrait, nom, côté (pastille), race, voie, niveau, rôle ; jauges d'XP et de loyauté (repère doré à 75 : amitié, +5 % de stats) ; Puissance, objets équipés et ÉQUIPEMENT ; EMMENER AU COMBAT (à la place d'un compagnon emmené) pour ceux restés à Havre-Aube.
- **Ordre par défaut**, **Tir normal** et **Sort emporté** en tuiles : icône dans un médaillon, titre, ce que fait le choix (Focus Nexus : attaque le Nexus ennemi ; Défends : protège la Barrière ; Suis-moi : vise là où tu vises ; Libre : décide seul ; Troupes ou Tir de classe ; mana et recharge du sort), coche sur le choix actuel. Choisir un sort fait entendre sa signature.

