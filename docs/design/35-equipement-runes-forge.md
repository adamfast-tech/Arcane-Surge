# Équipement, runes et Forge (étape 13.8)

> Conception d'origine : [`05-equipement-craft.md`](05-equipement-craft.md) (raretés, runes I à V, transmutation). Données : `data/items.json` (`bases`, `rarities`, `runes`, `fusion`) et `data/progression.json` (`rune_drops`).

## 1. Catalogue

- **260 objets** : 7 panoplies de zone de 36 pièces chacune, plus 8 uniques (dont l'Œuf de cendre, acte 6, et le Trident des Archives, acte 7) :
  - Bâton de la Première Sève, Croc de Gharok, Enclume-Cœur, Couronne de l'Énigme (choix et exploits de l'histoire) ;
  - Hache du Serment Brisé et Fiole des Trois Venins : légendaires de boss. Une chance sur huit à chaque victoire contre Gharok (2-10) ou l'Hydre (3-10), multipliée par la difficulté, une seule fois (`boss_unique` dans progression.json).
- Chaque zone a son butin (`loot_pool`), couvrant tous les emplacements : 8 armes, 4 mains secondaires, 4 têtes, 4 armures, 4 gants, 4 bottes, 2 médaillons, 4 anneaux, 2 charmes.
- La deuxième vague de 90 pièces (étape 13.9) ajoute 16 types :
  - armes : rapière, fléau, glaive, cimeterre ;
  - mains secondaires : cor, crâne ;
  - têtes : chapeau pointu, bandeau ou turban ;
  - armures : brigandine ;
  - gants : brassards ;
  - médaillons : collier, talisman ;
  - charmes : totem, osselets, clochette, œil.

| Zone | Panoplie | Exemples |
|---|---|---|
| 1 Bois des Lucioles | Bois, cuir, lucioles | Arc d'if, Rapière de ronce, Fléau du berger, Cor de chasse, Chapeau d'herboriste, Totem de hibou |
| 2 Collines d'Ambre | Steppe, ambre, orcs | Hache des steppes, Glaive de la milice, Fléau d'orage (Foudre), Crâne de loup, Brigandine cloutée, Osselets du clan |
| 3 Marais Murmurants | Cendres, os, Aube | Faux des Cendres (Ombre), Rapière de l'Aube (Lumière), Crâne de liche, Chapeau de sorcière, Masque à bec, Œil de brume |
| 4 Pics Gelés | Nains, givre, runes | Marteau runique, Glaive de givre (Givre), Arbalète naine, Cor des montagnes, Couronne runique, Clochette de glace |
| 5 Désert de Verre | Soleil, verre, Collège | Cimeterre des dunes (Feu), Glaive solaire, Crâne de cristal, Chapeau d'érudit, Turban de nomade, Œil du sphinx |
| 7 Cité Engloutie | Corail, perles, tridents | Trident des abysses, Harpon du chasseur de Léviathan, Conque des marées, Couronne de perles, Dent de Léviathan (étape 17.1) |
| 6 Forêt Cendrée | Dragons, braise, écailles | Épée en écailles de drake, Marteau de magma, Faux du phénix, Crâne de drake, Heaume à cornes de drake, Plume de phénix (étape 16.1) |

Les objets des sauvegardes existantes gardent leurs stats : seule leur icône change.

## 2. Visuels

- Chaque base porte un visuel `art` :
  - `t` : le type, parmi 60 (rapière, fléau, glaive, cimeterre, cor, crâne, chapeau, bandeau, brigandine, brassards, collier, talisman, totem, dé, cloche, œil, et bâton, baguette, sceptre, masse, arc, arbalète, épée, dague, faux, hache, marteau, lance, orbe, bouclier, carquois, tome, lanterne, miroir, capuche, couronne, heaume, masque, coiffe némès, robe, tunique, mailles, cuirasse, manteau, gants, gantelets, bandes, bottes, sandales, grèves, médaillon, pendentif, anneau, chevalière, fiole, plume, croc, cristal, sablier, enclume) ;
  - `m` : la matière (bois, bois sombre, bois-lune, fer, acier, or, bronze, cuivre, argent, os, cristal, givre, obsidienne, cuir, fourrure, pierre, braise, écailles, corail, perle) ;
  - `c` : la teinte (tissu, cuir, ruban) ;
  - `g` : la gemme.
- `ItemArt` dessine l'icône en pixel-art coloré (24×24, ombrée, contour), agrandie au plus proche voisin. La rareté se lit au cadre.
- Les runes sont des galets d'ardoise gravés du glyphe de leur famille, avec des points de niveau.
- `tools/item_sheet.gd` produit la planche de toutes les icônes.

## 3. Raretés

| Rareté | Budget | Affixes | Emplacements de runes | Amélioration max |
|---|---|---|---|---|
| Commun | ×1 | 0 | 1 | +5 |
| Rare | ×1,25 | 1 | 1 | +10 |
| Épique | ×1,55 | 2 | 2 | +15 |
| Légendaire | ×1,9 | 3 | 3 | +20 |
| **Mythique** | ×2,3 | 4 | 4 | +25 |

