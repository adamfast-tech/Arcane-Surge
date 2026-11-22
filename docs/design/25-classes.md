# Classes jouables (étape 13.3a)

> Ébauche : [`04-classes-races.md`](04-classes-races.md) §1 et §3.2. Données : `data/party.json` (`familiar`, `player_familiar`, `champion`, `ultimate`, `effect_mult`, `playable`), `data/units.json`, `data/spells.json`, `data/skill_trees/<classe>.json`. Code : `BattleSim._setup_casters` (classe du héros via `player_class`), `_class_on_hit`, `_wrath`, `_charge_line`, types de sorts `army` et `frenzy`, `SpriteAtlas._draw_weapon`.

Les 7 classes se choisissent à la création du personnage. Le grimoire (Bibliothèque, Deck ou Tiroir) est commun à toutes les classes. La classe change :
- l'invocation du Flux ;
- le Champion ;
- l'Ultime ;
- les statistiques de base ;
- l'arme du héros sur son sprite ;
- l'arbre de compétences, gardé séparément pour chaque classe.

## Invocations, Champions, Ultimes

| Classe | Invocation (Flux) | Champion | Ultime |
|---|---|---|---|
| Mage | Familier arcanique | Golem | **Météore arcanique** : impact de Feu, rayon 3, 220 dégâts |
| Archer | Archer (à distance) | Rôdeur géant (à distance, 4,2 m) | **Pluie d'étoiles** : 16 étoiles de Lumière, 95 dégâts chacune |
| Épéiste | Duelliste spectral (rapide) | Maître-lame (frappe toutes les 0,4 s) | **Mille lames** : 20 lames, 120 dégâts chacune, sur une zone de 3 m |
| Clerc | Acolyte de lumière (aura de soin 0,6 PV/s) | Gardien de lumière (aura 4 PV/s) | **Jugement solaire** : rayon 3,2, 200 dégâts de Lumière, Barrière +30 |
| Nécromancien | Squelette | Colosse d'os | **Armée des morts** : 240 dégâts d'Ombre, puis 20 squelettes surgissent |
| Chevalier | Templier (Lumière, DÉF 4) | Paladin colosse (240 PV, DÉF 30) | **Rempart sacré** : onde de 260 dégâts qui repousse ; Barrière +60 de bouclier ; bouclier sur les invocations |
| Berserker | Enragé (vol de vie 10 %) | Seigneur de guerre (vol de vie 15 %) | **Déchaînement** : choc de 300 dégâts, puis frénésie de 8 s pour toutes les invocations |

Notes sur les Ultimes et les compagnons :
- **Frénésie** : +40 % de dégâts et 10 % de vol de vie.
- **Flux des compagnons** : Brann et Krag gardent leur invocation habituelle. Le Chevalier et le Berserker joués par le héros ont donc la leur : le Templier et l'Enragé.
- **Hydre** : toute Ultime laisse une zone de 6 s qui cautérise les moignons de l'Hydre, comme les braises du Météore.
- **Ondes et charges** : elles ne déplacent ni les têtes de l'Hydre ni les bannières.

## Arbres (2 branches par classe, 22 nœuds)

La structure est celle du Mage :
- palier 0 : 2 passifs ;
- palier 5 : 2 passifs et 1 sort ;
- palier 10 : 3 passifs ;
- palier 20 : 1 passif de 3 rangs et 1 évolution ;
- palier 30 : 1 Clé de voûte.

Deux Clés de voûte au plus. La 3ᵉ branche, la Voie du Surge, viendra à l'étape 13.3b.

