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

## Épéiste : 60 techniques, 8 disciplines

| Discipline | Novice | Intermédiaire | Apprenti | Mage | Maître | Archimage | Interdit |
|---|---|---|---|---|---|---|---|
| **Taille** | Entaille | Tranche large, Fauchage | Moulinet | Tourbillon d'acier | Taille de lune | Fend-montagne | Coupe-monde |
| **Estoc** | Estoc rapide | Fente perçante | Coup droit | Iaidō | Mille estocs | Estoc céleste | Estoc de l'âme |
| **Danse** | Pas de danse | Valse des lames | Danse des lames, Pas du vent | Frénésie du duel | Ballet mortel | Danse éternelle | Danse de la mort |
| **Garde** | Parade | Contre-attaque | Garde haute | Riposte parfaite | Bastion de lames | Égide des lames | Lame inébranlable |
| **Spectres** | Lame volante | Duellistes | Rōnin spectral | Gardien d'acier, Vol de lames | Compagnie spectrale | Maître spectral | Légion des lames |
| **Tempête** | Lame-éclair | Taille-foudre | Tranche-tonnerre | Lame d'orage | Orage d'acier | Jugement de la lame | Lame divine |
| **Saignée** | Coupure | Saignée | Hémorragie | Lacérations | Saignée écarlate | Pluie de sang | Fleuve de sang |
| **Acier** | Pluie de dagues, Jeté de lame | Dagues obliques | Lames orbitales | Pluie d'épées | Épées dansantes | Tempête d'acier | Mille ciels |

Les sorts de l'arbre (Fente, Tranche-orage, Lames miroirs) restent à part. Ils se débloquent par l'arbre de l'Épéiste.

**Mécaniques ajoutées pour l'Épéiste :**
- **Saignement** (`bleed`) : 3,5 % des PV (plafonnés) par seconde, en dégâts physiques. Les ennemis qui saignent clignotent en rouge.
- **Renfort** : il gagne le vol de vie (`steal`) et la riposte (`thorns`), qui renvoie une part des coups reçus.
- Un renfort peut aussi accompagner un bouclier ou un soin de Barrière (Garde haute, Bastion de lames, Égide, Lame inébranlable).
- **Lames spectrales** :
  - Épée volante (20 s) ;
  - Danseuse de lames ;
  - Rōnin spectral ;
  - Gardien d'acier (tank) ;
  - Maître spectral (vol de vie).
- **Nouveaux sprites d'animation** : katana, rapière, dague, pétale.

## Clerc : 60 techniques, 8 disciplines

| Discipline | Novice | Intermédiaire | Apprenti | Mage | Maître | Archimage | Interdit |
|---|---|---|---|---|---|---|---|
| **Soins** | Soin léger | Prière fervente | Guérison, Renouveau | Source de vie | Résurgence | Résurrection | Martyre |
| **Châtiment** | Éclat sacré, Marque divine | Châtiment | Colère divine | Jugement | Courroux sacré | Épée de justice | Jugement dernier |
| **Bénédictions** | Bénédiction | Hymne | Grâce | Ferveur | Bénédiction suprême | Apothéose | Ascension |
| **Sanctuaires** | Cercle de lumière | Sanctuaire | Terre consacrée | Bastion sacré | Cathédrale de lumière | Sanctum | Jardin céleste |
| **Purification** | Aspersion | Eau bénite | Rite d'exorcisme | Purge sacrée | Bannissement | Grande purification | Anathème |
| **Anges** | Lueurs sacrées | Chérubins | Séraphin | Gardien de cristal, Anges gardiens | Chœur céleste | Archange | Ost céleste |
| **Rayons** | Rayon de l'aube | Chaîne de lumière, Lumière brûlante | Lance de lumière | Prisme | Rayon divin | Lance du soleil | Aube éternelle |
| **Égides** | Bouclier de la foi | Égide | Rempart de foi | Sceau de protection | Égide divine | Mur sacré | Rempart des dieux |

