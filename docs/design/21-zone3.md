# Zone 3 · Marais Murmurants (étape 12.1)

> Suite de [`16-zone2.md`](16-zone2.md) et de [`19-terrain-interactif.md`](19-terrain-interactif.md). Narration de l'acte 3 (les Cendres, Nyx, le Cercle des Cendres) : étape 12.2.

## Niveaux (niveaux globaux 21 à 30)

| N° | Nom | Type | Point clé |
|---|---|---|---|
| 3-1 | Les Pilotis | Assaut | Zombies et rats ; 1 banc de brume, portail de Lumière |
| 3-2 | Les Mares | Assaut | 4 mares de poison |
| 3-3 | La Brume | Assaut | 2 bancs de brume, Sorcières des brumes |
| 3-4 | Le Gué des Morts | Assaut | Squelettes à pavois, Abominations de vase |
| 3-5 | Le Crocodile-liche | Mini-boss | Charges, souffle de venin, morts relevés |
| 3-6 | Le Cercle de Saules | Assaut | Adeptes renégats, brume, mare |
| 3-7 | La Barque des passeurs | Escorte | Barque (2 400 PV), embuscades de rats, brume |
| 3-8 | La Sorcière des brumes | Purification | 2 sceaux, Sorcières, brume |
| 3-9 | L'Adepte renégat | Siège | 2 Nexus, tour, mares |
| 3-10 | L'Hydre des brumes | Boss | Têtes qui repoussent, venin, inondation de poison |

Les portails élémentaires de la zone sont de Feu (efficace contre la Nature) et de Lumière (efficace contre l'Ombre ; dissipe la brume).

## Bestiaire

| Unité | Rôle | Particularité |
|---|---|---|
| Zombie des tourbières | sbire | Ombre |
| Rat de peste | coureur | **Laisse une mare de poison en mourant** |
| Abomination de vase | brute | Grosse mare de poison en mourant |
| Crapaud cracheur | tireur | À distance |
| Squelette à pavois | bouclier | Bloque de face |
| Adepte renégat | lanceur | Sorts d'Ombre |
| Sorcière des brumes | soigneuse | Soigne le Nexus et les unités |
| **Crocodile-liche** | mini-boss | Charges, venin, renforts, brume |
| **Hydre des brumes** | boss | Têtes, venin, inondation, brume |
| Tête de l'Hydre | tête | Mord à 2,2 m ; protège le corps |
| Barque des passeurs | escorte | À faire traverser |

## Mécaniques de zone

- **Brume.**
  - Les bancs de brume (rayon ~2 m) dérivent sur la largeur de l'arène.
  - Les ennemis qui s'y cachent sont assombris, sans barre de vie, et **subissent 20 % de dégâts en moins**.
  - Les invocations de **Lumière** (portail de Lumière) dissipent la brume qu'elles traversent. **Purifier** la dissipe d'un coup.
  - Un banc dissipé se reforme lentement.
  - 4 bancs au plus : au-delà, le plus clair se reforme ailleurs.
  - Réglage par niveau : `fog` = `{count, r, speed, y_min, y_max}`.
- **Mares de poison** (sol `poison` du terrain interactif).
  - Elles ralentissent de 30 % les **invocations alliées** et les empoisonnent ; les bêtes du marais y sont immunisées.
  - Feu dessus → **Explosion toxique** : dégâts aux ennemis proches, la mare disparaît.
  - Givre dessus → **Gel** : la mare devient du verglas, qui ralentit les ennemis.
  - Purifier les assainit.
  - Origine : posées par le niveau (`pools`, permanentes), par la mort des Rats et des Abominations, par le venin et l'inondation des boss.
- **Hydre des brumes.**
  - Tant qu'au moins une tête vit, son corps ne subit que 25 % des dégâts.
  - Une tête tranchée laisse une **plaie** (cercle orange). Il faut la **brûler dans les 5 s** pour la cautériser : sort de Feu, sol de braises, ou invocation de Feu au contact. Sinon, **deux têtes repoussent** (6 au plus).
  - Phases :
    - P1 : charges, brume, zombies ;
    - P2 : nouvelles têtes, souffle de venin (couloirs qui laissent des mares) ;
    - P3 : nouvelles têtes, inondation de poison sur toute l'arène.
- Nouveaux types de capacités de boss :
  - `heads` (`xs`, `y`) ;
  - `fog` (`count`) ;
  - `venom` (comme `lane_strike`, plus des mares) ;
  - `flood` (`count`, `dur`).

## Décor

- Crépuscule violet pâle : lune voilée, saules en silhouette, maisons sur pilotis et lanternes, eau sombre.
- Herbe vert-gris, pierre gris violacé (`WorldArt.zone = 3`, recoloriage `_swamp`).
- Lumière mauve, brume basse épaisse et feux follets verdâtres.

## Récompenses

- Rareté plus haute qu'en zone 2 ; boss : 50 % rare, 50 % épique.
- Matériaux : Mousse de tourbière (1–3), Écaille de liche (0–2).

## Équilibrage (IA au niveau du lieu, 2 à 3 combats par niveau)

| Niveau | Victoires | Durée | Barrière |
|---|---|---|---|
| 3-1 | 2/2 | 99 s | 99 % |
| 3-2 | 2/2 | 140 s | 90 % |
| 3-3 | 2/2 | 200 s | 100 % |
| 3-4 | 2/2 | 139 s | 99 % |
| 3-5 | 2/2 | 129 s | 62 % |
| 3-6 | 2/2 | 186 s | 99 % |
| 3-7 | 2/2 | 125 s | 92 % |
| 3-8 | 2/2 | 145 s | 96 % |
| 3-9 | 2/2 | 159 s | 100 % |
| 3-10 | 3/3 | 443 s | 42 % |

Réglages après les premiers essais :
- dégâts des mares divisés par 3 ;
- dissimulation de la brume réduite de 30 % à 20 % ;
- Hydre : rayon réduit pour que les invocations convergent sur elle ; PV 36 000.
