# Acte 7 · Les Archives (narration de la zone 7, étape 17.2)

> Suite de [`38-narration-zone6.md`](38-narration-zone6.md). Arbre des choix : [`07-narration.md`](07-narration.md) §2. Zone jouable : [`39-zone7.md`](39-zone7.md).

## Distribution

| Personnage | Rôle | Portrait |
|---|---|---|
| **Ssareth** | Reptilien, Clerc. Scribe des Archives du Temps : la vérité avant tout, et sceller les Archives. Il sent les retours dans le temps. **6ᵉ compagnon** | Écailles vert-de-gris, collerette turquoise, yeux d'or fendus, robe d'écume, collier de perles de corail |
| **Le Léviathan** | Gardien des Archives, rongé par la Marée noire du Surge | Tête de serpent de mer bleu abysse, nageoires turquoise |
| **L'Ourdisseur** | Celui qui a créé les Sceaux d'Écho. On ne fait que l'entrevoir, au bout de ta ligne (7-9 A) | Silhouette encapuchonnée faite de fils, sans visage |
| La Voix inconnue | Revient en 7-5 | — |

## Ce que l'acte révèle

- Les Archives du Temps gardent chaque vie comme un fil de corail. Les Archivistes lisent et gardent les fils, mais ne lisent jamais le leur.
- La place des Statues honore tous les Porteurs d'Écho ; le dernier avant toi a eu le visage martelé, mais pas le nom : « M. ».
- **7-8 : la révélation.** Le fil noir porte enfin le nom en entier : « Morvaen, Porteur d'Écho, élève du premier Collège. Retours : quatre cent douze. » C'est le **3ᵉ Fragment de Morvaen** : « Un visage. Le Sceau m'a tout pris, sauf un visage. »
- La Voix a lu les Archives. 7-7 B : la fin du chant des Sirènes (Liriel morte mille fois, autrement à chaque retour).
- 7-9 A : l'**Ourdisseur** apparaît au bout de ta ligne. « Pas encore. »

## Déroulé

| Niveau | Temps fort |
|---|---|
| 7-1 | La Cité Engloutie, le souffle de nacre. **Ssareth rejoint le groupe** (méfiant si tu as menti au Sphinx) |
| 7-2 | Les fils de corail ; les nagas devenues sauvages |
| 7-3 | La grande marée ; Ssareth sent un retour dans le temps |
| 7-4 | La place des Statues ; la statue sans visage, « M. » |
| 7-5 | Le kraken des Archives ; la Voix |
| 7-6 | La cloche du registre ; les Archivistes ouvrent les portes (Archivistes +5) |
| 7-7 | Les Sirènes : **choix mineur** |
| 7-8 | La salle des fils ; le nom de Morvaen (Fragment +1) |
| 7-9 | Ta propre ligne : **choix** |
| 7-10 | Le Léviathan : **✦ choix majeur**. Fin de l'acte 7, vers les Terres Brisées |

## Choix

### 7-7 · Le chant des sirènes

| Option | Effets |
|---|---|
| A. Les délivrer : faire taire leur chant | `s1.sirenes_delivrees`, Ssareth +10, Sylwen +5 ; devant le Léviathan, elles chantent pour la Barrière (bouclier +25) |
| B. Écouter la fin du chant | `s1.chant_ecoute`, Corruption +5, Nyx +5 ; la fin de l'histoire de Liriel |

### 7-9 · Les Archives du Temps

| Option | Effets |
|---|---|
| A. Lire ta propre ligne | `s1.ligne_lue` et `s1.premonitions`, Ssareth −10 ; l'Ourdisseur ; devant le Léviathan, ses coups sont annoncés 0,5 s plus tôt (`warn_bonus`) |
| B. Sceller les Archives | `s1.archives_scellees`, Ssareth +20, Archivistes +10 ; devant le Léviathan, la marée ne monte pas (`no_tide`) |

**Prémonitions** : à chaque choix suivant, sous chaque option, l'écran de dialogue indique le type de ses conséquences, sans le détail (`Story.premonition` : Loyauté, Réputation, Corruption, Fragment, Objet, Fil du destin).

### ✦ 7-10 · Le Léviathan

| Option | Effets |
|---|---|
| A. Libérer le gardien | `s1.leviathan_libere`, Archivistes +20, Ssareth +10 : le Léviathan protège la Cité et l'Ordre des Archivistes s'allie |
| B. Le tuer | `s1.leviathan_tue`, Archivistes −10, Ssareth −15, **Trident des Archives** (arme unique légendaire : Puissance +10, Esprit +5, Destin +3, Foudre) |

## Les fils des actes précédents

| Drapeau | Effet dans l'acte 7 |
|---|---|
| `s1.sphinx_mensonge` (5-10 B) | Ssareth arrive méfiant : loyauté −10 (40) |
| `s1.sceau_revele` (5-10 A) | Ssareth : « C'est un bon début. » |
| `s1.oeuf_vole` (6-9 B) | Les dragons de la Mère survolent la côte en 7-2 et 7-4 (passages de dragons, clé `dragons` des `story_mods`) |

Nouvelles clés de `story_mods` : `dragons`, `no_tide`, `warn_bonus`.

## Ssareth, 6ᵉ compagnon

- Reptilien, Clerc ; bot défensif, sort **Chant des Archives** (la Barrière regagne 22 PV). Rejoint le groupe à la fin de 7-1 (`s1.ssareth_allie`), disponible dès 7-2.
- Il sent les retours dans le temps (réplique en 7-3) ; la perte de loyauté à chaque retour attend l'Observatoire.

## Illustrations

| Planche | Contenu |
|---|---|
| `quais` | Les quais engloutis, les bateaux échoués |
| `canal` | Le Grand Canal et son pont arqué |
| `statues` | La rangée des Porteurs, une statue sans visage |
| `archives` | La salle des fils de corail, le fil noir au centre |
| `palais` | La façade du palais aux colonnes de nacre |
| `abysse` | La fosse du Léviathan, deux yeux dans le noir |

Elles sont dessinées dans `StoryArt._cite` et `_cite_deep`. Les portraits `ssareth`, `leviathan` et `ourdisseur` sont dans `PortraitArt`.

## Aperçu web

- `?scene=z07_l08_outro` : le nom de Morvaen.
- `?scene=z07_l09_outro` : ta propre ligne.
- `?scene=z07_l10_outro` : le choix majeur.

## Vérifications

`tools/ui_smoke.gd` (`_act7_ok`) contrôle :
- les 20 scènes, les 3 portraits, les 6 planches et le sprite de Ssareth ;
- 7-1 (Ssareth recruté, méfiant après le mensonge au Sphinx), 7-7 A, 7-9 A (Prémonitions) et ✦ 7-10 A, joués à l'écran ;
- les Prémonitions d'une option ;
- devant le Léviathan : la marée retenue, les annonces allongées, le bouclier des Sirènes ; les dragons de l'Œuf volé en 7-2.