Les sorts de l'arbre (Prière, Lance solaire, Exorcisme) restent à part. Ils se débloquent par l'arbre du Clerc.

**Mécaniques ajoutées pour le Clerc :**
- **Soin de Barrière sur la durée** (`over`) : les PV reviennent peu à peu, sur n secondes (Prière fervente, Renouveau, Source de vie, Martyre).
- **Sanctuaires** : une zone peut soigner les invocations (`ally_heal`, une part de leurs PV par seconde) en plus de les protéger (`ally_shield`) et de brûler l'ennemi.
- **Purification** : elle a désormais sa propre animation (« pure ») quand elle purifie un portail ou la brume.
- **Anges** :
  - Lueur sacrée (20 s, à distance) ;
  - Chérubin (aura de soin) ;
  - Séraphin ;
  - Gardien de cristal (tank) ;
  - Archange (forte aura de soin).
- **Nouveaux sprites d'animation** : colombe, cloche, cierge, aile.

## Nécromancien : 60 techniques, 8 disciplines

| Discipline | Novice | Intermédiaire | Apprenti | Mage | Maître | Archimage | Interdit |
|---|---|---|---|---|---|---|---|
| **Os** | Éclat d'os, Pique d'os | Prison d'os | Lances d'os | Tempête d'os | Pluie d'os | Colonne vertébrale | Ossuaire infini |
| **Morts-vivants** | Relever les morts | Archers squelettes, Goules | Spectres | Golem d'os | Légion des morts | Liche | Abomination |
| **Maléfices** | Affaiblissement | Malédiction | Flétrissure | Sceau de faiblesse | Malédiction de mort | Malédiction éternelle | Condamnation |
| **Fléaux** | Contagion | Peste | Nuée de mouches | Pestilence | Grande peste | Pandémie | Fin des temps |
| **Âmes** | Siphon d'âme | Drain d'âme | Récolte d'âmes | Chaîne d'âmes | Moisson sanglante | Âmes damnées | Grande moisson |
| **Ténèbres** | Trait ténébreux | Vague d'ombre | Orbe de néant | Nova d'ombre | Abîme | Nuit éternelle | Néant absolu |
| **Sang** | Pacte de sang | Sang bouillant | Transfusion, Armure de sang | Rituel de sang | Calice de sang | Festin de sang | Océan de sang |
| **Nécropole** | Tombe ouverte | Cimetière | Terre des morts | Ossuaire, Chevalier de la mort | Nécropole | Royaume des morts | Jour des morts |

Les sorts de l'arbre (Horde, Malédiction de masse, Sacrifice d'âmes) restent à part. Ils se débloquent par l'arbre du Nécromancien.

**Mécaniques ajoutées pour le Nécromancien :**
- **Affaiblissement** (`weak`) : l'ennemi frappe 30 % moins fort (invocations et Barrière). Les ennemis affaiblis clignotent en violet.
- **Cimetières** (`spawn`, `spawn_every`) : une zone fait sortir une invocation à intervalle régulier (squelettes, archers squelettes, chevaliers de la mort).
- **Terre des morts** (`raise`) : tout ennemi tué dans la zone se relève en squelette.
- **Sacrifices** :
  - `heal_per` : chaque invocation sacrifiée soigne la Barrière (Transfusion, Grande moisson) ;
  - `surge_gain` : chaque sacrifice remplit aussi la Surge.
- **Immobilisation** (`stun`) sur une colonne (Colonne vertébrale).
- **Magie du sang** : même hors rang Interdit, certaines techniques se paient en PV de Barrière (Pacte, Sang bouillant, Rituel, Calice, Festin).
- **Morts-vivants** :
  - Archer squelette ;
  - Goule (vol de vie) ;
  - Spectre ;
  - Golem d'os ;
  - Chevalier de la mort ;
  - Liche (à distance) ;
  - Abomination.
- **Nouveaux sprites d'animation** : cercueil, mouche, fiole, griffe.

## Chevalier : 60 techniques, 8 disciplines

