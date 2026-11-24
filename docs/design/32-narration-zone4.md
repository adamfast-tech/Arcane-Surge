# Acte 4 · L'Honneur de Forgecœur (narration de la zone 4, étape 14.2)

> Suite de [`22-narration-zone3.md`](22-narration-zone3.md). Arbre des choix : [`07-narration.md`](07-narration.md) §2. Zone jouable : [`28-zone4.md`](28-zone4.md).

## Distribution

| Personnage | Rôle | Portrait |
|---|---|---|
| **Durgan Enclume** | Maître de la Forge de Havre-Aube, oncle de Brann. C'est lui qui a tourné la Clé-rune le jour où le clan a scellé la forteresse | Crâne chauve noirci de suie, lunettes de forge, barbe grise tressée d'anneaux de fer, tablier de cuir |
| **Ysolde** | Elfe, héritière des Runistes. Elle étudie les Portes des Pics et accompagne le groupe à partir de 4-3 | Cheveux de givre, diadème d'argent à gemme bleue, runes cyan tatouées sous les yeux |
| **Orrin Forgecœur** | Spectre du Thane, grand-père de Brann. Il est resté dans la forteresse avec la Garde de l'Enclume | Spectre bleu, heaume couronné, barbe blanche tressée d'anneaux d'or, bas du corps qui se dissout |
| La Voix inconnue | Revient en 4-5 | — |

## L'histoire du clan

- Il y a soixante hivers, une vague du Surge frappe les Pics. Le Cœur de la forteresse Forgecœur se noie dans la magie brute.
- Le clan scelle les Portes avec le Thane Orrin et la Garde de l'Enclume à l'intérieur. Les autres clans l'appellent depuis « le clan qui ferme » et rayent les noms des Scelleurs.
- **La vérité (4-8)** : c'est Orrin qui a ordonné de fermer. Le Colosse retenait le Surge, mais il fallait des nains pour tenir les runes. Il est resté, et Durgan a obéi en pleurant. Les nains figés sous le lac gelé (4-4) étaient des volontaires partis chercher de l'aide.
- La Voix inconnue y fait écho en 4-5 : « Moi, j'ai voulu en rouvrir une. Une seule. » C'est un nouvel indice sur Morvaen.

## Déroulé

| Niveau | Temps fort |
|---|---|
| 4-1 | À la Forge, Durgan confie à Brann la Clé-rune du clan. Sur la route du col, Brann raconte le scellement |
| 4-2 | Les cairns des Scelleurs, noms effacés au burin. Brann a pris le nom de Bastion d'Argent |
| 4-3 | La Porte naine vivante ; Ysolde, héritière des Runistes, rejoint le groupe |
| 4-4 | Le lac gelé : la Garde de l'Enclume figée sous la glace, ni morte ni vivante |
| 4-5 | La Sentinelle runique ; son dernier ordre : « Par ordre du Thane ». La Voix revient |
| 4-6 | L'aurore, puis le feu de camp : **choix mineur** avec Brann |
| 4-7 | Le chariot runique porte le Burin-maître jusqu'à la forteresse |
| 4-8 | Les Portes scellées s'ouvrent ; le spectre d'Orrin révèle la vérité (`s1.verite_orrin`, Brann +5) |
| 4-9 | **La Forteresse** (choix) |
| 4-10 | Le Colosse vaincu, agenouillé, attend un ordre. **✦ Le Cœur de Forgecœur** (choix majeur). Fin de l'acte 4, vers le Désert de Verre |

## Choix

### 4-6 · Le feu de camp

Brann : « Et si je descends là-dedans et que je ne trouve que la honte ? »

| Option | Effets |
|---|---|
| A. « L'honneur ne s'hérite pas. Tu l'as gagné cent fois à mes côtés. » | Brann +5 |
| B. « Alors on la regardera en face, ensemble. La vérité d'abord. » | Brann +10 (il apprécie l'honnêteté) |
| C. « Le passé se réécrit. Avec le Sceau, on pourrait défaire ce jour-là. » | Brann −10, Corruption +5 (c'est ce qu'a fait Morvaen) |

### 4-9 · La Forteresse

| Option | Condition | Effets |
|---|---|---|
| A. [Nain] Poser ta main sur la Clé et réveiller les Portes | Héros nain | `s1.portes_reactivees`, Brann +10, Nains +20 |
| A. [Brann · loyauté 60] Demander à Brann de tourner la Clé avec toi | Héros d'une autre race, Brann ≥ 60 | Mêmes effets |
| B. Sceller la forteresse, pour de bon | — | `s1.forteresse_scellee`, Brann −15, Sylwen +5 |

