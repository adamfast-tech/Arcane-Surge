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
| Havre-Aube | Profil (portrait, niveau, or, poussière, barre d'XP), titre, **Continuer** (bouton principal), tuiles Carte et Équipement, liste « Prochainement » avec cadenas (loyauté du Cercle, fil de l'Observatoire), état de la sauvegarde et du compte |
| Équipement (Armurerie) | Retour, Forge, bourse ; onglets du porteur ; poupée (personnage sur son socle, 10 emplacements autour, Puissance, flèches vertes des meilleurs objets) ; 5 stats en cases colorées ; fiche de l'emplacement ou de l'objet touché (Améliorer sans retirer, Runes, Retirer ; ou Équiper, Améliorer, Recycler avec la comparaison) ; réserve en grille avec filtres. Détail : `docs/design/35-equipement-runes-forge.md` |
| Forge | Bandeau de Durgan qui commente, 3 onglets à icône ; Gravure (grille d'objets, enclume avec les emplacements en grand, besace de runes et fiche « Graver ») ; Fusion (cercle rituel 3 → 1, grille de réserve) ; Runes (barre de fusion, fiche avec Recycler, grille) |
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
- Aperçus : `?room=map`, `&zone=4` pour une zone, `&prog=14` pour les 14 premiers niveaux gagnés.

## Bibliothèque (`scripts/ui/library_screen.gd`)

- **Ossian**, l'archiviste (portrait dans `scripts/gfx/portrait_art.gd` : cheveux blancs, demi-lunes d'argent, plume, robe d'étude verte, clé des archives), commente en bandeau ; sa phrase change avec l'école choisie.
- **Deck** en barre de sorts : 7 emplacements (icône, lueur à la couleur du sort, cadre au rang, mana), répartition par école et mana moyen. Toucher un sort l'ouvre dans la fiche.
- **Écoles** en médaillons (Tous, Feu, Givre, Foudre, Nature, Ombre, Arcane, Terre, Classes) avec un arc d'or : la part des sorts appris.
- **Sorts** en grille de tuiles, par rang (Novice à Interdit) ; chaque rang indique sorts appris / total et sa fourchette de prix. Une tuile montre l'état du sort : connu (en couleur, mana), dans le deck (coche sarcelle), à apprendre (pâle, prix en or, rouge s'il manque de l'or), verrouillé (cadenas, niveau requis) ; étincelle violette sur la magie interdite.
- **Classes** : 7 médaillons (emblème : leur Ultime, point sarcelle sur ta voie, arc des techniques apprises), puis GRIMOIRE (disciplines en pastilles avec leur compte, techniques par rang) ou LA VOIE (Ultime, sorts d'arbre, sorts de compagnon).
- **Fiche du sort**, fixe en bas : grande tuile, nom, rang, école ou discipline, stats en pastilles (Puissance, Mana, Recharge, Zone, Dégâts, Durée), description, bouton Écouter (la signature sonore du sort), et l'action : AJOUTER AU DECK / RETIRER DU DECK, ou APPRENDRE avec le prix et ce qui bloque (niveau, or manquant, voie, Corruption).
- Aperçus : `?room=library`, `&tab=feu` (ou une autre école, `classes`), `&class=archer`.

