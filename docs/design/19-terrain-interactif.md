# Terrain interactif et destruction de l'arène

> Suite de [`18-rangs-des-sorts.md`](18-rangs-des-sorts.md). Code :
> - simulation : `scripts/battle/terrain.gd` (`BattleTerrain`) ;
> - rendu : `scripts/battle/terrain_view.gd` (`TerrainView`) et `SpellFx` (séisme, vapeur, poussière) ;
> - textures : `FxArt.ground`.

Les sorts marquent l'arène et la transforment. Ce qu'ils laissent derrière eux change la suite du combat : sols, cratères, piliers effondrés, murs.

## Sols

| Sol | Laissé par | Effet sur les ennemis | Durée |
|---|---|---|---|
| Braises | Zones d'impact de Feu, Terre brûlée | Brûlure continue, chaque seconde | 4 à 8 s ; laisse une brûlure noire jusqu'à la fin du combat |
| Verglas | Zones de Givre, Pluie de givre, Blizzard, Banquise | Ralentit de 35 %, **conduit la foudre** | 6 à 10 s |
| Eau | Marais | Ralentit de 25 %, **conduit la foudre** | 9 à 10 s |
| Miasme | Zones d'Ombre, Miasme | **+30 % de dégâts subis** | 5 à 8 s |
| Champ statique | Champ statique | Foudroie 3 ennemis toutes les 0,8 s, **conduit la foudre** | 7 s |
| Rune piège | Rune piège (3 au plus) | Explose au passage du premier ennemi | 25 s |
| Cratère | Gros impacts (≥ 100 dégâts avec chute : Comète, Éclipse, Soleil noir, Déchirure, Météore), Cataclysme | Ralentit de 20 % | Tout le combat (14 au plus) |
| Gravats | Éboulement, pilier effondré, mur détruit | Ralentit de 30 % | 10 à 25 s |
| Fissure | Séisme, Cataclysme | Ralentit de 25 % | 12 s |
| Faille | Faille tellurique (sur toute la colonne) | Blesse et ralentit de 50 % | 8 s |

Les sols automatiques ne viennent que des sorts du joueur, pour ne pas encombrer l'arène. Un même sol posé au même endroit est ravivé au lieu d'être empilé.

## Réactions entre éléments

| Réaction | Déclencheur | Effet |
|---|---|---|
| **Vapeur** | Feu sur du verglas ou de l'eau, ou Givre sur des braises | Explosion de vapeur (50 % des dégâts du sort) ; les deux sols s'annulent |
| **Gel** | Givre sur de l'eau | L'eau devient verglas ; les ennemis qui s'y trouvent gèlent 1,5 s |
| **Électrocution** | Foudre sur un sol conducteur (verglas, eau, champ statique) | Tous les ennemis du sol subissent 60 % des dégâts |
| **Incendie** | Feu sur une zone de Nature (Racines, Ronces, Étreinte de la forêt…) | La zone devient un brasier : dégâts doublés, braises |
| **Résonance** | Arcane sur un sol actif | 40 % des dégâts à tous les ennemis du sol, sol prolongé de 2 s |

Chaque réaction s'affiche en combat (« VAPEUR ! », « ÉLECTROCUTION ! »…) et dans le journal.

## Piliers en ruine

- Les piliers qui bordent la chaussée ont des PV : 40 + 30 × hauteur, multipliés par la difficulté.
- Les sorts qui les touchent les ébrèchent.
- À 0 PV, le pilier bascule vers la chaussée : 0,5 s de chute, puis il **écrase les ennemis** sur toute sa longueur. Dégâts : (60 + 50 × hauteur) × difficulté, plus 1 s d'étourdissement.
- Il laisse des gravats, et reste couché en travers de la route.
- Le Séisme renverse ceux de sa bande ; le Cataclysme les renverse tous.
- Viser un pilier au bon moment devient une tactique.

## Murs de pierre

- Mur de pierre fait surgir un mur de 2,6 m pendant 10 s.
- Ses PV valent 300 × difficulté × puissance du joueur.
- Les ennemis s'entassent devant et le frappent : c'est le moment d'une grosse zone ou d'un séisme.
- Les invocations alliées le traversent.
- Une barre de vie s'affiche au-dessus du mur.
- Quand il cède, il laisse des gravats.

## Nouveaux sorts (13)

| Sort | École | Rang | Effet | Prix |
|---|---|---|---|---|
| Jet de pierres | Terre | Novice | Petite zone | 40 or |
| Pic rocheux | Terre | Intermédiaire | Colonne de pics | 240 |
| Mur de pierre | Terre | Apprenti | Mur bloquant 10 s | 510 |
| Éboulement | Terre | Mage | 6 rochers, gravats | 590 |
| Séisme | Terre | Maître | Bande de 4 m : dégâts, étourdissement, fissures, piliers renversés | 590 |
| Faille tellurique | Terre | Archimage | Colonne puis faille de 8 s | 1 700 |
| Cataclysme | Terre | Interdit | Toute l'arène : 5 cratères, tous les piliers abattus, 25 points de Barrière | 6 000 |
| Terre brûlée | Feu | Mage | Braises 8 s | 560 |
| Banquise | Givre | Apprenti | Verglas 10 s | 350 |
| Champ statique | Foudre | Maître | Sol foudroyant 7 s | 690 |
| Marais | Nature | Apprenti | Eau 10 s | 200 |
| Miasme | Ombre | Mage | +30 % de dégâts subis, 8 s | 560 |
| Rune piège | Arcane | Mage | Rune qui explose au passage | 600 |

Le Grimoire compte désormais 7 écoles et 55 sorts élémentaires, plus Purifier.

Nouveaux types de sorts :
- `wall` (mur) ;
- `quake` (séisme : `band` est la demi-hauteur de la bande, plus `stun`, `cracks` et `craters`) ;
- `ground` (sol : `ground_kind`, plus `dps`, `zap`, `blast` et `blast_r`).

Un sort peut aussi laisser un sol avec le champ `ground` : `{kind, r, dur, dps, along}`.

## Aperçu web

`?level=z01_l03&deck=marais,javelot_foudre,banquise,boule_de_feu,mur_pierre,seisme,cataclysme&mana=1` : mana 20 fois plus rapide, pour tout essayer.