| Discipline | Novice | Intermédiaire | Apprenti | Mage | Maître | Archimage | Interdit |
|---|---|---|---|---|---|---|---|
| **Boucliers** | Pavois | Mur de boucliers | Bastion | Égide du croisé | Citadelle | Rempart inviolable | Dernier bastion |
| **Charges** | Coup de bouclier | Charge de cavalerie | Charge lourde | Charge brisante | Charge héroïque | Galop de fer | Charge des damnés |
| **Étendards** | Fanion | Étendard de guerre | Bannière sacrée | Étendard royal | Oriflamme | Étendard de la victoire | Étendard noir |
| **Forteresse** | Palissade | Herse | Rempart, Rangée de pieux | Muraille | Donjon | Forteresse | Citadelle éternelle |
| **Ordre** | Écuyers | Arbalétriers | Cavalier | Paladin, Phalange | Compagnie de croisés | Ost royal | Roi déchu |
| **Justice** | Frappe juste, Lance bénie | Marteau sacré | Lame de justice | Châtiment du croisé | Marteau du ciel | Croisade | Ire du croisé |
| **Défi** | Provocation | Défi, Ruée | Cri de défi | Provocation de masse | Ultimatum | Duel royal | Défi à la mort |
| **Serments** | Serment de vaillance | Serment de protection | Serment de fer | Serment d'honneur | Serment éternel | Serment du roi | Serment de sang |

Les sorts de l'arbre (Bouclier levé, Charge, Cercle runique) restent à part. Ils se débloquent par l'arbre du Chevalier.

**Mécaniques ajoutées pour le Chevalier :**
- **Étendards** (`ally_atk`) : tant qu'elles restent près de la bannière, les invocations frappent plus fort. Une bannière peut aussi soigner, protéger, ou brûler l'ennemi (Oriflamme).
- **Murs du grimoire** :
  - palissade, herse, rempart, muraille, donjon, forteresse ;
  - ils ont leur propre animation (`wall`) ;
  - un mur peut aussi porter un renfort (Citadelle éternelle).
- **Provocations** : des zones qui attirent les ennemis vers le point visé (`pull`), avec marque et affaiblissement.
- **Étourdissement** (`stun`) sur les marteaux.
- **L'Ordre** :
  - Écuyer ;
  - Arbalétrier (à distance) ;
  - Cavalier (rapide) ;
  - Paladin (aura de soin) ;
  - Roi déchu.
- **Nouveaux sprites d'animation** : bannière, heaume, marteau, cheval.

## Berserker : 60 techniques, 8 disciplines

| Discipline | Novice | Intermédiaire | Apprenti | Mage | Maître | Archimage | Interdit |
|---|---|---|---|---|---|---|---|
| **Haches** | Hache lancée, Double hache | Haches jumelles | Tempête de haches | Hache du bourreau | Pluie de haches | Tourbillon de haches | Hache du jugement |
| **Fureur** | Rage | Colère | Frénésie sanglante, Rage aveugle | Furie | Folie guerrière | Rage du berserker | Fureur absolue |
| **Assauts** | Bond | Charge furieuse, Coup de boutoir | Bond du titan | Assaut brutal | Saut météore | Chute du titan | Saut de l'apocalypse |
| **Cris de guerre** | Cri de guerre | Hurlement de terreur | Intimidation | Cri des ancêtres | Rugissement | Cri du berserker | Hurlement du néant |
| **Totems** | Totem de rage | Totem de sang | Cercle de totems | Totems de guerre | Totem ancestral | Cercle des ancêtres | Totem du sang noir |
| **Carnage** | Morsure sanglante | Soif de sang | Festin du loup | Carnage | Buveur de sang | Bain de sang | Massacre |
| **Clan** | Pillards | Loups de guerre | Géant du clan | Horde barbare, Esprit de l'ours | Chef de guerre | Géants du clan | Titan de sang |
| **Séismes** | Piétinement | Secousse | Onde de choc | Tremblement | Fracture | Séisme du titan | Fin du monde |

