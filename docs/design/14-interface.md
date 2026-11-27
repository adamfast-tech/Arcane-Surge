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
| Carte | Même style ; bouton Jouer principal, cadenas sur les niveaux verrouillés, étoiles au trait |
| Combat | Icône de chaque sort au-dessus de son nom, icônes de pause et d'Ultime, étoiles de fin au trait |

## Défilement tactile

- Dans toute liste défilante (Bibliothèque, Carte, Équipement, Entraînement, Cercle, Sauvegarde, historique des dialogues), on fait défiler en glissant le doigt n'importe où, y compris sur une carte ou un bouton (`scripts/core/touch_scroll.gd`).
- Les boutons et les cadres d'une liste laissent passer les évènements vers le conteneur (`MOUSE_FILTER_PASS`).
- Au-delà de 14 px de glissé, l'appui devient un défilement, et l'appui en cours sur un bouton est annulé : relâcher ne le déclenche pas.
- Un écran reconstruit après un clic garde sa position de défilement.
