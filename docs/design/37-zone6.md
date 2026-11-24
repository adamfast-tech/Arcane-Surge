# Zone 6 · Forêt Cendrée (étape 16.1)

Suite de [`33-zone5.md`](33-zone5.md). La conception vient de [`06-monde.md`](06-monde.md) : zone 6, bestiaire, Wyrm de cendre, palette. La narration de l'acte 6 (Ignara, la trahison possible d'un compagnon) est l'étape 16.2.

## Niveaux (niveaux globaux 51 à 60)

| N° | Nom | Type | Point clé |
|---|---|---|---|
| 6-1 | La Lisière Cendrée | Assaut | Diablotins et salamandres ; premier incendie |
| 6-2 | Les Couloirs de Feu | Assaut | Deux incendies à la fois, Cultistes du Wyrm, Drakonides |
| 6-3 | L'Ombre des Ailes | Assaut | Passages de dragons, Wyverneaux |
| 6-4 | La Coulée de Magma | Assaut | 3 coulées de magma permanentes, Golems de magma |
| 6-5 | Le Drake ancien | Mini-boss | Souffle en couloirs, envol, mitraillage |
| 6-6 | Les Réfugiés de Braisemont | Escorte | Convoi (18 000 PV), embuscades de salamandres, incendie |
| 6-7 | Le Nid des Phénix | Assaut | 2 Phénix mineurs qui soignent le Nexus et renaissent, dragons |
| 6-8 | Les Autels du Wyrm | Purification | 2 sceaux, portail de Lumière mobile, phénix, incendie |
| 6-9 | La Citadelle draconide | Siège | 2 Nexus, tour, Démons des cendres, dragons |
| 6-10 | Le Wyrm de cendre | Boss | Souffle, envol et mitraillage, œufs en phase 3 |

- Presque tous les ennemis sont de **Feu** : le **Givre** les bat. Les portails de la zone sont surtout de Givre, avec un portail de Lumière contre les sceaux de 6-8.
- Le Givre sert aussi à éteindre le feu (voir plus bas).

## Bestiaire

| Unité | Rôle | Particularité |
|---|---|---|
| Diablotin de braise | sbire | Feu |
| Salamandre | coureur | Feu, très rapide |
| Drakonide cuirassé | bouclier | Bloque de face (60 %) |
| Wyverneau | tireur | Feu, à distance (3,5 m) |
| Golem de magma | brute | Feu ; laisse une flaque de feu en tombant (4 s, dégâts réduits de moitié) |
| Cultiste du Wyrm | lanceur | Feu ; sa boule de feu laisse un foyer (4 s) |
| Phénix mineur | soigneur | Soigne le Nexus et les unités ; **renaît** une fois à 50 % de PV, sauf si le Givre l'a frappé en dernier |
| Démon des cendres | brute élite | 460 PV, défense 22 ; flaque de feu en tombant |
| Œuf de wyrm | structure | Immobile, 170 PV ; éclot en 2 Wyverneaux après 10 s |
| **Drake ancien** | mini-boss | Feu |
| **Wyrm de cendre** | boss | Feu ; vol, œufs |
| Convoi de réfugiés | escorte | À conduire jusqu'au gué |

## Mécaniques de zone

