# Grimoires de classe (étape 13.5)

> Suite de [`25-classes.md`](25-classes.md) et de [`18-rangs-des-sorts.md`](18-rangs-des-sorts.md).
>
> Code :
> - `Profile.class_grimoire`, `disciplines`, `grimoire_of`, `learned` ;
> - `LibraryScreen._grimoire_sections` ;
> - `BattleSim._strike`, `_rally`, `_single_target` ;
> - `BattleTerrain._place_traps`, `_spring_trap` ;
> - `SpellRecipe` (`scripts/battle/spell_recipe.gd`).
>
> Données :
> - `data/spells.json` (`grimoire`, `disc`, `rank`, `vfx`, `svg`) ;
> - `data/party.json` (`disciplines`) ;
> - `data/units.json` (bêtes).

## Principe

Chaque classe a son propre grimoire : une soixantaine de techniques, du rang Novice au rang Interdit, comme les écoles élémentaires.

| Règle | Détail |
|---|---|
| **Achat** | À la Bibliothèque, onglet **Classes**, puis **Grimoire**. Le prix est en or, selon la puissance de la technique, comme pour les sorts élémentaires. Une technique Interdite coûte aussi 10 de Corruption, et sa magie se paie en Barrière au lancer. |
| **Voie requise** | Une technique ne s'apprend et ne sert qu'en suivant sa voie. Après un changement de voie (Salle de méditation), elle reste apprise : elle revient quand on reprend cette voie. |
| **Mage** | Son grimoire, ce sont les 7 écoles élémentaires (56 sorts). Elles restent ouvertes à toutes les voies. |
| **Deck** | Il compte 7 sorts au plus, et mêle librement grimoire de classe et écoles élémentaires. |
| **Tiroir** | Le bouton **⇄ ARCHER** fait passer les 8 cases des écoles aux 8 **disciplines** de la classe ; **⇄ ÉCOLES** revient aux écoles. Chaque discipline compte 8 techniques au plus, une par case. |
| **Répartition** | 9 techniques par rang de Novice à Mage, puis 8 par rang de Maître à Interdit : 60 en tout. |

## Archer : 60 techniques, 8 disciplines

| Discipline | Novice | Intermédiaire | Apprenti | Mage | Maître | Archimage | Interdit |
|---|---|---|---|---|---|---|---|
| **Tir** | Flèche vive, Ricochet | Flèche lourde | Transpercer | Tir mortel | Baliste | Flèche-comète | Tir de l'âme |
| **Volées** | Salve | Averse de flèches | Pluie barbelée | Déluge de flèches | Tempête de flèches | Ciel obscurci | Pluie de fer |
| **Pièges** | Collet | Chausse-trappes | Filet, Piège à épines | Mine à éclats | Champ de mines | Fosse aux pieux | Jardin de lames |
| **Traque** | Marque du chasseur | Cor de chasse, Pistage | Œil d'aigle | Proie désignée | Chasse sauvage | Curée | Marque de mort |
| **Bêtes** | Appel du faucon | Meute | Ours brun | Harde de cerfs, Instinct du prédateur | Roi des loups | Esprit de la forêt | Bête du Néant |
| **Poisons** | Flèche d'ortie | Nuage de spores | Flèche de venin | Brume toxique | Peste verte | Fleur de mort | Peste noire |
| **Éléments** | Flèche ardente | Flèche de givre | Flèche d'orage | Flèche à braises | Flèches trinité | Flèche boréale | Flèche du chaos |
| **Astral** | Trait d'aube | Étoile filante | Bénédiction lunaire | Ceinture d'Orion | Nova stellaire | Arc de lune | Chute de l'astre |

Les sorts de l'arbre (Tir de précision, Volée de flèches, Constellation) restent à part. Ils se débloquent par l'arbre de l'Archer.

## Nouvelles mécaniques

Ces mécaniques servent à tous les grimoires de classe.

**Paramètres des coups** (zone, colonne, ricochet, barrage, piège) :

| Paramètre | Effet |
|---|---|
| `single` | Tir unique : seule la plus grosse cible de la zone est touchée (boss, élite, brute). |
| `mark` | Marque la cible pendant n s : elle subit +15 % de dégâts (Clés de la Traque en plus). |
| `chill` | Ajoute n cumuls de ralentissement. |
| `knock` | Recul. Les boss, têtes, bannières et runes n'y sont pas sensibles. |
| `execute` | Dégâts en plus sur une cible sous 35 % de ses PV. |
| `big_game` | Dégâts en plus contre les élites et les boss. |
| `crit_add` | Chance de critique en plus. |
| `status` | Statuts élémentaires en plus. |

Une colonne ou un ricochet du grimoire applique aussi le statut de son élément : Feu, Givre, Nature ou Ombre.

**Nouveaux types et options :**