- Une option réservée hors de portée s'affiche **verrouillée** (grisée, cadenas), sauf si une autre option de la même lettre est ouverte. Le joueur voit donc qu'une autre voie existait.
- Nouvelle condition `except` ({race, class}) : l'option est masquée pour cette race ou cette classe. Elle complète `only`.

**Effets en combat** : les `story_mods` des 10 niveaux de la zone 4 (rejouables, et 4-10).

| Drapeau | Effet |
|---|---|
| `s1.portes_reactivees` | Portails FORGE ×2 (+20 défense et +50 % PV au lieu de +10 et +25 %) ; des Sentinelles anciennes rejoignent les vagues (poids +0,5) |
| `s1.forteresse_scellee` | Vagues réduites de 15 % (budget ×0,85) |

Nouvelles clés de `story_mods` : `forge_mult`, `budget_mult`, `pool_add` ({unité: poids}).

### ✦ 4-10 · Le Cœur de Forgecœur

| Option | Effets |
|---|---|
| A. Reprogrammer le Colosse avec Ysolde | `s1.colosse_allie` (le Colosse répondra à l'appel au combat final), Nains +10, Brann +5, Sylwen +5 |
| B. Briser son cœur et forger l'Enclume-Cœur | `s1.colosse_detruit`, **Enclume-Cœur** (main secondaire légendaire unique : Vigueur +9, Puissance +4, Foudre), Cristal de givre +9 et Rune brisée +6 (le butin de matériaux du boss ×3), Nains −5 |

- Nouvel effet `mats` ({matériau: quantité}) dans `Story.apply`.

**L'honneur de Forgecœur** (`s1.honneur_forgecoeur`) est restauré si les Portes ont été réactivées en 4-9, ou si la loyauté de Brann atteint 70. Brann devient alors « Héritier de Forgecœur » (`title_flag`, dans toutes les zones), et Orrin le lui dit avant de disparaître. Sinon, Brann promet que le nom Forgecœur se dira un jour la tête haute.

## Répliques de combat

- Brann, Sylwen, Krag et Nyx ont leurs répliques pour les Pics.
- Variantes selon `s1.portes_reactivees`, `s1.forteresse_scellee` et `s1.verite_orrin`.
- Répliques propres à 4-5, 4-9 et 4-10, dont les phases du Colosse.

## Illustrations

| Planche | Contenu |
|---|---|
| `forge` | La Forge de Havre-Aube : foyer, enclume, outils pendus, étincelles |
| `pics` | Route du col en lacets, pics enneigés, sapins, neige qui tombe |
| `porte` | Falaise déchiquetée et arche naine aux runes vivantes |
| `lac` | Lac gelé sous l'aurore boréale, silhouettes figées sous la glace |
| `forteresse` | Remparts, tours, bannières du clan, Portes scellées de givre noirci |
| `colosse` | Salle du Cœur : piliers runiques, grand cercle de runes, autel du Cœur |

Toutes sont dessinées dans `StoryArt._pics`, `_colosse` et `_forge`. Les portraits `durgan`, `ysolde` et `orrin` sont dans `PortraitArt`.

## Aperçu web

- `?scene=z04_l08_outro` : la révélation d'Orrin.
- `?scene=z04_l09_outro` : le choix des Portes, avec l'option de Brann verrouillée sur un profil neuf.
- `?scene=z04_l10_outro` : le choix majeur.

## Vérifications

`tools/ui_smoke.gd` (`_act4_ok`) contrôle :
- les 20 scènes, les 3 portraits et les 6 planches ;
- le feu de camp, la révélation, 4-9 par l'option de Brann puis ✦ 4-10 « Briser son cœur » (Enclume-Cœur, matériaux, honneur, titre) ;
- 4-9 avec Brann à 50 : l'option verrouillée ;
- les options vues par un Nain ;
- en combat (z04_l03) : FORGE ×2, Sentinelles dans les vagues, vagues ×0,85.

`tools/sim_cli.gd -- --flags=s1.portes_reactivees` joue un niveau avec des drapeaux d'histoire. Sur z04_l09 (Mage, 4 parties), les trois cas gagnent 3 fois sur 4 :

| Cas | Durée moyenne |
|---|---|
| Sans drapeau | 100 s |
| Portes réactivées | 110 s (plus d'ennemis, invocations plus solides) |
| Forteresse scellée | 89 s |