La rareté Mythique ne s'obtient que par fusion de 3 légendaires.

## 4. Runes

**Familles** (16) :

| Famille | Thème | Famille | Thème |
|---|---|---|---|
| Kaor | Puissance | Thun | Foudre |
| Vigr | Vigueur | Ver | Nature |
| Ilm | Esprit | Lux | Lumière |
| Sael | Célérité | Nox | Ombre |
| Wyrd | Destin | Ark | Arcane |
| Pyr | Feu | Ferr | Physique |
| Isa | Givre | Mor | Vie |
| | | Gard | Garde |
| | | Mult | Multiplicité |

**Puissance d'une rune.**
- Elle dépend du niveau (I à V : 1, 2, 3,5, 5,5, 8) et de la rareté (×1 à ×1,9).
- Exemple : Pyr III épique = 5,4, soit Sorts de Feu +8,1 % sur une arme.

**Effet selon l'objet** (`runes.categories`) :
- arme : arme et main secondaire ;
- armure : tête, armure, gants, bottes ;
- bijou : médaillon, anneaux ;
- charme.

| Rune | Arme | Armure | Bijou | Charme |
|---|---|---|---|---|
| Kaor | Attaque des invocations | +POU | Dégâts des sorts | Attaque du Champion |
| Vigr | PV des invocations | PV de Barrière | +VIG | PV du Champion |
| Ilm | Dégâts des sorts | Régénération de mana | +ESP | Mana par ennemi abattu |
| Sael | Cadence du Flux | Vitesse des invocations | Recharge des sorts | +CÉL |
| Wyrd | Critique | Esquive des invocations | Chance de butin plus rare | +DES |
| Pyr, Isa, Thun, Ver, Lux, Nox | Sorts de l'élément | Résistance à l'élément | Brûlure, gel, cadence, poison, soins ennemis −, vol de vie | Invocations de l'élément : dégâts |
| Ark | Sorts d'Arcane | Régénération de la Barrière | Dégâts de l'Ultime | Rayon de l'Ultime |
| Ferr | Techniques physiques | Résistance physique | Riposte des invocations | Invocations physiques : dégâts |
| Mor | Vol de vie | Régénération des invocations | Soins | Auras de soin |
| Gard | Bouclier des invocations | Défense des invocations | Bouclier de Barrière au départ | Dégâts subis par la Barrière − |
| Mult | Invocation en double | Portails Nombre +1 | Gain de Surge | Chance de butin plus rare |

**Où s'appliquent les effets.**
- Les runes de stats s'ajoutent aux stats de l'objet ; elles valent aussi pour les compagnons.
- Les effets spéciaux passent par les modificateurs du héros (`Profile.rune_mods_of`, ajoutés à `all_mods`) ; ceux de l'équipement des compagnons ne s'appliquent pas.

**Nouveaux modificateurs de la simulation :**
- `spell_dmg` ;
- `resist.<élément>` ;
- `unit_elem.<élément>` ;
- `unit_speed`, `cd_red`, `dodge`, `start_shield`, `portal_plus`, `free_clone`.

`luck` ne vit que dans le butin de `Profile.apply_battle`.

**Obtention.**
- Chaque étoile donne 40 % de chance d'une rune, multipliée par la difficulté. Un boss en garantit une.
- Le niveau dépend de la zone : I (zone 1), I–II, II, II–III, III (zone 5). Le niveau V ne s'obtient que par fusion.
- La rareté suit la table de la zone, avec la chance de la Difficulté et de la rune Wyrd ou Mult.
- Les nouvelles sauvegardes, et les sauvegardes d'avant les runes, reçoivent Kaor I, Ilm I et Pyr I.

## 5. La Forge

On y accède par une nouvelle salle d'Havre-Aube, par le bouton « Forge » de l'Équipement, ou par le bouton « Runes » de chaque objet. Elle a trois onglets.

**Présentation** (`scripts/ui/forge_screen.gd`, tuiles communes dans `scripts/ui/gear_ui.gd`) :
- titre « LA FORGE de Durgan Enclume », bourse (or, poussière) ;
- un bandeau de Durgan (portrait, nom, bulle) commente l'atelier, ce qui est choisi et le résultat de chaque action ;
- trois grands onglets à icône, avec un sous-titre (« Runes sur un objet », « 3 objets en 1 meilleur », « Réserve, fusion, recyclage ») ;
- les objets et les runes sont des tuiles carrées : cadre à la couleur de la rareté, lueur, icône, pastille « +N » ou niveau en chiffres romains, emplacements de runes.

### GRAVURE
- Choisir un objet dans la grille (objets portés, puis réserve). Il est posé sur **l'enclume** : l'objet en grand, ses stats, et ses emplacements de runes en grand (gravés ou libres).
- Toucher une rune de la besace affiche sa fiche : son effet sur cette catégorie d'objet, ce qui l'empêche, le prix, et « Graver ». Les emplacements libres s'allument : les toucher grave aussi.
- Toucher une rune gravée affiche son effet et « Retirer ».
- Graver coûte 25 or × niveau × valeur de rareté de la rune.
- Retirer une rune coûte 15 or × niveau ; elle revient en réserve.

