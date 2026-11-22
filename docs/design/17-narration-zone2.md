# Acte 2 · Les Alliances (narration de la zone 2, étape 11.2)

> Suite de [`12-narration-zone1.md`](12-narration-zone1.md). Arbre des choix : [`07-narration.md`](07-narration.md) §2. Zone jouable : [`16-zone2.md`](16-zone2.md).

## Distribution

| Personnage | Rôle | Portrait |
|---|---|---|
| **Krag** | Jeune orc des Enfants de la Fureur, fils de Gharok. Guide bourru, il rejoint le groupe selon les choix | `krag` : chignon noir, peintures de guerre, crocs, cape de fourrure |
| **Gharok** | Seigneur de guerre de Croc-Tonnerre, possédé par le Surge | `gharok` : possédé (neutre, colère, surpris) avec des yeux magenta et des veines du Surge ; libéré (joie, triste) avec un regard ambre |
| **Maëlle** | Prévôte d'Ambreval, village humain. Méfiante envers les orcs depuis la mort de son mari | `prevote` : tresses rousses, tabard de l'Aube |
| **Varg** | Chef pillard humain qui vend de l'ambre chargé de Surge | `varg` : casque à cornes, balafre |
| Ourza | Rebouteuse du clan (2-8), sans portrait, ses paroles passent par le narrateur | — |

## Déroulé

| Niveau | Temps fort |
|---|---|
| 2-1 | Route d'Ambre. Krag, prisonnier des pillards, est libéré : « On se reverra dans les collines. » |
| 2-2 | Maëlle présente le vent des steppes. « Un orc reste un orc. » |
| 2-3 | Krag explique les pylônes ; son clan suit un chef aux yeux violets |
| 2-4 | Le gué ; Krag accuse Varg d'armer les possédés |
| 2-5 | Varg avoue : l'ambre va à Gharok, qui entend une voix dans l'orage. La Voix inconnue de l'acte 1 se manifeste |
| 2-6 | Les chamans de Krag sont libérés, pas tués. Krag : « Je m'en souviendrai. » |
| 2-7 | Le chariot arrive ; Maëlle retient le nom de Krag |
| 2-8 | Ourza : « Le Surge s'est logé dans son cœur, pas dans son âme. » Krag laisse échapper « mon père » |
| 2-9 | **Le Traité d'Ambre** (choix) |
| 2-10 | Révélation : Gharok est le père de Krag. **✦ Gharok** (choix majeur). Fin de l'acte 2, vers les Marais Murmurants |

## Choix

### 2-9 · Le Traité d'Ambre

| Option | Effets | Effet en 2-10 |
|---|---|---|
| A. Défendre le village humain | `s1.traite_ambreval`, Royaumes humains +20, Clans orcs −15 | Les miliciens tiennent les flancs : Barrière +25 |
| B. Défendre le campement orc | `s1.traite_campement`, Clans orcs +20, Royaumes humains −15 | Les chamans affaiblissent Gharok : il commence à 90 % |
| C. **[Humain / Clerc]** Négocier le Traité | `s1.traite_negocie`, les deux +10 | Les deux bonus |

L'option C n'apparaît que pour un joueur humain ou clerc (condition `only` : `{race: [...], class: [...]}`). Elle est invisible pour un Mage elfe.

### ✦ 2-10 · Gharok

| Option | Effets |
|---|---|
| A. Exorciser | `s1.gharok_exorcise`, **Krag rejoint le groupe** (`s1.krag_allie`, loyauté 60), Clans orcs +20, Sylwen +5 |
| B. Achever | `s1.gharok_acheve`, **Croc de Gharok** (charme légendaire unique : Puissance +7, Célérité +5), Clans orcs −10, Sylwen −5 · si B ou C en 2-9 : Krag rejoint le groupe avec une loyauté de 20 (candidat à la trahison) · si A en 2-9 : Krag part (`s1.krag_parti`) |

## Krag, 3e compagnon

- Orc Berserker. Ses familiers sont des Lanceurs de haches, qui frappent à 2,4 m par-dessus la mêlée.
- Sorts au Cercle : Hache tournoyante (zone) et Bond furieux (colonne).
- Ordre par défaut : Défends. Rôle : assaut.
- Sa loyauté n'apparaît qu'une fois qu'il a rejoint le groupe.
- **Cercle** : 2 compagnons actifs parmi ceux qui ont rejoint le groupe. Sur la fiche d'un compagnon resté à Havre-Aube, le bouton « Remplacer X » l'échange avec un compagnon actif.
- À deux, le premier compagnon (ordre Brann, Sylwen, Krag) se place à gauche et le second à droite. « Échanger les côtés » inverse les deux.
- Un niveau qui impose son équipe (1-1 en solo, 1-2 avec Sylwen seule) l'emporte sur le Cercle.
- Le rôle de chacun est affiché au Cercle :
  - Brann est le seul à renforcer la Barrière.
  - Sylwen frappe de loin.
  - Krag frappe par-dessus la mêlée.

### Équilibrage (IA, simulateur `--active=`)

| Niveau | Brann + Sylwen | Brann + Krag | Sylwen + Krag |
|---|---|---|---|
| 2-5 Varg | 3/3 · 123 s · Barrière 47 % | 3/3 · 128 s · 51 % | 3/3 · 90 s · 63 % |
| 2-10 Gharok (rejoué) | 2/2 · 331 s · 40 % | 1/2 · 325 s · 26 % | 0/2 : sans le Bouclier levé de Brann, la Barrière cède vers 180 s |

Sur les longs combats de boss, l'équipe sans Brann est fragile : c'est voulu, et le Cercle l'indique. Krag n'est disponible qu'après 2-10.

## Illustrations

Planches générées par code (`StoryArt._ambre`) :

| Planche | Contenu |
|---|---|
| `steppe` | Plein jour, cristaux d'ambre |
| `moulins` | Moulins d'Ambreval |
| `campement` | Tentes orques au crépuscule et feu de camp |
| `orage` | Totems et éclairs |
| `traite` | Village humain et campement orc face à face |
| `fort` | Palissade de Gharok, 3 bannières, orage |

## Répliques de combat

Krag a ses propres répliques au départ, quand la Barrière faiblit, à mi-parcours et au changement de phase d'un boss. Une variante dépend de l'exorcisme de son père, et deux autres de sa loyauté (≤ 30 ou ≥ 75). Elles existent aussi en zone 1, pour les niveaux rejoués.

## Aperçu web

`?scene=z02_l10_intro` ouvre une scène ; `?level=z02_l01&krag=1` lance un niveau avec Sylwen et Krag.
