# Zone 7 · Cité Engloutie (étape 17.1)

Suite de [`37-zone6.md`](37-zone6.md). La conception vient de [`06-monde.md`](06-monde.md) : zone 7, bestiaire, Léviathan, palette. La narration de l'acte 7 (les Archives du Temps, Ssareth, la révélation sur Morvaen) est l'étape 17.2.

## Niveaux (niveaux globaux 61 à 70)

| N° | Nom | Type | Point clé |
|---|---|---|---|
| 7-1 | Les Quais Engloutis | Assaut | Hommes-poissons et anguilles ; première marée |
| 7-2 | Le Grand Canal | Assaut | Deux courants latéraux qui s'inversent, Nagas archères |
| 7-3 | Les Marées Hautes | Assaut | Grande marée (plus haute, plus longue), Gardes de corail, Mages des marées |
| 7-4 | La Place des Statues | Assaut | Marée et courant ensemble, Crabes titans |
| 7-5 | Le Kraken juvénile | Mini-boss | Tentacules en couloirs, encre, tourbillons |
| 7-6 | La Cloche des Archivistes | Escorte | Cloche de plongée (22 000 PV), courant, embuscades d'anguilles |
| 7-7 | Le Chant des Sirènes | Assaut | 2 Sirènes qui soignent, marée |
| 7-8 | Les Archives Noyées | Purification | 2 sceaux, portail de Lumière mobile, Sirène, marée |
| 7-9 | Le Palais du Léviathan | Siège | 2 Nexus, tour, Horreurs des abysses, marée et courant |
| 7-10 | Le Léviathan | Boss | Vagues, tentacules, portails avalés, tourbillon central |

- Les ennemis sont de **Givre** et de **Foudre** : la **Foudre** bat le Givre, la **Nature** bat la Foudre. Les portails de la zone sont surtout de Foudre et de Nature.

## Bestiaire

| Unité | Rôle | Particularité |
|---|---|---|
| Homme-poisson | sbire | Givre, aquatique |
| Anguille-foudre | coureur | Foudre, très rapide, aquatique |
| Crabe titan | brute | Défense 24, bloque de face (40 %) |
| Naga archère | tireur | Foudre, à distance (3,6 m), aquatique |
| Garde de corail | bouclier | Givre, bloque de face (60 %) |
| Mage des marées | lanceur | Givre ; ses sorts engourdissent les invocations |
| Sirène | soigneuse | Soigne le Nexus et les unités, aquatique |
| Horreur des abysses | brute élite | 470 PV, défense 22, aquatique |
| **Kraken juvénile** | mini-boss | Foudre |
| **Léviathan** | boss | Foudre ; il craint la Nature |
| Cloche des Archivistes | escorte | À conduire jusqu'aux portes des Archives |

## Mécaniques de zone

**Marée** (`tide` : `{first, low, high, move, low_y, high_y}`).
- Le niveau de l'eau monte (« LA MARÉE MONTE ! ») de `low_y` à `high_y` en `move` secondes, reste haut `high` secondes, redescend, puis reste bas `low` secondes.
- Tout ce qui est sous le niveau de l'eau est sous l'eau. À marée haute, les portails du premier rang (y = 5) sont noyés : ils n'ont plus d'effet (`Portal.submerged`). L'IA les ignore.
- Dans l'eau, tes invocations avancent à 75 % de leur vitesse ; les créatures aquatiques (champ `aquatic`) à 120 %.
- Une nappe d'eau translucide couvre l'arène jusqu'au niveau de la marée ; le bandeau d'aide affiche la marée haute et son temps restant.

**Courants latéraux** (`currents` : `[{y, h, dir, speed, flip}]`).
- Une rangée qui emporte les unités (invocations comme ennemis) d'un côté ; elle s'inverse toutes les `flip` secondes (« LE COURANT S'INVERSE »).
- Rendus par des flèches qui défilent.

**Tourbillon** (capacité `whirlpool` : `{dur, r, center}`).
- Il aspire en spirale les invocations à moins de 1,8 rayon et blesse celles qui sont en son cœur (8 PV/s, comme le feu de la zone 6). Les ennemis l'ignorent.
- Le Kraken le creuse où se trouvent tes troupes ; le Léviathan, au centre de l'arène.

**Autres capacités.**
- `row_sweep` avec `wave` et `push` : **vague déferlante**, qui repousse les invocations de la rangée vers la Barrière.
- `lane_strike` avec `tentacle` : les **tentacules** saisissent un couloir (annonce violette).
- `swallow` : le Léviathan **avale un portail** (deux à marée haute) pendant `dur` secondes (`Portal.swallowed`).
- L'encre du Kraken reprend la brume de la zone 3 (capacité `fog`).

## Décor

- Recoloriage `_abyss` : algues turquoise semées de corail, pierre bleutée (`WorldArt.zone = 7`).
- Fond `_backdrop_abyss` : rayons de lumière venus de la surface, tours englouties, bancs de poissons, bulles, coraux.
- Arène : lumière bleue, brume marine, bulles qui montent ; annonces des vagues en bleu clair, des tentacules en violet ; tourbillons en spirale.
- Carte : ambiance « abyss », planche « cite » (la cité engloutie sous la lumière de la surface).
- 11 sprites : Kraken juvénile, Léviathan et Cloche des Archivistes dessinés pour la zone ; les autres reprennent des silhouettes recoloriées (gobelin, salamandre, scorpion, momie, garde de clan, adepte, prêtresse, abomination).

## Récompenses

- 30 % commun, 42 % rare, 23 % épique, 3 % légendaire (la table est normalisée) ; boss : 28 % rare, 64 % épique, 8 % légendaire.
- Runes de niveau IV.
- Matériaux : Perle abyssale (1–3), Corail noir (0–2).
- Panoplie de 36 objets (corail, perles, tridents, écailles de naga).

## Répliques

Le fichier `data/dialogues/fr/z07.json` contient les personnages et les répliques de combat de la cité, dont celles de 7-2, 7-3, 7-5, 7-7 et 7-10. Les scènes viendront avec la narration (17.2).

## Équilibrage (IA au niveau du lieu, Mage, Brann et Sylwen, 3 parties)

| Niveau | Victoires | Durée | Barrière |
|---|---|---|---|
| 7-1 | 3/3 | 191 s | 97 % |
| 7-2 | 3/3 | 113 s | 84 % |
| 7-3 | 2/3 | 193 s | 62 % |
| 7-4 | 3/3 | 141 s | 96 % |
| 7-5 | 2/3 | 164 s | 34 % |
| 7-6 | 2/3 | 114 s | 97 % |
| 7-7 | 3/3 | 120 s | 99 % |
| 7-8 | 3/3 | 148 s | 98 % |
| 7-9 | 2/3 | 204 s | 59 % |
| 7-10 | 2/4 | 227 s | 36 % |

Le Kraken a 34 000 PV, le Léviathan 30 000 (×0,8 en Normal).

## Vérifications

`tools/ui_smoke.gd` (`_zone7_ok`) contrôle :
- les 11 sprites, les 10 niveaux et la planche ;
- la marée : les portails du premier rang noyés à marée haute, puis rendus ;
- l'eau : invocation ralentie, homme-poisson accéléré, crabe inchangé ;
- le tourbillon : il attire et blesse les invocations, pas les ennemis ;
- le courant et son inversion ;
- la vague qui repousse, le portail avalé puis rendu, les tentacules.
