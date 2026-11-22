# Étape 10.2 bis — Sorts du Mage et animations

> Suite de [`12-narration-zone1.md`](12-narration-zone1.md). Données : `data/spells.json` ; simulation : `scripts/battle/sim.gd` ; animations : `scripts/battle/spell_fx.gd` et `scripts/gfx/fx_art.gd`.

## 1. Les 7 sorts en combat

Le joueur dispose de **7 sorts** et de l'**Ultime**, sur deux rangées de quatre boutons en portrait (bordure à la couleur du sort, touches `1` à `7` sur ordinateur). Le menu Pause rappelle l'effet de chaque sort.

| Sort | Élément | Mana / recharge | Effet | Animation |
|---|---|---|---|---|
| **Boule de feu** | Feu | 30 / 6 s | Projectile (0,35 s) qui explose sur **2 m de rayon** (avant : 1,4 m) : 40 dégâts et brûlure | Boule de feu en arc avec traînée, éclair lumineux, gerbe d'étincelles, fumée, onde au sol, brûlure qui s'efface |
| **Pluie de givre** | Givre | 35 / 10 s | Zone de 2 m pendant **3 s** : 10 dégâts par seconde **en continu** ; chaque seconde, un cumul de givre (au 3e, l'ennemi gèle 1,5 s) | Pluie de traits glacés, éclaboussures, disque de givre au sol, cercle tournant |
| **Racines** | Nature | 30 / 12 s | Zone de 1,9 m pendant 4 s : **ralentit de 60 %** et inflige **de légers dégâts** (7 par seconde) | Racines épineuses qui sortent du sol puis se rétractent, feuilles, ennemis teintés de vert |
| **Éclair en chaîne** | Foudre | 30 / 7 s | Frappe l'ennemi le plus proche du point visé (2,5 m), puis rebondit sur 4 autres (45 dégâts, −20 % par rebond) | Éclair brisé et scintillant de cible en cible, éclats lumineux à chaque impact |
| **Vortex d'ombre** | Ombre | 40 / 14 s | Zone de 2,2 m pendant 3 s : **attire les ennemis** vers le centre, 10 dégâts par seconde (sans effet d'attraction sur les boss et les soigneurs fixes) | Disque sombre, trois bras en spirale qui tournent, particules aspirées |
| **Onde arcanique** | Arcane | 35 / 12 s | 20 dégâts sur 2,4 m et **recul** jusqu'à 2,2 m vers le fond de l'arène (sauf les boss et les soigneurs fixes) | Onde de choc à double front, mur de lumière, éclair et gerbe |
| **Purifier** | Lumière | 25 / 8 s | Purifie un portail maudit | Colonne de lumière sur le portail, étincelles qui montent |

Les dégâts sont multipliés par la Puissance du personnage (comme avant).

## 2. Pouvoirs

| Pouvoir | Animation |
|---|---|
| **Météore arcanique** (Ultime) | Le météore tombe du ciel en 0,8 s avec sa traînée violette ; à l'impact : grande explosion, double onde, éclair blanc et tremblement de l'écran |
| **Champion** | Colonne de lumière dorée et gerbe d'étincelles à l'apparition |
| **Bouclier levé** (Brann) | Étincelles cyan qui montent tout le long de la Barrière |
| **Tir de précision** (Sylwen) | Rayon et flèche lumineuse qui file dans la colonne |

## 3. Technique
- **Impacts différés** : `pending_impacts`. La Boule de feu et le Météore frappent quand le projectile arrive, l'animation et les dégâts sont synchronisés.
- **Zones** : `zones`. Dégâts continus, ralentissement (`zone_slow` sur l'unité), attraction, cumuls d'élément.
- **Animations** : particules, sprites pixel-art et lumières créés à la demande puis libérés ; foudre, spirales et ondes dessinées en traits.
- **IA des bots** et pilote automatique du simulateur : chaque nouveau type de sort a sa règle de ciblage (groupe le plus dense, soigneurs en priorité, ennemis près de la Barrière pour l'Onde et les Racines).

## 4. Calibrage après ce changement
Simulateur, 4 parties par niveau, personnage du niveau du lieu :

| Niveau | 1-1 | 1-2 | 1-3 | 1-4 | 1-5 | 1-6 | 1-7 | 1-8 | 1-9 | 1-10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Durée | 58 s | 58 s | 92 s | 104 s | 128 s | 96 s | 124 s | 143 s | 153 s | 229 s |
| Barrière | 97 % | 99 % | 98 % | 95 % | 42 % | 97 % | 94 % | 95 % | 97 % | 53 % |

Les durées restent proches du calibrage précédent : le mana limite toujours le nombre de sorts lancés.

> Suite : 42 sorts rangés en 7 rangs, voir [`18-rangs-des-sorts.md`](18-rangs-des-sorts.md).
