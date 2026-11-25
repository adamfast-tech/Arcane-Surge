# 42 — Tir normal de chaque classe

Le **Flux** (doigt posé sur l'arène, hors sorts) n'envoie plus le même familier pour tout le monde : chaque classe a son propre tir, avec sa cadence, son sprite et son animation. Code : [`scripts/battle/class_fire.gd`](../../scripts/battle/class_fire.gd) (simulation), [`scripts/battle/shot_fx.gd`](../../scripts/battle/shot_fx.gd) (gestes et impacts), `SpriteAtlas._gen_shot` (sprites), `Arena3D._put_shot` / `_shot_trails` (vol et traînées).

## Les sept tirs

Dégâts exprimés par rapport à un coup des troupes de la classe (son familier, avec la Puissance du lanceur). Les cadences sont celles d'un lanceur sans bonus : la Célérité, l'écho Flux torrentiel, la Brise et la vitesse d'attaque d'un Renfort les accélèrent.

| Classe | Toutes les | Tir | Effet | Repère visuel (couleur de classe) |
|---|---|---|---|---|
| Nécromancien | 0,3 s | 2 squelettes qui sortent de terre devant lui | 10 % plus grands, ×2 dégâts, ×2 PV ; immobiles le temps de se lever (0,45 s) | cercle de runes violet au sol, terre et os projetés, le squelette émerge du sol |
| Mage | 0,2 s | 3 lucioles d'un coup | mêmes stats que ses troupes | trois éclats cyan jaillissent du bâton et filent chacun à sa place |
| Archer | 0,5 s | flèche perçante | ×3 dégâts ; traverse 2 ennemis et s'arrête dans le 3ᵉ, sur toute la ligne visée | corde qui claque ; flèche à empennage vert, longue traînée verte ; étincelles à l'impact |
| Épéiste | 0,4 s | onde de coup d'épée | ×1,5 dégâts à **tous** les ennemis de l'arc (≈ 1,8 case de large) ; courte portée : s'éteint après 5,6 cases | arc balayé devant l'Épéiste ; croissant blanc-bleu et ses échos ; entailles en biais |
| Clerc | 0,6 s | orbe de lumière | file vers le groupe le plus proche devant elle ; au contact, un rayon tombe du ciel : ×1,5 dégâts dans un rayon de 0,95 case ; +0,4 Barrière par ennemi touché (1,6 au plus par rayon) | halo doré ; orbe-étoile flottante ; colonne de lumière, puis un éclat d'or qui rejoint la Barrière |
| Chevalier | 0,8 s | bouclier lancé | ×4 dégâts au premier ennemi de la ligne ; il recule de 0,45 case (ceux d'à côté de moitié, les élites de moitié, jamais les boss) et ralentit 1,2 s | bouclier bleu qui tournoie ; onde de choc et poussière à l'impact |
| Berserker | 0,15 s | 2 petites haches en éventail | ×0,7 dégâts, une cible chacune ; la cadence monte quand la Barrière baisse : ×1 pleine, ×2 à 25 % ou moins | haches qui tournoient, sillage d'étincelles rouges |

Le lanceur recule d'un cheveu à chaque tir, et la lueur de son arme prend la couleur de sa classe.

## Les tirs et les portails

Un tir est une unité alliée particulière (`Unit.shot`), qui **traverse les portails comme une invocation** :

- +N et ×N le dédoublent (le double garde sa course : mêmes ennemis déjà touchés, même portée restante) ;
- un portail d'élément le recolore (la flèche devient rouge après FEU) et ses coups appliquent l'élément ; la Lumière passe les portails négatifs et affaiblit les sceaux ;
- PUISSANCE ×1,5 dégâts, GÉANT élargit le tir (×1,3), HÂTE l'accélère ; -N l'absorbe, ÷N et CORRUPTION aussi, ENTRAVE le ralentit ;
- il compte pour les énigmes du Sphinx, touche les tours, le boss (même en vol) et le Nexus ;
- **l'onde de l'Épéiste repart** de plus belle (portée remise à 5,6 cases) en traversant un portail positif : sans portails, elle ne quitte jamais les abords du mur ; en les enfilant, elle atteint le Nexus.

Aucun ennemi ne peut viser ni blesser un tir (ni coups, ni zones, ni feu, ni tourbillons) ; il ne compte pas dans le plafond de 300 invocations.

## Les compagnons

Le tir de classe est celui du **héros**. Les compagnons gardent l'ancien Flux (leur familier, un toutes les 0,25 s) : leurs troupes tiennent le terrain pendant que les tirs frappent. S'ils tiraient eux aussi, il ne resterait plus d'armée pour retenir les ennemis (`ClassFire.COMPANIONS_FIRE`). Simulations (4 parties chacune) :

| Combat | Tout le monde tire | Compagnons avec leurs troupes |
|---|---|---|
| 4-5, Colosse runique | Mage, Nécro., Archer, Clerc, Chevalier 0/4 ; Épéiste, Berserker 3/4 | Nécro., Archer, Épéiste, Clerc 4/4 ; Mage 2/4 |
| 6-8 | Archer, Clerc, Chevalier 0/4 | voir le journal de l'étape |

## Le reste du combat

- **Champion** : sa charge monte au rythme de l'ancien Flux (4 par seconde de tir), quelle que soit la classe.
- **Renfort** (grimoires de classe) : les tirs lancés pendant sa durée en profitent (dégâts, critique, vol de vie ; sa vitesse d'attaque accélère la cadence du tir). Une classe qui tire peut toujours le lancer, même sans invocation sur le terrain.
- **Frénésie** du Berserker, Flèches astrales (un tir se divise en passant un portail), Rune Mult et Double fantôme (tir parfois doublé) s'appliquent aux tirs.