Les sorts de l'arbre (Tourbillon, Bond furieux, Hurlement, Rage primordiale) restent à part. Ils se débloquent par l'arbre du Berserker.

**Mécaniques ajoutées pour le Berserker :**
- **Totems** :
  - zones où les invocations frappent plus fort (`ally_atk`) et plus vite (`ally_aspd`), parfois soignées ;
  - totems de guerre : invocations immobiles avec une aura de soin (20 à 25 s).
- **Fureur** : la frénésie de toutes les invocations (`frenzy`) a désormais un prix (selon sa durée). Elle peut porter un renfort en plus (Folie guerrière, Rage du berserker, Fureur absolue).
- **Séismes du grimoire** (`quake`) : ils ont leur propre animation, sur toute la largeur de l'arène.
- **Carnage** : le sang versé soigne la Barrière (`barrier_heal` sur les coups).
- **Le clan** :
  - Pillard ;
  - Loup de guerre ;
  - Géant ;
  - Totem de guerre ;
  - Esprit de l'ours ;
  - Chef de guerre ;
  - Titan de sang (tous avec vol de vie).
- **Nouveaux sprites d'animation** : totem, poing.

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

## Équilibrage (simulateur, IA aux commandes)

### Archer

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

### Épéiste

| Niveau | Deck | Victoires | Durée | Barrière |
|---|---|---|---|---|
| 1-5 | Novice et Intermédiaire : Entaille, Estoc rapide, Coupure, Lame volante, Jeté de lame, Tranche large, Dagues obliques | 3/3 | 116 s | 50 % |
| 2-10 (Gharok) | Apprenti et Mage : Moulinet, Coup droit, Danse des lames, Hémorragie, Iaidō, Pluie d'épées, Lame d'orage | 3/3 | 268 s | 54 % |
| 2-10 (Gharok) | Deck de base (élémentaire) | 3/3 | 234 s | 48 % |
| 4-6 | Maître et Archimage : Taille de lune, Mille estocs, Compagnie spectrale, Orage d'acier, Épées dansantes, Jugement de la lame, Tempête d'acier | 3/3 | 104 s | 97 % |

L'IA vide son mana dans les premiers sorts du deck : à Gharok, Pluie d'épées et Lame d'orage ne partent presque jamais.

Réglages en cours de route :
- boucliers de Parade, Garde haute et Égide réduits pour leur rang ;
- Rōnin spectral : 140 PV et 26 d'attaque.

### Clerc

| Niveau | Deck | Victoires | Durée | Barrière |
|---|---|---|---|---|
| 1-5 | Novice et Intermédiaire : Éclat sacré, Marque divine, Cercle de lumière, Lueurs sacrées, Châtiment, Chérubins, Hymne | 3/3 | 96 s | 63 % |
| 2-10 (Gharok) | Apprenti et Mage : Colère divine, Séraphin, Terre consacrée, Guérison, Jugement, Ferveur, Prisme | 3/3 | 191 s | 93 % |
| 2-10 (Gharok) | Deck de base (élémentaire) | 3/3 | 245 s | 81 % |
| 4-6 | Maître et Archimage : Courroux sacré, Cathédrale, Chœur céleste, Rayon divin, Bénédiction suprême, Épée de justice, Lance du soleil | 3/3 | 151 s | 98 % |

Le Clerc garde la Barrière au plus haut, mais avance plus lentement : contre le Givre de la zone 4, sa Lumière ne bénéficie d'aucun avantage d'élément.

