# 42 — Tir normal de chaque classe

Le **Flux** (doigt posé sur l'arène, hors sorts) n'envoie plus le même familier pour tout le monde : chaque classe a son propre tir, avec sa cadence, son sprite et son animation. Code : [`scripts/battle/class_fire.gd`](../../scripts/battle/class_fire.gd) (simulation), [`scripts/battle/shot_fx.gd`](../../scripts/battle/shot_fx.gd) (gestes et impacts), `SpriteAtlas._gen_shot` (sprites), `Arena3D._put_shot` / `_shot_trails` (vol et traînées).

## Les sept tirs

Dégâts exprimés par rapport à un coup des troupes de la classe (son familier, avec la Puissance du lanceur). Les cadences sont celles d'un lanceur sans bonus : la Célérité, l'écho Flux torrentiel, la Brise et la vitesse d'attaque d'un Renfort les accélèrent.

| Classe | Toutes les | Tir | Effet | Repère visuel (couleur de classe) |
|---|---|---|---|---|
| Nécromancien | 1,2 s (jamais plus vite, bonus compris) | 2 squelettes qui sortent de terre devant lui | 10 % plus grands, ×2 dégâts, ×2 PV ; immobiles le temps de se lever (0,45 s) | cercle de runes violet au sol, terre et os projetés, le squelette émerge du sol |
| Mage | 1,2 s (jamais plus vite, bonus compris) | 3 lucioles | mêmes stats que ses troupes ; elles volent et dérivent chacune un peu | lucioles ailées à l'abdomen lumineux (jaune-vert, ou la couleur de leur élément) ; un éclat cyan jaillit du bâton vers chacune |
| Archer | 1,7 s | flèche perçante | ×3 dégâts ; traverse jusqu'à 8 ennemis sur toute la ligne visée | corde qui claque ; flèche à empennage vert, longue traînée verte ; étincelles à l'impact |
| Épéiste | 1,5 s | onde de coup d'épée | ×1,5 dégâts à **tous** les ennemis de l'arc (≈ 1,8 case de large), jusqu'au bout du terrain | arc balayé devant l'Épéiste ; croissant blanc-bleu et ses échos ; entailles en biais |
| Clerc | 0,6 s | orbe de lumière | file vers le groupe le plus proche devant elle ; au contact, un rayon tombe du ciel : ×1,5 dégâts dans un rayon de 0,95 case ; +0,4 Barrière par ennemi touché (1,6 au plus par rayon) | halo doré ; orbe-étoile flottante ; colonne de lumière, puis un éclat d'or qui rejoint la Barrière |
| Chevalier | 2 s | bouclier lancé | ×4 dégâts au premier ennemi de la ligne, puis une onde de choc : ×2 à tous les ennemis dans un rayon d'une case (4 ou 5 d'un groupe) ; ils reculent (0,45 case pour le premier, la moitié pour les autres et les élites, jamais les boss) et ralentissent | bouclier bleu qui tournoie ; double anneau de choc et poussière soulevée |
| Berserker | 2 s | 2 petites haches en éventail | ×0,7 dégâts, une cible chacune ; la cadence monte quand la Barrière baisse : ×1 pleine, ×2 à 25 % ou moins | haches qui tournoient, sillage d'étincelles rouges |

**Apparitions naturelles** : les squelettes et les lucioles d'une salve n'apparaissent jamais en rang. Chacun se pose un peu à côté de sa place (jusqu'à 0,42 case à gauche ou à droite, un peu devant ou derrière) et un peu après les autres (jusqu'à 0,22 s). Ensuite, chacun dérive légèrement de son côté.

Le premier appui tire aussitôt. Le tir se recharge aussi quand on ne tire pas.

Le lanceur recule d'un cheveu à chaque tir, et la lueur de son arme prend la couleur de sa classe.

## Les tirs et les portails

Un tir est une unité alliée particulière (`Unit.shot`), qui **traverse les portails comme une invocation** :

- +N et ×N le dédoublent (le double garde sa course : mêmes ennemis déjà touchés) ;
- un portail d'élément le recolore (la flèche devient rouge après FEU) et ses coups appliquent l'élément ; la Lumière passe les portails négatifs et affaiblit les sceaux ;
- PUISSANCE ×1,5 dégâts, GÉANT élargit le tir (×1,3), HÂTE l'accélère ; -N l'absorbe, ÷N et CORRUPTION aussi, ENTRAVE le ralentit ;
- il compte pour les énigmes du Sphinx, touche les tours, le boss (même en vol) et le Nexus ; en fin de course, il s'infléchit vers sa cible comme les troupes.

Aucun ennemi ne peut viser ni blesser un tir (ni coups, ni zones, ni feu, ni tourbillons) ; il ne compte pas dans le plafond de 300 invocations.

## Les compagnons

Le joueur choisit, **au Cercle**, pour chaque compagnon : **Troupes** (l'ancien Flux, un familier toutes les 0,25 s : elles tiennent le terrain, réglage par défaut) ou **Tir de classe** (le tir ci-dessus, propre à sa classe). Réglage enregistré dans `circle.<compagnon>.fire` (`troupes` ou `classe`).

Premières mesures, avec les anciennes cadences (4 parties par combat) : quand tout le monde tirait, il ne restait plus d'armée pour retenir les ennemis. Au boss 4-5, toutes les classes perdaient leurs 4 parties, sauf l'Épéiste et le Berserker (3 sur 4). Avec les troupes des compagnons, toutes gagnaient 4 fois sur 4, sauf le Mage (2 sur 4).

## Le reste du combat

- **Champion** : sa charge monte au rythme de l'ancien Flux (4 par seconde de tir), quelle que soit la classe.
- **Renfort** (grimoires de classe) : les tirs lancés pendant sa durée en profitent (dégâts, critique, vol de vie ; sa vitesse d'attaque accélère la cadence du tir). Une classe qui tire peut toujours le lancer, même sans invocation sur le terrain.
- **Frénésie** du Berserker, Flèches astrales (un tir se divise en passant un portail), Rune Mult et Double fantôme (tir parfois doublé) s'appliquent aux tirs.