| Classe | Branche | Sort (palier 5) | Évolution (palier 20) | Clé de voûte (palier 30) |
|---|---|---|---|---|
| Archer | Tireur d'élite | Tir de précision | Pluie d'étoiles+ | **Œil du faucon** : Champion +25 % de critique, critiques ×2,5, +20 % de portée |
| | Pisteur | Volée de flèches | Rôdeur aguerri | **Maître de la traque** : une proie marquée explose en épines (poison) et marque ses voisins |
| Épéiste | Duelliste | Fente | Maître-lame aguerri | **Danse parfaite** : chaque critique d'invocation retire 0,2 s aux recharges (1 s/s au plus) |
| | Lame-tempête | Tranche-orage | Mille lames+ | **Orage d'acier** : chaque lame de l'Ultime lance une chaîne de foudre |
| Clerc | Sanctification | Prière (+25 Barrière) | Gardien éternel | **Miracle** : une fois par partie, la Barrière tombée remonte à 50 % (2 s d'invulnérabilité) |
| | Jugement | Lance solaire | Jugement solaire+ | **Courroux céleste** : les soins en excès frappent les ennemis proches de la Barrière |
| Nécromancien | Ossuaire | Horde (7 squelettes) | Armée des morts+ | **Légion** : tous les 20 squelettes, un Colosse d'os se lève |
| | Malédictions | Malédiction de masse | Colosse maudit | **Pandémie** : un ennemi flétri propage Flétrissure et poison à sa mort |
| Chevalier | Rempart | Bouclier levé | Paladin aguerri | **Inébranlable** : la Barrière perd 5 PV au plus par coup |
| | Croisé | Charge | Rempart sacré+ | **Avant-garde** : le Champion charge sa colonne à l'apparition (3× son attaque, recul) |
| Berserker | Carnage | Tourbillon | Déchaînement+ | **Soif** : le vol de vie soigne la Barrière (1 % des dégâts, 2 PV/s au plus) |
| | Totem | Hurlement (frénésie 4 s) | Seigneur aguerri | **Chef de clan** : compagnons +30 % d'attaque et de PV |

Nouveaux effets d'arbre (clés de `mods`) :
- **Invocations :** `cadence`, `lifesteal`, `riposte`, `aura_heal`.
- **Marque :** `hunt_mark` (chance de marquer : +15 % de dégâts subis, 4 s), `mark_vuln`.
- **Poison :** `poison_dmg`.
- **Squelettes :** `skeleton_chance`, `army_count`.
- **Sorts :** `chain_bonus`.
- **Champion :** `champ_atk`.
- **Barrière :** `barrier_max`.
- **Compagnons :** `bot_atk`.
- **Frénésie :** `frenzy_dur`.
- **Ultime :** `ult_count`, `ult_dur`.
- **Clés de voûte :** `hawk_eye`, `thorn_burst`, `perfect_dance`, `ult_chain`, `miracle`, `wrath`, `legion`, `pandemic`, `barrier_cap`, `vanguard`, `thirst`, `clan_chief`.

Les sorts d'arbre sans rang (`tree_class`) n'apparaissent à la Bibliothèque que pour leur classe, ou une fois connus.

## Équilibrage (simulateur, IA aux commandes, sans arbre)

Commande : `tools/sim_cli.gd -- --level=X --runs=N --class=<classe>`.

| Niveau | Mage | Archer | Épéiste | Clerc | Nécro | Chevalier | Berserker |
|---|---|---|---|---|---|---|---|
| 1-5 | 6/6 · 108 s | 6/6 · 70 s | 6/6 · 105 s | 6/6 · 94 s | 6/6 · 98 s | 6/6 · 96 s | 6/6 · 98 s |
| 1-10 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 |
| 2-10 (Gharok) | 3/4 | 4/4 | 3/4 | 4/4 | 4/4 | 4/4 | 4/4 |
| 3-10 (Hydre, Brann et Sylwen) | 6/6 · 376 s | 6/6 · 587 s | 6/6 · 569 s | 6/6 · 543 s | 3/6 · 610 s | 2/3 · 700 s | 5/6 · 572 s |

- L'Hydre et les créatures du marais sont de Nature : le Météore de Feu (×1,5) y reste la meilleure Ultime.
- Le Chevalier avec Brann manque de dégâts. Avec Krag, il passe à 3/3 en 406 s ; le Cercle le conseille.