Réglages en cours de route :
- valeur des sanctuaires (soins et boucliers d'invocations) revue à la baisse ;
- Jardin céleste et Sanctum moins forts ;
- rayons d'Anathème et de la Grande purification réduits.

### Nécromancien

| Niveau | Deck | Victoires | Durée | Barrière |
|---|---|---|---|---|
| 1-5 | Novice et Intermédiaire : Éclat d'os, Relever les morts, Affaiblissement, Contagion, Pique d'os, Cimetière, Malédiction | 3/3 | 93 s | 57 % |
| 2-10 (Gharok) | Apprenti et Mage : Lances d'os, Récolte d'âmes, Terre des morts, Tempête d'os, Golem d'os, Nova d'ombre, Ossuaire | 3/3 | 273 s | 55 % (3 étoiles) |
| 2-10 (Gharok) | Deck de base (élémentaire) | 3/3 | 273 s | 40 % (1,7 étoile) |
| 4-6 | Maître et Archimage : Pluie d'os, Légion des morts, Malédiction de mort, Grande peste, Abîme, Nécropole, Nuit éternelle | 3/3 | 113 s | 97 % |

Réglages en cours de route :
- cimetières et Terre des morts réévalués (prix selon le nombre de morts relevés) ;
- Liche renforcée (360 PV, 70 d'attaque) ;
- 3 spectres et 4 archers squelettes au lieu de 2 et 3 ;
- Jour des morts : un chevalier toutes les 3 s pendant 12 s.

Le sacrifice (Récolte, Transfusion, Moisson) se vise sur ses propres invocations : l'IA, le smoke test et `cast_all.gd` le lancent là où elles se trouvent.

### Chevalier

| Niveau | Deck | Victoires | Durée | Barrière |
|---|---|---|---|---|
| 1-5 | Novice et Intermédiaire : Coup de bouclier, Fanion, Écuyers, Frappe juste, Lance bénie, Charge de cavalerie, Arbalétriers | 3/3 | 94 s | 81 % |
| 2-10 (Gharok) | Apprenti et Mage : Charge lourde, Bannière sacrée, Cavalier, Lame de justice, Châtiment du croisé, Paladin, Serment d'honneur | 3/3 | 257 s | 90 % |
| 2-10 (Gharok) | Deck de base (élémentaire) | 3/3 | 277 s | 89 % |
| 4-6 | Maître et Archimage, sorts de dégâts en tête : Croisade, Galop de fer, Marteau du ciel, Charge héroïque, Compagnie de croisés, Oriflamme, Serment éternel | 3/3 | 128 s | 99 % |
| 4-6 | Les mêmes sorts, Charge héroïque en tête | 2/3 | 223 s | 66 % |
| 4-6 | Deck de base (élémentaire) | 2/3 | 169 s | 66 % |

L'ordre du deck compte pour l'IA, qui dépense son mana dans les premiers sorts prêts.

Réglages en cours de route :
- Palissade réduite ;
- Cavalier seul, et un peu moins fort ;
- Ost royal avec un seul paladin ;
- Oriflamme et Étendard noir brûlent moins ;
- épées de la Croisade moins fortes ;
- Dernier bastion : +140.

### Berserker

| Niveau | Deck | Victoires | Durée | Barrière |
|---|---|---|---|---|
| 1-5 | Novice et Intermédiaire : Hache lancée, Bond, Cri de guerre, Totem de rage, Pillards, Haches jumelles, Charge furieuse | 3/3 | 98 s | 57 % |
| 2-10 (Gharok) | Apprenti et Mage : Tempête de haches, Bond du titan, Cercle de totems, Hache du bourreau, Carnage, Horde barbare, Tremblement | 3/3 | 231 s | 47 % |
| 2-10 (Gharok) | Deck de base (élémentaire) | 3/3 | 251 s | 49 % |
| 4-6 | Maître et Archimage : Pluie de haches, Saut météore, Chef de guerre, Fracture, Chute du titan, Tourbillon de haches, Folie guerrière | 3/3 | 87 s | 99 % |

Réglages en cours de route :
- Géant du clan : 280 PV et 28 d'attaque ;
- le Totem du sang noir brûle moins.

## Bilan

Les six classes non mages ont chacune leur grimoire : 6 × 60 = 360 techniques, chacune avec son icône et sa propre animation. Avec les 56 sorts élémentaires (le grimoire du Mage, ouvert à tous), cela fait 416 sorts à acheter à la Bibliothèque.
