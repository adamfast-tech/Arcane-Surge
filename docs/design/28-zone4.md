# Zone 4 · Pics Gelés (étape 14.1)

Suite de [`21-zone3.md`](21-zone3.md). La conception vient de [`06-monde.md`](06-monde.md) : zone 4, bestiaire, Colosse runique, palette. Narration de l'acte 4 (les Runes, la forteresse Forgecœur, l'honneur du clan de Brann) : étape 14.2.

## Niveaux (niveaux globaux 31 à 40)

| N° | Nom | Type | Point clé |
|---|---|---|---|
| 4-1 | La Route du Col | Assaut | Gobelins et loups ; 2 plaques de glace, portail de Foudre |
| 4-2 | Les Congères | Assaut | Avalanches annoncées |
| 4-3 | La Porte naine | Assaut | Portail FORGE, Golems de glace |
| 4-4 | Le Lac gelé | Assaut | Grande étendue de glace, Yétis |
| 4-5 | La Sentinelle runique | Mini-boss | Marteau en couloirs ; bouclier runique (seule la Foudre, puis le Feu, la blesse) |
| 4-6 | L'Aurore | Assaut | Esprits d'aurore (soigneurs), Élémentaires de blizzard |
| 4-7 | Le Chariot runique | Escorte | Chariot (4 400 PV), embuscades de loups |
| 4-8 | Les Portes scellées | Purification | 2 sceaux, portail de Lumière mobile, Esprits d'aurore |
| 4-9 | La Forteresse | Siège | 2 Nexus, tour, lac gelé, Sentinelles anciennes |
| 4-10 | Le Colosse runique | Boss | Runes corporelles, rotation des runes, portes corrompues, avalanches |

Les ennemis sont de Givre : la **Foudre** les bat, le Feu y est faible (×0,75). Les portails de la zone sont surtout de Foudre, avec des Portes FORGE.

## Bestiaire

| Unité | Rôle | Particularité |
|---|---|---|
| Gobelin des glaces | sbire | Givre |
| Loup blanc | coureur | Très rapide |
| Yéti | brute | 260 PV, défense 12 |
| Kobold à stalactites | tireur | À distance (3,2 m) |
| Golem de glace | bouclier | Bloque de face (60 %) |
| Élémentaire de blizzard | lanceur | Ses éclats de givre engourdissent les invocations touchées (ralenties 1,2 s) |
| Esprit d'aurore | soigneur | Lumière ; soigne le Nexus et les unités (2 au plus) |
| Sentinelle ancienne | brute élite | Naine, 420 PV, défense 22, bloque de face (40 %) |
| **Sentinelle runique** | mini-boss | Marteau, invocations, bouclier runique |
| **Colosse runique** | boss | Foudre ; runes corporelles |
| Rune corporelle | rune | Flotte devant le Colosse, tire des arcs de son élément |
| Chariot runique | escorte | À conduire jusqu'à la forteresse |

## Mécaniques de zone

**Glace** (sol `glace` du terrain interactif).
- Les plaques sont permanentes et posées par le niveau (`ice` : `{x, y, r}`).
- Tout ce qui s'y trouve glisse, invocations comme ennemis : vitesse ×1,6, puis ×1,3 pendant l'élan (0,8 s après en être sorti).
- Le Feu la fait fondre : elle devient de l'eau pendant 12 s, puis regèle.
- La Foudre s'y propage (électrocution), comme sur le verglas.

**Avalanches** (`avalanche` : `{first, every, warn, band, dmg}`).
- Une rangée entière est annoncée en blanc bleuté, puis la neige dévale.
- Elle blesse les invocations **et les ennemis**, et ensevelit tout le monde 1 s (ralentissement ou immobilisation). Elle ne touche pas la Barrière.

**Portes naines FORGE** (portail `forge`) : l'invocation ressort cuirassée, avec +10 de défense et +25 % de PV.

**Colosse runique.**
- **Runes corporelles :** tant qu'une rune vit, son corps ne subit que 30 % des dégâts. Chaque rune ne craint qu'un élément : une invocation de cet élément (passée par le portail correspondant) fonce sur elle, les autres la traversent. Les sorts du bon élément la blessent aussi, et **une Ultime la brise quel que soit son élément**.
- **Phases :**
  - P1 : coups de poing (couloirs), runes Feu et Nature ;
  - P2 : 3 runes qui **tournent** d'élément toutes les 14 s ;
  - P3 : 3 nouvelles runes, et il **corrompt une Porte runique** (un portail positif devient ÷2 pendant 10 s), avec des avalanches.
- **Nouvelles capacités de boss :**
  - `runes` (`elements`, `xs`) ;
  - `rotate_runes` ;
  - `corrupt_gates` (`count`, `dur`) ;
  - `avalanche` (`band`, `dmg`) ;
  - `lane_strike` accepte désormais `barrier` (PV de Barrière par coup).

## Décor

- Nuit d'aurore boréale : rideaux verts, cyan et violets, sommets enneigés, forteresse naine aux runes cyan.
- Recoloriage `_frost` : neige bleutée, granit bleu glacier (`WorldArt.zone = 4`).
- Brume blanche, neige qui tombe et lumière froide.

## Récompenses

- Rareté plus haute qu'en zone 3 ; boss : 45 % rare, 55 % épique.
- Matériaux : Cristal de givre (1–3), Rune brisée (0–2).

## Équilibrage (IA au niveau du lieu, Mage, Brann et Sylwen)

| Niveau | Victoires | Durée | Barrière |
|---|---|---|---|
| 4-1 | 3/3 | 66 s | 98 % |
| 4-2 | 3/3 | 57 s | 93 % |
| 4-3 | 3/3 | 143 s | 98 % |
| 4-4 | 3/3 | 139 s | 99 % |
| 4-5 | 3/3 | 239 s | 44 % |
| 4-6 | 3/4 | 234 s | 63 % |
| 4-7 | 3/3 | 139 s | 96 % |
| 4-8 | 3/3 | 128 s | 95 % |
| 4-9 | 3/4 | 100 s | 74 % |
| 4-10 | 2/2 | 425 s | 54 % |

Colosse avec d'autres classes (2 parties chacune) :
- Épéiste : 1/2 ;
- Nécromancien : 1/2 ;
- Berserker : 1/2 ;
- Chevalier : 0/2. Il est lent : avec Brann, l'équipe manque de dégâts, comme contre l'Hydre.

Réglages en cours de route :
- vagues réduites d'environ 28 % ;
- soins des Esprits d'aurore réduits ;
- PV des runes : 900 → 360 ;
- coups du Colosse : 1,5 PV de Barrière au lieu de 3 ;
- rotation des runes : toutes les 14 s au lieu de 9.

**Correctif général.** Quand un soigneur atteint son plafond, la vague le remplace par l'unité la plus courante du niveau : ce n'est plus un champignon de la zone 1.