**Incendies** (`wildfire` : `{first, every, max, width, speed, stop, life, dps}`).
- Un couloir de feu s'allume à la lisière ennemie (« LA FORÊT S'EMBRASE ! ») et descend vers la Barrière à `speed` m/s, jusqu'à `stop`. Il s'éteint de lui-même au bout de `life` secondes.
- La colonne choisie est loin des autres couloirs, plutôt là où passent les invocations.
- Le feu brûle les invocations (environ 1 s pour en brûler une ; l'escorte prend 40 %) et, à moitié, les ennemis qui ne sont pas de Feu. Les ennemis de Feu y sont chez eux.
- Le dégât ne suit pas le niveau des ennemis : il se règle sur les PV des invocations, et sur la difficulté choisie.
- Les runes de résistance au Feu (Pyr sur une armure) et `fire_resist` réduisent la brûlure.

**Le Givre éteint le feu** (`BattleSim.extinguish`, appelé par tout impact de Givre sur le terrain).
- Un foyer posé disparaît (« ÉTEINT ! », vapeur).
- Un couloir recule au-dessus du point d'impact et marque une pause de 4 s avant de repartir ; touché près de sa source, il s'éteint.
- Une coulée de magma refroidit et ne brûle plus pendant 6 s.

**Foyers** (`fires`, rendus en sol rougeoyant et en flammes) : laissés par les dragons, les Cultistes, les Golems de magma et les Démons, le souffle du Drake et du Wyrm. Les **coulées de magma** (`lava` : `[{x, y, r}]`) sont permanentes.

**Dragons** (`dragons` : `{first, every, warn, dmg, band, patches}`).
- Une ombre ailée annonce le passage (« UN DRAGON ! », rangée orange) sur la rangée où se trouvent le plus d'invocations.
- Le dragon mitraille la rangée (invocations seulement), puis y laisse `patches` foyers.
- Une silhouette de dragon traverse l'arène, son ombre glisse au sol.

**Envol des boss** (capacité `take_off` : `{dur}`).
- « EN VOL ! » : pendant `dur` secondes, seuls les tirs (unités à distance) et les sorts atteignent le boss.
- Les invocations au corps à corps qui l'atteignent l'attendent en dessous, sans se dissiper ; elles frappent quand il se pose (« se pose : frappe-le ! »). Elles sont alors une cible de choix pour le mitraillage.
- Le boss s'élève dans l'arène et flotte ; le bandeau d'aide affiche le temps de vol restant.

**Autres capacités.**
- `lane_strike` avec `fire` : le souffle laisse le couloir en flammes 7 s.
- `row_sweep` avec `dragon` : mitraillage d'une rangée, avec des foyers. `row_sweep` accepte désormais `barrier` (dégâts à la Barrière, 2 par défaut).
- `eggs` : le Wyrm pond 3 œufs devant lui (phase 3, puis toutes les 30 s).

**Unités.** Nouveaux champs : `fire_pool` (flaque à la mort), `ignite` (foyer du lanceur), `rebirth` (renaissance du phénix), `hatch` et `hatch_count` (œufs, rôle `oeuf`). Champs d'unité `airborne_t` et `reborn`.

**IA.**
- Les bots et le pilote automatique évitent les colonnes en feu.
- Ils éteignent au Givre le front de l'incendie le plus bas, ou un foyer où passent leurs invocations (`fire_target`).

## Décor

- Recoloriage `_cinder` : cendre grise semée de braises, basalte, feuillage calciné (`WorldArt.zone = 6`).
- Fond `_backdrop_ash` : ciel de fumée rougeoyant, volcan et sa coulée, dragons sur l'horizon, forêt calcinée en flammes.
- Arène : lumière rouge, brume de fumée, braises qui montent ; annonces des dragons et du souffle en orange.
- Carte : ambiance « cinder » (braises), planche « cendres » de StoryArt (forêt calcinée sous une lune rougie). Les onglets des zones passent sur deux rangées de 3.
- 12 sprites : Wyrm de cendre (dragon ailé dessiné pour la zone), Drake ancien (le même en écailles rouges), Wyverneau, Phénix mineur, Salamandre, Œuf de wyrm. Diablotin, Drakonide, Golem de magma, Cultiste, Démon des cendres et Convoi reprennent des silhouettes existantes, recoloriées.

## Récompenses

- Rareté plus haute qu'en zone 5 : 36 % commun, 42 % rare, 20 % épique, 2 % légendaire ; boss : 34 % rare, 60 % épique, 6 % légendaire.
- Runes de niveau III à IV.
- Matériaux : Écaille de cendre (1–3), Braise vive (0–2).
- Panoplie de 36 objets (dragons, braise, écailles), avec deux nouvelles matières d'icône : braise et écailles.

## Répliques

Le fichier `data/dialogues/fr/z06.json` contient les personnages et les répliques de combat de la forêt, dont celles de 6-2 à 6-7 et 6-10. Les scènes viendront avec la narration (16.2).

## Équilibrage (IA au niveau du lieu, Mage, Brann et Sylwen, 3 parties)

À niveau égal, l'écart de puissance avec les ennemis se creuse d'une zone à l'autre : les budgets de vagues et les PV des boss sont plus bas qu'en zone 5.

| Niveau | Victoires | Durée | Barrière | PV d'invocations brûlés |
|---|---|---|---|---|
| 6-1 | 3/3 | 114 s | 99 % | 1 600 |
| 6-2 | 3/3 | 155 s | 89 % | 9 900 |
| 6-3 | 3/3 | 122 s | 93 % | 1 300 |
| 6-4 | 3/3 | 186 s | 87 % | 14 100 |
| 6-5 | 2/3 | 235 s | 30 % | 7 700 |
| 6-6 | 3/3 | 109 s | 89 % | 5 900 |
| 6-7 | 3/3 | 109 s | 99 % | 6 600 |
| 6-8 | 2/3 | 247 s | 47 % | 5 100 |
| 6-9 | 2/3 | 168 s | 57 % | 10 000 |
| 6-10 | 2/3 | 245 s | 40 % | 6 100 |

Le Drake ancien a 23 000 PV, le Wyrm de cendre 30 000 (×0,8 en Normal) ; leurs souffles ne retirent qu'1 PV à la Barrière, leurs mitraillages 0,5.

## Vérifications

`tools/ui_smoke.gd` (`_zone6_ok`) contrôle :
- les 12 sprites, les 10 niveaux et la panoplie ;
- l'incendie : il avance, brûle une invocation, épargne un ennemi de Feu et blesse un Drakonide ; le Givre le fait reculer et éteint un foyer posé par un sort ;
- le dragon : annonce, puis 2 foyers ;
- le phénix : il renaît une fois, mais pas s'il est achevé au Givre ;
- la flaque du Golem de magma et l'éclosion d'un œuf (2 Wyverneaux) ;
- l'envol : une invocation attend sous le boss sans le blesser, un sort le blesse, il se pose et redevient vulnérable ; les 3 œufs du Wyrm.

Le simulateur affiche les PV d'invocations brûlés, par origine du feu, et les foyers éteints.