| Type ou option | Effet |
|---|---|
| **Renfort** (`rally`) | Les invocations gagnent, pendant n s : dégâts (`atk`), cadence (`aspd`), critique (`crit`), bouclier (`shield`) ou soin (`heal`). L'effet touche toutes les invocations, ou celles d'un rayon. Un sort de zone peut aussi porter un renfort (Curée, Marque de mort). |
| **Pièges** (`ground_kind: "piege"`) | Ils se posent à 1 ou plusieurs exemplaires (`count`, `spread`), 6 au plus sur le terrain. Le premier ennemi qui passe déclenche une explosion (`blast`, `blast_r`), avec les effets de la technique : entrave (`root`), marque, givre, recul, poison. |
| **Bêtes** (`army`) | Faucon, Loup gris, Ours brun, Roi des loups, Esprit de la forêt (aura de soin), Bête du Néant, Baliste (tourelle immobile qui tire à 4,6 m). `kinds` mêle plusieurs espèces, et `life` limite la durée de vie : faucons 25 s, baliste 40 s. |
| **Barrages** | `multi_elem` donne à chaque impact son propre élément (Flèches trinité, du chaos). `line` aligne les impacts (Ceinture d'Orion). |
| **Zones** | `damage` porte un premier coup (Fleur de mort). |

## Animations et icônes

Chaque technique décrit son animation dans `spells.json` (« vfx »), en couches assemblées par `SpellRecipe` à partir des briques de SpellSig. Les briques sont celles de l'étape 13.3c : sprites, glyphes, tracés, particules.

**Clés de la recette, par phase :**

| Clé | Phase |
|---|---|
| `shot` | Projectile : sprite, échelle, cloche, depuis le lanceur, le ciel ou en biais, rotation, traînée, orbe. |
| `cast` | Lancement. |
| `hit` | Impact, onde, renfort, soin. |
| `trap` | Piège déclenché. |
| `set` | Piège posé. |
| `col` | Colonne. |
| `chain` | Ricochet. |
| `zone` | Zone durable. |
| `pop` | Chaque bête qui surgit. |

**Couches** (`genre:arg`) :
- Pluie, chute ou jaillissement de sprites, orbite, éclats projetés, chute ondoyante.
- Silhouettes qui traversent la zone (cerfs, loups), empreintes.
- Glyphes : mire, œil, toile, étoile, mâchoires.
- Filet, croissant de lune, rayon épais, anneaux, sauts de cible en cible.
- Brume, braises, neige, spores.

**Nouveaux éléments graphiques :**
- 11 sprites : empreinte, cor, œil, lune, chausse-trappe, mâchoires, cerf, loup, flamme, goutte, faucon ;
- la texture de sol des pièges, teintée à la couleur de la technique ;
- 7 sprites de bêtes (6 recoloriages et la Baliste).

**Icônes.** Chaque technique a son icône au trait (« svg »). Elle combine une forme principale et un petit emblème.

**Garanties du smoke test :**
- 60 techniques, la répartition par rang et 8 disciplines ;
- 8 techniques au plus par discipline ;
- recettes toutes différentes, sans couche ni sprite inconnus ;
- icônes lisibles ;
- achat réservé à la voie ;
- chaque technique se lance en combat.

## Équilibrage (simulateur, IA aux commandes, classe Archer)

Commande : `tools/sim_cli.gd -- --level=X --runs=3 --class=archer --deck=a,b,…`. Pour lancer chaque technique une fois : `tools/cast_all.gd -- --class=archer`.

| Niveau | Deck | Victoires | Durée | Barrière |
|---|---|---|---|---|
| 1-5 | Novice et Intermédiaire : Flèche vive, Salve, Collet, Marque, Meute, Flèche ardente, Averse | 3/3 | 68 s | 62 % |
| 2-10 (Gharok) | Apprenti et Mage : Transpercer, Pluie barbelée, Piège à épines, Tir mortel, Déluge, Harde, Cor de chasse | 3/3 | 172 s | 54 % |
| 2-10 (Gharok) | Deck de base (élémentaire) | 3/3 | 220 s | 38 % |
| 4-6 | Maître et Archimage : Baliste, Tempête de flèches, Champ de mines, Chasse sauvage, Roi des loups, Ciel obscurci, Flèche boréale | 3/3 | 118 s | 95 % |
| 4-6 | Deck de base (élémentaire) | 3/3 | 105 s | 98 % |
| 4-6 | Maître et Archimage élémentaires (Comète, Tempête, Champ statique, Séisme, Jugement céleste, Pluie de météores, Nova) | 3/3 | 93 s | 95 % |

Les ennemis de la zone 4 sont de Givre : la Foudre élémentaire (×1,5) y garde l'avantage sur les flèches physiques.

Réglages en cours de route :
- valeur des invocations comptée selon leurs PV, leurs dégâts par seconde et leur aura (une élite compte double) ;
- Baliste, Esprit de la forêt et Bête du Néant renforcés pour leur rang ;
- l'IA lance un renfort dès que 8 invocations sont au contact (au lieu de dépendre de la menace sur la Barrière).

## Suite

Les grimoires des 5 autres classes suivent, une classe à la fois : Épéiste, Clerc, Nécromancien, Chevalier, Berserker. Chacun aura environ 60 techniques en 8 disciplines.