### FUSION (d'objets)
- Un cercle rituel accueille les 3 objets choisis dans la grille de réserve, et montre le résultat (modèle du premier, rareté au-dessus, niveau d'objet, emplacements). Les objets d'une autre rareté que la sélection sont grisés.
- 3 objets de même rareté donnent 1 objet de la rareté au-dessus (3 légendaires → Mythique).
- Le premier objet choisi donne son modèle. Le niveau d'objet est le plus haut des trois. Les affixes sont tirés à nouveau.
- Le résultat est marqué **« Issu d'une fusion »**. Il peut refusionner avec d'autres objets de même rareté (fusionnés ou non) pour monter encore d'une rareté.
- Les objets équipés et les uniques ne fusionnent pas.
- Les runes gravées sur les objets fusionnés reviennent en réserve.
- Coût : 120 / 360 / 900 / 2 400 or selon la rareté, +3 % par niveau d'objet.

### RUNES
- La réserve en grille. Toucher des runes les place dans la barre de fusion (3 places) ; la dernière touchée a sa fiche : ses 4 effets et « Recycler ».
- Fusion de 3 runes identiques (famille, niveau, rareté) : niveau +1, jusqu'à V. Coût : 40 or × niveau.
- Recyclage : 2 × niveau × valeur de rareté en Poussière d'arcane.

### Écrans touchés
- **Équipement** (« ARMURERIE », `scripts/ui/equipment_screen.gd`) :
  - onglets du porteur (toi, chaque compagnon) avec son sprite ;
  - **poupée** : le personnage sur un socle à la couleur de son élément, entouré de ses 10 emplacements (arme, tête, armure, mains, pieds à gauche ; main secondaire, amulette, 2 anneaux, charme à droite), sa Puissance, son niveau et son élément ; une flèche verte sur un emplacement signale un meilleur objet en réserve ;
  - les 5 stats en cases colorées ;
  - **fiche** de l'emplacement ou de l'objet touché : grande icône, rareté, niveau d'objet, jauge d'amélioration, stats, runes et leurs effets ; pour un objet porté : Améliorer (sans le retirer), Runes, Retirer ; pour un objet de réserve : comparaison avec l'équipé, Équiper, Améliorer, Recycler ;
  - **réserve** : filtres par emplacement (avec le nombre), grille de tuiles, les meilleurs d'abord ;
  - mention « Issu d'une fusion ».
- **Comparaison avec l'équipé** (`Profile.compare_to_equipped`, `better_items`) :
  - chaque objet de réserve est comparé à celui que porte le personnage affiché (toi ou un compagnon) au même emplacement ; pour les anneaux, au plus faible des deux ;
  - le score d'un objet est la somme de ses stats (améliorations, affixes et runes de stats compris), et l'écart est donné en Puissance ;
  - un objet meilleur a un cadre vert et un bandeau « Mieux que l'équipé · Puissance +N », ou « Emplacement libre » si rien n'est porté à cet endroit ;
  - ces objets passent en tête de l'inventaire, le plus gros gain d'abord ;
  - sous les stats de chaque objet, l'écart avec l'objet porté s'affiche stat par stat, en vert ou en rouge ;
  - sur une pièce équipée, le bouton « N mieux » filtre l'inventaire sur cet emplacement ; les emplacements vides affichent aussi leur nombre ;
  - la tuile Équipement d'Havre-Aube indique « N objets mieux en réserve » ;
  - quand les deux anneaux sont portés, équiper un anneau remplace le plus faible.
- **Fin de combat** : les runes gagnées apparaissent dans le butin, sur leur faisceau de rareté. Le bouton « Équipement » (à côté de Rejouer, Carte et Havre-Aube) ouvre directement l'équipement ; il passe au vert avec une flèche quand un objet de réserve fait mieux que l'équipé.
- **Aperçus** : `?room=forge`, `&tab=fusion` ou `&tab=runes`, `&gear=1` (un assortiment d'objets et de runes).

## 6. Vérifications

`tools/ui_smoke.gd` (`_gear_ok`) contrôle :
- les 260 icônes (36 par zone) et les 16 runes, avec leurs 4 effets ;
- la Fiole des Trois Venins, tombée une seule fois en 60 victoires contre l'Hydre ;
- Pyr gravée sur l'arme (Sorts de Feu en combat) ;
- Kaor sur un heaume (POU) ;
- l'emplacement plein, et le retrait ;
- la fusion de runes (refus d'un mélange) ;
- la fusion d'objets : modèle, niveau d'objet, marque « fusion », un objet fusionné qui refusionne, mélange refusé, objet équipé refusé, Mythique à 4 emplacements ;
- les runes au butin d'un boss ;
- le bouclier de départ et les résistances en combat ;
- les trois onglets de la Forge.
